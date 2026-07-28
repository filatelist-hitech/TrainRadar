# M1 Yandex Schedule cache-only contract

- Date: 2026-07-28, Europe/Moscow
- Milestone/task: M1-02b — local server-side read-only adapter for the future backend use case
- Scope: source-policy boundary plus local Go adapter/tests; no API key value, network request,
  API response fixture, HTTP endpoint, map implementation, GPS, account or M2+ work

## Decision and terms boundary

The owner authorized public/free M1 read-only map/schedule access while keeping M2–M6 invite-only.
The reviewed Yandex Schedule API terms require a public/free surface, attribution and restrict data
storage to temporary cache. The project contract is deliberately stricter where terms are not
numeric: response storage is in-memory only, TTL is at most 300 seconds, disk persistence is false
and schedule is unavailable when network/API is unavailable.

The required UI attribution is exactly:

`Данные предоставлены сервисом Яндекс.Расписания`

The API key is named only as `YANDEX_RASP_API_KEY`; no key value was read, written, requested or
stored. `backend/internal/schedule/yandex` reads it only from the backend process environment and
keeps it in a private adapter field. It is absent from the adapter response, errors and its
constant-label logger interface; `.env.example`, Flutter and public API surfaces are unchanged.

The adapter accepts only a positive in-memory TTL up to 300 seconds. A cache hit returns an isolated
copy with `hit` metadata; miss and expiry invoke only the injected upstream interface. Missing key,
missing upstream client or upstream error return explicit safe `unavailable` and never fake/stale
schedule data. There is no HTTP implementation, refresh job, filesystem access, snapshot, DB cache
or offline schedule path in this slice.

## Automated verification

Local M1-02b run on 2026-07-28, Europe/Moscow:

- `cd backend && go test ./...` — PASS.
- `cd backend && go test -race ./...` — PASS; concurrent cache test passed with the race detector.
- `make validate-data` — PASS: registry 44/44, 43 current usable stops and cache-only policy valid.
- `make docs-sync` / `make docs-check` — PASS: generated documentation has no drift.
- `make check-staged` — PASS: staged Go and Ruby tests, documentation impact and generated-doc
  synchronization passed.
- Deterministic unit coverage includes missing key, valid/max TTL, rejected TTL >300 seconds,
  cache miss/hit/expiry, upstream error, concurrent calls, credential redaction and no file/
  database persistence dependency.

The validator rejects a cache-only source in immutable import allowlist and rejects Yandex cache
policy that persists to disk or serves schedule offline.

## Manual and physical checks

- Current Yandex API key activation and live request/response probe: `NOT_RUN` (no key read and no
  separate owner permission for a real network request).
- Mandatory attribution visibility on public client: `NOT_RUN`.
- Network loss and cache expiry behaviour on iOS/Android: `NOT_RUN`.
- OSM extract/topology/attribution review: `NOT_RUN`.
- GPS, real tracks, matching, ETA and M2–M6 capabilities: `NOT_RUN` and out of scope.

## Limitation and next gate

No schedule data is currently stored or served by TrainRadar. The adapter is not wired to an HTTP
endpoint or a concrete network client. The active `next_action` remains M1-02b for the separate
versioned OSM/map portion; later runtime enablement still requires a separate owner permission for
a real probe and a locally configured server-side key.
