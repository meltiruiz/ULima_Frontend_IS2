# Bloques de horario propios (frontend) — Plan de implementación

> Estado de este plan. La rama `feat/bloques-horario-fe` lo ejecuta entero, y su código se
> aparta del texto de abajo en varios puntos, porque las revisiones de cada tarea y la
> revisión final corrigen defectos del propio plan. Cuando el plan y la rama no coinciden,
> mandan la spec (`specs/features/time-blocks/time-blocks.spec.md`) y el código de la rama,
> y una nueva ejecución coteja con ellos cada bloque de código antes de copiarlo. El plan ya
> incorpora el arreglo de `load()` de la Tarea 1 (`a1df656`) y la nota de `isoDate` del
> contrato (`05b747b`), pero conserva el código y la prosa anteriores a estos cinco desvíos.
> En la Tarea 3 (`4de67bb`), la prueba del reparto exige además que dos bloques que se
> cruzan nunca compartan columna. En la Tarea 4 (`747c677`), `_fechaDelDia` devuelve null
> con más de siete días sin `isoDate`, así que solo el ciclo sin semanas toma el día de la
> semana en la semana de hoy, y un ciclo con semanas servido por un backend sin RS-BE-36 no
> pinta bloques propios ni la línea de horas. En la Tarea 5 (`53b1a6c`), el botón de agregar
> no abre `/bloque` mientras `Get.isRegistered<TimeBlockFormController>()` sea true, porque
> get 4.7.3 borra ese controller recién al terminar la animación de salida, y la revisión
> final pone la misma guarda en «Editar el bloque» de la hoja de la Tarea 6 (`404a688`). En
> la Tarea 6 (`c824ff0`), cada acción de la hoja espera con un indicador sin texto que tapa
> el horario, una `DialogRoute` que no se cierra con atrás y que se quita con `removeRoute`.
> En la Tarea 7 (`bea7d45`), la línea de horas se oculta también cuando el total redondeado
> a un decimal da 0, y RF-BLQ-6 cambia su texto en la spec. La revisión final suma otros
> cambios. El service vuelve a pedir la ventana tras una recarga fallida o una escritura sin
> respuesta, y deja en sus reglas la que devuelve el servidor (`01fb2ec`). `numeroDeDia` de
> `time_block_conflicts.dart` reemplaza la copia del controller (`ccda4a4`), y elegir otra
> acción en la hoja quita el «Deshacer» anterior (`4505c13`). Dos pruebas que ya existían
> fijan ahora el borde de siete días y el borrado del formulario al cerrarse (`70ac5cc` y
> `64e43c2`). Con esos cambios, el service tiene 21 pruebas, la hoja 25 y `test/HU35_jeff/`
> 191, y las cifras de abajo quedan como historia de la ejecución. Por último, el plan trata
> la publicación del paquete de instalación de Android (APK) como un paso manual, y no lo
> es. `.github/workflows/build-apk.yml` compila y publica el APK de la landing en cada push
> a `main`, de modo que el merge de la rama es la publicación. Antes del merge hacen falta
> el backend en producción (con las rutas `/time-blocks/**`, la migración 0012 y el
> `isoDate`) y las respuestas del dueño, y todo lo que las tareas dejan para «antes de
> publicar» pasa a ser condición del merge.

> **Para agentes:** SUB-SKILL REQUERIDA: usa superpowers:subagent-driven-development (recomendado) o superpowers:executing-plans para ejecutar este plan tarea por tarea. Los pasos usan casillas (`- [ ]`).

**Objetivo:** Que la alumna registre en su horario bloques propios que se repiten por días de la semana, los vea junto a sus clases sin que se tapen, corrija un día suelto y lea cuántas horas le ocupan por semana, consumiendo el contrato `/time-blocks/me` del backend.
**Arquitectura:** Un `TimeBlocksService` (`GetxService` permanente) es el único que habla HTTP y guarda por dueño las reglas y la ventana de ocurrencias, con un modelo tipado cuyo `fromJson` conserva `null`. La validación, la detección de cruces y el reparto en columnas son funciones puras probadas aparte; el formulario de crear y editar es la ruta `/bloque` con su binding, y una hoja de acciones maneja las excepciones de un día. La pantalla de horario cambia solo lo que la funcionalidad obliga: cada día guarda su fecha exacta (`isoDate`, que manda el backend), una lista propia de ocurrencias en el controller (nunca en `_todasLasSecciones`) y la ventana del ciclo visible, del primer al último `isoDate`; el reparto lado a lado en `_courseBlock`, los días cancelados pintados tenues y con su texto, el domingo en la vista semanal, la rama del toque y la línea de horas que manda el servidor, en las dos vistas. `_timeToHours` no se toca y ninguna fecha se saca de `dateText`.
**Stack:** Flutter + Dart + GetX
**Spec:** `specs/features/time-blocks/time-blocks.spec.md` (y la contraparte en el otro repo)
**Repo y rama:** `$REPO` (el worktree de la rama; ver "Variables de los comandos"), rama `feat/bloques-horario-fe`

## Restricciones globales

- Español en comentarios, nombres de test y mensajes de commit.
- Commits: autor ya configurado en git, **sin** trailer Co-Authored-By. Un commit por tarea con `git add` explícito. Nada de push.
- Nada de código antes del **Paso 0 de la Tarea 1**: la spec tiene que estar aprobada por el dueño, en el chat, y con sus `targets` al día (AGENTS.md: «No implementes cambios funcionales sin spec aprobada»; «Implementa solo archivos incluidos en targets»).
- El worktree `.worktrees/avatar-fe` es compartido y ya alojó otras ramas; otra sesión puede cambiarle la rama. Antes de empezar y antes de cada `git commit`: `test "$(git branch --show-current)" = feat/bloques-horario-fe || echo 'PARAR: rama equivocada'` y `git status --short`, que solo puede listar los archivos de esa tarea. Después de cada commit: `git log -1 --format=%B | grep -qi '^co-authored-by:' && echo 'PARAR: el commit trae trailer'`; si sale, se corrige en el acto (`git log -1 --format=%B | grep -vi '^co-authored-by:' | git commit --amend -F -`, sin push) antes de la tarea siguiente.
- Repo PÚBLICO: ningún dato real. Alumna sintética `20230001` (la única cifra con forma de código de alumno), cursos inventados (`CURSO DE PRUEBA A`), secciones `80x`, y nada copiado de `test/HU31_jeff/fixtures/` ni de `spike-portal/`. Una segunda cuenta de prueba lleva un código que no puede ser real (`'alumna.b.test'`, como el `'docente.test'`).
- **Variables de los comandos.** El plan no fija rutas de una máquina concreta: si alguna vez se commitea en `docs/superpowers/plans/`, el repo es público. Los comandos usan dos variables:
  - `REPO`: la ruta absoluta del worktree donde está la rama `feat/bloques-horario-fe` (`git worktree list`, corrido desde el checkout del frontend, la muestra).
  - `FLUTTER`: el ejecutable `flutter` del SDK que indica el despacho (la CI usa 3.44.2; la máquina del dueño, 3.47.2).

  Cada llamada de shell empieza con `export REPO=… FLUTTER=…` (con los valores de esta máquina), porque las variables no sobreviven de una llamada a otra. Los comandos las usan como `cd "${REPO:?}"` y `"${FLUTTER:?}"`: si falta una, la llamada se corta con un error. Sin eso, un `cd` vacío deja la shell en `$HOME` y todo lo que sigue corre fuera del worktree. En las salidas esperadas, `$REPO` está en lugar de la ruta absoluta que imprime flutter.
- Pruebas: `"${FLUTTER:?}" test test/HU35_jeff/<archivo>`; análisis: `"${FLUTTER:?}" analyze`, sin issues nuevos (la línea base son 7, todos preexistentes: medirla al empezar la Tarea 1 y anotarla).
- Solo dobles escritos a mano (`extends ApiClient`, `extends AuthService`); nada de mockito ni mocktail; **sin dependencias nuevas** en `pubspec.yaml`, incluido cualquier paquete de selector de color.
- GetX: binding por ruta, nunca `Get.put` dentro de `build()`. HTTP solo en services; ningún widget lee JSON.
- Un dato que falta se omite; nunca se pinta un 0 inventado. Horas y fechas viajan como texto (`"HH:MM"`, `"YYYY-MM-DD"`), en hora de Lima.
- Texto visible: el que fija la spec. Cualquier texto nuevo se anota en el reporte para que el dueño lo lea antes de publicar.
- El `SkeletonPulse` anima sin fin: mientras haya un esqueleto en pantalla no se usa `pumpAndSettle`, sino `tester.pump()`.
- **Cifras de las pruebas.** Tras aplicar las decisiones finales del dueño (abajo), el código de las Tareas 1 a 7 se aplicó tal como está escrito, reemplazo por reemplazo, en una copia descartable del repo (fuera del worktree y sin git) y se corrió con Flutter 3.47.2. Cada ancla apareció una sola vez. Los rojos que se midieron dieron lo que dicen: los dos archivos que faltan en la Tarea 1, los 34 errores de compilación y el `+33 -13` de la Tarea 4, los 71 errores y el `+20 -3` de la Tarea 6, y los tres tipos de error de la Tarea 7. Por archivo: 19, 55, 46, 21, 23 y 21; `test/HU35_jeff/ test/HU31_jeff/` dio `+172`, `+193`, `+216` y `+237` al cerrar las Tareas 4, 5, 6 y 7; la suite completa, `+759`; `flutter analyze`, los 7 issues de la línea base. Los casos 18 y 19 del service llegan con la revisión de la Tarea 1, después de esa medición. El 19 de ese archivo se mide en el worktree, y `+172`, `+193`, `+216`, `+237` y `+759` resultan de sumar esos dos casos a la medida anterior, así que son cifras derivadas. El script de cierre de la Tarea 8 dio sus 7 rojos y después `OK`. Las notas en la cabecera de algunas tareas cuentan cómo se llegó hasta aquí. Si una corrida real da otra cifra, se compara prueba por prueba antes de seguir; nunca se ajusta una prueba para que cuadre.

## Decisiones finales del dueño (2026-09-21)

Las tareas las citan por su número. Ya están escritas en la spec, que el dueño aprueba entera en el Paso 0 de la Tarea 1, y no se reabren:

| | decisión | dónde |
|:--|:--|:--|
| D1 | Cada elemento de `days` de `GET /schedule/me/sessions` trae `isoDate` (`"YYYY-MM-DD"`, hora de Lima), o `null` si el ciclo no tiene semanas. La ventana que se pide es la del ciclo, del primer al último `isoDate` no nulo; sin ninguno, las cuatro semanas alrededor de hoy; si pasara de 120 días, 120 desde el lunes de la semana del día activo. Un bloque cae en un día por su `isoDate`, y solo si es `null` por el día de la semana en la semana de hoy. Nada se saca de `dateText` ni de `currentCycle`. | Tareas 1 (contrato), 4 y 7 |
| D2 | Un día cancelado se pinta en su hora normal, a 40 % de opacidad y con «Este día está cancelado», desde las excepciones de `GET /time-blocks/me` (el servidor no manda ocurrencias canceladas). Tocarlo abre la hoja con «Volver al patrón»; el «Deshacer» del aviso queda como atajo. | Tareas 4 y 6 |
| D3 | La línea de horas se oculta si el total de la semana es 0, igual que sin entrada o con `null`. | Tarea 7 |
| D4 | El tope de 20 cuenta todos los bloques guardados, vencidos incluidos; el mensaje de `TIME_BLOCK_LIMIT_REACHED` (lo escribe el backend) lo dice y sugiere borrar uno viejo. | Tarea 1 (contrato) |
| D5 | El backend agrega `PATCH` al CORS de `src/server.ts` en la tarea que crea las rutas. | Tarea 8 (reporte) |
| D6 | `weeks` trae una entrada por cada semana entre el lunes de `from` y el de `to`, con el total de la semana entera y `hours: 0` si no tiene nada. | Tareas 1 y 7 |
| D7 | Paleta en dos filas de seis; botón flotante abajo a la derecha; selectores con `helpText`, `cancelText` y `confirmText` en español (los meses quedan en inglés); cambiar la hora de un día no muestra el aviso de cruce; fechas de 2000-01-01 a 2099-12-31 en el servidor; excepciones canceladas con `startTime` y `endTime` en `null`. | Tareas 1, 5 y 6 |

## Estructura de archivos

| ruta | acción | responsabilidad |
|:---|:---|:---|
| `lib/models/time_block_model.dart` | crear | DTOs del contrato: regla, excepción y ocurrencia, con `fromJson`/`toJson` que conservan null |
| `lib/services/time_blocks_service.dart` | crear | `GetxService` permanente: estado único de bloques y ocurrencias; único que habla HTTP |
| `lib/pages/time_blocks/time_block_validators.dart` | crear | validadores puros que devuelven `String?` en español |
| `lib/pages/time_blocks/time_block_conflicts.dart` | crear | detección pura de cruces contra clases y contra otros bloques |
| `lib/pages/time_blocks/time_block_form_controller.dart` | crear | estado del formulario (crear y editar) |
| `lib/pages/time_blocks/time_block_form_binding.dart` | crear | binding por ruta |
| `lib/pages/time_blocks/time_block_form_page.dart` | crear | el formulario: nombre, color, días, horas, fechas |
| `lib/pages/time_blocks/time_block_actions_sheet.dart` | crear | hoja de acciones al tocar un bloque propio |
| `lib/pages/horario/horario_layout.dart` | crear | función pura del reparto en columnas de bloques simultáneos |
| `lib/pages/horario/horario.dart` | modificar | pintar bloques propios (y tenues los días cancelados), reparto en columnas, domingo en la vista semanal, rama del toque, línea de horas en las dos vistas |
| `lib/pages/horario/horario_controller.dart` | modificar | `isoDate` de cada día (`DaySchedule`), lista propia de ocurrencias, días cancelados, ventana del ciclo visible, horas de la semana activa |
| `lib/main.dart` | modificar | `Get.put` permanente del service y la ruta del formulario |
| `lib/services/api_client.dart` | modificar | `patchJson` (Tarea 1); fuera de los targets de hoy, se suma en el Paso 0 |
| `lib/services/auth_service.dart` | modificar | `logout()` vacía los bloques, como el récord en TT06 (Tarea 1); fuera de los targets de hoy, se suma en el Paso 0 |
| `specs/features/time-blocks/time-blocks.spec.md` | modificar | aprobación y targets (Paso 0 de la Tarea 1); «e implementada» y los `[@test]` que faltan (Tarea 8) |
| `specs/features/schedule/schedule.spec.md` | modificar | domingo en la vista semanal y toque de un bloque propio (Tarea 8) |
| `test/HU35_jeff/time_blocks_service_test.dart` | crear | modelo y service con dobles |
| `test/HU35_jeff/time_blocks_conflicto_test.dart` | crear | validadores y detección de cruces |
| `test/HU35_jeff/time_blocks_grilla_test.dart` | crear | reparto en columnas, ventana del ciclo, pintado (también de los días cancelados) y domingo |
| `test/HU35_jeff/time_blocks_form_test.dart` | crear | el formulario y su botón de entrada |
| `test/HU35_jeff/time_blocks_acciones_test.dart` | crear | la hoja de acciones y las excepciones |
| `test/HU35_jeff/time_blocks_horas_test.dart` | crear | la línea de horas semanales |
| `docs/specs/api-contracts.md`, `docs/specs/feature-index.md` | modificar | las rutas nuevas y el `isoDate` de los días (Tarea 1); la fila de la funcionalidad (Tarea 8) |

## Orden y cobertura

| requisito | tareas |
|:---|:---|
| RF-BLQ-1 (botón de agregar) | 5 |
| RF-BLQ-2 (formulario) | 2, 5 |
| RF-BLQ-3 (aviso de cruce) | 2, 5 |
| RF-BLQ-4 (fecha de cada día, pintado, días cancelados, reparto, domingo) | 3, 4 |
| RF-BLQ-5 (tocar un bloque, también un día cancelado) | 4, 6 |
| RF-BLQ-6 (horas de la semana, en las dos vistas) | 7 |
| RF-BLQ-7 (capa de datos, logout, ventana del ciclo) | 1, 4 |
| Contrato que se consume | 1 |
| Aprobación y targets de la spec | 1 (Paso 0) |
| Documentación | 1, 8 |

---

### Tarea 1: Modelo y capa de datos

**Archivos:**
- Modificar (Paso 0, con su propio commit y solo con el sí del dueño): `specs/features/time-blocks/time-blocks.spec.md:8-11` (targets) y `:15-16` (estado)
- Crear: `lib/models/time_block_model.dart`
- Crear: `lib/services/time_blocks_service.dart`
- Modificar: `lib/services/api_client.dart:99-104` (agregar `patchJson` justo antes de `deleteJson`)
- Modificar: `lib/services/auth_service.dart:16` (import) y `:397` (`logout()` vacía también los bloques, junto a la línea del récord)
- Modificar: `lib/main.dart:14-15` (import) y `lib/main.dart:69-71` (`Get.put` permanente). Los dos números son los de hoy: el Paso 3.d mete una línea, así que al llegar al 3.e ese segundo bloque ya está en `:70-72`. El ancla es literal, no el número.
- Modificar: `docs/specs/api-contracts.md:541` (última línea del archivo; la sección nueva va después) y `:228-234` (el ejemplo de `days` de `GET /schedule/me/sessions` gana `isoDate`, y una nota sobre el campo va antes de la de `asistenciaDisponible`, hoy `:265`). Se aplican en ese orden, así que el primer número sigue valiendo.
- Test: `test/HU35_jeff/time_blocks_service_test.dart`

**Interfaces:**
- Consume (del repo, sin cambios): `ApiClient({String? configuredBaseUrl})` con `Future<Map<String, dynamic>> getJson(String path, {String? token, Map<String, String?> query = const {}, bool suppressSessionExpiry = false})`, `Future<Map<String, dynamic>> postJson(String path, {required Map<String, dynamic> body, String? token})`, `Future<Map<String, dynamic>> putJson(String path, {required Map<String, dynamic> body, String? token})` y `Future<Map<String, dynamic>> deleteJson(String path, {String? token})` (`lib/services/api_client.dart:68-104`); `ApiException({required int statusCode, required String code, required String message, Object? details})` con `.message` (`lib/services/api_client.dart:10-25`); `AuthService.to.currentUser` → `UserModel?` (`lib/services/auth_service.dart:60`) con `.code` (`lib/models/user_model.dart:7`) y `.isTeacher` (`lib/models/user_model.dart:106`).
- Consume (del repo, con cambio en esta tarea): `ApiClient.patchJson` **no existe hoy** (`grep -rn "patchJson" lib/` no devuelve nada) y esta tarea lo agrega con el estilo exacto de `putJson`: `Future<Map<String, dynamic>> patchJson(String path, {required Map<String, dynamic> body, String? token})`. `putJson` sí existe (`api_client.dart:91-97`) y se usa tal cual. `AuthService.logout()` (`auth_service.dart:377-404`) ya vacía las cachés por usuario (TT06), con guarda `Get.isRegistered` para `AcademicRecordService` (`:397`); esta tarea suma la de `TimeBlocksService` con la misma guarda. La prueba lo hace correr con el mismo andamiaje que `test/HU02_jeff/user_cache_reset_test.dart` (un `StorageService` sin sesión guardada y `MallaService` registrado).
- Produce:
  ```dart
  // lib/models/time_block_model.dart
  class TimeBlockException {
    const TimeBlockException({required this.date, required this.status,
      required this.startTime, required this.endTime});
    final String date; final String status; // 'cancelled' | 'moved'
    final String? startTime; final String? endTime;
    factory TimeBlockException.fromJson(Object? json);
    Map<String, dynamic> toJson();
  }
  class TimeBlockRule {
    const TimeBlockRule({required this.id, required this.title, required this.colorHex,
      required this.daysOfWeek, required this.startTime, required this.endTime,
      required this.startDate, required this.endDate, required this.exceptions});
    final int id; final String title; final String colorHex;
    final List<int> daysOfWeek; final String startTime; final String endTime;
    final String startDate; final String endDate; final List<TimeBlockException> exceptions;
    static TimeBlockRule? tryFromJson(Object? json);   // null si falta id, horas o fechas
    factory TimeBlockRule.fromJson(Object? json);      // FormatException en ese caso
    Map<String, dynamic> toJson();
  }
  class TimeBlockOccurrence {
    const TimeBlockOccurrence({required this.blockId, required this.title, required this.colorHex,
      required this.date, required this.dayOfWeek, required this.startTime,
      required this.endTime, required this.moved});
    final int blockId; final String title; final String colorHex;
    final String date; final int dayOfWeek; final String startTime;
    final String endTime; final bool moved;
    static TimeBlockOccurrence? tryFromJson(Object? json);  // null si falta blockId, fecha u horas
    factory TimeBlockOccurrence.fromJson(Object? json);     // FormatException en ese caso
    Map<String, dynamic> toJson();
  }
  class TimeBlockWeek {
    const TimeBlockWeek({required this.weekStart, required this.hours});
    final String weekStart; final double? hours;
    factory TimeBlockWeek.fromJson(Object? json);
  }
  class TimeBlocksSnapshot {
    const TimeBlocksSnapshot({required this.occurrences, required this.weeks});
    final List<TimeBlockOccurrence> occurrences; final List<TimeBlockWeek> weeks;
    factory TimeBlocksSnapshot.fromJson(Object? json);
  }

  // lib/services/time_blocks_service.dart
  class TimeBlocksService extends GetxService {
    TimeBlocksService({ApiClient? apiClient});
    static TimeBlocksService get to => Get.find();
    static const Duration requestTimeout = Duration(seconds: 15);
    static const String genericErrorMessage = 'No se pudo guardar tu bloque. Inténtalo de nuevo.';
    List<TimeBlockRule> get blocks;  TimeBlocksSnapshot? get snapshot;
    bool get isLoading;  bool get hasError;
    Future<void> load({required String from, required String to, bool force = false});
    Future<void> reload();
    void clear();
    Future<TimeBlockRule> create(TimeBlockInput input);
    Future<TimeBlockRule> update(int id, TimeBlockInput input);
    Future<void> remove(int id);
    Future<void> setException(int id, String date,
        {required String status, String? startTime, String? endTime});
    Future<void> clearException(int id, String date);
  }
  class TimeBlockInput {
    const TimeBlockInput({required this.title, required this.colorHex,
      required this.daysOfWeek, required this.startTime, required this.endTime,
      required this.startDate, required this.endDate});
    final String title; final String colorHex; final List<int> daysOfWeek;
    final String startTime; final String endTime;
    final String startDate; final String endDate;
    Map<String, dynamic> toJson();
  }
  class TimeBlocksFailure implements Exception {
    const TimeBlocksFailure(this.message);
    final String message;
  }

  // lib/services/api_client.dart (método nuevo)
  Future<Map<String, dynamic>> patchJson(String path,
      {required Map<String, dynamic> body, String? token});
  ```

- [ ] **Paso 0: Aprobación del dueño y targets, antes de tocar código**

  La spec dice hoy «Pendiente de su aprobación de esta spec escrita antes de planificar» (`specs/features/time-blocks/time-blocks.spec.md:16`), y AGENTS.md prohíbe implementar sin spec aprobada (línea 3) y fuera de `targets` («Flujo Obligatorio», pasos 7 y 8). La rama va a tocar tres archivos de `lib/` que los `targets` no listan. Este paso no escribe código: **PARAR** y preguntarle al dueño **en el chat** estas dos cosas, y seguir solo con su sí explícito a las dos:

  1. ¿Aprueba la spec tal como está?
  2. ¿Aprueba sumar a sus `targets` los tres archivos que la rama toca fuera de la lista? Son `lib/pages/horario/horario_layout.dart` (la función pura del reparto en columnas, Tarea 3), `lib/services/api_client.dart` (la Tarea 1 le agrega `patchJson`, aditivo) y `lib/services/auth_service.dart` (la Tarea 1 hace que `logout()` vacíe también los bloques, como ya hace con el récord desde TT06).

  Sin el sí a las dos **no** se sigue con el Paso 1. La paleta del formulario ya no se pregunta: la spec fija dos filas de seis (RF-BLQ-2), que es lo que escribe la Tarea 5.

  La spec que se aprueba ya trae, sin commit en el árbol, los ajustes del 2026-09-21 (las decisiones D1 a D7 de arriba y la línea «Ajustada el 2026-09-21 …» del estado) y dos cambios más que no son decisiones D1 a D7. Uno es la cita corregida de `_weekDays` en «El domingo» de RF-BLQ-4, que pasa de `horario.dart:153-160` a `horario.dart:186-209` y explica que la lista de días termina en el sábado y su respaldo toma seis. El otro es la ubicación de la línea de horas en las dos vistas en RF-BLQ-6 (en la de día, debajo de la semana del ciclo; en la semanal, en la franja de abajo, junto al ciclo). `git status --short` muestra la spec modificada desde antes de este paso, y todo eso entra en el mismo commit. Si `git diff` de la spec muestra otra cosa que esos ajustes y esos dos cambios, **PARAR** y reportarlo.

  Con el sí, dos reemplazos en la spec y un commit propio. Ninguno toca código.

  **0.a — los targets** (`:8-11`). Reemplazar esto:

  ```markdown
    - ../../../lib/pages/horario/horario.dart
    - ../../../lib/pages/horario/horario_controller.dart
    - ../../../lib/main.dart
  ---
  ```

  por esto:

  ```markdown
    - ../../../lib/pages/horario/horario.dart
    - ../../../lib/pages/horario/horario_controller.dart
    - ../../../lib/pages/horario/horario_layout.dart
    - ../../../lib/services/api_client.dart
    - ../../../lib/services/auth_service.dart
    - ../../../lib/main.dart
  ---
  ```

  El precedente de `api_client.dart` en los targets es `specs/features/registro/registro.spec.md`.

  **0.b — el estado** (`:15-16`). Reemplazar esto:

  ```markdown
  > Estado: **diseñada con el dueño del proyecto el 2026-09-20**, sección por sección.
  > Pendiente de su aprobación de esta spec escrita antes de planificar.
  ```

  por esto, con `AAAA-MM-DD` cambiado por la fecha del día en que el dueño la aprobó en el chat (`TZ=America/Lima date +%F`):

  ```markdown
  > Estado: **diseñada con el dueño del proyecto el 2026-09-20**, sección por sección.
  > Aprobada por el dueño el AAAA-MM-DD, con los targets de arriba.
  ```

  La Tarea 8 le agrega «e implementada» a esa misma línea.

  Commit:

  ```bash
  cd "${REPO:?}"
  test "$(git branch --show-current)" = feat/bloques-horario-fe || echo 'PARAR: rama equivocada'
  git status --short
  git add specs/features/time-blocks/time-blocks.spec.md
  git commit -m "docs(time-blocks): la spec queda aprobada por el dueño, con los targets que la rama va a tocar

  Trae también los ajustes del 2026-09-21: la fecha exacta de cada día
  (isoDate), los días cancelados visibles, la línea de horas oculta en 0, el
  tope de 20 bloques guardados, las semanas enteras en weeks, y la paleta, los
  selectores y el cambio de hora de un día sin aviso de cruce."
  git log -1 --format=%B | grep -qi '^co-authored-by:' && echo 'PARAR: el commit trae trailer'
  ```

  Esperado: ningún `PARAR`, y `git status --short` antes del commit muestra solo `M specs/features/time-blocks/time-blocks.spec.md`. Sin trailer `Co-Authored-By`: el autor ya está configurado en git.

- [ ] **Paso 1: Escribir la prueba que falla**

  Antes de crear nada, con el árbol todavía sin tocar, confirmar la rama y medir y anotar la línea base de análisis (el esqueleto dice 7 issues preexistentes; hay que confirmarlo y guardar el número para el Paso 5 y para la Tarea 8):

  ```bash
  cd "${REPO:?}"
  test "$(git branch --show-current)" = feat/bloques-horario-fe || echo 'PARAR: rama equivocada'
  git status --short
  "${FLUTTER:?}" analyze 2>&1 | tail -12
  ```

  Si sale `PARAR: rama equivocada`, o `git status --short` lista algo, **PARAR** y reportarlo: otra sesión está usando el worktree.

  Esperado hoy: `7 issues found.`, todos `info` y ninguno en un archivo de esta tarea — `avoid_print` en `lib/main.dart:85`, tres `deprecated_member_use` (`lib/pages/chat/chat_page.dart:695`, `lib/services/attendance_risk_service.dart:55` dos veces), `unnecessary_import` en `test/HU20_jeff/otp_field_ime_test.dart:32` y dos `depend_on_referenced_packages` en `test/HU26_sam/export_csv_cajanegra_test.dart:20-21`.

  Después crear `test/HU35_jeff/time_blocks_service_test.dart` (la carpeta `test/HU35_jeff/` todavía no existe) con este contenido completo:

  ```dart
  // test/HU35_jeff/time_blocks_service_test.dart
  //
  // UNITARIA — HU35 (bloques de horario propios): modelo y capa de datos
  // (RF-BLQ-7 y la sección "Contrato que se consume" de la spec).
  // Modelo:   lib/models/time_block_model.dart
  // Servicio: lib/services/time_blocks_service.dart
  //
  // Datos inventados: la alumna 20230001 no existe, el bloque "PRÁCTICAS DE
  // PRUEBA" tampoco y las fechas son del ciclo de ejemplo de la spec. El
  // repositorio es público: nada de esto sale de un horario real.

  import 'dart:async';

  import 'package:flutter_test/flutter_test.dart';
  import 'package:get/get.dart';
  import 'package:ulima_plus/models/time_block_model.dart';
  import 'package:ulima_plus/models/user_model.dart';
  import 'package:ulima_plus/services/api_client.dart';
  import 'package:ulima_plus/services/auth_service.dart';
  import 'package:ulima_plus/services/malla_service.dart';
  import 'package:ulima_plus/services/storage_service.dart';
  import 'package:ulima_plus/services/time_blocks_service.dart';

  /// Ventana de cuatro semanas: 2026-09-21 es lunes y 2026-10-18 domingo.
  const String _desde = '2026-09-21';
  const String _hasta = '2026-10-18';

  UserModel _user({String code = '20230001', String role = 'student'}) =>
      UserModel(
        code: code,
        firstName: 'Alumna',
        lastName: 'De Prueba',
        email: 'test@aloe.ulima.edu.pe',
        role: role,
        currentCycle: '2026-2',
        setupComplete: true,
      );

  /// La regla tal como la manda `GET /time-blocks/me`. Los dos días de
  /// excepción (2026-10-07 y 2026-10-14) son miércoles, o sea que caen dentro
  /// del patrón [1, 3].
  Map<String, dynamic> _reglaJson({
    int id = 12,
    String titulo = 'PRÁCTICAS DE PRUEBA',
  }) =>
      <String, dynamic>{
        'id': id,
        'title': titulo,
        'colorHex': '#EB5757',
        'daysOfWeek': <dynamic>[1, 3],
        'startTime': '14:00',
        'endTime': '18:00',
        'startDate': '2026-09-01',
        'endDate': '2026-12-15',
        'exceptions': <dynamic>[
          // Una excepción cancelada llega con las dos horas en null, como en el
          // contrato del backend.
          <String, dynamic>{
            'date': '2026-10-07',
            'status': 'cancelled',
            'startTime': null,
            'endTime': null,
          },
          <String, dynamic>{
            'date': '2026-10-14',
            'status': 'moved',
            'startTime': '15:00',
            'endTime': '19:00',
          },
        ],
      };

  /// La lista de `GET /time-blocks/me`. La segunda entrada llega sin `id`: no
  /// es una regla que se pueda editar ni borrar, y el service la descarta en
  /// vez de guardarla con un id 0 (RF-BLQ-7).
  Map<String, dynamic> _bloquesJson() => <String, dynamic>{
        'blocks': <dynamic>[
          _reglaJson(),
          Map<String, dynamic>.from(_reglaJson(id: 99))..remove('id'),
        ],
      };

  Map<String, dynamic> _sinBloquesJson() =>
      <String, dynamic>{'blocks': <dynamic>[]};

  /// La ventana ya expandida por el servidor, recortada a dos ocurrencias: el
  /// lunes normal y el miércoles movido. `weeks` trae, como el backend, una
  /// entrada por cada semana de lunes a domingo de la ventana, con el total de
  /// la semana entera de la regla de [_reglaJson] (8 h; 4 h la del miércoles 7
  /// cancelado). La segunda llega sin horas (`null`): el backend no lo manda
  /// (una semana sin ocurrencias llega con 0), pero si llegara, el modelo lo
  /// conserva en null y la línea de RF-BLQ-6 no lo pinta como 0.
  Map<String, dynamic> _ocurrenciasJson() => <String, dynamic>{
        'occurrences': <dynamic>[
          <String, dynamic>{
            'blockId': 12,
            'title': 'PRÁCTICAS DE PRUEBA',
            'colorHex': '#EB5757',
            'date': '2026-09-21',
            'dayOfWeek': 1,
            'startTime': '14:00',
            'endTime': '18:00',
            'moved': false,
          },
          <String, dynamic>{
            'blockId': 12,
            'title': 'PRÁCTICAS DE PRUEBA',
            'colorHex': '#EB5757',
            'date': '2026-10-14',
            'dayOfWeek': 3,
            'startTime': '15:00',
            'endTime': '19:00',
            'moved': true,
          },
        ],
        'weeks': <dynamic>[
          <String, dynamic>{'weekStart': '2026-09-21', 'hours': 8},
          <String, dynamic>{'weekStart': '2026-09-28', 'hours': null},
          <String, dynamic>{'weekStart': '2026-10-05', 'hours': 4},
          <String, dynamic>{'weekStart': '2026-10-12', 'hours': 8},
        ],
      };

  Map<String, dynamic> _sinOcurrenciasJson() => <String, dynamic>{
        'occurrences': <dynamic>[],
        'weeks': <dynamic>[],
      };

  TimeBlockInput _entrada() => const TimeBlockInput(
        title: 'PRÁCTICAS DE PRUEBA',
        colorHex: '#EB5757',
        // Desordenados a propósito: toJson los manda ordenados.
        daysOfWeek: <int>[3, 1],
        startTime: '14:00',
        endTime: '18:00',
        startDate: '2026-09-01',
        endDate: '2026-12-15',
      );

  class _FakeAuthService extends AuthService {
    _FakeAuthService(UserModel? user) : userRx = Rx<UserModel?>(user);

    final Rx<UserModel?> userRx;

    @override
    UserModel? get currentUser => userRx.value;

    @override
    Rx<UserModel?> get currentUserRx => userRx;

    @override
    Future<void> refreshCurrentUser() async {}
  }

  /// Lo mínimo para que `AuthService.logout()` corra en la prueba, como en
  /// test/HU02_jeff/user_cache_reset_test.dart: no hay token guardado (no sale
  /// el POST /auth/logout) y limpiar la sesión no hace nada.
  class _SinSesionGuardada extends StorageService {
    @override
    Future<String?> get savedToken async => null;

    @override
    Future<void> clearSession() async {}
  }

  class _FakeBlocksApi extends ApiClient {
    _FakeBlocksApi({List<Object>? bloques, List<Object>? ocurrencias})
        : _bloques = bloques ?? <Object>[_bloquesJson()],
          _ocurrencias = ocurrencias ?? <Object>[_ocurrenciasJson()],
          super(configuredBaseUrl: 'http://test');

    /// Respuestas en orden; la última se repite. Un Map se devuelve, un
    /// Completer se espera y cualquier otra cosa se lanza.
    final List<Object> _bloques;
    final List<Object> _ocurrencias;

    int getBloques = 0;
    int getOcurrencias = 0;
    Map<String, String?> ultimaVentana = const <String, String?>{};

    /// "VERBO /ruta" de cada escritura, en orden.
    final List<String> escrituras = <String>[];
    final List<Map<String, dynamic>> cuerpos = <Map<String, dynamic>>[];
    Object? errorDeEscritura;

    Future<Map<String, dynamic>> _responder(List<Object> cola, int indice) {
      final r = cola[indice < cola.length ? indice : cola.length - 1];
      if (r is Completer<Map<String, dynamic>>) return r.future;
      if (r is Map<String, dynamic>) {
        return Future<Map<String, dynamic>>.value(r);
      }
      return Future<Map<String, dynamic>>.error(r);
    }

    Future<Map<String, dynamic>> _escribir(
      String llamada, {
      Map<String, dynamic>? body,
      required Map<String, dynamic> respuesta,
    }) {
      escrituras.add(llamada);
      if (body != null) cuerpos.add(body);
      if (errorDeEscritura != null) {
        return Future<Map<String, dynamic>>.error(errorDeEscritura!);
      }
      return Future<Map<String, dynamic>>.value(respuesta);
    }

    @override
    Future<Map<String, dynamic>> getJson(
      String path, {
      String? token,
      Map<String, String?> query = const {},
      bool suppressSessionExpiry = false,
    }) {
      if (path == '/time-blocks/me/occurrences') {
        ultimaVentana = query;
        return _responder(_ocurrencias, getOcurrencias++);
      }
      return _responder(_bloques, getBloques++);
    }

    @override
    Future<Map<String, dynamic>> postJson(
      String path, {
      required Map<String, dynamic> body,
      String? token,
    }) =>
        _escribir(
          'POST $path',
          body: body,
          respuesta: <String, dynamic>{'block': _reglaJson()},
        );

    @override
    Future<Map<String, dynamic>> patchJson(
      String path, {
      required Map<String, dynamic> body,
      String? token,
    }) =>
        _escribir(
          'PATCH $path',
          body: body,
          respuesta: <String, dynamic>{
            'block': _reglaJson(titulo: 'PRÁCTICAS EDITADAS'),
          },
        );

    @override
    Future<Map<String, dynamic>> putJson(
      String path, {
      required Map<String, dynamic> body,
      String? token,
    }) =>
        _escribir(
          'PUT $path',
          body: body,
          respuesta: <String, dynamic>{
            'exception': <String, dynamic>{
              'date': '2026-10-14',
              'status': 'moved',
              'startTime': '15:00',
              'endTime': '19:00',
            },
          },
        );

    @override
    Future<Map<String, dynamic>> deleteJson(String path, {String? token}) =>
        _escribir(
          'DELETE $path',
          respuesta: <String, dynamic>{'ok': true},
        );
  }

  _FakeAuthService _loguear(UserModel? user) {
    final auth = _FakeAuthService(user);
    Get.put<AuthService>(auth);
    return auth;
  }

  TimeBlocksService _servicio(_FakeBlocksApi api) =>
      Get.put<TimeBlocksService>(TimeBlocksService(apiClient: api));

  void main() {
    // Get.put de un GetxService agenda onReady con
    // Get.engine.addPostFrameCallback, que necesita el binding.
    TestWidgetsFlutterBinding.ensureInitialized();

    setUp(Get.reset);
    tearDown(Get.reset);

    group('UNITARIA · Modelo de los bloques de horario (HU35)', () {
      test('caso 1: el contrato completo se parsea tal como llega', () {
        final regla = TimeBlockRule.fromJson(
          (_bloquesJson()['blocks'] as List).first,
        );
        expect(regla.id, 12);
        expect(regla.title, 'PRÁCTICAS DE PRUEBA');
        expect(regla.colorHex, '#EB5757');
        expect(regla.daysOfWeek, <int>[1, 3]);
        expect(regla.startTime, '14:00');
        expect(regla.endTime, '18:00');
        expect(regla.startDate, '2026-09-01');
        expect(regla.endDate, '2026-12-15');
        expect(regla.exceptions, hasLength(2));
        expect(regla.exceptions.first.date, '2026-10-07');
        expect(regla.exceptions.first.status, 'cancelled');
        expect(regla.exceptions.first.startTime, isNull);
        expect(regla.exceptions.last.status, 'moved');
        expect(regla.exceptions.last.startTime, '15:00');
        expect(regla.exceptions.last.endTime, '19:00');

        final snapshot = TimeBlocksSnapshot.fromJson(_ocurrenciasJson());
        expect(snapshot.occurrences, hasLength(2));
        final primera = snapshot.occurrences.first;
        expect(primera.blockId, 12);
        expect(primera.title, 'PRÁCTICAS DE PRUEBA');
        expect(primera.colorHex, '#EB5757');
        expect(primera.date, '2026-09-21');
        expect(primera.dayOfWeek, 1);
        expect(primera.startTime, '14:00');
        expect(primera.endTime, '18:00');
        expect(primera.moved, isFalse);
        expect(snapshot.occurrences.last.moved, isTrue);
        expect(snapshot.occurrences.last.startTime, '15:00');
        expect(snapshot.weeks, hasLength(4));
        expect(snapshot.weeks.first.weekStart, '2026-09-21');
        expect(snapshot.weeks.first.hours, 8.0);
        expect(
          TimeBlockWeek.fromJson(
            <String, dynamic>{'weekStart': '2026-10-05', 'hours': 12.5},
          ).hours,
          12.5,
          reason: 'las horas pueden traer decimal y no se redondean',
        );
      });

      test('caso 2: un campo ausente queda en null y no se inventa ningún 0',
          () {
        expect(
          TimeBlockWeek.fromJson(
            <String, dynamic>{'weekStart': '2026-09-28'},
          ).hours,
          isNull,
        );
        expect(
          TimeBlocksSnapshot.fromJson(_ocurrenciasJson()).weeks[1].hours,
          isNull,
          reason: 'hours en null se conserva en null, nunca como 0',
        );

        final cancelado = TimeBlockException.fromJson(
          <String, dynamic>{'date': '2026-10-07', 'status': 'cancelled'},
        );
        expect(cancelado.startTime, isNull);
        expect(cancelado.endTime, isNull);

        final vacio = TimeBlocksSnapshot.fromJson(<String, dynamic>{});
        expect(vacio.occurrences, isEmpty);
        expect(vacio.weeks, isEmpty);

        final regla = TimeBlockRule.fromJson(<String, dynamic>{
          'id': 13,
          'title': 'BLOQUE DE PRUEBA',
          'colorHex': '#2F80ED',
          'daysOfWeek': <dynamic>[1, 0, 8, 'x', 3],
          'startTime': '07:00',
          'endTime': '09:00',
          'startDate': '2026-09-01',
          'endDate': '2026-09-30',
        });
        expect(
          regla.daysOfWeek,
          <int>[1, 3],
          reason: 'lo que no es un día de 1 a 7 se descarta, no se cuela como 0',
        );
        expect(regla.exceptions, isEmpty);

        final completa = <String, dynamic>{
          'blockId': 13,
          'title': 'BLOQUE DE PRUEBA',
          'colorHex': '#2F80ED',
          'date': '2026-09-21',
          'dayOfWeek': 1,
          'startTime': '07:00',
          'endTime': '09:00',
        };
        final sinMoved = TimeBlockOccurrence.fromJson(completa);
        expect(sinMoved.moved, isFalse);

        // Una ocurrencia sin lo imprescindible se descarta: no llega con un
        // blockId 0 (tocarla mandaría /time-blocks/me/0/…) ni con horas ''
        // (se pintaría a las 7:00, el respaldo de la grilla).
        final filtradas = TimeBlocksSnapshot.fromJson(<String, dynamic>{
          'occurrences': <dynamic>[
            Map<String, dynamic>.from(completa)..remove('blockId'),
            Map<String, dynamic>.from(completa)..remove('startTime'),
            Map<String, dynamic>.from(completa)..['date'] = 'mañana',
            completa,
          ],
        });
        expect(filtradas.occurrences, hasLength(1));
        expect(filtradas.occurrences.single.blockId, 13);
        expect(
          TimeBlockOccurrence.tryFromJson(<String, dynamic>{'blockId': 13}),
          isNull,
        );
        expect(
          TimeBlockOccurrence.tryFromJson(
            Map<String, dynamic>.from(completa)..remove('dayOfWeek'),
          )!.dayOfWeek,
          1,
          reason: 'sin dayOfWeek, sale de la fecha y no queda en 0',
        );

        // Una regla sin id no es una regla: no llega con id 0.
        expect(
          TimeBlockRule.tryFromJson(
            Map<String, dynamic>.from(_reglaJson())..remove('id'),
          ),
          isNull,
        );
        expect(
          () => TimeBlockRule.fromJson(<String, dynamic>{'title': 'SIN ID'}),
          throwsFormatException,
        );
      });

      test('caso 3: toJson devuelve el contrato y conserva los null', () {
        final cancelado = TimeBlockException.fromJson(
          <String, dynamic>{'date': '2026-10-07', 'status': 'cancelled'},
        );
        expect(cancelado.toJson(), <String, dynamic>{
          'date': '2026-10-07',
          'status': 'cancelled',
          'startTime': null,
          'endTime': null,
        });

        final regla = TimeBlockRule.fromJson(
          (_bloquesJson()['blocks'] as List).first,
        );
        final ida = TimeBlockRule.fromJson(regla.toJson());
        expect(ida.id, regla.id);
        expect(ida.title, regla.title);
        expect(ida.daysOfWeek, regla.daysOfWeek);
        expect(ida.startTime, regla.startTime);
        expect(ida.endDate, regla.endDate);
        expect(ida.exceptions, hasLength(2));
        expect(ida.exceptions.first.startTime, isNull);

        final movida = TimeBlocksSnapshot.fromJson(
          _ocurrenciasJson(),
        ).occurrences.last;
        expect(TimeBlockOccurrence.fromJson(movida.toJson()).moved, isTrue);
      });
    });

    group('UNITARIA · TimeBlocksService (HU35)', () {
      test('caso 4: load pide las dos rutas con la ventana y guarda todo',
          () async {
        _loguear(_user());
        final api = _FakeBlocksApi();
        final s = _servicio(api);

        await s.load(from: _desde, to: _hasta);

        expect(api.getBloques, 1);
        expect(api.getOcurrencias, 1);
        expect(api.ultimaVentana, <String, String?>{
          'from': _desde,
          'to': _hasta,
        });
        expect(
          s.blocks,
          hasLength(1),
          reason: 'la entrada sin id se descarta, no llega con id 0',
        );
        expect(s.blocks.single.title, 'PRÁCTICAS DE PRUEBA');
        expect(s.snapshot!.occurrences, hasLength(2));
        expect(s.snapshot!.weeks, hasLength(4));
        expect(s.isLoading, isFalse);
        expect(s.hasError, isFalse);
      });

      test('caso 5: sin force no repite la misma ventana; otra ventana sí',
          () async {
        _loguear(_user());
        final api = _FakeBlocksApi();
        final s = _servicio(api);

        await s.load(from: _desde, to: _hasta);
        await s.load(from: _desde, to: _hasta);
        expect(api.getOcurrencias, 1);

        await s.load(from: _desde, to: _hasta, force: true);
        expect(api.getOcurrencias, 2);

        await s.load(from: '2026-10-19', to: '2026-11-15');
        expect(api.getOcurrencias, 3);
        expect(api.ultimaVentana, <String, String?>{
          'from': '2026-10-19',
          'to': '2026-11-15',
        });
      });

      test('caso 6: dos load() simultáneos hacen una sola pareja de GET',
          () async {
        _loguear(_user());
        final reglas = Completer<Map<String, dynamic>>();
        final ocurrencias = Completer<Map<String, dynamic>>();
        final api = _FakeBlocksApi(
          bloques: <Object>[reglas],
          ocurrencias: <Object>[ocurrencias],
        );
        final s = _servicio(api);

        final a = s.load(from: _desde, to: _hasta);
        final b = s.load(from: _desde, to: _hasta);
        expect(s.isLoading, isTrue);

        reglas.complete(_bloquesJson());
        ocurrencias.complete(_ocurrenciasJson());
        await Future.wait(<Future<void>>[a, b]);

        expect(api.getBloques, 1);
        expect(api.getOcurrencias, 1);
        expect(s.isLoading, isFalse);
        expect(s.snapshot!.occurrences, hasLength(2));
      });

      test('caso 7: un docente o una sesión sin usuario nunca piden nada',
          () async {
        final auth = _loguear(_user(code: 'docente.test', role: 'teacher'));
        final api = _FakeBlocksApi();
        final s = _servicio(api);

        await s.load(from: _desde, to: _hasta);
        await s.load(from: _desde, to: _hasta, force: true);
        await s.reload();

        expect(api.getBloques, 0);
        expect(api.getOcurrencias, 0);
        expect(s.blocks, isEmpty);
        expect(s.snapshot, isNull);
        expect(s.isLoading, isFalse);

        auth.userRx.value = null;
        await s.load(from: _desde, to: _hasta, force: true);
        expect(api.getBloques, 0);
      });

      test('caso 8: otro usuario sin logout de por medio no ve lo anterior',
          () async {
        final auth = _loguear(_user());
        final api = _FakeBlocksApi(
          bloques: <Object>[_bloquesJson(), _sinBloquesJson()],
          ocurrencias: <Object>[_ocurrenciasJson(), _sinOcurrenciasJson()],
        );
        final s = _servicio(api);
        await s.load(from: _desde, to: _hasta);
        expect(s.blocks, hasLength(1));

        // Un código que no puede ser real: el repo es público.
        auth.userRx.value = _user(code: 'alumna.b.test');
        expect(s.blocks, isEmpty, reason: 'ni siquiera antes de llamar a load()');
        expect(s.snapshot, isNull);

        await s.load(from: _desde, to: _hasta);
        expect(api.getOcurrencias, 2);
        expect(s.blocks, isEmpty);
        expect(s.snapshot!.occurrences, isEmpty);
      });

      test('caso 9: un fallo no lanza: deja hasError y el siguiente reintenta',
          () async {
        _loguear(_user());
        final api = _FakeBlocksApi(
          bloques: <Object>[Exception('socket'), _bloquesJson()],
          ocurrencias: <Object>[Exception('socket'), _ocurrenciasJson()],
        );
        final s = _servicio(api);

        await expectLater(s.load(from: _desde, to: _hasta), completes);
        expect(s.hasError, isTrue);
        expect(s.blocks, isEmpty);
        expect(s.snapshot, isNull);
        expect(s.isLoading, isFalse);

        await s.load(from: _desde, to: _hasta);
        expect(
          api.getOcurrencias,
          2,
          reason: 'un fallo no deja la ventana marcada como cargada',
        );
        expect(s.hasError, isFalse);
        expect(s.snapshot!.occurrences, hasLength(2));
      });

      test('caso 10: create manda el body del contrato y recarga una sola vez',
          () async {
        _loguear(_user());
        final api = _FakeBlocksApi();
        final s = _servicio(api);
        await s.load(from: _desde, to: _hasta);

        final creado = await s.create(_entrada());

        expect(api.escrituras, <String>['POST /time-blocks/me']);
        expect(api.cuerpos.single, <String, dynamic>{
          'title': 'PRÁCTICAS DE PRUEBA',
          'colorHex': '#EB5757',
          'daysOfWeek': <int>[1, 3],
          'startTime': '14:00',
          'endTime': '18:00',
          'startDate': '2026-09-01',
          'endDate': '2026-12-15',
        });
        expect(creado.id, 12);
        expect(api.getBloques, 2, reason: 'una sola recarga de la ventana');
        expect(api.getOcurrencias, 2);
        expect(api.ultimaVentana, <String, String?>{
          'from': _desde,
          'to': _hasta,
        });
      });

      test('caso 11: update usa PATCH con el id y recarga', () async {
        _loguear(_user());
        final api = _FakeBlocksApi();
        final s = _servicio(api);
        await s.load(from: _desde, to: _hasta);

        final editado = await s.update(12, _entrada());

        expect(api.escrituras, <String>['PATCH /time-blocks/me/12']);
        expect(api.cuerpos.single['daysOfWeek'], <int>[1, 3]);
        expect(editado.title, 'PRÁCTICAS EDITADAS');
        expect(api.getOcurrencias, 2);
      });

      test('caso 12: remove borra el bloque y recarga', () async {
        _loguear(_user());
        final api = _FakeBlocksApi();
        final s = _servicio(api);
        await s.load(from: _desde, to: _hasta);

        await s.remove(12);

        expect(api.escrituras, <String>['DELETE /time-blocks/me/12']);
        expect(api.getOcurrencias, 2);
      });

      test('caso 13: cancelar un día no manda horas y moverlo sí', () async {
        _loguear(_user());
        final api = _FakeBlocksApi();
        final s = _servicio(api);
        await s.load(from: _desde, to: _hasta);

        await s.setException(12, '2026-10-07', status: 'cancelled');
        expect(
          api.escrituras.last,
          'PUT /time-blocks/me/12/occurrences/2026-10-07',
        );
        expect(api.cuerpos.last, <String, dynamic>{'status': 'cancelled'});

        await s.setException(
          12,
          '2026-10-14',
          status: 'moved',
          startTime: '15:00',
          endTime: '19:00',
        );
        expect(
          api.escrituras.last,
          'PUT /time-blocks/me/12/occurrences/2026-10-14',
        );
        expect(api.cuerpos.last, <String, dynamic>{
          'status': 'moved',
          'startTime': '15:00',
          'endTime': '19:00',
        });
        expect(api.getOcurrencias, 3, reason: 'una recarga por excepción');
      });

      test('caso 14: clearException devuelve el día al patrón y recarga',
          () async {
        _loguear(_user());
        final api = _FakeBlocksApi();
        final s = _servicio(api);
        await s.load(from: _desde, to: _hasta);

        await s.clearException(12, '2026-10-07');

        expect(
          api.escrituras,
          <String>['DELETE /time-blocks/me/12/occurrences/2026-10-07'],
        );
        expect(api.getOcurrencias, 2);
      });

      test('caso 15: un error del servidor sale con su mensaje y no recarga',
          () async {
        _loguear(_user());
        final api = _FakeBlocksApi()
          ..errorDeEscritura = ApiException(
            statusCode: 400,
            code: 'TIME_BLOCK_OUT_OF_GRID',
            message: 'El bloque tiene que empezar y terminar entre las 07:00 y las 22:00.',
          );
        final s = _servicio(api);
        await s.load(from: _desde, to: _hasta);

        await expectLater(
          s.create(_entrada()),
          throwsA(
            isA<TimeBlocksFailure>().having(
              (e) => e.message,
              'message',
              'El bloque tiene que empezar y terminar entre las 07:00 y las 22:00.',
            ),
          ),
        );
        expect(api.getOcurrencias, 1, reason: 'sin escritura no hay recarga');
      });

      test('caso 16: un fallo de red sale con el mensaje genérico', () async {
        _loguear(_user());
        final api = _FakeBlocksApi()..errorDeEscritura = Exception('socket');
        final s = _servicio(api);
        await s.load(from: _desde, to: _hasta);

        await expectLater(
          s.remove(12),
          throwsA(
            isA<TimeBlocksFailure>().having(
              (e) => e.message,
              'message',
              TimeBlocksService.genericErrorMessage,
            ),
          ),
        );
        expect(api.getOcurrencias, 1);
      });

      test('caso 17: logout() vacía los bloques y el siguiente load vuelve a pedir',
          () async {
        // TT06: AuthService.logout() invalida las cachés por usuario, como ya
        // hace con el récord. El doble de sesión sigue devolviendo a la misma
        // alumna, así que lo único que puede vaciar el estado es el clear()
        // que llama logout(): sin ese enganche, blocks seguiría lleno.
        _loguear(_user());
        Get.put<StorageService>(_SinSesionGuardada());
        Get.put<MallaService>(MallaService());
        final api = _FakeBlocksApi();
        final s = _servicio(api);
        await s.load(from: _desde, to: _hasta);
        expect(s.blocks, hasLength(1));

        await AuthService.to.logout();

        expect(s.blocks, isEmpty);
        expect(s.snapshot, isNull);
        await s.load(from: _desde, to: _hasta);
        expect(
          api.getOcurrencias,
          2,
          reason: 'sin la copia anterior, la misma ventana se vuelve a pedir',
        );
      });

      test('caso 18: un fallo al cambiar de ventana no la deja marcada como '
          'cargada', () async {
        // El caso 9 lo prueba en la primera carga. Aquí ya hay una foto, la de
        // la ventana anterior, y esa foto no puede contar como la de la nueva.
        _loguear(_user());
        final api = _FakeBlocksApi(
          bloques: <Object>[_bloquesJson(), Exception('socket'), _bloquesJson()],
          ocurrencias: <Object>[
            _ocurrenciasJson(),
            Exception('socket'),
            _sinOcurrenciasJson(),
          ],
        );
        final s = _servicio(api);
        await s.load(from: _desde, to: _hasta);

        await s.load(from: '2026-10-19', to: '2026-11-15');
        expect(s.hasError, isTrue);

        await s.load(from: '2026-10-19', to: '2026-11-15');
        expect(
          api.getOcurrencias,
          3,
          reason: 'un fallo no deja la ventana marcada como cargada, tampoco '
              'cuando queda la foto de la ventana anterior',
        );
        expect(api.ultimaVentana, <String, String?>{
          'from': '2026-10-19',
          'to': '2026-11-15',
        });
        expect(s.hasError, isFalse);
        expect(s.snapshot!.occurrences, isEmpty);
      });

      test('caso 19: con la foto de otra ventana, un segundo load() espera la '
          'carga en vuelo', () async {
        _loguear(_user());
        final reglas = Completer<Map<String, dynamic>>();
        final ocurrencias = Completer<Map<String, dynamic>>();
        final api = _FakeBlocksApi(
          bloques: <Object>[_bloquesJson(), reglas],
          ocurrencias: <Object>[_ocurrenciasJson(), ocurrencias],
        );
        final s = _servicio(api);
        await s.load(from: _desde, to: _hasta);

        final primera = s.load(from: '2026-10-19', to: '2026-11-15');
        var segundaTermino = false;
        final segunda = s
            .load(from: '2026-10-19', to: '2026-11-15')
            .then((_) => segundaTermino = true);
        await Future<void>.delayed(Duration.zero);
        expect(
          segundaTermino,
          isFalse,
          reason: 'la foto que hay es la de la ventana anterior: quien espera '
              'tiene que esperar la carga en vuelo',
        );

        reglas.complete(_sinBloquesJson());
        ocurrencias.complete(_sinOcurrenciasJson());
        await Future.wait(<Future<void>>[primera, segunda]);

        expect(segundaTermino, isTrue);
        expect(api.getOcurrencias, 2, reason: 'una sola pareja de GET');
        expect(s.snapshot!.occurrences, isEmpty);
      });
    });
  }
  ```

- [ ] **Paso 2: Correr la prueba y ver que falla**

  ```bash
  cd "${REPO:?}"
  "${FLUTTER:?}" test test/HU35_jeff/time_blocks_service_test.dart
  ```

  Esperado: la suite **no llega a cargar** —ningún test corrido, `00:00 +0 -1: Some tests failed.` y `Failing tests: …time_blocks_service_test.dart: loading …time_blocks_service_test.dart`—. El front-end saca **decenas de errores encadenados** (31 líneas `Error:` antes del resumen, medidas con Flutter 3.47.2 sobre esta versión de la prueba), y los dos primeros, en este orden, son exactamente los dos archivos que crea el Paso 3:

  ```
  00:00 +0: loading $REPO/test/HU35_jeff/time_blocks_service_test.dart
  test/HU35_jeff/time_blocks_service_test.dart:16:8: Error: Error when reading
  'lib/models/time_block_model.dart': No such file or directory
  import 'package:ulima_plus/models/time_block_model.dart';
         ^
  test/HU35_jeff/time_blocks_service_test.dart:22:8: Error: Error when reading
  'lib/services/time_blocks_service.dart': No such file or directory
  import 'package:ulima_plus/services/time_blocks_service.dart';
         ^
  test/HU35_jeff/time_blocks_service_test.dart:…: Error: Type 'TimeBlockInput' not found.
  test/HU35_jeff/time_blocks_service_test.dart:…: Error: Type 'TimeBlocksService' not found.
  ```

  Los demás son la cascada de esos dos (`Undefined name 'TimeBlockRule'`, `'TimeBlocksFailure' isn't a type`, `The getter 'message' isn't defined for the type 'Object?'`, …) y desaparecen solas al crear los archivos. Los números de línea y la redacción del compilador pueden variar de versión a versión; lo que tiene que aparecer son los dos archivos que no existen. Ninguno apunta a `malla_service.dart` ni a `storage_service.dart`, que ya existen.

  El tercer hueco —`patchJson`— **no** sale en esta salida: el `@override` sobre un método que la superclase no tiene es un error del **analizador**, no del front-end, y el front-end además ni llega a comprobarlo porque el archivo ya no compila. Se comprueba aparte, y tiene que no devolver nada:

  ```bash
  grep -rn "patchJson" "${REPO:?}/lib/"
  ```

- [ ] **Paso 3: Implementación mínima**

  **3.a — Crear `lib/models/time_block_model.dart`:**

  ```dart
  /// Modelos de los bloques de horario propios del alumno (RF-BLQ-7): la regla
  /// semanal, sus excepciones por día, y las ocurrencias ya expandidas por el
  /// servidor con el total de horas de cada semana.
  ///
  /// `fromJson` a mano con coerción defensiva, como
  /// `academic_record_model.dart`: un dato sin valor queda `null` y nunca 0. El
  /// único número que el alumno llega a leer es [TimeBlockWeek.hours], y es
  /// `double?` justamente para que la línea de horas no pueda pintar un 0
  /// inventado (RF-BLQ-6).
  ///
  /// Una regla o una ocurrencia a la que le falta lo imprescindible (el id,
  /// la fecha, las horas) no se rellena con 0 ni con '': `tryFromJson`
  /// devuelve null y las listas la descartan. `fromJson` lanza
  /// [FormatException] en ese mismo caso.
  ///
  /// Las horas viajan como `"HH:MM"` y las fechas como `"YYYY-MM-DD"`, en hora
  /// de Lima y sin zona pegada: son horas de pared, así que se guardan como
  /// texto y nadie las convierte a `DateTime`.
  library;

  /// `double` o `null`. Copia de `academic_record_model.dart:16-17`.
  double? _asDoubleOrNull(dynamic v) =>
      v == null ? null : (v is num ? v.toDouble() : double.tryParse(v.toString()));

  /// `int` o `null`. Un número con decimal no es un entero válido.
  int? _asIntOrNull(dynamic v) {
    if (v is int) return v;
    if (v is num) return v == v.truncateToDouble() ? v.toInt() : null;
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  String _asString(dynamic v) => v == null ? '' : v.toString();

  /// Texto sin espacios en los bordes, o `null` si no hay texto. Es lo que
  /// conserva en `null` las horas de una excepción `cancelled`.
  String? _asStringOrNull(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  Map<String, dynamic> _asMap(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  /// Los elementos que son objetos; el resto se descarta.
  List<Map<String, dynamic>> _asMapList(dynamic v) => v is List
      ? v.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList()
      : const <Map<String, dynamic>>[];

  /// Los días del patrón: 1 es lunes y 7 es domingo, la misma convención que
  /// `schedule_session.day_of_week`. Lo que no sea un entero de 1 a 7 se
  /// descarta en vez de colarse como un 0 que la grilla no sabría pintar.
  List<int> _asDaysOfWeek(dynamic v) => v is List
      ? v
          .map(_asIntOrNull)
          .whereType<int>()
          .where((d) => d >= 1 && d <= 7)
          .toList()
      : const <int>[];

  /// Lo que se sale del patrón un día concreto.
  class TimeBlockException {
    const TimeBlockException({
      required this.date,
      required this.status,
      required this.startTime,
      required this.endTime,
    });

    /// `"YYYY-MM-DD"`.
    final String date;

    /// `'cancelled'` (ese día no va) o `'moved'` (ese día tiene otras horas).
    final String status;

    /// Solo vienen con `'moved'`; con `'cancelled'` son `null` y se conservan
    /// así, sin convertirse en cadena vacía ni en la hora del patrón.
    final String? startTime;
    final String? endTime;

    factory TimeBlockException.fromJson(Object? json) {
      final map = _asMap(json);
      return TimeBlockException(
        date: _asString(map['date']),
        status: _asString(map['status']),
        startTime: _asStringOrNull(map['startTime']),
        endTime: _asStringOrNull(map['endTime']),
      );
    }

    Map<String, dynamic> toJson() => <String, dynamic>{
          'date': date,
          'status': status,
          'startTime': startTime,
          'endTime': endTime,
        };
  }

  /// La regla: el patrón semanal y el rango de fechas en que vale.
  class TimeBlockRule {
    const TimeBlockRule({
      required this.id,
      required this.title,
      required this.colorHex,
      required this.daysOfWeek,
      required this.startTime,
      required this.endTime,
      required this.startDate,
      required this.endDate,
      required this.exceptions,
    });

    /// El id del servidor. Siempre es uno real: una regla sin id se descarta
    /// al leerla ([tryFromJson]).
    final int id;
    final String title;

    /// `"#RRGGBB"`. El formulario solo ofrece los doce de `kCoursePalette`
    /// (RF-BLQ-2); el servidor acepta cualquier `#RRGGBB`, así que acá no se
    /// valida ni se normaliza: llega y se guarda.
    final String colorHex;

    /// 1 es lunes y 7 es domingo.
    final List<int> daysOfWeek;

    /// `"HH:MM"` en hora de Lima.
    final String startTime;
    final String endTime;

    /// `"YYYY-MM-DD"`.
    final String startDate;
    final String endDate;
    final List<TimeBlockException> exceptions;

    /// La regla de [json], o null si le falta algo sin lo cual no sirve: el
    /// `id` (editarla o borrarla mandaría `/time-blocks/me/0`), las horas o
    /// las fechas. Nunca se rellena con 0 ni con '' (RF-BLQ-7).
    static TimeBlockRule? tryFromJson(Object? json) {
      final map = _asMap(json);
      final id = _asIntOrNull(map['id']);
      final startTime = _asStringOrNull(map['startTime']);
      final endTime = _asStringOrNull(map['endTime']);
      final startDate = _asStringOrNull(map['startDate']);
      final endDate = _asStringOrNull(map['endDate']);
      if (id == null ||
          id <= 0 ||
          startTime == null ||
          endTime == null ||
          startDate == null ||
          endDate == null) {
        return null;
      }
      return TimeBlockRule(
        id: id,
        title: _asString(map['title']),
        colorHex: _asString(map['colorHex']),
        daysOfWeek: _asDaysOfWeek(map['daysOfWeek']),
        startTime: startTime,
        endTime: endTime,
        startDate: startDate,
        endDate: endDate,
        exceptions:
            _asMapList(map['exceptions']).map(TimeBlockException.fromJson).toList(),
      );
    }

    /// Como [tryFromJson], pero lanza [FormatException] si falta algo. Es para
    /// la respuesta de una escritura, que trae un solo bloque; las listas usan
    /// [tryFromJson] y descartan la entrada.
    factory TimeBlockRule.fromJson(Object? json) =>
        tryFromJson(json) ??
        (throw const FormatException('Bloque de horario incompleto.'));

    Map<String, dynamic> toJson() => <String, dynamic>{
          'id': id,
          'title': title,
          'colorHex': colorHex,
          'daysOfWeek': daysOfWeek,
          'startTime': startTime,
          'endTime': endTime,
          'startDate': startDate,
          'endDate': endDate,
          'exceptions': exceptions.map((e) => e.toJson()).toList(),
        };
  }

  /// Un día concreto del bloque, ya expandido por el servidor: las
  /// excepciones están aplicadas (un día cancelado no llega) y [moved] dice si
  /// ese día se salió del patrón.
  class TimeBlockOccurrence {
    const TimeBlockOccurrence({
      required this.blockId,
      required this.title,
      required this.colorHex,
      required this.date,
      required this.dayOfWeek,
      required this.startTime,
      required this.endTime,
      required this.moved,
    });

    /// El [TimeBlockRule.id] de su regla. Siempre es uno real: una ocurrencia
    /// sin él se descarta al leerla ([tryFromJson]).
    final int blockId;
    final String title;
    final String colorHex;

    /// `"YYYY-MM-DD"`: la vista de día filtra por esta fecha, no por el nombre
    /// del día.
    final String date;

    /// 1 es lunes y 7 es domingo. Si el servidor no lo mandara, sale de
    /// [date]; nunca queda en 0.
    final int dayOfWeek;
    final String startTime;
    final String endTime;
    final bool moved;

    /// La ocurrencia de [json], o null si le falta algo sin lo cual no se
    /// puede pintar ni tocar: el `blockId` (tocarla mandaría
    /// `/time-blocks/me/0/…`), una fecha que se pueda leer o las horas (sin
    /// ellas se pintaría a las 7:00, el respaldo de la grilla). Nunca se
    /// rellena con 0 ni con '' (RF-BLQ-7).
    static TimeBlockOccurrence? tryFromJson(Object? json) {
      final map = _asMap(json);
      final blockId = _asIntOrNull(map['blockId']);
      final date = _asStringOrNull(map['date']);
      final fecha = date == null ? null : DateTime.tryParse(date);
      final startTime = _asStringOrNull(map['startTime']);
      final endTime = _asStringOrNull(map['endTime']);
      if (blockId == null ||
          blockId <= 0 ||
          date == null ||
          fecha == null ||
          startTime == null ||
          endTime == null) {
        return null;
      }
      final dia = _asIntOrNull(map['dayOfWeek']);
      return TimeBlockOccurrence(
        blockId: blockId,
        title: _asString(map['title']),
        colorHex: _asString(map['colorHex']),
        date: date,
        dayOfWeek: dia != null && dia >= 1 && dia <= 7 ? dia : fecha.weekday,
        startTime: startTime,
        endTime: endTime,
        moved: map['moved'] == true,
      );
    }

    /// Como [tryFromJson], pero lanza [FormatException] si falta algo.
    factory TimeBlockOccurrence.fromJson(Object? json) =>
        tryFromJson(json) ??
        (throw const FormatException('Ocurrencia de bloque incompleta.'));

    Map<String, dynamic> toJson() => <String, dynamic>{
          'blockId': blockId,
          'title': title,
          'colorHex': colorHex,
          'date': date,
          'dayOfWeek': dayOfWeek,
          'startTime': startTime,
          'endTime': endTime,
          'moved': moved,
        };
  }

  /// Las horas que los bloques del alumno ocupan en una semana de lunes a
  /// domingo. [hours] es `double?` y lo calcula el servidor: la app lo muestra
  /// y no lo recalcula (RF-BLQ-6).
  class TimeBlockWeek {
    const TimeBlockWeek({required this.weekStart, required this.hours});

    /// El lunes de esa semana, `"YYYY-MM-DD"`.
    final String weekStart;
    final double? hours;

    factory TimeBlockWeek.fromJson(Object? json) {
      final map = _asMap(json);
      return TimeBlockWeek(
        weekStart: _asString(map['weekStart']),
        hours: _asDoubleOrNull(map['hours']),
      );
    }
  }

  /// Respuesta de `GET /time-blocks/me/occurrences`.
  class TimeBlocksSnapshot {
    const TimeBlocksSnapshot({required this.occurrences, required this.weeks});

    /// Ordenadas por fecha y hora de inicio, como las manda el servidor.
    final List<TimeBlockOccurrence> occurrences;
    final List<TimeBlockWeek> weeks;

    factory TimeBlocksSnapshot.fromJson(Object? json) {
      final map = _asMap(json);
      return TimeBlocksSnapshot(
        // Una ocurrencia incompleta se descarta, no se pinta a las 7:00.
        occurrences: _asMapList(map['occurrences'])
            .map(TimeBlockOccurrence.tryFromJson)
            .whereType<TimeBlockOccurrence>()
            .toList(),
        weeks: _asMapList(map['weeks']).map(TimeBlockWeek.fromJson).toList(),
      );
    }
  }
  ```

  **3.b — Crear `lib/services/time_blocks_service.dart`:**

  ```dart
  import 'package:flutter/foundation.dart';
  import 'package:get/get.dart';

  import '../models/time_block_model.dart';
  import 'api_client.dart';
  import 'auth_service.dart';

  /// Estado único de los bloques de horario propios del alumno (RF-BLQ-7).
  ///
  /// Es el único que habla HTTP con `/time-blocks/**`: ni el controlador del
  /// horario ni ningún widget leen ese JSON. Guarda dos cosas a la vez, porque
  /// la pantalla necesita las dos: las **reglas** ([blocks], para editar y para
  /// detectar cruces) y la **ventana de ocurrencias** ya expandida por el
  /// servidor ([snapshot], para pintar la grilla y la línea de horas).
  ///
  /// **Guarda por dueño**, como `AcademicRecordService`: [blocks] y [snapshot]
  /// descartan el estado de cualquier usuario que no sea el actual, y [load]
  /// descarta el estado ajeno antes del primer `await`. Además
  /// `AuthService.logout()` llama a [clear], igual que con el récord (TT06):
  /// los horarios de trabajo o de prácticas de la alumna no se quedan en
  /// memoria después de cerrar sesión.
  ///
  /// Un docente nunca dispara la petición: las rutas son de alumno y su horario
  /// es el de sus clases y asesorías.
  class TimeBlocksService extends GetxService {
    TimeBlocksService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

    static TimeBlocksService get to => Get.find();

    /// `ApiClient` no impone timeout (`_send` llama a `request.send()` sin
    /// `.timeout()`): sin esto, la grilla se quedaría cargando para siempre si
    /// el backend no responde.
    static const Duration requestTimeout = Duration(seconds: 15);

    /// Mensaje de una escritura que falló **sin** mensaje del servidor (red
    /// caída, plazo vencido). Un [ApiException] sí trae el suyo y se muestra
    /// tal cual: RF-BLQ-2 dice que el error del servidor es el que él manda.
    static const String genericErrorMessage =
        'No se pudo guardar tu bloque. Inténtalo de nuevo.';

    final ApiClient _api;
    final RxList<TimeBlockRule> _blocks = <TimeBlockRule>[].obs;
    final Rxn<TimeBlocksSnapshot> _snapshot = Rxn<TimeBlocksSnapshot>();
    final RxBool _loading = false.obs;
    final RxBool _hasError = false.obs;

    /// Alumno dueño del estado, o de la carga en vuelo.
    String? _ownerCode;

    /// La ventana que se pidió; [reload] vuelve a pedir esta misma.
    String? _from;
    String? _to;

    /// La ventana de la foto que hay en [_snapshot]. Cambia solo cuando una
    /// carga termina bien: tras un fallo, o mientras llega la ventana nueva,
    /// la foto sigue siendo la de la anterior y no cuenta como la pedida.
    String? _loadedFrom;
    String? _loadedTo;

    /// Sube con cada [clear] y con cada carga nueva. Una respuesta que vuelve
    /// con otro número es vieja y se descarta.
    int _generation = 0;

    /// Carga en vuelo: dos [load] seguidos de la misma ventana comparten una
    /// sola pareja de `GET`.
    Future<void>? _inFlight;

    bool get _esDelUsuarioActual {
      final code = AuthService.to.currentUser?.code;
      return code != null && code == _ownerCode;
    }

    /// Las reglas del usuario actual. Vacía mientras no haya una copia suya.
    List<TimeBlockRule> get blocks {
      // El Rx se lee SIEMPRE primero: así el Obx que llama a este getter se
      // suscribe aunque después se devuelva la lista vacía.
      final propias = _blocks.toList(growable: false);
      return _esDelUsuarioActual ? propias : const <TimeBlockRule>[];
    }

    /// La ventana de ocurrencias del usuario actual, o null si todavía no hay
    /// una copia suya.
    TimeBlocksSnapshot? get snapshot {
      final s = _snapshot.value;
      return _esDelUsuarioActual ? s : null;
    }

    /// A diferencia de [blocks] y [snapshot], no están filtrados por dueño.
    bool get isLoading => _loading.value;
    bool get hasError => _hasError.value;

    /// Olvida los bloques, la ventana y la carga en vuelo.
    void clear() {
      _generation++;
      _inFlight = null;
      _ownerCode = null;
      _from = null;
      _to = null;
      _loadedFrom = null;
      _loadedTo = null;
      _blocks.clear();
      _snapshot.value = null;
      _hasError.value = false;
      _loading.value = false;
    }

    /// Pide `GET /time-blocks/me` y `GET /time-blocks/me/occurrences` de la
    /// ventana `[from, to]`, las dos a la vez. Nunca lanza: un fallo queda en
    /// [hasError]. Sin usuario o con un docente no hace nada. Sin [force] es
    /// idempotente por usuario y por ventana.
    Future<void> load({
      required String from,
      required String to,
      bool force = false,
    }) {
      final user = AuthService.to.currentUser;
      if (user == null || user.isTeacher) return Future<void>.value();
      // Otro usuario sin logout de por medio: su estado se descarta ANTES de
      // cualquier await.
      if (_ownerCode != user.code) clear();
      final mismaVentana = _from == from && _to == to;
      // La carga en vuelo va antes que la foto: mientras llega esta ventana,
      // la foto que hay puede ser la de la anterior, y quien espera tiene que
      // esperar la de esta.
      if (!force && mismaVentana && _inFlight != null) return _inFlight!;
      // Solo corta la foto de ESTA ventana. Tras un fallo al cambiar de
      // ventana queda la de la anterior, y esa no la marca como cargada.
      if (!force && mismaVentana && _loadedFrom == from && _loadedTo == to) {
        return Future<void>.value();
      }
      _ownerCode = user.code;
      _from = from;
      _to = to;
      final generation = ++_generation;
      return _inFlight = _fetch(generation, from, to);
    }

    Future<void> _fetch(int generation, String from, String to) async {
      _loading.value = true;
      _hasError.value = false;
      try {
        final respuestas = await Future.wait(<Future<Map<String, dynamic>>>[
          _api.getJson('/time-blocks/me'),
          _api.getJson(
            '/time-blocks/me/occurrences',
            query: <String, String?>{'from': from, 'to': to},
          ),
        ]).timeout(requestTimeout);
        if (generation != _generation) return;
        _blocks.assignAll(_reglasDe(respuestas[0]));
        _snapshot.value = TimeBlocksSnapshot.fromJson(respuestas[1]);
        _loadedFrom = from;
        _loadedTo = to;
      } catch (e) {
        if (generation != _generation) return;
        // ApiException, fallo de red crudo (ApiClient no lo envuelve) o plazo
        // vencido. No se propaga: la grilla se queda sin bloques propios y el
        // horario de clases se sigue viendo.
        debugPrint('Error cargando los bloques de horario: $e');
        _hasError.value = true;
      } finally {
        if (generation == _generation) {
          _loading.value = false;
          _inFlight = null;
        }
      }
    }

    /// Las reglas de la respuesta. Una entrada sin id, horas o fechas se
    /// descarta ([TimeBlockRule.tryFromJson]): no entra con un id 0.
    List<TimeBlockRule> _reglasDe(Map<String, dynamic> json) {
      final raw = json['blocks'];
      if (raw is! List) return const <TimeBlockRule>[];
      return raw
          .map(TimeBlockRule.tryFromJson)
          .whereType<TimeBlockRule>()
          .toList();
    }

    /// Vuelve a pedir la ventana vigente. A diferencia de
    /// `AcademicRecordService.reload()`, **no** vacía antes: lo que hay sigue
    /// siendo válido mientras llega lo nuevo, y vaciarlo haría parpadear la
    /// grilla en cada guardado. Sin ventana pedida todavía, no hace nada.
    Future<void> reload() {
      final from = _from;
      final to = _to;
      if (from == null || to == null) return Future<void>.value();
      return load(from: from, to: to, force: true);
    }

    /// `POST /time-blocks/me`. Devuelve la regla creada y recarga la ventana
    /// vigente, para que la grilla muestre el bloque sin que la pantalla haga
    /// nada. Si falla, lanza [TimeBlocksFailure] y no recarga.
    Future<TimeBlockRule> create(TimeBlockInput input) async {
      final json = await _escribir(
        () => _api.postJson('/time-blocks/me', body: input.toJson()),
      );
      final bloque = TimeBlockRule.fromJson(json['block']);
      await reload();
      return bloque;
    }

    /// `PATCH /time-blocks/me/:id`: reemplaza la regla entera y el servidor
    /// conserva sus excepciones.
    Future<TimeBlockRule> update(int id, TimeBlockInput input) async {
      final json = await _escribir(
        () => _api.patchJson('/time-blocks/me/$id', body: input.toJson()),
      );
      final bloque = TimeBlockRule.fromJson(json['block']);
      await reload();
      return bloque;
    }

    /// `DELETE /time-blocks/me/:id`: el bloque y todos sus días.
    Future<void> remove(int id) async {
      await _escribir(() => _api.deleteJson('/time-blocks/me/$id'));
      await reload();
    }

    /// `PUT /time-blocks/me/:id/occurrences/:date`. Con `'cancelled'` no se
    /// mandan horas: el servidor las ignora en ese caso, y la respuesta trae
    /// la excepción con `startTime` y `endTime` en null.
    Future<void> setException(
      int id,
      String date, {
      required String status,
      String? startTime,
      String? endTime,
    }) async {
      await _escribir(
        () => _api.putJson(
          '/time-blocks/me/$id/occurrences/$date',
          body: <String, dynamic>{
            'status': status,
            // Marcador null-aware, como `advising_service.dart:59`: con
            // `'cancelled'` las dos horas son null y la clave NO viaja. Con
            // `if (startTime != null) 'startTime': startTime` el analizador
            // saca `use_null_aware_elements` y rompe la línea base del Paso 5.
            'startTime': ?startTime,
            'endTime': ?endTime,
          },
        ),
      );
      await reload();
    }

    /// `DELETE /time-blocks/me/:id/occurrences/:date`: ese día vuelve al patrón.
    Future<void> clearException(int id, String date) async {
      await _escribir(
        () => _api.deleteJson('/time-blocks/me/$id/occurrences/$date'),
      );
      await reload();
    }

    Future<Map<String, dynamic>> _escribir(
      Future<Map<String, dynamic>> Function() peticion,
    ) async {
      try {
        return await peticion().timeout(requestTimeout);
      } on ApiException catch (e) {
        // El mensaje del servidor se muestra tal cual (RF-BLQ-2).
        throw TimeBlocksFailure(e.message);
      } catch (e) {
        debugPrint('Error escribiendo un bloque de horario: $e');
        throw const TimeBlocksFailure(genericErrorMessage);
      }
    }
  }

  /// Los siete campos del body de `POST` y `PATCH /time-blocks/me`.
  class TimeBlockInput {
    const TimeBlockInput({
      required this.title,
      required this.colorHex,
      required this.daysOfWeek,
      required this.startTime,
      required this.endTime,
      required this.startDate,
      required this.endDate,
    });

    final String title;

    /// `"#RRGGBB"`, uno de los doce de `kCoursePalette` (RF-BLQ-2).
    final String colorHex;

    /// 1 es lunes y 7 es domingo.
    final List<int> daysOfWeek;

    /// `"HH:MM"` en hora de Lima.
    final String startTime;
    final String endTime;

    /// `"YYYY-MM-DD"`.
    final String startDate;
    final String endDate;

    /// Los días salen ordenados —y en una copia, que la lista puede venir
    /// const— para que el mismo bloque sea el mismo body sin importar en qué
    /// orden el alumno tocó los botones.
    Map<String, dynamic> toJson() => <String, dynamic>{
          'title': title,
          'colorHex': colorHex,
          'daysOfWeek': daysOfWeek.toList()..sort(),
          'startTime': startTime,
          'endTime': endTime,
          'startDate': startDate,
          'endDate': endDate,
        };
  }

  /// Fallo de una escritura, con un mensaje ya listo para mostrar.
  class TimeBlocksFailure implements Exception {
    const TimeBlocksFailure(this.message);

    final String message;

    @override
    String toString() => 'TimeBlocksFailure: $message';
  }
  ```

  **3.c — `lib/services/api_client.dart`: agregar `PATCH`.** Reemplazar esto (`api_client.dart:99-104`):

  ```dart
    Future<Map<String, dynamic>> deleteJson(
      String path, {
      String? token,
    }) {
      return _send('DELETE', path, token: token);
    }
  ```

  por esto:

  ```dart
    /// `PATCH` con cuerpo, idéntico a [putJson] salvo el verbo. No existía
    /// porque hasta ahora ninguna pantalla lo usaba; lo pide
    /// `PATCH /time-blocks/me/:id` (RF-BLQ-7), la única ruta de la app con este
    /// verbo.
    Future<Map<String, dynamic>> patchJson(
      String path, {
      required Map<String, dynamic> body,
      String? token,
    }) {
      return _send('PATCH', path, token: token, body: body);
    }

    Future<Map<String, dynamic>> deleteJson(
      String path, {
      String? token,
    }) {
      return _send('DELETE', path, token: token);
    }
  ```

  **3.d — `lib/main.dart`: el import.** Reemplazar esto (`main.dart:14-15`):

  ```dart
  import '/services/academic_record_service.dart';
  import '/services/post_login_route.dart';
  ```

  por esto:

  ```dart
  import '/services/academic_record_service.dart';
  import '/services/time_blocks_service.dart';
  import '/services/post_login_route.dart';
  ```

  **3.e — `lib/main.dart`: el `Get.put` permanente.** Reemplazar esto (`main.dart:69-71` antes del 3.d, `:70-72` después):

  ```dart
    // Estado único del récord (RF-REC-5), compartido por la tarjeta del Perfil y
    // /mi-record. No carga nada al arrancar: la tarjeta lo pide al montarse.
    Get.put<AcademicRecordService>(AcademicRecordService(), permanent: true);
  ```

  por esto:

  ```dart
    // Estado único del récord (RF-REC-5), compartido por la tarjeta del Perfil y
    // /mi-record. No carga nada al arrancar: la tarjeta lo pide al montarse.
    Get.put<AcademicRecordService>(AcademicRecordService(), permanent: true);
    // Estado único de los bloques de horario propios (RF-BLQ-7). Permanente
    // como MallaService: la pantalla de horario es una tab del shell y el
    // formulario de /bloque escribe sobre este mismo estado. Tampoco carga nada
    // al arrancar: el horario pide su ventana al montarse.
    Get.put<TimeBlocksService>(TimeBlocksService(), permanent: true);
  ```

  **3.f — `lib/services/auth_service.dart`: el import** (`:16`). Reemplazar esto:

  ```dart
  import 'storage_service.dart';
  ```

  por esto:

  ```dart
  import 'storage_service.dart';
  import 'time_blocks_service.dart';
  ```

  (`time_blocks_service.dart` importa a su vez `auth_service.dart`. Dart admite el import circular, y es el mismo caso que `academic_record_service.dart`.)

  **3.g — `lib/services/auth_service.dart`: `logout()` vacía también los bloques** (`:397`). Reemplazar esto:

  ```dart
      if (Get.isRegistered<AcademicRecordService>()) AcademicRecordService.to.clear();
  ```

  por esto:

  ```dart
      if (Get.isRegistered<AcademicRecordService>()) AcademicRecordService.to.clear();
      // Los bloques de horario propios (RF-BLQ-7) son horarios de trabajo o de
      // prácticas que el backend protege a propósito (RS-BE-35): se vacían
      // igual que el récord. Con guarda por lo mismo que la línea de arriba.
      if (Get.isRegistered<TimeBlocksService>()) TimeBlocksService.to.clear();
  ```

- [ ] **Paso 4: Correr la prueba y ver que pasa**

  ```bash
  cd "${REPO:?}"
  "${FLUTTER:?}" test test/HU35_jeff/time_blocks_service_test.dart
  ```

  Esperado: PASS — `00:00 +19: All tests passed!`, los 19 casos. Sin el 3.g, el caso 17 falla en `expect(s.blocks, isEmpty)`.

  En la salida aparecen tres líneas de `debugPrint` —`Error cargando los bloques de horario: Exception: socket` (casos 9 y 18) y `Error escribiendo un bloque de horario: Exception: socket` (caso 16)—: son los fallos que esas tres pruebas provocan a propósito, no un test en rojo.

- [ ] **Paso 5: `analyze` sin issues nuevos**

  ```bash
  cd "${REPO:?}"
  "${FLUTTER:?}" analyze 2>&1 | tail -20
  ```

  Esperado: `7 issues found.`, el mismo número y la misma lista de la línea base del Paso 1, con una sola diferencia admitida: el `avoid_print` de `lib/main.dart` baja de la línea 85 a la 91, porque el Paso 3 metió seis líneas antes. Ningún issue en `lib/models/time_block_model.dart`, `lib/services/time_blocks_service.dart`, `lib/services/api_client.dart`, `lib/services/auth_service.dart`, `lib/main.dart` ni `test/HU35_jeff/time_blocks_service_test.dart`. Si aparece alguno en esos seis archivos, se arregla antes de seguir.

- [ ] **Paso 6: Regresión de lo que se tocó fuera de la funcionalidad**

  `api_client.dart` lo usa toda la app; `main.dart` lo importan dos suites de widget (`test/HU33_jeff/registro_page_test.dart:7` y `test/HU34_jeff/record_page_test.dart:17`, que montan su tabla de rutas); y el `logout()` de `auth_service.dart` lo prueban `test/HU02_jeff/` (TT06). Corren las suites que dependen de los tres:

  ```bash
  cd "${REPO:?}"
  "${FLUTTER:?}" test test/services/api_client_test.dart test/HU34_jeff test/HU33_jeff test/HU31_jeff test/HU02_jeff
  ```

  Esperado: PASS — `+254: All tests passed!` (1 + 142 + 52 + 52 + 7), sin ninguna prueba nueva en rojo. Tarda unos dos minutos: `test/HU33_jeff/registro_service_test.dart` tiene un caso que espera un plazo real. El cambio en `ApiClient` es puramente aditivo (un método nuevo), el de `main.dart` registra un servicio más dentro de `main()`, que ninguna de esas suites llega a ejecutar, y el de `logout()` va con guarda `Get.isRegistered`: `test/HU02_jeff/user_cache_reset_test.dart` llama a `logout()` sin registrar `TimeBlocksService`.

- [ ] **Paso 7: Documentar el contrato en `docs/specs/api-contracts.md`**

  Reemplazar la última línea del archivo (`docs/specs/api-contracts.md:541`), que hoy dice exactamente:

  ```markdown
  En la app, `AcademicRecordService` es el único que llama a estas dos rutas. Un fallo del `GET` deja la tarjeta y la pantalla en su estado de error. Un fallo del `DELETE` se muestra como "No se pudo borrar tu récord. Inténtalo de nuevo.".
  ```

  por eso mismo seguido de la sección nueva:

  ````markdown
  En la app, `AcademicRecordService` es el único que llama a estas dos rutas. Un fallo del `GET` deja la tarjeta y la pantalla en su estado de error. Un fallo del `DELETE` se muestra como "No se pudo borrar tu récord. Inténtalo de nuevo.".

  ## Time Blocks (bloques de horario propios) — RF-BLQ-1 a RF-BLQ-7

  Bloques que el propio alumno registra en su horario (prácticas, trabajo): un patrón semanal con rango de fechas, más excepciones por día. Ver `specs/features/time-blocks/time-blocks.spec.md` y, en el backend, RS-BE-30 a RS-BE-35 de `ULima_Backend_IS2/specs/features/time-blocks/time-blocks.spec.md`.

  Alumno (`requireRole(student|delegate|subdelegate)`); el alumno sale del token y no hay parámetro de alumno ni acceso para docentes. Las horas viajan como `"HH:MM"` y las fechas como `"YYYY-MM-DD"`, siempre en hora de Lima y sin zona pegada: son horas de pared. Una fecha que no existe en el calendario o que cae fuera de 2000-01-01 a 2099-12-31 es un formato inválido para el servidor; el formulario de la app solo ofrece fechas del año pasado a dos años adelante, dentro de ese rango. `daysOfWeek` usa la convención de `schedule_session.day_of_week`: 1 es lunes y 7 es domingo.

  - `GET /time-blocks/me`
    - Response `200`:
      ```json
      { "blocks": [ {
        "id": 12, "title": "PRÁCTICAS DE PRUEBA", "colorHex": "#EB5757",
        "daysOfWeek": [1, 3], "startTime": "14:00", "endTime": "18:00",
        "startDate": "2026-09-01", "endDate": "2026-12-15",
        "exceptions": [ { "date": "2026-10-07", "status": "cancelled",
                          "startTime": null, "endTime": null },
                        { "date": "2026-10-14", "status": "moved",
                          "startTime": "15:00", "endTime": "19:00" } ]
      } ] }
      ```
    - `status` es `"cancelled"` o `"moved"`. En `"cancelled"`, `startTime` y `endTime` son `null` y la app los conserva así.
  - `POST /time-blocks/me`
    - Body: `{ "title": string, "colorHex": "#RRGGBB", "daysOfWeek": number[], "startTime": "HH:MM", "endTime": "HH:MM", "startDate": "YYYY-MM-DD", "endDate": "YYYY-MM-DD" }`
    - Response `201`: `{ "block": { …como arriba, con "exceptions": [] } }`
  - `PATCH /time-blocks/me/:id`
    - Body: los mismos siete campos. Reemplaza la regla entera y **conserva** las excepciones.
    - Response `200`: `{ "block": … }`
  - `DELETE /time-blocks/me/:id`
    - Response `200`: `{ "ok": true }`. Borra el bloque y sus excepciones.
  - `PUT /time-blocks/me/:id/occurrences/:date`
    - Body: `{ "status": "cancelled" }` o `{ "status": "moved", "startTime": "15:00", "endTime": "19:00" }`. Con `"cancelled"` la app **no manda** `startTime` ni `endTime` (si llegaran, el servidor las ignora); con `"moved"` las dos son obligatorias.
    - Response `200`: `{ "exception": { "date": "2026-10-14", "status": "moved", "startTime": "15:00", "endTime": "19:00" } }`, con la forma de la excepción dentro de su bloque (en `"cancelled"`, las dos horas en `null`). La app no lee la respuesta: recarga su ventana.
    - Idempotente: repetir el mismo `PUT` deja el mismo estado, y un `PUT` sobre una fecha que ya tenía excepción la reemplaza.
    - La fecha tiene que caer dentro del rango del bloque y en uno de sus días de la semana.
  - `DELETE /time-blocks/me/:id/occurrences/:date`
    - Response `200`: `{ "ok": true }`. Ese día vuelve al patrón. Idempotente, y no exige que la fecha siga en el patrón: sirve para limpiar una excepción que quedó fuera después de un `PATCH`.
  - `GET /time-blocks/me/occurrences?from=YYYY-MM-DD&to=YYYY-MM-DD`
    - La ventana es obligatoria, incluye los dos extremos y cubre 120 días como máximo.
    - Response `200` para `?from=2026-09-21&to=2026-09-27`, con el bloque de arriba:
      ```json
      {
        "occurrences": [ { "blockId": 12, "title": "PRÁCTICAS DE PRUEBA", "colorHex": "#EB5757",
                           "date": "2026-09-21", "dayOfWeek": 1,
                           "startTime": "14:00", "endTime": "18:00", "moved": false },
                         { "blockId": 12, "title": "PRÁCTICAS DE PRUEBA", "colorHex": "#EB5757",
                           "date": "2026-09-23", "dayOfWeek": 3,
                           "startTime": "14:00", "endTime": "18:00", "moved": false } ],
        "weeks": [ { "weekStart": "2026-09-21", "hours": 8 } ]
      }
      ```
    - El servidor ya expandió el patrón y aplicó las excepciones: un día cancelado no aparece y uno movido llega con sus horas nuevas y `moved: true`. Las ocurrencias salen ordenadas por fecha y hora de inicio.
    - `weeks` trae una entrada por cada semana de lunes a domingo entre el lunes de `from` y el lunes de `to`, ordenadas, con ese lunes en `weekStart` (puede ser anterior a `from`) y en `hours` el total de horas de los bloques del alumno en la semana **entera**, aunque la ventana la corte. `hours` puede traer decimal (`8.5`). Un día cancelado no suma y uno movido suma su duración nueva. Una semana sin ocurrencias llega con `hours: 0`. Solo cuentan los bloques propios, nunca las clases.
    - La app pinta la línea de RF-BLQ-6 solo con `hours` mayor que 0: con `0`, con `null` (el backend no lo manda) o sin la semana en la lista, no hay línea.
  - Errores: `404 TIME_BLOCK_NOT_FOUND`; `400 INVALID_REQUEST_BODY` (body inválido en `POST`, `PATCH` y `PUT`); `400 INVALID_QUERY_PARAMS` (falta `from` o `to`, alguna no es una fecha válida, o `to` es anterior a `from`); `400 TIME_BLOCK_OUT_OF_GRID` (alguna hora fuera de 07:00–22:00, el rango que la grilla puede pintar); `400 TIME_BLOCK_LIMIT_REACHED` (máximo 20 bloques **guardados**, vencidos incluidos: el tope acota lo que el servidor expande en una ventana, y un bloque vencido se sigue expandiendo en una ventana pasada; su mensaje lo dice y sugiere borrar uno viejo); `400 TIME_BLOCK_OCCURRENCE_NOT_IN_PATTERN` (la fecha no cae en el patrón del bloque); `400 TIME_BLOCK_WINDOW_TOO_WIDE` (más de 120 días); `400 INVALID_ROUTE_PARAMS` (un `:id` o un `:date` mal formados); `400 INVALID_JSON_BODY` (un cuerpo que no es JSON, en `POST`, `PATCH` y `PUT`); más los 401/403 del middleware.

  En la app, `TimeBlocksService` es el único que llama a estas siete rutas. El mensaje de un error del servidor se muestra tal cual llega (RF-BLQ-2); un fallo sin mensaje —red caída o plazo vencido— se muestra como "No se pudo guardar tu bloque. Inténtalo de nuevo.". Los ejemplos usan datos inventados.
  ````

  **7.b — `isoDate` en los días de `GET /schedule/me/sessions`.** El backend agrega a cada elemento de `days` la fecha exacta de ese día (decisión D1 del dueño; RS-BE-36, Tarea 7 del plan del backend, que lo pone también en los días del docente, que la app no lee: el campo es aditivo y ningún campo existente cambia). La app la usa desde la Tarea 4 para pedir la ventana del ciclo y para saber qué bloques caen en cada día, en vez de leer `dateText`. En `docs/specs/api-contracts.md`, reemplazar esto (`:228-234`, el ejemplo de `days`; el reemplazo de arriba va al final del archivo y no corre este número):

  ```markdown
      "days": [
        {
          "dayName": "Lunes",
          "dateText": "12 de Enero",
          "weekText": "Semana 2 del ciclo"
        }
      ],
  ```

  por esto:

  ```markdown
      "days": [
        {
          "dayName": "Lunes",
          "dateText": "12 de Enero",
          "weekText": "Semana 2 del ciclo",
          "isoDate": "2026-01-12"
        }
      ],
  ```

  y, justo antes de la nota de `asistenciaDisponible` que sigue al ejemplo (la primera línea del archivo que empieza con `> **` después de él), esta nota nueva con su línea en blanco detrás:

  ```markdown
  > **`isoDate`** (RS-BE-36): la fecha de ese día en hora de Lima, `"YYYY-MM-DD"`, la misma de la que sale `dateText` (que no trae año). Llega en `null` cuando el ciclo no tiene semanas: el mismo caso en que `dateText` viene vacío y `weekText` dice "Semana actual". Es aditivo: un backend anterior no lo manda, y la app lo trata como `null`. La app lo usa para pedir los bloques propios del ciclo visible y para saber qué bloques caen en cada día (`specs/features/time-blocks/time-blocks.spec.md`, RF-BLQ-4 y RF-BLQ-7). Con `null`, solo el ciclo sin semanas, que llega con siete días, toma ese día de la semana en la semana de hoy; si llegan más de siete días sin `isoDate` (un ciclo con semanas que manda un backend sin RS-BE-36), no hay fecha y la app no pinta bloques propios ni la línea de horas.

  ```

  Si la nota de `asistenciaDisponible` o el ejemplo de `days` no aparecen literales, **PARAR** y reportarlo en vez de improvisar.

- [ ] **Paso 8: Anotar en el reporte**

  Cinco cosas que el dueño tiene que leer al cerrar la funcionalidad (Tarea 8):

  1. **`ApiClient` ganó `patchJson`.** Era el riesgo abierto del esqueleto: `putJson` ya existía, `patchJson` no (`grep -rn "patchJson" lib/` no daba nada antes de esta tarea). Se agregó copiando el estilo de `putJson` y es aditivo.
  2. **`AuthService.logout()` vacía también los bloques** (`TimeBlocksService.clear()`), con la misma guarda que el récord de TT06. Es el otro cambio fuera de los archivos de la funcionalidad; los dos se sumaron a los targets en el Paso 0.
  3. **Texto nuevo que puede ver el alumno**, uno solo en esta tarea: `TimeBlocksService.genericErrorMessage` = "No se pudo guardar tu bloque. Inténtalo de nuevo.", que sale solo cuando el fallo no trae mensaje del servidor (red caída o plazo vencido). Los mensajes que sí manda el servidor se muestran tal cual y no se inventan aquí.
  4. **La línea base de `analyze` sigue en 7 issues**, con el `avoid_print` de `main.dart` corrido de la línea 85 a la 91. Ese es el número contra el que compara la Tarea 8.
  5. **`docs/specs/api-contracts.md` documenta `isoDate`** en los días de `GET /schedule/me/sessions` (D1). La app lo necesita del backend: sin él (un backend anterior), la ventana cae a las cuatro semanas alrededor de hoy y cada día toma sus bloques de la semana de hoy (Tarea 4).

- [ ] **Paso final: Commit**

  ```bash
  cd "${REPO:?}"
  test "$(git branch --show-current)" = feat/bloques-horario-fe || echo 'PARAR: rama equivocada'
  git status --short
  git add lib/models/time_block_model.dart \
          lib/services/time_blocks_service.dart \
          lib/services/api_client.dart \
          lib/services/auth_service.dart \
          lib/main.dart \
          docs/specs/api-contracts.md \
          test/HU35_jeff/time_blocks_service_test.dart
  git commit -m "feat(time-blocks): modelo y capa de datos de los bloques de horario propios (RF-BLQ-7)

  docs/specs/api-contracts.md documenta las siete rutas de /time-blocks y el
  isoDate que gana cada día de GET /schedule/me/sessions."
  git log -1 --format=%B | grep -qi '^co-authored-by:' && echo 'PARAR: el commit trae trailer'
  ```

  Antes del `git add`, `git status --short` solo puede listar esos siete archivos (y `test/HU35_jeff/`, nueva); si lista otro, o sale un `PARAR`, se detiene aquí. Sin trailer `Co-Authored-By`: el autor ya está configurado en git.
### Tarea 2: Validadores y detección de cruces (funciones puras)

**Requisitos:** RF-BLQ-2 (la parte de validación) y RF-BLQ-3 completo.

**Archivos:**
- Crear: `lib/pages/time_blocks/time_block_validators.dart`
- Crear: `lib/pages/time_blocks/time_block_conflicts.dart`
- Test: `test/HU35_jeff/time_blocks_conflicto_test.dart`

No se modifica ningún archivo existente. En particular, `HorarioPage._timeToHours` (`horario.dart:92-126`) **no se toca**: la spec limita los cambios de `horario.dart` a lo que obligan el reparto, el domingo y el toque («Qué NO entra»), y el aviso de cruce no lo necesita. La lectura de la hora del aviso vive en `time_block_conflicts.dart` (`horaAMinutos`), y el reparto de la Tarea 4 usa el mismo `_timeToHours` que el dibujo.

**Interfaces:**

- Consume — de la Tarea 1, `lib/models/time_block_model.dart`:
  ```dart
  class TimeBlockRule {
    const TimeBlockRule({required this.id, required this.title, required this.colorHex,
      required this.daysOfWeek, required this.startTime, required this.endTime,
      required this.startDate, required this.endDate, required this.exceptions});
    final int id; final String title; final String colorHex;
    final List<int> daysOfWeek; final String startTime; final String endTime;
    final String startDate; final String endDate; final List<TimeBlockException> exceptions;
  }
  class TimeBlockException { final String date; final String status; final String? startTime; final String? endTime; }
  ```
  De `TimeBlockRule` esta tarea solo lee `id`, `title`, `daysOfWeek`, `startTime`, `endTime`, `startDate` y `endDate`; el resto aparece porque el constructor los pide. `TimeBlockException` solo se usa como tipo de una lista vacía constante, así que a la Tarea 1 le basta con exportar el tipo.

- Consume — del repo: el mapa de una **sección** del horario, con su lista `horarios` dentro. Esa es la forma que tiene `_todasLasSecciones` (`lib/pages/horario/horario_controller.dart:28`), que se llena tal cual desde `data['secciones']` en `:139-143` y `:197-201`, y que el contrato describe en `docs/specs/api-contracts.md:222-263`: cada sección trae `curso` y `horarios`, y cada horario trae `dia` (nombre en español, "Lunes"), `hora_inicio` y `hora_fin` en 12 h (`"08:00 am"`).

  **No** es la forma que devuelve `HorarioController.coursesForDay` (`horario_controller.dart:246-340`): esa función **aplana** sección y horario en un solo mapa (`{...section, ...horario}`, `:277-282`) y además filtra a un solo día. El aviso de cruce necesita todas las clases de la semana, así que la entrada es la lista de secciones sin aplanar. Hoy `_todasLasSecciones` es privada; quien llame (la Tarea 5) tendrá que exponerla —esa es tarea suya, no de esta—, y esta tarea solo fija la forma del parámetro.

  Precedente de estilo: `lib/pages/teacher/advising_validators.dart` (validadores puros que devuelven `String?` y se componen con `??`).

- Produce — `lib/pages/time_blocks/time_block_validators.dart`:
  ```dart
  String? validarNombre(String v);
  String? validarDias(Set<int> dias);
  String? validarHoras(String? inicio, String? fin);
  String? validarFechas(String? desde, String? hasta);
  String? validarFormulario({required String nombre, required Set<int> dias,
    required String? inicio, required String? fin, required String? desde, required String? hasta});
  ```
  Aviso de homónimo: ya existe otro `validarFormulario` de nivel superior en `lib/pages/portal_sync/portal_sync_controller.dart:32`, con otra firma (`{required String password, required String passcode}`). No chocan porque Dart solo los ve juntos si un mismo archivo importa los dos, y ninguno lo hace ni lo va a hacer. Se conserva el nombre porque es el que fija el esqueleto; si algún día la Tarea 5 necesitara los dos, se importa uno con `as`.

- Produce — `lib/pages/time_blocks/time_block_conflicts.dart`:
  ```dart
  class Cruce {
    const Cruce({required this.conQue, required this.dia, required this.inicio, required this.fin});
    final String conQue; final int dia; final String inicio; final String fin;
  }
  int? horaAMinutos(String texto);
  bool seCruzan(String inicioA, String finA, String inicioB, String finB);
  List<Cruce> crucesDeBloque({
    required Set<int> dias, required String inicio, required String fin,
    required List<Map<String, dynamic>> secciones,
    required List<TimeBlockRule> bloques, int? ignorarBloqueId,
    String? desde, String? hasta,
  });
  String mensajeDeCruce(List<Cruce> cruces);
  ```
  `horaAMinutos` lee las dos formas de hora que circulan por la app, como `HorarioPage._timeToHours` (`horario.dart:92-126`), pero devuelve `null` ante un texto ilegible en vez del `7.0` silencioso de la grilla: aquí no hay dónde pintar, y una hora que no se lee no genera un aviso. `_timeToHours` no cambia. `desde` y `hasta` (`"YYYY-MM-DD"`, los del bloque que se está guardando) sirven para no avisar de un cruce con un bloque propio de otro rango de fechas: los dos nunca coinciden. `crucesDeBloque` y `mensajeDeCruce` los consume la Tarea 5.

---

- [ ] **Paso 1: Escribir la prueba que falla**

Crear `test/HU35_jeff/time_blocks_conflicto_test.dart` (la carpeta `test/HU35_jeff/` ya existe desde la Tarea 1):

```dart
// test/HU35_jeff/time_blocks_conflicto_test.dart
//
// UNITARIA — HU35 (bloques de horario propios): los validadores puros del
// formulario (RF-BLQ-2) y la detección de cruces contra las clases del horario
// y contra los demás bloques del alumno (RF-BLQ-3).
// Prueba: lib/pages/time_blocks/time_block_validators.dart
//         lib/pages/time_blocks/time_block_conflicts.dart
//
// Todos los valores son inventados: cursos "CURSO DE PRUEBA …" y secciones
// 80x. El repo es público: nada sale de un horario real, ni se reutilizan los
// fixtures del backend (test/HU31_jeff/fixtures) ni los del spike del portal.

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/models/time_block_model.dart';
import 'package:ulima_plus/pages/time_blocks/time_block_conflicts.dart';
import 'package:ulima_plus/pages/time_blocks/time_block_validators.dart';

void main() {
  // --- Datos inventados ----------------------------------------------------

  /// Una sección del horario con la forma que tiene `_todasLasSecciones`: la
  /// sección con su lista de `horarios`, y cada horario con `dia`,
  /// `hora_inicio` y `hora_fin` en 12 h.
  Map<String, dynamic> seccion(
    String curso,
    String codigo,
    List<Map<String, String>> horarios,
  ) => <String, dynamic>{
    'idSeccion': codigo,
    'codigoSeccion': codigo,
    'curso': curso,
    'horarios': horarios,
  };

  Map<String, String> clase(String dia, String inicio, String fin) =>
      <String, String>{'dia': dia, 'hora_inicio': inicio, 'hora_fin': fin};

  /// Un bloque propio ya guardado. Recibe los valores por parámetro para no
  /// repetir los siete campos del constructor en cada prueba.
  TimeBlockRule bloquePropio({
    required int id,
    required String titulo,
    required List<int> dias,
    required String inicio,
    required String fin,
  }) => TimeBlockRule(
    id: id,
    title: titulo,
    colorHex: '#F94B3F',
    daysOfWeek: dias,
    startTime: inicio,
    endTime: fin,
    startDate: '2026-09-01',
    endDate: '2026-12-15',
    exceptions: const <TimeBlockException>[],
  );

  const sinSecciones = <Map<String, dynamic>>[];
  const sinBloques = <TimeBlockRule>[];

  // --- Validadores (RF-BLQ-2) ----------------------------------------------

  group('validarNombre', () {
    test('vacío → error', () => expect(validarNombre(''), isNotNull));
    test('solo espacios → error', () => expect(validarNombre('   '), isNotNull));
    test('60 caracteres → ok', () => expect(validarNombre('a' * 60), isNull));
    test('61 caracteres → error', () => expect(validarNombre('a' * 61), isNotNull));
    test('un nombre normal → ok', () => expect(validarNombre('Prácticas'), isNull));
  });

  group('validarDias', () {
    test('ninguno → error', () => expect(validarDias(<int>{}), isNotNull));
    test('0 no es un día → error', () => expect(validarDias(<int>{0}), isNotNull));
    test('8 no es un día → error', () => expect(validarDias(<int>{8}), isNotNull));
    test('solo lunes → ok', () => expect(validarDias(<int>{1}), isNull));
    test('lunes, miércoles y domingo → ok',
        () => expect(validarDias(<int>{1, 3, 7}), isNull));
  });

  group('validarHoras', () {
    test('sin horas → error', () => expect(validarHoras(null, null), isNotNull));
    test('solo la de inicio → error', () => expect(validarHoras('14:00', null), isNotNull));
    test('formato de 12 h → error: el formulario entrega HH:MM',
        () => expect(validarHoras('2 pm', '6 pm'), isNotNull));
    test('fin antes que inicio → error', () => expect(validarHoras('18:00', '16:00'), isNotNull));
    test('iguales → error', () => expect(validarHoras('16:00', '16:00'), isNotNull));
    test('antes de las 7 am → error', () => expect(validarHoras('06:30', '09:00'), isNotNull));
    test('después de las 10 pm → error', () => expect(validarHoras('20:00', '22:30'), isNotNull));
    test('los bordes de la grilla sí entran',
        () => expect(validarHoras('07:00', '22:00'), isNull));
    test('un rango normal → ok', () => expect(validarHoras('14:00', '18:00'), isNull));
  });

  group('validarFechas', () {
    test('sin fechas → error', () => expect(validarFechas(null, '2026-12-15'), isNotNull));
    test('hasta antes que desde → error',
        () => expect(validarFechas('2026-12-15', '2026-09-01'), isNotNull));
    test('un solo día → ok', () => expect(validarFechas('2026-09-01', '2026-09-01'), isNull));
    test('texto que no es fecha → error',
        () => expect(validarFechas('mañana', '2026-09-02'), isNotNull));
    test('un ciclo entero → ok',
        () => expect(validarFechas('2026-09-01', '2026-12-15'), isNull));
  });

  group('validarFormulario', () {
    test('todo correcto → null', () {
      expect(
        validarFormulario(
          nombre: 'Prácticas',
          dias: <int>{1, 3},
          inicio: '14:00',
          fin: '18:00',
          desde: '2026-09-01',
          hasta: '2026-12-15',
        ),
        isNull,
      );
    });

    test('sin días marcados devuelve el mensaje de validarDias', () {
      expect(
        validarFormulario(
          nombre: 'Prácticas',
          dias: <int>{},
          inicio: '14:00',
          fin: '18:00',
          desde: '2026-09-01',
          hasta: '2026-12-15',
        ),
        validarDias(<int>{}),
      );
    });

    test('el nombre manda sobre los días: se reporta el primer problema', () {
      expect(
        validarFormulario(
          nombre: '  ',
          dias: <int>{},
          inicio: '18:00',
          fin: '14:00',
          desde: '2026-12-15',
          hasta: '2026-09-01',
        ),
        validarNombre('  '),
      );
    });
  });

  // --- Lectura de la hora del horario (las dos formas que circulan) --------

  group('horaAMinutos', () {
    test('12 h con am', () {
      expect(horaAMinutos('8:00 am'), 480);
    });
    test('12 h con pm, como lo manda el horario', () {
      expect(horaAMinutos('04:00 pm'), 960);
    });
    test('24 h con segundos', () => expect(horaAMinutos('14:00:00'), 840));
    test('24 h sin segundos', () => expect(horaAMinutos('14:30'), 870));
    test('medianoche y mediodía no se confunden', () {
      expect(horaAMinutos('12:00 am'), 0);
      expect(horaAMinutos('12:00 pm'), 720);
    });
    test('texto ilegible → null, no las 7 en silencio', () {
      expect(horaAMinutos('a las ocho'), isNull);
    });
    test('vacío → null', () => expect(horaAMinutos(''), isNull));
  });

  // --- Cruce entre dos rangos (RF-BLQ-3) -----------------------------------

  group('seCruzan', () {
    test('tocarse en el borde NO es cruce',
        () => expect(seCruzan('16:00', '18:00', '18:00', '20:00'), isFalse));
    test('tocarse en el borde tampoco al revés',
        () => expect(seCruzan('18:00', '20:00', '16:00', '18:00'), isFalse));
    test('solaparse a medias es cruce',
        () => expect(seCruzan('16:00', '18:00', '17:00', '19:00'), isTrue));
    test('uno contenido en el otro es cruce',
        () => expect(seCruzan('14:00', '18:00', '15:00', '16:00'), isTrue));
    test('compara bien los dos formatos mezclados',
        () => expect(seCruzan('14:00', '18:00', '4:00 pm', '6:00 pm'), isTrue));
    test('una hora ilegible no inventa un cruce',
        () => expect(seCruzan('14:00', '18:00', 'por confirmar', '18:00'), isFalse));
  });

  // --- Cruces del bloque contra el horario (RF-BLQ-3) ----------------------

  group('crucesDeBloque', () {
    final martes4a6 = <Map<String, dynamic>>[
      seccion('CURSO DE PRUEBA A', '801', <Map<String, String>>[
        clase('Martes', '04:00 pm', '06:00 pm'),
      ]),
    ];

    test('una clase el mismo día y a la misma hora es un cruce', () {
      final cruces = crucesDeBloque(
        dias: <int>{2},
        inicio: '14:00',
        fin: '18:00',
        secciones: martes4a6,
        bloques: sinBloques,
      );
      expect(cruces, hasLength(1));
      expect(cruces.first.conQue, 'CURSO DE PRUEBA A');
      expect(cruces.first.dia, 2);
      expect(cruces.first.inicio, '16:00');
      expect(cruces.first.fin, '18:00');
    });

    test('la misma clase en otro día no cruza', () {
      expect(
        crucesDeBloque(
          dias: <int>{3},
          inicio: '14:00',
          fin: '18:00',
          secciones: martes4a6,
          bloques: sinBloques,
        ),
        isEmpty,
      );
    });

    test('empezar justo cuando la clase termina no cruza', () {
      expect(
        crucesDeBloque(
          dias: <int>{2},
          inicio: '18:00',
          fin: '20:00',
          secciones: martes4a6,
          bloques: sinBloques,
        ),
        isEmpty,
      );
    });

    test('se listan todas las clases cruzadas, ordenadas por hora', () {
      final cruces = crucesDeBloque(
        dias: <int>{1},
        inicio: '08:00',
        fin: '12:00',
        secciones: <Map<String, dynamic>>[
          seccion('CURSO DE PRUEBA B', '802', <Map<String, String>>[
            clase('Lunes', '09:00 am', '11:00 am'),
          ]),
          seccion('CURSO DE PRUEBA A', '801', <Map<String, String>>[
            clase('Lunes', '08:00 am', '10:00 am'),
          ]),
        ],
        bloques: sinBloques,
      );
      expect(cruces.map((c) => c.conQue).toList(),
          <String>['CURSO DE PRUEBA A', 'CURSO DE PRUEBA B']);
    });

    test('el día sin tilde del horario también se reconoce', () {
      final cruces = crucesDeBloque(
        dias: <int>{3},
        inicio: '14:00',
        fin: '18:00',
        secciones: <Map<String, dynamic>>[
          seccion('CURSO DE PRUEBA C', '803', <Map<String, String>>[
            clase('Miercoles', '03:00 pm', '05:00 pm'),
          ]),
        ],
        bloques: sinBloques,
      );
      expect(cruces, hasLength(1));
      expect(cruces.first.dia, 3);
    });

    test('una hora ilegible del horario no genera un aviso', () {
      expect(
        crucesDeBloque(
          dias: <int>{2},
          inicio: '14:00',
          fin: '18:00',
          secciones: <Map<String, dynamic>>[
            seccion('CURSO DE PRUEBA A', '801', <Map<String, String>>[
              clase('Martes', 'por confirmar', 'por confirmar'),
            ]),
          ],
          bloques: sinBloques,
        ),
        isEmpty,
      );
    });

    test('cruza con otro bloque propio', () {
      final cruces = crucesDeBloque(
        dias: <int>{3},
        inicio: '16:00',
        fin: '19:00',
        secciones: sinSecciones,
        bloques: <TimeBlockRule>[
          bloquePropio(
            id: 7,
            titulo: 'Prácticas',
            dias: <int>[1, 3],
            inicio: '14:00',
            fin: '18:00',
          ),
        ],
      );
      expect(cruces, hasLength(1));
      expect(cruces.first.conQue, 'Prácticas');
      expect(cruces.first.dia, 3);
      expect(cruces.first.inicio, '14:00');
      expect(cruces.first.fin, '18:00');
    });

    test('al editar, un bloque no se cruza consigo mismo', () {
      expect(
        crucesDeBloque(
          dias: <int>{3},
          inicio: '16:00',
          fin: '19:00',
          secciones: sinSecciones,
          bloques: <TimeBlockRule>[
            bloquePropio(
              id: 7,
              titulo: 'Prácticas',
              dias: <int>[1, 3],
              inicio: '14:00',
              fin: '18:00',
            ),
          ],
          ignorarBloqueId: 7,
        ),
        isEmpty,
      );
    });

    test('un bloque propio de otro rango de fechas no cruza', () {
      // Prácticas va del 1 de septiembre al 15 de diciembre; el bloque nuevo,
      // de enero a febrero. Mismo día y misma hora, pero nunca coinciden.
      final practicas = <TimeBlockRule>[
        bloquePropio(
          id: 7,
          titulo: 'Prácticas',
          dias: <int>[1, 3],
          inicio: '14:00',
          fin: '18:00',
        ),
      ];
      expect(
        crucesDeBloque(
          dias: <int>{3},
          inicio: '16:00',
          fin: '19:00',
          desde: '2027-01-04',
          hasta: '2027-02-26',
          secciones: sinSecciones,
          bloques: practicas,
        ),
        isEmpty,
      );
      // Con los rangos solapados (del miércoles 9 al 15 de diciembre) sí cruza.
      expect(
        crucesDeBloque(
          dias: <int>{3},
          inicio: '16:00',
          fin: '19:00',
          desde: '2026-12-09',
          hasta: '2027-02-26',
          secciones: sinSecciones,
          bloques: practicas,
        ),
        hasLength(1),
      );
    });

    test('el domingo cruza como cualquier otro día', () {
      final cruces = crucesDeBloque(
        dias: <int>{7},
        inicio: '09:00',
        fin: '11:00',
        secciones: sinSecciones,
        bloques: <TimeBlockRule>[
          bloquePropio(
            id: 9,
            titulo: 'Voluntariado',
            dias: <int>[7],
            inicio: '10:00',
            fin: '13:00',
          ),
        ],
      );
      expect(cruces, hasLength(1));
      expect(cruces.first.dia, 7);
    });

    test('sin clases ni bloques no hay nada que avisar', () {
      expect(
        crucesDeBloque(
          dias: <int>{1, 2, 3, 4, 5, 6, 7},
          inicio: '07:00',
          fin: '22:00',
          secciones: sinSecciones,
          bloques: sinBloques,
        ),
        isEmpty,
      );
    });
  });

  // --- El texto del aviso (RF-BLQ-3) ---------------------------------------

  group('mensajeDeCruce', () {
    test('sin cruces no hay mensaje', () => expect(mensajeDeCruce(const <Cruce>[]), ''));

    test('un cruce se nombra con curso, día y horas, en el formato de la spec', () {
      final cruces = crucesDeBloque(
        dias: <int>{2},
        inicio: '14:00',
        fin: '18:00',
        secciones: <Map<String, dynamic>>[
          seccion('CURSO DE PRUEBA A', '801', <Map<String, String>>[
            clase('Martes', '04:00 pm', '06:00 pm'),
          ]),
        ],
        bloques: sinBloques,
      );
      expect(
        mensajeDeCruce(cruces),
        'Se cruza con CURSO DE PRUEBA A, martes de 4:00 pm a 6:00 pm.',
      );
    });

    test('varios cruces se listan uno por línea, en el orden recibido', () {
      expect(
        mensajeDeCruce(const <Cruce>[
          Cruce(conQue: 'CURSO DE PRUEBA A', dia: 1, inicio: '08:00', fin: '10:00'),
          Cruce(conQue: 'CURSO DE PRUEBA B', dia: 1, inicio: '09:00', fin: '11:00'),
        ]),
        'Se cruza con:\n'
        '• CURSO DE PRUEBA A, lunes de 8:00 am a 10:00 am\n'
        '• CURSO DE PRUEBA B, lunes de 9:00 am a 11:00 am',
      );
    });

    test('el mediodía se escribe 12 pm, no 0 pm', () {
      expect(
        mensajeDeCruce(const <Cruce>[
          Cruce(conQue: 'Prácticas', dia: 6, inicio: '12:00', fin: '13:30'),
        ]),
        'Se cruza con Prácticas, sábado de 12:00 pm a 1:30 pm.',
      );
    });
  });
}
```

- [ ] **Paso 2: Correr la prueba y ver que falla**

```
cd "${REPO:?}"
"${FLUTTER:?}" test test/HU35_jeff/time_blocks_conflicto_test.dart
```

Esperado: **FALLA al compilar**, no en un `expect`. La salida trae, entre otras (las rutas de los dos primeros errores pueden salir absolutas):

```
Error: Error when reading 'lib/pages/time_blocks/time_block_conflicts.dart': No such file or directory
Error: Error when reading 'lib/pages/time_blocks/time_block_validators.dart': No such file or directory
Error: Method not found: 'validarNombre'.
Error: Method not found: 'horaAMinutos'.
Error: Method not found: 'crucesDeBloque'.
Error: 'Cruce' isn't a type.
Failed to load "test/HU35_jeff/time_blocks_conflicto_test.dart": Compilation failed
```

Si en vez de eso falla por `TimeBlockRule` o `TimeBlockException`, la Tarea 1 no está: **PARAR** y terminarla antes de seguir.

- [ ] **Paso 3: Implementación mínima**

Crear `lib/pages/time_blocks/time_block_validators.dart`:

```dart
// lib/pages/time_blocks/time_block_validators.dart
// Validadores puros del formulario de bloques propios (HU35, RF-BLQ-2). Sin
// Flutter ni I/O: devuelven null si el campo está bien, o un mensaje en
// español, y se componen con `??`. Mismo patrón que
// lib/pages/teacher/advising_validators.dart.
//
// El servidor vuelve a validar todo (RS-BE-31): estos mensajes son para que el
// alumno no llegue al servidor con un formulario obviamente incompleto. Ante un
// error del servidor se muestra el mensaje del servidor, no uno de aquí.

/// Largo máximo del título, el mismo que el CHECK `chk_time_block_titulo` y el
/// `max(60)` del esquema Zod del backend.
const int _largoMaximoDelNombre = 60;

/// Primera y última hora que la grilla del horario puede pintar
/// (`HorarioPage.startHour` y `endHour`, horario.dart:21-22). Un bloque fuera
/// de ahí sería invisible en la app, y el servidor lo rechaza con
/// `TIME_BLOCK_OUT_OF_GRID`.
const int _minutoMinimoDeLaGrilla = 7 * 60;
const int _minutoMaximoDeLaGrilla = 22 * 60;

final RegExp _hhmm = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
final RegExp _fechaPlana = RegExp(r'^\d{4}-\d{2}-\d{2}$');

/// Minutos desde medianoche de un `"HH:MM"` estricto, o null si no lo es.
/// A propósito NO acepta "4:00 pm": el formulario entrega siempre `HH:MM`.
int? _minutosDeHhmm(String v) {
  if (!_hhmm.hasMatch(v)) return null;
  final partes = v.split(':');
  return int.parse(partes[0]) * 60 + int.parse(partes[1]);
}

String? validarNombre(String v) {
  final limpio = v.trim();
  if (limpio.isEmpty) return 'Ponle un nombre al bloque.';
  if (limpio.length > _largoMaximoDelNombre) {
    return 'El nombre no puede pasar de $_largoMaximoDelNombre caracteres.';
  }
  return null;
}

/// 1 es lunes y 7 es domingo, la misma convención que `schedule_session`.
String? validarDias(Set<int> dias) {
  if (dias.isEmpty) return 'Marca al menos un día.';
  if (dias.any((d) => d < 1 || d > 7)) return 'Hay un día que no existe.';
  return null;
}

String? validarHoras(String? inicio, String? fin) {
  if (inicio == null || inicio.isEmpty || fin == null || fin.isEmpty) {
    return 'Indica la hora de inicio y de fin.';
  }
  final desde = _minutosDeHhmm(inicio);
  final hasta = _minutosDeHhmm(fin);
  if (desde == null || hasta == null) return 'Hora inválida (usa HH:MM).';
  if (hasta <= desde) return 'La hora de fin debe ser posterior a la de inicio.';
  if (desde < _minutoMinimoDeLaGrilla || hasta > _minutoMaximoDeLaGrilla) {
    return 'El bloque tiene que estar entre las 7 am y las 10 pm.';
  }
  return null;
}

String? validarFechas(String? desde, String? hasta) {
  if (desde == null || desde.isEmpty || hasta == null || hasta.isEmpty) {
    return 'Indica desde y hasta cuándo va el bloque.';
  }
  final inicio = _fechaPlana.hasMatch(desde) ? DateTime.tryParse(desde) : null;
  final fin = _fechaPlana.hasMatch(hasta) ? DateTime.tryParse(hasta) : null;
  if (inicio == null || fin == null) return 'Fecha inválida (usa AAAA-MM-DD).';
  if (fin.isBefore(inicio)) {
    return 'La fecha de fin no puede ser anterior a la de inicio.';
  }
  return null;
}

/// Todo el formulario, en orden de precedencia: se reporta el primer problema,
/// que es el que el alumno tiene más arriba en la pantalla.
String? validarFormulario({
  required String nombre,
  required Set<int> dias,
  required String? inicio,
  required String? fin,
  required String? desde,
  required String? hasta,
}) {
  return validarNombre(nombre) ??
      validarDias(dias) ??
      validarHoras(inicio, fin) ??
      validarFechas(desde, hasta);
}
```

Crear `lib/pages/time_blocks/time_block_conflicts.dart`:

```dart
// lib/pages/time_blocks/time_block_conflicts.dart
// Detección pura de cruces de un bloque propio (HU35, RF-BLQ-3): contra las
// clases que el horario ya tiene en pantalla y contra los demás bloques del
// alumno. Sin Flutter, sin HTTP y sin GetX, para poder probarla sin montar
// widgets — igual que HorarioPage.blockGeometry y blockMetaLines.
//
// El cruce nunca impide guardar: solo alimenta el aviso que ofrece guardar
// igual o volver a editar. La spec del backend no menciona cruces en ninguna
// de sus reglas, así que este aviso es lo único que avisa.

import '../../models/time_block_model.dart';

/// Un cruce encontrado: con qué, qué día y a qué hora.
///
/// [dia] es 1 (lunes) a 7 (domingo). [inicio] y [fin] son `"HH:MM"` de 24 h,
/// normalizados: la clase los trae en 12 h ("04:00 pm") y el bloque propio en
/// 24 h, y el aviso tiene que leerse igual venga de donde venga.
class Cruce {
  const Cruce({
    required this.conQue,
    required this.dia,
    required this.inicio,
    required this.fin,
  });

  final String conQue;
  final int dia;
  final String inicio;
  final String fin;
}

/// Los días como se escriben en el aviso.
const List<String> _nombresDeDia = <String>[
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

/// Los mismos sin tilde: el horario manda "Miércoles" o "Miercoles" según de
/// dónde venga, y `_weekDays` de `HorarioPage` ya tolera las dos formas.
const List<String> _nombresDeDiaSinTilde = <String>[
  'lunes',
  'martes',
  'miercoles',
  'jueves',
  'viernes',
  'sabado',
  'domingo',
];

/// Nombre del día del horario → 1..7, o null si no es un día conocido.
int? _diaANumero(String nombre) {
  final limpio = nombre
      .trim()
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u');
  if (limpio.isEmpty) return null;
  final i = _nombresDeDiaSinTilde.indexOf(limpio);
  return i < 0 ? null : i + 1;
}

/// Minutos desde medianoche de una hora del horario.
///
/// Acepta las dos formas que circulan por la app: 12 h con sufijo
/// ("8:00 am", "04:00 pm") y 24 h con o sin segundos ("14:00", "14:00:00").
///
/// Devuelve null cuando no se puede leer. Ahí está la diferencia con
/// `HorarioPage._timeToHours`, que devuelve 7.0 para pintar el bloque al
/// inicio de la grilla en vez de hacerlo desaparecer: aquí no hay nada que
/// pintar, y una hora que no se lee no genera un aviso de cruce.
int? horaAMinutos(String texto) {
  var limpio = texto.trim().toLowerCase();
  if (limpio.isEmpty) return null;

  var esDoceHoras = false;
  var esPm = false;
  if (limpio.endsWith('am') || limpio.endsWith('pm')) {
    esPm = limpio.endsWith('pm');
    esDoceHoras = true;
    limpio = limpio.substring(0, limpio.length - 2).trim();
  }

  final partes = limpio.split(':');
  var hora = int.tryParse(partes[0].trim());
  if (hora == null) return null;
  final minuto = partes.length > 1 ? int.tryParse(partes[1].trim()) : 0;
  if (minuto == null || minuto < 0 || minuto > 59) return null;

  if (esDoceHoras) {
    if (hora < 1 || hora > 12) return null;
    if (esPm && hora != 12) hora += 12;
    if (!esPm && hora == 12) hora = 0;
  } else if (hora < 0 || hora > 23) {
    return null;
  }
  return hora * 60 + minuto;
}

String _enHhmm(int minutos) =>
    '${(minutos ~/ 60).toString().padLeft(2, '0')}:'
    '${(minutos % 60).toString().padLeft(2, '0')}';

/// Para el aviso, que se lee en 12 h como el resto del horario. Solo recibe
/// horas que salieron de [_enHhmm], así que el respaldo de 0 es inalcanzable
/// desde [crucesDeBloque]; está para que un [Cruce] armado a mano no reviente.
String _en12h(String hhmm) {
  final minutos = horaAMinutos(hhmm) ?? 0;
  final hora24 = minutos ~/ 60;
  final resto = minutos % 60;
  final sufijo = hora24 >= 12 ? 'pm' : 'am';
  final hora12 = hora24 % 12 == 0 ? 12 : hora24 % 12;
  return '$hora12:${resto.toString().padLeft(2, '0')} $sufijo';
}

/// Dos rangos del MISMO día se cruzan si uno empieza antes de que el otro
/// termine. Tocarse en el borde (una termina 18:00 y la otra empieza 18:00)
/// **no** es cruce.
bool _minutosSeCruzan(int inicioA, int finA, int inicioB, int finB) =>
    inicioA < finB && inicioB < finA;

/// [_minutosSeCruzan] sobre horas en texto, en cualquiera de los dos formatos.
/// Si alguna hora no se puede leer devuelve false: no se avisa de un cruce que
/// no se pudo comprobar.
bool seCruzan(String inicioA, String finA, String inicioB, String finB) {
  final ia = horaAMinutos(inicioA);
  final fa = horaAMinutos(finA);
  final ib = horaAMinutos(inicioB);
  final fb = horaAMinutos(finB);
  if (ia == null || fa == null || ib == null || fb == null) return false;
  return _minutosSeCruzan(ia, fa, ib, fb);
}

/// Si dos rangos de fechas `YYYY-MM-DD` (con los dos extremos dentro) se
/// solapan. Las fechas planas se comparan como texto. Si falta alguna, no se
/// descarta nada: sin fechas no se puede saber, y el aviso prefiere avisar de
/// más que callar un cruce real.
bool _rangosSeSolapan(
  String? desdeA,
  String? hastaA,
  String desdeB,
  String hastaB,
) {
  if (desdeA == null || hastaA == null || desdeB.isEmpty || hastaB.isEmpty) {
    return true;
  }
  return desdeA.compareTo(hastaB) <= 0 && desdeB.compareTo(hastaA) <= 0;
}

/// Con qué choca un bloque que el alumno está por guardar.
///
/// [secciones] son las secciones del horario **sin aplanar**, como las tiene
/// `_todasLasSecciones` del controller: cada una con `curso` y una lista
/// `horarios` de mapas con `dia`, `hora_inicio` y `hora_fin`. [bloques] son los
/// bloques propios ya guardados. [ignorarBloqueId] sirve al editar: un bloque
/// no se cruza consigo mismo.
///
/// Contra las clases mira el día de la semana y la hora: el horario de clases
/// es el del ciclo y no trae fechas. Contra los demás bloques propios mira
/// además el rango de fechas: si [desde] y [hasta] (los del bloque que se
/// guarda) no se solapan con los de otro bloque, los dos nunca coinciden y no
/// hay cruce que avisar. Compara los rangos, no día por día.
///
/// La lista sale ordenada por día y por hora de inicio, para que el aviso se
/// lea siempre igual sin importar en qué orden llegaron las clases.
List<Cruce> crucesDeBloque({
  required Set<int> dias,
  required String inicio,
  required String fin,
  required List<Map<String, dynamic>> secciones,
  required List<TimeBlockRule> bloques,
  int? ignorarBloqueId,
  String? desde,
  String? hasta,
}) {
  final inicioMin = horaAMinutos(inicio);
  final finMin = horaAMinutos(fin);
  if (inicioMin == null || finMin == null) return const <Cruce>[];

  final cruces = <Cruce>[];

  for (final seccion in secciones) {
    final horarios = seccion['horarios'];
    if (horarios is! List) continue;
    final curso = (seccion['curso'] as String? ?? '').trim();
    for (final crudo in horarios) {
      if (crudo is! Map) continue;
      final dia = _diaANumero(crudo['dia'] as String? ?? '');
      if (dia == null || !dias.contains(dia)) continue;
      final desdeMin = horaAMinutos(crudo['hora_inicio'] as String? ?? '');
      final hastaMin = horaAMinutos(crudo['hora_fin'] as String? ?? '');
      if (desdeMin == null || hastaMin == null) continue;
      if (!_minutosSeCruzan(inicioMin, finMin, desdeMin, hastaMin)) continue;
      cruces.add(Cruce(
        conQue: curso.isEmpty ? 'una clase' : curso,
        dia: dia,
        inicio: _enHhmm(desdeMin),
        fin: _enHhmm(hastaMin),
      ));
    }
  }

  for (final bloque in bloques) {
    if (ignorarBloqueId != null && bloque.id == ignorarBloqueId) continue;
    if (!_rangosSeSolapan(desde, hasta, bloque.startDate, bloque.endDate)) {
      continue;
    }
    final desdeMin = horaAMinutos(bloque.startTime);
    final hastaMin = horaAMinutos(bloque.endTime);
    if (desdeMin == null || hastaMin == null) continue;
    if (!_minutosSeCruzan(inicioMin, finMin, desdeMin, hastaMin)) continue;
    for (final dia in bloque.daysOfWeek) {
      if (!dias.contains(dia)) continue;
      cruces.add(Cruce(
        conQue: bloque.title,
        dia: dia,
        inicio: _enHhmm(desdeMin),
        fin: _enHhmm(hastaMin),
      ));
    }
  }

  cruces.sort((a, b) {
    final porDia = a.dia.compareTo(b.dia);
    return porDia != 0 ? porDia : a.inicio.compareTo(b.inicio);
  });
  return cruces;
}

/// El texto del aviso: nombra con qué y cuándo. Cadena vacía si no hay cruces
/// (quien llama no debe mostrar el aviso en ese caso).
String mensajeDeCruce(List<Cruce> cruces) {
  if (cruces.isEmpty) return '';
  final partes = cruces
      .map((c) =>
          '${c.conQue}, ${_nombresDeDia[c.dia - 1]} '
          'de ${_en12h(c.inicio)} a ${_en12h(c.fin)}')
      .toList();
  if (partes.length == 1) return 'Se cruza con ${partes.first}.';
  return 'Se cruza con:\n${partes.map((p) => '• $p').join('\n')}';
}
```

`horario.dart` no se toca en esta tarea: `_timeToHours` sigue como está (ver «Archivos»).

- [ ] **Paso 4: Correr la prueba y ver que pasa**

```
cd "${REPO:?}"
"${FLUTTER:?}" test test/HU35_jeff/time_blocks_conflicto_test.dart
```

Esperado: **PASS**, 55 pruebas, `+55: All tests passed!`.

- [ ] **Paso 5: Análisis**

Esta tarea solo crea archivos nuevos, así que no hace falta regresión del horario; basta comparar el análisis con la línea base que la Tarea 1 anotó (el esqueleto la estima en 7 issues preexistentes; vale el número medido, no el estimado):

```
cd "${REPO:?}"
"${FLUTTER:?}" analyze
```

Esperado: `flutter analyze` con los **mismos issues** de la línea base, ninguno nuevo y ninguno en los archivos de esta tarea. Si aparece un issue nuevo, corregirlo antes del commit; si aparece uno que no se entiende, **PARAR** y reportarlo.

- [ ] **Paso 6: Anotar los textos nuevos para el reporte**

Esta tarea introduce texto que el alumno va a ver. Copiarlo tal cual al reporte de la rama (la Tarea 8 los reúne todos para que el dueño los lea antes de publicar el APK); no va a ningún archivo del repo:

```
Validación — nombre:  "Ponle un nombre al bloque."
                      "El nombre no puede pasar de 60 caracteres."
Validación — días:    "Marca al menos un día."
                      "Hay un día que no existe."
Validación — horas:   "Indica la hora de inicio y de fin."
                      "Hora inválida (usa HH:MM)."
                      "La hora de fin debe ser posterior a la de inicio."
                      "El bloque tiene que estar entre las 7 am y las 10 pm."
Validación — fechas:  "Indica desde y hasta cuándo va el bloque."
                      "Fecha inválida (usa AAAA-MM-DD)."
                      "La fecha de fin no puede ser anterior a la de inicio."
Aviso de cruce (uno): "Se cruza con CURSO DE PRUEBA A, martes de 4:00 pm a 6:00 pm."
Aviso de cruce (varios): "Se cruza con:" y una línea "• <nombre>, <día> de <hora> a <hora>" por cruce.
```

De todo esto, lo único que la spec escribe es el patrón del aviso de un solo cruce, y lo escribe dentro de una frase y en minúscula: «se cruza con Paradigmas de Programación, martes de 4:00 pm a 6:00 pm» (RF-BLQ-3). O sea, la spec fija **qué datos** lleva el aviso y **en qué orden** —con qué, día, hora de inicio, hora de fin, las horas en 12 h—, pero no la mayúscula inicial, ni el punto final, ni el formato de lista cuando hay más de un cruce: esos tres son decisiones de esta tarea. Los mensajes de validación son todos nuevos y siguen el tono de `advising_validators.dart`.

- [ ] **Paso final: Commit**

```
cd "${REPO:?}"
test "$(git branch --show-current)" = feat/bloques-horario-fe || echo 'PARAR: rama equivocada'
git status --short
git add lib/pages/time_blocks/time_block_validators.dart \
        lib/pages/time_blocks/time_block_conflicts.dart \
        test/HU35_jeff/time_blocks_conflicto_test.dart
git commit -m "feat(time-blocks): validadores del formulario y detección de cruces (RF-BLQ-2, RF-BLQ-3)

Funciones puras, sin Flutter ni HTTP: los validadores devuelven String? en
español como los de asesoría, y la detección de cruces compara el bloque
contra las clases del horario y contra los demás bloques del alumno. Tocarse
en el borde no es cruce, al editar un bloque no se cruza consigo mismo y un
bloque propio de otro rango de fechas no cruza.

horaAMinutos lee las dos formas de hora del horario y devuelve null ante un
texto ilegible: una hora que no se lee no genera un aviso. La grilla no
cambia: HorarioPage._timeToHours sigue como estaba."
git log -1 --format=%B | grep -qi '^co-authored-by:' && echo 'PARAR: el commit trae trailer'
```

Antes del `git add`, `git status --short` solo puede listar esos tres archivos (dos en `lib/pages/time_blocks/`, nueva); si lista otro, o sale un `PARAR`, se detiene aquí. Sin trailer `Co-Authored-By`: el autor ya está configurado en git.
### Tarea 3: Reparto en columnas (función pura)

**Requisitos:** RF-BLQ-4, la parte del reparto («Reparto lado a lado»: el cálculo es una función pura, dado un conjunto de bloques con inicio y fin devuelve para cada uno su columna y cuántas columnas hay, con pruebas de dos y tres simultáneos, de uno contenido en otro y de dos que solo se tocan en el borde).

**Archivos:**
- Crear: `lib/pages/horario/horario_layout.dart`
- Test: `test/HU35_jeff/time_blocks_grilla_test.dart` (se crea aquí; la Tarea 4 lo amplía con las pruebas de widget del pintado, el domingo y los márgenes)

No se modifica ningún archivo existente. `test/HU35_jeff/` **no existe en el árbol de hoy**: la crea la Tarea 1 al escribir su propia prueba. Si se ejecuta esta tarea sin la Tarea 1 hecha, `mkdir -p test/HU35_jeff` antes de escribir el archivo.

**Interfaces:**

- Consume: **nada**. Ni de las tareas anteriores ni del repo. La función opera sobre minutos desde medianoche (`int`), no sobre texto, así que no usa `horaAMinutos` de la Tarea 2 ni los modelos de la Tarea 1; el archivo no importa `package:flutter/*`, ni `get`, ni nada del repo. Quien convierte `"14:00"` a minutos es quien la llama (la Tarea 4).

  Precedente de estilo, no dependencia: las dos funciones puras del horario, `HorarioPage.blockMetaLines` y `HorarioPage.blockGeometry` (`lib/pages/horario/horario.dart:56-82`), y el archivo de nivel superior `lib/pages/academic_record/record_course_row.dart:5-8`, cuyo comentario las cita como modelo. La spec pide lo mismo textualmente en RF-BLQ-4: «al estilo de `blockGeometry` y `blockMetaLines`».

  Nombres libres comprobados en el árbol de hoy: ni `SlotColumna`, ni `repartirEnColumnas`, ni `horario_layout` aparecen en `lib/` ni en `test/`, así que no hay homónimo con el que chocar.

- Produce — `lib/pages/horario/horario_layout.dart`:
  ```dart
  class SlotColumna {
    const SlotColumna(this.columna, this.columnas);
    final int columna;    // 0-based
    final int columnas;
  }

  List<SlotColumna> repartirEnColumnas(List<({int inicio, int fin})> bloques);
  ```
  `repartirEnColumnas` la consume la Tarea 4, que convierte `(columna, columnas)` en el `left`/`right` de `_courseBlock`. `SlotColumna` es el tipo que recorre esa conversión. Los dos campos son `int`; `columna` va de `0` a `columnas - 1`.

  El constructor es **posicional** (`SlotColumna(0, 2)`), no con nombre: son dos enteros que siempre van juntos y en ese orden, y así la prueba lee `(0, 2)` sin ruido. `toString()` se sobreescribe solo para que un fallo de prueba diga `SlotColumna(1 de 2)` y no `Instance of 'SlotColumna'`.

  La clase **no** define `==`: la prueba compara `(s.columna, s.columnas)` como registros de Dart, que sí tienen igualdad estructural. Si la Tarea 4 necesitara comparar `SlotColumna` directamente, que agregue `==` ahí; hoy nadie lo pide y no se escribe código que nadie usa.

- [ ] **Paso 1: Escribir la prueba que falla**

Crear `test/HU35_jeff/time_blocks_grilla_test.dart` con exactamente esto:

```dart
// test/HU35_jeff/time_blocks_grilla_test.dart
//
// UNITARIA — HU35 (bloques de horario propios): el reparto en columnas de los
// bloques que coinciden en el mismo tramo de un día (RF-BLQ-4, la parte del
// reparto).
// Función bajo prueba: lib/pages/horario/horario_layout.dart
//
// Todos los datos son inventados; el repo es público. Acá solo hay horas de
// pared: ni un código de alumno, ni un curso, ni una sección reales.
//
// Este archivo lo amplía la Tarea 4 con las pruebas de widget del pintado en
// las dos vistas, el domingo y los márgenes. Este grupo se queda como está: es
// la unidad que no necesita montar nada.

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/pages/horario/horario_layout.dart';

/// "14:30" → minutos desde medianoche.
///
/// Local a la prueba a propósito: la función bajo prueba recibe minutos y no
/// depende de ningún parseo, así que un fallo acá es un fallo del reparto y
/// nunca de la conversión de hora de la Tarea 2.
int minutos(String hhmm) {
  final partes = hhmm.split(':');
  return int.parse(partes[0]) * 60 + int.parse(partes[1]);
}

({int inicio, int fin}) tramo(String inicio, String fin) =>
    (inicio: minutos(inicio), fin: minutos(fin));

/// El reparto como pares `(columna, columnas)`. Los registros de Dart se
/// comparan por valor, así que la lista entera se puede afirmar de un tirón.
List<(int columna, int columnas)> reparto(List<({int inicio, int fin})> bloques) =>
    repartirEnColumnas(bloques).map((SlotColumna s) => (s.columna, s.columnas)).toList();

void main() {
  group('reparto en columnas de un día', () {
    test('sin bloques no hay nada que repartir', () {
      expect(reparto(const <({int inicio, int fin})>[]), isEmpty);
    });

    test('un bloque solo se queda con todo el ancho: columna 0 de 1', () {
      expect(reparto([tramo('14:00', '18:00')]), [(0, 1)]);
    });

    test('dos simultáneos se parten el ancho: 0 y 1 de 2', () {
      // Una clase de 4 a 6 y una práctica de 2 a 6. Sin reparto, la práctica
      // taparía la clase entera y se comería sus toques (`_courseBlock` con
      // `left`/`right` fijos por vista); con el reparto las dos quedan
      // visibles.
      expect(
        reparto([tramo('16:00', '18:00'), tramo('14:00', '18:00')]),
        [(1, 2), (0, 2)],
      );
    });

    test('tres simultáneos: tres columnas, una para cada uno', () {
      expect(
        reparto([tramo('14:00', '18:00'), tramo('15:00', '17:00'), tramo('16:00', '19:00')]),
        [(0, 3), (1, 3), (2, 3)],
      );
    });

    test('uno contenido en otro también se reparte', () {
      // El corto está dentro del largo: sin reparto desaparecería debajo.
      expect(reparto([tramo('14:00', '20:00'), tramo('16:00', '17:00')]), [(0, 2), (1, 2)]);
    });

    test('tocarse en el borde no es solaparse: los dos a ancho completo', () {
      // Mismo criterio que `seCruzan` de la Tarea 2: una termina 18:00 y la
      // otra empieza 18:00, así que no chocan y ninguna cede la mitad.
      expect(reparto([tramo('16:00', '18:00'), tramo('18:00', '20:00')]), [(0, 1), (0, 1)]);
    });

    test('dos racimos separados del mismo día se cuentan por separado', () {
      // 8-10 y 9-11 chocan entre ellos; 14-16 está solo y no tiene por qué
      // encogerse por lo que pasó en la mañana.
      expect(
        reparto([tramo('08:00', '10:00'), tramo('09:00', '11:00'), tramo('14:00', '16:00')]),
        [(0, 2), (1, 2), (0, 1)],
      );
    });

    test('en un racimo encadenado todos miden lo mismo', () {
      // A 8-10 y C 10-12 no se tocan, pero B 9-11 los encadena: es un solo
      // racimo de dos columnas, así que C reusa la columna 0 y los tres salen
      // del mismo ancho. Si `columnas` se calculara bloque a bloque, C saldría
      // "0 de 1" y el ancho cambiaría a mitad de la mañana.
      expect(
        reparto([tramo('08:00', '10:00'), tramo('09:00', '11:00'), tramo('10:00', '12:00')]),
        [(0, 2), (1, 2), (0, 2)],
      );
    });

    test('la salida respeta el orden de entrada aunque venga desordenada', () {
      // La vista entrega los bloques en el orden en que los va a pintar, que es
      // el del JSON y no el de la hora: resultado[i] tiene que ser el slot de
      // bloques[i].
      expect(
        reparto([tramo('18:00', '20:00'), tramo('07:00', '09:00'), tramo('07:30', '08:30')]),
        [(0, 1), (0, 2), (1, 2)],
      );
    });

    test('dos bloques idénticos no se tapan: uno a cada lado', () {
      expect(reparto([tramo('14:00', '16:00'), tramo('14:00', '16:00')]), [(0, 2), (1, 2)]);
    });

    test('la columna siempre cae dentro de la cuenta de columnas', () {
      // Invariante que la vista da por hecho al calcular el ancho: si
      // `columna >= columnas`, el bloque se dibujaría fuera de su día.
      final slots = repartirEnColumnas([
        tramo('07:00', '22:00'),
        tramo('08:00', '09:00'),
        tramo('08:30', '10:00'),
        tramo('12:00', '13:00'),
      ]);
      expect(slots, hasLength(4));
      for (final s in slots) {
        expect(s.columna, greaterThanOrEqualTo(0));
        expect(s.columna, lessThan(s.columnas));
      }
    });
  });
}
```

Qué fija cada caso, para que nadie los recorte después: los siete primeros son los que la spec nombra en RF-BLQ-4 y el esqueleto repite (vacío, uno solo, dos, tres, contenido, borde, dos racimos); el del racimo encadenado es el que distingue «primera columna libre + máximo del racimo» de «cuenta por bloque», que es la decisión de diseño de esta tarea; el del orden de entrada es lo que la Tarea 4 necesita para casar `resultado[i]` con su bloque; y el invariante protege el cálculo de ancho de la vista.

- [ ] **Paso 2: Correr la prueba y ver que falla**

```
cd "${REPO:?}"
"${FLUTTER:?}" test test/HU35_jeff/time_blocks_grilla_test.dart
```

Esperado: **no compila**, y ese es el fallo correcto —el archivo de la función todavía no existe—, no una aserción que no cuadra. La salida trae esto:

```
test/HU35_jeff/time_blocks_grilla_test.dart:16:8: Error: Error when reading 'lib/pages/horario/horario_layout.dart': No such file or directory
import 'package:ulima_plus/pages/horario/horario_layout.dart';
       ^
test/HU35_jeff/time_blocks_grilla_test.dart:34:5: Error: Method not found: 'repartirEnColumnas'.
    repartirEnColumnas(bloques).map((SlotColumna s) => (s.columna, s.columnas)).toList();
    ^^^^^^^^^^^^^^^^^^
test/HU35_jeff/time_blocks_grilla_test.dart:34:38: Error: 'SlotColumna' isn't a type.
    repartirEnColumnas(bloques).map((SlotColumna s) => (s.columna, s.columnas)).toList();
                                     ^^^^^^^^^^^
test/HU35_jeff/time_blocks_grilla_test.dart:112:21: Error: Method not found: 'repartirEnColumnas'.
      final slots = repartirEnColumnas([
                    ^^^^^^^^^^^^^^^^^^
00:00 +0 -1: loading $REPO/test/HU35_jeff/time_blocks_grilla_test.dart [E]
  Failed to load "$REPO/test/HU35_jeff/time_blocks_grilla_test.dart":
  Compilation failed for testPath=$REPO/test/HU35_jeff/time_blocks_grilla_test.dart: ...
00:00 +0 -1: Some tests failed.
```

(La línea 16 es el `import`, la 34 el ayudante `reparto` y la 112 la llamada dentro de la prueba del invariante; el bloque de errores se repite entero dentro del `Failed to load`. El texto exacto lo pone el compilador y puede variar de versión. Lo que tiene que verse es eso: falla al **compilar** porque falta el archivo, y ninguno de los errores apunta a un `expect`.)

Si en vez de eso sale `Failed to load ".../time_blocks_grilla_test.dart": Does not exist.`, el archivo del Paso 1 no se guardó donde toca. Si sale cualquier error dentro de `lib/`, viene de otra tarea: esta no toca ningún archivo existente.

- [ ] **Paso 3: Implementación mínima**

Crear `lib/pages/horario/horario_layout.dart` con exactamente esto (archivo nuevo, no hay nada que reemplazar):

```dart
// lib/pages/horario/horario_layout.dart
// El reparto en columnas de los bloques que coinciden en el mismo tramo de un
// día (RF-BLQ-4). Antes de RF-BLQ-4, `HorarioPage._courseBlock` recibía
// `left`/`right` fijos por vista (66/14 en la vista de día y 2/2 en la
// semanal), así que dos bloques simultáneos se dibujaban uno encima del otro a
// ancho completo y el de arriba se comía los toques del de abajo. Los bloques
// propios del alumno van a chocar con las clases a propósito, así que hay que
// repartir.
//
// Función pura de nivel superior para poder probarla sin montar widgets, igual
// que HorarioPage.blockGeometry y HorarioPage.blockMetaLines, que la spec cita
// como modelo. Este archivo no importa Flutter ni GetX a propósito: entran
// enteros, salen enteros.

/// En qué columna va un bloque y entre cuántas se reparte el ancho de su día.
///
/// [columna] es 0-based y siempre menor que [columnas].
///
/// [columnas] es la cuenta del racimo entero, no la del tramo exacto del
/// bloque: dos bloques encadenados por un tercero miden lo mismo aunque en su
/// hora concreta sobre sitio. Si no, un bloque cambiaría de ancho a media
/// mañana y la grilla parecería rota.
class SlotColumna {
  const SlotColumna(this.columna, this.columnas);

  final int columna;
  final int columnas;

  @override
  String toString() => 'SlotColumna($columna de $columnas)';
}

/// Reparte en columnas los bloques que se solapan dentro de un mismo día.
///
/// Los tramos van en **minutos desde medianoche**: convertir el texto de la
/// hora es cosa de quien llama. Entrada en el mismo orden en que se van a
/// pintar y salida en el mismo orden, de modo que `resultado[i]` es el slot de
/// `bloques[i]`.
///
/// Tocarse en el borde **no** es solaparse —una termina 18:00 y la otra empieza
/// 18:00—, el mismo criterio que `seCruzan` en
/// `lib/pages/time_blocks/time_block_conflicts.dart`.
///
/// El algoritmo: ordenar por hora de inicio, cortar en racimos de bloques que
/// se solapan en cadena y, dentro del racimo, dar a cada bloque la primera
/// columna que ya quedó libre. `columnas` es el máximo alcanzado por el racimo
/// y se le asigna a todos sus miembros.
///
/// Devuelve columnas, **no** píxeles: pasar de columna a `left`/`right`
/// depende del ancho disponible y de los márgenes de cada vista, así que vive
/// en la vista y se prueba ahí.
List<SlotColumna> repartirEnColumnas(List<({int inicio, int fin})> bloques) {
  if (bloques.isEmpty) return const <SlotColumna>[];

  final columnaDe = List<int>.filled(bloques.length, 0);
  final columnasDe = List<int>.filled(bloques.length, 1);

  // Índices ordenados por hora de inicio; a igual inicio, primero el más largo,
  // y a igual tramo se conserva el orden de entrada. El desempate no cambia el
  // ancho de nadie, solo de qué lado cae cada bloque, y así es estable.
  final orden = List<int>.generate(bloques.length, (i) => i)
    ..sort((a, b) {
      final porInicio = bloques[a].inicio.compareTo(bloques[b].inicio);
      if (porInicio != 0) return porInicio;
      final porFin = bloques[b].fin.compareTo(bloques[a].fin);
      if (porFin != 0) return porFin;
      return a.compareTo(b);
    });

  var racimo = <int>[];         // índices del racimo en curso
  var finesDeColumna = <int>[]; // hasta qué minuto está ocupada cada columna
  var finDelRacimo = 0;         // el fin más tardío visto en el racimo

  void cerrarRacimo() {
    final cuantas = finesDeColumna.length;
    for (final i in racimo) {
      columnasDe[i] = cuantas;
    }
    racimo = <int>[];
    finesDeColumna = <int>[];
  }

  for (final i in orden) {
    final bloque = bloques[i];

    // Empieza cuando el racimo entero ya terminó: nada de lo anterior lo
    // alcanza, así que abre racimo propio y vuelve a ancho completo.
    if (racimo.isNotEmpty && bloque.inicio >= finDelRacimo) cerrarRacimo();

    // La primera columna cuyo último bloque ya terminó. Tocarse en el borde
    // libera la columna, de ahí el `<=` y no `<`.
    var columna = finesDeColumna.indexWhere((fin) => fin <= bloque.inicio);
    if (columna == -1) {
      columna = finesDeColumna.length;
      finesDeColumna.add(bloque.fin);
    } else {
      finesDeColumna[columna] = bloque.fin;
    }

    columnaDe[i] = columna;
    racimo.add(i);
    finDelRacimo =
        racimo.length == 1 || bloque.fin > finDelRacimo ? bloque.fin : finDelRacimo;
  }
  cerrarRacimo();

  return List<SlotColumna>.generate(
    bloques.length,
    (i) => SlotColumna(columnaDe[i], columnasDe[i]),
  );
}
```

Tres cosas que parecen detalle y no lo son:

1. **`columnasDe` se rellena al cerrar el racimo, no al asignar la columna.** Cuando se asigna la columna todavía no se sabe cuántas va a tener el racimo: el bloque que la sube puede llegar después. Por eso hay dos pasadas lógicas sobre el mismo recorrido.
2. **El corte de racimo compara contra `finDelRacimo`, no contra el fin del bloque anterior.** Con A 8-12, B 9-10 y C 11-13, el anterior de C es B (que termina 10) pero A sigue ocupando la pista: si se comparara con B, C abriría racimo nuevo y se dibujaría encima de A. Con esta versión los tres salen del mismo racimo de dos columnas —A en la 0, B en la 1 y C reusando la 1, que B ya dejó libre—, que es lo que la grilla necesita.
3. **Un tramo degenerado no rompe nada, pero no queda solo.** Un bloque con `inicio == fin` sale `0 de 1` si está solo en el día; si cae dentro del tramo de otro, **sí** entra al racimo y toma su propia columna (`14:00-16:00` más `15:00-15:00` da `0 de 2` y `1 de 2`). Es lo coherente con `seCruzan`, que también los da por cruzados (`inicio < finB && inicioB < fin` se cumple en los dos sentidos). Ni el formulario ni el servidor dejan crear uno así —la Tarea 2 exige `fin > inicio`—, pero si llegara, la función responde sin caerse y sin dejar a nadie tapado.

- [ ] **Paso 4: Correr la prueba y ver que pasa**

```
cd "${REPO:?}"
"${FLUTTER:?}" test test/HU35_jeff/time_blocks_grilla_test.dart
```

Esperado: **PASS**, las 11 pruebas del grupo «reparto en columnas de un día» en verde (`00:00 +11: All tests passed!`).

- [ ] **Paso 5: Análisis**

```
cd "${REPO:?}"
"${FLUTTER:?}" analyze
```

Esperado: `7 issues found.`, el mismo número y la misma lista de la línea base que la Tarea 1 midió, con la única diferencia que ya traía la Tarea 1 (el `avoid_print` de `lib/main.dart` en la línea 91 en vez de la 85, porque la Tarea 1 metió seis líneas antes). Cero issues nuevos y ninguno en `lib/pages/horario/horario_layout.dart` ni en `test/HU35_jeff/time_blocks_grilla_test.dart`: el archivo no tiene imports, así que no hay nada que pueda quedar sin usar, y `SlotColumna` se usa desde la prueba. Si aparece uno en esos dos archivos, se arregla antes del commit.

No hace falta correr las suites del horario como regresión en esta tarea: no se tocó `horario.dart` ni ningún otro archivo existente, y todavía nadie llama a `repartirEnColumnas`. La regresión del horario le toca a la Tarea 4, que es la que modifica la vista.

- [ ] **Paso 6: Anotar en el reporte que esta tarea no agrega texto visible**

La Tarea 8 reúne todos los textos nuevos que ve el alumno. Esta tarea no aporta ninguno; dejarlo escrito para que no haya que volver a revisarla. Línea exacta para el reporte de la rama (no va a ningún archivo del repo):

```
Tarea 3 (reparto en columnas): ningún texto visible nuevo. La función devuelve
columnas, no píxeles ni etiquetas; el alumno no lee nada que salga de acá.
```

- [ ] **Paso final: Commit**

```
cd "${REPO:?}"
test "$(git branch --show-current)" = feat/bloques-horario-fe || echo 'PARAR: rama equivocada'
git status --short
git add lib/pages/horario/horario_layout.dart \
        test/HU35_jeff/time_blocks_grilla_test.dart
git commit -m "feat(time-blocks): reparto en columnas de los bloques simultáneos (RF-BLQ-4)

Función pura de nivel superior, sin Flutter ni GetX: recibe los tramos de un
día en minutos y devuelve para cada uno su columna y cuántas columnas tiene
su racimo. Tocarse en el borde no es solaparse, el mismo criterio que seCruzan.

El ancho lo fija el racimo entero y no el tramo de cada bloque, para que dos
bloques encadenados no cambien de ancho a media mañana. Devuelve columnas, no
píxeles: pasar de columna a left/right es cosa de la vista y se prueba ahí.

Todavía no la llama nadie; la usa la Tarea 4 al pintar la grilla."
git log -1 --format=%B | grep -qi '^co-authored-by:' && echo 'PARAR: el commit trae trailer'
```

Antes del `git add`, `git status --short` solo puede listar esos dos archivos; si lista otro, o sale un `PARAR`, se detiene aquí. Sin trailer `Co-Authored-By`: el autor ya está configurado en git.
### Tarea 4: Pintar los bloques en la grilla

**Requisitos:** RF-BLQ-4 completo: los bloques propios se pintan en las dos vistas del horario con el color que eligió la alumna y con su nombre, sin salón ni sección; lo que coincide en el mismo tramo de un día se reparte el ancho y todo queda visible y tocable; la vista semanal incluye el domingo. De RF-BLQ-4 y RF-BLQ-5, la parte de la grilla: un día cancelado se pinta en su hora de siempre, a 40 % de opacidad y con «Este día está cancelado» (D2), para que la Tarea 6 pueda abrir su hoja y devolverlo al patrón. De RF-BLQ-7, la parte que toca la pantalla: los bloques viven en una lista propia del controller, nunca en `_todasLasSecciones`, y el horario pide la ventana del ciclo visible, del primer al último `isoDate` de los días (o, si ningún día trae `isoDate`, las cuatro semanas alrededor de hoy). Cada día sabe su fecha por su `isoDate` (D1): nada se lee de `dateText` ni de `currentCycle`.

**Archivos:**
- Modificar: `lib/pages/horario/horario_controller.dart:7-8` (imports), `:10-16` (`DaySchedule` gana `isoDate` y `fromJson`), `:61-67` (`onInit`), `:80` (`reload`), `:84-88` (`onClose`), `:108-117` (`_loadDays` arma los días con `DaySchedule.fromJson`) y `:339-342` (miembros nuevos entre `coursesForDay` y `previousDay`). Las Tareas 1 a 3 no tocan este archivo: los números son los de hoy y siguen valiendo al empezar esta tarea; cada reemplazo corre los de abajo, así que manda el texto.
- Modificar: `lib/pages/horario/horario.dart`, doce bloques. Ninguna tarea anterior toca este archivo, así que los números son los de hoy; cada reemplazo corre los de abajo, así que **se ancla por el texto**, que existe literal:

  | bloque | qué | hoy |
  |:--|:--|:--|
  | 3.b.1 | import de `horario_layout.dart` | `:9-10` |
  | 3.b.2 | imports del modelo y de `course_colors.dart` | `:15-16` |
  | 3.b.3 | `_weekDays`: la lista con domingo | `:186-194` |
  | 3.b.4 | `_weekDays`: el respaldo de 7 | `:207-209` |
  | 3.b.5 | ayudantes nuevos y firma de `_courseBlock` | `:271-278` |
  | 3.b.6 | `_courseBlock`: el nombre | `:289-294` |
  | 3.b.7 | `_courseBlock`: color, líneas y columna | `:309-326` |
  | 3.b.8 | `_courseBlock`: el `for` de las líneas | `:487-495` |
  | 3.b.9 | cierre de `_courseBlock` e inicio de `_portraitGrid` | `:535-548` |
  | 3.b.10 | `_portraitGrid`: los bloques | `:582-594` |
  | 3.b.11 | `_landscapeWeekGrid`: los propios por día | `:630-633` |
  | 3.b.12 | `_landscapeWeekGrid`: los bloques | `:726-740` |

- Test: `test/HU35_jeff/time_blocks_grilla_test.dart` (ampliar; lo crea la Tarea 3): `:1-16` (cabecera e imports), `:33-37` (ayudantes antes de `main`) y `:118-125` (el final del archivo). Son los números del archivo tal como lo deja la Tarea 3; si alguien lo tocó después, vale el texto.

**Interfaces:**

- Consume — Tarea 1, `lib/models/time_block_model.dart` y `lib/services/time_blocks_service.dart`:
  ```dart
  class TimeBlockOccurrence {
    final int blockId; final String title; final String colorHex;
    final String date;        // "YYYY-MM-DD"
    final int dayOfWeek;      // 1 = lunes … 7 = domingo
    final String startTime; final String endTime;   // "HH:MM"
    final bool moved;
  }
  class TimeBlocksSnapshot { final List<TimeBlockOccurrence> occurrences; final List<TimeBlockWeek> weeks; }
  class TimeBlocksService extends GetxService {
    TimeBlocksService({ApiClient? apiClient});
    static TimeBlocksService get to => Get.find();
    TimeBlocksSnapshot? get snapshot;   // lee el Rx ANTES de filtrar por dueño: un Obx que lo llama queda suscrito
    List<TimeBlockRule> get blocks;     // ídem; de aquí salen los días cancelados
    Future<void> load({required String from, required String to, bool force = false});   // nunca lanza; docente o sin sesión: no hace nada
  }
  class TimeBlockRule { final int id; final String title; final String colorHex; final List<int> daysOfWeek;
    final String startTime; final String endTime; final String startDate; final String endDate;
    final List<TimeBlockException> exceptions; }
  class TimeBlockException { final String date; final String status; /* 'cancelled' | 'moved' */ }
  ```
- Consume — Tarea 2: nada. El reparto convierte las horas con el `_timeToHours` que ya usa el dibujo (`horario.dart:92-126`, sin cambios), así que reparto y dibujo coinciden siempre.
- Consume — Tarea 3, `lib/pages/horario/horario_layout.dart`: `class SlotColumna { final int columna; final int columnas; }` y `List<SlotColumna> repartirEnColumnas(List<({int inicio, int fin})> bloques);` (la salida va en el mismo orden que la entrada; tocarse en el borde no reparte).
- Consume — del repo: `Color? parseHexColor(String? hex)` (`lib/configs/course_colors.dart:37-46`); `DaySchedule(this.dayName, this.dateText, this.weekText)` (`horario_controller.dart:10-16`), que esta tarea amplía; de `HorarioController`, `currentDayIndex`, `daysList`, `currentLimaTime` (`:19-23`), `Future<void> _loadDays()` (`:98`), `List<Map<String, dynamic>> coursesForDay(DaySchedule activeDay)` (`:246`) y `Map<String, Color> get colorPorCurso` (`:375`); `ever` y `Worker` de GetX, con el mismo patrón de `lib/pages/malla/malla_controller.dart:79-88` (se crea en `onInit` y se apaga en `onClose`); de `HorarioPage`, `startHour`, `blockHairline`, `blockMetaLines`, `blockGeometry` (`horario.dart:21-82`) y `_timeToHours` (`:92-126`), que no cambian.
- Consume — del backend, con el campo nuevo de D1: `/schedule/me/sessions` arma `days` con las semanas reales del ciclo, siete días seguidos de lunes a domingo por semana (`src/modules/schedule/schedule.service.ts:211-233`). Cada día trae ahora `isoDate`, su fecha en hora de Lima (`"2026-09-21"`), calculada de la misma fecha que `dateText` («21 de Septiembre», sin año). Solo si el ciclo no tiene semanas manda los siete días con `isoDate` null, `dateText` vacío y «Semana actual». El campo es aditivo: un backend anterior no lo manda y la app lo lee como null. Las pruebas de esta tarea usan dobles y no dependen del backend desplegado.
- Produce — lo del esqueleto, más los días cancelados:
  ```dart
  // lib/pages/horario/horario_controller.dart (DaySchedule, D1)
  final String? isoDate;                                                  // nuevo
  DaySchedule(this.dayName, this.dateText, this.weekText, {this.isoDate});  // isoDate, nombrado opcional
  factory DaySchedule.fromJson(Map<String, dynamic> json);                // nuevo

  // lib/pages/horario/horario_controller.dart (HorarioController)
  List<TimeBlockOccurrence> bloquesDelDia(DaySchedule dia);
  List<TimeBlockOccurrence> bloquesCanceladosDelDia(DaySchedule dia);   // nuevo: RF-BLQ-5
  ({String from, String to}) ventanaVisible();

  // lib/pages/horario/horario.dart (HorarioPage, privado)
  Widget _courseBlock({
    required BuildContext context,
    required HorarioController controller,
    required Map<String, dynamic> course,
    required double hourHeight,
    required double left,
    required double right,
    int columna = 0,     // nuevo
    int columnas = 1,    // nuevo
    required bool compact,
    required bool vistaDia,
    double lineOffset = 0.0,
  });
  ```
  La **rama de dibujo del bloque propio** vive dentro de `_courseBlock`. Un bloque propio entra por el mismo mapa que una clase, con la ocurrencia tipada en `course['bloquePropio']`, y el método la guarda en la variable local `final bloquePropio = course['bloquePropio'] as TimeBlockOccurrence?;` (con `esBloquePropio`). Con ella el nombre va entero (sin el corte en `/` del nombre bilingüe del portal), el color sale de `parseHexColor(bloquePropio.colorHex)` sin pasar por `colorPorCurso`, y no hay línea de salón ni de sección. Un día cancelado entra igual, con la ocurrencia armada desde la regla y `course['diaCancelado'] == true`, que el método guarda en la local `final diaCancelado = course['diaCancelado'] == true;`: se pinta a 40 % de opacidad y lleva «Este día está cancelado» (`_diaCanceladoTexto`) debajo del nombre, donde una clase lleva su salón o su sección. **El toque no cambia en esta tarea**: el mapa no lleva `idSeccion`, así que hoy tocar un bloque propio no hace nada, igual que cualquier bloque sin sección (`horario.dart:441`). La Tarea 6 pone su rama en el `onTap` y usa esas mismas variables `bloquePropio` y `diaCancelado`.

  Para la Tarea 7, que también toca el controller, quedan ahí cuatro ayudantes privados que puede reutilizar: `_fechaDelDia(DaySchedule dia)` (la fecha del día, `DateTime` UTC a medianoche: su `isoDate` o, si es null, ese día de la semana en la semana de hoy; null si tampoco se reconoce el nombre), `static DateTime _lunesDe(DateTime fecha)`, `_lunesDeEstaSemana()` (el lunes de la semana de hoy en Lima) y `static String _fechaPlana(DateTime d)` (`"YYYY-MM-DD"`). No son parte del contrato.

**Cuatro decisiones de esta tarea, para que nadie las deshaga sin querer:**

1. **Las fechas salen de `isoDate`, y la ventana es la del ciclo visible (RF-BLQ-7, D1).** `/schedule/me/sessions` manda en cada día su fecha exacta (`isoDate`), y la app no lee ninguna fecha de `dateText` («21 de Septiembre», sin año) ni del ciclo del alumno (`currentCycle`): adivinar el año era frágil. La ventana va del primer al último `isoDate` no nulo de `daysList`, en el orden en que llegan. Un ciclo de 16 semanas son 112 días; si la ventana pasara de los 120 que acepta el servidor (`TIME_BLOCK_WINDOW_TOO_WIDE`), se piden solo 120 días desde el lunes de la semana del día activo, y un `ever` sobre `currentDayIndex` pide la ventana de la semana nueva al cambiar de semana (dentro de la misma, la ventana es la misma y `load` no pide nada). Va anotado en el reporte. Las cuatro semanas alrededor de hoy (la pasada, la actual y las dos siguientes) quedan para cuando ningún día trae `isoDate`: `daysList` vacío o el ciclo sin semanas. Un bloque cae en un día si su fecha es el `isoDate` de ese día; solo si es null se toma ese día de la semana en la semana de hoy (`_fechaDelDia`). Como la ventana sale de las fechas, el horario pide los bloques **después** de cargar los días (`_cargarDiasYBloques`).
2. **El reparto se hace con `FractionallySizedBox` y no con `left`/`right` calculados.** `_courseBlock` no conoce el ancho del día, porque en la vista semanal cada día es un `Expanded`. Por eso la pista sigue yendo de `left` a `right` y el bloque ocupa `1/columnas` de ella, alineado en su columna. Con una sola columna el factor es 1 y el rectángulo es el mismo que hoy, al píxel; la prueba de regresión lo fija. El hijo mide solo su parte, así que un toque en la otra columna le llega al bloque de al lado.
3. **Los bloques propios se leen fuera de los `LayoutBuilder`.** El builder de un `LayoutBuilder` corre durante el layout, fuera del `Obx` de `build`, y una lectura de un `Rx` ahí no suscribe a nada. Si los propios se leyeran ahí, la grilla no se enteraría de que llegaron (el service suele responder después que el horario) ni de lo que la alumna crea o borra. Dos pruebas lo fijan, una por vista: si la lectura de `_portraitGrid` se mete en su `LayoutBuilder`, falla «si los bloques llegan después de pintar el horario, aparecen solos»; si se mete la de `_landscapeWeekGrid`, falla «vista semanal: si los bloques llegan después, también aparecen solos». Los días cancelados se leen en el mismo sitio y por lo mismo.
4. **Un día cancelado se pinta tenue desde la regla, no desde las ocurrencias.** El servidor no manda un día cancelado entre las ocurrencias (RS-BE-33), pero la regla trae la excepción (`TimeBlockRule.exceptions`, Tarea 1), así que no hace falta expandir nada: `bloquesCanceladosDelDia` toma las excepciones `cancelled` cuya fecha es la del día, con las horas de su regla, y solo si la fecha sigue en el patrón (uno de sus días y dentro de su rango; una excepción que quedó fuera al editar la regla ya no se expande). Entran al reparto como cualquier bloque, en su hora de siempre, a 40 % de opacidad y con «Este día está cancelado» debajo del nombre (D2), en el lugar del salón o la sección y con la misma regla de alto que `blockMetaLines`: si el bloque queda chico, no entra y se omite, igual que el salón o la sección de una clase. Es lo que necesita RF-BLQ-5 («si el día está cancelado o movido, la hoja ofrece volver al patrón»): sin pintarlo, no hay nada que tocar. La Tarea 6 abre su hoja.

Además apareció un problema que obliga a una quinta pieza. `_weekDays` arma la vista semanal con la **primera aparición** de cada nombre en `daysList`, que es la primera semana del ciclo. A las clases les da igual porque se repiten, pero los bloques propios cambian de una semana a otra (un día cancelado, uno movido, uno fuera de sus fechas). Por eso la vista semanal busca los bloques propios en la **semana del día activo** (`_mismoDiaEnLaSemanaActiva`), sin tocar lo que ya pinta para las clases y las evaluaciones.

- [ ] **Paso 1: Escribir la prueba que falla**

Ampliar `test/HU35_jeff/time_blocks_grilla_test.dart` con tres reemplazos. El grupo de la Tarea 3 («reparto en columnas de un día») no se toca.

**1.a — Cabecera e imports.** Reemplazar esto (`:1-16`, la cabecera y los dos imports que dejó la Tarea 3; si la cabecera quedó con otro texto, reemplazar el comentario completo hasta el último `import`):

```dart
// test/HU35_jeff/time_blocks_grilla_test.dart
//
// UNITARIA — HU35 (bloques de horario propios): el reparto en columnas de los
// bloques que coinciden en el mismo tramo de un día (RF-BLQ-4, la parte del
// reparto).
// Función bajo prueba: lib/pages/horario/horario_layout.dart
//
// Todos los datos son inventados; el repo es público. Acá solo hay horas de
// pared: ni un código de alumno, ni un curso, ni una sección reales.
//
// Este archivo lo amplía la Tarea 4 con las pruebas de widget del pintado en
// las dos vistas, el domingo y los márgenes. Este grupo se queda como está: es
// la unidad que no necesita montar nada.

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/pages/horario/horario_layout.dart';
```

por esto:

```dart
// test/HU35_jeff/time_blocks_grilla_test.dart
//
// UNITARIA + WIDGET — HU35 (bloques de horario propios): la grilla del
// horario con los bloques propios (RF-BLQ-4).
// - El reparto en columnas de lo que coincide en el mismo tramo de un día.
//   Función: lib/pages/horario/horario_layout.dart
// - Qué bloques propios y qué días cancelados caen en cada día, y qué
//   ventana pide el horario (la del ciclo visible).
//   Controller: lib/pages/horario/horario_controller.dart
// - El pintado en las dos vistas, el reparto aplicado, el domingo, los días
//   cancelados y los márgenes de siempre. Pantalla:
//   lib/pages/horario/horario.dart
//
// Todos los datos son inventados; el repo es público. La alumna 20230001 no
// existe, los cursos se llaman "CURSO DE PRUEBA", las secciones son 80x y
// nada sale de un horario real ni de test/HU31_jeff/fixtures.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/horario/horario.dart';
import 'package:ulima_plus/pages/horario/horario_controller.dart';
import 'package:ulima_plus/pages/horario/horario_layout.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/time_blocks_service.dart';
```

**1.b — Los dobles y ayudantes, antes de `main`.** Reemplazar esto (`:33-37`):

```dart
List<(int columna, int columnas)> reparto(List<({int inicio, int fin})> bloques) =>
    repartirEnColumnas(bloques).map((SlotColumna s) => (s.columna, s.columnas)).toList();

void main() {
  group('reparto en columnas de un día', () {
```

por esto (el ayudante `reparto` y la apertura del grupo de la Tarea 3 quedan igual; lo nuevo va entre `reparto` y `main`, y `main` gana su primera línea):

```dart
List<(int columna, int columnas)> reparto(List<({int inicio, int fin})> bloques) =>
    repartirEnColumnas(bloques).map((SlotColumna s) => (s.columna, s.columnas)).toList();

// --- La grilla con los bloques propios (Tarea 4) ----------------------------
//
// La semana de prueba es la del lunes 21 al domingo 27 de septiembre de 2026,
// la de los ejemplos de la spec. "PRÁCTICAS DE PRUEBA" es un bloque inventado.

UserModel _alumna({String role = 'student'}) => UserModel(
      code: '20230001',
      firstName: 'Alumna',
      lastName: 'De Prueba',
      email: 'test@aloe.ulima.edu.pe',
      role: role,
      currentCycle: '2026-2',
      setupComplete: true,
    );

class _FakeAuthService extends AuthService {
  _FakeAuthService(UserModel? user) : userRx = Rx<UserModel?>(user);

  final Rx<UserModel?> userRx;

  @override
  UserModel? get currentUser => userRx.value;

  @override
  Rx<UserModel?> get currentUserRx => userRx;

  @override
  Future<void> refreshCurrentUser() async {}
}

/// Doble del cliente HTTP de [TimeBlocksService]: contesta las dos llamadas de
/// `load` con lo sembrado y anota cada ventana que se le pide. Como el
/// servidor, de las ocurrencias sembradas devuelve solo las que caen dentro
/// de la ventana pedida: así una prueba ve si la ventana alcanza.
class _FakeBloquesApi extends ApiClient {
  _FakeBloquesApi({
    this.reglas = const <Map<String, dynamic>>[],
    this.ocurrencias = const <Map<String, dynamic>>[],
  }) : super(configuredBaseUrl: 'http://test');

  final List<Map<String, dynamic>> reglas;
  final List<Map<String, dynamic>> ocurrencias;
  final List<Map<String, String?>> ventanasPedidas = <Map<String, String?>>[];

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    String? token,
    Map<String, String?> query = const {},
    bool suppressSessionExpiry = false,
  }) async {
    if (path == '/time-blocks/me/occurrences') {
      ventanasPedidas.add(query);
      final desde = query['from'] ?? '';
      final hasta = query['to'] ?? '';
      return <String, dynamic>{
        'occurrences': <Map<String, dynamic>>[
          for (final o in ocurrencias)
            if ((o['date'] as String).compareTo(desde) >= 0 &&
                (o['date'] as String).compareTo(hasta) <= 0)
              o,
        ],
        'weeks': <dynamic>[], // Vacío porque estas pruebas no miran horas.
      };
    }
    return <String, dynamic>{'blocks': reglas};
  }
}

const List<String> _nombresDeDia = <String>[
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

const List<String> _nombresDeMes = <String>[
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
];

/// Un ciclo de [semanas] semanas seguidas de lunes a domingo desde el lunes
/// [desde] (por omisión el 24 de agosto de 2026), con lo que arma el backend
/// para cada día: `dateText` ("24 de Agosto"), `weekText` ("Semana 1 del
/// ciclo") e `isoDate` ("2026-08-24").
List<DaySchedule> _ciclo({required int semanas, DateTime? desde}) {
  final lunes = desde ?? DateTime.utc(2026, 8, 24);
  return <DaySchedule>[
    for (var i = 0; i < semanas * 7; i++)
      _diaDelCiclo(lunes.add(Duration(days: i)), 1 + i ~/ 7),
  ];
}

DaySchedule _diaDelCiclo(DateTime fecha, int semana) => DaySchedule(
      _nombresDeDia[fecha.weekday - 1],
      '${fecha.day} de ${_nombresDeMes[fecha.month - 1]}',
      'Semana $semana del ciclo',
      isoDate: _iso(fecha),
    );

/// La fecha como la manda `isoDate`: "2026-09-21".
String _iso(DateTime fecha) =>
    '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-'
    '${fecha.day.toString().padLeft(2, '0')}';

/// La regla "Prácticas de prueba" con la forma de `GET /time-blocks/me`:
/// lunes y miércoles de 14:00 a 18:00, del 1 de septiembre al 15 de
/// diciembre de 2026, con las excepciones que se le pasen.
Map<String, dynamic> _reglaConExcepciones(
  List<Map<String, dynamic>> excepciones,
) =>
    <String, dynamic>{
      'id': 7,
      'title': 'Prácticas de prueba',
      'colorHex': '#27AE60',
      'daysOfWeek': <dynamic>[1, 3],
      'startTime': '14:00',
      'endTime': '18:00',
      'startDate': '2026-09-01',
      'endDate': '2026-12-15',
      'exceptions': excepciones,
    };

/// La semana de prueba con lo que arma el backend para cada día
/// ("21 de Septiembre", `isoDate` "2026-09-21"), de lunes a domingo.
List<DaySchedule> _semana({bool conDomingo = true}) => <DaySchedule>[
      for (final (nombre, dia) in const <(String, int)>[
        ('Lunes', 21),
        ('Martes', 22),
        ('Miércoles', 23),
        ('Jueves', 24),
        ('Viernes', 25),
        ('Sábado', 26),
        ('Domingo', 27),
      ])
        if (conDomingo || nombre != 'Domingo')
          DaySchedule(
            nombre,
            '$dia de Septiembre',
            'Semana 5 del ciclo',
            isoDate: '2026-09-$dia',
          ),
    ];

/// Una ocurrencia con la forma exacta del contrato
/// (`GET /time-blocks/me/occurrences`).
Map<String, dynamic> _ocurrencia({
  required String fecha,
  required int diaDeLaSemana,
  required String inicio,
  required String fin,
  String titulo = 'Prácticas de prueba',
  bool movida = false,
}) =>
    <String, dynamic>{
      'blockId': 7,
      'title': titulo,
      'colorHex': '#27AE60',
      'date': fecha,
      'dayOfWeek': diaDeLaSemana,
      'startTime': inicio,
      'endTime': fin,
      'moved': movida,
    };

/// Una clase como la devuelve `coursesForDay`: sección y horario aplanados,
/// con las horas en 12 h como las manda `/schedule/me/sessions`.
Map<String, dynamic> _clase(String curso, String inicio, String fin) =>
    <String, dynamic>{
      'idSeccion': '801',
      'codigoSeccion': '801',
      'curso': curso,
      'hora_inicio': inicio,
      'hora_fin': fin,
      'salon': 'AULA 801',
      'color': '#2F80ED',
      'isEvaluation': false,
      'isAdvising': false,
    };

/// El controller del horario sin su carga remota: días y clases sembrados, y
/// el reloj fijo en el 1 de septiembre, que no es ningún día de la semana de
/// prueba (así no se pinta la línea roja de "ahora").
///
/// `bloquesDelDia` y `ventanaVisible` NO se sobreescriben: son lo que se prueba.
class _HorarioDePrueba extends HorarioController {
  _HorarioDePrueba({
    required List<DaySchedule> dias,
    this.clasesPorDia = const <String, List<Map<String, dynamic>>>{},
  }) {
    daysList.assignAll(dias);
    currentLimaTime.value = DateTime.utc(2026, 9, 1, 10);
  }

  /// Las clases de cada día, por `dayName`.
  final Map<String, List<Map<String, dynamic>>> clasesPorDia;

  @override
  // ignore: must_call_super
  void onInit() {
    // Sin el onInit real: arranca un Timer.periodic de un minuto, que quedaría
    // pendiente al terminar la prueba, y pide el horario con un ApiClient
    // propio que no se puede inyectar. Mismo recurso que
    // test/HU07_sam/calculadora_flujo_cajanegra_test.dart.
  }

  @override
  List<Map<String, dynamic>> coursesForDay(DaySchedule activeDay) =>
      clasesPorDia[activeDay.dayName] ?? const <Map<String, dynamic>>[];
}

/// Vertical y horizontal. El vertical es más ancho que un teléfono a
/// propósito: la fuente de las pruebas dibuja cada letra como un cuadrado de
/// su tamaño, y "Domingo, 27 de Septiembre" a 18 px no entra en la franja del
/// día con menos de ~580 px (la fila desborda en la prueba, no en la app).
const Size _vertical = Size(600, 1000);
const Size _horizontal = Size(1000, 500);

/// Registra la sesión, el service de bloques y el controller, y monta
/// [HorarioPage]. `Get.put(HorarioController())` del `build` encuentra el
/// doble ya registrado y lo reusa: GetX no reemplaza una instancia viva.
Future<TimeBlocksService> _montar(
  WidgetTester tester, {
  required Size pantalla,
  List<Map<String, dynamic>> ocurrencias = const <Map<String, dynamic>>[],
  List<Map<String, dynamic>> reglas = const <Map<String, dynamic>>[],
  Map<String, List<Map<String, dynamic>>> clasesPorDia =
      const <String, List<Map<String, dynamic>>>{},
  List<DaySchedule>? dias,
  bool conDomingo = true,
  int diaActivo = 0,
  bool cargarAntes = true,
}) async {
  tester.view.physicalSize = pantalla;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  Get.put<AuthService>(_FakeAuthService(_alumna()));
  final servicio = TimeBlocksService(
    apiClient: _FakeBloquesApi(reglas: reglas, ocurrencias: ocurrencias),
  );
  Get.put<TimeBlocksService>(servicio);
  if (cargarAntes) await servicio.load(from: '2026-09-14', to: '2026-10-11');

  final horario = _HorarioDePrueba(
    dias: dias ?? _semana(conDomingo: conDomingo),
    clasesPorDia: clasesPorDia,
  );
  horario.currentDayIndex.value = diaActivo;
  Get.put<HorarioController>(horario);

  await tester.pumpWidget(const GetMaterialApp(home: HorarioPage()));
  await tester.pump();
  return servicio;
}

/// El bloque que lleva ese título: su [InkWell], que es lo que se toca.
Finder _bloque(String titulo) =>
    find.ancestor(of: find.text(titulo), matching: find.byType(InkWell));

/// Si un toque en el centro del bloque le llega a él y no a otro que lo tape.
/// El Stack entrega el toque al primer hijo que lo acepta, de arriba abajo, así
/// que un bloque tapado nunca aparece en el camino del toque.
bool _recibeElToque(WidgetTester tester, Finder bloque) {
  final objetivo = tester.renderObject(bloque);
  final camino = tester.hitTestOnBinding(tester.getCenter(bloque)).path;
  return camino.any((entrada) => entrada.target == objetivo);
}

/// La franja de un día en la vista semanal: la celda naranja de su nombre,
/// que mide lo mismo que la columna de la grilla debajo.
Rect _columnaDe(WidgetTester tester, String dia) => tester.getRect(
      find.ancestor(of: find.text(dia), matching: find.byType(Container)).first,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('reparto en columnas de un día', () {
```

**1.c — Los grupos nuevos, al final.** Reemplazar esto (`:118-125`, el cierre de la última prueba de la Tarea 3, de su grupo y de `main`):

```dart
      expect(slots, hasLength(4));
      for (final s in slots) {
        expect(s.columna, greaterThanOrEqualTo(0));
        expect(s.columna, lessThan(s.columnas));
      }
    });
  });
}
```

por esto:

```dart
      expect(slots, hasLength(4));
      for (final s in slots) {
        expect(s.columna, greaterThanOrEqualTo(0));
        expect(s.columna, lessThan(s.columnas));
      }
    });
  });

  group('UNITARIA · la ventana de bloques que pide el horario (RF-BLQ-7)', () {
    setUp(() {
      Get.testMode = true;
      Get.reset();
    });
    tearDown(Get.reset);

    /// La ventana que pediría el horario con [dias] cargados y el día
    /// [diaActivo] a la vista. El controller se crea sin registrar, así que
    /// su onInit no corre.
    ({String from, String to}) ventanaDelCiclo(
      List<DaySchedule> dias, {
      int diaActivo = 0,
      DateTime? hoy,
    }) {
      final horario = HorarioController();
      horario.daysList.assignAll(dias);
      horario.currentDayIndex.value = diaActivo;
      if (hoy != null) horario.currentLimaTime.value = hoy;
      return horario.ventanaVisible();
    }

    /// Cuántos días cubre una ventana contando los dos extremos, como el
    /// tope de 120 del servidor.
    int diasDe(({String from, String to}) ventana) =>
        DateTime.parse('${ventana.to}T00:00:00Z')
            .difference(DateTime.parse('${ventana.from}T00:00:00Z'))
            .inDays +
        1;

    test('es la del ciclo: del primer al último isoDate de los días', () {
      final ciclo = _ciclo(semanas: 16);
      const esperada = (from: '2026-08-24', to: '2026-12-13');
      expect(ventanaDelCiclo(ciclo), esperada);
      expect(diasDe(esperada), 112);
      // No depende del día activo: navegar dentro del ciclo no pide otra.
      expect(ventanaDelCiclo(ciclo, diaActivo: 7 * 15 + 6), esperada);
    });

    test('un ciclo de más de 120 días pide 120 desde el lunes de la semana del día activo',
        () {
      // 18 semanas son 126 días: no entran en una ventana
      // (TIME_BLOCK_WINDOW_TOO_WIDE).
      final ciclo = _ciclo(semanas: 18);
      final primera = ventanaDelCiclo(ciclo);
      expect(primera, (from: '2026-08-24', to: '2026-12-21'));
      expect(diasDe(primera), 120);
      // El jueves de esa semana pide lo mismo que su lunes.
      expect(ventanaDelCiclo(ciclo, diaActivo: 3), primera);
      // El miércoles 23 de diciembre (semana 18) pide desde su lunes, el 21,
      // aunque la ventana pase del final del ciclo: el servidor la acepta.
      final ultima = ventanaDelCiclo(ciclo, diaActivo: 7 * 17 + 2);
      expect(ultima, (from: '2026-12-21', to: '2027-04-19'));
      expect(diasDe(ultima), 120);
    });

    test('el año sale de isoDate: un ciclo que cruza de diciembre a enero no se adivina',
        () {
      // Seis semanas desde el lunes 14 de diciembre de 2026. dateText no trae
      // año ("24 de Enero"); isoDate sí ("2027-01-24").
      expect(
        ventanaDelCiclo(_ciclo(semanas: 6, desde: DateTime.utc(2026, 12, 14))),
        (from: '2026-12-14', to: '2027-01-24'),
      );
    });

    test('un ciclo sin semanas (isoDate null) pide las cuatro semanas alrededor de hoy',
        () {
      // Lo que manda el backend cuando el ciclo no tiene semanas: los siete
      // días con isoDate null, dateText vacío y "Semana actual".
      expect(
        ventanaDelCiclo(
          <DaySchedule>[
            for (final nombre in _nombresDeDia)
              DaySchedule(nombre, '', 'Semana actual'),
          ],
          hoy: DateTime.utc(2026, 9, 23, 10),
        ),
        (from: '2026-09-14', to: '2026-10-11'),
      );
    });

    test('en un ciclo largo, cambiar de semana pide la ventana de la semana nueva, y dentro de ella no',
        () async {
      // El controller REAL: lo que se prueba es el `ever` de su onInit sobre
      // currentDayIndex. Sus otras cargas fallan en silencio sin
      // StorageService registrado; no tocan a este doble.
      Get.put<AuthService>(_FakeAuthService(_alumna()));
      final api = _FakeBloquesApi();
      Get.put<TimeBlocksService>(TimeBlocksService(apiClient: api));
      final horario = Get.put<HorarioController>(HorarioController());
      await pumpEventQueue();
      // La del onInit: sin días todavía, es la de respaldo. No es lo que se
      // prueba aquí.
      api.ventanasPedidas.clear();

      horario.daysList.assignAll(_ciclo(semanas: 18));
      horario.currentDayIndex.value = 7 * 16; // lunes 14 de diciembre
      await pumpEventQueue();
      horario.currentDayIndex.value = 7 * 16 + 3; // jueves de esa semana
      await pumpEventQueue();
      horario.currentDayIndex.value = 7 * 17; // lunes 21 de diciembre
      await pumpEventQueue();

      expect(api.ventanasPedidas, <Map<String, String?>>[
        <String, String?>{'from': '2026-12-14', 'to': '2027-04-12'},
        <String, String?>{'from': '2026-12-21', 'to': '2027-04-19'},
      ]);
      // Borrarlo llama a su onClose, que apaga el reloj y el `ever`.
      Get.delete<HorarioController>();
    });

    /// La ventana que pediría el horario, sin días cargados, si hoy en Lima
    /// fuera [hoy]. El controller se crea sin registrar, así que su onInit no
    /// corre.
    ({String from, String to}) ventanaSiHoyEs(DateTime hoy) {
      final horario = HorarioController();
      horario.currentLimaTime.value = hoy;
      return horario.ventanaVisible();
    }

    test('sin ciclo con fechas, son las cuatro semanas alrededor de hoy, de lunes a domingo',
        () {
      // Miércoles 23: la semana pasada, esta y las dos siguientes.
      final ventana = ventanaSiHoyEs(DateTime.utc(2026, 9, 23, 10));
      expect(ventana, (from: '2026-09-14', to: '2026-10-11'));
      // En UTC: con la hora local, una máquina con cambio de hora dentro de la
      // ventana (Sídney lo tiene el 4 de octubre) contaría 26 días y 23 horas.
      final desde = DateTime.parse('${ventana.from}T00:00:00Z');
      final hasta = DateTime.parse('${ventana.to}T00:00:00Z');
      expect(
        hasta.difference(desde).inDays,
        27,
        reason: '28 días, lejos del tope de 120 del servidor',
      );
    });

    test('sin ciclo, el lunes y el domingo de una misma semana piden la misma ventana',
        () {
      const esperada = (from: '2026-09-14', to: '2026-10-11');
      expect(ventanaSiHoyEs(DateTime.utc(2026, 9, 21, 7)), esperada);
      expect(ventanaSiHoyEs(DateTime.utc(2026, 9, 27, 21, 59)), esperada);
    });

    test('sin ciclo, cruza el año sin romperse', () {
      // El 1 de enero de 2026 es jueves: su lunes es el 29 de diciembre.
      expect(
        ventanaSiHoyEs(DateTime.utc(2026, 1, 1, 10)),
        (from: '2025-12-22', to: '2026-01-18'),
      );
    });

    test('al crearse, el horario de una alumna pide sus bloques de esa ventana',
        () async {
      Get.put<AuthService>(_FakeAuthService(_alumna()));
      final api = _FakeBloquesApi();
      Get.put<TimeBlocksService>(TimeBlocksService(apiClient: api));

      // El controller REAL: lo que se prueba es su onInit. El resto de sus
      // cargas (días, secciones, evaluaciones, carga semanal) sale por su
      // propio ApiClient y falla en silencio sin StorageService registrado;
      // no toca a este doble. Los bloques se piden después de los días, que
      // aquí no llegan: la ventana es la de respaldo, una sola vez.
      final horario = Get.put<HorarioController>(HorarioController());
      await pumpEventQueue();

      final esperada = horario.ventanaVisible();
      expect(api.ventanasPedidas, <Map<String, String?>>[
        <String, String?>{'from': esperada.from, 'to': esperada.to},
      ]);
      // Borrarlo llama a su onClose, que apaga el reloj de un minuto.
      Get.delete<HorarioController>();
    });

    test('un docente no pide bloques propios', () async {
      Get.put<AuthService>(_FakeAuthService(_alumna(role: 'teacher')));
      final api = _FakeBloquesApi();
      Get.put<TimeBlocksService>(TimeBlocksService(apiClient: api));

      Get.put<HorarioController>(HorarioController());
      await pumpEventQueue();

      expect(api.ventanasPedidas, isEmpty);
      Get.delete<HorarioController>();
    });

    test('sin ciclo, al volver a la pestaña reload pide la ventana solo si cambió la semana',
        () async {
      // HomePage llama a reload() cada vez que se vuelve al horario, y el
      // controller vive mientras la app siga abierta: sin ciclo con fechas, es
      // lo único que corre la ventana de respaldo cuando pasa la semana.
      Get.put<AuthService>(_FakeAuthService(_alumna()));
      final api = _FakeBloquesApi();
      Get.put<TimeBlocksService>(TimeBlocksService(apiClient: api));
      // Sin registrar: su onInit no corre, así que las únicas peticiones son
      // las de cada reload. Sus otras cargas fallan en silencio, como arriba.
      final horario = HorarioController();

      horario.currentLimaTime.value = DateTime.utc(2026, 9, 23, 10);
      await horario.reload();
      await horario.reload(); // la misma semana: el service no vuelve a pedir
      horario.currentLimaTime.value = DateTime.utc(2026, 9, 30, 10);
      await horario.reload(); // la semana siguiente: ventana nueva

      expect(api.ventanasPedidas, <Map<String, String?>>[
        <String, String?>{'from': '2026-09-14', 'to': '2026-10-11'},
        <String, String?>{'from': '2026-09-21', 'to': '2026-10-18'},
      ]);
    });
  });

  group('UNITARIA · la fecha de cada día del horario (isoDate, D1)', () {
    test('DaySchedule.fromJson conserva isoDate y deja en null lo que no es una fecha',
        () {
      Map<String, dynamic> dia(Object? iso, {bool conClave = true}) =>
          <String, dynamic>{
            'dayName': 'Lunes',
            'dateText': '21 de Septiembre',
            'weekText': 'Semana 5 del ciclo',
            if (conClave) 'isoDate': iso,
          };

      final conFecha = DaySchedule.fromJson(dia('2026-09-21'));
      expect(conFecha.dayName, 'Lunes');
      expect(conFecha.dateText, '21 de Septiembre');
      expect(conFecha.weekText, 'Semana 5 del ciclo');
      expect(conFecha.isoDate, '2026-09-21');
      // Ciclo sin semanas: el backend manda null.
      expect(DaySchedule.fromJson(dia(null)).isoDate, isNull);
      // Un backend anterior no manda la clave: el campo es aditivo.
      expect(DaySchedule.fromJson(dia(null, conClave: false)).isoDate, isNull);
      // Lo que no es una fecha YYYY-MM-DD que existe no se cuela: ni el texto
      // del día, ni una fecha sin ceros, ni el 30 de febrero (DateTime lo
      // correría al 2 de marzo), ni un número. (Una fecha sin guiones no va
      // aquí: el script de cierre la tomaría por un código de alumno.)
      for (final malo in <Object>[
        '',
        '21 de Septiembre',
        '2026-9-21',
        '2026-02-30',
        21,
      ]) {
        expect(DaySchedule.fromJson(dia(malo)).isoDate, isNull, reason: '$malo');
      }
    });
  });

  group('UNITARIA · qué bloques propios caen en cada día (RF-BLQ-4)', () {
    setUp(() {
      Get.testMode = true;
      Get.reset();
    });
    tearDown(Get.reset);

    /// Un horario con el service ya cargado con [ocurrencias] y [reglas]. El
    /// controller se crea sin registrar: su onInit no corre y no pide nada.
    Future<HorarioController> horarioCon(
      List<Map<String, dynamic>> ocurrencias, {
      List<Map<String, dynamic>> reglas = const <Map<String, dynamic>>[],
    }) async {
      Get.put<AuthService>(_FakeAuthService(_alumna()));
      final servicio = TimeBlocksService(
        apiClient: _FakeBloquesApi(reglas: reglas, ocurrencias: ocurrencias),
      );
      Get.put<TimeBlocksService>(servicio);
      await servicio.load(from: '2026-09-14', to: '2026-10-11');
      return HorarioController();
    }

    test('filtra por fecha y no por nombre: el lunes 21 no es el lunes 28',
        () async {
      final horario = await horarioCon([
        _ocurrencia(fecha: '2026-09-21', diaDeLaSemana: 1, inicio: '14:00', fin: '18:00'),
      ]);
      // daysList trae los siete días de CADA semana del ciclo: por nombre,
      // la práctica del 21 saldría también el 28.
      final lunes21 = DaySchedule('Lunes', '21 de Septiembre', 'Semana 5 del ciclo',
          isoDate: '2026-09-21');
      final lunes28 = DaySchedule('Lunes', '28 de Septiembre', 'Semana 6 del ciclo',
          isoDate: '2026-09-28');

      expect(horario.bloquesDelDia(lunes21).map((o) => o.date), ['2026-09-21']);
      expect(horario.bloquesDelDia(lunes28), isEmpty);
    });

    test('la fecha del día es su isoDate, no su dateText', () async {
      final horario = await horarioCon([
        _ocurrencia(fecha: '2026-09-21', diaDeLaSemana: 1, inicio: '14:00', fin: '18:00'),
      ]);
      // Un dateText que no coincide con su isoDate: manda isoDate. Ninguna
      // fecha se lee de dateText (D1).
      expect(
        horario
            .bloquesDelDia(DaySchedule('Lunes', '28 de Septiembre', 'Semana 6 del ciclo',
                isoDate: '2026-09-21'))
            .map((o) => o.date),
        ['2026-09-21'],
      );
      expect(
        horario.bloquesDelDia(DaySchedule('Lunes', '21 de Septiembre', 'Semana 5 del ciclo',
            isoDate: '2026-09-28')),
        isEmpty,
      );
    });

    test('un ciclo sin semanas (isoDate null) toma ese día en la semana de hoy',
        () async {
      final horario = await horarioCon([
        _ocurrencia(fecha: '2026-09-23', diaDeLaSemana: 3, inicio: '14:00', fin: '18:00'),
        _ocurrencia(fecha: '2026-09-30', diaDeLaSemana: 3, inicio: '14:00', fin: '18:00'),
      ]);
      horario.currentLimaTime.value = DateTime.utc(2026, 9, 22, 10); // martes
      // Sin semanas el backend manda los siete días con isoDate null,
      // dateText "" y weekText "Semana actual" (schedule.service.ts): no hay
      // fecha contra la que comparar, y por nombre saldrían los cuatro
      // miércoles de la ventana uno al lado del otro. Se toma el miércoles de
      // esta semana.
      final soloEste = ['2026-09-23'];
      expect(
        horario.bloquesDelDia(DaySchedule('Miércoles', '', 'Semana actual')).map((o) => o.date),
        soloEste,
      );
      expect(
        horario.bloquesDelDia(DaySchedule('Miercoles', '', 'Semana actual')).map((o) => o.date),
        soloEste,
      );
      expect(horario.bloquesDelDia(DaySchedule('Jueves', '', 'Semana actual')), isEmpty);
    });

    test('sin el service de bloques registrado no hay bloques, y nada se cae', () {
      expect(
        HorarioController().bloquesDelDia(
          DaySchedule('Lunes', '21 de Septiembre', 'Semana 5 del ciclo',
              isoDate: '2026-09-21'),
        ),
        isEmpty,
      );
    });

    test('los bloques propios no se cuelan en las clases ni en sus colores',
        () async {
      // Si vivieran en _todasLasSecciones, coursesForDay los devolvería como
      // clases (y podría marcarlos como evaluación por el nombre) y
      // colorPorCurso les daría un color de la paleta de doce, quitándoselo a
      // un curso real.
      final horario = await horarioCon([
        _ocurrencia(fecha: '2026-09-21', diaDeLaSemana: 1, inicio: '14:00', fin: '18:00'),
      ]);
      final lunes = DaySchedule('Lunes', '21 de Septiembre', 'Semana 5 del ciclo',
          isoDate: '2026-09-21');

      expect(horario.bloquesDelDia(lunes), hasLength(1));
      expect(horario.coursesForDay(lunes), isEmpty);
      expect(horario.colorPorCurso, isEmpty);
    });

    test('un día cancelado sale aparte, con las horas de su regla, y no entre las ocurrencias',
        () async {
      // El servidor no manda el miércoles 23 cancelado (RS-BE-33); la regla
      // sí trae la excepción, y de ahí sale para pintarlo tenue (RF-BLQ-5).
      final horario = await horarioCon(
        [
          _ocurrencia(fecha: '2026-09-21', diaDeLaSemana: 1, inicio: '14:00', fin: '18:00'),
        ],
        reglas: [
          _reglaConExcepciones([
            <String, dynamic>{'date': '2026-09-23', 'status': 'cancelled'},
          ]),
        ],
      );
      final lunes21 = DaySchedule('Lunes', '21 de Septiembre', 'Semana 5 del ciclo',
          isoDate: '2026-09-21');
      final miercoles23 = DaySchedule('Miércoles', '23 de Septiembre', 'Semana 5 del ciclo',
          isoDate: '2026-09-23');

      expect(horario.bloquesDelDia(miercoles23), isEmpty);
      final cancelados = horario.bloquesCanceladosDelDia(miercoles23);
      expect(cancelados, hasLength(1));
      expect(cancelados.single.blockId, 7);
      expect(cancelados.single.date, '2026-09-23');
      expect(cancelados.single.dayOfWeek, 3);
      expect(cancelados.single.startTime, '14:00');
      expect(cancelados.single.endTime, '18:00');
      expect(horario.bloquesCanceladosDelDia(lunes21), isEmpty);
    });

    test('una excepción cancelada que quedó fuera del patrón no se pinta', () async {
      // Tras editar la regla, una excepción puede quedar en un día que el
      // patrón ya no genera: el servidor la ignora al expandir, y la grilla
      // también.
      final horario = await horarioCon(
        const <Map<String, dynamic>>[],
        reglas: [
          _reglaConExcepciones([
            // Jueves: la regla es de lunes y miércoles.
            <String, dynamic>{'date': '2026-09-24', 'status': 'cancelled'},
            // Miércoles, pero después del 15 de diciembre.
            <String, dynamic>{'date': '2027-01-06', 'status': 'cancelled'},
          ]),
        ],
      );

      expect(
        horario.bloquesCanceladosDelDia(
          DaySchedule('Jueves', '24 de Septiembre', 'Semana 5 del ciclo',
              isoDate: '2026-09-24'),
        ),
        isEmpty,
      );
      expect(
        horario.bloquesCanceladosDelDia(
          DaySchedule('Miércoles', '6 de Enero', 'Semana 19 del ciclo',
              isoDate: '2027-01-06'),
        ),
        isEmpty,
      );
    });
  });

  group('WIDGET · bloques propios en la grilla del horario (RF-BLQ-4)', () {
    setUp(() {
      Get.testMode = true;
      Get.reset();
    });
    tearDown(Get.reset);

    testWidgets(
        'vista de día: el bloque propio lleva su nombre y su color, sin salón ni sección',
        (tester) async {
      await _montar(tester, pantalla: _vertical, ocurrencias: [
        _ocurrencia(fecha: '2026-09-21', diaDeLaSemana: 1, inicio: '14:00', fin: '18:00'),
      ]);

      expect(find.text('PRÁCTICAS DE PRUEBA'), findsOneWidget);
      expect(find.text('Sin salón'), findsNothing);
      expect(find.textContaining('Sección'), findsNothing);

      // El color es el que eligió la alumna (#27AE60), no uno de la paleta
      // que colorPorCurso reparte entre las secciones.
      final caja = tester.widget<Container>(
        find
            .descendant(of: _bloque('PRÁCTICAS DE PRUEBA'), matching: find.byType(Container))
            .first,
      );
      expect((caja.decoration as BoxDecoration).color, const Color(0xFF27AE60));
    });

    testWidgets('el nombre de un bloque propio va entero aunque lleve una barra',
        (tester) async {
      // La barra corta el nombre bilingüe que manda el portal ("CURSO /
      // COURSE"); el nombre de un bloque lo escribió la alumna.
      await _montar(tester, pantalla: _vertical, ocurrencias: [
        _ocurrencia(
          fecha: '2026-09-21',
          diaDeLaSemana: 1,
          inicio: '14:00',
          fin: '18:00',
          titulo: 'Prácticas / Taller de prueba',
        ),
      ]);

      expect(find.text('PRÁCTICAS / TALLER DE PRUEBA'), findsOneWidget);
    });

    testWidgets('vista semanal: el bloque propio sale en la columna de su día y solo ahí',
        (tester) async {
      await _montar(tester, pantalla: _horizontal, ocurrencias: [
        _ocurrencia(fecha: '2026-09-23', diaDeLaSemana: 3, inicio: '14:00', fin: '18:00'),
      ]);

      expect(find.text('PRÁCTICAS DE PRUEBA'), findsOneWidget);
      expect(find.textContaining('Sección'), findsNothing);
      final miercoles = _columnaDe(tester, 'Miércoles');
      final bloque = tester.getRect(_bloque('PRÁCTICAS DE PRUEBA'));
      expect(bloque.left, greaterThanOrEqualTo(miercoles.left));
      expect(bloque.right, lessThanOrEqualTo(miercoles.right));
    });

    testWidgets('vista semanal: los bloques son los de la semana del día activo',
        (tester) async {
      // La vista semanal arma sus columnas con la primera semana del ciclo
      // (_weekDays), y a las clases les da igual. A los bloques no: cada
      // semana tiene los suyos. Con el martes 29 activo, la semana es la del
      // 28 de septiembre al 4 de octubre.
      final dosSemanas = <DaySchedule>[
        ..._semana(),
        for (var i = 0; i < 7; i++) _diaDelCiclo(DateTime.utc(2026, 9, 28 + i), 6),
      ];
      await _montar(
        tester,
        pantalla: _horizontal,
        dias: dosSemanas,
        diaActivo: 8,
        ocurrencias: [
          _ocurrencia(fecha: '2026-09-21', diaDeLaSemana: 1, inicio: '14:00', fin: '18:00'),
          _ocurrencia(
            fecha: '2026-09-28',
            diaDeLaSemana: 1,
            inicio: '14:00',
            fin: '18:00',
            titulo: 'Voluntariado de prueba',
          ),
        ],
      );

      expect(find.text('VOLUNTARIADO DE PRUEBA'), findsOneWidget);
      expect(find.text('PRÁCTICAS DE PRUEBA'), findsNothing);
    });

    testWidgets('la vista semanal suma el domingo: siete columnas y su bloque se ve',
        (tester) async {
      await _montar(tester, pantalla: _horizontal, ocurrencias: [
        _ocurrencia(fecha: '2026-09-27', diaDeLaSemana: 7, inicio: '09:00', fin: '13:00'),
      ]);

      for (final dia in const [
        'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo',
      ]) {
        expect(find.text(dia), findsOneWidget, reason: dia);
      }
      final domingo = _columnaDe(tester, 'Domingo');
      final bloque = tester.getRect(_bloque('PRÁCTICAS DE PRUEBA'));
      expect(bloque.left, greaterThanOrEqualTo(domingo.left));
      expect(bloque.right, lessThanOrEqualTo(domingo.right));
    });

    testWidgets('vista de día: el bloque del domingo también se ve', (tester) async {
      await _montar(tester, pantalla: _vertical, diaActivo: 6, ocurrencias: [
        _ocurrencia(fecha: '2026-09-27', diaDeLaSemana: 7, inicio: '09:00', fin: '13:00'),
      ]);

      expect(find.text('Domingo, 27 de Septiembre'), findsOneWidget);
      expect(find.text('PRÁCTICAS DE PRUEBA'), findsOneWidget);
    });

    testWidgets('un horario sin domingo sigue con sus seis columnas, como hoy',
        (tester) async {
      await _montar(tester, pantalla: _horizontal, conDomingo: false, clasesPorDia: {
        'Sábado': [_clase('CURSO DE PRUEBA A', '08:00 am', '10:00 am')],
      });

      for (final dia in const ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado']) {
        expect(find.text(dia), findsOneWidget, reason: dia);
      }
      expect(find.text('Domingo'), findsNothing);
      // Seis columnas iguales: el ancho menos los 34 de la columna de horas.
      expect(_columnaDe(tester, 'Sábado').width, closeTo((1000 - 34) / 6, 0.01));
      expect(find.text('CURSO DE PRUEBA A'), findsOneWidget);
    });

    testWidgets(
        'vista de día: una clase y un bloque a la misma hora se parten el ancho y los dos reciben toques',
        (tester) async {
      await _montar(
        tester,
        pantalla: _vertical,
        clasesPorDia: {
          'Lunes': [_clase('CURSO DE PRUEBA A', '04:00 pm', '06:00 pm')],
        },
        ocurrencias: [
          _ocurrencia(fecha: '2026-09-21', diaDeLaSemana: 1, inicio: '14:00', fin: '18:00'),
        ],
      );

      final clase = tester.getRect(_bloque('CURSO DE PRUEBA A'));
      final propio = tester.getRect(_bloque('PRÁCTICAS DE PRUEBA'));
      // La pista de la vista de día va de 66 a 600 - 14 = 586: 520 de ancho.
      // El bloque propio empieza antes (14:00) y se queda con la columna 0.
      expect(propio.left, 66);
      expect(propio.width, closeTo(260, 0.01));
      expect(clase.left, closeTo(326, 0.01));
      expect(clase.right, closeTo(586, 0.01));
      expect(propio.overlaps(clase), isFalse);
      expect(_recibeElToque(tester, _bloque('CURSO DE PRUEBA A')), isTrue);
      expect(_recibeElToque(tester, _bloque('PRÁCTICAS DE PRUEBA')), isTrue);
    });

    testWidgets('vista semanal: también se parten la columna de su día',
        (tester) async {
      await _montar(
        tester,
        pantalla: _horizontal,
        clasesPorDia: {
          'Lunes': [_clase('CURSO DE PRUEBA A', '04:00 pm', '06:00 pm')],
        },
        ocurrencias: [
          _ocurrencia(fecha: '2026-09-21', diaDeLaSemana: 1, inicio: '14:00', fin: '18:00'),
        ],
      );

      final lunes = _columnaDe(tester, 'Lunes');
      final clase = tester.getRect(_bloque('CURSO DE PRUEBA A'));
      final propio = tester.getRect(_bloque('PRÁCTICAS DE PRUEBA'));
      // La pista: 1 px del borde izquierdo de la columna y 2 de margen a cada
      // lado. Cada uno se queda con la mitad.
      final pista = lunes.width - 1 - 2 - 2;
      expect(propio.left, closeTo(lunes.left + 1 + 2, 0.01));
      expect(propio.width, closeTo(pista / 2, 0.01));
      expect(clase.right, closeTo(lunes.right - 2, 0.01));
      expect(propio.overlaps(clase), isFalse);
      expect(_recibeElToque(tester, _bloque('CURSO DE PRUEBA A')), isTrue);
      expect(_recibeElToque(tester, _bloque('PRÁCTICAS DE PRUEBA')), isTrue);
    });

    testWidgets('sin cruces, un bloque ocupa lo mismo que hoy en la vista de día (66 y 14)',
        (tester) async {
      await _montar(tester, pantalla: _vertical, clasesPorDia: {
        'Lunes': [_clase('CURSO DE PRUEBA A', '08:00 am', '10:00 am')],
      });

      final clase = tester.getRect(_bloque('CURSO DE PRUEBA A'));
      expect(clase.left, 66);
      expect(clase.right, 600 - 14);
    });

    testWidgets('sin cruces, un bloque ocupa lo mismo que hoy en la vista semanal (2 y 2)',
        (tester) async {
      await _montar(tester, pantalla: _horizontal, clasesPorDia: {
        'Lunes': [_clase('CURSO DE PRUEBA A', '08:00 am', '10:00 am')],
      });

      final lunes = _columnaDe(tester, 'Lunes');
      final clase = tester.getRect(_bloque('CURSO DE PRUEBA A'));
      expect(clase.left, closeTo(lunes.left + 1 + 2, 0.01));
      expect(clase.right, closeTo(lunes.right - 2, 0.01));
    });

    testWidgets('un día movido se pinta en su hora nueva, no en la del patrón',
        (tester) async {
      // El patrón es de 14:00 a 18:00 y ese lunes el servidor lo manda movido
      // a 15:00-19:00. Dos clases hacen de regla: una termina a las 3 pm y la
      // otra empieza a las 7 pm; ninguna se cruza con el bloque, solo se tocan.
      await _montar(
        tester,
        pantalla: _vertical,
        clasesPorDia: {
          'Lunes': [
            _clase('CURSO DE PRUEBA A', '01:00 pm', '03:00 pm'),
            _clase('CURSO DE PRUEBA B', '07:00 pm', '08:00 pm'),
          ],
        },
        ocurrencias: [
          _ocurrencia(
            fecha: '2026-09-21',
            diaDeLaSemana: 1,
            inicio: '15:00',
            fin: '19:00',
            movida: true,
          ),
        ],
      );

      final antes = tester.getRect(_bloque('CURSO DE PRUEBA A'));
      final movido = tester.getRect(_bloque('PRÁCTICAS DE PRUEBA'));
      final despues = tester.getRect(_bloque('CURSO DE PRUEBA B'));
      // Entre dos bloques seguidos queda justo el pelo de separación.
      expect(movido.top - antes.bottom, closeTo(HorarioPage.blockHairline, 0.01));
      expect(despues.top - movido.bottom, closeTo(HorarioPage.blockHairline, 0.01));
      // Tocarse en el borde no reparte: los tres van a ancho completo.
      expect(antes.left, 66);
      expect(movido.left, 66);
      expect(despues.left, 66);
    });

    testWidgets(
        'un día cancelado se pinta tenue y lo dice, con las horas de la regla, y no como ocurrencia',
        (tester) async {
      // La regla dice lunes y miércoles de 14:00 a 18:00, y el miércoles 23
      // está cancelado. El servidor no manda esa ocurrencia (RS-BE-33): la
      // grilla lo pinta desde la excepción de la regla, tenue y con "Este día
      // está cancelado" (D2), para que la alumna pueda tocarlo y devolverlo al
      // patrón (RF-BLQ-5, Tarea 6).
      await _montar(
        tester,
        pantalla: _horizontal,
        reglas: [
          _reglaConExcepciones([
            <String, dynamic>{'date': '2026-09-23', 'status': 'cancelled'},
          ]),
        ],
        ocurrencias: [
          _ocurrencia(fecha: '2026-09-21', diaDeLaSemana: 1, inicio: '14:00', fin: '18:00'),
        ],
      );

      final lunes = _columnaDe(tester, 'Lunes');
      final miercoles = _columnaDe(tester, 'Miércoles');
      final bloques = _bloque('PRÁCTICAS DE PRUEBA');
      expect(bloques, findsNWidgets(2));
      Rect? delLunes;
      Rect? delMiercoles;
      for (var i = 0; i < 2; i++) {
        final rect = tester.getRect(bloques.at(i));
        final tenue = find.ancestor(
          of: bloques.at(i),
          matching: find.byWidgetPredicate((w) => w is Opacity && w.opacity < 1),
        );
        final aviso = find.descendant(
          of: bloques.at(i),
          matching: find.text('Este día está cancelado'),
        );
        if (rect.center.dx >= miercoles.left && rect.center.dx <= miercoles.right) {
          delMiercoles = rect;
          expect(tenue, findsOneWidget, reason: 'el cancelado va tenue');
          expect(aviso, findsOneWidget, reason: 'y lo dice debajo del nombre');
        } else {
          expect(rect.center.dx, inInclusiveRange(lunes.left, lunes.right));
          delLunes = rect;
          expect(tenue, findsNothing, reason: 'el lunes es una ocurrencia normal');
          expect(aviso, findsNothing);
        }
      }
      // Las horas de la regla: el mismo tramo que la ocurrencia del lunes.
      expect(delLunes, isNotNull);
      expect(delMiercoles, isNotNull);
      expect(delMiercoles!.top, closeTo(delLunes!.top, 0.01));
      expect(delMiercoles.height, closeTo(delLunes.height, 0.01));
    });

    testWidgets('un bloque de la semana 10 del ciclo se ve al navegar hasta ella',
        (tester) async {
      // La ventana es la del ciclo (RF-BLQ-7): 16 semanas, no las cuatro
      // alrededor de hoy. El doble del API solo devuelve lo que cae dentro
      // de la ventana pedida, como el servidor.
      final servicio = await _montar(
        tester,
        pantalla: _vertical,
        dias: _ciclo(semanas: 16),
        cargarAntes: false,
        ocurrencias: [
          _ocurrencia(fecha: '2026-10-26', diaDeLaSemana: 1, inicio: '14:00', fin: '18:00'),
        ],
      );
      final horario = Get.find<HorarioController>();
      final ventana = horario.ventanaVisible();
      await servicio.load(from: ventana.from, to: ventana.to);
      await tester.pump();
      expect(find.text('PRÁCTICAS DE PRUEBA'), findsNothing); // lunes 24 de agosto

      horario.currentDayIndex.value = 7 * 9; // lunes de la semana 10
      await tester.pump();

      expect(find.text('Lunes, 26 de Octubre'), findsOneWidget);
      expect(find.text('PRÁCTICAS DE PRUEBA'), findsOneWidget);
    });

    testWidgets('si los bloques llegan después de pintar el horario, aparecen solos',
        (tester) async {
      final servicio = await _montar(
        tester,
        pantalla: _vertical,
        cargarAntes: false,
        ocurrencias: [
          _ocurrencia(fecha: '2026-09-21', diaDeLaSemana: 1, inicio: '14:00', fin: '18:00'),
        ],
      );
      expect(find.text('PRÁCTICAS DE PRUEBA'), findsNothing);

      // Es lo que pasa en la app: el horario pinta sus días antes de que
      // vuelvan los bloques, y el service recarga su ventana después de
      // crear, editar o borrar. La grilla no hace nada y tiene que enterarse.
      await servicio.load(from: '2026-09-14', to: '2026-10-11');
      await tester.pump();

      expect(find.text('PRÁCTICAS DE PRUEBA'), findsOneWidget);
    });

    testWidgets('vista semanal: si los bloques llegan después, también aparecen solos',
        (tester) async {
      // La vista semanal tiene su propio LayoutBuilder y su propia lectura de
      // los bloques propios (propiosPorDia): la prueba de arriba no la cubre.
      final servicio = await _montar(
        tester,
        pantalla: _horizontal,
        cargarAntes: false,
        ocurrencias: [
          _ocurrencia(fecha: '2026-09-23', diaDeLaSemana: 3, inicio: '14:00', fin: '18:00'),
        ],
      );
      expect(find.text('PRÁCTICAS DE PRUEBA'), findsNothing);

      await servicio.load(from: '2026-09-14', to: '2026-10-11');
      await tester.pump();

      expect(find.text('PRÁCTICAS DE PRUEBA'), findsOneWidget);
    });
  });
}
```

Qué fija cada prueba, para que nadie las recorte:

- **La ventana (11):** la del ciclo de 16 semanas, del primer al último `isoDate`, sin depender del día activo; la de un ciclo de 18 semanas, que no entra en 120 días y pide 120 desde el lunes de la semana del día activo (el jueves pide lo mismo que su lunes); el año que sale de `isoDate` en un ciclo que cruza de diciembre a enero, sin adivinarlo; el ciclo sin semanas (`isoDate` null), que pide las cuatro semanas alrededor de hoy; el `ever` del controller real, que en un ciclo largo pide la ventana de la semana nueva al cambiar de semana y nada dentro de la misma; y, sin ciclo con fechas, las cuatro semanas desde un miércoles, que el lunes y el domingo de una misma semana pidan lo mismo (el borde de `weekday - 1`) y el cruce de año. Además, que el `onInit` real de una alumna pida exactamente `ventanaVisible()` y una sola vez; que el de un docente no pida nada; y que `reload` (lo que `HomePage` llama al volver a la pestaña) no repita la petición en la misma semana y pida la ventana nueva cuando la semana cambió. Sin esa última, volver a poner `_loadDays()` en lugar de `_cargarDiasYBloques()` en `reload` no rompería ninguna prueba y la ventana de respaldo se quedaría congelada mientras la app siga abierta.
- **La fecha de cada día (1):** `DaySchedule.fromJson` conserva `isoDate`, lo deja en null cuando llega null o no llega (el campo es aditivo), y descarta lo que no es una fecha `YYYY-MM-DD` que existe.
- **Qué cae en cada día (7):** por fecha y no por nombre (el lunes 21 no es el 28, y `daysList` trae los dos); que la fecha es la de `isoDate` aunque `dateText` diga otra cosa (sin esa prueba, volver a comparar por `dateText` no rompería nada); el respaldo sin semanas (`isoDate` null), que toma el día en la semana de hoy y no los cuatro de la ventana; sin el service registrado no se cae; que los propios no se cuelan en `coursesForDay` ni en `colorPorCurso`; que un día cancelado sale en `bloquesCanceladosDelDia` con las horas de su regla y no en `bloquesDelDia`; y que una excepción cancelada fuera del patrón (otro día de la semana, o fuera del rango) no se pinta.
- **La grilla (16):**
  - nombre y color, sin salón ni sección;
  - el nombre con barra va entero;
  - la columna correcta en la semanal, y la semana del día activo;
  - el domingo en las dos vistas, y las seis columnas de siempre cuando no hay domingo;
  - el reparto en las dos vistas, con los dos bloques tocables. `_recibeElToque` mira el camino real del toque: el `Stack` entrega el toque al primer hijo que lo acepta, así que un bloque tapado no aparece en el camino;
  - los márgenes de hoy cuando no hay cruces, en las dos vistas (66/14, y 2/2 más el borde de 1 px de cada columna);
  - el día movido en su hora nueva;
  - el día cancelado, que se pinta tenue (un `Opacity` menor que 1) en su columna, con las horas de la regla y con «Este día está cancelado» dentro del bloque, mientras la ocurrencia normal no lleva ni lo uno ni lo otro;
  - un bloque de la semana 10 del ciclo, que se ve al navegar hasta ella: el doble del API solo devuelve lo que cae en la ventana pedida, así que con la ventana de cuatro semanas la prueba falla;
  - y los bloques que llegan tarde, en las dos vistas: cada una lee los propios en su propio sitio, fuera de su `LayoutBuilder`, y cada lectura tiene su prueba.
- Tres de widget son **de regresión**: «un horario sin domingo sigue con sus seis columnas, como hoy» y las dos de «sin cruces, un bloque ocupa lo mismo que hoy…». Pasarían con la vista de hoy (en el punto de control del Paso 3 ya pasan) y tienen que seguir pasando al final. El horario no tenía hasta ahora ninguna prueba de widget, y estas tres son las que lo protegen.

- [ ] **Paso 2: Correr la prueba y ver que falla**

```
cd "${REPO:?}"
"${FLUTTER:?}" test test/HU35_jeff/time_blocks_grilla_test.dart
```

Esperado: **no compila**, porque todavía no existe nada de lo que la prueba usa: `DaySchedule` sin `isoDate` ni `fromJson`, y los tres métodos del controller. Salen exactamente estos treinta y cuatro errores y ninguno más (cada uno seguido de su explicación y del trozo de código señalado). Si aparece otro, el fallo está en la prueba y no en lo que falta implementar:

```
test/HU35_jeff/time_blocks_grilla_test.dart:157:7: Error: No named parameter with the name 'isoDate'.
test/HU35_jeff/time_blocks_grilla_test.dart:200:13: Error: No named parameter with the name 'isoDate'.
test/HU35_jeff/time_blocks_grilla_test.dart:649:36: Error: Member not found: 'DaySchedule.fromJson'.
test/HU35_jeff/time_blocks_grilla_test.dart:655:26: Error: Member not found: 'DaySchedule.fromJson'.
test/HU35_jeff/time_blocks_grilla_test.dart:657:26: Error: Member not found: 'DaySchedule.fromJson'.
test/HU35_jeff/time_blocks_grilla_test.dart:669:28: Error: Member not found: 'DaySchedule.fromJson'.
test/HU35_jeff/time_blocks_grilla_test.dart:704:11: Error: No named parameter with the name 'isoDate'.
test/HU35_jeff/time_blocks_grilla_test.dart:706:11: Error: No named parameter with the name 'isoDate'.
test/HU35_jeff/time_blocks_grilla_test.dart:721:17: Error: No named parameter with the name 'isoDate'.
test/HU35_jeff/time_blocks_grilla_test.dart:727:13: Error: No named parameter with the name 'isoDate'.
test/HU35_jeff/time_blocks_grilla_test.dart:760:15: Error: No named parameter with the name 'isoDate'.
test/HU35_jeff/time_blocks_grilla_test.dart:776:11: Error: No named parameter with the name 'isoDate'.
test/HU35_jeff/time_blocks_grilla_test.dart:798:11: Error: No named parameter with the name 'isoDate'.
test/HU35_jeff/time_blocks_grilla_test.dart:800:11: Error: No named parameter with the name 'isoDate'.
test/HU35_jeff/time_blocks_grilla_test.dart:832:15: Error: No named parameter with the name 'isoDate'.
test/HU35_jeff/time_blocks_grilla_test.dart:839:15: Error: No named parameter with the name 'isoDate'.
test/HU35_jeff/time_blocks_grilla_test.dart:446:22: Error: The method 'ventanaVisible' isn't defined for the type 'HorarioController'.
test/HU35_jeff/time_blocks_grilla_test.dart:545:22: Error: The method 'ventanaVisible' isn't defined for the type 'HorarioController'.
test/HU35_jeff/time_blocks_grilla_test.dart:593:32: Error: The method 'ventanaVisible' isn't defined for the type 'HorarioController'.
test/HU35_jeff/time_blocks_grilla_test.dart:708:22: Error: The method 'bloquesDelDia' isn't defined for the type 'HorarioController'.
test/HU35_jeff/time_blocks_grilla_test.dart:709:22: Error: The method 'bloquesDelDia' isn't defined for the type 'HorarioController'.
test/HU35_jeff/time_blocks_grilla_test.dart:720:14: Error: The method 'bloquesDelDia' isn't defined for the type 'HorarioController'.
test/HU35_jeff/time_blocks_grilla_test.dart:726:17: Error: The method 'bloquesDelDia' isn't defined for the type 'HorarioController'.
test/HU35_jeff/time_blocks_grilla_test.dart:746:17: Error: The method 'bloquesDelDia' isn't defined for the type 'HorarioController'.
test/HU35_jeff/time_blocks_grilla_test.dart:750:17: Error: The method 'bloquesDelDia' isn't defined for the type 'HorarioController'.
test/HU35_jeff/time_blocks_grilla_test.dart:753:22: Error: The method 'bloquesDelDia' isn't defined for the type 'HorarioController'.
test/HU35_jeff/time_blocks_grilla_test.dart:758:29: Error: The method 'bloquesDelDia' isn't defined for the type 'HorarioController'.
test/HU35_jeff/time_blocks_grilla_test.dart:778:22: Error: The method 'bloquesDelDia' isn't defined for the type 'HorarioController'.
test/HU35_jeff/time_blocks_grilla_test.dart:802:22: Error: The method 'bloquesDelDia' isn't defined for the type 'HorarioController'.
test/HU35_jeff/time_blocks_grilla_test.dart:803:34: Error: The method 'bloquesCanceladosDelDia' isn't defined for the type 'HorarioController'.
test/HU35_jeff/time_blocks_grilla_test.dart:810:22: Error: The method 'bloquesCanceladosDelDia' isn't defined for the type 'HorarioController'.
test/HU35_jeff/time_blocks_grilla_test.dart:830:17: Error: The method 'bloquesCanceladosDelDia' isn't defined for the type 'HorarioController'.
test/HU35_jeff/time_blocks_grilla_test.dart:837:17: Error: The method 'bloquesCanceladosDelDia' isn't defined for the type 'HorarioController'.
test/HU35_jeff/time_blocks_grilla_test.dart:1161:31: Error: The method 'ventanaVisible' isn't defined for the type 'HorarioController'.
00:00 +0 -1: loading $REPO/test/HU35_jeff/time_blocks_grilla_test.dart [E]
  Failed to load "$REPO/test/HU35_jeff/time_blocks_grilla_test.dart":
00:00 +0 -1: Some tests failed.
```

Son doce de `isoDate` (el nombrado que todavía no existe en `DaySchedule`), cuatro de `DaySchedule.fromJson`, cuatro de `ventanaVisible`, diez de `bloquesDelDia`, y cuatro de `bloquesCanceladosDelDia`. La lista y los números de línea se midieron con `flutter test` (3.47.2) en una copia descartable del repo, con las Tareas 1 a 3 y este Paso 1 aplicados tal como están escritos; si la redacción del compilador cambia de versión, vale que sean esos treinta y cuatro usos.

Ninguno apunta a `reload`, que ya existe: la prueba de la pestaña compila desde ya, y es en el punto de control donde confirma que 3.a.4 quedó aplicado. Si esa cabecera cambió, los números pueden variar, pero el texto del error es el mismo. Si falla por `TimeBlocksService`, `time_blocks_service.dart` o `repartirEnColumnas`, falta una tarea anterior: **PARAR**.

- [ ] **Paso 3: Implementación mínima**

**3.a — El controller.** Siete reemplazos en `lib/pages/horario/horario_controller.dart`, en este orden.

3.a.1 — imports (`:7-8`). Reemplazar esto:

```dart
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
```

por esto:

```dart
import '../../models/time_block_model.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/time_blocks_service.dart';
```

3.a.2 — `DaySchedule` gana `isoDate` y un `fromJson` (`:10-16`). El constructor de siempre sigue valiendo: `isoDate` es un nombrado opcional, así que `_loadTeacherDaysAndSessions` (`:188`), que no se toca, sigue armando sus días igual y con `isoDate` en null. Reemplazar esto:

```dart
class DaySchedule {
  final String dayName;
  final String dateText;
  final String weekText;

  DaySchedule(this.dayName, this.dateText, this.weekText);
}
```

por esto:

```dart
class DaySchedule {
  final String dayName;
  final String dateText;
  final String weekText;

  /// La fecha exacta de ese día en hora de Lima, `"YYYY-MM-DD"`, o null
  /// cuando el ciclo no tiene semanas (el mismo caso en que [dateText] llega
  /// vacío). La manda `/schedule/me/sessions` (D1). De aquí, y nunca de
  /// [dateText], salen las fechas de los bloques propios (RF-BLQ-4 y
  /// RF-BLQ-7): [dateText] no trae año.
  final String? isoDate;

  DaySchedule(this.dayName, this.dateText, this.weekText, {this.isoDate});

  /// Un elemento de `days` de `/schedule/me/sessions`. Los tres textos se
  /// leen como siempre; [isoDate] queda en null si no llega (un backend
  /// anterior) o si no es una fecha `YYYY-MM-DD` que existe.
  factory DaySchedule.fromJson(Map<String, dynamic> json) => DaySchedule(
    json['dayName'] as String,
    json['dateText'] as String,
    json['weekText'] as String,
    isoDate: _fechaIsoONull(json['isoDate']),
  );
}

/// [valor] si es una fecha `YYYY-MM-DD` que existe en el calendario, o null.
/// `DateTime.tryParse` corre el 30 de febrero al 2 de marzo: por eso la vuelta
/// a texto tiene que dar lo mismo.
String? _fechaIsoONull(Object? valor) {
  if (valor is! String) return null;
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(valor)) return null;
  final fecha = DateTime.tryParse('${valor}T00:00:00Z');
  if (fecha == null) return null;
  final vuelta =
      '${fecha.year.toString().padLeft(4, '0')}-'
      '${fecha.month.toString().padLeft(2, '0')}-'
      '${fecha.day.toString().padLeft(2, '0')}';
  return vuelta == valor ? valor : null;
}
```

3.a.3 — `onInit` pide los bloques solo en la rama de alumno, después de los días, y vigila el día activo (`:61-67`). Reemplazar esto:

```dart
    } else {
      _loadDays();
      _loadSecciones();
      _loadAssessments();
      _loadWeeklyLoad();
    }
  }
```

por esto:

```dart
    } else {
      _cargarDiasYBloques();
      _loadSecciones();
      _loadAssessments();
      _loadWeeklyLoad();
      // En un ciclo de más de 120 días la ventana va desde el lunes de la
      // semana activa (ventanaVisible): al cambiar de semana se pide la
      // nueva. Dentro de la misma semana, load no vuelve a pedir nada.
      _ventanaDeBloques = ever<int>(
        currentDayIndex,
        (_) => _cargarBloquesPropios(),
      );
    }
  }
```

3.a.4 — `reload` también (`:80`, dentro de la rama de alumno; el docente no cambia). Reemplazar esto:

```dart
      await Future.wait([_loadDays(), _loadSecciones(), _loadAssessments()]);
```

por esto:

```dart
      await Future.wait([
        _cargarDiasYBloques(),
        _loadSecciones(),
        _loadAssessments(),
      ]);
```

`load` es idempotente por ventana. `HomePage` llama a `reload()` cada vez que se vuelve a la pestaña: si la ventana no cambió, no sale ninguna petición; sin ciclo con fechas, si cambió la semana, sale la nueva.

3.a.5 — `onClose` apaga también el vigilante del día activo (`:84-88`). Reemplazar esto:

```dart
  @override
  void onClose() {
    _clockTimer?.cancel();
    super.onClose();
  }
```

por esto:

```dart
  @override
  void onClose() {
    _clockTimer?.cancel();
    _ventanaDeBloques?.dispose();
    super.onClose();
  }
```

3.a.6 — `_loadDays` arma cada día con `DaySchedule.fromJson`, que lee también `isoDate` (`:108-117`; el mismo `map` de `_loadTeacherDaysAndSessions`, más abajo, no se toca: el ancla lleva el comentario que sigue, que solo está en `_loadDays`). Reemplazar esto:

```dart
              (d) => DaySchedule(
                d['dayName'] as String,
                d['dateText'] as String,
                d['weekText'] as String,
              ),
            )
            .toList(),
      );

      // Intentar buscar el día actual por fecha
```

por esto:

```dart
              (d) => DaySchedule.fromJson(Map<String, dynamic>.from(d as Map)),
            )
            .toList(),
      );

      // Intentar buscar el día actual por fecha
```

Lo demás de `_loadDays` no cambia: sigue eligiendo el día de hoy como siempre. Un elemento que no es un objeto, o sin alguno de los tres textos, lanza como antes, y el `catch` de siempre lo anota.

3.a.7 — los miembros nuevos, entre `coursesForDay` y `previousDay` (`:339-342` hoy; `:381-384` tras 3.a.1 a 3.a.6, que suman cuarenta y dos líneas). Reemplazar esto:

```dart
    return courses;
  }

  void previousDay() {
```

por esto:

```dart
    return courses;
  }

  /// Los bloques propios que caen en [dia] (RF-BLQ-4): las ocurrencias que el
  /// servidor ya expandió, filtradas por fecha ([_caeEnElDia]).
  List<TimeBlockOccurrence> bloquesDelDia(DaySchedule dia) {
    final propias = _bloquesPropios;
    if (propias.isEmpty) return const <TimeBlockOccurrence>[];
    return propias.where((o) => _caeEnElDia(o.date, dia)).toList();
  }

  /// Los días cancelados de los bloques propios que caen en [dia] (RF-BLQ-5),
  /// con las horas de su regla y `moved: false`.
  ///
  /// El servidor no manda un día cancelado entre las ocurrencias (RS-BE-33),
  /// pero la regla trae la excepción. La grilla lo pinta tenue, con "Este día
  /// está cancelado", para que la alumna pueda tocarlo y devolverlo al patrón
  /// desde su hoja. Solo cuenta si la fecha sigue en el patrón (uno de sus
  /// días y dentro de su rango): una excepción que quedó fuera al editar la
  /// regla ya no se expande, y tampoco se pinta.
  List<TimeBlockOccurrence> bloquesCanceladosDelDia(DaySchedule dia) {
    final reglas = _reglasPropias;
    if (reglas.isEmpty) return const <TimeBlockOccurrence>[];
    return <TimeBlockOccurrence>[
      for (final regla in reglas)
        for (final excepcion in regla.exceptions)
          if (excepcion.status == 'cancelled' &&
              _enElPatron(regla, excepcion.date) &&
              _caeEnElDia(excepcion.date, dia))
            TimeBlockOccurrence(
              blockId: regla.id,
              title: regla.title,
              colorHex: regla.colorHex,
              date: excepcion.date,
              dayOfWeek: DateTime.parse(excepcion.date).weekday,
              startTime: regla.startTime,
              endTime: regla.endTime,
              moved: false,
            ),
    ];
  }

  /// La ventana de ocurrencias que pide el horario (RF-BLQ-7), como fechas
  /// planas `YYYY-MM-DD`.
  ///
  /// Es la del ciclo visible: del primer al último `isoDate` no nulo de
  /// [daysList], en el orden en que llegan. No se lee nada de `dateText` ni
  /// del ciclo del alumno: `dateText` no trae año, y adivinarlo era frágil.
  ///
  /// Si esa ventana pasa de los 120 días que acepta el servidor
  /// (`TIME_BLOCK_WINDOW_TOO_WIDE`; un ciclo de 16 semanas son 112), son 120
  /// días desde el lunes de la semana del día activo. Al cambiar de semana,
  /// [currentDayIndex] cambia y el `ever` de `onInit` pide la ventana nueva;
  /// dentro de la misma semana es la misma, y `load` no vuelve a pedir nada.
  ///
  /// Si ningún día trae `isoDate` ([daysList] vacío, o el ciclo sin semanas,
  /// que llega con `isoDate` null, `dateText` vacío y "Semana actual"), son
  /// las cuatro semanas de lunes a domingo alrededor de hoy en Lima: la
  /// pasada, la actual y las dos siguientes.
  ({String from, String to}) ventanaVisible() {
    final ciclo = _fechasDelCiclo();
    if (ciclo == null) {
      final desde = _lunesDeEstaSemana().subtract(const Duration(days: 7));
      final hasta = desde.add(const Duration(days: 27));
      return (from: _fechaPlana(desde), to: _fechaPlana(hasta));
    }
    final (primero, ultimo, activo) = ciclo;
    if (ultimo.difference(primero).inDays < _diasMaximosPorVentana) {
      return (from: _fechaPlana(primero), to: _fechaPlana(ultimo));
    }
    final desde = _lunesDe(activo);
    final hasta = desde.add(const Duration(days: _diasMaximosPorVentana - 1));
    return (from: _fechaPlana(desde), to: _fechaPlana(hasta));
  }

  /// Los días que cubre como mucho una ventana, contando los dos extremos: el
  /// tope del servidor (`TIME_BLOCK_WINDOW_TOO_WIDE`).
  static const int _diasMaximosPorVentana = 120;

  /// Si la fecha plana [iso] ("2026-09-21") es la de [dia] ([_fechaDelDia]).
  ///
  /// Compara por FECHA. El nombre del día no basta: [daysList] trae los siete
  /// días de CADA semana del ciclo, y una práctica del lunes 21 no es la del
  /// lunes 28.
  bool _caeEnElDia(String iso, DaySchedule dia) {
    final fecha = _fechaDelDia(dia);
    return fecha != null && iso == _fechaPlana(fecha);
  }

  /// La fecha de [dia] a medianoche UTC: su `isoDate`, la fecha exacta que
  /// manda `/schedule/me/sessions` (D1).
  ///
  /// Si el ciclo no tiene semanas, el backend manda los siete días con
  /// `isoDate` null (y `dateText` vacío, "Semana actual"): no hay fecha, y
  /// por el nombre saldrían los cuatro lunes de la ventana uno al lado del
  /// otro. Se toma ese día de la semana en la semana de hoy, que es lo que
  /// "Semana actual" dice. null si tampoco se reconoce el nombre del día.
  DateTime? _fechaDelDia(DaySchedule dia) {
    final propia = _fechaDeIso(dia.isoDate);
    if (propia != null) return propia;
    final numero = _numeroDeDia(dia.dayName);
    if (numero == null) return null;
    return _lunesDeEstaSemana().add(Duration(days: numero - 1));
  }

  /// Si [fecha] cae en uno de los días de [regla] y dentro de su rango.
  static bool _enElPatron(TimeBlockRule regla, String fecha) {
    final dia = DateTime.tryParse(fecha);
    if (dia == null) return false;
    return regla.daysOfWeek.contains(dia.weekday) &&
        fecha.compareTo(regla.startDate) >= 0 &&
        fecha.compareTo(regla.endDate) <= 0;
  }

  /// La fecha del primer `isoDate` de [daysList], la del último y la del día
  /// activo (la primera, si el activo no trae), o null si ningún día trae
  /// `isoDate`.
  (DateTime, DateTime, DateTime)? _fechasDelCiclo() {
    final dias = daysList;
    // Marcador null-aware (`?`): un día sin isoDate no entra. Con un
    // `if (… case final f?)` el analizador saca `use_null_aware_elements`.
    final fechas = <DateTime>[
      for (final dia in dias) ?_fechaDeIso(dia.isoDate),
    ];
    if (fechas.isEmpty) return null;
    var indice = currentDayIndex.value;
    if (indice < 0 || indice >= dias.length) indice = 0;
    final activo = _fechaDeIso(dias[indice].isoDate) ?? fechas.first;
    return (fechas.first, fechas.last, activo);
  }

  /// `"2026-09-21"` → el 21 de septiembre de 2026 a medianoche UTC, o null.
  /// En UTC para que restar días no tropiece con un cambio de hora del
  /// dispositivo.
  static DateTime? _fechaDeIso(String? iso) =>
      iso == null ? null : DateTime.tryParse('${iso}T00:00:00Z');

  /// El lunes de la semana de [fecha].
  static DateTime _lunesDe(DateTime fecha) =>
      fecha.subtract(Duration(days: fecha.weekday - 1));

  /// El lunes de la semana de hoy en Lima, a medianoche UTC. Los campos de
  /// [currentLimaTime] ya son la hora de pared de Lima (`_nowInLima`).
  DateTime _lunesDeEstaSemana() {
    final ahora = currentLimaTime.value;
    return _lunesDe(DateTime.utc(ahora.year, ahora.month, ahora.day));
  }

  /// Las ocurrencias que el servidor ya expandió, o vacío.
  ///
  /// Van en su propia lista y NUNCA en [_todasLasSecciones] (RF-BLQ-7): ese
  /// arreglo alimenta [colorPorCurso] y el marcado de evaluaciones de
  /// [coursesForDay], así que un bloque ahí dentro le quitaría un color de la
  /// paleta a un curso real y podría quedar marcado como evaluación por
  /// coincidir de nombre con una.
  ///
  /// Se leen del service y no se copian: leer `snapshot` dentro del `Obx` de
  /// la pantalla lo suscribe, y la grilla refleja sola lo que la alumna crea,
  /// edita o borra. Sin el service registrado no hay bloques y nada se cae.
  List<TimeBlockOccurrence> get _bloquesPropios {
    if (!Get.isRegistered<TimeBlocksService>()) {
      return const <TimeBlockOccurrence>[];
    }
    return TimeBlocksService.to.snapshot?.occurrences ??
        const <TimeBlockOccurrence>[];
  }

  /// Las reglas de la alumna, del service, o vacío. Como [_bloquesPropios], se
  /// leen y no se copian: un día que se cancela o vuelve al patrón se repinta
  /// solo.
  List<TimeBlockRule> get _reglasPropias {
    if (!Get.isRegistered<TimeBlocksService>()) {
      return const <TimeBlockRule>[];
    }
    return TimeBlocksService.to.blocks;
  }

  /// El `ever` de [onInit] sobre [currentDayIndex]: en un ciclo de más de 120
  /// días, pide la ventana de la semana nueva. Lo apaga [onClose].
  Worker? _ventanaDeBloques;

  /// Los días primero y los bloques después: la ventana sale de las fechas
  /// del ciclo ([ventanaVisible]), y sin días sería la de respaldo.
  Future<void> _cargarDiasYBloques() async {
    await _loadDays();
    await _cargarBloquesPropios();
  }

  /// Pide al service la [ventanaVisible]. Idempotente: si la ventana es la
  /// misma y ya está cargada, el service no vuelve a pedir nada. Nunca lanza.
  Future<void> _cargarBloquesPropios() {
    if (!Get.isRegistered<TimeBlocksService>()) return Future<void>.value();
    final ventana = ventanaVisible();
    return TimeBlocksService.to.load(from: ventana.from, to: ventana.to);
  }

  static String _fechaPlana(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Nombre de un día del horario → 1 (lunes) a 7 (domingo), o null. Tolera
  /// "Miercoles" y "Sabado" sin tilde, como `_weekDays` de la vista. Es una
  /// copia corta a propósito: la de `time_block_conflicts.dart` es privada de
  /// ese archivo.
  static int? _numeroDeDia(String nombre) {
    final limpio = nombre
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
    const dias = <String>[
      'lunes',
      'martes',
      'miercoles',
      'jueves',
      'viernes',
      'sabado',
      'domingo',
    ];
    final i = dias.indexOf(limpio);
    return i < 0 ? null : i + 1;
  }

  void previousDay() {
```

**Punto de control** (no se hace commit aquí):

```
cd "${REPO:?}"
"${FLUTTER:?}" test test/HU35_jeff/time_blocks_grilla_test.dart
```

Esperado: `+33 -13: Some tests failed.` Pasan las 11 de la Tarea 3, las 19 unitarias nuevas y las 3 de regresión de widget. Fallan las 13 de abajo, todas porque la vista todavía no pinta bloques propios, ni días cancelados, ni el domingo:

- Nueve fallan en un `expect` con `Actual: _TextWidgetFinder:<Found 0 widgets with text "…": []>`, donde el texto es `"PRÁCTICAS DE PRUEBA"`, `"PRÁCTICAS / TALLER DE PRUEBA"`, `"VOLUNTARIADO DE PRUEBA"` o `"Domingo"`.
- La del día cancelado falla en su primer `expect`, `findsNWidgets(2)`, con `Actual: _AncestorWidgetFinder:<Found 0 widgets with type "InkWell" that are ancestors of widgets with text "PRÁCTICAS DE PRUEBA": []>`.
- Las tres que miden el bloque propio (las dos del reparto y la del día movido) fallan antes de llegar a un `expect`, al pedir su rectángulo: `The finder "Found 0 widgets with type "InkWell" that are ancestors of widgets with text "PRÁCTICAS DE PRUEBA": []" (used in a call to "getTopLeft()") could not find any matching widgets.`

```
vista de día: el bloque propio lleva su nombre y su color, sin salón ni sección
el nombre de un bloque propio va entero aunque lleve una barra
vista semanal: el bloque propio sale en la columna de su día y solo ahí
vista semanal: los bloques son los de la semana del día activo
la vista semanal suma el domingo: siete columnas y su bloque se ve
vista de día: el bloque del domingo también se ve
vista de día: una clase y un bloque a la misma hora se parten el ancho y los dos reciben toques
vista semanal: también se parten la columna de su día
un día movido se pinta en su hora nueva, no en la del patrón
un día cancelado se pinta tenue y lo dice, con las horas de la regla, y no como ocurrencia
un bloque de la semana 10 del ciclo se ve al navegar hasta ella
si los bloques llegan después de pintar el horario, aparecen solos
vista semanal: si los bloques llegan después, también aparecen solos
```

En la salida del punto de control aparecen además diecinueve líneas de `debugPrint` que empiezan por `Error al cargar`; se explican en el Paso 4 y no son pruebas en rojo.

Si falla alguna unitaria, el error está en 3.a: no seguir a 3.b.

**3.b — La vista.** Doce reemplazos en `lib/pages/horario/horario.dart`, en este orden. Los números son los de hoy; cada reemplazo corre los de abajo, así que vale el texto.

3.b.1 — (`:9-10`) Reemplazar esto:

```dart
import 'horario_controller.dart';
import 'horario_list_view.dart';
```

por esto:

```dart
import 'horario_controller.dart';
import 'horario_layout.dart';
import 'horario_list_view.dart';
```

3.b.2 — (`:15-16`) Reemplazar esto:

```dart
import '../../services/attendance_risk_service.dart';
import '../../models/contacto_model.dart';
```

por esto:

```dart
import '../../services/attendance_risk_service.dart';
import '../../models/contacto_model.dart';
import '../../models/time_block_model.dart';
import '../../configs/course_colors.dart';
```

3.b.3 — `_weekDays` suma el domingo (`:186-194`). Reemplazar esto:

```dart
  List<DaySchedule> _weekDays(HorarioController controller) {
    const expected = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
    ];
```

por esto:

```dart
  /// Los días de la vista semanal, en orden fijo de lunes a domingo: la
  /// primera aparición de cada nombre en `daysList`, que es la primera semana
  /// del ciclo (a las clases les da igual, se repiten todas las semanas).
  ///
  /// El domingo entra con RF-BLQ-4: antes la lista llegaba hasta el sábado y
  /// un bloque propio de domingo se veía en la vista de día pero desaparecía
  /// aquí. Un horario sin domingo sigue saliendo con sus seis columnas.
  List<DaySchedule> _weekDays(HorarioController controller) {
    const expected = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
```

3.b.4 — y su respaldo, cuando ningún nombre coincide (`:207-209`). Reemplazar esto:

```dart
    if (days.isNotEmpty) return days;
    return controller.daysList.take(6).toList();
  }
```

por esto:

```dart
    if (days.isNotEmpty) return days;
    return controller.daysList.take(7).toList();
  }
```

3.b.5 — los ayudantes nuevos, justo antes de `_courseBlock`, y los dos parámetros nuevos de su firma (`:271-278`). Reemplazar esto:

```dart
  Widget _courseBlock({
    required BuildContext context,
    required HorarioController controller,
    required Map<String, dynamic> course,
    required double hourHeight,
    required double left,
    required double right,
    required bool compact,
```

por esto:

```dart
  /// El mapa con el que una ocurrencia propia entra a [_courseBlock].
  ///
  /// Reusa las claves que ya leen las clases (`curso`, `hora_inicio`,
  /// `hora_fin`) para no duplicar el dibujo del bloque, y agrega
  /// `bloquePropio` con la ocurrencia tipada: de ahí salen su color y, con
  /// RF-BLQ-5, la hoja de acciones. `diaCancelado` marca un día cancelado
  /// (ver [HorarioController.bloquesCanceladosDelDia]), que se pinta tenue y
  /// con [_diaCanceladoTexto].
  /// No lleva `idSeccion`, `codigoSeccion`, `salon` ni `color`: un bloque
  /// propio no tiene curso, sección ni salón.
  static Map<String, dynamic> _bloqueComoCurso(
    TimeBlockOccurrence ocurrencia, {
    bool cancelado = false,
  }) =>
      <String, dynamic>{
        'curso': ocurrencia.title,
        'hora_inicio': ocurrencia.startTime,
        'hora_fin': ocurrencia.endTime,
        'isEvaluation': false,
        'isAdvising': false,
        'bloquePropio': ocurrencia,
        'diaCancelado': cancelado,
      };

  /// El tramo de un bloque en minutos, leído de las mismas claves, con los
  /// mismos respaldos (`'07:00 am'`/`'09:00 am'` si falta la hora) y con el
  /// mismo [_timeToHours] que [_courseBlock]. Así el reparto y el dibujo
  /// nunca discrepan sobre dónde está un bloque.
  ({int inicio, int fin}) _tramoEnMinutos(Map<String, dynamic> course) => (
        inicio:
            (_timeToHours(course['hora_inicio'] as String? ?? '07:00 am') * 60)
                .round(),
        fin: (_timeToHours(course['hora_fin'] as String? ?? '09:00 am') * 60)
            .round(),
      );

  /// La opacidad de un día cancelado: se ve, se toca y se distingue de uno
  /// que sí va (RF-BLQ-5, D2).
  static const double _opacidadDiaCancelado = 0.4;

  /// Lo que dice un día cancelado debajo de su nombre (D2), en el lugar donde
  /// una clase lleva su salón o su sección. La prueba lo busca por el texto
  /// literal, que es el que fija la spec.
  static const String _diaCanceladoTexto = 'Este día está cancelado';

  /// Pone un bloque en su columna dentro de la pista que va de `left` a
  /// `right` (RF-BLQ-4): mide `1/columnas` del ancho y se alinea en la columna
  /// que le tocó. Con una sola columna el factor es 1 y la alineación la
  /// izquierda: el bloque de siempre, al píxel. Con [tenue], a
  /// [_opacidadDiaCancelado]: la opacidad no le quita los toques.
  ///
  /// Con [FractionallySizedBox] y no calculando `left`/`right` porque aquí no
  /// se conoce el ancho del día: en la vista semanal cada día es un
  /// [Expanded]. El hijo mide solo su parte, así que un toque en la otra
  /// columna le llega al bloque de al lado y no a este.
  static Widget _enSuColumna({
    required int columna,
    required int columnas,
    bool tenue = false,
    required Widget bloque,
  }) {
    final double eje =
        columnas <= 1 ? -1.0 : 2 * columna / (columnas - 1) - 1;
    return FractionallySizedBox(
      widthFactor: 1 / columnas,
      alignment: Alignment(eje, 0),
      child: tenue
          ? Opacity(opacity: _opacidadDiaCancelado, child: bloque)
          : bloque,
    );
  }

  /// El día que se llama como [dia] dentro de la semana del día activo.
  ///
  /// [_weekDays] arma la vista semanal con la primera semana del ciclo. Para
  /// las clases da igual, pero los bloques propios cambian de una semana a
  /// otra (un día cancelado, uno movido, uno fuera de sus fechas), así que se
  /// buscan en la semana que la alumna estaba viendo al girar el teléfono.
  /// `daysList` trae cada semana como siete días seguidos de lunes a domingo
  /// (`schedule.service.ts`), de ahí el `% 7`.
  static DaySchedule _mismoDiaEnLaSemanaActiva(
    HorarioController controller,
    DaySchedule dia,
  ) {
    final dias = controller.daysList;
    if (dias.isEmpty) return dia;
    final activo = math.min(
      math.max(controller.currentDayIndex.value, 0),
      dias.length - 1,
    );
    final lunes = activo - activo % 7;
    final nombre = dia.dayName.trim().toLowerCase();
    for (var i = lunes; i < lunes + 7 && i < dias.length; i++) {
      if (dias[i].dayName.trim().toLowerCase() == nombre) return dias[i];
    }
    return dia;
  }

  /// Los bloques de un día ya repartidos en columnas (RF-BLQ-4): las clases,
  /// los bloques propios y los días cancelados juntos, porque los propios
  /// chocan con las clases a propósito y sin reparto el de arriba taparía al
  /// de abajo y se comería sus toques. Las clases van primero, en su orden de
  /// siempre; los cancelados, al final.
  List<Widget> _bloquesRepartidos({
    required BuildContext context,
    required HorarioController controller,
    required List<Map<String, dynamic>> clases,
    required List<TimeBlockOccurrence> propios,
    required List<TimeBlockOccurrence> cancelados,
    required double hourHeight,
    required double left,
    required double right,
    required bool compact,
    required bool vistaDia,
    required double lineOffset,
  }) {
    final bloques = <Map<String, dynamic>>[
      ...clases,
      ...propios.map(_bloqueComoCurso),
      for (final o in cancelados) _bloqueComoCurso(o, cancelado: true),
    ];
    final slots = repartirEnColumnas(bloques.map(_tramoEnMinutos).toList());
    return <Widget>[
      for (var i = 0; i < bloques.length; i++)
        _courseBlock(
          context: context,
          controller: controller,
          course: bloques[i],
          hourHeight: hourHeight,
          left: left,
          right: right,
          columna: slots[i].columna,
          columnas: slots[i].columnas,
          compact: compact,
          vistaDia: vistaDia,
          lineOffset: lineOffset,
        ),
    ];
  }

  Widget _courseBlock({
    required BuildContext context,
    required HorarioController controller,
    required Map<String, dynamic> course,
    required double hourHeight,
    required double left,
    required double right,
    /// La columna del bloque dentro de su día (desde 0) y entre cuántas se
    /// reparte el ancho, según [repartirEnColumnas]. Por omisión 0 de 1: todo
    /// el ancho, como antes del reparto.
    int columna = 0,
    int columnas = 1,
    required bool compact,
```

3.b.6 — el nombre (`:289-294`). Reemplazar esto:

```dart
    String nombreStr = (course['curso'] as String? ?? 'CURSO').toUpperCase();
    if (nombreStr.contains(' / ')) {
      nombreStr = nombreStr.split(' / ').first.trim();
    } else if (nombreStr.contains('/')) {
      nombreStr = nombreStr.split('/').first.trim();
    }
```

por esto:

```dart
    // Un bloque propio de la alumna llega con su ocurrencia en `bloquePropio`
    // (ver [_bloqueComoCurso]). No tiene curso, sección ni salón. Si además
    // es un día cancelado, `diaCancelado` lo pinta tenue y lo dice.
    final bloquePropio = course['bloquePropio'] as TimeBlockOccurrence?;
    final esBloquePropio = bloquePropio != null;
    final diaCancelado = course['diaCancelado'] == true;

    String nombreStr = (course['curso'] as String? ?? 'CURSO').toUpperCase();
    // La barra separa el nombre bilingüe que manda el portal ("CURSO /
    // COURSE"). El nombre de un bloque propio lo escribió la alumna: va entero.
    if (!esBloquePropio && nombreStr.contains(' / ')) {
      nombreStr = nombreStr.split(' / ').first.trim();
    } else if (!esBloquePropio && nombreStr.contains('/')) {
      nombreStr = nombreStr.split('/').first.trim();
    }
```

3.b.7 — el color, las líneas de debajo del nombre y la columna (`:309-326`). Reemplazar esto:

```dart
    final courseColor =
        controller.colorPorCurso[course['idSeccion']?.toString()] ??
        _resolveScheduleColor(colorStr, colors);
    final badgeText = course['isAdvising'] == true
        ? 'ASESORIA'
        : isEvaluation
        ? 'EVAL ${course['evalSigla']}'
        : null;
    final titleFontSize = compact ? 9.5 : 13.5;
    final metaFontSize = compact ? 8.0 : 11.0;
    final horizontalPadding = compact ? 5.0 : 10.0;

    return Positioned(
      top: topPosition,
      left: left,
      right: right,
      height: heightVal,
      child: InkWell(
```

por esto:

```dart
    // El color de un bloque propio es el que eligió la alumna, y NO pasa por
    // [HorarioController.colorPorCurso]: ese reparte la paleta de doce entre
    // las secciones, y un bloque ahí dentro le quitaría el suyo a un curso.
    final courseColor = bloquePropio != null
        ? parseHexColor(bloquePropio.colorHex) ?? colors.outline
        : controller.colorPorCurso[course['idSeccion']?.toString()] ??
              _resolveScheduleColor(colorStr, colors);
    final badgeText = course['isAdvising'] == true
        ? 'ASESORIA'
        : isEvaluation
        ? 'EVAL ${course['evalSigla']}'
        : null;
    final titleFontSize = compact ? 9.5 : 13.5;
    final metaFontSize = compact ? 8.0 : 11.0;
    final horizontalPadding = compact ? 5.0 : 10.0;
    // Debajo del nombre: el salón en la vista de día y la sección en la
    // semanal ([blockMetaLines]). Un bloque propio no tiene ninguno de los dos
    // y va solo con su nombre; un día cancelado lleva en ese lugar
    // [_diaCanceladoTexto] (D2), con la misma regla de alto: si el bloque es
    // chico, no entra y se omite. Se decide aquí, y no dentro de
    // [blockMetaLines], para no cambiar el contrato que prueba
    // test/HU31_jeff/horario_bloque_contenido_test.dart.
    final lineasDebajo = diaCancelado
        ? blockMetaLines(
            vistaDia: vistaDia,
            compact: compact,
            height: heightVal,
            seccionLabel: _diaCanceladoTexto,
            aula: _diaCanceladoTexto,
          )
        : esBloquePropio
        ? const <String>[]
        : blockMetaLines(
            vistaDia: vistaDia,
            compact: compact,
            height: heightVal,
            seccionLabel: course['isAdvising'] == true
                ? (course['codigoSeccion']?.toString() ?? 'Asesoría')
                : "Sección: ${course['codigoSeccion'] ?? 'Sin sección'}",
            aula: aulaStr,
          );

    return Positioned(
      top: topPosition,
      left: left,
      right: right,
      height: heightVal,
      child: _enSuColumna(columna: columna, columnas: columnas, tenue: diaCancelado, bloque: InkWell(
```

El cuerpo del `InkWell` queda **exactamente igual**, sin reindentar. Pasa a ser el último argumento de `_enSuColumna` y se cierra con un paréntesis más en 3.b.9. Así el diff muestra solo lo que cambia y no doscientas líneas corridas dos espacios. No correr `dart format` sobre el archivo: hoy no está formateado, y el formateador tocaría líneas ajenas a esta tarea.

3.b.8 — el `for` de las líneas usa la lista ya decidida (`:487-495`). Reemplazar esto:

```dart
                      for (final linea in blockMetaLines(
                        vistaDia: vistaDia,
                        compact: compact,
                        height: heightVal,
                        seccionLabel: course['isAdvising'] == true
                            ? (course['codigoSeccion']?.toString() ?? 'Asesoría')
                            : "Sección: ${course['codigoSeccion'] ?? 'Sin sección'}",
                        aula: aulaStr,
                      )) ...[
```

por esto:

```dart
                      for (final linea in lineasDebajo) ...[
```

3.b.9 — el cierre de `_courseBlock` (el paréntesis de `_enSuColumna`) y el inicio de `_portraitGrid`, que lee los propios fuera de su `LayoutBuilder` (`:535-548`). Reemplazar esto:

```dart
            ],
          ),
        ),
      ),
    );
  }

  Widget _portraitGrid({
    required BuildContext context,
    required HorarioController controller,
    required DaySchedule activeDay,
    required bool isDark,
  }) {
    return LayoutBuilder(
```

por esto:

```dart
            ],
          ),
        ),
      )),
    );
  }

  Widget _portraitGrid({
    required BuildContext context,
    required HorarioController controller,
    required DaySchedule activeDay,
    required bool isDark,
  }) {
    // Los bloques propios se leen AQUÍ y no dentro del LayoutBuilder: su
    // builder corre al hacer el layout, fuera del Obx de [build], y una
    // lectura ahí no suscribe a nada. Leídos aquí, cuando el service trae o
    // recarga su ventana el Obx se reconstruye y la grilla los pinta sola.
    // Los días cancelados, por lo mismo.
    final propios = controller.bloquesDelDia(activeDay);
    final cancelados = controller.bloquesCanceladosDelDia(activeDay);
    return LayoutBuilder(
```

3.b.10 — la vista de día pinta clases y propios repartidos (`:582-594`). Reemplazar esto:

```dart
                ...courses.map(
                  (course) => _courseBlock(
                    context: context,
                    controller: controller,
                    course: course,
                    hourHeight: dynamicHourHeight,
                    left: 66,
                    right: 14,
                    compact: dynamicHourHeight < 35,
                    vistaDia: true,
                    lineOffset: vertLineOffset,
                  ),
                ),
```

por esto:

```dart
                ..._bloquesRepartidos(
                  context: context,
                  controller: controller,
                  clases: courses,
                  propios: propios,
                  cancelados: cancelados,
                  hourHeight: dynamicHourHeight,
                  left: 66,
                  right: 14,
                  compact: dynamicHourHeight < 35,
                  vistaDia: true,
                  lineOffset: vertLineOffset,
                ),
```

3.b.11 — la vista semanal lee los propios y los días cancelados de cada columna, en la semana del día activo, antes de su `LayoutBuilder` (`:630-633`). Reemplazar esto:

```dart
    final studentName = user == null ? '' : user.fullName.toUpperCase();
    final cycle = user?.currentCycle ?? '';

    return Container(
```

por esto:

```dart
    final studentName = user == null ? '' : user.fullName.toUpperCase();
    final cycle = user?.currentCycle ?? '';
    // Fuera del LayoutBuilder por lo mismo que en [_portraitGrid]: así el Obx
    // de [build] se entera cuando llegan o cambian los bloques propios.
    final propiosPorDia = <DaySchedule, List<TimeBlockOccurrence>>{
      for (final day in weekDays)
        day: controller.bloquesDelDia(
          _mismoDiaEnLaSemanaActiva(controller, day),
        ),
    };
    final canceladosPorDia = <DaySchedule, List<TimeBlockOccurrence>>{
      for (final day in weekDays)
        day: controller.bloquesCanceladosDelDia(
          _mismoDiaEnLaSemanaActiva(controller, day),
        ),
    };

    return Container(
```

3.b.12 — y los pinta repartidos (`:726-740`). Reemplazar esto:

```dart
                              ...controller
                                  .coursesForDay(day)
                                  .map(
                                    (course) => _courseBlock(
                                      context: context,
                                      controller: controller,
                                      course: course,
                                      hourHeight: hourH,
                                      left: 2,
                                      right: 2,
                                      compact: true,
                                      vistaDia: false,
                                      lineOffset: labelPad,
                                    ),
                                  ),
```

por esto:

```dart
                              ..._bloquesRepartidos(
                                context: context,
                                controller: controller,
                                clases: controller.coursesForDay(day),
                                propios: propiosPorDia[day] ??
                                    const <TimeBlockOccurrence>[],
                                cancelados: canceladosPorDia[day] ??
                                    const <TimeBlockOccurrence>[],
                                hourHeight: hourH,
                                left: 2,
                                right: 2,
                                compact: true,
                                vistaDia: false,
                                lineOffset: labelPad,
                              ),
```

Nada más cambia en `horario.dart`: ni `blockGeometry`, ni `blockMetaLines`, ni `_timeToHours`, ni el `onTap`, ni la cabecera de la vista de día. `_courseBlock` sigue recibiendo `left`/`right` de cada vista (66/14 y 2/2); lo nuevo es qué parte de esa pista ocupa y, para un día cancelado, su opacidad y su línea «Este día está cancelado».

- [ ] **Paso 4: Correr la prueba y ver que pasa**

```
cd "${REPO:?}"
"${FLUTTER:?}" test test/HU35_jeff/time_blocks_grilla_test.dart
```

Esperado: **PASS**, `+46: All tests passed!` (11 de la Tarea 3 y 35 nuevas: 19 unitarias y 16 de widget).

En la salida aparecen diecinueve líneas de `debugPrint` que empiezan por `Error al cargar`, todas con `"StorageService" not found`. No son pruebas en rojo. Diez salen del `onInit` real de las tres pruebas que crean el controller registrado (`dias`, `secciones`, `evaluaciones` y `carga semanal` de la alumna, dos veces: la de «al crearse…» y la del ciclo largo; `dias y sesiones del docente` y `evaluaciones del docente` del docente), y nueve de los tres `reload` de la prueba de la pestaña (`dias`, `secciones` y `evaluaciones`, tres veces). Esas cargas del horario usan el `ApiClient` propio del controller, que sin `StorageService` falla antes de abrir ninguna conexión, y el controller se traga el error como siempre.

- [ ] **Paso 5: Regresión del horario, suite completa y análisis**

`horario.dart` y `horario_controller.dart` son pantallas que ya existían, así que se corre todo lo que las toca y la suite entera:

```
cd "${REPO:?}"
"${FLUTTER:?}" test test/HU35_jeff/ test/HU31_jeff/
"${FLUTTER:?}" test
"${FLUTTER:?}" analyze
```

Esperado:
- `test/HU35_jeff/ test/HU31_jeff/` termina en `+172: All tests passed!` (las 120 de `HU35_jeff` —19 de la Tarea 1, 55 de la Tarea 2 y las 46 de este archivo— y las 52 de `HU31_jeff`). `HU31_jeff` cubre `blockGeometry` y `blockMetaLines`, que no cambian.
- La suite completa termina en `+694: All tests passed!` (las 574 de antes de la rama más 120). Tarda entre dos y tres minutos y parece colgada en `test/HU33_jeff/registro_service_test.dart` «caso 3: el plazo vencido…»: esa prueba espera de verdad los 120 s de `RegistroService.registroTimeout`. No es de esta tarea y no hay que tocarla.
- `analyze` da `7 issues found.`, la misma lista de la línea base de la Tarea 1: el `avoid_print` en `lib/main.dart:91`, tres `deprecated_member_use`, un `unnecessary_import` y dos `depend_on_referenced_packages`. Ninguno cae en `horario.dart`, `horario_controller.dart` ni `time_blocks_grilla_test.dart`.

El `// ignore: must_call_super` del doble del controller es el mismo recurso que ya usa `test/HU07_sam/calculadora_flujo_cajanegra_test.dart:36`; sin él, `analyze` sube a 8. Si aparece un issue nuevo, se corrige antes del commit. Si aparece uno que no se entiende, **PARAR** y reportarlo.

- [ ] **Paso 6: Anotar en el reporte la ventana y los textos**

Texto exacto para el reporte de la rama (la Tarea 8 lo reúne):

```
Tarea 4 (pintar los bloques en la grilla):
- Texto visible nuevo, el que fija la spec (D2): "Este día está cancelado",
  debajo del nombre de un día cancelado. El bloque propio muestra el nombre
  que escribió la alumna, en mayúsculas como los cursos; no lleva insignia,
  salón ni sección. La columna "Domingo" de la vista semanal usa el nombre que
  ya manda el backend.
- La ventana es la del ciclo visible, como pide RF-BLQ-7: del primer al último
  isoDate que manda /schedule/me/sessions (D1). La app ya no lee fechas de
  dateText ni del ciclo del alumno. Si esa ventana pasara de 120 días (el tope
  del servidor; un ciclo de 16 semanas son 112), se piden 120 días desde el
  lunes de la semana del día que se está viendo, y al cambiar de semana, los
  de la semana nueva. Si ningún día trae isoDate, las cuatro semanas
  alrededor de hoy. Hace falta el backend con isoDate: sin él, la app cae a
  esas cuatro semanas.
- Un día cancelado se pinta en su hora de siempre, con su nombre y su color a
  40 % de opacidad y "Este día está cancelado" debajo (D2). Se puede tocar
  para devolverlo al patrón (Tarea 6).
- La vista semanal pinta los bloques propios de la semana del día activo; las
  clases y las marcas de evaluación siguen saliendo como hoy, con la primera
  semana del ciclo (comportamiento previo, no se tocó).
```

- [ ] **Paso final: Commit**

```
cd "${REPO:?}"
test "$(git branch --show-current)" = feat/bloques-horario-fe || echo 'PARAR: rama equivocada'
git status --short
git add lib/pages/horario/horario.dart \
        lib/pages/horario/horario_controller.dart \
        test/HU35_jeff/time_blocks_grilla_test.dart
git commit -m "feat(time-blocks): bloques propios en la grilla, lado a lado y con domingo (RF-BLQ-4)

Cada día del horario lee su isoDate, la fecha exacta que manda
/schedule/me/sessions, y ninguna fecha sale ya de dateText. El horario pide
al TimeBlocksService la ventana del ciclo visible, del primer al último
isoDate, después de cargar los días, y pinta las ocurrencias en las dos
vistas, con el color y el nombre que eligió la alumna y sin salón ni sección.
Si el ciclo pasa de 120 días, pide 120 desde el lunes de la semana activa.
Los bloques van en su propia lista del controller y nunca en
_todasLasSecciones, para no quitarle color a ningún curso. Los días
cancelados salen de la regla y se pintan tenues, con \"Este día está
cancelado\".

Lo que coincide en el mismo tramo de un día se reparte el ancho con
repartirEnColumnas: cada bloque ocupa su columna dentro de la pista de
siempre, así que nadie tapa a nadie ni se come sus toques. Sin cruces, el
bloque mide lo mismo que antes, al píxel.

La vista semanal suma el domingo y busca los bloques propios en la semana
del día activo. Los propios se leen fuera de los LayoutBuilder para que el
Obx se entere cuando llegan o cambian."
git log -1 --format=%B | grep -qi '^co-authored-by:' && echo 'PARAR: el commit trae trailer'
```

Antes del `git add`, `git status --short` solo puede listar esos tres archivos; si lista otro, o sale un `PARAR`, se detiene aquí. Sin trailer `Co-Authored-By`: el autor ya está configurado en git.
### Tarea 5: El formulario

> Una versión anterior de esta tarea se verificó en una copia descartable del repo (en `/tmp`), encima **solo** de las Tareas 1 y 2 de entonces: Paso 2 falló por las razones que dice, Paso 4 dio `+19`, `test/HU35_jeff/` (Tareas 1, 2 y 5) `+89` y `flutter analyze` quedó en los 7 issues de la línea base. Una revisión posterior la aplicó en orden, sobre las Tareas 1 a 4: las anclas 3d a 3g aparecieron literales y una sola vez cada una, y `test/HU35_jeff/ test/HU31_jeff/` dio `+177`. Después, la revisión sumó dos pruebas a esta tarea (las clases del horario sin inyectar) y pruebas a las Tareas 1, 2 y 4, y cambió `crucesDeBloque` (fechas). Las cifras de abajo (`+21` en el Paso 4 y `+191` en el Paso 5) se midieron después de las decisiones finales (ver «Cifras de las pruebas» en las restricciones globales). El worktree real no se tocó.

**Requisitos:** RF-BLQ-1 y RF-BLQ-2 completos, y el lado de pantalla de RF-BLQ-3 (el aviso antes de guardar).

**Archivos:**
- Crear: `lib/pages/time_blocks/time_block_form_controller.dart`
- Crear: `lib/pages/time_blocks/time_block_form_binding.dart`
- Crear: `lib/pages/time_blocks/time_block_form_page.dart`
- Modificar: `lib/main.dart:50-51` (imports) y `lib/main.dart:229-234` (final de `getPages`). Son los números de hoy; la Tarea 1 mete un import en `:15` y cinco líneas junto a los `Get.put`, así que al llegar aquí estarán en `:51-52` y `:235-240`. Guiarse por el texto del ancla, no por el número.
- Modificar: `lib/pages/horario/horario.dart:18-19` (cabecera de `HorarioPage`) y `lib/pages/horario/horario.dart:815-819` (el `return Scaffold(` de `build()`). Son los números de hoy; la Tarea 4 los corre; guiarse por el ancla.
- Test: `test/HU35_jeff/time_blocks_form_test.dart`

**Interfaces:**
- Consume:
  - De la Tarea 1, `lib/services/time_blocks_service.dart`:
    - `TimeBlocksService({ApiClient? apiClient})`, con el mismo patrón que `AcademicRecordService`.
    - `static TimeBlocksService get to`
    - `static const String genericErrorMessage` (`'No se pudo guardar tu bloque. Inténtalo de nuevo.'`)
    - `List<TimeBlockRule> get blocks` (ya filtrado por el alumno actual)
    - `Future<TimeBlockRule> create(TimeBlockInput input)` y `Future<TimeBlockRule> update(int id, TimeBlockInput input)`. Las dos envuelven cualquier fallo en `TimeBlocksFailure` y, si salen bien, recargan la ventana del horario antes de volver.
    - `const TimeBlockInput({required String title, required String colorHex, required List<int> daysOfWeek, required String startTime, required String endTime, required String startDate, required String endDate})`, con campos del mismo nombre.
    - `const TimeBlocksFailure(this.message)`: constructor posicional, con `final String message`.
  - De la Tarea 1, `lib/models/time_block_model.dart`: `const TimeBlockRule({required int id, required String title, required String colorHex, required List<int> daysOfWeek, required String startTime, required String endTime, required String startDate, required String endDate, required List<TimeBlockException> exceptions})` y el tipo `TimeBlockException`.
  - De la Tarea 2:
    - `String? validarDias(Set<int> dias)`
    - `String? validarHoras(String? inicio, String? fin)`
    - `String? validarFormulario({required String nombre, required Set<int> dias, required String? inicio, required String? fin, required String? desde, required String? hasta})`
    - `class Cruce`
    - `List<Cruce> crucesDeBloque({required Set<int> dias, required String inicio, required String fin, required List<Map<String, dynamic>> secciones, required List<TimeBlockRule> bloques, int? ignorarBloqueId, String? desde, String? hasta})`: con `desde`/`hasta` del bloque que se guarda, un bloque propio de otro rango de fechas no cruza
    - `String mensajeDeCruce(List<Cruce> cruces)`
  - Del repo:
    - `kCoursePalette` (`lib/configs/course_colors.dart:14-27`, doce colores).
    - `HorarioController.uniqueEnrolledCourses` (`lib/pages/horario/horario_controller.dart:405-432`). Devuelve las secciones **sin aplanar**, con su lista `horarios`, sin asesorías y una por `idSeccion`: es la forma que pide `crucesDeBloque`. La Tarea 2 anticipaba que habría que exponer `_todasLasSecciones`; no hace falta, y el controller del horario no se toca. Es un getter, así que un doble de `HorarioController` lo puede sobreescribir: la prueba lo hace para ejercitar `seccionesDelHorario()` sin inyectar nada.
    - `HorarioController.isListView` (`:26`) y `toggleListView()` (`:360-362`).
    - `HorarioPage._scheduleOrientations` y `HorarioPage._portraitOnly` (`lib/pages/horario/horario.dart:83-90`), y `SystemChrome`, ya importado en `horario.dart:4`. Son las que usa el toque de un curso (`horario.dart:442-444`) para cumplir "Schedule-only rotation" (`specs/features/schedule/schedule.spec.md:36`).
    - `AuthService.to.currentUser?.isTeacher`. `AuthService` ya está importado en `horario.dart:14` y `Get` en `:5`: no hacen falta imports nuevos en `horario.dart`.
    - `MaterialTheme.pageBg/cardBg/borderColor/textPrimary/textMuted/primaryColor/primaryDark` (`lib/configs/themes.dart`).
    - `MyApp({required String initialRoute})` (`lib/main.dart:95-97`).
  - Antes de empezar, confirmar que las Tareas 1 y 2 dejaron esas firmas:
    ```bash
    cd "${REPO:?}"
    grep -n "TimeBlocksService({\|static TimeBlocksService get to\|genericErrorMessage =\|class TimeBlockInput\|class TimeBlocksFailure\|TimeBlocksFailure(this\|get blocks\|Future<TimeBlockRule> create\|Future<TimeBlockRule> update" lib/services/time_blocks_service.dart
    grep -n "^class TimeBlockRule\|^class TimeBlockException\|const TimeBlockRule({" lib/models/time_block_model.dart
    grep -n "^String? validar\|^List<Cruce> crucesDeBloque\|^String mensajeDeCruce\|^class Cruce" lib/pages/time_blocks/time_block_validators.dart lib/pages/time_blocks/time_block_conflicts.dart
    ```
    Esperado: 9 líneas en el primero, 3 en el segundo y 8 en el tercero (`validarNombre`, `validarDias`, `validarHoras`, `validarFechas`, `validarFormulario`, `class Cruce`, `crucesDeBloque`, `mensajeDeCruce`). Si falta alguna, o una firma no coincide (por ejemplo, un `TimeBlocksFailure` con parámetro nombrado), **PARAR** y reportarlo. No se toca la Tarea 1 ni la 2 desde aquí.
- Produce:
  - Ruta `'/bloque'` en `lib/main.dart`: `GetPage(name: '/bloque', page: () => const TimeBlockFormPage(), binding: TimeBlockFormBinding())`.
    - Sin argumentos, crea un bloque.
    - Con `Get.toNamed('/bloque', arguments: bloque)`, donde `bloque` es un `TimeBlockRule`, edita ese bloque. Tiene que ser la **regla**, no una `TimeBlockOccurrence`: la Tarea 6 la busca en `TimeBlocksService.to.blocks` por `blockId`.
    - Al guardar, la pantalla se cierra con `Navigator.of(context).pop(true)`, así que el `await Get.toNamed('/bloque', …)` de quien la abrió devuelve `true`. Si se sale sin guardar, devuelve `null`. Mientras guarda no se puede salir.
  - `class TimeBlockFormBinding extends Bindings`, que hace `Get.lazyPut(() => TimeBlockFormController())`.
  - `class TimeBlockFormController extends GetxController`:
    - Constructor: `TimeBlockFormController({TimeBlocksService? service, List<Map<String, dynamic>> Function()? secciones})`.
    - Campos: `nombre` (`TextEditingController`), `colorHex` (`RxString`), `dias` (`RxSet<int>`, 1 = lunes … 7 = domingo), `inicio` y `fin` (`Rxn<TimeOfDay>`), `desde` y `hasta` (`Rxn<DateTime>`), `guardando` (`RxBool`), `errorMessage` (`RxnString`).
    - Getters: `TimeBlocksService get service`, `TimeBlockRule? get bloque`, `bool get editando`, y `String? get inicioTexto`, `finTexto`, `desdeTexto`, `hastaTexto` (`"HH:MM"` / `"YYYY-MM-DD"`).
    - Métodos: `bool validar()`, `List<Cruce> cruces()`, `Future<bool> guardar()`.
    - Estáticos: `static const String errorGenerico` (igual a `TimeBlocksService.genericErrorMessage`), `static List<Map<String, dynamic>> seccionesDelHorario()`, `static String hexDeColor(Color color)`, `static String fmtHora(TimeOfDay t)`, `static String fmtFecha(DateTime d)`, `static TimeOfDay? horaDeTexto(String? hhmm)`, `static DateTime? fechaDeTexto(String? yyyymmdd)`.
  - `class TimeBlockFormPage extends StatelessWidget`:
    - Textos: `tituloCrear`, `tituloEditar`, `guardarLabel`, `cruceTitulo`, `cruceVolver`, `cruceGuardar`, y los de los selectores de Flutter en español (D7): `pickerHoraTitulo` (`'Elige la hora'`), `pickerFechaTitulo` (`'Elige la fecha'`), `pickerCancelar` (`'Cancelar'`) y `pickerAceptar` (`'Aceptar'`), todos `static const String`. La Tarea 6 reusa los de la hora en su diálogo.
    - Keys: `nombreKey`, `diasKey`, `horaInicioKey`, `horaFinKey`, `desdeKey`, `hastaKey`, `guardarKey`, `avisoCruceKey` (`static const Key`) y `static Key colorKey(String hex)`.
    - `static const List<String> diasLabels`.
  - `class TimeBlockPickerField extends StatelessWidget` con `const TimeBlockPickerField({Key? key, required String texto, required IconData icono, required Brightness brightness, required VoidCallback onTap})`. Es pública porque la Tarea 6 la reusa para cambiar la hora de un día.
  - En `HorarioPage`, `static const Key agregarBloqueKey = Key('horario-agregar-bloque')` y el botón `FloatingActionButton.small` que abre `'/bloque'`. Aparece solo si se cumplen las tres condiciones: el usuario es alumno, la pantalla está en vertical y no está abierta la lista de chats. Antes de abrir el formulario fija la orientación en vertical y, al volver, devuelve la rotación del horario. Las dos últimas condiciones no están en RF-BLQ-1 («en la pantalla de horario, y solo para alumnos»): van al reporte como decisión del dueño (Paso 7 y punto 4 del reporte de la Tarea 8).

- [ ] **Paso 1: Escribir la prueba que falla**

Crear `test/HU35_jeff/time_blocks_form_test.dart` (la carpeta ya existe desde la Tarea 1) con este contenido:

```dart
// test/HU35_jeff/time_blocks_form_test.dart
//
// WIDGET — HU35 (bloques de horario propios): el formulario de un bloque
// (RF-BLQ-2), su aviso de cruce antes de guardar (RF-BLQ-3) y el botón que lo
// abre desde el horario, solo para alumnos (RF-BLQ-1).
// Pantallas: lib/pages/time_blocks/time_block_form_page.dart y el botón de
// lib/pages/horario/horario.dart.
//
// Todos los datos son inventados; el repo es público. La alumna es la
// 20230001, el docente es "docente.test" (el mismo de test/HU34_jeff) y el
// curso es "CURSO DE PRUEBA A", sección 801: nada sale del portal.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/main.dart';
import 'package:ulima_plus/models/time_block_model.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/horario/horario.dart';
import 'package:ulima_plus/pages/horario/horario_controller.dart';
import 'package:ulima_plus/pages/time_blocks/time_block_conflicts.dart';
import 'package:ulima_plus/pages/time_blocks/time_block_form_binding.dart';
import 'package:ulima_plus/pages/time_blocks/time_block_form_controller.dart';
import 'package:ulima_plus/pages/time_blocks/time_block_form_page.dart';
import 'package:ulima_plus/pages/time_blocks/time_block_validators.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/time_blocks_service.dart';

UserModel _alumna() => UserModel(
      code: '20230001',
      firstName: 'Alumna',
      lastName: 'De Prueba',
      email: 'test@aloe.ulima.edu.pe',
      role: 'student',
      currentCycle: '2026-2',
      setupComplete: true,
    );

UserModel _docente() => UserModel(
      code: 'docente.test',
      firstName: 'Docente',
      lastName: 'De Prueba',
      email: 'docente.test@ulima.edu.pe',
      role: 'teacher',
      teacherLabel: 'Profesor',
      currentCycle: '2026-2',
      setupComplete: true,
    );

class _FakeAuthService extends AuthService {
  _FakeAuthService(UserModel? user) : userRx = Rx<UserModel?>(user);

  final Rx<UserModel?> userRx;

  @override
  UserModel? get currentUser => userRx.value;

  @override
  Rx<UserModel?> get currentUserRx => userRx;

  @override
  Future<void> refreshCurrentUser() async {}
}

/// Cliente que no sale a la red: si algo del formulario lo llamara, la prueba
/// revienta en vez de pegarle a un backend.
class _ApiSinRed extends ApiClient {
  _ApiSinRed() : super(configuredBaseUrl: 'http://test');

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    String? token,
    Map<String, String?> query = const {},
    bool suppressSessionExpiry = false,
  }) =>
      throw StateError('El formulario no debe pedir $path');
}

/// Doble del service: guarda lo que le piden y responde sin HTTP.
class _FakeTimeBlocksService extends TimeBlocksService {
  _FakeTimeBlocksService({List<TimeBlockRule> bloques = const []})
      : _bloques = bloques,
        super(apiClient: _ApiSinRed());

  final List<TimeBlockRule> _bloques;
  final creados = <TimeBlockInput>[];
  final editados = <({int id, TimeBlockInput input})>[];

  /// Si no es null, `create` y `update` lo lanzan.
  Object? falla;

  /// Si no es null, `create` se queda esperando a que la prueba lo complete:
  /// así se ve el formulario A MITAD del guardado.
  Completer<void>? espera;

  @override
  List<TimeBlockRule> get blocks => _bloques;

  @override
  Future<TimeBlockRule> create(TimeBlockInput input) async {
    if (espera != null) await espera!.future;
    if (falla != null) throw falla!;
    creados.add(input);
    return _reglaDe(99, input);
  }

  @override
  Future<TimeBlockRule> update(int id, TimeBlockInput input) async {
    if (falla != null) throw falla!;
    editados.add((id: id, input: input));
    return _reglaDe(id, input);
  }
}

TimeBlockRule _reglaDe(int id, TimeBlockInput i) => TimeBlockRule(
      id: id,
      title: i.title,
      colorHex: i.colorHex,
      daysOfWeek: i.daysOfWeek,
      startTime: i.startTime,
      endTime: i.endTime,
      startDate: i.startDate,
      endDate: i.endDate,
      exceptions: const <TimeBlockException>[],
    );

/// Bloque inventado: lunes y miércoles de 14:00 a 18:00.
TimeBlockRule _practicas() => const TimeBlockRule(
      id: 12,
      title: 'Prácticas',
      colorHex: '#27AE60',
      daysOfWeek: <int>[1, 3],
      startTime: '14:00',
      endTime: '18:00',
      startDate: '2026-09-01',
      endDate: '2026-12-15',
      exceptions: <TimeBlockException>[],
    );

/// Una clase inventada con la forma de `/schedule/me/sessions`: martes de
/// 4:00 pm a 6:00 pm.
Map<String, dynamic> _claseDelMartes() => <String, dynamic>{
      'idSeccion': '801',
      'codigoSeccion': '801',
      'curso': 'CURSO DE PRUEBA A',
      'horarios': <dynamic>[
        <String, dynamic>{
          'dia': 'Martes',
          'inicio': '16:00:00',
          'hora_inicio': '4:00 pm',
          'fin': '18:00:00',
          'hora_fin': '6:00 pm',
          'salon': 'A-101',
          'color': '#2F80ED',
        },
      ],
    };

/// El horario en pantalla, con las clases que se le pasen. Es lo único que
/// une el formulario con las clases de verdad: `seccionesDelHorario()` lee
/// `uniqueEnrolledCourses` del `HorarioController` registrado. Sin su
/// `onInit` (reloj y carga remota), como en las pruebas de la grilla.
class _HorarioConClases extends HorarioController {
  _HorarioConClases(this.clases);

  final List<Map<String, dynamic>> clases;

  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  List<Map<String, dynamic>> get uniqueEnrolledCourses => clases;
}

/// App mínima: una pantalla de partida y la ruta /bloque con su binding REAL.
Widget _app() => GetMaterialApp(
      initialRoute: '/inicio',
      getPages: [
        GetPage(
          name: '/inicio',
          page: () => const Scaffold(body: Text('INICIO')),
        ),
        GetPage(
          name: '/bloque',
          page: () => const TimeBlockFormPage(),
          binding: TimeBlockFormBinding(),
        ),
      ],
    );

/// Pantalla de un iPhone SE en vertical (375 x 667). La superficie por defecto
/// de las pruebas es 800 x 600, o sea HORIZONTAL, y ahí el horario esconde el
/// botón de agregar: una prueba de "el docente no lo ve" pasaría por la razón
/// equivocada. El ancho chico, además, pone a prueba los siete días en fila.
void _telefonoVertical(WidgetTester tester) {
  tester.view.physicalSize = const Size(750, 1334);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

/// Registra los dobles, monta la app y abre el formulario (con o sin bloque).
Future<_FakeTimeBlocksService> _abrirFormulario(
  WidgetTester tester, {
  TimeBlockRule? bloque,
  List<TimeBlockRule> bloques = const [],
  List<Map<String, dynamic>> secciones = const [],
}) async {
  _telefonoVertical(tester);
  Get.put<AuthService>(_FakeAuthService(_alumna()));
  final service = _FakeTimeBlocksService(bloques: bloques);
  Get.put<TimeBlocksService>(service);
  await tester.pumpWidget(_app());
  await tester.pumpAndSettle();
  // Si la prueba pide clases, el controller se registra antes de navegar con
  // esas clases: el binding usa `lazyPut`, que no pisa lo ya registrado. Sin
  // bloque en los argumentos, crear así es idéntico a crear desde la ruta.
  if (secciones.isNotEmpty) {
    Get.put<TimeBlockFormController>(
      TimeBlockFormController(secciones: () => secciones),
    );
  }
  Get.toNamed<dynamic>('/bloque', arguments: bloque);
  await tester.pumpAndSettle();
  return service;
}

TimeBlockFormController get _c => Get.find<TimeBlockFormController>();

/// Llena lo que el alumno escribe o toca en widgets PROPIOS (nombre, color y
/// días). Las horas y las fechas se fijan en el controller: los pickers son de
/// Flutter (`showTimePicker`, `showDatePicker`) y su dial no es lo que se prueba.
Future<void> _llenar(
  WidgetTester tester, {
  String nombre = 'Prácticas',
  List<String> dias = const ['Ma'],
  TimeOfDay inicio = const TimeOfDay(hour: 14, minute: 0),
  TimeOfDay fin = const TimeOfDay(hour: 18, minute: 0),
}) async {
  await tester.enterText(find.byKey(TimeBlockFormPage.nombreKey), nombre);
  await tester.tap(find.byKey(TimeBlockFormPage.colorKey('#EB5757')));
  for (final d in dias) {
    // Un pump por toque: el SegmentedButton entrega el conjunto COMPLETO y
    // tiene que haberse repintado con el anterior antes del siguiente toque.
    await tester.tap(find.text(d));
    await tester.pump();
  }
  _c.inicio.value = inicio;
  _c.fin.value = fin;
  _c.desde.value = DateTime(2026, 9, 1);
  _c.hasta.value = DateTime(2026, 12, 15);
  await tester.pump();
}

Future<void> _guardar(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(TimeBlockFormPage.guardarKey));
  await tester.tap(find.byKey(TimeBlockFormPage.guardarKey));
  await tester.pumpAndSettle();
}

/// `HorarioPage` hace `Get.put(HorarioController())` dentro de `build`, y ese
/// controller arranca un `Timer.periodic` de un minuto. Hay que desmontar el
/// árbol y borrarlo ANTES de que termine la prueba o el binding falla con
/// "A Timer is still pending even after the widget tree was disposed".
Future<void> _desmontarHorario(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await Get.delete<HorarioController>(force: true);
}

/// Lo que la app le pidió a `SystemChrome.setPreferredOrientations`, en orden.
final _orientaciones = <List<Object?>>[];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.reset();
    // Doble del canal de plataforma. Sin él, `setPreferredOrientations` espera
    // una respuesta que en la prueba no llega nunca y el botón del horario se
    // queda sin navegar. Responde al toque y anota las orientaciones pedidas.
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
    Get.reset();
  });

  group('WIDGET · ruta /bloque (RF-BLQ-1)', () {
    testWidgets('la ruta /bloque vive en main.dart con su binding',
        (tester) async {
      // Monta la app REAL: lo que se blinda es la cadena GetPage → binding →
      // pantalla. Con una tabla de rutas escrita en la prueba, la ruta podría
      // faltar en main.dart y nadie se enteraría hasta abrir la app.
      Get.put<AuthService>(_FakeAuthService(_alumna()));
      Get.put<TimeBlocksService>(_FakeTimeBlocksService());

      await tester.pumpWidget(const MyApp(initialRoute: '/bloque'));
      await tester.pumpAndSettle();

      expect(find.byType(TimeBlockFormPage), findsOneWidget);
      expect(Get.currentRoute, '/bloque');
      expect(find.text(TimeBlockFormPage.tituloCrear), findsOneWidget);
    });
  });

  group('WIDGET · formulario de un bloque (RF-BLQ-2)', () {
    testWidgets('se abre vacío, en orden, y crea el bloque con el contrato',
        (tester) async {
      final service = await _abrirFormulario(tester);

      expect(find.text(TimeBlockFormPage.tituloCrear), findsOneWidget);
      expect(_c.nombre.text, isEmpty);
      expect(_c.dias, isEmpty);
      expect(_c.inicio.value, isNull);
      expect(_c.desde.value, isNull);
      // Los doce colores de la paleta de cursos, como círculos.
      for (final color in const [
        '#2F80ED', '#27AE60', '#EB5757', '#9B51E0', '#EC4899', '#F2994A',
        '#00B8A9', '#F2C94C', '#00A2C7', '#7CB518', '#8B6D5C', '#5B5BD6',
      ]) {
        expect(find.byKey(TimeBlockFormPage.colorKey(color)), findsOneWidget);
      }
      // Los siete días, de lunes a domingo.
      for (final d in TimeBlockFormPage.diasLabels) {
        expect(find.text(d), findsOneWidget);
      }
      // Orden de la spec: nombre, color, días, horas, desde y hasta.
      final ys = [
        TimeBlockFormPage.nombreKey,
        TimeBlockFormPage.colorKey('#2F80ED'),
        TimeBlockFormPage.diasKey,
        TimeBlockFormPage.horaInicioKey,
        TimeBlockFormPage.desdeKey,
      ].map((k) => tester.getTopLeft(find.byKey(k)).dy).toList();
      expect(ys, orderedEquals([...ys]..sort()));

      await _llenar(tester, nombre: '  Prácticas  ', dias: const ['Mi', 'Lu']);
      await _guardar(tester);

      expect(service.creados, hasLength(1));
      final enviado = service.creados.single;
      expect(enviado.title, 'Prácticas');
      expect(enviado.colorHex, '#EB5757');
      expect(enviado.daysOfWeek, [1, 3]); // 1 es lunes, como en el servidor
      expect(enviado.startTime, '14:00');
      expect(enviado.endTime, '18:00');
      expect(enviado.startDate, '2026-09-01');
      expect(enviado.endDate, '2026-12-15');
      expect(service.editados, isEmpty);
      // Guardó y volvió al horario.
      expect(Get.currentRoute, '/inicio');
    });

    testWidgets('se abre con un bloque, trae sus valores y edita ese id',
        (tester) async {
      final service = await _abrirFormulario(
        tester,
        bloque: _practicas(),
        // El mismo bloque está en la lista del service: al editar no puede
        // cruzarse consigo mismo, así que NO debe salir el aviso.
        bloques: [_practicas()],
      );

      expect(find.text(TimeBlockFormPage.tituloEditar), findsOneWidget);
      expect(_c.nombre.text, 'Prácticas');
      expect(_c.colorHex.value, '#27AE60');
      expect(_c.dias, {1, 3});
      expect(_c.inicioTexto, '14:00');
      expect(_c.finTexto, '18:00');
      expect(_c.desdeTexto, '2026-09-01');
      expect(_c.hastaTexto, '2026-12-15');
      expect(find.text('14:00'), findsOneWidget);
      expect(find.text('2026-12-15'), findsOneWidget);

      _c.fin.value = const TimeOfDay(hour: 19, minute: 0);
      await tester.pump();
      await _guardar(tester);

      expect(find.byKey(TimeBlockFormPage.avisoCruceKey), findsNothing);
      expect(service.creados, isEmpty);
      expect(service.editados, hasLength(1));
      expect(service.editados.single.id, 12);
      expect(service.editados.single.input.endTime, '19:00');
      expect(Get.currentRoute, '/inicio');
    });

    testWidgets('sin días marcados no guarda y dice por qué', (tester) async {
      final service = await _abrirFormulario(tester);
      await _llenar(tester, dias: const []);
      await _guardar(tester);

      expect(find.text(validarDias(<int>{})!), findsOneWidget);
      expect(service.creados, isEmpty);
      expect(Get.currentRoute, '/bloque');
    });

    testWidgets('hora de fin antes de la de inicio: no guarda y dice por qué',
        (tester) async {
      final service = await _abrirFormulario(tester);
      await _llenar(
        tester,
        inicio: const TimeOfDay(hour: 18, minute: 0),
        fin: const TimeOfDay(hour: 16, minute: 0),
      );
      await _guardar(tester);

      expect(find.text(validarHoras('18:00', '16:00')!), findsOneWidget);
      expect(service.creados, isEmpty);
      expect(Get.currentRoute, '/bloque');
    });

    testWidgets('fuera de 7 am–10 pm: no guarda y dice por qué', (tester) async {
      final service = await _abrirFormulario(tester);
      await _llenar(
        tester,
        inicio: const TimeOfDay(hour: 6, minute: 0),
        fin: const TimeOfDay(hour: 8, minute: 0),
      );
      await _guardar(tester);

      expect(find.text(validarHoras('06:00', '08:00')!), findsOneWidget);
      expect(service.creados, isEmpty);

      // Y por arriba: terminar a las 22:30 tampoco entra en la grilla.
      _c.inicio.value = const TimeOfDay(hour: 20, minute: 0);
      _c.fin.value = const TimeOfDay(hour: 22, minute: 30);
      await tester.pump();
      await _guardar(tester);

      expect(find.text(validarHoras('20:00', '22:30')!), findsOneWidget);
      expect(service.creados, isEmpty);
      expect(Get.currentRoute, '/bloque');
    });

    testWidgets('un error del servidor se muestra tal cual llega',
        (tester) async {
      final service = await _abrirFormulario(tester);
      service.falla = TimeBlocksFailure('Mensaje inventado del servidor.');
      await _llenar(tester);
      await _guardar(tester);

      expect(find.text('Mensaje inventado del servidor.'), findsOneWidget);
      expect(Get.currentRoute, '/bloque');
    });

    testWidgets('un fallo sin mensaje del servidor no deja el botón mudo',
        (tester) async {
      final service = await _abrirFormulario(tester);
      service.falla = StateError('inesperado');
      await _llenar(tester);
      await _guardar(tester);

      expect(find.text(TimeBlockFormController.errorGenerico), findsOneWidget);
      expect(Get.currentRoute, '/bloque');
      // El botón vuelve a estar disponible para reintentar.
      final boton = tester.widget<ElevatedButton>(
        find.byKey(TimeBlockFormPage.guardarKey),
      );
      expect(boton.onPressed, isNotNull);
    });

    testWidgets('mientras guarda no deja salir, y al terminar vuelve solo',
        (tester) async {
      final service = await _abrirFormulario(tester);
      service.espera = Completer<void>();
      await _llenar(tester);
      await tester.ensureVisible(find.byKey(TimeBlockFormPage.guardarKey));
      await tester.tap(find.byKey(TimeBlockFormPage.guardarKey));
      // Sin pumpAndSettle: el indicador de "guardando" gira sin fin.
      await tester.pump();

      final boton = tester.widget<ElevatedButton>(
        find.byKey(TimeBlockFormPage.guardarKey),
      );
      expect(boton.onPressed, isNull); // no se puede tocar dos veces

      // La flecha de la barra intenta salir a mitad del guardado: no sale.
      await tester.tap(find.byType(BackButton));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(Get.currentRoute, '/bloque');

      service.espera!.complete();
      await tester.pumpAndSettle();

      expect(service.creados, hasLength(1));
      expect(Get.currentRoute, '/inicio');
    });

    testWidgets('las horas y las fechas se eligen con los pickers de Flutter',
        (tester) async {
      await _abrirFormulario(tester);

      await tester.tap(find.byKey(TimeBlockFormPage.horaInicioKey));
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsOneWidget);
      // El título y los botones van en español (D7), no los de Flutter.
      expect(find.text(TimeBlockFormPage.pickerHoraTitulo), findsOneWidget);
      expect(find.text(TimeBlockFormPage.pickerCancelar), findsOneWidget);
      expect(find.text('OK'), findsNothing);
      // Aceptar sin mover el dial deja la hora que el picker propone.
      await tester.tap(find.text(TimeBlockFormPage.pickerAceptar));
      await tester.pumpAndSettle();
      expect(_c.inicioTexto, '14:00');
      expect(find.text('14:00'), findsOneWidget);

      await tester.ensureVisible(find.byKey(TimeBlockFormPage.desdeKey));
      await tester.tap(find.byKey(TimeBlockFormPage.desdeKey));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      expect(find.text(TimeBlockFormPage.pickerFechaTitulo), findsOneWidget);
      await tester.tap(find.text(TimeBlockFormPage.pickerAceptar));
      await tester.pumpAndSettle();
      // La fecha propuesta es la de hoy: basta con que haya llegado.
      expect(_c.desde.value, isNotNull);
      expect(find.text(_c.desdeTexto!), findsOneWidget);
    });
  });

  group('WIDGET · aviso de cruce antes de guardar (RF-BLQ-3)', () {
    testWidgets('con cruce muestra el aviso y, al confirmar, guarda',
        (tester) async {
      final clase = _claseDelMartes();
      final service = await _abrirFormulario(tester, secciones: [clase]);
      // Martes de 14:00 a 18:00 contra la clase del martes de 4 a 6 pm.
      await _llenar(tester, dias: const ['Ma']);
      await _guardar(tester);

      final esperado = mensajeDeCruce(
        crucesDeBloque(
          dias: {2},
          inicio: '14:00',
          fin: '18:00',
          secciones: [clase],
          bloques: const [],
        ),
      );
      // Nombra con qué choca (la forma exacta del texto es de la Tarea 2).
      expect(esperado.toLowerCase(), contains('curso de prueba a'));
      expect(find.byKey(TimeBlockFormPage.avisoCruceKey), findsOneWidget);
      expect(find.text(esperado), findsOneWidget);
      expect(service.creados, isEmpty); // el aviso llega ANTES de enviar

      await tester.tap(find.text(TimeBlockFormPage.cruceGuardar));
      await tester.pumpAndSettle();

      expect(service.creados, hasLength(1));
      expect(Get.currentRoute, '/inicio');
    });

    testWidgets('"Volver a editar" cierra el aviso y no guarda',
        (tester) async {
      final service = await _abrirFormulario(
        tester,
        secciones: [_claseDelMartes()],
      );
      await _llenar(tester, dias: const ['Ma']);
      await _guardar(tester);

      await tester.tap(find.text(TimeBlockFormPage.cruceVolver));
      await tester.pumpAndSettle();

      expect(find.byKey(TimeBlockFormPage.avisoCruceKey), findsNothing);
      expect(service.creados, isEmpty);
      expect(Get.currentRoute, '/bloque');
      expect(_c.nombre.text, 'Prácticas'); // no se pierde lo escrito
    });

    testWidgets('también avisa del cruce con otro bloque propio',
        (tester) async {
      final service = await _abrirFormulario(tester, bloques: [_practicas()]);
      // Miércoles de 16:00 a 20:00 contra Prácticas del miércoles 14-18.
      await _llenar(
        tester,
        nombre: 'Voluntariado',
        dias: const ['Mi'],
        inicio: const TimeOfDay(hour: 16, minute: 0),
        fin: const TimeOfDay(hour: 20, minute: 0),
      );
      await _guardar(tester);

      final esperado = mensajeDeCruce(
        crucesDeBloque(
          dias: {3},
          inicio: '16:00',
          fin: '20:00',
          secciones: const [],
          bloques: [_practicas()],
        ),
      );
      expect(esperado.toLowerCase(), contains('prácticas'));
      expect(find.byKey(TimeBlockFormPage.avisoCruceKey), findsOneWidget);
      expect(find.text(esperado), findsOneWidget);
      expect(service.creados, isEmpty);
    });

    testWidgets('tocarse en el borde no es cruce: guarda sin aviso',
        (tester) async {
      final service = await _abrirFormulario(
        tester,
        secciones: [_claseDelMartes()],
      );
      // Martes de 18:00 a 20:00: empieza justo cuando termina la clase.
      await _llenar(
        tester,
        dias: const ['Ma'],
        inicio: const TimeOfDay(hour: 18, minute: 0),
        fin: const TimeOfDay(hour: 20, minute: 0),
      );
      await _guardar(tester);

      expect(find.byKey(TimeBlockFormPage.avisoCruceKey), findsNothing);
      expect(service.creados, hasLength(1));
    });

    testWidgets(
        'sin clases inyectadas, compara contra las del horario en pantalla',
        (tester) async {
      // Aquí no se inyecta nada: el binding REAL crea el controller, y la
      // única fuente de clases es seccionesDelHorario() → el
      // HorarioController registrado. Si esa pieza devolviera siempre [],
      // las demás pruebas del aviso seguirían en verde y esta no.
      Get.put<HorarioController>(_HorarioConClases([_claseDelMartes()]));
      final service = await _abrirFormulario(tester);
      // Martes de 14:00 a 18:00 contra la clase del martes de 4 a 6 pm.
      await _llenar(tester, dias: const ['Ma']);
      await _guardar(tester);

      final esperado = mensajeDeCruce(
        crucesDeBloque(
          dias: {2},
          inicio: '14:00',
          fin: '18:00',
          secciones: [_claseDelMartes()],
          bloques: const [],
        ),
      );
      expect(find.byKey(TimeBlockFormPage.avisoCruceKey), findsOneWidget);
      expect(find.text(esperado), findsOneWidget);
      expect(service.creados, isEmpty);
    });
  });

  group('UNITARIA · de dónde salen las clases del aviso (RF-BLQ-3)', () {
    test('sin el horario registrado no hay clases contra las que cruzar', () {
      expect(Get.isRegistered<HorarioController>(), isFalse);
      expect(TimeBlockFormController.seccionesDelHorario(), isEmpty);
    });
  });

  group('WIDGET · botón de agregar en el horario (RF-BLQ-1)', () {
    Widget horario() => GetMaterialApp(
          home: const HorarioPage(),
          getPages: [
            GetPage(
              name: '/bloque',
              page: () => const Scaffold(body: Text('FORMULARIO')),
            ),
          ],
        );

    testWidgets('la alumna ve el botón y la lleva a /bloque', (tester) async {
      _telefonoVertical(tester);
      Get.put<AuthService>(_FakeAuthService(_alumna()));
      await tester.pumpWidget(horario());
      // Sin pumpAndSettle: sin datos, el horario pinta un SkeletonPulse que
      // anima sin fin.
      await tester.pump();

      expect(find.byKey(HorarioPage.agregarBloqueKey), findsOneWidget);

      await tester.tap(find.byKey(HorarioPage.agregarBloqueKey));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(Get.currentRoute, '/bloque');
      expect(find.text('FORMULARIO'), findsOneWidget);

      await _desmontarHorario(tester);
    });

    testWidgets('abre el formulario en vertical y al volver el horario rota',
        (tester) async {
      // Solo el horario puede girar (schedule.spec.md, "Schedule-only
      // rotation"): el formulario se abre fijado en vertical, igual que el
      // detalle de un curso, y al volver se devuelve la rotación del horario.
      _telefonoVertical(tester);
      Get.put<AuthService>(_FakeAuthService(_alumna()));
      await tester.pumpWidget(horario());
      await tester.pump();

      await tester.tap(find.byKey(HorarioPage.agregarBloqueKey));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(Get.currentRoute, '/bloque');
      expect(_orientaciones, [
        ['DeviceOrientation.portraitUp'],
      ]);

      Get.back<dynamic>();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(_orientaciones, hasLength(2));
      expect(_orientaciones.last, [
        'DeviceOrientation.portraitUp',
        'DeviceOrientation.landscapeLeft',
        'DeviceOrientation.landscapeRight',
      ]);

      await _desmontarHorario(tester);
    });

    testWidgets('un docente no ve el botón', (tester) async {
      // En vertical, donde la alumna SÍ lo ve: la única diferencia es el rol.
      _telefonoVertical(tester);
      Get.put<AuthService>(_FakeAuthService(_docente()));
      await tester.pumpWidget(horario());
      await tester.pump();

      expect(find.byKey(HorarioPage.agregarBloqueKey), findsNothing);

      await _desmontarHorario(tester);
    });

    testWidgets('en la lista de chats no aparece', (tester) async {
      _telefonoVertical(tester);
      Get.put<AuthService>(_FakeAuthService(_alumna()));
      await tester.pumpWidget(horario());
      await tester.pump();
      expect(find.byKey(HorarioPage.agregarBloqueKey), findsOneWidget);

      Get.find<HorarioController>().toggleListView();
      await tester.pump();

      expect(find.text('Mis chats'), findsOneWidget);
      expect(find.byKey(HorarioPage.agregarBloqueKey), findsNothing);

      await _desmontarHorario(tester);
    });

    testWidgets('en horizontal el botón no tapa la grilla semanal',
        (tester) async {
      // 800 x 600, la superficie por defecto: horizontal.
      Get.put<AuthService>(_FakeAuthService(_alumna()));
      await tester.pumpWidget(horario());
      await tester.pump();

      expect(find.byKey(HorarioPage.agregarBloqueKey), findsNothing);

      await _desmontarHorario(tester);
    });
  });
}
```

- [ ] **Paso 2: Correr la prueba y ver que falla**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test test/HU35_jeff/time_blocks_form_test.dart
```

Esperado: FALLA al compilar, antes de correr ninguna prueba. Los tres primeros errores son exactamente estos, los tres archivos que crea el Paso 3:

```
test/HU35_jeff/time_blocks_form_test.dart:25:8: Error: Error when reading 'lib/pages/time_blocks/time_block_form_binding.dart': No such file or directory
test/HU35_jeff/time_blocks_form_test.dart:26:8: Error: Error when reading 'lib/pages/time_blocks/time_block_form_controller.dart': No such file or directory
test/HU35_jeff/time_blocks_form_test.dart:27:8: Error: Error when reading 'lib/pages/time_blocks/time_block_form_page.dart': No such file or directory
```

Los demás son la cascada de esos tres (`Undefined name 'TimeBlockFormPage'`, `'TimeBlockFormController' isn't a type`, `Method not found: 'TimeBlockFormBinding'`, …) más siete `Error: Member not found: 'agregarBloqueKey'.`, que es la constante que el Paso 3 agrega a `HorarioPage`. Termina con `Some tests failed.` y la falla figura como `loading …/time_blocks_form_test.dart`.

Cualquier otro error indica que las Tareas 1 o 2 no dejaron las firmas de "Consume", y entonces hay que **PARAR** y reportar. Por ejemplo: `No named parameter with the name 'apiClient'`, `Undefined name 'validarDias'`, `Type 'TimeBlockInput' not found` o `Method not found: 'crucesDeBloque'`.

- [ ] **Paso 3: Implementación mínima**

**3a.** Crear `lib/pages/time_blocks/time_block_form_controller.dart`:

```dart
// lib/pages/time_blocks/time_block_form_controller.dart
// RF-BLQ-2: estado del formulario de un bloque propio. El mismo controller
// crea (sin argumento de ruta) y edita (con un TimeBlockRule en Get.arguments).
//
// No habla HTTP: eso es de TimeBlocksService. No valida a mano: eso es de
// time_block_validators.dart. Lo suyo es sostener los seis campos, traducirlos
// al contrato ("HH:MM", "YYYY-MM-DD") y decidir si se guarda.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../configs/course_colors.dart';
import '../../models/time_block_model.dart';
import '../../services/time_blocks_service.dart';
import '../horario/horario_controller.dart';
import 'time_block_conflicts.dart';
import 'time_block_validators.dart';

class TimeBlockFormController extends GetxController {
  TimeBlockFormController({
    TimeBlocksService? service,
    List<Map<String, dynamic>> Function()? secciones,
  })  : _service = service,
        _secciones = secciones ?? seccionesDelHorario;

  final TimeBlocksService? _service;
  final List<Map<String, dynamic>> Function() _secciones;

  /// Solo para fallos que no traen mensaje del servidor. Es el MISMO texto
  /// que ya usa el service (Tarea 1): el alumno no tiene por qué leer dos
  /// versiones del mismo error.
  static const String errorGenerico = TimeBlocksService.genericErrorMessage;

  /// El service se resuelve tarde (no en el constructor) para que el binding
  /// pueda construir el controller antes de que nadie toque `Get.find`.
  TimeBlocksService get service => _service ?? TimeBlocksService.to;

  /// Las clases del alumno, tal como las tiene el horario en pantalla. Si la
  /// pantalla de horario no está montada (el formulario abierto desde una ruta
  /// suelta), no hay clases contra las que cruzar y la lista va vacía.
  ///
  /// `uniqueEnrolledCourses` ya deja fuera las asesorías: son de una fecha
  /// suelta, y compararlas por día de la semana avisaría de un cruce en todas
  /// las semanas.
  static List<Map<String, dynamic>> seccionesDelHorario() =>
      Get.isRegistered<HorarioController>()
          ? Get.find<HorarioController>().uniqueEnrolledCourses
          : const <Map<String, dynamic>>[];

  /// `#RRGGBB` en mayúsculas, que es lo que pide el contrato.
  static String hexDeColor(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  static String fmtHora(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static String fmtFecha(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static TimeOfDay? horaDeTexto(String? hhmm) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch((hhmm ?? '').trim());
    if (m == null) return null;
    final h = int.parse(m.group(1)!);
    final min = int.parse(m.group(2)!);
    if (h > 23 || min > 59) return null;
    return TimeOfDay(hour: h, minute: min);
  }

  static DateTime? fechaDeTexto(String? yyyymmdd) =>
      DateTime.tryParse((yyyymmdd ?? '').trim());

  final nombre = TextEditingController();
  final colorHex = ''.obs;
  final dias = <int>{}.obs;
  final inicio = Rxn<TimeOfDay>();
  final fin = Rxn<TimeOfDay>();
  final desde = Rxn<DateTime>();
  final hasta = Rxn<DateTime>();

  final guardando = false.obs;
  final errorMessage = RxnString();

  TimeBlockRule? _bloque;

  /// El bloque que se está editando, o null si se está creando.
  TimeBlockRule? get bloque => _bloque;
  bool get editando => _bloque != null;

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg is TimeBlockRule) {
      _bloque = arg;
      nombre.text = arg.title;
      colorHex.value = arg.colorHex.toUpperCase();
      dias.assignAll(arg.daysOfWeek);
      inicio.value = horaDeTexto(arg.startTime);
      fin.value = horaDeTexto(arg.endTime);
      desde.value = fechaDeTexto(arg.startDate);
      hasta.value = fechaDeTexto(arg.endDate);
    } else {
      colorHex.value = hexDeColor(kCoursePalette.first);
    }
  }

  String? get inicioTexto =>
      inicio.value == null ? null : fmtHora(inicio.value!);
  String? get finTexto => fin.value == null ? null : fmtHora(fin.value!);
  String? get desdeTexto =>
      desde.value == null ? null : fmtFecha(desde.value!);
  String? get hastaTexto =>
      hasta.value == null ? null : fmtFecha(hasta.value!);

  /// Deja el mensaje del validador en [errorMessage] y dice si se puede seguir.
  bool validar() {
    final mensaje = validarFormulario(
      nombre: nombre.text,
      dias: dias.toSet(),
      inicio: inicioTexto,
      fin: finTexto,
      desde: desdeTexto,
      hasta: hastaTexto,
    );
    errorMessage.value = mensaje;
    return mensaje == null;
  }

  /// Cruces del bloque tal como está ahora, contra las clases en pantalla y
  /// contra los demás bloques del alumno. Al editar, el propio bloque no cuenta.
  List<Cruce> cruces() {
    final i = inicioTexto;
    final f = finTexto;
    if (i == null || f == null || dias.isEmpty) return const <Cruce>[];
    return crucesDeBloque(
      dias: dias.toSet(),
      inicio: i,
      fin: f,
      secciones: _secciones(),
      bloques: service.blocks,
      ignorarBloqueId: _bloque?.id,
      // Un bloque propio de otro rango de fechas nunca coincide con este.
      desde: desdeTexto,
      hasta: hastaTexto,
    );
  }

  /// Crea o edita. Devuelve true solo si el servidor aceptó. Un error del
  /// servidor se muestra TAL CUAL llega (RF-BLQ-2): no se reescribe acá.
  Future<bool> guardar() async {
    if (!validar()) return false;
    guardando.value = true;
    try {
      final input = TimeBlockInput(
        title: nombre.text.trim(),
        colorHex: colorHex.value,
        daysOfWeek: dias.toList()..sort(),
        startTime: inicioTexto!,
        endTime: finTexto!,
        startDate: desdeTexto!,
        endDate: hastaTexto!,
      );
      final actual = _bloque;
      if (actual == null) {
        await service.create(input);
      } else {
        await service.update(actual.id, input);
      }
      return true;
    } on TimeBlocksFailure catch (e) {
      errorMessage.value = e.message;
      return false;
    } catch (e) {
      // Red de seguridad: el service envuelve sus errores en
      // TimeBlocksFailure, pero si algo se le escapa el alumno tiene que ver
      // un mensaje y no un botón que no hace nada.
      debugPrint('Error guardando el bloque: $e');
      errorMessage.value = errorGenerico;
      return false;
    } finally {
      guardando.value = false;
    }
  }

  @override
  void onClose() {
    nombre.dispose();
    super.onClose();
  }
}
```

**3b.** Crear `lib/pages/time_blocks/time_block_form_binding.dart`:

```dart
// lib/pages/time_blocks/time_block_form_binding.dart
// Binding por ruta de /bloque (regla del repo: nada de Get.put en builds).
// `lazyPut` sin `fenix`: GetX elimina el controller al salir y su `onClose`
// libera el TextEditingController del nombre.

import 'package:get/get.dart';

import 'time_block_form_controller.dart';

class TimeBlockFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => TimeBlockFormController());
  }
}
```

**3c.** Crear `lib/pages/time_blocks/time_block_form_page.dart`:

```dart
// lib/pages/time_blocks/time_block_form_page.dart
// RF-BLQ-1 y RF-BLQ-2: el formulario de un bloque propio, en el orden que fija
// la spec: nombre, color, días, horas, desde y hasta.
//
// Los pickers y el estilo de los campos copian el único formulario con pickers
// del repo (lib/pages/teacher/create_advising_page.dart), con el título y los
// botones en español (D7). El selector de color son los doce círculos de
// kCoursePalette en dos filas: no se agrega ninguna dependencia de selector
// de color.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../configs/course_colors.dart';
import '../../configs/themes.dart';
import 'time_block_conflicts.dart';
import 'time_block_form_controller.dart';

class TimeBlockFormPage extends StatelessWidget {
  const TimeBlockFormPage({super.key});

  static const String tituloCrear = 'Nuevo bloque';
  static const String tituloEditar = 'Editar bloque';
  static const String guardarLabel = 'Guardar bloque';
  static const String cruceTitulo = 'Hay un cruce';
  static const String cruceVolver = 'Volver a editar';
  static const String cruceGuardar = 'Guardar igual';

  /// El título y los botones de los selectores de Flutter, en español (D7).
  /// Los nombres de los meses siguen en inglés: la app no carga
  /// flutter_localizations y esta funcionalidad no agrega dependencias.
  static const String pickerHoraTitulo = 'Elige la hora';
  static const String pickerFechaTitulo = 'Elige la fecha';
  static const String pickerCancelar = 'Cancelar';
  static const String pickerAceptar = 'Aceptar';

  static const Key nombreKey = Key('bloque-nombre');
  static const Key diasKey = Key('bloque-dias');
  static const Key horaInicioKey = Key('bloque-hora-inicio');
  static const Key horaFinKey = Key('bloque-hora-fin');
  static const Key desdeKey = Key('bloque-desde');
  static const Key hastaKey = Key('bloque-hasta');
  static const Key guardarKey = Key('bloque-guardar');
  static const Key avisoCruceKey = Key('bloque-aviso-cruce');

  /// Key del círculo de un color de la paleta, por su hex `#RRGGBB`.
  static Key colorKey(String hex) => Key('bloque-color-$hex');

  /// Etiquetas de los días, de lunes (1) a domingo (7).
  static const List<String> diasLabels = [
    'Lu',
    'Ma',
    'Mi',
    'Ju',
    'Vi',
    'Sá',
    'Do',
  ];

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TimeBlockFormController>();
    final brightness = Theme.brightnessOf(context);
    final labelColor = MaterialTheme.textPrimary(brightness);

    Widget label(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 18),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
        );

    return Scaffold(
      backgroundColor: MaterialTheme.pageBg(brightness),
      appBar: AppBar(
        title: Text(c.editando ? tituloEditar : tituloCrear),
      ),
      body: Obx(() {
        // Mientras guarda no se sale (ni con la flecha, ni con el botón atrás
        // de Android, ni deslizando en iOS): el guardado termina cerrando ESTA
        // pantalla, y si el alumno ya hubiera vuelto cerraría la de abajo.
        return PopScope(
          canPop: !c.guardando.value,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Nombre
                label('Nombre'),
                TextField(
                  key: nombreKey,
                  controller: c.nombre,
                  decoration: InputDecoration(
                    hintText: 'Ej. Prácticas',
                    filled: true,
                    fillColor: MaterialTheme.cardBg(brightness),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: MaterialTheme.borderColor(brightness),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: MaterialTheme.borderColor(brightness),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: MaterialTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                // 2. Color
                label('Color'),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final color in kCoursePalette)
                      _CirculoColor(
                        hex: TimeBlockFormController.hexDeColor(color),
                        color: color,
                        elegido: c.colorHex.value ==
                            TimeBlockFormController.hexDeColor(color),
                        onTap: () => c.colorHex.value =
                            TimeBlockFormController.hexDeColor(color),
                      ),
                  ],
                ),

                // 3. Días
                label('Días'),
                SegmentedButton<int>(
                  key: diasKey,
                  multiSelectionEnabled: true,
                  emptySelectionAllowed: true,
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                    textStyle:
                        const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  segments: [
                    for (var d = 1; d <= 7; d++)
                      ButtonSegment(
                        value: d,
                        label: Text(
                          diasLabels[d - 1],
                          softWrap: false,
                          overflow: TextOverflow.fade,
                        ),
                      ),
                  ],
                  selected: c.dias.toSet(),
                  onSelectionChanged: c.dias.assignAll,
                ),

                // 4. Horas
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          label('Hora de inicio'),
                          TimeBlockPickerField(
                            key: horaInicioKey,
                            texto: c.inicioTexto ?? '--:--',
                            icono: Icons.schedule,
                            brightness: brightness,
                            onTap: () async {
                              final elegida = await showTimePicker(
                                context: context,
                                initialTime: c.inicio.value ??
                                    const TimeOfDay(hour: 14, minute: 0),
                                helpText: pickerHoraTitulo,
                                cancelText: pickerCancelar,
                                confirmText: pickerAceptar,
                              );
                              if (elegida != null) c.inicio.value = elegida;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          label('Hora de fin'),
                          TimeBlockPickerField(
                            key: horaFinKey,
                            texto: c.finTexto ?? '--:--',
                            icono: Icons.schedule,
                            brightness: brightness,
                            onTap: () async {
                              final elegida = await showTimePicker(
                                context: context,
                                initialTime: c.fin.value ??
                                    const TimeOfDay(hour: 18, minute: 0),
                                helpText: pickerHoraTitulo,
                                cancelText: pickerCancelar,
                                confirmText: pickerAceptar,
                              );
                              if (elegida != null) c.fin.value = elegida;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // 5. Desde y hasta
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          label('Desde'),
                          TimeBlockPickerField(
                            key: desdeKey,
                            texto: c.desdeTexto ?? 'Elegir',
                            icono: Icons.calendar_today_outlined,
                            brightness: brightness,
                            onTap: () async {
                              final elegida = await _elegirFecha(
                                context,
                                c.desde.value,
                              );
                              if (elegida != null) c.desde.value = elegida;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          label('Hasta'),
                          TimeBlockPickerField(
                            key: hastaKey,
                            texto: c.hastaTexto ?? 'Elegir',
                            icono: Icons.calendar_today_outlined,
                            brightness: brightness,
                            onTap: () async {
                              final elegida = await _elegirFecha(
                                context,
                                c.hasta.value ?? c.desde.value,
                              );
                              if (elegida != null) c.hasta.value = elegida;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (c.errorMessage.value != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      c.errorMessage.value!,
                      style: const TextStyle(
                        color: MaterialTheme.primaryDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    key: guardarKey,
                    onPressed:
                        c.guardando.value ? null : () => _alGuardar(context, c),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MaterialTheme.primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          MaterialTheme.primaryColor.withValues(alpha: 0.5),
                    ),
                    child: c.guardando.value
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.2,
                            ),
                          )
                        : const Text(
                            guardarLabel,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Future<DateTime?> _elegirFecha(BuildContext context, DateTime? actual) {
    final hoy = DateTime.now();
    final primera = DateTime(hoy.year - 1);
    final ultima = DateTime(hoy.year + 2, 12, 31);
    // `showDatePicker` revienta si la fecha inicial cae fuera del rango: un
    // bloque viejo que se edita puede traer una fecha anterior a `primera`.
    var inicial = actual ?? hoy;
    if (inicial.isBefore(primera)) inicial = primera;
    if (inicial.isAfter(ultima)) inicial = ultima;
    return showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: primera,
      lastDate: ultima,
      helpText: pickerFechaTitulo,
      cancelText: pickerCancelar,
      confirmText: pickerAceptar,
    );
  }

  /// Validar → avisar del cruce → guardar. El aviso NUNCA impide guardar
  /// (RF-BLQ-3): ofrece las dos salidas y el alumno decide.
  Future<void> _alGuardar(
    BuildContext context,
    TimeBlockFormController c,
  ) async {
    if (!c.validar()) return;

    final cruces = c.cruces();
    if (cruces.isNotEmpty) {
      final seguir = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          key: avisoCruceKey,
          title: const Text(cruceTitulo),
          content: Text(mensajeDeCruce(cruces)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(cruceVolver),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(cruceGuardar),
            ),
          ],
        ),
      );
      // Cerrar con el barrier o con back devuelve null: tampoco guarda.
      if (seguir != true) return;
    }

    final ok = await c.guardar();
    // `Navigator.pop` y no `Get.back`: con un snackbar abierto, `Get.back`
    // cierra el snackbar y deja al alumno en el formulario ya guardado.
    if (ok && context.mounted) Navigator.of(context).pop(true);
  }
}

/// Un círculo de la paleta. El elegido lleva un anillo y un check. 40 px con
/// 12 de separación: en un iPhone SE (343 px útiles) entran seis por fila y
/// la paleta queda en dos filas de seis (RF-BLQ-2, D7); en una pantalla más
/// ancha el `Wrap` pone más en la primera (7 y 5).
class _CirculoColor extends StatelessWidget {
  const _CirculoColor({
    required this.hex,
    required this.color,
    required this.elegido,
    required this.onTap,
  });

  final String hex;
  final Color color;
  final bool elegido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: TimeBlockFormPage.colorKey(hex),
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: elegido
              ? Border.all(color: MaterialTheme.primaryColor, width: 3)
              : null,
        ),
        child: elegido
            ? const Icon(Icons.check, size: 18, color: Colors.white)
            : null,
      ),
    );
  }
}

/// Campo que abre un picker. Público a propósito: la hoja de acciones de
/// RF-BLQ-5 reusa el mismo campo para cambiar la hora de un día suelto.
class TimeBlockPickerField extends StatelessWidget {
  const TimeBlockPickerField({
    super.key,
    required this.texto,
    required this.icono,
    required this.brightness,
    required this.onTap,
  });

  final String texto;
  final IconData icono;
  final Brightness brightness;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(
          color: MaterialTheme.cardBg(brightness),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MaterialTheme.borderColor(brightness)),
        ),
        child: Row(
          children: [
            Icon(icono, size: 18, color: MaterialTheme.textMuted(brightness)),
            const SizedBox(width: 10),
            // Expanded + ellipsis: en un iPhone SE cada campo de la fila mide
            // ~135 px y un texto largo desbordaba la fila.
            Expanded(
              child: Text(
                texto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  color: MaterialTheme.textPrimary(brightness),
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

La paleta va en un `Wrap`, en dos filas de seis en un iPhone SE: es lo que fija la spec (RF-BLQ-2, decisión D7), así que ya no hay alternativa de una fila con scroll.

**3d.** `lib/main.dart`, imports (hoy líneas 50-51; tras la Tarea 1, 51-52). Reemplazar esto:

```dart
import 'pages/networking/networking_binding.dart';
import 'pages/networking/networking_page.dart';
```

por esto:

```dart
import 'pages/networking/networking_binding.dart';
import 'pages/networking/networking_page.dart';
import 'pages/time_blocks/time_block_form_binding.dart';
import 'pages/time_blocks/time_block_form_page.dart';
```

**3e.** `lib/main.dart`, final de `getPages` (hoy líneas 229-234; tras la Tarea 1, 235-240). Reemplazar esto:

```dart
        GetPage(
          name: '/networking',
          page: () => const NetworkingPage(),
          binding: NetworkingBinding(),
        ),
      ],
```

por esto:

```dart
        GetPage(
          name: '/networking',
          page: () => const NetworkingPage(),
          binding: NetworkingBinding(),
        ),
        // Bloques de horario propios (RF-BLQ-1, RF-BLQ-2). Sin argumento crea;
        // con un TimeBlockRule en `arguments` edita ese bloque. Binding por
        // ruta, como el resto.
        GetPage(
          name: '/bloque',
          page: () => const TimeBlockFormPage(),
          binding: TimeBlockFormBinding(),
        ),
      ],
```

**3f.** `lib/pages/horario/horario.dart`, cabecera de `HorarioPage` (hoy líneas 18-19). Reemplazar esto:

```dart
class HorarioPage extends StatelessWidget {
  const HorarioPage({super.key});
```

por esto:

```dart
class HorarioPage extends StatelessWidget {
  const HorarioPage({super.key});

  /// Botón para agregar un bloque propio (RF-BLQ-1). Solo lo ve el alumno.
  static const Key agregarBloqueKey = Key('horario-agregar-bloque');
```

**3g.** `lib/pages/horario/horario.dart`, el `return Scaffold(` de `build()` (hoy líneas 815-819; es el único `return Scaffold(` del archivo). Reemplazar esto:

```dart
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1E1E26)
          : const Color(0xFFF8F9FA),
      body: Obx(() {
```

por esto:

```dart
    // RF-BLQ-1: agregar un bloque propio es solo del alumno; el horario del
    // docente es el de sus clases y asesorías. En horizontal la grilla semanal
    // ocupa toda la pantalla y el botón la taparía; en la lista de chats no
    // hay grilla a la que agregar nada.
    final esAlumno = !(AuthService.to.currentUser?.isTeacher ?? false);
    final enHorizontal =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1E1E26)
          : const Color(0xFFF8F9FA),
      floatingActionButton: (esAlumno && !enHorizontal)
          ? Obx(
              () => controller.isListView.value
                  ? const SizedBox.shrink()
                  // `small`: la esquina inferior derecha es la franja de 9 a
                  // 10 pm, donde sí hay clases; el botón chico tapa menos.
                  : FloatingActionButton.small(
                      key: agregarBloqueKey,
                      tooltip: 'Agregar bloque',
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      // Como el toque de un curso: el formulario no rota
                      // (solo el horario puede), así que se fija en vertical
                      // antes de abrirlo y se devuelve la rotación al volver.
                      onPressed: () async {
                        await SystemChrome.setPreferredOrientations(
                          _portraitOnly,
                        );
                        await Get.toNamed<dynamic>('/bloque');
                        await SystemChrome.setPreferredOrientations(
                          _scheduleOrientations,
                        );
                      },
                      child: const Icon(Icons.add),
                    ),
            )
          : null,
      body: Obx(() {
```

El reemplazo usa `controller` y `colors`, que `build()` ya declara justo arriba (`final controller = Get.put(HorarioController());` y `final colors = Theme.of(context).colorScheme;`). Si un ancla de 3d–3g no aparece literal, o si `controller`/`colors` ya no están declarados antes del `return Scaffold(`, es porque una tarea anterior los cambió: **PARAR** y reportar en vez de improvisar el reemplazo.

- [ ] **Paso 4: Correr la prueba y ver que pasa**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test test/HU35_jeff/time_blocks_form_test.dart
```

Esperado: PASS, `+21: All tests passed!`.

En la salida aparecen líneas de `debugPrint` que no son fallos:
- `Error guardando el bloque: Bad state: inesperado`, del caso "un fallo sin mensaje del servidor", que lo provoca a propósito.
- `Error al cargar dias: "StorageService" not found...` y sus equivalentes de secciones, evaluaciones y carga (o, en el caso del docente, `Error al cargar dias y sesiones del docente` y `Error al cargar evaluaciones del docente`). Salen de `HorarioController` en las cinco pruebas del botón, que montan `HorarioPage` sin backend.

- [ ] **Paso 5: Regresión del horario**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test test/HU35_jeff/ test/HU31_jeff/
```

Esperado: PASS en todo, `+193: All tests passed!`: las 141 de `test/HU35_jeff/` (19 del service, 55 de cruces, 46 de la grilla y las 21 de esta tarea) y las 52 de `test/HU31_jeff/`. Esto incluye `time_blocks_grilla_test.dart` de las Tareas 3 y 4, que monta el mismo `HorarioPage`, y la geometría y el contenido de bloque de HU31. Si el total en verde es otro, se corre archivo por archivo y se compara con esas cifras. Si una prueba de la Tarea 4 falla porque el botón nuevo se interpone en un toque suyo (el botón solo existe para alumnos y en vertical), **PARAR** y reportar: no se mueve el botón ni se cambia esa prueba sin decidirlo con el dueño.

- [ ] **Paso 6: Análisis estático**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" analyze
```

Esperado: `7 issues found.`, la misma lista de la línea base que midió la Tarea 1, todos preexistentes. Única diferencia admitida: el `avoid_print` de `lib/main.dart` pasa a la línea 93 (85 en la línea base, más las seis líneas de la Tarea 1 y los dos imports de esta). Ningún issue nuevo en `lib/pages/time_blocks/`, `lib/main.dart`, `lib/pages/horario/horario.dart` ni `test/HU35_jeff/time_blocks_form_test.dart`. Si aparece alguno, se arregla antes de seguir.

- [ ] **Paso 7: Anotar en el reporte los textos nuevos que ve el alumno**, para que el dueño los lea antes de publicar:
  - Títulos: "Nuevo bloque" y "Editar bloque".
  - Etiquetas: "Nombre", "Color", "Días", "Hora de inicio", "Hora de fin", "Desde", "Hasta".
  - Pista del nombre: "Ej. Prácticas". Campos vacíos: "--:--" en las horas y "Elegir" en las fechas.
  - Días: "Lu", "Ma", "Mi", "Ju", "Vi", "Sá", "Do".
  - Botón: "Guardar bloque". Tooltip del botón del horario: "Agregar bloque".
  - Aviso de cruce: título "Hay un cruce" y botones "Volver a editar" y "Guardar igual". El cuerpo lo arma `mensajeDeCruce` (Tarea 2).
  - Los mensajes de validación son los de la Tarea 2, y el de un fallo sin mensaje del servidor es el de la Tarea 1 ("No se pudo guardar tu bloque. Inténtalo de nuevo."): esta tarea no agrega un segundo texto para lo mismo.
  - Los selectores de hora y de fecha llevan su título y sus botones en español (D7), pasados con `helpText`, `cancelText` y `confirmText`: "Elige la hora", "Elige la fecha", "Cancelar" y "Aceptar". Los nombres de los meses y los rótulos internos del selector (por ejemplo, los de escribir la hora a mano) siguen en inglés: la app no carga `flutter_localizations` y esta tarea no agrega dependencias. El formulario de asesorías del docente sigue con los textos de Flutter.
  - La paleta va en dos filas de seis (`Wrap`) en un iPhone SE, como fija la spec (D7); en una pantalla más ancha, 7 y 5.
  - Decisiones de pantalla pendientes del dueño. D7 solo fija el botón abajo a la derecha; las dos exclusiones y el tamaño los eligió esta tarea, y van al punto «Para mirar antes de publicar» del reporte de la Tarea 8. El código se queda como está mientras el dueño decide.
    - El botón de agregar no aparece en horizontal ni en la lista de chats. RF-BLQ-1 solo dice «en la pantalla de horario, y solo para alumnos». En horizontal la grilla semanal ocupa toda la pantalla y el botón taparía una columna; en la lista de chats no hay grilla. Si el dueño lo rechaza, se quita `!enHorizontal` de la condición y la prueba «en horizontal el botón no tapa la grilla semanal».
    - La grilla vertical ocupa toda la pantalla sin scroll ("Portrait calendar fit"), así que el botón flotante tapa la esquina derecha de la franja de 9 a 10 pm y se come los toques de esa esquina. Por eso esta tarea eligió el botón chico (`FloatingActionButton.small`). La burbuja del chatbot arranca abajo a la izquierda y no choca con él.
  - El aviso de cruce contra otro bloque propio mira también las fechas: un bloque de enero a febrero no avisa de un cruce con uno de septiembre a diciembre, porque nunca coinciden. Contra las clases solo mira el día y la hora (el horario de clases no trae fechas).

- [ ] **Paso final: Commit**

```bash
cd "${REPO:?}"
test "$(git branch --show-current)" = feat/bloques-horario-fe || echo 'PARAR: rama equivocada'
git status --short
git add lib/pages/time_blocks/time_block_form_controller.dart \
        lib/pages/time_blocks/time_block_form_binding.dart \
        lib/pages/time_blocks/time_block_form_page.dart \
        lib/main.dart \
        lib/pages/horario/horario.dart \
        test/HU35_jeff/time_blocks_form_test.dart
git commit -m "feat(time-blocks): formulario de bloque propio, aviso de cruce y botón de agregar en el horario (RF-BLQ-1 a RF-BLQ-3)"
git log -1 --format=%B | grep -qi '^co-authored-by:' && echo 'PARAR: el commit trae trailer'
```

Antes del `git add`, `git status --short` solo puede listar esos seis archivos; si lista otro, o sale un `PARAR`, se detiene aquí. Sin trailer `Co-Authored-By`: el autor ya está configurado en git.
### Tarea 6: Tocar un bloque propio

> Una versión anterior de esta tarea se verificó en una copia descartable del repo (en `/tmp`), con el código **literal** de las Tareas 1 a 5 de entonces aplicado encima de la rama `feat/bloques-horario-fe`: el Paso 2 falló al compilar por el archivo que falta, con 56 errores de cuatro tipos; el punto de control dio exactamente sus dos fallas; el Paso 4, `+20`; `test/HU35_jeff/` y `test/HU31_jeff/` juntos, `+197`; la suite completa, `+719`; `flutter analyze`, los 7 issues de la línea base. Después, una revisión cambió lo que esta tarea hace con un día cancelado (RF-BLQ-5: la grilla de la Tarea 4 lo pinta tenue y su hoja ofrece volver al patrón; el Deshacer del aviso se cierra solo), le sumó tres pruebas y sumó pruebas a las Tareas 1, 2, 4 y 5. Las cifras de abajo se midieron después de las decisiones finales del dueño (ver «Cifras de las pruebas» en las restricciones globales). El worktree real no se tocó.

**Requisitos:** RF-BLQ-5 completo: tocar un bloque propio abre una hoja con **Editar el bloque** (todas las semanas), **Cancelar solo este día**, **Cambiar la hora solo este día** y **Borrar el bloque** con una confirmación que dice que se borra el bloque y todos sus días; si el día está cancelado o movido, la hoja ofrece **volver al patrón**; tocar una clase sigue llevando al detalle del curso, como hoy.

**Archivos:**
- Crear: `lib/pages/time_blocks/time_block_actions_sheet.dart`
- Modificar: `lib/pages/horario/horario.dart:7-8` (un import) y `lib/pages/horario/horario.dart:327-329` (el comienzo del `onTap` de `_courseBlock`). Son los números de hoy. El import sigue en `:7-8` al llegar aquí (ninguna tarea anterior mete líneas antes); el `onTap` queda bastante más abajo, porque las Tareas 4 y 5 agregan líneas antes. Guiarse por el texto, que existe literal.
- Test: `test/HU35_jeff/time_blocks_acciones_test.dart`

No se toca `main.dart`, ni el controller del horario, ni el formulario: la ruta `/bloque`, el campo de hora y los validadores ya existen.

**Interfaces:**
- Consume — de la Tarea 1 (`lib/models/time_block_model.dart` y `lib/services/time_blocks_service.dart`):
  - `const TimeBlockOccurrence({required int blockId, required String title, required String colorHex, required String date, required int dayOfWeek, required String startTime, required String endTime, required bool moved})`; `const TimeBlockRule({required int id, required String title, required String colorHex, required List<int> daysOfWeek, required String startTime, required String endTime, required String startDate, required String endDate, required List<TimeBlockException> exceptions})`; `const TimeBlockException({required String date, required String status, required String? startTime, required String? endTime})`; `const TimeBlocksSnapshot({required List<TimeBlockOccurrence> occurrences, required List<TimeBlockWeek> weeks})`; el tipo `TimeBlockWeek`.
  - `TimeBlocksService({ApiClient? apiClient})`, `static TimeBlocksService get to`, `List<TimeBlockRule> get blocks`, `TimeBlocksSnapshot? get snapshot`, `Future<void> setException(int id, String date, {required String status, String? startTime, String? endTime})`, `Future<void> clearException(int id, String date)`, `Future<void> remove(int id)` y `static const String genericErrorMessage`. Las tres escrituras envuelven cualquier fallo en `TimeBlocksFailure` y, si salen bien, **recargan la ventana del horario** antes de volver: la grilla se entera sola y la hoja no tiene que hacer nada más.
  - `const TimeBlocksFailure(this.message)` con `final String message`.
- Consume — de la Tarea 2 (`lib/pages/time_blocks/time_block_validators.dart`): `String? validarHoras(String? inicio, String? fin)`.
- Consume — de la Tarea 4 (`lib/pages/horario/horario.dart` y `horario_controller.dart`): dentro de `_courseBlock`, la variable local `final bloquePropio = course['bloquePropio'] as TimeBlockOccurrence?;`, que es no nula justo en los bloques propios (la pone `_bloqueComoCurso`), y `final diaCancelado = course['diaCancelado'] == true;`, que es true en un día cancelado pintado tenue; y `List<TimeBlockOccurrence> bloquesDelDia(DaySchedule dia)` y `List<TimeBlockOccurrence> bloquesCanceladosDelDia(DaySchedule dia)` (este arma la ocurrencia de un día cancelado desde la regla, con las horas de la regla), que la prueba usa sin tocar a través de la grilla; y `DaySchedule(…, {String? isoDate})`, porque la grilla ubica cada bloque por el `isoDate` de su día.
- Consume — de la Tarea 5: la ruta `'/bloque'`, que **edita** cuando recibe un `TimeBlockRule` en `arguments` (la regla, no la ocurrencia); `class TimeBlockPickerField` con `const TimeBlockPickerField({Key? key, required String texto, required IconData icono, required Brightness brightness, required VoidCallback onTap})` y los textos en español del selector de hora, `TimeBlockFormPage.pickerHoraTitulo`, `pickerCancelar` y `pickerAceptar` (`time_block_form_page.dart`); y los estáticos `TimeBlockFormController.fmtHora(TimeOfDay t)` → `"HH:MM"` y `TimeBlockFormController.horaDeTexto(String? hhmm)` → `TimeOfDay?` (`time_block_form_controller.dart`).
- Consume — del repo:
  - `DescripCursosPage({Key? key, required String idSeccion})` (`lib/pages/descripcion_cursos/descrip_cursos.dart:13-19`), que hace `Get.put(DescripCursosController())` al construirse, y `Future<void> cargarDatosCurso(String idSeccion)` (`lib/pages/descripcion_cursos/descrip_cursos_controller.dart:51`). Solo la prueba los usa, para ver que una clase sigue yendo a su curso.
  - `MaterialTheme.textPrimary(Brightness)` (`lib/configs/themes.dart:63`), `MaterialTheme.textMuted(Brightness)` (`:71`) y `MaterialTheme.primaryDark` (`:12`).
  - `firstWhereOrNull`, la extensión de GetX que ya usa `descrip_cursos_controller.dart:48` y `:60`.
  - El patrón de hoja de `lib/components/avatar/avatar_perfil.dart:136-164` (`showModalBottomSheet<void>` + `SafeArea` + `ListTile`) y el de confirmación de `lib/pages/academic_record/academic_record_page.dart:605-645` (`showDialog<bool>` con "Cancelar"/"Borrar" y `ScaffoldMessenger` para el error).
- Antes de empezar, confirmar que las Tareas 1, 2, 4 y 5 dejaron esas firmas:
  ```bash
  cd "${REPO:?}"
  grep -c "static TimeBlocksService get to\|List<TimeBlockRule> get blocks\|Future<void> setException(\|Future<void> clearException(\|Future<void> remove(\|const TimeBlocksFailure(this.message)\|static const String genericErrorMessage" lib/services/time_blocks_service.dart
  grep -c "^String? validarHoras(String? inicio, String? fin)" lib/pages/time_blocks/time_block_validators.dart
  grep -c "final bloquePropio = course\['bloquePropio'\] as TimeBlockOccurrence?;" lib/pages/horario/horario.dart
  grep -c "final diaCancelado = course\['diaCancelado'\] == true;" lib/pages/horario/horario.dart
  grep -c "List<TimeBlockOccurrence> bloquesDelDia(DaySchedule dia)" lib/pages/horario/horario_controller.dart
  grep -c "List<TimeBlockOccurrence> bloquesCanceladosDelDia(DaySchedule dia)" lib/pages/horario/horario_controller.dart
  grep -c "^class TimeBlockPickerField extends StatelessWidget" lib/pages/time_blocks/time_block_form_page.dart
  grep -c "static String fmtHora(TimeOfDay t)\|static TimeOfDay? horaDeTexto(String? hhmm)" lib/pages/time_blocks/time_block_form_controller.dart
  grep -c "name: '/bloque'" lib/main.dart
  ```
  Esperado, en orden: `7`, `1`, `1`, `1`, `1`, `1`, `1`, `2`, `1`. Si alguno no coincide, **PARAR** y reportarlo: no se arregla una tarea anterior desde aquí.
- Produce:
  - La del esqueleto, más un nombrado opcional, en `lib/pages/time_blocks/time_block_actions_sheet.dart`:
    ```dart
    Future<void> mostrarAccionesDeBloque(BuildContext context, TimeBlockOccurrence ocurrencia,
        {bool cancelado = false});
    ```
    Abre la hoja y ejecuta lo que la alumna elija. Con `cancelado: true` (un día cancelado, que la grilla pinta tenue) la hoja ofrece **solo** volver al patrón (`clearException` con su fecha). Si no: editar el bloque (abre `'/bloque'` con la **regla**, buscada en `TimeBlocksService.to.blocks` por `blockId`, en vertical y devolviendo la rotación del horario al volver), cancelar este día (`setException(…, status: 'cancelled')`, con un aviso que se cierra solo y ofrece **Deshacer**, que deja el día como estaba: `clearException` si seguía el patrón, o `setException(…, status: 'moved', …)` con sus horas si ya estaba movido), cambiar la hora de este día (`setException(…, status: 'moved', startTime:, endTime:)`), volver al patrón (`clearException`, si la ocurrencia viene con `moved: true`) y borrar el bloque (`remove`, solo tras confirmar). Un fallo se avisa con el mensaje que trae. Cada aviso de la hoja reemplaza al que esté en pantalla.
  - En el mismo archivo, públicos para las pruebas y sin consumidores en tareas posteriores: `enum AccionDeBloque { editar, cancelarDia, cambiarHora, volverAlPatron, borrar }`, `String resumenDelDia(TimeBlockOccurrence ocurrencia)`, `class TimeBlockActionsSheet extends StatelessWidget` (con `const TimeBlockActionsSheet({Key? key, required TimeBlockOccurrence ocurrencia, required bool puedeEditar, bool cancelado = false})`, sus textos como `static const String` y sus keys como `static const Key`) y `class TimeBlockDayHoursDialog extends StatefulWidget` (con `const TimeBlockDayHoursDialog({Key? key, required String inicio, required String fin})`, que devuelve `({String inicio, String fin})?`). Privados, sin consumidores fuera del archivo: `_intentar` (corre una escritura y avisa si falla) y `_avisar` (muestra un aviso en lugar del que esté en pantalla).
  - En `HorarioPage._courseBlock`, la rama nueva del `onTap`: un bloque propio llama a `mostrarAccionesDeBloque(context, bloquePropio, cancelado: diaCancelado)` y no sigue; una clase, una asesoría o el docente siguen por sus ramas de siempre.

**Cinco decisiones de esta tarea, para que nadie las deshaga sin querer:**

1. **Un día cancelado se devuelve al patrón desde su propia hoja.** La spec lo pide así: «si el día está cancelado o movido, la hoja ofrece volver al patrón» (RF-BLQ-5). El servidor no manda un día cancelado entre las ocurrencias (RS-BE-33), así que la Tarea 4 lo pinta tenue desde la excepción de la regla (`bloquesCanceladosDelDia`) y lo marca con `diaCancelado`. Al tocarlo, la hoja ofrece una sola acción, **Volver al patrón** (`clearException` con su fecha): ese día no se edita, no se cancela otra vez ni se le cambia la hora. En un día movido, «Volver al patrón» sale junto a las demás. Además, el aviso «Se canceló este día.» trae un **Deshacer** que deja el día **como estaba**, no siempre en el patrón: si seguía el patrón llama a `clearException`; si ya estaba movido, vuelve a fijar su `moved` con las horas que tenía (el `PUT` de una ocurrencia reemplaza la excepción de esa fecha). Es un atajo: el aviso se cierra solo (decisión 4), y pasado eso el día se sigue devolviendo desde su hoja.
2. **La hoja devuelve la acción y la ejecuta quien la abrió.** Los diálogos que siguen (cambiar la hora, confirmar el borrado) se abren con el contexto del **navegador**, y los avisos con el **messenger**, los dos tomados antes del primer `await`. El `context` que llega de `_courseBlock` es el del `LayoutBuilder` de una de las dos vistas: si la alumna gira el teléfono con la hoja abierta, la grilla cambia de vista y ese contexto deja de estar montado. Con él, la acción elegida fallaría o no haría nada.
3. **Las dos listas de orientación se repiten en la hoja.** `HorarioPage._portraitOnly` y `_scheduleOrientations` (`horario.dart:83-90` hoy) son privadas de esa pantalla, y la hoja vive en otro archivo. Se copian como `_soloVertical` y `_orientacionesDelHorario`, con un comentario que apunta a las originales: editar desde la hoja fija el vertical antes de abrir `/bloque` y devuelve la rotación al volver, igual que el toque de un curso y el botón de agregar de la Tarea 5 ("Schedule-only rotation", `specs/features/schedule/schedule.spec.md:36`).
4. **El aviso con «Deshacer» se cierra solo, y cada aviso de la hoja reemplaza al que esté en pantalla.** Desde Flutter 3.38 (la CI usa 3.44.2 y esta Mac 3.47.2) un `SnackBar` con botón trae `persist: true` por omisión y no se cierra solo: quedaba de pantalla en pantalla, y el `ScaffoldMessenger` ponía en cola detrás de él los avisos de las otras pantallas. Por eso el de «Deshacer» lleva `persist: false` y se va a los 4 s (el día cancelado se sigue devolviendo desde su hoja); la prueba «el aviso con "Deshacer" se cierra solo…» lo fija. Y un aviso que llega mientras otro está en pantalla también esperaría en cola, así que `_avisar` hace `hideCurrentSnackBar()` y después `showSnackBar`; la prueba «un aviso nuevo reemplaza al de "Deshacer"» lo fija.
5. **El diálogo de «Cambiar la hora solo este día» pone las dos horas lado a lado y scrollea.** La hoja también se abre desde la vista semanal, en horizontal, y en un iPhone SE eso deja 375 px de alto: con las dos horas una debajo de la otra, el diálogo desbordaba 57 px y el campo de la hora de fin no recibía el toque. Lado a lado es lo mismo que hace el formulario (`time_block_form_page.dart`, «4. Horas»), y `scrollable: true` cubre la letra grande. La prueba «cambiar la hora cabe en un iPhone SE en horizontal» lo fija.

- [ ] **Paso 1: Escribir la prueba que falla**

Crear `test/HU35_jeff/time_blocks_acciones_test.dart` (la carpeta ya existe desde la Tarea 1) con este contenido:

```dart
// test/HU35_jeff/time_blocks_acciones_test.dart
//
// WIDGET + UNITARIA — HU35 (bloques de horario propios): tocar un bloque
// propio (RF-BLQ-5). La hoja de acciones, lo que cada acción le pide al
// service, y la rama nueva del toque en el horario: un bloque propio abre su
// hoja y una clase sigue yendo al detalle de su curso.
// Pantallas: lib/pages/time_blocks/time_block_actions_sheet.dart y el toque de
// lib/pages/horario/horario.dart.
//
// Todos los datos son inventados; el repo es público. La alumna es la
// 20230001, el bloque "Prácticas de prueba" no existe y el curso es "CURSO DE
// PRUEBA A", sección 801: nada sale del portal ni de test/HU31_jeff/fixtures.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/time_block_model.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/descripcion_cursos/descrip_cursos.dart';
import 'package:ulima_plus/pages/descripcion_cursos/descrip_cursos_controller.dart';
import 'package:ulima_plus/pages/horario/horario.dart';
import 'package:ulima_plus/pages/horario/horario_controller.dart';
import 'package:ulima_plus/pages/time_blocks/time_block_actions_sheet.dart';
import 'package:ulima_plus/pages/time_blocks/time_block_form_page.dart';
import 'package:ulima_plus/pages/time_blocks/time_block_validators.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/time_blocks_service.dart';

// --- Datos inventados ---------------------------------------------------------

UserModel _alumna() => UserModel(
      code: '20230001',
      firstName: 'Alumna',
      lastName: 'De Prueba',
      email: 'test@aloe.ulima.edu.pe',
      role: 'student',
      currentCycle: '2026-2',
      setupComplete: true,
    );

/// El bloque: lunes y miércoles de 14:00 a 18:00. El miércoles 23 ya se
/// movió a 15:00-19:00.
const TimeBlockRule _regla = TimeBlockRule(
  id: 7,
  title: 'Prácticas de prueba',
  colorHex: '#27AE60',
  daysOfWeek: <int>[1, 3],
  startTime: '14:00',
  endTime: '18:00',
  startDate: '2026-09-01',
  endDate: '2026-12-15',
  exceptions: <TimeBlockException>[
    TimeBlockException(
      date: '2026-09-23',
      status: 'moved',
      startTime: '15:00',
      endTime: '19:00',
    ),
  ],
);

/// El lunes 21: un día como cualquier otro del patrón.
const TimeBlockOccurrence _lunes21 = TimeBlockOccurrence(
  blockId: 7,
  title: 'Prácticas de prueba',
  colorHex: '#27AE60',
  date: '2026-09-21',
  dayOfWeek: 1,
  startTime: '14:00',
  endTime: '18:00',
  moved: false,
);

/// El miércoles 23, tal como lo manda el servidor: con sus horas nuevas y
/// `moved: true`.
const TimeBlockOccurrence _miercoles23Movido = TimeBlockOccurrence(
  blockId: 7,
  title: 'Prácticas de prueba',
  colorHex: '#27AE60',
  date: '2026-09-23',
  dayOfWeek: 3,
  startTime: '15:00',
  endTime: '19:00',
  moved: true,
);

/// El mismo bloque con el lunes 21 cancelado: el servidor no manda esa
/// ocurrencia, y la grilla lo pinta tenue desde la excepción de la regla
/// (Tarea 4).
const TimeBlockRule _reglaConLunes21Cancelado = TimeBlockRule(
  id: 7,
  title: 'Prácticas de prueba',
  colorHex: '#27AE60',
  daysOfWeek: <int>[1, 3],
  startTime: '14:00',
  endTime: '18:00',
  startDate: '2026-09-01',
  endDate: '2026-12-15',
  exceptions: <TimeBlockException>[
    TimeBlockException(
      date: '2026-09-21',
      status: 'cancelled',
      startTime: null,
      endTime: null,
    ),
  ],
);

/// Una clase como la devuelve `coursesForDay`: sección y horario aplanados,
/// con las horas en 12 h como las manda `/schedule/me/sessions`.
Map<String, dynamic> _clase(String curso, String inicio, String fin) =>
    <String, dynamic>{
      'idSeccion': '801',
      'codigoSeccion': '801',
      'curso': curso,
      'hora_inicio': inicio,
      'hora_fin': fin,
      'salon': 'AULA 801',
      'color': '#2F80ED',
      'isEvaluation': false,
      'isAdvising': false,
    };

/// La semana del lunes 21 al domingo 27 de septiembre de 2026, con lo que
/// arma el backend para cada día ("21 de Septiembre", `isoDate`
/// "2026-09-21"). La grilla ubica los bloques por `isoDate` (Tarea 4).
List<DaySchedule> _semana() => <DaySchedule>[
      for (final (nombre, dia) in const <(String, int)>[
        ('Lunes', 21),
        ('Martes', 22),
        ('Miércoles', 23),
        ('Jueves', 24),
        ('Viernes', 25),
        ('Sábado', 26),
        ('Domingo', 27),
      ])
        DaySchedule(
          nombre,
          '$dia de Septiembre',
          'Semana 5 del ciclo',
          isoDate: '2026-09-$dia',
        ),
    ];

// --- Dobles -------------------------------------------------------------------

class _FakeAuthService extends AuthService {
  _FakeAuthService(UserModel? user) : userRx = Rx<UserModel?>(user);

  final Rx<UserModel?> userRx;

  @override
  UserModel? get currentUser => userRx.value;

  @override
  Rx<UserModel?> get currentUserRx => userRx;

  @override
  Future<void> refreshCurrentUser() async {}
}

/// Cliente que no sale a la red: si algo de la hoja lo llamara, la prueba
/// revienta en vez de pegarle a un backend.
class _ApiSinRed extends ApiClient {
  _ApiSinRed() : super(configuredBaseUrl: 'http://test');

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    String? token,
    Map<String, String?> query = const {},
    bool suppressSessionExpiry = false,
  }) =>
      throw StateError('La hoja no debe pedir $path');
}

/// Doble del service: sirve reglas y ocurrencias fijas y anota cada
/// escritura en [llamadas], sin HTTP. La recarga que el service real hace
/// después de escribir no se simula: la hoja no depende de ella.
class _FakeTimeBlocksService extends TimeBlocksService {
  _FakeTimeBlocksService({
    this.reglas = const <TimeBlockRule>[_regla],
    List<TimeBlockOccurrence> ocurrencias = const <TimeBlockOccurrence>[],
  })  : _snapshot = TimeBlocksSnapshot(
          occurrences: ocurrencias,
          weeks: const <TimeBlockWeek>[],
        ),
        super(apiClient: _ApiSinRed());

  final List<TimeBlockRule> reglas;
  final TimeBlocksSnapshot _snapshot;

  /// Cada escritura, como "método id fecha …", en orden.
  final llamadas = <String>[];

  /// Si no es null, toda escritura lo lanza.
  Object? falla;

  @override
  List<TimeBlockRule> get blocks => reglas;

  @override
  TimeBlocksSnapshot? get snapshot => _snapshot;

  Future<void> _anotar(String llamada) async {
    if (falla != null) throw falla!;
    llamadas.add(llamada);
  }

  @override
  Future<void> setException(
    int id,
    String date, {
    required String status,
    String? startTime,
    String? endTime,
  }) =>
      _anotar('setException $id $date $status $startTime $endTime');

  @override
  Future<void> clearException(int id, String date) =>
      _anotar('clearException $id $date');

  @override
  Future<void> remove(int id) => _anotar('remove $id');
}

/// El controller del horario sin su carga remota: días y clases sembrados, y
/// el reloj fijo en el 1 de septiembre (así no se pinta la línea de "ahora").
/// `bloquesDelDia` es el real de la Tarea 4: lee el service.
class _HorarioDePrueba extends HorarioController {
  _HorarioDePrueba({required this.clasesDelLunes}) {
    daysList.assignAll(_semana());
    currentLimaTime.value = DateTime.utc(2026, 9, 1, 10);
  }

  final List<Map<String, dynamic>> clasesDelLunes;

  @override
  // ignore: must_call_super
  void onInit() {
    // Sin el onInit real: arranca un Timer.periodic de un minuto y pide el
    // horario con un ApiClient propio. Mismo recurso que la Tarea 4.
  }

  @override
  List<Map<String, dynamic>> coursesForDay(DaySchedule activeDay) =>
      activeDay.dayName == 'Lunes'
          ? clasesDelLunes
          : const <Map<String, dynamic>>[];
}

/// El detalle del curso sin su carga: `DescripCursosPage` hace
/// `Get.put(DescripCursosController())` al construirse y GetX no reemplaza
/// una instancia ya registrada, así que usa esta y no pide nada.
class _DetalleSinCarga extends DescripCursosController {
  @override
  Future<void> cargarDatosCurso(String idSeccion) async {}
}

// --- Montaje ------------------------------------------------------------------

/// Lo que la app le pidió a `SystemChrome.setPreferredOrientations`, en orden.
final _orientaciones = <List<Object?>>[];

/// Lo que recibió la ruta /bloque en `Get.arguments`.
Object? _argumentoDelFormulario;

/// Vertical y horizontal, como en la Tarea 4: el vertical es más ancho que un
/// teléfono porque la fuente de las pruebas dibuja cada letra como un
/// cuadrado y la franja del día desbordaría.
const Size _vertical = Size(600, 1000);
const Size _horizontal = Size(1000, 500);

/// Un iPhone SE (375 x 667), en píxeles físicos con `devicePixelRatio` 2: en
/// vertical para la hoja, y en horizontal (375 de alto) como queda al tocar un
/// bloque desde la vista semanal.
const Size _seVertical = Size(750, 1334);
const Size _seHorizontal = Size(1334, 750);

/// Monta el horario de una alumna con el lunes 21 activo: por omisión, el
/// bloque propio de 14:00 a 18:00 y, si se pide, una clase.
Future<_FakeTimeBlocksService> _montarHorario(
  WidgetTester tester, {
  required Size pantalla,
  List<Map<String, dynamic>> clases = const <Map<String, dynamic>>[],
  List<TimeBlockRule> reglas = const <TimeBlockRule>[_regla],
  List<TimeBlockOccurrence> ocurrencias = const <TimeBlockOccurrence>[_lunes21],
}) async {
  tester.view.physicalSize = pantalla;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  Get.put<AuthService>(_FakeAuthService(_alumna()));
  final service = _FakeTimeBlocksService(
    reglas: reglas,
    ocurrencias: ocurrencias,
  );
  Get.put<TimeBlocksService>(service);
  Get.put<HorarioController>(_HorarioDePrueba(clasesDelLunes: clases));

  await tester.pumpWidget(const GetMaterialApp(home: HorarioPage()));
  await tester.pump();
  return service;
}

/// El bloque del horario que lleva ese título: su [InkWell], que es lo que
/// se toca.
Finder _bloque(String titulo) =>
    find.ancestor(of: find.text(titulo), matching: find.byType(InkWell));

/// App mínima: un botón que abre la hoja como lo hace el toque del horario,
/// y la ruta /bloque, que anota el argumento con que se abrió.
Widget _app(TimeBlockOccurrence ocurrencia, {bool cancelado = false}) =>
    GetMaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => mostrarAccionesDeBloque(
                context,
                ocurrencia,
                cancelado: cancelado,
              ),
              child: const Text('ABRIR'),
            ),
          ),
        ),
      ),
      getPages: [
        GetPage(
          name: '/bloque',
          page: () {
            _argumentoDelFormulario = Get.arguments;
            return const Scaffold(body: Text('FORMULARIO'));
          },
        ),
      ],
    );

/// Pantalla de un iPhone SE (en vertical, si no se pide otra), registra el
/// service y abre la hoja de [ocurrencia] (de un día cancelado, si
/// [cancelado]).
Future<_FakeTimeBlocksService> _abrirHoja(
  WidgetTester tester, {
  required TimeBlockOccurrence ocurrencia,
  List<TimeBlockRule> reglas = const <TimeBlockRule>[_regla],
  Size pantalla = _seVertical,
  bool cancelado = false,
}) async {
  tester.view.physicalSize = pantalla;
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);

  final service = _FakeTimeBlocksService(reglas: reglas);
  Get.put<TimeBlocksService>(service);
  await tester.pumpWidget(_app(ocurrencia, cancelado: cancelado));
  await tester.tap(find.text('ABRIR'));
  await tester.pumpAndSettle();
  return service;
}

/// Toca una acción de la hoja; si la hoja scrollea, primero la trae a la
/// vista.
Future<void> _tocar(WidgetTester tester, String texto) async {
  await tester.ensureVisible(find.text(texto));
  await tester.tap(find.text(texto));
  await tester.pumpAndSettle();
}

/// Elige una hora con el picker de Flutter. El dial no es lo que se prueba:
/// se pasa a escribirla, en 24 h. Si el diálogo scrollea, primero trae el
/// campo a la vista.
Future<void> _elegirHora(
  WidgetTester tester,
  Key campo, {
  required String hora,
  required String minuto,
}) async {
  await tester.ensureVisible(find.byKey(campo));
  await tester.tap(find.byKey(campo));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.keyboard_outlined));
  await tester.pumpAndSettle();
  final campos = find.descendant(
    of: find.byType(TimePickerDialog),
    matching: find.byType(TextField),
  );
  await tester.enterText(campos.at(0), hora);
  await tester.enterText(campos.at(1), minuto);
  // El botón de aceptar va en español, como en el formulario (D7).
  await tester.tap(find.text(TimeBlockFormPage.pickerAceptar));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.reset();
    _orientaciones.clear();
    _argumentoDelFormulario = null;
    // Doble del canal de plataforma, como en la Tarea 5: sin él,
    // `setPreferredOrientations` espera una respuesta que en la prueba no
    // llega nunca. Responde al toque y anota las orientaciones pedidas.
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
    Get.reset();
  });

  group('UNITARIA · el resumen del día en la hoja (RF-BLQ-5)', () {
    test('nombra el día, la fecha y las horas', () {
      expect(
        resumenDelDia(_lunes21),
        'Lunes 21 de septiembre, 14:00 a 18:00',
      );
    });

    test('un día movido se resume con sus horas nuevas', () {
      expect(
        resumenDelDia(_miercoles23Movido),
        'Miércoles 23 de septiembre, 15:00 a 19:00',
      );
    });

    test('una fecha ilegible no inventa un día: quedan las horas', () {
      const sinFecha = TimeBlockOccurrence(
        blockId: 7,
        title: 'Prácticas de prueba',
        colorHex: '#27AE60',
        date: '',
        dayOfWeek: 0,
        startTime: '14:00',
        endTime: '18:00',
        moved: false,
      );
      expect(resumenDelDia(sinFecha), '14:00 a 18:00');
    });
  });

  group('WIDGET · tocar un bloque en el horario (RF-BLQ-5)', () {
    testWidgets('tocar un bloque propio abre su hoja, no el detalle de un curso',
        (tester) async {
      await _montarHorario(
        tester,
        pantalla: _vertical,
        clases: [_clase('CURSO DE PRUEBA A', '08:00 am', '10:00 am')],
      );

      await tester.tap(_bloque('PRÁCTICAS DE PRUEBA'));
      await tester.pumpAndSettle();

      expect(find.byType(TimeBlockActionsSheet), findsOneWidget);
      // El nombre como lo escribió la alumna, y qué día es.
      expect(find.text('Prácticas de prueba'), findsOneWidget);
      expect(find.text(resumenDelDia(_lunes21)), findsOneWidget);
      expect(find.byType(DescripCursosPage), findsNothing);
      // Abrir la hoja no toca la orientación: solo el formulario la fija.
      expect(_orientaciones, isEmpty);
    });

    testWidgets('en la vista semanal también abre la hoja, y la hoja cabe',
        (tester) async {
      // 500 px de alto: la hoja modal mide como mucho 9/16 de eso y sus
      // acciones no entran sin scroll. Un desborde haría fallar la prueba.
      await _montarHorario(tester, pantalla: _horizontal);

      await tester.tap(_bloque('PRÁCTICAS DE PRUEBA'));
      await tester.pumpAndSettle();

      expect(find.byType(TimeBlockActionsSheet), findsOneWidget);
      await tester.ensureVisible(find.text(TimeBlockActionsSheet.borrar));
      expect(find.text(TimeBlockActionsSheet.borrar), findsOneWidget);
    });

    testWidgets('tocar una clase sigue llevando al detalle del curso, sin hoja',
        (tester) async {
      Get.put<DescripCursosController>(_DetalleSinCarga());
      await _montarHorario(
        tester,
        pantalla: _vertical,
        clases: [_clase('CURSO DE PRUEBA A', '08:00 am', '10:00 am')],
      );

      await tester.tap(_bloque('CURSO DE PRUEBA A'));
      await tester.pump();
      // Sin pumpAndSettle: el detalle sin datos pinta un SkeletonPulse que
      // anima sin fin.
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(TimeBlockActionsSheet), findsNothing);
      expect(find.byType(DescripCursosPage), findsOneWidget);
      expect(_orientaciones, [
        ['DeviceOrientation.portraitUp'],
      ]);
    });

    testWidgets('tocar un día cancelado abre su hoja, solo con volver al patrón',
        (tester) async {
      // RF-BLQ-5: «si el día está cancelado o movido, la hoja ofrece volver
      // al patrón». El lunes 21 está cancelado: no llega como ocurrencia, y la
      // grilla lo pinta tenue desde la regla (Tarea 4).
      final service = await _montarHorario(
        tester,
        pantalla: _vertical,
        reglas: const <TimeBlockRule>[_reglaConLunes21Cancelado],
        ocurrencias: const <TimeBlockOccurrence>[],
      );

      await tester.tap(_bloque('PRÁCTICAS DE PRUEBA'));
      await tester.pumpAndSettle();

      expect(find.byType(TimeBlockActionsSheet), findsOneWidget);
      expect(find.text(TimeBlockActionsSheet.volverAlPatron), findsOneWidget);
      expect(find.text(TimeBlockActionsSheet.cancelarDia), findsNothing);
      await _tocar(tester, TimeBlockActionsSheet.volverAlPatron);

      expect(service.llamadas, ['clearException 7 2026-09-21']);
    });
  });

  group('WIDGET · la hoja de acciones de un bloque propio (RF-BLQ-5)', () {
    testWidgets(
        'un día normal ofrece editar, cancelar, cambiar la hora y borrar, sin volver al patrón',
        (tester) async {
      final service = await _abrirHoja(tester, ocurrencia: _lunes21);

      for (final texto in const [
        TimeBlockActionsSheet.editar,
        TimeBlockActionsSheet.editarDetalle,
        TimeBlockActionsSheet.cancelarDia,
        TimeBlockActionsSheet.cambiarHora,
        TimeBlockActionsSheet.borrar,
      ]) {
        expect(find.text(texto), findsOneWidget, reason: texto);
      }
      expect(find.text(TimeBlockActionsSheet.volverAlPatron), findsNothing);
      // Abrir la hoja no escribe nada.
      expect(service.llamadas, isEmpty);
    });

    testWidgets('un día movido ofrece volver al patrón, y lo devuelve',
        (tester) async {
      final service = await _abrirHoja(tester, ocurrencia: _miercoles23Movido);

      expect(find.text(TimeBlockActionsSheet.volverAlPatron), findsOneWidget);
      await _tocar(tester, TimeBlockActionsSheet.volverAlPatron);

      expect(find.byType(TimeBlockActionsSheet), findsNothing);
      expect(service.llamadas, ['clearException 7 2026-09-23']);
    });

    testWidgets(
        'la hoja de un día cancelado ofrece solo volver al patrón, y llama a clearException con su fecha',
        (tester) async {
      final service = await _abrirHoja(
        tester,
        ocurrencia: _lunes21,
        cancelado: true,
      );

      expect(find.text(TimeBlockActionsSheet.volverAlPatron), findsOneWidget);
      expect(
        find.text(TimeBlockActionsSheet.diaCanceladoDetalle),
        findsOneWidget,
      );
      for (final texto in const [
        TimeBlockActionsSheet.editar,
        TimeBlockActionsSheet.cancelarDia,
        TimeBlockActionsSheet.cambiarHora,
        TimeBlockActionsSheet.borrar,
      ]) {
        expect(find.text(texto), findsNothing, reason: texto);
      }

      await _tocar(tester, TimeBlockActionsSheet.volverAlPatron);

      expect(find.byType(TimeBlockActionsSheet), findsNothing);
      expect(service.llamadas, ['clearException 7 2026-09-21']);
    });

    testWidgets('editar abre /bloque con la regla del bloque, en vertical',
        (tester) async {
      final service = await _abrirHoja(tester, ocurrencia: _miercoles23Movido);

      await _tocar(tester, TimeBlockActionsSheet.editar);

      expect(Get.currentRoute, '/bloque');
      // La REGLA, no la ocurrencia: el formulario edita todas las semanas.
      expect(_argumentoDelFormulario, same(_regla));
      expect(_orientaciones, [
        ['DeviceOrientation.portraitUp'],
      ]);

      Get.back<dynamic>();
      await tester.pumpAndSettle();
      // Al volver, el horario recupera su rotación.
      expect(_orientaciones.last, [
        'DeviceOrientation.portraitUp',
        'DeviceOrientation.landscapeLeft',
        'DeviceOrientation.landscapeRight',
      ]);
      // Editar lo guarda el formulario, no la hoja.
      expect(service.llamadas, isEmpty);
    });

    testWidgets('sin la regla del bloque a mano no ofrece editar',
        (tester) async {
      await _abrirHoja(
        tester,
        ocurrencia: _lunes21,
        reglas: const <TimeBlockRule>[],
      );

      expect(find.text(TimeBlockActionsSheet.editar), findsNothing);
      expect(find.text(TimeBlockActionsSheet.cancelarDia), findsOneWidget);
    });

    testWidgets('cancelar solo este día manda la fecha de ese día',
        (tester) async {
      final service = await _abrirHoja(tester, ocurrencia: _lunes21);

      await _tocar(tester, TimeBlockActionsSheet.cancelarDia);

      expect(service.llamadas, ['setException 7 2026-09-21 cancelled null null']);
      expect(find.text(TimeBlockActionsSheet.diaCancelado), findsOneWidget);
    });

    testWidgets('la cancelación se deshace desde el aviso: el día vuelve al patrón',
        (tester) async {
      // Un atajo: el día cancelado también se devuelve desde su hoja (se
      // pinta tenue), pero justo después de cancelarlo basta con Deshacer.
      final service = await _abrirHoja(tester, ocurrencia: _lunes21);
      await _tocar(tester, TimeBlockActionsSheet.cancelarDia);

      await tester.tap(find.text(TimeBlockActionsSheet.deshacer));
      await tester.pumpAndSettle();

      expect(service.llamadas, [
        'setException 7 2026-09-21 cancelled null null',
        'clearException 7 2026-09-21',
      ]);
    });

    testWidgets(
        'deshacer la cancelación de un día movido lo devuelve a sus horas movidas',
        (tester) async {
      // Deshacer deja el día como estaba, no en el patrón: el miércoles 23 ya
      // iba de 15:00 a 19:00.
      final service = await _abrirHoja(tester, ocurrencia: _miercoles23Movido);
      await _tocar(tester, TimeBlockActionsSheet.cancelarDia);

      await tester.tap(find.text(TimeBlockActionsSheet.deshacer));
      await tester.pumpAndSettle();

      expect(service.llamadas, [
        'setException 7 2026-09-23 cancelled null null',
        'setException 7 2026-09-23 moved 15:00 19:00',
      ]);
    });

    testWidgets('un error del servidor se muestra tal cual llega',
        (tester) async {
      final service = await _abrirHoja(tester, ocurrencia: _lunes21);
      service.falla = const TimeBlocksFailure('Mensaje inventado del servidor.');

      await _tocar(tester, TimeBlockActionsSheet.cancelarDia);

      expect(find.text('Mensaje inventado del servidor.'), findsOneWidget);
      expect(find.text(TimeBlockActionsSheet.diaCancelado), findsNothing);
      expect(service.llamadas, isEmpty);
    });

    testWidgets('un fallo sin mensaje del servidor también avisa',
        (tester) async {
      final service = await _abrirHoja(tester, ocurrencia: _lunes21);
      service.falla = StateError('inesperado');

      await _tocar(tester, TimeBlockActionsSheet.borrar);
      await tester.tap(find.text(TimeBlockActionsSheet.borrarConfirmar));
      await tester.pumpAndSettle();

      expect(find.text(TimeBlocksService.genericErrorMessage), findsOneWidget);
      expect(service.llamadas, isEmpty);
    });

    testWidgets('el aviso con "Deshacer" se cierra solo: no queda de pantalla en pantalla',
        (tester) async {
      // Desde Flutter 3.38 un SnackBar con botón se queda por omisión hasta
      // que lo tocan, y deja en cola los avisos de las otras pantallas. El de
      // Deshacer lleva persist: false y se va a los 4 s.
      await _abrirHoja(tester, ocurrencia: _lunes21);
      await _tocar(tester, TimeBlockActionsSheet.cancelarDia);
      expect(find.text(TimeBlockActionsSheet.diaCancelado), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(find.text(TimeBlockActionsSheet.diaCancelado), findsNothing);
    });

    testWidgets('un aviso nuevo reemplaza al de "Deshacer"', (tester) async {
      // Mientras un aviso está en pantalla, el messenger pone en cola lo que
      // llega después: sin reemplazarlo, este error esperaría a que el de
      // Deshacer se fuera.
      final service = await _abrirHoja(tester, ocurrencia: _lunes21);
      await _tocar(tester, TimeBlockActionsSheet.cancelarDia);
      expect(find.text(TimeBlockActionsSheet.diaCancelado), findsOneWidget);

      service.falla = const TimeBlocksFailure('Mensaje inventado del servidor.');
      await tester.tap(find.text('ABRIR'));
      await tester.pumpAndSettle();
      await _tocar(tester, TimeBlockActionsSheet.borrar);
      await tester.tap(find.text(TimeBlockActionsSheet.borrarConfirmar));
      await tester.pumpAndSettle();

      expect(find.text('Mensaje inventado del servidor.'), findsOneWidget);
      expect(find.text(TimeBlockActionsSheet.diaCancelado), findsNothing);
    });

    testWidgets(
        'cambiar la hora usa los pickers del formulario y los mismos validadores',
        (tester) async {
      tester.platformDispatcher.alwaysUse24HourFormatTestValue = true;
      addTearDown(tester.platformDispatcher.clearAlwaysUse24HourTestValue);
      final service = await _abrirHoja(tester, ocurrencia: _lunes21);

      await _tocar(tester, TimeBlockActionsSheet.cambiarHora);

      // Arranca con las horas de ese día.
      expect(find.byKey(TimeBlockActionsSheet.cambiarHoraKey), findsOneWidget);
      expect(find.text('14:00'), findsOneWidget);
      expect(find.text('18:00'), findsOneWidget);

      // Terminar a la 1 pm, antes de empezar: no guarda y dice por qué.
      await _elegirHora(
        tester,
        TimeBlockActionsSheet.horaFinKey,
        hora: '13',
        minuto: '00',
      );
      expect(find.text('13:00'), findsOneWidget);
      await tester.tap(find.text(TimeBlockActionsSheet.guardarLabel));
      await tester.pumpAndSettle();
      expect(find.text(validarHoras('14:00', '13:00')!), findsOneWidget);
      expect(service.llamadas, isEmpty);

      // Hasta las 7:30 pm sí: ese día queda movido y el patrón no cambia.
      await _elegirHora(
        tester,
        TimeBlockActionsSheet.horaFinKey,
        hora: '19',
        minuto: '30',
      );
      await tester.tap(find.text(TimeBlockActionsSheet.guardarLabel));
      await tester.pumpAndSettle();

      expect(find.byKey(TimeBlockActionsSheet.cambiarHoraKey), findsNothing);
      expect(service.llamadas, ['setException 7 2026-09-21 moved 14:00 19:30']);
    });

    testWidgets('cambiar la hora cabe en un iPhone SE en horizontal',
        (tester) async {
      // Desde la vista semanal también se toca un bloque, y ahí quedan 375 px
      // de alto. Un desborde haría fallar la prueba.
      tester.platformDispatcher.alwaysUse24HourFormatTestValue = true;
      addTearDown(tester.platformDispatcher.clearAlwaysUse24HourTestValue);
      final service = await _abrirHoja(
        tester,
        ocurrencia: _lunes21,
        pantalla: _seHorizontal,
      );

      await _tocar(tester, TimeBlockActionsSheet.cambiarHora);
      await _elegirHora(
        tester,
        TimeBlockActionsSheet.horaFinKey,
        hora: '13',
        minuto: '00',
      );
      await tester.tap(find.text(TimeBlockActionsSheet.guardarLabel));
      await tester.pumpAndSettle();

      // El porqué se ve: no queda escondido debajo del borde.
      expect(
        find.text(validarHoras('14:00', '13:00')!).hitTestable(),
        findsOneWidget,
      );
      expect(service.llamadas, isEmpty);
    });

    testWidgets('borrar pide confirmación, y "Cancelar" no borra',
        (tester) async {
      final service = await _abrirHoja(tester, ocurrencia: _lunes21);

      await _tocar(tester, TimeBlockActionsSheet.borrar);

      expect(find.byKey(TimeBlockActionsSheet.confirmarBorradoKey), findsOneWidget);
      expect(find.text(TimeBlockActionsSheet.borrarTitulo), findsOneWidget);
      // Dice que se va el bloque entero, con todos sus días.
      final cuerpo = TimeBlockActionsSheet.borrarCuerpo('Prácticas de prueba');
      expect(cuerpo, contains('todos sus días'));
      expect(find.text(cuerpo), findsOneWidget);

      await tester.tap(find.text(TimeBlockActionsSheet.cancelarLabel));
      await tester.pumpAndSettle();

      expect(find.byKey(TimeBlockActionsSheet.confirmarBorradoKey), findsNothing);
      expect(service.llamadas, isEmpty);
    });

    testWidgets('confirmar el borrado borra el bloque entero', (tester) async {
      final service = await _abrirHoja(tester, ocurrencia: _lunes21);

      await _tocar(tester, TimeBlockActionsSheet.borrar);
      await tester.tap(find.text(TimeBlockActionsSheet.borrarConfirmar));
      await tester.pumpAndSettle();

      expect(service.llamadas, ['remove 7']);
    });
  });
}
```

Qué fija cada prueba, para que nadie las recorte:

- **El resumen (3, unitarias):** la cabecera de la hoja dice qué día es y a qué hora; un día movido se resume con sus horas nuevas; una fecha ilegible no inventa un día.
- **El toque en el horario (4):** un bloque propio abre su hoja y no navega ni fija la orientación; en la vista semanal (500 px de alto) también la abre y sus acciones se alcanzan con scroll, sin desbordar; una clase sigue yendo al detalle de su curso, sin hoja; y un **día cancelado** (pintado tenue por la Tarea 4) abre su hoja con solo «volver al patrón», que llama a `clearException` con su fecha. La de la clase es **de regresión**: pasa desde el primer momento, porque el camino de las clases no cambia, y tiene que seguir pasando al final.
- **La hoja (16):** un día normal ofrece las cuatro acciones y no «volver al patrón»; uno movido sí, y al tocarlo llama a `clearException` con su fecha; uno **cancelado** ofrece solo «volver al patrón», con su detalle, y lo devuelve; editar abre `/bloque` con **la misma regla** del service (`same`), fija el vertical y devuelve la rotación al volver; sin la regla a mano no se ofrece editar; cancelar manda **la fecha de ese día** y avisa; el aviso deshace la cancelación, y en un día que ya estaba movido lo devuelve a **sus horas movidas**, no al patrón; un error del servidor se muestra tal cual y uno sin mensaje también avisa; el aviso de «Deshacer» **se cierra solo** a los 4 s; un aviso nuevo **reemplaza** al de «Deshacer»; cambiar la hora arranca con las horas del día, usa el picker de Flutter, rechaza con **el mensaje de `validarHoras`** y guarda un día `moved`; ese diálogo **cabe en un iPhone SE en horizontal** y su error se ve; borrar pide confirmación y «Cancelar» no borra; confirmar borra el bloque entero.

`_elegirHora` trae el campo a la vista, pasa el picker de Flutter a modo texto (el ícono del teclado) y escribe la hora en 24 h (`alwaysUse24HourFormatTestValue`): el dial no es lo que se prueba, y así la prueba elige cualquier hora sin depender de coordenadas del reloj.

- [ ] **Paso 2: Correr la prueba y ver que falla**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test test/HU35_jeff/time_blocks_acciones_test.dart
```

Esperado: **FALLA al compilar**, antes de correr ninguna prueba. Los primeros errores son estos (las rutas pueden salir absolutas):

```
test/HU35_jeff/time_blocks_acciones_test.dart:24:8: Error: Error when reading 'lib/pages/time_blocks/time_block_actions_sheet.dart': No such file or directory
test/HU35_jeff/time_blocks_acciones_test.dart:322:32: Error: Method not found: 'mostrarAccionesDeBloque'.
test/HU35_jeff/time_blocks_acciones_test.dart:426:9: Error: Method not found: 'resumenDelDia'.
```

En total son 71 errores (la salida los repite en el resumen final), todos de cuatro tipos: el archivo que no existe (1), `Method not found: 'mostrarAccionesDeBloque'` (1), `Method not found: 'resumenDelDia'` (4) y `Undefined name 'TimeBlockActionsSheet'` (65). Esas cifras y los números de línea se midieron con `flutter test` (3.47.2) sobre el archivo del Paso 1 y las Tareas 1 a 5 tal como están escritas; si la redacción del compilador cambia, vale que sean esos cuatro tipos. Termina con `00:00 +0 -1: Some tests failed.` y la falla figura como `loading …/time_blocks_acciones_test.dart`.

Cualquier otro error quiere decir que una tarea anterior no dejó lo que esta consume, y hay que **PARAR** y reportarlo. Por ejemplo: `Undefined name 'TimeBlockOccurrence'` o `Type 'TimeBlocksSnapshot' not found` (Tarea 1), `Method not found: 'validarHoras'` (Tarea 2) o `The method 'bloquesDelDia' isn't defined` (Tarea 4). Lo que consume de la Tarea 5 (`TimeBlockPickerField`, `fmtHora`, `horaDeTexto`) solo lo usa la hoja, así que un hueco ahí no sale aquí sino en el punto de control 3.b.

- [ ] **Paso 3: Implementación mínima**

**3.a — Crear `lib/pages/time_blocks/time_block_actions_sheet.dart`:**

```dart
// lib/pages/time_blocks/time_block_actions_sheet.dart
// RF-BLQ-5: lo que pasa al tocar un bloque propio en el horario. Una hoja con
// lo que se puede hacer con ESE día y con el bloque entero:
//   - Editar el bloque (todas las semanas): abre /bloque con la regla.
//   - Cancelar solo este día.
//   - Cambiar la hora solo este día.
//   - Volver al patrón, solo si ese día ya se salió de él.
//   - Borrar el bloque, con confirmación.
//
// No habla HTTP: cada acción llama a TimeBlocksService, que recarga la ventana
// del horario al terminar, así que la grilla se entera sola. Un error se
// muestra con el mensaje que llegó del servidor, tal cual (RF-BLQ-2).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../configs/themes.dart';
import '../../models/time_block_model.dart';
import '../../services/time_blocks_service.dart';
import 'time_block_form_controller.dart';
import 'time_block_form_page.dart';
import 'time_block_validators.dart';

/// Lo que la alumna eligió en la hoja.
enum AccionDeBloque { editar, cancelarDia, cambiarHora, volverAlPatron, borrar }

/// Las mismas dos listas que `HorarioPage._portraitOnly` y
/// `HorarioPage._scheduleOrientations` (horario.dart), que son privadas de esa
/// pantalla. Solo el horario rota ("Schedule-only rotation",
/// specs/features/schedule/schedule.spec.md): el formulario se abre en vertical
/// y al volver se devuelve la rotación del horario, igual que al tocar un curso
/// o el botón de agregar.
const List<DeviceOrientation> _soloVertical = [DeviceOrientation.portraitUp];
const List<DeviceOrientation> _orientacionesDelHorario = [
  DeviceOrientation.portraitUp,
  DeviceOrientation.landscapeLeft,
  DeviceOrientation.landscapeRight,
];

const List<String> _dias = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];
const List<String> _meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// Qué día es y a qué hora, para la cabecera de la hoja:
/// "Lunes 21 de septiembre, 14:00 a 18:00". Las horas van en `HH:MM`, como en
/// el formulario. Si la fecha no se puede leer, quedan solo las horas: no se
/// inventa un día.
String resumenDelDia(TimeBlockOccurrence ocurrencia) {
  final horas = '${ocurrencia.startTime} a ${ocurrencia.endTime}';
  final fecha = DateTime.tryParse(ocurrencia.date);
  if (fecha == null) return horas;
  final dia = _dias[fecha.weekday - 1];
  return '${dia[0].toUpperCase()}${dia.substring(1)} ${fecha.day} de '
      '${_meses[fecha.month - 1]}, $horas';
}

/// Abre la hoja de acciones de [ocurrencia] y hace lo que la alumna elija.
///
/// Lo llama el toque de un bloque propio en `HorarioPage._courseBlock`.
/// [cancelado] es true cuando el bloque tocado es un día cancelado, que la
/// grilla pinta tenue desde la regla (RF-BLQ-5): su hoja solo ofrece volver
/// al patrón.
///
/// [context] tiene que ser del horario montado, y solo se usa antes del primer
/// `await`: si la alumna gira el teléfono con la hoja abierta, la grilla
/// cambia de vista y ese contexto deja de existir. El navegador y el
/// messenger de la app no cambian, así que se toman al empezar.
Future<void> mostrarAccionesDeBloque(
  BuildContext context,
  TimeBlockOccurrence ocurrencia, {
  bool cancelado = false,
}) async {
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final service = TimeBlocksService.to;
  // El formulario edita la REGLA (todas las semanas), no esta ocurrencia.
  final regla =
      service.blocks.firstWhereOrNull((b) => b.id == ocurrencia.blockId);

  final accion = await showModalBottomSheet<AccionDeBloque>(
    context: context,
    builder: (_) => TimeBlockActionsSheet(
      ocurrencia: ocurrencia,
      puedeEditar: regla != null,
      cancelado: cancelado,
    ),
  );
  if (accion == null) return;

  final id = ocurrencia.blockId;
  final fecha = ocurrencia.date;
  switch (accion) {
    case AccionDeBloque.editar:
      if (regla == null) return;
      await SystemChrome.setPreferredOrientations(_soloVertical);
      await Get.toNamed<dynamic>('/bloque', arguments: regla);
      await SystemChrome.setPreferredOrientations(_orientacionesDelHorario);
    case AccionDeBloque.cancelarDia:
      final ok = await _intentar(
        messenger,
        () => service.setException(id, fecha, status: 'cancelled'),
      );
      if (!ok) return;
      // Un atajo: el día cancelado también se devuelve desde su hoja (la
      // grilla lo pinta tenue). Deshacer lo deja como estaba: en el patrón, o
      // en sus horas movidas si ya se había movido.
      Future<void> deshacer() => ocurrencia.moved
          ? service.setException(
              id,
              fecha,
              status: 'moved',
              startTime: ocurrencia.startTime,
              endTime: ocurrencia.endTime,
            )
          : service.clearException(id, fecha);
      _avisar(
        messenger,
        SnackBar(
          content: const Text(TimeBlockActionsSheet.diaCancelado),
          // Se cierra solo a los 4 s. Desde Flutter 3.38 un aviso con botón
          // se queda por omisión hasta que lo tocan: pasaba de pantalla en
          // pantalla y dejaba en cola los avisos de las otras.
          persist: false,
          action: SnackBarAction(
            label: TimeBlockActionsSheet.deshacer,
            onPressed: () => _intentar(messenger, deshacer),
          ),
        ),
      );
    case AccionDeBloque.cambiarHora:
      if (!navigator.mounted) return;
      final horas = await showDialog<({String inicio, String fin})>(
        context: navigator.context,
        builder: (_) => TimeBlockDayHoursDialog(
          inicio: ocurrencia.startTime,
          fin: ocurrencia.endTime,
        ),
      );
      if (horas == null) return;
      await _intentar(
        messenger,
        () => service.setException(
          id,
          fecha,
          status: 'moved',
          startTime: horas.inicio,
          endTime: horas.fin,
        ),
      );
    case AccionDeBloque.volverAlPatron:
      await _intentar(messenger, () => service.clearException(id, fecha));
    case AccionDeBloque.borrar:
      if (!navigator.mounted) return;
      final confirmar = await showDialog<bool>(
        context: navigator.context,
        builder: (ctx) => AlertDialog(
          key: TimeBlockActionsSheet.confirmarBorradoKey,
          title: const Text(TimeBlockActionsSheet.borrarTitulo),
          content: Text(TimeBlockActionsSheet.borrarCuerpo(ocurrencia.title)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(TimeBlockActionsSheet.cancelarLabel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                TimeBlockActionsSheet.borrarConfirmar,
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
      // Cerrar el diálogo con el barrier o con back devuelve null: no borra.
      if (confirmar != true) return;
      await _intentar(messenger, () => service.remove(id));
  }
}

/// Corre una escritura del service y dice si salió bien. Si falla, lo avisa
/// con el mensaje que trae el error: el del servidor, tal cual.
Future<bool> _intentar(
  ScaffoldMessengerState messenger,
  Future<void> Function() escritura,
) async {
  try {
    await escritura();
    return true;
  } on TimeBlocksFailure catch (e) {
    _avisar(messenger, SnackBar(content: Text(e.message)));
  } catch (e) {
    // Red de seguridad, como en el formulario: el service envuelve sus
    // errores en TimeBlocksFailure, pero si algo se le escapa la alumna
    // tiene que enterarse de que no se hizo.
    debugPrint('Error en una acción de bloque: $e');
    _avisar(
      messenger,
      const SnackBar(content: Text(TimeBlocksService.genericErrorMessage)),
    );
  }
  return false;
}

/// Muestra [aviso] en lugar del que esté en pantalla. El messenger pone en
/// cola lo que llega mientras otro aviso está a la vista: sin quitarlo, el
/// error de la acción siguiente esperaría a que se fuera el de «Deshacer».
void _avisar(ScaffoldMessengerState messenger, SnackBar aviso) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(aviso);
}

/// La hoja: qué bloque y qué día, y las acciones. Devuelve la elegida con
/// `Navigator.pop`; quien la abrió ([mostrarAccionesDeBloque]) la ejecuta.
class TimeBlockActionsSheet extends StatelessWidget {
  const TimeBlockActionsSheet({
    super.key,
    required this.ocurrencia,
    required this.puedeEditar,
    this.cancelado = false,
  });

  final TimeBlockOccurrence ocurrencia;

  /// Si la regla del bloque está a mano. Llega con las ocurrencias en la
  /// misma carga, así que falta solo si el service quedó a medias.
  final bool puedeEditar;

  /// Si es un día cancelado (la grilla lo pinta tenue). Entonces la hoja
  /// solo ofrece volver al patrón.
  final bool cancelado;

  static const String editar = 'Editar el bloque';
  static const String editarDetalle = 'Todas las semanas';
  static const String cancelarDia = 'Cancelar solo este día';
  static const String cambiarHora = 'Cambiar la hora solo este día';
  static const String volverAlPatron = 'Volver al patrón';
  static const String diaCanceladoDetalle = 'Este día está cancelado';
  static const String borrar = 'Borrar el bloque';

  static const String diaCancelado = 'Se canceló este día.';
  static const String deshacer = 'Deshacer';

  static const String borrarTitulo = '¿Borrar el bloque?';
  static String borrarCuerpo(String titulo) =>
      'Se borra "$titulo" con todos sus días, no solo este.';
  static const String borrarConfirmar = 'Borrar';

  /// Los dos botones de los diálogos (borrar y cambiar la hora).
  static const String cancelarLabel = 'Cancelar';
  static const String guardarLabel = 'Guardar';

  static const Key confirmarBorradoKey = Key('bloque-confirmar-borrado');
  static const Key cambiarHoraKey = Key('bloque-cambiar-hora');
  static const Key horaInicioKey = Key('bloque-dia-hora-inicio');
  static const Key horaFinKey = Key('bloque-dia-hora-fin');

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.brightnessOf(context);
    void elegir(AccionDeBloque accion) => Navigator.of(context).pop(accion);

    // SingleChildScrollView: la hoja modal mide como mucho 9/16 del alto, y
    // en la vista semanal (horizontal) sus acciones no entran sin scroll.
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ocurrencia.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: MaterialTheme.textPrimary(brightness),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    resumenDelDia(ocurrencia),
                    style: TextStyle(
                      fontSize: 13,
                      color: MaterialTheme.textMuted(brightness),
                    ),
                  ),
                ],
              ),
            ),
            if (cancelado)
              // Un día cancelado solo se devuelve al patrón (RF-BLQ-5): ese
              // día no se edita, no se cancela otra vez ni cambia de hora.
              ListTile(
                leading: const Icon(Icons.undo),
                title: const Text(volverAlPatron),
                subtitle: const Text(diaCanceladoDetalle),
                onTap: () => elegir(AccionDeBloque.volverAlPatron),
              )
            else ...[
              if (puedeEditar)
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text(editar),
                  subtitle: const Text(editarDetalle),
                  onTap: () => elegir(AccionDeBloque.editar),
                ),
              ListTile(
                leading: const Icon(Icons.event_busy_outlined),
                title: const Text(cancelarDia),
                onTap: () => elegir(AccionDeBloque.cancelarDia),
              ),
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text(cambiarHora),
                onTap: () => elegir(AccionDeBloque.cambiarHora),
              ),
              // El servidor manda `moved: true` en un día que se salió del
              // patrón. Un día cancelado tiene su propia hoja (arriba).
              if (ocurrencia.moved)
                ListTile(
                  leading: const Icon(Icons.undo),
                  title: const Text(volverAlPatron),
                  onTap: () => elegir(AccionDeBloque.volverAlPatron),
                ),
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text(
                  borrar,
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () => elegir(AccionDeBloque.borrar),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Cambiar la hora solo este día": los mismos campos y pickers que el
/// formulario ([TimeBlockPickerField] y `showTimePicker`) y el mismo
/// validador puro ([validarHoras]). Devuelve las dos horas en `HH:MM`, o null
/// si la alumna se arrepiente. No habla con el service.
class TimeBlockDayHoursDialog extends StatefulWidget {
  const TimeBlockDayHoursDialog({
    super.key,
    required this.inicio,
    required this.fin,
  });

  /// Las horas de ese día, en `HH:MM`.
  final String inicio;
  final String fin;

  @override
  State<TimeBlockDayHoursDialog> createState() =>
      _TimeBlockDayHoursDialogState();
}

class _TimeBlockDayHoursDialogState extends State<TimeBlockDayHoursDialog> {
  TimeOfDay? _inicio;
  TimeOfDay? _fin;
  String? _error;

  @override
  void initState() {
    super.initState();
    _inicio = TimeBlockFormController.horaDeTexto(widget.inicio);
    _fin = TimeBlockFormController.horaDeTexto(widget.fin);
  }

  String? _texto(TimeOfDay? t) =>
      t == null ? null : TimeBlockFormController.fmtHora(t);

  Future<TimeOfDay?> _elegir(TimeOfDay? actual, TimeOfDay respaldo) =>
      showTimePicker(
        context: context,
        initialTime: actual ?? respaldo,
        // Los mismos textos en español que el formulario (D7).
        helpText: TimeBlockFormPage.pickerHoraTitulo,
        cancelText: TimeBlockFormPage.pickerCancelar,
        confirmText: TimeBlockFormPage.pickerAceptar,
      );

  void _guardar() {
    final inicio = _texto(_inicio);
    final fin = _texto(_fin);
    final error = validarHoras(inicio, fin);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop((inicio: inicio!, fin: fin!));
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.brightnessOf(context);
    Widget label(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 12),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: MaterialTheme.textPrimary(brightness),
            ),
          ),
        );

    return AlertDialog(
      key: TimeBlockActionsSheet.cambiarHoraKey,
      // Se puede abrir desde la vista semanal, en horizontal: en un iPhone SE
      // eso deja 375 px de alto, y con las dos horas una debajo de la otra el
      // diálogo desbordaba. Van lado a lado, como en el formulario, y si aun
      // así no entra (letra grande), el contenido scrollea.
      scrollable: true,
      title: const Text(TimeBlockActionsSheet.cambiarHora),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    label('Hora de inicio'),
                    TimeBlockPickerField(
                      key: TimeBlockActionsSheet.horaInicioKey,
                      texto: _texto(_inicio) ?? '--:--',
                      icono: Icons.schedule,
                      brightness: brightness,
                      onTap: () async {
                        final elegida = await _elegir(
                          _inicio,
                          const TimeOfDay(hour: 14, minute: 0),
                        );
                        if (elegida == null || !mounted) return;
                        setState(() {
                          _inicio = elegida;
                          _error = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    label('Hora de fin'),
                    TimeBlockPickerField(
                      key: TimeBlockActionsSheet.horaFinKey,
                      texto: _texto(_fin) ?? '--:--',
                      icono: Icons.schedule,
                      brightness: brightness,
                      onTap: () async {
                        final elegida = await _elegir(
                          _fin,
                          const TimeOfDay(hour: 18, minute: 0),
                        );
                        if (elegida == null || !mounted) return;
                        setState(() {
                          _fin = elegida;
                          _error = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: const TextStyle(
                  color: MaterialTheme.primaryDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(TimeBlockActionsSheet.cancelarLabel),
        ),
        TextButton(
          onPressed: _guardar,
          child: const Text(TimeBlockActionsSheet.guardarLabel),
        ),
      ],
    );
  }
}
```

**3.b — Punto de control** (sin commit): la hoja ya existe, pero el horario todavía no la abre.

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test test/HU35_jeff/time_blocks_acciones_test.dart
```

Esperado: `+20 -3: Some tests failed.` Pasan las 3 unitarias, la de la clase y las 16 de la hoja. Fallan exactamente estas tres, las tres con `Found 0 widgets with type "TimeBlockActionsSheet"`: un toque sobre un bloque propio (también sobre un día cancelado, que la Tarea 4 ya pinta tenue) todavía cae en la rama del alumno, que con `idSeccion` vacío no hace nada (`horario.dart:441` hoy).

```
tocar un bloque propio abre su hoja, no el detalle de un curso
en la vista semanal también abre la hoja, y la hoja cabe
tocar un día cancelado abre su hoja, solo con volver al patrón
```

Si falla otra, el error está en 3.a: no seguir a 3.c. Si en vez de correr no compila con `'TimeBlockPickerField' isn't a type` o `Member not found: 'fmtHora'` / `'horaDeTexto'`, la Tarea 5 no dejó lo que esta consume: **PARAR** y reportarlo.

**3.c — `lib/pages/horario/horario.dart`, el import** (`:7-8`, hoy y tras la Tarea 5: ninguna tarea anterior mete líneas antes). Reemplazar esto:

```dart
import '../descripcion_cursos/descrip_cursos.dart';
import '../teacher/at_risk_students_page.dart';
```

por esto:

```dart
import '../descripcion_cursos/descrip_cursos.dart';
import '../teacher/at_risk_students_page.dart';
import '../time_blocks/time_block_actions_sheet.dart';
```

(Queda justo encima de `import 'horario_controller.dart';`. El archivo no tiene los imports ordenados y `directives_ordering` no está activo en este repo —`flutter_lints: ^6.0.0` no lo incluye—, así que el sitio no cambia nada del análisis.)

**3.d — `lib/pages/horario/horario.dart`, la rama del toque** (`:327-329` hoy; más abajo al llegar aquí, porque las Tareas 4 y 5 meten líneas antes). Es el único `onTap: () async {` del archivo. Reemplazar esto:

```dart
        onTap: () async {
          final String idSeccion = course['idSeccion']?.toString() ?? '';
          final isTeacher = AuthService.to.currentUser?.isTeacher ?? false;
```

por esto:

```dart
        onTap: () async {
          // RF-BLQ-5: un bloque propio no tiene curso al que ir; abre su
          // hoja de acciones (la de un día cancelado solo ofrece volver al
          // patrón). Va primero: sin esta rama caería en la del alumno, que
          // con `idSeccion` vacío no hace nada.
          if (bloquePropio != null) {
            await mostrarAccionesDeBloque(
              context,
              bloquePropio,
              cancelado: diaCancelado,
            );
            return;
          }
          final String idSeccion = course['idSeccion']?.toString() ?? '';
          final isTeacher = AuthService.to.currentUser?.isTeacher ?? false;
```

`bloquePropio` y `diaCancelado` son las variables locales que la Tarea 4 declaró más arriba en el mismo `_courseBlock` (`final bloquePropio = course['bloquePropio'] as TimeBlockOccurrence?;` y `final diaCancelado = course['diaCancelado'] == true;`). `bloquePropio` es `final`, así que el `!= null` la promueve dentro del closure y no hace falta `!`. `context` es el parámetro de `_courseBlock` y se usa antes de cualquier `await` del `onTap`. Nada más cambia en `horario.dart`: las ramas del docente, de las asesorías y del detalle del curso quedan como están. Si el ancla de 3.d no aparece literal, o si `bloquePropio` no está declarada antes del `return Positioned(`, una tarea anterior la cambió: **PARAR** y reportar en vez de improvisar.

- [ ] **Paso 4: Correr la prueba y ver que pasa**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test test/HU35_jeff/time_blocks_acciones_test.dart
```

Esperado: PASS, `+23: All tests passed!`.

En la salida aparece una sola línea de `debugPrint`, `Error en una acción de bloque: Bad state: inesperado`, del caso «un fallo sin mensaje del servidor también avisa», que la provoca a propósito. No es una prueba en rojo.

- [ ] **Paso 5: Regresión del horario, suite completa y análisis**

`horario.dart` es una pantalla que ya existía y el toque de un curso pasa por el `onTap` que se tocó, así que se corre todo lo que la monta y la suite entera:

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test test/HU35_jeff/ test/HU31_jeff/
"${FLUTTER:?}" test
"${FLUTTER:?}" analyze
```

Esperado:
- El primero: `+216: All tests passed!` (las 164 de `test/HU35_jeff/` —19 del service, 55 de cruces, 46 de la grilla, 21 del formulario y las 23 de esta tarea— y las 52 de `test/HU31_jeff/`). Las líneas `Error al cargar … "StorageService" not found` que salen son de las pruebas de las Tareas 4 y 5 que montan el `HorarioController` real; no son fallas.
- El segundo: `+738: All tests passed!` (las 574 de antes de la rama más 164). Tarda un par de minutos.
- `analyze`: `7 issues found.`, la misma lista de la línea base que midió la Tarea 1, con el `avoid_print` en `lib/main.dart:93` (donde lo dejó la Tarea 5; esta tarea no toca `main.dart`). Ningún issue en `lib/pages/time_blocks/time_block_actions_sheet.dart`, `lib/pages/horario/horario.dart` ni `test/HU35_jeff/time_blocks_acciones_test.dart`. El `// ignore: must_call_super` del doble del controller es el mismo recurso de la Tarea 4; sin él, `analyze` sube a 8. Si aparece un issue nuevo, se corrige antes del commit; si aparece uno que no se entiende, **PARAR** y reportarlo.

Si una prueba de la Tarea 4 o de la 5 se pone roja, **PARAR**: esta tarea solo agrega una rama al principio del `onTap`, y ninguna de esas pruebas toca un bloque propio. Si el total en verde es otro, se corre archivo por archivo y se compara con esas cifras.

- [ ] **Paso 6: Anotar en el reporte los textos nuevos y las decisiones**

Texto exacto para el reporte de la rama (la Tarea 8 lo reúne para que el dueño lo lea antes de publicar el APK):

```
Tarea 6 (tocar un bloque propio):
- Hoja de acciones. Cabecera: el nombre del bloque tal como lo escribió la
  alumna y el día, "Lunes 21 de septiembre, 14:00 a 18:00". Acciones:
  "Editar el bloque" (debajo, "Todas las semanas"), "Cancelar solo este día",
  "Cambiar la hora solo este día", "Volver al patrón" (en un día movido) y
  "Borrar el bloque".
- Hoja de un día cancelado (se toca el bloque tenue de la grilla): una sola
  acción, "Volver al patrón", con "Este día está cancelado" debajo.
- Al cancelar un día: "Se canceló este día." con el botón "Deshacer", que
  deja el día como estaba (en el patrón, o en sus horas movidas si ya se había
  movido). El aviso se cierra solo a los 4 s (persist: false).
- Confirmación de borrado: título "¿Borrar el bloque?", cuerpo
  'Se borra "<nombre>" con todos sus días, no solo este.', botones "Cancelar"
  y "Borrar".
- Cambiar la hora de un día: título "Cambiar la hora solo este día",
  etiquetas "Hora de inicio" y "Hora de fin", lado a lado como en el
  formulario, "--:--" si falta una hora, botones "Cancelar" y "Guardar". Los
  mensajes de error son los de validarHoras (Tarea 2).
- Errores: el mensaje del servidor, tal cual. Un fallo sin mensaje (red caída,
  plazo vencido) muestra el de la Tarea 1, "No se pudo guardar tu bloque.
  Inténtalo de nuevo.", también al cancelar o al borrar; si el dueño prefiere un
  texto que no diga "guardar" para esos casos, se agrega en el service.
- El selector de hora lleva "Elige la hora", "Cancelar" y "Aceptar", los
  mismos textos en español que el formulario (Tarea 5, D7).
- Un día cancelado se devuelve al patrón desde su hoja, como pide RF-BLQ-5: la
  Tarea 4 lo pinta tenue (el servidor no lo manda como ocurrencia, RS-BE-33;
  sale de la excepción de la regla) y al tocarlo la hoja solo ofrece "Volver
  al patrón". El "Deshacer" del aviso es un atajo que no pide la spec: se
  cierra solo a los 4 s, así que no queda de pantalla en pantalla ni deja en
  cola los avisos de otras pantallas.
- "Este día está cancelado" es el texto que fija la spec para un día
  cancelado (D2): la grilla lo pinta debajo del nombre (Tarea 4) y la hoja lo
  repite debajo de "Volver al patrón".
- Cambiar la hora de un día NO muestra el aviso de cruce de RF-BLQ-3: la spec
  lo pide para el formulario, y así lo aceptó el dueño (D7). Si algún día se
  quiere también aquí, se arma con crucesDeBloque sobre ese único día.
```

- [ ] **Paso final: Commit**

```bash
cd "${REPO:?}"
test "$(git branch --show-current)" = feat/bloques-horario-fe || echo 'PARAR: rama equivocada'
git status --short
git add lib/pages/time_blocks/time_block_actions_sheet.dart \
        lib/pages/horario/horario.dart \
        test/HU35_jeff/time_blocks_acciones_test.dart
git commit -m "feat(time-blocks): hoja de acciones al tocar un bloque propio (RF-BLQ-5)

Tocar un bloque propio en el horario abre una hoja con editar el bloque,
cancelar o cambiar la hora solo ese día, volver al patrón si el día ya se
movió y borrar el bloque con confirmación. Cada acción llama al
TimeBlocksService, que recarga la ventana: la grilla se entera sola.

Tocar un día cancelado, que la grilla pinta tenue, abre una hoja con una
sola acción: volver al patrón. El aviso de cancelar trae además un Deshacer
que se cierra solo. Cada aviso de la hoja reemplaza al anterior, y el
diálogo de cambiar la hora cabe en horizontal. Tocar una clase sigue
llevando al detalle del curso."
git log -1 --format=%B | grep -qi '^co-authored-by:' && echo 'PARAR: el commit trae trailer'
```

Antes del `git add`, `git status --short` solo puede listar esos tres archivos; si lista otro, o sale un `PARAR`, se detiene aquí. Sin trailer `Co-Authored-By`: el autor ya está configurado en git.
### Tarea 7: La línea de horas de la semana

> Una versión anterior de esta tarea se verificó en una copia descartable del repo (en `/tmp`), con el código **literal** de las Tareas 1 a 6 de entonces: el Paso 2 no compiló por las tres piezas que faltaban; el Paso 4 dio `+19`; `flutter analyze`, los 7 issues de la línea base. Las pruebas no eran vacías: quitar la condición «sin bloques», devolver 0 cuando falta el dato, buscar siempre la semana de hoy en vez de la del día activo o sumar las ocurrencias hacía fallar al menos una. Una revisión posterior aplicó las Tareas 1 a 7 en orden y midió `+216` para `test/HU35_jeff/ test/HU31_jeff/` y `+738` para la suite completa (la Tarea 6 ya traía 20 pruebas). Después, esa revisión llevó la línea también a la vista semanal, corrigió lo que se asumía de las semanas en 0 (el backend sí las manda, RS-BE-34) y sumó pruebas aquí y en las Tareas 1, 2, 4, 5 y 6. Por último, las decisiones finales del dueño cambiaron dos cosas: la semana del día activo sale de su `isoDate` y no de `dateText` (D1), y una semana en 0 no pinta la línea (D3). Las cifras de abajo se midieron después de las decisiones finales del dueño (ver «Cifras de las pruebas» en las restricciones globales). El worktree real no se tocó.

**Requisitos:** RF-BLQ-6 completo: en la pantalla de horario —en sus dos vistas, la de día y la semanal horizontal—, una línea discreta «Tus bloques: 12 h esta semana» con las horas que los bloques propios ocupan en la semana de lunes a domingo que contiene el día activo. El número lo manda el servidor en `weeks` (RS-BE-34) y **no se recalcula en el cliente**. La línea solo sale con horas mayores que 0 (D3): sin bloques, sin la semana en `weeks`, con `hours` en `null` o con `hours: 0`, no hay línea. Nunca se pinta un 0.

**Archivos:**
- Crear: `test/HU35_jeff/time_blocks_horas_test.dart`
- Modificar: `lib/pages/horario/horario_controller.dart` (el final de `_numeroDeDia` y el comienzo de `previousDay`). Hoy ese ancla no existe: `_numeroDeDia` lo agrega la Tarea 4, y las Tareas 5 y 6 no tocan este archivo. Guiarse por el texto.
- Modificar: `lib/pages/horario/horario.dart`, cuatro anclas que hoy no existen o están más arriba: la `agregarBloqueKey` que agrega la Tarea 5 (`:25-26` al llegar aquí); la franja de `weekText` de la vista de día (hoy `:921-936`, y ninguna tarea anterior la toca); el final de `canceladosPorDia` y el `return Container(` de `_landscapeWeekGrid` (los agrega la Tarea 4); y el `Text(cycle, …)` de la franja inferior de identidad de la vista semanal (hoy `:790-797`). Las Tareas 4 a 6 corren los números; manda el texto, que existe literal.
- Test: `test/HU35_jeff/time_blocks_horas_test.dart`

**Interfaces:**
- Consume, de la Tarea 1 (`lib/models/time_block_model.dart` y `lib/services/time_blocks_service.dart`):
  ```dart
  class TimeBlockWeek { final String weekStart; /* lunes, "YYYY-MM-DD" */ final double? hours; }
  class TimeBlocksSnapshot { final List<TimeBlockOccurrence> occurrences; final List<TimeBlockWeek> weeks; }
  class TimeBlockRule { … }
  class TimeBlocksService extends GetxService {
    TimeBlocksService({ApiClient? apiClient});
    static TimeBlocksService get to => Get.find();
    List<TimeBlockRule> get blocks;      // lee el Rx ANTES de filtrar por dueño
    TimeBlocksSnapshot? get snapshot;    // ídem
    Future<void> load({required String from, required String to, bool force = false});
  }
  ```
- Consume, de la Tarea 4 (`lib/pages/horario/horario_controller.dart`): los imports `'../../models/time_block_model.dart'` y `'../../services/time_blocks_service.dart'`, que ya están puestos, y sus ayudantes privados `DateTime? _fechaDelDia(DaySchedule dia)` (la fecha del día, UTC a medianoche: su `isoDate` o, si es null, ese día de la semana en la semana de hoy), `static DateTime _lunesDe(DateTime fecha)` y `static String _fechaPlana(DateTime d)` (`"YYYY-MM-DD"`). Es la misma convención de `bloquesDelDia`: la fecha sale de `isoDate`, nunca de `dateText`.
- Consume, de la Tarea 4 (`lib/pages/horario/horario.dart`): en `_landscapeWeekGrid`, el mapa `canceladosPorDia`, leído fuera del `LayoutBuilder`, solo como ancla para leer las horas en el mismo sitio.
- Consume, de la Tarea 5 (`lib/pages/horario/horario.dart`): `static const Key agregarBloqueKey = Key('horario-agregar-bloque');`, solo como ancla.
- Consume, del repo y de la Tarea 4: `DaySchedule(this.dayName, this.dateText, this.weekText, {String? isoDate})`; de `HorarioController`, `currentDay`, `currentDayIndex`, `daysList`, `currentLimaTime` y `nextDay()`; dentro del `Obx` de `HorarioPage.build()`, las variables `controller`, `isDark` y `activeDay`; en `_landscapeWeekGrid`, `controller` y la franja inferior de identidad (código, nombre y ciclo, `horario.dart:762-801` hoy), que se construye dentro del `LayoutBuilder` pero lee variables tomadas antes de él (`studentCode`, `studentName`, `cycle`).
- Antes de empezar, confirmar que las Tareas 1, 4 y 5 dejaron lo que se consume:
  ```bash
  cd "${REPO:?}"
  grep -c "TimeBlocksSnapshot? get snapshot\|List<TimeBlockRule> get blocks" lib/services/time_blocks_service.dart
  grep -c "^class TimeBlockWeek\|final double? hours;" lib/models/time_block_model.dart
  grep -c "DateTime? _fechaDelDia(DaySchedule dia)\|static DateTime _lunesDe(DateTime fecha)\|static String _fechaPlana(DateTime d)\|final i = dias.indexOf(limpio);\|^import '../../models/time_block_model.dart';\|^import '../../services/time_blocks_service.dart';" lib/pages/horario/horario_controller.dart
  grep -c "static const Key agregarBloqueKey = Key('horario-agregar-bloque');\|^                  activeDay.weekText,$" lib/pages/horario/horario.dart
  grep -c "^    final canceladosPorDia = <DaySchedule, List<TimeBlockOccurrence>>{$\|^                        cycle,$" lib/pages/horario/horario.dart
  ```
  Esperado, en orden: `2`, `2`, `6`, `2`, `2`. Si alguno no coincide, **PARAR** y reportarlo: no se arregla una tarea anterior desde aquí.
- Produce (lo del esqueleto, más dos piezas públicas para probar la vista):
  ```dart
  // lib/pages/horario/horario_controller.dart (HorarioController)
  double? get horasDeLaSemanaActiva;

  // lib/pages/horario/horario.dart (HorarioPage)
  static const Key horasSemanaKey = Key('horario-horas-semana');
  static String textoDeHoras(double horas);   // 12 → "12 h", 12.5 → "12.5 h"
  // y en las dos vistas (solo una está en pantalla a la vez): en la de día,
  // bajo el texto de la semana del ciclo; en la semanal, en la franja de
  // abajo, junto al ciclo:
  //   Text('Tus bloques: ${textoDeHoras(horas)} esta semana', key: horasSemanaKey)
  ```
  Ninguna tarea posterior consume estas piezas. La Tarea 8 solo reúne el texto en el reporte.

**Cuatro decisiones de esta tarea que no hay que deshacer sin querer:**

1. **El total sale de `weeks` y no se suma.** La prueba siembra a propósito una sola ocurrencia de 4 h en la semana que el servidor dice que tiene 12 h. Si alguien suma las ocurrencias en la app, la prueba falla.
2. **La línea solo sale con horas mayores que 0 (D3), y hace falta tener bloques.** El backend manda en `weeks` una entrada por cada semana de lunes a domingo entre el lunes de `from` y el de `to`, con el total de la semana entera y `hours: 0` cuando la semana no tiene ocurrencias (RS-BE-34; así lo implementa `weeklyHours` en su plan y lo documenta su `api-contracts.md`). Una semana con todos sus días cancelados, o en la que el bloque todavía no empieza o ya terminó, llega con 0: la línea se oculta, igual que si la semana no vino (fuera de la ventana) o vino con `hours` en `null` (el backend no lo manda). La condición sobre las reglas (`blocks`) es la letra de la spec («si el alumno no tiene bloques, la línea no aparece»); con D3 casi siempre coincide con la del 0, y la prueba «sin bloques no hay total…» siembra a propósito una semana con horas para fijarla por sí sola.
3. **La semana sale del `isoDate` del día activo (D1).** Cada `weekStart` es un lunes: la semana del día activo es la entrada cuyo `weekStart` es el lunes de su fecha (`_fechaDelDia`, de la Tarea 4). No se lee `dateText`. Si `isoDate` es null (ciclo sin semanas, «Semana actual»), la fecha es ese día de la semana en la semana de hoy, así que es la semana de hoy, igual que en la Tarea 4.
4. **En las dos vistas, y leída dentro del `Obx` de `build`.** RF-BLQ-6 pone la línea «en la pantalla de horario», para la semana del día activo de la vista, y la vista semanal horizontal ya pinta los bloques de esa misma semana (Tarea 4). En la vista de día, la línea va en la franja de `weekText`, que se construye dentro del `Obx` de `build` y fuera de cualquier `LayoutBuilder`. En la semanal, las horas se leen en `_landscapeWeekGrid` antes de su `LayoutBuilder`, junto a `propiosPorDia` y `canceladosPorDia`, y la línea se pinta en la franja inferior de identidad, junto al ciclo: sus encabezados llevan solo el nombre del día, a propósito («Sin fecha: el horario es SEMANAL»), así que esa franja es el único sitio libre. Así las dos se actualizan solas cuando llegan los bloques o cambia el día. La prueba «si los bloques llegan después…» fija ese comportamiento en la vista de día, pero no delata por sí sola una lectura movida a un `LayoutBuilder`: en esta pantalla la grilla ya suscribe el mismo `Obx` al `snapshot` (Tarea 4) y lo reconstruye igual. Por eso la regla queda escrita en el comentario del código.

- [ ] **Paso 1: Escribir la prueba que falla**

Crear `test/HU35_jeff/time_blocks_horas_test.dart` (la carpeta ya existe desde la Tarea 1) con este contenido:

```dart
// test/HU35_jeff/time_blocks_horas_test.dart
//
// UNITARIA + WIDGET — HU35 (bloques de horario propios): la línea con las
// horas que los bloques propios ocupan en la semana del día activo (RF-BLQ-6).
// - El texto de las horas: HorarioPage.textoDeHoras
//   (lib/pages/horario/horario.dart).
// - Qué total le toca al día activo: HorarioController.horasDeLaSemanaActiva
//   (lib/pages/horario/horario_controller.dart).
// - La línea en las dos vistas, la de día y la semanal:
//   lib/pages/horario/horario.dart.
//
// El número lo calcula el servidor (RS-BE-34) y la app solo lo muestra. Por
// eso la única ocurrencia sembrada suma a propósito OTRA cifra (4 h) que la
// que manda `weeks` para su semana (12 h): si alguien sumara en la app, las
// pruebas lo delatan.
//
// Todos los datos son inventados; el repo es público. La alumna 20230001 no
// existe, el bloque "Prácticas de prueba" tampoco, y nada sale de un horario
// real ni de test/HU31_jeff/fixtures.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/horario/horario.dart';
import 'package:ulima_plus/pages/horario/horario_controller.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/time_blocks_service.dart';

// --- Datos inventados ---------------------------------------------------------

UserModel _alumna() => UserModel(
      code: '20230001',
      firstName: 'Alumna',
      lastName: 'De Prueba',
      email: 'test@aloe.ulima.edu.pe',
      role: 'student',
      currentCycle: '2026-2',
      setupComplete: true,
    );

/// La regla, con la forma de `GET /time-blocks/me`. Aquí solo importa que
/// exista: la línea aparece cuando la alumna tiene al menos un bloque.
Map<String, dynamic> _regla() => <String, dynamic>{
      'id': 7,
      'title': 'Prácticas de prueba',
      'colorHex': '#27AE60',
      'daysOfWeek': <dynamic>[1, 3],
      'startTime': '14:00',
      'endTime': '18:00',
      'startDate': '2026-09-01',
      'endDate': '2026-12-15',
      'exceptions': <dynamic>[],
    };

/// Una sola ocurrencia, de cuatro horas, el lunes 21. Sumada en la app, la
/// semana del 21 daría 4 h y no las 12 que dice el servidor.
Map<String, dynamic> _ocurrencia() => <String, dynamic>{
      'blockId': 7,
      'title': 'Prácticas de prueba',
      'colorHex': '#27AE60',
      'date': '2026-09-21',
      'dayOfWeek': 1,
      'startTime': '14:00',
      'endTime': '18:00',
      'moved': false,
    };

/// `weeks` de la ventana del 14 de septiembre al 11 de octubre de 2026, con la
/// forma de `GET /time-blocks/me/occurrences` (RS-BE-34): una entrada por
/// semana, con su lunes. Las cifras son inventadas y no cuadran a propósito con
/// las ocurrencias (ver la cabecera). La del 5 de octubre llega sin horas: el
/// backend siempre manda un número (0 si la semana no tiene nada), pero si
/// llegara null la app no lo convierte en 0.
List<Map<String, dynamic>> _semanas() => <Map<String, dynamic>>[
      <String, dynamic>{'weekStart': '2026-09-14', 'hours': 6},
      <String, dynamic>{'weekStart': '2026-09-21', 'hours': 12},
      <String, dynamic>{'weekStart': '2026-09-28', 'hours': 12.5},
      <String, dynamic>{'weekStart': '2026-10-05', 'hours': null},
    ];

const List<String> _nombres = <String>[
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

/// Cuatro semanas seguidas de lunes a domingo desde el lunes 21 de septiembre
/// de 2026, con lo que arma el backend para cada día ("21 de Septiembre",
/// `isoDate` "2026-09-21"), como llegan de `/schedule/me/sessions`. La cuarta
/// (del 12 de octubre) no está en `weeks`: cae fuera de la ventana.
List<DaySchedule> _cuatroSemanas() => <DaySchedule>[
      for (var i = 0; i < 28; i++) _diaNumero(i),
    ];

/// El día [i] contado desde el lunes 21 de septiembre de 2026.
DaySchedule _diaNumero(int i) {
  final fecha = DateTime.utc(2026, 9, 21 + i);
  final mes = fecha.month == 9 ? 'Septiembre' : 'Octubre';
  return DaySchedule(
    _nombres[fecha.weekday - 1],
    '${fecha.day} de $mes',
    'Semana ${5 + i ~/ 7} del ciclo',
    isoDate: '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-'
        '${fecha.day.toString().padLeft(2, '0')}',
  );
}

// Posiciones en [_cuatroSemanas].
const int _lunes21 = 0;
const int _miercoles23 = 2;
const int _domingo27 = 6;
const int _lunes28 = 7;
const int _lunes5Oct = 14;
const int _lunes12Oct = 21;

// --- Dobles --------------------------------------------------------------------

class _FakeAuthService extends AuthService {
  _FakeAuthService(UserModel? user) : userRx = Rx<UserModel?>(user);

  final Rx<UserModel?> userRx;

  @override
  UserModel? get currentUser => userRx.value;

  @override
  Rx<UserModel?> get currentUserRx => userRx;

  @override
  Future<void> refreshCurrentUser() async {}
}

/// Doble del cliente HTTP de [TimeBlocksService]: contesta las dos llamadas de
/// `load` con lo sembrado.
class _FakeBloquesApi extends ApiClient {
  _FakeBloquesApi({required this.reglas, required this.semanas})
      : super(configuredBaseUrl: 'http://test');

  final List<Map<String, dynamic>> reglas;
  final List<Map<String, dynamic>> semanas;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    String? token,
    Map<String, String?> query = const {},
    bool suppressSessionExpiry = false,
  }) async {
    if (path == '/time-blocks/me/occurrences') {
      return <String, dynamic>{
        'occurrences': <dynamic>[_ocurrencia()],
        'weeks': semanas,
      };
    }
    return <String, dynamic>{'blocks': reglas};
  }
}

/// El controller del horario sin su carga remota: días sembrados y el reloj
/// fijo. `horasDeLaSemanaActiva` NO se sobreescribe: es lo que se prueba.
class _HorarioDePrueba extends HorarioController {
  _HorarioDePrueba(
    List<DaySchedule> dias, {
    int diaActivo = 0,
    DateTime? hoy,
  }) {
    daysList.assignAll(dias);
    currentDayIndex.value = diaActivo;
    // Por omisión el 1 de septiembre: fuera de las cuatro semanas, así la
    // vista de día no pinta la línea roja de "ahora".
    currentLimaTime.value = hoy ?? DateTime.utc(2026, 9, 1, 10);
  }

  @override
  // ignore: must_call_super
  void onInit() {
    // Sin el onInit real: arranca un Timer.periodic de un minuto y pide el
    // horario con un ApiClient propio que no se puede inyectar. Mismo recurso
    // que test/HU35_jeff/time_blocks_grilla_test.dart.
  }
}

/// Registra la sesión de la alumna y un [TimeBlocksService] con lo sembrado.
/// Si [cargar], carga una ventana fija de cuatro semanas, no la que pediría el
/// horario (ver la nota de las pruebas).
Future<TimeBlocksService> _registrarBloques({
  List<Map<String, dynamic>>? reglas,
  List<Map<String, dynamic>>? semanas,
  bool cargar = true,
}) async {
  Get.put<AuthService>(_FakeAuthService(_alumna()));
  final servicio = TimeBlocksService(
    apiClient: _FakeBloquesApi(
      reglas: reglas ?? <Map<String, dynamic>>[_regla()],
      semanas: semanas ?? _semanas(),
    ),
  );
  Get.put<TimeBlocksService>(servicio);
  if (cargar) await servicio.load(from: '2026-09-14', to: '2026-10-11');
  return servicio;
}

/// Vertical y más ancho que un teléfono, como en time_blocks_grilla_test.dart:
/// la fuente de las pruebas dibuja cada letra como un cuadrado de su tamaño, y
/// "Miércoles, 23 de Septiembre" a 18 px con sus dos flechas necesita ~620 px
/// (la franja del día desborda en la prueba, no en la app). El horizontal es
/// el de time_blocks_grilla_test.dart.
const Size _vertical = Size(700, 1000);
const Size _horizontal = Size(1000, 500);

/// Monta [HorarioPage] sobre [_cuatroSemanas], en vertical si no se pide otra
/// pantalla. El `Get.put(HorarioController())` del `build` encuentra el
/// doble ya registrado y lo reusa.
Future<TimeBlocksService> _montar(
  WidgetTester tester, {
  List<Map<String, dynamic>>? reglas,
  List<Map<String, dynamic>>? semanas,
  int diaActivo = _lunes21,
  bool cargarAntes = true,
  Size pantalla = _vertical,
}) async {
  tester.view.physicalSize = pantalla;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final servicio = await _registrarBloques(
    reglas: reglas,
    semanas: semanas,
    cargar: cargarAntes,
  );
  Get.put<HorarioController>(
    _HorarioDePrueba(_cuatroSemanas(), diaActivo: diaActivo),
  );

  await tester.pumpWidget(const GetMaterialApp(home: HorarioPage()));
  await tester.pump();
  return servicio;
}

/// Toca la flecha de "día siguiente" de la franja del día.
Future<void> _diaSiguiente(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.arrow_forward_ios_rounded));
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UNITARIA · el texto de las horas (HorarioPage.textoDeHoras)', () {
    test('una cifra entera va sin decimal', () {
      expect(HorarioPage.textoDeHoras(12), '12 h');
      expect(HorarioPage.textoDeHoras(8.0), '8 h');
      expect(HorarioPage.textoDeHoras(0), '0 h');
    });

    test('una cifra con fracción va con un decimal', () {
      expect(HorarioPage.textoDeHoras(12.5), '12.5 h');
      expect(HorarioPage.textoDeHoras(0.5), '0.5 h');
    });

    test('se redondea a un decimal', () {
      // Una hora y 45 minutos; dos horas y 10 minutos.
      expect(HorarioPage.textoDeHoras(1.75), '1.8 h');
      expect(HorarioPage.textoDeHoras(2 + 10 / 60), '2.2 h');
    });

    test('si al redondear queda entera, va sin decimal: nunca "13.0 h"', () {
      expect(HorarioPage.textoDeHoras(12.96), '13 h');
    });
  });

  group('UNITARIA · el total de la semana del día activo (RF-BLQ-6)', () {
    setUp(() {
      Get.testMode = true;
      Get.reset();
    });
    tearDown(Get.reset);

    test('con bloques, es el hours que manda el servidor para esa semana',
        () async {
      await _registrarBloques();
      final horario = _HorarioDePrueba(_cuatroSemanas(), diaActivo: _miercoles23);

      expect(
        horario.horasDeLaSemanaActiva,
        12,
        reason: 'sale de weeks; la ocurrencia sembrada suma 4 h',
      );
    });

    test('de lunes a domingo, todos los días de la semana dan el mismo total',
        () async {
      await _registrarBloques();
      final horario = _HorarioDePrueba(_cuatroSemanas());

      for (var i = _lunes21; i <= _domingo27; i++) {
        horario.currentDayIndex.value = i;
        expect(
          horario.horasDeLaSemanaActiva,
          12,
          reason: horario.currentDay!.dateText,
        );
      }
    });

    test('del domingo al lunes siguiente, pasa al total de la otra semana',
        () async {
      await _registrarBloques();
      final horario = _HorarioDePrueba(_cuatroSemanas(), diaActivo: _domingo27);
      expect(horario.horasDeLaSemanaActiva, 12);

      horario.nextDay();

      expect(horario.currentDay!.dateText, '28 de Septiembre');
      expect(horario.horasDeLaSemanaActiva, 12.5);
    });

    test('sin bloques no hay total, aunque la semana traiga horas', () async {
      // La spec: sin bloques, la línea no aparece. Sin bloques el servidor
      // manda sus semanas en 0 (RS-BE-34), que ya se ocultan por D3; la
      // prueba siembra 12 h a propósito para fijar esta condición por sí
      // sola.
      await _registrarBloques(reglas: const <Map<String, dynamic>>[]);
      final horario = _HorarioDePrueba(_cuatroSemanas());

      expect(horario.horasDeLaSemanaActiva, isNull);
    });

    test('con hours en null no hay total: no se convierte en 0', () async {
      await _registrarBloques();
      final horario = _HorarioDePrueba(_cuatroSemanas(), diaActivo: _lunes5Oct);

      expect(horario.currentDay!.isoDate, '2026-10-05');
      expect(horario.horasDeLaSemanaActiva, isNull);
    });

    test('si la semana del día activo no vino en weeks, no hay total',
        () async {
      // Una semana no viene cuando cae fuera de la ventana pedida (una semana
      // sin ocurrencias, en cambio, sí viene, con 0: RS-BE-34). Es un dato que
      // falta, y la app no pone un 0 en su lugar.
      await _registrarBloques();
      final horario = _HorarioDePrueba(_cuatroSemanas(), diaActivo: _lunes12Oct);

      expect(horario.currentDay!.isoDate, '2026-10-12');
      expect(horario.horasDeLaSemanaActiva, isNull);
    });

    test('con bloques, una semana en 0 no tiene total: la línea se oculta',
        () async {
      // Pasa de verdad: una semana con todos sus días cancelados, o fuera de
      // las fechas del bloque, llega con hours: 0 (RS-BE-34). La línea solo
      // sale con horas mayores que 0 (D3).
      await _registrarBloques(
        semanas: <Map<String, dynamic>>[
          <String, dynamic>{'weekStart': '2026-09-21', 'hours': 0},
        ],
      );
      final horario = _HorarioDePrueba(_cuatroSemanas());

      expect(horario.horasDeLaSemanaActiva, isNull);
    });

    test('ciclo sin semanas (isoDate null): cuenta la semana de hoy',
        () async {
      await _registrarBloques();
      // Lo que manda el backend cuando el ciclo no tiene semanas: los siete
      // días sin fecha (isoDate null). Hoy es el miércoles 23, así que es la
      // semana del 21.
      final horario = _HorarioDePrueba(
        <DaySchedule>[
          for (final nombre in _nombres) DaySchedule(nombre, '', 'Semana actual'),
        ],
        diaActivo: 4,
        hoy: DateTime.utc(2026, 9, 23, 10),
      );

      expect(horario.horasDeLaSemanaActiva, 12);
    });

    test('sin el service registrado no hay total y nada se cae', () {
      Get.put<AuthService>(_FakeAuthService(_alumna()));
      final horario = _HorarioDePrueba(_cuatroSemanas());

      expect(horario.horasDeLaSemanaActiva, isNull);
    });
  });

  group('WIDGET · la línea en la pantalla de horario (RF-BLQ-6)', () {
    setUp(() {
      Get.testMode = true;
      Get.reset();
    });
    tearDown(Get.reset);

    testWidgets('con bloques, la línea dice el total de la semana del día activo',
        (tester) async {
      await _montar(tester, diaActivo: _miercoles23);

      expect(find.text('Miércoles, 23 de Septiembre'), findsOneWidget);
      expect(find.text('Tus bloques: 12 h esta semana'), findsOneWidget);
      expect(find.byKey(HorarioPage.horasSemanaKey), findsOneWidget);
      // La línea acompaña a la semana del ciclo, no la reemplaza.
      expect(find.text('Semana 5 del ciclo'), findsOneWidget);
    });

    testWidgets('al pasar de día dentro de la misma semana, no cambia',
        (tester) async {
      await _montar(tester, diaActivo: _lunes21);

      for (var i = 0; i < 6; i++) {
        await _diaSiguiente(tester);
      }

      expect(find.text('Domingo, 27 de Septiembre'), findsOneWidget);
      expect(find.text('Tus bloques: 12 h esta semana'), findsOneWidget);
    });

    testWidgets('al saltar a la semana siguiente, cambia', (tester) async {
      await _montar(tester, diaActivo: _domingo27);
      expect(find.text('Tus bloques: 12 h esta semana'), findsOneWidget);

      await _diaSiguiente(tester);

      expect(find.text('Lunes, 28 de Septiembre'), findsOneWidget);
      expect(find.text('Tus bloques: 12.5 h esta semana'), findsOneWidget);
      expect(find.text('Tus bloques: 12 h esta semana'), findsNothing);
    });

    testWidgets('sin bloques la línea no aparece', (tester) async {
      // Con las semanas de siempre (12 h la del 21): lo que la oculta es que
      // no hay bloques.
      await _montar(tester, reglas: const <Map<String, dynamic>>[]);

      expect(find.byKey(HorarioPage.horasSemanaKey), findsNothing);
      expect(find.textContaining('Tus bloques'), findsNothing);
      expect(find.text('Semana 5 del ciclo'), findsOneWidget);
    });

    testWidgets('con hours en null la línea no aparece, ni como 0',
        (tester) async {
      await _montar(tester, diaActivo: _lunes5Oct);

      expect(find.text('Lunes, 5 de Octubre'), findsOneWidget);
      expect(find.byKey(HorarioPage.horasSemanaKey), findsNothing);
      expect(find.textContaining('Tus bloques'), findsNothing);
      expect(find.textContaining('0 h'), findsNothing);
    });

    testWidgets('con bloques y la semana en 0, la línea no aparece',
        (tester) async {
      // RS-BE-34 manda todas las semanas de la ventana, con hours: 0 cuando
      // no tienen ocurrencias (por ejemplo, todos sus días cancelados). La
      // línea solo sale con horas mayores que 0 (D3): nunca "0 h".
      await _montar(
        tester,
        semanas: <Map<String, dynamic>>[
          <String, dynamic>{'weekStart': '2026-09-21', 'hours': 0},
        ],
      );

      expect(find.byKey(HorarioPage.horasSemanaKey), findsNothing);
      expect(find.textContaining('Tus bloques'), findsNothing);
      expect(find.textContaining('0 h'), findsNothing);
      expect(find.text('Semana 5 del ciclo'), findsOneWidget);
    });

    testWidgets('en horizontal la línea también sale, con la semana del día activo',
        (tester) async {
      // La vista semanal pinta los bloques de la semana del día activo
      // (Tarea 4); la línea dice las horas de esa misma semana, en la franja
      // de abajo, junto al ciclo. Con el lunes 28 activo es la semana del 28,
      // la de 12.5 h, y no la de las columnas (la primera, de 12 h).
      await _montar(tester, pantalla: _horizontal, diaActivo: _lunes28);

      expect(find.text('Tus bloques: 12.5 h esta semana'), findsOneWidget);
      expect(find.byKey(HorarioPage.horasSemanaKey), findsOneWidget);
      expect(find.text('2026-2'), findsOneWidget);
    });

    testWidgets('si los bloques llegan después de pintar el horario, la línea aparece sola',
        (tester) async {
      final servicio = await _montar(tester, cargarAntes: false);
      expect(find.byKey(HorarioPage.horasSemanaKey), findsNothing);

      // Es lo que pasa en la app: el horario pinta sus días antes de que
      // vuelvan los bloques, y el service recarga su ventana después de cada
      // escritura. La pantalla no hace nada y tiene que enterarse.
      await servicio.load(from: '2026-09-14', to: '2026-10-11');
      await tester.pump();

      expect(find.text('Tus bloques: 12 h esta semana'), findsOneWidget);
    });
  });
}
```

Notas para quien ejecuta:
- Ninguna prueba usa `pumpAndSettle`. Con días sembrados no hay esqueleto en pantalla, pero se sigue la regla global y se avanza con `tester.pump()`.
- La vista vertical mide 700 px y no 600 como en `time_blocks_grilla_test.dart`. Aquí la franja del día llega a mostrar «Miércoles, 23 de Septiembre», que con la fuente de las pruebas no cabe en 600 y desborda. Con 600 fallan dos pruebas por `A RenderFlex overflowed by 21 pixels on the right`, un fallo que no tiene nada que ver con esta tarea.
- La ventana de la prueba es fija (`load(from: '2026-09-14', to: '2026-10-11')`): el doble del controller no corre su `onInit`, así que no pide la del ciclo. La semana del 12 de octubre queda fuera de `weeks` a propósito.
- La vista horizontal mide 1000 x 500, como en `time_blocks_grilla_test.dart`; ahí la franja de abajo tiene sitio para el código, el nombre, la línea y el ciclo.

- [ ] **Paso 2: Correr la prueba y ver que falla**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test test/HU35_jeff/time_blocks_horas_test.dart
```

Esperado: no compila, porque las tres piezas que se prueban todavía no existen. La salida repite estos tres errores, uno por cada uso:

```
Error: Member not found: 'HorarioPage.textoDeHoras'.
Error: Member not found: 'horasSemanaKey'.
Error: The getter 'horasDeLaSemanaActiva' isn't defined for the type '_HorarioDePrueba'.
```

La salida termina en `00:00 +0 -1: Some tests failed.`, con el archivo como única falla (`…/time_blocks_horas_test.dart: loading …/time_blocks_horas_test.dart`). Si aparece cualquier otro error de compilación (un import que no resuelve, un `TimeBlocksService` sin `apiClient:`), es que una tarea anterior no dejó lo que se consume: **PARAR** y reportarlo.

- [ ] **Paso 3: Implementación mínima**

Son cinco reemplazos. No correr `dart format` sobre `horario.dart`: hoy no está formateado, y el formateador tocaría líneas ajenas a esta tarea. `horario_controller.dart` sí lo está, y el código de 3.a ya respeta ese formato.

**3.a — `lib/pages/horario/horario_controller.dart`: el total de la semana activa** (`:604-608` tras la Tarea 4, contado sobre sus reemplazos; manda el texto). Reemplazar esto:

```dart
    final i = dias.indexOf(limpio);
    return i < 0 ? null : i + 1;
  }

  void previousDay() {
```

por esto:

```dart
    final i = dias.indexOf(limpio);
    return i < 0 ? null : i + 1;
  }

  /// Las horas que los bloques propios ocupan en la semana del día activo
  /// —la de lunes a domingo que lo contiene—, o null si la línea de RF-BLQ-6
  /// no se pinta.
  ///
  /// El número NO se calcula aquí: es el `hours` que el servidor manda en
  /// `weeks` para esa semana (RS-BE-34). Sumar las ocurrencias en la app sería
  /// una segunda cuenta que podría no coincidir con la suya.
  ///
  /// null si no hay línea que pintar: si la alumna no tiene bloques, si la
  /// semana del día activo no vino en `weeks` (queda fuera de la
  /// [ventanaVisible]), o si vino con `hours` null o 0. Una semana sin
  /// ocurrencias viene con `hours: 0` (RS-BE-34), y la línea solo sale con
  /// horas mayores que 0 (D3): nunca se pinta "0 h" ni un 0 en lugar de un
  /// dato que falta.
  double? get horasDeLaSemanaActiva {
    // Todo lo reactivo se lee ANTES de cualquier return: el Obx de la pantalla
    // que llama a este getter queda suscrito a los bloques, a la ventana y al
    // día activo aunque hoy devuelva null, y la línea aparece sola cuando
    // llegan los bloques o cambia el día.
    final servicio = Get.isRegistered<TimeBlocksService>()
        ? TimeBlocksService.to
        : null;
    final snapshot = servicio?.snapshot;
    final reglas = servicio?.blocks ?? const <TimeBlockRule>[];
    final dia = currentDay;
    if (snapshot == null || reglas.isEmpty || dia == null) return null;
    final horas = _semanaQueContiene(dia, snapshot.weeks)?.hours;
    return horas != null && horas > 0 ? horas : null;
  }

  /// La entrada de [semanas] de la semana que contiene a [dia], o null.
  ///
  /// Cada `weekStart` es un lunes (RS-BE-34): [dia] es de la semana cuyo
  /// `weekStart` es el lunes de su fecha. La fecha es la de [_fechaDelDia],
  /// la misma de [bloquesDelDia]: su `isoDate` o, si el ciclo no tiene
  /// semanas, ese día en la semana de hoy. Nunca se lee `dateText`.
  TimeBlockWeek? _semanaQueContiene(
    DaySchedule dia,
    List<TimeBlockWeek> semanas,
  ) {
    final fecha = _fechaDelDia(dia);
    if (fecha == null) return null;
    final lunes = _fechaPlana(_lunesDe(fecha));
    for (final semana in semanas) {
      if (semana.weekStart == lunes) return semana;
    }
    return null;
  }

  void previousDay() {
```

No hacen falta imports: la Tarea 4 ya importó `time_block_model.dart` (de ahí salen `TimeBlockWeek` y `TimeBlockRule`) y `time_blocks_service.dart`, y dejó `_fechaDelDia`, `_lunesDe` y `_fechaPlana` en el mismo controller.

**3.b — `lib/pages/horario/horario.dart`: la key y el texto de las horas** (`:25-26` tras la Tarea 6). Reemplazar esto:

```dart
  /// Botón para agregar un bloque propio (RF-BLQ-1). Solo lo ve el alumno.
  static const Key agregarBloqueKey = Key('horario-agregar-bloque');
```

por esto:

```dart
  /// Botón para agregar un bloque propio (RF-BLQ-1). Solo lo ve el alumno.
  static const Key agregarBloqueKey = Key('horario-agregar-bloque');

  /// La línea "Tus bloques: N h esta semana" de las vistas de día y semanal.
  static const Key horasSemanaKey = Key('horario-horas-semana');

  /// Las horas de esa línea: sin decimal cuando la cifra es entera y con uno
  /// cuando no ("12 h", "12.5 h"). Se redondea a un decimal antes de decidir,
  /// para que 12.96 salga "13 h" y no "13.0 h".
  ///
  /// Pura y expuesta para poder probarla, igual que [blockGeometry]. Solo da
  /// forma: el número lo manda el servidor y no se recalcula en la app.
  static String textoDeHoras(double horas) {
    final decimas = (horas * 10).round();
    final cifra = decimas % 10 == 0
        ? '${decimas ~/ 10}'
        : (decimas / 10).toStringAsFixed(1);
    return '$cifra h';
  }
```

**3.c — `lib/pages/horario/horario.dart`: la línea bajo la semana del ciclo** (hoy `:921-936`; `:1180-1195` tras la Tarea 6, y 17 más abajo tras 3.b, contado sobre los reemplazos de las Tareas 4 a 6; manda el texto). Es el único `Container` con `activeDay.weekText`. Reemplazar esto:

```dart
              Container(
                width: double.infinity,
                color: isDark ? const Color(0xFF1B1B22) : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                child: Text(
                  activeDay.weekText,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFB0B0C0)
                        : const Color(0xFF666666),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
```

por esto:

```dart
              Container(
                width: double.infinity,
                color: isDark ? const Color(0xFF1B1B22) : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      activeDay.weekText,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFB0B0C0)
                            : const Color(0xFF666666),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // RF-BLQ-6: las horas de los bloques propios en la semana
                    // del día activo, tal como las manda el servidor. Se lee
                    // aquí, dentro del Obx de build y fuera de cualquier
                    // LayoutBuilder, para que la línea se entere sola cuando
                    // llegan los bloques o cambia el día. Si no hay dato, no
                    // hay línea: nunca un 0 inventado.
                    if (controller.horasDeLaSemanaActiva case final horas?) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Tus bloques: ${textoDeHoras(horas)} esta semana',
                        key: horasSemanaKey,
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFFB0B0C0)
                              : const Color(0xFF666666),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
```

`controller`, `isDark` y `activeDay` ya están declarados en ese punto (en `build()` y en el `Obx` que devuelve la vista de día).

**3.d — `lib/pages/horario/horario.dart`: la vista semanal lee las horas fuera de su `LayoutBuilder`** (el final de `canceladosPorDia`, que agregó la Tarea 4, y el `return Container(` de `_landscapeWeekGrid`: `:852-857` tras la Tarea 6, 17 más abajo tras 3.b). Reemplazar esto:

```dart
        day: controller.bloquesCanceladosDelDia(
          _mismoDiaEnLaSemanaActiva(controller, day),
        ),
    };

    return Container(
```

por esto:

```dart
        day: controller.bloquesCanceladosDelDia(
          _mismoDiaEnLaSemanaActiva(controller, day),
        ),
    };
    // RF-BLQ-6 también en la vista semanal, que pinta los bloques de la
    // semana del día activo. Se lee aquí, fuera del LayoutBuilder, por lo
    // mismo que los bloques: así el Obx de [build] se entera solo.
    final horasDeBloques = controller.horasDeLaSemanaActiva;

    return Container(
```

**3.e — `lib/pages/horario/horario.dart`: la línea en la franja de abajo de la vista semanal**, junto al ciclo (hoy `:790-791`; `:1014-1015` tras la Tarea 6 y 21 más abajo tras 3.b y 3.d; es el único `cycle,` solo en su línea). Reemplazar esto:

```dart
                      Text(
                        cycle,
```

por esto:

```dart
                      // RF-BLQ-6: los encabezados de la vista semanal no
                      // llevan fecha (el horario de clases es semanal), así
                      // que la línea va aquí, junto al ciclo. Nunca un 0
                      // inventado: sin dato no hay línea.
                      if (horasDeBloques != null) ...[
                        Text(
                          'Tus bloques: ${textoDeHoras(horasDeBloques)} esta semana',
                          key: horasSemanaKey,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Text(
                        cycle,
```

`horasDeBloques` es un `final` local de `_landscapeWeekGrid`, así que el `!= null` lo promueve dentro del builder. Las dos líneas llevan la misma key, pero nunca están en pantalla a la vez: `build` pinta una vista o la otra. Nada más cambia en `horario.dart`: ni la grilla, ni el botón de agregar, ni el toque. Si un ancla de 3.b a 3.e no aparece literal, una tarea anterior la cambió: **PARAR** y reportar en vez de improvisar.

- [ ] **Paso 4: Correr la prueba y ver que pasa**

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test test/HU35_jeff/time_blocks_horas_test.dart
```

Esperado: **PASS**, `+21: All tests passed!` (4 pruebas del texto de las horas, 9 del total de la semana y 8 de la línea en pantalla). Sin la condición `horas > 0` de 3.a fallan dos: «con bloques, una semana en 0 no tiene total…» y la de widget «con bloques y la semana en 0, la línea no aparece». Este archivo no imprime líneas de `debugPrint`, porque el doble del controller no corre el `onInit` real.

- [ ] **Paso 5: Regresión del horario, suite completa y análisis**

`horario.dart` y `horario_controller.dart` son pantallas que ya existían, así que se corre todo lo que las monta y la suite entera:

```bash
cd "${REPO:?}"
"${FLUTTER:?}" test test/HU35_jeff/ test/HU31_jeff/
"${FLUTTER:?}" test
"${FLUTTER:?}" analyze
```

Esperado. Cada total es el del Paso 5 de la Tarea 6 más las 21 de este archivo, sin ninguna falla:
- `test/HU35_jeff/ test/HU31_jeff/` termina en `+237: All tests passed!`: 185 de `test/HU35_jeff/` (19 del service, 55 de cruces, 46 de la grilla, 21 del formulario, 23 de las acciones y las 21 de esta tarea) y 52 de `test/HU31_jeff/`. Si la Tarea 6 dio otro total en verde, el esperado aquí es ese más 21. En la salida siguen apareciendo líneas de `debugPrint` de pruebas anteriores (`Error al cargar … "StorageService" not found`, de las que montan el `HorarioController` real); no son pruebas en rojo.
- La suite completa termina en `+759: All tests passed!` (`+738` de la Tarea 6 más 21). Tarda entre dos y tres minutos y parece colgada en `test/HU33_jeff/registro_service_test.dart`: esa prueba espera de verdad los 120 s de `RegistroService.registroTimeout`. No es de esta tarea y no hay que tocarla.
- `analyze` da `7 issues found.`, la misma lista de la línea base de la Tarea 1, con el `avoid_print` en `lib/main.dart:93` (esta tarea no toca `main.dart`). Ninguno cae en `horario.dart`, `horario_controller.dart` ni `time_blocks_horas_test.dart`. El `// ignore: must_call_super` del doble es el mismo recurso de la Tarea 4; sin él, `analyze` sube a 8.

Si falla una prueba de las Tareas 4 a 6, **PARAR** y reportarlo: sus dobles no mandan semanas (`weeks` vacío), así que la línea nueva no aparece en ninguna de ellas, ni en la vista de día ni en la semanal, y no debería cambiar nada. Si aparece un issue nuevo de `analyze`, se corrige antes del commit. Si aparece uno que no se entiende, **PARAR** y reportarlo.

- [ ] **Paso 6: Anotar en el reporte el texto y las decisiones**

Texto exacto para el reporte de la rama (la Tarea 8 lo reúne):

```
Tarea 7 (la línea de horas de la semana):
- Texto visible nuevo, el que fija la spec: "Tus bloques: 12 h esta semana",
  debajo de "Semana N del ciclo" en la vista de día, y en la franja de abajo
  de la vista semanal, junto al ciclo. Las horas van sin decimal cuando son
  enteras y con uno cuando no, con punto: "12 h", "12.5 h"; se redondean a un
  decimal ("1 h 45 min" sale "1.8 h").
- El backend manda una entrada por cada semana de la ventana, con el total
  de la semana entera y hours: 0 en las que no tienen ocurrencias (RS-BE-34).
  La línea solo sale con horas mayores que 0 (D3): una semana en 0 (todos
  sus días cancelados, o fuera de las fechas del bloque), sin la semana en la
  respuesta, con hours en null o sin bloques, no tiene línea.
- La semana del día activo sale de su isoDate (D1), no de dateText.
- La línea sale en las dos vistas. En la semanal va en la franja de abajo
  (código, nombre, ciclo), porque sus encabezados no llevan fecha: el "esta
  semana" es la del día activo, la misma de los bloques que pinta.
- Cuando se ve, la línea suma unos 16 px a la franja de la semana y se los
  quita a la grilla de la vista de día. La grilla no scrollea: reparte su alto
  entre sus 16 filas de hora (_dynamicHourHeight, con un mínimo de 22 px por
  hora), así que cada hora queda alrededor de 1 px más baja. Conviene mirarlo
  en un teléfono chico antes de publicar.
```

- [ ] **Paso final: Commit**

```bash
cd "${REPO:?}"
test "$(git branch --show-current)" = feat/bloques-horario-fe || echo 'PARAR: rama equivocada'
git status --short
git add lib/pages/horario/horario_controller.dart \
        lib/pages/horario/horario.dart \
        test/HU35_jeff/time_blocks_horas_test.dart
git commit -m "feat(time-blocks): línea con las horas de los bloques propios en la semana del día activo (RF-BLQ-6)

Las dos vistas del horario muestran \"Tus bloques: N h esta semana\": la de
día, debajo de la semana del ciclo; la semanal, en la franja de abajo. El
número es el hours que el servidor manda en weeks para la semana de lunes a
domingo del día activo, que sale de su isoDate; la app no lo recalcula.

La línea solo sale con horas mayores que 0: sin bloques, sin la semana en la
respuesta, con hours en null o en 0, no aparece. Nunca se pinta un 0. La cifra va sin
decimal cuando es entera y con uno cuando no (12 h, 12.5 h)."
git log -1 --format=%B | grep -qi '^co-authored-by:' && echo 'PARAR: el commit trae trailer'
```

Antes del `git add`, `git status --short` solo puede listar esos tres archivos; si lista otro, o sale un `PARAR`, se detiene aquí. Sin trailer `Co-Authored-By`: el autor ya está configurado en git.
### Tarea 8: Cierre

> Una versión anterior de esta tarea se verificó en una copia descartable (en `/tmp`): un clon de la rama `feat/bloques-horario-fe` (`b25e76e`) con el código **literal** de las Tareas 1 a 7 de entonces, aplicado reemplazo por reemplazo, con un commit por tarea. Resultado: el Paso 2 dio los rojos que decía; cada reemplazo encontró su ancla una sola vez; el Paso 4 dio `OK`, también después del commit; `test/HU31_jeff/` y `test/HU33_jeff/` juntos dieron `+104`; `flutter analyze` quedó en los 7 issues de la línea base. Cada comprobación del script se forzó también a rojo a propósito y saltó: un `[@test]` a un archivo que no existe, una prueba sin enlazar, un archivo nuevo de `lib/` fuera de los targets, un código de alumno no sintético commiteado, una prueba que lee `test/HU31_jeff/fixtures/`, un commit con trailer, otro con un autor que no es el noreply y otro con un committer que no lo es. Un comentario que solo nombra `test/HU31_jeff/fixtures/` no la hace saltar. Después, una revisión pasó los targets y la aprobación al Paso 0 de la Tarea 1, quitó el reemplazo de `api-contracts.md` (el contrato de la Tarea 1 ya dice lo que hace el backend), sumó la comprobación de «e implementada», dejó `20230001` como único código permitido y sumó pruebas en las Tareas 1, 2 y 4 a 7. Después, las decisiones finales del dueño (D1 a D7) reescribieron partes de las Tareas 1 y 4 a 7 y la spec; con ellas, el código de las Tareas 1 a 7 se volvió a aplicar tal como está escrito en una copia descartable, sin git, y dio `+183` en `test/HU35_jeff/`, `+757` en la suite completa y los 7 issues de la línea base, y los reemplazos de spec del Paso 0 y del Paso 3 encontraron su ancla una sola vez. El script del Paso 1 se corrió sobre un repo git de prueba, con la base en un commit y todo lo demás en otro (autor noreply): dio exactamente los 7 rojos del Paso 2 y, después del Paso 3, `OK`. El worktree real no se tocó.

**Requisitos:** los del esqueleto: que todo quede verde y documentado. En concreto: las suites de la funcionalidad, las de regresión y la completa en verde; `analyze` sin issues nuevos frente a la línea base de la Tarea 1; cada `[@test]` de la spec apunta a un archivo que existe; la fila nueva del índice; y un reporte con todos los textos nuevos que ve la alumna, las decisiones que el dueño tiene que aprobar y el aviso de que el APK no se publica todavía.

**Archivos:**
- Crear (fuera del repo, no se commitea): `/tmp/cierre-bloques/verificar_cierre.sh`
- Modificar: `specs/features/time-blocks/time-blocks.spec.md`, la línea de estado que dejó el Paso 0 de la Tarea 1 (`:19` tras el Paso 0), y los `[@test]` de RF-BLQ-2, RF-BLQ-3 y RF-BLQ-7 (`:63-65`, `:79-81` y `:182-184` antes del Paso 0). El Paso 0 de la Tarea 1 sumó tres líneas de targets arriba, y cada reemplazo de aquí corre los de abajo: hay que guiarse por el texto del ancla, no por el número. Los targets **no** se tocan aquí: los sumó el Paso 0, con el sí del dueño y antes de implementar.
- Modificar: `docs/specs/feature-index.md:25` (la fila 18 va justo debajo de la 17). Ninguna tarea anterior lo toca.
- Modificar: `specs/features/schedule/schedule.spec.md:29` y `:33`. **No está en el esqueleto.** Se agrega porque RF-BLQ-4 (domingo en la vista semanal) y RF-BLQ-5 (el toque de un bloque propio) cambian dos cosas que esa spec afirma al pie de la letra: «a weekly grid from Monday to Saturday» y «Al tocar un bloque de curso, se navega a `DescripCursosPage`». No cambia ningún requisito: solo alinea el texto con lo que la spec de los bloques ya aprobó. Va al reporte.
- `docs/specs/api-contracts.md` **no** se toca: la viñeta de `weeks` que escribió la Tarea 1 ya dice lo que hace el backend (una entrada por cada semana entre el lunes de `from` y el de `to`, con el total de la semana entera y `hours: 0` en una semana sin ocurrencias; RS-BE-34, `weeklyHours` del plan del backend y su propio `api-contracts.md`), y su Paso 7.b ya documentó el `isoDate` de los días de `GET /schedule/me/sessions`.
- Test: `/tmp/cierre-bloques/verificar_cierre.sh`, y como regresión `test/HU35_jeff/`, `test/HU31_jeff/`, `test/HU33_jeff/` y la suite completa.

**Interfaces:**
- Consume, de las Tareas 1 a 7, solo archivos y rutas (esta tarea no importa ni llama ningún símbolo):
  - Las seis pruebas y cuántas trae cada una: `test/HU35_jeff/time_blocks_service_test.dart` (19, Tarea 1), `time_blocks_conflicto_test.dart` (55, Tarea 2), `time_blocks_grilla_test.dart` (46: 11 de la Tarea 3 y 35 de la 4), `time_blocks_form_test.dart` (21, Tarea 5), `time_blocks_acciones_test.dart` (23, Tarea 6) y `time_blocks_horas_test.dart` (21, Tarea 7). En total, 185.
  - Los tres archivos de `lib/` que la rama toca fuera de los `targets` originales y que el Paso 0 de la Tarea 1 sumó a la spec: `lib/services/api_client.dart` (`patchJson`), `lib/services/auth_service.dart` (`logout()` vacía los bloques) y `lib/pages/horario/horario_layout.dart` (lo creó la Tarea 3). Y el commit `docs(time-blocks): la spec queda aprobada por el dueño…` de ese paso.
  - La sección `## Time Blocks (bloques de horario propios) — RF-BLQ-1 a RF-BLQ-7` que la Tarea 1 (Paso 7) dejó al final de `docs/specs/api-contracts.md`, y el `"isoDate"` que su Paso 7.b sumó al ejemplo de `days`.
  - La línea base de `analyze` que midió la Tarea 1 (Paso 1): 7 issues preexistentes, con el `avoid_print` de `lib/main.dart` que la Tarea 1 (seis líneas) y la Tarea 5 (dos imports) corrieron de la línea 85 a la 93.
  - Las notas «para el reporte» de cada tarea (Tarea 1 Paso 8, Tarea 2 Paso 6, Tarea 3 Paso 6, Tarea 4 Paso 6, Tarea 5 Paso 7, Tarea 6 Paso 6 y Tarea 7 Paso 6). El Paso 7 de abajo las reúne; si el ejecutor anotó alguna distinta, manda la anotada.
- Produce: nada nuevo en código. Tres archivos de documentación y el reporte final de la rama.
- Antes de empezar, confirmar la rama y que el Paso 0 y las siete tareas están hechos y commiteados:
  ```bash
  cd "${REPO:?}"
  test "$(git branch --show-current)" = feat/bloques-horario-fe || echo 'PARAR: rama equivocada'
  git status --short
  git log --format=%s d871bf3..HEAD | grep -cE '^feat\((bloques|time-blocks)\): '
  git log --format=%s d871bf3..HEAD | grep -c '^docs(time-blocks): la spec queda aprobada por el dueño'
  ls test/HU35_jeff/
  ```
  Esperado: ningún `PARAR`; `git status --short` no muestra nada en `lib/` ni en `test/`; el primer conteo da `7` (las siete tareas commitean con `feat(time-blocks):`; la expresión acepta también `feat(bloques):`, el alcance que la Tarea 1 usaba antes) y el segundo `1` (el Paso 0 de la Tarea 1); y `ls` lista los seis archivos de arriba y ninguno más. Si algo no coincide, **PARAR** y reportarlo: una tarea anterior no se arregla desde aquí.

- [ ] **Paso 1: Escribir la prueba que falla**

  Esta tarea no agrega código a la app, así que su prueba no es de Dart: es un script que comprueba el cierre sobre el árbol y el historial de la rama. Vive en `/tmp` y **no** se commitea. Solo lee y no escribe nada.

  ```bash
  mkdir -p /tmp/cierre-bloques
  ```

  Crear `/tmp/cierre-bloques/verificar_cierre.sh` con este contenido:

  ```bash
  #!/bin/bash
  # Cierre de los bloques de horario propios (Tarea 8 del plan frontend).
  # Comprueba que la funcionalidad quedó documentada y enlazada. Solo lee el
  # árbol y el historial; no escribe nada.
  #
  # Uso: bash /tmp/cierre-bloques/verificar_cierre.sh [raíz del repo]
  # Sin argumento, la raíz es $REPO (ver "Variables de los comandos").
  set -u

  RAIZ="${1:-${REPO:?falta REPO: la raíz del worktree de feat/bloques-horario-fe}}"
  # El main del que salió la rama. Es un hash fijo a propósito: el `main` local
  # de este repo está atrasado (8ff7b52) y origin/main puede moverse con otros
  # merges.
  BASE="${BASE:-d871bf3}"
  SPEC="specs/features/time-blocks/time-blocks.spec.md"
  DIR_SPEC="specs/features/time-blocks"
  HORARIO="specs/features/schedule/schedule.spec.md"
  INDICE="docs/specs/feature-index.md"
  CONTRATO="docs/specs/api-contracts.md"

  cd "$RAIZ" || exit 2
  fallos=0
  falla() { echo "FALLA: $1"; fallos=$((fallos + 1)); }

  # 1. Cada [@test] de la spec apunta a un archivo que existe.
  for p in $(grep -o '\[@test\] [^`]*' "$SPEC" | sed 's/^\[@test\] //'); do
    [ -f "$DIR_SPEC/$p" ] || falla "[@test] a un archivo que no existe: $p"
  done

  # 2. Cada prueba de test/HU35_jeff/ está enlazada desde la spec.
  for f in test/HU35_jeff/*_test.dart; do
    grep -qF "[@test] ../../../$f\`" "$SPEC" || falla "prueba sin enlazar en la spec: $f"
  done

  # 3. Cada requisito enlaza, dentro de su propia sección, las pruebas que lo cubren.
  enlaza() {
    awk -v rf="### $1 " -v t="[@test] ../../../test/HU35_jeff/$2\`" '
      index($0, "### ") == 1 { dentro = (index($0, rf) == 1) }
      dentro && index($0, t) { hallado = 1 }
      END { exit hallado ? 0 : 1 }' "$SPEC" || falla "$1 no enlaza $2"
  }
  enlaza RF-BLQ-1 time_blocks_form_test.dart
  enlaza RF-BLQ-2 time_blocks_form_test.dart
  enlaza RF-BLQ-2 time_blocks_conflicto_test.dart
  enlaza RF-BLQ-3 time_blocks_conflicto_test.dart
  enlaza RF-BLQ-3 time_blocks_form_test.dart
  enlaza RF-BLQ-4 time_blocks_grilla_test.dart
  enlaza RF-BLQ-5 time_blocks_acciones_test.dart
  enlaza RF-BLQ-6 time_blocks_horas_test.dart
  enlaza RF-BLQ-7 time_blocks_service_test.dart
  enlaza RF-BLQ-7 time_blocks_grilla_test.dart

  # 4. Todo archivo de lib/ que tocó la rama cae dentro de los targets de la spec
  #    (AGENTS.md, paso 8: "Implementa solo archivos incluidos en targets").
  targets=$(awk '/^targets:/ { t = 1; next }
                 t && /^  - / { sub(/^  - \.\.\/\.\.\/\.\.\//, ""); print; next }
                 t { exit }' "$SPEC")
  set -f   # los targets llevan ** y no se deben expandir contra el disco
  for f in $(git diff --name-only "$BASE"...HEAD -- lib/); do
    cubierto=0
    for t in $targets; do
      case "$t" in
        *'/**') prefijo="${t%'**'}"; case "$f" in "$prefijo"*) cubierto=1 ;; esac ;;
        *) [ "$f" = "$t" ] && cubierto=1 ;;
      esac
    done
    [ "$cubierto" -eq 1 ] || falla "archivo de la rama fuera de los targets de la spec: $f"
  done
  set +f

  # 5. El estado de la spec: aprobada (Paso 0 de la Tarea 1) e implementada.
  grep -qF 'Pendiente de su aprobación' "$SPEC" \
    && falla "la spec sigue diciendo que está pendiente de aprobación"
  grep -qF 'e implementada' "$SPEC" \
    || falla "la spec no dice que está implementada"

  # 6. La fila del índice de funcionalidades.
  grep -qF '| 18 | Bloques de horario propios | `specs/features/time-blocks/time-blocks.spec.md` |' "$INDICE" \
    || falla "$INDICE no tiene la fila de los bloques de horario propios"

  # 7. La spec del horario ya no contradice a la de los bloques.
  grep -qF 'from Monday to Saturday' "$HORARIO" \
    && falla "$HORARIO sigue diciendo que la vista semanal llega al sábado"
  grep -qF 'RF-BLQ-5' "$HORARIO" \
    || falla "$HORARIO no dice que el toque de un bloque propio abre su hoja"

  # 8. El contrato de las rutas nuevas y el isoDate de los días (lo escribió la Tarea 1).
  grep -q '^## Time Blocks' "$CONTRATO" \
    || falla "$CONTRATO no documenta las rutas /time-blocks"
  grep -qF '"isoDate": "2026-01-12"' "$CONTRATO" \
    || falla "$CONTRATO no documenta el isoDate de GET /schedule/me/sessions"

  # 9. Repo público: lo que agregó la rama no trae ningún código de alumno que no
  #    sea el sintético 20230001, y ninguna línea de las pruebas nuevas que no sea
  #    comentario nombra los fixtures reales ni el spike del portal.
  codigos=$(git diff "$BASE"...HEAD | grep '^+' | grep -oE '[0-9]+' \
            | grep -xE '20[0-9]{6}' | sort -u | grep -vxE '20230001')
  [ -z "$codigos" ] || falla "códigos de alumno no sintéticos: $(echo $codigos)"
  lecturas=$(grep -rnE 'fixtures|spike-portal' test/HU35_jeff \
             | grep -vE '^[^:]+:[0-9]+:[[:space:]]*//')
  [ -z "$lecturas" ] \
    || falla "una prueba de test/HU35_jeff/ lee fixtures reales: $(echo "$lecturas" | cut -d: -f1-2 | tr '\n' ' ')"

  # 10. Commits de la rama: sin trailer Co-Authored-By, y autor y committer con el
  #     noreply de GitHub (el repo es público).
  git log --format=%B "$BASE"..HEAD | grep -qi '^co-authored-by:' \
    && falla "hay commits de la rama con trailer Co-Authored-By"
  ajenos=$(git log --format='%h %ae%n%h %ce' "$BASE"..HEAD \
           | grep -v '@users\.noreply\.github\.com$' | cut -d' ' -f1 | sort -u)
  [ -z "$ajenos" ] || falla "commits firmados sin el noreply de GitHub: $(echo $ajenos)"

  if [ "$fallos" -eq 0 ]; then
    echo "OK: los bloques de horario propios quedaron documentados y enlazados."
    exit 0
  fi
  echo "$fallos comprobación(es) en rojo."
  exit 1
  ```

  El script corre con el `/bin/bash` 3.2 de macOS: no usa arreglos asociativos ni `mapfile`. Las comprobaciones 5, 6 y 7 miran texto que hoy existe, o que falta, al pie de la letra; si alguien retoca esas frases, se ajusta el script, no la documentación. La primera mitad de la 9 mira las líneas que agregaron los commits de la rama (código, pruebas y documentación): `20230001` es la alumna sintética de todas las pruebas y el único código permitido; la segunda cuenta del caso 8 de la Tarea 1 es `'alumna.b.test'`, que no tiene forma de código. Con `20[0-9]{6}` también entrarían fechas pegadas sin guiones; la rama las escribe siempre con guiones (`2026-09-21`), así que no chocan.

- [ ] **Paso 2: Correr la prueba y ver que falla**

  ```bash
  bash /tmp/cierre-bloques/verificar_cierre.sh; echo "exit=$?"
  ```

  Esperado: exactamente estas siete líneas, en este orden, y `exit=1`:

  ```
  FALLA: RF-BLQ-2 no enlaza time_blocks_conflicto_test.dart
  FALLA: RF-BLQ-3 no enlaza time_blocks_form_test.dart
  FALLA: RF-BLQ-7 no enlaza time_blocks_grilla_test.dart
  FALLA: la spec no dice que está implementada
  FALLA: docs/specs/feature-index.md no tiene la fila de los bloques de horario propios
  FALLA: specs/features/schedule/schedule.spec.md sigue diciendo que la vista semanal llega al sábado
  FALLA: specs/features/schedule/schedule.spec.md no dice que el toque de un bloque propio abre su hoja
  7 comprobación(es) en rojo.
  exit=1
  ```

  Son justo las siete cosas que arregla el Paso 3. Las comprobaciones 1, 2, 4, 8, 9 y 10, y la primera de la 5, ya pasan: miden lo que dejaron el Paso 0 y las Tareas 1 a 7. Si sale un `FALLA` de alguna de ellas (un `[@test]` a un archivo que no existe, una prueba sin enlazar, un archivo de `lib/` fuera de los targets, la spec todavía pendiente de aprobación, el contrato sin su sección o sin el `isoDate`, un código de alumno real, una prueba que lee fixtures, un commit con `Co-Authored-By` o firmado con otro correo), el problema es de una tarea anterior o del Paso 0: **PARAR** y reportarlo. No se arregla desde aquí.

- [ ] **Paso 3: Implementación mínima**

  Siete reemplazos (3.a a 3.g) en tres archivos de documentación. Ninguno toca código.

  **3.a — `specs/features/time-blocks/time-blocks.spec.md`: el estado** (`:19`, la línea que dejó el Paso 0 de la Tarea 1). Reemplazar esto, con la fecha `AAAA-MM-DD` que escribió el Paso 0:

  ```markdown
  > Aprobada por el dueño el AAAA-MM-DD, con los targets de arriba.
  ```

  por esto, con la misma fecha:

  ```markdown
  > Aprobada por el dueño el AAAA-MM-DD, con los targets de arriba, **e implementada.** Está
  > probada entera contra dobles, pero **todavía no contra el backend desplegado**: las rutas
  > `/time-blocks/**`, su migración `0012_time_blocks.sql` y el `isoDate` de los días de
  > `GET /schedule/me/sessions` tienen que estar en producción antes de publicar el APK.
  ```

  Las demás líneas del estado (`> Estado: **diseñada …**`, `> Contraparte de backend: …`, `> (RS-BE-30 a RS-BE-36).` y las tres de `> Ajustada el 2026-09-21 …`) no se tocan, ni los targets, que sumó el Paso 0. La redacción sigue el precedente de `specs/features/registro/registro.spec.md` (commit `f50f070`), que dejó dicho lo que faltaba probar.

  **3.b — la misma spec: RF-BLQ-2 también enlaza sus validadores** (`:63-65` antes del Paso 0; `:69-71` tras el Paso 0 y 3.a). Reemplazar esto:

  ```markdown
  el que él manda, no uno inventado por la app.

  `[@test] ../../../test/HU35_jeff/time_blocks_form_test.dart`
  ```

  por esto:

  ```markdown
  el que él manda, no uno inventado por la app.

  `[@test] ../../../test/HU35_jeff/time_blocks_form_test.dart`
  `[@test] ../../../test/HU35_jeff/time_blocks_conflicto_test.dart`
  ```

  Los validadores puros de RF-BLQ-2 («La validación vive en funciones puras…») se prueban en `time_blocks_conflicto_test.dart` (Tarea 2), no en el del formulario.

  **3.c — la misma spec: RF-BLQ-3 también enlaza el aviso en pantalla** (`:79-81` antes del Paso 0; `:86-88` tras el Paso 0, 3.a y 3.b). Reemplazar esto:

  ```markdown
  termina 18:00 y la otra empieza 18:00) **no** es cruce.

  `[@test] ../../../test/HU35_jeff/time_blocks_conflicto_test.dart`
  ```

  por esto:

  ```markdown
  termina 18:00 y la otra empieza 18:00) **no** es cruce.

  `[@test] ../../../test/HU35_jeff/time_blocks_conflicto_test.dart`
  `[@test] ../../../test/HU35_jeff/time_blocks_form_test.dart`
  ```

  El aviso con «Guardar igual» y «Volver a editar» se prueba en el grupo `WIDGET · aviso de cruce antes de guardar (RF-BLQ-3)` de `time_blocks_form_test.dart` (Tarea 5).

  **3.d — la misma spec: RF-BLQ-7 también enlaza la ventana y la lista propia** (`:182-184` antes del Paso 0; `:190-192` tras el Paso 0 y 3.a a 3.c). Reemplazar esto:

  ```markdown
  trae `isoDate`, la ventana es la de las cuatro semanas alrededor de hoy.

  `[@test] ../../../test/HU35_jeff/time_blocks_service_test.dart`
  ```

  por esto:

  ```markdown
  trae `isoDate`, la ventana es la de las cuatro semanas alrededor de hoy.

  `[@test] ../../../test/HU35_jeff/time_blocks_service_test.dart`
  `[@test] ../../../test/HU35_jeff/time_blocks_grilla_test.dart`
  ```

  La ventana que pide el horario, la fecha de cada día (`isoDate`) y los bloques fuera de `_todasLasSecciones` se prueban en los grupos `UNITARIA · la ventana de bloques que pide el horario (RF-BLQ-7)`, `UNITARIA · la fecha de cada día del horario (isoDate, D1)` y `UNITARIA · qué bloques propios caen en cada día (RF-BLQ-4)` de `time_blocks_grilla_test.dart` (Tarea 4), no en el del service. Los dos `[@test]` seguidos, sin línea en blanco, son el mismo formato que usa `specs/features/academic-record/academic-record.spec.md:143-146`.

  **3.e — `docs/specs/feature-index.md`: la fila 18** (`:25`). Reemplazar esto (la fila 17, completa):

  ```markdown
  | 17 | Récord académico | `specs/features/academic-record/academic-record.spec.md` | HU34 | RF-REC-1 a RF-REC-6: tarjeta en Perfil, pantalla /mi-record, borrado a pedido y consentimiento antes del portal | `lib/pages/academic_record/**`, `lib/services/academic_record_service.dart`, `lib/models/academic_record_model.dart`, `lib/components/portal_consent/**` | Implementado — pendiente de verificación end-to-end |
  ```

  por esto:

  ```markdown
  | 17 | Récord académico | `specs/features/academic-record/academic-record.spec.md` | HU34 | RF-REC-1 a RF-REC-6: tarjeta en Perfil, pantalla /mi-record, borrado a pedido y consentimiento antes del portal | `lib/pages/academic_record/**`, `lib/services/academic_record_service.dart`, `lib/models/academic_record_model.dart`, `lib/components/portal_consent/**` | Implementado — pendiente de verificación end-to-end |
  | 18 | Bloques de horario propios | `specs/features/time-blocks/time-blocks.spec.md` | HU35 | RF-BLQ-1 a RF-BLQ-7: bloques propios del alumno en el horario (crear, editar, corregir un día suelto), aviso de cruce, reparto lado a lado con las clases, domingo en la vista semanal y horas por semana | `lib/pages/time_blocks/**`, `lib/services/time_blocks_service.dart`, `lib/models/time_block_model.dart`, `lib/pages/horario/horario.dart`, `lib/pages/horario/horario_controller.dart`, `lib/pages/horario/horario_layout.dart` | Implementado — pendiente de probar contra el backend desplegado |
  ```

  `HU35` es el número que ya usan las carpetas de prueba de los dos repos (`test/HU35_jeff/`). La fila de Schedule (la 5) no se toca.

  **3.f — `specs/features/schedule/schedule.spec.md`: el toque** (`:29`). Reemplazar esto:

  ```markdown
  - **Course block tap**: Al tocar un bloque de curso, se navega a `DescripCursosPage` con el `idSeccion` correspondiente (no existe un details dialog separado para evaluaciones).
  ```

  por esto:

  ```markdown
  - **Course block tap**: Al tocar un bloque de curso, se navega a `DescripCursosPage` con el `idSeccion` correspondiente (no existe un details dialog separado para evaluaciones). Un bloque propio del alumno no es un curso: su toque abre la hoja de acciones de `specs/features/time-blocks/time-blocks.spec.md` (RF-BLQ-5).
  ```

  **3.g — la misma spec: el domingo** (`:33`). Reemplazar esto:

  ```markdown
  - **Landscape weekly calendar**: In horizontal orientation, `HorarioPage` remains the same page and renders a weekly grid from Monday to Saturday with the current backend-backed class blocks, course colors, evaluation markers, advising markers, tap behavior, and current-time indicator when applicable.
  ```

  por esto:

  ```markdown
  - **Landscape weekly calendar**: In horizontal orientation, `HorarioPage` remains the same page and renders a weekly grid from Monday to Sunday with the current backend-backed class blocks, the student's own time blocks (`specs/features/time-blocks/time-blocks.spec.md`, RF-BLQ-4), course colors, evaluation markers, advising markers, tap behavior, and current-time indicator when applicable.
  ```

  Esa línea está en inglés, como el resto de la sección; la 29 ya estaba en español. Cada una sigue en su idioma.

  `docs/specs/api-contracts.md` no se toca: la viñeta de `weeks` de la Tarea 1 ya coincide con el backend (RS-BE-34 y el `api-contracts.md` de su plan: una entrada por cada semana entre el lunes de `from` y el de `to`, con el total de la semana entera y `hours: 0` si no tiene ocurrencias), y el `isoDate` de los días ya está desde su Paso 7.b.

  Si algún ancla de 3.a a 3.g no aparece literal, **PARAR** y reportarlo en vez de improvisar el reemplazo.

- [ ] **Paso 4: Correr la prueba y ver que pasa**

  ```bash
  bash /tmp/cierre-bloques/verificar_cierre.sh; echo "exit=$?"
  ```

  Esperado: PASS.

  ```
  OK: los bloques de horario propios quedaron documentados y enlazados.
  exit=0
  ```

- [ ] **Paso 5: Suites de la funcionalidad y de regresión**

  ```bash
  cd "${REPO:?}"
  "${FLUTTER:?}" test test/HU35_jeff/
  "${FLUTTER:?}" test test/HU31_jeff/ test/HU33_jeff/
  ```

  Esperado:
  - La primera: `+185: All tests passed!`. Son 19 del service, 55 de validadores y cruces, 46 de la grilla, 21 del formulario, 23 de la hoja de acciones y 21 de la línea de horas. Si el total no cuadra, se corre archivo por archivo (`"${FLUTTER:?}" test test/HU35_jeff/<archivo>`) y se compara con esas cifras para saber de qué tarea viene la diferencia.
  - La segunda: `+104: All tests passed!` (52 de `HU31_jeff`, que cubre la geometría y el contenido de bloque del horario, y 52 de `HU33_jeff`). Tarda unos dos minutos y parece colgada en `test/HU33_jeff/registro_service_test.dart` «caso 3: el plazo vencido NO dice que falló…»: esa prueba espera de verdad los 120 s de `RegistroService.registroTimeout`.

  En la salida aparecen líneas de `debugPrint` que no son pruebas en rojo, porque las provocan esas mismas pruebas a propósito: `Error al cargar …: "StorageService" not found` (las pruebas que montan el `HorarioController` real), `Error cargando los bloques de horario: Exception: socket`, `Error escribiendo un bloque de horario: Exception: socket`, `Error guardando el bloque: Bad state: inesperado` y `Error en una acción de bloque: Bad state: inesperado`.

  Si alguna prueba falla, **PARAR** y reportarlo con el nombre de la prueba: esta tarea no tocó código, así que la falla viene de una tarea anterior, y se corrige ahí.

- [ ] **Paso 6: Suite completa y análisis contra la línea base**

  ```bash
  cd "${REPO:?}"
  "${FLUTTER:?}" test
  "${FLUTTER:?}" analyze
  ```

  Esperado:
  - `+759: All tests passed!`, en unos dos minutos y medio: las 574 que había antes de la rama más las 185 de `HU35_jeff`.
  - `analyze`: `7 issues found.`, todos `info` y todos preexistentes, los mismos de la línea base de la Tarea 1:
    ```
    info • Don't invoke 'print' in production code. … • lib/main.dart:93:9 • avoid_print
    info • 'withOpacity' is deprecated … • lib/pages/chat/chat_page.dart:695:37 • deprecated_member_use
    info • 'Share' is deprecated … • lib/services/attendance_risk_service.dart:55:11 • deprecated_member_use
    info • 'shareXFiles' is deprecated … • lib/services/attendance_risk_service.dart:55:17 • deprecated_member_use
    info • The import of 'package:flutter/services.dart' is unnecessary … • test/HU20_jeff/otp_field_ime_test.dart:32:8 • unnecessary_import
    info • The imported package 'path_provider_platform_interface' isn't a dependency … • test/HU26_sam/export_csv_cajanegra_test.dart:20:8 • depend_on_referenced_packages
    info • The imported package 'share_plus_platform_interface' isn't a dependency … • test/HU26_sam/export_csv_cajanegra_test.dart:21:8 • depend_on_referenced_packages
    ```
    La única diferencia con la línea base es que el `avoid_print` pasó de `lib/main.dart:85` a `:93`, porque la Tarea 1 metió seis líneas antes y la Tarea 5 dos imports. Ninguno de los siete cae en un archivo de esta funcionalidad. `analyze` termina con código de salida 1 por esos `info`, igual que en la línea base: no es una falla nueva.

  Si la suite tiene una falla, o si `analyze` da un issue que no está en esa lista, **PARAR** y reportarlo. No se arregla desde esta tarea: se anota con su archivo y su línea para la tarea que lo introdujo.

- [ ] **Paso 7: Reporte final para el dueño**

  El ejecutor entrega la rama con este texto. Si en los Pasos 5 y 6 midió otra cifra en verde, pone la medida; si en su tarea anotó algún punto distinto, pone el anotado. Va en el mensaje final. **No** va a ningún archivo del repo.

  ```
  Reporte de cierre: bloques de horario propios (frontend)
  Rama feat/bloques-horario-fe, sin push. Spec: specs/features/time-blocks/time-blocks.spec.md
  (RF-BLQ-1 a RF-BLQ-7).

  1. VERIFICACIÓN
  - test/HU35_jeff/: +185, en verde (19 service, 55 validadores y cruces, 46 grilla,
    21 formulario, 23 hoja de acciones, 21 línea de horas).
  - Regresión test/HU31_jeff/ y test/HU33_jeff/: +104, en verde.
  - Suite completa: +759, en verde.
  - flutter analyze: 7 issues, los mismos 7 preexistentes de la línea base (avoid_print en
    lib/main.dart:93, que antes estaba en la 85; tres deprecated_member_use; un
    unnecessary_import; dos depend_on_referenced_packages). Ninguno en archivos de esta
    funcionalidad.
  - Cada [@test] de la spec apunta a un archivo que existe, y las seis pruebas de
    test/HU35_jeff/ están enlazadas junto al requisito que cubren.

  2. EL APK NO SE PUBLICA TODAVÍA
  No se publica un APK con esta rama hasta que el backend esté desplegado con las rutas
  /time-blocks/** (RS-BE-30 a RS-BE-35, rama feat/bloques-horario del backend) y con su
  migración drizzle/0012_time_blocks.sql aplicada en la base de producción. Sin eso, la app
  pide rutas que no existen: los bloques no cargan (el horario de clases se sigue viendo) y
  guardar uno muestra "Error del servidor", el texto que ApiClient pone cuando la respuesta
  no trae JSON (el 404 de una ruta que no existe no lo trae). Todo lo de esta rama está
  probado contra dobles, nunca contra el backend real.
  El backend desplegado también tiene que mandar isoDate en cada día de
  GET /schedule/me/sessions (D1, RS-BE-36, Tarea 7 del plan del backend). Sin ese campo, la app no se rompe, pero pide solo las
  cuatro semanas alrededor de hoy y cada día toma sus bloques de la semana de hoy: al
  navegar a otra semana del ciclo, los bloques no serían los de esa semana.
  El CORS del backend (src/server.ts) suma PATCH en la misma tarea que crea las rutas
  (D5): con ese backend desplegado, editar un bloque también funciona en una build web. La
  app nativa (Android e iOS) no hace preflight y no depende de eso.

  3. TEXTOS NUEVOS QUE VE LA ALUMNA (leerlos antes de publicar)
  Horario
  - Botón de agregar (solo alumnos, en vertical y fuera de la lista de chats; ver 4.e y 4.i):
    tooltip "Agregar bloque".
  - "Tus bloques: 12 h esta semana": bajo "Semana N del ciclo" en la vista de día, y en la
    franja de abajo de la vista semanal, junto al ciclo. Es el texto que fija la spec. Las
    horas van sin decimal si son enteras y con uno si no ("12 h", "12.5 h"), redondeadas a
    un decimal ("1 h 45 min" sale "1.8 h"). Solo sale con horas mayores que 0: una semana
    en 0, sin dato o sin bloques no tiene línea (D3).
  - El bloque propio muestra el nombre que escribió la alumna, en mayúsculas como los
    cursos y entero (sin el corte en "/" del nombre bilingüe de los cursos), sin insignia,
    salón ni sección. Un día cancelado se ve en su hora de siempre, a 40 % de opacidad y
    con "Este día está cancelado" debajo del nombre (D2; si el bloque queda chico, no
    entra y se omite, como la sección de una clase). La columna "Domingo" de la vista semanal
    usa el nombre que ya manda el backend.
  Formulario (/bloque)
  - Títulos: "Nuevo bloque" / "Editar bloque". Botón: "Guardar bloque".
  - Etiquetas: "Nombre", "Color", "Días", "Hora de inicio", "Hora de fin", "Desde", "Hasta".
    Pista del nombre: "Ej. Prácticas". Vacíos: "--:--" en las horas y "Elegir" en las fechas.
    Ya elegidas, las horas se ven en 24 h ("14:00") y las fechas como "2026-09-21", igual
    que en el formulario de asesorías del docente.
  - Días: "Lu", "Ma", "Mi", "Ju", "Vi", "Sá", "Do".
  - Validación: "Ponle un nombre al bloque." / "El nombre no puede pasar de 60 caracteres." /
    "Marca al menos un día." / "Hay un día que no existe." / "Indica la hora de inicio y de
    fin." / "Hora inválida (usa HH:MM)." / "La hora de fin debe ser posterior a la de
    inicio." / "El bloque tiene que estar entre las 7 am y las 10 pm." / "Indica desde y
    hasta cuándo va el bloque." / "Fecha inválida (usa AAAA-MM-DD)." / "La fecha de fin no
    puede ser anterior a la de inicio."
  Aviso de cruce (antes de guardar)
  - Título "Hay un cruce"; botones "Volver a editar" y "Guardar igual".
  - Un cruce: "Se cruza con CURSO DE PRUEBA A, martes de 4:00 pm a 6:00 pm." Varios: "Se
    cruza con:" y una línea "• <nombre>, <día> de <hora> a <hora>" por cruce. La spec fija
    los datos y su orden; la mayúscula inicial, el punto final y la lista los decidió la
    implementación. Las horas van en 12 h, como en la spec.
  - Con una clase, el nombre es el del curso tal como lo manda el backend: si trae su
    nombre en inglés ("CURSO / COURSE"), sale entero, aunque la grilla lo corta en la
    barra. Si la clase llega sin nombre, dice "una clase". Con otro bloque propio, su
    nombre tal como lo escribió la alumna.
  Hoja al tocar un bloque propio
  - Cabecera: el nombre del bloque y el día, por ejemplo "Lunes 21 de septiembre, 14:00 a
    18:00". Aquí las horas van en 24 h, como en el formulario, y no en 12 h como en el
    aviso de cruce.
  - Acciones: "Editar el bloque" (debajo, "Todas las semanas"), "Cancelar solo este día",
    "Cambiar la hora solo este día", "Volver al patrón" (en un día movido o cancelado) y
    "Borrar el bloque".
  - Un día cancelado: una sola acción, "Volver al patrón", con "Este día está cancelado"
    debajo.
  - Al cancelar un día: aviso "Se canceló este día." con el botón "Deshacer"; se cierra
    solo a los 4 s.
  - Borrado: título "¿Borrar el bloque?", cuerpo 'Se borra "<nombre>" con todos sus días,
    no solo este.', botones "Cancelar" y "Borrar".
  - Cambiar la hora de un día: título "Cambiar la hora solo este día", "Hora de inicio" y
    "Hora de fin" lado a lado, "--:--" si falta una, botones "Cancelar" y "Guardar". Los
    errores son los de validación de horas de arriba.
  Errores
  - Del servidor: su mensaje, tal cual llega (RF-BLQ-2). Si la respuesta de error no trae
    JSON, "Error del servidor", el texto que ya pone ApiClient para toda la app. El de
    TIME_BLOCK_LIMIT_REACHED lo escribe el backend (D4); en su plan dice "Llegaste al
    máximo de 20 bloques guardados, contando los que ya terminaron. Borra uno viejo para
    crear otro."
  - Los 400 de validación del backend (INVALID_REQUEST_BODY, INVALID_JSON_BODY,
    INVALID_ROUTE_PARAMS, INVALID_QUERY_PARAMS) traen message en inglés ("Invalid request
    body" y sus pares), y la app lo mostraría tal cual. En la práctica no se alcanza, porque
    los validadores de la app replican las reglas del servidor. El dueño lo decide junto con
    el aviso de textos de la Tarea 5 del backend.
  - Sin respuesta del servidor (red caída, plazo vencido): "No se pudo guardar tu bloque.
    Inténtalo de nuevo.", también al cancelar un día o al borrar un bloque. Si se prefiere
    un texto que no diga "guardar" para esos dos casos, se agrega en el service.
  - Selectores de hora y de fecha (formulario y cambio de hora de un día): "Elige la
    hora", "Elige la fecha", "Cancelar" y "Aceptar", pasados con helpText, cancelText y
    confirmText (D7). Los nombres de los meses y los rótulos internos del selector siguen
    en inglés: la app no carga flutter_localizations y la rama no agrega dependencias.

  4. DECISIONES
  Ya tomadas por el dueño (D1 a D7) y escritas en la spec, salvo la posición del botón de
  e), que fija D7 y la spec no nombra; se listan para que se vean juntas:
  a) Fechas (D1, Tareas 4 y 7). Cada día del horario lleva su isoDate y la app ya no lee
     fechas de dateText ni del ciclo del alumno. La ventana es la del ciclo, del primer al
     último isoDate; si pasara de 120 días (un ciclo de 16 semanas son 112), se piden 120
     desde el lunes de la semana del día activo, y al cambiar de semana, los de la semana
     nueva.
  b) Día cancelado (D2, Tareas 4 y 6). Se pinta en su hora de siempre, a 40 % de
     opacidad y con "Este día está cancelado"; al tocarlo, la hoja solo ofrece "Volver al
     patrón". El aviso "Se canceló este día." trae además un "Deshacer" que se cierra solo
     a los 4 s (persist: false), para que no quede de pantalla en pantalla ni deje en cola
     los avisos de otras pantallas.
  c) Semanas en 0 (D3, Tarea 7). La línea de horas se oculta con 0, igual que sin dato o
     sin bloques.
  d) Paleta (D7, Tarea 5). Dos filas de seis (Wrap) en un iPhone SE; en una pantalla más
     ancha, 7 y 5.
  e) Botón flotante (D7, Tarea 5). Abajo a la derecha. Lo demás del botón está en i).
  f) Cambiar la hora de un día (D7, Tarea 6) no muestra el aviso de cruce: la spec lo pide
     solo para el formulario. Si algún día se quiere también ahí, se arma con
     crucesDeBloque sobre ese día.
  Para mirar antes de publicar:
  g) Vista semanal (Tarea 4). Pinta los bloques propios de la semana del día activo. Las
     clases y las marcas de evaluación siguen saliendo como hoy, con la primera semana del
     ciclo.
  h) Línea de horas (Tarea 7). Sale en las dos vistas; en la semanal, en la franja de abajo
     (sus encabezados no llevan fecha). En la vista de día le quita unos 16 px de alto a la
     grilla, que sigue sin scroll: cada hora queda alrededor de 1 px más baja. Conviene
     mirarlo en un teléfono chico.
  i) Botón flotante (Tarea 5), lo que eligió la tarea y espera al dueño. Es el chico
     (FloatingActionButton.small) porque, en la vista de día, que no tiene scroll, el botón
     tapa la esquina derecha de la franja de 9 a 10 pm y se come los toques de esa esquina;
     el chico tapa menos. No aparece en horizontal ni en la lista de chats, porque en
     horizontal la grilla semanal ocupa toda la pantalla y el botón taparía una columna, y
     en la lista de chats no hay grilla. RF-BLQ-1 solo lo pide en la pantalla de horario y
     solo para alumnos. Si el dueño rechaza la exclusión en horizontal, se quita
     !enHorizontal de la condición y la prueba "en horizontal el botón no tapa la grilla
     semanal".
  j) Fallo de carga de los bloques (Tareas 1, 4 y 7). Si falla GET /time-blocks/me o
     GET /time-blocks/me/occurrences (red, plazo de 15 s o error del servidor), el horario
     se ve sin bloques propios y sin ningún indicador, aunque el service expone hasError e
     isLoading. Un aviso visible exigiría texto nuevo en la spec.

  5. CAMBIOS FUERA DE LOS ARCHIVOS DE LA FUNCIONALIDAD
  - lib/services/api_client.dart ganó patchJson (Tarea 1): aditivo, copiado de putJson. Es
    la única ruta PATCH de la app.
  - lib/services/auth_service.dart: logout() vacía también los bloques
    (TimeBlocksService.clear()), con la misma guarda que el récord de TT06 (Tarea 1).
  - Targets de la spec: antes de implementar, y con el sí del dueño (Paso 0 de la Tarea 1),
    se agregaron lib/pages/horario/horario_layout.dart, lib/services/api_client.dart y
    lib/services/auth_service.dart (AGENTS.md, pasos 7 y 8). No cambia ningún requisito.
  - specs/features/schedule/schedule.spec.md: la vista semanal pasa a decir "Monday to
    Sunday" y el toque de un bloque remite a RF-BLQ-5. Solo alinea el texto con lo que
    RF-BLQ-4 y RF-BLQ-5 ya aprobaron. Este archivo no estaba en el esqueleto del plan.
  - La spec quedó "aprobada" en el Paso 0 y pasa a "e implementada" en la Tarea 8, con la
    advertencia del punto 2, y el índice de funcionalidades suma la fila 18.
  - docs/specs/api-contracts.md documenta las siete rutas /time-blocks (Tarea 1), con lo
    que hace el backend: weeks trae una entrada por cada semana de la ventana, con el total
    de la semana entera y hours: 0 en las que no tienen ocurrencias (RS-BE-34), y las
    excepciones canceladas vuelven con startTime y endTime en null. Documenta también el
    isoDate que gana cada día de GET /schedule/me/sessions (D1).
  ```

- [ ] **Paso final: Commit**

  ```bash
  cd "${REPO:?}"
  test "$(git branch --show-current)" = feat/bloques-horario-fe || echo 'PARAR: rama equivocada'
  git status --short
  git add specs/features/time-blocks/time-blocks.spec.md \
          specs/features/schedule/schedule.spec.md \
          docs/specs/feature-index.md
  git commit -m "docs(time-blocks): enlazar las pruebas y cerrar la spec de los bloques propios

  La spec pasa a implementada, con lo que falta dicho: probada contra dobles,
  todavía no contra el backend desplegado. RF-BLQ-2, RF-BLQ-3 y RF-BLQ-7
  enlazan también las pruebas que los cubren desde otro archivo.

  El índice suma la fila de la funcionalidad, y la spec del horario deja de
  decir que la vista semanal llega al sábado y que todo bloque lleva al
  detalle de un curso."
  git log -1 --format=%B | grep -qi '^co-authored-by:' && echo 'PARAR: el commit trae trailer'
  bash /tmp/cierre-bloques/verificar_cierre.sh
  git status --short
  ```

  Antes del `git add`, `git status --short` solo puede listar esos tres archivos; si lista otro, o sale un `PARAR`, se detiene aquí. Sin trailer `Co-Authored-By`: el autor ya está configurado en git. Tras el commit, el script vuelve a dar `OK: …`, y ahora su comprobación 10 incluye este commit. `git status --short` no muestra nada (el script vive en `/tmp`). Nada de push, y el APK no se publica: ver el punto 2 del reporte.
