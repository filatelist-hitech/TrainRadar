# Product

## Обещание

TrainRadar помогает пассажиру понять, где находится пригородный поезд, движется ли он,
опаздывает ли и насколько можно доверять позиции и ETA. Расчёт никогда не маскируется под факт.

## Публичный M1 и пилот

Любой пользователь может открыть M1 read-only offline-schematic map для коридора Москва-Павелецкая →
Узуново. Экран не требует аккаунта, не запрашивает location и не показывает реальное положение
поезда; он показывает 43 current stops, `Котляково` только disabled planned slot, source version and
ODbL attribution. Расписание пока не integrated with this screen: internal Яндекс adapter существует
только в backend. При будущей недоступности сети schedule будет unavailable, а не offline/stale;
каждый экран с такими данными обязан показывать attribution Яндекса.

Первый пользователь M2–M6 — участник личной invite-only группы владельца. Пилот accountless,
5–15 участников, Россия only; публичный M1 не является запуском пилота.

## Основные jobs

1. Перед поездкой увидеть карту коридора и доступное plan schedule с его источником и временем обновления.
2. В пути включить режим «Я в этом поезде» и осознанно поделиться наблюдениями.
3. Понять ближайшую остановку, задержку и диапазон ETA без ложной точности.
4. Увидеть источник, возраст и причину недоступности данных; contributors появляются только в M3+.
5. Остановить передачу и отозвать consent без аккаунта и поддержки.

## Truth contract

Каждое публичное состояние несёт `source_type`, `occurred_at`, `age_seconds`, `confidence`,
версию расчёта и один из статусов:

- `official_actual`;
- `crowd_confirmed` — не менее трёх независимых install-capability;
- `estimated`;
- `stale_lost`.

Только первые два входят в live coverage. Индивидуальная GPS-точка не показывается.

## Сигналы ценности

- corridor completeness: 44/44 registry slots accounted for; operational layers contain only
  enabled stops (`Котляково` disabled until commissioning approval);
- доля целевых рейсов с `official_actual` или `crowd_confirmed`;
- position freshness и false confirmed-train rate;
- precision/recall прибытия на остановку;
- ETA p50/p90/p95 и coverage интервала;
- battery impact, crash-free sessions, consent grant/revoke;
- отсутствие утечек индивидуальных треков.

## Не-цели

Билеты, соцсеть, вся Россия, B2B-панель, сложная ML-платформа, рейтинги поездов,
автоматическое распознавание состава и продажа истории перемещений не входят в MVP.
