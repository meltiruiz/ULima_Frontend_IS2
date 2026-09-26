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
import 'package:ulima_plus/services/malla_service.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';
import 'package:ulima_plus/services/storage_service.dart';

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
  _authService();
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

    test('caso 12b: la evaluación del mismo alumno espera a la que sigue en '
        'vuelo y sale cuando esta termina', () async {
      _loguear();
      final primera = Completer<Map<String, dynamic>>();
      final api = ApiFalsaDelTest(evaluaciones: [primera, resultadoJson()]);
      final s = _servicio(api);
      final a = s.evaluate(const {'n': 1});
      final b = s.evaluate(const {'n': 2});
      await pumpEventQueue();
      expect(api.cuerposDeEvaluacion, [
        {'n': 1},
      ]);
      primera.complete(desempateJson());
      expect(await a, isA<TiebreakStep>());
      expect(await b, isA<ResultStep>());
      expect(api.cuerposDeEvaluacion, [
        {'n': 1},
        {'n': 2},
      ]);
    });

    testWidgets('caso 12c: si la anterior vence a los 20 s, la que espera '
        'sale en ese momento', (tester) async {
      _loguear();
      final api = ApiFalsaDelTest(
        evaluaciones: [Completer<Map<String, dynamic>>(), resultadoJson()],
      );
      final s = _servicio(api);
      Object? error;
      unawaited(
        s
            .evaluate(const {'n': 1})
            .then((_) {}, onError: (Object e) => error = e),
      );
      EvaluationStep? paso;
      unawaited(s.evaluate(const {'n': 2}).then((p) => paso = p));
      await tester.pump(const Duration(seconds: 19, milliseconds: 999));
      expect(api.cuerposDeEvaluacion, hasLength(1));
      await tester.pump(const Duration(milliseconds: 1));
      expect(
        (error! as SpecialtyTestFailure).kind,
        SpecialtyTestFailureKind.offline,
      );
      expect(api.cuerposDeEvaluacion, hasLength(2));
      expect(paso, isA<ResultStep>());
    });

    test('caso 12d: otro alumno no espera la evaluación del anterior, y la '
        'que esperaba con el anterior ya no sale', () async {
      final auth = _loguear();
      final primera = Completer<Map<String, dynamic>>();
      final api = ApiFalsaDelTest(evaluaciones: [primera, resultadoJson()]);
      final s = _servicio(api);
      unawaited(
        s.evaluate(const {'n': 1}).then((_) {}, onError: (Object _) {}),
      );
      Object? error;
      unawaited(
        s
            .evaluate(const {'n': 2})
            .then((_) {}, onError: (Object e) => error = e),
      );
      auth.userRx.value = alumno(code: 'alumna.b.test');
      expect(await s.evaluate(const {'n': 3}), isA<ResultStep>());
      primera.complete(desempateJson());
      await pumpEventQueue();
      expect(api.cuerposDeEvaluacion, [
        {'n': 1},
        {'n': 3},
      ]);
      expect(error, isA<SpecialtyTestFailure>());
    });
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
    test('caso 19: lo que llega después de un clear() se descarta, aunque el '
        'alumno siguiente ya sea el dueño', () async {
      final auth = _loguear();
      final contenido = Completer<Map<String, dynamic>>();
      final resultado = Completer<Map<String, dynamic>>();
      final contenidoDeB = Completer<Map<String, dynamic>>();
      final api = ApiFalsaDelTest(
        contenido: [contenido, contenidoDeB],
        resultados: [resultado],
      );
      final s = _servicio(api);
      final pedido = s.fetchContent();
      final ultimo = s.loadLastResult();
      s.clear();
      // La alumna siguiente entra y su pedido la hace dueña antes de que
      // lleguen las respuestas del anterior. Con un dueño puesto, los getters
      // ya no ocultan nada, y solo el chequeo de generación las descarta.
      auth.userRx.value = alumno(code: 'alumna.b.test');
      final pedidoDeB = s.fetchContent();
      contenido.complete(contenidoJson());
      resultado.complete(ultimoResultadoJson());
      await pedido;
      await ultimo;
      expect(s.content, isNull);
      expect(s.lastResult, isNull);
      expect(s.lastResultStatus, LastResultStatus.loading);
      contenidoDeB.complete(contenidoJson(version: '2026-09-25.5'));
      expect((await pedidoDeB).version, '2026-09-25.5');
      expect(s.content!.version, '2026-09-25.5');
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
