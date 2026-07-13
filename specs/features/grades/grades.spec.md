---
name: Grades
description: Grade calculator, assessment inputs, syllabus flow, and current course average.
targets:
  - ../../../lib/pages/calculadora/**
  - ../../../lib/components/calculadora/**
  - ../../../lib/services/evaluations_service.dart
  - ../../../lib/services/api_client.dart
---

# Grades

## Requirements

- R6: Students can enter grades by assessment.
- R8: Assessment weights come from the syllabus via `GET /grades/me/courses`.
- R9: Course average updates after score changes (calculated via backend).

## UI Behavior

- Calculator shows assessments, weights, and registered scores.
- Score entry validates the 0 to 20 range.
- Course average updates after local changes.
- Las notas se persisten en backend vía `POST /grades/me/notes` (tabla `student_score`).
- El **cálculo de promedio ponderado** se delega al backend vía `POST /grades/me/calculate`.
- El frontend **no** realiza cálculos de promedio ni almacena notas localmente.

## API Dependencies

- `GET /grades/me/courses` — obtiene cursos y evaluaciones del sílabo con sus pesos.
- `POST /grades/me/calculate` — calcula el promedio ponderado en backend.
- `GET /grades/me/notes` — recupera notas guardadas del alumno.
- `POST /grades/me/notes` — guarda notas del alumno en backend.

## Verification

- Score entry validates the 0 to 20 range, and the average updates after changes (R6, R9).
  `[@test] ../../../test/HU07_aurelio/calculadora_flujo_cajanegra_test.dart`
- Registered assessments are excluded from the syllabus dropdown (R8).
  `[@test] ../../../test/HU06_aurelio/calculadora_evaluaciones_unitaria_test.dart`
