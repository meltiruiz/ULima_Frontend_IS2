// test/splash/splash_png_nativo_test.dart
//
// UNITARIA · Splash animado (specs/features/splash/splash.spec.md).
// RF-SPL-1 y RF-SPL-3. La estrella del splash nativo sale del mismo pintor
// que la intro, con R = 360 px en un lienzo transparente de 1152 × 1152.
//
// Con `flutter test --update-goldens` esta prueba escribe
// assets/splash/splash_estrella.png. Sin la bandera, comprueba el PNG del
// repo con una tolerancia y no con la comparación exacta de
// `matchesGoldenFile`, porque el suavizado cambia entre macOS y Linux.

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/components/logo/escena_del_logo.dart';
import 'package:ulima_plus/components/logo/pintor_del_logo.dart';

const double _lado = 1152;
const String _png = 'assets/splash/splash_estrella.png';

/// Un umbral de 48 niveles de alfa, en a lo sumo el 1 % de los píxeles, cubre
/// el suavizado de los bordes y nada más.
const int _umbral = 48;
const double _fraccionTolerada = 0.01;

class _Rgba {
  const _Rgba(this.ancho, this.alto, this.bytes);

  final int ancho;
  final int alto;
  final ByteData bytes;

  int alfa(int x, int y) => bytes.getUint8((y * ancho + x) * 4 + 3);
}

Future<_Rgba> _pintado(WidgetTester tester, GlobalKey clave) async {
  final frontera =
      clave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final imagen = (await tester.runAsync(() => frontera.toImage()))!;
  final datos = (await tester.runAsync(
    () => imagen.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  return _Rgba(imagen.width, imagen.height, datos);
}

Future<_Rgba> _delArchivo(WidgetTester tester) async {
  final bytes = File(_png).readAsBytesSync();
  final imagen = (await tester.runAsync(() async {
    final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
    return (await codec.getNextFrame()).image;
  }))!;
  final datos = (await tester.runAsync(
    () => imagen.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  return _Rgba(imagen.width, imagen.height, datos);
}

void main() {
  testWidgets('el PNG del nativo es la estrella de la geometría, sin «++», '
      'con R = 360 px', (tester) async {
    tester.view.physicalSize = const Size(_lado, _lado);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final clave = GlobalKey();
    final escena = ValueNotifier(
      EscenaDelLogo.reposo(
        centro: const Offset(_lado / 2, _lado / 2),
        radio: 360,
        conCruces: false,
      ),
    );
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RepaintBoundary(
            key: clave,
            child: SizedBox(
              width: _lado,
              height: _lado,
              child: CustomPaint(painter: PintorDelLogo(escena)),
            ),
          ),
        ),
      ),
    );

    if (autoUpdateGoldenFiles) {
      await expectLater(find.byKey(clave), matchesGoldenFile('../../$_png'));
      return;
    }

    expect(File(_png).existsSync(), isTrue, reason: 'falta $_png');
    final delRepo = await _delArchivo(tester);
    expect(delRepo.ancho, 1152);
    expect(delRepo.alto, 1152);

    for (final (x, y) in [(0, 0), (1151, 0), (0, 1151), (1151, 1151)]) {
      expect(delRepo.alfa(x, y), 0, reason: 'la esquina ($x, $y)');
    }

    var fuera = 0;
    var distintos = 0;
    final pintado = await _pintado(tester, clave);
    for (var y = 0; y < 1152; y++) {
      for (var x = 0; x < 1152; x++) {
        final a = delRepo.alfa(x, y);
        final distancia = math.sqrt(
          math.pow(x + 0.5 - 576, 2) + math.pow(y + 0.5 - 576, 2),
        );
        if (a > 0 && distancia > 384) fuera++;
        if ((a - pintado.alfa(x, y)).abs() > _umbral) distintos++;
      }
    }
    expect(fuera, 0, reason: 'ningún píxel blanco a más de 384 px del centro');
    expect(
      distintos / (1152 * 1152),
      lessThanOrEqualTo(_fraccionTolerada),
      reason: 'el PNG del repo no coincide con la geometría',
    );
  });

  test('assets/splash no entra en los assets de Flutter', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final assets = RegExp(
      r'^  assets:\n((?:    - .*\n)+)',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1)!;
    expect(assets, isNot(contains('assets/splash')));
  });

  test('flutter_native_splash usa el PNG nuevo en Android 12 o superior y en '
      'los demás, sobre #E77330 y sin variantes oscuras', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final bloque = pubspec.substring(
      pubspec.indexOf('flutter_native_splash:\n'),
    );
    final hasta = bloque.indexOf('\n\n');
    final config = bloque.substring(0, hasta);
    expect(config, contains('image: $_png'));
    expect(RegExp('image: $_png').allMatches(config), hasLength(2));
    expect(RegExp('color: "#E77330"').allMatches(config), hasLength(2));
    expect(config, isNot(contains('_dark')));
    expect(config, isNot(contains('icon_background_color')));
  });
}
