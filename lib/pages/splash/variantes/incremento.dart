// lib/pages/splash/variantes/incremento.dart
// Variante B, «Incremento» (RF-SPL-8). La estrella gira 45° con un resorte,
// los rombos laten, sale una onda y los «++» nacen detrás de la estrella
// como `i++`, mientras el conjunto se corre −36 u para quedar centrado. La
// maqueta es docs/images/UI/splash/incremento.html.

import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';

import '../../../components/logo/escena_del_logo.dart';
import '../../../components/logo/logo_geometria.dart';
import '../../../services/splash_variante_service.dart';
import 'variante_de_intro.dart';

class Incremento extends VarianteDeIntro {
  const Incremento();

  static const double corrimientoFinal = -36; // u
  static const double bordeDeNacimiento = 236; // u
  static const double inicioDeTics = 1400;
  static const double periodoDeTic = 1300;

  /// La maqueta termina el tic a los 700 ms de su inicio (S-34).
  static const double finDelTic = 700;

  /// ω0 = 15,7 rad/s y ζ = 0,55.
  static final SpringSimulation _resorteDeEntrada = SpringSimulation(
    const SpringDescription(mass: 1, stiffness: 246.7, damping: 17.3),
    0,
    1,
    0,
  );

  static final SpringSimulation _resorteDeTic = SpringSimulation(
    const SpringDescription(mass: 1, stiffness: 158, damping: 18.1),
    0,
    1,
    0,
  );

  @override
  VarianteSplash get tipo => VarianteSplash.incremento;

  @override
  double get finDeLaEntrada => 1150;

  @override
  double get duracionDeLaSalida => 620;

  /// La curva enfatizada de Material (RF-SPL-11).
  @override
  Curve get curvaDeLaSalida => const Cubic(0.2, 0, 0, 1);

  /// El inicio del tic en curso en [ms], o null. Ningún tic empieza después
  /// de [cargaLista], y el que empezó antes sigue hasta su final.
  double? _inicioDelTic(double ms, double? cargaLista) {
    if (cargaLista != null && cargaLista <= finDeLaEntrada) return null;
    final hasta = cargaLista == null ? ms : math.min(ms, cargaLista);
    if (hasta < inicioDeTics) return null;
    final n = ((hasta - inicioDeTics) / periodoDeTic).floor();
    return inicioDeTics + periodoDeTic * n;
  }

  int _ticsPrevios(double inicio) =>
      ((inicio - inicioDeTics) / periodoDeTic).round();

  double _giro(double ms, double? cargaLista) {
    final entrada = ms >= finDeLaEntrada ? 1.0 : _resorteDeEntrada.x(ms / 1000);
    var giro = 45 * grado * entrada;
    final inicio = _inicioDelTic(ms, cargaLista);
    if (inicio != null) {
      final avance = ms - inicio >= periodoDeTic
          ? 1.0
          : _resorteDeTic.x((ms - inicio) / 1000);
      giro += 45 * grado * (_ticsPrevios(inicio) + avance);
    }
    return giro;
  }

  /// El giro en reposo tras la carga en [cargaLista], que es el destino del
  /// último tic.
  double _giroDeReposo(double cargaLista) => destinoDelGiro(cargaLista);

  /// El pico del latido, al 32 % de su tramo. Se compara en ms y no en
  /// porcentaje, porque el porcentaje en coma flotante deja el pico en la
  /// bajada y el latido no llega a sus 24 u.
  static const double _picoDelLatido = 180 + 0.32 * 380;

  double _latidoDeEntrada(double ms) {
    if (ms < 180 || ms > 560) return 0;
    return ms <= _picoDelLatido
        ? Curves.easeOutCubic.transform(tramo(ms, 180, _picoDelLatido))
        : 1 - Curves.easeInOutCubic.transform(tramo(ms, _picoDelLatido, 560));
  }

  double _asiente(int i, double ms, double? inicio) {
    if (inicio == null) return 1;
    final s = inicio + (i == 0 ? 60 : 170);
    return 1 + 0.14 * medioSeno(tramo(ms, s, s + 320));
  }

  List<CruzEnEscena> _crucesDeEntrada(double ms) {
    final destino0 = LogoGeometria.centrosDeCruz[0];
    final destino1 = LogoGeometria.centrosDeCruz[1];
    return <CruzEnEscena>[
      if (ms >= 480)
        () {
          final r = conRebote(tramo(ms, 480, 920), 1.6);
          return CruzEnEscena(
            centro: Offset(mezcla(190, destino0.dx, r), destino0.dy),
            escala: mezcla(0.72, 1, r),
          );
        }(),
      if (ms >= 700)
        () {
          final r = conRebote(tramo(ms, 700, 1120), 1.5);
          return CruzEnEscena(
            centro: Offset(mezcla(destino0.dx, destino1.dx, r), destino1.dy),
            escala: mezcla(0.8, 1, r),
          );
        }(),
    ];
  }

