import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/models/registro_models.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/registro_service.dart';

/// Alta de cuenta contra miUlima (HU33), lado servicio.

class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.respuesta, this.error, this.demora})
      : super(configuredBaseUrl: 'http://test');

  final Map<String, dynamic>? respuesta;
  final Object? error;
  final Duration? demora;
  Map<String, dynamic>? ultimoBody;
  String? ultimaRuta;

  @override
  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    ultimaRuta = path;
    ultimoBody = body;
    if (demora != null) await Future<void>.delayed(demora!);
    if (error != null) throw error!;
    return respuesta ?? <String, dynamic>{};
  }
}

Map<String, dynamic> _respuestaValida() => {
      'token': 'jwt-de-prueba',
      'tokenType': 'Bearer',
      'expiresIn': 86400,
      'user': {
        'id': 1,
        'studentId': 1,
        'code': '20230001',
        'fullName': 'GARCIA LOPEZ MARIA',
        'institutionalEmail': '20230001@aloe.ulima.edu.pe',
        'role': 'student',
        'career_id': 1,
        'setupComplete': false,
      },
      'summary': {'enrollmentsUpserted': 5, 'sessionsUpserted': 12, 'progressUpserted': 40},
      'warnings': [
        {'code': 'SYLLABUS_UNAVAILABLE', 'block': 'silabo', 'message': 'Los sílabos no respondieron.'},
      ],
    };

