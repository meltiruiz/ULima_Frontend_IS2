// test/bienvenida/bienvenida_errores_test.dart
//
// UNITARIA · Bienvenida con Ulises (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-12. Cada error del backend o de la red es una burbuja de Ulises.
// Recorre cada fila de la tabla, del recibimiento y los turnos sin envío a
// E2, Google, la validación local, el envío y lo que sigue al 201, T0, el test
// y el 401 en un turno con sesión, con la limpieza local y la vuelta a E1
// (B-22). Las dos filas del paso al horario necesitan la capa del arranque y
// van en bienvenida_horario_test.dart.
// Archivo probado lib/pages/bienvenida/bienvenida_controller.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/domain/bienvenida/bienvenida_turnos.dart';
import 'package:ulima_plus/models/registro_models.dart';
import 'package:ulima_plus/pages/bienvenida/conversacion.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';

import '../HU36_jeff/datos_de_prueba.dart';
import '../HU36_jeff/dobles_de_red.dart';
import '../HU36_jeff/dobles_del_controlador.dart' show respuestasEnOrden;
import 'apoyo_bienvenida.dart';

typedef _T = TurnoDeLaBienvenida;

/// Llega a E2 con el código de prueba y una contraseña inventada.
Future<Bienvenida> _enE2(AuthDeLaBienvenida auth) async {
  final b = Bienvenida(auth: auth);
  await b.visitar();
  b.controlador.responderAlSaludo(yaUsa: true);
  b.login.codeController.text = '20230001';
  b.controlador.enviarCodigo();
  b.login.passwordController.text = 'secreta-de-prueba';
  return b;
}

/// Llega hasta N5 con datos válidos inventados.
Future<Bienvenida> _enN5({
  RegistroFalso? registro,
  bool adoptarFalla = false,
}) async {
  final b = Bienvenida(registro: registro, adoptarFalla: adoptarFalla);
  await b.visitar();
  final c = b.controlador..responderAlSaludo(yaUsa: false);
  c.registro!.codigoCtrl.text = '20230001';
  c.enviarCodigoDeAlumno();
  c.registro!
    ..passwordCtrl.text = 'Contrasena1'
    ..confirmacionCtrl.text = 'Contrasena1';
  c.enviarContrasenas();
  c.aceptarConsentimiento();
  c.registro!.portalPasswordCtrl.text = 'clave-de-prueba';
  c.enviarPortal();
  c.registro!.passcodeCtrl.text = '123456';
  return b;
}

/// Las burbujas de error de Ulises.
List<BurbujaDeUlises> _errores(Bienvenida b) => <BurbujaDeUlises>[
  for (final e in b.controlador.entradas)
    if (e is BurbujaDeUlises && e.tipo == TipoDeBurbuja.error) e,
];

