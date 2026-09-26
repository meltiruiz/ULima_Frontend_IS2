// lib/components/logo/sello_del_logo.dart
// El sello del logo ULima++ (RF-BIEN-4 y RF-BIEN-20 de la spec de la
// bienvenida). Es la estrella de la cabecera y «ULIMA++» a 1,22 veces su
// tamaño, con los «++» como cruces del logo inclinadas −12°. Lo usan la
// franja de la conversación y la cabecera de las pantallas de «¿Olvidaste tu
// contraseña?», en el mismo lugar y del mismo tamaño. El latido y el pulso
// repintan solo su pintor (RF-BIEN-18).

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/bienvenida/bienvenida_turnos.dart';
import '../header/app_header.dart';
import 'escena_del_logo.dart';
import 'logo_geometria.dart';
import 'pintor_del_logo.dart';

class SelloDelLogo extends StatelessWidget {
  const SelloDelLogo({
    super.key,
    this.latido,
    this.rombos,
    this.color = Colors.white,
  });

  static const double escala = 1.22;
  static const double tamanoDeEstrella = AppHeader.tamanoDeEstrella * escala;
  static const double separacion = AppHeader.separacion * escala;
  static const double inclinacionDeLosMas = -12 * math.pi / 180;

  /// El avance del latido, de 0 a 1. Sin latido vale 0.
  final ValueListenable<double>? latido;

  /// La opacidad de cada rombo durante el pulso, o null con los ocho enteros.
  final ValueListenable<List<double>?>? rombos;
  final Color color;

  /// El estilo único de «ULIMA++» de la cabecera, a 1,22 veces.
  static TextStyle estilo(ColorScheme colores) {
    final base = AppHeader.estiloDeMarca(colores);
    return base.copyWith(fontSize: (base.fontSize ?? 20) * escala);
  }

  @override
  Widget build(BuildContext context) {
    // Con el estilo de texto heredado, como el Text de la cabecera.
    final estiloDelSello = DefaultTextStyle.of(
      context,
    ).style.merge(estilo(Theme.of(context).colorScheme)).copyWith(color: color);
    final sistema = MediaQuery.textScalerOf(context);
    return Semantics(
      header: true,
      label: 'ULIMA++',
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, limites) {
          final escalaDeTexto = escalaQueCabe(
            estiloDelSello,
            sistema,
            limites.maxWidth,
          );
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: tamanoDeEstrella,
                child: CustomPaint(
                  painter: _PintorDeLaEstrella(
                    latido: latido,
                    rombos: rombos,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: separacion),
              Text('ULIMA', style: estiloDelSello, textScaler: escalaDeTexto),
              _LosMas(estilo: estiloDelSello, escala: escalaDeTexto),
            ],
          );
        },
      ),
    );
  }

  /// La escala del sistema o, si el sello no cabe en [ancho], la mayor con la
  /// que cabe (RF-BIEN-20). La subida de la bienvenida mide con ella.
  static TextScaler escalaQueCabe(
    TextStyle estilo,
    TextScaler sistema,
    double ancho,
  ) {
    if (!ancho.isFinite) return sistema;
    double anchoDelTexto(TextScaler s) {
      final p = TextPainter(
        text: TextSpan(text: 'ULIMA++', style: estilo),
        textDirection: TextDirection.ltr,
        textScaler: s,
      )..layout();
      final ancho = p.width;
      p.dispose();
      return ancho;
    }

    final libre = ancho - tamanoDeEstrella - separacion;
    if (anchoDelTexto(sistema) <= libre) return sistema;
    final base = anchoDelTexto(TextScaler.noScaling);
    return TextScaler.linear(math.max(0.5, libre / base));
  }

  /// Los centros de los «++» dentro de la caja de sus glifos, de [tamano] y
  /// con la línea base [base] desde arriba, y su largo, con [em] el tamaño de
  /// la letra ya escalado. Los usan el sello y la subida de la bienvenida,
  /// así que el destino de la subida coincide con el sello.
  static ({List<Offset> centros, double largo}) medidasDeLosMas({
    required Size tamano,
    required double base,
    required double em,
  }) {
    final y = base - 0.34 * em;
    return (
      centros: <Offset>[
        for (var i = 0; i < 2; i++) Offset(tamano.width * (0.25 + 0.5 * i), y),
      ],
      largo: 0.5 * em,
    );
  }
}

class _PintorDeLaEstrella extends CustomPainter {
  _PintorDeLaEstrella({this.latido, this.rombos, required this.color})
    : super(repaint: Listenable.merge(<Listenable?>[latido, rombos]));

