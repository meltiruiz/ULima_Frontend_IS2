// lib/components/logo/escena_del_logo.dart
// Lo que se ve del logo en un instante (RF-SPL-2). Las variantes de la intro
// devuelven una escena por milisegundo, el sello y la cabecera pintan una
// escena quieta y la bienvenida recibe la pose de la última (RF-SPL-21).
//
// La escena tiene un marco, que es `centro` y `radio` en dp de la vista, y
// todo lo demás va en unidades u de ese marco. `corrimiento` mueve el
// conjunto entero, como el −36 u de Incremento, y la estrella tiene además
// su propio desplazamiento, escala y giro, como en la subida de Código.

import 'dart:ui';

import 'logo_geometria.dart';

const Color _blanco = Color(0xFFFFFFFF);

/// Un rombo. El desplazamiento va hacia afuera del centro, en u, y el giro
/// es alrededor del centro de la estrella. La escala es alrededor del
/// centroide del rombo.
class RomboEnEscena {
  const RomboEnEscena({
    this.desplazamiento = 0,
    this.giro = 0,
    this.escala = 1,
    this.opacidad = 1,
  });

  static const RomboEnEscena enReposo = RomboEnEscena();

  final double desplazamiento;
  final double giro;
  final double escala;
  final double opacidad;
}

/// Un «+», con el centro en u del marco, sin el giro de la estrella.
class CruzEnEscena {
  const CruzEnEscena({
    required this.centro,
    this.escala = 1,
    this.giro = 0,
    this.opacidad = 1,
    this.grosor = 1,
    this.color = _blanco,
  });

  final Offset centro;
  final double escala;
  final double giro;
  final double opacidad;

  /// El grosor relativo al de la cruz del logo.
  final double grosor;
  final Color color;

  CruzEnEscena copyWith({
    Offset? centro,
    double? escala,
    double? giro,
    double? opacidad,
    double? grosor,
    Color? color,
  }) => CruzEnEscena(
    centro: centro ?? this.centro,
    escala: escala ?? this.escala,
    giro: giro ?? this.giro,
    opacidad: opacidad ?? this.opacidad,
    grosor: grosor ?? this.grosor,
    color: color ?? this.color,
  );
}

/// Un anillo blanco, con el centro, el radio y el trazo en u.
class AnilloEnEscena {
  const AnilloEnEscena({
    required this.centro,
    required this.radio,
    required this.trazo,
    required this.opacidad,
  });

  final Offset centro;
  final double radio;
  final double trazo;
  final double opacidad;
}

/// El destello de Ensamble. [avance] va de 0 a 1 a lo largo de la diagonal.
class DestelloEnEscena {
  const DestelloEnEscena({required this.avance, required this.intensidad});

  final double avance;
  final double intensidad;
}

/// El renglón «ULima++» de Código, en celdas de 0,6 em (decisión 4 del
/// plan). Solo pinta las letras, porque los «+» son cruces de la escena.
class TextoDeCodigo {
  const TextoDeCodigo({
    required this.visibles,
    required this.opacidad,
    this.dy = 0,
  });

  static const String palabra = 'ULima';

  /// El tamaño de la letra, en R.
  static const double tamano = 0.34;

  /// La línea base, en R bajo el centro.
  static const double lineaBase = 0.81;

  /// El ancho de una celda, en em.
  static const double celda = 0.6;

  /// Celdas del renglón «ULima++».
  static const int celdas = 7;

  /// Cuántas letras de «ULima» se ven.
  final int visibles;
  final double opacidad;

  /// Cuánto baja el renglón, en u.
  final double dy;

  static double get _em => tamano * LogoGeometria.radioNominal;

  /// El borde izquierdo de la celda [i], en u desde el centro.
  static double bordeDeCelda(int i) =>
      -celdas * celda * _em / 2 + i * celda * _em;

  /// El centro del glifo de la celda [i], en u. El «+» se centra 0,34 em
  /// sobre la línea base, como en `codigo.html`.
  static Offset centroDeCelda(int i) => Offset(
    bordeDeCelda(i) + celda * _em / 2,
    lineaBase * LogoGeometria.radioNominal - 0.34 * _em,
  );

  /// El tamaño de la letra en u.
  static double get tamanoEnU => _em;

  /// La línea base en u.
  static double get lineaBaseEnU => lineaBase * LogoGeometria.radioNominal;
}

/// Un cursor vertical, con el centro y el alto en u.
class CursorEnEscena {
  const CursorEnEscena({
    required this.centro,
    required this.alto,
    required this.opacidad,
  });

  final Offset centro;
  final double alto;
  final double opacidad;
}

/// Un «+» de la pose, en dp de la vista.
class PoseDeCruz {
  const PoseDeCruz({required this.centro, required this.escala});

  final Offset centro;
  final double escala;
}

/// Dónde queda el logo al terminar la intro, en dp de la vista. La intro la
/// pasa a la bienvenida como argumento de ruta (RF-SPL-21 y decisión S-33).
class PoseDelLogo {
  const PoseDelLogo({
    required this.centro,
    required this.radio,
    required this.giro,
    required this.cruces,
  });

  /// El centro de la estrella.
  final Offset centro;

