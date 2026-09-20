import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/portal_consent/portal_consent_view.dart';
import 'package:ulima_plus/models/portal_sync_models.dart';
import 'package:ulima_plus/models/registro_models.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/registro/registro_controller.dart';
import 'package:ulima_plus/pages/registro/registro_page.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/registro_service.dart';

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

Widget _app() => GetMaterialApp(
      initialRoute: '/registro',
      getPages: [
        GetPage(name: '/registro', page: () => const RegistroPage()),
        GetPage(name: '/login', page: () => const Scaffold(body: Text('LOGIN'))),
      ],
    );

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
      // El alumno no se movió de `/registro`: volver a mostrarle la misma
      // pantalla de consentimiento en el mismo intento es ruido.
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
      // No se recuerda entre visitas: `RegistroBinding` usa `lazyPut` sin
      // `fenix`, así que salir y volver a entrar construye otro controller.
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

  group('WIDGET · RegistroPage consentimiento (RF-REC-6)', () {
    setUp(() => Get.testMode = true);
    tearDown(Get.reset);

    testWidgets('caso 10: continuar muestra el consentimiento antes que miUlima',
        (tester) async {
      Get.put<RegistroController>(_controller());
      await tester.pumpWidget(_app());
      await tester.pump();

      await tester.tap(find.text('Continuar'));
      await tester.pump();

      expect(find.text(PortalConsentView.titulo), findsOneWidget);
      expect(find.text('Verificamos que eres alumno'), findsNothing);
      expect(find.text('Código del authenticator'), findsNothing,
          reason: 'el código vence en 30 s: no puede esperar a que se lea el aviso');
    });

    testWidgets('caso 11: «Acepto» lleva al formulario de miUlima',
        (tester) async {
      Get.put<RegistroController>(_controller());
      await tester.pumpWidget(_app());
      await tester.pump();

      await tester.tap(find.text('Continuar'));
      await tester.pump();

      // La tarjeta mide 340 de ancho y va dentro de un scroll: el botón puede
      // quedar fuera de los 800x600 del test.
      await tester.ensureVisible(find.text(PortalConsentView.botonAceptar));
      await tester.tap(find.text(PortalConsentView.botonAceptar));
      await tester.pump();

      expect(find.text('Verificamos que eres alumno'), findsOneWidget);
      expect(find.text('Código del authenticator'), findsOneWidget);
    });

    testWidgets('caso 12: «Volver» regresa a los datos sin borrarlos',
        (tester) async {
      final c = _controller();
      Get.put<RegistroController>(c);
      await tester.pumpWidget(_app());
      await tester.pump();

      await tester.tap(find.text('Continuar'));
      await tester.pump();
      expect(find.text(PortalConsentView.titulo), findsOneWidget);

      // El único `Text` con 'Volver' es el enlace de salida de la tarjeta: el
      // 'Volver' del scaffold es un tooltip, no un Text.
      await tester.ensureVisible(find.text('Volver'));
      await tester.tap(find.text('Volver'));
      await tester.pump();

      expect(find.text('Crea tu cuenta de ULima++'), findsOneWidget);
      expect(c.codigoCtrl.text, equals('20230001'),
          reason: 'salir del consentimiento es retroceder un paso, no empezar de cero');
    });
  });
}
