// test/login_navigation_paths_test.dart
//
// Blindaje contra el "TIPEO FANTASMA" en /login: batería que ejercita TODOS
// los caminos por los que la app llega a la pantalla de login, verificando que
// los campos repintan lo tecleado (es decir, que el LoginController y sus
// TextEditingController siguen vivos y notificando).
//
// ── El bug ────────────────────────────────────────────────────────────────
// Con un binding normal (`Get.lazyPut`), si se navega a /login con
// offAllNamed('/login') y ya había OTRA ruta /login en el stack, al eliminarse
// la vieja GetX dispone el LoginController asociado a ese tag (incluso el que
// la pantalla visible está usando). En release un ChangeNotifier disposed deja
// de notificar: el TextField recibe cada tecla pero repinta tarde ("se demora
// en presentarse lo tecleado"). En debug/test revienta con "A
// TextEditingController was used after being disposed".
//
// Se manifestó en el flujo login → "¿olvidaste tu contraseña?" → reset →
// offAllNamed('/login') (la /login original queda enterrada en el stack). El
// fix de PR #111 (offAllToLogin idempotente) cubría la DOBLE navegación
// (logout + 401) pero NO este caso de una sola navegación con /login enterrada.
//
// ── El fix ────────────────────────────────────────────────────────────────
// El LoginController se registra PERMANENTE (lib/pages/login/login_binding.dart):
// GetX no lo dispone por cambios de ruta, así que sus TextEditingController
// nunca mueren bajo la pantalla visible, sin importar el estado del stack. Al
// reingresar se limpian los campos (resetFields, post-frame) para no arrastrar
// lo tecleado por un usuario anterior en el mismo dispositivo.
//
// Cada test reproduce un camino con las rutas/binding REALES; sin el fix, los
// tests de "reset desde login" y "login↔forgot repetido" fallan con el error
// de TextEditingController disposed.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/pages/login/login_binding.dart';
import 'package:ulima_plus/pages/login/login_controller.dart';
import 'package:ulima_plus/pages/login/login_page.dart';
import 'package:ulima_plus/services/session_navigation.dart';

