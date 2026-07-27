#!/usr/bin/env ruby
# frozen_string_literal: true

require "digest"
require "json"
require "net/http"
require "time"
require "uri"
require "yaml"

module TrainRadar
  # Read-only verifier for public source surfaces. It deliberately never stores
  # source responses: CPPK terms are not an import licence, and Wikipedia is a
  # secondary discovery source rather than the registry authority.
  module CorridorSourceVerifier
    module_function

    CPPK_MAP_URL = URI("https://central-ppk.ru/new/imap/mapobjects.php")
    WIKIPEDIA_API_URL = URI("https://ru.wikipedia.org/w/api.php")
    CPPK_MAP_PARAMS = {
      "searchroute" => "Павелецкое направление",
      "searchcity" => "", "searchmetro" => "", "searchmck" => "",
      "searchmcd1" => "", "searchmcd2" => "", "searchmcd3" => "",
      "searchmcd4" => "", "searchparking" => "", "searchrexnp" => "",
      "searchrexwp" => "", "searchbm" => "", "searchturnstiles" => "",
      "searchvalidator" => "", "fromzone" => "", "tozone" => "",
      "searchstplus" => "", "xposo" => "53", "xpost" => "56",
      "yposo" => "36", "ypost" => "39"
    }.freeze

    # Exact display names on the CPPK map. They are aliases, never replacements
    # for the approved canonical registry names.
    CPPK_MAP_NAMES = {
      "Москва-Павелецкая" => "Москва (Павелецкий вокзал)",
      "Дербеневская" => "Дербеневкая",
      "Тульская" => "Тульская (ЗИЛ)",
      "Нагатинская" => "Нагатинская (Нижние Котлы)",
      "Варшавская" => "Варшавская (Коломенское)",
      "Бирюлёво-Товарная" => "Бирюлёво Товарная",
      "Бирюлёво-Пассажирская" => "Бирюлёво Пассажирская",
      "Данилово" => "Ост.пункт 52 км (Павелецкое направление)",
      "Взлётная" => "Взлетная",
      "85 км" => "Ост.пункт 85 км",
      "Кашира-Пассажирская" => "Кашира",
      "Зубово" => "Ост.пункт 121 км",
      "Колменка" => "Ост.пункт 131 км (Павелецкое направление)",
      "137 км" => "Ост.пункт 137 км (Павелецкое направление)",
      "146 км" => "Ост.пункт 146 км (Павелецкое направление)",
      "Новосёлки" => "Ост.пункт 152 км"
    }.freeze
    PLANNED_STOP = "Котляково"
    SCHEDULE_ONLY_STOPS = ["32 км"].freeze

    def load_registry(path)
      YAML.safe_load(File.read(path), [], [], false)
    end

    def fetch_cppk_map(http: Net::HTTP)
      query = URI.encode_www_form(CPPK_MAP_PARAMS)
      uri = URI("#{CPPK_MAP_URL}?#{query}")
      request = Net::HTTP::Post.new(uri)
      request.set_form_data("filterbytype" => "4")
      response = http.start(uri.host, uri.port, use_ssl: true, read_timeout: 30) { |client| client.request(request) }
      raise "CPPK map returned HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      response.body.force_encoding("UTF-8")
    end

    def parse_cppk_map(body)
      body.delete_prefix("\uFEFF").split("#@#").map do |entry|
        fields = entry.split("####")
        next unless fields.length >= 5

        id = entry[/\(ID:(\d+)\)/, 1]
        latitude = Float(fields[2]) rescue nil
        longitude = Float(fields[3]) rescue nil
        next unless id && latitude && longitude

        { "name" => fields[0].strip, "carrier_id" => id, "latitude" => latitude, "longitude" => longitude }
      end.compact
    end

    def map_projection(records)
      records.sort_by { |record| record.fetch("name") }
             .map { |record| record.slice("name", "carrier_id", "latitude", "longitude") }
    end

    def verify_map(stops, records)
      by_name = records.group_by { |record| record.fetch("name") }
      active_names = stops.map { |stop| stop.fetch("canonical_name") } - [PLANNED_STOP]
      expected_map_names = active_names - SCHEDULE_ONLY_STOPS
      matched = expected_map_names.map do |canonical_name|
        map_name = CPPK_MAP_NAMES.fetch(canonical_name, canonical_name)
        record = by_name[map_name]&.first
        record && { "canonical_name" => canonical_name }.merge(record)
      end.compact
      missing = expected_map_names - matched.map { |record| record.fetch("canonical_name") }
      expected_source_names = expected_map_names.map { |name| CPPK_MAP_NAMES.fetch(name, name) }

      {
        "current_route_stop_count" => active_names.length,
        "map_matched_stop_count" => matched.length,
        "map_matched_stops" => matched,
        "schedule_only_stops" => SCHEDULE_ONLY_STOPS,
        "missing_from_map" => missing,
        "planned_unused_stop" => PLANNED_STOP,
        "excluded_out_of_scope_map_objects" => records.map { |record| record.fetch("name") } - expected_source_names,
        "projection_checksum" => "sha256:#{Digest::SHA256.hexdigest(JSON.generate(map_projection(records)))}"
      }
    end

    def fetch_wikipedia_metadata(names, http: Net::HTTP)
      params = {
        "action" => "query", "format" => "json", "formatversion" => "2", "redirects" => "1",
        "prop" => "coordinates|info", "inprop" => "url", "titles" => names.join("|")
      }
      uri = URI("#{WIKIPEDIA_API_URL}?#{URI.encode_www_form(params)}")
      response = http.start(uri.host, uri.port, use_ssl: true, read_timeout: 30) { |client| client.get(uri) }
      raise "Wikipedia API returned HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      pages = JSON.parse(response.body).dig("query", "pages") || []
      pages.map do |page|
        next if page["missing"]

        coordinate = page.fetch("coordinates", []).find { |item| item["primary"] } || page.fetch("coordinates", []).first
        {
          "pageid" => page["pageid"], "title" => page["title"], "url" => page["fullurl"],
          "latitude" => coordinate && coordinate["lat"], "longitude" => coordinate && coordinate["lon"]
        }
      end.compact
    end

    def live_report(registry_path, http: Net::HTTP, now: Time.now.utc)
      stops = load_registry(registry_path).fetch("stops")
      report = { "checked_at" => now.iso8601, "status" => "completed_with_gaps" }

      begin
        report["cppk_interactive_map"] = verify_map(stops, parse_cppk_map(fetch_cppk_map(http: http)))
      rescue StandardError => e
        report["cppk_interactive_map"] = { "source_status" => "unavailable", "error" => e.message }
      end

      begin
        pages = fetch_wikipedia_metadata(stops.map { |stop| stop.fetch("canonical_name") }, http: http)
        report["wikipedia"] = {
          "source_status" => "reviewed_secondary_source",
          "page_count" => pages.length,
          "coordinate_count" => pages.count { |page| page["latitude"] && page["longitude"] },
          "pages" => pages
        }
      rescue StandardError => e
        report["wikipedia"] = { "source_status" => "unavailable", "error" => e.message }
      end

      report
    end
  end
end

if $PROGRAM_NAME == __FILE__
  root = File.expand_path("..", __dir__)
  report = TrainRadar::CorridorSourceVerifier.live_report(
    File.join(root, "data/reference/paveletsky_uzunovo_stations.yaml")
  )
  puts JSON.pretty_generate(report)
end
