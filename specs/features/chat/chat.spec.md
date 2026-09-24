---
name: Chat de sección (HU23)
description: Chat en vivo por sección para alumnos y docentes sobre Firebase RTDB, con la pestaña Chats del alumno, su bandeja de cursos, el acceso desde la ficha del curso y la conversación con la identidad de la app
targets:
  - ../../../lib/pages/chat/chat_page.dart
  - ../../../lib/pages/chat/chats_inbox_page.dart
  - ../../../lib/pages/chat/chat_linea_tiempo.dart
  - ../../../lib/pages/chat/curso_avatar.dart
  - ../../../lib/services/chat_repository.dart
  - ../../../lib/models/message.dart
  - ../../../lib/pages/home/home_shell_config.dart
  - ../../../lib/pages/home/home_page.dart
  - ../../../lib/components/footer/app_footer.dart
  - ../../../lib/components/header/app_header.dart
  - ../../../lib/pages/horario/horario.dart
  - ../../../lib/pages/horario/horario_controller.dart
  - ../../../lib/pages/horario/horario_list_view.dart
  - ../../../lib/pages/descripcion_cursos/descrip_cursos.dart
  - ../../../lib/pages/teacher/teacher_sections_page.dart
  - ../../../lib/configs/themes.dart
  - ../../../test/HU23_jeff/**
  - ../../../test/HU35_jeff/time_blocks_form_test.dart
  - ../../../test/HU35_jeff/time_blocks_lista_test.dart
---

# Chat de sección

> Estado: **diseñada con el dueño el 2026-09-23 y aprobada por él ese mismo día**, con los
> puntos que la spec fija por su cuenta y el AppBar en blanco sobre `#FF6600` (ver «Decisiones»).
> Queda **implementada el 2026-09-23; falta la revisión manual en un iPhone SE** que pide
> «Verificación», en claro y en oscuro, del footer del delegado, de la bandeja y de la
> conversación.
> Cubre la fase 1 de los chats de curso. Documenta el chat que ya existe y que se conserva
> (RF-CHAT-1 a RF-CHAT-4) y suma la pestaña Chats del alumno, su bandeja, el botón de la
> ficha del curso, el rediseño de la conversación y el acceso del docente (RF-CHAT-5 a
> RF-CHAT-13).
> Hasta hoy el chat no tenía spec de frontend. La contraparte de backend es
> `ULima_Backend_IS2/specs/features/chat/chat.spec.md` (R-CHAT-1 a R-CHAT-4), y esta fase no
> la cambia.
> `chat_repository.dart` y `message.dart` figuran en los targets porque esta spec fija su
> comportamiento, aunque la fase 1 no los modifica. `horario_list_view.dart` figura porque la
> fase 1 lo borra. Las pruebas de `test/HU23_jeff/` figuran porque la fase 1 las escribe o
> las ajusta, y las dos de HU35 porque les quita una prueba a cada una («Pruebas existentes
> que cambian»).
> Cada `[@test]` apunta a un archivo que existe y que tiene al menos un caso del requisito que
> lo enlaza.
> Después de la aprobación, la revisión de la Tarea 2 suma tres aclaraciones. Son la base de
> las referencias por línea («Contexto»), el toque del botón enviar deshabilitado (RF-CHAT-12 y
> «Pruebas existentes que cambian») y la corrida con `TZ=UTC` (RF-CHAT-11 y «Verificación»).
> La revisión de la Tarea 5 suma una cuarta, que acota en «Verificación» lo que prueba
> `chats_pestana_test`, y reescribe la oración anterior sobre los `[@test]`, que en la versión
> aprobada nombra pruebas por escribir. Las cuatro aclaraciones quedan aceptadas el 2026-09-23
> y no cambian ninguna decisión del dueño. La oración reescrita tampoco cambia ninguna, porque
> solo dice que las pruebas ya existen.
> Los ajustes de cierre de la fase 1, del mismo 2026-09-23, fijan la etiqueta activa en 13 px
> cuando el footer tiene seis pestañas, que decide el dueño (RF-CHAT-5). Suman también el
> espacio para la burbuja de Ulises al final de la bandeja y la sección en la etiqueta accesible
> de cada tarjeta (RF-CHAT-6 y RF-CHAT-13), el contraste del código y de la insignia de rol en
> la tarjeta del docente (RF-CHAT-13), el token `iconoNaranja` (RF-CHAT-8), el enviar
> deshabilitado sin respuesta de toque (RF-CHAT-12) y la excepción de formato de
> «Verificación».
> Ajustada el 2026-09-23: cada participante borra sus propios mensajes; aprobado por el dueño
> ese día. El ajuste reescribe RF-CHAT-4, suma dos textos a «Textos nuevos» y consume el
> cambio del backend del mismo día (R-CHAT-4 de su spec). Para el borrado deja atrás la
> moderación sin cambios de la decisión 11 y el backend sin cambios de la decisión 12
> («Decisiones»). Es también el único punto en que la app modifica `message.dart`, que pasa a
> leer `deletedByUid`, y `chat_repository.dart`, solo en el comentario de `deleteMessage`.
> El retoque final del mismo día cambia el cuerpo del diálogo de borrado, con sus dos textos
> en «Textos nuevos» (RF-CHAT-4), y la línea de la sección en la tarjeta del docente, que pasa
> a «Sección N» o «Sin sección» como en la bandeja (RF-CHAT-13).

## User Stories

- Como alumno, quiero encontrar el chat de cada curso en una pestaña propia, sin buscarlo
  dentro del horario.
- Como alumno, quiero abrir el chat de un curso desde su ficha.
- Como integrante de una sección, quiero leer la conversación con claridad y saber quién
  escribe y en qué día.
- Como profesor, quiero seguir entrando al chat desde mis secciones y moderar sus mensajes.
- Como integrante de una sección, quiero borrar mis propios mensajes.

## Contexto

El diagnóstico del 2026-09-23, hecho sobre `main` (c18faa7), es lo que motiva la fase 1.

Las referencias `archivo:línea` de esta spec apuntan a ese commit, también las de RF-CHAT-1 a
RF-CHAT-4, que describen lo que se conserva, y las de las pruebas. La fase 1 mueve esas
líneas y la spec no las sigue, así que cada referencia se lee en `c18faa7`, por ejemplo con
`git show c18faa7:lib/pages/chat/chat_page.dart`.

- El único acceso del alumno es un ícono de lista sin texto en el header de la pestaña
  Horario (`app_header.dart:95-115`). Queda a tres toques y desaparece en horizontal, porque
  ahí el header se oculta (`home_page.dart:107-108`).
- La lista «Mis chats» (`horario_list_view.dart`) parece una lista de cursos. Lleva un ícono
  de libro (`:189-193`), fuerza el nombre a mayúsculas (`:110-111`), no muestra ningún
  mensaje y pinta el hex crudo del curso (`:106-109`), mientras la grilla usa
  `colorPorCurso` (`horario.dart:507-510`).
- Tocar un curso en la grilla abre la ficha (`horario.dart:678-682`), con Anuncios,
  Asesorías y Contactos, y ninguna entrada al chat.
- `ChatPage` usa la paleta de WhatsApp (`chat_page.dart:349` y `:641-644`) y un AppBar
  `#FF5722` fijo (`:344`), distinto del naranja de marca `#FF6600` (`themes.dart:10`), que
  sigue brillante en oscuro.
- `showSender: true` (`chat_page.dart:460`) repite el nombre en cada burbuja, también en las
  propias.
- No hay separadores de día. `_formatTime` solo da `HH:mm` (`chat_page.dart:249-253`).
- En oscuro, los nombres y las insignias de moderador quedan cerca de 2:1 de contraste
  (`chat_page.dart:596-631` y `:713-740`).

## Requisitos

### RF-CHAT-1 — Entrar al chat de una sección (se conserva)

`ChatPage` pide la sesión de chat con `POST /chat/token` y el cuerpo `{sectionId}`
(`chat_repository.dart:66-91`). El backend responde con un custom token de Firebase y la
sesión `{uid, displayName, role, roleLabel, isModerator, weight}`
(`chat_repository.dart:9-42`). La app entra a Firebase con ese token solo cuando el usuario
de Firebase actual es otro (`chat_repository.dart:81-84`).

- La espera tiene un tope de 8 s (`chat_page.dart:46-48`) y, mientras dura, la pantalla
  muestra un indicador de carga.
- Si el token falla o se vence el tope, la pantalla muestra «No se pudo conectar al chat.» y
  «Solo los miembros de esta sección pueden entrar al chat.» (`chat_page.dart:255-295`),
  junto con el aviso emergente «No se pudo conectar al chat» (`chat_page.dart:55-61`). Sin
  sesión no aparece la barra de escritura.
- Quién entra y con qué rol lo decide el backend (R-CHAT-1 y R-CHAT-2 de su spec). La app
  nunca elige su rol ni su nombre.

`[@test] ../../../test/HU23_jeff/chat_page_test.dart`

### RF-CHAT-2 — Mensajes en vivo (se conserva)

- La conversación escucha `sections/{sectionId}/messages` en Firebase RTDB, ordenada por
  clave y limitada a los últimos 80 mensajes, y los ordena por fecha de creación
  (`chat_repository.dart:94-113`).
- `ChatMessage.fromMap` acepta el esquema nuevo (`body`, `createdAt`, `senderRole`) y el
  antiguo (`text`, `timestamp`), y deriva la etiqueta, el peso y el flag de moderador del rol
  cuando no vienen (`message.dart:43-72` y `:113-147`).
- Cada lista nueva lleva la vista al último mensaje (`chat_page.dart:237-247` y `:439-441`).
- Sin mensajes, la pantalla muestra «Chat privado de la sección» y «Solo los miembros de esta
  sección pueden leer y escribir. Sé el primero en saludar 👋» (`chat_page.dart:381-437`),
  con la barra de escritura disponible.
- Si el stream falla, la conversación muestra el error en lugar de la lista
  (`chat_page.dart:367-378`).

`[@test] ../../../test/HU23_jeff/chat_message_test.dart`
`[@test] ../../../test/HU23_jeff/chat_page_test.dart`

### RF-CHAT-3 — Enviar texto y carnet (se conserva)

- **Texto.** La app recorta el texto y no envía nada si queda vacío
  (`chat_page.dart:79-80`). Al enviar, el campo se limpia enseguida; si el envío falla, el
  texto vuelve al campo y aparece «No se pudo enviar el mensaje» (`chat_page.dart:82-95`).
  Sin sesión, el aviso es «Chat no disponible» con «Vuelve a intentar en unos segundos.»
  (`chat_page.dart:68-77`).
- Cada mensaje se crea con `push()` en RTDB con el remitente, su rol, su etiqueta, el flag
  de moderador, el peso, el cuerpo y el `createdAt` del servidor
  (`chat_repository.dart:116-143`).
- **Carnet.** «Enviar carnet» primero pide el carnet propio para confirmar que está visible y
  después publica un mensaje cuyo cuerpo es `__ULIMA_NETWORKING_CARD__:<uid>`
  (`chat_page.dart:98-132`, `chat_repository.dart:145-173`). Si el carnet está oculto
  (`NETWORKING_CARD_HIDDEN`), el aviso dice «Activa "Mostrar mi carnet" antes de enviarlo.».
- Un mensaje de carnet se pinta como burbuja especial, con «Envio su carnet de networking»
  junto a un recuadro con el ícono de credencial (`chat_page.dart:780-827`). Sus colores y
  su ícono los fija RF-CHAT-8. Tocarlo abre el carnet en un diálogo
  (`chat_page.dart:134-183`); si su dueño lo ocultó, el aviso dice «Este usuario oculto su
  carnet.». Los textos se conservan tal cual.

`[@test] ../../../test/HU23_jeff/chat_page_test.dart`

### RF-CHAT-4 — Borrar mensajes (ajustada el 2026-09-23)

En la versión aprobada de esta spec solo borra el profesor (`chat_page.dart:453-455`), y el
ajuste del 2026-09-23 trae a este requisito las decisiones que el dueño toma el mismo día.

- **Quién borra.** Todo participante, sea alumno, delegado, subdelegado, JP o profesor, borra
  sus propios mensajes, sin límite de tiempo. Un mensaje es propio si su `senderId` es el
  `uid` de la sesión, la misma comparación de RF-CHAT-9. El profesor titular, la sesión con
  rol `teacher`, borra además los de cualquiera. Nadie borra un mensaje ya borrado.
- **La acción.** Es un toque largo sobre la burbuja (`chat_page.dart:662-664`). Lo tiene el
  autor en sus mensajes no borrados, con cualquier rol, y la sesión `teacher` en cualquier
  mensaje no borrado. En un mensaje ajeno, el alumno, el delegado, el subdelegado y el JP no
  ven la acción. La autorización real es del backend, que compara el `senderId` guardado con
  el `uid` del participante y deja borrar cualquier mensaje solo al profesor titular
  (R-CHAT-4 de su spec).
- **Confirmación.** El toque largo abre el mismo diálogo «¿Eliminar mensaje?» con «Cancelar» y
  «Eliminar» (`chat_page.dart:194-221`), con su título y sus botones de siempre. Su cuerpo
  dice «Se eliminará para todos.» si el mensaje es propio, con cualquier rol, y «Se eliminará
  para todos y verán que lo eliminaste tú.» cuando el profesor titular borra el mensaje de
  otra persona. Lo propio se decide por `senderId`, no por el nombre, y ningún texto del
  diálogo lleva comillas rectas.
- **Borrado.** Al confirmar, la app llama a
  `DELETE /chat/sections/{sectionId}/messages/{messageId}` con el repositorio de siempre
  (`chat_repository.dart:180-187`). El backend marca el mensaje como borrado y el stream trae
  la lápida, con `deleted`, `deletedBy` (el nombre de quien borra), `deletedByUid`,
  `deletedByRole` y `deletedAt`. `ChatMessage` lee `deletedByUid` tal como llega, y queda
  nulo si no viene. Borrar un mensaje ya borrado responde 200 sin reescribir la lápida.
- **Lápida.** Va del lado de su remitente y sin su cuerpo (`chat_page.dart:829-889`), con los
  estilos de RF-CHAT-8 en sus tres variantes.
  - Si `deletedByUid` es el `senderId` del mensaje, el borrado es de su autor. El autor lee
    «Eliminaste este mensaje» y los demás, «Se eliminó este mensaje».
  - Si el borrado es de otra persona, el profesor titular, todos leen «Mensaje eliminado por
    <deletedBy>», y si no llega el nombre, «Mensaje eliminado por el profesor».
  - Si `deletedByUid` no llega o llega vacío, la lápida cuenta como borrada por otra persona.
- **Errores.** Un 403 (`CHAT_DELETE_FORBIDDEN`) muestra el aviso de error «No se pudo
  eliminar» con el texto del servidor, como «Solo puedes eliminar tus propios mensajes.».
  Cualquier otro fallo sigue con «Inténtalo de nuevo en unos segundos.»
  (`chat_page.dart:223-234`). Los dos avisos van en blanco sobre `errorBg` (RF-CHAT-8).

`[@test] ../../../test/HU23_jeff/chat_moderacion_test.dart`
`[@test] ../../../test/HU23_jeff/chat_page_test.dart`

### RF-CHAT-5 — La pestaña Chats del alumno

- El footer del alumno pasa a **Malla, Notas, Horario, Chats y Perfil**
  (`home_shell_config.dart:55-73`). Para un delegado, la pestaña Delegado sigue justo antes de
  Perfil (`home_shell_config.dart:61` y `:68-69`), así que su footer queda Malla, Notas,
  Horario, Chats, Delegado y Perfil.
- La pestaña se llama «Chats» y lleva un ícono de conversación de Lucide, el paquete que el
  footer ya usa (`LucideIcons.messagesSquare`).
- La app sigue abriendo en Malla (`home_page.dart:36`).
- Chats es vertical, como toda pestaña salvo Horario (BR-SHELL-F-00 de
  `specs/features/app-shell/app-shell.spec.md`).
- La pestaña muestra la bandeja de RF-CHAT-6. Ulises no aparece en ella, y su burbuja
  flotante sigue como hoy (`home_page.dart:102` y `:123`), también sobre esta pestaña.
- Las pestañas que el shell busca por su etiqueta («Horario» y «Asesorias»,
  `home_page.dart:42-43` y `:74-76`) se siguen encontrando igual con la pestaña nueva en
  medio.
- El footer sigue con `BottomNavigationBarType.fixed` (`app_footer.dart:27-51`). Con cinco
  pestañas o menos, la etiqueta activa va en 14 px y las demás en 12 px, como hoy. Con seis,
  que es el footer del delegado, la activa baja a 13 px y las demás siguen en 12, por
  decisión del dueño del 2026-09-23.
- Cada una de las seis pestañas recibe la sexta parte del ancho, 62,50 pt en el iPhone SE y
  60 dp en un Android de 360 dp. A 13 px «Delegado» mide 60,35 pt con SF, la fuente del
  iPhone, y 56,56 dp con Roboto, la de Android, así que en las dos pantallas las seis
  etiquetas se leen completas y sin desborde, con cualquiera de ellas activa y «Delegado»
  incluida. A 14 px no cabe, porque mide 64,84 pt con SF y 60,76 dp con Roboto.
- El footer del docente no cambia. Su entrada al chat es la pestaña Secciones (RF-CHAT-13).

`[@test] ../../../test/HU23_jeff/chats_pestana_test.dart`

### RF-CHAT-6 — La bandeja de chats

Una fila por cada sección matriculada, bajo el header de la app, sin subencabezado propio ni
botón de volver, porque es una pestaña. El fondo de la pestaña es el de las páginas de la
app, `MaterialTheme.pageBg`.

- **Datos.** Las filas salen de `HorarioController.uniqueEnrolledCourses`
  (`horario_controller.dart:701-728`), en el orden en que hoy las muestra «Mis chats». La
  bandeja no hace pedidos propios y solo lee lo que ya carga el controller.
- **Registro y recarga.** Al entrar a Chats, el shell hace lo mismo que al entrar a Horario
  (`home_page.dart:79-85`). Si `HorarioController` ya está registrado, llama a `reload()`;
  si no lo está, no llama a nada. La bandeja registra el controller al construirse con
  `Get.put(HorarioController())`, igual que el horario (`horario.dart:1081`), y en la
  primera entrada su `onInit` hace la carga (`horario_controller.dart:85-105`), sin un
  `reload()` aparte que la repita.
- **Cada fila** es una tarjeta con borde, como hoy (`horario_list_view.dart:173-179`), con
  fondo `cardBg`, borde `borderColor`, radio y relleno de 16 px y 10 px entre filas. De
  izquierda a derecha lleva
  - el círculo del curso, de 42 px, con sus iniciales (RF-CHAT-8), del color que le da la
    grilla, `colorPorCurso[idSeccion]` (`horario_controller.dart:671-699`). Siempre hay
    uno, porque `colorPorCurso` reparte la paleta entre las mismas secciones que lista
    `uniqueEnrolledCourses`;
  - el nombre del curso tal como llega, sin forzar mayúsculas, en `textPrimary`, de 15 px
    en negrita (w800) y hasta dos líneas con puntos suspensivos, como hoy
    (`horario_list_view.dart:200-209`);
  - debajo, «Sección N» con el código de la sección, en `textSecondary`, de 12 px en
    negrita (w800). Si el código llega nulo o vacío, también cuando solo trae espacios, la
    línea dice solo «Sin sección». Hoy ese caso muestra «Sección Sin sección», porque la
    lista deja pasar `''` (`horario_list_view.dart:112-113`);
  - un chevron, `LucideIcons.chevronRight` de 20 px en `textMuted`.
- **Toque.** La fila entera es un `InkWell` con ripple, dentro de un `Material` con el color
  y la forma de la tarjeta para que el ripple se vea, y abre `ChatPage` de esa sección con
  su nombre, su código y su color. Su semántica es la de un botón con la etiqueta «Abrir el
  chat de <curso>, sección <N>», o «Abrir el chat de <curso>, sin sección» cuando la fila
  dice «Sin sección», para que dos secciones del mismo curso se distingan. Su alto es de al
  menos 48 px.
- **Espacio para Ulises.** La lista deja 96 px de relleno al final. La burbuja de Ulises mide
  60 × 60 y el shell la pone encima de la pestaña, abajo a la izquierda y con 12 px de margen
  (`chatbot_bubble.dart:16`, `:31` y `:76`), así que con la lista al final la última fila
  queda por encima de la burbuja.
- **Contraste.** Sobre `cardBg`, el nombre da 17,85:1 en claro y 14,22:1 en oscuro,
  «Sección N» da 10,35:1 y 6,44:1, y el chevron 4,76:1 y 3,86:1. Así el texto llega a 4,5:1
  y el chevron a 3:1 en los dos temas. «Sección N» deja el color del curso que usa hoy
  (`horario_list_view.dart:212-219`).
- **Estados.** Mientras la primera carga de secciones no termina, la bandeja muestra un
  indicador y no el estado vacío; para eso `HorarioController` expone si esa carga ya
  terminó. Si terminó sin secciones, muestra el estado vacío de hoy, «No hay cursos
  matriculados.» (`horario_list_view.dart:232-263`).
- **Fase 2, fuera de esta spec.** La fila no muestra último mensaje, hora ni no leídos.
  Mostrarlos exige leer cada chat sin entrar, y eso pide un cambio del backend por las reglas
  de Firebase.

`[@test] ../../../test/HU23_jeff/chats_bandeja_test.dart`

### RF-CHAT-7 — «Chat del curso» en la ficha

- La ficha del curso (`DescripCursosPage`) solo la abre el alumno, desde la grilla
  (`horario.dart:678-682`). El docente, al tocar una clase, ve otra hoja
  (`horario.dart:664-677`).
- La franja de la sección (`descrip_cursos.dart:70-90`), que hoy solo dice «Sección: N»
  centrado (`descrip_cursos.dart:80-87`), pasa a ser una fila. El texto «Sección: N» se
  corre a la izquierda, sin cambiar, y a la derecha va un botón visible con
  `LucideIcons.messagesSquare` y el texto «Chat del curso». La franja crece lo justo para
  un blanco táctil de 48 px y el resto de la ficha no se mueve de orden.
- El botón es de contorno, con el fondo y el borde de tarjeta (`MaterialTheme.cardBg` y
  `borderColor`), el texto en `textPrimary` y el ícono en naranja de marca, `primaryDark` en
  claro y `primaryColor` en oscuro, como el botón de «Mis bloques»
  (`horario.dart:1115-1121`). El texto llega a 4,5:1 y el ícono a 3:1 contra el botón en los
  dos temas.
- **Color del curso.** `DescripCursosPage` hoy solo recibe `idSeccion`
  (`descrip_cursos.dart:14-19`) y `Seccion` no trae color, así que la ficha suma un
  parámetro opcional con el color del curso. La grilla se lo pasa al abrirla
  (`horario.dart:680`) con `controller.colorPorCurso[idSeccion]`, el mismo color que usa la
  bandeja. Si llega nulo, `ChatPage` usa el respaldo de RF-CHAT-8.
- El botón abre `ChatPage` de esa sección con `seccion.curso`, `seccion.codigoSeccion` y ese
  color.
- Al volver del chat, la ficha sigue igual y en la misma pestaña (Anuncios, Asesorías o
  Contactos).

`[@test] ../../../test/HU23_jeff/chat_ficha_curso_test.dart`

### RF-CHAT-8 — La conversación con la identidad de la app

Rige para alumno y docente.

- **Parámetros.** `ChatPage` sigue pidiendo el id de la sección y el nombre del curso, y
  suma dos parámetros opcionales, `sectionCode` y `courseColor`. Si el color no llega, usa
  `courseAccentColor(int.tryParse(sectionId) ?? 0)` (`course_colors.dart:29-33`), el acento
  de las vistas del docente, porque esa función recibe un `int` y el id llega como `String`.
  Si el código llega nulo o vacío, el subtítulo dice «Sin sección», como la bandeja. El
  caso es real, porque `TeacherSectionOption.sectionCode` (`advising_models.dart:87`) y
  `Seccion.codigoSeccion` (`seccion_model.dart:67`) caen a `''`.
- **AppBar.** Toma el color del header de la app, `MaterialTheme.headerColor`
  (`themes.dart:21-26`), que es el naranja de marca `#FF6600` en claro y la superficie
  oscura `#1E1E24` en oscuro. A la izquierda del título va el círculo del curso, de 36 px
  como el avatar de hoy (`chat_page.dart:316-320`). El título es el nombre del curso tal
  como llega y el subtítulo es «Sección N» o «Sin sección». Salen el ícono de grupo, «Chat
  grupal» (`chat_page.dart:316-338`) y el `#FF5722` fijo (`chat_page.dart:344`). En oscuro,
  la flecha, el título y el subtítulo van en blanco, que da 16,58:1. En claro también van en
  blanco sobre `#FF6600`, como el header, por decisión del dueño («AppBar en el tema claro»).
- **Círculo del curso.** Es un solo widget para la bandeja y el AppBar. Sus iniciales salen
  de una función pura con esta regla.
  1. El nombre se recorta y se parte en palabras por los espacios.
  2. Se descartan los conectores (de, del, la, las, el, los, y, e, en, para, a, al), los
     números romanos del I al X, que son las palabras enteras que cumplen
     `^(I{1,3}|IV|VI{0,3}|IX|X)$`, y las palabras sin ninguna letra. Ninguna de las dos
     comparaciones distingue mayúsculas, porque el nombre llega a veces todo en mayúsculas
     (`chat_page_test.dart:92`).
  3. Las iniciales son la primera letra de las dos primeras palabras que quedan, en
     mayúscula y con su tilde. Si queda una sola palabra, la inicial es una sola letra.
  4. Si no queda ninguna, la inicial es la primera letra del nombre. Si el nombre llega
     vacío o sin letras, el círculo va sin texto, solo con el color.

  «INGENIERÍA DE SOFTWARE II» e «Ingeniería de Software II» dan «IS», «Cálculo I» da «C»,
  «Programación en C» da «PC», «Lenguaje C» da «LC», «Ética y Ciudadanía» da «ÉC», «II»
  da «I», «de la» da «D» y un nombre vacío no da ninguna. La «C» de un lenguaje se
  conserva, porque no es un romano del I al X. Todos estos casos entran en
  `chat_identidad_test`.
  Las iniciales van en blanco o en negro (`#000000`), el que dé más contraste con el color
  del curso. Con esa regla ningún color baja de 4,5:1, porque el peor caso posible da
  4,58:1.
- **Fondo.** Es el de las páginas de la app, `MaterialTheme.pageBg` (`themes.dart:55-56`), en
  lugar del beige `#ECE5DD` y del `#0B141A` (`chat_page.dart:349`).
- **Burbujas propias.** Van en un naranja suave de la marca, claro con texto oscuro en el
  tema claro y oscuro con texto claro en el tema oscuro, con un token nuevo del chat,
  `MaterialTheme.chatOwnBubbleBg`, que vale `#FFE8DC` en claro y `#3A2A22` en oscuro. Con
  `textPrimary` da 15,16:1 y 11,74:1. Son los mismos tonos del badge de especialidad de la
  malla (`specialtyBg`, `themes.dart:147-148`), pero el chat no reutiliza ese token, para
  que un cambio en la malla no le cambie el color. Reemplazan a `#DCF8C6` y `#005C4B`
  (`chat_page.dart:641-643`).
- **Burbujas ajenas.** Van en el color de tarjeta, `MaterialTheme.cardBg`, con el borde de
  tarjeta, `borderColor`, y el texto en `textPrimary`.
- **Burbuja de carnet.** Lleva el fondo y el borde de cualquier burbuja de su lado, sin el
  borde `#FFB16A` de hoy (`chat_page.dart:680-684`). Su recuadro (`chat_page.dart:792-804`)
  va en `primaryDark` en los dos temas, con `LucideIcons.idCard` en blanco pleno, que da
  4,12:1, el mismo ícono de «Enviar carnet» (RF-CHAT-12). Hoy lleva
  `Icons.contact_page_outlined` en blanco al 92 % sobre `#FF7A1A`, que no llega al 3:1 de
  un ícono (2,61:1 aun en blanco pleno). «Envio su carnet de networking» va en
  `textPrimary`, con 15,16:1 y 11,74:1 sobre la burbuja propia y 17,85:1 y 14,22:1 sobre la
  ajena.
- **Lápida.** Va sobre `tagBg` con borde `borderColor`, y su texto y su ícono van en
  `textSecondary` (9,45:1 y 5,60:1), en lugar de `black45` y `white54` sobre un velo
  translúcido (`chat_page.dart:847` y `:862-868`).
- **Error del stream.** Va en `textSecondary` sobre `pageBg` (9,90:1 y 6,99:1), en lugar de
  `grey[600]` (`chat_page.dart:374`), que da 4,40:1 en claro y 3,91:1 en oscuro.
- **Estados.** El estado vacío y el de chat no disponible (`chat_page.dart:255-295` y
  `:381-437`) pasan a la tarjeta de la app, `cardBg` con borde `borderColor`, en lugar de
  `#1F2C34`. El título va en `textPrimary` y el cuerpo en `textSecondary` (10,35:1 y
  6,44:1). Los candados (`Icons.lock_clock` e `Icons.lock_outline_rounded`) van en
  `primaryDark` en claro y en `primaryColor` en oscuro (4,12:1 y 5,65:1), como los íconos
  de RF-CHAT-7 y RF-CHAT-13, porque el `#FF6600` sobre blanco da 2,94:1. Sus textos no
  cambian.
- **Avisos y diálogo de borrado.** También entran en la regla de contraste. Los tres avisos
  de error (`chat_page.dart:55-61`, `:88-94` y `:227-233`) van en blanco sobre un token
  nuevo, `MaterialTheme.errorBg`, que vale `#B3261E` en los dos temas y da 6,54:1, en lugar
  de `Colors.redAccent` (3,19:1). Los demás avisos (`chat_page.dart:71`, `:101`, `:117`,
  `:126`, `:144` y `:153`) hoy usan el fondo translúcido por omisión de GetX y no tienen un
  contraste fijo, así que pasan a `cardBg` con borde `borderColor` y texto en
  `textPrimary` (17,85:1 y 14,22:1). El diálogo de borrado (`chat_page.dart:194-221`) va
  sobre `cardBg`, con el título, el cuerpo y «Cancelar» en `textPrimary`, y «Eliminar» en
  blanco sobre `errorBg`, en lugar de `Colors.red[600]` (4,23:1). «Cancelar» deja el naranja
  del tema, que da 2,94:1 sobre blanco. Los textos de los avisos no cambian, y el cuerpo del
  diálogo lo fija RF-CHAT-4.
- **Contraste.** Todo texto de `ChatPage` llega a 4,5:1 contra su fondo en los dos temas, y
  todo ícono que da información, a 3:1. Eso abarca el cuerpo, la hora, el nombre, la
  etiqueta de rol, el separador de día, la lápida, los estados vacío, no disponible y de
  error, la pista del campo, los avisos y el diálogo de borrado. La única excepción es el
  texto del AppBar en claro, blanco sobre `#FF6600` como el header («AppBar en el tema claro»). La hora deja
  `black45` y `white38` (`chat_page.dart:766` y `:821`) y pasa a `textSecondary`, que da
  5,31:1 o más sobre las burbujas de arriba.
- **Colores con nombre.** Los colores del chat viven como tokens de `MaterialTheme`
  (`themes.dart`), y `ChatPage` deja de llevar hex sueltos. Cuentan como hex sueltos los
  `Color(0x…)` y los colores fijos de `Colors`, como `Colors.redAccent`, `Colors.red[600]`,
  `Colors.grey[600]`, `Colors.white70` o `Colors.black45`. Solo quedan `Colors.white`,
  `Colors.black` (también con opacidad, en las sombras) y `Colors.transparent`. Los tokens
  nuevos son tres, `chatOwnBubbleBg`, `errorBg` e `iconoNaranja`, y el resto son los que la
  app ya tiene.
- **Naranja de un ícono.** `MaterialTheme.iconoNaranja` vale `primaryDark` en claro y
  `primaryColor` en oscuro, el naranja que lleva a 3:1 un ícono que da información (4,12:1 y
  5,65:1 sobre `cardBg`). Lo leen los candados de los estados y «Enviar carnet» (RF-CHAT-12),
  el botón de la ficha (RF-CHAT-7), la tarjeta del docente (RF-CHAT-13) y el botón de «Mis
  bloques» del horario (`horario.dart:1115-1121`), en lugar de repetir la condición del tema
  en cada archivo. Ninguno de ellos cambia de color.

`[@test] ../../../test/HU23_jeff/chat_identidad_test.dart`

### RF-CHAT-9 — Nombre del remitente e inicio de grupo

- **Inicio de grupo.** Un mensaje abre grupo si es el primero de la lista, si el anterior
  tiene otro `senderId`, si el anterior es de otro día en hora de Lima (RF-CHAT-11) o si el
  anterior es una lápida. La regla vale igual para propios y ajenos.
- **Margen.** Un mensaje que abre grupo lleva 8 px de margen arriba y los demás, 2 px, los
  dos valores que ya existen (`chat_page.dart:670-675`). El margen deja de depender de si el
  mensaje lleva nombre, así que un mensaje propio que sigue a uno ajeno va con 8 px. La
  lápida conserva sus 8 px fijos (`chat_page.dart:855-860`).
- **Nombre.** Lo lleva solo un mensaje ajeno que abre grupo. Un mensaje propio nunca lleva
  nombre, y una lápida tampoco, porque ya dice quién la borró.
- La decisión 6 pide el nombre solo cuando cambia el remitente o el día. Que una lápida
  también abra grupo, y con eso le dé nombre al mensaje ajeno que la sigue aunque sea del
  mismo remitente y del mismo día, lo agrega esta spec y lo confirma el dueño
  («Decisiones»). Si no lo confirma, esa condición sale del inicio de grupo, y ese mensaje
  va con 2 px y sin nombre.
- El remitente se compara por `senderId`, así que dos personas con el mismo nombre cuentan
  como remitentes distintos.
- La regla vale también para los mensajes de carnet.
- Si un mensaje abre grupo y si lleva nombre lo decide una función pura sobre el mensaje, el
  anterior y el `uid` de la sesión, probada aparte. `ChatPage` deja de pasar
  `showSender: true` fijo (`chat_page.dart:460`).
- El nombre va en `textPrimary` y en el mismo color para todos. El color por remitente
  (`chat_page.dart:596-610`) sale, porque en oscuro no llega a 4,5:1 (RF-CHAT-10).

`[@test] ../../../test/HU23_jeff/chat_linea_tiempo_test.dart`
`[@test] ../../../test/HU23_jeff/chat_page_test.dart`

### RF-CHAT-10 — Profesor, Jefe de Práctica y Delegado

- Un moderador (`isModerator`, `message.dart:59`) se distingue solo por su etiqueta de rol,
  `senderRoleLabel` («Profesor», «Jefe de Práctica», «Delegado» o «Subdelegado»), escrita
  junto al nombre como texto y sin fondo de color.
- Su burbuja es igual a la de cualquier otro mensaje ajeno, sin borde de color ni fondo
  teñido. Salen `_roleAccent` y `_bubbleColor` (`chat_page.dart:612-631`) y el borde de
  moderador (`chat_page.dart:685-691`).
- La etiqueta aparece solo donde aparece el nombre (RF-CHAT-9). Un mensaje propio de un
  moderador no la muestra, porque no lleva nombre.
- El nombre y la etiqueta llegan a 4,5:1 contra la burbuja en los dos temas. La etiqueta va
  en `textSecondary`, en negrita.
- El peso (`weight`) sigue en el modelo y no cambia nada en pantalla.

`[@test] ../../../test/HU23_jeff/chat_identidad_test.dart`
`[@test] ../../../test/HU23_jeff/chat_page_test.dart`

### RF-CHAT-11 — Separadores de día

- Antes del primer mensaje de cada día va un separador centrado con «Hoy», «Ayer» o el día
  completo, como «Lunes 21 de septiembre».
- El día de un mensaje es su `createdAt` en hora de Lima, UTC−5 todo el año, como
  `_nowInLima` (`horario_controller.dart:78-79`), y no en la zona del teléfono. «Hoy» y
  «Ayer» se comparan con la fecha actual en Lima.
- Los días (Lunes a Domingo, con mayúscula inicial) y los meses (enero a diciembre, en
  minúscula) salen de listas propias en español, sin agregar `intl`. La lista `_months` del
  horario (`horario_controller.dart:63-76`) no sirve tal cual, porque lleva los meses con
  mayúscula.
- La hora de cada mensaje (`HH:mm`) se calcula en la misma hora de Lima, para que un mensaje
  nunca quede bajo un día que no es el suyo. Hoy se calcula en la zona del teléfono
  (`chat_page.dart:249-253`).
- Una lápida cuenta como mensaje de su día.
- El separador va en `textSecondary` sobre el fondo de la página, con 4,5:1 o más en los dos
  temas.
- La etiqueta del día sale de una función pura con la fecha de hoy inyectable, probada
  aparte.
- Una prueba de widget comprueba en `ChatPage` que el separador se pinta antes del primer
  mensaje de cada día y que la hora sale en hora de Lima cerca de la medianoche UTC. Un
  `createdAt` de 2026-09-15 03:30 UTC se muestra como «22:30» bajo «Lunes 14 de
  septiembre», y uno de 2026-09-15 05:10 UTC, como «00:10» bajo «Martes 15 de septiembre».
  Son fechas pasadas, así que la prueba no depende del día en que corre. En una máquina en
  UTC−5 la hora local coincide con la de Lima, y ningún `createdAt` le permite a esa prueba
  distinguir una hora calculada con `.toLocal()`. Por eso «Verificación» corre también
  `test/HU23_jeff` con `TZ=UTC`.

`[@test] ../../../test/HU23_jeff/chat_linea_tiempo_test.dart`
`[@test] ../../../test/HU23_jeff/chat_page_test.dart`

### RF-CHAT-12 — La barra de escritura

- «Enviar carnet» cambia `Icons.contact_page_outlined` (`chat_page.dart:498-509`) por un
  ícono de credencial (`LucideIcons.idCard`) y conserva el tooltip «Enviar carnet», que
  también es su etiqueta accesible. El ícono llega a 3:1 contra el campo en los dos temas,
  así que va en `primaryDark` en claro (3,76:1) y en `primaryColor` en oscuro (4,92:1). El
  `#FF7A1A` de hoy no llega en claro.
- **Botón enviar.** Sigue siendo un círculo relleno con `Icons.send` en blanco, el ícono que
  buscan las pruebas de hoy (`chat_page_test.dart:165` y `:178`). Con texto, el relleno es
  `primaryDark` en los dos temas, en lugar del `#FF5722` de hoy (`chat_page.dart:545-561`).
  El ícono blanco da 4,12:1 contra el relleno, y el círculo da 4,12:1 y 4,03:1 contra la
  barra. En oscuro no sirve `primaryColor`, porque el blanco sobre `#FF6600` da 2,94:1.
- **Enviar deshabilitado.** Mientras el campo, ya recortado, está vacío, el botón se ve
  deshabilitado. El relleno pasa a `tagBg` y el ícono a `textMuted` (4,34:1 y 3,36:1), sin
  sombra, sin ripple y sin la respuesta de toque de la plataforma (`enableFeedback`, el clic
  de Android), y con la semántica de un botón deshabilitado. Un toque sobre el botón
  deshabilitado no envía nada ni muestra ningún aviso, porque llega a enviar y enviar descarta
  el campo recortado vacío (RF-CHAT-3), igual que la tecla del teclado. El botón conserva esa
  acción de toque en lugar de anularla, ya que las dos pruebas de enviar que no cambian
  escriben y tocan sin un `pump()` de por medio («Pruebas existentes que cambian»), y su
  toque cae en el botón tal como estaba antes de escribir.
- El botón enviar lleva el tooltip «Enviar mensaje», que también es su etiqueta accesible,
  como «Enviar carnet».
- Enviar con la tecla del teclado sigue funcionando con la misma regla, y con el campo vacío
  no envía nada.
- **Colores de la barra.** La barra va en `cardBg` con un borde superior en `borderColor`,
  el campo en `tagBg`, el texto escrito en `textPrimary` (16,30:1 y 12,38:1) y la pista
  «Escribe un mensaje...» en `textSecondary` (9,45:1 y 5,60:1). Reemplazan a `#F0F0F0`,
  `#1F2C34`, `#2A3942`, `black87` y `grey[600]` (`chat_page.dart:476-495` y `:518-535`).
  Las cifras del ícono de carnet se miden contra el campo, y las del botón enviar, contra
  la barra.

`[@test] ../../../test/HU23_jeff/chat_page_test.dart`

### RF-CHAT-13 — El docente entra desde Secciones

- La pestaña Secciones del docente (`teacher_sections_page.dart`) sigue abriendo el chat
  directo de cada sección.
- **Toque.** El `GestureDetector` (`teacher_sections_page.dart:134-141`) cambia por un
  `InkWell` con ripple. La tarjeta pasa a un `Material` con el color `cardBg` y la forma de
  la tarjeta (radio de 16 px y borde `borderColor`), con el `InkWell` dentro, porque el
  `Container` decorado de hoy (`teacher_sections_page.dart:142-148`) taparía el ripple. Es
  lo mismo que pide la bandeja (RF-CHAT-6). Su semántica es la de un botón «Abrir el chat
  de <curso>, sección <N>», o «Abrir el chat de <curso>, sin sección» si el código llega
  vacío, como en la bandeja.
- **Sección.** Bajo el nombre del curso, la línea de la sección deja el código tal como llega
  (`teacher_sections_page.dart:180-181`) y dice «Sección N» con el código recortado, o solo
  «Sin sección» si el código llega vacío o con solo espacios. Usa la misma
  `etiquetaDeSeccion` de la fila de la bandeja (RF-CHAT-6) y del subtítulo del AppBar
  (RF-CHAT-8), así que el docente lee su sección igual que el alumno.
- **«Chat».** El ícono de la columna derecha sigue bajo la insignia de rol
  (`teacher_sections_page.dart:192-205`), cambia `Icons.forum_outlined` por
  `LucideIcons.messagesSquare` y suma a su derecha, en la misma fila, el texto visible
  «Chat».
- «Chat» llega a 4,5:1 y el ícono a 3:1 contra la tarjeta en los dos temas. El naranja de
  marca sobre blanco da 2,94:1, así que el ícono va en `primaryDark` en claro (4,12:1) y en
  `primaryColor` en oscuro (5,65:1), y el texto en `textSecondary` en los dos.
- **Contraste de la tarjeta.** La línea de la sección deja el naranja de marca
  (`teacher_sections_page.dart:181-183`), que da 2,94:1 sobre blanco, y pasa a
  `textSecondary`, con 10,35:1 y 6,44:1 contra la tarjeta. La insignia de rol
  (`teacher_sections_page.dart:195-197`) pasa de `textMuted` a `textSecondary`, en su texto
  y en su tinte al 12 %. Contra este tinte mezclado sobre la tarjeta, como lo mezcla
  `Color.alphaBlend`, sube de 4,11:1 y 3,37:1 a 8,45:1 y 5,26:1. Así la línea de la sección
  y la insignia llegan a 4,5:1 en los dos temas.
- La tarjeta abre `ChatPage` con el código de la sección y `courseAccentColor(sectionId)`
  como color, el mismo acento que usa Calificar (`teacher_grades_page.dart:100`).
- El rediseño de RF-CHAT-8 a RF-CHAT-12 vale igual para el docente, y el borrado de
  RF-CHAT-4 también.

`[@test] ../../../test/HU23_jeff/chat_docente_secciones_test.dart`

## Textos nuevos

«Chats» (la pestaña), «Sección N» y «Sin sección» (la fila de la bandeja, el subtítulo del
AppBar y la tarjeta del docente; «Sin sección» va solo, sin el «Sección» delante), «Abrir el chat de <curso>, sección
<N>» y «Abrir el chat de <curso>, sin sección» (la etiqueta accesible de una fila de la
bandeja y de una tarjeta del docente), «Chat del curso» (el botón de la ficha), «Chat» (la
tarjeta del docente), «Enviar mensaje» (el tooltip y la etiqueta accesible del botón enviar),
«Hoy», «Ayer» y «<Día> <n> de <mes>» (los separadores), «Eliminaste este mensaje» y «Se
eliminó este mensaje» (la lápida de un mensaje que borra su autor, RF-CHAT-4). El cuerpo del
diálogo de borrado dice «Se eliminará para todos.» o «Se eliminará para todos y verán que lo
eliminaste tú.» (RF-CHAT-4). Salen «Chat grupal» y el cuerpo anterior de este diálogo, el de
«eliminado por ti» o «eliminado por el profesor» entre comillas rectas. Los demás textos del
chat no cambian.

## Lo que sale del horario

Con la pestaña Chats, el horario deja de ser la puerta del chat y queda solo como calendario
(decisión 3). Lo detallan `specs/features/schedule/schedule.spec.md` y BR-SHELL-F-03 de
`specs/features/app-shell/app-shell.spec.md`. En código, la fase 1 quita lo siguiente.

- El ícono de lista del header (`app_header.dart:95-115`). El header sigue sabiendo si está
  en Horario, solo para devolver la rotación al volver de las alertas
  (`app_header.dart:128-131`).
- `HorarioListView` con su archivo (`horario_list_view.dart`), su import
  (`horario.dart:14`) y su rama en el cuerpo del horario (`horario.dart:1175-1178`).
- `isListView` y `toggleListView` (`horario_controller.dart:56-57` y `:656-658`), y la
  condición que ocultaba los botones de bloques propios en la lista
  (`horario.dart:1098-1101`). Esos botones quedan con dos condiciones, alumno y vertical.

## Pruebas existentes que cambian

La fase 1 cambia el comportamiento que fijan estas pruebas. Cada una se ajusta al
comportamiento nuevo, y ninguna se usa para conservar el viejo.

- «en la lista de chats no aparece», en `time_blocks_form_test.dart:910` y en
  `time_blocks_lista_test.dart:999`. Salen, porque ese estado deja de existir. RF-BLQ-8 de
  `specs/features/time-blocks/time-blocks.spec.md` queda ajustado en ese punto.
- «un mensaje de moderador muestra su etiqueta de rol» (`chat_page_test.dart:218-230`). La
  sesión es la del profesor y el mensaje tiene su mismo uid como remitente, así que es
  propio y con RF-CHAT-9 y RF-CHAT-10 ya no muestra etiqueta. La prueba pasa a un mensaje de
  moderador de otro `senderId`, que sí la muestra, y suma el caso inverso, en el que un
  mensaje propio de moderador no la muestra.
- «enviar carnet usa el mensaje especial del repo» (`chat_page_test.dart:184-194`) busca
  `Icons.contact_page_outlined` en la barra (`:189`). Pasa a buscar `LucideIcons.idCard`
  (RF-CHAT-12).
- «mensaje carnet se renderiza como burbuja especial» (`chat_page_test.dart:196-216`) busca
  el mismo ícono en la burbuja (`:215`). Pasa a buscar `LucideIcons.idCard` (RF-CHAT-8).

Las pruebas que tocan el botón enviar (`chat_page_test.dart:165` y `:178`) no cambian,
porque el ícono sigue siendo `Icons.send`. Tampoco suman un `pump()` entre escribir y tocar,
y por eso el botón deshabilitado de RF-CHAT-12 conserva su acción de toque.

## Contrato que se consume

Esta fase no cambia ningún contrato (decisión 12), salvo quién puede usar el borrado desde el
ajuste de RF-CHAT-4. Por lo demás, la app consume lo mismo que hoy.

- `POST /chat/token` con `{sectionId}`, que devuelve `{token, uid, displayName, role,
  roleLabel, isModerator, weight}` (R-CHAT-1 del backend).
- Firebase RTDB, con lectura de los últimos 80 mensajes de `sections/{sectionId}/messages` y
  creación con `push()`. Las reglas (`database.rules.json`) no cambian.
- `DELETE /chat/sections/{sectionId}/messages/{messageId}`, que desde el ajuste acepta a
  cualquier participante para sus mensajes y al profesor titular para cualquiera (R-CHAT-4
  del backend). Responde 200 `{deleted, messageId, deletedBy}`, 403
  `CHAT_DELETE_FORBIDDEN` y 404 `CHAT_MESSAGE_NOT_FOUND`.
- El carnet visible de un usuario, por `NetworkingService.fetchVisibleByUserId`
  (`chat_repository.dart:175-178`).
- Las secciones de `GET /schedule/me/sessions`, que el horario ya pide
  (`horario_controller.dart:172-186`) y que la bandeja reutiliza.

## Qué NO entra

- La fase 2, con último mensaje, hora y no leídos en la bandeja. Pide un cambio del backend
  por las reglas de Firebase.
- Ulises en la bandeja (decisión 10).
- Dependencias nuevas y cambios del backend o de las reglas de Firebase (decisión 12). El
  cambio del borrado en el backend es del ajuste de RF-CHAT-4 y la app solo lo consume.
- Notificaciones de mensajes nuevos.
- Cambios en cómo se confirma un borrado, salvo los colores del diálogo (RF-CHAT-8) y su
  cuerpo, que RF-CHAT-4 elige por `senderId`. Quién borra, qué dice la lápida y el cuerpo del
  diálogo cambian con el ajuste del 2026-09-23.
- Un límite de tiempo para borrar un mensaje propio.
- Editar mensajes, adjuntar archivos, buscar en el chat o cargar más allá de los últimos 80.
- El año en el separador de día. Un chat de sección vive dentro de un ciclo.
- Un estado de error propio de la bandeja. `_loadSecciones` se traga el error
  (`horario_controller.dart:183-185`) y la bandeja, como hoy «Mis chats», cae en el estado
  vacío.
- Cambiar los textos de hoy, entre ellos el error crudo del stream
  (`chat_page.dart:372`). El cuerpo del diálogo de borrado sí cambia (RF-CHAT-4).
- El contenido del diálogo del carnet (`NetworkingCardPreview`, `chat_page.dart:161-182`),
  que es de `specs/features/networking/networking.spec.md`. Los avisos y el diálogo de
  borrado sí entran (RF-CHAT-8).
- El chat y la bandeja en horizontal.
- Una ruta nombrada para el chat, que se sigue abriendo con `Get.to`.

## Decisiones

El dueño aprobó estas doce decisiones el 2026-09-23.

| # | Decisión | Dónde queda |
| --- | --- | --- |
| 1 | Pestaña «Chats» en el footer del alumno, con ícono de conversación de Lucide; la app sigue abriendo en Malla | RF-CHAT-5 y BR-SHELL-F-02 de app-shell |
| 2 | Bandeja con una fila por sección (círculo con iniciales, nombre, «Sección N», chevron), sin último mensaje, hora ni no leídos | RF-CHAT-6 |
| 3 | Horario sin el ícono de lista ni «Mis chats», solo calendario | schedule.spec.md y BR-SHELL-F-03 de app-shell |
| 4 | Botón visible «Chat del curso» en la ficha del alumno | RF-CHAT-7 y course-detail.spec.md |
| 5 | ChatPage con la identidad de la app y contraste de 4,5:1 en los dos temas | RF-CHAT-8 y «AppBar en el tema claro» |
| 6 | Nombre solo en mensajes ajenos y solo al cambiar de remitente o de día | RF-CHAT-9 |
| 7 | Moderadores distinguidos solo por su etiqueta, con la burbuja igual a las demás | RF-CHAT-10 |
| 8 | Separadores «Hoy», «Ayer» y «Lunes 21 de septiembre», en hora de Lima y sin `intl` | RF-CHAT-11 |
| 9 | «Enviar carnet» con ícono de credencial y enviar deshabilitado con el campo vacío | RF-CHAT-12 |
| 10 | Ulises no entra en la pestaña Chats y sigue en su burbuja | RF-CHAT-5 y «Qué NO entra» |
| 11 | El docente sigue entrando desde Secciones, con el texto «Chat» y ripple; moderación sin cambios | RF-CHAT-13 y RF-CHAT-4 |
| 12 | Sin dependencias nuevas y sin cambios en el backend ni en las reglas de Firebase | «Contrato que se consume» y «Qué NO entra» |

El mismo 2026-09-23 el dueño decide además que cada participante borre sus propios mensajes,
sin límite de tiempo, que el profesor titular siga borrando los de cualquiera y que la lápida
avise al estilo de WhatsApp. Esta decisión deja atrás, solo para el borrado, «moderación sin
cambios» de la decisión 11 y «sin cambios en el backend» de la decisión 12, y queda en
RF-CHAT-4.

Algunos puntos no están en las decisiones y esta spec los fija por su cuenta. El dueño los
confirma o los cambia al aprobarla.

- **Delegado.** Con Chats, su footer tiene seis pestañas (RF-CHAT-5). El dueño decide el
  2026-09-23 que con seis pestañas la etiqueta activa vaya en 13 px, y «Verificación»
  comprueba que las seis etiquetas caben en 360 y en 375 de ancho.
- **Subdelegado.** Recibe la misma regla de etiqueta que Profesor, Jefe de Práctica y Delegado,
  porque el modelo también lo marca como moderador (RF-CHAT-10).
- **Color del nombre.** Sale el color por remitente y todos los nombres van en
  `textPrimary` (RF-CHAT-9).
- **Nombre después de una lápida.** Una lápida abre grupo, así que el mensaje ajeno que la
  sigue lleva nombre aunque sea del mismo remitente y del mismo día, algo que la decisión 6
  no pide (RF-CHAT-9).
- **Hora del mensaje.** Pasa a hora de Lima, igual que el separador (RF-CHAT-11).
- **Burbuja de carnet.** Pierde el borde naranja y su recuadro pasa a `primaryDark` con el
  ícono de credencial (RF-CHAT-8).
- **Avisos y diálogo de borrado.** Entran en el 4,5:1 de la decisión 5, con un rojo nuevo,
  `errorBg`, para los avisos de error y para «Eliminar» (RF-CHAT-8).
- **Carga de la bandeja.** Muestra un indicador durante la primera carga en lugar del estado
  vacío (RF-CHAT-6).
- **Error de la bandeja.** Queda fuera («Qué NO entra»), aunque `AGENTS.md` pide estados
  explícitos de error. Sumarlo exige que `HorarioController` deje de tragarse el error de
  `_loadSecciones` y un texto nuevo.

## AppBar en el tema claro

El dueño eligió el 2026-09-23 texto y flecha blancos sobre `#FF6600`, igual que el header
(`app_header.dart:81-89`), para que el chat se vea como el resto de la app. Ese blanco da
2,94:1 y no llega al 4,5:1 de la decisión 5; es el mismo contraste de la cabecera de toda la
app, y se corrige en toda la app en un cambio aparte, no en esta fase. El resto del texto de
la conversación, bajo el AppBar, sí cumple 4,5:1. En oscuro el blanco sobre `#1E1E24` da
16,58:1.

## Verificación

- `dart format` sobre los archivos Dart que cambien, salvo `lib/pages/horario/horario.dart`,
  `test/HU35_jeff/time_blocks_form_test.dart` y `test/HU35_jeff/time_blocks_lista_test.dart`.
  Estos tres no pasan el formato desde antes de esta rama, ya en `c18faa7`, y reformatearlos
  cambia cientos de líneas que no son del chat. La fase 1 no los reformatea, y sus cambios en
  ellos siguen el estilo de cada archivo.
- `flutter analyze --no-pub`.
- `flutter test --no-pub`, con la suite completa, porque la fase 1 toca `horario.dart`,
  `horario_controller.dart`, `home_page.dart` y `app_header.dart`, que usan otras features.
  Incluye `test/HU23_jeff`, `test/components/header/app_header_test.dart` y `test/HU35_jeff`
  sin las dos pruebas de la lista de chats.
- `TZ=UTC flutter test --no-pub test/HU23_jeff`. Las pruebas corren solo en una máquina
  local, porque `.github/workflows/build-apk.yml` no corre `flutter test`, y en UTC−5 la hora
  local coincide con la de Lima. Con `TZ=UTC`, las pruebas de RF-CHAT-11 detectan una hora o
  un día calculados en la zona del teléfono, como con `.toLocal()`.
- `chats_pestana_test` comprueba que con seis pestañas la etiqueta activa va en 13 px y que
  con cinco o menos sigue en 14. Monta además el footer de un delegado a 360×640 y a 375×667
  con cada pestaña activa, y comprueba que no hay desborde y que las seis etiquetas se leen
  completas (RF-CHAT-5). La prueba mide las etiquetas con Roboto, la fuente de Android, porque
  la del iPhone no viene con el SDK de Flutter. Su verde vale para Android en 360 y en 375 dp,
  y en el iPhone SE la medida con SF la confirma la revisión manual del punto siguiente.
- Una revisión manual en un iPhone SE, en los temas claro y oscuro, del footer del delegado,
  de la bandeja y de la conversación.
