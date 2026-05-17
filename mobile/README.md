# UBBike Mobile

Aplicación Flutter reducida para la entrega del 25/05. Incluye autenticación,
inicio, gestión de bicicletas y perfil.

La estructura mantiene las plataformas `android`, `ios` y `web`. En Windows se
puede probar Android y Web; iOS queda preparado para compilarse en macOS con
Xcode.

## Ejecutar

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3001
```

## Verificar

```bash
flutter analyze
flutter test
```
