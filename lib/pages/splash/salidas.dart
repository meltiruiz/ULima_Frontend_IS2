// lib/pages/splash/salidas.dart
// Las salidas de la intro hacia /home (RF-SPL-11 y RF-SPL-13). El panel
// naranja se recoge hasta la cabecera y toma su color, la estrella vuela a
// la estrella de la cabecera y los «++» terminan sobre los del texto
// «ULIMA++». Cada salida es una función pura del instante y de la cabecera
// medida, y un pintor la dibuja. Las curvas de vuelo son las de la decisión
// 3 del plan.

import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import '../../components/logo/escena_del_logo.dart';
import '../../components/logo/logo_geometria.dart';
import '../../components/logo/pintor_del_logo.dart';
import '../../services/splash_variante_service.dart';
import 'puntos_de_aterrizaje.dart';
import 'variantes/variante_de_intro.dart';

/// El naranja del splash nativo y del primer cuadro, en los dos temas (S-2).
const Color naranjaDelSplash = Color(0xFFE77330);

class DestinoDeLaSalida {
  DestinoDeLaSalida._({
    required this.pantalla,
    required this.cabecera,
    required this.estrella,
    required this.texto,
    required this.anchosDeUlima,
    required this.cruces,
    required this.tamanoDeCruz,
    required this.color,
    required this.colorDelBorde,
    required this.pintorDeUlima,
    required this.pintorDeLosMas,
    required this.anchoDeUlima,
  });

  /// Mide «ULIMA» y los «++» con el mismo estilo y la misma escala de texto de
  /// la cabecera, así que la réplica cae sobre el texto real.
  factory DestinoDeLaSalida.desdeMedida(
    MedidaDeCabecera medida,
    Size pantalla,
  ) {
    TextPainter pintor(String texto) => TextPainter(
      text: TextSpan(text: texto, style: medida.estilo),
      textDirection: TextDirection.ltr,
      textScaler: medida.escalaDeTexto,
    )..layout();
    final ulima = pintor('ULIMA');
    final todo = pintor('ULIMA++');
    final mas = pintor('++');
    final anchos = <double>[
      for (var k = 0; k <= 5; k++)
        ulima.getOffsetForCaret(TextPosition(offset: k), Rect.zero).dx,
    ];
    final em = medida.escalaDeTexto.scale(medida.estilo.fontSize ?? 20);
    final base = todo.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    final anchoDeMas = (todo.width - ulima.width) / 2;
    todo.dispose();
    final y = medida.texto.top + base - 0.34 * em;
    return DestinoDeLaSalida._(
      pantalla: pantalla,
      cabecera: medida.cabecera,
      estrella: medida.estrella,
      texto: medida.texto,
      anchosDeUlima: List<double>.unmodifiable(anchos),
      cruces: List<Offset>.unmodifiable(<Offset>[
        for (var i = 0; i < 2; i++)
          Offset(medida.texto.left + ulima.width + anchoDeMas * (i + 0.5), y),
      ]),
      tamanoDeCruz: 0.5 * em,
      color: medida.color,
      colorDelBorde: medida.colorDelBorde,
      pintorDeUlima: ulima,
      pintorDeLosMas: mas,
      anchoDeUlima: ulima.width,
    );
  }

  final Size pantalla;
  final Rect cabecera;
  final Rect estrella;
  final Rect texto;
  final List<double> anchosDeUlima;
  final List<Offset> cruces;
  final double tamanoDeCruz;
  final Color color;
  final Color colorDelBorde;
  final TextPainter pintorDeUlima;
  final TextPainter pintorDeLosMas;

  /// La capa lo desecha al retirarse o al reemplazarlo.
  void desechar() {
    pintorDeUlima.dispose();
    pintorDeLosMas.dispose();
  }

  final double anchoDeUlima;
}

/// Un «+» en vuelo, en dp de la vista.
class CruzDeSalida {
  const CruzDeSalida({
    required this.centro,
    required this.largo,
    required this.sesgo,
  });

  final Offset centro;
  final double largo;

  /// La inclinación que iguala la cursiva de «ULIMA++», en radianes. Es un
  /// sesgo horizontal, como el skewX de las maquetas, y no un giro, así que
  /// con −12° la punta de arriba de la barra vertical cae hacia la derecha y
  /// la barra horizontal sigue horizontal.
  final double sesgo;
}

