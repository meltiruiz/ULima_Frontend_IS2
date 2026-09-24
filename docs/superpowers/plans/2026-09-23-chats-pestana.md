# Chats de curso, fase 1 — Plan de implementación

> **Para agentes:** SUB-SKILL REQUERIDA: usa superpowers:subagent-driven-development (recomendado) o superpowers:executing-plans para ejecutar este plan tarea por tarea. Los pasos usan casillas (`- [ ]`).

**Objetivo:** que los chats de curso se encuentren (pestaña «Chats» en el footer del alumno, botón en la ficha del curso, texto «Chat» en las tarjetas del docente) y se vean como parte de la app (colores, remitentes, separadores de día y contraste), sin tocar el backend.

**Arquitectura:** piezas puras nuevas (iniciales del curso, agrupación de mensajes, día y hora en Lima) y tres tokens de tema, `chatOwnBubbleBg` y `errorBg` desde la Tarea 1 e `iconoNaranja` desde los ajustes de cierre del 2026-09-23; `ChatPage` se rediseña sobre esas piezas; una página de bandeja nueva lee de `HorarioController`, que ya carga las secciones; Horario pierde su vista de lista y el header su toggle.

**Stack:** Flutter 3.x + GetX + Firebase Realtime Database (sin cambios) + `lucide_icons` (ya en el proyecto).

**Spec:** `specs/features/chat/chat.spec.md` (RF-CHAT-1 a RF-CHAT-13), aprobada el 2026-09-23 e implementada el mismo día, con la revisión manual en un iPhone SE pendiente, más los ajustes de `specs/features/app-shell/app-shell.spec.md` (BR-SHELL-F-02 y F-03), `specs/features/schedule/schedule.spec.md` («Solo calendario»), `specs/features/course-detail/course-detail.spec.md` y `specs/features/time-blocks/time-blocks.spec.md` (RF-BLQ-8, sin la condición de la lista de chats). El dueño aprobó estos cuatro ajustes el 2026-09-23, junto con la spec del chat, y el mismo día aprobó también el ajuste de RF-CHAT-4 por el que cada participante borra sus propios mensajes, así que no queda ninguna aprobación pendiente. Este ajuste es posterior a la Tarea 2 y manda sobre lo que ella dice de la moderación. Las piezas de la Tarea 1 viven en `lib/pages/chat/chat_linea_tiempo.dart` y `lib/pages/chat/curso_avatar.dart`, las rutas de los `targets` de la spec. **La spec es la fuente de los valores exactos** (tamaños, colores, textos, cifras de contraste, reglas); este plan dice en qué orden, en qué archivos y con qué pruebas. Si el plan y la spec difieren, manda la spec.

## Restricciones globales

- Español en comentarios, nombres de prueba y commits. Commits con `git add` explícito, SIN trailer Co-Authored-By ni ninguna línea de atribución (regla del dueño). Nada de push.
- Sin dependencias nuevas en `pubspec.yaml` (nada de `intl`). Íconos nuevos de `lucide_icons`.
- GetX: binding por ruta, nunca `Get.put` dentro de `build()` salvo el precedente explícito que cita la spec (`horario.dart:1081`). HTTP solo en services.
- Repo PÚBLICO: ningún dato real. Alumno sintético `20230001`; personas y cursos inventados («Docente De Prueba», «CURSO DE PRUEBA A»). En `test/HU23_jeff/chat_page_test.dart` el nombre de docente que parece real se reemplaza por uno inventado en la Tarea 2.
- Colores solo desde `MaterialTheme` (`lib/configs/themes.dart`); `ChatPage` no puede quedar con hex sueltos ni colores fijos de `Colors` salvo `white`, `black` (también con opacidad en sombras) y `transparent` (RF-CHAT-8).
- Contraste: texto >= 4,5:1 y ícono informativo >= 3:1 en los dos temas, con la única excepción del texto del AppBar del chat en claro (blanco sobre `#FF6600`, decisión del dueño).
- Hora de Lima = UTC−5 todo el año, como `_nowInLima` (`horario_controller.dart:78-79`).
- `flutter analyze` no puede sumar issues a la línea base (medirla al empezar la Tarea 1). Suite completa verde al cerrar cada tarea: `"$FLUTTER" test`.
- `FLUTTER` es el ejecutable `flutter` del SDK que indica el despacho; ninguna ruta de una máquina concreta entra en archivos del repo.

