// lib/pages/splash/paso_al_horario.dart
// El paso al horario de la bienvenida (RF-BIEN-11 y decisión B-33). La capa
// del arranque lo dibuja mientras /home se monta debajo. La franja pasa a la
// cabecera, el sello a la estrella y a «ULIMA++» de la cabecera, la
// conversación se desvanece y Ulises vuela de su último avatar a la burbuja.
// Es una función pura del instante, como las salidas de la intro, y un pintor
// la dibuja.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import '../../components/logo/escena_del_logo.dart';
import '../../components/logo/logo_geometria.dart';
import '../../components/logo/pintor_del_logo.dart';
import '../../components/logo/sello_del_logo.dart';
import '../bienvenida/widgets/vuelo_de_ulises.dart'
    show PoseDeUlises, curvaSeno;
import 'salidas.dart';
import 'variantes/variante_de_intro.dart' show grado, medioSeno, mezcla, tramo;

const double _duracion = 1050;
const double _vuelo = 1150;
const double _aterrizaje = 420;

/// Lo que la bienvenida entrega a la capa antes de navegar (RF-BIEN-11).
class DatosDelPaso {
  const DatosDelPaso({
    required this.franja,
    required this.colorDeLaFranja,
    required this.sello,
    required this.conversacion,
    required this.lugarDeLaConversacion,
    required this.avatar,
    required this.colorDeFondo,
    required this.colorDeLaPagina,
  });

  /// La franja, de borde a borde desde arriba, con sus esquinas de 26 dp.
  final Rect franja;
  final Color colorDeLaFranja;

  /// Las piezas del sello, medidas como las dibuja.
  final PiezasDelSello sello;

  /// La imagen de la conversación y del compositor, que se desvanece. La capa
  /// la descarta al retirarse.
  final ui.Image? conversacion;
  final Rect lugarDeLaConversacion;

  /// El último avatar de Ulises en la conversación, de donde sale a volar.
  final Rect? avatar;

  /// El fondo de la conversación, que también tapa el avatar en la imagen.
  final Color colorDeFondo;

  /// El fondo de /home, bajo su cabecera.
  final Color colorDeLaPagina;

  /// La capa descarta la imagen y el texto medido al retirarse.
  void desechar() {
    conversacion?.dispose();
    sello.desechar();
  }
}

class EscenaDelPaso {
  const EscenaDelPaso({
    required this.franja,
    required this.radioDeLaFranja,
    required this.colorDeLaFranja,
    required this.opacidadDeLaFranja,
    required this.opacidadDeLaConversacion,
    required this.estrella,
    required this.origenDeUlima,
    required this.escalaDeUlima,
    required this.fundidoAlTexto,
    required this.cruces,
    required this.opacidadDeLasCruces,
    required this.paginaOpacidad,
    required this.paginaDy,
    required this.ulises,
    required this.ulisesPosado,
  });

  final Rect franja;
  final double radioDeLaFranja;
  final Color colorDeLaFranja;

  /// La franja tapa la cabecera real hasta el 70 % y se desvanece hasta el
  /// 100 %, salvo detrás de la estrella y del texto, que llegan dibujados.
  final double opacidadDeLaFranja;
  final double opacidadDeLaConversacion;
  final EscenaDelLogo estrella;

  /// «ULIMA» del sello, que viaja y se achica hasta el texto de la cabecera.
  final Offset origenDeUlima;
  final double escalaDeUlima;

  /// El texto de la cabecera, «ULIMA++», que entra en el último 25 %.
  final double fundidoAlTexto;
  final List<CruzDeSalida> cruces;
  final double opacidadDeLasCruces;
  final double paginaOpacidad;
  final double paginaDy;

  /// Ulises en vuelo, o null si ya se posó en la burbuja.
  final PoseDeUlises? ulises;

  /// Ulises ya está en la burbuja, o no vuela.
  final bool ulisesPosado;
}

/// El paso dura 1050 ms, y con Ulises en vuelo, hasta que se posa.
double duracionDelPaso({required bool conVuelo}) =>
    conVuelo ? _vuelo + _aterrizaje : _duracion;

Offset _cubica(Offset p0, Offset p1, Offset p2, Offset p3, double t) {
  final s = 1 - t;
  return p0 * (s * s * s) +
      p1 * (3 * s * s * t) +
      p2 * (3 * s * t * t) +
      p3 * (t * t * t);
}

