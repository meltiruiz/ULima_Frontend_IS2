# Plan de implementación de la recarga desde la ULima en la app

> **Para agentes.** SUB-SKILL REQUERIDA. Usa `superpowers:subagent-driven-development`
> (recomendado) o `superpowers:executing-plans` para ejecutar este plan tarea por tarea. Los pasos
> usan casillas (`- [ ]`) para llevar la cuenta.

**Objetivo.** Que el alumno traiga desde la ULima, con un solo inicio de sesión en miUlima, sus
notas parciales por evaluación y su asistencia, que las vea en `/mis-notas` y en la ficha del curso
con la hora de la última lectura, y que la calculadora de siempre, reorganizada según la maqueta
aprobada, cuente las notas que la ULima ya publica sin guardarlas nunca como simuladas.

**Arquitectura.** Un `GetxService` permanente, `RecargaUlimaService`, es la única frontera con
`GET /grades/me/ulima` y `POST /portal-sync/refresh`. Guarda la vista, el aviso rojo y los estados
por curso atados al alumno dueño y los expone por getters que filtran por ese dueño. Las reglas sin
widgets (formato del peso y de la nota, hora de la lectura, avisos de RF-RCG-4 y filas de la
calculadora) viven en `lib/domain/recarga_ulima/`, y las piezas de pantalla (hoja, franja, aviso,
fila «Notas oficiales» y pie del bloque de asistencia) en `lib/components/recarga_ulima/`. La
calculadora guarda las filas de la ULima en una lista aparte de `curso['notas']`, así que el
guardado de las simuladas no cambia y el doble de HU07 sigue sirviendo sin tocarlo.

**Stack.** Flutter 3.47.2 del proyecto, GetX 4 y `flutter_test`. Sin dependencias nuevas.

**Spec.** `specs/features/recarga-portal/recarga-portal.spec.md` (RF-RCG-1 a RF-RCG-11, B1 a B19
y D1 a D24), aprobada por el dueño el 2026-09-26 con todas las opciones recomendadas (commit
`a0e0415`). Su contraparte es RS-BE-48 a RS-BE-60 de
`ULima_Backend_IS2/specs/features/recarga-portal/recarga-portal.spec.md`. La maqueta aprobada queda
como referencia en `docs/images/UI/recarga/calculadora-reorganizada.html`, con su fuente en
`docs/images/UI/recarga/reorganizada.html` (commit `ef22203`). La spec es la fuente de los valores
exactos y manda si este plan difiere de ella. Sus referencias `archivo:línea` citan `19fed1b`, y
el código de `lib/` y `test/` de ese commit es el mismo de `ef22203`, que es la base de este plan.

**Validación del plan.** El código de este plan ya corre en un clon desechable de `ef22203`,
repetido tarea por tarea con un commit por tarea. En cada una, la prueba nueva falla antes de
implementar y pasa después, y `flutter analyze` no suma avisos. Al final la suite completa pasa
con 1385 pruebas, que son las 1223 de la base más las 162 nuevas de `test/HU37_jeff/`.

## Restricciones globales

- Solo se tocan los `targets` de la spec, que en este plan son
  `lib/services/recarga_ulima_service.dart`, `lib/models/recarga_ulima_models.dart`,
  `lib/domain/recarga_ulima/**`, `lib/components/recarga_ulima/**`,
  `lib/pages/calculadora/calculadora_page.dart`, `lib/pages/calculadora/calculadora_controller.dart`,
  `lib/components/calculadora/curso_card.dart`, `lib/components/calculadora/nota_tile.dart`,
  `lib/pages/mis_notas/mis_notas_page.dart`, `lib/pages/mis_notas/mis_notas_controller.dart`,
  `lib/pages/descripcion_cursos/descrip_cursos.dart`,
  `lib/pages/descripcion_cursos/descrip_cursos_controller.dart`, `lib/models/seccion_model.dart`,
  `lib/pages/portal_sync/portal_sync_controller.dart`,
  `lib/pages/password_reset/password_reset_ui.dart`, `lib/configs/themes.dart`,
  `lib/services/auth_service.dart`, `lib/main.dart` y `test/HU37_jeff/**`. La Tarea 11 toca
  además la spec, las cinco specs enmendadas, `docs/specs/api-contracts.md`,
  `docs/specs/feature-index.md`, `README.md`, `AGENTS.md` y `KNOWLEDGE.md`.
- Sin dependencias nuevas, sin cambios de backend ni de base de datos y sin llamadas al backend
  real. Las pruebas usan solo dobles escritos a mano (`ApiRecargaFalsa` y `AuthFalso` de
  `test/HU37_jeff/recarga_dobles.dart`), sin mockito ni mocktail.
- La contraseña y el código llegan como parámetros de `RecargaUlimaService.recargar` y se
  descartan al volver. Nunca entran en un `Rx`, en `shared_preferences`, en
  `flutter_secure_storage` ni en un `debugPrint`, y el cuerpo de la petición nunca se imprime
  (RF-RCG-1).
- El cuerpo de la recarga es exactamente
  `{"credentials": {"password": …, "passcode": …}, "consent": true}`, sin `cookies` ni código de
  alumno. El plazo de la recarga es de 90 s y el de `GET /grades/me/ulima` de 15 s.
- La app nunca muestra el `message` del backend. Cada error lleva el cuerpo y la acción de la
  tabla de RF-RCG-4, y el título es siempre «No se pudo actualizar».
- Los umbrales no cambian. «Desaprobado» sale por debajo de 11 en la calculadora y la insignia
  «Final» aprueba desde 10.5 en `/mis-notas` (decisión B9).
- Todo texto visible nuevo sale de «Textos nuevos» de la spec, y las pruebas fijan cada uno. Fuera
  de esa tabla no se inventa ningún texto.
- Repo público. Todo dato de prueba es inventado. La alumna es la `20230001`, el segundo alumno el
  `20230002` y el docente `docente.test`. Los cursos son TALLER DE PROTOTIPADO (sección `812`,
  `sectionId` 81), CURSO DE PRUEBA B (sección `813`, `sectionId` 82) y CURSO DE PRUEBA A (sección
  `801`, `idSeccion` `301`), la contraseña de prueba es `clave-de-prueba` y el código `482913`.
  Ningún valor sale del portal, de capturas ni de carpetas fuera del repo.
- Commits en español con el estilo del log, con `git add` y rutas explícitas, sin trailer
  Co-Authored-By ni otra línea de atribución y con el autor noreply de GitHub, que se comprueba
  con `git log -1 --format='%an <%ae>'`. Nada de push y nunca `git stash` a secas.
- La prosa de comentarios, specs y documentos va sin dos puntos, sin guiones largos, en presente y
  según la RAE.
- `FLUTTER` y `DART` son los ejecutables `flutter` y `dart` del SDK que indica el despacho, en la
  misma carpeta `bin`. Ninguna ruta de una máquina concreta entra en archivos del repo. Si falta
  `.dart_tool`, corre antes `"$FLUTTER" pub get`.
- Tiempo. Un comando que tarda más de unos 2 minutos sin devolver nada corta la sesión. En cada
  paso de prueba primero se corre solo el archivo de la tarea, que tarda segundos. La suite
  completa (unos 3 minutos) y `flutter analyze` sobre todo el proyecto corren en segundo plano
  (`run_in_background`), y la tarea espera su notificación antes de hacer commit.
- `dart format` corre solo sobre los archivos nuevos y sobre `nota_tile.dart`, `mis_notas_page.dart`
  y `mis_notas_controller.dart`, que el plan reescribe enteros. Los demás archivos modificados no
  pasan `dart format` desde antes de esta rama (`calculadora_page.dart`,
  `calculadora_controller.dart`, `descrip_cursos_controller.dart`, `seccion_model.dart`,
  `portal_sync_controller.dart`, `password_reset_ui.dart` y `auth_service.dart`), y formatearlos
  mete cientos de líneas ajenas en el diff. Sus cambios siguen el estilo que ya tienen.
- Línea base medida en `ef22203`. `"$FLUTTER" analyze --no-pub` da 6 avisos de nivel info, ninguno
  de error ni de advertencia, y `"$FLUTTER" test --no-pub` da 1223 pruebas en verde. Los 6 avisos
  son preexistentes y se reportan aparte. Cada tarea deja los mismos 6 avisos y la suite en verde
  con la cuenta que indica.
- Los parches de este plan van como bloques `diff` con su cabecera `diff --git`. Se aplican con
  `git apply` desde un archivo del scratchpad del agente, o a mano con Edit sobre las líneas `-` y
  `+`. Si `git apply` rechaza un parche porque el archivo ya no coincide, se aplica a mano y se revisa el
  resultado con `git diff`.

## Estructura de archivos

| Archivo | Acción | Responsabilidad |
|---|---|---|
| `lib/models/recarga_ulima_models.dart` | crear | `VistaUlima`, `CursoUlima`, `EvaluacionUlima`, `EstadoCursoRecarga` y `ResultadoRecarga`, con lectura tolerante |
| `lib/domain/recarga_ulima/formato_nota.dart` | crear | `formatoPeso`, `numeroDePeso`, `formatoNotaUlima` y `formatoNotaCalculadora` (D10) |
| `lib/domain/recarga_ulima/ultima_lectura.dart` | crear | `cuandoSeLeyo`, `textoUltimaLectura` y `textoNotasLeidas` en hora de Lima (RF-RCG-9) |
| `lib/domain/recarga_ulima/avisos_recarga.dart` | crear | `AvisoRecarga`, `AccionAviso`, `avisoDeError`, `avisoPlazo` y `avisoSinRed` (RF-RCG-4) |
| `lib/domain/recarga_ulima/filas_calculadora.dart` | crear | las filas visibles de la calculadora, su orden, su promedio y las claves de la lista de la ULima (RF-RCG-7) |
| `lib/services/recarga_ulima_service.dart` | crear | estado compartido, `cargar`, `recargar`, `clear`, dueño de los datos y D23 (RF-RCG-1, RF-RCG-3 y RF-RCG-4) |
| `lib/components/recarga_ulima/hoja_recarga_ulima.dart` | crear | la hoja de recarga y `abrirHojaRecargaUlima` (RF-RCG-2) |
| `lib/components/recarga_ulima/aviso_recarga.dart` | crear | el aviso en tarjeta y compacto, el botón de acción y `ejecutarAccionRecarga` (RF-RCG-4) |
| `lib/components/recarga_ulima/franja_recarga.dart` | crear | la franja «Actualizar desde la ULima» de `/mis-notas` (RF-RCG-6) |
| `lib/components/recarga_ulima/fila_notas_oficiales.dart` | crear | la fila «Notas oficiales» de la calculadora (RF-RCG-5) |
| `lib/components/recarga_ulima/pie_asistencia.dart` | crear | `PieAsistencia` y `RecargaSinDatos` del bloque de asistencia (RF-RCG-8) |
| `lib/configs/themes.dart` | modificar | los tokens `textoNaranja` e `insigniaUlimaTexto` (D11 y RF-RCG-10) |
| `lib/main.dart` | modificar | registro permanente de `RecargaUlimaService` |
| `lib/services/auth_service.dart` | modificar | `logout()` llama a `RecargaUlimaService.clear()` con la guarda `Get.isRegistered` |
| `lib/pages/password_reset/password_reset_ui.dart` | modificar | `boxHeight`, `boxFill`, `idleBorderColor` y `readOnly` en `PasswordResetOtpField` |
| `lib/pages/mis_notas/mis_notas_controller.dart` | reescribir | lee `RecargaUlimaService` y las siglas del sílabo (RF-RCG-6, B10 y D9) |
| `lib/pages/mis_notas/mis_notas_page.dart` | reescribir | la franja o el aviso primero, las evaluaciones de la ULima y los estados de RF-RCG-6 |
| `lib/components/calculadora/nota_tile.dart` | reescribir | peso `num`, nota `double?`, `np`, `deUlima` y la marca «ULima» (RF-RCG-7) |
| `lib/components/calculadora/curso_card.dart` | modificar | filas visibles de las dos listas, orden del sílabo y línea del sílabo que no coincide |
| `lib/pages/calculadora/calculadora_controller.dart` | modificar | `ApiClient` inyectable, filas de la ULima, promedio con las dos clases de filas y `recargarTodo` |
| `lib/pages/calculadora/calculadora_page.dart` | modificar | sin birrete, con la fila «Notas oficiales» y el conteo de filas visibles |
| `lib/models/seccion_model.dart` | modificar | `asistenciaLeidaEn` |
| `lib/pages/descripcion_cursos/descrip_cursos_controller.dart` | modificar | `SeccionService` inyectable y `recargarSeccion` |
| `lib/pages/descripcion_cursos/descrip_cursos.dart` | modificar | el pie del bloque con datos y las señales del estado sin datos |
| `lib/pages/portal_sync/portal_sync_controller.dart` | modificar | `recargarTodo()` en lugar de `Get.delete` (RF-RCG-11) |
| `test/HU37_jeff/recarga_dobles.dart` | crear | usuarios, `AuthFalso`, `ApiRecargaFalsa`, `errorApi` y el JSON inventado del contrato |
| `test/HU37_jeff/recarga_ulima_models_test.dart` | crear | RF-RCG-1, modelos (8 casos) |
| `test/HU37_jeff/formato_nota_test.dart` | crear | D10 (3 casos) |
| `test/HU37_jeff/ultima_lectura_test.dart` | crear | RF-RCG-9 (8 casos) |
| `test/HU37_jeff/contraste_recarga_test.dart` | crear | RF-RCG-10 (27 casos) |
| `test/HU37_jeff/recarga_ulima_service_test.dart` | crear | RF-RCG-1, RF-RCG-3, RF-RCG-4 y D23 (40 casos) |
| `test/HU37_jeff/hoja_recarga_test.dart` | crear | RF-RCG-2, RF-RCG-3 y la forma por defecto de `PasswordResetOtpField` (15 casos) |
| `test/HU37_jeff/mis_notas_ulima_test.dart` | crear | RF-RCG-3, RF-RCG-4 y RF-RCG-6 (17 casos) |
| `test/HU37_jeff/filas_calculadora_test.dart` | crear | RF-RCG-7, filas y guardado (10 casos) |
| `test/HU37_jeff/calculadora_ulima_test.dart` | crear | RF-RCG-5 y RF-RCG-7 (20 casos) |
| `test/HU37_jeff/asistencia_recarga_test.dart` | crear | RF-RCG-8 (12 casos) |
| `test/HU37_jeff/portal_sync_refresco_calculadora_test.dart` | crear | RF-RCG-11 (2 casos) |

## Orden y dependencias

Las tareas van en orden, en la rama `feat/recarga-notas-asistencia-fe`. La Tarea 1 deja los
modelos y los dobles que usan todas las demás. La 2 y la 3 no dependen de nada más. La 4 usa la 1,
la 5 usa la 3 y la 4, la 6 usa la 2, la 3, la 4 y la 5, la 7 usa la 1, la 8 usa la 2, la 3, la 4,
la 6 y la 7, la 9 usa la 2, la 3, la 4, la 5 y la 6, y la 10 usa la 8. La Tarea 11 cierra la spec
cuando las diez anteriores están en verde.

## Notas del código real que el plan tiene en cuenta

- El doble de HU07 (`test/HU07_sam/calculadora_flujo_cajanegra_test.dart:30-93`) reemplaza
  `onInit` sin llamar a `super`, arma sus cursos sin la lista de la ULima y sobrescribe
  `eliminarNota(int, int)`. Por eso los `Rx` nuevos del controller se inicializan en su
  declaración, la conexión con la ULima vive en `conectarUlima()`, que solo llama el `onInit`
  real, y `CursoCard` trata la falta de `curso['notasUlima']` como una lista vacía.
- HU06 construye `CalculadoraController()` directo, sin `Get.put`
  (`test/HU06_sam/calculadora_evaluaciones_unitaria_test.dart:25-48`), así que el constructor nuevo
  no puede hacer red y su parámetro es opcional.
- `Get.put` conserva una instancia ya registrada. Las pruebas registran antes sus dobles de
  `CalculadoraController` y de `DescripCursosController`, que la página crea con `Get.lazyPut` y
  `Get.put` (`calculadora_page.dart:15` y `descrip_cursos.dart:29`).
- `ApiClient` no impone plazo (`api_client.dart:125-160`), así que el servicio usa `.timeout`. Un
  `Future.timeout` deja un `Timer` pendiente hasta que el futuro termina, y una prueba de widget
  que deja un `Completer` sin completar falla con «A Timer is still pending». Las pruebas completan
  sus `Completer` antes de terminar.
- `pumpAndSettle` no termina con un campo enfocado, por el cursor, ni con un
  `CircularProgressIndicator` en pantalla. Las pruebas de la hoja avanzan el reloj con `pump`.
- `find.text` no ve el `RichText` de la línea `Peso: …  •  Nota: …` de `NotaTile`. Las pruebas
  usan `find.textContaining(…, findRichText: true)`.
- En este Flutter, `containsSemantics` está obsoleto y `flutter analyze` lo marca. Las pruebas
  usan `isSemantics`, que solo compara lo que recibe.
- La etiqueta del campo de contraseña se une con su pista en un solo nodo
  (`Contraseña de miUlima` y `Tu contraseña del portal`), así que la prueba mira que la etiqueta
  empiece con el rótulo.
- La primera asignación de un `Rx` avisa a su `ever` aunque el valor no cambie, así que la prueba
  de `alCambiarVista` mira el orden de los avisos y no su número.
- Un `Container` suma el ancho de su borde al relleno del hijo. Por eso el borde en reposo de
  `PasswordResetOtpField` conserva el ancho de 2 cuando es transparente, y `/portal-sync`,
  `/registro` y el cambio de contraseña no se mueven ni un píxel.
- `EvaluationSyllabusService.loadEvaluationData` se traga sus errores y vacía su caché
  (`evaluations_service.dart:32-66`), así que `isLoaded` en falso es la señal de un sílabo que no
  carga, y entonces las filas de `/mis-notas` van sin sigla (D9).
- Los hijos de un `ListView.builder` se construyen fuera del seguimiento de su `Obx`. `/mis-notas`
  arma sus tarjetas dentro del `Obx`, para que la sigla, el aviso y la línea de lectura parcial se
  repinten solas.
- `contrasteWcag` y `enHoraDeLima` de `chat_linea_tiempo.dart` son públicas y se reutilizan. La
  lista `_meses` de ese archivo es privada, y `ultima_lectura.dart` repite los doce nombres.
- `DescripCursosController` crea hoy `SeccionService()` en un inicializador de campo
  (`descrip_cursos_controller.dart:16`). La Tarea 9 lo pasa al constructor, opcional, como ya está
  `asesoriaService`.
- El resumen de `/portal-sync` vuelve con `Get.back<bool>(result: true)`
  (`portal_sync_page.dart:250`), que es lo que espera «Cargar mis datos».

---

### Tarea 1. Modelos de la ULima y dobles de prueba

**Requisitos.** RF-RCG-1, «Modelos», con la lectura tolerante y el mapeo de `courses` a
`vista.cursos` y de `assessments` a `evaluaciones`, y el archivo `recarga_ulima_models_test.dart`
de «Pruebas previstas».

**Archivos.**
- Crear `test/HU37_jeff/recarga_dobles.dart`.
- Crear `test/HU37_jeff/recarga_ulima_models_test.dart`.
- Crear `lib/models/recarga_ulima_models.dart`.

**Interfaces.**
- Consume nada.
- Produce, en `package:ulima_plus/models/recarga_ulima_models.dart`, estas firmas.

```dart
enum MarcaUlima { graded, pending, np }
enum ParejaUlima { exact, exactOtherName, weekShift, none }

class EvaluacionUlima {
  final String key; final String? group; final String name; final int? week;
  final double weight; final double? value; final MarcaUlima mark;
  final int? assessmentId; final ParejaUlima match;
  bool get tienePareja; // match != none
  bool get publicada;   // mark != pending
  factory EvaluacionUlima.fromJson(Map<String, dynamic> json);
}
class CursoUlima {
  final int sectionId; final String courseCode, courseName, sectionCode;
  final DateTime? lastReadAt; final List<EvaluacionUlima> evaluaciones;
  factory CursoUlima.fromJson(Map<String, dynamic> json);
}
class VistaUlima {
  final DateTime? lastReadAt; final List<CursoUlima> cursos;
  factory VistaUlima.fromJson(Object? json);
}
class EstadoCursoRecarga {
  final int sectionId; final String attendance; final String grades;
  factory EstadoCursoRecarga.fromJson(Map<String, dynamic> json);
}
class ResultadoRecarga {
  final DateTime? readAt; final List<EstadoCursoRecarga> estados; final VistaUlima view;
  factory ResultadoRecarga.fromJson(Map<String, dynamic> json);
}
```

- Produce, en `test/HU37_jeff/recarga_dobles.dart`, `alumna({String code = '20230001'})`,
  `docente()`, `AuthFalso`, `loguear(UserModel?)`, `ApiRecargaFalsa({bool calcularPromedio})` con
  `responder(String, Object)`, `veces(String)`, `cuerposDe(String)` y `llamadas`,
  `errorApi(int, String, {Object? details})`, `evaluacionJson`, `cursoJson`, `vistaJson`,
  `resultadoJson` y la constante `lecturaDePrueba`. Las claves de `ApiRecargaFalsa` son el método
  y la ruta sin la query, como `GET /grades/me/ulima`.

- [ ] **Paso 1. Línea base.** En la raíz del worktree corre en segundo plano
  `"$FLUTTER" analyze --no-pub` y `"$FLUTTER" test --no-pub`, espera sus notificaciones y anota
  en el informe el número de avisos y de pruebas. En `ef22203` son 6 avisos de nivel info y 1223
  pruebas en verde.

- [ ] **Paso 2. Los dobles compartidos.** Crea `test/HU37_jeff/recarga_dobles.dart` con este
  contenido. Las tareas siguientes lo usan sin cambiarlo.

```dart
// test/HU37_jeff/recarga_dobles.dart
//
// Dobles y datos de prueba compartidos por las pruebas de la recarga desde la
// ULima (specs/features/recarga-portal/recarga-portal.spec.md). Todo es
// inventado, porque el repo es público. La alumna es la 20230001, el segundo
// alumno es el 20230002 y los cursos salen del ejemplo del contrato.

import 'dart:async';

import 'package:get/get.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/auth_service.dart';

UserModel alumna({String code = '20230001'}) => UserModel(
  code: code,
  firstName: 'Alumna',
  lastName: 'De Prueba',
  email: 'test@aloe.ulima.edu.pe',
  role: 'student',
  currentCycle: '2026-2',
  setupComplete: true,
);

/// Un docente, que nunca usa la recarga.
UserModel docente() => UserModel(
  code: 'docente.test',
  firstName: 'Docente',
  lastName: 'De Prueba',
  email: 'docente.test@ulima.edu.pe',
  role: 'teacher',
  currentCycle: '2026-2',
  setupComplete: true,
);

class AuthFalso extends AuthService {
  AuthFalso(UserModel? user) : userRx = Rx<UserModel?>(user);

  final Rx<UserModel?> userRx;

  @override
  UserModel? get currentUser => userRx.value;

  @override
  Rx<UserModel?> get currentUserRx => userRx;

  @override
  Future<void> refreshCurrentUser() async {}
}

/// Registra a [user] como el usuario actual.
AuthFalso loguear(UserModel? user) {
  final auth = AuthFalso(user);
  Get.put<AuthService>(auth);
  return auth;
}

/// `ApiClient` falso con respuestas por método y ruta, sin la query.
///
/// Cada clave es, por ejemplo, `GET /grades/me/ulima`. Las respuestas salen
/// en orden y la última se repite. Un `Map` se devuelve, un `Completer` se
/// espera y cualquier otra cosa se lanza. Una ruta sin respuestas devuelve
/// un mapa vacío. Con [calcularPromedio], `POST /grades/me/calculate` suma
/// valor · peso / 100 como el backend.
class ApiRecargaFalsa extends ApiClient {
  ApiRecargaFalsa({this.calcularPromedio = false})
    : super(configuredBaseUrl: 'http://test');

  final bool calcularPromedio;
  final Map<String, List<Object>> _respuestas = <String, List<Object>>{};
  final Map<String, int> _usadas = <String, int>{};

  /// Cada llamada, como `POST /portal-sync/refresh`, en orden.
  final List<String> llamadas = <String>[];

  /// El cuerpo de cada POST, en orden, junto a su ruta.
  final List<(String, Map<String, dynamic>)> cuerpos =
      <(String, Map<String, dynamic>)>[];

  void responder(String clave, Object respuesta) =>
      _respuestas.putIfAbsent(clave, () => <Object>[]).add(respuesta);

  int veces(String clave) => llamadas.where((l) => l == clave).length;

  List<Map<String, dynamic>> cuerposDe(String ruta) =>
      cuerpos.where((c) => c.$1 == ruta).map((c) => c.$2).toList();

  Future<Map<String, dynamic>> _salida(String clave) async {
    llamadas.add(clave);
    final lista = _respuestas[clave];
    if (lista == null || lista.isEmpty) return <String, dynamic>{};
    final i = _usadas[clave] ?? 0;
    _usadas[clave] = i + 1;
    final r = lista[i < lista.length ? i : lista.length - 1];
    if (r is Completer<Map<String, dynamic>>) return r.future;
    if (r is Map<String, dynamic>) return r;
    throw r;
  }

  static String _ruta(String path) => path.split('?').first;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    String? token,
    Map<String, String?> query = const {},
    bool suppressSessionExpiry = false,
  }) => _salida('GET ${_ruta(path)}');

  @override
  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) {
    final ruta = _ruta(path);
    cuerpos.add((ruta, body));
    if (calcularPromedio && ruta == '/grades/me/calculate') {
      llamadas.add('POST $ruta');
      var promedio = 0.0;
      var suma = 0.0;
      for (final n in (body['notas'] as List).cast<Map>()) {
        final peso = (n['peso'] as num).toDouble();
        promedio += (n['valor'] as num).toDouble() * peso / 100;
        suma += peso;
      }
      return Future.value(<String, dynamic>{
        'promedio': promedio,
        'sumaPesos': suma,
      });
    }
    return _salida('POST $ruta');
  }

  @override
  Future<Map<String, dynamic>> deleteJson(String path, {String? token}) =>
      _salida('DELETE ${_ruta(path)}');
}

ApiException errorApi(int status, String code, {Object? details}) =>
    ApiException(
      statusCode: status,
      code: code,
      message: 'mensaje del backend que la app nunca muestra',
      details: details,
    );

// --- JSON inventado con la forma del contrato ------------------------------

Map<String, dynamic> evaluacionJson({
  String key = '07.13',
  String? group = 'EVC',
  String name = 'Examen escrito 1',
  Object? week = 3,
  Object weight = 15,
  Object? value = 14.5,
  String mark = 'graded',
  Object? assessmentId = 5011,
  String match = 'exact',
}) => <String, dynamic>{
  'key': key,
  'group': group,
  'name': name,
  'week': week,
  'weight': weight,
  'value': value,
  'mark': mark,
  'assessmentId': assessmentId,
  'match': match,
};

Map<String, dynamic> cursoJson({
  Object sectionId = 81,
  String courseCode = '690417',
  String courseName = 'TALLER DE PROTOTIPADO',
  String sectionCode = '812',
  Object? lastReadAt = '2025-09-22T15:42:10.000Z',
  List<Map<String, dynamic>>? assessments,
}) => <String, dynamic>{
  'sectionId': sectionId,
  'courseCode': courseCode,
  'courseName': courseName,
  'sectionCode': sectionCode,
  'lastReadAt': lastReadAt,
  'assessments':
      assessments ??
      <Map<String, dynamic>>[
        evaluacionJson(),
        evaluacionJson(
          key: '07.15',
          name: 'Exposición',
          week: 10,
          weight: 20,
          value: null,
          mark: 'pending',
          assessmentId: 5013,
          match: 'week_shift',
        ),
      ],
};

/// La vista del ejemplo del contrato. La hora de lectura por omisión es del
/// 22 de septiembre de 2025 a las 10:42 de Lima, que da un texto fijo sea
/// cual sea el día en que corre la prueba.
Map<String, dynamic> vistaJson({
  Object? lastReadAt = '2025-09-22T15:42:10.000Z',
  List<Map<String, dynamic>>? courses,
}) => <String, dynamic>{
  'lastReadAt': lastReadAt,
  'courses': courses ?? <Map<String, dynamic>>[cursoJson()],
};

Map<String, dynamic> resultadoJson({
  Map<String, dynamic>? view,
  List<Map<String, dynamic>>? courses,
}) => <String, dynamic>{
  'readAt': '2025-09-22T15:42:10.000Z',
  'attendance': {'updated': 1, 'skipped': 0, 'failed': 0, 'unavailable': 0},
  'grades': {'read': 1, 'failed': 0, 'unavailable': 0, 'withValue': 1},
  'courses':
      courses ??
      <Map<String, dynamic>>[
        {
          'sectionId': 81,
          'courseCode': '690417',
          'sectionCode': '812',
          'attendance': 'updated',
          'grades': 'read',
        },
      ],
  'view': view ?? vistaJson(),
  'warnings': <dynamic>[],
};

/// El texto de la hora de lectura por omisión de [vistaJson].
const String lecturaDePrueba = 'el 22 de septiembre de 2025 a las 10:42';
```

- [ ] **Paso 3. Escribe la prueba que falla.** Crea
  `test/HU37_jeff/recarga_ulima_models_test.dart` con este contenido.

```dart
// test/HU37_jeff/recarga_ulima_models_test.dart
//
// UNITARIA · Recarga desde la ULima (specs/features/recarga-portal/
// recarga-portal.spec.md), RF-RCG-1, modelos.
// Archivo probado lib/models/recarga_ulima_models.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/models/recarga_ulima_models.dart';

import 'recarga_dobles.dart';

void main() {
  group('UNITARIA · VistaUlima (RF-RCG-1)', () {
    test('lee entera la vista del ejemplo del contrato, con courses en '
        'vista.cursos y assessments en evaluaciones', () {
      final vista = VistaUlima.fromJson(vistaJson());

      expect(vista.lastReadAt, DateTime.utc(2025, 9, 22, 15, 42, 10));
      expect(vista.cursos, hasLength(1));
      final curso = vista.cursos.single;
      expect(curso.sectionId, 81);
      expect(curso.courseCode, '690417');
      expect(curso.courseName, 'TALLER DE PROTOTIPADO');
      expect(curso.sectionCode, '812');
      expect(curso.lastReadAt, DateTime.utc(2025, 9, 22, 15, 42, 10));
      expect(curso.evaluaciones, hasLength(2));

      final primera = curso.evaluaciones.first;
      expect(primera.key, '07.13');
      expect(primera.group, 'EVC');
      expect(primera.name, 'Examen escrito 1');
      expect(primera.week, 3);
      expect(primera.weight, 15);
      expect(primera.value, 14.5);
      expect(primera.mark, MarcaUlima.graded);
      expect(primera.assessmentId, 5011);
      expect(primera.match, ParejaUlima.exact);
      expect(primera.tienePareja, isTrue);
      expect(primera.publicada, isTrue);

      final segunda = curso.evaluaciones.last;
      expect(segunda.value, isNull);
      expect(segunda.mark, MarcaUlima.pending);
      expect(segunda.match, ParejaUlima.weekShift);
      expect(segunda.publicada, isFalse);
    });

    test('un número que llega como texto se convierte', () {
      final vista = VistaUlima.fromJson(
        vistaJson(
          courses: [
            cursoJson(
              sectionId: '81',
              assessments: [
                evaluacionJson(
                  week: '3',
                  weight: '12.5',
                  value: '14.25',
                  assessmentId: '5011',
                ),
              ],
            ),
          ],
        ),
      );

      final e = vista.cursos.single.evaluaciones.single;
      expect(vista.cursos.single.sectionId, 81);
      expect(e.week, 3);
      expect(e.weight, 12.5);
      expect(e.value, 14.25);
      expect(e.assessmentId, 5011);
    });

    test('un mark o un match desconocidos se tratan como pending y none', () {
      final vista = VistaUlima.fromJson(
        vistaJson(
          courses: [
            cursoJson(
              assessments: [
                evaluacionJson(mark: 'otra_cosa', match: 'parecida'),
              ],
            ),
          ],
        ),
      );

      final e = vista.cursos.single.evaluaciones.single;
      expect(e.mark, MarcaUlima.pending);
      expect(e.value, isNull);
      expect(e.match, ParejaUlima.none);
      expect(e.tienePareja, isFalse);
    });

    test('np, exact_other_name y una evaluación sin semana', () {
      final vista = VistaUlima.fromJson(
        vistaJson(
          courses: [
            cursoJson(
              assessments: [
                evaluacionJson(
                  mark: 'np',
                  value: null,
                  match: 'exact_other_name',
                  week: null,
                ),
              ],
            ),
          ],
        ),
      );

      final e = vista.cursos.single.evaluaciones.single;
      expect(e.mark, MarcaUlima.np);
      expect(e.value, isNull);
      expect(e.publicada, isTrue);
      expect(e.match, ParejaUlima.exactOtherName);
      expect(e.week, isNull);
    });

    test('un graded sin valor se lee como pending y un match sin '
        'assessmentId como none', () {
      final vista = VistaUlima.fromJson(
        vistaJson(
          courses: [
            cursoJson(
              assessments: [
                evaluacionJson(value: null),
                evaluacionJson(assessmentId: null, match: 'exact'),
              ],
            ),
          ],
        ),
      );

      final evaluaciones = vista.cursos.single.evaluaciones;
      expect(evaluaciones.first.mark, MarcaUlima.pending);
      expect(evaluaciones.last.match, ParejaUlima.none);
    });

    test('una fecha ilegible queda null', () {
      final vista = VistaUlima.fromJson(
        vistaJson(
          lastReadAt: 'ayer por la tarde',
          courses: [cursoJson(lastReadAt: 42)],
        ),
      );

      expect(vista.lastReadAt, isNull);
      expect(vista.cursos.single.lastReadAt, isNull);
    });

    test('sin período activo la vista llega vacía, y un cuerpo que no es un '
        'mapa también', () {
      final vacia = VistaUlima.fromJson(<String, dynamic>{
        'lastReadAt': null,
        'courses': <dynamic>[],
      });
      expect(vacia.lastReadAt, isNull);
      expect(vacia.cursos, isEmpty);

      expect(VistaUlima.fromJson(null).cursos, isEmpty);
    });
  });

  group('UNITARIA · ResultadoRecarga (RF-RCG-1)', () {
    test('el resultado de la recarga trae sus estados por curso y su view', () {
      final r = ResultadoRecarga.fromJson(
        resultadoJson(
          courses: [
            {
              'sectionId': 81,
              'courseCode': '690417',
              'sectionCode': '812',
              'attendance': 'updated',
              'grades': 'read',
            },
            {
              'sectionId': '82',
              'courseCode': '690418',
              'sectionCode': '813',
              'attendance': 'missing',
              'grades': 'failed',
            },
          ],
        ),
      );

      expect(r.readAt, DateTime.utc(2025, 9, 22, 15, 42, 10));
      expect(r.estados, hasLength(2));
      expect(r.estados.first.sectionId, 81);
      expect(r.estados.first.attendance, 'updated');
      expect(r.estados.first.grades, 'read');
      expect(r.estados.last.sectionId, 82);
      expect(r.estados.last.attendance, 'missing');
      expect(r.estados.last.grades, 'failed');
      expect(r.view.cursos.single.courseName, 'TALLER DE PROTOTIPADO');
    });
  });
}
```

- [ ] **Paso 4. Comprueba que falla.**

```bash
"$FLUTTER" test --no-pub test/HU37_jeff/recarga_ulima_models_test.dart
```

**Esperado.** Falla al compilar porque no existe
`package:ulima_plus/models/recarga_ulima_models.dart`.

- [ ] **Paso 5. Implementa los modelos.** Crea `lib/models/recarga_ulima_models.dart` con este
  contenido. Un `graded` sin valor se lee como `pending` y una pareja sin `assessmentId` como
  `none`, porque ninguno de los dos se puede pintar ni emparejar.

