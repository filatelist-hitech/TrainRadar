# frozen_string_literal: true

require "minitest/autorun"
require_relative "../scripts/validate_reference_data"

class ReferenceValidatorTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  def setup
    @validator = TrainRadar::ReferenceValidator.new
    @registry = TrainRadar::ReferenceData.load_yaml(
      File.join(ROOT, "data/reference/paveletsky_uzunovo_stations.yaml")
    )
    @manifest = TrainRadar::ReferenceData.load_yaml(
      File.join(ROOT, "data/reference/source_manifest.yaml")
    )
  end

  def test_repository_fixtures_are_valid
    assert_empty @validator.validate_registry(@registry)
    assert_empty @validator.validate_manifest(@manifest)
  end

  def test_rejects_missing_stop
    registry = deep_copy(@registry)
    registry["stops"].pop

    assert_includes @validator.validate_registry(registry).join("\n"), "expected 44 stops"
  end

  def test_rejects_duplicate_stop_id_and_bad_ordinal
    registry = deep_copy(@registry)
    registry["stops"][1]["stop_id"] = registry["stops"][0]["stop_id"]
    registry["stops"][1]["ordinal"] = 1
    errors = @validator.validate_registry(registry).join("\n")

    assert_includes errors, "stop_id values must be unique"
    assert_includes errors, "ordinals must be exactly 1..44"
  end

  def test_rejects_missing_direction_metadata_for_special_stop
    registry = deep_copy(@registry)
    registry["stops"].find { |stop| stop["canonical_name"] == "32 км" }.delete("direction_service")

    assert_includes @validator.validate_registry(registry).join("\n"), "direction-dependent service metadata"
  end

  def test_rejects_unknown_stop_pattern_state
    registry = deep_copy(@registry)
    registry["allowed_stop_pattern_states"] << "invented_state"

    assert_includes @validator.validate_registry(registry).join("\n"), "allowed_stop_pattern_states"
  end

  def test_rejects_forbidden_branch_stop
    registry = deep_copy(@registry)
    registry["stops"][10]["canonical_name"] = "Аэропорт Домодедово"

    assert_includes @validator.validate_registry(registry).join("\n"), "forbidden branch token"
  end

  def test_rejects_unapproved_source_verification_shape
    registry = deep_copy(@registry)
    registry["verification_status"] = "verified"
    registry["verification"]["verification_status"] = "verified"
    registry["verification"]["identity_order_matches"] = 44
    registry["verification"]["planned_unused_stop_ids"] = []
    errors = @validator.validate_registry(registry).join("\n")

    assert_includes errors, "root.verification_status"
    assert_includes errors, "verification.verification_status"
    assert_includes errors, "verification.identity_order_matches"
    assert_includes errors, "verification.planned_unused_stop_ids"
  end

  def test_rejects_missing_cppk_snapshot_checksum
    manifest = deep_copy(@manifest)
    source = manifest["sources"].find do |candidate|
      candidate["source_id"] == "cppk_route_6001_2026-07-27"
    end
    source["checksum"] = nil

    assert_includes @validator.validate_manifest(manifest).join("\n"), "requires a SHA-256 checksum"
  end

  def test_rejects_missing_cppk_map_cross_check
    registry = deep_copy(@registry)
    registry["verification"].delete("automation")

    assert_includes(
      @validator.validate_registry(registry).join("\n"),
      "verification.automation must describe the CPPK map cross-check"
    )
  end

  def test_rejects_enabling_unbuilt_kotlyakovo
    registry = deep_copy(@registry)
    stop = registry["stops"].find { |candidate| candidate["stop_id"] == "tr-pu-stop-008" }
    stop["project_usage"]["enabled"] = true

    assert_includes(
      @validator.validate_registry(registry).join("\n"),
      "Котляково must remain planned_not_built and disabled"
    )
  end

  private

  def deep_copy(value)
    Marshal.load(Marshal.dump(value))
  end
end