## Estructura de archivos

| Archivo | Acción | Responsabilidad |
|---|---|---|
| `lib/configs/themes.dart` | modificar | tokens `chatOwnBubbleBg(Brightness)` y `errorBg(Brightness)`, y en los ajustes de cierre `iconoNaranja(Brightness)` (RF-CHAT-8) |
| `lib/pages/chat/chat_linea_tiempo.dart` | crear | funciones puras: iniciales, color de iniciales, día y hora en Lima, etiqueta de día, inicio de grupo, nombre |
| `lib/pages/chat/curso_avatar.dart` | crear | `CursoAvatar`: círculo del color del curso con sus iniciales (bandeja y AppBar) |
| `lib/pages/chat/chat_page.dart` | modificar | rediseño RF-CHAT-8 a 12, conservando RF-CHAT-1 a 4; parámetros opcionales `sectionCode` y `courseColor` |
| `lib/pages/chat/chats_inbox_page.dart` | crear | bandeja de la pestaña Chats (RF-CHAT-6) |
| `lib/pages/home/home_shell_config.dart`, `lib/pages/home/home_page.dart` | modificar | pestaña Chats del alumno y del delegado (RF-CHAT-5); recarga al entrar |
| `lib/components/footer/app_footer.dart` | modificar | en los ajustes de cierre, etiqueta activa en 13 px cuando el footer tiene seis pestañas (RF-CHAT-5 y BR-SHELL-F-02) |
| `lib/components/header/app_header.dart` | modificar | quitar el toggle lista/calendario (BR-SHELL-F-03) |
| `lib/pages/horario/horario_controller.dart`, `lib/pages/horario/horario.dart` | modificar | quitar `isListView`/`toggleListView` y la rama de lista; exponer si terminó la primera carga de secciones; pasar el color a la ficha |
| `lib/pages/horario/horario_list_view.dart` | borrar | la vista «Mis chats» sale |
| `lib/pages/descripcion_cursos/descrip_cursos.dart` | modificar | botón «Chat del curso» y parámetro opcional de color (RF-CHAT-7) |
| `lib/pages/teacher/teacher_sections_page.dart` | modificar | tarjeta con `InkWell`, texto «Chat» y color de acento (RF-CHAT-13) |
| `test/HU23_jeff/*` | crear/modificar | las pruebas que enlaza la spec |

Las dos piezas nuevas de la Tarea 1 están donde las ponen los `targets` de la spec (`specs/features/chat/chat.spec.md`), que mandan sobre la primera versión de este plan. Las tareas siguientes las importan con `import 'package:ulima_plus/pages/chat/chat_linea_tiempo.dart';` y `import 'package:ulima_plus/pages/chat/curso_avatar.dart';`, y el círculo del curso es la clase `CursoAvatar`. Nadie crea `lib/pages/chat/chat_timeline.dart` ni `lib/components/course_avatar.dart`, porque serían copias fuera de los `targets`.

## Orden y dependencias

Tarea 1 → Tarea 2 → Tarea 3 → Tarea 4 → Tarea 5, en ese orden y en la misma rama `feat/chats-pestana`.

---

### Tarea 1: Tokens y piezas puras

**Requisitos:** RF-CHAT-8 (tokens, círculo del curso, regla de iniciales y su color), RF-CHAT-9 (inicio de grupo y nombre, como función pura), RF-CHAT-11 (día y hora en Lima, etiqueta del día, como funciones puras).

**Archivos:** modificar `lib/configs/themes.dart`; crear `lib/pages/chat/chat_linea_tiempo.dart`, `lib/pages/chat/curso_avatar.dart`; pruebas `test/HU23_jeff/chat_linea_tiempo_test.dart` y `test/HU23_jeff/chat_identidad_test.dart`.

**Produce (firmas exactas, las usan las Tareas 2 a 4):**

