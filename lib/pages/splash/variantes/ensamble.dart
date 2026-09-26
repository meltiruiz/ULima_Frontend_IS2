// lib/pages/splash/variantes/ensamble.dart
// Variante A, «Ensamble» (RF-SPL-7). Arranca desde la estrella completa del
// nativo, los ocho rombos se abren juntos y vuelven a encajar uno a uno en
// sentido horario (S-3). La maqueta es
// docs/images/UI/splash/ensamble-adaptada.html.

import 'dart:math' as math;

import 'package:flutter/animation.dart';

import '../../../components/logo/escena_del_logo.dart';
import '../../../components/logo/logo_geometria.dart';
import '../../../services/splash_variante_service.dart';
import 'variante_de_intro.dart';

class Ensamble extends VarianteDeIntro {
  const Ensamble();

  static const double finDeLaQuietud = 80;
  static const double finDeLaApertura = 260;
  static const double alejamiento = 200; // u
  static const double inicioDeEncaje = 260;
  static const double pasoDeEncaje = 50;
  static const double duracionDeEncaje = 264;
  static const double periodoDeOnda = 1100;
  static const double ondaMaxima = 20; // u
  static const double entradaDeOnda = 300;
  static const List<double> inicioDeCruz = <double>[860, 930];

  @override
  VarianteSplash get tipo => VarianteSplash.ensamble;

  @override
  double get finDeLaEntrada => 1250;

  @override
  double get duracionDeLaSalida => 530;

  @override
  Curve get curvaDeLaSalida => Curves.easeInOutCubic;

  RomboEnEscena _rombo(int k, double ms) {
    if (ms < finDeLaQuietud) return RomboEnEscena.enReposo;
    final inicio = inicioDeEncaje + pasoDeEncaje * k;
    if (ms < inicio) {
      final p = Curves.easeOutCubic.transform(
        tramo(ms, finDeLaQuietud, finDeLaApertura),
      );
      return RomboEnEscena(
        desplazamiento: alejamiento * p,
        giro: -60 * grado * p,
        escala: 1 - 0.4 * p,
        opacidad: 1 - 0.6 * p,
      );
    }
    final t = tramo(ms, inicio, inicio + duracionDeEncaje);
    final g = Curves.easeOutCubic.transform(t);
    return RomboEnEscena(
      desplazamiento: alejamiento * (1 - conRebote(t, 1.25)),
      giro: -60 * grado * (1 - g),
      escala: 0.6 + 0.4 * g,
      opacidad: 0.4 + 0.6 * tramo(ms, inicio, inicio + 50),
    );
  }

  /// La estrella central se contrae 2,2 % con cada encaje. Si dos
  /// compresiones se solapan, manda la mayor (decisión 2 del plan).
  double _compresion(double ms) {
    var mayor = 0.0;
    for (var k = 0; k < 8; k++) {
      final c = inicioDeEncaje + pasoDeEncaje * k + 119;
      if (ms >= c && ms <= c + 190) {
        mayor = math.max(mayor, 0.022 * medioSeno(tramo(ms, c, c + 190)));
      }
    }
    return 1 - mayor;
  }

  List<CruzEnEscena> _cruces(double ms) => <CruzEnEscena>[
    for (var i = 0; i < 2; i++)
      if (ms >= inicioDeCruz[i])
        _cruz(i, tramo(ms, inicioDeCruz[i], inicioDeCruz[i] + 300)),
  ];

  CruzEnEscena _cruz(int i, double t) => CruzEnEscena(
    centro: LogoGeometria.centrosDeCruz[i],
    giro: -90 * grado * (1 - Curves.easeOutCubic.transform(t)),
    escala: conRebote(t, 2.4),
  );

  List<AnilloEnEscena> _anillos(double ms) {
    final anillos = <AnilloEnEscena>[];
    if (ms >= 720 && ms < 1260) {
      final e = Curves.easeOutCubic.transform(tramo(ms, 720, 1260));
      anillos.add(
        AnilloEnEscena(
          centro: Offset.zero,
          radio: mezcla(370, 640, e),
          trazo: mezcla(16, 3, e),
          opacidad: mezcla(0.35, 0, e),
        ),
      );
    }
    for (var i = 0; i < 2; i++) {
      final inicio = inicioDeCruz[i];
      if (ms >= inicio && ms < inicio + 300) {
        final t = tramo(ms, inicio, inicio + 300);
        anillos.add(
          AnilloEnEscena(
            centro: LogoGeometria.centrosDeCruz[i],
            radio: mezcla(48, 120, Curves.easeOutCubic.transform(t)),
            trazo: mezcla(6, 1, t),
            opacidad: 0.5 * (1 - t),
          ),
        );
      }
    }
    return anillos;
  }

  DestelloEnEscena? _destello(double ms) {
    if (ms < 720 || ms > 1080) return null;
    final avance = tramo(ms, 720, 1080);
    return DestelloEnEscena(avance: avance, intensidad: medioSeno(avance));
  }

  /// La amplitud de la onda de espera, de 0 a 1.
  double _amplitud(double ms, double? cargaLista) {
    final fin = finDeLaEntrada;
    if (ms <= fin) return 0;
    if (cargaLista != null && cargaLista <= fin) return 0;
    final entra = tramo(ms, fin, fin + entradaDeOnda);
    if (cargaLista == null || ms <= cargaLista) return entra;
    final alCargar = tramo(cargaLista, fin, fin + entradaDeOnda);
    return alCargar * (1 - tramo(ms, cargaLista, cargaLista + entradaDeOnda));
  }

  /// La onda en sentido horario, con forma de seno a la sexta.
  List<RomboEnEscena> _onda(double ms, double amplitud) {
    if (amplitud <= 0) return EscenaDelLogo.rombosEnReposo;
    final vuelta = (ms - finDeLaEntrada) / periodoDeOnda;
    return <RomboEnEscena>[
      for (var k = 0; k < 8; k++)
        RomboEnEscena(
          desplazamiento:
              ondaMaxima *
              amplitud *
              math.pow(math.sin(math.pi * ((vuelta - k / 8) % 1.0)), 6),
        ),
    ];
  }

  @override
  EscenaDelLogo escena(
    double ms, {
    required Offset centro,
    required double radio,
    double? cargaLista,
  }) {
    if (ms >= finDeLaEntrada) {
      return EscenaDelLogo(
        centro: centro,
        radio: radio,
        rombos: _onda(ms, _amplitud(ms, cargaLista)),
        cruces: EscenaDelLogo.crucesEnReposo(),
      );
    }
    return EscenaDelLogo(
      centro: centro,
      radio: radio,
      rombos: <RomboEnEscena>[for (var k = 0; k < 8; k++) _rombo(k, ms)],
      escalaCentral: _compresion(ms),
      cruces: _cruces(ms),
      anillos: _anillos(ms),
      destello: _destello(ms),
    );
  }

  @override
  double finDelReposo(double? cargaLista) =>
      cargaLista == null || cargaLista <= finDeLaEntrada
      ? finDeLaEntrada
      : cargaLista + entradaDeOnda;

  @override
  EscenaDelLogo alSalir(
    double msInicio,
    double msEnSalida, {
    required Offset centro,
    required double radio,
  }) {
    final amplitud =
        _amplitud(msInicio, null) *
        (1 - tramo(msEnSalida, 0, duracionDeLaSalida / 3));
    return EscenaDelLogo(
      centro: centro,
      radio: radio,
      rombos: _onda(msInicio + msEnSalida, amplitud),
      cruces: EscenaDelLogo.crucesEnReposo(),
    );
  }
}
