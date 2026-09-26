# Frontend Knowledge

## Producto

ULima++ es una app Flutter para estudiantes de la Universidad de Lima. Centraliza gestión académica personal y flujos de delegado/subdelegado.

## Alcance Actual

- App centrada en estudiantes.
- No hay admin screens.
- Hay login docente (HU18): un `app_user` vinculado a `teacher.user_id` puede iniciar sesión con código+contraseña o Google SSO `@ulima.edu.pe` y gestionar asesorías extra.
- Backend oficial: `../ULima_Backend_IS2`.
- PostgreSQL definitivo es fuente de verdad a través del backend.
- Los JSON en `assets/data` son mocks descartables.
- No migrar JSON a PostgreSQL.

## Stack

- Flutter
- Dart
- GetX
- shared_preferences
- flutter_svg
- lucide_icons_flutter

## Fuentes Del Producto

- Requisitos y casos de uso: README del proyecto.
- Mockups: `docs/images/UI`.
- Diagramas de casos de uso: `docs/images/casos_uso`.
- Contrato API local: `docs/specs/api-contracts.md`.
- Specs frontend: `specs/features/<feature>/<feature>.spec.md`.

## Features

| Feature | Objetivo |
| --- | --- |
| Auth | Login, sesión y logout. |
| Academic profile | Carrera, currículo y especialidades. |
| Curriculum | Malla, progreso real y simulación visual. |
| Grades | Notas personales y promedio calculado. |
| Schedule | Horario y evaluaciones. |
| Course detail | Detalle de curso, asesorías, contactos y anuncios. |
| Alerts | Alertas personales. |
| Section management | Flujos de delegado/subdelegado. |

## Historias Reales

| ID | Historia |
| --- | --- |
| US01 | Iniciar sesión con código y contraseña. |
| US02 | Cerrar sesión. |
| US03 | Visualizar malla curricular. |
| US04 | Simular/actualizar estados visuales de cursos. |
| US05 | Seleccionar especialidad. |
| US06 | Registrar notas personales por evaluación. |
| US07 | Visualizar promedio personal por curso. |
| US09 | Visualizar horario y evaluaciones. |
| US13 | Visualizar asesorías. |
| US14 | Visualizar contactos de sección. |
| US15 | Recibir alertas. |
| US16 | Registrar anuncios como delegado/subdelegado. |
| US17 | Visualizar anuncios de sección. |
| US18 | Visualizar métricas agregadas de sección. |

## Reglas De Dominio Para La UI

- Roles válidos: `student`, `delegate`, `subdelegate`, `teacher`.
- Docentes pueden iniciar sesión (HU18) para gestionar asesorías extra.
- Solo cursos con matrícula activa deben mostrarse como actuales.
- La malla debe distinguir progreso real y simulación visual.
- Las notas que el alumno registra en la calculadora son personales y no oficiales (`simulated_grades`). La calculadora muestra además, fijas y con la marca “ULima”, las notas parciales que publica la ULima, que guarda la tabla `student_portal_score`, escribe solo `POST /portal-sync/refresh` y lee `GET /grades/me/ulima`.
- Riesgo académico: avance evaluado > 55% y promedio personal < 10.5.
- Alta carga: 3+ evaluaciones en una semana académica.
- Anuncios visibles solo para estudiantes matriculados en la sección.

## Arquitectura

No reestructurar `lib/` sin spec aprobada.

- `lib/pages/**`: pantallas y controllers.
- `lib/components/**`: UI reusable.
- `lib/services/**`: API, storage y fuentes de datos.
- `lib/models/**`: modelos/DTOs.
- `lib/configs/**`: tema y configuración.

Cuando se integre backend:

- Crear o usar API client central.
- Services consumen endpoints.
- Controllers consumen services.
- Widgets consumen controllers.
- Mocks JSON se eliminan del flujo normal de esa feature.

## Prioridad Recomendada De Specs

1. Auth.
2. Academic profile.
3. Curriculum.
4. Grades.
5. Schedule.
6. Course detail.
7. Alerts.
8. Section management.

## Decisiones No Negociables

- No implementar comportamiento sin spec aprobada.
- No usar JSON como fallback final.
- No duplicar reglas de negocio que pertenezcan al backend.
- No guardar datos académicos oficiales en `shared_preferences`.
- No cambiar mockups/flujo visual sin spec.
