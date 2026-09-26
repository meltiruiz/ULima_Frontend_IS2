// test/splash/splash_reducir_movimiento_test.dart
//
// WIDGET · Splash animado (specs/features/splash/splash.spec.md).
// RF-SPL-14. Con «reducir movimiento» no hay variante, la estrella queda
// fija, los «++» aparecen con un fundido de 200 ms y la capa se desvanece en
// 250 ms sobre /home. Hacia la bienvenida se retira sin fundido.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ulima_plus/pages/splash/capa_de_arranque.dart';
import 'package:ulima_plus/services/splash_variante_service.dart';

import 'apoyo_splash.dart';

void main() {
  setUp(reiniciarArranque);
  tearDown(reiniciarArranque);

  Future<(CargaFalsa, VariantesFijas)> montar(WidgetTester tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    SharedPreferences.setMockInitialValues(<String, Object>{});
    telefono(tester);
    final carga = CargaFalsa();
    final variantes = VariantesFijas(VarianteSplash.ensamble);
    await tester.pumpWidget(
      appConCapa(
        intro: IntroDelArranque(
          carga: carga.call,
          variantes: variantes,
          random: Random(1),
        ),
        home: (_) => const HomeDePrueba(),
      ),
    );
    return (carga, variantes);
  }

  testWidgets('no hay variante, nada se mueve y los «++» aparecen en 200 ms', (
    tester,
  ) async {
    final (_, variantes) = await montar(tester);
    expect(
      CapaDeArranque.escenaActual!.cruces.every((c) => c.opacidad == 0),
      isTrue,
    );
    await avanzar(tester, 100);
    expect(variantes.lecturas, 0, reason: 'ni se lee ni se escribe la clave');
    final medio = CapaDeArranque.escenaActual!;
    // A la mitad de los 200 ms del fundido.
    expect(medio.cruces.first.opacidad, closeTo(0.5, 0.12));
    expect(medio.cruces.first.escala, 1);
    await avanzar(tester, 112);
    expect(
      CapaDeArranque.escenaActual!.cruces.every((c) => c.opacidad == 1),
      isTrue,
      reason: 'el fundido dura 200 ms',
    );
    await avanzar(tester, 1500);
    final quieta = CapaDeArranque.escenaActual!;
    expect(quieta.cruces.every((c) => c.opacidad == 1), isTrue);
    expect(quieta.giro, 0);
    expect(quieta.rombos.every((r) => r.desplazamiento == 0), isTrue);
    expect(quieta.centro, const Offset(187.5, 333.5));
  });

  testWidgets('con la carga lista navega a /home y la capa se desvanece en '
      '250 ms', (tester) async {
    final (carga, _) = await montar(tester);
    await avanzar(tester, 300);
    carga.terminar('/home');
    await avanzarHasta(
      tester,
      () => CapaDeArranque.fase == FaseDeLaCapa.fundido,
    );
    expect(Get.currentRoute, '/home');
    final dura = await avanzarHasta(
      tester,
      () => CapaDeArranque.fase == FaseDeLaCapa.inactiva,
    );
    expect(dura, inInclusiveRange(240, 290));
  });

  testWidgets('hacia la bienvenida la capa se retira sin fundido', (
    tester,
  ) async {
    final (carga, _) = await montar(tester);
    await avanzar(tester, 300);
    carga.terminar('/login');
    await avanzarHasta(tester, () => Get.currentRoute == '/login');
    final opacidades = <double>[];
    final cuadros = await avanzarHasta(tester, () {
      opacidades.add(CapaDeArranque.opacidad);
      return CapaDeArranque.fase == FaseDeLaCapa.inactiva;
    });
    expect(opacidades.every((o) => o == 1), isTrue);
    // Se retira con el primer cuadro de la bienvenida, no con el respaldo.
    expect(cuadros, lessThanOrEqualTo(32));
    expect(Get.currentRoute, '/login');
  });
}
