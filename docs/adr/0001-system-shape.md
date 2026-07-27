# ADR 0001: Modular monolith

- Status: Accepted
- Date: 2026-07-27

## Context

Пилот ограничен одним corridor, 5–15 участниками и неизвестными data feeds. Отдельные deployable
services сейчас увеличат failure modes, privacy surface и стоимость без измеренной нагрузки.

## Decision

Один Go process с явными модулями corridor, schedule, observation, matching, position, prediction,
privacy, transport и observability. Operational PostGIS и raw ciphertext store физически разделены.
Flutter — отдельный client. Module boundaries enforced package APIs and tests.

## Consequences

- проще локальный запуск, транзакции и tracing;
- privacy storage separation сохраняется, хотя compute process один;
- module extraction возможен только после evidence по scaling/failure/security boundary;
- M0 создаёт skeleton, а не все модули и не runtime integrations.

Локальный operational image собирается из pinned official `postgres:17-trixie` и multi-arch
`pglayers` PostGIS layer; это dev/test choice, не production platform decision.
