# Decisions

| ID | Decision | Status | Consequence |
|---|---|---|---|
| D-001 | MVP only Москва-Павелецкая → Узуново, exactly 44 | accepted | every layer has completeness gate |
| D-002 | Flutter iOS/Android; web later | accepted | no React/Next skeleton in M0 |
| D-003 | Go modular monolith | accepted | no microservices/Redis/ML by inertia |
| D-004 | REST + SSE; no WebSocket | accepted | ordered one-way live projection later |
| D-005 | operational PostGIS + separate ciphertext raw store | accepted | no exact GPS in operational DB |
| D-006 | raw exact GPS ≤24h then hard delete + key destruction | accepted | production KMS/delete is pre-GPS gate |
| D-007 | Russia only, operator is owner as individual | accepted product assumption | legal compliance remains mandatory |
| D-008 | accountless invite-only group 5–15 | accepted | scoped capabilities, no account graph |
| D-009 | foreground + separate active-trip background opt-in | accepted | no location permissions in M0 |
| D-010 | `crowd_confirmed` requires ≥3 independent capability | accepted | fewer contributors never count live |
| D-011 | Tutu only manual point-check | accepted | import/scheduler/cache/redistribution forbidden |
| D-012 | versioned OSM + ODbL attribution; no public tiles in prod | accepted | source/provider gate before M1 |
| D-013 | four truth states never mixed | accepted | explicit UI/API degradation |
| D-014 | M0 external stop properties remain pending | accepted | no fabricated coordinates/status/IDs |
| D-015 | `Котляково` retained as planned but disabled | accepted | registry stays 44; usable corridor stays 43 until commissioning proof and separate owner approval |
| D-016 | M0 discovery package accepted by owner on 2026-07-28 | accepted | completed predecessor for M1 |
| D-017 | M1 Offline rail map authorized by owner on 2026-07-28 | accepted | M1 only; M2–M6 remain blocked pending separate authorization |
| D-018 | M1 source admission is an explicit fail-closed allowlist | accepted | no schedule/OSM import until immutable snapshot, SHA-256, rights and OSM attribution gates pass |

Architecture rationale is expanded in `docs/adr/`.
