# TrainRadar Mobile

Flutter read-only M1 map для iOS/Android.

Экран показывает встроенную offline-схему Москва-Павелецкая → Узуново: 43 current stops, disabled
planned slot `Котляково`, versioned OSM source и ODbL attribution. Проект не содержит location
package, platform permissions, background capability, API client, schedule integration или realtime
implementation; public OSM tiles не используются.

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --simulator
```

Физические устройства, developer signing и реальные GPS-запуски требуют отдельного разрешения.

<!-- BEGIN GENERATED: mobile-capabilities -->
| Source of truth | Value |
| --- | --- |
| Package | `trainradar_mobile` |
| Flutter platforms | `iOS`, `Android` |
| Entrypoint | `mobile/lib/main.dart` |
| Module checks | `flutter analyze`, `flutter test` |
<!-- END GENERATED: mobile-capabilities -->