  List<AnilloEnEscena> _onda(double ms) {
    if (ms < 230 || ms >= 790) return const <AnilloEnEscena>[];
    final e = Curves.easeOutCubic.transform(tramo(ms, 230, 790));
    return <AnilloEnEscena>[
      AnilloEnEscena(
        centro: Offset.zero,
        radio: mezcla(250, 540, e),
        trazo: mezcla(13.5, 1.5, e),
        opacidad: mezcla(0.42, 0, e),
      ),
    ];
  }

  Offset _corrimiento(double ms) => Offset(
    corrimientoFinal * Curves.easeInOutCubic.transform(tramo(ms, 480, 1060)),
    0,
  );

  EscenaDelLogo _reposo(Offset centro, double radio, double giro) =>
      EscenaDelLogo(
        centro: centro,
        radio: radio,
        corrimiento: const Offset(corrimientoFinal, 0),
        giro: giro,
        cruces: EscenaDelLogo.crucesEnReposo(),
      );

  @override
  EscenaDelLogo escena(
    double ms, {
    required Offset centro,
    required double radio,
    double? cargaLista,
  }) {
    if (cargaLista != null &&
        ms >= finDeLaEntrada &&
        ms >= finDelReposo(cargaLista)) {
      return _reposo(centro, radio, _giroDeReposo(cargaLista));
    }
    final enEntrada = ms < finDeLaEntrada;
    final inicio = enEntrada ? null : _inicioDelTic(ms, cargaLista);
    final latidoDeEntrada = enEntrada ? _latidoDeEntrada(ms) : 0.0;
    final latido = enEntrada
        ? 24 * latidoDeEntrada
        : (inicio == null
              ? 0.0
              : 8 * medioSeno(tramo(ms, inicio, inicio + 420)));
    return EscenaDelLogo(
      centro: centro,
      radio: radio,
      corrimiento: _corrimiento(ms),
      giro: _giro(ms, cargaLista),
      escalaCentral: 1 - 0.05 * latidoDeEntrada,
      rombos: latido == 0
          ? EscenaDelLogo.rombosEnReposo
          : List<RomboEnEscena>.filled(
              8,
              RomboEnEscena(desplazamiento: latido),
            ),
      cruces: enEntrada
          ? _crucesDeEntrada(ms)
          : <CruzEnEscena>[
              for (var i = 0; i < 2; i++)
                CruzEnEscena(
                  centro: LogoGeometria.centrosDeCruz[i],
                  escala: _asiente(i, ms, inicio),
                ),
            ],
      anillos: _onda(ms),
      recorteDeCruces: ms < 920 ? bordeDeNacimiento : null,
    );
  }

  @override
  double finDelReposo(double? cargaLista) {
    if (cargaLista == null || cargaLista <= finDeLaEntrada) {
      return finDeLaEntrada;
    }
    final inicio = _inicioDelTic(cargaLista, cargaLista);
    if (inicio == null) return cargaLista;
    return math.max(cargaLista, inicio + finDelTic);
  }

  @override
  double giroAlSalir(double msInicio) => _giro(msInicio, msInicio);

  @override
  double destinoDelGiro(double msInicio) {
    final inicio = _inicioDelTic(msInicio, msInicio);
    final tics = inicio == null ? 0 : _ticsPrevios(inicio) + 1;
    return 45 * grado * (1 + tics);
  }

  @override
  EscenaDelLogo alSalir(
    double msInicio,
    double msEnSalida, {
    required Offset centro,
    required double radio,
  }) {
    final e = escena(
      msInicio + msEnSalida,
      centro: centro,
      radio: radio,
      cargaLista: msInicio,
    );
    final f = 1 - tramo(msEnSalida, 0, 150);
    return EscenaDelLogo(
      centro: centro,
      radio: radio,
      corrimiento: e.corrimiento,
      rombos: <RomboEnEscena>[
        for (final r in e.rombos)
          RomboEnEscena(desplazamiento: r.desplazamiento * f),
      ],
      cruces: <CruzEnEscena>[
        for (final c in e.cruces) c.copyWith(escala: 1 + (c.escala - 1) * f),
      ],
    );
  }
}
