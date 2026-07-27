# Data Dictionary

## Corridor registry

| Field | Type | Semantics |
|---|---|---|
| `stop_id` | string | stable TrainRadar ID, не external ID |
| `canonical_name` | string | rider-facing seed name |
| `aliases.items` | array | names with kind, sources and verification |
| `ordinal` | integer 1..44 | seed corridor order |
| `coordinates` | object | WGS84 lat/lon, source and status; null until verified |
| `kilometer` | object | confirmed railway mark only; name `137 км` is not enough |
| `object_type` | object | station/platform/tariff/technical classification |
| `direction_service` | object | boarding/alighting evidence per direction |
| `operational_status` | object | current infrastructure/passenger status |
| `fare_status` | object | current tariff status |
| `external_ids` | object | source-scoped identifiers, never merged by label alone |
| `neighboring_rail_segments` | object | internal graph refs and verification status |
| `provenance` | object | source refs and confidence basis |
| `verification_status` | enum | `pending`, later `verified` or `rejected` by policy |

## Public position

| Field | Meaning |
|---|---|
| `state` | one of four truth states |
| `source_type` | official/crowdsourced/model source |
| `contributors` | independent capability count, never participant identities |
| `age_seconds` | age at response/event creation |
| `confidence` | 0..1 score with internal breakdown/version |
| `live_coverage` | true only for official actual or crowd confirmed |
| `occurred_at` | source event time in UTC |
| `calculated_at` | derived-state calculation time |

## Time

Persist UTC instants plus original timezone and `ServiceDate`. Values after midnight may belong to
the previous service day. No naive local timestamps.

## Raw encrypted observation

Raw store accepts `observation_id`, ciphertext, nonce, wrapped DEK, `observed_at`, `expires_at`.
Plain latitude/longitude columns and public joins to install capability are forbidden.