class EscenaDeSalida {
  const EscenaDeSalida({
    required this.panel,
    required this.colorDelPanel,
    required this.combado,
    required this.radioInferior,
    required this.opacidadDelConjunto,
    required this.estrella,
    required this.restos,
    required this.cruces,
    required this.opacidadDeLasCruces,
    required this.opacidadDeLosMas,
    required this.reveladoDeUlima,
    required this.opacidadDeUlima,
    required this.letrasDeUlima,
    required this.paginaDy,
    required this.paginaOpacidad,
  });

  final Rect panel;
  final Color colorDelPanel;

  /// A. Cuánto baja el centro del borde inferior del panel, en dp.
  final double combado;

  /// B. El radio de las esquinas inferiores, en dp.
  final double radioInferior;

  /// El panel y todo lo que se dibuja encima, que se funden sobre la
  /// cabecera en los últimos 100 ms.
  final double opacidadDelConjunto;

  /// La estrella en vuelo, con lo que queda del bucle en sus rombos.
  final EscenaDelLogo estrella;

  /// Lo que queda de la intro en su marco, como el anillo y el cursor de
  /// Código.
  final EscenaDelLogo restos;
  final List<CruzDeSalida> cruces;
  final double opacidadDeLasCruces;

  /// Los «++» del texto de la réplica.
  final double opacidadDeLosMas;

  /// A. De 0 a 1, de izquierda a derecha.
  final double reveladoDeUlima;

  /// B. La opacidad de «ULIMA».
  final double opacidadDeUlima;

  /// C. Las letras tecleadas de «ULIMA».
  final int letrasDeUlima;
  final double paginaDy;
  final double paginaOpacidad;
}

Offset _bezierCubica(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
  final s = 1 - t;
  return p0 * (s * s * s) +
      p1 * (3 * s * s * t) +
      p2 * (3 * s * t * t) +
      p3 * (t * t * t);
}

/// El centro de la estrella en vuelo con el avance [e], ya con la curva.
Offset _vuelo(
  VarianteSplash tipo,
  Offset desde,
  Offset hasta,
  Size pantalla,
  double e,
) => switch (tipo) {
  VarianteSplash.ensamble => bezierCuadratica(
    desde,
    Offset(desde.dx, hasta.dy + 0.25 * (desde.dy - hasta.dy)),
    hasta,
    e,
  ),
  VarianteSplash.incremento => _bezierCubica(
    desde,
    Offset(desde.dx, desde.dy - 0.2 * pantalla.height),
    Offset(hasta.dx, hasta.dy + 120),
    hasta,
    e,
  ),
  VarianteSplash.codigo => _bezierCubica(
    desde,
    Offset(desde.dx + 40, desde.dy - 0.45 * (hasta - desde).distance),
    Offset(hasta.dx - 30, hasta.dy + 40),
    hasta,
    e,
  ),
};

