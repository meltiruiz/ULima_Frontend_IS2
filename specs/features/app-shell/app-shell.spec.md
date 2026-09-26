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
> Ajustada el 2026-09-25 por la spec del splash animado (`specs/features/splash/splash.spec.md`),
> que suma BR-SHELL-F-04, la estrella del logo junto a «ULIMA++» y los íconos claros de la barra
> de estado sobre el header. **Aprobado por el dueño el 2026-09-26** junto con esa spec, con la
> estrella de su decisión S-11, e implementado el 2026-09-26. Ese ajuste no cambia BR-SHELL-F-00 a
> BR-SHELL-F-03.
> Enmendada el mismo 2026-09-25 por la misma spec, porque el dueño pide que quien tiene sesión vea
> su horario después del splash (RF-SPL-20). BR-SHELL-F-02 suma la pestaña inicial Horario con
> un argumento de ruta y BR-SHELL-F-00 suma la orientación de Horario mientras la intro cubre la
> pantalla. **El dueño aprueba las dos enmiendas el 2026-09-26** junto con esa spec, con sus
> decisiones S-24, S-25, S-26 y S-31 en la opción por defecto, y deja explícita S-24, así que todos
> los roles abren en Horario. Quedan implementadas el 2026-09-26.

## Scope

- Esta spec cubre el encabezado global, las pestañas del footer y el comportamiento
  compartido del shell autenticado reutilizado por alumnos y docentes.
- Agrega la pestaña Chats al footer del alumno (BR-SHELL-F-02) y quita del header el
  control de lista de Horario (BR-SHELL-F-03). No crea rutas ni modifica sesión, permisos,
  APIs ni persistencia.
- BR-SHELL-F-04, aprobada el 2026-09-26, pone la estrella del logo junto a «ULIMA++» y fija
  los íconos claros de la barra de estado sobre el header. La ruta `/arranque` y la intro que
  aterriza en el header son de la spec del splash.
- La enmienda de BR-SHELL-F-00 y BR-SHELL-F-02, aprobada el 2026-09-26, abre el shell en
  Horario cuando la ruta lo pide. La intro que pasa ese argumento es de la spec del splash, y la
  bienvenida con Ulises que también lo pasa es de su spec nueva.

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
- Enmienda aprobada el 2026-09-26 (RF-SPL-20 de la spec del splash). Si el shell se monta en
  Horario mientras la capa de la intro cubre la pantalla, sigue en vertical y pide las
  orientaciones de Horario cuando la capa se retira (decisión S-26 de esa spec). Pasa lo mismo
  cuando llega desde el paso al horario de la bienvenida, que usa la misma capa (RF-BIEN-11).

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
- La aplicación sigue abriendo en la primera pestaña, Malla para el alumno, cuando la ruta
  `/home` llega sin argumento.
- Enmienda aprobada el 2026-09-26 (RF-SPL-20 de la spec del splash). Con el argumento de ruta
  `{'pestana': 'horario'}`, el shell abre en la pestaña Horario, que busca por su etiqueta, así que
  sirve para el alumno, el delegado, el subdelegado, el profesor titular y el jefe de práctica
  (decisiones S-24 y S-31 de esa spec). Lo pasan la intro del splash y, según su spec, la
  bienvenida con Ulises, también cuando el alumno sin especialidad termina su test en la
  conversación. Las demás llegadas a `/home` no lo pasan (decisión S-25 de esa spec).
  `[@test] ../../../test/splash/home_pestana_inicial_test.dart`
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

### BR-SHELL-F-04: Estrella del logo junto a «ULIMA++» (aprobada el 2026-09-26)

- A la izquierda del texto «ULIMA++», el header muestra la estrella del logo en blanco
  (`onPrimary`), de 26 dp de punta a punta, a 10 dp del texto y centrada en su línea, en los temas
  claro y oscuro, para alumnos y docentes. Hoy el header muestra solo el texto
  (`app_header.dart:79-88`) y el `SvgPicture` de `logo.svg` está comentado (`:161-168`).
- La estrella se pinta con la geometría de la intro (RF-SPL-2 de
  `specs/features/splash/splash.spec.md`) y no con `assets/images/logo.svg`, para que la estrella
  de la intro aterrice sobre la misma figura (RF-SPL-11).
- Es decorativa. No es pulsable ni tiene semántica propia, y el enlace de BR-SHELL-F-01 sigue
  siendo solo el texto, con su etiqueta.
- El alto del header no cambia, porque lo fija la campana de 30 dp, o el espacio de 30 dp del
  docente.
- El estilo del texto «ULIMA++» vive en un solo lugar, porque la intro dibuja una réplica suya, y
  el header informa a la intro dónde quedan su estrella y su texto una vez que se dibuja (RF-SPL-11).
- El header declara íconos claros en la barra de estado con un
  `AnnotatedRegion<SystemUiOverlayStyle>`, en los temas claro y oscuro, porque la intro del splash
  deja aplicado el último estilo de la barra y hoy ningún archivo de `lib/` fija uno (RF-SPL-4 de
  la spec del splash). Esta parte no depende de la decisión S-11.
- La misma estrella forma el sello de la bienvenida con Ulises, en la franja de la conversación y
  en la cabecera de las pantallas de «¿Olvidaste tu contraseña?» (RF-BIEN-4 y RF-BIEN-20 de
  `specs/features/bienvenida/bienvenida.spec.md`).
- El dueño descarta la alternativa de la decisión S-11 de la spec del splash, así que la estrella
  entra.
  `[@test] ../../../test/components/header/app_header_test.dart`

## Verification

- Ejecutar `dart format` sobre los archivos Dart modificados.
- Ejecutar `flutter analyze --no-pub`.
- Ejecutar `flutter test --no-pub test/components/header/app_header_test.dart`.
- Ejecutar `flutter test --no-pub test/HU23_jeff/chats_pestana_test.dart`.
- Con la enmienda de BR-SHELL-F-02, ejecutar también
  `flutter test --no-pub test/splash/home_pestana_inicial_test.dart`.