/// App de prueba con la ruta /login REAL (misma page y el LoginBinding real) y
/// stubs para las demás rutas que participan en cada camino.
Widget _buildApp({required String initialRoute}) {
  Widget stub(String label) => Scaffold(body: Center(child: Text(label)));
  return GetMaterialApp(
    initialRoute: initialRoute,
    getPages: [
      GetPage(
        name: '/login',
        page: () => const LoginPage(),
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

/// Teclea en el campo de código de /login y verifica que se ve lo tecleado
/// (si el controller estuviera disposed, esto reventaría o no repintaría).
Future<void> _typeAndVerify(WidgetTester tester, String texto) async {
  expect(find.byType(LoginPage), findsOneWidget);
  await tester.enterText(find.byType(TextField).first, texto);
  await tester.pump();
  expect(find.text(texto), findsOneWidget);
}

void main() {
  tearDown(Get.reset);

  testWidgets(
    'el campo de código usa teclado de TEXTO (el docente/JP ingresa un usuario '
    'alfanumérico como "hquintan", no un código numérico)',
    (tester) async {
      await tester.pumpWidget(_buildApp(initialRoute: '/login'));
      await tester.pumpAndSettle();

      // El primer TextField es el de código; el segundo, la contraseña.
      final codeField = tester.widget<TextField>(find.byType(TextField).first);
      expect(codeField.keyboardType, TextInputType.text);
    },
  );

  testWidgets(
    'Camino 1 — reset desde el login (login → forgot → reset → offAllToLogin): '
    'era el bug; los campos repintan por tecla',
    (tester) async {
      await tester.pumpWidget(_buildApp(initialRoute: '/login'));
      await tester.pumpAndSettle();

      // "¿Olvidaste tu contraseña?" apila forgot sobre /login (queda enterrada).
      Get.toNamed('/forgot-password');
      await tester.pumpAndSettle();
      Get.toNamed('/reset-password', arguments: {'identifier': '20230000'});
      await tester.pumpAndSettle();

      // Reset exitoso: navega a /login (una sola vez).
      expect(offAllToLogin(), isTrue);
      await tester.pumpAndSettle();

      await _typeAndVerify(tester, '20230000');
    },
  );

  testWidgets(
    'Camino 2 — reset desde el Perfil (autenticado; /login NO estaba en el stack)',
    (tester) async {
      await tester.pumpWidget(_buildApp(initialRoute: '/home'));
      await tester.pumpAndSettle();
      Get.toNamed('/perfil');
      await tester.pumpAndSettle();
      Get.toNamed('/reset-password', arguments: {'identifier': '20230000'});
      await tester.pumpAndSettle();

      expect(offAllToLogin(), isTrue);
      await tester.pumpAndSettle();

      await _typeAndVerify(tester, '20231111');
    },
  );

  testWidgets(
    'Camino 3 — logout normal desde el Perfil (/home → perfil → offAllToLogin)',
    (tester) async {
      await tester.pumpWidget(_buildApp(initialRoute: '/home'));
      await tester.pumpAndSettle();
      Get.toNamed('/perfil');
      await tester.pumpAndSettle();

      expect(offAllToLogin(), isTrue);
      await tester.pumpAndSettle();

      await _typeAndVerify(tester, '20232222');
    },
  );

  testWidgets(
    'Camino 4 - logout del docente (home shell -> offAllToLogin) [TT09]',
    (tester) async {
      await tester.pumpWidget(_buildApp(initialRoute: '/home'));
      await tester.pumpAndSettle();

      expect(offAllToLogin(), isTrue);
      await tester.pumpAndSettle();

      await _typeAndVerify(tester, 'hquintan');
    },
  );

  testWidgets(
    'Camino 5 — doble navegación (interceptor 401 + logout): la 2ª es no-op',
    (tester) async {
      await tester.pumpWidget(_buildApp(initialRoute: '/perfil'));
      await tester.pumpAndSettle();

      expect(offAllToLogin(), isTrue); // 401 en vuelo
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(offAllToLogin(), isFalse); // handler del botón: ya en /login
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      await _typeAndVerify(tester, '20233333');
    },
  );

  testWidgets('Camino 6 — arranque directo en /login (initialRoute)', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(initialRoute: '/login'));
    await tester.pumpAndSettle();
    await _typeAndVerify(tester, '20234444');
  });

  testWidgets(
    'Camino 7 — login ↔ forgot repetido y luego reset (varias /login enterradas)',
    (tester) async {
      await tester.pumpWidget(_buildApp(initialRoute: '/login'));
      await tester.pumpAndSettle();

      // Ir y volver de forgot varias veces (cada ida apila sobre /login).
      for (var i = 0; i < 3; i++) {
        Get.toNamed('/forgot-password');
        await tester.pumpAndSettle();
        Get.back();
        await tester.pumpAndSettle();
      }
      // Ahora sí completa el reset.
      Get.toNamed('/forgot-password');
      await tester.pumpAndSettle();
      Get.toNamed('/reset-password', arguments: {'identifier': '20230000'});
      await tester.pumpAndSettle();
      expect(offAllToLogin(), isTrue);
      await tester.pumpAndSettle();

      await _typeAndVerify(tester, '20235555');
    },
  );

  testWidgets(
    'resetFields — el login no arrastra lo tecleado por un usuario anterior '
    '(mismo dispositivo, dos usuarios)',
    (tester) async {
      await tester.pumpWidget(_buildApp(initialRoute: '/login'));
      await tester.pumpAndSettle();

      // Usuario A teclea su código y "pasa" a forgot y reset.
      await tester.enterText(find.byType(TextField).first, 'AAA11111');
      await tester.pump();
      Get.toNamed('/forgot-password');
      await tester.pumpAndSettle();
      Get.toNamed('/reset-password', arguments: {'identifier': 'AAA11111'});
      await tester.pumpAndSettle();
      offAllToLogin();
      await tester.pumpAndSettle();

      // Al volver a /login el campo debe estar LIMPIO (no muestra AAA11111).
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
      await tester.pumpAndSettle();
      Get.toNamed('/forgot-password');
      await tester.pumpAndSettle();
      Get.toNamed('/reset-password', arguments: {'identifier': '20230000'});
      await tester.pumpAndSettle();
      offAllToLogin();
      await tester.pumpAndSettle();

      final controller = Get.find<LoginController>();
      final passwordField = find.byType(TextField).at(1);
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
