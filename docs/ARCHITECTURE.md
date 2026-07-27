# Architecture

## Shape

Go modular monolith обслуживает REST и будущий SSE. Модули разделены доменными интерфейсами,
но разворачиваются одним процессом, пока измерения не докажут необходимость выделения сервисов.
Flutter — единственный клиент MVP. Redis, ClickHouse, Python/ML и web не добавляются.

## C4 Context

```mermaid
flowchart LR
    Rider["Приглашённый пассажир"] --> Mobile["TrainRadar Mobile"]
    Mobile --> API["TrainRadar API"]
    API --> Carrier["Официальные расписания/телеметрия (если доступны)"]
    API --> Yandex["Яндекс.Расписания API\nM1 cache-only"]
    API --> OSM["Versioned OSM extract"]
    Owner["Владелец пилота / оператор ПД"] --> API
    Tutu["Tutu MCP"] -. "только ручная point-check сверка" .-> Owner
```

## C4 Containers

```mermaid
flowchart TB
    Mobile["Flutter iOS/Android"]
    API["Go modular monolith\nREST + reserved SSE"]
    Operational[("PostgreSQL + PostGIS\noperational/spatial")]
    Raw[("Separate raw store\nciphertext only, <=24h")]
    Keys["External Russian KMS/HSM\nnot provided in M0"]

    Mobile -->|REST; future SSE| API
    API --> Operational
    API -->|ciphertext + wrapped DEK| Raw
    API --> Keys
    Raw -. "hard delete + key destruction" .-> Keys
```

В M0 API не подключён к БД и SSE отвечает `501`. В M1 future schedule adapter использует
Яндекс.Расписания API через Go backend: ключ только server-side, in-memory cache ≤300 секунд,
без persistence и без offline schedule. Compose проверяет только изоляцию dev stores.
Локальный volume сам по себе не является production encryption-at-rest.

## Модули backend

- `corridor`: registry, rail graph versions, stop patterns;
- `schedule`: source adapters, trips, service dates;
- `observation`: consented immutable inputs and validation;
- `matching`: future candidate generation and train grouping;
- `position`: public truth state and freshness;
- `prediction`: future delay/ETA;
- `privacy`: retention, deletion, access audit;
- `httpapi`: REST/SSE transport;
- `observability`: logs, metrics, traces without exact coordinates.

M0 реализует только transport shell, truth-state primitives и raw-retention policy.

## Future data flow (не реализован)

```mermaid
flowchart LR
    GPS["Consented mobile observation"] --> Edge["On-device minimization"]
    GTFS["Schedule/GTFS(-RT)"] --> Normalize["Versioned adapters"]
    OSM["Versioned OSM geometry"] --> Graph["Rail graph version"]
    Edge --> Ingest["Validation + encrypted raw write"]
    Ingest --> Candidate["Trip candidates"]
    Normalize --> Candidate
    Graph --> Match["Map matching + uncertainty"]
    Candidate --> Match
    Match --> Aggregate["Independent capability aggregation"]
    Aggregate --> Public["Public position state"]
    Public --> ETA["Transparent ETA model"]
    Public --> SSE["SSE projection"]
    ETA --> SSE
```

Точная точка пассажира не проходит в public projection.

## Observation lifecycle (не реализован)

```mermaid
stateDiagram-v2
    [*] --> ReceivedEncrypted
    ReceivedEncrypted --> Rejected: invalid/replay/outlier
    ReceivedEncrypted --> Candidate: valid + active consent
    Candidate --> MatchedTrain: schedule/graph evidence
    Candidate --> Unmatched: ambiguous
    MatchedTrain --> CrowdConfirmed: >=3 independent capabilities
    MatchedTrain --> Estimated: insufficient independent evidence
    CrowdConfirmed --> StaleLost: freshness expired
    Estimated --> StaleLost: model horizon expired
    ReceivedEncrypted --> Deleted: <=24h hard delete
```

## Planned map matching

Для M2/M3 планируется воспроизводимый HMM/route-constrained matcher: candidate rail segments из
versioned PostGIS graph, emission score по расстоянию/accuracy, transition score по времени,
скорости и направлению, затем ambiguity margin. Parallel-track ambiguity не скрывается:
если margin ниже порога, observation остаётся unmatched. Пороги калибруются на обезличенном replay;
в M0 нет кода, geometry или заявлений о точности.

## Planned ETA baseline

Для M5: scheduled time + наблюдаемая delay на последней подтверждённой контрольной точке +
эмпирические segment runtimes по service class/time bucket. Результат — интервал, confidence,
model version и calculated_at. Оценка: chronological holdout, p50/p90/p95 MAE, interval coverage
и отдельный degradation set. ML рассматривается только после baseline.

## Deployment and degradation

Первый deployment target не выбран. Если official feed пропал, система не подменяет его crowd
без смены state. Если независимых contributors меньше трёх — только estimate/unconfirmed internal
candidate. При storage/KMS failure raw ingestion fail-closed; read-only map может продолжить работу.
