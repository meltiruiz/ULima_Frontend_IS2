// lib/components/logo/pintor_del_logo.dart
// El único pintor del logo (RF-SPL-2). Se repinta con la escena que escucha,
// sin reconstruir widgets en cada cuadro (RF-SPL-17). Los caminos salen de
// LogoGeometria, que los construye una vez, y las cruces son dos rectángulos.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'escena_del_logo.dart';
import 'logo_geometria.dart';

/// Las letras de Código ya medidas, por letra y tamaño.
final Map<String, TextPainter> _letras = <String, TextPainter>{};

TextPainter _letra(String letra, double tamano) {
  return _letras.putIfAbsent('$letra@$tamano', () {
    return TextPainter(
      text: TextSpan(
        text: letra,
        style: TextStyle(
          fontFamily: 'monospace',
          fontFamilyFallback: const <String>['Menlo', 'Courier'],
          fontSize: tamano,
          color: const Color(0xFFFFFFFF),
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout();
  });
}

Color _conAlfa(Color color, double alfa) =>
    color.withValues(alpha: color.a * alfa.clamp(0.0, 1.0));

/// Pinta [escena] en [canvas], en coordenadas de la vista.
void pintarEscena(
  Canvas canvas,
  EscenaDelLogo escena, {
  Color color = const Color(0xFFFFFFFF),
}) {
  final u = escena.unidad;
  final pintura = Paint()..isAntiAlias = true;
  final destello = escena.destello;

  // La banda tenue del destello cruza el fondo naranja, detrás de todo.
  if (destello != null && destello.intensidad > 0) {
    _banda(canvas, escena, destello, 0.12 * destello.intensidad, null);
  }

  // La estrella con sus rombos.
  canvas.save();
  final centro = escena.centroDeLaEstrella;
  canvas.translate(centro.dx, centro.dy);
  canvas.rotate(escena.giro);
  canvas.scale(u * escena.escalaDeEstrella);
  if (destello != null && destello.intensidad > 0) {
    // Recortada a la silueta sin retraer y detrás de los rombos, así que
    // solo asoma por las rendijas (RF-SPL-7).
    _banda(
      canvas,
      escena,
      destello,
      destello.intensidad,
      LogoGeometria.silueta,
    );
  }
  for (var k = 0; k < 8; k++) {
    final r = escena.rombos[k];
    if (r.opacidad <= 0) continue;
    canvas.save();
    canvas.rotate(r.giro);
    final d = LogoGeometria.direccionesDeRombo[k] * r.desplazamiento;
    final c = LogoGeometria.centrosDeRombo[k];
    canvas.translate(d.dx + c.dx, d.dy + c.dy);
    canvas.scale(r.escala);
    canvas.translate(-c.dx, -c.dy);
    pintura.color = _conAlfa(color, r.opacidad * escena.opacidad);
    canvas.drawPath(LogoGeometria.rombos[k], pintura);
    canvas.restore();
  }
  canvas.save();
  canvas.scale(escena.escalaCentral);
  pintura.color = _conAlfa(color, escena.opacidad);
  canvas.drawPath(LogoGeometria.estrellaCentral, pintura);
  canvas.restore();
  canvas.restore();

  // Los anillos, en el marco.
  for (final a in escena.anillos) {
    if (a.opacidad <= 0) continue;
    final trazo = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = a.trazo * u
      ..color = _conAlfa(color, a.opacidad * escena.opacidad);
    canvas.drawCircle(escena.aVista(a.centro), a.radio * u, trazo);
  }

  // Los «+», recortados si la escena lo pide.
  final recorte = escena.recorteDeCruces;
  canvas.save();
  if (recorte != null) {
    final x = escena.aVista(Offset(recorte, 0)).dx;
    canvas.clipRect(Rect.fromLTRB(x, -1e5, 1e5, 1e5));
  }
  for (final c in escena.cruces) {
    if (c.opacidad <= 0 || c.escala <= 0) continue;
    canvas.save();
    final p = escena.aVista(c.centro);
    canvas.translate(p.dx, p.dy);
    canvas.rotate(c.giro);
    canvas.scale(u * c.escala);
    final (h, v) = LogoGeometria.barrasDeCruz(grosor: c.grosor);
    pintura.color = _conAlfa(c.color, c.opacidad * escena.opacidad);
    canvas.drawRect(h, pintura);
    canvas.drawRect(v, pintura);
    canvas.restore();
  }
  canvas.restore();

  // Las letras de Código, cada una centrada en su celda.
  final texto = escena.texto;
  if (texto != null && texto.opacidad > 0 && texto.visibles > 0) {
    final tamano = TextoDeCodigo.tamanoEnU * u;
    canvas.saveLayer(
      null,
      Paint()..color = _conAlfa(const Color(0xFFFFFFFF), texto.opacidad),
    );
    for (var i = 0; i < math.min(texto.visibles, 5); i++) {
      final letra = _letra(TextoDeCodigo.palabra[i], tamano);
      final celda =
          TextoDeCodigo.bordeDeCelda(i) +
          TextoDeCodigo.celda * TextoDeCodigo.tamanoEnU / 2;
      final base = escena.aVista(
        Offset(celda, TextoDeCodigo.lineaBaseEnU + texto.dy),
      );
      letra.paint(
        canvas,
        Offset(
          base.dx - letra.width / 2,
          base.dy -
              letra.computeDistanceToActualBaseline(TextBaseline.alphabetic),
        ),
      );
    }
    canvas.restore();
  }

  final cursor = escena.cursor;
  if (cursor != null && cursor.opacidad > 0) {
    pintura.color = _conAlfa(color, cursor.opacidad * escena.opacidad);
    canvas.drawRect(
      Rect.fromCenter(
        center: escena.aVista(cursor.centro),
        width: 0.08 * TextoDeCodigo.tamanoEnU * u,
        height: cursor.alto * u,
      ),
      pintura,
    );
  }
}

/// Una banda blanca con degradado que cruza en diagonal. Con [recorte], va
/// dentro de él y en u de la estrella. Sin él, cruza la pantalla en dp.
void _banda(
  Canvas canvas,
  EscenaDelLogo escena,
  DestelloEnEscena destello,
  double intensidad,
  Path? recorte,
) {
  const alcance = 520.0; // u a cada lado del centro
  const ancho = 140.0; // u
  final s = -alcance + 2 * alcance * destello.avance;
  final enU = recorte != null;
  final escala = enU ? 1.0 : escena.unidad;
  final origen = enU ? Offset.zero : escena.centroDeLaEstrella;
  final eje = const Offset(1, 1) / math.sqrt2;
  final medio = origen + eje * (s * escala);
  final desde = medio - eje * (ancho / 2 * escala);
  final hasta = medio + eje * (ancho / 2 * escala);
  const blanco = Color(0xFFFFFFFF);
  final pintura = Paint()
    ..shader = ui.Gradient.linear(
      desde,
      hasta,
      <Color>[
        _conAlfa(blanco, 0),
        _conAlfa(blanco, intensidad),
        _conAlfa(blanco, 0),
      ],
      const <double>[0, 0.5, 1],
    );
  canvas.save();
  if (recorte != null) canvas.clipPath(recorte);
  final lado = alcance * 2 * escala;
  canvas.drawRect(
    Rect.fromCenter(center: origen, width: lado, height: lado),
    pintura,
  );
  canvas.restore();
}

class PintorDelLogo extends CustomPainter {
  PintorDelLogo(this.escena, {this.color = const Color(0xFFFFFFFF)})
    : super(repaint: escena);

  final ValueListenable<EscenaDelLogo> escena;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) =>
      pintarEscena(canvas, escena.value, color: color);

  @override
  bool shouldRepaint(PintorDelLogo oldDelegate) =>
      oldDelegate.escena != escena || oldDelegate.color != color;
}

/// El logo de una escena que cambia, fuera de la semántica.
class LogoEnEscena extends StatelessWidget {
  const LogoEnEscena({
    super.key,
    required this.escena,
    this.color = const Color(0xFFFFFFFF),
  });

  final ValueListenable<EscenaDelLogo> escena;
  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      painter: PintorDelLogo(escena, color: color),
      size: Size.infinite,
    ),
  );
}
