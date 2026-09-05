---
name: Curriculum
description: Interactive curriculum grid, course status, prerequisites, and electives in Flutter.
targets:
  - ../../../lib/pages/malla/**
  - ../../../lib/services/malla_service.dart
  - ../../../lib/models/malla_models.dart
---

# Curriculum

## Requirements

- R4: Students can view their curriculum grid.
- R5: Students can update course status.
- R10: Students can view eligible courses.
- R11: Students can view the status of each course.
- R13: Specialty electives are visible when selected.

## UI Behavior

- The grid groups courses by cycle.
- Course cards expose the current status.
- Status changes update the visible grid state.
- Elective rendering follows selected specialties.
- The standalone route `/malla-clasica` permits vertical and horizontal
  orientation while active, keeps its own `Vista mapa (clásica)` title without
  the global authenticated header, and preserves zoom/pan navigation across the
  full curriculum canvas.
- In horizontal orientation, `/malla-clasica` keeps the header compact so only
  the `Vista mapa (clásica)` app bar remains visible; the course progress/count
  summary is hidden to maximize the curriculum canvas. In vertical orientation,
  the existing title, progress/count summary, and zoom controls remain unchanged.

## API Dependencies

- `GET /curriculum/me`
- `PUT /curriculum/me/simulation`
- `DELETE /curriculum/me/simulation/:curriculumCourseId`

## Verification

- Add linked widget tests for rendering by cycle, status, and prerequisites.