void main() {
  group('UNITARIA · RegistroService.registrar (HU33)', () {
    test('caso 1: manda los cuatro campos a /auth/register y nada más', () async {
      final api = _FakeApiClient(respuesta: _respuestaValida());
      await RegistroService(apiClient: api).registrar(
        code: '20230001',
        portalPassword: 'clave-portal',
        passcode: '123456',
        password: 'micontrasena',
      );

      expect(api.ultimaRuta, equals('/auth/register'));
      expect(
        api.ultimoBody!.keys.toSet(),
        equals({'code', 'portalPassword', 'passcode', 'password'}),
      );
    });

    test('caso 2: un 201 con warnings es éxito, no fallo', () async {
      final api = _FakeApiClient(respuesta: _respuestaValida());
      final r = await RegistroService(apiClient: api).registrar(
        code: '20230001', portalPassword: 'x', passcode: '123456', password: 'micontrasena',
      );

      expect(r.token, equals('jwt-de-prueba'));
      expect(r.user.code, equals('20230001'));
      expect(r.summary.cursos, equals(5));
      expect(r.warnings, hasLength(1));
      expect(r.warnings.first.message, equals('Los sílabos no respondieron.'));
    });

    test('caso 3: el plazo vencido NO dice que falló: dice que no se sabe', () async {
      final api = _FakeApiClient(
        respuesta: _respuestaValida(),
        demora: RegistroService.registroTimeout + const Duration(seconds: 1),
      );
      final e = await RegistroService(apiClient: api)
          .registrar(code: '20230001', portalPassword: 'x', passcode: '123456', password: 'micontrasena')
          .then<Object?>((_) => null)
          .catchError((Object err) => err);

      expect(e, isA<RegistroFailure>());
      expect((e! as RegistroFailure).code, equals('TIEMPO_AGOTADO'));
      expect((e as RegistroFailure).message, isNot(contains('no se pudo crear')));
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('caso 4: un 201 sin token deja la cuenta creada pero sin sesión', () async {
      final sinToken = _respuestaValida()..remove('token');
      final api = _FakeApiClient(respuesta: sinToken);
      final e = await RegistroService(apiClient: api)
          .registrar(code: '20230001', portalPassword: 'x', passcode: '123456', password: 'micontrasena')
          .then<Object?>((_) => null)
          .catchError((Object err) => err);

      expect(e, isA<RegistroFailure>());
      expect((e! as RegistroFailure).code, equals('SIN_TOKEN'));
    });

    test('caso 5: un fallo de red crudo no se disfraza de error del backend', () async {
      final api = _FakeApiClient(error: const _SocketExceptionFalsa());
      final e = await RegistroService(apiClient: api)
          .registrar(code: '20230001', portalPassword: 'x', passcode: '123456', password: 'micontrasena')
          .then<Object?>((_) => null)
          .catchError((Object err) => err);

      expect((e! as RegistroFailure).code, equals('SIN_CONEXION'));
    });

    test('caso 6: un ApiException conserva su código para que la pantalla decida', () async {
      final api = _FakeApiClient(
        error: ApiException(statusCode: 409, code: 'USER_ALREADY_EXISTS', message: 'x'),
      );
      final e = await RegistroService(apiClient: api)
          .registrar(code: '20230001', portalPassword: 'x', passcode: '123456', password: 'micontrasena')
          .then<Object?>((_) => null)
          .catchError((Object err) => err);

      expect((e! as RegistroFailure).code, equals('USER_ALREADY_EXISTS'));
    });
  });

  group('UNITARIA · RegistroService.mensajeDeError (HU33)', () {
    String mensaje(String code, [String backend = '']) =>
        RegistroService.mensajeDeError(
          ApiException(statusCode: 400, code: code, message: backend),
        );

    test('caso 1: el 401 del portal nombra las DOS causas posibles', () {
      final m = mensaje('PORTAL_AUTH_FAILED');
      expect(m, contains('contraseña'));
      expect(m, contains('authenticator'));
    });

    test('caso 2: cada código del contrato tiene su propio mensaje', () {
      final codigos = [
        'USER_ALREADY_EXISTS', 'PORTAL_AUTH_FAILED', 'PORTAL_SESSION_INVALID',
        'NOT_ENROLLED', 'PORTAL_IDENTITY_UNVERIFIABLE', 'PORTAL_TIMEOUT',
        'PORTAL_UNAVAILABLE', 'REGISTRATION_UNAVAILABLE',
      ];
      final mensajes = codigos.map((c) => mensaje(c)).toList();
      expect(mensajes.toSet(), hasLength(codigos.length),
          reason: 'dos códigos distintos no pueden compartir mensaje');
      for (final m in mensajes) {
        expect(m, isNotEmpty);
      }
    });

    test('caso 3: los mensajes en inglés del backend se traducen, no se muestran', () {
      expect(mensaje('INVALID_REQUEST_BODY', 'Invalid request body'),
          isNot(contains('Invalid')));
      expect(mensaje('INVALID_JSON_BODY', 'Invalid JSON body'),
          isNot(contains('Invalid')));
      expect(mensaje('INTERNAL_SERVER_ERROR', 'Unexpected server error'),
          isNot(contains('Unexpected')));
    });

    test('caso 4: los DOS códigos de 500 se contemplan', () {
      expect(mensaje('INTERNAL_ERROR', 'Error interno del servidor.'),
          equals(mensaje('INTERNAL_SERVER_ERROR', 'Unexpected server error')));
    });

    test('caso 5: el 429 usa el texto del backend, que trae el tiempo de espera', () {
      expect(mensaje('RATE_LIMITED', 'Intenta de nuevo en 42 minuto(s).'),
          equals('Intenta de nuevo en 42 minuto(s).'));
    });

    test('caso 6: un código desconocido con mensaje vacío no deja la pantalla muda', () {
      expect(mensaje('LO_QUE_SEA'), isNotEmpty);
    });

    test('caso 7: los códigos sin reintento útil dicen que no reintentes', () {
      // Los cuatro vuelven a `verificar`, donde el único botón dice "Crear mi
      // cuenta" y cada pulsada gasta uno de los cinco intentos por hora. Si el
      // mensaje solo describe el problema, la pantalla se lee como un
      // formulario que hay que corregir y la persona acaba bloqueada.
      expect(mensaje('NOT_ENROLLED'),
          contains('No hace falta que lo intentes de nuevo ahora'));
      expect(mensaje('REGISTRATION_UNAVAILABLE'), contains('más tarde'));
      // Estos dos ya lo decían y no se tocan.
      expect(mensaje('PORTAL_TIMEOUT'), contains('más tarde'));
      expect(mensaje('PORTAL_UNAVAILABLE'), contains('más tarde'));
    });

    test('caso 8: los códigos que SÍ se corrigen reintentando no dicen que esperes', () {
      // La contracara del caso 7: acá reintentar es exactamente lo que hay que
      // hacer, así que el mensaje no puede desanimarlo.
      expect(mensaje('PORTAL_AUTH_FAILED'), isNot(contains('más tarde')));
      expect(mensaje('PORTAL_SESSION_INVALID'), contains('de nuevo'));
    });

    test('caso 9: el 429 se muestra tal cual bajo los DOS limitadores', () {
      // El de por código da los minutos exactos; el de concurrencia dice "en
      // unos segundos". Los dos ya traen la espera, así que no se les agrega
      // nada: cualquier añadido nuestro chocaría con uno de los dos.
      const porCodigo =
          'Demasiados intentos de registro. Intenta de nuevo en 42 minuto(s).';
      const porConcurrencia =
          'Hay demasiados registros en curso. Intenta de nuevo en unos segundos.';
      expect(mensaje('RATE_LIMITED', porCodigo), equals(porCodigo));
      expect(mensaje('RATE_LIMITED', porConcurrencia), equals(porConcurrencia));
      // Y si el backend no manda texto, el respaldo tampoco deja a nadie mudo.
      expect(mensaje('RATE_LIMITED'), contains('Espera'));
    });
  });
}

/// Un fallo de red cualquiera: `ApiClient` los propaga sin envolver.
class _SocketExceptionFalsa implements Exception {
  const _SocketExceptionFalsa();
}
