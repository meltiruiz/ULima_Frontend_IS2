import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/storage_service.dart';

/// Qué 401s se tratan como sesión caducada y cuáles no (HU33).

/// Cuenta los cierres de sesión sin tocar el llavero ni SharedPreferences:
/// ninguno de los dos existe en un test unitario.
class _StorageEspia extends StorageService {
  int cierres = 0;

  @override
  Future<void> clearSession() async => cierres++;

  @override
  Future<String?> get savedToken async => 'token-guardado';
}

/// Pide una ruta contra un servidor falso que siempre responde 401 y devuelve
/// cuántas veces se cerró la sesión por el camino.
///
/// `runWithClient` sustituye el `Client()` que `Request.send()` construye por
/// dentro, así que no hace falta ningún servidor de verdad. `offAllToLogin()`
/// no navega porque `Get.context` es null sin un GetMaterialApp montado; lo que
/// distingue a los dos casos, y lo que de verdad destruye la sesión recién
/// creada, es el `clearSession()`.
Future<int> _cierresTrasUn401(String ruta, {required bool suprimir}) {
  final espia = _StorageEspia();
  Get.put<StorageService>(espia);
  final servidor = MockClient(
    (_) async => http.Response(
      jsonEncode({
        'error': {'code': 'UNAUTHORIZED', 'message': 'Token inválido'},
      }),
      401,
      headers: {'content-type': 'application/json'},
    ),
  );

  return http.runWithClient(() async {
    final api = ApiClient(configuredBaseUrl: 'http://test');
    Object? lanzado;
    try {
      await api.getJson(ruta, token: 'jwt', suppressSessionExpiry: suprimir);
    } catch (e) {
      lanzado = e;
    }
    expect(lanzado, isA<ApiException>(),
        reason: 'suprimir el efecto secundario no oculta el error');
    return espia.cierres;
  }, () => servidor);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Get.reset);

  group('UNITARIA · esRuta401Exenta (HU33)', () {
    test('caso 1: /auth/register queda exento: su 401 es del portal, no de sesión', () {
      expect(esRuta401Exenta('/auth/register'), isTrue);
    });

    test('caso 2: /auth/login sigue exento, como antes', () {
      expect(esRuta401Exenta('/auth/login'), isTrue);
    });

    test('caso 3: una ruta autenticada NO queda exenta', () {
      expect(esRuta401Exenta('/auth/me'), isFalse);
      expect(esRuta401Exenta('/portal-sync/import'), isFalse);
      expect(esRuta401Exenta('/academic-profile/careers'), isFalse);
    });

    test('caso 4: /auth/logout no entra por acá; su excepción es la de navegar', () {
      expect(esRuta401Exenta('/auth/logout'), isFalse);
    });
  });

  group('UNITARIA · ApiClient.suppressSessionExpiry (HU33)', () {
    test('caso 1: con la bandera puesta, el 401 de un catálogo NO cierra la sesión', () async {
      // Es el 401 que `adoptarSesion` puede recibir justo después del 201. La
      // ruta no está exenta —ni puede estarlo— así que sin la bandera borraría
      // el token guardado una línea antes (BR-REG-F-10, RS-FE-4).
      final cierres = await _cierresTrasUn401(
        '/academic-profile/careers',
        suprimir: true,
      );
      expect(cierres, equals(0));
    });

    test('caso 2: sin la bandera, el mismo 401 sí cierra la sesión', () async {
      // La conducta de siempre, que `login()` y `finishGoogleLogin()` conservan:
      // ahí un 401 del catálogo sí significa que la sesión murió.
      final cierres = await _cierresTrasUn401(
        '/academic-profile/careers',
        suprimir: false,
      );
      expect(cierres, equals(1));
    });

    test('caso 3: la bandera es por llamada, no por ruta', () async {
      // La misma ruta, los dos comportamientos. Es justo lo que
      // `esRuta401Exenta` no puede expresar.
      expect(
        await _cierresTrasUn401('/academic-profile/specialties', suprimir: true),
        equals(0),
      );
      Get.reset();
      expect(
        await _cierresTrasUn401('/academic-profile/specialties', suprimir: false),
        equals(1),
      );
    });
  });
}
