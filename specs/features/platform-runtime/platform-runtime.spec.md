---
name: Platform Runtime
description: Configuracion de API base URL para APK Android contra backend desplegado.
targets:
  - ../../../lib/services/api_client.dart
  - ../../../README.md
  - ../../../test/services/api_client_test.dart
---

# Platform Runtime

## Requirements

- La APK Android debe consumir el backend desplegado por medio de `API_BASE_URL`.
- Los builds release no deben caer silenciosamente a `localhost` ni `10.0.2.2`.
- El desarrollo local puede conservar los fallbacks actuales cuando `API_BASE_URL` no se inyecta.

## UI Behavior

- No hay cambios visuales ni de navegación.
- Si un build release se genera sin `API_BASE_URL`, la app falla temprano al resolver el backend en vez de intentar usar una URL local inválida.

## API Dependencies

- `GET /`
- `GET /health`
- Resto de endpoints existentes consumidos por los services actuales a través de `ApiClient`.

## Verification

- `flutter analyze`
- `flutter test`
- `flutter run --dart-define=API_BASE_URL=https://u-lima-backend-is-2-one.vercel.app`
- `flutter build apk --dart-define=API_BASE_URL=https://u-lima-backend-is-2-one.vercel.app`
- `[@test] ../../../test/services/api_client_test.dart`
