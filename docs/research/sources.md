# Primary Sources Reviewed

Review date: 2026-07-27. Это ссылки на нормы/спецификации, а не доказательство конкретных 44 stop
records.

| Source | Что подтверждает | Ограничение |
|---|---|---|
| [OSM Copyright and License](https://www.openstreetmap.org/copyright) | OSM data под ODbL; attribution и указание лицензии обязательны | нужен review производной БД и фактический extract |
| [OSMF Tile Usage Policy](https://operations.osmfoundation.org/policies/tiles/) | public raster tiles best-effort, no SLA; bulk/offline prefetch запрещены | policy может меняться; production provider не выбран |
| [GTFS Schedule Reference](https://gtfs.org/documentation/schedule/reference/) | `stops`, `trips`, `stop_times`, service day — разные структуры; stable source IDs важны | TrainRadar feed/лицензия не найдены |
| [GTFS Realtime Reference](https://gtfs.org/documentation/realtime/reference/) | realtime stop updates ссылаются на static stop IDs and sequences | official corridor GTFS-RT не подтверждён |
| [PostgreSQL pglayers announcement](https://www.postgresql.org/about/news/pglayers-postgresql-extensions-as-stackable-docker-layers-3344/) | PostGIS layer supports PostgreSQL 17 and linux/amd64 + linux/arm64 | dev image still не определяет production DB platform |
| [Android location permissions](https://developer.android.com/develop/sensors-and-location/location/permissions) | foreground/background permissions различаются; background требует явной платформенной декларации | Play approval и device behavior требуют проверки |
| [Android background location](https://developer.android.com/develop/sensors-and-location/location/background) | background access должен быть core/visible и ограничивается системой | battery/update cadence не гарантированы |
| [Apple Core Location authorization](https://developer.apple.com/documentation/corelocation/requesting-authorization-to-use-location-services) | permission надо запрашивать в контексте; When In Use предпочтительнее | physical iOS behavior не проверен |
| [Apple background updates](https://developer.apple.com/documentation/corelocation/handling-location-updates-in-the-background) | background capability требует прозрачности и OS lifecycle handling | developer capability не включалась в M0 |
| [152-ФЗ, официальный текст](https://ips.pravo.gov.ru/api/ips/legislation/document?baseid=None&hash=98490812b3409e2a8d78a11ca9010f434ea3d9250a11dbbdb78690cd5551bdd6) | оператором может быть физлицо; location-related data может относиться к определяемому лицу | нужен юрист по конкретному пилоту и текущей редакции |
| [ЦППК schedule entry](https://www.central-ppk.ru/new/schedule/) | кандидат на первичную проверку passenger service | в M0 fetch timed out; данные и права не верифицированы |

## Не использовано как dataset

Tutu MCP отсутствовал как доступный callable tool. По утверждённой политике он всё равно может
использоваться только вручную для малой point-check сверки; import/cache/scheduler/redistribution
запрещены.
