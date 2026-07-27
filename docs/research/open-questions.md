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
- [x] Выполнить read-only CPPK map cross-check: 42 current records имеют map match с ID/координатами;
  `32 км` остаётся schedule-only (2026-07-28, checksum в manifest).
- [x] Выбрать M1 schedule source: public/free Яндекс.Расписания API в cache-only режиме; persistent
  import, disk cache и offline schedule запрещены (owner authorization 2026-07-28, official terms reviewed).
- [ ] Перед runtime enablement подтвердить текущие API limits/terms и настроить server-side secret;
  ключ не хранить в Git/mobile/evidence.
- [ ] Получить sourced ordinary/accelerated/express patterns через runtime API contract; до этого
  не создавать persistent stop patterns из API response.
- [ ] Получить versioned OSM corridor extract с replication/version, SHA-256, ODbL attribution и
  topology review; до admission он не попадает в graph или map.
- [ ] Законно импортировать или independently re-check coordinates, object type, kilometer,
  operational/fare status и external IDs после admission соответствующего source snapshot.
- [ ] Подтвердить aliases всех пунктов, особенно `32 км` и `85 км`, независимым источником.
- [ ] Независимо подтвердить owner-supplied one-way platform rule для `32 км` и `85 км`; не
  выводить из него stop pattern каждого рейса.
- [ ] Определить доступность и лицензию GTFS/GTFS-RT/API ЦППК/РЖД.
- [x] Выполнить разрешённую ручную Tutu endpoint point-check: 9 прямых offers Москва-Павелецкая →
  Узуново на 2026-07-28; промежуточные stops не получены и не импортированы.

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
