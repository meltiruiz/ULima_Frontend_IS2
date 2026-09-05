---
name: Application shell
description: Comportamiento compartido del shell autenticado de ULima++.
targets:
  - ../../../lib/main.dart
  - ../../../lib/components/header/app_header.dart
  - ../../../lib/pages/home/home_page.dart
  - ../../../test/components/header/app_header_test.dart
---

# Application shell

## Scope

- Esta spec cubre el encabezado global y comportamiento compartido del shell
  autenticado reutilizado por alumnos y docentes.
- No modifica navegación interna, sesión, permisos, APIs ni persistencia.

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

## Verification

- Ejecutar `dart format` sobre los archivos Dart modificados.
- Ejecutar `flutter analyze --no-pub`.
- Ejecutar `flutter test --no-pub test/components/header/app_header_test.dart`.
