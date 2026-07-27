# TrainRadar Mobile

Flutter shell для iOS/Android milestone M0.

Сейчас экран показывает только corridor scope, pending data и явно выключенный GPS. Проект не
содержит location package, platform permissions, background capability, map, API client или
realtime implementation.

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --simulator
```

Физические устройства, developer signing и реальные GPS-запуски требуют отдельного разрешения.