```dart
// lib/configs/themes.dart, dentro de MaterialTheme, con el estilo de los tokens existentes
static Color chatOwnBubbleBg(Brightness b) => b == Brightness.dark ? const Color(0xFF3A2A22) : const Color(0xFFFFE8DC);
static Color errorBg(Brightness b) => const Color(0xFFB3261E);

// lib/pages/chat/chat_linea_tiempo.dart
String inicialesDeCurso(String nombre);            // regla de RF-CHAT-8, pasos 1 a 4
Color colorDeIniciales(Color fondo);                // Colors.white o Color(0xFF000000), el de mayor contraste WCAG
double contrasteWcag(Color a, Color b);             // razón WCAG 2.x, la usan las pruebas y colorDeIniciales
DateTime enHoraDeLima(DateTime instante);           // instante.toUtc() - 5 h (campos de pared de Lima)
String horaDeMensaje(DateTime createdAt);           // "HH:mm" en hora de Lima
String etiquetaDeDia(DateTime diaLima, DateTime hoyLima); // "Hoy", "Ayer" o "Lunes 21 de septiembre"
bool abreGrupo(ChatMessage actual, ChatMessage? anterior); // RF-CHAT-9
bool llevaNombre(ChatMessage actual, ChatMessage? anterior, String uidSesion); // RF-CHAT-9

// lib/pages/chat/curso_avatar.dart
class CursoAvatar extends StatelessWidget {
  const CursoAvatar({super.key, required this.nombre, required this.color, this.size = 42});
  final String nombre; final Color color; final double size;
}
```

- [ ] **Paso 1: línea base.** `cd` a la raíz del worktree, `"$FLUTTER" analyze` y `"$FLUTTER" test`; anota el número de issues y de pruebas en el informe.
- [ ] **Paso 2: pruebas que fallan.** Escribe las dos pruebas con estos casos, como mínimo:
  - `inicialesDeCurso`: «INGENIERÍA DE SOFTWARE II» → «IS»; «Ingeniería de Software II» → «IS»; «Cálculo I» → «C»; «Programación en C» → «PC»; «Lenguaje C» → «LC»; «Ética y Ciudadanía» → «ÉC»; «II» → «I»; «de la» → «D»; «» → «»; «  123  » → «» (sin letras).
  - `colorDeIniciales`: para cada color de `kCoursePalette` (`lib/configs/course_colors.dart`), `contrasteWcag(colorDeIniciales(c), c) >= 4.5`; y el peor caso de la spec (4,58:1).
  - Tokens: `contrasteWcag(textPrimary(b), chatOwnBubbleBg(b))` >= 4,5 en los dos temas (15,16 y 11,74); `contrasteWcag(Colors.white, errorBg(b))` >= 4,5 (6,54).
  - `horaDeMensaje`: `DateTime.utc(2026, 9, 15, 3, 30)` → «22:30»; `DateTime.utc(2026, 9, 15, 5, 10)` → «00:10».
  - `etiquetaDeDia`: mismo día → «Hoy»; día anterior → «Ayer»; 2026-09-21 con hoy 2026-09-23 → «Lunes 21 de septiembre»; cruce de mes y de año (2025-12-31 con hoy 2026-01-02 → «Miércoles 31 de diciembre»).
  - `abreGrupo` y `llevaNombre` con mensajes construidos con el constructor de `ChatMessage`: primero de la lista (abre; ajeno lleva nombre, propio no); mismo remitente y mismo día (no abre, sin nombre); otro `senderId` con el mismo nombre (abre); otro día en Lima aunque esté a minutos en UTC (abre); anterior es lápida (`deleted: true`) (abre); una lápida nunca lleva nombre; un propio nunca lleva nombre.
  - `CursoAvatar`: pinta las iniciales y el color; con nombre sin letras no pinta texto.
- [ ] **Paso 3:** córrelas y confirma que fallan por lo que falta.
- [ ] **Paso 4:** implementa lo mínimo en los tres archivos.
- [ ] **Paso 5:** córrelas en verde, suite completa en verde y `analyze` sin issues nuevos.
- [ ] **Paso 6: commit** `feat(chat): piezas del rediseño: iniciales del curso, días y horas en Lima, agrupación de mensajes y tokens del chat (RF-CHAT-8, RF-CHAT-9, RF-CHAT-11)`.

### Tarea 2: La conversación rediseñada

