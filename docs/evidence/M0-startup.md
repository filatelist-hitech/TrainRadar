# M0 Startup Evidence

- Verified at: 2026-07-27T20:28:23Z / 2026-07-27 23:28 MSK
- Workspace: `/Users/filatelist/Documents/it/trainradar`
- Git: initialized branch `main`, no commits
- Toolchain: Go 1.25.5; Flutter 3.44.0 / Dart 3.12.0; Xcode 26.6;
  Android SDK 36.0.0; Docker client/server 29.6.2; Ruby 2.6.10

## Automated results

| Command / check | Result |
|---|---|
| `make check` | PASS |
| `ruby scripts/validate_reference_data.rb` | PASS; 44 unique ordered stops; 44/44 still `pending` |
| data negative suite | PASS; 6 runs, 16 assertions |
| `ruby scripts/validate_openapi.rb` | PASS; OpenAPI 3.1, REST/SSE skeleton, four truth states |
| OpenAPI negative suite | PASS; 3 runs, 6 assertions |
| `go vet ./...` / `go test ./...` | PASS |
| `go test -race -cover ./...` | PASS; domain 75%, httpapi 90.9%, rawgps 75% |
| `go build -o /tmp/trainradar-api-m0 ./cmd/api` | PASS |
| API process smoke | PASS; `/healthz` 200, `/v1/status` 200, reserved SSE 501 |
| `flutter analyze` / `flutter test` | PASS; no issues, 1 widget test |
| `flutter build apk --debug` | PASS; debug APK produced |
| `flutter build ios --simulator` | PASS; Simulator `Runner.app` produced, no signing |
| platform permission scan | PASS; no location SDK/permission/background capability or developer team |
| `docker compose config --quiet` | PASS |
| `make compose-up` | PASS after multi-arch image fix; both final services healthy |
| operational SQL smoke | PASS; PostGIS `3.6`, schema `trainradar` |
| raw SQL smoke | PASS; ciphertext-only columns and `retention_positive`/`retention_max_24h` |
| 25-hour dummy ciphertext insert | PASS; rejected by `retention_max_24h` |
| operational/raw Docker networks | PASS; separate networks |
| `git diff --check` | PASS in final handoff run |

## Defects found and resolved during verification

1. Upstream `postgis/postgis:17-3.5` is amd64-only and failed on Apple arm64.
2. Initial multi-arch PostGIS layer was incompatible with Debian Bookworm glibc.
3. Final image uses pinned official `postgres:17-trixie` plus pinned multi-arch pglayers PostGIS;
   clean initialization and `CREATE EXTENSION postgis` passed.
4. Semantic OpenAPI validator found missing required `contributors`; contract corrected.

## NOT_RUN

- Physical iOS run: `NOT_RUN` (a device was visible, deliberately not used).
- Physical Android run: `NOT_RUN`.
- Real GPS collection/background tracking: `NOT_RUN` and prohibited in M0.
- Actual train/corridor field test: `NOT_RUN`.
- KMS/HSM encryption, hard-delete worker, key destruction and backup erasure: `NOT_RUN`.
- Target-user comprehension/accessibility field study: `NOT_RUN`.
- Carrier/infrastructure/Tutu verification of the 44 records: `NOT_RUN` in this startup run.
  A later carrier-only point-check is recorded in `M0-reference-verification.md`.

## Limitations and residue

- Build artifacts under `mobile/build/` are git-ignored.
- Containers were stopped with `docker compose stop`; final M0 volumes were not deleted.
- Failed/clean-room Compose attempts left additional stopped containers/volumes with names beginning
  `trainradar` and `trainradar-m0-verify`. They contain only local test database initialization,
  no real GPS or user data. They were not removed because deletion was not authorized.
- A healthy local raw store proves schema isolation and constraints, not production encryption-at-rest,
  KMS separation or deletion execution.
- Registry values remain seed-only `pending`; automated structure PASS is not source verification.