  /// El radio de la estrella hasta la punta sin retraer.
  final double radio;
  final double giro;
  final List<PoseDeCruz> cruces;
}

class EscenaDelLogo {
  const EscenaDelLogo({
    required this.centro,
    required this.radio,
    this.corrimiento = Offset.zero,
    this.desplazamientoDeEstrella = Offset.zero,
    this.escalaDeEstrella = 1,
    this.giro = 0,
    this.escalaCentral = 1,
    this.opacidad = 1,
    this.rombos = rombosEnReposo,
    this.cruces = const <CruzEnEscena>[],
    this.anillos = const <AnilloEnEscena>[],
    this.destello,
    this.texto,
    this.cursor,
    this.recorteDeCruces,
  });

  /// La estrella completa con sus «++», quieta.
  factory EscenaDelLogo.reposo({
    required Offset centro,
    required double radio,
    bool conCruces = true,
  }) => EscenaDelLogo(
    centro: centro,
    radio: radio,
    cruces: conCruces ? crucesEnReposo() : const <CruzEnEscena>[],
  );

  /// La escena quieta de una [pose], con el marco en la estrella.
  factory EscenaDelLogo.desdePose(PoseDelLogo pose) {
    final u = LogoGeometria.unidad(pose.radio);
    return EscenaDelLogo(
      centro: pose.centro,
      radio: pose.radio,
      giro: pose.giro,
      cruces: <CruzEnEscena>[
        for (final c in pose.cruces)
          CruzEnEscena(centro: (c.centro - pose.centro) / u, escala: c.escala),
      ],
    );
  }

  static const List<RomboEnEscena> rombosEnReposo = <RomboEnEscena>[
    RomboEnEscena.enReposo,
    RomboEnEscena.enReposo,
    RomboEnEscena.enReposo,
    RomboEnEscena.enReposo,
    RomboEnEscena.enReposo,
    RomboEnEscena.enReposo,
    RomboEnEscena.enReposo,
    RomboEnEscena.enReposo,
  ];

  static List<CruzEnEscena> crucesEnReposo() => <CruzEnEscena>[
    for (final c in LogoGeometria.centrosDeCruz) CruzEnEscena(centro: c),
  ];

  final Offset centro;
  final double radio;
  final Offset corrimiento;
  final Offset desplazamientoDeEstrella;
  final double escalaDeEstrella;

  /// El giro de la estrella y sus rombos, en radianes.
  final double giro;

  /// La escala de la estrella central sola, para la compresión y el pulso.
  final double escalaCentral;
  final double opacidad;
  final List<RomboEnEscena> rombos;
  final List<CruzEnEscena> cruces;
  final List<AnilloEnEscena> anillos;
  final DestelloEnEscena? destello;
  final TextoDeCodigo? texto;
  final CursorEnEscena? cursor;

  /// Si no es null, los «+» solo se ven a la derecha de esta x, en u del
  /// marco, como en Incremento, donde nacen detrás del rombo derecho.
  final double? recorteDeCruces;

  /// Cuántos dp mide una u del marco.
  double get unidad => LogoGeometria.unidad(radio);

  /// Un punto del marco, en u, llevado a dp de la vista.
  Offset aVista(Offset enU) => centro + (corrimiento + enU) * unidad;

  Offset get centroDeLaEstrella => aVista(desplazamientoDeEstrella);

  double get radioDeLaEstrella => radio * escalaDeEstrella;

  PoseDelLogo get pose => PoseDelLogo(
    centro: centroDeLaEstrella,
    radio: radioDeLaEstrella,
    giro: giro,
    cruces: <PoseDeCruz>[
      for (final c in cruces)
        PoseDeCruz(centro: aVista(c.centro), escala: c.escala),
    ],
  );

  EscenaDelLogo copyWith({
    Offset? centro,
    double? radio,
    Offset? corrimiento,
    Offset? desplazamientoDeEstrella,
    double? escalaDeEstrella,
    double? giro,
    double? escalaCentral,
    double? opacidad,
    List<RomboEnEscena>? rombos,
    List<CruzEnEscena>? cruces,
    List<AnilloEnEscena>? anillos,
    DestelloEnEscena? destello,
    TextoDeCodigo? texto,
    CursorEnEscena? cursor,
    double? recorteDeCruces,
  }) => EscenaDelLogo(
    centro: centro ?? this.centro,
    radio: radio ?? this.radio,
    corrimiento: corrimiento ?? this.corrimiento,
    desplazamientoDeEstrella:
        desplazamientoDeEstrella ?? this.desplazamientoDeEstrella,
    escalaDeEstrella: escalaDeEstrella ?? this.escalaDeEstrella,
    giro: giro ?? this.giro,
    escalaCentral: escalaCentral ?? this.escalaCentral,
    opacidad: opacidad ?? this.opacidad,
    rombos: rombos ?? this.rombos,
    cruces: cruces ?? this.cruces,
    anillos: anillos ?? this.anillos,
    destello: destello ?? this.destello,
    texto: texto ?? this.texto,
    cursor: cursor ?? this.cursor,
    recorteDeCruces: recorteDeCruces ?? this.recorteDeCruces,
  );
}
