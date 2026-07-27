# Data Quality

## Source priority

Priority is not silent overwrite:

1. fresh signed/contracted official telemetry → `official_actual`;
2. at least three independent plausible capabilities in agreement → `crowd_confirmed`;
3. schedule/graph/model projection → `estimated`;
4. expired or disconnected evidence → `stale_lost`.

Every conflict is retained as evidence and emitted with the winning source type. Fresh official
data outranks crowd; implausible official points are quarantined, not silently trusted.

## Registry usability

M0 registry scope is accepted as 44 fixed slots: 43 current carrier stops plus Котляково as an
approved planned-unused slot. `tr-pu-stop-008` has `operational_status: planned_not_built` and
`project_usage.enabled: false`; validators must fail closed if it appears in a route, trip stop
pattern or coverage calculation. Acceptance of registry scope does not verify its pending external
properties (geometry, kilometre, tariff, direction rules or external IDs). Activation requires
official commissioning evidence and a separate owner decision.

## M1 source admission quality gate

Ни schedule, ни OSM geometry не могут попасть в offline graph/map по одному display-source check.
`m1_source_admission` fail-closed: blocked source не включается в `importable_source_refs`; admitted
source требует immutable version/reference, SHA-256, reviewed import rights и `verified_m1_import`.
Для OSM обязательны `ODbL 1.0`, visible attribution и запрет public OSM tiles как production backend.
При checksum/right/topology failure слой не обновляется: остаётся последняя valid version либо слой
отключается. На 2026-07-28 список admitted sources пуст.

## Freshness buckets

Each adapter declares a measured `source_ttl`. Until feed cadence is known, no numeric TTL is
approved.

- `fresh`: age ≤ `source_ttl`;
- `aging`: `source_ttl` < age ≤ `3 × source_ttl`;
- `stale_lost`: age > `3 × source_ttl`, source disconnected, or clock invalid;
- `unknown`: no trustworthy timestamp.

Age is always visible. Only `fresh` actual/confirmed data may count as live coverage.

## Confidence calculation

Planned transparent policy, not implemented in M0:

```text
base = 0.30*freshness + 0.25*source_agreement + 0.20*map_fit
     + 0.15*motion_plausibility + 0.10*trip_identity
confidence = min(source_state_cap, base) × ambiguity_penalty
```

All components are 0..1 and stored with `policy_version`. Caps and thresholds require replay
calibration before M4; the formula never upgrades a state. A high-confidence estimate remains
`estimated`.

## Contributor threshold and independence

`crowd_confirmed` requires ≥3 active install-capability that pass:

- distinct rotating capability roots;
- no replayed nonce/window;
- plausible time/position/speed;
- agreement on the same trip candidate;
- anti-collusion signals without collecting stable advertising IDs.

One device may generate many observations but contributes at most one vote in a window.

## Outlier rejection

Reject or quarantine invalid coordinates, non-monotonic device time, duplicate nonce, impossible
speed/acceleration, teleport beyond reachable rail distance, poor declared accuracy, off-corridor
candidate and conflicting service date. Numeric thresholds remain pending until synthetic/replay
evaluation; they are versioned configuration, not hidden constants.

## Map-matching uncertainty

Persist candidate segments, top score, runner-up score, distance residual and graph version.
Parallel-track ambiguity below an approved margin yields `unmatched/estimated`, never a precise
track claim.

## Conflict and degradation

- Fresh official vs crowd conflict: public official state, conflict metric/incident, crowd retained.
- Official stale + crowd confirmed: explicit state transition to `crowd_confirmed`.
- Contributors fall below three: no confirmed continuation; estimate or stale based on model horizon.
- Graph/source version mismatch: fail closed for matching.
- No trustworthy time: exclude from live coverage.

## Privacy quality gate

Public outputs are train aggregates. No response, log, metric label or trace may include an
individual exact coordinate, raw capability or raw observation ID.
