---
name: Course Detail
description: Course detail tabs for announcements, advising, and contacts.
targets:
  - ../../../lib/pages/descripcion_cursos/**
  - ../../../lib/components/descripcion_cursos/**
  - ../../../lib/models/contacto_model.dart
  - ../../../lib/services/anuncio_service.dart
  - ../../../lib/services/contacto_service.dart
  - ../../../lib/services/docente_service.dart
---

# Course Detail

## Requirements

- R18: Students can view announcements from the section delegate.
- HU14: Students can view section contacts.
- HU25 integration: Contact cards can expose the public networking card when `optIn` is true.
- Advising UI remains in the course detail page, but its API and RSVP rules are documented in `specs/features/advising-student/advising-student.spec.md`.

## UI Behavior

- Course detail keeps separate tabs for announcements, advising, and contacts.
- Announcements display newest information first.
- Contacts display docente, optional jefe de practica, and students.
- Student contacts are sorted by role priority: delegado, subdelegado, estudiante.
- A visible networking card can be opened from contact rows; hidden cards keep the action disabled/neutral.

## API Dependencies

- `GET /course-detail/sections/:sectionId`
- `GET /course-detail/sections/:sectionId/announcements`
- `GET /course-detail/sections/:sectionId/contacts`
- `GET /course-detail/teachers`
- `GET /course-detail/enrollments`
- Asesorias: `GET /advising/section/:sectionId` + RSVP endpoints.

## Architecture

### Controller + Services
- `DescripCursosController` coordinates tab state and delegates HTTP access to services.
- `ContactoService` owns HTTP/parsing for section contacts and returns a typed `ContactosCursoResult`.

### Client DTO Mapper
- `contacto_model.dart` defines `ContactoCurso` and `ContactosCursoResult`.
- `docente_model.dart`, `user_model.dart`, and `networking_model.dart` parse nested DTOs.
- The UI does not read raw `Map<String, dynamic>` contact payloads.

### Validation And Error Surface
- Tab-specific errors stay independent: a failed contacts request does not hide announcements or advising.
- `ApiException` with 403 is treated as a permissions boundary instead of a retryable empty state.

## Verification

- `test/course_detail_sheet_test.dart`