EscenaDeSalida salidaHaciaHome({
  required VarianteDeIntro variante,
  required double msInicio,
  required double msEnSalida,
  required Offset centroDelMarco,
  required double radioDelMarco,
  required DestinoDeLaSalida destino,
}) {
  final duracion = variante.duracionDeLaSalida;
  final curva = variante.curvaDeLaSalida;
  final t = (msEnSalida / duracion).clamp(0.0, 1.0).toDouble();
  final e = curva.transform(t);
  final d = destino;
  final tipo = variante.tipo;
  final pose = variante
      .escena(
        msInicio,
        centro: centroDelMarco,
        radio: radioDelMarco,
        cargaLista: msInicio,
      )
      .pose;
  final restos = variante.alSalir(
    msInicio,
    msEnSalida,
    centro: centroDelMarco,
    radio: radioDelMarco,
  );

  // La estrella.
  final desde = pose.centro;
  final hasta = d.estrella.center;
  final radioFinal = d.estrella.width / 2;
  double radioEn(double avance) => mezcla(pose.radio, radioFinal, avance);
  Offset centroEn(double avance) =>
      _vuelo(tipo, desde, hasta, d.pantalla, avance);
  final centro = centroEn(e);
  final radio = radioEn(e);
  final giro = tipo == VarianteSplash.incremento
      ? mezcla(
          variante.giroAlSalir(msInicio),
          variante.destinoDelGiro(msInicio) + 45 * grado,
          e,
        )
      : pose.giro;

  // Los «++». Pegados a la estrella, su distancia a ella escala con su
  // radio.
  final unidadInicial = LogoGeometria.unidad(pose.radio);
  final cruces = <CruzDeSalida>[];
  for (var i = 0; i < 2; i++) {
    final origen = pose.cruces[i].centro;
    final largoInicial =
        LogoGeometria.largoDeCruz * unidadInicial * pose.cruces[i].escala;
    final glifo = d.cruces[i];
    Offset pegado(double avance) =>
        centroEn(avance) + (origen - desde) * (radioEn(avance) / pose.radio);
    double largoPegado(double avance) =>
        largoInicial * radioEn(avance) / pose.radio;
    switch (tipo) {
      case VarianteSplash.ensamble:
        // Cada «+» vuela por su cuenta, el segundo un 4 % después.
        final ei = curva.transform(tramo(t, 0.04 * i, 1));
        cruces.add(
          CruzDeSalida(
            centro: bezierCuadratica(
              origen,
              Offset(origen.dx, glifo.dy + 0.25 * (origen.dy - glifo.dy)),
              glifo,
              ei,
            ),
            largo: mezcla(largoInicial, d.tamanoDeCruz, ei),
            sesgo: -12 * grado * ei,
          ),
        );
      case VarianteSplash.incremento:
        // Pegados hasta los 150 ms y sueltos hacia los glifos en 450 ms. La
        // fila de B no nombra inclinación, pero su glifo es la misma cursiva
        // que en A, así que se sesgan igual para el fundido cruzado.
        final alSoltar = curva.transform(math.min(msEnSalida, 150) / duracion);
        final v = Curves.easeInOutCubic.transform(tramo(msEnSalida, 150, 600));
        cruces.add(
          CruzDeSalida(
            centro: msEnSalida <= 150
                ? pegado(e)
                : Offset.lerp(pegado(alSoltar), glifo, v)!,
            largo: msEnSalida <= 150
                ? largoPegado(e)
                : mezcla(largoPegado(alSoltar), d.tamanoDeCruz, v),
            sesgo: -12 * grado * v,
          ),
        );
      case VarianteSplash.codigo:
        // Sueltan la estrella al 45 % y aterrizan al final de la palabra.
        final alSoltar = curva.transform(math.min(t, 0.45));
        final v = Curves.easeInOutCubic.transform(tramo(t, 0.45, 1));
        cruces.add(
          CruzDeSalida(
            centro: t <= 0.45
                ? pegado(e)
                : Offset.lerp(pegado(alSoltar), glifo, v)!,
            largo: t <= 0.45
                ? largoPegado(e)
                : mezcla(largoPegado(alSoltar), d.tamanoDeCruz, v),
            sesgo: -10 * grado * v,
          ),
        );
    }
  }

  final (inicioDePagina, finDePagina, subida) = switch (tipo) {
    VarianteSplash.ensamble => (0.30, 0.70, 20.0),
    VarianteSplash.incremento => (0.30, 0.70, 32.0),
    VarianteSplash.codigo => (0.35, 0.75, 20.0),
  };
  final pagina = tramo(t, inicioDePagina, finDePagina);
  final letras = t <= 0.55 ? 0 : math.min(5, 1 + ((t - 0.55) / 0.07).floor());

  return EscenaDeSalida(
    panel: Rect.fromLTRB(
      0,
      0,
      d.pantalla.width,
      mezcla(d.pantalla.height, d.cabecera.bottom, e),
    ),
    colorDelPanel: Color.lerp(naranjaDelSplash, d.color, e)!,
    combado: tipo == VarianteSplash.ensamble ? 130 * medioSeno(t) : 0,
    radioInferior: tipo == VarianteSplash.incremento ? 75 * medioSeno(t) : 0,
    opacidadDelConjunto: 1 - tramo(msEnSalida, duracion - 100, duracion),
    estrella: EscenaDelLogo(
      centro: centro,
      radio: radio,
      giro: giro,
      rombos: restos.rombos,
    ),
    restos: restos,
    cruces: cruces,
    opacidadDeLasCruces: 1 - tramo(t, 0.75, 1),
    opacidadDeLosMas: tramo(t, 0.75, 1),
    reveladoDeUlima: tipo == VarianteSplash.ensamble ? tramo(t, 0.68, 1) : 1,
    opacidadDeUlima: tipo == VarianteSplash.incremento
        ? tramo(t, 0.62, 0.95)
        : 1,
    letrasDeUlima: tipo == VarianteSplash.codigo ? letras : 5,
    paginaDy: subida * (1 - pagina),
    paginaOpacidad: pagina,
  );
}

