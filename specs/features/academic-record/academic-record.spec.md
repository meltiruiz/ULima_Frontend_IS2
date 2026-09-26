---
name: Academic Record
description: Pantalla del récord académico (un ciclo a la vez), tarjeta de acceso en el Perfil, borrado a pedido y pantalla de consentimiento antes de dar las credenciales del portal
targets:
  - ../../../lib/pages/academic_record/**
  - ../../../lib/services/academic_record_service.dart
  - ../../../lib/models/academic_record_model.dart
  - ../../../lib/components/portal_consent/**
  - ../../../lib/pages/perfil/perfil.dart
  - ../../../lib/pages/portal_sync/portal_sync_page.dart
  - ../../../lib/pages/portal_sync/portal_sync_controller.dart
  - ../../../lib/services/portal_sync_service.dart
  - ../../../lib/pages/registro/**
  - ../../../lib/services/registro_service.dart
  - ../../../lib/services/auth_service.dart
  - ../../../lib/main.dart
---

# Récord académico

> Estado: **APROBADA** por el dueño del proyecto el 2026-09-18, con maquetas revisadas por él
> (se conservan en `ULIMA++/.superpowers/brainstorm/`, fuera del repo). Corregida el mismo
> día tras una revisión adversarial.
> Contraparte de backend: `ULima_Backend_IS2/specs/features/academic-record/academic-record.spec.md`
> (RS-BE-19 a RS-BE-29). Esta spec consume `GET` y `DELETE /academic-record/me`, y manda
> `consent: true` a `POST /portal-sync/import` y `POST /auth/register`.
>
> Nota del 2026-09-25 por la bienvenida con Ulises (`specs/features/bienvenida/bienvenida.spec.md`),
> **aprobada por el dueño el 2026-09-26** junto con esa spec e implementada el 2026-09-26. En el
> registro dentro de la conversación, el consentimiento de RF-REC-6 es una tarjeta con los mismos
> textos (ver «Nota de la bienvenida con Ulises» al final).

## User Stories

- Como alumno, quiero ver mi récord académico sin entrar al portal, con un estilo más
  entendible que su tabla de 12 columnas.
- Como alumno, quiero ver mi PPA y mis créditos apenas abro mi Perfil.
- Como alumno, quiero saber qué datos se llevan del portal antes de dárselos, y poder
  borrar mi récord de ULima++ cuando quiera.

## Requisitos

### RF-REC-1 — Tarjeta en el Perfil

En `perfil.dart`, dentro del bloque `if (!user.isTeacher)` y antes de `_CarreraCard`
—es decir, entre "Configurar carnet" y la tarjeta de Carrera—, una tarjeta con:

- **PPA** en grande y la **ubicación relativa** como insignia;
- los **créditos acumulados de los requeridos** ("164 de 200 créditos") con una barra;
- el enlace **"Ver mi récord completo ›"**, que navega con `Get.toNamed('/mi-record')`.

Un docente nunca ve la tarjeta ni dispara el `GET`, que para él respondería 403.

Lee el mismo `GET /academic-record/me` a través de `AcademicRecordService` (RF-REC-5);
**no** amplía `/auth/me`. Si el alumno nunca sincronizó, la tarjeta muestra "Sincroniza
con el portal para ver tu récord" en lugar de cifras, y el toque lleva igual a la pantalla
del récord, que muestra su estado vacío.

**Datos que faltan.** Si un dato viene `null`, no se muestra un 0: se omite (precedente
RS-BE-10 de no inventar ceros). Si `creditsAccumulated` o `creditsRequired` es `null`, o
`creditsRequired` ≤ 0, no se dibujan la barra ni el texto "N de M créditos". En los demás
casos el progreso es `clamp(acumulados / requeridos, 0, 1)`, una función pura probada con
`null`, 0 y acumulados mayores que requeridos.

**Decimales.** PPA, promedios y créditos se parsean con un helper que devuelve `double` o
`null` —nunca con `_asInt`, que convierte `"1.5"` y `null` en 0— y se muestran sin
redondear: "1.5 créd.", y "3 créd." sin ".0" cuando el valor es entero.

`[@test] ../../../test/HU34_jeff/record_card_test.dart`

### RF-REC-2 — Pantalla del récord: un ciclo a la vez

Ruta nueva en `lib/main.dart`, con binding por ruta como el resto:
`GetPage(name: '/mi-record', page: () => const AcademicRecordPage(), binding: AcademicRecordBinding())`.

De arriba abajo:

1. **Encabezado:** anillo con el porcentaje de créditos acumulados sobre requeridos
   (con la misma función y las mismas guardas de RF-REC-1: sin dato, no hay anillo),
   PPA grande e insignia de ubicación relativa.
2. **"Sincronizado hace N días"**, calculado de `syncedAt` en hora de Lima.
3. **Fila horizontal de chips de ciclo**, del más reciente al más viejo. Viene
   seleccionado el más reciente.
4. **Cursos del ciclo elegido** en una tarjeta. Arriba, el promedio del ciclo: se busca en
   `periods` el elemento con `periodCode` igual al del chip; si no hay elemento o su
   `average` es `null`, no se muestra.

Un solo ciclo a la vez: tocar otro chip cambia la lista. Estados explícitos de carga
(`SkeletonPulse`), error (`ErrorRetry`), vacío (RF-REC-4) y éxito.

`[@test] ../../../test/HU34_jeff/record_page_test.dart`

### RF-REC-3 — Cada curso, legible

Cada fila muestra el nombre, y debajo "código · N créd.". A la derecha, un chip:

| caso | chip |
|:---|:---|
| `grade` ≥ 14 | verde, con la nota |
| `grade` de 11 a 13 | ámbar, con la nota |
| `grade` < 11 (desaprobado) | rojo, con la nota |
| `grade` null y `gradeRaw` con texto (convalidación, retiro u otra marca del portal) | azul, con el texto de `gradeRaw` |
| `grade` null y `gradeRaw` null, en el ciclo más reciente del récord | neutro, "En curso" |
| `grade` null y `gradeRaw` null, en otro ciclo | neutro, "—" |

Los cursos del ciclo en curso llegan sin nota y son lo primero que ve el alumno, porque
ese ciclo viene seleccionado: nunca se pintan de azul como si estuvieran convalidados.

- `attempt ≥ 2` agrega la etiqueta **"N.ª vez"** junto al nombre.
- Si hay `observation`, va debajo del código, en texto pequeño (en un convalidado, es el
  motivo).
- Los cursos de mallas anteriores se muestran con su código y nombre originales.

La lógica que decide el chip y la etiqueta es una función pura y probada, como
`blockGeometry` y `blockMetaLines`, con los seis casos de la tabla.

`[@test] ../../../test/HU34_jeff/record_course_row_test.dart`

### RF-REC-4 — Estado vacío

Si `syncedAt` es `null`: ícono, "Aún no tienes tu récord", una línea que explica qué se
verá ("tus notas de toda la carrera, tu PPA y tus créditos") y el botón **"Sincronizar
con el portal"**, que navega con `Get.toNamed('/portal-sync')`.

`[@test] ../../../test/HU34_jeff/record_page_test.dart`

### RF-REC-5 — Borrar mi récord, y un solo estado

Al final de la pantalla, un botón **"Borrar mi récord de ULima++"**. Pide confirmación con
`showDialog<bool>` explicando que se borra la copia guardada, que la malla no cambia, y
que volver a sincronizar la guarda de nuevo. Con la confirmación llama a
`DELETE /academic-record/me` y la pantalla pasa al estado vacío.

La tarjeta del Perfil y la pantalla leen de un mismo `AcademicRecordService` (un
`GetxService` permanente, como `MallaService`), así que comparten un solo estado. Ese
estado se invalida y se vuelve a cargar tras el `DELETE` y en
`PortalSyncService.refreshAfterImport`, junto a los demás servicios que ya se limpian
ahí. Al volver con back, la tarjeta nunca muestra el PPA o los créditos anteriores.

`AuthService.logout()` también lo limpia (TT06: invalida TODAS las cachés por-usuario
al cerrar sesión, junto a `MallaService`, `CoursesService` y
`EvaluationSyllabusService`), con `Get.isRegistered<AcademicRecordService>()` de guarda
porque no todas las pruebas que llaman a `logout()` registran este servicio. A
diferencia del `DELETE` y de `refreshAfterImport`, el logout **no** vuelve a pedir:
solo vacía, para que la próxima cuenta que entre en el dispositivo no vea ni el PPA ni
un frame del estado de error del alumno anterior.

`[@test] ../../../test/HU34_jeff/record_page_test.dart`
`[@test] ../../../test/HU34_jeff/record_card_test.dart`
`[@test] ../../../test/HU34_jeff/academic_record_service_test.dart`
`[@test] ../../../test/HU02_jeff/user_cache_reset_test.dart`

### RF-REC-6 — Consentimiento antes de dar las credenciales

Requisito de la Ley 29733 que `portal-sync.spec.md` ya exigía y que no estaba implementado.

Una sola pantalla de consentimiento, reutilizada en los dos lugares donde el alumno le da
a ULima++ su contraseña del portal. Dice **qué datos se importan y para qué**: nombre,
código, carrera, nivel, cursos, secciones, docentes, horarios, matrícula, notas
históricas, PPA, ubicación relativa, créditos, y estado de impedimento y deuda; que se
usan para mostrárselos al propio alumno y para las funciones de ULima++ que ya usa
(horario, malla y la lista de su sección que ve su docente, con nombre y código —
`GradingStudent` en `official_grades_models.dart`); y que la contraseña se usa una sola
vez y no se guarda. Tiene un botón **"Acepto"** y otro para salir.

- **Portal Sync.** `PortalSyncStep` gana el paso `consent`, que pasa a ser el estado
  inicial. El formulario de credenciales (`form`) solo aparece tras tocar "Acepto". Si la
  importación falla, el controller vuelve a `form` sin volver a pedir la aceptación dentro
  de la misma visita; salir de la pantalla y volver a entrar la pide de nuevo.
- **Registro.** `RegistroPaso` gana el paso `consentimiento`, entre `datos` y
  `verificar`. Va antes del formulario del portal, nunca entre el código del authenticator
  y el botón que envía: ese código cambia cada 30 segundos (BR-REG-F-01). Sin aceptación,
  el registro no se envía.

Tras la aceptación, `PortalSyncService` y `RegistroService` mandan `consent: true` en el
body. Sin ese campo, el backend importa como hoy pero no guarda el récord (RS-BE-29 del
backend).

Se muestra antes de cada importación: son pocas —una por ciclo— y así el consentimiento
siempre corresponde a lo que se importa en ese momento.

*Enmienda del 2026-09-25, aprobada por el dueño el 2026-09-26 e implementada el 2026-09-26
(`specs/features/recarga-portal/recarga-portal.spec.md`, decisión B4).* Esta regla sigue
rigiendo la importación. La recarga de notas parciales y asistencia no pasa por
`PortalConsentView` y lleva su propio aviso en la hoja, en cada recarga, sin tocar las
constantes que congela `test/HU34_jeff/portal_sync_consent_test.dart`.

`[@test] ../../../test/HU34_jeff/portal_sync_consent_test.dart`
`[@test] ../../../test/HU34_jeff/registro_consent_test.dart`

## Contrato que se consume

Todos los numéricos llegan como `number` JSON, nunca como string; `credits`, `ppa`,
`average` y los `credits*` pueden traer decimal, y cualquier campo sin dato llega `null`.
El objeto de cada ciclo en `periods` es
`{ periodCode, average, relativePosition, level, convalidated, enrolled, approved, failed }`,
cada grupo con `{ courses, credits }`. El detalle completo está en la spec del backend.

`[@test] ../../../test/HU34_jeff/academic_record_model_test.dart`

## Nombres que no se confunden

La app ya tiene "notas oficiales" en `/mis-notas`: las que carga el docente en ULima++ para
el ciclo en curso. Esta pantalla se llama **"Mi récord académico"** y es el histórico del
portal. No se mezclan ni se nombran igual.

## Cambios en otras specs

- `portal-sync.spec.md`, BR-SYNC-F-02: pasa a remitir a RF-REC-6 de esta spec. Se quitan
  el WebView, que ya no existe (el login es el formulario nativo de Portal Sync), y la
  frase "la contraseña nunca sale del portal", que ya es falsa: se reemplaza por "la
  contraseña se usa una sola vez y no se guarda". BR-SYNC-F-03 suma el paso `consent` a
  los estados de `PortalSyncStep`.
- `registro.spec.md`: el alta suma el paso `consentimiento` entre los dos pasos de
  BR-REG-F-01, y el body de `POST /auth/register` suma `consent: true`.

## Qué NO entra

- El resumen por ciclo completo del portal: la pantalla muestra el promedio por ciclo
  solo donde el backend lo tenga (RS-BE-25).
- Mostrar el récord a otros roles, o desde el chatbot.
- Recordar el consentimiento entre importaciones.

## Nota de la bienvenida con Ulises (2026-09-25, aprobada el 2026-09-26)

Nace con `specs/features/bienvenida/bienvenida.spec.md` (RF-BIEN-7), y el dueño la aprueba con
ella el 2026-09-26. Toca RF-REC-6 en su forma y no en su contenido, y el resto de esta spec sigue
igual.

- **RF-REC-6, en el registro.** RF-REC-6 habla de una sola pantalla de consentimiento. Desde la
  bienvenida, el registro corre dentro de la conversación con Ulises y la ruta `/registro` sale,
  así que en el registro el consentimiento es una tarjeta de Ulises con los textos literales de
  `PortalConsentView`, tomados de sus constantes, y las respuestas rápidas «Acepto» y «Volver»
  (turno N3 de RF-BIEN-7). Va en el mismo lugar que hoy, después de las contraseñas y antes de la
  contraseña de miUlima, nunca entre el código del authenticator y el envío. Sin aceptación, el
  registro no se envía, y el cuerpo de `POST /auth/register` sigue llevando `consent: true`.
- **Portal Sync.** Sigue mostrando la pantalla `PortalConsentView` sin cambios, así que los dos
  lugares donde ULima++ pide la contraseña del portal dicen exactamente lo mismo.
- **Targets.** No cambian. La tarjeta vive en `lib/pages/bienvenida/**`, que está en los targets
  de la bienvenida, y lee las constantes de `PortalConsentView` sin cambiarlas.
- **Test Links.** `test/HU34_jeff/registro_consent_test.dart` sigue, con sus casos 10 a 12
  montando la conversación en lugar de la pantalla del registro.
