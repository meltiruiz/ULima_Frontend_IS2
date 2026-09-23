---
name: Time Blocks
description: Bloques de horario propios del alumno en la pantalla de horario — crearlos, editarlos, corregir un día suelto, verlos junto a las clases y sumar sus horas semanales
targets:
  - ../../../lib/pages/time_blocks/**
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

## User Stories

- Como alumno, quiero registrar mis prácticas en mi horario para ver mi semana completa.
- Como alumno, quiero corregir una semana suelta sin deshacer el patrón.
- Como alumno, quiero saber cuántas horas a la semana me llevan mis bloques.

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
  día, hora de fin posterior a la de inicio, las dos dentro de **7 am–10 pm**, y fecha de
  fin no anterior a la de inicio.
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
- Reescribir la pantalla de horario: se toca lo que el reparto en columnas, el domingo y el
  toque de un bloque propio obligan, y nada más.
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
