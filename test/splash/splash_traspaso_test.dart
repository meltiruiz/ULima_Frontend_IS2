// test/splash/splash_traspaso_test.dart
//
// WIDGET · Splash animado (specs/features/splash/splash.spec.md).
// RF-SPL-21 y RF-SPL-12. Sin sesión, y con la sesión de un alumno sin
// especialidad, la intro no tiene salida. El logo queda en la pose de su
// variante, la intro llega a /login por offAllToLogin con la pose como
// argumento, y la capa se retira sin fundido cuando la bienvenida pinta su
// primer cuadro. La capa queda montada e inactiva, lista para el paso al
// horario de la bienvenida.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/logo/escena_del_logo.dart';
import 'package:ulima_plus/pages/splash/capa_de_arranque.dart';
import 'package:ulima_plus/pages/splash/estado_de_la_capa.dart';
import 'package:ulima_plus/pages/splash/variantes/variantes.dart';
import 'package:ulima_plus/services/session_navigation.dart';
import 'package:ulima_plus/services/splash_variante_service.dart';

import 'apoyo_splash.dart';

PoseDelLogo _poseRecibida() =>
    (BienvenidaDePrueba.argumentos! as Map)[argumentoDePose] as PoseDelLogo;

void _igualAPose(PoseDelLogo real, PoseDelLogo esperada) {
  expect(real.centro.dx, closeTo(esperada.centro.dx, 1e-6));
  expect(real.centro.dy, closeTo(esperada.centro.dy, 1e-6));
  expect(real.radio, closeTo(esperada.radio, 1e-6));
  expect(real.cruces, hasLength(2));
  for (var i = 0; i < 2; i++) {
    expect(
      real.cruces[i].centro.dx,
      closeTo(esperada.cruces[i].centro.dx, 1e-6),
    );
    expect(
      real.cruces[i].centro.dy,
      closeTo(esperada.cruces[i].centro.dy, 1e-6),
    );
    expect(real.cruces[i].escala, closeTo(esperada.cruces[i].escala, 1e-6));
  }
}

void main() {
  setUp(reiniciarArranque);
  tearDown(reiniciarArranque);

  Future<CargaFalsa> montar(WidgetTester tester, VarianteSplash tipo) async {
    telefono(tester);
    final carga = CargaFalsa();
    await tester.pumpWidget(
      appConCapa(
        intro: IntroDelArranque(
          carga: carga.call,
          variantes: VariantesFijas(tipo),
          random: Random(1),
        ),
      ),
    );
    return carga;
  }

  for (final ruta in ['/login', '/setup-carrera']) {
    for (final tipo in VarianteSplash.values) {
      testWidgets('${tipo.name} hacia $ruta: la bienvenida recibe la pose del '
          'reposo, sin salida y sin transición', (tester) async {
        final carga = await montar(tester, tipo);
        carga.terminar(ruta);
        final v = varianteDe(tipo);
        final hasta = await avanzarHasta(
          tester,
          () => Get.currentRoute == '/login',
        );
        // El relevo llega al terminar la entrada, a los 1250, 1150 y 1330 ms,
        // más un par de cuadros (RF-SPL-17).
        expect(
          hasta,
          inInclusiveRange(v.finDeLaEntrada, v.finDeLaEntrada + 48),
        );
        final esperada = v
            .escena(
              v.finDelReposo(0),
              centro: const Offset(187.5, 333.5),
              radio: 90,
              cargaLista: 0,
            )
            .pose;
        _igualAPose(_poseRecibida(), esperada);
        expect(
          CapaDeArranque.fase,
          anyOf(FaseDeLaCapa.relevo, FaseDeLaCapa.inactiva),
        );
        expect(CapaDeArranque.salidaActual, isNull, reason: 'sin salida');
      });
    }
  }

  testWidgets('la capa se retira en cuanto la bienvenida pinta su primer '
      'cuadro, sin esperar el respaldo de 500 ms (RF-SPL-21)', (tester) async {
    final carga = await montar(tester, VarianteSplash.incremento);
    carga.terminar('/login');
    await avanzarHasta(tester, () => Get.currentRoute == '/login');
    final cuadros = await avanzarHasta(
      tester,
      () => CapaDeArranque.fase == FaseDeLaCapa.inactiva,
    );
    expect(cuadros, lessThanOrEqualTo(32));
  });

  testWidgets('antes del relevo precarga la imagen de Ulises, que entra '
      'volando apenas la bienvenida toma el relevo (RF-SPL-21)', (
    tester,
  ) async {
    final carga = await montar(tester, VarianteSplash.codigo);
    carga.terminar('/login');
    await avanzarHasta(tester, () => Get.currentRoute == '/login');
    final configuracion = createLocalImageConfiguration(
      tester.element(find.byType(CapaDeArranque)),
    );
    final clave = (await tester.runAsync(
      () => const AssetImage(
        'assets/images/ulises_chatbot.png',
      ).obtainKey(configuracion),
    ))!;
    expect(
      PaintingBinding.instance.imageCache.statusForKey(clave).tracked,
      isTrue,
    );
  });

  testWidgets('la capa se retira sin fundido cuando la bienvenida pinta su '
      'primer cuadro, y queda montada e inactiva', (tester) async {
    final semantica = tester.ensureSemantics();
    final carga = await montar(tester, VarianteSplash.ensamble);
    carga.terminar('/login');
    final opacidades = <double>[];
    await avanzarHasta(tester, () {
      opacidades.add(CapaDeArranque.opacidad);
      return CapaDeArranque.fase == FaseDeLaCapa.inactiva;
    });
    expect(opacidades.every((o) => o == 1), isTrue, reason: 'sin fundido');
    // La bienvenida avisa después de su cuadro, así que la capa inactiva se
    // dibuja en el cuadro siguiente.
    await tester.pump();
    expect(find.byType(CapaDeArranque), findsOneWidget);
    expect(EstadoDeLaCapa.cubre.value, isFalse);
    expect(find.bySemanticsLabel(etiquetaDeLaIntro), findsNothing);
    await tester.tap(find.text('bienvenida'));
    expect(toquesEnLaPagina, 1);
    expect(
      find.descendant(
        of: find.byType(CapaDeArranque),
        matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
      ),
      findsNothing,
      reason: 'inactiva no fija la barra de estado',
    );
    semantica.dispose();
  });

  testWidgets('si la carga termina en el bucle, Ensamble vuelve al reposo en '
      '300 ms antes del relevo (S-34)', (tester) async {
    final carga = await montar(tester, VarianteSplash.ensamble);
    await avanzar(tester, 2000);
    carga.terminar('/login');
    final hasta = await avanzarHasta(
      tester,
      () => Get.currentRoute == '/login',
    );
    expect(hasta, inInclusiveRange(280, 360));
    final pose = _poseRecibida();
    expect(pose.cruces[0].escala, closeTo(1, 1e-6));
  });
}
