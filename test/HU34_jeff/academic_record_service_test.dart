// test/HU34_jeff/academic_record_service_test.dart
//
// UNITARIA — HU34 (récord académico): AcademicRecordService (RF-REC-5).
// Servicio: lib/services/academic_record_service.dart
//
// Estado único del récord: caché por usuario, guarda de docente, respuestas
// viejas, borrado e invalidación tras importar.
//
// Datos inventados: ningún valor sale de un récord real, y son los mismos que
// usa test/HU34_jeff/academic_record_model_test.dart.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/services/academic_record_service.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/portal_sync_service.dart';

UserModel _user({String code = '20230001', String role = 'student'}) =>
    UserModel(
      code: code,
      firstName: 'Alumna',
      lastName: 'De Prueba',
      email: 'test@aloe.ulima.edu.pe',
      role: role,
      currentCycle: '2026-1',
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

class _FakeRecordApi extends ApiClient {
  _FakeRecordApi(this.getResponses) : super(configuredBaseUrl: 'http://test');

  /// Respuestas del GET, en orden; la última se repite. Un Map se devuelve,
  /// un Completer se espera y cualquier otra cosa se lanza.
  final List<Object> getResponses;
  Object? deleteError;
  int getCalls = 0;
  int deleteCalls = 0;
  String? lastGetPath;
  String? lastDeletePath;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    String? token,
    Map<String, String?> query = const {},
    bool suppressSessionExpiry = false,
  }) async {
    lastGetPath = path;
    final i =
        getCalls < getResponses.length ? getCalls : getResponses.length - 1;
    final r = getResponses[i];
    getCalls++;
    if (r is Completer<Map<String, dynamic>>) return r.future;
    if (r is Map<String, dynamic>) return r;
    throw r;
  }

  @override
  Future<Map<String, dynamic>> deleteJson(String path, {String? token}) async {
    deleteCalls++;
    lastDeletePath = path;
    if (deleteError != null) throw deleteError!;
    return <String, dynamic>{'ok': true};
  }
}

Map<String, dynamic> _syncedJson({Object? ppa = 14.62}) => <String, dynamic>{
      'syncedAt': '2026-09-18T15:00:00Z',
      'snapshot': <String, dynamic>{
        'ppa': ppa,
        'relativePosition': 'TERCIO SUPERIOR',
        'creditsAccumulated': 120,
        'creditsRequired': 200,
        'approved': <String, dynamic>{'courses': 40, 'credits': 118},
        'convalidated': <String, dynamic>{'courses': 1, 'credits': 2},
      },
      'periods': <dynamic>[],
      'record': <dynamic>[
        <String, dynamic>{
          'periodCode': '2026-1',
          'courses': <dynamic>[
            <String, dynamic>{
              'code': '100001',
              'name': 'CURSO DE PRUEBA A',
              'attempt': 1,
              'credits': 3,
              'grade': null,
              'gradeRaw': null,
              'section': '917',
              'observation': null,
            },
          ],
        },
      ],
    };

Map<String, dynamic> _neverSyncedJson() => <String, dynamic>{
      'syncedAt': null,
      'snapshot': null,
      'periods': <dynamic>[],
      'record': <dynamic>[],
    };

_FakeAuthService _loguear(UserModel? user) {
  final auth = _FakeAuthService(user);
  Get.put<AuthService>(auth);
  return auth;
}

AcademicRecordService _servicio(_FakeRecordApi api) =>
    Get.put<AcademicRecordService>(AcademicRecordService(apiClient: api));

PortalSyncService _portalSync() =>
    PortalSyncService(apiClient: ApiClient(configuredBaseUrl: 'http://test'));

