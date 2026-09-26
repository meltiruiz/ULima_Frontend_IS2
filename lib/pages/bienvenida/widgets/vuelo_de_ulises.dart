// lib/pages/bienvenida/widgets/vuelo_de_ulises.dart
// Dónde va Ulises en cada instante del recibimiento (RF-BIEN-2). El vuelo de
// 1300 ms con la curva seno sobre la Bézier de puntosDelVuelo, la estela, el
// rebote del aterrizaje con sus seis partículas, la sombra, el asentimiento y
// el salto a su avatar. Funciones puras del instante, en dp de la vista. Los
// detalles que la spec no fija son la decisión 12 del plan.

import 'dart:math' as math;

import 'package:flutter/animation.dart' show Curves;
import 'package:flutter/painting.dart';

import '../../splash/variantes/variante_de_intro.dart'
    show grado, medioSeno, mezcla, tramo;

typedef PuntosDelVuelo = ({Offset inicio, Offset control1, Offset control2});

/// Ulises en un instante, recortado en círculo, con su centro y su lado en
/// dp de la vista.
class PoseDeUlises {
  const PoseDeUlises({
    required this.centro,
    required this.lado,
    this.giro = 0,
    this.escalaX = 1,
    this.escalaY = 1,
    this.opacidad = 1,
  });

  final Offset centro;
  final double lado;

  /// En radianes.
  final double giro;
  final double escalaX;
  final double escalaY;
  final double opacidad;
}

/// Los puntos blancos de la estela miden 7 dp.
const double radioDeLaEstela = 3.5;

/// La curva seno de la maqueta, de 0 a 1.
double curvaSeno(double t) => 0.5 - 0.5 * math.cos(math.pi * t.clamp(0.0, 1.0));

Offset _cubica(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
  final s = 1 - t;
  return p0 * (s * s * s) +
      p1 * (3 * s * s * t) +
      p2 * (3 * s * t * t) +
      p3 * (t * t * t);
}

/// Entra con 62 dp y −26°, se inclina hasta 14° a mitad del vuelo, se
/// comprime cinco veces como un aleteo y llega con 70 dp, en 1300 ms desde
/// que empieza el vuelo.
PoseDeUlises ulisesEnVuelo(
  PuntosDelVuelo puntos,
  Offset aterrizaje,
  double ms,
) {
  final t = tramo(ms, 0, 1300);
  final e = curvaSeno(t);
  final medio = medioSeno(t);
  return PoseDeUlises(
    centro: _cubica(
      puntos.inicio,
      puntos.control1,
      puntos.control2,
      aterrizaje,
      e,
    ),
    lado: mezcla(62, 70, e),
    giro: -26 * grado * (1 - e) * (1 - medio) + 14 * grado * medio,
    escalaY: 1 - 0.1 * math.sin(5 * math.pi * t).abs(),
  );
}

/// El rebote de 480 ms, que lo aplasta contra el suelo y lo estira antes de
/// asentarse.
PoseDeUlises ulisesAlAterrizar(Offset aterrizaje, double ms) {
  final t = tramo(ms, 0, 480);
  final onda = math.sin(3 * math.pi * t) * (1 - t);
  return PoseDeUlises(
    centro: aterrizaje,
    lado: 70,
    escalaX: 1 + 0.15 * onda,
    escalaY: 1 - 0.15 * onda,
  );
}

/// El asentimiento de 320 ms, con −6° y un 6 % más de escala.
PoseDeUlises ulisesAsiente(Offset centro, double ms) {
  final s = medioSeno(tramo(ms, 0, 320));
  return PoseDeUlises(
    centro: centro,
    lado: 70,
    giro: -6 * grado * s,
    escalaX: 1 + 0.06 * s,
    escalaY: 1 + 0.06 * s,
  );
}

/// Se agacha en 190 ms y salta en 720 ms hasta su avatar de 40 dp, en un arco
/// con los controles 144 dp sobre su lugar y 132 dp sobre el avatar, y se
/// posa con el rebote al 60 % del salto, así que llega a los 910 ms.
PoseDeUlises ulisesSalta(Offset desde, Offset avatar, double ms) {
  if (ms < 190) {
    final s = medioSeno(tramo(ms, 0, 190));
    return PoseDeUlises(
      centro: desde,
      lado: 70,
      escalaX: 1 + 0.08 * s,
      escalaY: 1 - 0.12 * s,
    );
  }
  final t = Curves.easeInOutCubic.transform(tramo(ms, 190, 910));
  final rebote = t > 0.6 ? 1 + 0.08 * medioSeno(tramo(t, 0.6, 1)) : 1.0;
  return PoseDeUlises(
    centro: _cubica(
      desde,
      desde - const Offset(0, 144),
      avatar - const Offset(0, 132),
      avatar,
      t,
    ),
    lado: mezcla(70, 40, t) * rebote,
  );
}

/// La estela, en ms desde que empieza el vuelo. Un punto blanco de 7 dp cada
/// 1300 / 30 ms sobre la curva de Ulises, que se apaga en 560 ms, así que
/// nunca pasan de 30.
List<({Offset centro, double opacidad})> estelaDelVuelo(
  PuntosDelVuelo puntos,
  Offset aterrizaje,
  double ms,
) {
  const paso = 1300 / 30;
  return <({Offset centro, double opacidad})>[
    for (var i = 0; i < 30; i++)
      if (ms >= i * paso && ms - i * paso < 560)
        (
          centro: ulisesEnVuelo(puntos, aterrizaje, i * paso).centro,
          opacidad: 1 - (ms - i * paso) / 560,
        ),
  ];
}

/// Las seis partículas del aterrizaje, en ms desde que Ulises toca el suelo.
/// Salen de sus pies en abanico hacia arriba, hasta 30 dp, y se apagan en
/// 480 ms.
List<({Offset centro, double radio, double opacidad})> particulasDelAterrizaje(
  Offset aterrizaje,
  double ms,
) {
  if (ms < 0 || ms >= 480) {
    return const <({Offset centro, double radio, double opacidad})>[];
  }
  final t = ms / 480;
  final pies = aterrizaje + const Offset(0, 35);
  final alcance = 30 * Curves.easeOutCubic.transform(t);
  return <({Offset centro, double radio, double opacidad})>[
    for (var k = 0; k < 6; k++)
      (
        centro: pies + Offset.fromDirection(math.pi + k * math.pi / 5, alcance),
        radio: 3 * (1 - 0.5 * t),
        opacidad: 1 - t,
      ),
  ];
}

/// La sombra de Ulises en el suelo, un óvalo negro al 20 % que crece de 18 a
/// 56 dp al acercarse. [avance] va de 0 al empezar el vuelo a 1 al aterrizar.
({Offset centro, double ancho, double opacidad}) sombraDelVuelo(
  Offset aterrizaje,
  double avance,
) => (
  centro: aterrizaje + const Offset(0, 40),
  ancho: mezcla(18, 56, avance),
  opacidad: 0.2 * avance,
);
