# MVP Scope

## География

Единственный corridor registry: Москва-Павелецкая → Узуново, ровно 44 пункта из
`data/reference/paveletsky_uzunovo_stations.yaml`. Изменение количества, порядка или endpoint
требует проверенного источника и decision/ADR.

`Котляково` входит в 44-slot project registry как `planned_not_built`, но не входит в текущие
usable stop patterns, routing или coverage. Активация требует официального подтверждения ввода в
эксплуатацию и отдельного решения владельца.

Запрещены:

- Домодедово → Авиационная → Космос → Аэропорт Домодедово;
- ответвления Михнево/Жилёво на Большое кольцо;
- Ожерелье → Узловая;
- направления за Узуново.

## Продуктовый MVP M1–M6

После отдельных утверждений MVP может включить offline rail map, schedule import, stop patterns,
режим «Я в этом поезде», consented GPS, map matching, multi-rider aggregation, delay, интервальный
ETA, incident detection, историю своей поездки и уведомление о приближении.

## Текущая граница M0

M0 принят владельцем 2026-07-28. Любой последующий milestone требует отдельной явной авторизации.

В scope текущего пакета:

- документация решений, рисков, privacy и UX;
- seed registry 44/44 и manifest источников;
- автоматический scope/data validator;
- Flutter/Go/OpenAPI/Compose skeletons;
- тестовая стратегия и план M0–M6.

Вне scope M0:

- импорт расписаний или OSM;
- железнодорожная геометрия и карта;
- GPS permissions, SDK, реальные/синтетические треки;
- map matching, grouping, realtime stream, ETA и notifications;
- production hosting, tiles, KMS/HSM и developer accounts.

## Stop patterns

Registry содержит все 44 пункта, но каждый `Trip` имеет отдельный ordered stop pattern.
Допустимы только `scheduled_stop`, `pass_through`, `conditional`, `cancelled`. «Обычный»,
«ускоренный» и «экспресс» — классы шаблонов для QA, а не основания выдумать фактические остановки.
