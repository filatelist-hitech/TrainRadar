# M0 Reference Verification Evidence

- Carrier check: 2026-07-27T20:43:34Z / 2026-07-27 23:43 MSK
- Owner decision: 2026-07-27T21:14:32Z / 2026-07-28 00:14 MSK
- Automated map check: 2026-07-27T21:49:22Z / 2026-07-28 00:49 MSK
- Scope: source-backed verification of the approved 44-stop seed and `source_manifest`
- Source: official АО «Центральная ППК» schedule UI, route views and interactive map
- Method boundary: human-triggered read-only checks; no dataset import, persistent raw response or cache
- Verdict: `PASS_M0_SCOPE_WITH_PLANNED_EXCEPTION`

## Reproducible source views

| Check | Result | Stable projection checksum |
|---|---|---|
| Москва (Павелецкий вокзал) → Узуново, train 6001, schedule 3333886, 2026-07-27 | 43 ordered route points | `sha256:aa022372d4ebd56eaa2b8d4cdca518a68fa544c928fefdd9c61c2fe997d65041` |
| Узуново → Москва (Павелецкий вокзал), train 6002, schedule 3343569, 2026-07-27 | the same 43 points in reverse order | `sha256:ca82081638411caf4c5f816d56e88457a3fad08d6c4786025fb3659e982bf708` |
| Exact station search `Котляково` | empty JSON array `[]` | `sha256:4f53cda18c2baa0c0354bb5f9a3ecbe5ed12ab4d8e11ba873c2f11161202b945` |
| CPPK interactive map | 42 current registry matches; `32 км` schedule-only; three airport-branch objects excluded | `sha256:ea7a151fb05e5fe6d8a388dd05dae50aae0675bf9236055629e32a894acda276` |

Checksum projection is compact UTF-8 JSON with `tripId`, `trainNumber`, endpoint IDs and ordered
`stationId`/`name`/`direction`/`skip`. Volatile times, delay and fare fields are excluded. Raw
carrier responses are deliberately not committed because licence/redistribution rights remain
unknown.

## Comparison result

- Both endpoints match the approved scope.
- After removing seed slot `tr-pu-stop-008` (`Котляково`), all remaining 43 identities occur in the
  same order in both carrier route views.
- Both route views contain `32 км` and `85 км`, each represented as a route checkpoint.
- The sampled trains pass both special points without stopping. Owner supplied the rule that both
  platforms exist only toward Узуново; it is recorded as `supplied_not_independently_verified`, not
  promoted to a universal per-trip stop pattern.
- Carrier spelling yields alias candidates such as `ТУЛЬСКАЯ (ЗИЛ)`, `ПЛАТФОРМА КАЛИНИНА`,
  `Ост.Пункт 85 км (снт Земляничка)`, `КАШИРА`, `Колменка (д. Железня)`,
  `Ост.Пункт 137 км (снт Родник 2)` and `ОСТ.ПУНКТ 146 КМ (Мос.обл.)`. They are not promoted to
  verified aliases until source rights and canonicalization rules are approved.

## Planned-station resolution

The approved seed requires exactly 44 passenger stop points and includes `Котляково`. The current
carrier source exposes only 43 route points, omits `Котляково` in both directions and returns no
station-search match for it. On 2026-07-28 the owner confirmed that `Котляково` is a new station
that has not been built yet and approved retaining it in the project without current use.
Therefore:

- 43/44 identity/order comparison: `PASS`;
- M0 registry scope 44/44: `PASS_WITH_PLANNED_EXCEPTION`;
- current usable corridor: 43 stops;
- `tr-pu-stop-008` remains in the registry as `planned_not_built` and `planned_unused`;
- activation fails closed until official construction/commissioning verification and a separate
  owner approval;
- unverified external fields on individual stop records remain `pending`.

## Source-manifest verdict

`source_manifest.yaml` records the schedule/map reviews, stable checksums, allowed/prohibited use,
the checksummed owner decision for `Котляково`, the explicitly non-independent direction assertion,
the MediaWiki discovery boundary and a Tutu manual point-check. Carrier licence/redistribution
rights, official infrastructure inventory, versioned OSM extract and GTFS availability remain M1
inputs. The manifest is structurally verified, but it is not an import authorization.

## Automated validation run

Run at `2026-07-27T21:49:22Z`:

| Command | Result |
|---|---|
| `ruby scripts/verify_corridor_sources.rb` | PASS_WITH_GAPS: route evidence 43/43; map 42/43; `32 км` schedule-only; no unexpected in-scope gaps |
| `make check` | PASS: Go, Flutter, data/OpenAPI validators and test suites |
| `ruby test/verify_corridor_sources_test.rb` | PASS: parser and no-block gap semantics |
| `git diff --check` | PASS |

## NOT_RUN

- Tutu MCP manual point-check: `PASS_LIMITED` — 9 direct Москва-Павелецкая → Узуново offers on
  2026-07-28; response had endpoints only, not intermediate stops.
- Official infrastructure registry comparison: `NOT_RUN` — source not yet identified.
- Versioned OSM corridor extract/topology review: `NOT_RUN` — belongs to the M1 input gate.
- Physical corridor/train ride and real GPS: `NOT_RUN` and prohibited in M0.
