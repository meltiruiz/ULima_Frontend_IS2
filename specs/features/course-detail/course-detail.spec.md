---
name: Course Detail
description: Course detail tabs for announcements, advising, and contacts.
targets:
  - ../../../lib/pages/descripcion_cursos/**
  - ../../../lib/components/descripcion_cursos/**
  - ../../../lib/services/anuncio_service.dart
  - ../../../lib/services/asesoria_service.dart
  - ../../../lib/services/contacto_service.dart
  - ../../../lib/services/docente_service.dart
---

# Course Detail

> Ajustada el 2026-09-23 con las decisiones del dueño sobre los chats de curso
> (`specs/features/chat/chat.spec.md`). La ficha del alumno suma el botón «Chat del curso»
> en la franja de la sección (RF-CHAT-7). Aprobada por el dueño el 2026-09-23, junto con la
> spec del chat. La fase 1 del chat ya implementa este ajuste. Las pestañas y los contratos de
> esta spec no cambian.

> **Enmienda del 2026-09-25, aprobada por el dueño el 2026-09-26 e implementada el 2026-09-26**
> (`specs/features/recarga-portal/recarga-portal.spec.md`, RF-RCG-8). Hoy esta spec no describe
> el bloque de asistencia. La enmienda le suma, bajo las horas y el anillo, la hora de la última
> lectura, tomada de `asistenciaLeidaEn`, y el botón «Actualizar», que abre la hoja de recarga
> desde la ULima. Tras una recarga exitosa, la ficha vuelve a leer solo su sección con
> `DescripCursosController.recargarSeccion`, que prefiere `GET /course-detail/sections/:sectionId`
> y no repite `HorarioController.reload()`, y conserva la pestaña elegida. En el estado sin datos,
> el botón «Actualizar desde miUlima» pasa a decir «Actualizar desde la ULima» y abre la misma
> hoja en vez de `/portal-sync`, y el bloque muestra el aviso de error y la línea de lectura
> parcial encima del botón. Sin `RecargaUlimaService` registrado, el bloque queda como hoy.

`[@test] ../../../test/HU37_jeff/asistencia_recarga_test.dart`

## Requirements

- R18: Students can view announcements from the section delegate.
- R20: Students can view advising schedules inside the course detail.

## UI Behavior

- Course detail keeps separate tabs for announcements, advising, and contacts.
- Announcements display newest information first.
- Advising details include teacher, modality, location, and time.
- La franja de la sección, que hoy solo dice «Sección: N» centrado (`descrip_cursos.dart:70-90`), pasa a una fila con ese texto a la izquierda y, a la derecha, un botón visible con `LucideIcons.messagesSquare` y el texto «Chat del curso», que abre el chat de esa sección (`ChatPage`) con el nombre del curso, el código de la sección y el color que la grilla le da al curso. Ese color llega a la ficha en un parámetro opcional nuevo de `DescripCursosPage`, que la grilla llena con `colorPorCurso[idSeccion]` (`horario.dart:680`). La ficha solo la abre el alumno (`horario.dart:678-682`). El botón es de contorno, con texto a 4,5:1 e ícono a 3:1 en los dos temas, y un blanco táctil de 48 px. Al volver del chat, la ficha conserva su pestaña. El detalle está en RF-CHAT-7 de `specs/features/chat/chat.spec.md`.

## API Dependencies

- `GET /course-detail/sections/:sectionId`, que con la enmienda aprobada el 2026-09-26 trae también `asistenciaLeidaEn` en la `section`
- `GET /course-detail/sections/:sectionId/announcements`
- `GET /course-detail/sections/:sectionId/contacts`
- `GET /course-detail/teachers`
- `GET /course-detail/enrollments`
- Asesorías: `GET /advising/section/:sectionId` + RSVP endpoints (ver `specs/features/advising-student/advising-student.spec.md`).

## Verification

- Add linked tests for tab rendering and empty states.
- Verificar que el botón «Chat del curso» se ve en la franja de la sección y abre el chat de esa sección. `[@test] ../../../test/HU23_jeff/chat_ficha_curso_test.dart`
