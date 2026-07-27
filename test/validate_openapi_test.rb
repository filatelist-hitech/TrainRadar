# frozen_string_literal: true

require "minitest/autorun"
require_relative "../scripts/validate_openapi"

class OpenAPIValidatorTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  def setup
    @validator = TrainRadar::OpenAPIValidator.new
    @document = TrainRadar::OpenAPIData.load_yaml(File.join(ROOT, "openapi/openapi.yaml"))
  end

  def test_repository_contract_is_valid
    assert_empty @validator.validate(@document)
  end

  def test_rejects_missing_m0_not_implemented_response
    document = deep_copy(@document)
    document.dig("paths", "/v1/live/events", "get", "responses").delete("501")

    assert_includes @validator.validate(document).join("\n"), "document 200 and M0 501"
  end

  def test_rejects_mixed_or_extra_truth_state
    document = deep_copy(@document)
    document.dig("components", "schemas", "PositionState", "enum") << "unknown"

    assert_includes @validator.validate(document).join("\n"), "exactly four truth states"
  end

  private

  def deep_copy(value)
    Marshal.load(Marshal.dump(value))
  end
end
