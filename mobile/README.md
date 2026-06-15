# UBBike Mobile

Aplicacion movil Flutter para el prototipo MVP de UBBike.

## Ejecutar

```bash
flutter pub get
flutter run
```

Por defecto la app se conecta al backend local en:

- Web/escritorio/iOS simulator: `http://localhost:3000`
- Emulador Android: `http://10.0.2.2:3000`

Puede sobrescribirse con:

```bash
flutter run --dart-define=API_BASE_URL=http://IP_DE_TU_BACKEND:3000
```

## Preparar prueba en iOS

El proyecto ya incluye el target nativo `ios/` con permisos de camara, fotos y red local para pruebas. Para probarlo en simulador o iPhone fisico se debe abrir desde macOS con Xcode instalado:

```bash
cd mobile
flutter pub get
flutter doctor
flutter run -d ios
```

Para un iPhone fisico, abra `ios/Runner.xcworkspace` en Xcode y configure `Signing & Capabilities` con su Apple Team. Si la API corre en otra maquina de la red, ejecute Flutter indicando la URL real del backend:

```bash
flutter run -d ios --dart-define=API_BASE_URL=http://IP_DE_TU_BACKEND:3000
```

## Verificar

```bash
flutter analyze
flutter test
```

El prototipo incluye vistas para usuario, guardia y central de seguridad.