```dart
// lib/models/recarga_ulima_models.dart
//
// Modelos de la recarga desde la ULima (RF-RCG-1). Leen `GET /grades/me/ulima`
// y la respuesta de `POST /portal-sync/refresh`. La lectura es tolerante. Un
// número que llega como texto se convierte, una fecha ilegible queda `null`,
// un `mark` desconocido se trata como `pending` y un `match` desconocido como
// `none`.

/// Estado de una evaluación en el panel Nota del Aula Virtual.
enum MarcaUlima { graded, pending, np }

/// Cómo empareja el backend una evaluación de la ULima con el sílabo.
enum ParejaUlima { exact, exactOtherName, weekShift, none }

double? _decimal(Object? v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.trim());
  return null;
}

int? _entero(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim());
  return null;
}

DateTime? _fecha(Object? v) => v is String ? DateTime.tryParse(v) : null;

String _texto(Object? v) => v == null ? '' : v.toString();

List<Object?> _lista(Object? v) => v is List ? v : const <Object?>[];

Map<String, dynamic> _mapa(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : const <String, dynamic>{};

MarcaUlima _marca(Object? v) {
  switch (v) {
    case 'graded':
      return MarcaUlima.graded;
    case 'np':
      return MarcaUlima.np;
    default:
      return MarcaUlima.pending;
  }
}

ParejaUlima _pareja(Object? v) {
  switch (v) {
    case 'exact':
      return ParejaUlima.exact;
    case 'exact_other_name':
      return ParejaUlima.exactOtherName;
    case 'week_shift':
      return ParejaUlima.weekShift;
    default:
      return ParejaUlima.none;
  }
}

/// Una evaluación de un curso, tal como la publica la ULima.
class EvaluacionUlima {
  const EvaluacionUlima({
    required this.key,
    required this.group,
    required this.name,
    required this.week,
    required this.weight,
    required this.value,
    required this.mark,
    required this.assessmentId,
    required this.match,
  });

  final String key;
  final String? group;
  final String name;
  final int? week;
  final double weight;
  final double? value;
  final MarcaUlima mark;
  final int? assessmentId;
  final ParejaUlima match;

  /// Tiene pareja en el sílabo (RF-RCG-7, decisión B7).
  bool get tienePareja => match != ParejaUlima.none;

  /// La ULima ya publica algo, una nota o un NP.
  bool get publicada => mark != MarcaUlima.pending;

  factory EvaluacionUlima.fromJson(Map<String, dynamic> json) {
    final value = _decimal(json['value']);
    var mark = _marca(json['mark']);
    // Una nota «graded» sin valor no se puede pintar ni promediar, así que se
    // lee como pendiente.
    if (mark == MarcaUlima.graded && value == null) mark = MarcaUlima.pending;
    final assessmentId = _entero(json['assessmentId']);
    var match = _pareja(json['match']);
    // Sin `assessmentId` no hay con qué emparejar en el sílabo.
    if (assessmentId == null) match = ParejaUlima.none;
    final group = json['group'];
    return EvaluacionUlima(
      key: _texto(json['key']),
      group: group?.toString(),
      name: _texto(json['name']),
      week: _entero(json['week']),
      weight: _decimal(json['weight']) ?? 0,
      value: mark == MarcaUlima.graded ? value : null,
      mark: mark,
      assessmentId: assessmentId,
      match: match,
    );
  }
}

/// Un curso del alumno en el período activo, con sus evaluaciones.
class CursoUlima {
  const CursoUlima({
    required this.sectionId,
    required this.courseCode,
    required this.courseName,
    required this.sectionCode,
    required this.lastReadAt,
    required this.evaluaciones,
  });

  final int sectionId;
  final String courseCode;
  final String courseName;
  final String sectionCode;
  final DateTime? lastReadAt;

  /// Sale de `assessments` del JSON, en el orden en que llega.
  final List<EvaluacionUlima> evaluaciones;

  factory CursoUlima.fromJson(Map<String, dynamic> json) => CursoUlima(
    sectionId: _entero(json['sectionId']) ?? 0,
    courseCode: _texto(json['courseCode']),
    courseName: _texto(json['courseName']),
    sectionCode: _texto(json['sectionCode']),
    lastReadAt: _fecha(json['lastReadAt']),
    evaluaciones: _lista(
      json['assessments'],
    ).whereType<Map>().map((e) => EvaluacionUlima.fromJson(_mapa(e))).toList(),
  );
}

/// Lo que devuelve `GET /grades/me/ulima`.
class VistaUlima {
  const VistaUlima({required this.lastReadAt, required this.cursos});

  final DateTime? lastReadAt;

  /// Sale de `courses` del JSON, en el orden en que llega.
  final List<CursoUlima> cursos;

  factory VistaUlima.fromJson(Object? json) {
    final mapa = _mapa(json);
    return VistaUlima(
      lastReadAt: _fecha(mapa['lastReadAt']),
      cursos: _lista(
        mapa['courses'],
      ).whereType<Map>().map((c) => CursoUlima.fromJson(_mapa(c))).toList(),
    );
  }
}

/// Estado de un curso en una recarga, por panel.
class EstadoCursoRecarga {
  const EstadoCursoRecarga({
    required this.sectionId,
    required this.attendance,
    required this.grades,
  });

  final int sectionId;

  /// `updated`, `skipped`, `failed`, `unavailable`, `missing` o `not_reached`.
  final String attendance;

  /// `read`, `failed`, `unavailable`, `missing` o `not_reached`.
  final String grades;

  factory EstadoCursoRecarga.fromJson(Map<String, dynamic> json) =>
      EstadoCursoRecarga(
        sectionId: _entero(json['sectionId']) ?? 0,
        attendance: _texto(json['attendance']),
        grades: _texto(json['grades']),
      );
}

/// Lo que devuelve `POST /portal-sync/refresh` con `200`.
class ResultadoRecarga {
  const ResultadoRecarga({
    required this.readAt,
    required this.estados,
    required this.view,
  });

  final DateTime? readAt;
  final List<EstadoCursoRecarga> estados;
  final VistaUlima view;

  factory ResultadoRecarga.fromJson(Map<String, dynamic> json) =>
      ResultadoRecarga(
        readAt: _fecha(json['readAt']),
        estados: _lista(json['courses'])
            .whereType<Map>()
            .map((c) => EstadoCursoRecarga.fromJson(_mapa(c)))
            .toList(),
        view: VistaUlima.fromJson(json['view']),
      );
}
```

- [ ] **Paso 6. Comprueba que pasa.**

```bash
"$DART" format lib/models/recarga_ulima_models.dart test/HU37_jeff
"$FLUTTER" test --no-pub test/HU37_jeff/recarga_ulima_models_test.dart
"$FLUTTER" analyze --no-pub lib/models/recarga_ulima_models.dart test/HU37_jeff
```

**Esperado.** El formato no cambia nada, pasan las 8 pruebas y el análisis no encuentra avisos.

- [ ] **Paso 7. Commit.**

```bash
git add lib/models/recarga_ulima_models.dart test/HU37_jeff/recarga_dobles.dart test/HU37_jeff/recarga_ulima_models_test.dart
git commit -m "feat(recarga-portal): modelos de la vista de la ULima y del resultado de la recarga, con lectura tolerante (RF-RCG-1)"
git log -1 --format='%an <%ae>'
```

---

### Tarea 2. Formato del peso y de la nota, y hora de la última lectura

**Requisitos.** D10 (peso con hasta dos decimales, nota de `/mis-notas` con uno o dos y nota de la
calculadora siempre con uno) y RF-RCG-9 completo, con `enHoraDeLima` de `chat_linea_tiempo.dart`.

**Archivos.**
- Crear `test/HU37_jeff/formato_nota_test.dart`.
- Crear `test/HU37_jeff/ultima_lectura_test.dart`.
- Crear `lib/domain/recarga_ulima/formato_nota.dart`.
- Crear `lib/domain/recarga_ulima/ultima_lectura.dart`.

**Interfaces.**
- Consume `enHoraDeLima(DateTime)` de `package:ulima_plus/pages/chat/chat_linea_tiempo.dart`.
- Produce estas firmas.

```dart
// package:ulima_plus/domain/recarga_ulima/formato_nota.dart
String numeroDePeso(num peso);            // '20', '12.5', '12.25'
String formatoPeso(num peso);             // '20%', '12.5%'
String formatoNotaUlima(double nota);     // '15.0', '14.5', '14.25'
String formatoNotaCalculadora(double nota); // siempre un decimal, '14.3'

// package:ulima_plus/domain/recarga_ulima/ultima_lectura.dart
String cuandoSeLeyo(DateTime leidoEn, DateTime ahora); // 'hoy a las 10:42'
String textoUltimaLectura(DateTime leidoEn, DateTime ahora); // 'Última lectura …'
String textoNotasLeidas(DateTime leidoEn, DateTime ahora);   // 'Se muestran las notas leídas ….'
```

- [ ] **Paso 1. Escribe las pruebas que fallan.** Crea `test/HU37_jeff/formato_nota_test.dart`
  con este contenido.

```dart
// test/HU37_jeff/formato_nota_test.dart
//
// UNITARIA · Recarga desde la ULima (specs/features/recarga-portal/
// recarga-portal.spec.md), D10, formato del peso y de la nota.
// Archivo probado lib/domain/recarga_ulima/formato_nota.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/domain/recarga_ulima/formato_nota.dart';

void main() {
  group('UNITARIA · formato del peso (D10)', () {
    test('entero sin decimales y con hasta dos si los tiene', () {
      expect(formatoPeso(20), '20%');
      expect(formatoPeso(20.0), '20%');
      expect(formatoPeso(12.5), '12.5%');
      expect(formatoPeso(12.25), '12.25%');
      expect(formatoPeso(12.10), '12.1%');
      expect(numeroDePeso(12.5), '12.5');
    });
  });

  group('UNITARIA · formato de la nota (D10)', () {
    test('en /mis-notas, un decimal si tiene uno o ninguno y dos si los '
        'tiene', () {
      expect(formatoNotaUlima(15), '15.0');
      expect(formatoNotaUlima(14.5), '14.5');
      expect(formatoNotaUlima(14.3), '14.3');
      expect(formatoNotaUlima(14.25), '14.25');
    });

    test(
      'en la calculadora, siempre un decimal en las dos clases de filas',
      () {
        expect(formatoNotaCalculadora(14.25), '14.3');
        expect(formatoNotaCalculadora(15), '15.0');
      },
    );
  });
}
```

Crea `test/HU37_jeff/ultima_lectura_test.dart` con este contenido.

```dart
// test/HU37_jeff/ultima_lectura_test.dart
//
// UNITARIA · Recarga desde la ULima (specs/features/recarga-portal/
// recarga-portal.spec.md), RF-RCG-9, la hora de la última lectura.
// Archivo probado lib/domain/recarga_ulima/ultima_lectura.dart.
//
// Las fechas van en UTC, y Lima está 5 horas atrás todo el año, así que las
// 15:42 UTC son las 10:42 de Lima.
//
// Dart no cambia la zona horaria dentro del proceso, así que el caso del
// teléfono en otra zona depende de la zona de la máquina que corre la prueba.
// La suite corre solo en una máquina local, porque
// `.github/workflows/build-apk.yml` no corre `flutter test`. En una máquina en
// UTC−5, `toLocal()` deja las dos fechas en la hora de Lima, y ese caso no
// distingue una hora calculada en la zona del teléfono. Con `TZ=UTC`, este
// archivo falla si `cuandoSeLeyo` usa `toLocal()` en lugar de `enHoraDeLima`,
// así que la verificación lo corre también con
// `TZ=UTC flutter test --no-pub test/HU37_jeff/ultima_lectura_test.dart`.

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/domain/recarga_ulima/ultima_lectura.dart';

void main() {
  group('UNITARIA · cuandoSeLeyo (RF-RCG-9)', () {
    final ahora = DateTime.utc(
      2026,
      9,
      25,
      20,
    ); // 25 de septiembre, 15:00 de Lima

    test('el mismo día de Lima da «hoy a las HH:mm»', () {
      expect(
        cuandoSeLeyo(DateTime.utc(2026, 9, 25, 15, 42), ahora),
        'hoy a las 10:42',
      );
    });

    test('el día anterior da «ayer a las HH:mm», con ceros a la izquierda', () {
      expect(
        cuandoSeLeyo(DateTime.utc(2026, 9, 24, 14, 5), ahora),
        'ayer a las 09:05',
      );
    });

    test('otro día del mismo año da el día y el mes en minúscula', () {
      expect(
        cuandoSeLeyo(DateTime.utc(2026, 9, 22, 15, 42), ahora),
        'el 22 de septiembre a las 10:42',
      );
    });

    test('otro año suma « de 2025» después del mes', () {
      expect(
        cuandoSeLeyo(DateTime.utc(2025, 9, 22, 15, 42), ahora),
        'el 22 de septiembre de 2025 a las 10:42',
      );
    });

    test('las 23:59 y las 00:00 de Lima caen en días distintos aunque el '
        'teléfono esté en otra zona', () {
      // 04:59 UTC del 26 son las 23:59 del 25 en Lima.
      final ultimoMinuto = DateTime.utc(2026, 9, 26, 4, 59);
      // 05:00 UTC del 26 son las 00:00 del 26 en Lima.
      final medianoche = DateTime.utc(2026, 9, 26, 5);
      final ahoraDia26 = DateTime.utc(2026, 9, 26, 12);

      expect(cuandoSeLeyo(ultimoMinuto, ahoraDia26), 'ayer a las 23:59');
      expect(cuandoSeLeyo(medianoche, ahoraDia26), 'hoy a las 00:00');
      // Las mismas fechas en la zona del proceso, que con `TZ=UTC` no es la de
      // Lima, dan el mismo texto.
      expect(
        cuandoSeLeyo(ultimoMinuto.toLocal(), ahoraDia26.toLocal()),
        'ayer a las 23:59',
      );
    });

    test('un leidoEn posterior a ahora, por un reloj atrasado, da «hoy»', () {
      expect(
        cuandoSeLeyo(DateTime.utc(2026, 9, 26, 15, 42), ahora),
        'hoy a las 10:42',
      );
    });

    test('los doce meses salen en minúscula', () {
      const meses = [
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
      final fin = DateTime.utc(2026, 12, 31, 20);
      for (var m = 1; m <= 12; m++) {
        expect(
          cuandoSeLeyo(DateTime.utc(2026, m, 10, 15), fin),
          'el 10 de ${meses[m - 1]} a las 10:00',
        );
      }
    });

    test('los textos completos de la fila y del aviso', () {
      final leido = DateTime.utc(2026, 9, 25, 15, 42);
      expect(
        textoUltimaLectura(leido, ahora),
        'Última lectura hoy a las 10:42',
      );
      expect(
        textoNotasLeidas(leido, ahora),
        'Se muestran las notas leídas hoy a las 10:42.',
      );
    });
  });
}
```

- [ ] **Paso 2. Comprueba que fallan.**

```bash
"$FLUTTER" test --no-pub test/HU37_jeff/formato_nota_test.dart test/HU37_jeff/ultima_lectura_test.dart
```

**Esperado.** Fallan al compilar porque no existen los dos archivos de
`lib/domain/recarga_ulima/`.

- [ ] **Paso 3. Implementa el formato.** Crea `lib/domain/recarga_ulima/formato_nota.dart` con
  este contenido.

```dart
// lib/domain/recarga_ulima/formato_nota.dart
//
// Formato del peso y de la nota de la recarga desde la ULima (D10 de
// specs/features/recarga-portal/recarga-portal.spec.md). Punto decimal, como
// el resto de la app.

/// Diferencia por debajo de la cual dos decimales se consideran iguales.
const double _tolerancia = 1e-9;

bool _esEntero(num v) => (v - v.roundToDouble()).abs() < _tolerancia;

/// El peso sin el signo, entero sin decimales (`20`) y con hasta dos
/// decimales si los tiene (`12.5`, `12.25`).
String numeroDePeso(num peso) {
  if (_esEntero(peso)) return peso.round().toString();
  var texto = peso.toStringAsFixed(2);
  if (texto.endsWith('0')) texto = texto.substring(0, texto.length - 1);
  return texto;
}

/// El peso con su signo, como `20%` o `12.5%`, en las dos pantallas.
String formatoPeso(num peso) => '${numeroDePeso(peso)}%';

/// La nota de `/mis-notas`, con un decimal si tiene uno o ninguno (`15.0`,
/// `14.5`) y con dos si los tiene (`14.25`).
String formatoNotaUlima(double nota) =>
    _esEntero(nota * 10) ? nota.toStringAsFixed(1) : nota.toStringAsFixed(2);

/// La nota de la calculadora, siempre con un decimal, en las dos clases de
/// filas, así que una tarjeta nunca mezcla `14.25` y `14.3`.
String formatoNotaCalculadora(double nota) => nota.toStringAsFixed(1);
```

- [ ] **Paso 4. Implementa la hora.** Crea `lib/domain/recarga_ulima/ultima_lectura.dart` con este
  contenido. Un `leidoEn` posterior a `ahora`, por un reloj atrasado, cae en «hoy».

```dart
// lib/domain/recarga_ulima/ultima_lectura.dart
//
// La hora de la última lectura de la ULima (RF-RCG-9 y D22 de
// specs/features/recarga-portal/recarga-portal.spec.md).

import '../../pages/chat/chat_linea_tiempo.dart' show enHoraDeLima;

/// Los doce meses en minúscula. Repite la lista privada `_meses` de
/// `chat_linea_tiempo.dart`, que no está en los `targets` de la spec.
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

/// La parte variable del texto, vista desde [ahora], con las dos fechas en
/// hora de Lima y comparadas por fecha de calendario.
///
/// Mismo día, o un [leidoEn] posterior a [ahora] por un reloj atrasado, da
/// `hoy a las HH:mm`. El día anterior da `ayer a las HH:mm`. Otro día del
/// mismo año da `el 22 de septiembre a las HH:mm`, y otro año suma
/// ` de 2025` después del mes.
String cuandoSeLeyo(DateTime leidoEn, DateTime ahora) {
  final leido = enHoraDeLima(leidoEn);
  final hoy = enHoraDeLima(ahora);
  final diaLeido = DateTime.utc(leido.year, leido.month, leido.day);
  final diaHoy = DateTime.utc(hoy.year, hoy.month, hoy.day);
  final hh = leido.hour.toString().padLeft(2, '0');
  final mm = leido.minute.toString().padLeft(2, '0');
  final hora = 'a las $hh:$mm';
  final dias = diaHoy.difference(diaLeido).inDays;
  if (dias <= 0) return 'hoy $hora';
  if (dias == 1) return 'ayer $hora';
  final anio = leido.year == hoy.year ? '' : ' de ${leido.year}';
  return 'el ${leido.day} de ${_meses[leido.month - 1]}$anio $hora';
}

/// `Última lectura <cuándo>`, para la fila, la franja y el bloque de
/// asistencia.
String textoUltimaLectura(DateTime leidoEn, DateTime ahora) =>
    'Última lectura ${cuandoSeLeyo(leidoEn, ahora)}';

/// `Se muestran las notas leídas <cuándo>.`, para el aviso rojo.
String textoNotasLeidas(DateTime leidoEn, DateTime ahora) =>
    'Se muestran las notas leídas ${cuandoSeLeyo(leidoEn, ahora)}.';
```

- [ ] **Paso 5. Comprueba que pasan.**

```bash
"$DART" format lib/domain/recarga_ulima test/HU37_jeff
"$FLUTTER" test --no-pub test/HU37_jeff/formato_nota_test.dart test/HU37_jeff/ultima_lectura_test.dart
TZ=UTC "$FLUTTER" test --no-pub test/HU37_jeff/ultima_lectura_test.dart
"$FLUTTER" analyze --no-pub lib/domain/recarga_ulima test/HU37_jeff
```

**Esperado.** El formato no cambia nada, pasan las 11 pruebas, con `TZ=UTC` pasan otra vez las 8
de `ultima_lectura_test.dart` y el análisis no encuentra avisos. La corrida con `TZ=UTC` es la
que cubre el teléfono en otra zona, porque Dart no cambia la zona dentro del proceso y, en una
máquina en UTC−5, `toLocal()` deja las fechas en la hora de Lima.

- [ ] **Paso 6. Commit.**

```bash
git add lib/domain/recarga_ulima/formato_nota.dart lib/domain/recarga_ulima/ultima_lectura.dart test/HU37_jeff/formato_nota_test.dart test/HU37_jeff/ultima_lectura_test.dart
git commit -m "feat(recarga-portal): formato del peso y de la nota (D10) y hora de la última lectura en hora de Lima (RF-RCG-9)"
```

---

### Tarea 3. Naranjas de texto y contraste

**Requisitos.** RF-RCG-10, la tabla de contraste salvo las filas de D12 y D24, y los dos tokens de
D11 con su comentario.

**Archivos.**
- Crear `test/HU37_jeff/contraste_recarga_test.dart`.
- Modificar `lib/configs/themes.dart`, después de `iconoNaranja`.

**Interfaces.**
- Consume `contrasteWcag(Color, Color)` de `package:ulima_plus/pages/chat/chat_linea_tiempo.dart`.
- Produce `static Color MaterialTheme.textoNaranja(Brightness b)` (`#A34300` en claro y
  `#FF6600` en oscuro) y `static Color MaterialTheme.insigniaUlimaTexto(Brightness b)`
  (`#A34300` en claro y `#FF8C42` en oscuro).

- [ ] **Paso 1. Escribe la prueba que falla.** Crea `test/HU37_jeff/contraste_recarga_test.dart`
  con este contenido. Cada pieza se mide con su fondo real, y las opacidades se mezclan con
  `Color.alphaBlend`.

```dart
// test/HU37_jeff/contraste_recarga_test.dart
//
// UNITARIA · Recarga desde la ULima (specs/features/recarga-portal/
// recarga-portal.spec.md), RF-RCG-10, contraste de cada pieza nueva con los
// valores de lib/configs/themes.dart y la fórmula de WCAG 2.1. Quedan fuera
// el botón «Actualizar» de la hoja (D12) y el texto «Nota: …/20» de las filas
// de la ULima (D24), que la spec deja como el resto de la app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/pages/chat/chat_linea_tiempo.dart'
    show contrasteWcag;

/// [frente] con opacidad [alfa] pintado sobre [fondo].
Color _mezcla(Color frente, double alfa, Color fondo) =>
    Color.alphaBlend(frente.withValues(alpha: alfa), fondo);

/// Una fila de la tabla de RF-RCG-10.
typedef _Pieza = ({String nombre, Color frente, Color fondo, double minimo});

List<_Pieza> _piezas(Brightness b) {
  final esquema = b == Brightness.light
      ? MaterialTheme.lightScheme()
      : MaterialTheme.darkScheme();
  final fila = _mezcla(esquema.primary, 0.1, esquema.surface);
  final rojo = Colors.red;
  return [
    (
      nombre: 'segunda línea de la fila «Notas oficiales»',
      frente: _mezcla(esquema.onSurface, 0.7, fila),
      fondo: fila,
      minimo: 4.5,
    ),
    (
      nombre: 'ícono de la fila',
      frente: MaterialTheme.iconoNaranja(b),
      fondo: fila,
      minimo: 3,
    ),
    (
      nombre: 'flecha de la fila',
      frente: _mezcla(esquema.onSurface, 0.5, fila),
      fondo: fila,
      minimo: 3,
    ),
    (
      nombre: 'texto de la marca ULima',
      frente: MaterialTheme.insigniaUlimaTexto(b),
      fondo: MaterialTheme.espPrincipalBg(b),
      minimo: 4.5,
    ),
    (
      nombre: 'ícono de la franja',
      frente: MaterialTheme.primaryDark,
      fondo: MaterialTheme.espPrincipalBg(b),
      minimo: 3,
    ),
    (
      nombre: 'segunda línea de la franja y del aviso',
      frente: MaterialTheme.textSecondary(b),
      fondo: MaterialTheme.cardBg(b),
      minimo: 4.5,
    ),
    (
      nombre: 'acción del aviso',
      frente: MaterialTheme.textoNaranja(b),
      fondo: MaterialTheme.cardBg(b),
      minimo: 4.5,
    ),
    (
      nombre: 'ícono rojo del aviso sobre su caja',
      frente: rojo,
      fondo: _mezcla(rojo, 0.12, MaterialTheme.cardBg(b)),
      minimo: 3,
    ),
    (
      nombre: 'ícono rojo del aviso compacto',
      frente: rojo,
      fondo: MaterialTheme.bloqueAsistencia(b),
      minimo: 3,
    ),
    (
      nombre: 'botones «Actualizar» y del estado sin datos del bloque',
      frente: MaterialTheme.textoNaranja(b),
      fondo: MaterialTheme.bloqueAsistencia(b),
      minimo: 4.5,
    ),
    (
      nombre: 'aviso de consentimiento y ayuda de la hoja',
      frente: _mezcla(esquema.onSurface, 0.7, esquema.surface),
      fondo: esquema.surface,
      minimo: 4.5,
    ),
    (
      nombre: 'pista del campo de contraseña',
      frente: _mezcla(esquema.onSurface, 0.6, esquema.surface),
      fondo: esquema.surface,
      minimo: 4.5,
    ),
    (
      nombre: 'borde de las casillas y del campo',
      frente: _mezcla(esquema.onSurface, 0.5, esquema.surface),
      fondo: esquema.surface,
      minimo: 3,
    ),
  ];
}

void main() {
  for (final brillo in Brightness.values) {
    final tema = brillo == Brightness.light ? 'claro' : 'oscuro';
    group('UNITARIA · contraste de la recarga en $tema (RF-RCG-10)', () {
      for (final pieza in _piezas(brillo)) {
        test('${pieza.nombre} llega a ${pieza.minimo}:1', () {
          expect(
            contrasteWcag(pieza.frente, pieza.fondo),
            greaterThanOrEqualTo(pieza.minimo),
          );
        });
      }
    });
  }

  test('los dos naranjas de texto tienen el valor de D11', () {
    expect(
      MaterialTheme.textoNaranja(Brightness.light),
      const Color(0xFFA34300),
    );
    expect(
      MaterialTheme.textoNaranja(Brightness.dark),
      const Color(0xFFFF6600),
    );
    expect(
      MaterialTheme.insigniaUlimaTexto(Brightness.light),
      const Color(0xFFA34300),
    );
    expect(
      MaterialTheme.insigniaUlimaTexto(Brightness.dark),
      const Color(0xFFFF8C42),
    );
  });
}
```

- [ ] **Paso 2. Comprueba que falla.**

```bash
"$FLUTTER" test --no-pub test/HU37_jeff/contraste_recarga_test.dart
```

**Esperado.** Falla al compilar porque `MaterialTheme` no tiene `textoNaranja` ni
`insigniaUlimaTexto`.

- [ ] **Paso 3. Suma los dos tokens.** Aplica este cambio a `lib/configs/themes.dart`.