/// El paso en [ms], contados desde que la capa midió la cabecera. Sin
/// [destino], el paso queda en su primer cuadro.
EscenaDelPaso pasoAlHorario({
  required double ms,
  required DatosDelPaso datos,
  required DestinoDeLaSalida? destino,
  required Rect? burbuja,
  required Size pantalla,
}) {
  final d = destino;
  final s = datos.sello;
  final t = d == null ? 0.0 : tramo(ms, 0, _duracion);
  final e = Curves.easeInOutCubic.transform(t);
  final esquinas = Curves.easeInOutCubic.transform(tramo(t, 0, 0.4));
  final conversacion = 1 - tramo(t, 0, 0.35);
  final cuerpo = Curves.easeOutCubic.transform(tramo(t, 0.32, 0.75));
  final (ulises, posado) = _ulisesAlHorario(
    d == null ? 0 : ms,
    datos.avatar,
    burbuja,
    pantalla,
    conversacion,
  );
  return EscenaDelPaso(
    franja: d == null ? datos.franja : Rect.lerp(datos.franja, d.cabecera, e)!,
    radioDeLaFranja: 26 * (1 - esquinas),
    colorDeLaFranja: Color.lerp(
      datos.colorDeLaFranja,
      d?.color ?? datos.colorDeLaFranja,
      esquinas,
    )!,
    opacidadDeLaFranja: 1 - tramo(t, 0.7, 1),
    opacidadDeLaConversacion: conversacion,
    estrella: EscenaDelLogo(
      centro: d == null
          ? s.estrella
          : Offset.lerp(s.estrella, d.estrella.center, e)!,
      radio: d == null ? s.radio : mezcla(s.radio, d.estrella.width / 2, e),
    ),
    origenDeUlima: d == null
        ? s.origenDeUlima
        : Offset.lerp(s.origenDeUlima, d.texto.topLeft, e)!,
    escalaDeUlima: d == null
        ? 1
        : mezcla(1, d.pintorDeUlima.height / s.ulima.height, e),
    fundidoAlTexto: tramo(t, 0.75, 1),
    cruces: <CruzDeSalida>[
      for (var i = 0; i < s.mas.length; i++)
        CruzDeSalida(
          // Los «++» van con un salto de 6 dp.
          centro:
              (d == null ? s.mas[i] : Offset.lerp(s.mas[i], d.cruces[i], e)!) -
              Offset(0, 6 * medioSeno(e)),
          largo: d == null
              ? s.largoDeLosMas
              : mezcla(s.largoDeLosMas, d.tamanoDeCruz, e),
          // Sesgados −12° como en el sello y en la cabecera.
          sesgo: SelloDelLogo.inclinacionDeLosMas,
        ),
    ],
    opacidadDeLasCruces: 1 - tramo(t, 0.75, 1),
    paginaOpacidad: tramo(t, 0.22, 0.55),
    paginaDy: 24 * (1 - cuerpo),
    ulises: ulises,
    ulisesPosado: posado,
  );
}

/// Ulises sale de su último avatar, vuela en 1150 ms con la curva seno por la
/// derecha y hacia arriba, y baja a la burbuja. Crece hasta 1,6 veces en el
/// primer 45 %, se achica hasta 56 dp con un aleteo que se apaga y una
/// inclinación de hasta 12°, y se posa en 420 ms con un aplastamiento. Sin
/// burbuja, como el docente, se desvanece con la conversación.
(PoseDeUlises?, bool) _ulisesAlHorario(
  double ms,
  Rect? avatar,
  Rect? burbuja,
  Size pantalla,
  double opacidadDeLaConversacion,
) {
  if (avatar == null) return (null, true);
  if (burbuja == null) {
    return (
      PoseDeUlises(
        centro: avatar.center,
        lado: avatar.width,
        opacidad: opacidadDeLaConversacion,
      ),
      true,
    );
  }
  if (ms >= _vuelo + _aterrizaje) return (null, true);
  final hasta = burbuja.center;
  if (ms >= _vuelo) {
    final u = tramo(ms, _vuelo, _vuelo + _aterrizaje);
    final onda = math.sin(2 * math.pi * u) * (1 - u);
    return (
      PoseDeUlises(
        centro: hasta,
        lado: 56,
        escalaX: 1 + 0.18 * onda,
        escalaY: 1 - 0.18 * onda,
      ),
      false,
    );
  }
  final t = tramo(ms, 0, _vuelo);
  final desde = avatar.center;
  final inicial = avatar.width;
  final lado = t <= 0.45
      ? mezcla(inicial, 1.6 * inicial, Curves.easeOutCubic.transform(t / 0.45))
      : mezcla(
          1.6 * inicial,
          56,
          Curves.easeInOutCubic.transform(tramo(t, 0.45, 1)),
        );
  return (
    PoseDeUlises(
      centro: _cubica(
        desde,
        Offset(pantalla.width * 0.88, desde.dy - 0.2 * pantalla.height),
        Offset(
          hasta.dx + 0.35 * pantalla.width,
          hasta.dy - 0.3 * pantalla.height,
        ),
        hasta,
        curvaSeno(t),
      ),
      lado: lado,
      giro: 12 * grado * medioSeno(t),
      escalaY: 1 - 0.1 * math.sin(6 * math.pi * t).abs() * (1 - t),
    ),
    false,
  );
}

