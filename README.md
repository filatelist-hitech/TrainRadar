# TrainRadar

TrainRadar — прототип read-only карты пригородного коридора. M1-02b фиксирует проверяемый
offline map для единственного направления Москва-Павелецкая → Узуново и не реализует
отслеживание поездов.

## Текущее состояние

- milestone: `M1`, active slice `M1-02b`;
- registry/map: 44/44 project scope; 43 current stops on read-only offline schematic map,
  `Котляково` planned/disabled;
- OSM: Geofabrik `central-fed-district-260726`, SHA-256 and ODbL attribution are pinned; raw PBF is
  local runtime data, not Git; `make verify-m1-osm-runtime` verifies it;
- mobile: Flutter offline map without location permissions, GPS SDK, network tiles or API client;
- backend: Go modular monolith with health/status endpoints, reserved SSE and internal cache-only
  Яндекс.Расписания adapter (`YANDEX_RASP_API_KEY` stays in backend environment only);
- storage: отдельные dev-контейнеры operational PostGIS и raw-GPS ciphertext store;
- realtime, map matching, ETA, schedule integration, import scheduler и фактический GPS: не реализованы.

## Быстрый старт

Требуются Go, Flutter, Ruby с Psych, Make и Docker Compose.

```bash
cp .env.example .env
make setup
make check
make compose-up
```

После работы контейнеры можно остановить без удаления данных:

```bash
docker compose stop
```

<!-- BEGIN GENERATED: root-commands-and-configuration -->
### Проверки

```bash
make docs-sync
make docs-check
make check-staged
make check-full
make ready
```

### Конфигурация

Переменные из `.env.example` (значения и секреты не генерируются):
- `API_HOST`
- `API_PORT`
- `APP_ENV`
- `OPERATIONAL_DB_HOST`
- `OPERATIONAL_DB_NAME`
- `OPERATIONAL_DB_PASSWORD`
- `OPERATIONAL_DB_PORT`
- `OPERATIONAL_DB_USER`
- `RAW_GPS_DB_HOST`
- `RAW_GPS_DB_NAME`
- `RAW_GPS_DB_PASSWORD`
- `RAW_GPS_DB_PORT`
- `RAW_GPS_DB_USER`
- `RAW_GPS_KEK_BASE64`
- `RAW_GPS_RETENTION_HOURS`
<!-- END GENERATED: root-commands-and-configuration -->

## Структура

- `mobile/` — Flutter shell;
- `backend/` — Go API skeleton;
- `openapi/openapi.yaml` — контракт M0;
- `data/reference/` — registry и manifest источников;
- `scripts/` — автоматические валидаторы;
- `docs/` — продуктовые, архитектурные, privacy и QA-контракты;
- `.omx/plans/` — утверждённый план и test specification.

## Главная оговорка M0

Названия и порядок 44 registry slots получены из утверждённого seed-ТЗ. `Котляково` сохраняется как
ещё не построенная станция и не используется до отдельного решения. Координаты, километраж,
эксплуатационный/тарифный статус, внешние идентификаторы и direction-specific service ещё не
подтверждены первичными источниками. UI и API не должны изображать этот registry как live data.
