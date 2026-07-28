# Data Dictionary

## Corridor registry

| Field | Type | Semantics |
|---|---|---|
| `stop_id` | string | stable TrainRadar ID, не external ID |
| `canonical_name` | string | rider-facing seed name |
| `aliases.items` | array | names with kind, sources and verification |
| `ordinal` | integer 1..44 | fixed corridor-registry slot; it is not proof that a stop is currently usable |
| `coordinates` | object | WGS84 lat/lon, source and status; null until verified |
| `kilometer` | object | confirmed railway mark only; name `137 км` is not enough |
| `object_type` | object | station/platform/tariff/technical classification |
| `direction_service` | object | boarding/alighting evidence per direction |
| `operational_status` | object | current infrastructure/passenger status |
| `project_usage` | object | M0 usage gate for a planned registry slot; `enabled: false` excludes it from routes, stop patterns and coverage |
| `fare_status` | object | current tariff status |
| `external_ids` | object | source-scoped identifiers, never merged by label alone |
| `neighboring_rail_segments` | object | internal graph refs and verification status |
| `provenance` | object | source refs and confidence basis |
| `verification_status` | enum | field-level `pending`, later `verified` or `rejected` by policy; registry-level scope can be accepted with an explicit planned exception |

M0 registry scope contains 44 fixed slots. Forty-three are currently usable carrier stops;
`tr-pu-stop-008` (Котляково) is an approved `planned_not_built` slot with
`project_usage.enabled: false` and remains excluded until official commissioning evidence and a
separate owner decision.

## M1 source admission

| Field | Type | Semantics |
|---|---|---|
| `m1_source_admission.status` | enum | `no_sources_admitted`, `partially_admitted` или `fully_admitted`; относится только к immutable import allowlist |
| `importable_source_refs` | array | только source IDs, прошедшие local admission gate; пустой список означает запрет import |
| `cache_only_source_refs` | array | source IDs, разрешённые только для временного API cache; они не являются dataset/snapshot |
| `required_source_roles` | array | exactly `schedule_cache` → `yandex_rasp_api`, затем `osm_geometry` → `osm_corridor_extract` |
| `admission_status` | enum | `blocked`, `cache_only` или `admitted`; blocked source обязан иметь конкретные reasons |
| `snapshot` | object | для admitted source: immutable reference и source version |
| `rights` | object | для admitted source: `import_allowed: true` и дата review |
| `cache_policy` | object | storage, TTL, offline rule и имя server-side environment variable без значения ключа |

Admitted OSM geometry требует SHA-256, `ODbL 1.0`, видимого attribution и явного запрета public
OSM tiles в production. Эти поля не создают geometry и не являются разрешением на external fetch.

Яндекс schedule data не получает `snapshot`: M1 использует только in-memory cache до 300 секунд,
сбрасываемый при остановке процесса. При offline/API failure data отсутствует, а не становится stale
offline schedule.

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
