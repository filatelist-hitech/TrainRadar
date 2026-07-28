# Project Map

<!-- GENERATED FILE: do not edit; run `make docs-sync` -->

Детерминированная карта рабочего дерева, исключающая cache, build output, secrets и binary contents. Она не заменяет архитектурные решения в `docs/`.

## Верхний уровень и модули

| Путь | Назначение |
| --- | --- |
| `.githooks/` | Repo-local pre-commit и pre-push hooks. |
| `.github/` | CI workflow checks. |
| `assets/` | Канонические brand assets и платформенные производные. |
| `backend/` | Go modular-monolith API и доменная логика. |
| `data/` | Reference registry и manifests источников. |
| `docs/` | Архитектурные, продуктовые, privacy, QA и evidence-документы. |
| `infra/` | Инициализация local development data stores. |
| `mobile/` | Flutter shell для iOS и Android. |
| `openapi/` | OpenAPI 3.1 contract M0. |
| `scripts/` | Детерминированные локальные validators и documentation gates. |
| `test/` | Ruby tests validators и documentation gates. |

Ключевые конфигурации: `AGENTS.md`, `Makefile`, `docker-compose.yml`, `.env.example`, `docs/DOCS_MANIFEST.yaml`, `docs/CHANGE_IMPACT.yaml`, `.omx/plans/`.


## Entrypoints и платформы

| Surface | Entrypoint / состояние |
| --- | --- |
| Go API | `backend/cmd/api/main.go` — HTTP skeleton |
| Flutter | `mobile/lib/main.dart` — iOS/Android shell |
| Local services | `docker-compose.yml` — operational PostGIS и отдельный raw-GPS store |
| Validators | `scripts/validate_reference_data.rb`, `scripts/validate_openapi.rb` |

## Internal Go packages

| Package |
| --- |
| `backend/internal/config` |
| `backend/internal/domain` |
| `backend/internal/httpapi` |
| `backend/internal/rawgps` |
| `backend/internal/schedule/yandex` |

## Публичные интерфейсы

| Method | Path | Operation ID |
| --- | --- | --- |
| `GET` | `/healthz` | `getHealth` |
| `GET` | `/v1/live/events` | `subscribeLiveEvents` |
| `GET` | `/v1/status` | `getProjectStatus` |

## Конфигурация без секретов

Источник: `.env.example`; значения намеренно не публикуются.

| Переменная |
| --- |
| `API_HOST` |
| `API_PORT` |
| `APP_ENV` |
| `OPERATIONAL_DB_HOST` |
| `OPERATIONAL_DB_NAME` |
| `OPERATIONAL_DB_PASSWORD` |
| `OPERATIONAL_DB_PORT` |
| `OPERATIONAL_DB_USER` |
| `RAW_GPS_DB_HOST` |
| `RAW_GPS_DB_NAME` |
| `RAW_GPS_DB_PASSWORD` |
| `RAW_GPS_DB_PORT` |
| `RAW_GPS_DB_USER` |
| `RAW_GPS_KEK_BASE64` |
| `RAW_GPS_RETENTION_HOURS` |

## Тесты, документы и generated-код

- Ruby tests: `test/`.
- Go tests: `backend/**/*_test.go`.
- Flutter tests: `mobile/test/`.
- Human-owned документация: `docs/`, кроме явно generated файлов и блоков из `docs/DOCS_MANIFEST.yaml`.
- Generated documentation: `docs/PROJECT_MAP.md` и отмеченные блоки в README/API contract.
- Generated source code: не используется в M0.

## Канонические проверки

```bash
make docs-sync
make docs-check
make check-staged
make check-full
make ready
```
