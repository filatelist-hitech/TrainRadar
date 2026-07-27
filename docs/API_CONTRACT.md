# API Contract

Machine-readable skeleton: `openapi/openapi.yaml`.

## M0 endpoints

- `GET /healthz` — process health, no dependency/readiness claims.
- `GET /v1/status` — static startup status and explicit list of not implemented capabilities.
- `GET /v1/live/events` — reserved; M0 always returns `501 m0_realtime_not_implemented`.

## Future REST/SSE rules

- Version prefix `/v1`.
- UTC RFC 3339 timestamps, explicit service date/timezone in schedule resources.
- Error body has stable `code` and safe `message`; no raw data in details.
- SSE uses event type, opaque event ID, schema version and JSON payload.
- Client reconnects with `Last-Event-ID`; retention/replay window remains pending.
- Heartbeats contain no fabricated train state.

## Position contract

Every future position event includes `state`, `source_type`, `contributors`, `occurred_at`,
`age_seconds`, `confidence` and `live_coverage`. `live_coverage=true` is valid only for
`official_actual` or `crowd_confirmed`; the latter requires at least three independent capabilities.
An event is an aggregate train projection, never an individual GPS point.

## Compatibility

Additive optional fields are allowed within a schema version. Semantic changes to state,
freshness or contributor meaning require a new event schema version and migration note.
Generated clients are not introduced in M0.
