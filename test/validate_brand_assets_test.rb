# frozen_string_literal: true

require "minitest/autorun"
require "fileutils"
require "tmpdir"
require_relative "../scripts/validate_brand_assets"

class BrandAssetsValidatorTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  def setup
    @validator = TrainRadar::BrandAssetsValidator.new(ROOT)
    @manifest = TrainRadar::BrandAssets.load_manifest(ROOT)
  end

  def test_repository_brand_assets_are_valid
    assert_empty @validator.validate(@manifest)
  end

  def test_rejects_master_checksum_drift
    manifest = deep_copy(@manifest)
    manifest["master"]["sha256"] = "0" * 64

    assert_includes @validator.validate(manifest), "brand manifest must record the fixed approved master checksum"
  end

  def test_rejects_missing_ios_declaration
    manifest = deep_copy(@manifest)
    manifest["assets"].reject! { |asset| asset["platform"] == "ios" && asset["dimensions"] == [1024, 1024] }

    assert_includes @validator.validate(manifest), "brand manifest must declare the fixed iOS/Android asset matrix"
  end

  def test_rejects_missing_android_notification_declaration
    manifest = deep_copy(@manifest)
    manifest["assets"].reject! { |asset| asset["deployment_path"].end_with?("drawable-mdpi/ic_stat_trainradar.png") }

    assert_includes @validator.validate(manifest), "brand manifest must declare the fixed iOS/Android asset matrix"
  end

  def test_rejects_unapproved_web_surface
    temporary_root = File.join(Dir.tmpdir, "trainradar-brand-web-#{Process.pid}-#{object_id}")
    FileUtils.mkdir_p(File.join(temporary_root, "mobile/web"))
    errors = []
    TrainRadar::BrandAssetsValidator.new(temporary_root).send(:validate_platform_scope, @manifest, errors)

    assert_includes errors, "mobile/web exists but web/PWA is not an approved integrated platform"
  ensure
    FileUtils.remove_entry(temporary_root) if temporary_root && Dir.exist?(temporary_root)
  end

  private

  def deep_copy(value)
    Marshal.load(Marshal.dump(value))
  end
end
