#!/usr/bin/env ruby
# frozen_string_literal: true

require "set"
require "yaml"

module TrainRadar
  class ReferenceValidator
    EXPECTED_STOP_COUNT = 44
    EXPECTED_FIRST = "Москва-Павелецкая"
    EXPECTED_LAST = "Узуново"
    EXPECTED_NAMES = [
      "Москва-Павелецкая", "Дербеневская", "Тульская", "Верхние Котлы",
      "Нагатинская", "Варшавская", "Чертаново", "Котляково",
      "Бирюлёво-Товарная", "Бирюлёво-Пассажирская", "Булатниково",
      "Расторгуево", "Калинина", "Ленинская", "32 км", "Домодедово",
      "Взлётная", "Востряково", "Белые Столбы", "Данилово", "Барыбино",
      "Вельяминово", "Привалово", "Михнево", "Шугарово", "85 км", "Жилёво",
      "Ситенка", "Ступино", "Акри", "Белопесоцкий", "Кашира-Пассажирская",
      "Тесна", "Ожерелье", "Зубово", "Пурлово", "Колменка", "Топканово",
      "137 км", "Богатищево", "146 км", "Коровино", "Новосёлки", "Узуново"
    ].freeze
    ALLOWED_STOP_PATTERN_STATES = Set.new(
      %w[scheduled_stop pass_through conditional cancelled]
    ).freeze
    ALLOWED_DIRECTION_STATES = Set.new(
      %w[served not_served conditional pending]
    ).freeze
    FORBIDDEN_BRANCH_TOKENS = [
      "Авиационная",
      "Космос",
      "Аэропорт Домодедово",
      "Узловая"
    ].freeze
    REQUIRED_STOP_FIELDS = %w[
      stop_id canonical_name aliases ordinal coordinates kilometer object_type
      direction_service operational_status fare_status external_ids
      neighboring_rail_segments last_verified_at provenance confidence
      verification_status
    ].freeze
    REQUIRED_CPPK_SOURCE_REFS = %w[
      cppk_route_6001_2026-07-27
      cppk_route_6002_2026-07-27
      cppk_station_search_kotlyakovo_2026-07-27
    ].freeze
    KOTLYAKOVO_DECISION_REF = "owner_decision_kotlyakovo_2026-07-28"
    CPPK_MAP_SOURCE_REF = "cppk_interactive_map_2026-07-28"
    OWNER_DIRECTION_OBSERVATION_REF = "owner_observation_one_way_platforms_2026-07-28"
    REQUIRED_M0_VERIFICATION_SOURCE_REFS = (
      REQUIRED_CPPK_SOURCE_REFS + [KOTLYAKOVO_DECISION_REF, CPPK_MAP_SOURCE_REF]
    ).freeze

    def validate_registry(document)
      errors = []
      stops = document.is_a?(Hash) ? document["stops"] : nil
      return ["root.stops must be an array"] unless stops.is_a?(Array)

      validate_count_and_identity(stops, errors)
      validate_endpoints(stops, errors)
      validate_stop_pattern_states(document, errors)
      validate_special_stops(stops, errors)
      validate_planned_unused_stop(stops, errors)
      validate_required_fields(stops, errors)
      validate_forbidden_branches(stops, errors)
      validate_m0_source_verification(document, errors)
      errors
    end

    def validate_manifest(document)
      errors = []
      sources = document.is_a?(Hash) ? document["sources"] : nil
      return ["root.sources must be an array"] unless sources.is_a?(Array)

      identifiers = sources.map { |source| source["source_id"] }
      errors << "source_id values must be unique" unless identifiers.compact.uniq.length == sources.length

      required = %w[
        source_id owner license retrieved_at checksum update_method allowed_use
        prohibited_use verification_status
      ]
      sources.each_with_index do |source, index|
        missing = required.reject { |key| source.key?(key) }
        errors << "sources[#{index}] missing: #{missing.join(', ')}" unless missing.empty?
        unless source["url"] || source["identifier"]
          errors << "sources[#{index}] requires url or identifier"
        end
      end

      tutu = sources.find { |source| source["source_id"] == "tutu_manual_point_check" }
      if tutu
        prohibited = Array(tutu["prohibited_use"]).map(&:downcase)
        %w[import scheduler cache redistribution].each do |term|
          errors << "Tutu policy must forbid #{term}" unless prohibited.include?(term)
        end
      else
        errors << "source manifest must include tutu_manual_point_check"
      end

      validate_cppk_sources(sources, errors)
      errors
    end

    private

    def validate_count_and_identity(stops, errors)
      errors << "expected #{EXPECTED_STOP_COUNT} stops, got #{stops.length}" unless stops.length == EXPECTED_STOP_COUNT

      stop_ids = stops.map { |stop| stop["stop_id"] }
      errors << "stop_id values must be non-empty strings" unless stop_ids.all? { |id| id.is_a?(String) && !id.empty? }
      errors << "stop_id values must be unique" unless stop_ids.uniq.length == EXPECTED_STOP_COUNT
      expected_ids = (1..EXPECTED_STOP_COUNT).map { |ordinal| format("tr-pu-stop-%03d", ordinal) }
      errors << "stop_id values must match stable M0 slots" unless stop_ids == expected_ids

      ordinals = stops.map { |stop| stop["ordinal"] }
      errors << "ordinals must be exactly 1..44" unless ordinals == (1..EXPECTED_STOP_COUNT).to_a
      names = stops.map { |stop| stop["canonical_name"] }
      errors << "canonical names/order must match the approved 44-stop seed" unless names == EXPECTED_NAMES
    end

    def validate_endpoints(stops, errors)
      errors << "first stop must be #{EXPECTED_FIRST}" unless stops.first&.dig("canonical_name") == EXPECTED_FIRST
      errors << "last stop must be #{EXPECTED_LAST}" unless stops.last&.dig("canonical_name") == EXPECTED_LAST
    end

    def validate_stop_pattern_states(document, errors)
      states = Set.new(Array(document["allowed_stop_pattern_states"]))
      return if states == ALLOWED_STOP_PATTERN_STATES

      errors << "allowed_stop_pattern_states must be exactly #{ALLOWED_STOP_PATTERN_STATES.to_a.sort.join(', ')}"
    end

    def validate_special_stops(stops, errors)
      ["32 км", "85 км"].each do |name|
        stop = stops.find { |candidate| candidate["canonical_name"] == name }
        unless stop
          errors << "missing special stop #{name}"
          next
        end

        aliases = stop["aliases"]
        unless aliases.is_a?(Hash) &&
               aliases["items"].is_a?(Array) &&
               aliases["verification_status"] &&
               aliases["required_for_m0_verification"] == true
          errors << "#{name} must carry explicit aliases metadata"
        end

        service = stop["direction_service"]
        unless service.is_a?(Hash) &&
               service["special_handling"] == "direction_dependent" &&
               ALLOWED_DIRECTION_STATES.include?(service["towards_uzunovo"]) &&
               ALLOWED_DIRECTION_STATES.include?(service["towards_moscow"]) &&
               service["verification_status"]
          errors << "#{name} must carry direction-dependent service metadata"
        end
      end
    end

    def validate_required_fields(stops, errors)
      stops.each_with_index do |stop, index|
        missing = REQUIRED_STOP_FIELDS.reject { |key| stop.key?(key) }
        errors << "stops[#{index}] missing: #{missing.join(', ')}" unless missing.empty?
      end
    end

    def validate_forbidden_branches(stops, errors)
      searchable = stops.flat_map do |stop|
        [stop["canonical_name"]] + Array(stop.dig("aliases", "items")).map { |item| item["name"] }
      end.compact.join("\n").downcase

      FORBIDDEN_BRANCH_TOKENS.each do |token|
        errors << "forbidden branch token present: #{token}" if searchable.include?(token.downcase)
      end
    end

    def validate_m0_source_verification(document, errors)
      unless document["verification_status"] == "verified_m0_scope_with_planned_exception"
        errors << "root.verification_status must preserve the approved M0 planned exception"
      end

      verification = document["verification"]
      unless verification.is_a?(Hash)
        errors << "root.verification must describe the M0 source check"
        return
      end

      expected = {
        "verification_status" => "accepted_m0_scope",
        "registry_stop_count" => EXPECTED_STOP_COUNT,
        "current_carrier_route_stop_count" => 43,
        "identity_order_matches" => 43,
        "current_usable_stop_count" => 43,
        "planned_unused_stop_ids" => ["tr-pu-stop-008"],
        "source_refs" => REQUIRED_M0_VERIFICATION_SOURCE_REFS
      }
      expected.each do |key, value|
        errors << "verification.#{key} must equal #{value.inspect}" unless verification[key] == value
      end

      expected_automation = {
        "verification_status" => "accepted_read_only_source_enrichment",
        "source_ref" => CPPK_MAP_SOURCE_REF,
        "map_matched_stop_count" => 42,
        "map_schedule_only_stop_ids" => ["tr-pu-stop-015"],
        "map_missing_stop_ids" => [],
        "map_excluded_out_of_scope_object_names" => ["Аэропорт Домодедово", "Космос", "Авиационная"]
      }
      automation = verification["automation"]
      unless automation.is_a?(Hash)
        errors << "verification.automation must describe the CPPK map cross-check"
        return
      end
      expected_automation.each do |key, value|
        errors << "verification.automation.#{key} must equal #{value.inspect}" unless automation[key] == value
      end
      errors << "verification.automation.checked_at must be an ISO-8601 UTC timestamp" unless
        automation["checked_at"].is_a?(String) &&
        automation["checked_at"].match?(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/)

      errors << "verification.checked_at must be an ISO-8601 UTC timestamp" unless
        verification["checked_at"].is_a?(String) &&
        verification["checked_at"].match?(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/)
    end

    def validate_cppk_sources(sources, errors)
      carrier = sources.find { |source| source["source_id"] == "carrier_schedule" }
      unless carrier
        errors << "source manifest must include carrier_schedule"
        return
      end

      unless carrier["snapshot_refs"] == REQUIRED_CPPK_SOURCE_REFS
        errors << "carrier_schedule.snapshot_refs must identify all M0 CPPK checks"
      end

      REQUIRED_CPPK_SOURCE_REFS.each do |source_ref|
        source = sources.find { |candidate| candidate["source_id"] == source_ref }
        unless source
          errors << "source manifest missing #{source_ref}"
          next
        end

        checksum = source["checksum"]
        unless checksum.is_a?(String) && checksum.match?(/\Asha256:[0-9a-f]{64}\z/)
          errors << "#{source_ref} requires a SHA-256 checksum"
        end
      end

      map = sources.find { |source| source["source_id"] == CPPK_MAP_SOURCE_REF }
      unless map &&
             map["verification_status"] == "reviewed_live_surface" &&
             map["checksum"] == "sha256:ea7a151fb05e5fe6d8a388dd05dae50aae0675bf9236055629e32a894acda276"
        errors << "#{CPPK_MAP_SOURCE_REF} must preserve the reviewed projection checksum and status"
      end

      direction_observation = sources.find { |source| source["source_id"] == OWNER_DIRECTION_OBSERVATION_REF }
      unless direction_observation &&
             direction_observation["verification_status"] == "supplied_not_independently_verified"
        errors << "#{OWNER_DIRECTION_OBSERVATION_REF} must remain explicitly non-independent"
      end

      decision = sources.find { |source| source["source_id"] == KOTLYAKOVO_DECISION_REF }
      unless decision &&
             decision["verification_status"] == "verified_owner_decision" &&
             decision["checksum"] == "sha256:aefec3e4b2270f8dbbe2e1178f883fd73f2f706808fae3dd245080efe0a4cd35"
        errors << "#{KOTLYAKOVO_DECISION_REF} must preserve the approved checksum and status"
      end
    end

    def validate_planned_unused_stop(stops, errors)
      stop = stops.find { |candidate| candidate["stop_id"] == "tr-pu-stop-008" }
      return errors << "missing planned Котляково registry slot" unless stop

      usage = stop["project_usage"]
      unless stop["canonical_name"] == "Котляково" &&
             stop.dig("operational_status", "value") == "planned_not_built" &&
             stop.dig("operational_status", "source_ref") == KOTLYAKOVO_DECISION_REF &&
             usage.is_a?(Hash) &&
             usage["enabled"] == false &&
             usage["state"] == "planned_unused" &&
             usage["source_ref"] == KOTLYAKOVO_DECISION_REF
        errors << "Котляково must remain planned_not_built and disabled by owner decision"
      end
    end
  end

  module ReferenceData
    module_function

    def load_yaml(path)
      YAML.safe_load(File.read(path), [], [], false)
    end
  end
end

if $PROGRAM_NAME == __FILE__
  root = File.expand_path("..", __dir__)
  registry_path = File.join(root, "data/reference/paveletsky_uzunovo_stations.yaml")
  manifest_path = File.join(root, "data/reference/source_manifest.yaml")
  validator = TrainRadar::ReferenceValidator.new

  registry = TrainRadar::ReferenceData.load_yaml(registry_path)
  manifest = TrainRadar::ReferenceData.load_yaml(manifest_path)
  errors = validator.validate_registry(registry) + validator.validate_manifest(manifest)

  unless errors.empty?
    warn "Reference data validation failed:"
    errors.each { |error| warn "- #{error}" }
    exit 1
  end

  pending_count = registry.fetch("stops").count { |stop| stop["verification_status"] == "pending" }
  puts "PASS: corridor registry has 44 unique ordered stops and required scope guards"
  puts "PASS: M0 registry scope is 44/44 with Котляково fail-closed as planned_unused"
  puts "PASS: source manifest structure, CPPK snapshots, owner decision and Tutu restrictions"
  puts "INFO: #{pending_count}/44 records retain non-imported per-field status; root carrier verification is source-backed"
  puts "INFO: current carrier surface has 43 usable stops; Котляково activation requires a new approval"
end
