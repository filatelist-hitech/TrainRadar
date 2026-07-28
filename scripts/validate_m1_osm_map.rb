#!/usr/bin/env ruby
# frozen_string_literal: true

require "digest"
require "json"
require "yaml"

module TrainRadar
  class M1OSMMapValidator
    SHA256_PATTERN = /\Asha256:[0-9a-f]{64}\z/
    EXPECTED_RUNTIME_PATH = "data/runtime/osm/central-fed-district-260726.osm.pbf"
    EXPECTED_VERSION = "central-fed-district-260726"
    EXPECTED_BOUNDARY = { "south" => 54.45, "west" => 37.60, "north" => 55.80, "east" => 38.35 }.freeze
    FORBIDDEN_BRANCHES = ["Аэропорт Домодедово", "Космос", "Авиационная", "Узловая"].freeze
    PUBLIC_TILE_MARKERS = ["tile.openstreetmap.org", "{s}.tile.openstreetmap.org", "openstreetmap.org/{z}"].freeze

    def validate(registry:, manifest:, map:, mobile_source:, runtime_path: nil)
      errors = []
      source = Array(manifest["sources"]).find { |item| item["source_id"] == "osm_corridor_extract" }
      validate_source(source, errors)
      validate_map(registry, map, errors)
      validate_no_public_tiles(map, mobile_source, errors)
      validate_runtime(source, runtime_path, errors) if runtime_path
      errors
    end

    private

    def validate_source(source, errors)
      return errors << "osm_corridor_extract source is missing" unless source.is_a?(Hash)

      required = {
        "license" => "ODbL 1.0",
        "attribution" => "© OpenStreetMap contributors",
        "verification_status" => "verified_m1_import"
      }
      required.each { |field, value| errors << "OSM #{field} must equal #{value.inspect}" unless source[field] == value }
      errors << "OSM checksum must be SHA-256" unless source["checksum"].is_a?(String) && source["checksum"].match?(SHA256_PATTERN)
      errors << "OSM public tiles must be disabled" unless source.dig("rendering", "public_osm_tiles_production") == false
      snapshot = source["snapshot"]
      unless snapshot.is_a?(Hash) && snapshot["version"] == EXPECTED_VERSION &&
             snapshot["immutable_ref"] == source["url"] && snapshot["runtime_path"] == EXPECTED_RUNTIME_PATH &&
             snapshot["byte_size"].is_a?(Integer) && snapshot["upstream_md5"].match?(/\A[0-9a-f]{32}\z/)
        errors << "OSM snapshot must pin version, immutable URL, runtime path, size and upstream MD5"
      end
      errors << "OSM import rights must be reviewed" unless source.dig("rights", "import_allowed") == true && source.dig("rights", "reviewed_at").is_a?(String)
    end

    def validate_map(registry, map, errors)
      stops = Array(registry["stops"])
      enabled = stops.reject { |stop| stop["stop_id"] == "tr-pu-stop-008" }
      map_stops = Array(map["stops"])
      expected = enabled.map { |stop| stop.slice("stop_id", "ordinal", "canonical_name") }
      errors << "M1 map must contain exactly the 43 enabled registry stops" unless map_stops == expected
      planned = Array(map["planned_disabled_slots"])
      expected_planned = [{ "stop_id" => "tr-pu-stop-008", "ordinal" => 8, "canonical_name" => "Котляково", "status" => "planned_unused" }]
      errors << "Котляково must remain a single planned_unused map slot" unless planned == expected_planned
      errors << "map must be read-only" unless map["read_only"] == true && map["map_kind"] == "offline_schematic_rail_corridor"
      errors << "map source must use the pinned OSM version" unless map.dig("source", "version") == EXPECTED_VERSION
      errors << "map must visibly retain ODbL attribution" unless map.dig("source", "attribution") == "© OpenStreetMap contributors" && map.dig("source", "licence") == "ODbL 1.0"
      errors << "map corridor boundary must be the pinned Moscow-Paveletskaya to Uzunovo envelope" unless map.dig("corridor", "boundary") == EXPECTED_BOUNDARY
      errors << "map endpoints must be Moscow-Paveletskaya to Uzunovo" unless map.dig("corridor", "from") == "Москва-Павелецкая" && map.dig("corridor", "to") == "Узуново"
      errors << "map must exclude the forbidden branches" unless map.dig("corridor", "forbidden_branches") == FORBIDDEN_BRANCHES
      names = map_stops.map { |stop| stop["canonical_name"] }
      FORBIDDEN_BRANCHES.each { |name| errors << "forbidden branch appears in map stops: #{name}" if names.include?(name) }
    end

    def validate_no_public_tiles(map, mobile_source, errors)
      errors << "map source must disable production public OSM tiles" unless map.dig("source", "public_osm_tiles_production") == false
      PUBLIC_TILE_MARKERS.each do |marker|
        errors << "mobile map references forbidden public OSM tile marker #{marker}" if mobile_source.include?(marker)
      end
    end

    def validate_runtime(source, runtime_path, errors)
      return errors << "OSM runtime extract is missing: #{runtime_path}" unless File.file?(runtime_path)

      expected_checksum = source.fetch("checksum").delete_prefix("sha256:")
      errors << "OSM runtime checksum does not match metadata" unless Digest::SHA256.file(runtime_path).hexdigest == expected_checksum
      expected_size = source.dig("snapshot", "byte_size")
      errors << "OSM runtime byte size does not match metadata" unless File.size(runtime_path) == expected_size
    end
  end
end

if $PROGRAM_NAME == __FILE__
  root = File.expand_path("..", __dir__)
  runtime_path = ARGV == ["--require-runtime"] ? File.join(root, TrainRadar::M1OSMMapValidator::EXPECTED_RUNTIME_PATH) : nil
  registry = YAML.safe_load(File.read(File.join(root, "data/reference/paveletsky_uzunovo_stations.yaml")), [], [], false)
  manifest = YAML.safe_load(File.read(File.join(root, "data/reference/source_manifest.yaml")), [], [], false)
  map = JSON.parse(File.read(File.join(root, "mobile/assets/data/m1_corridor_map.json")))
  mobile_source = File.read(File.join(root, "mobile/lib/main.dart"))
  errors = TrainRadar::M1OSMMapValidator.new.validate(
    registry: registry, manifest: manifest, map: map, mobile_source: mobile_source, runtime_path: runtime_path
  )
  abort(errors.join("\n")) unless errors.empty?

  puts "PASS: M1 OSM map metadata, 43-stop scope, boundary and tile policy are valid"
  puts "PASS: OSM runtime checksum and byte size match" if runtime_path
end