  final ValueListenable<double>? latido;
  final ValueListenable<List<double>?>? rombos;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final radio = size.width / 2;
    final avance = latido?.value ?? 0;
    final opacidades = rombos?.value;
    pintarEscena(
      canvas,
      EscenaDelLogo(
        centro: centro,
        radio: radio,
        escalaDeEstrella: escalaDelLatido(avance),
        rombos: opacidades == null
            ? EscenaDelLogo.rombosEnReposo
            : <RomboEnEscena>[
                for (final o in opacidades) RomboEnEscena(opacidad: o),
              ],
      ),
      color: color,
    );
    if (avance > 0 && avance < 1) {
      final anillo = anilloDelLatido(avance);
      canvas.drawCircle(
        centro,
        radio * anillo.radio,
        Paint()
          ..isAntiAlias = true
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = color.withValues(alpha: anillo.opacidad),
      );
    }
  }

  @override
  bool shouldRepaint(_PintorDeLaEstrella oldDelegate) =>
      oldDelegate.latido != latido ||
      oldDelegate.rombos != rombos ||
      oldDelegate.color != color;
}

/// Los «++» del sello, como cruces del logo del ancho de los glifos.
class _LosMas extends StatelessWidget {
  const _LosMas({required this.estilo, required this.escala});

  final TextStyle estilo;
  final TextScaler escala;

  @override
  Widget build(BuildContext context) {
    // Se mide una vez y se desecha, y el pintor recibe solo las medidas.
    final glifos = TextPainter(
      text: TextSpan(text: '++', style: estilo),
      textDirection: TextDirection.ltr,
      textScaler: escala,
    )..layout();
    final tamano = Size(glifos.width, glifos.height);
    final base = glifos.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    glifos.dispose();
    return CustomPaint(
      size: tamano,
      painter: _PintorDeLosMas(
        base: base,
        em: escala.scale(estilo.fontSize ?? 20),
        color: estilo.color ?? Colors.white,
      ),
    );
  }
}

class _PintorDeLosMas extends CustomPainter {
  _PintorDeLosMas({required this.base, required this.em, required this.color});

  /// La línea base de los glifos «++», desde arriba.
  final double base;
  final double em;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final mas = SelloDelLogo.medidasDeLosMas(tamano: size, base: base, em: em);
    final pintura = Paint()
      ..isAntiAlias = true
      ..color = color;
    final (h, v) = LogoGeometria.barrasDeCruz();
    for (final c in mas.centros) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      // Un sesgo horizontal, como el skewX de la maqueta y la salida del
      // splash, y no un giro. Con −12° la punta de arriba de la barra vertical
      // cae hacia la derecha, como la cursiva de «ULIMA».
      canvas.skew(math.tan(SelloDelLogo.inclinacionDeLosMas), 0);
      canvas.scale(mas.largo / LogoGeometria.largoDeCruz);
      canvas.drawRect(h, pintura);
      canvas.drawRect(v, pintura);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PintorDeLosMas oldDelegate) =>
      oldDelegate.base != base ||
      oldDelegate.em != em ||
      oldDelegate.color != color;
}

/// La franja o la cabecera con el sello. Mide lo mismo que la cabecera de
/// /home (`app_header.dart:57-65`), desde el borde superior de la pantalla y
/// detrás de la barra de estado, y centra el sello a lo ancho y a la altura
/// de su fila (RF-BIEN-4 y RF-BIEN-20).
class CabeceraConSello extends StatelessWidget {
  const CabeceraConSello({
    super.key,
    this.color,
    this.radioInferior = 0,
    this.sello = const SelloDelLogo(),
  });

  /// El sello cabe entre dos márgenes de 56 dp, así que la flecha «Volver»
  /// de las pantallas de la contraseña nunca queda encima (RF-BIEN-20).
  static const double margenLateral = 56;

  final Color? color;
  final double radioInferior;
  final Widget sello;

