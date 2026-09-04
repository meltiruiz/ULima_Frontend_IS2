# ULima++ Frontend

App Flutter para estudiantes de la Universidad de Lima. Centraliza autenticación, perfil académico, malla curricular, notas personales, horario, asesorías, anuncios, alertas y flujo de delegado/subdelegado.

## Estado Actual

- La fuente de verdad es PostgreSQL a través del backend `ULima_Backend_IS2`.
- No existen archivos `assets/data/` en el proyecto.
- Toda integración con backend debe seguir el contrato local `docs/specs/api-contracts.md`, alineado con el contrato local del backend.
- Las specs frontend viven en `specs/features/<feature>/<feature>.spec.md`.
- No se debe reestructurar `lib/` sin spec aprobada.

## Stack

- Flutter
- Dart
- GetX
- shared_preferences
- flutter_svg
- lucide_icons_flutter

## Arquitectura Actual

```text
lib/
├── pages/        # Pantallas y controllers por página
├── components/   # Widgets reutilizables
├── services/     # API, almacenamiento local y acceso a datos
├── models/       # Modelos del dominio de la app
└── configs/      # Tema y configuración visual
```

Reglas:

- Las pantallas no deben llamar HTTP directamente.
- Los services encapsulan API/backend/storage.
- Los controllers GetX coordinan estado de pantalla.
- Los models adaptan DTOs a objetos de la app.
- `shared_preferences` debe guardar solo sesión/token/preferencias locales permitidas, no reemplazar PostgreSQL.

## Backend Y Datos

Backend proveedor:

```text
../ULima_Backend_IS2
```

Contrato REST:

```text
docs/specs/api-contracts.md
```

Principios:

- PostgreSQL es la fuente de verdad.
- No usar JSON como fallback cuando una feature ya consume API.
- Si faltan datos en backend/PostgreSQL, reportar el dato faltante.
- No implementar reglas de negocio distintas a las del backend.

## Features

| Feature | Pantallas/flujo |
| --- | --- |
| Auth | Login, restauración y cierre de sesión. |
| Academic profile | Configuración de carrera/especialidades y perfil. |
| Curriculum | Malla, progreso real y simulación visual. |
| Grades | Calculadora de notas personales por evaluación. |
| Schedule | Horario semanal y evaluaciones. |
| Course detail | Anuncios, asesorías y contactos de sección. |
| Alerts | Buzón de alertas personales. |
| Section management | Gestión de cursos/anuncios/métricas para delegado/subdelegado. |

## Reglas De Dominio Para UI

- Usuarios de app: estudiantes.
- Docentes pueden iniciar sesión (HU18) para gestionar asesorías extra.
- Roles UI válidos: `student`, `delegate`, `subdelegate`, `teacher`.
- La malla debe diferenciar progreso real de simulación visual.
- Las notas son personales y no oficiales.
- Las alertas de riesgo se basan en promedio personal, no en promedio de sección.
- Alta carga significa 3+ evaluaciones en una misma semana académica.
- Solo enrollments activos se muestran como cursos actuales.

## Specs

Antes de cambiar UI, services o models:

1. Revisa `AGENTS.md`.
2. Revisa `KNOWLEDGE.md`.
3. Revisa `docs/specs/feature-index.md`.
4. Actualiza o crea la spec de la feature.
5. Si cambia API, coordina primero con backend y actualiza `docs/specs/api-contracts.md`.
6. Espera aprobación explícita.
7. Implementa solo los `targets` aprobados.

## Comandos

```bash
flutter pub get
flutter analyze
flutter test
```

Si se modifica `pubspec.yaml`, ejecutar `flutter pub get`.

## Android APK

Para compilar la APK contra el backend desplegado:

```bash
flutter build apk --dart-define=API_BASE_URL=https://u-lima-backend-is-2-one.vercel.app
```

Para probar localmente la app Android contra el mismo backend:

```bash
flutter run --dart-define=API_BASE_URL=https://u-lima-backend-is-2-one.vercel.app
```

Notas:

- `API_BASE_URL` es obligatoria en builds release.
- Si no se inyecta en desarrollo, `ApiClient` mantiene los fallbacks locales actuales.

## Mockups

Los mockups siguen disponibles como referencia visual:

```text
docs/images/UI
```

La UI final debe respetar esos mockups salvo que una spec aprobada indique cambios.