```diff
diff --git a/lib/configs/themes.dart b/lib/configs/themes.dart
--- a/lib/configs/themes.dart
+++ b/lib/configs/themes.dart
@@ -173,6 +173,21 @@ class MaterialTheme {
   static Color iconoNaranja(Brightness b) =>
       b == Brightness.light ? primaryDark : primaryColor;
 
+  // ── Recarga desde la ULima (RF-RCG-10) ──────────────────────────────────
+
+  /// Naranja de un texto de acción, que pide 4,5:1 (D11). Va en `#A34300` en
+  /// claro y en `primaryColor` en oscuro, porque `primaryDark` da 4,12:1 sobre
+  /// `cardBg`. Sobre `cardBg` da 6,25:1 y 5,65:1, y sobre `bloqueAsistencia`
+  /// 5,31:1 y 4,67:1.
+  static Color textoNaranja(Brightness b) =>
+      b == Brightness.light ? const Color(0xFFA34300) : primaryColor;
+
+  /// Texto de la marca «ULima» de la calculadora (D11). Sobre
+  /// `espPrincipalBg` da 5,66:1 en claro y 5,92:1 en oscuro, donde
+  /// `primaryDark` da 3,73:1 en claro.
+  static Color insigniaUlimaTexto(Brightness b) =>
+      b == Brightness.light ? const Color(0xFFA34300) : const Color(0xFFFF8C42);
+
   // LIGHT SCHEME
   static ColorScheme lightScheme() {
     return const ColorScheme(
```

- [ ] **Paso 4. Comprueba que pasa.**

```bash
"$DART" format lib/configs/themes.dart test/HU37_jeff/contraste_recarga_test.dart
"$FLUTTER" test --no-pub test/HU37_jeff/contraste_recarga_test.dart
"$FLUTTER" analyze --no-pub lib/configs/themes.dart test/HU37_jeff
```

**Esperado.** El formato no cambia nada, pasan las 27 pruebas y el análisis no encuentra avisos.
Las mediciones coinciden con la tabla de la spec, por ejemplo 4,54:1 para la pista del campo en
claro y 3,25:1 para la flecha de la fila en claro.

- [ ] **Paso 5. Commit.**

```bash
git add lib/configs/themes.dart test/HU37_jeff/contraste_recarga_test.dart
git commit -m "feat(recarga-portal): naranjas de texto de D11 en el tema, con la prueba de contraste de RF-RCG-10"
```

---

### Tarea 4. `RecargaUlimaService`, sus avisos y el dueño de los datos

**Requisitos.** RF-RCG-1 completo (carga, recarga, cuerpo exacto, plazo, contraseña y código,
`enviando`, qué guarda y dónde, dueño de los datos y datos de terceros), la parte del servicio de
RF-RCG-3 (éxito con la única llamada a `HorarioController.reload()`, lectura parcial, error, plazo
vencido o fallo de red y `401`), la tabla de RF-RCG-4 como datos (D5), D17, D18, D23 y B19.

**Archivos.**
- Crear `test/HU37_jeff/recarga_ulima_service_test.dart`.
- Crear `lib/domain/recarga_ulima/avisos_recarga.dart`.
- Crear `lib/services/recarga_ulima_service.dart`.
- Modificar `lib/main.dart` (registro permanente, junto a `AcademicRecordService`).
- Modificar `lib/services/auth_service.dart` (`logout()`).

**Interfaces.**
- Consume los modelos de la Tarea 1, `ApiClient` y `ApiException`, `AuthService.to.currentUser`
  y `HorarioController.reload()`.
- Produce estas firmas.

```dart
// package:ulima_plus/domain/recarga_ulima/avisos_recarga.dart
enum AccionAviso { reintentar, cargarMisDatos }
class AvisoRecarga {
  const AvisoRecarga({required String cuerpo, required AccionAviso accion, bool esperaLectura = false});
  static const String titulo = 'No se pudo actualizar';
  final String cuerpo; final AccionAviso accion; final bool esperaLectura;
  String get textoAccion; // 'Reintentar' o 'Cargar mis datos'
}
const AvisoRecarga avisoPlazo;   // el plazo de 90 s, con esperaLectura
const AvisoRecarga avisoSinRed;  // fallo de red sin respuesta, con esperaLectura
AvisoRecarga avisoDeError(String code, {Object? details});

// package:ulima_plus/services/recarga_ulima_service.dart
class RecargaUlimaService extends GetxService {
  RecargaUlimaService({ApiClient? apiClient, Duration? plazo});
  static RecargaUlimaService get to;
  static const Duration plazoRecarga; // 90 s
  static const Duration plazoCarga;   // 15 s
  final Duration plazo;
  Future<void>? recargaHorario;
  VistaUlima? get vista;          // filtrado por dueño
  AvisoRecarga? get ultimoAviso;  // filtrado por dueño
  bool get errorCarga;            // filtrado por dueño
  bool get enviando;
  bool sinLecturaDeNotas(Object sectionId);
  bool sinLecturaDeAsistencia(Object sectionId);
  Worker alCambiarVista(void Function() alCambiar);
  void clear();
  void borrarAviso();
  Future<void> cargar();
  Future<bool> recargar({required String password, required String passcode});
}
```

- [ ] **Paso 1. Escribe la prueba que falla.** Crea
  `test/HU37_jeff/recarga_ulima_service_test.dart` con este contenido. El plazo se acorta a 20 ms
  en las pruebas de D23, y el espía de registros cubre `debugPrint` y `print`.

```dart
// test/HU37_jeff/recarga_ulima_service_test.dart
//
// UNITARIA · Recarga desde la ULima (specs/features/recarga-portal/
// recarga-portal.spec.md), RF-RCG-1, RF-RCG-3 y RF-RCG-4.
// Archivo probado lib/services/recarga_ulima_service.dart, con un ApiClient
// falso. Nunca toca el backend real.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/domain/recarga_ulima/avisos_recarga.dart';
import 'package:ulima_plus/pages/horario/horario_controller.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/malla_service.dart';
import 'package:ulima_plus/services/recarga_ulima_service.dart';
import 'package:ulima_plus/services/storage_service.dart';

import 'recarga_dobles.dart';

const String _refresh = 'POST /portal-sync/refresh';
const String _vistaGet = 'GET /grades/me/ulima';

/// El horario sin su carga remota, que cuenta cuántas veces se recarga.
class _HorarioEspia extends HorarioController {
  int recargas = 0;

  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  Future<void> reload() async => recargas++;
}

class _StorageFalso extends StorageService {
  @override
  Future<String?> get savedToken async => null;

  @override
  Future<void> clearSession() async {}
}

RecargaUlimaService _servicio(ApiRecargaFalsa api, {Duration? plazo}) =>
    Get.put<RecargaUlimaService>(
      RecargaUlimaService(apiClient: api, plazo: plazo),
    );

/// Una vista con otra hora de lectura, la del 22 de septiembre de 2025 a las
/// 10:50 de Lima.
Map<String, dynamic> _vistaNueva() =>
    vistaJson(lastReadAt: '2025-09-22T15:50:00.000Z');

Future<bool> _recargar(RecargaUlimaService s) =>
    s.recargar(password: 'clave-de-prueba', passcode: '482913');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  group('UNITARIA · carga y dueño de los datos (RF-RCG-1)', () {
    test('cargar() pide GET /grades/me/ulima y deja la vista', () async {
      loguear(alumna());
      final api = ApiRecargaFalsa()..responder(_vistaGet, vistaJson());
      final s = _servicio(api);

      await s.cargar();

      expect(api.veces(_vistaGet), 1);
      expect(s.vista!.cursos.single.courseName, 'TALLER DE PROTOTIPADO');
      expect(s.errorCarga, isFalse);
    });

    test('un fallo de cargar() no borra la vista del mismo alumno y deja '
        'errorCarga hasta la siguiente carga buena', () async {
      loguear(alumna());
      final api = ApiRecargaFalsa()
        ..responder(_vistaGet, vistaJson())
        ..responder(_vistaGet, errorApi(500, 'HTTP_ERROR'))
        ..responder(_vistaGet, vistaJson());
      final s = _servicio(api);

      await s.cargar();
      await s.cargar();
      expect(s.vista, isNotNull);
      expect(s.errorCarga, isTrue);

      await s.cargar();
      expect(s.errorCarga, isFalse);
    });

    test('un docente o una sesión sin usuario no piden nada', () async {
      final auth = loguear(docente());
      final api = ApiRecargaFalsa()..responder(_vistaGet, vistaJson());
      final s = _servicio(api);

      await s.cargar();
      expect(await _recargar(s), isFalse);
      auth.userRx.value = null;
      await s.cargar();

      expect(api.llamadas, isEmpty);
      expect(s.vista, isNull);
    });

    test('clear() vacía la vista, el aviso, errorCarga, enviando y los '
        'estados', () async {
      loguear(alumna());
      final api = ApiRecargaFalsa()
        ..responder(_vistaGet, errorApi(500, 'HTTP_ERROR'))
        ..responder(_refresh, errorApi(409, 'PORTAL_LOGIN_REJECTED'));
      final s = _servicio(api);
      await s.cargar();
      await _recargar(s);
      expect(s.errorCarga, isTrue);
      expect(s.ultimoAviso, isNotNull);

      s.clear();

      expect(s.vista, isNull);
      expect(s.ultimoAviso, isNull);
      expect(s.errorCarga, isFalse);
      expect(s.enviando, isFalse);
      expect(s.sinLecturaDeNotas(81), isFalse);
      expect(s.recargaHorario, isNull);
    });

    test('la vista, el aviso, errorCarga y los estados del 20230001 no se '
        'ven con el 20230002 como usuario actual', () async {
      final auth = loguear(alumna());
      final api = ApiRecargaFalsa()
        ..responder(
          _refresh,
          resultadoJson(
            courses: [
              {'sectionId': 81, 'attendance': 'failed', 'grades': 'failed'},
            ],
          ),
        )
        ..responder(_vistaGet, errorApi(500, 'HTTP_ERROR'));
      final s = _servicio(api);
      await _recargar(s);
      await s.cargar();
      expect(s.vista, isNotNull);
      expect(s.errorCarga, isTrue);
      expect(s.sinLecturaDeNotas(81), isTrue);

      // Un JWT vencido. Otro alumno entra sin logout() de por medio.
      auth.userRx.value = alumna(code: '20230002');

      expect(s.vista, isNull);
      expect(s.ultimoAviso, isNull);
      expect(s.errorCarga, isFalse);
      expect(s.sinLecturaDeNotas(81), isFalse);
      expect(s.sinLecturaDeAsistencia(81), isFalse);
    });

    test('un cargar() del 20230002 llama a clear() antes de su primer await, '
        'y si falla no deja ver la vista del 20230001', () async {
      final auth = loguear(alumna());
      final pendiente = Completer<Map<String, dynamic>>();
      final api = ApiRecargaFalsa()
        ..responder(_vistaGet, vistaJson())
        ..responder(_vistaGet, pendiente);
      final s = _servicio(api);
      await s.cargar();

      auth.userRx.value = alumna(code: '20230002');
      final carga = s.cargar();
      // Antes de que vuelva la respuesta, el estado del primero ya no está,
      // ni siquiera si vuelve el primero.
      auth.userRx.value = alumna();
      expect(s.vista, isNull);

      auth.userRx.value = alumna(code: '20230002');
      pendiente.completeError(errorApi(500, 'HTTP_ERROR'));
      await carga;
      expect(s.vista, isNull);
      expect(s.errorCarga, isTrue);
    });

    test('una respuesta de cargar() que llega después de clear() se '
        'descarta', () async {
      loguear(alumna());
      final pendiente = Completer<Map<String, dynamic>>();
      final api = ApiRecargaFalsa()..responder(_vistaGet, pendiente);
      final s = _servicio(api);

      final carga = s.cargar();
      s.clear();
      pendiente.complete(vistaJson());
      await carga;

      expect(s.vista, isNull);
    });

    test('alCambiarVista avisa con cada vista nueva y con clear()', () async {
      loguear(alumna());
      final api = ApiRecargaFalsa()..responder(_vistaGet, vistaJson());
      final s = _servicio(api);
      final conVista = <bool>[];
      final worker = s.alCambiarVista(() => conVista.add(s.vista != null));

      await s.cargar();
      s.clear();
      worker.dispose();

      expect(conVista, containsAllInOrder(<bool>[true, false]));
      expect(conVista.last, isFalse);
    });

    test('con el servicio registrado, AuthService.logout() llama a clear(), '
        'y sin él no falla', () async {
      Get.put<StorageService>(_StorageFalso());
      Get.put<MallaService>(MallaService());
      loguear(alumna());
      final api = ApiRecargaFalsa()..responder(_vistaGet, vistaJson());
      final s = _servicio(api);
      await s.cargar();
      expect(s.vista, isNotNull);

      await AuthService.to.logout();
      loguear(alumna());
      expect(s.vista, isNull);

      Get.delete<RecargaUlimaService>(force: true);
      await expectLater(AuthService.to.logout(), completes);
    });
  });

  group('UNITARIA · la recarga (RF-RCG-1, RF-RCG-3 y RF-RCG-4)', () {
    test('el cuerpo tiene exactamente credentials y consent: true, sin '
        'cookies ni código de alumno, y el plazo es de 90 s', () async {
      loguear(alumna());
      final api = ApiRecargaFalsa()..responder(_refresh, resultadoJson());
      final s = _servicio(api);

      await _recargar(s);

      expect(api.cuerposDe('/portal-sync/refresh').single, <String, dynamic>{
        'credentials': {'password': 'clave-de-prueba', 'passcode': '482913'},
        'consent': true,
      });
      expect(RecargaUlimaService.plazoRecarga, const Duration(seconds: 90));
      expect(
        RecargaUlimaService(apiClient: api).plazo,
        const Duration(seconds: 90),
      );
    });

    test(
      'un 200 aplica view, guarda los estados y llama una sola vez a '
      'HorarioController.reload(), cuyo Future queda en recargaHorario',
      () async {
        loguear(alumna());
        final horario =
            Get.put<HorarioController>(_HorarioEspia()) as _HorarioEspia;
        final api = ApiRecargaFalsa()
          ..responder(
            _refresh,
            resultadoJson(
              courses: [
                {'sectionId': 81, 'attendance': 'updated', 'grades': 'read'},
                {'sectionId': 82, 'attendance': 'missing', 'grades': 'failed'},
              ],
            ),
          );
        final s = _servicio(api);

        expect(await _recargar(s), isTrue);

        expect(s.vista!.cursos.single.sectionId, 81);
        expect(s.sinLecturaDeNotas(81), isFalse);
        expect(s.sinLecturaDeAsistencia(81), isFalse);
        expect(s.sinLecturaDeNotas(82), isTrue);
        expect(s.sinLecturaDeAsistencia('82'), isTrue);
        // Un curso que el resultado no trae tampoco tiene lectura.
        expect(s.sinLecturaDeNotas(83), isTrue);
        expect(horario.recargas, 1);
        expect(s.recargaHorario, isNotNull);
        await s.recargaHorario;
        expect(horario.recargas, 1);
        expect(api.veces(_vistaGet), 0);
        expect(s.ultimoAviso, isNull);
        expect(s.enviando, isFalse);
      },
    );

    test('un error no toca la vista ni llama a reload()', () async {
      loguear(alumna());
      final horario =
          Get.put<HorarioController>(_HorarioEspia()) as _HorarioEspia;
      final api = ApiRecargaFalsa()
        ..responder(_vistaGet, vistaJson())
        ..responder(_refresh, errorApi(409, 'PORTAL_LOGIN_REJECTED'));
      final s = _servicio(api);
      await s.cargar();
      final antes = s.vista;

      expect(await _recargar(s), isFalse);

      expect(s.vista, same(antes));
      expect(horario.recargas, 0);
      expect(s.recargaHorario, isNull);
      expect(s.ultimoAviso!.accion, AccionAviso.reintentar);
    });

    final tabla = <(String, int, String, Object?, String, AccionAviso)>[
      (
        'rechazo',
        409,
        'PORTAL_LOGIN_REJECTED',
        null,
        'miUlima rechazó los datos. Revisa tu contraseña y que el código del autenticador siga vigente.',
        AccionAviso.reintentar,
      ),
      (
        'cupo de 1 minuto',
        429,
        'RATE_LIMITED',
        {'retryAfterMinutes': 1, 'kind': 'quota'},
        'Llegaste al límite de actualizaciones por hora. Intenta de nuevo en 1 minuto.',
        AccionAviso.reintentar,
      ),
      (
        'cupo de N minutos',
        429,
        'RATE_LIMITED',
        {'retryAfterMinutes': 37, 'kind': 'quota'},
        'Llegaste al límite de actualizaciones por hora. Intenta de nuevo en 37 minutos.',
        AccionAviso.reintentar,
      ),
      (
        'rechazos',
        429,
        'RATE_LIMITED',
        {'retryAfterMinutes': 12, 'kind': 'rejected_logins'},
        'Hubo varios intentos con datos rechazados. Para cuidar tu cuenta de miUlima, intenta de nuevo en 12 minutos.',
        AccionAviso.reintentar,
      ),
      (
        '429 sin details',
        429,
        'RATE_LIMITED',
        null,
        'Hubo demasiados intentos. Intenta de nuevo más tarde.',
        AccionAviso.reintentar,
      ),
      (
        'en curso',
        409,
        'PORTAL_REFRESH_IN_PROGRESS',
        null,
        'Ya hay una actualización en curso. Espera a que termine y vuelve a intentarlo.',
        AccionAviso.reintentar,
      ),
      (
        'sin importación',
        409,
        'IMPORT_REQUIRED',
        null,
        'Primero carga tus datos del ciclo.',
        AccionAviso.cargarMisDatos,
      ),
      (
        'sesión cerrada',
        409,
        'PORTAL_SESSION_INVALID',
        null,
        'miUlima cerró la sesión antes de terminar. Inténtalo de nuevo.',
        AccionAviso.reintentar,
      ),
      (
        'otra cuenta',
        403,
        'PORTAL_IDENTITY_MISMATCH',
        null,
        'La cuenta de miUlima no corresponde a tu usuario de ULima++.',
        AccionAviso.reintentar,
      ),
      (
        'identidad',
        422,
        'PORTAL_IDENTITY_UNVERIFIABLE',
        null,
        'No se pudo confirmar tu identidad en miUlima.',
        AccionAviso.reintentar,
      ),
      (
        'caído',
        502,
        'PORTAL_UNAVAILABLE',
        null,
        'miUlima no está respondiendo. Inténtalo más tarde.',
        AccionAviso.reintentar,
      ),
      (
        'ilegible',
        502,
        'PORTAL_UNREADABLE',
        null,
        'miUlima responde con páginas que ULima++ no sabe leer.',
        AccionAviso.reintentar,
      ),
      (
        'lento',
        504,
        'PORTAL_TIMEOUT',
        null,
        'miUlima tardó demasiado en responder. Inténtalo más tarde.',
        AccionAviso.reintentar,
      ),
      (
        '400',
        400,
        'INVALID_REQUEST_BODY',
        null,
        'Algo falló al leer miUlima. Inténtalo de nuevo.',
        AccionAviso.reintentar,
      ),
      (
        '500',
        500,
        'HTTP_ERROR',
        null,
        'Algo falló al leer miUlima. Inténtalo de nuevo.',
        AccionAviso.reintentar,
      ),
      (
        'desconocido',
        418,
        'ALGO_NUEVO',
        null,
        'Algo falló al leer miUlima. Inténtalo de nuevo.',
        AccionAviso.reintentar,
      ),
    ];
    for (final (caso, status, code, details, cuerpo, accion) in tabla) {
      test('RF-RCG-4, $caso ($status $code) da su título, su cuerpo y su '
          'acción', () async {
        loguear(alumna());
        final api = ApiRecargaFalsa()
          ..responder(_refresh, errorApi(status, code, details: details));
        final s = _servicio(api);

        expect(await _recargar(s), isFalse);

        final aviso = s.ultimoAviso!;
        expect(AvisoRecarga.titulo, 'No se pudo actualizar');
        expect(aviso.cuerpo, cuerpo);
        expect(aviso.accion, accion);
        expect(
          aviso.textoAccion,
          accion == AccionAviso.reintentar ? 'Reintentar' : 'Cargar mis datos',
        );
        expect(aviso.cuerpo, isNot(contains('mensaje del backend')));
      });
    }

    test('el 409 IMPORT_REQUIRED por cambio de ciclo da el mismo aviso que '
        'el de la condición previa (B19)', () async {
      loguear(alumna());
      final api = ApiRecargaFalsa()
        ..responder(_refresh, errorApi(409, 'IMPORT_REQUIRED'))
        ..responder(
          _refresh,
          errorApi(
            409,
            'IMPORT_REQUIRED',
            details: {'reason': 'otro ciclo en la ULima'},
          ),
        );
      final s = _servicio(api);

      await _recargar(s);
      final previo = s.ultimoAviso;
      await _recargar(s);

      expect(s.ultimoAviso, previo);
    });

    test('un 401 no deja aviso, porque es la sesión de ULima++', () async {
      loguear(alumna());
      final api = ApiRecargaFalsa()
        ..responder(_refresh, errorApi(401, 'UNAUTHORIZED'));
      final s = _servicio(api);

      expect(await _recargar(s), isFalse);
      expect(s.ultimoAviso, isNull);
    });

    test('enviar un nuevo intento borra el aviso anterior', () async {
      loguear(alumna());
      final pendiente = Completer<Map<String, dynamic>>();
      final api = ApiRecargaFalsa()
        ..responder(_refresh, errorApi(409, 'PORTAL_LOGIN_REJECTED'))
        ..responder(_refresh, pendiente);
      final s = _servicio(api);
      await _recargar(s);
      expect(s.ultimoAviso, isNotNull);

      final segunda = _recargar(s);
      expect(s.ultimoAviso, isNull);
      expect(s.enviando, isTrue);
      pendiente.complete(resultadoJson());
      await segunda;
    });

    test('una segunda llamada durante enviando no sale', () async {
      loguear(alumna());
      final pendiente = Completer<Map<String, dynamic>>();
      final api = ApiRecargaFalsa()..responder(_refresh, pendiente);
      final s = _servicio(api);

      final primera = _recargar(s);
      expect(await _recargar(s), isFalse);
      expect(api.veces(_refresh), 1);

      pendiente.complete(resultadoJson());
      expect(await primera, isTrue);
    });

    test('una respuesta de recargar() que llega después de clear() se '
        'descarta y no vuelve a llenar la vista ni el aviso', () async {
      loguear(alumna());
      final bien = Completer<Map<String, dynamic>>();
      final mal = Completer<Map<String, dynamic>>();
      final api = ApiRecargaFalsa()
        ..responder(_refresh, bien)
        ..responder(_refresh, mal);
      final s = _servicio(api);

      final primera = _recargar(s);
      s.clear();
      bien.complete(resultadoJson());
      expect(await primera, isFalse);
      expect(s.vista, isNull);

      final segunda = _recargar(s);
      s.clear();
      mal.completeError(errorApi(409, 'PORTAL_LOGIN_REJECTED'));
      expect(await segunda, isFalse);
      expect(s.ultimoAviso, isNull);
    });

    test(
      'ningún mensaje de registro contiene la contraseña ni el código',
      () async {
        final mensajes = <String>[];
        final original = debugPrint;
        debugPrint = (String? m, {int? wrapWidth}) {
          if (m != null) mensajes.add(m);
        };
        addTearDown(() => debugPrint = original);
        loguear(alumna());
        final api = ApiRecargaFalsa()
          ..responder(_refresh, resultadoJson())
          ..responder(_refresh, errorApi(409, 'PORTAL_LOGIN_REJECTED'))
          ..responder(_refresh, const SocketException('sin red'))
          ..responder(_vistaGet, errorApi(500, 'HTTP_ERROR'));

        await runZoned(
          () async {
            final s = _servicio(api);
            await _recargar(s);
            await _recargar(s);
            await _recargar(s);
            await s.cargar();
          },
          zoneSpecification: ZoneSpecification(
            print: (_, _, _, linea) => mensajes.add(linea),
          ),
        );

        expect(mensajes, isNotEmpty);
        expect(
          mensajes.where(
            (m) => m.contains('clave-de-prueba') || m.contains('482913'),
          ),
          isEmpty,
        );
      },
    );
  });

  group('UNITARIA · plazo vencido o fallo de red (D23)', () {
    test('tras el plazo, recargar() pide la vista y, si la lastReadAt '
        'avanzó, vuelve como éxito sin estados y sin aviso', () async {
      loguear(alumna());
      final horario =
          Get.put<HorarioController>(_HorarioEspia()) as _HorarioEspia;
      final api = ApiRecargaFalsa()
        ..responder(_vistaGet, vistaJson())
        ..responder(_vistaGet, _vistaNueva())
        ..responder(_refresh, Completer<Map<String, dynamic>>());
      final s = _servicio(api, plazo: const Duration(milliseconds: 20));
      await s.cargar();

      expect(await _recargar(s), isTrue);

      expect(api.veces(_vistaGet), 2);
      expect(s.ultimoAviso, isNull);
      expect(s.sinLecturaDeNotas(81), isFalse);
      expect(horario.recargas, 1);
    });

    test('tras el plazo, si la lastReadAt no avanzó, vuelve con el aviso del '
        'plazo', () async {
      loguear(alumna());
      final api = ApiRecargaFalsa()
        ..responder(_vistaGet, vistaJson())
        ..responder(_refresh, Completer<Map<String, dynamic>>());
      final s = _servicio(api, plazo: const Duration(milliseconds: 20));
      await s.cargar();

      expect(await _recargar(s), isFalse);

      expect(api.veces(_vistaGet), 2);
      expect(s.ultimoAviso, avisoPlazo);
      expect(
        s.ultimoAviso!.cuerpo,
        'La actualización tardó demasiado. Inténtalo de nuevo en unos minutos.',
      );
    });

    test('tras un fallo de red, una vista con hora donde antes había null '
        'cuenta como guardada', () async {
      loguear(alumna());
      final api = ApiRecargaFalsa()
        ..responder(_vistaGet, vistaJson(lastReadAt: null))
        ..responder(_vistaGet, vistaJson())
        ..responder(_refresh, const SocketException('sin red'));
      final s = _servicio(api);
      await s.cargar();

      expect(await _recargar(s), isTrue);
      expect(s.ultimoAviso, isNull);
    });

    test('tras un fallo de red sin lectura nueva, vuelve con el aviso de la '
        'red', () async {
      loguear(alumna());
      final api = ApiRecargaFalsa()
        ..responder(_vistaGet, vistaJson())
        ..responder(_refresh, const SocketException('sin red'));
      final s = _servicio(api);
      await s.cargar();

      expect(await _recargar(s), isFalse);
      expect(s.ultimoAviso, avisoSinRed);
      expect(
        s.ultimoAviso!.cuerpo,
        'No hay conexión. Revisa tu internet e inténtalo de nuevo.',
      );
    });

    test(
      'con el aviso del plazo presente, un cargar() con la hora más nueva '
      'lo borra y llama a reload(), y uno con la misma hora lo deja',
      () async {
        loguear(alumna());
        final horario =
            Get.put<HorarioController>(_HorarioEspia()) as _HorarioEspia;
        final api = ApiRecargaFalsa()
          ..responder(_vistaGet, vistaJson())
          ..responder(_vistaGet, vistaJson())
          ..responder(_vistaGet, vistaJson())
          ..responder(_vistaGet, _vistaNueva())
          ..responder(_refresh, Completer<Map<String, dynamic>>());
        final s = _servicio(api, plazo: const Duration(milliseconds: 20));
        await s.cargar();
        await _recargar(s);
        expect(s.ultimoAviso, avisoPlazo);

        await s.cargar();
        expect(s.ultimoAviso, avisoPlazo);
        expect(horario.recargas, 0);

        await s.cargar();
        expect(s.ultimoAviso, isNull);
        expect(horario.recargas, 1);
      },
    );

    test('un aviso que no es del plazo ni de la red no lo borra una lectura '
        'nueva', () async {
      loguear(alumna());
      final api = ApiRecargaFalsa()
        ..responder(_vistaGet, vistaJson())
        ..responder(_vistaGet, _vistaNueva())
        ..responder(_refresh, errorApi(409, 'PORTAL_LOGIN_REJECTED'));
      final s = _servicio(api);
      await s.cargar();
      await _recargar(s);

      await s.cargar();
      expect(s.ultimoAviso, isNotNull);
    });
  });
}
```

- [ ] **Paso 2. Comprueba que falla.**

```bash
"$FLUTTER" test --no-pub test/HU37_jeff/recarga_ulima_service_test.dart
```

**Esperado.** Falla al compilar porque no existen `avisos_recarga.dart` ni
`recarga_ulima_service.dart`.

- [ ] **Paso 3. Los avisos.** Crea `lib/domain/recarga_ulima/avisos_recarga.dart` con este
  contenido. El aviso se elige solo por el código, así que los dos casos de `IMPORT_REQUIRED` y
  los dos de `PORTAL_REFRESH_IN_PROGRESS` dan el mismo cuerpo (B19).

```dart
// lib/domain/recarga_ulima/avisos_recarga.dart
//
// El aviso rojo de una recarga fallida (RF-RCG-4 y D5 de
// specs/features/recarga-portal/recarga-portal.spec.md). La app nunca
// muestra el `message` del backend, así que cada causa tiene su cuerpo fijo.

/// Qué hace el botón del aviso.
enum AccionAviso { reintentar, cargarMisDatos }

class AvisoRecarga {
  const AvisoRecarga({
    required this.cuerpo,
    required this.accion,
    this.esperaLectura = false,
  });

  /// El título es siempre el mismo.
  static const String titulo = 'No se pudo actualizar';

  final String cuerpo;
  final AccionAviso accion;

  /// Es el aviso del plazo o de la red, que se borra solo cuando una lectura
  /// posterior muestra que la recarga sí queda guardada (D23).
  final bool esperaLectura;

  String get textoAccion =>
      accion == AccionAviso.reintentar ? 'Reintentar' : 'Cargar mis datos';

  @override
  bool operator ==(Object other) =>
      other is AvisoRecarga &&
      other.cuerpo == cuerpo &&
      other.accion == accion &&
      other.esperaLectura == esperaLectura;

  @override
  int get hashCode => Object.hash(cuerpo, accion, esperaLectura);
}

/// El plazo de 90 s de la app vence sin respuesta.
const AvisoRecarga avisoPlazo = AvisoRecarga(
  cuerpo:
      'La actualización tardó demasiado. Inténtalo de nuevo en unos '
      'minutos.',
  accion: AccionAviso.reintentar,
  esperaLectura: true,
);

/// La petición falla por la red, sin respuesta del backend.
const AvisoRecarga avisoSinRed = AvisoRecarga(
  cuerpo: 'No hay conexión. Revisa tu internet e inténtalo de nuevo.',
  accion: AccionAviso.reintentar,
  esperaLectura: true,
);

String _minutos(int n) => n == 1 ? '1 minuto' : '$n minutos';

AvisoRecarga _reintentar(String cuerpo) =>
    AvisoRecarga(cuerpo: cuerpo, accion: AccionAviso.reintentar);

AvisoRecarga _limite(Object? details) {
  final datos = details is Map ? details : const <Object?, Object?>{};
  final minutos = datos['retryAfterMinutes'];
  final n = minutos is num ? minutos.round() : null;
  switch (datos['kind']) {
    case 'quota' when n != null:
      return _reintentar(
        'Llegaste al límite de actualizaciones por hora. '
        'Intenta de nuevo en ${_minutos(n)}.',
      );
    case 'rejected_logins' when n != null:
      return _reintentar(
        'Hubo varios intentos con datos rechazados. Para '
        'cuidar tu cuenta de miUlima, intenta de nuevo en ${_minutos(n)}.',
      );
    default:
      return _reintentar(
        'Hubo demasiados intentos. Intenta de nuevo más tarde.',
      );
  }
}

/// El aviso de un error del backend, por su código (tabla de RF-RCG-4). Un
/// `400`, un `500` o un código desconocido dan el aviso genérico.
AvisoRecarga avisoDeError(String code, {Object? details}) {
  switch (code) {
    case 'PORTAL_LOGIN_REJECTED':
      return _reintentar(
        'miUlima rechazó los datos. Revisa tu contraseña y '
        'que el código del autenticador siga vigente.',
      );
    case 'RATE_LIMITED':
      return _limite(details);
    case 'PORTAL_REFRESH_IN_PROGRESS':
      return _reintentar(
        'Ya hay una actualización en curso. Espera a que '
        'termine y vuelve a intentarlo.',
      );
    case 'IMPORT_REQUIRED':
      return const AvisoRecarga(
        cuerpo: 'Primero carga tus datos del ciclo.',
        accion: AccionAviso.cargarMisDatos,
      );
    case 'PORTAL_SESSION_INVALID':
      return _reintentar(
        'miUlima cerró la sesión antes de terminar. Inténtalo de nuevo.',
      );
    case 'PORTAL_IDENTITY_MISMATCH':
      return _reintentar(
        'La cuenta de miUlima no corresponde a tu usuario de ULima++.',
      );
    case 'PORTAL_IDENTITY_UNVERIFIABLE':
      return _reintentar('No se pudo confirmar tu identidad en miUlima.');
    case 'PORTAL_UNAVAILABLE':
      return _reintentar('miUlima no está respondiendo. Inténtalo más tarde.');
    case 'PORTAL_UNREADABLE':
      return _reintentar(
        'miUlima responde con páginas que ULima++ no sabe leer.',
      );
    case 'PORTAL_TIMEOUT':
      return _reintentar(
        'miUlima tardó demasiado en responder. Inténtalo más tarde.',
      );
    default:
      return _reintentar('Algo falló al leer miUlima. Inténtalo de nuevo.');
  }
}
```

- [ ] **Paso 4. El servicio.** Crea `lib/services/recarga_ulima_service.dart` con este contenido.

```dart
// lib/services/recarga_ulima_service.dart
//
// Única frontera de la app con `GET /grades/me/ulima` y
// `POST /portal-sync/refresh` (RF-RCG-1 de
// specs/features/recarga-portal/recarga-portal.spec.md). Es permanente porque
// la calculadora, `/mis-notas` y la ficha del curso comparten su estado.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../domain/recarga_ulima/avisos_recarga.dart';
import '../models/recarga_ulima_models.dart';
import '../pages/horario/horario_controller.dart';
import 'api_client.dart';
import 'auth_service.dart';

/// Estado de la recarga desde la ULima.
///
/// **La contraseña y el código no se guardan.** Llegan como parámetros de
/// [recargar] y se descartan al volver. Nunca entran en un `Rx`, en
/// `shared_preferences`, en `flutter_secure_storage` ni en un `debugPrint`, y
/// el cuerpo de la petición nunca se imprime.
///
/// **Dueño de los datos.** El estado se ata al alumno que lo pide, como en
/// `AcademicRecordService`. Los getters filtran por dueño, [cargar] y
/// [recargar] descartan el estado ajeno antes de cualquier `await`, y una
/// respuesta que vuelve después de un [clear] se descarta. Así el siguiente
/// alumno del mismo teléfono no ve nada del anterior, aunque el JWT caduque
/// sin pasar por `AuthService.logout()`.
class RecargaUlimaService extends GetxService {
  RecargaUlimaService({ApiClient? apiClient, Duration? plazo})
    : _api = apiClient ?? ApiClient(),
      plazo = plazo ?? plazoRecarga;

  static RecargaUlimaService get to => Get.find();

  /// Plazo de la app para la recarga, el mismo de la importación (D18).
  static const Duration plazoRecarga = Duration(seconds: 90);

  /// Plazo de `GET /grades/me/ulima`, que no entra al portal.
  static const Duration plazoCarga = Duration(seconds: 15);

  final ApiClient _api;

  /// El plazo de esta instancia. Las pruebas lo acortan.
  final Duration plazo;

  final Rxn<VistaUlima> _vista = Rxn<VistaUlima>();
  final Rxn<AvisoRecarga> _ultimoAviso = Rxn<AvisoRecarga>();
  final RxBool _errorCarga = false.obs;
  final RxBool _enviando = false.obs;

  /// Estados por curso del último `200`, por `sectionId` como texto, o `null`
  /// si no hay un resultado con estados.
  final Rxn<Map<String, EstadoCursoRecarga>> _estados =
      Rxn<Map<String, EstadoCursoRecarga>>();

  /// Código del alumno dueño del estado.
  String? _ownerCode;

  /// Sube con cada [clear]. Una respuesta que vuelve con otro número se
  /// descarta.
  int _generacion = 0;

  /// La `lastReadAt` que tiene la vista al enviar la recarga que termina en
  /// el aviso del plazo o de la red (D23).
  DateTime? _lecturaAlEnviar;

  /// La recarga del horario que corre tras una recarga guardada (RF-RCG-3).
  /// Es la única llamada a `HorarioController.reload()` de la recarga, y la
  /// ficha del curso la espera en vez de repetirla.
  Future<void>? recargaHorario;

  bool get _esDelActual {
    final code = AuthService.to.currentUser?.code;
    return code != null && code == _ownerCode;
  }

  /// La vista del alumno actual, o `null`. El `Rx` se lee primero para que el
  /// `Obx` que llama se suscriba aunque después se devuelva `null`.
  VistaUlima? get vista {
    final v = _vista.value;
    return _esDelActual ? v : null;
  }

  /// El aviso rojo de la última recarga fallida del alumno actual.
  AvisoRecarga? get ultimoAviso {
    final a = _ultimoAviso.value;
    return _esDelActual ? a : null;
  }

  /// Si la última carga de la vista termina en error. No borra la vista
  /// anterior.
  bool get errorCarga {
    final e = _errorCarga.value;
    return _esDelActual && e;
  }

  /// Hay una recarga en vuelo.
  bool get enviando => _enviando.value;

  /// Si el último resultado con estados no trae las notas de [sectionId]
  /// como leídas (RF-RCG-3).
  bool sinLecturaDeNotas(Object sectionId) {
    final estados = _estados.value;
    if (!_esDelActual || estados == null) return false;
    return estados['$sectionId']?.grades != 'read';
  }

  /// Si el último resultado con estados no trae la asistencia de
  /// [sectionId] como actualizada (RF-RCG-3 y RF-RCG-8).
  bool sinLecturaDeAsistencia(Object sectionId) {
    final estados = _estados.value;
    if (!_esDelActual || estados == null) return false;
    return estados['$sectionId']?.attendance != 'updated';
  }

  /// Llama a [alCambiar] con cada cambio de la vista, sin exponer el `Rx`.
  /// Quien lo pide cierra el `Worker`.
  Worker alCambiarVista(void Function() alCambiar) =>
      ever<VistaUlima?>(_vista, (_) => alCambiar());

  /// Vacía todo y descarta lo que esté en vuelo.
  void clear() {
    _generacion++;
    _ownerCode = null;
    _vista.value = null;
    _ultimoAviso.value = null;
    _errorCarga.value = false;
    _enviando.value = false;
    _estados.value = null;
    _lecturaAlEnviar = null;
    recargaHorario = null;
  }

  /// Borra el aviso rojo, como pide «Cargar mis datos» (RF-RCG-4).
  void borrarAviso() {
    _ultimoAviso.value = null;
    _lecturaAlEnviar = null;
  }

  /// Toma como dueño al alumno actual, o devuelve `false` si no hay uno que
  /// pueda usar la recarga. Descarta el estado ajeno antes de cualquier
  /// `await`.
  bool _tomarDueno() {
    final user = AuthService.to.currentUser;
    if (user == null || user.isTeacher) return false;
    if (_ownerCode != user.code) clear();
    _ownerCode = user.code;
    return true;
  }

  static bool _avanzo(DateTime? antes, DateTime? despues) =>
      despues != null && (antes == null || despues.isAfter(antes));

  /// Pide `GET /grades/me/ulima`. Nunca lanza. Un fallo no borra la vista
  /// que ya hay y deja [errorCarga] en verdadero hasta la siguiente carga
  /// buena.
  Future<void> cargar() async {
    if (!_tomarDueno()) return;
    final generacion = _generacion;
    try {
      final json = await _api.getJson('/grades/me/ulima').timeout(plazoCarga);
      if (generacion != _generacion) return;
      final nueva = VistaUlima.fromJson(json);
      _vista.value = nueva;
      _errorCarga.value = false;
      // D23. La recarga que vence el plazo o falla por la red sí queda
      // guardada.
      final aviso = _ultimoAviso.value;
      if (aviso != null &&
          aviso.esperaLectura &&
          _avanzo(_lecturaAlEnviar, nueva.lastReadAt)) {
        _ultimoAviso.value = null;
        _lecturaAlEnviar = null;
        _recargarHorario();
      }
    } catch (e) {
      if (generacion != _generacion) return;
      debugPrint(
        'No se pudieron cargar las notas de la ULima: '
        '${e.runtimeType}',
      );
      _errorCarga.value = true;
    }
  }

  void _recargarHorario() {
    recargaHorario = Get.isRegistered<HorarioController>()
        ? Get.find<HorarioController>().reload()
        : null;
  }

  /// Recarga notas y asistencia con un solo inicio de sesión en miUlima
  /// (`POST /portal-sync/refresh`, RF-RCG-1 y RF-RCG-3).
  ///
  /// Devuelve `true` si la recarga queda guardada, con un `200` o con la
  /// lectura posterior de D23. Con un error deja el aviso de RF-RCG-4 en
  /// [ultimoAviso] y devuelve `false`. Una segunda llamada mientras hay otra
  /// en vuelo no hace nada y devuelve `false`.
  Future<bool> recargar({
    required String password,
    required String passcode,
  }) async {
    if (_enviando.value) return false;
    if (!_tomarDueno()) return false;
    final generacion = _generacion;
    final lecturaAntes = _vista.value?.lastReadAt;
    _enviando.value = true;
    _ultimoAviso.value = null;
    _lecturaAlEnviar = null;
    _estados.value = null;
    try {
      final json = await _api
          .postJson(
            '/portal-sync/refresh',
            body: {
              'credentials': {'password': password, 'passcode': passcode},
              'consent': true,
            },
          )
          .timeout(plazo);
      if (generacion != _generacion) return false;
      final resultado = ResultadoRecarga.fromJson(json);
      _vista.value = resultado.view;
      _errorCarga.value = false;
      _estados.value = {for (final e in resultado.estados) '${e.sectionId}': e};
      _recargarHorario();
      return true;
    } on ApiException catch (e) {
      if (generacion != _generacion) return false;
      // El 401 es la expiración del JWT y la maneja ApiClient, que cierra la
      // sesión. El backend nunca responde 401 por un fallo del portal.
      if (e.statusCode != 401) {
        _ultimoAviso.value = avisoDeError(e.code, details: e.details);
      }
      return false;
    } on TimeoutException {
      return _trasPlazoORed(avisoPlazo, lecturaAntes, generacion);
    } catch (_) {
      // ApiClient propaga los fallos de red sin envolverlos.
      return _trasPlazoORed(avisoSinRed, lecturaAntes, generacion);
    } finally {
      if (generacion == _generacion) _enviando.value = false;
    }
  }

  /// El backend puede terminar y escribir después de que la app deja de
  /// esperar, así que se vuelve a pedir la vista antes de decidir (D23).
  Future<bool> _trasPlazoORed(
    AvisoRecarga aviso,
    DateTime? lecturaAntes,
    int generacion,
  ) async {
    if (generacion != _generacion) return false;
    await cargar();
    if (generacion != _generacion) return false;
    if (_avanzo(lecturaAntes, _vista.value?.lastReadAt)) {
      // Como un 200, pero sin estados por curso.
      _recargarHorario();
      return true;
    }
    _ultimoAviso.value = aviso;
    _lecturaAlEnviar = lecturaAntes;
    return false;
  }
}
```

- [ ] **Paso 5. El registro y el cierre de sesión.** Aplica estos dos cambios.

```diff
diff --git a/lib/main.dart b/lib/main.dart
--- a/lib/main.dart
+++ b/lib/main.dart
@@ -12,6 +12,7 @@ import '/services/auth_service.dart';
 import '/services/alert_service.dart';
 import '/services/malla_service.dart';
 import '/services/academic_record_service.dart';
+import '/services/recarga_ulima_service.dart';
 import '/services/time_blocks_service.dart';
 import '/services/post_login_route.dart';
 import '/services/storage_service.dart';
@@ -74,6 +75,9 @@ void main() async {
   // Estado único del récord (RF-REC-5), compartido por la tarjeta del Perfil y
   // /mi-record. No carga nada al arrancar: la tarjeta lo pide al montarse.
   Get.put<AcademicRecordService>(AcademicRecordService(), permanent: true);
+  // Estado único de la recarga desde la ULima (RF-RCG-1), compartido por la
+  // calculadora, /mis-notas y la ficha del curso. No carga nada al arrancar.
+  Get.put<RecargaUlimaService>(RecargaUlimaService(), permanent: true);
   // Estado único de los bloques de horario propios (RF-BLQ-7). Permanente
   // como MallaService: la pantalla de horario es una tab del shell y el
   // formulario de /bloque escribe sobre este mismo estado. Tampoco carga nada
```

```diff
diff --git a/lib/services/auth_service.dart b/lib/services/auth_service.dart
--- a/lib/services/auth_service.dart
+++ b/lib/services/auth_service.dart
@@ -13,6 +13,7 @@ import 'courses_service.dart';
 import 'evaluations_service.dart';
 import 'malla_service.dart';
 import 'official_grades_service.dart';
+import 'recarga_ulima_service.dart';
 import 'storage_service.dart';
 import 'time_blocks_service.dart';
 
@@ -396,6 +397,9 @@ class AuthService extends GetxService {
     // Con guarda porque, a diferencia de los tres de arriba, hay pruebas que
     // llaman a logout() sin registrar AcademicRecordService (test/HU02_jeff/).
     if (Get.isRegistered<AcademicRecordService>()) AcademicRecordService.to.clear();
+    // Las notas y la asistencia leídas de la ULima (RF-RCG-1), con la misma
+    // guarda.
+    if (Get.isRegistered<RecargaUlimaService>()) RecargaUlimaService.to.clear();
     // Los bloques de horario propios (RF-BLQ-7) son horarios de trabajo o de
     // prácticas que el backend protege a propósito (RS-BE-35): se vacían
     // igual que el récord. Con guarda por lo mismo que la línea de arriba.
```

- [ ] **Paso 6. Comprueba que pasa.**

```bash
"$DART" format lib/domain/recarga_ulima/avisos_recarga.dart lib/services/recarga_ulima_service.dart test/HU37_jeff/recarga_ulima_service_test.dart
"$FLUTTER" test --no-pub test/HU37_jeff/recarga_ulima_service_test.dart test/HU02_jeff
"$FLUTTER" analyze --no-pub lib/domain/recarga_ulima lib/services/recarga_ulima_service.dart lib/services/auth_service.dart test/HU37_jeff
```

**Esperado.** El formato no cambia nada, pasan las 40 pruebas del servicio y las de `HU02_jeff`, y
el análisis no encuentra avisos.

- [ ] **Paso 7. Suite completa en segundo plano.** Corre `"$FLUTTER" analyze --no-pub` y
  `"$FLUTTER" test --no-pub` con `run_in_background` y espera las dos notificaciones.
  **Esperado.** Los mismos 6 avisos de la línea base y 1309 pruebas en verde (1223 más las 86 de
  las Tareas 1 a 4).

- [ ] **Paso 8. Commit.**

```bash
git add lib/domain/recarga_ulima/avisos_recarga.dart lib/services/recarga_ulima_service.dart lib/main.dart lib/services/auth_service.dart test/HU37_jeff/recarga_ulima_service_test.dart
git commit -m "feat(recarga-portal): RecargaUlimaService con la vista, la recarga, el aviso rojo y el dueño de los datos (RF-RCG-1, RF-RCG-3 y RF-RCG-4)"
```

---

### Tarea 5. La hoja de recarga

**Requisitos.** RF-RCG-2 completo (forma, los cuatro parámetros opcionales de
`PasswordResetOtpField`, cuándo se enciende «Actualizar», espera y cierre), el cierre de la hoja
de RF-RCG-3, D4, D12, D13, D14 y la accesibilidad de la hoja de RF-RCG-10.

**Archivos.**
- Crear `test/HU37_jeff/hoja_recarga_test.dart`.
- Modificar `lib/pages/password_reset/password_reset_ui.dart` (`PasswordResetOtpField` y
  `_OtpBox`).
- Crear `lib/components/recarga_ulima/hoja_recarga_ulima.dart`.

**Interfaces.**
- Consume `RecargaUlimaService.recargar` y `AuthService.to.currentUser` de la Tarea 4,
  `validarFormulario({required String password, required String passcode})` de
  `portal_sync_controller.dart`, `PasswordResetPalette.from(context)` y
  `MaterialTheme.primaryColor`.
- Produce estas firmas.

```dart
// package:ulima_plus/pages/password_reset/password_reset_ui.dart
const PasswordResetOtpField({
  Key? key,
  required TextEditingController controller,
  required PasswordResetPalette palette,
  int length = passwordResetCodeLength,
  double boxHeight = 52,
  Color? boxFill,                          // null usa palette.fieldFill
  Color idleBorderColor = Colors.transparent,
  bool readOnly = false,
});

// package:ulima_plus/components/recarga_ulima/hoja_recarga_ulima.dart
Future<bool> abrirHojaRecargaUlima(BuildContext context); // true si la recarga se guardó
class HojaRecargaUlima extends StatefulWidget { const HojaRecargaUlima({Key? key}); }
```

- [ ] **Paso 1. Escribe la prueba que falla.** Crea `test/HU37_jeff/hoja_recarga_test.dart` con
  este contenido. Su primer grupo fija la forma por defecto de `PasswordResetOtpField`, que no
  puede cambiar para `/portal-sync`, `/registro` ni el cambio de contraseña.

```dart
// test/HU37_jeff/hoja_recarga_test.dart
//
// WIDGET · Recarga desde la ULima (specs/features/recarga-portal/
// recarga-portal.spec.md), RF-RCG-2 y RF-RCG-3, la hoja de recarga, y los
// cuatro parámetros opcionales de PasswordResetOtpField.
// Archivos probados lib/components/recarga_ulima/hoja_recarga_ulima.dart y
// lib/pages/password_reset/password_reset_ui.dart.
//
// Con un campo enfocado el cursor parpadea sin fin, así que estas pruebas
// avanzan el reloj con pump y nunca con pumpAndSettle.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/recarga_ulima/hoja_recarga_ulima.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/pages/password_reset/password_reset_ui.dart';
import 'package:ulima_plus/services/recarga_ulima_service.dart';

import 'recarga_dobles.dart';

const String _refresh = 'POST /portal-sync/refresh';

ThemeData _tema(Brightness brillo) {
  const tema = MaterialTheme(TextTheme());
  return brillo == Brightness.light ? tema.light() : tema.dark();
}

/// Una pantalla alta, porque con la fuente de pruebas cada letra mide 1 em y
/// la hoja entera no cabe en 600 de alto.
void _pantallaAlta(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

/// Deja correr las animaciones de la hoja, sin esperar al cursor.
Future<void> _asentar(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// El resultado de la última hoja cerrada, o `null` si sigue abierta.
bool? _resultado;

Future<ApiRecargaFalsa> _abrir(
  WidgetTester tester, {
  Brightness brillo = Brightness.light,
  ApiRecargaFalsa? api,
  bool conUsuario = true,
}) async {
  _pantallaAlta(tester);
  loguear(conUsuario ? alumna() : null);
  final falsa = api ?? ApiRecargaFalsa();
  Get.put<RecargaUlimaService>(RecargaUlimaService(apiClient: falsa));
  _resultado = null;
  await tester.pumpWidget(
    GetMaterialApp(
      theme: _tema(brillo),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                _resultado = await abrirHojaRecargaUlima(context);
              },
              child: const Text('ABRIR'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('ABRIR'));
  await _asentar(tester);
  return falsa;
}

Finder get _campoContrasena => find.byType(TextField).first;
Finder get _campoCodigo => find.descendant(
  of: find.byType(PasswordResetOtpField),
  matching: find.byType(TextField),
);
Finder get _cajas => find.descendant(
  of: find.byType(PasswordResetOtpField),
  matching: find.byType(AnimatedContainer),
);

ElevatedButton _botonActualizar(WidgetTester tester) =>
    tester.widget<ElevatedButton>(find.byType(ElevatedButton).last);

Future<void> _llenar(
  WidgetTester tester, {
  String password = 'clave-de-prueba',
  String codigo = '482913',
}) async {
  await tester.enterText(_campoContrasena, password);
  await tester.enterText(_campoCodigo, codigo);
  await tester.pump();
}

String _textoDe(WidgetTester tester, Finder campo) =>
    tester.widget<TextField>(campo).controller!.text;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  group('WIDGET · PasswordResetOtpField conserva su forma por defecto', () {
    testWidgets('sin los parámetros nuevos, 52 de alto, el relleno de la '
        'paleta y el borde en reposo transparente de 2', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      late PasswordResetPalette paleta;
      await tester.pumpWidget(
        MaterialApp(
          theme: _tema(Brightness.light),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                paleta = PasswordResetPalette.from(context);
                return PasswordResetOtpField(
                  controller: controller,
                  palette: paleta,
                );
              },
            ),
          ),
        ),
      );

      expect(_cajas, findsNWidgets(6));
      for (final caja in tester.widgetList<AnimatedContainer>(_cajas)) {
        final deco = caja.decoration! as BoxDecoration;
        expect(deco.color, paleta.fieldFill);
        final borde = deco.border! as Border;
        expect(borde.top.color, Colors.transparent);
        expect(borde.top.width, 2);
      }
      expect(tester.getSize(_cajas.first).height, 52);
    });
  });

  group('WIDGET · la hoja de recarga (RF-RCG-2)', () {
    testWidgets('los textos exactos, con el código del alumno en negrita', (
      tester,
    ) async {
      await _abrir(tester);

      expect(find.text('Actualizar desde la ULima'), findsOneWidget);
      expect(find.text('Entras como 20230001'), findsOneWidget);
      final entras = tester.widget<Text>(find.text('Entras como 20230001'));
      final codigo =
          (entras.textSpan! as TextSpan).children!.single as TextSpan;
      expect(codigo.text, '20230001');
      expect(codigo.style!.fontWeight, FontWeight.bold);
      expect(
        find.text(
          'Al tocar «Actualizar» aceptas que ULima++ lea en miUlima tus '
          'notas parciales y tu asistencia. La contraseña y el código se '
          'usan una sola vez y no se guardan.',
        ),
        findsOneWidget,
      );
      expect(find.text('Contraseña de miUlima'), findsOneWidget);
      expect(find.text('Tu contraseña del portal'), findsOneWidget);
      expect(find.text('Código del autenticador'), findsOneWidget);
      expect(
        find.text('El código de 6 dígitos que cambia cada 30 segundos.'),
        findsOneWidget,
      );
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Actualizar'), findsOneWidget);
      expect(find.byTooltip('Cerrar'), findsOneWidget);
      expect(find.byTooltip('Mostrar contraseña'), findsOneWidget);

      await tester.tap(find.byTooltip('Mostrar contraseña'));
      await tester.pump();
      expect(find.byTooltip('Ocultar contraseña'), findsOneWidget);
    });

    testWidgets('sin usuario, la línea «Entras como» no se pinta', (
      tester,
    ) async {
      await _abrir(tester, conUsuario: false);

      expect(find.textContaining('Entras como'), findsNothing);
      expect(find.text('Actualizar desde la ULima'), findsOneWidget);
    });

    testWidgets('«Actualizar» se apaga sin contraseña, con cinco dígitos y con '
        'una contraseña de espacios, y se enciende con seis', (tester) async {
      await _abrir(tester);
      expect(_botonActualizar(tester).onPressed, isNull);

      await _llenar(tester, password: '', codigo: '482913');
      expect(_botonActualizar(tester).onPressed, isNull);

      await _llenar(tester, codigo: '48291');
      expect(_botonActualizar(tester).onPressed, isNull);

      await _llenar(tester, password: '   ', codigo: '482913');
      expect(_botonActualizar(tester).onPressed, isNull);

      await _llenar(tester);
      expect(_botonActualizar(tester).onPressed, isNotNull);

      // Apagado lleva primary al 30 % de fondo y onSurface al 38 % de texto.
      await _llenar(tester, password: '');
      final estilo = _botonActualizar(tester).style!;
      final colores = _tema(Brightness.light).colorScheme;
      expect(
        estilo.backgroundColor!.resolve({WidgetState.disabled}),
        colores.primary.withValues(alpha: 0.3),
      );
      expect(
        estilo.foregroundColor!.resolve({WidgetState.disabled}),
        colores.onSurface.withValues(alpha: 0.38),
      );
      expect(estilo.backgroundColor!.resolve({}), MaterialTheme.primaryColor);
      expect(estilo.foregroundColor!.resolve({}), Colors.white);
    });

    testWidgets('las seis casillas miden 50 de alto, no tienen relleno y '
        'llevan el borde en reposo de D13, y el campo mide al menos 52', (
      tester,
    ) async {
      await _abrir(tester);
      final colores = _tema(Brightness.light).colorScheme;

      expect(_cajas, findsNWidgets(6));
      for (final caja in tester.widgetList<AnimatedContainer>(_cajas)) {
        final deco = caja.decoration! as BoxDecoration;
        expect(deco.color, Colors.transparent);
        final borde = deco.border! as Border;
        expect(borde.top.color, colores.onSurface.withValues(alpha: 0.5));
        expect(borde.top.width, 1);
      }
      for (var i = 0; i < 6; i++) {
        expect(tester.getSize(_cajas.at(i)).height, 50);
      }
      expect(tester.getSize(_campoContrasena).height, greaterThanOrEqualTo(52));
    });

    testWidgets('la espera muestra su texto, deja las casillas de solo '
        'lectura, apaga la X y «Cancelar» y no deja cerrar con atrás', (
      tester,
    ) async {
      final pendiente = Completer<Map<String, dynamic>>();
      final api = ApiRecargaFalsa()..responder(_refresh, pendiente);
      await _abrir(tester, api: api);
      await _llenar(tester);

      await tester.tap(find.text('Actualizar'));
      await tester.pump();

      expect(api.veces(_refresh), 1);
      expect(
        find.text('Leyendo miUlima. Puede tardar hasta un minuto.'),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Actualizar'), findsNothing);
      expect(tester.widget<TextField>(_campoCodigo).readOnly, isTrue);
      expect(tester.widget<TextField>(_campoContrasena).readOnly, isTrue);
      expect(
        tester
            .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.close))
            .onPressed,
        isNull,
      );
      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNull,
      );

      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(HojaRecargaUlima), findsOneWidget);

      // Al terminar, la hoja se cierra sola.
      pendiente.complete(resultadoJson());
      await _asentar(tester);
      expect(find.byType(HojaRecargaUlima), findsNothing);
    });

    for (final (forma, cerrar)
        in <(String, Future<void> Function(WidgetTester))>[
          ('la X', (t) => t.tap(find.byTooltip('Cerrar'))),
          ('«Cancelar»', (t) => t.tap(find.text('Cancelar'))),
          ('atrás', (t) => t.binding.handlePopRoute()),
        ]) {
      testWidgets('cerrar con $forma vacía los dos campos y al reabrir llegan '
          'vacíos', (tester) async {
        await _abrir(tester);
        await _llenar(tester);
        final contrasena = tester
            .widget<TextField>(_campoContrasena)
            .controller!;
        final codigo = tester.widget<TextField>(_campoCodigo).controller!;

        await cerrar(tester);
        await _asentar(tester);

        expect(find.byType(HojaRecargaUlima), findsNothing);
        expect(_resultado, isFalse);
        expect(contrasena.text, isEmpty);
        expect(codigo.text, isEmpty);

        await tester.tap(find.text('ABRIR'));
        await _asentar(tester);
        expect(_textoDe(tester, _campoContrasena), isEmpty);
        expect(_textoDe(tester, _campoCodigo), isEmpty);
      });
    }

    testWidgets('un toque fuera no la cierra', (tester) async {
      await _abrir(tester);

      await tester.tapAt(const Offset(10, 10));
      await _asentar(tester);

      expect(find.byType(HojaRecargaUlima), findsOneWidget);
    });

    testWidgets('el éxito cierra la hoja, vacía los campos y devuelve true', (
      tester,
    ) async {
      final api = ApiRecargaFalsa()..responder(_refresh, resultadoJson());
      await _abrir(tester, api: api);
      await _llenar(tester);
      final contrasena = tester.widget<TextField>(_campoContrasena).controller!;

      await tester.tap(find.text('Actualizar'));
      await _asentar(tester);

      expect(find.byType(HojaRecargaUlima), findsNothing);
      expect(_resultado, isTrue);
      expect(contrasena.text, isEmpty);
      expect(api.cuerposDe('/portal-sync/refresh').single['credentials'], {
        'password': 'clave-de-prueba',
        'passcode': '482913',
      });
    });

    testWidgets('el error cierra la hoja, vacía los campos, devuelve false y '
        'deja el aviso', (tester) async {
      final api = ApiRecargaFalsa()
        ..responder(_refresh, errorApi(409, 'PORTAL_LOGIN_REJECTED'));
      await _abrir(tester, api: api);
      await _llenar(tester);
      final codigo = tester.widget<TextField>(_campoCodigo).controller!;

      await tester.tap(find.text('Actualizar'));
      await _asentar(tester);

      expect(find.byType(HojaRecargaUlima), findsNothing);
      expect(_resultado, isFalse);
      expect(codigo.text, isEmpty);
      expect(RecargaUlimaService.to.ultimoAviso, isNotNull);
    });

    testWidgets('las etiquetas de Semantics', (tester) async {
      final semantica = tester.ensureSemantics();
      await _abrir(tester);

      expect(
        tester.getSemantics(find.text('Actualizar desde la ULima')),
        isSemantics(isHeader: true),
      );
      final contrasena = tester.getSemantics(_campoContrasena);
      expect(contrasena, isSemantics(isTextField: true, isObscured: true));
      expect(contrasena.label, startsWith('Contraseña de miUlima'));
      expect(
        tester.getSemantics(_campoCodigo),
        isSemantics(
          isTextField: true,
          label: 'Código del autenticador, 6 dígitos',
        ),
      );
      semantica.dispose();
    });

    for (final brillo in Brightness.values) {
      testWidgets('en ${brillo.name}, la ayuda y el aviso van en onSurface al '
          '70 % y la hoja no se desborda', (tester) async {
        await _abrir(tester, brillo: brillo);
        final colores = _tema(brillo).colorScheme;

        final ayuda = tester.widget<Text>(
          find.text('El código de 6 dígitos que cambia cada 30 segundos.'),
        );
        expect(ayuda.style!.color, colores.onSurface.withValues(alpha: 0.7));
        expect(tester.takeException(), isNull);
      });
    }
  });
}
```

- [ ] **Paso 2. Comprueba que falla.**

```bash
"$FLUTTER" test --no-pub test/HU37_jeff/hoja_recarga_test.dart
```

**Esperado.** Falla al compilar porque no existe `hoja_recarga_ulima.dart`.

- [ ] **Paso 3. Los cuatro parámetros opcionales.** Aplica este cambio a
  `lib/pages/password_reset/password_reset_ui.dart`. Con sus valores por defecto, la casilla mide
  52, usa `palette.fieldFill` y conserva el borde transparente de 2 en reposo.

```diff
diff --git a/lib/pages/password_reset/password_reset_ui.dart b/lib/pages/password_reset/password_reset_ui.dart
--- a/lib/pages/password_reset/password_reset_ui.dart
+++ b/lib/pages/password_reset/password_reset_ui.dart
@@ -269,12 +269,29 @@ class PasswordResetOtpField extends StatefulWidget {
     required this.controller,
     required this.palette,
     this.length = passwordResetCodeLength,
+    this.boxHeight = 52,
+    this.boxFill,
+    this.idleBorderColor = Colors.transparent,
+    this.readOnly = false,
   });
 
   final TextEditingController controller;
   final PasswordResetPalette palette;
   final int length;
 
