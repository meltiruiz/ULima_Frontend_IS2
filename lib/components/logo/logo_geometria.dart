// lib/components/logo/logo_geometria.dart
// La geometría única del logo ULima++ (RF-SPL-2 de la spec del splash). La
// usan la intro, la estrella de la cabecera, el sello de la bienvenida y la
// prueba que genera el PNG del splash nativo. Las medidas van en unidades u
// del SVG `assets/images/Universidad_de_Lima_logo.svg`, y los caminos tienen
// el origen en el centro de la estrella.

import 'dart:ui';

abstract final class LogoGeometria {
  /// Centro de la estrella en el SVG.
  static const Offset centroSvg = Offset(590.2, 394.3);

  /// Radio nominal hasta la punta, sin retraer.
  static const double radioNominal = 354.8;

  /// Lo que se retrae cada polígono, la mitad de la rendija de 7 u.
  static const double retraimiento = 3.5;

  /// Los ocho rombos retraídos, desde el de arriba y en sentido horario,
  /// como en `ensamble.html`.
  static const List<List<Offset>> rombosSvg = <List<Offset>>[
    [
      Offset(590.2, 279.7),
      Offset(679.7, 167.4),
      Offset(590.2, 45.4),
      Offset(500.7, 167.4),
    ],
    [
      Offset(671.3, 313.2),
      Offset(813.9, 297.1),
      Offset(836.9, 147.6),
      Offset(687.4, 170.6),
    ],
    [
      Offset(817.1, 304.8),
      Offset(704.8, 394.3),
      Offset(817.1, 483.7),
      Offset(939.1, 394.3),
    ],
    [
      Offset(671.3, 475.3),
      Offset(687.4, 617.9),
      Offset(836.9, 641.0),
      Offset(813.9, 491.4),
    ],
    [
      Offset(590.2, 508.8),
      Offset(500.7, 621.1),
      Offset(590.2, 743.2),
      Offset(679.7, 621.1),
    ],
    [
      Offset(509.2, 475.3),
      Offset(366.6, 491.4),
      Offset(343.5, 641.0),
      Offset(493.1, 617.9),
    ],
    [
      Offset(475.6, 394.3),
      Offset(363.3, 304.8),
      Offset(241.3, 394.3),
      Offset(363.3, 483.7),
    ],
    [
      Offset(509.2, 313.2),
      Offset(493.1, 170.6),
      Offset(343.5, 147.6),
      Offset(366.6, 297.1),
    ],
  ];

  /// La estrella central retraída, el polígono de 16 vértices que forman los
  /// vértices interiores de los rombos.
  static const List<Offset> estrellaCentralSvg = <Offset>[
    Offset(501.1, 179.2),
    Offset(590.2, 290.9),
    Offset(679.3, 179.2),
    Offset(663.3, 321.2),
    Offset(805.3, 305.2),
    Offset(693.6, 394.3),
    Offset(805.3, 483.3),
    Offset(663.3, 467.3),
    Offset(679.3, 609.3),
    Offset(590.2, 497.6),
    Offset(501.1, 609.3),
    Offset(517.2, 467.3),
    Offset(375.1, 483.3),
    Offset(486.8, 394.3),
    Offset(375.1, 305.2),
    Offset(517.2, 321.2),
  ];

