# QA Matrix

| Requirement | Automated evidence | Manual/physical | M0 status |
|---|---|---|---|
| 44 unique IDs and ordinals 1..44 | `make validate-data` | carrier + owner decision | registry 44/44 PASS; usable 43; `Котляково` disabled |
| exact endpoints | validator negative tests | carrier route both directions | automated PASS; carrier PASS |
| aliases/direction for 32/85 | schema guard | route views, owner direction assertion | checkpoints PASS; one-way platform assertion recorded as `supplied_not_independently_verified` |
| source manifest provenance | manifest/checksum guards + live CPPK map verifier | rights and infrastructure-source review | 43/43 route, 42/43 map, 1 `schedule_only`; rights/source remain M1 inputs |
| M1 OSM source and read-only map | `make validate-m1-osm`, `make verify-m1-osm-runtime`, Ruby negative tests and Flutter widget test: checksum/size metadata, ODbL, boundary, 44/43, `Котляково`, forbidden branches, public-tile ban and visible attribution | inspect source/retrieval, visual iOS/Android map review | automated PASS; source/visual device review `NOT_RUN` |
| public M1 schedule contract | source-policy validator + deterministic Go tests: missing key, TTL boundary, miss/hit/expiry, upstream failure, mutex cache, secret-safe error/log/response and no persistence dependency | real Yandex live probe, public attribution and network-loss review | adapter contract PASS; client/API/manual review `NOT_RUN` |
| allowed stop-pattern states | exact enum test | real trip patterns | enum PASS; patterns `NOT_RUN` |
| forbidden branches absent | exact seed/scope negative test + map-object exclusion | map review | automated PASS; three airport-branch map objects excluded |
| Go skeleton | `go vet`, `go test`, race/build, HTTP smoke | process smoke | PASS |
| Flutter M1 map | analyze/widget + APK/iOS simulator builds; packaged asset only | physical iOS/Android + accessibility/large-text visual review | automated PASS; physical/visual `NOT_RUN` |
| Brand assets concept 05-soft-3d | `make brand-assets`: SHA-256, image dimensions/alpha, iOS catalog, Android XML/manifest and deployment drift | square/round/maskable/small-size inspection; physical iOS/Android launcher | automated PASS; visual asset PASS; physical `NOT_RUN` |
| OpenAPI skeleton | semantic validator + HTTP tests | client review | PASS |
| Compose separation | config + clean runtime health | DB schema queries | PASS |
| raw retention ≤24h | Go unit + SQL rejection | KMS/delete/backup drill | policy PASS; drill `NOT_RUN` |
| truth-state separation | Go unit + schema enum | comprehension test | unit PASS; user test `NOT_RUN` |
| no real GPS in M0 | dependency/permission review | device network inspection | static review PASS; physical `NOT_RUN` |
| single next_action | YAML structural inspection | owner review | PASS; M1 authorized by owner on 2026-07-28 |

Structural validation cannot upgrade a source fact. It does enforce the approved fail-closed state:
`Котляково` remains in registry slot 8 but cannot enter active stop patterns or coverage.