Paint _conOpacidad(double opacidad) =>
    Paint()..color = Color.fromRGBO(0, 0, 0, opacidad.clamp(0.0, 1.0));

/// Pinta la salida sobre la página que ya está debajo.
void pintarSalida(
  Canvas canvas,
  EscenaDeSalida s,
  DestinoDeLaSalida d, {
  Color color = const Color(0xFFFFFFFF),
}) {
  if (s.opacidadDelConjunto <= 0) return;
  canvas.saveLayer(null, _conOpacidad(s.opacidadDelConjunto));

  // El panel, abombado en A, con las esquinas redondeadas en B y recto en C.
  final p = s.panel;
  final camino = Path();
  if (s.combado > 0) {
    camino
      ..moveTo(p.left, p.top)
      ..lineTo(p.right, p.top)
      ..lineTo(p.right, p.bottom)
      ..quadraticBezierTo(
        p.center.dx,
        p.bottom + 2 * s.combado,
        p.left,
        p.bottom,
      )
      ..close();
  } else {
    camino.addRRect(
      RRect.fromRectAndCorners(
        p,
        bottomLeft: Radius.circular(s.radioInferior),
        bottomRight: Radius.circular(s.radioInferior),
      ),
    );
  }
  canvas.drawPath(camino, Paint()..color = s.colorDelPanel);

  // Lo que queda de la intro en su marco, sin la estrella, que vuela.
  final marco = s.restos;
  final u = marco.unidad;
  for (final a in marco.anillos) {
    if (a.opacidad <= 0) continue;
    canvas.drawCircle(
      marco.aVista(a.centro),
      a.radio * u,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = a.trazo * u
        ..color = color.withValues(alpha: a.opacidad),
    );
  }
  final cursor = marco.cursor;
  if (cursor != null && cursor.opacidad > 0) {
    canvas.drawRect(
      Rect.fromCenter(
        center: marco.aVista(cursor.centro),
        width: 0.08 * TextoDeCodigo.tamanoEnU * u,
        height: cursor.alto * u,
      ),
      Paint()..color = color.withValues(alpha: cursor.opacidad),
    );
  }

  // La réplica de «ULIMA», con el estilo único de la cabecera, y sus «++».
  final origen = d.texto.topLeft;
  final ancho = switch (s.letrasDeUlima) {
    5 => d.anchoDeUlima * s.reveladoDeUlima,
    final n => d.anchosDeUlima[n],
  };
  if (ancho > 0 && s.opacidadDeUlima > 0) {
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(
        origen.dx - 4,
        origen.dy - 8,
        ancho + 4,
        d.texto.height + 16,
      ),
    );
    canvas.saveLayer(null, _conOpacidad(s.opacidadDeUlima));
    d.pintorDeUlima.paint(canvas, origen);
    canvas.restore();
    canvas.restore();
  }
  if (s.opacidadDeLosMas > 0) {
    canvas.saveLayer(null, _conOpacidad(s.opacidadDeLosMas));
    d.pintorDeLosMas.paint(canvas, origen + Offset(d.anchoDeUlima, 0));
    canvas.restore();
  }

  // La estrella en vuelo.
  pintarEscena(canvas, s.estrella, color: color);

  // Los «++» dibujados.
  if (s.opacidadDeLasCruces > 0) {
    final pintura = Paint()
      ..isAntiAlias = true
      ..color = color.withValues(alpha: s.opacidadDeLasCruces);
    final (h, v) = LogoGeometria.barrasDeCruz();
    for (final c in s.cruces) {
      canvas.save();
      canvas.translate(c.centro.dx, c.centro.dy);
      // En Flutter, como en skewX, x' = x + tan(sesgo) · y, y con y hacia
      // abajo un sesgo negativo lleva la parte de arriba a la derecha.
      canvas.skew(math.tan(c.sesgo), 0);
      canvas.scale(c.largo / LogoGeometria.largoDeCruz);
      canvas.drawRect(h, pintura);
      canvas.drawRect(v, pintura);
      canvas.restore();
    }
  }
  canvas.restore();
}
