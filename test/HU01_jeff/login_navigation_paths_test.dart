// test/HU01_jeff/login_navigation_paths_test.dart
//
// Blindaje contra el "TIPEO FANTASMA" en /login. La batería ejercita todos los
// caminos por los que la app llega al login y verifica que los campos
// repintan lo tecleado, es decir, que el LoginController y sus
// TextEditingController siguen vivos y notificando.
//
// ── El bug ────────────────────────────────────────────────────────────────
// Con un binding normal (`Get.lazyPut`), si se navega a /login con
// offAllNamed('/login') y ya había otra ruta /login en el stack, al
// eliminarse la vieja GetX dispone el LoginController asociado a ese tag,
// incluso el que la pantalla visible está usando. En release un
// ChangeNotifier disposed deja de notificar y el TextField repinta tarde. En
// debug y en test revienta con "A TextEditingController was used after being
// disposed". Se manifestó en el flujo login → "¿Olvidaste tu contraseña?" →
// reset → offAllNamed('/login'), con la /login original enterrada.
//
// ── El fix ────────────────────────────────────────────────────────────────
// LoginBinding registra el LoginController como permanente, y desde la
// bienvenida (specs/features/bienvenida) también el BienvenidaController. GetX
// no los dispone por cambios de ruta. Al reingresar se limpian los campos
// (resetFields, después del cuadro).
//
// ── La bienvenida ─────────────────────────────────────────────────────────
// /login muestra la conversación con Ulises. El campo del código vive en el
// compositor de E1, con los TextEditingController del LoginController. Cada
// camino llega a E1 con «Sí, entrar» y teclea ahí. Los servicios son dobles
// sin red y los datos, inventados.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/pages/bienvenida/bienvenida_page.dart';
import 'package:ulima_plus/pages/login/login_binding.dart';
import 'package:ulima_plus/pages/login/login_controller.dart';
import 'package:ulima_plus/services/session_navigation.dart';

import '../bienvenida/apoyo_bienvenida.dart';

/// App de prueba con la ruta /login real (la bienvenida y el LoginBinding
/// real) y páginas simples para las demás rutas de cada camino.
Widget _buildApp({required String initialRoute}) {
  Widget stub(String label) => Scaffold(body: Center(child: Text(label)));
  return GetMaterialApp(
    initialRoute: initialRoute,
    getPages: [
      GetPage(
        name: '/login',
        page: () => const BienvenidaPage(),
        binding: LoginBinding(),
      ),
      GetPage(name: '/forgot-password', page: () => stub('forgot')),
      GetPage(name: '/reset-password', page: () => stub('reset')),
      GetPage(name: '/home', page: () => stub('home')),
      GetPage(name: '/perfil', page: () => stub('perfil')),
      GetPage(name: '/setup-carrera', page: () => stub('setup')),
    ],
  );
}

/// Espera las transiciones de GetX.
Future<void> _transicion(WidgetTester tester) => avanzar(tester, 500);

/// Llega a E1, teclea en el campo del código y verifica que se ve lo
/// tecleado. Si el controller estuviera disposed, reventaría o no repintaría.
Future<void> _typeAndVerify(WidgetTester tester, String texto) async {
  expect(find.byType(BienvenidaPage), findsOneWidget);
  await llegarAE1(tester);
  await tester.enterText(find.byType(TextField).first, texto);
  await tester.pump();
  expect(find.text(texto), findsOneWidget);
}

