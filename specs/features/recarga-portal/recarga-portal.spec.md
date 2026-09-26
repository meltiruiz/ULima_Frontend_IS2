---
name: Recarga desde la ULima
description: Botones que, con un solo inicio de sesión en miUlima, traen las notas parciales por evaluación y la asistencia del Aula Virtual, y la calculadora de siempre reorganizada según la maqueta aprobada, con la fila «Notas oficiales», la pantalla /mis-notas con las notas de la ULima y las notas publicadas dentro de la calculadora
targets:
  - ../../../lib/services/recarga_ulima_service.dart
  - ../../../lib/models/recarga_ulima_models.dart
  - ../../../lib/domain/recarga_ulima/**
  - ../../../lib/components/recarga_ulima/**
  - ../../../lib/pages/calculadora/calculadora_page.dart
  - ../../../lib/pages/calculadora/calculadora_controller.dart
  - ../../../lib/components/calculadora/curso_card.dart
  - ../../../lib/components/calculadora/nota_tile.dart
  - ../../../lib/pages/mis_notas/mis_notas_page.dart
  - ../../../lib/pages/mis_notas/mis_notas_controller.dart
  - ../../../lib/pages/descripcion_cursos/descrip_cursos.dart
  - ../../../lib/pages/descripcion_cursos/descrip_cursos_controller.dart
  - ../../../lib/models/seccion_model.dart
  - ../../../lib/pages/portal_sync/portal_sync_controller.dart
  - ../../../lib/pages/password_reset/password_reset_ui.dart
  - ../../../lib/configs/themes.dart
  - ../../../lib/services/auth_service.dart
  - ../../../lib/main.dart
  - ../../../test/HU37_jeff/**
  - ../../../docs/specs/api-contracts.md
  # AGENTS.md y KNOWLEDGE.md entran por la decisión B12, que el dueño aprueba el 2026-09-26.
  - ../../../AGENTS.md
  - ../../../KNOWLEDGE.md
  # README.md entra porque RF-RCG-5 vuelve falsa su frase sobre la entrada a /mis-notas
  # (README.md:102). Lo demás de esa línea cambia por B10 y B12, aprobadas el 2026-09-26.
  - ../../../README.md
---

# Recarga de notas parciales y asistencia desde la ULima

> Estado. **Aprobada por el dueño el 2026-09-26 e implementada en la app el 2026-09-26.** El dueño
> responde «aplica» a la versión `b8facce` de esta spec y lo confirma como «Recarga: todas las
> recomendadas», así que aprueba las decisiones B1 a B19 y los puntos D1 a D24 en su opción
> recomendada, que es la que cada fila de «Decisiones» adopta por defecto. La misma aprobación
> fija en 65 000 el máximo del presupuesto de tiempo del backend, con 3 s reservados para la red,
> igual en las dos specs, y esta versión alinea con ese valor la cota de 68 000 de la versión
> `b8facce` (hueco 5 y D18).
> Contraparte del backend. `ULima_Backend_IS2/specs/features/recarga-portal/recarga-portal.spec.md`
> (RS-BE-48 a RS-BE-60), en la rama `feat/recarga-notas-asistencia`, que el dueño aprueba el
> mismo día en su versión `0161dee`. La aprobación incluye el diseño de BD de su migración
> `0015`, y aplicarla en producción sigue pidiendo un respaldo y el permiso del dueño en el
> momento del despliegue. Esta spec consume las rutas de esa spec y no inventa ningún campo. Lo
> que al contrato le falta para la maqueta, o no garantiza, está en «Contrato que se consume»,
> en «Huecos del contrato».
> Enmienda `grades.spec.md`, `course-detail.spec.md`, `portal-sync.spec.md`,
> `academic-record.spec.md` (RF-REC-6) y `schedule.spec.md`, con la misma aprobación (ver
> «Cambios en otras specs»). La rama `feat/recarga-notas-asistencia-fe` parte de `origin/main`
> en `19fed1b`, y todas las referencias `archivo:línea` citan ese estado. Después trae `main` en
> `87403a1`, con el test de especialidad, en un merge que conserva los dos lados en
> `lib/main.dart`, `lib/services/auth_service.dart` y `lib/configs/themes.dart` y deja esta
> funcionalidad en la fila 22 del índice, porque el test llega primero a `main` con la 21. Las
> referencias `archivo:línea` siguen citando `19fed1b`.
> Las pruebas de esta spec existen en `test/HU37_jeff/`, y cada requisito enlaza con `[@test]`
> los archivos que lo verifican. El backend de RS-BE-48 a RS-BE-60 está desplegado desde el
> 2026-09-26 (`9b5a1f2`, PR #12 del backend), con la `0015` aplicada con su respaldo (decisión
> B1). La medición de B15 se hizo ese mismo día sobre ese despliegue, con tres recargas de la
> cuenta del dueño en `iad1` que respondieron 200 en 12,3 s, 11,4 s y 11,4 s, sin ningún `504`.
> El dueño autorizó publicar la app con esas dos condiciones cumplidas. La revisión manual de
> «Verificación» (iPhone SE en claro y en oscuro, texto al 200 % y VoiceOver, y Android con
> TalkBack) queda pendiente y se hace sobre el APK publicado. Los ejemplos usan datos inventados
> (alumno `20230001`, curso TALLER DE PROTOTIPADO, sección `812`), porque el repositorio es público.

## User Stories

| ID | Descripción |
| --- | --- |
| HU-RCG-01 | Como alumno, quiero traer desde la ULima mis notas parciales por evaluación y verlas en «Notas oficiales» con su semana y su peso, sin esperar a que alguien las copie. |
| HU-RCG-02 | Como alumno, quiero que la calculadora cuente las notas que la ULima ya publica, sin registrarlas a mano, y seguir simulando las que faltan. |
| HU-RCG-03 | Como alumno, quiero actualizar mi asistencia desde la ficha del curso y saber de cuándo es el dato que veo. |

## Pedido y decisiones del dueño (2026-09-25 y 2026-09-26, vinculantes)

| # | Decisión | Dónde queda |
| --- | --- | --- |
| 1 | Botones de recarga junto a las notas y junto a la asistencia, que vuelven a pedir los datos a la ULima con la contraseña de miUlima y el código del autenticador (SecurID de un solo uso), para traer la asistencia real y las notas parciales por evaluación del Aula Virtual. | RF-RCG-2, RF-RCG-6 y RF-RCG-8 |
| 2 | Un solo inicio de sesión trae notas y asistencia juntas, y cualquiera de los dos botones actualiza ambas. | RF-RCG-1 y RF-RCG-3 |
| 3 | La calculadora conserva su diseño actual, idea de un integrante del equipo, y solo se reorganiza según la maqueta aprobada `calculadora-reorganizada.html`, con tres cambios. El birrete gris sin texto pasa a una fila «Notas oficiales» con la hora de la última lectura y el estilo de «Selecciona un Curso». La pantalla de notas oficiales (`/mis-notas`) conserva su diseño y suma la franja «Actualizar desde la ULima», las evaluaciones de la ULima con semana, peso y nota o «Sin nota», la hoja de recarga y el aviso rojo persistente con «Reintentar». En la calculadora, cada evaluación con nota de la ULima aparece como una fila de `nota_tile` con la marca «ULima», sin tacho, y cuenta en el promedio. | RF-RCG-5, RF-RCG-6 y RF-RCG-7 |
| 4 | El bloque de asistencia de la ficha del curso lleva también su botón de recarga y la hora de la última lectura. | RF-RCG-8 |
| 5 | El 2026-09-26 aprueba esta spec y la del backend con todas las opciones recomendadas («aplica», confirmado como «Recarga: todas las recomendadas»), es decir, B1 a B19 y D1 a D24 en la opción que cada fila adopta por defecto. | «Decisiones» |
| 6 | En esa misma aprobación, el presupuesto de tiempo del backend tiene un máximo de 65 000 y reserva 3 s para la red, igual en el backend y en la app. La cota de esta spec pasa de 68 000 a 65 000, como la de RS-BE-50. | RF-RCG-1, RF-RCG-3, hueco 5 y D18 |

La maqueta aprobada queda como referencia en
`docs/images/UI/recarga/calculadora-reorganizada.html`, con su fuente en `reorganizada.html` y
datos inventados, y es el cambio aprobado sobre las maquetas de `docs/images/UI` que pide
respetar `AGENTS.md`. Esta spec copia sus textos y sus medidas. La maqueta muestra la lista
«Qué no cambia», que esta spec copia y amplía
en «Qué no cambia de la calculadora». La maqueta no dibuja la ficha del curso, la espera de la hoja ni los errores
distintos del rechazo de la contraseña, así que esas piezas salen de esta spec, que las fija
como puntos D, y el dueño las aprueba con ellos el 2026-09-26.

## Contexto

Diagnóstico sobre `19fed1b`.

- **Calculadora.** `CalculadoraPage` (`calculadora_page.dart:8-171`) muestra el título
  «Calculadora de Notas» y, a su derecha, un `IconButton` con `Icons.school_outlined`, sin texto
  y con el tooltip «Notas oficiales» (`:40-44`), que es la única entrada a `/mis-notas` de toda la
  app. Debajo va «Cursos con notas: N» (`:47-62`). La lista pinta solo los cursos con alguna nota
  (`:78-82`), una `CursoCard` por curso, con su promedio y el aviso «Desaprobado» por debajo de
  11 (`curso_card.dart:95`). Cada nota es un `NotaTile` con peso, nota y tacho
  (`nota_tile.dart:66-87`).
- **Notas de la calculadora.** Son las de `simulated_grades`. `CalculadoraController` las lee de
  `GET /grades/me/notes` (`calculadora_controller.dart:121-137`), manda la lista entera de todos
  los cursos a `POST /grades/me/notes` en cada alta (`:139-166`), que el backend guarda con un
  upsert, y pide el promedio a `POST /grades/me/calculate` (`:168-199`). El peso se trunca a
  entero (`:85`). El modal «Registrar Nota» ofrece las evaluaciones del sílabo que todavía no
  tienen nota (`:277-283` y `add_score.dart:28-36`).
- **Notas oficiales.** `/mis-notas` (`mis_notas_page.dart`) lee `GET /official-grades/me`, es
  decir `student_score`, las notas que carga el docente dentro de ULima++. Tiene AppBar con
  flecha de recarga que vuelve a consultar al backend (`:20-37`), esqueleto, error, vacío
  (`:46-65`), una tarjeta por curso con filas «código · nombre», peso y nota, o una raya si no
  hay nota (`:151-195`), y la insignia «Final» con el umbral 10.5 (`:197-225`).
- **Ficha del curso.** El bloque de asistencia (`descrip_cursos.dart:154-307`) muestra horas
  asistidas, faltas, programadas y dictadas y un anillo, sin hora del dato ni botón. Su estado sin
  datos (`:314-360`) tiene el botón «Actualizar desde miUlima», que abre `/portal-sync` sin esperar
  el resultado (`:352`). La sección sale de `HorarioController.uniqueEnrolledCourses` o de
  `GET /course-detail/sections/:id` (`descrip_cursos_controller.dart:51-99`) y se asigna una sola
  vez.
- **Importación.** `/portal-sync` pide consentimiento en cada visita (RF-REC-6), contraseña y
  código, y gasta 1 de 5 cupos por hora. Su duración con las fases de delegados y de asistencia
  sigue sin medirse frente al plazo de 90 s de la app. Las únicas mediciones, de 40,7 s y 47,7 s
  (2026-09-02, con el backend en Lima), son anteriores a esas dos fases. Al terminar borra
  `CalculadoraController` con `Get.delete(force: true)` (`portal_sync_controller.dart:140-145`).
- **Estilos que la maqueta reutiliza.** La hoja «Selecciona un Curso» usa `primary` al 10 % de
  fondo y al 30 % de borde (`calculadora_page.dart:238-244`). La tarjeta «Actualizar desde
  miUlima» del Perfil (`perfil.dart:649-713`) es la base de la franja. La insignia del récord
  (`record_position_badge.dart`) es la base de la marca «ULima». El modal «Registrar Nota»
  (`add_score.dart:103-460`) es la base de la hoja.

## Requisitos

### RF-RCG-1. Capa de datos y estado compartido

Un servicio nuevo, `RecargaUlimaService` (`lib/services/recarga_ulima_service.dart`), es la única
frontera con las dos rutas nuevas. Es un `GetxService` permanente, registrado en `main.dart` junto
a `AcademicRecordService`, porque la calculadora, `/mis-notas` y la ficha del curso comparten su
estado.

- **Modelos** (`lib/models/recarga_ulima_models.dart`). `VistaUlima { lastReadAt: DateTime?,
  cursos: List<CursoUlima> }`, `CursoUlima { sectionId: int, courseCode, courseName, sectionCode,
  lastReadAt: DateTime?, evaluaciones: List<EvaluacionUlima> }` y `EvaluacionUlima { key, group?,
  name, week: int?, weight: double, value: double?, mark, assessmentId: int?, match }`, que
  leen `GET /grades/me/ulima` con este mapeo de claves. `VistaUlima.cursos` sale de `courses` y
  `CursoUlima.evaluaciones` sale de `assessments`, y todos los demás campos llevan el mismo
  nombre que en el JSON. En esta spec, `vista.cursos` y `evaluaciones` nombran siempre esas
  listas del modelo, y `courses` y `assessments` nombran siempre las claves del JSON.
  `ResultadoRecarga` guarda `readAt`, los estados por curso (`sectionId`, `attendance`,
  `grades`) y `view`. La lectura es tolerante. Un número que llega como texto se convierte, una
  fecha ilegible queda `null`, un `mark` desconocido se trata como `pending` y un `match`
  desconocido como `none`.
- **`cargar()`** hace `GET /grades/me/ulima` y deja el resultado en `vista` (un `Rx`). Un fallo no
  borra la vista que ya había del mismo alumno y deja `errorCarga` en verdadero hasta la
  siguiente carga buena.
- **`recargar({password, passcode})`** hace `POST /portal-sync/refresh` con el cuerpo exacto
  `{ "credentials": { "password": …, "passcode": … }, "consent": true }`. No manda `cookies`, ni el
  código del alumno, ni ninguna otra clave, porque el backend valida en modo estricto. El plazo de
  la app es de 90 s, el mismo de la importación (D18). La spec del backend acota su peor caso a
  87 s, contados desde que recibe la petición, y reserva así 3 s de ese plazo para la ida y la
  vuelta por la red del teléfono (hueco 5). Con `200` aplica
  `view` a `vista` y guarda los estados por curso del último resultado. Con error deja un
  `AvisoRecarga` (título, cuerpo y acción, RF-RCG-4) en `ultimoAviso`.
- **Plazo vencido o fallo de red** (D23). El backend puede terminar y escribir después de que la
  app deja de esperar. Por eso `recargar()` guarda, al enviar, la `lastReadAt` que tiene la vista
  y, tras el plazo o un fallo de red sin respuesta, llama a `cargar()` antes de volver. Si la
  vista nueva trae una `lastReadAt` posterior a la guardada, o una donde la vista del envío tenía
  `null`, la recarga sí se guardó y `recargar()` vuelve como un `200` sin estados por curso, así
  que no se pinta ninguna línea de lectura parcial. Si no, vuelve con el aviso del plazo o de la
  red. Mientras ese aviso siga presente, cualquier `cargar()` posterior que traiga una
  `lastReadAt` posterior a la guardada lo borra y corre la recarga del horario de RF-RCG-3. Las
  dos horas son del servidor, así que el reloj del teléfono no interviene. Sin vista cargada al
  enviar, como cuando la ficha del curso abre la hoja antes de que otra pantalla pida la vista,
  `recargar()` llama a `cargar()` antes del `POST`. Si tampoco así llega la vista, ninguna lectura
  cuenta como avance, ni la que sigue al plazo ni la de un `cargar()` posterior, porque la hora de
  una recarga anterior no se distingue de la de esta.
- **Contraseña y código.** Llegan como parámetros y se descartan al volver la llamada. Nunca
  entran en un `Rx`, en `shared_preferences`, en `flutter_secure_storage` ni en un `debugPrint`, y
  el cuerpo de la petición nunca se imprime. Es la misma regla de «Cambio de diseño» de
  `portal-sync.spec.md`.
- **`enviando`** (un `RxBool`) es verdadero mientras la recarga está en vuelo. Una segunda llamada
  en ese estado no hace nada.
- **Qué guarda y dónde.** Todo vive en memoria. `AuthService.logout()` llama a `clear()`, con la
  guarda `Get.isRegistered<RecargaUlimaService>()`, igual que con `AcademicRecordService`, y
  `clear()` vacía `vista`, `ultimoAviso`, `errorCarga`, `enviando` y los estados por curso. Nada
  de esto va a `shared_preferences`, porque son datos académicos oficiales (KNOWLEDGE.md,
  «Decisiones no negociables»).
- **Dueño de los datos.** `logout()` no basta. Cuando caduca el JWT, `ApiClient` borra la sesión
  y navega a `/login` sin llamar a `logout()` (`api_client.dart:143-160`), y el servicio es
  permanente, así que el siguiente alumno que entra en el mismo teléfono vería la vista del
  anterior. El servicio se ata al alumno como `AcademicRecordService`
  (`academic_record_service.dart:48-98`), con tres reglas.
  1. Guarda `_ownerCode`, el código del alumno dueño de la vista, del aviso, de `errorCarga` y de
     los estados por curso, y un contador de generación.
  2. `vista`, `ultimoAviso`, `errorCarga` y los estados por curso se leen por getters que leen
     primero su `Rx`, para que el `Obx` que los llama se suscriba, y devuelven `null`, falso o
     vacío si el código de `AuthService.to.currentUser` no es `_ownerCode`. Ninguna pantalla ni
     ningún controller lee los `Rx` sin pasar por esos getters.
  3. `cargar()` y `recargar()` comparan ese código con `_ownerCode` y, si difiere, llaman a
     `clear()` antes de cualquier `await`. `clear()` sube el contador, y cada petición lleva el
     número con el que salió. Una respuesta de `cargar()` o de `recargar()` que vuelve con otro
     número, porque en medio hubo un `clear()` o un cambio de dueño, se descarta sin tocar la
     vista, el aviso, `errorCarga` ni los estados.
- **Nada de datos de terceros.** El contrato no trae la mínima ni la máxima de la clase, y la app
  tampoco las pide ni las calcula.

`[@test] ../../../test/HU37_jeff/recarga_ulima_models_test.dart`
`[@test] ../../../test/HU37_jeff/recarga_ulima_service_test.dart`

### RF-RCG-2. La hoja de recarga

Una hoja modal con el formato del modal «Registrar Nota», en
`lib/components/recarga_ulima/hoja_recarga_ulima.dart`, que abren la franja de `/mis-notas`
(RF-RCG-6) y el botón del bloque de asistencia (RF-RCG-8). Es un `StatefulWidget` dueño de sus
dos `TextEditingController`, que se vacían con `clear()` antes de `dispose()`.

**Forma.** `showModalBottomSheet` con `isScrollControlled`, fondo `colorScheme.surface`, esquinas
superiores de 30, relleno de 24 y el alto del teclado sumado abajo, como `add_score.dart:108-118`.
De arriba abajo lleva lo siguiente.

1. El título `Actualizar desde la ULima` (22, negrita, `onSurface`) y, debajo, `Entras como
   20230001` (12, `onSurface`), con el código en negrita. El código sale de
   `AuthService.to.currentUser.code`, que la app ya tiene. Si no hay usuario, la línea no se
   pinta. A la derecha va la X de cerrar (`Icons.close`, tooltip `Cerrar`, blanco táctil de 48).
2. El aviso de consentimiento (13, `onSurface` al 70 %), con el texto exacto
   `Al tocar «Actualizar» aceptas que ULima++ lea en miUlima tus notas parciales y tu asistencia. La contraseña y el código se usan una sola vez y no se guardan.`
   Es la opción aprobada de la decisión B4. No toca el texto congelado de `PortalConsentView`.
3. El rótulo `Contraseña de miUlima` (14, negrita) y el campo, oculto por defecto, con la pista
   `Tu contraseña del portal`, `autofillHints: password` y un ojo a la derecha que alterna
   `Mostrar contraseña` y `Ocultar contraseña` en su tooltip. El campo mide al menos 52 de alto,
   con esquinas de 12.
4. El rótulo `Código del autenticador` (14, negrita) y seis casillas con
   `PasswordResetOtpField`, que ya trae teclado numérico, `digitsOnly` y
   `autofillHints: oneTimeCode`. Hoy ese widget fija las casillas en 52 de alto, las rellena con
   `palette.fieldFill` y solo pinta el borde de la activa (`password_reset_ui.dart:400-435`),
   mientras la maqueta dibuja casillas de contorno, sin relleno y de 50 de alto. La hoja le pasa
   `PasswordResetPalette.from(context)`, del que el widget sigue tomando el color del dígito
   (`fieldText`) y el borde de la casilla activa (`focusedFieldLine`). Además, el widget suma
   cuatro parámetros opcionales, cuyo valor por defecto deja como están `/portal-sync`,
   `/registro` y el cambio de contraseña. Son `boxHeight` (52 por defecto y 50 en la hoja),
   `boxFill` (`palette.fieldFill` por defecto y transparente en la hoja), `idleBorderColor`
   (transparente por defecto y `onSurface` al 50 % en la hoja, D13, con ancho de 1) y
   `readOnly` (falso por defecto y verdadero durante la espera, que no deja enfocar ni editar
   las casillas). Debajo, centrado, `El código de 6 dígitos que cambia cada 30 segundos.`
   (11, `onSurface` al 70 %, D14).
5. Dos botones de 48 de alto, uno al lado del otro, `Cancelar` (contorno) y `Actualizar`
   (relleno naranja y texto blanco en negrita, D12).

**Cuándo se enciende «Actualizar».** Solo con la contraseña no vacía después de `trim()` y el
código con `^\d{6,8}$`, el mismo criterio de `validarFormulario` en
`portal_sync_controller.dart:19-33`. Apagado, lleva `primary` al 30 % de fondo y `onSurface` al 38 %
de texto, como el botón «Registrar» apagado. La hoja no muestra mensajes de validación, porque el
botón apagado ya dice qué falta. La contraseña viaja sin `trim()` y el código sin recortar a seis,
igual que en `/portal-sync`.

**Espera.** Al tocar «Actualizar», la hoja llama a `RecargaUlimaService.recargar` y pasa a la
espera. Los dos campos quedan de solo lectura (las casillas, con `readOnly`), la X y «Cancelar»
se apagan, «Actualizar» cambia su texto por un indicador circular de 20 y, bajo los botones,
aparece `Leyendo miUlima. Puede tardar hasta un minuto.` (12, `onSurface` al 70 %, centrado,
D4). La espera no tiene etapas, porque la recarga es una sola petición.

**Cómo se cierra.** La hoja se abre con `isDismissible: false` y `enableDrag: false` (D4), así que
un toque fuera o un arrastre no la cierran ni dejan el código a medio escribir. Fuera de la espera
la cierran la X, «Cancelar» y el botón atrás del sistema. Durante la espera nada la cierra, y un
`PopScope` con `canPop: false` bloquea el botón atrás. Al terminar, con éxito o con error, la hoja
se cierra sola (RF-RCG-3). Cerrarla de cualquier forma, con la X, con «Cancelar», con atrás o al
terminar, vacía los dos campos.

`[@test] ../../../test/HU37_jeff/hoja_recarga_test.dart`

### RF-RCG-3. Resultado de la recarga

- **Éxito (`200`).** La hoja se cierra y vacía sus campos. `RecargaUlimaService` aplica `view` y
  guarda los estados por curso. Después, sin esperar a la pantalla, recarga el horario con
  `HorarioController.reload()` si el controller está registrado, porque la asistencia y
  `asistenciaLeidaEn` llegan por `GET /schedule/me/sessions` y no en `view`. Es la única llamada
  a `reload()` de la recarga, y el servicio expone su `Future` como `recargaHorario` para que
  nadie la repita. La calculadora y `/mis-notas` se actualizan solas porque leen `vista`
  (RF-RCG-6 y RF-RCG-7), y la ficha abierta vuelve a leer su sección (RF-RCG-8). La app no
  muestra ningún resumen ni aviso de éxito (D19). La hora nueva de la franja, de la fila «Notas
  oficiales» y del bloque de asistencia ya muestra la lectura nueva.
- **Lectura parcial.** Un `200` puede traer cursos que no se leyeron. Hasta el siguiente intento o
  hasta cerrar la app, una tarjeta de `/mis-notas` cuyo estado `grades` en ese resultado no es
  `read`, y un bloque de asistencia cuyo estado `attendance` no es `updated`, muestran bajo su
  encabezado `No se pudo leer en esta actualización.` (12, texto secundario, D6). Los avisos de
  `warnings` no se muestran uno por uno (D6).
- **Error.** La hoja se cierra y vacía la contraseña y el código, como pide la maqueta, y
  `ultimoAviso` queda con el aviso de RF-RCG-4. La vista anterior no cambia, así que las notas y la
  asistencia leídas antes siguen a la vista.
- **Plazo vencido o fallo de red.** Antes de cerrar la hoja, `recargar()` vuelve a pedir la vista
  (RF-RCG-1, D23). Si esa vista muestra que la recarga sí se guardó, la hoja sigue el camino del
  éxito, sin línea de lectura parcial. Si no, sigue el del error. Con el presupuesto por defecto
  del backend, de 60 000, su peor caso es de 82 s desde que recibe la petición, así que el backend
  ya terminó cuando vence el plazo de la app, salvo que la ida y la vuelta por la red del teléfono
  sumen más de 8 s. Con un presupuesto mayor, hasta el máximo de 65 000, ese margen se achica
  hasta los 3 s que reserva la cota (hueco 5). Si la red tarda más que ese margen, y tras un
  fallo de red, el backend puede seguir trabajando hasta su peor caso, y un «Reintentar» en ese
  lapso recibe `409 PORTAL_REFRESH_IN_PROGRESS`, cuyo aviso ya pide esperar.
- **`401`.** Es la expiración del JWT y la maneja `ApiClient` como siempre, que cierra la sesión.
  El backend nunca responde `401` por un fallo del portal.

`[@test] ../../../test/HU37_jeff/recarga_ulima_service_test.dart`
`[@test] ../../../test/HU37_jeff/hoja_recarga_test.dart`
`[@test] ../../../test/HU37_jeff/mis_notas_ulima_test.dart`
`[@test] ../../../test/HU37_jeff/asistencia_recarga_test.dart`

### RF-RCG-4. El aviso rojo persistente

Cuando una recarga falla, el aviso ocupa el lugar de la franja de `/mis-notas` (RF-RCG-6) y
aparece también, en versión compacta, en el bloque de asistencia de la ficha (RF-RCG-8). Vive en
`ultimoAviso`, en memoria. Se borra cuando el alumno envía un nuevo intento desde la hoja, al
tocar «Cargar mis datos», al cerrar sesión, al cambiar el alumno dueño (RF-RCG-1), al cerrar la
app (D17) y, si es el aviso del plazo o de la red, cuando una lectura posterior muestra que la
recarga sí se guardó (D23). Un aviso nuevo reemplaza al anterior.

**Forma en `/mis-notas`.** La tarjeta de la franja con el borde en rojo al 30 %, el ícono
`Icons.error_outline` de 20 en rojo (`Colors.red`) sobre una caja de rojo al 12 %, el título
`No se pudo actualizar` (14, peso 800, `textPrimary`), el cuerpo de la tabla de abajo (11,
`textSecondary`) y, si la vista tiene `lastReadAt`, la línea
`Se muestran las notas leídas hoy a las 10:42.` (11, `textSecondary`, D14), armada con RF-RCG-9.
Debajo va la acción, un botón de texto (12, peso 800, naranja de D11) con blanco táctil de 48. La
tarjeta lleva `Semantics(liveRegion: true)` para que el lector de pantalla la anuncie al aparecer.

**Mensajes y acciones** (D5). El título es siempre `No se pudo actualizar`. La app nunca muestra el
`message` del backend tal cual.

| Causa | Cuerpo | Acción |
| --- | --- | --- |
| `409 PORTAL_LOGIN_REJECTED` | `miUlima rechazó los datos. Revisa tu contraseña y que el código del autenticador siga vigente.` | `Reintentar` |
| `429 RATE_LIMITED`, `details.kind` = `quota` | `Llegaste al límite de actualizaciones por hora. Intenta de nuevo en N minutos.` | `Reintentar` |
| `429 RATE_LIMITED`, `details.kind` = `rejected_logins` | `Hubo varios intentos con datos rechazados. Para cuidar tu cuenta de miUlima, intenta de nuevo en N minutos.` | `Reintentar` |
| `429 RATE_LIMITED` sin `details` | `Hubo demasiados intentos. Intenta de nuevo más tarde.` | `Reintentar` |
| `409 PORTAL_REFRESH_IN_PROGRESS` | `Ya hay una actualización en curso. Espera a que termine y vuelve a intentarlo.` | `Reintentar` |
| `409 IMPORT_REQUIRED` | `Primero carga tus datos del ciclo.` | `Cargar mis datos`, que abre `/portal-sync`, espera su resultado y, si vuelve `true`, llama a `cargar()` |
| `409 PORTAL_SESSION_INVALID` | `miUlima cerró la sesión antes de terminar. Inténtalo de nuevo.` | `Reintentar` |
| `403 PORTAL_IDENTITY_MISMATCH` | `La cuenta de miUlima no corresponde a tu usuario de ULima++.` | `Reintentar` |
| `422 PORTAL_IDENTITY_UNVERIFIABLE` | `No se pudo confirmar tu identidad en miUlima.` | `Reintentar` |
| `502 PORTAL_UNAVAILABLE` | `miUlima no está respondiendo. Inténtalo más tarde.` | `Reintentar` |
| `502 PORTAL_UNREADABLE` | `miUlima responde con páginas que ULima++ no sabe leer.` | `Reintentar` |
| `504 PORTAL_TIMEOUT` | `miUlima tardó demasiado en responder. Inténtalo más tarde.` | `Reintentar` |
| Plazo de 90 s de la app | `La actualización tardó demasiado. Inténtalo de nuevo en unos minutos.` | `Reintentar` |
| Fallo de red sin respuesta | `No hay conexión. Revisa tu internet e inténtalo de nuevo.` | `Reintentar` |
| `400`, `500` o un código desconocido | `Algo falló al leer miUlima. Inténtalo de nuevo.` | `Reintentar` |

`N` sale de `details.retryAfterMinutes`, y con 1 el texto dice `1 minuto`. Todo aviso lleva una
acción, porque el aviso reemplaza a la franja y sin acción el alumno no tendría cómo volver a
abrir la hoja. `Reintentar` abre otra vez la hoja, vacía, también tras un `429` o un `403`, en
los que el backend vuelve a responder lo mismo mientras dure la causa. El aviso sigue a la vista
mientras la hoja está abierta y se borra al enviar.

Dos filas cubren más de un caso del backend, y la app no las distingue porque nunca lee el
`message`. El `409 IMPORT_REQUIRED` llega antes de tocar el portal, sin período activo o sin
matrícula activa, y también después de iniciar sesión, cuando la ULima ya muestra otro ciclo
(decisión B19). El mismo cuerpo y «Cargar mis datos» sirven para los dos, porque la importación
es la que activa el ciclo nuevo, aunque el segundo caso sí gasta una de las recargas de la hora.
El `409 PORTAL_REFRESH_IN_PROGRESS` llega con otra recarga del mismo alumno en curso y también con
una importación con contraseña en curso, y su cuerpo vale para las dos.

`[@test] ../../../test/HU37_jeff/recarga_ulima_service_test.dart`
`[@test] ../../../test/HU37_jeff/mis_notas_ulima_test.dart`

### RF-RCG-5. La fila «Notas oficiales» en la calculadora (cambio 1)

El `IconButton` del birrete (`calculadora_page.dart:40-44`) sale, y el título queda solo en su
fila. Bajo «Cursos con notas: N», dentro del mismo encabezado, aparece una fila tocable que ocupa
todo el ancho, en `lib/components/recarga_ulima/fila_notas_oficiales.dart`.

- **Estilo de «Selecciona un Curso».** Margen superior de 12, esquinas de 12, fondo `primary` al
  10 % y borde `primary` al 30 %, relleno de 8 arriba y abajo, 12 a la derecha y 14 a la
  izquierda, y alto mínimo de 48. A la izquierda, `Icons.school_outlined` de 22 en
  `MaterialTheme.iconoNaranja`. En el centro, `Notas oficiales` (14, peso 700, `onSurface`) y,
  debajo, la segunda línea (12, `onSurface` al 70 %). A la derecha, `Icons.chevron_right` de 22 en
  `onSurface` al 50 %.
- **Segunda línea.** Depende solo de la vista del alumno actual (RF-RCG-1), no de `errorCarga`.
  Con vista y `lastReadAt` presente, `Última lectura hoy a las 10:42` (RF-RCG-9), también si una
  carga posterior falló, porque esa hora sigue siendo la de los datos que la calculadora
  muestra. Con vista y `lastReadAt` en `null`, `Aún no se actualizan desde la ULima`. Sin vista,
  porque la primera carga está en curso o porque falló, la fila lleva solo el título.
- **Toque.** `Get.toNamed('/mis-notas')`. La fila no espera resultado, porque la calculadora lee
  `vista` y se actualiza sola.
- **Estados de la calculadora.** La fila está en los tres estados de hoy, con notas, sin notas y
  con el error de cursos, porque vive en el encabezado y no en la lista.
- **Accesibilidad.** Un solo nodo `Semantics` de botón con la etiqueta
  `Notas oficiales. Última lectura hoy a las 10:42`, o la variante sin lectura, y los hijos
  excluidos. Con el texto al 200 % las dos líneas se parten sin cortarse.
- **Controller.** `CalculadoraController` expone `ultimaLecturaUlima` y las filas de la ULima por
  curso como `Rx` propios y los llena desde `RecargaUlimaService` en `onInit`, con la guarda
  `Get.isRegistered`. La página nunca hace `Get.find` del servicio. Así la prueba HU07, cuyo doble
  reemplaza `onInit`, sigue pasando sin cambios.
- **README.** La frase de `README.md:102` que dice que a `/mis-notas` se llega por el ícono
  `school_outlined` de la calculadora deja de ser cierta con este cambio, así que el PR de
  implementación la corrige para nombrar la fila «Notas oficiales», aparte de lo que cambia por
  la decisión B12.

`[@test] ../../../test/HU37_jeff/calculadora_ulima_test.dart`

### RF-RCG-6. La pantalla «Notas oficiales» (`/mis-notas`, cambio 2)

La pantalla conserva su AppBar, su fondo, sus tarjetas y su insignia «Final». Cambian su fuente de
datos y lo que muestra cada fila, y suma la franja.

**Fuente.** `MisNotasController` deja de usar `OfficialGradesService` y lee `RecargaUlimaService`.
`load()` llama a `cargar()`, y la lista sale de `vista.cursos`, en el orden en que llegan. Es la
opción aprobada de la decisión B10. `OfficialGradesService` no cambia y lo siguen usando las
pantallas del docente. Para la sigla del prefijo (D9), el controller lee además
`EvaluationSyllabusService`, que la calculadora ya deja en caché, y si su carga falla las filas
van sin prefijo.

**Franja** (`lib/components/recarga_ulima/franja_recarga.dart`). Es el primer elemento de la
lista, con margen inferior de 12, y copia la tarjeta «Actualizar desde miUlima» del Perfil
(`perfil.dart:649-713`). Fondo `cardBg`, borde `borderColor`, esquinas de 14 y relleno de 14. A la
izquierda, la caja de 42 con esquinas de 12 en `espPrincipalBg` y `LucideIcons.refreshCw` de 20 en
`primaryDark`. En el centro, `Actualizar desde la ULima` (14, peso 800, `textPrimary`) y, debajo,
`Última lectura hoy a las 10:42` o `Aún no se actualizan desde la ULima` (11, `textSecondary`). A
la derecha, `LucideIcons.chevronRight` de 18 en `textMuted`. Tocarla abre la hoja (RF-RCG-2). Con
`ultimoAviso` presente, la franja se reemplaza por el aviso de RF-RCG-4. La franja lleva un
`Semantics` de botón con la etiqueta `Actualizar desde la ULima. Última lectura hoy a las 10:42`.

**Tarjeta de curso.** Igual que hoy, con `courseName` y `Sección <sectionCode>`. Bajo esa línea,
según el caso, va una línea de 12 en `textSecondary`.

- Curso con `lastReadAt` en `null` y sin evaluaciones, `Aún no se actualizan desde la ULima`, sin
  filas.
- Curso sin lectura en el último resultado, `No se pudo leer en esta actualización.` (RF-RCG-3).
- Si un curso cumple los dos casos, porque nunca se leyó y además falló en el último resultado,
  la tarjeta lleva solo `No se pudo leer en esta actualización.`, que es el dato más reciente.

**Fila de evaluación.** Una por cada elemento de `evaluaciones`, en el orden en que llegan (por
semana, las sin semana al final, y luego por clave).

- A la izquierda, en 13 y `textPrimary`, el nombre con el prefijo de la sigla del sílabo cuando la
  evaluación tiene pareja, como hoy (`EV01 · Examen escrito 1`), o solo el nombre de la ULima
  cuando no la tiene (D9). Debajo, `Semana N` (11, `textSecondary`), que no se pinta si `week` es
  `null`.
- En el centro, el peso, `20%`, en 12 y `textSecondary`, con el formato de D10.
- A la derecha, en una caja de 56 de ancho alineada a la derecha, la nota en 14, peso 800 y
  `textPrimary` con el formato de D10 si `mark` es `graded`, `NP` con el mismo estilo si es `np`
  (decisión B8), o `Sin nota` en 12, peso 600 y `textSecondary` si es `pending`.
- Las evaluaciones sin pareja en el sílabo (`match: none`) se muestran igual que las demás
  (decisión B7).

**Insignia «Final».** Igual que hoy. Suma el valor por el peso entre 100 de cada evaluación
publicada, cuenta `NP` como 0 (decisión B8) y las `pending` como 0, y aparece solo si el curso
tiene al menos una `graded` o `np`. Su umbral sigue en 10.5 (`mis_notas_page.dart:208`) con la
opción aprobada de la decisión B9.

**Estados.**

| Estado | Qué se ve |
| --- | --- |
| Primera carga | El esqueleto de hoy (`SkeletonCardList(count: 4)`), sin franja. |
| Error de carga sin datos | El vacío de hoy con `Icons.wifi_off` y `No se pudieron cargar tus notas oficiales.`, sin franja. |
| Sin cursos (`courses: []` en el JSON, `vista.cursos` vacía) | El vacío de hoy con `Icons.school_outlined` y `Aún no tienes cursos con notas oficiales.`, sin franja, porque una recarga respondería `409 IMPORT_REQUIRED`. |
| Antes de la primera lectura | La franja con `Aún no se actualizan desde la ULima` y las tarjetas con esa misma línea y sin filas. |
| Sin notas publicadas | La franja con la hora y las filas con `Sin nota`, sin «Final». Es el estado del sondeo de la semana 5. |
| Con notas | La franja con la hora, las filas con su nota y la insignia «Final». |
| Recarga fallida | El aviso de RF-RCG-4 en lugar de la franja y la vista anterior debajo. |
| Sin conexión al recargar la lista | La flecha del AppBar o el tirón hacia abajo conservan la vista que había, como hoy, porque el error solo se muestra sin datos. |

**Flecha del AppBar y tirón hacia abajo.** Siguen consultando solo a ULima++, ahora con `cargar()`.
No entran a miUlima.

`[@test] ../../../test/HU37_jeff/mis_notas_ulima_test.dart`

### RF-RCG-7. Las notas de la ULima en la calculadora (cambio 3)

**Qué entra.** De cada curso de `vista` que coincide con una sección de la calculadora (por
`sectionId`, comparado como texto con `curso['id']`), entran las evaluaciones con `mark` en
`graded` o `np` y con pareja en el sílabo (`match` distinto de `none`). Las `pending` no entran,
porque todavía no hay nota, y siguen disponibles para simular. Las que no tienen pareja no entran
(decisión B7).

**Cómo se ven.** Cada una es un `NotaTile` con el mismo contenedor, la misma tipografía y la línea
`Peso: 20%  •  Nota: 15.0/20` de siempre, con el formato de D10, o `Peso: 20%  •  Nota: NP` con
`np`. El título es el `name` de la ULima (D8). En lugar del tacho va la marca `ULima`, que no es
tocable. Es una píldora con el tamaño de `RecordPositionBadge` (relleno de 10 por 4, texto de 11
y peso 800), fondo `espPrincipalBg` y texto en el naranja de D11, en un alto de 40 como el tacho,
así que la fila mide lo mismo. La fila no se puede borrar ni editar. Su `Semantics` dice
`Examen escrito 1, peso 20 por ciento, nota 15.0 de 20, publicada por la ULima`.

**API de `NotaTile`.** Hoy recibe `int peso`, `double nota` y un `onDelete` obligatorio
(`nota_tile.dart:5-8`), así que no puede pintar `12.5%`, `NP` ni la marca. Cambia de forma
compatible con las llamadas de hoy. `peso` pasa a `num`, `nota` pasa a `double?`, y suma
`np` (falso por defecto) y `deUlima` (falso por defecto). `onDelete` pasa a `VoidCallback?`, con
un `assert` que lo exige cuando `deUlima` es falso. Con `deUlima`, el tile pinta la marca en lugar
del tacho, no abre el diálogo `Eliminar Nota` y lleva el `Semantics` de arriba. Con `np`, la línea
dice `Nota: NP`, y `nota` puede llegar `null`. En las dos clases de filas, el peso se escribe
con la función pura de D10 (`20%` o `12.5%`) y la nota con un decimal, como hoy (D10), así que
una misma tarjeta nunca mezcla `14.25` y `14.3`. Las funciones de formato viven en
`lib/domain/recarga_ulima/formato_nota.dart`.

**Promedio y suma de pesos.** `POST /grades/me/calculate` recibe las filas visibles del curso, las
simuladas y las de la ULima, con `NP` como 0 (decisión B8) y el peso exacto de la ULima, sin
truncar. La barra «Suma de pesos» suma también esas filas. El aviso «Desaprobado» conserva su
umbral de hoy, por debajo de 11 (`curso_card.dart:95`), con la opción aprobada de la decisión
B9.

**Una evaluación con las dos notas.** Si el alumno tiene una nota simulada para una evaluación
que la ULima ya publica (mismo `assessmentId`), se ve solo la fila de la ULima y el promedio usa
solo esa. La simulada no se borra de `simulated_grades` y vuelve a verse si la ULima retira la nota
(decisión B6).

**Guardar y borrar.** Las filas de la ULima viven en una lista aparte de `curso['notas']`, así que
`_guardarNotasRemotas` sigue mandando solo las simuladas, incluidas las que quedan ocultas, y nunca
una de la ULima. `CursoCard` trata la ausencia de esa lista aparte como una lista vacía, porque el
doble de HU07 arma sus cursos sin ella. El borrado conserva la firma
`eliminarNota(int cursoIndex, int notaIndex)`, que el doble de HU07 sobrescribe
(`test/HU07_sam/calculadora_flujo_cajanegra_test.dart:89`), y el `onDeleteNota` de `CursoCard`
sigue con la forma `Function(int, int)`. `notaIndex` es la posición de la simulada en
`curso['notas']`, la lista de simuladas, y no en la lista visible, que mezcla las dos clases de
filas y omite las simuladas ocultas. `CursoCard` traduce la fila visible a ese índice buscando en
`curso['notas']` la simulada con el mismo `evaluacionId`.

**Registrar Nota.** `getAvailableEvaluations` excluye también las evaluaciones con una fila de la
ULima visible. El modal, sus textos y su validación no cambian.

**Qué cursos se ven.** Un curso aparece si tiene al menos una fila visible, simulada o de la ULima,
así que un curso con notas publicadas y sin simulaciones aparece, como el tercero de la maqueta.
«Cursos con notas: N» cuenta esos cursos. El vacío «No hay notas registradas» sale solo si ningún
curso tiene filas.

**Orden de las filas.** El de `evaluaciones` del sílabo de la sección (semana y código), con las
que no están en el sílabo al final en su orden de hoy (D7).

**Sílabo que no coincide.** Si el curso tiene alguna evaluación de la ULima sin pareja, su tarjeta
suma al final de sus filas la línea
`La ULima publica evaluaciones que no están en el sílabo cargado. Míralas en Notas oficiales.`
(12, `onSurface` al 70 %, con `Icons.info_outline` de 16, D15).

**Cuándo se carga y se recalcula.** En `onInit`, si el servicio está registrado y todavía no
tiene vista para el alumno actual (su getter filtrado devuelve `null`, RF-RCG-1), el controller
llama a `cargar()`, y `recargarTodo()` (RF-RCG-11) la vuelve a pedir siempre. Con cada cambio de
`vista` (un `ever` que el controller cierra en `onClose`), el controller rehace las filas de la
ULima desde el getter filtrado y pide el promedio de los cursos que cambian. Un fallo de
`GET /grades/me/ulima` sin vista previa del alumno deja la calculadora como hoy, sin filas de la
ULima. Con vista previa del mismo alumno, las filas siguen, igual que la hora de RF-RCG-5.

`[@test] ../../../test/HU37_jeff/filas_calculadora_test.dart`
`[@test] ../../../test/HU37_jeff/calculadora_ulima_test.dart`
`[@test] ../../../test/HU37_jeff/formato_nota_test.dart`

### RF-RCG-8. La asistencia en la ficha del curso

**Con datos.** Bajo la fila de horas y anillo del bloque de asistencia (`descrip_cursos.dart:184-303`)
se suma una fila, en `lib/components/recarga_ulima/pie_asistencia.dart`, con dos piezas (D1).

- A la izquierda, expandida, `Última lectura hoy a las 10:42` (12, `onSurfaceVariant`), armada con
  RF-RCG-9 sobre `asistenciaLeidaEn` de la sección. Con `asistenciaLeidaEn` en `null`, la línea no
  se pinta (D2).
- A la derecha, un `TextButton.icon` con `Icons.sync` de 18 y el texto `Actualizar`, con blanco
  táctil de 48 y el color de texto de D11 sobre `bloqueAsistencia`. Abre la hoja (RF-RCG-2).

Si el último resultado no trae esta sección como leída, debajo va `No se pudo leer en esta actualización.`
(12, `onSurfaceVariant`, RF-RCG-3). Con `ultimoAviso` presente, la fila muestra en su lugar el
aviso compacto, con `Icons.error_outline` de 18 en rojo, `No se pudo actualizar` (13, peso 800)
y el cuerpo de RF-RCG-4 (12), y el botón cambia a la acción de ese aviso.

**Sin datos.** En el estado de `descrip_cursos.dart:314-360`, el botón pasa a decir
`Actualizar desde la ULima`, con el color de texto de D11, y abre la hoja en vez de
`/portal-sync` (D3). Los textos `Sin datos de asistencia para este curso.` y
`Todavía no se importaron tus horas de clase desde miUlima.` no cambian. Como D19 no muestra el
éxito, este estado también lleva las dos señales de la recarga, entre la línea
`Todavía no se importaron…` y el botón, separadas por 12 como el resto del bloque.

- Si el último resultado no trae esta sección como leída, `No se pudo leer en esta actualización.`
  (12, `onSurfaceVariant`). Es el caso de un `200` en el que el menú de miUlima no trae el curso
  (`missing`) o su página falla, y sin esta línea el bloque quedaría igual y mudo.
- Con `ultimoAviso` presente, el aviso compacto de arriba, en lugar de esa línea, y el botón
  cambia a la acción del aviso.

**Estado por curso.** El estado del último resultado se busca comparando `sectionId` como texto
con `idSeccion`, como en RF-RCG-7.

**Sin el servicio.** La ficha lee `RecargaUlimaService` solo con la guarda
`Get.isRegistered<RecargaUlimaService>()`, como la calculadora (RF-RCG-5). Sin el servicio, el
bloque queda como hoy, sin la fila nueva, y el botón del estado sin datos sigue abriendo
`/portal-sync`. Así `test/HU23_jeff/chat_ficha_curso_test.dart` y
`test/HU35_jeff/time_blocks_acciones_test.dart`, que montan `DescripCursosPage` sin el servicio,
siguen pasando sin cambios.

**Después de una recarga.** Si la hoja termina con `200`, la ficha llama a un método nuevo,
`DescripCursosController.recargarSeccion(idSeccion)`, y no llama ella a
`HorarioController.reload()`, que ya corre una sola vez desde el servicio (RF-RCG-3).
`recargarSeccion` pide primero `GET /course-detail/sections/:id`, que trae las horas del alumno
autenticado y `asistenciaLeidaEn`, porque `reload()` se traga sus errores
(`horario_controller.dart:176-193`) y `uniqueEnrolledCourses` puede seguir vieja. Solo si esa
petición falla, espera `recargaHorario` (RF-RCG-3) y busca la sección en
`uniqueEnrolledCourses`. Si ninguna de las dos la trae, la sección no cambia. Si alguna la trae,
la reemplaza en `secciones` y en `seccionActual` sin tocar anuncios, asesorías ni contactos. La
pestaña elegida no cambia.

**Modelo.** `Seccion` suma `asistenciaLeidaEn` (`DateTime?`), leído de `asistenciaLeidaEn` con
`DateTime.tryParse`. Un backend sin RS-BE-58 no lo manda y queda `null`. Las horas siguen
truncadas a entero como hoy (`seccion_model.dart:72-83`).

**Alto.** La fila nueva suma unos 52 de alto al bloque. En un iPhone SE vertical, la pestaña
elegida conserva al menos 200 de alto visible, y la verificación manual lo comprueba.

`[@test] ../../../test/HU37_jeff/asistencia_recarga_test.dart`

### RF-RCG-9. La hora de la última lectura

Una función pura, `cuandoSeLeyo(DateTime leidoEn, DateTime ahora)`, en
`lib/domain/recarga_ulima/ultima_lectura.dart`, devuelve la parte variable del texto (D22).

- Las dos fechas se llevan a hora de Lima (UTC−5 todo el año, sin horario de verano) con
  `enHoraDeLima` de `chat_linea_tiempo.dart`, que es pública, y se comparan por fecha de
  calendario.
- Mismo día, o un `leidoEn` posterior a `ahora` por un reloj atrasado, da `hoy a las HH:mm`. El
  día anterior da `ayer a las HH:mm`. Otro día del mismo año da `el 22 de septiembre a las HH:mm`,
  con el mes en minúscula. Otro año suma ` de 2025` después del mes. La lista de meses vive en
  `ultima_lectura.dart`, con los mismos doce nombres, porque la de `chat_linea_tiempo.dart`
  (`_meses`, `:133`) es privada y ese archivo no está en `targets`.
- `HH:mm` va en 24 horas y con ceros a la izquierda.
- Los textos completos son `Última lectura <cuándo>` en la fila, la franja y el bloque de
  asistencia, y `Se muestran las notas leídas <cuándo>.` en el aviso.

`[@test] ../../../test/HU37_jeff/ultima_lectura_test.dart`

### RF-RCG-10. Modo oscuro y contraste

Cada pieza usa tokens de `MaterialTheme` o del `ColorScheme`, nunca un color fijo que solo sirva
en claro. Los contrastes de esta tabla salen de la fórmula de WCAG 2.1 sobre los valores de
`themes.dart`, y la prueba de contraste los fija.

| Pieza | Claro | Oscuro | Mínimo |
| --- | --- | --- | --- |
| Segunda línea de la fila «Notas oficiales» | 6,04:1 | 7,95:1 | 4,5:1 |
| Ícono de la fila (`iconoNaranja`) | 3,64:1 | 5,00:1 | 3:1 |
| Flecha de la fila (`onSurface` al 50 %) | 3,25:1 | 4,81:1 | 3:1 |
| Texto de la marca `ULima` (`#A34300` en claro, `#FF8C42` en oscuro, sobre `espPrincipalBg`) | 5,66:1 | 5,92:1 | 4,5:1 |
| Texto `Nota: …/20` de las filas de la ULima (`primary` sobre `tertiaryContainer`, heredado de `NotaTile`, D24) | 2,44:1 | 5,55:1 | 4,5:1, **no se cumple en claro** |
| Ícono de la franja (`primaryDark` sobre `espPrincipalBg`, como la tarjeta del Perfil) | 3,73:1 | 3,32:1 | 3:1 |
| Segunda línea de la franja y del aviso (`textSecondary` sobre `cardBg`) | 10,35:1 | 6,44:1 | 4,5:1 |
| Acción del aviso (`#A34300` en claro, `#FF6600` en oscuro, sobre `cardBg`) | 6,25:1 | 5,65:1 | 4,5:1 |
| Ícono rojo del aviso sobre su caja | 3,14:1 | 4,00:1 | 3:1 |
| Ícono rojo del aviso compacto sobre `bloqueAsistencia` | 3,13:1 | 3,72:1 | 3:1 |
| Botón `Actualizar` del bloque de asistencia (`#A34300` y `#FF6600` sobre `bloqueAsistencia`) | 5,31:1 | 4,67:1 | 4,5:1 |
| Botón del estado sin datos (`#A34300` y `#FF6600` sobre `bloqueAsistencia`, D11; hoy `primary`, con 2,49:1 en claro) | 5,31:1 | 4,67:1 | 4,5:1 |
| Aviso de consentimiento y ayuda de la hoja (`onSurface` al 70 %) | 6,38:1 | 8,74:1 | 4,5:1 |
| Pista del campo de contraseña (`onSurface` al 60 %) | 4,54:1 | 6,74:1 | 4,5:1 |
| Borde de las casillas y del campo (`onSurface` al 50 %, D13) | 3,31:1 | 5,08:1 | 3:1 |
| Botón `Actualizar` de la hoja (blanco sobre `#FF6600`, D12) | 2,94:1 | 2,94:1 | 4,5:1, **no se cumple** |

Los naranjas de texto entran a `themes.dart` como dos tokens con nombre propio y un comentario
que cita su contraste, como `iconoNaranja`. `textoNaranja` vale `#A34300` en claro y `#FF6600` en
oscuro, para la acción del aviso y los dos botones del bloque de asistencia, e
`insigniaUlimaTexto` vale `#A34300` en claro y `#FF8C42` en oscuro, para la marca `ULima`. El
botón de la hoja repite el color de «Registrar», que tampoco llega a 4,5:1, y la decisión D12
deja ver la alternativa. Las filas de la ULima heredan de `NotaTile` el texto `Nota: …/20` en
`primary` sobre `tertiaryContainer`, igual que las simuladas de hoy, y la decisión D24 deja ver
la alternativa, que cambia la calculadora aprobada.

**Accesibilidad, además del contraste.** Todo lo tocable mide al menos 48 por 48. Cada botón de
solo ícono tiene tooltip. El título de la hoja es un encabezado (`Semantics(header: true)`), el
campo de contraseña y las casillas llevan su rótulo como etiqueta, y las casillas dicen
`Código del autenticador, 6 dígitos`. El texto de la espera y los avisos se anuncian con
`liveRegion`. Con el texto al 200 %, nada se corta y la hoja se desplaza. Ninguna pieza nueva
anima nada, salvo el indicador de la espera.

`[@test] ../../../test/HU37_jeff/contraste_recarga_test.dart`

### RF-RCG-11. La importación recarga la calculadora en vez de borrarla

La fila «Notas oficiales» lleva a `/mis-notas` con la calculadora montada debajo, y desde el aviso
de `IMPORT_REQUIRED` se llega a `/portal-sync`. Al terminar la importación,
`_refrescarPantallas` borra hoy `CalculadoraController` (`portal_sync_controller.dart:140-145`)
con su página todavía montada, y al volver, «Registrar Nota» haría `Get.find` de un controller que
ya no existe. Por eso `_refrescarPantallas` pasa a llamar a un método nuevo,
`CalculadoraController.recargarTodo()`, que vuelve a pedir el sílabo, los cursos, las notas
simuladas y la vista de la ULima y recalcula los promedios (D16). El resto de
`_refrescarPantallas` no cambia.

`[@test] ../../../test/HU37_jeff/portal_sync_refresco_calculadora_test.dart`

## Qué no cambia de la calculadora

Es la lista «Qué no cambia» de la maqueta aprobada, con lo que el código fija.

- La cabecera `ULIMA++` con la campana, el título `Calculadora de Notas` (24, peso 900) y
  `Cursos con notas: N` con su estilo.
- La `CursoCard`, con su cabecera naranja, `Sección: N`, el nombre, `Ciclo: …`, el promedio de 36,
  el aviso `Desaprobado` con su ícono y su umbral de 11, y la barra `Suma de pesos: X% / 100%`.
  La opción aprobada de la decisión B9 conserva los dos umbrales de hoy, 11 para el aviso y
  10.5 para la insignia `Final`. Las otras dos opciones, que el dueño no elige, cambian lo
  aprobado, una el aviso y la otra la insignia.
- Las filas de las notas simuladas, con peso, nota con un decimal, tacho y el diálogo
  `Eliminar Nota`.
- El botón ancho `+ Registrar Nota`, la hoja `Selecciona un Curso` y el modal `Registrar Nota`
  con sus textos (`Evaluación (del Sílabo)`, `Peso automático:`, `Nota (0 - 20)`, los tres errores
  de validación y `<sigla> registrada`).
- El vacío `No hay notas registradas` y `Comienza registrando una nota`, y el error
  `No se pudieron cargar tus cursos` con su reintento.
- El promedio lo sigue calculando `POST /grades/me/calculate`, sin normalizar, y las simuladas se
  siguen guardando en `simulated_grades` con `POST /grades/me/notes` y
  `DELETE /grades/me/notes/:sectionId/:assessmentId`.
- La barra inferior con Malla, Notas, Horario, Chats y Perfil, la calculadora como segunda
  pestaña (`pages[1]`) y la burbuja de Ulises.
- En `/mis-notas`, la barra naranja con `Notas oficiales`, las tarjetas de curso, la insignia
  `Final` y la flecha de recarga, que sigue consultando solo a ULima++.

D7 y D15 tocan la `CursoCard` más allá de los tres cambios aprobados, y el dueño aprueba los
dos el 2026-09-26. D7 ordena las filas según el sílabo, que es el orden que dibuja la maqueta pero
reordena las simuladas, que hoy salen en el orden en que se registraron. D15 suma una línea al
final de la tarjeta cuando la ULima publica evaluaciones que no están en el sílabo.

Lo único que sale es el birrete sin texto junto al título. Las pruebas `test/HU07_sam/**`,
`test/HU06_sam/**` y `test/HU23_jeff/chats_pestana_test.dart` siguen pasando sin cambios, y la
firma de `eliminarNota` que conserva RF-RCG-7 es la que lo permite.

## Textos nuevos

Los que copian la maqueta aprobada llevan la marca (M). Los demás los propone esta spec, y el
dueño los aprueba con ella el 2026-09-26.

| Dónde | Texto |
| --- | --- |
| Fila de la calculadora | `Notas oficiales` (M), `Última lectura hoy a las 10:42` (M), `Aún no se actualizan desde la ULima` (M) |
| Franja | `Actualizar desde la ULima` (M), `Última lectura hoy a las 10:42` (M) |
| Filas de `/mis-notas` | `Semana 4` (M), `Sin nota` (M), `NP` |
| Tarjetas de `/mis-notas` | `Aún no se actualizan desde la ULima`, `No se pudo leer en esta actualización.` |
| Hoja | `Actualizar desde la ULima` (M), `Entras como 20230001` (M), el aviso de consentimiento (M), `Contraseña de miUlima` (M), `Tu contraseña del portal` (M), `Código del autenticador` (M), `El código de 6 dígitos que cambia cada 30 segundos.` (M), `Cancelar` (M), `Actualizar` (M), `Cerrar`, `Mostrar contraseña`, `Ocultar contraseña`, `Leyendo miUlima. Puede tardar hasta un minuto.` |
| Aviso | `No se pudo actualizar` (M), `Reintentar` (M), `Se muestran las notas leídas hoy a las 10:42.` (M), el cuerpo del rechazo (M), los demás cuerpos de RF-RCG-4, `Cargar mis datos` |
| Calculadora | La marca `ULima` (M), `Nota: NP`, la línea del sílabo que no coincide |
| Ficha del curso | `Actualizar`, `Actualizar desde la ULima`, `No se pudo actualizar`, `No se pudo leer en esta actualización.`, en los dos estados del bloque |

## Flujo de datos

```
Calculadora
  onInit -> RecargaUlimaService.cargar() (si no hay vista) -> GET /grades/me/ulima
  ever(vista) -> filas ULima por curso -> POST /grades/me/calculate por curso que cambia
  fila «Notas oficiales» -> Get.toNamed('/mis-notas')

/mis-notas
  MisNotasController.load() -> RecargaUlimaService.cargar() -> GET /grades/me/ulima
  franja -> HojaRecargaUlima -> RecargaUlimaService.recargar(password, passcode)
    -> POST /portal-sync/refresh { credentials, consent: true }
      200 -> vista = view, estados por curso -> recargaHorario = HorarioController.reload() (una vez)
      plazo o red -> cargar() -> lastReadAt más nueva ? como 200, sin estados : aviso
      error -> ultimoAviso -> aviso rojo en la franja y en el bloque de asistencia

Ficha del curso
  botón «Actualizar» -> la misma hoja
    200 -> recargarSeccion(idSeccion) -> GET /course-detail/sections/:id
      si falla -> await recargaHorario -> uniqueEnrolledCourses

Cambio de alumno sin logout (JWT vencido)
  cargar() o recargar() con otro código -> clear() antes de cualquier await
  respuesta con otra generación -> se descarta
```

## Contrato que se consume

Detalle en `docs/specs/api-contracts.md`, secciones Grades, Official Grades, Schedule, Course
Detail y Portal Sync.

- `POST /portal-sync/refresh` (aprobado el 2026-09-26 y por implementar, RS-BE-49 a RS-BE-56).
  Cuerpo, errores, `details.kind` y `details.retryAfterMinutes` del `429`, estados por curso y
  `view`, con el `409 IMPORT_REQUIRED` por cambio de ciclo (decisión B19) y la cota del
  presupuesto de RS-BE-50, con su máximo de 65 000 (hueco 5). Sus dos fases leen los menús de
  Asistencia y de Nota con `parseAulas`, así que sin RS-BE-48 toda recarga termina en
  `502 PORTAL_UNREADABLE` (decisión B1).
- `POST /portal-sync/import`, que la spec del backend amplía de forma aditiva con el
  `409 PORTAL_REFRESH_IN_PROGRESS`, cuando hay una recarga del mismo alumno en curso, y con
  `details.kind` en sus dos `429` (RS-BE-50). `/portal-sync` los muestra con el `message` del
  backend, igual que hoy muestra el `429` y todo código que no traduce
  (`portal_sync_service.dart:111-118`), así que la app no cambia por ellos.
- `GET /grades/me/ulima` (aprobado el 2026-09-26 y por implementar, RS-BE-57).
- `asistenciaLeidaEn` en `secciones` de `GET /schedule/me/sessions` y de
  `GET /course-detail/sections` y `GET /course-detail/sections/:sectionId` (aprobado el
  2026-09-26 y por implementar, RS-BE-58).
- `POST /grades/me/calculate`, sin cambios, que ahora recibe también las filas de la ULima.
- `GET /grades/me/notes`, `POST /grades/me/notes` y `DELETE /grades/me/notes/:sectionId/:assessmentId`,
  sin cambios. Nunca reciben una nota de la ULima.
- `GET /grades/me/courses`, sin cambios, para el orden del sílabo y la sigla.
- `GET /official-grades/me` deja de tener pantalla de alumno por la opción aprobada de B10. La
  ruta sigue en el backend.

### Huecos del contrato

Lo que la maqueta o la app piden y el contrato aprobado no trae o no garantiza. La spec no
inventa campos y resuelve cada uno con lo que ya existe, en la opción por defecto que el dueño
aprueba el 2026-09-26.

1. `GET /grades/me/ulima` no trae la sigla de la evaluación del sílabo, y la fila de `/mis-notas`
   la muestra como prefijo, como hoy. Por defecto la app la toma de `syllabi` en
   `GET /grades/me/courses` por `assessmentId` (D9). Alternativa, que el backend sume
   `assessmentCode` a cada evaluación.
2. `view` trae solo notas. La asistencia nueva exige volver a pedir `GET /schedule/me/sessions`
   después de cada recarga (RF-RCG-3). Alternativa, que la respuesta de la recarga traiga las
   horas y `asistenciaLeidaEn` por curso.
3. `asistenciaLeidaEn` es `null` para las horas importadas antes de la migración `0015`, así que
   la app no puede decir de cuándo son. Por defecto no pinta la línea (D2).
4. El contrato no dice si la ULima redondea el promedio final, y de eso depende cuál sería el
   umbral único con una de las dos alternativas de la decisión B9, que el dueño no elige. La
   opción aprobada conserva los dos umbrales de hoy y no depende de ese dato.
5. La red del teléfono dentro de la cota del presupuesto del backend (D18). RS-BE-50 valida
   `PORTAL_REFRESH_BUDGET_MS` entre 20 000 y 65 000, con 60 000 por defecto, y usa el menor
   entre ese valor y 81 000 − 2 · `PORTAL_TIMEOUT_MS`. Esa fórmula resta a los 90 s de la app
   una petición en vuelo y el cierre de sesión (2 · `PORTAL_TIMEOUT_MS`, con 8 s cada uno por
   defecto), 6 s de transacción y respuesta y 3 s para la ida y la vuelta por la red del
   teléfono. El presupuesto cubre también el inicio de sesión, y el peor caso, contado desde que
   el backend recibe la petición, suma el presupuesto, esa petición en vuelo, la transacción con
   la respuesta y el cierre de sesión. Con los valores por defecto son 82 s, que dejan 8 s para
   la red, y con el máximo son 87 s, que dejan los 3 s reservados. El dueño aprueba el
   2026-09-26 este máximo de 65 000 con 3 s para la red, igual en el backend y en la app, en
   lugar del de 68 000, que no deja ningún margen para la red. Si la ida y la vuelta pasan de
   esos 3 s con el máximo, la app puede dejar de esperar justo antes de que el backend responda,
   y D23 cubre la escritura que llega después del plazo. Los márgenes de 6 s y de 3 s no están
   medidos, y los comprueba la medición de B15, que es la V5 del backend.

## Cambios en otras specs

El dueño los aprueba el 2026-09-26 junto con esta spec, y cada nota de enmienda registra esa
aprobación.

- `specs/features/grades/grades.spec.md`. Nota de enmienda con los tres cambios aprobados, dos en
  la calculadora (RF-RCG-5 y RF-RCG-7) y uno en `/mis-notas` (RF-RCG-6), que remite a «Qué no
  cambia de la calculadora». Anota además que la línea que dice que las notas se guardan
  en `student_score` describe mal el código, que las guarda en `simulated_grades`.
- `specs/features/course-detail/course-detail.spec.md`. Nota de enmienda con el botón, la hora de
  la última lectura y `recargarSeccion` (RF-RCG-8).
- `specs/features/portal-sync/portal-sync.spec.md`. BR-SYNC-F-06 recarga la calculadora en vez de
  borrarla (RF-RCG-11), la hoja reutiliza `PasswordResetOtpField` con cuatro parámetros
  opcionales que `/portal-sync` no usa (RF-RCG-2) y el aviso de `IMPORT_REQUIRED` es una entrada
  nueva a `/portal-sync`. Anota también que la pantalla muestra con el `message` del backend el
  `409 PORTAL_REFRESH_IN_PROGRESS` y el `429` con `details.kind` que la importación suma en la
  spec del backend, sin cambio de código.
- `specs/features/academic-record/academic-record.spec.md`. RF-REC-6 sigue rigiendo la
  importación. La recarga no pasa por `PortalConsentView` y lleva su propio aviso (decisión B4).
- `specs/features/schedule/schedule.spec.md`. `HorarioController.reload()` también corre una vez
  después de una recarga, desde `RecargaUlimaService`, y las secciones traen `asistenciaLeidaEn`.
- `docs/specs/api-contracts.md`. Las dos rutas nuevas, el campo nuevo, la sección Official Grades,
  que faltaba, las correcciones de la importación que ya recoge el contrato del backend
  (representantes, asistencia y `400 INVALID_REQUEST_BODY`), lo que la importación comparte con
  la recarga (tope de rechazos, guarda de un inicio de sesión a la vez y `details.kind`), el
  `409 IMPORT_REQUIRED` por cambio de ciclo y la cota del presupuesto, con su máximo de 65 000
  (hueco 5).
- `docs/specs/feature-index.md`. La fila 22.
- `README.md:102`, en el PR de implementación, en la frase que nombra la entrada a `/mis-notas`
  (RF-RCG-5). La misma línea cambia además la fuente de `/mis-notas` por la decisión B10 y la
  frase «Nunca se mezclan» por la decisión B12.
- `AGENTS.md` y `KNOWLEDGE.md`, en el PR de implementación, con el texto único de la decisión
  B12.

## Qué NO entra

- La mínima, la máxima, los agregados y el «Promedio» de la clase que publica la ULima (decisión
  B18), el grupo `EVC` y la clave `07.13`.
- Borrar las notas de la ULima a pedido (decisión B14), notificaciones cuando se publica una nota y
  cualquier recarga automática.
- Recordar la contraseña o el código entre recargas.
- Cambiar `PortalConsentView`, `/registro` o el flujo de la importación, salvo RF-RCG-11.
- Rediseñar la calculadora más allá de los tres cambios, como listar todos los cursos, mostrar las
  evaluaciones pendientes, proyectar la nota necesaria o dejar de truncar el peso de las simuladas.
- Un botón de recarga dentro de la calculadora. Su entrada es la fila «Notas oficiales».
- Las notas de `student_score` en una pantalla de alumno (decisión B10), las alertas y el chatbot
  (decisión B11) y cualquier cambio en las pantallas del docente.
- Fechas por sesión de la asistencia o un porcentaje nuevo en el bloque.

## Decisiones

El dueño aprueba el 2026-09-26 todas las decisiones y todos los puntos en su opción
recomendada, que es la que cada fila adopta por defecto (decisión 5 del dueño). La numeración
no cambia, porque la citan los requisitos, y la columna «Alternativa» guarda lo que el dueño no
elige.

### Decisiones del backend que cambian la app (B1 a B19)

Llevan el número de las decisiones de la spec del backend, y su opción aprobada es la misma en
las dos specs. En B9, la versión `0161dee` del backend adopta la opción de la app, que
conserva los dos umbrales de la calculadora aprobada.

| # | Decisión | Opción aprobada el 2026-09-26 y efecto en la app | Alternativa |
| --- | --- | --- | --- |
| B1 | RS-BE-48 como corrección aparte | Sí. RS-BE-48 va primero, en un PR propio del backend que lleva también la parte de delegados. La app no cambia, pero ningún botón funciona sin RS-BE-48 en producción. Los menús de Asistencia y de Nota llegan con el mismo formato de lista, RS-BE-51 y RS-BE-52 leen los dos con `parseAulas` y, sin RS-BE-48, toda recarga termina en `502 PORTAL_UNREADABLE`, que la app muestra con su aviso. Por eso la app se publica solo con RS-BE-48 desplegado («Verificación»). | Publicarlo junto con la recarga, con la misma condición de publicación. |
| B2 | Endpoint propio o importación completa | `POST /portal-sync/refresh` y la hoja de RF-RCG-2. | Los botones abren `/portal-sync` con el consentimiento de RF-REC-6 en cada toque, y `/mis-notas` necesita además B13. |
| B3 | Cupo, tope de rechazos y guarda de inicio de sesión | 5 recargas por hora, aparte de las 5 de la importación, y 3 rechazos cada 15 minutos, contados junto con los de la importación con contraseña, que además comparte con la recarga la guarda de un solo inicio de sesión a la vez. La app muestra los textos de RF-RCG-4 sin citar números. | Compartir las 5 por hora con la importación, otros números o una guarda solo entre recargas, que no cambian la app. |
| B4 | Consentimiento en cada recarga | El aviso de la hoja aprobada y `consent: true` en cada recarga, sin tocar `PortalConsentView`. | Una casilla sin marcar, `Acepto que ULima++ lea en miUlima mis notas parciales y mi asistencia.`, que enciende «Actualizar» junto con los dos campos. |
| B5 | Tabla, hora de lectura y migración `0015` | La tabla `student_portal_score` y las dos horas de lectura de `enrollment`, en la migración `0015`, con borrado en cascada desde la matrícula. Es una aprobación de diseño de BD, y aplicar la `0015` en producción sigue pidiendo un respaldo y el permiso del dueño en el momento del despliegue. La app depende solo de la forma del contrato. | Otro guardado con la misma forma no cambia la app. |
| B6 | Nota simulada cuando la ULima publica la misma evaluación | Se ve la de la ULima, la simulada no se borra y vuelve si la ULima la retira (RF-RCG-7). | Borrar la simulada al guardar la de la ULima. |
| B7 | Notas de la ULima sin pareja en el sílabo | Se ven en `/mis-notas`, no entran a la calculadora y la tarjeta avisa (RF-RCG-7). | Entran a la calculadora con su peso, aunque la suma pase de 100. |
| B8 | «NP» | Se ve `NP` y cuenta como 0 en el promedio y en «Final». | No contarlo, o hacer fallar al curso hasta tener una muestra. |
| B9 | Umbral único de aprobación | Ningún umbral único. Se conservan los dos de hoy, 11 para el aviso «Desaprobado» de la calculadora (`curso_card.dart:95`) y 10.5 para la insignia «Final» de `/mis-notas` (`mis_notas_page.dart:208`). Es la única opción que calza con la maqueta aprobada, que dibuja `prom < 11` y `fin >= 10.5` y pone los dos en «Qué no cambia», y la misma del backend. | 10.5 en las dos pantallas, que cambia la calculadora aprobada, porque el aviso baja de 11 a 10.5. U 11 en las dos si la ULima no redondea, que cambia la insignia «Final» aprobada. |
| B10 | Papel de `/mis-notas` y de las notas del docente | `/mis-notas` lee `GET /grades/me/ulima`, y las notas de `student_score` se quedan sin pantalla de alumno. | Mostrar las dos por evaluación, con la de la ULima mandando, o retirar la carga docente. |
| B11 | Alertas de riesgo y chatbot | Siguen como hoy. | Que lean las notas de la ULima, cada uno con su enmienda. |
| B12 | La regla «las notas son personales y no oficiales» | Cambia en el PR de implementación, en `AGENTS.md:58`, `KNOWLEDGE.md:72` y `README.md:102`, con el texto de abajo, que es el mismo en los dos repositorios. | Un texto distinto en cada repositorio, otro texto o no tocarla, y entonces la calculadora no puede mostrar las notas de la ULima. |
| B13 | La importación completa también lee el panel Nota | No. | Sí, y la importación también actualizaría `/mis-notas`. |
| B14 | Borrado de las notas de la ULima a pedido | Sin ruta nueva. | `DELETE /grades/me/ulima` y un botón en `/mis-notas`, con su spec. |
| B15 | Medición desde `iad1` antes de publicar | Obligatoria. Con la `0015` aplicada, el dueño corre tres recargas con su cuenta desde un despliegue en `iad1`. La app se publica después del despliegue del backend y solo si las tres terminan en 45 s o menos y sin `504`. | Otro tope, o publicar confiando solo en el presupuesto de 60 s. |
| B16 | Quién carga las evaluaciones del sílabo en ciclos futuros | La carga manual del dueño antes de cada ciclo. Sin ella, todas las notas de la ULima quedan sin pareja y solo se ven en `/mis-notas`. | Una spec aparte para un cargador. |
| B17 | Sondeos de solo lectura | Autorizados para V1 a V4 del backend. | Implementar sin sondear. |
| B18 | Mostrar el «Promedio» de la ULima | No se muestra. | Mostrarlo en la tarjeta de `/mis-notas` cuando valga más que 0, con su campo en el contrato. |
| B19 | Cambio de ciclo durante la recarga | El backend lee el ciclo de la ULima tras iniciar sesión y, si difiere del período activo, responde `409 IMPORT_REQUIRED` sin escribir nada y sin devolver el cupo. La app muestra el aviso de `IMPORT_REQUIRED` con «Cargar mis datos» (RF-RCG-4). Si el ciclo nuevo todavía no empieza, la importación no lo activa y la recarga sigue en ese `409` hasta la fecha de inicio, así que en ese lapso «Cargar mis datos» no lo resuelve. | Un código propio para ese caso, con su propio aviso en la app, que no lleve a `/portal-sync` a un alumno cuyo ciclo todavía no empieza. |

Texto aprobado para B12, que el PR de implementación escribe en `AGENTS.md` y `KNOWLEDGE.md`.
El dueño pide un solo texto para los dos repositorios, así que es el mismo de la decisión 12 de
la spec del backend y reemplaza a los dos textos que cada borrador propone por separado. «Las notas
que el alumno registra en la calculadora son personales y no oficiales
(`simulated_grades`). La calculadora muestra además, fijas y con la marca “ULima”, las
notas parciales que publica la ULima, que guarda la tabla `student_portal_score`, escribe
solo `POST /portal-sync/refresh` y lee `GET /grades/me/ulima`.»

En `README.md:102`, la frase «Nunca se mezclan» pasa a describir esa convivencia. En esa misma
línea, la fuente de `/mis-notas` pasa a `GET /grades/me/ulima` por la opción aprobada de B10, y
la entrada a `/mis-notas` cambia porque depende de RF-RCG-5 y no de B12.

### Puntos que fija esta spec (D1 a D24)

La spec fija cada punto con un valor por defecto, y el dueño los aprueba todos en ese valor el
2026-09-26. Cuatro de ellos, D8, D11, D13 y D14, cambian lo que dibuja la maqueta aprobada, y su
fila lo dice con «Cambia la maqueta aprobada», así que el dueño aprueba con ellos esos cuatro
retoques a la maqueta, cuya alternativa es la maqueta tal cual. D7 y D15, además, suman cambios
a la `CursoCard` más allá de los tres aprobados, como anota «Qué no cambia de la calculadora». D12
y D24 dejan los dos colores que no llegan a 4,5:1 como en el resto de la app, y D18 recoge el
máximo de 65 000 del presupuesto del backend (decisión 6 del dueño).

| # | Punto | Valor aprobado | Alternativa | Dónde |
| --- | --- | --- | --- | --- |
| D1 | Lugar del botón y de la hora en el bloque de asistencia | Una fila nueva bajo las horas y el anillo, con la hora a la izquierda y «Actualizar» a la derecha | El botón bajo el anillo y la hora bajo el título «Asistencia», que suma menos alto pero se corta con el texto grande | RF-RCG-8 |
| D2 | Asistencia sin hora de lectura | No se pinta la línea | `Última lectura sin registrar` | RF-RCG-8 |
| D3 | Botón del estado sin datos | Dice `Actualizar desde la ULima`, abre la hoja y el bloque muestra el aviso compacto y la línea de lectura parcial encima del botón | Dejarlo como hoy, hacia `/portal-sync` | RF-RCG-8 |
| D4 | Espera y cierre de la hoja | Texto de espera, campos de solo lectura, sin cierre por toque fuera ni por arrastre en ningún estado | Cerrar la hoja al enviar y mostrar la espera en la franja | RF-RCG-2 |
| D5 | Mensajes y acciones por error | La tabla de RF-RCG-4 | Mostrar el `message` del backend | RF-RCG-4 |
| D6 | Lectura parcial | La línea `No se pudo leer en esta actualización.` por curso, en memoria, sin mostrar `warnings` | Un aviso único con el número de cursos sin lectura, o nada | RF-RCG-3 |
| D7 | Orden de las filas en la calculadora | El del sílabo, con las ajenas al final, como dibuja la maqueta. Reordena las simuladas, que hoy salen en el orden en que se registraron, y es un cambio a la `CursoCard` más allá de los tres aprobados | Primero las de la ULima y después las simuladas en su orden de hoy | RF-RCG-7 |
| D8 | Título de una fila de la ULima en la calculadora | El `name` de la ULima, que trae el ordinal («Examen escrito 1»). Cambia la maqueta aprobada, que titula la fila con el nombre del sílabo | El nombre del sílabo, sin ordinal, como la maqueta | RF-RCG-7 |
| D9 | Prefijo de la fila en `/mis-notas` | La sigla del sílabo cuando hay pareja, tomada de `GET /grades/me/courses`, y solo el nombre sin pareja | Solo el nombre de la ULima, o un campo nuevo del backend (hueco 1) | RF-RCG-6 |
| D10 | Formato de peso y nota | Peso entero sin decimales y con hasta dos si los tiene (`12.5%`), en las dos pantallas. En `/mis-notas`, nota con un decimal si tiene uno o ninguno (`15.0`) y con dos si los tiene (`14.25`). En la calculadora, todas las filas, simuladas y de la ULima, siguen con un decimal (`toStringAsFixed(1)`), como hoy y como la maqueta, así que una tarjeta nunca mezcla `14.25` y `14.3`. Punto decimal, como el resto de la app | Dos decimales cuando los hay también en la calculadora, en las dos clases de filas, que cambia la fila aprobada de una simulada con dos decimales. O redondear todo a un decimal, como hoy | RF-RCG-6 y RF-RCG-7 |
| D11 | Naranjas de texto | `#A34300` en claro y `#FF8C42` en la marca en oscuro, `#FF6600` en la acción y los dos botones del bloque de asistencia en oscuro, porque `primaryDark` da 3,73:1 en la marca y 4,12:1 en la acción, y el `primary` de hoy del botón del estado sin datos da 2,49:1 en claro. Cambia la maqueta aprobada en la marca y en «Reintentar» | Los colores de la maqueta (`primaryDark`), por debajo de 4,5:1, y el botón del estado sin datos en `primary` | RF-RCG-4, RF-RCG-7, RF-RCG-8 y RF-RCG-10 |
| D12 | Color del botón «Actualizar» de la hoja | Blanco sobre `#FF6600`, como «Registrar» y la maqueta, con 2,94:1 | Blanco sobre `#B84500` (5,40:1), distinto del resto de los botones de la app | RF-RCG-2 y RF-RCG-10 |
| D13 | Borde del campo y de las casillas | `onSurface` al 50 % (3,31:1), con el parámetro `idleBorderColor` de `PasswordResetOtpField`, que las demás pantallas no usan. Cambia la maqueta aprobada, que dibuja el borde en `outline` al 50 % | El `outline` al 50 % de la maqueta y del modal «Registrar Nota» (1,16:1) | RF-RCG-2 y RF-RCG-10 |
| D14 | Textos tenues | La ayuda bajo las casillas en `onSurface` al 70 % (6,38:1), y la línea de la última lectura del aviso en `textSecondary` (6,44:1 en oscuro). Cambia la maqueta aprobada | Los valores de la maqueta, `onSurface` al 50 % (3,31:1) y `textMuted` (3,86:1 en oscuro) | RF-RCG-2 y RF-RCG-4 |
| D15 | Aviso de sílabo que no coincide | La línea al final de la tarjeta del curso, que es un cambio a la `CursoCard` más allá de los tres aprobados | Sin aviso, o un aviso en la fila «Notas oficiales» | RF-RCG-7 |
| D16 | Refresco de la calculadora tras importar | `recargarTodo()` en vez de `Get.delete` | Dejar el borrado y cerrar `/mis-notas` antes de abrir `/portal-sync` | RF-RCG-11 |
| D17 | Vida del aviso rojo | En memoria, hasta el siguiente envío, «Cargar mis datos», el cierre de sesión o el cierre de la app | Guardarlo para mostrarlo al volver a abrir la app | RF-RCG-4 |
| D18 | Plazo de la app | 90 s, como la importación, con la cota del presupuesto de RS-BE-50, que reserva 3 s para la red. Su peor caso es de 82 s con los valores por defecto y de 87 s con el máximo de 65 000, contados desde que el backend recibe la petición (hueco 5) | El máximo de 68 000 sin margen para la red, o subir el plazo de la app a unos 100 s, más que el de la importación | RF-RCG-1 y RF-RCG-3 |
| D19 | Aviso de éxito | Ninguno, la hora nueva ya lo dice | Un `SnackBar` con `Notas y asistencia actualizadas.` | RF-RCG-3 |
| D20 | Carpeta de pruebas | `test/HU37_jeff/`, la misma historia del backend | Otra carpeta | «Pruebas previstas» |
| D21 | Dónde vive el código | `RecargaUlimaService` como `GetxService` permanente, piezas en `lib/components/recarga_ulima/` y funciones puras en `lib/domain/recarga_ulima/` | Sumar la recarga a `PortalSyncService`, que no es un servicio compartido | RF-RCG-1 |
| D22 | Formato de la hora | `hoy`, `ayer` o `el 22 de septiembre`, y `a las HH:mm` | `hace N minutos`, que cambia sin que la pantalla se redibuje | RF-RCG-9 |
| D23 | Recarga que el backend guarda después del plazo o de un fallo de red | `recargar()` vuelve a pedir `GET /grades/me/ulima` antes de volver y, si la `lastReadAt` avanzó respecto de la de antes del envío, la trata como un `200` sin estados por curso. Mientras siga el aviso del plazo o de la red, cualquier carga posterior que muestre esa hora más nueva lo borra. Sin vista cargada, `recargar()` la pide antes del envío, y si no llega, ninguna lectura cuenta como avance | Volver a pedir la vista y dejar siempre el aviso | RF-RCG-1, RF-RCG-3 y RF-RCG-4 |
| D24 | Contraste de `Nota: …/20` en las filas de la ULima | Se hereda de `NotaTile`, en `primary` sobre `tertiaryContainer` (2,44:1 en claro), igual que las simuladas aprobadas | `textoNaranja` en las dos clases de filas (5,19:1 en claro), que cambia la calculadora aprobada | RF-RCG-7 y RF-RCG-10 |

## Pruebas previstas

Todas están en `test/HU37_jeff/` (D20), con datos inventados y el alumno `20230001`, y cada una
se enlaza con `[@test]` junto a su requisito. Comparten los dobles de `recarga_dobles.dart`.

- `recarga_ulima_models_test.dart` (unitaria, RF-RCG-1). La vista del ejemplo del contrato se lee
  entera, con `courses` en `vista.cursos` y `assessments` en `evaluaciones`. Un número en texto se
  convierte. Un `mark` o un `match` desconocidos se tratan como `pending` y `none`. Una fecha
  ilegible queda `null`. El resultado de la recarga trae sus estados por curso y su `view`.
- `recarga_ulima_service_test.dart` (unitaria con `ApiClient` simulado, RF-RCG-1, RF-RCG-3 y
  RF-RCG-4). El cuerpo tiene exactamente `credentials` y `consent: true`, sin `cookies` ni código
  de alumno. Cada fila de la tabla de RF-RCG-4 da su título, su cuerpo y su acción, con `1 minuto`
  y `N minutos`. Un `409 IMPORT_REQUIRED` con el mensaje del cambio de ciclo da el mismo aviso
  que el de la condición previa (B19). El plazo de 90 s y un fallo de red dan su aviso. Un `200`
  aplica `view`, guarda los estados y llama una sola vez a `HorarioController.reload()`, con un
  doble espía registrado, cuyo `Future` queda en `recargaHorario`. Un error no toca la vista ni llama a `reload()`. Una
  segunda llamada durante `enviando` no sale. `clear()` vacía todo. Con el servicio registrado,
  `AuthService.logout()` llama a `clear()`, y sin él no falla. Con un registrador espía, ningún
  mensaje contiene la contraseña ni el código. Casos del dueño de los datos (RF-RCG-1), cada uno
  con el alumno `20230001` y otro alumno inventado, `20230002`, sin `logout()` de por medio, como
  tras un JWT vencido. La vista, el aviso, `errorCarga` y los estados del primero no se ven con el
  segundo como usuario actual. Un `cargar()` del segundo llama a `clear()` antes de su primer
  `await`, y si falla no deja ver la vista del primero. Una respuesta de `cargar()` y una de
  `recargar()` que llegan después de `clear()` se descartan y no vuelven a llenar la vista ni el
  aviso. Casos de D23. Tras el plazo y tras un fallo de red, `recargar()` pide
  `GET /grades/me/ulima`. Si la `lastReadAt` avanzó, vuelve como éxito sin estados y sin aviso, y
  si no avanzó, vuelve con su aviso. Con el aviso del plazo presente, un `cargar()` posterior con
  la hora más nueva lo borra y llama a `reload()`, y uno con la misma hora lo deja. Sin vista
  cargada, `recargar()` la pide antes del `POST` y compara con ella, y si tampoco así llega, ni la
  lectura que sigue al plazo ni un `cargar()` posterior cuentan como avance.
- `ultima_lectura_test.dart` (unitaria, RF-RCG-9). Hoy, ayer, otro día, otro año, las 23:59 y las
  00:00 de Lima con el teléfono en otra zona, y un `leidoEn` posterior a `ahora`. Los doce meses
  salen en minúscula.
- `formato_nota_test.dart` (unitaria, D10). El peso `20` da `20%`, `12.5` da `12.5%` y `12.25` da
  `12.25%`. En `/mis-notas`, la nota `15` da `15.0`, `14.5` da `14.5` y `14.25` da `14.25`. En la
  calculadora, `14.25` da `14.3` en las dos clases de filas.
- `filas_calculadora_test.dart` (unitaria, RF-RCG-7). Una simulada y una de la ULima con el mismo
  `assessmentId` dan solo la de la ULima. `pending` y `match: none` no entran. `np` entra con valor
  0. El orden sigue al sílabo. Las filas que se guardan son solo las simuladas, también las
  ocultas. La fila visible de una simulada se traduce a su índice en `curso['notas']` por
  `evaluacionId`, también con una fila de la ULima antes y con una simulada oculta.
- `hoja_recarga_test.dart` (de widget, RF-RCG-2 y RF-RCG-3). Los textos exactos, `Entras como
  20230001` con el código en negrita, «Actualizar» apagado sin contraseña, con cinco dígitos y con
  una contraseña de espacios, y encendido con seis. Las seis casillas miden 50 de alto, no tienen
  relleno y llevan el borde en reposo de D13. La espera muestra su texto, deja las casillas de
  solo lectura, apaga la X y «Cancelar» y no deja cerrar con atrás. Cerrar con la X, con
  «Cancelar» y con atrás vacía los dos campos, y al reabrir la hoja llegan vacíos. El éxito y el
  error cierran la hoja y vacían los dos campos. Un `401` deja a la vista el login que pone
  `ApiClient`, sin la hoja ni aviso. Las etiquetas de `Semantics`. En claro y en oscuro.
- `mis_notas_ulima_test.dart` (de widget, RF-RCG-4 y RF-RCG-6). Cada fila de la tabla de estados.
  La franja con y sin lectura, y la etiqueta de su `Semantics`. Una fila `graded`, una `pending`
  con `Sin nota`, una `np` con `NP` y una sin semana. La sigla solo con pareja, y ninguna sigla si
  el sílabo no carga. La insignia «Final» con 10.5. Una tarjeta con `lastReadAt` en `null` que
  además falló en el último resultado lleva solo `No se pudo leer en esta actualización.`. El
  aviso de rechazo con la línea de la última lectura y «Reintentar», el de `IMPORT_REQUIRED` con
  «Cargar mis datos» y el de `403` con «Reintentar». El aviso lleva `liveRegion`. «Reintentar»
  abre la hoja vacía. «Cargar mis datos» borra el aviso, abre `/portal-sync` y llama a `cargar()`
  solo si vuelve `true`, no con `false` ni con `null`. La línea de lectura parcial. La flecha del
  AppBar llama solo a `GET /grades/me/ulima`.
- `calculadora_ulima_test.dart` (de widget, RF-RCG-5 y RF-RCG-7). La fila «Notas oficiales» con
  sus tres segundas líneas, su `Semantics` y su navegación a `/mis-notas`, en los tres estados de
  la calculadora. Con una vista previa y `errorCarga` en verdadero, la fila conserva la hora. El
  birrete ya no está. Una fila de la ULima con la marca `ULima` y sin tacho. El promedio y la suma
  de pesos cuentan las dos clases de filas. Con promedio 10.9 se ve «Desaprobado» y con 11 no,
  como hoy. Un curso solo con notas de la ULima aparece y cuenta en «Cursos con notas».
  `POST /grades/me/notes` nunca lleva una nota de la ULima. El tacho de una simulada que sigue a
  una fila de la ULima llama a `eliminarNota` con el índice de esa simulada en `curso['notas']`.
  «Registrar Nota» no ofrece una evaluación ya publicada. La línea del sílabo que no coincide.
- `asistencia_recarga_test.dart` (de widget, RF-RCG-8). La fila con hora y botón, sin línea con
  `asistenciaLeidaEn` en `null`. El botón del estado sin datos abre la hoja. Un `200` llama a
  `recargarSeccion`, que pide `GET /course-detail/sections/:id` sin volver a llamar a
  `reload()`, no recarga las pestañas y conserva la elegida. Si esa petición falla, espera
  `recargaHorario` y lee `uniqueEnrolledCourses`. El aviso compacto y la línea de lectura parcial,
  en el estado con datos y en el estado sin datos, donde van entre la línea explicativa y el botón
  y el aviso cambia la acción del botón. El estado por curso se encuentra con un `sectionId`
  entero y un `idSeccion` de texto. Sin `RecargaUlimaService` registrado, el bloque queda como
  hoy. `Seccion.fromJson` lee `asistenciaLeidaEn` y tolera que falte.
- `portal_sync_refresco_calculadora_test.dart` (unitaria, RF-RCG-11). Tras una importación
  exitosa, `CalculadoraController` sigue registrado y su `recargarTodo()` corre.
- `contraste_recarga_test.dart` (unitaria, RF-RCG-10). Cada fila de la tabla de contraste, salvo
  las de D12 y D24, cumple su mínimo con los valores de `themes.dart`.
- Siguen pasando sin cambios `test/HU07_sam/**`, `test/HU06_sam/**`, `test/HU02_jeff/**`,
  `test/HU20_jeff/otp_field_ime_test.dart`, `test/HU33_jeff/registro_page_test.dart`,
  `test/HU34_jeff/portal_sync_consent_test.dart`, `test/HU34_jeff/registro_consent_test.dart`,
  `test/HU34_jeff/record_page_test.dart`, `test/HU23_jeff/chats_pestana_test.dart`,
  `test/HU23_jeff/chat_ficha_curso_test.dart`, `test/HU35_jeff/time_blocks_acciones_test.dart` y
  `test/HU_asistencia/**`.

## Verificación

- `flutter analyze` sin avisos nuevos y `flutter test` en verde, con los avisos previos reportados
  aparte.
- `TZ=UTC flutter test --no-pub test/HU37_jeff/ultima_lectura_test.dart`. La suite corre solo en
  una máquina local, porque `.github/workflows/build-apk.yml` no corre `flutter test`, y en UTC−5
  la hora local coincide con la de Lima. Con `TZ=UTC`, las pruebas de RF-RCG-9 detectan una hora
  o un día calculados con `toLocal()`, y el caso de las 23:59 y las 00:00 cubre el teléfono en
  otra zona.
- Revisión manual en un iPhone SE, en claro y en oscuro, con el texto al 200 % y con VoiceOver, de
  la fila, la franja, la hoja con el teclado abierto, el aviso y el bloque de asistencia, y la
  misma revisión en Android con TalkBack.
- La app se publica solo con el backend de RS-BE-48 a RS-BE-60 desplegado, incluido RS-BE-48,
  sin el cual ningún botón funciona (decisión B1), con `PORTAL_REFRESH_BUDGET_MS` dentro de la
  cota de RS-BE-50, con su máximo de 65 000, que lo hace compatible con el plazo de D18 (hueco
  5), y con la medición de B15 hecha, con tres recargas de 45 s o menos y sin `504`. La migración `0015`
  tiene aprobado su diseño de BD desde el 2026-09-26, y se aplica en producción solo con un
  respaldo y el permiso del dueño en el momento del despliegue.
