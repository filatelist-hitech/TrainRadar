# Evidence

Evidence — воспроизводимое доказательство конкретного gate, а не скриншот «у меня зелёное».

Каждый milestone artifact содержит:

- дату/timezone и environment/tool versions;
- exact command и результат/exit code;
- проверяемое требование;
- input/source checksums, если применимо;
- ограничения и `NOT_RUN` для physical/field checks;
- ссылки на code/data/decision version.

M0 startup evidence находится в `M0-startup.md`; отдельная ручная сверка reference registry —
в `M0-reference-verification.md`; интеграция фирменных assets — в `brand-assets-2026-07-27.md`.
M1 fail-closed source-admission boundary фиксируется в `M1-source-admission-boundary.md`; он
подтверждает локальный запрет import, но не заменяет legal/source/map review.
Переход M1 на public/cache-only Яндекс.Расписания API фиксируется в
`M1-yandex-cache-contract.md`; это contract decision, а не evidence реального API запроса.
Не хранить здесь secrets, exact GPS, invites, raw capability IDs, access tokens или personal paths
вне необходимых локальных source identifiers.
