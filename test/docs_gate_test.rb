# frozen_string_literal: true

require "fileutils"
require "minitest/autorun"
require "open3"
require "stringio"
require "tmpdir"

require_relative "../scripts/docs_gate"

class DocsGateTest < Minitest::Test
  SOURCE_ROOT = File.expand_path("..", __dir__)

  def setup
    @root = Dir.mktmpdir("trainradar-docs-gate-test-")
    fixture_entries.each do |entry|
      copy_fixture_entry(entry)
    end
    run_git("init")
    run_git("config", "user.email", "docs-gate@example.test")
    run_git("config", "user.name", "Docs Gate Test")
    run_git("add", "--", ".")
    run_git("commit", "-m", "fixture")
  end

  def teardown
    FileUtils.remove_entry(@root) if @root && File.directory?(@root)
  end

  def test_docs_sync_is_idempotent
    gate.sync
    first = File.binread(File.join(@root, "docs/PROJECT_MAP.md"))

    gate.sync

    assert_equal first, File.binread(File.join(@root, "docs/PROJECT_MAP.md"))
  end

  def test_docs_check_detects_artificial_drift
    File.open(File.join(@root, "docs/PROJECT_MAP.md"), "a") { |file| file.puts "manual drift" }

    refute gate.check
    gate.sync
    assert gate.check
  end

  def test_project_map_order_is_stable
    first = gate.project_map
    second = gate.project_map
    module_rows = first.lines.grep(/^\| `[^`]+\/` \|/)

    assert_equal first, second
    assert_equal module_rows.sort, module_rows
  end

  def test_source_path_change_updates_generated_sections
    File.open(File.join(@root, ".env.example"), "a") { |file| file.puts "DOC_GATE_TEST_SETTING=1" }

    gate.sync

    assert_includes File.read(File.join(@root, "docs/PROJECT_MAP.md")), "DOC_GATE_TEST_SETTING"
    assert_includes File.read(File.join(@root, "README.md")), "DOC_GATE_TEST_SETTING"
  end

  def test_public_api_change_requires_human_owned_docs
    File.open(File.join(@root, "openapi/openapi.yaml"), "a") { |file| file.puts "# staged API change" }
    run_git("add", "--", "openapi/openapi.yaml")

    refute gate.check_impact(staged: true)
    assert_includes error_output, "rule public-api"
    assert_includes error_output, "docs/API_CONTRACT.md"
  end

  def test_new_project_path_requires_project_map
    FileUtils.mkdir_p(File.join(@root, "backend/new_module"))
    File.write(File.join(@root, "backend/new_module/entry.txt"), "fixture\n")
    run_git("add", "--", "backend/new_module/entry.txt")

    assert_equal ["backend/new_module/entry.txt"], gate.send(:staged_added_paths)
    refute gate.check_impact(staged: true)
    assert_includes error_output, "rule project-structure"
    assert_includes error_output, "docs/PROJECT_MAP.md"
  end

  def test_existing_project_path_does_not_require_project_map
    validator_path = File.join(@root, "scripts/validate_openapi.rb")
    File.open(validator_path, "a") { |file| file.puts "# implementation-only fixture change" }
    run_git("add", "--", "scripts/validate_openapi.rb")

    assert_empty gate.send(:staged_added_paths)
    assert gate.check_impact(staged: true), error_output
  end

  def test_sync_does_not_change_human_text_outside_markers
    path = File.join(@root, "docs/API_CONTRACT.md")
    original = File.read(path)
    human_prefix = "Human-owned introduction that must survive.\n\n"
    File.write(path, human_prefix + original)

    gate.sync

    assert_equal human_prefix, File.read(path).slice(0, human_prefix.length)
  end

  def test_auto_staging_changes_only_generated_manifest_target
    FileUtils.mkdir_p(File.join(@root, "new_module"))
    File.write(File.join(@root, "new_module/entry.txt"), "fixture\n")
    run_git("add", "--", "new_module/entry.txt")

    assert gate.send(:sync_safe_generated_from_index)

    staged = git_output("diff", "--cached", "--name-only").lines(chomp: true).sort
    assert_equal ["docs/PROJECT_MAP.md", "new_module/entry.txt"], staged
  end

  def test_generated_sections_are_updated_but_require_manual_staging
    openapi_path = File.join(@root, "openapi/openapi.yaml")
    contents = File.read(openapi_path).sub("operationId: getHealth", "operationId: getHealthChanged")
    File.write(openapi_path, contents)
    run_git("add", "--", "openapi/openapi.yaml")

    refute gate.send(:sync_safe_generated_from_index)

    assert_includes File.read(File.join(@root, "docs/API_CONTRACT.md")), "getHealthChanged"
    refute_includes git_output("diff", "--cached", "--name-only"), "docs/API_CONTRACT.md"
  end

  def test_partially_staged_change_never_overwrites_unstaged_generated_doc
    map_path = File.join(@root, "docs/PROJECT_MAP.md")
    File.open(map_path, "a") { |file| file.puts "user draft outside index" }
    handler_path = File.join(@root, "backend/internal/httpapi/handler.go")
    File.open(handler_path, "a") { |file| file.puts "// staged change" }
    run_git("add", "--", "backend/internal/httpapi/handler.go")

    refute gate.pre_commit
    assert_includes File.read(map_path), "user draft outside index"
  end

  def test_pre_commit_accepts_a_clean_staged_generated_document
    File.open(File.join(@root, "docs/PROJECT_MAP.md"), "a") { |file| file.puts "staged drift" }
    run_git("add", "--", "docs/PROJECT_MAP.md")

    assert gate.pre_commit
  end

  def test_hook_returns_nonzero_for_rejected_staged_content
    access_key = ["AKIA", "1234567890ABCDEF"].join
    File.write(File.join(@root, "unsafe.txt"), "token=#{access_key}\n")
    run_git("add", "--", "unsafe.txt")

    _output, status = Open3.capture2e(File.join(@root, ".githooks/pre-commit"), chdir: @root)

    refute status.success?
  end

  def test_install_hooks_is_repeatable
    assert gate.install_hooks
    assert gate.install_hooks

    assert_equal ".githooks", git_output("config", "--get", "core.hooksPath").strip
  end

  def test_brand_assets_accept_binary_png_signatures
    assert gate.brand_assets
  end

  def test_large_binary_allowlist_is_exactly_the_canonical_brand_master
    assert gate.send(:allowed_large_binary?, "assets/brand/trainradar/master/trainradar-icon-master-1254.png")
    refute gate.send(:allowed_large_binary?, "assets/brand/trainradar/master/replacement.png")
  end

  private

  def fixture_entries
    %w[
      AGENTS.md Makefile README.md .env.example .gitignore backend data docs docker-compose.yml
      mobile/README.md mobile/pubspec.yaml mobile/analysis_options.yaml mobile/lib mobile/test
      mobile/android/app/src/main/res mobile/ios/Runner/Assets.xcassets
      openapi scripts/docs_gate.rb scripts/validate_openapi.rb .githooks
    ]
  end

  def copy_fixture_entry(entry)
    source = File.join(SOURCE_ROOT, entry)
    return unless File.exist?(source)

    destination = File.join(@root, entry)
    FileUtils.mkdir_p(File.dirname(destination))
    FileUtils.cp_r(source, destination)
  end

  def gate
    @gate ||= TrainRadar::DocsGate.new(root: @root, out: StringIO.new, err: @error = StringIO.new)
  end

  def error_output
    @error.string
  end

  def run_git(*arguments)
    output, status = Open3.capture2e("git", *arguments, chdir: @root)
    assert status.success?, "git #{arguments.join(' ')} failed: #{output}"
  end

  def git_output(*arguments)
    output, status = Open3.capture2e("git", *arguments, chdir: @root)
    assert status.success?, "git #{arguments.join(' ')} failed: #{output}"
    output
  end
end
