# Instrucciones Para Agentes Frontend

Este repositorio usa Tessl con Spec Driven Development. No implementes cambios funcionales sin spec aprobada.

## Contexto Obligatorio

- Frontend: Flutter, Dart, GetX, shared_preferences, flutter_svg y lucide_icons_flutter.
- Backend proveedor: `../ULima_Backend_IS2`.
- Contrato REST local: `docs/specs/api-contracts.md`.
- PostgreSQL definitivo vive detrás del backend.
- No existen archivos `assets/data/` en el proyecto; la única fuente de verdad es PostgreSQL a través del backend.

## Flujo Obligatorio

1. Lee `.tessl/RULES.md`.
2. Lee `KNOWLEDGE.md`.
3. Lee `docs/specs/workflow.md` y `docs/specs/feature-index.md`.
4. Ubica la spec en `specs/features/<feature>/<feature>.spec.md`.
5. Si no existe o no cubre el cambio, actualiza la spec primero.
6. Si la feature consume API nueva o modificada, coordina con backend y actualiza `docs/specs/api-contracts.md`.
7. Espera aprobación explícita de la spec.
8. Implementa solo archivos incluidos en `targets`.
9. Ejecuta `flutter analyze`.
10. Si agregas tests, ejecuta `flutter test` y enlaza tests en la spec con `[@test]`.

## Arquitectura Frontend

- Mantén la estructura actual de `lib/`.
- `lib/pages/**`: pantallas y controllers.
- `lib/components/**`: widgets reutilizables.
- `lib/services/**`: API, storage y acceso a datos.
- `lib/models/**`: modelos de dominio/DTOs.
- No mover carpetas ni hacer refactors amplios sin spec aprobada.

## Reglas De Integración

- No llamar HTTP desde widgets.
- No leer JSON desde widgets.
- Los services son la frontera de API.
- Un API client central debe manejar base URL, headers, token y errores.
- `shared_preferences` solo guarda sesión/token/preferencias permitidas.
- Las notas, alertas, anuncios, malla y horario deben venir del backend cuando su feature esté integrada.
- Si faltan datos en PostgreSQL, reportar el faltante; no volver a JSON.

## Reglas De UI

- Respeta mockups en `docs/images/UI` salvo cambio aprobado.
- Mantén GetX como mecanismo reactivo.
- Usa estados explícitos de loading, error, vacío y éxito.
- No agregues texto explicativo dentro de la app que no exista en spec/mockup.
- No cambies navegación global sin spec.

## Reglas De Dominio

- Usuarios: estudiantes.
- Roles: `student`, `delegate`, `subdelegate`, `teacher`.
- Docente puede iniciar sesión (HU18) y tiene su propio home (`teacher_home_page.dart`).
- Las notas que el alumno registra en la calculadora son personales y no oficiales (`simulated_grades`). La calculadora muestra además, fijas y con la marca “ULima”, las notas parciales que publica la ULima, que guarda la tabla `student_portal_score`, escribe solo `POST /portal-sync/refresh` y lee `GET /grades/me/ulima`.
- Riesgo académico depende del promedio personal.
- Alta carga depende de 3+ evaluaciones en una semana.
- La simulación de malla es visual y no debe confundirse con progreso real.

## Verificación

- `flutter analyze` después de cambios Dart/config.
- `flutter test` si hay tests.
- `flutter pub get` si cambia `pubspec.yaml`.
- Reportar warnings preexistentes por separado.

# Agent Rules <!-- tessl-managed -->

@.tessl/RULES.md follow the [instructions](.tessl/RULES.md)
