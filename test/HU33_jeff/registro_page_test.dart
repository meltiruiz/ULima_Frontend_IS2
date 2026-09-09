import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/main.dart';
import 'package:ulima_plus/models/registro_models.dart';
import 'package:ulima_plus/pages/registro/registro_controller.dart';
import 'package:ulima_plus/pages/registro/registro_page.dart';
import 'package:ulima_plus/services/registro_service.dart';

/// La pantalla de registro (HU33), estado por estado.

/// Nunca completa: deja la pantalla en `enviando` para poder inspeccionarla.
class _ServicioColgado implements RegistroService {
  @override
  Future<RegistroResult> registrar({
    required String code,
    required String portalPassword,
    required String passcode,
    required String password,
  }) =>
      Completer<RegistroResult>().future;
}

/// Falla siempre con el `RegistroFailure` que se le dé.
class _ServicioQueFalla implements RegistroService {
  _ServicioQueFalla(this.fallo);

  final RegistroFailure fallo;

  @override
  Future<RegistroResult> registrar({
    required String code,
    required String portalPassword,
    required String passcode,
    required String password,
  }) async =>
      throw fallo;
}

/// Lleva el controller hasta `incierto` por el camino real: rellenar, avanzar
/// y que el envío falle con [codigo].
Future<RegistroController> _hastaIncierto(
  WidgetTester tester, {
  required String mensaje,
  required String codigo,
  IniciarSesionFn? iniciarSesion,
}) async {
  final c = RegistroController(
    service: _ServicioQueFalla(RegistroFailure(mensaje, code: codigo)),
    adoptarSesion: ({required token, required user}) async {},
    iniciarSesion: iniciarSesion ?? ({required code, required password}) async => null,
  );
  Get.put<RegistroController>(c);
  await tester.pumpWidget(_app());
  await tester.pump();

  c.codigoCtrl.text = '20230001';
  c.passwordCtrl.text = 'micontrasena';
  c.confirmacionCtrl.text = 'micontrasena';
  c.continuar();
  c.portalPasswordCtrl.text = 'clave';
  c.passcodeCtrl.text = '123456';
  await c.enviar();
  await tester.pump();
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
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('caso 1: arranca pidiendo los datos de ULima++, no los de miUlima',
      (tester) async {
    Get.put<RegistroController>(RegistroController(
      service: _ServicioColgado(),
      adoptarSesion: ({required token, required user}) async {},
      iniciarSesion: ({required code, required password}) async => null,
    ));
    await tester.pumpWidget(_app());
    await tester.pump();

    expect(find.text('Crea tu cuenta de ULima++'), findsOneWidget);
    expect(find.text('Contraseña de miUlima'), findsNothing,
        reason: 'las dos contraseñas nunca se ven a la vez');
  });

  testWidgets('caso 2: continuar con datos válidos lleva al paso de miUlima',
      (tester) async {
    final c = RegistroController(
      service: _ServicioColgado(),
      adoptarSesion: ({required token, required user}) async {},
      iniciarSesion: ({required code, required password}) async => null,
    );
    Get.put<RegistroController>(c);
    await tester.pumpWidget(_app());
    await tester.pump();

    c.codigoCtrl.text = '20230001';
    c.passwordCtrl.text = 'micontrasena';
    c.confirmacionCtrl.text = 'micontrasena';
    await tester.tap(find.text('Continuar'));
    await tester.pump();

    expect(find.text('Verificamos que eres alumno'), findsOneWidget);
    expect(find.text('Código del authenticator'), findsOneWidget);
  });

  testWidgets('caso 3: mientras se envía no se puede salir', (tester) async {
    final c = RegistroController(
      service: _ServicioColgado(),
      adoptarSesion: ({required token, required user}) async {},
      iniciarSesion: ({required code, required password}) async => null,
    );
    Get.put<RegistroController>(c);
    await tester.pumpWidget(_app());
    await tester.pump();

    c.codigoCtrl.text = '20230001';
    c.passwordCtrl.text = 'micontrasena';
    c.confirmacionCtrl.text = 'micontrasena';
    c.continuar();
    c.portalPasswordCtrl.text = 'clave';
    c.passcodeCtrl.text = '123456';
    unawaited(c.enviar());
    await tester.pump();

    expect(find.text('Creando tu cuenta…'), findsOneWidget);

    // El PopScope más cercano al contenido es el nuestro; buscarlo por
    // `byType` a secas encontraría también los que instala el Navigator.
    final scope = tester.widget<PopScope>(
      find
          .ancestor(
            of: find.text('Creando tu cuenta…'),
            matching: find.byType(PopScope),
          )
          .first,
    );
    expect(scope.canPop, isFalse,
        reason: 'salir a mitad del envío deja cuentas que su dueño no sabe que tiene');
  });

  testWidgets('caso 4: el estado incierto ofrece las dos salidas', (tester) async {
    final c = RegistroController(
      service: _ServicioColgado(),
      adoptarSesion: ({required token, required user}) async {},
      iniciarSesion: ({required code, required password}) async => null,
    );
    Get.put<RegistroController>(c);
    await tester.pumpWidget(_app());
    await tester.pump();

    c.paso.value = RegistroPaso.incierto;
    await tester.pump();

    expect(find.text('No pudimos confirmar si tu cuenta se creó'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Volver a intentar el registro'), findsOneWidget);
  });

  testWidgets('caso 5: por el plazo vencido la frase no se pinta dos veces',
      (tester) async {
    // El mensaje del servicio ES el título. Pintarlo además en naranja debajo
    // repetía la misma oración sin agregar nada.
    await _hastaIncierto(
      tester,
      mensaje: 'No pudimos confirmar si tu cuenta se creó.',
      codigo: 'TIEMPO_AGOTADO',
    );

    expect(
      find.textContaining('No pudimos confirmar si tu cuenta se creó'),
      findsOneWidget,
      reason: 'una sola vez: como título, no también como error',
    );
  });

  testWidgets('caso 6: si el 201 llegó, el título no duda de lo que ya se sabe',
      (tester) async {
    // Con SIN_TOKEN la cuenta EXISTE y el texto naranja lo decía, mientras el
    // título seguía preguntándoselo: la pantalla se contradecía hacia el lado
    // que sabe menos.
    await _hastaIncierto(
      tester,
      mensaje: 'Tu cuenta se creó, pero no recibimos la sesión.',
      codigo: 'SIN_TOKEN',
    );

    expect(find.text('Tu cuenta ya está creada'), findsOneWidget);
    expect(find.text('No pudimos confirmar si tu cuenta se creó'), findsNothing);
    // Este error sí dice algo nuevo, así que se sigue mostrando.
    expect(find.text('Tu cuenta se creó, pero no recibimos la sesión.'),
        findsOneWidget);
  });

  testWidgets('caso 7: el botón de rescate se apaga mientras el login está en vuelo',
      (tester) async {
    // Sin esto el botón no daba ningún acuse de recibo y un segundo toque
    // sobre una conexión lenta disparaba un segundo login.
    final puerta = Completer<String?>();
    await _hastaIncierto(
      tester,
      mensaje: 'No pudimos confirmar si tu cuenta se creó.',
      codigo: 'TIEMPO_AGOTADO',
      iniciarSesion: ({required code, required password}) => puerta.future,
    );

    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();

    expect(find.text('Iniciar sesión'), findsNothing,
        reason: 'el rótulo cede su lugar al spinner');
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Un login que no entra devuelve el botón a su sitio (y no navega).
    puerta.complete('Código o contraseña incorrectos.');
    await tester.pump();
    await tester.pump();
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('caso 8: desde /login se llega a /registro (RS-FE-1)', (tester) async {
    // Monta la app REAL —la tabla de rutas de main.dart y la LoginPage de
    // verdad— porque lo que hay que blindar son las dos cadenas: la de
    // `Get.toNamed` en el login y la del `GetPage` en main.dart. Con una tabla
    // de rutas escrita en el test, una de las dos podría estar mal escrita y
    // nadie se enteraría hasta ejecutar la app.
    await tester.pumpWidget(const MyApp(initialRoute: '/login'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('¿No tienes cuenta? Créala'));
    await tester.pumpAndSettle();

    expect(find.byType(RegistroPage), findsOneWidget);
    expect(find.text('Crea tu cuenta de ULima++'), findsOneWidget);
    expect(Get.currentRoute, equals('/registro'));
  });
}
