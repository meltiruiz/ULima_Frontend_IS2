# Plan de implementación del test de especialidad en la app

> **Para agentes:** SUB-SKILL REQUERIDA: usa superpowers:subagent-driven-development (recomendado) o superpowers:executing-plans para ejecutar este plan tarea por tarea. Los pasos usan casillas (`- [ ]`).

**Objetivo:** que el alumno nuevo haga el test de especialidad con Ulises como paso central del asistente, vea su resultado con el motivo, elija su principal y marque intereses, y encuentre en el Perfil su último resultado y el acceso para rehacerlo, en claro y en oscuro, con lector de pantalla, texto grande y menos movimiento.

**Arquitectura:** `SpecialtyTestService`, un `GetxService` permanente, es la única frontera con `/specialty-test/**` y guarda en memoria, atado al alumno, la copia del contenido, un test en pausa y el último resultado. Las reglas de la conversación, de la selección oficial, del contraste, de los íconos y de la fecha son funciones puras de `specialty_test_logic.dart`. `SpecialtyTestController` conduce la ruta `/test-especialidad` a través de un puerto de pantalla (`SpecialtyTestUi`) que las pruebas reemplazan por uno falso. Las cuatro vistas (bienvenida, pregunta, espera y resultado) solo leen el controlador, la tarjeta del Perfil lee el service y el asistente abre la ruta y lee su salida.

**Stack:** Flutter 3.47.2 en local (la CI compila el APK con 3.44.2), Dart 3.11, GetX 4.7.3, `http`, `lucide_icons_flutter` 3.1.15 y `flutter_test` con dobles escritos a mano.

**Spec:** `specs/features/specialty-test/specialty-test.spec.md` (RF-TEST-1 a RF-TEST-14), aprobada por el dueño el 2026-09-25, con la enmienda de `specs/features/academic-profile/academic-profile.spec.md` y el contrato de `docs/specs/api-contracts.md` («Specialty Test» y «Academic Profile»). La spec es la fuente de los valores exactos (tamaños, colores, textos, cifras de contraste y reglas). Este plan dice en qué orden, en qué archivos y con qué pruebas. Si el plan y la spec difieren, manda la spec.

**Repo y rama:** `$REPO`, el worktree de la rama `feat/test-especialidad-fe`, que al escribir el plan está en `757a9af`.

## Restricciones globales

- Solo archivos de los `targets` de la spec. Los que crea o cambia el plan están en «Estructura de archivos», todos dentro de esos `targets`, más los cuatro documentos de la Tarea 19.
- Español en comentarios, nombres de prueba y mensajes de commit, con el estilo del log (`feat(specialty-test): …` y `docs(specialty-test): …`, en presente).
- Commits con `git add` explícito, sin trailer `Co-Authored-By` ni otra línea de atribución, y con el autor que ya tiene configurado el repo, `Jeffangeloss <178797184+jeffangeloss@users.noreply.github.com>`. Nada de push y nada de `git stash`.
- Otra sesión puede compartir el worktree. Antes de cada commit se comprueban la rama y `git status --short`, que solo puede listar los archivos de la tarea.
- Repo público, así que ningún dato real. El alumno de prueba es `20230001`, un segundo alumno lleva un código que no puede ser real (`alumna.b.test`) y el docente es `docente.test`. Los cursos y electivos son inventados (`CURSO DE PRUEBA A`, `ELECTIVO DE PRUEBA A`) y los `specialtyId` 1, 5, 6 y 7 son ilustrativos, como en el contrato.
- Sin dependencias ni assets nuevos (decisión 8). Íconos de `lucide_icons_flutter` 3.1.15 y, para el corazón y la estrella rellenos, de `Icons`.
- GetX con binding por ruta y nunca `Get.put` dentro de `build()`. HTTP solo en `SpecialtyTestService` y `AuthService`. Ningún widget ni controlador lee JSON.
- Colores desde `MaterialTheme` o desde el contenido. Los únicos hex de las vistas nuevas son los que la spec fija iguales en los dos temas (héroe, pastilla dorada, punto verde y confeti).
- Contraste de 4,5:1 para el texto y de 3:1 para el ícono que informa, en los dos temas. La única excepción es la cabecera del asistente en claro (decisión 9).
- Hora de Lima en UTC−5 todo el año, con la función propia `fechaEnLima`.
- Textos visibles, los de «Textos nuevos» de la spec, que ya traen los dos derivados menores de la decisión 5 con su nota.
- Pruebas con dobles escritos a mano (`extends ApiClient`, `extends AuthService`, `extends StorageService` e `implements SpecialtyTestUi`), sin mockito ni mocktail.
- Dentro de `testWidgets` el reloj es falso, así que ahí no se usa `pumpEventQueue()` sino `tester.pump()`. Mientras haya animaciones que se repiten (el vaivén de la bienvenida, el brillo de la pluma o un `SkeletonPulse`) tampoco se usa `pumpAndSettle()`.
- `flutter analyze` no suma issues a la línea base y `dart format` corre sobre los archivos de cada tarea.
- La app no se publica. Cada push a `main` publica el APK (`.github/workflows/build-apk.yml`), así que el merge espera al backend desplegado con sus tres rutas y con la `0014` aplicada con el respaldo y el permiso del dueño.

## Variables de los comandos

El plan no fija rutas de una máquina concreta, porque el repo es público. Cada bloque de shell empieza con `cd "${REPO:?}"`, y antes de correrlo se exportan tres variables con los valores de la máquina.

- `REPO`, la ruta absoluta del worktree de la rama `feat/test-especialidad-fe` (la muestra `git worktree list`).
- `FLUTTER`, el ejecutable `flutter` del SDK.
- `DART`, el ejecutable `dart` del mismo SDK, que está junto a `flutter` en su carpeta `bin`.

Si `.dart_tool` no existe en el worktree, `"${FLUTTER:?}" pub get` va primero. Los comandos usan `--no-pub` para no tocar `pubspec.lock`.

## Línea base en `757a9af`

- `"${FLUTTER:?}" analyze --no-pub` da `6 issues found.`, todos `info` y previos. Son `avoid_print` en `lib/main.dart:95`, dos `deprecated_member_use` en `lib/services/attendance_risk_service.dart:55`, `unnecessary_import` en `test/HU20_jeff/otp_field_ime_test.dart:32` y dos `depend_on_referenced_packages` en `test/HU26_sam/export_csv_cajanegra_test.dart:20-21`. El número de línea del `avoid_print` sube cuando la Tarea 7 y las siguientes agregan líneas a `main.dart`, y eso no cuenta como issue nuevo.
- `"${FLUTTER:?}" test --no-pub` da `+1122: All tests passed!`.

Después del plan, la rama trae `main` en `19fed1b`, con el truco del 67, en un merge cuyo único conflicto es la fila 20 del índice, que conserva las dos filas. Con ese merge, `analyze` sigue en los mismos `6 issues found.`, en las mismas líneas, y `test` da `+1223: All tests passed!`, 101 pruebas más, que son las de `test/six_seven/`. La suite completa de la copia en `757a9af` no tiene esas 101 pruebas, así que el Paso 7 de las Tareas 7 y 18 y el Paso 1 de la Tarea 19 esperan la cifra de esa copia más 101, como dice cada «Esperado». Las corridas de un archivo o de una carpeta no cambian, porque `main` no suma pruebas fuera de `test/six_seven/`.

## Cómo se midieron las cifras

Cada «Esperado» sale de aplicar este plan tal como está escrito, tarea por tarea y paso por paso, en una copia descartable del worktree en `757a9af` (fuera del repo y sin git), con Flutter 3.47.2, y de correr ahí cada comando. Los rojos son los que da esa corrida. Al final, cada archivo de la copia quedó igual al código de referencia del que salen los bloques de este plan, la suite completa dio `+1363: All tests passed!` y `test/HU36_jeff/` dio `+241` con `TZ=UTC`. Si una corrida real da otra cifra, se compara prueba por prueba antes de seguir, y nunca se ajusta una prueba para que cuadre.

## Decisiones del plan

La spec las deja abiertas o no las nombra. Ninguna cambia un requisito, y el dueño revisa antes del merge los dos textos que suma la 5.

1. **`widgets/test_buttons.dart`.** Un archivo más dentro de `lib/pages/specialty_test/**`, con `TestPrimaryButton`, `TestSecondaryButton` y `TestErrorMessage`. Los usan las cuatro vistas, la tarjeta del Perfil, el Perfil y el asistente, cuyo botón inferior pasa al estilo del botón principal del test (RF-TEST-1). La Tarea 19 lo suma a «Se crean» de la spec.
2. **`AuthService({ApiClient? apiClient})` y `officialSpecialtyIds`.** El constructor gana un parámetro opcional para que las pruebas del plazo de `completeSetup`, de los catálogos y del Perfil corran sin red, y `isOfficialSpecialty` se apoya en un getter `officialSpecialtyIds`, que también usan el Perfil y el asistente. `officialSpecialtyIds` cuenta solo los elementos con `is_active == true`, la misma defensa que ya aplican el asistente y el Perfil.
3. **Un puerto de pantalla.** `SpecialtyTestController` no llama a `Get.back`, `Get.snackbar` ni `Get.dialog`. Pide cerrar, ir al home, avisar o preguntar a un `SpecialtyTestUi`. La ruta usa `UiDelTestConGet`, que cierra con `Get.key.currentState?.pop`, porque `Get.back()` de get 4.7.3 cierra el aviso abierto en lugar de la ruta.
4. **La pausa sale de `onClose`.** Cualquier cierre de la ruta con respuestas en memoria deja el test en pausa (el botón de pausa, el atrás del sistema en la bienvenida y «Ahora no»). Saltar, un `404` y un resultado ya borran las respuestas, así que no dejan nada.
5. **Dos singulares.** Con una sola respuesta, la etiqueta de la pastilla para el lector de pantalla dice «Ver tu respuesta anterior», el singular de «Ver tus N respuestas anteriores», igual que la spec ya da «1 respuesta anterior» para la pastilla. Es lo que oye quien usa VoiceOver o TalkBack en la pregunta 2. La fila de electivos con uno solo dice «1 electivo», que con el contenido `2026-09-25.4`, de siete electivos por diploma, no aparece. La spec ya suma los dos textos a «Textos nuevos», con una nota que los marca como derivados menores, así que la Tarea 19 no los agrega.
6. **Error de la espera sin mensaje.** Un fallo sin respuesta y una respuesta que no se puede leer muestran «No pudimos conectarnos. Revisa tu conexión e inténtalo de nuevo.», el texto de la fila de sin conexión.
7. **Desempate que no coincide.** Al repetir sin desempates, el paso vuelve a la última pregunta, para que un atrás desde el error no apunte a un desempate que ya no existe.
8. **Precarga con `404`.** Si la precarga del asistente termina en `404 SPECIALTY_TEST_NOT_AVAILABLE`, la bienvenida no pide el contenido otra vez, porque daría lo mismo, y pasa a la selección manual.
9. **Roboto en las pruebas que miden espacio.** La fuente de pruebas dibuja cada letra como un cuadrado del ancho de su tamaño. Las pruebas de «cabe sin desplazar» y de desborde cargan Roboto del SDK, como `test/HU23_jeff/chats_pestana_test.dart`.
10. **Validación del contenido.** Además de lo que lista RF-TEST-2, el modelo exige la versión, el id y el enunciado de cada pregunta y al menos una pregunta, porque la evaluación y el foco del lector los necesitan.

## Estructura de archivos

| Archivo | Acción | Responsabilidad | Tareas |
| --- | --- | --- | --- |
| `lib/models/specialty_test_models.dart` | crear | Modelos del contrato, con `tryFromJson` que conservan los `null` y la validación del contenido | 1 |
| `lib/configs/themes.dart` | modificar | Los 17 tokens de RF-TEST-12 | 2 |
| `lib/pages/specialty_test/specialty_test_logic.dart` | crear | Funciones puras de color y contraste, íconos, conversación, selección y fecha | 2 a 5 |
| `lib/services/specialty_test_service.dart` | crear | Capa de datos, plazos, guarda por dueño, precarga, pausa y último resultado | 6 |
| `lib/services/auth_service.dart` | modificar | Catálogo fallido, ids oficiales, reintento, plazo de `completeSetup`, `clear()` en `logout()` | 7 |
| `lib/main.dart` | modificar | Registro del service, ruta del test y binding del asistente | 7, 15 y 18 |
| `lib/pages/specialty_test/specialty_test_controller.dart` | crear | El recorrido, la evaluación, los guardados y el puerto de pantalla | 8 a 10 |
| `lib/pages/specialty_test/widgets/test_buttons.dart` | crear | Botones y mensaje de error compartidos | 11 |
| `lib/pages/specialty_test/widgets/ulises_bubble.dart` | crear | Avatar, burbuja, sello y turno de Ulises | 11 |
| `lib/pages/specialty_test/widgets/welcome_view.dart` | crear | La bienvenida | 11 |
| `lib/pages/specialty_test/widgets/task_icon.dart` | crear | La baldosa del ícono de la tarea | 12 |
| `lib/pages/specialty_test/widgets/question_view.dart` | crear | Barra, plumas, historial, duelo, escala y desempate | 12 |
| `lib/pages/specialty_test/widgets/waiting_view.dart` | crear | La espera y su error | 13 |
| `lib/pages/specialty_test/widgets/electives_sheet.dart` | crear | La hoja de electivos | 14 |
| `lib/pages/specialty_test/widgets/result_view.dart` | crear | El resultado, la hoja del empate y el confeti | 14 |
| `lib/pages/specialty_test/specialty_test_page.dart` | crear | La ruta por fase, el atrás del sistema y `UiDelTestConGet` | 15 |
| `lib/pages/specialty_test/specialty_test_binding.dart` | crear | El binding por ruta con el origen | 15 |
| `lib/pages/specialty_test/specialty_test_profile_card.dart` | crear | La tarjeta del Perfil | 16 |
| `lib/pages/perfil/perfil.dart` | modificar | La tarjeta montada con guarda, lo oficial en «Especialización» y el catálogo fallido | 16 y 17 |
| `lib/pages/setup_carrera/setup_carrera_binding.dart` | crear | El binding por ruta del asistente | 18 |
| `lib/pages/setup_carrera/setup_carrera_controller.dart` | reemplazar | Carrera, test y selección manual, con la precarga | 18 |
| `lib/pages/setup_carrera/setup_carrera_page.dart` | reemplazar | Tokens, estados de catálogo, atrás, botón nuevo y cabecera | 18 |
| `test/HU36_jeff/datos_de_prueba.dart` | crear | Contenido, resultados y alumno inventados | 1 |
| `test/HU36_jeff/dobles_de_red.dart` | crear | `ApiFalsaDelTest`, `AuthConUsuario` y `AlmacenDePrueba` | 6 |
| `test/HU36_jeff/dobles_del_controlador.dart` | crear | `AuthDelControlador`, `UiFalsa` y ayudas del controlador | 8 |
| `test/HU36_jeff/montaje_de_pantallas.dart` | crear | Montaje con tema, tamaño, escala, lector y movimiento, Roboto y la ruta real | 11 y 15 |
| `test/HU36_jeff/*_test.dart` | crear | Las 16 pruebas de «Pruebas por requisito» | 1 a 18 |
| Spec, enmienda, índice y contrato | modificar | Estado y `[@test]` | 19 |

Los archivos de apoyo de `test/HU36_jeff/` no terminan en `_test.dart`, así que `flutter test` no los corre como suites.

## Orden y cobertura

Las tareas van en orden y en la misma rama. Cada una deja la suite en verde.

| Requisito | Tareas | Pruebas |
| --- | --- | --- |
| RF-TEST-1 | 6, 8, 15 y 18 | `setup_carrera_flujo_test.dart`, `specialty_test_bienvenida_test.dart` y `specialty_test_conversacion_test.dart` |
| RF-TEST-2 | 1, 4, 6 y 7 | `specialty_test_models_test.dart`, `specialty_test_service_test.dart` y `specialty_test_logic_test.dart` |
| RF-TEST-3 | 8 y 11 | `specialty_test_bienvenida_test.dart` |
| RF-TEST-4 | 4, 8, 9, 12 y 15 | `specialty_test_conversacion_test.dart` y `specialty_test_logic_test.dart` |
| RF-TEST-5 y RF-TEST-6 | 3 y 12 | `specialty_test_preguntas_test.dart` y `specialty_test_logic_test.dart` |
| RF-TEST-7 | 9 y 13 | `specialty_test_evaluacion_test.dart` |
| RF-TEST-8 | 14 y 15 | `specialty_test_resultado_test.dart` |
| RF-TEST-9 | 5, 10 y 14 | `specialty_test_eleccion_test.dart` y `specialty_test_logic_test.dart` |
| RF-TEST-10 | 5 y 16 | `specialty_test_perfil_test.dart` y `specialty_test_logic_test.dart` |
| RF-TEST-11 | 8, 9, 10, 13 y 15 | `specialty_test_errores_test.dart` y `specialty_test_evaluacion_test.dart` |
| RF-TEST-12 | 2 y todas las vistas | `specialty_test_contraste_test.dart` |
| RF-TEST-13 | 11 a 14 | `specialty_test_accesibilidad_test.dart` |
| RF-TEST-14 | 5, 7, 17 y 18 | `perfil_especialidad_antigua_test.dart`, `specialty_test_logic_test.dart`, `specialty_test_service_test.dart` y `setup_carrera_flujo_test.dart` |
| Documentos | 19 | Búsquedas del Paso 4 de la Tarea 19 |

---

### Tarea 1: Modelos del contrato

**Requisitos:** RF-TEST-2 (modelos, contenido utilizable y `null` conservados).

**Archivos:**
- Crear `lib/models/specialty_test_models.dart`
- Crear `test/HU36_jeff/datos_de_prueba.dart` (datos inventados que comparten las pruebas)
- Crear `test/HU36_jeff/specialty_test_models_test.dart`

**Interfaces:**

- No consume nada del repo. El archivo no importa Flutter ni GetX.
- Produce lo que sigue, que usan todas las tareas siguientes.

```dart
// lib/models/specialty_test_models.dart
class TestElective { String code, name; String? shortName; int? credits;
  String? prerequisite; String get displayName; }
class TestSpecialty { String key; int specialtyId; String name, colorLight,
  colorDark; String? tagline, icon; int? totalCredits;
  List<TestElective> electives; }
class TestTask { String id, specialty, text; String? icon; }
enum TestQuestionType { duel, scale }
class TestQuestion { String id; int? n; TestQuestionType type; String prompt;
  TestTask? top, bottom, task; String? reaction, blockClose;
  bool get isDuel; List<TestTask> get tasks; }
class TestOption { String id, label; }
class UlisesReactions { List<String> pick, both, none, scale; }
class UlisesLines { List<String> welcome; String? duelHelp, scaleHelp,
  loading; UlisesReactions reactions; }
class SpecialtyTestContent { String version; List<TestSpecialty> specialties;
  UlisesLines ulises; List<TestOption> duelOptions, scaleOptions;
  List<TestQuestion> questions; int get totalQuestions;
  TestSpecialty? specialtyByKey(String key); String? optionLabel(String id);
  static SpecialtyTestContent? tryParse(Object? json); }
class TiebreakAnswer { String id, answer; Map<String, dynamic> toJson(); }
class TestTiebreak { String id; int order; String prompt; TestTask top, bottom; }
class TiebreakRecord { TestTiebreak tiebreak; String? ulisesLine, answer;
  TiebreakRecord withAnswer(String? answer); }
class RankingEntry { String key; int specialtyId; String name; int affinity; }
class SpecialtyTestResult { String? version; DateTime? completedAt; bool tie;
  List<RankingEntry> ranking; String? reason, reasonSource, headline,
  tiebreakOutcome; bool get reasonByAi; List<RankingEntry> get winners,
  others; }
sealed class EvaluationStep { static EvaluationStep? tryParse(Object? json); }
class TiebreakStep extends EvaluationStep { TestTiebreak tiebreak;
  String? ulisesLine; }
class ResultStep extends EvaluationStep { SpecialtyTestResult result; }
class LastSpecialtyTestResult { String? version; bool? isCurrentVersion;
  DateTime? completedAt; bool tie; List<RankingEntry> ranking;
  List<RankingEntry> get winners, others;
  static LastSpecialtyTestResult? tryParse(Object? json); }
```

```dart
// test/HU36_jeff/datos_de_prueba.dart
const String kVersionDePrueba; const List<String> kBienvenida, kPick, kBoth,
  kNone, kScale; const String kDuelHelp, kScaleHelp, kLoading, kMotivoLargo;
const int kIdSw = 1, kIdTi = 5, kIdSi = 6, kIdVj = 7;
Map<String, dynamic> contenidoJson({String version, String? iconoDeLaPrimera});
Map<String, String> respuestasCompletas();
Map<String, dynamic> desempateJson({int order = 1, String id = 'tb-si-vj-1'});
List<Map<String, dynamic>> rankingJson({bool empate = false});
Map<String, dynamic> resultadoJson({bool empate, String reasonSource,
  String motivo, String? headline, String? tiebreakOutcome});
Map<String, dynamic> ultimoResultadoJson({bool empate, bool? isCurrentVersion,
  String completedAt});
UserModel alumno({String code = '20230001', int? principal,
  List<int>? intereses, bool setupComplete = true, String role = 'student'});
```

- [ ] **Paso 1: Comprobar la rama y la línea base**

Este paso va antes de tocar nada. La spec ya está aprobada y sus `targets` cubren todos los archivos del plan, así que no hace falta otro paso de aprobación.

Desde `757a9af`, la línea principal de la rama puede traer uno o más commits antes de la Tarea 1, siempre que cada uno toque solo el plan o la spec del test o sea un merge que trae `main`, como el de `19fed1b`. El bucle revisa cada commit de esa línea y avisa con `PARAR` si uno toca otro archivo o si un merge trae algo que no está en `origin/main`.

```bash
cd "${REPO:?}"
test "$(git branch --show-current)" = feat/test-especialidad-fe || echo 'PARAR: rama equivocada'
git status --short
git merge-base --is-ancestor 757a9af HEAD || echo 'PARAR: la rama no parte de 757a9af'
git rev-list --first-parent 757a9af..HEAD | while read -r c; do
  if git rev-parse -q --verify "$c^2" >/dev/null; then
    git merge-base --is-ancestor "$c^2" origin/main \
      || echo "PARAR: el merge $c no trae main"
  else
    git diff-tree --no-commit-id --name-only -r "$c" \
      | grep -vx -e docs/superpowers/plans/2026-09-25-specialty-test-app.md \
        -e specs/features/specialty-test/specialty-test.spec.md \
      && echo "PARAR: $c toca algo más que el plan y la spec"
  fi
done
git log --oneline --first-parent 757a9af..HEAD
test -d .dart_tool || "${FLUTTER:?}" pub get
"${FLUTTER:?}" analyze --no-pub
```

Esperado: ningún `PARAR`, `git status --short` vacío, un `git log` cuyo commit más antiguo es el de este plan, `cabfb43`, con encima solo commits del plan o de la spec y merges de `main`, y `6 issues found.`, la lista de «Línea base».

- [ ] **Paso 2: Escribir los datos de prueba y la prueba que falla**

Los datos son un recorte inventado de cinco preguntas con la forma de la `2026-09-25.4`. Las líneas de Ulises son las de esa versión, porque RF-TEST-3 mide la bienvenida con sus cuatro líneas, y las tareas, los electivos y los resultados son inventados. El nombre del archivo no termina en `_test.dart`, así que `flutter test` no lo corre como suite.

Crea `test/HU36_jeff/datos_de_prueba.dart` con este contenido.

```dart
// test/HU36_jeff/datos_de_prueba.dart
//
// Datos de prueba del test de especialidad (HU36). No es un archivo de
// pruebas, y lo importan las pruebas de esta carpeta.
//
// El contenido es un recorte inventado de cinco preguntas con la forma de la
// versión 2026-09-25.4. Las líneas de Ulises son las de esa versión, porque
// RF-TEST-3 pide medir la bienvenida con sus cuatro líneas; las tareas, los
// electivos y los resultados son inventados. Los `specialtyId` son
// ilustrativos, como en el contrato. El alumno de prueba es 20230001.

import 'package:ulima_plus/models/user_model.dart';

const String kVersionDePrueba = '2026-09-25.4';

/// Las cuatro líneas de bienvenida de la versión 2026-09-25.4.
const List<String> kBienvenida = <String>[
  '¡Hola! Soy Ulises. Te voy a mostrar tareas de verdad, de las que se hacen '
      'en cada especialidad, y tú eliges cuál harías con más ganas.',
  'Son 14 preguntas, a veces una o dos más para desempatar, y te toma unos '
      'tres minutos. No hay respuestas buenas ni malas.',
  'Piensa en lo que harías con gusto un día cualquiera, no en lo que suena '
      'más importante.',
  'Si te gustan las dos, dilo. Si ninguna te llama, también vale.',
];

const String kDuelHelp = 'Toca la tarea que harías con más ganas.';
const String kScaleHelp = 'Elige cuánto te gustaría hacer esta tarea.';
const String kLoading = 'Dame un toque que junto tus respuestas.';
const List<String> kPick = <String>[
  'Anotado.',
  '¡Cra!',
  'Listo.',
  'Ya, siguiente.',
  'Lo apunto.',
  'Sigamos.',
  'Tomo nota.',
];
const List<String> kBoth = <String>[
  'Las dos, ¿no? Eso también cuenta.',
  'Ya, medio punto para cada una.',
];
const List<String> kNone = <String>[
  'Ninguna, ya. También me sirve saberlo.',
  'Ok, ninguna de las dos era lo tuyo.',
];
const List<String> kScale = <String>['Anotado.', 'Lo tengo.', '¡Cra!'];

/// Ids ilustrativos de las cuatro especialidades.
const int kIdSw = 1;
const int kIdTi = 5;
const int kIdSi = 6;
const int kIdVj = 7;

Map<String, dynamic> _tarea(
  String id,
  String especialidad,
  String texto,
  String? icono,
) => <String, dynamic>{
  'id': id,
  'specialty': especialidad,
  'text': texto,
  'illustration': 'Descripción de prueba que la app no muestra.',
  'icon': ?icono,
};

Map<String, dynamic> _especialidad(
  String clave,
  int id,
  String nombre,
  String claro,
  String oscuro,
  String icono,
  List<Map<String, dynamic>> electivos,
) => <String, dynamic>{
  'key': clave,
  'specialtyId': id,
  'name': nombre,
  'tagline': 'Frase de prueba de $nombre.',
  'color': <String, dynamic>{'light': claro, 'dark': oscuro},
  'icon': icono,
  'totalCredits': 21,
  'electives': electivos,
};

Map<String, dynamic> _electivo(String codigo, String letra) =>
    <String, dynamic>{
      'code': codigo,
      'name': 'ELECTIVO DE PRUEBA $letra',
      'shortName': 'Electivo $letra',
      'credits': 3,
      'prerequisite': 'Haber culminado el V ciclo',
    };

/// El contenido de prueba, con cinco preguntas, dos de ellas escalas con
/// `blockClose`, así que el sello cuenta hasta 2. La 1 y la 4 traen reacción
/// propia; la 2 no, y usa la lista de reacciones.
Map<String, dynamic> contenidoJson({
  String version = kVersionDePrueba,
  String? iconoDeLaPrimera = 'shopping-cart',
}) => <String, dynamic>{
  'version': version,
  'specialties': <dynamic>[
    _especialidad(
      'sw',
      kIdSw,
      'Ingeniería de Software',
      '#1E3A8A',
      '#A5C0F7',
      'code-xml',
      [
        _electivo('900101', 'A'),
        _electivo('900102', 'B'),
        _electivo('900103', 'C'),
      ],
    ),
    _especialidad(
      'ti',
      kIdTi,
      'Tecnologías de la Información',
      '#0F7A45',
      '#7EE8BE',
      'server-cog',
      [_electivo('900201', 'D')],
    ),
    _especialidad(
      'si',
      kIdSi,
      'Sistemas de Información',
      '#9333EA',
      '#B98AF8',
      'chart-column-big',
      [_electivo('900301', 'E'), _electivo('900302', 'F')],
    ),
    _especialidad(
      'vj',
      kIdVj,
      'Desarrollo de Videojuegos',
      '#76164A',
      '#EC7FB3',
      'gamepad-2',
      [_electivo('900401', 'G'), _electivo('900402', 'H')],
    ),
  ],
  'ulises': <String, dynamic>{
    'welcome': kBienvenida,
    'startButton': 'Vamos',
    'duelHelp': kDuelHelp,
    'scaleHelp': kScaleHelp,
    'reactions': <String, dynamic>{
      'pick': kPick,
      'both': kBoth,
      'none': kNone,
      'scale': kScale,
    },
    'loading': kLoading,
  },
  'duelOptions': <dynamic>[
    <String, dynamic>{'id': 'top', 'label': '(tarea de arriba)'},
    <String, dynamic>{'id': 'bottom', 'label': '(tarea de abajo)'},
    <String, dynamic>{'id': 'both', 'label': 'Me gustan las dos'},
    <String, dynamic>{'id': 'none', 'label': 'Ninguna me llama'},
  ],
  'scaleOptions': <dynamic>[
    <String, dynamic>{'id': 'nada', 'label': 'Nada'},
    <String, dynamic>{'id': 'un_poco', 'label': 'Un poco'},
    <String, dynamic>{'id': 'bastante', 'label': 'Bastante'},
    <String, dynamic>{'id': 'me_encantaria', 'label': 'Me encantaría'},
  ],
  'questions': <dynamic>[
    <String, dynamic>{
      'id': 'q01',
      'n': 1,
      'type': 'duel',
      'prompt': '¿Cuál harías con más ganas?',
      'top': _tarea(
        'q01.top',
        'sw',
        'Tarea de prueba uno arriba',
        iconoDeLaPrimera,
      ),
      'bottom': _tarea(
        'q01.bottom',
        'si',
        'Tarea de prueba uno abajo',
        'shelving-unit',
      ),
      'reaction': 'Reacción propia de la pregunta uno.',
    },
    <String, dynamic>{
      'id': 'q02',
      'n': 2,
      'type': 'duel',
      'prompt': '¿Y entre estas dos?',
      'top': _tarea(
        'q02.top',
        'ti',
        'Tarea de prueba dos arriba',
        'refrigerator',
      ),
      'bottom': _tarea(
        'q02.bottom',
        'vj',
        'Tarea de prueba dos abajo',
        'mountain',
      ),
    },
    <String, dynamic>{
      'id': 'q03',
      'n': 3,
      'type': 'scale',
      'prompt': '¿Cuánto te gustaría hacer esto?',
      'task': _tarea(
        'q03.task',
        'vj',
        'Tarea de prueba tres en escala',
        'smartphone',
      ),
      'blockClose': 'Cierre de prueba del bloque uno.',
    },
    <String, dynamic>{
      'id': 'q04',
      'n': 4,
      'type': 'duel',
      'prompt': '¿Cuál de estas elegirías?',
      'top': _tarea('q04.top', 'sw', 'Tarea de prueba cuatro arriba', 'route'),
      'bottom': _tarea(
        'q04.bottom',
        'ti',
        'Tarea de prueba cuatro abajo',
        'school',
      ),
      'reaction': 'Reacción propia de la pregunta cuatro.',
    },
    <String, dynamic>{
      'id': 'q05',
      'n': 5,
      'type': 'scale',
      'prompt': '¿Cuánto te gustaría hacer esta otra?',
      'task': _tarea(
        'q05.task',
        'si',
        'Tarea de prueba cinco en escala',
        'user-minus',
      ),
      'blockClose': 'Cierre de prueba del bloque dos.',
    },
  ],
};

/// Las respuestas completas de [contenidoJson].
Map<String, String> respuestasCompletas() => <String, String>{
  'q01': 'top',
  'q02': 'both',
  'q03': 'bastante',
  'q04': 'none',
  'q05': 'nada',
};

/// Un paso de desempate de `POST /specialty-test/me/evaluate`.
Map<String, dynamic> desempateJson({
  int order = 1,
  String id = 'tb-si-vj-1',
}) => <String, dynamic>{
  'status': 'tiebreak',
  'tiebreak': <String, dynamic>{
    'id': id,
    'order': order,
    'prompt': '¿Cuál harías con más ganas?',
    'top': _tarea('$id.top', 'si', 'Tarea de desempate $order arriba', 'soup'),
    'bottom': _tarea(
      '$id.bottom',
      'vj',
      'Tarea de desempate $order abajo',
      'map-pinned',
    ),
  },
  'ulisesLine': order == 1
      ? 'Tienes dos especialidades muy parejas. Te hago una pregunta más '
            'para desempatar.'
      : 'Sigue reñido. Una última y listo.',
};

Map<String, dynamic> _fila(String clave, int id, String nombre, int afinidad) =>
    <String, dynamic>{
      'key': clave,
      'specialtyId': id,
      'name': nombre,
      'affinity': afinidad,
    };

/// El ranking de prueba, en el que Videojuegos gana con 75.
List<Map<String, dynamic>> rankingJson({bool empate = false}) => empate
    ? [
        _fila('si', kIdSi, 'Sistemas de Información', 62),
        _fila('vj', kIdVj, 'Desarrollo de Videojuegos', 62),
        _fila('ti', kIdTi, 'Tecnologías de la Información', 30),
        _fila('sw', kIdSw, 'Ingeniería de Software', 24),
      ]
    : [
        _fila('vj', kIdVj, 'Desarrollo de Videojuegos', 75),
        _fila('si', kIdSi, 'Sistemas de Información', 65),
        _fila('ti', kIdTi, 'Tecnologías de la Información', 28),
        _fila('sw', kIdSw, 'Ingeniería de Software', 24),
      ];

/// Motivo inventado de 330 caracteres, largo como los de las plantillas.
const String kMotivoLargo =
    'Desarrollo de Videojuegos sumó la mayor parte de los puntos de los '
    'duelos de prueba y la escala de prueba le dio un empujón más. Las '
    'tareas que elegiste tienen en común pensar en quien juega, probar '
    'ideas rápido y ajustar reglas hasta que la experiencia funcione, que '
    'es justo lo que se trabaja en sus electivos de prueba durante el ciclo.';

/// Un paso de resultado de `POST /specialty-test/me/evaluate`.
Map<String, dynamic> resultadoJson({
  bool empate = false,
  String reasonSource = 'templates',
  String motivo = kMotivoLargo,
  String? headline,
  String? tiebreakOutcome,
}) => <String, dynamic>{
  'status': 'result',
  'result': <String, dynamic>{
    'version': kVersionDePrueba,
    'completedAt': '2026-09-25T20:15:00.000Z',
    'tie': empate,
    'ranking': rankingJson(empate: empate),
    'reason': motivo,
    'reasonSource': reasonSource,
    'ulises': <String, dynamic>{
      'intro': 'Ya tengo tu resultado.',
      'headline':
          headline ??
          (empate
              ? 'Empate. Sistemas de Información y Desarrollo de Videojuegos '
                    'quedaron igualitas, con 62 %.'
              : 'Lo tuyo apunta a Desarrollo de Videojuegos, con 75 % de '
                    'afinidad.'),
      'tiebreakOutcome': tiebreakOutcome,
      'closing': 'Línea de cierre que la app no pinta.',
      'retake': 'Línea de rehacer que la app no pinta.',
    },
  },
};

/// `GET /specialty-test/me/result` con un resultado. Las 03:30 UTC del 26 son
/// las 22:30 del 25 en Lima.
Map<String, dynamic> ultimoResultadoJson({
  bool empate = false,
  bool? isCurrentVersion = true,
  String completedAt = '2026-09-26T03:30:00.000Z',
}) => <String, dynamic>{
  'result': <String, dynamic>{
    'version': kVersionDePrueba,
    'isCurrentVersion': ?isCurrentVersion,
    'completedAt': completedAt,
    'tie': empate,
    'ranking': rankingJson(empate: empate),
  },
};

/// El alumno de prueba.
UserModel alumno({
  String code = '20230001',
  int? principal,
  List<int>? intereses,
  bool setupComplete = true,
  String role = 'student',
}) => UserModel(
  code: code,
  firstName: 'Alumna',
  lastName: 'De Prueba',
  email: 'test@aloe.ulima.edu.pe',
  role: role,
  careerId: 1,
  especialidadPrincipal: principal,
  especialidadesInteres: intereses,
  currentCycle: '2026-2',
  setupComplete: setupComplete,
);
```

Crea `test/HU36_jeff/specialty_test_models_test.dart` con este contenido.

```dart
// test/HU36_jeff/specialty_test_models_test.dart
//
// Pruebas unitarias de HU36, el test de especialidad, sobre los modelos del
// contrato (RF-TEST-2).
// Modelo: lib/models/specialty_test_models.dart
//
// Datos inventados (datos_de_prueba.dart). Las líneas de Ulises son las de la
// versión 2026-09-25.4.

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/models/specialty_test_models.dart';

import 'datos_de_prueba.dart';

/// Un contenido nuevo en cada llamada, para romperlo sin tocar otro.
Map<String, dynamic> _contenido() => contenidoJson();

List<dynamic> _preguntas(Map<String, dynamic> c) => c['questions'] as List;

Map<String, dynamic> _especialidad(Map<String, dynamic> c, int i) =>
    (c['specialties'] as List)[i] as Map<String, dynamic>;

void main() {
  group('UNITARIA · Contenido del test (RF-TEST-2)', () {
    test('caso 1: el contenido completo se lee tal como llega', () {
      final c = SpecialtyTestContent.tryParse(_contenido())!;
      expect(c.version, kVersionDePrueba);
      expect(c.specialties.map((s) => s.key), ['sw', 'ti', 'si', 'vj']);
      final sw = c.specialtyByKey('sw')!;
      expect(sw.specialtyId, kIdSw);
      expect(sw.name, 'Ingeniería de Software');
      expect(sw.colorLight, '#1E3A8A');
      expect(sw.colorDark, '#A5C0F7');
      expect(sw.icon, 'code-xml');
      expect(sw.totalCredits, 21);
      expect(sw.electives, hasLength(3));
      expect(sw.electives.first.code, '900101');
      expect(sw.electives.first.displayName, 'Electivo A');
      expect(sw.electives.first.credits, 3);
      expect(sw.electives.first.prerequisite, 'Haber culminado el V ciclo');
      expect(c.ulises.welcome, kBienvenida);
      expect(c.ulises.duelHelp, kDuelHelp);
      expect(c.ulises.scaleHelp, kScaleHelp);
      expect(c.ulises.reactions.pick, kPick);
      expect(c.ulises.reactions.both, kBoth);
      expect(c.ulises.reactions.none, kNone);
      expect(c.ulises.reactions.scale, kScale);
      expect(c.ulises.loading, kLoading);
      expect(c.optionLabel('both'), 'Me gustan las dos');
      expect(c.optionLabel('none'), 'Ninguna me llama');
      expect(c.scaleOptions.map((o) => o.id), [
        'nada',
        'un_poco',
        'bastante',
        'me_encantaria',
      ]);
      expect(c.totalQuestions, 5);
      final q1 = c.questions.first;
      expect(q1.id, 'q01');
      expect(q1.n, 1);
      expect(q1.isDuel, isTrue);
      expect(q1.top!.id, 'q01.top');
      expect(q1.top!.specialty, 'sw');
      expect(q1.top!.icon, 'shopping-cart');
      expect(q1.bottom!.specialty, 'si');
      expect(q1.reaction, 'Reacción propia de la pregunta uno.');
      final q3 = c.questions[2];
      expect(q3.type, TestQuestionType.scale);
      expect(q3.task!.id, 'q03.task');
      expect(q3.tasks, hasLength(1));
      expect(q3.blockClose, 'Cierre de prueba del bloque uno.');
    });

    test('caso 2: los null se conservan y no se inventan textos ni ceros', () {
      final json = _contenido();
      final sw = _especialidad(json, 0);
      sw.remove('tagline');
      sw.remove('totalCredits');
      ((sw['electives'] as List).first as Map).remove('credits');
      final c = SpecialtyTestContent.tryParse(json)!;
      expect(c.questions[1].reaction, isNull);
      expect(c.questions[1].blockClose, isNull);
      expect(c.specialties.first.tagline, isNull);
      expect(c.specialties.first.totalCredits, isNull);
      expect(c.specialties.first.electives.first.credits, isNull);
    });

    test('caso 3: un contenido roto se rechaza entero', () {
      final rotos = <String, Map<String, dynamic>>{
        'sin versión': _contenido()..remove('version'),
        'tipo desconocido': _contenido()
          ..update('questions', (q) => q..[0]['type'] = 'ranking'),
        'duelo sin bottom': _contenido()
          ..update('questions', (q) => q..[0].remove('bottom')),
        'escala sin task': _contenido()
          ..update('questions', (q) => q..[2].remove('task')),
        'tarea sin id': _contenido()
          ..update('questions', (q) => q..[0]['top'].remove('id')),
        'tarea sin texto': _contenido()
          ..update('questions', (q) => q..[0]['top'].remove('text')),
        'clave fuera de las especialidades': _contenido()
          ..update('questions', (q) => q..[0]['top']['specialty'] = 'xx'),
        'especialidad sin specialtyId': _contenido()
          ..update('specialties', (s) => s..[0].remove('specialtyId')),
        'especialidad sin nombre': _contenido()
          ..update('specialties', (s) => s..[1].remove('name')),
        'especialidad sin color oscuro': _contenido()
          ..update('specialties', (s) => s..[2]['color'].remove('dark')),
        'tres opciones de escala': _contenido()
          ..update('scaleOptions', (o) => (o as List).sublist(0, 3)),
        'duelo sin none': _contenido()
          ..update('duelOptions', (o) => (o as List).sublist(0, 3)),
        'sin preguntas': _contenido()..['questions'] = <dynamic>[],
      };
      for (final caso in rotos.entries) {
        expect(
          SpecialtyTestContent.tryParse(caso.value),
          isNull,
          reason: caso.key,
        );
      }
      expect(SpecialtyTestContent.tryParse(null), isNull);
      expect(SpecialtyTestContent.tryParse('texto'), isNull);
    });

    test('caso 4: un hex que no se puede leer no invalida el contenido', () {
      final json = _contenido();
      (_especialidad(json, 0)['color'] as Map)['light'] = 'naranja';
      final c = SpecialtyTestContent.tryParse(json)!;
      expect(c.specialties.first.colorLight, 'naranja');
    });

    test(
      'caso 5: un icon ausente o fuera del mapa no invalida el contenido',
      () {
        final sinIcono = SpecialtyTestContent.tryParse(
          contenidoJson(iconoDeLaPrimera: null),
        )!;
        expect(sinIcono.questions.first.top!.icon, isNull);
        final desconocido = SpecialtyTestContent.tryParse(
          contenidoJson(iconoDeLaPrimera: 'icono-que-no-existe'),
        )!;
        expect(desconocido.questions.first.top!.icon, 'icono-que-no-existe');
        final json = _contenido();
        _especialidad(json, 3).remove('icon');
        expect(
          SpecialtyTestContent.tryParse(json)!.specialties.last.icon,
          isNull,
        );
      },
    );

    test('caso 6: la app no fija el número de preguntas ni la versión', () {
      final json = contenidoJson(version: '2027-01-10.1');
      _preguntas(json).removeLast();
      final c = SpecialtyTestContent.tryParse(json)!;
      expect(c.version, '2027-01-10.1');
      expect(c.totalQuestions, 4);
    });
  });

  group('UNITARIA · Paso de la evaluación (RF-TEST-2)', () {
    test('caso 7: un desempate se lee con su orden, sus tareas y la línea', () {
      final paso = EvaluationStep.tryParse(desempateJson(order: 2));
      expect(paso, isA<TiebreakStep>());
      final d = (paso! as TiebreakStep).tiebreak;
      expect(d.id, 'tb-si-vj-1');
      expect(d.order, 2);
      expect(d.top.id, 'tb-si-vj-1.top');
      expect(d.top.icon, 'soup');
      expect(d.bottom.specialty, 'vj');
      expect(
        (paso as TiebreakStep).ulisesLine,
        'Sigue reñido. Una última y listo.',
      );
    });

    test('caso 8: un resultado se lee entero y tiebreakOutcome sigue null', () {
      final paso = EvaluationStep.tryParse(resultadoJson());
      expect(paso, isA<ResultStep>());
      final r = (paso! as ResultStep).result;
      expect(r.version, kVersionDePrueba);
      expect(r.completedAt, DateTime.utc(2026, 9, 25, 20, 15));
      expect(r.tie, isFalse);
      expect(r.ranking.map((e) => e.key), ['vj', 'si', 'ti', 'sw']);
      expect(r.ranking.first.specialtyId, kIdVj);
      expect(r.ranking.first.affinity, 75);
      expect(r.reason, kMotivoLargo);
      expect(r.reasonSource, 'templates');
      expect(r.reasonByAi, isFalse);
      expect(
        r.headline,
        'Lo tuyo apunta a Desarrollo de Videojuegos, con 75 % de afinidad.',
      );
      expect(r.tiebreakOutcome, isNull);
      expect(r.winners.map((e) => e.key), ['vj']);
      expect(r.others.map((e) => e.key), ['si', 'ti', 'sw']);
    });

    test('caso 9: con empate, las ganadoras son las dos primeras', () {
      final r =
          (EvaluationStep.tryParse(
                    resultadoJson(empate: true, reasonSource: 'ai'),
                  )!
                  as ResultStep)
              .result;
      expect(r.tie, isTrue);
      expect(r.reasonByAi, isTrue);
      expect(r.winners.map((e) => e.key), ['si', 'vj']);
      expect(r.others.map((e) => e.key), ['ti', 'sw']);
    });

    test('caso 10: un paso roto no se lee', () {
      expect(EvaluationStep.tryParse({'status': 'otro'}), isNull);
      final sinAfinidad = resultadoJson();
      ((sinAfinidad['result'] as Map)['ranking'] as List).first.remove(
        'affinity',
      );
      expect(EvaluationStep.tryParse(sinAfinidad), isNull);
      final fueraDeRango = resultadoJson();
      ((fueraDeRango['result'] as Map)['ranking'] as List).first['affinity'] =
          101;
      expect(EvaluationStep.tryParse(fueraDeRango), isNull);
      final sinTie = resultadoJson();
      (sinTie['result'] as Map).remove('tie');
      expect(EvaluationStep.tryParse(sinTie), isNull);
      final desempateSinTop = desempateJson();
      (desempateSinTop['tiebreak'] as Map).remove('top');
      expect(EvaluationStep.tryParse(desempateSinTop), isNull);
    });

    test('caso 11: el desempate respondido viaja como {id, answer}', () {
      expect(
        const TiebreakAnswer(id: 'tb-si-vj-1', answer: 'bottom').toJson(),
        {'id': 'tb-si-vj-1', 'answer': 'bottom'},
      );
    });

    test('caso 11b: un desempate en memoria cambia de respuesta sin perder '
        'su tarea ni su línea', () {
      final paso = EvaluationStep.tryParse(desempateJson())! as TiebreakStep;
      final registro = TiebreakRecord(
        tiebreak: paso.tiebreak,
        ulisesLine: paso.ulisesLine,
      );
      expect(registro.answer, isNull);
      final respondido = registro.withAnswer('top');
      expect(respondido.answer, 'top');
      expect(respondido.tiebreak.id, 'tb-si-vj-1');
      expect(respondido.ulisesLine, paso.ulisesLine);
    });
  });

  group('UNITARIA · Último resultado (RF-TEST-2 y RF-TEST-10)', () {
    test('caso 12: se lee con su versión, su fecha y su ranking', () {
      final r = LastSpecialtyTestResult.tryParse(
        ultimoResultadoJson()['result'],
      )!;
      expect(r.version, kVersionDePrueba);
      expect(r.isCurrentVersion, isTrue);
      expect(r.completedAt, DateTime.utc(2026, 9, 26, 3, 30));
      expect(r.tie, isFalse);
      expect(r.winners.single.key, 'vj');
      expect(r.others, hasLength(3));
    });

    test('caso 13: isCurrentVersion ausente queda null, no false', () {
      final r = LastSpecialtyTestResult.tryParse(
        ultimoResultadoJson(isCurrentVersion: null)['result'],
      )!;
      expect(r.isCurrentVersion, isNull);
      final viejo = LastSpecialtyTestResult.tryParse(
        ultimoResultadoJson(isCurrentVersion: false)['result'],
      )!;
      expect(viejo.isCurrentVersion, isFalse);
    });

    test('caso 14: un resultado sin ranking no se lee', () {
      final json = ultimoResultadoJson()['result'] as Map<String, dynamic>;
      json['ranking'] = <dynamic>[];
      expect(LastSpecialtyTestResult.tryParse(json), isNull);
    });
  });
}
```

- [ ] **Paso 3: Correr la prueba y ver que falla**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/HU36_jeff/specialty_test_models_test.dart
```

Esperado: FALLA al compilar, sin llegar a correr ningún caso. La salida trae 34 errores distintos (líneas `Error:`), y los primeros dicen esto (las rutas pueden salir absolutas).

```text
test/HU36_jeff/specialty_test_models_test.dart:26:17: Error: Undefined name 'SpecialtyTestContent'.
test/HU36_jeff/specialty_test_models_test.dart:68:23: Error: Undefined name 'TestQuestionType'.
```

- [ ] **Paso 4: Escribir los modelos**

Cada `tryFromJson` conserva los `null` y no inventa ceros ni textos. `SpecialtyTestContent.tryParse` rechaza el contenido entero si falta algo de lo que pide RF-TEST-2, y además exige la versión, el id y el enunciado de cada pregunta y al menos una pregunta (decisión 10 del plan). Un hex que no se lee y un `icon` ausente o desconocido no lo invalidan.

Crea `lib/models/specialty_test_models.dart` con este contenido.

```dart
// lib/models/specialty_test_models.dart
// Modelos del contrato del test de especialidad (RF-TEST-2).
//
// Los `tryFromJson` conservan los `null` que manda el servidor y no inventan
// ceros ni textos. Lo que la app necesita para no pintar un test roto se
// comprueba en [SpecialtyTestContent.tryParse], [EvaluationStep.tryParse] y
// [LastSpecialtyTestResult.tryParse], que devuelven `null` si falta.

/// Un electivo de una especialidad, tal como lo manda el contenido.
class TestElective {
  const TestElective({
    required this.code,
    required this.name,
    this.shortName,
    this.credits,
    this.prerequisite,
  });

  final String code;
  final String name;
  final String? shortName;
  final int? credits;
  final String? prerequisite;

  /// El nombre corto si llega, o el nombre completo.
  String get displayName => shortName ?? name;

  static TestElective? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final code = _texto(json['code']);
    final name = _texto(json['name']);
    if (code == null || name == null) return null;
    return TestElective(
      code: code,
      name: name,
      shortName: _texto(json['shortName']),
      credits: _entero(json['credits']),
      prerequisite: _texto(json['prerequisite']),
    );
  }
}

/// Una de las cuatro especialidades del contenido.
class TestSpecialty {
  const TestSpecialty({
    required this.key,
    required this.specialtyId,
    required this.name,
    required this.colorLight,
    required this.colorDark,
    this.tagline,
    this.icon,
    this.totalCredits,
    this.electives = const <TestElective>[],
  });

  /// `sw`, `ti`, `si` o `vj`.
  final String key;
  final int specialtyId;
  final String name;

  /// Hex `#RRGGBB` tal como llega. Si no se puede leer, cuenta como neutro
  /// (RF-TEST-12) y no invalida el contenido.
  final String colorLight;
  final String colorDark;
  final String? tagline;

  /// Nombre de Lucide en kebab-case, o null si no llega (RF-TEST-5).
  final String? icon;
  final int? totalCredits;
  final List<TestElective> electives;

  static TestSpecialty? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final key = _texto(json['key']);
    final specialtyId = _entero(json['specialtyId']);
    final name = _texto(json['name']);
    final color = json['color'];
    if (key == null || specialtyId == null || name == null || color is! Map) {
      return null;
    }
    final light = color['light'];
    final dark = color['dark'];
    if (light is! String || dark is! String) return null;
    final electivos = json['electives'];
    return TestSpecialty(
      key: key,
      specialtyId: specialtyId,
      name: name,
      colorLight: light,
      colorDark: dark,
      tagline: _texto(json['tagline']),
      icon: _texto(json['icon']),
      totalCredits: _entero(json['totalCredits']),
      electives: electivos is List
          ? electivos
                .map(TestElective.tryFromJson)
                .whereType<TestElective>()
                .toList(growable: false)
          : const <TestElective>[],
    );
  }
}

/// Una tarea de un duelo, de una escala o de un desempate.
class TestTask {
  const TestTask({
    required this.id,
    required this.specialty,
    required this.text,
    this.icon,
  });

  final String id;

  /// Clave de su especialidad. Solo enciende la tarjeta tocada (RF-TEST-5).
  final String specialty;
  final String text;
  final String? icon;

  static TestTask? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final id = _texto(json['id']);
    final specialty = _texto(json['specialty']);
    final text = _texto(json['text']);
    if (id == null || specialty == null || text == null) return null;
    return TestTask(
      id: id,
      specialty: specialty,
      text: text,
      icon: _texto(json['icon']),
    );
  }
}

enum TestQuestionType { duel, scale }

/// Una pregunta del contenido, que es un duelo con `top` y `bottom` o una
/// escala con `task`.
class TestQuestion {
  const TestQuestion({
    required this.id,
    required this.type,
    required this.prompt,
    this.n,
    this.top,
    this.bottom,
    this.task,
    this.reaction,
    this.blockClose,
  });

  final String id;
  final int? n;
  final TestQuestionType type;
  final String prompt;
  final TestTask? top;
  final TestTask? bottom;
  final TestTask? task;
  final String? reaction;
  final String? blockClose;

  bool get isDuel => type == TestQuestionType.duel;

  /// Las tareas de la pregunta, en el orden en que se pintan.
  List<TestTask> get tasks => isDuel ? [top!, bottom!] : [task!];

  static TestQuestion? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final id = _texto(json['id']);
    final prompt = _texto(json['prompt']);
    if (id == null || prompt == null) return null;
    final tipo = json['type'];
    if (tipo == 'duel') {
      final top = TestTask.tryFromJson(json['top']);
      final bottom = TestTask.tryFromJson(json['bottom']);
      if (top == null || bottom == null) return null;
      return TestQuestion(
        id: id,
        n: _entero(json['n']),
        type: TestQuestionType.duel,
        prompt: prompt,
        top: top,
        bottom: bottom,
        reaction: _texto(json['reaction']),
        blockClose: _texto(json['blockClose']),
      );
    }
    if (tipo == 'scale') {
      final task = TestTask.tryFromJson(json['task']);
      if (task == null) return null;
      return TestQuestion(
        id: id,
        n: _entero(json['n']),
        type: TestQuestionType.scale,
        prompt: prompt,
        task: task,
        reaction: _texto(json['reaction']),
        blockClose: _texto(json['blockClose']),
      );
    }
    return null;
  }
}

/// Una opción del duelo o de la escala, con su id y su etiqueta.
class TestOption {
  const TestOption({required this.id, required this.label});

  final String id;
  final String label;

  static TestOption? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final id = _texto(json['id']);
    final label = _texto(json['label']);
    if (id == null || label == null) return null;
    return TestOption(id: id, label: label);
  }
}

/// Las listas de reacciones de Ulises (RF-TEST-4).
class UlisesReactions {
  const UlisesReactions({
    this.pick = const <String>[],
    this.both = const <String>[],
    this.none = const <String>[],
    this.scale = const <String>[],
  });

  final List<String> pick;
  final List<String> both;
  final List<String> none;
  final List<String> scale;

  static UlisesReactions fromJson(Object? json) {
    if (json is! Map) return const UlisesReactions();
    return UlisesReactions(
      pick: _textos(json['pick']),
      both: _textos(json['both']),
      none: _textos(json['none']),
      scale: _textos(json['scale']),
    );
  }
}

/// Las líneas de Ulises del recorrido. `startButton` llega pero no se usa
/// (decisión abierta 7).
class UlisesLines {
  const UlisesLines({
    this.welcome = const <String>[],
    this.duelHelp,
    this.scaleHelp,
    this.reactions = const UlisesReactions(),
    this.loading,
  });

  final List<String> welcome;
  final String? duelHelp;
  final String? scaleHelp;
  final UlisesReactions reactions;
  final String? loading;

  static UlisesLines fromJson(Object? json) {
    if (json is! Map) return const UlisesLines();
    return UlisesLines(
      welcome: _textos(json['welcome']),
      duelHelp: _texto(json['duelHelp']),
      scaleHelp: _texto(json['scaleHelp']),
      reactions: UlisesReactions.fromJson(json['reactions']),
      loading: _texto(json['loading']),
    );
  }
}

/// El contenido de `GET /specialty-test/content`.
class SpecialtyTestContent {
  const SpecialtyTestContent({
    required this.version,
    required this.specialties,
    required this.ulises,
    required this.duelOptions,
    required this.scaleOptions,
    required this.questions,
  });

  final String version;
  final List<TestSpecialty> specialties;
  final UlisesLines ulises;
  final List<TestOption> duelOptions;
  final List<TestOption> scaleOptions;
  final List<TestQuestion> questions;

  int get totalQuestions => questions.length;

  TestSpecialty? specialtyByKey(String key) {
    for (final s in specialties) {
      if (s.key == key) return s;
    }
    return null;
  }

  /// La etiqueta de una opción del duelo (`both` o `none`) o de la escala.
  String? optionLabel(String id) {
    for (final o in [...duelOptions, ...scaleOptions]) {
      if (o.id == id) return o.label;
    }
    return null;
  }

  /// Comprueba lo que la app necesita (RF-TEST-2) y devuelve null si algo
  /// falta. Un elemento roto invalida todo el contenido, porque la app nunca
  /// pinta un test a medias. No fija el número de preguntas ni la versión.
  static SpecialtyTestContent? tryParse(Object? json) {
    if (json is! Map) return null;
    final version = _texto(json['version']);
    final rawSpecialties = json['specialties'];
    final rawQuestions = json['questions'];
    final rawDuel = json['duelOptions'];
    final rawScale = json['scaleOptions'];
    if (version == null ||
        rawSpecialties is! List ||
        rawQuestions is! List ||
        rawDuel is! List ||
        rawScale is! List) {
      return null;
    }

    final specialties = <TestSpecialty>[];
    for (final raw in rawSpecialties) {
      final s = TestSpecialty.tryFromJson(raw);
      if (s == null) return null;
      specialties.add(s);
    }
    final claves = specialties.map((s) => s.key).toSet();
    if (specialties.isEmpty) return null;

    final questions = <TestQuestion>[];
    for (final raw in rawQuestions) {
      final q = TestQuestion.tryFromJson(raw);
      if (q == null) return null;
      if (q.tasks.any((t) => !claves.contains(t.specialty))) return null;
      questions.add(q);
    }
    if (questions.isEmpty) return null;

    final duelOptions = <TestOption>[];
    for (final raw in rawDuel) {
      final o = TestOption.tryFromJson(raw);
      if (o == null) return null;
      duelOptions.add(o);
    }
    final idsDuelo = duelOptions.map((o) => o.id).toSet();
    if (!idsDuelo.contains('both') || !idsDuelo.contains('none')) return null;

    final scaleOptions = <TestOption>[];
    for (final raw in rawScale) {
      final o = TestOption.tryFromJson(raw);
      if (o == null) return null;
      scaleOptions.add(o);
    }
    // RF-TEST-6 ata un emoji a cada opción por su orden.
    if (scaleOptions.length != 4) return null;

    return SpecialtyTestContent(
      version: version,
      specialties: List.unmodifiable(specialties),
      ulises: UlisesLines.fromJson(json['ulises']),
      duelOptions: List.unmodifiable(duelOptions),
      scaleOptions: List.unmodifiable(scaleOptions),
      questions: List.unmodifiable(questions),
    );
  }
}

/// Un desempate respondido, tal como viaja en `tiebreakAnswers`.
class TiebreakAnswer {
  const TiebreakAnswer({required this.id, required this.answer});

  final String id;
  final String answer;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'answer': answer,
  };
}

/// Un desempate que manda el servidor.
class TestTiebreak {
  const TestTiebreak({
    required this.id,
    required this.order,
    required this.prompt,
    required this.top,
    required this.bottom,
  });

  final String id;

  /// 1 o 2.
  final int order;
  final String prompt;
  final TestTask top;
  final TestTask bottom;

  static TestTiebreak? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final id = _texto(json['id']);
    final order = _entero(json['order']);
    final prompt = _texto(json['prompt']);
    final top = TestTask.tryFromJson(json['top']);
    final bottom = TestTask.tryFromJson(json['bottom']);
    if (id == null ||
        order == null ||
        prompt == null ||
        top == null ||
        bottom == null) {
      return null;
    }
    return TestTiebreak(
      id: id,
      order: order,
      prompt: prompt,
      top: top,
      bottom: bottom,
    );
  }
}

/// Un desempate del recorrido en memoria, con el que mandó el servidor, la
/// línea de Ulises que lo anuncia y la respuesta, si ya la hay. Vive solo en
/// la memoria del controlador y del service (RF-TEST-2 y RF-TEST-4).
class TiebreakRecord {
  const TiebreakRecord({required this.tiebreak, this.ulisesLine, this.answer});

  final TestTiebreak tiebreak;
  final String? ulisesLine;
  final String? answer;

  TiebreakRecord withAnswer(String? answer) => TiebreakRecord(
    tiebreak: tiebreak,
    ulisesLine: ulisesLine,
    answer: answer,
  );
}

/// Una fila del ranking.
class RankingEntry {
  const RankingEntry({
    required this.key,
    required this.specialtyId,
    required this.name,
    required this.affinity,
  });

  final String key;
  final int specialtyId;
  final String name;

  /// Entero de 0 a 100 que calcula el servidor.
  final int affinity;

  static RankingEntry? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final key = _texto(json['key']);
    final specialtyId = _entero(json['specialtyId']);
    final name = _texto(json['name']);
    final affinity = _entero(json['affinity']);
    if (key == null ||
        specialtyId == null ||
        name == null ||
        affinity == null ||
        affinity < 0 ||
        affinity > 100) {
      return null;
    }
    return RankingEntry(
      key: key,
      specialtyId: specialtyId,
      name: name,
      affinity: affinity,
    );
  }
}

/// El resultado de una evaluación que terminó.
class SpecialtyTestResult {
  const SpecialtyTestResult({
    required this.version,
    required this.tie,
    required this.ranking,
    this.completedAt,
    this.reason,
    this.reasonSource,
    this.headline,
    this.tiebreakOutcome,
  });

  final String? version;
  final DateTime? completedAt;
  final bool tie;
  final List<RankingEntry> ranking;
  final String? reason;

  /// `"ai"` o `"templates"`.
  final String? reasonSource;
  final String? headline;

  /// null sin desempate.
  final String? tiebreakOutcome;

  bool get reasonByAi => reasonSource == 'ai';

  /// Las ganadoras, que son la primera o, con empate, las dos primeras.
  List<RankingEntry> get winners =>
      tie ? ranking.take(2).toList(growable: false) : [ranking.first];

  /// Las filas de abajo, desde el puesto 2 o, con empate, desde el 3.
  List<RankingEntry> get others => ranking.skip(tie ? 2 : 1).toList();

  static SpecialtyTestResult? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final ranking = _ranking(json['ranking']);
    final tie = json['tie'];
    if (ranking == null || tie is! bool) return null;
    if (tie && ranking.length < 2) return null;
    final ulises = json['ulises'];
    return SpecialtyTestResult(
      version: _texto(json['version']),
      completedAt: _fecha(json['completedAt']),
      tie: tie,
      ranking: ranking,
      reason: _texto(json['reason']),
      reasonSource: _texto(json['reasonSource']),
      headline: ulises is Map ? _texto(ulises['headline']) : null,
      tiebreakOutcome: ulises is Map ? _texto(ulises['tiebreakOutcome']) : null,
    );
  }
}

/// Lo que devuelve `POST /specialty-test/me/evaluate`.
sealed class EvaluationStep {
  const EvaluationStep();

  static EvaluationStep? tryParse(Object? json) {
    if (json is! Map) return null;
    final status = json['status'];
    if (status == 'tiebreak') {
      final tiebreak = TestTiebreak.tryFromJson(json['tiebreak']);
      if (tiebreak == null) return null;
      return TiebreakStep(
        tiebreak: tiebreak,
        ulisesLine: _texto(json['ulisesLine']),
      );
    }
    if (status == 'result') {
      final result = SpecialtyTestResult.tryFromJson(json['result']);
      if (result == null) return null;
      return ResultStep(result);
    }
    return null;
  }
}

class TiebreakStep extends EvaluationStep {
  const TiebreakStep({required this.tiebreak, this.ulisesLine});

  final TestTiebreak tiebreak;
  final String? ulisesLine;
}

class ResultStep extends EvaluationStep {
  const ResultStep(this.result);

  final SpecialtyTestResult result;
}

/// El último resultado guardado (`GET /specialty-test/me/result`), sin
/// motivo, que no se guarda.
class LastSpecialtyTestResult {
  const LastSpecialtyTestResult({
    required this.tie,
    required this.ranking,
    this.version,
    this.isCurrentVersion,
    this.completedAt,
  });

  final String? version;

  /// null si el servidor no lo manda, y entonces la tarjeta no dice que el
  /// test cambió.
  final bool? isCurrentVersion;
  final DateTime? completedAt;
  final bool tie;
  final List<RankingEntry> ranking;

  List<RankingEntry> get winners =>
      tie ? ranking.take(2).toList(growable: false) : [ranking.first];

  List<RankingEntry> get others => ranking.skip(tie ? 2 : 1).toList();

  static LastSpecialtyTestResult? tryParse(Object? json) {
    if (json is! Map) return null;
    final ranking = _ranking(json['ranking']);
    final tie = json['tie'];
    if (ranking == null || tie is! bool) return null;
    if (tie && ranking.length < 2) return null;
    final current = json['isCurrentVersion'];
    return LastSpecialtyTestResult(
      version: _texto(json['version']),
      isCurrentVersion: current is bool ? current : null,
      completedAt: _fecha(json['completedAt']),
      tie: tie,
      ranking: ranking,
    );
  }
}

// ── Lectura segura ────────────────────────────────────────────────────────────

String? _texto(Object? value) => value is String ? value : null;

int? _entero(Object? value) {
  if (value is int) return value;
  if (value is num && value == value.roundToDouble()) return value.toInt();
  return null;
}

List<String> _textos(Object? value) {
  if (value is! List) return const <String>[];
  return value.whereType<String>().toList(growable: false);
}

DateTime? _fecha(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

List<RankingEntry>? _ranking(Object? value) {
  if (value is! List || value.isEmpty) return null;
  final ranking = <RankingEntry>[];
  for (final raw in value) {
    final entry = RankingEntry.tryFromJson(raw);
    if (entry == null) return null;
    ranking.add(entry);
  }
  return List.unmodifiable(ranking);
}
```

- [ ] **Paso 5: Correr la prueba y ver que pasa**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/HU36_jeff/specialty_test_models_test.dart
```

Esperado: PASS, `+15: All tests passed!`.

- [ ] **Paso 6: Dar formato y analizar**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/models/specialty_test_models.dart \
  test/HU36_jeff/datos_de_prueba.dart \
  test/HU36_jeff/specialty_test_models_test.dart
```

Esperado: `Formatted 3 files (0 changed)`.

```bash
cd "${REPO:?}"
"${FLUTTER:?}" analyze --no-pub
```

Esperado: `6 issues found.`, los 6 de la línea base y ninguno en un archivo de esta tarea.

- [ ] **Paso 7: Commit**

```bash
cd "${REPO:?}"
test "$(git branch --show-current)" = feat/test-especialidad-fe || echo 'PARAR: rama equivocada'
git status --short
git add lib/models/specialty_test_models.dart \
  test/HU36_jeff/datos_de_prueba.dart \
  test/HU36_jeff/specialty_test_models_test.dart
git commit -m 'feat(specialty-test): los modelos leen el contenido, el paso de la evaluación y el último resultado sin inventar datos (RF-TEST-2)'
git log -1 --format='%an <%ae>'
git log -1 --format=%B | grep -qi '^co-authored-by:' && echo 'PARAR: el commit trae trailer'
```

Esperado: ningún `PARAR`. Antes del `git add`, `git status --short` lista solo los archivos de la tarea, y el autor es `Jeffangeloss <178797184+jeffangeloss@users.noreply.github.com>`.

---

### Tarea 2: Tokens del test y contraste

**Requisitos:** RF-TEST-12 (tokens nuevos, colores del contenido, guarda en tiempo de ejecución y la cabecera como única excepción).

**Archivos:**
- Modificar `lib/configs/themes.dart` (los 17 tokens van después de `iconoNaranja`)
- Crear `lib/pages/specialty_test/specialty_test_logic.dart` con la sección de color y contraste
- Crear `test/HU36_jeff/specialty_test_contraste_test.dart`

**Interfaces:**

- Consume `MaterialTheme.pageBg`, `cardBg`, `textPrimary`, `headerColor`,
  `borderColor`, `iconoNaranja` y `errorBg` (`lib/configs/themes.dart`), y
  `TestSpecialty` de la Tarea 1.
- Produce lo que sigue.

```dart
// lib/configs/themes.dart, dentro de MaterialTheme
static Color testInk2(Brightness b); testMuted; testLine; testChipBg;
  testAccent; testAccentHi; testAccentInk; testAccentText; testAccentDeep;
  testAccentSoft; testHeartOff; testTrack; testFeatherOn; testFeatherOff;
  testTaskTileBg; testTaskIconInk; testAiBadgeBg   // todos (Brightness b)

// lib/pages/specialty_test/specialty_test_logic.dart
const double kContrasteTexto = 4.5;
const double kContrasteIcono = 3.0;
double razonDeContraste(Color a, Color b);
Color? colorDeHex(String? hex);
Color? colorDeEspecialidad(TestSpecialty? especialidad, Brightness brillo);
Color tinte(Color color, Color fondo, double alfa);   // opaco, 8 bits por canal
Color oscurecido(Color color);                        // un 20 % más oscuro
Color colorQueSeLee(Color? color, {required Color fondo,
  required Color respaldo, bool esTexto = true});
```

- [ ] **Paso 1: Escribir la prueba que falla**

Las cifras son las de las tablas de RF-TEST-12 con dos decimales. Las mezclas (tarjeta encendida, tarjeta del resultado e insignia «IA») se miden redondeadas a 8 bits por canal, como las pinta la pantalla, y así dan justo las cifras de la spec.

Crea `test/HU36_jeff/specialty_test_contraste_test.dart` con este contenido.

```dart
// test/HU36_jeff/specialty_test_contraste_test.dart
//
// Pruebas unitarias de HU36, el test de especialidad, sobre el modo oscuro y
// el contraste (RF-TEST-12).
// Tokens:  lib/configs/themes.dart
// Lógica:  lib/pages/specialty_test/specialty_test_logic.dart
//
// Las cifras son las de las tablas de RF-TEST-12, redondeadas a dos
// decimales. Las mezclas (tarjeta encendida, tarjeta del resultado e
// insignia «IA») se redondean a 8 bits por canal, como las pinta la pantalla.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_logic.dart';

const Brightness _claro = Brightness.light;
const Brightness _oscuro = Brightness.dark;
const Color _blanco = Color(0xFFFFFFFF);

Matcher _cifra(double valor) => closeTo(valor, 0.006);

double _c(Color a, Color b) => razonDeContraste(a, b);

/// Los colores de las especialidades en la versión 2026-09-25.4.
const Map<String, (String, String)> _colores = {
  'sw': ('#1E3A8A', '#A5C0F7'),
  'ti': ('#0F7A45', '#7EE8BE'),
  'si': ('#9333EA', '#B98AF8'),
  'vj': ('#76164A', '#EC7FB3'),
};

void main() {
  group('UNITARIA · Tokens del test en los dos temas (RF-TEST-12)', () {
    test('caso 1: cada token tiene el valor de la tabla', () {
      final tabla = <String, (Color Function(Brightness), int, int)>{
        'testInk2': (MaterialTheme.testInk2, 0xFF334155, 0xFFCFCFDB),
        'testMuted': (MaterialTheme.testMuted, 0xFF556070, 0xFFA5A5B5),
        'testLine': (MaterialTheme.testLine, 0xFFE2E8F0, 0xFF30303A),
        'testChipBg': (MaterialTheme.testChipBg, 0xFFEEF2F7, 0xFF24242C),
        'testAccent': (MaterialTheme.testAccent, 0xFFFF6600, 0xFFFF8C42),
        'testAccentHi': (MaterialTheme.testAccentHi, 0xFFFF7F24, 0xFFFF9D5C),
        'testAccentInk': (MaterialTheme.testAccentInk, 0xFF1A0E05, 0xFF16161C),
        'testAccentText': (
          MaterialTheme.testAccentText,
          0xFFB84A00,
          0xFFFF9A57,
        ),
        'testAccentDeep': (
          MaterialTheme.testAccentDeep,
          0xFF7A3300,
          0xFFFFC49A,
        ),
        'testAccentSoft': (
          MaterialTheme.testAccentSoft,
          0xFFFFF1E6,
          0xFF3A2A22,
        ),
        'testHeartOff': (MaterialTheme.testHeartOff, 0xFF64748B, 0xFF9A9AAC),
        'testTrack': (MaterialTheme.testTrack, 0xFFE8EDF3, 0xFF2C2C36),
        'testFeatherOn': (MaterialTheme.testFeatherOn, 0xFFD45500, 0xFFFF8C42),
        'testFeatherOff': (
          MaterialTheme.testFeatherOff,
          0xFFCBD5E1,
          0xFF3A3A46,
        ),
        'testTaskTileBg': (
          MaterialTheme.testTaskTileBg,
          0xFFF1F5F9,
          0xFF25252D,
        ),
        'testTaskIconInk': (
          MaterialTheme.testTaskIconInk,
          0xFF64748B,
          0xFF8A8A9C,
        ),
        'testAiBadgeBg': (MaterialTheme.testAiBadgeBg, 0x61140A50, 0xFF16161C),
      };
      for (final fila in tabla.entries) {
        final (token, claro, oscuro) = fila.value;
        expect(token(_claro), Color(claro), reason: '${fila.key} en claro');
        expect(token(_oscuro), Color(oscuro), reason: '${fila.key} en oscuro');
      }
    });

    test('caso 2: los pares del test llegan a las cifras de la tabla', () {
      final pagina = MaterialTheme.pageBg;
      final tarjeta = MaterialTheme.cardBg;
      final texto = MaterialTheme.textPrimary;
      // (par, claro, oscuro)
      final pares = <(String, double, double, double, double)>[
        (
          'texto sobre página',
          _c(texto(_claro), pagina(_claro)),
          17.06,
          _c(texto(_oscuro), pagina(_oscuro)),
          15.45,
        ),
        (
          'texto sobre tarjeta',
          _c(texto(_claro), tarjeta(_claro)),
          17.85,
          _c(texto(_oscuro), tarjeta(_oscuro)),
          14.22,
        ),
        (
          'testInk2 sobre tarjeta',
          _c(MaterialTheme.testInk2(_claro), tarjeta(_claro)),
          10.35,
          _c(MaterialTheme.testInk2(_oscuro), tarjeta(_oscuro)),
          10.74,
        ),
        (
          'testMuted sobre página',
          _c(MaterialTheme.testMuted(_claro), pagina(_claro)),
          6.09,
          _c(MaterialTheme.testMuted(_oscuro), pagina(_oscuro)),
          7.42,
        ),
        (
          'testMuted sobre tarjeta',
          _c(MaterialTheme.testMuted(_claro), tarjeta(_claro)),
          6.38,
          _c(MaterialTheme.testMuted(_oscuro), tarjeta(_oscuro)),
          6.83,
        ),
        (
          'testAccentText sobre página',
          _c(MaterialTheme.testAccentText(_claro), pagina(_claro)),
          5.00,
          _c(MaterialTheme.testAccentText(_oscuro), pagina(_oscuro)),
          8.59,
        ),
        (
          'testAccentInk sobre testAccent',
          _c(
            MaterialTheme.testAccentInk(_claro),
            MaterialTheme.testAccent(_claro),
          ),
          6.45,
          _c(
            MaterialTheme.testAccentInk(_oscuro),
            MaterialTheme.testAccent(_oscuro),
          ),
          7.79,
        ),
        (
          'testAccentInk sobre testAccentHi',
          _c(
            MaterialTheme.testAccentInk(_claro),
            MaterialTheme.testAccentHi(_claro),
          ),
          7.50,
          _c(
            MaterialTheme.testAccentInk(_oscuro),
            MaterialTheme.testAccentHi(_oscuro),
          ),
          8.78,
        ),
        (
          'testAccentDeep sobre testAccentSoft',
          _c(
            MaterialTheme.testAccentDeep(_claro),
            MaterialTheme.testAccentSoft(_claro),
          ),
          8.25,
          _c(
            MaterialTheme.testAccentDeep(_oscuro),
            MaterialTheme.testAccentSoft(_oscuro),
          ),
          8.87,
        ),
        (
          'ícono testAccentText sobre testAccentSoft',
          _c(
            MaterialTheme.testAccentText(_claro),
            MaterialTheme.testAccentSoft(_claro),
          ),
          4.72,
          _c(
            MaterialTheme.testAccentText(_oscuro),
            MaterialTheme.testAccentSoft(_oscuro),
          ),
          6.53,
        ),
        (
          'testMuted sobre testChipBg',
          _c(MaterialTheme.testMuted(_claro), MaterialTheme.testChipBg(_claro)),
          5.67,
          _c(
            MaterialTheme.testMuted(_oscuro),
            MaterialTheme.testChipBg(_oscuro),
          ),
          6.34,
        ),
        (
          'testFeatherOn sobre página',
          _c(MaterialTheme.testFeatherOn(_claro), pagina(_claro)),
          3.94,
          _c(MaterialTheme.testFeatherOn(_oscuro), pagina(_oscuro)),
          7.79,
        ),
        (
          'testHeartOff sobre página',
          _c(MaterialTheme.testHeartOff(_claro), pagina(_claro)),
          4.55,
          _c(MaterialTheme.testHeartOff(_oscuro), pagina(_oscuro)),
          6.51,
        ),
      ];
      for (final (nombre, claro, cifraClaro, oscuro, cifraOscuro) in pares) {
        expect(claro, _cifra(cifraClaro), reason: '$nombre en claro');
        expect(oscuro, _cifra(cifraOscuro), reason: '$nombre en oscuro');
      }
    });

    test('caso 3: el héroe, la pastilla de afinidad y los avisos de error', () {
      const tinta = Color(0xFF1A0E05);
      expect(_c(tinta, const Color(0xFFFF6600)), _cifra(6.45));
      expect(_c(tinta, const Color(0xFFFFB020)), _cifra(10.36));
      for (final b in Brightness.values) {
        expect(_c(_blanco, MaterialTheme.errorBg(b)), _cifra(6.54));
        // Estrella y «Tu principal» en testAccentText sobre la página.
        expect(
          _c(MaterialTheme.testAccentText(b), MaterialTheme.pageBg(b)),
          greaterThanOrEqualTo(kContrasteTexto),
        );
      }
    });

    test('caso 4: la cabecera del asistente en claro es la única excepción '
        'al 4,5:1', () {
      expect(_c(_blanco, MaterialTheme.headerColor(_claro)), _cifra(2.94));
      expect(
        _c(_blanco, MaterialTheme.headerColor(_claro)),
        lessThan(kContrasteTexto),
      );
      expect(_c(_blanco, MaterialTheme.headerColor(_oscuro)), _cifra(16.58));
    });
  });

  group('UNITARIA · Colores de las especialidades (RF-TEST-12)', () {
    test('caso 5: cada color del contenido da las cifras de la tabla', () {
      // Por clave, sobre blanco, sobre #F8FAFC, tinta sobre tarjeta encendida,
      //         oscuro sobre #1E1E24, oscuro sobre #16161C,
      //         tinta sobre la tarjeta del resultado, color sobre ella)
      const cifras = <String, List<double>>{
        'sw': [10.36, 9.90, 14.45, 9.07, 9.85, 9.57, 6.10],
        'ti': [5.40, 5.16, 15.10, 11.19, 12.16, 9.12, 7.18],
        'si': [5.38, 5.14, 14.97, 6.36, 6.91, 10.48, 4.69],
        'vj': [10.58, 10.12, 14.31, 6.52, 7.08, 10.50, 4.81],
      };
      for (final clave in _colores.keys) {
        final claro = colorDeHex(_colores[clave]!.$1)!;
        final oscuro = colorDeHex(_colores[clave]!.$2)!;
        final encendida = tinte(claro, MaterialTheme.cardBg(_claro), 0.12);
        final resultado = tinte(oscuro, MaterialTheme.cardBg(_oscuro), 0.18);
        final c = cifras[clave]!;
        expect(_c(claro, _blanco), _cifra(c[0]), reason: '$clave sobre blanco');
        expect(
          _c(claro, MaterialTheme.pageBg(_claro)),
          _cifra(c[1]),
          reason: '$clave sobre la página',
        );
        expect(
          _c(MaterialTheme.textPrimary(_claro), encendida),
          _cifra(c[2]),
          reason: '$clave tarjeta encendida',
        );
        expect(
          _c(oscuro, MaterialTheme.cardBg(_oscuro)),
          _cifra(c[3]),
          reason: '$clave oscuro sobre la tarjeta',
        );
        expect(
          _c(oscuro, MaterialTheme.pageBg(_oscuro)),
          _cifra(c[4]),
          reason: '$clave oscuro sobre la página',
        );
        expect(
          _c(MaterialTheme.textPrimary(_oscuro), resultado),
          _cifra(c[5]),
          reason: '$clave tinta sobre el resultado',
        );
        expect(
          _c(oscuro, resultado),
          _cifra(c[6]),
          reason: '$clave título sobre el resultado',
        );
        // En claro, el extremo oscuro del degradado solo sube el contraste
        // del blanco.
        expect(_c(_blanco, oscurecido(claro)), greaterThan(_c(_blanco, claro)));
      }
    });

    test('caso 6: la insignia «IA» llega a su cifra en los dos temas', () {
      final claro = <double>[];
      final oscuro = <double>[];
      for (final par in _colores.values) {
        final insignia = MaterialTheme.testAiBadgeBg(_claro);
        final fondoClaro = tinte(
          insignia.withValues(alpha: 1),
          colorDeHex(par.$1)!,
          insignia.a,
        );
        claro.add(_c(_blanco, fondoClaro));
        oscuro.add(
          _c(colorDeHex(par.$2)!, MaterialTheme.testAiBadgeBg(_oscuro)),
        );
      }
      claro.sort();
      oscuro.sort();
      expect(claro.first, _cifra(8.79));
      expect(claro.last, _cifra(13.69));
      expect(oscuro.first, _cifra(6.91));
      expect(oscuro.last, _cifra(12.16));
    });
  });

  group('UNITARIA · Guarda en tiempo de ejecución (RF-TEST-12)', () {
    test('caso 7: un color que llega al mínimo se usa tal cual', () {
      final sw = colorDeHex('#1E3A8A');
      expect(colorQueSeLee(sw, fondo: _blanco, respaldo: Colors.black), sw);
    });

    test('caso 8: un color que no llega cae al respaldo como texto, y como '
        'ícono solo si baja de 3:1', () {
      // #FF9900 sobre blanco da 2,14:1; #D97706 da 3,19:1.
      const flojo = Color(0xFFFF9900);
      const justo = Color(0xFFD97706);
      final respaldo = MaterialTheme.textPrimary(_claro);
      expect(
        colorQueSeLee(flojo, fondo: _blanco, respaldo: respaldo),
        respaldo,
      );
      expect(
        colorQueSeLee(
          flojo,
          fondo: _blanco,
          respaldo: respaldo,
          esTexto: false,
        ),
        respaldo,
      );
      expect(
        colorQueSeLee(justo, fondo: _blanco, respaldo: respaldo),
        respaldo,
      );
      expect(
        colorQueSeLee(
          justo,
          fondo: _blanco,
          respaldo: respaldo,
          esTexto: false,
        ),
        justo,
      );
    });

    test('caso 9: un hex roto cuenta como neutro y cae al respaldo', () {
      for (final roto in <String?>['naranja', '#12345', '#GGGGGG', '', null]) {
        expect(colorDeHex(roto), isNull, reason: '$roto');
        expect(
          colorQueSeLee(
            colorDeHex(roto),
            fondo: _blanco,
            respaldo: Colors.black,
          ),
          Colors.black,
        );
      }
      expect(colorDeHex(' #1e3a8a '), const Color(0xFF1E3A8A));
    });
  });
}
```

- [ ] **Paso 2: Correr la prueba y ver que falla**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/HU36_jeff/specialty_test_contraste_test.dart
```

Esperado: FALLA al compilar, sin llegar a correr ningún caso. La salida trae 74 errores distintos (líneas `Error:`), y los primeros dicen esto (las rutas pueden salir absolutas).

```text
test/HU36_jeff/specialty_test_contraste_test.dart:23:32: Error: Method not found: 'razonDeContraste'.
test/HU36_jeff/specialty_test_contraste_test.dart:37:36: Error: Member not found: 'testInk2'.
```

- [ ] **Paso 3: Agregar los tokens y la sección de color**

Los tokens van después de `iconoNaranja`, con el estilo de los del chat. La sección de color abre `specialty_test_logic.dart`, que las Tareas 3 a 5 amplían.

En `lib/configs/themes.dart`, cambia este bloque, que aparece una sola vez,

```dart
  static Color iconoNaranja(Brightness b) =>
      b == Brightness.light ? primaryDark : primaryColor;
```

por este otro.

```dart
  static Color iconoNaranja(Brightness b) =>
      b == Brightness.light ? primaryDark : primaryColor;

  // ── Test de especialidad (HU36, RF-TEST-12) ──────────────────────────────
  // Paleta de la maqueta `ulises-v2.html`, que ya llega al contraste pedido.
  // Las cifras de cada par están en la tabla de RF-TEST-12.

  /// Texto de la tarjeta apagada y de las opciones.
  static Color testInk2(Brightness b) =>
      b == Brightness.light ? const Color(0xFF334155) : const Color(0xFFCFCFDB);

  /// Texto secundario del test y de la tarjeta del Perfil.
  static Color testMuted(Brightness b) =>
      b == Brightness.light ? const Color(0xFF556070) : const Color(0xFFA5A5B5);

  /// Bordes de tarjetas y botones.
  static Color testLine(Brightness b) =>
      b == Brightness.light ? const Color(0xFFE2E8F0) : const Color(0xFF30303A);

  /// Pastilla del historial.
  static Color testChipBg(Brightness b) =>
      b == Brightness.light ? const Color(0xFFEEF2F7) : const Color(0xFF24242C);

  /// Fondo del botón principal y de la opción elegida.
  static Color testAccent(Brightness b) =>
      b == Brightness.light ? const Color(0xFFFF6600) : const Color(0xFFFF8C42);

  /// Tope del degradado del botón principal.
  static Color testAccentHi(Brightness b) =>
      b == Brightness.light ? const Color(0xFFFF7F24) : const Color(0xFFFF9D5C);

  /// Texto sobre `testAccent`.
  static Color testAccentInk(Brightness b) =>
      b == Brightness.light ? const Color(0xFF1A0E05) : const Color(0xFF16161C);

  /// Rótulos, botones secundarios y «Reintentar».
  static Color testAccentText(Brightness b) =>
      b == Brightness.light ? const Color(0xFFB84A00) : const Color(0xFFFF9A57);

  /// Texto sobre `testAccentSoft`.
  static Color testAccentDeep(Brightness b) =>
      b == Brightness.light ? const Color(0xFF7A3300) : const Color(0xFFFFC49A);

  /// Pastillas, sello y opción elegida.
  static Color testAccentSoft(Brightness b) =>
      b == Brightness.light ? const Color(0xFFFFF1E6) : const Color(0xFF3A2A22);

  /// Corazón sin marcar.
  static Color testHeartOff(Brightness b) =>
      b == Brightness.light ? const Color(0xFF64748B) : const Color(0xFF9A9AAC);

  /// Pista de las barras.
  static Color testTrack(Brightness b) =>
      b == Brightness.light ? const Color(0xFFE8EDF3) : const Color(0xFF2C2C36);

  /// Plumas llenas. En claro va en `#D45500` y no en el `#FF6600` de la
  /// maqueta, que da 2,81:1 (decisión abierta 15).
  static Color testFeatherOn(Brightness b) =>
      b == Brightness.light ? const Color(0xFFD45500) : const Color(0xFFFF8C42);

  /// Plumas vacías.
  static Color testFeatherOff(Brightness b) =>
      b == Brightness.light ? const Color(0xFFCBD5E1) : const Color(0xFF3A3A46);

  /// Baldosa del ícono de la tarea.
  static Color testTaskTileBg(Brightness b) =>
      b == Brightness.light ? const Color(0xFFF1F5F9) : const Color(0xFF25252D);

  /// Ícono de la tarea antes del toque y en la escala, y el ícono neutro.
  static Color testTaskIconInk(Brightness b) =>
      b == Brightness.light ? const Color(0xFF64748B) : const Color(0xFF8A8A9C);

  /// Fondo de la insignia «IA» de la tarjeta del resultado, que es `#140A50`
  /// al 38 % en claro, sobre el color de la ganadora, y `#16161C` en oscuro.
  static Color testAiBadgeBg(Brightness b) =>
      b == Brightness.light ? const Color(0x61140A50) : const Color(0xFF16161C);
```

Crea `lib/pages/specialty_test/specialty_test_logic.dart` con este contenido.

```dart
// lib/pages/specialty_test/specialty_test_logic.dart
// Funciones puras del test de especialidad (HU36). Ninguna toca la red, GetX
// ni el árbol de widgets, así que se prueban solas
// (test/HU36_jeff/specialty_test_logic_test.dart y
// test/HU36_jeff/specialty_test_contraste_test.dart).

import 'package:flutter/material.dart';

import '../../models/specialty_test_models.dart';

// ── Color y contraste (RF-TEST-12) ────────────────────────────────────────────

/// Mínimo WCAG de un texto contra su fondo.
const double kContrasteTexto = 4.5;

/// Mínimo WCAG de un ícono que da información.
const double kContrasteIcono = 3.0;

/// Razón de contraste WCAG 2.x entre dos colores opacos, de 1 a 21.
double razonDeContraste(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final claro = la > lb ? la : lb;
  final oscuro = la > lb ? lb : la;
  return (claro + 0.05) / (oscuro + 0.05);
}

final RegExp _hex = RegExp(r'^#([0-9a-fA-F]{6})$');

/// El color de un hex `#RRGGBB`, o null si no se puede leer. Un null cuenta
/// como neutro y no invalida el contenido (RF-TEST-2).
Color? colorDeHex(String? hex) {
  final m = _hex.firstMatch(hex?.trim() ?? '');
  if (m == null) return null;
  return Color(0xFF000000 | int.parse(m.group(1)!, radix: 16));
}

/// El color de una especialidad en el tema, `color.light` o `color.dark`.
Color? colorDeEspecialidad(TestSpecialty? especialidad, Brightness brillo) {
  if (especialidad == null) return null;
  return colorDeHex(
    brillo == Brightness.light
        ? especialidad.colorLight
        : especialidad.colorDark,
  );
}

/// [color] al [alfa] sobre [fondo], ya opaco y redondeado a 8 bits por canal,
/// como lo pinta la pantalla. Así se miden la tarjeta encendida (12 %), la del
/// resultado en oscuro (18 %) y la insignia «IA».
Color tinte(Color color, Color fondo, double alfa) {
  int canal(double c, double f) => ((c * alfa + f * (1 - alfa)) * 255).round();
  return Color.fromARGB(
    255,
    canal(color.r, fondo.r),
    canal(color.g, fondo.g),
    canal(color.b, fondo.b),
  );
}

/// [color] un 20 % más oscuro, el extremo inferior del degradado de la
/// tarjeta de la ganadora en claro (RF-TEST-8).
Color oscurecido(Color color) => tinte(Colors.black, color, 0.2);

/// La guarda de RF-TEST-12. Devuelve [color] si llega al mínimo contra
/// [fondo] (4,5:1 como texto, 3:1 como ícono), o [respaldo] si no llega o si
/// es null. El contenido puede cambiar sin otro APK, así que la app no confía
/// a ciegas en sus colores.
Color colorQueSeLee(
  Color? color, {
  required Color fondo,
  required Color respaldo,
  bool esTexto = true,
}) {
  if (color == null) return respaldo;
  final minimo = esTexto ? kContrasteTexto : kContrasteIcono;
  return razonDeContraste(color, fondo) >= minimo ? color : respaldo;
}
```

- [ ] **Paso 4: Correr la prueba y ver que pasa**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/HU36_jeff/specialty_test_contraste_test.dart
```

Esperado: PASS, `+9: All tests passed!`.

- [ ] **Paso 5: Dar formato y analizar**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/configs/themes.dart \
  lib/pages/specialty_test/specialty_test_logic.dart \
  test/HU36_jeff/specialty_test_contraste_test.dart
```

Esperado: `Formatted 3 files (0 changed)`.

```bash
cd "${REPO:?}"
"${FLUTTER:?}" analyze --no-pub
```

Esperado: `6 issues found.`, los 6 de la línea base y ninguno en un archivo de esta tarea.

- [ ] **Paso 6: Commit**

```bash
cd "${REPO:?}"
test "$(git branch --show-current)" = feat/test-especialidad-fe || echo 'PARAR: rama equivocada'
git status --short
git add lib/configs/themes.dart \
  lib/pages/specialty_test/specialty_test_logic.dart \
  test/HU36_jeff/specialty_test_contraste_test.dart
git commit -m 'feat(specialty-test): los tokens del test y la guarda de contraste cumplen las tablas de la spec (RF-TEST-12)'
git log -1 --format='%an <%ae>'
git log -1 --format=%B | grep -qi '^co-authored-by:' && echo 'PARAR: el commit trae trailer'
```

Esperado: ningún `PARAR`. Antes del `git add`, `git status --short` lista solo los archivos de la tarea, y el autor es `Jeffangeloss <178797184+jeffangeloss@users.noreply.github.com>`.

---

### Tarea 3: Mapa cerrado de íconos

**Requisitos:** RF-TEST-5 y decisión 8 (los 52 nombres de la `2026-09-25.4`, el ícono neutro y nada armado con un punto de código del servidor).

**Archivos:**
- Modificar `lib/pages/specialty_test/specialty_test_logic.dart` (import de Lucide y sección de íconos al final)
- Crear `test/HU36_jeff/specialty_test_logic_test.dart`

**Interfaces:**

- Consume `LucideIcons` de `lucide_icons_flutter` 3.1.15, que ya está en
  `pubspec.yaml`.
- Produce lo que sigue, que usan la escala, el duelo, el resultado y la tarjeta del
  Perfil.

```dart
const IconData kIconoNeutro = LucideIcons.sparkles;
const Map<String, IconData> kIconosDelTest;   // exactamente 52 entradas
IconData iconoDelTest(String? nombre);        // kIconoNeutro si no está
```

- [ ] **Paso 1: Escribir la prueba que falla**

La prueba escribe aparte la misma lista de 52 pares, así que un nombre cambiado de constante en el mapa se nota. Los 52 nombres salen del `contenido-test.json` de la `2026-09-25.4` (4 especialidades y 48 tareas), y cada constante existe en `lucide_icons_flutter` 3.1.15.

Crea `test/HU36_jeff/specialty_test_logic_test.dart` con este contenido.

```dart
// test/HU36_jeff/specialty_test_logic_test.dart
//
// Pruebas unitarias de HU36, el test de especialidad, sobre las funciones
// puras de lib/pages/specialty_test/specialty_test_logic.dart, que son el mapa
// de íconos (RF-TEST-5), las líneas de Ulises, el sello, el historial y el
// cuerpo de la evaluación (RF-TEST-4) y la selección oficial, los corazones
// (RF-TEST-9 y RF-TEST-14) y la fecha en Lima (RF-TEST-10).
//
// Datos inventados (datos_de_prueba.dart).

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_logic.dart';

void main() {
  _iconos();
}

void _iconos() {
  group('UNITARIA · Mapa de íconos (RF-TEST-5, decisión 8)', () {
    // Los 52 nombres de la versión 2026-09-25.4 con la constante que da su
    // camelCase. Es la misma lista que el mapa de la app, escrita aparte para
    // que un nombre cambiado de constante se note.
    const esperado = <String, IconData>{
      // Las cuatro especialidades.
      'code-xml': LucideIcons.codeXml,
      'server-cog': LucideIcons.serverCog,
      'chart-column-big': LucideIcons.chartColumnBig,
      'gamepad-2': LucideIcons.gamepad2,
      // Las 48 tareas, 24 de las preguntas y 24 de los desempates.
      'shopping-cart': LucideIcons.shoppingCart,
      'shelving-unit': LucideIcons.shelvingUnit,
      'refrigerator': LucideIcons.refrigerator,
      'mountain': LucideIcons.mountain,
      'eye': LucideIcons.eye,
      'store': LucideIcons.store,
      'drumstick': LucideIcons.drumstick,
      'rabbit': LucideIcons.rabbit,
      'camera': LucideIcons.camera,
      'folder-search': LucideIcons.folderSearch,
      'school': LucideIcons.school,
      'drafting-compass': LucideIcons.draftingCompass,
      'rocket': LucideIcons.rocket,
      'smartphone': LucideIcons.smartphone,
      'hand-coins': LucideIcons.handCoins,
      'clipboard-pen-line': LucideIcons.clipboardPenLine,
      'ticket': LucideIcons.ticket,
      'clock-arrow-up': LucideIcons.clockArrowUp,
      'route': LucideIcons.route,
      'messages-square': LucideIcons.messagesSquare,
      'user-minus': LucideIcons.userMinus,
      'pencil': LucideIcons.pencil,
      'footprints': LucideIcons.footprints,
      'bus': LucideIcons.bus,
      'calendar-clock': LucideIcons.calendarClock,
      'hospital': LucideIcons.hospital,
      'key-round': LucideIcons.keyRound,
      'receipt': LucideIcons.receipt,
      'blocks': LucideIcons.blocks,
      'goal': LucideIcons.goal,
      'database': LucideIcons.database,
      'rocking-chair': LucideIcons.rockingChair,
      'land-plot': LucideIcons.landPlot,
      'dices': LucideIcons.dices,
      'ghost': LucideIcons.ghost,
      'headphones': LucideIcons.headphones,
      'siren': LucideIcons.siren,
      'badge-percent': LucideIcons.badgePercent,
      'stamp': LucideIcons.stamp,
      'graduation-cap': LucideIcons.graduationCap,
      'house-wifi': LucideIcons.houseWifi,
      'drama': LucideIcons.drama,
      'droplet': LucideIcons.droplet,
      'radio-tower': LucideIcons.radioTower,
      'soup': LucideIcons.soup,
      'map-pinned': LucideIcons.mapPinned,
      'split': LucideIcons.split,
      'pill-bottle': LucideIcons.pillBottle,
    };

    test('caso 1: el mapa trae los 52 nombres y ningún otro', () {
      expect(kIconosDelTest.length, 52);
      expect(kIconosDelTest.keys.toSet(), esperado.keys.toSet());
      for (final nombre in esperado.keys) {
        expect(kIconosDelTest[nombre], esperado[nombre], reason: nombre);
      }
    });

    test('caso 2: cada nombre da un ícono distinto y ninguno es el neutro', () {
      final puntos = kIconosDelTest.values.map((i) => i.codePoint).toSet();
      expect(puntos, hasLength(52));
      expect(puntos, isNot(contains(kIconoNeutro.codePoint)));
      expect(kIconoNeutro, LucideIcons.sparkles);
    });

    test('caso 3: un nombre fuera del mapa o ausente cae al neutro', () {
      expect(iconoDelTest('shopping-cart'), LucideIcons.shoppingCart);
      expect(iconoDelTest('gamepad-2'), LucideIcons.gamepad2);
      expect(iconoDelTest('icono-que-no-existe'), LucideIcons.sparkles);
      expect(iconoDelTest('ShoppingCart'), LucideIcons.sparkles);
      expect(iconoDelTest(''), LucideIcons.sparkles);
      expect(iconoDelTest(null), LucideIcons.sparkles);
    });
  });
}
```

- [ ] **Paso 2: Correr la prueba y ver que falla**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/HU36_jeff/specialty_test_logic_test.dart
```

Esperado: FALLA al compilar, sin llegar a correr ningún caso. La salida trae 12 errores distintos (líneas `Error:`), y los primeros dicen esto (las rutas pueden salir absolutas).

```text
test/HU36_jeff/specialty_test_logic_test.dart:84:14: Error: Undefined name 'kIconosDelTest'.
test/HU36_jeff/specialty_test_logic_test.dart:86:16: Error: Undefined name 'kIconosDelTest'.
```

- [ ] **Paso 3: Agregar el mapa**

En `lib/pages/specialty_test/specialty_test_logic.dart`, cambia este bloque, que aparece una sola vez,

```dart
import 'package:flutter/material.dart';
```

por este otro.

```dart
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
```

Agrega al final de `lib/pages/specialty_test/specialty_test_logic.dart`, tras una línea en blanco, este bloque.

```dart
// ── Íconos de las tareas y de las especialidades (RF-TEST-5, decisión 8) ────

/// El ícono de un nombre fuera del mapa o ausente. No es de ninguna
/// especialidad ni de ninguna tarea, así que no delata nada.
const IconData kIconoNeutro = LucideIcons.sparkles;

/// Mapa cerrado de los 52 nombres de Lucide de la versión 2026-09-25.4 a sus
/// constantes de `lucide_icons_flutter` 3.1.15, cada una con el camelCase de
/// su nombre. La app nunca arma un `IconData` con un punto de código que
/// llegue del servidor, porque el build de release recorta la fuente a las
/// constantes que nombra el código. Un nombre nuevo sale neutro hasta el
/// siguiente APK.
const Map<String, IconData> kIconosDelTest = <String, IconData>{
  // Las cuatro especialidades.
  'code-xml': LucideIcons.codeXml,
  'server-cog': LucideIcons.serverCog,
  'chart-column-big': LucideIcons.chartColumnBig,
  'gamepad-2': LucideIcons.gamepad2,
  // Las 48 tareas, 24 de las preguntas y 24 de los desempates.
  'shopping-cart': LucideIcons.shoppingCart,
  'shelving-unit': LucideIcons.shelvingUnit,
  'refrigerator': LucideIcons.refrigerator,
  'mountain': LucideIcons.mountain,
  'eye': LucideIcons.eye,
  'store': LucideIcons.store,
  'drumstick': LucideIcons.drumstick,
  'rabbit': LucideIcons.rabbit,
  'camera': LucideIcons.camera,
  'folder-search': LucideIcons.folderSearch,
  'school': LucideIcons.school,
  'drafting-compass': LucideIcons.draftingCompass,
  'rocket': LucideIcons.rocket,
  'smartphone': LucideIcons.smartphone,
  'hand-coins': LucideIcons.handCoins,
  'clipboard-pen-line': LucideIcons.clipboardPenLine,
  'ticket': LucideIcons.ticket,
  'clock-arrow-up': LucideIcons.clockArrowUp,
  'route': LucideIcons.route,
  'messages-square': LucideIcons.messagesSquare,
  'user-minus': LucideIcons.userMinus,
  'pencil': LucideIcons.pencil,
  'footprints': LucideIcons.footprints,
  'bus': LucideIcons.bus,
  'calendar-clock': LucideIcons.calendarClock,
  'hospital': LucideIcons.hospital,
  'key-round': LucideIcons.keyRound,
  'receipt': LucideIcons.receipt,
  'blocks': LucideIcons.blocks,
  'goal': LucideIcons.goal,
  'database': LucideIcons.database,
  'rocking-chair': LucideIcons.rockingChair,
  'land-plot': LucideIcons.landPlot,
  'dices': LucideIcons.dices,
  'ghost': LucideIcons.ghost,
  'headphones': LucideIcons.headphones,
  'siren': LucideIcons.siren,
  'badge-percent': LucideIcons.badgePercent,
  'stamp': LucideIcons.stamp,
  'graduation-cap': LucideIcons.graduationCap,
  'house-wifi': LucideIcons.houseWifi,
  'drama': LucideIcons.drama,
  'droplet': LucideIcons.droplet,
  'radio-tower': LucideIcons.radioTower,
  'soup': LucideIcons.soup,
  'map-pinned': LucideIcons.mapPinned,
  'split': LucideIcons.split,
  'pill-bottle': LucideIcons.pillBottle,
};

/// El ícono de [nombre], o [kIconoNeutro] si no está en el mapa o es null.
IconData iconoDelTest(String? nombre) => kIconosDelTest[nombre] ?? kIconoNeutro;
```

- [ ] **Paso 4: Correr la prueba y ver que pasa**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/HU36_jeff/specialty_test_logic_test.dart
```

Esperado: PASS, `+3: All tests passed!`.

- [ ] **Paso 5: Dar formato y analizar**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/pages/specialty_test/specialty_test_logic.dart \
  test/HU36_jeff/specialty_test_logic_test.dart
```

Esperado: `Formatted 2 files (0 changed)`.

```bash
cd "${REPO:?}"
"${FLUTTER:?}" analyze --no-pub
```

Esperado: `6 issues found.`, los 6 de la línea base y ninguno en un archivo de esta tarea.

- [ ] **Paso 6: Commit**

```bash
cd "${REPO:?}"
test "$(git branch --show-current)" = feat/test-especialidad-fe || echo 'PARAR: rama equivocada'
git status --short
git add lib/pages/specialty_test/specialty_test_logic.dart \
  test/HU36_jeff/specialty_test_logic_test.dart
git commit -m 'feat(specialty-test): el mapa cerrado de íconos traduce los 52 nombres de la 2026-09-25.4 y cae al neutro (RF-TEST-5)'
git log -1 --format='%an <%ae>'
git log -1 --format=%B | grep -qi '^co-authored-by:' && echo 'PARAR: el commit trae trailer'
```

Esperado: ningún `PARAR`. Antes del `git add`, `git status --short` lista solo los archivos de la tarea, y el autor es `Jeffangeloss <178797184+jeffangeloss@users.noreply.github.com>`.

---

### Tarea 4: Líneas de Ulises, sello, historial y cuerpo de la evaluación

**Requisitos:** RF-TEST-4 (reglas de cada burbuja, sello k de B, historial, descarte de desempates) y RF-TEST-2 (cuerpo exacto de la evaluación).

**Archivos:**
- Modificar `lib/pages/specialty_test/specialty_test_logic.dart` (sección de la conversación al final)
- Modificar `test/HU36_jeff/specialty_test_logic_test.dart` (imports, grupo `_conversacion`)

**Interfaces:**

- Consume `SpecialtyTestContent`, `TestQuestion`, `TestTask`,
  `TiebreakRecord` y `TiebreakAnswer` de la Tarea 1.
- Produce lo que sigue, que usan el controlador (Tareas 8 y 9) y la pantalla de la
  pregunta (Tarea 12).

```dart
class SelloDeBloque { final int k, total; String get texto; }  // == por valor
class TurnoDeUlises { final List<String> lineas; final SelloDeBloque? sello; }
String? reaccionA(SpecialtyTestContent c, int indice, String respuesta);
SelloDeBloque? selloDe(SpecialtyTestContent c, int indice);
TurnoDeUlises turnoAntesDePregunta(SpecialtyTestContent c, int indice,
  Map<String, String> respuestas);
TurnoDeUlises turnoAntesDeDesempate(TiebreakRecord desempate);
TurnoDeUlises turnoDeEspera(SpecialtyTestContent c, {required bool trasDesempate});
String subtituloDelPaso(SpecialtyTestContent c, int paso);
String textoDeRespuesta(SpecialtyTestContent c, {required List<TestTask> tareas,
  required String respuesta});
class EntradaDelHistorial { final String etiqueta, respuesta; }
List<EntradaDelHistorial> historial(SpecialtyTestContent c,
  Map<String, String> respuestas, List<TiebreakRecord> desempates, int paso);
String textoDeLaPastilla(int n);
String etiquetaDeLaPastilla(int n, {required bool desplegada});
List<TiebreakRecord> desempatesTrasResponder({required int totalPreguntas,
  required List<TiebreakRecord> desempates, required int paso,
  required String respuesta});
int? primerPasoSinResponder(SpecialtyTestContent c,
  Map<String, String> respuestas, List<TiebreakRecord> desempates);
int preguntasRespondidas(SpecialtyTestContent c, Map<String, String> respuestas);
Map<String, dynamic> cuerpoDeEvaluacion({required String version,
  required Map<String, String> respuestas,
  required List<TiebreakRecord> desempates});
```

Un «paso» es un índice. De 0 a T − 1 son las preguntas y desde T, los
desempates en orden.

- [ ] **Paso 1: Escribir la prueba que falla**

Los casos 4 a 11 fijan cada regla de la burbuja con el contenido de prueba, en el que la pregunta 1 y la 4 traen reacción propia, la 2 no, y la 3 y la 5 son escalas con `blockClose` (B = 2).

En `test/HU36_jeff/specialty_test_logic_test.dart`, cambia este bloque, que aparece una sola vez,

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_logic.dart';
```

por este otro.

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ulima_plus/models/specialty_test_models.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_logic.dart';

import 'datos_de_prueba.dart';
```

En `test/HU36_jeff/specialty_test_logic_test.dart`, cambia este bloque, que aparece una sola vez,

```dart
  _iconos();
}
```

por este otro.

```dart
  _iconos();
  _conversacion();
}
```

Agrega al final de `test/HU36_jeff/specialty_test_logic_test.dart`, tras una línea en blanco, este bloque.

```dart
SpecialtyTestContent _contenido([Map<String, dynamic>? json]) =>
    SpecialtyTestContent.tryParse(json ?? contenidoJson())!;

TiebreakRecord _desempate(int order, {String? respuesta}) => TiebreakRecord(
  tiebreak:
      (EvaluationStep.tryParse(
                desempateJson(order: order, id: 'tb-si-vj-$order'),
              )!
              as TiebreakStep)
          .tiebreak,
  ulisesLine: 'Línea del desempate $order.',
  answer: respuesta,
);

void _conversacion() {
  group('UNITARIA · Líneas de Ulises y sello (RF-TEST-4)', () {
    final c = _contenido();
    final r = respuestasCompletas();

    test('caso 4: antes de la pregunta 1 va duelHelp', () {
      final turno = turnoAntesDePregunta(c, 0, const {});
      expect(turno.lineas, [kDuelHelp]);
      expect(turno.sello, isNull);
    });

    test('caso 5: un duelo con reacción propia la usa, sin importar la '
        'respuesta', () {
      expect(turnoAntesDePregunta(c, 1, {'q01': 'none'}).lineas, [
        'Reacción propia de la pregunta uno.',
      ]);
    });

    test('caso 6: sin reacción propia rota pick, both y none con el índice '
        'N − 1 módulo el largo', () {
      // Antes de la pregunta 3 (N = 3) la respondida es la 2, con índice 2.
      // Además la 3 es la primera escala, así que va scaleHelp.
      expect(turnoAntesDePregunta(c, 2, {'q02': 'top'}).lineas, [
        kPick[2],
        kScaleHelp,
      ]);
      expect(turnoAntesDePregunta(c, 2, {'q02': 'bottom'}).lineas, [
        kPick[2],
        kScaleHelp,
      ]);
      expect(turnoAntesDePregunta(c, 2, {'q02': 'both'}).lineas, [
        kBoth[0],
        kScaleHelp,
      ]);
      expect(turnoAntesDePregunta(c, 2, {'q02': 'none'}).lineas, [
        kNone[0],
        kScaleHelp,
      ]);
      final sinReacciones = contenidoJson();
      for (final q in sinReacciones['questions'] as List) {
        (q as Map).remove('reaction');
      }
      final otra = _contenido(sinReacciones);
      expect(turnoAntesDePregunta(otra, 1, {'q01': 'top'}).lineas, [kPick[1]]);
      expect(turnoAntesDePregunta(otra, 4, {'q04': 'both'}).lineas, [kBoth[0]]);
      expect(turnoAntesDePregunta(otra, 4, {'q04': 'top'}).lineas, [kPick[4]]);
    });

    test('caso 7: una escala con blockClose lo usa y trae el sello k de B', () {
      final turno = turnoAntesDePregunta(c, 3, r);
      expect(turno.lineas, ['Cierre de prueba del bloque uno.']);
      expect(turno.sello, const SelloDeBloque(1, 2));
      expect(turno.sello!.texto, 'Cierra el bloque 1 de 2');
    });

    test('caso 8: una escala sin blockClose rota la lista de scale y no trae '
        'sello', () {
      final json = contenidoJson();
      ((json['questions'] as List)[2] as Map).remove('blockClose');
      final otra = _contenido(json);
      final turno = turnoAntesDePregunta(otra, 3, r);
      // N − 1 = 3, y 3 módulo 3 es 0.
      expect(turno.lineas, [kScale[0]]);
      expect(turno.sello, isNull);
      // Con un solo blockClose en el contenido, el que queda es el 1 de 1.
      expect(selloDe(otra, 4), const SelloDeBloque(1, 1));
    });

    test('caso 9: una lista vacía no inventa ninguna línea', () {
      final json = contenidoJson();
      final reacciones = (json['ulises'] as Map)['reactions'] as Map;
      reacciones['both'] = <String>[];
      ((json['questions'] as List)[0] as Map).remove('reaction');
      final otra = _contenido(json);
      expect(turnoAntesDePregunta(otra, 1, {'q01': 'both'}).lineas, isEmpty);
    });

    test('caso 10: el desempate usa la línea del servidor y la espera, el '
        'cierre de la última y la línea de espera', () {
      expect(turnoAntesDeDesempate(_desempate(1)).lineas, [
        'Línea del desempate 1.',
      ]);
      final espera = turnoDeEspera(c, trasDesempate: false);
      expect(espera.lineas, ['Cierre de prueba del bloque dos.', kLoading]);
      expect(espera.sello, const SelloDeBloque(2, 2));
      final trasDesempate = turnoDeEspera(c, trasDesempate: true);
      expect(trasDesempate.lineas, [kLoading]);
      expect(trasDesempate.sello, isNull);
    });

    test('caso 11: el subtítulo cuenta las preguntas del contenido y nombra '
        'los desempates', () {
      expect(subtituloDelPaso(c, 0), 'Pregunta 1 de 5');
      expect(subtituloDelPaso(c, 4), 'Pregunta 5 de 5');
      expect(subtituloDelPaso(c, 5), 'Desempate 1');
      expect(subtituloDelPaso(c, 6), 'Desempate 2');
    });
  });

  group('UNITARIA · Historial y desempates (RF-TEST-4)', () {
    final c = _contenido();

    test('caso 12: el historial lista lo respondido antes del paso, sin '
        'colores', () {
      final filas = historial(c, respuestasCompletas(), const [], 5);
      expect(filas.map((f) => f.etiqueta), ['1', '2', '3', '4', '5']);
      expect(filas.map((f) => f.respuesta), [
        'Tarea de prueba uno arriba',
        'Me gustan las dos',
        'Bastante · Tarea de prueba tres en escala',
        'Ninguna me llama',
        'Nada · Tarea de prueba cinco en escala',
      ]);
      expect(historial(c, respuestasCompletas(), const [], 2), hasLength(2));
    });

    test('caso 13: los desempates van como «Desempate 1» y «Desempate 2»', () {
      final filas = historial(c, respuestasCompletas(), [
        _desempate(1, respuesta: 'bottom'),
        _desempate(2),
      ], 6);
      expect(filas, hasLength(6));
      expect(filas.last.etiqueta, 'Desempate 1');
      expect(filas.last.respuesta, 'Tarea de desempate 1 abajo');
    });

    test('caso 14: la pastilla dice N respuestas o 1 respuesta, y su '
        'etiqueta dice ver u ocultar', () {
      expect(textoDeLaPastilla(1), '1 respuesta anterior');
      expect(textoDeLaPastilla(4), '4 respuestas anteriores');
      expect(
        etiquetaDeLaPastilla(4, desplegada: false),
        'Ver tus 4 respuestas anteriores',
      );
      expect(
        etiquetaDeLaPastilla(1, desplegada: false),
        'Ver tu respuesta anterior',
      );
      expect(
        etiquetaDeLaPastilla(4, desplegada: true),
        'Ocultar tus respuestas anteriores',
      );
    });

    test('caso 15: responder una pregunta borra todos los desempates, y '
        'responder el 1 borra el 2', () {
      final dos = [
        _desempate(1, respuesta: 'top'),
        _desempate(2, respuesta: 'bottom'),
      ];
      expect(
        desempatesTrasResponder(
          totalPreguntas: 5,
          desempates: dos,
          paso: 3,
          respuesta: 'top',
        ),
        isEmpty,
      );
      final trasElPrimero = desempatesTrasResponder(
        totalPreguntas: 5,
        desempates: dos,
        paso: 5,
        respuesta: 'both',
      );
      expect(trasElPrimero, hasLength(1));
      expect(trasElPrimero.single.answer, 'both');
      final trasElSegundo = desempatesTrasResponder(
        totalPreguntas: 5,
        desempates: dos,
        paso: 6,
        respuesta: 'none',
      );
      expect(trasElSegundo.map((d) => d.answer), ['top', 'none']);
    });

    test(
      'caso 16: el primer paso sin responder y las preguntas respondidas',
      () {
        expect(primerPasoSinResponder(c, const {}, const []), 0);
        expect(
          primerPasoSinResponder(c, {'q01': 'top', 'q02': 'none'}, const []),
          2,
        );
        expect(
          primerPasoSinResponder(c, respuestasCompletas(), [_desempate(1)]),
          5,
        );
        expect(
          primerPasoSinResponder(c, respuestasCompletas(), const []),
          isNull,
        );
        expect(preguntasRespondidas(c, {'q01': 'top', 'q03': 'nada'}), 2);
      },
    );

    test('caso 17: el cuerpo de la evaluación es exactamente version, '
        'answers y tiebreakAnswers', () {
      final cuerpo = cuerpoDeEvaluacion(
        version: kVersionDePrueba,
        respuestas: respuestasCompletas(),
        desempates: [
          _desempate(1, respuesta: 'bottom'),
          _desempate(2),
        ],
      );
      expect(cuerpo, {
        'version': kVersionDePrueba,
        'answers': respuestasCompletas(),
        'tiebreakAnswers': [
          {'id': 'tb-si-vj-1', 'answer': 'bottom'},
        ],
      });
      expect(
        cuerpoDeEvaluacion(
          version: kVersionDePrueba,
          respuestas: respuestasCompletas(),
          desempates: const [],
        )['tiebreakAnswers'],
        isEmpty,
      );
    });
  });
}
```

- [ ] **Paso 2: Correr la prueba y ver que falla**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/HU36_jeff/specialty_test_logic_test.dart
```

Esperado: FALLA al compilar, sin llegar a correr ningún caso. La salida trae 41 errores distintos (líneas `Error:`), y los primeros dicen esto (las rutas pueden salir absolutas).

```text
test/HU36_jeff/specialty_test_logic_test.dart:139:14: Error: Method not found: 'turnoAntesDePregunta'.
test/HU36_jeff/specialty_test_logic_test.dart:148:14: Error: Method not found: 'turnoAntesDePregunta'.
```

- [ ] **Paso 3: Agregar la sección de la conversación**

Agrega al final de `lib/pages/specialty_test/specialty_test_logic.dart`, tras una línea en blanco, este bloque.

```dart
// ── La conversación con Ulises (RF-TEST-4) ────────────────────────────────────
//
// Un «paso» del recorrido es un índice. De 0 a T − 1 son las preguntas del
// contenido y desde T van los desempates, en orden.

/// El sello «Cierra el bloque k de B» que cae junto a un `blockClose`.
class SelloDeBloque {
  const SelloDeBloque(this.k, this.total);

  /// Orden de la pregunta entre las que traen `blockClose`.
  final int k;

  /// Cuántas preguntas del contenido traen `blockClose`.
  final int total;

  String get texto => 'Cierra el bloque $k de $total';

  @override
  bool operator ==(Object other) =>
      other is SelloDeBloque && other.k == k && other.total == total;

  @override
  int get hashCode => Object.hash(k, total);
}

/// El último turno de Ulises, con sus burbujas en orden y el sello si una de
/// ellas es un `blockClose`. La app no escribe ninguna línea propia.
class TurnoDeUlises {
  const TurnoDeUlises(this.lineas, {this.sello});

  final List<String> lineas;
  final SelloDeBloque? sello;
}

String? _rotar(List<String> lista, int n) =>
    lista.isEmpty ? null : lista[n % lista.length];

/// La reacción a la respuesta [respuesta] de la pregunta de índice [indice].
/// Un duelo usa su `reaction` o, sin ella, la lista de `pick`, `both` o
/// `none`; una escala, su `blockClose` o la lista de `scale`. De la lista va
/// la línea de índice N − 1 módulo su largo, donde N − 1 = [indice] + 1 es el
/// número de la pregunta respondida.
String? reaccionA(
  SpecialtyTestContent contenido,
  int indice,
  String respuesta,
) {
  final pregunta = contenido.questions[indice];
  final reacciones = contenido.ulises.reactions;
  final numero = indice + 1;
  if (pregunta.isDuel) {
    if (pregunta.reaction != null) return pregunta.reaction;
    final lista = switch (respuesta) {
      'both' => reacciones.both,
      'none' => reacciones.none,
      _ => reacciones.pick,
    };
    return _rotar(lista, numero);
  }
  return pregunta.blockClose ?? _rotar(reacciones.scale, numero);
}

/// El sello de la pregunta de índice [indice], o null si no trae
/// `blockClose`. El contrato no manda el campo `block`, y esta cuenta da el
/// mismo número.
SelloDeBloque? selloDe(SpecialtyTestContent contenido, int indice) {
  if (contenido.questions[indice].blockClose == null) return null;
  final conCierre = <int>[
    for (var i = 0; i < contenido.questions.length; i++)
      if (contenido.questions[i].blockClose != null) i,
  ];
  return SelloDeBloque(conCierre.indexOf(indice) + 1, conCierre.length);
}

/// El turno de Ulises antes de la pregunta de índice [indice].
TurnoDeUlises turnoAntesDePregunta(
  SpecialtyTestContent contenido,
  int indice,
  Map<String, String> respuestas,
) {
  final lineas = <String>[];
  SelloDeBloque? sello;
  if (indice == 0) {
    final ayuda = contenido.ulises.duelHelp;
    if (ayuda != null) lineas.add(ayuda);
  } else {
    final previa = contenido.questions[indice - 1];
    final reaccion = reaccionA(
      contenido,
      indice - 1,
      respuestas[previa.id] ?? '',
    );
    if (reaccion != null) lineas.add(reaccion);
    if (!previa.isDuel && previa.blockClose != null) {
      sello = selloDe(contenido, indice - 1);
    }
  }
  final primeraEscala = contenido.questions.indexWhere((q) => !q.isDuel);
  final ayudaEscala = contenido.ulises.scaleHelp;
  if (indice == primeraEscala && ayudaEscala != null) lineas.add(ayudaEscala);
  return TurnoDeUlises(lineas, sello: sello);
}

/// El turno antes de un desempate, con la línea que manda el servidor.
TurnoDeUlises turnoAntesDeDesempate(TiebreakRecord desempate) =>
    TurnoDeUlises([?desempate.ulisesLine]);

/// El turno de la espera, con el `blockClose` de la última pregunta y su
/// sello, si lo trae y la espera sigue a esa pregunta, y la línea de espera.
TurnoDeUlises turnoDeEspera(
  SpecialtyTestContent contenido, {
  required bool trasDesempate,
}) {
  final lineas = <String>[];
  SelloDeBloque? sello;
  if (!trasDesempate) {
    final ultima = contenido.questions.length - 1;
    final cierre = contenido.questions[ultima].blockClose;
    if (cierre != null) {
      lineas.add(cierre);
      sello = selloDe(contenido, ultima);
    }
  }
  final espera = contenido.ulises.loading;
  if (espera != null) lineas.add(espera);
  return TurnoDeUlises(lineas, sello: sello);
}

/// «Pregunta N de T», «Desempate 1» o «Desempate 2».
String subtituloDelPaso(SpecialtyTestContent contenido, int paso) {
  final total = contenido.totalQuestions;
  return paso < total
      ? 'Pregunta ${paso + 1} de $total'
      : 'Desempate ${paso - total + 1}';
}

/// El texto de una respuesta en el historial, que es la tarea elegida, «Me
/// gustan las dos», «Ninguna me llama» o, en una escala,
/// «`<etiqueta> · <tarea>`».
String textoDeRespuesta(
  SpecialtyTestContent contenido, {
  required List<TestTask> tareas,
  required String respuesta,
}) {
  if (tareas.length == 1) {
    final etiqueta = contenido.optionLabel(respuesta) ?? respuesta;
    return '$etiqueta · ${tareas.single.text}';
  }
  return switch (respuesta) {
    'top' => tareas.first.text,
    'bottom' => tareas.last.text,
    _ => contenido.optionLabel(respuesta) ?? respuesta,
  };
}

/// Una fila del historial, con el número de la pregunta, o «Desempate k», y
/// la respuesta.
class EntradaDelHistorial {
  const EntradaDelHistorial(this.etiqueta, this.respuesta);

  final String etiqueta;
  final String respuesta;
}

/// Lo respondido antes del paso [paso], en orden y sin colores.
List<EntradaDelHistorial> historial(
  SpecialtyTestContent contenido,
  Map<String, String> respuestas,
  List<TiebreakRecord> desempates,
  int paso,
) {
  final total = contenido.totalQuestions;
  final filas = <EntradaDelHistorial>[];
  for (var i = 0; i < paso && i < total; i++) {
    final pregunta = contenido.questions[i];
    final respuesta = respuestas[pregunta.id];
    if (respuesta == null) continue;
    filas.add(
      EntradaDelHistorial(
        '${i + 1}',
        textoDeRespuesta(
          contenido,
          tareas: pregunta.tasks,
          respuesta: respuesta,
        ),
      ),
    );
  }
  for (var j = 0; j < paso - total && j < desempates.length; j++) {
    final d = desempates[j];
    final respuesta = d.answer;
    if (respuesta == null) continue;
    filas.add(
      EntradaDelHistorial(
        'Desempate ${j + 1}',
        textoDeRespuesta(
          contenido,
          tareas: [d.tiebreak.top, d.tiebreak.bottom],
          respuesta: respuesta,
        ),
      ),
    );
  }
  return filas;
}

/// «N respuestas anteriores» o «1 respuesta anterior».
String textoDeLaPastilla(int n) =>
    n == 1 ? '1 respuesta anterior' : '$n respuestas anteriores';

/// La etiqueta de la pastilla para el lector de pantalla. Con una sola
/// respuesta va en singular, como la pastilla.
String etiquetaDeLaPastilla(int n, {required bool desplegada}) {
  if (desplegada) return 'Ocultar tus respuestas anteriores';
  return n == 1
      ? 'Ver tu respuesta anterior'
      : 'Ver tus $n respuestas anteriores';
}

/// Los desempates que quedan tras responder el paso [paso] con [respuesta].
/// Responder una pregunta los borra todos, porque el servidor decide cuáles
/// tocan. Responder el desempate i conserva los anteriores, le pone la
/// respuesta y borra los siguientes.
List<TiebreakRecord> desempatesTrasResponder({
  required int totalPreguntas,
  required List<TiebreakRecord> desempates,
  required int paso,
  required String respuesta,
}) {
  if (paso < totalPreguntas) return const <TiebreakRecord>[];
  final i = paso - totalPreguntas;
  return [...desempates.take(i), desempates[i].withAnswer(respuesta)];
}

/// El primer paso sin responder, o null si todo está respondido y toca
/// evaluar. Sirve para seguir un test en pausa (RF-TEST-3).
int? primerPasoSinResponder(
  SpecialtyTestContent contenido,
  Map<String, String> respuestas,
  List<TiebreakRecord> desempates,
) {
  final pregunta = contenido.questions.indexWhere(
    (q) => !respuestas.containsKey(q.id),
  );
  if (pregunta >= 0) return pregunta;
  final desempate = desempates.indexWhere((d) => d.answer == null);
  if (desempate >= 0) return contenido.totalQuestions + desempate;
  return null;
}

/// Cuántas preguntas del contenido tienen respuesta, la N de «Tienes un test
/// a medias, N de T.» (RF-TEST-10).
int preguntasRespondidas(
  SpecialtyTestContent contenido,
  Map<String, String> respuestas,
) => contenido.questions.where((q) => respuestas.containsKey(q.id)).length;

/// El cuerpo exacto de `POST /specialty-test/me/evaluate` (RS-BE-39), con la
/// versión con la que el alumno responde, las respuestas por id de pregunta y
/// los desempates respondidos en orden. Nunca lleva datos del alumno.
Map<String, dynamic> cuerpoDeEvaluacion({
  required String version,
  required Map<String, String> respuestas,
  required List<TiebreakRecord> desempates,
}) => <String, dynamic>{
  'version': version,
  'answers': Map<String, String>.of(respuestas),
  'tiebreakAnswers': <Map<String, dynamic>>[
    for (final d in desempates)
      if (d.answer != null)
        TiebreakAnswer(id: d.tiebreak.id, answer: d.answer!).toJson(),
  ],
};
```

- [ ] **Paso 4: Correr la prueba y ver que pasa**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/HU36_jeff/specialty_test_logic_test.dart
```

Esperado: PASS, `+17: All tests passed!`.

- [ ] **Paso 5: Dar formato y analizar**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/pages/specialty_test/specialty_test_logic.dart \
  test/HU36_jeff/specialty_test_logic_test.dart
```

Esperado: `Formatted 2 files (0 changed)`.

```bash
cd "${REPO:?}"
"${FLUTTER:?}" analyze --no-pub
```

Esperado: `6 issues found.`, los 6 de la línea base y ninguno en un archivo de esta tarea.

- [ ] **Paso 6: Commit**

```bash
cd "${REPO:?}"
test "$(git branch --show-current)" = feat/test-especialidad-fe || echo 'PARAR: rama equivocada'
git status --short
git add lib/pages/specialty_test/specialty_test_logic.dart \
  test/HU36_jeff/specialty_test_logic_test.dart
git commit -m 'feat(specialty-test): las líneas de Ulises, el sello, el historial y el cuerpo de la evaluación salen de funciones puras (RF-TEST-4)'
git log -1 --format='%an <%ae>'
git log -1 --format=%B | grep -qi '^co-authored-by:' && echo 'PARAR: el commit trae trailer'
```

Esperado: ningún `PARAR`. Antes del `git add`, `git status --short` lista solo los archivos de la tarea, y el autor es `Jeffangeloss <178797184+jeffangeloss@users.noreply.github.com>`.

---

### Tarea 5: Selección oficial, corazones y fecha en Lima

**Requisitos:** RF-TEST-9 (cuerpo del `PUT` al elegir y con los corazones), RF-TEST-14 (selección oficial) y RF-TEST-10 (fecha en hora de Lima).

**Archivos:**
- Modificar `lib/pages/specialty_test/specialty_test_logic.dart` (secciones de la selección y de la fecha al final)
- Modificar `test/HU36_jeff/specialty_test_logic_test.dart` (grupo `_seleccion`)

**Interfaces:**

- No consume nada nuevo.
- Produce lo que sigue, que usan el controlador (Tarea 10), el Perfil (Tarea 17), el
  asistente (Tarea 18) y la tarjeta del Perfil (Tarea 16).

```dart
class SeleccionDeEspecialidades { final int? principal;
  final List<int> intereses; }                    // == por valor
SeleccionDeEspecialidades seleccionOficial({required int? principal,
  required Iterable<int> intereses, required Set<int> oficiales});
Set<int> corazonesIniciales({required Iterable<int> intereses,
  required Iterable<int> idsDelRanking});
SeleccionDeEspecialidades seleccionAlElegir({required int elegida,
  required int? principalActual, required Set<int> corazones,
  required List<int> idsDelRanking, int? otraGanadora});
SeleccionDeEspecialidades seleccionConCorazones({required int? principalActual,
  required Set<int> corazones, required List<int> idsDelRanking});
String fechaEnLima(DateTime instante);           // «dd/mm/aaaa»
```

- [ ] **Paso 1: Escribir la prueba que falla**

En `test/HU36_jeff/specialty_test_logic_test.dart`, cambia este bloque, que aparece una sola vez,

```dart
  _conversacion();
}
```

por este otro.

```dart
  _conversacion();
  _seleccion();
}
```

Agrega al final de `test/HU36_jeff/specialty_test_logic_test.dart`, tras una línea en blanco, este bloque.

```dart
void _seleccion() {
  // El ranking de prueba es vj (7), si (6), ti (5) y sw (1).
  const ranking = <int>[kIdVj, kIdSi, kIdTi, kIdSw];

  group(
    'UNITARIA · Selección oficial y corazones (RF-TEST-9 y RF-TEST-14)',
    () {
      test('caso 18: la selección oficial saca los ids antiguos y la principal '
          'de los intereses', () {
        expect(
          seleccionOficial(
            principal: 3,
            intereses: [kIdSi, 3, 99, kIdSi, kIdTi],
            oficiales: {kIdSw, kIdTi, kIdSi, kIdVj},
          ),
          const SeleccionDeEspecialidades(intereses: [kIdSi, kIdTi]),
        );
        expect(
          seleccionOficial(
            principal: kIdSi,
            intereses: [kIdSi, kIdVj],
            oficiales: {kIdSw, kIdTi, kIdSi, kIdVj},
          ),
          const SeleccionDeEspecialidades(principal: kIdSi, intereses: [kIdVj]),
        );
      });

      test('caso 19: al abrir, los corazones son los intereses que están en '
          'el ranking', () {
        expect(
          corazonesIniciales(intereses: [kIdSi, 3], idsDelRanking: ranking),
          {kIdSi},
        );
      });

      test('caso 20: elegir la ganadora manda los corazones sin ella', () {
        expect(
          seleccionAlElegir(
            elegida: kIdVj,
            principalActual: null,
            corazones: {kIdTi, kIdVj},
            idsDelRanking: ranking,
          ),
          const SeleccionDeEspecialidades(principal: kIdVj, intereses: [kIdTi]),
        );
      });

      test('caso 21: una principal anterior del ranking pasa a interés; una '
          'antigua no viaja', () {
        expect(
          seleccionAlElegir(
            elegida: kIdVj,
            principalActual: kIdSw,
            corazones: {kIdTi},
            idsDelRanking: ranking,
          ),
          const SeleccionDeEspecialidades(
            principal: kIdVj,
            intereses: [kIdTi, kIdSw],
          ),
        );
        expect(
          seleccionAlElegir(
            elegida: kIdVj,
            principalActual: 3,
            corazones: const {},
            idsDelRanking: ranking,
          ),
          const SeleccionDeEspecialidades(principal: kIdVj),
        );
      });

      test(
        'caso 22: con empate, la ganadora que no se elige pasa a interés',
        () {
          expect(
            seleccionAlElegir(
              elegida: kIdSi,
              principalActual: null,
              corazones: const {},
              idsDelRanking: [kIdSi, kIdVj, kIdTi, kIdSw],
              otraGanadora: kIdVj,
            ),
            const SeleccionDeEspecialidades(
              principal: kIdSi,
              intereses: [kIdVj],
            ),
          );
        },
      );

      test('caso 23: un corazón deja la principal como está y manda los '
          'corazones en el orden del ranking', () {
        expect(
          seleccionConCorazones(
            principalActual: kIdSw,
            corazones: {kIdTi, kIdSi},
            idsDelRanking: ranking,
          ),
          const SeleccionDeEspecialidades(
            principal: kIdSw,
            intereses: [kIdSi, kIdTi],
          ),
        );
        // Una principal antigua no viaja (decisión abierta 26).
        expect(
          seleccionConCorazones(
            principalActual: 3,
            corazones: {kIdTi},
            idsDelRanking: ranking,
          ),
          const SeleccionDeEspecialidades(intereses: [kIdTi]),
        );
      });
    },
  );

  group('UNITARIA · Fecha en hora de Lima (RF-TEST-10)', () {
    test(
      'caso 24: la fecha sale en UTC−5 sin importar la zona del teléfono',
      () {
        expect(fechaEnLima(DateTime.utc(2026, 9, 26, 3, 30)), '25/09/2026');
        expect(fechaEnLima(DateTime.utc(2026, 9, 25, 20, 15)), '25/09/2026');
        expect(fechaEnLima(DateTime.utc(2026, 9, 26, 4, 59)), '25/09/2026');
        expect(fechaEnLima(DateTime.utc(2026, 9, 26, 5)), '26/09/2026');
        expect(fechaEnLima(DateTime.utc(2027, 1, 1, 2)), '31/12/2026');
        expect(
          fechaEnLima(DateTime.utc(2026, 3, 5, 12).toLocal()),
          '05/03/2026',
        );
      },
    );
  });
}
```

- [ ] **Paso 2: Correr la prueba y ver que falla**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/HU36_jeff/specialty_test_logic_test.dart
```

Esperado: FALLA al compilar, sin llegar a correr ningún caso. La salida trae 23 errores distintos (líneas `Error:`), y los primeros dicen esto (las rutas pueden salir absolutas).

```text
test/HU36_jeff/specialty_test_logic_test.dart:367:17: Error: Couldn't find constructor 'SeleccionDeEspecialidades'.
test/HU36_jeff/specialty_test_logic_test.dart:370:11: Error: Method not found: 'seleccionOficial'.
```

- [ ] **Paso 3: Agregar la selección y la fecha**

Agrega al final de `lib/pages/specialty_test/specialty_test_logic.dart`, tras una línea en blanco, este bloque.

```dart
// ── Selección de especialidades (RF-TEST-9 y RF-TEST-14) ─────────────────────

/// Una selección lista para `PUT /academic-profile/me/specialties`, que
/// reemplaza la selección entera (BR-AP-04).
class SeleccionDeEspecialidades {
  const SeleccionDeEspecialidades({
    this.principal,
    this.intereses = const <int>[],
  });

  final int? principal;
  final List<int> intereses;

  @override
  bool operator ==(Object other) =>
      other is SeleccionDeEspecialidades &&
      other.principal == principal &&
      other.intereses.length == intereses.length &&
      Iterable<int>.generate(
        intereses.length,
      ).every((i) => other.intereses[i] == intereses[i]);

  @override
  int get hashCode => Object.hash(principal, Object.hashAll(intereses));

  @override
  String toString() => 'Seleccion($principal, $intereses)';
}

/// La principal solo si es oficial y los intereses oficiales sin la
/// principal, en su orden y sin repetir (RF-TEST-14). Así nunca viaja un id
/// antiguo, que con BR-AP-07 daría `404 SPECIALTY_NOT_FOUND`.
SeleccionDeEspecialidades seleccionOficial({
  required int? principal,
  required Iterable<int> intereses,
  required Set<int> oficiales,
}) {
  final principalOficial = principal != null && oficiales.contains(principal)
      ? principal
      : null;
  final vistos = <int>{};
  final interesesOficiales = <int>[
    for (final id in intereses)
      if (oficiales.contains(id) && id != principalOficial && vistos.add(id))
        id,
  ];
  return SeleccionDeEspecialidades(
    principal: principalOficial,
    intereses: interesesOficiales,
  );
}

/// Los corazones marcados al abrir el resultado, que son los intereses del
/// alumno que están en el ranking.
Set<int> corazonesIniciales({
  required Iterable<int> intereses,
  required Iterable<int> idsDelRanking,
}) {
  final ranking = idsDelRanking.toSet();
  return intereses.where(ranking.contains).toSet();
}

List<int> _enOrdenDelRanking(Set<int> ids, List<int> idsDelRanking) =>
    idsDelRanking.where(ids.contains).toList();

/// La selección al elegir [elegida] como principal. Los intereses son los
/// corazones, la principal anterior si es otra y está en el ranking
/// (decisión abierta 23) y, con empate, la otra ganadora (decisión abierta
/// 11). Los ids salen solo del ranking.
SeleccionDeEspecialidades seleccionAlElegir({
  required int elegida,
  required int? principalActual,
  required Set<int> corazones,
  required List<int> idsDelRanking,
  int? otraGanadora,
}) {
  final intereses = <int>{...corazones, ?principalActual, ?otraGanadora}
    ..remove(elegida);
  return seleccionOficial(
    principal: elegida,
    intereses: _enOrdenDelRanking(intereses, idsDelRanking),
    oficiales: idsDelRanking.toSet(),
  );
}

/// La selección de un corazón o de «Decidir después», con la principal
/// actual sin cambios y los corazones como intereses.
SeleccionDeEspecialidades seleccionConCorazones({
  required int? principalActual,
  required Set<int> corazones,
  required List<int> idsDelRanking,
}) => seleccionOficial(
  principal: principalActual,
  intereses: _enOrdenDelRanking(corazones, idsDelRanking),
  oficiales: idsDelRanking.toSet(),
);

// ── Fecha en hora de Lima (RF-TEST-10) ────────────────────────────────────────

/// Lima está en UTC−5 todo el año, sin horario de verano.
const Duration _desfaseLima = Duration(hours: 5);

/// «dd/mm/aaaa» de [instante] en hora de Lima, sin depender de la zona del
/// teléfono.
String fechaEnLima(DateTime instante) {
  final lima = instante.toUtc().subtract(_desfaseLima);
  final dd = lima.day.toString().padLeft(2, '0');
  final mm = lima.month.toString().padLeft(2, '0');
  return '$dd/$mm/${lima.year}';
}
```

- [ ] **Paso 4: Correr la prueba y ver que pasa**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/HU36_jeff/specialty_test_logic_test.dart
```

Esperado: PASS, `+24: All tests passed!`.

- [ ] **Paso 5: Dar formato y analizar**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/pages/specialty_test/specialty_test_logic.dart \
  test/HU36_jeff/specialty_test_logic_test.dart
```

Esperado: `Formatted 2 files (0 changed)`.

```bash
cd "${REPO:?}"
"${FLUTTER:?}" analyze --no-pub
```

Esperado: `6 issues found.`, los 6 de la línea base y ninguno en un archivo de esta tarea.

- [ ] **Paso 6: Commit**

```bash
cd "${REPO:?}"
test "$(git branch --show-current)" = feat/test-especialidad-fe || echo 'PARAR: rama equivocada'
git status --short
git add lib/pages/specialty_test/specialty_test_logic.dart \
  test/HU36_jeff/specialty_test_logic_test.dart
git commit -m 'feat(specialty-test): la selección oficial, los corazones y la fecha en Lima salen de funciones puras (RF-TEST-9 y RF-TEST-14)'
git log -1 --format='%an <%ae>'
git log -1 --format=%B | grep -qi '^co-authored-by:' && echo 'PARAR: el commit trae trailer'
```

Esperado: ningún `PARAR`. Antes del `git add`, `git status --short` lista solo los archivos de la tarea, y el autor es `Jeffangeloss <178797184+jeffangeloss@users.noreply.github.com>`.

---

### Tarea 6: Capa de datos SpecialtyTestService

**Requisitos:** RF-TEST-2 (tres rutas, plazos, guarda por dueño, precarga, pausa, último resultado y traducción de errores).

**Archivos:**
- Crear `lib/services/specialty_test_service.dart`
- Crear `test/HU36_jeff/dobles_de_red.dart` (`ApiFalsaDelTest`, `AuthConUsuario`, `AlmacenDePrueba`)
- Crear `test/HU36_jeff/specialty_test_service_test.dart`

**Interfaces:**

- Consume `ApiClient` con `getJson` y `postJson`, `ApiException`
  (`lib/services/api_client.dart`, sin cambios), `AuthService.to.currentUser`
  con `.code` e `.isTeacher`, y los modelos de la Tarea 1.
- Produce lo que sigue, que usan `AuthService.logout()` (Tarea 7), el controlador, la
  tarjeta del Perfil y el asistente.

```dart
enum SpecialtyTestFailureKind { notAvailable, versionOutdated, invalidAnswers,
  tiebreakMismatch, rateLimited, offline, server }
class SpecialtyTestFailure implements Exception { final SpecialtyTestFailureKind
  kind; final String? message, currentVersion, expectedTiebreak;
  final int? retryAfterMinutes; static SpecialtyTestFailure from(Object e); }
enum LastResultStatus { loading, none, loaded, error, notAvailable }
class PausedSpecialtyTest { final SpecialtyTestContent content;
  final Map<String, String> answers; final List<TiebreakRecord> tiebreaks;
  int get answeredQuestions; }
class SpecialtyTestService extends GetxService {
  SpecialtyTestService({ApiClient? apiClient});
  static SpecialtyTestService get to;
  static const Duration contentTimeout, resultTimeout;   // 15 s
  static const Duration evaluateTimeout;                 // 20 s
  static const Duration saveTimeout;                     // 15 s, para completeSetup
  SpecialtyTestContent? get content; PausedSpecialtyTest? get paused;
  LastResultStatus get lastResultStatus; LastSpecialtyTestResult? get lastResult;
  void clear();
  Future<SpecialtyTestContent> fetchContent();           // lanza SpecialtyTestFailure
  void prefetchContent();
  Future<SpecialtyTestContent>? takePrefetch();
  Future<EvaluationStep> evaluate(Map<String, dynamic> body); // lanza
  Future<void> loadLastResult({bool force = false});     // nunca lanza
  void pause(PausedSpecialtyTest test); void discardPaused(); }
```

```dart
// test/HU36_jeff/dobles_de_red.dart
class ApiFalsaDelTest extends ApiClient { ApiFalsaDelTest({List<Object>?
  contenido, evaluaciones, resultados, guardados, carreras, especialidades});
  int getsDeContenido, getsDeResultado, getsDeCarreras, getsDeEspecialidades;
  List<Map<String, dynamic>> cuerposDeEvaluacion, cuerposDeGuardado;
  List<String> llamadas; }
Map<String, dynamic> respuestaDeGuardado(Map<String, dynamic> body);
Map<String, dynamic> carrerasJson();
Map<String, dynamic> especialidadesJson({List<int>? ids});
class AuthConUsuario extends AuthService { Rx<UserModel?> userRx; }
class AlmacenDePrueba extends StorageService { String? token;
  int setupsGuardados; }
```

- [ ] **Paso 1: Escribir los dobles y la prueba que falla**

Cada cola de `ApiFalsaDelTest` devuelve un Map, espera un Completer o lanza cualquier otra cosa, y la última respuesta se repite. Los plazos se prueban con `testWidgets`, cuyo reloj falso avanza con `tester.pump(duración)`. `AlmacenDePrueba` todavía no se usa, y lo usa la Tarea 7.

Crea `test/HU36_jeff/dobles_de_red.dart` con este contenido.

```dart
// test/HU36_jeff/dobles_de_red.dart
//
// Dobles escritos a mano para las pruebas del test de especialidad (HU36).
// No es un archivo de pruebas. Nada de mockito ni mocktail.

import 'dart:async';

import 'package:get/get.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/storage_service.dart';

import 'datos_de_prueba.dart';

/// Un `ApiClient` sin red. Cada ruta tiene su cola de respuestas en orden, y
/// la última se repite. Un Map se devuelve, un Completer se espera y
/// cualquier otra cosa se lanza.
class ApiFalsaDelTest extends ApiClient {
  ApiFalsaDelTest({
    List<Object>? contenido,
    List<Object>? evaluaciones,
    List<Object>? resultados,
    List<Object>? guardados,
    List<Object>? carreras,
    List<Object>? especialidades,
  }) : contenido = contenido ?? <Object>[contenidoJson()],
       evaluaciones = evaluaciones ?? <Object>[resultadoJson()],
       resultados = resultados ?? <Object>[ultimoResultadoJson()],
       guardados = guardados ?? const <Object>[],
       carreras = carreras ?? <Object>[carrerasJson()],
       especialidades = especialidades ?? <Object>[especialidadesJson()],
       super(configuredBaseUrl: 'http://test');

  final List<Object> contenido;
  final List<Object> evaluaciones;
  final List<Object> resultados;

  /// Sin respuestas propias, el `PUT` devuelve lo que recibe.
  final List<Object> guardados;
  final List<Object> carreras;
  final List<Object> especialidades;

  int getsDeContenido = 0;
  int getsDeResultado = 0;
  int getsDeCarreras = 0;
  int getsDeEspecialidades = 0;
  final List<Map<String, dynamic>> cuerposDeEvaluacion =
      <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> cuerposDeGuardado = <Map<String, dynamic>>[];

  /// "VERBO /ruta" de cada llamada, en orden.
  final List<String> llamadas = <String>[];

  Future<Map<String, dynamic>> _responder(List<Object> cola, int indice) {
    final r = cola[indice < cola.length ? indice : cola.length - 1];
    if (r is Completer<Map<String, dynamic>>) return r.future;
    if (r is Map<String, dynamic>) {
      return Future<Map<String, dynamic>>.value(r);
    }
    return Future<Map<String, dynamic>>.error(r);
  }

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    String? token,
    Map<String, String?> query = const {},
    bool suppressSessionExpiry = false,
  }) {
    llamadas.add('GET $path');
    switch (path) {
      case '/specialty-test/content':
        return _responder(contenido, getsDeContenido++);
      case '/specialty-test/me/result':
        return _responder(resultados, getsDeResultado++);
      case '/academic-profile/careers':
        return _responder(carreras, getsDeCarreras++);
      case '/academic-profile/specialties':
        return _responder(especialidades, getsDeEspecialidades++);
    }
    return Future<Map<String, dynamic>>.error(
      StateError('ruta sin respuesta de prueba: $path'),
    );
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) {
    llamadas.add('POST $path');
    if (path == '/specialty-test/me/evaluate') {
      cuerposDeEvaluacion.add(body);
      return _responder(evaluaciones, cuerposDeEvaluacion.length - 1);
    }
    // POST /auth/logout y cualquier otro no tienen nada que responder.
    return Future<Map<String, dynamic>>.value(<String, dynamic>{});
  }

  @override
  Future<Map<String, dynamic>> putJson(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) {
    llamadas.add('PUT $path');
    cuerposDeGuardado.add(body);
    if (guardados.isEmpty) {
      return Future<Map<String, dynamic>>.value(respuestaDeGuardado(body));
    }
    return _responder(guardados, cuerposDeGuardado.length - 1);
  }
}

/// Lo que responde `PUT /academic-profile/me/specialties` a [body].
Map<String, dynamic> respuestaDeGuardado(Map<String, dynamic> body) =>
    <String, dynamic>{
      'message': 'Specialties updated',
      'specialties': <dynamic>[
        if (body['primarySpecialtyId'] != null)
          <String, dynamic>{
            'specialtyId': body['primarySpecialtyId'],
            'selectionType': 'primary',
          },
        for (final id in body['interestSpecialtyIds'] as List)
          <String, dynamic>{'specialtyId': id, 'selectionType': 'interest'},
      ],
    };

/// `GET /academic-profile/careers` con la carrera de prueba.
Map<String, dynamic> carrerasJson() => <String, dynamic>{
  'careers': <dynamic>[
    <String, dynamic>{
      'id': 1,
      'code': 'ING-PRUEBA',
      'name': 'Carrera de Prueba',
      'faculty': 'Facultad de Prueba',
    },
  ],
};

/// `GET /academic-profile/specialties` con las cuatro oficiales, con los
/// campos que la app lee.
Map<String, dynamic> especialidadesJson({List<int>? ids}) {
  const nombres = <int, String>{
    kIdSw: 'Ingeniería de Software',
    kIdTi: 'Tecnologías de la Información',
    kIdSi: 'Sistemas de Información',
    kIdVj: 'Desarrollo de Videojuegos',
  };
  final lista = ids ?? nombres.keys.toList();
  return <String, dynamic>{
    'specialties': <dynamic>[
      for (var i = 0; i < lista.length; i++)
        <String, dynamic>{
          'id': lista[i],
          'carrera_id': 1,
          'name': nombres[lista[i]] ?? 'ESPECIALIDAD DE PRUEBA ${lista[i]}',
          'description': 'Descripción de prueba.',
          'is_active': true,
          'display_order': i + 1,
        },
    ],
  };
}

/// Un `AuthService` que solo pone un usuario, como en las pruebas de HU35.
class AuthConUsuario extends AuthService {
  AuthConUsuario(UserModel? user) : userRx = Rx<UserModel?>(user);

  final Rx<UserModel?> userRx;

  @override
  UserModel? get currentUser => userRx.value;

  @override
  Rx<UserModel?> get currentUserRx => userRx;

  @override
  Future<void> refreshCurrentUser() async {}
}

/// Un `StorageService` en memoria, con un token de prueba. No toca
/// `shared_preferences` ni el llavero.
class AlmacenDePrueba extends StorageService {
  AlmacenDePrueba({this.token = 'token-de-prueba'});

  String? token;
  int setupsGuardados = 0;

  @override
  Future<String?> get savedToken async => token;

  @override
  Future<void> saveToken(String token) async => this.token = token;

  @override
  Future<void> saveCode(String code) async {}

  @override
  Future<void> saveSetup({
    required String code,
    required int careerId,
    int? especialidadPrincipal,
    required List<int> especialidadesInteres,
    required bool setupComplete,
  }) async => setupsGuardados++;

  @override
  Future<void> clearSession() async => token = null;
}
```

Crea `test/HU36_jeff/specialty_test_service_test.dart` con este contenido.

```dart
// test/HU36_jeff/specialty_test_service_test.dart
//
// Pruebas unitarias de HU36, el test de especialidad, sobre la capa de datos
// (RF-TEST-2).
// Servicio: lib/services/specialty_test_service.dart
//
// Datos inventados (datos_de_prueba.dart) y dobles escritos a mano
// (dobles_de_red.dart). El alumno de prueba es 20230001.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:ulima_plus/models/specialty_test_models.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';

AuthConUsuario _loguear([String code = '20230001', String role = 'student']) {
  final auth = AuthConUsuario(alumno(code: code, role: role));
  Get.put<AuthService>(auth);
  return auth;
}

SpecialtyTestService _servicio(ApiFalsaDelTest api) =>
    Get.put<SpecialtyTestService>(SpecialtyTestService(apiClient: api));

ApiException _api(int status, String code, {Object? details}) => ApiException(
  statusCode: status,
  code: code,
  message: 'Mensaje de prueba de $code.',
  details: details,
);

void main() {
  // Get.put de un GetxService agenda onReady con
  // Get.engine.addPostFrameCallback, que necesita el binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(Get.reset);
  tearDown(Get.reset);

  _contenido();
  _errores();
  _evaluacion();
  _ultimoResultado();
  _dueno();
}

void _contenido() {
  group('UNITARIA · Contenido y precarga (RF-TEST-2)', () {
    test(
      'caso 1: fetchContent pide la ruta y deja la copia de la sesión',
      () async {
        _loguear();
        final api = ApiFalsaDelTest();
        final s = _servicio(api);
        expect(s.content, isNull);
        final c = await s.fetchContent();
        expect(api.llamadas, ['GET /specialty-test/content']);
        expect(c.version, kVersionDePrueba);
        expect(s.content, same(c));
      },
    );

    test('caso 2: dos pedidos en vuelo comparten un GET, y la apertura '
        'siguiente pide otra vez', () async {
      _loguear();
      final pendiente = Completer<Map<String, dynamic>>();
      final api = ApiFalsaDelTest(
        contenido: [
          pendiente,
          contenidoJson(version: '2026-09-25.5'),
        ],
      );
      final s = _servicio(api);
      final a = s.fetchContent();
      final b = s.fetchContent();
      expect(api.getsDeContenido, 1);
      pendiente.complete(contenidoJson());
      expect((await a).version, kVersionDePrueba);
      expect(await b, same(await a));
      final otra = await s.fetchContent();
      expect(api.getsDeContenido, 2);
      expect(otra.version, '2026-09-25.5');
      expect(s.content, same(otra));
    });

    test('caso 3: la precarga es el pedido de la primera apertura y se usa '
        'una sola vez', () async {
      _loguear();
      final pendiente = Completer<Map<String, dynamic>>();
      final api = ApiFalsaDelTest(contenido: [pendiente]);
      final s = _servicio(api);
      s.prefetchContent();
      s.prefetchContent();
      expect(api.getsDeContenido, 1);
      final precarga = s.takePrefetch();
      expect(precarga, isNotNull);
      expect(s.takePrefetch(), isNull);
      expect(api.getsDeContenido, 1);
      pendiente.complete(contenidoJson());
      expect((await precarga!).version, kVersionDePrueba);
    });

    test('caso 4: una precarga que falla no lanza fuera y se entrega en '
        'error a quien la toma', () async {
      _loguear();
      final api = ApiFalsaDelTest(contenido: [http.ClientException('sin red')]);
      final s = _servicio(api);
      s.prefetchContent();
      await pumpEventQueue();
      final precarga = s.takePrefetch()!;
      await expectLater(
        precarga,
        throwsA(
          isA<SpecialtyTestFailure>().having(
            (f) => f.kind,
            'kind',
            SpecialtyTestFailureKind.offline,
          ),
        ),
      );
    });

    testWidgets('caso 5: el contenido vence a los 15 s como sin conexión', (
      tester,
    ) async {
      _loguear();
      final api = ApiFalsaDelTest(
        contenido: [Completer<Map<String, dynamic>>()],
      );
      final s = _servicio(api);
      Object? error;
      unawaited(
        s.fetchContent().then((_) {}, onError: (Object e) => error = e),
      );
      await tester.pump(const Duration(seconds: 14, milliseconds: 999));
      expect(error, isNull);
      await tester.pump(const Duration(milliseconds: 1));
      expect(error, isA<SpecialtyTestFailure>());
      expect(
        (error! as SpecialtyTestFailure).kind,
        SpecialtyTestFailureKind.offline,
      );
    });

    test('caso 6: un contenido que no pasa la validación es un error y no '
        'queda como copia', () async {
      _loguear();
      final roto = contenidoJson()..remove('version');
      final s = _servicio(ApiFalsaDelTest(contenido: [roto]));
      await expectLater(
        s.fetchContent(),
        throwsA(
          isA<SpecialtyTestFailure>()
              .having((f) => f.kind, 'kind', SpecialtyTestFailureKind.server)
              .having((f) => f.message, 'message', isNull),
        ),
      );
      expect(s.content, isNull);
    });

    test(
      'caso 7: un test en pausa queda en memoria del alumno y se borra',
      () async {
        _loguear();
        final s = _servicio(ApiFalsaDelTest());
        final c = await s.fetchContent();
        s.pause(
          PausedSpecialtyTest(
            content: c,
            answers: {'q01': 'top', 'q03': 'nada'},
            tiebreaks: const [],
          ),
        );
        expect(s.paused!.content, same(c));
        expect(s.paused!.answeredQuestions, 2);
        s.discardPaused();
        expect(s.paused, isNull);
      },
    );
  });
}

void _errores() {
  group('UNITARIA · Traducción de errores (RF-TEST-2)', () {
    test('caso 8: cada fallo se traduce a su tipo, con su mensaje y sus '
        'detalles', () {
      final casos = <Object, SpecialtyTestFailureKind>{
        _api(404, 'SPECIALTY_TEST_NOT_AVAILABLE'):
            SpecialtyTestFailureKind.notAvailable,
        _api(409, 'SPECIALTY_TEST_VERSION_OUTDATED'):
            SpecialtyTestFailureKind.versionOutdated,
        _api(400, 'SPECIALTY_TEST_INVALID_ANSWERS'):
            SpecialtyTestFailureKind.invalidAnswers,
        _api(400, 'SPECIALTY_TEST_TIEBREAK_MISMATCH'):
            SpecialtyTestFailureKind.tiebreakMismatch,
        _api(429, 'RATE_LIMITED'): SpecialtyTestFailureKind.rateLimited,
        _api(500, 'INTERNAL_SERVER_ERROR'): SpecialtyTestFailureKind.server,
        _api(413, 'PAYLOAD_TOO_LARGE'): SpecialtyTestFailureKind.server,
        TimeoutException('plazo'): SpecialtyTestFailureKind.offline,
        http.ClientException('sin red'): SpecialtyTestFailureKind.offline,
        StateError('otro'): SpecialtyTestFailureKind.server,
      };
      for (final caso in casos.entries) {
        expect(
          SpecialtyTestFailure.from(caso.key).kind,
          caso.value,
          reason: '${caso.key}',
        );
      }
      expect(
        SpecialtyTestFailure.from(_api(500, 'INTERNAL_SERVER_ERROR')).message,
        'Mensaje de prueba de INTERNAL_SERVER_ERROR.',
      );
      expect(
        SpecialtyTestFailure.from(TimeoutException('plazo')).message,
        isNull,
      );
      expect(
        SpecialtyTestFailure.from(
          _api(
            409,
            'SPECIALTY_TEST_VERSION_OUTDATED',
            details: {'currentVersion': '2026-09-25.5'},
          ),
        ).currentVersion,
        '2026-09-25.5',
      );
      expect(
        SpecialtyTestFailure.from(
          _api(
            400,
            'SPECIALTY_TEST_TIEBREAK_MISMATCH',
            details: {'expected': 'tb-si-vj-1'},
          ),
        ).expectedTiebreak,
        'tb-si-vj-1',
      );
      expect(
        SpecialtyTestFailure.from(
          _api(429, 'RATE_LIMITED', details: {'retryAfterMinutes': 12}),
        ).retryAfterMinutes,
        12,
      );
    });

    test('caso 9: el 404 del contenido llega como notAvailable con el '
        'mensaje del servidor', () async {
      _loguear();
      final s = _servicio(
        ApiFalsaDelTest(contenido: [_api(404, 'SPECIALTY_TEST_NOT_AVAILABLE')]),
      );
      await expectLater(
        s.fetchContent(),
        throwsA(
          isA<SpecialtyTestFailure>()
              .having(
                (f) => f.kind,
                'kind',
                SpecialtyTestFailureKind.notAvailable,
              )
              .having(
                (f) => f.message,
                'message',
                'Mensaje de prueba de SPECIALTY_TEST_NOT_AVAILABLE.',
              ),
        ),
      );
    });
  });
}

void _evaluacion() {
  group('UNITARIA · Evaluación (RF-TEST-2 y RF-TEST-7)', () {
    test(
      'caso 10: evaluate manda el cuerpo tal cual y devuelve el paso',
      () async {
        _loguear();
        final api = ApiFalsaDelTest(
          evaluaciones: [desempateJson(), resultadoJson()],
        );
        final s = _servicio(api);
        final cuerpo = <String, dynamic>{
          'version': kVersionDePrueba,
          'answers': respuestasCompletas(),
          'tiebreakAnswers': <dynamic>[],
        };
        expect(await s.evaluate(cuerpo), isA<TiebreakStep>());
        expect(await s.evaluate(cuerpo), isA<ResultStep>());
        expect(api.llamadas, [
          'POST /specialty-test/me/evaluate',
          'POST /specialty-test/me/evaluate',
        ]);
        expect(api.cuerposDeEvaluacion.first, cuerpo);
      },
    );

    testWidgets('caso 11: la evaluación vence a los 20 s como sin conexión', (
      tester,
    ) async {
      _loguear();
      final s = _servicio(
        ApiFalsaDelTest(evaluaciones: [Completer<Map<String, dynamic>>()]),
      );
      Object? error;
      unawaited(
        s.evaluate(const {}).then((_) {}, onError: (Object e) => error = e),
      );
      await tester.pump(const Duration(seconds: 19, milliseconds: 999));
      expect(error, isNull);
      await tester.pump(const Duration(milliseconds: 1));
      expect(
        (error! as SpecialtyTestFailure).kind,
        SpecialtyTestFailureKind.offline,
      );
    });

    test(
      'caso 12: una respuesta de evaluación que no se lee es un error',
      () async {
        _loguear();
        final s = _servicio(
          ApiFalsaDelTest(
            evaluaciones: [
              <String, dynamic>{'status': 'otro'},
            ],
          ),
        );
        await expectLater(
          s.evaluate(const {}),
          throwsA(isA<SpecialtyTestFailure>()),
        );
      },
    );
  });
}

void _ultimoResultado() {
  group('UNITARIA · Último resultado (RF-TEST-2)', () {
    test('caso 13: sin test, con resultado, error y no disponible', () async {
      _loguear();
      final api = ApiFalsaDelTest(
        resultados: [
          <String, dynamic>{'result': null},
          ultimoResultadoJson(),
          http.ClientException('sin red'),
          _api(404, 'SPECIALTY_TEST_NOT_AVAILABLE'),
        ],
      );
      final s = _servicio(api);
      expect(s.lastResultStatus, LastResultStatus.loading);
      await s.loadLastResult();
      expect(s.lastResultStatus, LastResultStatus.none);
      expect(s.lastResult, isNull);
      await s.loadLastResult(force: true);
      expect(s.lastResultStatus, LastResultStatus.loaded);
      expect(s.lastResult!.winners.single.key, 'vj');
      await s.loadLastResult(force: true);
      expect(s.lastResultStatus, LastResultStatus.error);
      await s.loadLastResult(force: true);
      expect(s.lastResultStatus, LastResultStatus.notAvailable);
      expect(api.getsDeResultado, 4);
    });

    test('caso 14: con respuesta vigente no pide otra vez, y tras un error '
        'sí', () async {
      _loguear();
      final api = ApiFalsaDelTest(
        resultados: [http.ClientException('sin red'), ultimoResultadoJson()],
      );
      final s = _servicio(api);
      await s.loadLastResult();
      expect(s.lastResultStatus, LastResultStatus.error);
      await s.loadLastResult();
      expect(s.lastResultStatus, LastResultStatus.loaded);
      await s.loadLastResult();
      expect(api.getsDeResultado, 2);
    });

    test('caso 15: una evaluación que termina en resultado deja el último '
        'resultado viejo', () async {
      _loguear();
      final api = ApiFalsaDelTest();
      final s = _servicio(api);
      await s.loadLastResult();
      await s.loadLastResult();
      expect(api.getsDeResultado, 1);
      await s.evaluate(const {});
      await s.loadLastResult();
      expect(api.getsDeResultado, 2);
    });

    test(
      'caso 16: sin copia del contenido, la pide junto con el resultado',
      () async {
        _loguear();
        final api = ApiFalsaDelTest();
        final s = _servicio(api);
        await s.loadLastResult();
        await pumpEventQueue();
        expect(api.getsDeContenido, 1);
        expect(s.content, isNotNull);
        await s.loadLastResult(force: true);
        await pumpEventQueue();
        expect(api.getsDeContenido, 1);
      },
    );

    test('caso 17: un docente no dispara el GET', () async {
      _loguear('docente.test', 'teacher');
      final api = ApiFalsaDelTest();
      final s = _servicio(api);
      await s.loadLastResult();
      expect(api.llamadas, isEmpty);
    });

    testWidgets('caso 18: el último resultado vence a los 15 s como error', (
      tester,
    ) async {
      _loguear();
      final s = _servicio(
        ApiFalsaDelTest(resultados: [Completer<Map<String, dynamic>>()]),
      );
      unawaited(s.loadLastResult());
      await tester.pump(const Duration(seconds: 15));
      expect(s.lastResultStatus, LastResultStatus.error);
      // El contenido que se pidió junto con el resultado también vence.
      await tester.pump(const Duration(seconds: 1));
    });
  });
}

void _dueno() {
  group('UNITARIA · Guarda por dueño (RF-TEST-2)', () {
    test('caso 19: lo que llega después de un clear() se descarta', () async {
      _loguear();
      final contenido = Completer<Map<String, dynamic>>();
      final resultado = Completer<Map<String, dynamic>>();
      final api = ApiFalsaDelTest(
        contenido: [contenido, contenidoJson()],
        resultados: [resultado],
      );
      final s = _servicio(api);
      final pedido = s.fetchContent();
      final ultimo = s.loadLastResult();
      s.clear();
      contenido.complete(contenidoJson());
      resultado.complete(ultimoResultadoJson());
      await pedido;
      await ultimo;
      expect(s.content, isNull);
      expect(s.lastResult, isNull);
      expect(s.lastResultStatus, LastResultStatus.loading);
    });

    test('caso 20: otro alumno no ve el estado del anterior', () async {
      final auth = _loguear();
      final s = _servicio(ApiFalsaDelTest());
      final c = await s.fetchContent();
      await s.loadLastResult();
      s.pause(
        PausedSpecialtyTest(content: c, answers: const {}, tiebreaks: const []),
      );
      auth.userRx.value = alumno(code: 'alumna.b.test');
      expect(s.content, isNull);
      expect(s.paused, isNull);
      expect(s.lastResult, isNull);
      await s.loadLastResult();
      expect(s.lastResultStatus, LastResultStatus.loaded);
      auth.userRx.value = alumno();
      expect(s.content, isNull);
    });

    test('caso 21: sin alumno no se guarda un test en pausa', () async {
      final auth = _loguear();
      final s = _servicio(ApiFalsaDelTest());
      final c = await s.fetchContent();
      auth.userRx.value = null;
      s.pause(
        PausedSpecialtyTest(content: c, answers: const {}, tiebreaks: const []),
      );
      auth.userRx.value = alumno();
      expect(s.paused, isNull);
    });
  });
}
```

- [ ] **Paso 2: Correr la prueba y ver que falla**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/HU36_jeff/specialty_test_service_test.dart
```

Esperado: FALLA al compilar, sin llegar a correr ningún caso. La salida trae 51 errores distintos (líneas `Error:`), y los primeros dicen esto (las rutas pueden salir absolutas).

```text
test/HU36_jeff/specialty_test_service_test.dart:29:1: Error: Type 'SpecialtyTestService' not found.
test/HU36_jeff/specialty_test_service_test.dart:30:13: Error: 'SpecialtyTestService' isn't a type.
```

- [ ] **Paso 3: Escribir el service**

Es el único que habla con `/specialty-test/**`. Una respuesta que llega después de un `clear()` o para otro alumno se descarta, igual que en `TimeBlocksService`. Un contenido o un paso que no se leen cuentan como `server` sin mensaje, y el registro dice solo el hecho.

Crea `lib/services/specialty_test_service.dart` con este contenido.

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../models/specialty_test_models.dart';
import 'api_client.dart';
import 'auth_service.dart';

/// Los fallos del test que la app distingue (RF-TEST-2 y RF-TEST-11).
enum SpecialtyTestFailureKind {
  /// `404 SPECIALTY_TEST_NOT_AVAILABLE`, al pedir el contenido o al evaluar.
  notAvailable,

  /// `409 SPECIALTY_TEST_VERSION_OUTDATED`, con `details.currentVersion`.
  versionOutdated,

  /// `400 SPECIALTY_TEST_INVALID_ANSWERS`.
  invalidAnswers,

  /// `400 SPECIALTY_TEST_TIEBREAK_MISMATCH`, con `details.expected`.
  tiebreakMismatch,

  /// `429 RATE_LIMITED`, con `details.retryAfterMinutes`.
  rateLimited,

  /// Plazo vencido o fallo de red sin respuesta.
  offline,

  /// Cualquier otro error, o una respuesta que no se puede leer.
  server,
}

/// Un fallo del test ya traducido. [message] es el del servidor, o null sin
/// respuesta o con una respuesta que no se puede leer.
class SpecialtyTestFailure implements Exception {
  const SpecialtyTestFailure(
    this.kind, {
    this.message,
    this.currentVersion,
    this.expectedTiebreak,
    this.retryAfterMinutes,
  });

  final SpecialtyTestFailureKind kind;
  final String? message;
  final String? currentVersion;
  final String? expectedTiebreak;
  final int? retryAfterMinutes;

  /// Traduce cualquier error de una llamada del test.
  static SpecialtyTestFailure from(Object error) {
    if (error is SpecialtyTestFailure) return error;
    // `http.ClientException` envuelve a `SocketException` en Android e iOS.
    if (error is TimeoutException || error is http.ClientException) {
      return const SpecialtyTestFailure(SpecialtyTestFailureKind.offline);
    }
    if (error is! ApiException) {
      return const SpecialtyTestFailure(SpecialtyTestFailureKind.server);
    }
    final details = error.details is Map ? error.details as Map : const {};
    final kind = switch (error.code) {
      'SPECIALTY_TEST_NOT_AVAILABLE' => SpecialtyTestFailureKind.notAvailable,
      'SPECIALTY_TEST_VERSION_OUTDATED' =>
        SpecialtyTestFailureKind.versionOutdated,
      'SPECIALTY_TEST_INVALID_ANSWERS' =>
        SpecialtyTestFailureKind.invalidAnswers,
      'SPECIALTY_TEST_TIEBREAK_MISMATCH' =>
        SpecialtyTestFailureKind.tiebreakMismatch,
      'RATE_LIMITED' => SpecialtyTestFailureKind.rateLimited,
      _ => SpecialtyTestFailureKind.server,
    };
    final minutos = details['retryAfterMinutes'];
    return SpecialtyTestFailure(
      kind,
      message: error.message,
      currentVersion: details['currentVersion'] is String
          ? details['currentVersion'] as String
          : null,
      expectedTiebreak: details['expected'] is String
          ? details['expected'] as String
          : null,
      retryAfterMinutes: minutos is int ? minutos : null,
    );
  }

  @override
  String toString() => 'SpecialtyTestFailure($kind, $message)';
}

/// Los cinco estados del último resultado (RF-TEST-2).
enum LastResultStatus { loading, none, loaded, error, notAvailable }

/// Un test en pausa, con la copia del contenido con la que arranca, las
/// respuestas y los desempates. Vive solo en memoria (decisión abierta 9).
class PausedSpecialtyTest {
  const PausedSpecialtyTest({
    required this.content,
    required this.answers,
    required this.tiebreaks,
  });

  final SpecialtyTestContent content;
  final Map<String, String> answers;
  final List<TiebreakRecord> tiebreaks;

  /// La N de «Tienes un test a medias, N de T.».
  int get answeredQuestions =>
      content.questions.where((q) => answers.containsKey(q.id)).length;
}

/// Capa de datos del test de especialidad (RF-TEST-2).
///
/// Es el único que llama a `/specialty-test/**`, y ningún widget ni
/// controlador lee ese JSON. Guarda en memoria, atado al código del alumno,
/// la copia vigente del contenido, un test en pausa y el último resultado.
/// Nada va a disco. `AuthService.logout()` llama a [clear], y una respuesta
/// que llega después de un [clear] o para otro alumno se descarta.
class SpecialtyTestService extends GetxService {
  SpecialtyTestService({ApiClient? apiClient})
    : _api = apiClient ?? ApiClient();

  static SpecialtyTestService get to => Get.find();

  /// `ApiClient` no impone plazo, así que el service pone el suyo.
  static const Duration contentTimeout = Duration(seconds: 15);
  static const Duration resultTimeout = Duration(seconds: 15);

  /// Incluye hasta 5 s de Cohere y el arranque en frío (decisión abierta 17).
  static const Duration evaluateTimeout = Duration(seconds: 20);

  /// Plazo de los guardados que lanza el test con
  /// `AuthService.completeSetup` (decisión abierta 24).
  static const Duration saveTimeout = Duration(seconds: 15);

  final ApiClient _api;
  final Rxn<SpecialtyTestContent> _content = Rxn<SpecialtyTestContent>();
  final Rxn<PausedSpecialtyTest> _paused = Rxn<PausedSpecialtyTest>();
  final Rxn<LastSpecialtyTestResult> _last = Rxn<LastSpecialtyTestResult>();
  final Rx<LastResultStatus> _lastStatus = LastResultStatus.loading.obs;

  /// Alumno dueño del estado.
  String? _ownerCode;

  /// Sube con cada [clear]. Una respuesta que vuelve con otro número se
  /// descarta.
  int _generation = 0;

  Future<SpecialtyTestContent>? _contentInFlight;

  /// La precarga del asistente que todavía no usa ninguna apertura.
  Future<SpecialtyTestContent>? _prefetch;

  Future<void>? _lastInFlight;

  /// El último resultado hay que pedirlo otra vez. Empieza en true, y una
  /// evaluación que termina en resultado lo vuelve a poner en true.
  bool _lastStale = true;

  bool get _esDelUsuarioActual {
    final code = AuthService.to.currentUser?.code;
    return code != null && code == _ownerCode;
  }

  /// Ata el estado al alumno actual y descarta el de otro.
  void _adoptarDueno() {
    final code = AuthService.to.currentUser?.code;
    if (code == _ownerCode) return;
    clear();
    _ownerCode = code;
  }

  /// La copia vigente del contenido de la sesión, o null.
  SpecialtyTestContent? get content {
    final c = _content.value;
    return _esDelUsuarioActual ? c : null;
  }

  /// El test en pausa del alumno actual, o null.
  PausedSpecialtyTest? get paused {
    final p = _paused.value;
    return _esDelUsuarioActual ? p : null;
  }

  LastResultStatus get lastResultStatus {
    final s = _lastStatus.value;
    return _esDelUsuarioActual ? s : LastResultStatus.loading;
  }

  LastSpecialtyTestResult? get lastResult {
    final r = _last.value;
    return _esDelUsuarioActual ? r : null;
  }

  /// Vacía todo. Lo llama `AuthService.logout()`.
  void clear() {
    _generation++;
    _ownerCode = null;
    _content.value = null;
    _contentInFlight = null;
    _prefetch = null;
    _paused.value = null;
    _last.value = null;
    _lastStatus.value = LastResultStatus.loading;
    _lastStale = true;
    _lastInFlight = null;
  }

  /// `GET /specialty-test/content`. Cada llamada pide el contenido, salvo
  /// que ya haya un pedido en vuelo, que se comparte. Lanza
  /// [SpecialtyTestFailure]; un contenido que no pasa la validación del
  /// modelo cuenta como error de carga.
  Future<SpecialtyTestContent> fetchContent() {
    _adoptarDueno();
    return _contentInFlight ??= _pedirContenido(_generation);
  }

  Future<SpecialtyTestContent> _pedirContenido(int generation) async {
    try {
      final json = await _api
          .getJson('/specialty-test/content')
          .timeout(contentTimeout);
      final content = SpecialtyTestContent.tryParse(json);
      if (content == null) {
        // Sin datos en el registro, solo el hecho.
        debugPrint('El contenido del test de especialidad no es válido.');
        throw const SpecialtyTestFailure(SpecialtyTestFailureKind.server);
      }
      if (generation == _generation) _content.value = content;
      return content;
    } catch (e) {
      throw SpecialtyTestFailure.from(e);
    } finally {
      if (generation == _generation) _contentInFlight = null;
    }
  }

  /// La precarga del paso de carrera (RF-TEST-1). Pide el contenido en
  /// segundo plano, y un fallo no se muestra.
  void prefetchContent() {
    _adoptarDueno();
    if (_prefetch != null) return;
    final pedido = fetchContent();
    _prefetch = pedido;
    unawaited(pedido.then<void>((_) {}, onError: (Object _) {}));
  }

  /// La precarga sin usar, que es el pedido de la primera apertura desde el
  /// asistente, o null si no hay. Quien la toma la consume.
  Future<SpecialtyTestContent>? takePrefetch() {
    final pedido = _esDelUsuarioActual ? _prefetch : null;
    _prefetch = null;
    return pedido;
  }

  /// `POST /specialty-test/me/evaluate` con [body], que arma
  /// `cuerpoDeEvaluacion`. Si el paso es un resultado, el servidor ya lo
  /// guardó, así que el último resultado queda viejo aunque la app descarte
  /// el paso (RF-TEST-4). Lanza [SpecialtyTestFailure].
  Future<EvaluationStep> evaluate(Map<String, dynamic> body) async {
    _adoptarDueno();
    final generation = _generation;
    try {
      final json = await _api
          .postJson('/specialty-test/me/evaluate', body: body)
          .timeout(evaluateTimeout);
      final step = EvaluationStep.tryParse(json);
      if (step == null) {
        debugPrint('La respuesta de la evaluación del test no es válida.');
        throw const SpecialtyTestFailure(SpecialtyTestFailureKind.server);
      }
      if (step is ResultStep && generation == _generation) _lastStale = true;
      return step;
    } catch (e) {
      throw SpecialtyTestFailure.from(e);
    }
  }

  /// `GET /specialty-test/me/result`. Nunca lanza, y el estado queda en
  /// [lastResultStatus]. Sin [force] no repite un pedido que ya tiene
  /// respuesta vigente. Si todavía no hay copia del contenido, la pide junto
  /// con el resultado para los colores de la tarjeta (RF-TEST-10). Un docente
  /// nunca la dispara.
  Future<void> loadLastResult({bool force = false}) {
    final user = AuthService.to.currentUser;
    if (user == null || user.isTeacher) return Future<void>.value();
    _adoptarDueno();
    if (_lastInFlight != null) return _lastInFlight!;
    final vigente =
        _lastStatus.value == LastResultStatus.loaded ||
        _lastStatus.value == LastResultStatus.none ||
        _lastStatus.value == LastResultStatus.notAvailable;
    if (!force && !_lastStale && vigente) return Future<void>.value();
    if (_content.value == null) {
      unawaited(fetchContent().then<void>((_) {}, onError: (Object _) {}));
    }
    return _lastInFlight = _pedirUltimo(_generation);
  }

  Future<void> _pedirUltimo(int generation) async {
    _lastStatus.value = LastResultStatus.loading;
    _lastStale = false;
    try {
      final json = await _api
          .getJson('/specialty-test/me/result')
          .timeout(resultTimeout);
      if (generation != _generation) return;
      if (!json.containsKey('result')) {
        throw const SpecialtyTestFailure(SpecialtyTestFailureKind.server);
      }
      final raw = json['result'];
      if (raw == null) {
        _last.value = null;
        _lastStatus.value = LastResultStatus.none;
        return;
      }
      final result = LastSpecialtyTestResult.tryParse(raw);
      if (result == null) {
        debugPrint('El último resultado del test no es válido.');
        throw const SpecialtyTestFailure(SpecialtyTestFailureKind.server);
      }
      _last.value = result;
      _lastStatus.value = LastResultStatus.loaded;
    } catch (e) {
      if (generation != _generation) return;
      final failure = SpecialtyTestFailure.from(e);
      if (failure.kind == SpecialtyTestFailureKind.notAvailable) {
        _last.value = null;
        _lastStatus.value = LastResultStatus.notAvailable;
      } else {
        _lastStatus.value = LastResultStatus.error;
        _lastStale = true;
      }
    } finally {
      if (generation == _generation) _lastInFlight = null;
    }
  }

  /// Guarda un test en pausa del alumno actual (RF-TEST-4). Sin alumno no
  /// guarda nada.
  void pause(PausedSpecialtyTest test) {
    if (AuthService.to.currentUser == null) return;
    _adoptarDueno();
    _paused.value = test;
  }

  /// Borra el test en pausa (al terminar, al «Empezar de nuevo» y al saltar
  /// el test).
  void discardPaused() => _paused.value = null;
}
```

- [ ] **Paso 4: Correr la prueba y ver que pasa**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/HU36_jeff/specialty_test_service_test.dart
```

Esperado: PASS, `+21: All tests passed!`.

- [ ] **Paso 5: Dar formato y analizar**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/services/specialty_test_service.dart \
  test/HU36_jeff/dobles_de_red.dart \
  test/HU36_jeff/specialty_test_service_test.dart
```

Esperado: `Formatted 3 files (0 changed)`.

```bash
cd "${REPO:?}"
"${FLUTTER:?}" analyze --no-pub
```

Esperado: `6 issues found.`, los 6 de la línea base y ninguno en un archivo de esta tarea.

- [ ] **Paso 6: Commit**

```bash
cd "${REPO:?}"
test "$(git branch --show-current)" = feat/test-especialidad-fe || echo 'PARAR: rama equivocada'
git status --short
git add lib/services/specialty_test_service.dart \
  test/HU36_jeff/dobles_de_red.dart \
  test/HU36_jeff/specialty_test_service_test.dart
git commit -m 'feat(specialty-test): SpecialtyTestService es la frontera con /specialty-test con plazos, guarda por dueño y precarga (RF-TEST-2)'
git log -1 --format='%an <%ae>'
git log -1 --format=%B | grep -qi '^co-authored-by:' && echo 'PARAR: el commit trae trailer'
```

Esperado: ningún `PARAR`. Antes del `git add`, `git status --short` lista solo los archivos de la tarea, y el autor es `Jeffangeloss <178797184+jeffangeloss@users.noreply.github.com>`.

---

### Tarea 7: AuthService para el test y registro del service

**Requisitos:** RF-TEST-2 (plazo de `completeSetup`, `clear()` en `logout()`) y RF-TEST-14 (`isOfficialSpecialty`, `catalogsFailed`, `reloadCatalogs`).

**Archivos:**
- Modificar `lib/services/auth_service.dart` (constructor, catálogos, `completeSetup` y `logout`)
- Modificar `lib/main.dart` (import y `Get.put` permanente junto a `TimeBlocksService`)
- Modificar `test/HU36_jeff/specialty_test_service_test.dart` (imports, grupo `_authService`)

**Interfaces:**

- Consume `SpecialtyTestService.clear()` y `saveTimeout` de la Tarea 6, y
  `AlmacenDePrueba` y `ApiFalsaDelTest` de `dobles_de_red.dart`.
- Produce lo que sigue, que usan el controlador, el Perfil y el asistente.

```dart
AuthService({ApiClient? apiClient});   // solo las pruebas pasan apiClient
bool get catalogsFailed;
Set<int> get officialSpecialtyIds;     // ids activos del catálogo cargado
bool isOfficialSpecialty(int id);
Future<bool> reloadCatalogs();         // nunca lanza
Future<void> completeSetup({required int careerId, int? especialidadPrincipal,
  required List<int> especialidadesInteres, Duration? timeout});
```

`getEspecialidadName` no cambia y sigue dando `''` para un id que no está
en el catálogo, porque la malla depende de eso (RF-TEST-14).

- [ ] **Paso 1: Escribir la prueba que falla**

El grupo usa un `AuthService` real sobre la API falsa, con la sesión puesta por `adoptarSesion`, que carga los catálogos como un registro recién hecho.

En `test/HU36_jeff/specialty_test_service_test.dart`, cambia este bloque, que aparece una sola vez,

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:ulima_plus/models/specialty_test_models.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
```

por este otro.

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:ulima_plus/models/specialty_test_models.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/malla_service.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';
import 'package:ulima_plus/services/storage_service.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
```

En `test/HU36_jeff/specialty_test_service_test.dart`, cambia este bloque, que aparece una sola vez,

```dart
  _dueno();
}
```

por este otro.

```dart
  _dueno();
  _authService();
}
```

Agrega al final de `test/HU36_jeff/specialty_test_service_test.dart`, tras una línea en blanco, este bloque.

```dart
/// Un `AuthService` real sobre la API falsa, con sesión puesta por
/// `adoptarSesion`, que carga los catálogos como un registro recién hecho.
Future<AuthService> _sesion(
  ApiFalsaDelTest api, {
  int? principal,
  List<int>? intereses,
}) async {
  Get.put<StorageService>(AlmacenDePrueba());
  final auth = AuthService(apiClient: api);
  Get.put<AuthService>(auth);
  await auth.adoptarSesion(
    token: 'token-de-prueba',
    user: alumno(principal: principal, intereses: intereses),
  );
  return auth;
}

void _authService() {
  group('UNITARIA · AuthService para el test (RF-TEST-2 y RF-TEST-14)', () {
    testWidgets('caso 22: completeSetup con plazo vence a los 15 s sin tocar '
        'el usuario ni las preferencias', (tester) async {
      final api = ApiFalsaDelTest(
        guardados: [Completer<Map<String, dynamic>>()],
      );
      final auth = await _sesion(api, principal: kIdSw);
      Object? error;
      unawaited(
        auth
            .completeSetup(
              careerId: 1,
              especialidadPrincipal: kIdVj,
              especialidadesInteres: [kIdSw],
              timeout: SpecialtyTestService.saveTimeout,
            )
            .then((_) {}, onError: (Object e) => error = e),
      );
      await tester.pump(const Duration(seconds: 14, milliseconds: 999));
      expect(error, isNull);
      await tester.pump(const Duration(milliseconds: 1));
      expect(error, isA<TimeoutException>());
      expect(auth.currentUser!.especialidadPrincipal, kIdSw);
      expect((StorageService.to as AlmacenDePrueba).setupsGuardados, 0);
    });

    testWidgets('caso 23: sin plazo, completeSetup espera lo que haga falta', (
      tester,
    ) async {
      final pendiente = Completer<Map<String, dynamic>>();
      final api = ApiFalsaDelTest(guardados: [pendiente]);
      final auth = await _sesion(api);
      var listo = false;
      unawaited(
        auth
            .completeSetup(
              careerId: 1,
              especialidadPrincipal: kIdVj,
              especialidadesInteres: [kIdVj, kIdSw],
            )
            .then((_) => listo = true),
      );
      await tester.pump(const Duration(seconds: 30));
      expect(listo, isFalse);
      pendiente.complete(respuestaDeGuardado(api.cuerposDeGuardado.single));
      await tester.pump();
      expect(listo, isTrue);
      expect(api.cuerposDeGuardado.single, {
        'primarySpecialtyId': kIdVj,
        'interestSpecialtyIds': [kIdSw],
      });
      expect(auth.currentUser!.especialidadPrincipal, kIdVj);
      expect(auth.currentUser!.especialidadesInteres, [kIdSw]);
    });

    test('caso 24: catalogsFailed distingue un catálogo que no carga de uno '
        'vacío, y reloadCatalogs reintenta', () async {
      final api = ApiFalsaDelTest(
        especialidades: [
          http.ClientException('sin red'),
          http.ClientException('sin red'),
          especialidadesJson(ids: const []),
          especialidadesJson(),
        ],
      );
      final auth = await _sesion(api);
      expect(auth.catalogsFailed, isTrue);
      expect(auth.especialidades, isEmpty);
      expect(await auth.reloadCatalogs(), isTrue);
      expect(auth.catalogsFailed, isFalse);
      expect(auth.especialidades, isEmpty);
      expect(await auth.reloadCatalogs(), isTrue);
      expect(auth.especialidades, hasLength(4));
    });

    test('caso 25: isOfficialSpecialty dice si el id está en el catálogo '
        'cargado y activo', () async {
      final catalogo = especialidadesJson();
      // Un id antiguo que un backend sin BR-AP-07 todavía mandaría inactivo.
      (catalogo['specialties'] as List).add(<String, dynamic>{
        'id': 3,
        'carrera_id': 1,
        'name': 'ESPECIALIDAD ANTIGUA DE PRUEBA',
        'is_active': false,
        'display_order': 5,
      });
      final auth = await _sesion(ApiFalsaDelTest(especialidades: [catalogo]));
      for (final id in [kIdSw, kIdTi, kIdSi, kIdVj]) {
        expect(auth.isOfficialSpecialty(id), isTrue, reason: '$id');
      }
      expect(auth.isOfficialSpecialty(3), isFalse);
      expect(auth.isOfficialSpecialty(99), isFalse);
      expect(auth.officialSpecialtyIds, {kIdSw, kIdTi, kIdSi, kIdVj});
      // getEspecialidadName no cambia y sigue dando '' para un id
      // desconocido.
      expect(auth.getEspecialidadName(99), '');
    });

    test('caso 26: logout() vacía el test y el siguiente pedido vuelve a la '
        'red', () async {
      final api = ApiFalsaDelTest();
      final auth = await _sesion(api);
      Get.put<MallaService>(MallaService());
      final s = _servicio(api);
      final c = await s.fetchContent();
      await s.loadLastResult();
      s.pause(
        PausedSpecialtyTest(content: c, answers: const {}, tiebreaks: const []),
      );
      await auth.logout();
      expect(auth.currentUser, isNull);
      await auth.adoptarSesion(token: 'token-de-prueba', user: alumno());
      expect(s.content, isNull);
      expect(s.paused, isNull);
      expect(s.lastResult, isNull);
      await s.loadLastResult();
      expect(api.getsDeResultado, 2);
    });
  });
}
```

- [ ] **Paso 2: Correr la prueba y ver que falla**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/HU36_jeff/specialty_test_service_test.dart
```

Esperado: FALLA al compilar, sin llegar a correr ningún caso. La salida trae 10 errores distintos (líneas `Error:`), y los primeros dicen esto (las rutas pueden salir absolutas).

```text
test/HU36_jeff/specialty_test_service_test.dart:529:15: Error: No named parameter with the name 'timeout'.
test/HU36_jeff/specialty_test_service_test.dart:581:19: Error: The getter 'catalogsFailed' isn't defined for the type 'AuthService'.
```

- [ ] **Paso 3: Cambiar AuthService**

Son siete ediciones, en este orden. La sexta pone llaves a la línea del récord en `logout()`, porque `dart format` la parte en dos y sin llaves el analizador marca `curly_braces_in_flow_control_structures`.

En `lib/services/auth_service.dart`, cambia este bloque, que aparece una sola vez,

```dart
import 'evaluations_service.dart';
import 'malla_service.dart';
import 'official_grades_service.dart';
import 'storage_service.dart';
import 'time_blocks_service.dart';

class AuthService extends GetxService {
  static AuthService get to => Get.find();
  static const String invalidCredentialsMessage =
      'Código o contraseña incorrectos.';
```

por este otro.

```dart
import 'evaluations_service.dart';
import 'malla_service.dart';
import 'official_grades_service.dart';
import 'specialty_test_service.dart';
import 'storage_service.dart';
import 'time_blocks_service.dart';

class AuthService extends GetxService {
  /// [apiClient] solo lo pasan las pruebas; la app usa el `ApiClient` de
  /// siempre.
  AuthService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  static AuthService get to => Get.find();
  static const String invalidCredentialsMessage =
      'Código o contraseña incorrectos.';
```

En `lib/services/auth_service.dart`, cambia este bloque, que aparece una sola vez,

```dart
    return backendMessage;
  }

  final ApiClient _api = ApiClient();
  final Rx<UserModel?> _currentUser = Rx<UserModel?>(null);
  final RxList<Map<String, dynamic>> _carreras = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _especialidades =
      <Map<String, dynamic>>[].obs;
  final RxBool _loading = false.obs;

  // Instancia única de Google Sign-In.
  // - Web: requiere `clientId` (el client web) para el botón oficial (GIS).
```

por este otro.

```dart
    return backendMessage;
  }

  final ApiClient _api;
  final Rx<UserModel?> _currentUser = Rx<UserModel?>(null);
  final RxList<Map<String, dynamic>> _carreras = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _especialidades =
      <Map<String, dynamic>>[].obs;
  final RxBool _loading = false.obs;

  /// El último intento de cargar los catálogos falló. Distingue un catálogo
  /// que no carga de uno que carga vacío, como el de una carrera sin
  /// especialidades (RF-TEST-14).
  final RxBool _catalogsFailed = false.obs;

  // Instancia única de Google Sign-In.
  // - Web: requiere `clientId` (el client web) para el botón oficial (GIS).
```

En `lib/services/auth_service.dart`, cambia este bloque, que aparece una sola vez,

```dart
  String getEspecialidadName(int id) {
    final match = _especialidades.firstWhereOrNull((e) => e['id'] == id);
    return match != null ? match['name']?.toString() ?? '' : '';
  }

  /// Recarga el usuario actual desde `/auth/me` SIN cerrar la sesión si falla.
```

por este otro.

```dart
  String getEspecialidadName(int id) {
    final match = _especialidades.firstWhereOrNull((e) => e['id'] == id);
    return match != null ? match['name']?.toString() ?? '' : '';
  }

  bool get catalogsFailed => _catalogsFailed.value;

  /// Los ids del catálogo cargado que están activos. Con BR-AP-07 el catálogo
  /// trae solo los cuatro oficiales, y el filtro `is_active` queda como
  /// defensa, igual que en el asistente y en el Perfil.
  Set<int> get officialSpecialtyIds => {
    for (final e in _especialidades)
      if (e['is_active'] == true) ?_parseInt(e['id']),
  };

  /// Si [id] está en el catálogo oficial cargado (RF-TEST-14).
  bool isOfficialSpecialty(int id) => officialSpecialtyIds.contains(id);

  /// El mismo `_loadCatalogs` expuesto para «Reintentar» (RF-TEST-1 y
  /// RF-TEST-14). Devuelve si cargó y nunca lanza.
  Future<bool> reloadCatalogs() async {
    final user = _currentUser.value;
    if (user == null || user.isTeacher) return false;
    try {
      final token = await _requiredToken();
      await _loadCatalogs(token: token, careerId: user.careerId);
      return true;
    } catch (_) {
      _catalogsFailed.value = true;
      return false;
    }
  }

  /// Recarga el usuario actual desde `/auth/me` SIN cerrar la sesión si falla.
```

En `lib/services/auth_service.dart`, cambia este bloque, que aparece una sola vez,

```dart
    } catch (_) {}
  }

  Future<void> completeSetup({
    required int careerId,
    int? especialidadPrincipal,
    required List<int> especialidadesInteres,
  }) async {
    final user = _currentUser.value;
    if (user == null) return;

    final token = await _requiredToken();
    final response = await _api.putJson(
      '/academic-profile/me/specialties',
      token: token,
      body: {
```

por este otro.

```dart
    } catch (_) {}
  }

  /// [timeout] lo pasa solo el test de especialidad (RF-TEST-2 y decisión
  /// abierta 24). Al vencer lanza `TimeoutException` antes de tocar el
  /// usuario y las preferencias, así que una respuesta tardía no cambia nada
  /// en la app. La hoja «Editar» del Perfil y la selección manual siguen sin
  /// plazo.
  Future<void> completeSetup({
    required int careerId,
    int? especialidadPrincipal,
    required List<int> especialidadesInteres,
    Duration? timeout,
  }) async {
    final user = _currentUser.value;
    if (user == null) return;

    final token = await _requiredToken();
    final put = _api.putJson(
      '/academic-profile/me/specialties',
      token: token,
      body: {
```

En `lib/services/auth_service.dart`, cambia este bloque, que aparece una sola vez,

```dart
            .toList(),
      },
    );

    final savedSpecialties = _listFrom(response, 'specialties');
    final savedPrincipal = savedSpecialties
```

por este otro.

```dart
            .toList(),
      },
    );
    final response = timeout == null ? await put : await put.timeout(timeout);

    final savedSpecialties = _listFrom(response, 'specialties');
    final savedPrincipal = savedSpecialties
```

En `lib/services/auth_service.dart`, cambia este bloque, que aparece una sola vez,

```dart
    EvaluationSyllabusService().clear();
    // Con guarda porque, a diferencia de los tres de arriba, hay pruebas que
    // llaman a logout() sin registrar AcademicRecordService (test/HU02_jeff/).
    if (Get.isRegistered<AcademicRecordService>()) AcademicRecordService.to.clear();
    // Los bloques de horario propios (RF-BLQ-7) son horarios de trabajo o de
    // prácticas que el backend protege a propósito (RS-BE-35): se vacían
    // igual que el récord. Con guarda por lo mismo que la línea de arriba.
    if (Get.isRegistered<TimeBlocksService>()) TimeBlocksService.to.clear();
    _profesorSectionIds.clear();
    _currentUser.value = null;
    await _storage.clearSession();
```

por este otro.

```dart
    EvaluationSyllabusService().clear();
    // Con guarda porque, a diferencia de los tres de arriba, hay pruebas que
    // llaman a logout() sin registrar AcademicRecordService (test/HU02_jeff/).
    if (Get.isRegistered<AcademicRecordService>()) {
      AcademicRecordService.to.clear();
    }
    // Los bloques de horario propios (RF-BLQ-7) son horarios de trabajo o de
    // prácticas que el backend protege a propósito (RS-BE-35): se vacían
    // igual que el récord. Con guarda por lo mismo que la línea de arriba.
    if (Get.isRegistered<TimeBlocksService>()) TimeBlocksService.to.clear();
    // El contenido, el test en pausa y el último resultado del test de
    // especialidad (RF-TEST-2). Con guarda por lo mismo que las dos de arriba.
    if (Get.isRegistered<SpecialtyTestService>()) {
      SpecialtyTestService.to.clear();
    }
    _profesorSectionIds.clear();
    _currentUser.value = null;
    await _storage.clearSession();
```

En `lib/services/auth_service.dart`, cambia este bloque, que aparece una sola vez,

```dart
    int? careerId,
    bool suppressSessionExpiry = false,
  }) async {
    final careersResponse = await _api.getJson(
      '/academic-profile/careers',
      token: token,
      suppressSessionExpiry: suppressSessionExpiry,
    );
    _carreras.assignAll(_listFrom(careersResponse, 'careers'));

    final specialtiesResponse = await _api.getJson(
      '/academic-profile/specialties',
      token: token,
      query: {'careerId': careerId?.toString()},
      suppressSessionExpiry: suppressSessionExpiry,
    );
    _especialidades.assignAll(_listFrom(specialtiesResponse, 'specialties'));
  }

  Future<String> _requiredToken() async {
```

por este otro.

```dart
    int? careerId,
    bool suppressSessionExpiry = false,
  }) async {
    try {
      final careersResponse = await _api.getJson(
        '/academic-profile/careers',
        token: token,
        suppressSessionExpiry: suppressSessionExpiry,
      );
      _carreras.assignAll(_listFrom(careersResponse, 'careers'));

      final specialtiesResponse = await _api.getJson(
        '/academic-profile/specialties',
        token: token,
        query: {'careerId': careerId?.toString()},
        suppressSessionExpiry: suppressSessionExpiry,
      );
      _especialidades.assignAll(_listFrom(specialtiesResponse, 'specialties'));
      _catalogsFailed.value = false;
    } catch (_) {
      _catalogsFailed.value = true;
      rethrow;
    }
  }

  Future<String> _requiredToken() async {
```

- [ ] **Paso 4: Registrar el service en main.dart**

El `Get.put` va justo después del de `TimeBlocksService`. La ruta y los bindings llegan en las Tareas 15 y 18.

En `lib/main.dart`, cambia este bloque, que aparece una sola vez,

```dart
import '/services/academic_record_service.dart';
```

por este otro.

```dart
import '/services/academic_record_service.dart';
import '/services/specialty_test_service.dart';
```

En `lib/main.dart`, cambia este bloque, que aparece una sola vez,

```dart
  Get.put<TimeBlocksService>(TimeBlocksService(), permanent: true);
```

por este otro.

```dart
  Get.put<TimeBlocksService>(TimeBlocksService(), permanent: true);
  // Capa de datos del test de especialidad (RF-TEST-2). Permanente porque
  // guarda en memoria la copia del contenido de la sesión, un test en pausa
  // y el último resultado. Tampoco carga nada al arrancar.
  Get.put<SpecialtyTestService>(SpecialtyTestService(), permanent: true);
```

- [ ] **Paso 5: Correr la prueba y ver que pasa**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/HU36_jeff/specialty_test_service_test.dart
```

Esperado: PASS, `+26: All tests passed!`.

- [ ] **Paso 6: Dar formato y analizar**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/services/auth_service.dart \
  lib/main.dart \
  test/HU36_jeff/specialty_test_service_test.dart
```

Esperado: `Formatted 3 files (0 changed)`.

```bash
cd "${REPO:?}"
"${FLUTTER:?}" analyze --no-pub
```

Esperado: `6 issues found.`, los 6 de la línea base y ninguno en un archivo de esta tarea.

- [ ] **Paso 7: Correr la suite completa**

Cambian `auth_service.dart` y `main.dart`, que usan otras funcionalidades. `test/HU02_jeff/user_cache_reset_test.dart` llama a `logout()` sin registrar `SpecialtyTestService`, y la guarda `Get.isRegistered` lo deja pasar. Las subclases de `AuthService` de las pruebas no cambian, porque el parámetro nuevo es opcional. Tarda unos tres minutos.

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub
```

Esperado: PASS, `+1297: All tests passed!`, las `+1196` de la copia en `757a9af` más las 101 de `test/six_seven/` que trae `main` (ver «Línea base»).

- [ ] **Paso 8: Commit**

```bash
cd "${REPO:?}"
test "$(git branch --show-current)" = feat/test-especialidad-fe || echo 'PARAR: rama equivocada'
git status --short
git add lib/services/auth_service.dart \
  lib/main.dart \
  test/HU36_jeff/specialty_test_service_test.dart
git commit -m 'feat(specialty-test): AuthService distingue un catálogo fallido, reintenta, dice qué es oficial y pone plazo a los guardados del test (RF-TEST-2 y RF-TEST-14)'
git log -1 --format='%an <%ae>'
git log -1 --format=%B | grep -qi '^co-authored-by:' && echo 'PARAR: el commit trae trailer'
```

Esperado: ningún `PARAR`. Antes del `git add`, `git status --short` lista solo los archivos de la tarea, y el autor es `Jeffangeloss <178797184+jeffangeloss@users.noreply.github.com>`.

---

### Tarea 8: Controlador, bienvenida, recorrido y pausa

**Requisitos:** RF-TEST-1 (precarga), RF-TEST-3 (estados de la bienvenida, «Seguir el test», «Empezar de nuevo», saltar), RF-TEST-4 (responder, avanzar, atrás, historial, pausa) y las filas de la bienvenida y de las preguntas de RF-TEST-11.

**Archivos:**
- Crear `lib/pages/specialty_test/specialty_test_controller.dart` (sin la evaluación, que llega en la Tarea 9)
- Crear `test/HU36_jeff/dobles_del_controlador.dart` (`AuthDelControlador`, `UiFalsa` y ayudas)
- Crear `test/HU36_jeff/specialty_test_bienvenida_test.dart`, `test/HU36_jeff/specialty_test_conversacion_test.dart` y `test/HU36_jeff/specialty_test_errores_test.dart`

**Interfaces:**

- Consume `SpecialtyTestService` (`paused`, `pause`, `discardPaused`,
  `fetchContent`, `takePrefetch`) de la Tarea 6, `AuthService.to` de la
  Tarea 7 y las funciones de las Tareas 4 y 5.
- Produce lo que sigue, que usan las Tareas 9 a 15.

```dart
enum OrigenDelTest { asistente, perfil }
enum FaseDelTest { bienvenida, pregunta, espera, resultado }
enum EstadoDeCarga { cargando, lista, error }
enum SalidaDelTest { seleccionManual, terminado }
enum TipoDeAviso { error, info, exito }
class AvisoDelTest { final TipoDeAviso tipo; final String mensaje;
  final String? titulo; }
abstract class SpecialtyTestUi { void cerrar([SalidaDelTest? salida]);
  void irAlHome(); void avisar(AvisoDelTest aviso);
  Future<void> pedirReinicio(String mensaje); }
class TextosDelTest { static const String sinConexion, noDisponible,
  noSeGuardo, noSeConfirmo, guardadoTitulo, guardadoMensaje; }
class SpecialtyTestController extends GetxController {
  SpecialtyTestController({required OrigenDelTest origen,
    required SpecialtyTestUi ui, SpecialtyTestService? service,
    AuthService? auth});
  static const Duration pausaDeAvance;          // 350 ms
  final OrigenDelTest origen;
  final Rx<FaseDelTest> fase; final Rx<EstadoDeCarga> carga;
  final Rxn<SpecialtyTestContent> contenido;
  final RxMap<String, String> respuestas; final RxList<TiebreakRecord> desempates;
  final RxInt paso; final RxBool bloqueado, historialAbierto;
  bool get enAsistente, hayAvance, enDesempate; int get totalPreguntas;
  TestQuestion? get preguntaActual; TiebreakRecord? get desempateActual;
  String? get respuestaActual; int? get principalActual;
  void reintentarCarga(); void empezar(); void empezarDeNuevo();
  void saltar(); void ahoraNo(); void pausar();
  void responder(String valor, {bool avanceSolo = true});
  void avanzar(); void atras(); void alternarHistorial(); }
```

```dart
// test/HU36_jeff/dobles_del_controlador.dart
class AuthDelControlador extends AuthService { Rx<UserModel?> userRx;
  List<Object?> respuestasDeGuardado; List<SeleccionDeEspecialidades> guardados;
  List<Duration?> plazos; }
class UiFalsa implements SpecialtyTestUi { List<SalidaDelTest?> cierres;
  int alHome; List<AvisoDelTest> avisos; List<String> reinicios;
  Completer<void>? dialogo; }
({AuthDelControlador auth, SpecialtyTestService service}) prepararTest(
  ApiFalsaDelTest api, {UserModel? usuario});
Future<SpecialtyTestController> montarControlador({OrigenDelTest origen,
  UiFalsa? ui});                    // solo fuera de testWidgets
void responderPasos(SpecialtyTestController c, List<String> valores);
List<String> get respuestasEnOrden;
```

La pantalla es un puerto (`SpecialtyTestUi`), así que las pruebas del
controlador no montan widgets. La versión con GetX llega en la Tarea 15.

- [ ] **Paso 1: Escribir los dobles y las pruebas que fallan**

Tres archivos de prueba nacen aquí con su grupo del controlador, y las Tareas 9 a 15 les suman grupos de pantalla. En el caso 2 de la conversación el controlador se crea con `Get.put` y la carga corre con `tester.pump()`, porque dentro de `testWidgets` `pumpEventQueue` no avanza el reloj falso.

Crea `test/HU36_jeff/dobles_del_controlador.dart` con este contenido.

```dart
// test/HU36_jeff/dobles_del_controlador.dart
//
// Dobles del controlador del test de especialidad (HU36). No es un archivo
// de pruebas.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_logic.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';

/// Un `AuthService` con usuario cuyo `completeSetup` no sale a la red. Cada
/// guardado toma la siguiente respuesta de [respuestasDeGuardado], donde null
/// guarda, un Completer espera y cualquier otra cosa se lanza. Al guardar
/// pone al día el usuario como el real.
class AuthDelControlador extends AuthService {
  AuthDelControlador(UserModel user) : userRx = Rx<UserModel?>(user);

  final Rx<UserModel?> userRx;
  final List<Object?> respuestasDeGuardado = <Object?>[];
  final List<SeleccionDeEspecialidades> guardados =
      <SeleccionDeEspecialidades>[];
  final List<Duration?> plazos = <Duration?>[];

  @override
  UserModel? get currentUser => userRx.value;

  @override
  Rx<UserModel?> get currentUserRx => userRx;

  @override
  Future<void> refreshCurrentUser() async {}

  @override
  Future<void> completeSetup({
    required int careerId,
    int? especialidadPrincipal,
    required List<int> especialidadesInteres,
    Duration? timeout,
  }) async {
    guardados.add(
      SeleccionDeEspecialidades(
        principal: especialidadPrincipal,
        intereses: List<int>.of(especialidadesInteres),
      ),
    );
    plazos.add(timeout);
    final respuesta = respuestasDeGuardado.isEmpty
        ? null
        : respuestasDeGuardado.removeAt(0);
    if (respuesta is Completer<void>) {
      await respuesta.future;
    } else if (respuesta != null) {
      throw respuesta;
    }
    final user = userRx.value!;
    user.especialidadPrincipal = especialidadPrincipal;
    user.especialidadesInteres = especialidadesInteres
        .where((id) => id != especialidadPrincipal)
        .toList();
    user.setupComplete = true;
    userRx.refresh();
  }
}

/// La pantalla falsa, que anota lo que el controlador le pide.
class UiFalsa implements SpecialtyTestUi {
  final List<SalidaDelTest?> cierres = <SalidaDelTest?>[];
  int alHome = 0;
  final List<AvisoDelTest> avisos = <AvisoDelTest>[];
  final List<String> reinicios = <String>[];

  /// Si no es null, el diálogo de reinicio espera a que se complete.
  Completer<void>? dialogo;

  @override
  void cerrar([SalidaDelTest? salida]) => cierres.add(salida);

  @override
  void irAlHome() => alHome++;

  @override
  void avisar(AvisoDelTest aviso) => avisos.add(aviso);

  @override
  Future<void> pedirReinicio(String mensaje) {
    reinicios.add(mensaje);
    return dialogo?.future ?? Future<void>.value();
  }
}

/// Registra el usuario, el service sobre [api] y, si se pide, la precarga.
({AuthDelControlador auth, SpecialtyTestService service}) prepararTest(
  ApiFalsaDelTest api, {
  UserModel? usuario,
}) {
  final auth = AuthDelControlador(usuario ?? alumno());
  Get.put<AuthService>(auth);
  final service = Get.put<SpecialtyTestService>(
    SpecialtyTestService(apiClient: api),
  );
  return (auth: auth, service: service);
}

/// Crea el controlador como lo haría su binding y deja correr la carga.
Future<SpecialtyTestController> montarControlador({
  OrigenDelTest origen = OrigenDelTest.asistente,
  UiFalsa? ui,
}) async {
  final c = Get.put<SpecialtyTestController>(
    SpecialtyTestController(origen: origen, ui: ui ?? UiFalsa()),
  );
  await pumpEventQueue();
  return c;
}

/// Responde en orden cada paso con [valores], sin la pausa de 350 ms.
void responderPasos(SpecialtyTestController c, List<String> valores) {
  for (final v in valores) {
    c.responder(v, avanceSolo: false);
    c.avanzar();
  }
}

/// Las respuestas de [respuestasCompletas] en el orden de las preguntas.
List<String> get respuestasEnOrden => respuestasCompletas().values.toList();
```

Crea `test/HU36_jeff/specialty_test_bienvenida_test.dart` con este contenido.

```dart
// test/HU36_jeff/specialty_test_bienvenida_test.dart
//
// Pruebas de HU36, el test de especialidad, sobre la bienvenida (RF-TEST-3),
// con la precarga del asistente (RF-TEST-1 y RF-TEST-2).
// Controlador: lib/pages/specialty_test/specialty_test_controller.dart
//
// Datos inventados (datos_de_prueba.dart). El alumno de prueba es 20230001.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:ulima_plus/models/specialty_test_models.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';

/// Un test en pausa con la copia de una versión anterior y dos respuestas.
PausedSpecialtyTest _pausado() => PausedSpecialtyTest(
  content: SpecialtyTestContent.tryParse(
    contenidoJson(version: '2026-09-24.1'),
  )!,
  answers: const {'q01': 'top', 'q02': 'none'},
  tiebreaks: const [],
);

void main() {
  // Get.put de un GetxService agenda onReady con
  // Get.engine.addPostFrameCallback, que necesita el binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(Get.reset);
  tearDown(Get.reset);

  _controlador();
}

void _controlador() {
  group('UNITARIA · Bienvenida en el controlador (RF-TEST-1 a RF-TEST-3)', () {
    test(
      'caso 1: desde el asistente usa la precarga y no pide otra vez',
      () async {
        final api = ApiFalsaDelTest();
        prepararTest(api).service.prefetchContent();
        await pumpEventQueue();
        final c = await montarControlador();
        expect(api.getsDeContenido, 1);
        expect(c.carga.value, EstadoDeCarga.lista);
        expect(c.fase.value, FaseDelTest.bienvenida);
        expect(c.contenido.value!.version, kVersionDePrueba);
      },
    );

    test(
      'caso 2: con la precarga en vuelo, la bienvenida espera cargando',
      () async {
        final pendiente = Completer<Map<String, dynamic>>();
        final api = ApiFalsaDelTest(contenido: [pendiente]);
        prepararTest(api).service.prefetchContent();
        final c = await montarControlador();
        expect(c.carga.value, EstadoDeCarga.cargando);
        pendiente.complete(contenidoJson());
        await pumpEventQueue();
        expect(c.carga.value, EstadoDeCarga.lista);
        expect(api.getsDeContenido, 1);
      },
    );

    test(
      'caso 3: si la precarga terminó en error, pide el contenido otra vez',
      () async {
        final api = ApiFalsaDelTest(
          contenido: [http.ClientException('sin red'), contenidoJson()],
        );
        prepararTest(api).service.prefetchContent();
        await pumpEventQueue();
        final c = await montarControlador();
        expect(api.getsDeContenido, 2);
        expect(c.carga.value, EstadoDeCarga.lista);
      },
    );

    test('caso 4: desde el Perfil y en cada apertura siguiente pide el '
        'contenido una vez', () async {
      final api = ApiFalsaDelTest();
      prepararTest(api);
      await montarControlador(origen: OrigenDelTest.perfil);
      expect(api.getsDeContenido, 1);
      Get.delete<SpecialtyTestController>();
      await montarControlador();
      expect(api.getsDeContenido, 2);
    });

    test(
      'caso 5: «Empezar el test» abre la pregunta 1 con la copia vigente',
      () async {
        prepararTest(ApiFalsaDelTest());
        final c = await montarControlador();
        expect(c.hayAvance, isFalse);
        c.empezar();
        expect(c.fase.value, FaseDelTest.pregunta);
        expect(c.paso.value, 0);
        expect(c.preguntaActual!.id, 'q01');
      },
    );

    test('caso 6: mientras carga, el botón principal no hace nada', () async {
      final api = ApiFalsaDelTest(
        contenido: [Completer<Map<String, dynamic>>()],
      );
      prepararTest(api);
      final c = await montarControlador();
      c.empezar();
      expect(c.fase.value, FaseDelTest.bienvenida);
    });

    test('caso 7: un test en pausa sigue en su primer paso sin responder y '
        'con su propia copia', () async {
      final t = prepararTest(
        ApiFalsaDelTest(contenido: [contenidoJson(version: '2026-09-25.5')]),
      );
      t.service.pause(_pausado());
      final c = await montarControlador();
      expect(c.hayAvance, isTrue);
      c.empezar();
      expect(c.fase.value, FaseDelTest.pregunta);
      expect(c.paso.value, 2);
      expect(c.contenido.value!.version, '2026-09-24.1');
    });

    test('caso 8: «Empezar de nuevo» borra las respuestas y abre la pregunta '
        '1 con la copia vigente', () async {
      final t = prepararTest(
        ApiFalsaDelTest(contenido: [contenidoJson(version: '2026-09-25.5')]),
      );
      t.service.pause(_pausado());
      final c = await montarControlador();
      c.empezarDeNuevo();
      expect(c.respuestas, isEmpty);
      expect(t.service.paused, isNull);
      expect(c.paso.value, 0);
      expect(c.fase.value, FaseDelTest.pregunta);
      expect(c.contenido.value!.version, '2026-09-25.5');
    });

    test('caso 9: «Saltar y elegir por mi cuenta» borra las respuestas y '
        'pasa a la selección manual', () async {
      final t = prepararTest(ApiFalsaDelTest());
      t.service.pause(_pausado());
      final ui = UiFalsa();
      final c = await montarControlador(ui: ui);
      c.saltar();
      expect(ui.cierres, [SalidaDelTest.seleccionManual]);
      expect(t.service.paused, isNull);
      Get.delete<SpecialtyTestController>();
      expect(t.service.paused, isNull);
    });

    test(
      'caso 10: «Ahora no» cierra la ruta y deja el avance en pausa',
      () async {
        final t = prepararTest(ApiFalsaDelTest());
        final ui = UiFalsa();
        final c = await montarControlador(origen: OrigenDelTest.perfil, ui: ui);
        c.empezar();
        c.responder('top', avanceSolo: false);
        c.atras();
        expect(c.fase.value, FaseDelTest.bienvenida);
        c.ahoraNo();
        expect(ui.cierres, [null]);
        Get.delete<SpecialtyTestController>();
        expect(t.service.paused!.answers, {'q01': 'top'});
        expect(t.service.paused!.content.version, kVersionDePrueba);
      },
    );

    test('caso 11: sin avance, cerrar no deja nada en pausa', () async {
      final t = prepararTest(ApiFalsaDelTest());
      await montarControlador();
      Get.delete<SpecialtyTestController>();
      expect(t.service.paused, isNull);
    });
  });
}
```

Crea `test/HU36_jeff/specialty_test_conversacion_test.dart` con este contenido.

```dart
// test/HU36_jeff/specialty_test_conversacion_test.dart
//
// Pruebas de HU36, el test de especialidad, sobre la conversación con Ulises
// (RF-TEST-4).
// Controlador: lib/pages/specialty_test/specialty_test_controller.dart
//
// Datos inventados (datos_de_prueba.dart). El alumno de prueba es 20230001.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/specialty_test_models.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';

TiebreakRecord _desempate(int order, {String? respuesta}) => TiebreakRecord(
  tiebreak:
      (EvaluationStep.tryParse(
                desempateJson(order: order, id: 'tb-si-vj-$order'),
              )!
              as TiebreakStep)
          .tiebreak,
  ulisesLine: 'Línea del desempate $order.',
  answer: respuesta,
);

void main() {
  // Get.put de un GetxService agenda onReady con
  // Get.engine.addPostFrameCallback, que necesita el binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(Get.reset);
  tearDown(Get.reset);

  _controlador();
}

void _controlador() {
  group('UNITARIA · Recorrido en el controlador (RF-TEST-4)', () {
    test('caso 1: responder y avanzar recorren las preguntas y guardan cada '
        'respuesta', () async {
      prepararTest(ApiFalsaDelTest());
      final c = await montarControlador();
      c.empezar();
      responderPasos(c, ['top', 'both']);
      expect(c.paso.value, 2);
      expect(c.respuestas, {'q01': 'top', 'q02': 'both'});
      expect(c.preguntaActual!.type, TestQuestionType.scale);
      expect(c.respuestaActual, isNull);
    });

    testWidgets('caso 2: el avance solo llega a los 350 ms y los toques de '
        'ese tiempo no cuentan', (tester) async {
      prepararTest(ApiFalsaDelTest());
      // Dentro de testWidgets el tiempo es falso y pumpEventQueue no avanza,
      // así que la carga corre con tester.pump().
      final c = Get.put<SpecialtyTestController>(
        SpecialtyTestController(origen: OrigenDelTest.asistente, ui: UiFalsa()),
      );
      await tester.pump();
      c.empezar();
      c.responder('top');
      expect(c.bloqueado.value, isTrue);
      c.responder('bottom');
      await tester.pump(const Duration(milliseconds: 349));
      expect(c.paso.value, 0);
      expect(c.respuestas['q01'], 'top');
      await tester.pump(const Duration(milliseconds: 1));
      expect(c.paso.value, 1);
      expect(c.bloqueado.value, isFalse);
    });

    test('caso 3: sin avance solo, la respuesta queda marcada hasta '
        '«Siguiente»', () async {
      prepararTest(ApiFalsaDelTest());
      final c = await montarControlador();
      c.empezar();
      c.responder('none', avanceSolo: false);
      expect(c.paso.value, 0);
      expect(c.respuestaActual, 'none');
      c.responder('top', avanceSolo: false);
      expect(c.respuestaActual, 'top');
      c.avanzar();
      expect(c.paso.value, 1);
      // Sin respuesta, «Siguiente» no avanza.
      c.avanzar();
      expect(c.paso.value, 1);
    });

    test('caso 4: atrás lleva a la anterior con su respuesta marcada, y desde '
        'la 1 a la bienvenida', () async {
      prepararTest(ApiFalsaDelTest());
      final c = await montarControlador();
      c.empezar();
      responderPasos(c, ['top', 'both']);
      c.atras();
      expect(c.paso.value, 1);
      expect(c.respuestaActual, 'both');
      c.atras();
      c.atras();
      expect(c.fase.value, FaseDelTest.bienvenida);
      expect(c.hayAvance, isTrue);
      c.empezar();
      expect(c.paso.value, 2);
    });

    test('caso 5: la última respuesta lleva a la espera, también si se '
        'repite la misma', () async {
      prepararTest(ApiFalsaDelTest());
      final c = await montarControlador();
      c.empezar();
      responderPasos(c, respuestasEnOrden);
      expect(c.fase.value, FaseDelTest.espera);
      c.atras();
      expect(c.fase.value, FaseDelTest.pregunta);
      expect(c.paso.value, 4);
      expect(c.respuestaActual, 'nada');
      responderPasos(c, ['nada']);
      expect(c.fase.value, FaseDelTest.espera);
    });

    test('caso 6: cambiar una pregunta borra los desempates y cambiar el 1 '
        'borra el 2', () async {
      final t = prepararTest(ApiFalsaDelTest());
      t.service.pause(
        PausedSpecialtyTest(
          content: SpecialtyTestContent.tryParse(contenidoJson())!,
          answers: respuestasCompletas(),
          tiebreaks: [
            _desempate(1, respuesta: 'top'),
            _desempate(2),
          ],
        ),
      );
      final c = await montarControlador();
      c.empezar();
      expect(c.paso.value, 6);
      expect(c.enDesempate, isTrue);
      c.atras();
      expect(c.paso.value, 5);
      expect(c.respuestaActual, 'top');
      c.responder('none', avanceSolo: false);
      expect(c.desempates, hasLength(1));
      expect(c.desempates.single.answer, 'none');
      c.atras();
      expect(c.paso.value, 4);
      c.responder('nada', avanceSolo: false);
      expect(c.desempates, isEmpty);
    });

    test('caso 7: el historial se despliega y se pliega, y se pliega al '
        'avanzar', () async {
      prepararTest(ApiFalsaDelTest());
      final c = await montarControlador();
      c.empezar();
      responderPasos(c, ['top']);
      c.alternarHistorial();
      expect(c.historialAbierto.value, isTrue);
      c.alternarHistorial();
      expect(c.historialAbierto.value, isFalse);
      c.alternarHistorial();
      responderPasos(c, ['both']);
      expect(c.historialAbierto.value, isFalse);
    });

    test('caso 8: pausar cierra la ruta y deja las respuestas y la copia en '
        'el service', () async {
      final t = prepararTest(ApiFalsaDelTest());
      final ui = UiFalsa();
      final c = await montarControlador(ui: ui);
      c.empezar();
      responderPasos(c, ['top', 'both']);
      c.pausar();
      expect(ui.cierres, [null]);
      Get.delete<SpecialtyTestController>();
      expect(t.service.paused!.answers, {'q01': 'top', 'q02': 'both'});
      expect(t.service.paused!.answeredQuestions, 2);
    });
  });
}
```

Crea `test/HU36_jeff/specialty_test_errores_test.dart` con este contenido.

```dart
// test/HU36_jeff/specialty_test_errores_test.dart
//
// Pruebas de HU36, el test de especialidad, sobre cada fila de la tabla de
// errores y sin conexión (RF-TEST-11).
// Controlador: lib/pages/specialty_test/specialty_test_controller.dart
//
// Datos inventados (datos_de_prueba.dart). El alumno de prueba es 20230001.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:ulima_plus/models/specialty_test_models.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';

ApiException _api(int status, String code, String mensaje, {Object? details}) =>
    ApiException(
      statusCode: status,
      code: code,
      message: mensaje,
      details: details,
    );

const String _noDisponible =
    'El test de especialidad no está disponible para tu carrera.';

void main() {
  // Get.put de un GetxService agenda onReady con
  // Get.engine.addPostFrameCallback, que necesita el binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(Get.reset);
  tearDown(Get.reset);

  _bienvenida();
}

void _bienvenida() {
  group(
    'UNITARIA · Errores de la bienvenida y de las preguntas (RF-TEST-11)',
    () {
      test('fila 1: sin conexión, contenido no válido o un 500 dejan el error '
          'con el secundario activo', () async {
        final fallas = <Object>[
          http.ClientException('sin red'),
          contenidoJson()..remove('questions'),
          _api(500, 'INTERNAL_SERVER_ERROR', 'Error del servidor'),
        ];
        for (final falla in fallas) {
          Get.reset();
          final t = prepararTest(ApiFalsaDelTest(contenido: [falla]));
          t.service.pause(
            PausedSpecialtyTest(
              content: SpecialtyTestContent.tryParse(contenidoJson())!,
              answers: const {'q01': 'top'},
              tiebreaks: const [],
            ),
          );
          final ui = UiFalsa();
          final c = await montarControlador(ui: ui);
          expect(c.carga.value, EstadoDeCarga.error, reason: '$falla');
          c.empezar();
          expect(c.fase.value, FaseDelTest.bienvenida);
          // «Saltar y elegir por mi cuenta» sigue activo, y un fallo nunca
          // atrapa al alumno en el asistente.
          c.saltar();
          expect(ui.cierres, [SalidaDelTest.seleccionManual]);
        }
      });

      testWidgets('fila 1: el plazo de 15 s también deja el error', (
        tester,
      ) async {
        prepararTest(
          ApiFalsaDelTest(contenido: [Completer<Map<String, dynamic>>()]),
        );
        final c = Get.put<SpecialtyTestController>(
          SpecialtyTestController(origen: OrigenDelTest.perfil, ui: UiFalsa()),
        );
        await tester.pump(const Duration(seconds: 14));
        expect(c.carga.value, EstadoDeCarga.cargando);
        await tester.pump(const Duration(seconds: 1));
        expect(c.carga.value, EstadoDeCarga.error);
      });

      test('fila 1: «Reintentar» pide otra vez y carga', () async {
        final api = ApiFalsaDelTest(
          contenido: [http.ClientException('sin red'), contenidoJson()],
        );
        prepararTest(api);
        final c = await montarControlador();
        expect(c.carga.value, EstadoDeCarga.error);
        c.reintentarCarga();
        await pumpEventQueue();
        expect(c.carga.value, EstadoDeCarga.lista);
        expect(api.getsDeContenido, 2);
      });

      test('fila 2: el 404 en el asistente pasa a la selección manual sin '
          'aviso', () async {
        final t = prepararTest(
          ApiFalsaDelTest(
            contenido: [
              _api(404, 'SPECIALTY_TEST_NOT_AVAILABLE', _noDisponible),
            ],
          ),
        );
        t.service.prefetchContent();
        await pumpEventQueue();
        final ui = UiFalsa();
        await montarControlador(ui: ui);
        expect(ui.cierres, [SalidaDelTest.seleccionManual]);
        expect(ui.avisos, isEmpty);
      });

      test('fila 2: el 404 en el Perfil avisa con el mensaje del servidor y '
          'cierra la ruta', () async {
        prepararTest(
          ApiFalsaDelTest(
            contenido: [
              _api(404, 'SPECIALTY_TEST_NOT_AVAILABLE', _noDisponible),
            ],
          ),
        );
        final ui = UiFalsa();
        await montarControlador(origen: OrigenDelTest.perfil, ui: ui);
        expect(ui.cierres, [null]);
        expect(ui.avisos.single.tipo, TipoDeAviso.info);
        expect(ui.avisos.single.mensaje, _noDisponible);
      });

      test('fila 3: entre pregunta y pregunta el test no usa la red', () async {
        final api = ApiFalsaDelTest();
        prepararTest(api);
        final c = await montarControlador();
        final antes = api.llamadas.length;
        c.empezar();
        responderPasos(c, ['top', 'both', 'bastante', 'none']);
        c.atras();
        c.alternarHistorial();
        expect(api.llamadas.length, antes);
      });
    },
  );
}
```

- [ ] **Paso 2: Correr las pruebas y ver que fallan**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/HU36_jeff/specialty_test_bienvenida_test.dart \
  test/HU36_jeff/specialty_test_conversacion_test.dart \
  test/HU36_jeff/specialty_test_errores_test.dart
```

Esperado: FALLA al compilar, sin llegar a correr ningún caso. La salida trae 62 errores distintos (líneas `Error:`), y los primeros dicen esto (las rutas pueden salir absolutas).

```text
test/HU36_jeff/dobles_del_controlador.dart:11:8: Error: Error when reading 'lib/pages/specialty_test/specialty_test_controller.dart': No such file or directory
test/HU36_jeff/dobles_del_controlador.dart:74:26: Error: Type 'SpecialtyTestUi' not found.
```

- [ ] **Paso 3: Escribir el controlador sin la evaluación**

El bloque final lleva a la espera tras el último paso y no llama al servidor. La Tarea 9 lo reemplaza entero. Dos detalles pesan. `RxMap.assignAll` adopta el mapa que recibe, así que el de la pausa se copia antes. Y cualquier cierre con avance deja el test en pausa desde `onClose`, así que el botón de pausa, «Ahora no» y el atrás del sistema en la bienvenida solo cierran la ruta.

Crea `lib/pages/specialty_test/specialty_test_controller.dart` con este contenido.

```dart
// lib/pages/specialty_test/specialty_test_controller.dart
// El recorrido del test de especialidad (RF-TEST-1 a RF-TEST-11), con la
// bienvenida, las preguntas, el atrás, la pausa, la evaluación, los
// desempates, los reintentos y los guardados del resultado.

import 'dart:async';

import 'package:get/get.dart';

import '../../models/specialty_test_models.dart';
import '../../services/auth_service.dart';
import '../../services/specialty_test_service.dart';
import 'specialty_test_logic.dart';

/// De dónde se abre `/test-especialidad`.
enum OrigenDelTest { asistente, perfil }

/// La pantalla que muestra la ruta.
enum FaseDelTest { bienvenida, pregunta, espera, resultado }

/// La carga del contenido en la bienvenida.
enum EstadoDeCarga { cargando, lista, error }

/// Con qué se cierra la ruta. El asistente pasa a la selección manual con
/// [seleccionManual]; un cierre sin valor lo deja en el paso de carrera.
enum SalidaDelTest { seleccionManual, terminado }

enum TipoDeAviso { error, info, exito }

/// Un aviso pasajero (RF-TEST-11).
class AvisoDelTest {
  const AvisoDelTest(this.tipo, this.mensaje, {this.titulo});

  final TipoDeAviso tipo;
  final String mensaje;

  /// Solo el aviso de éxito del Perfil lleva título.
  final String? titulo;
}

/// Lo que el controlador le pide a la pantalla. La ruta usa la versión con
/// GetX de `specialty_test_page.dart`, y las pruebas, una falsa.
abstract class SpecialtyTestUi {
  /// Cierra la ruta del test.
  void cerrar([SalidaDelTest? salida]);

  /// Termina el asistente con `Get.offAllNamed('/home')`.
  void irAlHome();

  void avisar(AvisoDelTest aviso);

  /// Muestra el diálogo con [mensaje] y «Empezar de nuevo», y termina cuando
  /// el alumno lo toca.
  Future<void> pedirReinicio(String mensaje);
}

/// Textos propios de la app que salen del controlador.
class TextosDelTest {
  static const String sinConexion =
      'No pudimos conectarnos. Revisa tu conexión e inténtalo de nuevo.';
  static const String noDisponible =
      'El test de especialidad no está disponible para tu carrera.';
  static const String noSeGuardo =
      'No se pudo guardar. Revisa tu conexión e inténtalo de nuevo.';
  static const String noSeConfirmo =
      'No se pudo confirmar el guardado. Revisa tu conexión e inténtalo de '
      'nuevo.';
  static const String guardadoTitulo = 'Especialidades actualizadas';
  static const String guardadoMensaje = 'Tu selección se guardó correctamente.';
}

class SpecialtyTestController extends GetxController {
  SpecialtyTestController({
    required this.origen,
    required SpecialtyTestUi ui,
    SpecialtyTestService? service,
    AuthService? auth,
  }) : _ui = ui,
       _service = service ?? SpecialtyTestService.to,
       _auth = auth ?? AuthService.to;

  /// Pausa entre el toque y el avance solo (RF-TEST-5). No es movimiento, así
  /// que se queda con menos movimiento.
  static const Duration pausaDeAvance = Duration(milliseconds: 350);

  final OrigenDelTest origen;
  final SpecialtyTestUi _ui;
  final SpecialtyTestService _service;
  final AuthService _auth;

  final fase = FaseDelTest.bienvenida.obs;
  final carga = EstadoDeCarga.cargando.obs;

  /// La copia del contenido con la que se responde, que es la vigente o la
  /// de un test en pausa.
  final contenido = Rxn<SpecialtyTestContent>();
  final respuestas = <String, String>{}.obs;
  final desempates = <TiebreakRecord>[].obs;

  /// El paso actual. De 0 a T − 1 son preguntas y desde T, desempates.
  final paso = 0.obs;

  /// Los 350 ms entre el toque y el avance, en los que otro toque no hace
  /// nada.
  final bloqueado = false.obs;
  final historialAbierto = false.obs;

  /// La copia vigente que trae la bienvenida, para «Empezar el test» y
  /// «Empezar de nuevo».
  SpecialtyTestContent? _vigente;
  Timer? _avance;
  bool _cerrado = false;

  bool get enAsistente => origen == OrigenDelTest.asistente;

  /// Hay respuestas en memoria, de esta ruta o de un test en pausa.
  bool get hayAvance => respuestas.isNotEmpty || desempates.isNotEmpty;

  int get totalPreguntas => contenido.value?.totalQuestions ?? 0;

  bool get enDesempate => paso.value >= totalPreguntas;

  /// La pregunta del paso actual, o null en un desempate.
  TestQuestion? get preguntaActual {
    final c = contenido.value;
    if (c == null || paso.value >= c.totalQuestions) return null;
    return c.questions[paso.value];
  }

  /// El desempate del paso actual, o null en una pregunta.
  TiebreakRecord? get desempateActual {
    final i = paso.value - totalPreguntas;
    if (i < 0 || i >= desempates.length) return null;
    return desempates[i];
  }

  /// La respuesta marcada en el paso actual, o null.
  String? get respuestaActual {
    final q = preguntaActual;
    if (q != null) return respuestas[q.id];
    return desempateActual?.answer;
  }

  /// La principal actual del alumno, que usan el resultado y sus guardados.
  int? get principalActual => _auth.currentUser?.especialidadPrincipal;

  @override
  void onInit() {
    super.onInit();
    final pausado = _service.paused;
    if (pausado != null) {
      contenido.value = pausado.content;
      // Una copia, porque `RxMap.assignAll` adopta el mapa que recibe, y el
      // de la pausa puede ser de solo lectura.
      respuestas.assignAll(Map<String, String>.of(pausado.answers));
      desempates.assignAll(pausado.tiebreaks);
    }
    unawaited(_cargarContenido());
  }

  @override
  void onClose() {
    _cerrado = true;
    _avance?.cancel();
    // Cualquier cierre con avance deja el test en pausa, sea el botón de
    // pausa, el atrás del sistema en la bienvenida o «Ahora no». Saltar y
    // terminar ya borraron las respuestas.
    final c = contenido.value;
    if (hayAvance && c != null) {
      _service.pause(
        PausedSpecialtyTest(
          content: c,
          answers: Map<String, String>.of(respuestas),
          tiebreaks: List<TiebreakRecord>.of(desempates),
        ),
      );
    }
    super.onClose();
  }

  // ── Bienvenida (RF-TEST-3) ─────────────────────────────────────────────────

  /// Pide el contenido de esta apertura. La primera apertura desde el
  /// asistente usa la precarga (RF-TEST-1), con su copia si ya está, la
  /// espera si sigue en vuelo y otro pedido si terminó en error.
  Future<void> _cargarContenido() async {
    carga.value = EstadoDeCarga.cargando;
    try {
      final precarga = enAsistente ? _service.takePrefetch() : null;
      SpecialtyTestContent vigente;
      if (precarga == null) {
        vigente = await _service.fetchContent();
      } else {
        try {
          vigente = await precarga;
        } on SpecialtyTestFailure catch (f) {
          if (f.kind == SpecialtyTestFailureKind.notAvailable) rethrow;
          vigente = await _service.fetchContent();
        }
      }
      if (_cerrado) return;
      _vigente = vigente;
      contenido.value ??= vigente;
      carga.value = EstadoDeCarga.lista;
    } on SpecialtyTestFailure catch (f) {
      if (_cerrado) return;
      if (f.kind == SpecialtyTestFailureKind.notAvailable) {
        _noDisponible(f.message);
        return;
      }
      carga.value = EstadoDeCarga.error;
    }
  }

  void reintentarCarga() {
    if (carga.value != EstadoDeCarga.error) return;
    unawaited(_cargarContenido());
  }

  /// «Empezar el test», o «Seguir el test» con avance en memoria, que vuelve
  /// al primer paso sin responder con la copia de ese test.
  void empezar() {
    if (carga.value != EstadoDeCarga.lista) return;
    if (!hayAvance) {
      _abrirPreguntaUno(_vigente!);
      return;
    }
    final c = contenido.value!;
    final siguiente = primerPasoSinResponder(c, respuestas, desempates);
    if (siguiente == null) {
      // Con todo respondido, la espera sigue al último paso.
      paso.value = c.totalQuestions + desempates.length - 1;
      _evaluar();
      return;
    }
    paso.value = siguiente;
    fase.value = FaseDelTest.pregunta;
  }

  /// «Empezar de nuevo» borra las respuestas y abre la pregunta 1 con la
  /// copia vigente.
  void empezarDeNuevo() {
    if (carga.value != EstadoDeCarga.lista) return;
    _borrarRespuestas();
    _abrirPreguntaUno(_vigente!);
  }

  void _abrirPreguntaUno(SpecialtyTestContent c) {
    contenido.value = c;
    respuestas.clear();
    desempates.clear();
    paso.value = 0;
    historialAbierto.value = false;
    fase.value = FaseDelTest.pregunta;
  }

  void _borrarRespuestas() {
    respuestas.clear();
    desempates.clear();
    _service.discardPaused();
  }

  /// «Saltar y elegir por mi cuenta» borra las respuestas, y el asistente
  /// pasa a la selección manual.
  void saltar() {
    _borrarRespuestas();
    _ui.cerrar(SalidaDelTest.seleccionManual);
  }

  /// «Ahora no», en el Perfil. Un avance queda en pausa.
  void ahoraNo() => _ui.cerrar();

  /// «Pausar el test y seguir luego». [onClose] guarda el avance.
  void pausar() => _ui.cerrar();

  /// El test no existe para la carrera (`404 SPECIALTY_TEST_NOT_AVAILABLE`).
  /// En el asistente pasa a la selección manual sin aviso; en el Perfil avisa
  /// con el mensaje del servidor y cierra la ruta.
  void _noDisponible(String? mensaje, {bool avisarSiempre = false}) {
    _borrarRespuestas();
    if (!enAsistente || avisarSiempre) {
      _ui.avisar(
        AvisoDelTest(TipoDeAviso.info, mensaje ?? TextosDelTest.noDisponible),
      );
    }
    _ui.cerrar(enAsistente ? SalidaDelTest.seleccionManual : null);
  }

  // ── Preguntas y desempates (RF-TEST-4 a RF-TEST-6) ─────────────────────────

  /// Responde el paso actual con [valor]. Con [avanceSolo], la pregunta
  /// avanza a los 350 ms y en ese tiempo otro toque no hace nada. Sin él
  /// (lector de pantalla activo), avanza con «Siguiente» (RF-TEST-13).
  void responder(String valor, {bool avanceSolo = true}) {
    final c = contenido.value;
    if (c == null || fase.value != FaseDelTest.pregunta || bloqueado.value) {
      return;
    }
    final p = paso.value;
    if (p < c.totalQuestions) respuestas[c.questions[p].id] = valor;
    desempates.assignAll(
      desempatesTrasResponder(
        totalPreguntas: c.totalQuestions,
        desempates: desempates,
        paso: p,
        respuesta: valor,
      ),
    );
    if (!avanceSolo) return;
    bloqueado.value = true;
    _avance = Timer(pausaDeAvance, () {
      bloqueado.value = false;
      avanzar();
    });
  }

  /// Pasa al paso siguiente. Tras la última pregunta o un desempate, va al
  /// desempate que ya está en memoria o evalúa.
  void avanzar() {
    final c = contenido.value;
    if (c == null || fase.value != FaseDelTest.pregunta) return;
    if (respuestaActual == null) return;
    historialAbierto.value = false;
    final p = paso.value;
    final siguiente = p + 1;
    final hayDesempateSiguiente =
        siguiente >= c.totalQuestions &&
        siguiente - c.totalQuestions < desempates.length;
    if (siguiente < c.totalQuestions || hayDesempateSiguiente) {
      paso.value = siguiente;
      return;
    }
    _evaluar();
  }

  /// «Pregunta anterior» y el atrás del sistema en las preguntas y en la
  /// espera (RF-TEST-4). Desde la pregunta 1 vuelve a la bienvenida.
  void atras() {
    switch (fase.value) {
      case FaseDelTest.pregunta:
        _avance?.cancel();
        bloqueado.value = false;
        historialAbierto.value = false;
        if (paso.value == 0) {
          fase.value = FaseDelTest.bienvenida;
        } else {
          paso.value = paso.value - 1;
        }
      case FaseDelTest.espera:
        _descartarEvaluacion();
        fase.value = FaseDelTest.pregunta;
      case FaseDelTest.bienvenida:
      case FaseDelTest.resultado:
        break;
    }
  }

  void alternarHistorial() => historialAbierto.toggle();

  // ── Evaluación, espera y desempates (RF-TEST-7 y RF-TEST-11) ───────────────

  /// La espera tras el último paso. Esta versión todavía no llama al
  /// servidor.
  void _evaluar() => fase.value = FaseDelTest.espera;

  /// Sin una evaluación en vuelo, no hay nada que descartar.
  void _descartarEvaluacion() {}
}
```

- [ ] **Paso 4: Correr las pruebas y ver que pasan**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/HU36_jeff/specialty_test_bienvenida_test.dart \
  test/HU36_jeff/specialty_test_conversacion_test.dart \
  test/HU36_jeff/specialty_test_errores_test.dart
```

Esperado: PASS, `+25: All tests passed!`.

- [ ] **Paso 5: Dar formato y analizar**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/pages/specialty_test/specialty_test_controller.dart \
  test/HU36_jeff/dobles_del_controlador.dart \
  test/HU36_jeff/specialty_test_bienvenida_test.dart \
  test/HU36_jeff/specialty_test_conversacion_test.dart \
  test/HU36_jeff/specialty_test_errores_test.dart
```

Esperado: `Formatted 5 files (0 changed)`.

```bash
cd "${REPO:?}"
"${FLUTTER:?}" analyze --no-pub
```

Esperado: `6 issues found.`, los 6 de la línea base y ninguno en un archivo de esta tarea.

- [ ] **Paso 6: Commit**

```bash
cd "${REPO:?}"
test "$(git branch --show-current)" = feat/test-especialidad-fe || echo 'PARAR: rama equivocada'
git status --short
git add lib/pages/specialty_test/specialty_test_controller.dart \
  test/HU36_jeff/dobles_del_controlador.dart \
  test/HU36_jeff/specialty_test_bienvenida_test.dart \
  test/HU36_jeff/specialty_test_conversacion_test.dart \
  test/HU36_jeff/specialty_test_errores_test.dart
git commit -m 'feat(specialty-test): el controlador conduce la bienvenida, las preguntas, el atrás y la pausa sin red (RF-TEST-3 y RF-TEST-4)'
git log -1 --format='%an <%ae>'
git log -1 --format=%B | grep -qi '^co-authored-by:' && echo 'PARAR: el commit trae trailer'
```

Esperado: ningún `PARAR`. Antes del `git add`, `git status --short` lista solo los archivos de la tarea, y el autor es `Jeffangeloss <178797184+jeffangeloss@users.noreply.github.com>`.

---

### Tarea 9: Controlador, evaluación, espera y desempates

**Requisitos:** RF-TEST-7 (cuándo evalúa, una sola a la vez, desempates, resultado), RF-TEST-4 (atrás desde la espera) y las filas de la espera de RF-TEST-11.

**Archivos:**
- Modificar `lib/pages/specialty_test/specialty_test_controller.dart` (el bloque de la evaluación se reemplaza)
- Crear `test/HU36_jeff/specialty_test_evaluacion_test.dart`
- Modificar `test/HU36_jeff/specialty_test_errores_test.dart` (grupo `_espera`)

**Interfaces:**

- Consume `SpecialtyTestService.evaluate` y `SpecialtyTestFailure`,
  `cuerpoDeEvaluacion` (Tarea 4) y `corazonesIniciales` (Tarea 5).
- Produce lo que sigue, que usan las pantallas de la espera y del resultado.

```dart
final Rxn<SpecialtyTestFailure> errorDeEspera;   // null mientras se espera
final Rxn<SpecialtyTestResult> resultado;
final RxSet<int> corazones;
bool get esperaTrasDesempate;
String get textoDelErrorDeEspera;   // mensaje del servidor o el de sin conexión
void reintentarEvaluacion();
```

- [ ] **Paso 1: Escribir las pruebas que fallan**

Crea `test/HU36_jeff/specialty_test_evaluacion_test.dart` con este contenido.

```dart
// test/HU36_jeff/specialty_test_evaluacion_test.dart
//
// Pruebas de HU36, el test de especialidad, sobre la evaluación, la espera y
// los desempates (RF-TEST-7).
// Controlador: lib/pages/specialty_test/specialty_test_controller.dart
//
// Datos inventados (datos_de_prueba.dart). El alumno de prueba es 20230001.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';

Map<String, dynamic> _cuerpo([
  List<Map<String, dynamic>> desempates = const [],
]) => <String, dynamic>{
  'version': kVersionDePrueba,
  'answers': respuestasCompletas(),
  'tiebreakAnswers': desempates,
};

void main() {
  // Get.put de un GetxService agenda onReady con
  // Get.engine.addPostFrameCallback, que necesita el binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(Get.reset);
  tearDown(Get.reset);

  _controlador();
}

void _controlador() {
  group('UNITARIA · Evaluación en el controlador (RF-TEST-7)', () {
    test('caso 1: tras la última pregunta evalúa con todas las respuestas y '
        'sin desempates', () async {
      final pendiente = Completer<Map<String, dynamic>>();
      final api = ApiFalsaDelTest(evaluaciones: [pendiente]);
      prepararTest(api);
      final c = await montarControlador();
      c.empezar();
      responderPasos(c, respuestasEnOrden);
      expect(c.fase.value, FaseDelTest.espera);
      expect(c.esperaTrasDesempate, isFalse);
      await pumpEventQueue();
      expect(api.cuerposDeEvaluacion.single, _cuerpo());
      pendiente.complete(resultadoJson());
    });

    test('caso 2: el resultado abre el resultado, borra las respuestas y '
        'marca los corazones de los intereses', () async {
      final t = prepararTest(
        ApiFalsaDelTest(),
        usuario: alumno(intereses: [kIdSi, 3]),
      );
      final c = await montarControlador();
      c.empezar();
      responderPasos(c, respuestasEnOrden);
      await pumpEventQueue();
      expect(c.fase.value, FaseDelTest.resultado);
      expect(c.resultado.value!.ranking.first.key, 'vj');
      expect(c.respuestas, isEmpty);
      expect(t.service.paused, isNull);
      expect(c.corazones, {kIdSi});
    });

    test('caso 3: un desempate se muestra como duelo y su respuesta vuelve a '
        'evaluar con los desempates en orden', () async {
      final api = ApiFalsaDelTest(
        evaluaciones: [
          desempateJson(order: 1, id: 'tb-si-vj-1'),
          desempateJson(order: 2, id: 'tb-si-vj-2'),
          resultadoJson(tiebreakOutcome: 'Ahí está, ya se inclinó la balanza.'),
        ],
      );
      prepararTest(api);
      final c = await montarControlador();
      c.empezar();
      responderPasos(c, respuestasEnOrden);
      await pumpEventQueue();
      expect(c.fase.value, FaseDelTest.pregunta);
      expect(c.paso.value, 5);
      expect(c.enDesempate, isTrue);
      expect(c.desempateActual!.tiebreak.id, 'tb-si-vj-1');
      expect(c.desempateActual!.ulisesLine, startsWith('Tienes dos'));
      responderPasos(c, ['bottom']);
      expect(c.esperaTrasDesempate, isTrue);
      await pumpEventQueue();
      expect(c.paso.value, 6);
      expect(c.desempateActual!.tiebreak.order, 2);
      responderPasos(c, ['top']);
      await pumpEventQueue();
      expect(c.fase.value, FaseDelTest.resultado);
      expect(api.cuerposDeEvaluacion, [
        _cuerpo(),
        _cuerpo([
          {'id': 'tb-si-vj-1', 'answer': 'bottom'},
        ]),
        _cuerpo([
          {'id': 'tb-si-vj-1', 'answer': 'bottom'},
          {'id': 'tb-si-vj-2', 'answer': 'top'},
        ]),
      ]);
    });

    test('caso 4: nunca hay dos evaluaciones en vuelo, y el paso tardío se '
        'descarta', () async {
      final primera = Completer<Map<String, dynamic>>();
      final api = ApiFalsaDelTest(evaluaciones: [primera, desempateJson()]);
      final t = prepararTest(api);
      final c = await montarControlador();
      c.empezar();
      responderPasos(c, respuestasEnOrden);
      await pumpEventQueue();
      c.atras();
      expect(c.fase.value, FaseDelTest.pregunta);
      responderPasos(c, ['un_poco']);
      await pumpEventQueue();
      expect(api.cuerposDeEvaluacion, hasLength(1));
      expect(c.fase.value, FaseDelTest.espera);
      // La primera llega con un resultado y se descarta, pero el servidor ya
      // lo guardó, así que el último resultado queda viejo.
      await t.service.loadLastResult();
      primera.complete(resultadoJson());
      await pumpEventQueue();
      expect(c.fase.value, FaseDelTest.pregunta);
      expect(c.enDesempate, isTrue);
      expect(api.cuerposDeEvaluacion, hasLength(2));
      expect(
        (api.cuerposDeEvaluacion.last['answers'] as Map)['q05'],
        'un_poco',
      );
      await t.service.loadLastResult();
      expect(api.getsDeResultado, 2);
    });

    test('caso 5: atrás desde la espera vuelve al paso que la dispara, con '
        'su respuesta', () async {
      final pendiente = Completer<Map<String, dynamic>>();
      prepararTest(ApiFalsaDelTest(evaluaciones: [pendiente]));
      final c = await montarControlador();
      c.empezar();
      responderPasos(c, respuestasEnOrden);
      c.atras();
      expect(c.fase.value, FaseDelTest.pregunta);
      expect(c.paso.value, 4);
      expect(c.respuestaActual, 'nada');
      pendiente.complete(resultadoJson());
      await pumpEventQueue();
      expect(c.fase.value, FaseDelTest.pregunta);
      expect(c.resultado.value, isNull);
    });

    test('caso 6: un reintento manda el mismo cuerpo', () async {
      final api = ApiFalsaDelTest(
        evaluaciones: [http.ClientException('sin red'), resultadoJson()],
      );
      prepararTest(api);
      final c = await montarControlador();
      c.empezar();
      responderPasos(c, respuestasEnOrden);
      await pumpEventQueue();
      expect(c.errorDeEspera.value, isNotNull);
      c.reintentarEvaluacion();
      expect(c.errorDeEspera.value, isNull);
      await pumpEventQueue();
      expect(api.cuerposDeEvaluacion[1], api.cuerposDeEvaluacion[0]);
      expect(c.fase.value, FaseDelTest.resultado);
    });

    test('caso 7: con empate, el resultado trae las dos ganadoras', () async {
      prepararTest(
        ApiFalsaDelTest(evaluaciones: [resultadoJson(empate: true)]),
      );
      final c = await montarControlador();
      c.empezar();
      responderPasos(c, respuestasEnOrden);
      await pumpEventQueue();
      expect(c.resultado.value!.tie, isTrue);
      expect(c.resultado.value!.winners.map((w) => w.key), ['si', 'vj']);
    });

    test('caso 8: seguir un test en pausa con todo respondido evalúa '
        'enseguida con la versión de su copia', () async {
      final api = ApiFalsaDelTest(
        contenido: [
          contenidoJson(),
          contenidoJson(version: '2026-09-25.5'),
        ],
        evaluaciones: [Completer<Map<String, dynamic>>(), resultadoJson()],
      );
      final t = prepararTest(api);
      final c = await montarControlador();
      c.empezar();
      responderPasos(c, respuestasEnOrden);
      c.pausar();
      Get.delete<SpecialtyTestController>();
      expect(t.service.paused!.answeredQuestions, 5);
      final otra = await montarControlador();
      otra.empezar();
      expect(otra.fase.value, FaseDelTest.espera);
      await pumpEventQueue();
      expect(api.cuerposDeEvaluacion.last['version'], kVersionDePrueba);
      expect(otra.fase.value, FaseDelTest.resultado);
    });
  });
}
```

En `test/HU36_jeff/specialty_test_errores_test.dart`, cambia este bloque, que aparece una sola vez,

```dart
  _bienvenida();
}
```

por este otro.

```dart
  _bienvenida();
  _espera();
}
```

Agrega al final de `test/HU36_jeff/specialty_test_errores_test.dart`, tras una línea en blanco, este bloque.

```dart
/// Llega hasta la espera con todas las respuestas.
Future<SpecialtyTestController> _hastaLaEspera({
  OrigenDelTest origen = OrigenDelTest.asistente,
  UiFalsa? ui,
}) async {
  final c = await montarControlador(origen: origen, ui: ui);
  c.empezar();
  responderPasos(c, respuestasEnOrden);
  await pumpEventQueue();
  return c;
}

void _espera() {
  group('UNITARIA · Errores de la espera (RF-TEST-11)', () {
    test('fila 4: sin conexión deja el aviso de la espera, las respuestas y '
        '«Pregunta anterior»', () async {
      prepararTest(
        ApiFalsaDelTest(evaluaciones: [http.ClientException('sin red')]),
      );
      final c = await _hastaLaEspera();
      expect(c.fase.value, FaseDelTest.espera);
      expect(c.errorDeEspera.value!.kind, SpecialtyTestFailureKind.offline);
      expect(
        c.textoDelErrorDeEspera,
        'No pudimos conectarnos. Revisa tu conexión e inténtalo de nuevo.',
      );
      expect(c.respuestas, respuestasCompletas());
      c.atras();
      expect(c.fase.value, FaseDelTest.pregunta);
      expect(c.errorDeEspera.value, isNull);
    });

    testWidgets('fila 4: el plazo de 20 s también', (tester) async {
      prepararTest(
        ApiFalsaDelTest(evaluaciones: [Completer<Map<String, dynamic>>()]),
      );
      final c = Get.put<SpecialtyTestController>(
        SpecialtyTestController(origen: OrigenDelTest.asistente, ui: UiFalsa()),
      );
      await tester.pump();
      c.empezar();
      responderPasos(c, respuestasEnOrden);
      await tester.pump(const Duration(seconds: 19));
      expect(c.errorDeEspera.value, isNull);
      await tester.pump(const Duration(seconds: 1));
      expect(c.errorDeEspera.value!.kind, SpecialtyTestFailureKind.offline);
    });

    test('fila 5: un 409 o un 400 de respuestas abre el diálogo y «Empezar de '
        'nuevo» pide el contenido y abre la pregunta 1', () async {
      for (final falla in [
        _api(
          409,
          'SPECIALTY_TEST_VERSION_OUTDATED',
          'El test se actualizó. Vuelve a empezarlo.',
          details: {'currentVersion': '2026-09-25.5'},
        ),
        _api(
          400,
          'SPECIALTY_TEST_INVALID_ANSWERS',
          'Las respuestas no corresponden a esta versión del test.',
        ),
      ]) {
        Get.reset();
        final api = ApiFalsaDelTest(
          contenido: [
            contenidoJson(),
            contenidoJson(version: '2026-09-25.5'),
          ],
          evaluaciones: [falla],
        );
        prepararTest(api);
        final ui = UiFalsa()..dialogo = Completer<void>();
        final c = await _hastaLaEspera(ui: ui);
        expect(ui.reinicios, [falla.message]);
        expect(c.fase.value, FaseDelTest.espera);
        ui.dialogo!.complete();
        await pumpEventQueue();
        expect(api.getsDeContenido, 2);
        expect(c.fase.value, FaseDelTest.pregunta);
        expect(c.paso.value, 0);
        expect(c.respuestas, isEmpty);
        expect(c.contenido.value!.version, '2026-09-25.5');
      }
    });

    test('fila 6: el 404 al evaluar avisa, borra las respuestas y cierra '
        'según el origen', () async {
      for (final origen in OrigenDelTest.values) {
        Get.reset();
        final t = prepararTest(
          ApiFalsaDelTest(
            evaluaciones: [
              _api(404, 'SPECIALTY_TEST_NOT_AVAILABLE', _noDisponible),
            ],
          ),
        );
        final ui = UiFalsa();
        final c = await _hastaLaEspera(origen: origen, ui: ui);
        expect(ui.avisos.single.mensaje, _noDisponible);
        expect(ui.avisos.single.tipo, TipoDeAviso.info);
        expect(ui.cierres, [
          origen == OrigenDelTest.asistente
              ? SalidaDelTest.seleccionManual
              : null,
        ]);
        expect(c.respuestas, isEmpty);
        expect(c.errorDeEspera.value, isNull);
        Get.delete<SpecialtyTestController>();
        expect(t.service.paused, isNull);
      }
    });

    test('fila 7: el desempate que no coincide se repite una vez sin '
        'desempates y sigue con lo que responda el servidor', () async {
      final api = ApiFalsaDelTest(
        evaluaciones: [
          desempateJson(),
          _api(
            400,
            'SPECIALTY_TEST_TIEBREAK_MISMATCH',
            'Los desempates enviados no son los que corresponden a estas '
                'respuestas.',
            details: {'expected': null},
          ),
          resultadoJson(),
        ],
      );
      prepararTest(api);
      final c = await _hastaLaEspera();
      responderPasos(c, ['top']);
      await pumpEventQueue();
      expect(api.cuerposDeEvaluacion, hasLength(3));
      expect(api.cuerposDeEvaluacion[1]['tiebreakAnswers'], isNotEmpty);
      expect(api.cuerposDeEvaluacion[2]['tiebreakAnswers'], isEmpty);
      expect(c.fase.value, FaseDelTest.resultado);
    });

    test('fila 7: si vuelve a fallar, queda el error de la espera', () async {
      final mismatch = _api(
        400,
        'SPECIALTY_TEST_TIEBREAK_MISMATCH',
        'Los desempates enviados no son los que corresponden a estas '
            'respuestas.',
      );
      final api = ApiFalsaDelTest(
        evaluaciones: [desempateJson(), mismatch, mismatch],
      );
      prepararTest(api);
      final c = await _hastaLaEspera();
      responderPasos(c, ['top']);
      await pumpEventQueue();
      expect(api.cuerposDeEvaluacion, hasLength(3));
      expect(
        c.errorDeEspera.value!.kind,
        SpecialtyTestFailureKind.tiebreakMismatch,
      );
      c.atras();
      expect(c.paso.value, 4);
      expect(c.desempates, isEmpty);
    });

    test('fila 8: el 429 muestra el mensaje del servidor y conserva las '
        'respuestas', () async {
      const mensaje =
          'Hiciste demasiados intentos del test. Intenta de nuevo en 12 '
          'minuto(s).';
      final api = ApiFalsaDelTest(
        evaluaciones: [
          _api(
            429,
            'RATE_LIMITED',
            mensaje,
            details: {'retryAfterMinutes': 12},
          ),
          resultadoJson(),
        ],
      );
      prepararTest(api);
      final c = await _hastaLaEspera();
      expect(c.textoDelErrorDeEspera, mensaje);
      expect(c.respuestas, respuestasCompletas());
      c.reintentarEvaluacion();
      await pumpEventQueue();
      expect(c.fase.value, FaseDelTest.resultado);
    });

    test('fila 9: un 413 o un 500 muestran el mensaje del servidor y '
        '«Reintentar»', () async {
      for (final falla in [
        _api(413, 'PAYLOAD_TOO_LARGE', 'La petición es demasiado grande.'),
        _api(500, 'INTERNAL_SERVER_ERROR', 'Error del servidor'),
      ]) {
        Get.reset();
        prepararTest(ApiFalsaDelTest(evaluaciones: [falla]));
        final c = await _hastaLaEspera();
        expect(c.textoDelErrorDeEspera, falla.message);
      }
    });

    test('fila 10: si Cohere falla, el resultado llega igual con el motivo '
        'de las plantillas', () async {
      prepararTest(ApiFalsaDelTest(evaluaciones: [resultadoJson()]));
      final c = await _hastaLaEspera();
      expect(c.fase.value, FaseDelTest.resultado);
      expect(c.resultado.value!.reasonByAi, isFalse);
    });
  });
}
```

- [ ] **Paso 2: Correr las pruebas y ver que fallan**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/HU36_jeff/specialty_test_evaluacion_test.dart \
  test/HU36_jeff/specialty_test_errores_test.dart
```

Esperado: FALLA al compilar, sin llegar a correr ningún caso. La salida trae 22 errores distintos (líneas `Error:`), y los primeros dicen esto (las rutas pueden salir absolutas).

```text
test/HU36_jeff/specialty_test_evaluacion_test.dart:67:16: Error: The getter 'resultado' isn't defined for the type 'SpecialtyTestController'.
test/HU36_jeff/specialty_test_evaluacion_test.dart:70:16: Error: The getter 'corazones' isn't defined for the type 'SpecialtyTestController'.
```

- [ ] **Paso 3: Reemplazar el bloque de la evaluación**

La evaluación en vuelo nunca se cancela. Un atrás desde la espera sube `_evaluacionVigente`, así que su paso se descarta al llegar, y una respuesta nueva mientras tanto espera a que termine la anterior. Un `400 SPECIALTY_TEST_TIEBREAK_MISMATCH` se repite una sola vez sin desempates y deja el paso en la última pregunta, para que el atrás no apunte a un desempate que ya no existe.

En `lib/pages/specialty_test/specialty_test_controller.dart`, cambia este bloque, que aparece una sola vez,

```dart
  // ── Evaluación, espera y desempates (RF-TEST-7 y RF-TEST-11) ───────────────

  /// La espera tras el último paso. Esta versión todavía no llama al
  /// servidor.
  void _evaluar() => fase.value = FaseDelTest.espera;

  /// Sin una evaluación en vuelo, no hay nada que descartar.
  void _descartarEvaluacion() {}
}
```

por este otro.

```dart
  // ── Evaluación, espera y desempates (RF-TEST-7 y RF-TEST-11) ───────────────

  /// El error de la espera, o null mientras se espera.
  final errorDeEspera = Rxn<SpecialtyTestFailure>();
  final resultado = Rxn<SpecialtyTestResult>();

  /// Sube con cada evaluación pedida y con cada atrás desde la espera. Una
  /// respuesta que vuelve con otro número se descarta.
  int _evaluacionVigente = 0;
  bool _evaluando = false;
  bool _otraPendiente = false;

  /// La espera sigue a un desempate y no a la última pregunta.
  bool get esperaTrasDesempate => paso.value >= totalPreguntas;

  void _evaluar() {
    fase.value = FaseDelTest.espera;
    errorDeEspera.value = null;
    final id = ++_evaluacionVigente;
    // Nunca dos en vuelo. La nueva sale cuando termina o vence la anterior.
    if (_evaluando) {
      _otraPendiente = true;
      return;
    }
    unawaited(_lanzarEvaluacion(id));
  }

  void _descartarEvaluacion() {
    _evaluacionVigente++;
    errorDeEspera.value = null;
  }

  bool _sigueVigente(int id) =>
      !_cerrado && id == _evaluacionVigente && fase.value == FaseDelTest.espera;

  Future<void> _lanzarEvaluacion(int id) async {
    _evaluando = true;
    try {
      var reintentado = false;
      while (true) {
        final c = contenido.value!;
        final cuerpo = cuerpoDeEvaluacion(
          version: c.version,
          respuestas: respuestas,
          desempates: desempates,
        );
        try {
          final pasoNuevo = await _service.evaluate(cuerpo);
          if (_sigueVigente(id)) _aplicarPaso(pasoNuevo);
          return;
        } on SpecialtyTestFailure catch (f) {
          if (!_sigueVigente(id)) return;
          if (f.kind == SpecialtyTestFailureKind.tiebreakMismatch &&
              !reintentado) {
            // Una sola vez y sin desempates, porque el servidor decide
            // cuáles tocan (decisión abierta 19).
            reintentado = true;
            desempates.clear();
            if (paso.value >= c.totalQuestions) {
              paso.value = c.totalQuestions - 1;
            }
            continue;
          }
          await _fallaDeEvaluacion(f);
          return;
        }
      }
    } finally {
      _evaluando = false;
      if (_otraPendiente && !_cerrado) {
        _otraPendiente = false;
        if (fase.value == FaseDelTest.espera) {
          unawaited(_lanzarEvaluacion(_evaluacionVigente));
        }
      }
    }
  }

  void _aplicarPaso(EvaluationStep pasoNuevo) {
    switch (pasoNuevo) {
      case TiebreakStep(:final tiebreak, :final ulisesLine):
        final antes = (tiebreak.order - 1).clamp(0, desempates.length);
        desempates.assignAll([
          ...desempates.take(antes),
          TiebreakRecord(tiebreak: tiebreak, ulisesLine: ulisesLine),
        ]);
        paso.value = totalPreguntas + desempates.length - 1;
        fase.value = FaseDelTest.pregunta;
      case ResultStep(:final result):
        _mostrarResultado(result);
    }
  }

  Future<void> _fallaDeEvaluacion(SpecialtyTestFailure f) async {
    switch (f.kind) {
      case SpecialtyTestFailureKind.versionOutdated:
      case SpecialtyTestFailureKind.invalidAnswers:
        await _ui.pedirReinicio(f.message ?? '');
        if (_cerrado) return;
        await _empezarConContenidoNuevo();
      case SpecialtyTestFailureKind.notAvailable:
        _noDisponible(f.message, avisarSiempre: true);
      case SpecialtyTestFailureKind.offline:
      case SpecialtyTestFailureKind.rateLimited:
      case SpecialtyTestFailureKind.tiebreakMismatch:
      case SpecialtyTestFailureKind.server:
        errorDeEspera.value = f;
    }
  }

  /// El texto del error de la espera, que es el mensaje del servidor o, sin
  /// él, el de sin conexión.
  String get textoDelErrorDeEspera =>
      errorDeEspera.value?.message ?? TextosDelTest.sinConexion;

  void reintentarEvaluacion() {
    if (fase.value != FaseDelTest.espera || errorDeEspera.value == null) {
      return;
    }
    _evaluar();
  }

  /// «Empezar de nuevo» del diálogo de la espera. Pide el contenido otra vez
  /// y abre la pregunta 1.
  Future<void> _empezarConContenidoNuevo() async {
    _borrarRespuestas();
    contenido.value = null;
    _vigente = null;
    fase.value = FaseDelTest.bienvenida;
    await _cargarContenido();
    if (_cerrado || carga.value != EstadoDeCarga.lista) return;
    _abrirPreguntaUno(_vigente!);
  }

  // ── Resultado (RF-TEST-8) ──────────────────────────────────────────────────

  /// Los corazones que se ven marcados.
  final corazones = <int>{}.obs;

  void _mostrarResultado(SpecialtyTestResult r) {
    _avance?.cancel();
    resultado.value = r;
    _borrarRespuestas();
    corazones.assignAll(
      corazonesIniciales(
        intereses: _auth.currentUser?.especialidadesInteres ?? const <int>[],
        idsDelRanking: _idsDe(r),
      ),
    );
    fase.value = FaseDelTest.resultado;
  }

  List<int> _idsDe(SpecialtyTestResult r) =>
      r.ranking.map((e) => e.specialtyId).toList(growable: false);
}
```

- [ ] **Paso 4: Correr las pruebas y ver que pasan**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/HU36_jeff/specialty_test_evaluacion_test.dart \
  test/HU36_jeff/specialty_test_errores_test.dart \
  test/HU36_jeff/specialty_test_bienvenida_test.dart \
  test/HU36_jeff/specialty_test_conversacion_test.dart
```

Esperado: PASS, `+42: All tests passed!`.

- [ ] **Paso 5: Dar formato y analizar**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/pages/specialty_test/specialty_test_controller.dart \
  test/HU36_jeff/specialty_test_evaluacion_test.dart \
  test/HU36_jeff/specialty_test_errores_test.dart
```

Esperado: `Formatted 3 files (0 changed)`.

```bash
cd "${REPO:?}"
"${FLUTTER:?}" analyze --no-pub
```

Esperado: `6 issues found.`, los 6 de la línea base y ninguno en un archivo de esta tarea.

- [ ] **Paso 6: Commit**

```bash
cd "${REPO:?}"
test "$(git branch --show-current)" = feat/test-especialidad-fe || echo 'PARAR: rama equivocada'
git status --short
git add lib/pages/specialty_test/specialty_test_controller.dart \
  test/HU36_jeff/specialty_test_evaluacion_test.dart \
  test/HU36_jeff/specialty_test_errores_test.dart
git commit -m 'feat(specialty-test): el controlador evalúa una vez a la vez, muestra los desempates y traduce cada error de la espera (RF-TEST-7 y RF-TEST-11)'
git log -1 --format='%an <%ae>'
git log -1 --format=%B | grep -qi '^co-authored-by:' && echo 'PARAR: el commit trae trailer'
```

Esperado: ningún `PARAR`. Antes del `git add`, `git status --short` lista solo los archivos de la tarea, y el autor es `Jeffangeloss <178797184+jeffangeloss@users.noreply.github.com>`.

---

### Tarea 10: Controlador, elegir, corazones, Decidir después y Rehacer

**Requisitos:** RF-TEST-9 entero y las filas de los guardados de RF-TEST-11.

**Archivos:**
- Modificar `lib/pages/specialty_test/specialty_test_controller.dart` (imports y bloque de la elección al final)
- Crear `test/HU36_jeff/specialty_test_eleccion_test.dart`
- Modificar `test/HU36_jeff/specialty_test_errores_test.dart` (imports, grupo `_guardados`)

**Interfaces:**

- Consume `AuthService.completeSetup(..., timeout:)` (Tarea 7),
  `SpecialtyTestService.saveTimeout` y `seleccionAlElegir` y
  `seleccionConCorazones` (Tarea 5).
- Produce lo que sigue, que usa la pantalla del resultado (Tarea 14).

```dart
final RxBool guardando, guardandoCorazones;
bool get botonesActivos;     // ningún guardado en vuelo
bool get yaEsPrincipal;      // «Ya es tu principal»
Future<void> elegirPrincipal(int elegida);
void alternarCorazon(int specialtyId);
Future<void> decidirDespues();
void rehacer();
void atrasEnResultado();     // nada en el asistente, «Decidir después» en el Perfil
```

- [ ] **Paso 1: Escribir las pruebas que fallan**

Crea `test/HU36_jeff/specialty_test_eleccion_test.dart` con este contenido.

```dart
// test/HU36_jeff/specialty_test_eleccion_test.dart
//
// Pruebas de HU36, el test de especialidad, sobre «Elegir como principal»,
// los corazones, «Decidir después» y «Rehacer el test» (RF-TEST-9).
// Controlador: lib/pages/specialty_test/specialty_test_controller.dart
//
// Datos inventados (datos_de_prueba.dart). El alumno de prueba es 20230001.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_logic.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';

/// Llega al resultado con [usuario] y el resultado de [evaluacion].
Future<({SpecialtyTestController c, AuthDelControlador auth, UiFalsa ui})>
_alResultado({
  OrigenDelTest origen = OrigenDelTest.asistente,
  UserModel? usuario,
  Map<String, dynamic>? evaluacion,
}) async {
  final t = prepararTest(
    ApiFalsaDelTest(evaluaciones: [evaluacion ?? resultadoJson()]),
    usuario: usuario,
  );
  final ui = UiFalsa();
  final c = await montarControlador(origen: origen, ui: ui);
  c.empezar();
  responderPasos(c, respuestasEnOrden);
  await pumpEventQueue();
  expect(c.fase.value, FaseDelTest.resultado);
  return (c: c, auth: t.auth, ui: ui);
}

void main() {
  // Get.put de un GetxService agenda onReady con
  // Get.engine.addPostFrameCallback, que necesita el binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(Get.reset);
  tearDown(Get.reset);

  _controlador();
}

void _controlador() {
  group('UNITARIA · Elegir como principal (RF-TEST-9)', () {
    test('caso 1: en el asistente manda la ganadora y los corazones y va al '
        'home', () async {
      final r = await _alResultado(usuario: alumno(intereses: [kIdTi]));
      expect(r.c.corazones, {kIdTi});
      await r.c.elegirPrincipal(kIdVj);
      expect(
        r.auth.guardados.single,
        const SeleccionDeEspecialidades(principal: kIdVj, intereses: [kIdTi]),
      );
      expect(r.auth.plazos.single, SpecialtyTestService.saveTimeout);
      expect(r.ui.alHome, 1);
      expect(r.ui.cierres, isEmpty);
    });

    test('caso 2: en el Perfil cierra la ruta y avisa como siempre', () async {
      final r = await _alResultado(origen: OrigenDelTest.perfil);
      await r.c.elegirPrincipal(kIdVj);
      expect(r.ui.cierres, [SalidaDelTest.terminado]);
      expect(r.ui.alHome, 0);
      expect(r.ui.avisos.single.tipo, TipoDeAviso.exito);
      expect(r.ui.avisos.single.titulo, 'Especialidades actualizadas');
      expect(
        r.ui.avisos.single.mensaje,
        'Tu selección se guardó correctamente.',
      );
    });

    test('caso 3: una principal anterior del ranking pasa a interés', () async {
      final r = await _alResultado(usuario: alumno(principal: kIdSw));
      await r.c.elegirPrincipal(kIdVj);
      expect(
        r.auth.guardados.single,
        const SeleccionDeEspecialidades(principal: kIdVj, intereses: [kIdSw]),
      );
    });

    test(
      'caso 4: con empate, la ganadora que no se elige pasa a interés',
      () async {
        final r = await _alResultado(evaluacion: resultadoJson(empate: true));
        await r.c.elegirPrincipal(kIdVj);
        expect(
          r.auth.guardados.single,
          const SeleccionDeEspecialidades(principal: kIdVj, intereses: [kIdSi]),
        );
      },
    );

    test(
      'caso 5: si la ganadora ya es la principal, el botón lo dice',
      () async {
        final r = await _alResultado(usuario: alumno(principal: kIdVj));
        expect(r.c.yaEsPrincipal, isTrue);
        Get.reset();
        final otra = await _alResultado(usuario: alumno(principal: kIdSw));
        expect(otra.c.yaEsPrincipal, isFalse);
      },
    );
  });

  group('UNITARIA · Corazones (RF-TEST-9)', () {
    test(
      'caso 6: un corazón guarda enseguida con la principal sin cambios',
      () async {
        final r = await _alResultado(usuario: alumno(principal: kIdSw));
        r.c.alternarCorazon(kIdSi);
        expect(r.c.corazones, {kIdSi});
        await pumpEventQueue();
        expect(
          r.auth.guardados.single,
          const SeleccionDeEspecialidades(principal: kIdSw, intereses: [kIdSi]),
        );
        r.c.alternarCorazon(kIdSi);
        await pumpEventQueue();
        expect(
          r.auth.guardados.last,
          const SeleccionDeEspecialidades(principal: kIdSw),
        );
      },
    );

    test(
      'caso 7: los toques seguidos se juntan y se manda el último estado',
      () async {
        final r = await _alResultado();
        final primero = Completer<void>();
        r.auth.respuestasDeGuardado.add(primero);
        r.c.alternarCorazon(kIdSi);
        r.c.alternarCorazon(kIdTi);
        r.c.alternarCorazon(kIdSw);
        r.c.alternarCorazon(kIdSw);
        expect(r.auth.guardados, hasLength(1));
        primero.complete();
        await pumpEventQueue();
        expect(r.auth.guardados, hasLength(2));
        expect(
          r.auth.guardados.last,
          const SeleccionDeEspecialidades(intereses: [kIdSi, kIdTi]),
        );
        expect(r.c.guardandoCorazones.value, isFalse);
      },
    );

    test('caso 8: si el guardado de los toques juntados falla, se descartan '
        'con él', () async {
      final r = await _alResultado();
      final primero = Completer<void>();
      r.auth.respuestasDeGuardado
        ..add(primero)
        ..add(TimeoutException('plazo'));
      r.c.alternarCorazon(kIdSi);
      r.c.alternarCorazon(kIdTi);
      primero.complete();
      await pumpEventQueue();
      expect(r.c.corazones, {kIdSi});
      expect(r.ui.avisos.single.tipo, TipoDeAviso.error);
    });

    test('caso 9: en el asistente, el primer corazón completa la '
        'configuración', () async {
      final r = await _alResultado(usuario: alumno(setupComplete: false));
      r.c.alternarCorazon(kIdTi);
      await pumpEventQueue();
      expect(r.auth.currentUser!.setupComplete, isTrue);
    });

    test('caso 10: nunca hay dos guardados en vuelo entre corazones y '
        'botones', () async {
      final r = await _alResultado();
      final corazon = Completer<void>();
      r.auth.respuestasDeGuardado.add(corazon);
      r.c.alternarCorazon(kIdSi);
      expect(r.c.botonesActivos, isFalse);
      await r.c.elegirPrincipal(kIdVj);
      await r.c.decidirDespues();
      r.c.rehacer();
      expect(r.auth.guardados, hasLength(1));
      expect(r.c.fase.value, FaseDelTest.resultado);
      corazon.complete();
      await pumpEventQueue();
      final boton = Completer<void>();
      r.auth.respuestasDeGuardado.add(boton);
      unawaited(r.c.elegirPrincipal(kIdVj));
      r.c.alternarCorazon(kIdTi);
      expect(r.c.corazones, {kIdSi});
      expect(r.auth.guardados, hasLength(2));
      boton.complete();
      await pumpEventQueue();
    });
  });

  group('UNITARIA · Decidir después, Rehacer y atrás (RF-TEST-9)', () {
    test('caso 11: «Decidir después» en el asistente guarda la selección y va '
        'al home', () async {
      final r = await _alResultado(
        usuario: alumno(principal: kIdSw, intereses: [kIdTi]),
      );
      await r.c.decidirDespues();
      expect(
        r.auth.guardados.single,
        const SeleccionDeEspecialidades(principal: kIdSw, intereses: [kIdTi]),
      );
      expect(r.ui.alHome, 1);
    });

    test(
      'caso 12: «Decidir después» en el Perfil cierra sin guardar',
      () async {
        final r = await _alResultado(origen: OrigenDelTest.perfil);
        await r.c.decidirDespues();
        expect(r.auth.guardados, isEmpty);
        expect(r.ui.cierres, [SalidaDelTest.terminado]);
      },
    );

    test('caso 13: «Rehacer el test» vuelve a la pregunta 1 con la misma '
        'copia y sin respuestas', () async {
      final r = await _alResultado();
      final copia = r.c.contenido.value;
      r.c.rehacer();
      expect(r.c.fase.value, FaseDelTest.pregunta);
      expect(r.c.paso.value, 0);
      expect(r.c.respuestas, isEmpty);
      expect(r.c.resultado.value, isNull);
      expect(r.c.contenido.value, same(copia));
    });

    test('caso 14: el atrás del sistema no hace nada en el asistente y es '
        '«Decidir después» en el Perfil', () async {
      final asistente = await _alResultado();
      asistente.c.atrasEnResultado();
      await pumpEventQueue();
      expect(asistente.ui.cierres, isEmpty);
      expect(asistente.ui.alHome, 0);
      expect(asistente.auth.guardados, isEmpty);
      Get.reset();
      final perfil = await _alResultado(origen: OrigenDelTest.perfil);
      perfil.c.atrasEnResultado();
      await pumpEventQueue();
      expect(perfil.ui.cierres, [SalidaDelTest.terminado]);
    });
  });
}
```

En `test/HU36_jeff/specialty_test_errores_test.dart`, cambia este bloque, que aparece una sola vez,

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:ulima_plus/models/specialty_test_models.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';
```

por este otro.

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:ulima_plus/models/specialty_test_models.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_logic.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';
```

En `test/HU36_jeff/specialty_test_errores_test.dart`, cambia este bloque, que aparece una sola vez,

```dart
  _espera();
}
```

por este otro.

```dart
  _espera();
  _guardados();
}
```

Agrega al final de `test/HU36_jeff/specialty_test_errores_test.dart`, tras una línea en blanco, este bloque.

```dart
void _guardados() {
  group('UNITARIA · Errores de los guardados del resultado (RF-TEST-11)', () {
    Future<({SpecialtyTestController c, AuthDelControlador auth, UiFalsa ui})>
    alResultado() async {
      final t = prepararTest(ApiFalsaDelTest());
      final ui = UiFalsa();
      final c = await _hastaLaEspera(ui: ui);
      expect(c.fase.value, FaseDelTest.resultado);
      return (c: c, auth: t.auth, ui: ui);
    }

    test('fila 11: un PUT que falla avisa con el mensaje del servidor o el '
        'propio, y el corazón vuelve', () async {
      final r = await alResultado();
      r.auth.respuestasDeGuardado
        ..add(_api(404, 'SPECIALTY_NOT_FOUND', 'Mensaje de prueba del 404.'))
        ..add(Exception('sin red'));
      r.c.alternarCorazon(kIdSi);
      await pumpEventQueue();
      expect(r.c.corazones, isEmpty);
      expect(r.ui.avisos.last.mensaje, 'Mensaje de prueba del 404.');
      expect(r.ui.avisos.last.tipo, TipoDeAviso.error);
      r.c.alternarCorazon(kIdTi);
      await pumpEventQueue();
      expect(r.c.corazones, isEmpty);
      expect(
        r.ui.avisos.last.mensaje,
        'No se pudo guardar. Revisa tu conexión e inténtalo de nuevo.',
      );
      expect(r.c.fase.value, FaseDelTest.resultado);
    });

    test('fila 12: un PUT sin respuesta en 15 s avisa que no se confirmó, y '
        'el asistente no termina', () async {
      final r = await alResultado();
      r.c.alternarCorazon(kIdSi);
      await pumpEventQueue();
      r.auth.respuestasDeGuardado
        ..add(TimeoutException('plazo'))
        ..add(TimeoutException('plazo'));
      r.c.alternarCorazon(kIdTi);
      await pumpEventQueue();
      expect(r.c.corazones, {kIdSi});
      await r.c.elegirPrincipal(kIdVj);
      expect(r.ui.alHome, 0);
      expect(r.c.botonesActivos, isTrue);
      expect(r.ui.avisos.map((a) => a.mensaje), [
        'No se pudo confirmar el guardado. Revisa tu conexión e inténtalo de '
            'nuevo.',
        'No se pudo confirmar el guardado. Revisa tu conexión e inténtalo de '
            'nuevo.',
      ]);
      // Repetir es seguro, porque cada PUT manda la selección entera.
      await r.c.elegirPrincipal(kIdVj);
      expect(r.ui.alHome, 1);
      expect(
        r.auth.guardados.last,
        const SeleccionDeEspecialidades(principal: kIdVj, intereses: [kIdSi]),
      );
    });
  });
}
```

- [ ] **Paso 2: Correr las pruebas y ver que fallan**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/HU36_jeff/specialty_test_eleccion_test.dart \
  test/HU36_jeff/specialty_test_errores_test.dart
```

Esperado: FALLA al compilar, sin llegar a correr ningún caso. La salida trae 36 errores distintos (líneas `Error:`), y los primeros dicen esto (las rutas pueden salir absolutas).

```text
test/HU36_jeff/specialty_test_eleccion_test.dart:71:17: Error: The method 'elegirPrincipal' isn't defined for the type 'SpecialtyTestController'.
test/HU36_jeff/specialty_test_eleccion_test.dart:84:17: Error: The method 'elegirPrincipal' isn't defined for the type 'SpecialtyTestController'.
```

- [ ] **Paso 3: Agregar la elección y los guardados**

Un `PUT` sin respuesta en 15 s llega como `TimeoutException` desde `completeSetup` y da «No se pudo confirmar el guardado…», porque puede estar hecho en el servidor. Los toques seguidos de los corazones se juntan y, si ese guardado falla, se descartan con él.

En `lib/pages/specialty_test/specialty_test_controller.dart`, cambia este bloque, que aparece una sola vez,

```dart
import 'dart:async';

import 'package:get/get.dart';

import '../../models/specialty_test_models.dart';
import '../../services/auth_service.dart';
import '../../services/specialty_test_service.dart';
import 'specialty_test_logic.dart';
```

por este otro.

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../models/specialty_test_models.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/specialty_test_service.dart';
import 'specialty_test_logic.dart';
```

En `lib/pages/specialty_test/specialty_test_controller.dart`, cambia este bloque, que aparece una sola vez,

```dart
        idsDelRanking: _idsDe(r),
      ),
    );
    fase.value = FaseDelTest.resultado;
```

por este otro.

```dart
        idsDelRanking: _idsDe(r),
      ),
    );
    _corazonesConfirmados = Set<int>.of(corazones);
    fase.value = FaseDelTest.resultado;
```

En `lib/pages/specialty_test/specialty_test_controller.dart`, cambia este bloque, que aparece una sola vez,

```dart
  List<int> _idsDe(SpecialtyTestResult r) =>
      r.ranking.map((e) => e.specialtyId).toList(growable: false);
}
```

por este otro.

```dart
  List<int> _idsDe(SpecialtyTestResult r) =>
      r.ranking.map((e) => e.specialtyId).toList(growable: false);

  // ── Elegir, corazones y Decidir después (RF-TEST-9) ─────────────────────────

  /// Un guardado de los botones en vuelo.
  final guardando = false.obs;

  /// Un guardado de los corazones en vuelo.
  final guardandoCorazones = false.obs;
  bool _corazonesPendientes = false;

  /// Los últimos corazones que confirmó el servidor.
  Set<int> _corazonesConfirmados = <int>{};

  /// Los botones responden cuando no hay ningún guardado en vuelo.
  bool get botonesActivos => !guardando.value && !guardandoCorazones.value;

  /// La ganadora ya es la principal, y el botón dice «Ya es tu principal».
  bool get yaEsPrincipal {
    final r = resultado.value;
    if (r == null || r.tie) return false;
    return r.ranking.first.specialtyId == principalActual;
  }

  /// «Elegir como principal». Con empate, la pantalla pregunta cuál y pasa
  /// aquí su `specialtyId`.
  Future<void> elegirPrincipal(int elegida) async {
    final r = resultado.value;
    if (r == null || !botonesActivos) return;
    int? otra;
    if (r.tie) {
      for (final w in r.winners) {
        if (w.specialtyId != elegida) otra = w.specialtyId;
      }
    }
    final seleccion = seleccionAlElegir(
      elegida: elegida,
      principalActual: principalActual,
      corazones: corazones,
      idsDelRanking: _idsDe(r),
      otraGanadora: otra,
    );
    if (!await _guardarBotones(seleccion)) return;
    if (enAsistente) {
      _ui.irAlHome();
      return;
    }
    _ui.cerrar(SalidaDelTest.terminado);
    _ui.avisar(
      const AvisoDelTest(
        TipoDeAviso.exito,
        TextosDelTest.guardadoMensaje,
        titulo: TextosDelTest.guardadoTitulo,
      ),
    );
  }

  /// El corazón de una fila. Cambia al tocarlo y guarda enseguida. Los
  /// toques seguidos se juntan y se manda el último estado.
  void alternarCorazon(int specialtyId) {
    if (resultado.value == null || guardando.value) return;
    if (corazones.contains(specialtyId)) {
      corazones.remove(specialtyId);
    } else {
      corazones.add(specialtyId);
    }
    if (guardandoCorazones.value) {
      _corazonesPendientes = true;
      return;
    }
    unawaited(_guardarCorazones());
  }

  Future<void> _guardarCorazones() async {
    final r = resultado.value!;
    guardandoCorazones.value = true;
    try {
      while (true) {
        final enviados = Set<int>.of(corazones);
        final seleccion = seleccionConCorazones(
          principalActual: principalActual,
          corazones: enviados,
          idsDelRanking: _idsDe(r),
        );
        final error = await _guardar(seleccion);
        if (_cerrado) return;
        if (error != null) {
          // Vuelven al último estado confirmado, y los toques juntados se
          // descartan con el guardado que falló.
          corazones.assignAll(_corazonesConfirmados);
          _corazonesPendientes = false;
          _ui.avisar(error);
          return;
        }
        _corazonesConfirmados = enviados;
        if (!_corazonesPendientes) return;
        _corazonesPendientes = false;
        if (setEquals(corazones.toSet(), _corazonesConfirmados)) return;
      }
    } finally {
      if (!_cerrado) guardandoCorazones.value = false;
    }
  }

  /// «Decidir después». En el asistente manda la selección actual para
  /// marcar la configuración como completa; en el Perfil cierra sin guardar,
  /// porque los corazones ya están guardados.
  Future<void> decidirDespues() async {
    final r = resultado.value;
    if (r == null || !botonesActivos) return;
    if (!enAsistente) {
      _ui.cerrar(SalidaDelTest.terminado);
      return;
    }
    final seleccion = seleccionConCorazones(
      principalActual: principalActual,
      corazones: corazones,
      idsDelRanking: _idsDe(r),
    );
    if (await _guardarBotones(seleccion)) _ui.irAlHome();
  }

  /// «Rehacer el test» vuelve a la pregunta 1 con la misma copia y sin
  /// respuestas, sin pasar por la bienvenida.
  void rehacer() {
    if (resultado.value == null || !botonesActivos) return;
    final c = contenido.value!;
    resultado.value = null;
    _abrirPreguntaUno(c);
  }

  /// El atrás del sistema en el resultado. En el asistente no hace nada; en
  /// el Perfil es «Decidir después» (decisión abierta 12).
  void atrasEnResultado() {
    if (enAsistente) return;
    unawaited(decidirDespues());
  }

  Future<bool> _guardarBotones(SeleccionDeEspecialidades seleccion) async {
    guardando.value = true;
    final error = await _guardar(seleccion);
    if (_cerrado) return false;
    guardando.value = false;
    if (error != null) {
      _ui.avisar(error);
      return false;
    }
    return true;
  }

  /// Un `PUT` con plazo de 15 s. Devuelve null si guardó, o el aviso que
  /// explica el fallo.
  Future<AvisoDelTest?> _guardar(SeleccionDeEspecialidades seleccion) async {
    final careerId = _auth.currentUser?.careerId;
    if (careerId == null) {
      return const AvisoDelTest(TipoDeAviso.error, TextosDelTest.noSeGuardo);
    }
    try {
      await _auth.completeSetup(
        careerId: careerId,
        especialidadPrincipal: seleccion.principal,
        especialidadesInteres: seleccion.intereses,
        timeout: SpecialtyTestService.saveTimeout,
      );
      return null;
    } on TimeoutException {
      // El guardado puede estar hecho en el servidor.
      return const AvisoDelTest(TipoDeAviso.error, TextosDelTest.noSeConfirmo);
    } on ApiException catch (e) {
      return AvisoDelTest(TipoDeAviso.error, e.message);
    } catch (_) {
      return const AvisoDelTest(TipoDeAviso.error, TextosDelTest.noSeGuardo);
    }
  }
}
```

- [ ] **Paso 4: Correr las pruebas y ver que pasan**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/HU36_jeff/specialty_test_eleccion_test.dart \
  test/HU36_jeff/specialty_test_errores_test.dart \
  test/HU36_jeff/specialty_test_evaluacion_test.dart \
  test/HU36_jeff/specialty_test_bienvenida_test.dart \
  test/HU36_jeff/specialty_test_conversacion_test.dart
```

Esperado: PASS, `+58: All tests passed!`.

- [ ] **Paso 5: Dar formato y analizar**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/pages/specialty_test/specialty_test_controller.dart \
  test/HU36_jeff/specialty_test_eleccion_test.dart \
  test/HU36_jeff/specialty_test_errores_test.dart
```

Esperado: `Formatted 3 files (0 changed)`.

```bash
cd "${REPO:?}"
"${FLUTTER:?}" analyze --no-pub
```

Esperado: `6 issues found.`, los 6 de la línea base y ninguno en un archivo de esta tarea.

- [ ] **Paso 6: Commit**

```bash
cd "${REPO:?}"
test "$(git branch --show-current)" = feat/test-especialidad-fe || echo 'PARAR: rama equivocada'
git status --short
git add lib/pages/specialty_test/specialty_test_controller.dart \
  test/HU36_jeff/specialty_test_eleccion_test.dart \
  test/HU36_jeff/specialty_test_errores_test.dart
git commit -m 'feat(specialty-test): el resultado elige la principal, guarda los corazones con plazo y deja decidir después (RF-TEST-9)'
git log -1 --format='%an <%ae>'
git log -1 --format=%B | grep -qi '^co-authored-by:' && echo 'PARAR: el commit trae trailer'
```

Esperado: ningún `PARAR`. Antes del `git add`, `git status --short` lista solo los archivos de la tarea, y el autor es `Jeffangeloss <178797184+jeffangeloss@users.noreply.github.com>`.

---

### Tarea 11: La bienvenida en pantalla

**Requisitos:** RF-TEST-3 (héroe, líneas, pastillas, botones según el origen, cargando, error, espacio a 375 × 667) y su parte de RF-TEST-13.

**Archivos:**
- Crear `lib/pages/specialty_test/widgets/test_buttons.dart` (botón principal, secundario y mensaje de error, que comparten las pantallas y el asistente)
- Crear `lib/pages/specialty_test/widgets/ulises_bubble.dart` y `lib/pages/specialty_test/widgets/welcome_view.dart`
- Crear `test/HU36_jeff/montaje_de_pantallas.dart` (montaje de pantallas y Roboto para medir)
- Modificar `test/HU36_jeff/specialty_test_bienvenida_test.dart` (grupo `_pantalla`)
- Crear `test/HU36_jeff/specialty_test_accesibilidad_test.dart` (grupo `_bienvenida`)

**Interfaces:**

- Consume el controlador de la Tarea 8 (`contenido`, `carga`,
  `hayAvance`, `enAsistente`, `empezar`, `empezarDeNuevo`, `saltar`,
  `ahoraNo`, `reintentarCarga`), `iconoDelTest` y `colorDeHex`, y
  `SkeletonPulse` y `SkeletonBox` de `lib/components/skeleton.dart`.
- Produce lo que sigue, que usan las Tareas 12 a 18.

```dart
// widgets/test_buttons.dart
class TestPrimaryButton { const TestPrimaryButton({required String label,
  required VoidCallback? onPressed, IconData? icon, bool loading = false,
  double height = 52}); }
class TestSecondaryButton { const TestSecondaryButton({required String label,
  required VoidCallback? onPressed, IconData? icon}); }  // 48 px como mínimo
class TestErrorMessage { const TestErrorMessage({required String text,
  required VoidCallback onRetry}); }
// widgets/ulises_bubble.dart
class UlisesAvatar { const UlisesAvatar({required double size}); }
class UlisesBubble { const UlisesBubble({required String text,
  bool showAvatar = true, double avatarSize = 28, double fontSize = 13.5}); }
class SelloDeBloqueView { const SelloDeBloqueView({required SelloDeBloque sello}); }
class UlisesTurnView { const UlisesTurnView({required TurnoDeUlises turno,
  FocusNode? focusNode}); }   // región viva
// widgets/welcome_view.dart
class WelcomeView extends GetView<SpecialtyTestController> {
  static const Key skeletonKey, heroKey; }
```

```dart
// test/HU36_jeff/montaje_de_pantallas.dart
const Size kIphoneSE = Size(375, 667);
Future<void> montarPantalla(WidgetTester tester, Widget pantalla,
  {Brightness brillo, double escala, bool lector, bool sinMovimiento,
  Size tamano});
SpecialtyTestController ponerControlador({OrigenDelTest origen, UiFalsa? ui});
Color? colorDeTexto(WidgetTester tester, String texto);
bool dentroDeLaPantalla(WidgetTester tester, Finder finder, {Size tamano});
Future<void> cargarRoboto();
```

- [ ] **Paso 1: Escribir las pruebas que fallan**

Las medidas de espacio cargan Roboto del SDK de Flutter, como `test/HU23_jeff/chats_pestana_test.dart`. Sin ella, la fuente de pruebas dibuja cada letra como un cuadrado del ancho de su tamaño, casi el doble de ancha que la del teléfono, y ningún «cabe» se parece al real.

Crea `test/HU36_jeff/montaje_de_pantallas.dart` con este contenido.

```dart
// test/HU36_jeff/montaje_de_pantallas.dart
//
// Montaje de las pantallas del test de especialidad (HU36) en las pruebas
// de widget. No es un archivo de pruebas.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';

import 'dobles_del_controlador.dart';

/// El iPhone SE de RF-TEST-3 y RF-TEST-8.
const Size kIphoneSE = Size(375, 667);

/// Monta [pantalla] con el tema de la app, en el tamaño [tamano] y con la
/// escala de texto, el lector de pantalla y el movimiento que se pidan.
Future<void> montarPantalla(
  WidgetTester tester,
  Widget pantalla, {
  Brightness brillo = Brightness.light,
  double escala = 1.0,
  bool lector = false,
  bool sinMovimiento = false,
  Size tamano = kIphoneSE,
}) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final tema = MaterialTheme(ThemeData().textTheme);
  await tester.pumpWidget(
    GetMaterialApp(
      theme: tema.light(),
      darkTheme: tema.dark(),
      themeMode: brillo == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(escala),
          disableAnimations: sinMovimiento,
          accessibleNavigation: lector,
        ),
        child: child!,
      ),
      home: Scaffold(body: pantalla),
    ),
  );
  await tester.pump();
}

/// Registra el controlador con una pantalla falsa. Dentro de testWidgets la
/// carga corre con `tester.pump()`, no con `pumpEventQueue`.
SpecialtyTestController ponerControlador({
  OrigenDelTest origen = OrigenDelTest.asistente,
  UiFalsa? ui,
}) => Get.put<SpecialtyTestController>(
  SpecialtyTestController(origen: origen, ui: ui ?? UiFalsa()),
);

/// El color del primer `Text` con [texto].
Color? colorDeTexto(WidgetTester tester, String texto) =>
    tester.widget<Text>(find.text(texto).first).style?.color;

/// Si [finder] cae entero dentro de la pantalla de [tamano].
bool dentroDeLaPantalla(
  WidgetTester tester,
  Finder finder, {
  Size tamano = kIphoneSE,
}) {
  final r = tester.getRect(finder);
  return r.top >= 0 &&
      r.bottom <= tamano.height &&
      r.left >= 0 &&
      r.right <= tamano.width;
}

/// Carga Roboto del SDK de Flutter con el nombre de familia del tema, como
/// `test/HU23_jeff/chats_pestana_test.dart`. Sin esto, la fuente de pruebas
/// dibuja cada letra como un cuadrado del ancho de su tamaño y ninguna
/// medida de «cabe sin desplazar» se parece a la del teléfono.
Future<void> cargarRoboto() async {
  final raiz = Platform.environment['FLUTTER_ROOT'];
  expect(
    raiz,
    isNotNull,
    reason: 'flutter test fija FLUTTER_ROOT; sin él no hay Roboto que medir',
  );
  final cargador = FontLoader('Roboto');
  for (final peso in ['Regular', 'Medium', 'Bold', 'Black']) {
    final archivo = File(
      '$raiz/bin/cache/artifacts/material_fonts/Roboto-$peso.ttf',
    );
    expect(archivo.existsSync(), isTrue, reason: archivo.path);
    cargador.addFont(
      Future<ByteData>.value(ByteData.sublistView(archivo.readAsBytesSync())),
    );
  }
  await cargador.load();
}
```

En `test/HU36_jeff/specialty_test_bienvenida_test.dart`, cambia este bloque, que aparece una sola vez,

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:ulima_plus/models/specialty_test_models.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';
```

por este otro.

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/specialty_test_models.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/ulises_bubble.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/welcome_view.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';
import 'montaje_de_pantallas.dart';
```

En `test/HU36_jeff/specialty_test_bienvenida_test.dart`, cambia este bloque, que aparece una sola vez,

```dart
  _controlador();
}
```

por este otro.

```dart
  _controlador();
  _pantalla();
}
```

Agrega al final de `test/HU36_jeff/specialty_test_bienvenida_test.dart`, tras una línea en blanco, este bloque.

```dart
void _pantalla() {
  group('WIDGET · La bienvenida (RF-TEST-3)', () {
    testWidgets('caso 12: las líneas de bienvenida van en orden, sin el '
        'nombre del alumno, y solo la primera sin avatar', (tester) async {
      prepararTest(ApiFalsaDelTest());
      ponerControlador();
      await montarPantalla(tester, const WelcomeView());
      expect(find.text('Test de especialidad'), findsOneWidget);
      expect(find.text('Ulises'), findsOneWidget);
      final burbujas = tester
          .widgetList<UlisesBubble>(find.byType(UlisesBubble))
          .toList();
      expect(burbujas.map((b) => b.text), kBienvenida);
      expect(burbujas.map((b) => b.showAvatar), [false, true, true, true]);
      expect(find.textContaining('Alumna'), findsNothing);
      expect(find.text('Vamos'), findsNothing);
    });

    testWidgets('caso 13: en el asistente van las dos pastillas, «Empezar el '
        'test» y «Saltar y elegir por mi cuenta»', (tester) async {
      prepararTest(ApiFalsaDelTest());
      final ui = UiFalsa();
      ponerControlador(ui: ui);
      await montarPantalla(tester, const WelcomeView());
      expect(find.text('3 a 4 min'), findsOneWidget);
      expect(find.text('Rehazlo en Perfil'), findsOneWidget);
      expect(find.text('Empezar el test'), findsOneWidget);
      expect(find.text('Ahora no'), findsNothing);
      await tester.tap(find.text('Saltar y elegir por mi cuenta'));
      expect(ui.cierres, [SalidaDelTest.seleccionManual]);
    });

    testWidgets('caso 14: en el Perfil no va «Rehazlo en Perfil» y el '
        'secundario es «Ahora no»', (tester) async {
      prepararTest(ApiFalsaDelTest());
      final ui = UiFalsa();
      ponerControlador(origen: OrigenDelTest.perfil, ui: ui);
      await montarPantalla(tester, const WelcomeView());
      expect(find.text('Rehazlo en Perfil'), findsNothing);
      expect(find.text('Saltar y elegir por mi cuenta'), findsNothing);
      await tester.tap(find.text('Ahora no'));
      expect(ui.cierres, [null]);
    });

    testWidgets('caso 15: con un test en pausa, «Seguir el test» y «Empezar '
        'de nuevo»', (tester) async {
      final t = prepararTest(ApiFalsaDelTest());
      t.service.pause(_pausado());
      final c = ponerControlador();
      await montarPantalla(tester, const WelcomeView());
      expect(find.text('Seguir el test'), findsOneWidget);
      expect(find.text('Empezar el test'), findsNothing);
      await tester.tap(find.text('Seguir el test'));
      expect(c.fase.value, FaseDelTest.pregunta);
      expect(c.paso.value, 2);
    });

    testWidgets('caso 16: mientras carga hay esqueleto, el principal está '
        'desactivado y el secundario responde', (tester) async {
      prepararTest(
        ApiFalsaDelTest(contenido: [Completer<Map<String, dynamic>>()]),
      );
      final ui = UiFalsa();
      final c = ponerControlador(ui: ui);
      await montarPantalla(tester, const WelcomeView());
      expect(find.byKey(WelcomeView.skeletonKey), findsOneWidget);
      expect(find.byType(UlisesBubble), findsNothing);
      // El héroe se ve completo.
      expect(find.byType(UlisesAvatar), findsOneWidget);
      await tester.tap(find.text('Empezar el test'));
      expect(c.fase.value, FaseDelTest.bienvenida);
      await tester.tap(find.text('Saltar y elegir por mi cuenta'));
      expect(ui.cierres, [SalidaDelTest.seleccionManual]);
      // El plazo de 15 s del contenido sigue vivo y se vence antes de salir.
      await tester.pump(const Duration(seconds: 15));
    });

    testWidgets('caso 17: con error, el mensaje y «Reintentar», que vuelve a '
        'pedir', (tester) async {
      final api = ApiFalsaDelTest(
        contenido: [http.ClientException('sin red'), contenidoJson()],
      );
      prepararTest(api);
      final c = ponerControlador();
      await montarPantalla(tester, const WelcomeView());
      expect(find.text('No pudimos cargar el test.'), findsOneWidget);
      await tester.tap(find.text('Empezar el test'));
      expect(c.fase.value, FaseDelTest.bienvenida);
      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      expect(api.getsDeContenido, 2);
      expect(find.byType(UlisesBubble), findsNWidgets(4));
    });

    testWidgets('caso 18: con las cuatro líneas de 2026-09-25.4 a 375 × 667 '
        'nada desborda y los botones siguen a la vista', (tester) async {
      prepararTest(ApiFalsaDelTest());
      ponerControlador();
      await montarPantalla(tester, const WelcomeView());
      expect(tester.takeException(), isNull);
      expect(dentroDeLaPantalla(tester, find.text('Empezar el test')), isTrue);
      expect(
        dentroDeLaPantalla(tester, find.text('Saltar y elegir por mi cuenta')),
        isTrue,
      );
      // El cuerpo desplaza y los botones quedan fijos abajo.
      final antes = tester.getRect(find.text('Empezar el test'));
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.pump();
      expect(tester.getRect(find.text('Empezar el test')), antes);
    });

    testWidgets('caso 19: en oscuro el héroe sigue naranja y el cuerpo toma '
        'los tokens', (tester) async {
      prepararTest(ApiFalsaDelTest());
      ponerControlador();
      await montarPantalla(
        tester,
        const WelcomeView(),
        brillo: Brightness.dark,
      );
      expect(
        colorDeTexto(tester, 'Test de especialidad'),
        const Color(0xFF1A0E05),
      );
      expect(
        colorDeTexto(tester, kBienvenida.first),
        MaterialTheme.textPrimary(Brightness.dark),
      );
      expect(
        colorDeTexto(tester, 'Ulises'),
        MaterialTheme.testMuted(Brightness.dark),
      );
    });
  });
}
```

Crea `test/HU36_jeff/specialty_test_accesibilidad_test.dart` con este contenido.

```dart
// test/HU36_jeff/specialty_test_accesibilidad_test.dart
//
// Pruebas de widget de HU36, el test de especialidad, sobre la accesibilidad
// (RF-TEST-13), con lector de pantalla, texto grande y menos movimiento.
// Pantallas: lib/pages/specialty_test/widgets/
//
// Datos inventados (datos_de_prueba.dart). El alumno de prueba es 20230001.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/test_buttons.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/welcome_view.dart';

import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';
import 'montaje_de_pantallas.dart';

/// Toda imagen de [pantalla] queda fuera del árbol de accesibilidad.
void _imagenesFueraDelArbol(WidgetTester tester) {
  final imagenes = find.byType(Image);
  final excluidas = find.descendant(
    of: find.byType(ExcludeSemantics),
    matching: find.byType(Image),
  );
  expect(imagenes.evaluate().length, excluidas.evaluate().length);
}

/// Todo botón del test mide al menos 48 de alto.
void _blancosTactiles(WidgetTester tester) {
  for (final tipo in [TestSecondaryButton, TestPrimaryButton]) {
    for (final e in find.byType(tipo).evaluate()) {
      expect(e.size!.height, greaterThanOrEqualTo(48));
    }
  }
}

void main() {
  // Get.put de un GetxService agenda onReady con
  // Get.engine.addPostFrameCallback, que necesita el binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(cargarRoboto);
  setUp(Get.reset);
  tearDown(Get.reset);

  _bienvenida();
}

void _bienvenida() {
  group('WIDGET · Accesibilidad de la bienvenida (RF-TEST-13)', () {
    for (final escala in [1.0, 1.3, 2.0]) {
      testWidgets('con texto a $escala no desborda y los blancos miden 48', (
        tester,
      ) async {
        prepararTest(ApiFalsaDelTest());
        ponerControlador();
        await montarPantalla(tester, const WelcomeView(), escala: escala);
        expect(tester.takeException(), isNull);
        _blancosTactiles(tester);
        expect(
          dentroDeLaPantalla(tester, find.text('Empezar el test')),
          isTrue,
        );
      });
    }

    testWidgets('desde 1,3 el héroe baja a 200 px', (tester) async {
      prepararTest(ApiFalsaDelTest());
      ponerControlador();
      await montarPantalla(tester, const WelcomeView(), escala: 1.3);
      expect(tester.getSize(find.byKey(WelcomeView.heroKey)).height, 200);
    });

    testWidgets('las imágenes de Ulises y los orbes quedan fuera del árbol', (
      tester,
    ) async {
      prepararTest(ApiFalsaDelTest());
      ponerControlador();
      await montarPantalla(tester, const WelcomeView());
      _imagenesFueraDelArbol(tester);
      expect(find.bySemanticsLabel('Empezar el test'), findsOneWidget);
    });

    testWidgets('con menos movimiento no hay vaivén: la pantalla se asienta', (
      tester,
    ) async {
      prepararTest(ApiFalsaDelTest());
      ponerControlador();
      await montarPantalla(tester, const WelcomeView(), sinMovimiento: true);
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
```

- [ ] **Paso 2: Correr las pruebas y ver que fallan**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/HU36_jeff/specialty_test_bienvenida_test.dart \
  test/HU36_jeff/specialty_test_accesibilidad_test.dart
```

Esperado: FALLA al compilar, sin llegar a correr ningún caso. La salida trae 28 errores distintos (líneas `Error:`), y los primeros dicen esto (las rutas pueden salir absolutas).

```text
test/HU36_jeff/specialty_test_bienvenida_test.dart:19:8: Error: Error when reading 'lib/pages/specialty_test/widgets/welcome_view.dart': No such file or directory
test/HU36_jeff/specialty_test_bienvenida_test.dart:202:42: Error: Couldn't find constructor 'WelcomeView'.
```

- [ ] **Paso 3: Escribir los botones, la burbuja y la bienvenida**

Cada `Obx` lee sus Rx dentro de su propia función y pasa valores a sus hijos, porque un `Obx` que no lee ningún Rx falla. El `Focus` de `UlisesTurnView` va dentro de la región viva, así que su nodo es el mismo. El héroe es igual en los dos temas (decisión abierta 13) y con menos movimiento no se mueve.

Crea `lib/pages/specialty_test/widgets/test_buttons.dart` con este contenido.

```dart
// lib/pages/specialty_test/widgets/test_buttons.dart
// Los botones y el mensaje de error que comparten las pantallas del test y
// el asistente (RF-TEST-1, RF-TEST-11 y RF-TEST-12).

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../configs/themes.dart';

/// El botón principal, a lo ancho, con 52 px de alto como mínimo, degradado
/// de `testAccentHi` a `testAccent` y texto en `testAccentInk`. Desactivado
/// baja su opacidad y no responde.
class TestPrimaryButton extends StatelessWidget {
  const TestPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final double height;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final tinta = MaterialTheme.testAccentInk(b);
    final activo = onPressed != null && !loading;
    return Semantics(
      button: true,
      enabled: activo,
      label: label,
      excludeSemantics: true,
      onTap: activo ? onPressed : null,
      child: Opacity(
        opacity: activo || loading ? 1 : 0.45,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: height),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  MaterialTheme.testAccentHi(b),
                  MaterialTheme.testAccent(b),
                ],
              ),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(17),
                onTap: activo ? onPressed : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: tinta,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (loading) ...[
                        const SizedBox(width: 9),
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: tinta,
                          ),
                        ),
                      ] else if (icon != null) ...[
                        const SizedBox(width: 9),
                        Icon(icon, size: 19, color: tinta),
                      ],
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

/// El botón secundario, con texto en `testAccentText`, 48 px de alto como
/// mínimo y sin fondo.
class TestSecondaryButton extends StatelessWidget {
  const TestSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final color = MaterialTheme.testAccentText(b);
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        disabledForegroundColor: color.withValues(alpha: 0.45),
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 6)],
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Un error de carga (RF-TEST-11), con el texto en `textPrimary` sobre
/// `cardBg`, el ícono en `iconoNaranja` y «Reintentar» como botón
/// secundario.
class TestErrorMessage extends StatelessWidget {
  const TestErrorMessage({
    super.key,
    required this.text,
    required this.onRetry,
  });

  final String text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 6),
      decoration: BoxDecoration(
        color: MaterialTheme.cardBg(b),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MaterialTheme.testLine(b)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Icon(
                  LucideIcons.wifiOff,
                  size: 18,
                  color: MaterialTheme.iconoNaranja(b),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: MaterialTheme.textPrimary(b),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TestSecondaryButton(label: 'Reintentar', onPressed: onRetry),
          ),
        ],
      ),
    );
  }
}
```

Crea `lib/pages/specialty_test/widgets/ulises_bubble.dart` con este contenido.

```dart
// lib/pages/specialty_test/widgets/ulises_bubble.dart
// La burbuja y el avatar de Ulises (RF-TEST-3 y RF-TEST-4).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../configs/themes.dart';
import '../specialty_test_logic.dart';

/// Ulises con la misma imagen del chatbot, recortada en círculo como en
/// `chatbot_page.dart`. Queda fuera del árbol de accesibilidad.
class UlisesAvatar extends StatelessWidget {
  const UlisesAvatar({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ClipOval(
        child: Image.asset(
          'assets/images/ulises_chatbot.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}

/// Una burbuja de Ulises, con el avatar de 28 px o con la sangría que deja
/// su lugar.
class UlisesBubble extends StatelessWidget {
  const UlisesBubble({
    super.key,
    required this.text,
    this.showAvatar = true,
    this.avatarSize = 28,
    this.fontSize = 13.5,
  });

  final String text;
  final bool showAvatar;
  final double avatarSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (showAvatar)
          UlisesAvatar(size: avatarSize)
        else
          SizedBox(width: avatarSize),
        const SizedBox(width: 7),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: MaterialTheme.cardBg(b),
              border: Border.all(color: MaterialTheme.testLine(b)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(6),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: MaterialTheme.textPrimary(b),
                fontSize: fontSize,
                height: 1.4,
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
      ],
    );
  }
}

/// El sello «Cierra el bloque k de B», un poco girado, en `testAccentSoft`.
class SelloDeBloqueView extends StatelessWidget {
  const SelloDeBloqueView({super.key, required this.sello});

  final SelloDeBloque sello;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Padding(
      padding: const EdgeInsets.only(left: 35),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Transform.rotate(
          angle: -2 * math.pi / 180,
          child: Container(
            padding: const EdgeInsets.fromLTRB(3, 3, 10, 3),
            decoration: BoxDecoration(
              color: MaterialTheme.testAccentSoft(b),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: MaterialTheme.testAccent(b),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.check,
                      size: 11,
                      color: MaterialTheme.testAccentInk(b),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    sello.texto,
                    style: TextStyle(
                      color: MaterialTheme.testAccentDeep(b),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
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

/// El último turno de Ulises, con sus burbujas, el avatar en la última y el
/// sello después de la primera si lo hay. Es una región viva, así que el
/// lector lee la reacción al avanzar (RF-TEST-13).
class UlisesTurnView extends StatelessWidget {
  const UlisesTurnView({super.key, required this.turno, this.focusNode});

  final TurnoDeUlises turno;

  /// El foco del lector en la espera (RF-TEST-13).
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final lineas = turno.lineas;
    final hijos = <Widget>[];
    for (var i = 0; i < lineas.length; i++) {
      if (i > 0) hijos.add(const SizedBox(height: 4));
      hijos.add(
        UlisesBubble(text: lineas[i], showAvatar: i == lineas.length - 1),
      );
      if (i == 0 && turno.sello != null) {
        hijos
          ..add(const SizedBox(height: 6))
          ..add(SelloDeBloqueView(sello: turno.sello!));
      }
    }
    Widget contenido = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: hijos,
    );
    // El Focus va dentro de la región viva, así que su nodo es el mismo.
    if (focusNode != null) {
      contenido = Focus(focusNode: focusNode, child: contenido);
    }
    return Semantics(liveRegion: true, container: true, child: contenido);
  }
}
```

Crea `lib/pages/specialty_test/widgets/welcome_view.dart` con este contenido.

```dart
// lib/pages/specialty_test/widgets/welcome_view.dart
// La bienvenida del test (RF-TEST-3), pantalla 1 de la maqueta.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../components/skeleton.dart';
import '../../../configs/themes.dart';
import '../../../models/specialty_test_models.dart';
import '../specialty_test_controller.dart';
import '../specialty_test_logic.dart';
import 'test_buttons.dart';
import 'ulises_bubble.dart';

/// Tinta del héroe, igual en los dos temas (decisión abierta 13).
const Color _tintaHeroe = Color(0xFF1A0E05);

class WelcomeView extends GetView<SpecialtyTestController> {
  const WelcomeView({super.key});

  /// Marca el esqueleto para las pruebas. Con `SkeletonPulse` en pantalla no
  /// se puede usar `pumpAndSettle`.
  static const Key skeletonKey = Key('bienvenida-esqueleto');

  /// Marca el héroe, que baja a 200 px desde la escala 1,3 (RF-TEST-13).
  static const Key heroKey = Key('bienvenida-heroe');

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return ColoredBox(
      color: MaterialTheme.pageBg(b),
      child: Column(
        children: [
          // Cada Obx lee sus Rx dentro de su función, para quedar suscrito.
          Obx(
            () =>
                _Heroe(especialidades: controller.contenido.value?.specialties),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Obx(
                () => _Cuerpo(
                  carga: controller.carga.value,
                  lineas: controller.contenido.value?.ulises.welcome,
                  enAsistente: controller.enAsistente,
                  onRetry: controller.reintentarCarga,
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Obx(
                () => _Botones(
                  lista: controller.carga.value == EstadoDeCarga.lista,
                  avance: controller.hayAvance,
                  controller: controller,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Heroe extends StatefulWidget {
  const _Heroe({required this.especialidades});

  final List<TestSpecialty>? especialidades;

  @override
  State<_Heroe> createState() => _HeroeState();
}

class _HeroeState extends State<_Heroe> with SingleTickerProviderStateMixin {
  late final AnimationController _vaiven = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Con menos movimiento no hay vaivén de Ulises ni de los orbes.
    if (MediaQuery.disableAnimationsOf(context)) {
      _vaiven.stop();
      _vaiven.value = 0;
    } else if (!_vaiven.isAnimating) {
      _vaiven.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _vaiven.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final escala = MediaQuery.textScalerOf(context).scale(1);
    final alto = escala >= 1.3 ? 200.0 : 284.0;
    final arriba = MediaQuery.paddingOf(context).top;
    final lado = escala >= 1.3 ? 104.0 : 136.0;
    final especialidades = widget.especialidades ?? const <TestSpecialty>[];
    // Posiciones de los cuatro orbes, en fracciones del héroe.
    const lugares = <Offset>[
      Offset(0.06, 0.45),
      Offset(0.80, 0.37),
      Offset(0.79, 0.66),
      Offset(0.11, 0.70),
    ];
    return SizedBox(
      key: WelcomeView.heroKey,
      height: alto + arriba,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, 0.16),
              radius: 0.95,
              colors: [
                Color(0xFFFFA35E),
                Color(0xFFFF7A1A),
                Color(0xFFFF6600),
                Color(0xFFE25A00),
              ],
              stops: [0, 0.40, 0.68, 1],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, box) {
              return AnimatedBuilder(
                animation: _vaiven,
                builder: (context, _) {
                  final t = Curves.easeInOut.transform(_vaiven.value);
                  return Stack(
                    children: [
                      for (var i = 0; i < 4; i++)
                        Positioned(
                          left: box.maxWidth * lugares[i].dx,
                          top: arriba + alto * lugares[i].dy - 4 * t,
                          child: _Orbe(
                            especialidad: i < especialidades.length
                                ? especialidades[i]
                                : null,
                          ),
                        ),
                      Align(
                        alignment: Alignment(0, arriba / (alto + arriba) + 0.1),
                        child: Transform.translate(
                          offset: Offset(0, -5 * t),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Color(0xEBFFFFFF),
                              shape: BoxShape.circle,
                            ),
                            child: UlisesAvatar(size: lado),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        top: arriba + 12,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(8, 6, 11, 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ExcludeSemantics(
                                  child: Icon(
                                    LucideIcons.compass,
                                    size: 15,
                                    color: _tintaHeroe,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'Test de especialidad',
                                    style: TextStyle(
                                      color: _tintaHeroe,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Un orbe blanco de 42 px con el ícono de una especialidad en su color
/// claro, sin nombre. Es decorativo.
class _Orbe extends StatelessWidget {
  const _Orbe({required this.especialidad});

  final TestSpecialty? especialidad;

  @override
  Widget build(BuildContext context) {
    final e = especialidad;
    return ExcludeSemantics(
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x735A1E00),
              blurRadius: 14,
              offset: Offset(0, 6),
              spreadRadius: -4,
            ),
          ],
        ),
        child: e == null
            ? null
            : Icon(
                iconoDelTest(e.icon),
                size: 21,
                color:
                    colorDeHex(e.colorLight) ??
                    MaterialTheme.testTaskIconInk(Brightness.light),
              ),
      ),
    );
  }
}

class _Cuerpo extends StatelessWidget {
  const _Cuerpo({
    required this.carga,
    required this.lineas,
    required this.enAsistente,
    required this.onRetry,
  });

  final EstadoDeCarga carga;
  final List<String>? lineas;
  final bool enAsistente;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final lineas = this.lineas;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 35, bottom: 5),
          child: Text(
            'Ulises',
            style: TextStyle(
              color: MaterialTheme.testMuted(b),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (carga == EstadoDeCarga.error)
          TestErrorMessage(text: 'No pudimos cargar el test.', onRetry: onRetry)
        else if (carga == EstadoDeCarga.cargando || lineas == null)
          const SkeletonPulse(
            key: WelcomeView.skeletonKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 35),
                  child: SkeletonBox(width: 230, height: 54, borderRadius: 18),
                ),
                SizedBox(height: 6),
                Padding(
                  padding: EdgeInsets.only(left: 35),
                  child: SkeletonBox(width: 180, height: 38, borderRadius: 18),
                ),
              ],
            ),
          )
        else
          Semantics(
            container: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < lineas.length; i++) ...[
                  if (i > 0) const SizedBox(height: 4),
                  UlisesBubble(text: lineas[i], showAvatar: i > 0),
                ],
              ],
            ),
          ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 35),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              const _Pastilla(icono: LucideIcons.clock, texto: '3 a 4 min'),
              if (enAsistente)
                const _Pastilla(
                  icono: LucideIcons.rotateCcw,
                  texto: 'Rehazlo en Perfil',
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Pastilla extends StatelessWidget {
  const _Pastilla({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 30),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
        decoration: BoxDecoration(
          color: MaterialTheme.testAccentSoft(b),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(
                icono,
                size: 15,
                color: MaterialTheme.testAccentText(b),
              ),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                texto,
                style: TextStyle(
                  color: MaterialTheme.testAccentDeep(b),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Botones extends StatelessWidget {
  const _Botones({
    required this.lista,
    required this.avance,
    required this.controller,
  });

  final bool lista;
  final bool avance;
  final SpecialtyTestController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TestPrimaryButton(
          label: avance ? 'Seguir el test' : 'Empezar el test',
          icon: LucideIcons.arrowRight,
          onPressed: lista ? controller.empezar : null,
        ),
        const SizedBox(height: 4),
        if (avance)
          TestSecondaryButton(
            label: 'Empezar de nuevo',
            onPressed: lista ? controller.empezarDeNuevo : null,
          ),
        if (controller.enAsistente)
          TestSecondaryButton(
            label: 'Saltar y elegir por mi cuenta',
            onPressed: controller.saltar,
          )
        else
          TestSecondaryButton(label: 'Ahora no', onPressed: controller.ahoraNo),
      ],
    );
  }
}
```

- [ ] **Paso 4: Correr las pruebas y ver que pasan**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/HU36_jeff/specialty_test_bienvenida_test.dart \
  test/HU36_jeff/specialty_test_accesibilidad_test.dart
```

Esperado: PASS, `+25: All tests passed!`.

- [ ] **Paso 5: Dar formato y analizar**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/pages/specialty_test/widgets/test_buttons.dart \
  lib/pages/specialty_test/widgets/ulises_bubble.dart \
  lib/pages/specialty_test/widgets/welcome_view.dart \
  test/HU36_jeff/montaje_de_pantallas.dart \
  test/HU36_jeff/specialty_test_bienvenida_test.dart \
  test/HU36_jeff/specialty_test_accesibilidad_test.dart
```

Esperado: `Formatted 6 files (0 changed)`.

```bash
cd "${REPO:?}"
"${FLUTTER:?}" analyze --no-pub
```

Esperado: `6 issues found.`, los 6 de la línea base y ninguno en un archivo de esta tarea.

- [ ] **Paso 6: Commit**

```bash
cd "${REPO:?}"
test "$(git branch --show-current)" = feat/test-especialidad-fe || echo 'PARAR: rama equivocada'
git status --short
git add lib/pages/specialty_test/widgets/test_buttons.dart \
  lib/pages/specialty_test/widgets/ulises_bubble.dart \
  lib/pages/specialty_test/widgets/welcome_view.dart \
  test/HU36_jeff/montaje_de_pantallas.dart \
  test/HU36_jeff/specialty_test_bienvenida_test.dart \
  test/HU36_jeff/specialty_test_accesibilidad_test.dart
git commit -m 'feat(specialty-test): la bienvenida muestra a Ulises, sus líneas y los botones de cada origen, con carga y error (RF-TEST-3)'
git log -1 --format='%an <%ae>'
git log -1 --format=%B | grep -qi '^co-authored-by:' && echo 'PARAR: el commit trae trailer'
```

Esperado: ningún `PARAR`. Antes del `git add`, `git status --short` lista solo los archivos de la tarea, y el autor es `Jeffangeloss <178797184+jeffangeloss@users.noreply.github.com>`.

---

### Tarea 12: La pregunta en pantalla, con el duelo, la escala y el desempate

**Requisitos:** RF-TEST-4 (barra, plumas, burbuja, sello, historial, transiciones), RF-TEST-5, RF-TEST-6 y su parte de RF-TEST-13.

**Archivos:**
- Crear `lib/pages/specialty_test/widgets/task_icon.dart` y `lib/pages/specialty_test/widgets/question_view.dart`
- Crear `test/HU36_jeff/specialty_test_preguntas_test.dart`
- Modificar `test/HU36_jeff/specialty_test_conversacion_test.dart` (imports, grupo `_pantalla`)
- Modificar `test/HU36_jeff/specialty_test_accesibilidad_test.dart` (imports, grupo `_preguntas`)

**Interfaces:**

- Consume el controlador (`contenido`, `paso`, `respuestas`,
  `desempates`, `preguntaActual`, `desempateActual`, `respuestaActual`,
  `historialAbierto`, `responder`, `avanzar`, `atras`, `pausar`,
  `alternarHistorial`), las funciones de las Tareas 3 y 4 y los widgets de
  la Tarea 11.
- Produce lo que sigue, que usan la espera (Tarea 13) y la ruta (Tarea 15).

```dart
// widgets/task_icon.dart
class TaskIconTile { const TaskIconTile({required String? icono, Color? color,
  double width = 80, double height = 80, double iconSize = 40,
  BorderRadius borderRadius, bool apagada = false}); }
// widgets/question_view.dart
class QuestionView extends GetView<SpecialtyTestController> {
  static Key tarjetaKey(String valor); static Key opcionKey(String id);
  static const Key historialKey; }
class TestTopBar { const TestTopBar({required String subtitulo,
  required VoidCallback onBack, required VoidCallback onPause}); }
class TestFeathers { const TestFeathers({required int total,
  required int? actual, Set<int> respondidas}); static Key plumaKey(int i); }
```

- [ ] **Paso 1: Escribir las pruebas que fallan**

Crea `test/HU36_jeff/specialty_test_preguntas_test.dart` con este contenido.

```dart
// test/HU36_jeff/specialty_test_preguntas_test.dart
//
// Pruebas de widget de HU36, el test de especialidad, sobre el duelo
// (RF-TEST-5) y la escala de gusto (RF-TEST-6), con los íconos de Lucide de
// cada tarea.
// Pantalla: lib/pages/specialty_test/widgets/question_view.dart
//
// Datos inventados (datos_de_prueba.dart). El alumno de prueba es 20230001.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/specialty_test_models.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/question_view.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/task_icon.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';
import 'montaje_de_pantallas.dart';

const Color _swClaro = Color(0xFF1E3A8A);
const Color _swOscuro = Color(0xFFA5C0F7);

/// Abre la pregunta de índice [indice] con las respuestas anteriores de
/// [respuestasCompletas] y monta la pantalla.
Future<SpecialtyTestController> _enLaPregunta(
  WidgetTester tester, {
  int indice = 0,
  Brightness brillo = Brightness.light,
  double escala = 1.0,
  Size tamano = kIphoneSE,
  Map<String, dynamic>? contenido,
}) async {
  prepararTest(ApiFalsaDelTest(contenido: [contenido ?? contenidoJson()]));
  final c = ponerControlador();
  await tester.pump();
  c.empezar();
  responderPasos(c, respuestasEnOrden.take(indice).toList());
  await montarPantalla(
    tester,
    const QuestionView(),
    brillo: brillo,
    escala: escala,
    tamano: tamano,
  );
  return c;
}

BoxDecoration _decoracion(WidgetTester tester, String valor) =>
    tester
            .widget<AnimatedContainer>(
              find
                  .descendant(
                    of: find.byKey(QuestionView.tarjetaKey(valor)),
                    matching: find.byType(AnimatedContainer),
                  )
                  .first,
            )
            .decoration!
        as BoxDecoration;

TaskIconTile _baldosa(WidgetTester tester, String valor) =>
    tester.widget<TaskIconTile>(
      find.descendant(
        of: find.byKey(QuestionView.tarjetaKey(valor)),
        matching: find.byType(TaskIconTile),
      ),
    );

Icon _icono(WidgetTester tester, Finder dentroDe) => tester.widget<Icon>(
  find.descendant(
    of: find.descendant(of: dentroDe, matching: find.byType(TaskIconTile)),
    matching: find.byType(Icon),
  ),
);

void main() {
  // Get.put de un GetxService agenda onReady con
  // Get.engine.addPostFrameCallback, que necesita el binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(Get.reset);
  tearDown(Get.reset);

  _duelo();
  _escala();
}

void _duelo() {
  group('WIDGET · El duelo (RF-TEST-5)', () {
    testWidgets('caso 1: antes del toque las dos tarjetas son neutras', (
      tester,
    ) async {
      await _enLaPregunta(tester);
      const b = Brightness.light;
      for (final valor in ['top', 'bottom']) {
        final d = _decoracion(tester, valor);
        expect(d.color, MaterialTheme.cardBg(b));
        expect(d.border!.top.color, MaterialTheme.testLine(b));
        expect(_baldosa(tester, valor).color, isNull);
      }
      expect(
        _icono(tester, find.byKey(QuestionView.tarjetaKey('top'))).color,
        MaterialTheme.testTaskIconInk(b),
      );
      expect(find.text('ESTO O AQUELLO'), findsOneWidget);
      expect(find.text('¿Cuál harías con más ganas?'), findsOneWidget);
      expect(find.byIcon(LucideIcons.check), findsNothing);
    });

    testWidgets('caso 2: al tocar, la tarjeta se enciende con el color de su '
        'especialidad y la otra se apaga', (tester) async {
      final c = await _enLaPregunta(tester);
      await tester.tap(find.byKey(QuestionView.tarjetaKey('top')));
      await tester.pump(const Duration(milliseconds: 150));
      final d = _decoracion(tester, 'top');
      expect(d.border!.top.color, _swClaro);
      expect(d.border!.top.width, 1.5);
      expect(d.boxShadow!.single.spreadRadius, 4);
      expect(_baldosa(tester, 'top').color, _swClaro);
      expect(_baldosa(tester, 'bottom').apagada, isTrue);
      final otra = tester.widget<Text>(find.text('Tarea de prueba uno abajo'));
      expect(otra.style!.color, MaterialTheme.testInk2(Brightness.light));
      expect(otra.style!.fontWeight, FontWeight.w600);
      expect(find.byIcon(LucideIcons.check), findsOneWidget);
      expect(c.respuestas['q01'], 'top');
      await tester.pump(const Duration(milliseconds: 250));
    });

    testWidgets('caso 3: en oscuro se enciende con color.dark', (tester) async {
      await _enLaPregunta(tester, brillo: Brightness.dark);
      await tester.tap(find.byKey(QuestionView.tarjetaKey('top')));
      await tester.pump(const Duration(milliseconds: 150));
      expect(_decoracion(tester, 'top').border!.top.color, _swOscuro);
      await tester.pump(const Duration(milliseconds: 250));
    });

    testWidgets('caso 4: «Me gustan las dos» enciende las dos y «Ninguna me '
        'llama» apaga las dos', (tester) async {
      await _enLaPregunta(tester);
      await tester.tap(find.text('Me gustan las dos'));
      await tester.pump(const Duration(milliseconds: 150));
      expect(_baldosa(tester, 'top').color, isNotNull);
      expect(_baldosa(tester, 'bottom').color, isNotNull);
      expect(find.byIcon(LucideIcons.check), findsNWidgets(2));
      await tester.pump(const Duration(milliseconds: 250));
      Get.reset();
      await _enLaPregunta(tester);
      await tester.tap(find.text('Ninguna me llama'));
      await tester.pump(const Duration(milliseconds: 150));
      expect(_baldosa(tester, 'top').apagada, isTrue);
      expect(_baldosa(tester, 'bottom').apagada, isTrue);
      expect(find.byIcon(LucideIcons.check), findsNothing);
      await tester.pump(const Duration(milliseconds: 250));
    });

    testWidgets('caso 5: avanza sola a los 350 ms y otro toque en ese tiempo '
        'no hace nada', (tester) async {
      final c = await _enLaPregunta(tester);
      await tester.tap(find.byKey(QuestionView.tarjetaKey('top')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(QuestionView.tarjetaKey('bottom')));
      await tester.pump(const Duration(milliseconds: 249));
      expect(c.paso.value, 0);
      expect(c.respuestas['q01'], 'top');
      await tester.pump(const Duration(milliseconds: 1));
      expect(c.paso.value, 1);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Tarea de prueba dos arriba'), findsOneWidget);
    });

    testWidgets('caso 6: el ícono de la tarea es el de su nombre, y uno '
        'desconocido cae al neutro', (tester) async {
      await _enLaPregunta(tester);
      expect(
        _icono(tester, find.byKey(QuestionView.tarjetaKey('top'))).icon,
        LucideIcons.shoppingCart,
      );
      expect(
        _icono(tester, find.byKey(QuestionView.tarjetaKey('bottom'))).icon,
        LucideIcons.shelvingUnit,
      );
      Get.reset();
      await _enLaPregunta(
        tester,
        contenido: contenidoJson(iconoDeLaPrimera: 'icono-que-no-existe'),
      );
      expect(
        _icono(tester, find.byKey(QuestionView.tarjetaKey('top'))).icon,
        LucideIcons.sparkles,
      );
    });

    testWidgets('caso 7: el desempate usa la misma pantalla, con su rótulo y '
        'sus íconos, neutros hasta el toque', (tester) async {
      final t = prepararTest(ApiFalsaDelTest());
      t.service.pause(
        PausedSpecialtyTest(
          content: SpecialtyTestContent.tryParse(contenidoJson())!,
          answers: respuestasCompletas(),
          tiebreaks: [
            TiebreakRecord(
              tiebreak:
                  (EvaluationStep.tryParse(desempateJson())! as TiebreakStep)
                      .tiebreak,
              ulisesLine: 'Línea del desempate de prueba.',
            ),
          ],
        ),
      );
      final c = ponerControlador();
      await tester.pump();
      c.empezar();
      await montarPantalla(tester, const QuestionView());
      expect(find.text('DESEMPATE'), findsOneWidget);
      expect(find.text('Desempate 1'), findsOneWidget);
      expect(find.text('Línea del desempate de prueba.'), findsOneWidget);
      final top = find.byKey(QuestionView.tarjetaKey('top'));
      expect(_icono(tester, top).icon, LucideIcons.soup);
      expect(
        _icono(tester, top).color,
        MaterialTheme.testTaskIconInk(Brightness.light),
      );
      await tester.tap(top);
      await tester.pump(const Duration(milliseconds: 150));
      // `si` en claro.
      expect(_icono(tester, top).color, const Color(0xFF9333EA));
      await tester.pump(const Duration(milliseconds: 250));
    });
  });
}

void _escala() {
  group('WIDGET · La escala de gusto (RF-TEST-6)', () {
    testWidgets('caso 8: la tarjeta trae el ícono, el rótulo, la tarea y el '
        'enunciado, y el ícono nunca toma color', (tester) async {
      final c = await _enLaPregunta(tester, indice: 2);
      expect(find.text('ESCALA DE GUSTO'), findsOneWidget);
      expect(find.text('Tarea de prueba tres en escala'), findsOneWidget);
      expect(find.text('¿Cuánto te gustaría hacer esto?'), findsOneWidget);
      Icon icono() => tester.widget<Icon>(
        find.descendant(
          of: find.byType(TaskIconTile),
          matching: find.byType(Icon),
        ),
      );
      expect(icono().icon, LucideIcons.smartphone);
      expect(icono().color, MaterialTheme.testTaskIconInk(Brightness.light));
      c.responder('bastante', avanceSolo: false);
      await tester.pump();
      expect(icono().color, MaterialTheme.testTaskIconInk(Brightness.light));
    });

    testWidgets('caso 9: las cuatro opciones van en fila, con su emoji y en '
        'su orden', (tester) async {
      await _enLaPregunta(tester, indice: 2);
      final y = <double>{
        for (final id in ['nada', 'un_poco', 'bastante', 'me_encantaria'])
          tester.getTopLeft(find.byKey(QuestionView.opcionKey(id))).dy,
      };
      expect(y, hasLength(1));
      final x = [
        for (final id in ['nada', 'un_poco', 'bastante', 'me_encantaria'])
          tester.getTopLeft(find.byKey(QuestionView.opcionKey(id))).dx,
      ];
      expect(x, [...x]..sort());
      for (final e in ['😴', '🙂', '😃', '🤩']) {
        expect(find.text(e), findsOneWidget);
      }
      expect(
        tester.getSize(find.byKey(QuestionView.opcionKey('nada'))).height,
        greaterThanOrEqualTo(64),
      );
    });

    for (final (escala, ancho) in [(1.3, 375.0), (1.0, 320.0)]) {
      testWidgets('caso 10: con texto a $escala y $ancho de ancho van en dos '
          'por dos', (tester) async {
        await _enLaPregunta(
          tester,
          indice: 2,
          escala: escala,
          tamano: Size(ancho, 667),
        );
        double arriba(String id) =>
            tester.getTopLeft(find.byKey(QuestionView.opcionKey(id))).dy;
        expect(arriba('nada'), arriba('un_poco'));
        expect(arriba('bastante'), greaterThan(arriba('nada')));
        expect(arriba('bastante'), arriba('me_encantaria'));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('caso 11: la opción elegida pasa a naranja y crece un 8 %', (
      tester,
    ) async {
      final c = await _enLaPregunta(tester, indice: 2);
      await tester.tap(find.text('Bastante'));
      await tester.pump(const Duration(milliseconds: 150));
      const b = Brightness.light;
      final opcion = find.byKey(QuestionView.opcionKey('bastante'));
      final material = tester.widget<Material>(
        find.descendant(of: opcion, matching: find.byType(Material)).first,
      );
      expect(material.color, MaterialTheme.testAccentSoft(b));
      expect(
        (material.shape! as RoundedRectangleBorder).side.color,
        MaterialTheme.testAccent(b),
      );
      expect(colorDeTexto(tester, 'Bastante'), MaterialTheme.testAccentDeep(b));
      expect(
        tester
            .widget<AnimatedScale>(
              find.descendant(of: opcion, matching: find.byType(AnimatedScale)),
            )
            .scale,
        1.08,
      );
      expect(c.respuestas['q03'], 'bastante');
      await tester.pump(const Duration(milliseconds: 250));
    });
  });
}
```

En `test/HU36_jeff/specialty_test_conversacion_test.dart`, cambia este bloque, que aparece una sola vez,

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/specialty_test_models.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';
```

por este otro.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/specialty_test_models.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/question_view.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/ulises_bubble.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';
import 'montaje_de_pantallas.dart';
```

En `test/HU36_jeff/specialty_test_conversacion_test.dart`, cambia este bloque, que aparece una sola vez,

```dart
  _controlador();
}
```

por este otro.

```dart
  _controlador();
  _pantalla();
}
```

Agrega al final de `test/HU36_jeff/specialty_test_conversacion_test.dart`, tras una línea en blanco, este bloque.

```dart
/// Monta la conversación en la pregunta 1 y deja al controlador a mano.
Future<SpecialtyTestController> _conversacion(
  WidgetTester tester, {
  UiFalsa? ui,
}) async {
  prepararTest(ApiFalsaDelTest());
  final c = ponerControlador(ui: ui);
  await tester.pump();
  c.empezar();
  await montarPantalla(tester, const QuestionView());
  return c;
}

/// Responde tocando y deja pasar el avance y la transición.
Future<void> _tocarYAvanzar(WidgetTester tester, Finder objetivo) async {
  await tester.tap(objetivo);
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump(const Duration(milliseconds: 200));
}

List<String> _burbujas(WidgetTester tester) => tester
    .widgetList<UlisesBubble>(find.byType(UlisesBubble))
    .map((b) => b.text)
    .toList();

void _pantalla() {
  group('WIDGET · La conversación con Ulises (RF-TEST-4)', () {
    testWidgets('caso 9: la barra dice «Pregunta N de T» con las preguntas '
        'del contenido', (tester) async {
      await _conversacion(tester);
      expect(find.text('Ulises'), findsOneWidget);
      expect(find.text('Pregunta 1 de 5'), findsOneWidget);
      expect(find.byTooltip('Pregunta anterior'), findsOneWidget);
      expect(find.byTooltip('Pausar el test y seguir luego'), findsOneWidget);
      await _tocarYAvanzar(tester, find.byKey(QuestionView.tarjetaKey('top')));
      expect(find.text('Pregunta 2 de 5'), findsOneWidget);
    });

    testWidgets('caso 10: las plumas van llenas hasta la actual y vacías '
        'después, siempre en naranja', (tester) async {
      await _conversacion(tester);
      await _tocarYAvanzar(tester, find.byKey(QuestionView.tarjetaKey('top')));
      const b = Brightness.light;
      Color pluma(int i) =>
          tester.widget<Icon>(find.byKey(TestFeathers.plumaKey(i))).color!;
      expect(pluma(0), MaterialTheme.testFeatherOn(b));
      expect(pluma(1), MaterialTheme.testFeatherOn(b));
      expect(pluma(2), MaterialTheme.testFeatherOff(b));
      expect(pluma(4), MaterialTheme.testFeatherOff(b));
    });

    testWidgets('caso 11: en pantalla queda solo el último turno de Ulises, '
        'con sus reglas', (tester) async {
      await _conversacion(tester);
      expect(_burbujas(tester), [kDuelHelp]);
      await _tocarYAvanzar(tester, find.byKey(QuestionView.tarjetaKey('top')));
      expect(_burbujas(tester), ['Reacción propia de la pregunta uno.']);
      await _tocarYAvanzar(tester, find.text('Me gustan las dos'));
      expect(_burbujas(tester), [kBoth[0], kScaleHelp]);
      await _tocarYAvanzar(tester, find.text('Bastante'));
      expect(_burbujas(tester), ['Cierre de prueba del bloque uno.']);
      expect(find.text('Cierra el bloque 1 de 2'), findsOneWidget);
    });

    testWidgets('caso 12: ninguna línea ni rótulo nombra una especialidad', (
      tester,
    ) async {
      await _conversacion(tester);
      for (final nombre in [
        'Ingeniería de Software',
        'Tecnologías de la Información',
        'Sistemas de Información',
        'Desarrollo de Videojuegos',
      ]) {
        expect(find.textContaining(nombre), findsNothing);
      }
    });

    testWidgets('caso 13: la pastilla del historial se despliega y se pliega', (
      tester,
    ) async {
      await _conversacion(tester);
      expect(find.text('1 respuesta anterior'), findsNothing);
      await _tocarYAvanzar(tester, find.byKey(QuestionView.tarjetaKey('top')));
      expect(find.text('1 respuesta anterior'), findsOneWidget);
      expect(find.byKey(QuestionView.historialKey), findsNothing);
      await tester.tap(find.text('1 respuesta anterior'));
      await tester.pump();
      expect(find.byKey(QuestionView.historialKey), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(QuestionView.historialKey),
          matching: find.textContaining('Tarea de prueba uno arriba'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('1 respuesta anterior'));
      await tester.pump();
      expect(find.byKey(QuestionView.historialKey), findsNothing);
    });

    testWidgets(
      'caso 14: «Pregunta anterior» vuelve con la respuesta marcada',
      (tester) async {
        final c = await _conversacion(tester);
        await _tocarYAvanzar(
          tester,
          find.byKey(QuestionView.tarjetaKey('top')),
        );
        await tester.tap(find.byTooltip('Pregunta anterior'));
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.text('Pregunta 1 de 5'), findsOneWidget);
        expect(find.byIcon(LucideIcons.check), findsOneWidget);
        expect(c.respuestaActual, 'top');
      },
    );

    testWidgets('caso 15: «Pausar el test y seguir luego» cierra la ruta', (
      tester,
    ) async {
      final ui = UiFalsa();
      await _conversacion(tester, ui: ui);
      await tester.tap(find.byTooltip('Pausar el test y seguir luego'));
      expect(ui.cierres, [null]);
    });
  });
}
```

En `test/HU36_jeff/specialty_test_accesibilidad_test.dart`, cambia este bloque, que aparece una sola vez,

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/test_buttons.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/welcome_view.dart';

import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';
import 'montaje_de_pantallas.dart';
```

por este otro.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/question_view.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/test_buttons.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/ulises_bubble.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/welcome_view.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';
import 'montaje_de_pantallas.dart';
```

En `test/HU36_jeff/specialty_test_accesibilidad_test.dart`, cambia este bloque, que aparece una sola vez,

```dart
  _bienvenida();
}
```

por este otro.

```dart
  _bienvenida();
  _preguntas();
}
```

Agrega al final de `test/HU36_jeff/specialty_test_accesibilidad_test.dart`, tras una línea en blanco, este bloque.

```dart
/// Monta la conversación en la pregunta de índice [indice].
Future<SpecialtyTestController> _enLaPregunta(
  WidgetTester tester, {
  int indice = 0,
  double escala = 1.0,
  bool lector = false,
  bool sinMovimiento = false,
}) async {
  prepararTest(ApiFalsaDelTest());
  final c = ponerControlador();
  await tester.pump();
  c.empezar();
  responderPasos(c, respuestasEnOrden.take(indice).toList());
  await montarPantalla(
    tester,
    const QuestionView(),
    escala: escala,
    lector: lector,
    sinMovimiento: sinMovimiento,
  );
  await tester.pump();
  return c;
}

/// El nodo `Focus` que envuelve a [texto] tiene el foco.
bool _conFoco(WidgetTester tester, String texto) =>
    Focus.of(tester.element(find.text(texto))).hasPrimaryFocus;

void _preguntas() {
  group('WIDGET · Accesibilidad de las preguntas (RF-TEST-13)', () {
    testWidgets('cada tarjeta es un botón con su tarea, la ayuda y selected', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await _enLaPregunta(tester, lector: true);
      final top = find.byKey(QuestionView.tarjetaKey('top'));
      expect(
        tester.getSemantics(top),
        isSemantics(
          label: 'Tarea de prueba uno arriba',
          hint: kDuelHelp,
          isButton: true,
          hasTapAction: true,
          isSelected: false,
        ),
      );
      await tester.tap(top);
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.getSemantics(top), isSemantics(isSelected: true));
      expect(
        tester.getSemantics(find.text('Me gustan las dos')),
        isSemantics(label: 'Me gustan las dos', isButton: true),
      );
      semantica.dispose();
    });

    testWidgets('la escala es un grupo con el enunciado y cada opción, un '
        'botón exclusivo con checked', (tester) async {
      final semantica = tester.ensureSemantics();
      await _enLaPregunta(tester, indice: 2, lector: true);
      final opcion = find.byKey(QuestionView.opcionKey('bastante'));
      expect(
        tester.getSemantics(opcion),
        isSemantics(
          label: 'Bastante',
          isButton: true,
          isInMutuallyExclusiveGroup: true,
          isChecked: false,
        ),
      );
      await tester.tap(opcion);
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.getSemantics(opcion), isSemantics(isChecked: true));
      semantica.dispose();
    });

    testWidgets('la burbuja es una región viva y el enunciado, un encabezado', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await _enLaPregunta(tester);
      expect(
        tester.getSemantics(find.byType(UlisesTurnView)),
        isSemantics(isLiveRegion: true),
      );
      expect(
        tester.getSemantics(find.text('¿Cuál harías con más ganas?')),
        isSemantics(isHeader: true),
      );
      semantica.dispose();
    });

    testWidgets('el foco pasa al enunciado nuevo al avanzar y al volver', (
      tester,
    ) async {
      final c = await _enLaPregunta(tester, lector: true);
      expect(_conFoco(tester, '¿Cuál harías con más ganas?'), isTrue);
      await tester.tap(find.byKey(QuestionView.tarjetaKey('top')));
      await tester.pump();
      await tester.tap(find.text('Siguiente'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
      expect(c.paso.value, 1);
      expect(_conFoco(tester, '¿Y entre estas dos?'), isTrue);
      await tester.tap(find.byTooltip('Pregunta anterior'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
      expect(_conFoco(tester, '¿Cuál harías con más ganas?'), isTrue);
    });

    testWidgets('con lector no hay avance solo y aparece «Siguiente»', (
      tester,
    ) async {
      final c = await _enLaPregunta(tester, lector: true);
      expect(find.text('Siguiente'), findsNothing);
      await tester.tap(find.byKey(QuestionView.tarjetaKey('bottom')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(c.paso.value, 0);
      expect(find.text('Siguiente'), findsOneWidget);
      await tester.tap(find.text('Siguiente'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(c.paso.value, 1);
    });

    testWidgets('la pastilla del historial dice ver u ocultar y su estado', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await _enLaPregunta(tester, indice: 2);
      final pastilla = find.text('2 respuestas anteriores');
      expect(
        tester.getSemantics(pastilla),
        isSemantics(
          label: 'Ver tus 2 respuestas anteriores',
          isButton: true,
          isExpanded: false,
        ),
      );
      await tester.tap(pastilla);
      await tester.pump();
      expect(
        tester.getSemantics(pastilla),
        isSemantics(
          label: 'Ocultar tus respuestas anteriores',
          isExpanded: true,
        ),
      );
      semantica.dispose();
    });

    testWidgets('las imágenes quedan fuera del árbol y los blancos miden 48', (
      tester,
    ) async {
      await _enLaPregunta(tester);
      _imagenesFueraDelArbol(tester);
      for (final t in ['Pregunta anterior', 'Pausar el test y seguir luego']) {
        final r = tester.getSize(find.byTooltip(t));
        expect(r.width, greaterThanOrEqualTo(48));
        expect(r.height, greaterThanOrEqualTo(48));
      }
      expect(
        tester
            .getSize(
              find.ancestor(
                of: find.text('Me gustan las dos'),
                matching: find.byType(InkWell),
              ),
            )
            .height,
        greaterThanOrEqualTo(48),
      );
    });

    for (final escala in [1.0, 1.3, 2.0]) {
      testWidgets('con texto a $escala ni el duelo ni la escala desbordan', (
        tester,
      ) async {
        await _enLaPregunta(tester, escala: escala);
        expect(tester.takeException(), isNull);
        Get.reset();
        await _enLaPregunta(tester, indice: 2, escala: escala);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('desde 1,3 «Me gustan las dos» y «Ninguna me llama» van una '
        'debajo de otra', (tester) async {
      await _enLaPregunta(tester, escala: 1.3);
      expect(
        tester.getTopLeft(find.text('Ninguna me llama')).dy,
        greaterThan(tester.getBottomLeft(find.text('Me gustan las dos')).dy),
      );
    });

    testWidgets('con menos movimiento no brilla la pluma ni crece la opción', (
      tester,
    ) async {
      await _enLaPregunta(tester, indice: 2, sinMovimiento: true);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(QuestionView.opcionKey('nada')));
      await tester.pump();
      expect(
        tester
            .widget<AnimatedScale>(
              find.descendant(
                of: find.byKey(QuestionView.opcionKey('nada')),
                matching: find.byType(AnimatedScale),
              ),
            )
            .scale,
        1,
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
    });
  });
}
```

- [ ] **Paso 2: Correr las pruebas y ver que fallan**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/HU36_jeff/specialty_test_preguntas_test.dart \
  test/HU36_jeff/specialty_test_conversacion_test.dart \
  test/HU36_jeff/specialty_test_accesibilidad_test.dart
```

Esperado: FALLA al compilar, sin llegar a correr ningún caso. La salida trae 46 errores distintos (líneas `Error:`), y los primeros dicen esto (las rutas pueden salir absolutas).

```text
test/HU36_jeff/specialty_test_preguntas_test.dart:18:8: Error: Error when reading 'lib/pages/specialty_test/widgets/task_icon.dart': No such file or directory
test/HU36_jeff/specialty_test_preguntas_test.dart:67:1: Error: Type 'TaskIconTile' not found.
```

- [ ] **Paso 3: Escribir la baldosa y la pregunta**

Las tarjetas son neutras hasta el toque y se encienden con el color de su especialidad en 150 ms. La escala nunca toma ese color. `_DatosDelPaso.tryDe` devuelve null cuando el paso ya no tiene pregunta ni desempate, porque al pasar a la espera o al resultado la pantalla puede reconstruirse un instante antes de que la ruta cambie de vista. Cada paso nuevo lleva el foco a su enunciado.

Crea `lib/pages/specialty_test/widgets/task_icon.dart` con este contenido.

```dart
// lib/pages/specialty_test/widgets/task_icon.dart
// La baldosa con el ícono de una tarea (RF-TEST-5 y RF-TEST-6).

import 'package:flutter/material.dart';

import '../../../configs/themes.dart';
import '../specialty_test_logic.dart';

/// La baldosa del ícono de una tarea. Sin [color] va neutra, con el fondo
/// `testTaskTileBg` y el ícono en `testTaskIconInk`, como antes del toque y
/// siempre en la escala. Con [color], el de su especialidad, se enciende.
/// El ícono sale del mapa cerrado, y un nombre desconocido cae al neutro.
/// Es decorativa, así que queda fuera del árbol de accesibilidad.
class TaskIconTile extends StatelessWidget {
  const TaskIconTile({
    super.key,
    required this.icono,
    this.color,
    this.width = 80,
    this.height = 80,
    this.iconSize = 40,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.apagada = false,
  });

  /// Nombre de Lucide que manda el contenido, o null.
  final String? icono;
  final Color? color;
  final double width;
  final double height;
  final double iconSize;
  final BorderRadius borderRadius;

  /// La otra tarjeta del duelo tras el toque, con el ícono al 50 %.
  final bool apagada;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final encendido = color;
    final fondo = encendido == null
        ? MaterialTheme.testTaskTileBg(b)
        : tinte(encendido, MaterialTheme.cardBg(b), 0.16);
    return ExcludeSemantics(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        height: height,
        decoration: BoxDecoration(color: fondo, borderRadius: borderRadius),
        alignment: Alignment.center,
        child: Opacity(
          opacity: apagada ? 0.5 : 1,
          child: Icon(
            iconoDelTest(icono),
            size: iconSize,
            color: encendido ?? MaterialTheme.testTaskIconInk(b),
          ),
        ),
      ),
    );
  }
}
```

Crea `lib/pages/specialty_test/widgets/question_view.dart` con este contenido.

```dart
// lib/pages/specialty_test/widgets/question_view.dart
// La conversación con Ulises en una pregunta (RF-TEST-4 a RF-TEST-6), con la
// barra, las plumas, el historial, el duelo, la escala y el desempate.
// Pantallas 2 y 3 de la maqueta.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../configs/themes.dart';
import '../../../models/specialty_test_models.dart';
import '../specialty_test_controller.dart';
import '../specialty_test_logic.dart';
import 'task_icon.dart';
import 'test_buttons.dart';
import 'ulises_bubble.dart';

/// Los emojis decorativos de la escala, uno por opción y en su orden.
const List<String> _emojis = <String>['😴', '🙂', '😃', '🤩'];

/// Si la escala de texto pide la versión apilada (RF-TEST-6 y RF-TEST-13).
bool _textoGrande(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(1) >= 1.3;

class QuestionView extends GetView<SpecialtyTestController> {
  const QuestionView({super.key});

  /// La tarjeta del duelo de `top` o de `bottom`.
  static Key tarjetaKey(String valor) => Key('tarjeta-$valor');

  /// Una opción de la escala por su id.
  static Key opcionKey(String id) => Key('opcion-$id');

  static const Key historialKey = Key('historial-lista');

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final sinMovimiento = MediaQuery.disableAnimationsOf(context);
    return ColoredBox(
      color: MaterialTheme.pageBg(b),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Obx(
              () => TestTopBar(
                subtitulo: subtituloDelPaso(
                  controller.contenido.value!,
                  controller.paso.value,
                ),
                onBack: controller.atras,
                onPause: controller.pausar,
              ),
            ),
            Obx(() {
              final c = controller.contenido.value!;
              final p = controller.paso.value;
              return TestFeathers(
                total: c.totalQuestions,
                actual: p < c.totalQuestions ? p : null,
                respondidas: {
                  for (var i = 0; i < c.totalQuestions; i++)
                    if (controller.respuestas.containsKey(c.questions[i].id)) i,
                },
              );
            }),
            Expanded(
              child: Obx(() {
                final datos = _DatosDelPaso.tryDe(controller);
                // Al salir de la pregunta (espera o resultado) el paso puede
                // quedar sin datos un instante, hasta que la ruta cambia de
                // pantalla.
                if (datos == null) return const SizedBox.shrink();
                return AnimatedSwitcher(
                  duration: Duration(milliseconds: sinMovimiento ? 150 : 180),
                  // La reacción y la pregunta siguiente entran juntas, y el
                  // par anterior se encoge hacia la pastilla del historial,
                  // que está arriba. Con menos movimiento, solo un fundido.
                  transitionBuilder: (hijo, animacion) {
                    final fundido = FadeTransition(
                      opacity: animacion,
                      child: hijo,
                    );
                    if (sinMovimiento) return fundido;
                    return SizeTransition(
                      sizeFactor: animacion,
                      alignment: Alignment.topCenter,
                      child: fundido,
                    );
                  },
                  child: _Paso(
                    key: ValueKey<int>(datos.paso),
                    datos: datos,
                    controller: controller,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lo que pinta un paso, leído de los Rx dentro del Obx.
class _DatosDelPaso {
  const _DatosDelPaso({
    required this.paso,
    required this.contenido,
    required this.pregunta,
    required this.desempate,
    required this.respuesta,
    required this.turno,
    required this.filasDelHistorial,
    required this.historialAbierto,
  });

  static _DatosDelPaso? tryDe(SpecialtyTestController c) {
    final contenido = c.contenido.value;
    final paso = c.paso.value;
    final respuestas = Map<String, String>.of(c.respuestas);
    final desempates = c.desempates.toList();
    final historialAbierto = c.historialAbierto.value;
    if (contenido == null) return null;
    final pregunta = c.preguntaActual;
    final desempate = c.desempateActual;
    if (pregunta == null && desempate == null) return null;
    return _DatosDelPaso(
      paso: paso,
      contenido: contenido,
      pregunta: pregunta,
      desempate: desempate,
      respuesta: c.respuestaActual,
      turno: pregunta != null
          ? turnoAntesDePregunta(contenido, paso, respuestas)
          : turnoAntesDeDesempate(desempate!),
      filasDelHistorial: historial(contenido, respuestas, desempates, paso),
      historialAbierto: historialAbierto,
    );
  }

  final int paso;
  final SpecialtyTestContent contenido;
  final TestQuestion? pregunta;
  final TiebreakRecord? desempate;
  final String? respuesta;
  final TurnoDeUlises turno;
  final List<EntradaDelHistorial> filasDelHistorial;
  final bool historialAbierto;
}

class _Paso extends StatefulWidget {
  const _Paso({super.key, required this.datos, required this.controller});

  final _DatosDelPaso datos;
  final SpecialtyTestController controller;

  @override
  State<_Paso> createState() => _PasoState();
}

class _PasoState extends State<_Paso> {
  /// El foco del lector pasa al enunciado del paso nuevo (RF-TEST-13).
  final FocusNode _enunciado = FocusNode(debugLabel: 'enunciado');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _enunciado.requestFocus();
      // El sello cae con una vibración leve (RF-TEST-6).
      if (widget.datos.turno.sello != null) HapticFeedback.lightImpact();
    });
  }

  @override
  void dispose() {
    _enunciado.dispose();
    super.dispose();
  }

  void _responder(String valor) {
    HapticFeedback.selectionClick();
    widget.controller.responder(
      valor,
      avanceSolo: !MediaQuery.accessibleNavigationOf(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.datos;
    final pregunta = d.pregunta;
    final lector = MediaQuery.accessibleNavigationOf(context);
    final esEscala = pregunta != null && !pregunta.isDuel;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (d.filasDelHistorial.isNotEmpty)
            _Historial(
              filas: d.filasDelHistorial,
              abierto: d.historialAbierto,
              onTap: widget.controller.alternarHistorial,
            ),
          UlisesTurnView(turno: d.turno),
          const SizedBox(height: 12),
          if (esEscala)
            _Escala(
              pregunta: pregunta,
              opciones: d.contenido.scaleOptions,
              respuesta: d.respuesta,
              foco: _enunciado,
              onTap: _responder,
            )
          else ...[
            _Encabezado(
              rotulo: pregunta == null ? 'Desempate' : 'Esto o aquello',
              enunciado: pregunta?.prompt ?? d.desempate!.tiebreak.prompt,
              foco: _enunciado,
            ),
            const SizedBox(height: 12),
            _Duelo(
              tareas:
                  pregunta?.tasks ??
                  [d.desempate!.tiebreak.top, d.desempate!.tiebreak.bottom],
              contenido: d.contenido,
              respuesta: d.respuesta,
              ayuda: d.contenido.ulises.duelHelp,
              onTap: _responder,
            ),
            const SizedBox(height: 14),
            _LasDosONinguna(
              contenido: d.contenido,
              respuesta: d.respuesta,
              onTap: _responder,
            ),
          ],
          if (lector && d.respuesta != null) ...[
            const SizedBox(height: 14),
            TestPrimaryButton(
              label: 'Siguiente',
              icon: LucideIcons.arrowRight,
              onPressed: widget.controller.avanzar,
            ),
          ],
        ],
      ),
    );
  }
}

/// La barra de 52 px de la conversación, con «Pregunta anterior», Ulises y
/// «Pausar el test y seguir luego». La usan la pregunta y la espera.
class TestTopBar extends StatelessWidget {
  const TestTopBar({
    super.key,
    required this.subtitulo,
    required this.onBack,
    required this.onPause,
  });

  final String subtitulo;
  final VoidCallback onBack;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final tinta = MaterialTheme.textPrimary(b);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Pregunta anterior',
              style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: onBack,
              icon: Icon(LucideIcons.chevronLeft, color: tinta, size: 22),
            ),
            Expanded(
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: SizedBox(
                      width: 38,
                      height: 38,
                      child: Stack(
                        children: [
                          const UlisesAvatar(size: 38),
                          Positioned(
                            right: -1,
                            bottom: 0,
                            child: Container(
                              width: 11,
                              height: 11,
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: MaterialTheme.pageBg(b),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ulises',
                          style: TextStyle(
                            color: tinta,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          subtitulo,
                          style: TextStyle(
                            color: MaterialTheme.testMuted(b),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Pausar el test y seguir luego',
              style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: onPause,
              icon: Icon(LucideIcons.pause, color: tinta, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

/// Una pluma por pregunta, siempre en naranja (RF-TEST-4). [actual] es null
/// en los desempates y en la espera, donde van todas llenas. Son
/// decorativas.
class TestFeathers extends StatefulWidget {
  const TestFeathers({
    super.key,
    required this.total,
    required this.actual,
    this.respondidas = const <int>{},
  });

  final int total;
  final int? actual;
  final Set<int> respondidas;

  /// Marca cada pluma para las pruebas.
  static Key plumaKey(int i) => Key('pluma-$i');

  @override
  State<TestFeathers> createState() => _TestFeathersState();
}

class _TestFeathersState extends State<TestFeathers>
    with SingleTickerProviderStateMixin {
  late final AnimationController _brillo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) || widget.actual == null) {
      _brillo.stop();
      _brillo.value = 0;
    } else if (!_brillo.isAnimating) {
      _brillo.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(TestFeathers oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.actual == null && _brillo.isAnimating) {
      _brillo.stop();
      _brillo.value = 0;
    }
  }

  @override
  void dispose() {
    _brillo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final llena = MaterialTheme.testFeatherOn(b);
    final vacia = MaterialTheme.testFeatherOff(b);
    return ExcludeSemantics(
      child: Container(
        height: 32,
        padding: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: MaterialTheme.testLine(b))),
        ),
        child: AnimatedBuilder(
          animation: _brillo,
          builder: (context, _) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.total; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Transform.rotate(
                    angle: 22 * math.pi / 180,
                    child: Icon(
                      LucideIcons.feather,
                      key: TestFeathers.plumaKey(i),
                      size: 18,
                      color:
                          widget.actual == null ||
                              i == widget.actual ||
                              widget.respondidas.contains(i)
                          ? llena
                          : vacia,
                      shadows: i == widget.actual
                          ? [
                              Shadow(
                                color: llena.withValues(
                                  alpha: 0.9 * _brillo.value,
                                ),
                                blurRadius: 5,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// La pastilla «N respuestas anteriores» y, desplegada, la lista de lo
/// respondido, sin colores de especialidad y solo para leer.
class _Historial extends StatelessWidget {
  const _Historial({
    required this.filas,
    required this.abierto,
    required this.onTap,
  });

  final List<EntradaDelHistorial> filas;
  final bool abierto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final gris = MaterialTheme.testMuted(b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Semantics(
            button: true,
            expanded: abierto,
            label: etiquetaDeLaPastilla(filas.length, desplegada: abierto),
            excludeSemantics: true,
            onTap: onTap,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(999),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Center(
                  widthFactor: 1,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(9, 5, 12, 5),
                    decoration: BoxDecoration(
                      color: MaterialTheme.testChipBg(b),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          abierto
                              ? LucideIcons.chevronUp
                              : LucideIcons.chevronDown,
                          size: 14,
                          color: gris,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            textoDeLaPastilla(filas.length),
                            style: TextStyle(
                              color: gris,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (abierto)
          Container(
            key: QuestionView.historialKey,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MaterialTheme.cardBg(b),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: MaterialTheme.testLine(b)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final f in filas)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${f.etiqueta}  ',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(text: f.respuesta),
                        ],
                      ),
                      style: TextStyle(
                        color: MaterialTheme.textPrimary(b),
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// El rótulo en mayúsculas y el enunciado, que es un encabezado y recibe el
/// foco del lector.
class _Encabezado extends StatelessWidget {
  const _Encabezado({
    required this.rotulo,
    required this.enunciado,
    required this.foco,
  });

  final String rotulo;
  final String enunciado;
  final FocusNode foco;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo.toUpperCase(),
          style: TextStyle(
            color: MaterialTheme.testAccentText(b),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.66,
          ),
        ),
        const SizedBox(height: 3),
        Focus(
          focusNode: foco,
          child: Semantics(
            header: true,
            child: Text(
              enunciado,
              style: TextStyle(
                color: MaterialTheme.textPrimary(b),
                fontSize: 17.5,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum _EstadoTarjeta { neutra, encendida, apagada }

/// Las dos tarjetas del duelo, neutras hasta el toque (RF-TEST-5).
class _Duelo extends StatelessWidget {
  const _Duelo({
    required this.tareas,
    required this.contenido,
    required this.respuesta,
    required this.ayuda,
    required this.onTap,
  });

  final List<TestTask> tareas;
  final SpecialtyTestContent contenido;
  final String? respuesta;
  final String? ayuda;
  final ValueChanged<String> onTap;

  _EstadoTarjeta _estado(String valor) {
    switch (respuesta) {
      case null:
        return _EstadoTarjeta.neutra;
      case 'both':
        return _EstadoTarjeta.encendida;
      case 'none':
        return _EstadoTarjeta.apagada;
      default:
        return respuesta == valor
            ? _EstadoTarjeta.encendida
            : _EstadoTarjeta.apagada;
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    Widget tarjeta(TestTask tarea, String valor) => _TarjetaDeTarea(
      key: QuestionView.tarjetaKey(valor),
      tarea: tarea,
      estado: _estado(valor),
      color:
          colorDeEspecialidad(contenido.specialtyByKey(tarea.specialty), b) ??
          MaterialTheme.testTaskIconInk(b),
      ayuda: ayuda,
      onTap: () => onTap(valor),
    );
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            tarjeta(tareas.first, 'top'),
            const SizedBox(height: 12),
            tarjeta(tareas.last, 'bottom'),
          ],
        ),
        ExcludeSemantics(
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: MaterialTheme.pageBg(b),
              shape: BoxShape.circle,
              border: Border.all(color: MaterialTheme.testLine(b), width: 1.5),
            ),
            child: Text(
              'o',
              style: TextStyle(
                color: MaterialTheme.testMuted(b),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TarjetaDeTarea extends StatelessWidget {
  const _TarjetaDeTarea({
    super.key,
    required this.tarea,
    required this.estado,
    required this.color,
    required this.ayuda,
    required this.onTap,
  });

  final TestTask tarea;
  final _EstadoTarjeta estado;

  /// El color de su especialidad en el tema, que solo se ve encendida.
  final Color color;
  final String? ayuda;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final encendida = estado == _EstadoTarjeta.encendida;
    final apagada = estado == _EstadoTarjeta.apagada;
    final tarjeta = MaterialTheme.cardBg(b);
    return Semantics(
      button: true,
      selected: encendida,
      label: tarea.text,
      hint: ayuda,
      excludeSemantics: true,
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: const BoxConstraints(minHeight: 104),
            decoration: BoxDecoration(
              color: encendida ? tinte(color, tarjeta, 0.12) : tarjeta,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: encendida ? color : MaterialTheme.testLine(b),
                width: 1.5,
              ),
              boxShadow: encendida
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        spreadRadius: 4,
                      ),
                    ]
                  : null,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
                  child: Row(
                    children: [
                      TaskIconTile(
                        icono: tarea.icon,
                        color: encendida ? color : null,
                        apagada: apagada,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tarea.text,
                          style: TextStyle(
                            color: apagada
                                ? MaterialTheme.testInk2(b)
                                : MaterialTheme.textPrimary(b),
                            fontSize: 14,
                            fontWeight: apagada
                                ? FontWeight.w600
                                : FontWeight.w700,
                            height: 1.32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (encendida)
            Positioned(
              top: -9,
              right: -7,
              child: ExcludeSemantics(
                // El salto de la insignia, que no ocurre con menos
                // movimiento.
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: MediaQuery.disableAnimationsOf(context) ? 1 : 0.4,
                    end: 1,
                  ),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.elasticOut,
                  builder: (context, escala, hijo) =>
                      Transform.scale(scale: escala, child: hijo),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: MaterialTheme.pageBg(b),
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      LucideIcons.check,
                      size: 13,
                      color: MaterialTheme.pageBg(b),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// «Me gustan las dos» y «Ninguna me llama», con las etiquetas de
/// `duelOptions`, en dos columnas o, desde 1,3, una debajo de otra.
class _LasDosONinguna extends StatelessWidget {
  const _LasDosONinguna({
    required this.contenido,
    required this.respuesta,
    required this.onTap,
  });

  final SpecialtyTestContent contenido;
  final String? respuesta;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    Widget boton(String id) => _BotonAlterno(
      etiqueta: contenido.optionLabel(id)!,
      elegido: respuesta == id,
      onTap: () => onTap(id),
    );
    if (_textoGrande(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [boton('both'), const SizedBox(height: 8), boton('none')],
      );
    }
    return Row(
      children: [
        Expanded(child: boton('both')),
        const SizedBox(width: 8),
        Expanded(child: boton('none')),
      ],
    );
  }
}

class _BotonAlterno extends StatelessWidget {
  const _BotonAlterno({
    required this.etiqueta,
    required this.elegido,
    required this.onTap,
  });

  final String etiqueta;
  final bool elegido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Semantics(
      button: true,
      selected: elegido,
      label: etiqueta,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: elegido
            ? MaterialTheme.testAccentSoft(b)
            : MaterialTheme.cardBg(b),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: elegido
                ? MaterialTheme.testAccent(b)
                : MaterialTheme.testLine(b),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Text(
                  etiqueta,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: elegido
                        ? MaterialTheme.testAccentDeep(b)
                        : MaterialTheme.testInk2(b),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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

/// La escala de gusto (RF-TEST-6). Nunca se enciende con el color de su
/// especialidad, porque ese color la delataría.
class _Escala extends StatelessWidget {
  const _Escala({
    required this.pregunta,
    required this.opciones,
    required this.respuesta,
    required this.foco,
    required this.onTap,
  });

  final TestQuestion pregunta;
  final List<TestOption> opciones;
  final String? respuesta;
  final FocusNode foco;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final dosPorDos =
        _textoGrande(context) || MediaQuery.sizeOf(context).width < 340;
    final botones = [
      for (var i = 0; i < opciones.length; i++)
        _OpcionDeEscala(
          key: QuestionView.opcionKey(opciones[i].id),
          emoji: _emojis[i],
          etiqueta: opciones[i].label,
          elegida: respuesta == opciones[i].id,
          onTap: () => onTap(opciones[i].id),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: MaterialTheme.cardBg(b),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: MaterialTheme.testLine(b)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TaskIconTile(
                icono: pregunta.task!.icon,
                width: double.infinity,
                height: 92,
                borderRadius: BorderRadius.zero,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESCALA DE GUSTO',
                      style: TextStyle(
                        color: MaterialTheme.testAccentText(b),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.66,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      pregunta.task!.text,
                      style: TextStyle(
                        color: MaterialTheme.textPrimary(b),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Focus(
                      focusNode: foco,
                      child: Semantics(
                        header: true,
                        child: Text(
                          pregunta.prompt,
                          style: TextStyle(
                            color: MaterialTheme.testMuted(b),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          container: true,
          explicitChildNodes: true,
          label: pregunta.prompt,
          child: dosPorDos
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FilaDeOpciones(opciones: botones.sublist(0, 2)),
                    const SizedBox(height: 6),
                    _FilaDeOpciones(opciones: botones.sublist(2)),
                  ],
                )
              : _FilaDeOpciones(opciones: botones),
        ),
      ],
    );
  }
}

/// Una fila de opciones del mismo alto, aunque una etiqueta ocupe dos
/// líneas.
class _FilaDeOpciones extends StatelessWidget {
  const _FilaDeOpciones({required this.opciones});

  final List<Widget> opciones;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < opciones.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(child: opciones[i]),
          ],
        ],
      ),
    );
  }
}

class _OpcionDeEscala extends StatelessWidget {
  const _OpcionDeEscala({
    super.key,
    required this.emoji,
    required this.etiqueta,
    required this.elegida,
    required this.onTap,
  });

  final String emoji;
  final String etiqueta;
  final bool elegida;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final sinMovimiento = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      checked: elegida,
      label: etiqueta,
      excludeSemantics: true,
      onTap: onTap,
      child: AnimatedScale(
        scale: elegida && !sinMovimiento ? 1.08 : 1,
        duration: const Duration(milliseconds: 150),
        child: Material(
          color: elegida
              ? MaterialTheme.testAccentSoft(b)
              : MaterialTheme.cardBg(b),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(
              color: elegida
                  ? MaterialTheme.testAccent(b)
                  : MaterialTheme.testLine(b),
              width: elegida ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(15),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ExcludeSemantics(
                      child: Text(emoji, style: const TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      etiqueta,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: elegida
                            ? MaterialTheme.testAccentDeep(b)
                            : MaterialTheme.testInk2(b),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                  ],
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

- [ ] **Paso 4: Correr las pruebas y ver que pasan**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/HU36_jeff/specialty_test_preguntas_test.dart \
  test/HU36_jeff/specialty_test_conversacion_test.dart \
  test/HU36_jeff/specialty_test_accesibilidad_test.dart
```

Esperado: PASS, `+45: All tests passed!`.

- [ ] **Paso 5: Dar formato y analizar**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/pages/specialty_test/widgets/task_icon.dart \
  lib/pages/specialty_test/widgets/question_view.dart \
  test/HU36_jeff/specialty_test_preguntas_test.dart \
  test/HU36_jeff/specialty_test_conversacion_test.dart \
  test/HU36_jeff/specialty_test_accesibilidad_test.dart
```

Esperado: `Formatted 5 files (0 changed)`.

```bash
cd "${REPO:?}"
"${FLUTTER:?}" analyze --no-pub
```

Esperado: `6 issues found.`, los 6 de la línea base y ninguno en un archivo de esta tarea.

- [ ] **Paso 6: Commit**

```bash
cd "${REPO:?}"
test "$(git branch --show-current)" = feat/test-especialidad-fe || echo 'PARAR: rama equivocada'
git status --short
git add lib/pages/specialty_test/widgets/task_icon.dart \
  lib/pages/specialty_test/widgets/question_view.dart \
  test/HU36_jeff/specialty_test_preguntas_test.dart \
  test/HU36_jeff/specialty_test_conversacion_test.dart \
  test/HU36_jeff/specialty_test_accesibilidad_test.dart
git commit -m 'feat(specialty-test): la conversación pinta el duelo, la escala y el desempate con la barra, las plumas y el historial (RF-TEST-4 a RF-TEST-6)'
git log -1 --format='%an <%ae>'
git log -1 --format=%B | grep -qi '^co-authored-by:' && echo 'PARAR: el commit trae trailer'
```

Esperado: ningún `PARAR`. Antes del `git add`, `git status --short` lista solo los archivos de la tarea, y el autor es `Jeffangeloss <178797184+jeffangeloss@users.noreply.github.com>`.

---

### Tarea 13: La espera en pantalla

**Requisitos:** RF-TEST-7 (espera en la conversación, cierre de bloque, indicador) y la fila de la espera sin conexión de RF-TEST-11, con su parte de RF-TEST-13.

**Archivos:**
- Crear `lib/pages/specialty_test/widgets/waiting_view.dart`
- Modificar `test/HU36_jeff/specialty_test_evaluacion_test.dart` (imports, grupo `_pantalla`)
- Modificar `test/HU36_jeff/specialty_test_accesibilidad_test.dart` (imports, grupo `_espera`)

**Interfaces:**

- Consume `errorDeEspera`, `textoDelErrorDeEspera`, `reintentarEvaluacion`,
  `esperaTrasDesempate` (Tarea 9), `turnoDeEspera` (Tarea 4), `TestTopBar` y
  `TestFeathers` (Tarea 12) y `TestErrorMessage` (Tarea 11).
- Produce `class WaitingView extends StatefulWidget`, que la ruta muestra en
  la fase `espera`.

- [ ] **Paso 1: Escribir las pruebas que fallan**

En `test/HU36_jeff/specialty_test_evaluacion_test.dart`, cambia este bloque, que aparece una sola vez,

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';
```

por este otro.

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/question_view.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/ulises_bubble.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/waiting_view.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';
import 'montaje_de_pantallas.dart';
```

En `test/HU36_jeff/specialty_test_evaluacion_test.dart`, cambia este bloque, que aparece una sola vez,

```dart
  _controlador();
}
```

por este otro.

```dart
  _controlador();
  _pantalla();
}
```

Agrega al final de `test/HU36_jeff/specialty_test_evaluacion_test.dart`, tras una línea en blanco, este bloque.

```dart
/// Llega a la espera con la evaluación pendiente de [evaluacion] y monta la
/// pantalla.
Future<SpecialtyTestController> _enLaEspera(
  WidgetTester tester,
  List<Object> evaluaciones, {
  bool sinMovimiento = false,
}) async {
  prepararTest(ApiFalsaDelTest(evaluaciones: evaluaciones));
  final c = ponerControlador();
  await tester.pump();
  c.empezar();
  responderPasos(c, respuestasEnOrden);
  await montarPantalla(
    tester,
    const WaitingView(),
    sinMovimiento: sinMovimiento,
  );
  return c;
}

List<String> _burbujas(WidgetTester tester) => tester
    .widgetList<UlisesBubble>(find.byType(UlisesBubble))
    .map((b) => b.text)
    .toList();

void _pantalla() {
  group('WIDGET · La espera (RF-TEST-7)', () {
    testWidgets('caso 9: con las plumas llenas, el cierre de la última, su '
        'sello, la línea de espera y el indicador', (tester) async {
      final pendiente = Completer<Map<String, dynamic>>();
      await _enLaEspera(tester, [pendiente]);
      expect(find.text('Pregunta 5 de 5'), findsOneWidget);
      for (var i = 0; i < 5; i++) {
        expect(
          tester.widget<Icon>(find.byKey(TestFeathers.plumaKey(i))).color,
          MaterialTheme.testFeatherOn(Brightness.light),
        );
      }
      expect(_burbujas(tester), ['Cierre de prueba del bloque dos.', kLoading]);
      expect(find.text('Cierra el bloque 2 de 2'), findsOneWidget);
      final indicador = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicador.color, MaterialTheme.testAccent(Brightness.light));
      pendiente.complete(resultadoJson());
      await tester.pump();
    });

    testWidgets('caso 10: tras un desempate va solo la línea de espera', (
      tester,
    ) async {
      final pendiente = Completer<Map<String, dynamic>>();
      final c = await _enLaEspera(tester, [desempateJson(), pendiente]);
      await tester.pump();
      responderPasos(c, ['top']);
      await tester.pump();
      expect(find.text('Desempate 1'), findsOneWidget);
      expect(_burbujas(tester), [kLoading]);
      pendiente.complete(resultadoJson());
      await tester.pump();
    });

    testWidgets('caso 11: sin conexión, el aviso y «Reintentar» en lugar de '
        'la línea de espera', (tester) async {
      final c = await _enLaEspera(tester, [
        http.ClientException('sin red'),
        resultadoJson(),
      ]);
      await tester.pump();
      expect(
        find.text(
          'No pudimos conectarnos. Revisa tu conexión e inténtalo de nuevo.',
        ),
        findsOneWidget,
      );
      expect(_burbujas(tester), ['Cierre de prueba del bloque dos.']);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      expect(c.fase.value, FaseDelTest.resultado);
    });

    testWidgets('caso 12: con menos movimiento el indicador no aparece y la '
        'burbuja sola dice que se espera', (tester) async {
      final pendiente = Completer<Map<String, dynamic>>();
      await _enLaEspera(tester, [pendiente], sinMovimiento: true);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text(kLoading), findsOneWidget);
      pendiente.complete(resultadoJson());
      await tester.pump();
    });
  });
}
```

En `test/HU36_jeff/specialty_test_accesibilidad_test.dart`, cambia este bloque, que aparece una sola vez,

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/question_view.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/test_buttons.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/ulises_bubble.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/welcome_view.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';
import 'montaje_de_pantallas.dart';
```

por este otro.

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/question_view.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/test_buttons.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/ulises_bubble.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/waiting_view.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/welcome_view.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';
import 'montaje_de_pantallas.dart';
```

En `test/HU36_jeff/specialty_test_accesibilidad_test.dart`, cambia este bloque, que aparece una sola vez,

```dart
  _preguntas();
}
```

por este otro.

```dart
  _preguntas();
  _espera();
}
```

Agrega al final de `test/HU36_jeff/specialty_test_accesibilidad_test.dart`, tras una línea en blanco, este bloque.

```dart
void _espera() {
  group('WIDGET · Accesibilidad de la espera (RF-TEST-13)', () {
    for (final escala in [1.0, 1.3, 2.0]) {
      testWidgets('con texto a $escala no desborda, y el foco y la región viva '
          'quedan en la burbuja', (tester) async {
        final semantica = tester.ensureSemantics();
        final pendiente = Completer<Map<String, dynamic>>();
        prepararTest(ApiFalsaDelTest(evaluaciones: [pendiente]));
        final c = ponerControlador();
        await tester.pump();
        c.empezar();
        responderPasos(c, respuestasEnOrden);
        await montarPantalla(tester, const WaitingView(), escala: escala);
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(
          Focus.of(tester.element(find.text(kLoading))).hasPrimaryFocus,
          isTrue,
        );
        expect(
          tester.getSemantics(find.byType(UlisesTurnView)),
          isSemantics(isLiveRegion: true),
        );
        pendiente.complete(resultadoJson());
        await tester.pump();
        semantica.dispose();
      });
    }
  });
}
```

- [ ] **Paso 2: Correr las pruebas y ver que fallan**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/HU36_jeff/specialty_test_evaluacion_test.dart \
  test/HU36_jeff/specialty_test_accesibilidad_test.dart
```

Esperado: FALLA al compilar, sin llegar a correr ningún caso. La salida trae 5 errores distintos (líneas `Error:`), y los primeros dicen esto (las rutas pueden salir absolutas).

```text
test/HU36_jeff/specialty_test_evaluacion_test.dart:236:11: Error: Couldn't find constructor 'WaitingView'.
test/HU36_jeff/specialty_test_accesibilidad_test.dart:336:44: Error: Couldn't find constructor 'WaitingView'.
```

- [ ] **Paso 3: Escribir la espera**

Con error, el aviso ocupa el lugar de la línea de espera y el `blockClose` de la última pregunta se queda. Con menos movimiento el indicador no aparece y la burbuja sola dice que se espera.

Crea `lib/pages/specialty_test/widgets/waiting_view.dart` con este contenido.

```dart
// lib/pages/specialty_test/widgets/waiting_view.dart
// La espera de la evaluación y su error (RF-TEST-7 y RF-TEST-11).

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../configs/themes.dart';
import '../specialty_test_controller.dart';
import '../specialty_test_logic.dart';
import 'question_view.dart';
import 'test_buttons.dart';
import 'ulises_bubble.dart';

/// La espera se queda en la conversación, con la barra y las plumas llenas.
/// Durante la espera nada responde salvo «Pregunta anterior», la pausa y
/// «Reintentar».
class WaitingView extends StatefulWidget {
  const WaitingView({super.key});

  @override
  State<WaitingView> createState() => _WaitingViewState();
}

class _WaitingViewState extends State<WaitingView> {
  /// En la espera, el foco del lector queda en la burbuja (RF-TEST-13).
  final FocusNode _burbuja = FocusNode(debugLabel: 'espera');

  SpecialtyTestController get _c => Get.find<SpecialtyTestController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _burbuja.requestFocus();
    });
  }

  @override
  void dispose() {
    _burbuja.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final sinMovimiento = MediaQuery.disableAnimationsOf(context);
    return ColoredBox(
      color: MaterialTheme.pageBg(b),
      child: SafeArea(
        bottom: false,
        child: Obx(() {
          final c = _c.contenido.value;
          if (c == null) return const SizedBox.shrink();
          final error = _c.errorDeEspera.value;
          final completo = turnoDeEspera(
            c,
            trasDesempate: _c.esperaTrasDesempate,
          );
          // Con error, el aviso ocupa el lugar de la línea de espera.
          final turno = error == null
              ? completo
              : TurnoDeUlises(
                  completo.lineas.where((l) => l != c.ulises.loading).toList(),
                  sello: completo.sello,
                );
          return Column(
            children: [
              TestTopBar(
                subtitulo: subtituloDelPaso(c, _c.paso.value),
                onBack: _c.atras,
                onPause: _c.pausar,
              ),
              TestFeathers(total: c.totalQuestions, actual: null),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (turno.lineas.isNotEmpty)
                        UlisesTurnView(turno: turno, focusNode: _burbuja),
                      const SizedBox(height: 12),
                      if (error != null)
                        TestErrorMessage(
                          text: _c.textoDelErrorDeEspera,
                          onRetry: _c.reintentarEvaluacion,
                        )
                      else if (!sinMovimiento)
                        Padding(
                          padding: const EdgeInsets.only(left: 35),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: MaterialTheme.testAccent(b),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
```

- [ ] **Paso 4: Correr las pruebas y ver que pasan**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/HU36_jeff/specialty_test_evaluacion_test.dart \
  test/HU36_jeff/specialty_test_accesibilidad_test.dart
```

Esperado: PASS, `+33: All tests passed!`.

- [ ] **Paso 5: Dar formato y analizar**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/pages/specialty_test/widgets/waiting_view.dart \
  test/HU36_jeff/specialty_test_evaluacion_test.dart \
  test/HU36_jeff/specialty_test_accesibilidad_test.dart
```

Esperado: `Formatted 3 files (0 changed)`.

```bash
cd "${REPO:?}"
"${FLUTTER:?}" analyze --no-pub
```

Esperado: `6 issues found.`, los 6 de la línea base y ninguno en un archivo de esta tarea.

- [ ] **Paso 6: Commit**

```bash
cd "${REPO:?}"
test "$(git branch --show-current)" = feat/test-especialidad-fe || echo 'PARAR: rama equivocada'
git status --short
git add lib/pages/specialty_test/widgets/waiting_view.dart \
  test/HU36_jeff/specialty_test_evaluacion_test.dart \
  test/HU36_jeff/specialty_test_accesibilidad_test.dart
git commit -m 'feat(specialty-test): la espera se queda en la conversación con su línea, su sello y su error (RF-TEST-7 y RF-TEST-11)'
git log -1 --format='%an <%ae>'
git log -1 --format=%B | grep -qi '^co-authored-by:' && echo 'PARAR: el commit trae trailer'
```

Esperado: ningún `PARAR`. Antes del `git add`, `git status --short` lista solo los archivos de la tarea, y el autor es `Jeffangeloss <178797184+jeffangeloss@users.noreply.github.com>`.

---

### Tarea 14: El resultado en pantalla

**Requisitos:** RF-TEST-8 entero, la parte visual de RF-TEST-9 (corazones, «Ya es tu principal», hoja del empate) y su parte de RF-TEST-13.

**Archivos:**
- Crear `lib/pages/specialty_test/widgets/electives_sheet.dart` y `lib/pages/specialty_test/widgets/result_view.dart`
- Crear `test/HU36_jeff/specialty_test_resultado_test.dart`
- Modificar `test/HU36_jeff/specialty_test_eleccion_test.dart` (imports, grupo `_pantalla`)
- Modificar `test/HU36_jeff/specialty_test_accesibilidad_test.dart` (imports, grupo `_resultado`)

**Interfaces:**

- Consume `resultado`, `corazones`, `guardando`, `botonesActivos`,
  `yaEsPrincipal`, `principalActual`, `elegirPrincipal`, `alternarCorazon`,
  `decidirDespues` y `rehacer` (Tareas 9 y 10), `tinte`, `oscurecido`,
  `colorQueSeLee`, `colorDeEspecialidad`, `iconoDelTest` (Tareas 2 y 3) y
  los widgets de la Tarea 11.
- Produce lo que sigue.

```dart
// widgets/electives_sheet.dart
Future<void> mostrarElectivos(BuildContext context,
  List<TestSpecialty> especialidades);
class ElectivesSheet { const ElectivesSheet({required List<TestSpecialty>
  especialidades}); }
// widgets/result_view.dart
class ResultView extends StatefulWidget { static const Key tarjetaKey,
  cuerpoKey, confetiKey; static Key filaKey(int specialtyId);
  static Key corazonKey(int specialtyId); }
```

- [ ] **Paso 1: Escribir las pruebas que fallan**

El caso 6 mide con Roboto que a 375 × 667 y con la escala en 1,0 el cuerpo del medio no tiene nada que desplazar, en claro y en oscuro. El caso 10 atrapa la vibración fuerte en el canal `SystemChannels.platform`.

Crea `test/HU36_jeff/specialty_test_resultado_test.dart` con este contenido.

```dart
// test/HU36_jeff/specialty_test_resultado_test.dart
//
// Pruebas de widget de HU36, el test de especialidad, sobre el resultado
// (RF-TEST-8).
// Pantalla: lib/pages/specialty_test/widgets/result_view.dart
//
// Datos inventados (datos_de_prueba.dart). El alumno de prueba es 20230001.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_logic.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/result_view.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/ulises_bubble.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';
import 'montaje_de_pantallas.dart';

const Color _vjClaro = Color(0xFF76164A);
const Color _vjOscuro = Color(0xFFEC7FB3);

/// Llega al resultado de [evaluacion] y monta la pantalla. Deja pasar la
/// entrada (600 ms) y el confeti (1200 ms).
Future<SpecialtyTestController> _enElResultado(
  WidgetTester tester, {
  Map<String, dynamic>? evaluacion,
  UserModel? usuario,
  Brightness brillo = Brightness.light,
  bool sinMovimiento = false,
  bool esperarEntrada = true,
}) async {
  prepararTest(
    ApiFalsaDelTest(evaluaciones: [evaluacion ?? resultadoJson()]),
    usuario: usuario,
  );
  final c = ponerControlador();
  await tester.pump();
  c.empezar();
  responderPasos(c, respuestasEnOrden);
  await tester.pump();
  expect(c.fase.value, FaseDelTest.resultado);
  await montarPantalla(
    tester,
    const ResultView(),
    brillo: brillo,
    sinMovimiento: sinMovimiento,
  );
  if (esperarEntrada) await tester.pump(const Duration(milliseconds: 1300));
  return c;
}

double _arriba(WidgetTester tester, Finder f) => tester.getTopLeft(f).dy;

void main() {
  // Get.put de un GetxService agenda onReady con
  // Get.engine.addPostFrameCallback, que necesita el binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(cargarRoboto);
  setUp(Get.reset);
  tearDown(Get.reset);

  _resultado();
}

void _resultado() {
  group('WIDGET · El resultado (RF-TEST-8)', () {
    testWidgets('caso 1: las piezas van en orden, de Ulises a los botones', (
      tester,
    ) async {
      await _enElResultado(tester);
      final orden = [
        find.byType(UlisesBubble),
        find.byKey(ResultView.tarjetaKey),
        find.text('2 electivos'),
        find.text('También te puede interesar'),
        find.byKey(ResultView.filaKey(kIdSi)),
        find.byKey(ResultView.filaKey(kIdTi)),
        find.byKey(ResultView.filaKey(kIdSw)),
        find.text('Elegir como principal'),
        find.text('Decidir después'),
      ];
      final alturas = [for (final f in orden) _arriba(tester, f)];
      expect(alturas, [...alturas]..sort());
      expect(find.text('Rehacer el test'), findsOneWidget);
      expect(find.text('Tu n.º 1'), findsOneWidget);
      expect(find.text('75 % afinidad'), findsOneWidget);
      expect(find.text('Desarrollo de Videojuegos'), findsOneWidget);
      expect(find.text('65 %'), findsOneWidget);
    });

    testWidgets('caso 2: la burbuja lleva headline y tiebreakOutcome tal cual '
        'y nunca intro, closing ni retake', (tester) async {
      await _enElResultado(
        tester,
        evaluacion: resultadoJson(
          headline:
              'Esta vez ninguna despegó del todo. Por ahora, '
              'Desarrollo de Videojuegos va adelante, con 45 %.',
          tiebreakOutcome: 'Ahí está, ya se inclinó la balanza.',
        ),
      );
      expect(
        tester.widget<UlisesBubble>(find.byType(UlisesBubble)).text,
        'Esta vez ninguna despegó del todo. Por ahora, Desarrollo de '
        'Videojuegos va adelante, con 45 %. Ahí está, ya se inclinó la '
        'balanza.',
      );
      expect(find.textContaining('Ya tengo tu resultado'), findsNothing);
      expect(find.textContaining('que la app no pinta'), findsNothing);
    });

    testWidgets('caso 3: la insignia «IA» sale solo con reasonSource "ai"', (
      tester,
    ) async {
      await _enElResultado(tester);
      expect(find.text('IA'), findsNothing);
      Get.reset();
      await _enElResultado(
        tester,
        evaluacion: resultadoJson(reasonSource: 'ai'),
      );
      expect(find.text('IA'), findsOneWidget);
    });

    testWidgets('caso 4: el motivo se corta en cuatro líneas y «Leer más» lo '
        'despliega', (tester) async {
      await _enElResultado(tester);
      Text motivo() => tester.widget<Text>(
        find.byWidgetPredicate(
          (w) => w is Text && w.textSpan?.toPlainText() == kMotivoLargo,
        ),
      );
      expect(motivo().maxLines, 4);
      await tester.tap(find.text('Leer más'));
      await tester.pump();
      expect(motivo().maxLines, isNull);
      await tester.tap(find.text('Leer menos'));
      await tester.pump();
      expect(motivo().maxLines, 4);
    });

    testWidgets('caso 5: con empate, «Empate», los dos nombres, una pastilla '
        'y las filas desde el puesto 3', (tester) async {
      await _enElResultado(tester, evaluacion: resultadoJson(empate: true));
      expect(find.text('Empate'), findsOneWidget);
      expect(find.text('Sistemas de Información'), findsOneWidget);
      expect(find.text('Desarrollo de Videojuegos'), findsOneWidget);
      expect(find.textContaining('% afinidad'), findsOneWidget);
      expect(find.text('Electivos de las dos'), findsOneWidget);
      expect(find.byKey(ResultView.filaKey(kIdSi)), findsNothing);
      expect(find.byKey(ResultView.filaKey(kIdTi)), findsOneWidget);
      expect(find.byKey(ResultView.corazonKey(kIdVj)), findsNothing);
    });

    for (final brillo in Brightness.values) {
      testWidgets('caso 6: a 375 × 667 con 1,0 todo cabe sin desplazar en '
          '${brillo.name}', (tester) async {
        await _enElResultado(tester, brillo: brillo);
        final cuerpo = tester.state<ScrollableState>(
          find.descendant(
            of: find.byKey(ResultView.cuerpoKey),
            matching: find.byType(Scrollable),
          ),
        );
        expect(cuerpo.position.maxScrollExtent, 0);
        expect(
          dentroDeLaPantalla(tester, find.text('Rehacer el test')),
          isTrue,
        );
      });
    }

    testWidgets('caso 7: la hoja de electivos trae el título, la frase y cada '
        'electivo', (tester) async {
      await _enElResultado(tester);
      await tester.tap(find.text('Ver'));
      await tester.pumpAndSettle();
      expect(
        find.text('Electivos de Desarrollo de Videojuegos'),
        findsOneWidget,
      );
      expect(
        find.text('Frase de prueba de Desarrollo de Videojuegos.'),
        findsOneWidget,
      );
      expect(find.text('Electivo G'), findsWidgets);
      expect(find.text('900401 · 3 créditos'), findsOneWidget);
      expect(find.text('Haber culminado el V ciclo'), findsNWidgets(2));
    });

    testWidgets('caso 8: la principal actual lleva la estrella con «Tu '
        'principal» y no tiene corazón', (tester) async {
      await _enElResultado(tester, usuario: alumno(principal: kIdSi));
      expect(find.text('Tu principal'), findsOneWidget);
      expect(find.byKey(ResultView.corazonKey(kIdSi)), findsNothing);
      expect(
        colorDeTexto(tester, 'Tu principal'),
        MaterialTheme.testAccentText(Brightness.light),
      );
    });

    testWidgets('caso 9: en claro la tarjeta es un degradado del color y en '
        'oscuro el color al 18 % con el título en color', (tester) async {
      await _enElResultado(tester);
      BoxDecoration deco() =>
          tester
                  .widget<Container>(find.byKey(ResultView.tarjetaKey))
                  .decoration!
              as BoxDecoration;
      expect((deco().gradient! as LinearGradient).colors, [
        _vjClaro,
        oscurecido(_vjClaro),
      ]);
      expect(colorDeTexto(tester, 'Tu n.º 1'), Colors.white);
      Get.reset();
      await _enElResultado(tester, brillo: Brightness.dark);
      const b = Brightness.dark;
      expect(deco().color, tinte(_vjOscuro, MaterialTheme.cardBg(b), 0.18));
      expect(colorDeTexto(tester, 'Desarrollo de Videojuegos'), _vjOscuro);
      expect(colorDeTexto(tester, 'Tu n.º 1'), MaterialTheme.textPrimary(b));
    });

    testWidgets('caso 10: al entrar hay confeti y una vibración fuerte, y la '
        'afinidad cuenta hasta su valor', (tester) async {
      final vibraciones = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (llamada) async {
          if (llamada.method == 'HapticFeedback.vibrate') {
            vibraciones.add(llamada.arguments);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await _enElResultado(tester, esperarEntrada: false);
      expect(find.byKey(ResultView.confetiKey), findsOneWidget);
      expect(vibraciones, contains('HapticFeedbackType.heavyImpact'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('75 % afinidad'), findsNothing);
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.text('75 % afinidad'), findsOneWidget);
    });
  });
}
```

En `test/HU36_jeff/specialty_test_eleccion_test.dart`, cambia este bloque, que aparece una sola vez,

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_logic.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';
```

por este otro.

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_logic.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/result_view.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';
import 'montaje_de_pantallas.dart';
```

En `test/HU36_jeff/specialty_test_eleccion_test.dart`, cambia este bloque, que aparece una sola vez,

```dart
  _controlador();
}
```

por este otro.

```dart
  _controlador();
  _pantalla();
}
```

Agrega al final de `test/HU36_jeff/specialty_test_eleccion_test.dart`, tras una línea en blanco, este bloque.

```dart
/// Monta el resultado con [usuario] y sin animaciones de entrada.
Future<({SpecialtyTestController c, AuthDelControlador auth})>
_pantallaDelResultado(
  WidgetTester tester, {
  UserModel? usuario,
  Map<String, dynamic>? evaluacion,
}) async {
  final t = prepararTest(
    ApiFalsaDelTest(evaluaciones: [evaluacion ?? resultadoJson()]),
    usuario: usuario,
  );
  final c = ponerControlador();
  await tester.pump();
  c.empezar();
  responderPasos(c, respuestasEnOrden);
  await tester.pump();
  await montarPantalla(tester, const ResultView(), sinMovimiento: true);
  return (c: c, auth: t.auth);
}

void _pantalla() {
  group('WIDGET · Elegir y corazones en el resultado (RF-TEST-9)', () {
    testWidgets('caso 15: los corazones marcados son los intereses y el '
        'toque guarda', (tester) async {
      final r = await _pantallaDelResultado(
        tester,
        usuario: alumno(intereses: [kIdTi]),
      );
      Icon corazon(int id) => tester.widget<Icon>(
        find.descendant(
          of: find.byKey(ResultView.corazonKey(id)),
          matching: find.byType(Icon),
        ),
      );
      expect(corazon(kIdTi).icon, Icons.favorite_rounded);
      expect(corazon(kIdSi).icon, isNot(Icons.favorite_rounded));
      await tester.tap(find.byKey(ResultView.corazonKey(kIdSi)));
      await tester.pump();
      expect(corazon(kIdSi).icon, Icons.favorite_rounded);
      expect(
        r.auth.guardados.single,
        const SeleccionDeEspecialidades(intereses: [kIdSi, kIdTi]),
      );
    });

    testWidgets('caso 16: si la ganadora ya es la principal, el botón dice '
        '«Ya es tu principal» y no guarda', (tester) async {
      final r = await _pantallaDelResultado(
        tester,
        usuario: alumno(principal: kIdVj),
      );
      expect(find.text('Elegir como principal'), findsNothing);
      await tester.tap(find.text('Ya es tu principal'));
      await tester.pump();
      expect(r.auth.guardados, isEmpty);
    });

    testWidgets('caso 17: con empate, la hoja pregunta cuál y «Cancelar» no '
        'guarda', (tester) async {
      final r = await _pantallaDelResultado(
        tester,
        evaluacion: resultadoJson(empate: true),
      );
      await tester.tap(find.text('Elegir como principal'));
      await tester.pumpAndSettle();
      expect(find.text('¿Cuál eliges como principal?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(r.auth.guardados, isEmpty);
      await tester.tap(find.text('Elegir como principal'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Desarrollo de Videojuegos'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        r.auth.guardados.single,
        const SeleccionDeEspecialidades(principal: kIdVj, intereses: [kIdSi]),
      );
    });

    testWidgets('caso 18: mientras un guardado está en vuelo los botones no '
        'responden', (tester) async {
      final r = await _pantallaDelResultado(tester);
      final pendiente = Completer<void>();
      r.auth.respuestasDeGuardado.add(pendiente);
      await tester.tap(find.byKey(ResultView.corazonKey(kIdSi)));
      await tester.pump();
      await tester.tap(find.text('Decidir después'));
      await tester.tap(find.text('Rehacer el test'));
      await tester.pump();
      expect(r.auth.guardados, hasLength(1));
      expect(r.c.fase.value, FaseDelTest.resultado);
      pendiente.complete();
      await tester.pump();
      await tester.tap(find.text('Rehacer el test'));
      await tester.pump();
      expect(r.c.fase.value, FaseDelTest.pregunta);
    });
  });
}
```

En `test/HU36_jeff/specialty_test_accesibilidad_test.dart`, cambia este bloque, que aparece una sola vez,

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/question_view.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/test_buttons.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/ulises_bubble.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/waiting_view.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/welcome_view.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';
import 'montaje_de_pantallas.dart';
```

por este otro.

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/question_view.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/result_view.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/test_buttons.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/ulises_bubble.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/waiting_view.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/welcome_view.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';
import 'montaje_de_pantallas.dart';
```

En `test/HU36_jeff/specialty_test_accesibilidad_test.dart`, cambia este bloque, que aparece una sola vez,

```dart
  _espera();
}
```

por este otro.

```dart
  _espera();
  _resultado();
}
```

Agrega al final de `test/HU36_jeff/specialty_test_accesibilidad_test.dart`, tras una línea en blanco, este bloque.

```dart
/// Llega al resultado de [evaluacion] y monta la pantalla.
Future<SpecialtyTestController> _enElResultado(
  WidgetTester tester, {
  Map<String, dynamic>? evaluacion,
  double escala = 1.0,
  bool sinMovimiento = true,
}) async {
  prepararTest(ApiFalsaDelTest(evaluaciones: [evaluacion ?? resultadoJson()]));
  final c = ponerControlador();
  await tester.pump();
  c.empezar();
  responderPasos(c, respuestasEnOrden);
  await tester.pump();
  await montarPantalla(
    tester,
    const ResultView(),
    escala: escala,
    sinMovimiento: sinMovimiento,
  );
  await tester.pump();
  return c;
}

void _resultado() {
  group('WIDGET · Accesibilidad del resultado (RF-TEST-13)', () {
    testWidgets('la tarjeta es un nodo con la número uno, su afinidad y el '
        'motivo con la insignia «IA»', (tester) async {
      final semantica = tester.ensureSemantics();
      await _enElResultado(
        tester,
        evaluacion: resultadoJson(reasonSource: 'ai'),
      );
      expect(
        find.bySemanticsLabel(
          'Tu n.º 1, Desarrollo de Videojuegos, 75 % de afinidad',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Motivo redactado con IA. $kMotivoLargo'),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(find.text('Leer más')),
        isSemantics(isButton: true),
      );
      semantica.dispose();
    });

    testWidgets('con empate la tarjeta nombra las dos', (tester) async {
      final semantica = tester.ensureSemantics();
      await _enElResultado(tester, evaluacion: resultadoJson(empate: true));
      expect(
        find.bySemanticsLabel(
          'Empate, Sistemas de Información y Desarrollo de Videojuegos, 62 % '
          'de afinidad',
        ),
        findsOneWidget,
      );
      semantica.dispose();
    });

    testWidgets('cada fila se lee con su puesto y el corazón es un botón con '
        'toggled', (tester) async {
      final semantica = tester.ensureSemantics();
      await _enElResultado(tester);
      expect(
        find.bySemanticsLabel(
          'Puesto 2, Sistemas de Información, 65 % de afinidad',
        ),
        findsOneWidget,
      );
      final corazon = find.byKey(ResultView.corazonKey(kIdSi));
      expect(
        tester.getSemantics(corazon),
        isSemantics(
          label: 'Marcar Sistemas de Información como interés',
          isButton: true,
          isToggled: false,
        ),
      );
      await tester.tap(corazon);
      await tester.pump();
      expect(
        tester.getSemantics(corazon),
        isSemantics(
          label: 'Quitar Sistemas de Información de tus intereses',
          isToggled: true,
        ),
      );
      semantica.dispose();
    });

    testWidgets('al abrir el resultado el foco pasa a la burbuja de Ulises', (
      tester,
    ) async {
      await _enElResultado(tester);
      expect(
        Focus.of(
          tester.element(
            find.text(
              'Lo tuyo apunta a Desarrollo de Videojuegos, con 75 % de '
              'afinidad.',
            ),
          ),
        ).hasPrimaryFocus,
        isTrue,
      );
    });

    testWidgets('con menos movimiento no hay confeti ni giro y la afinidad '
        'sale con su valor final', (tester) async {
      await _enElResultado(tester);
      expect(find.byKey(ResultView.confetiKey), findsNothing);
      expect(find.text('75 % afinidad'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    for (final escala in [1.0, 1.3, 2.0]) {
      testWidgets('con texto a $escala no desborda y los botones siguen '
          'abajo', (tester) async {
        await _enElResultado(tester, escala: escala);
        expect(tester.takeException(), isNull);
        expect(
          dentroDeLaPantalla(tester, find.text('Rehacer el test')),
          isTrue,
        );
        _blancosTactiles(tester);
      });
    }
  });
}
```

- [ ] **Paso 2: Correr las pruebas y ver que fallan**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/HU36_jeff/specialty_test_resultado_test.dart \
  test/HU36_jeff/specialty_test_eleccion_test.dart \
  test/HU36_jeff/specialty_test_accesibilidad_test.dart
```

Esperado: FALLA al compilar, sin llegar a correr ningún caso. La salida trae 23 errores distintos (líneas `Error:`), y los primeros dicen esto (las rutas pueden salir absolutas).

```text
test/HU36_jeff/specialty_test_resultado_test.dart:50:11: Error: Couldn't find constructor 'ResultView'.
test/HU36_jeff/specialty_test_resultado_test.dart:80:20: Error: Undefined name 'ResultView'.
```

- [ ] **Paso 3: Escribir la hoja de electivos y el resultado**

La tarjeta de la número uno toma el color de la ganadora. En claro va en degradado con texto blanco, o en tinta si el blanco no llega a 4,5:1 sobre ese color. En oscuro va al 18 % sobre `cardBg` con el título en el color (decisión abierta 22). El motivo se mide sin la insignia para decidir si hace falta «Leer más». La hoja del empate devuelve el `specialtyId` elegido o null con «Cancelar».

Crea `lib/pages/specialty_test/widgets/electives_sheet.dart` con este contenido.

```dart
// lib/pages/specialty_test/widgets/electives_sheet.dart
// La hoja de electivos del resultado (RF-TEST-8). Con empate trae una
// sección por especialidad.

import 'package:flutter/material.dart';

import '../../../configs/themes.dart';
import '../../../models/specialty_test_models.dart';

/// Abre la hoja con los electivos de [especialidades].
Future<void> mostrarElectivos(
  BuildContext context,
  List<TestSpecialty> especialidades,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ElectivesSheet(especialidades: especialidades),
  );
}

class ElectivesSheet extends StatelessWidget {
  const ElectivesSheet({super.key, required this.especialidades});

  final List<TestSpecialty> especialidades;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final gris = MaterialTheme.testMuted(b);
    final tinta = MaterialTheme.textPrimary(b);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: MaterialTheme.sheetBg(b),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: MaterialTheme.sheetHandle(b),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              for (final e in especialidades) ...[
                const SizedBox(height: 16),
                Semantics(
                  header: true,
                  child: Text(
                    'Electivos de ${e.name}',
                    style: TextStyle(
                      color: tinta,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (e.tagline != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    e.tagline!,
                    style: TextStyle(color: gris, fontSize: 12.5, height: 1.35),
                  ),
                ],
                const SizedBox(height: 8),
                for (final electivo in e.electives)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: MaterialTheme.testLine(b)),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          electivo.displayName,
                          style: TextStyle(
                            color: tinta,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          electivo.credits == null
                              ? electivo.code
                              : '${electivo.code} · ${electivo.credits} '
                                    'créditos',
                          style: TextStyle(color: gris, fontSize: 12),
                        ),
                        if (electivo.prerequisite != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            electivo.prerequisite!,
                            style: TextStyle(
                              color: gris,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

Crea `lib/pages/specialty_test/widgets/result_view.dart` con este contenido.

```dart
// lib/pages/specialty_test/widgets/result_view.dart
// El resultado (RF-TEST-8 y RF-TEST-9), pantallas 4 y 5 de la maqueta.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../configs/themes.dart';
import '../../../models/specialty_test_models.dart';
import '../specialty_test_controller.dart';
import '../specialty_test_logic.dart';
import 'electives_sheet.dart';
import 'test_buttons.dart';
import 'ulises_bubble.dart';

const Color _tintaDorada = Color(0xFF1A0E05);
const List<Color> _dorado = [Color(0xFFFFD166), Color(0xFFFFB020)];

class ResultView extends StatefulWidget {
  const ResultView({super.key});

  static const Key tarjetaKey = Key('resultado-tarjeta');
  static const Key cuerpoKey = Key('resultado-cuerpo');
  static const Key confetiKey = Key('resultado-confeti');
  static Key filaKey(int specialtyId) => Key('fila-$specialtyId');
  static Key corazonKey(int specialtyId) => Key('corazon-$specialtyId');

  @override
  State<ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<ResultView> with TickerProviderStateMixin {
  /// El giro de la tarjeta y la cuenta de la afinidad, 600 ms, una vez.
  late final AnimationController _entrada = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  /// El confeti, una sola vez.
  late final AnimationController _confeti = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  /// Al abrir el resultado, el foco del lector pasa a Ulises (RF-TEST-13).
  final FocusNode _ulises = FocusNode(debugLabel: 'ulises-resultado');
  bool _motivoAbierto = false;
  bool _arranco = false;

  SpecialtyTestController get _c => Get.find<SpecialtyTestController>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_arranco) return;
    _arranco = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      // Sin giro, sin confeti y sin cuenta. Sale el valor final.
      _entrada.value = 1;
    } else {
      _entrada.forward();
      _confeti.forward();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ulises.requestFocus();
      HapticFeedback.heavyImpact();
    });
  }

  @override
  void dispose() {
    _entrada.dispose();
    _confeti.dispose();
    _ulises.dispose();
    super.dispose();
  }

  Future<void> _elegir(SpecialtyTestResult r) async {
    if (!r.tie) {
      await _c.elegirPrincipal(r.ranking.first.specialtyId);
      return;
    }
    final elegida = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _HojaDelEmpate(ganadoras: r.winners),
    );
    if (elegida != null) await _c.elegirPrincipal(elegida);
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return ColoredBox(
      color: MaterialTheme.pageBg(b),
      child: SafeArea(
        child: Obx(() {
          final r = _c.resultado.value;
          final contenido = _c.contenido.value;
          final principal = _c.principalActual;
          final corazones = _c.corazones.toSet();
          final activos = _c.botonesActivos;
          final yaEsPrincipal = _c.yaEsPrincipal;
          if (r == null || contenido == null) return const SizedBox.shrink();
          final ganadoras = [
            for (final w in r.winners) contenido.specialtyByKey(w.key),
          ].whereType<TestSpecialty>().toList();
          return Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: _UlisesDelResultado(
                      texto: [?r.headline, ?r.tiebreakOutcome].join(' '),
                      foco: _ulises,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      key: ResultView.cuerpoKey,
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AnimatedBuilder(
                            animation: _entrada,
                            builder: (context, _) => _TarjetaGanadora(
                              resultado: r,
                              contenido: contenido,
                              avance: Curves.easeOut.transform(_entrada.value),
                              motivoAbierto: _motivoAbierto,
                              onMotivo: () => setState(
                                () => _motivoAbierto = !_motivoAbierto,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _FilaDeElectivos(ganadoras: ganadoras, empate: r.tie),
                          const SizedBox(height: 10),
                          const _EncabezadoDeLasDemas(),
                          for (var i = 0; i < r.others.length; i++)
                            _FilaDelRanking(
                              key: ResultView.filaKey(r.others[i].specialtyId),
                              puesto: r.ranking.indexOf(r.others[i]) + 1,
                              entrada: r.others[i],
                              especialidad: contenido.specialtyByKey(
                                r.others[i].key,
                              ),
                              primera: i == 0,
                              marcada: corazones.contains(
                                r.others[i].specialtyId,
                              ),
                              esPrincipal: r.others[i].specialtyId == principal,
                              onCorazon: _c.guardando.value
                                  ? null
                                  : () => _c.alternarCorazon(
                                      r.others[i].specialtyId,
                                    ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TestPrimaryButton(
                          label: yaEsPrincipal
                              ? 'Ya es tu principal'
                              : 'Elegir como principal',
                          height: 48,
                          loading: _c.guardando.value,
                          onPressed: yaEsPrincipal || !activos
                              ? null
                              : () => _elegir(r),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TestSecondaryButton(
                                label: 'Decidir después',
                                onPressed: activos ? _c.decidirDespues : null,
                              ),
                            ),
                            Expanded(
                              child: TestSecondaryButton(
                                label: 'Rehacer el test',
                                icon: LucideIcons.rotateCcw,
                                onPressed: activos ? _c.rehacer : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!MediaQuery.disableAnimationsOf(context))
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: 180,
                  child: IgnorePointer(
                    child: ExcludeSemantics(
                      child: AnimatedBuilder(
                        animation: _confeti,
                        builder: (context, _) => CustomPaint(
                          key: ResultView.confetiKey,
                          painter: _Confeti(_confeti.value),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

/// Ulises a 34 px con `headline` y, si llega, `tiebreakOutcome`.
class _UlisesDelResultado extends StatelessWidget {
  const _UlisesDelResultado({required this.texto, required this.foco});

  final String texto;
  final FocusNode foco;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: Focus(
        focusNode: foco,
        child: UlisesBubble(text: texto, avatarSize: 34, fontSize: 13),
      ),
    );
  }
}

/// Los colores de la tarjeta de la número uno en el tema.
class _ColoresDeLaTarjeta {
  _ColoresDeLaTarjeta(TestSpecialty? e, Brightness b)
    : oscuro = b == Brightness.dark,
      color = colorDeEspecialidad(e, b) ?? MaterialTheme.iconoNaranja(b) {
    final tarjeta = MaterialTheme.cardBg(b);
    if (oscuro) {
      fondo = tinte(color, tarjeta, 0.18);
      tinta = MaterialTheme.textPrimary(b);
      titulo = colorQueSeLee(color, fondo: fondo, respaldo: tinta);
      insigniaTexto = colorQueSeLee(
        color,
        fondo: MaterialTheme.testAiBadgeBg(b),
        respaldo: tinta,
      );
    } else {
      fondo = color;
      // El blanco sobre el color de la ganadora, o la tinta si no llega.
      tinta = colorQueSeLee(
        Colors.white,
        fondo: color,
        respaldo: MaterialTheme.textPrimary(b),
      );
      titulo = tinta;
      insigniaTexto = tinta;
    }
  }

  final bool oscuro;
  final Color color;
  late final Color fondo;
  late final Color tinta;
  late final Color titulo;
  late final Color insigniaTexto;
}

class _TarjetaGanadora extends StatelessWidget {
  const _TarjetaGanadora({
    required this.resultado,
    required this.contenido,
    required this.avance,
    required this.motivoAbierto,
    required this.onMotivo,
  });

  final SpecialtyTestResult resultado;
  final SpecialtyTestContent contenido;

  /// De 0 a 1, el avance del giro y de la cuenta de la afinidad.
  final double avance;
  final bool motivoAbierto;
  final VoidCallback onMotivo;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final r = resultado;
    final primera = r.ranking.first;
    final especialidad = contenido.specialtyByKey(primera.key);
    final k = _ColoresDeLaTarjeta(especialidad, b);
    final nombres = r.winners.map((w) => w.name).toList();
    final afinidad = (primera.affinity * avance).round();
    final resumen = r.tie
        ? 'Empate, ${nombres.join(' y ')}, ${primera.affinity} % de afinidad'
        : 'Tu n.º 1, ${primera.name}, ${primera.affinity} % de afinidad';
    final tarjeta = Container(
      key: ResultView.tarjetaKey,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      decoration: BoxDecoration(
        color: k.oscuro ? k.fondo : null,
        gradient: k.oscuro
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [k.color, oscurecido(k.color)],
              ),
        borderRadius: BorderRadius.circular(22),
        border: k.oscuro
            ? Border.all(color: k.color.withValues(alpha: 0.35))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            container: true,
            label: resumen,
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: k.tinta.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Icon(
                          iconoDelTest(especialidad?.icon),
                          size: 14,
                          color: k.tinta,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          r.tie ? 'Empate' : 'Tu n.º 1',
                          style: TextStyle(
                            color: k.tinta,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: _dorado,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$afinidad % afinidad',
                          style: const TextStyle(
                            color: _tintaDorada,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  for (final nombre in nombres)
                    Text(
                      nombre,
                      style: TextStyle(
                        color: k.titulo,
                        fontSize: 20.5,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                  const SizedBox(height: 8),
                  _Medidor(
                    fraccion: afinidad / 100,
                    pista: k.tinta.withValues(alpha: 0.24),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 9),
          _Motivo(
            texto: r.reason ?? '',
            porIa: r.reasonByAi,
            colores: k,
            abierto: motivoAbierto,
            onTap: onMotivo,
          ),
        ],
      ),
    );
    if (avance >= 1) return tarjeta;
    // El giro de entrada, 600 ms, una sola vez.
    return Opacity(
      opacity: avance.clamp(0.0, 1.0),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0014)
          ..rotateY(-70 * math.pi / 180 * (1 - avance)),
        child: tarjeta,
      ),
    );
  }
}

/// El medidor de 6 px, decorativo porque el número está en la pastilla.
class _Medidor extends StatelessWidget {
  const _Medidor({required this.fraccion, required this.pista});

  final double fraccion;
  final Color pista;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 6,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: pista)),
            FractionallySizedBox(
              widthFactor: fraccion.clamp(0.0, 1.0),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFC94D), Color(0xFFFFB020)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// El motivo, cortado en cuatro líneas con «Leer más», y la insignia «IA»
/// si lo redactó Cohere.
class _Motivo extends StatelessWidget {
  const _Motivo({
    required this.texto,
    required this.porIa,
    required this.colores,
    required this.abierto,
    required this.onTap,
  });

  final String texto;
  final bool porIa;
  final _ColoresDeLaTarjeta colores;
  final bool abierto;
  final VoidCallback onTap;

  static const TextStyle _estilo = TextStyle(fontSize: 12.5, height: 1.38);

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final estilo = _estilo.copyWith(color: colores.tinta);
    return LayoutBuilder(
      builder: (context, box) {
        // Mide si el motivo pasa de cuatro líneas, sin la insignia.
        final medida = TextPainter(
          text: TextSpan(text: texto, style: estilo),
          maxLines: 4,
          textDirection: TextDirection.ltr,
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: math.max(0, box.maxWidth - (porIa ? 44 : 0)));
        final corta = medida.didExceedMaxLines;
        medida.dispose();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              label: porIa ? 'Motivo redactado con IA. $texto' : texto,
              excludeSemantics: true,
              child: Text.rich(
                TextSpan(
                  children: [
                    if (porIa)
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Container(
                          margin: const EdgeInsets.only(right: 5),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: MaterialTheme.testAiBadgeBg(b),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.sparkles,
                                size: 9,
                                color: colores.insigniaTexto,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'IA',
                                style: TextStyle(
                                  color: colores.insigniaTexto,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    TextSpan(text: texto),
                  ],
                ),
                style: estilo,
                maxLines: abierto ? null : 4,
                overflow: abierto ? null : TextOverflow.ellipsis,
              ),
            ),
            if (corta || abierto)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onTap,
                  style: TextButton.styleFrom(
                    foregroundColor: colores.tinta,
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    abierto ? 'Leer menos' : 'Leer más',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

/// La fila de electivos de la ganadora, o de las dos con empate, con «Ver».
class _FilaDeElectivos extends StatelessWidget {
  const _FilaDeElectivos({required this.ganadoras, required this.empate});

  final List<TestSpecialty> ganadoras;
  final bool empate;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    if (ganadoras.isEmpty) return const SizedBox.shrink();
    final primera = ganadoras.first;
    final color =
        colorDeEspecialidad(primera, b) ?? MaterialTheme.iconoNaranja(b);
    final baldosa = tinte(color, MaterialTheme.cardBg(b), 0.13);
    final n = primera.electives.length;
    final cortos = empate
        ? [
            for (final g in ganadoras)
              if (g.electives.isNotEmpty) g.electives.first.displayName,
          ]
        : primera.electives.take(2).map((e) => e.displayName).toList();
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: MaterialTheme.cardBg(b),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: MaterialTheme.testLine(b)),
      ),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: baldosa,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                LucideIcons.bookOpen,
                size: 17,
                color: colorQueSeLee(
                  color,
                  fondo: baldosa,
                  respaldo: MaterialTheme.textPrimary(b),
                  esTexto: false,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  empate
                      ? 'Electivos de las dos'
                      : (n == 1 ? '1 electivo' : '$n electivos'),
                  style: TextStyle(
                    color: MaterialTheme.textPrimary(b),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (cortos.isNotEmpty)
                  Text(
                    cortos.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: MaterialTheme.testMuted(b),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => mostrarElectivos(context, ganadoras),
            style: TextButton.styleFrom(
              foregroundColor: MaterialTheme.testAccentText(b),
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ver',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
                ExcludeSemantics(
                  child: Icon(LucideIcons.chevronRight, size: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EncabezadoDeLasDemas extends StatelessWidget {
  const _EncabezadoDeLasDemas();

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final gris = MaterialTheme.testMuted(b);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              'También te puede interesar',
              style: TextStyle(
                color: MaterialTheme.textPrimary(b),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ExcludeSemantics(
            child: Icon(LucideIcons.heart, size: 12, color: gris),
          ),
          const SizedBox(width: 4),
          Text(
            'guárdala',
            style: TextStyle(
              color: gris,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Una fila desde el puesto 2 (o el 3 con empate), con su corazón de 48 px
/// o, si es la principal, la estrella con «Tu principal».
class _FilaDelRanking extends StatelessWidget {
  const _FilaDelRanking({
    super.key,
    required this.puesto,
    required this.entrada,
    required this.especialidad,
    required this.primera,
    required this.marcada,
    required this.esPrincipal,
    required this.onCorazon,
  });

  final int puesto;
  final RankingEntry entrada;
  final TestSpecialty? especialidad;
  final bool primera;
  final bool marcada;
  final bool esPrincipal;
  final VoidCallback? onCorazon;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final pagina = MaterialTheme.pageBg(b);
    final color =
        colorDeEspecialidad(especialidad, b) ?? MaterialTheme.iconoNaranja(b);
    final baldosa = tinte(color, MaterialTheme.cardBg(b), 0.14);
    final etiqueta =
        'Puesto $puesto, ${entrada.name}, ${entrada.affinity} % de afinidad'
        '${esPrincipal ? ', Tu principal' : ''}';
    return Container(
      constraints: const BoxConstraints(minHeight: 53),
      decoration: BoxDecoration(
        border: primera
            ? null
            : Border(top: BorderSide(color: MaterialTheme.testLine(b))),
      ),
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: etiqueta,
        child: Row(
          children: [
            ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.only(left: 4, top: 6, bottom: 6),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: baldosa,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        iconoDelTest(especialidad?.icon),
                        size: 17,
                        color: color,
                      ),
                    ),
                    Positioned(
                      left: -6,
                      top: -6,
                      child: Container(
                        width: 17,
                        height: 17,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: MaterialTheme.textPrimary(b),
                          shape: BoxShape.circle,
                          border: Border.all(color: pagina, width: 2),
                        ),
                        child: Text(
                          '$puesto',
                          style: TextStyle(
                            color: pagina,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            entrada.name,
                            style: TextStyle(
                              color: MaterialTheme.textPrimary(b),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${entrada.affinity} %',
                          style: TextStyle(
                            color: colorQueSeLee(
                              color,
                              fondo: pagina,
                              respaldo: MaterialTheme.textPrimary(b),
                            ),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: SizedBox(
                        height: 4,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ColoredBox(
                                color: MaterialTheme.testTrack(b),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: entrada.affinity / 100,
                              child: ColoredBox(color: color),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
            if (esPrincipal)
              Padding(
                padding: const EdgeInsets.only(right: 2),
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: MaterialTheme.testAccentText(b),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Tu principal',
                        style: TextStyle(
                          color: MaterialTheme.testAccentText(b),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Semantics(
                button: true,
                toggled: marcada,
                label: marcada
                    ? 'Quitar ${entrada.name} de tus intereses'
                    : 'Marcar ${entrada.name} como interés',
                excludeSemantics: true,
                onTap: onCorazon,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    key: ResultView.corazonKey(entrada.specialtyId),
                    onPressed: onCorazon,
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      marcada ? Icons.favorite_rounded : LucideIcons.heart,
                      size: 21,
                      color: marcada
                          ? colorQueSeLee(
                              color,
                              fondo: pagina,
                              respaldo: MaterialTheme.textPrimary(b),
                              esTexto: false,
                            )
                          : MaterialTheme.testHeartOff(b),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// La hoja «¿Cuál eliges como principal?» del empate (decisión abierta 11).
class _HojaDelEmpate extends StatelessWidget {
  const _HojaDelEmpate({required this.ganadoras});

  final List<RankingEntry> ganadoras;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Container(
      decoration: BoxDecoration(
        color: MaterialTheme.sheetBg(b),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  '¿Cuál eliges como principal?',
                  style: TextStyle(
                    color: MaterialTheme.textPrimary(b),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              for (final g in ganadoras) ...[
                TestPrimaryButton(
                  label: g.name,
                  height: 48,
                  onPressed: () => Navigator.of(context).pop(g.specialtyId),
                ),
                const SizedBox(height: 8),
              ],
              TestSecondaryButton(
                label: 'Cancelar',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Confeti decorativo, una sola vez. Semilla fija para que las pruebas vean
/// siempre lo mismo.
class _Confeti extends CustomPainter {
  _Confeti(this.t);

  final double t;

  static const List<Color> _colores = [
    Color(0xFFFF6600),
    Color(0xFFFFB020),
    Color(0xFF22C55E),
    Color(0xFF2563EB),
    Color(0xFFC0267E),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final azar = math.Random(7);
    final pincel = Paint();
    for (var i = 0; i < 28; i++) {
      final x = azar.nextDouble() * size.width;
      final caida = size.height * (0.2 + azar.nextDouble() * 0.8) * t;
      pincel.color = _colores[i % _colores.length].withValues(
        alpha: (1 - t).clamp(0.0, 1.0),
      );
      canvas.save();
      canvas.translate(x, caida);
      canvas.rotate(azar.nextDouble() * math.pi * t * 4);
      canvas.drawRect(const Rect.fromLTWH(-3, -1.5, 6, 3), pincel);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_Confeti old) => old.t != t;
}
```

- [ ] **Paso 4: Correr las pruebas y ver que pasan**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/HU36_jeff/specialty_test_resultado_test.dart \
  test/HU36_jeff/specialty_test_eleccion_test.dart \
  test/HU36_jeff/specialty_test_accesibilidad_test.dart
```

Esperado: PASS, `+58: All tests passed!`.

- [ ] **Paso 5: Dar formato y analizar**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/pages/specialty_test/widgets/electives_sheet.dart \
  lib/pages/specialty_test/widgets/result_view.dart \
  test/HU36_jeff/specialty_test_resultado_test.dart \
  test/HU36_jeff/specialty_test_eleccion_test.dart \
  test/HU36_jeff/specialty_test_accesibilidad_test.dart
```

Esperado: `Formatted 5 files (0 changed)`.

```bash
cd "${REPO:?}"
"${FLUTTER:?}" analyze --no-pub
```

Esperado: `6 issues found.`, los 6 de la línea base y ninguno en un archivo de esta tarea.

- [ ] **Paso 6: Commit**

```bash
cd "${REPO:?}"
test "$(git branch --show-current)" = feat/test-especialidad-fe || echo 'PARAR: rama equivocada'
git status --short
git add lib/pages/specialty_test/widgets/electives_sheet.dart \
  lib/pages/specialty_test/widgets/result_view.dart \
  test/HU36_jeff/specialty_test_resultado_test.dart \
  test/HU36_jeff/specialty_test_eleccion_test.dart \
  test/HU36_jeff/specialty_test_accesibilidad_test.dart
git commit -m 'feat(specialty-test): el resultado muestra la número uno, su motivo, los electivos y las demás con su corazón, sin desplazar en el iPhone SE (RF-TEST-8)'
git log -1 --format='%an <%ae>'
git log -1 --format=%B | grep -qi '^co-authored-by:' && echo 'PARAR: el commit trae trailer'
```

Esperado: ningún `PARAR`. Antes del `git add`, `git status --short` lista solo los archivos de la tarea, y el autor es `Jeffangeloss <178797184+jeffangeloss@users.noreply.github.com>`.

---

### Tarea 15: La ruta /test-especialidad

**Requisitos:** RF-TEST-1 (ruta con su binding y el argumento `origen`), el atrás del sistema de RF-TEST-4 y RF-TEST-8, y los avisos y el diálogo de RF-TEST-11.

**Archivos:**
- Crear `lib/pages/specialty_test/specialty_test_page.dart` y `lib/pages/specialty_test/specialty_test_binding.dart`
- Modificar `lib/main.dart` (imports y `GetPage` de la ruta)
- Modificar `test/HU36_jeff/montaje_de_pantallas.dart` (imports, `abrirLaRuta` y `asentar`)
- Modificar `test/HU36_jeff/specialty_test_conversacion_test.dart`, `test/HU36_jeff/specialty_test_resultado_test.dart` y `test/HU36_jeff/specialty_test_errores_test.dart` (grupos `_ruta` y `_avisos`)

**Interfaces:**

- Consume las cuatro vistas (Tareas 11 a 14) y el controlador entero.
- Produce lo que sigue, que usan la tarjeta del Perfil (Tarea 16) y el asistente
  (Tarea 18).

```dart
class SpecialtyTestPage extends GetView<SpecialtyTestController> {
  static const String ruta = '/test-especialidad';
  static Map<String, String> argumentos(OrigenDelTest origen); }
class UiDelTestConGet implements SpecialtyTestUi { const UiDelTestConGet(); }
class SpecialtyTestBinding extends Bindings { }   // lazyPut sin fenix
// test/HU36_jeff/montaje_de_pantallas.dart
Future<Future<Object?>?> abrirLaRuta(WidgetTester tester,
  {OrigenDelTest origen});
Future<void> asentar(WidgetTester tester);
```

`UiDelTestConGet.cerrar` usa `Get.key.currentState?.pop`, porque
`Get.back()` de get 4.7.3 cierra el aviso abierto en lugar de la ruta.

- [ ] **Paso 1: Escribir las pruebas que fallan**

En `test/HU36_jeff/montaje_de_pantallas.dart`, cambia este bloque, que aparece una sola vez,

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';

import 'dobles_del_controlador.dart';
```

por este otro.

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_binding.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_page.dart';

import 'dobles_del_controlador.dart';
```

Agrega al final de `test/HU36_jeff/montaje_de_pantallas.dart`, tras una línea en blanco, este bloque.

```dart
/// Monta la app con la ruta real del test sobre una pantalla de inicio y la
/// abre con [origen]. Devuelve el `Future` de `Get.toNamed`, que se completa
/// con la salida al cerrarse la ruta.
Future<Future<Object?>?> abrirLaRuta(
  WidgetTester tester, {
  OrigenDelTest origen = OrigenDelTest.asistente,
}) async {
  tester.view.physicalSize = kIphoneSE;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final tema = MaterialTheme(ThemeData().textTheme);
  await tester.pumpWidget(
    GetMaterialApp(
      theme: tema.light(),
      initialRoute: '/inicio',
      getPages: [
        GetPage(
          name: '/inicio',
          page: () => const Scaffold(body: Text('Pantalla de inicio')),
        ),
        GetPage(
          name: '/home',
          page: () => const Scaffold(body: Text('Home de prueba')),
        ),
        GetPage(
          name: SpecialtyTestPage.ruta,
          page: () => const SpecialtyTestPage(),
          binding: SpecialtyTestBinding(),
        ),
      ],
    ),
  );
  final salida = Get.toNamed<Object?>(
    SpecialtyTestPage.ruta,
    arguments: SpecialtyTestPage.argumentos(origen),
  );
  await asentar(tester);
  return salida;
}

/// Deja pasar las transiciones de ruta y de pantalla. No usa
/// `pumpAndSettle`, porque el vaivén de la bienvenida y el brillo de la
/// pluma se repiten sin fin.
Future<void> asentar(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
}
```

En `test/HU36_jeff/specialty_test_conversacion_test.dart`, cambia este bloque, que aparece una sola vez,

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/specialty_test_models.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/question_view.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/ulises_bubble.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';
import 'montaje_de_pantallas.dart';
```

por este otro.

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/specialty_test_models.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/question_view.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/ulises_bubble.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';
import 'montaje_de_pantallas.dart';
```

En `test/HU36_jeff/specialty_test_conversacion_test.dart`, cambia este bloque, que aparece una sola vez,

```dart
  _pantalla();
}
```

por este otro.

```dart
  _pantalla();
  _ruta();
}
```

Agrega al final de `test/HU36_jeff/specialty_test_conversacion_test.dart`, tras una línea en blanco, este bloque.

```dart
void _ruta() {
  group('WIDGET · El atrás del sistema en la ruta (RF-TEST-1 y RF-TEST-4)', () {
    testWidgets('caso 16: el argumento dice el origen y el atrás en la '
        'bienvenida cierra la ruta sin salida', (tester) async {
      final t = prepararTest(ApiFalsaDelTest());
      final salida = await abrirLaRuta(tester, origen: OrigenDelTest.perfil);
      final c = Get.find<SpecialtyTestController>();
      expect(c.origen, OrigenDelTest.perfil);
      c.empezar();
      responderPasos(c, ['top']);
      c.atras();
      c.atras();
      await asentar(tester);
      expect(c.fase.value, FaseDelTest.bienvenida);
      await tester.binding.handlePopRoute();
      await asentar(tester);
      expect(find.text('Pantalla de inicio'), findsOneWidget);
      expect(await salida, isNull);
      // El controlador murió con la ruta y dejó el avance en pausa.
      expect(Get.isRegistered<SpecialtyTestController>(), isFalse);
      expect(t.service.paused!.answers, {'q01': 'top'});
    });

    testWidgets('caso 17: en una pregunta, el atrás del sistema lleva a la '
        'anterior y desde la espera, a la pregunta', (tester) async {
      prepararTest(
        ApiFalsaDelTest(evaluaciones: [Completer<Map<String, dynamic>>()]),
      );
      await abrirLaRuta(tester);
      final c = Get.find<SpecialtyTestController>();
      c.empezar();
      responderPasos(c, ['top', 'both']);
      await asentar(tester);
      await tester.binding.handlePopRoute();
      await asentar(tester);
      expect(c.paso.value, 1);
      expect(find.text('Pregunta 2 de 5'), findsOneWidget);
      responderPasos(c, ['both', 'nada', 'top', 'nada']);
      await tester.pump();
      expect(c.fase.value, FaseDelTest.espera);
      await tester.binding.handlePopRoute();
      await asentar(tester);
      expect(c.fase.value, FaseDelTest.pregunta);
      expect(c.paso.value, 4);
      // La evaluación en vuelo vence y se descarta.
      await tester.pump(const Duration(seconds: 20));
    });
  });
}
```

En `test/HU36_jeff/specialty_test_resultado_test.dart`, cambia este bloque, que aparece una sola vez,

```dart
  _resultado();
}
```

por este otro.

```dart
  _resultado();
  _ruta();
}
```

Agrega al final de `test/HU36_jeff/specialty_test_resultado_test.dart`, tras una línea en blanco, este bloque.

```dart
void _ruta() {
  group('WIDGET · El atrás del sistema en el resultado (RF-TEST-8)', () {
    testWidgets('caso 11: en el asistente no hace nada', (tester) async {
      final t = prepararTest(ApiFalsaDelTest());
      await abrirLaRuta(tester);
      final c = Get.find<SpecialtyTestController>();
      c.empezar();
      responderPasos(c, respuestasEnOrden);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(ResultView), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ResultView), findsOneWidget);
      expect(c.fase.value, FaseDelTest.resultado);
      expect(t.auth.guardados, isEmpty);
    });

    testWidgets('caso 12: en el Perfil es «Decidir después» y cierra la ruta '
        'sin guardar', (tester) async {
      final t = prepararTest(ApiFalsaDelTest());
      final salida = await abrirLaRuta(tester, origen: OrigenDelTest.perfil);
      final c = Get.find<SpecialtyTestController>();
      c.empezar();
      responderPasos(c, respuestasEnOrden);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.binding.handlePopRoute();
      await asentar(tester);
      expect(find.text('Pantalla de inicio'), findsOneWidget);
      expect(await salida, SalidaDelTest.terminado);
      expect(t.auth.guardados, isEmpty);
    });
  });
}
```

En `test/HU36_jeff/specialty_test_errores_test.dart`, cambia este bloque, que aparece una sola vez,

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:ulima_plus/models/specialty_test_models.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_logic.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';
```

por este otro.

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/specialty_test_models.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_logic.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_page.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';
import 'montaje_de_pantallas.dart';
```

En `test/HU36_jeff/specialty_test_errores_test.dart`, cambia este bloque, que aparece una sola vez,

```dart
  _guardados();
}
```

por este otro.

```dart
  _guardados();
  _avisos();
}
```

Agrega al final de `test/HU36_jeff/specialty_test_errores_test.dart`, tras una línea en blanco, este bloque.

```dart
void _avisos() {
  group('WIDGET · Los avisos y el diálogo de la ruta (RF-TEST-11)', () {
    testWidgets('fila 13: el aviso de error va en blanco sobre errorBg y el '
        'que informa, en cardBg con borde', (tester) async {
      prepararTest(ApiFalsaDelTest());
      await abrirLaRuta(tester);
      const ui = UiDelTestConGet();
      const b = Brightness.light;
      ui.avisar(const AvisoDelTest(TipoDeAviso.error, 'Aviso de prueba.'));
      await asentar(tester);
      var barra = tester.widget<GetSnackBar>(find.byType(GetSnackBar));
      expect(barra.backgroundColor, MaterialTheme.errorBg(b));
      expect(colorDeTexto(tester, 'Aviso de prueba.'), Colors.white);
      await tester.pump(const Duration(seconds: 5));
      await asentar(tester);
      ui.avisar(const AvisoDelTest(TipoDeAviso.info, 'Otro aviso de prueba.'));
      await asentar(tester);
      barra = tester.widget<GetSnackBar>(find.byType(GetSnackBar));
      expect(barra.backgroundColor, MaterialTheme.cardBg(b));
      expect(barra.borderColor, MaterialTheme.borderColor(b));
      expect(
        colorDeTexto(tester, 'Otro aviso de prueba.'),
        MaterialTheme.textPrimary(b),
      );
      // Con el aviso abierto, cerrar la ruta la cierra igual.
      ui.cerrar();
      await asentar(tester);
      expect(find.text('Pantalla de inicio'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await asentar(tester);
    });

    testWidgets('fila 5: el diálogo trae el mensaje y «Empezar de nuevo», y '
        'el atrás no lo cierra', (tester) async {
      prepararTest(ApiFalsaDelTest());
      await abrirLaRuta(tester);
      const ui = UiDelTestConGet();
      var tocado = false;
      unawaited(
        ui
            .pedirReinicio('El test se actualizó. Vuelve a empezarlo.')
            .then((_) => tocado = true),
      );
      await asentar(tester);
      expect(
        find.text('El test se actualizó. Vuelve a empezarlo.'),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await asentar(tester);
      expect(find.text('Empezar de nuevo'), findsOneWidget);
      expect(tocado, isFalse);
      await tester.tap(find.text('Empezar de nuevo'));
      await asentar(tester);
      expect(tocado, isTrue);
    });
  });
}
```

- [ ] **Paso 2: Correr las pruebas y ver que fallan**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/HU36_jeff/specialty_test_conversacion_test.dart \
  test/HU36_jeff/specialty_test_resultado_test.dart \
  test/HU36_jeff/specialty_test_errores_test.dart
```

Esperado: FALLA al compilar, sin llegar a correr ningún caso. La salida trae 11 errores distintos (líneas `Error:`), y los primeros dicen esto (las rutas pueden salir absolutas).

```text
test/HU36_jeff/montaje_de_pantallas.dart:15:8: Error: Error when reading 'lib/pages/specialty_test/specialty_test_page.dart': No such file or directory
test/HU36_jeff/montaje_de_pantallas.dart:133:17: Error: Undefined name 'SpecialtyTestPage'.
```

- [ ] **Paso 3: Escribir la página y el binding**

Crea `lib/pages/specialty_test/specialty_test_page.dart` con este contenido.

```dart
// lib/pages/specialty_test/specialty_test_page.dart
// La ruta /test-especialidad (RF-TEST-1), que cambia entre la bienvenida,
// la pregunta, la espera y el resultado.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../configs/themes.dart';
import 'specialty_test_controller.dart';
import 'widgets/question_view.dart';
import 'widgets/result_view.dart';
import 'widgets/waiting_view.dart';
import 'widgets/welcome_view.dart';

class SpecialtyTestPage extends GetView<SpecialtyTestController> {
  const SpecialtyTestPage({super.key});

  static const String ruta = '/test-especialidad';

  /// Los argumentos de la ruta para [origen].
  static Map<String, String> argumentos(OrigenDelTest origen) => {
    'origen': origen.name,
  };

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final sinMovimiento = MediaQuery.disableAnimationsOf(context);
    return Obx(() {
      final fase = controller.fase.value;
      return PopScope(
        // Solo la bienvenida deja salir con el atrás del sistema. En las
        // preguntas y en la espera lleva al paso previo; en el resultado,
        // nada en el asistente y «Decidir después» en el Perfil.
        canPop: fase == FaseDelTest.bienvenida,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (fase == FaseDelTest.resultado) {
            controller.atrasEnResultado();
          } else {
            controller.atras();
          }
        },
        child: Scaffold(
          backgroundColor: MaterialTheme.pageBg(b),
          body: AnimatedSwitcher(
            duration: Duration(milliseconds: sinMovimiento ? 150 : 220),
            child: KeyedSubtree(
              key: ValueKey<FaseDelTest>(fase),
              child: switch (fase) {
                FaseDelTest.bienvenida => const WelcomeView(),
                FaseDelTest.pregunta => const QuestionView(),
                FaseDelTest.espera => const WaitingView(),
                FaseDelTest.resultado => const ResultView(),
              },
            ),
          ),
        ),
      );
    });
  }
}

/// La pantalla con GetX. Cierra la ruta con `pop` del navegador y no con
/// `Get.back()`, que con un aviso abierto solo cierra el aviso.
class UiDelTestConGet implements SpecialtyTestUi {
  const UiDelTestConGet();

  Brightness get _brillo {
    final contexto = Get.context;
    return contexto == null ? Brightness.light : Theme.of(contexto).brightness;
  }

  @override
  void cerrar([SalidaDelTest? salida]) =>
      Get.key.currentState?.pop<SalidaDelTest>(salida);

  @override
  void irAlHome() => Get.offAllNamed<void>('/home');

  @override
  void avisar(AvisoDelTest aviso) {
    final b = _brillo;
    switch (aviso.tipo) {
      case TipoDeAviso.exito:
        // El aviso de siempre del Perfil (`perfil.dart`), sin cambios.
        Get.snackbar(aviso.titulo ?? '', aviso.mensaje);
      case TipoDeAviso.error:
        // Blanco sobre `errorBg`, 6,54:1, como los avisos de error del chat.
        Get.rawSnackbar(
          messageText: Text(
            aviso.mensaje,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          backgroundColor: MaterialTheme.errorBg(b),
          margin: const EdgeInsets.all(12),
          borderRadius: 12,
        );
      case TipoDeAviso.info:
        Get.rawSnackbar(
          messageText: Text(
            aviso.mensaje,
            style: TextStyle(color: MaterialTheme.textPrimary(b), fontSize: 14),
          ),
          backgroundColor: MaterialTheme.cardBg(b),
          borderColor: MaterialTheme.borderColor(b),
          margin: const EdgeInsets.all(12),
          borderRadius: 12,
        );
    }
  }

  @override
  Future<void> pedirReinicio(String mensaje) {
    return Get.dialog<void>(
      PopScope(
        canPop: false,
        child: Builder(
          builder: (context) {
            final b = Theme.of(context).brightness;
            return AlertDialog(
              backgroundColor: MaterialTheme.cardBg(b),
              content: Text(
                mensaje,
                style: TextStyle(
                  color: MaterialTheme.textPrimary(b),
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: MaterialTheme.testAccentText(b),
                    minimumSize: const Size(48, 48),
                  ),
                  child: const Text(
                    'Empezar de nuevo',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      barrierDismissible: false,
    );
  }
}
```

Crea `lib/pages/specialty_test/specialty_test_binding.dart` con este contenido.

```dart
// lib/pages/specialty_test/specialty_test_binding.dart
// El binding por ruta de /test-especialidad (RF-TEST-1).

import 'package:get/get.dart';

import 'specialty_test_controller.dart';
import 'specialty_test_page.dart';

/// `lazyPut` sin `fenix`, para que el controlador muera al cerrar la ruta y
/// su `onClose` deje el avance en pausa. El argumento `origen` dice si se
/// abrió desde el asistente o desde el Perfil.
class SpecialtyTestBinding extends Bindings {
  @override
  void dependencies() {
    final argumentos = Get.arguments;
    final origen = argumentos is Map && argumentos['origen'] == 'perfil'
        ? OrigenDelTest.perfil
        : OrigenDelTest.asistente;
    Get.lazyPut<SpecialtyTestController>(
      () =>
          SpecialtyTestController(origen: origen, ui: const UiDelTestConGet()),
    );
  }
}
```

- [ ] **Paso 4: Registrar la ruta en main.dart**

La ruta va justo después de `/setup-carrera`. El binding de `/setup-carrera` llega en la Tarea 18.

En `lib/main.dart`, cambia este bloque, que aparece una sola vez,

```dart
import 'pages/setup_carrera/setup_carrera_page.dart';
```

por este otro.

```dart
import 'pages/setup_carrera/setup_carrera_page.dart';
import 'pages/specialty_test/specialty_test_binding.dart';
import 'pages/specialty_test/specialty_test_page.dart';
```

En `lib/main.dart`, cambia este bloque, que aparece una sola vez,

```dart
        GetPage(name: '/setup-carrera', page: () => const SetupCarreraPage()),
```

por este otro.

```dart
        GetPage(name: '/setup-carrera', page: () => const SetupCarreraPage()),
        // Test de especialidad (RF-TEST-1), con el argumento
        // {'origen': 'asistente'} o {'origen': 'perfil'}. Binding por ruta,
        // como el resto, así que el controlador muere al cerrar la ruta y
        // deja el avance en pausa.
        GetPage(
          name: SpecialtyTestPage.ruta,
          page: () => const SpecialtyTestPage(),
          binding: SpecialtyTestBinding(),
        ),
```

- [ ] **Paso 5: Correr las pruebas y ver que pasan**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/HU36_jeff/specialty_test_conversacion_test.dart \
  test/HU36_jeff/specialty_test_resultado_test.dart \
  test/HU36_jeff/specialty_test_errores_test.dart
```

Esperado: PASS, `+49: All tests passed!`.

- [ ] **Paso 6: Dar formato y analizar**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/pages/specialty_test/specialty_test_page.dart \
  lib/pages/specialty_test/specialty_test_binding.dart \
  lib/main.dart \
  test/HU36_jeff/montaje_de_pantallas.dart \
  test/HU36_jeff/specialty_test_conversacion_test.dart \
  test/HU36_jeff/specialty_test_resultado_test.dart \
  test/HU36_jeff/specialty_test_errores_test.dart
```

Esperado: `Formatted 7 files (0 changed)`.

```bash
cd "${REPO:?}"
"${FLUTTER:?}" analyze --no-pub
```

Esperado: `6 issues found.`, los 6 de la línea base y ninguno en un archivo de esta tarea.

- [ ] **Paso 7: Correr toda la carpeta del test**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/HU36_jeff
```

Esperado: PASS, `+213: All tests passed!`.

- [ ] **Paso 8: Commit**

```bash
cd "${REPO:?}"
test "$(git branch --show-current)" = feat/test-especialidad-fe || echo 'PARAR: rama equivocada'
git status --short
git add lib/pages/specialty_test/specialty_test_page.dart \
  lib/pages/specialty_test/specialty_test_binding.dart \
  lib/main.dart \
  test/HU36_jeff/montaje_de_pantallas.dart \
  test/HU36_jeff/specialty_test_conversacion_test.dart \
  test/HU36_jeff/specialty_test_resultado_test.dart \
  test/HU36_jeff/specialty_test_errores_test.dart
git commit -m 'feat(specialty-test): la ruta /test-especialidad cambia de vista por fase, maneja el atrás del sistema y muestra los avisos (RF-TEST-1 y RF-TEST-11)'
git log -1 --format='%an <%ae>'
git log -1 --format=%B | grep -qi '^co-authored-by:' && echo 'PARAR: el commit trae trailer'
```

Esperado: ningún `PARAR`. Antes del `git add`, `git status --short` lista solo los archivos de la tarea, y el autor es `Jeffangeloss <178797184+jeffangeloss@users.noreply.github.com>`.

---

### Tarea 16: La tarjeta del test en el Perfil

**Requisitos:** RF-TEST-10 entero.

**Archivos:**
- Crear `lib/pages/specialty_test/specialty_test_profile_card.dart`
- Modificar `lib/pages/perfil/perfil.dart` (dos imports y la tarjeta debajo de «Especialización»)
- Crear `test/HU36_jeff/specialty_test_perfil_test.dart`

**Interfaces:**

- Consume `SpecialtyTestService` (`lastResultStatus`, `lastResult`,
  `paused`, `content`, `loadLastResult`), `SpecialtyTestPage.ruta` y
  `argumentos` (Tarea 15), `fechaEnLima` (Tarea 5) y los widgets de la
  Tarea 11.
- Produce lo que sigue.

```dart
class SpecialtyTestProfileCard extends StatefulWidget {
  static const Key skeletonKey; static const String titulo;
  static Key iconoKey(String clave); static Key barraKey(String clave); }
```

- [ ] **Paso 1: Escribir la prueba que falla**

El caso 11 monta el Perfil sin `SpecialtyTestService`, como `test/HU34_jeff/record_card_test.dart`, y fija que la guarda lo deja pasar sin HTTP. El registro de `AcademicRecordService` escribe un aviso de ruta sin respuesta en la consola, que no cuenta como fallo.

Crea `test/HU36_jeff/specialty_test_perfil_test.dart` con este contenido.

```dart
// test/HU36_jeff/specialty_test_perfil_test.dart
//
// Pruebas de widget de HU36, el test de especialidad, sobre el último
// resultado en el Perfil y «Rehacer el test» (RF-TEST-10).
// Tarjeta: lib/pages/specialty_test/specialty_test_profile_card.dart
//
// Datos inventados (datos_de_prueba.dart). El alumno de prueba es 20230001.
// La fecha se mide en hora de Lima, y la verificación de la spec corre esta
// carpeta con TZ=UTC.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/specialty_test_models.dart';
import 'package:ulima_plus/pages/perfil/perfil.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_page.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_profile_card.dart';
import 'package:ulima_plus/services/academic_record_service.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';
import 'montaje_de_pantallas.dart';

Future<ApiFalsaDelTest> _tarjeta(
  WidgetTester tester, {
  List<Object>? resultados,
  List<Object>? contenido,
  PausedSpecialtyTest? pausado,
}) async {
  final api = ApiFalsaDelTest(resultados: resultados, contenido: contenido);
  final t = prepararTest(api);
  if (pausado != null) t.service.pause(pausado);
  await montarPantalla(
    tester,
    const SingleChildScrollView(child: SpecialtyTestProfileCard()),
  );
  await tester.pump();
  return api;
}

PausedSpecialtyTest _pausado() => PausedSpecialtyTest(
  content: SpecialtyTestContent.tryParse(contenidoJson())!,
  answers: const {'q01': 'top', 'q02': 'none'},
  tiebreaks: const [],
);

ApiException _noDisponible() => ApiException(
  statusCode: 404,
  code: 'SPECIALTY_TEST_NOT_AVAILABLE',
  message: 'El test de especialidad no está disponible para tu carrera.',
);

void main() {
  // Get.put de un GetxService agenda onReady con
  // Get.engine.addPostFrameCallback, que necesita el binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(Get.reset);
  tearDown(Get.reset);

  _estados();
  _navegacion();
}

void _estados() {
  group('WIDGET · Los estados de la tarjeta del Perfil (RF-TEST-10)', () {
    testWidgets('caso 1: mientras carga, un esqueleto', (tester) async {
      final pendiente = Completer<Map<String, dynamic>>();
      await _tarjeta(tester, resultados: [pendiente]);
      expect(find.byKey(SpecialtyTestProfileCard.skeletonKey), findsOneWidget);
      pendiente.complete(<String, dynamic>{'result': null});
      await tester.pump();
      expect(find.byKey(SpecialtyTestProfileCard.skeletonKey), findsNothing);
    });

    testWidgets('caso 2: sin test, Ulises, el título, el aviso y «Hacer el '
        'test»', (tester) async {
      await _tarjeta(
        tester,
        resultados: [
          <String, dynamic>{'result': null},
        ],
      );
      expect(find.text('Test de especialidad'), findsOneWidget);
      expect(find.text('Todavía no hiciste el test.'), findsOneWidget);
      expect(find.text('Hacer el test'), findsOneWidget);
    });

    testWidgets('caso 3: con resultado, la fecha en hora de Lima, la número '
        'uno, las demás y «Rehacer el test»', (tester) async {
      await _tarjeta(tester);
      expect(find.text('Hecho el 25/09/2026'), findsOneWidget);
      expect(find.text('Desarrollo de Videojuegos'), findsOneWidget);
      expect(find.text('75 %'), findsOneWidget);
      expect(find.text('Sistemas de Información'), findsOneWidget);
      expect(find.text('24 %'), findsOneWidget);
      expect(find.text('Rehacer el test'), findsOneWidget);
      expect(find.text('El test cambió desde que lo hiciste.'), findsNothing);
      // Sin motivo, que no se guarda.
      expect(find.textContaining('sumó'), findsNothing);
    });

    testWidgets('caso 4: con empate van las dos ganadoras', (tester) async {
      await _tarjeta(tester, resultados: [ultimoResultadoJson(empate: true)]);
      expect(
        find.byKey(SpecialtyTestProfileCard.iconoKey('si')),
        findsOneWidget,
      );
      expect(
        find.byKey(SpecialtyTestProfileCard.iconoKey('vj')),
        findsOneWidget,
      );
    });

    testWidgets('caso 5: con otra versión, «El test cambió desde que lo '
        'hiciste.»', (tester) async {
      await _tarjeta(
        tester,
        resultados: [ultimoResultadoJson(isCurrentVersion: false)],
      );
      expect(find.text('El test cambió desde que lo hiciste.'), findsOneWidget);
    });

    testWidgets('caso 6: con un test a medias, «Tienes un test a medias, N de '
        'T.» y «Seguir el test», con o sin resultado', (tester) async {
      await _tarjeta(tester, pausado: _pausado());
      expect(find.text('Tienes un test a medias, 2 de 5.'), findsOneWidget);
      expect(find.text('Seguir el test'), findsOneWidget);
      expect(find.text('Desarrollo de Videojuegos'), findsOneWidget);
      Get.reset();
      await _tarjeta(
        tester,
        resultados: [
          <String, dynamic>{'result': null},
        ],
        pausado: _pausado(),
      );
      expect(find.text('Tienes un test a medias, 2 de 5.'), findsOneWidget);
      expect(find.text('Todavía no hiciste el test.'), findsNothing);
    });

    testWidgets('caso 7: con error, el aviso y «Reintentar», que vuelve a '
        'pedir', (tester) async {
      final api = await _tarjeta(
        tester,
        resultados: [http.ClientException('sin red'), ultimoResultadoJson()],
      );
      expect(find.text('No se pudo cargar tu último test.'), findsOneWidget);
      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      expect(api.getsDeResultado, 2);
      expect(find.text('Desarrollo de Videojuegos'), findsOneWidget);
    });

    testWidgets('caso 8: sin el test disponible, la tarjeta no aparece', (
      tester,
    ) async {
      await _tarjeta(tester, resultados: [_noDisponible()]);
      expect(find.text('Test de especialidad'), findsNothing);
      expect(tester.getSize(find.byType(SpecialtyTestProfileCard)).height, 0);
    });

    testWidgets('caso 9: los colores salen del contenido y, sin contenido, '
        'van neutros', (tester) async {
      await _tarjeta(tester);
      const b = Brightness.light;
      Color? icono(String clave) => tester
          .widget<Icon>(find.byKey(SpecialtyTestProfileCard.iconoKey(clave)))
          .color;
      Color? barra(String clave) => tester
          .widget<ColoredBox>(
            find.byKey(SpecialtyTestProfileCard.barraKey(clave)),
          )
          .color;
      expect(icono('vj'), const Color(0xFF76164A));
      expect(barra('si'), const Color(0xFF9333EA));
      Get.reset();
      await _tarjeta(tester, contenido: [http.ClientException('sin red')]);
      expect(find.text('Desarrollo de Videojuegos'), findsOneWidget);
      expect(icono('vj'), MaterialTheme.iconoNaranja(b));
      expect(barra('si'), MaterialTheme.testMuted(b));
    });
  });
}

void _navegacion() {
  group('WIDGET · Los botones de la tarjeta y el Perfil (RF-TEST-10)', () {
    testWidgets('caso 10: «Rehacer el test» abre el test desde el Perfil y, '
        'al volver de un test terminado, pide otra vez', (tester) async {
      final api = ApiFalsaDelTest();
      prepararTest(api);
      Object? argumentos;
      await tester.pumpWidget(
        GetMaterialApp(
          home: const Scaffold(
            body: SingleChildScrollView(child: SpecialtyTestProfileCard()),
          ),
          getPages: [
            GetPage(
              name: SpecialtyTestPage.ruta,
              page: () {
                argumentos = Get.arguments;
                return const Scaffold(body: Text('Test de prueba'));
              },
            ),
          ],
        ),
      );
      await tester.pump();
      expect(api.getsDeResultado, 1);
      await tester.tap(find.text('Rehacer el test'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(argumentos, {'origen': 'perfil'});
      // Un test terminado deja el último resultado viejo.
      await SpecialtyTestService.to.evaluate(const {});
      Get.back<void>();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(api.getsDeResultado, 2);
    });

    testWidgets('caso 11: el Perfil sin el service no monta la tarjeta ni '
        'falla', (tester) async {
      Get.put<AuthService>(AuthDelControlador(alumno()));
      Get.put<AcademicRecordService>(
        AcademicRecordService(apiClient: ApiFalsaDelTest()),
      );
      await tester.pumpWidget(const GetMaterialApp(home: ProfilePage()));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(SpecialtyTestProfileCard), findsNothing);
    });

    testWidgets('caso 12: con el service, la tarjeta va debajo de '
        '«Especialización»', (tester) async {
      prepararTest(ApiFalsaDelTest());
      Get.put<AcademicRecordService>(
        AcademicRecordService(apiClient: ApiFalsaDelTest()),
      );
      await tester.pumpWidget(const GetMaterialApp(home: ProfilePage()));
      await tester.pump();
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Test de especialidad'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      final especializacion = tester.getTopLeft(
        find.text('Especialización').first,
      );
      final tarjeta = tester.getTopLeft(find.text('Test de especialidad'));
      expect(tarjeta.dy, greaterThan(especializacion.dy));
    });
  });
}
```

- [ ] **Paso 2: Correr la prueba y ver que falla**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/HU36_jeff/specialty_test_perfil_test.dart
```

Esperado: FALLA al compilar, sin llegar a correr ningún caso. La salida trae 11 errores distintos (líneas `Error:`), y los primeros dicen esto (las rutas pueden salir absolutas).

```text
test/HU36_jeff/specialty_test_perfil_test.dart:43:40: Error: Method not found: 'SpecialtyTestProfileCard'.
test/HU36_jeff/specialty_test_perfil_test.dart:78:25: Error: Undefined name 'SpecialtyTestProfileCard'.
```

- [ ] **Paso 3: Escribir la tarjeta y montarla en el Perfil**

La tarjeta pide el último resultado después del primer frame, como la del récord, y otra vez al volver de la ruta del test. Con el test no disponible devuelve `SizedBox.shrink()`, así que el espacio de arriba va dentro de ella. `dart format` corrige de paso la sangría de `NetworkingProfileEntryCard` en `perfil.dart`, que ya venía corrida un espacio.

Crea `lib/pages/specialty_test/specialty_test_profile_card.dart` con este contenido.

```dart
// lib/pages/specialty_test/specialty_test_profile_card.dart
// La tarjeta del test en «Configuración académica» del Perfil (RF-TEST-10).

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/skeleton.dart';
import '../../configs/themes.dart';
import '../../models/specialty_test_models.dart';
import '../../services/specialty_test_service.dart';
import 'specialty_test_controller.dart';
import 'specialty_test_logic.dart';
import 'specialty_test_page.dart';
import 'widgets/test_buttons.dart';
import 'widgets/ulises_bubble.dart';

/// El último resultado, un test a medias y el acceso para hacerlo o
/// rehacerlo. Sin maqueta, usa las piezas del resultado (decisión abierta
/// 16). La monta `perfil.dart` solo si `SpecialtyTestService` está
/// registrado. Con el test no disponible no aparece.
class SpecialtyTestProfileCard extends StatefulWidget {
  const SpecialtyTestProfileCard({super.key});

  static const Key skeletonKey = Key('tarjeta-test-esqueleto');
  static const String titulo = 'Test de especialidad';

  /// El ícono de una ganadora y la barra de una fila, por su clave.
  static Key iconoKey(String clave) => Key('icono-perfil-$clave');
  static Key barraKey(String clave) => Key('barra-perfil-$clave');

  @override
  State<SpecialtyTestProfileCard> createState() =>
      _SpecialtyTestProfileCardState();
}

class _SpecialtyTestProfileCardState extends State<SpecialtyTestProfileCard> {
  SpecialtyTestService get _s => SpecialtyTestService.to;

  @override
  void initState() {
    super.initState();
    // Después del frame, nunca durante build, como la tarjeta del récord.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _s.loadLastResult();
    });
  }

  Future<void> _abrirElTest() async {
    await Get.toNamed<Object?>(
      SpecialtyTestPage.ruta,
      arguments: SpecialtyTestPage.argumentos(OrigenDelTest.perfil),
    );
    // Si el test terminó, el service tiene el resultado marcado como viejo
    // y lo pide otra vez.
    if (mounted) await _s.loadLastResult();
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Obx(() {
      // Los Rx se leen siempre, para que el Obx quede suscrito a todos.
      final estado = _s.lastResultStatus;
      final resultado = _s.lastResult;
      final pausado = _s.paused;
      final contenido = _s.content;
      if (estado == LastResultStatus.notAvailable) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: MaterialTheme.cardBg(b),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: MaterialTheme.borderColor(b)),
          ),
          child: switch (estado) {
            LastResultStatus.loading => const SkeletonPulse(
              key: SpecialtyTestProfileCard.skeletonKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 140, height: 14),
                  SizedBox(height: 10),
                  SkeletonBox(width: double.infinity, height: 32),
                  SizedBox(height: 8),
                  SkeletonBox(width: double.infinity, height: 10),
                ],
              ),
            ),
            LastResultStatus.error => _Error(
              onRetry: () {
                _s.loadLastResult(force: true);
              },
            ),
            _ => _Contenido(
              resultado: estado == LastResultStatus.loaded ? resultado : null,
              pausado: pausado,
              contenido: contenido,
              onAbrir: _abrirElTest,
            ),
          },
        ),
      );
    });
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo({this.conUlises = false});

  final bool conUlises;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Row(
      children: [
        if (conUlises) ...[
          const UlisesAvatar(size: 28),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            SpecialtyTestProfileCard.titulo,
            style: TextStyle(
              color: MaterialTheme.textPrimary(b),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Titulo(),
        const SizedBox(height: 8),
        TestErrorMessage(
          text: 'No se pudo cargar tu último test.',
          onRetry: onRetry,
        ),
      ],
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({
    required this.resultado,
    required this.pausado,
    required this.contenido,
    required this.onAbrir,
  });

  final LastSpecialtyTestResult? resultado;
  final PausedSpecialtyTest? pausado;
  final SpecialtyTestContent? contenido;
  final VoidCallback onAbrir;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final gris = MaterialTheme.testMuted(b);
    final r = resultado;
    final p = pausado;
    final String boton;
    if (p != null) {
      boton = 'Seguir el test';
    } else if (r != null) {
      boton = 'Rehacer el test';
    } else {
      boton = 'Hacer el test';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Titulo(conUlises: r == null && p == null),
        if (r?.completedAt != null) ...[
          const SizedBox(height: 2),
          Text(
            'Hecho el ${fechaEnLima(r!.completedAt!)}',
            style: TextStyle(color: gris, fontSize: 12),
          ),
        ],
        const SizedBox(height: 10),
        if (p != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Tienes un test a medias, ${p.answeredQuestions} de '
              '${p.content.totalQuestions}.',
              style: TextStyle(
                color: MaterialTheme.textPrimary(b),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (r == null && p == null)
          Text(
            'Todavía no hiciste el test.',
            style: TextStyle(color: gris, fontSize: 13),
          ),
        if (r != null) ...[
          for (final w in r.winners)
            _FilaGanadora(entrada: w, contenido: contenido),
          for (final o in r.others)
            _FilaCompacta(entrada: o, contenido: contenido),
          if (r.isCurrentVersion == false)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'El test cambió desde que lo hiciste.',
                style: TextStyle(color: gris, fontSize: 12),
              ),
            ),
        ],
        const SizedBox(height: 10),
        TestPrimaryButton(label: boton, height: 48, onPressed: onAbrir),
      ],
    );
  }
}

/// El color de una especialidad del contenido, o null si no hay copia o no
/// se puede leer.
Color? _colorDe(SpecialtyTestContent? contenido, String clave, Brightness b) =>
    colorDeEspecialidad(contenido?.specialtyByKey(clave), b);

class _FilaGanadora extends StatelessWidget {
  const _FilaGanadora({required this.entrada, required this.contenido});

  final RankingEntry entrada;
  final SpecialtyTestContent? contenido;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final color = _colorDe(contenido, entrada.key, b);
    final baldosa = color == null
        ? MaterialTheme.testTaskTileBg(b)
        : tinte(color, MaterialTheme.cardBg(b), 0.14);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: baldosa,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                iconoDelTest(contenido?.specialtyByKey(entrada.key)?.icon),
                key: SpecialtyTestProfileCard.iconoKey(entrada.key),
                size: 19,
                color: colorQueSeLee(
                  color,
                  fondo: baldosa,
                  respaldo: MaterialTheme.iconoNaranja(b),
                  esTexto: false,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entrada.name,
              style: TextStyle(
                color: MaterialTheme.textPrimary(b),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${entrada.affinity} %',
            style: TextStyle(
              color: MaterialTheme.textPrimary(b),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaCompacta extends StatelessWidget {
  const _FilaCompacta({required this.entrada, required this.contenido});

  final RankingEntry entrada;
  final SpecialtyTestContent? contenido;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final barra =
        _colorDe(contenido, entrada.key, b) ?? MaterialTheme.testMuted(b);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entrada.name,
                  style: TextStyle(
                    color: MaterialTheme.textPrimary(b),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${entrada.affinity} %',
                style: TextStyle(
                  color: MaterialTheme.testMuted(b),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 4,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(color: MaterialTheme.testTrack(b)),
                  ),
                  FractionallySizedBox(
                    widthFactor: entrada.affinity / 100,
                    child: ColoredBox(
                      key: SpecialtyTestProfileCard.barraKey(entrada.key),
                      color: barra,
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

En `lib/pages/perfil/perfil.dart`, cambia este bloque, que aparece una sola vez,

```dart
import '../academic_record/record_profile_card.dart';
```

por este otro.

```dart
import '../academic_record/record_profile_card.dart';
import '../specialty_test/specialty_test_profile_card.dart';
```

En `lib/pages/perfil/perfil.dart`, cambia este bloque, que aparece una sola vez,

```dart
import '../../services/session_navigation.dart';
```

por este otro.

```dart
import '../../services/session_navigation.dart';
import '../../services/specialty_test_service.dart';
```

En `lib/pages/perfil/perfil.dart`, cambia este bloque, que aparece una sola vez,

```dart
        const _EspecialidadCard(),
      ],
```

por este otro.

```dart
        const _EspecialidadCard(),
        // RF-TEST-10, con la guarda de `logout()`, para que las pruebas que
        // montan el Perfil sin este service sigan pasando sin HTTP real.
        if (Get.isRegistered<SpecialtyTestService>())
          const SpecialtyTestProfileCard(),
      ],
```

- [ ] **Paso 4: Correr la prueba y ver que pasa**

```bash
cd "${REPO:?}"
TZ=UTC "${FLUTTER:?}" test --no-pub test/HU36_jeff/specialty_test_perfil_test.dart
```

Esperado: PASS, `+12: All tests passed!`.

- [ ] **Paso 5: Dar formato y analizar**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/pages/specialty_test/specialty_test_profile_card.dart \
  lib/pages/perfil/perfil.dart \
  test/HU36_jeff/specialty_test_perfil_test.dart
```

Esperado: `Formatted 3 files (1 changed)`.

```bash
cd "${REPO:?}"
"${FLUTTER:?}" analyze --no-pub
```

Esperado: `6 issues found.`, los 6 de la línea base y ninguno en un archivo de esta tarea.

- [ ] **Paso 6: Commit**

```bash
cd "${REPO:?}"
test "$(git branch --show-current)" = feat/test-especialidad-fe || echo 'PARAR: rama equivocada'
git status --short
git add lib/pages/specialty_test/specialty_test_profile_card.dart \
  lib/pages/perfil/perfil.dart \
  test/HU36_jeff/specialty_test_perfil_test.dart
git commit -m 'feat(specialty-test): el Perfil muestra el último resultado del test y el acceso para hacerlo, seguirlo o rehacerlo (RF-TEST-10)'
git log -1 --format='%an <%ae>'
git log -1 --format=%B | grep -qi '^co-authored-by:' && echo 'PARAR: el commit trae trailer'
```

Esperado: ningún `PARAR`. Antes del `git add`, `git status --short` lista solo los archivos de la tarea, y el autor es `Jeffangeloss <178797184+jeffangeloss@users.noreply.github.com>`.

---

### Tarea 17: Solo lo oficial en el Perfil y el id antiguo en caché

**Requisitos:** RF-TEST-14 (chip vacío, «Sin especialización seleccionada», catálogo fallido, hoja de «Editar» con la selección oficial).

**Archivos:**
- Modificar `lib/pages/perfil/perfil.dart` (dos imports, «Especialización», `_CatalogoFallido` y la hoja)
- Crear `test/HU36_jeff/perfil_especialidad_antigua_test.dart`

**Interfaces:**

- Consume `AuthService.catalogsFailed`, `officialSpecialtyIds` y
  `reloadCatalogs` (Tarea 7), `seleccionOficial` (Tarea 5) y
  `TestSecondaryButton` (Tarea 11).
- No produce nada nuevo para otras tareas. `getEspecialidadName`,
  `_PrincipalChip` y la malla no cambian.

- [ ] **Paso 1: Escribir la prueba que falla**

Usa un `AuthService` real sobre la API falsa y carga Roboto, porque el Perfil tiene filas que con la fuente de pruebas desbordan a 375 de ancho sin que haya desborde real. La sesión y los reintentos corren dentro de `tester.runAsync`, porque esperan futuros de verdad.

Crea `test/HU36_jeff/perfil_especialidad_antigua_test.dart` con este contenido.

```dart
// test/HU36_jeff/perfil_especialidad_antigua_test.dart
//
// Pruebas de widget de HU36, el test de especialidad, sobre lo oficial en el
// Perfil y el id antiguo en caché (RF-TEST-14, decisión 6).
// Pantalla: lib/pages/perfil/perfil.dart
//
// Datos inventados (datos_de_prueba.dart). El alumno de prueba es 20230001.
// El id 3 hace de especialidad antigua, porque no está en el catálogo
// oficial.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/malla_models.dart';
import 'package:ulima_plus/pages/perfil/perfil.dart';
import 'package:ulima_plus/services/academic_record_service.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/malla_service.dart';
import 'package:ulima_plus/services/storage_service.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'montaje_de_pantallas.dart';

const int _antigua = 3;

/// Un `AuthService` real sobre la API falsa, con la sesión puesta y los
/// catálogos cargados como en un registro recién hecho.
Future<AuthService> _sesion(
  ApiFalsaDelTest api, {
  int? principal,
  List<int>? intereses,
}) async {
  Get.put<StorageService>(AlmacenDePrueba());
  final auth = Get.put<AuthService>(AuthService(apiClient: api));
  await auth.adoptarSesion(
    token: 'token-de-prueba',
    user: alumno(principal: principal, intereses: intereses),
  );
  Get.put<MallaService>(MallaService());
  Get.put<AcademicRecordService>(
    AcademicRecordService(apiClient: ApiFalsaDelTest()),
  );
  return auth;
}

Future<void> _perfil(WidgetTester tester) async {
  await montarPantalla(tester, const ProfilePage());
  await tester.pump();
  await tester.scrollUntilVisible(
    find.text('Configuración académica'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
}

void main() {
  // Get.put de un GetxService agenda onReady con
  // Get.engine.addPostFrameCallback, que necesita el binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(cargarRoboto);
  setUp(Get.reset);
  tearDown(Get.reset);

  group('WIDGET · Solo lo oficial en «Especialización» (RF-TEST-14)', () {
    testWidgets('caso 1: un id antiguo no pinta ningún chip, vacío ni con '
        'nombre', (tester) async {
      await tester.runAsync(
        () => _sesion(
          ApiFalsaDelTest(),
          principal: _antigua,
          intereses: [kIdSi, _antigua],
        ),
      );
      await _perfil(tester);
      expect(find.text('Principal'), findsNothing);
      expect(find.text('También me interesa'), findsOneWidget);
      expect(find.text('Sistemas de Información'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is Text && w.data == ''),
        findsNothing,
      );
    });

    testWidgets('caso 2: solo con ids antiguos dice «Sin especialización '
        'seleccionada» en textSecondary', (tester) async {
      await tester.runAsync(
        () => _sesion(
          ApiFalsaDelTest(),
          principal: _antigua,
          intereses: [_antigua],
        ),
      );
      await _perfil(tester);
      expect(find.text('Sin especialización seleccionada'), findsOneWidget);
      expect(
        colorDeTexto(tester, 'Sin especialización seleccionada'),
        MaterialTheme.textSecondary(Brightness.light),
      );
    });

    testWidgets('caso 3: con el catálogo fallido, el aviso y «Reintentar», y '
        '«Editar» no abre la hoja', (tester) async {
      final api = ApiFalsaDelTest(
        especialidades: [
          http.ClientException('sin red'),
          http.ClientException('sin red'),
          especialidadesJson(),
        ],
      );
      await tester.runAsync(() => _sesion(api, intereses: [kIdSi]));
      await _perfil(tester);
      expect(
        find.text('No se pudieron cargar tus especialidades.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Editar'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Guardar'), findsNothing);
      await tester.runAsync(() async {
        await tester.tap(find.text('Reintentar'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      await tester.pump();
      expect(
        find.text('No se pudieron cargar tus especialidades.'),
        findsNothing,
      );
      expect(find.text('Sistemas de Información'), findsOneWidget);
    });

    testWidgets('caso 4: la hoja de «Editar» arranca con la selección oficial '
        'y su PUT no lleva el id antiguo', (tester) async {
      final api = ApiFalsaDelTest();
      await tester.runAsync(
        () => _sesion(api, principal: _antigua, intereses: [kIdTi, _antigua]),
      );
      await _perfil(tester);
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('Guardar'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      await tester.pumpAndSettle();
      expect(api.cuerposDeGuardado.single, {
        'primarySpecialtyId': null,
        'interestSpecialtyIds': [kIdTi],
      });
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('caso 5: getEspecialidadName y la malla no cambian: un id '
        'antiguo da un nombre vacío y sus electivos no aparecen', (
      tester,
    ) async {
      final auth = (await tester.runAsync(() => _sesion(ApiFalsaDelTest())))!;
      expect(auth.getEspecialidadName(_antigua), '');
      expect(auth.getEspecialidadName(kIdSw), 'Ingeniería de Software');
      final electivo = CourseNode(
        id: 'curso-prueba-a',
        code: 'E-PRUEBA-A',
        name: 'CURSO DE PRUEBA A',
        credits: 3,
        level: 8,
        prerequisites: const [],
        category: CourseCategory.elective,
        row: 0,
        specialties: const ['Ingeniería de Software'],
      );
      final malla = MallaService.to;
      expect(
        malla.electiveMatchesUserSpecialties(electivo, [_antigua]),
        isFalse,
      );
      expect(malla.electiveMatchesUserSpecialties(electivo, [kIdSw]), isTrue);
    });
  });
}
```

- [ ] **Paso 2: Correr la prueba y ver que falla**

Compila, porque todo lo que usa ya existe. El caso 5 pasa desde ya, porque fija lo que no cambia (`getEspecialidadName` y la malla).

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/HU36_jeff/perfil_especialidad_antigua_test.dart
```

Esperado: FALLA, con `+1 -4: Some tests failed.`

- [ ] **Paso 3: Cambiar «Especialización» y su hoja**

En `lib/pages/perfil/perfil.dart`, cambia este bloque, que aparece una sola vez,

```dart
import '../academic_record/record_profile_card.dart';
import '../specialty_test/specialty_test_profile_card.dart';
```

por este otro.

```dart
import '../academic_record/record_profile_card.dart';
import '../specialty_test/specialty_test_logic.dart';
import '../specialty_test/specialty_test_profile_card.dart';
import '../specialty_test/widgets/test_buttons.dart';
```

En `lib/pages/perfil/perfil.dart`, cambia este bloque, que aparece una sola vez,

```dart
              GestureDetector(
                onTap: () => _openSheet(context),
```

por este otro.

```dart
              GestureDetector(
                // Con el catálogo fallido la hoja no se abre (RF-TEST-14).
                onTap: () {
                  if (!auth.catalogsFailed) _openSheet(context);
                },
```

En `lib/pages/perfil/perfil.dart`, cambia este bloque, que aparece una sola vez,

```dart
          Obx(() {
            final user = auth.currentUser;
            final principal = user?.especialidadPrincipal;
            final interes = user?.especialidadesInteres ?? [];
```

por este otro.

```dart
          Obx(() {
            final user = auth.currentUser;
            // Con el catálogo fallido no se sabe qué es oficial (RF-TEST-14).
            if (auth.catalogsFailed) {
              return _CatalogoFallido(onRetry: auth.reloadCatalogs);
            }
            // Solo los ids oficiales, así que un id antiguo nunca pinta un
            // chip vacío.
            final seleccion = seleccionOficial(
              principal: user?.especialidadPrincipal,
              intereses: user?.especialidadesInteres ?? const <int>[],
              oficiales: auth.officialSpecialtyIds,
            );
            final principal = seleccion.principal;
            final interes = seleccion.intereses;
```

En `lib/pages/perfil/perfil.dart`, cambia este bloque, que aparece una sola vez,

```dart
                'Sin especialización seleccionada',
                style: TextStyle(
                  color: MaterialTheme.placeholderText(brightness),
```

por este otro.

```dart
                'Sin especialización seleccionada',
                style: TextStyle(
                  // `placeholderText` daba 2,32:1 (RF-TEST-14).
                  color: MaterialTheme.textSecondary(brightness),
```

En `lib/pages/perfil/perfil.dart`, cambia este bloque, que aparece una sola vez,

```dart
class _PrincipalChip extends StatelessWidget {
```

por este otro.

```dart
/// «No se pudieron cargar tus especialidades.» con «Reintentar», que vuelve
/// a pedir los catálogos (RF-TEST-14).
class _CatalogoFallido extends StatelessWidget {
  const _CatalogoFallido({required this.onRetry});

  final Future<bool> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'No se pudieron cargar tus especialidades.',
          style: TextStyle(
            color: MaterialTheme.textPrimary(brightness),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        TestSecondaryButton(label: 'Reintentar', onPressed: onRetry),
      ],
    );
  }
}

class _PrincipalChip extends StatelessWidget {
```

En `lib/pages/perfil/perfil.dart`, cambia este bloque, que aparece una sola vez,

```dart
    final user = AuthService.to.currentUser;
    _principal = user?.especialidadPrincipal;
    _interes = Set.of(user?.especialidadesInteres ?? []);
    // Sanear estado heredado inconsistente (principal duplicada como interés
    // por datos antiguos): el backend lo rechaza con 409 DUPLICATE_PRIMARY.
    if (_principal != null) _interes.remove(_principal);
```

por este otro.

```dart
    final user = AuthService.to.currentUser;
    // Arranca con la selección oficial (RF-TEST-14), así que un id antiguo
    // nunca viaja en el PUT, que con BR-AP-07 daría 404 SPECIALTY_NOT_FOUND.
    // La función saca además la principal de los intereses, que el backend
    // rechaza con 409 DUPLICATE_PRIMARY.
    final seleccion = seleccionOficial(
      principal: user?.especialidadPrincipal,
      intereses: user?.especialidadesInteres ?? const <int>[],
      oficiales: AuthService.to.officialSpecialtyIds,
    );
    _principal = seleccion.principal;
    _interes = Set.of(seleccion.intereses);
```

- [ ] **Paso 4: Correr la prueba y ver que pasa**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/HU36_jeff/perfil_especialidad_antigua_test.dart
```

Esperado: PASS, `+5: All tests passed!`.

- [ ] **Paso 5: Dar formato y analizar**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/pages/perfil/perfil.dart \
  test/HU36_jeff/perfil_especialidad_antigua_test.dart
```

Esperado: `Formatted 2 files (0 changed)`.

```bash
cd "${REPO:?}"
"${FLUTTER:?}" analyze --no-pub
```

Esperado: `6 issues found.`, los 6 de la línea base y ninguno en un archivo de esta tarea.

- [ ] **Paso 6: Correr las pruebas que montan el Perfil**

El Perfil también lo montan la tarjeta del récord y la pestaña de chats.

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/HU34_jeff/record_card_test.dart \
  test/HU23_jeff/chats_pestana_test.dart \
  test/HU36_jeff/specialty_test_perfil_test.dart \
  test/HU36_jeff/perfil_especialidad_antigua_test.dart
```

Esperado: PASS, `+75: All tests passed!`.

- [ ] **Paso 7: Commit**

```bash
cd "${REPO:?}"
test "$(git branch --show-current)" = feat/test-especialidad-fe || echo 'PARAR: rama equivocada'
git status --short
git add lib/pages/perfil/perfil.dart \
  test/HU36_jeff/perfil_especialidad_antigua_test.dart
git commit -m 'feat(specialty-test): el Perfil pinta solo las especialidades oficiales y avisa cuando el catálogo no carga (RF-TEST-14)'
git log -1 --format='%an <%ae>'
git log -1 --format=%B | grep -qi '^co-authored-by:' && echo 'PARAR: el commit trae trailer'
```

Esperado: ningún `PARAR`. Antes del `git add`, `git status --short` lista solo los archivos de la tarea, y el autor es `Jeffangeloss <178797184+jeffangeloss@users.noreply.github.com>`.

---

### Tarea 18: El asistente con el test como paso central

**Requisitos:** RF-TEST-1 entero (sin el paso «Decisión», precarga, vuelta de la ruta, estados de catálogo, atrás, botón, cabecera, modo oscuro y binding) y la selección oficial del asistente de RF-TEST-14.

**Archivos:**
- Crear `lib/pages/setup_carrera/setup_carrera_binding.dart`
- Reemplazar `lib/pages/setup_carrera/setup_carrera_controller.dart` y `lib/pages/setup_carrera/setup_carrera_page.dart`
- Modificar `lib/main.dart` (import y binding de `/setup-carrera`)
- Crear `test/HU36_jeff/setup_carrera_flujo_test.dart`

**Interfaces:**

- Consume `SpecialtyTestService.prefetchContent` (Tarea 6),
  `SpecialtyTestPage.ruta`, `argumentos` y `SalidaDelTest` (Tareas 8 y 15),
  `seleccionOficial` (Tarea 5), `AuthService.catalogsFailed` y
  `reloadCatalogs` (Tarea 7) y `TestPrimaryButton` y `TestErrorMessage`
  (Tarea 11).
- Produce lo que sigue.

```dart
enum SetupStep { carrera, seleccion }        // sale `decision`
class SetupCarreraController extends GetxController {
  SetupCarreraController({Future<Object?> Function()? abrirTest});
  bool get catalogoFallido;
  Future<void> continuar(); void irASeleccion(); void volverACarrera();
  Future<void> reintentarCatalogos(); }       // salen chooseSi, chooseNoSe,
                                              // chooseExplorar, goToDecision
class SetupCarreraBinding extends Bindings { }
```

Salen `SpecialtyDecision`, `decision`, `_DecisionStep` y `_DecisionCard`.
`setPrincipal`, `toggleInteres` y `finish` siguen igual.

- [ ] **Paso 1: Escribir la prueba que falla**

El caso 3 atrapa `SystemNavigator.pop` en el canal de la plataforma. En la carrera el atrás del sistema sale de la app, porque el asistente es la única ruta de la pila, y en la selección vuelve a la carrera.

Crea `test/HU36_jeff/setup_carrera_flujo_test.dart` con este contenido.

```dart
// test/HU36_jeff/setup_carrera_flujo_test.dart
//
// Pruebas de widget de HU36, el test de especialidad, sobre el asistente con
// el test como paso central (RF-TEST-1) y la selección oficial (RF-TEST-14).
// Pantalla: lib/pages/setup_carrera/
//
// Datos inventados (datos_de_prueba.dart). El alumno de prueba es 20230001.
// El id 3 hace de especialidad antigua.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/pages/setup_carrera/setup_carrera_binding.dart';
import 'package:ulima_plus/pages/setup_carrera/setup_carrera_controller.dart';
import 'package:ulima_plus/pages/setup_carrera/setup_carrera_page.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';
import 'package:ulima_plus/services/storage_service.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'montaje_de_pantallas.dart';

/// Un `AuthService` real sobre [api], con la sesión y los catálogos
/// puestos, y el service del test registrado.
Future<void> _sesion(
  WidgetTester tester,
  ApiFalsaDelTest api, {
  int? principal,
  List<int>? intereses,
}) async {
  await tester.runAsync(() async {
    Get.put<StorageService>(AlmacenDePrueba());
    final auth = Get.put<AuthService>(AuthService(apiClient: api));
    await auth.adoptarSesion(
      token: 'token-de-prueba',
      user: alumno(
        principal: principal,
        intereses: intereses,
        setupComplete: false,
      ),
    );
  });
  Get.put<SpecialtyTestService>(SpecialtyTestService(apiClient: api));
}

/// Monta el asistente con un [abrirTest] falso que devuelve [salida].
Future<SetupCarreraController> _asistente(
  WidgetTester tester, {
  Object? salida,
  Brightness brillo = Brightness.light,
}) async {
  final c = Get.put<SetupCarreraController>(
    SetupCarreraController(abrirTest: () async => salida),
  );
  await montarPantalla(tester, const SetupCarreraPage(), brillo: brillo);
  await tester.pump();
  return c;
}

void main() {
  // Get.put de un GetxService agenda onReady con
  // Get.engine.addPostFrameCallback, que necesita el binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(cargarRoboto);
  setUp(Get.reset);
  tearDown(Get.reset);

  group('WIDGET · El asistente con el test (RF-TEST-1)', () {
    testWidgets('caso 1: carrera, test y selección manual, sin el paso '
        '«Decisión»', (tester) async {
      await _sesion(tester, ApiFalsaDelTest());
      final c = await _asistente(tester, salida: SalidaDelTest.seleccionManual);
      expect(find.text('Tu carrera'), findsOneWidget);
      expect(find.text('Carrera de Prueba'), findsOneWidget);
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      expect(c.step.value, SetupStep.seleccion);
      expect(find.text('Especialización principal'), findsOneWidget);
      for (final texto in [
        'Sí, quiero elegir ahora',
        'Todavía no estoy seguro',
        'Quiero explorar primero',
        'Opcional. Puedes elegirla ahora, explorarla o decidirlo luego desde '
            'tu perfil.',
      ]) {
        expect(find.text(texto), findsNothing);
      }
    });

    testWidgets('caso 2: la pausa o el atrás del test dejan al alumno en la '
        'carrera', (tester) async {
      await _sesion(tester, ApiFalsaDelTest());
      final c = await _asistente(tester);
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      expect(c.step.value, SetupStep.carrera);
    });

    testWidgets('caso 3: el atrás del sistema vuelve de la selección a la '
        'carrera, y en la carrera sale de la app', (tester) async {
      final salidas = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (llamada) async {
          salidas.add(llamada.method);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await _sesion(tester, ApiFalsaDelTest());
      final c = await _asistente(tester, salida: SalidaDelTest.seleccionManual);
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(c.step.value, SetupStep.carrera);
      expect(salidas, isNot(contains('SystemNavigator.pop')));
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(salidas, contains('SystemNavigator.pop'));
    });

    testWidgets('caso 4: al montarse pide el contenido del test una sola vez', (
      tester,
    ) async {
      final api = ApiFalsaDelTest();
      await _sesion(tester, api);
      await _asistente(tester);
      await tester.pump();
      expect(api.getsDeContenido, 1);
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      expect(api.getsDeContenido, 1);
      expect(SpecialtyTestService.to.takePrefetch(), isNotNull);
    });

    testWidgets(
      'caso 5: la ruta tiene su binding y la página no hace Get.put',
      (tester) async {
        await _sesion(tester, ApiFalsaDelTest());
        SetupCarreraBinding().dependencies();
        expect(Get.isRegistered<SetupCarreraController>(), isTrue);
        expect(Get.isPrepared<SetupCarreraController>(), isTrue);
        await montarPantalla(tester, const SetupCarreraPage());
        expect(
          Get.find<SetupCarreraController>().step.value,
          SetupStep.carrera,
        );
      },
    );

    testWidgets('caso 6: sin catálogo, la carrera y la selección muestran su '
        'aviso con «Reintentar», y «Continuar» sigue activo', (tester) async {
      final api = ApiFalsaDelTest(
        especialidades: [
          http.ClientException('sin red'),
          http.ClientException('sin red'),
          http.ClientException('sin red'),
          especialidadesJson(),
        ],
      );
      await _sesion(tester, api);
      final c = await _asistente(tester, salida: SalidaDelTest.seleccionManual);
      expect(find.text('No pudimos cargar tu carrera.'), findsOneWidget);
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      expect(c.step.value, SetupStep.seleccion);
      expect(
        find.text('No pudimos cargar las especialidades.'),
        findsOneWidget,
      );
      await tester.runAsync(() async {
        await tester.tap(find.text('Reintentar'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      await tester.pump();
      expect(
        find.text('No pudimos cargar las especialidades.'),
        findsOneWidget,
      );
      await tester.runAsync(() async {
        await tester.tap(find.text('Reintentar'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      await tester.pump();
      expect(find.text('Ingeniería de Software'), findsOneWidget);
    });

    testWidgets('caso 7: «Finalizar configuración» cabe entero a 375 de '
        'ancho', (tester) async {
      await _sesion(tester, ApiFalsaDelTest(), intereses: [kIdSi]);
      await _asistente(tester, salida: SalidaDelTest.seleccionManual);
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      final texto = find.text('Finalizar configuración');
      expect(texto, findsOneWidget);
      expect(tester.takeException(), isNull);
      // Una sola línea, dentro del botón.
      expect(tester.getSize(texto).height, lessThan(30));
      expect(dentroDeLaPantalla(tester, texto), isTrue);
    });

    for (final brillo in Brightness.values) {
      testWidgets('caso 8: en ${brillo.name}, la cabecera va en headerColor '
          'con texto blanco y el resto en tokens', (tester) async {
        await _sesion(tester, ApiFalsaDelTest());
        await _asistente(tester, brillo: brillo);
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
        expect(scaffold.backgroundColor, MaterialTheme.pageBg(brillo));
        final cabecera = tester.widget<Container>(
          find
              .ancestor(
                of: find.text('Hola, Alumna'),
                matching: find.byType(Container),
              )
              .first,
        );
        expect(
          (cabecera.decoration! as BoxDecoration).color,
          MaterialTheme.headerColor(brillo),
        );
        expect(colorDeTexto(tester, 'Hola, Alumna'), Colors.white);
        expect(
          colorDeTexto(tester, 'Tu carrera'),
          MaterialTheme.textPrimary(brillo),
        );
        expect(
          colorDeTexto(tester, 'Carrera de Prueba'),
          MaterialTheme.textPrimary(brillo),
        );
      });
    }
  });

  group('WIDGET · La selección manual solo con lo oficial (RF-TEST-14)', () {
    testWidgets('caso 9: arranca con la selección oficial y su PUT no lleva '
        'el id antiguo', (tester) async {
      final api = ApiFalsaDelTest();
      await _sesion(tester, api, principal: 3, intereses: [kIdTi, 3]);
      final c = await _asistente(tester, salida: SalidaDelTest.seleccionManual);
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      expect(c.selectedPrincipal.value, isNull);
      expect(c.selectedInteres, {kIdTi});
      await tester.runAsync(() async {
        await tester.tap(find.text('Finalizar configuración'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      await tester.pump();
      expect(api.cuerposDeGuardado.single, {
        'primarySpecialtyId': null,
        'interestSpecialtyIds': [kIdTi],
      });
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('caso 10: solo muestra las especialidades activas del '
        'catálogo', (tester) async {
      final catalogo = especialidadesJson();
      (catalogo['specialties'] as List).add(<String, dynamic>{
        'id': 3,
        'carrera_id': 1,
        'name': 'ESPECIALIDAD ANTIGUA DE PRUEBA',
        'is_active': false,
        'display_order': 5,
      });
      await _sesion(tester, ApiFalsaDelTest(especialidades: [catalogo]));
      await _asistente(tester, salida: SalidaDelTest.seleccionManual);
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      expect(find.text('ESPECIALIDAD ANTIGUA DE PRUEBA'), findsNothing);
      expect(find.text('Desarrollo de Videojuegos'), findsOneWidget);
    });
  });
}
```

- [ ] **Paso 2: Correr la prueba y ver que falla**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/HU36_jeff/setup_carrera_flujo_test.dart
```

Esperado: FALLA al compilar, sin llegar a correr ningún caso. La salida trae 3 errores distintos (líneas `Error:`), y los primeros dicen esto (las rutas pueden salir absolutas).

```text
test/HU36_jeff/setup_carrera_flujo_test.dart:58:28: Error: No named parameter with the name 'abrirTest'.
test/HU36_jeff/setup_carrera_flujo_test.dart:152:9: Error: Method not found: 'SetupCarreraBinding'.
```

- [ ] **Paso 3: Escribir el binding y reemplazar el controlador y la página**

La página deja sus 40 hex por tokens de `MaterialTheme` y sus textos no cambian. La cabecera va en `headerColor` con el texto en blanco en los dos temas (decisión 9). El nombre de la especialidad elegida y sus rótulos van en `testAccentDeep` sobre `testAccentSoft` (8,25:1) y los de interés en `textSecondary` sobre `espInteresBg`, porque el naranja y el celeste de hoy no llegan a 4,5:1.

Crea `lib/pages/setup_carrera/setup_carrera_binding.dart` con este contenido.

```dart
// lib/pages/setup_carrera/setup_carrera_binding.dart
// El binding por ruta de /setup-carrera (RF-TEST-1).

import 'package:get/get.dart';

import 'setup_carrera_controller.dart';

/// Reemplaza el `Get.put` dentro de `build`, como pide la regla del repo que
/// recuerda `main.dart`.
class SetupCarreraBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SetupCarreraController>(() => SetupCarreraController());
  }
}
```

Reemplaza el contenido entero de `lib/pages/setup_carrera/setup_carrera_controller.dart` por este.

```dart
import 'package:get/get.dart';

import '../../services/auth_service.dart';
import '../../services/specialty_test_service.dart';
import '../specialty_test/specialty_test_controller.dart';
import '../specialty_test/specialty_test_logic.dart';
import '../specialty_test/specialty_test_page.dart';

/// Los pasos del asistente (RF-TEST-1). El test es una ruta aparte,
/// `/test-especialidad`, que se abre sobre el paso de carrera.
enum SetupStep { carrera, seleccion }

class SetupCarreraController extends GetxController {
  /// [abrirTest] solo lo pasan las pruebas. El asistente abre la ruta del
  /// test con el origen `asistente` y espera su salida.
  SetupCarreraController({Future<Object?> Function()? abrirTest})
    : _abrirTest = abrirTest ?? _abrirLaRutaDelTest;

  static Future<Object?> _abrirLaRutaDelTest() => Get.toNamed<Object?>(
    SpecialtyTestPage.ruta,
    arguments: SpecialtyTestPage.argumentos(OrigenDelTest.asistente),
  )!;

  final Future<Object?> Function() _abrirTest;

  final step = SetupStep.carrera.obs;
  final selectedPrincipal = RxnInt();
  final selectedInteres = <int>{}.obs;
  final saving = false.obs;
  final errorMessage = RxnString();

  AuthService get _auth => AuthService.to;

  String get selectedCarreraName => _auth.getCareerName(selectedCarreraId);

  int? get selectedCarreraId => _auth.currentUser?.careerId;

  /// El último intento de cargar los catálogos falló (RF-TEST-14).
  bool get catalogoFallido => _auth.catalogsFailed;

  List<Map<String, dynamic>> get especialidadesDisponibles {
    final cId = selectedCarreraId;
    if (cId == null) return const [];
    // El filtro `is_active` se queda como defensa (RF-TEST-14).
    final list = _auth.especialidades
        .where((e) => e['carrera_id'] == cId && e['is_active'] == true)
        .toList();
    list.sort((a, b) {
      final oA = (a['display_order'] as num?)?.toInt() ?? 999;
      final oB = (b['display_order'] as num?)?.toInt() ?? 999;
      return oA.compareTo(oB);
    });
    return list;
  }

  @override
  void onInit() {
    super.onInit();
    _cargarSeleccionOficial();
    // La precarga del test, una sola vez al montarse (RF-TEST-1). Un fallo
    // no se muestra en el paso de carrera.
    if (Get.isRegistered<SpecialtyTestService>()) {
      SpecialtyTestService.to.prefetchContent();
    }
  }

  /// La selección del alumno, solo con ids oficiales (RF-TEST-14).
  void _cargarSeleccionOficial() {
    final u = _auth.currentUser;
    final seleccion = seleccionOficial(
      principal: u?.especialidadPrincipal,
      intereses: u?.especialidadesInteres ?? const <int>[],
      oficiales: _auth.officialSpecialtyIds,
    );
    selectedPrincipal.value = seleccion.principal;
    selectedInteres.assignAll(seleccion.intereses);
  }

  /// «Continuar» del paso de carrera abre el test. Saltarlo, o un test no
  /// disponible, deja la selección manual, y la pausa y el atrás dejan al
  /// alumno aquí. Elegir o decidir después terminan el asistente desde la
  /// ruta del test.
  Future<void> continuar() async {
    final salida = await _abrirTest();
    if (isClosed) return;
    if (salida == SalidaDelTest.seleccionManual) irASeleccion();
  }

  void irASeleccion() {
    _cargarSeleccionOficial();
    step.value = SetupStep.seleccion;
  }

  /// El atrás del sistema en la selección manual.
  void volverACarrera() => step.value = SetupStep.carrera;

  /// «Reintentar» de los estados de catálogo. Tras cargar, vuelve a leer la
  /// selección oficial.
  Future<void> reintentarCatalogos() async {
    if (await _auth.reloadCatalogs()) _cargarSeleccionOficial();
  }

  void setPrincipal(int id) {
    if (selectedPrincipal.value == id) {
      selectedPrincipal.value = null;
    } else {
      selectedPrincipal.value = id;
      selectedInteres.remove(id);
    }
  }

  void toggleInteres(int id) {
    if (selectedPrincipal.value == id) return;
    if (selectedInteres.contains(id)) {
      selectedInteres.remove(id);
    } else {
      selectedInteres.add(id);
    }
  }

  Future<void> finish() async {
    errorMessage.value = null;
    final cId = selectedCarreraId;
    if (cId == null) {
      errorMessage.value = 'No se pudo determinar tu carrera.';
      return;
    }
    saving.value = true;
    try {
      await _auth.completeSetup(
        careerId: cId,
        especialidadPrincipal: selectedPrincipal.value,
        especialidadesInteres: selectedInteres.toList(),
      );
      Get.offAllNamed('/home');
    } catch (e) {
      errorMessage.value = 'No pudimos guardar la configuración: $e';
    } finally {
      saving.value = false;
    }
  }
}
```

Reemplaza el contenido entero de `lib/pages/setup_carrera/setup_carrera_page.dart` por este.

```dart
// lib/pages/setup_carrera/setup_carrera_page.dart
// Asistente de configuración inicial (primer login), con la carrera, el test
// de especialidad, que es una ruta aparte, y la selección manual (RF-TEST-1).
// Los colores son tokens de MaterialTheme, en claro y en oscuro.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../configs/themes.dart';
import '../../services/auth_service.dart';
import '../specialty_test/widgets/test_buttons.dart';
import 'setup_carrera_controller.dart';

class SetupCarreraPage extends GetView<SetupCarreraController> {
  const SetupCarreraPage({super.key});

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final user = AuthService.to.currentUser;
    return Scaffold(
      backgroundColor: MaterialTheme.pageBg(b),
      body: SafeArea(
        child: Column(
          children: [
            _WizardHeader(name: user?.firstName ?? 'Alumno'),
            Expanded(
              child: Obx(() {
                switch (controller.step.value) {
                  case SetupStep.carrera:
                    // Sin PopScope, porque el asistente es la única ruta de
                    // la pila y el atrás del sistema sale de la app, como
                    // hoy.
                    return _CarreraStep(controller: controller);
                  case SetupStep.seleccion:
                    return PopScope(
                      canPop: false,
                      onPopInvokedWithResult: (didPop, _) {
                        if (!didPop) controller.volverACarrera();
                      },
                      child: _SeleccionStep(controller: controller),
                    );
                }
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

/// En `headerColor`, con el texto y el ícono en blanco en los dos temas, como
/// el header de la app (decisión 9).
class _WizardHeader extends StatelessWidget {
  const _WizardHeader({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: BoxDecoration(
        color: MaterialTheme.headerColor(b),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.13),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sparkles, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Hola, $name',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Antes de empezar, cuéntanos qué estás estudiando.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Paso 1: Carrera ───────────────────────────────────────────────────────────

class _CarreraStep extends StatelessWidget {
  const _CarreraStep({required this.controller});
  final SetupCarreraController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SectionLabel(
                  icon: LucideIcons.graduationCap,
                  title: 'Tu carrera',
                  subtitle: 'Se asigna automáticamente según tu cuenta ULima.',
                ),
                const SizedBox(height: 14),
                Obx(() {
                  // Sin catálogo, el aviso y «Reintentar» (RF-TEST-1). La
                  // carrera sale del usuario, así que «Continuar» sigue
                  // activo.
                  if (controller.catalogoFallido) {
                    return TestErrorMessage(
                      text: 'No pudimos cargar tu carrera.',
                      onRetry: controller.reintentarCatalogos,
                    );
                  }
                  return _TarjetaDeCarrera(
                    nombre: controller.selectedCarreraName,
                  );
                }),
              ],
            ),
          ),
        ),
        _BottomButton(
          label: 'Continuar',
          icon: LucideIcons.arrowRight,
          onPressed: controller.continuar,
        ),
      ],
    );
  }
}

class _TarjetaDeCarrera extends StatelessWidget {
  const _TarjetaDeCarrera({required this.nombre});
  final String nombre;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MaterialTheme.cardBg(b),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MaterialTheme.borderColor(b)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: MaterialTheme.specialtyBg(b),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              LucideIcons.graduationCap,
              color: MaterialTheme.iconoNaranja(b),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Carrera asignada',
                  style: TextStyle(
                    color: MaterialTheme.textSecondary(b),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nombre,
                  style: TextStyle(
                    color: MaterialTheme.textPrimary(b),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: MaterialTheme.tagBg(b),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: MaterialTheme.textSecondary(b),
                ),
                const SizedBox(width: 4),
                Text(
                  'Fija',
                  style: TextStyle(
                    color: MaterialTheme.textSecondary(b),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Paso 2: Selección manual ──────────────────────────────────────────────────

class _SeleccionStep extends StatelessWidget {
  const _SeleccionStep({required this.controller});
  final SetupCarreraController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final opciones = controller.especialidadesDisponibles;
      final fallo = controller.catalogoFallido;
      final principal = controller.selectedPrincipal.value;
      final intereses = controller.selectedInteres.toSet();
      final saving = controller.saving.value;

      return Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SectionLabel(
                    icon: LucideIcons.bookmark,
                    title: 'Especialización principal',
                    subtitle: 'Elige una mención como tu diploma principal.',
                  ),
                  const SizedBox(height: 16),
                  // Un catálogo que llega vacío por un fallo muestra el
                  // aviso en lugar de la lista en blanco (RF-TEST-1).
                  if (fallo && opciones.isEmpty)
                    TestErrorMessage(
                      text: 'No pudimos cargar las especialidades.',
                      onRetry: controller.reintentarCatalogos,
                    ),
                  ...opciones.map((esp) {
                    final id = int.tryParse(esp['id']?.toString() ?? '') ?? 0;
                    final name = esp['name'] as String;
                    final desc = esp['description'] as String? ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _EspecialidadCard(
                        name: name,
                        desc: desc,
                        isPrincipal: principal == id,
                        isInteres: intereses.contains(id),
                        onTapPrincipal: () => controller.setPrincipal(id),
                        onTapInteres: () => controller.toggleInteres(id),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  _ErrorBanner(controller: controller),
                ],
              ),
            ),
          ),
          _BottomButton(
            label: (principal == null && intereses.isEmpty)
                ? 'Saltar por ahora'
                : 'Finalizar configuración',
            icon: LucideIcons.arrowRight,
            onPressed: saving ? null : controller.finish,
            loading: saving,
          ),
        ],
      );
    });
  }
}

class _EspecialidadCard extends StatefulWidget {
  const _EspecialidadCard({
    required this.name,
    required this.desc,
    required this.isPrincipal,
    required this.isInteres,
    required this.onTapPrincipal,
    required this.onTapInteres,
  });

  final String name;
  final String desc;
  final bool isPrincipal;
  final bool isInteres;
  final VoidCallback onTapPrincipal;
  final VoidCallback onTapInteres;

  @override
  State<_EspecialidadCard> createState() => _EspecialidadCardState();
}

class _EspecialidadCardState extends State<_EspecialidadCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final active = widget.isPrincipal || widget.isInteres;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: widget.isPrincipal
            ? MaterialTheme.testAccentSoft(b)
            : widget.isInteres
            ? MaterialTheme.espInteresBg(b)
            : MaterialTheme.cardBg(b),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.isPrincipal
              ? MaterialTheme.testAccent(b)
              : widget.isInteres
              ? MaterialTheme.textSecondary(b)
              : MaterialTheme.borderColor(b),
          width: active ? 1.6 : 1,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: TextStyle(
                          color: widget.isPrincipal
                              ? MaterialTheme.testAccentDeep(b)
                              : MaterialTheme.textPrimary(b),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (widget.isPrincipal)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Principal',
                            style: TextStyle(
                              color: MaterialTheme.testAccentDeep(b),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else if (widget.isInteres)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Me interesa',
                            style: TextStyle(
                              color: MaterialTheme.textSecondary(b),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      _expanded
                          ? LucideIcons.chevronUp
                          : LucideIcons.chevronDown,
                      size: 16,
                      color: MaterialTheme.textMuted(b),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_expanded && widget.desc.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(
                widget.desc,
                style: TextStyle(
                  color: MaterialTheme.textSecondary(b),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          Divider(height: 1, thickness: 1, color: MaterialTheme.borderColor(b)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: _ActionChip(
                    label: widget.isPrincipal
                        ? 'Quitar principal'
                        : 'Principal',
                    icon: widget.isPrincipal ? LucideIcons.x : LucideIcons.star,
                    active: widget.isPrincipal,
                    onTap: widget.onTapPrincipal,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionChip(
                    label: widget.isInteres ? 'Quitar interés' : 'Me interesa',
                    icon: widget.isInteres ? LucideIcons.x : LucideIcons.heart,
                    active: widget.isInteres,
                    onTap: widget.isPrincipal ? null : widget.onTapInteres,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final disabled = onTap == null;
    final Color tinta;
    if (disabled) {
      tinta = MaterialTheme.chipDisabledText(b);
    } else if (active) {
      tinta = MaterialTheme.testAccentDeep(b);
    } else {
      tinta = MaterialTheme.chipInactiveText(b);
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active && !disabled
              ? MaterialTheme.testAccentSoft(b)
              : MaterialTheme.chipDisabledBg(b),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active && !disabled
                ? MaterialTheme.testAccent(b)
                : MaterialTheme.chipDisabledBorder(b),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: tinta),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: tinta,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Compartidos ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: MaterialTheme.specialtyBg(b),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: MaterialTheme.iconoNaranja(b), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: MaterialTheme.textPrimary(b),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: MaterialTheme.textSecondary(b),
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.controller});
  final SetupCarreraController controller;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Obx(() {
      final msg = controller.errorMessage.value;
      if (msg == null) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: MaterialTheme.testAccentSoft(b),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: MaterialTheme.testAccent(b)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              size: 16,
              color: MaterialTheme.testAccentDeep(b),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: TextStyle(
                  color: MaterialTheme.testAccentDeep(b),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// El botón inferior con el estilo del botón principal del test, a lo ancho,
/// con 52 px de alto y texto en tinta sobre naranja, así que «Finalizar
/// configuración» cabe entero.
class _BottomButton extends StatelessWidget {
  const _BottomButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: TestPrimaryButton(
          label: label,
          icon: icon,
          onPressed: onPressed,
          loading: loading,
        ),
      ),
    );
  }
}
```

- [ ] **Paso 4: Dar el binding a la ruta en main.dart**

En `lib/main.dart`, cambia este bloque, que aparece una sola vez,

```dart
import 'pages/setup_carrera/setup_carrera_page.dart';
```

por este otro.

```dart
import 'pages/setup_carrera/setup_carrera_binding.dart';
import 'pages/setup_carrera/setup_carrera_page.dart';
```

En `lib/main.dart`, cambia este bloque, que aparece una sola vez,

```dart
        GetPage(name: '/setup-carrera', page: () => const SetupCarreraPage()),
```

por este otro.

```dart
        // Asistente del alumno nuevo (RF-TEST-1). Binding por ruta, en lugar
        // del Get.put que tenía dentro de build.
        GetPage(
          name: '/setup-carrera',
          page: () => const SetupCarreraPage(),
          binding: SetupCarreraBinding(),
        ),
```

- [ ] **Paso 5: Correr la prueba y ver que pasa**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub test/HU36_jeff/setup_carrera_flujo_test.dart
```

Esperado: PASS, `+11: All tests passed!`.

- [ ] **Paso 6: Dar formato y analizar**

```bash
cd "${REPO:?}"
"${DART:?}" format lib/pages/setup_carrera/setup_carrera_binding.dart \
  lib/pages/setup_carrera/setup_carrera_controller.dart \
  lib/pages/setup_carrera/setup_carrera_page.dart \
  lib/main.dart \
  test/HU36_jeff/setup_carrera_flujo_test.dart
```

Esperado: `Formatted 5 files (0 changed)`.

```bash
cd "${REPO:?}"
"${FLUTTER:?}" analyze --no-pub
```

Esperado: `6 issues found.`, los 6 de la línea base y ninguno en un archivo de esta tarea.

- [ ] **Paso 7: Correr la suite completa**

Cambian `main.dart` y el asistente, al que lleva el login. `test/HU01_jeff/login_navigation_paths_test.dart` arma sus propias rutas y sigue igual.

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub
```

Esperado: PASS, `+1464: All tests passed!`, las `+1363` de la copia en `757a9af` más las 101 de `test/six_seven/` que trae `main` (ver «Línea base»).

- [ ] **Paso 8: Commit**

```bash
cd "${REPO:?}"
test "$(git branch --show-current)" = feat/test-especialidad-fe || echo 'PARAR: rama equivocada'
git status --short
git add lib/pages/setup_carrera/setup_carrera_binding.dart \
  lib/pages/setup_carrera/setup_carrera_controller.dart \
  lib/pages/setup_carrera/setup_carrera_page.dart \
  lib/main.dart \
  test/HU36_jeff/setup_carrera_flujo_test.dart
git commit -m 'feat(specialty-test): el asistente pasa de la carrera al test y a la selección manual, en claro y en oscuro (RF-TEST-1)'
git log -1 --format='%an <%ae>'
git log -1 --format=%B | grep -qi '^co-authored-by:' && echo 'PARAR: el commit trae trailer'
```

Esperado: ningún `PARAR`. Antes del `git add`, `git status --short` lista solo los archivos de la tarea, y el autor es `Jeffangeloss <178797184+jeffangeloss@users.noreply.github.com>`.

---

### Tarea 19: Cierre, documentos y verificación

**Requisitos:** La sección «Verificación» de la spec, los `[@test]` de cada requisito y «Cambios en otras specs».

**Archivos:**
- Modificar `specs/features/specialty-test/specialty-test.spec.md` (estado, `[@test]`, «Se crean», «Cambian» y «Pruebas por requisito»)
- Modificar `specs/features/academic-profile/academic-profile.spec.md` (estado de la enmienda)
- Modificar `docs/specs/feature-index.md` (filas 2 y 21)
- Modificar `docs/specs/api-contracts.md` (título de «Specialty Test»)

**Interfaces:**

- Consume todo lo anterior. No toca código.
- Produce la spec al día con lo implementado, sin cambiar ningún requisito.

- [ ] **Paso 1: Correr la verificación de la spec**

Estos son los comandos de «Verificación» de la spec. La carpeta del test corre también con `TZ=UTC`, para que la fecha de la tarjeta del Perfil no dependa de la zona del equipo.

```bash
cd "${REPO:?}"
"${DART:?}" format lib/models/specialty_test_models.dart \
  lib/services/specialty_test_service.dart \
  lib/services/auth_service.dart \
  lib/main.dart \
  lib/configs/themes.dart \
  lib/pages/perfil/perfil.dart \
  lib/pages/setup_carrera/setup_carrera_controller.dart \
  lib/pages/setup_carrera/setup_carrera_page.dart \
  lib/pages/setup_carrera/setup_carrera_binding.dart \
  lib/pages/specialty_test/ \
  test/HU36_jeff
```

Esperado: `Formatted 41 files (0 changed)`.

```bash
cd "${REPO:?}"
"${FLUTTER:?}" analyze --no-pub
```

Esperado: `6 issues found.`, los 6 de la línea base y ninguno en un archivo de esta tarea.

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test --no-pub
```

Esperado: PASS, `+1464: All tests passed!`, las `+1363` de la copia en `757a9af` más las 101 de `test/six_seven/` que trae `main` (ver «Línea base»).

```bash
cd "${REPO:?}"
TZ=UTC "${FLUTTER:?}" test --no-pub test/HU36_jeff
```

Esperado: PASS, `+241: All tests passed!`.

- [ ] **Paso 2: Poner la spec al día**

Sale la marca *(pendiente)* de los 18 `[@test]`, porque las pruebas ya existen (decisión abierta 21), y la spec suma los archivos que el plan agrega dentro de sus `targets`. Los dos textos de la decisión 5 no se suman aquí, porque «Textos nuevos» ya los trae con su nota de derivados menores.

En `specs/features/specialty-test/specialty-test.spec.md`, cambia este bloque, que aparece una sola vez,

```markdown
> Todos los `[@test]` apuntan a pruebas que se crean con la implementación y hoy no existen, así
> que cada uno lleva la marca *(pendiente)*, como en la spec del backend (decisión abierta 21).
```

por este otro.

```markdown
> Todos los `[@test]` apuntan a pruebas que ya existen en `test/HU36_jeff/`, así que ninguno
> lleva la marca *(pendiente)* (decisión abierta 21).
```

En `specs/features/specialty-test/specialty-test.spec.md`, cambia este bloque, que aparece una sola vez,

```markdown
> la `0012` y la `0013`. Pendiente de implementar.
```

por este otro.

```markdown
> la `0012` y la `0013`. Implementada en la rama `feat/test-especialidad-fe` según
> `docs/superpowers/plans/2026-09-25-specialty-test-app.md`. Falta el merge, que espera al
> backend desplegado con sus tres rutas y la `0014`, y la revisión manual en un iPhone SE.
```

En `specs/features/specialty-test/specialty-test.spec.md`, quita la marca *(pendiente)* que sigue a cada uno de los 18 enlaces `[@test]`, con un editor o con estos comandos.

```bash
cd "${REPO:?}"
perl -0pi -e 's/\Q` *(pendiente)*\E/`/g' specs/features/specialty-test/specialty-test.spec.md
grep -c '(pendiente)\*' specs/features/specialty-test/specialty-test.spec.md
```

donde el `grep` final cuenta 2, las dos menciones de la marca que no son un `[@test]`.

En `specs/features/specialty-test/specialty-test.spec.md`, cambia este bloque, que aparece una sola vez,

```markdown
Todas se crean con la implementación, en `test/HU36_jeff/`, y hoy no existen. Las pruebas de
widget usan un `ApiClient` falso y datos inventados, con el alumno de prueba 20230001.
```

por este otro.

```markdown
Todas están en `test/HU36_jeff/`, con los datos y los dobles que comparten
(`datos_de_prueba.dart`, `dobles_de_red.dart`, `dobles_del_controlador.dart` y
`montaje_de_pantallas.dart`). Las pruebas de widget usan un `ApiClient` falso y datos
inventados, con el alumno de prueba 20230001, y las que miden espacio cargan Roboto del SDK.
```

En `specs/features/specialty-test/specialty-test.spec.md`, cambia este bloque, que aparece una sola vez,

```markdown
| `lib/pages/specialty_test/widgets/task_icon.dart` |
```

por este otro.

```markdown
| `lib/pages/specialty_test/widgets/test_buttons.dart` | El botón principal, el secundario y el mensaje de error que comparten el test, la tarjeta del Perfil, el Perfil y el asistente |
| `lib/pages/specialty_test/widgets/task_icon.dart` |
```

En `specs/features/specialty-test/specialty-test.spec.md`, cambia este bloque, que aparece una sola vez,

```markdown
| `lib/services/auth_service.dart` | `isOfficialSpecialty`, `catalogsFailed`, `reloadCatalogs`, el parámetro opcional `timeout` de `completeSetup` y `clear()` del test en `logout()` |
```

por este otro.

```markdown
| `lib/services/auth_service.dart` | `isOfficialSpecialty` sobre `officialSpecialtyIds`, `catalogsFailed`, `reloadCatalogs`, el parámetro opcional `timeout` de `completeSetup`, `clear()` del test en `logout()` y el parámetro opcional `apiClient` del constructor, que solo usan las pruebas |
```

- [ ] **Paso 3: Poner al día la enmienda, el índice y el contrato**

En `specs/features/academic-profile/academic-profile.spec.md`, cambia este bloque, que aparece una sola vez,

```markdown
> aprobada por el dueño ese día junto con esa spec y pendiente de implementar.** Cambia el
> asistente de configuración y el Perfil (ver «Enmienda por el test de especialidad» al final).
> Hasta que se implemente, el código sigue el texto sin enmendar.
```

por este otro.

```markdown
> aprobada por el dueño ese día junto con esa spec e implementada en la rama
> `feat/test-especialidad-fe`.** Cambia el asistente de configuración y el Perfil (ver «Enmienda
> por el test de especialidad» al final). El código de esa rama sigue el texto enmendado.
```

En `specs/features/academic-profile/academic-profile.spec.md`, cambia este bloque, que aparece una sola vez,

```markdown
Del 2026-09-25, aprobada por el dueño ese día junto con la spec del test y pendiente de
implementar.
```

por este otro.

```markdown
Del 2026-09-25, aprobada por el dueño ese día junto con la spec del test e implementada en la
rama `feat/test-especialidad-fe`.
```

En `docs/specs/feature-index.md`, cambia este bloque, que aparece una sola vez,

```markdown
aprobada por el dueño ese día con la spec del test y pendiente de implementar**
```

por este otro.

```markdown
aprobada por el dueño ese día con la spec del test e implementada en la rama `feat/test-especialidad-fe`**
```

En `docs/specs/feature-index.md`, cambia este bloque, que aparece una sola vez,

```markdown
texto blanco en la cabecera del asistente. Pendiente de implementar.
```

por este otro.

```markdown
texto blanco en la cabecera del asistente. Implementada en la rama `feat/test-especialidad-fe`, pendiente del merge, que espera al backend desplegado con la `0014`, y de la revisión manual en un iPhone SE.
```

En `docs/specs/api-contracts.md`, cambia este bloque, que aparece una sola vez,

```markdown
## Specialty Test (test de especialidad), aprobado el 2026-09-25 y pendiente de implementar
```

por este otro.

```markdown
## Specialty Test (test de especialidad), aprobado el 2026-09-25 e implementado en la app en la rama `feat/test-especialidad-fe`
```

- [ ] **Paso 4: Revisar que los documentos no se contradicen**

Ninguna prueba nueva y ningún código. Son tres búsquedas, dos que deben salir vacías y una que confirma que la spec ya trae los dos textos de la decisión 5, para no sumarlos otra vez.

```bash
cd "${REPO:?}"
grep -n '(pendiente)\*' specs/features/specialty-test/specialty-test.spec.md | grep '@test'
grep -n 'Pendiente de implementar' specs/features/specialty-test/specialty-test.spec.md
grep -o '«Ver tu respuesta anterior»\|«1 electivo»' specs/features/specialty-test/specialty-test.spec.md | sort -u
```

Esperado: las dos primeras búsquedas no imprimen nada, y la tercera imprime «1 electivo» y «Ver tu respuesta anterior», una vez cada uno.

- [ ] **Paso 5: Commit**

```bash
cd "${REPO:?}"
test "$(git branch --show-current)" = feat/test-especialidad-fe || echo 'PARAR: rama equivocada'
git status --short
git add specs/features/specialty-test/specialty-test.spec.md \
  specs/features/academic-profile/academic-profile.spec.md \
  docs/specs/feature-index.md \
  docs/specs/api-contracts.md
git commit -m 'docs(specialty-test): la spec, la enmienda, el índice y el contrato dicen que la app implementa el test en la rama'
git log -1 --format='%an <%ae>'
git log -1 --format=%B | grep -qi '^co-authored-by:' && echo 'PARAR: el commit trae trailer'
```

Esperado: ningún `PARAR`. Antes del `git add`, `git status --short` lista solo los archivos de la tarea, y el autor es `Jeffangeloss <178797184+jeffangeloss@users.noreply.github.com>`.

---

## Lo que queda fuera del plan

Estos pasos de «Verificación» de la spec no los puede hacer un agente y quedan para el dueño, en este orden.

1. Desplegar el backend de la rama `feat/test-especialidad` con sus tres rutas y aplicar la `0014` en producción, con el respaldo y su permiso explícito en ese momento, como con la `0012` y la `0013`.
2. Recorrer la app contra el backend desplegado con una cuenta de prueba. Un test termina sin desempate y otro con dos, se elige una principal, se marca un corazón, se rehace el test desde el Perfil y ahí se ve el último resultado.
3. Revisar en un iPhone SE, en claro y en oscuro, el asistente, las 14 preguntas, un desempate, el resultado y la tarjeta del Perfil, y repetir con VoiceOver, con el texto más grande y con reducir movimiento.
4. Leer los dos textos de la decisión 5 del plan, que la spec lista en «Textos nuevos» como derivados menores.
5. Hacer el merge a `main`, que publica el APK.