void main() {
  // Get.put de un GetxService agenda onReady con
  // Get.engine.addPostFrameCallback, que necesita el binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(Get.reset);
  tearDown(Get.reset);

  group('UNITARIA · AcademicRecordService (HU34)', () {
    test('caso 1: un alumno pide GET /academic-record/me una vez y guarda el récord',
        () async {
      _loguear(_user());
      final api = _FakeRecordApi([_syncedJson()]);
      final s = _servicio(api);

      await s.load();

      expect(api.lastGetPath, '/academic-record/me');
      expect(api.getCalls, 1);
      expect(s.record!.snapshot!.ppa, 14.62);
      expect(s.isLoading, isFalse);
      expect(s.hasError, isFalse);
    });

    test('caso 2: sin force no vuelve a pedir; con force sí', () async {
      _loguear(_user());
      final api = _FakeRecordApi([_syncedJson(), _syncedJson(ppa: 15.1)]);
      final s = _servicio(api);

      await s.load();
      await s.load();
      expect(api.getCalls, 1);

      await s.load(force: true);
      expect(api.getCalls, 2);
      expect(s.record!.snapshot!.ppa, 15.1);
    });

    test('caso 3: un docente o una sesión sin usuario nunca disparan el GET',
        () async {
      final auth = _loguear(_user(code: 'docente.test', role: 'teacher'));
      final api = _FakeRecordApi([_syncedJson()]);
      final s = _servicio(api);

      await s.load();
      await s.load(force: true);
      await s.reload();
      expect(api.getCalls, 0);
      expect(s.record, isNull);
      expect(s.isLoading, isFalse);

      auth.userRx.value = null;
      await s.load(force: true);
      expect(api.getCalls, 0);
      expect(s.record, isNull);
    });

    test(
        'caso 4: un fallo no lanza: deja hasError y ningún récord, y el '
        'siguiente load() reintenta', () async {
      _loguear(_user());
      final errores = <Object>[
        Exception('socket'),
        ApiException(statusCode: 500, code: 'HTTP_ERROR', message: 'x'),
      ];
      for (final error in errores) {
        final api = _FakeRecordApi([error, _syncedJson()]);
        // Sin registrarlo: load() solo busca AuthService.
        final s = AcademicRecordService(apiClient: api);

        await expectLater(s.load(), completes);
        expect(s.hasError, isTrue, reason: '$error');
        expect(s.record, isNull, reason: '$error');
        expect(s.isLoading, isFalse, reason: '$error');

        await s.load();
        expect(api.getCalls, 2, reason: 'un fallo no deja la caché marcada');
        expect(s.hasError, isFalse);
        expect(s.record!.snapshot!.ppa, 14.62);
      }
    });

    test('caso 5: dos load() simultáneos hacen un solo GET', () async {
      _loguear(_user());
      final pendiente = Completer<Map<String, dynamic>>();
      final api = _FakeRecordApi([pendiente]);
      final s = _servicio(api);

      final a = s.load();
      final b = s.load();
      expect(s.isLoading, isTrue);

      pendiente.complete(_syncedJson());
      await Future.wait([a, b]);
      expect(api.getCalls, 1);
      expect(s.record!.snapshot!.ppa, 14.62);
      expect(s.isLoading, isFalse);
    });

    test('caso 6: otro usuario sin logout de por medio nunca ve el récord anterior',
        () async {
      final auth = _loguear(_user());
      final api = _FakeRecordApi([_syncedJson(), _neverSyncedJson()]);
      final s = _servicio(api);
      await s.load();
      expect(s.record, isNotNull);

      auth.userRx.value = _user(code: 'otro.alumno.test');
      expect(s.record, isNull, reason: 'ni siquiera antes de llamar a load()');

      await s.load();
      expect(api.getCalls, 2);
      expect(s.record!.hasRecord, isFalse);
    });

    test('caso 7: una respuesta que llega después de clear() se descarta',
        () async {
      _loguear(_user());
      final vieja = Completer<Map<String, dynamic>>();
      final nueva = Completer<Map<String, dynamic>>();
      final api = _FakeRecordApi([vieja, nueva]);
      final s = _servicio(api);

      unawaited(s.load());
      s.clear();
      final f = s.load();

      vieja.complete(_syncedJson());
      await Future<void>.delayed(Duration.zero);
      expect(s.record, isNull, reason: 'la respuesta vieja no se pinta');
      expect(s.isLoading, isTrue, reason: 'la carga nueva sigue en vuelo');

      nueva.complete(_syncedJson(ppa: 15.1));
      await f;
      expect(s.record!.snapshot!.ppa, 15.1);
      expect(s.isLoading, isFalse);
      expect(api.getCalls, 2);
    });

    test('caso 8: reload() vacía el estado antes de pedir', () async {
      _loguear(_user());
      final segundo = Completer<Map<String, dynamic>>();
      final api = _FakeRecordApi([_syncedJson(), segundo]);
      final s = _servicio(api);
      await s.load();

      final f = s.reload();
      expect(s.record, isNull, reason: 'nunca se ve el PPA anterior');
      expect(s.isLoading, isTrue);

      segundo.complete(_syncedJson(ppa: 15.1));
      await f;
      expect(s.record!.snapshot!.ppa, 15.1);
    });

    test(
        'caso 9: deleteRecord llama al DELETE, muestra el estado vacío al '
        'instante y recarga', () async {
      _loguear(_user());
      final recarga = Completer<Map<String, dynamic>>();
      final api = _FakeRecordApi([_syncedJson(), recarga]);
      final s = _servicio(api);
      await s.load();

      final f = s.deleteRecord();
      await Future<void>.delayed(Duration.zero);
      expect(api.deleteCalls, 1);
      expect(api.lastDeletePath, '/academic-record/me');
      expect(s.record, isNotNull,
          reason: 'el estado vacío se ve sin esperar la recarga');
      expect(s.record!.hasRecord, isFalse);
      expect(api.getCalls, 2, reason: 'recarga para confirmar el borrado');

      recarga.complete(_neverSyncedJson());
      await f;
      expect(s.record!.hasRecord, isFalse);
      expect(s.isLoading, isFalse);
    });

    test('caso 10: si la recarga posterior al DELETE falla, el estado sigue vacío',
        () async {
      _loguear(_user());
      final api = _FakeRecordApi([_syncedJson(), Exception('socket')]);
      final s = _servicio(api);
      await s.load();

      await s.deleteRecord();

      expect(s.record, isNotNull);
      expect(s.record!.hasRecord, isFalse);
      expect(api.getCalls, 2);
    });

    test('caso 11: si el DELETE falla, lanza AcademicRecordFailure y conserva el récord',
        () async {
      _loguear(_user());
      final api = _FakeRecordApi([_syncedJson()])
        ..deleteError =
            ApiException(statusCode: 500, code: 'HTTP_ERROR', message: 'x');
      final s = _servicio(api);
      await s.load();

      await expectLater(
        s.deleteRecord(),
        throwsA(
          isA<AcademicRecordFailure>().having(
            (e) => e.message,
            'message',
            AcademicRecordService.deleteErrorMessage,
          ),
        ),
      );
      expect(s.record!.hasRecord, isTrue);
      expect(s.record!.snapshot!.ppa, 14.62);
      expect(api.getCalls, 1, reason: 'sin borrado no hay recarga');
    });

    test('caso 12: un docente no llama al DELETE', () async {
      _loguear(_user(code: 'docente.test', role: 'teacher'));
      final api = _FakeRecordApi([_syncedJson()]);
      final s = _servicio(api);

      await s.deleteRecord();

      expect(api.deleteCalls, 0);
      expect(api.getCalls, 0);
    });
  });

  group('UNITARIA · refreshAfterImport invalida el récord (HU34)', () {
    // MallaService no se registra a propósito: su Get.find falla dentro del
    // try compartido de refreshAfterImport. Que el récord igual se recargue
    // prueba que su bloque tiene un try propio.
    test('caso 13: vacía el récord al instante y lo vuelve a pedir', () async {
      _loguear(_user());
      final segundo = Completer<Map<String, dynamic>>();
      final api = _FakeRecordApi([_syncedJson(), segundo]);
      _servicio(api);
      await AcademicRecordService.to.load();
      expect(AcademicRecordService.to.record!.snapshot!.ppa, 14.62);

      final f = _portalSync().refreshAfterImport();
      await Future<void>.delayed(Duration.zero);
      expect(AcademicRecordService.to.record, isNull,
          reason: 'nunca se ve el PPA anterior');
      expect(api.getCalls, 2);

      segundo.complete(_syncedJson(ppa: 15.1));
      await f;
      expect(AcademicRecordService.to.record!.snapshot!.ppa, 15.1);
    });

    test('caso 14: sin AcademicRecordService registrado, no lanza', () async {
      _loguear(_user());
      await expectLater(_portalSync().refreshAfterImport(), completes);
    });
  });
}
