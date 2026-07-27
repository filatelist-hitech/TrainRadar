# TrainRadar

TrainRadar — прототип live-карты пригородных поездов. M0 создаёт проверяемый фундамент для
единственного пилотного коридора Москва-Павелецкая → Узуново и не реализует отслеживание поездов.

## Текущее состояние

- milestone: `M0 Discovery / startup package`;
- registry: 44/44 seed-записи из утверждённого ТЗ, внешняя верификация пока `pending`;
- mobile: собираемый Flutter shell для iOS/Android без location permissions и GPS SDK;
- backend: Go modular monolith с health/status endpoints и зарезервированным SSE endpoint;
- storage: отдельные dev-контейнеры operational PostGIS и raw-GPS ciphertext store;
- realtime, map matching, ETA, schedule import и фактический GPS: не реализованы.

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

## Структура

- `mobile/` — Flutter shell;
- `backend/` — Go API skeleton;
- `openapi/openapi.yaml` — контракт M0;
- `data/reference/` — registry и manifest источников;
- `scripts/` — автоматические валидаторы;
- `docs/` — продуктовые, архитектурные, privacy и QA-контракты;
- `.omx/plans/` — утверждённый план и test specification.

## Главная оговорка M0

Названия и порядок 44 пунктов получены из утверждённого seed-ТЗ. Координаты, километраж,
эксплуатационный/тарифный статус, внешние идентификаторы и direction-specific service ещё не
подтверждены первичными источниками. UI и API не должны изображать этот registry как live data.
