#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "json"
require "open3"
require "set"
require "tmpdir"
require "yaml"

module TrainRadar
  class DocsGate
    MANIFEST_PATH = "docs/DOCS_MANIFEST.yaml"
    IMPACT_PATH = "docs/CHANGE_IMPACT.yaml"
    GENERATED_BEGIN = "<!-- BEGIN GENERATED: %s -->"
    GENERATED_END = "<!-- END GENERATED: %s -->"
    DOCUMENT_FIELDS = %w[
      path audience owner type source_paths generation_command check_command
      update_conditions auto_stage
    ].freeze
    DOCUMENT_TYPES = %w[generated generated-sections human].freeze
    EXCLUDED_TOP_LEVEL = %w[.git .dart_tool .idea .omx .codex].freeze
    EXCLUDED_PATH_PARTS = %w[.DS_Store build coverage vendor node_modules .dart_tool .idea].freeze
    LARGE_BINARY_BYTES = 1_048_576

    def initialize(root: File.expand_path("..", __dir__), out: $stdout, err: $stderr)
      @root = root
      @out = out
      @err = err
    end

    def sync
      manifest = load_manifest(@root)
      validate_manifest!(manifest, @root)
      changed = write_rendered_documents(manifest, @root)
      changed.each { |path| @out.puts "UPDATED: #{path}" }
      @out.puts(changed.empty? ? "PASS: generated documentation is already synchronized" : "PASS: generated documentation synchronized")
      changed
    end

    def check
      manifest = load_manifest(@root)
      validate_manifest!(manifest, @root)
      drift = rendered_drift(manifest, @root)
      if drift.empty?
        @out.puts "PASS: generated documentation has no drift"
        return true
      end

      @err.puts "Documentation drift detected: #{drift.join(', ')}"
      @err.puts "Run: make docs-sync"
      false
    rescue ValidationError => e
      @err.puts "Documentation manifest validation failed: #{e.message}"
      false
    end

    def check_impact(staged: false)
      files = staged ? staged_paths : tracked_changed_paths
      return true if files.empty?

      root = staged ? stage_checkout : @root
      manifest = load_manifest(root)
      validate_manifest!(manifest, root)
      impact = load_yaml(File.join(root, IMPACT_PATH))
      validate_impact!(impact)
      changed = files.to_set
      failures = []

      Array(impact.fetch("rules")).each do |rule|
        triggers = Array(rule.fetch("source_paths"))
        hits = files.select { |path| triggers.any? { |pattern| path_matches?(pattern, path) } }
        next if hits.empty?

        missing = Array(rule.fetch("required_documents")) - changed.to_a
        next if missing.empty?

        failures << [rule.fetch("id"), hits, missing]
      end

      if failures.empty?
        @out.puts "PASS: documentation impact is covered"
        return true
      end

      @err.puts "Documentation impact requires human-owned updates:"
      failures.each do |id, hits, missing|
        @err.puts "- rule #{id}: source change #{hits.join(', ')} requires #{missing.join(', ')}"
      end
      @err.puts "Update and stage the listed documents; generated sections still require review."
      false
    rescue ValidationError => e
      @err.puts "Documentation impact validation failed: #{e.message}"
      false
    ensure
      FileUtils.remove_entry(root) if staged && root && root != @root && File.directory?(root)
    end

    def pre_commit
      files = staged_paths
      return true if files.empty?

      return false unless staged_safety_checks(files)
      return false unless sync_safe_generated_from_index
      return false unless check_impact(staged: true)
      return false unless staged_fast_checks(staged_paths)

      @out.puts "PASS: staged change gate completed"
      true
    end

    def install_hooks
      success = run("git", "config", "core.hooksPath", ".githooks", chdir: @root)
      @out.puts "PASS: core.hooksPath=.githooks" if success
      success
    end

    def brand_assets(root = @root)
      asset_roots = [
        "mobile/android/app/src/main/res",
        "mobile/ios/Runner/Assets.xcassets"
      ]
      pngs = asset_roots.flat_map do |relative_root|
        Dir.glob(File.join(root, relative_root, "**/*.png"))
      end.sort
      errors = pngs.map do |path|
        content = File.binread(path)
        relative_path = relative_from(root, path)
        "brand asset is not a PNG: #{relative_path}" unless content.start_with?("\x89PNG\r\n\x1A\n".b)
      end.compact
      if errors.empty?
        @out.puts "PASS: #{pngs.length} mobile visual assets have valid PNG signatures"
        true
      else
        errors.each { |error| @err.puts error }
        false
      end
    end

    def project_map(root = @root)
      tracked = tracked_files(root)
      top_levels = tracked.select { |path| path.include?("/") }.map { |path| path.split("/").first }.uniq.sort
      modules = top_levels.map { |name| module_description(name, tracked) }.compact
      endpoints = api_endpoints(root)
      env_keys = environment_keys(root)
      generated = tracked.select { |path| path.include?("generated") || path.include?(".g.") }

      lines = [
        "# Project Map",
        "",
        "<!-- GENERATED FILE: do not edit; run `make docs-sync` -->",
        "",
        "Детерминированная карта рабочего дерева, исключающая cache, build output, secrets и binary contents. Она не заменяет архитектурные решения в `docs/`.",
        "",
        "## Верхний уровень и модули",
        "",
        "| Путь | Назначение |",
        "| --- | --- |"
      ]
      modules.each { |name, description| lines << "| `#{name}/` | #{description} |" }

      lines.concat([
        "",
        "Ключевые конфигурации: `AGENTS.md`, `Makefile`, `docker-compose.yml`, `.env.example`, `docs/DOCS_MANIFEST.yaml`, `docs/CHANGE_IMPACT.yaml`, `.omx/plans/`.",
        "",
        "",
        "## Entrypoints и платформы",
        "",
        "| Surface | Entrypoint / состояние |",
        "| --- | --- |",
        "| Go API | `backend/cmd/api/main.go` — HTTP skeleton |",
        "| Flutter | `mobile/lib/main.dart` — iOS/Android shell |",
        "| Local services | `docker-compose.yml` — operational PostGIS и отдельный raw-GPS store |",
        "| Validators | `scripts/validate_reference_data.rb`, `scripts/validate_openapi.rb` |",
        "",
        "## Публичные интерфейсы",
        "",
        "| Method | Path | Operation ID |",
        "| --- | --- | --- |"
      ])
      endpoints.each { |method, path, operation| lines << "| `#{method.upcase}` | `#{path}` | `#{operation}` |" }

      lines.concat([
        "",
        "## Конфигурация без секретов",
        "",
        "Источник: `.env.example`; значения намеренно не публикуются.",
        "",
        "| Переменная |",
        "| --- |"
      ])
      env_keys.each { |key| lines << "| `#{key}` |" }

      lines.concat([
        "",
        "## Тесты, документы и generated-код",
        "",
        "- Ruby tests: `test/`.",
        "- Go tests: `backend/**/*_test.go`.",
        "- Flutter tests: `mobile/test/`.",
        "- Human-owned документация: `docs/`, кроме явно generated файлов и блоков из `docs/DOCS_MANIFEST.yaml`.",
        "- Generated documentation: `docs/PROJECT_MAP.md` и отмеченные блоки в README/API contract.",
        "- Generated source code: #{generated.empty? ? "не используется в M0." : generated.map { |path| "`#{path}`" }.join(", ")}"
      ])

      lines.concat([
        "",
        "## Канонические проверки",
        "",
        "```bash",
        "make docs-sync",
        "make docs-check",
        "make check-staged",
        "make check-full",
        "make ready",
        "```",
        ""
      ])
      lines.join("\n")
    end

    private

    class ValidationError < StandardError; end

    def load_manifest(root)
      load_yaml(File.join(root, MANIFEST_PATH))
    end

    def load_yaml(path)
      YAML.safe_load(File.read(path), [], [], false)
    rescue Errno::ENOENT
      raise ValidationError, "missing #{relative(path)}"
    rescue Psych::Exception => e
      raise ValidationError, "invalid YAML in #{relative(path)}: #{e.message}"
    end

    def validate_manifest!(manifest, root)
      raise ValidationError, "#{MANIFEST_PATH} root must be a mapping" unless manifest.is_a?(Hash)
      documents = manifest["documents"]
      raise ValidationError, "#{MANIFEST_PATH}.documents must be an array" unless documents.is_a?(Array)

      paths = []
      documents.each_with_index do |document, index|
        raise ValidationError, "documents[#{index}] must be a mapping" unless document.is_a?(Hash)
        missing = DOCUMENT_FIELDS.reject { |field| document.key?(field) }
        raise ValidationError, "documents[#{index}] missing #{missing.join(', ')}" unless missing.empty?
        raise ValidationError, "invalid document type #{document['type']}" unless DOCUMENT_TYPES.include?(document["type"])
        raise ValidationError, "document path must be repo-relative" if document["path"].start_with?("/") || document["path"].include?("..")
        raise ValidationError, "auto_stage requires type=generated for #{document['path']}" if document["auto_stage"] && document["type"] != "generated"
        paths << document["path"]

        if document["type"] == "generated-sections"
          sections = Array(document["generated_sections"])
          raise ValidationError, "generated-sections document #{document['path']} has no sections" if sections.empty?
          body = File.read(File.join(root, document["path"]))
          sections.each { |section| validate_markers!(body, section, document["path"]) }
        end
      end
      raise ValidationError, "document paths must be unique" unless paths.uniq.length == paths.length

      documented_markdown = Dir.glob(File.join(root, "docs/**/*.md")).map { |path| relative_from(root, path) }.sort
      missing = documented_markdown - paths
      raise ValidationError, "unregistered docs: #{missing.join(', ')}" unless missing.empty?
    end

    def validate_impact!(impact)
      raise ValidationError, "#{IMPACT_PATH} root must be a mapping" unless impact.is_a?(Hash)
      rules = impact["rules"]
      raise ValidationError, "#{IMPACT_PATH}.rules must be an array" unless rules.is_a?(Array)
      ids = rules.map do |rule|
        raise ValidationError, "impact rule must be a mapping" unless rule.is_a?(Hash)
        %w[id source_paths required_documents].each do |field|
          raise ValidationError, "impact rule missing #{field}" unless rule.key?(field)
        end
        rule["id"]
      end
      raise ValidationError, "impact rule ids must be unique" unless ids.uniq.length == ids.length
    end

    def rendered_documents(manifest, root)
      manifest.fetch("documents").map do |document|
        next if document["type"] == "human"

        path = document.fetch("path")
        target = File.join(root, path)
        current = File.exist?(target) ? File.read(target) : ""
        rendered = case document.fetch("type")
                   when "generated" then render_generated_file(path, root)
                   when "generated-sections" then render_sections(current, document, root)
                   end
        [path, rendered]
      end.compact.to_h
    end

    def render_generated_file(path, root)
      return project_map(root) if path == "docs/PROJECT_MAP.md"

      raise ValidationError, "no renderer for #{path}"
    end

    def render_sections(current, document, root)
      Array(document.fetch("generated_sections")).reduce(current) do |body, section|
        replacement = generated_section(section, root)
        begin_marker = Regexp.escape(format(GENERATED_BEGIN, section))
        end_marker = Regexp.escape(format(GENERATED_END, section))
        body.sub(/#{begin_marker}.*?#{end_marker}/m, "#{format(GENERATED_BEGIN, section)}\n#{replacement}\n#{format(GENERATED_END, section)}")
      end
    end

    def generated_section(section, root)
      case section
      when "root-commands-and-configuration"
        keys = environment_keys(root).map { |key| "- `#{key}`" }
        (["### Проверки", "", "```bash", "make docs-sync", "make docs-check", "make check-staged", "make check-full", "make ready", "```", "", "### Конфигурация", "", "Переменные из `.env.example` (значения и секреты не генерируются):"] + keys).join("\n")
      when "mobile-capabilities"
        "| Source of truth | Value |\n| --- | --- |\n| Package | `#{mobile_package_name(root)}` |\n| Flutter platforms | `iOS`, `Android` |\n| Entrypoint | `mobile/lib/main.dart` |\n| Module checks | `flutter analyze`, `flutter test` |"
      when "api-reference"
        lines = ["| Method | Path | Operation ID |", "| --- | --- | --- |"]
        api_endpoints(root).each { |method, path, operation| lines << "| `#{method.upcase}` | `#{path}` | `#{operation}` |" }
        lines.join("\n")
      else
        raise ValidationError, "no renderer for generated section #{section}"
      end
    end

    def write_rendered_documents(manifest, root)
      changed = []
      rendered_documents(manifest, root).each do |path, content|
        absolute = File.join(root, path)
        next if File.exist?(absolute) && File.read(absolute) == content

        FileUtils.mkdir_p(File.dirname(absolute))
        File.write(absolute, content)
        changed << path
      end
      changed.sort
    end

    def rendered_drift(manifest, root)
      rendered_documents(manifest, root).each_with_object([]) do |(path, content), drift|
        absolute = File.join(root, path)
        drift << path unless File.exist?(absolute) && File.read(absolute) == content
      end.sort
    end

    def validate_markers!(body, section, path)
      begin_marker = format(GENERATED_BEGIN, section)
      end_marker = format(GENERATED_END, section)
      valid = body.scan(begin_marker).length == 1 && body.scan(end_marker).length == 1 && body.index(begin_marker) < body.index(end_marker)
      raise ValidationError, "#{path} must contain one ordered marker pair for #{section}" unless valid
    end

    def staged_safety_checks(files)
      return false unless run("git", "diff", "--cached", "--check", chdir: @root)

      files.each do |path|
        content = staged_blob(path)
        next if content.nil?

        if content.bytesize > LARGE_BINARY_BYTES && binary?(content)
          @err.puts "Large staged binary exceeds #{LARGE_BINARY_BYTES} bytes: #{path}"
          return false
        end
        next if binary?(content)

        if content.match?(/^(<<<<<<< |=======|>>>>>>> )/)
          @err.puts "Conflict marker in staged file: #{path}"
          return false
        end
        if content.match?(/-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----|ghp_[A-Za-z0-9]{30,}|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{20,}/)
          @err.puts "Potential secret in staged file: #{path}"
          return false
        end
      end
      true
    end

    def sync_safe_generated_from_index
      stage_root = stage_checkout
      manifest = load_manifest(stage_root)
      validate_manifest!(manifest, stage_root)
      manual_review_required = []
      rendered_documents(manifest, stage_root).each do |path, content|
        document = manifest.fetch("documents").find { |candidate| candidate["path"] == path }
        absolute = File.join(@root, path)
        if document.fetch("auto_stage") && !tracked?(path)
          @err.puts "Generated file is not tracked and cannot be auto-staged safely: #{path}"
          @err.puts "Run make docs-sync, review it, then git add -- #{path}"
          return false
        end
        if unstaged_change?(path)
          @err.puts "Generated file has unstaged user edits; refusing to overwrite: #{path}"
          @err.puts "Review and stage it manually after make docs-sync."
          return false
        end
        next if File.exist?(absolute) && File.read(absolute) == content

        File.write(absolute, content)
        if document.fetch("auto_stage")
          return false unless run("git", "add", "--", path, chdir: @root)
          @out.puts "AUTO-STAGED GENERATED DOC: #{path}"
        else
          manual_review_required << path
        end
      end
      unless manual_review_required.empty?
        @err.puts "Generated sections updated but intentionally not staged: #{manual_review_required.join(', ')}"
        @err.puts "Review them and run git add -- #{manual_review_required.join(' ')} before retrying."
        return false
      end
      true
    rescue ValidationError => e
      @err.puts "Cannot synchronize generated documentation from index: #{e.message}"
      false
    ensure
      FileUtils.remove_entry(stage_root) if stage_root && File.directory?(stage_root)
    end

    def staged_fast_checks(files)
      stage_root = stage_checkout
      changed_go = files.any? { |path| path.match?(%r{\Abackend/.+\.go\z}) }
      changed_mobile = files.any? { |path| path.match?(%r{\Amobile/(lib|test)/.+\.dart\z}) || path == "mobile/pubspec.yaml" }
      changed_ruby = files.any? { |path| path.match?(%r{\A(scripts|test)/.+\.rb\z}) }
      changed_schema = files.any? { |path| %w[openapi/openapi.yaml data/reference/paveletsky_uzunovo_stations.yaml data/reference/source_manifest.yaml].include?(path) }
      changed_brand_assets = files.any? { |path| path_matches?("mobile/android/app/src/main/res/**", path) || path_matches?("mobile/ios/Runner/Assets.xcassets/**", path) }

      if changed_go
        files.grep(%r{\Abackend/.+\.go\z}).each do |path|
          content = File.binread(File.join(stage_root, path))
          formatted, status = Open3.capture2("gofmt", stdin_data: content)
          unless status.success? && formatted == content
            @err.puts "Staged Go file is not gofmt-formatted: #{path}"
            return false
          end
        end
        return false unless run("go", "test", "./...", chdir: File.join(stage_root, "backend"))
      end

      if changed_mobile
        copy_flutter_package_config(stage_root)
        return false unless run("flutter", "analyze", chdir: File.join(stage_root, "mobile"))
        return false unless run("flutter", "test", chdir: File.join(stage_root, "mobile"))
      end

      if changed_schema
        return false unless run("ruby", "scripts/validate_reference_data.rb", chdir: stage_root)
        return false unless run("ruby", "scripts/validate_openapi.rb", chdir: stage_root)
      end

      if changed_ruby
        return false unless run("ruby", "-e", 'Dir["test/**/*_test.rb"].sort.each { |file| load file }', chdir: stage_root)
      end
      return false if changed_brand_assets && !brand_assets(stage_root)
      true
    ensure
      FileUtils.remove_entry(stage_root) if stage_root && File.directory?(stage_root)
    end

    def copy_flutter_package_config(stage_root)
      source = File.join(@root, "mobile/.dart_tool/package_config.json")
      return unless File.exist?(source)

      destination = File.join(stage_root, "mobile/.dart_tool/package_config.json")
      FileUtils.mkdir_p(File.dirname(destination))
      FileUtils.cp(source, destination)
    end

    def stage_checkout
      destination = Dir.mktmpdir("trainradar-index-")
      success = run("git", "--work-tree=#{destination}", "checkout-index", "-a", chdir: @root)
      raise ValidationError, "unable to materialize staged index" unless success

      destination
    rescue StandardError
      FileUtils.remove_entry(destination) if destination && File.directory?(destination)
      raise
    end

    def staged_paths
      output, status = Open3.capture2("git", "diff", "--cached", "--name-only", "-z", "--diff-filter=ACMR", chdir: @root)
      raise ValidationError, "cannot read staged paths" unless status.success?

      output.split("\0").reject(&:empty?).sort
    end

    def tracked_changed_paths
      output, status = Open3.capture2("git", "diff", "--name-only", "--diff-filter=ACMR", chdir: @root)
      raise ValidationError, "cannot read changed paths" unless status.success?

      output.lines(chomp: true).sort
    end

    def tracked_files(root)
      command = root == @root ? ["git", "ls-files", "--cached", "--others", "--exclude-standard"] : ["git", "ls-files"]
      output, status = Open3.capture2(*command, chdir: @root)
      raise ValidationError, "cannot list tracked files" unless status.success?

      output.lines(chomp: true).reject { |path| excluded_path?(path) }.sort
    end

    def module_description(name, tracked)
      descriptions = {
        "backend" => "Go modular-monolith API и доменная логика.",
        "data" => "Reference registry и manifests источников.",
        "docs" => "Архитектурные, продуктовые, privacy, QA и evidence-документы.",
        "infra" => "Инициализация local development data stores.",
        "mobile" => "Flutter shell для iOS и Android.",
        "openapi" => "OpenAPI 3.1 contract M0.",
        "scripts" => "Детерминированные локальные validators и documentation gates.",
        "test" => "Ruby tests validators и documentation gates.",
        ".githooks" => "Repo-local pre-commit и pre-push hooks.",
        ".github" => "CI workflow checks."
      }
      return [name, descriptions.fetch(name, "Tracked repository configuration.")] if descriptions.key?(name)
      return nil if EXCLUDED_TOP_LEVEL.include?(name)

      [name, "Tracked repository configuration."] if tracked.any? { |path| path.start_with?("#{name}/") || path == name }
    end

    def api_endpoints(root)
      path = File.join(root, "openapi/openapi.yaml")
      return [] unless File.exist?(path)

      document = load_yaml(path)
      document.fetch("paths", {}).sort.flat_map do |route, operations|
        operations.map do |method, definition|
          next unless %w[get post put patch delete head options].include?(method)

          [method, route, definition.fetch("operationId", "-")]
        end
      end.compact
    end

    def environment_keys(root)
      path = File.join(root, ".env.example")
      return [] unless File.exist?(path)

      File.readlines(path, chomp: true).map { |line| line[/\A([A-Z][A-Z0-9_]*)=/, 1] }.compact.sort
    end

    def mobile_package_name(root)
      path = File.join(root, "mobile/pubspec.yaml")
      return "unknown" unless File.exist?(path)

      load_yaml(path).fetch("name", "unknown")
    end

    def staged_blob(path)
      output, status = Open3.capture2("git", "show", ":#{path}", chdir: @root)
      status.success? ? output : nil
    end

    def binary?(content)
      content.include?("\x00")
    end

    def tracked?(path)
      _output, status = Open3.capture2("git", "ls-files", "--error-unmatch", "--", path, chdir: @root)
      status.success?
    end

    def unstaged_change?(path)
      output, status = Open3.capture2("git", "diff", "--", path, chdir: @root)
      raise ValidationError, "cannot inspect worktree state for #{path}" unless status.success?

      !output.empty?
    end

    def path_matches?(pattern, path)
      File.fnmatch?(pattern, path, File::FNM_PATHNAME | File::FNM_EXTGLOB)
    end

    def excluded_path?(path)
      parts = path.split("/")
      EXCLUDED_TOP_LEVEL.include?(parts.first) || !(parts & EXCLUDED_PATH_PARTS).empty?
    end

    def relative(path)
      relative_from(@root, path)
    end

    def relative_from(root, path)
      path.delete_prefix("#{root}/")
    end

    def run(*command, chdir:)
      @out.puts "+ #{command.join(' ')}"
      system(*command, chdir: chdir)
    end
  end
end

if $PROGRAM_NAME == __FILE__
  gate = TrainRadar::DocsGate.new
  command = ARGV.fetch(0, "")
  success = case command
            when "sync" then gate.sync; true
            when "check" then gate.check
            when "check-impact" then gate.check_impact(staged: ARGV.include?("--staged"))
            when "pre-commit" then gate.pre_commit
            when "install-hooks" then gate.install_hooks
            when "brand-assets" then gate.brand_assets
            else
              warn "Usage: ruby scripts/docs_gate.rb {sync|check|check-impact [--staged]|pre-commit|install-hooks|brand-assets}"
              false
            end
  exit(success ? 0 : 1)
end