**Requisitos:** RF-CHAT-8 a RF-CHAT-12 en `ChatPage`, conservando RF-CHAT-1 a RF-CHAT-4 tal como los describe la spec.

**Archivos:** modificar `lib/pages/chat/chat_page.dart`; modificar `test/HU23_jeff/chat_page_test.dart`; crear `test/HU23_jeff/chat_moderacion_test.dart`; ampliar `test/HU23_jeff/chat_identidad_test.dart` (obligatorio, con los casos del Paso 1) y `chat_linea_tiempo_test.dart` si hace falta.

**Consume:** todo lo que produce la Tarea 1, con los dos imports que indica «Estructura de archivos».
**Produce:** `ChatPage({required String sectionId, required String courseName, String? sectionCode, Color? courseColor, ChatRepositoryContract? repository})`.

- [ ] **Paso 1: pruebas que fallan** (con el `ChatRepositoryContract` falso que ya usa `chat_page_test.dart`):
  - AppBar con `CursoAvatar`, título = curso, subtítulo «Sección 801» y «Sin sección» con código vacío; sin «Chat grupal».
  - Fondo = `pageBg`; burbuja propia en `chatOwnBubbleBg`; ajena en `cardBg` con borde.
  - Nombre solo en ajenos que abren grupo; nunca en propios; la etiqueta de rol junto al nombre, sin borde ni fondo teñido en la burbuja del moderador.
  - En `chat_identidad_test.dart`, que es el `[@test]` de RF-CHAT-8 y de RF-CHAT-10, las pruebas de widget sobre `ChatPage` en los dos temas. Para RF-CHAT-10, la etiqueta de rol sale solo junto al nombre (un mensaje ajeno de moderador que abre grupo), en `textSecondary`, en negrita y sin fondo, y no sale en el mensaje del mismo moderador que sigue al suyo el mismo día ni en uno propio; la burbuja del moderador es igual a la de otro ajeno. Para RF-CHAT-8, el AppBar en `headerColor` con `CursoAvatar` de 36 px y la flecha, el título y el subtítulo en blanco; el fondo en `pageBg`; la burbuja propia en `chatOwnBubbleBg` y la ajena en `cardBg` con borde `borderColor`; la burbuja de carnet sin borde naranja, con su recuadro en `primaryDark` y `LucideIcons.idCard` en blanco; la lápida en `tagBg` con borde `borderColor` y su texto y su ícono en `textSecondary`; el error del stream en `textSecondary`; los estados vacío y no disponible en `cardBg` con borde, el título en `textPrimary`, el cuerpo en `textSecondary` y el candado en `primaryDark` en claro y `primaryColor` en oscuro; los avisos de error en blanco sobre `errorBg` y los demás en `cardBg` con borde y texto en `textPrimary`; el diálogo de borrado en `cardBg`, con «Eliminar» en blanco sobre `errorBg`. Las cifras de contraste de cada par ya las fija el grupo «pares de colores de ChatPage» de la Tarea 1, así que estas pruebas comprueban que `ChatPage` usa esos tokens en cada elemento.
  - Separadores: con los dos `createdAt` de RF-CHAT-11 aparecen «Lunes 14 de septiembre» antes de «22:30» y «Martes 15 de septiembre» antes de «00:10».
  - Barra: «Enviar carnet» con `LucideIcons.idCard` y su tooltip; `Icons.send` con tooltip «Enviar mensaje»; con el campo vacío el botón está deshabilitado (no llama a enviar) y con texto sí envía.
  - Colores: ningún `Color(0x…)` ni `Colors.<fijo>` en `chat_page.dart` salvo los permitidos (una prueba que lee el archivo como texto y busca los patrones).
  - `chat_moderacion_test.dart`: solo el rol teacher ve «¿Eliminar mensaje?» con long-press, «Eliminar» en blanco sobre `errorBg`, y el JP no.
  - Ajusta las pruebas existentes de `chat_page_test.dart` que cambian por la spec (la de la etiqueta de rol de moderador y la que depende del nombre repetido) y reemplaza el nombre de docente que parece real por «Docente De Prueba». No borres pruebas de RF-CHAT-1 a 4.
