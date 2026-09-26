// test/splash/splash_geometria_test.dart
//
// UNITARIA · Splash animado (specs/features/splash/splash.spec.md).
// RF-SPL-2 fija una sola geometría del logo, con los ocho rombos y la
// estrella central retraídos 3,5 u, la silueta sin retraer y las dos cruces.
// Archivo probado lib/components/logo/logo_geometria.dart.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/components/logo/escena_del_logo.dart';
import 'package:ulima_plus/components/logo/logo_geometria.dart';
import 'package:ulima_plus/components/logo/pintor_del_logo.dart';

/// Distancia con signo de [p] a la recta de [a] a [b]. Es positiva a la
/// derecha del sentido de avance.
double _distancia(Offset p, Offset a, Offset b) {
  final d = b - a;
  final n = Offset(-d.dy, d.dx) / d.distance;
  final v = p - a;
  return v.dx * n.dx + v.dy * n.dy;
}

/// Comprueba que cada lado de [retraido] queda a 3,5 u de su lado en
/// [original], hacia adentro.
void _seRetrae(List<Offset> retraido, List<Offset> original) {
  expect(retraido.length, original.length);
  final signo = _distancia(_centroide(original), original[0], original[1]).sign;
  for (var i = 0; i < original.length; i++) {
    final a = original[i];
    final b = original[(i + 1) % original.length];
    for (final p in [retraido[i], retraido[(i + 1) % retraido.length]]) {
      final d = _distancia(p, a, b) * signo;
      expect(d, closeTo(LogoGeometria.retraimiento, 0.2), reason: 'lado $i');
    }
  }
}

Offset _centroide(List<Offset> puntos) =>
    puntos.reduce((a, b) => a + b) / puntos.length.toDouble();

double _alcance(List<Offset> puntos) =>
    puntos.map((p) => (p - LogoGeometria.centroSvg).distance).reduce(math.max);

