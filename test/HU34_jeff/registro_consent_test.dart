import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/portal_consent/portal_consent_view.dart';
import 'package:ulima_plus/domain/bienvenida/bienvenida_turnos.dart';
import 'package:ulima_plus/models/portal_sync_models.dart';
import 'package:ulima_plus/models/registro_models.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/compositor.dart';
import 'package:ulima_plus/pages/registro/registro_controller.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/registro_service.dart';
import 'package:ulima_plus/services/session_navigation.dart';

import '../bienvenida/apoyo_bienvenida.dart';

/// Consentimiento en el alta de cuenta (RF-REC-6).
///
/// El paso `consentimiento` va entre `datos` y `verificar`, nunca entre el
/// código del authenticator y el botón que envía: ese código vence en 30
/// segundos (BR-REG-F-01). Sin aceptación el registro no se envía, y tras
/// aceptar el body de `POST /auth/register` lleva `consent: true`.
///
/// Todos los valores son inventados.

/// Doble del servicio: cuenta llamadas y guarda qué consentimiento recibió.
class _ServicioFalso implements RegistroService {
  _ServicioFalso({this.resultado, this.fallo});

  final RegistroResult? resultado;
  final RegistroFailure? fallo;
  int llamadas = 0;
  bool? consentRecibido;

  @override
  Future<RegistroResult> registrar({
    required String code,
    required String portalPassword,
    required String passcode,
    required String password,
    required bool consent,
  }) async {
    llamadas++;
    consentRecibido = consent;
    if (fallo != null) throw fallo!;
    return resultado!;
  }
}

/// Doble del cliente HTTP: guarda el body para mirar sus claves.
class _FakeApiClient extends ApiClient {
  _FakeApiClient(this.respuesta) : super(configuredBaseUrl: 'http://test');

  final Map<String, dynamic> respuesta;
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
    return respuesta;
  }
}

UserModel _usuario() => UserModel(
      code: '20230001',
      firstName: 'Alumna',
      lastName: 'De Prueba',
      email: 'test@aloe.ulima.edu.pe',
      role: 'student',
      currentCycle: '2026-1',
      setupComplete: false,
    );

PortalSyncSummary _summary() => const PortalSyncSummary(
      coursesCreated: 0,
      sectionsCreated: 0,
      sectionsUpdated: 0,
      sessionsUpserted: 12,
      enrollmentsUpserted: 5,
      enrollmentsWithdrawn: 0,
      progressUpserted: 40,
      syllabiUpserted: 0,
    );

RegistroResult _resultado() => RegistroResult(
      token: 'jwt',
      user: _usuario(),
      summary: _summary(),
      warnings: const [],
    );

/// Respuesta `201` inventada, con la forma del contrato.
Map<String, dynamic> _respuestaValida() => {
      'token': 'jwt',
      'tokenType': 'Bearer',
      'expiresIn': 86400,
      'user': {
        'id': 1,
        'studentId': 1,
        'code': '20230001',
        'fullName': 'DE PRUEBA ALUMNA',
        'institutionalEmail': 'test@aloe.ulima.edu.pe',
        'role': 'student',
        'career_id': 1,
        'setupComplete': false,
      },
      'summary': {
        'enrollmentsUpserted': 5,
        'sessionsUpserted': 12,
        'progressUpserted': 40,
      },
      'warnings': <dynamic>[],
    };

/// Controller con las tres costuras controladas y los cinco campos llenos.
RegistroController _controller({RegistroService? servicio}) {
  final c = RegistroController(
    service: servicio ?? _ServicioFalso(resultado: _resultado()),
    adoptarSesion: ({required token, required user}) async {},
    iniciarSesion: ({required code, required password}) async => null,
  );
  c.codigoCtrl.text = '20230001';
  c.passwordCtrl.text = 'micontrasena';
  c.confirmacionCtrl.text = 'micontrasena';
  c.portalPasswordCtrl.text = 'clave-portal';
  c.passcodeCtrl.text = '123456';
  return c;
}

