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

  /// Termina cuando la última evaluación pedida del dueño actual responde o
  /// vence su plazo. La siguiente la espera, así que nunca hay dos en vuelo,
  /// aunque la ruta que la pide se cierre y otra siga el test (RF-TEST-7).
  Future<void>? _evaluateInFlight;

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
    _evaluateInFlight = null;
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
  ///
  /// Si otra evaluación del mismo alumno sigue en vuelo, esta sale cuando
  /// aquella responde o vence, y mientras tanto no sale nada (RF-TEST-7).
  /// Una que espera y encuentra otro dueño al salir no se manda.
  Future<EvaluationStep> evaluate(Map<String, dynamic> body) async {
    _adoptarDueno();
    final generation = _generation;
    final anterior = _evaluateInFlight;
    final propia = Completer<void>();
    _evaluateInFlight = propia.future;
    try {
      if (anterior != null) {
        await anterior;
        if (generation != _generation) {
          throw const SpecialtyTestFailure(SpecialtyTestFailureKind.server);
        }
      }
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
    } finally {
      propia.complete();
      if (identical(_evaluateInFlight, propia.future)) {
        _evaluateInFlight = null;
      }
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
