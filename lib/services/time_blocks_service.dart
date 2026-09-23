import 'dart:async';

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

  /// La ventana de la foto que hay en [_snapshot]. Se asigna solo cuando una
  /// carga termina bien y se vacía cuando una falla: tras un fallo, o
  /// mientras llega la ventana nueva, la foto que queda no cuenta como la
  /// pedida.
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
      // La foto que quede no cuenta como la de esta ventana, así que el
      // siguiente load() sin force la vuelve a pedir. Sin esto, la recarga
      // fallida que sigue a una escritura dejaba la ventana marcada como
      // cargada, y ni volver a la pestaña ni cambiar de día la reintentaban.
      _loadedFrom = null;
      _loadedTo = null;
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
  /// nada. Si falla, lanza [TimeBlocksFailure]: con un rechazo del servidor
  /// no recarga, y sin respuesta recarga sin esperar ([_escribir]).
  Future<TimeBlockRule> create(TimeBlockInput input) async {
    final json = await _escribir(
      () => _api.postJson('/time-blocks/me', body: input.toJson()),
    );
    final bloque = TimeBlockRule.fromJson(json['block']);
    _ponerRegla(bloque);
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
    _ponerRegla(bloque);
    await reload();
    return bloque;
  }

  /// Deja en [blocks] la regla que devolvió el servidor, en lugar de la del
  /// mismo id si ya estaba, antes de recargar. Si la recarga falla, el aviso
  /// de cruce del formulario ya ve el bloque guardado y la alumna no lo crea
  /// otra vez. Solo completa la copia del usuario actual.
  void _ponerRegla(TimeBlockRule regla) {
    if (!_esDelUsuarioActual) return;
    final i = _blocks.indexWhere((b) => b.id == regla.id);
    if (i < 0) {
      _blocks.add(regla);
    } else {
      _blocks[i] = regla;
    }
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
      // Sin respuesta (red caída o plazo vencido), la escritura pudo quedar
      // guardada en el servidor. Se recarga la ventana sin esperar: si se
      // guardó, la grilla y el aviso de cruce la ven y la alumna no la repite.
      unawaited(reload());
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
