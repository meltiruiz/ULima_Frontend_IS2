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

    // Tras clear() no hay dueño y cada getter devuelve null o falso, así que
    // estas pruebas piden un cargar() del mismo alumno, que queda pendiente,
    // antes de mirar.
    test('clear() vacía la vista, el aviso, errorCarga y enviando, y el mismo '
        'alumno no los recupera al volver', () async {
      loguear(alumna());
      final vuelta = Completer<Map<String, dynamic>>();
      final api = ApiRecargaFalsa()
        ..responder(_vistaGet, vistaJson())
        ..responder(_vistaGet, errorApi(500, 'HTTP_ERROR'))
        ..responder(_vistaGet, vuelta)
        ..responder(_refresh, errorApi(409, 'PORTAL_LOGIN_REJECTED'));
      final s = _servicio(api);
      await s.cargar();
      await s.cargar();
      await _recargar(s);
      expect(s.vista, isNotNull);
      expect(s.errorCarga, isTrue);
      expect(s.ultimoAviso, isNotNull);

      s.clear();
      expect(s.enviando, isFalse);
      final carga = s.cargar();

      expect(s.vista, isNull);
      expect(s.ultimoAviso, isNull);
      expect(s.errorCarga, isFalse);
      vuelta.completeError(errorApi(500, 'HTTP_ERROR'));
      await carga;
    });

    test('clear() vacía los estados y recargaHorario, y el mismo alumno no '
        'los recupera al volver', () async {
      loguear(alumna());
      Get.put<HorarioController>(_HorarioEspia());
      final vuelta = Completer<Map<String, dynamic>>();
      final api = ApiRecargaFalsa()
        ..responder(_vistaGet, vistaJson())
        ..responder(_vistaGet, vuelta)
        ..responder(
          _refresh,
          resultadoJson(
            courses: [
              {'sectionId': 81, 'attendance': 'failed', 'grades': 'failed'},
            ],
          ),
        );
      final s = _servicio(api);
      await s.cargar();
      await _recargar(s);
      expect(s.sinLecturaDeNotas(81), isTrue);
      expect(s.recargaHorario, isNotNull);

      s.clear();
      expect(s.recargaHorario, isNull);
      final carga = s.cargar();

      expect(s.sinLecturaDeNotas(81), isFalse);
      expect(s.sinLecturaDeAsistencia(81), isFalse);
      vuelta.completeError(errorApi(500, 'HTTP_ERROR'));
      await carga;
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
        ..responder(_refresh, errorApi(409, 'PORTAL_LOGIN_REJECTED'))
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
      expect(s.errorCarga, isFalse);
      expect(s.sinLecturaDeNotas(81), isFalse);
      expect(s.sinLecturaDeAsistencia(81), isFalse);

      // Los estados y el aviso no conviven, porque cada envío borra los dos,
      // así que el aviso sale de una segunda recarga del primero, fallida.
      auth.userRx.value = alumna();
      await _recargar(s);
      expect(s.ultimoAviso, isNotNull);

      auth.userRx.value = alumna(code: '20230002');
      expect(s.ultimoAviso, isNull);
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

    test('una respuesta de cargar() del 20230001 que llega después de clear() '
        'y del cargar() del 20230002 se descarta', () async {
      final auth = loguear(alumna());
      final delPrimero = Completer<Map<String, dynamic>>();
      final delSegundo = Completer<Map<String, dynamic>>();
      final api = ApiRecargaFalsa()
        ..responder(_vistaGet, delPrimero)
        ..responder(_vistaGet, delSegundo);
      final s = _servicio(api);

      final cargaDelPrimero = s.cargar();
      s.clear();
      auth.userRx.value = alumna(code: '20230002');
      final cargaDelSegundo = s.cargar();
      delPrimero.complete(vistaJson());
      await cargaDelPrimero;
      expect(s.vista, isNull);

      delSegundo.completeError(errorApi(500, 'HTTP_ERROR'));
      await cargaDelSegundo;
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
          ..responder(_vistaGet, vistaJson())
          ..responder(
            _refresh,
            resultadoJson(
              view: _vistaNueva(),
              courses: [
                {'sectionId': 81, 'attendance': 'updated', 'grades': 'read'},
                {'sectionId': 82, 'attendance': 'missing', 'grades': 'failed'},
              ],
            ),
          );
        final s = _servicio(api);
        await s.cargar();

        expect(await _recargar(s), isTrue);

        expect(s.vista!.lastReadAt, DateTime.utc(2025, 9, 22, 15, 50));
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
        // Solo la carga de antes. Un 200 no vuelve a pedir la vista.
        expect(api.veces(_vistaGet), 1);
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
      final api = ApiRecargaFalsa()
        ..responder(_vistaGet, vistaJson())
        ..responder(_refresh, pendiente);
      final s = _servicio(api);
      await s.cargar();

      final primera = _recargar(s);
      expect(await _recargar(s), isFalse);
      expect(api.veces(_refresh), 1);

      pendiente.complete(resultadoJson());
      expect(await primera, isTrue);
    });

    test('un clear() mientras recargar() pide la vista previa corta la '
        'recarga antes del envío', () async {
      loguear(alumna());
      final previa = Completer<Map<String, dynamic>>();
      final api = ApiRecargaFalsa()..responder(_vistaGet, previa);
      final s = _servicio(api);

      final recarga = _recargar(s);
      expect(s.enviando, isTrue);
      s.clear();
      previa.complete(vistaJson());

      expect(await recarga, isFalse);
      expect(api.veces(_refresh), 0);
      expect(s.enviando, isFalse);
    });

    // Tras clear() no hay dueño y los getters no filtran nada, así que el
    // 20230002 ya tiene un cargar() pendiente cuando vuelve la respuesta.
    for (final exito in <bool>[true, false]) {
      test('una respuesta ${exito ? 'buena' : 'de error'} de recargar() del '
          '20230001 que llega después de clear() y del cargar() del 20230002 '
          'se descarta', () async {
        final auth = loguear(alumna());
        final delPrimero = Completer<Map<String, dynamic>>();
        final delSegundo = Completer<Map<String, dynamic>>();
        final api = ApiRecargaFalsa()
          ..responder(_vistaGet, vistaJson())
          ..responder(_vistaGet, delSegundo)
          ..responder(_refresh, delPrimero);
        final s = _servicio(api);
        await s.cargar();

        final recarga = _recargar(s);
        s.clear();
        auth.userRx.value = alumna(code: '20230002');
        final carga = s.cargar();
        if (exito) {
          delPrimero.complete(
            resultadoJson(
              courses: [
                {'sectionId': 81, 'attendance': 'failed', 'grades': 'failed'},
              ],
            ),
          );
        } else {
          delPrimero.completeError(errorApi(409, 'PORTAL_LOGIN_REJECTED'));
        }

        expect(await recarga, isFalse);
        expect(s.vista, isNull);
        expect(s.ultimoAviso, isNull);
        expect(s.sinLecturaDeNotas(81), isFalse);
        expect(s.enviando, isFalse);
        delSegundo.completeError(errorApi(500, 'HTTP_ERROR'));
        await carga;
      });
    }

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

    test('sin vista cargada, recargar() la pide antes del envío y, tras el '
        'plazo, una lectura igual a esa no cuenta como guardada', () async {
      loguear(alumna());
      final horario =
          Get.put<HorarioController>(_HorarioEspia()) as _HorarioEspia;
      final api = ApiRecargaFalsa()
        // La lectura de una recarga de días antes, que no avanza.
        ..responder(_vistaGet, vistaJson())
        ..responder(_refresh, Completer<Map<String, dynamic>>());
      final s = _servicio(api, plazo: const Duration(milliseconds: 20));

      // Sin cargar() previo, como desde la ficha del curso.
      expect(await _recargar(s), isFalse);

      expect(api.llamadas, <String>[_vistaGet, _refresh, _vistaGet]);
      expect(s.ultimoAviso, avisoPlazo);
      expect(horario.recargas, 0);
    });

    test('sin vista cargada, una lectura posterior a la que se pide antes del '
        'envío sí cuenta como guardada', () async {
      loguear(alumna());
      final api = ApiRecargaFalsa()
        ..responder(_vistaGet, vistaJson())
        ..responder(_vistaGet, _vistaNueva())
        ..responder(_refresh, const SocketException('sin red'));
      final s = _servicio(api);

      expect(await _recargar(s), isTrue);

      expect(api.llamadas, <String>[_vistaGet, _refresh, _vistaGet]);
      expect(s.ultimoAviso, isNull);
    });

    test('si tampoco llega la vista antes del envío, ninguna lectura cuenta '
        'como avance, ni tras el plazo ni en un cargar() posterior', () async {
      loguear(alumna());
      final horario =
          Get.put<HorarioController>(_HorarioEspia()) as _HorarioEspia;
      final api = ApiRecargaFalsa()
        ..responder(_vistaGet, errorApi(500, 'HTTP_ERROR'))
        ..responder(_vistaGet, vistaJson())
        ..responder(_vistaGet, _vistaNueva())
        ..responder(_refresh, Completer<Map<String, dynamic>>());
      final s = _servicio(api, plazo: const Duration(milliseconds: 20));

      expect(await _recargar(s), isFalse);
      expect(s.ultimoAviso, avisoPlazo);

      await s.cargar();
      expect(s.ultimoAviso, avisoPlazo);
      expect(horario.recargas, 0);
      expect(s.vista!.lastReadAt, DateTime.utc(2025, 9, 22, 15, 50));
    });

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
