---
name: Time Blocks
description: Bloques de horario propios del alumno en la pantalla de horario — crearlos, editarlos, corregir un día suelto, verlos junto a las clases, sumar sus horas semanales y verlos todos en la lista Mis bloques
targets:
  - ../../../lib/pages/time_blocks/**
  - ../../../lib/pages/time_blocks/time_block_list_page.dart
  - ../../../lib/pages/time_blocks/time_block_list_controller.dart
  - ../../../lib/pages/time_blocks/time_block_list_binding.dart
  - ../../../lib/services/time_blocks_service.dart
  - ../../../lib/models/time_block_model.dart
  - ../../../lib/pages/horario/horario.dart
  - ../../../lib/pages/horario/horario_controller.dart
  - ../../../lib/pages/horario/horario_layout.dart
  - ../../../lib/services/api_client.dart
  - ../../../lib/services/auth_service.dart
  - ../../../lib/main.dart
---

# Bloques de horario propios

> Estado: **diseñada con el dueño del proyecto el 2026-09-20**, sección por sección.
> Aprobada por el dueño con los targets de arriba (los planes el 2026-09-22; la spec y los targets, de forma explícita el 2026-09-23), **e implementada.** Está
> probada entera contra dobles, pero **todavía no contra el backend desplegado**: las rutas
> `/time-blocks/**`, su migración `0012_time_blocks.sql` y el `isoDate` de los días de
> `GET /schedule/me/sessions` tienen que estar en producción antes de mergear a `main`,
> porque cada push a `main` publica el APK (`.github/workflows/build-apk.yml`).
> Contraparte de backend: `ULima_Backend_IS2/specs/features/time-blocks/time-blocks.spec.md`
> (RS-BE-30 a RS-BE-36).
> Ajustada el 2026-09-21 con las decisiones finales del dueño: fecha exacta de cada día
> (`isoDate`), días cancelados visibles, línea de horas oculta en 0 y tope de 20 bloques
> guardados.
> Ajustada el 2026-09-22 en RF-BLQ-6, que ahora oculta la línea de horas también cuando el total redondeado a un decimal da 0; el dueño aprobó ese ajuste el 2026-09-23.
> Ajustada el 2026-09-23 con el arreglo del bloque sin días reales y la lista Mis bloques, aprobado por el dueño ese día.
> Ajustada el 2026-09-23 en RF-BLQ-8 con los retoques de la revisión visual, que cambian el cuerpo de la confirmación de borrado desde la lista y fijan el contraste de sus avisos y del botón.

## User Stories

- Como alumno, quiero registrar mis prácticas en mi horario para ver mi semana completa.
- Como alumno, quiero corregir una semana suelta sin deshacer el patrón.
- Como alumno, quiero saber cuántas horas a la semana me llevan mis bloques.
- Como alumno, quiero ver todos mis bloques guardados, también los que la grilla no pinta,
  para editarlos o borrarlos.

## Requisitos

### RF-BLQ-1 — Agregar un bloque desde el horario

En la pantalla de horario, y solo para alumnos, un botón para agregar un bloque. Abre el
formulario de RF-BLQ-2 como ruta nueva con binding por ruta, como el resto de la app.

Un docente no lo ve: su horario es el de sus clases y asesorías.

`[@test] ../../../test/HU35_jeff/time_blocks_form_test.dart`

### RF-BLQ-2 — El formulario

Campos, en este orden: **nombre**, **color**, **días de la semana**, **hora de inicio y
fin**, **desde** y **hasta**.

- El color se elige de la paleta de doce que la app ya usa para los cursos
  (`lib/configs/course_colors.dart`), como círculos en **dos filas de seis**: en un iPhone
  SE los doce no entran en una sola fila. En una pantalla más ancha caben más en la primera
  fila. No se agrega ninguna dependencia de selector de color.
- Los días son botones de alternancia, de lunes a domingo. Viajan al servidor como números
  con su convención: 1 es lunes y 7 es domingo, igual que `schedule_session.day_of_week`.
- Las horas usan `showTimePicker` y las fechas `showDatePicker`, igual que el formulario de
  asesorías (`lib/pages/teacher/create_advising_page.dart`), que es el precedente del repo.
  Su título y sus botones van en español: «Elige la hora», «Elige la fecha», «Cancelar» y
  «Aceptar». Los nombres de los meses quedan en inglés: la app no carga
  `flutter_localizations` y esta funcionalidad no agrega dependencias.
- La validación vive en funciones puras que devuelven `String?` en español, como
  `lib/pages/teacher/advising_validators.dart`: nombre entre 1 y 60 caracteres, al menos un
  día, hora de fin posterior a la de inicio, las dos dentro de **7 am–10 pm**, fecha de
  fin no anterior a la de inicio, y **al menos una fecha del rango que caiga en uno de los
  días marcados**. Un bloque de martes y sábado que va del miércoles 23 al miércoles 23 no
  tiene ningún día real: el servidor no genera ninguna ocurrencia y la grilla no pinta
  nada. El mensaje es «Entre esas fechas no cae ninguno de los días que marcaste.», idéntico
  al del servidor (RS-BE-31). Si faltan las fechas o están invertidas, esta regla no suma
  nada: ya hay otro mensaje para eso.
- **Dónde abren los selectores de fecha al crear.** «Desde» abre en hoy. «Hasta» abre en
  el último día del ciclo visible —el último `isoDate` no nulo de los días que manda
  `GET /schedule/me/sessions`, el mismo extremo de la ventana de RF-BLQ-7— cuando ese día
  no es anterior a «Desde». Si no hay ciclo con fechas (el horario no está montado o ningún
  día trae `isoDate`) o ese día es anterior a «Desde», abre en «Desde» (o en hoy, si
  «Desde» sigue vacío) más 6 días. Aceptar los dos selectores sin moverlos ya no deja
  desde = hasta. Solo cambia dónde abre el selector: los campos no se prellenan.
- El mismo formulario sirve para crear y para editar; al editar trae los valores actuales.

El servidor vuelve a validar todo: el mensaje que se muestra ante un error del servidor es
el que él manda, no uno inventado por la app.

`[@test] ../../../test/HU35_jeff/time_blocks_form_test.dart`
`[@test] ../../../test/HU35_jeff/time_blocks_conflicto_test.dart`

### RF-BLQ-3 — Aviso de choque antes de guardar

Antes de enviar, la app compara el bloque contra las clases que ya tiene en pantalla y
contra los demás bloques del alumno. Si hay cruce, muestra un aviso que **nombra con qué**
y **cuándo** —"se cruza con Paradigmas de Programación, martes de 4:00 pm a 6:00 pm"— y
ofrece guardar igual o volver a editar. **Nunca impide guardar**: el cruce puede ser real y
el alumno lo sabe.

El aviso es del formulario. Cambiar la hora de un solo día (RF-BLQ-5) no lo muestra.

La detección es una función pura, probada aparte: dos rangos de hora en el mismo día de la
semana se cruzan si uno empieza antes de que el otro termine. Tocarse en el borde (una
termina 18:00 y la otra empieza 18:00) **no** es cruce.

**Solo avisa de cruces que pueden pasar en una fecha real.** Contra otro bloque propio,
avisa solo si existe al menos una fecha común a los dos rangos cuyo día de la semana está
en los dos bloques y en la que las horas se cruzan; que los rangos se solapen no basta (un
bloque de lunes que va del miércoles 23 al domingo 27 no tiene ningún lunes, así que no se
cruza con otro de lunes que va del lunes 21 a fin de octubre, aunque los rangos se
solapen). Un bloque guardado sin ningún día real en su rango no produce ningún aviso.
Contra una clase, que no trae fechas, avisa solo por los días de la semana que tienen al
menos una fecha real dentro del rango del bloque nuevo. Si falta un rango, se toma como
abierto y el aviso prefiere avisar de más que callar un cruce real.

`[@test] ../../../test/HU35_jeff/time_blocks_conflicto_test.dart`
`[@test] ../../../test/HU35_jeff/time_blocks_form_test.dart`

### RF-BLQ-4 — Pintados junto a las clases, sin taparse

Los bloques propios se pintan en las dos vistas del horario —la de día y la semanal
horizontal— con el color que eligió el alumno, y llevan su nombre. No muestran salón ni
sección, porque no tienen.

**Cada día sabe su fecha.** Un bloque cae en un día por su fecha, no por el nombre del día:
el horario trae los siete días de cada semana del ciclo, y la práctica del lunes 21 no es
la del lunes 28. La fecha de cada día es el `isoDate` que manda `GET /schedule/me/sessions`
(`"YYYY-MM-DD"`, en hora de Lima). Si viene `null` —el ciclo no tiene semanas, el mismo
caso en que `dateText` llega vacío—, se toma ese día de la semana en la semana de hoy.
Ninguna fecha se saca de `dateText`, que no trae año.

**Los días cancelados se ven.** Un día cancelado se pinta en su hora de siempre, con el
color del bloque a 40 % de opacidad y «Este día está cancelado» debajo del nombre, donde
una clase lleva su salón o su sección (si el bloque queda chico, el texto no entra y se
omite, igual que el de una clase). El servidor no manda los días cancelados entre las
ocurrencias: la app los saca de las excepciones que ya trae `GET /time-blocks/me`, con
las horas de la regla, y solo si la fecha sigue en el patrón. Tocarlo abre RF-BLQ-5.

**Reparto lado a lado.** Cuando dos o más bloques coinciden en el mismo tramo de un día, se
reparten el ancho en columnas y todos quedan visibles y tocables. Hoy no es así: dos
bloques simultáneos se dibujan uno encima del otro a ancho completo y el de arriba se come
los toques del de abajo (`horario.dart:276-277`, `left`/`right` fijos por vista). Esta
funcionalidad lo arregla, porque sus bloques **van a chocar a propósito** con las clases.

El cálculo del reparto es una función pura —dado un conjunto de bloques con inicio y fin,
devuelve para cada uno su columna y cuántas columnas hay— al estilo de `blockGeometry` y
`blockMetaLines`, con pruebas de dos y tres simultáneos, de uno contenido en otro y de dos
que solo se tocan en el borde.

**El domingo.** La vista semanal horizontal hoy llega hasta el sábado (`horario.dart:186-209`,
`_weekDays`: la lista de días termina en el sábado y su respaldo toma seis), aunque el
backend manda domingo y la vista de día sí lo muestra. Un bloque de domingo se vería en una
vista y desaparecería en la otra, así que la semanal pasa a incluirlo.

`[@test] ../../../test/HU35_jeff/time_blocks_grilla_test.dart`

### RF-BLQ-5 — Tocar un bloque propio

Tocar un bloque propio abre una hoja con cinco acciones posibles:

- **Editar el bloque** (todas las semanas): abre el formulario de RF-BLQ-2.
- **Cancelar solo este día**.
- **Cambiar la hora solo este día**, sin el aviso de cruce de RF-BLQ-3.
- **Volver al patrón**, solo si el día está movido o cancelado: quita la excepción de ese
  día.
- **Borrar el bloque**, con confirmación que dice que se borra el bloque y todos sus días.

Un día que sigue el patrón ofrece editar, cancelar, cambiar la hora y borrar. Un día movido
ofrece además volver al patrón. Un día cancelado —el que RF-BLQ-4 pinta tenue— abre la hoja
con una sola acción, **Volver al patrón**, y «Este día está cancelado» debajo. El aviso que
sale al cancelar un día trae además un **Deshacer**, un atajo que se cierra solo.

Tocar una clase sigue llevando al detalle del curso, como hoy. El bloque propio necesita su
propia rama en el `onTap` de `_courseBlock`, junto a las que ya existen para asesorías y
evaluaciones: hoy cualquier bloque con sección navega al detalle del curso
(`horario.dart:441`), y un bloque propio no tiene curso al que ir.

`[@test] ../../../test/HU35_jeff/time_blocks_acciones_test.dart`

### RF-BLQ-6 — Las horas de la semana

En la pantalla de horario, una línea discreta con las horas que los bloques propios ocupan
en la semana del día que se está viendo —la semana de lunes a domingo que contiene la fecha
(`isoDate`) del día activo—: "Tus bloques: 12 h esta semana". En la vista de día va debajo
de la semana del ciclo; en la semanal, en la franja de abajo, junto al ciclo. El número lo
calcula el servidor (RS-BE-34): el total de esa semana entera, aunque la ventana pedida la
corte. La app lo muestra y **no lo recalcula**, para que no haya dos cuentas que puedan
diferir.

La línea solo aparece si el total, redondeado a un decimal (la precisión con que se pinta),
es mayor que 0. Si el alumno no tiene bloques, si la semana no viene en la respuesta, o si
su total viene `null`, en 0 (una semana sin ocurrencias: todos sus días cancelados, o fuera
de las fechas del bloque) o por debajo de 0.05 h (menos de 3 minutos, que redondeados dan
0), no aparece. Nunca se pinta "0 h".

`[@test] ../../../test/HU35_jeff/time_blocks_horas_test.dart`

### RF-BLQ-7 — Capa de datos tipada

Un `TimeBlocksService` (`GetxService` permanente, como `MallaService`) y un modelo tipado
para los bloques y sus ocurrencias, con `fromJson` que conserva `null` y no inventa ceros.
El service es el único que habla HTTP; ningún widget lee JSON.

La pantalla de horario hoy llama a `ApiClient` directo desde el controlador y pide el
horario dos veces (`horario_controller.dart:101-103` y `:136-138`). Esta funcionalidad
**no** reescribe eso: agrega su propia capa tipada y deja el horario como está, salvo lo
que RF-BLQ-4 y RF-BLQ-5 obligan a tocar. Lo único que cambia en la lectura del horario es
que cada día guarda también su `isoDate` (`null` si no llega).

Los bloques se guardan en una lista propia del controlador, **nunca** mezclados con
`_todasLasSecciones`: ese arreglo alimenta el reparto de colores de los cursos y el marcado
de evaluaciones, y un bloque propio ahí dentro le robaría color a un curso real.

La ventana que la app pide es la del ciclo visible: del primer al último `isoDate` no nulo
de los días que manda `GET /schedule/me/sessions`. Ninguna fecha se saca de `dateText` ni
del ciclo del alumno (`currentCycle`). Un ciclo de 16 semanas son 112 días; si la ventana
del ciclo pasara de los 120 que acepta el servidor, la app pide solo 120 días desde el
lunes de la semana del día activo, y vuelve a pedir al cambiar de semana. Si ningún día
trae `isoDate`, la ventana es la de las cuatro semanas alrededor de hoy.

`[@test] ../../../test/HU35_jeff/time_blocks_service_test.dart`
`[@test] ../../../test/HU35_jeff/time_blocks_grilla_test.dart`

### RF-BLQ-8 — Mis bloques

La grilla solo pinta los días reales de un bloque dentro de la ventana del ciclo. Un bloque
vencido, uno fuera de esa ventana o uno sin ningún día real entre sus fechas (el de martes
y sábado del miércoles 23 al miércoles 23) no se ve en ella, y sin verlo no se puede editar
ni borrar. La lista «Mis bloques» los muestra todos.

- **El botón.** Uno pequeño junto al botón de agregar del horario (RF-BLQ-1), con las
  mismas condiciones: solo para alumnos, y ni en horizontal ni en la lista de chats. Su
  etiqueta accesible es «Mis bloques». Abre la pantalla en una ruta nueva, `/mis-bloques`,
  con binding por ruta. Como el formulario, la pantalla se abre fijada en vertical y, al
  volver, el horario recupera su rotación. Su ícono llega a un contraste de al menos 3:1 con
  el fondo del botón en los dos temas de la app, lo que WCAG 2.x pide a un componente.
- **La lista.** Todos los bloques guardados de la alumna, los de `TimeBlocksService.blocks`
  (`GET /time-blocks/me`), sin recortarlos a la ventana del horario. Primero van los
  vigentes y después los que ya terminaron, cada grupo ordenado por fecha de inicio (a
  igual inicio, primero el que termina antes). Cada fila muestra el color del bloque, su
  nombre, sus días (Lu, Ma, Mi, Ju, Vi, Sá, Do), sus horas en `HH:MM`, como el formulario
  y la hoja de RF-BLQ-5 («Lu, Mi · 14:00 a 18:00»), y sus fechas en dd/mm/aaaa («Del
  01/09/2026 al 15/12/2026»).
- **Lo que avisa una fila.** Si ninguno de los días marcados cae entre sus fechas, la fila
  dice «Ningún día marcado cae entre sus fechas». Lo decide la misma función pura que
  valida el formulario (RF-BLQ-2). Si su fecha de fin ya pasó en hora de Lima, dice
  «Terminó». Un bloque que termina hoy sigue vigente. Si se cumplen las dos cosas, la fila
  muestra los dos avisos. Los avisos van en 12 px, que para WCAG 2.x no es texto grande, así
  que llegan a un contraste de al menos 4,5:1 con el fondo de la fila en los dos temas de
  la app.
- **Tocar una fila** abre una hoja con dos acciones. «Editar el bloque» abre el formulario
  de RF-BLQ-2 con la regla, igual que la hoja de RF-BLQ-5. «Borrar el bloque» pide
  confirmación con el mismo título y los mismos botones que en RF-BLQ-5, pero su cuerpo es
  «Se borra "<nombre>" con todos sus días.», sin el «no solo este» de la hoja de un día,
  porque desde la lista no se tocó ningún día. Las dos acciones usan el mismo código que esa
  hoja.
- **Estados.** Si todavía no hay ningún bloque y hay una carga en curso, o todavía no ha
  llegado ninguna (el horario pide los bloques después de sus días), un indicador. Si la
  última carga falló, «No se pudieron cargar tus bloques.» y un botón «Reintentar» que
  vuelve a pedir la ventana vigente (`reload()`), aunque queden bloques de antes: pueden
  estar viejos, porque borrar uno no lo quita de la lista hasta que la recarga llega. Si la
  carga terminó y no hay ninguno, «Todavía no tienes bloques propios.».
- Al volver de editar o de borrar, la lista y la grilla ya muestran el cambio. El service
  recarga después de cada escritura (RF-BLQ-7) y las dos pantallas leen de él.

Textos nuevos: «Mis bloques» (la etiqueta del botón y el título de la pantalla), «Ningún
día marcado cae entre sus fechas», «Terminó», «Del dd/mm/aaaa al dd/mm/aaaa», «No se
pudieron cargar tus bloques.», «Reintentar», «Todavía no tienes bloques propios.» y «Se
borra "<nombre>" con todos sus días.».

`[@test] ../../../test/HU35_jeff/time_blocks_lista_test.dart`

## Contrato que se consume

`GET`, `POST`, `PATCH`, `DELETE /time-blocks/me`, `PUT` y `DELETE` de una ocurrencia, y
`GET /time-blocks/me/occurrences?from=&to=`. Las horas llegan como `"HH:MM"` y las fechas
como `"YYYY-MM-DD"`, en hora de Lima. El detalle está en la spec del backend. Lo que esta
pantalla da por hecho:

- Cada día de `GET /schedule/me/sessions` trae `isoDate`, su fecha exacta, o `null` si el
  ciclo no tiene semanas (RS-BE-36). Es un campo aditivo: ningún campo existente cambia.
- Una excepción cancelada llega con `startTime` y `endTime` en `null`, y el servidor no
  manda ese día entre las ocurrencias.
- `weeks` trae una entrada por cada semana entre el lunes de `from` y el lunes de `to`, con
  el total de la semana entera, y `hours: 0` cuando esa semana no tiene nada.
- El tope es de **20 bloques guardados**, vencidos incluidos: acota lo que el servidor
  expande en una ventana, y un bloque vencido se sigue expandiendo en una ventana pasada. El
  mensaje de `TIME_BLOCK_LIMIT_REACHED` lo dice y sugiere borrar uno viejo; la app lo muestra
  tal cual, como cualquier error del servidor.
- El servidor acepta fechas de 2000-01-01 a 2099-12-31; el formulario solo ofrece del año
  pasado a dos años adelante.

## Qué NO entra

- Repeticiones más ricas que "estos días de la semana".
- Recordatorios, notificaciones o compartir bloques.
- Bloques fuera de 7 am–10 pm: el formulario no los deja y el servidor los rechaza.
- Reescribir la pantalla de horario. Se toca solo lo que piden los requisitos de esta spec,
  que son el botón de agregar, los bloques propios en la grilla, el reparto en columnas, el
  domingo, el toque de un bloque propio, la línea de horas, la fecha de cada día y el botón
  de «Mis bloques».
- Mostrar las horas de las clases en la suma: solo cuentan los bloques propios.
- El aviso de cruce al cambiar la hora de un solo día.

## Decisiones

Las siete decisiones del dueño están en la tabla de la spec del backend. Las que mandan
sobre esta pantalla: el reparto lado a lado en vez de taparse o pintar semitransparente; el
aviso de choque que no impide guardar; y la grilla que se queda en 7 am–10 pm.

Las decisiones finales del 2026-09-21, ya escritas arriba: cada día lleva su fecha exacta
(`isoDate`) y ninguna fecha se adivina de `dateText` (RF-BLQ-4 y RF-BLQ-7); los días
cancelados se ven, tenues y con su texto (RF-BLQ-4 y RF-BLQ-5); la línea de horas se oculta
en 0 (RF-BLQ-6); el tope cuenta los 20 bloques guardados; y la paleta en dos filas, los
selectores en español y el cambio de hora de un día sin aviso de cruce (RF-BLQ-2, RF-BLQ-3
y RF-BLQ-5).
