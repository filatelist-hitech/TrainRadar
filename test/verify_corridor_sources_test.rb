# frozen_string_literal: true

require "minitest/autorun"
require_relative "../scripts/verify_corridor_sources"

class CorridorSourceVerifierTest < Minitest::Test
  def test_parses_cppk_map_object_projection
    body = "\uFEFFМосква (Павелецкий вокзал)########55.729802####37.640560####<div>(ID:30486)</div>#####a4de48####0"

    assert_equal [
      { "name" => "Москва (Павелецкий вокзал)", "carrier_id" => "30486", "latitude" => 55.729802, "longitude" => 37.64056 }
    ], TrainRadar::CorridorSourceVerifier.parse_cppk_map(body)
  end

  def test_verifies_the_full_registry_without_treating_source_gaps_as_failures
    stops = TrainRadar::CorridorSourceVerifier.load_registry(File.expand_path("../data/reference/paveletsky_uzunovo_stations.yaml", __dir__)).fetch("stops")
    names = stops.map { |stop| stop.fetch("canonical_name") }.to_h { |name| [name, name] }
    names.merge!(TrainRadar::CorridorSourceVerifier::CPPK_MAP_NAMES)
    records = names.reject { |name, _| ["Котляково", "32 км"].include?(name) }.map.with_index do |(_canonical, map_name), index|
      { "name" => map_name, "carrier_id" => (index + 1).to_s, "latitude" => 55.0 + index, "longitude" => 37.0 + index }
    end

    result = TrainRadar::CorridorSourceVerifier.verify_map(stops, records)

    assert_equal 43, result.fetch("current_route_stop_count")
    assert_equal 42, result.fetch("map_matched_stop_count")
    assert_equal ["32 км"], result.fetch("schedule_only_stops")
    assert_empty result.fetch("missing_from_map")
    assert_equal "Котляково", result.fetch("planned_unused_stop")
  end
end