- [ ] **Paso 2:** córrelas y confirma el rojo.
- [ ] **Paso 3:** rediseña `chat_page.dart` según la spec (AppBar con `MaterialTheme.headerColor`, estados, lápida, avisos con `errorBg`/`cardBg`, diálogo, barra) usando las piezas de la Tarea 1. Quita `_roleAccent`, `_bubbleColor`, el color por remitente y `showSender: true` fijo.
- [ ] **Paso 4:** verde enfocado, suite completa, `analyze` sin issues nuevos.
- [ ] **Paso 5: commit** `feat(chat): la conversación con la identidad de la app, remitentes agrupados y separadores de día (RF-CHAT-8 a RF-CHAT-12)`.

### Tarea 3: La pestaña Chats y la bandeja

**Requisitos:** RF-CHAT-5 y RF-CHAT-6; BR-SHELL-F-02 y BR-SHELL-F-03 de app-shell; «Solo calendario» de schedule.

**Archivos:** crear `lib/pages/chat/chats_inbox_page.dart`; modificar `lib/pages/home/home_shell_config.dart`, `lib/pages/home/home_page.dart`, `lib/components/header/app_header.dart`, `lib/pages/horario/horario_controller.dart`, `lib/pages/horario/horario.dart`; borrar `lib/pages/horario/horario_list_view.dart`; pruebas nuevas `test/HU23_jeff/chats_pestana_test.dart` y `test/HU23_jeff/chats_bandeja_test.dart`; ajustar `test/components/header/app_header_test.dart` y las dos pruebas de `test/HU35_jeff/` que llaman a `toggleListView` (la spec del chat dice cuáles salen o cambian).

**Consume:** `CursoAvatar` (Tarea 1, `package:ulima_plus/pages/chat/curso_avatar.dart`) y `ChatPage(sectionCode:, courseColor:)` (Tarea 2).
**Produce:** `HorarioController` sin `isListView`/`toggleListView`, con un `RxBool` público que dice si terminó la primera carga de secciones (nómbralo `seccionesCargadas`); la página `ChatsInboxPage`.

- [ ] **Paso 1: pruebas que fallan:**
  - `chats_pestana_test.dart`: footer del alumno = Malla, Notas, Horario, Chats, Perfil; del delegado = Malla, Notas, Horario, Chats, Delegado, Perfil; del docente sin cambios; la app abre en Malla; Chats es vertical; el shell sigue encontrando «Horario» y «Asesorias» por etiqueta; a 375×667 las seis etiquetas del delegado se leen completas y sin desborde con cada pestaña activa; entrar a Chats llama a `reload()` si el controller ya está registrado.
  - `chats_bandeja_test.dart`: una fila por sección de `uniqueEnrolledCourses`, en ese orden, con `CursoAvatar` del color de `colorPorCurso`, nombre tal como llega, «Sección N» o «Sin sección» (código nulo, vacío o solo espacios), chevron; tocar abre `ChatPage` con curso, código y color; semántica «Abrir el chat de <curso>» y alto >= 48; indicador mientras `seccionesCargadas` es falso; «No hay cursos matriculados.» si terminó sin secciones; Ulises no aparece en la lista.
  - `app_header_test.dart`: el header del alumno ya no tiene el ícono de lista ni el de calendario.
- [ ] **Paso 2:** rojo.
- [ ] **Paso 3:** implementa; borra `horario_list_view.dart` y todo uso de `isListView`/`toggleListView`; los FAB de bloques quedan con las condiciones alumno y vertical (ya no existe la lista de chats).
- [ ] **Paso 4:** verde enfocado, suite completa, `analyze`.
- [ ] **Paso 5: commit** `feat(chat): pestaña Chats con la bandeja de chats de curso; Horario queda solo calendario (RF-CHAT-5, RF-CHAT-6)`.

### Tarea 4: La ficha del curso y la tarjeta del docente

**Requisitos:** RF-CHAT-7 y RF-CHAT-13; el punto de course-detail.

**Archivos:** modificar `lib/pages/descripcion_cursos/descrip_cursos.dart`, `lib/pages/horario/horario.dart` (pasar `controller.colorPorCurso[idSeccion]` al abrir la ficha), `lib/pages/teacher/teacher_sections_page.dart`; pruebas nuevas `test/HU23_jeff/chat_ficha_curso_test.dart` y `test/HU23_jeff/chat_docente_secciones_test.dart`.