Paint _conOpacidad(double opacidad) =>
    Paint()..color = Color.fromRGBO(0, 0, 0, opacidad.clamp(0.0, 1.0));

/// Pinta el paso sobre /home. Ulises va aparte, como un widget en su capa.
void pintarElPaso(
  Canvas canvas,
  EscenaDelPaso e,
  DatosDelPaso datos,
  DestinoDeLaSalida? destino,
) {
  // Mientras el cuerpo de /home sube, la capa corre la página entera, así que
  // lo que baja de su cabecera asoma bajo la franja. Una banda del fondo de
  // /home lo tapa, y el cuerpo se ve subir desde la cabecera (RF-BIEN-11).
  if (destino != null && e.paginaOpacidad > 0 && e.paginaDy > 0) {
    canvas.drawRect(
      Rect.fromLTWH(e.franja.left, e.franja.bottom, e.franja.width, e.paginaDy),
      Paint()..color = datos.colorDeLaPagina,
    );
  }

  // La conversación y el compositor, sobre su fondo, sin el avatar del que
  // sale Ulises.
  if (e.opacidadDeLaConversacion > 0) {
    canvas.saveLayer(null, _conOpacidad(e.opacidadDeLaConversacion));
    final lugar = datos.lugarDeLaConversacion;
    canvas.drawRect(lugar, Paint()..color = datos.colorDeFondo);
    final imagen = datos.conversacion;
    if (imagen != null) {
      canvas.drawImageRect(
        imagen,
        Offset.zero & Size(imagen.width.toDouble(), imagen.height.toDouble()),
        lugar,
        Paint()..filterQuality = FilterQuality.medium,
      );
    }
    final avatar = datos.avatar;
    if (avatar != null) {
      canvas.drawCircle(
        avatar.center,
        avatar.width / 2 + 1,
        Paint()..color = datos.colorDeFondo,
      );
    }
    canvas.restore();
  }

  // La franja, que ya es la cabecera. Detrás de la estrella y del texto
  // queda entera, porque los dibujados caen sobre los reales.
  final esquina = Radius.circular(e.radioDeLaFranja);
  final franja = RRect.fromRectAndCorners(
    e.franja,
    bottomLeft: esquina,
    bottomRight: esquina,
  );
  final pintura = Paint()..color = e.colorDeLaFranja;
  if (destino == null || e.opacidadDeLaFranja >= 1) {
    canvas.drawRRect(franja, pintura);
  } else {
    final piezas = Path()
      ..addRect(destino.estrella.inflate(4))
      ..addRect(destino.texto.inflate(4));
    canvas.save();
    canvas.clipPath(piezas);
    canvas.drawRRect(franja, pintura);
    canvas.restore();
    canvas.save();
    canvas.clipPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(e.franja.inflate(1)),
        piezas,
      ),
    );
    canvas.drawRRect(
      franja,
      Paint()
        ..color = e.colorDeLaFranja.withValues(alpha: e.opacidadDeLaFranja),
    );
    canvas.restore();
  }

  // «ULIMA» del sello, que viaja, y el texto de la cabecera al final.
  if (e.fundidoAlTexto < 1) {
    canvas.saveLayer(null, _conOpacidad(1 - e.fundidoAlTexto));
    canvas.translate(e.origenDeUlima.dx, e.origenDeUlima.dy);
    canvas.scale(e.escalaDeUlima);
    datos.sello.ulima.paint(canvas, Offset.zero);
    canvas.restore();
  }
  if (destino != null && e.fundidoAlTexto > 0) {
    canvas.saveLayer(null, _conOpacidad(e.fundidoAlTexto));
    destino.pintorDeUlima.paint(canvas, destino.texto.topLeft);
    destino.pintorDeLosMas.paint(
      canvas,
      destino.texto.topLeft + Offset(destino.anchoDeUlima, 0),
    );
    canvas.restore();
  }

  pintarEscena(canvas, e.estrella);

  // Los «++» dibujados, que se funden con los glifos en el último 25 %.
  if (e.opacidadDeLasCruces > 0) {
    final blanco = Paint()
      ..isAntiAlias = true
      ..color = const Color(
        0xFFFFFFFF,
      ).withValues(alpha: e.opacidadDeLasCruces);
    final (h, v) = LogoGeometria.barrasDeCruz();
    for (final c in e.cruces) {
      canvas.save();
      canvas.translate(c.centro.dx, c.centro.dy);
      // Un sesgo horizontal, como la cursiva de «ULIMA++», y no un giro.
      canvas.skew(math.tan(c.sesgo), 0);
      canvas.scale(c.largo / LogoGeometria.largoDeCruz);
      canvas.drawRect(h, blanco);
      canvas.drawRect(v, blanco);
      canvas.restore();
    }
  }
}
