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

> **Enmienda del 2026-09-25, aprobada por el dueño el 2026-09-26 e implementada el 2026-09-26**
> (`specs/features/recarga-portal/recarga-portal.spec.md`). La calculadora conserva su diseño y
> la maqueta aprobada suma tres cambios, dos en la calculadora y uno en `/mis-notas`. El birrete
> sin texto junto al título pasa a la fila «Notas oficiales», con la hora de la última lectura de
> la ULima, que lleva a `/mis-notas` (RF-RCG-5). Las notas que ya publicó la ULima entran como
> filas de `NotaTile` con la marca «ULima», sin tacho, y cuentan en el promedio, sin guardarse
> nunca en `simulated_grades` (RF-RCG-7). `/mis-notas` conserva su diseño y suma la franja
> «Actualizar desde la ULima», las evaluaciones de la ULima, la hoja de recarga y el aviso rojo
> (RF-RCG-6). Lo que no cambia, y los dos puntos aprobados que tocan la tarjeta del curso más allá
> de esos tres cambios, están en «Qué no cambia de la calculadora» de esa spec. La misma enmienda anota dos desfases de este texto con el código. Las notas del
> alumno se guardan en `simulated_grades`, no en `student_score`, y las pruebas de «Verification»
> viven hoy en `test/HU07_sam/` y `test/HU06_sam/`, no en las carpetas `_aurelio`.

`[@test] ../../../test/HU37_jeff/calculadora_ulima_test.dart`
`[@test] ../../../test/HU37_jeff/filas_calculadora_test.dart`
`[@test] ../../../test/HU37_jeff/mis_notas_ulima_test.dart`

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
- `GET /grades/me/ulima`, aprobado el 2026-09-26 y por implementar, con las notas que publica la ULima (RF-RCG-7 de `specs/features/recarga-portal/recarga-portal.spec.md`).

## Verification

- Score entry validates the 0 to 20 range, and the average updates after changes (R6, R9).
  `[@test] ../../../test/HU07_aurelio/calculadora_flujo_cajanegra_test.dart`
- Registered assessments are excluded from the syllabus dropdown (R8).
  `[@test] ../../../test/HU06_aurelio/calculadora_evaluaciones_unitaria_test.dart`
