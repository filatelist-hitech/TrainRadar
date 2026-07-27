# Risk Register

Scale: probability/impact `L/M/H`. Owners are roles, not assigned people.

| ID | Risk | P/I | Mitigation / trigger | Owner |
|---|---|---|---|---|
| R1 | official telemetry absent | H/H | product works with explicit crowd/estimate states; no official claim | product/data |
| R2 | crowdsourcing cold start | H/H | invite cohort, estimate labelled, coverage excludes unknown | product |
| R3 | GPS spoofing/Sybil/replay | H/H | ≥3 independent capabilities, nonce, plausibility, simulations | security |
| R4 | parallel-track map error | M/H | ambiguity margin, unmatched fallback, field replay | geo |
| R5 | iOS/Android background limits/policy | H/H | separate opt-in, active-trip only, physical/battery tests | mobile/privacy |
| R6 | OSM/ODbL violation | M/H | versioned extracts, attribution, provider review | data/legal |
| R7 | schedule licence/availability | H/H | no import until terms/source version approved | data/legal |
| R8 | privacy/regulatory non-compliance | M/H | legal gate, minimization, consent, Russian residency review | owner/privacy |
| R9 | false ETA precision | H/H | range, confidence, baseline evaluation, degraded set | prediction/UX |
| R10 | maps/realtime/storage cost | M/M | no public tile dependency, measure before provider/services | architecture |
| R11 | insufficient analytics sample | H/M | no public rankings, confidence intervals, explicit sample size | product |
| R12 | raw delete/key destruction failure | M/H | ≤24h constraint, alert, fail-closed, drill before GPS | security/ops |
| R13 | owner as individual lacks operational capacity | M/H | compliance/process review before pilot | owner |
| R14 | planned `Котляково` is accidentally treated as operational | M/H | `planned_unused`, validator fail-closed, commissioning evidence plus separate owner approval | rail data |

No risk is «accepted» merely because M0 skeleton compiles.
