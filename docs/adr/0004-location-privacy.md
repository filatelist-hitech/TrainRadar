# ADR 0004: Separate encrypted raw-GPS store with 24-hour maximum

- Status: Accepted
- Date: 2026-07-27

## Context

Exact passenger coordinates способны раскрыть дом, работу и поездки. Они нужны только кратко для
matching/debug quality, не для продукта как долговременная история. Operational DB не должен
становиться складом индивидуальных треков.

## Decision

- exact raw payload шифруется application-layer envelope encryption до отдельного store;
- per-payload/batch DEK wrapped внешним российским KMS/HSM;
- `expires_at` не позже `observed_at + 24h`;
- hard delete + key destruction; failure alert and fail-closed ingestion;
- public API and ordinary logs never expose individual raw data;
- foreground consent and separate active-trip background opt-in.

## Consequences

Compose raw DB хранит ciphertext columns и SQL constraint, но не доказывает production encryption,
delete job, KMS or backup erasure. Все эти проверки блокируют реальный GPS.