**Consume:** `ChatPage(sectionCode:, courseColor:)` (Tarea 2); `courseAccentColor` (`lib/configs/course_colors.dart`).

- [ ] **Paso 1: pruebas que fallan:**
  - Ficha: la franja muestra «Sección: N» a la izquierda y el botón «Chat del curso» con `LucideIcons.messagesSquare` a la derecha, de 48 px de alto táctil; abre `ChatPage` con `seccion.curso`, `seccion.codigoSeccion` y el color recibido; sin color, `ChatPage` usa su respaldo; al volver, la ficha sigue en la misma pestaña.
  - Docente: la tarjeta es un `InkWell` dentro de un `Material` con `cardBg` y forma redondeada; muestra `LucideIcons.messagesSquare` y el texto «Chat»; semántica «Abrir el chat de <curso>»; abre `ChatPage` con el código y `courseAccentColor(int.tryParse(sectionId) ?? 0)`.
  - Contraste de «Chat del curso», «Chat» y sus íconos en los dos temas con `contrasteWcag` (`package:ulima_plus/pages/chat/chat_linea_tiempo.dart`).
- [ ] **Paso 2:** rojo. **Paso 3:** implementa. **Paso 4:** verde, suite completa, `analyze`.
- [ ] **Paso 5: commit** `feat(chat): botón Chat del curso en la ficha y texto Chat en las secciones del docente (RF-CHAT-7, RF-CHAT-13)`.

### Tarea 5: Cierre

- [ ] **Paso 1:** en `specs/features/chat/chat.spec.md`, cada `[@test]` apunta a un archivo que existe y que tiene al menos un caso del requisito que lo enlaza (por ejemplo, RF-CHAT-10 en `chat_identidad_test.dart` y en `chat_page_test.dart`). Los `targets` nombran además las rutas reales de las piezas de la Tarea 1, `lib/pages/chat/chat_linea_tiempo.dart` y `lib/pages/chat/curso_avatar.dart`. El estado de la spec dice «implementada el 2026-09-23; falta la revisión manual en un iPhone SE», y la fila 19 de `docs/specs/feature-index.md` dice lo mismo. Esta revisión es la de «Verificación», que en el iPhone SE comprueba con SF que las seis etiquetas del footer del delegado se leen completas en 375 pt con cualquiera activa, porque `chats_pestana_test` mide con Roboto (RF-CHAT-5). Las aprobaciones ya se dieron. El dueño decidió el 2026-09-23 el ajuste del footer, con la etiqueta activa en 13 px cuando hay seis pestañas. El mismo día aprobó la spec del chat, el ajuste de RF-CHAT-4 y los ajustes de app-shell (BR-SHELL-F-02 y BR-SHELL-F-03), schedule, course-detail y time-blocks (RF-BLQ-8), cuyas notas dicen «Aprobada por el dueño el 2026-09-23, junto con la spec del chat».
- [ ] **Paso 2:** `README.md`: actualiza las menciones de «Mis chats», el toggle del header y «Chat grupal» (buscar con `grep -n "Mis chats\|Chat grupal\|toggleListView\|format_list_bulleted" README.md`) para que describan la pestaña Chats y la cabecera nueva. Sin datos reales.
- [ ] **Paso 3:** suite completa, `analyze` con la misma cantidad de issues que la línea base, ninguna ruta de una máquina concreta (carpetas de usuario o temporales) en las líneas agregadas fuera de `docs/superpowers/plans/`, y ningún código de ocho dígitos que no sea `20230001` en lo agregado.
- [ ] **Paso 4: capturas para el dueño** (no van al repo): con una prueba descartable fuera del repo, PNG a 375×667 con DPR 2, en claro y en oscuro, de la pestaña Chats, una conversación con mensajes de varios días y de un moderador, la ficha con el botón, la pestaña Secciones del docente y el footer del delegado con «Delegado» activo. Guárdalas en el scratchpad y lista las rutas en el informe.
- [ ] **Paso 5: commit** `docs(chat): cerrar la spec del chat y el README con la pestaña Chats`.
