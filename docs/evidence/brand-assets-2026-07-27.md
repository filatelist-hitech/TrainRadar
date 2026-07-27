# Brand Assets Integration Evidence

- Checked at: 2026-07-27T21:01:12Z / 2026-07-28 00:01 MSK
- Scope: approved TrainRadar concept `05-soft-3d` only
- Canonical master: `assets/brand/trainradar/master/trainradar-icon-master-1254.png`
- Master SHA-256: `74761a3e5ffc28007f29ba32c4f8c0514ef89c88d276897a61ce1de795dbab2e`
- Source pack: `trainradar-icon-production.zip`

## Automated results

| Command / check | Result |
|---|---|
| `ruby scripts/validate_brand_assets.rb` | PASS: immutable master checksum, fixed platform matrix, dimensions, alpha policy, strict white notification glyph, iOS `Contents.json`, Android manifest/adaptive XML and deployment drift |
| `ruby test/validate_brand_assets_test.rb` | PASS: 5 runs, 10 assertions |
| `make check` | PASS: data, brand, Go, Flutter analysis/tests, OpenAPI and Compose syntax |
| `flutter build apk --debug` | PASS: `mobile/build/app/outputs/flutter-apk/app-debug.apk` |
| `flutter build ios --simulator` | PASS: `mobile/build/ios/iphonesimulator/Runner.app`; no signing |
| `jq` / `xmllint` for brand manifest, iOS JSON and Android XML | PASS |
| `git diff --check` | PASS |

## Visual asset inspection

- Square launcher: PASS — train, turquoise radar/rails and orange live-point are visible.
- Round launcher: PASS — Android receives the same approved launcher bitmap and applies its own round
  mask. The supplied legacy round PNG was visually blank (only plum background), so it was replaced
  byte-for-byte with the matching approved launcher PNG; no master modification or new artwork.
- Adaptive/maskable foreground: PASS — composition is padded inside the Android adaptive safe area.
- Android notification glyph: PASS — strict `#FFFFFF` + alpha glyph at mdpi 24×24; it is separate
  from launcher. RGB was deterministically normalized while preserving the supplied alpha silhouette.
- Small iOS AppIcon: PASS — 20×20 derivative remains recognisable.

## NOT_RUN

- Physical iOS launcher rendering and App Store preview: `NOT_RUN`.
- Physical Android launcher rendering, Android 13 themed icon and notification shade: `NOT_RUN`.
- Store upload/metadata validation: `NOT_RUN` (not requested).

## Scope boundary

`mobile/web` does not exist. No favicon, PWA manifest or web configuration was added.