  /// La fila de la cabecera, que fija la campana de 30 dp o el texto si con
  /// letra grande es más alto.
  static double altoDeLaFila(BuildContext context) {
    final texto = TextPainter(
      text: TextSpan(
        text: 'ULIMA++',
        style: DefaultTextStyle.of(
          context,
        ).style.merge(AppHeader.estiloDeMarca(Theme.of(context).colorScheme)),
      ),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final alto = texto.height;
    texto.dispose();
    return math.max(30, math.max(AppHeader.tamanoDeEstrella, alto));
  }

  static double alto(BuildContext context) =>
      50 + altoDeLaFila(context) + 20 + 2;

  static double centroDeLaFila(BuildContext context) =>
      50 + altoDeLaFila(context) / 2;

  @override
  Widget build(BuildContext context) {
    final fila = altoDeLaFila(context);
    return Container(
      height: alto(context),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(radioInferior),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: margenLateral,
            right: margenLateral,
            top: 50,
            height: fila,
            child: Center(child: sello),
          ),
        ],
      ),
    );
  }
}

/// Dónde queda cada pieza de un sello ya dibujado, en coordenadas globales.
/// Es el destino de la subida del recibimiento y el origen del paso al
/// horario (decisión 14 del plan), así que el logo dibujado cae siempre sobre
/// el sello real.
class PiezasDelSello {
  const PiezasDelSello({
    required this.estrella,
    required this.radio,
    required this.ulima,
    required this.origenDeUlima,
    required this.mas,
    required this.largoDeLosMas,
  });

  /// Mide el sello de [claveDelSello] con el estilo y la escala con que se
  /// dibuja, o null si todavía no tiene tamaño. Quien lo recibe desecha
  /// [ulima] con [desechar].
  ///
  /// El estilo, el tema y la escala salen del contexto del propio sello, y no
  /// del de quien pregunta: por encima del Material del Scaffold el estilo
  /// heredado es el de error de MaterialApp, en monospace y subrayado.
  static PiezasDelSello? medir(GlobalKey claveDelSello) {
    final context = claveDelSello.currentContext;
    final caja = context?.findRenderObject();
    if (context == null ||
        caja is! RenderBox ||
        !caja.hasSize ||
        !caja.attached) {
      return null;
    }
    final sello = caja.localToGlobal(Offset.zero) & caja.size;
    final estilo = DefaultTextStyle.of(context).style
        .merge(SelloDelLogo.estilo(Theme.of(context).colorScheme))
        .copyWith(color: Colors.white);
    final escala = SelloDelLogo.escalaQueCabe(
      estilo,
      MediaQuery.textScalerOf(context),
      MediaQuery.sizeOf(context).width - 2 * CabeceraConSello.margenLateral,
    );
    TextPainter medirTexto(String texto) => TextPainter(
      text: TextSpan(text: texto, style: estilo),
      textDirection: TextDirection.ltr,
      textScaler: escala,
    )..layout();
    final ulima = medirTexto('ULIMA');
    final glifos = medirTexto('++');
    final tamanoDeLosMas = Size(glifos.width, glifos.height);
    final base = glifos.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    glifos.dispose();
    // La fila del sello centra en vertical la estrella, «ULIMA» y los «++»,
    // así que cada pieza se mide desde el centro de su caja. La fila puede
    // ser más baja que el texto, como en la franja, y entonces cada caja mide
    // lo que la fila y su texto se pinta desde arriba.
    final izquierdaDeUlima =
        sello.left + SelloDelLogo.tamanoDeEstrella + SelloDelLogo.separacion;
    final altoDeUlima = math.min(ulima.height, sello.height);
    final altoDeLosMas = math.min(tamanoDeLosMas.height, sello.height);
    final esquinaDeLosMas = Offset(
      izquierdaDeUlima + ulima.width,
      sello.center.dy - altoDeLosMas / 2,
    );
    final mas = SelloDelLogo.medidasDeLosMas(
      tamano: tamanoDeLosMas,
      base: base,
      em: escala.scale(estilo.fontSize ?? 20),
    );
    return PiezasDelSello(
      estrella: Offset(
        sello.left + SelloDelLogo.tamanoDeEstrella / 2,
        sello.center.dy,
      ),
      radio: SelloDelLogo.tamanoDeEstrella / 2,
      ulima: ulima,
      origenDeUlima: Offset(
        izquierdaDeUlima,
        sello.center.dy - altoDeUlima / 2,
      ),
      mas: <Offset>[for (final c in mas.centros) esquinaDeLosMas + c],
      largoDeLosMas: mas.largo,
    );
  }

  /// El centro de la estrella y su radio de punta a punta.
  final Offset estrella;
  final double radio;

  /// «ULIMA» ya medido con el estilo del sello, para dibujarlo encima.
  final TextPainter ulima;
  final Offset origenDeUlima;

  /// Los centros de los «++».
  final List<Offset> mas;
  final double largoDeLosMas;

  void desechar() => ulima.dispose();
}
