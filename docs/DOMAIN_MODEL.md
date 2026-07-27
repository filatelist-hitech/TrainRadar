# Domain Model

## Сущности

| Entity | Назначение | Ключевые поля |
|---|---|---|
| `Vehicle` | физический состав, если идентичность доказана | `vehicle_id`, external IDs, validity |
| `Trip` | плановый рейс | `trip_id`, `route_id`, `service_date`, stop pattern |
| `ServiceDate` | операционный день, не просто UTC date | local date, timezone, source version |
| `Route` | пассажирский маршрут | corridor, direction, service class |
| `Stop` | канонический объект registry | stable ID, aliases, object type, provenance |
| `RailSegment` | направленное ребро versioned graph | endpoints, geometry version, topology |
| `Observation` | неизменяемое входное свидетельство | pseudonym, time, encrypted payload, consent |
| `TrainTrack` | версия агрегированного трека рейса | input refs, algorithm version, uncertainty |
| `Prediction` | ETA/delay result | checkpoint, interval, confidence, model version |
| `Incident` | внеплановая остановка/аномалия | evidence window, status, reason |

## Value objects

- `PositionTruth`: `official_actual | crowd_confirmed | estimated | stale_lost`;
- `StopPatternState`: `scheduled_stop | pass_through | conditional | cancelled`;
- `Freshness`: source-specific TTL, age, bucket;
- `Confidence`: score 0..1 + breakdown + policy version;
- `ConsentGrant`: purpose, foreground/background scope, issued/revoked time;
- `InstallCapability`: rotating pseudonymous capability, не публичный user ID.

## Инварианты

- 44-stop registry и конкретный trip stop pattern не являются одной таблицей.
- `Trip` идентифицируется вместе с `ServiceDate`; время хранится UTC + исходная timezone.
- `Delay` относится к checkpoint и calculated_at.
- `Prediction` всегда содержит интервал и версию.
- `Observation` не изменяется; исправления создают новую derived version.
- `crowd_confirmed` требует три независимые capability после anti-collusion checks.
- `TrainTrack` не содержит публично доступной связи с участником.