+  /// Alto de cada casilla. La hoja de recarga desde la ULima usa 50 (RF-RCG-2).
+  final double boxHeight;
+
+  /// Relleno de cada casilla. Con `null` usa `palette.fieldFill`.
+  final Color? boxFill;
+
+  /// Borde de las casillas que no tienen el foco, de 1 de ancho. Con el
+  /// transparente de siempre no se ve (D13 de la recarga).
+  final Color idleBorderColor;
+
+  /// Durante la espera de la recarga, las casillas no se enfocan ni se editan.
+  final bool readOnly;
+
   @override
   State<PasswordResetOtpField> createState() => _PasswordResetOtpFieldState();
 }
@@ -304,6 +321,7 @@ class _PasswordResetOtpFieldState extends State<PasswordResetOtpField> {
       widget.controller.addListener(_handleValueChanged);
       _paintedText = widget.controller.text;
     }
+    if (widget.readOnly && !oldWidget.readOnly) _focusNode.unfocus();
   }
 
   @override
@@ -358,6 +376,9 @@ class _PasswordResetOtpFieldState extends State<PasswordResetOtpField> {
                   palette: widget.palette,
                   digit: i < text.length ? text[i] : '',
                   active: _focusNode.hasFocus && i == activeIndex,
+                  height: widget.boxHeight,
+                  fill: widget.boxFill ?? widget.palette.fieldFill,
+                  idleBorderColor: widget.idleBorderColor,
                 ),
               ),
             ],
