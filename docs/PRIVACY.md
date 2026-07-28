# Privacy

## Роли и граница

M1 — публичный read-only map/schedule surface без аккаунтов, location permissions, GPS,
install-capability или персональных данных. Яндекс API key остаётся server-side secret; schedule
cache существует только в памяти backend не более 300 секунд и не содержит user identity.
M1-02b map packaged as an offline schematic contains only public corridor/stop projection and ODbL
attribution; it makes no network tile request, records no interaction and does not turn a train or
passenger into a location signal.

Пилот M2–M6 проводится только в России, invite-only, 5–15 участников. Зафиксированное продуктовое
решение: оператор персональных данных — владелец как физическое лицо. Это не заключение о
полноте compliance; применимость уведомлений, локализации, формы согласия и мер защиты требует
юридической проверки до первой реальной точки.

## Purpose limitation

Разрешённые цели:

1. определить агрегированное положение выбранного пригородного рейса;
2. рассчитать качество, задержку/ETA и обнаружить аномалию;
3. показать участнику собственную активную поездку;
4. расследовать security/privacy incident по минимальному audit trail.

Маркетинг, profiling, рейтинг пассажиров, продажа или публичный individual history запрещены.

## Consent

- Accountless invite выдаёт ограниченную capability, не публичный профиль.
- Foreground location запрашивается в контексте «Начать поездку» после plain-language объяснения.
- Background — отдельный opt-in, не pre-checked; только во время активной поездки.
- UI постоянно показывает активный сбор и kill switch.
- Revocation немедленно прекращает новые observations; будущий upload очереди удаляется.
- Отказ не блокирует просмотр доступной агрегированной информации.

## Data minimization и retention

| Data | Store | Retention |
|---|---|---|
| exact raw GPS payload | отдельный ciphertext-only raw store | максимум 24 часа |
| per-observation DEK | внешний KMS/HSM | уничтожается вместе/раньше hard delete |
| derived aggregate train track | operational store | policy pending; без individual link |
| rotating install capability | security boundary | минимальный период anti-replay; pending |
| own-trip local history | device | user-controlled; server sync не утверждён |
| consent receipt | privacy boundary | срок pending legal review |
| access audit | restricted operational log | срок pending legal/security review |

M0 не собирает данные. Dev raw schema только запрещает expiry >24h; delete worker, KMS и production
encryption не реализованы.

Brand launcher, adaptive и notification assets не содержат GPS, capability, персональный идентификатор
или telemetry и не добавляют location permission/SDK. Они остаются публичными статическими ресурсами.

## Encryption and separation

- TLS для transit.
- Envelope encryption до записи: unique DEK на payload/batch, KEK вне raw DB.
- Raw store не содержит plaintext coordinates и не имеет foreign key к operational user model.
- Operational DB не хранит exact raw GPS.
- Production keys и data residency — российская инфраструктура, выбор провайдера pending.

## Pseudonymization and deanonymization resistance

Capabilities ротируются; публичный contributor count агрегирован. Small-cell data, exact route
history, timing correlations и query patterns не выдаются. Доступ к raw требует break-glass role,
reason, time-bound grant и audit.

## Deletion

Hard-delete job должен:

1. выбрать expired ciphertext по `expires_at`;
2. уничтожить/отозвать соответствующий key material;
3. удалить row и проверить отсутствие в replicas/backups по утверждённой политике;
4. записать aggregate deletion evidence без observation ID/coordinates.

Failure запускает alert и fail-closed ingestion. Backup design остаётся open question.

## Public/API rules

Запрещены endpoint индивидуальных треков, точек, capability lookup и raw export. Даже владелец
пилота видит aggregate health; raw access — только отдельная audited incident procedure.
