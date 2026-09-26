// test/HU01_jeff/login_relogin_regression_test.dart
// Regresión del "tipeo fantasma" tras cerrar sesión (US02 -> US01).
//
// El mecanismo del bug. Al cerrar sesión con un token ya invalidado, el POST
// /auth/logout responde 401 y el interceptor del ApiClient navega a /login
// (Get.currentRoute aún es /perfil, así que su guarda no aplica). Acto
// seguido el handler del botón "Cerrar sesión" navega otra vez a /login. La
// segunda offAllNamed apilaba una segunda ruta /login que tomaba el mismo
// controller, y al desecharse la primera GetX disponía sus
// TextEditingController mientras la página visible los usaba. En debug y en
// test revienta con "A TextEditingController was used after being disposed".
//
// El fix. Todos los caminos que cierran sesión navegan con offAllToLogin()
// (lib/services/session_navigation.dart), que es idempotente. Desde la
// bienvenida, /login muestra la conversación con Ulises y el campo vive en el
// compositor de E1, así que cada prueba llega a E1 con «Sí, entrar».

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/pages/bienvenida/bienvenida_page.dart';
import 'package:ulima_plus/pages/login/login_binding.dart';
import 'package:ulima_plus/pages/login/login_controller.dart';
import 'package:ulima_plus/services/session_navigation.dart';

import '../bienvenida/apoyo_bienvenida.dart';

/// App mínima con la ruta /login real (la bienvenida y el LoginBinding real
/// que main.dart) y un /perfil de prueba desde donde se cierra sesión.
Widget _buildApp() {
  return GetMaterialApp(
    initialRoute: '/perfil',
    getPages: [
      GetPage(
        name: '/login',
        page: () => const BienvenidaPage(),
        binding: LoginBinding(),
      ),
      GetPage(
        name: '/perfil',
        page: () => const Scaffold(body: Center(child: Text('Perfil'))),
      ),
    ],
  );
}

void main() {
  setUp(registrarLosServiciosDeLaBienvenida);
  tearDown(Get.reset);

  testWidgets(
    'doble navegación a /login (interceptor 401 + logout del Perfil): '
    'los campos siguen repintando por tecla',
    (tester) async {
      await tester.pumpWidget(_buildApp());
      await avanzar(tester, 500);

      // 1ª navegación. Un 401 en vuelo durante el logout lleva al login.
      expect(offAllToLogin(), isTrue);
      // La primera /login llega a construirse antes de que el handler del
      // logout retome el control.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // 2ª navegación. El handler del botón "Cerrar sesión" del Perfil es un
      // no-op, porque /login ya es la ruta actual.
      expect(offAllToLogin(), isFalse);
      await avanzar(tester, 500);

      // Solo queda una bienvenida visible.
      expect(find.byType(BienvenidaPage), findsOneWidget);

      // El usuario teclea su código y el texto se ve sin quitar el foco.
      await llegarAE1(tester);
      await tester.enterText(find.byType(TextField).first, '20230001');
      await tester.pump();
      expect(find.text('20230001'), findsOneWidget);
    },
  );

  testWidgets(
    'rebuild provocado por un Rx que envuelve al campo (passwordVisible): '
    'el campo sigue mostrando lo tecleado',
    (tester) async {
      await tester.pumpWidget(_buildApp());
      await avanzar(tester, 500);

      Get.offAllNamed('/login');
      await avanzar(tester, 500);
      await llegarAE1(tester);
      await llegarAE2(tester);

      final controller = Get.find<LoginController>();

      // Teclea en la contraseña de E2, envuelta en Obx por passwordVisible,
      // provoca un rebuild cambiando el Rx y sigue tecleando.
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
