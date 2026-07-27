# TrainRadar — правила работы

## Граница MVP

- Единственный коридор: Москва-Павелецкая → Узуново.
- Канонический registry содержит ровно 44 пассажирских остановочных пункта.
- `Котляково` сохраняется как planned slot №8, но не используется до подтверждения ввода в
  эксплуатацию и отдельного решения владельца.
- Запрещены аэропортовая ветка Домодедово, Большое кольцо, Ожерелье → Узловая и направления за Узуново.
- Текущий milestone — M1. M2–M6 не начинать без отдельного решения владельца.
- Mobile: Flutter для iOS и Android. Backend: Go modular monolith. API: REST + SSE.

## Архитектурные инварианты

- `official_actual`, `crowd_confirmed`, `estimated`, `stale_lost` — разные состояния; fallback всегда видим.
- `estimated`, `stale_lost` и неизвестное состояние не входят в live coverage.
- `crowd_confirmed` требует минимум три независимые install-capability.
- Corridor registry и stop pattern рейса не смешиваются. Допустимые состояния stop pattern:
  `scheduled_stop`, `pass_through`, `conditional`, `cancelled`.
- Сырые observations неизменяемы; производные состояния версионируются.
- Публичная позиция поезда не равна точке пассажира. Индивидуальные GPS-треки не выдаются публичным API.
- OSM geometry версируется; attribution ODbL обязателен. Публичные OSM tiles не используются как production backend.
- Tutu MCP разрешён только для ручной point-check сверки. Import, scheduler, cache и redistribution запрещены.
- В M1 разрешён только публичный read-only Яндекс.Расписания API: временный in-memory cache до
  300 секунд, обязательный attribution, без disk persistence, offline schedule и ключа в клиенте/Git.

## Приватность

- M1 публичен только как read-only map/schedule без аккаунтов, GPS или персональных данных.
  Пилот M2–M6 остаётся accountless, invite-only, 5–15 участников; оператор ПД — владелец как физлицо.
- Foreground location запрашивается только в контексте активной поездки.
- Background location — отдельный opt-in, действует только во время активной поездки и явно выключается.
- Exact raw GPS на сервере хранится зашифрованно не более 24 часов, затем hard delete и уничтожение ключа.
- Не добавлять SDK геолокации, реальные треки, developer accounts или production secrets без явного разрешения.
  API-ключи передаются только через локальную server-side конфигурацию и никогда не попадают в client,
  Git, evidence или ответы агента.

## Brand invariants

- Перед изменением UI, splash screen, launcher assets, favicon или store metadata читать `docs/BRAND.md`.
- Использовать только активы из `assets/brand/trainradar/`; не генерировать новую иконку и не заменять
  концепт №5 без явного запроса владельца.
- После затрагивающих изменений запускать `make validate-brand` и явно сообщать о любом расхождении checksum.

## Команды

```bash
make setup
make compose-up
make validate-data
make lint
make test
make check
git diff --check
```

## Definition of done для M0

1. Обязательное дерево и два OMX-плана содержательны.
2. Reference registry проходит автоматическую проверку 44/44 и scope guard.
3. Go и Flutter skeletons форматируются, анализируются и тестируются.
4. OpenAPI и Docker Compose синтаксически валидны.
5. Неизвестные помечены `pending` и перечислены в `docs/research/open-questions.md`.
6. Команды, дата и результаты сохранены в `docs/evidence/`; физические проверки отмечены `NOT_RUN`.
7. `docs/EXECUTION_STATE.yaml` содержит ровно один `next_action`.

## Evidence и заявления

- Не называть данные verified без source reference, даты и воспроизводимой проверки.
- Не называть endpoint realtime-ready, пока он не реализован и не проверен деградационными тестами.
- После изменения кода, data или решения обновлять соответствующие docs, QA matrix и evidence в том же срезе.
- Не выполнять commit, push, deploy, публикацию, удаление данных или платные операции без явного разрешения.

## Commit and documentation gate

- До завершения задачи определить documentation impact через `docs/CHANGE_IMPACT.yaml` и обновить нужные документы в том же срезе.
- Generated-блоки не редактировать вручную; после структурных изменений запускать `make docs-sync`, а `docs/PROJECT_MAP.md` менять только генератором.
- Перед commit запускать `make check-staged`; перед push/PR — `make ready` (или `make check-full`). Актуальность generated docs подтверждает только `make docs-check`.
- В финальном отчёте указывать обновлённые документы и отдельно разделять автоматический PASS от ручного `NOT_RUN`.
- Подробный protocol, recovery после конфликта и правила manifest: `docs/CONTRIBUTING.md`.
