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
Неизвестная лицензия блокирует import, но не блокирует запись вопроса. Cache-only API не является
import: для него отдельно фиксируются terms, attribution, storage/TTL и запрет offline serving.

## M1 admission boundary

`m1_source_admission` в `data/reference/source_manifest.yaml` — локальная граница данных M1.
`yandex_rasp_api` разрешён только как `cache_only`: backend получает response по HTTPS, держит его
в памяти не более 300 секунд и не отдаёт schedule offline. API key остаётся server-side secret,
а каждый экран с данными показывает «Данные предоставлены сервисом Яндекс.Расписания».
`importable_source_refs` остаётся пустым: API response не становится snapshot или dataset.
`osm_corridor_extract` всё ещё blocked до immutable version/checksum/ODbL/topology review.

## Текущее состояние M0

- Seed-ТЗ имеет локальный SHA-256 и даёт только 44 названия, порядок и продуктовые ограничения.
- Страница и два route view ЦППК вручную проверены 2026-07-27: 43 пункта совпадают с seed после
  исключения `Котляково`; стабильные projection checksums записаны в manifest.
- Read-only автоматическая сверка интерактивной карты ЦППК от 2026-07-28 сопоставила 42 из 43
  текущих пунктов с именем, ID и координатами; `32 км` подтверждён route view, но не выдан картой.
  Три объекта аэропортовой ветки обнаружены и исключены scope guard'ом.
- `Котляково` отсутствует в обоих route view и в текущем station search ЦППК; это согласуется с
  owner decision о ещё не построенной станции.
- Owner decision от 2026-07-28 сохраняет `Котляково` в registry, но запрещает использование до
  подтверждения ввода в эксплуатацию и отдельного разрешения.
- Лицензия/redistribution rights ЦППК не подтверждены; raw response не сохранён и import запрещён.
- Яндекс.Расписания API reviewed 2026-07-28: owner разрешил только public/free M1 read-only
  surface в рамках official terms; persistent storage, offline schedule и raw redistribution
  запрещены validator'ом.
- MediaWiki API подключён только как вторичный discovery source: автоматическое сопоставление
  страниц с неоднозначными названиями запрещено.
- Tutu MCP выполнил только разрешённую ручную endpoint point-check; промежуточных остановок он
  в ответе не дал и источником registry не является.
- Official infrastructure source не идентифицирован.
- `osm_corridor_extract` admitted 2026-07-28: Geofabrik dated PBF
  `central-fed-district-260726.osm.pbf`, immutable URL, local SHA-256
  `4ab28c4d1bc42f890731bb8943b9f8158ca491d458f01442f5c9552476e49d9f` and upstream MD5
  `541e19bb16f1c6386d4986854720305e` are recorded in the manifest. Raw PBF lives only in ignored
  `data/runtime/osm/`; `make verify-m1-osm-runtime` recomputes SHA-256 and byte-size. Its lawful use
  in this slice is the 43-stop offline schematic projection with `© OpenStreetMap contributors` and
  ODbL 1.0 visible in the app. It is not a production public-tiles backend, a train-position source
  or proof that every rail/infrastructure attribute is verified.
- Публичный/партнёрский GTFS(-RT) feed для коридора не подтверждён.

Поэтому coordinates/IDs из карты считаются только read-only verification evidence, а не импортом;
полные stop patterns, infrastructure types и fare statuses не считаются verified. M0 scope принят
как 43 текущих пункта плюс один fail-closed planned slot.
