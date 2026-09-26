---
name: Test de especialidad
description: Test de especialidad que conduce Ulises como paso central del asistente del alumno nuevo, con duelos, escalas, desempates, el resultado con su motivo, la elección de la principal y de los intereses, el último resultado en el Perfil, modo oscuro, contraste WCAG, accesibilidad y el caso del id de especialidad antiguo
targets:
  - ../../../lib/pages/specialty_test/**
  - ../../../lib/services/specialty_test_service.dart
  - ../../../lib/models/specialty_test_models.dart
  - ../../../lib/pages/setup_carrera/setup_carrera_page.dart
  - ../../../lib/pages/setup_carrera/setup_carrera_controller.dart
  - ../../../lib/pages/setup_carrera/setup_carrera_binding.dart
  - ../../../lib/pages/perfil/perfil.dart
  - ../../../lib/services/auth_service.dart
  - ../../../lib/configs/themes.dart
  - ../../../lib/main.dart
  - ../../../test/HU36_jeff/**
---

# Test de especialidad

> Estado: **APROBADA** por el dueño del proyecto el 2026-09-25 en la página de revisión, junto
> con la spec del backend. Recoge las decisiones 1 a 7 del dueño de ese día y los dos cambios
> con los que aprueba esta spec, que son los íconos de Lucide en lugar de las ilustraciones
> (decisión 8) y el texto blanco en la cabecera del asistente (decisión 9), las dos en
> «Decisiones del dueño». Todas las demás decisiones abiertas quedan aprobadas en la opción
> que la spec adopta por defecto, y los hallazgos del contrato frente a la maqueta quedan en
> esa lista con su resolución. La aprobación incluye el cambio de base de datos del backend, la tabla
> `student_specialty_test_result` de la migración `0014`. Aplicar la `0014` en producción pide
> además, en el momento del despliegue, el respaldo y el permiso explícito del dueño, como con
> la `0012` y la `0013`. Implementada en la rama `feat/test-especialidad-fe` según
> `docs/superpowers/plans/2026-09-25-specialty-test-app.md`. El merge espera cuatro pasos a cargo
> del dueño, en el orden que ese plan fija en «Lo que queda fuera del plan». Primero va el
> backend desplegado con sus tres rutas y la `0014`, y después, como pide «Verificación», el
> recorrido contra ese backend con una cuenta de prueba y la revisión manual en un iPhone SE. Por
> último, el dueño lee «Ver tu respuesta anterior» y «1 electivo», los dos textos que el plan suma
> a «Textos nuevos».
> La contraparte de backend es
> `ULima_Backend_IS2/specs/features/specialty-test/specialty-test.spec.md` (RS-BE-37 a RS-BE-47,
> rama `feat/test-especialidad`), aprobada el mismo día con las mismas decisiones 8 y 9. Las dos
> specs describen la versión `2026-09-25.4` del contenido. Esta spec consume sus tres rutas
> nuevas y `PUT /academic-profile/me/specialties` con la enmienda BR-AP-07 y BR-AP-08 de esa
> rama, que el dueño aprueba con ella.
> Enmienda la spec de frontend `specs/features/academic-profile/academic-profile.spec.md` en el
> asistente y en el Perfil (ver «Cambios en otras specs»), enmienda que el dueño aprueba con
> esta spec.
> Todos los `[@test]` apuntan a pruebas que ya existen en `test/HU36_jeff/`, así que ninguno
> lleva la marca *(pendiente)* (decisión abierta 21).
> Los ejemplos usan datos inventados.
> Enmienda del 2026-09-25 por la bienvenida con Ulises (`specs/features/bienvenida/bienvenida.spec.md`),
> **aprobada por el dueño el 2026-09-26** junto con esa spec e implementada el 2026-09-26. Suma el
> origen `bienvenida`, con el que el alumno que crea su cuenta en la conversación y el alumno con
> cuenta que todavía no elige su especialidad hacen el test con Ulises, sin la ruta
> `/test-especialidad` y sin el asistente de carrera. El detalle está en «Enmienda de la
> bienvenida con Ulises», al final. Sus pruebas están en `test/bienvenida/`, y desde esa fecha
> el código sigue la enmienda.

## El problema

El asistente del alumno nuevo (`/setup-carrera`) tiene tres pasos, que son la carrera, una
decisión con tres opciones y una lista de especialidades con «Principal» y «Me interesa». Nada
ayuda a decidir, y la lista sale del catálogo de `GET /academic-profile/specialties`, que hoy
trae también las especialidades antiguas (la app las filtra en el cliente con
`is_active == true`, `setup_carrera_controller.dart:26-28`). Las capturas del asistente actual
(`capturas/01` a `capturas/08`, en claro y en oscuro) muestran además tres huecos.

- **Sin modo oscuro.** Cada par de capturas `_claro` y `_oscuro` es idéntico byte a byte, porque
  `setup_carrera_page.dart` pinta con 40 `Color(0x…)` fijos, empezando por el fondo `#F7F7F8`
  (`:21`).
- **Sin estados de catálogo.** Sin catálogo, el paso de carrera muestra la tarjeta sin nombre
  (captura 07) y la selección queda en blanco (captura 08), sin aviso ni forma de reintentar.
- **Botón cortado.** «Finalizar configuración» no cabe en su botón (capturas 04 y 06), que además
  lleva texto blanco sobre `#FF6600`, con 2,94:1.

El test resuelve lo primero. Ulises, el cuervo del chatbot, conversa con el alumno y le muestra
tareas reales de cada especialidad en 14 preguntas, a veces una o dos más para desempatar. El
backend calcula el resultado con la fórmula del contenido, Cohere redacta el motivo y la app
muestra el resultado, deja elegir la principal y marcar intereses, y guarda en el Perfil el
acceso para rehacerlo.

## User Stories

- Como alumno nuevo, quiero que un test corto me recomiende una especialidad y me diga por qué,
  para elegir con algo más que el nombre del diploma.
- Como alumno nuevo, quiero saltar el test y elegir por mi cuenta si ya sé lo que quiero.
- Como alumno, quiero elegir la recomendada como principal y marcar otras como interés desde el
  mismo resultado.
- Como alumno, quiero rehacer el test desde mi Perfil y ver ahí mi último resultado.
- Como alumno que usa lector de pantalla, texto grande o menos movimiento, quiero hacer el test
  igual que los demás.

## Decisiones del dueño (2026-09-25, vinculantes)

Las decisiones 1 a 7 salen de `decisiones.md`, el registro del dueño. La 8 y la 9 son los dos
cambios con los que el dueño aprueba esta spec y la del backend el mismo día, en la página de
revisión.

| # | Decisión | Requisitos |
| --- | --- | --- |
| 1 | El test es el paso central de `/setup-carrera`, con la opción «Saltar y elegir por mi cuenta», y se puede rehacer desde el Perfil. | RF-TEST-1, RF-TEST-3, RF-TEST-10 |
| 2 | El puntaje es transparente y lo calcula el backend. Cohere solo redacta el motivo y, si falla o tarda, el resultado sale con el motivo de las plantillas. | RF-TEST-7, RF-TEST-8 |
| 3 | El contenido está aprobado y va versionado. El backend publica la `2026-09-25.4`, que es la `2026-09-25.3` más el ícono de cada tarea (decisión 8), sin otro cambio. La `2026-09-25.3` es la `2026-09-25.2` aprobada más los cambios que el dueño aprueba el 2026-09-25 en la página de revisión. Son cuatro por las sumillas oficiales de Sistemas (la pregunta 13 abajo, `tb-ti-si-1` arriba y `tb-si-vj-2` abajo cambian de texto, y `tb-sw-si-1` arriba solo de ilustración), dos por los sílabos de Videojuegos de cactus (la pregunta 2 abajo se ancla en Proyecto de Videojuegos, 650081, y luego en Diseño de Videojuegos, y `tb-sw-vj-1` abajo cambia de texto), el código 550090 de Diseño de Videojuegos en lugar del 550043, que conserva el requisito del diploma (Storytelling) y suma una nota en `meta.diplomaNotes`, y la puesta al día de `meta.sources` y `meta.sourceLimits`. El mismo día el dueño deja la escala de TI (pregunta 4) y `tb-sw-si-2` con su texto actual. La línea `low` de Ulises, la línea `second` sin usar, el Metropolitano de la pregunta 10 y la línea `tie` en un empate con afinidad menor que 50 no forman parte de esta decisión y van en las decisiones abiertas 27 y 28, que el dueño aprueba con la spec. | RF-TEST-2, RF-TEST-4, RF-TEST-8 |
| 4 | Diseño «Conversación con Ulises», con la misma imagen del chatbot (`assets/images/ulises_chatbot.png`), según la maqueta `ulises-v2.html` de cinco pantallas. Las tarjetas del duelo son grises y se encienden en el color de su especialidad al tocarlas. El resultado va sin scroll, en claro y en oscuro, con la número uno, su porcentaje, el motivo, sus electivos, las otras tres con un corazón y los botones «Elegir como principal», «Decidir después» y «Rehacer el test». Modo oscuro obligatorio. | RF-TEST-3 a RF-TEST-9, RF-TEST-12 |
| 5 | Se guarda solo el último resultado por alumno, con el ranking, la fecha y la versión, para mostrarlo en el Perfil. Las respuestas una por una no se guardan. | RF-TEST-2, RF-TEST-10 |
| 6 | Solo se muestran y se eligen los cuatro diplomas oficiales, con el filtro en el backend y sin tocar los datos de especialidades. `getEspecialidadName()` devolvería una cadena vacía para un id antiguo en caché, y esta spec lo cubre. | RF-TEST-14 |
| 7 | La validación del contenido está hecha. | RF-TEST-2 |
| 8 | Íconos en lugar de ilustraciones. En vez de 48 SVG, cada tarea lleva un ícono de Lucide, de la misma familia que ya usa la app (`lucide_icons_flutter` 3.1.15), coloreado con su especialidad. El contenido suma el campo `icon` en cada tarea y pasa a la versión `2026-09-25.4`. El backend lo sirve en `GET /specialty-test/content` y en el paso de desempate, y la app lo pinta con un mapa cerrado de nombres a `LucideIcons`, en el que un nombre desconocido cae a un ícono neutro. Reemplaza la propuesta de la decisión abierta 2. | RF-TEST-2, RF-TEST-5, RF-TEST-6 |
| 9 | La cabecera del asistente lleva texto blanco sobre el naranja, como el resto de la app y como la decisión previa del dueño para los chats, en lugar de la tinta oscura que propone la primera versión de la spec (decisión abierta 14). | RF-TEST-1, RF-TEST-12 |

## Requisitos

### RF-TEST-1 · El asistente con el test como paso central

El asistente pasa de tres pasos a este recorrido.

1. **Carrera.** Igual que hoy, con la carrera fija y «Continuar». Si el catálogo de carreras no
   carga, la tarjeta muestra «No pudimos cargar tu carrera.» y «Reintentar», que llama a
   `AuthService.reloadCatalogs()` (RF-TEST-14). «Continuar» sigue activo, porque la carrera sale
   del usuario (`careerId`) y el catálogo solo pone su nombre. El atrás del sistema sigue como
   hoy, sin `PopScope`. El asistente es la única ruta de la pila, porque se llega a él por
   `initialRoute` o por `Get.offAllNamed` (`main.dart:88` y `login_controller.dart:46`), así
   que Android sale de la app, y al abrirla el alumno vuelve al asistente porque
   `setupComplete` sigue en `false`.
2. **Test.** «Continuar» abre la ruta nueva `/test-especialidad` con el argumento
   `origen: asistente`, sobre el asistente, que queda debajo en la pila. La ruta muestra la
   bienvenida (RF-TEST-3), las preguntas (RF-TEST-4 a RF-TEST-7) y el resultado (RF-TEST-8 y
   RF-TEST-9).
   - «Saltar y elegir por mi cuenta» cierra la ruta y el asistente pasa a la selección manual.
   - Un `404 SPECIALTY_TEST_NOT_AVAILABLE` al pedir el contenido hace lo mismo, sin aviso, porque
     el test no existe para esa carrera (RS-BE-38).
   - «Elegir como principal» y «Decidir después» guardan con `PUT` y terminan el asistente con
     `Get.offAllNamed('/home')` (RF-TEST-9).
   - El atrás del sistema en la bienvenida, o el botón de pausa (RF-TEST-4), cierra la ruta y
     deja al alumno en el paso de carrera. Con «Continuar» vuelve a la bienvenida.
3. **Selección manual.** Es el paso «Selección» de hoy (`_SeleccionStep`,
   `setup_carrera_page.dart:365-435`), con las mismas reglas de principal e interés y los
   botones «Saltar por ahora» y «Finalizar configuración». Muestra solo las especialidades
   oficiales (RF-TEST-14). Si el catálogo de especialidades llega vacío por un fallo, muestra
   «No pudimos cargar las especialidades.» y «Reintentar» en lugar de la lista en blanco. El
   atrás del sistema vuelve al paso de carrera, con un `PopScope` que hoy la página no tiene.

Sale el paso «Decisión» (`_DecisionStep` y `_DecisionCard`, `setup_carrera_page.dart:219-363`)
con sus tres opciones, y con él `SpecialtyDecision`, `decision`, `chooseSi`, `chooseNoSe` y
`chooseExplorar` (`setup_carrera_controller.dart:7`, `:11` y `:47-59`). «Todavía no estoy
seguro» queda cubierto por «Decidir después» y por «Saltar por ahora», y «Quiero explorar
primero» por el propio test. `SetupStep` queda con `carrera` y `seleccion`.

- **Destino tras el login.** `postLoginRoute` (`post_login_route.dart:11-14`) no cambia. Un
  alumno con `setupComplete == false` sigue entrando a `/setup-carrera`, y un docente nunca ve
  el asistente ni el test.
- **Bindings.** `/setup-carrera` pasa a tener binding por ruta (`SetupCarreraBinding`), en lugar
  del `Get.put` dentro de `build` (`setup_carrera_page.dart:17`), como pide la regla del repo que
  recuerda `main.dart`. `/test-especialidad` tiene el suyo (`SpecialtyTestBinding`), con
  `lazyPut` sin `fenix`, para que el controlador muera al cerrar la ruta.
- **Precarga.** Al montarse, el controlador del asistente pide el contenido del test en segundo
  plano, una sola vez, para que la bienvenida no espere. Un fallo de esa precarga no se muestra
  en el paso de carrera. La precarga es el pedido del contenido de la primera apertura del test
  (RF-TEST-2), así que esa bienvenida usa su copia si ya está, la espera con el estado
  «Cargando» si sigue en vuelo y pide el contenido otra vez si la precarga termina en error.
- **Modo oscuro.** Los pasos de carrera y de selección manual dejan sus 40 `Color(0x…)` fijos y
  pasan a los tokens de `MaterialTheme` (RF-TEST-12), como en el chat (RF-CHAT-8). Los textos de
  esos pasos no cambian.
- **Botón inferior.** `_BottomButton` (`setup_carrera_page.dart:766`) pasa al estilo del botón
  principal del test, a lo ancho, con 52 px de alto y texto en tinta sobre naranja (RF-TEST-12),
  así que «Finalizar configuración» cabe entero.
- **Cabecera.** `_WizardHeader` (`setup_carrera_page.dart:47`) sigue en los pasos de carrera y
  de selección manual y no aparece dentro de la ruta del test. Toma `headerColor`
  (`themes.dart:21-26`) en lugar del `MaterialTheme.primaryColor` fijo de hoy, y su texto y su
  ícono siguen en blanco en los dos temas, como el header de la app y el AppBar del chat
  (decisión 9). En oscuro, el blanco sobre `#1E1E24` da 16,58:1. En claro, el blanco sobre
  `#FF6600` da 2,94:1 y no llega al 4,5:1 de RF-TEST-12. Es el mismo contraste de la cabecera
  de toda la app, un riesgo conocido que el dueño acepta el 2026-09-25 y que se corrige en toda
  la app en un cambio aparte. Su saludo «Hola, <nombre>» no cambia.
- **Orientación.** Vertical, como toda ruta fuera de Horario (BR-SHELL-F-00 de app-shell).

`[@test] ../../../test/HU36_jeff/setup_carrera_flujo_test.dart`

### RF-TEST-2 · Capa de datos del test

- **Service.** `SpecialtyTestService`, un `GetxService` permanente que `main.dart` registra junto
  a `TimeBlocksService` (`main.dart:81`), es el único que llama a `/specialty-test/**`. Ningún
  widget ni controlador lee JSON ni llama a `ApiClient`.
- **Operaciones.** `fetchContent()` pide `GET /specialty-test/content`, `evaluate()` manda
  `POST /specialty-test/me/evaluate`, `loadLastResult()` pide `GET /specialty-test/me/result` y
  `clear()` vacía todo.
- **Plazos.** `ApiClient` no impone plazo (`api_client.dart:140`), así que el service pone el
  suyo, como `TimeBlocksService` y `AcademicRecordService`. Son 15 s para el contenido y para el
  último resultado, y 20 s para la evaluación, que incluye hasta 5 s de Cohere y el arranque en
  frío del servidor (decisión abierta 17). Los guardados que lanza el test (RF-TEST-9) van por
  `AuthService.completeSetup`, que suma un parámetro opcional `timeout`. El test lo usa con
  15 s, y la hoja «Editar» del Perfil y la selección manual siguen sin él. Al vencer,
  `completeSetup` lanza `TimeoutException` antes de tocar el usuario y las preferencias, así
  que una respuesta tardía no cambia nada en la app (decisión abierta 24).
- **Guarda por dueño.** El estado queda atado al código del alumno, igual que en
  `TimeBlocksService`. Una respuesta que llega para otro alumno, o después de un `clear()`, se
  descarta. `AuthService.logout()` llama a `clear()` con la misma guarda `Get.isRegistered` que
  usa con el récord y los bloques (`auth_service.dart:398-402`).
- **Contenido.** Cada apertura de `/test-especialidad` pide el contenido una vez, en la
  bienvenida, para no arrancar con una versión vieja. La excepción es la primera apertura desde
  el asistente, cuyo pedido es la precarga del paso de carrera (RF-TEST-1). Las aperturas
  siguientes, como la de después de una pausa o la que sale del Perfil, lo piden de nuevo.
  «Rehacer el test» no abre la ruta otra vez y sigue con la misma copia (RF-TEST-9). La copia
  vigente queda en memoria durante la sesión, porque la tarjeta del Perfil usa sus colores y sus
  íconos (RF-TEST-10), y un test en pausa guarda además la copia con la que arranca
  (RF-TEST-4). Nunca se guarda en disco.
- **Respuestas.** Viven solo en la memoria del service mientras el test está en curso o en
  pausa (RF-TEST-4). No se guardan en disco ni viajan a otro lado que no sea el cuerpo de la
  evaluación (decisión 5). Se borran al terminar, al «Empezar de nuevo», al saltar el test y al
  cerrar sesión.
- **Cuerpo de la evaluación.** Es exactamente `{ "version", "answers", "tiebreakAnswers" }`, con
  la versión del contenido con la que el alumno responde, las respuestas por id de pregunta y los
  desempates en orden (RS-BE-39). Nunca lleva datos del alumno.
- **Modelos.** `specialty_test_models.dart` tiene el contenido (versión, especialidades con
  electivos, líneas de Ulises, opciones y preguntas), el paso de la evaluación (desempate o
  resultado) y el último resultado. Sus `fromJson` conservan los `null`, como
  `tiebreakOutcome`, y no inventan ceros ni textos.
- **Contenido utilizable.** Antes de usar el contenido, el modelo comprueba lo que la app
  necesita para no pintar un test roto. Cada pregunta es `duel`, con `top` y `bottom`, o
  `scale`, con `task`; cada tarea trae id, texto y una clave que está entre las especialidades;
  y cada especialidad trae `specialtyId`, nombre y sus dos colores. Además, `scaleOptions` trae
  exactamente cuatro opciones, porque RF-TEST-6 ata un emoji a cada una por su orden, y
  `duelOptions` trae `both` y `none`, cuyas etiquetas usa RF-TEST-5. Un color presente con un
  hex que no se puede leer no invalida el contenido y cuenta como neutro (RF-TEST-12). Del mismo
  modo, un `icon` ausente o fuera del mapa de íconos, en una tarea o en una especialidad, no
  invalida el contenido y cuenta como el ícono neutro (RF-TEST-5). Si algo falla, la
  bienvenida muestra el mismo estado que sin conexión (RF-TEST-11) y el registro dice solo que
  el contenido no es válido, sin datos. La app no fija el número de preguntas ni la versión,
  así que le da lo mismo la `2026-09-25.4` que publica el backend (RS-BE-37) o una versión
  posterior.
- **Errores.** El service traduce cada fallo a un tipo propio con estos casos.
  - `notAvailable`, por `404 SPECIALTY_TEST_NOT_AVAILABLE`, al pedir el contenido o al evaluar
    (paso 6 de RS-BE-39).
  - `versionOutdated`, por `409 SPECIALTY_TEST_VERSION_OUTDATED`, con `details.currentVersion`.
  - `invalidAnswers`, por `400 SPECIALTY_TEST_INVALID_ANSWERS`.
  - `tiebreakMismatch`, por `400 SPECIALTY_TEST_TIEBREAK_MISMATCH`, con `details.expected`.
  - `rateLimited`, por `429 RATE_LIMITED`, con el mensaje del servidor y
    `details.retryAfterMinutes`.
  - `offline`, por un plazo vencido o un fallo de red sin respuesta (`TimeoutException` y
    `http.ClientException`, que en Android e iOS envuelve a `SocketException`).
  - `server`, por cualquier otro `ApiException`, con su mensaje.
- **Último resultado.** `loadLastResult()` deja uno de cinco estados, que son cargando, sin
  test, con resultado, error y no disponible. Tras una evaluación que termina en resultado,
  aunque la app descarte ese paso por un atrás desde la espera (RF-TEST-4), el service marca el
  último resultado como viejo, y la tarjeta del Perfil lo vuelve a pedir al montarse, porque
  solo `GET /specialty-test/me/result` trae `isCurrentVersion` (RS-BE-45).

`[@test] ../../../test/HU36_jeff/specialty_test_service_test.dart`
`[@test] ../../../test/HU36_jeff/specialty_test_models_test.dart`

### RF-TEST-3 · La bienvenida

Es la pantalla 1 de la maqueta.

- **Héroe.** Ocupa 284 px de alto con la escala de texto en 1,0, con esquinas inferiores de
  36 px y un degradado radial de naranjas (`#FFA35E`, `#FF7A1A`, `#FF6600` y `#E25A00`). Lleva
  arriba a la izquierda la pastilla «Test de especialidad» con el ícono de brújula
  (`LucideIcons.compass`), en tinta `#1A0E05` sobre blanco al 85 %. Al centro va Ulises, a
  136 px, recortado en círculo como en el chatbot (`chatbot_page.dart:716-734`) y con un aro
  blanco de 5 px. Alrededor flotan cuatro orbes blancos de 42 px con el ícono de cada
  especialidad en su color claro, sin nombres. El héroe es igual en los dos temas (decisión
  abierta 13).
- **Ulises.** Debajo del héroe, el rótulo «Ulises» y una burbuja por cada línea de
  `ulises.welcome`, en orden. La primera va sin avatar y las demás con el avatar de 28 px, como
  en la maqueta. La app no agrega el nombre del alumno, porque las líneas del contenido no lo
  traen y el nombre llega como «APELLIDOS NOMBRES» (`user_model.dart:54-66`). El «Hola,
  Valeria» de la maqueta es ilustrativo (decisión abierta 8).
- **Pastillas.** «3 a 4 min», con el ícono de reloj, y «Rehazlo en Perfil», con
  `LucideIcons.rotateCcw`. La segunda sale solo con `origen: asistente`.
- **Botones.** «Empezar el test», principal, con flecha, y «Saltar y elegir por mi cuenta»,
  secundario. Con `origen: perfil`, el secundario es «Ahora no» y cierra la ruta. El
  `startButton` del contenido («Vamos») no se usa, porque la decisión 4 nombra el botón «Empezar
  el test» (decisión abierta 7).
- **Test en pausa.** Si hay respuestas en memoria (RF-TEST-4), el botón principal dice «Seguir
  el test» y vuelve al primer paso sin responder, con la copia del contenido de ese test, y
  aparece un segundo botón secundario, «Empezar de nuevo», que borra las respuestas y abre la
  pregunta 1 con la copia vigente.
- **Cargando.** Mientras llega el contenido, el héroe se ve completo, las burbujas son dos
  bloques de `SkeletonPulse` y el botón principal está desactivado. El secundario sigue activo.
- **Error.** Las burbujas dejan su lugar a «No pudimos cargar el test.» y a «Reintentar». El
  secundario sigue activo, así que un fallo nunca atrapa al alumno en el asistente.
- **No disponible.** Con `origen: asistente`, la ruta se cierra y el asistente pasa a la
  selección manual (RF-TEST-1). Con `origen: perfil`, un aviso muestra el mensaje del servidor
  («El test de especialidad no está disponible para tu carrera.») y la ruta se cierra.
- **Espacio.** Si las líneas de bienvenida no caben, el cuerpo desplaza y los botones quedan
  fijos abajo. Con las cuatro líneas de `welcome` de la versión `2026-09-25.4`, a 375 × 667,
  nada desborda y los botones siguen a la vista.

`[@test] ../../../test/HU36_jeff/specialty_test_bienvenida_test.dart`

### RF-TEST-4 · La conversación con Ulises

Rige para el duelo, la escala, el desempate y la espera.

- **Barra.** Mide 52 px. A la izquierda, «Pregunta anterior» (`LucideIcons.chevronLeft`). Al
  centro, Ulises a 38 px con un punto verde decorativo, el nombre «Ulises» y debajo «Pregunta N
  de T», donde T es el número de preguntas del contenido (14 hoy), o «Desempate 1» y «Desempate
  2». A la derecha, «Pausar el test y seguir luego» (`LucideIcons.pause`).
- **Plumas.** Una por pregunta, bajo la barra. Van llenas en `testFeatherOn` las respondidas,
  la actual llena y con un brillo suave, y el resto en `testFeatherOff`. En los desempates y en
  la espera van todas llenas. Siempre van en naranja y nunca en el color de una especialidad,
  para que no lleven la cuenta a la vista.
- **Burbuja de Ulises.** En pantalla queda solo el último turno de Ulises, con su avatar de
  28 px. La app elige sus líneas con estas reglas y no escribe ninguna propia.
  - Antes de la pregunta 1 va `duelHelp`.
  - Antes de la pregunta N, con N mayor que 1, va la reacción a la respuesta N − 1. Si N − 1 es
    un duelo, es su `reaction`; si el duelo no la trae, es una línea de `reactions.pick`,
    `reactions.both` o `reactions.none` según la respuesta, la de índice (N − 1) módulo el largo
    de la lista. Si N − 1 es una escala, es su `blockClose`; si no lo trae, es una línea de
    `reactions.scale` con la misma regla de índice.
  - Antes de la primera escala del contenido va además una segunda burbuja con `scaleHelp`.
  - Antes de un desempate va la `ulisesLine` que manda el servidor (RF-TEST-7).
  - Ninguna línea nombra especialidades, porque así está escrito el contenido y el servidor.
- **Sello de bloque.** Junto a un `blockClose` cae el sello «Cierra el bloque k de B», donde k
  es el orden de esa pregunta entre las que traen `blockClose` y B es cuántas lo traen (4 hoy).
  El contrato no manda el campo `block` del contenido, y esta cuenta da el mismo número.
- **Historial plegado.** Desde la pregunta 2, arriba del turno de Ulises, una pastilla dice «N
  respuestas anteriores», o «1 respuesta anterior». Al tocarla se despliega, dentro del mismo
  espacio que desplaza, la lista de lo respondido, con el número de la pregunta y la respuesta.
  La respuesta es el texto de la tarea elegida, «Me gustan las dos», «Ninguna me llama» o, en
  una escala, «<etiqueta> · <tarea>». Los desempates van como «Desempate 1» y «Desempate 2».
  La lista va sin colores de especialidad y solo se lee. Otro toque la pliega.
- **Atrás.** «Pregunta anterior» y el atrás del sistema llevan al paso previo. Desde la
  pregunta 1 van a la bienvenida, desde el desempate 1 a la última pregunta, desde el desempate
  2 al desempate 1 y desde la espera al paso que la dispara. La respuesta previa aparece
  marcada. Cambiar la respuesta de cualquier pregunta borra todos los desempates, y cambiar el
  desempate 1 borra el 2, porque el servidor decide cuáles tocan. Responder de nuevo, aunque sea
  lo mismo, vuelve a evaluar.
- **Atrás desde la espera.** La evaluación en vuelo no se cancela, y su paso se descarta al
  llegar. Si ese paso es un resultado, el servidor ya lo tiene guardado (RS-BE-44), así que el
  service marca igual el último resultado como viejo (RF-TEST-2). Si el alumno responde de
  nuevo antes de que llegue, la evaluación nueva sale cuando la anterior termina o vence su
  plazo, y mientras tanto se ve la espera, de modo que nunca hay dos en vuelo (RF-TEST-7).
- **Pausa.** Cierra la ruta y deja en la memoria del service las respuestas y la copia del
  contenido con la que arranca el test (RF-TEST-2). En el asistente, el alumno queda en el paso
  de carrera; en el Perfil, vuelve a su tarjeta, que ofrece seguir (RF-TEST-10). Cerrar la app
  o la sesión pierde el avance (decisión abierta 9). Al seguir, el test usa esa copia aunque la
  versión vigente sea otra, y la evaluación manda su versión, que el servidor acepta mientras
  siga en su registro (RS-BE-37). Si el servidor la retira antes, responde
  `409 SPECIALTY_TEST_VERSION_OUTDATED` y rige su fila de RF-TEST-11 (decisión abierta 25).
- **Transiciones.** La reacción y la pregunta siguiente entran juntas en 180 ms, sin puntos de
  «escribiendo», y el par anterior se encoge dentro de la pastilla del historial.

`[@test] ../../../test/HU36_jeff/specialty_test_conversacion_test.dart`
`[@test] ../../../test/HU36_jeff/specialty_test_logic_test.dart`

### RF-TEST-5 · El duelo

Es la pantalla 2 de la maqueta.

- **Encabezado.** El rótulo «Esto o aquello», en mayúsculas de 11 px y en `testAccentText`, y
  debajo el `prompt` de la pregunta, en 17,5 px y negrita.
- **Tarjetas.** Dos, apiladas, con la tarea `top` arriba y la `bottom` abajo. Cada una mide al
  menos 104 px de alto y lleva a la izquierda una baldosa de 80 px en `testTaskTileBg`, con el
  ícono de la tarea de 40 px al centro, y a la derecha el texto de la tarea en 14 px y negrita.
  Entre las dos va una moneda con «o», decorativa.
- **Neutras hasta el toque.** Antes del toque, las dos tarjetas son iguales, con el fondo
  `cardBg`, el borde `testLine` y el ícono en `testTaskIconInk`. Ni la tarjeta, ni el color del
  ícono, ni Ulises dejan ver de qué especialidad es cada tarea (decisión 4), y ninguna tarea usa
  el ícono de una especialidad, como exige el contenido (RS-BE-37). La guía de ilustración del
  contenido, que pide el estilo neutro hasta el resultado, queda superada por la decisión 4,
  igual que en RS-BE-38.
- **Al tocar.** En 150 ms la tarjeta se enciende con el color de su especialidad, `color.light` o
  `color.dark` según el tema. El borde pasa a 1,5 px en ese color, el fondo a ese color al 12 %
  sobre `cardBg`, aparece un halo de 4 px al 20 % y el ícono toma el color. Arriba a la
  derecha cae una insignia de 28 px en el color, con el visto en el color de la página, y suena
  `HapticFeedback.selectionClick`. La otra tarjeta se apaga, con el ícono al 50 % y el texto en
  `testInk2` y peso 600.
- **Las dos o ninguna.** Debajo van dos botones de 48 px en dos columnas, con las etiquetas de
  `duelOptions` para `both` y `none`. «Me gustan las dos» enciende las dos tarjetas y «Ninguna
  me llama» apaga las dos.
- **Avance.** A los 350 ms del toque, la pregunta avanza sola y la pluma se llena. En esos 350 ms
  otro toque no hace nada. Con un lector de pantalla activo (`MediaQuery.accessibleNavigation`)
  no hay avance solo, y tras elegir aparece el botón «Siguiente» (RF-TEST-13, decisión abierta
  18).
- **Íconos de las tareas.** Desde la `2026-09-25.4`, cada tarea trae en `icon` el nombre de su
  ícono en Lucide, en kebab-case (por ejemplo `shopping-cart`), y las tareas del desempate lo
  traen igual (decisión 8). La app lo traduce con un mapa cerrado de nombres a constantes de
  `LucideIcons` (`lucide_icons_flutter` 3.1.15), en `specialty_test_logic.dart`. El mapa trae
  los 52 nombres de la `2026-09-25.4`, que son los 48 de las tareas y los 4 de las
  especialidades, cada uno con la constante que da su camelCase (`shopping-cart` con
  `LucideIcons.shoppingCart`), y ningún otro. Los íconos de las especialidades de RF-TEST-3,
  RF-TEST-8 y RF-TEST-10 salen del mismo mapa. Un nombre fuera del mapa, o una tarea sin
  `icon`, cae al ícono neutro `LucideIcons.sparkles`, que no es de ninguna especialidad ni de
  ninguna tarea y por eso no delata nada. Una versión nueva del contenido cambia los íconos sin
  otro APK mientras use nombres del mapa, y un nombre nuevo sale neutro hasta el siguiente APK.
  La app no arma un `IconData` con un punto de código que llegue del servidor, porque el build
  de release recorta la fuente de íconos a las constantes que nombra el código. La descripción
  `illustration` del contenido no se muestra.
- **Desempate.** Usa esta misma pantalla, con el rótulo «Desempate» y las dos tareas que manda
  el servidor.

`[@test] ../../../test/HU36_jeff/specialty_test_preguntas_test.dart`
`[@test] ../../../test/HU36_jeff/specialty_test_logic_test.dart`

### RF-TEST-6 · La escala de gusto

Es la pantalla 3 de la maqueta.

- **Tarjeta.** Arriba una franja de 92 px en `testTaskTileBg` con el ícono de la tarea de 40 px
  al centro, traducido con el mapa de RF-TEST-5, y debajo el rótulo «Escala de gusto», el texto
  de la tarea en 15 px y negrita, y el `prompt` de la pregunta en 12,5 px y `testMuted`. La
  escala nunca se enciende con el color de su especialidad, porque no es un duelo y ese color
  la delataría, así que su ícono va siempre en `testTaskIconInk`.
- **Opciones.** Las cuatro de `scaleOptions`, en una fila de cuatro, de 64 px de alto como
  mínimo, con su etiqueta y encima un emoji decorativo, 😴, 🙂, 😃 y 🤩, en ese orden. Con la
  escala de texto por encima de 1,3 o con menos de 340 px de ancho, van en una grilla de dos por
  dos.
- **Al elegir.** La opción crece un 8 % y pasa a naranja, con el fondo `testAccentSoft`, el
  borde `testAccent` y la etiqueta en `testAccentDeep`, y suena
  `HapticFeedback.selectionClick`. El avance sigue la regla de RF-TEST-5.
- **Fin de bloque.** Si la escala trae `blockClose`, al avanzar cae el sello de bloque con
  `HapticFeedback.lightImpact`, junto a la burbuja de Ulises (RF-TEST-4).

`[@test] ../../../test/HU36_jeff/specialty_test_preguntas_test.dart`

### RF-TEST-7 · Evaluación, espera y desempates

- **Cuándo evalúa.** Al responder la última pregunta, la app llama a `evaluate()` con todas las
  respuestas y `tiebreakAnswers` vacío. Tras responder un desempate, vuelve a llamar con las
  mismas respuestas y los desempates en orden. El servidor no guarda nada entre una llamada y
  otra (RS-BE-39), así que un reintento manda el mismo cuerpo.
- **La espera.** Se queda en la conversación, con la barra y las plumas llenas. Si la última
  pregunta trae `blockClose`, va primero esa burbuja con su sello. Después va una burbuja con
  `ulises.loading` («Dame un toque que junto tus respuestas.»), que es el texto de espera, y un
  indicador de progreso pequeño en `testAccent`. Con menos movimiento, el indicador no gira y la
  burbuja sola dice que se espera (RF-TEST-13). La espera cubre también la redacción del motivo
  por Cohere, de hasta 5 s en el servidor.
- **Desempate.** Si llega `status: "tiebreak"`, la app muestra el desempate como un duelo
  (RF-TEST-5), con la `ulisesLine` del servidor en la burbuja y «Desempate 1» o «Desempate 2»,
  según `order`, en la barra.
- **Resultado.** Si llega `status: "result"`, la app abre el resultado (RF-TEST-8), borra las
  respuestas de la memoria y marca el último resultado como viejo (RF-TEST-2).
- **Una sola a la vez.** Durante la espera, las tarjetas, las opciones y los botones no
  responden. Nunca salen dos evaluaciones juntas, y tras un atrás desde la espera la evaluación
  nueva aguarda a que termine la anterior (RF-TEST-4).
- **La app no calcula.** La app no calcula afinidades, no decide si toca un desempate ni ordena
  el ranking. Muestra lo que llega (decisión 2).

`[@test] ../../../test/HU36_jeff/specialty_test_evaluacion_test.dart`

### RF-TEST-8 · El resultado

Son las pantallas 4 y 5 de la maqueta. De arriba abajo, van estas piezas.

1. **Entrada.** Confeti decorativo, una sola vez, y `HapticFeedback.heavyImpact`.
2. **Ulises.** Su avatar de 34 px y una burbuja con `ulises.headline` y, si no es `null`,
   `ulises.tiebreakOutcome`, separados por un espacio. `headline` va siempre y tal cual llega.
   El servidor pone ahí la línea `tie` con empate, aunque la afinidad sea menor que 50, la
   `low` sin empate y con la afinidad de la ganadora por debajo de 50, y la `winner` en otro
   caso (RS-BE-42 y decisiones abiertas 27 y 28). La app no calcula ese corte. `intro`,
   `closing` y `retake` no se pintan (decisión abierta 6).
3. **Tarjeta de la número uno.**
   - En claro, el fondo es un degradado del `color.light` de la ganadora a ese mismo color un
     20 % más oscuro, con el texto en blanco salvo el de la pastilla. En oscuro, el fondo es el
     `color.dark` al 18 % sobre `cardBg`, con un borde de 1 px en ese color al 35 %, el texto en
     `textPrimary` y el título en `color.dark`. Es un cambio frente a la pantalla 5 de la
     maqueta, que usa un degradado saturado con texto blanco (decisión abierta 22).
   - Arriba, «Tu n.º 1» con el ícono de la especialidad en una baldosa de 22 px, y a la derecha la
     pastilla «75 % afinidad», en tinta `#1A0E05` sobre un degradado de `#FFD166` a `#FFB020`.
   - El título es el `name` de la ganadora en 20,5 px y negrita, en hasta dos líneas y sin
     puntos suspensivos, porque «Tecnologías de la Información» no cabe en una.
   - Un medidor de 6 px con la afinidad, decorativo, porque el número ya está en la pastilla.
   - El motivo, `reason`, en 12,5 px. Si `reasonSource` es `"ai"`, lo encabeza la insignia «IA»,
     con `LucideIcons.sparkles`, en 10 px y negrita, sobre `testAiBadgeBg`, con el texto en
     blanco en claro y en `color.dark` en oscuro (RF-TEST-12). Con `"templates"` va sin
     insignia. Con la escala de texto en 1,0, el motivo se corta en cuatro líneas y «Leer más»
     lo despliega dentro de la tarjeta, con «Leer menos» para volver, porque los motivos de los
     ocho ejemplos del contenido `2026-09-25.4` miden de 190 a 541 caracteres y el de la
     maqueta 104 (decisión abierta 5).
   - Al entrar, la tarjeta gira una vez en 600 ms y la afinidad cuenta desde 0 hasta su valor en
     600 ms.
4. **Electivos.** Una fila con el ícono de libro en una baldosa del color de la ganadora, el
   título «N electivos», donde N es el número de electivos de la ganadora en el contenido, y
   debajo los dos primeros `shortName` unidos por « · », cortados con puntos suspensivos. «Ver»
   abre una hoja con el título «Electivos de <nombre>», el `tagline` y una fila por electivo con
   el `shortName` en negrita, «<código> · N créditos» y el `prerequisite` tal cual, en
   `testMuted`.
5. **Las demás.** El rótulo «También te puede interesar» y, a la derecha, un corazón pequeño con
   «guárdala», como en la maqueta. Debajo, una fila por cada especialidad desde el puesto 2, con
   el ícono en una baldosa de su color y el número del puesto encima, el nombre en 12,5 px y
   negrita, la afinidad «65 %» en su color y negrita, una barra de 4 px decorativa y el corazón
   de 48 px (RF-TEST-9). Si esa especialidad es la principal actual del alumno, en lugar del
   corazón va una estrella rellena con «Tu principal» en 11,5 px, las dos en `testAccentText`
   (RF-TEST-12) y sin acción.
6. **Botones.** «Elegir como principal», principal y a lo ancho, y debajo, en dos columnas,
   «Decidir después» y «Rehacer el test», con `LucideIcons.rotateCcw`.

- **Empate.** Con `tie: true`, el rótulo de la tarjeta es «Empate» y lleva los dos nombres, uno
  por línea, con una sola pastilla de afinidad, porque es la misma. El color de la tarjeta es el
  de la primera del ranking. La fila de electivos dice «Electivos de las dos» y su hoja trae una
  sección por especialidad. Las filas de abajo empiezan en el puesto 3, así que las dos
  ganadoras no tienen corazón. Por eso, al elegir una en la hoja del empate, la otra pasa a
  interés (RF-TEST-9 y decisión abierta 11).
- **Sin scroll.** A 375 × 667, el iPhone SE, con la escala de texto en 1,0 y el motivo cortado,
  todo cabe sin desplazar, en claro y en oscuro. Con más escala de texto o con el motivo
  desplegado, desplaza la parte del medio y los botones quedan fijos abajo.
- **Lo que no entra de la maqueta.** La línea de cada fila que explica el puesto («Perdió en el
  desempate», «Le diste "Un poco"», «Ganó 1 de 5 duelos») no entra, porque el contrato no la
  manda y calcularla en la app repetiría reglas del backend (decisión abierta 3). El nombre corto
  de «Elegir Software como principal» y de «7 electivos de Software» tampoco, porque el contrato
  no trae nombres cortos de especialidad, y el botón dice «Elegir como principal», como la
  decisión 4 (decisión abierta 4). El «Desde VI ciclo» del subtítulo de electivos tampoco,
  porque el contrato no trae un ciclo por especialidad y cada electivo tiene su propio
  `prerequisite`. En su lugar van los dos primeros `shortName`.
- **Atrás del sistema.** En el asistente no hace nada, porque los tres botones deciden. En el
  Perfil hace lo mismo que «Decidir después» (decisión abierta 12).
- **Cierre de la app.** Si el alumno cierra la app en el resultado del asistente sin tocar
  nada, `setupComplete` sigue en `false`, y al abrirla vuelve al paso de carrera y a la
  bienvenida, con el test desde cero, aunque el servidor ya tiene guardado el resultado
  (decisión abierta 12).

`[@test] ../../../test/HU36_jeff/specialty_test_resultado_test.dart`

### RF-TEST-9 · Elegir como principal, corazones y Decidir después

`PUT /academic-profile/me/specialties` reemplaza la selección entera (BR-AP-04), así que la app
siempre manda la principal y los intereses completos, con `AuthService.completeSetup`
(`auth_service.dart:330-376`), que ya pone al día el usuario y las preferencias. Los ids que
manda son solo los cuatro `specialtyId` del ranking, que el servidor resuelve entre las
especialidades activas, y la principal nunca viaja también como interés (RF-TEST-14).

- **Uno a la vez y con plazo.** Los tres guardados del resultado siguen la misma regla. Nunca
  hay dos en vuelo, cada uno vence a los 15 s (RF-TEST-2) y, si falla o vence, la pantalla
  vuelve al último estado confirmado y un aviso lo dice (RF-TEST-11). Como cada `PUT` manda la
  selección entera, repetirlo no duplica nada, y el siguiente guardado deja en el servidor lo
  que muestra la pantalla.
- **Elegir como principal.** Manda como principal el `specialtyId` de la ganadora y como
  intereses los corazones marcados, sin la ganadora. Si el alumno ya tiene otra principal y es
  una de las cuatro del ranking, esa principal anterior va también como interés, para que no
  salga de su selección sin que el alumno lo decida (decisión abierta 23). Con empate, el botón
  abre una hoja «¿Cuál eliges como principal?» con las dos ganadoras y «Cancelar», y la
  ganadora que no se elige va también como interés (decisión abierta 11). Si la ganadora ya es
  la principal, el botón se desactiva y dice «Ya es tu principal». Al guardar, en el asistente
  termina con `Get.offAllNamed('/home')`, y en el Perfil cierra la ruta y muestra el aviso de
  siempre, «Especialidades actualizadas» y «Tu selección se guardó correctamente.»
  (`perfil.dart:939-942`).
- **Corazón.** Marca o desmarca como interés la especialidad de su fila y guarda enseguida, con
  la principal actual sin cambios. El corazón cambia al tocarlo y, si el guardado falla o vence,
  vuelve a su estado y un aviso lo dice (RF-TEST-11). Nunca hay dos guardados en vuelo; los
  toques seguidos se juntan y se manda el último estado, y si ese guardado falla o vence, los
  toques juntados se descartan con él. Al abrir el resultado, los corazones marcados son los de
  las especialidades que ya son interés del alumno. En el asistente, el primer
  guardado marca además la configuración como completa (BR-AP-04), así que si el alumno cierra
  la app después de un corazón, la próxima vez entra a `/home` (decisión abierta 10).
- **Decidir después.** En el asistente, manda la selección actual, con la principal como está y
  los corazones marcados, para marcar la configuración como completa, y termina con
  `Get.offAllNamed('/home')`. En el Perfil cierra la ruta sin guardar nada, porque los
  corazones ya están guardados. El último resultado ya está guardado en el servidor aunque el
  alumno no elija nada (RS-BE-44).
- **Rehacer el test.** Vuelve a la pregunta 1 con el mismo contenido y sin respuestas, sin pasar
  por la bienvenida. Los corazones ya guardados se quedan. El resultado guardado cambia solo
  cuando el test nuevo termina (RS-BE-44).

`[@test] ../../../test/HU36_jeff/specialty_test_eleccion_test.dart`

### RF-TEST-10 · El último resultado en el Perfil y «Rehacer el test»

El Perfil suma la tarjeta `SpecialtyTestProfileCard` en «Configuración académica», debajo de
«Especialización» (`perfil.dart:310-337`). Como las demás tarjetas académicas, solo la ve un
alumno (`perfil.dart:44-51`). La maqueta no tiene esta tarjeta, así que su diseño lo fija esta
spec con las piezas del resultado (decisión abierta 16). La tarjeta se monta solo si
`SpecialtyTestService` está registrado, con la misma guarda `Get.isRegistered` que usa
`logout()` (`auth_service.dart:398-402`). En la app, `main.dart` siempre lo registra. La guarda
existe para que las pruebas que montan el Perfil sin ese service, como
`test/HU34_jeff/record_card_test.dart:253-271`, sigan pasando sin tocarlas y sin HTTP real.

- **Cargando.** Un `SkeletonPulse`, como la tarjeta del récord.
- **Sin test.** Ulises a 28 px, el título «Test de especialidad», «Todavía no hiciste el test.» y
  el botón «Hacer el test».
- **Con resultado.** El título «Test de especialidad» y «Hecho el dd/mm/aaaa», con la fecha de
  `completedAt` en hora de Lima (UTC−5, sin horario de verano, con una función propia como la
  del chat). Debajo, la número uno, o las dos del empate, con el ícono en su baldosa, el nombre y
  la afinidad, y las demás en filas compactas con su afinidad y su barra. Si
  `isCurrentVersion` es `false`, una línea dice «El test cambió desde que lo hiciste.». Al final,
  el botón «Rehacer el test». No hay motivo, porque no se guarda (RS-BE-44).
- **En pausa.** Si hay un test a medias en memoria, la tarjeta dice «Tienes un test a medias, N
  de T.» y su botón es «Seguir el test», con o sin un resultado anterior debajo.
- **Error.** «No se pudo cargar tu último test.» y «Reintentar».
- **No disponible.** Con `404 SPECIALTY_TEST_NOT_AVAILABLE`, la tarjeta no aparece.
- **Colores.** Salen de la copia del contenido de la sesión (RF-TEST-2). Si todavía no hay
  copia, la tarjeta la pide junto con el último resultado. Si el contenido no carga, los nombres y
  las afinidades salen del resultado igual, y los íconos y las barras van en los colores neutros
  (`iconoNaranja` y `testMuted`).
- **Botones.** «Hacer el test», «Rehacer el test» y «Seguir el test» abren `/test-especialidad`
  con `origen: perfil`, que empieza en la bienvenida (RF-TEST-3). Al volver de un test
  terminado, la tarjeta pide el último resultado otra vez.

`[@test] ../../../test/HU36_jeff/specialty_test_perfil_test.dart`

### RF-TEST-11 · Errores y sin conexión

Entre pregunta y pregunta el test no usa la red, así que una caída de conexión solo se nota al
cargar, al evaluar y al guardar. Los textos de error van en `textPrimary` sobre `cardBg`, con el
ícono en `iconoNaranja`, y «Reintentar» va como botón secundario en `testAccentText`. Los avisos
pasajeros de un guardado que falla o vence («No se pudo guardar…», «No se pudo confirmar el
guardado…» o el mensaje del servidor) van en blanco sobre `errorBg` (6,54:1), como los avisos
de error del chat (RF-CHAT-8). Los avisos que solo informan, como el de no disponible, van en
`cardBg` con borde `borderColor` y texto en `textPrimary`, como los demás avisos del chat. El
aviso de éxito del Perfil («Especialidades actualizadas») no cambia.

| Momento | Caso | Qué ve el alumno |
| --- | --- | --- |
| Bienvenida | Sin conexión, plazo vencido, contenido no válido, `500` u otro error | «No pudimos cargar el test.» y «Reintentar». El botón secundario sigue activo |
| Bienvenida | `404 SPECIALTY_TEST_NOT_AVAILABLE` | En el asistente, la selección manual sin aviso. En el Perfil, el mensaje del servidor y el cierre de la ruta |
| Preguntas | Sin conexión | Nada. El test sigue |
| Espera | Sin conexión o plazo vencido | En lugar de la burbuja de espera, «No pudimos conectarnos. Revisa tu conexión e inténtalo de nuevo.» y «Reintentar», con las respuestas intactas y «Pregunta anterior» disponible |
| Espera | `409 SPECIALTY_TEST_VERSION_OUTDATED` (versión retirada, también la de un test en pausa) o `400 SPECIALTY_TEST_INVALID_ANSWERS` | Un diálogo con el mensaje del servidor y «Empezar de nuevo», que pide el contenido otra vez y abre la pregunta 1 |
| Espera | `404 SPECIALTY_TEST_NOT_AVAILABLE` (paso 6 de RS-BE-39) | Un aviso con el mensaje del servidor y las respuestas borradas. En el asistente, la selección manual; en el Perfil, el cierre de la ruta. No hay «Reintentar», porque repetir da lo mismo |
| Espera | `400 SPECIALTY_TEST_TIEBREAK_MISMATCH` | La app descarta sus desempates y repite una sola vez con `tiebreakAnswers` vacío, y sigue con lo que responda el servidor. Si vuelve a fallar, el estado de error de la espera |
| Espera | `429 RATE_LIMITED` | El mensaje del servidor tal cual, que dice los minutos, y «Reintentar». Las respuestas se conservan |
| Espera | `413`, `500` u otro error con mensaje | El mensaje del servidor y «Reintentar» |
| Espera | Cohere falla o tarda | Nada. Llega `reasonSource: "templates"` y el motivo va sin la insignia «IA» |
| Resultado | El `PUT` falla | Un aviso con el mensaje del servidor o, sin mensaje, «No se pudo guardar. Revisa tu conexión e inténtalo de nuevo.». El corazón vuelve a su estado y el resultado sigue en pantalla |
| Resultado | El `PUT` no responde en 15 s | «No se pudo confirmar el guardado. Revisa tu conexión e inténtalo de nuevo.», porque el guardado puede estar hecho en el servidor. Los corazones vuelven al último estado confirmado y, en el asistente, los botones responden otra vez y el asistente no termina. Repetir es seguro, porque cada `PUT` manda la selección entera (RF-TEST-9) |
| Perfil | El último resultado falla | «No se pudo cargar tu último test.» y «Reintentar» |
| Cualquiera | `401` | `ApiClient` cierra la sesión y lleva al login, como en toda la app (`api_client.dart:143-161`) |
| Cualquiera | `403` | No ocurre, porque la app nunca abre el test para un docente |

`[@test] ../../../test/HU36_jeff/specialty_test_errores_test.dart`

### RF-TEST-12 · Modo oscuro y contraste

- **Tema.** El test, el asistente entero y la tarjeta del Perfil siguen
  `Theme.of(context).brightness`, que sale del tema del sistema (`main.dart:116`). Los widgets
  nuevos no llevan hex sueltos. Sus colores son tokens de `MaterialTheme` o los colores de las
  especialidades que manda el contenido.
- **Tokens nuevos.** Salen de la paleta de la maqueta, que ya llega al contraste pedido, y viven
  en `themes.dart` como los del chat. Se reusan `pageBg`, `cardBg`, `textPrimary`, `headerColor`,
  `borderColor`, `iconoNaranja` y `errorBg`.

| Token | Claro | Oscuro | Uso |
| --- | --- | --- | --- |
| `testInk2` | `#334155` | `#CFCFDB` | Texto de la tarjeta apagada y de las opciones |
| `testMuted` | `#556070` | `#A5A5B5` | Texto secundario del test y de la tarjeta del Perfil |
| `testLine` | `#E2E8F0` | `#30303A` | Bordes de tarjetas y botones |
| `testChipBg` | `#EEF2F7` | `#24242C` | Pastilla del historial |
| `testAccent` | `#FF6600` | `#FF8C42` | Fondo del botón principal y de la opción elegida |
| `testAccentHi` | `#FF7F24` | `#FF9D5C` | Tope del degradado del botón principal |
| `testAccentInk` | `#1A0E05` | `#16161C` | Texto sobre `testAccent` |
| `testAccentText` | `#B84A00` | `#FF9A57` | Rótulos, botones secundarios y «Reintentar» |
| `testAccentDeep` | `#7A3300` | `#FFC49A` | Texto sobre `testAccentSoft` |
| `testAccentSoft` | `#FFF1E6` | `#3A2A22` | Pastillas, sello y opción elegida |
| `testHeartOff` | `#64748B` | `#9A9AAC` | Corazón sin marcar |
| `testTrack` | `#E8EDF3` | `#2C2C36` | Pista de las barras |
| `testFeatherOn` | `#D45500` | `#FF8C42` | Plumas llenas |
| `testFeatherOff` | `#CBD5E1` | `#3A3A46` | Plumas vacías |
| `testTaskTileBg` | `#F1F5F9` | `#25252D` | Baldosa del ícono de la tarea |
| `testTaskIconInk` | `#64748B` | `#8A8A9C` | Ícono de la tarea antes del toque y en la escala, y el ícono neutro |
| `testAiBadgeBg` | `#140A50` al 38 % | `#16161C` | Fondo de la insignia «IA» de la tarjeta del resultado |

  La pluma llena de la maqueta es `#FF6600`, que sobre `#F8FAFC` da 2,81:1 y no llega al 3:1 de
  un ícono, así que en claro va en `#D45500`, con 3,94:1 (decisión abierta 15).

- **Colores de las especialidades.** Son los del contenido, `color.light` y `color.dark`, que
  manda el servidor, y no los de la maqueta (`#5B4BDB`, `#0B7A71`, `#2563EB` y `#C0267E`). La
  spec toma los de la maqueta como ilustrativos, y el dueño aprueba esa lectura el 2026-09-25
  (decisión abierta 1). La `2026-09-25.4` que publica el backend trae estos colores, que dan
  estos contrastes.

| Clave | Claro | Sobre `#FFFFFF` y `#F8FAFC` | Blanco sobre el color | Tinta sobre la tarjeta encendida | Oscuro | Sobre `#1E1E24` y `#16161C` | Tinta y color sobre la tarjeta del resultado |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `sw` | `#1E3A8A` | 10,36:1 y 9,90:1 | 10,36:1 | 14,45:1 | `#A5C0F7` | 9,07:1 y 9,85:1 | 9,57:1 y 6,10:1 |
| `ti` | `#0F7A45` | 5,40:1 y 5,16:1 | 5,40:1 | 15,10:1 | `#7EE8BE` | 11,19:1 y 12,16:1 | 9,12:1 y 7,18:1 |
| `si` | `#9333EA` | 5,38:1 y 5,14:1 | 5,38:1 | 14,97:1 | `#B98AF8` | 6,36:1 y 6,91:1 | 10,48:1 y 4,69:1 |
| `vj` | `#76164A` | 10,58:1 y 10,12:1 | 10,58:1 | 14,31:1 | `#EC7FB3` | 6,52:1 y 7,08:1 | 10,50:1 y 4,81:1 |

  La tarjeta encendida es el color al 12 % sobre `cardBg`, con el texto en `textPrimary`. La
  tarjeta del resultado en oscuro es el color al 18 % sobre `#1E1E24`, con el texto en
  `textPrimary` y el título en el color, porque el blanco sobre los `color.dark` da solo de
  1,48:1 a 2,61:1 (decisión abierta 22). En claro, el extremo más oscuro del degradado solo sube
  el contraste del blanco (de 5,38:1 a 7,49:1 en el peor caso, `si`).

- **Guarda en tiempo de ejecución.** El contenido puede cambiar de versión sin otro APK, así que
  la app no confía a ciegas en sus colores. Una función pura calcula el contraste WCAG, y si un
  color servido no llega a 4,5:1 contra el fondo donde va como texto, o a 3:1 donde va como
  ícono, ese texto o ícono va en `textPrimary` y el color queda solo en las piezas decorativas.
  Un hex que no se puede leer cuenta como neutro y no invalida el contenido (RF-TEST-2).
- **Contraste del resto.** Todo texto del test, del asistente y de la tarjeta del Perfil llega a
  4,5:1 contra su fondo en los dos temas, y todo ícono que da información, a 3:1. La única
  excepción es la cabecera del asistente en claro, con texto blanco sobre `#FF6600` a 2,94:1,
  un riesgo conocido que el dueño acepta el 2026-09-25 (RF-TEST-1 y decisión 9).

| Par | Claro | Oscuro |
| --- | --- | --- |
| Texto principal sobre la página | `#0F172A` sobre `#F8FAFC`, 17,06:1 | `#EDEDF3` sobre `#16161C`, 15,45:1 |
| Texto principal sobre la tarjeta | `#0F172A` sobre `#FFFFFF`, 17,85:1 | `#EDEDF3` sobre `#1E1E24`, 14,22:1 |
| `testInk2` sobre la tarjeta | 10,35:1 | 10,74:1 |
| `testMuted` sobre la página y la tarjeta | 6,09:1 y 6,38:1 | 7,42:1 y 6,83:1 |
| `testAccentText` sobre la página | 5,00:1 | 8,59:1 |
| `testAccentInk` sobre `testAccent` y `testAccentHi` | 6,45:1 y 7,50:1 | 7,79:1 y 8,78:1 |
| `testAccentDeep` sobre `testAccentSoft` | 8,25:1 | 8,87:1 |
| Ícono en `testAccentText` sobre `testAccentSoft` | 4,72:1 | 6,53:1 |
| `testMuted` sobre `testChipBg` | 5,67:1 | 6,34:1 |
| `testFeatherOn` sobre la página | 3,94:1 | 7,79:1 |
| `testHeartOff` sobre la página | 4,55:1 | 6,51:1 |
| Tinta `#1A0E05` sobre el naranja del héroe `#FF6600` | 6,45:1 | 6,45:1 |
| Tinta `#1A0E05` sobre la pastilla `#FFB020` | 10,36:1 | 10,36:1 |
| Insignia «IA» | Blanco sobre `testAiBadgeBg` encima del `color.light`, de 8,79:1 a 13,69:1 | `color.dark` sobre `testAiBadgeBg`, de 6,91:1 a 12,16:1 |
| Estrella y «Tu principal» en `testAccentText` sobre la página | 5,00:1 | 8,59:1 |
| Blanco sobre `errorBg` (`#B3261E`) en los avisos de error | 6,54:1 | 6,54:1 |
| Blanco sobre `headerColor` en la cabecera del asistente | 2,94:1, riesgo conocido que el dueño acepta (decisión 9) | 16,58:1 |

- **Piezas decorativas.** El medidor y las barras de afinidad, el halo, el confeti, el punto
  verde, la moneda «o», los orbes del héroe, las plumas y los íconos de las tareas no llevan
  un contraste mínimo, porque lo que dicen está también en texto. El medidor dorado sobre la
  pista de la tarjeta, por ejemplo, baja a 1,87:1 con `ti`, y la afinidad se lee en la pastilla.

`[@test] ../../../test/HU36_jeff/specialty_test_contraste_test.dart`

### RF-TEST-13 · Accesibilidad

- **Lectores de pantalla.** Con TalkBack y VoiceOver rigen estas etiquetas.
  - Cada tarjeta del duelo es un botón con el texto de su tarea como etiqueta, `duelHelp` como
    pista y el estado `selected` después de elegir. «Me gustan las dos» y «Ninguna me llama»
    son botones con su texto.
  - La escala es un grupo con el `prompt` como etiqueta, y cada opción es un botón con
    `inMutuallyExclusiveGroup`, su etiqueta y el estado `checked`.
  - La burbuja de Ulises es una región viva (`liveRegion`), así que al avanzar se lee la
    reacción, y el `prompt` de la pregunta nueva es un encabezado (`header`).
  - Al cambiar de pregunta, el foco del lector pasa al `prompt` de la pregunta nueva, y al
    volver con «Pregunta anterior», al de esa pregunta. En la espera queda en la burbuja de
    espera, y al abrir el resultado pasa a la burbuja de Ulises. El foco nunca se queda en una
    tarjeta que ya no está en pantalla.
  - «Pregunta anterior» y «Pausar el test y seguir luego» son las etiquetas de sus botones, y
    el subtítulo de la barra se lee. La pastilla del historial dice «Ver tus N respuestas
    anteriores» u «Ocultar tus respuestas anteriores», con su estado desplegado.
  - La tarjeta del resultado es un solo nodo con «Tu n.º 1, <nombre>, <afinidad> % de
    afinidad», o «Empate, <nombre> y <nombre>, <afinidad> % de afinidad», y el motivo. La
    insignia «IA» se lee «Motivo redactado con IA». «Leer más» es un botón. La estrella de «Tu
    principal» queda fuera del árbol y su texto se lee con la fila.
  - Cada fila del ranking se lee «Puesto N, <nombre>, <afinidad> % de afinidad». El corazón es
    un botón con `toggled`, cuya etiqueta es «Marcar <nombre> como interés» o «Quitar <nombre>
    de tus intereses», como en la maqueta.
  - Quedan fuera del árbol de accesibilidad las imágenes de Ulises, los orbes, el punto verde,
    las plumas, la moneda, los emojis, los íconos de las tareas, el medidor, las barras y el
    confeti.
  - Sin avance solo y con el botón «Siguiente», como dice RF-TEST-5, porque un cambio de
    pregunta sin aviso desorienta a quien navega por voz (WCAG 3.2.2).
- **Tamaño de texto.** Todo respeta `MediaQuery.textScaler` hasta el 200 %. Ningún contenedor de
  texto tiene alto fijo, solo alto mínimo. Desde 1,3, la escala va en dos por dos, «Me gustan
  las dos» y «Ninguna me llama» van una debajo de otra y el héroe baja a 200 px. A 375 × 667, con
  1,0, 1,3 y 2,0, ninguna pantalla desborda.
- **Menos movimiento.** Con `MediaQuery.disableAnimationsOf(context)`, no hay vaivén de Ulises ni
  de los orbes, brillo de la pluma, salto de la insignia, giro de la tarjeta, confeti, cuenta de
  la afinidad (sale el valor final) ni crecimiento de la opción, y el indicador de la espera no
  gira. Todas las transiciones pasan a fundidos de 150 ms. La pausa de 350 ms antes de avanzar
  se queda, porque no es movimiento.
- **Blancos táctiles.** Los botones de ícono (atrás, pausa, corazón y «Ver») miden al menos
  48 × 48, y los demás botones, al menos 48 de alto.
- **El color nunca va solo.** La tarjeta elegida lleva además la insignia con el visto, el borde
  más grueso y el estado `selected`. La opción de la escala lleva el borde, el tamaño y
  `checked`, y el corazón marcado va relleno, con `toggled`.
- **Vibración.** Sigue a la maqueta y nunca reemplaza una señal visual ni de texto.

`[@test] ../../../test/HU36_jeff/specialty_test_accesibilidad_test.dart`

### RF-TEST-14 · Solo lo oficial en la app y el id antiguo (decisión 6)

Con BR-AP-07, el catálogo de `GET /academic-profile/specialties` trae solo las cuatro
oficiales. Un id antiguo puede seguir en la app por dos caminos. El primero es el usuario en
memoria, porque `/auth/me` y el login siguen leyendo lo guardado sin filtro (decisión abierta 13
del backend). El segundo son las preferencias locales que escribe `saveSetup`
(`storage_service.dart:128-156`), aunque ningún código lee esas claves para pintar
(`savedSetupFor` no tiene quien lo llame). Hoy, `getEspecialidadName`
(`auth_service.dart:92-95`) devuelve `''` para un id que no está en el catálogo, y el Perfil
pinta un chip vacío (`_PrincipalChip` y `_InteresChip`, `perfil.dart:490-610`). Según la
comprobación en solo lectura del 2026-09-25, ninguna selección activa apunta a una antigua, así
que el caso es de defensa.

- **`getEspecialidadName` no cambia.** Sigue devolviendo `''` para un id desconocido, porque la
  malla depende de eso. `electiveMatchesUserSpecialties` (`malla_service.dart:180-194`) descarta
  los nombres vacíos, así que los electivos de una especialidad antigua dejan de aparecer en la
  malla, lo que es coherente con mostrar solo lo oficial (decisión 6).
  `_PrincipalChip._pendingCount` ya devuelve 0 con un nombre vacío.
- **Consultas nuevas.** `AuthService` suma `isOfficialSpecialty(int id)`, que dice si el id está
  en el catálogo cargado, y `catalogsFailed`, que distingue un catálogo que no carga de uno que
  carga vacío, como el de una carrera sin especialidades. Suma también `reloadCatalogs()`, el
  mismo `_loadCatalogs` expuesto para «Reintentar».
- **Selección oficial.** Una función pura recibe la principal, los intereses y los ids oficiales
  y devuelve la principal solo si es oficial y los intereses oficiales sin la principal.
- **Perfil.** Con el catálogo cargado, la tarjeta «Especialización» pinta solo los ids
  oficiales. Si no queda ninguno, dice «Sin especialización seleccionada» en `textSecondary`, en
  lugar del `placeholderText` de hoy (`perfil.dart:440`), que da 2,32:1. Nunca pinta un chip
  vacío. Con el catálogo fallido, dice «No se pudieron cargar tus especialidades.» con
  «Reintentar», y «Editar» no abre la hoja hasta que el catálogo cargue.
- **Nunca se manda un id antiguo.** La hoja de «Editar» (`perfil.dart:875-889`) y la selección
  manual del asistente (`setup_carrera_controller.dart:37-45`) arrancan con la selección
  oficial, así que su `PUT` no lleva un id antiguo, que con BR-AP-07 daría
  `404 SPECIALTY_NOT_FOUND`. Como el `PUT` reemplaza la selección entera, al guardar el id
  antiguo sale de la selección del alumno en la base. La decisión 6 no lo pide, porque solo
  pide mostrar y elegir lo oficial sin tocar los datos de especialidades. Es una consecuencia
  de mandar solo ids oficiales (decisión abierta 26). El resultado del test usa como ids
  oficiales los cuatro `specialtyId` del ranking (RF-TEST-9), así que no depende del catálogo.
- **El test no usa `getEspecialidadName`.** El resultado y la tarjeta del Perfil toman el
  `name` y el `specialtyId` que manda el servidor.
- **El filtro del cliente se queda.** La app sigue filtrando `is_active == true`
  (`setup_carrera_controller.dart:26-28` y `perfil.dart:895-897`) como defensa, aunque con
  BR-AP-07 ya no excluye nada.

`[@test] ../../../test/HU36_jeff/perfil_especialidad_antigua_test.dart`
`[@test] ../../../test/HU36_jeff/specialty_test_logic_test.dart`

## Textos nuevos

Los textos de Ulises, las preguntas, las tareas, las opciones, los nombres, los electivos, el
motivo y los mensajes de error del servidor vienen del backend y la app los muestra tal cual.
Los textos propios de la app son estos.

- **Bienvenida.** «Test de especialidad», «Ulises», «3 a 4 min», «Rehazlo en Perfil», «Empezar el
  test», «Saltar y elegir por mi cuenta», «Ahora no», «Seguir el test», «Empezar de nuevo» y «No
  pudimos cargar el test.».
- **Conversación.** «Pregunta N de T», «Desempate 1», «Desempate 2», «Pregunta anterior»,
  «Pausar el test y seguir luego», «N respuestas anteriores», «1 respuesta anterior», «Ver tus N
  respuestas anteriores», «Ver tu respuesta anterior», «Ocultar tus respuestas anteriores»,
  «Cierra el bloque k de B», «Esto o aquello», «Escala de gusto», «Desempate», «o» y «Siguiente».
- **Espera.** «No pudimos conectarnos. Revisa tu conexión e inténtalo de nuevo.» y «Reintentar».
- **Resultado.** «Tu n.º 1», «Empate», «N % afinidad», «Tu n.º 1, <nombre>, N % de afinidad»,
  «Empate, <nombre> y <nombre>, N % de afinidad», «IA», «Motivo redactado con IA», «Leer
  más», «Leer menos», «N electivos», «1 electivo», «Electivos de las dos», «Ver», «Electivos
  de <nombre>», «<código> · N créditos», «También te puede interesar», «guárdala», «Puesto N,
  <nombre>, N % de afinidad», «Marcar <nombre> como interés», «Quitar <nombre> de tus
  intereses», «Tu principal», «Elegir como principal», «Ya es tu principal», «¿Cuál eliges como
  principal?», «Cancelar», «Decidir después», «Rehacer el test», «No se pudo guardar. Revisa tu
  conexión e inténtalo de nuevo.» y «No se pudo confirmar el guardado. Revisa tu conexión e
  inténtalo de nuevo.».
- **Perfil.** «Test de especialidad», «Hecho el dd/mm/aaaa», «El test cambió desde que lo
  hiciste.», «Todavía no hiciste el test.», «Hacer el test», «Tienes un test a medias, N de T.»,
  «Seguir el test», «No se pudo cargar tu último test.», «No se pudieron cargar tus
  especialidades.» y «Reintentar».
- **Asistente.** «No pudimos cargar tu carrera.» y «No pudimos cargar las especialidades.».

El plan de la app (decisión 5 de `docs/superpowers/plans/2026-09-25-specialty-test-app.md`) suma
a esta lista «Ver tu respuesta anterior» y «1 electivo», dos derivados menores de textos ya
aprobados que no cambian ningún requisito. El primero es la etiqueta del lector de pantalla para
la pastilla del historial con una sola respuesta, el singular de «Ver tus N respuestas
anteriores», como «1 respuesta anterior» lo es de la pastilla. El segundo es el singular de «N
electivos», que con el contenido `2026-09-25.4`, de siete electivos por diploma, no aparece. El
dueño los lee antes del merge.

Salen los textos del paso «Decisión», que son «Especialización», «Opcional. Puedes elegirla
ahora, explorarla o decidirlo luego desde tu perfil.», «Sí, quiero elegir ahora», «Todavía no
estoy seguro», «Quiero explorar primero» y sus subtítulos.

## Pantallas y archivos

### Pantallas

| Pantalla | Estado | Requisito |
| --- | --- | --- |
| Bienvenida del test, con Ulises y «Empezar el test» | Nueva | RF-TEST-3 |
| Pregunta de duelo, de escala y de desempate, con la barra, las plumas y el historial | Nueva | RF-TEST-4 a RF-TEST-6 |
| Espera de la evaluación | Nueva | RF-TEST-7 |
| Resultado, con la hoja de electivos y la hoja del empate | Nueva | RF-TEST-8 y RF-TEST-9 |
| Tarjeta del test en el Perfil | Nueva | RF-TEST-10 |
| Asistente, paso de carrera | Cambia (modo oscuro, estado de catálogo, botón, precarga) | RF-TEST-1 |
| Asistente, paso «Decisión» | Sale | RF-TEST-1 |
| Asistente, selección manual | Cambia (modo oscuro, estado de catálogo, solo oficiales, botón) | RF-TEST-1 y RF-TEST-14 |
| Perfil, tarjeta «Especialización» y su hoja de «Editar» | Cambia (id antiguo y catálogo fallido) | RF-TEST-14 |
| Login, home, malla y chatbot | No cambian | «Qué NO entra» |

### Se crean

| Archivo | Qué tiene |
| --- | --- |
| `lib/pages/specialty_test/specialty_test_page.dart` | La ruta `/test-especialidad`, que cambia entre bienvenida, pregunta, espera y resultado |
| `lib/pages/specialty_test/specialty_test_controller.dart` | El recorrido del test, el atrás, la pausa, los reintentos y los guardados |
| `lib/pages/specialty_test/specialty_test_binding.dart` | El binding por ruta |
| `lib/pages/specialty_test/specialty_test_logic.dart` | Funciones puras de las líneas de Ulises, el sello, el historial, el descarte de desempates, el cuerpo de la evaluación, la selección oficial, los corazones, el contraste, los colores, el mapa de íconos con su ícono neutro y la fecha en Lima |
| `lib/pages/specialty_test/widgets/welcome_view.dart` | La bienvenida (RF-TEST-3) |
| `lib/pages/specialty_test/widgets/question_view.dart` | La barra, las plumas, el historial, el duelo, la escala y el desempate (RF-TEST-4 a RF-TEST-6) |
| `lib/pages/specialty_test/widgets/waiting_view.dart` | La espera y su error (RF-TEST-7 y RF-TEST-11) |
| `lib/pages/specialty_test/widgets/result_view.dart` | El resultado (RF-TEST-8 y RF-TEST-9) |
| `lib/pages/specialty_test/widgets/electives_sheet.dart` | La hoja de electivos |
| `lib/pages/specialty_test/widgets/ulises_bubble.dart` | La burbuja y el avatar de Ulises |
| `lib/pages/specialty_test/widgets/test_buttons.dart` | El botón principal, el secundario y el mensaje de error que comparten el test, la tarjeta del Perfil, el Perfil y el asistente |
| `lib/pages/specialty_test/widgets/task_icon.dart` | La baldosa con el ícono de la tarea, en `testTaskIconInk` o en el color de su especialidad (RF-TEST-5 y RF-TEST-6) |
| `lib/pages/specialty_test/specialty_test_profile_card.dart` | La tarjeta del Perfil (RF-TEST-10) |
| `lib/pages/setup_carrera/setup_carrera_binding.dart` | El binding por ruta del asistente |
| `lib/services/specialty_test_service.dart` | La capa de datos (RF-TEST-2) |
| `lib/models/specialty_test_models.dart` | Los modelos del contrato |
| `test/HU36_jeff/*.dart` | Las pruebas de «Pruebas por requisito» |

### Cambian

| Archivo | Qué cambia |
| --- | --- |
| `lib/main.dart` | Registra `SpecialtyTestService` y agrega `/test-especialidad` con su binding y el binding de `/setup-carrera` |
| `lib/pages/setup_carrera/setup_carrera_controller.dart` | Sin el paso «Decisión», con la precarga, la vuelta de la ruta del test y la selección oficial |
| `lib/pages/setup_carrera/setup_carrera_page.dart` | Sin el paso «Decisión», sin `Get.put` en `build`, con tokens en lugar de hex, los estados de catálogo, el atrás de la selección manual y el botón nuevo |
| `lib/pages/perfil/perfil.dart` | La tarjeta del test en «Configuración académica», montada solo con `SpecialtyTestService` registrado, y el caso del id antiguo en «Especialización» y en su hoja |
| `lib/services/auth_service.dart` | `isOfficialSpecialty` sobre `officialSpecialtyIds`, `catalogsFailed`, `reloadCatalogs`, el parámetro opcional `timeout` de `completeSetup`, `clear()` del test en `logout()` y el parámetro opcional `apiClient` del constructor, que solo usan las pruebas |
| `lib/configs/themes.dart` | Los tokens de RF-TEST-12 |

### No cambian

| Archivo | Por qué |
| --- | --- |
| `lib/services/post_login_route.dart` | El alumno sin configuración sigue entrando a `/setup-carrera` |
| `lib/services/storage_service.dart` | El test no guarda nada en disco y las claves viejas de especialidades no se leen para pintar |
| `lib/services/api_client.dart` | Los plazos van en el service y en `completeSetup`, como en los demás |
| `test/HU34_jeff/record_card_test.dart` | Monta el Perfil sin `SpecialtyTestService`, y la guarda de RF-TEST-10 deja fuera la tarjeta |
| `lib/services/malla_service.dart` | Ya descarta los nombres vacíos (RF-TEST-14) |
| `lib/models/user_model.dart` | La principal y los intereses siguen igual |
| `lib/pages/chatbot/**` | El chatbot no lee el resultado (RS-BE-47) |
| `pubspec.yaml` | Los íconos de las tareas salen de `lucide_icons_flutter` 3.1.15, que ya está, y el test no suma assets (decisión 8) |

## Contrato que se consume

El detalle está en `docs/specs/api-contracts.md` («Specialty Test» y la enmienda de «Academic
Profile») y en la spec del backend. Todas las rutas usan el token del alumno, y ninguna lleva
datos del alumno en el cuerpo.

- `GET /specialty-test/content` devuelve la versión vigente, las cuatro especialidades con su
  `specialtyId`, sus colores, su ícono y sus electivos, las líneas de Ulises del recorrido, las
  opciones y las preguntas, cada tarea con su id, su texto, su descripción de ilustración, el
  nombre de su ícono en Lucide y la clave de su especialidad.
- `POST /specialty-test/me/evaluate` recibe todas las respuestas y devuelve el siguiente
  desempate, con sus dos tareas en la misma forma y la línea de Ulises, o el resultado con el
  ranking, el empate, el motivo, su origen y las líneas de Ulises. El resultado queda guardado
  como el último del alumno.
- `GET /specialty-test/me/result` devuelve el último resultado, sin motivo y con
  `isCurrentVersion`, o `{ "result": null }`.
- `PUT /academic-profile/me/specialties` sin cambios de forma, con `404 SPECIALTY_NOT_FOUND` para
  una especialidad inactiva y el reemplazo en una sola transacción (BR-AP-07 y BR-AP-08).
- `GET /academic-profile/specialties` trae solo las activas (BR-AP-07). La app lee de cada
  elemento `id`, `carrera_id`, `name`, `description`, `is_active` y `display_order`.

## Pruebas por requisito

Todas están en `test/HU36_jeff/`, con los datos y los dobles que comparten
(`datos_de_prueba.dart`, `dobles_de_red.dart`, `dobles_del_controlador.dart` y
`montaje_de_pantallas.dart`). Las pruebas de widget usan un `ApiClient` falso y datos
inventados, con el alumno de prueba 20230001, y las que miden espacio cargan Roboto del SDK.

| Requisito | Pruebas | Qué fijan |
| --- | --- | --- |
| RF-TEST-1 | `setup_carrera_flujo_test.dart` | Carrera, test y selección manual; sin el paso «Decisión»; «Saltar» y el `404` llevan a la selección manual; el atrás del sistema en cada paso, con la salida de la app en el de carrera; la precarga pedida una sola vez al montar el asistente; el binding; los estados de catálogo vacío y fallido; el botón nuevo sin corte a 375 de ancho; la cabecera en `headerColor` con texto blanco en los dos temas; ningún hex fijo en el asistente en oscuro |
| RF-TEST-2 | `specialty_test_service_test.dart`, `specialty_test_models_test.dart` | Las tres rutas y sus cuerpos; los plazos de 15 y 20 s; la guarda por dueño; `clear()` en `logout()`; un pedido del contenido por apertura de la ruta, con la precarga como el de la primera apertura en el asistente (copia reusada si ya está, espera si sigue en vuelo y pedido nuevo si termina en error); el plazo de 15 s de `completeSetup` con `timeout`, sin tocar el usuario al vencer; la traducción de cada error; los `null` conservados; el contenido no válido rechazado, también sin cuatro `scaleOptions` o sin `both` y `none`; el hex ilegible y el `icon` ausente o fuera del mapa, que no lo invalidan |
| RF-TEST-3 | `specialty_test_bienvenida_test.dart` | Las líneas de bienvenida en orden y sin nombre; las pastillas y los botones según el origen; «Seguir el test» y «Empezar de nuevo» con un test en pausa; cargando, error y no disponible; las cuatro líneas de `welcome` de `2026-09-25.4` a 375 × 667, con el cuerpo que desplaza, sin desborde y con los botones a la vista |
| RF-TEST-4 | `specialty_test_conversacion_test.dart`, `specialty_test_logic_test.dart` | La regla de cada burbuja, con reacción propia, rotación de `pick`, `both`, `none` y `scale`, `duelHelp` y `scaleHelp`; el sello con k y B contados; el historial; el atrás con el descarte de desempates; el atrás desde la espera, con el paso tardío descartado, el resultado tardío marcado como viejo y la evaluación siguiente en cola; la pausa con la versión vigente cambiada, que sigue con su copia |
| RF-TEST-5 y RF-TEST-6 | `specialty_test_preguntas_test.dart`, `specialty_test_logic_test.dart` | Tarjetas neutras antes del toque; el encendido con el color del tema; las dos y ninguna; el avance a los 350 ms y los toques ignorados; el ícono de la tarea en `testTaskIconInk` antes del toque y en el color de su especialidad después, también en el desempate; el ícono de la escala siempre en `testTaskIconInk`; el mapa con los 52 nombres de la `2026-09-25.4` y ningún otro; `LucideIcons.sparkles` con un nombre fuera del mapa o sin `icon`; la escala en cuatro y en dos por dos |
| RF-TEST-7 | `specialty_test_evaluacion_test.dart` | La evaluación tras la última pregunta; el texto de espera; uno y dos desempates; el resultado; ninguna evaluación doble; el mismo cuerpo en el reintento |
| RF-TEST-8 | `specialty_test_resultado_test.dart` | Las piezas en orden; `headline` y `tiebreakOutcome` en la burbuja, con las líneas `low` y `tie` tal cual llegan, y sin `intro`; la insignia «IA» solo con `"ai"`; el motivo cortado y «Leer más»; el empate; sin desplazar a 375 × 667 con 1,0 en claro y en oscuro; la hoja de electivos; «Tu principal» con su estrella; el atrás del sistema, sin efecto en el asistente e igual a «Decidir después» en el Perfil |
| RF-TEST-9 | `specialty_test_eleccion_test.dart` | El cuerpo del `PUT` al elegir, con empate y la otra ganadora como interés, con la ganadora ya principal y con una principal anterior distinta que pasa a interés; los corazones marcados al abrir según los intereses del alumno; el corazón que guarda, revierte y junta toques; el primer corazón en el asistente, que completa la configuración; el plazo de 15 s, con el estado confirmado de vuelta y el aviso propio; ningún guardado doble entre corazones y botones; «Decidir después» en el asistente y en el Perfil; «Rehacer el test» |
| RF-TEST-10 | `specialty_test_perfil_test.dart` | Los seis estados de la tarjeta; la fecha en hora de Lima con `TZ=UTC`; «El test cambió desde que lo hiciste.»; los colores neutros sin contenido; la recarga al volver; la tarjeta ausente, sin fallo del Perfil, cuando `SpecialtyTestService` no está registrado |
| RF-TEST-11 | `specialty_test_errores_test.dart` | Cada fila de la tabla de errores |
| RF-TEST-12 | `specialty_test_contraste_test.dart` | Cada token en los dos temas; los colores del contenido de la tabla; la guarda con un color que no llega y con un hex roto; la insignia «IA», la estrella y los avisos sobre `errorBg`; la cabecera del asistente como única excepción al 4,5:1 |
| RF-TEST-13 | `specialty_test_accesibilidad_test.dart` | Las etiquetas, estados y regiones vivas; el foco al cambiar de pregunta, al volver y al abrir el resultado; lo excluido del árbol; «Siguiente» con lector de pantalla; sin desborde con 1,0, 1,3 y 2,0; sin animaciones con menos movimiento; los blancos de 48 |
| RF-TEST-14 | `perfil_especialidad_antigua_test.dart`, `specialty_test_logic_test.dart` | El chip vacío que ya no aparece; «Sin especialización seleccionada» con solo ids antiguos; el catálogo fallido con «Reintentar»; la hoja y el asistente que no mandan un id antiguo; `getEspecialidadName` igual; la malla sin cambios |

## Cambios en otras specs

- `specs/features/academic-profile/academic-profile.spec.md`. La enmienda del asistente, que
  queda en carrera, test y selección manual, y del Perfil, con la tarjeta del test y el caso del
  id antiguo. El dueño la aprueba con esta spec el 2026-09-25.
- `docs/images/UI`. `ConfiguracionCarrera.png` queda superada por el asistente nuevo, y
  `Perfil.png`, por la tarjeta del test. `AGENTS.md` pide respetar esas maquetas salvo un cambio
  aprobado, y el dueño aprueba ese cambio con esta spec el 2026-09-25. Las imágenes no se
  tocan.
- `docs/specs/api-contracts.md`. La sección «Specialty Test» con las tres rutas y, en «Academic
  Profile», el filtro del listado, el `404` por especialidad inactiva y los campos que la app
  lee del listado.
- `docs/specs/feature-index.md`. La fila 21 de esta funcionalidad y la enmienda en la fila de
  Academic Profile. La fila 20 la toma el truco del 67 en su rama (`feat/six-seven-fe`, sin
  mergear).

## Qué NO entra

- **Calcular algo del resultado en la app.** Ni afinidades, ni desempates, ni el orden, ni la
  explicación de cada puesto (decisión 2 y decisión abierta 3).
- **Guardar respuestas en disco o en el servidor.** Solo viven en memoria (decisión 5).
- **Borrar el último resultado desde la app.** Rehacer el test lo reemplaza.
- **Elegir la principal desde la tarjeta del Perfil.** Se elige en el resultado o con «Editar»
  (decisión abierta 16).
- **El test para un docente o para otra carrera.** El docente no lo ve y otra carrera recibe el
  `404` del servidor.
- **Cambiar la malla, el login o `/auth/me`.** Siguen como están (RF-TEST-14).
- **El saludo del asistente.** «Hola, <nombre>» toma hoy el `firstName` que sale de partir
  «APELLIDOS NOMBRES» (`user_model.dart:54-66`) y queda para otro cambio.
- **El chatbot.** No lee el resultado (RS-BE-47) y no cambia.
- **El truco del 67.** Tiene su propia spec.
- **Ilustraciones por tarea.** Salen los 48 SVG de la primera versión de la spec, y cada tarea
  lleva un ícono de Lucide (decisión 8 y RF-TEST-5).
- **Dependencias o assets nuevos.** Los íconos de las tareas salen de `lucide_icons_flutter`
  3.1.15, que ya está en `pubspec.yaml`, y el test no suma imágenes al APK.

## Decisiones abiertas

Cada punto nace como decisión abierta, con la opción que la spec adopta por defecto. El dueño
los aprueba todos el 2026-09-25 en esa opción, salvo el 2 y el 14, que cambian con las
decisiones 8 y 9, y el 20, que queda sin uso. Los que dicen «hallazgo» son huecos del contrato
del backend frente a la maqueta. La numeración se conserva, porque el texto de arriba y la spec
del backend citan cada punto por su número.

1. **Colores.** Aprobada. La app usa los colores del contenido que manda el servidor (por
   ejemplo `#1E3A8A` y `#A5C0F7` para Software), que llegan al contraste pedido, y no los de la
   maqueta (`#5B4BDB` y `#A69DFF`). Resuelve así la decisión abierta 16 del backend. Un cambio
   posterior a los de la maqueta va en el contenido con una versión nueva, sin tocar la app.
2. **Ilustraciones (hallazgo).** Cambiada por el dueño (decisión 8). La maqueta pide una
   ilustración por tarea, y el contrato de la `2026-09-25.3` manda solo su descripción. En
   lugar de los 48 SVG que propone la primera versión de esta spec, cada tarea lleva desde la
   `2026-09-25.4` el nombre de un ícono de Lucide, que la app pinta con el mapa cerrado de
   RF-TEST-5 y con `LucideIcons.sparkles` para un nombre fuera del mapa. Como el ícono viaja en
   el contenido, una versión nueva cambia los íconos sin otro APK mientras use nombres del
   mapa.
3. **Explicación de cada puesto (hallazgo).** Aprobada. La maqueta pone bajo cada especialidad
   «Perdió en el desempate», «Le diste "Un poco"» o «Ganó 1 de 5 duelos». El ranking del
   contrato trae solo clave, id, nombre y afinidad, así que la fila muestra solo la afinidad.
   Para tenerla, el backend tendría que mandarla por especialidad, porque calcularla en la app
   repite reglas del servidor y en el Perfil no hay respuestas para calcularla.
4. **Nombre corto (hallazgo).** Aprobada. La maqueta dice «Elegir Software como principal» y «7
   electivos de Software». El contrato no trae nombres cortos de especialidad, así que el botón
   dice «Elegir como principal», como la decisión 4, y la fila dice «7 electivos».
5. **Motivo largo (hallazgo).** Aprobada. Los motivos de las plantillas miden de 190 a 541
   caracteres en los ocho ejemplos del contenido `2026-09-25.4`, y el de Cohere hasta 500,
   frente a los 104 de la maqueta. Para cumplir «sin scroll», el motivo se corta en cuatro
   líneas con «Leer más».
6. **Líneas de Ulises en el resultado (hallazgo).** Aprobada. El contrato manda `intro`,
   `headline`, `tiebreakOutcome`, `closing` y `retake`, y la maqueta tiene lugar para una
   burbuja. La burbuja lleva `headline` y `tiebreakOutcome`, y `intro`, `closing` y `retake` no
   se muestran. `headline` va siempre, porque con afinidad menor que 50 el servidor manda ahí la
   línea `low` (decisión abierta 27), que dice algo distinto de la tarjeta. Pintarla siempre
   evita que la app calcule el corte de 50. `headline` ocupa el lugar de la línea de la maqueta
   («Lo tuyo es esto»), que dice lo mismo que `winner`. Las alternativas son sumar `intro`
   delante, que alarga la burbuja, o una segunda burbuja con `closing`, que obliga a desplazar
   en el iPhone SE.
7. **«Empezar el test» o «Vamos».** Aprobada. La decisión 4 nombra el botón «Empezar el test» y
   el contenido aprobado trae `startButton: "Vamos"`. La spec usa «Empezar el test».
8. **Textos de la maqueta.** Aprobada. Las líneas de Ulises de la maqueta («¡Craa! Hola, Valeria
   👋» o «¡Anotado! Va otra 👇»), su enunciado «Primera práctica y te dejan escoger» y sus
   tareas son ilustrativos. Mandan los del contenido, sin el nombre del alumno.
9. **Pausa solo en memoria.** Aprobada. Cerrar la app o la sesión pierde el avance. Guardarlo en
   disco choca con la regla de `AGENTS.md` sobre `shared_preferences` y con la decisión 5, que
   no guarda respuestas.
10. **Corazón que guarda enseguida.** Aprobada. En el asistente, el primer corazón marca la
    configuración como completa. La alternativa, guardar los corazones solo al salir del
    resultado, pierde lo marcado si el alumno cierra la app.
11. **Empate.** Aprobada. «Elegir como principal» abre una hoja con las dos ganadoras, y la que
    no se elige pasa a interés, porque en el resultado no tiene corazón. La alternativa es un
    corazón junto a cada nombre de la tarjeta del empate, que la maqueta no tiene.
12. **Atrás y cierre en el resultado.** Aprobada. El atrás del sistema no hace nada en el
    asistente y en el Perfil equivale a «Decidir después». Si el alumno cierra la app en el
    resultado del asistente sin tocar nada, vuelve al asistente y hace el test desde cero,
    aunque el servidor ya tiene guardado el resultado, porque marcar la configuración como
    completa sin una acción suya le quitaría la selección manual. La alternativa es que la
    bienvenida del asistente ofrezca el último resultado guardado.
13. **Héroe de la bienvenida en oscuro.** Aprobada. La maqueta lo muestra solo en claro. La spec
    lo deja naranja en los dos temas, con la tinta a 6,45:1.
14. **Cabecera del asistente.** Cambiada por el dueño (decisión 9). La cabecera lleva texto
    blanco sobre el naranja en claro, como el header de la app y el AppBar del chat, en lugar de
    la tinta oscura que propone la primera versión de la spec. Su contraste real en claro, de
    2,94:1, queda como riesgo conocido que el dueño acepta (RF-TEST-1 y RF-TEST-12).
15. **Plumas en claro.** Aprobada. Van en `#D45500` en lugar del `#FF6600` de la maqueta, que da
    2,81:1.
16. **Tarjeta del Perfil.** Aprobada. Sin maqueta, la spec la arma con las piezas del resultado y
    sin «Elegir como principal». El backend guarda el `specialtyId` pensando en elegir desde ahí
    (decisión abierta 8 del backend), así que el dueño puede pedir ese botón en otro cambio.
17. **Plazo de la evaluación.** Aprobada. 20 s, por los 5 s de Cohere y el arranque en frío.
18. **Lector de pantalla.** Aprobada. Sin avance solo y con «Siguiente».
19. **Desempate que no coincide.** Aprobada. Un reintento sin desempates y, si falla, el error.
20. **Sin uso.** Ya no aplica, porque la spec del backend describe la misma `2026-09-25.4` que
    esta spec (decisión 3). El número se conserva para no mover las referencias de la spec del
    backend.
21. **`[@test]` pendientes.** Aprobada. `docs/specs/spec-template.md` pide no enlazar pruebas que
    no existen. Como en la spec del backend, cada enlace lleva *(pendiente)* hasta que la prueba
    exista.
22. **Tarjeta de la n.º 1 en oscuro.** Aprobada. La pantalla 5 de la maqueta usa un degradado
    saturado (de `#4C41B8` a `#2D2484`, una versión oscurecida del color claro) con texto blanco
    y un aro al 35 %. La spec usa en cambio el `color.dark` del contenido al 18 % sobre `cardBg`,
    con el texto en `textPrimary` y el título en el color, como la tarjeta encendida del duelo,
    porque el contenido fija `color.dark` para el tema oscuro y esos colores son pasteles que no
    sostienen texto blanco (de 1,48:1 a 2,61:1). La alternativa fiel a la maqueta es un
    degradado que parte del `color.light` oscurecido un 20 % y baja a un tono más oscuro, con
    texto blanco, el aro de 1 px del `color.dark` al 35 % y la insignia «IA» como en claro. El
    blanco da ahí de 7,45:1 (`ti`) a 12,92:1 (`vj`) con los cuatro colores del contenido, así
    que las dos opciones cumplen el contraste.
23. **Principal anterior.** Aprobada. Si el alumno ya tiene una principal y elige otra desde el
    resultado, la anterior pasa a interés, así que no sale de su selección sin que él lo decida.
    La estrella «Tu principal» de su fila no tiene acción. La alternativa es un diálogo que
    confirma el cambio antes del `PUT` y deja elegir si la anterior queda como interés. Ninguna
    de las dos está en `decisiones.md`, y el dueño aprueba la primera con la spec.
24. **Plazo de los guardados.** Aprobada. Los `PUT` del resultado vencen a los 15 s, como los
    demás plazos del test. Al vencer, los corazones vuelven al último estado confirmado, el
    asistente no termina y el aviso dice «No se pudo confirmar el guardado…», porque el guardado
    puede estar hecho en el servidor. El plazo va como parámetro opcional de `completeSetup`,
    así que la hoja «Editar» del Perfil y la selección manual siguen sin plazo. La alternativa
    es ponérselo a todos los llamadores.
25. **Test en pausa y versión nueva.** Aprobada. Al seguir un test en pausa, la app usa la copia
    del contenido con la que arranca y manda su versión, que el servidor acepta mientras esté en
    su registro (RS-BE-37 y decisión abierta 11 del backend). Solo una versión retirada da el
    `409` y obliga a empezar de nuevo. La alternativa, descartar el avance ante cualquier versión
    nueva, hace empezar de nuevo a quien el backend dejaría terminar.
26. **Selecciones antiguas al guardar.** Aprobada. Como la app manda solo ids oficiales y el
    `PUT` reemplaza la selección entera, el primer guardado de un alumno con un id antiguo lo
    saca de su selección. La decisión 6 no lo pide, porque solo pide mostrar y elegir lo oficial
    sin tocar los datos de especialidades. Según la comprobación del 2026-09-25, hoy no afecta a
    nadie. La alternativa, conservar el id antiguo, choca con BR-AP-07, que responde
    `404 SPECIALTY_NOT_FOUND` a una especialidad inactiva.
27. **Las tres dudas del revisor que el dueño no marca una por una (decisión 3).** Aprobada. La
    spec las adopta con la opción recomendada, como la decisión abierta 1 del backend. La línea
    `low` de Ulises sale cuando la afinidad de la ganadora es menor que 50, el mismo corte de la
    plantilla `low` del motivo. La línea `second` de Ulises no se usa, porque el ranking del
    resultado siempre muestra el segundo lugar y la plantilla `second` del motivo lo nombra
    cuando su afinidad llega a 50. La pregunta 10 nombra el Metropolitano, como ya lo hace la
    `2026-09-25.4`. La app no depende de ninguna de las tres, porque pinta `headline` tal cual
    llega (RF-TEST-8) y el contrato no manda la línea `second`. Un cambio posterior de alguna
    toca la lógica de RS-BE-42 o la pregunta 10 en una versión nueva del contenido, sin tocar
    la app.
28. **Empate con afinidad menor que 50.** Aprobada. El titular de Ulises es la línea `tie` y no
    la `low`, igual que el motivo, que con empate usa solo la plantilla `tie`. Es la decisión
    abierta 3 del backend, cuyo cálculo exacto con respuestas al azar da el caso en el 2,8 % de
    los tests. La app pinta el titular tal cual llega (RF-TEST-8), así que un cambio posterior a
    la `low` no la toca.

## Verificación

- `dart format` sobre los archivos Dart que se crean o cambian.
- `flutter analyze --no-pub`.
- `flutter test --no-pub` con la suite completa, porque cambian `main.dart`, `auth_service.dart` y
  `perfil.dart`, que usan otras funcionalidades. Incluye `test/HU36_jeff`,
  `test/HU01_jeff/login_navigation_paths_test.dart`, `test/HU19_jeff` y
  `test/HU34_jeff/record_card_test.dart`, que monta el Perfil sin `SpecialtyTestService` y pasa
  sin cambios gracias a la guarda de RF-TEST-10.
- `TZ=UTC flutter test --no-pub test/HU36_jeff`, para que la fecha de la tarjeta del Perfil no
  dependa de la zona del equipo.
- La app no se publica antes de que el backend tenga desplegadas las tres rutas y aplicada la
  migración `0014`, porque cada push a `main` publica el APK (`.github/workflows/build-apk.yml`).
  El dueño aprueba la `0014` con las specs, y aplicarla en producción pide además, en el
  momento del despliegue, el respaldo y su permiso explícito, como con la `0012` y la `0013`.
- Un recorrido contra el backend desplegado con una cuenta de prueba, que termine una vez sin
  desempate y otra con dos, elija una principal, marque un corazón, rehaga el test desde el
  Perfil y vea ahí el último resultado.
- Una revisión manual en un iPhone SE, en claro y en oscuro, del asistente, las 14 preguntas, un
  desempate, el resultado y la tarjeta del Perfil, repetida con VoiceOver, con el texto más
  grande y con reducir movimiento.

## Enmienda de la bienvenida con Ulises (2026-09-25, aprobada el 2026-09-26)

Nace con `specs/features/bienvenida/bienvenida.spec.md` (RF-BIEN-10, RF-BIEN-12, RF-BIEN-16 y
RF-BIEN-21, con las decisiones B-10, B-13, B-14, B-15 y B-34), y el dueño la aprueba con ella el
2026-09-26, con la decisión B-10 en la opción que elige ese día junto con S-29 del splash. Cambia
los puntos de esta lista, y el resto de la spec sigue igual. La implementación del test ya está en
`main` desde `87403a1`, así que la enmienda toca código ya escrito, como el controlador del test y
sus vistas.

- **RF-TEST-1.** Suma un origen `bienvenida`. El alumno que crea su cuenta en la conversación, y
  el que tiene cuenta y todavía no elige su especialidad, hacen el test en ella, sin la ruta
  `/test-especialidad`, sin el paso de carrera y sin `/setup-carrera` (decisión B-10 y RF-BIEN-21
  de la bienvenida). Ni el arranque ni la bienvenida llevan al asistente, que queda sin llegadas y
  sigue en el código hasta un cambio aparte. En «Destino tras el login», `postLoginRoute` sigue
  igual y sigue dando `/setup-carrera` para ese alumno, pero la intro y la bienvenida lo traducen
  en el test de la conversación (RF-SPL-12 del splash). El Perfil sigue abriendo la ruta con
  `origen: perfil`. Con origen `bienvenida`, `SpecialtyTestBinding` no crea el controlador del
  test. Lo crea la bienvenida al empezar T0, sin `Get.put`, y lo cierra ella al pasar al horario,
  al reiniciarse, también tras un 401, y en el `dispose` de su página. Las reglas que viven en ese
  controlador, una sola evaluación en vuelo, el descarte del paso tras un atrás desde la espera y
  los guardados de uno en uno, no cambian (decisión B-34).
- **RF-TEST-2.** Con origen `bienvenida`, el contenido se pide una vez en T0 y no hay precarga.
  Las respuestas siguen solo en memoria. Una evaluación o un `PUT` que responde después del cierre
  del controlador se descarta sin tocar la pantalla, y la guarda por dueño y el `clear()` de
  `logout()` siguen igual.
- **RF-TEST-3.** Con origen `bienvenida` no hay pantalla de bienvenida del test. Su papel lo toma
  T0, con «¿Empezamos tu test de especialidad? Son T preguntas cortas.», «Empezar el test» y
  «Saltar y elegir por mi cuenta», y sus estados de carga, error y no disponible pasan a burbujas
  de Ulises (RF-BIEN-10). No hay «Seguir el test» ni «Empezar de nuevo», porque no hay pausa.
- **RF-TEST-4.** Con origen `bienvenida` no hay barra de 52 px, plumas, historial plegado ni
  pausa. La franja con el sello hace de cabecera, el contador va en el rótulo del compositor,
  «Pregunta anterior» es un enlace del compositor y la conversación entera es el historial. Las
  reglas de las líneas de Ulises, del sello de bloque y del atrás no cambian.
- **RF-TEST-5 y RF-TEST-6.** El duelo y la escala se dibujan también en el compositor, con las
  tarjetas compactas de la maqueta de la bienvenida (decisión B-13) y la tarea de la escala en la
  burbuja de Ulises.
- **RF-TEST-7.** Con origen `bienvenida`, la espera no tiene «la barra y las plumas llenas»,
  porque no hay barra. Es la burbuja con `ulises.loading` y su indicador, con el compositor vacío.
- **RF-TEST-8.** Con origen `bienvenida`, el resultado va dentro de la conversación, que desplaza,
  y la regla «sin scroll» no aplica (decisión B-15). El atrás del sistema no hace nada, como en el
  asistente. El confeti se dibuja bajo la franja del sello.
- **RF-TEST-9.** Con origen `bienvenida`, «Elegir como principal» y «Decidir después» terminan con
  la despedida y el paso al horario de RF-BIEN-11, en lugar de `Get.offAllNamed('/home')`.
- **RF-TEST-11.** Con origen `bienvenida`, los textos de la tabla son burbujas de Ulises, y la fila
  del 401 sigue RF-BIEN-12, porque en `/login` el interceptor no navega.
- **RF-TEST-13.** Con origen `bienvenida`, la burbuja de Ulises no es región viva y el foco del
  lector pasa a la primera burbuja nueva (RF-BIEN-16).
- **«Textos nuevos» y «Pantallas y archivos».** Suman el origen `bienvenida` y los widgets que se
  dibujan en el compositor.
- **Targets.** No cambian, porque `lib/pages/specialty_test/**` ya está en ellos. La spec de la
  bienvenida también lo tiene en los suyos, porque es ella la que hace estos cambios.
- **Test Links.** Las pruebas de la enmienda son
  `test/bienvenida/bienvenida_test_especialidad_test.dart` y
  `test/bienvenida/bienvenida_sin_especialidad_test.dart`, y las de
  `test/HU36_jeff/` siguen en verde.
