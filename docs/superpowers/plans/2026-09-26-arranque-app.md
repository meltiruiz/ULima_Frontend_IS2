# Plan de implementación del arranque de la app (splash animado y bienvenida con Ulises)

> **Para agentes.** SUB-SKILL REQUERIDA. Usa `superpowers:subagent-driven-development`
> (recomendado) o `superpowers:executing-plans` para ejecutar este plan tarea por tarea. Los pasos
> usan casillas (`- [ ]`) para llevar la cuenta.

**Objetivo.** Que la app abra con un splash nativo que no corta el logo y una intro animada al
azar (Ensamble, Incremento o Código) que corre mientras carga, que termina en `/home` abierto en
Horario o, sin sesión o sin especialidad, en el relevo sin salto a la bienvenida con Ulises, y que
esa bienvenida reemplace a la tarjeta del login con una conversación en la que el que vuelve
entra, el nuevo crea su cuenta y hace su test y el alumno sin especialidad hace el test, con el
logo entero en todo momento, hasta su horario.

**Arquitectura.** Una sola geometría del logo en `lib/components/logo/` pinta el PNG del nativo,
la intro, la estrella de la cabecera y el sello. `main()` llama a `runApp` enseguida y la carga de
hoy corre en paralelo con la intro, que vive en una capa permanente del `builder` de
`GetMaterialApp` (`lib/pages/splash/`). Cada variante es una línea de tiempo pura que devuelve una
escena del logo por milisegundo, y las salidas hacia `/home` son funciones puras del instante y de
la cabecera medida. La bienvenida ocupa `/login` con un controlador permanente que decide la
conversación y una página que la dibuja y marca su ritmo. Las reglas puras de la bienvenida van en
`lib/domain/bienvenida/`, y el test de especialidad corre en la conversación con el mismo
controlador de su ruta, creado por la bienvenida con el origen `bienvenida`. El paso al horario lo
dibuja la misma capa del splash.

**Stack.** Flutter 3.47.2 en local (la CI compila el APK con 3.44.2), Dart 3.11, GetX 4.7.3,
`shared_preferences`, `flutter_native_splash` 2.4.4 en `dev_dependencies`, `lucide_icons_flutter`
y `flutter_test` con dobles escritos a mano. Sin dependencias nuevas.

**Specs.** `specs/features/splash/splash.spec.md` (RF-SPL-1 a RF-SPL-21) y
`specs/features/bienvenida/bienvenida.spec.md` (RF-BIEN-1 a RF-BIEN-21), aprobadas por el dueño el
2026-09-26 en `f0376e8` con todas sus opciones por defecto salvo S-29, B-9 y B-10, que el dueño
elige ese día. Las acompañan sus enmiendas aprobadas en `specs/features/app-shell/app-shell.spec.md`
(BR-SHELL-F-00, BR-SHELL-F-02 y BR-SHELL-F-04), `specs/features/auth/auth.spec.md`,
`specs/features/registro/registro.spec.md` y la enmienda de la bienvenida que la spec del test de
especialidad escribe al final desde el 2026-09-26. La spec de la bienvenida suma ese día una
enmienda técnica a sus targets, con `google_sign_in_button.dart` y `google_sign_in_button_stub.dart`,
que cambia la Tarea 32 sin tocar ningún comportamiento aprobado. Las specs son la fuente de los
valores exactos (tiempos, medidas, colores, textos y contrastes) y mandan si este plan difiere de
ellas. Sus referencias `archivo:línea` apuntan a `41ff0a6` y `4e2a0b2`. El código que este plan
cita es el de `fcbf2e7`, y en los archivos que no trae el merge de `main` coincide con el de
`f0376e8`.

**Repo y rama.** `$REPO`, el worktree de la rama `feat/splash-animado`, que al corregir el plan
está en `fcbf2e7`, el merge que trae `main` con el test de especialidad.

## La rama del test de especialidad

La bienvenida dibuja el test de especialidad dentro de la conversación y reutiliza su controlador,
sus piezas de pantalla, sus tokens de color y los cambios de `AuthService` que trae la rama
`feat/test-especialidad-fe` (spec `specs/features/specialty-test/specialty-test.spec.md` y plan
`docs/superpowers/plans/2026-09-25-specialty-test-app.md`). Esa rama cierra su Tarea 19 en
`f4871c1`, entra a `main` con el merge `87403a1` y llega a `feat/splash-animado` con el merge
`fcbf2e7`, antes de la Tarea 1.

- **Sobre qué se implementa.** Todas las tareas corren sobre `fcbf2e7`, que ya trae el test de
  especialidad entero, así que ninguna tarea hace un merge. Si `origin/main` avanza antes de
  terminar el plan, se trae con `git merge --no-ff origin/main` en un commit aparte, entre dos
  tareas, y el informe anota qué cambió.
- **Desde qué tarea depende.** Las Tareas 1 a 19 no usan el código del test, aunque ya está en la
  rama. Son el splash completo y las piezas de la bienvenida que no tocan el test. La Tarea 14
  solo conserva su registro en la carga del arranque y sus rutas en `paginasDeLaApp`. El uso
  empieza en la **Tarea 20**, con los tokens `test*`, y sigue en todas las tareas desde ahí. Las
  Tareas 21 y 22 cambian su controlador y sus vistas según la enmienda aprobada, que la spec del
  test escribe al final desde el 2026-09-26.
- **Qué se usa de ella.** `SpecialtyTestController`, `SpecialtyTestUi`, `OrigenDelTest`,
  `TextosDelTest`, `SpecialtyTestService`, las funciones de `specialty_test_logic.dart`
  (`turnoAntesDePregunta`, `turnoAntesDeDesempate`, `turnoDeEspera`, `textoDeRespuesta`,
  `seleccionOficial`), los tokens `test*` de `themes.dart`, `AuthService.officialSpecialtyIds`,
  `AuthService.catalogsFailed`, `AuthService.reloadCatalogs` y el `timeout` de `completeSetup`, y
  las vistas `question_view.dart`, `waiting_view.dart` y `result_view.dart` con `ulises_bubble.dart`
  y `task_icon.dart`.
- **Si su código cambia.** Los nombres de arriba son los de `f4871c1`. Si un nombre no cuadra con
  el código de la rama, las Tareas 21 a 33 usan el nombre real y el informe de la tarea lo anota.
  Nunca se reescribe el código del test para que cuadre con este plan, fuera de lo que pide su
  enmienda.

## Restricciones globales

- Solo se tocan los `targets` de las dos specs, más los documentos de la Tarea 33 y, en las
  Tareas 21 y 22, `lib/pages/specialty_test/**`, que está en los targets de la bienvenida por la
  enmienda al test. `lib/components/google_sign_in_button.dart` y
  `lib/components/google_sign_in_button_stub.dart`, que cambia la Tarea 32, están en los targets de
  la bienvenida por su enmienda técnica del 2026-09-26. El splash nunca toca
  `lib/pages/setup_carrera/**`, que sale de sus targets (RF-SPL-12).
- Sin dependencias ni paquetes nuevos (RF-SPL-17 y RF-BIEN-18). La intro y la bienvenida usan
  `CustomPainter`, `AnimationController`, `Ticker`, `SpringSimulation`, `Curves` y `TextPainter`
  del SDK. `flutter_native_splash` sigue en `dev_dependencies`.
- `#E77330` es el naranja del splash nativo y del primer cuadro, en los dos temas (S-2). R, el
  radio de la estrella en el primer cuadro, mide 90 dp, y una unidad u del SVG mide R/354,8 dp.
  La estrella de la cabecera mide 26 dp de punta a punta y el sello, 1,22 veces la cabecera.
- `shared_preferences` guarda solo `splash_ultima_variante`, con `ensamble`, `incremento` o
  `codigo` (RF-SPL-6). La conversación de la bienvenida no se guarda en disco (RF-BIEN-5).
- Las contraseñas, su repetición y el código del authenticator no entran nunca en un `Rx`, en el
  historial, en un registro ni en el disco (RF-BIEN-9).
- Textos visibles, solo los de «Textos nuevos» de cada spec y los de hoy que las specs conservan.
  Las etiquetas de semántica son «ULIMA++, cargando» durante la intro y «ULIMA++» en el paso al
  horario y en el sello.
- Colores de la bienvenida desde `MaterialTheme` (RF-BIEN-14). Los únicos hex sueltos de las vistas
  nuevas son `#E77330` del splash y el blanco del logo.
- Toda navegación a `/login` pasa por `offAllToLogin` de `session_navigation.dart`
  (`test/HU02_jeff/session_navigation_guard_test.dart` sigue en verde).
- Nunca `Get.put` dentro de un `build`, y la bienvenida crea y cierra los controladores del
  registro y del test ella misma, sin `Get.put` (B-20 y B-34).
- Repo público. Todo dato de prueba es inventado, con el alumno sintético `20230001`, la segunda
  cuenta `alumna.b.test` y el docente `docente.test`. Ningún nombre, correo ni código real.
- Commits en español con el estilo del log (`feat(splash): …`, `feat(bienvenida): …`,
  `test(…)`, `docs(…)`), en presente, con `git add` y rutas explícitas, sin trailer
  `Co-Authored-By` ni otra línea de atribución y con el autor noreply de GitHub,
  `Jeffangeloss <178797184+jeffangeloss@users.noreply.github.com>`, que se comprueba con
  `git log -1 --format='%an <%ae>'` después de cada commit. Nada de push y nunca `git stash` a
  secas. Otra sesión puede compartir el worktree, así que antes de cada commit se comprueban la
  rama y `git status --short`, que solo puede listar los archivos de la tarea.
- La prosa de comentarios, specs y documentos va sin dos puntos, sin guiones largos, en presente y
  según la RAE.
- El splash y la bienvenida se publican juntos, en el mismo push a `main` (S-30). El test de
  especialidad ya está en `main` desde `87403a1`. Este plan no hace push.

## Variables de los comandos

El plan no fija rutas de una máquina concreta, porque el repo es público. Cada bloque de shell
empieza con `cd "${REPO:?}"`, y antes de correrlo se exportan tres variables con los valores de la
máquina.

- `REPO`, la ruta absoluta del worktree de la rama `feat/splash-animado` (la muestra
  `git worktree list`).
- `FLUTTER`, el ejecutable `flutter` del SDK que indica el despacho.
- `DART`, el ejecutable `dart` del mismo SDK, que está junto a `flutter` en su carpeta `bin`.

Si `.dart_tool` no existe en el worktree, `"${FLUTTER:?}" pub get --offline` va primero. Los
comandos usan `--no-pub` para no tocar `pubspec.lock`. El único que puede resolver los paquetes por
su cuenta es `dart run flutter_native_splash:create` de la Tarea 3, porque `pubspec.yaml` cambia, y
si toca `pubspec.lock` se revierte con `git checkout -- pubspec.lock`.

La suite completa tarda unos tres minutos, así que corre en segundo plano con su salida en un
archivo del scratchpad, y la tarea espera a que termine antes de dar nada por verde.

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub > "${SCRATCH:?}/suite.txt" 2>&1 &
wait $!
tail -3 "${SCRATCH:?}/suite.txt"
```

`SCRATCH` es la carpeta del scratchpad de la sesión que ejecuta la tarea, fuera del repo.

## Línea base en `fcbf2e7`

- `"${FLUTTER:?}" analyze --no-pub` da `6 issues found.`, todos `info` y previos. Son
  `avoid_print` en `lib/main.dart:103`, dos `deprecated_member_use` en
  `lib/services/attendance_risk_service.dart:55`, `unnecessary_import` en
  `test/HU20_jeff/otp_field_ime_test.dart:32` y dos `depend_on_referenced_packages` en
  `test/HU26_sam/export_csv_cajanegra_test.dart:20-21`. La Tarea 14 quita el `avoid_print` de
  `main.dart`, porque la carga deja de usar `print`, así que desde ahí la base es de 5.
- `"${FLUTTER:?}" test --no-pub` da `+1496: All tests passed!`, con las pruebas de
  `test/HU36_jeff/` del test de especialidad.
- Cada tarea compara sus dos cifras con esta base. La de `analyze` baja a 5 en la Tarea 14 y la
  suite nunca pierde pruebas.

## Cómo leer los «Esperado»

Los bloques de código de este plan son la referencia y no salen de una corrida. Cada «Esperado»
dice qué prueba falla y por qué en el rojo, y qué archivo o carpeta pasa en el verde, sin fijar la
cifra de la suite. Cada tarea anota en su informe la cifra de la suite completa, que nunca baja
respecto de la tarea anterior. Si una prueba del plan choca con una API real, se corrige la
prueba o el código para cumplir la spec, se anota en el informe y nunca se cambia lo que la spec
pide para que una prueba pase. Si
`flutter analyze` marca un `unused_import` o un `unnecessary_import` en un archivo del plan, se
quita el import sobrante antes del commit, porque la base no suma avisos.

## Decisiones del plan

La spec las deja abiertas o no las nombra. Ninguna cambia un requisito.

1. **La escena como dato.** Cada variante es una clase sin estado que devuelve una
   `EscenaDelLogo` por milisegundo, y un solo `PintorDelLogo` la dibuja. Así cada fila de las
   tablas de RF-SPL-7 a RF-SPL-9 se prueba con un número, sin montar widgets.
2. **La compresión de Ensamble.** Cuando dos compresiones de la estrella central se solapan, manda
   la mayor, así que la estrella nunca baja de 97,8 %.
3. **Las curvas de las salidas.** La spec fija el tipo de curva y no sus puntos de control. Ensamble
   usa una cuadrática con el control en `(inicio.dx, destino.dy + 0,25 · (inicio.dy − destino.dy))`,
   Incremento una cúbica que entra a la cabecera desde abajo con los controles en
   `(inicio.dx, inicio.dy − 0,2 · alto)` y `(destino.dx, destino.dy + 120)`, y Código una cúbica con
   los controles en `(inicio.dx + 40, inicio.dy − 0,45 · distancia)` y
   `(destino.dx − 30, destino.dy + 40)`. En Código la página aparece entre el 35 % y el 75 %.
4. **Código en una rejilla.** «ULima++» se escribe en celdas de 0,6 em, que es el ancho de las
   letras monoespaciadas del sistema, y cada letra se centra en su celda. Como en `codigo.html`,
   el «+» tecleado es la cruz del logo a 0,83 de su tamaño y con el 87 % de su grosor, centrado
   0,34 em sobre la línea base, y el vuelo sale en arco con el control 0,38 R a la derecha del
   destino y 0,91 R sobre el más alto de los dos extremos.
5. **La espera por la cabecera.** Después de navegar a `/home`, la capa espera a lo sumo tres
   cuadros la medida de la cabecera. Sin ella, la salida es el fundido de 300 ms de RF-SPL-11.
6. **El ritmo en la página.** El controlador de la bienvenida decide qué dice Ulises y cuánto espera
   cada burbuja antes de entrar, y la página las revela con esas pausas o todas juntas con lector de
   pantalla (RF-BIEN-5 y RF-BIEN-16). Así las pruebas del controlador no dependen del reloj.
7. **El login mientras dura la tarjeta.** La Tarea 19 suma a `LoginController` los métodos que
   devuelven el desenlace y deja `submit` y `loginWithGoogle` como envoltorios que navegan, para que
   la tarjeta de hoy siga funcionando hasta que la Tarea 29 la reemplace y los borre.
8. **Un error al guardar la selección manual.** La spec no fija su texto. Ulises dice el de
   `TextosDelTest.noSeGuardo`, el mismo del test, y el compositor vuelve a responder.
9. **Navegar sin transición.** `session_navigation.dart` suma `offAllSinTransicion`, que toma el
   `page` y el `binding` de la `GetPage` registrada con `Get.routeTree.matchRoute`. La usan la intro
   hacia `/home`, `offAllToLogin` desde la intro y el paso al horario de la bienvenida.
10. **Los emojis de la escala.** La Tarea 22 hace públicos los emojis de las cuatro opciones de la
    escala, que el plan del test deja privados en `question_view.dart`, porque la respuesta del
    alumno los muestra («🤩 Me encantaría»).
11. **El rebote del segundo «+» de Código termina a los 1330 ms.** RF-SPL-9 da el vuelo del
    segundo «+» de 830 a 1210 ms, un rebote de 150 ms desde que cada «+» llega y el fin de la
    entrada a los 1330 ms, y RF-SPL-17 y RF-SPL-21 fijan en 1330 ms la salida hacia `/home` y el
    relevo a la bienvenida, con el logo completo y quieto. Si el rebote empezara a los 1210 ms,
    terminaría a los 1360 ms, dentro de la salida o del primer cuadro de la bienvenida. El segundo
    «+» empieza su rebote a los 1180 ms, 30 ms antes del fin de su vuelo, cuando
    `Curves.easeInOutCubic` ya cubre el 99,5 % de su curva y el «+» está a menos de 1 dp de su
    lugar, así que conserva sus 150 ms y su 12 % y termina con la entrada. El primero no choca con
    nada y rebota de 1160 a 1310 ms, como en la maqueta. La salida y el relevo empiezan a los
    1330 ms con el logo quieto, y el informe de la Tarea 9 lo anota para el dueño.
12. **Los detalles del vuelo que la spec no fija.** RF-BIEN-2 da la estela, las partículas y la
    sombra por su tamaño, su cantidad y su tiempo. La estela deja un punto cada 1300/30 ms sobre la
    misma curva de Ulises, las seis partículas salen de sus pies en abanico hacia arriba hasta
    30 dp y la sombra es un óvalo negro al 20 % que crece de 18 a 56 dp. En el paso al horario, la
    Bézier hacia la burbuja tiene sus controles en `(0,88 · ancho, inicio.dy − 0,2 · alto)` y
    `(burbuja.dx + 0,35 · ancho, burbuja.dy − 0,3 · alto)`.
13. **El reloj del recibimiento en reposo.** Con la tarjeta y los botones quietos, el `Ticker` del
    recibimiento calla (`muted`) y la subida cuenta desde el primer cuadro después del toque. Así la
    pantalla en reposo no pide cuadros (RF-BIEN-18) y `pumpAndSettle` termina sobre `/login`.
14. **Las piezas del sello, medidas una vez.** `PiezasDelSello.medir` mide el sello de la franja
    como lo dibuja, con su estilo y su escala de texto. Es el destino de la subida y el origen del
    paso al horario, así que el logo dibujado cae siempre sobre el sello real.
15. **El cursor sin parpadeo.** RF-BIEN-15 pide que el cursor no parpadee con reducir movimiento, y
    el SDK solo lo permite con `EditableText.debugDeterministicCursor`, un interruptor global. La
    bienvenida lo enciende mientras está montada con reducir movimiento y lo devuelve a su valor
    en su `dispose`.
16. **La acción de toque de los controles.** Los controles que usan
    `Semantics(excludeSemantics: true)` suman `onTap` en ese `Semantics`, porque sin él la acción
    del `InkWell` no llega al lector y el doble toque no los activa (RF-BIEN-16). La Tarea 31 lo
    suma a los de las Tareas 26 y 28.

## Estructura de archivos

| Archivo | Acción | Responsabilidad | Tareas |
| --- | --- | --- | --- |
| `lib/components/logo/logo_geometria.dart` | crear | Los polígonos retraídos y sin retraer, las cruces y los caminos construidos una vez (RF-SPL-2) | 1 |
| `lib/components/logo/escena_del_logo.dart` | crear | `EscenaDelLogo`, sus piezas y `PoseDelLogo`, que viaja a la bienvenida | 2 |
| `lib/components/logo/pintor_del_logo.dart` | crear | `PintorDelLogo`, el único pintor del logo, y `LogoEnEscena` | 2 |
| `assets/splash/splash_estrella.png` | crear | La estrella del nativo, de 1152 × 1152 px | 3 |
| `pubspec.yaml` y los recursos nativos | modificar | `flutter_native_splash` apunta al PNG nuevo, y `dart run flutter_native_splash:create` regenera Android, iOS y web | 3 |
| `lib/services/splash_variante_service.dart` | crear | `VarianteSplash`, `elegirVariante` y el servicio de la preferencia | 4 |
| `lib/components/logo/estrella_del_logo.dart` | crear | La estrella quieta de la cabecera | 5 |
| `lib/pages/splash/puntos_de_aterrizaje.dart` | crear | Las medidas que informan la cabecera y la burbuja de Ulises | 5 |
| `lib/components/header/app_header.dart` | modificar | La estrella, el estilo único de «ULIMA++», la barra de estado y el informe de su medida | 5 |
| `lib/pages/splash/estado_de_la_capa.dart` | crear | `EstadoDeLaCapa.cubre`, que dice si la capa tapa la pantalla | 6 |
| `lib/pages/home/home_page.dart` | modificar | La pestaña inicial por argumento y las orientaciones al retirarse la capa | 6 |
| `lib/pages/splash/variantes/variante_de_intro.dart` | crear | La base de las variantes y las curvas que comparten | 7 |
| `lib/pages/splash/variantes/ensamble.dart` | crear | Ensamble, su bucle y su vuelta al reposo | 7 |
| `lib/pages/splash/variantes/incremento.dart` | crear | Incremento, sus tics y su vuelta al reposo | 8 |
| `lib/pages/splash/variantes/codigo.dart` | crear | Código, su tecleo y su cursor | 9 |
| `lib/pages/splash/salidas.dart` | crear | Las tres salidas hacia `/home` como funciones puras y su pintor | 10 |
| `lib/services/session_navigation.dart` | modificar | La guarda de `/arranque`, la navegación sin transición, la pose y el motivo | 11 y 15 |
| `lib/pages/splash/arranque_page.dart` | crear | La página vacía de `/arranque` | 12 |
| `lib/pages/splash/capa_de_arranque.dart` | crear | La capa permanente del `builder`, la intro y su entrada para la bienvenida | 12, 13 y 30 |
| `lib/pages/splash/carga_del_arranque.dart` | crear | La carga de hoy como función que devuelve la ruta | 14 |
| `lib/main.dart` | modificar | `runApp` inmediato, `/arranque`, la capa, las `GetPage` una sola vez, con las del test de especialidad que trae `fcbf2e7`, y `/login` con la bienvenida | 14 y 29 |
| `lib/services/api_client.dart` | modificar | El 401 pasa `motivo: expirada` y su aviso sale abajo, y un comentario deja de nombrar la pantalla del registro | 15 y 29 |
| `lib/pages/password_reset/*_controller.dart` y `lib/pages/perfil/perfil.dart` | modificar | `motivo: restablecida` y los avisos abajo | 15 |
| `lib/components/logo/sello_del_logo.dart` | crear | El sello, con la estrella y «ULIMA++» a 1,22 veces la cabecera, y la medida de sus piezas | 17 y 28 |
| `lib/pages/password_reset/password_reset_ui.dart`, `forgot_password_page.dart` y `reset_password_page.dart` | modificar | La cabecera con el sello y la barra de estado | 18 |
| `lib/domain/bienvenida/bienvenida_turnos.dart` | crear | Los turnos, el atrás, el turno de cada error, el conteo, el latido, el pulso, las medidas del recibimiento, «Si no cabe» y la configuración de GIS | 16 |
| `lib/pages/login/login_controller.dart` | modificar | El desenlace sin navegar, la red caída y los campos vacíos | 19 y 29 |
| `lib/pages/registro/registro_controller.dart` | modificar | El cierre propio, el texto de «incierto» y el `onClose` que usa ese cierre | 19 y 29 |
| `lib/configs/themes.dart` | modificar | Los tokens `bienvenida*` de RF-BIEN-14 | 20 |
| `lib/pages/specialty_test/specialty_test_controller.dart` | modificar | El origen `bienvenida` | 21 |
| `lib/pages/specialty_test/widgets/question_view.dart` y `result_view.dart` | modificar | El duelo, la escala y el resultado se dibujan también compactos, dentro del compositor | 22 |
| `lib/pages/bienvenida/conversacion.dart` | crear | Los mensajes, las respuestas y el compositor de cada turno | 23 |
| `lib/pages/bienvenida/bienvenida_controller.dart` | crear | Las visitas, los turnos del login, del registro y del test, los errores, el atrás, la llegada con sesión y el saludo en la conversación | 23 a 26 y 28 |
| `lib/pages/bienvenida/bienvenida_page.dart` | crear | La página de `/login` | 26 a 31 |
| `lib/pages/bienvenida/widgets/revelador.dart` | crear | El ritmo de las burbujas y del compositor | 26 |
| `lib/pages/bienvenida/widgets/burbujas.dart` | crear | Los grupos de Ulises, las respuestas del alumno, la tarjeta del consentimiento y el foco del lector | 26, 28, 30 y 31 |
| `lib/pages/bienvenida/widgets/franja_con_sello.dart` | crear | La franja, el sello, el latido, el pulso y la píldora | 26, 28 y 31 |
| `lib/pages/bienvenida/widgets/compositor.dart` | crear | El compositor y sus piezas | 26 a 29, 31 y 32 |
| `lib/pages/bienvenida/widgets/compositor_del_test.dart` | crear | El test y la selección manual dentro del compositor | 27 |
| `lib/pages/bienvenida/widgets/anillo_de_foco.dart` | crear | El anillo de 2 dp en `bienvenidaFoco` de los botones, las píldoras y los enlaces con el foco del teclado | 31 |
| `lib/pages/bienvenida/widgets/vuelo_de_ulises.dart` | crear | La curva, la estela, las partículas y el salto de Ulises | 28 |
| `lib/pages/bienvenida/widgets/recibimiento.dart` | crear | El recibimiento, la tarjeta, los dos botones y la subida al sello | 28 y 31 |
| `lib/pages/login/login_binding.dart` | modificar | Registra también el controlador de la bienvenida | 29 |
| `lib/pages/login/login_page.dart`, `lib/pages/registro/registro_page.dart`, `registro_binding.dart` y `test/HU33_jeff/registro_page_test.dart` | borrar | La bienvenida los reemplaza (B-23) | 29 |
| `lib/pages/splash/paso_al_horario.dart` | crear | El dibujo del paso al horario | 30 |
| `lib/components/chatbot_bubble.dart` | modificar | Informa su lugar y espera a Ulises solo en el paso al horario | 30 |
| `lib/components/google_sign_in_button.dart`, `google_sign_in_button_stub.dart` y `google_sign_in_button_web.dart` | modificar | El botón de GIS configurado y dibujado otra vez al cambiar el tema. Los dos primeros entran a los targets por la enmienda técnica del 2026-09-26 | 32 |
| `lib/components/portal_consent/portal_consent_view.dart` y `lib/services/auth_service.dart` | modificar | Solo los comentarios que nombran `/registro` | 29 |
| `README.md` | modificar | «El arranque», el login, el registro y la ruta post-login | 14 y 33 |
| `test/splash/apoyo_splash.dart` | crear | Teléfonos, escenas, carga falsa, `Random` fijo y montaje de la capa | 4 y 12 |
| `test/splash/*_test.dart` | crear | Las pruebas de la spec del splash | 1 a 14 |
| `test/components/header/app_header_test.dart` | modificar | La estrella, la barra de estado y la medida | 5 |
| `test/bienvenida/apoyo_bienvenida.dart` | crear | Dobles de `AuthService`, `LoginController`, `RegistroService`, `StorageService` y del test, y el montaje de `/login`, con la capa si hace falta | 23 a 26, 29 y 30 |
| `test/bienvenida/*_test.dart` | crear | Las pruebas de «Pruebas por requisito» de la bienvenida y la de sus reglas puras | 15 a 32 |
| `test/HU01_jeff/**`, `test/HU33_jeff/registro_page_test.dart` y `test/HU34_jeff/registro_consent_test.dart` | modificar o borrar | Pasan a la bienvenida | 29 |
| Specs, enmiendas, maquetas e índice | modificar | Estado, `[@test]` y notas, también de la enmienda del test y de las notas de Perfil académico, Chatbot y Récord académico | 33 |

Los archivos de apoyo de `test/splash/` y `test/bienvenida/` no terminan en `_test.dart`, así que
`flutter test` no los corre como suites.

## Orden y cobertura

Las tareas van en orden y en la misma rama. Cada una deja la suite en verde. Las Tareas 1 a 14 son
el splash, las 15 a 19 son piezas de la bienvenida que no usan el test de especialidad y las 20 a
33 son la bienvenida que lo usa.

| Requisito | Tareas | Pruebas |
| --- | --- | --- |
| RF-SPL-1 y RF-SPL-3 | 3 | `splash_png_nativo_test.dart` |
| RF-SPL-2 | 1 y 2 | `splash_geometria_test.dart` |
| RF-SPL-4 | 11 a 14 y 30 | `splash_arranque_test.dart` y `bienvenida_horario_test.dart` |
| RF-SPL-5 | 12 | `splash_primer_cuadro_test.dart` |
| RF-SPL-6 | 4 y 13 | `splash_seleccion_test.dart` |
| RF-SPL-7 a RF-SPL-9 | 7 a 9 | `splash_ensamble_test.dart`, `splash_incremento_test.dart` y `splash_codigo_test.dart` |
| RF-SPL-10 | 7 a 9 y 13 | Las tres anteriores y `splash_arranque_test.dart` |
| RF-SPL-11 y RF-SPL-13 | 10 y 13 | `splash_salida_test.dart` |
| RF-SPL-12 y RF-SPL-21 | 11 y 13 | `splash_traspaso_test.dart` |
| RF-SPL-14 | 12 y 13 | `splash_reducir_movimiento_test.dart` |
| RF-SPL-15 | 12 | `splash_accesibilidad_test.dart` |
| RF-SPL-16 a RF-SPL-18 | 13 y 14 | `splash_arranque_test.dart` y las tres de las variantes |
| RF-SPL-19 | 33 | Documentación |
| RF-SPL-20 y BR-SHELL-F-02 | 6 | `home_pestana_inicial_test.dart` |
| BR-SHELL-F-04 | 5 | `app_header_test.dart` |
| RF-BIEN-1 | 15, 23, 26 y 29 | `bienvenida_ruta_test.dart` |
| RF-BIEN-2 y RF-BIEN-3 | 16 y 28 | `bienvenida_recibimiento_test.dart` |
| RF-BIEN-4 | 16, 17, 26 y 28 | `bienvenida_sello_test.dart` |
| RF-BIEN-5 | 23 y 26 | `bienvenida_conversacion_test.dart` |
| RF-BIEN-6 | 19, 23, 26, 27, 29 y 32 | `bienvenida_entrar_test.dart` y `bienvenida_ruta_test.dart` |
| RF-BIEN-7 y RF-BIEN-8 | 19, 24, 27 y 29 | `bienvenida_registro_test.dart` |
| RF-BIEN-9 | 19 y 24 | `bienvenida_credenciales_test.dart` |
| RF-BIEN-10 | 21, 22, 25 y 27 | `bienvenida_test_especialidad_test.dart` |
| RF-BIEN-11 | 30 | `bienvenida_horario_test.dart` |
| RF-BIEN-12 | 23 a 25 y 30 | `bienvenida_errores_test.dart` y, para el paso al horario, `bienvenida_horario_test.dart` |
| RF-BIEN-13 | 16 y 23 a 25 | `bienvenida_atras_test.dart` |
| RF-BIEN-14 | 20 | `bienvenida_contraste_test.dart` |
| RF-BIEN-15 y RF-BIEN-16 | 26, 30 y 31 | `bienvenida_movimiento_test.dart`, `bienvenida_accesibilidad_test.dart` y `bienvenida_horario_test.dart` |
| RF-BIEN-17 | 26 | `bienvenida_barra_estado_test.dart` |
| RF-BIEN-18 y RF-BIEN-19 | 33 | Medición manual y documentación |
| RF-BIEN-20 | 15 y 18 | `bienvenida_restablecer_test.dart` |
| RF-BIEN-21 | 23, 25 y 28 | `bienvenida_sin_especialidad_test.dart` |
| Reglas puras de la bienvenida | 16 | `bienvenida_turnos_test.dart` |
| Documentos | 33 | Búsquedas del Paso 4 de la Tarea 33 |

## Notas del código real que el plan tiene en cuenta

- `main()` espera Firebase, `StorageService`, los servicios, con `SpecialtyTestService` al final,
  `tryRestoreSession` y las alertas antes de `runApp` (`main.dart:62-111`). La Tarea 14 mueve todo
  eso a una función que la capa espera, salvo en web, donde el orden sigue igual (S-22).
- `offAllToLogin` no navega si `Get.context` es null o si `/login` ya es la ruta actual
  (`session_navigation.dart:32-39`). Con `runApp` inmediato, `Get.context` existe durante la carga,
  así que la Tarea 11 suma la guarda de `/arranque` antes de que la Tarea 14 mueva `runApp`.
- `Get.offAll` de get 4.7.3 acepta `routeName`, `binding`, `transition`, `opaque` y `arguments`
  (`extension_navigation.dart:957-990`), y `Get.routeTree.matchRoute(nombre).route` devuelve la
  `GetPage` que registró `getPages`.
- `HomePage` fija `_currentIndex = 0` (`home_page.dart:36`) y pide sus orientaciones en `initState`
  (`:62-66`). `ModalRoute.of` no se puede leer en `initState`, así que la Tarea 6 lee el argumento en
  el primer `didChangeDependencies`.
- `AppHeader` es un `StatelessWidget` con «ULIMA++» dentro de un `InkWell` con semántica propia
  (`app_header.dart:71-89`). La estrella va fuera de ese `InkWell` para que el enlace siga siendo
  solo el texto (BR-SHELL-F-01).
- `ChatbotBubble` fija su lugar inicial en el primer `LayoutBuilder` (`chatbot_bubble.dart:76`) y
  deja de latir con `disableAnimations` (`:47-51`).
- `LoginBinding` reusa el `LoginController` permanente y limpia sus campos después del cuadro
  (`login_binding.dart:25-38`). La prueba del «tipeo fantasma» monta la ruta real y teclea en el
  primer `TextField` (`test/HU01_jeff/login_navigation_paths_test.dart:60-65`).
- `RegistroController.onClose` borra y desecha los cinco campos a la vez (`registro_controller.dart:
  148-163`). La Tarea 19 separa el borrado inmediato del `dispose` diferido que pide B-20.
- `ApiClient` borra la sesión en un 401 y llama a `offAllToLogin`, y solo si navegó muestra «Sesión
  expirada» (`api_client.dart:143-160`).
- `PasswordResetScaffold` pone la tarjeta en un `Center` dentro de un `SafeArea` y la flecha arriba
  a la izquierda (`password_reset_ui.dart:100-163`). Portal Sync lo usa sin cambios
  (`portal_sync_page.dart:24`).
- `flutter test` corre con la fuente de pruebas, en la que cada letra mide 1 em. Las pruebas que
  miden si algo cabe cargan Roboto del SDK, como `test/HU23_jeff/chats_pestana_test.dart:300-320`.
- Dentro de `testWidgets` el reloj es falso. Mientras la intro, la burbuja de Ulises o un
  `SkeletonPulse` animan sin fin no se usa `pumpAndSettle`, sino `pump` con una duración.

---

### Tarea 1. La geometría única del logo

**Requisitos.** RF-SPL-2 completo.

**Archivos.**
- Crear `lib/components/logo/logo_geometria.dart`.
- Crear `test/splash/splash_geometria_test.dart`.

**Interfaces.**
- Consume nada.
- Produce, en `package:ulima_plus/components/logo/logo_geometria.dart`, estas firmas, que usan
  las Tareas 2, 3, 5, 7 a 10, 16 y 28.

```dart
abstract final class LogoGeometria {
  static const Offset centroSvg;            // (590,2; 394,3)
  static const double radioNominal;         // 354,8 u
  static const double retraimiento;         // 3,5 u
  static const List<List<Offset>> rombosSvg;              // 8 × 4, k = 0 arriba, horario
  static const List<Offset> estrellaCentralSvg;           // 16
  static const List<List<Offset>> rombosSinRetraerSvg;    // 8 × 4
  static const List<Offset> estrellaCentralSinRetraerSvg; // 16
  static const double largoDeCruz;          // 72,8 u
  static const double grosorDeCruz;         // 17,4 u
  static const List<Offset> centrosDeCruz;  // (308,7; −133,8) y (402,5; −133,8)
  static final List<Path> rombos;           // retraídos, con el origen en el centro
  static final Path estrellaCentral;
  static final Path silueta;                // la unión sin retraer
  static final List<Offset> centrosDeRombo; // centroides, en u
  static final List<Offset> direccionesDeRombo; // unitarias, hacia afuera
  static double unidad(double radioDp);     // radioDp / 354,8
  static (Rect, Rect) barrasDeCruz({double grosor = 1}); // horizontal y vertical, en u
}
```

- [ ] **Paso 1. Línea base.** En la raíz del worktree corre `"${FLUTTER:?}" analyze --no-pub` y la
  suite completa en segundo plano, como dice «Variables de los comandos». Anota las dos cifras en
  el informe. En `fcbf2e7` son `6 issues found.` y `+1496: All tests passed!`.

- [ ] **Paso 2. Escribe la prueba que falla.** Crea `test/splash/splash_geometria_test.dart` con
  este contenido.

```dart
// test/splash/splash_geometria_test.dart
//
// UNITARIA · Splash animado (specs/features/splash/splash.spec.md).
// RF-SPL-2 fija una sola geometría del logo, con los ocho rombos y la
// estrella central retraídos 3,5 u, la silueta sin retraer y las dos cruces.
// Archivo probado lib/components/logo/logo_geometria.dart.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/components/logo/logo_geometria.dart';

/// Distancia con signo de [p] a la recta de [a] a [b]. Es positiva a la
/// derecha del sentido de avance.
double _distancia(Offset p, Offset a, Offset b) {
  final d = b - a;
  final n = Offset(-d.dy, d.dx) / d.distance;
  final v = p - a;
  return v.dx * n.dx + v.dy * n.dy;
}

/// Comprueba que cada lado de [retraido] queda a 3,5 u de su lado en
/// [original], hacia adentro.
void _seRetrae(List<Offset> retraido, List<Offset> original) {
  expect(retraido.length, original.length);
  final signo = _distancia(
    _centroide(original),
    original[0],
    original[1],
  ).sign;
  for (var i = 0; i < original.length; i++) {
    final a = original[i];
    final b = original[(i + 1) % original.length];
    for (final p in [retraido[i], retraido[(i + 1) % retraido.length]]) {
      final d = _distancia(p, a, b) * signo;
      expect(d, closeTo(LogoGeometria.retraimiento, 0.2), reason: 'lado $i');
    }
  }
}

Offset _centroide(List<Offset> puntos) =>
    puntos.reduce((a, b) => a + b) / puntos.length.toDouble();

double _alcance(List<Offset> puntos) => puntos
    .map((p) => (p - LogoGeometria.centroSvg).distance)
    .reduce(math.max);

void main() {
  group('la geometría (RF-SPL-2)', () {
    test('ocho rombos de cuatro vértices y una estrella central de 16', () {
      expect(LogoGeometria.rombosSvg, hasLength(8));
      expect(LogoGeometria.rombosSinRetraerSvg, hasLength(8));
      for (final r in LogoGeometria.rombosSvg) {
        expect(r, hasLength(4));
      }
      expect(LogoGeometria.estrellaCentralSvg, hasLength(16));
      expect(LogoGeometria.estrellaCentralSinRetraerSvg, hasLength(16));
      expect(LogoGeometria.rombos, hasLength(8));
    });

    test('el rombo 0 está arriba y los demás siguen en sentido horario', () {
      for (var k = 0; k < 8; k++) {
        final angulo = k * math.pi / 4;
        final d = LogoGeometria.direccionesDeRombo[k];
        expect(d.dx, closeTo(math.sin(angulo), 0.02), reason: 'rombo $k');
        expect(d.dy, closeTo(-math.cos(angulo), 0.02), reason: 'rombo $k');
        expect(d.distance, closeTo(1, 1e-9));
      }
    });

    test('cada polígono se retrae 3,5 u, que deja la rendija de 7 u', () {
      for (var k = 0; k < 8; k++) {
        _seRetrae(LogoGeometria.rombosSvg[k], LogoGeometria.rombosSinRetraerSvg[k]);
      }
      _seRetrae(
        LogoGeometria.estrellaCentralSvg,
        LogoGeometria.estrellaCentralSinRetraerSvg,
      );
    });

    test('la punta sin retraer llega a 354,8 u y la retraída a 88,5 dp con '
        'R = 90 dp', () {
      final sinRetraer = LogoGeometria.rombosSinRetraerSvg.map(_alcance);
      expect(sinRetraer.reduce(math.max), closeTo(354.8, 0.1));
      final retraida = LogoGeometria.rombosSvg.map(_alcance).reduce(math.max);
      expect(retraida * LogoGeometria.unidad(90), closeTo(88.5, 0.1));
    });

    test('la silueta sin retraer cubre la rendija y los polígonos retraídos '
        'no', () {
      // Un punto a 2 u del lado que comparten el rombo 0 y la estrella
      // central, del lado del rombo, cae en la rendija.
      final a = LogoGeometria.estrellaCentralSinRetraerSvg[0];
      final b = LogoGeometria.estrellaCentralSinRetraerSvg[1];
      final d = (b - a) / (b - a).distance;
      final haciaElRombo = Offset(d.dy, -d.dx);
      final punto = (a + b) / 2 + haciaElRombo * 2 - LogoGeometria.centroSvg;
      expect(LogoGeometria.silueta.contains(punto), isTrue);
      expect(LogoGeometria.rombos[0].contains(punto), isFalse);
      expect(LogoGeometria.estrellaCentral.contains(punto), isFalse);
      expect(LogoGeometria.silueta.contains(const Offset(0, -360)), isFalse);
    });

    test('cada «+» mide 72,8 u de punta a punta y 17,4 u de grosor, arriba a '
        'la derecha', () {
      final (horizontal, vertical) = LogoGeometria.barrasDeCruz();
      expect(horizontal.width, closeTo(72.8, 1e-9));
      expect(horizontal.height, closeTo(17.4, 1e-9));
      expect(vertical.width, closeTo(17.4, 1e-9));
      expect(vertical.height, closeTo(72.8, 1e-9));
      final (_, fina) = LogoGeometria.barrasDeCruz(grosor: 0.87);
      expect(fina.width, closeTo(17.4 * 0.87, 1e-9));
      expect(LogoGeometria.centrosDeCruz, const [
        Offset(308.7, -133.8),
        Offset(402.5, -133.8),
      ]);
    });

    test('los caminos se construyen una sola vez', () {
      expect(identical(LogoGeometria.rombos, LogoGeometria.rombos), isTrue);
      expect(
        identical(LogoGeometria.estrellaCentral, LogoGeometria.estrellaCentral),
        isTrue,
      );
      expect(identical(LogoGeometria.silueta, LogoGeometria.silueta), isTrue);
    });
  });
}
```

- [ ] **Paso 3. Corre la prueba y confirma que falla.**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/splash/splash_geometria_test.dart
```

Esperado. Falla la compilación, porque `package:ulima_plus/components/logo/logo_geometria.dart`
no existe.

- [ ] **Paso 4. Escribe la geometría.** Crea `lib/components/logo/logo_geometria.dart` con este
  contenido. Los polígonos retraídos son los de `docs/images/UI/splash/ensamble.html` y los sin
  retraer, los de `assets/images/Universidad_de_Lima_logo.svg`, en el mismo orden de vértices.

```dart
// lib/components/logo/logo_geometria.dart
// La geometría única del logo ULima++ (RF-SPL-2 de la spec del splash). La
// usan la intro, la estrella de la cabecera, el sello de la bienvenida y la
// prueba que genera el PNG del splash nativo. Las medidas van en unidades u
// del SVG `assets/images/Universidad_de_Lima_logo.svg`, y los caminos tienen
// el origen en el centro de la estrella.

import 'dart:ui';

abstract final class LogoGeometria {
  /// Centro de la estrella en el SVG.
  static const Offset centroSvg = Offset(590.2, 394.3);

  /// Radio nominal hasta la punta, sin retraer.
  static const double radioNominal = 354.8;

  /// Lo que se retrae cada polígono, la mitad de la rendija de 7 u.
  static const double retraimiento = 3.5;

  /// Los ocho rombos retraídos, desde el de arriba y en sentido horario,
  /// como en `ensamble.html`.
  static const List<List<Offset>> rombosSvg = <List<Offset>>[
    [Offset(590.2, 279.7), Offset(679.7, 167.4), Offset(590.2, 45.4), Offset(500.7, 167.4)],
    [Offset(671.3, 313.2), Offset(813.9, 297.1), Offset(836.9, 147.6), Offset(687.4, 170.6)],
    [Offset(817.1, 304.8), Offset(704.8, 394.3), Offset(817.1, 483.7), Offset(939.1, 394.3)],
    [Offset(671.3, 475.3), Offset(687.4, 617.9), Offset(836.9, 641.0), Offset(813.9, 491.4)],
    [Offset(590.2, 508.8), Offset(500.7, 621.1), Offset(590.2, 743.2), Offset(679.7, 621.1)],
    [Offset(509.2, 475.3), Offset(366.6, 491.4), Offset(343.5, 641.0), Offset(493.1, 617.9)],
    [Offset(475.6, 394.3), Offset(363.3, 304.8), Offset(241.3, 394.3), Offset(363.3, 483.7)],
    [Offset(509.2, 313.2), Offset(493.1, 170.6), Offset(343.5, 147.6), Offset(366.6, 297.1)],
  ];

  /// La estrella central retraída, el polígono de 16 vértices que forman los
  /// vértices interiores de los rombos.
  static const List<Offset> estrellaCentralSvg = <Offset>[
    Offset(501.1, 179.2), Offset(590.2, 290.9), Offset(679.3, 179.2),
    Offset(663.3, 321.2), Offset(805.3, 305.2), Offset(693.6, 394.3),
    Offset(805.3, 483.3), Offset(663.3, 467.3), Offset(679.3, 609.3),
    Offset(590.2, 497.6), Offset(501.1, 609.3), Offset(517.2, 467.3),
    Offset(375.1, 483.3), Offset(486.8, 394.3), Offset(375.1, 305.2),
    Offset(517.2, 321.2),
  ];

  /// Los rombos del SVG, sin retraer, con el mismo orden de vértices.
  static const List<List<Offset>> rombosSinRetraerSvg = <List<Offset>>[
    [Offset(590.2, 285.3), Offset(684.1, 167.5), Offset(590.2, 39.5), Offset(496.3, 167.5)],
    [Offset(667.3, 317.2), Offset(817.0, 300.3), Offset(841.1, 143.4), Offset(684.2, 167.5)],
    [Offset(817.0, 300.4), Offset(699.2, 394.3), Offset(817.0, 488.1), Offset(945.0, 394.3)],
    [Offset(667.3, 471.3), Offset(684.2, 621.0), Offset(841.1, 645.2), Offset(817.0, 488.2)],
    [Offset(590.2, 503.2), Offset(496.3, 621.0), Offset(590.2, 749.1), Offset(684.1, 621.0)],
    [Offset(513.2, 471.3), Offset(363.5, 488.2), Offset(339.3, 645.2), Offset(496.3, 621.0)],
    [Offset(481.2, 394.3), Offset(363.4, 300.4), Offset(235.4, 394.3), Offset(363.4, 488.1)],
    [Offset(513.2, 317.2), Offset(496.3, 167.5), Offset(339.3, 143.4), Offset(363.5, 300.3)],
  ];

  /// La estrella central sin retraer, que sale de los mismos vértices del SVG.
  static const List<Offset> estrellaCentralSinRetraerSvg = <Offset>[
    Offset(496.3, 167.5), Offset(590.2, 285.3), Offset(684.1, 167.5),
    Offset(667.3, 317.2), Offset(817.0, 300.4), Offset(699.2, 394.3),
    Offset(817.0, 488.1), Offset(667.3, 471.3), Offset(684.1, 621.0),
    Offset(590.2, 503.2), Offset(496.3, 621.0), Offset(513.2, 471.3),
    Offset(363.4, 488.1), Offset(481.2, 394.3), Offset(363.4, 300.4),
    Offset(513.2, 317.2),
  ];

  /// Cada «+» mide 72,8 u de punta a punta y 17,4 u de grosor.
  static const double largoDeCruz = 72.8;
  static const double grosorDeCruz = 17.4;

  /// Centros de los «++» desde el centro de la estrella, arriba a la derecha.
  static const List<Offset> centrosDeCruz = <Offset>[
    Offset(308.7, -133.8),
    Offset(402.5, -133.8),
  ];

  static List<Offset> _relativos(List<Offset> svg) => <Offset>[
    for (final p in svg) p - centroSvg,
  ];

  static Path _poligono(List<Offset> svg) =>
      Path()..addPolygon(_relativos(svg), true);

  /// Los rombos retraídos. Se construyen la primera vez que se leen.
  static final List<Path> rombos = List<Path>.unmodifiable(<Path>[
    for (final r in rombosSvg) _poligono(r),
  ]);

  static final Path estrellaCentral = _poligono(estrellaCentralSvg);

  /// La unión de los polígonos sin retraer, que recorta el destello de
  /// Ensamble (RF-SPL-7).
  static final Path silueta = () {
    final camino = Path();
    for (final r in rombosSinRetraerSvg) {
      camino.addPolygon(_relativos(r), true);
    }
    camino.addPolygon(_relativos(estrellaCentralSinRetraerSvg), true);
    return camino;
  }();

  /// El centroide de cada rombo retraído, en u desde el centro.
  static final List<Offset> centrosDeRombo = List<Offset>.unmodifiable(<Offset>[
    for (final r in rombosSvg)
      _relativos(r).reduce((a, b) => a + b) / r.length.toDouble(),
  ]);

  /// La dirección hacia afuera de cada rombo.
  static final List<Offset> direccionesDeRombo = List<Offset>.unmodifiable(
    <Offset>[for (final c in centrosDeRombo) c / c.distance],
  );

  /// Cuántos dp mide una unidad con un radio de [radioDp].
  static double unidad(double radioDp) => radioDp / radioNominal;

  /// Las dos barras de un «+» centrado en el origen, en u. Con [grosor]
  /// menor que 1, la cruz es más fina, como el «+» tecleado de Código.
  static (Rect, Rect) barrasDeCruz({double grosor = 1}) {
    final g = grosorDeCruz * grosor;
    return (
      Rect.fromCenter(center: Offset.zero, width: largoDeCruz, height: g),
      Rect.fromCenter(center: Offset.zero, width: g, height: largoDeCruz),
    );
  }
}
```

- [ ] **Paso 5. Corre la prueba y confirma que pasa.**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/components/logo/logo_geometria.dart test/splash/splash_geometria_test.dart
"${FLUTTER:?}" test --no-pub test/splash/splash_geometria_test.dart
"${FLUTTER:?}" analyze --no-pub
```

Esperado. `All tests passed!` con las siete pruebas y `6 issues found.`. Si `dart format` rompe
las filas de los polígonos en varias líneas, se aceptan como las deja.

- [ ] **Paso 6. Commit.**

```bash
cd "${REPO:?}"
git branch --show-current
git status --short
git add lib/components/logo/logo_geometria.dart test/splash/splash_geometria_test.dart
git commit -m "feat(splash): una sola geometría del logo con los rombos retraídos 3,5 u, la silueta sin retraer y los «++» (RF-SPL-2)"
git log -1 --format='%an <%ae>'
```

---

### Tarea 2. La escena, la pose y el pintor del logo

**Requisitos.** RF-SPL-2 («La usan la intro, la estrella de la cabecera…» y «Los caminos se
construyen una sola vez») y la forma de la pose de RF-SPL-21 (decisión S-33).

**Archivos.**
- Crear `lib/components/logo/escena_del_logo.dart`.
- Crear `lib/components/logo/pintor_del_logo.dart`.
- Modificar `test/splash/splash_geometria_test.dart` (grupo `la escena y el pintor`).

**Interfaces.**
- Consume `LogoGeometria` de la Tarea 1.
- Produce estas firmas, que usan las Tareas 3, 5, 7 a 13, 16, 28 y 30.

```dart
// escena_del_logo.dart
class RomboEnEscena { const RomboEnEscena({double desplazamiento = 0,
  double giro = 0, double escala = 1, double opacidad = 1});
  static const RomboEnEscena enReposo; }
class CruzEnEscena { const CruzEnEscena({required Offset centro,
  double escala = 1, double giro = 0, double opacidad = 1, double grosor = 1,
  Color color = const Color(0xFFFFFFFF)});
  CruzEnEscena copyWith({...}); }
class AnilloEnEscena { const AnilloEnEscena({required Offset centro,
  required double radio, required double trazo, required double opacidad}); }
class DestelloEnEscena { const DestelloEnEscena({required double avance,
  required double intensidad}); }
class TextoDeCodigo { const TextoDeCodigo({required int visibles,
  required double opacidad, double dy = 0});
  static const String palabra = 'ULima'; static const double tamano; // en R
  static const double lineaBase; static const double celda; // en em
  static Offset centroDeCelda(int i); } // en u
class CursorEnEscena { const CursorEnEscena({required Offset centro,
  required double alto, required double opacidad}); }
class EscenaDelLogo {
  const EscenaDelLogo({required Offset centro, required double radio,
    Offset corrimiento = Offset.zero, Offset desplazamientoDeEstrella = Offset.zero,
    double escalaDeEstrella = 1, double giro = 0, double escalaCentral = 1,
    double opacidad = 1, List<RomboEnEscena> rombos = rombosEnReposo,
    List<CruzEnEscena> cruces = const [], List<AnilloEnEscena> anillos = const [],
    DestelloEnEscena? destello, TextoDeCodigo? texto, CursorEnEscena? cursor,
    double? recorteDeCruces});
  factory EscenaDelLogo.reposo({required Offset centro, required double radio,
    bool conCruces = true});
  factory EscenaDelLogo.desdePose(PoseDelLogo pose);
  static const List<RomboEnEscena> rombosEnReposo;
  static List<CruzEnEscena> crucesEnReposo();
  double get unidad; Offset get centroDeLaEstrella; double get radioDeLaEstrella;
  PoseDelLogo get pose; EscenaDelLogo copyWith({...}); }
class PoseDelLogo { const PoseDelLogo({required Offset centro,
  required double radio, required double giro, required List<PoseDeCruz> cruces}); }
class PoseDeCruz { const PoseDeCruz({required Offset centro, required double escala}); }
// pintor_del_logo.dart
void pintarEscena(Canvas canvas, EscenaDelLogo escena, {Color color = const Color(0xFFFFFFFF)});
class PintorDelLogo extends CustomPainter { PintorDelLogo(ValueListenable<EscenaDelLogo> escena,
  {Color color = const Color(0xFFFFFFFF)}); }
class LogoEnEscena extends StatelessWidget { const LogoEnEscena({required
  ValueListenable<EscenaDelLogo> escena, Color color = const Color(0xFFFFFFFF)}); }
```

- [ ] **Paso 1. Escribe la prueba que falla.** Agrega estos imports y este grupo al final de
  `main()` de `test/splash/splash_geometria_test.dart`.

```dart
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ulima_plus/components/logo/escena_del_logo.dart';
import 'package:ulima_plus/components/logo/pintor_del_logo.dart';
```

```dart
  group('la escena y el pintor', () {
    const centro = Offset(100, 100);

    test('la escena en reposo trae los ocho rombos quietos y los dos «+» en '
        'su lugar', () {
      final e = EscenaDelLogo.reposo(centro: centro, radio: 90);
      expect(e.rombos, hasLength(8));
      expect(e.rombos.every((r) => r.desplazamiento == 0 && r.opacidad == 1),
          isTrue);
      expect(
        e.cruces.map((c) => c.centro).toList(),
        LogoGeometria.centrosDeCruz,
      );
      final sinCruces =
          EscenaDelLogo.reposo(centro: centro, radio: 90, conCruces: false);
      expect(sinCruces.cruces, isEmpty);
    });

    test('la pose da el centro, el radio y los «+» en dp de la vista', () {
      final pose = EscenaDelLogo.reposo(centro: centro, radio: 90).pose;
      final u = 90 / 354.8;
      expect(pose.centro, centro);
      expect(pose.radio, 90);
      expect(pose.giro, 0);
      expect(pose.cruces[0].centro.dx, closeTo(100 + 308.7 * u, 1e-9));
      expect(pose.cruces[0].centro.dy, closeTo(100 - 133.8 * u, 1e-9));
      expect(pose.cruces[1].escala, 1);
    });

    test('la pose de una escena corrida y de una estrella movida sigue a la '
        'estrella', () {
      final e = EscenaDelLogo.reposo(centro: centro, radio: 90).copyWith(
        corrimiento: const Offset(-36, 0),
        desplazamientoDeEstrella: const Offset(0, -10),
        escalaDeEstrella: 0.5,
      );
      final u = 90 / 354.8;
      expect(e.pose.centro.dx, closeTo(100 - 36 * u, 1e-9));
      expect(e.pose.centro.dy, closeTo(100 - 10 * u, 1e-9));
      expect(e.pose.radio, closeTo(45, 1e-9));
    });

    test('una escena desde una pose vuelve a dar la misma pose', () {
      final original = EscenaDelLogo.reposo(centro: centro, radio: 90)
          .copyWith(corrimiento: const Offset(-36, 0), giro: 0.2)
          .pose;
      final vuelta = EscenaDelLogo.desdePose(original).pose;
      expect(vuelta.centro.dx, closeTo(original.centro.dx, 1e-9));
      expect(vuelta.centro.dy, closeTo(original.centro.dy, 1e-9));
      expect(vuelta.radio, closeTo(original.radio, 1e-9));
      expect(vuelta.giro, closeTo(original.giro, 1e-9));
      for (var i = 0; i < 2; i++) {
        expect(vuelta.cruces[i].centro.dx,
            closeTo(original.cruces[i].centro.dx, 1e-9));
        expect(vuelta.cruces[i].centro.dy,
            closeTo(original.cruces[i].centro.dy, 1e-9));
      }
    });

    testWidgets('el pintor dibuja la estrella en blanco y nada fuera de ella',
        (tester) async {
      tester.view.physicalSize = const Size(200, 200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final clave = GlobalKey();
      final escena = ValueNotifier(
        EscenaDelLogo.reposo(centro: centro, radio: 90, conCruces: false),
      );
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: clave,
            child: SizedBox(
              width: 200,
              height: 200,
              child: CustomPaint(painter: PintorDelLogo(escena)),
            ),
          ),
        ),
      );
      final alfa = await _alfas(tester, clave);
      expect(alfa(100, 100), 255, reason: 'el centro de la estrella');
      expect(alfa(100, 30), 255, reason: 'dentro del rombo de arriba');
      expect(alfa(100, 5), 0, reason: 'más allá de la punta, a 95 dp');
      expect(alfa(0, 0), 0, reason: 'la esquina');
    });

    test('el pintor no se repinta con la misma escena', () {
      final escena = ValueNotifier(
        EscenaDelLogo.reposo(centro: centro, radio: 90),
      );
      expect(PintorDelLogo(escena).shouldRepaint(PintorDelLogo(escena)),
          isFalse);
    });
  });
```

  Agrega también esta función de apoyo al final del archivo, fuera de `main()`.

```dart
/// El alfa de cada píxel de lo que pintó el `RepaintBoundary` de [clave].
Future<int Function(int x, int y)> _alfas(
  WidgetTester tester,
  GlobalKey clave,
) async {
  final frontera =
      clave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final imagen = (await tester.runAsync(() => frontera.toImage()))!;
  final datos = (await tester.runAsync(
    () => imagen.toByteData(format: ImageByteFormat.rawRgba),
  ))!;
  final ancho = imagen.width;
  return (x, y) => datos.getUint8((y * ancho + x) * 4 + 3);
}
```

- [ ] **Paso 2. Corre la prueba y confirma que falla.**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/splash/splash_geometria_test.dart
```

Esperado. Falla la compilación, porque `escena_del_logo.dart` y `pintor_del_logo.dart` no existen.

- [ ] **Paso 3. Escribe la escena.** Crea `lib/components/logo/escena_del_logo.dart` con este
  contenido.

```dart
// lib/components/logo/escena_del_logo.dart
// Lo que se ve del logo en un instante (RF-SPL-2). Las variantes de la intro
// devuelven una escena por milisegundo, el sello y la cabecera pintan una
// escena quieta y la bienvenida recibe la pose de la última (RF-SPL-21).
//
// La escena tiene un marco, que es `centro` y `radio` en dp de la vista, y
// todo lo demás va en unidades u de ese marco. `corrimiento` mueve el
// conjunto entero, como el −36 u de Incremento, y la estrella tiene además
// su propio desplazamiento, escala y giro, como en la subida de Código.

import 'dart:ui';

import 'logo_geometria.dart';

const Color _blanco = Color(0xFFFFFFFF);

/// Un rombo. El desplazamiento va hacia afuera del centro, en u, y el giro
/// es alrededor del centro de la estrella. La escala es alrededor del
/// centroide del rombo.
class RomboEnEscena {
  const RomboEnEscena({
    this.desplazamiento = 0,
    this.giro = 0,
    this.escala = 1,
    this.opacidad = 1,
  });

  static const RomboEnEscena enReposo = RomboEnEscena();

  final double desplazamiento;
  final double giro;
  final double escala;
  final double opacidad;
}

/// Un «+», con el centro en u del marco, sin el giro de la estrella.
class CruzEnEscena {
  const CruzEnEscena({
    required this.centro,
    this.escala = 1,
    this.giro = 0,
    this.opacidad = 1,
    this.grosor = 1,
    this.color = _blanco,
  });

  final Offset centro;
  final double escala;
  final double giro;
  final double opacidad;

  /// El grosor relativo al de la cruz del logo.
  final double grosor;
  final Color color;

  CruzEnEscena copyWith({
    Offset? centro,
    double? escala,
    double? giro,
    double? opacidad,
    double? grosor,
    Color? color,
  }) => CruzEnEscena(
    centro: centro ?? this.centro,
    escala: escala ?? this.escala,
    giro: giro ?? this.giro,
    opacidad: opacidad ?? this.opacidad,
    grosor: grosor ?? this.grosor,
    color: color ?? this.color,
  );
}

/// Un anillo blanco, con el centro, el radio y el trazo en u.
class AnilloEnEscena {
  const AnilloEnEscena({
    required this.centro,
    required this.radio,
    required this.trazo,
    required this.opacidad,
  });

  final Offset centro;
  final double radio;
  final double trazo;
  final double opacidad;
}

/// El destello de Ensamble. [avance] va de 0 a 1 a lo largo de la diagonal.
class DestelloEnEscena {
  const DestelloEnEscena({required this.avance, required this.intensidad});

  final double avance;
  final double intensidad;
}

/// El renglón «ULima++» de Código, en celdas de 0,6 em (decisión 4 del
/// plan). Solo pinta las letras, porque los «+» son cruces de la escena.
class TextoDeCodigo {
  const TextoDeCodigo({
    required this.visibles,
    required this.opacidad,
    this.dy = 0,
  });

  static const String palabra = 'ULima';

  /// El tamaño de la letra, en R.
  static const double tamano = 0.34;

  /// La línea base, en R bajo el centro.
  static const double lineaBase = 0.81;

  /// El ancho de una celda, en em.
  static const double celda = 0.6;

  /// Celdas del renglón «ULima++».
  static const int celdas = 7;

  /// Cuántas letras de «ULima» se ven.
  final int visibles;
  final double opacidad;

  /// Cuánto baja el renglón, en u.
  final double dy;

  static double get _em => tamano * LogoGeometria.radioNominal;

  /// El borde izquierdo de la celda [i], en u desde el centro.
  static double bordeDeCelda(int i) =>
      -celdas * celda * _em / 2 + i * celda * _em;

  /// El centro del glifo de la celda [i], en u. El «+» se centra 0,34 em
  /// sobre la línea base, como en `codigo.html`.
  static Offset centroDeCelda(int i) => Offset(
    bordeDeCelda(i) + celda * _em / 2,
    lineaBase * LogoGeometria.radioNominal - 0.34 * _em,
  );

  /// El tamaño de la letra en u.
  static double get tamanoEnU => _em;

  /// La línea base en u.
  static double get lineaBaseEnU => lineaBase * LogoGeometria.radioNominal;
}

/// Un cursor vertical, con el centro y el alto en u.
class CursorEnEscena {
  const CursorEnEscena({
    required this.centro,
    required this.alto,
    required this.opacidad,
  });

  final Offset centro;
  final double alto;
  final double opacidad;
}

/// Un «+» de la pose, en dp de la vista.
class PoseDeCruz {
  const PoseDeCruz({required this.centro, required this.escala});

  final Offset centro;
  final double escala;
}

/// Dónde queda el logo al terminar la intro, en dp de la vista. La intro la
/// pasa a la bienvenida como argumento de ruta (RF-SPL-21 y decisión S-33).
class PoseDelLogo {
  const PoseDelLogo({
    required this.centro,
    required this.radio,
    required this.giro,
    required this.cruces,
  });

  /// El centro de la estrella.
  final Offset centro;

  /// El radio de la estrella hasta la punta sin retraer.
  final double radio;
  final double giro;
  final List<PoseDeCruz> cruces;
}

class EscenaDelLogo {
  const EscenaDelLogo({
    required this.centro,
    required this.radio,
    this.corrimiento = Offset.zero,
    this.desplazamientoDeEstrella = Offset.zero,
    this.escalaDeEstrella = 1,
    this.giro = 0,
    this.escalaCentral = 1,
    this.opacidad = 1,
    this.rombos = rombosEnReposo,
    this.cruces = const <CruzEnEscena>[],
    this.anillos = const <AnilloEnEscena>[],
    this.destello,
    this.texto,
    this.cursor,
    this.recorteDeCruces,
  });

  /// La estrella completa con sus «++», quieta.
  factory EscenaDelLogo.reposo({
    required Offset centro,
    required double radio,
    bool conCruces = true,
  }) => EscenaDelLogo(
    centro: centro,
    radio: radio,
    cruces: conCruces ? crucesEnReposo() : const <CruzEnEscena>[],
  );

  /// La escena quieta de una [pose], con el marco en la estrella.
  factory EscenaDelLogo.desdePose(PoseDelLogo pose) {
    final u = LogoGeometria.unidad(pose.radio);
    return EscenaDelLogo(
      centro: pose.centro,
      radio: pose.radio,
      giro: pose.giro,
      cruces: <CruzEnEscena>[
        for (final c in pose.cruces)
          CruzEnEscena(centro: (c.centro - pose.centro) / u, escala: c.escala),
      ],
    );
  }

  static const List<RomboEnEscena> rombosEnReposo = <RomboEnEscena>[
    RomboEnEscena.enReposo,
    RomboEnEscena.enReposo,
    RomboEnEscena.enReposo,
    RomboEnEscena.enReposo,
    RomboEnEscena.enReposo,
    RomboEnEscena.enReposo,
    RomboEnEscena.enReposo,
    RomboEnEscena.enReposo,
  ];

  static List<CruzEnEscena> crucesEnReposo() => <CruzEnEscena>[
    for (final c in LogoGeometria.centrosDeCruz) CruzEnEscena(centro: c),
  ];

  final Offset centro;
  final double radio;
  final Offset corrimiento;
  final Offset desplazamientoDeEstrella;
  final double escalaDeEstrella;

  /// El giro de la estrella y sus rombos, en radianes.
  final double giro;

  /// La escala de la estrella central sola, para la compresión y el pulso.
  final double escalaCentral;
  final double opacidad;
  final List<RomboEnEscena> rombos;
  final List<CruzEnEscena> cruces;
  final List<AnilloEnEscena> anillos;
  final DestelloEnEscena? destello;
  final TextoDeCodigo? texto;
  final CursorEnEscena? cursor;

  /// Si no es null, los «+» solo se ven a la derecha de esta x, en u del
  /// marco, como en Incremento, donde nacen detrás del rombo derecho.
  final double? recorteDeCruces;

  /// Cuántos dp mide una u del marco.
  double get unidad => LogoGeometria.unidad(radio);

  /// Un punto del marco, en u, llevado a dp de la vista.
  Offset aVista(Offset enU) => centro + (corrimiento + enU) * unidad;

  Offset get centroDeLaEstrella => aVista(desplazamientoDeEstrella);

  double get radioDeLaEstrella => radio * escalaDeEstrella;

  PoseDelLogo get pose => PoseDelLogo(
    centro: centroDeLaEstrella,
    radio: radioDeLaEstrella,
    giro: giro,
    cruces: <PoseDeCruz>[
      for (final c in cruces)
        PoseDeCruz(centro: aVista(c.centro), escala: c.escala),
    ],
  );

  EscenaDelLogo copyWith({
    Offset? centro,
    double? radio,
    Offset? corrimiento,
    Offset? desplazamientoDeEstrella,
    double? escalaDeEstrella,
    double? giro,
    double? escalaCentral,
    double? opacidad,
    List<RomboEnEscena>? rombos,
    List<CruzEnEscena>? cruces,
    List<AnilloEnEscena>? anillos,
    DestelloEnEscena? destello,
    TextoDeCodigo? texto,
    CursorEnEscena? cursor,
    double? recorteDeCruces,
  }) => EscenaDelLogo(
    centro: centro ?? this.centro,
    radio: radio ?? this.radio,
    corrimiento: corrimiento ?? this.corrimiento,
    desplazamientoDeEstrella:
        desplazamientoDeEstrella ?? this.desplazamientoDeEstrella,
    escalaDeEstrella: escalaDeEstrella ?? this.escalaDeEstrella,
    giro: giro ?? this.giro,
    escalaCentral: escalaCentral ?? this.escalaCentral,
    opacidad: opacidad ?? this.opacidad,
    rombos: rombos ?? this.rombos,
    cruces: cruces ?? this.cruces,
    anillos: anillos ?? this.anillos,
    destello: destello ?? this.destello,
    texto: texto ?? this.texto,
    cursor: cursor ?? this.cursor,
    recorteDeCruces: recorteDeCruces ?? this.recorteDeCruces,
  );
}
```

- [ ] **Paso 4. Escribe el pintor.** Crea `lib/components/logo/pintor_del_logo.dart` con este
  contenido.

```dart
// lib/components/logo/pintor_del_logo.dart
// El único pintor del logo (RF-SPL-2). Se repinta con la escena que escucha,
// sin reconstruir widgets en cada cuadro (RF-SPL-17). Los caminos salen de
// LogoGeometria, que los construye una vez, y las cruces son dos rectángulos.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'escena_del_logo.dart';
import 'logo_geometria.dart';

/// Las letras de Código ya medidas, por letra y tamaño.
final Map<String, TextPainter> _letras = <String, TextPainter>{};

TextPainter _letra(String letra, double tamano) {
  return _letras.putIfAbsent('$letra@$tamano', () {
    return TextPainter(
      text: TextSpan(
        text: letra,
        style: TextStyle(
          fontFamily: 'monospace',
          fontFamilyFallback: const <String>['Menlo', 'Courier'],
          fontSize: tamano,
          color: const Color(0xFFFFFFFF),
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout();
  });
}

Color _conAlfa(Color color, double alfa) =>
    color.withValues(alpha: color.a * alfa.clamp(0.0, 1.0));

/// Pinta [escena] en [canvas], en coordenadas de la vista.
void pintarEscena(
  Canvas canvas,
  EscenaDelLogo escena, {
  Color color = const Color(0xFFFFFFFF),
}) {
  final u = escena.unidad;
  final pintura = Paint()..isAntiAlias = true;
  final destello = escena.destello;

  // La banda tenue del destello cruza el fondo naranja, detrás de todo.
  if (destello != null && destello.intensidad > 0) {
    _banda(canvas, escena, destello, 0.12 * destello.intensidad, null);
  }

  // La estrella con sus rombos.
  canvas.save();
  final centro = escena.centroDeLaEstrella;
  canvas.translate(centro.dx, centro.dy);
  canvas.rotate(escena.giro);
  canvas.scale(u * escena.escalaDeEstrella);
  if (destello != null && destello.intensidad > 0) {
    // Recortada a la silueta sin retraer y detrás de los rombos, así que
    // solo asoma por las rendijas (RF-SPL-7).
    _banda(canvas, escena, destello, destello.intensidad, LogoGeometria.silueta);
  }
  for (var k = 0; k < 8; k++) {
    final r = escena.rombos[k];
    if (r.opacidad <= 0) continue;
    canvas.save();
    canvas.rotate(r.giro);
    final d = LogoGeometria.direccionesDeRombo[k] * r.desplazamiento;
    final c = LogoGeometria.centrosDeRombo[k];
    canvas.translate(d.dx + c.dx, d.dy + c.dy);
    canvas.scale(r.escala);
    canvas.translate(-c.dx, -c.dy);
    pintura.color = _conAlfa(color, r.opacidad * escena.opacidad);
    canvas.drawPath(LogoGeometria.rombos[k], pintura);
    canvas.restore();
  }
  canvas.save();
  canvas.scale(escena.escalaCentral);
  pintura.color = _conAlfa(color, escena.opacidad);
  canvas.drawPath(LogoGeometria.estrellaCentral, pintura);
  canvas.restore();
  canvas.restore();

  // Los anillos, en el marco.
  for (final a in escena.anillos) {
    if (a.opacidad <= 0) continue;
    final trazo = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = a.trazo * u
      ..color = _conAlfa(color, a.opacidad * escena.opacidad);
    canvas.drawCircle(escena.aVista(a.centro), a.radio * u, trazo);
  }

  // Los «+», recortados si la escena lo pide.
  final recorte = escena.recorteDeCruces;
  canvas.save();
  if (recorte != null) {
    final x = escena.aVista(Offset(recorte, 0)).dx;
    canvas.clipRect(Rect.fromLTRB(x, -1e5, 1e5, 1e5));
  }
  for (final c in escena.cruces) {
    if (c.opacidad <= 0 || c.escala <= 0) continue;
    canvas.save();
    final p = escena.aVista(c.centro);
    canvas.translate(p.dx, p.dy);
    canvas.rotate(c.giro);
    canvas.scale(u * c.escala);
    final (h, v) = LogoGeometria.barrasDeCruz(grosor: c.grosor);
    pintura.color = _conAlfa(c.color, c.opacidad * escena.opacidad);
    canvas.drawRect(h, pintura);
    canvas.drawRect(v, pintura);
    canvas.restore();
  }
  canvas.restore();

  // Las letras de Código, cada una centrada en su celda.
  final texto = escena.texto;
  if (texto != null && texto.opacidad > 0 && texto.visibles > 0) {
    final tamano = TextoDeCodigo.tamanoEnU * u;
    canvas.saveLayer(
      null,
      Paint()..color = _conAlfa(const Color(0xFFFFFFFF), texto.opacidad),
    );
    for (var i = 0; i < math.min(texto.visibles, 5); i++) {
      final letra = _letra(TextoDeCodigo.palabra[i], tamano);
      final celda = TextoDeCodigo.bordeDeCelda(i) +
          TextoDeCodigo.celda * TextoDeCodigo.tamanoEnU / 2;
      final base = escena.aVista(
        Offset(celda, TextoDeCodigo.lineaBaseEnU + texto.dy),
      );
      letra.paint(
        canvas,
        Offset(
          base.dx - letra.width / 2,
          base.dy - letra.computeDistanceToActualBaseline(
            TextBaseline.alphabetic,
          ),
        ),
      );
    }
    canvas.restore();
  }

  final cursor = escena.cursor;
  if (cursor != null && cursor.opacidad > 0) {
    pintura.color = _conAlfa(color, cursor.opacidad * escena.opacidad);
    canvas.drawRect(
      Rect.fromCenter(
        center: escena.aVista(cursor.centro),
        width: 0.08 * TextoDeCodigo.tamanoEnU * u,
        height: cursor.alto * u,
      ),
      pintura,
    );
  }
}

/// Una banda blanca con degradado que cruza en diagonal. Con [recorte], va
/// dentro de él y en u de la estrella. Sin él, cruza la pantalla en dp.
void _banda(
  Canvas canvas,
  EscenaDelLogo escena,
  DestelloEnEscena destello,
  double intensidad,
  Path? recorte,
) {
  const alcance = 520.0; // u a cada lado del centro
  const ancho = 140.0; // u
  final s = -alcance + 2 * alcance * destello.avance;
  final enU = recorte != null;
  final escala = enU ? 1.0 : escena.unidad;
  final origen = enU ? Offset.zero : escena.centroDeLaEstrella;
  final eje = const Offset(1, 1) / math.sqrt2;
  final medio = origen + eje * (s * escala);
  final desde = medio - eje * (ancho / 2 * escala);
  final hasta = medio + eje * (ancho / 2 * escala);
  const blanco = Color(0xFFFFFFFF);
  final pintura = Paint()
    ..shader = ui.Gradient.linear(
      desde,
      hasta,
      <Color>[
        _conAlfa(blanco, 0),
        _conAlfa(blanco, intensidad),
        _conAlfa(blanco, 0),
      ],
      const <double>[0, 0.5, 1],
    );
  canvas.save();
  if (recorte != null) canvas.clipPath(recorte);
  final lado = alcance * 2 * escala;
  canvas.drawRect(
    Rect.fromCenter(center: origen, width: lado, height: lado),
    pintura,
  );
  canvas.restore();
}

class PintorDelLogo extends CustomPainter {
  PintorDelLogo(this.escena, {this.color = const Color(0xFFFFFFFF)})
    : super(repaint: escena);

  final ValueListenable<EscenaDelLogo> escena;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) =>
      pintarEscena(canvas, escena.value, color: color);

  @override
  bool shouldRepaint(PintorDelLogo oldDelegate) =>
      oldDelegate.escena != escena || oldDelegate.color != color;
}

/// El logo de una escena que cambia, fuera de la semántica.
class LogoEnEscena extends StatelessWidget {
  const LogoEnEscena({
    super.key,
    required this.escena,
    this.color = const Color(0xFFFFFFFF),
  });

  final ValueListenable<EscenaDelLogo> escena;
  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      painter: PintorDelLogo(escena, color: color),
      size: Size.infinite,
    ),
  );
}
```

- [ ] **Paso 5. Corre la prueba y confirma que pasa.**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/components/logo test/splash/splash_geometria_test.dart
"${FLUTTER:?}" test --no-pub test/splash/splash_geometria_test.dart
"${FLUTTER:?}" analyze --no-pub
```

Esperado. `All tests passed!` con las trece pruebas y `6 issues found.`.

- [ ] **Paso 6. Commit.**

```bash
cd "${REPO:?}"
git status --short
git add lib/components/logo/escena_del_logo.dart lib/components/logo/pintor_del_logo.dart test/splash/splash_geometria_test.dart
git commit -m "feat(splash): la escena del logo, su pose para la bienvenida y un solo pintor que la dibuja (RF-SPL-2 y S-33)"
git log -1 --format='%an <%ae>'
```

---

### Tarea 3. El PNG del splash nativo y los recursos nativos

**Requisitos.** RF-SPL-1 y RF-SPL-3 completos (decisiones S-1, S-2 y S-16).

**Archivos.**
- Crear `test/splash/splash_png_nativo_test.dart`.
- Crear `assets/splash/splash_estrella.png` (lo escribe la prueba).
- Modificar `pubspec.yaml:76-84`.
- Regenerar con `flutter_native_splash` los archivos de `android/app/src/main/res/drawable*/**`,
  `android/app/src/main/res/values*/styles.xml`, `ios/Runner/Assets.xcassets/LaunchImage.imageset/**`,
  `ios/Runner/Assets.xcassets/LaunchBackground.imageset/**`,
  `ios/Runner/Base.lproj/LaunchScreen.storyboard`, `ios/Runner/Info.plist`, `web/index.html` y
  `web/splash/**`.

**Interfaces.**
- Consume `EscenaDelLogo.reposo` y `PintorDelLogo` de la Tarea 2.
- Produce `assets/splash/splash_estrella.png`, que usa la prueba del primer cuadro (Tarea 12).
  `assets/splash/` no entra en los assets de Flutter.

- [ ] **Paso 1. Escribe la prueba que falla.** Crea `test/splash/splash_png_nativo_test.dart` con
  este contenido.

```dart
// test/splash/splash_png_nativo_test.dart
//
// UNITARIA · Splash animado (specs/features/splash/splash.spec.md).
// RF-SPL-1 y RF-SPL-3. La estrella del splash nativo sale del mismo pintor
// que la intro, con R = 360 px en un lienzo transparente de 1152 × 1152.
//
// Con `flutter test --update-goldens` esta prueba escribe
// assets/splash/splash_estrella.png. Sin la bandera, comprueba el PNG del
// repo con una tolerancia y no con la comparación exacta de
// `matchesGoldenFile`, porque el suavizado cambia entre macOS y Linux.

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/components/logo/escena_del_logo.dart';
import 'package:ulima_plus/components/logo/pintor_del_logo.dart';

const double _lado = 1152;
const String _png = 'assets/splash/splash_estrella.png';

/// Un umbral de 48 niveles de alfa, en a lo sumo el 1 % de los píxeles, cubre
/// el suavizado de los bordes y nada más.
const int _umbral = 48;
const double _fraccionTolerada = 0.01;

class _Rgba {
  const _Rgba(this.ancho, this.alto, this.bytes);

  final int ancho;
  final int alto;
  final ByteData bytes;

  int alfa(int x, int y) => bytes.getUint8((y * ancho + x) * 4 + 3);
}

Future<_Rgba> _pintado(WidgetTester tester, GlobalKey clave) async {
  final frontera =
      clave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final imagen = (await tester.runAsync(() => frontera.toImage()))!;
  final datos = (await tester.runAsync(
    () => imagen.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  return _Rgba(imagen.width, imagen.height, datos);
}

Future<_Rgba> _delArchivo(WidgetTester tester) async {
  final bytes = File(_png).readAsBytesSync();
  final imagen = (await tester.runAsync(() async {
    final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
    return (await codec.getNextFrame()).image;
  }))!;
  final datos = (await tester.runAsync(
    () => imagen.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  return _Rgba(imagen.width, imagen.height, datos);
}

void main() {
  testWidgets('el PNG del nativo es la estrella de la geometría, sin «++», '
      'con R = 360 px', (tester) async {
    tester.view.physicalSize = const Size(_lado, _lado);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final clave = GlobalKey();
    final escena = ValueNotifier(
      EscenaDelLogo.reposo(
        centro: const Offset(_lado / 2, _lado / 2),
        radio: 360,
        conCruces: false,
      ),
    );
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RepaintBoundary(
            key: clave,
            child: SizedBox(
              width: _lado,
              height: _lado,
              child: CustomPaint(painter: PintorDelLogo(escena)),
            ),
          ),
        ),
      ),
    );

    if (autoUpdateGoldenFiles) {
      await expectLater(
        find.byKey(clave),
        matchesGoldenFile('../../$_png'),
      );
      return;
    }

    expect(File(_png).existsSync(), isTrue, reason: 'falta $_png');
    final delRepo = await _delArchivo(tester);
    expect(delRepo.ancho, 1152);
    expect(delRepo.alto, 1152);

    for (final (x, y) in [(0, 0), (1151, 0), (0, 1151), (1151, 1151)]) {
      expect(delRepo.alfa(x, y), 0, reason: 'la esquina ($x, $y)');
    }

    var fuera = 0;
    var distintos = 0;
    final pintado = await _pintado(tester, clave);
    for (var y = 0; y < 1152; y++) {
      for (var x = 0; x < 1152; x++) {
        final a = delRepo.alfa(x, y);
        final distancia = math.sqrt(
          math.pow(x + 0.5 - 576, 2) + math.pow(y + 0.5 - 576, 2),
        );
        if (a > 0 && distancia > 384) fuera++;
        if ((a - pintado.alfa(x, y)).abs() > _umbral) distintos++;
      }
    }
    expect(fuera, 0, reason: 'ningún píxel blanco a más de 384 px del centro');
    expect(
      distintos / (1152 * 1152),
      lessThanOrEqualTo(_fraccionTolerada),
      reason: 'el PNG del repo no coincide con la geometría',
    );
  });

  test('assets/splash no entra en los assets de Flutter', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final assets = RegExp(r'^  assets:\n((?:    - .*\n)+)', multiLine: true)
        .firstMatch(pubspec)!
        .group(1)!;
    expect(assets, isNot(contains('assets/splash')));
  });

  test('flutter_native_splash usa el PNG nuevo en Android 12 o superior y en '
      'los demás, sobre #E77330 y sin variantes oscuras', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final bloque = pubspec.substring(pubspec.indexOf('flutter_native_splash:\n'));
    final hasta = bloque.indexOf('\n\n');
    final config = bloque.substring(0, hasta);
    expect(config, contains('image: $_png'));
    expect(RegExp('image: $_png').allMatches(config), hasLength(2));
    expect(RegExp('color: "#E77330"').allMatches(config), hasLength(2));
    expect(config, isNot(contains('_dark')));
    expect(config, isNot(contains('icon_background_color')));
  });
}
```

- [ ] **Paso 2. Corre la prueba y confirma que falla.**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/splash/splash_png_nativo_test.dart
```

Esperado. Fallan dos pruebas. La primera, con `falta assets/splash/splash_estrella.png`, y la
tercera, porque `pubspec.yaml` todavía apunta a `UL_fondo_naranja_grande.png`. La segunda pasa.

- [ ] **Paso 3. Apunta el splash nativo al PNG nuevo.** En `pubspec.yaml`, reemplaza el bloque de
  `flutter_native_splash` y su comentario (`pubspec.yaml:76-84`) por este.

```yaml
# Splash al abrir la app (RF-SPL-1 de specs/features/splash/splash.spec.md).
# La estrella del logo, blanca y sin «++», sobre el naranja de marca de borde a
# borde, en los temas claro y oscuro. El PNG lo escribe
# test/splash/splash_png_nativo_test.dart con --update-goldens desde la misma
# geometría de la intro, y el ícono del launcher no cambia. Regenerar con
#   flutter test --update-goldens test/splash/splash_png_nativo_test.dart
#   dart run flutter_native_splash:create
flutter_native_splash:
  color: "#E77330"
  image: assets/splash/splash_estrella.png
  android_12:
    color: "#E77330"
    image: assets/splash/splash_estrella.png
```

- [ ] **Paso 4. Genera el PNG.**

```bash
cd "${REPO:?}"
mkdir -p assets/splash
"${FLUTTER:?}" test --no-pub --update-goldens test/splash/splash_png_nativo_test.dart
"${FLUTTER:?}" test --no-pub test/splash/splash_png_nativo_test.dart
```

Esperado. La primera corrida escribe `assets/splash/splash_estrella.png` y la segunda da
`All tests passed!` con las tres pruebas.

- [ ] **Paso 5. Regenera los recursos nativos.**

```bash
cd "${REPO:?}"
"${DART:?}" run flutter_native_splash:create
git status --short
```

Esperado. `git status --short` lista solo `pubspec.yaml`, `assets/splash/`, `test/splash/` y
archivos de `android/app/src/main/res/drawable*`, `android/app/src/main/res/values*`,
`ios/Runner/Assets.xcassets/LaunchImage.imageset`, `ios/Runner/Assets.xcassets/LaunchBackground.imageset`,
`ios/Runner/Base.lproj/LaunchScreen.storyboard`, `ios/Runner/Info.plist`, `web/index.html` y
`web/splash/`. Los `drawable-night-*` que hoy existen pueden salir, porque la configuración ya no
tiene variantes oscuras. Si aparece otro archivo, se revierte con `git checkout -- <archivo>` y se
anota en el informe. `mipmap-*` no cambia, porque el ícono del launcher sigue igual.

- [ ] **Paso 6. Comprueba las medidas del nativo.**

```bash
cd "${REPO:?}"
file assets/splash/splash_estrella.png android/app/src/main/res/drawable-xxxhdpi/android12splash.png
grep -n "E77330\|splash" android/app/src/main/res/values-v31/styles.xml
```

Esperado. Los dos PNG miden 1152 × 1152 y `values-v31/styles.xml` fija `windowSplashScreenBackground`
en `#E77330` y el ícono `android12splash`.

- [ ] **Paso 7. Verificación y commit.**

```bash
cd "${REPO:?}"
"${DART:?}" format test/splash/splash_png_nativo_test.dart
"${FLUTTER:?}" analyze --no-pub
git add pubspec.yaml assets/splash/splash_estrella.png test/splash/splash_png_nativo_test.dart android/app/src/main/res ios/Runner web
git status --short
git commit -m "feat(splash): el splash nativo muestra la estrella entera sobre #E77330, sin cortes en Android 12 y sin cuadrado detrás (RF-SPL-1 y RF-SPL-3)"
git log -1 --format='%an <%ae>'
```

El `git add` de las carpetas nativas solo suma lo que regeneró el Paso 5, que ya se revisó. Si
`git status --short` muestra algo más antes del commit, se saca del índice con
`git restore --staged <archivo>`.

---

### Tarea 4. Una variante al azar en cada arranque en frío

**Requisitos.** RF-SPL-6 completo (decisiones S-4 y S-5), salvo el momento en que corre el tiempo
de la intro, que es de la Tarea 13.

**Archivos.**
- Crear `lib/services/splash_variante_service.dart`.
- Crear `test/splash/apoyo_splash.dart`.
- Crear `test/splash/splash_seleccion_test.dart`.

**Interfaces.**
- Consume `SharedPreferences` y `StorageService.clearSession` de hoy.
- Produce estas firmas, que usan las Tareas 7 a 9 y 12 a 14.

```dart
enum VarianteSplash { ensamble, incremento, codigo;
  String get clave; static VarianteSplash? deClave(String? clave); }
VarianteSplash elegirVariante(VarianteSplash? ultima, Random random);
class SplashVarianteService {
  SplashVarianteService({Future<SharedPreferences> Function()? preferencias});
  static const String clave = 'splash_ultima_variante';
  Future<VarianteSplash> elegir(Random random); }
// test/splash/apoyo_splash.dart
class RandomFijo implements Random { RandomFijo(List<int> valores);
  final List<int> maximos; }
```

- [ ] **Paso 1. Escribe el apoyo de las pruebas.** Crea `test/splash/apoyo_splash.dart` con este
  contenido. La Tarea 12 le suma el montaje de la capa.

```dart
// test/splash/apoyo_splash.dart
//
// Apoyo de las pruebas del splash. No termina en _test.dart, así que
// `flutter test` no lo corre como suite.

import 'dart:math';

/// Un `Random` que devuelve [valores] en orden, cada uno módulo el máximo que
/// le piden, y anota esos máximos.
class RandomFijo implements Random {
  RandomFijo(this.valores);

  final List<int> valores;
  final List<int> maximos = <int>[];
  var _i = 0;

  @override
  int nextInt(int max) {
    maximos.add(max);
    final v = valores[_i % valores.length];
    _i++;
    return v % max;
  }

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}
```

- [ ] **Paso 2. Escribe la prueba que falla.** Crea `test/splash/splash_seleccion_test.dart` con
  este contenido.

```dart
// test/splash/splash_seleccion_test.dart
//
// UNITARIA · Splash animado (specs/features/splash/splash.spec.md).
// RF-SPL-6. La variante sale al azar con probabilidad pareja y sin repetir la
// del arranque anterior, y la última se guarda en shared_preferences.
// Archivo probado lib/services/splash_variante_service.dart.

import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ulima_plus/services/splash_variante_service.dart';
import 'package:ulima_plus/services/storage_service.dart';

import 'apoyo_splash.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('elegirVariante (RF-SPL-6)', () {
    test('sin una última válida sale una de las tres', () {
      final vistas = <VarianteSplash>{
        for (var i = 0; i < 3; i++) elegirVariante(null, RandomFijo([i])),
      };
      expect(vistas, VarianteSplash.values.toSet());
    });

    test('con una última sale una de las otras dos, nunca la misma', () {
      for (final ultima in VarianteSplash.values) {
        final random = RandomFijo([0, 1]);
        final a = elegirVariante(ultima, random);
        final b = elegirVariante(ultima, random);
        expect({a, b}, VarianteSplash.values.toSet()..remove(ultima));
        expect(random.maximos, [2, 2]);
      }
    });

    test('a la larga cada variante sale en un tercio de los arranques y '
        'nunca dos veces seguidas', () {
      final random = Random(7);
      final cuenta = <VarianteSplash, int>{};
      VarianteSplash? ultima;
      const arranques = 30000;
      for (var i = 0; i < arranques; i++) {
        final v = elegirVariante(ultima, random);
        expect(v, isNot(ultima));
        cuenta[v] = (cuenta[v] ?? 0) + 1;
        ultima = v;
      }
      for (final v in VarianteSplash.values) {
        expect(cuenta[v]! / arranques, closeTo(1 / 3, 0.02), reason: '$v');
      }
    });

    test('las claves son ensamble, incremento y codigo', () {
      expect(VarianteSplash.values.map((v) => v.clave).toList(), [
        'ensamble',
        'incremento',
        'codigo',
      ]);
      expect(VarianteSplash.deClave('codigo'), VarianteSplash.codigo);
      expect(VarianteSplash.deClave('otra'), isNull);
      expect(VarianteSplash.deClave(null), isNull);
    });
  });

  group('SplashVarianteService (RF-SPL-6)', () {
    test('lee la última, elige otra y la guarda con su clave', () async {
      SharedPreferences.setMockInitialValues({
        'splash_ultima_variante': 'codigo',
      });
      final random = RandomFijo([1]);
      final v = await SplashVarianteService().elegir(random);
      expect(v, VarianteSplash.incremento);
      expect(random.maximos, [2]);
      final prefs = await SharedPreferences.getInstance();
      await Future<void>.delayed(Duration.zero);
      expect(prefs.getString('splash_ultima_variante'), 'incremento');
    });

    test('un valor desconocido cuenta como la primera vez', () async {
      SharedPreferences.setMockInitialValues({
        'splash_ultima_variante': 'otra',
      });
      final random = RandomFijo([2]);
      expect(await SplashVarianteService().elegir(random), VarianteSplash.codigo);
      expect(random.maximos, [3]);
    });

    test('si la lectura falla, sale entre las tres y no se guarda', () async {
      final random = RandomFijo([0]);
      final servicio = SplashVarianteService(
        preferencias: () async => throw StateError('sin almacén'),
      );
      expect(await servicio.elegir(random), VarianteSplash.ensamble);
      expect(random.maximos, [3]);
    });

    test('cerrar sesión no borra la última variante', () async {
      SharedPreferences.setMockInitialValues({
        'splash_ultima_variante': 'ensamble',
        'session_code': '20230001',
      });
      FlutterSecureStorage.setMockInitialValues({'session_token': 'jwt'});
      final almacen = await StorageService().init();
      await almacen.clearSession();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('session_code'), isNull);
      expect(prefs.getString('splash_ultima_variante'), 'ensamble');
    });
  });
}
```

- [ ] **Paso 3. Corre la prueba y confirma que falla.**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/splash/splash_seleccion_test.dart
```

Esperado. Falla la compilación, porque `splash_variante_service.dart` no existe.

- [ ] **Paso 4. Escribe el servicio.** Crea `lib/services/splash_variante_service.dart` con este
  contenido.

```dart
// lib/services/splash_variante_service.dart
// La variante de la intro del splash (RF-SPL-6). Sale al azar, con
// probabilidad pareja y sin repetir la del arranque anterior, y la última se
// guarda en shared_preferences con su propia instancia, así que la lectura no
// espera a que la carga registre StorageService. Es una preferencia de
// interfaz y no un dato académico, y cerrar sesión no la borra.

import 'dart:async';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

enum VarianteSplash {
  ensamble,
  incremento,
  codigo;

  /// El valor que se guarda.
  String get clave => name;

  static VarianteSplash? deClave(String? clave) {
    for (final v in values) {
      if (v.name == clave) return v;
    }
    return null;
  }
}

/// Con una [ultima] válida sale una de las otras dos con probabilidad 1/2, y
/// sin ella, una de las tres con probabilidad 1/3.
VarianteSplash elegirVariante(VarianteSplash? ultima, Random random) {
  if (ultima == null) {
    return VarianteSplash.values[random.nextInt(VarianteSplash.values.length)];
  }
  final otras = <VarianteSplash>[
    for (final v in VarianteSplash.values)
      if (v != ultima) v,
  ];
  return otras[random.nextInt(otras.length)];
}

class SplashVarianteService {
  SplashVarianteService({Future<SharedPreferences> Function()? preferencias})
    : _preferencias = preferencias ?? SharedPreferences.getInstance;

  static const String clave = 'splash_ultima_variante';

  final Future<SharedPreferences> Function() _preferencias;

  /// Lee la última, elige y guarda la elegida sin esperar la escritura. Si la
  /// lectura falla, la variante sale entre las tres y no se guarda.
  Future<VarianteSplash> elegir(Random random) async {
    SharedPreferences? prefs;
    VarianteSplash? ultima;
    try {
      prefs = await _preferencias();
      ultima = VarianteSplash.deClave(prefs.getString(clave));
    } catch (_) {
      prefs = null;
    }
    final elegida = elegirVariante(ultima, random);
    if (prefs != null) {
      unawaited(
        prefs.setString(clave, elegida.clave).catchError((Object _) => false),
      );
    }
    return elegida;
  }
}
```

- [ ] **Paso 5. Corre la prueba y confirma que pasa.**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/services/splash_variante_service.dart test/splash/apoyo_splash.dart test/splash/splash_seleccion_test.dart
"${FLUTTER:?}" test --no-pub test/splash/splash_seleccion_test.dart
"${FLUTTER:?}" analyze --no-pub
```

Esperado. `All tests passed!` con las ocho pruebas y `6 issues found.`.

- [ ] **Paso 6. Commit.**

```bash
cd "${REPO:?}"
git status --short
git add lib/services/splash_variante_service.dart test/splash/apoyo_splash.dart test/splash/splash_seleccion_test.dart
git commit -m "feat(splash): la intro elige su variante al azar sin repetir la anterior y la recuerda en splash_ultima_variante (RF-SPL-6)"
git log -1 --format='%an <%ae>'
```

---

### Tarea 5. La estrella en la cabecera, su estilo único, la barra de estado y su medida

**Requisitos.** BR-SHELL-F-04 de app-shell completo y la parte de RF-SPL-11 que pide que la
cabecera informe dónde quedan su estrella y su texto, sin una `GlobalKey` compartida, y que el
estilo de «ULIMA++» viva en un solo lugar. La parte de la barra de estado de RF-SPL-4 para
`/home`.

**Archivos.**
- Crear `lib/components/logo/estrella_del_logo.dart`.
- Crear `lib/pages/splash/puntos_de_aterrizaje.dart`.
- Modificar `lib/components/header/app_header.dart`.
- Modificar `test/components/header/app_header_test.dart` (grupo `BR-SHELL-F-04`).

**Interfaces.**
- Consume `EscenaDelLogo` y `PintorDelLogo` de la Tarea 2.
- Produce estas firmas, que usan las Tareas 10, 13, 16, 26 y 30.

```dart
// estrella_del_logo.dart
class EscenaFija implements ValueListenable<EscenaDelLogo> { EscenaFija(EscenaDelLogo value); }
class EstrellaDelLogo extends StatelessWidget { const EstrellaDelLogo({double tamano = 26,
  Color color = const Color(0xFFFFFFFF)}); } // de punta a punta, fuera de la semántica
// puntos_de_aterrizaje.dart
class MedidaDeCabecera { const MedidaDeCabecera({required Rect cabecera,
  required Rect estrella, required Rect texto, required TextStyle estilo,
  required TextScaler escalaDeTexto, required Color color,
  required Color colorDelBorde}); }
abstract final class PuntosDeAterrizaje {
  static final ValueNotifier<MedidaDeCabecera?> cabecera;
  static final ValueNotifier<Rect?> burbuja;
  static final ValueNotifier<bool> ulisesEnVuelo;
  static void reiniciar(); }
// app_header.dart
class AppHeader extends StatefulWidget { static TextStyle estiloDeMarca(ColorScheme colores);
  static const double tamanoDeEstrella = 26; static const double separacion = 10; }
```

- [ ] **Paso 1. Escribe la prueba que falla.** En `test/components/header/app_header_test.dart`,
  suma estos imports y este grupo al final de `main()`.

```dart
import 'package:ulima_plus/components/logo/estrella_del_logo.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/pages/splash/puntos_de_aterrizaje.dart';
```

```dart
  group('BR-SHELL-F-04 · la estrella junto a «ULIMA++»', () {
    tearDown(PuntosDeAterrizaje.reiniciar);

    Future<void> montar(
      WidgetTester tester,
      UserModel usuario, {
      Brightness brillo = Brightness.light,
    }) async {
      Get.put<AuthService>(_FakeAuthService(usuario));
      if (!usuario.isTeacher) Get.put<AlertService>(_AlertasSinRed());
      const tema = MaterialTheme(TextTheme());
      await tester.pumpWidget(
        GetMaterialApp(
          theme: brillo == Brightness.light ? tema.light() : tema.dark(),
          home: Scaffold(
            body: Align(alignment: Alignment.topCenter, child: AppHeader()),
          ),
        ),
      );
      await tester.pump();
    }

    for (final usuario in [_alumna(), _docente()]) {
      testWidgets('la estrella de 26 dp va a 10 dp a la izquierda del texto, '
          'centrada en su línea, para ${usuario.role}', (tester) async {
        await montar(tester, usuario);
        final estrella = tester.getRect(find.byType(EstrellaDelLogo));
        final texto = tester.getRect(find.text('ULIMA++'));
        expect(estrella.width, 26);
        expect(estrella.height, 26);
        expect(texto.left - estrella.right, closeTo(10, 0.01));
        expect(estrella.center.dy, closeTo(texto.center.dy, 0.5));
        // El alto no cambia, con 50 + 30 + 20 y el borde de 2.
        expect(tester.getSize(find.byType(AppHeader)).height, 102);
      });
    }

    testWidgets('la estrella es decorativa y el enlace sigue siendo solo el '
        'texto', (tester) async {
      await montar(tester, _alumna());
      final estrella = find.byType(EstrellaDelLogo);
      expect(
        find.descendant(of: estrella, matching: find.byType(ExcludeSemantics)),
        findsOneWidget,
      );
      expect(
        find.ancestor(of: estrella, matching: find.byType(InkWell)),
        findsNothing,
      );
      expect(
        find.bySemanticsLabel('Abrir promoción de Don Belisario'),
        findsOneWidget,
      );
    });

    for (final brillo in Brightness.values) {
      testWidgets('declara íconos claros en la barra de estado en '
          '${brillo.name}', (tester) async {
        await montar(tester, _alumna(), brillo: brillo);
        final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
          find.descendant(
            of: find.byType(AppHeader),
            matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
          ),
        );
        expect(region.value.statusBarIconBrightness, Brightness.light);
        expect(region.value.statusBarBrightness, Brightness.dark);
      });
    }

    testWidgets('informa dónde quedan su estrella y su texto una vez que se '
        'dibuja', (tester) async {
      await montar(tester, _alumna());
      final medida = PuntosDeAterrizaje.cabecera.value;
      expect(medida, isNotNull);
      expect(medida!.estrella, tester.getRect(find.byType(EstrellaDelLogo)));
      expect(medida.texto, tester.getRect(find.text('ULIMA++')));
      expect(medida.cabecera, tester.getRect(find.byType(AppHeader)));
      expect(medida.estilo.fontSize, 20);
      expect(medida.estilo.fontStyle, FontStyle.italic);
      expect(medida.color, MaterialTheme.primaryColor);
    });
  });
```

- [ ] **Paso 2. Corre la prueba y confirma que falla.**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/components/header/app_header_test.dart
```

Esperado. Falla la compilación, porque `estrella_del_logo.dart` y `puntos_de_aterrizaje.dart` no
existen.

- [ ] **Paso 3. Escribe la estrella quieta.** Crea `lib/components/logo/estrella_del_logo.dart`.

```dart
// lib/components/logo/estrella_del_logo.dart
// La estrella del logo, quieta y sin «++», como en la cabecera
// (BR-SHELL-F-04). Se pinta con la geometría única (RF-SPL-2), así que la
// estrella de la intro aterriza sobre la misma figura (RF-SPL-11).

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'escena_del_logo.dart';
import 'pintor_del_logo.dart';

/// Una escena que no cambia nunca.
class EscenaFija implements ValueListenable<EscenaDelLogo> {
  EscenaFija(this.value);

  @override
  final EscenaDelLogo value;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

class EstrellaDelLogo extends StatelessWidget {
  const EstrellaDelLogo({
    super.key,
    this.tamano = 26,
    this.color = const Color(0xFFFFFFFF),
  });

  /// De punta a punta, sin retraer.
  final double tamano;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final escena = EscenaFija(
      EscenaDelLogo.reposo(
        centro: Offset(tamano / 2, tamano / 2),
        radio: tamano / 2,
        conCruces: false,
      ),
    );
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: tamano,
        child: CustomPaint(painter: PintorDelLogo(escena, color: color)),
      ),
    );
  }
}
```

- [ ] **Paso 4. Escribe los puntos de aterrizaje.** Crea
  `lib/pages/splash/puntos_de_aterrizaje.dart`.

```dart
// lib/pages/splash/puntos_de_aterrizaje.dart
// Dónde quedan las piezas a las que llega la capa del arranque. La cabecera
// informa su estrella y su texto una vez que se dibuja (RF-SPL-11), y la
// burbuja de Ulises su lugar inicial (RF-BIEN-11). Cada una informa desde su
// propio State, sin una GlobalKey compartida, y si dos cabeceras conviven un
// instante manda la última que se dibuja.

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

class MedidaDeCabecera {
  const MedidaDeCabecera({
    required this.cabecera,
    required this.estrella,
    required this.texto,
    required this.estilo,
    required this.escalaDeTexto,
    required this.color,
    required this.colorDelBorde,
  });

  /// La cabecera entera, con su borde inferior, en coordenadas globales.
  final Rect cabecera;
  final Rect estrella;

  /// El texto «ULIMA++».
  final Rect texto;
  final TextStyle estilo;
  final TextScaler escalaDeTexto;

  /// `headerColor` del tema.
  final Color color;
  final Color colorDelBorde;

  @override
  bool operator ==(Object other) =>
      other is MedidaDeCabecera &&
      other.cabecera == cabecera &&
      other.estrella == estrella &&
      other.texto == texto &&
      other.estilo == estilo &&
      other.escalaDeTexto == escalaDeTexto &&
      other.color == color &&
      other.colorDelBorde == colorDelBorde;

  @override
  int get hashCode => Object.hash(
    cabecera,
    estrella,
    texto,
    estilo,
    escalaDeTexto,
    color,
    colorDelBorde,
  );
}

abstract final class PuntosDeAterrizaje {
  static final ValueNotifier<MedidaDeCabecera?> cabecera =
      ValueNotifier<MedidaDeCabecera?>(null);

  /// El lugar inicial de la burbuja de Ulises, en coordenadas globales.
  static final ValueNotifier<Rect?> burbuja = ValueNotifier<Rect?>(null);

  /// La capa lo enciende solo en el paso al horario de la bienvenida, y la
  /// burbuja espera oculta hasta que se apaga (decisiones S-28 y B-16).
  static final ValueNotifier<bool> ulisesEnVuelo = ValueNotifier<bool>(false);

  static void reiniciar() {
    cabecera.value = null;
    burbuja.value = null;
    ulisesEnVuelo.value = false;
  }
}
```

- [ ] **Paso 5. Cambia la cabecera.** En `lib/components/header/app_header.dart`, haz estos cambios.

  1. Suma los imports.

```dart
import 'package:ulima_plus/components/logo/estrella_del_logo.dart';
import 'package:ulima_plus/pages/splash/puntos_de_aterrizaje.dart';
```

  2. Convierte `AppHeader` en un `StatefulWidget` con el mismo constructor. Las constantes, el
     enlace y `_launchExternally` pasan a la clase del widget, y el estilo de marca queda en un
     solo lugar.

```dart
class AppHeader extends StatefulWidget {
  /// Si la pestaña activa es Horario. Solo sirve para devolverle la rotación
  /// al volver de las alertas (BR-SHELL-F-03).
  final bool isScheduleTab;
  final AppHeaderLinkLauncher? linkLauncher;

  const AppHeader({super.key, this.isScheduleTab = false, this.linkLauncher});

  /// La estrella mide 26 dp de punta a punta y va a 10 dp del texto
  /// (BR-SHELL-F-04).
  static const double tamanoDeEstrella = 26;
  static const double separacion = 10;

  /// El único estilo de «ULIMA++». La capa del arranque y el sello de la
  /// bienvenida dibujan réplicas suyas (RF-SPL-11 y RF-BIEN-4).
  static TextStyle estiloDeMarca(ColorScheme colores) => TextStyle(
    color: colores.onPrimary,
    fontSize: 20,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.bold,
  );

  static const List<DeviceOrientation> _scheduleOrientations = [
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];
  static const List<DeviceOrientation> _portraitOnly = [
    DeviceOrientation.portraitUp,
  ];

  static final Uri _donBelisarioPromotionUri = Uri.parse(
    'https://www.donbelisario.com.pe/clasico-combo-contundente?'
    'gsImpressionId=01KXPTTES6C5C0S9FKJG902C2G&'
    'gsListName=Recomendaciones%20-%20Promociones&gsIndex=3',
  );

  static Future<bool> _launchExternally(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  // Claves propias de esta cabecera. No se comparten, así que dos cabeceras
  // que conviven un instante no chocan.
  final GlobalKey _claveCabecera = GlobalKey();
  final GlobalKey _claveEstrella = GlobalKey();
  final GlobalKey _claveTexto = GlobalKey();

  Future<void> _openDonBelisarioPromotion() async {
    final launcher = widget.linkLauncher ?? AppHeader._launchExternally;
    await launcher(AppHeader._donBelisarioPromotionUri);
  }

  Rect? _rectDe(GlobalKey clave) {
    final caja = clave.currentContext?.findRenderObject() as RenderBox?;
    if (caja == null || !caja.hasSize || !caja.attached) return null;
    return caja.localToGlobal(Offset.zero) & caja.size;
  }

  /// Informa la medida después del cuadro, cuando ya hay layout.
  void _informar(Duration _) {
    if (!mounted) return;
    final cabecera = _rectDe(_claveCabecera);
    final estrella = _rectDe(_claveEstrella);
    final texto = _rectDe(_claveTexto);
    if (cabecera == null || estrella == null || texto == null) return;
    final colores = Theme.of(context).colorScheme;
    PuntosDeAterrizaje.cabecera.value = MedidaDeCabecera(
      cabecera: cabecera,
      estrella: estrella,
      texto: texto,
      // El estilo con el que se dibuja, con lo que hereda del tema, para que
      // la réplica de la intro caiga sobre el texto real.
      estilo: DefaultTextStyle.of(
        context,
      ).style.merge(AppHeader.estiloDeMarca(colores)),
      escalaDeTexto: MediaQuery.textScalerOf(context),
      color: MaterialTheme.headerColor(Theme.brightnessOf(context)),
      colorDelBorde: colores.primaryContainer,
    );
  }
```

  3. Reemplaza el `build` de hoy por este en `_AppHeaderState`. El `Container` va dentro del
     `AnnotatedRegion`, la estrella queda fuera del enlace y la campana es la de hoy con
     `widget.isScheduleTab` y las listas de orientaciones de `AppHeader`.

```dart
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(_informar);
    final colors = Theme.of(context).colorScheme;
    // La campana es propia del alumno (BR-SHELL-F-03).
    final isTeacher = AuthService.to.currentUser?.isTeacher ?? false;
    final showAlerts = !isTeacher;

    // Íconos claros sobre la cabecera naranja u oscura, en los dos temas. La
    // intro del splash deja aplicado el último estilo de la barra, así que la
    // cabecera declara el suyo (RF-SPL-4 y BR-SHELL-F-04).
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        key: _claveCabecera,
        padding: const EdgeInsets.only(
          top: 50,
          left: 20,
          right: 20,
          bottom: 20,
        ),
        decoration: BoxDecoration(
          color: MaterialTheme.headerColor(Theme.brightnessOf(context)),
          border: Border(
            bottom: BorderSide(color: colors.primaryContainer, width: 2.0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                EstrellaDelLogo(
                  key: _claveEstrella,
                  tamano: AppHeader.tamanoDeEstrella,
                  color: colors.onPrimary,
                ),
                const SizedBox(width: AppHeader.separacion),
                Semantics(
                  button: true,
                  excludeSemantics: true,
                  label: 'Abrir promoción de Don Belisario',
                  child: InkWell(
                    key: const Key('app-header-brand-link'),
                    borderRadius: BorderRadius.circular(4),
                    onTap: _openDonBelisarioPromotion,
                    child: Text(
                      'ULIMA++',
                      key: _claveTexto,
                      style: AppHeader.estiloDeMarca(colors),
                    ),
                  ),
                ),
              ],
            ),
            if (showAlerts)
              Obx(() {
                final count = Get.isRegistered<AlertService>()
                    ? AlertService.to.unreadCount
                    : 0;
                return InkWell(
                  onTap: () async {
                    await SystemChrome.setPreferredOrientations(
                      AppHeader._portraitOnly,
                    );
                    await Get.to(() => const AlertasPage());
                    if (widget.isScheduleTab) {
                      await SystemChrome.setPreferredOrientations(
                        AppHeader._scheduleOrientations,
                      );
                    }
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        color: colors.onPrimary,
                        size: 30,
                      ),
                      if (count > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color.fromARGB(255, 29, 111, 219),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Center(
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              })
            else
              const SizedBox(width: 30, height: 30),
          ],
        ),
      ),
    );
  }
}
```

  Hoy la fila va dentro de una `Column` de un solo hijo (`app_header.dart:66-156`), que no
  cambia nada y sale. Borra también el comentario `LOGO SVG` del final
  (`app_header.dart:161-168`), que la estrella reemplaza.

- [ ] **Paso 6. Corre la prueba y confirma que pasa.**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/components/logo/estrella_del_logo.dart lib/pages/splash/puntos_de_aterrizaje.dart lib/components/header/app_header.dart test/components/header/app_header_test.dart
"${FLUTTER:?}" test --no-pub test/components/header/app_header_test.dart test/HU23_jeff/chats_pestana_test.dart
"${FLUTTER:?}" analyze --no-pub
```

Esperado. `All tests passed!` en los dos archivos, con las pruebas de hoy del header y las siete
nuevas, y `6 issues found.`. Las pruebas de hoy siguen en verde porque el constructor y el enlace
no cambian.

- [ ] **Paso 7. Suite completa y commit.** Corre la suite completa en segundo plano. Esperado,
  `All tests passed!` con siete pruebas más que la Tarea 4.

```bash
cd "${REPO:?}"
git status --short
git add lib/components/logo/estrella_del_logo.dart lib/pages/splash/puntos_de_aterrizaje.dart lib/components/header/app_header.dart test/components/header/app_header_test.dart
git commit -m "feat(app-shell): la cabecera muestra la estrella del logo junto a «ULIMA++», declara íconos claros e informa dónde queda (BR-SHELL-F-04)"
git log -1 --format='%an <%ae>'
```

---

### Tarea 6. `/home` abre en Horario con el argumento y pide sus orientaciones al retirarse la capa

**Requisitos.** RF-SPL-20 completo (decisiones S-24, S-25, S-26 y S-31), con la enmienda de
BR-SHELL-F-00 y BR-SHELL-F-02 de app-shell.

**Archivos.**
- Crear `lib/pages/splash/estado_de_la_capa.dart`.
- Modificar `lib/pages/home/home_page.dart:23-66`.
- Crear `test/splash/home_pestana_inicial_test.dart`.

**Interfaces.**
- Consume nada de tareas anteriores.
- Produce estas firmas, que usan las Tareas 12, 13 y 30.

```dart
// estado_de_la_capa.dart
abstract final class EstadoDeLaCapa { static final ValueNotifier<bool> cubre; }
// home_page.dart
const String argumentoDePestana = 'pestana';
const Map<String, String> abrirEnHorario = {'pestana': 'horario'};
int indiceDePestanaInicial(Object? argumentos, List<String> etiquetas);
```

- [ ] **Paso 1. Escribe la prueba que falla.** Crea `test/splash/home_pestana_inicial_test.dart`
  con este contenido. Los dobles son los de `test/HU23_jeff/chats_pestana_test.dart:134-265`, con
  `canGrade` configurable.

```dart
// test/splash/home_pestana_inicial_test.dart
//
// UNITARIA + WIDGET · Splash animado (specs/features/splash/splash.spec.md).
// RF-SPL-20 y BR-SHELL-F-02 de app-shell. Con el argumento
// {'pestana': 'horario'}, /home abre en Horario para todos los roles, sin él
// abre en la primera pestaña, y mientras la capa del arranque cubre la
// pantalla la app sigue en vertical.
// Archivo probado lib/pages/home/home_page.dart.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/footer/app_footer.dart';
import 'package:ulima_plus/models/advising_models.dart';
import 'package:ulima_plus/models/curso_delegado_model.dart';
import 'package:ulima_plus/models/portal_sync_models.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/delegado/delegado_cursos/delegado_cursos_controller.dart';
import 'package:ulima_plus/pages/home/home_controller.dart';
import 'package:ulima_plus/pages/home/home_page.dart';
import 'package:ulima_plus/pages/horario/horario.dart';
import 'package:ulima_plus/pages/horario/horario_controller.dart';
import 'package:ulima_plus/pages/malla/malla_list_controller.dart';
import 'package:ulima_plus/pages/malla/malla_list_page.dart';
import 'package:ulima_plus/pages/splash/estado_de_la_capa.dart';
import 'package:ulima_plus/pages/teacher/teacher_home_controller.dart';
import 'package:ulima_plus/pages/teacher/teacher_sections_controller.dart';
import 'package:ulima_plus/pages/teacher/teacher_sections_page.dart';
import 'package:ulima_plus/services/advising_service.dart';
import 'package:ulima_plus/services/alert_service.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/delegate_service.dart';
import 'package:ulima_plus/services/malla_service.dart';
import 'package:ulima_plus/services/portal_sync_service.dart';

// --- Datos inventados ---------------------------------------------------------

UserModel _usuario(String rol, {String? etiqueta}) => UserModel(
  code: rol == 'teacher' ? 'docente.test' : '20230001',
  firstName: 'Persona',
  lastName: 'De Prueba',
  email: 'test@aloe.ulima.edu.pe',
  role: rol,
  teacherLabel: etiqueta,
  currentCycle: '2026-2',
  setupComplete: true,
);

const List<String> _soloVertical = <String>['DeviceOrientation.portraitUp'];
const List<String> _rotacionDelHorario = <String>[
  'DeviceOrientation.portraitUp',
  'DeviceOrientation.landscapeLeft',
  'DeviceOrientation.landscapeRight',
];

// --- Dobles -------------------------------------------------------------------

class _FakeAuthService extends AuthService {
  _FakeAuthService(UserModel user, {this.califica = false})
    : userRx = Rx<UserModel?>(user);

  final Rx<UserModel?> userRx;
  final bool califica;

  @override
  UserModel? get currentUser => userRx.value;

  @override
  Rx<UserModel?> get currentUserRx => userRx;

  @override
  bool get canGrade => califica;

  @override
  Future<void> refreshCurrentUser() async {}
}

class _ApiSinRed extends ApiClient {
  _ApiSinRed() : super(configuredBaseUrl: 'http://test');

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    String? token,
    Map<String, String?> query = const {},
    bool suppressSessionExpiry = false,
  }) async => <String, dynamic>{};
}

class _PortalSinRed extends PortalSyncService {
  @override
  Future<PortalSyncStatus> status() async => PortalSyncStatus.desconocido;
}

class _MallaSinRed extends MallaService {
  @override
  Future<void> load() async => throw StateError('sin red');
}

class _AlertasSinRed extends AlertService {
  @override
  Future<void> fetchAlerts() async {}
}

class _DelegadoSinRed extends DelegateService {
  @override
  Future<List<CursoDelegado>> fetchDelegateSections() async =>
      <CursoDelegado>[];
}

class _AsesoriasSinRed extends AdvisingService {
  @override
  Future<List<TeacherSectionOption>> fetchSections() async =>
      <TeacherSectionOption>[];
}

// --- Montaje ------------------------------------------------------------------

final _orientaciones = <List<Object?>>[];

void _registrarDobles(UserModel usuario, {bool califica = false}) {
  Get.put<AuthService>(_FakeAuthService(usuario, califica: califica));
  Get.put<HomeController>(HomeController(portalSync: _PortalSinRed()));
  Get.put<HorarioController>(HorarioController(apiClient: _ApiSinRed()));
  if (usuario.isTeacher) {
    Get.put<TeacherSectionsController>(
      TeacherSectionsController(service: _AsesoriasSinRed()),
    );
    Get.put<TeacherHomeController>(TeacherHomeController());
  } else {
    Get.put<AlertService>(_AlertasSinRed());
    Get.put<MallaService>(_MallaSinRed());
    Get.put<MallaListController>(MallaListController());
    if (usuario.isDelegate) {
      Get.put<DelegadoCursosController>(
        DelegadoCursosController(delegateService: _DelegadoSinRed()),
      );
    }
  }
}

/// Abre /home como la intro, con Get.offAll, sin transición y con
/// [argumentos].
Future<void> _abrirHome(
  WidgetTester tester,
  UserModel usuario, {
  Object? argumentos,
  bool califica = false,
}) async {
  tester.view.physicalSize = const Size(800, 2800);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  _registrarDobles(usuario, califica: califica);
  await tester.pumpWidget(const GetMaterialApp(home: SizedBox.shrink()));
  Get.offAll<void>(
    () => const HomePage(),
    routeName: '/home',
    arguments: argumentos,
    transition: Transition.noTransition,
  );
  await tester.pump();
  await tester.pump();
}

Future<void> _desmontar(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  if (Get.isRegistered<HorarioController>()) {
    await Get.delete<HorarioController>(force: true);
  }
}

int _pestanaActual(WidgetTester tester) =>
    tester.widget<AppFooter>(find.byType(AppFooter)).currentIndex;

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
    EstadoDeLaCapa.cubre.value = false;
    _orientaciones.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (llamada) async {
          if (llamada.method == 'SystemChrome.setPreferredOrientations') {
            _orientaciones.add(llamada.arguments as List<Object?>);
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    EstadoDeLaCapa.cubre.value = false;
    Get.reset();
  });

  group('indiceDePestanaInicial (RF-SPL-20)', () {
    const alumno = ['Malla', 'Notas', 'Horario', 'Chats', 'Perfil'];
    const jefeDePractica = ['Secciones', 'Horario', 'Asesorias', 'Perfil'];

    test('con el argumento, la pestaña Horario por su etiqueta', () {
      expect(indiceDePestanaInicial(abrirEnHorario, alumno), 2);
      expect(indiceDePestanaInicial(abrirEnHorario, jefeDePractica), 1);
    });

    test('sin argumento o con otro valor, la primera', () {
      expect(indiceDePestanaInicial(null, alumno), 0);
      expect(indiceDePestanaInicial({'pestana': 'malla'}, alumno), 0);
      expect(indiceDePestanaInicial('horario', alumno), 0);
      expect(indiceDePestanaInicial(abrirEnHorario, ['Malla']), 0);
    });
  });

  group('WIDGET · la pestaña inicial (RF-SPL-20 y S-24)', () {
    final casos = <(String, UserModel, bool, int)>[
      ('el alumno', _usuario('student'), false, 2),
      ('el delegado', _usuario('delegado'), false, 2),
      ('el subdelegado', _usuario('subdelegado'), false, 2),
      ('el profesor titular', _usuario('teacher', etiqueta: 'Profesor'), true, 2),
      ('el jefe de práctica', _usuario('teacher', etiqueta: 'JP'), false, 1),
    ];
    for (final (nombre, usuario, califica, indice) in casos) {
      testWidgets('$nombre abre en Horario con el argumento', (tester) async {
        await _abrirHome(
          tester,
          usuario,
          argumentos: abrirEnHorario,
          califica: califica,
        );
        expect(find.byType(HorarioPage), findsOneWidget);
        expect(_pestanaActual(tester), indice);
        expect(_orientaciones.last, _rotacionDelHorario);
        await _desmontar(tester);
      });
    }

    testWidgets('sin argumento abre en la primera pestaña, como hoy', (
      tester,
    ) async {
      await _abrirHome(tester, _usuario('student'));
      expect(find.byType(MallaListPage), findsOneWidget);
      expect(_pestanaActual(tester), 0);
      expect(_orientaciones.last, _soloVertical);
      await _desmontar(tester);
    });

    testWidgets('el docente sin argumento abre en Secciones', (tester) async {
      await _abrirHome(tester, _usuario('teacher', etiqueta: 'JP'));
      expect(find.byType(TeacherSectionsPage), findsOneWidget);
      await _desmontar(tester);
    });
  });

  group('WIDGET · la orientación bajo la capa (RF-SPL-20 y S-26)', () {
    testWidgets('abierta en Horario bajo la capa sigue en vertical y pide la '
        'rotación del horario cuando la capa se retira', (tester) async {
      EstadoDeLaCapa.cubre.value = true;
      await _abrirHome(tester, _usuario('student'), argumentos: abrirEnHorario);
      expect(find.byType(HorarioPage), findsOneWidget);
      expect(_orientaciones, isEmpty);

      EstadoDeLaCapa.cubre.value = false;
      await tester.pump();
      expect(_orientaciones.last, _rotacionDelHorario);
      await _desmontar(tester);
    });

    testWidgets('fuera de Horario bajo la capa pide la vertical al retirarse',
        (tester) async {
      EstadoDeLaCapa.cubre.value = true;
      await _abrirHome(tester, _usuario('student'));
      expect(_orientaciones, isEmpty);
      EstadoDeLaCapa.cubre.value = false;
      await tester.pump();
      expect(_orientaciones.last, _soloVertical);
      await _desmontar(tester);
    });
  });
}
```

- [ ] **Paso 2. Corre la prueba y confirma que falla.**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/splash/home_pestana_inicial_test.dart
```

Esperado. Falla la compilación, porque `estado_de_la_capa.dart`, `indiceDePestanaInicial` y
`abrirEnHorario` no existen.

- [ ] **Paso 3. Escribe el estado de la capa.** Crea `lib/pages/splash/estado_de_la_capa.dart`.

```dart
// lib/pages/splash/estado_de_la_capa.dart
// Si la capa del arranque cubre la pantalla. Mientras la cubre, /home no pide
// las orientaciones de Horario, y las pide cuando la capa se retira
// (RF-SPL-20, decisión S-26 y BR-SHELL-F-00 de app-shell).

import 'package:flutter/foundation.dart';

abstract final class EstadoDeLaCapa {
  static final ValueNotifier<bool> cubre = ValueNotifier<bool>(false);
}
```

- [ ] **Paso 4. Cambia `HomePage`.** En `lib/pages/home/home_page.dart`, suma el import de
  `../splash/estado_de_la_capa.dart`, estas declaraciones antes de `class HomePage` y los cambios
  del `State`.

```dart
/// La clave del argumento de ruta que elige la pestaña inicial (RF-SPL-20).
const String argumentoDePestana = 'pestana';

/// Lo pasan la intro del splash y la bienvenida al llegar a /home (S-31).
const Map<String, String> abrirEnHorario = <String, String>{
  argumentoDePestana: 'horario',
};

/// El índice con el que abre el shell. Con `{'pestana': 'horario'}` es la
/// pestaña Horario, que se busca por su etiqueta y así sirve para todos los
/// roles (S-24). Sin argumento, o con otro valor, es la primera (S-25).
int indiceDePestanaInicial(Object? argumentos, List<String> etiquetas) {
  if (argumentos is Map && argumentos[argumentoDePestana] == 'horario') {
    final i = etiquetas.indexOf('Horario');
    if (i >= 0) return i;
  }
  return 0;
}
```

  En `_HomePageState`, borra el `initState` de hoy (`home_page.dart:62-66`) y suma esto.

```dart
  bool _argumentoLeido = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argumentoLeido) return;
    _argumentoLeido = true;
    // El argumento se lee una sola vez, al montarse (RF-SPL-20).
    _currentIndex = indiceDePestanaInicial(
      ModalRoute.of(context)?.settings.arguments,
      [for (final i in _config.footerItems) i.label],
    );
    // Bajo la capa del arranque la app sigue en vertical, y las orientaciones
    // se piden cuando la capa se retira (S-26).
    if (EstadoDeLaCapa.cubre.value) {
      EstadoDeLaCapa.cubre.addListener(_alRetirarseLaCapa);
    } else {
      _applyPreferredOrientations();
    }
  }

  void _alRetirarseLaCapa() {
    if (EstadoDeLaCapa.cubre.value) return;
    EstadoDeLaCapa.cubre.removeListener(_alRetirarseLaCapa);
    if (mounted) _applyPreferredOrientations();
  }
```

  Y en `dispose`, antes de `super.dispose()`, suma
  `EstadoDeLaCapa.cubre.removeListener(_alRetirarseLaCapa);`.

- [ ] **Paso 5. Corre las pruebas y confirma que pasan.**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/pages/splash/estado_de_la_capa.dart lib/pages/home/home_page.dart test/splash/home_pestana_inicial_test.dart
"${FLUTTER:?}" test --no-pub test/splash/home_pestana_inicial_test.dart test/HU23_jeff/chats_pestana_test.dart
"${FLUTTER:?}" analyze --no-pub
```

Esperado. `All tests passed!` en los dos archivos. «La app abre en Malla, en vertical» de
`chats_pestana_test.dart` sigue en verde, porque monta `HomePage` sin argumento y fuera de la
capa. `6 issues found.`.

- [ ] **Paso 6. Suite completa y commit.** Corre la suite completa en segundo plano. Esperado,
  `All tests passed!`.

```bash
cd "${REPO:?}"
git status --short
git add lib/pages/splash/estado_de_la_capa.dart lib/pages/home/home_page.dart test/splash/home_pestana_inicial_test.dart
git commit -m "feat(app-shell): /home abre en Horario con el argumento de ruta para todos los roles y pide sus orientaciones cuando se retira la capa (RF-SPL-20)"
git log -1 --format='%an <%ae>'
```

---

### Tarea 7. La base de las variantes y Ensamble

**Requisitos.** RF-SPL-7 completo (decisiones S-3 y S-17), el bucle A de RF-SPL-10 y la vuelta al
reposo de Ensamble de RF-SPL-21 (decisión S-34).

**Archivos.**
- Crear `lib/pages/splash/variantes/variante_de_intro.dart`.
- Crear `lib/pages/splash/variantes/ensamble.dart`.
- Crear `test/splash/splash_ensamble_test.dart`.

**Interfaces.**
- Consume `EscenaDelLogo` y sus piezas (Tarea 2), `LogoGeometria` (Tarea 1) y `VarianteSplash`
  (Tarea 4).
- Produce estas firmas, que usan las Tareas 8 a 10 y 13.

```dart
// variante_de_intro.dart
abstract class VarianteDeIntro {
  const VarianteDeIntro();
  VarianteSplash get tipo;
  double get finDeLaEntrada;      // ms
  double get duracionDeLaSalida;  // ms, hacia /home
  Curve get curvaDeLaSalida;
  /// La entrada, el bucle mientras [cargaLista] es null o posterior a [ms] y,
  /// hacia la bienvenida, la vuelta al reposo desde [cargaLista].
  EscenaDelLogo escena(double ms, {required Offset centro, required double radio,
    double? cargaLista});
  /// Cuándo queda el logo en reposo si la carga termina en [cargaLista].
  double finDelReposo(double? cargaLista);
  /// Lo que queda del bucle durante la salida que empieza en [msInicio].
  EscenaDelLogo alSalir(double msInicio, double msEnSalida,
    {required Offset centro, required double radio});
  /// El giro de la estrella al empezar la salida y su destino (Incremento).
  double giroAlSalir(double msInicio) => 0;
  double destinoDelGiro(double msInicio) => 0;
}
double tramo(double ms, double desde, double hasta);   // de 0 a 1, acotado
double conRebote(double t, double s);                   // easeOutBack con s
double medioSeno(double t);                             // sen(π·t)
double mezcla(double a, double b, double t);
Offset bezierCuadratica(Offset p0, Offset p1, Offset p2, double t);
const double grado;                                     // π / 180
// ensamble.dart
class Ensamble extends VarianteDeIntro { const Ensamble(); }
```

- [ ] **Paso 1. Escribe la prueba que falla.** Crea `test/splash/splash_ensamble_test.dart`.

```dart
// test/splash/splash_ensamble_test.dart
//
// UNITARIA · Splash animado (specs/features/splash/splash.spec.md).
// RF-SPL-7 fija la entrada de Ensamble fila por fila, RF-SPL-10 su onda de
// espera y RF-SPL-21 su vuelta al reposo antes del relevo (S-34). RF-SPL-17
// fija la duración de 1250 + 530 ms.
// Archivo probado lib/pages/splash/variantes/ensamble.dart.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/components/logo/escena_del_logo.dart';
import 'package:ulima_plus/components/logo/logo_geometria.dart';
import 'package:ulima_plus/pages/splash/variantes/ensamble.dart';
import 'package:ulima_plus/pages/splash/variantes/variante_de_intro.dart';
import 'package:ulima_plus/services/splash_variante_service.dart';

const _centro = Offset(187.5, 333.5);
const _v = Ensamble();

EscenaDelLogo _en(double ms, {double? cargaLista}) =>
    _v.escena(ms, centro: _centro, radio: 90, cargaLista: cargaLista);

void _enReposo(EscenaDelLogo e, {bool conCruces = true}) {
  for (final r in e.rombos) {
    expect(r.desplazamiento, closeTo(0, 1e-6));
    expect(r.giro, closeTo(0, 1e-6));
    expect(r.escala, closeTo(1, 1e-6));
    expect(r.opacidad, closeTo(1, 1e-6));
  }
  expect(e.escalaCentral, closeTo(1, 1e-6));
  expect(e.destello, isNull);
  if (conCruces) {
    expect(e.cruces, hasLength(2));
    for (var i = 0; i < 2; i++) {
      expect(e.cruces[i].centro, LogoGeometria.centrosDeCruz[i]);
      expect(e.cruces[i].escala, closeTo(1, 1e-6));
      expect(e.cruces[i].giro, closeTo(0, 1e-6));
    }
  } else {
    expect(e.cruces, isEmpty);
  }
}

void main() {
  group('Ensamble, la entrada (RF-SPL-7)', () {
    test('es la variante ensamble, entra en 1250 ms y sale en 530 ms', () {
      expect(_v.tipo, VarianteSplash.ensamble);
      expect(_v.finDeLaEntrada, 1250);
      expect(_v.duracionDeLaSalida, 530);
      expect(_v.finDeLaEntrada + _v.duracionDeLaSalida, 1780);
    });

    test('quieta de 0 a 80 ms, igual al nativo y sin «++»', () {
      _enReposo(_en(0), conCruces: false);
      _enReposo(_en(80), conCruces: false);
      expect(_en(0).centro, _centro);
      expect(_en(0).radio, 90);
    });

    test('a los 260 ms los ocho rombos están abiertos, 200 u afuera, a −60°, '
        'con escala 0,6 y opacidad 0,4', () {
      for (final r in _en(260).rombos) {
        expect(r.desplazamiento, closeTo(200, 1e-6));
        expect(r.giro, closeTo(-60 * grado, 1e-6));
        expect(r.escala, closeTo(0.6, 1e-6));
        expect(r.opacidad, closeTo(0.4, 1e-6));
      }
    });

    test('cada rombo encaja desde 260 + 50·k durante 264 ms, el último hasta '
        '874 ms', () {
      for (var k = 0; k < 8; k++) {
        final inicio = 260.0 + 50 * k;
        final abierto = _en(inicio - 1).rombos[k];
        if (k > 0) expect(abierto.desplazamiento, closeTo(200, 1e-6));
        final alMedio = _en(inicio + 50).rombos[k];
        expect(alMedio.opacidad, closeTo(1, 1e-6), reason: 'opacidad a 50 ms');
        final encajado = _en(inicio + 264).rombos[k];
        expect(encajado.desplazamiento, closeTo(0, 1e-6), reason: 'rombo $k');
        expect(encajado.giro, closeTo(0, 1e-6));
        expect(encajado.escala, closeTo(1, 1e-6));
      }
      expect(260 + 50 * 7 + 264, 874);
    });

    test('el encaje rebota, porque el desplazamiento pasa de cero', () {
      var minimo = double.infinity;
      for (var ms = 260.0; ms <= 524; ms += 2) {
        minimo = math.min(minimo, _en(ms).rombos[0].desplazamiento);
      }
      expect(minimo, lessThan(0));
    });

    test('la estrella central se contrae 2,2 % 119 ms después de cada encaje',
        () {
      // El pico de la compresión del rombo 0 es a 260 + 119 + 95 ms.
      expect(_en(474).escalaCentral, closeTo(0.978, 1e-3));
      expect(_en(378).escalaCentral, closeTo(1, 1e-6));
    });

    test('el destello cruza de 720 a 1080 ms, sin desenfoque', () {
      expect(_en(719).destello, isNull);
      final medio = _en(900).destello!;
      expect(medio.avance, closeTo(0.5, 1e-6));
      expect(medio.intensidad, closeTo(1, 1e-6));
      expect(_en(1081).destello, isNull);
    });

    test('el anillo crece de 370 u a 640 u entre 720 y 1260 ms', () {
      final inicio = _en(720).anillos.firstWhere((a) => a.centro == Offset.zero);
      expect(inicio.radio, closeTo(370, 1e-6));
      expect(inicio.trazo, closeTo(16, 1e-6));
      expect(inicio.opacidad, closeTo(0.35, 1e-6));
      expect(_en(1260).anillos, isEmpty);
    });

    test('cada «+» aparece girando de −90° a 0° con rebote de escala', () {
      expect(_en(859).cruces, isEmpty);
      final nace = _en(860).cruces.single;
      expect(nace.giro, closeTo(-90 * grado, 1e-6));
      expect(nace.escala, closeTo(0, 1e-6));
      expect(_en(930).cruces, hasLength(2));
      final primero = _en(1160).cruces[0];
      expect(primero.giro, closeTo(0, 1e-6));
      expect(primero.escala, closeTo(1, 1e-6));
      var maxima = 0.0;
      for (var ms = 860.0; ms <= 1160; ms += 2) {
        maxima = math.max(maxima, _en(ms).cruces[0].escala);
      }
      expect(maxima, greaterThan(1), reason: 'el rebote de escala');
      final onda = _en(900).anillos.where((a) => a.centro != Offset.zero);
      expect(onda, isNotEmpty, reason: 'la onda del primer «+»');
    });

    test('a los 1250 ms queda el logo completo con sus «++»', () {
      _enReposo(_en(1250));
      expect(_en(1250).anillos, isEmpty);
    });
  });

  group('Ensamble, la espera y el reposo (RF-SPL-10 y RF-SPL-21)', () {
    test('si la carga sigue, una onda de hasta 20 u recorre los rombos en '
        'sentido horario, con un período de 1100 ms, y entra en 300 ms', () {
      final alEntrar = _en(1250);
      expect(alEntrar.rombos.every((r) => r.desplazamiento == 0), isTrue);
      var maximo = 0.0;
      for (var ms = 1550.0; ms < 1550 + 1100; ms += 5) {
        final ds = _en(ms).rombos.map((r) => r.desplazamiento);
        maximo = math.max(maximo, ds.reduce(math.max));
      }
      expect(maximo, closeTo(20, 0.5));
      // Un período después, cada rombo vuelve a su desplazamiento.
      for (var k = 0; k < 8; k++) {
        expect(
          _en(1700).rombos[k].desplazamiento,
          closeTo(_en(2800).rombos[k].desplazamiento, 1e-6),
        );
      }
      // El pico pasa del rombo k al k + 1 en 1100 / 8 ms.
      final a = _en(1800).rombos.map((r) => r.desplazamiento).toList();
      final b = _en(1800 + 1100 / 8).rombos.map((r) => r.desplazamiento).toList();
      for (var k = 0; k < 8; k++) {
        expect(b[(k + 1) % 8], closeTo(a[k], 1e-6));
      }
    });

    test('con la carga lista antes de 1250 ms no hay bucle', () {
      _enReposo(_en(1500, cargaLista: 600));
      expect(_v.finDelReposo(600), 1250);
      expect(_v.finDelReposo(null), 1250);
    });

    test('si la carga termina en el bucle, la onda se apaga en 300 ms antes '
        'del relevo', () {
      expect(_v.finDelReposo(2000), 2300);
      final apagandose = _en(2150, cargaLista: 2000);
      final sinApagar = _en(2150);
      final suma = apagandose.rombos.fold<double>(0, (s, r) => s + r.desplazamiento);
      final sumaSinApagar =
          sinApagar.rombos.fold<double>(0, (s, r) => s + r.desplazamiento);
      expect(suma, lessThan(sumaSinApagar));
      _enReposo(_en(2300, cargaLista: 2000));
      _enReposo(_en(2600, cargaLista: 2000));
    });

    test('en la salida la onda se apaga en el primer tercio', () {
      final inicio = _v.alSalir(2000, 0, centro: _centro, radio: 90);
      final ahora = _en(2000);
      for (var k = 0; k < 8; k++) {
        expect(
          inicio.rombos[k].desplazamiento,
          closeTo(ahora.rombos[k].desplazamiento, 1e-6),
        );
      }
      final tercio = _v.alSalir(2000, 530 / 3, centro: _centro, radio: 90);
      expect(tercio.rombos.every((r) => r.desplazamiento.abs() < 1e-9), isTrue);
    });
  });
}
```

- [ ] **Paso 2. Corre la prueba y confirma que falla.**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/splash/splash_ensamble_test.dart
```

Esperado. Falla la compilación, porque `variante_de_intro.dart` y `ensamble.dart` no existen.

- [ ] **Paso 3. Escribe la base.** Crea `lib/pages/splash/variantes/variante_de_intro.dart`.

```dart
// lib/pages/splash/variantes/variante_de_intro.dart
// La base de las tres variantes de la intro (RF-SPL-6 a RF-SPL-10). Cada una
// es una línea de tiempo pura. Recibe el instante en ms, contado desde que la
// intro empieza a moverse, y devuelve la escena del logo. Así cada fila de
// las tablas de la spec se prueba con un número (decisión 1 del plan).

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/animation.dart';

import '../../../components/logo/escena_del_logo.dart';
import '../../../services/splash_variante_service.dart';

const double grado = math.pi / 180;

/// El avance de 0 a 1 entre [desde] y [hasta], acotado.
double tramo(double ms, double desde, double hasta) =>
    ((ms - desde) / (hasta - desde)).clamp(0.0, 1.0).toDouble();

/// easeOutBack con el sobrepaso [s]. Vale 0 en 0 y 1 en 1, y pasa de 1 en
/// el medio.
double conRebote(double t, double s) {
  final u = t - 1;
  return 1 + u * u * ((s + 1) * u + s);
}

/// Medio seno, de 0 a 1 y de vuelta a 0.
double medioSeno(double t) => math.sin(math.pi * t.clamp(0.0, 1.0));

double mezcla(double a, double b, double t) => a + (b - a) * t;

Offset bezierCuadratica(Offset p0, Offset p1, Offset p2, double t) {
  final s = 1 - t;
  return p0 * (s * s) + p1 * (2 * s * t) + p2 * (t * t);
}

abstract class VarianteDeIntro {
  const VarianteDeIntro();

  VarianteSplash get tipo;

  /// Fin de la entrada, en ms.
  double get finDeLaEntrada;

  /// La duración de la salida hacia /home, en ms (RF-SPL-11).
  double get duracionDeLaSalida;
  Curve get curvaDeLaSalida;

  /// La escena en [ms]. Si la carga sigue al terminar la entrada, la variante
  /// repite su bucle (RF-SPL-10). Si la carga termina durante el bucle, en
  /// [cargaLista], la variante vuelve al reposo, que es lo que pide el relevo
  /// a la bienvenida (RF-SPL-21 y S-34). Hacia /home, la capa pasa a la
  /// salida en [cargaLista] y deja de pedir esta escena.
  EscenaDelLogo escena(
    double ms, {
    required Offset centro,
    required double radio,
    double? cargaLista,
  });

  /// Cuándo queda el logo en reposo, listo para el relevo.
  double finDelReposo(double? cargaLista);

  /// Lo que queda del bucle mientras corre la salida que empieza en
  /// [msInicio], con el reposo como base. La salida mueve la estrella y los
  /// «+» por su cuenta.
  EscenaDelLogo alSalir(
    double msInicio,
    double msEnSalida, {
    required Offset centro,
    required double radio,
  });

  /// El giro de la estrella al empezar la salida.
  double giroAlSalir(double msInicio) => 0;

  /// El destino del giro en curso al empezar la salida.
  double destinoDelGiro(double msInicio) => 0;
}
```

- [ ] **Paso 4. Escribe Ensamble.** Crea `lib/pages/splash/variantes/ensamble.dart`.

```dart
// lib/pages/splash/variantes/ensamble.dart
// Variante A, «Ensamble» (RF-SPL-7). Arranca desde la estrella completa del
// nativo, los ocho rombos se abren juntos y vuelven a encajar uno a uno en
// sentido horario (S-3). La maqueta es
// docs/images/UI/splash/ensamble-adaptada.html.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/animation.dart';

import '../../../components/logo/escena_del_logo.dart';
import '../../../components/logo/logo_geometria.dart';
import '../../../services/splash_variante_service.dart';
import 'variante_de_intro.dart';

class Ensamble extends VarianteDeIntro {
  const Ensamble();

  static const double finDeLaQuietud = 80;
  static const double finDeLaApertura = 260;
  static const double alejamiento = 200; // u
  static const double inicioDeEncaje = 260;
  static const double pasoDeEncaje = 50;
  static const double duracionDeEncaje = 264;
  static const double periodoDeOnda = 1100;
  static const double ondaMaxima = 20; // u
  static const double entradaDeOnda = 300;
  static const List<double> inicioDeCruz = <double>[860, 930];

  @override
  VarianteSplash get tipo => VarianteSplash.ensamble;

  @override
  double get finDeLaEntrada => 1250;

  @override
  double get duracionDeLaSalida => 530;

  @override
  Curve get curvaDeLaSalida => Curves.easeInOutCubic;

  RomboEnEscena _rombo(int k, double ms) {
    if (ms < finDeLaQuietud) return RomboEnEscena.enReposo;
    final inicio = inicioDeEncaje + pasoDeEncaje * k;
    if (ms < inicio) {
      final p = Curves.easeOutCubic.transform(
        tramo(ms, finDeLaQuietud, finDeLaApertura),
      );
      return RomboEnEscena(
        desplazamiento: alejamiento * p,
        giro: -60 * grado * p,
        escala: 1 - 0.4 * p,
        opacidad: 1 - 0.6 * p,
      );
    }
    final t = tramo(ms, inicio, inicio + duracionDeEncaje);
    final g = Curves.easeOutCubic.transform(t);
    return RomboEnEscena(
      desplazamiento: alejamiento * (1 - conRebote(t, 1.25)),
      giro: -60 * grado * (1 - g),
      escala: 0.6 + 0.4 * g,
      opacidad: 0.4 + 0.6 * tramo(ms, inicio, inicio + 50),
    );
  }

  /// La estrella central se contrae 2,2 % con cada encaje. Si dos
  /// compresiones se solapan, manda la mayor (decisión 2 del plan).
  double _compresion(double ms) {
    var mayor = 0.0;
    for (var k = 0; k < 8; k++) {
      final c = inicioDeEncaje + pasoDeEncaje * k + 119;
      if (ms >= c && ms <= c + 190) {
        mayor = math.max(mayor, 0.022 * medioSeno(tramo(ms, c, c + 190)));
      }
    }
    return 1 - mayor;
  }

  List<CruzEnEscena> _cruces(double ms) => <CruzEnEscena>[
    for (var i = 0; i < 2; i++)
      if (ms >= inicioDeCruz[i])
        _cruz(i, tramo(ms, inicioDeCruz[i], inicioDeCruz[i] + 300)),
  ];

  CruzEnEscena _cruz(int i, double t) => CruzEnEscena(
    centro: LogoGeometria.centrosDeCruz[i],
    giro: -90 * grado * (1 - Curves.easeOutCubic.transform(t)),
    escala: conRebote(t, 2.4),
  );

  List<AnilloEnEscena> _anillos(double ms) {
    final anillos = <AnilloEnEscena>[];
    if (ms >= 720 && ms < 1260) {
      final e = Curves.easeOutCubic.transform(tramo(ms, 720, 1260));
      anillos.add(
        AnilloEnEscena(
          centro: Offset.zero,
          radio: mezcla(370, 640, e),
          trazo: mezcla(16, 3, e),
          opacidad: mezcla(0.35, 0, e),
        ),
      );
    }
    for (var i = 0; i < 2; i++) {
      final inicio = inicioDeCruz[i];
      if (ms >= inicio && ms < inicio + 300) {
        final t = tramo(ms, inicio, inicio + 300);
        anillos.add(
          AnilloEnEscena(
            centro: LogoGeometria.centrosDeCruz[i],
            radio: mezcla(48, 120, Curves.easeOutCubic.transform(t)),
            trazo: mezcla(6, 1, t),
            opacidad: 0.5 * (1 - t),
          ),
        );
      }
    }
    return anillos;
  }

  DestelloEnEscena? _destello(double ms) {
    if (ms < 720 || ms > 1080) return null;
    final avance = tramo(ms, 720, 1080);
    return DestelloEnEscena(avance: avance, intensidad: medioSeno(avance));
  }

  /// La amplitud de la onda de espera, de 0 a 1.
  double _amplitud(double ms, double? cargaLista) {
    final fin = finDeLaEntrada;
    if (ms <= fin) return 0;
    if (cargaLista != null && cargaLista <= fin) return 0;
    final entra = tramo(ms, fin, fin + entradaDeOnda);
    if (cargaLista == null || ms <= cargaLista) return entra;
    final alCargar = tramo(cargaLista, fin, fin + entradaDeOnda);
    return alCargar * (1 - tramo(ms, cargaLista, cargaLista + entradaDeOnda));
  }

  /// La onda en sentido horario, con forma de seno a la sexta.
  List<RomboEnEscena> _onda(double ms, double amplitud) {
    if (amplitud <= 0) return EscenaDelLogo.rombosEnReposo;
    final vuelta = (ms - finDeLaEntrada) / periodoDeOnda;
    return <RomboEnEscena>[
      for (var k = 0; k < 8; k++)
        RomboEnEscena(
          desplazamiento:
              ondaMaxima *
              amplitud *
              math.pow(math.sin(math.pi * ((vuelta - k / 8) % 1.0)), 6),
        ),
    ];
  }

  @override
  EscenaDelLogo escena(
    double ms, {
    required Offset centro,
    required double radio,
    double? cargaLista,
  }) {
    if (ms >= finDeLaEntrada) {
      return EscenaDelLogo(
        centro: centro,
        radio: radio,
        rombos: _onda(ms, _amplitud(ms, cargaLista)),
        cruces: EscenaDelLogo.crucesEnReposo(),
      );
    }
    return EscenaDelLogo(
      centro: centro,
      radio: radio,
      rombos: <RomboEnEscena>[for (var k = 0; k < 8; k++) _rombo(k, ms)],
      escalaCentral: _compresion(ms),
      cruces: _cruces(ms),
      anillos: _anillos(ms),
      destello: _destello(ms),
    );
  }

  @override
  double finDelReposo(double? cargaLista) =>
      cargaLista == null || cargaLista <= finDeLaEntrada
      ? finDeLaEntrada
      : cargaLista + entradaDeOnda;

  @override
  EscenaDelLogo alSalir(
    double msInicio,
    double msEnSalida, {
    required Offset centro,
    required double radio,
  }) {
    final amplitud =
        _amplitud(msInicio, null) *
        (1 - tramo(msEnSalida, 0, duracionDeLaSalida / 3));
    return EscenaDelLogo(
      centro: centro,
      radio: radio,
      rombos: _onda(msInicio + msEnSalida, amplitud),
      cruces: EscenaDelLogo.crucesEnReposo(),
    );
  }
}
```

- [ ] **Paso 5. Corre la prueba y confirma que pasa.**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/pages/splash/variantes test/splash/splash_ensamble_test.dart
"${FLUTTER:?}" test --no-pub test/splash/splash_ensamble_test.dart
"${FLUTTER:?}" analyze --no-pub
```

Esperado. `All tests passed!` con las catorce pruebas y `6 issues found.`.

- [ ] **Paso 6. Commit.**

```bash
cd "${REPO:?}"
git status --short
git add lib/pages/splash/variantes/variante_de_intro.dart lib/pages/splash/variantes/ensamble.dart test/splash/splash_ensamble_test.dart
git commit -m "feat(splash): Ensamble desarma la estrella del nativo y la vuelve a armar rombo a rombo, con su onda de espera y su vuelta al reposo (RF-SPL-7 y RF-SPL-10)"
git log -1 --format='%an <%ae>'
```

---

### Tarea 8. Incremento

**Requisitos.** RF-SPL-8 completo, el bucle B de RF-SPL-10 con la salida que absorbe el tic en
curso y la vuelta al reposo de Incremento de RF-SPL-21 (decisión S-34).

**Archivos.**
- Crear `lib/pages/splash/variantes/incremento.dart`.
- Crear `test/splash/splash_incremento_test.dart`.

**Interfaces.**
- Consume la base y las curvas de la Tarea 7.
- Produce `class Incremento extends VarianteDeIntro { const Incremento(); }` con
  `giroAlSalir` y `destinoDelGiro`, que usa la salida B de la Tarea 10.

- [ ] **Paso 1. Escribe la prueba que falla.** Crea `test/splash/splash_incremento_test.dart`.

```dart
// test/splash/splash_incremento_test.dart
//
// UNITARIA · Splash animado (specs/features/splash/splash.spec.md).
// RF-SPL-8 fija la entrada de Incremento, RF-SPL-10 sus tics de espera y la
// salida que absorbe el tic en curso, y RF-SPL-21 su vuelta al reposo, que
// termina el tic en curso a lo sumo 700 ms después de su inicio (S-34).
// Archivo probado lib/pages/splash/variantes/incremento.dart.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/components/logo/escena_del_logo.dart';
import 'package:ulima_plus/components/logo/logo_geometria.dart';
import 'package:ulima_plus/pages/splash/variantes/incremento.dart';
import 'package:ulima_plus/pages/splash/variantes/variante_de_intro.dart';
import 'package:ulima_plus/services/splash_variante_service.dart';

const _centro = Offset(187.5, 333.5);
const _v = Incremento();

EscenaDelLogo _en(double ms, {double? cargaLista}) =>
    _v.escena(ms, centro: _centro, radio: 90, cargaLista: cargaLista);

void main() {
  group('Incremento, la entrada (RF-SPL-8)', () {
    test('es la variante incremento, entra en 1150 ms y sale en 620 ms', () {
      expect(_v.tipo, VarianteSplash.incremento);
      expect(_v.finDeLaEntrada, 1150);
      expect(_v.duracionDeLaSalida, 620);
      expect(_v.finDeLaEntrada + _v.duracionDeLaSalida, 1770);
    });

    test('arranca igual al nativo, sin giro ni «++»', () {
      final e = _en(0);
      expect(e.giro, 0);
      expect(e.corrimiento, Offset.zero);
      expect(e.cruces, isEmpty);
    });

    test('la estrella gira 45° con el resorte a los 500 ms', () {
      expect(_en(500).giro, closeTo(45 * grado, 1.5 * grado));
      expect(_en(1150).giro, closeTo(45 * grado, 1e-9));
    });

    test('el latido saca los rombos 24 u y baja la estrella central a 95 % '
        'en el primer 32 %', () {
      final pico = _en(180 + 0.32 * 380);
      expect(pico.rombos.first.desplazamiento, closeTo(24, 1e-6));
      expect(pico.escalaCentral, closeTo(0.95, 1e-6));
      expect(_en(560).rombos.first.desplazamiento, closeTo(0, 1e-6));
    });

    test('la onda va de 250 u a 540 u entre 230 y 790 ms', () {
      final onda = _en(230).anillos.single;
      expect(onda.radio, closeTo(250, 1e-6));
      expect(onda.trazo, closeTo(13.5, 1e-6));
      expect(onda.opacidad, closeTo(0.42, 1e-6));
      expect(_en(790).anillos, isEmpty);
    });

    test('el primer «+» sale de detrás de la estrella, de x = 190 u a su '
        'lugar, y solo se ve a la derecha de x = 236 u hasta los 920 ms', () {
      final nace = _en(480).cruces.single;
      expect(nace.centro.dx, closeTo(190, 1e-6));
      expect(nace.escala, closeTo(0.72, 1e-6));
      expect(_en(600).recorteDeCruces, 236);
      final llega = _en(920).cruces.first;
      expect(llega.centro.dx, closeTo(LogoGeometria.centrosDeCruz[0].dx, 1e-6));
      expect(llega.escala, closeTo(1, 1e-6));
      expect(_en(920).recorteDeCruces, isNull);
    });

    test('el segundo «+» nace del primero y se corre 94 u, como i++', () {
      expect(_en(699).cruces, hasLength(1));
      final nace = _en(700).cruces[1];
      expect(nace.centro.dx, closeTo(LogoGeometria.centrosDeCruz[0].dx, 1e-6));
      expect(nace.escala, closeTo(0.8, 1e-6));
      final llega = _en(1120).cruces[1];
      expect(llega.centro.dx, closeTo(LogoGeometria.centrosDeCruz[1].dx, 1e-6));
      expect(
        LogoGeometria.centrosDeCruz[1].dx - LogoGeometria.centrosDeCruz[0].dx,
        closeTo(94, 0.5),
      );
    });

    test('todo el conjunto se corre −36 u entre 480 y 1060 ms', () {
      expect(_en(480).corrimiento, Offset.zero);
      expect(_en(1060).corrimiento.dx, closeTo(-36, 1e-6));
    });

    test('a los 1150 ms queda el logo completo, corrido y con sus «++»', () {
      final e = _en(1150);
      expect(e.corrimiento.dx, closeTo(-36, 1e-6));
      expect(e.rombos.every((r) => r.desplazamiento == 0), isTrue);
      for (var i = 0; i < 2; i++) {
        expect(e.cruces[i].centro, LogoGeometria.centrosDeCruz[i]);
        expect(e.cruces[i].escala, closeTo(1, 1e-6));
      }
      // La pose sigue al conjunto corrido (RF-SPL-21).
      expect(e.pose.centro.dx, closeTo(187.5 - 36 * 90 / 354.8, 1e-9));
    });
  });

  group('Incremento, los tics y el reposo (RF-SPL-10 y RF-SPL-21)', () {
    test('desde 1400 ms hay un tic de 45° cada 1300 ms', () {
      expect(_en(1399).giro, closeTo(45 * grado, 1e-9));
      expect(_en(2100).giro, closeTo(90 * grado, 0.5 * grado));
      expect(_en(2700).giro, closeTo(90 * grado, 0.1 * grado));
      expect(_en(3400).giro, closeTo(135 * grado, 0.5 * grado));
    });

    test('con cada tic los rombos laten 8 u y cada «+» asiente un 14 %', () {
      expect(_en(1400 + 210).rombos.first.desplazamiento, closeTo(8, 1e-6));
      expect(_en(1400 + 60 + 160).cruces[0].escala, closeTo(1.14, 1e-6));
      expect(_en(1400 + 170 + 160).cruces[1].escala, closeTo(1.14, 1e-6));
      expect(_en(1400 + 500).rombos.first.desplazamiento, closeTo(0, 1e-6));
    });

    test('con la carga lista antes de 1150 ms no hay tics', () {
      expect(_en(1700, cargaLista: 900).giro, closeTo(45 * grado, 1e-9));
      expect(_v.finDelReposo(900), 1150);
    });

    test('hacia la bienvenida termina el tic en curso, a lo sumo 700 ms '
        'desde su inicio', () {
      expect(_v.finDelReposo(1500), 2100);
      expect(_v.finDelReposo(2200), 2200);
      expect(_v.finDelReposo(1300), 1300);
      final reposo = _en(2100, cargaLista: 1500);
      expect(reposo.giro, closeTo(90 * grado, 1e-9));
      expect(reposo.rombos.every((r) => r.desplazamiento == 0), isTrue);
      // Ningún tic nuevo empieza después de la carga.
      expect(_en(2800, cargaLista: 1500).giro, closeTo(90 * grado, 1e-9));
    });

    test('la salida absorbe el tic en curso y termina 45° más allá de su '
        'destino', () {
      expect(_v.giroAlSalir(1500), greaterThan(45 * grado));
      expect(_v.giroAlSalir(1500), lessThan(90 * grado));
      expect(_v.destinoDelGiro(1500), closeTo(90 * grado, 1e-9));
      expect(_v.destinoDelGiro(1200), closeTo(45 * grado, 1e-9));
    });

    test('en la salida, el latido y el asentimiento se apagan en 150 ms', () {
      final inicio = _v.alSalir(1610, 0, centro: _centro, radio: 90);
      expect(inicio.rombos.first.desplazamiento, closeTo(8, 1e-6));
      final apagado = _v.alSalir(1610, 150, centro: _centro, radio: 90);
      expect(apagado.rombos.every((r) => r.desplazamiento == 0), isTrue);
      expect(apagado.cruces.every((c) => (c.escala - 1).abs() < 1e-9), isTrue);
    });
  });
}
```

- [ ] **Paso 2. Corre la prueba y confirma que falla.**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/splash/splash_incremento_test.dart
```

Esperado. Falla la compilación, porque `incremento.dart` no existe.

- [ ] **Paso 3. Escribe Incremento.** Crea `lib/pages/splash/variantes/incremento.dart`.

```dart
// lib/pages/splash/variantes/incremento.dart
// Variante B, «Incremento» (RF-SPL-8). La estrella gira 45° con un resorte,
// los rombos laten, sale una onda y los «++» nacen detrás de la estrella
// como `i++`, mientras el conjunto se corre −36 u para quedar centrado. La
// maqueta es docs/images/UI/splash/incremento.html.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';

import '../../../components/logo/escena_del_logo.dart';
import '../../../components/logo/logo_geometria.dart';
import '../../../services/splash_variante_service.dart';
import 'variante_de_intro.dart';

class Incremento extends VarianteDeIntro {
  const Incremento();

  static const double corrimientoFinal = -36; // u
  static const double bordeDeNacimiento = 236; // u
  static const double inicioDeTics = 1400;
  static const double periodoDeTic = 1300;

  /// La maqueta termina el tic a los 700 ms de su inicio (S-34).
  static const double finDelTic = 700;

  /// ω0 = 15,7 rad/s y ζ = 0,55.
  static final SpringSimulation _resorteDeEntrada = SpringSimulation(
    const SpringDescription(mass: 1, stiffness: 246.7, damping: 17.3),
    0,
    1,
    0,
  );

  static final SpringSimulation _resorteDeTic = SpringSimulation(
    const SpringDescription(mass: 1, stiffness: 158, damping: 18.1),
    0,
    1,
    0,
  );

  @override
  VarianteSplash get tipo => VarianteSplash.incremento;

  @override
  double get finDeLaEntrada => 1150;

  @override
  double get duracionDeLaSalida => 620;

  /// La curva enfatizada de Material (RF-SPL-11).
  @override
  Curve get curvaDeLaSalida => const Cubic(0.2, 0, 0, 1);

  /// El inicio del tic en curso en [ms], o null. Ningún tic empieza después
  /// de [cargaLista], y el que empezó antes sigue hasta su final.
  double? _inicioDelTic(double ms, double? cargaLista) {
    if (cargaLista != null && cargaLista <= finDeLaEntrada) return null;
    final hasta = cargaLista == null ? ms : math.min(ms, cargaLista);
    if (hasta < inicioDeTics) return null;
    final n = ((hasta - inicioDeTics) / periodoDeTic).floor();
    return inicioDeTics + periodoDeTic * n;
  }

  int _ticsPrevios(double inicio) =>
      ((inicio - inicioDeTics) / periodoDeTic).round();

  double _giro(double ms, double? cargaLista) {
    final entrada = ms >= finDeLaEntrada
        ? 1.0
        : _resorteDeEntrada.x(ms / 1000);
    var giro = 45 * grado * entrada;
    final inicio = _inicioDelTic(ms, cargaLista);
    if (inicio != null) {
      final avance = ms - inicio >= periodoDeTic
          ? 1.0
          : _resorteDeTic.x((ms - inicio) / 1000);
      giro += 45 * grado * (_ticsPrevios(inicio) + avance);
    }
    return giro;
  }

  /// El giro en reposo tras la carga en [cargaLista], que es el destino del
  /// último tic.
  double _giroDeReposo(double cargaLista) => destinoDelGiro(cargaLista);

  double _latidoDeEntrada(double ms) {
    if (ms < 180 || ms > 560) return 0;
    final p = tramo(ms, 180, 560);
    return p < 0.32
        ? Curves.easeOutCubic.transform(p / 0.32)
        : 1 - Curves.easeInOutCubic.transform((p - 0.32) / 0.68);
  }

  double _asiente(int i, double ms, double? inicio) {
    if (inicio == null) return 1;
    final s = inicio + (i == 0 ? 60 : 170);
    return 1 + 0.14 * medioSeno(tramo(ms, s, s + 320));
  }

  List<CruzEnEscena> _crucesDeEntrada(double ms) {
    final destino0 = LogoGeometria.centrosDeCruz[0];
    final destino1 = LogoGeometria.centrosDeCruz[1];
    return <CruzEnEscena>[
      if (ms >= 480)
        () {
          final r = conRebote(tramo(ms, 480, 920), 1.6);
          return CruzEnEscena(
            centro: Offset(mezcla(190, destino0.dx, r), destino0.dy),
            escala: mezcla(0.72, 1, r),
          );
        }(),
      if (ms >= 700)
        () {
          final r = conRebote(tramo(ms, 700, 1120), 1.5);
          return CruzEnEscena(
            centro: Offset(mezcla(destino0.dx, destino1.dx, r), destino1.dy),
            escala: mezcla(0.8, 1, r),
          );
        }(),
    ];
  }

  List<AnilloEnEscena> _onda(double ms) {
    if (ms < 230 || ms >= 790) return const <AnilloEnEscena>[];
    final e = Curves.easeOutCubic.transform(tramo(ms, 230, 790));
    return <AnilloEnEscena>[
      AnilloEnEscena(
        centro: Offset.zero,
        radio: mezcla(250, 540, e),
        trazo: mezcla(13.5, 1.5, e),
        opacidad: mezcla(0.42, 0, e),
      ),
    ];
  }

  Offset _corrimiento(double ms) => Offset(
    corrimientoFinal *
        Curves.easeInOutCubic.transform(tramo(ms, 480, 1060)),
    0,
  );

  EscenaDelLogo _reposo(Offset centro, double radio, double giro) =>
      EscenaDelLogo(
        centro: centro,
        radio: radio,
        corrimiento: const Offset(corrimientoFinal, 0),
        giro: giro,
        cruces: EscenaDelLogo.crucesEnReposo(),
      );

  @override
  EscenaDelLogo escena(
    double ms, {
    required Offset centro,
    required double radio,
    double? cargaLista,
  }) {
    if (cargaLista != null &&
        ms >= finDeLaEntrada &&
        ms >= finDelReposo(cargaLista)) {
      return _reposo(centro, radio, _giroDeReposo(cargaLista));
    }
    final enEntrada = ms < finDeLaEntrada;
    final inicio = enEntrada ? null : _inicioDelTic(ms, cargaLista);
    final latidoDeEntrada = enEntrada ? _latidoDeEntrada(ms) : 0.0;
    final latido = enEntrada
        ? 24 * latidoDeEntrada
        : (inicio == null ? 0.0 : 8 * medioSeno(tramo(ms, inicio, inicio + 420)));
    return EscenaDelLogo(
      centro: centro,
      radio: radio,
      corrimiento: _corrimiento(ms),
      giro: _giro(ms, cargaLista),
      escalaCentral: 1 - 0.05 * latidoDeEntrada,
      rombos: latido == 0
          ? EscenaDelLogo.rombosEnReposo
          : List<RomboEnEscena>.filled(
              8,
              RomboEnEscena(desplazamiento: latido),
            ),
      cruces: enEntrada
          ? _crucesDeEntrada(ms)
          : <CruzEnEscena>[
              for (var i = 0; i < 2; i++)
                CruzEnEscena(
                  centro: LogoGeometria.centrosDeCruz[i],
                  escala: _asiente(i, ms, inicio),
                ),
            ],
      anillos: _onda(ms),
      recorteDeCruces: ms < 920 ? bordeDeNacimiento : null,
    );
  }

  @override
  double finDelReposo(double? cargaLista) {
    if (cargaLista == null || cargaLista <= finDeLaEntrada) {
      return finDeLaEntrada;
    }
    final inicio = _inicioDelTic(cargaLista, cargaLista);
    if (inicio == null) return cargaLista;
    return math.max(cargaLista, inicio + finDelTic);
  }

  @override
  double giroAlSalir(double msInicio) => _giro(msInicio, msInicio);

  @override
  double destinoDelGiro(double msInicio) {
    final inicio = _inicioDelTic(msInicio, msInicio);
    final tics = inicio == null ? 0 : _ticsPrevios(inicio) + 1;
    return 45 * grado * (1 + tics);
  }

  @override
  EscenaDelLogo alSalir(
    double msInicio,
    double msEnSalida, {
    required Offset centro,
    required double radio,
  }) {
    final e = escena(
      msInicio + msEnSalida,
      centro: centro,
      radio: radio,
      cargaLista: msInicio,
    );
    final f = 1 - tramo(msEnSalida, 0, 150);
    return EscenaDelLogo(
      centro: centro,
      radio: radio,
      corrimiento: e.corrimiento,
      rombos: <RomboEnEscena>[
        for (final r in e.rombos)
          RomboEnEscena(desplazamiento: r.desplazamiento * f),
      ],
      cruces: <CruzEnEscena>[
        for (final c in e.cruces) c.copyWith(escala: 1 + (c.escala - 1) * f),
      ],
    );
  }
}
```

- [ ] **Paso 4. Corre la prueba y confirma que pasa.**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/pages/splash/variantes/incremento.dart test/splash/splash_incremento_test.dart
"${FLUTTER:?}" test --no-pub test/splash/splash_incremento_test.dart
"${FLUTTER:?}" analyze --no-pub
```

Esperado. `All tests passed!` con las quince pruebas y `6 issues found.`.

- [ ] **Paso 5. Commit.**

```bash
cd "${REPO:?}"
git status --short
git add lib/pages/splash/variantes/incremento.dart test/splash/splash_incremento_test.dart
git commit -m "feat(splash): Incremento gira la estrella con un resorte y hace nacer los «++» como i++, con tics de espera que la salida absorbe (RF-SPL-8 y RF-SPL-10)"
git log -1 --format='%an <%ae>'
```

---

### Tarea 9. Código y el registro de las variantes

**Requisitos.** RF-SPL-9 completo (decisión S-15), el bucle C de RF-SPL-10 y la vuelta al reposo
de Código de RF-SPL-21 (decisiones S-34 y 11 del plan).

**Archivos.**
- Crear `lib/pages/splash/variantes/codigo.dart`.
- Crear `lib/pages/splash/variantes/variantes.dart`.
- Crear `test/splash/splash_codigo_test.dart`.

**Interfaces.**
- Consume la base y las curvas de la Tarea 7 y `TextoDeCodigo` y `CursorEnEscena` de la Tarea 2.
- Produce `class Codigo extends VarianteDeIntro { const Codigo(); }` y, en `variantes.dart`,
  `VarianteDeIntro varianteDe(VarianteSplash tipo)`, que usa la Tarea 13.

- [ ] **Paso 1. Escribe la prueba que falla.** Crea `test/splash/splash_codigo_test.dart`.

```dart
// test/splash/splash_codigo_test.dart
//
// UNITARIA · Splash animado (specs/features/splash/splash.spec.md).
// RF-SPL-9 fija la entrada de Código, RF-SPL-10 su cursor de espera y
// RF-SPL-21 su vuelta al reposo. La estrella mide R = 90 dp y las medidas de
// la maqueta, hecha con 86 dp, se escalan con R.
// Archivo probado lib/pages/splash/variantes/codigo.dart.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/components/logo/escena_del_logo.dart';
import 'package:ulima_plus/components/logo/logo_geometria.dart';
import 'package:ulima_plus/pages/splash/variantes/codigo.dart';
import 'package:ulima_plus/pages/splash/variantes/ensamble.dart';
import 'package:ulima_plus/pages/splash/variantes/incremento.dart';
import 'package:ulima_plus/pages/splash/variantes/variante_de_intro.dart';
import 'package:ulima_plus/pages/splash/variantes/variantes.dart';
import 'package:ulima_plus/services/splash_variante_service.dart';

const _centro = Offset(187.5, 333.5);
const _v = Codigo();
const _r = 354.8;

EscenaDelLogo _en(double ms, {double? cargaLista}) =>
    _v.escena(ms, centro: _centro, radio: 90, cargaLista: cargaLista);

void main() {
  group('Código, la entrada (RF-SPL-9)', () {
    test('es la variante codigo, entra en 1330 ms y sale en 420 ms', () {
      expect(_v.tipo, VarianteSplash.codigo);
      expect(_v.finDeLaEntrada, 1330);
      expect(_v.duracionDeLaSalida, 420);
      expect(_v.finDeLaEntrada + _v.duracionDeLaSalida, 1750);
    });

    test('la estrella sube 0,66 R y se achica a 0,82 R en 320 ms', () {
      expect(_en(0).desplazamientoDeEstrella, Offset.zero);
      final arriba = _en(320);
      expect(arriba.desplazamientoDeEstrella.dy, closeTo(-0.66 * _r, 1e-6));
      expect(arriba.escalaDeEstrella, closeTo(0.82, 1e-6));
    });

    test('«ULima» se teclea a los 250, 318, 386, 454 y 522 ms', () {
      expect(_en(249).texto, isNull);
      expect(_en(250).texto!.visibles, 1);
      expect(_en(453).texto!.visibles, 3);
      expect(_en(522).texto!.visibles, 5);
    });

    test('el cursor aparece de 160 a 240 ms, avanza con cada letra y cada «+» '
        'y retrocede dos a los 780 ms', () {
      expect(_en(160).cursor!.opacidad, closeTo(0, 1e-6));
      expect(_en(240).cursor!.opacidad, closeTo(1, 1e-6));
      double x(double ms) => _en(ms).cursor!.centro.dx;
      expect(x(240), closeTo(TextoDeCodigo.bordeDeCelda(0), 1e-6));
      expect(x(700), closeTo(TextoDeCodigo.bordeDeCelda(7), 1e-6));
      expect(x(780), closeTo(TextoDeCodigo.bordeDeCelda(5), 1e-6));
      expect(_en(960).cursor, isNull);
    });

    test('cada «+» tecleado aparece en #FFE7A3 con un rebote de 0,55 a 1 en '
        '110 ms', () {
      final nace = _en(610).cruces.single;
      expect(nace.color, const Color(0xFFFFE7A3));
      expect(nace.escala, closeTo(0.55 * Codigo.escalaTecleada, 1e-6));
      expect(nace.centro, TextoDeCodigo.centroDeCelda(5));
      expect(_en(720).cruces[0].escala, closeTo(Codigo.escalaTecleada, 1e-6));
      expect(_en(680).cruces, hasLength(2));
    });

    test('cada «+» vuela a su lugar, gira 90°, se engruesa y pasa a blanco', () {
      final llega = _en(1160).cruces[0];
      expect(llega.centro, LogoGeometria.centrosDeCruz[0]);
      expect(llega.giro, closeTo(90 * grado, 1e-6));
      expect(llega.grosor, closeTo(1, 1e-6));
      expect(llega.color, const Color(0xFFFFFFFF));
      expect(llega.escala, closeTo(1, 1e-6));
      final segundo = _en(1210).cruces[1];
      expect(segundo.centro, LogoGeometria.centrosDeCruz[1]);
      // Cada uno sube en arco sobre los dos extremos.
      final medio = _en(970).cruces[0];
      expect(medio.centro.dy, lessThan(LogoGeometria.centrosDeCruz[0].dy));
    });

    test('al aterrizar cada «+» rebota 12 % durante 150 ms', () {
      expect(_en(1160 + 75).cruces[0].escala, closeTo(1.12, 1e-6));
      expect(_en(1310).cruces[0].escala, closeTo(1, 1e-6));
    });

    test('el segundo «+» rebota de 1180 a 1330 ms, cuando ya está a menos de '
        '1 dp de su lugar, y termina con la entrada (decisión 11 del plan)',
        () {
      final llegando = _en(1180).cruces[1];
      // Un dp en u, con R = 90 dp.
      const unDp = _r / 90;
      expect(
        (llegando.centro - LogoGeometria.centrosDeCruz[1]).distance,
        lessThan(unDp),
      );
      expect(_en(1180 + 75).cruces[1].escala, closeTo(1.12, 1e-6));
      expect(_en(1330).cruces[1].escala, closeTo(1, 1e-6));
    });

    test('el texto baja 0,12 R y se desvanece entre 790 y 960 ms', () {
      expect(_en(790).texto!.opacidad, closeTo(1, 1e-6));
      final cayendo = _en(959).texto!;
      expect(cayendo.opacidad, lessThan(0.05));
      expect(cayendo.dy, closeTo(0.12 * _r, 0.01 * _r));
    });

    test('la estrella vuelve al centro y a R entre 820 y 1210 ms, y late '
        '3,5 % hasta los 1330 ms', () {
      final vuelta = _en(1210);
      expect(vuelta.desplazamientoDeEstrella.dy, closeTo(0, 1e-6));
      expect(vuelta.escalaDeEstrella, closeTo(1, 1e-6));
      expect(_en(1270).escalaDeEstrella, closeTo(1.035, 1e-6));
    });

    test('un anillo sale de 1,02 R a 1,5 R entre 1190 y 1410 ms', () {
      final anillo = _en(1190).anillos.single;
      expect(anillo.radio, closeTo(1.02 * _r, 1e-6));
      expect(anillo.opacidad, closeTo(0.38, 1e-6));
      expect(_en(1409).anillos, hasLength(1));
      expect(_en(1410).anillos, isEmpty);
    });

    test('a los 1330 ms el logo está completo, sin texto ni cursor', () {
      final e = _en(1330);
      expect(e.texto, isNull);
      expect(e.cursor, isNull);
      expect(e.desplazamientoDeEstrella, Offset.zero);
      expect(e.escalaDeEstrella, closeTo(1, 1e-6));
      for (var i = 0; i < 2; i++) {
        expect(e.cruces[i].centro, LogoGeometria.centrosDeCruz[i]);
        expect(e.cruces[i].escala, closeTo(1, 1e-6), reason: 'quieto');
      }
    });
  });

  group('Código, la espera y el reposo (RF-SPL-10 y RF-SPL-21)', () {
    test('si la carga sigue, un cursor parpadea a la derecha de los «++», '
        'entra en 200 ms y sigue un coseno de 1060 ms', () {
      expect(_en(1330).cursor, isNull);
      final lleno = _en(1530).cursor!;
      expect(lleno.opacidad, closeTo(1, 1e-6));
      expect(lleno.centro.dx, greaterThan(LogoGeometria.centrosDeCruz[1].dx));
      expect(_en(1530 + 530).cursor, isNull);
      expect(_en(1530 + 1060).cursor!.opacidad, closeTo(1, 1e-6));
    });

    test('con la carga lista, el cursor se apaga en 120 ms', () {
      expect(_v.finDelReposo(1600), 1720);
      expect(_en(1720, cargaLista: 1600).cursor, isNull);
      final saliendo = _v.alSalir(1530, 60, centro: _centro, radio: 90);
      expect(saliendo.cursor!.opacidad, closeTo(0.5, 1e-6));
      expect(_v.alSalir(1530, 120, centro: _centro, radio: 90).cursor, isNull);
    });

    test('hacia la bienvenida el relevo es a los 1330 ms, con los dos «+» '
        'quietos (RF-SPL-17, RF-SPL-21 y decisión 11 del plan)', () {
      expect(_v.finDelReposo(null), 1330);
      expect(_v.finDelReposo(900), 1330);
      final quieto = _en(1330, cargaLista: 900);
      for (var i = 0; i < 2; i++) {
        expect(quieto.cruces[i].escala, closeTo(1, 1e-6));
      }
    });
  });

  test('varianteDe da la variante de cada tipo', () {
    expect(varianteDe(VarianteSplash.ensamble), isA<Ensamble>());
    expect(varianteDe(VarianteSplash.incremento), isA<Incremento>());
    expect(varianteDe(VarianteSplash.codigo), isA<Codigo>());
  });
}
```

- [ ] **Paso 2. Corre la prueba y confirma que falla.**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/splash/splash_codigo_test.dart
```

Esperado. Falla la compilación, porque `codigo.dart` y `variantes.dart` no existen.

- [ ] **Paso 3. Escribe Código.** Crea `lib/pages/splash/variantes/codigo.dart`.

```dart
// lib/pages/splash/variantes/codigo.dart
// Variante C, «Código» (RF-SPL-9). La estrella sube y se achica, se teclea
// «ULima» en la letra monoespaciada del sistema (S-15), los «++» saltan en
// arco a su lugar junto a la estrella y la estrella vuelve al centro. La
// maqueta es docs/images/UI/splash/codigo.html, hecha con R = 86 dp, así que
// sus medidas van en R.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/animation.dart';

import '../../../components/logo/escena_del_logo.dart';
import '../../../components/logo/logo_geometria.dart';
import '../../../services/splash_variante_service.dart';
import 'variante_de_intro.dart';

class Codigo extends VarianteDeIntro {
  const Codigo();

  static const List<double> tecleos = <double>[250, 318, 386, 454, 522];
  static const List<double> tecleoDeCruces = <double>[610, 680];
  static const List<double> inicioDeVuelo = <double>[780, 830];
  static const double duracionDeVuelo = 380;
  static const Color amarillo = Color(0xFFFFE7A3);

  /// El «+» tecleado mide 0,83 de la cruz del logo y tiene el 87 % de su
  /// grosor, como en la maqueta (decisión 4 del plan).
  static const double escalaTecleada = 0.83;
  static const double grosorTecleado = 0.87;

  /// Cuándo empieza el rebote de 150 ms de cada «+». El primero rebota al
  /// llegar, a los 1160 ms. El segundo empieza 30 ms antes del fin de su
  /// vuelo, cuando ya cubre el 99,5 % de su curva y está a menos de 1 dp de
  /// su lugar, así que termina a los 1330 ms, con la entrada (decisión 11 del
  /// plan).
  static const List<double> inicioDelRebote = <double>[1160, 1180];

  static const double _r = LogoGeometria.radioNominal;

  /// A la derecha de los «++», donde parpadea el cursor de espera.
  static const Offset _cursorDeEspera = Offset(402.5 + 36.4 + 24, -133.8);

  @override
  VarianteSplash get tipo => VarianteSplash.codigo;

  @override
  double get finDeLaEntrada => 1330;

  @override
  double get duracionDeLaSalida => 420;

  @override
  Curve get curvaDeLaSalida => Curves.easeInOutCubic;

  double _subida(double ms) => Curves.easeOutCubic.transform(tramo(ms, 0, 320));

  double _vuelta(double ms) =>
      Curves.easeInOutCubic.transform(tramo(ms, 820, 1210));

  Offset _desplazamiento(double ms) =>
      Offset(0, -0.66 * _r * _subida(ms) * (1 - _vuelta(ms)));

  double _escala(double ms) {
    final base = mezcla(mezcla(1, 0.82, _subida(ms)), 1, _vuelta(ms));
    return base * (1 + 0.035 * medioSeno(tramo(ms, 1210, 1330)));
  }

  int _letras(double ms) => tecleos.where((t) => ms >= t).length;

  int _celdaDelCursor(double ms) => ms >= 780
      ? 5
      : _letras(ms) + tecleoDeCruces.where((t) => ms >= t).length;

  double _caida(double ms) =>
      0.12 * _r * Curves.easeInOutCubic.transform(tramo(ms, 790, 960));

  CursorEnEscena? _cursorDeTecleo(double ms) {
    if (ms < 160 || ms >= 960) return null;
    final opacidad = ms < 790 ? tramo(ms, 160, 240) : 1 - tramo(ms, 790, 960);
    return CursorEnEscena(
      centro: Offset(
        TextoDeCodigo.bordeDeCelda(_celdaDelCursor(ms)),
        TextoDeCodigo.centroDeCelda(0).dy + _caida(ms),
      ),
      alto: 1.05 * TextoDeCodigo.tamanoEnU,
      opacidad: opacidad,
    );
  }

  TextoDeCodigo? _texto(double ms) => ms < 250 || ms >= 960
      ? null
      : TextoDeCodigo(
          visibles: _letras(ms),
          opacidad: 1 - tramo(ms, 790, 960),
          dy: _caida(ms),
        );

  double _rebote(int i, double ms) {
    final a = inicioDelRebote[i];
    return 1 + 0.12 * medioSeno(tramo(ms, a, a + 150));
  }

  CruzEnEscena? _cruz(int i, double ms) {
    final aparece = tecleoDeCruces[i];
    if (ms < aparece) return null;
    final origen = TextoDeCodigo.centroDeCelda(5 + i);
    final destino = LogoGeometria.centrosDeCruz[i];
    final despega = inicioDeVuelo[i];
    if (ms < despega) {
      final t = tramo(ms, aparece, aparece + 110);
      return CruzEnEscena(
        centro: origen,
        escala: escalaTecleada * mezcla(0.55, 1, conRebote(t, 1.70158)),
        grosor: grosorTecleado,
        color: amarillo,
      );
    }
    final t = Curves.easeInOutCubic.transform(
      tramo(ms, despega, despega + duracionDeVuelo),
    );
    final control = Offset(
      destino.dx + 0.38 * _r,
      math.min(origen.dy, destino.dy) - 0.91 * _r,
    );
    return CruzEnEscena(
      centro: bezierCuadratica(origen, control, destino, t),
      escala: mezcla(escalaTecleada, 1, t) * _rebote(i, ms),
      giro: 90 * grado * t,
      grosor: mezcla(grosorTecleado, 1, t),
      color: Color.lerp(amarillo, const Color(0xFFFFFFFF), t)!,
    );
  }

  List<AnilloEnEscena> _anillos(double ms) {
    if (ms < 1190 || ms >= 1410) return const <AnilloEnEscena>[];
    final e = Curves.easeOutCubic.transform(tramo(ms, 1190, 1410));
    return <AnilloEnEscena>[
      AnilloEnEscena(
        centro: Offset.zero,
        radio: mezcla(1.02 * _r, 1.5 * _r, e),
        trazo: mezcla(10, 2, e),
        opacidad: mezcla(0.38, 0, e),
      ),
    ];
  }

  double _opacidadDeEspera(double ms) {
    final fin = finDeLaEntrada;
    if (ms < fin) return 0;
    if (ms < fin + 200) return tramo(ms, fin, fin + 200);
    return 0.5 + 0.5 * math.cos(2 * math.pi * (ms - fin - 200) / 1060);
  }

  CursorEnEscena? _cursorEnEspera(double ms, double? cargaLista) {
    if (ms < finDeLaEntrada) return null;
    if (cargaLista != null && cargaLista <= finDeLaEntrada) return null;
    var opacidad = _opacidadDeEspera(ms);
    if (cargaLista != null && ms > cargaLista) {
      opacidad =
          _opacidadDeEspera(cargaLista) *
          (1 - tramo(ms, cargaLista, cargaLista + 120));
    }
    if (opacidad <= 1e-9) return null;
    return CursorEnEscena(
      centro: _cursorDeEspera,
      alto: 1.2 * LogoGeometria.largoDeCruz,
      opacidad: opacidad,
    );
  }

  List<CruzEnEscena> _crucesEnReposo(double ms) => <CruzEnEscena>[
    for (var i = 0; i < 2; i++)
      CruzEnEscena(
        centro: LogoGeometria.centrosDeCruz[i],
        escala: _rebote(i, ms),
      ),
  ];

  @override
  EscenaDelLogo escena(
    double ms, {
    required Offset centro,
    required double radio,
    double? cargaLista,
  }) {
    if (ms >= finDeLaEntrada) {
      return EscenaDelLogo(
        centro: centro,
        radio: radio,
        cruces: _crucesEnReposo(ms),
        anillos: _anillos(ms),
        cursor: _cursorEnEspera(ms, cargaLista),
      );
    }
    return EscenaDelLogo(
      centro: centro,
      radio: radio,
      desplazamientoDeEstrella: _desplazamiento(ms),
      escalaDeEstrella: _escala(ms),
      cruces: <CruzEnEscena>[for (var i = 0; i < 2; i++) ?_cruz(i, ms)],
      anillos: _anillos(ms),
      texto: _texto(ms),
      cursor: _cursorDeTecleo(ms),
    );
  }

  /// El logo queda quieto con la entrada, y desde el bucle cuando el cursor
  /// se apaga en 120 ms (RF-SPL-21 y S-34).
  @override
  double finDelReposo(double? cargaLista) {
    if (cargaLista == null || cargaLista <= finDeLaEntrada) return finDeLaEntrada;
    return cargaLista + 120;
  }

  @override
  EscenaDelLogo alSalir(
    double msInicio,
    double msEnSalida, {
    required Offset centro,
    required double radio,
  }) {
    final ms = msInicio + msEnSalida;
    final cursor = _cursorEnEspera(msInicio, null);
    final f = 1 - tramo(msEnSalida, 0, 120);
    return EscenaDelLogo(
      centro: centro,
      radio: radio,
      cruces: _crucesEnReposo(ms),
      // El anillo sigue en el centro de la pantalla mientras la estrella
      // vuela, y se apaga a los 1410 ms (RF-SPL-9).
      anillos: _anillos(ms),
      cursor: cursor == null || f <= 0
          ? null
          : CursorEnEscena(
              centro: cursor.centro,
              alto: cursor.alto,
              opacidad: cursor.opacidad * f,
            ),
    );
  }
}
```

- [ ] **Paso 4. Escribe el registro de las variantes.** Crea
  `lib/pages/splash/variantes/variantes.dart`.

```dart
// lib/pages/splash/variantes/variantes.dart
// La variante de cada tipo (RF-SPL-6).

import '../../../services/splash_variante_service.dart';
import 'codigo.dart';
import 'ensamble.dart';
import 'incremento.dart';
import 'variante_de_intro.dart';

export 'variante_de_intro.dart';

VarianteDeIntro varianteDe(VarianteSplash tipo) => switch (tipo) {
  VarianteSplash.ensamble => const Ensamble(),
  VarianteSplash.incremento => const Incremento(),
  VarianteSplash.codigo => const Codigo(),
};
```

- [ ] **Paso 5. Corre las pruebas y confirma que pasan.**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/pages/splash/variantes test/splash/splash_codigo_test.dart
"${FLUTTER:?}" test --no-pub test/splash/splash_codigo_test.dart test/splash/splash_ensamble_test.dart test/splash/splash_incremento_test.dart
"${FLUTTER:?}" analyze --no-pub
```

Esperado. `All tests passed!` en los tres archivos y `6 issues found.`. El informe anota la
decisión 11 del plan, el rebote del segundo «+» de 1180 a 1330 ms, para que el dueño la vea en la
revisión manual.

- [ ] **Paso 6. Commit.**

```bash
cd "${REPO:?}"
git status --short
git add lib/pages/splash/variantes/codigo.dart lib/pages/splash/variantes/variantes.dart test/splash/splash_codigo_test.dart
git commit -m "feat(splash): Código teclea «ULima» y hace saltar los «++» a su lugar junto a la estrella, con el cursor de espera (RF-SPL-9 y RF-SPL-10)"
git log -1 --format='%an <%ae>'
```

---

### Tarea 10. Las salidas hacia `/home`

**Requisitos.** RF-SPL-11 completo y RF-SPL-13 (decisiones S-2 y S-11), salvo lo que depende de
montar la capa, que es de la Tarea 13.

**Archivos.**
- Crear `lib/pages/splash/salidas.dart`.
- Crear `test/splash/splash_salida_test.dart` (grupo `las salidas como funciones puras`).

**Interfaces.**
- Consume las variantes de las Tareas 7 a 9, `EscenaDelLogo`, `PoseDelLogo` y `pintarEscena`
  (Tarea 2) y `MedidaDeCabecera` (Tarea 5).
- Produce estas firmas, que usan las Tareas 13 y 30.

```dart
const Color naranjaDelSplash = Color(0xFFE77330);
class DestinoDeLaSalida {
  factory DestinoDeLaSalida.desdeMedida(MedidaDeCabecera medida, Size pantalla);
  final Size pantalla; final Rect cabecera; final Rect estrella; final Rect texto;
  final List<double> anchosDeUlima; // del prefijo de 0 a 5 letras
  final List<Offset> cruces; final double tamanoDeCruz;
  final Color color; final Color colorDelBorde;
  final TextPainter pintorDeUlima; final TextPainter pintorDeLosMas; }
class CruzDeSalida { const CruzDeSalida({required Offset centro, required double largo,
  required double giro}); }
class EscenaDeSalida {
  final Rect panel; final Color colorDelPanel; final double combado; final double radioInferior;
  final double opacidadDelConjunto; final EscenaDelLogo estrella; final EscenaDelLogo restos;
  final List<CruzDeSalida> cruces; final double opacidadDeLasCruces;
  final double opacidadDeLosMas; final double reveladoDeUlima; final double opacidadDeUlima;
  final int letrasDeUlima; final double paginaDy; final double paginaOpacidad; }
EscenaDeSalida salidaHaciaHome({required VarianteDeIntro variante, required double msInicio,
  required double msEnSalida, required Offset centroDelMarco, required double radioDelMarco,
  required DestinoDeLaSalida destino});
void pintarSalida(Canvas canvas, EscenaDeSalida escena, DestinoDeLaSalida destino);
```

- [ ] **Paso 1. Escribe la prueba que falla.** Crea `test/splash/splash_salida_test.dart`. La
  Tarea 13 le suma el grupo de la capa.

```dart
// test/splash/splash_salida_test.dart
//
// UNITARIA + WIDGET · Splash animado (specs/features/splash/splash.spec.md).
// RF-SPL-11 fija la salida hacia /home de cada variante, con el panel que se
// recoge hasta la cabecera, la estrella que vuela a la estrella de la
// cabecera y los «++» que terminan sobre los del texto, y RF-SPL-13 el color
// del panel en cada tema.
// Archivos probados lib/pages/splash/salidas.dart y, desde la Tarea 13,
// lib/pages/splash/capa_de_arranque.dart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/pages/splash/puntos_de_aterrizaje.dart';
import 'package:ulima_plus/pages/splash/salidas.dart';
import 'package:ulima_plus/pages/splash/variantes/codigo.dart';
import 'package:ulima_plus/pages/splash/variantes/ensamble.dart';
import 'package:ulima_plus/pages/splash/variantes/incremento.dart';
import 'package:ulima_plus/pages/splash/variantes/variante_de_intro.dart';

const _pantalla = Size(375, 667);
const _centro = Offset(187.5, 333.5);

/// Una cabecera como la de la app en 375 × 667, medida a mano.
MedidaDeCabecera _medida({Color color = MaterialTheme.primaryColor}) =>
    MedidaDeCabecera(
      cabecera: const Rect.fromLTWH(0, 0, 375, 102),
      estrella: const Rect.fromLTWH(20, 52, 26, 26),
      texto: const Rect.fromLTWH(56, 55, 90, 20),
      estilo: const TextStyle(
        fontSize: 20,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      escalaDeTexto: TextScaler.noScaling,
      color: color,
      colorDelBorde: const Color(0xFF333333),
    );

EscenaDeSalida _salida(
  VarianteDeIntro v,
  double msEnSalida, {
  double? msInicio,
  MedidaDeCabecera? medida,
}) => salidaHaciaHome(
  variante: v,
  msInicio: msInicio ?? v.finDeLaEntrada,
  msEnSalida: msEnSalida,
  centroDelMarco: _centro,
  radioDelMarco: 90,
  destino: DestinoDeLaSalida.desdeMedida(medida ?? _medida(), _pantalla),
);

void main() {
  group('las salidas como funciones puras (RF-SPL-11)', () {
    final variantes = <VarianteDeIntro>[
      const Ensamble(),
      const Incremento(),
      const Codigo(),
    ];

    test('el destino ubica «ULIMA» y los dos «+» del texto de la cabecera', () {
      final d = DestinoDeLaSalida.desdeMedida(_medida(), _pantalla);
      expect(d.anchosDeUlima, hasLength(6));
      expect(d.anchosDeUlima.first, 0);
      expect(d.cruces, hasLength(2));
      expect(d.cruces[0].dx, greaterThan(56 + d.anchosDeUlima.last - 1));
      expect(d.cruces[1].dx, greaterThan(d.cruces[0].dx));
      expect(d.tamanoDeCruz, greaterThan(0));
    });

    for (final v in variantes) {
      group('${v.tipo.name}', () {
        test('empieza con el panel en toda la pantalla y la estrella en su '
            'pose', () {
          final s = _salida(v, 0);
          expect(s.panel, Offset.zero & _pantalla);
          expect(s.colorDelPanel, naranjaDelSplash);
          final pose = v
              .escena(v.finDeLaEntrada, centro: _centro, radio: 90)
              .pose;
          expect(s.estrella.centro.dx, closeTo(pose.centro.dx, 1e-6));
          expect(s.estrella.centro.dy, closeTo(pose.centro.dy, 1e-6));
          expect(s.estrella.radio, closeTo(90, 1e-6));
          expect(s.paginaOpacidad, 0);
          expect(s.opacidadDelConjunto, 1);
        });

        test('termina con el panel en la cabecera, la estrella de 26 dp en la '
            'de la cabecera y los «++» sobre el texto', () {
          final s = _salida(v, v.duracionDeLaSalida);
          expect(s.panel, const Rect.fromLTRB(0, 0, 375, 102));
          expect(s.colorDelPanel, MaterialTheme.primaryColor);
          expect(s.estrella.centro, const Offset(33, 65));
          expect(s.estrella.radio, closeTo(13, 1e-6));
          final d = DestinoDeLaSalida.desdeMedida(_medida(), _pantalla);
          for (var i = 0; i < 2; i++) {
            expect(s.cruces[i].centro.dx, closeTo(d.cruces[i].dx, 1e-6));
            expect(s.cruces[i].centro.dy, closeTo(d.cruces[i].dy, 1e-6));
          }
          expect(s.opacidadDeLasCruces, 0);
          expect(s.opacidadDeLosMas, 1);
          expect(s.paginaDy, 0);
          expect(s.paginaOpacidad, 1);
          expect(s.opacidadDelConjunto, 0);
        });

        test('los «++» dibujados se funden con los del texto en el último '
            '25 %', () {
          expect(
            _salida(v, 0.75 * v.duracionDeLaSalida).opacidadDeLosMas,
            closeTo(0, 1e-9),
          );
          expect(
            _salida(v, 0.875 * v.duracionDeLaSalida).opacidadDeLosMas,
            closeTo(0.5, 1e-6),
          );
        });

        test('el panel se funde sobre la cabecera en los últimos 100 ms', () {
          final d = v.duracionDeLaSalida;
          expect(_salida(v, d - 100).opacidadDelConjunto, 1);
          expect(_salida(v, d - 50).opacidadDelConjunto, closeTo(0.5, 1e-6));
        });

        test('en oscuro el panel termina en el headerColor oscuro', () {
          final oscuro = MaterialTheme.headerColor(Brightness.dark);
          final s = _salida(v, v.duracionDeLaSalida, medida: _medida(color: oscuro));
          expect(s.colorDelPanel, oscuro);
        });
      });
    }

    test('A. el borde del panel se abomba unos 130 dp a mitad de la salida, '
        '«ULIMA» se revela desde el 68 % y el segundo «+» va un 4 % después',
        () {
      const v = Ensamble();
      expect(_salida(v, 265).combado, closeTo(130, 1e-6));
      expect(_salida(v, 0.68 * 530).reveladoDeUlima, closeTo(0, 1e-9));
      expect(_salida(v, 0.84 * 530).reveladoDeUlima, closeTo(0.5, 1e-6));
      final s = _salida(v, 0.5 * 530);
      final d = DestinoDeLaSalida.desdeMedida(_medida(), _pantalla);
      final avance0 = (s.cruces[0].centro - d.cruces[0]).distance;
      final avance1 = (s.cruces[1].centro - d.cruces[1]).distance;
      expect(avance1, greaterThan(avance0 - 1));
      expect(_salida(v, 530).cruces[0].giro, closeTo(-12 * grado, 1e-6));
      expect(_salida(v, 0.5 * 530).paginaDy, closeTo(10, 1e-6));
    });

    test('B. las esquinas llegan a 75 dp, la estrella gira otros 45° más lo '
        'que falte del tic y los «++» se sueltan a los 150 ms', () {
      const v = Incremento();
      expect(_salida(v, 310).radioInferior, closeTo(75, 1e-6));
      // Sin tic en curso, gira de 45° a 90°.
      expect(_salida(v, 0).estrella.giro, closeTo(45 * grado, 1e-9));
      expect(_salida(v, 620).estrella.giro, closeTo(90 * grado, 1e-9));
      // A mitad de un tic, termina 45° más allá de su destino.
      expect(
        _salida(v, 620, msInicio: 1500).estrella.giro,
        closeTo(135 * grado, 1e-9),
      );
      // Pegados a la estrella hasta los 150 ms.
      final pegados = _salida(v, 100);
      final rel0 = pegados.cruces[0].centro - pegados.estrella.centro;
      final rel1 = pegados.cruces[1].centro - pegados.estrella.centro;
      final inicial = _salida(v, 0);
      final relInicial = inicial.cruces[0].centro - inicial.estrella.centro;
      final factor = pegados.estrella.radio / inicial.estrella.radio;
      expect(rel0.dx, closeTo(relInicial.dx * factor, 1e-6));
      expect(rel1.dx, greaterThan(rel0.dx));
      expect(_salida(v, 0.62 * 620).opacidadDeUlima, closeTo(0, 1e-9));
      expect(_salida(v, 0.95 * 620).opacidadDeUlima, closeTo(1, 1e-9));
      expect(_salida(v, 0).paginaDy, 32);
    });

    test('C. el panel va recto, «ULIMA» se teclea desde el 55 %, una letra '
        'cada 7 %, y los «++» se sueltan al 45 %', () {
      const v = Codigo();
      expect(_salida(v, 210).combado, 0);
      expect(_salida(v, 210).radioInferior, 0);
      expect(_salida(v, 0.54 * 420).letrasDeUlima, 0);
      expect(_salida(v, 0.56 * 420).letrasDeUlima, 1);
      expect(_salida(v, 0.70 * 420).letrasDeUlima, 3);
      expect(_salida(v, 0.90 * 420).letrasDeUlima, 5);
      final antes = _salida(v, 0.44 * 420);
      final rel = antes.cruces[0].centro - antes.estrella.centro;
      final inicial = _salida(v, 0);
      final relInicial = inicial.cruces[0].centro - inicial.estrella.centro;
      final factor = antes.estrella.radio / inicial.estrella.radio;
      expect(rel.dx, closeTo(relInicial.dx * factor, 1e-6));
      expect(_salida(v, 420).cruces[1].giro, closeTo(-10 * grado, 1e-6));
      expect(_salida(v, 0.35 * 420).paginaOpacidad, closeTo(0, 1e-9));
      // El anillo de Código sigue en el centro de la pantalla.
      final restos = _salida(v, 40).restos;
      expect(restos.centro, _centro);
      expect(restos.anillos, isNotEmpty);
    });
  });
}
```

- [ ] **Paso 2. Corre la prueba y confirma que falla.**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/splash/splash_salida_test.dart
```

Esperado. Falla la compilación, porque `salidas.dart` no existe.

- [ ] **Paso 3. Escribe las salidas.** Crea `lib/pages/splash/salidas.dart`.

```dart
// lib/pages/splash/salidas.dart
// Las salidas de la intro hacia /home (RF-SPL-11 y RF-SPL-13). El panel
// naranja se recoge hasta la cabecera y toma su color, la estrella vuela a
// la estrella de la cabecera y los «++» terminan sobre los del texto
// «ULIMA++». Cada salida es una función pura del instante y de la cabecera
// medida, y un pintor la dibuja. Las curvas de vuelo son las de la decisión
// 3 del plan.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import '../../components/logo/escena_del_logo.dart';
import '../../components/logo/logo_geometria.dart';
import '../../components/logo/pintor_del_logo.dart';
import '../../services/splash_variante_service.dart';
import 'puntos_de_aterrizaje.dart';
import 'variantes/variante_de_intro.dart';

/// El naranja del splash nativo y del primer cuadro, en los dos temas (S-2).
const Color naranjaDelSplash = Color(0xFFE77330);

class DestinoDeLaSalida {
  DestinoDeLaSalida._({
    required this.pantalla,
    required this.cabecera,
    required this.estrella,
    required this.texto,
    required this.anchosDeUlima,
    required this.cruces,
    required this.tamanoDeCruz,
    required this.color,
    required this.colorDelBorde,
    required this.pintorDeUlima,
    required this.pintorDeLosMas,
    required this.anchoDeUlima,
  });

  /// Mide «ULIMA» y los «++» con el mismo estilo y la misma escala de texto de
  /// la cabecera, así que la réplica cae sobre el texto real.
  factory DestinoDeLaSalida.desdeMedida(
    MedidaDeCabecera medida,
    Size pantalla,
  ) {
    TextPainter pintor(String texto) => TextPainter(
      text: TextSpan(text: texto, style: medida.estilo),
      textDirection: TextDirection.ltr,
      textScaler: medida.escalaDeTexto,
    )..layout();
    final ulima = pintor('ULIMA');
    final todo = pintor('ULIMA++');
    final mas = pintor('++');
    final anchos = <double>[
      for (var k = 0; k <= 5; k++)
        ulima.getOffsetForCaret(TextPosition(offset: k), Rect.zero).dx,
    ];
    final em = medida.escalaDeTexto.scale(medida.estilo.fontSize ?? 20);
    final base = todo.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    final anchoDeMas = (todo.width - ulima.width) / 2;
    final y = medida.texto.top + base - 0.34 * em;
    return DestinoDeLaSalida._(
      pantalla: pantalla,
      cabecera: medida.cabecera,
      estrella: medida.estrella,
      texto: medida.texto,
      anchosDeUlima: List<double>.unmodifiable(anchos),
      cruces: List<Offset>.unmodifiable(<Offset>[
        for (var i = 0; i < 2; i++)
          Offset(
            medida.texto.left + ulima.width + anchoDeMas * (i + 0.5),
            y,
          ),
      ]),
      tamanoDeCruz: 0.5 * em,
      color: medida.color,
      colorDelBorde: medida.colorDelBorde,
      pintorDeUlima: ulima,
      pintorDeLosMas: mas,
      anchoDeUlima: ulima.width,
    );
  }

  final Size pantalla;
  final Rect cabecera;
  final Rect estrella;
  final Rect texto;
  final List<double> anchosDeUlima;
  final List<Offset> cruces;
  final double tamanoDeCruz;
  final Color color;
  final Color colorDelBorde;
  final TextPainter pintorDeUlima;
  final TextPainter pintorDeLosMas;
  final double anchoDeUlima;
}

/// Un «+» en vuelo, en dp de la vista.
class CruzDeSalida {
  const CruzDeSalida({
    required this.centro,
    required this.largo,
    required this.giro,
  });

  final Offset centro;
  final double largo;
  final double giro;
}

class EscenaDeSalida {
  const EscenaDeSalida({
    required this.panel,
    required this.colorDelPanel,
    required this.combado,
    required this.radioInferior,
    required this.opacidadDelConjunto,
    required this.estrella,
    required this.restos,
    required this.cruces,
    required this.opacidadDeLasCruces,
    required this.opacidadDeLosMas,
    required this.reveladoDeUlima,
    required this.opacidadDeUlima,
    required this.letrasDeUlima,
    required this.paginaDy,
    required this.paginaOpacidad,
  });

  final Rect panel;
  final Color colorDelPanel;

  /// A. Cuánto baja el centro del borde inferior del panel, en dp.
  final double combado;

  /// B. El radio de las esquinas inferiores, en dp.
  final double radioInferior;

  /// El panel y todo lo que se dibuja encima, que se funden sobre la
  /// cabecera en los últimos 100 ms.
  final double opacidadDelConjunto;

  /// La estrella en vuelo, con lo que queda del bucle en sus rombos.
  final EscenaDelLogo estrella;

  /// Lo que queda de la intro en su marco, como el anillo y el cursor de
  /// Código.
  final EscenaDelLogo restos;
  final List<CruzDeSalida> cruces;
  final double opacidadDeLasCruces;

  /// Los «++» del texto de la réplica.
  final double opacidadDeLosMas;

  /// A. De 0 a 1, de izquierda a derecha.
  final double reveladoDeUlima;

  /// B. La opacidad de «ULIMA».
  final double opacidadDeUlima;

  /// C. Las letras tecleadas de «ULIMA».
  final int letrasDeUlima;
  final double paginaDy;
  final double paginaOpacidad;
}

Offset _bezierCubica(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
  final s = 1 - t;
  return p0 * (s * s * s) +
      p1 * (3 * s * s * t) +
      p2 * (3 * s * t * t) +
      p3 * (t * t * t);
}

/// El centro de la estrella en vuelo con el avance [e], ya con la curva.
Offset _vuelo(
  VarianteSplash tipo,
  Offset desde,
  Offset hasta,
  Size pantalla,
  double e,
) => switch (tipo) {
  VarianteSplash.ensamble => bezierCuadratica(
    desde,
    Offset(desde.dx, hasta.dy + 0.25 * (desde.dy - hasta.dy)),
    hasta,
    e,
  ),
  VarianteSplash.incremento => _bezierCubica(
    desde,
    Offset(desde.dx, desde.dy - 0.2 * pantalla.height),
    Offset(hasta.dx, hasta.dy + 120),
    hasta,
    e,
  ),
  VarianteSplash.codigo => _bezierCubica(
    desde,
    Offset(desde.dx + 40, desde.dy - 0.45 * (hasta - desde).distance),
    Offset(hasta.dx - 30, hasta.dy + 40),
    hasta,
    e,
  ),
};

EscenaDeSalida salidaHaciaHome({
  required VarianteDeIntro variante,
  required double msInicio,
  required double msEnSalida,
  required Offset centroDelMarco,
  required double radioDelMarco,
  required DestinoDeLaSalida destino,
}) {
  final duracion = variante.duracionDeLaSalida;
  final curva = variante.curvaDeLaSalida;
  final t = (msEnSalida / duracion).clamp(0.0, 1.0).toDouble();
  final e = curva.transform(t);
  final d = destino;
  final tipo = variante.tipo;
  final pose = variante
      .escena(
        msInicio,
        centro: centroDelMarco,
        radio: radioDelMarco,
        cargaLista: msInicio,
      )
      .pose;
  final restos = variante.alSalir(
    msInicio,
    msEnSalida,
    centro: centroDelMarco,
    radio: radioDelMarco,
  );

  // La estrella.
  final desde = pose.centro;
  final hasta = d.estrella.center;
  final radioFinal = d.estrella.width / 2;
  double radioEn(double avance) => mezcla(pose.radio, radioFinal, avance);
  Offset centroEn(double avance) => _vuelo(tipo, desde, hasta, d.pantalla, avance);
  final centro = centroEn(e);
  final radio = radioEn(e);
  final giro = tipo == VarianteSplash.incremento
      ? mezcla(
          variante.giroAlSalir(msInicio),
          variante.destinoDelGiro(msInicio) + 45 * grado,
          e,
        )
      : pose.giro;

  // Los «++». Pegados a la estrella, su distancia a ella escala con su
  // radio.
  final unidadInicial = LogoGeometria.unidad(pose.radio);
  final cruces = <CruzDeSalida>[];
  for (var i = 0; i < 2; i++) {
    final origen = pose.cruces[i].centro;
    final largoInicial =
        LogoGeometria.largoDeCruz * unidadInicial * pose.cruces[i].escala;
    final glifo = d.cruces[i];
    Offset pegado(double avance) =>
        centroEn(avance) + (origen - desde) * (radioEn(avance) / pose.radio);
    double largoPegado(double avance) =>
        largoInicial * radioEn(avance) / pose.radio;
    switch (tipo) {
      case VarianteSplash.ensamble:
        // Cada «+» vuela por su cuenta, el segundo un 4 % después.
        final ei = curva.transform(tramo(t, 0.04 * i, 1));
        cruces.add(
          CruzDeSalida(
            centro: bezierCuadratica(
              origen,
              Offset(origen.dx, glifo.dy + 0.25 * (origen.dy - glifo.dy)),
              glifo,
              ei,
            ),
            largo: mezcla(largoInicial, d.tamanoDeCruz, ei),
            giro: -12 * grado * ei,
          ),
        );
      case VarianteSplash.incremento:
        // Pegados hasta los 150 ms y sueltos hacia los glifos en 450 ms.
        final alSoltar = curva.transform(math.min(msEnSalida, 150) / duracion);
        final v = Curves.easeInOutCubic.transform(tramo(msEnSalida, 150, 600));
        cruces.add(
          CruzDeSalida(
            centro: msEnSalida <= 150
                ? pegado(e)
                : Offset.lerp(pegado(alSoltar), glifo, v)!,
            largo: msEnSalida <= 150
                ? largoPegado(e)
                : mezcla(largoPegado(alSoltar), d.tamanoDeCruz, v),
            giro: -12 * grado * v,
          ),
        );
      case VarianteSplash.codigo:
        // Sueltan la estrella al 45 % y aterrizan al final de la palabra.
        final alSoltar = curva.transform(math.min(t, 0.45));
        final v = Curves.easeInOutCubic.transform(tramo(t, 0.45, 1));
        cruces.add(
          CruzDeSalida(
            centro: t <= 0.45
                ? pegado(e)
                : Offset.lerp(pegado(alSoltar), glifo, v)!,
            largo: t <= 0.45
                ? largoPegado(e)
                : mezcla(largoPegado(alSoltar), d.tamanoDeCruz, v),
            giro: -10 * grado * v,
          ),
        );
    }
  }

  final (inicioDePagina, finDePagina, subida) = switch (tipo) {
    VarianteSplash.ensamble => (0.30, 0.70, 20.0),
    VarianteSplash.incremento => (0.30, 0.70, 32.0),
    VarianteSplash.codigo => (0.35, 0.75, 20.0),
  };
  final pagina = tramo(t, inicioDePagina, finDePagina);
  final letras = t <= 0.55 ? 0 : math.min(5, 1 + ((t - 0.55) / 0.07).floor());

  return EscenaDeSalida(
    panel: Rect.fromLTRB(
      0,
      0,
      d.pantalla.width,
      mezcla(d.pantalla.height, d.cabecera.bottom, e),
    ),
    colorDelPanel: Color.lerp(naranjaDelSplash, d.color, e)!,
    combado: tipo == VarianteSplash.ensamble ? 130 * medioSeno(t) : 0,
    radioInferior: tipo == VarianteSplash.incremento ? 75 * medioSeno(t) : 0,
    opacidadDelConjunto: 1 - tramo(msEnSalida, duracion - 100, duracion),
    estrella: EscenaDelLogo(
      centro: centro,
      radio: radio,
      giro: giro,
      rombos: restos.rombos,
    ),
    restos: restos,
    cruces: cruces,
    opacidadDeLasCruces: 1 - tramo(t, 0.75, 1),
    opacidadDeLosMas: tramo(t, 0.75, 1),
    reveladoDeUlima: tipo == VarianteSplash.ensamble ? tramo(t, 0.68, 1) : 1,
    opacidadDeUlima: tipo == VarianteSplash.incremento
        ? tramo(t, 0.62, 0.95)
        : 1,
    letrasDeUlima: tipo == VarianteSplash.codigo ? letras : 5,
    paginaDy: subida * (1 - pagina),
    paginaOpacidad: pagina,
  );
}

Paint _conOpacidad(double opacidad) =>
    Paint()..color = Color.fromRGBO(0, 0, 0, opacidad.clamp(0.0, 1.0));

/// Pinta la salida sobre la página que ya está debajo.
void pintarSalida(
  Canvas canvas,
  EscenaDeSalida s,
  DestinoDeLaSalida d, {
  Color color = const Color(0xFFFFFFFF),
}) {
  if (s.opacidadDelConjunto <= 0) return;
  canvas.saveLayer(null, _conOpacidad(s.opacidadDelConjunto));

  // El panel, abombado en A, con las esquinas redondeadas en B y recto en C.
  final p = s.panel;
  final camino = Path();
  if (s.combado > 0) {
    camino
      ..moveTo(p.left, p.top)
      ..lineTo(p.right, p.top)
      ..lineTo(p.right, p.bottom)
      ..quadraticBezierTo(
        p.center.dx,
        p.bottom + 2 * s.combado,
        p.left,
        p.bottom,
      )
      ..close();
  } else {
    camino.addRRect(
      RRect.fromRectAndCorners(
        p,
        bottomLeft: Radius.circular(s.radioInferior),
        bottomRight: Radius.circular(s.radioInferior),
      ),
    );
  }
  canvas.drawPath(camino, Paint()..color = s.colorDelPanel);

  // Lo que queda de la intro en su marco, sin la estrella, que vuela.
  final marco = s.restos;
  final u = marco.unidad;
  for (final a in marco.anillos) {
    if (a.opacidad <= 0) continue;
    canvas.drawCircle(
      marco.aVista(a.centro),
      a.radio * u,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = a.trazo * u
        ..color = color.withValues(alpha: a.opacidad),
    );
  }
  final cursor = marco.cursor;
  if (cursor != null && cursor.opacidad > 0) {
    canvas.drawRect(
      Rect.fromCenter(
        center: marco.aVista(cursor.centro),
        width: 0.08 * TextoDeCodigo.tamanoEnU * u,
        height: cursor.alto * u,
      ),
      Paint()..color = color.withValues(alpha: cursor.opacidad),
    );
  }

  // La réplica de «ULIMA», con el estilo único de la cabecera, y sus «++».
  final origen = d.texto.topLeft;
  final ancho = switch (s.letrasDeUlima) {
    5 => d.anchoDeUlima * s.reveladoDeUlima,
    final n => d.anchosDeUlima[n],
  };
  if (ancho > 0 && s.opacidadDeUlima > 0) {
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(
        origen.dx - 4,
        origen.dy - 8,
        ancho + 4,
        d.texto.height + 16,
      ),
    );
    canvas.saveLayer(null, _conOpacidad(s.opacidadDeUlima));
    d.pintorDeUlima.paint(canvas, origen);
    canvas.restore();
    canvas.restore();
  }
  if (s.opacidadDeLosMas > 0) {
    canvas.saveLayer(null, _conOpacidad(s.opacidadDeLosMas));
    d.pintorDeLosMas.paint(canvas, origen + Offset(d.anchoDeUlima, 0));
    canvas.restore();
  }

  // La estrella en vuelo.
  pintarEscena(canvas, s.estrella, color: color);

  // Los «++» dibujados.
  if (s.opacidadDeLasCruces > 0) {
    final pintura = Paint()
      ..isAntiAlias = true
      ..color = color.withValues(alpha: s.opacidadDeLasCruces);
    final (h, v) = LogoGeometria.barrasDeCruz();
    for (final c in s.cruces) {
      canvas.save();
      canvas.translate(c.centro.dx, c.centro.dy);
      canvas.rotate(c.giro);
      canvas.scale(c.largo / LogoGeometria.largoDeCruz);
      canvas.drawRect(h, pintura);
      canvas.drawRect(v, pintura);
      canvas.restore();
    }
  }
  canvas.restore();
}
```

  La réplica usa `saveLayer` con la opacidad, y el `color` del estilo de la cabecera ya es
  `onPrimary`, así que se ve igual que el texto real y cae sobre él al terminar.

- [ ] **Paso 4. Corre la prueba y confirma que pasa.**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/pages/splash/salidas.dart test/splash/splash_salida_test.dart
"${FLUTTER:?}" test --no-pub test/splash/splash_salida_test.dart
"${FLUTTER:?}" analyze --no-pub
```

Esperado. `All tests passed!` y `6 issues found.`. Si la prueba del destino falla porque la fuente
de pruebas mide 1 em por letra, el cálculo sigue siendo válido y lo que se ajusta es solo el
rectángulo del texto de `_medida`, nunca la fórmula.

- [ ] **Paso 5. Commit.**

```bash
cd "${REPO:?}"
git status --short
git add lib/pages/splash/salidas.dart test/splash/splash_salida_test.dart
git commit -m "feat(splash): las tres salidas hacia /home recogen el panel hasta la cabecera y llevan la estrella y los «++» a su lugar en el texto (RF-SPL-11 y RF-SPL-13)"
git log -1 --format='%an <%ae>'
```

---

### Tarea 11. La navegación de la intro, sin transición y con la guarda de `/arranque`

**Requisitos.** De RF-SPL-4, «Navegación sin transición» (decisión S-19), «La bienvenida siempre
por `offAllToLogin`» y «Un 401 durante la carga» (decisión S-20), y la pose como argumento de
RF-SPL-21 (decisión S-33).

**Archivos.**
- Modificar `lib/services/session_navigation.dart`.
- Crear `test/splash/splash_arranque_test.dart` (grupo `la navegación de la intro`).

**Interfaces.**
- Consume `PoseDelLogo` de la Tarea 2.
- Produce estas firmas, que usan las Tareas 13, 15, 29 y 30.

```dart
const String rutaDelArranque = '/arranque';
const String argumentoDePose = 'pose';
bool offAllSinTransicion(String ruta, {Object? arguments});
bool offAllToLogin({PoseDelLogo? pose, bool desdeLaIntro = false});
```

- [ ] **Paso 1. Escribe la prueba que falla.** Crea `test/splash/splash_arranque_test.dart`. Las
  Tareas 12 a 14 le suman sus grupos.

```dart
// test/splash/splash_arranque_test.dart
//
// UNITARIA + WIDGET · Splash animado (specs/features/splash/splash.spec.md).
// RF-SPL-4 fija que la intro navega sin transición, con el page y el binding
// de la GetPage de su destino y su argumento de ruta, que llega a la
// bienvenida siempre por offAllToLogin y que un 401 durante la carga no
// navega mientras la ruta es /arranque. Las Tareas 12 a 14 suman la capa, la
// intro completa y la carga.
// Archivos probados lib/services/session_navigation.dart y, desde la Tarea
// 12, lib/pages/splash/capa_de_arranque.dart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/logo/escena_del_logo.dart';
import 'package:ulima_plus/services/session_navigation.dart';

/// Un binding que deja constancia de que corrió.
class _BindingMarcado extends Bindings {
  static int veces = 0;

  @override
  void dependencies() => veces++;
}

Widget _pagina(String texto) => Scaffold(body: Center(child: Text(texto)));

Widget _app({String initialRoute = rutaDelArranque}) => GetMaterialApp(
  initialRoute: initialRoute,
  getPages: [
    GetPage(name: rutaDelArranque, page: () => _pagina('arranque')),
    GetPage(
      name: '/home',
      page: () => _pagina('home'),
      binding: _BindingMarcado(),
    ),
    GetPage(name: '/login', page: () => _pagina('login')),
    GetPage(name: '/perfil', page: () => _pagina('perfil')),
  ],
);

/// La ruta de la página que muestra [texto].
Route<dynamic> _rutaDe(WidgetTester tester, String texto) =>
    ModalRoute.of(tester.element(find.text(texto)))!;

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
    _BindingMarcado.veces = 0;
  });
  tearDown(Get.reset);

  group('la navegación de la intro (RF-SPL-4)', () {
    testWidgets('offAllSinTransicion usa el page y el binding de la GetPage, '
        'sin transición, opaca y con el argumento', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pump();
      final navego = offAllSinTransicion(
        '/home',
        arguments: const {'pestana': 'horario'},
      );
      expect(navego, isTrue);
      await tester.pump();
      expect(find.text('home'), findsOneWidget);
      expect(find.text('arranque'), findsNothing);
      expect(Get.currentRoute, '/home');
      expect(_BindingMarcado.veces, 1);
      final ruta = _rutaDe(tester, 'home');
      expect(ruta, isA<GetPageRoute<dynamic>>());
      expect((ruta as GetPageRoute<dynamic>).transition, Transition.noTransition);
      expect(ruta.opaque, isTrue);
      expect(ruta.settings.arguments, const {'pestana': 'horario'});
    });

    testWidgets('en /arranque, offAllToLogin no navega salvo desde la intro',
        (tester) async {
      await tester.pumpWidget(_app());
      await tester.pump();
      expect(offAllToLogin(), isFalse);
      await tester.pump();
      expect(Get.currentRoute, rutaDelArranque);
      expect(find.text('arranque'), findsOneWidget);
    });

    testWidgets('desde la intro llega a /login sin transición y con la pose',
        (tester) async {
      await tester.pumpWidget(_app());
      await tester.pump();
      final pose = EscenaDelLogo.reposo(
        centro: const Offset(144, 320),
        radio: 90,
      ).pose;
      expect(offAllToLogin(pose: pose, desdeLaIntro: true), isTrue);
      await tester.pump();
      expect(Get.currentRoute, '/login');
      final ruta = _rutaDe(tester, 'login') as GetPageRoute<dynamic>;
      expect(ruta.transition, Transition.noTransition);
      expect((ruta.settings.arguments! as Map)[argumentoDePose], same(pose));
      // Ya en /login, una segunda llamada no navega.
      expect(offAllToLogin(desdeLaIntro: true), isFalse);
    });

    testWidgets('fuera de /arranque, offAllToLogin sigue igual que hoy, con su '
        'transición y sin argumentos', (tester) async {
      await tester.pumpWidget(_app(initialRoute: '/perfil'));
      await tester.pump();
      expect(offAllToLogin(), isTrue);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(Get.currentRoute, '/login');
      final ruta = _rutaDe(tester, 'login') as GetPageRoute<dynamic>;
      expect(ruta.transition, isNot(Transition.noTransition));
      expect(ruta.settings.arguments, isNull);
    });
  });
}
```

- [ ] **Paso 2. Corre la prueba y confirma que falla.**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/splash/splash_arranque_test.dart
```

Esperado. Falla la compilación, porque `rutaDelArranque`, `offAllSinTransicion`,
`argumentoDePose` y los parámetros nuevos de `offAllToLogin` no existen.

- [ ] **Paso 3. Cambia `session_navigation.dart`.** Suma el import y las constantes después del
  comentario de cabecera, y reemplaza `offAllToLogin` (`session_navigation.dart:25-39`) por esto.

```dart
import 'package:get/get.dart';

import '../components/logo/escena_del_logo.dart';

/// La página vacía en la que arranca la app mientras corre la intro
/// (RF-SPL-4).
const String rutaDelArranque = '/arranque';

/// La clave del argumento con la pose del logo que la intro pasa a la
/// bienvenida (RF-SPL-21 y decisión S-33).
const String argumentoDePose = 'pose';

/// Navega a [ruta] sin transición, con el `page` y el `binding` de la
/// `GetPage` que registró `main.dart`, así que el binding no se duplica
/// (decisión S-19). La usan la intro del splash y el paso al horario de la
/// bienvenida. Devuelve `false` si no hay navegador o la ruta no existe.
bool offAllSinTransicion(String ruta, {Object? arguments}) {
  if (Get.context == null) return false;
  final pagina = Get.routeTree.matchRoute(ruta).route;
  if (pagina == null) return false;
  Get.offAll<void>(
    pagina.page,
    routeName: ruta,
    binding: pagina.binding,
    arguments: arguments,
    transition: Transition.noTransition,
    duration: Duration.zero,
    opaque: true,
  );
  return true;
}

/// Limpia el stack y navega a /login una sola vez.
///
/// Devuelve `true` si efectivamente navegó y `false` si no había navegador
/// montado, si /login ya es la ruta actual (incluida una navegación a /login
/// aún en transición) o si la ruta actual es /arranque y no la llama la intro.
/// Así un 401 durante la carga borra la sesión en `ApiClient` sin navegar ni
/// mostrar «Sesión expirada», y la intro navega una sola vez (decisión S-20).
///
/// Desde la intro navega sin transición y con la [pose] del logo como
/// argumento (RF-SPL-4 y RF-SPL-21). Los demás llamadores no cambian, y
/// `onPressed: offAllToLogin` sigue compilando porque los parámetros son
/// nombrados y opcionales.
bool offAllToLogin({PoseDelLogo? pose, bool desdeLaIntro = false}) {
  if (Get.context == null) return false;
  if (Get.currentRoute == rutaDelArranque && !desdeLaIntro) return false;
  final alreadyOnLogin =
      Get.currentRoute == '/login' || Get.currentRoute == '/LoginPage';
  if (alreadyOnLogin) return false;
  final argumentos = <String, Object>{argumentoDePose: ?pose};
  if (desdeLaIntro) {
    return offAllSinTransicion(
      '/login',
      arguments: argumentos.isEmpty ? null : argumentos,
    );
  }
  Get.offAllNamed('/login', arguments: argumentos.isEmpty ? null : argumentos);
  return true;
}
```

  El comentario de cabecera del archivo suma, al final, este párrafo.

```dart
// La intro del splash llega a la bienvenida por aquí, sin transición y con la
// pose del logo, y mientras la ruta actual es /arranque nadie más navega a
// /login (RF-SPL-4 de specs/features/splash/splash.spec.md).
```

- [ ] **Paso 4. Corre las pruebas y confirma que pasan.**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/services/session_navigation.dart test/splash/splash_arranque_test.dart
"${FLUTTER:?}" test --no-pub test/splash/splash_arranque_test.dart test/HU02_jeff test/HU01_jeff test/HU33_jeff/api_client_401_test.dart
"${FLUTTER:?}" analyze --no-pub
```

Esperado. `All tests passed!`. La guarda de `session_navigation_guard_test.dart` sigue en verde,
porque el único `offAllNamed('/login')` está en `session_navigation.dart` y
`offAllSinTransicion('/login'` no coincide con su expresión. `6 issues found.`.

- [ ] **Paso 5. Commit.**

```bash
cd "${REPO:?}"
git status --short
git add lib/services/session_navigation.dart test/splash/splash_arranque_test.dart
git commit -m "feat(splash): offAllToLogin no navega durante /arranque salvo desde la intro, que llega sin transición y con la pose del logo (RF-SPL-4 y RF-SPL-21)"
git log -1 --format='%an <%ae>'
```

---

### Tarea 12. La capa permanente, el primer cuadro y la entrada

**Requisitos.** De RF-SPL-4, «La capa es permanente», el estado en el `State` y los toques
bloqueados, con la barra de estado de la capa. RF-SPL-5 completo (decisiones S-18 y S-21),
RF-SPL-15 completo (decisión S-13) y, de RF-SPL-6, que la estrella queda quieta hasta que la
variante está elegida y que el tiempo corre desde ese momento. La capa todavía no termina la intro,
que es de la Tarea 13.

**Archivos.**
- Crear `lib/pages/splash/arranque_page.dart`.
- Crear `lib/pages/splash/capa_de_arranque.dart`.
- Modificar `test/splash/apoyo_splash.dart` (montaje de la capa y dobles).
- Crear `test/splash/splash_primer_cuadro_test.dart`.
- Crear `test/splash/splash_accesibilidad_test.dart`.
- Modificar `test/splash/splash_arranque_test.dart` (grupo `la capa`).

**Interfaces.**
- Consume las Tareas 2, 4, 6, 9 y 11.
- Produce estas firmas, que usan las Tareas 13, 14 y 30.

```dart
// arranque_page.dart
class ArranquePage extends StatelessWidget { const ArranquePage(); }
// capa_de_arranque.dart
class IntroDelArranque { const IntroDelArranque({required Future<String> Function() carga,
  required SplashVarianteService variantes, required Random random}); }
class FalloAntesDeLosServicios implements Exception { const FalloAntesDeLosServicios(Object causa); }
enum FaseDeLaCapa { inactiva, eligiendo, intro, esperandoCabecera, salida, fundido, relevo,
  pasoAlHorario }
const String etiquetaDeLaIntro = 'ULIMA++, cargando';
const double radioDelNativo = 90;
Offset centroDelNativo(Size vista, Size pantallaFisica);
class CapaDeArranque extends StatefulWidget {
  const CapaDeArranque({required Widget child, IntroDelArranque? intro});
  static FaseDeLaCapa get fase;
  static EscenaDelLogo? get escenaActual;        // para las pruebas
  static void avisarPrimerCuadroDeLaBienvenida(); // desde la Tarea 13
  static void reiniciar(); }                       // para las pruebas
```

- [ ] **Paso 1. Suma el montaje al apoyo.** Agrega a `test/splash/apoyo_splash.dart` estos
  imports y declaraciones.

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/pages/splash/arranque_page.dart';
import 'package:ulima_plus/pages/splash/capa_de_arranque.dart';
import 'package:ulima_plus/pages/splash/estado_de_la_capa.dart';
import 'package:ulima_plus/pages/splash/puntos_de_aterrizaje.dart';
import 'package:ulima_plus/services/session_navigation.dart';
import 'package:ulima_plus/services/splash_variante_service.dart';
```

```dart
/// Una carga que termina cuando la prueba lo pide.
class CargaFalsa {
  final Completer<String> _fin = Completer<String>();
  int llamadas = 0;

  Future<String> call() {
    llamadas++;
    return _fin.future;
  }

  void terminar(String ruta) => _fin.complete(ruta);

  void fallar(Object error) => _fin.completeError(error);
}

/// Un servicio de variantes sin almacén. Elige [variante] cuando la prueba
/// llama a [elegirYa], o enseguida si [enseguida] es true.
class VariantesFijas extends SplashVarianteService {
  VariantesFijas(this.variante, {this.enseguida = true});

  final VarianteSplash variante;
  final bool enseguida;
  final Completer<void> _permiso = Completer<void>();
  int lecturas = 0;

  void elegirYa() => _permiso.complete();

  @override
  Future<VarianteSplash> elegir(Random random) async {
    lecturas++;
    if (!enseguida) await _permiso.future;
    return variante;
  }
}

/// Un teléfono de [ancho] × [alto] dp, con la pantalla física de
/// [altoFisico] dp si llega, o del mismo alto que la vista.
void telefono(
  WidgetTester tester, {
  double ancho = 375,
  double alto = 667,
  double? altoFisico,
  double dpr = 2,
}) {
  tester.view.physicalSize = Size(ancho * dpr, alto * dpr);
  tester.view.devicePixelRatio = dpr;
  tester.view.display.size = Size(ancho * dpr, (altoFisico ?? alto) * dpr);
  tester.view.display.devicePixelRatio = dpr;
  addTearDown(tester.view.reset);
  addTearDown(tester.view.display.reset);
}

class PaginaDePrueba extends StatelessWidget {
  const PaginaDePrueba(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => toquesEnLaPagina++,
        child: Text(texto),
      ),
    ),
  );
}

/// Cuántos toques llegaron a una página de prueba.
int toquesEnLaPagina = 0;

/// Una bienvenida de prueba que avisa a la capa cuando pinta su primer
/// cuadro, como la real (RF-SPL-21), y guarda sus argumentos.
class BienvenidaDePrueba extends StatefulWidget {
  const BienvenidaDePrueba({super.key});

  static Object? argumentos;

  @override
  State<BienvenidaDePrueba> createState() => _BienvenidaDePruebaState();
}

class _BienvenidaDePruebaState extends State<BienvenidaDePrueba> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => CapaDeArranque.avisarPrimerCuadroDeLaBienvenida(),
    );
  }

  @override
  Widget build(BuildContext context) {
    BienvenidaDePrueba.argumentos = ModalRoute.of(context)?.settings.arguments;
    return const PaginaDePrueba('bienvenida');
  }
}

/// La app con la capa en su builder, /arranque y páginas de prueba.
Widget appConCapa({
  IntroDelArranque? intro,
  WidgetBuilder? home,
  List<NavigatorObserver> observadores = const <NavigatorObserver>[],
  ThemeMode modo = ThemeMode.light,
}) => GetMaterialApp(
  initialRoute: intro == null ? '/login' : rutaDelArranque,
  themeMode: modo,
  theme: ThemeData.light(),
  darkTheme: ThemeData.dark(),
  navigatorObservers: observadores,
  builder: (context, child) => CapaDeArranque(intro: intro, child: child!),
  getPages: [
    GetPage(name: rutaDelArranque, page: () => const ArranquePage()),
    GetPage(
      name: '/home',
      page: () => Builder(
        builder: home ?? (_) => const PaginaDePrueba('home'),
      ),
    ),
    GetPage(name: '/login', page: () => const BienvenidaDePrueba()),
  ],
);

/// Deja la capa, sus puntos y Get como al empezar.
void reiniciarArranque() {
  Get.testMode = true;
  Get.reset();
  CapaDeArranque.reiniciar();
  EstadoDeLaCapa.cubre.value = false;
  PuntosDeAterrizaje.reiniciar();
  toquesEnLaPagina = 0;
  BienvenidaDePrueba.argumentos = null;
}
```

- [ ] **Paso 2. Escribe las pruebas que fallan.** Crea `test/splash/splash_primer_cuadro_test.dart`.

```dart
// test/splash/splash_primer_cuadro_test.dart
//
// WIDGET · Splash animado (specs/features/splash/splash.spec.md).
// RF-SPL-5. El primer cuadro de Flutter pinta #E77330 de borde a borde y la
// estrella del nativo con R = 90 dp, sin «++» ni giro, centrada en la mitad
// del alto de la pantalla física. Es una guarda de regresión contra
// assets/splash/splash_estrella.png compuesto sobre #E77330, con tolerancia
// (S-18). La equivalencia real la comprueba la grabación de «Verificación».

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/pages/splash/capa_de_arranque.dart';
import 'package:ulima_plus/services/splash_variante_service.dart';

import 'apoyo_splash.dart';

Future<ByteData> _rgba(WidgetTester tester, ui.Image imagen) async =>
    (await tester.runAsync(
      () => imagen.toByteData(format: ui.ImageByteFormat.rawRgba),
    ))!;

void main() {
  setUp(reiniciarArranque);
  tearDown(reiniciarArranque);

  test('el centro es la mitad del alto de la pantalla física', () {
    expect(
      centroDelNativo(const Size(375, 627), const Size(375, 667)),
      const Offset(187.5, 333.5),
    );
    // Sin medida de la pantalla, o si no alcanza a la vista, la vista.
    expect(
      centroDelNativo(const Size(375, 667), Size.zero),
      const Offset(187.5, 333.5),
    );
  });

  testWidgets('en Android 12 a 14 con tres botones la estrella se centra en '
      'la pantalla física y no en la vista (S-21)', (tester) async {
    telefono(tester, alto: 627, altoFisico: 667);
    final carga = CargaFalsa();
    await tester.pumpWidget(
      appConCapa(
        intro: IntroDelArranque(
          carga: carga.call,
          variantes: VariantesFijas(VarianteSplash.ensamble, enseguida: false),
          random: Random(1),
        ),
      ),
    );
    final escena = CapaDeArranque.escenaActual!;
    expect(escena.centro, const Offset(187.5, 333.5));
    expect(escena.radio, 90);
    expect(escena.cruces, isEmpty);
    expect(escena.giro, 0);
  });

  testWidgets('el primer cuadro, pintado a 4x, coincide con el PNG del nativo '
      'sobre #E77330', (tester) async {
    telefono(tester, ancho: 288, alto: 640, dpr: 4);
    final clave = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: clave,
        child: appConCapa(
          intro: IntroDelArranque(
            carga: CargaFalsa().call,
            variantes: VariantesFijas(VarianteSplash.codigo, enseguida: false),
            random: Random(1),
          ),
        ),
      ),
    );
    final frontera =
        clave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final cuadro = (await tester.runAsync(
      () => frontera.toImage(pixelRatio: 4),
    ))!;
    expect(cuadro.width, 1152);
    expect(cuadro.height, 2560);
    final pantalla = await _rgba(tester, cuadro);

    final bytes = File('assets/splash/splash_estrella.png').readAsBytesSync();
    final png = (await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
      return (await codec.getNextFrame()).image;
    }))!;
    final nativo = await _rgba(tester, png);

    // El azul separa el blanco (255) del #E77330 (48).
    var distintos = 0;
    const arriba = 1280 - 576;
    for (var y = 0; y < 1152; y++) {
      for (var x = 0; x < 1152; x++) {
        final alfa = nativo.getUint8((y * 1152 + x) * 4 + 3) / 255;
        final esperado = 48 + (255 - 48) * alfa;
        final real = pantalla.getUint8(((y + arriba) * 1152 + x) * 4 + 2);
        if ((real - esperado).abs() > 48) distintos++;
      }
    }
    expect(distintos / (1152 * 1152), lessThanOrEqualTo(0.01));
    // Arriba y abajo del cuadrado, #E77330 de borde a borde.
    expect(pantalla.getUint8((10 * 1152 + 10) * 4 + 2), 48);
    expect(pantalla.getUint8((2550 * 1152 + 1140) * 4 + 2), 48);
  });
}
```

  Crea `test/splash/splash_accesibilidad_test.dart`.

```dart
// test/splash/splash_accesibilidad_test.dart
//
// WIDGET · Splash animado (specs/features/splash/splash.spec.md).
// RF-SPL-15. Durante la intro la capa es un solo nodo de semántica con la
// etiqueta fija «ULIMA++, cargando», sin región viva ni anuncios, y el
// lector no ve la página de debajo. Inactiva, queda fuera de la semántica.

import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/pages/splash/capa_de_arranque.dart';
import 'package:ulima_plus/services/splash_variante_service.dart';

import 'apoyo_splash.dart';

void main() {
  final anuncios = <Object?>[];

  setUp(() {
    reiniciarArranque();
    anuncios.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockDecodedMessageHandler<Object?>(SystemChannels.accessibility, (
          mensaje,
        ) async {
          anuncios.add(mensaje);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockDecodedMessageHandler<Object?>(SystemChannels.accessibility, null);
    reiniciarArranque();
  });

  testWidgets('durante la intro hay un solo nodo «ULIMA++, cargando», fijo, '
      'sin región viva, y la página de debajo no se ve', (tester) async {
    final semantica = tester.ensureSemantics();
    telefono(tester);
    await tester.pumpWidget(
      appConCapa(
        intro: IntroDelArranque(
          carga: CargaFalsa().call,
          variantes: VariantesFijas(VarianteSplash.incremento),
          random: Random(1),
        ),
      ),
    );
    for (var ms = 0; ms <= 1500; ms += 250) {
      await tester.pump(const Duration(milliseconds: 250));
      final nodo = find.bySemanticsLabel(etiquetaDeLaIntro);
      expect(nodo, findsOneWidget, reason: 'a los $ms ms');
      expect(
        tester.getSemantics(nodo),
        containsSemantics(label: etiquetaDeLaIntro, isLiveRegion: false),
      );
    }
    // La página de debajo queda fuera de la semántica.
    final excluida = tester.widget<ExcludeSemantics>(
      find
          .descendant(
            of: find.byType(CapaDeArranque),
            matching: find.byType(ExcludeSemantics),
          )
          .first,
    );
    expect(excluida.excluding, isTrue);
    expect(anuncios, isEmpty);
    semantica.dispose();
  });

  testWidgets('sin intro la capa queda fuera de la semántica y la página se '
      'lee', (tester) async {
    final semantica = tester.ensureSemantics();
    telefono(tester);
    await tester.pumpWidget(appConCapa());
    await tester.pump();
    expect(find.bySemanticsLabel(etiquetaDeLaIntro), findsNothing);
    expect(find.bySemanticsLabel('bienvenida'), findsOneWidget);
    semantica.dispose();
  });
}
```

  En `test/splash/splash_arranque_test.dart`, suma estos imports y este grupo al final de
  `main()`.

```dart
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:ulima_plus/pages/splash/capa_de_arranque.dart';
import 'package:ulima_plus/pages/splash/estado_de_la_capa.dart';
import 'package:ulima_plus/services/splash_variante_service.dart';

import 'apoyo_splash.dart';
```

```dart
  group('la capa (RF-SPL-4 y RF-SPL-6)', () {
    setUp(reiniciarArranque);
    tearDown(reiniciarArranque);

    testWidgets('sin intro está inactiva, no tapa la pantalla y deja pasar '
        'los toques', (tester) async {
      telefono(tester);
      await tester.pumpWidget(appConCapa());
      await tester.pump();
      expect(CapaDeArranque.fase, FaseDeLaCapa.inactiva);
      expect(EstadoDeLaCapa.cubre.value, isFalse);
      await tester.tap(find.text('bienvenida'));
      expect(toquesEnLaPagina, 1);
    });

    testWidgets('con intro tapa la pantalla, bloquea los toques y la barra de '
        'estado usa íconos claros', (tester) async {
      telefono(tester);
      await tester.pumpWidget(
        appConCapa(
          intro: IntroDelArranque(
            carga: CargaFalsa().call,
            variantes: VariantesFijas(VarianteSplash.ensamble),
            random: Random(1),
          ),
        ),
      );
      await tester.pump();
      expect(EstadoDeLaCapa.cubre.value, isTrue);
      expect(CapaDeArranque.fase, isNot(FaseDeLaCapa.inactiva));
      final bloqueo = tester.widget<AbsorbPointer>(
        find
            .descendant(
              of: find.byType(CapaDeArranque),
              matching: find.byType(AbsorbPointer),
            )
            .first,
      );
      expect(bloqueo.absorbing, isTrue);
      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.descendant(
          of: find.byType(CapaDeArranque),
          matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
        ).first,
      );
      expect(region.value.statusBarIconBrightness, Brightness.light);
    });

    testWidgets('la estrella queda quieta hasta que la variante está elegida y '
        'el tiempo de la intro corre desde ahí', (tester) async {
      telefono(tester);
      final variantes = VariantesFijas(VarianteSplash.ensamble, enseguida: false);
      await tester.pumpWidget(
        appConCapa(
          intro: IntroDelArranque(
            carga: CargaFalsa().call,
            variantes: variantes,
            random: Random(1),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(CapaDeArranque.fase, FaseDeLaCapa.eligiendo);
      final quieta = CapaDeArranque.escenaActual!;
      expect(quieta.rombos.every((r) => r.desplazamiento == 0), isTrue);
      expect(quieta.cruces, isEmpty);

      variantes.elegirYa();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(CapaDeArranque.fase, FaseDeLaCapa.intro);
      // A unos 200 ms de la elección, los rombos de Ensamble se están
      // abriendo.
      expect(
        CapaDeArranque.escenaActual!.rombos[3].desplazamiento,
        greaterThan(100),
      );
    });

    testWidgets('la carga corre en paralelo desde el montaje', (tester) async {
      telefono(tester);
      final carga = CargaFalsa();
      await tester.pumpWidget(
        appConCapa(
          intro: IntroDelArranque(
            carga: carga.call,
            variantes: VariantesFijas(VarianteSplash.codigo, enseguida: false),
            random: Random(1),
          ),
        ),
      );
      expect(carga.llamadas, 1);
    });
  });
```

- [ ] **Paso 3. Corre las pruebas y confirma que fallan.**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/splash
```

Esperado. Falla la compilación de las pruebas que importan `capa_de_arranque.dart` y
`arranque_page.dart`, que no existen.

- [ ] **Paso 4. Escribe la página del arranque.** Crea `lib/pages/splash/arranque_page.dart`.

```dart
// lib/pages/splash/arranque_page.dart
// La página vacía de /arranque, del naranja del splash, sobre la que corre
// la intro (RF-SPL-4).

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'salidas.dart';

class ArranquePage extends StatelessWidget {
  const ArranquePage({super.key});

  @override
  Widget build(BuildContext context) =>
      const AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: ColoredBox(color: naranjaDelSplash, child: SizedBox.expand()),
      );
}
```

- [ ] **Paso 5. Escribe la capa.** Crea `lib/pages/splash/capa_de_arranque.dart` con este
  contenido. La Tarea 13 le suma el final de la intro y la Tarea 30 el paso al horario.

```dart
// lib/pages/splash/capa_de_arranque.dart
// La capa del arranque (RF-SPL-4 de la spec del splash). Es una pieza fija
// del builder de GetMaterialApp, montada en todas las plataformas. Inactiva
// no pinta nada, no bloquea toques y queda fuera de la semántica. Activa tapa
// la pantalla con la intro y, desde la spec de la bienvenida, con su paso al
// horario (decisión B-33).
//
// Su estado vive en este State y no en un GetxController, porque GetX liga a
// /arranque lo que se registra mientras esa es la ruta actual y lo borra al
// retirarla, en plena salida.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../components/logo/escena_del_logo.dart';
import '../../components/logo/pintor_del_logo.dart';
import '../../services/splash_variante_service.dart';
import 'estado_de_la_capa.dart';
import 'salidas.dart';
import 'variantes/variantes.dart';

/// Lo que la intro necesita del arranque. La carga se inyecta, como el
/// `Random`, así que las pruebas la reemplazan sin Firebase ni el almacén
/// seguro (RF-SPL-4).
class IntroDelArranque {
  const IntroDelArranque({
    required this.carga,
    required this.variantes,
    required this.random,
  });

  final Future<String> Function() carga;
  final SplashVarianteService variantes;
  final Random random;
}

/// La carga falló antes de registrar los servicios, así que no hay una ruta
/// segura (RF-SPL-18).
class FalloAntesDeLosServicios implements Exception {
  const FalloAntesDeLosServicios(this.causa);

  final Object causa;

  @override
  String toString() => 'FalloAntesDeLosServicios($causa)';
}

enum FaseDeLaCapa {
  inactiva,
  eligiendo,
  intro,
  esperandoCabecera,
  salida,
  fundido,
  relevo,
  pasoAlHorario,
}

/// La etiqueta fija de la intro (RF-SPL-15 y S-13).
const String etiquetaDeLaIntro = 'ULIMA++, cargando';

/// El radio de la estrella en el primer cuadro, en dp (RF-SPL-5).
const double radioDelNativo = 90;

/// El centro del nativo es la mitad del alto de la pantalla física, medido
/// desde el borde superior de la vista (S-21). Sin esa medida, o si la
/// pantalla física no alcanza a la vista, es el centro de la vista.
Offset centroDelNativo(Size vista, Size pantallaFisica) {
  final alto = pantallaFisica.height;
  final y = alto > 0 && alto >= vista.height ? alto / 2 : vista.height / 2;
  return Offset(vista.width / 2, y);
}

class CapaDeArranque extends StatefulWidget {
  const CapaDeArranque({super.key, required this.child, this.intro});

  /// El Navigator de GetMaterialApp.
  final Widget child;

  /// La intro, o null en web y donde no hay intro (S-22).
  final IntroDelArranque? intro;

  static _CapaDeArranqueState? _estado;

  static FaseDeLaCapa get fase =>
      _estado?._fase.value ?? FaseDeLaCapa.inactiva;

  @visibleForTesting
  static EscenaDelLogo? get escenaActual => _estado?._escena.value;

  /// La bienvenida avisa que pintó su primer cuadro, igual al último de la
  /// intro, y la capa se retira sin fundido (RF-SPL-21).
  static void avisarPrimerCuadroDeLaBienvenida() =>
      _estado?._alPintarLaBienvenida();

  @visibleForTesting
  static void reiniciar() => _estado = null;

  @override
  State<CapaDeArranque> createState() => _CapaDeArranqueState();
}

class _CapaDeArranqueState extends State<CapaDeArranque>
    with SingleTickerProviderStateMixin {
  late final Ticker _reloj = createTicker(_alTic);
  final ValueNotifier<FaseDeLaCapa> _fase = ValueNotifier<FaseDeLaCapa>(
    FaseDeLaCapa.inactiva,
  );
  final ValueNotifier<EscenaDelLogo?> _escena = ValueNotifier<EscenaDelLogo?>(
    null,
  );

  /// Cómo se ve la página de debajo. Solo la salida la mueve y la funde.
  final ValueNotifier<Offset> _corrimientoDeLaPagina = ValueNotifier<Offset>(
    Offset.zero,
  );
  final ValueNotifier<double> _opacidadDeLaPagina = ValueNotifier<double>(1);

  /// La opacidad de lo que la capa pinta, para los fundidos.
  final ValueNotifier<double> _opacidad = ValueNotifier<double>(1);

  VarianteDeIntro? _variante;
  Duration _ahora = Duration.zero;
  Duration? _inicioDeLaIntro;
  bool _preparada = false;
  Offset _centro = Offset.zero;
  Size _vista = Size.zero;

  /// Los ms de la intro, contados desde que la variante está elegida.
  double get _ms => _inicioDeLaIntro == null
      ? 0
      : (_ahora - _inicioDeLaIntro!).inMicroseconds / 1000;

  String get _etiqueta => etiquetaDeLaIntro;

  @override
  void initState() {
    super.initState();
    CapaDeArranque._estado = this;
    if (widget.intro != null) {
      _fase.value = FaseDeLaCapa.eligiendo;
      EstadoDeLaCapa.cubre.value = true;
      _reloj.start();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _medir();
    if (_preparada || widget.intro == null) return;
    _preparada = true;
    // El primer cuadro es el nativo, sin «++» y sin giro (RF-SPL-5).
    _escena.value = EscenaDelLogo.reposo(
      centro: _centro,
      radio: radioDelNativo,
      conCruces: false,
    );
    _empezarLaCarga();
    unawaited(_elegirVariante());
  }

  void _medir() {
    _vista = MediaQuery.sizeOf(context);
    final pantalla = View.of(context).display;
    _centro = centroDelNativo(
      _vista,
      pantalla.size / pantalla.devicePixelRatio,
    );
  }

  /// La carga corre en paralelo con la intro desde el montaje. La Tarea 13
  /// le suma lo que pasa al terminar.
  void _empezarLaCarga() {
    unawaited(widget.intro!.carga().then((_) {}, onError: (Object _) {}));
  }

  Future<void> _elegirVariante() async {
    final intro = widget.intro!;
    final tipo = await intro.variantes.elegir(intro.random);
    if (!mounted || _fase.value != FaseDeLaCapa.eligiendo) return;
    _variante = varianteDe(tipo);
    _inicioDeLaIntro = _ahora;
    _fase.value = FaseDeLaCapa.intro;
  }

  void _alTic(Duration transcurrido) {
    _ahora = transcurrido;
    if (_fase.value == FaseDeLaCapa.intro) {
      _escena.value = _variante!.escena(
        _ms,
        centro: _centro,
        radio: radioDelNativo,
      );
    }
  }

  void _alPintarLaBienvenida() {}

  @override
  void dispose() {
    _reloj.dispose();
    if (identical(CapaDeArranque._estado, this)) CapaDeArranque._estado = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<FaseDeLaCapa>(
      valueListenable: _fase,
      builder: (context, fase, _) {
        final activa = fase != FaseDeLaCapa.inactiva;
        // Siempre los mismos tres hijos, para que el Navigator no se vuelva a
        // montar cuando la capa cambia de fase.
        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: _fondoDeLaPagina(context, fase)),
            ExcludeSemantics(
              excluding: activa,
              child: AbsorbPointer(
                absorbing: activa,
                child: _PaginaDeDebajo(capa: this, child: widget.child),
              ),
            ),
            if (activa)
              AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle.light,
                child: Semantics(
                  container: true,
                  label: _etiqueta,
                  excludeSemantics: true,
                  child: AbsorbPointer(
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _PintorDeLaCapa(this),
                    ),
                  ),
                ),
              )
            else
              const SizedBox.shrink(),
          ],
        );
      },
    );
  }

  /// Detrás de la página va el fondo del tema, así que la salida no deja ver
  /// un destello blanco ni negro (RF-SPL-11).
  Color _fondoDeLaPagina(BuildContext context, FaseDeLaCapa fase) =>
      fase == FaseDeLaCapa.salida || fase == FaseDeLaCapa.pasoAlHorario
      ? Theme.of(context).colorScheme.surface
      : const Color(0x00000000);
}

class _PaginaDeDebajo extends StatelessWidget {
  const _PaginaDeDebajo({required this.capa, required this.child});

  final _CapaDeArranqueState capa;
  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Offset>(
    valueListenable: capa._corrimientoDeLaPagina,
    builder: (context, corrimiento, hijo) => Transform.translate(
      offset: corrimiento,
      child: ValueListenableBuilder<double>(
        valueListenable: capa._opacidadDeLaPagina,
        builder: (context, opacidad, hijo) =>
            Opacity(opacity: opacidad, child: hijo),
        child: hijo,
      ),
    ),
    child: child,
  );
}

class _PintorDeLaCapa extends CustomPainter {
  _PintorDeLaCapa(this.capa)
    : super(
        repaint: Listenable.merge(<Listenable>[
          capa._fase,
          capa._escena,
          capa._opacidad,
        ]),
      );

  final _CapaDeArranqueState capa;

  @override
  void paint(Canvas canvas, Size size) {
    final opacidad = capa._opacidad.value;
    if (opacidad <= 0) return;
    final escena = capa._escena.value;
    if (opacidad < 1) {
      canvas.saveLayer(
        null,
        Paint()..color = Color.fromRGBO(0, 0, 0, opacidad),
      );
    }
    canvas.drawRect(Offset.zero & size, Paint()..color = naranjaDelSplash);
    if (escena != null) pintarEscena(canvas, escena);
    if (opacidad < 1) canvas.restore();
  }

  @override
  bool shouldRepaint(_PintorDeLaCapa oldDelegate) => oldDelegate.capa != capa;
}
```

  El fondo que va detrás de la página durante la salida es `colorScheme.surface`, el mismo del
  `Scaffold` de `HomePage` (`home_page.dart:114`).

- [ ] **Paso 6. Corre las pruebas y confirma que pasan.**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/pages/splash test/splash
"${FLUTTER:?}" test --no-pub test/splash
"${FLUTTER:?}" analyze --no-pub
```

Esperado. `All tests passed!` en `test/splash` y `6 issues found.`. Si la comparación del primer
cuadro pasa del 1 %, se revisa primero que la vista mida 1152 × 2560 píxeles y que la estrella
quede en (576, 1280), y nunca se sube la tolerancia.

- [ ] **Paso 7. Commit.**

```bash
cd "${REPO:?}"
git status --short
git add lib/pages/splash/arranque_page.dart lib/pages/splash/capa_de_arranque.dart test/splash/apoyo_splash.dart test/splash/splash_primer_cuadro_test.dart test/splash/splash_accesibilidad_test.dart test/splash/splash_arranque_test.dart
git commit -m "feat(splash): la capa permanente del arranque pinta el primer cuadro igual al nativo, se anuncia una vez y bloquea los toques mientras corre la entrada (RF-SPL-4, RF-SPL-5 y RF-SPL-15)"
git log -1 --format='%an <%ae>'
```

---

### Tarea 13. El final de la intro, la salida, el relevo, la espera y los fallos

**Requisitos.** De RF-SPL-4, que al terminar la entrada y la carga la capa navega sin transición,
espera el primer cuadro, mide la cabecera y reproduce la salida, y que un cambio de ruta durante
la salida termina en el fundido de 300 ms. RF-SPL-10, RF-SPL-12, RF-SPL-14 (decisión S-12),
RF-SPL-16 (decisión S-14), RF-SPL-17 (decisiones S-6, S-7 y S-17), RF-SPL-18 (decisión S-8) y
RF-SPL-21 en lo que toca a la capa (decisiones S-33 y S-34), con la salida de RF-SPL-11 montada
en la capa.

**Archivos.**
- Modificar `lib/pages/splash/capa_de_arranque.dart`.
- Modificar `test/splash/apoyo_splash.dart` (`HomeDePrueba` y `avanzar`).
- Modificar `test/splash/splash_arranque_test.dart` (grupo `el final de la intro`).
- Modificar `test/splash/splash_salida_test.dart` (grupo `la salida en la capa`).
- Crear `test/splash/splash_traspaso_test.dart`.
- Crear `test/splash/splash_reducir_movimiento_test.dart`.

**Interfaces.**
- Consume `salidaHaciaHome`, `pintarSalida` y `DestinoDeLaSalida` (Tarea 10),
  `offAllSinTransicion` y `offAllToLogin` (Tarea 11), `abrirEnHorario` (Tarea 6) y
  `PuntosDeAterrizaje` (Tarea 5).
- Produce, además de lo de la Tarea 12,
  `@visibleForTesting static EscenaDeSalida? get salidaActual` y `static double get opacidad`
  en `CapaDeArranque`.

- [ ] **Paso 1. Suma el apoyo.** Agrega a `test/splash/apoyo_splash.dart` estas declaraciones.

```dart
/// Una página /home que informa su cabecera después de su primer cuadro,
/// como AppHeader (RF-SPL-11), o que no la informa.
class HomeDePrueba extends StatefulWidget {
  const HomeDePrueba({super.key, this.informa = true});

  final bool informa;

  @override
  State<HomeDePrueba> createState() => _HomeDePruebaState();
}

class _HomeDePruebaState extends State<HomeDePrueba> {
  @override
  void initState() {
    super.initState();
    if (!widget.informa) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final oscuro = Theme.of(context).brightness == Brightness.dark;
      PuntosDeAterrizaje.cabecera.value = MedidaDeCabecera(
        cabecera: const Rect.fromLTWH(0, 0, 375, 102),
        estrella: const Rect.fromLTWH(20, 52, 26, 26),
        texto: const Rect.fromLTWH(56, 55, 90, 20),
        estilo: const TextStyle(
          fontSize: 20,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        escalaDeTexto: TextScaler.noScaling,
        color: oscuro
            ? const Color.fromARGB(255, 30, 30, 36)
            : const Color(0xFFFF6600),
        colorDelBorde: Theme.of(context).colorScheme.primaryContainer,
      );
    });
  }

  @override
  Widget build(BuildContext context) => const PaginaDePrueba('home');
}

/// Avanza [ms] en cuadros de 16 ms, como una pantalla de 60 Hz.
Future<void> avanzar(WidgetTester tester, int ms) async {
  for (var t = 0; t < ms; t += 16) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// Avanza en cuadros de 16 ms hasta que [condicion] se cumple o pasan
/// [tope] ms, y devuelve los ms que pasaron.
Future<int> avanzarHasta(
  WidgetTester tester,
  bool Function() condicion, {
  int tope = 10000,
}) async {
  var t = 0;
  while (!condicion() && t < tope) {
    await tester.pump(const Duration(milliseconds: 16));
    t += 16;
  }
  return t;
}

/// Cuenta las rutas que entran con cada nombre.
class ObservadorDeRutas extends NavigatorObserver {
  final List<String?> nombres = <String?>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      nombres.add(route.settings.name);
}
```

- [ ] **Paso 2. Escribe las pruebas que fallan.** En `test/splash/splash_arranque_test.dart`, suma
  estos imports y este grupo.

```dart
import 'package:ulima_plus/pages/splash/variantes/variantes.dart';
```

```dart
  group('el final de la intro (RF-SPL-4, RF-SPL-10, RF-SPL-17 y RF-SPL-18)',
      () {
    final hapticas = <String>[];

    setUp(() {
      reiniciarArranque();
      hapticas.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (llamada) async {
            if (llamada.method.startsWith('HapticFeedback')) {
              hapticas.add(llamada.method);
            }
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
      reiniciarArranque();
    });

    Future<CargaFalsa> montar(
      WidgetTester tester,
      VarianteSplash variante, {
      WidgetBuilder? home,
      List<NavigatorObserver> observadores = const [],
    }) async {
      telefono(tester);
      final carga = CargaFalsa();
      await tester.pumpWidget(
        appConCapa(
          intro: IntroDelArranque(
            carga: carga.call,
            variantes: VariantesFijas(variante),
            random: Random(1),
          ),
          home: home ?? (_) => const HomeDePrueba(),
          observadores: observadores,
        ),
      );
      return carga;
    }

    for (final tipo in VarianteSplash.values) {
      testWidgets('${tipo.name}: con la carga lista antes, la entrada se ve '
          'completa y la salida deja /home en Horario en 1,8 s o menos', (
        tester,
      ) async {
        final carga = await montar(tester, tipo);
        carga.terminar('/home');
        final v = varianteDe(tipo);
        final hasta = await avanzarHasta(
          tester,
          () => CapaDeArranque.fase == FaseDeLaCapa.inactiva,
        );
        expect(Get.currentRoute, '/home');
        expect(
          ModalRoute.of(tester.element(find.text('home')))!.settings.arguments,
          const {'pestana': 'horario'},
        );
        expect(hasta, greaterThanOrEqualTo(v.finDeLaEntrada + v.duracionDeLaSalida));
        // Más el primer cuadro de /home y su medida (RF-SPL-17).
        expect(hasta, lessThanOrEqualTo(1780 + 64));
        expect(EstadoDeLaCapa.cubre.value, isFalse);
        expect(hapticas, isEmpty, reason: 'sin háptica (S-14)');
      });
    }

    testWidgets('con la carga más larga, Incremento repite sus tics y la '
        'salida empieza al terminar la carga', (tester) async {
      final carga = await montar(tester, VarianteSplash.incremento);
      await avanzar(tester, 2100);
      expect(CapaDeArranque.fase, FaseDeLaCapa.intro);
      expect(CapaDeArranque.escenaActual!.giro, greaterThan(80 * grado));
      carga.terminar('/home');
      await avanzar(tester, 64);
      expect(
        CapaDeArranque.fase,
        anyOf(FaseDeLaCapa.esperandoCabecera, FaseDeLaCapa.salida),
      );
      await avanzar(tester, 700);
      expect(CapaDeArranque.fase, FaseDeLaCapa.inactiva);
    });

    testWidgets('un 401 durante la carga no navega ni avisa, y la intro llega '
        'una sola vez a la bienvenida (S-20)', (tester) async {
      final rutas = ObservadorDeRutas();
      telefono(tester);
      await tester.pumpWidget(
        appConCapa(
          intro: IntroDelArranque(
            carga: () async {
              await Future<void>.delayed(const Duration(milliseconds: 100));
              // Lo que hace el interceptor de ApiClient con un 401 durante
              // la carga, con /arranque como ruta actual.
              expect(offAllToLogin(), isFalse);
              return '/login';
            },
            variantes: VariantesFijas(VarianteSplash.ensamble),
            random: Random(1),
          ),
          observadores: [rutas],
        ),
      );
      await avanzarHasta(tester, () => CapaDeArranque.fase == FaseDeLaCapa.inactiva);
      expect(rutas.nombres.where((n) => n == '/login'), hasLength(1));
      expect(Get.isSnackbarOpen, isFalse);
    });

    testWidgets('un fallo antes de registrar los servicios deja la intro en su '
        'bucle y lo registra (RF-SPL-18)', (tester) async {
      final registro = <String>[];
      final anterior = debugPrint;
      debugPrint = (String? m, {int? wrapWidth}) => registro.add(m ?? '');
      addTearDown(() => debugPrint = anterior);
      final carga = await montar(tester, VarianteSplash.ensamble);
      carga.fallar(const FalloAntesDeLosServicios('sin Firebase'));
      await avanzar(tester, 5000);
      expect(CapaDeArranque.fase, FaseDeLaCapa.intro);
      expect(EstadoDeLaCapa.cubre.value, isTrue);
      expect(registro.join(), contains('sin Firebase'));
    });

    testWidgets('un fallo después de registrarlos hace el relevo a la '
        'bienvenida', (tester) async {
      final carga = await montar(tester, VarianteSplash.codigo);
      carga.fallar(StateError('almacén de claves'));
      await avanzarHasta(tester, () => CapaDeArranque.fase == FaseDeLaCapa.inactiva);
      expect(Get.currentRoute, '/login');
    });

    testWidgets('si la cabecera no se mide, la salida es un fundido de 300 ms',
        (tester) async {
      final carga = await montar(
        tester,
        VarianteSplash.ensamble,
        home: (_) => const HomeDePrueba(informa: false),
      );
      carga.terminar('/home');
      await avanzarHasta(tester, () => CapaDeArranque.fase == FaseDeLaCapa.fundido);
      final desde = await avanzarHasta(
        tester,
        () => CapaDeArranque.fase == FaseDeLaCapa.inactiva,
      );
      expect(desde, inInclusiveRange(290, 340));
    });

    testWidgets('si la ruta de debajo cambia durante la salida, termina con el '
        'fundido de 300 ms', (tester) async {
      final carga = await montar(tester, VarianteSplash.incremento);
      carga.terminar('/home');
      await avanzarHasta(tester, () => CapaDeArranque.fase == FaseDeLaCapa.salida);
      await avanzar(tester, 100);
      expect(offAllToLogin(), isTrue);
      await avanzar(tester, 32);
      expect(CapaDeArranque.fase, FaseDeLaCapa.fundido);
      await avanzar(tester, 400);
      expect(CapaDeArranque.fase, FaseDeLaCapa.inactiva);
    });
  });
```

  En `test/splash/splash_salida_test.dart`, suma estos imports y este grupo.

```dart
import 'dart:math';

import 'package:get/get.dart';
import 'package:ulima_plus/pages/splash/capa_de_arranque.dart';
import 'package:ulima_plus/services/splash_variante_service.dart';

import 'apoyo_splash.dart';
```

```dart
  group('la salida en la capa (RF-SPL-11 y RF-SPL-13)', () {
    setUp(reiniciarArranque);
    tearDown(reiniciarArranque);

    for (final modo in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('la página sube y aparece como un todo sobre el fondo del '
          'tema, y el panel termina en el headerColor (${modo.name})', (
        tester,
      ) async {
        telefono(tester);
        final carga = CargaFalsa();
        await tester.pumpWidget(
          appConCapa(
            intro: IntroDelArranque(
              carga: carga.call,
              variantes: VariantesFijas(VarianteSplash.ensamble),
              random: Random(1),
            ),
            home: (_) => const HomeDePrueba(),
            modo: modo,
          ),
        );
        carga.terminar('/home');
        await avanzarHasta(tester, () => CapaDeArranque.fase == FaseDeLaCapa.salida);
        await avanzar(tester, 265);
        final medio = CapaDeArranque.salidaActual!;
        expect(medio.paginaDy, inExclusiveRange(0, 20));
        final corrida = tester.widget<Transform>(
          find
              .ancestor(of: find.text('home'), matching: find.byType(Transform))
              .last,
        );
        expect(corrida.transform.getTranslation().y, closeTo(medio.paginaDy, 1e-6));
        await avanzar(tester, 250);
        final ultimo = CapaDeArranque.salidaActual;
        final esperado = modo == ThemeMode.dark
            ? const Color.fromARGB(255, 30, 30, 36)
            : const Color(0xFFFF6600);
        if (ultimo != null) {
          expect(ultimo.colorDelPanel.r, closeTo(esperado.r, 0.02));
          expect(ultimo.colorDelPanel.g, closeTo(esperado.g, 0.02));
          expect(ultimo.colorDelPanel.b, closeTo(esperado.b, 0.02));
        }
        await avanzarHasta(tester, () => CapaDeArranque.fase == FaseDeLaCapa.inactiva);
        expect(Get.currentRoute, '/home');
      });
    }
  });
```

  Crea `test/splash/splash_traspaso_test.dart`.

```dart
// test/splash/splash_traspaso_test.dart
//
// WIDGET · Splash animado (specs/features/splash/splash.spec.md).
// RF-SPL-21 y RF-SPL-12. Sin sesión, y con la sesión de un alumno sin
// especialidad, la intro no tiene salida. El logo queda en la pose de su
// variante, la intro llega a /login por offAllToLogin con la pose como
// argumento, y la capa se retira sin fundido cuando la bienvenida pinta su
// primer cuadro. La capa queda montada e inactiva, lista para el paso al
// horario de la bienvenida.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/logo/escena_del_logo.dart';
import 'package:ulima_plus/pages/splash/capa_de_arranque.dart';
import 'package:ulima_plus/pages/splash/estado_de_la_capa.dart';
import 'package:ulima_plus/pages/splash/variantes/variantes.dart';
import 'package:ulima_plus/services/session_navigation.dart';
import 'package:ulima_plus/services/splash_variante_service.dart';

import 'apoyo_splash.dart';

PoseDelLogo _poseRecibida() =>
    (BienvenidaDePrueba.argumentos! as Map)[argumentoDePose] as PoseDelLogo;

void _igualAPose(PoseDelLogo real, PoseDelLogo esperada) {
  expect(real.centro.dx, closeTo(esperada.centro.dx, 1e-6));
  expect(real.centro.dy, closeTo(esperada.centro.dy, 1e-6));
  expect(real.radio, closeTo(esperada.radio, 1e-6));
  expect(real.cruces, hasLength(2));
  for (var i = 0; i < 2; i++) {
    expect(real.cruces[i].centro.dx, closeTo(esperada.cruces[i].centro.dx, 1e-6));
    expect(real.cruces[i].centro.dy, closeTo(esperada.cruces[i].centro.dy, 1e-6));
    expect(real.cruces[i].escala, closeTo(esperada.cruces[i].escala, 1e-6));
  }
}

void main() {
  setUp(reiniciarArranque);
  tearDown(reiniciarArranque);

  Future<CargaFalsa> montar(WidgetTester tester, VarianteSplash tipo) async {
    telefono(tester);
    final carga = CargaFalsa();
    await tester.pumpWidget(
      appConCapa(
        intro: IntroDelArranque(
          carga: carga.call,
          variantes: VariantesFijas(tipo),
          random: Random(1),
        ),
      ),
    );
    return carga;
  }

  for (final ruta in ['/login', '/setup-carrera']) {
    for (final tipo in VarianteSplash.values) {
      testWidgets('${tipo.name} hacia $ruta: la bienvenida recibe la pose del '
          'reposo, sin salida y sin transición', (tester) async {
        final carga = await montar(tester, tipo);
        carga.terminar(ruta);
        final v = varianteDe(tipo);
        await avanzarHasta(tester, () => Get.currentRoute == '/login');
        final esperada = v
            .escena(
              v.finDelReposo(0),
              centro: const Offset(187.5, 333.5),
              radio: 90,
              cargaLista: 0,
            )
            .pose;
        _igualAPose(_poseRecibida(), esperada);
        expect(CapaDeArranque.fase, anyOf(FaseDeLaCapa.relevo, FaseDeLaCapa.inactiva));
        expect(CapaDeArranque.salidaActual, isNull, reason: 'sin salida');
      });
    }
  }

  testWidgets('la capa se retira sin fundido cuando la bienvenida pinta su '
      'primer cuadro, y queda montada e inactiva', (tester) async {
    final semantica = tester.ensureSemantics();
    final carga = await montar(tester, VarianteSplash.ensamble);
    carga.terminar('/login');
    final opacidades = <double>[];
    await avanzarHasta(tester, () {
      opacidades.add(CapaDeArranque.opacidad);
      return CapaDeArranque.fase == FaseDeLaCapa.inactiva;
    });
    expect(opacidades.every((o) => o == 1), isTrue, reason: 'sin fundido');
    expect(find.byType(CapaDeArranque), findsOneWidget);
    expect(EstadoDeLaCapa.cubre.value, isFalse);
    expect(find.bySemanticsLabel(etiquetaDeLaIntro), findsNothing);
    await tester.tap(find.text('bienvenida'));
    expect(toquesEnLaPagina, 1);
    expect(
      find.descendant(
        of: find.byType(CapaDeArranque),
        matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
      ),
      findsNothing,
      reason: 'inactiva no fija la barra de estado',
    );
    semantica.dispose();
  });

  testWidgets('si la carga termina en el bucle, Ensamble vuelve al reposo en '
      '300 ms antes del relevo (S-34)', (tester) async {
    final carga = await montar(tester, VarianteSplash.ensamble);
    await avanzar(tester, 2000);
    carga.terminar('/login');
    final hasta = await avanzarHasta(tester, () => Get.currentRoute == '/login');
    expect(hasta, inInclusiveRange(280, 360));
    final pose = _poseRecibida();
    expect(pose.cruces[0].escala, closeTo(1, 1e-6));
  });
}
```

  Crea `test/splash/splash_reducir_movimiento_test.dart`.

```dart
// test/splash/splash_reducir_movimiento_test.dart
//
// WIDGET · Splash animado (specs/features/splash/splash.spec.md).
// RF-SPL-14. Con «reducir movimiento» no hay variante, la estrella queda
// fija, los «++» aparecen con un fundido de 200 ms y la capa se desvanece en
// 250 ms sobre /home. Hacia la bienvenida se retira sin fundido.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ulima_plus/pages/splash/capa_de_arranque.dart';
import 'package:ulima_plus/services/splash_variante_service.dart';

import 'apoyo_splash.dart';

void main() {
  setUp(reiniciarArranque);
  tearDown(reiniciarArranque);

  Future<(CargaFalsa, VariantesFijas)> montar(WidgetTester tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    SharedPreferences.setMockInitialValues(<String, Object>{});
    telefono(tester);
    final carga = CargaFalsa();
    final variantes = VariantesFijas(VarianteSplash.ensamble);
    await tester.pumpWidget(
      appConCapa(
        intro: IntroDelArranque(
          carga: carga.call,
          variantes: variantes,
          random: Random(1),
        ),
        home: (_) => const HomeDePrueba(),
      ),
    );
    return (carga, variantes);
  }

  testWidgets('no hay variante, nada se mueve y los «++» aparecen en 200 ms',
      (tester) async {
    final (_, variantes) = await montar(tester);
    expect(
      CapaDeArranque.escenaActual!.cruces.every((c) => c.opacidad == 0),
      isTrue,
    );
    await avanzar(tester, 100);
    expect(variantes.lecturas, 0, reason: 'ni se lee ni se escribe la clave');
    final medio = CapaDeArranque.escenaActual!;
    expect(medio.cruces.first.opacidad, inExclusiveRange(0, 1));
    expect(medio.cruces.first.escala, 1);
    await avanzar(tester, 1500);
    final quieta = CapaDeArranque.escenaActual!;
    expect(quieta.cruces.every((c) => c.opacidad == 1), isTrue);
    expect(quieta.giro, 0);
    expect(quieta.rombos.every((r) => r.desplazamiento == 0), isTrue);
    expect(quieta.centro, const Offset(187.5, 333.5));
  });

  testWidgets('con la carga lista navega a /home y la capa se desvanece en '
      '250 ms', (tester) async {
    final (carga, _) = await montar(tester);
    await avanzar(tester, 300);
    carga.terminar('/home');
    await avanzarHasta(tester, () => CapaDeArranque.fase == FaseDeLaCapa.fundido);
    expect(Get.currentRoute, '/home');
    final dura = await avanzarHasta(
      tester,
      () => CapaDeArranque.fase == FaseDeLaCapa.inactiva,
    );
    expect(dura, inInclusiveRange(240, 290));
  });

  testWidgets('hacia la bienvenida la capa se retira sin fundido', (
    tester,
  ) async {
    final (carga, _) = await montar(tester);
    await avanzar(tester, 300);
    carga.terminar('/login');
    final opacidades = <double>[];
    await avanzarHasta(tester, () {
      opacidades.add(CapaDeArranque.opacidad);
      return CapaDeArranque.fase == FaseDeLaCapa.inactiva;
    });
    expect(opacidades.every((o) => o == 1), isTrue);
    expect(Get.currentRoute, '/login');
  });
}
```

- [ ] **Paso 3. Corre las pruebas y confirma que fallan.**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/splash
```

Esperado. Falla la compilación, porque `CapaDeArranque.salidaActual`, `CapaDeArranque.opacidad` y
`HomeDePrueba` todavía no existen del lado de la capa. Con esos dos getters escritos, las pruebas
fallan porque la capa nunca navega y se queda en `FaseDeLaCapa.intro`.

- [ ] **Paso 4. Termina la intro en la capa.** En `lib/pages/splash/capa_de_arranque.dart`, haz
  estos cambios.

  1. Suma los imports.

```dart
import 'package:get/get.dart';

import '../../services/session_navigation.dart';
import '../home/home_page.dart' show abrirEnHorario;
import 'puntos_de_aterrizaje.dart';
```

  2. Suma a `CapaDeArranque` estos getters.

```dart
  @visibleForTesting
  static EscenaDeSalida? get salidaActual => _estado?._salida.value;

  /// La opacidad de lo que pinta la capa, que solo baja en un fundido.
  static double get opacidad => _estado?._opacidad.value ?? 1;
```

  3. Suma estos campos al `State`, después de `_centro` y `_vista`.

```dart
  final ValueNotifier<EscenaDeSalida?> _salida = ValueNotifier<EscenaDeSalida?>(
    null,
  );
  bool _sinMovimiento = false;

  /// Los ms de la intro en que terminó la carga, y la ruta que devolvió.
  double? _cargaLista;
  String? _destino;

  Duration _inicioDeFase = Duration.zero;
  int _cuadrosEsperando = 0;
  double _msInicioDeSalida = 0;
  DestinoDeLaSalida? _destinoDeLaSalida;
  double _duracionDelFundido = 300;

  bool get _haciaHome => _destino == '/home';

  double get _msDeFase => (_ahora - _inicioDeFase).inMicroseconds / 1000;
```

  4. En `didChangeDependencies`, lee reducir movimiento antes de elegir la variante. La línea
     `_preparada = true;` pasa a ser estas dos.

```dart
    _preparada = true;
    _sinMovimiento = MediaQuery.disableAnimationsOf(context);
```

  5. Reemplaza `_empezarLaCarga`, `_elegirVariante`, `_alTic` y `_alPintarLaBienvenida` por esto,
     y suma los métodos que siguen.

```dart
  /// La carga corre en paralelo con la intro desde el montaje (RF-SPL-4).
  void _empezarLaCarga() {
    unawaited(
      widget.intro!.carga().then(_alCargar, onError: _alFallarLaCarga),
    );
  }

  void _alCargar(String ruta) {
    if (!mounted) return;
    _destino = ruta;
    _cargaLista = _ms;
  }

  /// Antes de registrar los servicios no hay ruta segura y la intro sigue en
  /// su bucle, como hoy queda quieto el nativo. Después, la intro hace el
  /// relevo a la bienvenida sin borrar nada (RF-SPL-18).
  void _alFallarLaCarga(Object error, StackTrace pila) {
    debugPrint('Arranque. La carga falló con $error');
    if (error is FalloAntesDeLosServicios) return;
    _alCargar('/login');
  }

  Future<void> _elegirVariante() async {
    if (_sinMovimiento) {
      // Sin variante, y sin leer ni escribir la preferencia (RF-SPL-14).
      _inicioDeLaIntro = _ahora;
      _fase.value = FaseDeLaCapa.intro;
      return;
    }
    final intro = widget.intro!;
    final tipo = await intro.variantes.elegir(intro.random);
    if (!mounted || _fase.value != FaseDeLaCapa.eligiendo) return;
    _variante = varianteDe(tipo);
    _inicioDeLaIntro = _ahora;
    _fase.value = FaseDeLaCapa.intro;
  }

  void _alTic(Duration transcurrido) {
    _ahora = transcurrido;
    switch (_fase.value) {
      case FaseDeLaCapa.intro:
        _avanzarLaIntro();
      case FaseDeLaCapa.esperandoCabecera:
        _esperarLaCabecera();
      case FaseDeLaCapa.salida:
        _avanzarLaSalida();
      case FaseDeLaCapa.fundido:
        _avanzarElFundido();
      case FaseDeLaCapa.relevo:
        // Si la bienvenida no avisa en 500 ms, la capa se retira igual.
        if (_msDeFase > 500) _retirar();
      case FaseDeLaCapa.inactiva:
      case FaseDeLaCapa.eligiendo:
      case FaseDeLaCapa.pasoAlHorario:
        break;
    }
  }

  void _avanzarLaIntro() {
    final ms = _ms;
    if (_sinMovimiento) {
      // La estrella fija y los «++» con un fundido de 200 ms (RF-SPL-14).
      _escena.value = EscenaDelLogo(
        centro: _centro,
        radio: radioDelNativo,
        cruces: <CruzEnEscena>[
          for (final c in EscenaDelLogo.crucesEnReposo())
            c.copyWith(opacidad: (ms / 200).clamp(0.0, 1.0).toDouble()),
        ],
      );
      if (_destino != null && ms >= 200) _terminarLaIntro();
      return;
    }
    final v = _variante!;
    // Hacia /home el bucle sigue hasta que empieza la salida. Hacia la
    // bienvenida la variante vuelve al reposo desde la carga (S-34).
    _escena.value = v.escena(
      ms,
      centro: _centro,
      radio: radioDelNativo,
      cargaLista: _haciaHome ? null : _cargaLista,
    );
    if (_destino == null) return;
    final lista = _haciaHome
        ? ms >= v.finDeLaEntrada
        : ms >= v.finDelReposo(_cargaLista);
    if (lista) _terminarLaIntro();
  }

  void _terminarLaIntro() {
    if (_haciaHome) {
      PuntosDeAterrizaje.cabecera.value = null;
      if (!offAllSinTransicion('/home', arguments: abrirEnHorario)) {
        _retirar();
        return;
      }
      if (_sinMovimiento) {
        _empezarElFundido(250);
        return;
      }
      _cuadrosEsperando = 0;
      _fase.value = FaseDeLaCapa.esperandoCabecera;
      return;
    }
    // Sin sesión, o con la de un alumno sin especialidad, no hay salida y
    // la bienvenida toma el relevo con la pose (RF-SPL-12 y RF-SPL-21).
    unawaited(
      precacheImage(
        const AssetImage('assets/images/ulises_chatbot.png'),
        context,
      ).catchError((Object _) {}),
    );
    final pose = _escena.value!.pose;
    _inicioDeFase = _ahora;
    _fase.value = FaseDeLaCapa.relevo;
    if (!offAllToLogin(pose: pose, desdeLaIntro: true)) _retirar();
  }

  /// Espera el primer cuadro de /home y la medida de su cabecera, a lo sumo
  /// tres cuadros (decisión 5 del plan). La variante sigue su bucle.
  void _esperarLaCabecera() {
    _escena.value = _variante!.escena(
      _ms,
      centro: _centro,
      radio: radioDelNativo,
    );
    final medida = PuntosDeAterrizaje.cabecera.value;
    if (medida != null && Get.currentRoute == '/home') {
      _destinoDeLaSalida = DestinoDeLaSalida.desdeMedida(medida, _vista);
      _msInicioDeSalida = _ms;
      _inicioDeFase = _ahora;
      _fase.value = FaseDeLaCapa.salida;
      _avanzarLaSalida();
      return;
    }
    _cuadrosEsperando++;
    if (_cuadrosEsperando > 3) _empezarElFundido(300);
  }

  void _avanzarLaSalida() {
    final v = _variante!;
    if (Get.currentRoute != '/home') {
      // La ruta de debajo cambió, por ejemplo por un 401 (RF-SPL-4).
      _empezarElFundido(300);
      return;
    }
    final ms = _msDeFase;
    final s = salidaHaciaHome(
      variante: v,
      msInicio: _msInicioDeSalida,
      msEnSalida: ms,
      centroDelMarco: _centro,
      radioDelMarco: radioDelNativo,
      destino: _destinoDeLaSalida!,
    );
    _salida.value = s;
    _corrimientoDeLaPagina.value = Offset(0, s.paginaDy);
    _opacidadDeLaPagina.value = s.paginaOpacidad;
    if (ms >= v.duracionDeLaSalida) _retirar();
  }

  void _empezarElFundido(double duracion) {
    _duracionDelFundido = duracion;
    _inicioDeFase = _ahora;
    _corrimientoDeLaPagina.value = Offset.zero;
    _opacidadDeLaPagina.value = 1;
    _fase.value = FaseDeLaCapa.fundido;
  }

  void _avanzarElFundido() {
    final ms = _msDeFase;
    _opacidad.value = (1 - ms / _duracionDelFundido).clamp(0.0, 1.0).toDouble();
    if (ms >= _duracionDelFundido) _retirar();
  }

  void _alPintarLaBienvenida() {
    if (_fase.value == FaseDeLaCapa.relevo) _retirar();
  }

  /// La capa queda inactiva, sin pintar, sin bloquear toques y fuera de la
  /// semántica, pero montada (RF-SPL-4).
  void _retirar() {
    _reloj.stop();
    _salida.value = null;
    _opacidad.value = 1;
    _corrimientoDeLaPagina.value = Offset.zero;
    _opacidadDeLaPagina.value = 1;
    _fase.value = FaseDeLaCapa.inactiva;
    EstadoDeLaCapa.cubre.value = false;
  }
```

  6. En `_PintorDeLaCapa`, suma `capa._salida` a la lista de `Listenable.merge` y reemplaza
     `paint` por este.

```dart
  @override
  void paint(Canvas canvas, Size size) {
    final opacidad = capa._opacidad.value;
    if (opacidad <= 0) return;
    if (opacidad < 1) {
      canvas.saveLayer(
        null,
        Paint()..color = Color.fromRGBO(0, 0, 0, opacidad),
      );
    }
    final salida = capa._salida.value;
    final destino = capa._destinoDeLaSalida;
    if (salida != null && destino != null) {
      // La salida, o su fundido si la ruta cambió en medio.
      pintarSalida(canvas, salida, destino);
    } else {
      canvas.drawRect(Offset.zero & size, Paint()..color = naranjaDelSplash);
      final escena = capa._escena.value;
      if (escena != null) pintarEscena(canvas, escena);
    }
    if (opacidad < 1) canvas.restore();
  }
```

- [ ] **Paso 5. Corre las pruebas y confirma que pasan.**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/pages/splash test/splash
"${FLUTTER:?}" test --no-pub test/splash
"${FLUTTER:?}" analyze --no-pub
```

Esperado. `All tests passed!` en `test/splash` y `6 issues found.`. Si una prueba de tiempos cae
fuera de su rango por uno o dos cuadros de 16 ms, se revisa primero en qué cuadro arranca cada
fase, porque la spec cuenta la entrada desde que la variante está elegida y la salida desde que
la cabecera está medida.

- [ ] **Paso 6. Suite completa y commit.** Corre la suite completa en segundo plano. Esperado,
  `All tests passed!`.

```bash
cd "${REPO:?}"
git status --short
git add lib/pages/splash/capa_de_arranque.dart test/splash
git commit -m "feat(splash): la intro termina en la salida hacia /home o en el relevo sin salto a la bienvenida, espera la carga en su bucle y sobrevive a sus fallos (RF-SPL-10 a RF-SPL-18 y RF-SPL-21)"
git log -1 --format='%an <%ae>'
```

---

### Tarea 14. `runApp` inmediato, la carga en paralelo y el README del arranque

**Requisitos.** De RF-SPL-4, `runApp` justo después del bloqueo en vertical, la carga como función
que devuelve la ruta (decisión S-7), `/arranque` con la capa en el `builder`, las `GetPage`
declaradas una sola vez y el arranque de hoy en web (decisión S-22), con la ruta inicial del
alumno sin especialidad en `/login` (RF-SPL-12). La sección «El arranque» del README.

**Archivos.**
- Crear `lib/pages/splash/carga_del_arranque.dart`.
- Modificar `lib/main.dart:62-285`.
- Modificar `test/splash/splash_arranque_test.dart` (grupo `la carga y main`).
- Modificar `README.md` («El arranque»).

**Interfaces.**
- Consume la capa de las Tareas 12 y 13, `SplashVarianteService` (Tarea 4) y `rutaDelArranque`
  (Tarea 11).
- Produce estas firmas, que usa la Tarea 29.

```dart
// carga_del_arranque.dart
Future<String> cargarElArranque({Future<void> Function()? iniciarFirebase});
void registrarLosServicios();
String rutaInicialEnWeb(String ruta);
// main.dart
final List<GetPage<dynamic>> paginasDeLaApp;
class MyApp extends StatelessWidget { const MyApp({String initialRoute = rutaDelArranque,
  IntroDelArranque? intro}); }
```

- [ ] **Paso 1. Escribe la prueba que falla.** En `test/splash/splash_arranque_test.dart`, suma
  estos imports y este grupo.

```dart
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ulima_plus/main.dart';
import 'package:ulima_plus/pages/splash/arranque_page.dart';
import 'package:ulima_plus/pages/splash/carga_del_arranque.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';
import 'package:ulima_plus/services/storage_service.dart';
```

```dart
  group('la carga y main (RF-SPL-4, RF-SPL-12 y RF-SPL-18)', () {
    setUp(reiniciarArranque);
    tearDown(reiniciarArranque);

    test('un fallo de Firebase o del almacén es un fallo antes de los '
        'servicios', () async {
      await expectLater(
        cargarElArranque(
          iniciarFirebase: () async => throw StateError('sin Firebase'),
        ),
        throwsA(isA<FalloAntesDeLosServicios>()),
      );
      expect(Get.isRegistered<AuthService>(), isFalse);
    });

    test('sin sesión guardada registra los servicios y devuelve /login, sin '
        'red', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
      final ruta = await cargarElArranque(iniciarFirebase: () async {});
      expect(ruta, '/login');
      expect(Get.isRegistered<StorageService>(), isTrue);
      expect(Get.isRegistered<AuthService>(), isTrue);
      // El servicio del test de especialidad llega con fcbf2e7 y sigue
      // registrado, ahora desde la carga.
      expect(Get.isRegistered<SpecialtyTestService>(), isTrue);
    });

    test('la carga ya no pide las alertas, que pide el home al montarse '
        '(S-7)', () {
      final fuente = File(
        'lib/pages/splash/carga_del_arranque.dart',
      ).readAsStringSync();
      expect(fuente, isNot(contains('fetchAlerts')));
    });

    test('en web, el alumno sin especialidad arranca en /login', () {
      expect(rutaInicialEnWeb('/setup-carrera'), '/login');
      expect(rutaInicialEnWeb('/home'), '/home');
      expect(rutaInicialEnWeb('/login'), '/login');
    });

    test('las GetPage se declaran una sola vez, con /arranque y las rutas del '
        'test de especialidad', () {
      final nombres = paginasDeLaApp.map((p) => p.name).toList();
      expect(nombres.toSet(), hasLength(nombres.length));
      expect(
        nombres,
        containsAll(<String>[
          rutaDelArranque,
          '/home',
          '/login',
          '/setup-carrera',
          '/test-especialidad',
        ]),
      );
    });

    testWidgets('fuera de web la app arranca en /arranque con la capa activa',
        (tester) async {
      telefono(tester);
      await tester.pumpWidget(
        MyApp(
          intro: IntroDelArranque(
            carga: CargaFalsa().call,
            variantes: VariantesFijas(VarianteSplash.ensamble),
            random: Random(1),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ArranquePage), findsOneWidget);
      expect(find.byType(CapaDeArranque), findsOneWidget);
      expect(CapaDeArranque.fase, isNot(FaseDeLaCapa.inactiva));
    });
  });
```

- [ ] **Paso 2. Corre la prueba y confirma que falla.**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/splash/splash_arranque_test.dart
```

Esperado. Falla la compilación, porque `carga_del_arranque.dart`, `paginasDeLaApp` y el
parámetro `intro` de `MyApp` no existen.

- [ ] **Paso 3. Escribe la carga.** Crea `lib/pages/splash/carga_del_arranque.dart`.

```dart
// lib/pages/splash/carga_del_arranque.dart
// La carga del arranque como una función que devuelve la ruta de destino y
// corre en paralelo con la intro (RF-SPL-4). Da los mismos pasos que el
// main() de antes y en el mismo orden, salvo las alertas del alumno, que
// pide HomeController al montarse (decisión S-7). Un fallo antes de registrar
// los servicios deja la intro en su bucle (RF-SPL-18).

import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../firebase_options.dart';
import '../../services/academic_record_service.dart';
import '../../services/alert_service.dart';
import '../../services/auth_service.dart';
import '../../services/malla_service.dart';
import '../../services/post_login_route.dart';
import '../../services/specialty_test_service.dart';
import '../../services/storage_service.dart';
import '../../services/time_blocks_service.dart';
import 'capa_de_arranque.dart';

Future<void> _iniciarFirebase() =>
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

Future<String> cargarElArranque({
  Future<void> Function()? iniciarFirebase,
}) async {
  try {
    await (iniciarFirebase ?? _iniciarFirebase)();
    LucideIcons.info.codePoint;
    await Get.putAsync<StorageService>(
      () => StorageService().init(),
      permanent: true,
    );
  } catch (error) {
    throw FalloAntesDeLosServicios(error);
  }
  registrarLosServicios();
  final restaurada = await AuthService.to.tryRestoreSession();
  if (!restaurada) return '/login';
  return postLoginRoute(AuthService.to.currentUser!);
}

/// Los servicios globales permanentes, en el orden de siempre.
void registrarLosServicios() {
  Get.put<AuthService>(AuthService(), permanent: true);
  Get.put<AlertService>(AlertService(), permanent: true);
  Get.put<MallaService>(MallaService(), permanent: true);
  // Estado único del récord (RF-REC-5), compartido por la tarjeta del Perfil
  // y /mi-record. No carga nada al arrancar.
  Get.put<AcademicRecordService>(AcademicRecordService(), permanent: true);
  // Estado único de los bloques de horario propios (RF-BLQ-7). Tampoco carga
  // nada al arrancar.
  Get.put<TimeBlocksService>(TimeBlocksService(), permanent: true);
  // Capa de datos del test de especialidad (RF-TEST-2). Permanente porque
  // guarda en memoria la copia del contenido de la sesión, un test en pausa
  // y el último resultado. Tampoco carga nada al arrancar.
  Get.put<SpecialtyTestService>(SpecialtyTestService(), permanent: true);
}

/// En web no hay intro y la ruta inicial es la de la carga, salvo el alumno
/// sin especialidad, que arranca en la bienvenida (RF-SPL-12 y S-22).
String rutaInicialEnWeb(String ruta) =>
    ruta == '/setup-carrera' ? '/login' : ruta;
```

  El registro de `SpecialtyTestService`, que `main()` trae desde `fcbf2e7`, pasa a
  `registrarLosServicios` en el mismo lugar, después de `TimeBlocksService` y con su comentario.

- [ ] **Paso 4. Cambia `main.dart`.** Haz estos cambios en `lib/main.dart`.

  1. Suma estos imports y quita los que dejan de usarse en `main.dart`, que pasan a la carga.
     Son `package:firebase_core/firebase_core.dart`, `package:lucide_icons_flutter/lucide_icons.dart`,
     `/firebase_options.dart`, `/services/malla_service.dart`,
     `/services/academic_record_service.dart`, `/services/time_blocks_service.dart`,
     `/services/specialty_test_service.dart`, `/services/post_login_route.dart` y
     `/services/storage_service.dart`. Se quedan
     `/services/auth_service.dart` y `/services/alert_service.dart`, que usa el arranque de web.

```dart
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'pages/splash/arranque_page.dart';
import 'pages/splash/capa_de_arranque.dart';
import 'pages/splash/carga_del_arranque.dart';
import 'services/session_navigation.dart';
import 'services/splash_variante_service.dart';
```

  2. Reemplaza `main()` (`main.dart:62-111`) por este.

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
  if (kIsWeb) {
    // En web no hay intro y el arranque sigue en el orden de siempre, porque
    // una recarga en /#/home construiría HomePage antes que los servicios
    // (S-22). El único cambio es la ruta del alumno sin especialidad.
    final ruta = await cargarElArranque();
    final user = AuthService.to.currentUser;
    if (user != null && !user.isTeacher) {
      try {
        await AlertService.to.fetchAlerts();
      } catch (e) {
        debugPrint('Error loading alerts at startup: $e');
      }
    }
    runApp(MyApp(initialRoute: rutaInicialEnWeb(ruta)));
    return;
  }
  // runApp enseguida, y la carga corre en paralelo con la intro (RF-SPL-4).
  runApp(
    MyApp(
      intro: IntroDelArranque(
        carga: cargarElArranque,
        variantes: SplashVarianteService(),
        random: Random(),
      ),
    ),
  );
}
```

  3. Saca la lista de `getPages` de `MyApp.build` a una variable de nivel superior, con la ruta
     `/arranque` al principio, y cambia `MyApp` así.

```dart
/// Las rutas de la app, declaradas una sola vez. La intro y la bienvenida
/// toman de aquí el page y el binding de /home y /login para navegar sin
/// transición (RF-SPL-4).
final List<GetPage<dynamic>> paginasDeLaApp = <GetPage<dynamic>>[
  GetPage(name: rutaDelArranque, page: () => const ArranquePage()),
  // Las demás GetPage siguen igual que hoy (main.dart:137-281), en el mismo
  // orden y con los mismos comentarios, desde '/login' hasta '/mis-bloques',
  // con '/setup-carrera' y SetupCarreraBinding y '/test-especialidad' y
  // SpecialtyTestBinding.
];

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.initialRoute = rutaDelArranque, this.intro});

  final String initialRoute;

  /// La intro del splash, o null en web (S-22).
  final IntroDelArranque? intro;

  @override
  Widget build(BuildContext context) {
    final materialTheme = MaterialTheme(Theme.of(context).textTheme);
    return GetMaterialApp(
      title: 'ULIMA++',
      theme: materialTheme.light(),
      darkTheme: materialTheme.dark(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      // Física de scroll uniforme en TODA la app (ver AppScrollBehavior).
      scrollBehavior: const AppScrollBehavior(),
      initialRoute: initialRoute,
      // La capa del arranque es una pieza fija del builder, montada en todas
      // las plataformas. En web queda inactiva desde el principio (RF-SPL-4).
      builder: (context, child) =>
          CapaDeArranque(intro: intro, child: child ?? const SizedBox.shrink()),
      getPages: paginasDeLaApp,
    );
  }
}
```

  El comentario de «Física de scroll uniforme» es el de hoy (`main.dart:126-128`), completo. Las
  veinte `GetPage` de `/login` a `/mis-bloques` se copian tal cual a `paginasDeLaApp`, con sus
  comentarios, también las de `/setup-carrera` y `/test-especialidad` con sus bindings, y el bloque
  de `GetMaterialApp` pierde el suyo. `AppScrollBehavior` no cambia.

- [ ] **Paso 5. Reescribe «El arranque» del README.** En `README.md`, reemplaza el texto que va
  desde el párrafo «`main()` es `async` y hace doce cosas…» hasta el final de la tabla de doce
  pasos (`README.md:130-145`) por este. El bloque de código de `MyApp` que sigue se actualiza con
  el `builder` y `paginasDeLaApp`.

```markdown
Desde el splash animado (`specs/features/splash/splash.spec.md`), `main()` llama a `runApp` apenas
bloquea la vertical, y la carga de hoy corre en paralelo con la intro en
`lib/pages/splash/carga_del_arranque.dart`. La app se ve antes, porque el primer cuadro ya no espera
la red, y la intro decide adónde ir cuando terminan su entrada y la carga.

| # | Paso | Dónde | Por qué |
|---:|:---|:---|:---|
| 1 | `WidgetsFlutterBinding.ensureInitialized()` | `main()` | Requisito previo a tocar canales de plataforma. |
| 2 | `SystemChrome.setPreferredOrientations([portraitUp])` | `main()` | La app arranca bloqueada en vertical, y Horario habilita la horizontal. |
| 3 | `runApp(MyApp(intro: …))` | `main()` | `GetMaterialApp` arranca en `/arranque`, una página `#E77330`, con la capa de la intro en su `builder`. |
| 4 | `Firebase.initializeApp` y `StorageService` | `cargarElArranque()` | Si fallan, no hay ruta segura y la intro sigue en su bucle, como antes quedaba quieto el splash nativo. |
| 5 | `registrarLosServicios()` | `cargarElArranque()` | `AuthService`, `AlertService`, `MallaService`, `AcademicRecordService`, `TimeBlocksService` y `SpecialtyTestService`, permanentes. |
| 6 | `AuthService.tryRestoreSession()` | `cargarElArranque()` | `GET /auth/me` con el JWT. Un 401 borra la sesión sin navegar mientras la ruta es `/arranque`. |
| 7 | La ruta de destino | `cargarElArranque()` | `postLoginRoute(user)` si restauró y `/login` si no. Las alertas ya no se piden aquí, porque las pide el home al montarse. |
| 8 | La salida o el relevo | `CapaDeArranque` | Con sesión, la intro navega sin transición a `/home` abierto en Horario y reproduce su salida hasta la cabecera. Sin sesión, o sin especialidad, deja el logo en el centro y la bienvenida con Ulises toma el relevo en `/login`. |

En web no hay intro. `main()` conserva el orden de antes, con la carga y las alertas antes de
`runApp`, y el único cambio es que el alumno sin especialidad arranca en `/login`.
```

- [ ] **Paso 6. Corre las pruebas y confirma que pasan.**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/main.dart lib/pages/splash/carga_del_arranque.dart test/splash/splash_arranque_test.dart
"${FLUTTER:?}" test --no-pub test/splash test/HU01_jeff test/HU02_jeff
"${FLUTTER:?}" analyze --no-pub
```

Esperado. `All tests passed!` y `5 issues found.`, porque el `print` de `main.dart:103` pasa a
`debugPrint` y el aviso `avoid_print` desaparece. Desde aquí la base de `analyze` es de 5.

- [ ] **Paso 7. Suite completa y commit.** Corre la suite completa en segundo plano. Esperado,
  `All tests passed!`.

```bash
cd "${REPO:?}"
git status --short
git add lib/main.dart lib/pages/splash/carga_del_arranque.dart test/splash/splash_arranque_test.dart README.md
git commit -m "feat(splash): main llama a runApp enseguida y la carga corre en paralelo con la intro desde /arranque, sin cambiar el arranque de web (RF-SPL-4 y S-22)"
git log -1 --format='%an <%ae>'
```

- [ ] **Paso 8. Cierre del splash.** El splash queda completo en la rama y no se publica solo
  (S-30). La revisión manual de su «Verificación» se hace con la bienvenida, en la Tarea 33.

---

### Tarea 15. El motivo de la llegada a `/login` y los avisos abajo

**Requisitos.** De RF-BIEN-1, «El motivo de la llegada» (decisión B-21), y la posición de los
avisos de B-29 y de RF-BIEN-20, que salen abajo con su texto de hoy. El aviso «Estamos creando tu
cuenta» sale abajo desde la Tarea 24, porque lo muestra la bienvenida.

**Archivos.**
- Modificar `lib/services/session_navigation.dart`.
- Modificar `lib/services/api_client.dart:158-160`.
- Modificar `lib/pages/password_reset/reset_password_controller.dart:159-166` y `:196`.
- Modificar `lib/pages/password_reset/forgot_password_controller.dart:10-35`.
- Modificar `lib/pages/perfil/perfil.dart:824-829` (solo el aviso «Código enviado»).
- Crear `test/bienvenida/bienvenida_ruta_test.dart` (grupo `el motivo de la llegada`).
- Crear `test/bienvenida/bienvenida_restablecer_test.dart` (grupo `los avisos abajo`).

**Interfaces.**
- Consume `offAllToLogin` de la Tarea 11.
- Produce estas firmas, que usan las Tareas 23 y 29.

```dart
// session_navigation.dart
enum MotivoDeLlegada { expirada, restablecida }
const String argumentoDeMotivo = 'motivo';
bool offAllToLogin({MotivoDeLlegada? motivo, PoseDelLogo? pose, bool desdeLaIntro = false});
// forgot_password_controller.dart
ForgotPasswordController({PasswordResetService? service});
```

- [ ] **Paso 1. Escribe las pruebas que fallan.** Crea `test/bienvenida/bienvenida_ruta_test.dart`.
  La Tarea 29 le suma los grupos de la ruta.

```dart
// test/bienvenida/bienvenida_ruta_test.dart
//
// UNITARIA + WIDGET · Bienvenida con Ulises
// (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-1 y B-21. offAllToLogin suma el motivo de la llegada como argumento
// de ruta. El 401 pasa `expirada` y su aviso sale abajo (B-29). El cierre de
// sesión y «Volver a iniciar sesión» del Perfil no pasan motivo. La Tarea 29
// suma la ruta de la bienvenida y sus visitas.
// Archivos probados lib/services/session_navigation.dart y
// lib/services/api_client.dart.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/session_navigation.dart';
import 'package:ulima_plus/services/storage_service.dart';

class _StorageEspia extends StorageService {
  int cierres = 0;

  @override
  Future<void> clearSession() async => cierres++;

  @override
  Future<String?> get savedToken async => 'token-guardado';
}

Widget _pagina(String texto) => Scaffold(body: Center(child: Text(texto)));

Widget _app() => GetMaterialApp(
  initialRoute: '/perfil',
  getPages: [
    GetPage(name: '/perfil', page: () => _pagina('perfil')),
    GetPage(name: '/login', page: () => _pagina('login')),
  ],
);

Object? _argumentosDe(WidgetTester tester, String texto) =>
    ModalRoute.of(tester.element(find.text(texto)))!.settings.arguments;

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  group('el motivo de la llegada (RF-BIEN-1 y B-21)', () {
    testWidgets('offAllToLogin pasa el motivo como argumento de ruta', (
      tester,
    ) async {
      await tester.pumpWidget(_app());
      expect(offAllToLogin(motivo: MotivoDeLlegada.restablecida), isTrue);
      await tester.pumpAndSettle();
      expect(_argumentosDe(tester, 'login'), {
        argumentoDeMotivo: MotivoDeLlegada.restablecida,
      });
    });

    testWidgets('sin motivo no pasa argumentos, como el cierre de sesión', (
      tester,
    ) async {
      await tester.pumpWidget(_app());
      expect(offAllToLogin(), isTrue);
      await tester.pumpAndSettle();
      expect(_argumentosDe(tester, 'login'), isNull);
    });

    test('«Volver a iniciar sesión» del Perfil sigue siendo un VoidCallback', () {
      // perfil.dart:101 usa `onPressed: offAllToLogin`.
      const VoidCallback boton = offAllToLogin;
      expect(boton, isNotNull);
    });

    testWidgets('el 401 borra la sesión, llega con `expirada` y su aviso sale '
        'abajo (B-29)', (tester) async {
      final espia = _StorageEspia();
      Get.put<StorageService>(espia);
      await tester.pumpWidget(_app());
      final servidor = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {'code': 'UNAUTHORIZED', 'message': 'Token inválido'},
          }),
          401,
          headers: {'content-type': 'application/json'},
        ),
      );
      await tester.runAsync(
        () => http.runWithClient(() async {
          try {
            await ApiClient(configuredBaseUrl: 'http://test').getJson('/alerts/me');
          } catch (_) {}
        }, () => servidor),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(espia.cierres, 1);
      expect(Get.currentRoute, '/login');
      expect(_argumentosDe(tester, 'login'), {
        argumentoDeMotivo: MotivoDeLlegada.expirada,
      });
      final aviso = tester.widget<GetSnackBar>(find.byType(GetSnackBar));
      expect(aviso.snackPosition, SnackPosition.BOTTOM);
      expect(find.text('Sesión expirada'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });
}
```

  Crea `test/bienvenida/bienvenida_restablecer_test.dart`. La Tarea 18 le suma el sello.

```dart
// test/bienvenida/bienvenida_restablecer_test.dart
//
// UNITARIA + WIDGET · Bienvenida con Ulises
// (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-20. Las pantallas de «¿Olvidaste tu contraseña?» conservan sus
// textos y sus pasos, sus avisos salen abajo, y el restablecimiento llega a
// la bienvenida con `restablecida`. La Tarea 18 suma el sello en su
// cabecera.
// Archivos probados lib/pages/password_reset/*_controller.dart y
// lib/pages/perfil/perfil.dart.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/pages/password_reset/forgot_password_controller.dart';
import 'package:ulima_plus/pages/password_reset/reset_password_controller.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/password_reset_service.dart';
import 'package:ulima_plus/services/session_navigation.dart';
import 'package:ulima_plus/services/storage_service.dart';

class _ServicioFalso extends PasswordResetService {
  @override
  Future<String> request(String identifier) async => 'Te enviamos un código.';

  @override
  Future<void> confirm({
    required String identifier,
    required String code,
    required String newPassword,
  }) async {}
}

class _AlmacenFalso extends StorageService {
  @override
  Future<void> clearToken() async {}
}

class _AuthSinRed extends AuthService {
  @override
  Future<void> logout() async {}
}

Widget _pagina(String texto) => Scaffold(body: Center(child: Text(texto)));

Future<void> _montar(WidgetTester tester) async {
  await tester.pumpWidget(
    GetMaterialApp(
      initialRoute: '/forgot-password',
      getPages: [
        GetPage(name: '/forgot-password', page: () => _pagina('olvido')),
        GetPage(name: '/reset-password', page: () => _pagina('restablecer')),
        GetPage(name: '/login', page: () => _pagina('login')),
      ],
    ),
  );
}

void _avisoAbajo(WidgetTester tester, String titulo) {
  expect(find.text(titulo), findsOneWidget);
  final aviso = tester.widget<GetSnackBar>(find.byType(GetSnackBar));
  expect(aviso.snackPosition, SnackPosition.BOTTOM, reason: titulo);
}

Future<void> _cerrarAvisos(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  group('los avisos abajo (RF-BIEN-20 y B-29)', () {
    testWidgets('«Solicitud enviada» sale abajo', (tester) async {
      await _montar(tester);
      final c = ForgotPasswordController(service: _ServicioFalso());
      c.identifierController.text = '20230001';
      await c.submit();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      _avisoAbajo(tester, 'Solicitud enviada');
      await _cerrarAvisos(tester);
    });

    testWidgets('«Código reenviado» sale abajo', (tester) async {
      await _montar(tester);
      final c = ResetPasswordController(service: _ServicioFalso());
      c.identifier = '20230001';
      await c.resendCode();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      _avisoAbajo(tester, 'Código reenviado');
      c.onClose();
      await _cerrarAvisos(tester);
    });

    testWidgets('el restablecimiento llega con `restablecida` y «Contraseña '
        'actualizada» sale abajo', (tester) async {
      Get.put<StorageService>(_AlmacenFalso());
      Get.put<AuthService>(_AuthSinRed());
      await _montar(tester);
      final c = ResetPasswordController(service: _ServicioFalso());
      c.identifier = '20230001';
      c.codeController.text = '123456';
      c.passwordController.text = 'Contrasena1';
      c.confirmController.text = 'Contrasena1';
      await c.submit();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(Get.currentRoute, '/login');
      expect(
        ModalRoute.of(tester.element(find.text('login')))!.settings.arguments,
        {argumentoDeMotivo: MotivoDeLlegada.restablecida},
      );
      _avisoAbajo(tester, 'Contraseña actualizada');
      await _cerrarAvisos(tester);
    });

    test('«Código enviado» del Perfil sale abajo', () {
      final perfil = File('lib/pages/perfil/perfil.dart').readAsStringSync();
      final inicio = perfil.indexOf("'Código enviado'");
      expect(inicio, isNonNegative);
      final llamada = perfil.substring(inicio, perfil.indexOf(');', inicio));
      expect(llamada, contains('snackPosition: SnackPosition.BOTTOM'));
      // Los avisos «Error» del Perfil no cambian.
      expect(perfil, contains("Get.snackbar('Error', e.message);"));
    });
  });
}
```

- [ ] **Paso 2. Corre las pruebas y confirma que fallan.**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/bienvenida
```

Esperado. Falla la compilación, porque `MotivoDeLlegada`, `argumentoDeMotivo` y el parámetro
`service` de `ForgotPasswordController` no existen.

- [ ] **Paso 3. Suma el motivo.** En `lib/services/session_navigation.dart`, suma esto después de
  `argumentoDePose` y cambia la firma y el mapa de argumentos de `offAllToLogin`.

```dart
/// Por qué se llega a la bienvenida (B-21). El cierre de sesión y «Volver a
/// iniciar sesión» del Perfil no pasan ninguno.
enum MotivoDeLlegada { expirada, restablecida }

/// La clave del argumento con el motivo de la llegada.
const String argumentoDeMotivo = 'motivo';
```

```dart
bool offAllToLogin({
  MotivoDeLlegada? motivo,
  PoseDelLogo? pose,
  bool desdeLaIntro = false,
}) {
  if (Get.context == null) return false;
  if (Get.currentRoute == rutaDelArranque && !desdeLaIntro) return false;
  final alreadyOnLogin =
      Get.currentRoute == '/login' || Get.currentRoute == '/LoginPage';
  if (alreadyOnLogin) return false;
  final argumentos = <String, Object>{
    argumentoDePose: ?pose,
    argumentoDeMotivo: ?motivo,
  };
  if (desdeLaIntro) {
    return offAllSinTransicion(
      '/login',
      arguments: argumentos.isEmpty ? null : argumentos,
    );
  }
  Get.offAllNamed('/login', arguments: argumentos.isEmpty ? null : argumentos);
  return true;
}
```

- [ ] **Paso 4. Pasa `expirada` y baja el aviso del 401.** En `lib/services/api_client.dart`,
  reemplaza el bloque del aviso (`api_client.dart:158-160`) por este.

```dart
      if (!path.contains('/auth/logout') &&
          offAllToLogin(motivo: MotivoDeLlegada.expirada)) {
        // Abajo, para no tapar el sello de la bienvenida (B-29).
        Get.snackbar(
          'Sesión expirada',
          'Tu sesión caducó o iniciaste sesión en otro dispositivo.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
```

- [ ] **Paso 5. Pasa `restablecida` y baja los avisos del restablecimiento.** En
  `reset_password_controller.dart`, cambia `offAllToLogin();` por
  `offAllToLogin(motivo: MotivoDeLlegada.restablecida);` y suma
  `snackPosition: SnackPosition.BOTTOM,` a los dos `Get.snackbar`, «Contraseña actualizada» y
  «Código reenviado». En `forgot_password_controller.dart`, haz inyectable el servicio y baja su
  aviso.

```dart
class ForgotPasswordController extends GetxController {
  /// Inyectable solo para las pruebas. En la app se construye el real.
  ForgotPasswordController({PasswordResetService? service})
    : _service = service ?? PasswordResetService();

  final identifierController = TextEditingController();
  final errorMessage = RxnString();
  final submitting = false.obs;

  final PasswordResetService _service;
```

```dart
      Get.toNamed('/reset-password', arguments: {'identifier': identifier});
      // Abajo, para no tapar el sello de la cabecera (RF-BIEN-20).
      Get.snackbar(
        'Solicitud enviada',
        message,
        snackPosition: SnackPosition.BOTTOM,
      );
```

  En `lib/pages/perfil/perfil.dart`, el aviso «Código enviado» (`perfil.dart:824-829`) suma
  `snackPosition: SnackPosition.BOTTOM,`, porque sale sobre `/reset-password`. Los avisos
  «Error» de las líneas siguientes no cambian.

- [ ] **Paso 6. Corre las pruebas y confirma que pasan.**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/services/session_navigation.dart lib/services/api_client.dart lib/pages/password_reset test/bienvenida
"${FLUTTER:?}" test --no-pub test/bienvenida test/HU20_jeff test/HU01_jeff test/HU02_jeff test/HU33_jeff/api_client_401_test.dart test/splash
"${FLUTTER:?}" analyze --no-pub
```

Esperado. `All tests passed!` y `5 issues found.`. `dart format` sobre `perfil.dart` no se corre,
porque el archivo entero no pasa hoy el formato y el cambio es de una línea. Si el analizador pide
formato, se formatea solo el bloque del aviso a mano.

- [ ] **Paso 7. Commit.**

```bash
cd "${REPO:?}"
git status --short
git add lib/services/session_navigation.dart lib/services/api_client.dart lib/pages/password_reset/reset_password_controller.dart lib/pages/password_reset/forgot_password_controller.dart lib/pages/perfil/perfil.dart test/bienvenida/bienvenida_ruta_test.dart test/bienvenida/bienvenida_restablecer_test.dart
git commit -m "feat(bienvenida): /login recibe el motivo de la llegada y los avisos de la sesión y del restablecimiento salen abajo, sin tapar el sello (RF-BIEN-1, RF-BIEN-20 y B-29)"
git log -1 --format='%an <%ae>'
```

---

### Tarea 16. Las reglas puras de la bienvenida

**Requisitos.** La decisión B-26 y las reglas que la spec deja como funciones puras. Son los
turnos, el atrás de RF-BIEN-13, el turno de cada fallo del envío de RF-BIEN-8, el conteo de
cursos de RF-BIEN-8 (decisiones B-4 y B-31), el latido y el pulso de RF-BIEN-4, las medidas del
recibimiento y «Si no cabe» de RF-BIEN-2 (decisiones B-27 y B-28), los puntos del vuelo de Ulises
y la configuración del botón de GIS de RF-BIEN-6 (decisión B-35). Los textos de «Textos nuevos»
quedan en un solo lugar.

**Archivos.**
- Crear `lib/domain/bienvenida/bienvenida_turnos.dart`.
- Crear `test/bienvenida/bienvenida_turnos_test.dart`.

**Interfaces.**
- Consume nada.
- Produce estas firmas, que usan las Tareas 17 y 23 a 32.

```dart
enum TurnoDeLaBienvenida { recibimiento, llegadaConSesion, e1Codigo, e2Contrasena,
  e3Despedida, n1Codigo, n2Contrasena, n3Consentimiento, n4Portal, n5Authenticator, envio,
  incierto, t0Invitacion, pregunta, espera, desempate, resultado, seleccionManual,
  pasoAlHorario }
enum AccionDelAtras { salirDeLaApp, volverAE1, yaTengoCuenta, volver, avisarQueSeEnvia,
  volverAIntentar, preguntaAnterior, irAT0, nada }
AccionDelAtras accionDelAtras(TurnoDeLaBienvenida turno, {bool testDisponible = true});
TurnoDeLaBienvenida turnoTrasFalloDelEnvio(String? codigo);
String? fraseDelConteo(int cursos);
String textoDeCuentaLista(int cursos);
const Duration duracionDelLatido; // 380 ms
double escalaDelLatido(double avance);
({double radio, double opacidad}) anilloDelLatido(double avance); // radio en radios de la estrella
const Duration periodoDelPulso; // 1100 ms
double posicionDelPulso(double ms);
double opacidadDelRombo(int k, double posicion);
class MedidasDelRecibimiento { Offset estrella; double radio; Rect ulises; Rect tarjeta;
  Rect botones; bool enConversacion; }
MedidasDelRecibimiento medirElRecibimiento({required Offset estrella, required double radio,
  required Rect columna, required double altoDePantalla, required double areaSeguraArriba,
  required double areaSeguraAbajo, required double altoDeLaTarjeta,
  required double altoDeLosBotones});
({Offset inicio, Offset control1, Offset control2}) puntosDelVuelo(Offset aterrizaje,
  Size pantalla);
enum TemaDelBotonDeGoogle { outline, filledBlack }
class ConfiguracionDelBotonDeGoogle { TemaDelBotonDeGoogle tema; double ancho;
  static const String texto, idioma, forma, logo, tamano, tipo; }
ConfiguracionDelBotonDeGoogle configuracionDelBotonDeGoogle({required bool oscuro,
  required double anchoDelCompositor});
abstract final class TextosDeLaBienvenida { /* los textos de «Textos nuevos» */ }
```

- [ ] **Paso 1. Escribe la prueba que falla.** Crea `test/bienvenida/bienvenida_turnos_test.dart`.

```dart
// test/bienvenida/bienvenida_turnos_test.dart
//
// UNITARIA · Bienvenida con Ulises (specs/features/bienvenida/bienvenida.spec.md).
// Las reglas puras de B-26. El atrás de RF-BIEN-13, el turno de cada fallo
// del envío y el conteo de RF-BIEN-8, el latido y el pulso de RF-BIEN-4, las
// medidas y «Si no cabe» de RF-BIEN-2 (B-27 y B-28), el vuelo de Ulises y la
// configuración de GIS de RF-BIEN-6 (B-35).
// Archivo probado lib/domain/bienvenida/bienvenida_turnos.dart.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/domain/bienvenida/bienvenida_turnos.dart';

typedef _T = TurnoDeLaBienvenida;
typedef _A = AccionDelAtras;

void main() {
  group('el atrás del sistema (RF-BIEN-13)', () {
    test('cada turno hace lo mismo que su enlace secundario', () {
      final tabla = <_T, _A>{
        _T.recibimiento: _A.salirDeLaApp,
        _T.llegadaConSesion: _A.salirDeLaApp,
        _T.e1Codigo: _A.salirDeLaApp,
        _T.e2Contrasena: _A.volverAE1,
        _T.n1Codigo: _A.yaTengoCuenta,
        _T.n2Contrasena: _A.volver,
        _T.n3Consentimiento: _A.volver,
        _T.n4Portal: _A.volver,
        _T.n5Authenticator: _A.volver,
        _T.envio: _A.avisarQueSeEnvia,
        _T.incierto: _A.volverAIntentar,
        _T.t0Invitacion: _A.nada,
        _T.resultado: _A.nada,
        _T.pregunta: _A.preguntaAnterior,
        _T.espera: _A.preguntaAnterior,
        _T.desempate: _A.preguntaAnterior,
        _T.seleccionManual: _A.irAT0,
        _T.pasoAlHorario: _A.nada,
        _T.e3Despedida: _A.nada,
      };
      for (final MapEntry(key: turno, value: accion) in tabla.entries) {
        expect(accionDelAtras(turno), accion, reason: '$turno');
      }
      expect(tabla.keys.toSet(), _T.values.toSet(), reason: 'todos los turnos');
      expect(
        accionDelAtras(_T.seleccionManual, testDisponible: false),
        _A.nada,
      );
    });
  });

  group('el envío del registro (RF-BIEN-8)', () {
    test('cada fallo vuelve al turno de hoy', () {
      for (final codigo in [
        'USER_ALREADY_EXISTS',
        'INVALID_REQUEST_BODY',
        'INVALID_JSON_BODY',
      ]) {
        expect(turnoTrasFalloDelEnvio(codigo), _T.n1Codigo, reason: codigo);
      }
      expect(turnoTrasFalloDelEnvio('TIEMPO_AGOTADO'), _T.incierto);
      expect(turnoTrasFalloDelEnvio('SIN_TOKEN'), _T.incierto);
      expect(turnoTrasFalloDelEnvio('SIN_CONEXION'), _T.n5Authenticator);
      expect(turnoTrasFalloDelEnvio('PORTAL_AUTH_FAILED'), _T.n5Authenticator);
      expect(turnoTrasFalloDelEnvio(null), _T.n5Authenticator);
    });

    test('la frase del conteo, sin nombre ni las otras cifras (B-4 y B-31)', () {
      expect(fraseDelConteo(0), isNull);
      expect(fraseDelConteo(1), 'Traje tu curso del ciclo.');
      expect(fraseDelConteo(6), 'Traje tus 6 cursos del ciclo.');
      expect(textoDeCuentaLista(0), '¡Craa! Tu cuenta ya está lista.');
      expect(
        textoDeCuentaLista(6),
        '¡Craa! Tu cuenta ya está lista. Traje tus 6 cursos del ciclo.',
      );
    });
  });

  group('el latido y el pulso (RF-BIEN-4)', () {
    test('el latido dura 380 ms, sube 13 % en el primer 42 % y 5 % entre el '
        '48 % y el 92 %', () {
      expect(duracionDelLatido, const Duration(milliseconds: 380));
      expect(escalaDelLatido(0), 1);
      expect(escalaDelLatido(0.21), closeTo(1.13, 1e-9));
      expect(escalaDelLatido(0.45), 1);
      expect(escalaDelLatido(0.70), closeTo(1.05, 1e-9));
      expect(escalaDelLatido(0.95), 1);
      expect(escalaDelLatido(1), 1);
    });

    test('el anillo del latido crece de 0,62 a 1,5 radios y su opacidad baja '
        'de 0,55 a 0', () {
      expect(anilloDelLatido(0).radio, closeTo(0.62, 1e-9));
      expect(anilloDelLatido(0).opacidad, closeTo(0.55, 1e-9));
      expect(anilloDelLatido(1).radio, closeTo(1.5, 1e-9));
      expect(anilloDelLatido(1).opacidad, closeTo(0, 1e-9));
    });

    test('el pulso recorre los ocho rombos en 1100 ms desde el de arriba', () {
      expect(periodoDelPulso, const Duration(milliseconds: 1100));
      expect(posicionDelPulso(0), 0);
      expect(posicionDelPulso(1100 / 8), closeTo(1, 1e-9));
      expect(posicionDelPulso(1100), closeTo(0, 1e-9));
    });

    test('la opacidad es 0,42 + 0,58 × máx(0; 1 − d / 2,4), con d circular',
        () {
      expect(opacidadDelRombo(0, 0), closeTo(1, 1e-9));
      expect(opacidadDelRombo(2, 0), closeTo(0.42 + 0.58 * (1 - 2 / 2.4), 1e-9));
      expect(opacidadDelRombo(4, 0), closeTo(0.42, 1e-9));
      expect(opacidadDelRombo(7, 0), closeTo(0.42 + 0.58 * (1 - 1 / 2.4), 1e-9));
      expect(opacidadDelRombo(0, 7.5), closeTo(0.42 + 0.58 * (1 - 0.5 / 2.4), 1e-9));
    });
  });

  group('las medidas del recibimiento (RF-BIEN-2, B-27 y B-28)', () {
    MedidasDelRecibimiento enElSe({required double tarjeta}) =>
        medirElRecibimiento(
          estrella: const Offset(187.5, 333.5),
          radio: 90,
          columna: const Rect.fromLTWH(0, 0, 375, 667),
          altoDePantalla: 667,
          areaSeguraArriba: 20,
          areaSeguraAbajo: 0,
          altoDeLaTarjeta: tarjeta,
          altoDeLosBotones: 110,
        );

    test('en el iPhone SE con el texto al 100 % la estrella no se mueve', () {
      final m = enElSe(tarjeta: 59.5);
      expect(m.estrella, const Offset(187.5, 333.5));
      expect(m.radio, 90);
      expect(m.ulises.center, const Offset(83.5, 471.5));
      expect(m.ulises.width, 70);
      expect(m.botones.top, 531);
      expect(m.botones.left, 22);
      expect(m.botones.right, 375 - 22);
      expect(m.tarjeta.top, 471.5 - 22);
      expect(m.tarjeta.left, 83.5 + 35 + 11);
      expect(m.tarjeta.right, 375 - 12);
      // Unos 14 dp bajo el margen de la estrella y 22 dp sobre los botones.
      expect(m.tarjeta.top - (333.5 + 90 + 12), closeTo(14, 0.01));
      expect(m.botones.top - m.tarjeta.bottom, closeTo(22, 0.01));
      expect(m.enConversacion, isFalse);
    });

    test('si la tarjeta crece, Ulises y la tarjeta suben lo justo y la '
        'estrella sube antes de que entren en su margen', () {
      final m = enElSe(tarjeta: 99.5);
      expect(m.botones.top - m.tarjeta.bottom, closeTo(16, 0.01));
      expect(m.ulises.top, closeTo(m.estrella.dy + 90 + 12, 0.01));
      expect(m.estrella.dy, closeTo(300.5, 0.01));
      expect(m.radio, 90);
    });

    test('si no alcanza, la estrella se achica hasta 60 dp sin acercarse a '
        'menos de 24 dp del área segura', () {
      final m = enElSe(tarjeta: 300);
      expect(m.radio, lessThan(90));
      expect(m.radio, greaterThanOrEqualTo(60));
      expect(m.estrella.dy - m.radio, closeTo(20 + 24, 0.01));
      expect(m.ulises.top, closeTo(m.estrella.dy + m.radio + 12, 0.01));
    });

    test('si ni así cabe, Ulises saluda ya en la conversación', () {
      final m = enElSe(tarjeta: 420);
      expect(m.enConversacion, isTrue);
      expect(m.estrella, const Offset(187.5, 333.5));
      expect(m.radio, 90);
    });
  });

  group('el vuelo de Ulises (RF-BIEN-2)', () {
    test('los puntos son los de la maqueta por 1,2, desde el aterrizaje', () {
      final p = puntosDelVuelo(const Offset(83.5, 471.5), const Size(375, 667));
      expect(p.inicio, const Offset(83.5 + 353, 471.5 - 578));
      expect(p.control1, const Offset(83.5 + 221, 471.5 - 478));
      expect(p.control2, const Offset(83.5 - 187, 471.5 - 226));
    });

    test('en una tableta el inicio se corre arriba y a la derecha hasta quedar '
        'fuera', () {
      final p = puntosDelVuelo(const Offset(400, 900), const Size(1024, 1366));
      final fuera = p.inicio.dx - 31 >= 1024 || p.inicio.dy + 31 <= 0;
      expect(fuera, isTrue);
      expect(p.inicio.dx, greaterThanOrEqualTo(400 + 353));
      expect(p.inicio.dy, lessThanOrEqualTo(900 - 578));
    });
  });

  group('el botón de Google en web (RF-BIEN-6 y B-35)', () {
    test('continue_with, es, rectangular, el logo a la izquierda y el tema del '
        'sistema', () {
      final claro = configuracionDelBotonDeGoogle(
        oscuro: false,
        anchoDelCompositor: 351,
      );
      expect(claro.tema, TemaDelBotonDeGoogle.outline);
      expect(claro.ancho, 351);
      final oscuro = configuracionDelBotonDeGoogle(
        oscuro: true,
        anchoDelCompositor: 560,
      );
      expect(oscuro.tema, TemaDelBotonDeGoogle.filledBlack);
      expect(oscuro.ancho, 400, reason: 'el máximo de GIS');
      expect(ConfiguracionDelBotonDeGoogle.texto, 'continue_with');
      expect(ConfiguracionDelBotonDeGoogle.idioma, 'es');
      expect(ConfiguracionDelBotonDeGoogle.forma, 'rectangular');
      expect(ConfiguracionDelBotonDeGoogle.logo, 'left');
    });
  });

  test('los textos de Ulises con número', () {
    expect(
      TextosDeLaBienvenida.invitacionAlTest(14),
      '¿Empezamos tu test de especialidad? Son 14 preguntas cortas.',
    );
    expect(TextosDeLaBienvenida.rotuloDelDuelo(3, 14), 'Esto o aquello · 3 de 14');
    expect(TextosDeLaBienvenida.rotuloDeLaEscala(9, 14), 'Escala de gusto · 9 de 14');
  });
}
```

- [ ] **Paso 2. Corre la prueba y confirma que falla.**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/bienvenida/bienvenida_turnos_test.dart
```

Esperado. Falla la compilación, porque `bienvenida_turnos.dart` no existe.

- [ ] **Paso 3. Escribe las reglas.** Crea `lib/domain/bienvenida/bienvenida_turnos.dart`.

```dart
// lib/domain/bienvenida/bienvenida_turnos.dart
// Las reglas puras de la bienvenida con Ulises (decisión B-26 de
// specs/features/bienvenida/bienvenida.spec.md). Los turnos, el atrás de
// cada uno, el turno al que vuelve cada fallo del envío, el conteo de cursos,
// el latido del sello, el pulso de los rombos, las medidas del recibimiento
// con su regla «Si no cabe», el vuelo de Ulises y la configuración del botón
// de Google en web. Sin widgets ni GetX.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/animation.dart' show Curves;

enum TurnoDeLaBienvenida {
  recibimiento,
  llegadaConSesion,
  e1Codigo,
  e2Contrasena,
  e3Despedida,
  n1Codigo,
  n2Contrasena,
  n3Consentimiento,
  n4Portal,
  n5Authenticator,
  envio,
  incierto,
  t0Invitacion,
  pregunta,
  espera,
  desempate,
  resultado,
  seleccionManual,
  pasoAlHorario,
}

enum AccionDelAtras {
  salirDeLaApp,
  volverAE1,
  yaTengoCuenta,
  volver,
  avisarQueSeEnvia,
  volverAIntentar,
  preguntaAnterior,
  irAT0,
  nada,
}

/// El atrás del sistema hace lo mismo que el enlace secundario del turno
/// (RF-BIEN-13).
AccionDelAtras accionDelAtras(
  TurnoDeLaBienvenida turno, {
  bool testDisponible = true,
}) => switch (turno) {
  TurnoDeLaBienvenida.recibimiento ||
  TurnoDeLaBienvenida.llegadaConSesion ||
  TurnoDeLaBienvenida.e1Codigo => AccionDelAtras.salirDeLaApp,
  TurnoDeLaBienvenida.e2Contrasena => AccionDelAtras.volverAE1,
  TurnoDeLaBienvenida.n1Codigo => AccionDelAtras.yaTengoCuenta,
  TurnoDeLaBienvenida.n2Contrasena ||
  TurnoDeLaBienvenida.n3Consentimiento ||
  TurnoDeLaBienvenida.n4Portal ||
  TurnoDeLaBienvenida.n5Authenticator => AccionDelAtras.volver,
  TurnoDeLaBienvenida.envio => AccionDelAtras.avisarQueSeEnvia,
  TurnoDeLaBienvenida.incierto => AccionDelAtras.volverAIntentar,
  TurnoDeLaBienvenida.pregunta ||
  TurnoDeLaBienvenida.espera ||
  TurnoDeLaBienvenida.desempate => AccionDelAtras.preguntaAnterior,
  TurnoDeLaBienvenida.seleccionManual =>
    testDisponible ? AccionDelAtras.irAT0 : AccionDelAtras.nada,
  TurnoDeLaBienvenida.t0Invitacion ||
  TurnoDeLaBienvenida.resultado ||
  TurnoDeLaBienvenida.e3Despedida ||
  TurnoDeLaBienvenida.pasoAlHorario => AccionDelAtras.nada,
};

/// El turno al que vuelve la conversación tras un fallo del envío, con las
/// reglas de hoy de `registro_controller.dart:265-286` (RF-BIEN-8 y B-32).
TurnoDeLaBienvenida turnoTrasFalloDelEnvio(String? codigo) {
  const aIncierto = <String>{'TIEMPO_AGOTADO', 'SIN_TOKEN'};
  const aN1 = <String>{
    'USER_ALREADY_EXISTS',
    'INVALID_REQUEST_BODY',
    'INVALID_JSON_BODY',
  };
  if (aIncierto.contains(codigo)) return TurnoDeLaBienvenida.incierto;
  if (aN1.contains(codigo)) return TurnoDeLaBienvenida.n1Codigo;
  return TurnoDeLaBienvenida.n5Authenticator;
}

/// La frase del conteo, sin nombre (B-4) y sin las otras dos cifras del
/// resumen de hoy (B-31). Con 0 cursos no hay frase.
String? fraseDelConteo(int cursos) {
  if (cursos <= 0) return null;
  if (cursos == 1) return 'Traje tu curso del ciclo.';
  return 'Traje tus $cursos cursos del ciclo.';
}

/// La burbuja del 201, en una sola burbuja como en la maqueta.
String textoDeCuentaLista(int cursos) {
  final frase = fraseDelConteo(cursos);
  return frase == null
      ? TextosDeLaBienvenida.cuentaLista
      : '${TextosDeLaBienvenida.cuentaLista} $frase';
}

const Duration duracionDelLatido = Duration(milliseconds: 380);

/// La escala de la estrella en el latido, con el [avance] de 0 a 1.
double escalaDelLatido(double avance) {
  if (avance <= 0 || avance >= 1) return 1;
  if (avance <= 0.42) return 1 + 0.13 * math.sin(math.pi * avance / 0.42);
  if (avance >= 0.48 && avance <= 0.92) {
    return 1 + 0.05 * math.sin(math.pi * (avance - 0.48) / 0.44);
  }
  return 1;
}

/// El anillo del latido, con el radio en radios de la estrella.
({double radio, double opacidad}) anilloDelLatido(double avance) {
  final t = avance.clamp(0.0, 1.0).toDouble();
  return (
    radio: 0.62 + (1.5 - 0.62) * Curves.easeOutCubic.transform(t),
    opacidad: 0.55 * (1 - t),
  );
}

const Duration periodoDelPulso = Duration(milliseconds: 1100);

/// Dónde va el pulso, en rombos desde el de arriba, en sentido horario.
double posicionDelPulso(double ms) =>
    (ms / periodoDelPulso.inMilliseconds * 8) % 8;

/// La opacidad del rombo [k] con el pulso en [posicion].
double opacidadDelRombo(int k, double posicion) {
  final directa = (k - posicion).abs() % 8;
  final d = math.min(directa, 8 - directa);
  return 0.42 + 0.58 * math.max(0, 1 - d / 2.4);
}

/// Dónde queda cada pieza del recibimiento (RF-BIEN-2). Ulises se ancla a la
/// estrella, la tarjeta a Ulises y los botones al borde inferior.
class MedidasDelRecibimiento {
  const MedidasDelRecibimiento({
    required this.estrella,
    required this.radio,
    required this.ulises,
    required this.tarjeta,
    required this.botones,
    required this.enConversacion,
  });

  final Offset estrella;
  final double radio;
  final Rect ulises;
  final Rect tarjeta;
  final Rect botones;

  /// Ni achicando la estrella caben, y Ulises saluda ya en la conversación.
  final bool enConversacion;
}

MedidasDelRecibimiento medirElRecibimiento({
  required Offset estrella,
  required double radio,
  required Rect columna,
  required double altoDePantalla,
  required double areaSeguraArriba,
  required double areaSeguraAbajo,
  required double altoDeLaTarjeta,
  required double altoDeLosBotones,
}) {
  const ladoDeUlises = 70.0;
  final fondoDeLosBotones = altoDePantalla - areaSeguraAbajo - 26;
  final botones = Rect.fromLTRB(
    columna.left + 22,
    fondoDeLosBotones - altoDeLosBotones,
    columna.right - 22,
    fondoDeLosBotones,
  );
  final ux = estrella.dx - 104;
  var uy = estrella.dy + 138;

  // Si Ulises o la tarjeta quedan a menos de 16 dp de los botones, suben
  // juntos lo justo.
  double fondo(double y) =>
      math.max(y + ladoDeUlises / 2, y - 22 + altoDeLaTarjeta);
  final exceso = fondo(uy) - (botones.top - 16);
  if (exceso > 0) uy -= exceso;

  var sy = estrella.dy;
  var r = radio;
  var enConversacion = false;
  final arriba = uy - ladoDeUlises / 2;
  if (arriba < sy + r + 12) {
    // La estrella sube lo justo, sin acercarse a menos de 24 dp del área
    // segura de arriba, y si no alcanza, se achica hasta 60 dp.
    final techo = areaSeguraArriba + 24;
    sy = arriba - r - 12;
    if (sy - r < techo) {
      r = (arriba - 12 - techo) / 2;
      sy = techo + r;
      if (r < 60) {
        enConversacion = true;
        r = radio;
        sy = estrella.dy;
      }
    }
  }

  final ulises = Rect.fromCenter(
    center: Offset(ux, uy),
    width: ladoDeUlises,
    height: ladoDeUlises,
  );
  return MedidasDelRecibimiento(
    estrella: Offset(estrella.dx, sy),
    radio: r,
    ulises: ulises,
    tarjeta: Rect.fromLTRB(
      ulises.right + 11,
      uy - 22,
      columna.right - 12,
      uy - 22 + altoDeLaTarjeta,
    ),
    botones: botones,
    enConversacion: enConversacion,
  );
}

/// La curva del vuelo de Ulises. Sus puntos son los de la maqueta, medidos
/// desde el aterrizaje y por 1,2 (B-27). Si el inicio cae dentro de la
/// pantalla, se corre arriba y a la derecha hasta quedar fuera.
({Offset inicio, Offset control1, Offset control2}) puntosDelVuelo(
  Offset aterrizaje,
  Size pantalla,
) {
  const mitad = 31.0; // Ulises mide 62 dp al empezar
  var inicio = aterrizaje + const Offset(353, -578);
  if (inicio.dx - mitad < pantalla.width && inicio.dy + mitad > 0) {
    final c = math.min(pantalla.width - (inicio.dx - mitad), inicio.dy + mitad);
    inicio += Offset(c, -c);
  }
  return (
    inicio: inicio,
    control1: aterrizaje + const Offset(221, -478),
    control2: aterrizaje + const Offset(-187, -226),
  );
}

enum TemaDelBotonDeGoogle { outline, filledBlack }

/// La configuración del botón oficial de GIS en web, como valores simples
/// que la VM prueba (B-35). La traduce `google_sign_in_button_web.dart`.
class ConfiguracionDelBotonDeGoogle {
  const ConfiguracionDelBotonDeGoogle({required this.tema, required this.ancho});

  static const String tipo = 'standard';
  static const String texto = 'continue_with';
  static const String idioma = 'es';
  static const String forma = 'rectangular';
  static const String logo = 'left';
  static const String tamano = 'large';

  final TemaDelBotonDeGoogle tema;

  /// El ancho del compositor hasta 400 px, el máximo de GIS.
  final double ancho;
}

ConfiguracionDelBotonDeGoogle configuracionDelBotonDeGoogle({
  required bool oscuro,
  required double anchoDelCompositor,
}) => ConfiguracionDelBotonDeGoogle(
  tema: oscuro ? TemaDelBotonDeGoogle.filledBlack : TemaDelBotonDeGoogle.outline,
  ancho: math.min(anchoDelCompositor, 400),
);

/// Los textos de «Textos nuevos» y los de hoy que la bienvenida conserva.
abstract final class TextosDeLaBienvenida {
  // Recibimiento.
  static const String saludo = '¡Craa! Hola, soy Ulises 👋';
  static const String pregunta = '¿Ya usas ULima++?';
  static const String siEntrar = 'Sí, entrar';
  static const String soyNuevo = 'Soy nuevo';
  static const String ulises = 'Ulises';
  static const String tu = 'Tú';

  // Sí, entrar.
  static const String e1 = '¡Qué bueno verte! ¿Cuál es tu código o usuario?';
  static const String rotuloCodigo = 'Código';
  static const String pistaCodigo = 'Tu código o usuario';
  static const String separadorO = 'o';
  static const String continuarConGoogle = 'Continuar con Google';
  static const String e2 = 'Y tu contraseña de ULima++.';
  static const String rotuloContrasena = 'Contraseña';
  static const String pistaContrasena = 'Tu contraseña';
  static const String entrar = 'Entrar';
  static const String olvidaste = '¿Olvidaste tu contraseña?';
  static const String contrasenaLista = 'Contraseña lista';
  static const String e3 = '¡Hola de nuevo! Te llevo a tu horario 🪶';

  // Sin especialidad (RF-BIEN-21).
  static const String saludoConSesion = '¡Craa! Hola de nuevo 👋';
  static const String faltaEspecialidad = 'Te falta elegir tu especialidad.';
  static const String holaFaltaEspecialidad =
      '¡Hola de nuevo! Te falta elegir tu especialidad.';

  // Soy nuevo.
  static const String n1a = '¡Genial! Tu cuenta se crea aquí mismo.';
  static const String n1b = '¿Cuál es tu código de alumno?';
  static const String rotuloCodigoDeAlumno = 'Código de alumno';
  static const String pistaCodigoDeAlumno = 'Tu código de alumno';
  static const String n2 =
      'Ahora elige la contraseña con la que entrarás a ULima++. No es la de '
      'miUlima.';
  static const String pistaNueva = 'Al menos 8 caracteres';
  static const String rotuloRepetir = 'Repetir contraseña';
  static const String pistaRepetir = 'La misma otra vez';
  static const String contrasenaUlimaLista = 'Contraseña de ULima++ lista';
  static const String n3 =
      'Para traer tus cursos entro a miUlima una sola vez. Antes, lee esto 👇';
  static const String acepto = 'Acepto';
  static const String n4 = 'Tu contraseña de miUlima, la del portal.';
  static const String rotuloPortal = 'Contraseña de miUlima';
  static const String pistaPortal = 'Tu contraseña del portal';
  static const String contrasenaMiUlimaLista = 'Contraseña de miUlima lista';
  static const String n5 = 'Último paso. El código de tu authenticator.';
  static const String rotuloAuthenticator = 'Código del authenticator';
  static const String notaAuthenticator =
      'El código de 6 dígitos que cambia cada 30 segundos.';
  static const String crearMiCuenta = 'Crear mi cuenta';
  static const String authenticatorListo = 'Código del authenticator listo';
  static const String volver = 'Volver';
  static const String yaTengoCuenta = 'Ya tengo cuenta';

  // Envío.
  static const String creando = 'Estoy creando tu cuenta y trayendo tu ciclo.';
  static const String advertencia =
      'Puede tomar un par de minutos: no cierres la app.';
  static const String pildoraCreando = 'Creando tu cuenta…';
  static const String pildoraCreada = 'Cuenta creada';
  static const String cuentaLista = '¡Craa! Tu cuenta ya está lista.';
  static const String avisosDelRegistro = 'Algunas cosas que notamos';
  static const String avisoEnvioTitulo = 'Estamos creando tu cuenta';
  static const String avisoEnvioTexto =
      'No cierres la app: si sales ahora podrías quedarte con una cuenta a '
      'medias.';

  // incierto.
  static const String inciertoTitulo =
      'No pudimos confirmar si tu cuenta se creó.';
  static const String inciertoTexto =
      'Es posible que sí se haya creado. Prueba entrar con el código y la '
      'contraseña que acabas de elegir.';
  static const String creadaTitulo = 'Tu cuenta ya está creada.';
  static const String creadaTexto =
      'Entra con el código y la contraseña que acabas de elegir.';
  static const String volverAIntentar = 'Volver a intentar el registro';
  static const String iniciarSesion = 'Iniciar sesión';

  // Test.
  static String invitacionAlTest(int preguntas) =>
      '¿Empezamos tu test de especialidad? Son $preguntas preguntas cortas.';
  static const String saltar = 'Saltar y elegir por mi cuenta';
  static const String empezarElTest = 'Empezar el test';
  static const String noCargoElTest = 'No pudimos cargar el test.';
  static const String reintentar = 'Reintentar';
  static String rotuloDelDuelo(int n, int total) =>
      'Esto o aquello · $n de $total';
  static String rotuloDeLaEscala(int n, int total) =>
      'Escala de gusto · $n de $total';
  static const String preguntaAnterior = 'Pregunta anterior';
  static const String listoAlHorario = '¡Listo! Te llevo a tu horario 🪶';
  static const String eligeMencion =
      'Elige una mención como tu diploma principal.';
  static const String noCargaronEspecialidades =
      'No pudimos cargar las especialidades.';
  static const String sinCarrera = 'No se pudo determinar tu carrera.';
  static const String principal = 'Principal';
  static const String meInteresa = 'Me interesa';
  static const String saltarPorAhora = 'Saltar por ahora';
  static const String finalizar = 'Finalizar configuración';

  // Errores y sesión.
  static const String sinConexion =
      'No hay conexión. Revisa tu internet e inténtalo de nuevo.';
  static const String sesionCaducada =
      'Tu sesión caducó o iniciaste sesión en otro dispositivo.';

  // Semántica.
  static const String enviar = 'Enviar';
  static const String mostrarContrasena = 'Mostrar contraseña';
  static const String ocultarContrasena = 'Ocultar contraseña';
}
```

- [ ] **Paso 4. Corre la prueba y confirma que pasa.**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/domain/bienvenida test/bienvenida/bienvenida_turnos_test.dart
"${FLUTTER:?}" test --no-pub test/bienvenida/bienvenida_turnos_test.dart
"${FLUTTER:?}" analyze --no-pub
```

Esperado. `All tests passed!` y `5 issues found.`.

- [ ] **Paso 5. Commit.**

```bash
cd "${REPO:?}"
git status --short
git add lib/domain/bienvenida/bienvenida_turnos.dart test/bienvenida/bienvenida_turnos_test.dart
git commit -m "feat(bienvenida): los turnos, el atrás, el conteo, el latido, el pulso, las medidas del recibimiento y el botón de GIS salen de funciones puras (B-26)"
git log -1 --format='%an <%ae>'
```

---

### Tarea 17. El sello y la cabecera con el sello

**Requisitos.** De RF-BIEN-4, «La franja» en su alto, «El sello», «El latido», «El pulso» y
«Semántica», y de RF-BIEN-20, «Dónde vive» y que «ULIMA» deja de crecer si con letra grande no
cabe entre los márgenes de 56 dp.

**Archivos.**
- Crear `lib/components/logo/sello_del_logo.dart`.
- Crear `test/bienvenida/bienvenida_sello_test.dart` (grupo `el sello quieto`).

**Interfaces.**
- Consume `AppHeader.estiloDeMarca`, `AppHeader.tamanoDeEstrella` y `AppHeader.separacion`
  (Tarea 5), `pintarEscena` (Tarea 2) y `escalaDelLatido`, `anilloDelLatido` y
  `opacidadDelRombo` (Tarea 16).
- Produce estas firmas, que usan las Tareas 18, 26, 28 y 30.

```dart
class SelloDelLogo extends StatelessWidget {
  const SelloDelLogo({ValueListenable<double>? latido,
    ValueListenable<List<double>?>? rombos, Color color = Colors.white});
  static const double escala;            // 1,22
  static const double tamanoDeEstrella;  // 31,72 dp
  static TextStyle estilo(ColorScheme colores); }
class CabeceraConSello extends StatelessWidget {
  const CabeceraConSello({Color? color, double radioInferior = 0, Widget sello = const SelloDelLogo()});
  static const double margenLateral;     // 56 dp
  static double altoDeLaFila(BuildContext context);
  static double alto(BuildContext context);            // 50 + fila + 20 + 2
  static double centroDeLaFila(BuildContext context); } // 50 + fila / 2
```

- [ ] **Paso 1. Escribe la prueba que falla.** Crea `test/bienvenida/bienvenida_sello_test.dart`.
  La Tarea 28 le suma el latido y el pulso en la conversación.

```dart
// test/bienvenida/bienvenida_sello_test.dart
//
// WIDGET · Bienvenida con Ulises (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-4. El sello es la estrella de la cabecera y «ULIMA++» a 1,22 veces
// su tamaño, centrado a lo ancho y a la altura de la fila de la cabecera, en
// una franja que mide lo mismo que la cabecera de /home. Es un encabezado
// «ULIMA++». La Tarea 28 suma el latido, el pulso y la subida.
// Archivo probado lib/components/logo/sello_del_logo.dart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/header/app_header.dart';
import 'package:ulima_plus/components/logo/sello_del_logo.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/services/alert_service.dart';
import 'package:ulima_plus/services/auth_service.dart';

class _AuthDeAlumna extends AuthService {
  @override
  UserModel? get currentUser => UserModel(
    code: '20230001',
    firstName: 'Alumna',
    lastName: 'De Prueba',
    email: 'test@aloe.ulima.edu.pe',
    role: 'student',
    currentCycle: '2026-2',
    setupComplete: true,
  );
}

class _AlertasSinRed extends AlertService {
  @override
  Future<void> fetchAlerts() async {}
}

Future<void> _montar(
  WidgetTester tester,
  Widget hijo, {
  double escala = 1,
}) async {
  tester.view.physicalSize = const Size(750, 1334);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  const tema = MaterialTheme(TextTheme());
  await tester.pumpWidget(
    GetMaterialApp(
      theme: tema.light(),
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(375, 667),
          textScaler: TextScaler.linear(escala),
        ),
        child: Scaffold(
          body: Align(alignment: Alignment.topCenter, child: hijo),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
    Get.put<AuthService>(_AuthDeAlumna());
    Get.put<AlertService>(_AlertasSinRed());
  });
  tearDown(Get.reset);

  group('el sello quieto (RF-BIEN-4)', () {
    testWidgets('la estrella y «ULIMA» miden 1,22 veces los de la cabecera', (
      tester,
    ) async {
      await _montar(tester, const CabeceraConSello(color: Colors.orange));
      expect(SelloDelLogo.tamanoDeEstrella, closeTo(26 * 1.22, 1e-9));
      final texto = tester.widget<Text>(find.text('ULIMA'));
      expect(texto.style!.fontSize, closeTo(20 * 1.22, 1e-9));
      expect(texto.style!.fontStyle, FontStyle.italic);
      expect(texto.style!.fontWeight, FontWeight.bold);
    });

    for (final escala in [1.0, 2.0]) {
      testWidgets('la franja mide lo mismo que la cabecera de /home con el '
          'texto al ${escala * 100} %', (tester) async {
        await _montar(tester, AppHeader(), escala: escala);
        final cabecera = tester.getSize(find.byType(AppHeader)).height;
        await _montar(tester, const CabeceraConSello(), escala: escala);
        expect(tester.getSize(find.byType(CabeceraConSello)).height, cabecera);
      });
    }

    testWidgets('el sello va centrado a lo ancho y a la altura de la fila de '
        'la cabecera', (tester) async {
      await _montar(tester, const CabeceraConSello());
      final sello = tester.getRect(find.byType(SelloDelLogo));
      expect(sello.center.dx, closeTo(375 / 2, 0.5));
      final contexto = tester.element(find.byType(CabeceraConSello));
      expect(sello.center.dy, closeTo(CabeceraConSello.centroDeLaFila(contexto), 0.5));
    });

    testWidgets('es un encabezado «ULIMA++» y su dibujo queda fuera de la '
        'semántica', (tester) async {
      final semantica = tester.ensureSemantics();
      await _montar(tester, const CabeceraConSello());
      final nodo = find.bySemanticsLabel('ULIMA++');
      expect(nodo, findsOneWidget);
      expect(tester.getSemantics(nodo), containsSemantics(isHeader: true));
      expect(find.bySemanticsLabel('ULIMA'), findsNothing);
      semantica.dispose();
    });

    testWidgets('con letra grande, «ULIMA» deja de crecer para caber entre los '
        'márgenes de 56 dp (RF-BIEN-20)', (tester) async {
      await _montar(tester, const CabeceraConSello(), escala: 3);
      final sello = tester.getRect(find.byType(SelloDelLogo));
      expect(sello.left, greaterThanOrEqualTo(56 - 0.5));
      expect(sello.right, lessThanOrEqualTo(375 - 56 + 0.5));
      expect(tester.takeException(), isNull);
    });
  });
}
```

- [ ] **Paso 2. Corre la prueba y confirma que falla.**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/bienvenida/bienvenida_sello_test.dart
```

Esperado. Falla la compilación, porque `sello_del_logo.dart` no existe.

- [ ] **Paso 3. Escribe el sello.** Crea `lib/components/logo/sello_del_logo.dart`.

```dart
// lib/components/logo/sello_del_logo.dart
// El sello del logo ULima++ (RF-BIEN-4 y RF-BIEN-20 de la spec de la
// bienvenida). Es la estrella de la cabecera y «ULIMA++» a 1,22 veces su
// tamaño, con los «++» como cruces del logo inclinadas −12°. Lo usan la
// franja de la conversación y la cabecera de las pantallas de «¿Olvidaste tu
// contraseña?», en el mismo lugar y del mismo tamaño. El latido y el pulso
// repintan solo su pintor (RF-BIEN-18).

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/bienvenida/bienvenida_turnos.dart';
import '../header/app_header.dart';
import 'escena_del_logo.dart';
import 'logo_geometria.dart';
import 'pintor_del_logo.dart';

class SelloDelLogo extends StatelessWidget {
  const SelloDelLogo({
    super.key,
    this.latido,
    this.rombos,
    this.color = Colors.white,
  });

  static const double escala = 1.22;
  static const double tamanoDeEstrella = AppHeader.tamanoDeEstrella * escala;
  static const double separacion = AppHeader.separacion * escala;
  static const double inclinacionDeLosMas = -12 * math.pi / 180;

  /// El avance del latido, de 0 a 1. Sin latido vale 0.
  final ValueListenable<double>? latido;

  /// La opacidad de cada rombo durante el pulso, o null con los ocho enteros.
  final ValueListenable<List<double>?>? rombos;
  final Color color;

  /// El estilo único de «ULIMA++» de la cabecera, a 1,22 veces.
  static TextStyle estilo(ColorScheme colores) {
    final base = AppHeader.estiloDeMarca(colores);
    return base.copyWith(fontSize: (base.fontSize ?? 20) * escala);
  }

  @override
  Widget build(BuildContext context) {
    // Con el estilo de texto heredado, como el Text de la cabecera.
    final estiloDelSello = DefaultTextStyle.of(context).style
        .merge(estilo(Theme.of(context).colorScheme))
        .copyWith(color: color);
    final sistema = MediaQuery.textScalerOf(context);
    return Semantics(
      header: true,
      label: 'ULIMA++',
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, limites) {
          final escalaDeTexto = _escalaQueCabe(
            estiloDelSello,
            sistema,
            limites.maxWidth,
          );
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: tamanoDeEstrella,
                child: CustomPaint(
                  painter: _PintorDeLaEstrella(
                    latido: latido,
                    rombos: rombos,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: separacion),
              Text('ULIMA', style: estiloDelSello, textScaler: escalaDeTexto),
              _LosMas(estilo: estiloDelSello, escala: escalaDeTexto),
            ],
          );
        },
      ),
    );
  }

  /// La escala del sistema o, si el sello no cabe en [ancho], la mayor con la
  /// que cabe (RF-BIEN-20).
  static TextScaler _escalaQueCabe(
    TextStyle estilo,
    TextScaler sistema,
    double ancho,
  ) {
    if (!ancho.isFinite) return sistema;
    double anchoDelTexto(TextScaler s) {
      final p = TextPainter(
        text: TextSpan(text: 'ULIMA++', style: estilo),
        textDirection: TextDirection.ltr,
        textScaler: s,
      )..layout();
      return p.width;
    }

    final libre = ancho - tamanoDeEstrella - separacion;
    if (anchoDelTexto(sistema) <= libre) return sistema;
    final base = anchoDelTexto(TextScaler.noScaling);
    return TextScaler.linear(math.max(0.5, libre / base));
  }
}

class _PintorDeLaEstrella extends CustomPainter {
  _PintorDeLaEstrella({this.latido, this.rombos, required this.color})
    : super(repaint: Listenable.merge(<Listenable?>[latido, rombos]));

  final ValueListenable<double>? latido;
  final ValueListenable<List<double>?>? rombos;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final radio = size.width / 2;
    final avance = latido?.value ?? 0;
    final opacidades = rombos?.value;
    pintarEscena(
      canvas,
      EscenaDelLogo(
        centro: centro,
        radio: radio,
        escalaDeEstrella: escalaDelLatido(avance),
        rombos: opacidades == null
            ? EscenaDelLogo.rombosEnReposo
            : <RomboEnEscena>[
                for (final o in opacidades) RomboEnEscena(opacidad: o),
              ],
      ),
      color: color,
    );
    if (avance > 0 && avance < 1) {
      final anillo = anilloDelLatido(avance);
      canvas.drawCircle(
        centro,
        radio * anillo.radio,
        Paint()
          ..isAntiAlias = true
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = color.withValues(alpha: anillo.opacidad),
      );
    }
  }

  @override
  bool shouldRepaint(_PintorDeLaEstrella oldDelegate) =>
      oldDelegate.latido != latido ||
      oldDelegate.rombos != rombos ||
      oldDelegate.color != color;
}

/// Los «++» del sello, como cruces del logo del ancho de los glifos.
class _LosMas extends StatelessWidget {
  const _LosMas({required this.estilo, required this.escala});

  final TextStyle estilo;
  final TextScaler escala;

  @override
  Widget build(BuildContext context) {
    final glifos = TextPainter(
      text: TextSpan(text: '++', style: estilo),
      textDirection: TextDirection.ltr,
      textScaler: escala,
    )..layout();
    return CustomPaint(
      size: Size(glifos.width, glifos.height),
      painter: _PintorDeLosMas(glifos: glifos, estilo: estilo, escala: escala),
    );
  }
}

class _PintorDeLosMas extends CustomPainter {
  _PintorDeLosMas({
    required this.glifos,
    required this.estilo,
    required this.escala,
  });

  final TextPainter glifos;
  final TextStyle estilo;
  final TextScaler escala;

  @override
  void paint(Canvas canvas, Size size) {
    final em = escala.scale(estilo.fontSize ?? 20);
    final base = glifos.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    final y = base - 0.34 * em;
    final largo = 0.5 * em;
    final pintura = Paint()
      ..isAntiAlias = true
      ..color = estilo.color ?? Colors.white;
    final (h, v) = LogoGeometria.barrasDeCruz();
    for (var i = 0; i < 2; i++) {
      canvas.save();
      canvas.translate(size.width * (0.25 + 0.5 * i), y);
      canvas.rotate(SelloDelLogo.inclinacionDeLosMas);
      canvas.scale(largo / LogoGeometria.largoDeCruz);
      canvas.drawRect(h, pintura);
      canvas.drawRect(v, pintura);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PintorDeLosMas oldDelegate) =>
      oldDelegate.estilo != estilo || oldDelegate.escala != escala;
}

/// La franja o la cabecera con el sello. Mide lo mismo que la cabecera de
/// /home (`app_header.dart:57-65`), desde el borde superior de la pantalla y
/// detrás de la barra de estado, y centra el sello a lo ancho y a la altura
/// de su fila (RF-BIEN-4 y RF-BIEN-20).
class CabeceraConSello extends StatelessWidget {
  const CabeceraConSello({
    super.key,
    this.color,
    this.radioInferior = 0,
    this.sello = const SelloDelLogo(),
  });

  /// El sello cabe entre dos márgenes de 56 dp, así que la flecha «Volver»
  /// de las pantallas de la contraseña nunca queda encima (RF-BIEN-20).
  static const double margenLateral = 56;

  final Color? color;
  final double radioInferior;
  final Widget sello;

  /// La fila de la cabecera, que fija la campana de 30 dp o el texto si con
  /// letra grande es más alto.
  static double altoDeLaFila(BuildContext context) {
    final texto = TextPainter(
      text: TextSpan(
        text: 'ULIMA++',
        style: DefaultTextStyle.of(
          context,
        ).style.merge(AppHeader.estiloDeMarca(Theme.of(context).colorScheme)),
      ),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    return math.max(30, math.max(AppHeader.tamanoDeEstrella, texto.height));
  }

  static double alto(BuildContext context) =>
      50 + altoDeLaFila(context) + 20 + 2;

  static double centroDeLaFila(BuildContext context) =>
      50 + altoDeLaFila(context) / 2;

  @override
  Widget build(BuildContext context) {
    final fila = altoDeLaFila(context);
    return Container(
      height: alto(context),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(radioInferior),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: margenLateral,
            right: margenLateral,
            top: 50,
            height: fila,
            child: Center(child: sello),
          ),
        ],
      ),
    );
  }
}
```

  El pintor de la estrella dibuja el anillo del latido fuera de su caja, porque `CustomPaint` no
  recorta. `Colors.white` es el color del texto de la cabecera en los dos temas (`onPrimary`), y
  la franja lo recibe del tema en la Tarea 26.

- [ ] **Paso 4. Corre la prueba y confirma que pasa.**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/components/logo/sello_del_logo.dart test/bienvenida/bienvenida_sello_test.dart
"${FLUTTER:?}" test --no-pub test/bienvenida/bienvenida_sello_test.dart test/components/header
"${FLUTTER:?}" analyze --no-pub
```

Esperado. `All tests passed!` y `5 issues found.`.

- [ ] **Paso 5. Commit.**

```bash
cd "${REPO:?}"
git status --short
git add lib/components/logo/sello_del_logo.dart test/bienvenida/bienvenida_sello_test.dart
git commit -m "feat(bienvenida): el sello del logo a 1,22 veces la cabecera, con su latido, su pulso y una cabecera que mide lo mismo que la de /home (RF-BIEN-4)"
git log -1 --format='%an <%ae>'
```

---

### Tarea 18. El sello en las pantallas de «¿Olvidaste tu contraseña?»

**Requisitos.** RF-BIEN-20 completo (decisión B-9), salvo los avisos abajo, que hizo la Tarea 15.

**Archivos.**
- Modificar `lib/pages/password_reset/password_reset_ui.dart:100-163`.
- Modificar `lib/pages/password_reset/forgot_password_page.dart:18` y
  `lib/pages/password_reset/reset_password_page.dart:22`.
- Modificar `test/bienvenida/bienvenida_restablecer_test.dart` (grupo `el sello en la cabecera`).

**Interfaces.**
- Consume `CabeceraConSello` y `SelloDelLogo` (Tarea 17).
- Produce `PasswordResetScaffold({…, bool conSello = false})`.

- [ ] **Paso 1. Escribe la prueba que falla.** En `test/bienvenida/bienvenida_restablecer_test.dart`,
  suma estos imports y este grupo.

```dart
import 'package:flutter/services.dart';
import 'package:ulima_plus/components/logo/sello_del_logo.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/pages/password_reset/forgot_password_page.dart';
import 'package:ulima_plus/pages/password_reset/password_reset_ui.dart';
import 'package:ulima_plus/pages/password_reset/reset_password_page.dart';
```

```dart
  group('el sello en la cabecera (RF-BIEN-20 y B-9)', () {
    Future<void> montar(
      WidgetTester tester, {
      Brightness brillo = Brightness.light,
      double escala = 1,
      double teclado = 0,
      String inicial = '/forgot-password',
    }) async {
      tester.view.physicalSize = const Size(750, 1334);
      tester.view.devicePixelRatio = 2;
      tester.view.viewInsets = FakeViewPadding(bottom: teclado * 2);
      addTearDown(tester.view.reset);
      const tema = MaterialTheme(TextTheme());
      await tester.pumpWidget(
        GetMaterialApp(
          theme: brillo == Brightness.light ? tema.light() : tema.dark(),
          initialRoute: inicial,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(escala)),
            child: child!,
          ),
          getPages: [
            GetPage(
              name: '/forgot-password',
              page: () => const ForgotPasswordPage(),
              binding: BindingsBuilder(() {
                Get.lazyPut(
                  () => ForgotPasswordController(service: _ServicioFalso()),
                );
              }),
            ),
            GetPage(
              name: '/reset-password',
              page: () => const ResetPasswordPage(),
              binding: BindingsBuilder(() {
                Get.lazyPut(
                  () => ResetPasswordController(service: _ServicioFalso()),
                );
              }),
            ),
            GetPage(name: '/sello', page: () => const Scaffold(
              body: Column(children: [CabeceraConSello()]),
            )),
          ],
        ),
      );
      await tester.pump();
    }

    Rect selloDeLaFranja(WidgetTester tester) =>
        tester.getRect(find.byType(SelloDelLogo).last);

    for (final brillo in Brightness.values) {
      testWidgets('/forgot-password y /reset-password llevan el sello en el '
          'mismo lugar y del mismo tamaño que la franja (${brillo.name})', (
        tester,
      ) async {
        await montar(tester, brillo: brillo, inicial: '/sello');
        final enLaFranja = selloDeLaFranja(tester);
        Get.offAllNamed('/forgot-password');
        await tester.pumpAndSettle();
        expect(tester.getRect(find.byType(SelloDelLogo)), enLaFranja);
        Get.toNamed('/reset-password', arguments: {'identifier': '20230001'});
        await tester.pumpAndSettle();
        expect(tester.getRect(find.byType(SelloDelLogo).last), enLaFranja);
      });
    }

    testWidgets('en cada cuadro de la transición queda un sello a la vista', (
      tester,
    ) async {
      await montar(tester);
      Get.toNamed('/reset-password', arguments: {'identifier': '20230001'});
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(find.byType(SelloDelLogo), findsWidgets, reason: 'cuadro $i');
      }
      Get.back<void>();
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(find.byType(SelloDelLogo), findsWidgets, reason: 'cuadro $i');
      }
    });

    testWidgets('la flecha sigue arriba a la izquierda y el sello nunca queda '
        'bajo ella', (tester) async {
      await montar(tester);
      final flecha = tester.getRect(find.byTooltip('Volver'));
      final sello = tester.getRect(find.byType(SelloDelLogo));
      expect(flecha.left, lessThan(20));
      expect(sello.left, greaterThan(flecha.right));
    });

    for (final escala in [1.0, 1.3, 2.0]) {
      testWidgets('con el texto al ${escala * 100} % y el teclado abierto, la '
          'tarjeta queda bajo la cabecera y nada desborda', (tester) async {
        await montar(tester, escala: escala, teclado: 300);
        final cabecera = tester.getRect(find.byType(CabeceraConSello));
        final tarjeta = tester.getRect(
          find.ancestor(
            of: find.text('¿Olvidaste tu contraseña?'),
            matching: find.byType(DecoratedBox),
          ).first,
        );
        expect(tarjeta.top, greaterThanOrEqualTo(cabecera.bottom));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('declara íconos claros y el sello es un encabezado', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await montar(tester);
      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
      );
      expect(region.value.statusBarIconBrightness, Brightness.light);
      expect(
        tester.getSemantics(find.bySemanticsLabel('ULIMA++')),
        containsSemantics(isHeader: true),
      );
      semantica.dispose();
    });

    testWidgets('sin encenderlo, PasswordResetScaffold no lleva el sello, '
        'como en Portal Sync', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => PasswordResetScaffold(
              palette: PasswordResetPalette.from(context),
              child: const Text('portal'),
            ),
          ),
        ),
      );
      expect(find.byType(SelloDelLogo), findsNothing);
      expect(find.byType(CabeceraConSello), findsNothing);
    });
  });
```

- [ ] **Paso 2. Corre la prueba y confirma que falla.**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/bienvenida/bienvenida_restablecer_test.dart
```

Esperado. Fallan las pruebas del grupo nuevo, porque las pantallas no llevan el sello.

- [ ] **Paso 3. Suma la cabecera con el sello a `PasswordResetScaffold`.** En
  `lib/pages/password_reset/password_reset_ui.dart`, suma los imports y reemplaza la clase
  `PasswordResetScaffold` por esta. La tarjeta es la de hoy, en un método que usan los dos
  diseños.

```dart
import 'package:flutter/services.dart' show SystemUiOverlayStyle;

import '../../components/logo/sello_del_logo.dart';
```

```dart
/// Scaffold común del flujo: fondo, flecha de retorno y card centrada. Con
/// [conSello], la cabecera lleva el sello del logo en el mismo lugar que la
/// franja de la bienvenida, y la tarjeta queda bajo ella (RF-BIEN-20).
class PasswordResetScaffold extends StatelessWidget {
  const PasswordResetScaffold({
    super.key,
    required this.palette,
    required this.child,
    this.conSello = false,
  });

  final PasswordResetPalette palette;
  final Widget child;

  /// Lo encienden solo `/forgot-password` y `/reset-password`. Portal Sync
  /// no lo enciende y no cambia.
  final bool conSello;

  Widget _tarjeta() => SingleChildScrollView(
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.cardBorder),
          boxShadow: [
            BoxShadow(
              color: palette.cardShadow,
              blurRadius: 32,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 36, 32, 32),
          child: child,
        ),
      ),
    ),
  );

  Widget _flecha(BuildContext context) => IconButton(
    icon: Icon(Icons.arrow_back, color: palette.backIcon),
    tooltip: 'Volver',
    onPressed: () => Navigator.of(context).maybePop(),
  );

  @override
  Widget build(BuildContext context) {
    if (!conSello) {
      return Scaffold(
        backgroundColor: palette.background,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Stack(
            children: [
              Center(child: _tarjeta()),
              Positioned(top: 4, left: 4, child: _flecha(context)),
            ],
          ),
        ),
      );
    }
    // Íconos claros, porque arriba siempre hay #FF6600 o #262626.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: palette.background,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            Column(
              children: [
                // Sin color propio, porque el fondo ya es el de la franja.
                const CabeceraConSello(),
                Expanded(
                  child: SafeArea(top: false, child: Center(child: _tarjeta())),
                ),
              ],
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: _flecha(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

  En `forgot_password_page.dart` y en `reset_password_page.dart`, el `PasswordResetScaffold` suma
  `conSello: true,` después de `palette: palette,`.

- [ ] **Paso 4. Corre las pruebas y confirma que pasan.**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/pages/password_reset test/bienvenida/bienvenida_restablecer_test.dart
"${FLUTTER:?}" test --no-pub test/bienvenida test/HU20_jeff test/HU34_jeff/portal_sync_consent_test.dart test/HU01_jeff
"${FLUTTER:?}" analyze --no-pub
```

Esperado. `All tests passed!`. `test/HU20_jeff/**` y `portal_sync_consent_test.dart` siguen en
verde sin cambios. Si alguna prueba de HU20 depende del árbol de `PasswordResetScaffold`, se
ajusta solo esa búsqueda, como permite la spec. `5 issues found.`.

- [ ] **Paso 5. Commit.**

```bash
cd "${REPO:?}"
git status --short
git add lib/pages/password_reset/password_reset_ui.dart lib/pages/password_reset/forgot_password_page.dart lib/pages/password_reset/reset_password_page.dart test/bienvenida/bienvenida_restablecer_test.dart
git commit -m "feat(bienvenida): las pantallas de «¿Olvidaste tu contraseña?» llevan el sello del logo en su cabecera, en el mismo lugar que la conversación (RF-BIEN-20)"
git log -1 --format='%an <%ae>'
```

---

### Tarea 19. `LoginController` devuelve el desenlace y `RegistroController` se cierra sin GetX

**Requisitos.** De RF-BIEN-6, que `LoginController` devuelve a la bienvenida si la sesión quedó
puesta o el mensaje del error, que atrapa el fallo crudo de la red con un `finally` que apaga
`submitting` y que publica el desenlace de Google en web en un resultado observable. De RF-BIEN-5,
que vacía sus dos campos al salir la bienvenida. De RF-BIEN-9, el cierre propio del registro que
borra los cinco campos enseguida y hace el `dispose` después del cuadro (decisión B-20). De
RF-BIEN-8, el texto de «Iniciar sesión» desde `incierto` que nombra «Ya tengo cuenta» (decisión
B-30).

**Archivos.**
- Modificar `lib/pages/login/login_controller.dart`.
- Modificar `lib/pages/registro/registro_controller.dart:146-163` y `:320-324`.
- Crear `test/bienvenida/bienvenida_entrar_test.dart` (grupo `LoginController devuelve el desenlace`).
- Crear `test/bienvenida/bienvenida_credenciales_test.dart` (grupo `el cierre propio del registro`).

**Interfaces.**
- Consume `AuthService.login`, `loginWithGoogle` y `finishGoogleLogin` de hoy.
- Produce estas firmas, que usan las Tareas 23, 24 y 29.

```dart
// login_controller.dart
enum TipoDeDesenlace { sesionPuesta, error, sinConexion, cancelado }
class DesenlaceDelLogin { const DesenlaceDelLogin.sesionPuesta();
  const DesenlaceDelLogin.error(String mensaje); const DesenlaceDelLogin.sinConexion();
  const DesenlaceDelLogin.cancelado(); TipoDeDesenlace get tipo; String? get mensaje; }
Future<DesenlaceDelLogin> entrar();
Future<DesenlaceDelLogin> entrarConGoogle();
final Rxn<DesenlaceDelLogin> desenlaceDeGoogleEnWeb;
void vaciarCampos();
// registro_controller.dart
void cerrar();       // borra ya, desecha después del cuadro
bool get cerrado;
```

- [ ] **Paso 1. Escribe las pruebas que fallan.** Crea `test/bienvenida/bienvenida_entrar_test.dart`.
  Las Tareas 23 y 27 le suman los turnos.

```dart
// test/bienvenida/bienvenida_entrar_test.dart
//
// UNITARIA + WIDGET · Bienvenida con Ulises
// (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-6. LoginController deja de navegar y devuelve el desenlace, atrapa
// el fallo crudo de la red y apaga `submitting`, y vacía sus campos al
// salir. Las Tareas 23 y 27 suman los turnos E1, E2 y E3.
// Archivo probado lib/pages/login/login_controller.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/login/login_controller.dart';
import 'package:ulima_plus/services/auth_service.dart';

UserModel _alumna() => UserModel(
  code: '20230001',
  firstName: 'Alumna',
  lastName: 'De Prueba',
  email: 'test@aloe.ulima.edu.pe',
  role: 'student',
  currentCycle: '2026-2',
  setupComplete: true,
);

/// Lo que `AuthService.login` no atrapa, como un socket caído.
class _RedCaida implements Exception {
  const _RedCaida();
}

class _AuthDePrueba extends AuthService {
  _AuthDePrueba({this.error, this.redCaida = false, this.google});

  final String? error;
  final bool redCaida;

  /// Lo que devuelve Google, con 'cancelar' para el selector cerrado.
  final String? google;
  UserModel? _usuario;
  int logins = 0;

  @override
  UserModel? get currentUser => _usuario;

  @override
  Future<String?> login({required String code, required String password}) async {
    logins++;
    if (redCaida) throw const _RedCaida();
    if (error != null) return error;
    _usuario = _alumna();
    return null;
  }

  @override
  Future<String?> loginWithGoogle() async {
    if (google == 'cancelar') return null;
    if (google != null) return google;
    _usuario = _alumna();
    return null;
  }
}

LoginController _controlador(_AuthDePrueba auth) {
  Get.testMode = true;
  Get.reset();
  Get.put<AuthService>(auth);
  return LoginController()
    ..codeController.text = '20230001'
    ..passwordController.text = 'secreta-de-prueba';
}

void main() {
  group('LoginController devuelve el desenlace (RF-BIEN-6)', () {
    tearDown(Get.reset);

    test('con la sesión puesta devuelve sesionPuesta y no navega', () async {
      final c = _controlador(_AuthDePrueba());
      final d = await c.entrar();
      expect(d.tipo, TipoDeDesenlace.sesionPuesta);
      expect(c.submitting.value, isFalse);
      expect(Get.currentRoute, isNot('/home'));
    });

    test('un login rechazado devuelve el mensaje de hoy', () async {
      final c = _controlador(
        _AuthDePrueba(error: 'Código o contraseña incorrectos.'),
      );
      final d = await c.entrar();
      expect(d.tipo, TipoDeDesenlace.error);
      expect(d.mensaje, 'Código o contraseña incorrectos.');
    });

    test('un fallo crudo de la red devuelve sinConexion y apaga submitting',
        () async {
      final c = _controlador(_AuthDePrueba(redCaida: true));
      final d = await c.entrar();
      expect(d.tipo, TipoDeDesenlace.sinConexion);
      expect(c.submitting.value, isFalse);
    });

    test('con un campo vacío no llama al backend', () async {
      final auth = _AuthDePrueba();
      final c = _controlador(auth)..passwordController.text = '';
      final d = await c.entrar();
      expect(d.tipo, TipoDeDesenlace.error);
      expect(d.mensaje, 'Ingresa tu código y contraseña.');
      expect(auth.logins, 0);
    });

    test('Google cancelado no hace nada, un error trae su mensaje', () async {
      final cancelado = _controlador(_AuthDePrueba(google: 'cancelar'));
      expect((await cancelado.entrarConGoogle()).tipo, TipoDeDesenlace.cancelado);
      final conError = _controlador(
        _AuthDePrueba(google: 'Tu correo no está registrado en el sistema.'),
      );
      final d = await conError.entrarConGoogle();
      expect(d.tipo, TipoDeDesenlace.error);
      expect(d.mensaje, 'Tu correo no está registrado en el sistema.');
      final bien = _controlador(_AuthDePrueba());
      expect((await bien.entrarConGoogle()).tipo, TipoDeDesenlace.sesionPuesta);
    });

    test('vaciarCampos borra el código y la contraseña', () {
      final c = _controlador(_AuthDePrueba())..vaciarCampos();
      expect(c.codeController.text, '');
      expect(c.passwordController.text, '');
      expect(c.passwordVisible.value, isFalse);
    });
  });
}
```

  Crea `test/bienvenida/bienvenida_credenciales_test.dart`. La Tarea 24 le suma los turnos.

```dart
// test/bienvenida/bienvenida_credenciales_test.dart
//
// UNITARIA + WIDGET · Bienvenida con Ulises
// (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-9 y B-20. La bienvenida cierra el controlador del registro sin
// GetX. Cerrarlo borra los cinco campos enseguida y los desecha después del
// cuadro en que el campo del compositor sale del árbol. La Tarea 24 suma los
// turnos y el oráculo de cuentas.
// Archivo probado lib/pages/registro/registro_controller.dart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/pages/registro/registro_controller.dart';

void main() {
  group('el cierre propio del registro (RF-BIEN-9 y B-20)', () {
    testWidgets('cerrar borra los cinco campos enseguida y los desecha '
        'después del cuadro, sin error de un campo desechado', (tester) async {
      final c = RegistroController(
        adoptarSesion: ({required token, required user}) async {},
        iniciarSesion: ({required code, required password}) async => null,
      );
      final campos = [
        c.codigoCtrl,
        c.passwordCtrl,
        c.confirmacionCtrl,
        c.portalPasswordCtrl,
        c.passcodeCtrl,
      ];
      for (final campo in campos) {
        campo.text = 'dato-de-prueba';
      }
      final mostrar = ValueNotifier<bool>(true);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<bool>(
              valueListenable: mostrar,
              builder: (_, visible, _) => visible
                  ? TextField(controller: c.passwordCtrl)
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      );
      // Como la bienvenida, primero saca el campo y en el mismo cuadro cierra.
      mostrar.value = false;
      c.cerrar();
      expect(c.cerrado, isTrue);
      for (final campo in campos) {
        expect(campo.text, '', reason: 'se borra enseguida');
      }
      await tester.pump();
      await tester.pump();
      expect(tester.takeException(), isNull);
      for (final campo in campos) {
        expect(() => campo.addListener(() {}), throwsFlutterError);
      }
      // Cerrar dos veces no hace nada.
      c.cerrar();
    });

    test('el texto de «Iniciar sesión» desde incierto nombra «Ya tengo '
        'cuenta» (B-30)', () async {
      final c = RegistroController(
        adoptarSesion: ({required token, required user}) async {},
        iniciarSesion: ({required code, required password}) async =>
            'Código o contraseña incorrectos.',
      )..paso.value = RegistroPaso.incierto;
      expect(await c.intentarIniciarSesion(), isFalse);
      expect(
        c.errorMessage.value,
        'Seguimos sin poder confirmarlo. Puedes volver a intentar el '
        'registro: si te dice que ya existe una cuenta con ese código, es que '
        'sí se creó y puedes recuperar la contraseña con “Ya tengo cuenta”.',
      );
    });
  });
}
```

- [ ] **Paso 2. Corre las pruebas y confirma que fallan.**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/bienvenida/bienvenida_entrar_test.dart test/bienvenida/bienvenida_credenciales_test.dart
```

Esperado. Falla la compilación, porque `entrar`, `DesenlaceDelLogin`, `cerrar` y `cerrado` no
existen.

- [ ] **Paso 3. Cambia `LoginController`.** En `lib/pages/login/login_controller.dart`, suma el
  desenlace antes de la clase y reemplaza el cuerpo desde `_onGoogleUserChanged` hasta
  `loginWithGoogle` por esto. `submit` y `loginWithGoogle` quedan como envoltorios que navegan,
  solo para la tarjeta de hoy, y la Tarea 29 los borra (decisión 7 del plan).

```dart
enum TipoDeDesenlace { sesionPuesta, error, sinConexion, cancelado }

/// Lo que devuelve un intento de entrar. La bienvenida decide el turno
/// siguiente con él, y el controlador ya no navega (RF-BIEN-6).
class DesenlaceDelLogin {
  const DesenlaceDelLogin.sesionPuesta()
    : tipo = TipoDeDesenlace.sesionPuesta,
      mensaje = null;
  const DesenlaceDelLogin.error(String this.mensaje)
    : tipo = TipoDeDesenlace.error;
  const DesenlaceDelLogin.sinConexion()
    : tipo = TipoDeDesenlace.sinConexion,
      mensaje = null;
  const DesenlaceDelLogin.cancelado()
    : tipo = TipoDeDesenlace.cancelado,
      mensaje = null;

  final TipoDeDesenlace tipo;
  final String? mensaje;
}
```

```dart
  /// El desenlace del login con Google en web, que llega por
  /// `onCurrentUserChanged` sin nadie que lo espere (RF-BIEN-6).
  final desenlaceDeGoogleEnWeb = Rxn<DesenlaceDelLogin>();

  Future<void> _onGoogleUserChanged(GoogleSignInAccount? account) async {
    if (account == null || submitting.value) return;
    errorMessage.value = null;
    submitting.value = true;
    try {
      final error = await _auth.finishGoogleLogin(account);
      final desenlace = error == null
          ? const DesenlaceDelLogin.sesionPuesta()
          : DesenlaceDelLogin.error(error);
      if (error != null) errorMessage.value = error;
      desenlaceDeGoogleEnWeb.value = desenlace;
      // Solo la tarjeta de hoy navega. La Tarea 29 quita estas dos líneas.
      final user = _auth.currentUser;
      if (error == null && user != null) Get.offAllNamed(postLoginRoute(user));
    } catch (_) {
      desenlaceDeGoogleEnWeb.value = const DesenlaceDelLogin.sinConexion();
    } finally {
      submitting.value = false;
    }
  }

  /// Limpia el formulario. Se llama al (re)entrar a /login porque el
  /// LoginController es permanente (ver LoginBinding).
  void resetFields() {
    vaciarCampos();
    submitting.value = false;
  }

  /// Vacía el código y la contraseña. La bienvenida lo llama al salir hacia
  /// el horario, al reiniciarse y tras un 401, así que la contraseña ya no
  /// queda en el campo durante toda la sesión (RF-BIEN-5).
  void vaciarCampos() {
    codeController.clear();
    passwordController.clear();
    errorMessage.value = null;
    passwordVisible.value = false;
  }

  /// Entra con código o usuario y contraseña, sin navegar.
  Future<DesenlaceDelLogin> entrar() async {
    final code = codeController.text.trim();
    final password = passwordController.text;
    if (code.isEmpty || password.isEmpty) {
      // Es solo defensa, porque la bienvenida no deja enviar un campo vacío.
      const mensaje = 'Ingresa tu código y contraseña.';
      errorMessage.value = mensaje;
      return const DesenlaceDelLogin.error(mensaje);
    }
    errorMessage.value = null;
    submitting.value = true;
    try {
      final error = await _auth.login(code: code, password: password);
      if (error != null) {
        errorMessage.value = error;
        return DesenlaceDelLogin.error(error);
      }
      return const DesenlaceDelLogin.sesionPuesta();
    } catch (_) {
      // `AuthService.login` solo atrapa ApiException, y un fallo de red sale
      // crudo. Antes dejaba el botón girando.
      return const DesenlaceDelLogin.sinConexion();
    } finally {
      submitting.value = false;
    }
  }

  /// Entra con Google en Android e iOS, sin navegar.
  Future<DesenlaceDelLogin> entrarConGoogle() async {
    errorMessage.value = null;
    submitting.value = true;
    try {
      final error = await _auth.loginWithGoogle();
      if (error != null) {
        errorMessage.value = error;
        return DesenlaceDelLogin.error(error);
      }
      // `loginWithGoogle` devuelve null también cuando la persona cancela.
      return _auth.currentUser == null
          ? const DesenlaceDelLogin.cancelado()
          : const DesenlaceDelLogin.sesionPuesta();
    } catch (_) {
      return const DesenlaceDelLogin.sinConexion();
    } finally {
      submitting.value = false;
    }
  }

  /// La tarjeta de hoy, hasta la Tarea 29.
  Future<void> submit() async {
    final d = await entrar();
    if (d.tipo == TipoDeDesenlace.sinConexion) {
      errorMessage.value =
          'No hay conexión. Revisa tu internet e inténtalo de nuevo.';
    }
    final user = _auth.currentUser;
    if (d.tipo == TipoDeDesenlace.sesionPuesta && user != null) {
      Get.offAllNamed(postLoginRoute(user));
    }
  }

  /// La tarjeta de hoy, hasta la Tarea 29.
  Future<void> loginWithGoogle() async {
    final d = await entrarConGoogle();
    final user = _auth.currentUser;
    if (d.tipo == TipoDeDesenlace.sesionPuesta && user != null) {
      Get.offAllNamed(postLoginRoute(user));
    }
  }
```

- [ ] **Paso 4. Cambia `RegistroController`.** En `lib/pages/registro/registro_controller.dart`,
  suma el import de `package:flutter/scheduler.dart` y reemplaza `onClose` por esto.

```dart
  bool _cerrado = false;

  /// Si el tramo del registro ya se cerró.
  bool get cerrado => _cerrado;

  /// Cierra el registro sin GetX, como lo hace la bienvenida (B-20). Borra
  /// los cinco campos enseguida y los desecha después del cuadro en que el
  /// campo del compositor ya no está en el árbol, para no reabrir el error de
  /// un TextEditingController usado después de su dispose.
  void cerrar() {
    if (_cerrado) return;
    _cerrado = true;
    final campos = _campos;
    for (final c in campos) {
      c.clear();
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      for (final c in campos) {
        c.dispose();
      }
    });
    SchedulerBinding.instance.scheduleFrame();
  }

  List<TextEditingController> get _campos => <TextEditingController>[
    codigoCtrl,
    passwordCtrl,
    confirmacionCtrl,
    portalPasswordCtrl,
    passcodeCtrl,
  ];

  @override
  void onClose() {
    // Por la ruta /registro de hoy, que la Tarea 29 quita. `clear()` antes
    // de `dispose()`, así el texto no queda en el buffer del campo.
    if (!_cerrado) {
      _cerrado = true;
      for (final c in _campos) {
        c.clear();
        c.dispose();
      }
    }
    super.onClose();
  }
```

  En `enviar`, después de cada `await` (el de `_service.registrar` y el de `_adoptar`), suma
  `if (_cerrado) return;`, para que una respuesta tardía no toque campos ya borrados. Cambia el
  final del texto de `intentarIniciarSesion` (`registro_controller.dart:320-323`) por este.

```dart
    errorMessage.value =
        'Seguimos sin poder confirmarlo. Puedes volver a intentar el registro: '
        'si te dice que ya existe una cuenta con ese código, es que sí se creó '
        'y puedes recuperar la contraseña con “Ya tengo cuenta”.';
```

  El comentario de los campos (`registro_controller.dart:100-102`) cambia su primera frase por
  «Los cinco campos viven solo acá. Las dos contraseñas, la repetición y el código del
  authenticator nunca entran en un Rx, en el historial, en un registro ni en el disco. El código
  de alumno es la excepción, porque su burbuja lo muestra en la conversación (RF-BIEN-9).».

- [ ] **Paso 5. Corre las pruebas y confirma que pasan.**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/pages/login/login_controller.dart lib/pages/registro/registro_controller.dart test/bienvenida
"${FLUTTER:?}" test --no-pub test/bienvenida test/HU01_jeff test/HU33_jeff test/HU34_jeff
"${FLUTTER:?}" analyze --no-pub
```

Esperado. `All tests passed!`. Las pruebas de hoy del login y del registro siguen en verde,
porque la tarjeta y la ruta `/registro` no cambian todavía. `5 issues found.`.

- [ ] **Paso 6. Suite completa y commit.** Corre la suite completa en segundo plano. Esperado,
  `All tests passed!`.

```bash
cd "${REPO:?}"
git status --short
git add lib/pages/login/login_controller.dart lib/pages/registro/registro_controller.dart test/bienvenida/bienvenida_entrar_test.dart test/bienvenida/bienvenida_credenciales_test.dart
git commit -m "feat(bienvenida): LoginController devuelve el desenlace sin colgarse sin red y RegistroController se cierra sin GetX, con el texto de incierto que nombra «Ya tengo cuenta» (RF-BIEN-6, RF-BIEN-9 y B-30)"
git log -1 --format='%an <%ae>'
```

- [ ] **Paso 7. Punto de control.** Las Tareas 1 a 19 no usan el código del test de
  especialidad, que la rama ya trae desde `fcbf2e7`. Antes de seguir, el informe anota si
  `origin/main` avanzó y, si avanzó, el merge aparte que lo trae («La rama del test de
  especialidad»).

---

### Tarea 20. Los tokens de la bienvenida, sobre el test que ya está en la rama

**Requisitos.** RF-BIEN-14 completo (decisión B-24, con B-3 en `bienvenidaNuevoFondo`). **Desde
esta tarea el plan usa el código del test de especialidad**, que la rama trae desde `fcbf2e7`
(«La rama del test de especialidad»), así que la tarea no hace ningún merge.

**Archivos.**
- Modificar `lib/configs/themes.dart` (tokens `bienvenida*`).
- Crear `test/bienvenida/bienvenida_contraste_test.dart`.

**Interfaces.**
- Consume los tokens `test*` de la Tarea 2 del plan del test y `razonDeContraste` de
  `specialty_test_logic.dart`.
- Produce, en `MaterialTheme`, `static Color bienvenidaFranja(Brightness b)` y los otros 17
  tokens de la tabla de RF-BIEN-14, con los mismos nombres de la spec.

- [ ] **Paso 1. Comprueba que la rama trae el test.**

```bash
cd "${REPO:?}"
git status --short
git merge-base --is-ancestor f4871c1 HEAD && echo "el test está en la rama"
grep -c "Implementada en la rama" specs/features/specialty-test/specialty-test.spec.md
ls test/HU36_jeff | wc -l
```

Esperado. `git status --short` vacío, `el test está en la rama`, un `1` de la spec del test, que
dice en su estado que está implementada, y las pruebas de `test/HU36_jeff/`. Si falta algo, la
tarea se detiene y el informe lo dice, porque las Tareas 21 y 22 cambian el controlador y las
vistas del test. Las cifras de `analyze` y de la suite son las de la base, con `5 issues found.`
desde la Tarea 14.

- [ ] **Paso 2. Escribe la prueba que falla.** Crea `test/bienvenida/bienvenida_contraste_test.dart`.

```dart
// test/bienvenida/bienvenida_contraste_test.dart
//
// UNITARIA · Bienvenida con Ulises (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-14. Los tokens nuevos en los dos temas y cada par de la tabla de
// contraste, con las dos excepciones de la spec.
// Archivo probado lib/configs/themes.dart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_logic.dart';

typedef _Token = Color Function(Brightness);

const _claro = Brightness.light;
const _oscuro = Brightness.dark;

void main() {
  group('los tokens nuevos (RF-BIEN-14)', () {
    final tabla = <String, (_Token, int, int)>{
      'bienvenidaFranja': (MaterialTheme.bienvenidaFranja, 0xFFFF6600, 0xFF262626),
      'bienvenidaPropia': (MaterialTheme.bienvenidaPropia, 0xFFFFE7D4, 0xFF3A2A22),
      'bienvenidaPropiaTinta':
          (MaterialTheme.bienvenidaPropiaTinta, 0xFF6B2D00, 0xFFFFC49A),
      'bienvenidaSaludo': (MaterialTheme.bienvenidaSaludo, 0xFFFFFFFF, 0xFF33333B),
      'bienvenidaSaludoTinta':
          (MaterialTheme.bienvenidaSaludoTinta, 0xFF1A0E05, 0xFFF5F5F7),
      'bienvenidaSaludoSub':
          (MaterialTheme.bienvenidaSaludoSub, 0xFF7A3300, 0xFFFFC49A),
      'bienvenidaEntrarFondo':
          (MaterialTheme.bienvenidaEntrarFondo, 0xFFFFFFFF, 0xFFFF8C42),
      'bienvenidaEntrarTinta':
          (MaterialTheme.bienvenidaEntrarTinta, 0xFF1A0E05, 0xFF16161C),
      'bienvenidaNuevoFondo':
          (MaterialTheme.bienvenidaNuevoFondo, 0xFFB84A00, 0x00000000),
      'bienvenidaNuevoBorde':
          (MaterialTheme.bienvenidaNuevoBorde, 0xFFFFFFFF, 0xFF5A5A66),
      'bienvenidaNuevoTinta':
          (MaterialTheme.bienvenidaNuevoTinta, 0xFFFFFFFF, 0xFFEDEDF3),
      'bienvenidaPildora': (MaterialTheme.bienvenidaPildora, 0xFF0F172A, 0xFF33333B),
      'bienvenidaPildoraLista':
          (MaterialTheme.bienvenidaPildoraLista, 0xFF15803D, 0xFF15803D),
      'bienvenidaGoogleFondo':
          (MaterialTheme.bienvenidaGoogleFondo, 0xFFFFFFFF, 0xFF131314),
      'bienvenidaGoogleBorde':
          (MaterialTheme.bienvenidaGoogleBorde, 0xFF747775, 0xFF8E918F),
      'bienvenidaGoogleTinta':
          (MaterialTheme.bienvenidaGoogleTinta, 0xFF1F1F1F, 0xFFE3E3E3),
      'bienvenidaFoco': (MaterialTheme.bienvenidaFoco, 0xFFD45500, 0xFFFF8C42),
    };

    for (final MapEntry(key: nombre, value: (token, claro, oscuro))
        in tabla.entries) {
      test('$nombre en claro y en oscuro', () {
        expect(token(_claro).toARGB32(), claro, reason: '$nombre claro');
        expect(token(_oscuro).toARGB32(), oscuro, reason: '$nombre oscuro');
      });
    }
  });

  group('la tabla de contraste (RF-BIEN-14)', () {
    void par(String nombre, Color texto, Color fondo, double esperado) {
      final razon = razonDeContraste(texto, fondo);
      expect(razon, closeTo(esperado, 0.01), reason: nombre);
    }

    for (final b in [_claro, _oscuro]) {
      final claro = b == _claro;
      test('cada par de la tabla en ${b.name}', () {
        par('burbujas', MaterialTheme.textPrimary(b), MaterialTheme.cardBg(b),
            claro ? 17.85 : 14.22);
        par('nombre Ulises', MaterialTheme.testMuted(b), MaterialTheme.pageBg(b),
            claro ? 6.09 : 7.42);
        par('respuesta del alumno', MaterialTheme.bienvenidaPropiaTinta(b),
            MaterialTheme.bienvenidaPropia(b), claro ? 8.81 : 8.87);
        par('pregunta', MaterialTheme.bienvenidaSaludoTinta(b),
            MaterialTheme.bienvenidaSaludo(b), claro ? 18.94 : 11.50);
        par('saludo', MaterialTheme.bienvenidaSaludoSub(b),
            MaterialTheme.bienvenidaSaludo(b), claro ? 9.13 : 8.12);
        par('Sí, entrar', MaterialTheme.bienvenidaEntrarTinta(b),
            MaterialTheme.bienvenidaEntrarFondo(b), claro ? 18.94 : 7.79);
        // Soy nuevo en oscuro es transparente sobre la franja.
        par('Soy nuevo', MaterialTheme.bienvenidaNuevoTinta(b),
            claro ? MaterialTheme.bienvenidaNuevoFondo(b)
                : MaterialTheme.bienvenidaFranja(b),
            claro ? 5.23 : 12.98);
        par('pista', MaterialTheme.testMuted(b), MaterialTheme.testChipBg(b),
            claro ? 5.67 : 6.34);
        par('enlaces', MaterialTheme.testAccentText(b), MaterialTheme.cardBg(b),
            claro ? 5.23 : 7.91);
        par('rellenos', MaterialTheme.testAccentInk(b), MaterialTheme.testAccent(b),
            claro ? 6.45 : 7.79);
        par('píldora', Colors.white, MaterialTheme.bienvenidaPildora(b),
            claro ? 17.85 : 12.52);
        par('píldora lista', Colors.white, MaterialTheme.bienvenidaPildoraLista(b),
            5.02);
        par('Google', MaterialTheme.bienvenidaGoogleTinta(b),
            MaterialTheme.bienvenidaGoogleFondo(b), claro ? 16.48 : 14.47);
        par('borde de Google', MaterialTheme.bienvenidaGoogleBorde(b),
            claro ? MaterialTheme.bienvenidaGoogleFondo(b) : MaterialTheme.cardBg(b),
            claro ? 4.53 : 5.21);
        par('foco', MaterialTheme.bienvenidaFoco(b), MaterialTheme.cardBg(b),
            claro ? 4.12 : 7.17);
        par('sello', Colors.white, MaterialTheme.bienvenidaFranja(b),
            claro ? 2.94 : 15.13);
      });
    }

    test('las dos excepciones son las de la spec', () {
      // El blanco sobre #FF6600 del sello es el de la cabecera de toda la app.
      expect(
        razonDeContraste(Colors.white, MaterialTheme.bienvenidaFranja(_claro)),
        lessThan(4.5),
      );
      // El logo del primer cuadro es un dibujo sin texto.
      expect(
        razonDeContraste(Colors.white, const Color(0xFFE77330)),
        closeTo(3.05, 0.01),
      );
    });
  });
}
```

- [ ] **Paso 3. Corre la prueba y confirma que falla.**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/bienvenida/bienvenida_contraste_test.dart
```

Esperado. Falla la compilación, porque los tokens `bienvenida*` no existen.

- [ ] **Paso 4. Suma los tokens.** En `lib/configs/themes.dart`, después de los tokens `test*` del
  test de especialidad, suma estos.

```dart
  // ── Bienvenida con Ulises (RF-BIEN-14) ──────────────────────────────────

  /// La franja del sello y el fondo del recibimiento después del relevo.
  static Color bienvenidaFranja(Brightness b) =>
      b == Brightness.light ? primaryColor : const Color(0xFF262626);

  /// Fondo de las respuestas del alumno.
  static Color bienvenidaPropia(Brightness b) =>
      b == Brightness.light ? const Color(0xFFFFE7D4) : const Color(0xFF3A2A22);

  /// Texto de las respuestas del alumno.
  static Color bienvenidaPropiaTinta(Brightness b) =>
      b == Brightness.light ? const Color(0xFF6B2D00) : const Color(0xFFFFC49A);

  /// Tarjeta del saludo del recibimiento.
  static Color bienvenidaSaludo(Brightness b) =>
      b == Brightness.light ? Colors.white : const Color(0xFF33333B);

  /// «¿Ya usas ULima++?».
  static Color bienvenidaSaludoTinta(Brightness b) =>
      b == Brightness.light ? const Color(0xFF1A0E05) : const Color(0xFFF5F5F7);

  /// «¡Craa! Hola, soy Ulises 👋» en la tarjeta.
  static Color bienvenidaSaludoSub(Brightness b) =>
      b == Brightness.light ? const Color(0xFF7A3300) : const Color(0xFFFFC49A);

  /// Botón «Sí, entrar».
  static Color bienvenidaEntrarFondo(Brightness b) =>
      b == Brightness.light ? Colors.white : const Color(0xFFFF8C42);

  static Color bienvenidaEntrarTinta(Brightness b) =>
      b == Brightness.light ? const Color(0xFF1A0E05) : const Color(0xFF16161C);

  /// Botón «Soy nuevo», naranja oscuro en claro (B-3) y transparente en
  /// oscuro.
  static Color bienvenidaNuevoFondo(Brightness b) =>
      b == Brightness.light ? const Color(0xFFB84A00) : const Color(0x00000000);

  /// Borde de 1,5 dp de «Soy nuevo».
  static Color bienvenidaNuevoBorde(Brightness b) =>
      b == Brightness.light ? Colors.white : const Color(0xFF5A5A66);

  static Color bienvenidaNuevoTinta(Brightness b) =>
      b == Brightness.light ? Colors.white : const Color(0xFFEDEDF3);

  /// Píldora «Creando tu cuenta…».
  static Color bienvenidaPildora(Brightness b) =>
      b == Brightness.light ? const Color(0xFF0F172A) : const Color(0xFF33333B);

  /// Píldora «Cuenta creada».
  static Color bienvenidaPildoraLista(Brightness b) => const Color(0xFF15803D);

  /// Botón «Continuar con Google», con los colores de la marca de Google.
  static Color bienvenidaGoogleFondo(Brightness b) =>
      b == Brightness.light ? Colors.white : const Color(0xFF131314);

  static Color bienvenidaGoogleBorde(Brightness b) =>
      b == Brightness.light ? const Color(0xFF747775) : const Color(0xFF8E918F);

  static Color bienvenidaGoogleTinta(Brightness b) =>
      b == Brightness.light ? const Color(0xFF1F1F1F) : const Color(0xFFE3E3E3);

  /// Borde del campo con foco y anillo de foco del teclado.
  static Color bienvenidaFoco(Brightness b) =>
      b == Brightness.light ? primaryDark : const Color(0xFFFF8C42);
```

- [ ] **Paso 5. Corre las pruebas y confirma que pasan.**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/configs/themes.dart test/bienvenida/bienvenida_contraste_test.dart
"${FLUTTER:?}" test --no-pub test/bienvenida/bienvenida_contraste_test.dart test/HU36_jeff/specialty_test_contraste_test.dart
"${FLUTTER:?}" analyze --no-pub
```

Esperado. `All tests passed!` y `5 issues found.`. Si un par de los tokens `test*` no da la cifra
de la spec de la bienvenida, se revisa primero el valor del token del test, y la diferencia va al
informe para el dueño sin cambiar el token del test.

- [ ] **Paso 6. Commit.**

```bash
cd "${REPO:?}"
git status --short
git add lib/configs/themes.dart test/bienvenida/bienvenida_contraste_test.dart
git commit -m "feat(bienvenida): los tokens de la bienvenida en los dos temas con la tabla de contraste de la spec (RF-BIEN-14)"
git log -1 --format='%an <%ae>'
```

---

### Tarea 21. El controlador del test acepta el origen `bienvenida`

**Requisitos.** La enmienda aprobada a la spec del test, en RF-TEST-1 (el origen `bienvenida`,
creado y cerrado sin `SpecialtyTestBinding`), RF-TEST-2 (sin precarga ni pausa, y lo que responde
después del cierre se descarta), RF-TEST-3 (sin «Seguir el test» ni «Empezar de nuevo»), RF-TEST-8
(el atrás en el resultado no hace nada) y RF-TEST-9 (los dos botones terminan en el paso al
horario), con la decisión B-34 y, de RF-BIEN-10, «Sin carrera».

**Archivos.**
- Modificar `lib/pages/specialty_test/specialty_test_controller.dart`.
- Crear `test/bienvenida/bienvenida_test_especialidad_test.dart` (grupo `el controlador con
  origen bienvenida`).

**Interfaces.**
- Consume `SpecialtyTestController`, `SpecialtyTestUi` y `TextosDelTest` de la rama del test, y
  sus apoyos de prueba `prepararTest`, `UiFalsa`, `ApiFalsaDelTest`, `alumno`,
  `respuestasEnOrden` y `responderPasos` de `test/HU36_jeff/`.
- Produce `OrigenDelTest.bienvenida`, `bool get enBienvenida`, `bool get terminaEnElHome` y
  `TextosDelTest.sinCarrera`.

- [ ] **Paso 1. Escribe la prueba que falla.** Crea
  `test/bienvenida/bienvenida_test_especialidad_test.dart`. Las Tareas 22, 25 y 27 le suman sus
  grupos.

```dart
// test/bienvenida/bienvenida_test_especialidad_test.dart
//
// UNITARIA + WIDGET · Bienvenida con Ulises
// (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-10 y la enmienda aprobada a la spec del test. Con el origen
// `bienvenida`, el controlador del test se crea y se cierra sin GetX, no usa
// la precarga ni la pausa, termina en el paso al horario y descarta lo que
// responde después de cerrarse. Las Tareas 22, 25 y 27 suman las piezas
// compactas y los turnos del test en la conversación.
// Archivo probado lib/pages/specialty_test/specialty_test_controller.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/specialty_test_models.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';

import '../HU36_jeff/datos_de_prueba.dart';
import '../HU36_jeff/dobles_de_red.dart';
import '../HU36_jeff/dobles_del_controlador.dart';

/// El controlador como lo crea la bienvenida, sin Get.put.
Future<SpecialtyTestController> _enLaBienvenida(UiFalsa ui) async {
  final c = SpecialtyTestController(origen: OrigenDelTest.bienvenida, ui: ui)
    ..onStart();
  await pumpEventQueue();
  return c;
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  group('el controlador con origen bienvenida (enmienda a RF-TEST-1, '
      'RF-TEST-2 y RF-TEST-9, B-34)', () {
    test('no adopta un test en pausa ni deja uno al cerrarse', () async {
      final (:auth, :service) = prepararTest(ApiFalsaDelTest());
      final c = await _enLaBienvenida(UiFalsa());
      expect(c.enBienvenida, isTrue);
      expect(c.terminaEnElHome, isTrue);
      c.empezar();
      c.responder('top', avanceSolo: false);
      c.onDelete();
      expect(service.paused, isNull);
      expect(auth.guardados, isEmpty);
    });

    test('pide el contenido una vez, sin la precarga', () async {
      final api = ApiFalsaDelTest();
      final (auth: _, :service) = prepararTest(api);
      service.prefetchContent();
      await pumpEventQueue();
      final antes = api.getsDeContenido;
      final c = await _enLaBienvenida(UiFalsa());
      expect(api.getsDeContenido, antes + 1);
      expect(c.carga.value, EstadoDeCarga.lista);
    });

    test('«Elegir como principal» y «Decidir después» terminan en el paso '
        'al horario, como el asistente', () async {
      prepararTest(ApiFalsaDelTest());
      final ui = UiFalsa();
      final c = await _enLaBienvenida(ui);
      c.empezar();
      responderPasos(c, respuestasEnOrden);
      await pumpEventQueue();
      expect(c.resultado.value, isNotNull);
      await c.elegirPrincipal(c.resultado.value!.ranking.first.specialtyId);
      expect(ui.alHome, 1);
      expect(ui.cierres, isEmpty);
    });

    test('el atrás en el resultado no hace nada', () async {
      prepararTest(ApiFalsaDelTest());
      final ui = UiFalsa();
      final c = await _enLaBienvenida(ui);
      c.empezar();
      responderPasos(c, respuestasEnOrden);
      await pumpEventQueue();
      c.atrasEnResultado();
      await pumpEventQueue();
      expect(ui.alHome, 0);
      expect(ui.cierres, isEmpty);
    });

    test('un 404 pasa a la selección manual sin aviso', () async {
      prepararTest(
        ApiFalsaDelTest(
          contenido: <Object>[
            const SpecialtyTestFailure(
              SpecialtyTestFailureKind.notAvailable,
              message:
                  'El test de especialidad no está disponible para tu carrera.',
            ),
          ],
        ),
      );
      final ui = UiFalsa();
      await _enLaBienvenida(ui);
      expect(ui.cierres, [SalidaDelTest.seleccionManual]);
      expect(ui.avisos, isEmpty);
    });

    test('sin carrera no llama a completeSetup y avisa «No se pudo determinar '
        'tu carrera.»', () async {
      final sinCarrera = UserModel(
        code: '20230001',
        firstName: 'Alumna',
        lastName: 'De Prueba',
        email: 'test@aloe.ulima.edu.pe',
        role: 'student',
        currentCycle: '2026-2',
        setupComplete: false,
      );
      final (:auth, service: _) = prepararTest(
        ApiFalsaDelTest(),
        usuario: sinCarrera,
      );
      final ui = UiFalsa();
      final c = await _enLaBienvenida(ui);
      c.empezar();
      responderPasos(c, respuestasEnOrden);
      await pumpEventQueue();
      await c.decidirDespues();
      expect(auth.guardados, isEmpty);
      expect(ui.avisos.single.mensaje, 'No se pudo determinar tu carrera.');
      expect(ui.alHome, 0);
    });

    test('una evaluación que responde después del cierre se descarta', () async {
      prepararTest(ApiFalsaDelTest());
      final ui = UiFalsa();
      final c = await _enLaBienvenida(ui);
      c.empezar();
      responderPasos(c, respuestasEnOrden);
      c.onDelete();
      await pumpEventQueue();
      expect(c.resultado.value, isNull);
      expect(ui.cierres, isEmpty);
      expect(ui.avisos, isEmpty);
    });
  });
}
```

  `ApiFalsaDelTest` devuelve como error lo que no es un mapa, y
  `SpecialtyTestFailure.from` deja pasar un fallo ya traducido, así que la cola acepta el 404 en
  esa forma.

- [ ] **Paso 2. Corre la prueba y confirma que falla.**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/bienvenida/bienvenida_test_especialidad_test.dart
```

Esperado. Falla la compilación, porque `OrigenDelTest.bienvenida`, `enBienvenida` y
`terminaEnElHome` no existen.

- [ ] **Paso 3. Suma el origen.** En `lib/pages/specialty_test/specialty_test_controller.dart`, haz
  estos cambios. Los fragmentos son los de `f4871c1`, y si el código de la rama cambió, se aplica la
  misma regla en su lugar nuevo.

  1. El origen y el texto nuevo.

```dart
/// De dónde se abre el test. Con `bienvenida`, el test corre dentro de la
/// conversación con Ulises, sin la ruta /test-especialidad (enmienda de la
/// spec de la bienvenida a RF-TEST-1).
enum OrigenDelTest { asistente, perfil, bienvenida }
```

```dart
  /// Sin `careerId`, en la conversación, como el asistente de hoy
  /// (`setup_carrera_controller.dart:123-126` y RF-BIEN-10).
  static const String sinCarrera = 'No se pudo determinar tu carrera.';
```

  2. Los getters, junto a `enAsistente`.

```dart
  bool get enBienvenida => origen == OrigenDelTest.bienvenida;

  /// El asistente y la bienvenida terminan en el home y pasan a la
  /// selección manual. El Perfil cierra su ruta.
  bool get terminaEnElHome => origen != OrigenDelTest.perfil;
```

  3. En `onInit`, el test en pausa solo se adopta fuera de la bienvenida.

```dart
    final pausado = enBienvenida ? null : _service.paused;
```

  4. En `onClose`, la pausa solo se guarda fuera de la bienvenida.

```dart
    if (hayAvance && c != null && !enBienvenida) {
```

  5. En `_borrarRespuestas`, la pausa del service solo se descarta fuera de la bienvenida.

```dart
    if (!enBienvenida) _service.discardPaused();
```

  6. En `_noDisponible`, `enAsistente` pasa a `terminaEnElHome` en las dos líneas.

```dart
    if (!terminaEnElHome || avisarSiempre) {
      _ui.avisar(
        AvisoDelTest(TipoDeAviso.info, mensaje ?? TextosDelTest.noDisponible),
      );
    }
    _ui.cerrar(terminaEnElHome ? SalidaDelTest.seleccionManual : null);
```

  7. En `elegirPrincipal`, `decidirDespues` y `atrasEnResultado`, `enAsistente` pasa a
     `terminaEnElHome` (tres sitios, `if (enAsistente) {`, `if (!enAsistente) {` y
     `if (enAsistente) return;`).

  8. En `_guardar`, el aviso sin carrera depende del origen.

```dart
    if (careerId == null) {
      return AvisoDelTest(
        TipoDeAviso.error,
        enBienvenida ? TextosDelTest.sinCarrera : TextosDelTest.noSeGuardo,
      );
    }
```

- [ ] **Paso 4. Corre las pruebas y confirma que pasan.**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/pages/specialty_test/specialty_test_controller.dart test/bienvenida/bienvenida_test_especialidad_test.dart
"${FLUTTER:?}" test --no-pub test/bienvenida/bienvenida_test_especialidad_test.dart test/HU36_jeff
"${FLUTTER:?}" analyze --no-pub
```

Esperado. `All tests passed!`. Las pruebas del test de especialidad siguen en verde, porque el
asistente y el Perfil no cambian. `5 issues found.`, los de la base.

- [ ] **Paso 5. Commit.**

```bash
cd "${REPO:?}"
git status --short
git add lib/pages/specialty_test/specialty_test_controller.dart test/bienvenida/bienvenida_test_especialidad_test.dart
git commit -m "feat(specialty-test): el controlador acepta el origen bienvenida, sin precarga ni pausa y con el paso al horario al guardar (enmienda a RF-TEST-1, RF-TEST-2 y RF-TEST-9)"
git log -1 --format='%an <%ae>'
```

---

### Tarea 22. Las piezas del test se dibujan también en el compositor

**Requisitos.** La enmienda aprobada a RF-TEST-5 y RF-TEST-6 (el duelo y la escala también en el
compositor, con las tarjetas compactas de la decisión B-13), a RF-TEST-8 (el resultado en la
conversación y el confeti bajo la franja) y la decisión 10 del plan.

**Archivos.**
- Modificar `lib/pages/specialty_test/widgets/question_view.dart`.
- Modificar `lib/pages/specialty_test/widgets/result_view.dart`.
- Modificar `test/bienvenida/bienvenida_test_especialidad_test.dart` (grupo `las piezas compactas`).

**Interfaces.**
- Consume las vistas de las Tareas 12 y 14 del plan del test.
- Produce estas firmas públicas, en sus mismos archivos, que usan las Tareas 25 y 27.

```dart
// question_view.dart
const List<String> emojisDeLaEscala; // '😴', '🙂', '😃', '🤩'
bool textoGrande(BuildContext context);
enum EstadoDeTarjeta { neutra, encendida, apagada }
class DueloDelTest { const DueloDelTest({required List<TestTask> tareas,
  required SpecialtyTestContent contenido, required String? respuesta,
  required String? ayuda, required ValueChanged<String> onTap, bool compacto = false}); }
class TarjetaDeTarea { ..., bool compacto = false }
class LasDosONinguna { const LasDosONinguna({required SpecialtyTestContent contenido,
  required String? respuesta, required ValueChanged<String> onTap}); }
class EscalaDelTest { const EscalaDelTest({required TestQuestion pregunta,
  required List<TestOption> opciones, required String? respuesta,
  required FocusNode foco, required ValueChanged<String> onTap}); }
// result_view.dart
class TarjetaGanadora, FilaDeElectivos, EncabezadoDeLasDemas, FilaDelRanking, HojaDelEmpate;
class PintorDelConfeti extends CustomPainter { PintorDelConfeti(double t); }
```

- [ ] **Paso 1. Escribe la prueba que falla.** En
  `test/bienvenida/bienvenida_test_especialidad_test.dart`, suma estos imports y este grupo.

```dart
import 'package:flutter/material.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/question_view.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/task_icon.dart';
```

```dart
  group('las piezas compactas (B-13)', () {
    testWidgets('en el compositor, las tarjetas miden 56 dp como mínimo con la '
        'baldosa de 40 dp y el ícono de 22 dp', (tester) async {
      final contenido = SpecialtyTestContent.tryFromJson(contenidoJson())!;
      final duelo = contenido.questions.firstWhere((q) => q.isDuel);
      const tema = MaterialTheme(TextTheme());
      await tester.pumpWidget(
        MaterialApp(
          theme: tema.light(),
          home: Scaffold(
            body: DueloDelTest(
              tareas: [duelo.top!, duelo.bottom!],
              contenido: contenido,
              respuesta: null,
              ayuda: null,
              onTap: (_) {},
              compacto: true,
            ),
          ),
        ),
      );
      final tarjetas = find.byType(TarjetaDeTarea);
      expect(tarjetas, findsNWidgets(2));
      final alto = tester.getSize(tarjetas.first).height;
      expect(alto, greaterThanOrEqualTo(56));
      expect(alto, lessThan(104));
      final baldosa = tester.getSize(find.byType(TaskIconTile).first);
      expect(baldosa, const Size(40, 40));
    });

    test('los emojis de la escala son públicos y siguen el orden de las '
        'opciones (RF-TEST-6)', () {
      expect(emojisDeLaEscala, ['😴', '🙂', '😃', '🤩']);
    });
  });
```

- [ ] **Paso 2. Corre la prueba y confirma que falla.**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/bienvenida/bienvenida_test_especialidad_test.dart
```

Esperado. Falla la compilación, porque `DueloDelTest`, `TarjetaDeTarea` y `emojisDeLaEscala` son
privados.

- [ ] **Paso 3. Haz públicas las piezas.** En `question_view.dart` y `result_view.dart`, renombra
  las clases y las constantes privadas en todo el archivo, sin cambiar su cuerpo.

```bash
cd "${REPO:?}"
V=lib/pages/specialty_test/widgets
perl -pi \
  -e 's/\b_emojis\b/emojisDeLaEscala/g;' \
  -e 's/\b_textoGrande\b/textoGrande/g;' \
  -e 's/\b_EstadoTarjeta\b/EstadoDeTarjeta/g;' \
  -e 's/\b_Duelo\b/DueloDelTest/g;' \
  -e 's/\b_TarjetaDeTarea\b/TarjetaDeTarea/g;' \
  -e 's/\b_LasDosONinguna\b/LasDosONinguna/g;' \
  -e 's/\b_BotonAlterno\b/BotonAlterno/g;' \
  -e 's/\b_Escala\b/EscalaDelTest/g;' \
  -e 's/\b_FilaDeOpciones\b/FilaDeOpciones/g;' \
  -e 's/\b_OpcionDeEscala\b/OpcionDeEscala/g;' \
  "$V/question_view.dart"
perl -pi \
  -e 's/\b_TarjetaGanadora\b/TarjetaGanadora/g;' \
  -e 's/\b_ColoresDeLaTarjeta\b/ColoresDeLaTarjeta/g;' \
  -e 's/\b_Medidor\b/MedidorDeAfinidad/g;' \
  -e 's/\b_Motivo\b/MotivoDelResultado/g;' \
  -e 's/\b_FilaDeElectivos\b/FilaDeElectivos/g;' \
  -e 's/\b_EncabezadoDeLasDemas\b/EncabezadoDeLasDemas/g;' \
  -e 's/\b_FilaDelRanking\b/FilaDelRanking/g;' \
  -e 's/\b_HojaDelEmpate\b/HojaDelEmpate/g;' \
  -e 's/\b_Confeti\b/PintorDelConfeti/g;' \
  "$V/result_view.dart"
git diff --stat
```

  `perl` corre igual en macOS y en Linux, y `\b` evita tocar nombres más largos como
  `_DueloState`. Después, en
  `question_view.dart`, suma el parámetro `compacto` a `DueloDelTest` y a `TarjetaDeTarea`.

```dart
  /// En el compositor de la conversación, las tarjetas son las compactas de
  /// la maqueta (B-13).
  final bool compacto;
```

  En `DueloDelTest`, el constructor suma `this.compacto = false`, y la función `tarjeta(…)` pasa
  `compacto: compacto` a `TarjetaDeTarea`. En `TarjetaDeTarea`, el constructor suma
  `this.compacto = false`, y el alto mínimo y la baldosa dependen de él.

```dart
            constraints: BoxConstraints(minHeight: compacto ? 56 : 104),
```

```dart
                      TaskIconTile(
                        icono: tarea.icon,
                        color: encendida ? color : null,
                        apagada: apagada,
                        width: compacto ? 40 : 80,
                        height: compacto ? 40 : 80,
                        iconSize: compacto ? 22 : 40,
                      ),
```

  Los comentarios de documentación de las clases renombradas no cambian. Si la rama del test ya
  usa alguno de los nombres nuevos, se elige otro y se anota en el informe.

- [ ] **Paso 4. Corre las pruebas y confirma que pasan.**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/pages/specialty_test/widgets test/bienvenida/bienvenida_test_especialidad_test.dart
"${FLUTTER:?}" test --no-pub test/bienvenida/bienvenida_test_especialidad_test.dart test/HU36_jeff
"${FLUTTER:?}" analyze --no-pub
```

Esperado. `All tests passed!` y las pruebas del test de especialidad en verde, porque sus vistas
siguen con `compacto: false`. Los avisos, los de la base.

- [ ] **Paso 5. Commit.**

```bash
cd "${REPO:?}"
git status --short
git add lib/pages/specialty_test/widgets/question_view.dart lib/pages/specialty_test/widgets/result_view.dart test/bienvenida/bienvenida_test_especialidad_test.dart
git commit -m "feat(specialty-test): el duelo, la escala y el resultado se pueden dibujar en la conversación, con las tarjetas compactas (enmienda a RF-TEST-5, RF-TEST-6 y RF-TEST-8, B-13)"
git log -1 --format='%an <%ae>'
```

---

### Tarea 23. El controlador de la bienvenida, con las visitas y «Sí, entrar»

**Requisitos.** De RF-BIEN-1, «Los controladores», «Cada montaje es una visita» y «La navegación
queda en la bienvenida» (decisión B-19). De RF-BIEN-2, lo que pasa «Al responder». RF-BIEN-3 en
su parte de datos, RF-BIEN-5 en su parte de datos (los grupos, las respuestas, el historial en
memoria y los campos vacíos al salir), RF-BIEN-6 completo en su parte de datos (decisión B-6), con
el cierre del autocompletado de «El autocompletado» antes de vaciar los campos, la llegada con
sesión de RF-BIEN-21 y el atrás de RF-BIEN-13 en los turnos de «Sí, entrar».

**Archivos.**
- Crear `lib/pages/bienvenida/conversacion.dart`.
- Crear `lib/pages/bienvenida/bienvenida_controller.dart`.
- Crear `test/bienvenida/apoyo_bienvenida.dart`.
- Modificar `test/bienvenida/bienvenida_entrar_test.dart` (grupo `los turnos de «Sí, entrar»`).
- Modificar `test/bienvenida/bienvenida_ruta_test.dart` (grupo `las visitas`).
- Crear `test/bienvenida/bienvenida_sin_especialidad_test.dart` (grupo `la llegada con sesión`).

**Interfaces.**
- Consume `TurnoDeLaBienvenida`, `accionDelAtras` y `TextosDeLaBienvenida` (Tarea 16),
  `LoginController.entrar`, `entrarConGoogle`, `desenlaceDeGoogleEnWeb` y `vaciarCampos`
  (Tarea 19), `MotivoDeLlegada` (Tarea 15) y `postLoginRoute` de hoy.
- Produce estas firmas, que usan las Tareas 24 a 31.

```dart
// conversacion.dart
enum TipoDeBurbuja { texto, error, consentimiento, avisos, cargando, esperando }
abstract final class Ritmo { entreBurbujas 850 ms; antesDelCompositor 500 ms;
  trasLaRespuesta 650 ms; antesDelPaso 900 ms }
sealed class EntradaDeLaConversacion { int id; Duration pausa; }
class BurbujaDeUlises extends EntradaDeLaConversacion { String texto; TipoDeBurbuja tipo;
  String? titulo; List<String> lineas; SelloDeBloque? sello; }
class RespuestaDelAlumno extends EntradaDeLaConversacion { String texto; bool secreta;
  bool conGoogle; }
class ResultadoDelTest extends EntradaDeLaConversacion {}
// bienvenida_controller.dart
class BienvenidaController extends GetxController {
  BienvenidaController({AuthService? auth, LoginController? login,
    RegistroController Function()? crearRegistro,
    SpecialtyTestController Function(SpecialtyTestUi ui)? crearTest,
    Future<String?> Function()? tokenGuardado, void Function(String ruta)? abrirRuta,
    void Function()? terminarAutocompletado});
  final RxList<EntradaDeLaConversacion> entradas;
  final Rxn<TurnoDeLaBienvenida> turno;       // el compositor abierto, o null
  final Rxn<TurnoDeLaBienvenida> ultimoTurno;  // para el atrás
  final RxBool esperando; final RxnString errorLocal; final RxInt latidos;
  RegistroController? registro; SpecialtyTestController? test;
  bool get conSesion;
  int nuevaVisita(); Future<void> empezarVisita(int visita, {MotivoDeLlegada? motivo});
  void terminarVisita(int visita);
  void responderAlSaludo({required bool yaUsa}); void ulisesAterrizoConSesion();
  void enviarCodigo(); Future<void> entrar(); Future<void> entrarConGoogle();
  void soyNuevo(); void abrirOlvido(); void volverAE1();
  bool get atrasSaleDeLaApp; void atras(); void pasoHecho(); }
```

- [ ] **Paso 1. Escribe el apoyo de las pruebas.** Crea `test/bienvenida/apoyo_bienvenida.dart`.
  La Tarea 26 le suma el montaje de la página.

```dart
// test/bienvenida/apoyo_bienvenida.dart
//
// Apoyo de las pruebas de la bienvenida. No termina en _test.dart, así que
// `flutter test` no lo corre como suite. Todo dato es inventado.

import 'package:get/get.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/bienvenida/bienvenida_controller.dart';
import 'package:ulima_plus/pages/bienvenida/conversacion.dart';
import 'package:ulima_plus/pages/login/login_controller.dart';
import 'package:ulima_plus/services/auth_service.dart';

UserModel alumnaDePrueba({bool setupComplete = true, int? careerId = 1}) =>
    UserModel(
      code: '20230001',
      firstName: 'Alumna',
      lastName: 'De Prueba',
      email: 'test@aloe.ulima.edu.pe',
      role: 'student',
      careerId: careerId,
      currentCycle: '2026-2',
      setupComplete: setupComplete,
    );

UserModel docenteDePrueba() => UserModel(
  code: 'docente.test',
  firstName: 'Docente',
  lastName: 'De Prueba',
  email: 'docente.test@ulima.edu.pe',
  role: 'teacher',
  currentCycle: '2026-2',
  setupComplete: true,
);

/// Lo que `AuthService.login` no atrapa.
class RedCaida implements Exception {
  const RedCaida();
}

/// Un AuthService sin red. [alEntrar] es el usuario que queda al entrar.
class AuthDeLaBienvenida extends AuthService {
  AuthDeLaBienvenida({
    this.usuario,
    this.alEntrar,
    this.errorDeLogin,
    this.redCaida = false,
    this.google,
  });

  UserModel? usuario;
  UserModel? alEntrar;
  String? errorDeLogin;
  bool redCaida;

  /// Lo que devuelve Google, con 'cancelar' para el selector cerrado.
  String? google;
  int logouts = 0;

  @override
  UserModel? get currentUser => usuario;

  @override
  Future<String?> login({required String code, required String password}) async {
    if (redCaida) throw const RedCaida();
    if (errorDeLogin != null) return errorDeLogin;
    usuario = alEntrar ?? alumnaDePrueba();
    return null;
  }

  @override
  Future<String?> loginWithGoogle() async {
    if (google == 'cancelar') return null;
    if (google != null) return google;
    usuario = alEntrar ?? alumnaDePrueba();
    return null;
  }

  @override
  Future<void> logout() async {
    logouts++;
    usuario = null;
  }
}

/// El controlador de la bienvenida con sus dobles, fuera de GetX.
class Bienvenida {
  Bienvenida({AuthDeLaBienvenida? auth, this.token})
    : auth = auth ?? AuthDeLaBienvenida() {
    Get.testMode = true;
    Get.put<AuthService>(this.auth);
    login = LoginController();
    controlador = BienvenidaController(
      auth: this.auth,
      login: login,
      tokenGuardado: () async => token,
      abrirRuta: rutas.add,
      terminarAutocompletado: () => autocompletados.add((
        codigo: login.codeController.text,
        contrasena: login.passwordController.text,
      )),
    )..onStart();
  }

  final AuthDeLaBienvenida auth;
  String? token;
  final List<String> rutas = <String>[];

  /// Cada cierre del autocompletado, con lo que tenían los campos en ese
  /// momento (RF-BIEN-6).
  final List<({String codigo, String contrasena})> autocompletados =
      <({String codigo, String contrasena})>[];
  late final LoginController login;
  late final BienvenidaController controlador;

  List<String> get deUlises => <String>[
    for (final e in controlador.entradas)
      if (e is BurbujaDeUlises) e.texto,
  ];

  List<String> get delAlumno => <String>[
    for (final e in controlador.entradas)
      if (e is RespuestaDelAlumno) e.texto,
  ];

  /// Empieza una visita nueva, como el primer cuadro de la página.
  Future<void> visitar({MotivoDeLlegada? motivo}) async {
    final v = controlador.nuevaVisita();
    await controlador.empezarVisita(v, motivo: motivo);
  }
}
```

  Suma el import de `package:ulima_plus/services/session_navigation.dart` para
  `MotivoDeLlegada`.

- [ ] **Paso 2. Escribe las pruebas que fallan.** En `test/bienvenida/bienvenida_entrar_test.dart`,
  suma estos imports y este grupo.

```dart
import 'package:ulima_plus/domain/bienvenida/bienvenida_turnos.dart';
import 'package:ulima_plus/pages/bienvenida/conversacion.dart';

import 'apoyo_bienvenida.dart';
```

```dart
  group('los turnos de «Sí, entrar» (RF-BIEN-6)', () {
    tearDown(Get.reset);

    Future<Bienvenida> enE2({AuthDeLaBienvenida? auth}) async {
      final b = Bienvenida(auth: auth);
      await b.visitar();
      b.controlador.responderAlSaludo(yaUsa: true);
      b.login.codeController.text = '  20230001 ';
      b.controlador.enviarCodigo();
      b.login.passwordController.text = 'secreta-de-prueba';
      return b;
    }

    test('al responder, la conversación trae el primer grupo y la respuesta, '
        'y sigue E1', () async {
      final b = Bienvenida();
      await b.visitar();
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.recibimiento);
      b.controlador.responderAlSaludo(yaUsa: true);
      expect(b.deUlises, [
        TextosDeLaBienvenida.saludo,
        TextosDeLaBienvenida.pregunta,
        TextosDeLaBienvenida.e1,
      ]);
      expect(b.delAlumno, ['Sí, entrar']);
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.e1Codigo);
      expect(b.controlador.latidos.value, 1);
      // El primer turno de la rama espera 650 ms tras la respuesta.
      final e1 = b.controlador.entradas.last;
      expect(e1.pausa, Ritmo.trasLaRespuesta);
    });

    test('E1 manda el código recortado, tal como se escribió, y abre E2', () async {
      final b = await enE2();
      expect(b.delAlumno.last, '20230001');
      expect(b.deUlises.last, TextosDeLaBienvenida.e2);
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.e2Contrasena);
    });

    test('el usuario alfanumérico del docente también vale', () async {
      final b = Bienvenida(auth: AuthDeLaBienvenida(alEntrar: docenteDePrueba()));
      await b.visitar();
      b.controlador.responderAlSaludo(yaUsa: true);
      b.login.codeController.text = 'docente.test';
      b.controlador.enviarCodigo();
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.e2Contrasena);
    });

    test('con la sesión puesta entra un candado y la despedida, y pide el paso '
        'al horario', () async {
      final b = await enE2();
      await b.controlador.entrar();
      final respuesta =
          b.controlador.entradas.whereType<RespuestaDelAlumno>().last;
      expect(respuesta.texto, TextosDeLaBienvenida.contrasenaLista);
      expect(respuesta.secreta, isTrue);
      expect(b.deUlises.last, TextosDeLaBienvenida.e3);
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.pasoAlHorario);
      expect(b.rutas, isEmpty, reason: 'la bienvenida no navega a /setup-carrera');
    });

    test('con la sesión puesta cierra el autocompletado con el código y la '
        'contraseña todavía escritos, y un login rechazado no lo cierra '
        '(RF-BIEN-6)', () async {
      final rechazado = await enE2(
        auth: AuthDeLaBienvenida(errorDeLogin: 'Código o contraseña incorrectos.'),
      );
      await rechazado.controlador.entrar();
      expect(rechazado.autocompletados, isEmpty);
      Get.reset();
      final b = await enE2();
      await b.controlador.entrar();
      expect(b.autocompletados, [
        (codigo: '  20230001 ', contrasena: 'secreta-de-prueba'),
      ]);
      // Los campos se vacían después, al pasar al horario.
      b.controlador.pasoHecho();
      expect(b.login.codeController.text, '');
      expect(b.login.passwordController.text, '');
      expect(b.autocompletados, hasLength(1));
    });

    test('un docente también va al paso al horario', () async {
      final b = await enE2(auth: AuthDeLaBienvenida(alEntrar: docenteDePrueba()));
      await b.controlador.entrar();
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.pasoAlHorario);
    });

    test('con la configuración a medias, Ulises dice que falta la especialidad '
        'y sigue el test, sin navegar a /setup-carrera (B-10)', () async {
      final b = await enE2(
        auth: AuthDeLaBienvenida(alEntrar: alumnaDePrueba(setupComplete: false)),
      );
      await b.controlador.entrar();
      expect(b.deUlises.last, TextosDeLaBienvenida.holaFaltaEspecialidad);
      expect(b.controlador.turno.value, isNot(TurnoDeLaBienvenida.pasoAlHorario));
      expect(b.controlador.conSesion, isTrue);
      expect(b.rutas, isEmpty);
    });

    test('un login rechazado dice el mensaje y vuelve a E1 con el código y la '
        'contraseña vacía (B-6)', () async {
      final b = await enE2(
        auth: AuthDeLaBienvenida(errorDeLogin: 'Código o contraseña incorrectos.'),
      );
      await b.controlador.entrar();
      final error = b.controlador.entradas.last as BurbujaDeUlises;
      expect(error.texto, 'Código o contraseña incorrectos.');
      expect(error.tipo, TipoDeBurbuja.error);
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.e1Codigo);
      expect(b.login.codeController.text, '  20230001 ');
      expect(b.login.passwordController.text, '');
    });

    test('sin conexión dice el texto de hoy y E2 sigue abierto con la '
        'contraseña escrita', () async {
      final b = await enE2(auth: AuthDeLaBienvenida(redCaida: true));
      await b.controlador.entrar();
      expect(b.deUlises.last, TextosDeLaBienvenida.sinConexion);
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.e2Contrasena);
      expect(b.login.passwordController.text, 'secreta-de-prueba');
      expect(b.controlador.esperando.value, isFalse);
    });

    test('Google cancelado no hace nada, un error es una burbuja y E1 sigue',
        () async {
      final b = Bienvenida(auth: AuthDeLaBienvenida(google: 'cancelar'));
      await b.visitar();
      b.controlador.responderAlSaludo(yaUsa: true);
      final antes = b.controlador.entradas.length;
      await b.controlador.entrarConGoogle();
      expect(b.controlador.entradas.length, antes);
      b.auth.google = 'Tu correo no está registrado en el sistema.';
      await b.controlador.entrarConGoogle();
      expect(b.deUlises.last, 'Tu correo no está registrado en el sistema.');
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.e1Codigo);
    });

    test('Google con la sesión puesta responde con su logo y sigue igual que '
        'con el código', () async {
      final b = Bienvenida();
      await b.visitar();
      b.controlador.responderAlSaludo(yaUsa: true);
      await b.controlador.entrarConGoogle();
      final respuesta =
          b.controlador.entradas.whereType<RespuestaDelAlumno>().last;
      expect(respuesta.texto, TextosDeLaBienvenida.continuarConGoogle);
      expect(respuesta.conGoogle, isTrue);
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.pasoAlHorario);
    });

    test('Google en web llega por el resultado observable mientras E1 está '
        'abierto', () async {
      final b = Bienvenida();
      await b.visitar();
      b.controlador.responderAlSaludo(yaUsa: true);
      b.auth.usuario = alumnaDePrueba();
      b.login.desenlaceDeGoogleEnWeb.value = const DesenlaceDelLogin.sesionPuesta();
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.pasoAlHorario);
      expect(b.login.desenlaceDeGoogleEnWeb.value, isNull);
    });

    test('«Soy nuevo» en E1 y en E2 vacía el login y empieza el registro', () async {
      final b = await enE2();
      b.controlador.soyNuevo();
      expect(b.delAlumno.last, TextosDeLaBienvenida.soyNuevo);
      expect(b.login.codeController.text, '');
      expect(b.login.passwordController.text, '');
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.n1Codigo);
      expect(b.deUlises.sublist(b.deUlises.length - 2), [
        TextosDeLaBienvenida.n1a,
        TextosDeLaBienvenida.n1b,
      ]);
    });

    test('«¿Olvidaste tu contraseña?» abre /forgot-password encima', () async {
      final b = await enE2();
      b.controlador.abrirOlvido();
      expect(b.rutas, ['/forgot-password']);
    });

    test('el atrás en E2 vuelve a E1 con el código, y en E1 sale de la app',
        () async {
      final b = await enE2();
      expect(b.controlador.atrasSaleDeLaApp, isFalse);
      b.controlador.atras();
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.e1Codigo);
      expect(b.login.codeController.text, '  20230001 ');
      expect(b.controlador.atrasSaleDeLaApp, isTrue);
    });
  });
```

  En `test/bienvenida/bienvenida_ruta_test.dart`, suma el import de `apoyo_bienvenida.dart` y de
  `bienvenida_turnos.dart` y este grupo.

```dart
  // Cerrar el registro programa un cuadro, así que el binding va primero.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('las visitas (RF-BIEN-1 y B-19)', () {
    test('cada visita reinicia la conversación, cierra los tramos y vacía el '
        'login', () async {
      final b = Bienvenida();
      await b.visitar();
      b.controlador.responderAlSaludo(yaUsa: false);
      expect(b.controlador.registro, isNotNull);
      b.login.codeController.text = '20230001';
      await b.visitar();
      expect(b.controlador.entradas, isEmpty);
      expect(b.controlador.registro, isNull);
      expect(b.login.codeController.text, '');
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.recibimiento);
    });

    test('una visita vieja no toca la nueva', () async {
      final b = Bienvenida();
      final vieja = b.controlador.nuevaVisita();
      final nueva = b.controlador.nuevaVisita();
      await b.controlador.empezarVisita(nueva);
      b.controlador.responderAlSaludo(yaUsa: false);
      await b.controlador.empezarVisita(vieja);
      b.controlador.terminarVisita(vieja);
      expect(b.controlador.registro, isNotNull);
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.n1Codigo);
      b.controlador.terminarVisita(nueva);
      expect(b.controlador.registro, isNull);
    });

    test('con un motivo arranca directo en E1, con el primer grupo y sin la '
        'pregunta (B-8)', () async {
      for (final motivo in MotivoDeLlegada.values) {
        final b = Bienvenida();
        await b.visitar(motivo: motivo);
        expect(b.deUlises, [TextosDeLaBienvenida.saludo, TextosDeLaBienvenida.e1]);
        expect(b.controlador.turno.value, TurnoDeLaBienvenida.e1Codigo);
        Get.reset();
      }
    });

    test('al pasar al horario se borra el historial y se vacía el login', () async {
      final b = Bienvenida();
      await b.visitar();
      b.controlador.responderAlSaludo(yaUsa: true);
      b.login.codeController.text = '20230001';
      b.controlador.pasoHecho();
      expect(b.controlador.entradas, isEmpty);
      expect(b.login.codeController.text, '');
    });
  });
```

  Crea `test/bienvenida/bienvenida_sin_especialidad_test.dart`. Las Tareas 25 y 28 le suman sus
  grupos.

```dart
// test/bienvenida/bienvenida_sin_especialidad_test.dart
//
// UNITARIA + WIDGET · Bienvenida con Ulises
// (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-21 y B-10. Un alumno con sesión y la configuración a medias llega
// a la bienvenida y sigue en la conversación hasta el test, sin la pregunta
// ni los dos botones. Sin sesión, o con un motivo, la llegada es la de
// siempre aunque currentUser quede en memoria. Las Tareas 25 y 28 suman el
// test y el recibimiento.
// Archivo probado lib/pages/bienvenida/bienvenida_controller.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/domain/bienvenida/bienvenida_turnos.dart';
import 'package:ulima_plus/services/session_navigation.dart';

import 'apoyo_bienvenida.dart';

void main() {
  tearDown(Get.reset);

  group('la llegada con sesión (RF-BIEN-21)', () {
    test('con el token y un alumno sin especialidad, la visita es la llegada '
        'con sesión', () async {
      final b = Bienvenida(
        auth: AuthDeLaBienvenida(usuario: alumnaDePrueba(setupComplete: false)),
        token: 'jwt-de-prueba',
      );
      await b.visitar();
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.llegadaConSesion);
      expect(b.controlador.conSesion, isTrue);
      expect(b.controlador.atrasSaleDeLaApp, isTrue);
    });

    test('al terminar el rebote de Ulises entra el primer grupo, sin '
        'respuesta del alumno', () async {
      final b = Bienvenida(
        auth: AuthDeLaBienvenida(usuario: alumnaDePrueba(setupComplete: false)),
        token: 'jwt-de-prueba',
      );
      await b.visitar();
      b.controlador.ulisesAterrizoConSesion();
      expect(b.deUlises.take(2), [
        TextosDeLaBienvenida.saludoConSesion,
        TextosDeLaBienvenida.faltaEspecialidad,
      ]);
      expect(b.delAlumno, isEmpty);
    });

    test('sin token, o con un motivo, la llegada es la de siempre aunque '
        'currentUser quede en memoria', () async {
      final sinToken = Bienvenida(
        auth: AuthDeLaBienvenida(usuario: alumnaDePrueba(setupComplete: false)),
      );
      await sinToken.visitar();
      expect(sinToken.controlador.turno.value, TurnoDeLaBienvenida.recibimiento);
      Get.reset();
      final conMotivo = Bienvenida(
        auth: AuthDeLaBienvenida(usuario: alumnaDePrueba(setupComplete: false)),
        token: 'jwt-de-prueba',
      );
      await conMotivo.visitar(motivo: MotivoDeLlegada.expirada);
      expect(conMotivo.controlador.turno.value, TurnoDeLaBienvenida.e1Codigo);
    });
  });
}
```

- [ ] **Paso 3. Corre las pruebas y confirma que fallan.**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/bienvenida
```

Esperado. Falla la compilación, porque `conversacion.dart` y `bienvenida_controller.dart` no
existen.

- [ ] **Paso 4. Escribe la conversación.** Crea `lib/pages/bienvenida/conversacion.dart`.

```dart
// lib/pages/bienvenida/conversacion.dart
// Lo que se ve en la conversación con Ulises (RF-BIEN-5). El controlador
// arma las entradas con la pausa que espera cada una antes de entrar, y la
// página las revela con ese ritmo, o todas juntas con lector de pantalla
// (decisión 6 del plan). Nada de esto se guarda en disco.

import '../specialty_test/specialty_test_logic.dart' show SelloDeBloque;

enum TipoDeBurbuja { texto, error, consentimiento, avisos, cargando, esperando }

/// Las pausas del ritmo (RF-BIEN-2, RF-BIEN-5 y RF-BIEN-6).
abstract final class Ritmo {
  static const Duration entreBurbujas = Duration(milliseconds: 850);
  static const Duration antesDelCompositor = Duration(milliseconds: 500);
  static const Duration trasLaRespuesta = Duration(milliseconds: 650);
  static const Duration antesDelPaso = Duration(milliseconds: 900);
}

sealed class EntradaDeLaConversacion {
  const EntradaDeLaConversacion({required this.id, required this.pausa});

  /// Una clave estable, así que una burbuja nueva no reconstruye las
  /// anteriores (RF-BIEN-18).
  final int id;

  /// Cuánto espera antes de entrar, contado desde la entrada anterior.
  final Duration pausa;
}

class BurbujaDeUlises extends EntradaDeLaConversacion {
  const BurbujaDeUlises({
    required super.id,
    required this.texto,
    super.pausa = Duration.zero,
    this.tipo = TipoDeBurbuja.texto,
    this.titulo,
    this.lineas = const <String>[],
    this.sello,
  });

  final String texto;
  final TipoDeBurbuja tipo;

  /// Un título en negrita sobre el texto, como la tarea de una escala o
  /// «Algunas cosas que notamos».
  final String? titulo;

  /// Líneas precedidas de «· », como los avisos del registro.
  final List<String> lineas;

  /// El sello «Cierra el bloque k de B» junto a la burbuja (RF-TEST-4).
  final SelloDeBloque? sello;
}

/// Una respuesta del alumno. Un dato secreto se muestra como un candado y un
/// rótulo, nunca con su valor (RF-BIEN-9).
class RespuestaDelAlumno extends EntradaDeLaConversacion {
  const RespuestaDelAlumno({
    required super.id,
    required this.texto,
    this.secreta = false,
    this.conGoogle = false,
  }) : super(pausa: Duration.zero);

  final String texto;
  final bool secreta;
  final bool conGoogle;
}

/// El resultado del test, con sus tarjetas a lo ancho de la columna
/// (RF-BIEN-10).
class ResultadoDelTest extends EntradaDeLaConversacion {
  const ResultadoDelTest({required super.id, super.pausa = Duration.zero});
}
```

- [ ] **Paso 5. Escribe el controlador.** Crea `lib/pages/bienvenida/bienvenida_controller.dart`.
  Las Tareas 24 y 25 le suman el registro y el test.

```dart
// lib/pages/bienvenida/bienvenida_controller.dart
// La conversación de la bienvenida con Ulises (RF-BIEN-1 a RF-BIEN-13 y
// RF-BIEN-21 de specs/features/bienvenida/bienvenida.spec.md). Es permanente,
// como LoginController, con una visita por cada montaje de su página (B-19).
// Decide qué dice Ulises, qué pide el compositor y cuánto espera cada
// burbuja, y deja el dibujo y el ritmo a la página. Crea y cierra ella misma
// los controladores del registro y del test, sin Get.put (B-20 y B-34).

import 'dart:async';

import 'package:flutter/services.dart' show TextInput;
import 'package:get/get.dart';

import '../../domain/bienvenida/bienvenida_turnos.dart';
import '../../services/auth_service.dart';
import '../../services/post_login_route.dart';
import '../../services/session_navigation.dart';
import '../../services/storage_service.dart';
import '../login/login_controller.dart';
import '../registro/registro_controller.dart';
import '../specialty_test/specialty_test_controller.dart';
import 'conversacion.dart';

typedef TextosB = TextosDeLaBienvenida;
typedef TurnoB = TurnoDeLaBienvenida;

class BienvenidaController extends GetxController {
  BienvenidaController({
    AuthService? auth,
    LoginController? login,
    RegistroController Function()? crearRegistro,
    SpecialtyTestController Function(SpecialtyTestUi ui)? crearTest,
    Future<String?> Function()? tokenGuardado,
    void Function(String ruta)? abrirRuta,
    void Function()? terminarAutocompletado,
  }) : _authInyectado = auth,
       _loginInyectado = login,
       _crearRegistro = crearRegistro ?? RegistroController.new,
       _crearTest =
           crearTest ??
           ((ui) => SpecialtyTestController(
             origen: OrigenDelTest.bienvenida,
             ui: ui,
           )),
       _tokenGuardado =
           tokenGuardado ?? (() => StorageService.to.savedToken),
       _abrirRuta = abrirRuta ?? ((ruta) => Get.toNamed<void>(ruta)),
       _terminarAutocompletado =
           terminarAutocompletado ?? (() => TextInput.finishAutofillContext());

  final AuthService? _authInyectado;
  final LoginController? _loginInyectado;
  final RegistroController Function() _crearRegistro;
  final SpecialtyTestController Function(SpecialtyTestUi ui) _crearTest;
  final Future<String?> Function() _tokenGuardado;
  final void Function(String ruta) _abrirRuta;

  /// Cierra el contexto del autocompletado para que el sistema ofrezca
  /// guardar el código y la contraseña (RF-BIEN-6). Las pruebas lo cambian
  /// por un registro, porque en la VM no hay plataforma que lo reciba.
  final void Function() _terminarAutocompletado;

  AuthService get _auth => _authInyectado ?? AuthService.to;
  LoginController get _login => _loginInyectado ?? Get.find<LoginController>();

  /// El historial vive solo aquí, en memoria (RF-BIEN-5).
  final entradas = <EntradaDeLaConversacion>[].obs;

  /// El turno del compositor abierto, o null con el compositor cerrado.
  final turno = Rxn<TurnoDeLaBienvenida>();

  /// El último turno abierto, que decide el atrás del sistema.
  final ultimoTurno = Rxn<TurnoDeLaBienvenida>();
  final esperando = false.obs;
  final errorLocal = RxnString();

  /// Sube con cada respuesta del alumno, y el sello late (RF-BIEN-4).
  final latidos = 0.obs;

  RegistroController? registro;
  SpecialtyTestController? test;

  int _visita = 0;
  int _siguienteId = 0;
  bool _conSesion = false;
  Worker? _googleEnWeb;

  /// La visita trae una sesión puesta o la puso «Sí, entrar» (RF-BIEN-21).
  bool get conSesion => _conSesion;

  @override
  void onInit() {
    super.onInit();
    _googleEnWeb = ever<DesenlaceDelLogin?>(_login.desenlaceDeGoogleEnWeb, (d) {
      if (d == null || turno.value != TurnoB.e1Codigo) return;
      _login.desenlaceDeGoogleEnWeb.value = null;
      _trasGoogle(d);
    });
  }

  @override
  void onClose() {
    _googleEnWeb?.dispose();
    _cerrarLosTramos();
    super.onClose();
  }

  // ── Ayudas ───────────────────────────────────────────────────────────────

  int _id() => _siguienteId++;

  /// Ulises dice [lineas]. La primera espera [primera] y las siguientes
  /// 850 ms (RF-BIEN-5).
  void _decir(
    List<String> lineas, {
    Duration primera = Ritmo.trasLaRespuesta,
    TipoDeBurbuja tipo = TipoDeBurbuja.texto,
  }) {
    for (var i = 0; i < lineas.length; i++) {
      entradas.add(
        BurbujaDeUlises(
          id: _id(),
          texto: lineas[i],
          tipo: tipo,
          pausa: i == 0 ? primera : Ritmo.entreBurbujas,
        ),
      );
    }
  }

  /// Un error del backend o de la red, que entra enseguida (RF-BIEN-12).
  void _decirError(String mensaje) =>
      _decir(<String>[mensaje], primera: Duration.zero, tipo: TipoDeBurbuja.error);

  /// El compositor se cierra, entra la respuesta y el sello late.
  void _responder(String texto, {bool secreta = false, bool conGoogle = false}) {
    turno.value = null;
    errorLocal.value = null;
    entradas.add(
      RespuestaDelAlumno(
        id: _id(),
        texto: texto,
        secreta: secreta,
        conGoogle: conGoogle,
      ),
    );
    latidos.value++;
  }

  void _abrir(TurnoDeLaBienvenida t) {
    turno.value = t;
    ultimoTurno.value = t;
  }

  // ── Visitas (RF-BIEN-1) ──────────────────────────────────────────────────

  /// El State de la página crea una visita al montarse.
  int nuevaVisita() => ++_visita;

  /// Después del primer cuadro de la página. Borra la conversación, cierra
  /// los tramos, vacía el login y mira si hay una sesión puesta.
  Future<void> empezarVisita(int visita, {MotivoDeLlegada? motivo}) async {
    if (visita != _visita) return;
    _reiniciar();
    final token = await _tokenGuardado();
    if (visita != _visita) return;
    final usuario = _auth.currentUser;
    final hayToken = token != null && token.isNotEmpty;
    if (motivo == null && hayToken && usuario != null) {
      // La llegada con sesión sigue lo que diga postLoginRoute (RF-BIEN-21).
      _conSesion = true;
      if (postLoginRoute(usuario) == '/home') {
        _decir(<String>[TextosB.e3], primera: Duration.zero);
        _abrir(TurnoB.pasoAlHorario);
        return;
      }
      _abrir(TurnoB.llegadaConSesion);
      return;
    }
    if (motivo != null) {
      // Directo a «Sí, entrar», con el sello ya en su lugar (RF-BIEN-3).
      _decir(<String>[TextosB.saludo], primera: Duration.zero);
      _abrirE1(primera: Ritmo.entreBurbujas);
      return;
    }
    _abrir(TurnoB.recibimiento);
  }

  /// El dispose de la página. Una visita vieja no toca la nueva.
  void terminarVisita(int visita) {
    if (visita != _visita) return;
    _cerrarLosTramos();
  }

  void _reiniciar() {
    _cerrarLosTramos();
    entradas.clear();
    turno.value = null;
    ultimoTurno.value = null;
    esperando.value = false;
    errorLocal.value = null;
    _conSesion = false;
    _login.vaciarCampos();
  }

  void _cerrarLosTramos() {
    _cerrarRegistro();
    _cerrarTest();
  }

  void _cerrarRegistro() {
    registro?.cerrar();
    registro = null;
  }

  void _cerrarTest() {
    test?.onDelete();
    test = null;
  }

  // ── Recibimiento (RF-BIEN-2 y RF-BIEN-21) ────────────────────────────────

  /// «Sí, entrar» o «Soy nuevo». La conversación ya trae el primer grupo.
  void responderAlSaludo({required bool yaUsa}) {
    if (turno.value != TurnoB.recibimiento) return;
    entradas.add(BurbujaDeUlises(id: _id(), texto: TextosB.saludo));
    entradas.add(BurbujaDeUlises(id: _id(), texto: TextosB.pregunta));
    _responder(yaUsa ? TextosB.siEntrar : TextosB.soyNuevo);
    if (yaUsa) {
      _abrirE1();
    } else {
      _abrirN1();
    }
  }

  /// En la llegada con sesión, el fin del rebote de Ulises hace de respuesta,
  /// sin respuesta del alumno.
  void ulisesAterrizoConSesion() {
    if (turno.value != TurnoB.llegadaConSesion) return;
    turno.value = null;
    entradas.add(BurbujaDeUlises(id: _id(), texto: TextosB.saludoConSesion));
    entradas.add(BurbujaDeUlises(id: _id(), texto: TextosB.faltaEspecialidad));
    _empezarElTest();
  }

  // ── «Sí, entrar» (RF-BIEN-6) ─────────────────────────────────────────────

  void _abrirE1({Duration primera = Ritmo.trasLaRespuesta}) {
    _decir(<String>[TextosB.e1], primera: primera);
    _abrir(TurnoB.e1Codigo);
  }

  void enviarCodigo() {
    if (turno.value != TurnoB.e1Codigo) return;
    final codigo = _login.codeController.text.trim();
    if (codigo.isEmpty) return;
    _responder(codigo);
    _decir(<String>[TextosB.e2]);
    _abrir(TurnoB.e2Contrasena);
  }

  Future<void> entrar() async {
    if (turno.value != TurnoB.e2Contrasena || esperando.value) return;
    if (_login.passwordController.text.isEmpty) return;
    esperando.value = true;
    final d = await _login.entrar();
    esperando.value = false;
    switch (d.tipo) {
      case TipoDeDesenlace.sesionPuesta:
        // Con los dos campos todavía escritos y montados, el sistema empareja
        // el usuario con la contraseña y ofrece guardarlos. Los campos se
        // vacían después, al pasar al horario o al reiniciar (RF-BIEN-6).
        _terminarAutocompletado();
        _responder(TextosB.contrasenaLista, secreta: true);
        _trasEntrar();
      case TipoDeDesenlace.error:
        // Vuelve a E1 con el código escrito y la contraseña vacía (B-6).
        _login.passwordController.clear();
        _decirError(d.mensaje ?? TextosB.sinConexion);
        _abrir(TurnoB.e1Codigo);
      case TipoDeDesenlace.sinConexion:
        _decirError(TextosB.sinConexion);
        _abrir(TurnoB.e2Contrasena);
      case TipoDeDesenlace.cancelado:
        break;
    }
  }

  Future<void> entrarConGoogle() async {
    if (turno.value != TurnoB.e1Codigo || esperando.value) return;
    esperando.value = true;
    final d = await _login.entrarConGoogle();
    esperando.value = false;
    _trasGoogle(d);
  }

  void _trasGoogle(DesenlaceDelLogin d) {
    switch (d.tipo) {
      case TipoDeDesenlace.sesionPuesta:
        _responder(TextosB.continuarConGoogle, conGoogle: true);
        _trasEntrar();
      case TipoDeDesenlace.error:
        _decirError(d.mensaje ?? TextosB.sinConexion);
      case TipoDeDesenlace.sinConexion:
        _decirError(TextosB.sinConexion);
      case TipoDeDesenlace.cancelado:
        break;
    }
  }

  /// Con la sesión puesta, un docente o un alumno completo van al horario y
  /// un alumno a medias sigue con el test, sin navegar a /setup-carrera
  /// (RF-BIEN-6 y B-10).
  void _trasEntrar() {
    final usuario = _auth.currentUser;
    if (usuario == null) return;
    _conSesion = true;
    if (postLoginRoute(usuario) == '/home') {
      _decir(<String>[TextosB.e3]);
      _abrir(TurnoB.pasoAlHorario);
      return;
    }
    _decir(<String>[TextosB.holaFaltaEspecialidad]);
    _empezarElTest();
  }

  /// «Soy nuevo» en E1 o en E2. Lo escrito no pasa de una rama a la otra.
  void soyNuevo() {
    final t = turno.value;
    if (t != TurnoB.e1Codigo && t != TurnoB.e2Contrasena) return;
    _responder(TextosB.soyNuevo);
    _login.vaciarCampos();
    _abrirN1();
  }

  /// Abre /forgot-password encima, con el sello en su cabecera (B-9).
  void abrirOlvido() => _abrirRuta('/forgot-password');

  void volverAE1() {
    if (turno.value != TurnoB.e2Contrasena) return;
    _abrir(TurnoB.e1Codigo);
  }

  // ── Registro (Tarea 24) ──────────────────────────────────────────────────

  void _abrirN1({Duration primera = Ritmo.trasLaRespuesta}) {
    registro ??= _crearRegistro();
    _decir(<String>[TextosB.n1a, TextosB.n1b], primera: primera);
    _abrir(TurnoB.n1Codigo);
  }

  // ── Test (Tarea 25) ──────────────────────────────────────────────────────

  void _empezarElTest() {
    _abrir(TurnoB.t0Invitacion);
  }

  // ── Atrás (RF-BIEN-13) ───────────────────────────────────────────────────

  AccionDelAtras get _accionDelAtras =>
      accionDelAtras(ultimoTurno.value ?? TurnoB.recibimiento);

  bool get atrasSaleDeLaApp =>
      _accionDelAtras == AccionDelAtras.salirDeLaApp;

  void atras() {
    switch (_accionDelAtras) {
      case AccionDelAtras.volverAE1:
        volverAE1();
      case AccionDelAtras.yaTengoCuenta:
      case AccionDelAtras.volver:
      case AccionDelAtras.avisarQueSeEnvia:
      case AccionDelAtras.volverAIntentar:
      case AccionDelAtras.preguntaAnterior:
      case AccionDelAtras.irAT0:
      case AccionDelAtras.salirDeLaApp:
      case AccionDelAtras.nada:
        break;
    }
  }

  // ── Paso al horario (RF-BIEN-11) ─────────────────────────────────────────

  /// La página entregó el paso a la capa y navegó a /home. Se cierran los
  /// tramos, se borra el historial y se vacían los campos.
  void pasoHecho() => _reiniciar();
}
```

  Los dos `typedef` de arriba solo acortan los nombres de los textos y de los turnos.

- [ ] **Paso 6. Corre las pruebas y confirma que pasan.**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/pages/bienvenida test/bienvenida
"${FLUTTER:?}" test --no-pub test/bienvenida
"${FLUTTER:?}" analyze --no-pub
```

Esperado. `All tests passed!` y los avisos de la base.

- [ ] **Paso 7. Commit.**

```bash
cd "${REPO:?}"
git status --short
git add lib/pages/bienvenida/conversacion.dart lib/pages/bienvenida/bienvenida_controller.dart test/bienvenida
git commit -m "feat(bienvenida): el controlador de la bienvenida conduce las visitas, el recibimiento, «Sí, entrar» con código o Google y la llegada con sesión (RF-BIEN-1, RF-BIEN-6 y RF-BIEN-21)"
git log -1 --format='%an <%ae>'
```

---

### Tarea 24. El registro en la conversación

**Requisitos.** RF-BIEN-7 y RF-BIEN-8 en su parte de datos (decisiones B-5, B-17, B-30, B-31 y
B-32), RF-BIEN-9 en su parte de datos (decisión B-20) y el atrás de RF-BIEN-13 en los turnos del
registro, con el aviso «Estamos creando tu cuenta» abajo (B-29).

**Archivos.**
- Modificar `lib/pages/bienvenida/bienvenida_controller.dart`.
- Modificar `test/bienvenida/apoyo_bienvenida.dart` (`RegistroFalso` y el registro inyectable).
- Crear `test/bienvenida/bienvenida_registro_test.dart`.
- Modificar `test/bienvenida/bienvenida_credenciales_test.dart` (grupo `las credenciales en la
  conversación`).
- Crear `test/bienvenida/bienvenida_atras_test.dart` (grupo `el atrás en el registro`).

**Interfaces.**
- Consume `RegistroController` con `cerrar` (Tarea 19), sus validadores de hoy y
  `validateNewPassword` y `validatePasswordConfirmation` de `password_reset_validators.dart`,
  `textoDeCuentaLista` (Tarea 16) y el controlador de la Tarea 23.
- Produce, en `BienvenidaController`, estas firmas, que usan las Tareas 25 a 27.

```dart
enum EstadoDeLaPildora { creando, creada }
final Rxn<EstadoDeLaPildora> pildora; final RxBool enviando;
BienvenidaController({..., void Function(String titulo, String texto)? avisar});
void enviarCodigoDeAlumno(); void enviarContrasenas(); void aceptarConsentimiento();
void enviarPortal(); Future<void> crearCuenta(); void volver(); void yaTengoCuenta();
Future<void> iniciarSesionDesdeIncierto(); void volverAIntentarElRegistro();
```

- [ ] **Paso 1. Suma el registro al apoyo.** En `test/bienvenida/apoyo_bienvenida.dart`, suma estos
  imports, esta clase y los dos parámetros de `Bienvenida`.

```dart
import 'dart:async';

import 'package:ulima_plus/models/portal_sync_models.dart';
import 'package:ulima_plus/models/registro_models.dart';
import 'package:ulima_plus/pages/registro/registro_controller.dart';
import 'package:ulima_plus/services/registro_service.dart';
```

```dart
/// Un RegistroService sin red. Responde con [resultado], lanza [fallo] o
/// espera a [pendiente], y cuenta las llamadas.
class RegistroFalso implements RegistroService {
  RegistroFalso({this.resultado, this.fallo, this.pendiente});

  RegistroResult? resultado;
  RegistroFailure? fallo;
  Completer<RegistroResult>? pendiente;
  int llamadas = 0;

  @override
  Future<RegistroResult> registrar({
    required String code,
    required String portalPassword,
    required String passcode,
    required String password,
    required bool consent,
  }) async {
    llamadas++;
    if (pendiente != null) return pendiente!.future;
    if (fallo != null) throw fallo!;
    return resultado!;
  }
}

RegistroResult resultadoDelRegistro({
  int cursos = 5,
  List<String> avisos = const <String>[],
}) => RegistroResult(
  token: 'jwt-de-prueba',
  user: alumnaDePrueba(setupComplete: false),
  summary: PortalSyncSummary(
    coursesCreated: 0,
    sectionsCreated: 0,
    sectionsUpdated: 0,
    sessionsUpserted: 12,
    enrollmentsUpserted: cursos,
    enrollmentsWithdrawn: 0,
    progressUpserted: 40,
    syllabiUpserted: 0,
  ),
  warnings: <PortalSyncWarning>[
    for (final a in avisos)
      PortalSyncWarning.fromJson(<String, dynamic>{'code': 'AVISO', 'message': a}),
  ],
);
```

  `Bienvenida` suma los parámetros `RegistroFalso? registro` y `bool adoptarFalla = false`, los
  campos `final RegistroFalso servicioDeRegistro` y `final List<String> avisos`, y pasa al
  controlador estos dos argumentos.

```dart
      crearRegistro: () => RegistroController(
        service: servicioDeRegistro,
        adoptarSesion: ({required token, required user}) async {
          if (adoptarFalla) throw StateError('sin catálogos');
          this.auth.usuario = user;
        },
        iniciarSesion: ({required code, required password}) =>
            this.auth.login(code: code, password: password),
      ),
      avisar: (titulo, texto) => avisos.add(titulo),
```

  Con `servicioDeRegistro = registro ?? RegistroFalso(resultado: resultadoDelRegistro())` en la
  lista de inicialización.

- [ ] **Paso 2. Escribe las pruebas que fallan.** Crea `test/bienvenida/bienvenida_registro_test.dart`.
  La Tarea 27 le suma el compositor.

```dart
// test/bienvenida/bienvenida_registro_test.dart
//
// UNITARIA + WIDGET · Bienvenida con Ulises
// (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-7 y RF-BIEN-8. El registro de hoy repartido en turnos, con sus
// validadores sin red, el consentimiento que no se repite, el envío con su
// advertencia de hoy, cada desenlace y el paso al test. La Tarea 27 suma el
// compositor de cada turno.
// Archivo probado lib/pages/bienvenida/bienvenida_controller.dart.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/domain/bienvenida/bienvenida_turnos.dart';
import 'package:ulima_plus/models/registro_models.dart';
import 'package:ulima_plus/pages/bienvenida/bienvenida_controller.dart';
import 'package:ulima_plus/pages/bienvenida/conversacion.dart';

import 'apoyo_bienvenida.dart';

typedef _T = TurnoDeLaBienvenida;

/// Llega hasta N5 con datos válidos inventados.
Future<Bienvenida> _enN5({RegistroFalso? registro, bool adoptarFalla = false}) async {
  final b = Bienvenida(registro: registro, adoptarFalla: adoptarFalla);
  await b.visitar();
  final c = b.controlador..responderAlSaludo(yaUsa: false);
  c.registro!.codigoCtrl.text = '20230001';
  c.enviarCodigoDeAlumno();
  c.registro!
    ..passwordCtrl.text = 'Contrasena1'
    ..confirmacionCtrl.text = 'Contrasena1';
  c.enviarContrasenas();
  c.aceptarConsentimiento();
  c.registro!.portalPasswordCtrl.text = 'clave-de-prueba';
  c.enviarPortal();
  c.registro!.passcodeCtrl.text = '123456';
  return b;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Get.reset);

  group('los datos de la cuenta (RF-BIEN-7)', () {
    test('N1 valida el código en local y sigue N2', () async {
      final b = Bienvenida();
      await b.visitar();
      final c = b.controlador..responderAlSaludo(yaUsa: false);
      c.registro!.codigoCtrl.text = '12ab';
      c.enviarCodigoDeAlumno();
      expect(
        c.errorLocal.value,
        'El código son entre 6 y 10 dígitos, sin espacios ni letras.',
      );
      expect(c.turno.value, _T.n1Codigo);
      c.registro!.codigoCtrl.text = ' 20230001 ';
      c.enviarCodigoDeAlumno();
      expect(b.delAlumno.last, '20230001');
      expect(b.deUlises.last, TextosDeLaBienvenida.n2);
      expect(c.turno.value, _T.n2Contrasena);
      expect(c.errorLocal.value, isNull);
    });

    test('N2 valida las dos contraseñas y responde con un candado', () async {
      final b = Bienvenida();
      await b.visitar();
      final c = b.controlador..responderAlSaludo(yaUsa: false);
      c.registro!.codigoCtrl.text = '20230001';
      c.enviarCodigoDeAlumno();
      c.registro!
        ..passwordCtrl.text = 'corta'
        ..confirmacionCtrl.text = 'corta';
      c.enviarContrasenas();
      expect(c.errorLocal.value, isNotNull);
      c.registro!
        ..passwordCtrl.text = 'Contrasena1'
        ..confirmacionCtrl.text = 'Contrasena2';
      c.enviarContrasenas();
      expect(c.errorLocal.value, isNotNull);
      c.registro!.confirmacionCtrl.text = 'Contrasena1';
      c.enviarContrasenas();
      final respuesta = c.entradas.whereType<RespuestaDelAlumno>().last;
      expect(respuesta.texto, TextosDeLaBienvenida.contrasenaUlimaLista);
      expect(respuesta.secreta, isTrue);
      final tarjeta = c.entradas.last as BurbujaDeUlises;
      expect(tarjeta.tipo, TipoDeBurbuja.consentimiento);
      expect(c.turno.value, _T.n3Consentimiento);
    });

    test('aceptado una vez, el consentimiento no se repite al volver', () async {
      final b = await _enN5();
      final c = b.controlador..volver();
      expect(c.turno.value, _T.n4Portal);
      c.volver();
      expect(c.turno.value, _T.n2Contrasena);
      expect(b.delAlumno.last, TextosDeLaBienvenida.volver);
      expect(b.deUlises.last, TextosDeLaBienvenida.n2);
      expect(c.registro!.passwordCtrl.text, 'Contrasena1');
      c.enviarContrasenas();
      expect(c.turno.value, _T.n4Portal);
    });

    test('ningún turno antes del envío llama al backend', () async {
      final b = await _enN5();
      expect(b.servicioDeRegistro.llamadas, 0);
    });

    test('«Ya tengo cuenta» cierra el registro y abre E1', () async {
      final b = await _enN5();
      final registro = b.controlador.registro!;
      b.controlador.yaTengoCuenta();
      expect(b.delAlumno.last, TextosDeLaBienvenida.yaTengoCuenta);
      expect(b.controlador.registro, isNull);
      expect(registro.cerrado, isTrue);
      expect(b.controlador.turno.value, _T.e1Codigo);
    });
  });

  group('el envío y sus desenlaces (RF-BIEN-8)', () {
    test('mientras se envía, la advertencia de hoy, la píldora y el pulso, sin '
        'compositor', () async {
      final pendiente = Completer<RegistroResult>();
      final b = await _enN5(registro: RegistroFalso(pendiente: pendiente));
      final c = b.controlador;
      unawaited(c.crearCuenta());
      await Future<void>.delayed(Duration.zero);
      expect(b.delAlumno.last, TextosDeLaBienvenida.authenticatorListo);
      expect(b.deUlises.sublist(b.deUlises.length - 2), [
        TextosDeLaBienvenida.creando,
        TextosDeLaBienvenida.advertencia,
      ]);
      expect(c.pildora.value, EstadoDeLaPildora.creando);
      expect(c.enviando.value, isTrue);
      expect(c.turno.value, isNull);
      expect(c.ultimoTurno.value, _T.envio);
      // El atrás no sale y avisa abajo (BR-REG-F-09).
      c.atras();
      expect(b.avisos, [TextosDeLaBienvenida.avisoEnvioTitulo]);
      pendiente.complete(resultadoDelRegistro());
      await Future<void>.delayed(Duration.zero);
      expect(c.enviando.value, isFalse);
    });

    test('un 201 dice la cuenta y el conteo en una burbuja, cierra el registro '
        'y sigue el test', () async {
      final b = await _enN5();
      final registro = b.controlador.registro!;
      await b.controlador.crearCuenta();
      expect(b.controlador.pildora.value, EstadoDeLaPildora.creada);
      expect(
        b.deUlises,
        contains('¡Craa! Tu cuenta ya está lista. Traje tus 5 cursos del ciclo.'),
      );
      expect(registro.cerrado, isTrue);
      expect(b.controlador.registro, isNull);
      expect(b.controlador.conSesion, isTrue);
      expect(b.controlador.ultimoTurno.value, _T.t0Invitacion);
    });

    test('con 0 cursos no hay frase del conteo, y los avisos van en otra '
        'burbuja', () async {
      final b = await _enN5(
        registro: RegistroFalso(
          resultado: resultadoDelRegistro(cursos: 0, avisos: ['Sílabo caído.']),
        ),
      );
      await b.controlador.crearCuenta();
      expect(b.deUlises, contains('¡Craa! Tu cuenta ya está lista.'));
      final avisos = b.controlador.entradas
          .whereType<BurbujaDeUlises>()
          .firstWhere((e) => e.tipo == TipoDeBurbuja.avisos);
      expect(avisos.titulo, 'Algunas cosas que notamos');
      expect(avisos.lineas, ['Sílabo caído.']);
    });

    test('una cuenta que ya existe vuelve a N1 con el texto de hoy y el código '
        'del authenticator borrado', () async {
      final b = await _enN5(
        registro: RegistroFalso(
          fallo: const RegistroFailure(
            'Ya existe una cuenta con ese código. Inicia sesión o recupera tu '
            'contraseña.',
            code: 'USER_ALREADY_EXISTS',
          ),
        ),
      );
      await b.controlador.crearCuenta();
      expect(b.deUlises.last, startsWith('Ya existe una cuenta con ese código.'));
      expect(b.controlador.turno.value, _T.n1Codigo);
      expect(b.controlador.registro!.passcodeCtrl.text, '');
      expect(b.controlador.registro!.portalPasswordCtrl.text, 'clave-de-prueba');
      expect(b.controlador.pildora.value, isNull);
    });

    test('sin conexión vuelve a N5, como hoy vuelve a verificar (B-32)', () async {
      final b = await _enN5(
        registro: RegistroFalso(
          fallo: const RegistroFailure(
            'No hay conexión. Revisa tu internet e inténtalo de nuevo.',
            code: 'SIN_CONEXION',
          ),
        ),
      );
      await b.controlador.crearCuenta();
      expect(b.deUlises.last, TextosDeLaBienvenida.sinConexion);
      expect(b.controlador.turno.value, _T.n5Authenticator);
    });

    test('con el plazo vencido queda en la duda, con los dos títulos de hoy', () async {
      final b = await _enN5(
        registro: RegistroFalso(
          fallo: const RegistroFailure(
            'No pudimos confirmar si tu cuenta se creó.',
            code: 'TIEMPO_AGOTADO',
          ),
        ),
      );
      await b.controlador.crearCuenta();
      expect(b.deUlises.sublist(b.deUlises.length - 2), [
        TextosDeLaBienvenida.inciertoTitulo,
        TextosDeLaBienvenida.inciertoTexto,
      ]);
      expect(b.controlador.turno.value, _T.incierto);
    });

    test('con el 201 y sin sesión, la cuenta está creada y suma el mensaje',
        () async {
      final b = await _enN5(adoptarFalla: true);
      await b.controlador.crearCuenta();
      expect(b.deUlises, containsAllInOrder([
        TextosDeLaBienvenida.creadaTitulo,
        TextosDeLaBienvenida.creadaTexto,
        'Tu cuenta se creó, pero no pudimos dejarte la sesión iniciada.',
      ]));
      expect(b.controlador.turno.value, _T.incierto);
    });

    test('«Iniciar sesión» desde incierto sigue el test si entra, o dice que '
        'sigue sin poder confirmarlo', () async {
      final b = await _enN5(
        registro: RegistroFalso(
          fallo: const RegistroFailure('x', code: 'TIEMPO_AGOTADO'),
        ),
      );
      await b.controlador.crearCuenta();
      b.auth.errorDeLogin = 'Código o contraseña incorrectos.';
      await b.controlador.iniciarSesionDesdeIncierto();
      expect(b.deUlises.last, startsWith('Seguimos sin poder confirmarlo.'));
      expect(b.deUlises.last, endsWith('con “Ya tengo cuenta”.'));
      expect(b.controlador.turno.value, _T.incierto);
      b.auth
        ..errorDeLogin = null
        ..alEntrar = alumnaDePrueba(setupComplete: false);
      await b.controlador.iniciarSesionDesdeIncierto();
      expect(b.controlador.registro, isNull);
      expect(b.controlador.ultimoTurno.value, _T.t0Invitacion);
    });

    test('«Volver a intentar el registro» vuelve a N5 con el código del '
        'authenticator borrado', () async {
      final b = await _enN5(
        registro: RegistroFalso(
          fallo: const RegistroFailure('x', code: 'TIEMPO_AGOTADO'),
        ),
      );
      await b.controlador.crearCuenta();
      b.controlador.volverAIntentarElRegistro();
      expect(b.delAlumno.last, TextosDeLaBienvenida.volverAIntentar);
      expect(b.deUlises.last, TextosDeLaBienvenida.n5);
      expect(b.controlador.turno.value, _T.n5Authenticator);
      expect(b.controlador.registro!.passcodeCtrl.text, '');
      expect(b.controlador.registro!.portalPasswordCtrl.text, 'clave-de-prueba');
    });
  });
}
```

  En `test/bienvenida/bienvenida_credenciales_test.dart`, suma estos imports y este grupo.

```dart
import 'package:get/get.dart';
import 'package:ulima_plus/pages/bienvenida/conversacion.dart';

import 'apoyo_bienvenida.dart';
```

```dart
  group('las credenciales en la conversación (RF-BIEN-9)', () {
    tearDown(Get.reset);

    test('el historial guarda los rótulos y nunca las contraseñas ni el código '
        'del authenticator', () async {
      final b = Bienvenida();
      await b.visitar();
      final c = b.controlador..responderAlSaludo(yaUsa: false);
      c.registro!.codigoCtrl.text = '20230001';
      c.enviarCodigoDeAlumno();
      c.registro!
        ..passwordCtrl.text = 'Secreta-Ulima-1'
        ..confirmacionCtrl.text = 'Secreta-Ulima-1';
      c.enviarContrasenas();
      c.aceptarConsentimiento();
      c.registro!.portalPasswordCtrl.text = 'Secreta-Portal-1';
      c.enviarPortal();
      c.registro!.passcodeCtrl.text = '482913';
      await c.crearCuenta();
      final textos = <String>[
        for (final e in c.entradas)
          if (e is BurbujaDeUlises) ...[e.texto, ...e.lineas]
          else if (e is RespuestaDelAlumno) e.texto,
      ].join('|');
      expect(textos, isNot(contains('Secreta-Ulima-1')));
      expect(textos, isNot(contains('Secreta-Portal-1')));
      expect(textos, isNot(contains('482913')));
      expect(textos, contains('20230001'), reason: 'el código sí se muestra');
    });

    test('el controlador del registro se crea sin Get.put', () async {
      final b = Bienvenida();
      await b.visitar();
      b.controlador.responderAlSaludo(yaUsa: false);
      expect(b.controlador.registro, isNotNull);
      expect(Get.isRegistered<RegistroController>(), isFalse);
    });

    test('se cierra al reiniciar la bienvenida y en el dispose de su visita',
        () async {
      final b = Bienvenida();
      final visita = b.controlador.nuevaVisita();
      await b.controlador.empezarVisita(visita);
      b.controlador.responderAlSaludo(yaUsa: false);
      final registro = b.controlador.registro!;
      b.controlador.terminarVisita(visita);
      expect(registro.cerrado, isTrue);
    });
  });
```

  Crea `test/bienvenida/bienvenida_atras_test.dart`. La Tarea 25 le suma el test.

```dart
// test/bienvenida/bienvenida_atras_test.dart
//
// UNITARIA · Bienvenida con Ulises (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-13. El atrás del sistema hace lo mismo que el enlace secundario de
// cada turno. La Tarea 25 suma los turnos del test.
// Archivo probado lib/pages/bienvenida/bienvenida_controller.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/domain/bienvenida/bienvenida_turnos.dart';

import 'apoyo_bienvenida.dart';

typedef _T = TurnoDeLaBienvenida;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Get.reset);

  group('el atrás en el registro (RF-BIEN-13)', () {
    test('N1 es «Ya tengo cuenta» y N2 es «Volver»', () async {
      final b = Bienvenida();
      await b.visitar();
      final c = b.controlador..responderAlSaludo(yaUsa: false);
      c.registro!.codigoCtrl.text = '20230001';
      c.enviarCodigoDeAlumno();
      c.atras();
      expect(c.turno.value, _T.n1Codigo);
      c.atras();
      expect(c.turno.value, _T.e1Codigo);
      expect(c.registro, isNull);
    });

    test('incierto es «Volver a intentar el registro»', () async {
      final b = Bienvenida(
        registro: RegistroFalso(
          fallo: const RegistroFailure('x', code: 'TIEMPO_AGOTADO'),
        ),
      );
      await b.visitar();
      final c = b.controlador..responderAlSaludo(yaUsa: false);
      c.registro!.codigoCtrl.text = '20230001';
      c.enviarCodigoDeAlumno();
      c.registro!
        ..passwordCtrl.text = 'Contrasena1'
        ..confirmacionCtrl.text = 'Contrasena1';
      c.enviarContrasenas();
      c.aceptarConsentimiento();
      c.registro!.portalPasswordCtrl.text = 'clave-de-prueba';
      c.enviarPortal();
      c.registro!.passcodeCtrl.text = '123456';
      await c.crearCuenta();
      expect(c.turno.value, _T.incierto);
      c.atras();
      expect(c.turno.value, _T.n5Authenticator);
    });
  });
}
```

  Esta prueba usa `RegistroFailure`, así que suma el import de
  `package:ulima_plus/models/registro_models.dart`.

- [ ] **Paso 3. Corre las pruebas y confirma que fallan.**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/bienvenida
```

Esperado. Falla la compilación, porque los métodos del registro y `EstadoDeLaPildora` no existen.

- [ ] **Paso 4. Suma el registro al controlador.** En
  `lib/pages/bienvenida/bienvenida_controller.dart`, haz estos cambios.

  1. Los imports y el estado de la píldora.

```dart
import '../password_reset/password_reset_validators.dart';
```

```dart
/// La píldora bajo la franja mientras se crea la cuenta (RF-BIEN-8).
enum EstadoDeLaPildora { creando, creada }
```

  2. El parámetro `avisar` del constructor, con su campo, y el estado nuevo.

```dart
    void Function(String titulo, String texto)? avisar,
```

```dart
       _avisar =
           avisar ??
           ((titulo, texto) => Get.snackbar(
             titulo,
             texto,
             snackPosition: SnackPosition.BOTTOM,
           )),
```

```dart
  final void Function(String titulo, String texto) _avisar;

  final pildora = Rxn<EstadoDeLaPildora>();

  /// Mientras se envía el registro, el pulso recorre los rombos (RF-BIEN-4).
  final enviando = false.obs;
```

  3. En `_reiniciar`, suma `pildora.value = null;` y `enviando.value = false;`.

  4. Reemplaza la sección `// ── Registro (Tarea 24)` por esta.

```dart
  // ── Registro (RF-BIEN-7 a RF-BIEN-9) ─────────────────────────────────────

  void _abrirN1({Duration primera = Ritmo.trasLaRespuesta}) {
    registro ??= _crearRegistro();
    _decir(<String>[TextosB.n1a, TextosB.n1b], primera: primera);
    _abrir(TurnoB.n1Codigo);
  }

  /// Cada turno valida lo suyo en local, con los validadores de hoy, antes
  /// de cerrar el compositor y sin llamar a la red (BR-REG-F-03).
  bool _valida(String? error) {
    errorLocal.value = error;
    return error == null;
  }

  void enviarCodigoDeAlumno() {
    final r = registro;
    if (r == null || turno.value != TurnoB.n1Codigo) return;
    if (!_valida(validarCodigo(r.codigoCtrl.text))) return;
    // El código es la excepción, porque su burbuja lo muestra (RF-BIEN-9).
    _responder(r.codigoCtrl.text.trim());
    _decir(<String>[TextosB.n2]);
    _abrir(TurnoB.n2Contrasena);
  }

  void enviarContrasenas() {
    final r = registro;
    if (r == null || turno.value != TurnoB.n2Contrasena) return;
    final error =
        validateNewPassword(r.passwordCtrl.text) ??
        validatePasswordConfirmation(r.passwordCtrl.text, r.confirmacionCtrl.text);
    if (!_valida(error)) return;
    _responder(TextosB.contrasenaUlimaLista, secreta: true);
    // Aceptado una vez, el consentimiento dura lo que dura la rama.
    if (r.consentimientoAceptado.value) {
      _abrirN4();
    } else {
      _decir(<String>[TextosB.n3]);
      entradas.add(
        BurbujaDeUlises(
          id: _id(),
          texto: '',
          tipo: TipoDeBurbuja.consentimiento,
          pausa: Ritmo.entreBurbujas,
        ),
      );
      _abrir(TurnoB.n3Consentimiento);
    }
  }

  void aceptarConsentimiento() {
    final r = registro;
    if (r == null || turno.value != TurnoB.n3Consentimiento) return;
    r.aceptarConsentimiento();
    _responder(TextosB.acepto);
    _abrirN4();
  }

  void _abrirN4() {
    _decir(<String>[TextosB.n4]);
    _abrir(TurnoB.n4Portal);
  }

  void enviarPortal() {
    final r = registro;
    if (r == null || turno.value != TurnoB.n4Portal) return;
    if (!_valida(validarPortalPassword(r.portalPasswordCtrl.text))) return;
    _responder(TextosB.contrasenaMiUlimaLista, secreta: true);
    _abrirN5();
  }

  void _abrirN5() {
    _decir(<String>[TextosB.n5]);
    _abrir(TurnoB.n5Authenticator);
  }

  /// «Crear mi cuenta». El envío es un botón y no sale solo al completar las
  /// seis casillas (B-5).
  Future<void> crearCuenta() async {
    final r = registro;
    if (r == null || turno.value != TurnoB.n5Authenticator) return;
    if (!_valida(validarPasscode(r.passcodeCtrl.text))) return;
    _responder(TextosB.authenticatorListo, secreta: true);
    _decir(<String>[TextosB.creando, TextosB.advertencia]);
    ultimoTurno.value = TurnoB.envio;
    pildora.value = EstadoDeLaPildora.creando;
    enviando.value = true;
    await r.enviar();
    if (!identical(registro, r)) return;
    enviando.value = false;
    switch (r.paso.value) {
      case RegistroPaso.listo:
        _alCrearLaCuenta(r);
      case RegistroPaso.incierto:
        pildora.value = null;
        _decirLaDuda(r);
      case RegistroPaso.datos:
        pildora.value = null;
        _decirError(r.errorMessage.value ?? TextosB.sinConexion);
        _abrir(TurnoB.n1Codigo);
      case RegistroPaso.verificar:
      case RegistroPaso.consentimiento:
      case RegistroPaso.enviando:
        pildora.value = null;
        _decirError(r.errorMessage.value ?? TextosB.sinConexion);
        _abrir(TurnoB.n5Authenticator);
    }
  }

  void _alCrearLaCuenta(RegistroController r) {
    pildora.value = EstadoDeLaPildora.creada;
    final resultado = r.resultado.value;
    _decir(<String>[
      textoDeCuentaLista(resultado?.summary.cursos ?? 0),
    ], primera: Duration.zero);
    final avisos = resultado?.warnings ?? const [];
    if (avisos.isNotEmpty) {
      entradas.add(
        BurbujaDeUlises(
          id: _id(),
          texto: '',
          tipo: TipoDeBurbuja.avisos,
          titulo: TextosB.avisosDelRegistro,
          lineas: <String>[for (final a in avisos) a.message],
          pausa: Ritmo.entreBurbujas,
        ),
      );
    }
    _cerrarRegistro();
    _conSesion = true;
    _empezarElTest();
  }

  /// Los títulos de hoy con un punto final, y con SIN_TOKEN el mensaje si no
  /// repite el título (`registro_page.dart:405-433`).
  void _decirLaDuda(RegistroController r) {
    final confirmada = r.cuentaConfirmada.value;
    final lineas = confirmada
        ? <String>[TextosB.creadaTitulo, TextosB.creadaTexto]
        : <String>[TextosB.inciertoTitulo, TextosB.inciertoTexto];
    final mensaje = r.errorMessage.value;
    String normal(String s) =>
        s.replaceAll(RegExp(r'[.…]'), '').trim().toLowerCase();
    if (mensaje != null && normal(mensaje) != normal(lineas.first)) {
      lineas.add(mensaje);
    }
    _decir(lineas, primera: Duration.zero);
    _abrir(TurnoB.incierto);
  }

  Future<void> iniciarSesionDesdeIncierto() async {
    final r = registro;
    if (r == null || turno.value != TurnoB.incierto || esperando.value) return;
    esperando.value = true;
    final entro = await r.intentarIniciarSesion();
    esperando.value = false;
    if (!identical(registro, r)) return;
    if (!entro) {
      _decirError(r.errorMessage.value ?? TextosB.sinConexion);
      return;
    }
    _responder(TextosB.iniciarSesion);
    _cerrarRegistro();
    _conSesion = true;
    final usuario = _auth.currentUser;
    if (usuario != null && postLoginRoute(usuario) == '/home') {
      _decir(<String>[TextosB.e3]);
      _abrir(TurnoB.pasoAlHorario);
      return;
    }
    _empezarElTest();
  }

  void volverAIntentarElRegistro() {
    final r = registro;
    if (r == null || turno.value != TurnoB.incierto) return;
    r.volverAVerificar();
    _responder(TextosB.volverAIntentar);
    _abrirN5();
  }

  /// «Ya tengo cuenta», en todos los turnos del registro antes del envío y
  /// en incierto (RF-BIEN-9).
  void yaTengoCuenta() {
    const conEnlace = <TurnoDeLaBienvenida>{
      TurnoB.n1Codigo,
      TurnoB.n2Contrasena,
      TurnoB.n3Consentimiento,
      TurnoB.n4Portal,
      TurnoB.n5Authenticator,
      TurnoB.incierto,
    };
    if (!conEnlace.contains(turno.value)) return;
    _responder(TextosB.yaTengoCuenta);
    _cerrarRegistro();
    _abrirE1();
  }

  /// «Volver» reabre el turno anterior con lo escrito, y Ulises repite su
  /// pregunta (BR-REG-F-05).
  void volver() {
    final anterior = switch (turno.value) {
      TurnoB.n2Contrasena => TurnoB.n1Codigo,
      TurnoB.n3Consentimiento || TurnoB.n4Portal => TurnoB.n2Contrasena,
      TurnoB.n5Authenticator => TurnoB.n4Portal,
      _ => null,
    };
    if (anterior == null) return;
    _responder(TextosB.volver);
    final pregunta = switch (anterior) {
      TurnoB.n1Codigo => TextosB.n1b,
      TurnoB.n2Contrasena => TextosB.n2,
      _ => TextosB.n4,
    };
    _decir(<String>[pregunta]);
    _abrir(anterior);
  }
```

  5. En `atras()`, las cuatro acciones del registro llaman a su método.

```dart
      case AccionDelAtras.yaTengoCuenta:
        yaTengoCuenta();
      case AccionDelAtras.volver:
        volver();
      case AccionDelAtras.avisarQueSeEnvia:
        _avisar(TextosB.avisoEnvioTitulo, TextosB.avisoEnvioTexto);
      case AccionDelAtras.volverAIntentar:
        volverAIntentarElRegistro();
```

- [ ] **Paso 5. Corre las pruebas y confirma que pasan.**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/pages/bienvenida test/bienvenida
"${FLUTTER:?}" test --no-pub test/bienvenida test/HU33_jeff
"${FLUTTER:?}" analyze --no-pub
```

Esperado. `All tests passed!` y los avisos de la base.

- [ ] **Paso 6. Commit.**

```bash
cd "${REPO:?}"
git status --short
git add lib/pages/bienvenida/bienvenida_controller.dart test/bienvenida
git commit -m "feat(bienvenida): el registro de hoy corre en turnos de la conversación, con el envío, sus desenlaces y las credenciales fuera del historial (RF-BIEN-7 a RF-BIEN-9)"
git log -1 --format='%an <%ae>'
```

---

### Tarea 25. El test y la selección manual en la conversación, con el 401

**Requisitos.** RF-BIEN-10 completo en su parte de datos (decisiones B-1, B-11, B-12, B-14, B-15 y
B-34), el 401 de RF-BIEN-12 (decisión B-22), el atrás de RF-BIEN-13 en los turnos del test y
RF-BIEN-21 hasta el paso al horario (decisión B-10).

**Archivos.**
- Modificar `lib/pages/bienvenida/bienvenida_controller.dart`.
- Modificar `lib/domain/bienvenida/bienvenida_turnos.dart` (texto «Empezar de nuevo»).
- Modificar `test/bienvenida/apoyo_bienvenida.dart` (el service del test y los guardados).
- Modificar `test/bienvenida/bienvenida_test_especialidad_test.dart` (grupo `el test en la
  conversación`).
- Crear `test/bienvenida/bienvenida_errores_test.dart`.
- Modificar `test/bienvenida/bienvenida_atras_test.dart` (grupo `el atrás en el test`).
- Modificar `test/bienvenida/bienvenida_sin_especialidad_test.dart` (grupo `hasta el horario`).

**Interfaces.**
- Consume el controlador del test con el origen `bienvenida` (Tarea 21), `emojisDeLaEscala`
  (Tarea 22), `turnoAntesDePregunta`, `turnoAntesDeDesempate`, `turnoDeEspera`,
  `textoDeRespuesta` y `seleccionOficial` de `specialty_test_logic.dart`, y
  `AuthService.officialSpecialtyIds`, `especialidades`, `catalogsFailed`, `reloadCatalogs` y
  `completeSetup`.
- Produce, en `BienvenidaController`, estas firmas, que usa la Tarea 27.

```dart
final RxInt confeti; final RxnInt principalManual; final RxSet<int> interesesManuales;
final RxBool catalogoFallido; final RxBool pideReinicio;
List<Map<String, dynamic>> get especialidadesOficiales;
void empezarElTest(); void saltarElTest(); void reintentarElContenido();
void responderAlTest(String valor, {bool conLector = false}); void siguiente();
void preguntaAnterior(); void reintentarLaEvaluacion(); void empezarDeNuevo();
Future<void> elegirComoPrincipal(int especialidad); Future<void> decidirDespues();
void rehacerElTest(); void alternarCorazon(int especialidad);
void marcarPrincipal(int especialidad); void alternarInteres(int especialidad);
Future<void> terminarLaSeleccion(); Future<void> reintentarElCatalogo();
```

- [ ] **Paso 1. Suma el test al apoyo.** En `test/bienvenida/apoyo_bienvenida.dart`, suma estos
  imports, los parámetros y los métodos de `AuthDeLaBienvenida` y el service del test en
  `Bienvenida`.

```dart
import 'package:ulima_plus/pages/specialty_test/specialty_test_logic.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';

import '../HU36_jeff/dobles_de_red.dart';
```

```dart
  // En AuthDeLaBienvenida:
  final List<SeleccionDeEspecialidades> guardados = <SeleccionDeEspecialidades>[];
  Object? falloAlGuardar;
  bool catalogoFalla = false;

  @override
  Future<void> completeSetup({
    required int careerId,
    int? especialidadPrincipal,
    required List<int> especialidadesInteres,
    Duration? timeout,
  }) async {
    if (falloAlGuardar != null) throw falloAlGuardar!;
    guardados.add(
      SeleccionDeEspecialidades(
        principal: especialidadPrincipal,
        intereses: List<int>.of(especialidadesInteres),
      ),
    );
    usuario?.setupComplete = true;
  }

  @override
  List<Map<String, dynamic>> get especialidades => catalogoFalla
      ? const <Map<String, dynamic>>[]
      : <Map<String, dynamic>>[
          for (final (id, nombre, orden) in const [
            (1, 'Ingeniería de Software', 1),
            (5, 'Tecnologías de Información', 2),
            (6, 'Sistemas Inteligentes', 3),
            (7, 'Videojuegos', 4),
          ])
            <String, dynamic>{
              'id': id,
              'carrera_id': 1,
              'name': nombre,
              'display_order': orden,
              'is_active': true,
            },
        ];

  @override
  Set<int> get officialSpecialtyIds => catalogoFalla ? <int>{} : {1, 5, 6, 7};

  @override
  bool get catalogsFailed => catalogoFalla;

  @override
  Future<bool> reloadCatalogs() async {
    catalogoFalla = false;
    return true;
  }
```

  `Bienvenida` suma el parámetro `ApiFalsaDelTest? apiDelTest` y, antes de crear el controlador,
  registra el service del test sobre esa API.

```dart
    Get.put<SpecialtyTestService>(
      SpecialtyTestService(apiClient: apiDelTest ?? ApiFalsaDelTest()),
    );
```

  Los nombres de las especialidades y sus ids son los inventados de la rama del test (1, 5, 6 y 7).

- [ ] **Paso 2. Escribe las pruebas que fallan.** En
  `test/bienvenida/bienvenida_test_especialidad_test.dart`, suma estos imports y este grupo.

```dart
import 'package:ulima_plus/domain/bienvenida/bienvenida_turnos.dart';
import 'package:ulima_plus/pages/bienvenida/conversacion.dart';

import 'apoyo_bienvenida.dart';
```

```dart
  group('el test en la conversación (RF-BIEN-10)', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    /// Una alumna recién registrada, con la conversación en T0.
    Future<Bienvenida> enT0({ApiFalsaDelTest? api, int? careerId = 1}) async {
      final b = Bienvenida(
        auth: AuthDeLaBienvenida(
          usuario: alumnaDePrueba(setupComplete: false, careerId: careerId),
          alEntrar: alumnaDePrueba(setupComplete: false, careerId: careerId),
        ),
        token: 'jwt-de-prueba',
        apiDelTest: api,
      );
      await b.visitar();
      b.controlador.ulisesAterrizoConSesion();
      await pumpEventQueue();
      return b;
    }

    String? ultimaDeUlises(Bienvenida b) => b.deUlises.isEmpty ? null : b.deUlises.last;

    test('mientras llega el contenido Ulises muestra la burbuja de carga, y '
        'después la invitación con T preguntas (B-11 y B-12)', () async {
      final b = await enT0();
      final c = b.controlador;
      expect(c.test, isNotNull);
      expect(Get.isRegistered<SpecialtyTestController>(), isFalse);
      expect(
        ultimaDeUlises(b),
        '¿Empezamos tu test de especialidad? Son 5 preguntas cortas.',
      );
      expect(
        c.entradas.whereType<BurbujaDeUlises>().any(
          (e) => e.tipo == TipoDeBurbuja.cargando,
        ),
        isFalse,
        reason: 'la burbuja de carga se reemplaza',
      );
      expect(c.turno.value, TurnoDeLaBienvenida.t0Invitacion);
    });

    test('cada pregunta es un turno con sus líneas y el prompt, y la respuesta '
        'es el texto de la tarea o el emoji con la etiqueta', () async {
      final b = await enT0();
      final c = b.controlador..empezarElTest();
      expect(b.delAlumno.last, TextosDeLaBienvenida.empezarElTest);
      expect(b.deUlises, containsAllInOrder([kDuelHelp, '¿Cuál harías con más ganas?']));
      expect(c.turno.value, TurnoDeLaBienvenida.pregunta);
      final tareaDeArriba = c.test!.preguntaActual!.top!.text;
      c
        ..responderAlTest('top', conLector: true)
        ..siguiente();
      expect(b.delAlumno.last, tareaDeArriba);
      expect(b.deUlises, contains('Reacción propia de la pregunta uno.'));
      expect(c.latidos.value, greaterThanOrEqualTo(2));
    });

    test('«Pregunta anterior» repite el paso previo, y desde la pregunta 1 '
        'lleva a T0', () async {
      final b = await enT0();
      final c = b.controlador..empezarElTest();
      c
        ..responderAlTest('top', conLector: true)
        ..siguiente()
        ..preguntaAnterior();
      expect(b.delAlumno.last, TextosDeLaBienvenida.preguntaAnterior);
      expect(c.test!.paso.value, 0);
      expect(c.turno.value, TurnoDeLaBienvenida.pregunta);
      c.preguntaAnterior();
      expect(c.turno.value, TurnoDeLaBienvenida.t0Invitacion);
    });

    test('la espera dice la línea de carga, y el resultado entra con el '
        'confeti y sus tres botones', () async {
      final b = await enT0();
      final c = b.controlador..empezarElTest();
      for (final v in respuestasEnOrden) {
        c
          ..responderAlTest(v, conLector: true)
          ..siguiente();
      }
      expect(
        c.entradas.whereType<BurbujaDeUlises>().last.tipo,
        TipoDeBurbuja.esperando,
      );
      expect(b.deUlises.last, kLoading);
      await pumpEventQueue();
      expect(c.confeti.value, 1);
      expect(c.entradas.whereType<ResultadoDelTest>(), hasLength(1));
      expect(c.turno.value, TurnoDeLaBienvenida.resultado);
    });

    test('«Elegir como principal» guarda, responde y se despide hacia el '
        'horario', () async {
      final b = await enT0();
      final c = b.controlador..empezarElTest();
      for (final v in respuestasEnOrden) {
        c
          ..responderAlTest(v, conLector: true)
          ..siguiente();
      }
      await pumpEventQueue();
      final primera = c.test!.resultado.value!.ranking.first.specialtyId;
      await c.elegirComoPrincipal(primera);
      expect(b.auth.guardados.single.principal, primera);
      expect(b.delAlumno.last, 'Elegir como principal');
      expect(b.deUlises.last, TextosDeLaBienvenida.listoAlHorario);
      expect(c.turno.value, TurnoDeLaBienvenida.pasoAlHorario);
    });

    test('«Rehacer el test» vuelve a la pregunta 1 sin pasar por T0', () async {
      final b = await enT0();
      final c = b.controlador..empezarElTest();
      for (final v in respuestasEnOrden) {
        c
          ..responderAlTest(v, conLector: true)
          ..siguiente();
      }
      await pumpEventQueue();
      c.rehacerElTest();
      expect(b.delAlumno.last, 'Rehacer el test');
      expect(c.turno.value, TurnoDeLaBienvenida.pregunta);
      expect(c.test!.paso.value, 0);
    });

    test('«Saltar y elegir por mi cuenta» pasa a la selección manual con la '
        'lista oficial, y el atrás vuelve a T0', () async {
      final b = await enT0();
      final c = b.controlador..saltarElTest();
      expect(b.deUlises.last, TextosDeLaBienvenida.eligeMencion);
      expect(c.turno.value, TurnoDeLaBienvenida.seleccionManual);
      expect(c.especialidadesOficiales.map((e) => e['id']), [1, 5, 6, 7]);
      c.atras();
      expect(c.turno.value, TurnoDeLaBienvenida.t0Invitacion);
    });

    test('la selección manual guarda con «Finalizar configuración» o «Saltar '
        'por ahora»', () async {
      final b = await enT0();
      final c = b.controlador
        ..saltarElTest()
        ..marcarPrincipal(5)
        ..alternarInteres(7);
      await c.terminarLaSeleccion();
      expect(b.auth.guardados.single.principal, 5);
      expect(b.auth.guardados.single.intereses, [7]);
      expect(b.delAlumno.last, TextosDeLaBienvenida.finalizar);
      expect(c.turno.value, TurnoDeLaBienvenida.pasoAlHorario);
    });

    test('un 404 pasa a la selección manual sin aviso, y el atrás no hace '
        'nada', () async {
      final b = await enT0(
        api: ApiFalsaDelTest(
          contenido: <Object>[
            const SpecialtyTestFailure(
              SpecialtyTestFailureKind.notAvailable,
              message: 'No disponible.',
            ),
          ],
        ),
      );
      final c = b.controlador;
      expect(c.turno.value, TurnoDeLaBienvenida.seleccionManual);
      expect(b.deUlises, isNot(contains('No disponible.')));
      c.atras();
      expect(c.turno.value, TurnoDeLaBienvenida.seleccionManual);
    });

    test('sin carrera no guarda y dice el texto de hoy del asistente', () async {
      final b = await enT0(careerId: null);
      final c = b.controlador
        ..saltarElTest()
        ..marcarPrincipal(5);
      await c.terminarLaSeleccion();
      expect(b.auth.guardados, isEmpty);
      expect(b.deUlises.last, TextosDeLaBienvenida.sinCarrera);
    });

    test('si el catálogo no carga, dice que no pudo y ofrece reintentar', () async {
      final b = await enT0();
      b.auth.catalogoFalla = true;
      final c = b.controlador..saltarElTest();
      expect(b.deUlises.last, TextosDeLaBienvenida.noCargaronEspecialidades);
      expect(c.catalogoFallido.value, isTrue);
      await c.reintentarElCatalogo();
      expect(c.catalogoFallido.value, isFalse);
    });
  });
```

  Crea `test/bienvenida/bienvenida_errores_test.dart`.

```dart
// test/bienvenida/bienvenida_errores_test.dart
//
// UNITARIA · Bienvenida con Ulises (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-12. Cada error del backend o de la red es una burbuja de Ulises.
// Recorre cada fila de la tabla, del recibimiento y los turnos sin envío a
// E2, Google, la validación local, el envío y lo que sigue al 201, T0, el test
// y el 401 en un turno con sesión, con la limpieza local y la vuelta a E1
// (B-22). Las dos filas del paso al horario necesitan la capa del arranque y
// van en bienvenida_horario_test.dart.
// Archivo probado lib/pages/bienvenida/bienvenida_controller.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/domain/bienvenida/bienvenida_turnos.dart';
import 'package:ulima_plus/models/registro_models.dart';
import 'package:ulima_plus/pages/bienvenida/conversacion.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';

import '../HU36_jeff/datos_de_prueba.dart';
import '../HU36_jeff/dobles_de_red.dart';
import 'apoyo_bienvenida.dart';

typedef _T = TurnoDeLaBienvenida;

/// Llega a E2 con el código de prueba y una contraseña inventada.
Future<Bienvenida> _enE2(AuthDeLaBienvenida auth) async {
  final b = Bienvenida(auth: auth);
  await b.visitar();
  b.controlador.responderAlSaludo(yaUsa: true);
  b.login.codeController.text = '20230001';
  b.controlador.enviarCodigo();
  b.login.passwordController.text = 'secreta-de-prueba';
  return b;
}

/// Llega hasta N5 con datos válidos inventados.
Future<Bienvenida> _enN5({RegistroFalso? registro, bool adoptarFalla = false}) async {
  final b = Bienvenida(registro: registro, adoptarFalla: adoptarFalla);
  await b.visitar();
  final c = b.controlador..responderAlSaludo(yaUsa: false);
  c.registro!.codigoCtrl.text = '20230001';
  c.enviarCodigoDeAlumno();
  c.registro!
    ..passwordCtrl.text = 'Contrasena1'
    ..confirmacionCtrl.text = 'Contrasena1';
  c.enviarContrasenas();
  c.aceptarConsentimiento();
  c.registro!.portalPasswordCtrl.text = 'clave-de-prueba';
  c.enviarPortal();
  c.registro!.passcodeCtrl.text = '123456';
  return b;
}

/// Las burbujas de error de Ulises.
List<BurbujaDeUlises> _errores(Bienvenida b) => <BurbujaDeUlises>[
  for (final e in b.controlador.entradas)
    if (e is BurbujaDeUlises && e.tipo == TipoDeBurbuja.error) e,
];

Future<Bienvenida> _conSesion(ApiFalsaDelTest api) async {
  final b = Bienvenida(
    auth: AuthDeLaBienvenida(usuario: alumnaDePrueba(setupComplete: false)),
    token: 'jwt-de-prueba',
    apiDelTest: api,
  );
  await b.visitar();
  b.controlador.ulisesAterrizoConSesion();
  await pumpEventQueue();
  return b;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Get.reset);

  group('cada fila de la tabla, antes del test (RF-BIEN-12)', () {
    test('el recibimiento y los turnos sin envío no usan la red, así que sin '
        'conexión no se ve nada', () async {
      final b = await _enE2(AuthDeLaBienvenida(redCaida: true));
      expect(_errores(b), isEmpty);
      expect(b.controlador.turno.value, _T.e2Contrasena);
    });

    test('en E2, cada error del login dice el mensaje de AuthService y vuelve '
        'a E1 con el código y la contraseña vacía (B-6)', () async {
      // Los mensajes de la tabla salen de loginErrorMessage.
      const invalido = AuthService.invalidCredentialsMessage;
      expect(AuthService.loginErrorMessage('USER_NOT_FOUND', 'x'), invalido);
      expect(AuthService.loginErrorMessage('INVALID_PASSWORD', 'x'), invalido);
      expect(
        AuthService.loginErrorMessage('NOT_ENROLLED', 'x'),
        'No tienes una matrícula activa.',
      );
      expect(
        AuthService.loginErrorMessage('OTRO_ERROR', 'Mensaje del backend de prueba.'),
        'Mensaje del backend de prueba.',
      );
      for (final mensaje in <String>[
        invalido,
        'No tienes una matrícula activa.',
        'Mensaje del backend de prueba.',
      ]) {
        final b = await _enE2(AuthDeLaBienvenida(errorDeLogin: mensaje));
        await b.controlador.entrar();
        expect(_errores(b).single.texto, mensaje);
        expect(b.controlador.turno.value, _T.e1Codigo);
        expect(b.login.codeController.text, '20230001');
        expect(b.login.passwordController.text, '');
        Get.reset();
      }
    });

    test('en E2, sin conexión, E2 sigue abierto con la contraseña escrita',
        () async {
      final b = await _enE2(AuthDeLaBienvenida(redCaida: true));
      await b.controlador.entrar();
      expect(_errores(b).single.texto, TextosDeLaBienvenida.sinConexion);
      expect(b.controlador.turno.value, _T.e2Contrasena);
      expect(b.login.passwordController.text, 'secreta-de-prueba');
    });

    test('en E1, Google cancelado no dice nada, y INVALID_DOMAIN, '
        'USER_NOT_FOUND, la falta de idToken y otro fallo son una burbuja con '
        'E1 abierto, sin ofrecer crear la cuenta', () async {
      final b = Bienvenida(auth: AuthDeLaBienvenida(google: 'cancelar'));
      await b.visitar();
      b.controlador.responderAlSaludo(yaUsa: true);
      final antes = b.controlador.entradas.length;
      await b.controlador.entrarConGoogle();
      expect(b.controlador.entradas, hasLength(antes));
      for (final mensaje in <String>[
        'Debes usar tu correo @aloe.ulima.edu.pe o @ulima.edu.pe.',
        'Tu correo no está registrado en el sistema.',
        'No se obtuvo información de Google.',
        'No se pudo iniciar sesión con Google.',
      ]) {
        b.auth.google = mensaje;
        final respuestas = b.delAlumno.length;
        await b.controlador.entrarConGoogle();
        expect(b.deUlises.last, mensaje);
        expect(_errores(b).last.texto, mensaje);
        expect(b.delAlumno, hasLength(respuestas), reason: 'ninguna oferta');
        expect(b.controlador.turno.value, _T.e1Codigo);
      }
    });

    test('de N1 a N5, la validación local va bajo el campo y no es burbuja',
        () async {
      final b = Bienvenida();
      await b.visitar();
      final c = b.controlador..responderAlSaludo(yaUsa: false);
      c.registro!.codigoCtrl.text = '12ab';
      c.enviarCodigoDeAlumno();
      expect(c.errorLocal.value, isNotNull);
      expect(_errores(b), isEmpty);
      expect(c.turno.value, _T.n1Codigo);
    });

    test('el envío sin conexión vuelve a N5, el plazo vencido y el 201 sin '
        'sesión quedan en incierto, y un «Iniciar sesión» que no entra lo dice '
        '(B-30 y B-32)', () async {
      final sinRed = await _enN5(
        registro: RegistroFalso(
          fallo: const RegistroFailure(
            'No hay conexión. Revisa tu internet e inténtalo de nuevo.',
            code: 'SIN_CONEXION',
          ),
        ),
      );
      await sinRed.controlador.crearCuenta();
      expect(sinRed.deUlises.last, TextosDeLaBienvenida.sinConexion);
      expect(sinRed.controlador.turno.value, _T.n5Authenticator);
      Get.reset();

      final plazo = await _enN5(
        registro: RegistroFalso(
          fallo: const RegistroFailure('x', code: 'TIEMPO_AGOTADO'),
        ),
      );
      await plazo.controlador.crearCuenta();
      expect(plazo.controlador.turno.value, _T.incierto);
      plazo.auth.errorDeLogin = 'Código o contraseña incorrectos.';
      await plazo.controlador.iniciarSesionDesdeIncierto();
      expect(plazo.deUlises.last, startsWith('Seguimos sin poder confirmarlo.'));
      expect(plazo.controlador.turno.value, _T.incierto);
      Get.reset();

      final sinSesion = await _enN5(adoptarFalla: true);
      await sinSesion.controlador.crearCuenta();
      expect(sinSesion.deUlises, contains(TextosDeLaBienvenida.creadaTitulo));
      expect(sinSesion.controlador.turno.value, _T.incierto);
    });

    test('después del 201, los catálogos que fallan no se notan y sigue el '
        'test (BR-REG-F-10)', () async {
      final b = await _enN5();
      b.auth.catalogoFalla = true;
      await b.controlador.crearCuenta();
      await pumpEventQueue();
      expect(_errores(b), isEmpty);
      expect(b.controlador.ultimoTurno.value, _T.t0Invitacion);
    });
  });

  group('los errores del test (RF-BIEN-12)', () {
    test('en T0, el contenido que no llega dice «No pudimos cargar el test.» '
        'y reintentar lo pide otra vez', () async {
      final api = ApiFalsaDelTest(
        contenido: <Object>[
          const SpecialtyTestFailure(SpecialtyTestFailureKind.offline),
          contenidoJson(),
        ],
      );
      final b = await _conSesion(api);
      final error = b.controlador.entradas.whereType<BurbujaDeUlises>().last;
      expect(error.texto, TextosDeLaBienvenida.noCargoElTest);
      expect(error.tipo, TipoDeBurbuja.error);
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.t0Invitacion);
      b.controlador.reintentarElContenido();
      await pumpEventQueue();
      expect(
        b.deUlises.last,
        '¿Empezamos tu test de especialidad? Son 5 preguntas cortas.',
      );
    });

    test('un error de la espera es una burbuja con su texto y «Reintentar»', () async {
      final api = ApiFalsaDelTest(
        evaluaciones: <Object>[
          const SpecialtyTestFailure(SpecialtyTestFailureKind.offline),
          resultadoJson(),
        ],
      );
      final b = await _conSesion(api);
      final c = b.controlador..empezarElTest();
      for (final v in respuestasEnOrden) {
        c
          ..responderAlTest(v, conLector: true)
          ..siguiente();
      }
      await pumpEventQueue();
      expect(
        c.entradas.whereType<BurbujaDeUlises>().last.tipo,
        TipoDeBurbuja.error,
      );
      expect(c.turno.value, TurnoDeLaBienvenida.espera);
      c.reintentarLaEvaluacion();
      await pumpEventQueue();
      expect(c.turno.value, TurnoDeLaBienvenida.resultado);
    });

    test('un 401 en un turno con sesión limpia la sesión local, borra el '
        'historial y vuelve a E1 (B-22)', () async {
      final api = ApiFalsaDelTest(
        evaluaciones: <Object>[
          const SpecialtyTestFailure(SpecialtyTestFailureKind.server),
        ],
      );
      final b = await _conSesion(api);
      final c = b.controlador..empezarElTest();
      for (final v in respuestasEnOrden) {
        c
          ..responderAlTest(v, conLector: true)
          ..siguiente();
      }
      // El interceptor del 401 borró el token.
      b.token = null;
      await pumpEventQueue();
      expect(b.auth.logouts, 1);
      expect(c.test, isNull);
      expect(b.deUlises, [
        TextosDeLaBienvenida.sesionCaducada,
        TextosDeLaBienvenida.e1,
      ]);
      expect(c.turno.value, TurnoDeLaBienvenida.e1Codigo);
      expect(c.conSesion, isFalse);
    });
  });
}
```

  En `test/bienvenida/bienvenida_atras_test.dart`, suma estos imports y este grupo.

```dart
import '../HU36_jeff/dobles_de_red.dart';
```

```dart
  group('el atrás en el test (RF-BIEN-13)', () {
    test('T0 y el resultado no hacen nada, las preguntas son «Pregunta '
        'anterior»', () async {
      final b = Bienvenida(
        auth: AuthDeLaBienvenida(usuario: alumnaDePrueba(setupComplete: false)),
        token: 'jwt-de-prueba',
        apiDelTest: ApiFalsaDelTest(),
      );
      await b.visitar();
      final c = b.controlador..ulisesAterrizoConSesion();
      await pumpEventQueue();
      c.atras();
      expect(c.turno.value, _T.t0Invitacion);
      expect(c.atrasSaleDeLaApp, isFalse);
      c.empezarElTest();
      c
        ..responderAlTest('top', conLector: true)
        ..siguiente()
        ..atras();
      expect(c.test!.paso.value, 0);
      expect(b.delAlumno.last, 'Pregunta anterior');
    });
  });
```

  En `test/bienvenida/bienvenida_sin_especialidad_test.dart`, suma este grupo.

```dart
  group('hasta el horario (RF-BIEN-21)', () {
    test('la llegada con sesión sigue en T0 y termina en el paso al horario, '
        'nunca en /setup-carrera', () async {
      final b = Bienvenida(
        auth: AuthDeLaBienvenida(usuario: alumnaDePrueba(setupComplete: false)),
        token: 'jwt-de-prueba',
      );
      await b.visitar();
      final c = b.controlador..ulisesAterrizoConSesion();
      await pumpEventQueue();
      expect(c.turno.value, TurnoDeLaBienvenida.t0Invitacion);
      c
        ..saltarElTest()
        ..marcarPrincipal(1);
      await c.terminarLaSeleccion();
      expect(c.turno.value, TurnoDeLaBienvenida.pasoAlHorario);
      expect(b.rutas, isEmpty);
    });
  });
```

- [ ] **Paso 3. Corre las pruebas y confirma que fallan.**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/bienvenida
```

Esperado. Falla la compilación, porque `empezarElTest`, `responderAlTest` y los demás métodos del
test no existen.

- [ ] **Paso 4. Suma el texto.** En `lib/domain/bienvenida/bienvenida_turnos.dart`, dentro de la
  sección «Test» de `TextosDeLaBienvenida`, suma el texto de hoy del diálogo del test y los de los
  botones del resultado, que son los de su spec.

```dart
  static const String empezarDeNuevo = 'Empezar de nuevo';
  static const String elegirComoPrincipal = 'Elegir como principal';
  static const String decidirDespues = 'Decidir después';
  static const String rehacerElTest = 'Rehacer el test';
  static const String siguiente = 'Siguiente';
```

- [ ] **Paso 5. Suma el test al controlador.** En
  `lib/pages/bienvenida/bienvenida_controller.dart`, haz estos cambios.

  1. Los imports.

```dart
import '../../models/specialty_test_models.dart';
import '../specialty_test/specialty_test_logic.dart';
import '../specialty_test/widgets/question_view.dart' show emojisDeLaEscala;
```

  2. El estado nuevo, junto a `enviando`.

```dart
  /// Sube con cada resultado, y la página dibuja el confeti una vez bajo la
  /// franja (RF-BIEN-10).
  final confeti = 0.obs;
  final principalManual = RxnInt();
  final interesesManuales = <int>{}.obs;
  final catalogoFallido = false.obs;

  /// El test pidió empezar de nuevo, y el compositor lo ofrece.
  final pideReinicio = false.obs;

  final List<Worker> _trabajosDelTest = <Worker>[];
  int? _idDeLaCarga;
  FaseDelTest? _faseMostrada;
  int _pasoMostrado = -1;
  bool _volviendo = false;
  bool _saltando = false;
  bool _testDisponible = true;
  String? _botonQueGuarda;
  Completer<void>? _reinicio;
```

  3. `_cerrarTest` pasa a ser este, y `_reiniciar` suma
     `principalManual.value = null; interesesManuales.clear(); catalogoFallido.value = false;`.

```dart
  void _cerrarTest() {
    for (final w in _trabajosDelTest) {
      w.dispose();
    }
    _trabajosDelTest.clear();
    test?.onDelete();
    test = null;
    _idDeLaCarga = null;
    _faseMostrada = null;
    _pasoMostrado = -1;
    pideReinicio.value = false;
    _reinicio?.complete();
    _reinicio = null;
  }
```

  4. `_accionDelAtras` pasa el test disponible.

```dart
  AccionDelAtras get _accionDelAtras => accionDelAtras(
    ultimoTurno.value ?? TurnoB.recibimiento,
    testDisponible: _testDisponible,
  );
```

  5. En `atras()`, las dos acciones del test.

```dart
      case AccionDelAtras.preguntaAnterior:
        preguntaAnterior();
      case AccionDelAtras.irAT0:
        _volverAT0();
```

  6. Reemplaza la sección `// ── Test (Tarea 25)` por esta, y suma la clase `_UiDeLaBienvenida`
     al final del archivo.

```dart
  // ── Test (RF-BIEN-10 y RF-BIEN-21) ───────────────────────────────────────

  /// T0. La bienvenida crea el controlador del test ella misma, sin
  /// Get.put, y pide el contenido una vez (B-34 y enmienda a RF-TEST-2).
  void _empezarElTest({Duration primera = Ritmo.trasLaRespuesta}) {
    _cerrarTest();
    _testDisponible = true;
    ultimoTurno.value = TurnoB.t0Invitacion;
    final t = test = _crearTest(_UiDeLaBienvenida(this));
    _idDeLaCarga = _id();
    entradas.add(
      BurbujaDeUlises(
        id: _idDeLaCarga!,
        texto: '',
        tipo: TipoDeBurbuja.cargando,
        pausa: primera,
      ),
    );
    _trabajosDelTest.addAll(<Worker>[
      ever<EstadoDeCarga>(t.carga, (_) => _alCambiarLaCarga()),
      ever<FaseDelTest>(t.fase, _alCambiarLaFase),
      ever<int>(t.paso, _alCambiarElPaso),
      ever<SpecialtyTestFailure?>(t.errorDeEspera, _alFallarLaEspera),
    ]);
    t.onStart();
    _alCambiarLaCarga();
  }

  void _reemplazarLaCarga(String texto, {TipoDeBurbuja tipo = TipoDeBurbuja.texto}) {
    final id = _idDeLaCarga;
    _idDeLaCarga = null;
    final i = id == null ? -1 : entradas.indexWhere((e) => e.id == id);
    final burbuja = BurbujaDeUlises(
      id: i >= 0 ? id! : _id(),
      texto: texto,
      tipo: tipo,
      pausa: i >= 0 ? entradas[i].pausa : Duration.zero,
    );
    if (i >= 0) {
      entradas[i] = burbuja;
    } else {
      entradas.add(burbuja);
    }
  }

  void _alCambiarLaCarga() {
    final t = test;
    if (t == null || _idDeLaCarga == null) return;
    switch (t.carga.value) {
      case EstadoDeCarga.cargando:
        break;
      case EstadoDeCarga.lista:
        if (t.fase.value != FaseDelTest.bienvenida) return;
        _reemplazarLaCarga(
          TextosB.invitacionAlTest(t.contenido.value!.totalQuestions),
        );
        _faseMostrada = FaseDelTest.bienvenida;
        _pasoMostrado = t.paso.value;
        _abrir(TurnoB.t0Invitacion);
      case EstadoDeCarga.error:
        _reemplazarLaCarga(TextosB.noCargoElTest, tipo: TipoDeBurbuja.error);
        _abrir(TurnoB.t0Invitacion);
        unawaited(_trasUnFalloConSesion());
    }
  }

  void empezarElTest() {
    final t = test;
    if (t == null || turno.value != TurnoB.t0Invitacion) return;
    if (t.carga.value != EstadoDeCarga.lista) return;
    _responder(TextosB.empezarElTest);
    t.empezar();
  }

  void saltarElTest() {
    final t = test;
    if (t == null || turno.value != TurnoB.t0Invitacion) return;
    _responder(TextosB.saltar);
    _saltando = true;
    t.saltar();
    _saltando = false;
  }

  void reintentarElContenido() {
    final t = test;
    if (t == null || t.carga.value != EstadoDeCarga.error) return;
    _responder(TextosB.reintentar);
    _idDeLaCarga = _id();
    entradas.add(
      BurbujaDeUlises(
        id: _idDeLaCarga!,
        texto: '',
        tipo: TipoDeBurbuja.cargando,
        pausa: Ritmo.trasLaRespuesta,
      ),
    );
    t.reintentarCarga();
  }

  /// Con [conLector], la pregunta no avanza sola y espera «Siguiente»
  /// (RF-TEST-5 y RF-TEST-13).
  void responderAlTest(String valor, {bool conLector = false}) {
    if (turno.value != TurnoB.pregunta && turno.value != TurnoB.desempate) {
      return;
    }
    test?.responder(valor, avanceSolo: !conLector);
  }

  void siguiente() => test?.avanzar();

  void preguntaAnterior() {
    final t = test;
    if (t == null) return;
    const conEnlace = <TurnoDeLaBienvenida>{
      TurnoB.pregunta,
      TurnoB.desempate,
      TurnoB.espera,
    };
    if (!conEnlace.contains(ultimoTurno.value)) return;
    _responder(TextosB.preguntaAnterior);
    _volviendo = true;
    t.atras();
  }

  void reintentarLaEvaluacion() {
    final t = test;
    if (t == null || t.errorDeEspera.value == null) return;
    _responder(TextosB.reintentar);
    t.reintentarEvaluacion();
    _decir(<String>[
      ?t.contenido.value?.ulises.loading,
    ], tipo: TipoDeBurbuja.esperando);
  }

  void empezarDeNuevo() {
    if (!pideReinicio.value) return;
    pideReinicio.value = false;
    _responder(TextosB.empezarDeNuevo);
    _volviendo = true;
    _reinicio?.complete();
    _reinicio = null;
  }

  Future<void> elegirComoPrincipal(int especialidad) async {
    _botonQueGuarda = TextosB.elegirComoPrincipal;
    await test?.elegirPrincipal(especialidad);
  }

  Future<void> decidirDespues() async {
    _botonQueGuarda = TextosB.decidirDespues;
    await test?.decidirDespues();
  }

  void rehacerElTest() {
    final t = test;
    if (t == null || t.resultado.value == null) return;
    _responder(TextosB.rehacerElTest);
    _volviendo = true;
    t.rehacer();
  }

  void alternarCorazon(int especialidad) => test?.alternarCorazon(especialidad);

  /// La fase del test cambió. Cada cambio de fase es un turno nuevo, y al
  /// pasar de una pregunta a la espera entra la respuesta a esa pregunta.
  /// Los cambios de paso dentro de una fase que no es la de preguntas, como
  /// el paso 0 de «Rehacer el test» con el resultado todavía a la vista, no
  /// dicen nada.
  void _alCambiarLaFase(FaseDelTest fase) {
    final t = test;
    final c = t?.contenido.value;
    if (t == null || c == null || fase == _faseMostrada) return;
    final venia = _faseMostrada;
    _faseMostrada = fase;
    switch (fase) {
      case FaseDelTest.bienvenida:
        _decir(<String>[TextosB.invitacionAlTest(c.totalQuestions)]);
        _abrir(TurnoB.t0Invitacion);
      case FaseDelTest.pregunta:
        _decirElPaso(t, c, t.paso.value);
      case FaseDelTest.espera:
        if (venia == FaseDelTest.pregunta && !_volviendo) {
          _responder(_textoDeLaRespuesta(t, c, _pasoMostrado));
        }
        final lineas = turnoDeEspera(c, trasDesempate: t.esperaTrasDesempate);
        _decirConSello(lineas.lineas, lineas.sello, ultimaEsperando: true);
        _abrir(TurnoB.espera);
      case FaseDelTest.resultado:
        _decirElResultado(t);
    }
    _volviendo = false;
    _pasoMostrado = t.paso.value;
  }

  /// El paso cambió dentro de las preguntas. Si el alumno avanzó, entra su
  /// respuesta al paso que deja, y Ulises dice el paso nuevo. Con «Pregunta
  /// anterior» no entra ninguna respuesta más.
  void _alCambiarElPaso(int paso) {
    final t = test;
    final c = t?.contenido.value;
    if (t == null || c == null) return;
    if (t.fase.value != FaseDelTest.pregunta ||
        _faseMostrada != FaseDelTest.pregunta ||
        paso == _pasoMostrado) {
      return;
    }
    if (paso > _pasoMostrado && !_volviendo) {
      _responder(_textoDeLaRespuesta(t, c, _pasoMostrado));
    }
    _volviendo = false;
    _pasoMostrado = paso;
    _decirElPaso(t, c, paso);
  }

  /// Ulises dice [lineas], con el sello junto a la primera, que es el
  /// `blockClose` (RF-TEST-4).
  void _decirConSello(
    List<String> lineas,
    SelloDeBloque? sello, {
    bool ultimaEsperando = false,
  }) {
    for (var i = 0; i < lineas.length; i++) {
      final ultima = i == lineas.length - 1;
      entradas.add(
        BurbujaDeUlises(
          id: _id(),
          texto: lineas[i],
          sello: i == 0 ? sello : null,
          tipo: ultima && ultimaEsperando
              ? TipoDeBurbuja.esperando
              : TipoDeBurbuja.texto,
          pausa: i == 0 ? Ritmo.trasLaRespuesta : Ritmo.entreBurbujas,
        ),
      );
    }
  }

  void _decirElPaso(
    SpecialtyTestController t,
    SpecialtyTestContent c,
    int paso,
  ) {
    if (paso < c.totalQuestions) {
      final previo = turnoAntesDePregunta(c, paso, Map<String, String>.of(t.respuestas));
      final q = c.questions[paso];
      _decirConSello(previo.lineas, previo.sello);
      // En una escala, la tarea en negrita y debajo el prompt.
      entradas.add(
        BurbujaDeUlises(
          id: _id(),
          texto: q.prompt,
          titulo: q.isDuel ? null : q.task?.text,
          pausa: previo.lineas.isEmpty
              ? Ritmo.trasLaRespuesta
              : Ritmo.entreBurbujas,
        ),
      );
      _abrir(TurnoB.pregunta);
      return;
    }
    final d = t.desempateActual!;
    final previo = turnoAntesDeDesempate(d);
    _decirConSello(previo.lineas, null);
    entradas.add(
      BurbujaDeUlises(
        id: _id(),
        texto: d.tiebreak.prompt,
        pausa: previo.lineas.isEmpty
            ? Ritmo.trasLaRespuesta
            : Ritmo.entreBurbujas,
      ),
    );
    _abrir(TurnoB.desempate);
  }

  String _textoDeLaRespuesta(
    SpecialtyTestController t,
    SpecialtyTestContent c,
    int paso,
  ) {
    if (paso < 0) return '';
    if (paso < c.totalQuestions) {
      final q = c.questions[paso];
      final valor = t.respuestas[q.id] ?? '';
      if (!q.isDuel) {
        final i = c.scaleOptions.indexWhere((o) => o.id == valor);
        final etiqueta = c.optionLabel(valor) ?? valor;
        return i >= 0 ? '${emojisDeLaEscala[i]} $etiqueta' : etiqueta;
      }
      return textoDeRespuesta(c, tareas: [q.top!, q.bottom!], respuesta: valor);
    }
    final i = paso - c.totalQuestions;
    if (i >= t.desempates.length) return '';
    final d = t.desempates[i];
    return textoDeRespuesta(
      c,
      tareas: [d.tiebreak.top, d.tiebreak.bottom],
      respuesta: d.answer ?? '',
    );
  }

  void _decirElResultado(SpecialtyTestController t) {
    final r = t.resultado.value;
    if (r == null) return;
    confeti.value++;
    _decir(<String>[?r.headline, ?r.tiebreakOutcome]);
    entradas.add(ResultadoDelTest(id: _id(), pausa: Ritmo.entreBurbujas));
    _abrir(TurnoB.resultado);
  }

  void _alFallarLaEspera(SpecialtyTestFailure? fallo) {
    final t = test;
    if (t == null || fallo == null) return;
    _decirError(t.textoDelErrorDeEspera);
    _abrir(TurnoB.espera);
    unawaited(_trasUnFalloConSesion());
  }

  void _volverAT0() {
    final t = test;
    final c = t?.contenido.value;
    if (t == null || c == null || !_testDisponible) return;
    _decir(<String>[TextosB.invitacionAlTest(c.totalQuestions)]);
    _abrir(TurnoB.t0Invitacion);
  }

  // Lo que el controlador del test le pide a la conversación.

  void _aLaSeleccionManual() {
    // Sin el toque de «Saltar», la salida viene de un 404 y el test no está
    // disponible (RF-TEST-1).
    if (!_saltando) {
      _testDisponible = false;
      // La burbuja de carga no llega a su invitación.
      final id = _idDeLaCarga;
      if (id != null) entradas.removeWhere((e) => e.id == id);
      _cerrarTest();
    }
    principalManual.value = _auth.currentUser?.especialidadPrincipal;
    interesesManuales.assignAll(
      _auth.currentUser?.especialidadesInteres ?? const <int>[],
    );
    _decir(<String>[TextosB.eligeMencion]);
    catalogoFallido.value =
        _auth.catalogsFailed || especialidadesOficiales.isEmpty;
    if (catalogoFallido.value) {
      _decirError(TextosB.noCargaronEspecialidades);
    }
    _abrir(TurnoB.seleccionManual);
  }

  void _despedirseDelTest() {
    _responder(_botonQueGuarda ?? TextosB.elegirComoPrincipal);
    _botonQueGuarda = null;
    _decir(<String>[TextosB.listoAlHorario]);
    _abrir(TurnoB.pasoAlHorario);
  }

  void _avisoDelTest(AvisoDelTest aviso) {
    _decirError(aviso.mensaje);
    unawaited(_trasUnFalloConSesion());
  }

  Future<void> _pedirReinicio(String mensaje) {
    _decirError(mensaje);
    pideReinicio.value = true;
    _abrir(TurnoB.espera);
    final reinicio = _reinicio = Completer<void>();
    return reinicio.future;
  }

  // ── Selección manual (RF-TEST-1 y RF-TEST-14) ────────────────────────────

  /// Solo las oficiales de la carrera, en su orden (RF-TEST-14).
  List<Map<String, dynamic>> get especialidadesOficiales {
    final carrera = _auth.currentUser?.careerId;
    if (carrera == null) return const <Map<String, dynamic>>[];
    final oficiales = _auth.officialSpecialtyIds;
    final lista = _auth.especialidades
        .where(
          (e) =>
              e['carrera_id'] == carrera &&
              oficiales.contains(int.tryParse('${e['id']}')),
        )
        .toList();
    lista.sort(
      (a, b) => ((a['display_order'] as num?) ?? 999).compareTo(
        (b['display_order'] as num?) ?? 999,
      ),
    );
    return lista;
  }

  void marcarPrincipal(int especialidad) {
    if (principalManual.value == especialidad) {
      principalManual.value = null;
    } else {
      principalManual.value = especialidad;
      interesesManuales.remove(especialidad);
    }
  }

  void alternarInteres(int especialidad) {
    if (principalManual.value == especialidad) return;
    if (!interesesManuales.remove(especialidad)) {
      interesesManuales.add(especialidad);
    }
  }

  Future<void> terminarLaSeleccion() async {
    if (turno.value != TurnoB.seleccionManual || esperando.value) return;
    final carrera = _auth.currentUser?.careerId;
    if (carrera == null) {
      _decirError(TextosB.sinCarrera);
      return;
    }
    final seleccion = seleccionOficial(
      principal: principalManual.value,
      intereses: interesesManuales,
      oficiales: _auth.officialSpecialtyIds,
    );
    esperando.value = true;
    try {
      await _auth.completeSetup(
        careerId: carrera,
        especialidadPrincipal: seleccion.principal,
        especialidadesInteres: seleccion.intereses,
      );
    } catch (_) {
      esperando.value = false;
      // La spec no fija este texto (decisión 8 del plan).
      _decirError(TextosDelTest.noSeGuardo);
      unawaited(_trasUnFalloConSesion());
      return;
    }
    esperando.value = false;
    _botonQueGuarda = seleccion.principal == null && seleccion.intereses.isEmpty
        ? TextosB.saltarPorAhora
        : TextosB.finalizar;
    _despedirseDelTest();
  }

  Future<void> reintentarElCatalogo() async {
    if (turno.value != TurnoB.seleccionManual) return;
    esperando.value = true;
    final cargo = await _auth.reloadCatalogs();
    esperando.value = false;
    catalogoFallido.value = !cargo || especialidadesOficiales.isEmpty;
    if (catalogoFallido.value) _decirError(TextosB.noCargaronEspecialidades);
  }

  // ── El 401 dentro de la conversación (RF-BIEN-12 y B-22) ─────────────────

  /// En /login el interceptor del 401 borra la sesión y no navega, así que
  /// tras cada fallo de un turno con sesión se mira si el token sigue.
  Future<void> _trasUnFalloConSesion() async {
    if (!_conSesion) return;
    final token = await _tokenGuardado();
    if (token != null && token.isNotEmpty) return;
    // La misma limpieza local que logout, sin red porque no hay token.
    await _auth.logout();
    _reiniciar();
    _decirError(TextosB.sesionCaducada);
    _abrirE1(primera: Ritmo.entreBurbujas);
  }
```

```dart
/// La pantalla del test dentro de la conversación (B-34).
class _UiDeLaBienvenida implements SpecialtyTestUi {
  _UiDeLaBienvenida(this._bienvenida);

  final BienvenidaController _bienvenida;

  @override
  void cerrar([SalidaDelTest? salida]) {
    if (salida == SalidaDelTest.seleccionManual) {
      _bienvenida._aLaSeleccionManual();
    }
  }

  @override
  void irAlHome() => _bienvenida._despedirseDelTest();

  @override
  void avisar(AvisoDelTest aviso) => _bienvenida._avisoDelTest(aviso);

  @override
  Future<void> pedirReinicio(String mensaje) =>
      _bienvenida._pedirReinicio(mensaje);
}
```

  7. En `_trasEntrar`, `ulisesAterrizoConSesion`, `_alCrearLaCuenta` e
     `iniciarSesionDesdeIncierto`, las llamadas a `_empezarElTest()` quedan igual, salvo la de
     `_alCrearLaCuenta`, que pasa a `_empezarElTest(primera: Ritmo.entreBurbujas)`, porque sigue a
     otra burbuja de Ulises.

- [ ] **Paso 6. Corre las pruebas y confirma que pasan.**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/pages/bienvenida lib/domain/bienvenida test/bienvenida
"${FLUTTER:?}" test --no-pub test/bienvenida test/HU36_jeff
"${FLUTTER:?}" analyze --no-pub
```

Esperado. `All tests passed!` y los avisos de la base. Las pruebas de la Tarea 24 que llegan al
test siguen en verde, porque el apoyo registra el service del test sobre la API falsa.

- [ ] **Paso 7. Suite completa y commit.** Corre la suite completa en segundo plano. Esperado,
  `All tests passed!`.

```bash
cd "${REPO:?}"
git status --short
git add lib/pages/bienvenida/bienvenida_controller.dart lib/domain/bienvenida/bienvenida_turnos.dart test/bienvenida
git commit -m "feat(bienvenida): el test de especialidad y la selección manual corren en la conversación hasta el horario, y un 401 vuelve a E1 con la limpieza local (RF-BIEN-10, RF-BIEN-12 y RF-BIEN-21)"
git log -1 --format='%an <%ae>'
```

---

### Tarea 26. La página, la franja, la conversación y el compositor de «Sí, entrar»

**Requisitos.** De RF-BIEN-1, que el primer cuadro sale solo de los argumentos y que la página
no lee el estado de la visita anterior. RF-BIEN-3 en su primer cuadro, RF-BIEN-4 en la franja, el
latido y el pulso, RF-BIEN-5 completo en pantalla, RF-BIEN-6 en el compositor de E1 y E2 con
«Continuar con Google» en Android e iOS y con «El autocompletado» (un solo `AutofillGroup` y el
campo de E1 montado durante E2), la píldora de RF-BIEN-8, el aviso a la capa de RF-SPL-21 y
RF-BIEN-17 completo.

**Archivos.**
- Crear `lib/pages/bienvenida/bienvenida_page.dart`.
- Crear `lib/pages/bienvenida/widgets/revelador.dart`.
- Crear `lib/pages/bienvenida/widgets/burbujas.dart`.
- Crear `lib/pages/bienvenida/widgets/franja_con_sello.dart`.
- Crear `lib/pages/bienvenida/widgets/compositor.dart`.
- Modificar `lib/pages/bienvenida/bienvenida_controller.dart` (`visitaEmpezada`).
- Modificar `test/bienvenida/apoyo_bienvenida.dart` (`montarLaBienvenida`).
- Crear `test/bienvenida/bienvenida_conversacion_test.dart`.
- Crear `test/bienvenida/bienvenida_barra_estado_test.dart`.
- Modificar `test/bienvenida/bienvenida_entrar_test.dart` (grupo `el autocompletado`).
- Modificar `test/bienvenida/bienvenida_ruta_test.dart` (grupo `la página y sus visitas`).

**Interfaces.**
- Consume el controlador de las Tareas 23 a 25, `CabeceraConSello` y `SelloDelLogo` (Tarea 17),
  los tokens (Tarea 20), `UlisesAvatar` y `SelloDeBloqueView` de `ulises_bubble.dart`,
  `SkeletonPulse` de `lib/components/skeleton.dart`, `CapaDeArranque` (Tarea 12) y
  `PortalConsentView` de hoy.
- Produce estas firmas, que usan las Tareas 27 a 31.

```dart
// bienvenida_controller.dart
final RxInt visitaEmpezada;
// bienvenida_page.dart
class BienvenidaPage extends StatefulWidget { const BienvenidaPage(); }
// widgets/revelador.dart
class Revelador extends ChangeNotifier { int get visibles; bool get compositorVisible;
  bool retenido; void actualizar({required List<EntradaDeLaConversacion> entradas,
  required bool hayCompositor, required bool conLector, Duration pausaDelCompositor});
  void mostrarYa(int cuantas); }
// widgets/burbujas.dart
class EntradaView extends StatelessWidget { const EntradaView({required EntradaDeLaConversacion
  entrada, required EntradaDeLaConversacion? anterior, required bool primerGrupo,
  required Widget Function(BuildContext) resultado, bool conMovimiento = true}); }
// widgets/franja_con_sello.dart
class FranjaConSello extends StatelessWidget { const FranjaConSello({required
  ValueListenable<double> latido, required ValueListenable<List<double>?> rombos,
  double radioInferior = 26}); }
class PildoraDelRegistro extends StatelessWidget { const PildoraDelRegistro({required
  EstadoDeLaPildora estado}); }
// widgets/compositor.dart
class MarcoDelCompositor extends StatelessWidget { const MarcoDelCompositor({required Widget child}); }
class CampoDelCompositor, BotonDeEnvio, OjoDeLaContrasena, RespuestasRapidas, BotonPrincipal,
  EnlaceSecundario, ErrorLocal, BotonDeGoogle, RotuloDelCampo;
Widget compositorDelTurno(BuildContext context, BienvenidaController c, TurnoDeLaBienvenida turno);
```

- [ ] **Paso 1. Suma el montaje al apoyo.** En `test/bienvenida/apoyo_bienvenida.dart`, suma estos
  imports y esta función.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/pages/bienvenida/bienvenida_page.dart';
```

```dart
/// Monta /login con la bienvenida real y los controladores de [b], y llega
/// con [argumentos], como la intro o offAllToLogin.
Future<void> montarLaBienvenida(
  WidgetTester tester,
  Bienvenida b, {
  Map<String, Object>? argumentos,
  Brightness brillo = Brightness.light,
  Size pantalla = const Size(375, 667),
  double escala = 1,
  bool conLector = false,
  bool sinMovimiento = false,
}) async {
  tester.view.physicalSize = pantalla * 2;
  tester.view.devicePixelRatio = 2;
  tester.view.display.size = pantalla * 2;
  tester.view.display.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  addTearDown(tester.view.display.reset);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(
        accessibleNavigation: conLector,
        disableAnimations: sinMovimiento,
      );
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  Get.put<LoginController>(b.login, permanent: true);
  Get.put<BienvenidaController>(b.controlador, permanent: true);
  const tema = MaterialTheme(TextTheme());
  await tester.pumpWidget(
    GetMaterialApp(
      theme: brillo == Brightness.light ? tema.light() : tema.dark(),
      home: const SizedBox.shrink(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(escala)),
        child: child!,
      ),
      getPages: [
        GetPage(name: '/login', page: () => const BienvenidaPage()),
        GetPage(name: '/forgot-password', page: () => const Text('olvido')),
        GetPage(name: '/home', page: () => const Text('home')),
      ],
    ),
  );
  Get.offAll<void>(
    () => const BienvenidaPage(),
    routeName: '/login',
    arguments: argumentos,
    transition: Transition.noTransition,
  );
  await tester.pump();
  await tester.pump();
}

/// Avanza [ms] en cuadros de 16 ms.
Future<void> avanzar(WidgetTester tester, int ms) async {
  for (var t = 0; t < ms; t += 16) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}
```

- [ ] **Paso 2. Escribe las pruebas que fallan.** Crea
  `test/bienvenida/bienvenida_conversacion_test.dart`.

```dart
// test/bienvenida/bienvenida_conversacion_test.dart
//
// WIDGET · Bienvenida con Ulises (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-5. La franja con el sello, la conversación y el compositor fijo
// abajo, los grupos de Ulises, las respuestas a la derecha, el ritmo de 850 y
// 500 ms, el compositor de E1 y E2 y el teclado. Llega con un motivo, así que
// empieza directo en E1, sin el recibimiento de la Tarea 28.
// Archivo probado lib/pages/bienvenida/bienvenida_page.dart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/logo/sello_del_logo.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/domain/bienvenida/bienvenida_turnos.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/compositor.dart';
import 'package:ulima_plus/services/session_navigation.dart';

import 'apoyo_bienvenida.dart';

const _expirada = <String, Object>{argumentoDeMotivo: MotivoDeLlegada.expirada};

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  testWidgets('la franja con el sello va arriba, la conversación en medio y '
      'el compositor abajo', (tester) async {
    final b = Bienvenida();
    await montarLaBienvenida(tester, b, argumentos: _expirada);
    await avanzar(tester, 1500);
    final sello = tester.getRect(find.byType(SelloDelLogo));
    final compositor = tester.getRect(find.byType(MarcoDelCompositor));
    expect(sello.top, lessThan(100));
    expect(compositor.bottom, closeTo(667, 0.5));
    expect(find.text(TextosDeLaBienvenida.saludo), findsOneWidget);
    expect(find.text(TextosDeLaBienvenida.e1), findsOneWidget);
  });

  testWidgets('cada burbuja entra 850 ms después de la anterior y el '
      'compositor 500 ms después de la última', (tester) async {
    final b = Bienvenida();
    await montarLaBienvenida(tester, b, argumentos: _expirada);
    // El saludo entra enseguida, E1 850 ms después.
    expect(find.text(TextosDeLaBienvenida.saludo), findsOneWidget);
    expect(find.text(TextosDeLaBienvenida.e1), findsNothing);
    await tester.pump(const Duration(milliseconds: 840));
    expect(find.text(TextosDeLaBienvenida.e1), findsNothing);
    await tester.pump(const Duration(milliseconds: 20));
    expect(find.text(TextosDeLaBienvenida.e1), findsOneWidget);
    expect(find.byType(MarcoDelCompositor), findsNothing);
    await tester.pump(const Duration(milliseconds: 510));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(MarcoDelCompositor), findsOneWidget);
  });

  testWidgets('el primer grupo lleva el nombre «Ulises» y los siguientes no, '
      'y las respuestas van a la derecha con «Tú»', (tester) async {
    final semantica = tester.ensureSemantics();
    final b = Bienvenida();
    await montarLaBienvenida(tester, b, argumentos: _expirada);
    await avanzar(tester, 1500);
    expect(find.text('Ulises'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '20230001');
    await tester.tap(find.byType(BotonDeEnvio));
    await avanzar(tester, 1600);
    final respuesta = tester.getRect(find.text('20230001').last);
    expect(respuesta.right, greaterThan(375 - 40));
    expect(find.bySemanticsLabel('Tú, 20230001'), findsOneWidget);
    expect(find.text('Ulises'), findsOneWidget, reason: 'solo el primer grupo');
    expect(find.text(TextosDeLaBienvenida.e2), findsOneWidget);
    semantica.dispose();
  });

  testWidgets('el botón de envío queda inactivo con el campo vacío', (
    tester,
  ) async {
    final b = Bienvenida();
    await montarLaBienvenida(tester, b, argumentos: _expirada);
    await avanzar(tester, 1500);
    final boton = tester.widget<BotonDeEnvio>(find.byType(BotonDeEnvio));
    expect(boton.alTocar, isNull);
    await tester.enterText(find.byType(TextField).first, 'docente.test');
    await tester.pump();
    expect(
      tester.widget<BotonDeEnvio>(find.byType(BotonDeEnvio)).alTocar,
      isNotNull,
    );
  });

  testWidgets('E2 trae el ojo, «Entrar», «¿Olvidaste tu contraseña?» y «Soy '
      'nuevo»', (tester) async {
    final semantica = tester.ensureSemantics();
    addTearDown(semantica.dispose);
    final b = Bienvenida();
    await montarLaBienvenida(tester, b, argumentos: _expirada);
    await avanzar(tester, 1500);
    await tester.enterText(find.byType(TextField).first, '20230001');
    await tester.tap(find.byType(BotonDeEnvio));
    await avanzar(tester, 2000);
    expect(find.bySemanticsLabel(TextosDeLaBienvenida.mostrarContrasena),
        findsOneWidget);
    expect(find.text(TextosDeLaBienvenida.entrar), findsOneWidget);
    expect(find.text(TextosDeLaBienvenida.olvidaste), findsOneWidget);
    expect(find.text(TextosDeLaBienvenida.soyNuevo), findsOneWidget);
    await tester.tap(find.text(TextosDeLaBienvenida.olvidaste));
    expect(b.rutas, ['/forgot-password']);
  });

  testWidgets('E1 trae «o», «Continuar con Google» y «Soy nuevo»', (tester) async {
    final b = Bienvenida();
    await montarLaBienvenida(tester, b, argumentos: _expirada);
    await avanzar(tester, 1500);
    expect(find.text(TextosDeLaBienvenida.separadorO), findsOneWidget);
    expect(find.byType(BotonDeGoogle), findsOneWidget);
    expect(
      tester.getSize(find.byType(BotonDeGoogle)).height,
      greaterThanOrEqualTo(48),
    );
    expect(find.text(TextosDeLaBienvenida.soyNuevo), findsOneWidget);
  });

  testWidgets('con el teclado abierto la franja queda arriba y el compositor '
      'sobre el teclado', (tester) async {
    final b = Bienvenida();
    await montarLaBienvenida(tester, b, argumentos: _expirada);
    await avanzar(tester, 1500);
    tester.view.viewInsets = const FakeViewPadding(bottom: 600);
    await tester.pump();
    final sello = tester.getRect(find.byType(SelloDelLogo));
    final compositor = tester.getRect(find.byType(MarcoDelCompositor));
    expect(sello.top, lessThan(100));
    expect(compositor.bottom, closeTo(667 - 300, 0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('las burbujas de Ulises van en cardBg y las respuestas en '
      'bienvenidaPropia', (tester) async {
    final b = Bienvenida();
    await montarLaBienvenida(tester, b, argumentos: _expirada);
    await avanzar(tester, 1500);
    final caja = tester.widget<DecoratedBox>(
      find
          .ancestor(
            of: find.text(TextosDeLaBienvenida.saludo),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect(
      (caja.decoration as BoxDecoration).color,
      MaterialTheme.cardBg(Brightness.light),
    );
  });
}
```

  Crea `test/bienvenida/bienvenida_barra_estado_test.dart`.

```dart
// test/bienvenida/bienvenida_barra_estado_test.dart
//
// WIDGET · Bienvenida con Ulises (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-17. La bienvenida declara íconos claros en los dos temas y, en una
// pantalla ancha, la conversación va en una columna de 600 dp centrada.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/pages/bienvenida/bienvenida_page.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/compositor.dart';
import 'package:ulima_plus/services/session_navigation.dart';

import 'apoyo_bienvenida.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  for (final brillo in Brightness.values) {
    testWidgets('íconos claros en ${brillo.name}', (tester) async {
      await montarLaBienvenida(
        tester,
        Bienvenida(),
        brillo: brillo,
        argumentos: const {argumentoDeMotivo: MotivoDeLlegada.expirada},
      );
      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find
            .descendant(
              of: find.byType(BienvenidaPage),
              matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
            )
            .first,
      );
      expect(region.value.statusBarIconBrightness, Brightness.light);
      expect(region.value.statusBarBrightness, Brightness.dark);
    });
  }

  testWidgets('en una pantalla ancha, una columna de 600 dp centrada', (
    tester,
  ) async {
    await montarLaBienvenida(
      tester,
      Bienvenida(),
      pantalla: const Size(1024, 768),
      argumentos: const {argumentoDeMotivo: MotivoDeLlegada.expirada},
    );
    await avanzar(tester, 1500);
    final compositor = tester.getRect(find.byType(MarcoDelCompositor));
    expect(compositor.width, lessThanOrEqualTo(600));
    expect(compositor.center.dx, closeTo(512, 0.5));
  });
}
```

  En `test/bienvenida/bienvenida_entrar_test.dart`, suma estos imports y este grupo, que fija «El
  autocompletado» de RF-BIEN-6 en pantalla. El cierre del contexto antes de vaciar los campos ya
  lo fija el grupo de la Tarea 23.

```dart
import 'package:flutter/material.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/compositor.dart';
import 'package:ulima_plus/services/session_navigation.dart';
```

```dart
  group('el autocompletado (RF-BIEN-6)', () {
    setUp(() {
      Get.testMode = true;
      Get.reset();
    });
    tearDown(Get.reset);

    testWidgets('E1 y E2 van en un mismo AutofillGroup, en E2 el campo del '
        'código sigue montado, invisible y fuera del foco, y la sesión puesta '
        'cierra el contexto con los dos campos escritos', (tester) async {
      final b = Bienvenida();
      await montarLaBienvenida(
        tester,
        b,
        argumentos: const {argumentoDeMotivo: MotivoDeLlegada.expirada},
      );
      await avanzar(tester, 1500);
      final grupo = find.byType(AutofillGroup);
      expect(grupo, findsOneWidget);
      final grupoDeE1 = tester.element(grupo);
      Finder campoDe(TextEditingController c, {bool soloVisibles = true}) =>
          find.descendant(
            of: grupo,
            matching: find.byWidgetPredicate(
              (w) => w is TextField && w.controller == c,
              skipOffstage: soloVisibles,
            ),
            skipOffstage: soloVisibles,
          );
      expect(campoDe(b.login.codeController), findsOneWidget);
      expect(
        tester.widget<TextField>(campoDe(b.login.codeController)).autofillHints,
        [AutofillHints.username],
      );

      await tester.enterText(campoDe(b.login.codeController), '20230001');
      await tester.tap(find.byType(BotonDeEnvio));
      await avanzar(tester, 2000);
      expect(tester.element(grupo), same(grupoDeE1), reason: 'el mismo grupo');
      expect(campoDe(b.login.passwordController), findsOneWidget);
      expect(
        tester.widget<TextField>(campoDe(b.login.passwordController)).autofillHints,
        [AutofillHints.password],
      );
      // El campo del código no se ve, pero sigue montado en el grupo.
      expect(campoDe(b.login.codeController), findsNothing);
      final oculto = campoDe(b.login.codeController, soloVisibles: false);
      expect(oculto, findsOneWidget);
      expect(
        tester.widget<TextField>(oculto).autofillHints,
        [AutofillHints.username],
      );
      final offstage = tester.widget<Offstage>(
        find.ancestor(of: oculto, matching: find.byType(Offstage)).first,
      );
      expect(offstage.offstage, isTrue, reason: 'fuera de la vista y de la semántica');
      expect(
        find.ancestor(of: oculto, matching: find.byType(ExcludeFocus)),
        findsWidgets,
        reason: 'fuera del foco',
      );

      await tester.enterText(
        campoDe(b.login.passwordController),
        'secreta-de-prueba',
      );
      await tester.pump();
      await tester.tap(find.text(TextosDeLaBienvenida.entrar));
      await tester.pump();
      expect(b.autocompletados, [
        (codigo: '20230001', contrasena: 'secreta-de-prueba'),
      ]);
      await avanzar(tester, 3000);
    });
  });
```

  En `test/bienvenida/bienvenida_ruta_test.dart`, suma estos imports y este grupo, que fija en
  pantalla las dos reglas de «Cada montaje es una visita» de RF-BIEN-1. El controlador ya las
  cumple desde la Tarea 23, y aquí se ve que la página tampoco pinta ni toca la visita que no es
  la suya.

```dart
import 'package:ulima_plus/pages/bienvenida/bienvenida_page.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/compositor.dart';
import 'package:ulima_plus/pages/splash/salidas.dart' show naranjaDelSplash;
```

```dart
  group('la página y sus visitas (RF-BIEN-1)', () {
    setUp(() {
      Get.testMode = true;
      Get.reset();
    });
    tearDown(Get.reset);

    testWidgets('tras un cierre de sesión que deja la franja con el sello, el '
        'primer cuadro sale solo de los argumentos y no muestra nada de la '
        'visita anterior', (tester) async {
      final b = Bienvenida();
      await montarLaBienvenida(
        tester,
        b,
        argumentos: const {argumentoDeMotivo: MotivoDeLlegada.expirada},
      );
      await avanzar(tester, 1500);
      expect(find.text(TextosDeLaBienvenida.e1), findsOneWidget);
      // Va al home y cierra sesión, que llega a /login sin argumentos.
      Get.offAllNamed<void>('/home');
      await avanzar(tester, 600);
      expect(offAllToLogin(), isTrue);
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'sin setState en el build');
      final nueva = find.byType(BienvenidaPage).last;
      // El primer cuadro es el naranja del splash con el logo en reposo, y
      // la conversación de la visita anterior no se pinta.
      expect(
        find.descendant(
          of: nueva,
          matching: find.byWidgetPredicate(
            (w) => w is ColoredBox && w.color == naranjaDelSplash,
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: nueva, matching: find.text(TextosDeLaBienvenida.e1)),
        findsNothing,
      );
      expect(
        find.descendant(of: nueva, matching: find.byType(MarcoDelCompositor)),
        findsNothing,
      );
      // Después del primer cuadro, la visita nueva empieza de cero.
      await tester.pump();
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.recibimiento);
      await avanzar(tester, 4000);
    });

    testWidgets('en el restablecimiento conviven dos /login, sin setState '
        'durante el build, y el dispose de la página vieja no toca la visita '
        'nueva', (tester) async {
      final b = Bienvenida();
      await montarLaBienvenida(
        tester,
        b,
        argumentos: const {argumentoDeMotivo: MotivoDeLlegada.expirada},
      );
      await avanzar(tester, 1500);
      // «¿Olvidaste tu contraseña?» abre /forgot-password encima, y el
      // restablecimiento navega a /login con la vieja todavía en la pila.
      Get.toNamed<void>('/forgot-password');
      await avanzar(tester, 600);
      expect(offAllToLogin(motivo: MotivoDeLlegada.restablecida), isTrue);
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'sin setState en el build');
      // La visita nueva empieza en E1 por el motivo, y abre un tramo que el
      // dispose de la vieja cerraría si no estuviera guardado por la visita.
      await tester.pump();
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.e1Codigo);
      b.controlador.soyNuevo();
      expect(b.controlador.registro, isNotNull);
      await avanzar(tester, 1500);
      expect(find.byType(BienvenidaPage, skipOffstage: false), findsOneWidget);
      expect(b.controlador.registro, isNotNull, reason: 'la vieja no la toca');
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.n1Codigo);
      expect(tester.takeException(), isNull);
    });
  });
```

- [ ] **Paso 3. Corre las pruebas y confirma que fallan.**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/bienvenida/bienvenida_conversacion_test.dart test/bienvenida/bienvenida_barra_estado_test.dart test/bienvenida/bienvenida_entrar_test.dart test/bienvenida/bienvenida_ruta_test.dart
```

Esperado. Falla la compilación, porque la página y sus widgets no existen. Sin el grupo en la
página y sin el campo oculto de E2, el grupo `el autocompletado` falla en el `AutofillGroup` y en
el campo del código montado.

- [ ] **Paso 4. Suma la visita atendida al controlador.** En
  `lib/pages/bienvenida/bienvenida_controller.dart`, suma el campo y márcalo al final de cada
  camino de `empezarVisita`, justo antes de cada `return` y al final del método.

```dart
  /// La visita que el controlador ya atiende. La página no lee el estado
  /// mientras su visita no es esta (RF-BIEN-1).
  final visitaEmpezada = 0.obs;
```

```dart
    visitaEmpezada.value = visita;
```

  Suma también el acceso público al login, que usan los compositores.

```dart
  LoginController get login => _login;
```

- [ ] **Paso 5. Escribe el revelador.** Crea `lib/pages/bienvenida/widgets/revelador.dart`.

```dart
// lib/pages/bienvenida/widgets/revelador.dart
// El ritmo de la conversación (RF-BIEN-5). Revela cada entrada después de su
// pausa, y el compositor 500 ms después de la última, o 900 ms antes del
// paso al horario. Con lector de pantalla, las burbujas de un turno entran
// juntas (RF-BIEN-16). Retenido, no revela nada, como mientras corre el
// recibimiento. Las pausas no son movimiento, así que siguen con reducir
// movimiento (RF-BIEN-15).

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../conversacion.dart';

class Revelador extends ChangeNotifier {
  List<EntradaDeLaConversacion> _entradas = const <EntradaDeLaConversacion>[];
  bool _hayCompositor = false;
  bool _conLector = false;
  Duration _pausaDelCompositor = Ritmo.antesDelCompositor;
  int _visibles = 0;
  bool _compositor = false;
  bool _retenido = false;
  Timer? _reloj;

  int get visibles => _visibles;
  bool get compositorVisible => _compositor;
  bool get retenido => _retenido;

  set retenido(bool valor) {
    _retenido = valor;
    _programar();
  }

  void actualizar({
    required List<EntradaDeLaConversacion> entradas,
    required bool hayCompositor,
    required bool conLector,
    Duration pausaDelCompositor = Ritmo.antesDelCompositor,
  }) {
    _entradas = List<EntradaDeLaConversacion>.of(entradas);
    _hayCompositor = hayCompositor;
    _conLector = conLector;
    _pausaDelCompositor = pausaDelCompositor;
    var cambio = false;
    if (_visibles > _entradas.length) {
      _visibles = _entradas.length;
      cambio = true;
    }
    // Una entrada nueva o un turno sin compositor lo cierran.
    if (_compositor && (!hayCompositor || _visibles < _entradas.length)) {
      _compositor = false;
      cambio = true;
    }
    if (cambio) notifyListeners();
    _programar();
  }

  /// Muestra ya las primeras [cuantas], como el primer grupo que la
  /// conversación trae al terminar el recibimiento.
  void mostrarYa(int cuantas) {
    if (cuantas <= _visibles) return;
    _visibles = cuantas.clamp(0, _entradas.length);
    notifyListeners();
    _programar();
  }

  void _programar() {
    _reloj?.cancel();
    if (_retenido) return;
    if (_visibles < _entradas.length) {
      final pausa = _conLector ? Duration.zero : _entradas[_visibles].pausa;
      _reloj = Timer(pausa, () {
        _visibles++;
        notifyListeners();
        _programar();
      });
      return;
    }
    if (_hayCompositor && !_compositor) {
      final pausa = _conLector && _pausaDelCompositor == Ritmo.antesDelCompositor
          ? Duration.zero
          : _pausaDelCompositor;
      _reloj = Timer(pausa, () {
        _compositor = true;
        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }
}
```

  Una pausa de cero también va por un `Timer`, así que la revelación nunca notifica dentro de un
  `build`.

- [ ] **Paso 6. Escribe la franja y la píldora.** Crea
  `lib/pages/bienvenida/widgets/franja_con_sello.dart`.

```dart
// lib/pages/bienvenida/widgets/franja_con_sello.dart
// La franja con el sello (RF-BIEN-4) y la píldora del registro (RF-BIEN-8).

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../components/logo/sello_del_logo.dart';
import '../../../configs/themes.dart';
import '../../../domain/bienvenida/bienvenida_turnos.dart';
import '../bienvenida_controller.dart';

class FranjaConSello extends StatelessWidget {
  const FranjaConSello({
    super.key,
    required this.latido,
    required this.rombos,
    this.radioInferior = 26,
  });

  final ValueListenable<double> latido;
  final ValueListenable<List<double>?> rombos;
  final double radioInferior;

  @override
  Widget build(BuildContext context) => CabeceraConSello(
    color: MaterialTheme.bienvenidaFranja(Theme.brightnessOf(context)),
    radioInferior: radioInferior,
    sello: SelloDelLogo(latido: latido, rombos: rombos),
  );
}

class PildoraDelRegistro extends StatelessWidget {
  const PildoraDelRegistro({super.key, required this.estado});

  final EstadoDeLaPildora estado;

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);
    final creada = estado == EstadoDeLaPildora.creada;
    final texto = creada
        ? TextosDeLaBienvenida.pildoraCreada
        : TextosDeLaBienvenida.pildoraCreando;
    return Semantics(
      liveRegion: true,
      label: texto,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: creada
              ? MaterialTheme.bienvenidaPildoraLista(b)
              : MaterialTheme.bienvenidaPildora(b),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (creada)
                const Icon(LucideIcons.check, size: 14, color: Colors.white)
              else
                const SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                texto,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

  Con reducir movimiento, el indicador de la píldora queda quieto. La Tarea 31 lo cambia por un
  círculo sin animación.

- [ ] **Paso 7. Escribe las burbujas.** Crea `lib/pages/bienvenida/widgets/burbujas.dart`.

```dart
// lib/pages/bienvenida/widgets/burbujas.dart
// Los grupos de Ulises, las respuestas del alumno, la tarjeta del
// consentimiento y los avisos del registro (RF-BIEN-5, RF-BIEN-7 y
// RF-BIEN-16). Cada grupo de Ulises se lee como «Ulises» seguido de sus
// burbujas, y cada respuesta como «Tú, <texto>».

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../components/portal_consent/portal_consent_view.dart';
import '../../../components/skeleton.dart';
import '../../../configs/themes.dart';
import '../../../domain/bienvenida/bienvenida_turnos.dart';
import '../../specialty_test/widgets/question_view.dart' show emojisDeLaEscala;
import '../../specialty_test/widgets/ulises_bubble.dart';
import '../conversacion.dart';

class EntradaView extends StatelessWidget {
  const EntradaView({
    super.key,
    required this.entrada,
    required this.anterior,
    required this.primerGrupo,
    required this.resultado,
    this.conMovimiento = true,
  });

  final EntradaDeLaConversacion entrada;
  final EntradaDeLaConversacion? anterior;

  /// Si es el primer grupo de Ulises, que lleva el avatar de 40 dp y el
  /// nombre.
  final bool primerGrupo;
  final WidgetBuilder resultado;
  final bool conMovimiento;

  @override
  Widget build(BuildContext context) {
    final hijo = switch (entrada) {
      final BurbujaDeUlises u => _BurbujaDeUlises(
        entrada: u,
        primeraDelGrupo: anterior is! BurbujaDeUlises,
        primerGrupo: primerGrupo,
      ),
      final RespuestaDelAlumno r => _Respuesta(entrada: r),
      ResultadoDelTest() => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: resultado(context),
      ),
    };
    return _Entra(conMovimiento: conMovimiento, child: hijo);
  }
}

/// Cada burbuja entra en 340 ms, subiendo 8 dp y de 98 % a 100 % con un
/// leve rebote. Con reducir movimiento, un fundido de 200 ms (RF-BIEN-15).
class _Entra extends StatelessWidget {
  const _Entra({required this.conMovimiento, required this.child});

  final bool conMovimiento;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 0, end: 1),
    duration: Duration(milliseconds: conMovimiento ? 340 : 200),
    curve: conMovimiento ? Curves.easeOutBack : Curves.linear,
    child: child,
    builder: (context, t, hijo) {
      final opacidad = t.clamp(0.0, 1.0);
      if (!conMovimiento) return Opacity(opacity: opacidad, child: hijo);
      return Opacity(
        opacity: opacidad,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - t)),
          child: Transform.scale(scale: 0.98 + 0.02 * t, child: hijo),
        ),
      );
    },
  );
}

class _BurbujaDeUlises extends StatelessWidget {
  const _BurbujaDeUlises({
    required this.entrada,
    required this.primeraDelGrupo,
    required this.primerGrupo,
  });

  final BurbujaDeUlises entrada;
  final bool primeraDelGrupo;
  final bool primerGrupo;

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);
    final avatar = primerGrupo ? 40.0 : 28.0;
    final ancha = entrada.tipo == TipoDeBurbuja.consentimiento;
    return Padding(
      padding: EdgeInsets.only(top: primeraDelGrupo ? 12 : 6),
      child: LayoutBuilder(
        builder: (context, limites) {
          final maximo = limites.maxWidth * (ancha ? 0.92 : 0.74);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: avatar,
                child: primeraDelGrupo
                    ? UlisesAvatar(size: avatar)
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (primeraDelGrupo && primerGrupo)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          TextosDeLaBienvenida.ulises,
                          style: TextStyle(
                            color: MaterialTheme.testMuted(b),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maximo),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: MaterialTheme.cardBg(b),
                          border: Border.all(color: MaterialTheme.testLine(b)),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(primeraDelGrupo ? 6 : 18),
                            topRight: const Radius.circular(18),
                            bottomLeft: const Radius.circular(18),
                            bottomRight: const Radius.circular(18),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          child: _Contenido(entrada: entrada),
                        ),
                      ),
                    ),
                    if (entrada.sello != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: SelloDeBloqueView(sello: entrada.sello!),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.entrada});

  final BurbujaDeUlises entrada;

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);
    final estilo = TextStyle(
      color: MaterialTheme.textPrimary(b),
      fontSize: 14,
      height: 1.35,
    );
    final negrita = estilo.copyWith(fontWeight: FontWeight.w700);
    switch (entrada.tipo) {
      case TipoDeBurbuja.cargando:
        return const SkeletonPulse(child: SkeletonBox(width: 180, height: 14));
      case TipoDeBurbuja.error:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              LucideIcons.circleAlert,
              size: 16,
              color: MaterialTheme.testAccentText(b),
            ),
            const SizedBox(width: 6),
            Flexible(child: Text(entrada.texto, style: estilo)),
          ],
        );
      case TipoDeBurbuja.esperando:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(entrada.texto, style: estilo)),
            const SizedBox(width: 8),
            SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: MaterialTheme.testAccent(b),
              ),
            ),
          ],
        );
      case TipoDeBurbuja.consentimiento:
        // Los textos literales de PortalConsentView (RF-BIEN-7 y RF-REC-6).
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(PortalConsentView.titulo, style: negrita.copyWith(fontSize: 15)),
            const SizedBox(height: 6),
            Text(PortalConsentView.introduccion, style: estilo),
            const SizedBox(height: 4),
            for (final dato in PortalConsentView.datosImportados)
              Text('· $dato', style: estilo),
            const SizedBox(height: 6),
            Text(PortalConsentView.finalidad, style: estilo),
            const SizedBox(height: 6),
            Text(PortalConsentView.contrasena, style: negrita),
          ],
        );
      case TipoDeBurbuja.avisos:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entrada.titulo ?? '', style: negrita),
            for (final l in entrada.lineas) Text('· $l', style: estilo),
          ],
        );
      case TipoDeBurbuja.texto:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entrada.titulo != null) Text(entrada.titulo!, style: negrita),
            Text(entrada.texto, style: estilo),
          ],
        );
    }
  }
}

class _Respuesta extends StatelessWidget {
  const _Respuesta({required this.entrada});

  final RespuestaDelAlumno entrada;

  /// El emoji de la escala queda fuera de la semántica (RF-BIEN-16).
  String get _lectura {
    var texto = entrada.texto;
    for (final e in emojisDeLaEscala) {
      if (texto.startsWith('$e ')) texto = texto.substring(e.length + 1);
    }
    return 'Tú, $texto';
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);
    final tinta = MaterialTheme.bienvenidaPropiaTinta(b);
    final estilo = TextStyle(
      color: tinta,
      fontSize: 14,
      fontWeight: FontWeight.w700,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Align(
        alignment: Alignment.centerRight,
        child: FractionallySizedBox(
          widthFactor: 0.72,
          alignment: Alignment.centerRight,
          child: Align(
            alignment: Alignment.centerRight,
            child: Semantics(
              label: _lectura,
              excludeSemantics: true,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: MaterialTheme.bienvenidaPropia(b),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(6),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (entrada.secreta) ...[
                        Icon(LucideIcons.lock, size: 14, color: tinta),
                        const SizedBox(width: 6),
                      ],
                      if (entrada.conGoogle) ...[
                        SvgPicture.asset(
                          'assets/images/google_logo.svg',
                          width: 16,
                          height: 16,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(child: Text(entrada.texto, style: estilo)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Paso 8. Escribe el compositor.** Crea `lib/pages/bienvenida/widgets/compositor.dart` con
  las piezas y los turnos de «Sí, entrar». La Tarea 27 le suma los demás turnos.

```dart
// lib/pages/bienvenida/widgets/compositor.dart
// El compositor de la conversación y sus piezas (RF-BIEN-5 y RF-BIEN-16).
// Va fijo abajo, sobre el teclado, mide hasta el 60 % del alto disponible y
// desplaza por dentro si su contenido es más alto. Todo control mide al
// menos 48 dp de alto.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../configs/themes.dart';
import '../../../domain/bienvenida/bienvenida_turnos.dart';
import '../bienvenida_controller.dart';

typedef _Textos = TextosDeLaBienvenida;

class MarcoDelCompositor extends StatelessWidget {
  const MarcoDelCompositor({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);
    final mq = MediaQuery.of(context);
    final disponible = mq.size.height - mq.viewInsets.bottom;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: MaterialTheme.cardBg(b),
        border: Border(top: BorderSide(color: MaterialTheme.testLine(b))),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: disponible * 0.6),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            12,
            10,
            12,
            24 + (mq.viewInsets.bottom > 0 ? 0 : mq.padding.bottom),
          ),
          child: child,
        ),
      ),
    );
  }
}

class RotuloDelCampo extends StatelessWidget {
  const RotuloDelCampo(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text(
      texto,
      style: TextStyle(
        color: MaterialTheme.testInk2(Theme.brightnessOf(context)),
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class CampoDelCompositor extends StatelessWidget {
  const CampoDelCompositor({
    super.key,
    required this.controlador,
    required this.pista,
    this.oculto = false,
    this.teclado = TextInputType.text,
    this.accion = TextInputAction.done,
    this.pistasDeAutocompletado,
    this.alEnviar,
    this.sufijo,
    this.autofocus = true,
    this.focusNode,
  });

  final TextEditingController controlador;
  final String pista;
  final bool oculto;
  final TextInputType teclado;
  final TextInputAction accion;
  final Iterable<String>? pistasDeAutocompletado;
  final ValueChanged<String>? alEnviar;
  final Widget? sufijo;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);
    // Con lector de pantalla el campo no toma el foco solo (RF-BIEN-16).
    final lector = MediaQuery.accessibleNavigationOf(context);
    final borde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: TextField(
        controller: controlador,
        focusNode: focusNode,
        autofocus: autofocus && !lector,
        obscureText: oculto,
        keyboardType: teclado,
        textInputAction: accion,
        autofillHints: pistasDeAutocompletado,
        onSubmitted: alEnviar,
        style: TextStyle(color: MaterialTheme.textPrimary(b), fontSize: 15),
        decoration: InputDecoration(
          hintText: pista,
          hintStyle: TextStyle(color: MaterialTheme.testMuted(b), fontSize: 15),
          filled: true,
          fillColor: MaterialTheme.testChipBg(b),
          focusColor: MaterialTheme.cardBg(b),
          suffixIcon: sufijo,
          border: borde,
          enabledBorder: borde,
          focusedBorder: borde.copyWith(
            borderSide: BorderSide(
              color: MaterialTheme.bienvenidaFoco(b),
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class BotonDeEnvio extends StatelessWidget {
  const BotonDeEnvio({super.key, required this.alTocar});

  /// Null mientras el campo está vacío, y el botón queda al 40 %.
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);
    return Semantics(
      button: true,
      enabled: alTocar != null,
      label: _Textos.enviar,
      excludeSemantics: true,
      child: Opacity(
        opacity: alTocar == null ? 0.4 : 1,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: alTocar,
            child: Ink(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    MaterialTheme.testAccentHi(b),
                    MaterialTheme.testAccent(b),
                  ],
                ),
              ),
              child: Icon(
                LucideIcons.arrowUp,
                color: MaterialTheme.testAccentInk(b),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OjoDeLaContrasena extends StatelessWidget {
  const OjoDeLaContrasena({
    super.key,
    required this.visible,
    required this.alTocar,
  });

  final bool visible;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    toggled: visible,
    label: visible ? _Textos.ocultarContrasena : _Textos.mostrarContrasena,
    excludeSemantics: true,
    child: IconButton(
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      onPressed: alTocar,
      icon: Icon(
        visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 20,
        color: MaterialTheme.testMuted(Theme.brightnessOf(context)),
      ),
    ),
  );
}

/// Una respuesta rápida, en píldora. La principal va rellena.
class RespuestaRapida extends StatelessWidget {
  const RespuestaRapida({
    super.key,
    required this.texto,
    required this.alTocar,
    this.principal = false,
    this.esperando = false,
  });

  final String texto;
  final VoidCallback? alTocar;
  final bool principal;
  final bool esperando;

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);
    return Semantics(
      button: true,
      label: texto,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: esperando ? null : alTocar,
          child: Ink(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: principal
                  ? null
                  : Border.all(color: MaterialTheme.testAccent(b), width: 1.5),
              gradient: principal
                  ? LinearGradient(
                      colors: [
                        MaterialTheme.testAccentHi(b),
                        MaterialTheme.testAccent(b),
                      ],
                    )
                  : null,
            ),
            child: Center(
              widthFactor: 1,
              child: esperando
                  ? SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: MaterialTheme.testAccentInk(b),
                      ),
                    )
                  : Text(
                      texto,
                      style: TextStyle(
                        color: principal
                            ? MaterialTheme.testAccentInk(b)
                            : MaterialTheme.testAccentText(b),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class RespuestasRapidas extends StatelessWidget {
  const RespuestasRapidas({super.key, required this.respuestas});

  final List<RespuestaRapida> respuestas;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.end,
    spacing: 8,
    runSpacing: 8,
    children: respuestas,
  );
}

class BotonPrincipal extends StatelessWidget {
  const BotonPrincipal({
    super.key,
    required this.texto,
    required this.alTocar,
    this.esperando = false,
  });

  final String texto;
  final VoidCallback? alTocar;
  final bool esperando;

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);
    final activo = alTocar != null && !esperando;
    return Semantics(
      button: true,
      enabled: activo,
      label: texto,
      excludeSemantics: true,
      child: Opacity(
        opacity: alTocar == null ? 0.4 : 1,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: activo ? alTocar : null,
            child: Ink(
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  colors: [
                    MaterialTheme.testAccentHi(b),
                    MaterialTheme.testAccent(b),
                  ],
                ),
              ),
              child: Center(
                child: esperando
                    ? SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: MaterialTheme.testAccentInk(b),
                        ),
                      )
                    : Text(
                        texto,
                        style: TextStyle(
                          color: MaterialTheme.testAccentInk(b),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EnlaceSecundario extends StatelessWidget {
  const EnlaceSecundario({
    super.key,
    required this.texto,
    required this.alTocar,
    this.apagado = false,
  });

  final String texto;
  final VoidCallback? alTocar;

  /// «¿Olvidaste tu contraseña?» va en testMuted, como en la maqueta.
  final bool apagado;

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);
    return Semantics(
      button: true,
      label: texto,
      excludeSemantics: true,
      child: InkWell(
        onTap: alTocar,
        child: SizedBox(
          height: 48,
          child: Center(
            widthFactor: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                texto,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: apagado
                      ? MaterialTheme.testMuted(b)
                      : MaterialTheme.testAccentText(b),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ErrorLocal extends StatelessWidget {
  const ErrorLocal(this.mensaje, {super.key});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final color = MaterialTheme.testAccentText(Theme.brightnessOf(context));
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Icon(LucideIcons.circleAlert, size: 14, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(mensaje, style: TextStyle(color: color, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

/// «Continuar con Google» en Android e iOS, con el logo oficial y los
/// colores de la marca de Google (RF-BIEN-6).
class BotonDeGoogle extends StatelessWidget {
  const BotonDeGoogle({super.key, required this.alTocar});

  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);
    return Semantics(
      button: true,
      label: _Textos.continuarConGoogle,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: alTocar,
          child: Ink(
            height: 48,
            decoration: BoxDecoration(
              color: MaterialTheme.bienvenidaGoogleFondo(b),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MaterialTheme.bienvenidaGoogleBorde(b)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/images/google_logo.svg',
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  _Textos.continuarConGoogle,
                  style: TextStyle(
                    color: MaterialTheme.bienvenidaGoogleTinta(b),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Un campo con su botón de envío a la derecha.
class _CampoConEnvio extends StatelessWidget {
  const _CampoConEnvio({required this.campo, required this.alEnviar});

  final Widget campo;
  final VoidCallback? alEnviar;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: campo),
      const SizedBox(width: 8),
      BotonDeEnvio(alTocar: alEnviar),
    ],
  );
}

/// El compositor de cada turno. Null en los turnos sin compositor.
Widget? compositorDelTurno(
  BuildContext context,
  BienvenidaController c,
  TurnoDeLaBienvenida turno,
) => switch (turno) {
  TurnoDeLaBienvenida.e1Codigo => _E1(c: c),
  TurnoDeLaBienvenida.e2Contrasena => _E2(c: c),
  _ => null,
};

/// El campo con el texto que el botón de envío escucha.
class _AlEscribir extends StatelessWidget {
  const _AlEscribir({required this.controlador, required this.builder});

  final TextEditingController controlador;
  final Widget Function(BuildContext context, bool vacio) builder;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<TextEditingValue>(
    valueListenable: controlador,
    builder: (context, valor, _) => builder(context, valor.text.trim().isEmpty),
  );
}

class _E1 extends StatelessWidget {
  const _E1({required this.c});

  final BienvenidaController c;

  @override
  Widget build(BuildContext context) {
    final login = c.login;
    final b = Theme.brightnessOf(context);
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const RotuloDelCampo(_Textos.rotuloCodigo),
          _AlEscribir(
            controlador: login.codeController,
            builder: (context, vacio) => _CampoConEnvio(
              campo: CampoDelCompositor(
                controlador: login.codeController,
                pista: _Textos.pistaCodigo,
                accion: TextInputAction.next,
                pistasDeAutocompletado: const [AutofillHints.username],
                alEnviar: (_) => c.enviarCodigo(),
              ),
              alEnviar: vacio || c.esperando.value ? null : c.enviarCodigo,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Divider(color: MaterialTheme.testLine(b))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  _Textos.separadorO,
                  style: TextStyle(color: MaterialTheme.testMuted(b)),
                ),
              ),
              Expanded(child: Divider(color: MaterialTheme.testLine(b))),
            ],
          ),
          const SizedBox(height: 10),
          BotonDeGoogle(
            alTocar: c.esperando.value ? null : c.entrarConGoogle,
          ),
          EnlaceSecundario(texto: _Textos.soyNuevo, alTocar: c.soyNuevo),
        ],
      ),
    );
  }
}

class _E2 extends StatelessWidget {
  const _E2({required this.c});

  final BienvenidaController c;

  @override
  Widget build(BuildContext context) {
    final login = c.login;
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // El campo de E1 sigue montado en el grupo del autocompletado,
          // invisible y fuera de la semántica y del foco, para que el llavero
          // de iOS y el gestor de contraseñas de Google emparejen el usuario
          // con la contraseña (RF-BIEN-6).
          ExcludeFocus(
            child: Offstage(
              child: CampoDelCompositor(
                controlador: login.codeController,
                pista: _Textos.pistaCodigo,
                pistasDeAutocompletado: const [AutofillHints.username],
                autofocus: false,
              ),
            ),
          ),
          const RotuloDelCampo(_Textos.rotuloContrasena),
          CampoDelCompositor(
            controlador: login.passwordController,
            pista: _Textos.pistaContrasena,
            oculto: !login.passwordVisible.value,
            pistasDeAutocompletado: const [AutofillHints.password],
            alEnviar: (_) => c.entrar(),
            sufijo: OjoDeLaContrasena(
              visible: login.passwordVisible.value,
              alTocar: login.passwordVisible.toggle,
            ),
          ),
          const SizedBox(height: 10),
          _AlEscribir(
            controlador: login.passwordController,
            builder: (context, vacio) => BotonPrincipal(
              texto: _Textos.entrar,
              esperando: c.esperando.value,
              alTocar: vacio ? null : c.entrar,
            ),
          ),
          EnlaceSecundario(
            texto: _Textos.olvidaste,
            alTocar: c.abrirOlvido,
            apagado: true,
          ),
          EnlaceSecundario(texto: _Textos.soyNuevo, alTocar: c.soyNuevo),
        ],
      ),
    );
  }
}
```

  El compositor lee el `LoginController` por el getter `login` del controlador de la bienvenida,
  que suma el Paso 4.

- [ ] **Paso 9. Escribe la página.** Crea `lib/pages/bienvenida/bienvenida_page.dart`. La Tarea 28
  le suma el recibimiento, la Tarea 30 el paso al horario y la Tarea 31 lo que falta de
  accesibilidad y movimiento.

```dart
// lib/pages/bienvenida/bienvenida_page.dart
// La página de /login con la bienvenida de Ulises (RF-BIEN-1 a RF-BIEN-17).
// Cada montaje es una visita. El primer cuadro sale solo de los argumentos de
// la ruta, que son la pose del splash, el motivo o ninguno, y avisa a la capa
// del arranque cuando lo pinta (RF-SPL-21). Después pinta el estado del
// controlador, con el ritmo del revelador.

import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../components/logo/escena_del_logo.dart';
import '../../components/logo/estrella_del_logo.dart' show EscenaFija;
import '../../components/logo/pintor_del_logo.dart';
import '../../components/logo/sello_del_logo.dart';
import '../../configs/themes.dart';
import '../../domain/bienvenida/bienvenida_turnos.dart';
import '../../services/session_navigation.dart';
import '../splash/capa_de_arranque.dart';
import '../splash/salidas.dart' show naranjaDelSplash;
import 'bienvenida_controller.dart';
import 'conversacion.dart';
import 'widgets/burbujas.dart';
import 'widgets/compositor.dart';
import 'widgets/franja_con_sello.dart';
import 'widgets/revelador.dart';

class BienvenidaPage extends StatefulWidget {
  const BienvenidaPage({super.key});

  @override
  State<BienvenidaPage> createState() => _BienvenidaPageState();
}

class _BienvenidaPageState extends State<BienvenidaPage>
    with TickerProviderStateMixin {
  late final BienvenidaController _c = Get.find<BienvenidaController>();
  late final int _visita;
  final Revelador _revelador = Revelador();
  final ScrollController _desplazamiento = ScrollController();
  late final AnimationController _latido = AnimationController(
    vsync: this,
    duration: duracionDelLatido,
  );
  final ValueNotifier<List<double>?> _rombos = ValueNotifier<List<double>?>(
    null,
  );
  late final Ticker _pulso = createTicker(_alPulsar);
  final List<Worker> _trabajos = <Worker>[];
  Timer? _finDeLaPildora;
  final ValueNotifier<EstadoDeLaPildora?> _pildora =
      ValueNotifier<EstadoDeLaPildora?>(null);

  bool _leida = false;
  PoseDelLogo? _pose;
  MotivoDeLlegada? _motivo;

  bool get _sinMovimiento => MediaQuery.disableAnimationsOf(context);
  bool get _conLector => MediaQuery.accessibleNavigationOf(context);

  @override
  void initState() {
    super.initState();
    _visita = _c.nuevaVisita();
    _trabajos.addAll(<Worker>[
      ever<int>(_c.latidos, (_) => _latir()),
      ever<bool>(_c.enviando, _alCambiarElEnvio),
      ever<EstadoDeLaPildora?>(_c.pildora, _alCambiarLaPildora),
      ever<List<EntradaDeLaConversacion>>(_c.entradas, (_) => _sincronizar()),
      ever<TurnoDeLaBienvenida?>(_c.turno, (_) => _sincronizar()),
      ever<int>(_c.visitaEmpezada, (_) => _sincronizar()),
    ]);
    _revelador.addListener(_alRevelar);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // El primer cuadro ya se pintó igual al último de la intro.
      CapaDeArranque.avisarPrimerCuadroDeLaBienvenida();
      unawaited(_c.empezarVisita(_visita, motivo: _motivo));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_leida) return;
    _leida = true;
    final argumentos = ModalRoute.of(context)?.settings.arguments;
    if (argumentos is Map) {
      final pose = argumentos[argumentoDePose];
      final motivo = argumentos[argumentoDeMotivo];
      _pose = pose is PoseDelLogo ? pose : null;
      _motivo = motivo is MotivoDeLlegada ? motivo : null;
    }
    // Sin pose, el splash no precargó a Ulises (RF-BIEN-3).
    if (_pose == null) {
      unawaited(
        precacheImage(
          const AssetImage('assets/images/ulises_chatbot.png'),
          context,
        ).catchError((Object _) {}),
      );
    }
  }

  bool get _atendida => _c.visitaEmpezada.value == _visita;

  void _sincronizar() {
    if (!mounted || !_atendida) return;
    final turno = _c.turno.value;
    _revelador.actualizar(
      entradas: _c.entradas,
      hayCompositor: turno != null && _tieneCompositor(turno),
      conLector: _conLector,
      pausaDelCompositor: turno == TurnoDeLaBienvenida.pasoAlHorario
          ? Ritmo.antesDelPaso
          : Ritmo.antesDelCompositor,
    );
  }

  bool _tieneCompositor(TurnoDeLaBienvenida t) =>
      t != TurnoDeLaBienvenida.recibimiento &&
      t != TurnoDeLaBienvenida.llegadaConSesion;

  void _alRevelar() {
    if (!mounted) return;
    setState(() {});
    // La conversación se desplaza en 450 ms hasta el final, o salta con
    // reducir movimiento (RF-BIEN-5 y RF-BIEN-15).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_desplazamiento.hasClients) return;
      final fin = _desplazamiento.position.maxScrollExtent;
      if (_sinMovimiento) {
        _desplazamiento.jumpTo(fin);
      } else {
        unawaited(
          _desplazamiento.animateTo(
            fin,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
          ),
        );
      }
    });
  }

  void _latir() {
    if (!mounted || _sinMovimiento) return;
    unawaited(_latido.forward(from: 0));
  }

  Duration _inicioDelPulso = Duration.zero;
  Duration _ahoraDelPulso = Duration.zero;
  List<double>? _desdeAlApagar;

  void _alCambiarElEnvio(bool enviando) {
    if (!mounted || _sinMovimiento) return;
    _inicioDelPulso = _ahoraDelPulso;
    _desdeAlApagar = enviando ? null : _rombos.value;
    if (!_pulso.isActive) unawaited(_pulso.start());
  }

  /// El pulso recorre los ocho rombos mientras se envía, y con cualquier
  /// desenlace vuelven a la opacidad plena en 200 ms (RF-BIEN-4).
  void _alPulsar(Duration t) {
    _ahoraDelPulso = t;
    final ms = (t - _inicioDelPulso).inMicroseconds / 1000;
    if (_c.enviando.value) {
      final p = posicionDelPulso(ms);
      _rombos.value = <double>[for (var k = 0; k < 8; k++) opacidadDelRombo(k, p)];
      return;
    }
    final desde = _desdeAlApagar;
    final avance = (ms / 200).clamp(0.0, 1.0);
    if (desde == null || avance >= 1) {
      _rombos.value = null;
      _pulso.stop();
      return;
    }
    _rombos.value = <double>[for (final o in desde) o + (1 - o) * avance];
  }

  void _alCambiarLaPildora(EstadoDeLaPildora? estado) {
    _finDeLaPildora?.cancel();
    _pildora.value = estado;
    // «Cuenta creada» se va 900 ms después (RF-BIEN-8).
    if (estado == EstadoDeLaPildora.creada) {
      _finDeLaPildora = Timer(const Duration(milliseconds: 900), () {
        _pildora.value = null;
      });
    }
  }

  @override
  void dispose() {
    for (final w in _trabajos) {
      w.dispose();
    }
    _finDeLaPildora?.cancel();
    _revelador
      ..removeListener(_alRevelar)
      ..dispose();
    _desplazamiento.dispose();
    _latido.dispose();
    _pulso.dispose();
    _rombos.dispose();
    _pildora.dispose();
    _c.terminarVisita(_visita);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Arriba siempre hay #E77330, la franja naranja o la #262626
      // (RF-BIEN-17).
      value: SystemUiOverlayStyle.light,
      child: Obx(
        () => PopScope(
          canPop: _atendida && _c.atrasSaleDeLaApp,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _c.atras();
          },
          child: Scaffold(
            backgroundColor: MaterialTheme.pageBg(b),
            resizeToAvoidBottomInset: true,
            // Un solo grupo del autocompletado para todos los turnos, que
            // vive lo que vive la página, así que E1 y E2 comparten el mismo
            // aunque el compositor cambie. Al salir no guarda nada, porque
            // solo la sesión puesta cierra el contexto con
            // finishAutofillContext (RF-BIEN-6).
            body: AutofillGroup(
              onDisposeAction: AutofillContextAction.cancel,
              child: _cuerpo(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cuerpo(BuildContext context) {
    final atendida = _atendida;
    final turno = atendida ? _c.ultimoTurno.value : null;
    // Antes de que el controlador atienda la visita, el primer cuadro sale
    // solo de los argumentos (RF-BIEN-1).
    final directo = _motivo != null;
    final enElPrimerCuadro =
        !directo &&
        (!atendida ||
            turno == TurnoDeLaBienvenida.recibimiento ||
            turno == TurnoDeLaBienvenida.llegadaConSesion);
    return Stack(
      children: [
        _conversacion(context, atendida: atendida),
        if (enElPrimerCuadro) Positioned.fill(child: _primerCuadro(context)),
        Positioned(
          top: CabeceraConSello.alto(context) + 8,
          left: 0,
          right: 0,
          child: Center(
            child: ValueListenableBuilder<EstadoDeLaPildora?>(
              valueListenable: _pildora,
              builder: (context, estado, _) => estado == null
                  ? const SizedBox.shrink()
                  : PildoraDelRegistro(estado: estado),
            ),
          ),
        ),
      ],
    );
  }

  /// #E77330 de borde a borde y el logo blanco en la pose recibida, o en su
  /// pose de reposo sin pose, en los dos temas (RF-BIEN-2 y RF-BIEN-3).
  Widget _primerCuadro(BuildContext context) {
    final pose = _pose ?? _poseDeReposo(context);
    return ColoredBox(
      color: naranjaDelSplash,
      child: LogoEnEscena(escena: EscenaFija(EscenaDelLogo.desdePose(pose))),
    );
  }

  PoseDelLogo _poseDeReposo(BuildContext context) {
    final vista = MediaQuery.sizeOf(context);
    final pantalla = View.of(context).display;
    // En web la estrella se centra en la vista, porque display.size es el
    // del monitor (RF-BIEN-3).
    final centro = kIsWeb
        ? vista.center(Offset.zero)
        : centroDelNativo(vista, pantalla.size / pantalla.devicePixelRatio);
    return EscenaDelLogo.reposo(centro: centro, radio: radioDelNativo).pose;
  }

  Widget _conversacion(BuildContext context, {required bool atendida}) {
    final visibles = atendida ? _revelador.visibles : 0;
    final entradas = _c.entradas;
    final turno = _c.turno.value;
    final primerIdDeUlises = entradas
        .whereType<BurbujaDeUlises>()
        .map((e) => e.id)
        .firstOrNull;
    return Column(
      children: [
        FranjaConSello(latido: _latido, rombos: _rombos),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView.builder(
                controller: _desplazamiento,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                itemCount: visibles.clamp(0, entradas.length),
                itemBuilder: (context, i) {
                  final entrada = entradas[i];
                  final anterior = i > 0 ? entradas[i - 1] : null;
                  return EntradaView(
                    key: ValueKey<int>(entrada.id),
                    entrada: entrada,
                    anterior: anterior,
                    primerGrupo: _enElPrimerGrupo(entradas, i, primerIdDeUlises),
                    conMovimiento: !_sinMovimiento,
                    resultado: (context) => const SizedBox.shrink(),
                  );
                },
              ),
            ),
          ),
        ),
        if (atendida && turno != null && _revelador.compositorVisible)
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: _CompositorAnimado(
                key: ValueKey<TurnoDeLaBienvenida>(turno),
                conMovimiento: !_sinMovimiento,
                child: compositorDelTurno(context, _c, turno),
              ),
            ),
          ),
      ],
    );
  }

  /// El primer grupo de Ulises es el de las burbujas desde la primera hasta
  /// la primera respuesta del alumno.
  bool _enElPrimerGrupo(
    List<EntradaDeLaConversacion> entradas,
    int i,
    int? primerId,
  ) {
    if (primerId == null) return false;
    for (var j = 0; j <= i; j++) {
      if (entradas[j] is RespuestaDelAlumno) return false;
    }
    return true;
  }
}

/// El compositor entra en 300 ms, subiendo 8 dp, o con un fundido de 200 ms
/// con reducir movimiento (RF-BIEN-5 y RF-BIEN-15).
class _CompositorAnimado extends StatelessWidget {
  const _CompositorAnimado({
    super.key,
    required this.conMovimiento,
    required this.child,
  });

  final bool conMovimiento;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final contenido = child;
    if (contenido == null) return const SizedBox.shrink();
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: conMovimiento ? 300 : 200),
      curve: Curves.easeOutCubic,
      child: MarcoDelCompositor(child: contenido),
      builder: (context, t, hijo) => Opacity(
        opacity: t,
        child: conMovimiento
            ? Transform.translate(offset: Offset(0, 8 * (1 - t)), child: hijo)
            : hijo,
      ),
    );
  }
}
```

- [ ] **Paso 10. Corre las pruebas y confirma que pasan.**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/pages/bienvenida test/bienvenida
"${FLUTTER:?}" test --no-pub test/bienvenida
"${FLUTTER:?}" analyze --no-pub
```

Esperado. `All tests passed!` y los avisos de la base. Si una prueba de tiempos falla por un
cuadro, se revisa que la burbuja cuente su pausa desde que entró la anterior y que el compositor
cuente sus 500 ms desde la última.

- [ ] **Paso 11. Commit.**

```bash
cd "${REPO:?}"
git status --short
git add lib/pages/bienvenida test/bienvenida
git commit -m "feat(bienvenida): la página de la bienvenida con la franja y el sello, la conversación con su ritmo y el compositor de «Sí, entrar» (RF-BIEN-4, RF-BIEN-5, RF-BIEN-6 y RF-BIEN-17)"
git log -1 --format='%an <%ae>'
```

---

### Tarea 27. El compositor del registro, del test y de la selección manual

**Requisitos.** RF-BIEN-7 en su compositor (decisión B-5), el envío de RF-BIEN-8 sin compositor,
RF-BIEN-9 en pantalla (las dos contraseñas nunca a la vez y los enlaces fijos), RF-BIEN-10 en su
compositor y su resultado (decisiones B-13 y B-15), con el confeti bajo la franja.

**Archivos.**
- Modificar `lib/pages/bienvenida/widgets/compositor.dart`.
- Crear `lib/pages/bienvenida/widgets/compositor_del_test.dart`.
- Modificar `lib/pages/bienvenida/bienvenida_page.dart` (el resultado y el confeti).
- Modificar `test/bienvenida/bienvenida_registro_test.dart` (grupo `el compositor del registro`).
- Modificar `test/bienvenida/bienvenida_test_especialidad_test.dart` (grupo `el compositor del
  test`).
- Modificar `test/bienvenida/bienvenida_credenciales_test.dart` (grupo `en pantalla`).

**Interfaces.**
- Consume el controlador de las Tareas 23 a 25, las piezas del test de la Tarea 22,
  `PasswordResetOtpField` y `PasswordResetPalette` de hoy.
- Produce `ResultadoEnLaConversacion`, `CompositorDelTest` y `SeleccionManual` en
  `compositor_del_test.dart`, y los turnos nuevos de `compositorDelTurno`.

- [ ] **Paso 1. Escribe las pruebas que fallan.** En
  `test/bienvenida/bienvenida_registro_test.dart`, suma estos imports y este grupo.

```dart
import 'package:flutter/material.dart';
import 'package:ulima_plus/components/portal_consent/portal_consent_view.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/compositor.dart';
import 'package:ulima_plus/pages/password_reset/password_reset_ui.dart';
import 'package:ulima_plus/services/session_navigation.dart';
```

```dart
  group('el compositor del registro (RF-BIEN-7 y RF-BIEN-9)', () {
    Future<Bienvenida> enN1(WidgetTester tester) async {
      final b = Bienvenida();
      await montarLaBienvenida(
        tester,
        b,
        argumentos: const {argumentoDeMotivo: MotivoDeLlegada.expirada},
      );
      await avanzar(tester, 1500);
      await tester.tap(find.text(TextosDeLaBienvenida.soyNuevo));
      await avanzar(tester, 3000);
      return b;
    }

    Future<void> escribir(WidgetTester tester, int campo, String texto) async {
      await tester.enterText(find.byType(TextField).at(campo), texto);
      await tester.pump();
    }

    testWidgets('N1 pide el código con teclado numérico y trae «Ya tengo '
        'cuenta»', (tester) async {
      await enN1(tester);
      expect(find.text(TextosDeLaBienvenida.rotuloCodigoDeAlumno), findsOneWidget);
      final campo = tester.widget<TextField>(find.byType(TextField));
      expect(campo.keyboardType, TextInputType.number);
      expect(find.text(TextosDeLaBienvenida.yaTengoCuenta), findsOneWidget);
    });

    testWidgets('las dos contraseñas nunca están a la vez en el compositor', (
      tester,
    ) async {
      await enN1(tester);
      await escribir(tester, 0, '20230001');
      await tester.tap(find.byType(BotonDeEnvio));
      await avanzar(tester, 2500);
      expect(find.text(TextosDeLaBienvenida.pistaNueva), findsOneWidget);
      expect(find.text(TextosDeLaBienvenida.pistaPortal), findsNothing);
      await escribir(tester, 0, 'Contrasena1');
      await escribir(tester, 1, 'Contrasena1');
      await tester.tap(find.byType(BotonDeEnvio));
      await avanzar(tester, 3000);
      // N3, la tarjeta del consentimiento con sus textos literales.
      expect(find.text(PortalConsentView.titulo), findsOneWidget);
      expect(find.text(TextosDeLaBienvenida.acepto), findsOneWidget);
      await tester.tap(find.text(TextosDeLaBienvenida.acepto));
      await avanzar(tester, 2500);
      expect(find.text(TextosDeLaBienvenida.pistaPortal), findsOneWidget);
      expect(find.text(TextosDeLaBienvenida.pistaNueva), findsNothing);
      expect(find.text(TextosDeLaBienvenida.yaTengoCuenta), findsOneWidget);
      expect(find.text(TextosDeLaBienvenida.volver), findsOneWidget);
    });

    testWidgets('N5 trae las seis casillas y solo envía con «Crear mi '
        'cuenta» (B-5)', (tester) async {
      final b = await enN1(tester);
      await escribir(tester, 0, '20230001');
      await tester.tap(find.byType(BotonDeEnvio));
      await avanzar(tester, 2500);
      await escribir(tester, 0, 'Contrasena1');
      await escribir(tester, 1, 'Contrasena1');
      await tester.tap(find.byType(BotonDeEnvio));
      await avanzar(tester, 3000);
      await tester.tap(find.text(TextosDeLaBienvenida.acepto));
      await avanzar(tester, 2500);
      await escribir(tester, 0, 'clave-de-prueba');
      await tester.tap(find.byType(BotonDeEnvio));
      await avanzar(tester, 2500);
      expect(find.byType(PasswordResetOtpField), findsOneWidget);
      expect(find.text(TextosDeLaBienvenida.notaAuthenticator), findsOneWidget);
      b.controlador.registro!.passcodeCtrl.text = '123456';
      await tester.pump();
      expect(b.servicioDeRegistro.llamadas, 0, reason: 'no envía solo');
      await tester.tap(find.text(TextosDeLaBienvenida.crearMiCuenta));
      await tester.pump();
      expect(b.servicioDeRegistro.llamadas, 1);
      await avanzar(tester, 4000);
    });
  });
```

  En `test/bienvenida/bienvenida_test_especialidad_test.dart`, suma este grupo.

```dart
  group('el compositor del test (RF-BIEN-10 y B-13)', () {
    /// Entra con la configuración a medias desde E1, así que la
    /// conversación sigue con el test (RF-BIEN-6 y B-10).
    Future<Bienvenida> enT0(WidgetTester tester) async {
      final b = Bienvenida(
        auth: AuthDeLaBienvenida(alEntrar: alumnaDePrueba(setupComplete: false)),
        token: 'jwt-de-prueba',
      );
      await montarLaBienvenida(
        tester,
        b,
        argumentos: const {argumentoDeMotivo: MotivoDeLlegada.expirada},
      );
      await avanzar(tester, 1500);
      await tester.enterText(find.byType(TextField).first, '20230001');
      await tester.tap(find.byType(BotonDeEnvio));
      await avanzar(tester, 2000);
      await tester.enterText(find.byType(TextField).first, 'secreta-de-prueba');
      await tester.tap(find.text(TextosDeLaBienvenida.entrar));
      await avanzar(tester, 3500);
      return b;
    }

    testWidgets('T0 ofrece «Saltar y elegir por mi cuenta» y «Empezar el '
        'test»', (tester) async {
      await enT0(tester);
      expect(find.text(TextosDeLaBienvenida.saltar), findsOneWidget);
      expect(find.text(TextosDeLaBienvenida.empezarElTest), findsOneWidget);
    });

    testWidgets('el duelo va en el compositor con el rótulo, las tarjetas '
        'compactas y las dos opciones de abajo', (tester) async {
      final b = await enT0(tester);
      await tester.tap(find.text(TextosDeLaBienvenida.empezarElTest));
      await avanzar(tester, 3500);
      expect(find.text('Esto o aquello · 1 de 5'), findsOneWidget);
      final duelo = tester.widget<DueloDelTest>(find.byType(DueloDelTest));
      expect(duelo.compacto, isTrue);
      expect(find.text('Me gustan las dos'), findsOneWidget);
      expect(find.text('Ninguna me llama'), findsOneWidget);
      final tarea = b.controlador.test!.preguntaActual!.top!.text;
      await tester.tap(find.byType(TarjetaDeTarea).first);
      await tester.pump(const Duration(milliseconds: 360));
      await avanzar(tester, 300);
      expect(find.text(tarea), findsWidgets, reason: 'la respuesta del alumno');
      expect(find.text(TextosDeLaBienvenida.preguntaAnterior), findsNothing,
          reason: 'la pregunta 2 todavía no entra');
      await avanzar(tester, 3000);
      expect(find.text(TextosDeLaBienvenida.preguntaAnterior), findsOneWidget);
    });

    testWidgets('la selección manual lista las oficiales con «Principal» y '
        '«Me interesa»', (tester) async {
      await enT0(tester);
      await tester.tap(find.text(TextosDeLaBienvenida.saltar));
      await avanzar(tester, 3000);
      expect(find.text('Ingeniería de Software'), findsOneWidget);
      expect(find.text(TextosDeLaBienvenida.principal), findsNWidgets(4));
      expect(find.text(TextosDeLaBienvenida.meInteresa), findsNWidgets(4));
      expect(find.text(TextosDeLaBienvenida.saltarPorAhora), findsOneWidget);
      await tester.tap(find.text(TextosDeLaBienvenida.principal).first);
      await tester.pump();
      expect(find.text(TextosDeLaBienvenida.finalizar), findsOneWidget);
    });
  });
```

  En `test/bienvenida/bienvenida_credenciales_test.dart`, suma este grupo.

```dart
  group('en pantalla (RF-BIEN-9)', () {
    testWidgets('«Soy nuevo» está en E1 y en E2, y «Ya tengo cuenta» en N1',
        (tester) async {
      final b = Bienvenida(
        auth: AuthDeLaBienvenida(errorDeLogin: 'Código o contraseña incorrectos.'),
      );
      await montarLaBienvenida(
        tester,
        b,
        argumentos: const {argumentoDeMotivo: MotivoDeLlegada.expirada},
      );
      await avanzar(tester, 1500);
      expect(find.text(TextosDeLaBienvenida.soyNuevo), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '20230001');
      await tester.tap(find.byType(BotonDeEnvio));
      await avanzar(tester, 2000);
      expect(find.text(TextosDeLaBienvenida.soyNuevo), findsOneWidget);
      // Un login rechazado no ofrece crear una cuenta.
      await tester.enterText(find.byType(TextField).first, 'mala');
      await tester.tap(find.text(TextosDeLaBienvenida.entrar));
      await avanzar(tester, 2000);
      expect(find.textContaining('crear'), findsNothing);
      expect(find.text(TextosDeLaBienvenida.soyNuevo), findsOneWidget);
    });
  });
```

  Suma a los dos últimos archivos los imports de `apoyo_bienvenida.dart`,
  `bienvenida_turnos.dart`, `compositor.dart` y `session_navigation.dart` que falten, y a
  `bienvenida_test_especialidad_test.dart` el de `question_view.dart` (ya está desde la Tarea 22).

- [ ] **Paso 2. Corre las pruebas y confirma que fallan.**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/bienvenida
```

Esperado. Fallan los grupos nuevos, porque `compositorDelTurno` devuelve null en los turnos del
registro y del test.

- [ ] **Paso 3. Suma los turnos del registro.** En `lib/pages/bienvenida/widgets/compositor.dart`,
  suma los imports de `../../password_reset/password_reset_ui.dart` y de
  `compositor_del_test.dart`, reemplaza `compositorDelTurno` por esta versión y suma los turnos.

```dart
Widget? compositorDelTurno(
  BuildContext context,
  BienvenidaController c,
  TurnoDeLaBienvenida turno,
) => switch (turno) {
  TurnoDeLaBienvenida.e1Codigo => _E1(c: c),
  TurnoDeLaBienvenida.e2Contrasena => _E2(c: c),
  TurnoDeLaBienvenida.n1Codigo => _N1(c: c),
  TurnoDeLaBienvenida.n2Contrasena => _N2(c: c),
  TurnoDeLaBienvenida.n3Consentimiento => _N3(c: c),
  TurnoDeLaBienvenida.n4Portal => _N4(c: c),
  TurnoDeLaBienvenida.n5Authenticator => _N5(c: c),
  TurnoDeLaBienvenida.incierto => _Incierto(c: c),
  TurnoDeLaBienvenida.t0Invitacion ||
  TurnoDeLaBienvenida.pregunta ||
  TurnoDeLaBienvenida.desempate ||
  TurnoDeLaBienvenida.espera ||
  TurnoDeLaBienvenida.resultado => CompositorDelTest(c: c, turno: turno),
  TurnoDeLaBienvenida.seleccionManual => SeleccionManual(c: c),
  TurnoDeLaBienvenida.recibimiento ||
  TurnoDeLaBienvenida.llegadaConSesion ||
  TurnoDeLaBienvenida.e3Despedida ||
  TurnoDeLaBienvenida.envio ||
  TurnoDeLaBienvenida.pasoAlHorario => null,
};

/// Los enlaces que el registro deja fijos antes del envío (RF-BIEN-9).
class _EnlacesDelRegistro extends StatelessWidget {
  const _EnlacesDelRegistro({required this.c, this.conVolver = true});

  final BienvenidaController c;
  final bool conVolver;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 8,
    children: [
      if (conVolver) EnlaceSecundario(texto: _Textos.volver, alTocar: c.volver),
      EnlaceSecundario(texto: _Textos.yaTengoCuenta, alTocar: c.yaTengoCuenta),
    ],
  );
}

class _ConError extends StatelessWidget {
  const _ConError({required this.c, required this.children});

  final BienvenidaController c;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Obx(
    () => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...children,
        if (c.errorLocal.value != null) ErrorLocal(c.errorLocal.value!),
      ],
    ),
  );
}

class _N1 extends StatelessWidget {
  const _N1({required this.c});

  final BienvenidaController c;

  @override
  Widget build(BuildContext context) {
    final r = c.registro!;
    return _ConError(
      c: c,
      children: [
        const RotuloDelCampo(_Textos.rotuloCodigoDeAlumno),
        _AlEscribir(
          controlador: r.codigoCtrl,
          builder: (context, vacio) => _CampoConEnvio(
            campo: CampoDelCompositor(
              controlador: r.codigoCtrl,
              pista: _Textos.pistaCodigoDeAlumno,
              teclado: TextInputType.number,
              alEnviar: (_) => c.enviarCodigoDeAlumno(),
            ),
            alEnviar: vacio ? null : c.enviarCodigoDeAlumno,
          ),
        ),
        _EnlacesDelRegistro(c: c, conVolver: false),
      ],
    );
  }
}

class _N2 extends StatelessWidget {
  const _N2({required this.c});

  final BienvenidaController c;

  @override
  Widget build(BuildContext context) {
    final r = c.registro!;
    return Obx(
      () => _ConError(
        c: c,
        children: [
          const RotuloDelCampo(_Textos.rotuloContrasena),
          CampoDelCompositor(
            controlador: r.passwordCtrl,
            pista: _Textos.pistaNueva,
            oculto: !r.passwordVisible.value,
            accion: TextInputAction.next,
            pistasDeAutocompletado: const [AutofillHints.newPassword],
            sufijo: OjoDeLaContrasena(
              visible: r.passwordVisible.value,
              alTocar: r.passwordVisible.toggle,
            ),
          ),
          const SizedBox(height: 10),
          const RotuloDelCampo(_Textos.rotuloRepetir),
          _AlEscribir(
            controlador: r.confirmacionCtrl,
            builder: (context, vacio) => _CampoConEnvio(
              campo: CampoDelCompositor(
                controlador: r.confirmacionCtrl,
                pista: _Textos.pistaRepetir,
                oculto: !r.passwordVisible.value,
                autofocus: false,
                alEnviar: (_) => c.enviarContrasenas(),
              ),
              alEnviar: vacio ? null : c.enviarContrasenas,
            ),
          ),
          _EnlacesDelRegistro(c: c),
        ],
      ),
    );
  }
}

class _N3 extends StatelessWidget {
  const _N3({required this.c});

  final BienvenidaController c;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      RespuestasRapidas(
        respuestas: [
          RespuestaRapida(texto: _Textos.volver, alTocar: c.volver),
          RespuestaRapida(
            texto: _Textos.acepto,
            alTocar: c.aceptarConsentimiento,
            principal: true,
          ),
        ],
      ),
      _EnlacesDelRegistro(c: c, conVolver: false),
    ],
  );
}

class _N4 extends StatelessWidget {
  const _N4({required this.c});

  final BienvenidaController c;

  @override
  Widget build(BuildContext context) {
    final r = c.registro!;
    return Obx(
      () => _ConError(
        c: c,
        children: [
          const RotuloDelCampo(_Textos.rotuloPortal),
          _AlEscribir(
            controlador: r.portalPasswordCtrl,
            builder: (context, vacio) => _CampoConEnvio(
              campo: CampoDelCompositor(
                controlador: r.portalPasswordCtrl,
                pista: _Textos.pistaPortal,
                oculto: !r.portalPasswordVisible.value,
                alEnviar: (_) => c.enviarPortal(),
                sufijo: OjoDeLaContrasena(
                  visible: r.portalPasswordVisible.value,
                  alTocar: r.portalPasswordVisible.toggle,
                ),
              ),
              alEnviar: vacio ? null : c.enviarPortal,
            ),
          ),
          _EnlacesDelRegistro(c: c),
        ],
      ),
    );
  }
}

class _N5 extends StatelessWidget {
  const _N5({required this.c});

  final BienvenidaController c;

  @override
  Widget build(BuildContext context) {
    final r = c.registro!;
    final b = Theme.brightnessOf(context);
    return _ConError(
      c: c,
      children: [
        const RotuloDelCampo(_Textos.rotuloAuthenticator),
        // El campo de seis casillas de hoy (RF-BIEN-7).
        PasswordResetOtpField(
          controller: r.passcodeCtrl,
          palette: PasswordResetPalette.from(context),
        ),
        const SizedBox(height: 6),
        Text(
          _Textos.notaAuthenticator,
          style: TextStyle(color: MaterialTheme.testMuted(b), fontSize: 12),
        ),
        const SizedBox(height: 10),
        _AlEscribir(
          controlador: r.passcodeCtrl,
          builder: (context, vacio) => BotonPrincipal(
            texto: _Textos.crearMiCuenta,
            alTocar: vacio ? null : c.crearCuenta,
          ),
        ),
        _EnlacesDelRegistro(c: c),
      ],
    );
  }
}

class _Incierto extends StatelessWidget {
  const _Incierto({required this.c});

  final BienvenidaController c;

  @override
  Widget build(BuildContext context) => Obx(
    () => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        RespuestasRapidas(
          respuestas: [
            RespuestaRapida(
              texto: _Textos.volverAIntentar,
              alTocar: c.esperando.value ? null : c.volverAIntentarElRegistro,
            ),
            RespuestaRapida(
              texto: _Textos.iniciarSesion,
              principal: true,
              esperando: c.esperando.value,
              alTocar: c.iniciarSesionDesdeIncierto,
            ),
          ],
        ),
        EnlaceSecundario(texto: _Textos.yaTengoCuenta, alTocar: c.yaTengoCuenta),
      ],
    ),
  );
}
```

- [ ] **Paso 4. Escribe el compositor del test.** Crea
  `lib/pages/bienvenida/widgets/compositor_del_test.dart`.

```dart
// lib/pages/bienvenida/widgets/compositor_del_test.dart
// El test de especialidad dentro de la conversación (RF-BIEN-10). T0, el
// duelo y la escala con las tarjetas compactas (B-13), la espera, el
// resultado en la conversación (B-15) y la selección manual (RF-TEST-1 y
// RF-TEST-14). Las piezas son las del test (Tarea 22).

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../configs/themes.dart';
import '../../../domain/bienvenida/bienvenida_turnos.dart';
import '../../../models/specialty_test_models.dart';
import '../../specialty_test/specialty_test_controller.dart';
import '../../specialty_test/widgets/question_view.dart';
import '../../specialty_test/widgets/result_view.dart';
import '../bienvenida_controller.dart';
import 'compositor.dart';

typedef _Textos = TextosDeLaBienvenida;

class CompositorDelTest extends StatelessWidget {
  const CompositorDelTest({super.key, required this.c, required this.turno});

  final BienvenidaController c;
  final TurnoDeLaBienvenida turno;

  @override
  Widget build(BuildContext context) {
    final t = c.test;
    if (t == null) return const SizedBox.shrink();
    // Cada caso lee sus Rx dentro de su propio Obx.
    switch (turno) {
      case TurnoDeLaBienvenida.t0Invitacion:
        return Obx(() {
          final error = t.carga.value == EstadoDeCarga.error;
          return RespuestasRapidas(
            respuestas: [
              RespuestaRapida(texto: _Textos.saltar, alTocar: c.saltarElTest),
              RespuestaRapida(
                texto: error ? _Textos.reintentar : _Textos.empezarElTest,
                principal: true,
                alTocar: error ? c.reintentarElContenido : c.empezarElTest,
              ),
            ],
          );
        });
      case TurnoDeLaBienvenida.pregunta:
      case TurnoDeLaBienvenida.desempate:
        return _Pregunta(c: c, t: t);
      case TurnoDeLaBienvenida.espera:
        return Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (c.pideReinicio.value)
                RespuestaRapida(
                  texto: _Textos.empezarDeNuevo,
                  principal: true,
                  alTocar: c.empezarDeNuevo,
                )
              else if (t.errorDeEspera.value != null)
                RespuestaRapida(
                  texto: _Textos.reintentar,
                  principal: true,
                  alTocar: c.reintentarLaEvaluacion,
                ),
              EnlaceSecundario(
                texto: _Textos.preguntaAnterior,
                alTocar: c.preguntaAnterior,
              ),
            ],
          ),
        );
      case TurnoDeLaBienvenida.resultado:
        return _BotonesDelResultado(c: c, t: t);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _Pregunta extends StatefulWidget {
  const _Pregunta({required this.c, required this.t});

  final BienvenidaController c;
  final SpecialtyTestController t;

  @override
  State<_Pregunta> createState() => _PreguntaState();
}

class _PreguntaState extends State<_Pregunta> {
  final FocusNode _foco = FocusNode(debugLabel: 'escala');

  @override
  void dispose() {
    _foco.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final t = widget.t;
    final b = Theme.brightnessOf(context);
    final lector = MediaQuery.accessibleNavigationOf(context);
    void responder(String valor) => c.responderAlTest(valor, conLector: lector);
    return Obx(() {
      final contenido = t.contenido.value!;
      final paso = t.paso.value;
      final respuesta = t.respuestaActual;
      final total = contenido.totalQuestions;
      final pregunta = t.preguntaActual;
      final desempate = t.desempateActual;
      final rotulo = pregunta == null
          ? 'Desempate ${paso - total + 1}'
          : pregunta.isDuel
          ? _Textos.rotuloDelDuelo(paso + 1, total)
          : _Textos.rotuloDeLaEscala(paso + 1, total);
      final Widget respuestas;
      if (pregunta != null && !pregunta.isDuel) {
        respuestas = EscalaDelTest(
          pregunta: pregunta,
          opciones: contenido.scaleOptions,
          respuesta: respuesta,
          foco: _foco,
          onTap: responder,
        );
      } else {
        final tareas = pregunta != null
            ? <TestTask>[pregunta.top!, pregunta.bottom!]
            : <TestTask>[desempate!.tiebreak.top, desempate.tiebreak.bottom];
        respuestas = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            DueloDelTest(
              tareas: tareas,
              contenido: contenido,
              respuesta: respuesta,
              ayuda: null,
              onTap: responder,
              compacto: true,
            ),
            const SizedBox(height: 8),
            LasDosONinguna(
              contenido: contenido,
              respuesta: respuesta,
              onTap: responder,
            ),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rotulo.toUpperCase(),
            style: TextStyle(
              color: MaterialTheme.testAccentText(b),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          respuestas,
          if (lector && respuesta != null) ...[
            const SizedBox(height: 8),
            BotonPrincipal(texto: _Textos.siguiente, alTocar: c.siguiente),
          ],
          // Desde la pregunta 2 y en los desempates (RF-BIEN-10).
          if (paso > 0)
            EnlaceSecundario(
              texto: _Textos.preguntaAnterior,
              alTocar: c.preguntaAnterior,
            ),
        ],
      );
    });
  }
}

class _BotonesDelResultado extends StatelessWidget {
  const _BotonesDelResultado({required this.c, required this.t});

  final BienvenidaController c;
  final SpecialtyTestController t;

  Future<void> _elegir(BuildContext context) async {
    final r = t.resultado.value;
    if (r == null) return;
    var elegida = r.ranking.first.specialtyId;
    if (r.tie) {
      // Con empate, la hoja del test pregunta cuál (RF-TEST-9).
      final id = await showModalBottomSheet<int>(
        context: context,
        builder: (_) => HojaDelEmpate(ganadoras: r.winners),
      );
      if (id == null) return;
      elegida = id;
    }
    await c.elegirComoPrincipal(elegida);
  }

  @override
  Widget build(BuildContext context) => Obx(() {
    final activos = t.botonesActivos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        BotonPrincipal(
          texto: _Textos.elegirComoPrincipal,
          esperando: t.guardando.value,
          alTocar: activos ? () => _elegir(context) : null,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RespuestaRapida(
                texto: _Textos.decidirDespues,
                alTocar: activos ? c.decidirDespues : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: RespuestaRapida(
                texto: _Textos.rehacerElTest,
                alTocar: activos ? c.rehacerElTest : null,
              ),
            ),
          ],
        ),
      ],
    );
  });
}

TestSpecialty? _porId(SpecialtyTestContent contenido, int id) {
  for (final s in contenido.specialties) {
    if (s.specialtyId == id) return s;
  }
  return null;
}

/// El resultado en la conversación, que desplaza (B-15). Son la tarjeta de
/// la número uno y la de los electivos y «También te puede interesar», con
/// sus corazones.
class ResultadoEnLaConversacion extends StatefulWidget {
  const ResultadoEnLaConversacion({super.key, required this.c});

  final BienvenidaController c;

  @override
  State<ResultadoEnLaConversacion> createState() =>
      _ResultadoEnLaConversacionState();
}

class _ResultadoEnLaConversacionState extends State<ResultadoEnLaConversacion> {
  bool _motivoAbierto = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.c.test;
    final r = t?.resultado.value;
    final contenido = t?.contenido.value;
    if (t == null || r == null || contenido == null) {
      return const SizedBox.shrink();
    }
    final sinMovimiento = MediaQuery.disableAnimationsOf(context);
    final ganadoras = <TestSpecialty>[
      for (final w in r.winners) ?_porId(contenido, w.specialtyId),
    ];
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: sinMovimiento ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 900),
      builder: (context, avance, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TarjetaGanadora(
            resultado: r,
            contenido: contenido,
            avance: avance,
            motivoAbierto: _motivoAbierto,
            onMotivo: () => setState(() => _motivoAbierto = !_motivoAbierto),
          ),
          const SizedBox(height: 10),
          FilaDeElectivos(ganadoras: ganadoras, empate: r.tie),
          const SizedBox(height: 10),
          const EncabezadoDeLasDemas(),
          Obx(
            () => Column(
              children: [
                for (var i = 1; i < r.ranking.length; i++)
                  FilaDelRanking(
                    puesto: i + 1,
                    entrada: r.ranking[i],
                    especialidad: _porId(contenido, r.ranking[i].specialtyId),
                    primera: false,
                    marcada: t.corazones.contains(r.ranking[i].specialtyId),
                    esPrincipal:
                        t.principalActual == r.ranking[i].specialtyId,
                    onCorazon: () =>
                        widget.c.alternarCorazon(r.ranking[i].specialtyId),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// La lista oficial con «Principal» y «Me interesa» y el botón de hoy
/// (RF-TEST-1 y RF-TEST-14).
class SeleccionManual extends StatelessWidget {
  const SeleccionManual({super.key, required this.c});

  final BienvenidaController c;

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);
    return Obx(() {
      if (c.catalogoFallido.value) {
        return RespuestaRapida(
          texto: _Textos.reintentar,
          principal: true,
          esperando: c.esperando.value,
          alTocar: c.reintentarElCatalogo,
        );
      }
      final nada =
          c.principalManual.value == null && c.interesesManuales.isEmpty;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final e in c.especialidadesOficiales)
            _FilaManual(
              nombre: e['name']?.toString() ?? '',
              principal: c.principalManual.value == e['id'],
              interes: c.interesesManuales.contains(e['id']),
              alPrincipal: () => c.marcarPrincipal(e['id'] as int),
              alInteres: () => c.alternarInteres(e['id'] as int),
              brillo: b,
            ),
          const SizedBox(height: 8),
          BotonPrincipal(
            texto: nada ? _Textos.saltarPorAhora : _Textos.finalizar,
            esperando: c.esperando.value,
            alTocar: c.terminarLaSeleccion,
          ),
        ],
      );
    });
  }
}

class _FilaManual extends StatelessWidget {
  const _FilaManual({
    required this.nombre,
    required this.principal,
    required this.interes,
    required this.alPrincipal,
    required this.alInteres,
    required this.brillo,
  });

  final String nombre;
  final bool principal;
  final bool interes;
  final VoidCallback alPrincipal;
  final VoidCallback alInteres;
  final Brightness brillo;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          nombre,
          style: TextStyle(
            color: MaterialTheme.textPrimary(brillo),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            RespuestaRapida(
              texto: _Textos.principal,
              principal: principal,
              alTocar: alPrincipal,
            ),
            RespuestaRapida(
              texto: _Textos.meInteresa,
              principal: interes,
              alTocar: alInteres,
            ),
          ],
        ),
      ],
    ),
  );
}
```

  Los nombres `specialties`, `winners`, `corazones`, `principalActual`, `guardando`,
  `botonesActivos` y los parámetros de las piezas de `result_view.dart` son los de la rama del
  test. Si alguno cambió, se usa el de la rama, sin cambiar lo que dibuja.

- [ ] **Paso 5. Monta el resultado y el confeti en la página.** En
  `lib/pages/bienvenida/bienvenida_page.dart`, el `resultado` de `EntradaView` pasa a
  `(context) => ResultadoEnLaConversacion(c: _c)`, con el import de
  `widgets/compositor_del_test.dart`. Suma un confeti de una vez bajo la franja, que nunca pasa
  sobre el sello, con la háptica del test (RF-TEST-8).

```dart
  late final AnimationController _confeti = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
```

  En `initState`, suma el trabajo, y en `dispose`, `_confeti.dispose();`.

```dart
      ever<int>(_c.confeti, (_) {
        if (!mounted || _sinMovimiento) return;
        unawaited(HapticFeedback.heavyImpact());
        unawaited(_confeti.forward(from: 0));
      }),
```

  En `_cuerpo`, después de `_conversacion`, suma la capa del confeti, recortada bajo la franja.

```dart
        Positioned(
          top: CabeceraConSello.alto(context),
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: ClipRect(
              child: AnimatedBuilder(
                animation: _confeti,
                builder: (context, _) => _confeti.isAnimating
                    ? CustomPaint(painter: PintorDelConfeti(_confeti.value))
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
```

- [ ] **Paso 6. Corre las pruebas y confirma que pasan.**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/pages/bienvenida test/bienvenida
"${FLUTTER:?}" test --no-pub test/bienvenida test/HU36_jeff
"${FLUTTER:?}" analyze --no-pub
```

Esperado. `All tests passed!` y los avisos de la base.

- [ ] **Paso 7. Commit.**

```bash
cd "${REPO:?}"
git status --short
git add lib/pages/bienvenida test/bienvenida
git commit -m "feat(bienvenida): el compositor de cada turno del registro, del test y de la selección manual, con el resultado en la conversación y el confeti bajo la franja (RF-BIEN-7 a RF-BIEN-10)"
git log -1 --format='%an <%ae>'
```

---

### Tarea 28. El recibimiento, el vuelo de Ulises y la subida al sello

**Requisitos.** RF-BIEN-2 completo (decisiones B-2, B-3, B-27 y B-28), el recibimiento corto de
RF-BIEN-3, la subida y el latido al posarse de RF-BIEN-4, y el recibimiento y la subida de
RF-BIEN-21. Reducir movimiento y el lector de pantalla del recibimiento van en la Tarea 31.

**Archivos.**
- Crear `lib/pages/bienvenida/widgets/vuelo_de_ulises.dart`.
- Crear `lib/pages/bienvenida/widgets/recibimiento.dart`.
- Modificar `lib/components/logo/sello_del_logo.dart` (`escalaQueCabe`, `medidasDeLosMas` y
  `PiezasDelSello`).
- Modificar `lib/pages/bienvenida/bienvenida_controller.dart` (el saludo en la conversación).
- Modificar `lib/pages/bienvenida/widgets/compositor.dart` (sus dos respuestas rápidas).
- Modificar `lib/pages/bienvenida/widgets/franja_con_sello.dart` (la clave y la visibilidad del
  sello).
- Modificar `lib/pages/bienvenida/widgets/burbujas.dart` (el avatar y el nombre ocultos hasta que
  Ulises se posa).
- Modificar `lib/pages/bienvenida/bienvenida_page.dart` (el recibimiento en lugar del primer
  cuadro fijo).
- Crear `test/bienvenida/bienvenida_recibimiento_test.dart`.
- Modificar `test/bienvenida/bienvenida_sello_test.dart` (grupo `el latido y el pulso en la
  conversación`).
- Modificar `test/bienvenida/bienvenida_sin_especialidad_test.dart` (grupo `el recibimiento con
  sesión`).

**Interfaces.**
- Consume `medirElRecibimiento`, `MedidasDelRecibimiento` y `puntosDelVuelo` (Tarea 16),
  `SelloDelLogo` y `CabeceraConSello` (Tarea 17), `EscenaDelLogo`, `CruzEnEscena` y
  `pintarEscena` (Tarea 2), `LogoGeometria.largoDeCruz` (Tarea 1), `tramo`, `mezcla`,
  `medioSeno` y `grado` (Tarea 7), `naranjaDelSplash` (Tarea 10), los tokens (Tarea 20), el
  controlador de las Tareas 23 a 25 y la página de las Tareas 26 y 27.
- Produce estas firmas, que usan las Tareas 30 y 31.

```dart
// vuelo_de_ulises.dart
typedef PuntosDelVuelo = ({Offset inicio, Offset control1, Offset control2});
class PoseDeUlises { const PoseDeUlises({required Offset centro, required double lado,
  double giro = 0, double escalaX = 1, double escalaY = 1, double opacidad = 1}); }
double curvaSeno(double t);
PoseDeUlises ulisesEnVuelo(PuntosDelVuelo puntos, Offset aterrizaje, double ms); // 0 a 1300 ms
PoseDeUlises ulisesAlAterrizar(Offset aterrizaje, double ms);      // 480 ms
PoseDeUlises ulisesAsiente(Offset centro, double ms);              // 320 ms
PoseDeUlises ulisesSalta(Offset desde, Offset avatar, double ms);  // 190 + 720 ms
List<({Offset centro, double opacidad})> estelaDelVuelo(PuntosDelVuelo puntos,
  Offset aterrizaje, double ms);
List<({Offset centro, double radio, double opacidad})> particulasDelAterrizaje(
  Offset aterrizaje, double ms);
({Offset centro, double ancho, double opacidad}) sombraDelVuelo(Offset aterrizaje, double avance);
// recibimiento.dart
abstract final class TiemposDelRecibimiento { quieto 160; aterrizaje 1460; finDelRebote 1940;
  botones 2320; inicioDeLaSubida 90; finDeLaSubida 990; inicioDelSalto 120; posado 1030 }
class Recibimiento extends StatefulWidget { const Recibimiento({required PoseDelLogo pose,
  required bool conSesion, required GlobalKey claveDelSello, required Rect avatar,
  required void Function(bool yaUsa) alResponder, required VoidCallback alAterrizarConSesion,
  required VoidCallback alSaludarEnLaConversacion, required VoidCallback alSubir,
  required VoidCallback alPosarseElSello, required VoidCallback alTerminar});
  static const Key claveDelFondo, claveDeUlises, claveDeLaTarjeta, claveDeLosBotones;
  static ({Color fondo, EscenaDelLogo? estrella}) cuadroActual(BuildContext context);
  static ({Offset centro, double radio}) estrellaActual(BuildContext context); }
// sello_del_logo.dart
static TextScaler SelloDelLogo.escalaQueCabe(TextStyle estilo, TextScaler sistema, double ancho);
static ({List<Offset> centros, double largo}) SelloDelLogo.medidasDeLosMas(TextPainter glifos,
  double em);
class PiezasDelSello { Offset estrella; double radio; TextPainter ulima; Offset origenDeUlima;
  List<Offset> mas; double largoDeLosMas;
  static PiezasDelSello? medir(BuildContext context, GlobalKey claveDelSello); }
// bienvenida_controller.dart
final RxBool saludoEnLaConversacion; void saludarEnLaConversacion();
// franja_con_sello.dart y burbujas.dart
FranjaConSello({..., GlobalKey? claveDelSello, bool selloVisible = true});
EntradaView({..., bool ocultarAvatar = false});
```

- [ ] **Paso 1. Escribe las pruebas que fallan.** Crea
  `test/bienvenida/bienvenida_recibimiento_test.dart`. Carga Roboto una vez, porque las medidas
  dependen de la fuente, como `test/HU23_jeff/chats_pestana_test.dart`.

```dart
// test/bienvenida/bienvenida_recibimiento_test.dart
//
// UNITARIA + WIDGET · Bienvenida con Ulises
// (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-2 y RF-BIEN-3. El primer cuadro igual a la pose recibida, el vuelo
// de Ulises, la tarjeta a los 1,94 s y los botones a los 2,32 s, los toques
// ignorados antes, las medidas en 375 × 667 con 1,0, 1,3 y 2,0, «Si no cabe»
// y la subida con el primer grupo. Las medidas usan Roboto, la fuente del
// tema en Android, que sale de FLUTTER_ROOT.
// Archivos probados lib/pages/bienvenida/widgets/recibimiento.dart y
// lib/pages/bienvenida/widgets/vuelo_de_ulises.dart.

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/logo/escena_del_logo.dart';
import 'package:ulima_plus/components/logo/sello_del_logo.dart';
import 'package:ulima_plus/domain/bienvenida/bienvenida_turnos.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/compositor.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/recibimiento.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/vuelo_de_ulises.dart';
import 'package:ulima_plus/services/session_navigation.dart';

import 'apoyo_bienvenida.dart';

/// La pose que deja la intro en 375 × 667.
PoseDelLogo _pose() =>
    EscenaDelLogo.reposo(centro: const Offset(187.5, 333.5), radio: 90).pose;

Map<String, Object> _conPose() => <String, Object>{argumentoDePose: _pose()};

Finder _fondo() => find.byKey(Recibimiento.claveDelFondo);
Finder _ulises() => find.byKey(Recibimiento.claveDeUlises);

/// Carga Roboto del SDK de Flutter con el nombre de familia del tema.
Future<void> _cargarRoboto() async {
  final raiz = Platform.environment['FLUTTER_ROOT'];
  expect(
    raiz,
    isNotNull,
    reason: 'flutter test fija FLUTTER_ROOT; sin él no hay Roboto que medir',
  );
  final archivo = File(
    '$raiz/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
  );
  expect(archivo.existsSync(), isTrue, reason: archivo.path);
  final cargador = FontLoader('Roboto')
    ..addFont(
      Future<ByteData>.value(ByteData.sublistView(archivo.readAsBytesSync())),
    );
  await cargador.load();
}

void main() {
  setUpAll(_cargarRoboto);
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  group('el vuelo, en funciones puras (RF-BIEN-2)', () {
    const aterrizaje = Offset(83.5, 471.5);
    final puntos = puntosDelVuelo(aterrizaje, const Size(375, 667));
    const grados = math.pi / 180;

    test('entra con 62 dp y −26° y llega con 70 dp a su lugar', () {
      final inicio = ulisesEnVuelo(puntos, aterrizaje, 0);
      expect(inicio.centro, puntos.inicio);
      expect(inicio.lado, closeTo(62, 1e-9));
      expect(inicio.giro, closeTo(-26 * grados, 1e-9));
      final fin = ulisesEnVuelo(puntos, aterrizaje, 1300);
      expect(fin.centro.dx, closeTo(83.5, 1e-9));
      expect(fin.centro.dy, closeTo(471.5, 1e-9));
      expect(fin.lado, closeTo(70, 1e-9));
    });

    test('se inclina hasta 14° a mitad del vuelo', () {
      expect(
        ulisesEnVuelo(puntos, aterrizaje, 650).giro,
        closeTo(14 * grados, 1e-9),
      );
    });

    test('la estela nunca pasa de 30 puntos y cada uno se apaga en 560 ms', () {
      for (var ms = 0.0; ms <= 1900; ms += 10) {
        final estela = estelaDelVuelo(puntos, aterrizaje, ms);
        expect(estela.length, lessThanOrEqualTo(30));
        expect(estela.every((p) => p.opacidad > 0 && p.opacidad <= 1), isTrue);
      }
      expect(estelaDelVuelo(puntos, aterrizaje, 1300 + 560), isEmpty);
    });

    test('suelta seis partículas al posarse, que se apagan en 480 ms', () {
      expect(particulasDelAterrizaje(aterrizaje, 0), hasLength(6));
      expect(particulasDelAterrizaje(aterrizaje, 480), isEmpty);
    });

    test('se agacha 190 ms y se posa en su avatar de 40 dp a los 910 ms', () {
      const avatar = Offset(32, 150);
      expect(ulisesSalta(aterrizaje, avatar, 100).escalaY, lessThan(1));
      final posado = ulisesSalta(aterrizaje, avatar, 910);
      expect(posado.centro.dx, closeTo(avatar.dx, 1e-9));
      expect(posado.centro.dy, closeTo(avatar.dy, 1e-9));
      expect(posado.lado, closeTo(40, 1e-9));
    });
  });

  for (final brillo in Brightness.values) {
    testWidgets('el primer cuadro es #E77330 con el logo en la pose recibida, '
        'en ${brillo.name}', (tester) async {
      await montarLaBienvenida(
        tester,
        Bienvenida(),
        argumentos: _conPose(),
        brillo: brillo,
      );
      final cuadro = Recibimiento.cuadroActual(tester.element(_fondo()));
      expect(cuadro.fondo, const Color(0xFFE77330));
      expect(cuadro.estrella!.pose.centro, _pose().centro);
      expect(cuadro.estrella!.pose.radio, 90);
      expect(cuadro.estrella!.cruces, hasLength(2));
    });
  }

  testWidgets('Ulises entra con 62 dp, aterriza con 70 dp junto a la estrella '
      'y la tarjeta aparece a los 1,94 s', (tester) async {
    await montarLaBienvenida(tester, Bienvenida(), argumentos: _conPose());
    await avanzar(tester, 200);
    expect(tester.getSize(_ulises()).width, closeTo(62, 1));
    await avanzar(tester, 1700);
    final ulises = tester.getRect(_ulises());
    expect(ulises.width, closeTo(70, 3));
    expect(ulises.center.dx, closeTo(187.5 - 104, 1));
    expect(ulises.center.dy, closeTo(333.5 + 138, 1));
    expect(find.text(TextosDeLaBienvenida.pregunta), findsNothing);
    await avanzar(tester, 150);
    expect(find.text(TextosDeLaBienvenida.pregunta), findsOneWidget);
  });

  testWidgets('los toques no cuentan hasta que los botones empiezan a entrar, '
      'a los 2,32 s', (tester) async {
    final b = Bienvenida();
    await montarLaBienvenida(tester, b, argumentos: _conPose());
    await avanzar(tester, 2100);
    expect(find.text(TextosDeLaBienvenida.siEntrar), findsNothing);
    await tester.tapAt(const Offset(187.5, 556));
    await tester.pump();
    expect(b.delAlumno, isEmpty);
    await avanzar(tester, 300);
    await tester.tap(find.text(TextosDeLaBienvenida.siEntrar));
    await tester.pump();
    expect(b.delAlumno, [TextosDeLaBienvenida.siEntrar]);
    await avanzar(tester, 3000);
  });

  for (final escala in [1.0, 1.3, 2.0]) {
    testWidgets('en 375 × 667 con el texto a $escala, nada entra en el margen '
        'de la estrella ni queda a menos de 16 dp de los botones', (
      tester,
    ) async {
      await montarLaBienvenida(
        tester,
        Bienvenida(),
        argumentos: _conPose(),
        escala: escala,
      );
      await avanzar(tester, 3000);
      final estrella = Recibimiento.estrellaActual(tester.element(_fondo()));
      final tarjeta = tester.getRect(find.byKey(Recibimiento.claveDeLaTarjeta));
      final botones = tester.getRect(
        find.byKey(Recibimiento.claveDeLosBotones),
      );
      final ulises = tester.getRect(_ulises());
      final margen = estrella.centro.dy + estrella.radio + 12;
      expect(tarjeta.top, greaterThanOrEqualTo(margen - 0.5));
      expect(ulises.top, greaterThanOrEqualTo(margen - 3));
      expect(botones.top - tarjeta.bottom, greaterThanOrEqualTo(16 - 0.5));
      expect(botones.top - ulises.bottom, greaterThanOrEqualTo(16 - 3));
      if (escala == 1.0) {
        expect(estrella.centro.dy, 333.5, reason: 'con 1,0 no se mueve');
        expect(estrella.radio, 90);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('si ni achicando la estrella caben, Ulises saluda ya en la '
      'conversación con las dos respuestas rápidas (B-28)', (tester) async {
    final b = Bienvenida();
    await montarLaBienvenida(
      tester,
      b,
      pantalla: const Size(600, 360),
      escala: 1.3,
    );
    await avanzar(tester, 4500);
    expect(find.byType(Recibimiento), findsNothing);
    expect(find.text(TextosDeLaBienvenida.pregunta), findsOneWidget);
    expect(find.byType(RespuestaRapida), findsNWidgets(2));
    await tester.tap(find.text(TextosDeLaBienvenida.siEntrar));
    await tester.pump();
    expect(
      b.deUlises.where((t) => t == TextosDeLaBienvenida.saludo),
      hasLength(1),
    );
    expect(b.deUlises.last, TextosDeLaBienvenida.e1);
  });

  testWidgets('al responder, el logo sube al sello, la conversación ya trae '
      'el primer grupo y E1 entra 650 ms después de que Ulises se posa', (
    tester,
  ) async {
    await montarLaBienvenida(tester, Bienvenida(), argumentos: _conPose());
    await avanzar(tester, 2800);
    await tester.tap(find.text(TextosDeLaBienvenida.siEntrar));
    await avanzar(tester, 1100);
    expect(find.byType(Recibimiento), findsNothing);
    expect(find.byType(SelloDelLogo), findsOneWidget);
    expect(find.text(TextosDeLaBienvenida.saludo), findsOneWidget);
    expect(find.text(TextosDeLaBienvenida.pregunta), findsOneWidget);
    expect(find.text(TextosDeLaBienvenida.ulises), findsOneWidget);
    expect(find.text(TextosDeLaBienvenida.e1), findsNothing);
    await avanzar(tester, 700);
    expect(find.text(TextosDeLaBienvenida.e1), findsOneWidget);
  });

  testWidgets('sin argumentos, el recibimiento corto arranca con el logo en su '
      'pose de reposo en el centro de la pantalla física (RF-BIEN-3)', (
    tester,
  ) async {
    await montarLaBienvenida(tester, Bienvenida());
    final cuadro = Recibimiento.cuadroActual(tester.element(_fondo()));
    expect(cuadro.fondo, const Color(0xFFE77330));
    expect(cuadro.estrella!.pose.centro, const Offset(187.5, 333.5));
    expect(cuadro.estrella!.pose.radio, 90);
    expect(cuadro.estrella!.cruces, hasLength(2));
  });

  testWidgets('con un motivo no hay recibimiento y el sello está entero desde '
      'el primer cuadro', (tester) async {
    await montarLaBienvenida(
      tester,
      Bienvenida(),
      argumentos: const {argumentoDeMotivo: MotivoDeLlegada.restablecida},
    );
    expect(find.byType(Recibimiento), findsNothing);
    expect(find.byType(SelloDelLogo), findsOneWidget);
    await avanzar(tester, 1500);
    expect(find.byType(BotonDeEnvio), findsOneWidget);
  });
}
```

  En `test/bienvenida/bienvenida_sello_test.dart`, suma estos imports y este grupo al final de
  `main()`.

```dart
import 'dart:async';

import 'package:ulima_plus/models/registro_models.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/compositor.dart';
import 'package:ulima_plus/services/session_navigation.dart';

import 'apoyo_bienvenida.dart';
```

```dart
  group('el latido y el pulso en la conversación (RF-BIEN-4)', () {
    const expirada = <String, Object>{
      argumentoDeMotivo: MotivoDeLlegada.expirada,
    };

    setUp(() {
      Get.testMode = true;
      Get.reset();
    });
    tearDown(Get.reset);

    testWidgets('el sello late 380 ms con cada respuesta', (tester) async {
      await montarLaBienvenida(tester, Bienvenida(), argumentos: expirada);
      await avanzar(tester, 1500);
      final sello = tester.widget<SelloDelLogo>(find.byType(SelloDelLogo));
      expect(sello.latido!.value, 0);
      await tester.enterText(find.byType(TextField).first, '20230001');
      await tester.tap(find.byType(BotonDeEnvio));
      await tester.pump(const Duration(milliseconds: 80));
      expect(sello.latido!.value, inExclusiveRange(0, 1));
      await avanzar(tester, 400);
      expect(sello.latido!.value, 1);
      await avanzar(tester, 2000);
    });

    testWidgets('el pulso recorre los rombos solo durante el envío y vuelven a '
        'la opacidad plena en 200 ms', (tester) async {
      final pendiente = Completer<RegistroResult>();
      final b = Bienvenida(registro: RegistroFalso(pendiente: pendiente));
      await montarLaBienvenida(tester, b, argumentos: expirada);
      await avanzar(tester, 1500);
      final c = b.controlador..soyNuevo();
      c.registro!.codigoCtrl.text = '20230001';
      c.enviarCodigoDeAlumno();
      c.registro!
        ..passwordCtrl.text = 'Contrasena1'
        ..confirmacionCtrl.text = 'Contrasena1';
      c.enviarContrasenas();
      c.aceptarConsentimiento();
      c.registro!.portalPasswordCtrl.text = 'clave-de-prueba';
      c.enviarPortal();
      c.registro!.passcodeCtrl.text = '123456';
      final sello = tester.widget<SelloDelLogo>(find.byType(SelloDelLogo));
      expect(sello.rombos!.value, isNull);
      unawaited(c.crearCuenta());
      await avanzar(tester, 300);
      final rombos = sello.rombos!.value!;
      expect(rombos, hasLength(8));
      expect(rombos.every((o) => o >= 0.42 - 1e-9 && o <= 1 + 1e-9), isTrue);
      expect(rombos.any((o) => o < 0.9), isTrue);
      pendiente.completeError(
        const RegistroFailure(
          'No hay conexión. Revisa tu internet e inténtalo de nuevo.',
          code: 'SIN_CONEXION',
        ),
      );
      await avanzar(tester, 250);
      expect(sello.rombos!.value, isNull);
      await avanzar(tester, 3000);
    });
  });
```

  En `test/bienvenida/bienvenida_sin_especialidad_test.dart`, suma este grupo. Sin argumentos,
  la alumna ve el recibimiento corto, que sigue igual que con la pose desde «Quieto».

```dart
  group('el recibimiento con sesión (RF-BIEN-21)', () {
    setUp(() {
      Get.testMode = true;
      Get.reset();
    });

    testWidgets('sin la tarjeta ni los botones, con el primer grupo al subir '
        'y T0 a los 3,62 s del relevo', (tester) async {
      final b = Bienvenida(
        auth: AuthDeLaBienvenida(usuario: alumnaDePrueba(setupComplete: false)),
        token: 'jwt-de-prueba',
      );
      await montarLaBienvenida(tester, b);
      await avanzar(tester, 2400);
      expect(find.text(TextosDeLaBienvenida.pregunta), findsNothing);
      expect(find.text(TextosDeLaBienvenida.siEntrar), findsNothing);
      await avanzar(tester, 800);
      expect(find.text(TextosDeLaBienvenida.saludoConSesion), findsOneWidget);
      expect(find.text(TextosDeLaBienvenida.faltaEspecialidad), findsOneWidget);
      expect(b.delAlumno, isEmpty);
      await avanzar(tester, 1500);
      expect(
        find.text(TextosDeLaBienvenida.invitacionAlTest(5)),
        findsOneWidget,
      );
      await avanzar(tester, 2000);
    });
  });
```

- [ ] **Paso 2. Corre las pruebas y confirma que fallan.**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/bienvenida
```

Esperado. Falla la compilación, porque `recibimiento.dart` y `vuelo_de_ulises.dart` no existen.

- [ ] **Paso 3. Escribe el vuelo.** Crea `lib/pages/bienvenida/widgets/vuelo_de_ulises.dart`.

```dart
// lib/pages/bienvenida/widgets/vuelo_de_ulises.dart
// Dónde va Ulises en cada instante del recibimiento (RF-BIEN-2). El vuelo de
// 1300 ms con la curva seno sobre la Bézier de puntosDelVuelo, la estela, el
// rebote del aterrizaje con sus seis partículas, la sombra, el asentimiento y
// el salto a su avatar. Funciones puras del instante, en dp de la vista.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../splash/variantes/variante_de_intro.dart'
    show grado, medioSeno, mezcla, tramo;

typedef PuntosDelVuelo = ({Offset inicio, Offset control1, Offset control2});

class PoseDeUlises {
  const PoseDeUlises({
    required this.centro,
    required this.lado,
    this.giro = 0,
    this.escalaX = 1,
    this.escalaY = 1,
    this.opacidad = 1,
  });

  final Offset centro;
  final double lado;
  final double giro;
  final double escalaX;
  final double escalaY;
  final double opacidad;
}

/// La curva seno de la maqueta, de 0 a 1.
double curvaSeno(double t) =>
    0.5 - 0.5 * math.cos(math.pi * t.clamp(0.0, 1.0));

Offset _cubica(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
  final s = 1 - t;
  return p0 * (s * s * s) +
      p1 * (3 * s * s * t) +
      p2 * (3 * s * t * t) +
      p3 * (t * t * t);
}

/// Entra con 62 dp y −26°, se inclina hasta 14° a mitad del vuelo, se
/// comprime cinco veces como un aleteo y llega con 70 dp.
PoseDeUlises ulisesEnVuelo(
  PuntosDelVuelo puntos,
  Offset aterrizaje,
  double ms,
) {
  final t = tramo(ms, 0, 1300);
  final e = curvaSeno(t);
  final medio = medioSeno(t);
  return PoseDeUlises(
    centro: _cubica(
      puntos.inicio,
      puntos.control1,
      puntos.control2,
      aterrizaje,
      e,
    ),
    lado: mezcla(62, 70, e),
    giro: -26 * grado * (1 - e) * (1 - medio) + 14 * grado * medio,
    escalaY: 1 - 0.1 * math.sin(5 * math.pi * t).abs(),
  );
}

/// El rebote de 480 ms, que lo aplasta contra el suelo y lo estira antes de
/// asentarse.
PoseDeUlises ulisesAlAterrizar(Offset aterrizaje, double ms) {
  final t = tramo(ms, 0, 480);
  final onda = math.sin(3 * math.pi * t) * (1 - t);
  return PoseDeUlises(
    centro: aterrizaje,
    lado: 70,
    escalaX: 1 + 0.15 * onda,
    escalaY: 1 - 0.15 * onda,
  );
}

/// El asentimiento de 320 ms, con −6° y un 6 % más de escala.
PoseDeUlises ulisesAsiente(Offset centro, double ms) {
  final s = medioSeno(tramo(ms, 0, 320));
  return PoseDeUlises(
    centro: centro,
    lado: 70,
    giro: -6 * grado * s,
    escalaX: 1 + 0.06 * s,
    escalaY: 1 + 0.06 * s,
  );
}

/// Se agacha en 190 ms y salta en 720 ms hasta su avatar de 40 dp, en un arco
/// con los controles 144 dp sobre su lugar y 132 dp sobre el avatar, y se
/// posa con el rebote al 60 %.
PoseDeUlises ulisesSalta(Offset desde, Offset avatar, double ms) {
  if (ms < 190) {
    final s = medioSeno(tramo(ms, 0, 190));
    return PoseDeUlises(
      centro: desde,
      lado: 70,
      escalaX: 1 + 0.08 * s,
      escalaY: 1 - 0.12 * s,
    );
  }
  final t = Curves.easeInOutCubic.transform(tramo(ms, 190, 910));
  final rebote = t > 0.6 ? 1 + 0.08 * medioSeno(tramo(t, 0.6, 1)) : 1.0;
  return PoseDeUlises(
    centro: _cubica(
      desde,
      desde - const Offset(0, 144),
      avatar - const Offset(0, 132),
      avatar,
      t,
    ),
    lado: mezcla(70, 40, t) * rebote,
  );
}

/// La estela, en ms desde que empieza el vuelo. Un punto blanco de 7 dp cada
/// 1300 / 30 ms, que se apaga en 560 ms, así que nunca pasan de 30.
List<({Offset centro, double opacidad})> estelaDelVuelo(
  PuntosDelVuelo puntos,
  Offset aterrizaje,
  double ms,
) {
  const paso = 1300 / 30;
  return <({Offset centro, double opacidad})>[
    for (var i = 0; i < 30; i++)
      if (ms >= i * paso && ms - i * paso < 560)
        (
          centro: ulisesEnVuelo(puntos, aterrizaje, i * paso).centro,
          opacidad: 1 - (ms - i * paso) / 560,
        ),
  ];
}

/// Las seis partículas del aterrizaje, en ms desde que Ulises toca el suelo.
/// Salen de sus pies en abanico hacia arriba, hasta 30 dp, y se apagan en
/// 480 ms.
List<({Offset centro, double radio, double opacidad})> particulasDelAterrizaje(
  Offset aterrizaje,
  double ms,
) {
  if (ms < 0 || ms >= 480) {
    return const <({Offset centro, double radio, double opacidad})>[];
  }
  final t = ms / 480;
  final pies = aterrizaje + const Offset(0, 35);
  final alcance = 30 * Curves.easeOutCubic.transform(t);
  return <({Offset centro, double radio, double opacidad})>[
    for (var k = 0; k < 6; k++)
      (
        centro: pies + Offset.fromDirection(math.pi + k * math.pi / 5, alcance),
        radio: 3 * (1 - 0.5 * t),
        opacidad: 1 - t,
      ),
  ];
}

/// La sombra de Ulises en el suelo, que crece al acercarse. [avance] va de 0
/// al empezar el vuelo a 1 al aterrizar.
({Offset centro, double ancho, double opacidad}) sombraDelVuelo(
  Offset aterrizaje,
  double avance,
) => (
  centro: aterrizaje + const Offset(0, 40),
  ancho: mezcla(18, 56, avance),
  opacidad: 0.2 * avance,
);
```

- [ ] **Paso 4. Haz públicas las medidas del sello.** En `lib/components/logo/sello_del_logo.dart`,
  renombra `_escalaQueCabe` a `escalaQueCabe`, en su declaración y en `build`, sin tocar su
  cuerpo, y cambia su comentario por este.

```dart
  /// La escala del sistema o, si el sello no cabe en [ancho], la mayor con la
  /// que cabe (RF-BIEN-20). La subida de la bienvenida mide con ella.
```

  Suma `medidasDeLosMas` después de `escalaQueCabe`.

```dart
  /// Los centros de los «++» dentro de la caja de sus [glifos] y su largo,
  /// con [em] el tamaño de la letra ya escalado. Los usan el sello y la
  /// subida de la bienvenida, así que el destino de la subida coincide con el
  /// sello.
  static ({List<Offset> centros, double largo}) medidasDeLosMas(
    TextPainter glifos,
    double em,
  ) {
    final base = glifos.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    final y = base - 0.34 * em;
    return (
      centros: <Offset>[
        for (var i = 0; i < 2; i++) Offset(glifos.width * (0.25 + 0.5 * i), y),
      ],
      largo: 0.5 * em,
    );
  }
```

  Y el `paint` de `_PintorDeLosMas` pasa a usarla.

```dart
  @override
  void paint(Canvas canvas, Size size) {
    final mas = SelloDelLogo.medidasDeLosMas(
      glifos,
      escala.scale(estilo.fontSize ?? 20),
    );
    final pintura = Paint()
      ..isAntiAlias = true
      ..color = estilo.color ?? Colors.white;
    final (h, v) = LogoGeometria.barrasDeCruz();
    for (final c in mas.centros) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(SelloDelLogo.inclinacionDeLosMas);
      canvas.scale(mas.largo / LogoGeometria.largoDeCruz);
      canvas.drawRect(h, pintura);
      canvas.drawRect(v, pintura);
      canvas.restore();
    }
  }
```

  Al final del archivo, suma `PiezasDelSello`, que mide el sello de la franja como lo dibuja.
  Es el destino de la subida del recibimiento y el origen del paso al horario de la Tarea 30.

```dart
/// Dónde queda cada pieza de un sello ya dibujado, en coordenadas globales.
class PiezasDelSello {
  const PiezasDelSello({
    required this.estrella,
    required this.radio,
    required this.ulima,
    required this.origenDeUlima,
    required this.mas,
    required this.largoDeLosMas,
  });

  /// Mide el sello de [claveDelSello] con el estilo y la escala con que se
  /// dibuja, o null si todavía no tiene tamaño.
  static PiezasDelSello? medir(BuildContext context, GlobalKey claveDelSello) {
    final caja = claveDelSello.currentContext?.findRenderObject() as RenderBox?;
    if (caja == null || !caja.hasSize) return null;
    final sello = caja.localToGlobal(Offset.zero) & caja.size;
    final estilo = DefaultTextStyle.of(context).style
        .merge(SelloDelLogo.estilo(Theme.of(context).colorScheme))
        .copyWith(color: Colors.white);
    final escala = SelloDelLogo.escalaQueCabe(
      estilo,
      MediaQuery.textScalerOf(context),
      MediaQuery.sizeOf(context).width - 2 * CabeceraConSello.margenLateral,
    );
    TextPainter medirTexto(String texto) => TextPainter(
      text: TextSpan(text: texto, style: estilo),
      textDirection: TextDirection.ltr,
      textScaler: escala,
    )..layout();
    final ulima = medirTexto('ULIMA');
    final glifos = medirTexto('++');
    final izquierdaDeUlima =
        sello.left + SelloDelLogo.tamanoDeEstrella + SelloDelLogo.separacion;
    final esquinaDeLosMas = Offset(
      izquierdaDeUlima + ulima.width,
      sello.center.dy - glifos.height / 2,
    );
    final mas = SelloDelLogo.medidasDeLosMas(
      glifos,
      escala.scale(estilo.fontSize ?? 20),
    );
    return PiezasDelSello(
      estrella: Offset(
        sello.left + SelloDelLogo.tamanoDeEstrella / 2,
        sello.center.dy,
      ),
      radio: SelloDelLogo.tamanoDeEstrella / 2,
      ulima: ulima,
      origenDeUlima: Offset(
        izquierdaDeUlima,
        sello.center.dy - ulima.height / 2,
      ),
      mas: <Offset>[for (final c in mas.centros) esquinaDeLosMas + c],
      largoDeLosMas: mas.largo,
    );
  }

  final Offset estrella;
  final double radio;
  final TextPainter ulima;
  final Offset origenDeUlima;
  final List<Offset> mas;
  final double largoDeLosMas;
}
```

  La fila del sello centra en vertical la estrella, «ULIMA» y los «++», así que cada pieza se
  mide desde el centro de su caja.

- [ ] **Paso 5. Escribe el recibimiento.** Crea `lib/pages/bienvenida/widgets/recibimiento.dart`.

```dart
// lib/pages/bienvenida/widgets/recibimiento.dart
// El recibimiento de la bienvenida (RF-BIEN-2, RF-BIEN-3 y RF-BIEN-21). Tapa
// la conversación desde el primer cuadro, igual al último de la intro, trae a
// Ulises volando junto a la estrella, muestra el saludo y los dos botones y,
// al responder, lleva el logo al sello y a Ulises a su avatar. Las medidas se
// calculan una vez, al empezar el vuelo (B-27), y la estrella nunca queda
// tapada (RF-BIEN-4).

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../components/logo/escena_del_logo.dart';
import '../../../components/logo/logo_geometria.dart';
import '../../../components/logo/pintor_del_logo.dart';
import '../../../components/logo/sello_del_logo.dart';
import '../../../configs/themes.dart';
import '../../../domain/bienvenida/bienvenida_turnos.dart';
import '../../splash/salidas.dart' show naranjaDelSplash;
import '../../splash/variantes/variante_de_intro.dart'
    show grado, mezcla, tramo;
import 'vuelo_de_ulises.dart';

typedef _Textos = TextosDeLaBienvenida;

/// Los tiempos del recibimiento en ms. Los cuatro primeros cuentan desde el
/// relevo del splash y los demás desde la respuesta (RF-BIEN-2 y RF-BIEN-4).
abstract final class TiemposDelRecibimiento {
  static const double quieto = 160;
  static const double aterrizaje = 1460;
  static const double finDelRebote = 1940;
  static const double botones = 2320;
  static const double inicioDeLaSubida = 90;
  static const double finDeLaSubida = 990;
  static const double inicioDelSalto = 120;
  static const double posado = 1030;
}

typedef _T = TiemposDelRecibimiento;

class Recibimiento extends StatefulWidget {
  const Recibimiento({
    super.key,
    required this.pose,
    required this.conSesion,
    required this.claveDelSello,
    required this.avatar,
    required this.alResponder,
    required this.alAterrizarConSesion,
    required this.alSaludarEnLaConversacion,
    required this.alSubir,
    required this.alPosarseElSello,
    required this.alTerminar,
  });

  static const Key claveDelFondo = Key('recibimiento-fondo');
  static const Key claveDeUlises = Key('recibimiento-ulises');
  static const Key claveDeLaTarjeta = Key('recibimiento-tarjeta');
  static const Key claveDeLosBotones = Key('recibimiento-botones');

  /// El fondo y la estrella del cuadro actual, para las pruebas. [context] es
  /// el de una pieza del recibimiento.
  @visibleForTesting
  static ({Color fondo, EscenaDelLogo? estrella}) cuadroActual(
    BuildContext context,
  ) {
    final estado = context.findAncestorStateOfType<_RecibimientoState>()!;
    final pintor = estado._pintor(estado.context);
    return (fondo: pintor.color, estrella: pintor.estrella);
  }

  /// La estrella después de «Si no cabe», para las pruebas.
  @visibleForTesting
  static ({Offset centro, double radio}) estrellaActual(BuildContext context) {
    final estado = context.findAncestorStateOfType<_RecibimientoState>()!;
    return (centro: estado._estrella, radio: estado._radio);
  }

  /// La pose que deja la intro, o la de reposo sin pose (RF-BIEN-3).
  final PoseDelLogo pose;

  /// Hay una sesión puesta, así que no hay tarjeta ni botones y el fin del
  /// rebote hace de respuesta (RF-BIEN-21).
  final bool conSesion;

  /// La clave del sello de la franja, que es el destino de la subida.
  final GlobalKey claveDelSello;

  /// Dónde queda el avatar de 40 dp del primer grupo.
  final Rect avatar;
  final void Function(bool yaUsa) alResponder;
  final VoidCallback alAterrizarConSesion;
  final VoidCallback alSaludarEnLaConversacion;

  /// Empieza la subida, y la conversación ya trae su primer grupo.
  final VoidCallback alSubir;

  /// El logo llega al sello, que late (RF-BIEN-4).
  final VoidCallback alPosarseElSello;

  /// Ulises se posa en su avatar y el recibimiento termina.
  final VoidCallback alTerminar;

  @override
  State<Recibimiento> createState() => _RecibimientoState();
}

enum _Fase { llegada, saludo, subida, fin }

class _RecibimientoState extends State<Recibimiento>
    with SingleTickerProviderStateMixin {
  late final Ticker _reloj = createTicker(_alTic);
  double _ms = 0;
  _Fase _fase = _Fase.llegada;
  double? _respuestaEn;
  bool _conTarjeta = false;
  bool _selloPosado = false;
  MedidasDelRecibimiento? _medidas;
  PuntosDelVuelo? _puntos;
  Offset? _aterrizaje;
  PiezasDelSello? _destino;
  late Offset _estrella = widget.pose.centro;
  late double _radio = widget.pose.radio;

  static const TextStyle _estiloSaludo = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  static const TextStyle _estiloPregunta = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    height: 1.25,
  );
  static const TextStyle _estiloBoton = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
  );

  @override
  void initState() {
    super.initState();
    unawaited(_reloj.start());
  }

  @override
  void dispose() {
    _reloj.dispose();
    super.dispose();
  }

  void _alTic(Duration t) {
    _ms = t.inMicroseconds / 1000;
    if (_medidas == null && _ms >= _T.quieto) _medir();
    switch (_fase) {
      case _Fase.llegada:
        if (_medidas != null) _moverLaEstrella();
        if (_ms >= _T.finDelRebote) _alTerminarElRebote();
      case _Fase.saludo:
        // Con la tarjeta y los botones quietos, el reloj calla y no pide
        // cuadros mientras el alumno lee (RF-BIEN-18).
        if (_ms >= _T.botones + 400) _reloj.muted = true;
      case _Fase.subida:
        // Tras un toque en reposo, la subida cuenta desde este cuadro.
        _respuestaEn ??= _ms;
        _destino ??= PiezasDelSello.medir(context, widget.claveDelSello);
        final desde = _ms - _respuestaEn!;
        if (!_selloPosado && desde >= _T.finDeLaSubida) {
          _selloPosado = true;
          widget.alPosarseElSello();
        }
        if (desde >= _T.posado) {
          _fase = _Fase.fin;
          _reloj.stop();
          widget.alTerminar();
          return;
        }
      case _Fase.fin:
        return;
    }
    setState(() {});
  }

  /// Mide una vez, al empezar el vuelo, con la escala de texto de ese
  /// momento (B-27). Los textos se miden con el estilo heredado, como los
  /// dibuja la tarjeta.
  void _medir() {
    final mq = MediaQuery.of(context);
    final ancho = math.min(mq.size.width, 600.0);
    final columna = Rect.fromLTWH(
      (mq.size.width - ancho) / 2,
      0,
      ancho,
      mq.size.height,
    );
    final heredado = DefaultTextStyle.of(context).style;
    double alto(String texto, TextStyle estilo, double maximo) =>
        (TextPainter(
          text: TextSpan(text: texto, style: heredado.merge(estilo)),
          textDirection: TextDirection.ltr,
          textScaler: mq.textScaler,
        )..layout(maxWidth: maximo)).height;
    final bordeDeUlises = widget.pose.centro.dx - 104 + 35;
    final anchoDelTexto = columna.right - 12 - (bordeDeUlises + 11) - 26;
    final anchoDelBoton = columna.width - 44;
    final boton = math.max(
      50.0,
      math.max(
            alto(_Textos.siEntrar, _estiloBoton, anchoDelBoton),
            alto(_Textos.soyNuevo, _estiloBoton, anchoDelBoton),
          ) +
          18,
    );
    final medidas = medirElRecibimiento(
      estrella: widget.pose.centro,
      radio: widget.pose.radio,
      columna: columna,
      altoDePantalla: mq.size.height,
      areaSeguraArriba: mq.padding.top,
      areaSeguraAbajo: mq.padding.bottom,
      altoDeLaTarjeta:
          9 +
          alto(_Textos.saludo, _estiloSaludo, anchoDelTexto) +
          1 +
          alto(_Textos.pregunta, _estiloPregunta, anchoDelTexto) +
          11,
      altoDeLosBotones: boton * 2 + 10,
    );
    _medidas = medidas;
    // Con sesión no hay tarjeta ni botones, así que «Si no cabe» no aplica y
    // Ulises aterriza en su lugar de la maqueta (RF-BIEN-21).
    final aterrizaje = widget.conSesion
        ? widget.pose.centro + const Offset(-104, 138)
        : medidas.ulises.center;
    _aterrizaje = aterrizaje;
    _puntos = puntosDelVuelo(aterrizaje, mq.size);
  }

  /// Si Ulises y la tarjeta no caben, la estrella sube, y si hace falta se
  /// achica, lo justo antes de que Ulises aterrice, en 300 ms (B-28).
  void _moverLaEstrella() {
    final m = _medidas!;
    if (widget.conSesion || m.enConversacion) return;
    final t = Curves.easeInOutCubic.transform(
      tramo(_ms, _T.aterrizaje - 300, _T.aterrizaje),
    );
    _estrella = Offset.lerp(widget.pose.centro, m.estrella, t)!;
    _radio = mezcla(widget.pose.radio, m.radio, t);
  }

  void _alTerminarElRebote() {
    if (widget.conSesion) {
      // El fin del rebote hace de respuesta, sin el asentimiento
      // (RF-BIEN-21).
      widget.alAterrizarConSesion();
      _subir(_T.finDelRebote);
    } else if (_medidas!.enConversacion) {
      // Ni achicando la estrella caben, así que Ulises saluda ya en la
      // conversación (B-28).
      widget.alSaludarEnLaConversacion();
      _subir(_T.finDelRebote);
    } else {
      _conTarjeta = true;
      _fase = _Fase.saludo;
    }
  }

  void _responder(bool yaUsa) {
    // Los toques cuentan desde que los botones empiezan a entrar.
    if (_fase != _Fase.saludo || _ms < _T.botones) return;
    widget.alResponder(yaUsa);
    // En reposo el reloj calla y _ms quedó en el último cuadro, así que la
    // subida cuenta desde el primer cuadro después del toque.
    final enReposo = _reloj.muted;
    _reloj.muted = false;
    _subir(enReposo ? null : _ms);
  }

  void _subir(double? ms) {
    _respuestaEn = ms;
    _fase = _Fase.subida;
    widget.alSubir();
  }

  _PintorDelRecibimiento _pintor(BuildContext context) {
    final tamano = MediaQuery.sizeOf(context);
    final franja = MaterialTheme.bienvenidaFranja(Theme.brightnessOf(context));
    // Mientras Ulises vuela, el fondo pasa en 1100 ms, con la curva seno, de
    // #E77330 al color de la franja (RF-BIEN-2).
    final cambio = curvaSeno(tramo(_ms, _T.quieto, _T.quieto + 1100));
    final quieta = EscenaDelLogo.desdePose(
      widget.pose,
    ).copyWith(centro: _estrella, radio: _radio);
    final a = _aterrizaje;
    final puntos = _puntos;
    final vuelo = _ms - _T.quieto;
    var sombra = a == null || vuelo < 0
        ? null
        : sombraDelVuelo(a, curvaSeno(tramo(vuelo, 0, 1300)));
    var fondo = Offset.zero & tamano;
    var radio = 0.0;
    EscenaDelLogo? estrella = quieta;
    var revelado = 0.0;
    final respuesta = _respuestaEn;
    final destino = _destino;
    if (respuesta != null) {
      final desde = _ms - respuesta;
      final lineal = tramo(desde, _T.inicioDeLaSubida, _T.finDeLaSubida);
      final t = Curves.easeInOutCubic.transform(lineal);
      // El fondo de pantalla completa se recoge hasta la franja y sus
      // esquinas inferiores pasan de 0 a 26 dp (RF-BIEN-4).
      fondo = Rect.fromLTWH(
        0,
        0,
        tamano.width,
        mezcla(tamano.height, CabeceraConSello.alto(context), t),
      );
      radio = 26 * t;
      if (sombra != null) {
        final s = sombra;
        sombra = (
          centro: s.centro,
          ancho: s.ancho,
          opacidad: s.opacidad * (1 - tramo(desde, _T.inicioDelSalto, 310)),
        );
      }
      if (_selloPosado) {
        // El sello de la franja ya se ve entero en su lugar.
        estrella = null;
      } else if (destino != null) {
        estrella = _enLaSubida(quieta, destino, lineal, t);
        revelado = tramo(lineal, 0.55, 1);
      }
    }
    return _PintorDelRecibimiento(
      fondo: fondo,
      color: Color.lerp(naranjaDelSplash, franja, cambio)!,
      radio: radio,
      estrella: estrella,
      sombra: sombra,
      estela: a == null || puntos == null
          ? const <({Offset centro, double opacidad})>[]
          : estelaDelVuelo(puntos, a, vuelo),
      particulas: a == null
          ? const <({Offset centro, double radio, double opacidad})>[]
          : particulasDelAterrizaje(a, _ms - _T.aterrizaje),
      ulima: _selloPosado ? null : destino?.ulima,
      origenDeUlima: destino?.origenDeUlima,
      revelado: revelado,
    );
  }

  /// La estrella va de su pose a su lugar en el sello, se achica hasta
  /// 1,22 × 26 dp de punta a punta y gira 45° (RF-BIEN-4).
  EscenaDelLogo _enLaSubida(
    EscenaDelLogo quieta,
    PiezasDelSello d,
    double lineal,
    double t,
  ) {
    final centro = Offset.lerp(quieta.centro, d.estrella, t)!;
    final radio = mezcla(quieta.radio, d.radio, t);
    final u = LogoGeometria.unidad(radio);
    return quieta.copyWith(
      centro: centro,
      radio: radio,
      giro: quieta.giro + 45 * grado * t,
      cruces: <CruzEnEscena>[
        for (var i = 0; i < quieta.cruces.length && i < d.mas.length; i++)
          _cruzEnLaSubida(quieta, i, d, lineal, centro, u),
      ],
    );
  }

  /// Cada «+» sale al 22 % del tiempo, el segundo un 6 % después, salta en un
  /// arco de 18 dp y cae tras «ULIMA», inclinado −12°.
  CruzEnEscena _cruzEnLaSubida(
    EscenaDelLogo quieta,
    int i,
    PiezasDelSello d,
    double lineal,
    Offset centro,
    double u,
  ) {
    final cruz = quieta.cruces[i];
    final avance = Curves.easeInOutCubic.transform(
      tramo(lineal, 0.22 + 0.06 * i, 1),
    );
    final enVista =
        Offset.lerp(quieta.aVista(cruz.centro), d.mas[i], avance)! -
        Offset(0, 18 * math.sin(math.pi * avance));
    final tamano = mezcla(
      quieta.unidad * cruz.escala,
      d.largoDeLosMas / LogoGeometria.largoDeCruz,
      avance,
    );
    return cruz.copyWith(
      centro: (enVista - centro) / u,
      escala: tamano / u,
      giro: SelloDelLogo.inclinacionDeLosMas * avance,
    );
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: CustomPaint(
          key: Recibimiento.claveDelFondo,
          painter: _pintor(context),
        ),
      ),
      if (_aterrizaje != null && _ms >= _T.quieto) _ulises(),
      if (_conTarjeta) ..._tarjetaYBotones(context),
    ],
  );

  Widget _ulises() {
    final a = _aterrizaje!;
    var pose = _ms < _T.aterrizaje
        ? ulisesEnVuelo(_puntos!, a, _ms - _T.quieto)
        : _ms < _T.finDelRebote
        ? ulisesAlAterrizar(a, _ms - _T.aterrizaje)
        : ulisesAsiente(a, _ms - _T.finDelRebote);
    final respuesta = _respuestaEn;
    if (respuesta != null) {
      pose = ulisesSalta(
        a,
        widget.avatar.center,
        _ms - respuesta - _T.inicioDelSalto,
      );
    }
    return Positioned(
      left: pose.centro.dx - pose.lado / 2,
      top: pose.centro.dy - pose.lado / 2,
      // Una capa aislada, así que el vuelo no repinta el resto (RF-BIEN-18).
      child: RepaintBoundary(
        child: IgnorePointer(
          child: ExcludeSemantics(
            child: Transform.rotate(
              angle: pose.giro,
              child: Transform.scale(
                scaleX: pose.escalaX,
                scaleY: pose.escalaY,
                child: ClipOval(
                  key: Recibimiento.claveDeUlises,
                  child: Image.asset(
                    'assets/images/ulises_chatbot.png',
                    width: pose.lado,
                    height: pose.lado,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _tarjetaYBotones(BuildContext context) {
    final m = _medidas!;
    final b = Theme.brightnessOf(context);
    final respuesta = _respuestaEn;
    // Al responder, la tarjeta y los botones se van en 280 ms.
    final salida = respuesta == null
        ? 1.0
        : 1 - tramo(_ms - respuesta, 0, 280);
    final tarjeta = tramo(_ms, _T.finDelRebote, _T.finDelRebote + 360);
    final botones = tramo(_ms, _T.botones, _T.botones + 400);
    return <Widget>[
      Positioned(
        left: m.tarjeta.left,
        top: m.tarjeta.top,
        width: m.tarjeta.width,
        child: Opacity(
          opacity: (tarjeta * salida).clamp(0.0, 1.0),
          // Entra en 360 ms con un leve rebote.
          child: Transform.scale(
            scale: 0.9 + 0.1 * Curves.easeOutBack.transform(tarjeta),
            alignment: Alignment.centerLeft,
            child: const _Tarjeta(key: Recibimiento.claveDeLaTarjeta),
          ),
        ),
      ),
      if (_ms >= _T.botones)
        Positioned(
          left: m.botones.left,
          width: m.botones.width,
          top: m.botones.top,
          child: IgnorePointer(
            ignoring: respuesta != null,
            child: Opacity(
              opacity: (botones * salida).clamp(0.0, 1.0),
              // Entran en 400 ms desde 18 dp más abajo (B-2).
              child: Transform.translate(
                offset: Offset(
                  0,
                  18 * (1 - Curves.easeOutCubic.transform(botones)),
                ),
                child: Column(
                  key: Recibimiento.claveDeLosBotones,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Boton(
                      texto: _Textos.siEntrar,
                      fondo: MaterialTheme.bienvenidaEntrarFondo(b),
                      tinta: MaterialTheme.bienvenidaEntrarTinta(b),
                      alTocar: () => _responder(true),
                    ),
                    const SizedBox(height: 10),
                    _Boton(
                      texto: _Textos.soyNuevo,
                      fondo: MaterialTheme.bienvenidaNuevoFondo(b),
                      tinta: MaterialTheme.bienvenidaNuevoTinta(b),
                      borde: MaterialTheme.bienvenidaNuevoBorde(b),
                      alTocar: () => _responder(false),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    ];
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({super.key});

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);
    return Semantics(
      container: true,
      label: '${_Textos.saludo.replaceAll(' 👋', '')}. ${_Textos.pregunta}',
      excludeSemantics: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // El pico, un cuadrado de 14 dp girado 45° que asoma 5 dp por la
          // izquierda a 17 dp del borde superior, hacia Ulises.
          Positioned(
            left: -5,
            top: 17,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: SizedBox.square(
                dimension: 14,
                child: ColoredBox(color: MaterialTheme.bienvenidaSaludo(b)),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: MaterialTheme.bienvenidaSaludo(b),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(13, 9, 13, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _Textos.saludo,
                    style: _RecibimientoState._estiloSaludo.copyWith(
                      color: MaterialTheme.bienvenidaSaludoSub(b),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _Textos.pregunta,
                    style: _RecibimientoState._estiloPregunta.copyWith(
                      color: MaterialTheme.bienvenidaSaludoTinta(b),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Boton extends StatelessWidget {
  const _Boton({
    required this.texto,
    required this.fondo,
    required this.tinta,
    required this.alTocar,
    this.borde,
  });

  final String texto;
  final Color fondo;
  final Color tinta;
  final Color? borde;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: texto,
    excludeSemantics: true,
    child: Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        // Cada uno se oscurece un 7 % al tocarlo (B-3).
        highlightColor: Colors.black.withValues(alpha: 0.07),
        splashColor: Colors.transparent,
        onTap: alTocar,
        child: Ink(
          decoration: BoxDecoration(
            color: fondo,
            borderRadius: BorderRadius.circular(16),
            border: borde == null
                ? null
                : Border.all(color: borde!, width: 1.5),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 50),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Text(
                  texto,
                  textAlign: TextAlign.center,
                  style: _RecibimientoState._estiloBoton.copyWith(color: tinta),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// El fondo, la sombra, la estela, las partículas, la estrella y la
/// revelación de «ULIMA», en un solo pintor.
class _PintorDelRecibimiento extends CustomPainter {
  _PintorDelRecibimiento({
    required this.fondo,
    required this.color,
    required this.radio,
    required this.estrella,
    required this.sombra,
    required this.estela,
    required this.particulas,
    required this.ulima,
    required this.origenDeUlima,
    required this.revelado,
  });

  final Rect fondo;
  final Color color;
  final double radio;
  final EscenaDelLogo? estrella;
  final ({Offset centro, double ancho, double opacidad})? sombra;
  final List<({Offset centro, double opacidad})> estela;
  final List<({Offset centro, double radio, double opacidad})> particulas;
  final TextPainter? ulima;
  final Offset? origenDeUlima;
  final double revelado;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        fondo,
        bottomLeft: Radius.circular(radio),
        bottomRight: Radius.circular(radio),
      ),
      Paint()..color = color,
    );
    final s = sombra;
    if (s != null && s.opacidad > 0) {
      canvas.drawOval(
        Rect.fromCenter(
          center: s.centro,
          width: s.ancho,
          height: s.ancho * 0.22,
        ),
        Paint()..color = Colors.black.withValues(alpha: s.opacidad),
      );
    }
    final blanco = Paint()..isAntiAlias = true;
    for (final p in estela) {
      blanco.color = Colors.white.withValues(alpha: p.opacidad);
      canvas.drawCircle(p.centro, 3.5, blanco);
    }
    for (final p in particulas) {
      blanco.color = Colors.white.withValues(alpha: p.opacidad);
      canvas.drawCircle(p.centro, p.radio, blanco);
    }
    final e = estrella;
    if (e != null) pintarEscena(canvas, e);
    final texto = ulima;
    final origen = origenDeUlima;
    if (texto != null && origen != null && revelado > 0) {
      // «ULIMA» se revela de izquierda a derecha desde el 55 % de la subida.
      canvas.save();
      canvas.clipRect(
        Rect.fromLTWH(
          origen.dx,
          origen.dy - 4,
          texto.width * revelado,
          texto.height + 8,
        ),
      );
      texto.paint(canvas, origen);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PintorDelRecibimiento oldDelegate) => true;
}
```

  El pintor se crea en cada cuadro del recibimiento, que dura unos 3 s y termina con él. La
  conversación de debajo no se reconstruye mientras tanto, y con la tarjeta y los botones quietos
  el reloj calla, así que la pantalla en reposo no pide cuadros (RF-BIEN-18). Por eso
  `pumpAndSettle` termina sobre `/login`, aunque las pausas de la conversación, que son `Timer`,
  se esperan con `avanzar`.

- [ ] **Paso 6. Suma el saludo en la conversación.** En `bienvenida_controller.dart`, suma el
  estado y el método después de `responderAlSaludo`.

```dart
  /// «Si no cabe», el último recurso. Ulises saluda ya en la conversación y
  /// la pregunta queda con sus respuestas rápidas (B-28).
  final saludoEnLaConversacion = false.obs;

  void saludarEnLaConversacion() {
    if (turno.value != TurnoB.recibimiento || saludoEnLaConversacion.value) {
      return;
    }
    saludoEnLaConversacion.value = true;
    entradas.add(BurbujaDeUlises(id: _id(), texto: TextosB.saludo));
    entradas.add(BurbujaDeUlises(id: _id(), texto: TextosB.pregunta));
  }
```

  `responderAlSaludo` suma las dos burbujas del primer grupo solo si el saludo no está ya en la
  conversación, y `_reiniciar` lo apaga.

```dart
  void responderAlSaludo({required bool yaUsa}) {
    if (turno.value != TurnoB.recibimiento) return;
    if (!saludoEnLaConversacion.value) {
      entradas.add(BurbujaDeUlises(id: _id(), texto: TextosB.saludo));
      entradas.add(BurbujaDeUlises(id: _id(), texto: TextosB.pregunta));
    }
    _responder(yaUsa ? TextosB.siEntrar : TextosB.soyNuevo);
    if (yaUsa) {
      _abrirE1();
    } else {
      _abrirN1();
    }
  }
```

```dart
  void _reiniciar() {
    _cerrarLosTramos();
    entradas.clear();
    turno.value = null;
    ultimoTurno.value = null;
    esperando.value = false;
    errorLocal.value = null;
    saludoEnLaConversacion.value = false;
    _conSesion = false;
    _login.vaciarCampos();
  }
```

  En `compositor.dart`, suma este caso en `compositorDelTurno`, antes del caso que agrupa los
  turnos sin compositor. El `switch` sigue exhaustivo, porque `recibimiento` también queda en ese
  grupo.

```dart
  TurnoDeLaBienvenida.recibimiento when c.saludoEnLaConversacion.value =>
    RespuestasRapidas(
      respuestas: [
        RespuestaRapida(
          texto: _Textos.siEntrar,
          principal: true,
          alTocar: () => c.responderAlSaludo(yaUsa: true),
        ),
        RespuestaRapida(
          texto: _Textos.soyNuevo,
          alTocar: () => c.responderAlSaludo(yaUsa: false),
        ),
      ],
    ),
```

- [ ] **Paso 7. Prepara la franja y las burbujas.** En `franja_con_sello.dart`, `FranjaConSello`
  suma la clave y la visibilidad del sello.

```dart
class FranjaConSello extends StatelessWidget {
  const FranjaConSello({
    super.key,
    required this.latido,
    required this.rombos,
    this.radioInferior = 26,
    this.claveDelSello,
    this.selloVisible = true,
  });

  final ValueListenable<double> latido;
  final ValueListenable<List<double>?> rombos;
  final double radioInferior;

  /// La clave con la que la subida del recibimiento mide el sello.
  final GlobalKey? claveDelSello;

  /// Oculto mientras el recibimiento dibuja el suyo en el mismo lugar.
  final bool selloVisible;

  @override
  Widget build(BuildContext context) => CabeceraConSello(
    color: MaterialTheme.bienvenidaFranja(Theme.brightnessOf(context)),
    radioInferior: radioInferior,
    sello: Opacity(
      opacity: selloVisible ? 1 : 0,
      child: SelloDelLogo(key: claveDelSello, latido: latido, rombos: rombos),
    ),
  );
}
```

  En `burbujas.dart`, `EntradaView` suma `this.ocultarAvatar = false` con su campo
  `final bool ocultarAvatar;` y lo pasa a `_BurbujaDeUlises`, que suma el mismo campo. Allí, el
  avatar y el nombre quedan así.

```dart
              SizedBox(
                width: avatar,
                child: primeraDelGrupo
                    // Ulises es el avatar mientras salta, y al posarse el
                    // avatar queda en su lugar (RF-BIEN-2).
                    ? Opacity(
                        opacity: ocultarAvatar ? 0 : 1,
                        child: UlisesAvatar(size: avatar),
                      )
                    : const SizedBox.shrink(),
              ),
```

```dart
                    if (primeraDelGrupo && primerGrupo)
                      // El nombre aparece en 250 ms al posarse Ulises.
                      AnimatedOpacity(
                        opacity: ocultarAvatar ? 0 : 1,
                        duration: const Duration(milliseconds: 250),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            TextosDeLaBienvenida.ulises,
                            style: TextStyle(
                              color: MaterialTheme.testMuted(b),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
```

- [ ] **Paso 8. Monta el recibimiento en la página.** En `bienvenida_page.dart`, suma los imports
  de `dart:math` y del recibimiento, y quita los de `estrella_del_logo.dart`,
  `pintor_del_logo.dart` y `salidas.dart`, que solo usaba `_primerCuadro`.

```dart
import 'dart:math' as math;
```

```dart
import 'widgets/recibimiento.dart';
```

  Suma el estado del recibimiento a `_BienvenidaPageState`.

```dart
  final GlobalKey _claveDelSello = GlobalKey();
  bool _recibimientoTerminado = false;
  bool _selloVisible = true;
  bool _avatarVisible = true;
```

  En `didChangeDependencies`, después de leer los argumentos, retén el revelador. Sin un motivo,
  el recibimiento lo suelta cuando Ulises se posa.

```dart
    _revelador.retenido = _motivo == null;
```

  Reemplaza `_tieneCompositor`, porque con «Si no cabe» el recibimiento tiene sus respuestas
  rápidas.

```dart
  bool _tieneCompositor(TurnoDeLaBienvenida t) => switch (t) {
    TurnoDeLaBienvenida.recibimiento => _c.saludoEnLaConversacion.value,
    TurnoDeLaBienvenida.llegadaConSesion => false,
    _ => true,
  };
```

  Reemplaza `_cuerpo` por esta versión, que conserva la capa del confeti de la Tarea 27 y la
  píldora, y borra `_primerCuadro`.

```dart
  Widget _cuerpo(BuildContext context) {
    final atendida = _atendida;
    // Sin un motivo, el recibimiento tapa la conversación desde el primer
    // cuadro, que sale solo de los argumentos (RF-BIEN-1 a RF-BIEN-3).
    final conRecibimiento = _motivo == null && !_recibimientoTerminado;
    return Stack(
      children: [
        _conversacion(context, atendida: atendida),
        Positioned(
          top: CabeceraConSello.alto(context),
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: ClipRect(
              child: AnimatedBuilder(
                animation: _confeti,
                builder: (context, _) => _confeti.isAnimating
                    ? CustomPaint(painter: PintorDelConfeti(_confeti.value))
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        if (conRecibimiento)
          Positioned.fill(child: _recibimiento(context, atendida: atendida)),
        Positioned(
          top: CabeceraConSello.alto(context) + 8,
          left: 0,
          right: 0,
          child: Center(
            child: ValueListenableBuilder<EstadoDeLaPildora?>(
              valueListenable: _pildora,
              builder: (context, estado, _) => estado == null
                  ? const SizedBox.shrink()
                  : PildoraDelRegistro(estado: estado),
            ),
          ),
        ),
      ],
    );
  }
```

  Suma estos métodos.

```dart
  Widget _recibimiento(BuildContext context, {required bool atendida}) =>
      Recibimiento(
        pose: _pose ?? _poseDeReposo(context),
        conSesion: atendida && _c.conSesion,
        claveDelSello: _claveDelSello,
        avatar: _avatar(context),
        alResponder: (yaUsa) => _c.responderAlSaludo(yaUsa: yaUsa),
        alAterrizarConSesion: _c.ulisesAterrizoConSesion,
        alSaludarEnLaConversacion: _c.saludarEnLaConversacion,
        alSubir: () {
          // La conversación ya trae su primer grupo, sin esperar el ritmo.
          _sincronizar();
          _revelador.mostrarYa(_primerGrupoConRespuesta());
          setState(() {
            _selloVisible = false;
            _avatarVisible = false;
          });
        },
        alPosarseElSello: () {
          setState(() => _selloVisible = true);
          _latir();
        },
        alTerminar: () {
          setState(() {
            _avatarVisible = true;
            _recibimientoTerminado = true;
          });
          // 650 ms después empieza el primer turno de la rama elegida.
          _revelador.retenido = false;
        },
      );

  /// El primer grupo de Ulises y, si la hay, la respuesta del alumno. Las
  /// entradas que siguen esperan su pausa (RF-BIEN-2 y RF-BIEN-21).
  int _primerGrupoConRespuesta() {
    final entradas = _c.entradas;
    final respuesta = entradas.indexWhere((e) => e is RespuestaDelAlumno);
    if (respuesta >= 0) return respuesta + 1;
    return entradas.takeWhile((e) => e is BurbujaDeUlises).length.clamp(0, 2);
  }

  /// El avatar de 40 dp del primer grupo, bajo la franja, con el relleno de
  /// la lista y el de la primera burbuja.
  Rect _avatar(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final columna = math.min(ancho, 600.0);
    return Rect.fromLTWH(
      (ancho - columna) / 2 + 12,
      CabeceraConSello.alto(context) + 8 + 12,
      40,
      40,
    );
  }
```

  En `_conversacion`, la franja recibe la clave y la visibilidad, y cada entrada del primer grupo
  oculta su avatar mientras Ulises salta.

```dart
        FranjaConSello(
          latido: _latido,
          rombos: _rombos,
          claveDelSello: _claveDelSello,
          selloVisible: _selloVisible,
        ),
```

```dart
                itemBuilder: (context, i) {
                  final entrada = entradas[i];
                  final anterior = i > 0 ? entradas[i - 1] : null;
                  final primerGrupo = _enElPrimerGrupo(
                    entradas,
                    i,
                    primerIdDeUlises,
                  );
                  return EntradaView(
                    key: ValueKey<int>(entrada.id),
                    entrada: entrada,
                    anterior: anterior,
                    primerGrupo: primerGrupo,
                    ocultarAvatar: primerGrupo && !_avatarVisible,
                    conMovimiento: !_sinMovimiento,
                    resultado: (context) => ResultadoEnLaConversacion(c: _c),
                  );
                },
```

  El `Recibimiento` cuenta su tiempo desde su primer cuadro, que es el relevo. La visita se
  atiende en los primeros milisegundos, así que `conSesion` ya vale lo que corresponde cuando el
  recibimiento mide, a los 160 ms.

- [ ] **Paso 9. Corre las pruebas y confirma que pasan.**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/components/logo lib/pages/bienvenida test/bienvenida
"${FLUTTER:?}" test --no-pub test/bienvenida
"${FLUTTER:?}" analyze --no-pub
```

Esperado. `All tests passed!` y los avisos de la base. Si una medida con 1,3 o 2,0 queda fuera
por menos de 1 dp, se revisa que `_medir` mida con el estilo heredado y con el ancho del texto de
la tarjeta antes de tocar la prueba.

- [ ] **Paso 10. Commit.**

```bash
cd "${REPO:?}"
git status --short
git add lib/components/logo/sello_del_logo.dart lib/pages/bienvenida test/bienvenida
git commit -m "feat(bienvenida): Ulises vuela junto a la estrella del splash, saluda con dos botones y lleva el logo al sello al responder, sin tapar nunca la estrella (RF-BIEN-2 a RF-BIEN-4 y RF-BIEN-21)"
git log -1 --format='%an <%ae>'
```

---

### Tarea 29. `/login` muestra la bienvenida, `/registro` sale y las pruebas de hoy pasan a la conversación

**Requisitos.** De RF-BIEN-1, «La ruta», «Los controladores», «La navegación queda en la
bienvenida» y «`/registro` sale» (decisiones B-19, B-23 y B-25). Las tablas «Salen» y
«Modificados» de la spec en lo que toca a `login_page.dart`, `registro_page.dart`,
`registro_binding.dart`, los comentarios que nombran `/registro` y las pruebas de
`test/HU01_jeff/`, `test/HU33_jeff/` y `test/HU34_jeff/registro_consent_test.dart`. En web, E1
muestra el botón oficial de Google de hoy, que la Tarea 32 configura.

**Archivos.**
- Modificar `lib/main.dart` (la `GetPage` de `/login` y la salida de `/registro`).
- Modificar `lib/pages/login/login_binding.dart`.
- Modificar `lib/pages/login/login_controller.dart` (salen `submit`, `loginWithGoogle` y la
  navegación de `_onGoogleUserChanged`).
- Modificar `lib/pages/registro/registro_controller.dart` (`onClose` y un comentario).
- Modificar `lib/pages/bienvenida/widgets/compositor.dart` (el botón de Google en web).
- Modificar los comentarios de `lib/components/portal_consent/portal_consent_view.dart:1-16` y
  `:36-38`, `lib/services/auth_service.dart:189-197` y `lib/services/api_client.dart:27-35`.
- Borrar `lib/pages/login/login_page.dart`, `lib/pages/registro/registro_page.dart`,
  `lib/pages/registro/registro_binding.dart` y `test/HU33_jeff/registro_page_test.dart`.
- Modificar `test/bienvenida/apoyo_bienvenida.dart` (`StorageSinToken`,
  `registrarLosServiciosDeLaBienvenida`, `llegarAE1`, `llegarAE2` y el login lento).
- Modificar `test/bienvenida/bienvenida_ruta_test.dart` (grupo `la ruta /login con la
  bienvenida`).
- Modificar `test/bienvenida/bienvenida_registro_test.dart` (grupo `lo que probaba la pantalla
  del registro`).
- Reescribir `test/HU01_jeff/login_navigation_paths_test.dart` y
  `test/HU01_jeff/login_relogin_regression_test.dart`.
- Modificar `test/HU34_jeff/registro_consent_test.dart` (el grupo de widgets y dos comentarios).

**Interfaces.**
- Consume `BienvenidaPage` (Tarea 26), `BienvenidaController` (Tareas 23 a 25 y 28), `Recibimiento`
  (Tarea 28), `LoginController` con `entrar`, `entrarConGoogle`, `desenlaceDeGoogleEnWeb` y
  `vaciarCampos` (Tarea 19), `RegistroController.cerrar` (Tarea 19), `paginasDeLaApp` y `MyApp`
  (Tarea 14) y el apoyo de las Tareas 23 a 26.
- Produce estas firmas, que usan las Tareas 30 a 32.

```dart
// login_binding.dart, que registra LoginController y BienvenidaController, permanentes
class LoginBinding extends Bindings { void dependencies(); }
// test/bienvenida/apoyo_bienvenida.dart
class StorageSinToken extends StorageService {}
AuthDeLaBienvenida registrarLosServiciosDeLaBienvenida();
Future<void> llegarAE1(WidgetTester tester);
Future<void> llegarAE2(WidgetTester tester, {String codigo = '20230001'});
// AuthDeLaBienvenida suma Completer<String?>? loginPendiente e int logins
```

- [ ] **Paso 1. Suma el apoyo.** En `test/bienvenida/apoyo_bienvenida.dart`, suma estos imports,
  la clase, las tres funciones y el login lento de `AuthDeLaBienvenida`.

```dart
import 'package:ulima_plus/domain/bienvenida/bienvenida_turnos.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/compositor.dart';
import 'package:ulima_plus/services/storage_service.dart';
```

```dart
/// Un StorageService sin sesión guardada, para montar la ruta real de /login.
class StorageSinToken extends StorageService {
  @override
  Future<String?> get savedToken async => null;
}

/// Registra, sin red, los servicios que lee la bienvenida que crea
/// LoginBinding, como en la app real.
AuthDeLaBienvenida registrarLosServiciosDeLaBienvenida() {
  Get.testMode = true;
  final auth = AuthDeLaBienvenida();
  Get.put<AuthService>(auth);
  Get.put<StorageService>(StorageSinToken());
  return auth;
}

/// Desde el recibimiento, toca «Sí, entrar» y espera el compositor de E1.
Future<void> llegarAE1(WidgetTester tester) async {
  await avanzar(tester, 2800);
  await tester.tap(find.text(TextosDeLaBienvenida.siEntrar));
  await avanzar(tester, 2600);
}

/// Desde E1, envía [codigo] y espera el compositor de E2.
Future<void> llegarAE2(WidgetTester tester, {String codigo = '20230001'}) async {
  await tester.enterText(find.byType(TextField).first, codigo);
  await tester.tap(find.byType(BotonDeEnvio));
  await avanzar(tester, 2000);
}
```

  En `AuthDeLaBienvenida`, suma los dos campos y reemplaza `login` por esta versión.

```dart
  /// Si no es null, `login` espera a este Completer, como un login lento.
  Completer<String?>? loginPendiente;
  int logins = 0;

  @override
  Future<String?> login({required String code, required String password}) async {
    logins++;
    final pendiente = loginPendiente;
    if (pendiente != null) return pendiente.future;
    if (redCaida) throw const RedCaida();
    if (errorDeLogin != null) return errorDeLogin;
    usuario = alEntrar ?? alumnaDePrueba();
    return null;
  }
```

- [ ] **Paso 2. Escribe las pruebas que fallan.** En `test/bienvenida/bienvenida_ruta_test.dart`,
  suma estos imports y este grupo, y en el comentario de cabecera cambia «La Tarea 29 suma la ruta
  de la bienvenida y sus visitas.» por «La ruta /login muestra la bienvenida, con LoginBinding, y
  /registro ya no existe.».

```dart
import 'package:ulima_plus/main.dart';
import 'package:ulima_plus/pages/bienvenida/bienvenida_controller.dart';
import 'package:ulima_plus/pages/login/login_binding.dart';
import 'package:ulima_plus/pages/login/login_controller.dart';
```

  `bienvenida_turnos.dart` y `bienvenida_page.dart` ya están importados desde las Tareas 23 y 26,
  así que no se repiten.

```dart
  group('la ruta /login con la bienvenida (RF-BIEN-1, B-19, B-23 y B-25)', () {
    test('/login muestra la bienvenida con LoginBinding, y /registro ya no '
        'existe', () {
      final login = paginasDeLaApp.firstWhere((p) => p.name == '/login');
      expect(login.page(), isA<BienvenidaPage>());
      expect(login.binding, isA<LoginBinding>());
      expect(paginasDeLaApp.map((p) => p.name), isNot(contains('/registro')));
    });

    testWidgets('LoginBinding registra LoginController y la bienvenida y los '
        'reusa en cada llegada (B-19)', (tester) async {
      registrarLosServiciosDeLaBienvenida();
      LoginBinding().dependencies();
      final login = Get.find<LoginController>();
      final bienvenida = Get.find<BienvenidaController>();
      LoginBinding().dependencies();
      await tester.pump();
      expect(Get.find<LoginController>(), same(login));
      expect(Get.find<BienvenidaController>(), same(bienvenida));
    });

    testWidgets('en la app real, «Soy nuevo» abre el registro en la '
        'conversación sin salir de /login (RS-FE-1 y B-23)', (tester) async {
      registrarLosServiciosDeLaBienvenida();
      await tester.pumpWidget(const MyApp(initialRoute: '/login'));
      await avanzar(tester, 2800);
      await tester.tap(find.text(TextosDeLaBienvenida.soyNuevo));
      await tester.pump();
      expect(
        Get.find<BienvenidaController>().turno.value,
        TurnoDeLaBienvenida.n1Codigo,
      );
      expect(Get.currentRoute, '/login');
      await avanzar(tester, 4000);
      expect(
        find.text(TextosDeLaBienvenida.rotuloCodigoDeAlumno),
        findsOneWidget,
      );
    });
  });
```

  En `test/bienvenida/bienvenida_registro_test.dart`, suma estos imports y este grupo. Son los
  casos 3 a 7 de `registro_page_test.dart`, que sale, ahora en la conversación. Los casos 1, 2 y
  8 ya los cubren el grupo de la Tarea 27 y la prueba de la app real de arriba.

```dart
import 'package:ulima_plus/pages/bienvenida/bienvenida_page.dart';
```

```dart
  group('lo que probaba la pantalla del registro, ahora en la conversación '
      '(HU33 y RF-BIEN-8)', () {
    setUp(() {
      Get.testMode = true;
      Get.reset();
    });

    /// Monta la bienvenida y deja el registro listo para enviar en N5.
    Future<Bienvenida> montadaEnN5(
      WidgetTester tester, {
      RegistroFalso? registro,
      bool adoptarFalla = false,
    }) async {
      final b = Bienvenida(registro: registro, adoptarFalla: adoptarFalla);
      await montarLaBienvenida(
        tester,
        b,
        argumentos: const {argumentoDeMotivo: MotivoDeLlegada.expirada},
      );
      await avanzar(tester, 1500);
      final c = b.controlador..soyNuevo();
      c.registro!.codigoCtrl.text = '20230001';
      c.enviarCodigoDeAlumno();
      c.registro!
        ..passwordCtrl.text = 'Contrasena1'
        ..confirmacionCtrl.text = 'Contrasena1';
      c.enviarContrasenas();
      c.aceptarConsentimiento();
      c.registro!.portalPasswordCtrl.text = 'clave-de-prueba';
      c.enviarPortal();
      c.registro!.passcodeCtrl.text = '123456';
      await avanzar(tester, 500);
      return b;
    }

    testWidgets('mientras se envía, el atrás no sale y avisa abajo (caso 3)', (
      tester,
    ) async {
      final pendiente = Completer<RegistroResult>();
      final b = await montadaEnN5(
        tester,
        registro: RegistroFalso(pendiente: pendiente),
      );
      unawaited(b.controlador.crearCuenta());
      await avanzar(tester, 300);
      expect(find.text(TextosDeLaBienvenida.pildoraCreando), findsOneWidget);
      final scope = tester.widget<PopScope>(
        find
            .ancestor(
              of: find.text(TextosDeLaBienvenida.pildoraCreando),
              matching: find.byWidgetPredicate((w) => w is PopScope),
            )
            .first,
      );
      expect(scope.canPop, isFalse);
      await Get.key.currentState!.maybePop();
      await tester.pump();
      expect(b.avisos, [TextosDeLaBienvenida.avisoEnvioTitulo]);
      expect(find.byType(BienvenidaPage), findsOneWidget);
      pendiente.completeError(
        const RegistroFailure(
          'No hay conexión. Revisa tu internet e inténtalo de nuevo.',
          code: 'SIN_CONEXION',
        ),
      );
      await avanzar(tester, 3000);
    });

    testWidgets('con el plazo vencido, «No pudimos confirmar…» se lee una vez y '
        'están las dos salidas (casos 4 y 5)', (tester) async {
      final b = await montadaEnN5(
        tester,
        registro: RegistroFalso(
          fallo: const RegistroFailure(
            'No pudimos confirmar si tu cuenta se creó.',
            code: 'TIEMPO_AGOTADO',
          ),
        ),
      );
      await b.controlador.crearCuenta();
      await avanzar(tester, 4000);
      expect(
        find.textContaining('No pudimos confirmar si tu cuenta se creó'),
        findsOneWidget,
      );
      expect(find.text(TextosDeLaBienvenida.iniciarSesion), findsOneWidget);
      expect(find.text(TextosDeLaBienvenida.volverAIntentar), findsOneWidget);
    });

    testWidgets('si el 201 llegó, Ulises no duda de lo que ya se sabe (caso 6)',
        (tester) async {
      final b = await montadaEnN5(tester, adoptarFalla: true);
      await b.controlador.crearCuenta();
      await avanzar(tester, 5000);
      expect(find.text(TextosDeLaBienvenida.creadaTitulo), findsOneWidget);
      expect(find.text(TextosDeLaBienvenida.inciertoTitulo), findsNothing);
    });

    testWidgets('«Iniciar sesión» se apaga mientras el login de rescate está en '
        'vuelo y un segundo toque no pide otro (caso 7)', (tester) async {
      final b = await montadaEnN5(
        tester,
        registro: RegistroFalso(
          fallo: const RegistroFailure('x', code: 'TIEMPO_AGOTADO'),
        ),
      );
      await b.controlador.crearCuenta();
      await avanzar(tester, 4000);
      final puerta = Completer<String?>();
      b.auth.loginPendiente = puerta;
      await tester.tap(find.text(TextosDeLaBienvenida.iniciarSesion));
      await tester.pump();
      expect(find.text(TextosDeLaBienvenida.iniciarSesion), findsNothing);
      expect(
        find.descendant(
          of: find.byType(RespuestaRapida),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byType(RespuestaRapida).last);
      await tester.pump();
      expect(b.auth.logins, 1);
      puerta.complete('Código o contraseña incorrectos.');
      await avanzar(tester, 3000);
      expect(find.text(TextosDeLaBienvenida.iniciarSesion), findsOneWidget);
    });
  });
```

  El archivo ya importa `dart:async`, `registro_models.dart`, `compositor.dart` y
  `session_navigation.dart` desde las Tareas 24 y 27.

  Reescribe `test/HU01_jeff/login_navigation_paths_test.dart` con este contenido. Conserva los
  caminos de hoy, que ahora llegan a E1 con «Sí, entrar» y teclean en el compositor, que usa los
  mismos `TextEditingController` del `LoginController` permanente.

```dart
// test/HU01_jeff/login_navigation_paths_test.dart
//
// Blindaje contra el "TIPEO FANTASMA" en /login. La batería ejercita todos los
// caminos por los que la app llega al login y verifica que los campos
// repintan lo tecleado, es decir, que el LoginController y sus
// TextEditingController siguen vivos y notificando.
//
// ── El bug ────────────────────────────────────────────────────────────────
// Con un binding normal (`Get.lazyPut`), si se navega a /login con
// offAllNamed('/login') y ya había otra ruta /login en el stack, al
// eliminarse la vieja GetX dispone el LoginController asociado a ese tag,
// incluso el que la pantalla visible está usando. En release un
// ChangeNotifier disposed deja de notificar y el TextField repinta tarde. En
// debug y en test revienta con "A TextEditingController was used after being
// disposed". Se manifestó en el flujo login → "¿Olvidaste tu contraseña?" →
// reset → offAllNamed('/login'), con la /login original enterrada.
//
// ── El fix ────────────────────────────────────────────────────────────────
// LoginBinding registra el LoginController como permanente, y desde la
// bienvenida (specs/features/bienvenida) también el BienvenidaController. GetX
// no los dispone por cambios de ruta. Al reingresar se limpian los campos
// (resetFields, después del cuadro).
//
// ── La bienvenida ─────────────────────────────────────────────────────────
// /login muestra la conversación con Ulises. El campo del código vive en el
// compositor de E1, con los TextEditingController del LoginController. Cada
// camino llega a E1 con «Sí, entrar» y teclea ahí. Los servicios son dobles
// sin red y los datos, inventados.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/pages/bienvenida/bienvenida_page.dart';
import 'package:ulima_plus/pages/login/login_binding.dart';
import 'package:ulima_plus/pages/login/login_controller.dart';
import 'package:ulima_plus/services/session_navigation.dart';

import '../bienvenida/apoyo_bienvenida.dart';

/// App de prueba con la ruta /login real (la bienvenida y el LoginBinding
/// real) y páginas simples para las demás rutas de cada camino.
Widget _buildApp({required String initialRoute}) {
  Widget stub(String label) => Scaffold(body: Center(child: Text(label)));
  return GetMaterialApp(
    initialRoute: initialRoute,
    getPages: [
      GetPage(
        name: '/login',
        page: () => const BienvenidaPage(),
        binding: LoginBinding(),
      ),
      GetPage(name: '/forgot-password', page: () => stub('forgot')),
      GetPage(name: '/reset-password', page: () => stub('reset')),
      GetPage(name: '/home', page: () => stub('home')),
      GetPage(name: '/perfil', page: () => stub('perfil')),
      GetPage(name: '/setup-carrera', page: () => stub('setup')),
    ],
  );
}

/// Espera las transiciones de GetX.
Future<void> _transicion(WidgetTester tester) => avanzar(tester, 500);

/// Llega a E1, teclea en el campo del código y verifica que se ve lo
/// tecleado. Si el controller estuviera disposed, reventaría o no repintaría.
Future<void> _typeAndVerify(WidgetTester tester, String texto) async {
  expect(find.byType(BienvenidaPage), findsOneWidget);
  await llegarAE1(tester);
  await tester.enterText(find.byType(TextField).first, texto);
  await tester.pump();
  expect(find.text(texto), findsOneWidget);
}

void main() {
  setUp(registrarLosServiciosDeLaBienvenida);
  tearDown(Get.reset);

  testWidgets(
    'el campo de código usa teclado de TEXTO (el docente/JP ingresa un usuario '
    'alfanumérico como "docente.test", no un código numérico)',
    (tester) async {
      await tester.pumpWidget(_buildApp(initialRoute: '/login'));
      await llegarAE1(tester);

      final codeField = tester.widget<TextField>(find.byType(TextField).first);
      expect(codeField.keyboardType, TextInputType.text);
    },
  );

  testWidgets(
    'Camino 1 — reset desde el login (login → forgot → reset → offAllToLogin): '
    'era el bug; los campos repintan por tecla',
    (tester) async {
      await tester.pumpWidget(_buildApp(initialRoute: '/login'));
      await _transicion(tester);

      // "¿Olvidaste tu contraseña?" apila forgot sobre /login (queda enterrada).
      Get.toNamed('/forgot-password');
      await _transicion(tester);
      Get.toNamed('/reset-password', arguments: {'identifier': '20230000'});
      await _transicion(tester);

      // Reset exitoso, que navega a /login una sola vez.
      expect(offAllToLogin(), isTrue);
      await _transicion(tester);

      await _typeAndVerify(tester, '20230000');
    },
  );

  testWidgets(
    'Camino 2 — reset desde el Perfil (autenticado; /login NO estaba en el stack)',
    (tester) async {
      await tester.pumpWidget(_buildApp(initialRoute: '/home'));
      await _transicion(tester);
      Get.toNamed('/perfil');
      await _transicion(tester);
      Get.toNamed('/reset-password', arguments: {'identifier': '20230000'});
      await _transicion(tester);

      expect(offAllToLogin(), isTrue);
      await _transicion(tester);

      await _typeAndVerify(tester, '20231111');
    },
  );

  testWidgets(
    'Camino 3 — logout normal desde el Perfil (/home → perfil → offAllToLogin)',
    (tester) async {
      await tester.pumpWidget(_buildApp(initialRoute: '/home'));
      await _transicion(tester);
      Get.toNamed('/perfil');
      await _transicion(tester);

      expect(offAllToLogin(), isTrue);
      await _transicion(tester);

      await _typeAndVerify(tester, '20232222');
    },
  );

  testWidgets(
    'Camino 4 - logout del docente (home shell -> offAllToLogin) [TT09]',
    (tester) async {
      await tester.pumpWidget(_buildApp(initialRoute: '/home'));
      await _transicion(tester);

      expect(offAllToLogin(), isTrue);
      await _transicion(tester);

      await _typeAndVerify(tester, 'docente.test');
    },
  );

  testWidgets(
    'Camino 5 — doble navegación (interceptor 401 + logout): la 2ª es no-op',
    (tester) async {
      await tester.pumpWidget(_buildApp(initialRoute: '/perfil'));
      await _transicion(tester);

      expect(offAllToLogin(), isTrue); // 401 en vuelo
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(offAllToLogin(), isFalse); // handler del botón: ya en /login
      await _transicion(tester);

      await _typeAndVerify(tester, '20233333');
    },
  );

  testWidgets('Camino 6 — arranque directo en /login (initialRoute)', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(initialRoute: '/login'));
    await _typeAndVerify(tester, '20234444');
  });

  testWidgets(
    'Camino 7 — login ↔ forgot repetido y luego reset (varias /login enterradas)',
    (tester) async {
      await tester.pumpWidget(_buildApp(initialRoute: '/login'));
      await _transicion(tester);

      // Ir y volver de forgot varias veces (cada ida apila sobre /login).
      for (var i = 0; i < 3; i++) {
        Get.toNamed('/forgot-password');
        await _transicion(tester);
        Get.back();
        await _transicion(tester);
      }
      // Ahora sí completa el reset.
      Get.toNamed('/forgot-password');
      await _transicion(tester);
      Get.toNamed('/reset-password', arguments: {'identifier': '20230000'});
      await _transicion(tester);
      expect(offAllToLogin(), isTrue);
      await _transicion(tester);

      await _typeAndVerify(tester, '20235555');
    },
  );

  testWidgets(
    'resetFields — el login no arrastra lo tecleado por un usuario anterior '
    '(mismo dispositivo, dos usuarios)',
    (tester) async {
      await tester.pumpWidget(_buildApp(initialRoute: '/login'));
      await llegarAE1(tester);

      // Usuario A teclea su código y "pasa" a forgot y reset.
      await tester.enterText(find.byType(TextField).first, 'AAA11111');
      await tester.pump();
      Get.toNamed('/forgot-password');
      await _transicion(tester);
      Get.toNamed('/reset-password', arguments: {'identifier': 'AAA11111'});
      await _transicion(tester);
      offAllToLogin();
      await _transicion(tester);

      // Al volver a /login el campo está limpio y la conversación, vacía.
      expect(find.text('AAA11111'), findsNothing);
      expect(Get.find<LoginController>().codeController.text, '');

      // Usuario B teclea y se ve normal.
      await _typeAndVerify(tester, 'BBB22222');
    },
  );

  testWidgets(
    'passwordVisible — un rebuild por Rx no rompe el campo tras el reset',
    (tester) async {
      await tester.pumpWidget(_buildApp(initialRoute: '/login'));
      await _transicion(tester);
      Get.toNamed('/forgot-password');
      await _transicion(tester);
      Get.toNamed('/reset-password', arguments: {'identifier': '20230000'});
      await _transicion(tester);
      offAllToLogin();
      await _transicion(tester);
      await llegarAE1(tester);
      await llegarAE2(tester);

      // En E2 el compositor muestra solo el campo de la contraseña. El del
      // código sigue montado fuera de la vista, para el autocompletado.
      final controller = Get.find<LoginController>();
      final passwordField = find.byType(TextField).first;
      await tester.enterText(passwordField, 'secreta');
      await tester.pump();
      controller.passwordVisible.toggle();
      await tester.pump();
      await tester.enterText(passwordField, 'secreta123');
      await tester.pump();

      expect(controller.passwordController.text, 'secreta123');
      expect(find.text('secreta123'), findsOneWidget);
    },
  );
}
```

  Reescribe `test/HU01_jeff/login_relogin_regression_test.dart` con este contenido.

```dart
// test/HU01_jeff/login_relogin_regression_test.dart
// Regresión del "tipeo fantasma" tras cerrar sesión (US02 -> US01).
//
// El mecanismo del bug. Al cerrar sesión con un token ya invalidado, el POST
// /auth/logout responde 401 y el interceptor del ApiClient navega a /login
// (Get.currentRoute aún es /perfil, así que su guarda no aplica). Acto
// seguido el handler del botón "Cerrar sesión" navega otra vez a /login. La
// segunda offAllNamed apilaba una segunda ruta /login que tomaba el mismo
// controller, y al desecharse la primera GetX disponía sus
// TextEditingController mientras la página visible los usaba. En debug y en
// test revienta con "A TextEditingController was used after being disposed".
//
// El fix. Todos los caminos que cierran sesión navegan con offAllToLogin()
// (lib/services/session_navigation.dart), que es idempotente. Desde la
// bienvenida, /login muestra la conversación con Ulises y el campo vive en el
// compositor de E1, así que cada prueba llega a E1 con «Sí, entrar».

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/pages/bienvenida/bienvenida_page.dart';
import 'package:ulima_plus/pages/login/login_binding.dart';
import 'package:ulima_plus/pages/login/login_controller.dart';
import 'package:ulima_plus/services/session_navigation.dart';

import '../bienvenida/apoyo_bienvenida.dart';

/// App mínima con la ruta /login real (la bienvenida y el LoginBinding real
/// que main.dart) y un /perfil de prueba desde donde se cierra sesión.
Widget _buildApp() {
  return GetMaterialApp(
    initialRoute: '/perfil',
    getPages: [
      GetPage(
        name: '/login',
        page: () => const BienvenidaPage(),
        binding: LoginBinding(),
      ),
      GetPage(
        name: '/perfil',
        page: () => const Scaffold(body: Center(child: Text('Perfil'))),
      ),
    ],
  );
}

void main() {
  setUp(registrarLosServiciosDeLaBienvenida);
  tearDown(Get.reset);

  testWidgets(
    'doble navegación a /login (interceptor 401 + logout del Perfil): '
    'los campos siguen repintando por tecla',
    (tester) async {
      await tester.pumpWidget(_buildApp());
      await avanzar(tester, 500);

      // 1ª navegación. Un 401 en vuelo durante el logout lleva al login.
      expect(offAllToLogin(), isTrue);
      // La primera /login llega a construirse antes de que el handler del
      // logout retome el control.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // 2ª navegación. El handler del botón "Cerrar sesión" del Perfil es un
      // no-op, porque /login ya es la ruta actual.
      expect(offAllToLogin(), isFalse);
      await avanzar(tester, 500);

      // Solo queda una bienvenida visible.
      expect(find.byType(BienvenidaPage), findsOneWidget);

      // El usuario teclea su código y el texto se ve sin quitar el foco.
      await llegarAE1(tester);
      await tester.enterText(find.byType(TextField).first, '20230001');
      await tester.pump();
      expect(find.text('20230001'), findsOneWidget);
    },
  );

  testWidgets(
    'rebuild provocado por un Rx que envuelve al campo (passwordVisible): '
    'el campo sigue mostrando lo tecleado',
    (tester) async {
      await tester.pumpWidget(_buildApp());
      await avanzar(tester, 500);

      Get.offAllNamed('/login');
      await avanzar(tester, 500);
      await llegarAE1(tester);
      await llegarAE2(tester);

      final controller = Get.find<LoginController>();

      // Teclea en la contraseña de E2, envuelta en Obx por passwordVisible,
      // provoca un rebuild cambiando el Rx y sigue tecleando.
      final passwordField = find.byType(TextField).first;
      await tester.enterText(passwordField, 'secreta');
      await tester.pump();

      controller.passwordVisible.toggle();
      await tester.pump();

      await tester.enterText(passwordField, 'secreta123');
      await tester.pump();

      expect(controller.passwordController.text, 'secreta123');
      expect(find.text('secreta123'), findsOneWidget);
    },
  );
}
```

  En `test/HU34_jeff/registro_consent_test.dart`, quita el import de `registro_page.dart` y la
  función `_app`, suma estos imports y reemplaza el grupo `WIDGET · RegistroPage consentimiento
  (RF-REC-6)` por este. Los grupos unitarios no cambian.

```dart
import 'package:ulima_plus/domain/bienvenida/bienvenida_turnos.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/compositor.dart';
import 'package:ulima_plus/services/session_navigation.dart';

import '../bienvenida/apoyo_bienvenida.dart';
```

```dart
  group('WIDGET · el consentimiento en la conversación (RF-REC-6 y RF-BIEN-7)',
      () {
    setUp(() {
      Get.testMode = true;
      Get.reset();
    });
    tearDown(Get.reset);

    /// Llega a N3 desde E1 con «Soy nuevo» y datos válidos inventados.
    Future<Bienvenida> enN3(WidgetTester tester) async {
      final b = Bienvenida();
      await montarLaBienvenida(
        tester,
        b,
        argumentos: const {argumentoDeMotivo: MotivoDeLlegada.expirada},
      );
      await avanzar(tester, 1500);
      await tester.tap(find.text(TextosDeLaBienvenida.soyNuevo));
      await avanzar(tester, 3000);
      await tester.enterText(find.byType(TextField).first, '20230001');
      await tester.tap(find.byType(BotonDeEnvio));
      await avanzar(tester, 2500);
      await tester.enterText(find.byType(TextField).at(0), 'micontrasena');
      await tester.enterText(find.byType(TextField).at(1), 'micontrasena');
      await tester.tap(find.byType(BotonDeEnvio));
      await avanzar(tester, 3000);
      return b;
    }

    testWidgets('caso 10: tras las contraseñas, el consentimiento va antes '
        'que miUlima', (tester) async {
      await enN3(tester);

      expect(find.text(PortalConsentView.titulo), findsOneWidget);
      expect(find.text(TextosDeLaBienvenida.rotuloPortal), findsNothing);
      expect(find.text(TextosDeLaBienvenida.rotuloAuthenticator), findsNothing,
          reason: 'el código vence en 30 s: no puede esperar a que se lea el aviso');
    });

    testWidgets('caso 11: «Acepto» lleva a la contraseña de miUlima', (
      tester,
    ) async {
      final b = await enN3(tester);

      await tester.tap(find.text(TextosDeLaBienvenida.acepto));
      await avanzar(tester, 2500);

      expect(find.text(TextosDeLaBienvenida.rotuloPortal), findsOneWidget);
      expect(b.controlador.registro!.consentimientoAceptado.value, isTrue);
    });

    testWidgets('caso 12: «Volver» regresa a las contraseñas sin borrar nada',
        (tester) async {
      final b = await enN3(tester);

      await tester.tap(find.text(TextosDeLaBienvenida.volver));
      await avanzar(tester, 2500);

      final c = b.controlador;
      expect(c.turno.value, TurnoDeLaBienvenida.n2Contrasena);
      expect(c.registro!.codigoCtrl.text, equals('20230001'),
          reason: 'salir del consentimiento es retroceder un paso, no empezar de cero');
      expect(c.registro!.passwordCtrl.text, equals('micontrasena'));
    });
  });
```

  En el mismo archivo, el comentario del caso 5 cambia «El alumno no se movió de `/registro`:
  volver a mostrarle la misma pantalla de consentimiento en el mismo intento es ruido.» por «El
  alumno sigue en el mismo registro, y volver a pedirle la aceptación en el mismo intento es
  ruido.», y el del caso 7 cambia «`RegistroBinding` usa `lazyPut` sin `fenix`, así que salir y
  volver a entrar construye otro controller.» por «la bienvenida crea un RegistroController nuevo
  en cada registro y lo cierra al salir.».

- [ ] **Paso 3. Corre las pruebas y confirma que fallan.**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/bienvenida/bienvenida_ruta_test.dart test/bienvenida/bienvenida_registro_test.dart test/HU01_jeff test/HU34_jeff/registro_consent_test.dart
```

Esperado. `/login muestra la bienvenida…` falla, porque `/login` todavía muestra `LoginPage` y
`/registro` sigue en la lista. Las pruebas de `HU01_jeff` fallan con `"BienvenidaController" not
found`, porque `LoginBinding` todavía no la registra. Los casos 3 a 7 y los de `HU34_jeff`
pasan, porque la conversación ya los sostiene.

- [ ] **Paso 4. Registra la bienvenida en `LoginBinding`.** Reemplaza el comentario de cabecera y
  `dependencies` de `lib/pages/login/login_binding.dart`.

```dart
// lib/pages/login/login_binding.dart
// Binding de la ruta /login, que muestra la bienvenida con Ulises.
//
// Registra el LoginController y el BienvenidaController como PERMANENTES
// (decisión B-19 de specs/features/bienvenida). Motivo del LoginController, el
// bug del "tipeo fantasma": con un binding normal (`lazyPut`), cuando se
// navega a /login con offAllToLogin() y ya había otra ruta /login enterrada en
// el stack, al eliminarse esa ruta vieja GetX dispone el LoginController y sus
// TextEditingController, incluso si la pantalla visible los está usando. Al
// ser permanente, GetX no lo dispone por cambios de ruta. Al reingresar se
// limpian los campos (resetFields) para no arrastrar lo tecleado por una
// sesión o un usuario anterior.
//
// El BienvenidaController es permanente por lo mismo. Cada montaje de su
// página es una visita nueva, que la página empieza después de su primer
// cuadro, así que aquí no se reinicia nada. Va después del LoginController,
// que escucha desde su onInit.

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../bienvenida/bienvenida_controller.dart';
import 'login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<LoginController>()) {
      // Reusar la instancia permanente. Se limpian los campos DESPUÉS del
      // frame actual, porque hacerlo durante el binding, que corre en pleno
      // build de la ruta, dispararía "setState() called during build" al
      // notificar al TextField todavía montado de la /login anterior.
      final controller = Get.find<LoginController>();
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => controller.resetFields(),
      );
    } else {
      Get.put(LoginController(), permanent: true);
    }
    if (!Get.isRegistered<BienvenidaController>()) {
      Get.put(BienvenidaController(), permanent: true);
    }
  }
}
```

- [ ] **Paso 5. Cambia `/login` en `main.dart` y saca `/registro`.** En `paginasDeLaApp`, la
  `GetPage` de `/login` queda así, y la de `/registro`, con su comentario de tres líneas, sale.

```dart
        GetPage(
          name: '/login',
          // La bienvenida con Ulises (specs/features/bienvenida, RF-BIEN-1).
          page: () => const BienvenidaPage(),
          // LoginController y BienvenidaController PERMANENTES (ver
          // LoginBinding), que evitan el "tipeo fantasma" cuando se navega a
          // /login con una /login previa aún en el stack (flujo reset de
          // contraseña). Cubre todos los caminos a /login.
          binding: LoginBinding(),
        ),
```

  En los imports, `pages/login/login_page.dart`, `pages/registro/registro_binding.dart` y
  `pages/registro/registro_page.dart` salen, y entra este.

```dart
import 'pages/bienvenida/bienvenida_page.dart';
```

  Borra los tres archivos y la prueba de la pantalla del registro.

```bash
cd "${REPO:?}"
git rm lib/pages/login/login_page.dart lib/pages/registro/registro_page.dart lib/pages/registro/registro_binding.dart test/HU33_jeff/registro_page_test.dart
```

- [ ] **Paso 6. `LoginController` deja de navegar del todo.** En
  `lib/pages/login/login_controller.dart`, borra `submit` y `loginWithGoogle`, que solo usaba la
  tarjeta, y el import de `post_login_route.dart`. En `_onGoogleUserChanged`, borra estas tres
  líneas.

```dart
      // Solo la tarjeta de hoy navega. La Tarea 29 quita estas dos líneas.
      final user = _auth.currentUser;
      if (error == null && user != null) Get.offAllNamed(postLoginRoute(user));
```

- [ ] **Paso 7. Cierra el registro con `cerrar`.** En `lib/pages/registro/registro_controller.dart`,
  `onClose` queda así.

```dart
  @override
  void onClose() {
    // Desde que /registro sale (B-23), ninguna ruta lo registra en GetX, y
    // la bienvenida lo cierra con cerrar(). Si alguien lo registrara, su
    // cierre hace lo mismo.
    cerrar();
    super.onClose();
  }
```

  Y el comentario de `consentimientoAceptado` queda así.

```dart
  /// True cuando el alumno ya tocó «Acepto» en ESTE registro.
  ///
  /// No se guarda en ningún lado (RF-REC-6, «Qué NO entra»). La bienvenida
  /// crea un RegistroController nuevo en cada registro y lo cierra al salir,
  /// así que volver a empezar pide la aceptación de nuevo. Un fallo que
  /// devuelve a `datos` sí la conserva, porque el alumno sigue en el mismo
  /// registro.
```

- [ ] **Paso 8. El botón de Google en web.** En `lib/pages/bienvenida/widgets/compositor.dart`,
  suma estos imports y cambia el `BotonDeGoogle` de `_E1` por esta alternativa. En web,
  `signIn()` no funciona con `google_sign_in` 6.x, así que va el botón oficial de hoy, y la cuenta
  llega a `LoginController` por `onCurrentUserChanged`.

```dart
import 'package:flutter/foundation.dart' show kIsWeb;
```

```dart
import '../../../components/google_sign_in_button.dart';
```

```dart
          if (kIsWeb)
            Center(child: googleSignInButton())
          else
            BotonDeGoogle(
              alTocar: c.esperando.value ? null : c.entrarConGoogle,
            ),
```

- [ ] **Paso 9. Los comentarios que nombran `/registro`.** Cambia estos cuatro.
  1. `portal_consent_view.dart:1-3`, la cabecera, por este texto.

```dart
// lib/components/portal_consent/portal_consent_view.dart
// Pantalla de consentimiento previa a pedirle al alumno la contraseña de
// miUlima. La monta Portal Sync (/portal-sync), y la bienvenida (/login) usa
// sus textos en la tarjeta del consentimiento de la conversación.
```

  2. `portal_consent_view.dart:12-16`, desde «Los dos lugares donde» hasta «que en la otra.», por
     este texto.

```dart
/// pasa con su contraseña **antes** de que la escriba. Portal Sync monta este
/// widget y la bienvenida dibuja su tarjeta con estas mismas constantes, así
/// que los dos lugares donde ULima++ se la pide dicen exactamente lo mismo, y
/// si el alumno acepta en uno, aceptó lo mismo que en el otro.
```

  3. `portal_consent_view.dart:36-38`, el comentario de `exitLabel`, por este texto.

```dart
  /// Texto del enlace para salir, «Ahora no» en Portal Sync.
```

  4. En `auth_service.dart:191-193`, «arrancaría `/registro` de la pila con `offAllToLogin()`»
     pasa a «sacaría a la persona de la conversación del registro con `offAllToLogin()`», y en
     `api_client.dart:33`, «se le sacaría de la pantalla de registro» pasa a «se le sacaría de la
     conversación del registro».

- [ ] **Paso 10. Corre las pruebas y confirma que pasan.**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/main.dart lib/pages/login lib/pages/registro lib/pages/bienvenida lib/components/portal_consent lib/services test/bienvenida test/HU01_jeff test/HU34_jeff
"${FLUTTER:?}" test --no-pub test/bienvenida test/HU01_jeff test/HU02_jeff test/HU33_jeff test/HU34_jeff test/splash
"${FLUTTER:?}" analyze --no-pub
grep -rn "LoginPage\|RegistroPage\|RegistroBinding\|'/registro'" lib test | grep -v "Get.currentRoute == '/LoginPage'" || echo "sin restos"
```

Esperado. `All tests passed!`, los avisos de la base y `sin restos`. La búsqueda deja fuera la
guarda `Get.currentRoute == '/LoginPage'` de `session_navigation.dart`, que se conserva, porque
GetX le da ese nombre a una ruta anónima y la Tarea 33 la da por buena. Esta tarea no la borra. La
guarda de `session_navigation_guard_test.dart` sigue en verde, porque nada nuevo navega a `/login`
fuera de `session_navigation.dart`.

- [ ] **Paso 11. Suite completa y commit.** Corre la suite completa en segundo plano, con el
  comando de «Variables de los comandos». Esperado, `All tests passed!`.

```bash
cd "${REPO:?}"
git status --short
git add lib/main.dart lib/pages/login lib/pages/registro lib/pages/bienvenida/widgets/compositor.dart lib/components/portal_consent/portal_consent_view.dart lib/services/auth_service.dart lib/services/api_client.dart test/bienvenida test/HU01_jeff test/HU34_jeff
git commit -m "feat(bienvenida): /login muestra la bienvenida con LoginBinding, salen la tarjeta del login y la ruta /registro, y las pruebas de hoy pasan a la conversación (RF-BIEN-1, B-19, B-23 y B-25)"
git log -1 --format='%an <%ae>'
```

---

### Tarea 30. El paso al horario, dibujado por la capa, con Ulises que vuela a su burbuja

**Requisitos.** RF-BIEN-11 completo (decisiones B-16 y B-33), la entrada de la capa para la
bienvenida de RF-SPL-4, la semántica del paso de RF-BIEN-16 y el paso con reducir movimiento de
RF-BIEN-15.

**Archivos.**
- Crear `lib/pages/splash/paso_al_horario.dart`.
- Modificar `lib/pages/splash/capa_de_arranque.dart` (la entrada del paso y su fase).
- Modificar `lib/components/chatbot_bubble.dart` (informa su lugar y espera a Ulises).
- Modificar `lib/pages/bienvenida/bienvenida_page.dart` (entrega el paso y navega).
- Modificar `lib/pages/bienvenida/widgets/burbujas.dart` (la clave del último avatar).
- Modificar `test/bienvenida/apoyo_bienvenida.dart` (`montarLaBienvenida` con la capa y otra
  `/home`).
- Crear `test/bienvenida/bienvenida_horario_test.dart`.

**Interfaces.**
- Consume `DestinoDeLaSalida`, `CruzDeSalida` y `MedidaDeCabecera` (Tareas 5 y 10),
  `PuntosDeAterrizaje` (Tarea 5), `EstadoDeLaCapa` (Tarea 6), `offAllSinTransicion` (Tarea 11),
  `abrirEnHorario` (Tarea 6), la capa de las Tareas 12 y 13, `PiezasDelSello` y `PoseDeUlises`
  (Tarea 28) y `pasoHecho` (Tarea 23).
- Produce estas firmas, que usa la Tarea 31.

```dart
// paso_al_horario.dart
class DatosDelPaso { const DatosDelPaso({required Rect franja, required Color colorDeLaFranja,
  required PiezasDelSello sello, required ui.Image? conversacion,
  required Rect lugarDeLaConversacion, required Rect? avatar, required Color colorDeFondo}); }
class EscenaDelPaso { Rect franja; double radioDeLaFranja; Color colorDeLaFranja;
  double opacidadDeLaFranja; double opacidadDeLaConversacion; EscenaDelLogo estrella;
  Offset origenDeUlima; double escalaDeUlima; double fundidoAlTexto; List<CruzDeSalida> cruces;
  double opacidadDeLasCruces; double paginaOpacidad; double paginaDy; PoseDeUlises? ulises;
  bool ulisesPosado; }
double duracionDelPaso({required bool conVuelo});   // 1050, o 1150 + 420 con vuelo
EscenaDelPaso pasoAlHorario({required double ms, required DatosDelPaso datos,
  required DestinoDeLaSalida? destino, required Rect? burbuja, required Size pantalla});
void pintarElPaso(Canvas canvas, EscenaDelPaso escena, DatosDelPaso datos,
  DestinoDeLaSalida? destino);
// capa_de_arranque.dart
static bool CapaDeArranque.empezarElPasoAlHorario(DatosDelPaso datos);
@visibleForTesting static EscenaDelPaso? get CapaDeArranque.pasoActual;
// test/bienvenida/apoyo_bienvenida.dart
montarLaBienvenida(..., bool conCapa = false, Widget Function()? home);
```

- [ ] **Paso 1. Suma la capa y otra `/home` al montaje.** En `test/bienvenida/apoyo_bienvenida.dart`,
  suma el import de la capa y los dos parámetros de `montarLaBienvenida`. El `builder` y la
  `GetPage` de `/home` quedan así.

```dart
import 'package:ulima_plus/pages/splash/capa_de_arranque.dart';
```

```dart
  bool conCapa = false,
  Widget Function()? home,
```

```dart
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(escala)),
        // Con la capa del arranque, como el builder de MyApp (RF-SPL-4).
        child: conCapa ? CapaDeArranque(child: child!) : child!,
      ),
```

```dart
        GetPage(name: '/home', page: home ?? () => const Text('home')),
```

- [ ] **Paso 2. Escribe las pruebas que fallan.** Crea `test/bienvenida/bienvenida_horario_test.dart`.

```dart
// test/bienvenida/bienvenida_horario_test.dart
//
// UNITARIA + WIDGET · Bienvenida con Ulises
// (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-11. El paso al horario como función pura del instante, y la capa
// del arranque que lo dibuja mientras /home se monta debajo, con Ulises que
// vuela a su burbuja, el fundido si la cabecera no se mide y el fundido de
// 220 ms con reducir movimiento (RF-BIEN-15). Durante el paso ningún toque
// llega a /home, que se monta con la capa encima y así sigue en vertical, y
// al llegar desde el splash la burbuja aparece con la página. Todo dato es
// inventado.
// Archivos probados lib/pages/splash/paso_al_horario.dart,
// lib/pages/splash/capa_de_arranque.dart y lib/components/chatbot_bubble.dart.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/chatbot_bubble.dart';
import 'package:ulima_plus/components/logo/sello_del_logo.dart';
import 'package:ulima_plus/domain/bienvenida/bienvenida_turnos.dart';
import 'package:ulima_plus/pages/home/home_page.dart' show abrirEnHorario;
import 'package:ulima_plus/pages/splash/capa_de_arranque.dart';
import 'package:ulima_plus/pages/splash/estado_de_la_capa.dart';
import 'package:ulima_plus/pages/splash/paso_al_horario.dart';
import 'package:ulima_plus/pages/splash/puntos_de_aterrizaje.dart';
import 'package:ulima_plus/pages/splash/salidas.dart';
import 'package:ulima_plus/services/session_navigation.dart';
import 'package:ulima_plus/services/splash_variante_service.dart';

import '../splash/apoyo_splash.dart'
    show
        CargaFalsa,
        HomeDePrueba,
        VariantesFijas,
        appConCapa,
        reiniciarArranque,
        telefono,
        toquesEnLaPagina;
import 'apoyo_bienvenida.dart';

const _pantalla = Size(375, 667);
const _avatar = Rect.fromLTWH(12, 130, 40, 40);
const _burbuja = Rect.fromLTWH(12, 595, 60, 60);
const _colorDeLaCabecera = Color(0xFF1E1E24);

PiezasDelSello _sello() => PiezasDelSello(
  estrella: const Offset(142, 75),
  radio: 15.86,
  ulima: TextPainter(
    text: const TextSpan(text: 'ULIMA', style: TextStyle(fontSize: 24.4)),
    textDirection: TextDirection.ltr,
  )..layout(),
  origenDeUlima: const Offset(168, 61),
  mas: const <Offset>[Offset(252, 70), Offset(264, 70)],
  largoDeLosMas: 12.2,
);

DatosDelPaso _datos({Rect? avatar = _avatar}) => DatosDelPaso(
  franja: const Rect.fromLTWH(0, 0, 375, 102),
  colorDeLaFranja: const Color(0xFFFF6600),
  sello: _sello(),
  conversacion: null,
  lugarDeLaConversacion: const Rect.fromLTWH(0, 102, 375, 565),
  avatar: avatar,
  colorDeFondo: const Color(0xFFF5F5F7),
);

DestinoDeLaSalida _destino() => DestinoDeLaSalida.desdeMedida(
  const MedidaDeCabecera(
    cabecera: Rect.fromLTWH(0, 0, 375, 102),
    estrella: Rect.fromLTWH(20, 52, 26, 26),
    texto: Rect.fromLTWH(56, 55, 90, 20),
    estilo: TextStyle(
      fontSize: 20,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    escalaDeTexto: TextScaler.noScaling,
    color: _colorDeLaCabecera,
    colorDelBorde: Color(0xFF3A3A44),
  ),
  _pantalla,
);

EscenaDelPaso _en(double ms, {Rect? burbuja = _burbuja, Rect? avatar = _avatar}) =>
    pasoAlHorario(
      ms: ms,
      datos: _datos(avatar: avatar),
      destino: _destino(),
      burbuja: burbuja,
      pantalla: _pantalla,
    );

/// Una /home con la cabecera que se informa y la burbuja de Ulises. Su botón
/// «home» cuenta los toques en `toquesEnLaPagina`.
class _HomeConBurbuja extends StatelessWidget {
  const _HomeConBurbuja({this.informa = true});

  final bool informa;

  /// Si la capa cubría la pantalla cuando /home se construyó por primera
  /// vez, que es cuando HomePage decide sus orientaciones (Tarea 6).
  static bool? cubiertaAlMontarse;

  @override
  Widget build(BuildContext context) {
    cubiertaAlMontarse ??= EstadoDeLaCapa.cubre.value;
    return Scaffold(
      body: Stack(
        children: [
          HomeDePrueba(informa: informa),
          const Positioned.fill(child: ChatbotBubble()),
        ],
      ),
    );
  }
}

/// Entra con «Sí, entrar» desde E1, con la capa del arranque en el builder,
/// y vuelve en el cuadro en que la capa toma el paso.
Future<Bienvenida> _hastaElPaso(
  WidgetTester tester, {
  bool informa = true,
  bool sinMovimiento = false,
}) async {
  final b = Bienvenida(auth: AuthDeLaBienvenida(alEntrar: alumnaDePrueba()));
  await montarLaBienvenida(
    tester,
    b,
    argumentos: const {argumentoDeMotivo: MotivoDeLlegada.expirada},
    sinMovimiento: sinMovimiento,
    conCapa: true,
    home: () => _HomeConBurbuja(informa: informa),
  );
  await avanzar(tester, 1500);
  await llegarAE2(tester);
  await tester.enterText(find.byType(TextField).first, 'secreta-de-prueba');
  await tester.tap(find.text(TextosDeLaBienvenida.entrar));
  // E3 entra 650 ms después y el paso empieza 900 ms después de E3.
  for (var t = 0;
      t < 3000 && CapaDeArranque.fase == FaseDeLaCapa.inactiva;
      t += 16) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  expect(CapaDeArranque.fase, isNot(FaseDeLaCapa.inactiva));
  return b;
}

/// La burbuja oculta mientras Ulises vuela, con su GestureDetector dentro.
Finder _burbujaOculta() => find.descendant(
  of: find.byType(ChatbotBubble),
  matching: find.byWidgetPredicate(
    (w) => w is Opacity && w.opacity == 0 && w.child is GestureDetector,
  ),
);

void main() {
  setUp(reiniciarArranque);
  setUp(() => _HomeConBurbuja.cubiertaAlMontarse = null);
  tearDown(reiniciarArranque);

  group('el paso, en funciones puras (RF-BIEN-11)', () {
    test('antes de medir la cabecera, el paso queda en su primer cuadro', () {
      final e = pasoAlHorario(
        ms: 0,
        datos: _datos(),
        destino: null,
        burbuja: null,
        pantalla: _pantalla,
      );
      expect(e.radioDeLaFranja, 26);
      expect(e.franja, const Rect.fromLTWH(0, 0, 375, 102));
      expect(e.estrella.centro, const Offset(142, 75));
      expect(e.opacidadDeLaConversacion, 1);
      expect(e.paginaOpacidad, 0);
    });

    test('las esquinas pasan de 26 dp a 0 en el primer 40 % y el color va al '
        'de la cabecera', () {
      expect(_en(0).radioDeLaFranja, closeTo(26, 1e-9));
      expect(_en(0.4 * 1050).radioDeLaFranja, closeTo(0, 1e-9));
      expect(
        _en(0.4 * 1050).colorDeLaFranja.toARGB32(),
        _colorDeLaCabecera.toARGB32(),
      );
    });

    test('la conversación se desvanece en el primer 35 % y /home aparece del '
        '22 % al 55 %, subiendo 24 dp desde el 32 % hasta el 75 %', () {
      expect(_en(0.35 * 1050).opacidadDeLaConversacion, closeTo(0, 1e-9));
      expect(_en(0.22 * 1050).paginaOpacidad, closeTo(0, 1e-9));
      expect(_en(0.55 * 1050).paginaOpacidad, closeTo(1, 1e-9));
      expect(_en(0.32 * 1050).paginaDy, closeTo(24, 1e-9));
      expect(_en(0.75 * 1050).paginaDy, closeTo(0, 1e-9));
    });

    test('la franja con el sello tapa la cabecera hasta el 70 % y se desvanece '
        'hasta el 100 %', () {
      expect(_en(0.7 * 1050).opacidadDeLaFranja, closeTo(1, 1e-9));
      expect(_en(1050).opacidadDeLaFranja, closeTo(0, 1e-9));
    });

    test('el sello termina en la estrella de 26 dp y en el texto de la '
        'cabecera, y las cruces se funden con los glifos en el último 25 %', () {
      final d = _destino();
      final fin = _en(1050);
      expect(fin.estrella.centro.dx, closeTo(d.estrella.center.dx, 1e-9));
      expect(fin.estrella.centro.dy, closeTo(d.estrella.center.dy, 1e-9));
      expect(fin.estrella.radio, closeTo(13, 1e-9));
      expect(fin.origenDeUlima.dx, closeTo(d.texto.left, 1e-9));
      expect(fin.origenDeUlima.dy, closeTo(d.texto.top, 1e-9));
      for (var i = 0; i < 2; i++) {
        expect(fin.cruces[i].centro.dx, closeTo(d.cruces[i].dx, 1e-9));
        expect(fin.cruces[i].centro.dy, closeTo(d.cruces[i].dy, 1e-9));
      }
      expect(fin.opacidadDeLasCruces, closeTo(0, 1e-9));
      expect(fin.fundidoAlTexto, closeTo(1, 1e-9));
      expect(_en(0.75 * 1050).opacidadDeLasCruces, closeTo(1, 1e-9));
    });

    test('Ulises sale de su avatar, crece hasta 1,6 veces, llega a la burbuja '
        'con 56 dp y se posa en 420 ms', () {
      expect(_en(0).ulises!.centro, _avatar.center);
      expect(_en(0).ulises!.lado, closeTo(40, 1e-9));
      expect(_en(0.45 * 1150).ulises!.lado, closeTo(64, 1e-9));
      final llega = _en(1150);
      expect(llega.ulises!.centro.dx, closeTo(_burbuja.center.dx, 1e-9));
      expect(llega.ulises!.centro.dy, closeTo(_burbuja.center.dy, 1e-9));
      expect(llega.ulises!.lado, closeTo(56, 1e-9));
      expect(llega.ulisesPosado, isFalse);
      expect(_en(1570).ulises, isNull);
      expect(_en(1570).ulisesPosado, isTrue);
      expect(duracionDelPaso(conVuelo: true), 1570);
    });

    test('sin burbuja, como el docente, Ulises se desvanece con la '
        'conversación y el paso dura 1050 ms', () {
      expect(_en(0, burbuja: null).ulises!.opacidad, closeTo(1, 1e-9));
      expect(_en(0.35 * 1050, burbuja: null).ulises!.opacidad, closeTo(0, 1e-9));
      expect(_en(0, burbuja: null).ulisesPosado, isTrue);
      expect(duracionDelPaso(conVuelo: false), 1050);
    });
  });

  group('la capa dibuja el paso (RF-BIEN-11 y B-33)', () {
    testWidgets('la bienvenida entrega el paso, navega a /home en Horario y se '
        'reinicia, y la burbuja espera oculta a Ulises', (tester) async {
      final semantica = tester.ensureSemantics();
      final b = await _hastaElPaso(tester);
      await avanzar(tester, 150);
      expect(CapaDeArranque.fase, FaseDeLaCapa.pasoAlHorario);
      expect(EstadoDeLaCapa.cubre.value, isTrue);
      expect(Get.currentRoute, '/home');
      final home = tester.element(find.byType(HomeDePrueba));
      expect(ModalRoute.of(home)!.settings.arguments, abrirEnHorario);
      expect(b.controlador.entradas, isEmpty);
      expect(b.login.codeController.text, '');
      expect(b.login.passwordController.text, '');
      expect(PuntosDeAterrizaje.ulisesEnVuelo.value, isTrue);
      expect(_burbujaOculta(), findsOneWidget);
      // El lector solo ve «ULIMA++», sin «cargando» (RF-BIEN-16).
      expect(find.bySemanticsLabel('ULIMA++'), findsOneWidget);
      expect(find.bySemanticsLabel(etiquetaDeLaIntro), findsNothing);
      await avanzar(tester, 1700);
      expect(CapaDeArranque.fase, FaseDeLaCapa.inactiva);
      expect(EstadoDeLaCapa.cubre.value, isFalse);
      expect(PuntosDeAterrizaje.ulisesEnVuelo.value, isFalse);
      expect(_burbujaOculta(), findsNothing);
      semantica.dispose();
    });

    testWidgets('durante el paso ningún toque llega a /home, que se monta con '
        'la capa encima y así sigue en vertical, y al retirarse la capa los '
        'toques vuelven (S-26)', (tester) async {
      final orientaciones = <Object?>[];
      final mensajero = tester.binding.defaultBinaryMessenger;
      mensajero.setMockMethodCallHandler(SystemChannels.platform, (llamada) async {
        if (llamada.method == 'SystemChrome.setPreferredOrientations') {
          orientaciones.add(llamada.arguments);
        }
        return null;
      });
      addTearDown(
        () => mensajero.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await _hastaElPaso(tester);
      await avanzar(tester, 150);
      expect(CapaDeArranque.fase, FaseDeLaCapa.pasoAlHorario);
      expect(_HomeConBurbuja.cubiertaAlMontarse, isTrue);
      await tester.tap(find.text('home'), warnIfMissed: false);
      await tester.pump();
      expect(toquesEnLaPagina, 0, reason: 'los toques quedan en la capa');
      expect(orientaciones, isEmpty, reason: 'nada pide girar bajo la capa');
      await avanzar(tester, 1700);
      expect(CapaDeArranque.fase, FaseDeLaCapa.inactiva);
      await tester.tap(find.text('home'));
      await tester.pump();
      expect(toquesEnLaPagina, 1);
    });

    testWidgets('al llegar a /home desde el splash, la burbuja aparece con la '
        'página y no espera a nadie (S-28)', (tester) async {
      telefono(tester);
      final carga = CargaFalsa();
      await tester.pumpWidget(
        appConCapa(
          intro: IntroDelArranque(
            carga: carga.call,
            variantes: VariantesFijas(VarianteSplash.ensamble),
            random: Random(1),
          ),
          home: (_) => const _HomeConBurbuja(),
        ),
      );
      carga.terminar('/home');
      var enLaSalida = false;
      for (var t = 0;
          t < 4000 &&
              (!enLaSalida || CapaDeArranque.fase != FaseDeLaCapa.inactiva);
          t += 16) {
        await tester.pump(const Duration(milliseconds: 16));
        if (CapaDeArranque.fase == FaseDeLaCapa.salida) {
          enLaSalida = true;
          expect(find.byType(ChatbotBubble), findsOneWidget);
          expect(_burbujaOculta(), findsNothing);
          expect(PuntosDeAterrizaje.ulisesEnVuelo.value, isFalse);
        }
      }
      expect(enLaSalida, isTrue);
      expect(CapaDeArranque.fase, FaseDeLaCapa.inactiva);
      expect(_burbujaOculta(), findsNothing);
    });

    testWidgets('si la cabecera no se mide, el paso es un fundido de 300 ms y '
        'la burbuja aparece con la página', (tester) async {
      await _hastaElPaso(tester, informa: false);
      await avanzar(tester, 500);
      expect(CapaDeArranque.fase, FaseDeLaCapa.inactiva);
      expect(PuntosDeAterrizaje.ulisesEnVuelo.value, isFalse);
      expect(_burbujaOculta(), findsNothing);
    });

    testWidgets('con reducir movimiento, /home entera debajo y la capa se '
        'desvanece encima en 220 ms, sin vuelo (RF-BIEN-15)', (tester) async {
      await _hastaElPaso(tester, sinMovimiento: true);
      var visto = false;
      var dura = 0;
      while (dura < 1000 && CapaDeArranque.fase != FaseDeLaCapa.inactiva) {
        visto = visto || PuntosDeAterrizaje.ulisesEnVuelo.value;
        await tester.pump(const Duration(milliseconds: 16));
        dura += 16;
      }
      expect(CapaDeArranque.fase, FaseDeLaCapa.inactiva);
      expect(dura, lessThanOrEqualTo(300));
      expect(visto, isFalse);
    });
  });
}
```

  `HomeDePrueba` informa su cabecera como `AppHeader` y la burbuja informa su lugar sola, así
  que la prueba ejercita el mismo camino que la app.

- [ ] **Paso 3. Corre las pruebas y confirma que fallan.**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/bienvenida/bienvenida_horario_test.dart
```

Esperado. Falla la compilación, porque `paso_al_horario.dart` no existe.

- [ ] **Paso 4. Escribe el paso.** Crea `lib/pages/splash/paso_al_horario.dart`.

```dart
// lib/pages/splash/paso_al_horario.dart
// El paso al horario de la bienvenida (RF-BIEN-11 y decisión B-33). La capa
// del arranque lo dibuja mientras /home se monta debajo. La franja pasa a la
// cabecera, el sello a la estrella y a «ULIMA++» de la cabecera, la
// conversación se desvanece y Ulises vuela de su último avatar a la burbuja.
// Es una función pura del instante, como las salidas de la intro, y un pintor
// la dibuja.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import '../../components/logo/escena_del_logo.dart';
import '../../components/logo/logo_geometria.dart';
import '../../components/logo/pintor_del_logo.dart';
import '../../components/logo/sello_del_logo.dart';
import '../bienvenida/widgets/vuelo_de_ulises.dart' show PoseDeUlises, curvaSeno;
import 'salidas.dart';
import 'variantes/variante_de_intro.dart' show grado, medioSeno, mezcla, tramo;

const double _duracion = 1050;
const double _vuelo = 1150;
const double _aterrizaje = 420;

/// Lo que la bienvenida entrega a la capa antes de navegar (RF-BIEN-11).
class DatosDelPaso {
  const DatosDelPaso({
    required this.franja,
    required this.colorDeLaFranja,
    required this.sello,
    required this.conversacion,
    required this.lugarDeLaConversacion,
    required this.avatar,
    required this.colorDeFondo,
  });

  /// La franja, de borde a borde desde arriba, con sus esquinas de 26 dp.
  final Rect franja;
  final Color colorDeLaFranja;

  /// Las piezas del sello, medidas como las dibuja.
  final PiezasDelSello sello;

  /// La imagen de la conversación y del compositor, que se desvanece. La capa
  /// la descarta al retirarse.
  final ui.Image? conversacion;
  final Rect lugarDeLaConversacion;

  /// El último avatar de Ulises en la conversación, de donde sale a volar.
  final Rect? avatar;

  /// El fondo de la conversación, que también tapa el avatar en la imagen.
  final Color colorDeFondo;
}

class EscenaDelPaso {
  const EscenaDelPaso({
    required this.franja,
    required this.radioDeLaFranja,
    required this.colorDeLaFranja,
    required this.opacidadDeLaFranja,
    required this.opacidadDeLaConversacion,
    required this.estrella,
    required this.origenDeUlima,
    required this.escalaDeUlima,
    required this.fundidoAlTexto,
    required this.cruces,
    required this.opacidadDeLasCruces,
    required this.paginaOpacidad,
    required this.paginaDy,
    required this.ulises,
    required this.ulisesPosado,
  });

  final Rect franja;
  final double radioDeLaFranja;
  final Color colorDeLaFranja;

  /// La franja tapa la cabecera real hasta el 70 % y se desvanece hasta el
  /// 100 %, salvo detrás de la estrella y del texto, que llegan dibujados.
  final double opacidadDeLaFranja;
  final double opacidadDeLaConversacion;
  final EscenaDelLogo estrella;

  /// «ULIMA» del sello, que viaja y se achica hasta el texto de la cabecera.
  final Offset origenDeUlima;
  final double escalaDeUlima;

  /// El texto de la cabecera, «ULIMA++», que entra en el último 25 %.
  final double fundidoAlTexto;
  final List<CruzDeSalida> cruces;
  final double opacidadDeLasCruces;
  final double paginaOpacidad;
  final double paginaDy;

  /// Ulises en vuelo, o null si ya se posó en la burbuja.
  final PoseDeUlises? ulises;

  /// Ulises ya está en la burbuja, o no vuela.
  final bool ulisesPosado;
}

/// El paso dura 1050 ms, y con Ulises en vuelo, hasta que se posa.
double duracionDelPaso({required bool conVuelo}) =>
    conVuelo ? _vuelo + _aterrizaje : _duracion;

Offset _cubica(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
  final s = 1 - t;
  return p0 * (s * s * s) +
      p1 * (3 * s * s * t) +
      p2 * (3 * s * t * t) +
      p3 * (t * t * t);
}

EscenaDelPaso pasoAlHorario({
  required double ms,
  required DatosDelPaso datos,
  required DestinoDeLaSalida? destino,
  required Rect? burbuja,
  required Size pantalla,
}) {
  final d = destino;
  final s = datos.sello;
  // Sin la cabecera medida, el paso queda en su primer cuadro.
  final t = d == null ? 0.0 : tramo(ms, 0, _duracion);
  final e = Curves.easeInOutCubic.transform(t);
  final esquinas = Curves.easeInOutCubic.transform(tramo(t, 0, 0.4));
  final conversacion = 1 - tramo(t, 0, 0.35);
  final cuerpo = Curves.easeOutCubic.transform(tramo(t, 0.32, 0.75));
  final (ulises, posado) = _ulisesAlHorario(
    d == null ? 0 : ms,
    datos.avatar,
    burbuja,
    pantalla,
    conversacion,
  );
  return EscenaDelPaso(
    franja: d == null ? datos.franja : Rect.lerp(datos.franja, d.cabecera, e)!,
    radioDeLaFranja: 26 * (1 - esquinas),
    colorDeLaFranja: Color.lerp(
      datos.colorDeLaFranja,
      d?.color ?? datos.colorDeLaFranja,
      esquinas,
    )!,
    opacidadDeLaFranja: 1 - tramo(t, 0.7, 1),
    opacidadDeLaConversacion: conversacion,
    estrella: EscenaDelLogo(
      centro: d == null ? s.estrella : Offset.lerp(s.estrella, d.estrella.center, e)!,
      radio: d == null ? s.radio : mezcla(s.radio, d.estrella.width / 2, e),
    ),
    origenDeUlima: d == null
        ? s.origenDeUlima
        : Offset.lerp(s.origenDeUlima, d.texto.topLeft, e)!,
    escalaDeUlima: d == null
        ? 1
        : mezcla(1, d.pintorDeUlima.height / s.ulima.height, e),
    fundidoAlTexto: tramo(t, 0.75, 1),
    cruces: <CruzDeSalida>[
      for (var i = 0; i < s.mas.length; i++)
        CruzDeSalida(
          // Los «++» van con un salto de 6 dp.
          centro:
              (d == null ? s.mas[i] : Offset.lerp(s.mas[i], d.cruces[i], e)!) -
              Offset(0, 6 * medioSeno(e)),
          largo: d == null
              ? s.largoDeLosMas
              : mezcla(s.largoDeLosMas, d.tamanoDeCruz, e),
          giro: SelloDelLogo.inclinacionDeLosMas,
        ),
    ],
    opacidadDeLasCruces: 1 - tramo(t, 0.75, 1),
    paginaOpacidad: tramo(t, 0.22, 0.55),
    paginaDy: 24 * (1 - cuerpo),
    ulises: ulises,
    ulisesPosado: posado,
  );
}

/// Ulises sale de su último avatar, vuela en 1150 ms con la curva seno por la
/// derecha y hacia arriba, y baja a la burbuja. Crece hasta 1,6 veces en el
/// primer 45 %, se achica hasta 56 dp con un aleteo que se apaga y una
/// inclinación de hasta 12°, y se posa en 420 ms con un aplastamiento. Sin
/// burbuja, como el docente, se desvanece con la conversación.
(PoseDeUlises?, bool) _ulisesAlHorario(
  double ms,
  Rect? avatar,
  Rect? burbuja,
  Size pantalla,
  double opacidadDeLaConversacion,
) {
  if (avatar == null) return (null, true);
  if (burbuja == null) {
    return (
      PoseDeUlises(
        centro: avatar.center,
        lado: avatar.width,
        opacidad: opacidadDeLaConversacion,
      ),
      true,
    );
  }
  if (ms >= _vuelo + _aterrizaje) return (null, true);
  final hasta = burbuja.center;
  if (ms >= _vuelo) {
    final u = tramo(ms, _vuelo, _vuelo + _aterrizaje);
    final onda = math.sin(2 * math.pi * u) * (1 - u);
    return (
      PoseDeUlises(
        centro: hasta,
        lado: 56,
        escalaX: 1 + 0.18 * onda,
        escalaY: 1 - 0.18 * onda,
      ),
      false,
    );
  }
  final t = tramo(ms, 0, _vuelo);
  final desde = avatar.center;
  final inicial = avatar.width;
  final lado = t <= 0.45
      ? mezcla(inicial, 1.6 * inicial, Curves.easeOutCubic.transform(t / 0.45))
      : mezcla(
          1.6 * inicial,
          56,
          Curves.easeInOutCubic.transform(tramo(t, 0.45, 1)),
        );
  return (
    PoseDeUlises(
      centro: _cubica(
        desde,
        Offset(pantalla.width * 0.88, desde.dy - 0.2 * pantalla.height),
        Offset(hasta.dx + 0.35 * pantalla.width, hasta.dy - 0.3 * pantalla.height),
        hasta,
        curvaSeno(t),
      ),
      lado: lado,
      giro: 12 * grado * medioSeno(t),
      escalaY: 1 - 0.1 * math.sin(6 * math.pi * t).abs() * (1 - t),
    ),
    false,
  );
}

Paint _conOpacidad(double opacidad) =>
    Paint()..color = Color.fromRGBO(0, 0, 0, opacidad.clamp(0.0, 1.0));

/// Pinta el paso sobre /home. Ulises va aparte, como un widget en su capa.
void pintarElPaso(
  Canvas canvas,
  EscenaDelPaso e,
  DatosDelPaso datos,
  DestinoDeLaSalida? destino,
) {
  // La conversación y el compositor, sobre su fondo, sin el avatar del que
  // sale Ulises.
  if (e.opacidadDeLaConversacion > 0) {
    canvas.saveLayer(null, _conOpacidad(e.opacidadDeLaConversacion));
    final lugar = datos.lugarDeLaConversacion;
    canvas.drawRect(lugar, Paint()..color = datos.colorDeFondo);
    final imagen = datos.conversacion;
    if (imagen != null) {
      canvas.drawImageRect(
        imagen,
        Offset.zero & Size(imagen.width.toDouble(), imagen.height.toDouble()),
        lugar,
        Paint()..filterQuality = FilterQuality.medium,
      );
    }
    final avatar = datos.avatar;
    if (avatar != null) {
      canvas.drawCircle(
        avatar.center,
        avatar.width / 2 + 1,
        Paint()..color = datos.colorDeFondo,
      );
    }
    canvas.restore();
  }

  // La franja, que ya es la cabecera. Detrás de la estrella y del texto
  // queda entera, porque los dibujados caen sobre los reales.
  final esquina = Radius.circular(e.radioDeLaFranja);
  final franja = RRect.fromRectAndCorners(
    e.franja,
    bottomLeft: esquina,
    bottomRight: esquina,
  );
  final pintura = Paint()..color = e.colorDeLaFranja;
  if (destino == null || e.opacidadDeLaFranja >= 1) {
    canvas.drawRRect(franja, pintura);
  } else {
    final piezas = Path()
      ..addRect(destino.estrella.inflate(4))
      ..addRect(destino.texto.inflate(4));
    canvas.save();
    canvas.clipPath(piezas);
    canvas.drawRRect(franja, pintura);
    canvas.restore();
    canvas.save();
    canvas.clipPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(e.franja.inflate(1)),
        piezas,
      ),
    );
    canvas.drawRRect(
      franja,
      Paint()
        ..color = e.colorDeLaFranja.withValues(alpha: e.opacidadDeLaFranja),
    );
    canvas.restore();
  }

  // «ULIMA» del sello, que viaja, y el texto de la cabecera al final.
  if (e.fundidoAlTexto < 1) {
    canvas.saveLayer(null, _conOpacidad(1 - e.fundidoAlTexto));
    canvas.translate(e.origenDeUlima.dx, e.origenDeUlima.dy);
    canvas.scale(e.escalaDeUlima);
    datos.sello.ulima.paint(canvas, Offset.zero);
    canvas.restore();
  }
  if (destino != null && e.fundidoAlTexto > 0) {
    canvas.saveLayer(null, _conOpacidad(e.fundidoAlTexto));
    destino.pintorDeUlima.paint(canvas, destino.texto.topLeft);
    destino.pintorDeLosMas.paint(
      canvas,
      destino.texto.topLeft + Offset(destino.anchoDeUlima, 0),
    );
    canvas.restore();
  }

  pintarEscena(canvas, e.estrella);

  // Los «++» dibujados, que se funden con los glifos en el último 25 %.
  if (e.opacidadDeLasCruces > 0) {
    final blanco = Paint()
      ..isAntiAlias = true
      ..color = const Color(0xFFFFFFFF).withValues(alpha: e.opacidadDeLasCruces);
    final (h, v) = LogoGeometria.barrasDeCruz();
    for (final c in e.cruces) {
      canvas.save();
      canvas.translate(c.centro.dx, c.centro.dy);
      canvas.rotate(c.giro);
      canvas.scale(c.largo / LogoGeometria.largoDeCruz);
      canvas.drawRect(h, blanco);
      canvas.drawRect(v, blanco);
      canvas.restore();
    }
  }
}
```

- [ ] **Paso 5. La entrada del paso en la capa.** En `lib/pages/splash/capa_de_arranque.dart`, haz
  estos cambios.

  1. Suma los imports.

```dart
import '../bienvenida/widgets/vuelo_de_ulises.dart' show PoseDeUlises;
import 'paso_al_horario.dart';
```

  2. Suma a `CapaDeArranque` la entrada y un getter para las pruebas.

```dart
  /// La bienvenida entrega el paso al horario antes de navegar a /home
  /// (RF-BIEN-11 y B-33). Devuelve false si la capa no está montada o ya
  /// cubre la pantalla, y entonces la bienvenida navega igual.
  static bool empezarElPasoAlHorario(DatosDelPaso datos) =>
      _estado?._empezarElPaso(datos) ?? false;

  @visibleForTesting
  static EscenaDelPaso? get pasoActual => _estado?._escenaDelPaso.value;
```

  3. Suma estos campos al `State` y cambia `_etiqueta`. Durante el paso, el lector solo ve
     «ULIMA++», sin «cargando» (RF-BIEN-16).

```dart
  DatosDelPaso? _paso;
  final ValueNotifier<EscenaDelPaso?> _escenaDelPaso =
      ValueNotifier<EscenaDelPaso?>(null);
  Rect? _burbuja;
  bool _conVuelo = false;
```

```dart
  String get _etiqueta => _paso != null ? 'ULIMA++' : etiquetaDeLaIntro;
```

  4. En `_alTic`, `FaseDeLaCapa.pasoAlHorario` sale del grupo que no hace nada y pasa a su caso.

```dart
      case FaseDeLaCapa.pasoAlHorario:
        _avanzarElPaso();
```

  5. Suma estos métodos.

```dart
  bool _empezarElPaso(DatosDelPaso datos) {
    if (!mounted || _fase.value != FaseDeLaCapa.inactiva) return false;
    _paso = datos;
    _vista = MediaQuery.sizeOf(context);
    _sinMovimiento = MediaQuery.disableAnimationsOf(context);
    PuntosDeAterrizaje.cabecera.value = null;
    PuntosDeAterrizaje.burbuja.value = null;
    _destinoDeLaSalida = null;
    _burbuja = null;
    _conVuelo = false;
    _cuadrosEsperando = 0;
    _opacidad.value = 1;
    // /home se mide quieta y aparece desde el 22 % (RF-BIEN-11). Con reducir
    // movimiento se monta entera debajo (RF-BIEN-15).
    _corrimientoDeLaPagina.value = Offset.zero;
    _opacidadDeLaPagina.value = _sinMovimiento ? 1 : 0;
    _escenaDelPaso.value = pasoAlHorario(
      ms: 0,
      datos: datos,
      destino: null,
      burbuja: null,
      pantalla: _vista,
    );
    EstadoDeLaCapa.cubre.value = true;
    _fase.value = FaseDeLaCapa.pasoAlHorario;
    _ahora = Duration.zero;
    _inicioDeFase = Duration.zero;
    _reloj.start();
    return true;
  }

  void _avanzarElPaso() {
    final datos = _paso!;
    if (Get.currentRoute != '/home') {
      // La ruta de debajo cambió, por ejemplo por un 401, o la bienvenida no
      // pudo navegar.
      _cuadrosEsperando++;
      if (_destinoDeLaSalida != null || _cuadrosEsperando > 3) {
        _fundirElPaso(300);
      }
      return;
    }
    if (_sinMovimiento) {
      _fundirElPaso(220);
      return;
    }
    var destino = _destinoDeLaSalida;
    if (destino == null) {
      // Espera el primer cuadro de /home y la medida de su cabecera, a lo
      // sumo tres cuadros, como la salida de la intro.
      final medida = PuntosDeAterrizaje.cabecera.value;
      if (medida == null) {
        _cuadrosEsperando++;
        if (_cuadrosEsperando > 3) _fundirElPaso(300);
        return;
      }
      destino = DestinoDeLaSalida.desdeMedida(medida, _vista);
      _destinoDeLaSalida = destino;
      _burbuja = PuntosDeAterrizaje.burbuja.value;
      // La burbuja espera oculta a Ulises solo en este paso (B-16).
      _conVuelo = _burbuja != null && datos.avatar != null;
      if (_conVuelo) PuntosDeAterrizaje.ulisesEnVuelo.value = true;
      _inicioDeFase = _ahora;
    }
    final ms = _msDeFase;
    final e = pasoAlHorario(
      ms: ms,
      datos: datos,
      destino: destino,
      burbuja: _conVuelo ? _burbuja : null,
      pantalla: _vista,
    );
    _escenaDelPaso.value = e;
    _corrimientoDeLaPagina.value = Offset(0, e.paginaDy);
    _opacidadDeLaPagina.value = e.paginaOpacidad;
    if (e.ulisesPosado && PuntosDeAterrizaje.ulisesEnVuelo.value) {
      // En el cuadro en que Ulises se posa aparece la burbuja real.
      PuntosDeAterrizaje.ulisesEnVuelo.value = false;
    }
    if (ms >= duracionDelPaso(conVuelo: _conVuelo)) _retirar();
  }

  /// Un fundido cruzado sobre /home, ya montada debajo, así que la estrella
  /// de su cabecera se ve durante todo el fundido (RF-BIEN-11).
  void _fundirElPaso(double duracion) {
    PuntosDeAterrizaje.ulisesEnVuelo.value = false;
    _empezarElFundido(duracion);
  }
```

  6. `_retirar` suma, antes de cambiar la fase, el descarte de la imagen y del paso.

```dart
    // La imagen de la conversación se descarta al retirarse (RF-BIEN-11).
    _paso?.conversacion?.dispose();
    _paso = null;
    _escenaDelPaso.value = null;
    PuntosDeAterrizaje.ulisesEnVuelo.value = false;
```

  7. En `dispose`, suma `_escenaDelPaso.dispose();`.

  8. En `build`, el hijo del `AbsorbPointer` de la capa activa pasa a ser un `Stack` con el pintor
     y con Ulises.

```dart
                  child: AbsorbPointer(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomPaint(
                          size: Size.infinite,
                          painter: _PintorDeLaCapa(this),
                        ),
                        _UlisesDelPaso(escena: _escenaDelPaso),
                      ],
                    ),
                  ),
```

  9. En `_PintorDeLaCapa`, suma `capa._escenaDelPaso` a la lista de `Listenable.merge`, y en
     `paint` reemplaza desde `final salida = capa._salida.value;` hasta el cierre del `else` por
     esto, que pinta el paso antes que la salida.

```dart
    final paso = capa._escenaDelPaso.value;
    final datos = capa._paso;
    final salida = capa._salida.value;
    final destino = capa._destinoDeLaSalida;
    if (paso != null && datos != null) {
      pintarElPaso(canvas, paso, datos, destino);
    } else if (salida != null && destino != null) {
      // La salida, o su fundido si la ruta cambió en medio.
      pintarSalida(canvas, salida, destino);
    } else {
      canvas.drawRect(Offset.zero & size, Paint()..color = naranjaDelSplash);
      final escena = capa._escena.value;
      if (escena != null) pintarEscena(canvas, escena);
    }
```

  10. Al final del archivo, suma a Ulises del paso.

```dart
/// Ulises en el paso al horario, en una capa aislada, como en el
/// recibimiento (RF-BIEN-18).
class _UlisesDelPaso extends StatelessWidget {
  const _UlisesDelPaso({required this.escena});

  final ValueNotifier<EscenaDelPaso?> escena;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<EscenaDelPaso?>(
    valueListenable: escena,
    builder: (context, e, _) {
      final PoseDeUlises? pose = e?.ulises;
      if (pose == null || pose.opacidad <= 0) return const SizedBox.shrink();
      return Stack(
        children: [
          Positioned(
            left: pose.centro.dx - pose.lado / 2,
            top: pose.centro.dy - pose.lado / 2,
            child: RepaintBoundary(
              child: Opacity(
                opacity: pose.opacidad.clamp(0.0, 1.0),
                child: Transform.rotate(
                  angle: pose.giro,
                  child: Transform.scale(
                    scaleX: pose.escalaX,
                    scaleY: pose.escalaY,
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/ulises_chatbot.png',
                        width: pose.lado,
                        height: pose.lado,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
```

- [ ] **Paso 6. La burbuja informa su lugar y espera a Ulises.** En
  `lib/components/chatbot_bubble.dart`, suma el import, la clave y el aviso, y envuelve el
  `GestureDetector` para que la burbuja quede oculta mientras Ulises vuela hacia ella.

```dart
import '../pages/splash/puntos_de_aterrizaje.dart';
```

```dart
  final GlobalKey _clave = GlobalKey();
  bool _informada = false;

  /// Informa su lugar inicial una vez, después de su primer cuadro, como la
  /// cabecera informa su estrella (RF-BIEN-11).
  void _informar() {
    final caja = _clave.currentContext?.findRenderObject() as RenderBox?;
    if (!mounted || caja == null || !caja.hasSize) return;
    PuntosDeAterrizaje.burbuja.value =
        caja.localToGlobal(Offset.zero) & caja.size;
  }
```

  En `build`, después de calcular `pos`, pide el aviso la primera vez.

```dart
        if (!_informada) {
          _informada = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => _informar());
        }
```

  Y el hijo del `Positioned` queda así, con la clave en el `GestureDetector`.

```dart
              // Oculta solo mientras la capa trae a Ulises en el paso al
              // horario. En cualquier otra llegada aparece con la página
              // (decisiones S-28 y B-16).
              child: ValueListenableBuilder<bool>(
                valueListenable: PuntosDeAterrizaje.ulisesEnVuelo,
                builder: (context, enVuelo, hijo) =>
                    Opacity(opacity: enVuelo ? 0 : 1, child: hijo),
                child: GestureDetector(
                  key: _clave,
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Get.toNamed('/chatbot'),
                  onPanStart: (_) => setState(() => _dragging = true),
                  onPanUpdate: (d) => setState(() {
                    _pos = Offset(
                      clampX(pos.dx + d.delta.dx),
                      clampY(pos.dy + d.delta.dy),
                    );
                  }),
                  onPanEnd: (_) => setState(() {
                    _dragging = false;
                    // Snap al borde horizontal más cercano; conserva la altura.
                    final goRight = (_pos!.dx + bubble / 2) > maxW / 2;
                    _pos = Offset(
                      goRight ? (maxW - bubble - _margin) : _margin,
                      clampY(_pos!.dy),
                    );
                  }),
                  child: _BubbleVisual(
                    pulse: _pulse,
                    size: bubble,
                    dragging: _dragging,
                  ),
                ),
              ),
```

- [ ] **Paso 7. La bienvenida entrega el paso y navega.** En
  `lib/pages/bienvenida/widgets/burbujas.dart`, `EntradaView` suma
  `final GlobalKey? claveDelAvatar;` en su constructor, lo pasa a `_BurbujaDeUlises`, que suma el
  mismo campo, y el `SizedBox` del avatar recibe `key: claveDelAvatar`.

  En `lib/pages/bienvenida/bienvenida_page.dart`, suma estos imports.

```dart
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
```

```dart
import '../home/home_page.dart' show abrirEnHorario;
import '../splash/paso_al_horario.dart' show DatosDelPaso;
```

  Suma los campos.

```dart
  final GlobalKey _claveDeLaConversacion = GlobalKey();
  final GlobalKey _claveDelUltimoAvatar = GlobalKey();
  bool _pasoEmpezado = false;
```

  Al final de `_alRevelar`, empieza el paso cuando el revelador abre el turno del paso, 900 ms
  después de E3, en el cuadro siguiente, así que la imagen sale ya pintada.

```dart
    if (_revelador.compositorVisible &&
        _c.turno.value == TurnoDeLaBienvenida.pasoAlHorario) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _empezarElPaso());
    }
```

  Suma estos métodos.

```dart
  /// Entrega a la capa la franja, el sello, a Ulises en su último avatar y
  /// una imagen de la conversación, navega a /home en Horario sin transición
  /// y reinicia la conversación (RF-BIEN-11).
  void _empezarElPaso() {
    if (_pasoEmpezado || !mounted) return;
    _pasoEmpezado = true;
    final datos = _datosDelPaso();
    final entregado =
        datos != null && CapaDeArranque.empezarElPasoAlHorario(datos);
    if (!entregado) datos?.conversacion?.dispose();
    offAllSinTransicion('/home', arguments: abrirEnHorario);
    _c.pasoHecho();
  }

  DatosDelPaso? _datosDelPaso() {
    final sello = PiezasDelSello.medir(context, _claveDelSello);
    final caja =
        _claveDeLaConversacion.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (sello == null || caja == null || !caja.hasSize) return null;
    final b = Theme.brightnessOf(context);
    final avatar =
        _claveDelUltimoAvatar.currentContext?.findRenderObject() as RenderBox?;
    return DatosDelPaso(
      franja: Rect.fromLTWH(
        0,
        0,
        MediaQuery.sizeOf(context).width,
        CabeceraConSello.alto(context),
      ),
      colorDeLaFranja: MaterialTheme.bienvenidaFranja(b),
      sello: sello,
      conversacion: _imagen(caja),
      lugarDeLaConversacion: caja.localToGlobal(Offset.zero) & caja.size,
      avatar: avatar == null || !avatar.hasSize
          ? null
          : avatar.localToGlobal(Offset.zero) & avatar.size,
      colorDeFondo: MaterialTheme.pageBg(b),
    );
  }

  /// Si la plataforma no puede capturar la imagen, la capa pinta solo el
  /// fondo de la conversación, que se desvanece igual.
  ui.Image? _imagen(RenderRepaintBoundary caja) {
    try {
      return caja.toImageSync(
        pixelRatio: MediaQuery.devicePixelRatioOf(context),
      );
    } on Object {
      return null;
    }
  }
```

  Suma también `import 'dart:ui' as ui;` para el tipo de la imagen.

  Reemplaza `_conversacion` por esta versión. La lista y el compositor van dentro de un
  `RepaintBoundary` con la clave, y el primer avatar del último grupo de Ulises recibe la clave
  del avatar. Lo demás es lo de las Tareas 26 a 28.

```dart
  Widget _conversacion(BuildContext context, {required bool atendida}) {
    final visibles = atendida ? _revelador.visibles : 0;
    final entradas = _c.entradas;
    final turno = _c.turno.value;
    final primerIdDeUlises = entradas
        .whereType<BurbujaDeUlises>()
        .map((e) => e.id)
        .firstOrNull;
    final cuantas = visibles.clamp(0, entradas.length);
    // El primer avatar del último grupo de Ulises, de donde sale a volar en
    // el paso al horario (RF-BIEN-11).
    var ultimoAvatar = -1;
    for (var i = 0; i < cuantas; i++) {
      if (entradas[i] is BurbujaDeUlises &&
          (i == 0 || entradas[i - 1] is! BurbujaDeUlises)) {
        ultimoAvatar = i;
      }
    }
    return Column(
      children: [
        FranjaConSello(
          latido: _latido,
          rombos: _rombos,
          claveDelSello: _claveDelSello,
          selloVisible: _selloVisible,
        ),
        Expanded(
          child: RepaintBoundary(
            key: _claveDeLaConversacion,
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: ListView.builder(
                        controller: _desplazamiento,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                        itemCount: cuantas,
                        itemBuilder: (context, i) {
                          final entrada = entradas[i];
                          final primerGrupo = _enElPrimerGrupo(
                            entradas,
                            i,
                            primerIdDeUlises,
                          );
                          return EntradaView(
                            key: ValueKey<int>(entrada.id),
                            entrada: entrada,
                            anterior: i > 0 ? entradas[i - 1] : null,
                            primerGrupo: primerGrupo,
                            ocultarAvatar: primerGrupo && !_avatarVisible,
                            claveDelAvatar: i == ultimoAvatar
                                ? _claveDelUltimoAvatar
                                : null,
                            conMovimiento: !_sinMovimiento,
                            resultado: (context) =>
                                ResultadoEnLaConversacion(c: _c),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                if (atendida && turno != null && _revelador.compositorVisible)
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: _CompositorAnimado(
                        key: ValueKey<TurnoDeLaBienvenida>(turno),
                        conMovimiento: !_sinMovimiento,
                        child: compositorDelTurno(context, _c, turno),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
```

- [ ] **Paso 8. Corre las pruebas y confirma que pasan.**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/pages/splash lib/components/chatbot_bubble.dart lib/pages/bienvenida test/bienvenida
"${FLUTTER:?}" test --no-pub test/bienvenida test/splash test/HU23_jeff
"${FLUTTER:?}" analyze --no-pub
```

Esperado. `All tests passed!` y los avisos de la base. `test/HU23_jeff` monta `ChatbotBubble` en
el shell, y sigue en verde porque la burbuja solo se oculta mientras `ulisesEnVuelo` vale `true`.

- [ ] **Paso 9. Suite completa y commit.** Corre la suite completa en segundo plano. Esperado,
  `All tests passed!`.

```bash
cd "${REPO:?}"
git status --short
git add lib/pages/splash lib/components/chatbot_bubble.dart lib/pages/bienvenida test/bienvenida
git commit -m "feat(bienvenida): el paso al horario lo dibuja la capa del arranque, con la franja que pasa a la cabecera, el sello a su estrella y Ulises que vuela a su burbuja (RF-BIEN-11, B-16 y B-33)"
git log -1 --format='%an <%ae>'
```

---

### Tarea 31. Reducir movimiento y el lector de pantalla en la bienvenida

**Requisitos.** RF-BIEN-15 en el recibimiento, «Si no cabe», la subida al sello, el sello, la
píldora, el cursor y la llegada con sesión (el paso al horario ya lo cubre la Tarea 30), y
RF-BIEN-16 en el recibimiento, la llegada con sesión, cada turno, los controles, los blancos
táctiles, el teclado físico, con el orden de foco y el anillo de 2 dp en `bienvenidaFoco` de los
botones, las píldoras y los enlaces, y el tamaño de texto con 1,0, 1,3 y 2,0.

**Archivos.**
- Modificar `lib/pages/bienvenida/widgets/recibimiento.dart`.
- Modificar `lib/pages/bienvenida/bienvenida_page.dart`.
- Modificar `lib/pages/bienvenida/widgets/burbujas.dart` (el foco del lector).
- Modificar `lib/pages/bienvenida/widgets/franja_con_sello.dart` (la píldora quieta).
- Modificar `lib/pages/bienvenida/widgets/compositor.dart` (la acción de toque y el anillo de foco
  de cada control).
- Crear `lib/pages/bienvenida/widgets/anillo_de_foco.dart`.
- Crear `test/bienvenida/bienvenida_movimiento_test.dart`.
- Crear `test/bienvenida/bienvenida_accesibilidad_test.dart`.

**Interfaces.**
- Consume el recibimiento (Tarea 28), la página (Tareas 26 a 30), `montarLaBienvenida` con
  `conLector` y `sinMovimiento` (Tarea 26) y `llegarAE2` (Tarea 29).
- Produce estas firmas, que usa la Tarea 33 en la verificación.

```dart
// recibimiento.dart
abstract final class TiemposSinMovimiento { cruceDeLaEstrella 220; ulises 120;
  fundidoDeUlises 160; fondo 150; tarjeta 280; botones 660; fundido 180;
  cruceDeLaSubida 220; fundidoDelAvatar 140 }
static ({Color fondo, EscenaDelLogo? estrella, EscenaDelLogo? estrellaDebajo,
  double opacidadDeLaEstrella, int puntos}) Recibimiento.cuadroActual(BuildContext context);
// burbujas.dart
EntradaView({..., bool enfocar = false});
// anillo_de_foco.dart
class AnilloDeFoco extends StatefulWidget { const AnilloDeFoco({required BorderRadius radio,
  required Widget child}); }
```

- [ ] **Paso 1. Escribe las pruebas que fallan.** Crea
  `test/bienvenida/bienvenida_movimiento_test.dart`.

```dart
// test/bienvenida/bienvenida_movimiento_test.dart
//
// WIDGET · Bienvenida con Ulises (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-15. Con reducir movimiento nada se mueve, gira ni cambia de escala,
// y cada cambio del logo es un fundido cruzado que deja siempre un logo a la
// vista. Las pausas del ritmo se quedan.
// Archivos probados lib/pages/bienvenida/widgets/recibimiento.dart y
// lib/pages/bienvenida/bienvenida_page.dart.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/logo/escena_del_logo.dart';
import 'package:ulima_plus/components/logo/sello_del_logo.dart';
import 'package:ulima_plus/domain/bienvenida/bienvenida_turnos.dart';
import 'package:ulima_plus/models/registro_models.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/compositor.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/franja_con_sello.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/recibimiento.dart';
import 'package:ulima_plus/services/session_navigation.dart';

import 'apoyo_bienvenida.dart';

Map<String, Object> _conPose() => <String, Object>{
  argumentoDePose: EscenaDelLogo.reposo(
    centro: const Offset(187.5, 333.5),
    radio: 90,
  ).pose,
};

const _expirada = <String, Object>{argumentoDeMotivo: MotivoDeLlegada.expirada};

Finder _ulises() => find.byKey(Recibimiento.claveDeUlises);

double _opacidadDeUlises(WidgetTester tester) => tester
    .widget<Opacity>(
      find.ancestor(of: _ulises(), matching: find.byType(Opacity)).first,
    )
    .opacity;

({Color fondo, EscenaDelLogo? estrella, EscenaDelLogo? estrellaDebajo,
    double opacidadDeLaEstrella, int puntos})
_cuadro(WidgetTester tester) => Recibimiento.cuadroActual(
  tester.element(find.byKey(Recibimiento.claveDelFondo)),
);

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  testWidgets('Ulises no vuela: aparece en su lugar con un fundido de 160 ms, '
      '120 ms después del relevo, sin sombra, estela ni partículas', (
    tester,
  ) async {
    await montarLaBienvenida(
      tester,
      Bienvenida(),
      argumentos: _conPose(),
      sinMovimiento: true,
    );
    await avanzar(tester, 80);
    expect(_ulises(), findsNothing);
    await avanzar(tester, 120);
    expect(tester.getSize(_ulises()).width, 70);
    expect(_opacidadDeUlises(tester), inExclusiveRange(0, 1));
    expect(_cuadro(tester).puntos, 0);
    await avanzar(tester, 150);
    expect(_opacidadDeUlises(tester), 1);
    expect(_cuadro(tester).puntos, 0);
  });

  testWidgets('la tarjeta y los botones aparecen con fundidos de 180 ms, sin '
      'desplazamiento, y los toques cuentan desde los botones', (tester) async {
    final b = Bienvenida();
    await montarLaBienvenida(
      tester,
      b,
      argumentos: _conPose(),
      sinMovimiento: true,
    );
    await avanzar(tester, 360);
    final escala = tester.widget<Transform>(
      find
          .ancestor(
            of: find.byKey(Recibimiento.claveDeLaTarjeta),
            matching: find.byType(Transform),
          )
          .first,
    );
    expect(escala.transform, Matrix4.identity());
    await avanzar(tester, 400);
    expect(find.byKey(Recibimiento.claveDeLosBotones), findsOneWidget);
    await tester.tap(find.text(TextosDeLaBienvenida.siEntrar));
    await tester.pump();
    expect(b.delAlumno, [TextosDeLaBienvenida.siEntrar]);
    await avanzar(tester, 2000);
  });

  testWidgets('si RF-BIEN-2 sube la estrella, la nueva aparece encima en '
      '220 ms y la del centro sigue entera debajo hasta quedar cubierta', (
    tester,
  ) async {
    await montarLaBienvenida(
      tester,
      Bienvenida(),
      argumentos: _conPose(),
      sinMovimiento: true,
      escala: 2,
    );
    await avanzar(tester, 100);
    final cuadro = _cuadro(tester);
    expect(cuadro.estrellaDebajo, isNotNull);
    expect(cuadro.estrellaDebajo!.pose.centro, const Offset(187.5, 333.5));
    expect(cuadro.estrellaDebajo!.pose.radio, 90);
    expect(cuadro.estrella!.pose.centro.dy, lessThan(333.5));
    expect(cuadro.opacidadDeLaEstrella, inExclusiveRange(0, 1));
    await avanzar(tester, 200);
    expect(_cuadro(tester).estrellaDebajo, isNull);
    expect(_cuadro(tester).opacidadDeLaEstrella, 1);
  });

  testWidgets('al responder, la franja con el sello y la conversación '
      'aparecen encima en 220 ms mientras el recibimiento sigue entero '
      'debajo, y Ulises pasa a su avatar en 140 ms', (tester) async {
    await montarLaBienvenida(
      tester,
      Bienvenida(),
      argumentos: _conPose(),
      sinMovimiento: true,
    );
    await avanzar(tester, 900);
    await tester.tap(find.text(TextosDeLaBienvenida.siEntrar));
    await avanzar(tester, 100);
    expect(find.byType(Recibimiento), findsOneWidget);
    final cuadro = _cuadro(tester);
    expect(cuadro.estrella!.pose.radio, 90, reason: 'entero debajo');
    final encima = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.byType(FranjaConSello),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(encima.opacity.value, inExclusiveRange(0, 1));
    expect(_opacidadDeUlises(tester), lessThan(1));
    await avanzar(tester, 200);
    expect(find.byType(Recibimiento), findsNothing);
    expect(find.byType(SelloDelLogo), findsOneWidget);
  });

  testWidgets('el sello no late, no hay pulso y la píldora queda quieta', (
    tester,
  ) async {
    final pendiente = Completer<RegistroResult>();
    final b = Bienvenida(registro: RegistroFalso(pendiente: pendiente));
    await montarLaBienvenida(
      tester,
      b,
      argumentos: _expirada,
      sinMovimiento: true,
    );
    await avanzar(tester, 1500);
    final sello = tester.widget<SelloDelLogo>(find.byType(SelloDelLogo));
    await tester.enterText(find.byType(TextField).first, '20230001');
    await tester.tap(find.byType(BotonDeEnvio));
    await avanzar(tester, 200);
    expect(sello.latido!.value, 0);
    final c = b.controlador..soyNuevo();
    c.registro!.codigoCtrl.text = '20230001';
    c.enviarCodigoDeAlumno();
    c.registro!
      ..passwordCtrl.text = 'Contrasena1'
      ..confirmacionCtrl.text = 'Contrasena1';
    c.enviarContrasenas();
    c.aceptarConsentimiento();
    c.registro!.portalPasswordCtrl.text = 'clave-de-prueba';
    c.enviarPortal();
    c.registro!.passcodeCtrl.text = '123456';
    unawaited(c.crearCuenta());
    await avanzar(tester, 300);
    expect(sello.rombos!.value, isNull);
    final indicador = tester.widget<CircularProgressIndicator>(
      find.descendant(
        of: find.byType(PildoraDelRegistro),
        matching: find.byType(CircularProgressIndicator),
      ),
    );
    expect(indicador.value, isNotNull);
    pendiente.completeError(
      const RegistroFailure(
        'No hay conexión. Revisa tu internet e inténtalo de nuevo.',
        code: 'SIN_CONEXION',
      ),
    );
    await avanzar(tester, 3000);
  });

  testWidgets('el cursor del campo no parpadea mientras la bienvenida está '
      'montada, y vuelve a como estaba al salir', (tester) async {
    await montarLaBienvenida(
      tester,
      Bienvenida(),
      argumentos: _expirada,
      sinMovimiento: true,
    );
    await avanzar(tester, 1500);
    expect(EditableText.debugDeterministicCursor, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(EditableText.debugDeterministicCursor, isFalse);
  });
}
```

  Crea `test/bienvenida/bienvenida_accesibilidad_test.dart`.

```dart
// test/bienvenida/bienvenida_accesibilidad_test.dart
//
// WIDGET · Bienvenida con Ulises (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-16. Con lector de pantalla, la tarjeta y los botones aparecen con
// el relevo y el foco pasa a la tarjeta, la llegada con sesión empieza con el
// relevo, las burbujas de un turno entran juntas y el foco pasa a la primera
// nueva de Ulises. Los controles son botones con su texto y miden al menos
// 48 dp. Con teclado físico, el foco va del campo al botón de envío y después
// a los enlaces, con el anillo de 2 dp en bienvenidaFoco en los botones, las
// píldoras y los enlaces. Intro envía y nada desborda con el texto al 100, 130
// y 200 %.
// Archivos probados lib/pages/bienvenida/widgets/recibimiento.dart,
// lib/pages/bienvenida/widgets/burbujas.dart y
// lib/pages/bienvenida/bienvenida_page.dart.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/logo/escena_del_logo.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/domain/bienvenida/bienvenida_turnos.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/anillo_de_foco.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/compositor.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/recibimiento.dart';
import 'package:ulima_plus/services/session_navigation.dart';

import 'apoyo_bienvenida.dart';

Map<String, Object> _conPose() => <String, Object>{
  argumentoDePose: EscenaDelLogo.reposo(
    centro: const Offset(187.5, 333.5),
    radio: 90,
  ).pose,
};

const _expirada = <String, Object>{argumentoDeMotivo: MotivoDeLlegada.expirada};

/// El anillo de 2 dp que rodea un control con el foco del teclado.
final _anilloEncendido = Border.all(
  color: MaterialTheme.bienvenidaFoco(Brightness.light),
  width: 2,
);

/// Muestra el foco como con teclado físico, también después de un toque, y
/// deja el modo de siempre al terminar la prueba.
void _conTecladoFisico() {
  FocusManager.instance.highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;
  addTearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );
}

Future<void> _tab(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pump();
}

/// Si el foco del teclado está dentro de [control].
bool _enfocado(Finder control) {
  final contexto = FocusManager.instance.primaryFocus?.context;
  if (contexto == null) return false;
  return find
      .descendant(
        of: control,
        matching: find.byElementPredicate((e) => identical(e, contexto)),
      )
      .evaluate()
      .isNotEmpty;
}

/// El borde del anillo de foco que envuelve el texto [texto], o null si no
/// se ve.
Border? _anilloSobre(WidgetTester tester, String texto) => _borde(
  tester,
  find
      .ancestor(of: find.text(texto), matching: find.byType(AnilloDeFoco))
      .first,
);

/// El borde del anillo de foco dentro de [control], o null si no se ve.
Border? _anilloDe(WidgetTester tester, Finder control) => _borde(
  tester,
  find.descendant(of: control, matching: find.byType(AnilloDeFoco)).first,
);

Border? _borde(WidgetTester tester, Finder anillo) {
  final caja = tester.widget<DecoratedBox>(
    find.descendant(of: anillo, matching: find.byType(DecoratedBox)).first,
  );
  return (caja.decoration as BoxDecoration).border as Border?;
}

/// Guarda lo que la app le manda al lector por el canal de accesibilidad.
List<Map<Object?, Object?>> _escucharAlLector(WidgetTester tester) {
  final eventos = <Map<Object?, Object?>>[];
  final mensajero = tester.binding.defaultBinaryMessenger;
  mensajero.setMockDecodedMessageHandler<dynamic>(
    SystemChannels.accessibility,
    (mensaje) async {
      if (mensaje is Map) eventos.add(mensaje);
      return null;
    },
  );
  addTearDown(
    () => mensajero.setMockDecodedMessageHandler<dynamic>(
      SystemChannels.accessibility,
      null,
    ),
  );
  return eventos;
}

Iterable<Object?> _focos(List<Map<Object?, Object?>> eventos) => eventos
    .where((e) => e['type'] == 'focus')
    .map((e) => e['nodeId']);

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  testWidgets('con lector, la tarjeta y los botones aparecen con el relevo, el '
      'foco pasa a la tarjeta y los toques cuentan enseguida', (tester) async {
    final semantica = tester.ensureSemantics();
    final eventos = _escucharAlLector(tester);
    final b = Bienvenida();
    await montarLaBienvenida(
      tester,
      b,
      argumentos: _conPose(),
      conLector: true,
    );
    await avanzar(tester, 50);
    final tarjeta = find.byKey(Recibimiento.claveDeLaTarjeta);
    expect(tarjeta, findsOneWidget);
    expect(find.byKey(Recibimiento.claveDeLosBotones), findsOneWidget);
    expect(_focos(eventos), contains(tester.getSemantics(tarjeta).id));
    expect(
      tester.getSemantics(tarjeta),
      containsSemantics(label: '¡Craa! Hola, soy Ulises. ¿Ya usas ULima++?'),
    );
    await tester.tap(find.text(TextosDeLaBienvenida.siEntrar));
    await tester.pump();
    expect(b.delAlumno, [TextosDeLaBienvenida.siEntrar]);
    await avanzar(tester, 2000);
    semantica.dispose();
  });

  testWidgets('los dos botones del recibimiento son botones con su texto y '
      'miden al menos 48 dp', (tester) async {
    final semantica = tester.ensureSemantics();
    await montarLaBienvenida(tester, Bienvenida(), argumentos: _conPose());
    await avanzar(tester, 3000);
    for (final texto in [
      TextosDeLaBienvenida.siEntrar,
      TextosDeLaBienvenida.soyNuevo,
    ]) {
      expect(
        tester.getSemantics(find.bySemanticsLabel(texto)),
        containsSemantics(label: texto, isButton: true, hasTapAction: true),
      );
    }
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    semantica.dispose();
  });

  testWidgets('los controles del compositor son botones que el lector puede '
      'tocar, y miden al menos 48 dp', (tester) async {
    final semantica = tester.ensureSemantics();
    await montarLaBienvenida(tester, Bienvenida(), argumentos: _expirada);
    await avanzar(tester, 1500);
    await tester.enterText(find.byType(TextField).first, '20230001');
    await tester.pump();
    for (final texto in [
      TextosDeLaBienvenida.enviar,
      TextosDeLaBienvenida.continuarConGoogle,
      TextosDeLaBienvenida.soyNuevo,
    ]) {
      expect(
        tester.getSemantics(find.bySemanticsLabel(texto)),
        containsSemantics(label: texto, isButton: true, hasTapAction: true),
      );
    }
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    semantica.dispose();
  });

  testWidgets('con lector y sesión, la conversación empieza con el relevo y '
      'el foco pasa a la primera burbuja de Ulises', (tester) async {
    final semantica = tester.ensureSemantics();
    final eventos = _escucharAlLector(tester);
    final b = Bienvenida(
      auth: AuthDeLaBienvenida(usuario: alumnaDePrueba(setupComplete: false)),
      token: 'jwt-de-prueba',
    );
    await montarLaBienvenida(tester, b, conLector: true);
    await avanzar(tester, 200);
    expect(find.byKey(Recibimiento.claveDeLaTarjeta), findsNothing);
    expect(find.text(TextosDeLaBienvenida.saludoConSesion), findsOneWidget);
    expect(_focos(eventos), isNotEmpty);
    await avanzar(tester, 3000);
    semantica.dispose();
  });

  testWidgets('con lector, las burbujas de un turno entran juntas y el foco '
      'pasa a la primera nueva de Ulises', (tester) async {
    final semantica = tester.ensureSemantics();
    final eventos = _escucharAlLector(tester);
    await montarLaBienvenida(
      tester,
      Bienvenida(),
      argumentos: _expirada,
      conLector: true,
    );
    await avanzar(tester, 50);
    expect(find.text(TextosDeLaBienvenida.saludo), findsOneWidget);
    expect(find.text(TextosDeLaBienvenida.e1), findsOneWidget);
    final antes = _focos(eventos).length;
    expect(antes, greaterThan(0));
    await tester.enterText(find.byType(TextField).first, '20230001');
    await tester.tap(find.byType(BotonDeEnvio));
    await avanzar(tester, 100);
    expect(find.text(TextosDeLaBienvenida.e2), findsOneWidget);
    expect(_focos(eventos).length, greaterThan(antes));
    semantica.dispose();
  });

  testWidgets('el campo no toma el foco solo con lector, e Intro envía', (
    tester,
  ) async {
    final b = Bienvenida();
    await montarLaBienvenida(
      tester,
      b,
      argumentos: _expirada,
      conLector: true,
    );
    await avanzar(tester, 600);
    final campo = tester.widget<TextField>(find.byType(TextField).first);
    expect(campo.autofocus, isFalse);
    await tester.enterText(find.byType(TextField).first, '20230001');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(b.delAlumno, ['20230001']);
    await avanzar(tester, 2000);
  });

  testWidgets('con teclado físico, el foco va del campo al botón de envío y '
      'después a los enlaces, y el anillo de 2 dp en bienvenidaFoco sigue al '
      'foco en E1 y en E2', (tester) async {
    _conTecladoFisico();
    final b = Bienvenida();
    await montarLaBienvenida(tester, b, argumentos: _expirada);
    await avanzar(tester, 1500);
    final soyNuevo = find.widgetWithText(
      EnlaceSecundario,
      TextosDeLaBienvenida.soyNuevo,
    );

    // E1. El campo, el botón de envío, «Continuar con Google» y «Soy nuevo».
    await tester.enterText(find.byType(TextField).first, '20230001');
    await tester.pump();
    expect(_enfocado(find.byType(CampoDelCompositor)), isTrue);
    await _tab(tester);
    expect(_enfocado(find.byType(BotonDeEnvio)), isTrue);
    expect(_anilloDe(tester, find.byType(BotonDeEnvio)), _anilloEncendido);
    await _tab(tester);
    expect(_enfocado(find.byType(BotonDeGoogle)), isTrue);
    expect(_anilloDe(tester, find.byType(BotonDeEnvio)), isNull);
    expect(_anilloDe(tester, find.byType(BotonDeGoogle)), _anilloEncendido);
    await _tab(tester);
    expect(_enfocado(soyNuevo), isTrue);
    expect(_anilloDe(tester, soyNuevo), _anilloEncendido);

    // E2. El campo con su ojo, «Entrar», «¿Olvidaste tu contraseña?» y «Soy
    // nuevo». El campo del código que sigue montado no toma el foco.
    await tester.tap(find.byType(BotonDeEnvio));
    await avanzar(tester, 2000);
    await tester.enterText(find.byType(TextField).first, 'secreta-de-prueba');
    await tester.pump();
    await _tab(tester);
    expect(_enfocado(find.byType(OjoDeLaContrasena)), isTrue);
    expect(_anilloDe(tester, find.byType(OjoDeLaContrasena)), _anilloEncendido);
    await _tab(tester);
    expect(_enfocado(find.byType(BotonPrincipal)), isTrue);
    expect(_anilloDe(tester, find.byType(BotonPrincipal)), _anilloEncendido);
    await _tab(tester);
    final olvidaste = find.widgetWithText(
      EnlaceSecundario,
      TextosDeLaBienvenida.olvidaste,
    );
    expect(_enfocado(olvidaste), isTrue);
    expect(_anilloDe(tester, olvidaste), _anilloEncendido);
    await _tab(tester);
    expect(_enfocado(soyNuevo), isTrue);
  });

  testWidgets('el anillo de foco rodea también los dos botones del '
      'recibimiento y las píldoras, y un toque no lo enciende', (tester) async {
    _conTecladoFisico();
    await montarLaBienvenida(tester, Bienvenida(), argumentos: _conPose());
    await avanzar(tester, 3000);
    expect(_anilloSobre(tester, TextosDeLaBienvenida.siEntrar), isNull);
    await _tab(tester);
    expect(_anilloSobre(tester, TextosDeLaBienvenida.siEntrar), _anilloEncendido);
    await _tab(tester);
    expect(_anilloSobre(tester, TextosDeLaBienvenida.siEntrar), isNull);
    expect(_anilloSobre(tester, TextosDeLaBienvenida.soyNuevo), _anilloEncendido);

    const tema = MaterialTheme(TextTheme());
    await tester.pumpWidget(
      MaterialApp(
        theme: tema.light(),
        home: Scaffold(
          body: Center(
            child: RespuestasRapidas(
              respuestas: [
                RespuestaRapida(
                  texto: TextosDeLaBienvenida.volver,
                  alTocar: () {},
                ),
                RespuestaRapida(
                  texto: TextosDeLaBienvenida.acepto,
                  alTocar: () {},
                  principal: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await _tab(tester);
    expect(_anilloSobre(tester, TextosDeLaBienvenida.volver), _anilloEncendido);
    await _tab(tester);
    expect(_anilloSobre(tester, TextosDeLaBienvenida.volver), isNull);
    expect(_anilloSobre(tester, TextosDeLaBienvenida.acepto), _anilloEncendido);

    // Con el tacto, el foco no se ve (FocusHighlightMode.touch).
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTouch;
    await tester.pump();
    expect(_anilloSobre(tester, TextosDeLaBienvenida.acepto), isNull);
  });

  for (final escala in <double>[1.0, 1.3, 2.0]) {
    testWidgets('con el texto al ${(escala * 100).round()} % en 375 × 667, E1 '
        'y E2 no desbordan', (tester) async {
      await montarLaBienvenida(
        tester,
        Bienvenida(),
        argumentos: _expirada,
        escala: escala,
      );
      await avanzar(tester, 1500);
      expect(tester.takeException(), isNull);
      await llegarAE2(tester);
      expect(tester.takeException(), isNull);
    });
  }
}
```

- [ ] **Paso 2. Corre las pruebas y confirma que fallan.**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/bienvenida/bienvenida_movimiento_test.dart test/bienvenida/bienvenida_accesibilidad_test.dart
```

Esperado. Falla la compilación, porque `cuadroActual` no trae `estrellaDebajo` ni `puntos` y
`anillo_de_foco.dart` no existe. Sin eso, fallan las de movimiento, porque Ulises vuela, las del
lector, porque la tarjeta espera el aterrizaje y nadie mueve el foco, y las del teclado físico,
porque ningún control dibuja el anillo.

- [ ] **Paso 3. Reducir movimiento y el lector en el recibimiento.** En
  `lib/pages/bienvenida/widgets/recibimiento.dart`, haz estos cambios.

  1. Suma el import y los tiempos sin movimiento, después de `TiemposDelRecibimiento`.

```dart
import 'package:flutter/semantics.dart' show FocusSemanticEvent;
```

```dart
/// Los tiempos con reducir movimiento en ms, desde el relevo, y los tres
/// últimos desde la respuesta (RF-BIEN-15).
abstract final class TiemposSinMovimiento {
  static const double cruceDeLaEstrella = 220;
  static const double ulises = 120;
  static const double fundidoDeUlises = 160;
  static const double fondo = 150;
  static const double tarjeta = 280;
  static const double botones = 660;
  static const double fundido = 180;
  static const double cruceDeLaSubida = 220;
  static const double fundidoDelAvatar = 140;
}

typedef _S = TiemposSinMovimiento;
```

  2. `cuadroActual` devuelve también la estrella de debajo y los puntos.

```dart
  @visibleForTesting
  static ({
    Color fondo,
    EscenaDelLogo? estrella,
    EscenaDelLogo? estrellaDebajo,
    double opacidadDeLaEstrella,
    int puntos,
  })
  cuadroActual(BuildContext context) {
    final estado = context.findAncestorStateOfType<_RecibimientoState>()!;
    final p = estado._pintor(estado.context);
    return (
      fondo: p.color,
      estrella: p.estrella,
      estrellaDebajo: p.estrellaDebajo,
      opacidadDeLaEstrella: p.opacidadDeLaEstrella,
      puntos: p.estela.length + p.particulas.length + (p.sombra == null ? 0 : 1),
    );
  }
```

  3. En el `State`, suma el cruce de la estrella, los modos y los instantes que dependen de ellos.

```dart
  double _cruceDeLaEstrella = 1;

  bool get _sinMovimiento => MediaQuery.disableAnimationsOf(context);
  bool get _conLector => MediaQuery.accessibleNavigationOf(context);

  /// Con lector, la tarjeta y los botones aparecen con el relevo (RF-BIEN-16).
  /// Sin movimiento, Ulises aparece en su lugar y la tarjeta y los botones
  /// entran con fundidos (RF-BIEN-15).
  double get _msDeMedida => _conLector || _sinMovimiento ? 0 : _T.quieto;
  double get _msDeLaTarjeta =>
      _conLector ? 0 : (_sinMovimiento ? _S.tarjeta : _T.finDelRebote);
  double get _msDeLosBotones =>
      _conLector ? 0 : (_sinMovimiento ? _S.botones : _T.botones);
  double get _finDeLaEntrada => _conLector
      ? 0
      : (_sinMovimiento ? _S.botones + _S.fundido : _T.botones + 400);
  double get _finDeLaSubida =>
      _sinMovimiento ? _S.cruceDeLaSubida : _T.finDeLaSubida;
  double get _posado => _sinMovimiento ? _S.cruceDeLaSubida : _T.posado;
```

  4. Suma `didUpdateWidget`. La visita se atiende en los primeros milisegundos, así que con
     lector la sesión puede llegar con la tarjeta ya puesta.

```dart
  @override
  void didUpdateWidget(Recibimiento anterior) {
    super.didUpdateWidget(anterior);
    if (widget.conSesion && !anterior.conSesion && _fase == _Fase.saludo) {
      // El reloj vuelve a correr y el próximo cuadro sigue sin tarjeta.
      _reloj.muted = false;
    }
  }
```

  5. Reemplaza `_alTic`, `_moverLaEstrella`, `_alTerminarElRebote` y `_responder` por estos.

```dart
  void _alTic(Duration t) {
    _ms = t.inMicroseconds / 1000;
    if (_medidas == null && _ms >= _msDeMedida) _medir();
    switch (_fase) {
      case _Fase.llegada:
        if (_medidas == null) break;
        _moverLaEstrella();
        if (_ms >= _msDeLaTarjeta) _alTerminarElRebote();
      case _Fase.saludo:
        if (widget.conSesion) {
          // La llegada con sesión no lleva tarjeta ni botones (RF-BIEN-21).
          _conTarjeta = false;
          widget.alAterrizarConSesion();
          _subir(_ms);
        } else if (_ms >= _finDeLaEntrada) {
          // Con todo quieto, el reloj calla y no pide cuadros (RF-BIEN-18).
          _reloj.muted = true;
        }
      case _Fase.subida:
        // Tras un toque en reposo, la subida cuenta desde este cuadro.
        _respuestaEn ??= _ms;
        if (!_sinMovimiento) {
          _destino ??= PiezasDelSello.medir(context, widget.claveDelSello);
        }
        final desde = _ms - _respuestaEn!;
        if (!_selloPosado && desde >= _finDeLaSubida) {
          _selloPosado = true;
          widget.alPosarseElSello();
        }
        if (desde >= _posado) {
          _fase = _Fase.fin;
          _reloj.stop();
          widget.alTerminar();
          return;
        }
      case _Fase.fin:
        return;
    }
    setState(() {});
  }

  /// Si Ulises y la tarjeta no caben, la estrella sube, y si hace falta se
  /// achica, lo justo antes de que Ulises aterrice, en 300 ms (B-28). Sin
  /// movimiento no se desliza, y la nueva aparece encima en 220 ms mientras la
  /// del centro sigue entera debajo (RF-BIEN-15).
  void _moverLaEstrella() {
    final m = _medidas!;
    if (widget.conSesion || m.enConversacion) return;
    if (_sinMovimiento) {
      _estrella = m.estrella;
      _radio = m.radio;
      _cruceDeLaEstrella = tramo(_ms, 0, _S.cruceDeLaEstrella);
      return;
    }
    final t = Curves.easeInOutCubic.transform(
      tramo(_ms, _T.aterrizaje - 300, _T.aterrizaje),
    );
    _estrella = Offset.lerp(widget.pose.centro, m.estrella, t)!;
    _radio = mezcla(widget.pose.radio, m.radio, t);
  }

  void _alTerminarElRebote() {
    if (widget.conSesion) {
      // El fin del rebote hace de respuesta, sin el asentimiento, y con
      // lector la conversación empieza con el relevo (RF-BIEN-16 y
      // RF-BIEN-21).
      widget.alAterrizarConSesion();
      _subir(_msDeLaTarjeta);
    } else if (_medidas!.enConversacion) {
      // Ni achicando la estrella caben, así que Ulises saluda ya en la
      // conversación (B-28).
      widget.alSaludarEnLaConversacion();
      _subir(_msDeLaTarjeta);
    } else {
      _conTarjeta = true;
      _fase = _Fase.saludo;
    }
  }

  void _responder(bool yaUsa) {
    // Los toques cuentan desde que los botones empiezan a entrar.
    if (_fase != _Fase.saludo || _ms < _msDeLosBotones) return;
    widget.alResponder(yaUsa);
    // En reposo el reloj calla y _ms quedó en el último cuadro, así que la
    // subida cuenta desde el primer cuadro después del toque.
    final enReposo = _reloj.muted;
    _reloj.muted = false;
    _subir(enReposo ? null : _ms);
  }
```

  6. En `_pintor`, el fondo, la estrella de debajo, la sombra y la subida cambian así. La línea
     de `cambio` pasa a ser esta.

```dart
    // El fondo pasa en 1100 ms con la curva seno mientras Ulises vuela, o
    // en 150 ms sin movimiento (RF-BIEN-2 y RF-BIEN-15).
    final quieto = _sinMovimiento;
    final cambio = quieto
        ? tramo(_ms, _S.ulises, _S.ulises + _S.fondo)
        : curvaSeno(tramo(_ms, _T.quieto, _T.quieto + 1100));
```

  Después de `quieta`, suma la estrella de debajo.

```dart
    // Sin movimiento, la estrella del centro sigue entera debajo mientras la
    // nueva aparece encima.
    final seMovio =
        _estrella != widget.pose.centro || _radio != widget.pose.radio;
    final debajo = quieto && seMovio && _cruceDeLaEstrella < 1
        ? EscenaDelLogo.desdePose(widget.pose)
        : null;
```

  La sombra empieza con `quieto ||` en su condición, `var sombra = quieto || a == null || vuelo < 0`,
  y la subida solo se dibuja con movimiento, porque sin él el recibimiento sigue entero debajo de
  la conversación que aparece encima.

```dart
    if (respuesta != null && !quieto) {
```

  Y el pintor recibe la estrella de debajo y su cruce, y ni la estela ni las partículas sin
  movimiento.

```dart
    return _PintorDelRecibimiento(
      fondo: fondo,
      color: Color.lerp(naranjaDelSplash, franja, cambio)!,
      radio: radio,
      estrella: estrella,
      estrellaDebajo: debajo,
      opacidadDeLaEstrella: debajo == null ? 1 : _cruceDeLaEstrella,
      sombra: sombra,
      estela: quieto || a == null || puntos == null
          ? const <({Offset centro, double opacidad})>[]
          : estelaDelVuelo(puntos, a, vuelo),
      particulas: quieto || a == null
          ? const <({Offset centro, double radio, double opacidad})>[]
          : particulasDelAterrizaje(a, _ms - _T.aterrizaje),
      ulima: _selloPosado ? null : destino?.ulima,
      origenDeUlima: destino?.origenDeUlima,
      revelado: revelado,
    );
```

  7. En `build`, Ulises aparece desde los 120 ms sin movimiento.

```dart
      if (_aterrizaje != null &&
          _ms >= (_sinMovimiento ? _S.ulises : _T.quieto))
        _ulises(),
```

  8. En `_ulises`, la pose sin movimiento es un fundido en su lugar, y el `ClipOval` va dentro de
     un `Opacity` con `pose.opacidad`. Todo lo que va antes del `return` pasa a ser esto.

```dart
    final a = _aterrizaje!;
    final respuesta = _respuestaEn;
    PoseDeUlises pose;
    if (_sinMovimiento) {
      // Ulises no vuela. Aparece en su lugar con un fundido de 160 ms, y al
      // responder pasa a su avatar con uno de 140 ms (RF-BIEN-15).
      pose = PoseDeUlises(
        centro: a,
        lado: 70,
        opacidad: respuesta == null
            ? tramo(_ms, _S.ulises, _S.ulises + _S.fundidoDeUlises)
            : 1 - tramo(_ms - respuesta, 0, _S.fundidoDelAvatar),
      );
    } else {
      pose = _ms < _T.aterrizaje
          ? ulisesEnVuelo(_puntos!, a, _ms - _T.quieto)
          : _ms < _T.finDelRebote
          ? ulisesAlAterrizar(a, _ms - _T.aterrizaje)
          : ulisesAsiente(a, _ms - _T.finDelRebote);
      if (respuesta != null) {
        pose = ulisesSalta(
          a,
          widget.avatar.center,
          _ms - respuesta - _T.inicioDelSalto,
        );
      }
    }
```

  Y el `return` de `_ulises` queda así.

```dart
    return Positioned(
      left: pose.centro.dx - pose.lado / 2,
      top: pose.centro.dy - pose.lado / 2,
      // Una capa aislada, así que el vuelo no repinta el resto (RF-BIEN-18).
      child: RepaintBoundary(
        child: IgnorePointer(
          child: ExcludeSemantics(
            child: Transform.rotate(
              angle: pose.giro,
              child: Transform.scale(
                scaleX: pose.escalaX,
                scaleY: pose.escalaY,
                child: Opacity(
                  opacity: pose.opacidad.clamp(0.0, 1.0),
                  child: ClipOval(
                    key: Recibimiento.claveDeUlises,
                    child: Image.asset(
                      'assets/images/ulises_chatbot.png',
                      width: pose.lado,
                      height: pose.lado,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
```

  9. En `_tarjetaYBotones`, los tiempos y las formas de entrar siguen el modo.

```dart
    final m = _medidas!;
    final b = Theme.brightnessOf(context);
    final respuesta = _respuestaEn;
    final quieto = _sinMovimiento;
    final lector = _conLector;
    // Al responder se van en 280 ms. Sin movimiento siguen enteros debajo de
    // la conversación que aparece encima.
    final salida = respuesta == null || quieto
        ? 1.0
        : 1 - tramo(_ms - respuesta, 0, 280);
    // Con lector están desde el relevo. Sin movimiento, fundidos de 180 ms
    // sin desplazamiento.
    final tarjeta = lector
        ? 1.0
        : tramo(_ms, _msDeLaTarjeta, _msDeLaTarjeta + (quieto ? _S.fundido : 360));
    final botones = lector
        ? 1.0
        : tramo(_ms, _msDeLosBotones, _msDeLosBotones + (quieto ? _S.fundido : 400));
    final conForma = !quieto && !lector;
```

  El `Transform.scale` de la tarjeta usa `scale: conForma ? 0.9 + 0.1 *
  Curves.easeOutBack.transform(tarjeta) : 1`, el `Transform.translate` de los botones usa
  `Offset(0, conForma ? 18 * (1 - Curves.easeOutCubic.transform(botones)) : 0)` y la condición
  de los botones pasa a ser `if (_ms >= _msDeLosBotones)`.

  10. `_Tarjeta` pasa a `StatefulWidget`, y con lector mueve el foco a sí misma en su primer
      cuadro. Su `build` es el de la Tarea 28.

```dart
class _Tarjeta extends StatefulWidget {
  const _Tarjeta({super.key});

  @override
  State<_Tarjeta> createState() => _TarjetaState();
}

class _TarjetaState extends State<_Tarjeta> {
  @override
  void initState() {
    super.initState();
    // Con lector, el foco pasa a la tarjeta y después a los dos botones
    // (RF-BIEN-16).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !MediaQuery.accessibleNavigationOf(context)) return;
      context.findRenderObject()?.sendSemanticsEvent(const FocusSemanticEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);
    return Semantics(
      container: true,
      label: '${_Textos.saludo.replaceAll(' 👋', '')}. ${_Textos.pregunta}',
      excludeSemantics: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // El pico, un cuadrado de 14 dp girado 45° que asoma 5 dp por la
          // izquierda a 17 dp del borde superior, hacia Ulises.
          Positioned(
            left: -5,
            top: 17,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: SizedBox.square(
                dimension: 14,
                child: ColoredBox(color: MaterialTheme.bienvenidaSaludo(b)),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: MaterialTheme.bienvenidaSaludo(b),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(13, 9, 13, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _Textos.saludo,
                    style: _RecibimientoState._estiloSaludo.copyWith(
                      color: MaterialTheme.bienvenidaSaludoSub(b),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _Textos.pregunta,
                    style: _RecibimientoState._estiloPregunta.copyWith(
                      color: MaterialTheme.bienvenidaSaludoTinta(b),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

  11. `_PintorDelRecibimiento` suma `required this.estrellaDebajo` y
      `required this.opacidadDeLaEstrella`, con sus campos `final EscenaDelLogo? estrellaDebajo;` y
      `final double opacidadDeLaEstrella;`, y en `paint`, la estrella queda así.

```dart
    final abajo = estrellaDebajo;
    if (abajo != null) pintarEscena(canvas, abajo);
    final e = estrella;
    if (e != null) {
      if (opacidadDeLaEstrella < 1) {
        canvas.saveLayer(
          null,
          Paint()..color = Color.fromRGBO(0, 0, 0, opacidadDeLaEstrella),
        );
        pintarEscena(canvas, e);
        canvas.restore();
      } else {
        pintarEscena(canvas, e);
      }
    }
```

  12. En `_Boton`, el `Semantics` suma `onTap: alTocar`. Con `excludeSemantics`, la acción de
      toque del `InkWell` no llega al lector, así que sin ella el botón no se puede activar con
      doble toque (RF-BIEN-16). Ese `Semantics` va además dentro de
      `AnilloDeFoco(radio: BorderRadius.circular(16), child: …)`, con el import de
      `anillo_de_foco.dart`, para que el foco del teclado se vea en los dos botones.

- [ ] **Paso 4. La subida sin movimiento y el foco en la página.** En
  `lib/pages/bienvenida/bienvenida_page.dart`, haz estos cambios.

  1. Suma el cruce de la subida, el estado del cruce, el foco y el cursor.

```dart
  /// Sin movimiento, la franja con el sello y la conversación aparecen encima
  /// del recibimiento en 220 ms (RF-BIEN-15). Fuera de ese cruce vale 1.
  late final AnimationController _cruceDeLaSubida = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: 1,
  );
  bool _cruceSinMovimiento = false;

  /// La primera burbuja nueva de Ulises, a la que va el foco del lector
  /// (RF-BIEN-16).
  int _visiblesAntes = 0;
  int? _idAEnfocar;

  /// El cursor que había antes de montar la bienvenida.
  bool? _cursorAnterior;
```

  2. Al final de `didChangeDependencies`, fuera de la guarda de `_leida`, fija el cursor.

```dart
    // Sin movimiento, el cursor del campo no parpadea (RF-BIEN-15). El SDK
    // solo lo permite con este interruptor global, que la página devuelve a su
    // valor en su dispose.
    _cursorAnterior ??= EditableText.debugDeterministicCursor;
    EditableText.debugDeterministicCursor =
        _sinMovimiento || _cursorAnterior!;
```

  En `dispose`, suma esto y `_cruceDeLaSubida.dispose();`.

```dart
    final cursor = _cursorAnterior;
    if (cursor != null) EditableText.debugDeterministicCursor = cursor;
```

  3. Al principio de `_alRevelar`, después de la guarda de `mounted`, elige la burbuja a enfocar.

```dart
    final visibles = _revelador.visibles;
    final entradas = _c.entradas;
    if (_conLector && visibles > _visiblesAntes) {
      final nuevas = entradas.sublist(
        _visiblesAntes.clamp(0, entradas.length),
        visibles.clamp(0, entradas.length),
      );
      _idAEnfocar =
          nuevas.whereType<BurbujaDeUlises>().firstOrNull?.id ?? _idAEnfocar;
    }
    _visiblesAntes = visibles;
```

  4. En `_recibimiento`, `alSubir` y `alTerminar` quedan así.

```dart
        alSubir: () {
          // La conversación ya trae su primer grupo, sin esperar el ritmo.
          _sincronizar();
          _revelador.mostrarYa(_primerGrupoConRespuesta());
          setState(() {
            // Sin movimiento, el sello y el avatar se ven enteros en la
            // franja y la conversación que aparecen encima (RF-BIEN-15).
            _selloVisible = _sinMovimiento;
            _avatarVisible = _sinMovimiento;
            _cruceSinMovimiento = _sinMovimiento;
          });
          if (_sinMovimiento) unawaited(_cruceDeLaSubida.forward(from: 0));
        },
```

```dart
        alTerminar: () {
          setState(() {
            _avatarVisible = true;
            _recibimientoTerminado = true;
            _cruceSinMovimiento = false;
          });
          // 650 ms después empieza el primer turno de la rama elegida.
          _revelador.retenido = false;
        },
```

  5. En `_cuerpo`, la conversación va en un `FadeTransition` con el cruce, y sin movimiento pasa
     encima del recibimiento. Las claves conservan el estado de los dos al cambiar de orden.

```dart
    final conversacion = KeyedSubtree(
      key: const ValueKey<String>('conversacion'),
      child: FadeTransition(
        opacity: _cruceDeLaSubida,
        child: _conversacion(context, atendida: atendida),
      ),
    );
    final recibimiento = conRecibimiento
        ? Positioned.fill(
            key: const ValueKey<String>('recibimiento'),
            child: _recibimiento(context, atendida: atendida),
          )
        : null;
    // Sin movimiento, la franja y la conversación aparecen encima del
    // recibimiento, que sigue entero debajo hasta quedar cubierto.
    final encima = _cruceSinMovimiento;
    return Stack(
      children: [
        if (encima && recibimiento != null) recibimiento,
        conversacion,
        Positioned(
          top: CabeceraConSello.alto(context),
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: ClipRect(
              child: AnimatedBuilder(
                animation: _confeti,
                builder: (context, _) => _confeti.isAnimating
                    ? CustomPaint(painter: PintorDelConfeti(_confeti.value))
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        if (!encima && recibimiento != null) recibimiento,
        Positioned(
          top: CabeceraConSello.alto(context) + 8,
          left: 0,
          right: 0,
          child: Center(
            child: ValueListenableBuilder<EstadoDeLaPildora?>(
              valueListenable: _pildora,
              builder: (context, estado, _) => estado == null
                  ? const SizedBox.shrink()
                  : PildoraDelRegistro(estado: estado),
            ),
          ),
        ),
      ],
    );
```

  Estas líneas reemplazan el `return Stack(...)` de `_cuerpo`. Antes de ellas quedan
  `final atendida = _atendida;` y `conRecibimiento` de la Tarea 28.

  6. En `_conversacion`, cada `EntradaView` recibe `enfocar: entrada.id == _idAEnfocar`.

- [ ] **Paso 5. El foco en la burbuja y la píldora quieta.** En
  `lib/pages/bienvenida/widgets/burbujas.dart`, suma el import, el parámetro `enfocar` de
  `EntradaView` con su campo `final bool enfocar;` y este envoltorio, y el `build` de
  `EntradaView` devuelve `_Enfocable(enfocar: enfocar, child: _Entra(...))`.

```dart
import 'package:flutter/semantics.dart' show FocusSemanticEvent;
```

```dart
/// Con lector de pantalla, el foco pasa a la primera burbuja nueva de Ulises
/// (RF-BIEN-16). El nodo de cada entrada es un contenedor, así que el lector
/// lee el grupo en su orden.
class _Enfocable extends StatefulWidget {
  const _Enfocable({required this.enfocar, required this.child});

  final bool enfocar;
  final Widget child;

  @override
  State<_Enfocable> createState() => _EnfocableState();
}

class _EnfocableState extends State<_Enfocable> {
  @override
  void initState() {
    super.initState();
    if (widget.enfocar) _enfocar();
  }

  @override
  void didUpdateWidget(_Enfocable anterior) {
    super.didUpdateWidget(anterior);
    if (widget.enfocar && !anterior.enfocar) _enfocar();
  }

  void _enfocar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.findRenderObject()?.sendSemanticsEvent(const FocusSemanticEvent());
    });
  }

  @override
  Widget build(BuildContext context) =>
      Semantics(container: true, child: widget.child);
}
```

  En `franja_con_sello.dart`, el indicador de la píldora deja de ser `const` y queda quieto sin
  movimiento.

```dart
              else
                SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(
                    // Sin movimiento, el indicador queda quieto y el texto
                    // dice solo que se espera (RF-BIEN-15).
                    value: MediaQuery.disableAnimationsOf(context) ? 0.75 : null,
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
```

  Crea `lib/pages/bienvenida/widgets/anillo_de_foco.dart`.

```dart
// lib/pages/bienvenida/widgets/anillo_de_foco.dart
// El anillo de foco de la bienvenida (RF-BIEN-16). Con el foco del teclado
// físico en un botón, una píldora o un enlace, un anillo de 2 dp en
// bienvenidaFoco lo rodea con la forma del control. Con el tacto no se ve,
// porque sigue el modo de resaltado de Flutter.

import 'package:flutter/material.dart';

import '../../../configs/themes.dart';

class AnilloDeFoco extends StatefulWidget {
  const AnilloDeFoco({super.key, required this.radio, required this.child});

  /// El radio de las esquinas del control, para que el anillo siga su forma.
  final BorderRadius radio;
  final Widget child;

  @override
  State<AnilloDeFoco> createState() => _AnilloDeFocoState();
}

class _AnilloDeFocoState extends State<AnilloDeFoco> {
  bool _conFoco = false;
  bool _conTeclado =
      FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_alCambiarElModo);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_alCambiarElModo);
    super.dispose();
  }

  void _alCambiarElModo(FocusHighlightMode modo) {
    final conTeclado = modo == FocusHighlightMode.traditional;
    if (mounted && conTeclado != _conTeclado) {
      setState(() => _conTeclado = conTeclado);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = MaterialTheme.bienvenidaFoco(Theme.brightnessOf(context));
    return Focus(
      // No toma el foco. Solo escucha el del control que envuelve, y no suma
      // nada a la semántica.
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onFocusChange: (conFoco) {
        if (conFoco != _conFoco) setState(() => _conFoco = conFoco);
      },
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: widget.radio,
          border: _conFoco && _conTeclado
              ? Border.all(color: color, width: 2)
              : null,
        ),
        child: widget.child,
      ),
    );
  }
}
```

  En `compositor.dart`, suma el import de `anillo_de_foco.dart`. Cada control que usa
  `Semantics(excludeSemantics: true)` suma la acción de toque en ese `Semantics`, por la misma
  razón que `_Boton`, y su `build` devuelve ese `Semantics` dentro de un `AnilloDeFoco` con el
  radio de su forma.

| Control | Suma en `Semantics` | Radio del anillo |
| --- | --- | --- |
| `BotonDeEnvio` | `onTap: alTocar` | `BorderRadius.circular(24)` |
| `OjoDeLaContrasena` | `onTap: alTocar` | `BorderRadius.circular(24)` |
| `RespuestaRapida` | `onTap: esperando ? null : alTocar` | `BorderRadius.circular(999)` |
| `BotonPrincipal` | `onTap: activo ? alTocar : null` | `BorderRadius.circular(15)` |
| `EnlaceSecundario` | `onTap: alTocar` | `BorderRadius.circular(8)` |
| `BotonDeGoogle` | `onTap: alTocar` | `BorderRadius.circular(12)` |

  El campo ya marca su foco con el borde de 2 dp en `bienvenidaFoco` de la Tarea 26, así que no
  lleva anillo.

- [ ] **Paso 6. Corre las pruebas y confirma que pasan.**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/pages/bienvenida test/bienvenida
"${FLUTTER:?}" test --no-pub test/bienvenida
"${FLUTTER:?}" analyze --no-pub
```

Esperado. `All tests passed!` y los avisos de la base. Si `meetsGuideline` marca un control de
menos de 48 dp, se agranda el control, que es lo que pide RF-BIEN-16, y no se quita la prueba.

- [ ] **Paso 7. Suite completa y commit.** Corre la suite completa en segundo plano. Esperado,
  `All tests passed!`.

```bash
cd "${REPO:?}"
git status --short
git add lib/pages/bienvenida test/bienvenida
git commit -m "feat(bienvenida): con reducir movimiento todo es fundido cruzado sin perder el logo, y con lector la tarjeta llega con el relevo y el foco sigue a Ulises (RF-BIEN-15 y RF-BIEN-16)"
git log -1 --format='%an <%ae>'
```

---

### Tarea 32. El botón oficial de Google en web, configurado

**Requisitos.** De RF-BIEN-6, «Google en web» con «El tema» (decisiones B-25 y B-35). La cuenta
por `onCurrentUserChanged` ya la cubren las Tareas 19 y 23. `google_sign_in_button.dart` y
`google_sign_in_button_stub.dart` están en los targets de la bienvenida por su enmienda técnica del
2026-09-26, que no cambia ningún comportamiento aprobado.

**Archivos.**
- Modificar `lib/components/google_sign_in_button.dart`.
- Modificar `lib/components/google_sign_in_button_stub.dart`.
- Modificar `lib/components/google_sign_in_button_web.dart`.
- Modificar `lib/pages/bienvenida/widgets/compositor.dart` (E1 en web).
- Modificar `test/bienvenida/bienvenida_entrar_test.dart` (grupo `el botón de GIS`).

**Interfaces.**
- Consume `ConfiguracionDelBotonDeGoogle`, `TemaDelBotonDeGoogle` y
  `configuracionDelBotonDeGoogle` (Tarea 16), y el E1 de la Tarea 29.
- Produce esta firma, que usa la verificación de la Tarea 33.

```dart
Widget googleSignInButton({required ConfiguracionDelBotonDeGoogle configuracion});
```

- [ ] **Paso 1. Escribe la prueba que falla.** En `test/bienvenida/bienvenida_entrar_test.dart`,
  suma estos imports y este grupo. La llamada a `renderButton` no tiene prueba automática, porque
  `google_sign_in_button_web.dart` solo compila en web, y la cubre la revisión manual en Chrome de
  la Tarea 33 (decisión B-35). Los valores ya los prueba la Tarea 16 en la VM.

```dart
import 'package:flutter/widgets.dart';
import 'package:ulima_plus/components/google_sign_in_button.dart';
import 'package:ulima_plus/domain/bienvenida/bienvenida_turnos.dart';
```

```dart
  group('el botón de GIS (RF-BIEN-6, B-25 y B-35)', () {
    testWidgets('fuera de web, el botón con su configuración no dibuja nada', (
      tester,
    ) async {
      await tester.pumpWidget(
        Center(
          child: googleSignInButton(
            configuracion: configuracionDelBotonDeGoogle(
              oscuro: false,
              anchoDelCompositor: 351,
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(SizedBox)), Size.zero);
    });
  });
```

  Si el archivo ya importa `bienvenida_turnos.dart` o `widgets.dart` por otra vía, se omite ese
  import.

- [ ] **Paso 2. Corre la prueba y confirma que falla.**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/bienvenida/bienvenida_entrar_test.dart
```

Esperado. Falla la compilación, porque `googleSignInButton` no tiene el parámetro
`configuracion`.

- [ ] **Paso 3. La firma nueva.** `lib/components/google_sign_in_button.dart` queda así.

```dart
import 'package:flutter/widgets.dart';

import '../domain/bienvenida/bienvenida_turnos.dart';
// Import condicional. En web usa el botón oficial de Google (GIS), y en
// móvil y escritorio el stub, porque ahí va el botón propio.
import 'google_sign_in_button_stub.dart'
    if (dart.library.html) 'google_sign_in_button_web.dart'
    as platform;

/// Botón oficial de Google Identity Services, con la configuración de la
/// bienvenida (RF-BIEN-6 y B-35). Solo se dibuja en web, porque en
/// `google_sign_in` 6.x `signIn()` no funciona ahí y se requiere
/// `renderButton`. En móvil devuelve un widget vacío.
Widget googleSignInButton({
  required ConfiguracionDelBotonDeGoogle configuracion,
}) => platform.googleSignInButton(configuracion: configuracion);
```

  `lib/components/google_sign_in_button_stub.dart` queda así.

```dart
import 'package:flutter/widgets.dart';

import '../domain/bienvenida/bienvenida_turnos.dart';

/// Stub para plataformas que no son web. En móvil la bienvenida usa su botón
/// propio, que llama a `GoogleSignIn.signIn()`, así que aquí no se dibuja
/// nada.
Widget googleSignInButton({
  required ConfiguracionDelBotonDeGoogle configuracion,
}) => const SizedBox.shrink();
```

- [ ] **Paso 4. El botón de web, configurado y dibujado otra vez al cambiar el tema.**
  `lib/components/google_sign_in_button_web.dart` queda así.

```dart
import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as gsi_web;

import '../domain/bienvenida/bienvenida_turnos.dart';

/// Dibuja el botón oficial de Google (GIS) para web. Al hacer clic dispara
/// el flujo de Google, y la cuenta llega por `GoogleSignIn.onCurrentUserChanged`
/// a LoginController, que publica el desenlace para la bienvenida
/// (RF-BIEN-6).
///
/// El botón se crea una vez por configuración y se reutiliza, para que el
/// SDK no llame a `initialize()` en cada reconstrucción. La configuración de
/// GIS queda fija al dibujar el botón, así que un cambio del tema o del ancho
/// lo vuelve a dibujar. El aviso de GIS por un `initialize()` repetido que eso
/// puede dejar en la consola se acepta, porque web no se despliega.
Widget googleSignInButton({
  required ConfiguracionDelBotonDeGoogle configuracion,
}) => _GoogleSignInButtonWeb(configuracion: configuracion);

class _GoogleSignInButtonWeb extends StatefulWidget {
  const _GoogleSignInButtonWeb({required this.configuracion});

  final ConfiguracionDelBotonDeGoogle configuracion;

  @override
  State<_GoogleSignInButtonWeb> createState() => _GoogleSignInButtonWebState();
}

class _GoogleSignInButtonWebState extends State<_GoogleSignInButtonWeb> {
  late Widget _button = _dibujar(widget.configuracion);

  @override
  void didUpdateWidget(_GoogleSignInButtonWeb anterior) {
    super.didUpdateWidget(anterior);
    final antes = anterior.configuracion;
    final ahora = widget.configuracion;
    if (antes.tema != ahora.tema || antes.ancho != ahora.ancho) {
      _button = _dibujar(ahora);
    }
  }

  /// Los valores salen de la función pura de lib/domain/bienvenida (B-35).
  static Widget _dibujar(ConfiguracionDelBotonDeGoogle c) =>
      gsi_web.renderButton(
        configuration: gsi_web.GSIButtonConfiguration(
          type: gsi_web.GSIButtonType.standard,
          theme: switch (c.tema) {
            TemaDelBotonDeGoogle.outline => gsi_web.GSIButtonTheme.outline,
            TemaDelBotonDeGoogle.filledBlack =>
              gsi_web.GSIButtonTheme.filledBlack,
          },
          size: gsi_web.GSIButtonSize.large,
          text: gsi_web.GSIButtonText.continueWith,
          shape: gsi_web.GSIButtonShape.rectangular,
          logoAlignment: gsi_web.GSIButtonLogoAlignment.left,
          minimumWidth: c.ancho,
          locale: ConfiguracionDelBotonDeGoogle.idioma,
        ),
      );

  @override
  Widget build(BuildContext context) => KeyedSubtree(
    // Un botón nuevo monta su propio elemento de GIS.
    key: ValueKey<Object>(_button),
    child: _button,
  );
}
```

  Las constantes de texto de `ConfiguracionDelBotonDeGoogle` (`standard`, `continue_with`,
  `rectangular`, `left` y `large`) son los nombres que usa GIS para esos mismos enums, y la prueba
  de la Tarea 16 los fija. Este archivo los traduce a los enums de `google_sign_in_web`.

- [ ] **Paso 5. E1 le pasa el tema y el ancho.** En `lib/pages/bienvenida/widgets/compositor.dart`,
  la rama de web de `_E1` queda así, y suma el import de la función.

```dart
          if (kIsWeb)
            // El ancho del compositor, hasta 400 px, y el tema del sistema.
            LayoutBuilder(
              builder: (context, limites) => Center(
                child: googleSignInButton(
                  configuracion: configuracionDelBotonDeGoogle(
                    oscuro: Theme.brightnessOf(context) == Brightness.dark,
                    anchoDelCompositor: limites.maxWidth,
                  ),
                ),
              ),
            )
          else
            BotonDeGoogle(
              alTocar: c.esperando.value ? null : c.entrarConGoogle,
            ),
```

  `configuracionDelBotonDeGoogle` vive en `bienvenida_turnos.dart`, que `compositor.dart` ya
  importa.

- [ ] **Paso 6. Corre las pruebas y confirma que pasan.**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/components lib/pages/bienvenida test/bienvenida
"${FLUTTER:?}" test --no-pub test/bienvenida
"${FLUTTER:?}" analyze --no-pub
```

Esperado. `All tests passed!` y los avisos de la base. `flutter analyze` revisa también
`google_sign_in_button_web.dart`, así que los tipos de `GSIButtonConfiguration` quedan
comprobados aunque la prueba no pueda montarlo.

- [ ] **Paso 7. Commit.**

```bash
cd "${REPO:?}"
git status --short
git add lib/components/google_sign_in_button.dart lib/components/google_sign_in_button_stub.dart lib/components/google_sign_in_button_web.dart lib/pages/bienvenida/widgets/compositor.dart test/bienvenida/bienvenida_entrar_test.dart
git commit -m "feat(bienvenida): en web, el botón oficial de Google dice «Continuar con Google» en español, con el tema del sistema y el ancho del compositor, y se vuelve a dibujar al cambiar el tema (RF-BIEN-6, B-25 y B-35)"
git log -1 --format='%an <%ae>'
```

---

### Tarea 33. Los documentos quedan al día y la verificación completa

**Requisitos.** RF-SPL-19, RF-BIEN-18 en su medición, que queda en la lista del Paso 6, y
RF-BIEN-19 (las maquetas ya están en el repo desde `b720d70` y `026107d`, con su `README.md`). El
estado de las dos specs y de las enmiendas de app-shell, Auth y Registro, el de la enmienda de la
spec del test y el de las notas de Perfil académico, Chatbot y Récord académico, que la corrección
del plan del 2026-09-26 ya escribe como aprobadas y pendientes. Las filas del índice, las
secciones del README que nombran el login, el registro, la ruta post-login y las rutas, y la parte
automática de «Verificación» de las dos specs. La revisión manual queda en la lista del Paso 6,
para el dueño.

**Archivos.**
- Modificar `specs/features/splash/splash.spec.md` y `specs/features/bienvenida/bienvenida.spec.md`
  (estado y marcas `[@test]`).
- Modificar `specs/features/app-shell/app-shell.spec.md`, `specs/features/auth/auth.spec.md` y
  `specs/features/registro/registro.spec.md` (las notas de estado y los «(pendiente…)» que quedan).
- Modificar `specs/features/specialty-test/specialty-test.spec.md`,
  `specs/features/academic-profile/academic-profile.spec.md`,
  `specs/features/chatbot/chatbot.spec.md` y `specs/features/academic-record/academic-record.spec.md`
  (el estado de la enmienda y de las notas de la bienvenida).
- Modificar `docs/specs/feature-index.md` (filas 0, 1, 10, 16, 21, 22 y 23).
- Modificar `README.md`.

**Interfaces.**
- Consume lo que dejaron las Tareas 1 a 32. No produce firmas.

- [ ] **Paso 1. La fecha y el árbol limpio.**

```bash
cd "${REPO:?}"
git status --short
FECHA="$(date +%F)"
echo "$FECHA"
```

Esperado. `git status --short` vacío y la fecha del día, que los pasos siguientes escriben donde
dice «implementada».

- [ ] **Paso 2. El estado de las specs y del índice.** Corre este script. Cada reemplazo exige
  encontrar su texto una sola vez, así que si una línea cambió en el camino el script se detiene y
  dice cuál.

```bash
cd "${REPO:?}"
FECHA="$FECHA" python3 - <<'PY'
import os
import pathlib
import re

fecha = os.environ["FECHA"]

def cambiar(ruta, pares):
    p = pathlib.Path(ruta)
    texto = p.read_text(encoding="utf-8")
    for viejo, nuevo in pares:
        veces = texto.count(viejo)
        if veces != 1:
            raise SystemExit(f"{ruta}: {veces} veces «{viejo[:60]}»")
        texto = texto.replace(viejo, nuevo)
    p.write_text(texto, encoding="utf-8")

estado = (
    "**Aprobada por el dueño el 2026-09-26 y pendiente de implementar.**",
    f"**Aprobada por el dueño el 2026-09-26 e implementada el {fecha}.** La revisión\n"
    "> manual de «Verificación» queda pendiente.",
)
cambiar("specs/features/splash/splash.spec.md", [
    estado,
    ("> Los `[@test]` apuntan a pruebas que todavía no existen. Cada uno lleva «(pendiente)», nombra\n"
     "> la prueba que fija el requisito y se escribe con la implementación.",
     "> Los `[@test]` apuntan a la prueba que fija cada requisito, escrita con la implementación."),
])
cambiar("specs/features/bienvenida/bienvenida.spec.md", [
    estado,
    ("> Los `[@test]` apuntan a pruebas que todavía no existen. Cada uno lleva «(pendiente)» y se\n"
     "> escribe con la implementación.",
     "> Los `[@test]` apuntan a la prueba que fija cada requisito, escrita con la implementación."),
])
cambiar("specs/features/app-shell/app-shell.spec.md", [
    ("estrella de su decisión S-11, y pendiente de implementar.",
     f"estrella de su decisión S-11, e implementado el {fecha}."),
    ("los roles abren en Horario. Quedan pendientes de implementar.",
     f"los roles abren en Horario. Quedan implementadas el {fecha}."),
])
for spec in ("specs/features/auth/auth.spec.md", "specs/features/registro/registro.spec.md"):
    cambiar(spec, [
        ("(`specs/features/bienvenida/bienvenida.spec.md`) y pendiente de\n> implementar.",
         f"(`specs/features/bienvenida/bienvenida.spec.md`) e implementada el\n> {fecha}."),
        ("Hasta que se implemente, el código sigue el texto de arriba.",
         "Desde esa fecha, el código sigue la enmienda."),
    ])
cambiar("docs/specs/feature-index.md", [
    ("están **aprobadas por el dueño el 2026-09-26** y pendientes de implementar",
     f"están **aprobadas por el dueño el 2026-09-26** e implementadas el {fecha}"),
    ("**aprobado por el dueño el 2026-09-26** y pendiente de implementar",
     f"**aprobado por el dueño el 2026-09-26** e implementado el {fecha}"),
    ("queda **aprobada por el dueño el 2026-09-26**, escrita en la spec y sin implementar",
     f"queda **aprobada por el dueño el 2026-09-26** e implementada el {fecha}"),
])
# Los «(pendiente…)» que no son marcas [@test] con su paréntesis al final.
cambiar("specs/features/app-shell/app-shell.spec.md", [
    ("`[@test] ../../../test/components/header/app_header_test.dart` (pendiente del caso nuevo)",
     "`[@test] ../../../test/components/header/app_header_test.dart`"),
])
cambiar("specs/features/auth/auth.spec.md", [
    ("`bienvenida_sin_especialidad_test.dart` y `bienvenida_restablecer_test.dart` (pendientes), y",
     "`bienvenida_sin_especialidad_test.dart` y `bienvenida_restablecer_test.dart`, y"),
])
cambiar("specs/features/registro/registro.spec.md", [
    ("`test/bienvenida/bienvenida_registro_test.dart` (pendiente), y los casos 10 a 12 de",
     "`test/bienvenida/bienvenida_registro_test.dart`, y los casos 10 a 12 de"),
])
# La enmienda de la spec del test y las notas de Perfil académico, Chatbot y
# Récord académico, escritas por la corrección del plan del 2026-09-26.
nota = (
    "**aprobada por el dueño el 2026-09-26** junto con esa spec y pendiente de implementar.",
    f"**aprobada por el dueño el 2026-09-26** junto con esa spec e implementada el {fecha}.",
)
cambiar("specs/features/specialty-test/specialty-test.spec.md", [
    nota,
    ("bienvenida con Ulises», al final. Sus pruebas se escriben con la implementación y llevan la\n"
     "> marca de pendientes hasta entonces. Hasta que se implemente, el código sigue el texto de arriba.",
     "bienvenida con Ulises», al final. Sus pruebas están en `test/bienvenida/`, y desde esa fecha\n"
     "> el código sigue la enmienda."),
    ("`test/bienvenida/bienvenida_sin_especialidad_test.dart` (pendientes), y las de",
     "`test/bienvenida/bienvenida_sin_especialidad_test.dart`, y las de"),
])
for spec in ("specs/features/academic-profile/academic-profile.spec.md",
             "specs/features/chatbot/chatbot.spec.md",
             "specs/features/academic-record/academic-record.spec.md"):
    cambiar(spec, [nota])
indice = pathlib.Path("docs/specs/feature-index.md")
texto = indice.read_text(encoding="utf-8")
# Auth y Registro dicen lo mismo, así que van juntas.
viejo = "está **aprobada por el dueño el 2026-09-26** y pendiente de implementar"
if texto.count(viejo) != 2:
    raise SystemExit(f"feature-index: {texto.count(viejo)} veces «{viejo}»")
texto = texto.replace(viejo, f"está **aprobada por el dueño el 2026-09-26** e implementada el {fecha}")
viejo = "**Aprobada por el dueño el 2026-09-26 y pendiente de implementar**"
if texto.count(viejo) != 2:
    raise SystemExit(f"feature-index: {texto.count(viejo)} veces «{viejo}»")
texto = texto.replace(
    viejo,
    f"**Aprobada por el dueño el 2026-09-26 e implementada el {fecha}**, con la revisión manual "
    "de «Verificación» pendiente",
)
indice.write_text(texto, encoding="utf-8")

# Las marcas [@test] cuyo archivo existe pierden «(pendiente)».
marca = re.compile(r"`\[@test\] ([^`]+)` \(pendiente\)")
faltan = []
for spec in ("specs/features/splash/splash.spec.md",
             "specs/features/bienvenida/bienvenida.spec.md",
             "specs/features/app-shell/app-shell.spec.md"):
    p = pathlib.Path(spec)
    def quitar(m):
        prueba = (p.parent / m.group(1)).resolve()
        if prueba.exists():
            return f"`[@test] {m.group(1)}`"
        faltan.append(f"{spec}: {m.group(1)}")
        return m.group(0)
    p.write_text(marca.sub(quitar, p.read_text(encoding="utf-8")), encoding="utf-8")
print("faltan:", faltan or "ninguna")
PY
```

Esperado. `faltan: ninguna`. Si falta una prueba, la tarea que la crea quedó incompleta, y se
vuelve a esa tarea antes de seguir.

- [ ] **Paso 3. El README.** Corre este script, con el mismo control de una sola aparición. Cambia
  la tabla de los bindings, la ruta post-login con su diagrama y su guarda, la tabla de pantallas,
  los dos flujos del login, los tres diagramas que nombran `LoginPage` y la tabla de los services.
  Escribe entera la tabla de rutas desde `paginasDeLaApp`, con la misma cuenta en cada lugar que la
  da, y cambia las filas que nombran la tarjeta o `login_page.dart`, que son el componente del
  botón de Google, las pantallas estrechas, los requisitos RF-APP-01, 02, 08 y 09, la pantalla de
  HU01 y la sección de Google en web.

```bash
cd "${REPO:?}"
python3 - <<'PY'
import pathlib

p = pathlib.Path("README.md")
texto = p.read_text(encoding="utf-8")

def cambiar(viejo, nuevo):
    global texto
    veces = texto.count(viejo)
    if veces != 1:
        raise SystemExit(f"README: {veces} veces «{viejo[:70]}»")
    texto = texto.replace(viejo, nuevo)

cambiar(
    "| `LoginBinding` | [`lib/pages/login/login_binding.dart`](lib/pages/login/login_binding.dart)`:25-39` | `/login` → `LoginPage` | `Get.put(LoginController(), permanent: true)`. Si ya existe, lo reusa y agenda `resetFields()` en `addPostFrameCallback` para no disparar un `setState during build`. **Único binding con instancia permanente.** |",
    "| `LoginBinding` | [`lib/pages/login/login_binding.dart`](lib/pages/login/login_binding.dart) | `/login` → `BienvenidaPage` | `Get.put(LoginController(), permanent: true)` y después `Get.put(BienvenidaController(), permanent: true)`. Si ya existen, los reusa y agenda `resetFields()` en `addPostFrameCallback` para no disparar un `setState during build`. **Único binding con instancias permanentes.** |",
)
cambiar(
    "| `false` | `false` | `/setup-carrera` |",
    "| `false` | `false` | `/setup-carrera`, que la intro y la bienvenida traducen en el test de especialidad dentro de la conversación |",
)
cambiar(
    "| *(sin sesión restaurada)* | — | `/login` (`main.dart:81`) |",
    "| *(sin sesión restaurada)* | — | `/login`, la bienvenida con Ulises, por el relevo de la intro |",
)
inicio = texto.index("Los **cuatro llamadores** son")
fin = texto.index("\n", inicio)
texto = (
    texto[:inicio]
    + "Los llamadores son el arranque (`lib/pages/splash/carga_del_arranque.dart`) y la bienvenida, que "
    "la consulta después de cada entrada, con código, con Google en Android e iOS y con Google en web. "
    "`LoginController` ya no navega. Devuelve un `DesenlaceDelLogin` y la bienvenida decide el turno "
    "siguiente (RF-BIEN-6). Con `/home` sigue el paso al horario, que dibuja la capa del arranque, y con "
    "`/setup-carrera` el alumno hace el test de especialidad en la conversación, sin ver el asistente de "
    "carrera (RF-SPL-12 y RF-BIEN-21). Que sea una sola función es la razón de que el destino sea el "
    "mismo en todos los caminos."
    + texto[fin:]
)
inicio = texto.index('    START(["main async · lib/main.dart L48"])')
fin = texto.index("    SHELL --> R1{", inicio)
texto = (
    texto[:inicio]
    + '''    START(["main async · lib/main.dart"]) --> B1["ensureInitialized<br/>y orientacion portraitUp"]
    B1 --> WEB{"kIsWeb"}
    WEB -->|no| RUNI["runApp con la intro<br/>GetMaterialApp en /arranque<br/>CapaDeArranque en el builder"]
    RUNI --> CARGA["cargarElArranque en paralelo<br/>Firebase · Storage · servicios<br/>tryRestoreSession"]
    WEB -->|si| CARGAW["cargarElArranque antes de runApp<br/>y alertas del alumno"]
    CARGA --> T{"Sesion restaurada"}
    CARGAW --> T
    T -->|no| RLOGIN["/login"]
    T -->|si| PLR["postLoginRoute user<br/>post_login_route.dart"]
    PLR --> D1{"isTeacher o setupComplete"}
    D1 -->|si| RHOME["/home abierto en Horario"]
    D1 -->|no| RSETUP["/setup-carrera"]
    RSETUP -->|"la intro y la bienvenida la traducen"| RLOGIN
    RHOME --> SAL["Salida de la intro<br/>hasta la cabecera de /home"]
    RLOGIN --> BIEN["BienvenidaPage con LoginBinding permanente<br/>conversacion con Ulises"]
    BIEN --> ENT["Si, entrar con codigo o Google<br/>LoginController devuelve el desenlace"]
    BIEN --> NUEVO["Soy nuevo<br/>el registro en la conversacion"]
    ENT --> PLR2{"postLoginRoute"}
    PLR2 -->|"/home"| PASO["E3 y paso al horario<br/>dibujado por la capa"]
    PLR2 -->|"/setup-carrera"| TEST["Test de especialidad<br/>en la conversacion"]
    NUEVO --> TEST
    TEST --> PASO
    PASO --> SHELL["HomeShellConfig.forUser<br/>home_shell_config.dart"]
    SAL --> SHELL

'''
    + texto[fin:]
)
# Las cercas de código se arman con una variable, porque este script va dentro
# de un bloque de código del plan.
cerca = "`" * 3
inicio = texto.index(cerca + "dart\nbool offAllToLogin() {")
fin = texto.index("Nadie debe hacer", inicio)
guarda = (
    cerca + "dart\n"
    "bool offAllToLogin({\n"
    "  MotivoDeLlegada? motivo,\n"
    "  PoseDelLogo? pose,\n"
    "  bool desdeLaIntro = false,\n"
    "}) {\n"
    "  if (Get.context == null) return false;\n"
    "  if (Get.currentRoute == rutaDelArranque && !desdeLaIntro) return false;\n"
    "  final alreadyOnLogin =\n"
    "      Get.currentRoute == '/login' || Get.currentRoute == '/LoginPage';\n"
    "  if (alreadyOnLogin) return false;\n"
    "  final argumentos = <String, Object>{\n"
    "    argumentoDePose: ?pose,\n"
    "    argumentoDeMotivo: ?motivo,\n"
    "  };\n"
    "  if (desdeLaIntro) {\n"
    "    return offAllSinTransicion(\n"
    "      '/login',\n"
    "      arguments: argumentos.isEmpty ? null : argumentos,\n"
    "    );\n"
    "  }\n"
    "  Get.offAllNamed('/login', arguments: argumentos.isEmpty ? null : argumentos);\n"
    "  return true;\n"
    "}\n"
    + cerca + "\n"
    "([`lib/services/session_navigation.dart`](lib/services/session_navigation.dart))\n"
    "\n"
    "Desde la bienvenida, `offAllToLogin` suma el motivo de la llegada, que viaja como argumento de\n"
    "ruta. El 401 pasa `expirada` y el restablecimiento de contraseña pasa `restablecida`, y con\n"
    "cualquiera de los dos la conversación empieza directo en E1. La intro pasa la pose del logo con\n"
    "`desdeLaIntro`, que navega sin transición, y mientras la ruta es `/arranque` ningún otro llamador\n"
    "navega (RF-SPL-4 y RF-BIEN-1).\n"
    "\n"
)
texto = texto[:inicio] + guarda + texto[fin:]
cambiar(
    "| `LoginPage` | [`lib/pages/login/login_page.dart:10`](lib/pages/login/login_page.dart) | Pública | Código/usuario + contraseña, Google SSO y enlace a recuperación | `AuthService` | `InicioSesion.png` |",
    "| `BienvenidaPage` | [`lib/pages/bienvenida/bienvenida_page.dart`](lib/pages/bienvenida/bienvenida_page.dart) | Pública | La conversación con Ulises, con «Sí, entrar» con código o usuario y contraseña, «Continuar con Google», «¿Olvidaste tu contraseña?», «Soy nuevo» con el registro y el test de especialidad | `AuthService`, `RegistroService`, `SpecialtyTestService` | `ulises-te-recibe-combinada.html` |",
)
# La tabla de rutas se escribe entera desde paginasDeLaApp, con una fila
# por GetPage, y el script se detiene si las cuentas no coinciden.
import re

fuente = pathlib.Path("lib/main.dart").read_text(encoding="utf-8")
inicio = fuente.index("final List<GetPage<dynamic>> paginasDeLaApp")
nombres = re.findall(r"name: ([^,\n]+),", fuente[inicio:fuente.index("];", inicio)])
n = len(nombres)
filas = [
    "| `/arranque` | `ArranquePage` | ninguno | — | `paginasDeLaApp` |",
    "| `/login` | `BienvenidaPage` | `LoginBinding`, `LoginController` y `BienvenidaController` **permanentes** | `{pose?, motivo?}` | `paginasDeLaApp` |",
    "| `/forgot-password` | `ForgotPasswordPage` | `BindingsBuilder` | — | `paginasDeLaApp` |",
    "| `/reset-password` | `ResetPasswordPage` | `BindingsBuilder` | `{identifier, maskedEmail?}` | `paginasDeLaApp` |",
    "| `/setup-carrera` | `SetupCarreraPage` | `SetupCarreraBinding` | — | `paginasDeLaApp` |",
    "| `/test-especialidad` | `SpecialtyTestPage` | `SpecialtyTestBinding` | `{origen: asistente}` o `{origen: perfil}` | `paginasDeLaApp` |",
    "| `/home` | `HomePage` | 4 `lazyPut`: malla, secciones, asesorías, calificar | `{pestana: horario}` desde la intro y la bienvenida | `paginasDeLaApp` |",
    "| `/malla-clasica` | `MallaPage` | `MallaController` | — | `paginasDeLaApp` |",
    "| `/silabo` | `SilaboViewerPage` | `SilaboViewerController` | `{url, titulo}` | `paginasDeLaApp` |",
    "| `/teacher-home` | `TeacherHomePage` | `TeacherHomeBinding` | — | `paginasDeLaApp` |",
    "| `/teacher-advising-create` | `CreateAdvisingPage` | `CreateAdvisingBinding` | devuelve `true` | `paginasDeLaApp` |",
    "| `/teacher-advising-attendees` | `AttendeesPage` | `AttendeesBinding`, `fenix: true` | `{sessionId, title}` | `paginasDeLaApp` |",
    "| `/teacher-grade-section` | `TeacherGradeSectionPage` | `TeacherGradeSectionBinding` | `{sectionId, courseName, sectionCode, title}` | `paginasDeLaApp` |",
    "| `/mis-notas` | `MisNotasPage` | `MisNotasBinding` | — | `paginasDeLaApp` |",
    "| `/mi-record` | `AcademicRecordPage` | `AcademicRecordBinding` | — | `paginasDeLaApp` |",
    "| `/portal-sync` | `PortalSyncPage` | `PortalSyncBinding` | devuelve `true` si cargó | `paginasDeLaApp` |",
    "| `/chatbot` | `ChatbotPage` | ninguno | — | `paginasDeLaApp` |",
    "| `/networking` | `NetworkingPage` | `NetworkingBinding` | — | `paginasDeLaApp` |",
    "| `/bloque` | `TimeBlockFormPage` | `TimeBlockFormBinding` | una `TimeBlockRule` para editar, o nada para crear | `paginasDeLaApp` |",
    "| `/mis-bloques` | `TimeBlockListPage` | `TimeBlockListBinding` | — | `paginasDeLaApp` |",
]
if len(filas) != n:
    raise SystemExit(f"README: {len(filas)} filas para {n} rutas de paginasDeLaApp")
inicio = texto.index("#### Las 15 rutas nombradas")
fin = texto.index("\n\n> **3 · Por qué", inicio)
texto = (
    texto[:inicio]
    + f"#### Las {n} rutas nombradas\n\n"
    + "| Ruta | Página | Binding | Argumentos | Definida en |\n"
    + "|:---|:---|:---|:---|:---|\n"
    + "\n".join(filas)
    + texto[fin:]
)
# La misma cuenta de rutas en cada lugar que la da. Las cuentas de pantallas
# («28 pantallas» y su tabla) cuentan otra cosa, ya venían desfasadas por
# otras funcionalidades y quedan para una puesta al día aparte del README.
cambiar("| Ruta nombrada en `getPages` | 15 |", f"| Ruta nombrada en `getPages` | {n} |")
cambiar(
    "Las 15 rutas están declaradas en [`lib/main.dart`](lib/main.dart) (`main.dart:105-211`).",
    f"Las {n} rutas están declaradas en `paginasDeLaApp` de [`lib/main.dart`](lib/main.dart).",
)
cambiar("| 15 rutas nombradas | `lib/main.dart:105-211`. |", f"| {n} rutas nombradas | `paginasDeLaApp` de `lib/main.dart`. |")
cambiar("tabla de 15 getPages", f"tabla de {n} getPages")
if texto.count("15 rutas nombradas") < 2:
    raise SystemExit("README: faltan menciones de «15 rutas nombradas»")
texto = texto.replace("15 rutas nombradas", f"{n} rutas nombradas")
inicio = texto.index("#### 1 · Login con código y contraseña")
fin = texto.index("4. `AuthService.login()` hace", inicio)
texto = (
    texto[:inicio]
    + '''#### 1 · Entrar con código y contraseña

1. `/login` muestra la bienvenida con Ulises (`lib/pages/bienvenida/bienvenida_page.dart`), una
   conversación con la franja del sello arriba y el compositor abajo. Sin sesión, al arrancar, Ulises
   vuela junto a la estrella del splash y pregunta «¿Ya usas ULima++?» con dos botones, «Sí, entrar» y
   «Soy nuevo». Con el motivo `expirada` o `restablecida`, la conversación empieza directo en E1.
2. E1 pide el código o usuario con teclado de **texto**, porque el docente entra con un usuario
   alfanumérico institucional. E2 pide la contraseña, con el ojo, «Entrar», «¿Olvidaste tu contraseña?»
   y «Soy nuevo».
3. `LoginController.entrar()` llama a `AuthService.login()` y devuelve un `DesenlaceDelLogin`, sin
   navegar. Atrapa el fallo crudo de la red y apaga `submitting` en un `finally`.
'''
    + texto[fin:]
)
cambiar(
    "7. `Get.offAllNamed(postLoginRoute(user))` (`login_controller.dart:83`).",
    "7. Con la sesión puesta, `BienvenidaController` consulta `postLoginRoute(user)`. Con `/home`, Ulises\n"
    "   dice «¡Hola de nuevo! Te llevo a tu horario 🪶» y la capa del arranque dibuja el paso al horario.\n"
    "   Con `/setup-carrera`, el alumno sigue en la conversación con el test de especialidad.",
)
inicio = texto.index("2. **Móvil y escritorio**: `OutlinedButton`")
fin = texto.index("4. Ambos caminos convergen", inicio)
texto = (
    texto[:inicio]
    + '''2. **Android e iOS**. El botón propio «Continuar con Google» del compositor de E1 llama a
   `LoginController.entrarConGoogle()`, que abre `signIn()`. Si el usuario cancela el selector, no pasa
   nada y E1 sigue abierto.
3. **Web**. E1 dibuja el botón oficial de Google Identity Services con `renderButton`, configurado con
   `continueWith`, `es`, el tema del sistema y el ancho del compositor
   (`google_sign_in_button_web.dart`). La cuenta llega por `googleSignIn.onCurrentUserChanged` a
   `LoginController`, que publica el desenlace en `desenlaceDeGoogleEnWeb` para la bienvenida.
'''
    + texto[fin:]
)
cambiar('    LOGIN["LoginPage"] --> PLR{"postLoginRoute"}', '    LOGIN["BienvenidaPage"] --> PLR{"postLoginRoute"}')
cambiar('    PLR -->|"setupComplete false"| SETUP["SetupCarreraPage"]', '    PLR -->|"setupComplete false"| SETUP["Test de especialidad en la conversacion"]')
cambiar('    LOGINT["LoginPage"] --> PLRT{"postLoginRoute - isTeacher"}', '    LOGINT["BienvenidaPage"] --> PLRT{"postLoginRoute - isTeacher"}')
cambiar('    state "Sin sesion - LoginPage" as SinSesion', '    state "Sin sesion - BienvenidaPage" as SinSesion')
cambiar('    state "Autenticado sin setup - SetupCarreraPage" as SinSetup', '    state "Autenticado sin setup - test en la conversacion" as SinSetup')
cambiar('    SinSetup --> Listo : PUT me specialties y offAllNamed home', '    SinSetup --> Listo : PUT me specialties y paso al horario')
cambiar(
    "| `auth_service.dart` | `login` :155 | `POST /auth/login` | `String?` — `null` es éxito, texto es el mensaje de error | `LoginController.login` :73 → `LoginPage` |",
    "| `auth_service.dart` | `login` :155 | `POST /auth/login` | `String?` — `null` es éxito, texto es el mensaje de error | `LoginController.entrar` → `BienvenidaController` |",
)
# Las filas que nombran la tarjeta del login o login_page.dart.
cambiar(
    "| `googleSignInButton()` | [`lib/components/google_sign_in_button.dart`](lib/components/google_sign_in_button.dart) | `pages/login/login_page.dart` — fachada con import condicional |",
    "| `googleSignInButton()` | [`lib/components/google_sign_in_button.dart`](lib/components/google_sign_in_button.dart) | `pages/bienvenida/widgets/compositor.dart`, en E1 de web. Es la fachada con import condicional y recibe la configuración de GIS |",
)
cambiar(
    "| *web* de Google Sign-In | [`lib/components/google_sign_in_button_web.dart`](lib/components/google_sign_in_button_web.dart) | Rama `dart.library.html`: botón oficial GIS con una `GlobalKey` fija para evitar el warning de `initialize()` llamado dos veces |",
    "| *web* de Google Sign-In | [`lib/components/google_sign_in_button_web.dart`](lib/components/google_sign_in_button_web.dart) | Rama `dart.library.html`: botón oficial GIS con `continueWith`, `es`, el tema del sistema y el ancho del compositor, que se vuelve a dibujar al cambiar el tema o el ancho |",
)
cambiar(
    "- **Login, `maxWidth: 340`** (`login_page.dart:59`): la tarjeta no se estira en tablet ni en web.",
    "- **Bienvenida, columna de 600 dp** (`bienvenida_page.dart`). En una pantalla ancha, la conversación y el compositor van en una columna centrada de 600 dp (RF-BIEN-17).",
)
cambiar(
    "| `RF-APP-01` | Iniciar sesión con código y contraseña; el formulario valida no-vacío y **no llama a la API** si falta un campo (`BR-AUTH-F-01`) | [`lib/pages/login/login_page.dart`](lib/pages/login/login_page.dart) | `AuthService` → `POST /auth/login` | Implementado |",
    "| `RF-APP-01` | Iniciar sesión con código y contraseña; el formulario valida no-vacío y **no llama a la API** si falta un campo (`BR-AUTH-F-01`) | [`lib/pages/bienvenida/bienvenida_page.dart`](lib/pages/bienvenida/bienvenida_page.dart) | `AuthService` → `POST /auth/login` | Implementado |",
)
cambiar(
    "| `RF-APP-02` | Traducir todo error de login a `Código o contraseña incorrectos.` sin distinguir usuario inexistente de contraseña mala (`BR-AUTH-F-01`) | `login_page.dart` | `AuthService.loginErrorMessage` | Implementado |",
    "| `RF-APP-02` | Traducir todo error de login a `Código o contraseña incorrectos.` sin distinguir usuario inexistente de contraseña mala (`BR-AUTH-F-01`) | `bienvenida_controller.dart` | `AuthService.loginErrorMessage` | Implementado |",
)
cambiar(
    "| `RF-APP-08` | Mostrar spinner y deshabilitar el botón `Entrar` mientras el login está en vuelo (`BR-AUTH-F-08`) | `login_page.dart` | `LoginController.submitting` | Implementado |",
    "| `RF-APP-08` | Mostrar spinner y deshabilitar el botón `Entrar` mientras el login está en vuelo (`BR-AUTH-F-08`) | `compositor.dart` | `LoginController.submitting` | Implementado |",
)
cambiar(
    "| `RF-APP-09` | Iniciar sesión con Google en web y Android restringido a `@aloe.ulima.edu.pe` (alumno) y `@ulima.edu.pe` (docente), sin autoaprovisionamiento (`BR-AUTH-F-10`) | `login_page.dart`, `google_sign_in_button_web.dart` | `AuthService.loginWithGoogle` → `POST /auth/google` | Implementado |",
    "| `RF-APP-09` | Iniciar sesión con Google en web y Android restringido a `@aloe.ulima.edu.pe` (alumno) y `@ulima.edu.pe` (docente), sin autoaprovisionamiento (`BR-AUTH-F-10`) | `compositor.dart`, `google_sign_in_button_web.dart` | `AuthService.loginWithGoogle` → `POST /auth/google` | Implementado |",
)
cambiar(
    "| **Pantalla** | [`lib/pages/login/login_page.dart`](lib/pages/login/login_page.dart) |",
    "| **Pantalla** | [`lib/pages/bienvenida/bienvenida_page.dart`](lib/pages/bienvenida/bienvenida_page.dart) |",
)
cambiar(
    "3. **El botón se construye una sola vez.** `renderButton()` se guarda en un campo\n   `late final` dentro de `initState`\n   ([`lib/components/google_sign_in_button_web.dart`](lib/components/google_sign_in_button_web.dart)`:24-30`)\n   para que Flutter no destruya y recree el `HtmlElementView`; si se recreara, GIS\n   avisaría con «google.accounts.id.initialize() is called multiple times».\n4. **La UI difiere.** En web se pinta el botón oficial de Google; en móvil, un\n   `OutlinedButton` propio con `assets/images/google_logo.svg`\n   ([`lib/pages/login/login_page.dart`](lib/pages/login/login_page.dart)`:359-368`).",
    "3. **El botón se construye una vez por configuración.** `renderButton()` se guarda en el\n   `State` ([`lib/components/google_sign_in_button_web.dart`](lib/components/google_sign_in_button_web.dart))\n   y solo se vuelve a crear si cambian el tema o el ancho, así que Flutter no recrea el\n   `HtmlElementView` en cada reconstrucción. Al cambiar el tema, GIS puede avisar\n   «google.accounts.id.initialize() is called multiple times», un aviso que se acepta porque\n   web no se despliega (RF-BIEN-6).\n4. **La UI difiere.** En web se pinta el botón oficial de Google, configurado con `continueWith`,\n   `es` y el tema del sistema. En Android e iOS va el botón propio «Continuar con Google» del\n   compositor de E1, con `assets/images/google_logo.svg`\n   ([`lib/pages/bienvenida/widgets/compositor.dart`](lib/pages/bienvenida/widgets/compositor.dart)).",
)
p.write_text(texto, encoding="utf-8")
print("README al día")
PY
```

Esperado. `README al día`, con `#### Las 20 rutas nombradas`, 20 filas en su tabla y el 20 en cada
lugar que cuenta las rutas. Las cuentas de pantallas no cambian, como dice el comentario del
script. Los textos viejos se copian del README de hoy, con sus guiones largos, porque el script
los busca tal cual. Los nuevos no los usan, salvo el «—» de las celdas vacías de la tabla de rutas,
que es el formato de esa tabla. Si una línea ya no está igual, por ejemplo por un merge aparte de
`origin/main`, el script dice cuál y se ajusta solo ese par. La celda de mockup `InicioSesion.png`
de la sección «Mockups» queda, porque documenta la tarjeta anterior.

- [ ] **Paso 4. Las búsquedas de los documentos.** Son las pruebas de la fila «Documentos» de la
  cobertura.

```bash
cd "${REPO:?}"
grep -rn "(pendiente" specs/features/splash specs/features/bienvenida specs/features/app-shell specs/features/auth specs/features/registro specs/features/specialty-test specs/features/academic-profile specs/features/chatbot specs/features/academic-record | grep -v "\*(pendiente)\*" || echo "sin pendientes"
grep -rn "pendientes\? de implementar\|sin implementar" docs/specs/feature-index.md specs/features/splash specs/features/bienvenida specs/features/app-shell specs/features/auth specs/features/registro specs/features/specialty-test specs/features/academic-profile specs/features/chatbot specs/features/academic-record
grep -rn "LoginPage\|RegistroPage\|RegistroBinding\|'/registro'\|login_page.dart" README.md lib test | grep -v "/LoginPage"
grep -n "Password Reset" docs/specs/feature-index.md | grep -c "fila 23"
```

Esperado. `sin pendientes`, porque los `*(pendiente)*` en cursiva de la spec del test describen su
convención de marcas y la búsqueda los deja fuera. La segunda solo muestra la fila 13 del índice, el
chatbot, que no es de este plan. La tercera solo muestra la celda `InicioSesion.png` de «Mockups»,
que documenta la tarjeta anterior. La búsqueda deja fuera la guarda `'/LoginPage'` de
`session_navigation.dart` y sus menciones en el README, que siguen porque GetX le da ese nombre a
una ruta anónima. La cuarta da `1`, la mención de la fila 23 que dejó el merge `fcbf2e7`.

- [ ] **Paso 5. La verificación automática de las dos specs.** Corre el formato, el análisis, la
  prueba del PNG del nativo y la suite completa en segundo plano, con el comando de «Variables de
  los comandos».

```bash
cd "${REPO:?}"
"${DART:?}" format --output=none --set-exit-if-changed lib test
"${FLUTTER:?}" analyze --no-pub
"${FLUTTER:?}" test --no-pub test/splash/splash_png_nativo_test.dart
git status --short
```

Esperado. El formato no cambia nada, `analyze` da `5 issues found.`, los de la base,
la prueba del PNG pasa sin `--update-goldens` y `git status --short` muestra solo los documentos
de los Pasos 2 y 3. La suite completa da `All tests passed!`, con `test/splash`,
`test/bienvenida`, `test/HU01_jeff`, `test/HU02_jeff`, `test/HU20_jeff`, `test/HU23_jeff`,
`test/HU33_jeff`, `test/HU34_jeff`, `test/HU36_jeff` y `test/components/header`.

- [ ] **Paso 6. La lista para la revisión manual.** El informe de la tarea le deja al dueño esta
  lista, que sale de «Verificación» de las dos specs. Ninguna la hace el agente.
  1. En un Android 12 a 14 con barra de tres botones, en un Android 15 o superior, en un Android
     anterior a 12 y en el iPhone SE del dueño, en claro y en oscuro, cada variante con cada
     destino (con sesión, sin sesión y un alumno de prueba sin especialidad), grabando a 60 fps y
     revisando cuadro a cuadro que la estrella no salta entre el nativo y el primer cuadro, ni en
     el relevo, ni al retirarse la capa, y que la barra de estado se lee en cada destino.
  2. Con sesión, el alumno, el delegado, el profesor titular y el jefe de práctica abren en
     Horario, en vertical y en horizontal.
  3. Los recorridos «Sí, entrar» con código y con Google, un docente, «Soy nuevo» hasta el
     horario, un error de cada tramo, el modo avión durante el envío, el alumno de prueba sin
     especialidad al abrir la app y al entrar, «¿Olvidaste tu contraseña?» hasta entrar con la
     contraseña nueva y el restablecimiento desde el Perfil, con un sello a la vista en cada
     cuadro de `/forgot-password` y `/reset-password`.
  4. La misma revisión con TalkBack, con VoiceOver, con el texto al 200 %, con un teclado físico y
     con reducir movimiento.
  5. El llavero de iOS y el gestor de contraseñas de Google ofrecen la contraseña en E2 y ofrecen
     guardarla al entrar. Si no, rige «El autocompletado» de RF-BIEN-6.
  6. En el iPhone SE, con el texto al 100 %, la estrella no se mueve durante el recibimiento, y
     con el texto al 200 % nada se tapa.
  7. En Chrome, el botón oficial de Google dice «Continuar con Google» en español, con el tema del
     sistema y el ancho del compositor, y se vuelve a dibujar al cambiar el tema (B-35).
  8. En Android 12 o superior, si la grabación muestra la animación de salida del sistema encima
     del primer cuadro, el cambio vuelve a la spec del splash antes de tocar `MainActivity.kt`. En
     iOS, antes de revisar el nativo, se reinstala la app o se reinicia el teléfono.
  9. Las mediciones de RF-SPL-17 y de RF-BIEN-18 en modo perfil. Tres arranques en frío por
     variante, cinco por destino contra `main` en `41ff0a6`, y tres recorridos por tramo de la
     bienvenida.
  10. Un registro real contra el backend desplegado, con una cuenta que el dueño elija y sus
      datos, que nunca entran al repo.
  11. El splash y la bienvenida se publican juntos, en el mismo push a `main` (decisión S-30). El
      test de especialidad ya está en `main` desde `87403a1`. Este plan no hace push.

- [ ] **Paso 7. Commit.**

```bash
cd "${REPO:?}"
git status --short
git add specs/features/splash/splash.spec.md specs/features/bienvenida/bienvenida.spec.md specs/features/app-shell/app-shell.spec.md specs/features/auth/auth.spec.md specs/features/registro/registro.spec.md specs/features/specialty-test/specialty-test.spec.md specs/features/academic-profile/academic-profile.spec.md specs/features/chatbot/chatbot.spec.md specs/features/academic-record/academic-record.spec.md docs/specs/feature-index.md README.md
git commit -m "docs(arranque): el splash y la bienvenida quedan implementados en sus specs, el índice y el README, con la revisión manual de «Verificación» pendiente"
git log -1 --format='%an <%ae>'
```
