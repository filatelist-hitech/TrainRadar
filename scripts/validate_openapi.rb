#!/usr/bin/env ruby
# frozen_string_literal: true

require "set"
require "yaml"

module TrainRadar
  class OpenAPIValidator
    REQUIRED_PATHS = Set.new(%w[/healthz /v1/status /v1/live/events]).freeze
    POSITION_STATES = Set.new(
      %w[official_actual crowd_confirmed estimated stale_lost]
    ).freeze

    def validate(document)
      errors = []
      unless document.is_a?(Hash)
        return ["OpenAPI root must be a mapping"]
      end

      errors << "OpenAPI version must be 3.1.0" unless document["openapi"] == "3.1.0"
      paths = document["paths"]
      return errors + ["paths must be a mapping"] unless paths.is_a?(Hash)

      missing_paths = REQUIRED_PATHS - Set.new(paths.keys)
      errors << "missing paths: #{missing_paths.to_a.sort.join(', ')}" unless missing_paths.empty?

      event_responses = paths.dig("/v1/live/events", "get", "responses")
      unless event_responses.is_a?(Hash) && event_responses.key?("501") && event_responses.key?("200")
        errors << "reserved SSE endpoint must document 200 and M0 501"
      end

      schemas = document.dig("components", "schemas")
      return errors + ["components.schemas must be a mapping"] unless schemas.is_a?(Hash)

      states = Set.new(Array(schemas.dig("PositionState", "enum")))
      errors << "PositionState enum must contain exactly four truth states" unless states == POSITION_STATES
      errors << "ProjectStatus.registered_stops must be const 44" unless schemas.dig(
        "ProjectStatus", "properties", "registered_stops", "const"
      ) == 44

      event_required = Set.new(Array(schemas.dig("TrainPositionEvent", "required")))
      %w[state source_type contributors age_seconds confidence live_coverage].each do |field|
        errors << "TrainPositionEvent must require #{field}" unless event_required.include?(field)
      end

      errors
    end
  end

  module OpenAPIData
    module_function

    def load_yaml(path)
      YAML.safe_load(File.read(path), [], [], false)
    end
  end
end

if $PROGRAM_NAME == __FILE__
  root = File.expand_path("..", __dir__)
  document = TrainRadar::OpenAPIData.load_yaml(File.join(root, "openapi/openapi.yaml"))
  errors = TrainRadar::OpenAPIValidator.new.validate(document)

  unless errors.empty?
    warn "OpenAPI validation failed:"
    errors.each { |error| warn "- #{error}" }
    exit 1
  end

  puts "PASS: OpenAPI 3.1 M0 REST/SSE skeleton and truth-state contract"
end
