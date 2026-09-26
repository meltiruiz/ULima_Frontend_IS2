// lib/pages/splash/variantes/codigo.dart
// Variante C, «Código» (RF-SPL-9). La estrella sube y se achica, se teclea
// «ULima» en la letra monoespaciada del sistema (S-15), los «++» saltan en
// arco a su lugar junto a la estrella y la estrella vuelve al centro. La
// maqueta es docs/images/UI/splash/codigo.html, hecha con R = 86 dp, así que
// sus medidas van en R.

import 'dart:math' as math;

import 'package:flutter/animation.dart';

import '../../../components/logo/escena_del_logo.dart';
import '../../../components/logo/logo_geometria.dart';
import '../../../services/splash_variante_service.dart';
import 'variante_de_intro.dart';

class Codigo extends VarianteDeIntro {
  const Codigo();

  static const List<double> tecleos = <double>[250, 318, 386, 454, 522];
  static const List<double> tecleoDeCruces = <double>[610, 680];
  static const List<double> inicioDeVuelo = <double>[780, 830];
  static const double duracionDeVuelo = 380;
  static const Color amarillo = Color(0xFFFFE7A3);

  /// El «+» tecleado mide 0,83 de la cruz del logo y tiene el 87 % de su
  /// grosor, como en la maqueta (decisión 4 del plan).
  static const double escalaTecleada = 0.83;
  static const double grosorTecleado = 0.87;

  /// Cuándo empieza el rebote de 150 ms de cada «+». El primero rebota al
  /// llegar, a los 1160 ms. El segundo empieza 30 ms antes del fin de su
  /// vuelo, cuando ya cubre el 99,5 % de su curva y está a menos de 1 dp de
  /// su lugar, así que termina a los 1330 ms, con la entrada (decisión 11 del
  /// plan).
  static const List<double> inicioDelRebote = <double>[1160, 1180];

  static const double _r = LogoGeometria.radioNominal;

  /// A la derecha de los «++», donde parpadea el cursor de espera.
  static const Offset _cursorDeEspera = Offset(402.5 + 36.4 + 24, -133.8);

  @override
  VarianteSplash get tipo => VarianteSplash.codigo;

  @override
  double get finDeLaEntrada => 1330;

  @override
  double get duracionDeLaSalida => 420;

  @override
  Curve get curvaDeLaSalida => Curves.easeInOutCubic;

  double _subida(double ms) => Curves.easeOutCubic.transform(tramo(ms, 0, 320));

  double _vuelta(double ms) =>
      Curves.easeInOutCubic.transform(tramo(ms, 820, 1210));

  Offset _desplazamiento(double ms) =>
      Offset(0, -0.66 * _r * _subida(ms) * (1 - _vuelta(ms)));

  double _escala(double ms) {
    final base = mezcla(mezcla(1, 0.82, _subida(ms)), 1, _vuelta(ms));
    return base * (1 + 0.035 * medioSeno(tramo(ms, 1210, 1330)));
  }

  int _letras(double ms) => tecleos.where((t) => ms >= t).length;

  int _celdaDelCursor(double ms) =>
      ms >= 780 ? 5 : _letras(ms) + tecleoDeCruces.where((t) => ms >= t).length;

  double _caida(double ms) =>
      0.12 * _r * Curves.easeInOutCubic.transform(tramo(ms, 790, 960));

  CursorEnEscena? _cursorDeTecleo(double ms) {
    if (ms < 160 || ms >= 960) return null;
    final opacidad = ms < 790 ? tramo(ms, 160, 240) : 1 - tramo(ms, 790, 960);
    return CursorEnEscena(
      centro: Offset(
        TextoDeCodigo.bordeDeCelda(_celdaDelCursor(ms)),
        TextoDeCodigo.centroDeCelda(0).dy + _caida(ms),
      ),
      alto: 1.05 * TextoDeCodigo.tamanoEnU,
      opacidad: opacidad,
    );
  }

  TextoDeCodigo? _texto(double ms) => ms < 250 || ms >= 960
      ? null
      : TextoDeCodigo(
          visibles: _letras(ms),
          opacidad: 1 - tramo(ms, 790, 960),
          dy: _caida(ms),
        );

  double _rebote(int i, double ms) {
    final a = inicioDelRebote[i];
    return 1 + 0.12 * medioSeno(tramo(ms, a, a + 150));
  }