  /// Los rombos del SVG, sin retraer, con el mismo orden de vértices.
  static const List<List<Offset>> rombosSinRetraerSvg = <List<Offset>>[
    [
      Offset(590.2, 285.3),
      Offset(684.1, 167.5),
      Offset(590.2, 39.5),
      Offset(496.3, 167.5),
    ],
    [
      Offset(667.3, 317.2),
      Offset(817.0, 300.3),
      Offset(841.1, 143.4),
      Offset(684.2, 167.5),
    ],
    [
      Offset(817.0, 300.4),
      Offset(699.2, 394.3),
      Offset(817.0, 488.1),
      Offset(945.0, 394.3),
    ],
    [
      Offset(667.3, 471.3),
      Offset(684.2, 621.0),
      Offset(841.1, 645.2),
      Offset(817.0, 488.2),
    ],
    [
      Offset(590.2, 503.2),
      Offset(496.3, 621.0),
      Offset(590.2, 749.1),
      Offset(684.1, 621.0),
    ],
    [
      Offset(513.2, 471.3),
      Offset(363.5, 488.2),
      Offset(339.3, 645.2),
      Offset(496.3, 621.0),
    ],
    [
      Offset(481.2, 394.3),
      Offset(363.4, 300.4),
      Offset(235.4, 394.3),
      Offset(363.4, 488.1),
    ],
    [
      Offset(513.2, 317.2),
      Offset(496.3, 167.5),
      Offset(339.3, 143.4),
      Offset(363.5, 300.3),
    ],
  ];

  /// La estrella central sin retraer, que sale de los mismos vértices del SVG.
  static const List<Offset> estrellaCentralSinRetraerSvg = <Offset>[
    Offset(496.3, 167.5),
    Offset(590.2, 285.3),
    Offset(684.1, 167.5),
    Offset(667.3, 317.2),
    Offset(817.0, 300.4),
    Offset(699.2, 394.3),
    Offset(817.0, 488.1),
    Offset(667.3, 471.3),
    Offset(684.1, 621.0),
    Offset(590.2, 503.2),
    Offset(496.3, 621.0),
    Offset(513.2, 471.3),
    Offset(363.4, 488.1),
    Offset(481.2, 394.3),
    Offset(363.4, 300.4),
    Offset(513.2, 317.2),
  ];

  /// Cada «+» mide 72,8 u de punta a punta y 17,4 u de grosor.
  static const double largoDeCruz = 72.8;
  static const double grosorDeCruz = 17.4;

  /// Centros de los «++» desde el centro de la estrella, arriba a la derecha.
  static const List<Offset> centrosDeCruz = <Offset>[
    Offset(308.7, -133.8),
    Offset(402.5, -133.8),
  ];

  static List<Offset> _relativos(List<Offset> svg) => <Offset>[
    for (final p in svg) p - centroSvg,
  ];

  static Path _poligono(List<Offset> svg) =>
      Path()..addPolygon(_relativos(svg), true);

  /// Los rombos retraídos. Se construyen la primera vez que se leen.
  static final List<Path> rombos = List<Path>.unmodifiable(<Path>[
    for (final r in rombosSvg) _poligono(r),
  ]);

  static final Path estrellaCentral = _poligono(estrellaCentralSvg);

  /// La unión de los polígonos sin retraer, que recorta el destello de
  /// Ensamble (RF-SPL-7).
  static final Path silueta = () {
    final camino = Path();
    for (final r in rombosSinRetraerSvg) {
      camino.addPolygon(_relativos(r), true);
    }
    camino.addPolygon(_relativos(estrellaCentralSinRetraerSvg), true);
    return camino;
  }();

  /// El centroide de cada rombo retraído, en u desde el centro.
  static final List<Offset> centrosDeRombo = List<Offset>.unmodifiable(<Offset>[
    for (final r in rombosSvg)
      _relativos(r).reduce((a, b) => a + b) / r.length.toDouble(),
  ]);

  /// La dirección hacia afuera de cada rombo.
  static final List<Offset> direccionesDeRombo = List<Offset>.unmodifiable(
    <Offset>[for (final c in centrosDeRombo) c / c.distance],
  );

  /// Cuántos dp mide una unidad con un radio de [radioDp].
  static double unidad(double radioDp) => radioDp / radioNominal;

  /// Las dos barras de un «+» centrado en el origen, en u. Con [grosor]
  /// menor que 1, la cruz es más fina, como el «+» tecleado de Código.
  static (Rect, Rect) barrasDeCruz({double grosor = 1}) {
    final g = grosorDeCruz * grosor;
    return (
      Rect.fromCenter(center: Offset.zero, width: largoDeCruz, height: g),
      Rect.fromCenter(center: Offset.zero, width: g, height: largoDeCruz),
    );
  }
}
