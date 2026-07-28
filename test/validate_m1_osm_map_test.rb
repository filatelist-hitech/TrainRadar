# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "yaml"
require_relative "../scripts/validate_m1_osm_map"

class M1OSMMapValidatorTest < Minitest::Test
  def setup
    @root = File.expand_path("..", __dir__)
    @registry = YAML.safe_load(File.read(File.join(@root, "data/reference/paveletsky_uzunovo_stations.yaml")), [], [], false)
    @manifest = YAML.safe_load(File.read(File.join(@root, "data/reference/source_manifest.yaml")), [], [], false)
    @map = JSON.parse(File.read(File.join(@root, "mobile/assets/data/m1_corridor_map.json")))
    @mobile_source = File.read(File.join(@root, "mobile/lib/main.dart"))
  end

  def test_pinned_m1_map_contract_is_valid
    assert_empty validate
  end

  def test_rejects_kotlyakovo_in_usable_map
    @map["stops"] << { "stop_id" => "tr-pu-stop-008", "ordinal" => 8, "canonical_name" => "Котляково" }

    assert_includes validate.join("\n"), "43 enabled registry stops"
  end

  def test_rejects_forbidden_branch_and_public_tile
    @map["corridor"]["forbidden_branches"].pop
    @mobile_source += "https://tile.openstreetmap.org/{z}/{x}/{y}.png"

    errors = validate.join("\n")
    assert_includes errors, "forbidden branches"
    assert_includes errors, "forbidden public OSM tile"
  end

  private

  def validate
    TrainRadar::M1OSMMapValidator.new.validate(
      registry: @registry, manifest: @manifest, map: @map, mobile_source: @mobile_source
    )
  end
end
