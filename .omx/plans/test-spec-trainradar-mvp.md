# TrainRadar MVP Test Specification

- Status: Approved
- Scope: M0–M6 verification contract
- Current executable subset: M0
- Date: 2026-07-28

## Evidence protocol

Every run records command, timestamp/timezone, versions, exit result, input checksum/version and
limitations. Physical device, real GPS, train ride or participant study stays `NOT_RUN` until
actually executed. Test data must be synthetic or irreversibly anonymized and approved.

## M0 suites

### DATA-M0

| ID | Test | Expected |
|---|---|---|
| DATA-001 | load corridor YAML | syntactically valid mapping |
| DATA-002 | stop count | exactly 44 |
| DATA-003 | `stop_id` | 44 non-empty unique IDs |
| DATA-004 | ordinals | ordered exactly 1..44 |
| DATA-005 | endpoints | first Москва-Павелецкая, last Узуново |
| DATA-006 | special aliases metadata | `32 км`/`85 км` explicit and verification-required |
| DATA-007 | special direction metadata | both directions present, `direction_dependent` |
| DATA-008 | stop-pattern enum | exact four allowed states |
| DATA-009 | forbidden branches | no airport/Big Ring/Uzlovaya stop token |
| DATA-010 | required fields | provenance/coordinate/status placeholders present |
| DATA-011 | manifest schema | owner/licence/retrieval/checksum/update/use/status keys |
| DATA-012 | Tutu constraints | import/scheduler/cache/redistribution explicitly forbidden |
| DATA-013 | planned `Котляково` | slot 8 retained; `planned_not_built`; project usage disabled |
| DATA-014 | activation guard | owner decision checksum present; enabling planned station fails |
| DATA-015 | read-only CPPK map cross-check | 42 map matches, `32 км` schedule-only, airport branch objects excluded |
| DATA-NEG | mutate count/ID/ordinal/state/special/branch | validator fails each mutation |

Command: `make validate-data` and `ruby test/validate_reference_data_test.rb`.

### GO-M0

| ID | Test | Expected |
|---|---|---|
| GO-001 | `go test ./...` | all packages pass |
| GO-002 | truth-state table | actual/confirmed live; estimate/stale/unknown not live |
| GO-003 | crowd threshold | exactly minimum 3 |
| GO-004 | raw policy boundary | retention >24h rejected |
| GO-005 | health handler | 200 and safe body |
| GO-006 | reserved SSE | 501 and explicit M0 error |
| GO-007 | `go vet` + gofmt gate | clean |

### FLUTTER-M0

| ID | Test | Expected |
|---|---|---|
| FL-001 | `flutter analyze` | no issues |
| FL-002 | widget smoke | corridor, 44, pending data, GPS off visible |
| FL-003 | dependency/manifest inspection | no location SDK/permissions/background capability |
| FL-004 | iOS simulator/build | run if available; signing account not required |
| FL-005 | Android debug build | run if SDK available |
| FL-PHY | physical iOS/Android | `NOT_RUN` in M0 |
| GPS-PHY | actual location collection | `NOT_RUN` and prohibited in M0 |

### CONTRACT/INFRA-M0

- OpenAPI YAML parses; state enum and reserved SSE exist.
- Backend handler behavior matches 200/501 skeleton.
- `docker compose config --quiet` passes.
- Optional `docker compose up -d --wait` proves both dev DB health; it does not prove encryption.
- SQL raw constraint caps `expires_at`; actual delete/KMS remains `NOT_RUN`.
- `git diff --check` passes; no commit exists.

## M1 suites

- registry completeness: exact 44 IDs; operational graph/map contain the 43 enabled current stops;
- explicit exclusion property: `Котляково` cannot enter routing, stop patterns or coverage while disabled;
- topology degree/direction and endpoint properties;
- forbidden branch and bounding corridor tests;
- reproducible OSM extract checksum/version/licence/attribution;
- cache-only Яндекс API contract: public/free surface, mandatory attribution, server-side key,
  in-memory TTL ≤300 seconds, no disk persistence and no schedule when offline;
- sourced stop-pattern contract fixtures for ordinary/accelerated/express, когда их возвращает API;
- map golden/accessibility/offline tests and manual source/map review.

Exit: 44/44 registry slots accounted for, 43 enabled current stops across operational layers,
planned `Котляково` visibly fail-closed; offline map не выдаёт расписание, а online schedule всегда
показывает attribution и freshness. Не требуется immutable schedule snapshot.

## M2 suites

- consent state-machine property tests: no observation without active purpose grant;
- foreground/background separation, revoke and pending-upload purge;
- synthetic coordinate/time/property tests;
- encryption round-trip only in controlled test KMS;
- raw expiry boundary, deletion, key destruction, replica/backup policy;
- public API scan proves no individual point;
- physical iOS/Android permission lifecycle and battery tests.

Exit: single rider remains private/local or encrypted; never `crowd_confirmed`.

## M3 suites

### Hostile simulations

1. one device floods observations;
2. cloned/replayed capability;
3. three collocated spoofers;
4. time rollback/teleport/impossible acceleration;
5. wrong trip chosen near crossing;
6. parallel tracks with near-identical geometry;
7. gaps/out-of-order batches;
8. source version mismatch.

Properties: no false confirmation under approved fixtures, deterministic versioned output,
uncertain candidates unmatched, contributor count privacy-safe.

## M4 suites

- OpenAPI/SSE schema contract and backward compatibility;
- reconnect with valid/expired/unknown `Last-Event-ID`;
- duplicate/order/heartbeat/backpressure;
- source transition actual→crowd→estimate→stale;
- TTL boundary and clock skew;
- mobile offline/resume/background network lifecycle;
- semantics, large text, contrast, reduced motion and non-color state mapping;
- privacy scan for event/log/metric leakage.

## M5 suites

Datasets split chronologically and by service conditions. Report:

- station arrival precision/recall;
- ETA MAE p50/p90/p95;
- interval coverage and average width;
- errors for fresh/crowd/estimated/stale transitions;
- comparison to schedule-only baseline;
- false incident rate;
- calibration drift by source/data version.

No production gate based only on mean error.

## M6 suites

- invite issuance/revocation and abuse rate limits;
- deletion/key-destruction and incident response drill;
- privacy/security review with resolved critical findings;
- physical iOS/Android corridor runs;
- background battery and crash-free sessions;
- consent grant/revoke comprehension;
- pilot coverage and false-confirmed-train monitoring;
- rollback to read-only and invite revocation.

## Stop conditions

Stop the milestone on privacy leakage, expired raw retention, source/licence ambiguity, corridor
count drift, any false `crowd_confirmed` in mandatory hostile fixtures, or missing reproducible
evidence. Fix/review inside the same milestone; do not advance by relabelling `NOT_RUN` as PASS.
