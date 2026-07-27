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
- Страница ЦППК идентифицирована как кандидат, но snapshot/права/структура не подтверждены.
- Official infrastructure source не идентифицирован.
- OSM data extract не получен; лицензия и tile policy зафиксированы как constraints.
- Публичный/партнёрский GTFS(-RT) feed для коридора не подтверждён.

Поэтому никакие coordinates, external IDs, stop patterns или operational statuses не считаются verified.
