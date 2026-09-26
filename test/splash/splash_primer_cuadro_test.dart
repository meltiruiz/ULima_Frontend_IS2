// test/splash/splash_primer_cuadro_test.dart
//
// WIDGET · Splash animado (specs/features/splash/splash.spec.md).
// RF-SPL-5. El primer cuadro de Flutter pinta #E77330 de borde a borde y la
// estrella del nativo con R = 90 dp, sin «++» ni giro, centrada en la mitad
// del alto de la pantalla física. Es una guarda de regresión contra
// assets/splash/splash_estrella.png compuesto sobre #E77330, con tolerancia
// (S-18). La equivalencia real la comprueba la grabación de «Verificación».

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/pages/splash/capa_de_arranque.dart';
import 'package:ulima_plus/services/splash_variante_service.dart';

import 'apoyo_splash.dart';

Future<ByteData> _rgba(WidgetTester tester, ui.Image imagen) async =>
    (await tester.runAsync(
      () => imagen.toByteData(format: ui.ImageByteFormat.rawRgba),
    ))!;

void main() {
  setUp(reiniciarArranque);
  tearDown(reiniciarArranque);

  test('el centro es la mitad del alto de la pantalla física', () {
    expect(
      centroDelNativo(const Size(375, 627), const Size(375, 667)),
      const Offset(187.5, 333.5),
    );
    // Sin medida de la pantalla, o si no alcanza a la vista, la vista.
    expect(
      centroDelNativo(const Size(375, 667), Size.zero),
      const Offset(187.5, 333.5),
    );
  });

  testWidgets('si la vista llega en 0 × 0, la estrella se centra en cuanto '
      'llegan sus medidas, antes de que la intro empiece (RF-SPL-5)', (
    tester,
  ) async {
    // En Android en release, las métricas de la ventana pueden llegar
    // después de runApp, que ahora va antes de Firebase.
    tester.view.physicalSize = Size.zero;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      appConCapa(
        intro: IntroDelArranque(
          carga: CargaFalsa().call,
          variantes: VariantesFijas(VarianteSplash.ensamble, enseguida: false),
          random: Random(1),
        ),
      ),
    );
    telefono(tester);
    await tester.pump();
    final escena = CapaDeArranque.escenaActual!;
    expect(escena.centro, const Offset(187.5, 333.5));
    expect(escena.radio, 90);
    expect(escena.cruces, isEmpty);
  });

  testWidgets('en Android 12 a 14 con tres botones la estrella se centra en '
      'la pantalla física y no en la vista (S-21)', (tester) async {
    telefono(tester, alto: 627, altoFisico: 667);
    final carga = CargaFalsa();
    await tester.pumpWidget(
      appConCapa(
        intro: IntroDelArranque(
          carga: carga.call,
          variantes: VariantesFijas(VarianteSplash.ensamble, enseguida: false),
          random: Random(1),
        ),
      ),
    );
    final escena = CapaDeArranque.escenaActual!;
    expect(escena.centro, const Offset(187.5, 333.5));
    expect(escena.radio, 90);
    expect(escena.cruces, isEmpty);
    expect(escena.giro, 0);
  });

  testWidgets('el primer cuadro, pintado a 4x, coincide con el PNG del nativo '
      'sobre #E77330', (tester) async {
    telefono(tester, ancho: 288, alto: 640, dpr: 4);
    final clave = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: clave,
        child: appConCapa(
          intro: IntroDelArranque(
            carga: CargaFalsa().call,
            variantes: VariantesFijas(VarianteSplash.codigo, enseguida: false),
            random: Random(1),
          ),
        ),
      ),
    );
    final frontera =
        clave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final cuadro = (await tester.runAsync(
      () => frontera.toImage(pixelRatio: 4),
    ))!;
    expect(cuadro.width, 1152);
    expect(cuadro.height, 2560);
    final pantalla = await _rgba(tester, cuadro);

    final bytes = File('assets/splash/splash_estrella.png').readAsBytesSync();
    final png = (await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
      return (await codec.getNextFrame()).image;
    }))!;
    final nativo = await _rgba(tester, png);

    // El azul separa el blanco (255) del #E77330 (48).
    var distintos = 0;
    const arriba = 1280 - 576;
    for (var y = 0; y < 1152; y++) {
      for (var x = 0; x < 1152; x++) {
        final alfa = nativo.getUint8((y * 1152 + x) * 4 + 3) / 255;
        final esperado = 48 + (255 - 48) * alfa;
        final real = pantalla.getUint8(((y + arriba) * 1152 + x) * 4 + 2);
        if ((real - esperado).abs() > 48) distintos++;
      }
    }
    expect(distintos / (1152 * 1152), lessThanOrEqualTo(0.01));
    // Sin «++». El centro de cada cruz, a (308,7; −133,8) u y
    // (402,5; −133,8) u de la estrella, queda en el naranja del fondo.
    const pxPorUnidad = 4 * 90 / 354.8;
    for (final dx in [308.7, 402.5]) {
      final x = (576 + dx * pxPorUnidad).round();
      final y = (1280 - 133.8 * pxPorUnidad).round();
      expect(
        pantalla.getUint8((y * 1152 + x) * 4 + 2),
        closeTo(48, 4),
        reason: 'la cruz de $dx u no se pinta en el primer cuadro',
      );
    }
    // Arriba y abajo del cuadrado, #E77330 de borde a borde.
    expect(pantalla.getUint8((10 * 1152 + 10) * 4 + 2), 48);
    expect(pantalla.getUint8((2550 * 1152 + 1140) * 4 + 2), 48);
  });
}
