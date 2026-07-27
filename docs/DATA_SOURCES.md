# Data Sources

Канонический manifest: `data/reference/source_manifest.yaml`.

## Классы источников

1. Official carrier/infrastructure: расписание, эксплуатационный статус, официальная телеметрия.
2. GTFS/GTFS-RT: только если обнаружен законный актуальный feed с версией и условиями использования.
3. Versioned OSM extract: geometry/topology cross-check под ODbL и с attribution.
4. Consented crowdsourced observations: доказательство движения, не источник passenger stop registry.
5. Tutu MCP: только ручная point-check сверка; не источник dataset.

## Приём источника

До import обязательны owner, URL/identifier, licence/terms, retrieved_at, checksum, update method,
allowed/prohibited use и verification status. Snapshot получает immutable source version.
Неизвестная лицензия блокирует import, но не блокирует запись вопроса.

## Текущее состояние M0

- Seed-ТЗ имеет локальный SHA-256 и даёт только 44 названия, порядок и продуктовые ограничения.
- Страница и два route view ЦППК вручную проверены 2026-07-27: 43 пункта совпадают с seed после
  исключения `Котляково`; стабильные projection checksums записаны в manifest.
- `Котляково` отсутствует в обоих route view и в текущем station search ЦППК; это согласуется с
  owner decision о ещё не построенной станции.
- Owner decision от 2026-07-28 сохраняет `Котляково` в registry, но запрещает использование до
  подтверждения ввода в эксплуатацию и отдельного разрешения.
- Лицензия/redistribution rights ЦППК не подтверждены; raw response не сохранён и import запрещён.
- Official infrastructure source не идентифицирован.
- OSM data extract не получен; лицензия и tile policy зафиксированы как constraints.
- Публичный/партнёрский GTFS(-RT) feed для коридора не подтверждён.

Поэтому никакие coordinates, external IDs, aliases, полные stop patterns или operational statuses
не считаются verified. M0 scope принят как 43 текущих пункта плюс один fail-closed planned slot.