void main() {
  group('la geometría (RF-SPL-2)', () {
    test('ocho rombos de cuatro vértices y una estrella central de 16', () {
      expect(LogoGeometria.rombosSvg, hasLength(8));
      expect(LogoGeometria.rombosSinRetraerSvg, hasLength(8));
      for (final r in LogoGeometria.rombosSvg) {
        expect(r, hasLength(4));
      }
      expect(LogoGeometria.estrellaCentralSvg, hasLength(16));
      expect(LogoGeometria.estrellaCentralSinRetraerSvg, hasLength(16));
      expect(LogoGeometria.rombos, hasLength(8));
    });

    test('el rombo 0 está arriba y los demás siguen en sentido horario', () {
      for (var k = 0; k < 8; k++) {
        final angulo = k * math.pi / 4;
        final d = LogoGeometria.direccionesDeRombo[k];
        expect(d.dx, closeTo(math.sin(angulo), 0.02), reason: 'rombo $k');
        expect(d.dy, closeTo(-math.cos(angulo), 0.02), reason: 'rombo $k');
        expect(d.distance, closeTo(1, 1e-9));
      }
    });

    test('cada polígono se retrae 3,5 u, que deja la rendija de 7 u', () {
      for (var k = 0; k < 8; k++) {
        _seRetrae(
          LogoGeometria.rombosSvg[k],
          LogoGeometria.rombosSinRetraerSvg[k],
        );
      }
      _seRetrae(
        LogoGeometria.estrellaCentralSvg,
        LogoGeometria.estrellaCentralSinRetraerSvg,
      );
    });

    test('la punta sin retraer llega a 354,8 u y la retraída a 88,5 dp con '
        'R = 90 dp', () {
      final sinRetraer = LogoGeometria.rombosSinRetraerSvg.map(_alcance);
      expect(sinRetraer.reduce(math.max), closeTo(354.8, 0.1));
      final retraida = LogoGeometria.rombosSvg.map(_alcance).reduce(math.max);
      expect(retraida * LogoGeometria.unidad(90), closeTo(88.5, 0.1));
    });

    test('la silueta sin retraer cubre la rendija y los polígonos retraídos '
        'no', () {
      // Un punto a 2 u del lado que comparten el rombo 0 y la estrella
      // central, del lado del rombo, cae en la rendija.
      final a = LogoGeometria.estrellaCentralSinRetraerSvg[0];
      final b = LogoGeometria.estrellaCentralSinRetraerSvg[1];
      final d = (b - a) / (b - a).distance;
      final haciaElRombo = Offset(d.dy, -d.dx);
      final punto = (a + b) / 2 + haciaElRombo * 2 - LogoGeometria.centroSvg;
      expect(LogoGeometria.silueta.contains(punto), isTrue);
      expect(LogoGeometria.rombos[0].contains(punto), isFalse);
      expect(LogoGeometria.estrellaCentral.contains(punto), isFalse);
      expect(LogoGeometria.silueta.contains(const Offset(0, -360)), isFalse);
    });

    test('cada «+» mide 72,8 u de punta a punta y 17,4 u de grosor, arriba a '
        'la derecha', () {
      final (horizontal, vertical) = LogoGeometria.barrasDeCruz();
      expect(horizontal.width, closeTo(72.8, 1e-9));
      expect(horizontal.height, closeTo(17.4, 1e-9));
      expect(vertical.width, closeTo(17.4, 1e-9));
      expect(vertical.height, closeTo(72.8, 1e-9));
      final (_, fina) = LogoGeometria.barrasDeCruz(grosor: 0.87);
      expect(fina.width, closeTo(17.4 * 0.87, 1e-9));
      expect(LogoGeometria.centrosDeCruz, const [
        Offset(308.7, -133.8),
        Offset(402.5, -133.8),
      ]);
    });

    test('los caminos se construyen una sola vez', () {
      expect(identical(LogoGeometria.rombos, LogoGeometria.rombos), isTrue);
      expect(
        identical(LogoGeometria.estrellaCentral, LogoGeometria.estrellaCentral),
        isTrue,
      );
      expect(identical(LogoGeometria.silueta, LogoGeometria.silueta), isTrue);
    });
  });

  group('la escena y el pintor', () {
    const centro = Offset(100, 100);

    test('la escena en reposo trae los ocho rombos quietos y los dos «+» en '
        'su lugar', () {
      final e = EscenaDelLogo.reposo(centro: centro, radio: 90);
      expect(e.rombos, hasLength(8));
      expect(
        e.rombos.every((r) => r.desplazamiento == 0 && r.opacidad == 1),
        isTrue,
      );
      expect(
        e.cruces.map((c) => c.centro).toList(),
        LogoGeometria.centrosDeCruz,
      );
      final sinCruces = EscenaDelLogo.reposo(
        centro: centro,
        radio: 90,
        conCruces: false,
      );
      expect(sinCruces.cruces, isEmpty);
    });

    test('la pose da el centro, el radio y los «+» en dp de la vista', () {
      final pose = EscenaDelLogo.reposo(centro: centro, radio: 90).pose;
      final u = 90 / 354.8;
      expect(pose.centro, centro);
      expect(pose.radio, 90);
      expect(pose.giro, 0);
      expect(pose.cruces[0].centro.dx, closeTo(100 + 308.7 * u, 1e-9));
      expect(pose.cruces[0].centro.dy, closeTo(100 - 133.8 * u, 1e-9));
      expect(pose.cruces[1].escala, 1);
    });

    test('la pose de una escena corrida y de una estrella movida sigue a la '
        'estrella', () {
      final e = EscenaDelLogo.reposo(centro: centro, radio: 90).copyWith(
        corrimiento: const Offset(-36, 0),
        desplazamientoDeEstrella: const Offset(0, -10),
        escalaDeEstrella: 0.5,
      );
      final u = 90 / 354.8;
      expect(e.pose.centro.dx, closeTo(100 - 36 * u, 1e-9));
      expect(e.pose.centro.dy, closeTo(100 - 10 * u, 1e-9));
      expect(e.pose.radio, closeTo(45, 1e-9));
    });

    test('una escena desde una pose vuelve a dar la misma pose', () {
      final original = EscenaDelLogo.reposo(
        centro: centro,
        radio: 90,
      ).copyWith(corrimiento: const Offset(-36, 0), giro: 0.2).pose;
      final vuelta = EscenaDelLogo.desdePose(original).pose;
      expect(vuelta.centro.dx, closeTo(original.centro.dx, 1e-9));
      expect(vuelta.centro.dy, closeTo(original.centro.dy, 1e-9));
      expect(vuelta.radio, closeTo(original.radio, 1e-9));
      expect(vuelta.giro, closeTo(original.giro, 1e-9));
      for (var i = 0; i < 2; i++) {
        expect(
          vuelta.cruces[i].centro.dx,
          closeTo(original.cruces[i].centro.dx, 1e-9),
        );
        expect(
          vuelta.cruces[i].centro.dy,
          closeTo(original.cruces[i].centro.dy, 1e-9),
        );
      }
    });

    testWidgets('el pintor dibuja la estrella en blanco y nada fuera de ella', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(200, 200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final clave = GlobalKey();
      final escena = ValueNotifier(
        EscenaDelLogo.reposo(centro: centro, radio: 90, conCruces: false),
      );
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: clave,
            child: SizedBox(
              width: 200,
              height: 200,
              child: CustomPaint(painter: PintorDelLogo(escena)),
            ),
          ),
        ),
      );
      final alfa = await _alfas(tester, clave);
      expect(alfa(100, 100), 255, reason: 'el centro de la estrella');
      expect(alfa(100, 30), 255, reason: 'dentro del rombo de arriba');
      expect(alfa(100, 5), 0, reason: 'más allá de la punta, a 95 dp');
      expect(alfa(0, 0), 0, reason: 'la esquina');
    });

    test('el pintor no se repinta con la misma escena', () {
      final escena = ValueNotifier(
        EscenaDelLogo.reposo(centro: centro, radio: 90),
      );
      expect(
        PintorDelLogo(escena).shouldRepaint(PintorDelLogo(escena)),
        isFalse,
      );
    });
  });
}

/// El alfa de cada píxel de lo que pintó el `RepaintBoundary` de [clave].
Future<int Function(int x, int y)> _alfas(
  WidgetTester tester,
  GlobalKey clave,
) async {
  final frontera =
      clave.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final imagen = (await tester.runAsync(() => frontera.toImage()))!;
  final datos = (await tester.runAsync(
    () => imagen.toByteData(format: ImageByteFormat.rawRgba),
  ))!;
  final ancho = imagen.width;
  return (x, y) => datos.getUint8((y * ancho + x) * 4 + 3);
}
