# M1 Yandex Schedule cache-only contract

- Date: 2026-07-28, Europe/Moscow
- Milestone/task: M1-02a — public read-only schedule contract without schedule import
- Scope: source-policy and validator update only; no API key, network request, API response, map
  implementation, GPS, account or M2+ work

## Decision and terms boundary

The owner authorized public/free M1 read-only map/schedule access while keeping M2–M6 invite-only.
The reviewed Yandex Schedule API terms require a public/free surface, attribution and restrict data
storage to temporary cache. The project contract is deliberately stricter where terms are not
numeric: response storage is in-memory only, TTL is at most 300 seconds, disk persistence is false
and schedule is unavailable when network/API is unavailable.

The required UI attribution is exactly:

`Данные предоставлены сервисом Яндекс.Расписания`

The API key is named only as `YANDEX_RASP_API_KEY`; no key value was read, written, requested or
stored. It must be configured server-side only during a later implementation task.

## Automated verification

Local run on 2026-07-28, Europe/Moscow:

- `ruby test/validate_reference_data_test.rb` — PASS: 14 runs, 46 assertions.
- `make validate-data` — PASS: registry 44/44, 43 current usable stops and cache-only policy valid.
- `make docs-sync` / `make docs-check` — PASS: generated documentation has no drift.
- `make check` — PASS: format, lint, Go tests, Flutter analyze/test, Ruby suite (40 runs,
  202 assertions), OpenAPI, `docker compose config --quiet`, brand gate and docs check.
- `make check-staged` — `NOT_RUN`; no commit/staging was requested for this task.

The validator rejects a cache-only source in immutable import allowlist and rejects Yandex cache
policy that persists to disk or serves schedule offline.

## Manual and physical checks

- Current Yandex API key activation and request/response contract: `NOT_RUN`.
- Mandatory attribution visibility on public client: `NOT_RUN`.
- Network loss and cache expiry behaviour on iOS/Android: `NOT_RUN`.
- OSM extract/topology/attribution review: `NOT_RUN`.
- GPS, real tracks, matching, ETA and M2–M6 capabilities: `NOT_RUN` and out of scope.

## Limitation and next gate

No schedule data is currently stored or served by TrainRadar. The next bounded task obtains a
versioned OSM corridor extract and implements the public M1 read-only client with the cache-only
Yandex adapter, using a locally configured server-side key.
