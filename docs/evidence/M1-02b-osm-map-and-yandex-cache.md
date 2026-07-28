# M1-02b — OSM map and cache-only schedule adapter

- Date: 2026-07-28
- Scope: only Москва-Павелецкая → Узуново, 44 registry slots / 43 enabled current map stops.

## OSM source admission

- Source: Geofabrik `central-fed-district-260726.osm.pbf`;
  `https://download.geofabrik.de/russia/central-fed-district-260726.osm.pbf`.
- Source snapshot/version: `central-fed-district-260726`; retrieved manually over HTTPS at
  `2026-07-28T00:28:17Z`.
- Licence and display attribution: `ODbL 1.0`, `© OpenStreetMap contributors`.
- Local runtime file: ignored `data/runtime/osm/central-fed-district-260726.osm.pbf`; it is not
  staged or committed.
- SHA-256: `4ab28c4d1bc42f890731bb8943b9f8158ca491d458f01442f5c9552476e49d9f`.
- Upstream MD5 cross-check: `541e19bb16f1c6386d4986854720305e`; byte size `870364656`.
- Reproduction: download the dated URL into the runtime path, run `shasum -a 256` and
  `make verify-m1-osm-runtime`. The compact Git projection is not a raw extract and must retain
  ODbL attribution.

## Automated evidence — PASS

- `make validate-data validate-m1-osm` — registry 44/44, 43 enabled projection stops, `Котляково`
  excluded from usable map scope, fixed boundary, forbidden branches and public OSM tile ban.
- `ruby test/validate_m1_osm_map_test.rb` — positive contract plus negative `Котляково`, branch and
  tile checks.
- `ruby scripts/validate_m1_osm_map.rb --require-runtime` — local runtime SHA-256 and byte-size.
- Existing deterministic Go unit tests cover `YANDEX_RASP_API_KEY` absent, TTL max/rejection, cache
  miss/hit/expiry/concurrency, upstream failure, secret-safe error/log/result and no persistence.

## Manual and network evidence — NOT_RUN

- No live request to Яндекс.Расписания was sent; no API key was configured for this task.
- No iOS/Android physical-device, accessibility/large-text or visual map review was run.
- No independent manual OSM topology/rail-object review was run; the admitted snapshot supports the
  bounded schematic projection only and is not called fully verified geometry.

## Secret boundary

`YANDEX_RASP_API_KEY` is read only by the backend process environment. It is absent from Flutter,
Git values, fixtures, errors, logs, evidence and public models. The adapter has no endpoint or
Flutter integration in this slice.