void main() {
  setUp(registrarLosServiciosDeLaBienvenida);
  tearDown(Get.reset);

  testWidgets(
    'el campo de código usa teclado de TEXTO (el docente/JP ingresa un usuario '
    'alfanumérico como "docente.test", no un código numérico)',
    (tester) async {
      await tester.pumpWidget(_buildApp(initialRoute: '/login'));
      await llegarAE1(tester);

      final codeField = tester.widget<TextField>(find.byType(TextField).first);
      expect(codeField.keyboardType, TextInputType.text);
    },
  );

  testWidgets(
    'Camino 1 — reset desde el login (login → forgot → reset → offAllToLogin): '
    'era el bug; los campos repintan por tecla',
    (tester) async {
      await tester.pumpWidget(_buildApp(initialRoute: '/login'));
      await _transicion(tester);

      // "¿Olvidaste tu contraseña?" apila forgot sobre /login (queda enterrada).
      Get.toNamed('/forgot-password');
      await _transicion(tester);
      Get.toNamed('/reset-password', arguments: {'identifier': '20230000'});
      await _transicion(tester);

      // Reset exitoso, que navega a /login una sola vez.
      expect(offAllToLogin(), isTrue);
      await _transicion(tester);

      await _typeAndVerify(tester, '20230000');
    },
  );

  testWidgets(
    'Camino 2 — reset desde el Perfil (autenticado; /login NO estaba en el stack)',
    (tester) async {
      await tester.pumpWidget(_buildApp(initialRoute: '/home'));
      await _transicion(tester);
      Get.toNamed('/perfil');
      await _transicion(tester);
      Get.toNamed('/reset-password', arguments: {'identifier': '20230000'});
      await _transicion(tester);

      expect(offAllToLogin(), isTrue);
      await _transicion(tester);

      await _typeAndVerify(tester, '20231111');
    },
  );

  testWidgets(
    'Camino 3 — logout normal desde el Perfil (/home → perfil → offAllToLogin)',
    (tester) async {
      await tester.pumpWidget(_buildApp(initialRoute: '/home'));
      await _transicion(tester);
      Get.toNamed('/perfil');
      await _transicion(tester);

      expect(offAllToLogin(), isTrue);
      await _transicion(tester);

      await _typeAndVerify(tester, '20232222');
    },
  );

  testWidgets(
    'Camino 4 - logout del docente (home shell -> offAllToLogin) [TT09]',
    (tester) async {
      await tester.pumpWidget(_buildApp(initialRoute: '/home'));
      await _transicion(tester);

      expect(offAllToLogin(), isTrue);
      await _transicion(tester);

      await _typeAndVerify(tester, 'docente.test');
    },
  );

  testWidgets(
    'Camino 5 — doble navegación (interceptor 401 + logout): la 2ª es no-op',
    (tester) async {
      await tester.pumpWidget(_buildApp(initialRoute: '/perfil'));
      await _transicion(tester);

      expect(offAllToLogin(), isTrue); // 401 en vuelo
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(offAllToLogin(), isFalse); // handler del botón: ya en /login
      await _transicion(tester);

      await _typeAndVerify(tester, '20233333');
    },
  );

  testWidgets('Camino 6 — arranque directo en /login (initialRoute)', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(initialRoute: '/login'));
    await _typeAndVerify(tester, '20234444');
  });

  testWidgets(
    'Camino 7 — login ↔ forgot repetido y luego reset (varias /login enterradas)',
    (tester) async {
      await tester.pumpWidget(_buildApp(initialRoute: '/login'));
      await _transicion(tester);

      // Ir y volver de forgot varias veces (cada ida apila sobre /login).
      for (var i = 0; i < 3; i++) {
        Get.toNamed('/forgot-password');
        await _transicion(tester);
        Get.back();
        await _transicion(tester);
      }
      // Ahora sí completa el reset.
      Get.toNamed('/forgot-password');
      await _transicion(tester);
      Get.toNamed('/reset-password', arguments: {'identifier': '20230000'});
      await _transicion(tester);
      expect(offAllToLogin(), isTrue);
      await _transicion(tester);

      await _typeAndVerify(tester, '20235555');
    },
  );

  testWidgets(
    'resetFields — el login no arrastra lo tecleado por un usuario anterior '
    '(mismo dispositivo, dos usuarios)',
    (tester) async {
      await tester.pumpWidget(_buildApp(initialRoute: '/login'));
      await llegarAE1(tester);

      // Usuario A teclea su código y "pasa" a forgot y reset.
      await tester.enterText(find.byType(TextField).first, 'AAA11111');
      await tester.pump();
      Get.toNamed('/forgot-password');
      await _transicion(tester);
      Get.toNamed('/reset-password', arguments: {'identifier': 'AAA11111'});
      await _transicion(tester);
      offAllToLogin();
      await _transicion(tester);

      // Al volver a /login el campo está limpio y la conversación, vacía.
      expect(find.text('AAA11111'), findsNothing);
      expect(Get.find<LoginController>().codeController.text, '');

      // Usuario B teclea y se ve normal.
      await _typeAndVerify(tester, 'BBB22222');
    },
  );

  testWidgets(
    'passwordVisible — un rebuild por Rx no rompe el campo tras el reset',
    (tester) async {
      await tester.pumpWidget(_buildApp(initialRoute: '/login'));
      await _transicion(tester);
      Get.toNamed('/forgot-password');
      await _transicion(tester);
      Get.toNamed('/reset-password', arguments: {'identifier': '20230000'});
      await _transicion(tester);
      offAllToLogin();
      await _transicion(tester);
      await llegarAE1(tester);
      await llegarAE2(tester);

      // En E2 el compositor muestra solo el campo de la contraseña. El del
      // código sigue montado fuera de la vista, para el autocompletado.
      final controller = Get.find<LoginController>();
      final passwordField = find.byType(TextField).first;
      await tester.enterText(passwordField, 'secreta');
      await tester.pump();
      controller.passwordVisible.toggle();
      await tester.pump();
      await tester.enterText(passwordField, 'secreta123');
      await tester.pump();

      expect(controller.passwordController.text, 'secreta123');
      expect(find.text('secreta123'), findsOneWidget);
    },
  );
}
