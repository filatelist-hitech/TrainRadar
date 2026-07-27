# Corridor Registry

Source of truth для машинной проверки:
`data/reference/paveletsky_uzunovo_stations.yaml`. В M0 все 44 записи имеют
`verification_status: pending`; stable internal IDs фиксируют seed slots, а не утверждают внешнюю
идентичность.

| # | stop_id | Каноническое имя | Seed alias | Status |
|---:|---|---|---|---|
| 1 | tr-pu-stop-001 | Москва-Павелецкая | Павелецкий вокзал | pending |
| 2 | tr-pu-stop-002 | Дербеневская | — | pending |
| 3 | tr-pu-stop-003 | Тульская | — | pending |
| 4 | tr-pu-stop-004 | Верхние Котлы | — | pending |
| 5 | tr-pu-stop-005 | Нагатинская | — | pending |
| 6 | tr-pu-stop-006 | Варшавская | — | pending |
| 7 | tr-pu-stop-007 | Чертаново | — | pending |
| 8 | tr-pu-stop-008 | Котляково | — | pending |
| 9 | tr-pu-stop-009 | Бирюлёво-Товарная | — | pending |
| 10 | tr-pu-stop-010 | Бирюлёво-Пассажирская | — | pending |
| 11 | tr-pu-stop-011 | Булатниково | — | pending |
| 12 | tr-pu-stop-012 | Расторгуево | — | pending |
| 13 | tr-pu-stop-013 | Калинина | — | pending |
| 14 | tr-pu-stop-014 | Ленинская | — | pending |
| 15 | tr-pu-stop-015 | 32 км | alias pending; direction-dependent | pending |
| 16 | tr-pu-stop-016 | Домодедово | — | pending |
| 17 | tr-pu-stop-017 | Взлётная | — | pending |
| 18 | tr-pu-stop-018 | Востряково | — | pending |
| 19 | tr-pu-stop-019 | Белые Столбы | — | pending |
| 20 | tr-pu-stop-020 | Данилово | бывш. 52 км | pending |
| 21 | tr-pu-stop-021 | Барыбино | — | pending |
| 22 | tr-pu-stop-022 | Вельяминово | — | pending |
| 23 | tr-pu-stop-023 | Привалово | — | pending |
| 24 | tr-pu-stop-024 | Михнево | — | pending |
| 25 | tr-pu-stop-025 | Шугарово | — | pending |
| 26 | tr-pu-stop-026 | 85 км | alias pending; direction-dependent | pending |
| 27 | tr-pu-stop-027 | Жилёво | — | pending |
| 28 | tr-pu-stop-028 | Ситенка | — | pending |
| 29 | tr-pu-stop-029 | Ступино | — | pending |
| 30 | tr-pu-stop-030 | Акри | — | pending |
| 31 | tr-pu-stop-031 | Белопесоцкий | — | pending |
| 32 | tr-pu-stop-032 | Кашира-Пассажирская | — | pending |
| 33 | tr-pu-stop-033 | Тесна | — | pending |
| 34 | tr-pu-stop-034 | Ожерелье | — | pending |
| 35 | tr-pu-stop-035 | Зубово | бывш. 121 км | pending |
| 36 | tr-pu-stop-036 | Пурлово | — | pending |
| 37 | tr-pu-stop-037 | Колменка | бывш. 131 км | pending |
| 38 | tr-pu-stop-038 | Топканово | — | pending |
| 39 | tr-pu-stop-039 | 137 км | — | pending |
| 40 | tr-pu-stop-040 | Богатищево | — | pending |
| 41 | tr-pu-stop-041 | 146 км | — | pending |
| 42 | tr-pu-stop-042 | Коровино | — | pending |
| 43 | tr-pu-stop-043 | Новосёлки | бывш. 152 км | pending |
| 44 | tr-pu-stop-044 | Узуново | — | pending |

## Stop-pattern matrix

| Template | Registry coverage | Per-trip state |
|---|---|---|
| ordinary | все 44 остаются graph checkpoints | фактические states pending до schedule source |
| accelerated | все 44 остаются graph checkpoints | часть может быть `pass_through`; не заполнять без источника |
| express | все 44 остаются graph checkpoints | ограниченный набор `scheduled_stop`; pending |

`32 км` и `85 км` не удаляются при direction-specific service. Их точные aliases и
boarding/alighting directions — блокирующие open questions M0.