Future<Bienvenida> _conSesion(ApiFalsaDelTest api) async {
  final b = Bienvenida(
    auth: AuthDeLaBienvenida(usuario: alumnaDePrueba(setupComplete: false)),
    token: 'jwt-de-prueba',
    apiDelTest: api,
  );
  await b.visitar();
  b.controlador.ulisesAterrizoConSesion();
  await pumpEventQueue();
  return b;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Get.reset);

  group('cada fila de la tabla, antes del test (RF-BIEN-12)', () {
    test('el recibimiento y los turnos sin envío no usan la red, así que sin '
        'conexión no se ve nada', () async {
      final b = await _enE2(AuthDeLaBienvenida(redCaida: true));
      expect(_errores(b), isEmpty);
      expect(b.controlador.turno.value, _T.e2Contrasena);
    });

    test('en E2, cada error del login dice el mensaje de AuthService y vuelve '
        'a E1 con el código y la contraseña vacía (B-6)', () async {
      // Los mensajes de la tabla salen de loginErrorMessage.
      const invalido = AuthService.invalidCredentialsMessage;
      expect(AuthService.loginErrorMessage('USER_NOT_FOUND', 'x'), invalido);
      expect(AuthService.loginErrorMessage('INVALID_PASSWORD', 'x'), invalido);
      expect(
        AuthService.loginErrorMessage('NOT_ENROLLED', 'x'),
        'No tienes una matrícula activa.',
      );
      expect(
        AuthService.loginErrorMessage(
          'OTRO_ERROR',
          'Mensaje del backend de prueba.',
        ),
        'Mensaje del backend de prueba.',
      );
      for (final mensaje in <String>[
        invalido,
        'No tienes una matrícula activa.',
        'Mensaje del backend de prueba.',
      ]) {
        final b = await _enE2(AuthDeLaBienvenida(errorDeLogin: mensaje));
        await b.controlador.entrar();
        expect(_errores(b).single.texto, mensaje);
        expect(b.controlador.turno.value, _T.e1Codigo);
        expect(b.login.codeController.text, '20230001');
        expect(b.login.passwordController.text, '');
        Get.reset();
      }
    });

    test(
      'en E2, sin conexión, E2 sigue abierto con la contraseña escrita',
      () async {
        final b = await _enE2(AuthDeLaBienvenida(redCaida: true));
        await b.controlador.entrar();
        expect(_errores(b).single.texto, TextosDeLaBienvenida.sinConexion);
        expect(b.controlador.turno.value, _T.e2Contrasena);
        expect(b.login.passwordController.text, 'secreta-de-prueba');
      },
    );

    test('en E1, Google cancelado no dice nada, y INVALID_DOMAIN, '
        'USER_NOT_FOUND, la falta de idToken y otro fallo son una burbuja con '
        'E1 abierto, sin ofrecer crear la cuenta', () async {
      final b = Bienvenida(auth: AuthDeLaBienvenida(google: 'cancelar'));
      await b.visitar();
      b.controlador.responderAlSaludo(yaUsa: true);
      final antes = b.controlador.entradas.length;
      await b.controlador.entrarConGoogle();
      expect(b.controlador.entradas, hasLength(antes));
      for (final mensaje in <String>[
        'Debes usar tu correo @aloe.ulima.edu.pe o @ulima.edu.pe.',
        'Tu correo no está registrado en el sistema.',
        'No se obtuvo información de Google.',
        'No se pudo iniciar sesión con Google.',
      ]) {
        b.auth.google = mensaje;
        final respuestas = b.delAlumno.length;
        await b.controlador.entrarConGoogle();
        expect(b.deUlises.last, mensaje);
        expect(_errores(b).last.texto, mensaje);
        expect(b.delAlumno, hasLength(respuestas), reason: 'ninguna oferta');
        expect(b.controlador.turno.value, _T.e1Codigo);
      }
    });

    test(
      'de N1 a N5, la validación local va bajo el campo y no es burbuja',
      () async {
        final b = Bienvenida();
        await b.visitar();
        final c = b.controlador..responderAlSaludo(yaUsa: false);
        c.registro!.codigoCtrl.text = '12ab';
        c.enviarCodigoDeAlumno();
        expect(c.errorLocal.value, isNotNull);
        expect(_errores(b), isEmpty);
        expect(c.turno.value, _T.n1Codigo);
      },
    );

    test('el envío sin conexión vuelve a N5, el plazo vencido y el 201 sin '
        'sesión quedan en incierto, y un «Iniciar sesión» que no entra lo dice '
        '(B-30 y B-32)', () async {
      final sinRed = await _enN5(
        registro: RegistroFalso(
          fallo: const RegistroFailure(
            'No hay conexión. Revisa tu internet e inténtalo de nuevo.',
            code: 'SIN_CONEXION',
          ),
        ),
      );
      await sinRed.controlador.crearCuenta();
      expect(sinRed.deUlises.last, TextosDeLaBienvenida.sinConexion);
      expect(sinRed.controlador.turno.value, _T.n5Authenticator);
      Get.reset();

      final plazo = await _enN5(
        registro: RegistroFalso(
          fallo: const RegistroFailure('x', code: 'TIEMPO_AGOTADO'),
        ),
      );
      await plazo.controlador.crearCuenta();
      expect(plazo.controlador.turno.value, _T.incierto);
      plazo.auth.errorDeLogin = 'Código o contraseña incorrectos.';
      await plazo.controlador.iniciarSesionDesdeIncierto();
      expect(
        plazo.deUlises.last,
        startsWith('Seguimos sin poder confirmarlo.'),
      );
      expect(plazo.controlador.turno.value, _T.incierto);
      Get.reset();

      final sinSesion = await _enN5(adoptarFalla: true);
      await sinSesion.controlador.crearCuenta();
      expect(sinSesion.deUlises, contains(TextosDeLaBienvenida.creadaTitulo));
      expect(sinSesion.controlador.turno.value, _T.incierto);
    });

    test('después del 201, los catálogos que fallan no se notan y sigue el '
        'test (BR-REG-F-10)', () async {
      final b = await _enN5();
      b.auth.catalogoFalla = true;
      await b.controlador.crearCuenta();
      await pumpEventQueue();
      expect(_errores(b), isEmpty);
      expect(b.controlador.ultimoTurno.value, _T.t0Invitacion);
    });
  });

  group('los errores del test (RF-BIEN-12)', () {
    test('en T0, el contenido que no llega dice «No pudimos cargar el test.» '
        'y reintentar lo pide otra vez', () async {
      final api = ApiFalsaDelTest(
        contenido: <Object>[
          const SpecialtyTestFailure(SpecialtyTestFailureKind.offline),
          contenidoJson(),
        ],
      );
      final b = await _conSesion(api);
      final error = b.controlador.entradas.whereType<BurbujaDeUlises>().last;
      expect(error.texto, TextosDeLaBienvenida.noCargoElTest);
      expect(error.tipo, TipoDeBurbuja.error);
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.t0Invitacion);
      b.controlador.reintentarElContenido();
      await pumpEventQueue();
      expect(
        b.deUlises.last,
        '¿Empezamos tu test de especialidad? Son 5 preguntas cortas.',
      );
    });

    test(
      'un error de la espera es una burbuja con su texto y «Reintentar»',
      () async {
        final api = ApiFalsaDelTest(
          evaluaciones: <Object>[
            const SpecialtyTestFailure(SpecialtyTestFailureKind.offline),
            resultadoJson(),
          ],
        );
        final b = await _conSesion(api);
        final c = b.controlador..empezarElTest();
        for (final v in respuestasEnOrden) {
          c
            ..responderAlTest(v, conLector: true)
            ..siguiente();
        }
        await pumpEventQueue();
        expect(
          c.entradas.whereType<BurbujaDeUlises>().last.tipo,
          TipoDeBurbuja.error,
        );
        expect(c.turno.value, TurnoDeLaBienvenida.espera);
        c.reintentarLaEvaluacion();
        await pumpEventQueue();
        expect(c.turno.value, TurnoDeLaBienvenida.resultado);
      },
    );

    test(
      'un 401 al cargar T0 limpia la sesión local y vuelve a E1 (B-22)',
      () async {
        final b = Bienvenida(
          auth: AuthDeLaBienvenida(
            usuario: alumnaDePrueba(setupComplete: false),
          ),
          token: 'jwt-de-prueba',
          apiDelTest: ApiFalsaDelTest(
            contenido: <Object>[
              const SpecialtyTestFailure(SpecialtyTestFailureKind.server),
            ],
          ),
        );
        await b.visitar();
        // El interceptor del 401 borró el token mientras llegaba el contenido.
        b.token = null;
        b.controlador.ulisesAterrizoConSesion();
        await pumpEventQueue();
        expect(b.auth.logouts, 1);
        expect(b.controlador.turno.value, TurnoDeLaBienvenida.e1Codigo);
        expect(b.deUlises.first, TextosDeLaBienvenida.sesionCaducada);
      },
    );

    test('un 401 al reintentar el catálogo de la selección manual limpia la '
        'sesión local y vuelve a E1 (B-22)', () async {
      final b = await _conSesion(ApiFalsaDelTest());
      b.auth
        ..catalogoFalla = true
        ..recargaFalla = true;
      final c = b.controlador..saltarElTest();
      expect(c.catalogoFallido.value, isTrue);
      b.token = null;
      await c.reintentarElCatalogo();
      await pumpEventQueue();
      expect(b.auth.logouts, 1);
      expect(c.turno.value, TurnoDeLaBienvenida.e1Codigo);
    });

    test('«Empezar de nuevo» con el contenido que ya no llega dice «No '
        'pudimos cargar el test.» y ofrece reintentar (RF-TEST-11 y '
        'RF-BIEN-10)', () async {
      final api = ApiFalsaDelTest(
        contenido: <Object>[
          contenidoJson(),
          const SpecialtyTestFailure(SpecialtyTestFailureKind.offline),
          contenidoJson(),
        ],
        evaluaciones: <Object>[
          const SpecialtyTestFailure(
            SpecialtyTestFailureKind.versionOutdated,
            message: 'El test cambió.',
          ),
          resultadoJson(),
        ],
      );
      final b = await _conSesion(api);
      final c = b.controlador..empezarElTest();
      for (final v in respuestasEnOrden) {
        c
          ..responderAlTest(v, conLector: true)
          ..siguiente();
      }
      await pumpEventQueue();
      expect(c.pideReinicio.value, isTrue);
      c.empezarDeNuevo();
      await pumpEventQueue();
      expect(b.deUlises.last, TextosDeLaBienvenida.noCargoElTest);
      expect(c.turno.value, TurnoDeLaBienvenida.t0Invitacion);
      c.reintentarElContenido();
      await pumpEventQueue();
      expect(b.deUlises.last, TextosDeLaBienvenida.invitacionAlTest(5));
    });

    test('un 404 no deja la burbuja de carga en la conversación', () async {
      final b = await _conSesion(
        ApiFalsaDelTest(
          contenido: <Object>[
            const SpecialtyTestFailure(SpecialtyTestFailureKind.notAvailable),
          ],
        ),
      );
      expect(
        b.controlador.entradas.whereType<BurbujaDeUlises>().where(
          (e) => e.tipo == TipoDeBurbuja.cargando,
        ),
        isEmpty,
      );
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.seleccionManual);
    });

    test('un 401 en un turno con sesión limpia la sesión local, borra el '
        'historial y vuelve a E1 (B-22)', () async {
      final api = ApiFalsaDelTest(
        evaluaciones: <Object>[
          const SpecialtyTestFailure(SpecialtyTestFailureKind.server),
        ],
      );
      final b = await _conSesion(api);
      final c = b.controlador..empezarElTest();
      for (final v in respuestasEnOrden) {
        c
          ..responderAlTest(v, conLector: true)
          ..siguiente();
      }
      // El interceptor del 401 borró el token.
      b.token = null;
      await pumpEventQueue();
      expect(b.auth.logouts, 1);
      expect(c.test, isNull);
      expect(b.deUlises, [
        TextosDeLaBienvenida.sesionCaducada,
        TextosDeLaBienvenida.e1,
      ]);
      expect(c.turno.value, TurnoDeLaBienvenida.e1Codigo);
      expect(c.conSesion, isFalse);
    });
  });
}