void main() {
  // El archivo mezcla `test` y `testWidgets`; dejar el binding puesto desde el
  // arranque evita depender del orden en que se ejecuten.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UNITARIA · RegistroController consentimiento (RF-REC-6)', () {
    test('caso 1: continuar lleva al consentimiento, no al formulario del portal',
        () {
      final servicio = _ServicioFalso(resultado: _resultado());
      final c = _controller(servicio: servicio);
      expect(c.paso.value, equals(RegistroPaso.datos));

      c.continuar();

      expect(c.paso.value, equals(RegistroPaso.consentimiento),
          reason: 'el consentimiento va ANTES de pedir la contraseña de miUlima');
      expect(servicio.llamadas, equals(0));
    });

    test('caso 2: aceptar lleva a verificar y deja constancia de la aceptación',
        () {
      final c = _controller();
      c.continuar();
      expect(c.consentimientoAceptado.value, isFalse);

      c.aceptarConsentimiento();

      expect(c.paso.value, equals(RegistroPaso.verificar));
      expect(c.consentimientoAceptado.value, isTrue);
    });

    test('caso 3: sin aceptación el registro no se envía', () async {
      final servicio = _ServicioFalso(resultado: _resultado());
      final c = _controller(servicio: servicio);
      c.continuar();

      await c.enviar();

      expect(servicio.llamadas, equals(0),
          reason: 'sin «Acepto» no sale nada hacia el backend');
      expect(c.paso.value, equals(RegistroPaso.consentimiento));
    });

    test('caso 4: tras aceptar, el alta manda consent: true', () async {
      final servicio = _ServicioFalso(resultado: _resultado());
      final c = _controller(servicio: servicio);
      c.continuar();
      c.aceptarConsentimiento();

      await c.enviar();

      expect(servicio.llamadas, equals(1));
      expect(servicio.consentRecibido, isTrue);
      expect(c.paso.value, equals(RegistroPaso.listo));
    });

    test('caso 5: un fallo que vuelve a datos no vuelve a pedir la aceptación',
        () async {
      // El alumno sigue en el mismo registro, y volver a pedirle la
      // aceptación en el mismo intento es ruido.
      final c = _controller(
        servicio: _ServicioFalso(
          fallo: const RegistroFailure('Ya existe una cuenta.',
              code: 'USER_ALREADY_EXISTS'),
        ),
      );
      c.continuar();
      c.aceptarConsentimiento();
      await c.enviar();
      expect(c.paso.value, equals(RegistroPaso.datos));

      c.continuar();

      expect(c.paso.value, equals(RegistroPaso.verificar));
    });

    test('caso 6: volver desde el consentimiento no borra lo tipeado', () {
      final c = _controller();
      c.continuar();
      expect(c.paso.value, equals(RegistroPaso.consentimiento));

      c.volverADatos();

      expect(c.paso.value, equals(RegistroPaso.datos));
      expect(c.codigoCtrl.text, equals('20230001'));
      expect(c.passwordCtrl.text, equals('micontrasena'));
      expect(c.confirmacionCtrl.text, equals('micontrasena'));
    });

    test('caso 7: una visita nueva arranca sin aceptación', () {
      // No se recuerda entre visitas: la bienvenida crea un
      // RegistroController nuevo en cada registro y lo cierra al salir.
      final c = _controller();
      c.continuar();
      c.aceptarConsentimiento();
      expect(c.consentimientoAceptado.value, isTrue);

      final otra = _controller();

      expect(otra.consentimientoAceptado.value, isFalse);
      expect(otra.paso.value, equals(RegistroPaso.datos));
      otra.continuar();
      expect(otra.paso.value, equals(RegistroPaso.consentimiento));
    });
  });

  group('UNITARIA · RegistroService consent (RF-REC-6, RS-BE-29)', () {
    test('caso 8: consent true viaja en el nivel superior del body', () async {
      final api = _FakeApiClient(_respuestaValida());

      await RegistroService(apiClient: api).registrar(
        code: '20230001',
        portalPassword: 'clave-portal',
        passcode: '123456',
        password: 'micontrasena',
        consent: true,
      );

      expect(api.ultimaRuta, equals('/auth/register'));
      expect(api.ultimoBody!['consent'], isTrue);
      expect(
        api.ultimoBody!.keys.toSet(),
        equals({'code', 'portalPassword', 'passcode', 'password', 'consent'}),
      );
    });

    test('caso 9: sin consentimiento el campo no se manda; nunca va false',
        () async {
      final api = _FakeApiClient(_respuestaValida());

      await RegistroService(apiClient: api).registrar(
        code: '20230001',
        portalPassword: 'clave-portal',
        passcode: '123456',
        password: 'micontrasena',
        consent: false,
      );

      expect(
        api.ultimoBody!.keys.toSet(),
        equals({'code', 'portalPassword', 'passcode', 'password'}),
      );
      expect(api.ultimoBody!.containsKey('consent'), isFalse);
    });
  });

  group('WIDGET · el consentimiento en la conversación (RF-REC-6 y RF-BIEN-7)',
      () {
    setUp(() {
      Get.testMode = true;
      Get.reset();
    });
    tearDown(Get.reset);

    /// Llega a N3 desde E1 con «Soy nuevo» y datos válidos inventados.
    Future<Bienvenida> enN3(WidgetTester tester) async {
      final b = Bienvenida();
      await montarLaBienvenida(
        tester,
        b,
        argumentos: const {argumentoDeMotivo: MotivoDeLlegada.expirada},
      );
      await avanzar(tester, 1500);
      await tester.tap(find.text(TextosDeLaBienvenida.soyNuevo));
      await avanzar(tester, 3000);
      // Un cuadro tras teclear, para que el botón de envío se encienda.
      await tester.enterText(find.byType(TextField).first, '20230001');
      await tester.pump();
      await tester.tap(find.byType(BotonDeEnvio));
      await avanzar(tester, 2500);
      await tester.enterText(find.byType(TextField).at(0), 'micontrasena');
      await tester.enterText(find.byType(TextField).at(1), 'micontrasena');
      await tester.pump();
      await tester.tap(find.byType(BotonDeEnvio));
      await avanzar(tester, 3000);
      return b;
    }

    testWidgets('caso 10: tras las contraseñas, el consentimiento va antes '
        'que miUlima', (tester) async {
      await enN3(tester);

      expect(find.text(PortalConsentView.titulo), findsOneWidget);
      expect(find.text(TextosDeLaBienvenida.rotuloPortal), findsNothing);
      expect(find.text(TextosDeLaBienvenida.rotuloAuthenticator), findsNothing,
          reason: 'el código vence en 30 s: no puede esperar a que se lea el aviso');
    });

    testWidgets('caso 11: «Acepto» lleva a la contraseña de miUlima', (
      tester,
    ) async {
      final b = await enN3(tester);

      await tester.tap(find.text(TextosDeLaBienvenida.acepto));
      await avanzar(tester, 2500);

      expect(find.text(TextosDeLaBienvenida.rotuloPortal), findsOneWidget);
      expect(b.controlador.registro!.consentimientoAceptado.value, isTrue);
    });

    testWidgets('caso 12: «Volver» regresa a las contraseñas sin borrar nada',
        (tester) async {
      final b = await enN3(tester);

      await tester.tap(find.text(TextosDeLaBienvenida.volver));
      await avanzar(tester, 2500);

      final c = b.controlador;
      expect(c.turno.value, TurnoDeLaBienvenida.n2Contrasena);
      expect(c.registro!.codigoCtrl.text, equals('20230001'),
          reason: 'salir del consentimiento es retroceder un paso, no empezar de cero');
      expect(c.registro!.passwordCtrl.text, equals('micontrasena'));
    });
  });
}