@@ -369,6 +390,8 @@ class _PasswordResetOtpFieldState extends State<PasswordResetOtpField> {
           child: TextField(
             controller: widget.controller,
             focusNode: _focusNode,
+            readOnly: widget.readOnly,
+            canRequestFocus: !widget.readOnly,
             keyboardType: TextInputType.number,
             textInputAction: TextInputAction.next,
             autocorrect: false,
@@ -402,25 +425,36 @@ class _OtpBox extends StatelessWidget {
     required this.palette,
     required this.digit,
     required this.active,
+    required this.height,
+    required this.fill,
+    required this.idleBorderColor,
   });
 
   final PasswordResetPalette palette;
   final String digit;
   final bool active;
+  final double height;
+  final Color fill;
+  final Color idleBorderColor;
 
   @override
   Widget build(BuildContext context) {
     return AnimatedContainer(
       duration: const Duration(milliseconds: 120),
-      height: 52,
+      height: height,
       alignment: Alignment.center,
       decoration: BoxDecoration(
-        color: palette.fieldFill,
+        color: fill,
         borderRadius: BorderRadius.circular(12),
-        border: Border.all(
-          color: active ? palette.focusedFieldLine : Colors.transparent,
-          width: 2,
-        ),
+        // En reposo, el transparente de siempre conserva el ancho de 2, así
+        // que las pantallas de hoy no se mueven ni un píxel. Un borde visible
+        // en reposo va de 1 (D13 de la recarga).
+        border: active
+            ? Border.all(color: palette.focusedFieldLine, width: 2)
+            : Border.all(
+                color: idleBorderColor,
+                width: idleBorderColor == Colors.transparent ? 2 : 1,
+              ),
       ),
       child: Text(
         digit,
```

- [ ] **Paso 4. La hoja.** Crea `lib/components/recarga_ulima/hoja_recarga_ulima.dart` con este
  contenido.

```dart
// lib/components/recarga_ulima/hoja_recarga_ulima.dart
//
// La hoja de recarga desde la ULima (RF-RCG-2 y RF-RCG-3 de
// specs/features/recarga-portal/recarga-portal.spec.md), con el formato del
// modal «Registrar Nota». La abren la franja de /mis-notas y el bloque de
// asistencia de la ficha del curso.

import 'package:flutter/material.dart';

import '../../configs/themes.dart';
import '../../pages/password_reset/password_reset_ui.dart';
import '../../pages/portal_sync/portal_sync_controller.dart'
    show validarFormulario;
import '../../services/auth_service.dart';
import '../../services/recarga_ulima_service.dart';

/// Abre la hoja y devuelve `true` si la recarga queda guardada. Un toque
/// fuera o un arrastre no la cierran (D4).
Future<bool> abrirHojaRecargaUlima(BuildContext context) async {
  final guardada = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (_) => const HojaRecargaUlima(),
  );
  return guardada ?? false;
}

class HojaRecargaUlima extends StatefulWidget {
  const HojaRecargaUlima({super.key});

  @override
  State<HojaRecargaUlima> createState() => _HojaRecargaUlimaState();
}

class _HojaRecargaUlimaState extends State<HojaRecargaUlima> {
  // La contraseña y el código viven solo en estos dos controllers, que se
  // vacían al cerrar de cualquier forma y antes de dispose().
  final TextEditingController _password = TextEditingController();
  final TextEditingController _passcode = TextEditingController();
  bool _verPassword = false;
  bool _esperando = false;

  @override
  void initState() {
    super.initState();
    _password.addListener(_refrescar);
    _passcode.addListener(_refrescar);
  }

  @override
  void dispose() {
    _password.removeListener(_refrescar);
    _passcode.removeListener(_refrescar);
    _vaciar();
    _password.dispose();
    _passcode.dispose();
    super.dispose();
  }

  void _refrescar() {
    if (mounted) setState(() {});
  }

  void _vaciar() {
    _password.clear();
    _passcode.clear();
  }

  /// El mismo criterio de `/portal-sync`, contraseña no vacía tras `trim()`
  /// y código con `^\d{6,8}$`.
  bool get _listo =>
      validarFormulario(password: _password.text, passcode: _passcode.text) ==
      null;

  void _cerrar() {
    _vaciar();
    Navigator.of(context).pop(false);
  }

  Future<void> _actualizar() async {
    if (!_listo || _esperando) return;
    setState(() => _esperando = true);
    // La contraseña viaja sin trim() y el código sin recortar a seis, igual
    // que en /portal-sync.
    final guardada = await RecargaUlimaService.to.recargar(
      password: _password.text,
      passcode: _passcode.text.trim(),
    );
    _vaciar();
    if (mounted) Navigator.of(context).pop(guardada);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tenue = colors.onSurface.withValues(alpha: 0.7);
    final borde = colors.onSurface.withValues(alpha: 0.5);
    final codigo = AuthService.to.currentUser?.code;
    final rotulo = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: colors.onSurface,
    );

    return PopScope(
      canPop: !_esperando,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _vaciar();
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            'Actualizar desde la ULima',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                        if (codigo != null)
                          Text.rich(
                            TextSpan(
                              text: 'Entras como ',
                              children: [
                                TextSpan(
                                  text: codigo,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurface,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    icon: Icon(Icons.close, color: colors.onSurface),
                    onPressed: _esperando ? null : _cerrar,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Al tocar «Actualizar» aceptas que ULima++ lea en miUlima tus '
                'notas parciales y tu asistencia. La contraseña y el código '
                'se usan una sola vez y no se guardan.',
                style: TextStyle(fontSize: 13, color: tenue),
              ),
              const SizedBox(height: 20),
              ExcludeSemantics(
                child: Text('Contraseña de miUlima', style: rotulo),
              ),
              const SizedBox(height: 8),
              Semantics(
                container: true,
                label: 'Contraseña de miUlima',
                child: TextField(
                  controller: _password,
                  obscureText: !_verPassword,
                  readOnly: _esperando,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: const [AutofillHints.password],
                  style: TextStyle(color: colors.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Tu contraseña del portal',
                    hintStyle: TextStyle(
                      color: colors.onSurface.withValues(alpha: 0.6),
                    ),
                    constraints: const BoxConstraints(minHeight: 52),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borde),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borde),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.primary, width: 2),
                    ),
                    suffixIcon: IconButton(
                      tooltip: _verPassword
                          ? 'Ocultar contraseña'
                          : 'Mostrar contraseña',
                      icon: Icon(
                        _verPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: tenue,
                      ),
                      onPressed: _esperando
                          ? null
                          : () => setState(() => _verPassword = !_verPassword),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ExcludeSemantics(
                child: Text('Código del autenticador', style: rotulo),
              ),
              const SizedBox(height: 8),
              Semantics(
                container: true,
                label: 'Código del autenticador, 6 dígitos',
                child: PasswordResetOtpField(
                  controller: _passcode,
                  palette: PasswordResetPalette.from(context),
                  boxHeight: 50,
                  boxFill: Colors.transparent,
                  idleBorderColor: borde,
                  readOnly: _esperando,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'El código de 6 dígitos que cambia cada 30 segundos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: tenue),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _esperando ? null : _cerrar,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: colors.onSurface,
                        side: BorderSide(
                          color: colors.outline.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _listo && !_esperando ? _actualizar : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: MaterialTheme.primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: colors.primary.withValues(
                          alpha: 0.3,
                        ),
                        disabledForegroundColor: colors.onSurface.withValues(
                          alpha: 0.38,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _esperando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Actualizar',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
              if (_esperando) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Center(
                    child: Text(
                      'Leyendo miUlima. Puede tardar hasta un minuto.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: tenue),
                    ),
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

- [ ] **Paso 5. Comprueba que pasa.**

```bash
"$DART" format lib/components/recarga_ulima test/HU37_jeff/hoja_recarga_test.dart
"$FLUTTER" test --no-pub test/HU37_jeff/hoja_recarga_test.dart test/HU20_jeff/otp_field_ime_test.dart test/HU33_jeff/registro_page_test.dart test/HU34_jeff/portal_sync_consent_test.dart
"$FLUTTER" analyze --no-pub lib/components/recarga_ulima lib/pages/password_reset/password_reset_ui.dart test/HU37_jeff
```

**Esperado.** El formato no cambia nada, pasan las 15 pruebas de la hoja y las tres pruebas que
usan hoy `PasswordResetOtpField` siguen en verde, y el análisis no encuentra avisos.

- [ ] **Paso 6. Suite completa en segundo plano.** Como en la Tarea 4. **Esperado.** Los mismos 6
  avisos y 1324 pruebas en verde.

- [ ] **Paso 7. Commit.**

```bash
git add lib/pages/password_reset/password_reset_ui.dart lib/components/recarga_ulima/hoja_recarga_ulima.dart test/HU37_jeff/hoja_recarga_test.dart
git commit -m "feat(recarga-portal): hoja de recarga con el formato de «Registrar Nota» y cuatro parámetros opcionales en PasswordResetOtpField (RF-RCG-2)"
```

---

### Tarea 6. `/mis-notas` con la franja y el aviso rojo

**Requisitos.** RF-RCG-6 completo (fuente, franja, tarjeta de curso, fila de evaluación, insignia
«Final», estados, flecha del AppBar y tirón hacia abajo), la forma del aviso de RF-RCG-4 con sus
acciones, la línea de lectura parcial de RF-RCG-3, B8, B9, B10, D9, D10 y D17.

**Archivos.**
- Crear `test/HU37_jeff/mis_notas_ulima_test.dart`.
- Crear `lib/components/recarga_ulima/aviso_recarga.dart`.
- Crear `lib/components/recarga_ulima/franja_recarga.dart`.
- Reescribir `lib/pages/mis_notas/mis_notas_controller.dart`.
- Reescribir `lib/pages/mis_notas/mis_notas_page.dart`.

**Interfaces.**
- Consume `RecargaUlimaService` y los avisos de la Tarea 4, `abrirHojaRecargaUlima` de la Tarea
  5, `formatoPeso` y `formatoNotaUlima`, `textoUltimaLectura` y `textoNotasLeidas` de la Tarea 2,
  `MaterialTheme.textoNaranja` de la Tarea 3, `EvaluationSyllabusService` y
  `notas_calculo.calcularPromedioPonderado`.
- Produce estas firmas.

```dart
// package:ulima_plus/components/recarga_ulima/aviso_recarga.dart
Future<bool> ejecutarAccionRecarga(BuildContext context, AvisoRecarga? aviso);
class AvisoRecargaTarjeta extends StatelessWidget {
  const AvisoRecargaTarjeta({Key? key, required AvisoRecarga aviso,
      required DateTime? ultimaLectura, required VoidCallback onAccion});
}
class AvisoRecargaCompacto extends StatelessWidget {
  const AvisoRecargaCompacto({Key? key, required AvisoRecarga aviso});
}
class BotonAccionRecarga extends StatelessWidget {
  const BotonAccionRecarga({Key? key, required String texto,
      required VoidCallback onPressed, IconData? icono});
}

// package:ulima_plus/components/recarga_ulima/franja_recarga.dart
const String textoSinLecturaUlima = 'Aún no se actualizan desde la ULima';
class FranjaRecarga extends StatelessWidget {
  const FranjaRecarga({Key? key, required DateTime? ultimaLectura, required VoidCallback onTap});
}

// package:ulima_plus/pages/mis_notas/mis_notas_controller.dart
MisNotasController({RecargaUlimaService? servicio, EvaluationSyllabusService? silabo});
```

- [ ] **Paso 1. Escribe la prueba que falla.** Crea `test/HU37_jeff/mis_notas_ulima_test.dart`
  con este contenido. Monta `/mis-notas` con una ruta falsa de `/portal-sync` que vuelve con el
  valor que pide cada caso.

```dart
// test/HU37_jeff/mis_notas_ulima_test.dart
//
// WIDGET · Recarga desde la ULima (specs/features/recarga-portal/
// recarga-portal.spec.md), RF-RCG-4 y RF-RCG-6, la pantalla «Notas
// oficiales» (/mis-notas) con las notas de la ULima, la franja y el aviso.
// Archivos probados lib/pages/mis_notas/**, lib/components/recarga_ulima/
// franja_recarga.dart y lib/components/recarga_ulima/aviso_recarga.dart.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/recarga_ulima/hoja_recarga_ulima.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/pages/mis_notas/mis_notas_controller.dart';
import 'package:ulima_plus/pages/mis_notas/mis_notas_page.dart';
import 'package:ulima_plus/services/evaluations_service.dart';
import 'package:ulima_plus/services/recarga_ulima_service.dart';

import 'recarga_dobles.dart';

const String _vistaGet = 'GET /grades/me/ulima';
const String _cursosGet = 'GET /grades/me/courses';
const String _refresh = 'POST /portal-sync/refresh';

/// El sílabo de la sección 81, con la sigla EV01 para la evaluación 5011.
Map<String, dynamic> _silaboJson() => <String, dynamic>{
  'cursos': <dynamic>[],
  'syllabi': [
    {
      'cursoId': '81',
      'cursoNombre': 'TALLER DE PROTOTIPADO',
      'evaluaciones': [
        {
          'id': '5011',
          'nombre': 'Examen escrito',
          'sigla': 'EV01',
          'peso': 15,
          'tipo': 'continua',
        },
        {
          'id': '5013',
          'nombre': 'Exposición',
          'sigla': 'EX01',
          'peso': 20,
          'tipo': 'continua',
        },
      ],
    },
  ],
};

/// Lo que devuelve `/portal-sync` en cada visita de la prueba.
Object? _salidaPortal = true;

Future<ApiRecargaFalsa> _abrir(
  WidgetTester tester, {
  ApiRecargaFalsa? api,
  Future<void> Function(RecargaUlimaService)? antes,
  bool silaboFalla = false,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  loguear(alumna());
  final falsa = api ?? (ApiRecargaFalsa()..responder(_vistaGet, vistaJson()));
  falsa.responder(
    _cursosGet,
    silaboFalla ? errorApi(500, 'HTTP_ERROR') : _silaboJson(),
  );
  final servicio = Get.put<RecargaUlimaService>(
    RecargaUlimaService(apiClient: falsa),
  );
  if (antes != null) await antes(servicio);
  await tester.pumpWidget(
    GetMaterialApp(
      theme: const MaterialTheme(TextTheme()).light(),
      initialRoute: '/mis-notas',
      getPages: [
        GetPage(
          name: '/mis-notas',
          page: () => const MisNotasPage(),
          binding: BindingsBuilder(() {
            Get.put(
              MisNotasController(
                silabo: EvaluationSyllabusService(apiClient: falsa),
              ),
            );
          }),
        ),
        GetPage(
          name: '/portal-sync',
          page: () => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Get.back<Object?>(result: _salidaPortal),
                child: const Text('VOLVER DEL PORTAL'),
              ),
            ),
          ),
        ),
      ],
    ),
  );
  await tester.pump();
  await tester.pump();
  return falsa;
}

/// Deja correr las animaciones sin esperar a un cursor o a un indicador.
Future<void> _asentar(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Map<String, dynamic> _conNotas() => vistaJson(
  courses: [
    cursoJson(
      assessments: [
        evaluacionJson(),
        evaluacionJson(
          key: '07.15',
          name: 'Exposición',
          week: 10,
          weight: 20,
          value: null,
          mark: 'np',
          assessmentId: 5013,
        ),
        evaluacionJson(
          key: '07.20',
          name: 'Trabajo final',
          week: null,
          weight: 12.5,
          value: null,
          mark: 'pending',
          assessmentId: null,
          match: 'none',
        ),
      ],
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.reset();
    _salidaPortal = true;
  });
  tearDown(Get.reset);

  group('WIDGET · estados de /mis-notas (RF-RCG-6)', () {
    testWidgets('primera carga, el esqueleto de hoy y sin franja', (
      tester,
    ) async {
      final pendiente = Completer<Map<String, dynamic>>();
      await _abrir(
        tester,
        api: ApiRecargaFalsa()..responder(_vistaGet, pendiente),
      );

      expect(find.text('Actualizar desde la ULima'), findsNothing);
      expect(find.text('Notas oficiales'), findsOneWidget);

      pendiente.complete(vistaJson());
      await tester.pump();
      expect(find.text('Actualizar desde la ULima'), findsOneWidget);
    });

    testWidgets(
      'error de carga sin datos, el vacío con wifi_off y sin franja',
      (tester) async {
        await _abrir(
          tester,
          api: ApiRecargaFalsa()
            ..responder(_vistaGet, errorApi(500, 'HTTP_ERROR')),
        );

        expect(find.byIcon(Icons.wifi_off), findsOneWidget);
        expect(
          find.text('No se pudieron cargar tus notas oficiales.'),
          findsOneWidget,
        );
        expect(find.text('Actualizar desde la ULima'), findsNothing);
      },
    );

    testWidgets('sin cursos, el vacío de hoy y sin franja', (tester) async {
      await _abrir(
        tester,
        api: ApiRecargaFalsa()
          ..responder(_vistaGet, vistaJson(lastReadAt: null, courses: [])),
      );

      expect(find.byIcon(Icons.school_outlined), findsOneWidget);
      expect(
        find.text('Aún no tienes cursos con notas oficiales.'),
        findsOneWidget,
      );
      expect(find.text('Actualizar desde la ULima'), findsNothing);
    });

    testWidgets('antes de la primera lectura, la franja y las tarjetas dicen '
        '«Aún no se actualizan desde la ULima» y no tienen filas', (
      tester,
    ) async {
      await _abrir(
        tester,
        api: ApiRecargaFalsa()
          ..responder(
            _vistaGet,
            vistaJson(
              lastReadAt: null,
              courses: [cursoJson(lastReadAt: null, assessments: [])],
            ),
          ),
      );

      expect(find.text('Actualizar desde la ULima'), findsOneWidget);
      expect(
        find.text('Aún no se actualizan desde la ULima'),
        findsNWidgets(2),
      );
      expect(find.text('Sección 812'), findsOneWidget);
      expect(find.text('Sin nota'), findsNothing);
      expect(find.text('Final'), findsNothing);
    });

    testWidgets('sin notas publicadas, la franja con la hora y las filas con '
        '«Sin nota», sin «Final»', (tester) async {
      await _abrir(
        tester,
        api: ApiRecargaFalsa()
          ..responder(
            _vistaGet,
            vistaJson(
              courses: [
                cursoJson(
                  assessments: [evaluacionJson(value: null, mark: 'pending')],
                ),
              ],
            ),
          ),
      );

      expect(find.text('Última lectura $lecturaDePrueba'), findsOneWidget);
      expect(find.text('Sin nota'), findsOneWidget);
      expect(find.text('Final'), findsNothing);
    });

    testWidgets('con notas, una graded, una np con NP, una pending sin semana '
        'y la insignia «Final»', (tester) async {
      await _abrir(
        tester,
        api: ApiRecargaFalsa()..responder(_vistaGet, _conNotas()),
      );

      expect(find.text('EV01 · Examen escrito 1'), findsOneWidget);
      expect(find.text('Semana 3'), findsOneWidget);
      expect(find.text('15%'), findsOneWidget);
      expect(find.text('14.5'), findsOneWidget);
      expect(find.text('EX01 · Exposición'), findsOneWidget);
      expect(find.text('Semana 10'), findsOneWidget);
      expect(find.text('NP'), findsOneWidget);
      // Sin pareja va sin sigla, sin semana, y se muestra igual (B7).
      expect(find.text('Trabajo final'), findsOneWidget);
      expect(find.text('12.5%'), findsOneWidget);
      expect(find.text('Sin nota'), findsOneWidget);
      // 14.5 · 15 / 100, con NP y la pendiente en 0.
      expect(find.text('Final'), findsOneWidget);
      expect(find.text('2.17'), findsOneWidget);
    });

    testWidgets('ninguna sigla si el sílabo no carga', (tester) async {
      await _abrir(
        tester,
        api: ApiRecargaFalsa()..responder(_vistaGet, _conNotas()),
        silaboFalla: true,
      );

      expect(find.text('Examen escrito 1'), findsOneWidget);
      expect(find.text('Exposición'), findsOneWidget);
      expect(find.textContaining('EV01'), findsNothing);
    });

    testWidgets('la insignia «Final» aprueba con 10.5 y desaprueba con 10.4', (
      tester,
    ) async {
      await _abrir(
        tester,
        api: ApiRecargaFalsa()
          ..responder(
            _vistaGet,
            vistaJson(
              courses: [
                cursoJson(
                  assessments: [evaluacionJson(weight: 100, value: 10.5)],
                ),
                cursoJson(
                  sectionId: 82,
                  sectionCode: '813',
                  courseName: 'CURSO DE PRUEBA B',
                  assessments: [evaluacionJson(weight: 100, value: 10.4)],
                ),
              ],
            ),
          ),
      );

      Color colorDe(String texto) =>
          tester.widget<Text>(find.text(texto)).style!.color!;
      expect(colorDe('10.50'), const Color(0xFF16A34A));
      expect(colorDe('10.40'), const Color(0xFFDC2626));
    });

    testWidgets('la franja lleva un Semantics de botón con su etiqueta, con y '
        'sin lectura', (tester) async {
      final semantica = tester.ensureSemantics();
      await _abrir(tester);

      expect(
        find.bySemanticsLabel(
          'Actualizar desde la ULima. Última lectura $lecturaDePrueba',
        ),
        findsWidgets,
      );
      semantica.dispose();
    });

    testWidgets('la franja abre la hoja de recarga', (tester) async {
      await _abrir(tester);

      await tester.tap(find.text('Actualizar desde la ULima'));
      await _asentar(tester);

      expect(find.byType(HojaRecargaUlima), findsOneWidget);
    });

    testWidgets('la flecha del AppBar llama solo a GET /grades/me/ulima y, sin '
        'conexión, conserva la vista', (tester) async {
      final api = ApiRecargaFalsa()
        ..responder(_vistaGet, vistaJson())
        ..responder(_vistaGet, errorApi(500, 'HTTP_ERROR'));
      await _abrir(tester, api: api);
      final antes = List<String>.of(api.llamadas);

      await tester.tap(find.byTooltip('Actualizar notas'));
      await tester.pump();
      await tester.pump();

      expect(api.llamadas.sublist(antes.length), [_vistaGet]);
      expect(api.veces(_refresh), 0);
      expect(find.text('TALLER DE PROTOTIPADO'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsNothing);
    });
  });

  group('WIDGET · lectura parcial y aviso rojo (RF-RCG-3 y RF-RCG-4)', () {
    testWidgets('una tarjeta sin lectura en el último resultado lleva «No se '
        'pudo leer en esta actualización.», también si nunca se leyó', (
      tester,
    ) async {
      final api = ApiRecargaFalsa()
        ..responder(
          _refresh,
          resultadoJson(
            view: vistaJson(
              courses: [
                cursoJson(),
                cursoJson(
                  sectionId: 82,
                  sectionCode: '813',
                  courseName: 'CURSO DE PRUEBA B',
                  lastReadAt: null,
                  assessments: [],
                ),
              ],
            ),
            courses: [
              {'sectionId': 81, 'attendance': 'updated', 'grades': 'read'},
              {'sectionId': 82, 'attendance': 'failed', 'grades': 'failed'},
            ],
          ),
        )
        ..responder(_vistaGet, errorApi(500, 'HTTP_ERROR'));
      await _abrir(
        tester,
        api: api,
        antes: (s) =>
            s.recargar(password: 'clave-de-prueba', passcode: '482913'),
      );

      expect(
        find.text('No se pudo leer en esta actualización.'),
        findsOneWidget,
      );
      // La franja sí lleva «Aún no…» solo si la vista no tiene hora; aquí
      // la tiene, así que no queda ningún «Aún no se actualizan».
      expect(find.text('Aún no se actualizan desde la ULima'), findsNothing);
    });

    testWidgets('el aviso de rechazo reemplaza a la franja, con la línea de la '
        'última lectura, «Reintentar» y la vista anterior debajo', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      final api = ApiRecargaFalsa()
        ..responder(_vistaGet, vistaJson())
        ..responder(_refresh, errorApi(409, 'PORTAL_LOGIN_REJECTED'));
      await _abrir(
        tester,
        api: api,
        antes: (s) async {
          await s.cargar();
          await s.recargar(password: 'clave-de-prueba', passcode: '482913');
        },
      );

      expect(find.text('Actualizar desde la ULima'), findsNothing);
      expect(find.text('No se pudo actualizar'), findsOneWidget);
      expect(
        find.text(
          'miUlima rechazó los datos. Revisa tu contraseña y que el '
          'código del autenticador siga vigente.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Se muestran las notas leídas $lecturaDePrueba.'),
        findsOneWidget,
      );
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text('TALLER DE PROTOTIPADO'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('No se pudo actualizar')),
        isSemantics(isLiveRegion: true),
      );
      semantica.dispose();
    });

    testWidgets('el de 403 lleva «Reintentar», que abre la hoja vacía', (
      tester,
    ) async {
      final api = ApiRecargaFalsa()
        ..responder(_vistaGet, vistaJson())
        ..responder(_refresh, errorApi(403, 'PORTAL_IDENTITY_MISMATCH'));
      await _abrir(
        tester,
        api: api,
        antes: (s) async {
          await s.cargar();
          await s.recargar(password: 'clave-de-prueba', passcode: '482913');
        },
      );

      expect(
        find.text(
          'La cuenta de miUlima no corresponde a tu usuario de '
          'ULima++.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Reintentar'));
      await _asentar(tester);

      expect(find.byType(HojaRecargaUlima), findsOneWidget);
      final contrasena = tester.widget<TextField>(
        find
            .descendant(
              of: find.byType(HojaRecargaUlima),
              matching: find.byType(TextField),
            )
            .first,
      );
      expect(contrasena.controller!.text, isEmpty);
      // El aviso sigue a la vista mientras la hoja está abierta.
      expect(find.text('No se pudo actualizar'), findsOneWidget);
    });

    for (final (salida, recarga) in <(Object?, bool)>[
      (true, true),
      (false, false),
      (null, false),
    ]) {
      testWidgets('el de IMPORT_REQUIRED lleva «Cargar mis datos», que borra '
          'el aviso, abre /portal-sync y, si vuelve $salida, '
          '${recarga ? 'sí' : 'no'} pide la vista', (tester) async {
        _salidaPortal = salida;
        final api = ApiRecargaFalsa()
          ..responder(_vistaGet, vistaJson())
          ..responder(_refresh, errorApi(409, 'IMPORT_REQUIRED'));
        await _abrir(
          tester,
          api: api,
          antes: (s) async {
            await s.cargar();
            await s.recargar(password: 'clave-de-prueba', passcode: '482913');
          },
        );
        expect(find.text('Primero carga tus datos del ciclo.'), findsOneWidget);
        final vistasAntes = api.veces(_vistaGet);

        await tester.tap(find.text('Cargar mis datos'));
        await _asentar(tester);
        expect(find.text('VOLVER DEL PORTAL'), findsOneWidget);
        expect(RecargaUlimaService.to.ultimoAviso, isNull);

        await tester.tap(find.text('VOLVER DEL PORTAL'));
        await _asentar(tester);

        expect(api.veces(_vistaGet), vistasAntes + (recarga ? 1 : 0));
        expect(find.text('Actualizar desde la ULima'), findsOneWidget);
      });
    }
  });
}
```

- [ ] **Paso 2. Comprueba que falla.**

```bash
"$FLUTTER" test --no-pub test/HU37_jeff/mis_notas_ulima_test.dart
```

**Esperado.** Falla al compilar porque `MisNotasController` no tiene el parámetro `silabo`.

- [ ] **Paso 3. El aviso.** Crea `lib/components/recarga_ulima/aviso_recarga.dart` con este
  contenido. `ejecutarAccionRecarga` lo usa también la ficha del curso en la Tarea 9.

```dart
// lib/components/recarga_ulima/aviso_recarga.dart
//
// El aviso rojo persistente de una recarga fallida (RF-RCG-4 de
// specs/features/recarga-portal/recarga-portal.spec.md), en su versión de
// tarjeta para /mis-notas y en su versión compacta para el bloque de
// asistencia (RF-RCG-8), y la acción de su botón.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../configs/themes.dart';
import '../../domain/recarga_ulima/avisos_recarga.dart';
import '../../domain/recarga_ulima/ultima_lectura.dart';
import '../../services/recarga_ulima_service.dart';
import 'hoja_recarga_ulima.dart';

/// Lo que hace el botón del aviso, o el de recarga si no hay aviso.
///
/// `Reintentar` abre otra vez la hoja, vacía. `Cargar mis datos` borra el
/// aviso, abre `/portal-sync`, espera su resultado y, si vuelve `true`, pide
/// otra vez la vista. Devuelve `true` solo si una recarga queda guardada.
Future<bool> ejecutarAccionRecarga(
  BuildContext context,
  AvisoRecarga? aviso,
) async {
  if (aviso?.accion == AccionAviso.cargarMisDatos) {
    final servicio = RecargaUlimaService.to;
    servicio.borrarAviso();
    final cargado = await Get.toNamed<dynamic>('/portal-sync');
    if (cargado == true) await servicio.cargar();
    return false;
  }
  return abrirHojaRecargaUlima(context);
}

/// El aviso en lugar de la franja de `/mis-notas`.
class AvisoRecargaTarjeta extends StatelessWidget {
  const AvisoRecargaTarjeta({
    super.key,
    required this.aviso,
    required this.ultimaLectura,
    required this.onAccion,
  });

  final AvisoRecarga aviso;

  /// La `lastReadAt` de la vista, o `null` si todavía no hay lectura.
  final DateTime? ultimaLectura;
  final VoidCallback onAccion;

  @override
  Widget build(BuildContext context) {
    final brillo = Theme.of(context).brightness;
    final secundario = TextStyle(
      fontSize: 11,
      color: MaterialTheme.textSecondary(brillo),
    );
    final lectura = ultimaLectura;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MaterialTheme.cardBg(brillo),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AvisoRecarga.titulo,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: MaterialTheme.textPrimary(brillo),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(aviso.cuerpo, style: secundario),
                  if (lectura != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      textoNotasLeidas(lectura, DateTime.now()),
                      style: secundario,
                    ),
                  ],
                  BotonAccionRecarga(
                    texto: aviso.textoAccion,
                    onPressed: onAccion,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// El aviso compacto del bloque de asistencia de la ficha (RF-RCG-8).
class AvisoRecargaCompacto extends StatelessWidget {
  const AvisoRecargaCompacto({super.key, required this.aviso});

  final AvisoRecarga aviso;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AvisoRecarga.titulo,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
                Text(
                  aviso.cuerpo,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
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

/// Botón de texto en el naranja de D11, con blanco táctil de 48.
class BotonAccionRecarga extends StatelessWidget {
  const BotonAccionRecarga({
    super.key,
    required this.texto,
    required this.onPressed,
    this.icono,
  });

  final String texto;
  final VoidCallback onPressed;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final brillo = Theme.of(context).brightness;
    final estilo = TextButton.styleFrom(
      foregroundColor: MaterialTheme.textoNaranja(brillo),
      minimumSize: const Size(48, 48),
      tapTargetSize: MaterialTapTargetSize.padded,
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
    );
    final icono = this.icono;
    if (icono == null) {
      return TextButton(
        onPressed: onPressed,
        style: estilo,
        child: Text(texto),
      );
    }
    return TextButton.icon(
      onPressed: onPressed,
      style: estilo,
      icon: Icon(icono, size: 18),
      label: Text(texto),
    );
  }
}
```

- [ ] **Paso 4. La franja.** Crea `lib/components/recarga_ulima/franja_recarga.dart` con este
  contenido.

```dart
// lib/components/recarga_ulima/franja_recarga.dart
//
// La franja «Actualizar desde la ULima» de /mis-notas (RF-RCG-6 de
// specs/features/recarga-portal/recarga-portal.spec.md), que copia la
// tarjeta «Actualizar desde miUlima» del Perfil y abre la hoja de recarga.

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../configs/themes.dart';
import '../../domain/recarga_ulima/ultima_lectura.dart';

/// Texto de lo que todavía no tiene lectura de la ULima.
const String textoSinLecturaUlima = 'Aún no se actualizan desde la ULima';

class FranjaRecarga extends StatelessWidget {
  const FranjaRecarga({
    super.key,
    required this.ultimaLectura,
    required this.onTap,
  });

  /// La `lastReadAt` de la vista, o `null` si todavía no hay lectura.
  final DateTime? ultimaLectura;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brillo = Theme.of(context).brightness;
    final lectura = ultimaLectura;
    final segunda = lectura == null
        ? textoSinLecturaUlima
        : textoUltimaLectura(lectura, DateTime.now());
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: MaterialTheme.borderColor(brillo)),
    );
    return Semantics(
      button: true,
      label: 'Actualizar desde la ULima. $segunda',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: MaterialTheme.cardBg(brillo),
        shape: forma,
        child: InkWell(
          onTap: onTap,
          customBorder: forma,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: MaterialTheme.espPrincipalBg(brillo),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    LucideIcons.refreshCw,
                    color: MaterialTheme.primaryDark,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Actualizar desde la ULima',
                        style: TextStyle(
                          color: MaterialTheme.textPrimary(brillo),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        segunda,
                        style: TextStyle(
                          color: MaterialTheme.textSecondary(brillo),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: MaterialTheme.textMuted(brillo),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Paso 5. El controller.** Reemplaza todo `lib/pages/mis_notas/mis_notas_controller.dart`
  por este contenido. `OfficialGradesService` no cambia y lo siguen usando las pantallas del
  docente.

```dart
import 'package:get/get.dart';

import '../../domain/notas/notas_calculo.dart' as notas_calculo;
import '../../domain/recarga_ulima/avisos_recarga.dart';
import '../../models/recarga_ulima_models.dart';
import '../../services/evaluations_service.dart';
import '../../services/recarga_ulima_service.dart';

/// Notas oficiales del alumno, las que publica la ULima (RF-RCG-6, decisión
/// B10). Lee `RecargaUlimaService`, que comparte su estado con la calculadora
/// y la ficha del curso. `OfficialGradesService` sigue en las pantallas del
/// docente.
class MisNotasController extends GetxController {
  MisNotasController({
    RecargaUlimaService? servicio,
    EvaluationSyllabusService? silabo,
  }) : _servicio = servicio ?? RecargaUlimaService.to,
       _silabo = silabo ?? EvaluationSyllabusService();

  final RecargaUlimaService _servicio;
  final EvaluationSyllabusService _silabo;

  final isLoading = false.obs;

  /// La sigla del sílabo de cada evaluación, por `assessmentId` (D9). Queda
  /// vacía si el sílabo no carga, y entonces las filas van sin prefijo.
  final siglas = <String, String>{}.obs;

  VistaUlima? get vista => _servicio.vista;
  AvisoRecarga? get aviso => _servicio.ultimoAviso;
  bool get errorCarga => _servicio.errorCarga;

  /// El último resultado no trae las notas de [curso] como leídas.
  bool sinLectura(CursoUlima curso) =>
      _servicio.sinLecturaDeNotas(curso.sectionId);

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// Consulta solo a ULima++, nunca entra a miUlima.
  Future<void> load() async {
    isLoading.value = true;
    try {
      await Future.wait([_servicio.cargar(), _cargarSiglas()]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _cargarSiglas() async {
    await _silabo.loadEvaluationData();
    if (!_silabo.isLoaded) {
      siglas.clear();
      return;
    }
    siglas.assignAll({
      for (final silabo in _silabo.allSyllabuses)
        for (final e in silabo.evaluaciones)
          if (e.sigla.isNotEmpty) e.id: e.sigla,
    });
  }

  /// `EV01 · Examen escrito 1` con pareja y sigla, o solo el nombre de la
  /// ULima (D9). Lee [siglas] de [conSiglas] para que el `Obx` que llama se
  /// suscriba.
  String titulo(EvaluacionUlima e, Map<String, String> conSiglas) {
    final sigla = e.tienePareja ? conSiglas['${e.assessmentId}'] : null;
    return sigla == null ? e.name : '$sigla · ${e.name}';
  }

  /// Nota final con lo ya publicado, con `NP` y las pendientes como 0
  /// (decisión B8).
  double notaFinal(CursoUlima curso) =>
      notas_calculo.calcularPromedioPonderado([
        for (final e in curso.evaluaciones)
          {'valor': e.value ?? 0, 'peso': e.weight},
      ]);

  /// La insignia «Final» sale solo con alguna nota o algún NP.
  bool tieneNotas(CursoUlima curso) =>
      curso.evaluaciones.any((e) => e.publicada);
}
```

- [ ] **Paso 6. La página.** Reemplaza todo `lib/pages/mis_notas/mis_notas_page.dart` por este
  contenido. El AppBar, el fondo, las tarjetas, `_FinalBadge` y `_Empty` son los de hoy, y las
  tarjetas se arman dentro del `Obx`.

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/recarga_ulima/aviso_recarga.dart';
import '../../components/recarga_ulima/franja_recarga.dart';
import '../../components/recarga_ulima/hoja_recarga_ulima.dart';
import '../../components/skeleton.dart';
import '../../configs/themes.dart';
import '../../domain/recarga_ulima/formato_nota.dart';
import '../../models/recarga_ulima_models.dart';
import 'mis_notas_controller.dart';

/// Texto de la tarjeta de un curso sin lectura en la última recarga.
const String textoLecturaParcial = 'No se pudo leer en esta actualización.';

/// Notas oficiales del alumno, las que publica la ULima (RF-RCG-6). Solo
/// lectura, con la franja que abre la hoja de recarga.
class MisNotasPage extends StatelessWidget {
  const MisNotasPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MisNotasController>();
    final brightness = Theme.brightnessOf(context);

    return Scaffold(
      backgroundColor: MaterialTheme.pageBg(brightness),
      appBar: AppBar(
        title: const Text('Notas oficiales'),
        // El botón de refrescar vuelve a consultar a ULima++, además del tirón
        // hacia abajo, y no entra a miUlima, que es lo que hace la franja.
        actions: [
          Obx(
            () => IconButton(
              icon: controller.isLoading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              tooltip: 'Actualizar notas',
              onPressed: controller.isLoading.value ? null : controller.load,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.load,
        color: MaterialTheme.primaryColor,
        child: Obx(() {
          final vista = controller.vista;
          final aviso = controller.aviso;
          final siglas = Map<String, String>.of(controller.siglas);

          if (vista == null) {
            if (controller.isLoading.value) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: SkeletonCardList(count: 4, showAvatar: false),
              );
            }
            if (controller.errorCarga) {
              return _fill(
                _Empty(
                  icon: Icons.wifi_off,
                  message: 'No se pudieron cargar tus notas oficiales.',
                  brightness: brightness,
                ),
              );
            }
          }
          if (vista == null || vista.cursos.isEmpty) {
            // Sin cursos no hay franja, porque una recarga responde
            // 409 IMPORT_REQUIRED.
            return _fill(
              _Empty(
                icon: Icons.school_outlined,
                message: 'Aún no tienes cursos con notas oficiales.',
                brightness: brightness,
              ),
            );
          }
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: aviso != null
                    ? AvisoRecargaTarjeta(
                        aviso: aviso,
                        ultimaLectura: vista.lastReadAt,
                        onAccion: () => ejecutarAccionRecarga(context, aviso),
                      )
                    : FranjaRecarga(
                        ultimaLectura: vista.lastReadAt,
                        onTap: () => abrirHojaRecargaUlima(context),
                      ),
              ),
              for (final curso in vista.cursos)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CourseCard(
                    curso: curso,
                    titulos: [
                      for (final e in curso.evaluaciones)
                        controller.titulo(e, siglas),
                    ],
                    notaFinal: controller.notaFinal(curso),
                    calificado: controller.tieneNotas(curso),
                    lineaEstado: controller.sinLectura(curso)
                        ? textoLecturaParcial
                        : (curso.lastReadAt == null &&
                              curso.evaluaciones.isEmpty)
                        ? textoSinLecturaUlima
                        : null,
                    brightness: brightness,
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _fill(Widget child) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [SizedBox(height: 400, child: Center(child: child))],
  );
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.curso,
    required this.titulos,
    required this.notaFinal,
    required this.calificado,
    required this.lineaEstado,
    required this.brightness,
  });

  final CursoUlima curso;

  /// El título de cada evaluación, en el orden de `curso.evaluaciones`.
  final List<String> titulos;
  final double notaFinal;
  final bool calificado;

  /// `Aún no se actualizan desde la ULima`, `No se pudo leer en esta
  /// actualización.` o nada.
  final String? lineaEstado;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final textPrimary = MaterialTheme.textPrimary(brightness);
    final textSecondary = MaterialTheme.textSecondary(brightness);
    final linea = lineaEstado;

    return Container(
      decoration: BoxDecoration(
        color: MaterialTheme.cardBg(brightness),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MaterialTheme.borderColor(brightness)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      curso.courseName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sección ${curso.sectionCode}',
                      style: TextStyle(fontSize: 13, color: textSecondary),
                    ),
                    if (linea != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        linea,
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              _FinalBadge(nota: notaFinal, calificado: calificado),
            ],
          ),
          if (curso.evaluaciones.isNotEmpty) const SizedBox(height: 12),
          for (var i = 0; i < curso.evaluaciones.length; i++)
            _AssessmentRow(
              evaluacion: curso.evaluaciones[i],
              titulo: titulos[i],
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
        ],
      ),
    );
  }
}

class _AssessmentRow extends StatelessWidget {
  const _AssessmentRow({
    required this.evaluacion,
    required this.titulo,
    required this.textPrimary,
    required this.textSecondary,
  });

  final EvaluacionUlima evaluacion;
  final String titulo;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final semana = evaluacion.week;
    final nota = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w800,
      color: textPrimary,
    );
    final valor = switch (evaluacion.mark) {
      MarcaUlima.graded => Text(
        formatoNotaUlima(evaluacion.value!),
        textAlign: TextAlign.right,
        style: nota,
      ),
      MarcaUlima.np => Text('NP', textAlign: TextAlign.right, style: nota),
      MarcaUlima.pending => Text(
        'Sin nota',
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textSecondary,
        ),
      ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(fontSize: 13, color: textPrimary),
                ),
                if (semana != null)
                  Text(
                    'Semana $semana',
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
              ],
            ),
          ),
          Text(
            formatoPeso(evaluacion.weight),
            style: TextStyle(fontSize: 12, color: textSecondary),
          ),
          const SizedBox(width: 14),
          SizedBox(width: 56, child: valor),
        ],
      ),
    );
  }
}

class _FinalBadge extends StatelessWidget {
  const _FinalBadge({required this.nota, required this.calificado});

  final double nota;
  final bool calificado;

  @override
  Widget build(BuildContext context) {
    if (!calificado) {
      return const SizedBox.shrink();
    }
    final aprobado = nota >= 10.5;
    final color = aprobado ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            'Final',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            nota.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.icon,
    required this.message,
    required this.brightness,
  });

  final IconData icon;
  final String message;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final textSecondary = MaterialTheme.textSecondary(brightness);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 48, color: textSecondary),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: textSecondary),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Paso 7. Comprueba que pasa.**

```bash
"$DART" format lib/components/recarga_ulima lib/pages/mis_notas/mis_notas_controller.dart lib/pages/mis_notas/mis_notas_page.dart test/HU37_jeff/mis_notas_ulima_test.dart
"$FLUTTER" test --no-pub test/HU37_jeff/mis_notas_ulima_test.dart
"$FLUTTER" analyze --no-pub lib/components/recarga_ulima lib/pages/mis_notas test/HU37_jeff
```

**Esperado.** El formato no cambia nada, pasan las 17 pruebas y el análisis no encuentra avisos.

- [ ] **Paso 8. Suite completa en segundo plano.** Como en la Tarea 4. **Esperado.** Los mismos 6
  avisos y 1341 pruebas en verde.

- [ ] **Paso 9. Commit.**

```bash
git add lib/components/recarga_ulima/aviso_recarga.dart lib/components/recarga_ulima/franja_recarga.dart lib/pages/mis_notas/mis_notas_controller.dart lib/pages/mis_notas/mis_notas_page.dart test/HU37_jeff/mis_notas_ulima_test.dart
git commit -m "feat(recarga-portal): /mis-notas lee las notas de la ULima, con la franja, el aviso rojo y la lectura parcial (RF-RCG-4 y RF-RCG-6)"
```

---

### Tarea 7. Reglas de las filas de la calculadora

**Requisitos.** De RF-RCG-7, «Qué entra», «Una evaluación con las dos notas», «Orden de las
filas», la traducción de la fila visible al índice de `eliminarNota`, «Qué cursos se ven» y la
condición de la línea de D15, con B6, B7, B8 y D7.

**Archivos.**
- Crear `test/HU37_jeff/filas_calculadora_test.dart`.
- Crear `lib/domain/recarga_ulima/filas_calculadora.dart`.

**Interfaces.**
- Consume los modelos de la Tarea 1.
- Produce, en `package:ulima_plus/domain/recarga_ulima/filas_calculadora.dart`, estas firmas.

```dart
const String claveNotasUlima = 'notasUlima';
const String claveUlimaSinPareja = 'ulimaSinPareja';
List<Map<String, dynamic>> notasUlimaDeCurso(CursoUlima? curso);
bool ulimaSinPareja(CursoUlima? curso);
bool mismasNotasUlima(Object? antes, List<Map<String, dynamic>> despues);
class FilaCalculadora {
  final bool deUlima; final String titulo; final num peso; final double? valor;
  final bool np; final String evaluacionId; final int? indiceSimulada;
  double get valorParaPromedio; // NP y null como 0
}
List<FilaCalculadora> filasVisibles({required List<Object?> simuladas,
    required List<Object?> ulima, List<String> ordenSilabo = const []});
List<Map<String, double>> notasParaPromedio(List<FilaCalculadora> filas);
bool tieneFilasVisibles(Map<dynamic, dynamic> curso);
Set<String> idsConNotaUlima(Map<dynamic, dynamic> curso);
```

- [ ] **Paso 1. Escribe la prueba que falla.** Crea `test/HU37_jeff/filas_calculadora_test.dart`
  con este contenido. La Tarea 8 le suma el grupo del guardado.

```dart
// test/HU37_jeff/filas_calculadora_test.dart
//
// UNITARIA · Recarga desde la ULima (specs/features/recarga-portal/
// recarga-portal.spec.md), RF-RCG-7, las filas de la calculadora.
// Archivo probado lib/domain/recarga_ulima/filas_calculadora.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/domain/recarga_ulima/filas_calculadora.dart';
import 'package:ulima_plus/models/recarga_ulima_models.dart';

import 'recarga_dobles.dart';

Map<String, dynamic> _simulada(String id, {int peso = 20, double valor = 16}) =>
    {
      'titulo': 'Simulada $id',
      'peso': peso,
      'valor': valor,
      'evaluacionId': id,
    };

CursoUlima _curso(List<Map<String, dynamic>> evaluaciones) =>
    CursoUlima.fromJson(cursoJson(assessments: evaluaciones));

void main() {
  group('UNITARIA · qué entra de la ULima (RF-RCG-7)', () {
    test(
      'entran graded y np con pareja, y no entran pending ni match none',
      () {
        final notas = notasUlimaDeCurso(
          _curso([
            evaluacionJson(assessmentId: 5011, value: 14.5),
            evaluacionJson(assessmentId: 5012, mark: 'np', value: null),
            evaluacionJson(assessmentId: 5013, mark: 'pending', value: null),
            evaluacionJson(assessmentId: null, match: 'none'),
          ]),
        );

        expect(notas.map((n) => n['evaluacionId']), ['5011', '5012']);
        expect(notas.first['titulo'], 'Examen escrito 1');
        expect(notas.first['peso'], 15);
        expect(notas.first['valor'], 14.5);
        expect(notas.last['np'], isTrue);
        expect(notasUlimaDeCurso(null), isEmpty);
      },
    );

    test('una evaluación sin pareja marca el curso para la línea de D15', () {
      expect(ulimaSinPareja(_curso([evaluacionJson()])), isFalse);
      expect(
        ulimaSinPareja(
          _curso([
            evaluacionJson(),
            evaluacionJson(assessmentId: null, match: 'none'),
          ]),
        ),
        isTrue,
      );
      expect(ulimaSinPareja(null), isFalse);
    });
  });

  group('UNITARIA · filas visibles (RF-RCG-7)', () {
    final ulima = notasUlimaDeCurso(
      _curso([
        evaluacionJson(assessmentId: 5011, value: 14.5),
        evaluacionJson(
          assessmentId: 5013,
          mark: 'np',
          value: null,
          weight: 12.5,
        ),
      ]),
    );

    test('una simulada y una de la ULima con el mismo assessmentId dan solo '
        'la de la ULima', () {
      final filas = filasVisibles(
        simuladas: [_simulada('5011'), _simulada('5012')],
        ulima: ulima,
      );

      expect(filas.where((f) => f.evaluacionId == '5011'), hasLength(1));
      expect(filas.firstWhere((f) => f.evaluacionId == '5011').deUlima, isTrue);
      expect(filas, hasLength(3));
    });

    test('np entra con valor 0 y con el peso exacto de la ULima', () {
      final filas = filasVisibles(simuladas: const [], ulima: ulima);
      final np = filas.firstWhere((f) => f.np);

      expect(np.valorParaPromedio, 0);
      expect(np.peso, 12.5);
      expect(notasParaPromedio(filas), [
        {'valor': 14.5, 'peso': 15.0},
        {'valor': 0.0, 'peso': 12.5},
      ]);
    });

    test('el orden sigue al sílabo, con las ajenas al final en su orden de '
        'hoy', () {
      final filas = filasVisibles(
        simuladas: [_simulada('9001'), _simulada('5012'), _simulada('9000')],
        ulima: ulima,
        ordenSilabo: ['5012', '5011', '5013'],
      );

      expect(filas.map((f) => f.evaluacionId), [
        '5012',
        '5011',
        '5013',
        '9001',
        '9000',
      ]);
    });

    test('la fila visible de una simulada se traduce a su índice en '
        "curso['notas'] por evaluacionId, con una de la ULima antes y una "
        'simulada oculta', () {
      final simuladas = [_simulada('5011'), _simulada('5012')];
      final filas = filasVisibles(
        simuladas: simuladas,
        ulima: ulima,
        ordenSilabo: ['5011', '5012', '5013'],
      );

      // La 5011 simulada queda oculta, y la 5012 es la segunda fila visible.
      expect(filas[1].evaluacionId, '5012');
      expect(filas[1].deUlima, isFalse);
      expect(filas[1].indiceSimulada, 1);
      expect(filas[0].indiceSimulada, isNull);
    });

    test(
      'la simulada oculta vuelve a verse si la ULima retira la nota (B6)',
      () {
        final simuladas = [_simulada('5011')];

        expect(
          filasVisibles(
            simuladas: simuladas,
            ulima: ulima,
          ).where((f) => !f.deUlima),
          isEmpty,
        );
        expect(
          filasVisibles(simuladas: simuladas, ulima: const []).single.deUlima,
          isFalse,
        );
      },
    );

    test('un curso sin la lista de la ULima, como los del doble de HU07, '
        'cuenta solo sus simuladas', () {
      expect(tieneFilasVisibles({'notas': <Object?>[]}), isFalse);
      expect(
        tieneFilasVisibles({
          'notas': [_simulada('5011')],
        }),
        isTrue,
      );
      expect(
        tieneFilasVisibles({'notas': <Object?>[], claveNotasUlima: ulima}),
        isTrue,
      );
      expect(idsConNotaUlima({'notas': <Object?>[]}), isEmpty);
      expect(idsConNotaUlima({claveNotasUlima: ulima}), {'5011', '5013'});
    });

    test('mismasNotasUlima compara campo por campo', () {
      expect(mismasNotasUlima(null, const []), isTrue);
      expect(
        mismasNotasUlima(
          ulima,
          notasUlimaDeCurso(
            _curso([
              evaluacionJson(assessmentId: 5011, value: 14.5),
              evaluacionJson(
                assessmentId: 5013,
                mark: 'np',
                value: null,
                weight: 12.5,
              ),
            ]),
          ),
        ),
        isTrue,
      );
      expect(mismasNotasUlima(ulima, const []), isFalse);
    });
  });
}
```

- [ ] **Paso 2. Comprueba que falla.**

```bash
"$FLUTTER" test --no-pub test/HU37_jeff/filas_calculadora_test.dart
```

**Esperado.** Falla al compilar porque no existe `filas_calculadora.dart`.

- [ ] **Paso 3. Implementa las reglas.** Crea `lib/domain/recarga_ulima/filas_calculadora.dart`
  con este contenido.

```dart
// lib/domain/recarga_ulima/filas_calculadora.dart
//
// Las filas de la calculadora cuando la ULima ya publica notas (RF-RCG-7 de
// specs/features/recarga-portal/recarga-portal.spec.md). Las simuladas viven
// en `curso['notas']` y las de la ULima en una lista aparte, bajo
// [claveNotasUlima], así que el guardado nunca las mezcla.

import '../../models/recarga_ulima_models.dart';

/// Clave del curso de la calculadora con sus filas de la ULima.
const String claveNotasUlima = 'notasUlima';

/// Clave del curso de la calculadora que dice si la ULima publica alguna
/// evaluación sin pareja en el sílabo (D15).
const String claveUlimaSinPareja = 'ulimaSinPareja';

/// Las filas de la ULima que entran a la calculadora, las que tienen nota o
/// NP y pareja en el sílabo. Las pendientes siguen disponibles para simular y
/// las que no tienen pareja se ven solo en `/mis-notas` (decisión B7).
List<Map<String, dynamic>> notasUlimaDeCurso(CursoUlima? curso) => [
  if (curso != null)
    for (final e in curso.evaluaciones)
      if (e.publicada && e.tienePareja)
        {
          'titulo': e.name,
          'peso': e.weight,
          'valor': e.value,
          'np': e.mark == MarcaUlima.np,
          'evaluacionId': '${e.assessmentId}',
        },
];

/// Si la ULima publica alguna evaluación del curso sin pareja en el sílabo.
bool ulimaSinPareja(CursoUlima? curso) =>
    curso?.evaluaciones.any((e) => !e.tienePareja) ?? false;

const List<String> _camposUlima = [
  'titulo',
  'peso',
  'valor',
  'np',
  'evaluacionId',
];

/// Si [antes], lo que tiene el curso, ya es igual a [despues]. Evita pedir
/// otra vez el promedio de un curso que no cambia.
bool mismasNotasUlima(Object? antes, List<Map<String, dynamic>> despues) {
  final lista = antes is List ? antes : const <Object?>[];
  if (lista.length != despues.length) return false;
  for (var i = 0; i < lista.length; i++) {
    final a = lista[i];
    if (a is! Map) return false;
    for (final campo in _camposUlima) {
      if (a[campo] != despues[i][campo]) return false;
    }
  }
  return true;
}

/// Una fila visible de la calculadora, simulada o de la ULima.
class FilaCalculadora {
  const FilaCalculadora({
    required this.deUlima,
    required this.titulo,
    required this.peso,
    required this.valor,
    required this.np,
    required this.evaluacionId,
    this.indiceSimulada,
  });

  final bool deUlima;
  final String titulo;
  final num peso;

  /// `null` solo con [np].
  final double? valor;
  final bool np;
  final String evaluacionId;

  /// La posición de la simulada en `curso['notas']`, que es la que pide
  /// `eliminarNota`. `null` en una fila de la ULima.
  final int? indiceSimulada;

  /// `NP` cuenta como 0 (decisión B8).
  double get valorParaPromedio => np ? 0 : (valor ?? 0);
}

String _id(Object? nota) => nota is Map ? '${nota['evaluacionId']}' : '';

/// Las filas visibles de un curso (RF-RCG-7).
///
/// Una simulada con el mismo `evaluacionId` que una de la ULima no se ve,
/// pero sigue en [simuladas] y vuelve si la ULima retira la nota (decisión
/// B6). El orden es el de [ordenSilabo], con las que no están en el sílabo al
/// final, primero las de la ULima y después las simuladas en su orden de hoy
/// (D7).
List<FilaCalculadora> filasVisibles({
  required List<Object?> simuladas,
  required List<Object?> ulima,
  List<String> ordenSilabo = const [],
}) {
  final idsUlima = {for (final u in ulima) _id(u)};
  final filas = <FilaCalculadora>[
    for (final u in ulima.whereType<Map>())
      FilaCalculadora(
        deUlima: true,
        titulo: '${u['titulo']}',
        peso: (u['peso'] as num?) ?? 0,
        valor: (u['valor'] as num?)?.toDouble(),
        np: u['np'] == true,
        evaluacionId: _id(u),
      ),
    for (final s in simuladas.whereType<Map>())
      if (!idsUlima.contains(_id(s)))
        FilaCalculadora(
          deUlima: false,
          titulo: '${s['titulo']}',
          peso: (s['peso'] as num?) ?? 0,
          valor: (s['valor'] as num?)?.toDouble() ?? 0,
          np: false,
          evaluacionId: _id(s),
          indiceSimulada: simuladas.indexWhere((n) => _id(n) == _id(s)),
        ),
  ];
  final posicion = {
    for (var i = 0; i < ordenSilabo.length; i++) ordenSilabo[i]: i,
  };
  final conOrden = filas.asMap().entries.toList()
    ..sort((a, b) {
      final pa = posicion[a.value.evaluacionId] ?? ordenSilabo.length;
      final pb = posicion[b.value.evaluacionId] ?? ordenSilabo.length;
      return pa != pb ? pa.compareTo(pb) : a.key.compareTo(b.key);
    });
  return [for (final e in conOrden) e.value];
}

/// Lo que recibe `POST /grades/me/calculate`, con el peso exacto de la ULima
/// y `NP` como 0.
List<Map<String, double>> notasParaPromedio(List<FilaCalculadora> filas) => [
  for (final f in filas)
    {'valor': f.valorParaPromedio, 'peso': f.peso.toDouble()},
];

/// Si el curso tiene alguna fila visible, simulada o de la ULima. Un curso
/// sin la lista de la ULima, como los que arma el doble de HU07, cuenta solo
/// sus simuladas.
bool tieneFilasVisibles(Map<dynamic, dynamic> curso) =>
    ((curso['notas'] as List?)?.isNotEmpty ?? false) ||
    ((curso[claveNotasUlima] as List?)?.isNotEmpty ?? false);

/// Los `evaluacionId` con una fila de la ULima visible en el curso.
Set<String> idsConNotaUlima(Map<dynamic, dynamic> curso) => {
  for (final u in (curso[claveNotasUlima] as List?) ?? const <Object?>[])
    _id(u),
};
```

- [ ] **Paso 4. Comprueba que pasa.**

```bash
"$DART" format lib/domain/recarga_ulima/filas_calculadora.dart test/HU37_jeff/filas_calculadora_test.dart
"$FLUTTER" test --no-pub test/HU37_jeff/filas_calculadora_test.dart
"$FLUTTER" analyze --no-pub lib/domain/recarga_ulima test/HU37_jeff
```

**Esperado.** El formato no cambia nada, pasan las 9 pruebas y el análisis no encuentra avisos.

- [ ] **Paso 5. Commit.**

```bash
git add lib/domain/recarga_ulima/filas_calculadora.dart test/HU37_jeff/filas_calculadora_test.dart
git commit -m "feat(recarga-portal): reglas puras de las filas de la calculadora con las notas de la ULima (RF-RCG-7)"
```

---

### Tarea 8. La calculadora con la fila «Notas oficiales» y las notas de la ULima

**Requisitos.** RF-RCG-5 completo y RF-RCG-7 en la pantalla («Cómo se ven», «API de `NotaTile`»,
«Promedio y suma de pesos», «Guardar y borrar», «Registrar Nota», «Qué cursos se ven», «Sílabo que
no coincide» y «Cuándo se carga y se recalcula»), D8, D10, D15, D24 y la parte de la calculadora de
«Qué no cambia de la calculadora». `recargarTodo()` queda lista para la Tarea 10.

**Archivos.**
- Crear `test/HU37_jeff/calculadora_ulima_test.dart`.
- Modificar `test/HU37_jeff/filas_calculadora_test.dart` (grupo del guardado).
- Reescribir `lib/components/calculadora/nota_tile.dart`.
- Modificar `lib/components/calculadora/curso_card.dart`.
- Crear `lib/components/recarga_ulima/fila_notas_oficiales.dart`.
- Modificar `lib/pages/calculadora/calculadora_controller.dart`.
- Modificar `lib/pages/calculadora/calculadora_page.dart`.

**Interfaces.**
- Consume las reglas de la Tarea 7, `RecargaUlimaService.vista`, `cargar` y `alCambiarVista` de
  la Tarea 4, `textoSinLecturaUlima` de la Tarea 6, el formato y la hora de la Tarea 2 y los
  tokens de la Tarea 3.
- Produce estas firmas.

```dart
// package:ulima_plus/components/calculadora/nota_tile.dart
const NotaTile({Key? key, required String titulo, required num peso, required double? nota,
    bool np = false, bool deUlima = false, VoidCallback? onDelete}); // onDelete obligatorio sin deUlima

// package:ulima_plus/components/calculadora/curso_card.dart
const CursoCard({..., required Function(int, int) onDeleteNota, List<String> ordenSilabo = const []});

// package:ulima_plus/components/recarga_ulima/fila_notas_oficiales.dart
const FilaNotasOficiales({Key? key, required bool hayVista, required DateTime? ultimaLectura,
    required VoidCallback onTap});

// package:ulima_plus/pages/calculadora/calculadora_controller.dart
CalculadoraController({ApiClient? apiClient});
final RxBool hayVistaUlima;
final Rxn<DateTime> ultimaLecturaUlima;
void conectarUlima();
void aplicarVistaUlima({bool recalcular = true});
Future<void> recargarTodo();
Future<void> eliminarNota(int cursoIndex, int notaIndex); // firma de hoy, sin cambios
```

- [ ] **Paso 1. Escribe las pruebas que fallan.** Crea `test/HU37_jeff/calculadora_ulima_test.dart`
  con este contenido. Su doble arma un curso y el sílabo como el de HU07, pero conserva el
  `ApiClient` falso y llama a `conectarUlima()`.

```dart
// test/HU37_jeff/calculadora_ulima_test.dart
//
// WIDGET · Recarga desde la ULima (specs/features/recarga-portal/
// recarga-portal.spec.md), RF-RCG-5 y RF-RCG-7, la fila «Notas oficiales» y
// las notas de la ULima dentro de la calculadora.
// Archivos probados lib/pages/calculadora/**, lib/components/calculadora/**
// y lib/components/recarga_ulima/fila_notas_oficiales.dart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/calculadora/nota_tile.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/evaluation_model.dart';
import 'package:ulima_plus/pages/calculadora/calculadora_controller.dart';
import 'package:ulima_plus/pages/calculadora/calculadora_page.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/recarga_ulima_service.dart';

import 'recarga_dobles.dart';

const String _vistaGet = 'GET /grades/me/ulima';

EvaluationComponent _ev(String id, String nombre, String sigla, double peso) =>
    EvaluationComponent(
      id: id,
      nombre: nombre,
      sigla: sigla,
      peso: peso,
      tipo: 'continua',
    );

/// La calculadora con un curso sembrado, sin la carga remota de cursos y
/// sílabo, pero con el ApiClient falso y la conexión real a la ULima.
class _CalculadoraDePrueba extends CalculadoraController {
  _CalculadoraDePrueba({
    required ApiClient api,
    this.simuladas = const [],
    this.conCurso = true,
    this.errorCursos = false,
  }) : super(apiClient: api);

  final List<Map<String, dynamic>> simuladas;
  final bool conCurso;
  final bool errorCursos;
  final List<(int, int)> borradas = [];

  @override
  // ignore: must_call_super
  void onInit() {
    if (errorCursos) {
      cargaError.value = true;
    } else if (conCurso) {
      cursos.add({
        'id': '81',
        'nombre': 'TALLER DE PROTOTIPADO',
        'ciclo': '2026-2',
        'codigoSeccion': '812',
        'notas': <Map<String, dynamic>>[...simuladas].obs,
        '_promedio': 0.0,
        '_sumaPesos': 0.0,
      });
    }
    syllabusData['81'] = CourseSyllabus(
      cursoId: '81',
      cursoNombre: 'TALLER DE PROTOTIPADO',
      evaluaciones: [
        _ev('5011', 'Examen escrito', 'EV01', 15),
        _ev('5012', 'Práctica', 'PC01', 25),
        _ev('5013', 'Exposición', 'EX01', 20),
      ],
    );
    conectarUlima();
  }

  @override
  Future<void> eliminarNota(int cursoIndex, int notaIndex) async {
    borradas.add((cursoIndex, notaIndex));
  }
}

Map<String, dynamic> _simulada(String id, String titulo, int peso, double v) =>
    {'titulo': titulo, 'peso': peso, 'valor': v, 'evaluacionId': id};

/// Monta la calculadora. Sin [vista], no registra el servicio de la ULima.
Future<(_CalculadoraDePrueba, ApiRecargaFalsa)> _montar(
  WidgetTester tester, {
  Object? vista,
  bool conServicio = true,
  List<Map<String, dynamic>> simuladas = const [],
  bool conCurso = true,
  bool errorCursos = false,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  loguear(alumna());
  final api = ApiRecargaFalsa(calcularPromedio: true);
  if (vista != null) api.responder(_vistaGet, vista);
  if (conServicio) {
    Get.put<RecargaUlimaService>(RecargaUlimaService(apiClient: api));
  }
  final c =
      Get.put<CalculadoraController>(
            _CalculadoraDePrueba(
              api: api,
              simuladas: simuladas,
              conCurso: conCurso,
              errorCursos: errorCursos,
            ),
          )
          as _CalculadoraDePrueba;
  await tester.pumpWidget(
    GetMaterialApp(
      theme: const MaterialTheme(TextTheme()).light(),
      home: const CalculadoraPage(),
      getPages: [
        GetPage(
          name: '/mis-notas',
          page: () => const Scaffold(body: Text('PANTALLA DE NOTAS OFICIALES')),
        ),
      ],
    ),
  );
  await tester.pump();
  await tester.pump();
  return (c, api);
}

Map<String, dynamic> _vistaCon(
  List<Map<String, dynamic>> evaluaciones, {
  Object? lastReadAt = '2025-09-22T15:42:10.000Z',
}) => vistaJson(
  lastReadAt: lastReadAt,
  courses: [cursoJson(lastReadAt: lastReadAt, assessments: evaluaciones)],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  group('WIDGET · la fila «Notas oficiales» (RF-RCG-5)', () {
    testWidgets('el birrete ya no está y la fila va bajo «Cursos con notas»', (
      tester,
    ) async {
      await _montar(tester, vista: vistaJson());

      expect(find.byTooltip('Notas oficiales'), findsNothing);
      expect(
        find.widgetWithIcon(IconButton, Icons.school_outlined),
        findsNothing,
      );
      expect(find.text('Notas oficiales'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Notas oficiales')).dy,
        greaterThan(
          tester.getTopLeft(find.textContaining('Cursos con notas')).dy,
        ),
      );
    });

    testWidgets('con lectura, «Última lectura …», y su Semantics de botón', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await _montar(tester, vista: vistaJson());

      expect(find.text('Última lectura $lecturaDePrueba'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Notas oficiales. Última lectura $lecturaDePrueba',
        ),
        findsWidgets,
      );
      semantica.dispose();
    });

    testWidgets('sin lectura, «Aún no se actualizan desde la ULima»', (
      tester,
    ) async {
      await _montar(tester, vista: vistaJson(lastReadAt: null));

      expect(find.text('Aún no se actualizan desde la ULima'), findsOneWidget);
    });

    testWidgets('sin vista, porque la carga falló o no hay servicio, solo el '
        'título', (tester) async {
      await _montar(tester, vista: errorApi(500, 'HTTP_ERROR'));
      expect(find.text('Notas oficiales'), findsOneWidget);
      expect(find.textContaining('Última lectura'), findsNothing);
      expect(find.text('Aún no se actualizan desde la ULima'), findsNothing);
    });

    testWidgets('sin el servicio registrado la fila también está, con solo el '
        'título', (tester) async {
      await _montar(tester, conServicio: false);

      expect(find.text('Notas oficiales'), findsOneWidget);
      expect(find.textContaining('Última lectura'), findsNothing);
    });

    testWidgets('con una vista previa y errorCarga en verdadero, la fila '
        'conserva la hora', (tester) async {
      final (_, api) = await _montar(tester, vista: vistaJson());
      api.responder(_vistaGet, errorApi(500, 'HTTP_ERROR'));

      await RecargaUlimaService.to.cargar();
      await tester.pump();

      expect(RecargaUlimaService.to.errorCarga, isTrue);
      expect(find.text('Última lectura $lecturaDePrueba'), findsOneWidget);
    });

    for (final (estado, conCurso, errorCursos) in <(String, bool, bool)>[
      ('con notas', true, false),
      ('sin notas', false, false),
      ('con el error de cursos', false, true),
    ]) {
      testWidgets('en el estado $estado, la fila lleva a /mis-notas', (
        tester,
      ) async {
        await _montar(
          tester,
          vista: vistaJson(),
          conCurso: conCurso,
          errorCursos: errorCursos,
        );

        await tester.tap(find.text('Notas oficiales'));
        await tester.pumpAndSettle();

        expect(find.text('PANTALLA DE NOTAS OFICIALES'), findsOneWidget);
      });
    }
  });

  group('WIDGET · las notas de la ULima en la calculadora (RF-RCG-7)', () {
    testWidgets(
      'una fila de la ULima lleva la marca «ULima», sin tacho, con su '
      'Semantics',
      (tester) async {
        final semantica = tester.ensureSemantics();
        await _montar(tester, vista: _vistaCon([evaluacionJson(value: 15)]));

        expect(find.text('Examen escrito 1'), findsOneWidget);
        expect(find.text('ULima'), findsOneWidget);
        expect(find.byIcon(Icons.delete_outline), findsNothing);
        expect(
          find.bySemanticsLabel(
            'Examen escrito 1, peso 15 por ciento, nota '
            '15.0 de 20, publicada por la ULima',
          ),
          findsWidgets,
        );
        semantica.dispose();
      },
    );

    testWidgets('un curso solo con notas de la ULima aparece y cuenta en '
        '«Cursos con notas»', (tester) async {
      await _montar(tester, vista: _vistaCon([evaluacionJson(value: 15)]));

      expect(find.text('Cursos con notas: 1'), findsOneWidget);
      expect(find.text('TALLER DE PROTOTIPADO'), findsOneWidget);
      expect(find.text('No hay notas registradas'), findsNothing);
    });

    testWidgets('el promedio y la suma de pesos cuentan las dos clases de '
        'filas, con NP como 0', (tester) async {
      final (_, api) = await _montar(
        tester,
        vista: _vistaCon([
          evaluacionJson(assessmentId: 5011, value: 14, weight: 15),
          evaluacionJson(
            assessmentId: 5013,
            mark: 'np',
            value: null,
            weight: 20,
          ),
        ]),
        simuladas: [_simulada('5012', 'Práctica', 25, 16)],
      );

      expect(api.cuerposDe('/grades/me/calculate').last, {
        'notas': [
          {'valor': 14.0, 'peso': 15.0},
          {'valor': 0.0, 'peso': 20.0},
          {'valor': 16.0, 'peso': 25.0},
        ],
      });
      // 14 · 0.15 + 16 · 0.25 = 6.10, con 15 + 20 + 25 de pesos.
      expect(find.text('6.10'), findsOneWidget);
      expect(find.text('Suma de pesos: 60.0% / 100%'), findsOneWidget);
      expect(
        find.textContaining('Peso: 20%  •  Nota: NP', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Peso: 15%  •  Nota: 14.0/20', findRichText: true),
        findsOneWidget,
      );
    });

    for (final (valor, desaprobado) in <(double, bool)>[
      (10.9, true),
      (11, false),
    ]) {
      testWidgets('con promedio $valor ${desaprobado ? '' : 'no '}se ve '
          '«Desaprobado», como hoy', (tester) async {
        await _montar(
          tester,
          vista: _vistaCon([evaluacionJson(value: valor, weight: 100)]),
        );

        expect(
          find.textContaining('Desaprobado'),
          desaprobado ? findsOneWidget : findsNothing,
        );
      });
    }

    testWidgets('el orden de las filas sigue al sílabo', (tester) async {
      await _montar(
        tester,
        vista: _vistaCon([evaluacionJson(assessmentId: 5012, value: 15)]),
        simuladas: [
          _simulada('5013', 'Exposición', 20, 12),
          _simulada('5011', 'Examen escrito', 15, 13),
        ],
      );

      final titulos = tester
          .widgetList<NotaTile>(find.byType(NotaTile))
          .map((t) => t.titulo)
          .toList();
      expect(titulos, ['Examen escrito', 'Examen escrito 1', 'Exposición']);
    });

    testWidgets('el tacho de una simulada que sigue a una fila de la ULima '
        "llama a eliminarNota con su índice en curso['notas']", (tester) async {
      final (c, _) = await _montar(
        tester,
        vista: _vistaCon([evaluacionJson(assessmentId: 5011, value: 15)]),
        simuladas: [
          _simulada('5011', 'Examen escrito', 15, 13),
          _simulada('5012', 'Práctica', 25, 16),
        ],
      );

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(c.borradas, [(0, 1)]);
    });

    testWidgets('«Registrar Nota» no ofrece una evaluación ya publicada', (
      tester,
    ) async {
      final (c, _) = await _montar(
        tester,
        vista: _vistaCon([evaluacionJson(assessmentId: 5011, value: 15)]),
      );

      expect(c.getAvailableEvaluations(0).map((e) => e.id), ['5012', '5013']);
    });

    testWidgets('POST /grades/me/notes nunca lleva una nota de la ULima', (
      tester,
    ) async {
      final (c, api) = await _montar(
        tester,
        vista: _vistaCon([evaluacionJson(assessmentId: 5011, value: 15)]),
      );

      c.agregarNota(0, 'Práctica', 25, 16, '5012');
      await tester.pump();

      expect(api.cuerposDe('/grades/me/notes').single, {
        'cursos': [
          {
            'sectionId': 81,
            'notas': [
              {'assessmentId': 5012, 'valor': 16.0},
            ],
          },
        ],
      });
    });

    testWidgets('la línea del sílabo que no coincide', (tester) async {
      await _montar(
        tester,
        vista: _vistaCon([
          evaluacionJson(value: 15),
          evaluacionJson(
            key: '07.30',
            name: 'Examen extra',
            assessmentId: null,
            match: 'none',
          ),
        ]),
      );

      expect(
        find.text(
          'La ULima publica evaluaciones que no están en el sílabo '
          'cargado. Míralas en Notas oficiales.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.text('Examen extra'), findsNothing);
    });

    testWidgets('una vista nueva rehace las filas y la simulada oculta vuelve '
        'si la ULima retira la nota (B6)', (tester) async {
      final (_, api) = await _montar(
        tester,
        vista: _vistaCon([evaluacionJson(assessmentId: 5011, value: 15)]),
        simuladas: [_simulada('5011', 'Examen escrito', 15, 13)],
      );
      expect(find.text('ULima'), findsOneWidget);
      api.responder(_vistaGet, _vistaCon(const []));

      await RecargaUlimaService.to.cargar();
      await tester.pump();

      expect(find.text('ULima'), findsNothing);
      expect(find.text('Examen escrito'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });
  });
}
```

Aplica este cambio a `test/HU37_jeff/filas_calculadora_test.dart`, que suma el grupo del
guardado.

```diff
diff --git a/test/HU37_jeff/filas_calculadora_test.dart b/test/HU37_jeff/filas_calculadora_test.dart
--- a/test/HU37_jeff/filas_calculadora_test.dart
+++ b/test/HU37_jeff/filas_calculadora_test.dart
@@ -2,11 +2,14 @@
 //
 // UNITARIA · Recarga desde la ULima (specs/features/recarga-portal/
 // recarga-portal.spec.md), RF-RCG-7, las filas de la calculadora.
-// Archivo probado lib/domain/recarga_ulima/filas_calculadora.dart.
+// Archivos probados lib/domain/recarga_ulima/filas_calculadora.dart y el
+// guardado de lib/pages/calculadora/calculadora_controller.dart.
 
 import 'package:flutter_test/flutter_test.dart';
+import 'package:get/get.dart';
 import 'package:ulima_plus/domain/recarga_ulima/filas_calculadora.dart';
 import 'package:ulima_plus/models/recarga_ulima_models.dart';
+import 'package:ulima_plus/pages/calculadora/calculadora_controller.dart';
 
 import 'recarga_dobles.dart';
 
@@ -188,4 +191,54 @@ void main() {
       expect(mismasNotasUlima(ulima, const []), isFalse);
     });
   });
+
+  group('UNITARIA · el guardado de la calculadora (RF-RCG-7)', () {
+    setUp(() {
+      Get.testMode = true;
+      Get.reset();
+      loguear(alumna());
+    });
+    tearDown(Get.reset);
+
+    test('las filas que se guardan son solo las simuladas, también las '
+        'ocultas', () async {
+      final api = ApiRecargaFalsa(calcularPromedio: true);
+      final c = CalculadoraController(apiClient: api);
+      c.cursos.add({
+        'id': '81',
+        'nombre': 'TALLER DE PROTOTIPADO',
+        'ciclo': '2026-2',
+        'codigoSeccion': '812',
+        'notas': <Map<String, dynamic>>[_simulada('5011')].obs,
+        claveNotasUlima: notasUlimaDeCurso(
+          _curso([evaluacionJson(assessmentId: 5011, value: 14.5)]),
+        ),
+        '_promedio': 0.0,
+        '_sumaPesos': 0.0,
+      });
+
+      c.agregarNota(0, 'Práctica', 25, 16, '5012');
+      await Future<void>.delayed(Duration.zero);
+
+      final guardado = api.cuerposDe('/grades/me/notes').single;
+      expect(guardado, {
+        'cursos': [
+          {
+            'sectionId': 81,
+            'notas': [
+              {'assessmentId': 5011, 'valor': 16.0},
+              {'assessmentId': 5012, 'valor': 16.0},
+            ],
+          },
+        ],
+      });
+      // El promedio sí cuenta la de la ULima y no la simulada oculta.
+      expect(api.cuerposDe('/grades/me/calculate').last, {
+        'notas': [
+          {'valor': 14.5, 'peso': 15.0},
+          {'valor': 16.0, 'peso': 25.0},
+        ],
+      });
+    });
+  });
 }
```

- [ ] **Paso 2. Comprueba que fallan.**

```bash
"$FLUTTER" test --no-pub test/HU37_jeff/calculadora_ulima_test.dart test/HU37_jeff/filas_calculadora_test.dart
```

**Esperado.** Fallan al compilar porque `CalculadoraController` no tiene el parámetro
`apiClient` ni el método `conectarUlima`.

- [ ] **Paso 3. `NotaTile`.** Reemplaza todo `lib/components/calculadora/nota_tile.dart` por este
  contenido. Las llamadas de hoy siguen valiendo, porque `peso` pasa de `int` a `num`, `nota` de
  `double` a `double?` y `onDelete` a opcional con un `assert`.

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../configs/themes.dart';
import '../../domain/recarga_ulima/formato_nota.dart';

class NotaTile extends StatelessWidget {
  final String titulo;

  /// Entero en las simuladas y con el peso exacto de la ULima en las suyas.
  final num peso;

  /// `null` solo con [np].
  final double? nota;

  /// La ULima publica «NP» (decisión B8). La línea dice `Nota: NP`.
  final bool np;

  /// La nota la publica la ULima (RF-RCG-7). Lleva la marca «ULima» en lugar
  /// del tacho y no se puede borrar ni editar.
  final bool deUlima;
  final VoidCallback? onDelete;

  const NotaTile({
    super.key,
    required this.titulo,
    required this.peso,
    required this.nota,
    this.np = false,
    this.deUlima = false,
    this.onDelete,
  }) : assert(deUlima || onDelete != null, 'Una nota simulada se borra');

  String get _textoNota =>
      np ? 'Nota: NP' : 'Nota: ${formatoNotaCalculadora(nota ?? 0)}/20';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fila = _fila(context, colors);
    if (!deUlima) return fila;
    final notaDicha = np
        ? 'nota NP'
        : 'nota ${formatoNotaCalculadora(nota ?? 0)} de 20';
    return Semantics(
      container: true,
      excludeSemantics: true,
      label:
          '$titulo, peso ${numeroDePeso(peso)} por ciento, $notaDicha, '
          'publicada por la ULima',
      child: fila,
    );
  }

  Widget _fila(BuildContext context, ColorScheme colors) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: colors.onTertiaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    children: [
                      TextSpan(text: "Peso: ${formatoPeso(peso)}  •  "),
                      TextSpan(
                        text: _textoNota,
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (deUlima)
            const SizedBox(height: 40, child: Center(child: _InsigniaUlima()))
          else
            IconButton(
              icon: Icon(Icons.delete_outline, color: colors.error, size: 22),
              onPressed: () {
                Get.defaultDialog(
                  title: "Eliminar Nota",
                  titleStyle: TextStyle(color: colors.onSurface),
                  middleTextStyle: TextStyle(color: colors.onSurfaceVariant),
                  backgroundColor: colors.surface,
                  middleText:
                      "¿Estás seguro de que quieres eliminar '$titulo'?",
                  textConfirm: "Eliminar",
                  textCancel: "Cancelar",
                  confirmTextColor: colors.onError,
                  buttonColor: colors.error,
                  onConfirm: () {
                    onDelete!();
                    debugPrint(
                      "✅ ÉXITO: Se eliminó la nota '$titulo' correctamente.",
                    );
                    Get.back();
                  },
                );
              },
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

/// La marca «ULima» de una nota publicada, con el tamaño de
/// `RecordPositionBadge` y el naranja de D11. No es tocable.
class _InsigniaUlima extends StatelessWidget {
  const _InsigniaUlima();

  @override
  Widget build(BuildContext context) {
    final brillo = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: MaterialTheme.espPrincipalBg(brillo),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'ULima',
        style: TextStyle(
          color: MaterialTheme.insigniaUlimaTexto(brillo),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
```

- [ ] **Paso 4. `CursoCard`.** Aplica este cambio a `lib/components/calculadora/curso_card.dart`.

```diff
diff --git a/lib/components/calculadora/curso_card.dart b/lib/components/calculadora/curso_card.dart
--- a/lib/components/calculadora/curso_card.dart
+++ b/lib/components/calculadora/curso_card.dart
@@ -1,5 +1,6 @@
 import 'package:flutter/material.dart';
 import 'package:get/get.dart';
+import '../../domain/recarga_ulima/filas_calculadora.dart';
 import 'nota_tile.dart';
 
 class CursoCard extends StatelessWidget {
@@ -7,8 +8,14 @@ class CursoCard extends StatelessWidget {
   final double promedio;
   final double sumaPesos;
   final int cursoIndex;
+
+  /// Recibe la posición de la simulada en `curso['notas']`, no la de la fila
+  /// visible (RF-RCG-7).
   final Function(int, int) onDeleteNota;
 
+  /// Los ids de las evaluaciones del sílabo de la sección, en su orden (D7).
+  final List<String> ordenSilabo;
+
   const CursoCard({
     super.key,
     required this.curso,
@@ -16,6 +23,7 @@ class CursoCard extends StatelessWidget {
     required this.sumaPesos,
     required this.cursoIndex,
     required this.onDeleteNota,
+    this.ordenSilabo = const [],
   });
 
   @override
@@ -152,17 +160,34 @@ class CursoCard extends StatelessWidget {
           Padding(
             padding: const EdgeInsets.symmetric(vertical: 5),
             child: Obx(() {
-              final listasNotas = curso['notas'] as List;
+              // Las simuladas y las de la ULima, en listas aparte. El doble de
+              // HU07 arma sus cursos sin la segunda.
+              final filas = filasVisibles(
+                simuladas: curso['notas'] as List,
+                ulima: (curso[claveNotasUlima] as List?) ?? const [],
+                ordenSilabo: ordenSilabo,
+              );
               return Column(
-                children: List.generate(listasNotas.length, (index) {
-                  final nota = listasNotas[index];
-                  return NotaTile(
-                    titulo: nota['titulo'],
-                    peso: nota['peso'],
-                    nota: nota['valor'],
-                    onDelete: () => onDeleteNota(cursoIndex, index),
-                  );
-                }),
+                children: [
+                  for (final fila in filas)
+                    fila.deUlima
+                        ? NotaTile(
+                            titulo: fila.titulo,
+                            peso: fila.peso,
+                            nota: fila.valor,
+                            np: fila.np,
+                            deUlima: true,
+                          )
+                        : NotaTile(
+                            titulo: fila.titulo,
+                            peso: fila.peso,
+                            nota: fila.valor,
+                            onDelete: () =>
+                                onDeleteNota(cursoIndex, fila.indiceSimulada!),
+                          ),
+                  if (curso[claveUlimaSinPareja] == true)
+                    const _SilaboQueNoCoincide(),
+                ],
               );
             }),
           ),
@@ -171,3 +196,33 @@ class CursoCard extends StatelessWidget {
     );
   }
 }
+
+/// La línea de un curso con evaluaciones de la ULima que no están en el
+/// sílabo cargado (D15).
+class _SilaboQueNoCoincide extends StatelessWidget {
+  const _SilaboQueNoCoincide();
+
+  @override
+  Widget build(BuildContext context) {
+    final tenue = Theme.of(
+      context,
+    ).colorScheme.onSurface.withValues(alpha: 0.7);
+    return Padding(
+      padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
+      child: Row(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        children: [
+          Icon(Icons.info_outline, size: 16, color: tenue),
+          const SizedBox(width: 6),
+          Expanded(
+            child: Text(
+              'La ULima publica evaluaciones que no están en el sílabo '
+              'cargado. Míralas en Notas oficiales.',
+              style: TextStyle(fontSize: 12, color: tenue),
+            ),
+          ),
+        ],
+      ),
+    );
+  }
+}
```

- [ ] **Paso 5. La fila «Notas oficiales».** Crea
  `lib/components/recarga_ulima/fila_notas_oficiales.dart` con este contenido.

```dart
// lib/components/recarga_ulima/fila_notas_oficiales.dart
//
// La fila «Notas oficiales» del encabezado de la calculadora (RF-RCG-5 de
// specs/features/recarga-portal/recarga-portal.spec.md), con el estilo de la
// hoja «Selecciona un Curso». Reemplaza al birrete sin texto.

import 'package:flutter/material.dart';

import '../../configs/themes.dart';
import '../../domain/recarga_ulima/ultima_lectura.dart';
import 'franja_recarga.dart' show textoSinLecturaUlima;

class FilaNotasOficiales extends StatelessWidget {
  const FilaNotasOficiales({
    super.key,
    required this.hayVista,
    required this.ultimaLectura,
    required this.onTap,
  });

  /// Hay una vista de la ULima del alumno actual. Sin ella, porque la primera
  /// carga está en curso o termina en error, la fila lleva solo el título.
  final bool hayVista;

  /// La `lastReadAt` de la vista, o `null` si todavía no hay lectura.
  final DateTime? ultimaLectura;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final lectura = ultimaLectura;
    final segunda = !hayVista
        ? null
        : lectura == null
        ? textoSinLecturaUlima
        : textoUltimaLectura(lectura, DateTime.now());
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: colors.primary.withValues(alpha: 0.3)),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Semantics(
        button: true,
        label: segunda == null
            ? 'Notas oficiales'
            : 'Notas oficiales. $segunda',
        excludeSemantics: true,
        onTap: onTap,
        child: Material(
          color: colors.primary.withValues(alpha: 0.1),
          shape: forma,
          child: InkWell(
            onTap: onTap,
            customBorder: forma,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 22,
                      color: MaterialTheme.iconoNaranja(colors.brightness),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Notas oficiales',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colors.onSurface,
                            ),
                          ),
                          if (segunda != null)
                            Text(
                              segunda,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 22,
                      color: colors.onSurface.withValues(alpha: 0.5),
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

- [ ] **Paso 6. El controller.** Aplica este cambio a
  `lib/pages/calculadora/calculadora_controller.dart`. Los `Rx` nuevos van en su declaración,
  porque el doble de HU07 no llama a `super.onInit()`.

```diff
diff --git a/lib/pages/calculadora/calculadora_controller.dart b/lib/pages/calculadora/calculadora_controller.dart
--- a/lib/pages/calculadora/calculadora_controller.dart
+++ b/lib/pages/calculadora/calculadora_controller.dart
@@ -1,12 +1,18 @@
 import 'package:flutter/foundation.dart';
 import 'package:get/get.dart';
+import '../../domain/recarga_ulima/filas_calculadora.dart';
 import '../../models/evaluation_model.dart';
 import '../../services/evaluations_service.dart';
 import '../../services/courses_service.dart';
 import '../../services/auth_service.dart';
 import '../../services/api_client.dart';
+import '../../services/recarga_ulima_service.dart';
 
 class CalculadoraController extends GetxController {
+  /// [apiClient] es para las pruebas. Sin él usa el `ApiClient` de siempre.
+  CalculadoraController({ApiClient? apiClient})
+      : _api = apiClient ?? ApiClient();
+
   late var cursos = <Map<String, dynamic>>[].obs;
 
   // Distingue "falló la carga de cursos" de "aún no registras notas": antes un
@@ -17,22 +23,95 @@ class CalculadoraController extends GetxController {
 
   late EvaluationSyllabusService _syllabusService;
   late CoursesService _coursesService;
-  late ApiClient _api;
+  final ApiClient _api;
 
   late var syllabusData = <String, CourseSyllabus>{}.obs;
 
+  /// Hay una vista de la ULima del alumno actual (RF-RCG-5). Sin ella la fila
+  /// «Notas oficiales» lleva solo el título.
+  final RxBool hayVistaUlima = false.obs;
+
+  /// La `lastReadAt` de esa vista, para la segunda línea de la fila.
+  final Rxn<DateTime> ultimaLecturaUlima = Rxn<DateTime>();
+
+  /// Escucha los cambios de la vista de la ULima. Lo cierra [onClose].
+  Worker? _vistaUlima;
+
   @override
   void onInit() {
     super.onInit();
-    _api = ApiClient();
     _syllabusService = EvaluationSyllabusService();
     _coursesService = CoursesService();
 
     _cargarDatosSyllabus();
     _inicializarCursos();
+    conectarUlima();
+  }
+
+  @override
+  void onClose() {
+    _vistaUlima?.dispose();
+    super.onClose();
+  }
+
+  /// Llena las filas de la ULima desde `RecargaUlimaService` y las rehace con
+  /// cada cambio de su vista (RF-RCG-7). La página nunca hace `Get.find` del
+  /// servicio. Sin el servicio registrado, la calculadora queda como hoy.
+  void conectarUlima() {
+    if (!Get.isRegistered<RecargaUlimaService>()) return;
+    final servicio = RecargaUlimaService.to;
+    _vistaUlima?.dispose();
+    _vistaUlima = servicio.alCambiarVista(aplicarVistaUlima);
+    aplicarVistaUlima();
+    if (servicio.vista == null) servicio.cargar();
+  }
+
+  /// Rehace las filas de la ULima de cada curso desde la vista del alumno
+  /// actual y, con [recalcular], pide el promedio de los cursos que cambian.
+  /// Un fallo de la carga sin vista previa deja la calculadora como hoy, y con
+  /// vista previa del mismo alumno las filas siguen.
+  void aplicarVistaUlima({bool recalcular = true}) {
+    final vista = Get.isRegistered<RecargaUlimaService>()
+        ? RecargaUlimaService.to.vista
+        : null;
+    hayVistaUlima.value = vista != null;
+    ultimaLecturaUlima.value = vista?.lastReadAt;
+    final cambiados = <int>[];
+    for (var i = 0; i < cursos.length; i++) {
+      final curso = cursos[i];
+      final deUlima = vista?.cursos.firstWhereOrNull(
+        (c) => '${c.sectionId}' == '${curso['id']}',
+      );
+      final notas = notasUlimaDeCurso(deUlima);
+      final sinPareja = ulimaSinPareja(deUlima);
+      if (mismasNotasUlima(curso[claveNotasUlima], notas) &&
+          (curso[claveUlimaSinPareja] ?? false) == sinPareja) {
+        continue;
+      }
+      curso[claveNotasUlima] = notas;
+      curso[claveUlimaSinPareja] = sinPareja;
+      cambiados.add(i);
+    }
+    if (cambiados.isEmpty) return;
+    cursos.refresh();
+    if (!recalcular) return;
+    for (final i in cambiados) {
+      _calcularPromedio(i);
+    }
   }
 
-  void _cargarDatosSyllabus() async {
+  /// Vuelve a pedir el sílabo, los cursos, las notas simuladas y la vista de
+  /// la ULima, y recalcula los promedios (RF-RCG-11). Lo llama la importación
+  /// en vez de borrar el controller.
+  Future<void> recargarTodo() async {
+    await _cargarDatosSyllabus();
+    await _inicializarCursos();
+    if (Get.isRegistered<RecargaUlimaService>()) {
+      await RecargaUlimaService.to.cargar();
+    }
+  }
+
+  Future<void> _cargarDatosSyllabus() async {
     try {
       await _syllabusService.loadEvaluationData();
       for (var syllabus in _syllabusService.allSyllabuses) {
@@ -47,7 +126,7 @@ class CalculadoraController extends GetxController {
   /// Reintenta la carga de cursos (botón "Reintentar" del estado de error).
   void recargar() => _inicializarCursos();
 
-  void _inicializarCursos() async {
+  Future<void> _inicializarCursos() async {
     try {
       final user = AuthService.to.currentUser;
 
@@ -103,6 +182,7 @@ class CalculadoraController extends GetxController {
       }
 
       cursos.value = cursosExpandidos;
+      aplicarVistaUlima(recalcular: false);
       for (int i = 0; i < cursos.length; i++) {
         await _calcularPromedio(i);
       }
@@ -167,20 +247,16 @@ class CalculadoraController extends GetxController {
 
   Future<void> _calcularPromedio(int cursoIndex) async {
     if (cursoIndex < 0 || cursoIndex >= cursos.length) return;
-    final notas = cursos[cursoIndex]['notas'] as List;
+    final curso = cursos[cursoIndex];
     try {
-      final notasClean = notas
-          .map(
-            (n) => {
-              'valor': (n['valor'] is num)
-                  ? (n['valor'] as num).toDouble()
-                  : (double.tryParse(n['valor']?.toString() ?? '') ?? 0.0),
-              'peso': (n['peso'] is num)
-                  ? (n['peso'] as num).toDouble()
-                  : (double.tryParse(n['peso']?.toString() ?? '') ?? 0.0),
-            },
-          )
-          .toList();
+      // Las filas visibles, simuladas y de la ULima, con NP como 0 y el peso
+      // exacto de la ULima (RF-RCG-7).
+      final notasClean = notasParaPromedio(
+        filasVisibles(
+          simuladas: curso['notas'] as List,
+          ulima: (curso[claveNotasUlima] as List?) ?? const [],
+        ),
+      );
 
       final result = await _api.postJson(
         '/grades/me/calculate',
@@ -274,11 +350,19 @@ class CalculadoraController extends GetxController {
     return [];
   }
 
+  /// Las evaluaciones del sílabo sin nota simulada y sin una fila de la ULima
+  /// visible (RF-RCG-7).
   List<EvaluationComponent> getAvailableEvaluations(int cursoIndex) {
     final allEvaluations = getEvaluationsForCourse(cursoIndex);
     final registeredIds = getRegisteredEvaluationIds(cursoIndex);
+    final deUlima = cursoIndex >= 0 && cursoIndex < cursos.length
+        ? idsConNotaUlima(cursos[cursoIndex])
+        : const <String>{};
     return allEvaluations
-        .where((eval) => !registeredIds.contains(eval.id))
+        .where(
+          (eval) =>
+              !registeredIds.contains(eval.id) && !deUlima.contains(eval.id),
+        )
         .toList();
   }
 
```

- [ ] **Paso 7. La página.** Aplica este cambio a `lib/pages/calculadora/calculadora_page.dart`.

```diff
diff --git a/lib/pages/calculadora/calculadora_page.dart b/lib/pages/calculadora/calculadora_page.dart
--- a/lib/pages/calculadora/calculadora_page.dart
+++ b/lib/pages/calculadora/calculadora_page.dart
@@ -3,6 +3,8 @@ import 'package:get/get.dart';
 import '../../components/calculadora/curso_card.dart';
 import '../../components/calculadora/add_score.dart';
 import '../../components/error_retry.dart';
+import '../../components/recarga_ulima/fila_notas_oficiales.dart';
+import '../../domain/recarga_ulima/filas_calculadora.dart';
 import 'calculadora_controller.dart';
 
 class CalculadoraPage extends GetView<CalculadoraController> {
@@ -25,32 +27,19 @@ class CalculadoraPage extends GetView<CalculadoraController> {
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
-                Row(
-                  children: [
-                    Expanded(
-                      child: Text(
-                        "Calculadora de Notas",
-                        style: TextStyle(
-                          fontSize: 24,
-                          fontWeight: FontWeight.w900,
-                          color: colors.onSurface,
-                        ),
-                      ),
-                    ),
-                    IconButton(
-                      tooltip: 'Notas oficiales',
-                      onPressed: () => Get.toNamed('/mis-notas'),
-                      icon: Icon(Icons.school_outlined, color: colors.onSurface),
-                    ),
-                  ],
+                Text(
+                  "Calculadora de Notas",
+                  style: TextStyle(
+                    fontSize: 24,
+                    fontWeight: FontWeight.w900,
+                    color: colors.onSurface,
+                  ),
                 ),
                 Obx(() {
-                  final cursosConNotas = controller.cursos
-                      .where(
-                        (curso) =>
-                            (curso['notas'] as List?)?.isNotEmpty ?? false,
-                      )
-                      .length;
+                  // Un curso cuenta con al menos una fila visible, simulada o
+                  // de la ULima (RF-RCG-7).
+                  final cursosConNotas =
+                      controller.cursos.where(tieneFilasVisibles).length;
                   return Text(
                     "Cursos con notas: $cursosConNotas",
                     style: TextStyle(
@@ -60,6 +49,16 @@ class CalculadoraPage extends GetView<CalculadoraController> {
                     ),
                   );
                 }),
+                // RF-RCG-5. Es la única entrada a /mis-notas, en los tres
+                // estados de la calculadora. No espera resultado, porque la
+                // calculadora lee la vista de la ULima y se actualiza sola.
+                Obx(
+                  () => FilaNotasOficiales(
+                    hayVista: controller.hayVistaUlima.value,
+                    ultimaLectura: controller.ultimaLecturaUlima.value,
+                    onTap: () => Get.toNamed('/mis-notas'),
+                  ),
+                ),
               ],
             ),
           ),
@@ -75,11 +74,8 @@ class CalculadoraPage extends GetView<CalculadoraController> {
                 );
               }
 
-              final cursosConNotas = controller.cursos
-                  .where(
-                    (curso) => (curso['notas'] as List?)?.isNotEmpty ?? false,
-                  )
-                  .toList();
+              final cursosConNotas =
+                  controller.cursos.where(tieneFilasVisibles).toList();
 
               if (cursosConNotas.isEmpty) {
                 return Center(
@@ -129,6 +125,12 @@ class CalculadoraPage extends GetView<CalculadoraController> {
                     promedio: controller.calcularPromedio(cursoIndex),
                     sumaPesos: controller.sumaPesos(cursoIndex),
                     onDeleteNota: controller.eliminarNota,
+                    ordenSilabo: [
+                      for (final e in controller.getEvaluationsForCourse(
+                        cursoIndex,
+                      ))
+                        e.id,
+                    ],
                   );
                 },
               );
```

- [ ] **Paso 8. Comprueba que pasa.**

```bash
"$DART" format lib/components/calculadora/nota_tile.dart lib/components/calculadora/curso_card.dart lib/components/recarga_ulima/fila_notas_oficiales.dart test/HU37_jeff/calculadora_ulima_test.dart test/HU37_jeff/filas_calculadora_test.dart
"$FLUTTER" test --no-pub test/HU37_jeff/calculadora_ulima_test.dart test/HU37_jeff/filas_calculadora_test.dart test/HU07_sam test/HU06_sam test/HU23_jeff/chats_pestana_test.dart
"$FLUTTER" analyze --no-pub lib/components/calculadora lib/components/recarga_ulima lib/pages/calculadora test/HU37_jeff
```

**Esperado.** El formato no cambia nada, pasan las 20 pruebas de la calculadora y las 10 de las
filas, `HU07_sam`, `HU06_sam` y `chats_pestana_test.dart` siguen en verde sin cambios, y el
análisis no encuentra avisos.

- [ ] **Paso 9. Suite completa en segundo plano.** Como en la Tarea 4. **Esperado.** Los mismos 6
  avisos y 1371 pruebas en verde.

- [ ] **Paso 10. Commit.**

```bash
git add lib/components/calculadora/nota_tile.dart lib/components/calculadora/curso_card.dart lib/components/recarga_ulima/fila_notas_oficiales.dart lib/pages/calculadora/calculadora_controller.dart lib/pages/calculadora/calculadora_page.dart test/HU37_jeff/calculadora_ulima_test.dart test/HU37_jeff/filas_calculadora_test.dart
git commit -m "feat(recarga-portal): la calculadora suma la fila «Notas oficiales» y las notas publicadas por la ULima con su marca (RF-RCG-5 y RF-RCG-7)"
```

---

### Tarea 9. La asistencia en la ficha del curso

**Requisitos.** RF-RCG-8 completo (con datos, sin datos, estado por curso, sin el servicio,
después de una recarga y modelo), la línea de lectura parcial de RF-RCG-3 en el bloque, D1, D2 y
D3.

**Archivos.**
- Crear `test/HU37_jeff/asistencia_recarga_test.dart`.
- Modificar `lib/models/seccion_model.dart`.
- Modificar `lib/pages/descripcion_cursos/descrip_cursos_controller.dart`.
- Crear `lib/components/recarga_ulima/pie_asistencia.dart`.
- Modificar `lib/pages/descripcion_cursos/descrip_cursos.dart`.

**Interfaces.**
- Consume `RecargaUlimaService` (`ultimoAviso`, `sinLecturaDeAsistencia`, `recargaHorario`) de la
  Tarea 4, `ejecutarAccionRecarga`, `AvisoRecargaCompacto` y `BotonAccionRecarga` de la Tarea 6,
  `textoUltimaLectura` de la Tarea 2 y `HorarioController.uniqueEnrolledCourses`.
- Produce estas firmas.

```dart
// package:ulima_plus/models/seccion_model.dart
final DateTime? asistenciaLeidaEn; // parámetro opcional del constructor

// package:ulima_plus/pages/descripcion_cursos/descrip_cursos_controller.dart
DescripCursosController({AsesoriaService? asesoriaService, SeccionService? seccionService});
Future<void> recargarSeccion(String idSeccion);

// package:ulima_plus/components/recarga_ulima/pie_asistencia.dart
const String textoAsistenciaSinLeer = 'No se pudo leer en esta actualización.';
const PieAsistencia({Key? key, required String idSeccion, required DateTime? leidaEn,
    required Future<void> Function() alRecargar});
const RecargaSinDatos({Key? key, required String idSeccion,
    required Future<void> Function() alRecargar});
```

- [ ] **Paso 1. Escribe la prueba que falla.** Crea
  `test/HU37_jeff/asistencia_recarga_test.dart` con este contenido. La ficha usa la sección 301
  de `test/HU23_jeff/chat_ficha_curso_test.dart`.

```dart
// test/HU37_jeff/asistencia_recarga_test.dart
//
// WIDGET · Recarga desde la ULima (specs/features/recarga-portal/
// recarga-portal.spec.md), RF-RCG-8, el botón y la hora de la última lectura
// en el bloque de asistencia de la ficha del curso.
// Archivos probados lib/pages/descripcion_cursos/**,
// lib/components/recarga_ulima/pie_asistencia.dart y
// lib/models/seccion_model.dart.
//
// La sección es la 301, código 801, del CURSO DE PRUEBA A, como en
// test/HU23_jeff/chat_ficha_curso_test.dart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/recarga_ulima/hoja_recarga_ulima.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/seccion_model.dart';
import 'package:ulima_plus/pages/descripcion_cursos/descrip_cursos.dart';
import 'package:ulima_plus/pages/descripcion_cursos/descrip_cursos_controller.dart';
import 'package:ulima_plus/pages/horario/horario_controller.dart';
import 'package:ulima_plus/services/recarga_ulima_service.dart';
import 'package:ulima_plus/services/seccion_service.dart';

import 'recarga_dobles.dart';

const String _refresh = 'POST /portal-sync/refresh';
const String _leida = '2025-09-22T15:42:10.000Z';

Map<String, dynamic> _seccionJson({
  bool conDatos = true,
  int asistido = 12,
  Object? leidaEn = _leida,
}) => <String, dynamic>{
  'idSeccion': '301',
  'codigoSeccion': '801',
  'curso': 'CURSO DE PRUEBA A',
  'asistido': conDatos ? asistido : 0,
  'inasistencia': conDatos ? 2 : 0,
  'total': conDatos ? 30 : 0,
  'asistenciaDisponible': conDatos,
  'horasTranscurridas': conDatos ? asistido + 2 : 0,
  'asistenciaLeidaEn': leidaEn,
};

/// `SeccionService` sin red. Cada respuesta es una `Seccion`, `null` o algo
/// que se lanza, y la última se repite.
class _SeccionesFalsas extends SeccionService {
  _SeccionesFalsas(this.respuestas);

  final List<Object?> respuestas;
  int pedidas = 0;

  @override
  Future<Seccion?> findSectionById(String id) async {
    final r =
        respuestas[pedidas < respuestas.length
            ? pedidas
            : respuestas.length - 1];
    pedidas++;
    if (r is Seccion?) return r;
    throw r;
  }
}

/// La ficha con la sección fija y sin red en las pestañas. `DescripCursosPage`
/// hace `Get.put(DescripCursosController())` y GetX conserva esta instancia.
class _Ficha extends DescripCursosController {
  _Ficha(this._inicial, this.falsas) : super(seccionService: falsas);

  final Seccion _inicial;
  final _SeccionesFalsas falsas;
  int cargasDePestanas = 0;

  @override
  Future<void> cargarDatosCurso(String idSeccion) async {
    seccionActual.value = _inicial;
    secciones.value = <Seccion>[_inicial];
  }

  @override
  Future<void> fetchAnuncios(String idSeccion) async => cargasDePestanas++;

  @override
  Future<void> fetchAsesorias(String idSeccion) async => cargasDePestanas++;

  @override
  Future<void> fetchContactos(String idSeccion) async => cargasDePestanas++;
}

/// El horario sin su carga remota. Cuenta sus recargas y devuelve
/// [enrolados] en `uniqueEnrolledCourses`.
class _HorarioEspia extends HorarioController {
  _HorarioEspia(this.enrolados);

  final List<Map<String, dynamic>> enrolados;
  int recargas = 0;

  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  Future<void> reload() async => recargas++;

  @override
  List<Map<String, dynamic>> get uniqueEnrolledCourses => enrolados;
}

Future<void> _asentar(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<_Ficha> _abrirFicha(
  WidgetTester tester, {
  Map<String, dynamic>? seccion,
  List<Object?> recargadas = const [null],
  ApiRecargaFalsa? api,
  bool conServicio = true,
  Future<void> Function(RecargaUlimaService)? antes,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  loguear(alumna());
  if (conServicio) {
    final servicio = Get.put<RecargaUlimaService>(
      RecargaUlimaService(apiClient: api ?? ApiRecargaFalsa()),
    );
    if (antes != null) await antes(servicio);
  }
  final ficha =
      Get.put<DescripCursosController>(
            _Ficha(
              Seccion.fromJson(seccion ?? _seccionJson()),
              _SeccionesFalsas(recargadas),
            ),
          )
          as _Ficha;
  await tester.pumpWidget(
    GetMaterialApp(
      theme: const MaterialTheme(TextTheme()).light(),
      home: DescripCursosPage(idSeccion: '301'),
    ),
  );
  await tester.pump();
  return ficha;
}

Finder get _enLaHoja => find.byType(HojaRecargaUlima);

/// Llena la hoja y toca su «Actualizar».
Future<void> _enviarHoja(WidgetTester tester) async {
  final campos = find.descendant(
    of: _enLaHoja,
    matching: find.byType(TextField),
  );
  await tester.enterText(campos.first, 'clave-de-prueba');
  await tester.enterText(campos.last, '482913');
  await tester.pump();
  await tester.tap(
    find.descendant(of: _enLaHoja, matching: find.text('Actualizar')),
  );
  await _asentar(tester);
}

Map<String, dynamic> _resultado(String asistencia) => resultadoJson(
  view: vistaJson(
    courses: [
      cursoJson(
        sectionId: 301,
        sectionCode: '801',
        courseName: 'CURSO DE PRUEBA A',
      ),
    ],
  ),
  courses: [
    {'sectionId': 301, 'attendance': asistencia, 'grades': 'read'},
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  group('UNITARIA · Seccion.asistenciaLeidaEn (RF-RCG-8)', () {
    test('Seccion.fromJson lee asistenciaLeidaEn y tolera que falte', () {
      expect(
        Seccion.fromJson(_seccionJson()).asistenciaLeidaEn,
        DateTime.utc(2025, 9, 22, 15, 42, 10),
      );
      expect(
        Seccion.fromJson(_seccionJson(leidaEn: null)).asistenciaLeidaEn,
        isNull,
      );
      expect(
        Seccion.fromJson(
          _seccionJson()..remove('asistenciaLeidaEn'),
        ).asistenciaLeidaEn,
        isNull,
      );
      expect(
        Seccion.fromJson(
          _seccionJson(leidaEn: 'no es fecha'),
        ).asistenciaLeidaEn,
        isNull,
      );
    });
  });

  group('WIDGET · el bloque con datos (RF-RCG-8)', () {
    testWidgets('la fila nueva lleva la hora a la izquierda y «Actualizar», '
        'en el naranja de D11, a la derecha', (tester) async {
      await _abrirFicha(tester);

      final hora = find.text('Última lectura $lecturaDePrueba');
      expect(hora, findsOneWidget);
      final boton = find.widgetWithText(TextButton, 'Actualizar');
      expect(boton, findsOneWidget);
      expect(
        find.descendant(of: boton, matching: find.byIcon(Icons.sync)),
        findsOneWidget,
      );
      expect(tester.getCenter(hora).dx, lessThan(tester.getCenter(boton).dx));
      expect(tester.getSize(boton).height, greaterThanOrEqualTo(48));
      expect(
        tester.widget<TextButton>(boton).style!.foregroundColor!.resolve({}),
        MaterialTheme.textoNaranja(Brightness.light),
      );
    });

    testWidgets('con asistenciaLeidaEn en null no hay línea de hora', (
      tester,
    ) async {
      await _abrirFicha(tester, seccion: _seccionJson(leidaEn: null));

      expect(find.textContaining('Última lectura'), findsNothing);
      expect(find.widgetWithText(TextButton, 'Actualizar'), findsOneWidget);
    });

    testWidgets('un 200 llama a recargarSeccion, que pide la sección sin '
        'volver a llamar a reload(), no recarga las pestañas y conserva la '
        'elegida', (tester) async {
      final horario =
          Get.put<HorarioController>(_HorarioEspia(const [])) as _HorarioEspia;
      final api = ApiRecargaFalsa()..responder(_refresh, _resultado('updated'));
      final ficha = await _abrirFicha(
        tester,
        api: api,
        recargadas: [Seccion.fromJson(_seccionJson(asistido: 13))],
      );
      ficha.selectedTab.value = 1;
      await tester.pump();
      final pestanas = ficha.cargasDePestanas;
      expect(find.text('12 horas'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Actualizar'));
      await _asentar(tester);
      await _enviarHoja(tester);

      expect(_enLaHoja, findsNothing);
      expect(ficha.falsas.pedidas, 1);
      expect(horario.recargas, 1);
      expect(ficha.cargasDePestanas, pestanas);
      expect(ficha.selectedTab.value, 1);
      expect(find.text('13 horas'), findsOneWidget);
    });

    testWidgets('si esa petición falla, espera recargaHorario y lee '
        'uniqueEnrolledCourses', (tester) async {
      final horario =
          Get.put<HorarioController>(
                _HorarioEspia([_seccionJson(asistido: 14)]),
              )
              as _HorarioEspia;
      final api = ApiRecargaFalsa()..responder(_refresh, _resultado('updated'));
      final ficha = await _abrirFicha(
        tester,
        api: api,
        recargadas: [errorApi(500, 'HTTP_ERROR')],
      );

      await tester.tap(find.widgetWithText(TextButton, 'Actualizar'));
      await _asentar(tester);
      await _enviarHoja(tester);

      expect(ficha.falsas.pedidas, 1);
      expect(horario.recargas, 1);
      expect(find.text('14 horas'), findsOneWidget);
    });

    testWidgets('la línea de lectura parcial, con un sectionId entero y un '
        'idSeccion de texto', (tester) async {
      final api = ApiRecargaFalsa()..responder(_refresh, _resultado('failed'));
      await _abrirFicha(
        tester,
        api: api,
        antes: (s) =>
            s.recargar(password: 'clave-de-prueba', passcode: '482913'),
      );

      expect(
        find.text('No se pudo leer en esta actualización.'),
        findsOneWidget,
      );
    });

    testWidgets('el aviso compacto reemplaza a la hora y el botón pasa a la '
        'acción del aviso', (tester) async {
      final api = ApiRecargaFalsa()
        ..responder(_refresh, errorApi(409, 'IMPORT_REQUIRED'));
      await _abrirFicha(
        tester,
        api: api,
        antes: (s) =>
            s.recargar(password: 'clave-de-prueba', passcode: '482913'),
      );

      expect(find.text('No se pudo actualizar'), findsOneWidget);
      expect(find.text('Primero carga tus datos del ciclo.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.textContaining('Última lectura'), findsNothing);
      expect(
        find.widgetWithText(TextButton, 'Cargar mis datos'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextButton, 'Actualizar'), findsNothing);
    });
  });

  group('WIDGET · el bloque sin datos (RF-RCG-8 y D3)', () {
    testWidgets('el botón dice «Actualizar desde la ULima», en el naranja de '
        'D11, y abre la hoja', (tester) async {
      await _abrirFicha(tester, seccion: _seccionJson(conDatos: false));

      expect(
        find.text('Sin datos de asistencia para este curso.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Todavía no se importaron tus horas de clase desde '
          'miUlima.',
        ),
        findsOneWidget,
      );
      expect(find.text('Actualizar desde miUlima'), findsNothing);
      final boton = find.widgetWithText(
        TextButton,
        'Actualizar desde la ULima',
      );
      expect(
        tester.widget<TextButton>(boton).style!.foregroundColor!.resolve({}),
        MaterialTheme.textoNaranja(Brightness.light),
      );

      await tester.tap(boton);
      await _asentar(tester);
      expect(_enLaHoja, findsOneWidget);
    });

    testWidgets('la línea de lectura parcial va entre la línea explicativa y '
        'el botón', (tester) async {
      final api = ApiRecargaFalsa()..responder(_refresh, _resultado('missing'));
      await _abrirFicha(
        tester,
        seccion: _seccionJson(conDatos: false),
        api: api,
        antes: (s) =>
            s.recargar(password: 'clave-de-prueba', passcode: '482913'),
      );

      final explicativa = tester.getTopLeft(
        find.text(
          'Todavía no se importaron '
          'tus horas de clase desde miUlima.',
        ),
      );
      final parcial = tester.getTopLeft(
        find.text('No se pudo leer en esta actualización.'),
      );
      final boton = tester.getTopLeft(
        find.widgetWithText(TextButton, 'Actualizar desde la ULima'),
      );
      expect(parcial.dy, greaterThan(explicativa.dy));
      expect(boton.dy, greaterThan(parcial.dy));
    });

    testWidgets('el aviso compacto va en el mismo lugar y cambia la acción del '
        'botón', (tester) async {
      final api = ApiRecargaFalsa()
        ..responder(_refresh, errorApi(409, 'PORTAL_LOGIN_REJECTED'));
      await _abrirFicha(
        tester,
        seccion: _seccionJson(conDatos: false),
        api: api,
        antes: (s) =>
            s.recargar(password: 'clave-de-prueba', passcode: '482913'),
      );

      expect(find.text('No se pudo actualizar'), findsOneWidget);
      final boton = find.widgetWithText(TextButton, 'Reintentar');
      expect(boton, findsOneWidget);
      expect(
        tester.getTopLeft(boton).dy,
        greaterThan(tester.getTopLeft(find.text('No se pudo actualizar')).dy),
      );

      await tester.tap(boton);
      await _asentar(tester);
      expect(_enLaHoja, findsOneWidget);
    });
  });

  group('WIDGET · sin RecargaUlimaService (RF-RCG-8)', () {
    testWidgets('el bloque con datos queda como hoy, sin la fila nueva', (
      tester,
    ) async {
      await _abrirFicha(tester, conServicio: false);

      expect(find.text('12 horas'), findsOneWidget);
      expect(find.textContaining('Última lectura'), findsNothing);
      expect(find.widgetWithText(TextButton, 'Actualizar'), findsNothing);
    });

    testWidgets('el botón del estado sin datos sigue abriendo /portal-sync', (
      tester,
    ) async {
      await _abrirFicha(
        tester,
        seccion: _seccionJson(conDatos: false),
        conServicio: false,
      );

      expect(find.text('Actualizar desde miUlima'), findsOneWidget);
      expect(find.text('Actualizar desde la ULima'), findsNothing);
    });
  });
}
```

- [ ] **Paso 2. Comprueba que falla.**

```bash
"$FLUTTER" test --no-pub test/HU37_jeff/asistencia_recarga_test.dart
```

**Esperado.** Falla al compilar porque `DescripCursosController` no tiene el parámetro
`seccionService`.

- [ ] **Paso 3. El modelo.** Aplica este cambio a `lib/models/seccion_model.dart`. Las horas
  siguen truncadas a entero como hoy.

```diff
diff --git a/lib/models/seccion_model.dart b/lib/models/seccion_model.dart
--- a/lib/models/seccion_model.dart
+++ b/lib/models/seccion_model.dart
@@ -18,6 +18,10 @@ class Seccion {
   /// RS-BE-16.
   final int horasTranscurridas;
 
+  /// Hora de la última lectura de la asistencia en miUlima (RS-BE-58 y
+  /// RF-RCG-8), o `null` si no hay ninguna o el backend no la manda.
+  final DateTime? asistenciaLeidaEn;
+
   Seccion({
     required this.idSeccion,
     required this.codigoSeccion,
@@ -30,6 +34,7 @@ class Seccion {
     required this.total,
     required this.asistenciaDisponible,
     required this.horasTranscurridas,
+    this.asistenciaLeidaEn,
   });
 
   /// Fracción asistida (0..1) sobre las horas TRANSCURRIDAS, o `null` si
@@ -81,6 +86,9 @@ class Seccion {
       horasTranscurridas: (json['horasTranscurridas'] as num?)?.toInt() ??
           (((json['asistido'] as num?)?.toInt() ?? 0) +
               ((json['inasistencia'] as num?)?.toInt() ?? 0)),
+      asistenciaLeidaEn: json['asistenciaLeidaEn'] is String
+          ? DateTime.tryParse(json['asistenciaLeidaEn'] as String)
+          : null,
     );
   }
 }
```

- [ ] **Paso 4. El controller.** Aplica este cambio a
  `lib/pages/descripcion_cursos/descrip_cursos_controller.dart`.

```diff
diff --git a/lib/pages/descripcion_cursos/descrip_cursos_controller.dart b/lib/pages/descripcion_cursos/descrip_cursos_controller.dart
--- a/lib/pages/descripcion_cursos/descrip_cursos_controller.dart
+++ b/lib/pages/descripcion_cursos/descrip_cursos_controller.dart
@@ -9,18 +9,23 @@ import 'package:ulima_plus/services/anuncio_service.dart';
 import 'package:ulima_plus/services/api_client.dart';
 import 'package:ulima_plus/services/asesoria_service.dart';
 import 'package:ulima_plus/services/contacto_service.dart';
+import 'package:ulima_plus/services/recarga_ulima_service.dart';
 import 'package:ulima_plus/services/seccion_service.dart';
 import 'package:ulima_plus/pages/horario/horario_controller.dart';
 
 class DescripCursosController extends GetxController {
-  final SeccionService _seccionService = SeccionService();
+  final SeccionService _seccionService;
   final AnuncioService _anuncioService = AnuncioService();
   final AsesoriaService _asesoriaService;
   final ContactoService _contactoService = ContactoService();
 
   // HU17: `asesoriaService` es inyectable para pruebas (por defecto la real).
-  DescripCursosController({AsesoriaService? asesoriaService})
-      : _asesoriaService = asesoriaService ?? AsesoriaService();
+  // RF-RCG-8. `seccionService` también, para `recargarSeccion`.
+  DescripCursosController({
+    AsesoriaService? asesoriaService,
+    SeccionService? seccionService,
+  })  : _asesoriaService = asesoriaService ?? AsesoriaService(),
+        _seccionService = seccionService ?? SeccionService();
 
   RxList<Seccion> secciones = <Seccion>[].obs;
   Rxn<Seccion> seccionActual = Rxn<Seccion>();
@@ -193,6 +198,40 @@ class DescripCursosController extends GetxController {
     }
   }
 
+  /// Vuelve a leer solo la sección después de una recarga exitosa desde la
+  /// ULima (RF-RCG-8), sin tocar anuncios, asesorías, contactos ni la pestaña
+  /// elegida.
+  ///
+  /// Pide primero `GET /course-detail/sections/:id`, que trae las horas del
+  /// alumno y `asistenciaLeidaEn`, porque `HorarioController.reload()` se
+  /// traga sus errores y `uniqueEnrolledCourses` puede seguir vieja. Solo si
+  /// esa petición falla espera la recarga del horario que ya lanza
+  /// `RecargaUlimaService` y busca la sección ahí. Nunca llama a `reload()`.
+  Future<void> recargarSeccion(String idSeccion) async {
+    Seccion? nueva;
+    try {
+      nueva = await _seccionService.findSectionById(idSeccion);
+    } catch (e) {
+      debugPrint('recargarSeccion falló: $e');
+      final horario = Get.isRegistered<RecargaUlimaService>()
+          ? RecargaUlimaService.to.recargaHorario
+          : null;
+      if (horario != null) await horario;
+      if (Get.isRegistered<HorarioController>()) {
+        final datos = Get.find<HorarioController>()
+            .uniqueEnrolledCourses
+            .firstWhereOrNull((c) => c['idSeccion']?.toString() == idSeccion);
+        if (datos != null) nueva = Seccion.fromJson(datos);
+      }
+    }
+    if (nueva == null) return;
+    final i = secciones.indexWhere((s) => s.idSeccion == idSeccion);
+    if (i >= 0) secciones[i] = nueva;
+    if (seccionActual.value?.idSeccion == idSeccion) {
+      seccionActual.value = nueva;
+    }
+  }
+
   void limpiarDatos() {
     secciones.clear();
     seccionActual.value = null;
```

- [ ] **Paso 5. El pie del bloque.** Crea `lib/components/recarga_ulima/pie_asistencia.dart` con
  este contenido.

```dart
// lib/components/recarga_ulima/pie_asistencia.dart
//
// La recarga en el bloque de asistencia de la ficha del curso (RF-RCG-8 de
// specs/features/recarga-portal/recarga-portal.spec.md). La ficha monta estas
// piezas solo con `RecargaUlimaService` registrado.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/recarga_ulima/avisos_recarga.dart';
import '../../domain/recarga_ulima/ultima_lectura.dart';
import '../../services/recarga_ulima_service.dart';
import 'aviso_recarga.dart';

/// Texto de un curso sin lectura de asistencia en la última recarga.
const String textoAsistenciaSinLeer = 'No se pudo leer en esta actualización.';

Future<void> _actuar(
  BuildContext context,
  AvisoRecarga? aviso,
  Future<void> Function() alRecargar,
) async {
  if (await ejecutarAccionRecarga(context, aviso)) await alRecargar();
}

/// La fila bajo las horas y el anillo, con la hora de la última lectura a la
/// izquierda y «Actualizar» a la derecha (D1).
class PieAsistencia extends StatelessWidget {
  const PieAsistencia({
    super.key,
    required this.idSeccion,
    required this.leidaEn,
    required this.alRecargar,
  });

  final String idSeccion;

  /// `asistenciaLeidaEn` de la sección. Con `null` la línea no se pinta (D2).
  final DateTime? leidaEn;

  /// Lo que hace la ficha tras una recarga guardada, que es volver a leer su
  /// sección.
  final Future<void> Function() alRecargar;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Obx(() {
      final servicio = RecargaUlimaService.to;
      final aviso = servicio.ultimoAviso;
      final sinLeer = servicio.sinLecturaDeAsistencia(idSeccion);
      final leida = leidaEn;
      final secundario = TextStyle(
        fontSize: 12,
        color: colors.onSurfaceVariant,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: aviso != null
                    ? AvisoRecargaCompacto(aviso: aviso)
                    : leida == null
                    ? const SizedBox.shrink()
                    : Text(
                        textoUltimaLectura(leida, DateTime.now()),
                        style: secundario,
                      ),
              ),
              BotonAccionRecarga(
                texto: aviso?.textoAccion ?? 'Actualizar',
                icono: Icons.sync,
                onPressed: () => _actuar(context, aviso, alRecargar),
              ),
            ],
          ),
          if (aviso == null && sinLeer)
            Text(textoAsistenciaSinLeer, style: secundario),
        ],
      );
    });
  }
}

/// Las señales y el botón del estado sin datos, entre la línea explicativa y
/// el final del bloque (D3).
class RecargaSinDatos extends StatelessWidget {
  const RecargaSinDatos({
    super.key,
    required this.idSeccion,
    required this.alRecargar,
  });

  final String idSeccion;
  final Future<void> Function() alRecargar;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Obx(() {
      final servicio = RecargaUlimaService.to;
      final aviso = servicio.ultimoAviso;
      final sinLeer = servicio.sinLecturaDeAsistencia(idSeccion);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (aviso != null) ...[
            AvisoRecargaCompacto(aviso: aviso),
            const SizedBox(height: 12),
          ] else if (sinLeer) ...[
            Text(
              textoAsistenciaSinLeer,
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
          ],
          BotonAccionRecarga(
            texto: aviso?.textoAccion ?? 'Actualizar desde la ULima',
            icono: Icons.sync,
            onPressed: () => _actuar(context, aviso, alRecargar),
          ),
        ],
      );
    });
  }
}
```

- [ ] **Paso 6. La ficha.** Aplica este cambio a
  `lib/pages/descripcion_cursos/descrip_cursos.dart`.

```diff
diff --git a/lib/pages/descripcion_cursos/descrip_cursos.dart b/lib/pages/descripcion_cursos/descrip_cursos.dart
--- a/lib/pages/descripcion_cursos/descrip_cursos.dart
+++ b/lib/pages/descripcion_cursos/descrip_cursos.dart
@@ -3,9 +3,11 @@ import 'dart:math' as math;
 import 'package:flutter/material.dart';
 import 'package:get/get.dart';
 import 'package:lucide_icons_flutter/lucide_icons.dart';
+import '../../components/recarga_ulima/pie_asistencia.dart';
 import '../../configs/themes.dart';
 import '../../models/seccion_model.dart';
 import '../../services/chat_repository.dart';
+import '../../services/recarga_ulima_service.dart';
 import '../chat/chat_page.dart';
 import 'anuncios_tab.dart';
 import 'asesoria_tab.dart';
@@ -44,6 +46,12 @@ class DescripCursosPage extends StatelessWidget {
   Color _attendanceDivider(ColorScheme colors) =>
       MaterialTheme.bloqueAsistenciaLinea(colors.brightness);
 
+  /// La recarga desde la ULima solo se monta con su servicio registrado
+  /// (RF-RCG-8). Sin él, el bloque queda como antes de la recarga.
+  bool get _conRecarga => Get.isRegistered<RecargaUlimaService>();
+
+  Future<void> _recargarSeccion() => control.recargarSeccion(idSeccion);
+
   Widget _courseTitle(BuildContext context, Seccion seccion) {
     ColorScheme colors = Theme.of(context).colorScheme;
 
@@ -169,7 +177,7 @@ class DescripCursosPage extends StatelessWidget {
     // (ver `_AnilloAsistencia`). El `NaN` que clampeaba al máximo y pintaba la
     // dona llena y verde murió con eso. Ver RS-BE-10 y RS-BE-16.
     if (!seccion.asistenciaDisponible) {
-      return _asistenciaSinDatos(context, colors);
+      return _asistenciaSinDatos(context, colors, seccion);
     }
 
     return Container(
@@ -301,6 +309,14 @@ class DescripCursosPage extends StatelessWidget {
               ),
             ],
           ),
+          if (_conRecarga) ...[
+            const SizedBox(height: 12),
+            PieAsistencia(
+              idSeccion: seccion.idSeccion,
+              leidaEn: seccion.asistenciaLeidaEn,
+              alRecargar: _recargarSeccion,
+            ),
+          ],
         ],
       ),
     );
@@ -311,7 +327,11 @@ class DescripCursosPage extends StatelessWidget {
   /// Deliberadamente NEUTRO, no verde: el verde es el color de "todo bien" en
   /// esta app, y "no sabemos" no es "todo bien". Tampoco muestra los tres ceros,
   /// que se leían como asistencia perfecta.
-  Widget _asistenciaSinDatos(BuildContext context, ColorScheme colors) {
+  Widget _asistenciaSinDatos(
+    BuildContext context,
+    ColorScheme colors,
+    Seccion seccion,
+  ) {
     return Container(
       width: double.infinity,
       color: _attendanceBackground(colors),
@@ -346,14 +366,22 @@ class DescripCursosPage extends StatelessWidget {
             style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
           ),
           const SizedBox(height: 12),
-          Align(
-            alignment: Alignment.centerLeft,
-            child: TextButton.icon(
-              onPressed: () => Get.toNamed<dynamic>('/portal-sync'),
-              icon: const Icon(Icons.sync, size: 18),
-              label: const Text('Actualizar desde miUlima'),
+          // D3. Con la recarga, el botón abre la hoja y el bloque muestra sus
+          // señales. Sin ella, sigue abriendo /portal-sync.
+          if (_conRecarga)
+            RecargaSinDatos(
+              idSeccion: seccion.idSeccion,
+              alRecargar: _recargarSeccion,
+            )
+          else
+            Align(
+              alignment: Alignment.centerLeft,
+              child: TextButton.icon(
+                onPressed: () => Get.toNamed<dynamic>('/portal-sync'),
+                icon: const Icon(Icons.sync, size: 18),
+                label: const Text('Actualizar desde miUlima'),
+              ),
             ),
-          ),
         ],
       ),
     );
```

- [ ] **Paso 7. Comprueba que pasa.**

```bash
"$DART" format lib/components/recarga_ulima/pie_asistencia.dart lib/pages/descripcion_cursos/descrip_cursos.dart test/HU37_jeff/asistencia_recarga_test.dart
"$FLUTTER" test --no-pub test/HU37_jeff/asistencia_recarga_test.dart test/HU23_jeff/chat_ficha_curso_test.dart test/HU35_jeff/time_blocks_acciones_test.dart test/HU_asistencia test/HU17_ronald
"$FLUTTER" analyze --no-pub lib/components/recarga_ulima lib/pages/descripcion_cursos lib/models/seccion_model.dart test/HU37_jeff
```

**Esperado.** El formato no cambia nada, pasan las 12 pruebas de la ficha y las de la ficha, los
bloques, la asistencia y las asesorías siguen en verde sin cambios, y el análisis no encuentra
avisos.

- [ ] **Paso 8. Suite completa en segundo plano.** Como en la Tarea 4. **Esperado.** Los mismos 6
  avisos y 1383 pruebas en verde.

- [ ] **Paso 9. Commit.**

```bash
git add lib/models/seccion_model.dart lib/pages/descripcion_cursos/descrip_cursos_controller.dart lib/components/recarga_ulima/pie_asistencia.dart lib/pages/descripcion_cursos/descrip_cursos.dart test/HU37_jeff/asistencia_recarga_test.dart
git commit -m "feat(recarga-portal): el bloque de asistencia de la ficha lleva la hora de la última lectura y el botón de recarga (RF-RCG-8)"
```

---

### Tarea 10. La importación recarga la calculadora

**Requisitos.** RF-RCG-11 y D16.

**Archivos.**
- Crear `test/HU37_jeff/portal_sync_refresco_calculadora_test.dart`.
- Modificar `lib/pages/portal_sync/portal_sync_controller.dart` (`_refrescarPantallas`).

**Interfaces.**
- Consume `CalculadoraController.recargarTodo()` de la Tarea 8 y `PortalSyncController`,
  `PortalSyncService` y `PortalSyncStep` de hoy.
- Produce nada para otras tareas.

- [ ] **Paso 1. Escribe la prueba que falla.** Crea
  `test/HU37_jeff/portal_sync_refresco_calculadora_test.dart` con este contenido.

```dart
// test/HU37_jeff/portal_sync_refresco_calculadora_test.dart
//
// UNITARIA · Recarga desde la ULima (specs/features/recarga-portal/
// recarga-portal.spec.md), RF-RCG-11, la importación recarga la calculadora
// en vez de borrarla.
// Archivo probado lib/pages/portal_sync/portal_sync_controller.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/pages/calculadora/calculadora_controller.dart';
import 'package:ulima_plus/pages/portal_sync/portal_sync_controller.dart';
import 'package:ulima_plus/services/portal_sync_service.dart';

import 'recarga_dobles.dart';

/// La calculadora sin carga remota, que cuenta sus recargas.
class _CalculadoraEspia extends CalculadoraController {
  int recargas = 0;

  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  Future<void> recargarTodo() async => recargas++;
}

/// Una importación que sale bien, sin token. Todo inventado.
Map<String, dynamic> _importOk() => <String, dynamic>{
  'period': {'id': 2, 'code': '2026-2'},
  'identity': {
    'portalCode': '20230001',
    'fullName': 'Alumna De Prueba',
    'career': 'CARRERA DE PRUEBA',
  },
  'summary': {'enrollmentsUpserted': 5},
  'warnings': <dynamic>[],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  test('tras una importación exitosa, CalculadoraController sigue registrado '
      'y su recargarTodo() corre una vez', () async {
    loguear(alumna());
    final calculadora =
        Get.put<CalculadoraController>(_CalculadoraEspia())
            as _CalculadoraEspia;
    final api = ApiRecargaFalsa()
      ..responder('POST /portal-sync/import', _importOk());
    final c = PortalSyncController(service: PortalSyncService(apiClient: api));
    c.aceptarConsentimiento();
    c.passwordCtrl.text = 'clave-de-prueba';
    c.passcodeCtrl.text = '482913';

    await c.submit();

    expect(c.step.value, PortalSyncStep.done);
    expect(Get.isRegistered<CalculadoraController>(), isTrue);
    expect(Get.find<CalculadoraController>(), same(calculadora));
    expect(calculadora.recargas, 1);
  });

  test('sin la calculadora registrada, la importación no la crea', () async {
    loguear(alumna());
    final api = ApiRecargaFalsa()
      ..responder('POST /portal-sync/import', _importOk());
    final c = PortalSyncController(service: PortalSyncService(apiClient: api));
    c.aceptarConsentimiento();
    c.passwordCtrl.text = 'clave-de-prueba';
    c.passcodeCtrl.text = '482913';

    await c.submit();

    expect(c.step.value, PortalSyncStep.done);
    expect(Get.isRegistered<CalculadoraController>(), isFalse);
  });
}
```

- [ ] **Paso 2. Comprueba que falla.**

```bash
"$FLUTTER" test --no-pub test/HU37_jeff/portal_sync_refresco_calculadora_test.dart
```

**Esperado.** El primer caso falla con `Expected: true, Actual: <false>`, porque hoy
`_refrescarPantallas` borra el controller con `Get.delete`.

- [ ] **Paso 3. Implementa.** Aplica este cambio a
  `lib/pages/portal_sync/portal_sync_controller.dart`. El resto de `_refrescarPantallas` no
  cambia.

```diff
diff --git a/lib/pages/portal_sync/portal_sync_controller.dart b/lib/pages/portal_sync/portal_sync_controller.dart
--- a/lib/pages/portal_sync/portal_sync_controller.dart
+++ b/lib/pages/portal_sync/portal_sync_controller.dart
@@ -138,10 +138,12 @@ class PortalSyncController extends GetxController {
         await Get.find<HorarioController>().reload();
       }
       if (Get.isRegistered<CalculadoraController>()) {
-        // Se borra en vez de recargarlo: `recargar()` no reejecuta la carga del
-        // sílabo, así que los pesos de las evaluaciones quedarían viejos. La
-        // pestaña lo vuelve a crear al abrirse.
-        await Get.delete<CalculadoraController>(force: true);
+        // Se recarga entero en vez de borrarlo (RF-RCG-11). La fila «Notas
+        // oficiales» y el aviso de IMPORT_REQUIRED abren /portal-sync con la
+        // calculadora montada debajo, y borrar su controller deja a
+        // «Registrar Nota» sin él. `recargarTodo()` sí vuelve a pedir el
+        // sílabo, así que los pesos no quedan viejos.
+        await Get.find<CalculadoraController>().recargarTodo();
       }
       // La importación crea alertas (impedimentos, riesgo académico).
       if (Get.isRegistered<AlertService>()) {
```

- [ ] **Paso 4. Comprueba que pasa.**

```bash
"$DART" format test/HU37_jeff/portal_sync_refresco_calculadora_test.dart
"$FLUTTER" test --no-pub test/HU37_jeff/portal_sync_refresco_calculadora_test.dart test/HU34_jeff/portal_sync_consent_test.dart test/HU31_jeff
"$FLUTTER" analyze --no-pub lib/pages/portal_sync test/HU37_jeff
```

**Esperado.** El formato no cambia nada, pasan las 2 pruebas nuevas, las de `/portal-sync` siguen
en verde y el análisis no encuentra avisos.

- [ ] **Paso 5. Suite completa en segundo plano.** Como en la Tarea 4. **Esperado.** Los mismos 6
  avisos y 1385 pruebas en verde.

- [ ] **Paso 6. Commit.**

```bash
git add lib/pages/portal_sync/portal_sync_controller.dart test/HU37_jeff/portal_sync_refresco_calculadora_test.dart
git commit -m "feat(recarga-portal): la importación recarga la calculadora en vez de borrarla (RF-RCG-11)"
```

---

### Tarea 11. Cierre de la spec, de las enmiendas, del índice, del contrato y de B12

**Requisitos.** Paso 10 del flujo de `AGENTS.md` (enlazar las pruebas con `[@test]` junto al
requisito que verifican), el estado de la spec, las enmiendas de «Cambios en otras specs», la fila
21 del índice, la parte de la app del contrato, el texto único de la decisión B12 en `AGENTS.md`,
`KNOWLEDGE.md` y `README.md:102`, y la frase del README sobre la entrada a `/mis-notas`
(RF-RCG-5). Esta tarea no toca código Dart. `FECHA` es la fecha del día del cierre, en formato
`AAAA-MM-DD`.

**Archivos.**
- Modificar `specs/features/recarga-portal/recarga-portal.spec.md`.
- Modificar `specs/features/grades/grades.spec.md`, `specs/features/course-detail/course-detail.spec.md`,
  `specs/features/portal-sync/portal-sync.spec.md`,
  `specs/features/academic-record/academic-record.spec.md` y
  `specs/features/schedule/schedule.spec.md`.
- Modificar `docs/specs/api-contracts.md` y `docs/specs/feature-index.md`.
- Modificar `AGENTS.md`, `KNOWLEDGE.md` y `README.md`.

**Interfaces.**
- Consume los once archivos de prueba de `test/HU37_jeff/` de las Tareas 1 a 10.
- Produce nada para otras tareas.

- [ ] **Paso 1. Aplica los cambios de texto.** Guarda este script en el scratchpad del agente,
  por ejemplo como `cierre.py`, y córrelo desde la raíz del worktree con
  `FECHA=AAAA-MM-DD python3 <scratchpad>/cierre.py`. Cada reemplazo comprueba antes que su texto
  aparece una sola vez, así que el script se detiene sin escribir ese archivo si algo difiere de
  `ef22203`. En ese caso el cambio se hace a mano con Edit, con el mismo texto. El script no entra
  al repo.

```python
import os
from pathlib import Path

FECHA = os.environ['FECHA']
assert len(FECHA) == 10 and FECHA[4] == '-' and FECHA[7] == '-', FECHA


def cambiar(ruta, pares):
    p = Path(ruta)
    s = p.read_text(encoding='utf-8')
    for viejo, nuevo in pares:
        assert s.count(viejo) == 1, (ruta, viejo[:70])
        s = s.replace(viejo, nuevo)
    p.write_text(s, encoding='utf-8')


# 1. La spec de la recarga.
SPEC = 'specs/features/recarga-portal/recarga-portal.spec.md'
cambiar(SPEC, [
    (
        '> Estado. **Aprobada por el dueño el 2026-09-26, pendiente de implementación.** El dueño',
        f'> Estado. **Aprobada por el dueño el 2026-09-26 e implementada en la app el {FECHA}.** El dueño',
    ),
    (
        '> Las pruebas de esta spec todavía no existen. Por la regla de `specs/README.md`, esta spec no\n'
        '> lleva enlaces `[@test]` hasta que existan, y «Pruebas previstas» nombra cada archivo y sus\n'
        '> casos. Los ejemplos usan datos inventados (alumno `20230001`, curso TALLER DE PROTOTIPADO,\n'
        '> sección `812`), porque el repositorio es público.',
        '> Las pruebas de esta spec existen en `test/HU37_jeff/`, y cada requisito enlaza con `[@test]`\n'
        '> los archivos que lo verifican. Falta la revisión manual de «Verificación», y la app se publica\n'
        '> solo con las condiciones de B1 y B15. Los ejemplos usan datos inventados (alumno `20230001`,\n'
        '> curso TALLER DE PROTOTIPADO, sección `812`), porque el repositorio es público.',
    ),
    (
        'La maqueta aprobada vive fuera del repositorio, con datos inventados, y es el cambio aprobado\n'
        'sobre las maquetas de `docs/images/UI` que pide respetar `AGENTS.md`. Esta spec copia sus\n'
        'textos y sus medidas. La maqueta muestra la lista «Qué no cambia», que esta spec copia y amplía\n',
        'La maqueta aprobada queda como referencia en\n'
        '`docs/images/UI/recarga/calculadora-reorganizada.html`, con su fuente en `reorganizada.html` y\n'
        'datos inventados, y es el cambio aprobado sobre las maquetas de `docs/images/UI` que pide\n'
        'respetar `AGENTS.md`. Esta spec copia sus textos y sus medidas. La maqueta muestra la lista\n'
        '«Qué no cambia», que esta spec copia y amplía\n',
    ),
    (
        'Todas van en `test/HU37_jeff/` (D20), con datos inventados y el alumno `20230001`. Se enlazan con\n'
        '`[@test]` junto a su requisito cuando existan.',
        'Todas están en `test/HU37_jeff/` (D20), con datos inventados y el alumno `20230001`, y cada una\n'
        'se enlaza con `[@test]` junto a su requisito. Comparten los dobles de `recarga_dobles.dart`.',
    ),
    (
        '- `flutter analyze` sin avisos nuevos y `flutter test` en verde, con los avisos previos reportados\n'
        '  aparte.\n',
        '- `flutter analyze` sin avisos nuevos y `flutter test` en verde, con los avisos previos reportados\n'
        '  aparte.\n'
        '- `TZ=UTC flutter test --no-pub test/HU37_jeff/ultima_lectura_test.dart`. La suite corre solo en\n'
        '  una máquina local, porque `.github/workflows/build-apk.yml` no corre `flutter test`, y en UTC−5\n'
        '  la hora local coincide con la de Lima. Con `TZ=UTC`, las pruebas de RF-RCG-9 detectan una hora\n'
        '  o un día calculados con `toLocal()`, y el caso de las 23:59 y las 00:00 cubre el teléfono en\n'
        '  otra zona.\n',
    ),
])

PRUEBAS = {
    '### RF-RCG-2. La hoja de recarga': [
        'recarga_ulima_models_test.dart', 'recarga_ulima_service_test.dart'],
    '### RF-RCG-3. Resultado de la recarga': ['hoja_recarga_test.dart'],
    '### RF-RCG-4. El aviso rojo persistente': [
        'recarga_ulima_service_test.dart', 'hoja_recarga_test.dart',
        'mis_notas_ulima_test.dart', 'asistencia_recarga_test.dart'],
    '### RF-RCG-5. La fila «Notas oficiales» en la calculadora (cambio 1)': [
        'recarga_ulima_service_test.dart', 'mis_notas_ulima_test.dart'],
    '### RF-RCG-6. La pantalla «Notas oficiales» (`/mis-notas`, cambio 2)': [
        'calculadora_ulima_test.dart'],
    '### RF-RCG-7. Las notas de la ULima en la calculadora (cambio 3)': [
        'mis_notas_ulima_test.dart'],
    '### RF-RCG-8. La asistencia en la ficha del curso': [
        'filas_calculadora_test.dart', 'calculadora_ulima_test.dart',
        'formato_nota_test.dart'],
    '### RF-RCG-9. La hora de la última lectura': ['asistencia_recarga_test.dart'],
    '### RF-RCG-10. Modo oscuro y contraste': ['ultima_lectura_test.dart'],
    '### RF-RCG-11. La importación recarga la calculadora en vez de borrarla': [
        'contraste_recarga_test.dart'],
    '## Qué no cambia de la calculadora': [
        'portal_sync_refresco_calculadora_test.dart'],
}
p = Path(SPEC)
s = p.read_text(encoding='utf-8')
for ancla, archivos in PRUEBAS.items():
    assert s.count(ancla) == 1, ancla
    enlaces = ''.join(f'`[@test] ../../../test/HU37_jeff/{a}`\n' for a in archivos)
    s = s.replace(ancla, enlaces + '\n' + ancla)
p.write_text(s, encoding='utf-8')

# 2. Las cinco specs enmendadas.
PEND = 'aprobada por el dueño el 2026-09-26 y pendiente de implementación'
HECHA = f'aprobada por el dueño el 2026-09-26 e implementada el {FECHA}'
cambiar('specs/features/grades/grades.spec.md', [
    (PEND, HECHA),
    (
        'no en las carpetas `_aurelio`. Hasta que\n> se implemente, el código sigue el texto de esta spec.\n',
        'no en las carpetas `_aurelio`.\n\n'
        '`[@test] ../../../test/HU37_jeff/calculadora_ulima_test.dart`\n'
        '`[@test] ../../../test/HU37_jeff/filas_calculadora_test.dart`\n'
        '`[@test] ../../../test/HU37_jeff/mis_notas_ulima_test.dart`\n',
    ),
])
cambiar('specs/features/course-detail/course-detail.spec.md', [
    (PEND, HECHA),
    (
        '> parcial encima del botón. Sin `RecargaUlimaService` registrado, el bloque queda como hoy.\n'
        '> Hasta que se implemente, el código sigue el texto de esta spec.\n',
        '> parcial encima del botón. Sin `RecargaUlimaService` registrado, el bloque queda como hoy.\n\n'
        '`[@test] ../../../test/HU37_jeff/asistencia_recarga_test.dart`\n',
    ),
])
cambiar('specs/features/portal-sync/portal-sync.spec.md', [
    (PEND, HECHA),
    (
        '> Hasta que se implemente, el código sigue el texto de esta spec.\n',
        '\n`[@test] ../../../test/HU37_jeff/portal_sync_refresco_calculadora_test.dart`\n'
        '`[@test] ../../../test/HU37_jeff/hoja_recarga_test.dart`\n',
    ),
])
cambiar('specs/features/academic-record/academic-record.spec.md', [(PEND, HECHA)])
cambiar('specs/features/schedule/schedule.spec.md', [(PEND, HECHA)])

# 3. El contrato, solo en lo que es de la app.
cambiar('docs/specs/api-contracts.md', [
    (
        'Hoy lo lee `/mis-notas` (`official_grades_service.dart:40-47`).',
        'Desde RF-RCG-6 ninguna pantalla de alumno lo lee (`official_grades_service.dart:40-47`).',
    ),
    (
        '*Aprobado el 2026-09-26, pendiente de implementación (decisión B10 de',
        f'*Aprobado el 2026-09-26 e implementado en la app el {FECHA} (decisión B10 de',
    ),
])

# 4. El índice, fila 21.
cambiar('docs/specs/feature-index.md', [(
    '(hueco 5). Pendiente de implementación. Depende de la spec del backend',
    f'(hueco 5). Implementada en la app el {FECHA}, con sus pruebas en `test/HU37_jeff/`, y falta la '
    'revisión manual de «Verificación». Depende de la spec del backend',
)])

# 5. El texto único de B12.
B12 = ('Las notas que el alumno registra en la calculadora son personales y no oficiales '
       '(`simulated_grades`). La calculadora muestra además, fijas y con la marca “ULima”, las '
       'notas parciales que publica la ULima, que guarda la tabla `student_portal_score`, escribe '
       'solo `POST /portal-sync/refresh` y lee `GET /grades/me/ulima`.')
cambiar('AGENTS.md', [('- Las notas son personales no oficiales.\n', f'- {B12}\n')])
cambiar('KNOWLEDGE.md', [('- Las notas son personales, no oficiales.\n', f'- {B12}\n')])

# 6. El README.
SPEC_LINK = '[`specs/features/recarga-portal`](specs/features/recarga-portal/recarga-portal.spec.md)'
cambiar('README.md', [
    (
        'Última precisión, porque se malinterpreta seguido: **las notas de la calculadora son personales y no oficiales** (`AGENTS.md:58`, `KNOWLEDGE.md:72`, `README.md:81`). La pestaña *Notas* es una calculadora donde el alumno registra lo que él cree que sacó, y la app **no** calcula riesgo académico con esas notas: las alertas llegan hechas de `GET /alerts/me` (`alert_service.dart:35`) y el backend las deriva de las notas **oficiales** de `student_score`, con los umbrales `ACADEMIC_RISK_MIN_PROGRESS = 55` y `ACADEMIC_RISK_MAX_AVERAGE = 10.5` (`alerts.logic.ts:6,8` del backend). Lo oficial está en otra pantalla, `/mis-notas`, que lee `GET /official-grades/me` y es de **solo lectura**; se llega a ella desde el ícono `school_outlined` con tooltip "Notas oficiales" de la propia calculadora (`calculadora_page.dart:31-46`). Nunca se mezclan. En la misma línea,',
        f'Última precisión, porque se malinterpreta seguido. **{B12}** Es el texto único de la decisión B12 de {SPEC_LINK}, el mismo de `AGENTS.md:58` y `KNOWLEDGE.md:72`. La pestaña *Notas* es una calculadora donde el alumno registra la nota que cree tener, y la app **no** calcula riesgo académico con esas notas ni con las de la ULima, porque las alertas llegan hechas de `GET /alerts/me` (`alert_service.dart:35`) y el backend las deriva de las notas que carga el docente en `student_score`, con los umbrales `ACADEMIC_RISK_MIN_PROGRESS = 55` y `ACADEMIC_RISK_MAX_AVERAGE = 10.5` (`alerts.logic.ts:6,8` del backend). Las notas oficiales están en `/mis-notas`, que lee `GET /grades/me/ulima` y es de **solo lectura**, y se llega a ella desde la fila «Notas oficiales» del encabezado de la calculadora (`fila_notas_oficiales.dart`, RF-RCG-5). Las dos clases de notas conviven en la calculadora, pero las de la ULima nunca se guardan en `simulated_grades` ni se borran desde ella. En la misma línea,',
    ),
    (
        '| Alumno | Notas personales por evaluación y promedio ponderado | `CoursesService`, `EvaluationSyllabusService`, `ApiClient` |',
        '| Alumno | Notas personales por evaluación y promedio ponderado, con las notas que publica la ULima y la fila «Notas oficiales» | `CoursesService`, `EvaluationSyllabusService`, `ApiClient`, `RecargaUlimaService` |',
    ),
    (
        '| Alumno | Notas **oficiales** publicadas por el docente, solo lectura | `OfficialGradesService` |',
        '| Alumno | Notas **oficiales** que publica la ULima por evaluación, solo lectura, con la franja y la hoja de recarga | `RecargaUlimaService`, `EvaluationSyllabusService` |',
    ),
    (
        '| Alumno | Detalle de sección: dona de asistencia + 3 pestañas y el botón «Chat del curso» | `SeccionService`, `AnuncioService`, `AsesoriaService`, `ContactoService` |',
        '| Alumno | Detalle de sección con la dona de asistencia, la hora de su última lectura y el botón de recarga, 3 pestañas y el botón «Chat del curso» | `SeccionService`, `AnuncioService`, `AsesoriaService`, `ContactoService`, `RecargaUlimaService` |',
    ),
    (
        '1. Header `Calculadora de Notas`, contador `Cursos con notas: N` y un `IconButton` `school_outlined` con\n'
        '   tooltip **Notas oficiales** → `/mis-notas` (`calculadora_page.dart:31-46`).',
        '1. Header `Calculadora de Notas`, contador `Cursos con notas: N` y la fila **Notas oficiales**, con la\n'
        '   hora de la última lectura de la ULima, que lleva a `/mis-notas` (`fila_notas_oficiales.dart`, RF-RCG-5).',
    ),
    (
        "9. **Notas oficiales** (`/mis-notas`): `GET /official-grades/me`, nota final ponderada en cliente con el\n"
        "   mismo dominio `notas_calculo.calcularPromedioPonderado`, solo lectura, `AppBar 'Notas oficiales'`.",
        "9. **Notas oficiales** (`/mis-notas`) lee `GET /grades/me/ulima` por `RecargaUlimaService`, con la nota\n"
        "   final ponderada en el cliente con `notas_calculo.calcularPromedioPonderado`, solo lectura y con la\n"
        "   franja que abre la hoja de recarga (RF-RCG-6). Las notas que ya publica la ULima entran a la\n"
        "   calculadora con la marca «ULima», sin tacho, y nunca se guardan en `simulated_grades` (RF-RCG-7).",
    ),
    ('#### Notas oficiales — 4 métodos', '#### Notas oficiales — 6 métodos'),
    (
        '| `official_grades_service.dart` | `fetchMyOfficialCourses` :40 | `GET /official-grades/me` | `List<OfficialCourse>` | `MisNotasController.load` :32 → `/mis-notas` |\n',
        '| `official_grades_service.dart` | `fetchMyOfficialCourses` :40 | `GET /official-grades/me` | `List<OfficialCourse>` | ninguna pantalla desde RF-RCG-6 (decisión B10), y la ruta sigue en el backend |\n'
        '| `recarga_ulima_service.dart` | `cargar` | `GET /grades/me/ulima`, plazo 15 s | `VistaUlima`; nunca lanza, y un fallo deja `errorCarga` sin borrar la vista | `MisNotasController.load`, `CalculadoraController.conectarUlima` y `recargarTodo`, y «Cargar mis datos» |\n'
        '| `recarga_ulima_service.dart` | `recargar` | `POST /portal-sync/refresh` body `{credentials:{password, passcode}, consent: true}`, plazo 90 s | `bool`; un error deja `ultimoAviso` con el texto de RF-RCG-4 | `HojaRecargaUlima`, desde `/mis-notas` y la ficha del curso |\n',
    ),
    (
        'Recorrido real de `/mis-notas`, la implementación más limpia del patrón: página → controller →\n'
        'service → `ApiClient` → backend → modelo → estado observable → repintado.',
        'Recorrido de `/mis-notas` hasta `ef22203`, la implementación más limpia del patrón (página,\n'
        'controller, service, `ApiClient`, backend, modelo, estado observable y repintado). Desde RF-RCG-6 el\n'
        'controller lee `RecargaUlimaService` en lugar de `OfficialGradesService`, con el mismo recorrido.',
    ),
])
p = Path('README.md')
s = p.read_text(encoding='utf-8')
fila_hu31 = next(l for l in s.split('\n') if l.startswith('| [`test/HU31_jeff/`](test/HU31_jeff) |'))
fila_hu37 = ('| [`test/HU37_jeff/`](test/HU37_jeff) | HU-RCG-01 a HU-RCG-03, recarga desde la ULima | jeff | 11 | 162 | '
             'Unitaria + Widget | Modelos tolerantes de `GET /grades/me/ulima`; formato del peso, de la nota y de la hora en '
             'Lima; contraste de RF-RCG-10; `RecargaUlimaService` con el cuerpo exacto, cada aviso de RF-RCG-4, el dueño de '
             'los datos y el plazo de D23; la hoja de recarga; `/mis-notas` con la franja y el aviso; las filas de la '
             'calculadora con la marca «ULima»; el bloque de asistencia de la ficha, y la importación que recarga la '
             'calculadora |')
assert s.count(fila_hu31) == 1
s = s.replace(fila_hu31, fila_hu31 + '\n' + fila_hu37)
p.write_text(s, encoding='utf-8')
print('cierre aplicado')
```

  El script hace estos cambios.
  - En la spec de la recarga, el estado pasa a «implementada en la app el FECHA», el párrafo de
    las pruebas dice que existen y que falta la revisión manual y las condiciones de B1 y B15, la
    maqueta queda en `docs/images/UI/recarga/`, «Pruebas previstas» dice que todas existen, cada
    requisito, de RF-RCG-1 a RF-RCG-11, termina con los enlaces `[@test]` de sus archivos y
    «Verificación» suma la corrida de `ultima_lectura_test.dart` con `TZ=UTC`.
  - En `grades.spec.md`, `course-detail.spec.md`, `portal-sync.spec.md`,
    `academic-record.spec.md` y `schedule.spec.md`, la enmienda pasa de «pendiente de
    implementación» a «implementada el FECHA», sale la frase «Hasta que se implemente…» y las tres
    primeras suman sus enlaces `[@test]`.
  - En `api-contracts.md`, solo la sección Official Grades, que es de la app, dice que ninguna
    pantalla de alumno lee `GET /official-grades/me` y que el cambio de B10 está implementado en
    la app. Las rutas del backend siguen como pendientes, porque las implementa el otro repo.
  - En la fila 21 del índice, «Pendiente de implementación.» pasa a «Implementada en la app el
    FECHA, con sus pruebas en `test/HU37_jeff/`, y falta la revisión manual de «Verificación».».
  - `AGENTS.md:58` y `KNOWLEDGE.md:72` pasan al texto único de B12, el mismo del backend.
  - En `README.md`, la línea 102 lleva el texto de B12, la fuente nueva de `/mis-notas` y la fila
    «Notas oficiales» como entrada; las filas de `CalculadoraPage`, `MisNotasPage` y
    `DescripCursosPage` de la tabla de pantallas suman `RecargaUlimaService`; los puntos 1 y 9 de
    «Calculadora de notas» describen la fila y la fuente nuevas; la tabla «Notas oficiales» suma
    los dos métodos del servicio; el recorrido de `/mis-notas` avisa que su diagrama es el de
    `ef22203`; y «La matriz completa» suma la fila de `test/HU37_jeff/`, sin tocar la fila TOTAL,
    que ya está desactualizada desde antes de esta rama.

- [ ] **Paso 2. Revisa el diff.** Corre `git diff --stat` y `git diff` y lee cada cambio. Solo
  cambian los once archivos de la lista, y ningún enlace `[@test]` apunta a un archivo que no
  existe.

```bash
git diff --stat
grep -rhoE '\[@test\] \.\./\.\./\.\./test/HU37_jeff/[a-z_]+\.dart' specs | sed 's#.*/test/#test/#' | sort -u | while read f; do test -f "$f" || echo "FALTA $f"; done
```

**Esperado.** Once archivos cambiados y ninguna línea `FALTA`.

- [ ] **Paso 3. Verificación final.** Corre en primer plano el formato, las dos búsquedas y
  `ultima_lectura_test.dart` con `TZ=UTC`, y en segundo plano el análisis y la suite completa,
  esperando sus notificaciones.

```bash
"$DART" format --output=none --set-exit-if-changed lib/models/recarga_ulima_models.dart lib/domain/recarga_ulima lib/services/recarga_ulima_service.dart lib/components/recarga_ulima lib/components/calculadora/nota_tile.dart lib/components/calculadora/curso_card.dart lib/pages/mis_notas lib/pages/descripcion_cursos/descrip_cursos.dart lib/configs/themes.dart test/HU37_jeff
git diff ef22203 -- . ':(exclude)docs/superpowers/plans' | grep '^+' | grep -nE '/Users/|/private/|/tmp/|/home/'
git diff ef22203 -- . | grep '^+' | grep -oE '\b[0-9]{8}\b' | sort -u
TZ=UTC "$FLUTTER" test --no-pub test/HU37_jeff/ultima_lectura_test.dart
"$FLUTTER" analyze --no-pub      # en segundo plano
"$FLUTTER" test --no-pub         # en segundo plano
```

**Esperado.** El formato no cambia nada, la búsqueda de rutas no encuentra nada, los únicos
códigos de ocho dígitos son `20230001` y `20230002`, la corrida con `TZ=UTC` pasa las 8 pruebas de
`ultima_lectura_test.dart`, `analyze` da los mismos 6 avisos de la línea base y la suite pasa con
1385 pruebas.

- [ ] **Paso 4. Commit.**

```bash
git add specs/features/recarga-portal/recarga-portal.spec.md specs/features/grades/grades.spec.md specs/features/course-detail/course-detail.spec.md specs/features/portal-sync/portal-sync.spec.md specs/features/academic-record/academic-record.spec.md specs/features/schedule/schedule.spec.md docs/specs/api-contracts.md docs/specs/feature-index.md AGENTS.md KNOWLEDGE.md README.md
git commit -m "docs(recarga-portal): la spec queda implementada en la app, con sus [@test], las enmiendas, el índice, el contrato, el README y el texto de B12"
git log -1 --format='%an <%ae>'
```

## Cobertura de la spec

| Parte de la spec | Tarea | Prueba |
|---|---|---|
| RF-RCG-1, modelos y lectura tolerante | 1 | `recarga_ulima_models_test.dart` |
| RF-RCG-1, `cargar`, `recargar`, cuerpo exacto, plazo de 90 s, `enviando` y `clear` | 4 | `recarga_ulima_service_test.dart`, grupos de carga y de la recarga |
| RF-RCG-1, contraseña y código fuera de todo registro | 4 y 5 | el caso del espía de registros y los de cierre de la hoja |
| RF-RCG-1, dueño de los datos sin `logout()` y `logout()` con y sin el servicio | 4 | `recarga_ulima_service_test.dart`, grupo de carga y dueño |
| RF-RCG-1 y D23, plazo vencido o fallo de red | 4 | `recarga_ulima_service_test.dart`, grupo de D23 |
| RF-RCG-2, forma, textos, botón, espera y cierre, y D4, D12, D13 y D14 | 5 | `hoja_recarga_test.dart` |
| RF-RCG-2, forma por defecto de `PasswordResetOtpField` | 5 | `hoja_recarga_test.dart`, primer grupo, y `otp_field_ime_test.dart`, `registro_page_test.dart` y `portal_sync_consent_test.dart` sin cambios |
| RF-RCG-3, éxito con una sola llamada a `reload()` y `recargaHorario` | 4 | `recarga_ulima_service_test.dart` |
| RF-RCG-3, la hoja se cierra y vacía con éxito y con error | 5 | `hoja_recarga_test.dart` |
| RF-RCG-3, lectura parcial en `/mis-notas` y en la ficha | 6 y 9 | `mis_notas_ulima_test.dart` y `asistencia_recarga_test.dart` |
| RF-RCG-4, tabla de mensajes y acciones, `1 minuto` y `N minutos`, B19 y `401` | 4 | `recarga_ulima_service_test.dart`, casos de RF-RCG-4 |
| RF-RCG-4, forma del aviso, `liveRegion`, «Reintentar» y «Cargar mis datos» | 6 | `mis_notas_ulima_test.dart`, grupo del aviso |
| RF-RCG-5, fila «Notas oficiales», segunda línea, toque, tres estados y accesibilidad | 8 | `calculadora_ulima_test.dart`, grupo de la fila |
| RF-RCG-6, fuente, franja, tarjetas, filas, insignia «Final», estados y flecha | 6 | `mis_notas_ulima_test.dart` |
| RF-RCG-7, qué entra, las dos notas, orden, índice de borrado y qué cursos se ven | 7 | `filas_calculadora_test.dart` |
| RF-RCG-7, `NotaTile`, marca «ULima», promedio, suma de pesos, guardado, «Registrar Nota» y D15 | 8 | `calculadora_ulima_test.dart` y el grupo del guardado de `filas_calculadora_test.dart` |
| RF-RCG-7, «Qué no cambia de la calculadora» | 8 | `HU07_sam`, `HU06_sam` y `chats_pestana_test.dart` sin cambios |
| RF-RCG-8, pie con hora y botón, estado sin datos, aviso compacto, `recargarSeccion` y sin el servicio | 9 | `asistencia_recarga_test.dart`, más `chat_ficha_curso_test.dart` y `time_blocks_acciones_test.dart` sin cambios |
| RF-RCG-8, `Seccion.asistenciaLeidaEn` | 9 | `asistencia_recarga_test.dart`, grupo unitario |
| RF-RCG-9 | 2 | `ultima_lectura_test.dart`, también con `TZ=UTC` |
| RF-RCG-10, contrastes salvo D12 y D24 | 3 | `contraste_recarga_test.dart` |
| RF-RCG-10, 48 por 48, tooltips, encabezado, etiquetas y `liveRegion` | 5, 6, 8 y 9 | los casos de Semantics y de tamaño de cada archivo de widget |
| RF-RCG-11 y D16 | 10 | `portal_sync_refresco_calculadora_test.dart` |
| D10 | 2 | `formato_nota_test.dart` |
| «Cambios en otras specs», B12, README, índice y contrato | 11 | revisión del diff del Paso 2 |
| «Verificación», análisis y suite | todas | los pasos de verificación de cada tarea |

## Fuera del plan

- La revisión manual de «Verificación» en un iPhone SE, en claro y en oscuro, con el texto al 200 %
  y con VoiceOver, de la fila, la franja, la hoja con el teclado abierto, el aviso y el bloque de
  asistencia, y la misma revisión en Android con TalkBack. La hace el dueño después de la Tarea 11,
  con el backend de RS-BE-48 a RS-BE-60 en un entorno de prueba.
- La publicación. La app sale solo con el backend de RS-BE-48 a RS-BE-60 desplegado (decisión
  B1), con `PORTAL_REFRESH_BUDGET_MS` dentro de la cota de RS-BE-50 y con la medición de B15
  hecha. La migración `0015` se aplica en producción solo con un respaldo y el permiso del dueño en
  el momento del despliegue. Ningún paso de este plan despliega nada, toca una base de datos ni
  hace push.
- Los contrastes que la spec deja por debajo de 4,5:1 a propósito, el botón «Actualizar» de la
  hoja (D12) y el texto `Nota: …/20` de las filas de la ULima (D24), siguen como en el resto de la
  app.
