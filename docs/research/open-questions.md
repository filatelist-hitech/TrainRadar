# Open Questions

Все вопросы ниже не блокируют создание skeleton, но блокируют соответствующие milestones.

## M0 source verification

- [x] Сверить текущие route views ЦППК в обоих направлениях: 43 seed-пункта совпадают по порядку
  после исключения `Котляково` (2026-07-27, evidence/checksums сохранены).
- [x] Разрешить M0 scope для `Котляково`: owner decision от 2026-07-28 сохраняет пункт №8 как
  `planned_not_built`/`planned_unused`; текущий carrier route ожидаемо его не содержит.
- [ ] Перед активацией `Котляково` получить официальное подтверждение строительства/ввода в
  эксплуатацию и отдельное разрешение владельца.
- [ ] Идентифицировать официальный infrastructure registry/source и права использования.
- [ ] Зафиксировать coordinates, object type, kilometer, operational/fare status и external IDs.
- [ ] Подтвердить aliases всех пунктов, особенно `32 км` и `85 км`.
- [ ] Подтвердить boarding/alighting direction rules для `32 км` и `85 км`.
- [ ] Получить versioned OSM corridor extract, checksum, replication/version и topology review.
- [ ] Определить доступность и лицензию GTFS/GTFS-RT/API ЦППК/РЖД.
- [ ] Выполнить разрешённую ручную Tutu point-check сверку, если MCP станет доступен.

## Privacy/legal before M2

- [ ] Проверить обязанности оператора-физлица, форму согласия, уведомление регулятора и local policy.
- [ ] Выбрать российский hosting/KMS/HSM и доказать residency/key separation.
- [ ] Утвердить consent receipt, rotating capability и retention для derived/audit data.
- [ ] Утвердить backup deletion/key-destruction procedure.
- [ ] Определить процедуру subject access/deletion для accountless participant.

## Product/UX/platform

- [ ] Утвердить минимальные iOS/Android versions и distribution path.
- [ ] Утвердить visual palette/iconography и проверить четыре truth states с участниками.
- [ ] Измерить battery impact foreground/background active-trip tracking.
- [ ] Зафиксировать invitation/revocation flow без аккаунта.

## Architecture/data science

- [ ] Выбрать Postgres migrations/driver только перед первым DB-backed slice.
- [ ] Откалибровать freshness TTL по фактическим feed cadences.
- [ ] Откалибровать outlier/map ambiguity/confidence thresholds на synthetic/replay evidence.
- [ ] Утвердить SSE replay window, heartbeat и auth model до M4.
- [ ] Зафиксировать schedule-only ETA baseline dataset и success thresholds до M5.
