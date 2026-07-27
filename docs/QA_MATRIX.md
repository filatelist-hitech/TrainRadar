# QA Matrix

| Requirement | Automated evidence | Manual/physical | M0 status |
|---|---|---|---|
| 44 unique IDs and ordinals 1..44 | `make validate-data` | source comparison | automated PASS; source `pending` |
| exact endpoints | validator negative tests | carrier/infrastructure check | automated PASS; source `pending` |
| aliases/direction for 32/85 | schema guard | exact service rules | data `pending` |
| allowed stop-pattern states | exact enum test | real trip patterns | enum PASS; patterns `NOT_RUN` |
| forbidden branches absent | exact seed/scope negative test | map review | automated PASS; map `NOT_RUN` |
| Go skeleton | `go vet`, `go test`, race/build, HTTP smoke | process smoke | PASS |
| Flutter skeleton | analyze/widget + APK/iOS simulator builds | physical iOS/Android | automated PASS; physical `NOT_RUN` |
| OpenAPI skeleton | semantic validator + HTTP tests | client review | PASS |
| Compose separation | config + clean runtime health | DB schema queries | PASS |
| raw retention ≤24h | Go unit + SQL rejection | KMS/delete/backup drill | policy PASS; drill `NOT_RUN` |
| truth-state separation | Go unit + schema enum | comprehension test | unit PASS; user test `NOT_RUN` |
| no real GPS in M0 | dependency/permission review | device network inspection | static review PASS; physical `NOT_RUN` |
| single next_action | YAML structural inspection | owner review | PASS |

Source verification cannot be satisfied by the structural validator.
