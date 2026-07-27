# Observability

## Goals

Доказать freshness, state transitions, source health, privacy deletion и quality degradation без
утечки exact GPS.

## Structured logs

Allowed: request ID, route template, status, latency, source/version IDs, aggregate state,
error code. Forbidden: latitude/longitude, raw observation/capability/invite, full IP, trip
membership and ciphertext. Logs use allowlisted fields, not arbitrary payload dumps.

## Metrics

- `trainradar_source_freshness_seconds{source_id}`;
- `trainradar_position_state_total{state}`;
- `trainradar_live_coverage_ratio`;
- `trainradar_contributor_count_bucket` with privacy-safe buckets;
- `trainradar_match_ambiguous_total`;
- `trainradar_sse_connections` and reconnect/error counters;
- `trainradar_raw_delete_lag_seconds`, failures and key-destruction failures;
- API latency/error saturation;
- mobile crash-free sessions and battery test results (external evidence).

High-cardinality vehicle/trip/capability labels запрещены.

## Traces

Trace spans may carry source version and derived aggregate identifiers only. Raw ingest span is
redacted at boundary. Sampling must not select based on exact location or participant.

## Alerts and SLO candidates

M0 не утверждает production SLO. До M4 нужны measured targets для freshness, false confirmation,
SSE availability и delete lag. Any expired raw record or key-destruction failure is security alert,
not a normal latency percentile.

## M0 evidence

Health endpoint and local tests prove process skeleton only. They do not prove DB readiness,
realtime delivery, location correctness or production observability.
