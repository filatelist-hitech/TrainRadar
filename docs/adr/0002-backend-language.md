# ADR 0002: Go backend

- Status: Accepted
- Date: 2026-07-27

## Context

Исходная гипотеза допускала Kotlin или Go. Нужны простой deployable modular monolith,
предсказуемые concurrency/HTTP primitives, хорошие Postgres/PostGIS adapters и низкая стоимость
малого пилота.

## Decision

Использовать Go. M0 придерживается standard library, чтобы skeleton не фиксировал преждевременно
router, ORM, migration framework или telemetry SDK.

## Consequences

- один статический binary и быстрые unit tests;
- SSE реализуется обычным `net/http` позже;
- SQL/PostGIS tooling, migrations и tracing packages выбираются на milestone, где они нужны;
- команда должна явно моделировать domain types, а не прятать семантику в ORM structs.