  CruzEnEscena? _cruz(int i, double ms) {
    final aparece = tecleoDeCruces[i];
    if (ms < aparece) return null;
    final origen = TextoDeCodigo.centroDeCelda(5 + i);
    final destino = LogoGeometria.centrosDeCruz[i];
    final despega = inicioDeVuelo[i];
    if (ms < despega) {
      final t = tramo(ms, aparece, aparece + 110);
      return CruzEnEscena(
        centro: origen,
        escala: escalaTecleada * mezcla(0.55, 1, conRebote(t, 1.70158)),
        grosor: grosorTecleado,
        color: amarillo,
      );
    }
    final t = Curves.easeInOutCubic.transform(
      tramo(ms, despega, despega + duracionDeVuelo),
    );
    final control = Offset(
      destino.dx + 0.38 * _r,
      math.min(origen.dy, destino.dy) - 0.91 * _r,
    );
    return CruzEnEscena(
      centro: bezierCuadratica(origen, control, destino, t),
      escala: mezcla(escalaTecleada, 1, t) * _rebote(i, ms),
      giro: 90 * grado * t,
      grosor: mezcla(grosorTecleado, 1, t),
      color: Color.lerp(amarillo, const Color(0xFFFFFFFF), t)!,
    );
  }

  List<AnilloEnEscena> _anillos(double ms) {
    if (ms < 1190 || ms >= 1410) return const <AnilloEnEscena>[];
    final e = Curves.easeOutCubic.transform(tramo(ms, 1190, 1410));
    return <AnilloEnEscena>[
      AnilloEnEscena(
        centro: Offset.zero,
        radio: mezcla(1.02 * _r, 1.5 * _r, e),
        trazo: mezcla(10, 2, e),
        opacidad: mezcla(0.38, 0, e),
      ),
    ];
  }

  double _opacidadDeEspera(double ms) {
    final fin = finDeLaEntrada;
    if (ms < fin) return 0;
    if (ms < fin + 200) return tramo(ms, fin, fin + 200);
    return 0.5 + 0.5 * math.cos(2 * math.pi * (ms - fin - 200) / 1060);
  }

  CursorEnEscena? _cursorEnEspera(double ms, double? cargaLista) {
    if (ms < finDeLaEntrada) return null;
    if (cargaLista != null && cargaLista <= finDeLaEntrada) return null;
    var opacidad = _opacidadDeEspera(ms);
    if (cargaLista != null && ms > cargaLista) {
      opacidad =
          _opacidadDeEspera(cargaLista) *
          (1 - tramo(ms, cargaLista, cargaLista + 120));
    }
    if (opacidad <= 1e-9) return null;
    return CursorEnEscena(
      centro: _cursorDeEspera,
      alto: 1.2 * LogoGeometria.largoDeCruz,
      opacidad: opacidad,
    );
  }

  List<CruzEnEscena> _crucesEnReposo(double ms) => <CruzEnEscena>[
    for (var i = 0; i < 2; i++)
      CruzEnEscena(
        centro: LogoGeometria.centrosDeCruz[i],
        escala: _rebote(i, ms),
      ),
  ];

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
        cruces: _crucesEnReposo(ms),
        anillos: _anillos(ms),
        cursor: _cursorEnEspera(ms, cargaLista),
      );
    }
    return EscenaDelLogo(
      centro: centro,
      radio: radio,
      desplazamientoDeEstrella: _desplazamiento(ms),
      escalaDeEstrella: _escala(ms),
      cruces: <CruzEnEscena>[for (var i = 0; i < 2; i++) ?_cruz(i, ms)],
      anillos: _anillos(ms),
      texto: _texto(ms),
      cursor: _cursorDeTecleo(ms),
    );
  }

  /// El logo queda quieto con la entrada, y desde el bucle cuando el cursor
  /// se apaga en 120 ms (RF-SPL-21 y S-34).
  @override
  double finDelReposo(double? cargaLista) {
    if (cargaLista == null || cargaLista <= finDeLaEntrada) {
      return finDeLaEntrada;
    }
    return cargaLista + 120;
  }

  @override
  EscenaDelLogo alSalir(
    double msInicio,
    double msEnSalida, {
    required Offset centro,
    required double radio,
  }) {
    final ms = msInicio + msEnSalida;
    final cursor = _cursorEnEspera(msInicio, null);
    final f = 1 - tramo(msEnSalida, 0, 120);
    return EscenaDelLogo(
      centro: centro,
      radio: radio,
      cruces: _crucesEnReposo(ms),
      // El anillo sigue en el centro de la pantalla mientras la estrella
      // vuela, y se apaga a los 1410 ms (RF-SPL-9).
      anillos: _anillos(ms),
      cursor: cursor == null || f <= 0
          ? null
          : CursorEnEscena(
              centro: cursor.centro,
              alto: cursor.alto,
              opacidad: cursor.opacidad * f,
            ),
    );
  }
}
