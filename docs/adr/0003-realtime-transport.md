# ADR 0003: SSE, не WebSocket

- Status: Accepted
- Date: 2026-07-27

## Context

Клиенту нужен преимущественно server→client поток агрегированных позиций. Двунаправленная
realtime-сессия не является требованием; команды пользователя остаются REST.

## Decision

REST для запросов/команд, Server-Sent Events для live projections. WebSocket не используется.
M0 резервирует `/v1/live/events`, но возвращает 501 и не производит события.

## Consequences

- проще HTTP auth, proxies, observability и reconnect через `Last-Event-ID`;
- нужны heartbeat, bounded replay, backpressure и stale rules до M4;
- mobile lifecycle/reconnect нужно проверить физически;
- если появится доказанная двунаправленная low-latency потребность, требуется новая ADR.
