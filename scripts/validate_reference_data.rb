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

    def validate_registry(document)
      errors = []
      stops = document.is_a?(Hash) ? document["stops"] : nil
      return ["root.stops must be an array"] unless stops.is_a?(Array)

      validate_count_and_identity(stops, errors)
      validate_endpoints(stops, errors)
      validate_stop_pattern_states(document, errors)
      validate_special_stops(stops, errors)
      validate_required_fields(stops, errors)
      validate_forbidden_branches(stops, errors)
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
  puts "PASS: source manifest structure and Tutu usage restrictions"
  puts "INFO: #{pending_count}/44 stop records remain verification_status=pending"
end
