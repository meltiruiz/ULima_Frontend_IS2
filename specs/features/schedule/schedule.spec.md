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
- **Course block tap**: Al tocar un bloque de curso, se navega a `DescripCursosPage` con el `idSeccion` correspondiente (no existe un details dialog separado para evaluaciones).
- **High-load alert**: If the active academic week has 3 or more assessments, `isActiveWeekHighLoad` is true and the UI shows the existing warning banner under the day selector.
- **Portrait calendar fit**: In vertical orientation, the calendar grid renders the complete 7:00-22:00 day without vertical scrolling by compressing hour rows and course block content to the available viewport.
- **Course block alignment**: Course blocks align visually with the hour separators and keep a small inset from the start/end hour lines so their time range reads accurately.
- **Landscape weekly calendar**: In horizontal orientation, `HorarioPage` remains the same page and renders a weekly grid from Monday to Saturday with the current backend-backed class blocks, course colors, evaluation markers, advising markers, tap behavior, and current-time indicator when applicable.
- **Landscape reference layout**: The horizontal calendar follows the compact timetable reference from `PrograMovil/lib/pages/horario/horario_semanal.dart`: an orange day/date strip, a narrow hour gutter, full-height day columns, compact rounded course blocks, and a dark student identity strip with code, full name, and current cycle.
- **Landscape chrome removal**: When `HorarioPage` is shown horizontally from the authenticated shell, the global header and footer are hidden to maximize the schedule grid area.
- **Schedule-only rotation**: `HorarioPage` is the only authenticated footer page that may rotate horizontally for students, delegates, subdelegates, teachers, and teaching assistants; every other footer page remains portrait-only.

## API Dependencies

- `GET /schedule/me/sessions`
- `GET /schedule/me/assessments`
- `GET /schedule/me/load`

## Verification

- Verify that evaluation cards and regular classes coexist in the same time grid.
- Verify that regular class blocks render per-session classrooms and hex colors.
- Verify that the current-time line appears only on the current Lima day and only within schedule hours.
- Verify that the high-load banner appears only in weeks with 3+ assessments.
