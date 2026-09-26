// test/bienvenida/bienvenida_barra_estado_test.dart
//
// WIDGET · Bienvenida con Ulises (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-17. La bienvenida declara íconos claros en los dos temas y, en una
// pantalla ancha, la conversación va en una columna de 600 dp centrada.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/pages/bienvenida/bienvenida_page.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/compositor.dart';
import 'package:ulima_plus/services/session_navigation.dart';

import 'apoyo_bienvenida.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  for (final brillo in Brightness.values) {
    testWidgets('íconos claros en ${brillo.name}', (tester) async {
      await montarLaBienvenida(
        tester,
        Bienvenida(),
        brillo: brillo,
        argumentos: const {argumentoDeMotivo: MotivoDeLlegada.expirada},
      );
      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find
            .descendant(
              of: find.byType(BienvenidaPage),
              matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
            )
            .first,
      );
      expect(region.value.statusBarIconBrightness, Brightness.light);
      expect(region.value.statusBarBrightness, Brightness.dark);
    });
  }

  testWidgets('en una pantalla ancha, una columna de 600 dp centrada', (
    tester,
  ) async {
    await montarLaBienvenida(
      tester,
      Bienvenida(),
      pantalla: const Size(1024, 768),
      argumentos: const {argumentoDeMotivo: MotivoDeLlegada.expirada},
    );
    await avanzar(tester, 1500);
    final compositor = tester.getRect(find.byType(MarcoDelCompositor));
    expect(compositor.width, lessThanOrEqualTo(600));
    expect(compositor.center.dx, closeTo(512, 0.5));
    // La conversación, no solo el compositor, va en la misma columna.
    final conversacion = tester.getRect(
      find.descendant(
        of: find.byType(BienvenidaPage),
        matching: find.byType(ListView),
      ),
    );
    expect(conversacion.width, 600);
    expect(conversacion.center.dx, closeTo(512, 0.5));
  });
}
