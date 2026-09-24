---
name: Schedule
description: Academic schedule, evaluation calendar, and weekly load visualization.
targets:
  - ../../../lib/pages/horario/**
  - ../../../lib/pages/home/home_page.dart
  - ../../../lib/services/evaluations_service.dart
  - ../../../lib/services/seccion_service.dart
---

# Schedule

> Ajustada el 2026-09-23 con las decisiones del dueño sobre los chats de curso
> (`specs/features/chat/chat.spec.md`). Horario queda solo como calendario y pierde la vista
> de lista «Mis chats», que se abría con el ícono de lista del header. Los chats del alumno
> pasan a su propia pestaña. Aprobada por el dueño el 2026-09-23, junto con la spec del chat.
> La fase 1 del chat ya implementa este ajuste. El resto de esta spec no cambia.

## Requirements

- R19: Students can view exams organized by week and day.
- R22: The system calculates evaluations per week.
- R23: High-load weeks are identified.
- R24: Class blocks show the classroom for each specific scheduled session.
- R25: Course colors can be rendered from backend-provided hex colors.
- R26: The schedule grid shows the current-time indicator for the current Lima day.

## UI Behavior

- **Unified schedule and evaluations**: `HorarioController` combines regular class sessions with scheduled assessments for the selected day and renders both in the same time grid.
- **Dynamic date mapping**: Assessments from `/schedule/me/assessments` include an ISO date that is mapped to the day text format used by `activeDay.dateText`.
- **Classrooms per session**: Each regular block uses `salon`/`aula` from that session, so a section can have different classrooms on different days.
- **Course colors**: Regular class blocks accept `color` as either a legacy name (`blue`, `green`, etc.) or a hex value in `#RRGGBB`/`#AARRGGBB` format.
- **Current-time line**: The grid shows a red current-time line only when the selected day is the current date in Lima, calculated as UTC-5, and the current time is between 7:00 and 22:00.
- **Course block tap**: Al tocar un bloque de curso, se navega a `DescripCursosPage` con el `idSeccion` correspondiente (no existe un details dialog separado para evaluaciones). Un bloque propio del alumno no es un curso: su toque abre la hoja de acciones de `specs/features/time-blocks/time-blocks.spec.md` (RF-BLQ-5).
- **High-load alert**: If the active academic week has 3 or more assessments, `isActiveWeekHighLoad` is true and the UI shows the existing warning banner under the day selector.
- **Portrait calendar fit**: In vertical orientation, the calendar grid renders the complete 7:00-22:00 day without vertical scrolling by compressing hour rows and course block content to the available viewport.
- **Course block alignment**: Course blocks align visually with the hour separators and keep a small inset from the start/end hour lines so their time range reads accurately.
- **Landscape weekly calendar**: In horizontal orientation, `HorarioPage` remains the same page and renders a weekly grid from Monday to Sunday with the current backend-backed class blocks, the student's own time blocks (`specs/features/time-blocks/time-blocks.spec.md`, RF-BLQ-4), course colors, evaluation markers, advising markers, tap behavior, and current-time indicator when applicable.
- **Landscape reference layout**: The horizontal calendar follows the compact timetable reference from `PrograMovil/lib/pages/horario/horario_semanal.dart`: an orange day/date strip, a narrow hour gutter, full-height day columns, compact rounded course blocks, and a dark student identity strip with code, full name, and current cycle. For a student, the strip also carries the weekly hours of their own time blocks next to the cycle («Tus bloques: 12 h esta semana», `specs/features/time-blocks/time-blocks.spec.md`, RF-BLQ-6), only when that total, rounded to one decimal, is greater than 0.
- **Landscape chrome removal**: When `HorarioPage` is shown horizontally from the authenticated shell, the global header and footer are hidden to maximize the schedule grid area.
- **Schedule-only rotation**: `HorarioPage` is the only authenticated footer page that may rotate horizontally for students, delegates, subdelegates, teachers, and teaching assistants; every other footer page remains portrait-only.
- **Solo calendario**: `HorarioPage` muestra siempre la grilla, en vertical y en horizontal, para alumnos y docentes. Sale la vista de lista «Mis chats» (`HorarioListView`, `horario.dart:1175-1178`), junto con el ícono del header que la alternaba (`app_header.dart:95-115`, BR-SHELL-F-03 de `specs/features/app-shell/app-shell.spec.md`) y el estado `isListView` del controlador (`horario_controller.dart:56-57` y `:656-658`). El alumno entra a los chats de sus cursos desde la pestaña Chats (RF-CHAT-5 y RF-CHAT-6 de `specs/features/chat/chat.spec.md`) o desde la ficha de un curso, a la que sigue llevando el toque de un bloque de curso (RF-CHAT-7). Al abrirla, la grilla le pasa además el color que le da al curso (`colorPorCurso[idSeccion]`, `horario.dart:680`), que la ficha usa para el chat. La bandeja de chats lee las secciones matriculadas y sus colores de `HorarioController` (`uniqueEnrolledCourses` y `colorPorCurso`), que además expone si terminó la primera carga de secciones (RF-CHAT-6). Los botones de bloques propios dependen solo de que el usuario sea alumno y de que la pantalla esté en vertical (RF-BLQ-1 y RF-BLQ-8 de `specs/features/time-blocks/time-blocks.spec.md`).

## API Dependencies

- `GET /schedule/me/sessions`, whose days also carry `isoDate`, the exact date that places the student's own time blocks (`null` when the cycle has no weeks; RF-BLQ-4 and RF-BLQ-7 of `specs/features/time-blocks/time-blocks.spec.md`)
- `GET /schedule/me/assessments`
- `GET /schedule/me/load`
- `GET /time-blocks/me` and `GET /time-blocks/me/occurrences?from=&to=`, only through `TimeBlocksService`, for the student's own time blocks, their cancelled days and their weekly hours (`specs/features/time-blocks/time-blocks.spec.md`, RF-BLQ-4, RF-BLQ-6 and RF-BLQ-7)

## Verification

- Verify that evaluation cards and regular classes coexist in the same time grid.
- Verify that regular class blocks render per-session classrooms and hex colors.
- Verify that the current-time line appears only on the current Lima day and only within schedule hours.
- Verify that the high-load banner appears only in weeks with 3+ assessments.
- Verificar que Horario no ofrece ninguna vista de lista ni el texto «Mis chats», y que el header del alumno en Horario solo muestra la campana. `[@test] ../../../test/HU23_jeff/chats_pestana_test.dart`
