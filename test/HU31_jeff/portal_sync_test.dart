import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/models/portal_sync_models.dart';
import 'package:ulima_plus/pages/portal_sync/portal_sync_controller.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/portal_sync_service.dart';

/// Carga de ciclo desde miUlima (portal-sync), lado frontend.

class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.respuesta, this.error})
      : super(configuredBaseUrl: 'http://test');

  final Map<String, dynamic>? respuesta;
  final Object? error;
  Map<String, dynamic>? ultimoBody;

  @override
  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    ultimoBody = body;
    if (error != null) throw error!;
    return respuesta ?? <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String?> query = const {},
    String? token,
  }) async {
    if (error != null) throw error!;
    return respuesta ?? <String, dynamic>{};
  }
}

void main() {
  group('validadores', () {
    test('la contraseña vacía no pasa', () {
      expect(validarPassword(''), isNotNull);
      expect(validarPassword('   '), isNotNull);
      expect(validarPassword('algo'), isNull);
    });

    test('el código del authenticator son 6 a 8 dígitos', () {
      expect(validarPasscode(''), isNotNull);
      expect(validarPasscode('12345'), isNotNull, reason: 'muy corto');
      expect(validarPasscode('12 34 56'), isNotNull, reason: 'con espacios');
      expect(validarPasscode('abcdef'), isNotNull, reason: 'no son dígitos');
      expect(validarPasscode('123456'), isNull);
      expect(validarPasscode('12345678'), isNull);
    });

    test('el formulario devuelve el PRIMER error, empezando por la contraseña', () {
      expect(validarFormulario(password: '', passcode: ''),
          equals(validarPassword('')));
      expect(validarFormulario(password: 'ok', passcode: 'x'),
          equals(validarPasscode('x')));
      expect(validarFormulario(password: 'ok', passcode: '123456'), isNull);
    });
  });

  group('PortalSyncService.import', () {
    test('manda credentials y NO manda el usuario: el backend lo saca del JWT', () async {
      final api = _FakeApiClient(respuesta: {
        'period': {'id': 2, 'code': '2026-2'},
        'identity': {'portalCode': '20235218', 'fullName': 'X', 'career': 'Y'},
        'summary': {'enrollmentsUpserted': 5},
        'warnings': <dynamic>[],
      });
      await PortalSyncService(apiClient: api)
          .import(password: 'clave', passcode: '123456');

      final creds = api.ultimoBody!['credentials'] as Map<String, dynamic>;
      expect(creds.keys.toSet(), equals({'password', 'passcode'}));
      expect(api.ultimoBody!.containsKey('cookies'), isFalse);
      // Ni código de alumno ni usuario: mandarlos abriría una vía para
      // importar en nombre de otro alumno.
      expect(api.ultimoBody.toString(), isNot(contains('20235218')));
    });

    test('un login rechazado da un mensaje claro y conserva su código', () async {
      final api = _FakeApiClient(
        error: ApiException(statusCode: 409, code: 'PORTAL_LOGIN_REJECTED', message: 'x'),
      );
      final e = await PortalSyncService(apiClient: api)
          .import(password: 'clave', passcode: '000000')
          .then<Object?>((_) => null)
          .catchError((Object err) => err);
      expect(e, isA<PortalSyncFailure>());
      final f = e as PortalSyncFailure;
      expect(f.code, 'PORTAL_LOGIN_REJECTED');
      expect(f.message.toLowerCase(), contains('contraseña'));
    });

    test('cada error del portal tiene su propio mensaje, ninguno genérico', () async {
      const codigos = [
        'PORTAL_SESSION_INVALID', 'PORTAL_IDENTITY_MISMATCH',
        'PORTAL_IDENTITY_UNVERIFIABLE', 'PORTAL_TIMEOUT', 'PORTAL_UNAVAILABLE',
      ];
      final mensajes = <String>{};
      for (final code in codigos) {
        final api = _FakeApiClient(
          error: ApiException(statusCode: 502, code: code, message: ''),
        );
        final e = await PortalSyncService(apiClient: api)
            .import(password: 'c', passcode: '123456')
            .then<Object?>((_) => null)
            .catchError((Object err) => err);
        mensajes.add((e as PortalSyncFailure).message);
      }
      expect(mensajes.length, codigos.length,
          reason: 'dos códigos distintos no pueden compartir mensaje');
    });

    test('un fallo de red crudo no se escapa sin traducir', () async {
      // ApiClient propaga los fallos de red SIN envolver en ApiException.
      final api = _FakeApiClient(error: Exception('socket'));
      final e = await PortalSyncService(apiClient: api)
          .import(password: 'c', passcode: '123456')
          .then<Object?>((_) => null)
          .catchError((Object err) => err);
      expect(e, isA<PortalSyncFailure>());
      expect((e as PortalSyncFailure).message.toLowerCase(), contains('conexión'));
    });
  });

  group('PortalSyncService.status', () {
    test('un fallo NO muestra el aviso: needsImport queda en false', () async {
      // Proponerle cargar a quien ya tiene sus datos es peor que no
      // proponérselo a quien los necesita, que igual entra por Perfil.
      final api = _FakeApiClient(error: Exception('sin red'));
      final s = await PortalSyncService(apiClient: api).status();
      expect(s.needsImport, isFalse);
      expect(s.activePeriod, isNull);
    });

    test('lee needsImport y el período activo', () async {
      final api = _FakeApiClient(respuesta: {
        'activePeriod': {'id': 2, 'code': '2026-2'},
        'enrollmentsInActivePeriod': 0,
        'needsImport': true,
      });
      final s = await PortalSyncService(apiClient: api).status();
      expect(s.needsImport, isTrue);
      expect(s.activePeriod?.code, '2026-2');
    });

    test('tolera activePeriod null, que el contrato permite', () async {
      final api = _FakeApiClient(respuesta: {
        'activePeriod': null, 'enrollmentsInActivePeriod': 0, 'needsImport': true,
      });
      final s = await PortalSyncService(apiClient: api).status();
      expect(s.activePeriod, isNull);
      expect(s.needsImport, isTrue);
    });
  });

  group('PortalSyncResult.fromJson', () {
    test('lee el resumen y las advertencias', () {
      final r = PortalSyncResult.fromJson({
        'period': {'id': 2, 'code': '2026-2'},
        'identity': {'fullName': 'JEFFERSON', 'career': 'Ing. Sistemas'},
        'summary': {
          'enrollmentsUpserted': 5, 'sessionsUpserted': 11,
          'progressUpserted': 32, 'syllabiUpserted': 3,
        },
        'warnings': [
          {'code': 'SYLLABUS_UNAVAILABLE', 'block': 'silabo', 'message': 'sin sílabo'},
        ],
      });
      expect(r.periodCode, '2026-2');
      expect(r.summary.cursos, 5);
      expect(r.summary.sessionsUpserted, 11);
      expect(r.warnings.single.code, 'SYLLABUS_UNAVAILABLE');
    });

    test('una respuesta incompleta no revienta la pantalla', () {
      final r = PortalSyncResult.fromJson(<String, dynamic>{});
      expect(r.periodCode, '');
      expect(r.summary.cursos, 0);
      expect(r.warnings, isEmpty);
    });

    test('coerciona números que lleguen como texto', () {
      final r = PortalSyncResult.fromJson({
        'summary': {'enrollmentsUpserted': '7'},
      });
      expect(r.summary.cursos, 7);
    });
  });
}
