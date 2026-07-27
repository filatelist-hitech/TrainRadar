# Test Strategy

Полная исполнимая спецификация: `.omx/plans/test-spec-trainradar-mvp.md`.

## Test pyramid by milestone

- M0: schema/data validator, negative scope tests, Go units/HTTP smoke, Flutter widget/analyze,
  OpenAPI YAML parse, Compose config, whitespace.
- M1: 44/44 registry accounting, 43 enabled-stop graph/map integration, planned-stop exclusion,
  OSM attribution and source-version snapshot tests.
- M2: consent state machine, local synthetic track, encrypted raw retention/delete integration;
  no public confirmed train.
- M3: contributor independence, replay/spoof/outlier/property tests and ambiguity simulations.
- M4: SSE contract/reconnect/backpressure/stale degradation and truth-state UI accessibility.
- M5: chronological replay evaluation, ETA p50/p90/p95, interval coverage and degraded datasets.
- M6: privacy/security review, field pilot, battery, crash-free, revocation/deletion evidence.

## Test classes

- unit: pure domain policies and state gates;
- property-based: coordinates, time/service date, confidence bounds, retention;
- contract: source adapters and OpenAPI/SSE;
- integration: PostGIS topology, raw encryption/deletion/KMS failure;
- replay/simulation: anonymized or synthetic tracks, gaps, outliers, spoofing, stale;
- UI/accessibility: semantics, text scaling, contrast, reduced motion, offline/error;
- field: physical iOS/Android and actual train corridor, always `NOT_RUN` until performed.

## Evidence standard

Each evidence artifact includes date, environment, exact command, exit code/result, relevant
versions, limitations and artifact checksum if data is involved. A skipped physical check is
`NOT_RUN`, never PASS.
