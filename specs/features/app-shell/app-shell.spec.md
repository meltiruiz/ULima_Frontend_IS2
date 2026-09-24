---
name: Application shell
description: Comportamiento compartido del shell autenticado de ULima++.
targets:
  - ../../../lib/main.dart
  - ../../../lib/components/header/app_header.dart
  - ../../../lib/pages/home/home_page.dart
  - ../../../lib/pages/home/home_shell_config.dart
  - ../../../lib/components/footer/app_footer.dart
  - ../../../test/components/header/app_header_test.dart
---

# Application shell

> Ajustada el 2026-09-23 con las decisiones del dueño sobre los chats de curso
> (`specs/features/chat/chat.spec.md`). El footer del alumno suma la pestaña Chats
> (BR-SHELL-F-02) y el header ya no tiene el toggle lista/calendario de Horario
> (BR-SHELL-F-03). Aprobada por el dueño el 2026-09-23, junto con la spec del chat. La fase 1
> del chat ya implementa los dos cambios. El mismo día el dueño decide que con seis pestañas
> la etiqueta activa del footer vaya en 13 px (BR-SHELL-F-02). BR-SHELL-F-00 y BR-SHELL-F-01
> no cambian.

## Scope

- Esta spec cubre el encabezado global, las pestañas del footer y el comportamiento
  compartido del shell autenticado reutilizado por alumnos y docentes.
- Agrega la pestaña Chats al footer del alumno (BR-SHELL-F-02) y quita del header el
  control de lista de Horario (BR-SHELL-F-03). No crea rutas ni modifica sesión, permisos,
  APIs ni persistencia.

## UI Behavior

### BR-SHELL-F-00: Orientación del shell autenticado

- El shell autenticado mantiene la aplicación en orientación vertical para
  todas las pestañas y rutas, sin importar si el usuario es alumno, delegado,
  subdelegado, profesor o jefe de práctica.
- La única excepción es la pestaña `Horario`, donde el shell permite orientación
  vertical y horizontal para alumnos, profesores y jefes de práctica.
- La ruta standalone `/malla-clasica` también permite orientación horizontal
  mientras está activa, porque no pertenece al footer y conserva su propio
  título interno.
- Al cambiar desde `Horario` hacia cualquier otra pestaña del footer, el shell
  vuelve a restringir la orientación a vertical.
- Al salir o destruir el shell autenticado, la orientación global vuelve a
  vertical.

### BR-SHELL-F-01: Enlace promocional desde el nombre de la aplicación

- El texto `ULIMA++` del encabezado funciona como un control pulsable para
  alumnos y docentes.
- Al pulsarlo, la aplicación solicita abrir, fuera de ULima++, exactamente la
  siguiente URI mediante `url_launcher` y `LaunchMode.externalApplication`:
  `https://www.donbelisario.com.pe/clasico-combo-contundente?gsImpressionId=01KXPTTES6C5C0S9FKJG902C2G&gsListName=Recomendaciones%20-%20Promociones&gsIndex=3`.
- La acción no cambia de ruta dentro de GetX ni llama al backend.
- El control conserva el estilo visual del texto actual y expone semántica de
  botón para tecnologías de asistencia.
  `[@test] ../../../test/components/header/app_header_test.dart`

### BR-SHELL-F-02: Pestañas del footer

- El footer del alumno muestra, en este orden, Malla, Notas, Horario, Chats y Perfil
  (`home_shell_config.dart:55-73`). Un delegado conserva su pestaña Delegado justo antes de
  Perfil, así que su footer queda Malla, Notas, Horario, Chats, Delegado y Perfil.
- La pestaña Chats lleva un ícono de conversación de Lucide y abre la bandeja de chats de
  curso (RF-CHAT-5 y RF-CHAT-6 de `specs/features/chat/chat.spec.md`). Es vertical, como
  toda pestaña salvo Horario (BR-SHELL-F-00).
- La aplicación sigue abriendo en la primera pestaña, Malla para el alumno.
- El footer del docente no cambia.
- Con cinco pestañas o menos, la etiqueta activa del footer va en 14 px y las demás en 12 px.
  Con seis, el footer del delegado, la activa va en 13 px y las demás en 12, para que las
  seis etiquetas se lean completas en un Android de 360 dp y en el iPhone SE (RF-CHAT-5 de
  `specs/features/chat/chat.spec.md`, con sus medidas).
  `[@test] ../../../test/HU23_jeff/chats_pestana_test.dart`

### BR-SHELL-F-03: Controles del header

- Para el alumno, el header muestra solo la campana de alertas a la derecha, en todas las
  pestañas. El ícono que alternaba Horario entre lista y calendario
  (`app_header.dart:95-115`) sale, porque el horario queda solo como calendario
  (`specs/features/schedule/schedule.spec.md`) y el chat tiene su pestaña.
- Para el docente, el header sigue sin controles a la derecha.
- El header sigue sabiendo si la pestaña activa es Horario, solo para devolver la rotación
  del horario al volver de las alertas (`app_header.dart:128-131`).
  `[@test] ../../../test/components/header/app_header_test.dart`

## Verification

- Ejecutar `dart format` sobre los archivos Dart modificados.
- Ejecutar `flutter analyze --no-pub`.
- Ejecutar `flutter test --no-pub test/components/header/app_header_test.dart`.
- Ejecutar `flutter test --no-pub test/HU23_jeff/chats_pestana_test.dart`.
