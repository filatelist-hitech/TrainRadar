# M1 source-admission boundary

- Date: 2026-07-28, Europe/Moscow
- Milestone/task: M1-01 — local fail-closed admission boundary for schedule and OSM geometry sources
- Scope: no external request, download, source import, geometry, map packaging, GPS or realtime work

> Historical M1-01 evidence. The schedule portion was superseded on 2026-07-28 by the owner-approved
> public/cache-only Yandex API contract in `M1-yandex-cache-contract.md`; immutable schedule import
> remains prohibited.

## Inputs and source state

`data/reference/source_manifest.yaml` preserves the M0 source references and introduces an empty
M1 allowlist. `carrier_schedule` remains blocked because licence/import rights and an immutable
lawful snapshot with version/checksum are absent. `osm_corridor_extract` remains blocked because
no versioned extract, replication/version, checksum, topology review or visible attribution has
been admitted. No source response or snapshot was fetched during this task.

Known source references retained by this gate:

- `approved_seed_spec`: SHA-256 `bc0f8ec80c9b8a96d02e36a4d5e40a12d2f675fafd174a0fd4b8fe48e3b0aecf`;
  project input, no redistribution right.
- `owner_decision_kotlyakovo_2026-07-28`: SHA-256
  `aefec3e4b2270f8dbbe2e1178f883fd73f2f706808fae3dd245080efe0a4cd35`; planned-unused slot only.
- `osm_corridor_extract`: licence policy recorded as `ODbL 1.0`, but status remains `pending`; it
  is not a versioned dataset and has no checksum yet.

## Automated verification

Local run on 2026-07-28, Europe/Moscow:

- `ruby test/validate_reference_data_test.rb` — PASS: 13 runs, 42 assertions.
- `make validate-data` — PASS: registry 44/44, 43 current usable stops, `Котляково` remains
  `planned_unused`; M1 allowlist is empty.
- `make check` — PASS: format, lint, Go tests, Flutter analyze/test, Ruby suite (39 runs,
  198 assertions), OpenAPI, `docker compose config --quiet`, brand gate and `make docs-check`.
- `make docs-sync` / `make docs-check` — PASS: generated documentation has no drift.
- `make check-staged` — first run stopped because the changed reference manifest required an
  explicit `docs/CORRIDOR_REGISTRY.md` update; the required human-owned document was then added
  to the same staged slice. Final rerun PASS: documentation impact, staged data/OpenAPI validators
  and the full Ruby suite (39 runs, 198 assertions) passed.

The validator asserts that M1 requires exactly the `schedule` and `osm_geometry` source roles;
a blocked source cannot appear in `importable_source_refs`; an admitted source requires immutable
snapshot version/reference, SHA-256, explicit licence and reviewed import rights. Admitted OSM also
requires `© OpenStreetMap contributors`, `ODbL 1.0` and a false public-tile production flag.

## Manual and physical checks

- Legal carrier rights and licence review: `NOT_RUN`.
- Source reviewer check for `32 км` and `85 км`: `NOT_RUN`.
- OSM extract/topology/attribution review: `NOT_RUN`.
- Offline map packaging and network-disabled mobile run: `NOT_RUN`.
- Physical iOS/Android run: `NOT_RUN`.

## Limitation and next gate

This artifact proves the immutable import reject path, not the quality or availability of an external
source. The next task is to obtain a versioned OSM geometry snapshot and implement the separate
cache-only Yandex schedule adapter without converting its responses into a dataset.
