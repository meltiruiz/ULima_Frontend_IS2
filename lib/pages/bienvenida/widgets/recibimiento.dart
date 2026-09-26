// lib/pages/bienvenida/widgets/recibimiento.dart
// El recibimiento de la bienvenida (RF-BIEN-2, RF-BIEN-3 y RF-BIEN-21). Tapa
// la conversación desde el primer cuadro, igual al último de la intro, trae a
// Ulises volando junto a la estrella, muestra el saludo y los dos botones y,
// al responder, lleva el logo al sello y a Ulises a su avatar. Las medidas se
// calculan una vez, al empezar el vuelo (B-27), y la estrella nunca queda
// tapada (RF-BIEN-4).

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart' show FocusSemanticEvent;

import '../../../components/logo/escena_del_logo.dart';
import '../../../components/logo/logo_geometria.dart';
import '../../../components/logo/pintor_del_logo.dart';
import '../../../components/logo/sello_del_logo.dart';
import '../../../configs/themes.dart';
import '../../../domain/bienvenida/bienvenida_turnos.dart';
import '../../splash/salidas.dart' show naranjaDelSplash;
import '../../splash/variantes/variante_de_intro.dart'
    show grado, mezcla, tramo;
import 'anillo_de_foco.dart';
import 'vuelo_de_ulises.dart';

typedef _Textos = TextosDeLaBienvenida;

/// Los tiempos del recibimiento en ms. Los cuatro primeros cuentan desde el
/// relevo del splash y los demás desde la respuesta (RF-BIEN-2 y RF-BIEN-4).
abstract final class TiemposDelRecibimiento {
  static const double quieto = 160;
  static const double aterrizaje = 1460;
  static const double finDelRebote = 1940;
  static const double botones = 2320;
  static const double inicioDeLaSubida = 90;
  static const double finDeLaSubida = 990;
  static const double inicioDelSalto = 120;
  static const double posado = 1030;
}

typedef _T = TiemposDelRecibimiento;

/// Los tiempos con reducir movimiento en ms (RF-BIEN-15).
abstract final class TiemposSinMovimiento {
  /// Duración del cruce de «Si no cabe», desde que se sabe que no hay
  /// sesión.
  static const double cruceDeLaEstrella = 220;

  /// Ulises aparece a los 120 ms del relevo, con un fundido de 160 ms, y el
  /// fondo cambia desde ese momento en 150 ms.
  static const double ulises = 120;
  static const double fundidoDeUlises = 160;
  static const double fondo = 150;

  /// La tarjeta y los botones entran a los 280 y 660 ms del relevo, con un
  /// fundido de 180 ms cada uno.
  static const double tarjeta = 280;
  static const double botones = 660;
  static const double fundido = 180;

  /// Desde la respuesta, la conversación aparece encima en 220 ms y Ulises
  /// pasa a su avatar en 140 ms.
  static const double cruceDeLaSubida = 220;
  static const double fundidoDelAvatar = 140;
}

typedef _S = TiemposSinMovimiento;

class Recibimiento extends StatefulWidget {
  const Recibimiento({
    super.key,
    required this.pose,
    required this.conSesion,
    required this.claveDelSello,
    required this.avatar,
    required this.alResponder,
    required this.alAterrizarConSesion,
    required this.alSaludarEnLaConversacion,
    required this.alSubir,
    required this.alPosarseElSello,
    required this.alTerminar,
  });

  static const Key claveDelFondo = Key('recibimiento-fondo');
  static const Key claveDeUlises = Key('recibimiento-ulises');
  static const Key claveDeLaTarjeta = Key('recibimiento-tarjeta');
  static const Key claveDeLosBotones = Key('recibimiento-botones');

  /// El fondo y el área que cubre, la estrella, la de debajo con reducir
  /// movimiento, los puntos de la sombra, la estela y las partículas, los
  /// «++» que viajan en la subida y cuánto se ve de «ULIMA» del cuadro
  /// actual, para las pruebas. [context] es el de una pieza del
  /// recibimiento.
  @visibleForTesting
  static ({
    Color? fondo,
    Rect? areaDelFondo,
    EscenaDelLogo? estrella,
    EscenaDelLogo? estrellaDebajo,
    double opacidadDeLaEstrella,
    int puntos,
    int crucesDeLaSubida,
    double reveladoDeUlima,
  })
  cuadroActual(BuildContext context) {
    final estado = context.findAncestorStateOfType<_RecibimientoState>()!;
    final p = estado._pintor(estado.context);
    return (
      fondo: p.fondo == null ? null : p.color,
      areaDelFondo: p.fondo,
      estrella: p.estrella,
      estrellaDebajo: p.estrellaDebajo,
      opacidadDeLaEstrella: p.opacidadDeLaEstrella,
      puntos:
          p.estela.length + p.particulas.length + (p.sombra == null ? 0 : 1),
      crucesDeLaSubida: p.cruces.length,
      reveladoDeUlima: p.ulima == null || p.origenDeUlima == null
          ? 0
          : p.revelado,
    );
  }

  /// La estrella después de «Si no cabe», para las pruebas.
  @visibleForTesting
  static ({Offset centro, double radio}) estrellaActual(BuildContext context) {
    final estado = context.findAncestorStateOfType<_RecibimientoState>()!;
    return (centro: estado._estrella, radio: estado._radio);
  }

  /// La pose que deja la intro, o la de reposo sin pose (RF-BIEN-3).
  final PoseDelLogo pose;

  /// Hay una sesión puesta, así que no hay tarjeta ni botones y el fin del
  /// rebote hace de respuesta (RF-BIEN-21). Null mientras el controlador
  /// todavía no atiende la visita, y el recibimiento espera a saberlo.
  final bool? conSesion;

  /// La clave del sello de la franja, que es el destino de la subida.
  final GlobalKey claveDelSello;

  /// Dónde queda el avatar de 40 dp del primer grupo.
  final Rect avatar;
  final void Function(bool yaUsa) alResponder;
  final VoidCallback alAterrizarConSesion;
  final VoidCallback alSaludarEnLaConversacion;

  /// Empieza la subida, y la conversación ya trae su primer grupo.
  final VoidCallback alSubir;

  /// El logo llega al sello, que late (RF-BIEN-4).
  final VoidCallback alPosarseElSello;

  /// Ulises se posa en su avatar y el recibimiento termina.
  final VoidCallback alTerminar;

  @override
  State<Recibimiento> createState() => _RecibimientoState();
}

enum _Fase { llegada, saludo, subida, fin }

class _RecibimientoState extends State<Recibimiento>
    with SingleTickerProviderStateMixin {
  late final Ticker _reloj = createTicker(_alTic);
  double _ms = 0;
  _Fase _fase = _Fase.llegada;
  double? _respuestaEn;
  bool _conTarjeta = false;
  bool _selloPosado = false;
  MedidasDelRecibimiento? _medidas;
  PuntosDelVuelo? _puntos;
  Offset? _aterrizaje;
  PiezasDelSello? _destino;
  late Offset _estrella = widget.pose.centro;
  late double _radio = widget.pose.radio;
  double _cruceDeLaEstrella = 1;

  /// Cuándo empezó el cruce de la estrella, que espera a saber si hay sesión.
  double? _inicioDelCruce;

  bool get _sinMovimiento => MediaQuery.disableAnimationsOf(context);
  bool get _conLector => MediaQuery.accessibleNavigationOf(context);

  /// Con lector, la tarjeta y los botones aparecen con el relevo (RF-BIEN-16).
  /// Sin movimiento, Ulises aparece en su lugar y la tarjeta y los botones
  /// entran con fundidos (RF-BIEN-15).
  double get _msDeMedida => _conLector || _sinMovimiento ? 0 : _T.quieto;
  double get _msDeLaTarjeta =>
      _conLector ? 0 : (_sinMovimiento ? _S.tarjeta : _T.finDelRebote);
  double get _msDeLosBotones =>
      _conLector ? 0 : (_sinMovimiento ? _S.botones : _T.botones);

  /// Con lector la tarjeta no espera, pero Ulises vuela y el fondo cambia
  /// igual, así que el reloj sigue hasta el fin de la entrada.
  double get _finDeLaEntrada =>
      _sinMovimiento ? _S.botones + _S.fundido : _T.botones + 400;

  /// Sin movimiento o con lector, la tarjeta no espera a que la estrella se
  /// deslice, así que «Si no cabe» es un fundido cruzado (RF-BIEN-15 y
  /// RF-BIEN-16).
  bool get _cruzaLaEstrella => _sinMovimiento || _conLector;
  double get _finDeLaSubida =>
      _sinMovimiento ? _S.cruceDeLaSubida : _T.finDeLaSubida;
  double get _posado => _sinMovimiento ? _S.cruceDeLaSubida : _T.posado;

  static const TextStyle _estiloSaludo = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  static const TextStyle _estiloPregunta = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    height: 1.25,
  );
  static const TextStyle _estiloBoton = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
  );

  /// La entrada de la tarjeta, con el leve rebote de la maqueta.
  static const Curve _rebote = Cubic(0.2, 0.9, 0.25, 1.25);

  @override
  void initState() {
    super.initState();
    unawaited(_reloj.start());
  }

  @override
  void dispose() {
    _reloj.dispose();
    _destino?.desechar();
    super.dispose();
  }

  @override
  void didUpdateWidget(Recibimiento anterior) {
    super.didUpdateWidget(anterior);
    // Las medidas pueden llegar antes que la visita: con lector, sin
    // movimiento, o si el token tarda más de 160 ms. Con sesión, Ulises
    // aterriza en su lugar de la maqueta.
    final a = _aterrizaje;
    if (widget.conSesion == true && anterior.conSesion != true && a != null) {
      final aterrizaje = widget.pose.centro + const Offset(-104, 138);
      if (aterrizaje != a) {
        _aterrizaje = aterrizaje;
        _puntos = puntosDelVuelo(aterrizaje, MediaQuery.sizeOf(context));
      }
    }
  }

  void _alTic(Duration t) {
    _ms = t.inMicroseconds / 1000;
    if (_medidas == null && _ms >= _msDeMedida) _medir();
    switch (_fase) {
      case _Fase.llegada:
        if (_medidas == null) break;
        _moverLaEstrella();
        if (_ms >= _msDeLaTarjeta) _alTerminarElRebote();
      case _Fase.saludo:
        // Con lector, la tarjeta llega antes que el cruce de la estrella.
        _moverLaEstrella();
        // Con todo quieto, el reloj calla y no pide cuadros mientras el
        // alumno lee (decisión 13 del plan y RF-BIEN-18).
        if (_ms >= _finDeLaEntrada && _cruceDeLaEstrella >= 1) {
          _reloj.muted = true;
        }
      case _Fase.subida:
        // Tras un toque en reposo, la subida cuenta desde este cuadro.
        _respuestaEn ??= _ms;
        if (!_sinMovimiento) {
          _destino ??= PiezasDelSello.medir(widget.claveDelSello);
        }
        final desde = _ms - _respuestaEn!;
        if (!_selloPosado && desde >= _finDeLaSubida) {
          _selloPosado = true;
          widget.alPosarseElSello();
        }
        if (desde >= _posado) {
          _fase = _Fase.fin;
          _reloj.stop();
          widget.alTerminar();
          return;
        }
      case _Fase.fin:
        return;
    }
    setState(() {});
  }

  /// Mide una vez, al empezar el vuelo, con la escala de texto de ese
  /// momento (B-27). Los textos se miden con el estilo heredado, como los
  /// dibuja la tarjeta.
  void _medir() {
    final mq = MediaQuery.of(context);
    final ancho = math.min(mq.size.width, 600.0);
    final columna = Rect.fromLTWH(
      (mq.size.width - ancho) / 2,
      0,
      ancho,
      mq.size.height,
    );
    final heredado = DefaultTextStyle.of(context).style;
    double alto(String texto, TextStyle estilo, double maximo) {
      final p = TextPainter(
        text: TextSpan(text: texto, style: heredado.merge(estilo)),
        textDirection: TextDirection.ltr,
        textScaler: mq.textScaler,
      )..layout(maxWidth: maximo);
      final h = p.height;
      p.dispose();
      return h;
    }

    final bordeDeUlises = widget.pose.centro.dx - 104 + 35;
    final anchoDelTexto = columna.right - 12 - (bordeDeUlises + 11) - 26;
    final anchoDelBoton = columna.width - 44;
    final boton = math.max(
      50.0,
      math.max(
            alto(_Textos.siEntrar, _estiloBoton, anchoDelBoton),
            alto(_Textos.soyNuevo, _estiloBoton, anchoDelBoton),
          ) +
          18,
    );
    final medidas = medirElRecibimiento(
      estrella: widget.pose.centro,
      radio: widget.pose.radio,
      columna: columna,
      altoDePantalla: mq.size.height,
      areaSeguraArriba: mq.padding.top,
      areaSeguraAbajo: mq.padding.bottom,
      altoDeLaTarjeta:
          9 +
          alto(_Textos.saludo, _estiloSaludo, anchoDelTexto) +
          1 +
          alto(_Textos.pregunta, _estiloPregunta, anchoDelTexto) +
          11,
      altoDeLosBotones: boton * 2 + 10,
    );
    _medidas = medidas;
    // Con sesión no hay tarjeta ni botones, así que «Si no cabe» no aplica y
    // Ulises aterriza en su lugar de la maqueta (RF-BIEN-21).
    final aterrizaje = widget.conSesion == true
        ? widget.pose.centro + const Offset(-104, 138)
        : medidas.ulises.center;
    _aterrizaje = aterrizaje;
    _puntos = puntosDelVuelo(aterrizaje, mq.size);
  }

  /// Si Ulises y la tarjeta no caben, la estrella sube, y si hace falta se
  /// achica, lo justo antes de que Ulises aterrice, en 300 ms con
  /// easeInOutCubic (B-28). Sin movimiento o con lector no se desliza, y la
  /// nueva aparece encima en 220 ms, desde que se sabe que no hay sesión,
  /// mientras la del centro sigue entera debajo (RF-BIEN-15 y RF-BIEN-16).
  void _moverLaEstrella() {
    final m = _medidas!;
    // Con sesión, o mientras todavía no se sabe, la estrella no se mueve
    // (RF-BIEN-21).
    if (widget.conSesion != false || m.enConversacion) return;
    if (_cruzaLaEstrella) {
      _estrella = m.estrella;
      _radio = m.radio;
      final inicio = _inicioDelCruce ??= _ms;
      _cruceDeLaEstrella = tramo(_ms, inicio, inicio + _S.cruceDeLaEstrella);
      return;
    }
    final t = Curves.easeInOutCubic.transform(
      tramo(_ms, _T.aterrizaje - 300, _T.aterrizaje),
    );
    _estrella = Offset.lerp(widget.pose.centro, m.estrella, t)!;
    _radio = mezcla(widget.pose.radio, m.radio, t);
  }

  void _alTerminarElRebote() {
    final conSesion = widget.conSesion;
    // Mientras el controlador no atiende la visita, Ulises sigue asentado.
    if (conSesion == null) return;
    if (conSesion) {
      // El fin del rebote hace de respuesta, sin el asentimiento, y con
      // lector la conversación empieza con el relevo (RF-BIEN-16 y
      // RF-BIEN-21).
      widget.alAterrizarConSesion();
      _subir(_ms);
    } else if (_medidas!.enConversacion) {
      // Ni achicando la estrella caben, así que Ulises saluda ya en la
      // conversación (B-28).
      widget.alSaludarEnLaConversacion();
      _subir(_ms);
    } else {
      _conTarjeta = true;
      _fase = _Fase.saludo;
    }
  }

  void _responder(bool yaUsa) {
    // Los toques cuentan desde que los botones empiezan a entrar.
    if (_fase != _Fase.saludo || _ms < _msDeLosBotones) return;
    widget.alResponder(yaUsa);
    // En reposo el reloj calla y _ms quedó en el último cuadro, así que la
    // subida cuenta desde el primer cuadro después del toque. Sin movimiento
    // también, porque el cruce de la página empieza en ese cuadro.
    final enReposo = _reloj.muted;
    _reloj.muted = false;
    _subir(enReposo || _sinMovimiento ? null : _ms);
  }

  void _subir(double? ms) {
    _respuestaEn = ms;
    _fase = _Fase.subida;
    widget.alSubir();
  }

  _PintorDelRecibimiento _pintor(BuildContext context) {
    final tamano = MediaQuery.sizeOf(context);
    final franja = MaterialTheme.bienvenidaFranja(Theme.brightnessOf(context));
    // Mientras Ulises vuela, el fondo pasa en 1100 ms, con la curva seno, de
    // #E77330 al color de la franja, o en 150 ms sin movimiento (RF-BIEN-2 y
    // RF-BIEN-15).
    final quieto = _sinMovimiento;
    final cambio = quieto
        ? tramo(_ms, _S.ulises, _S.ulises + _S.fondo)
        : curvaSeno(tramo(_ms, _T.quieto, _T.quieto + 1100));
    final quieta = EscenaDelLogo.desdePose(
      widget.pose,
    ).copyWith(centro: _estrella, radio: _radio);
    // Sin movimiento o con lector, la estrella del centro sigue entera debajo
    // mientras la nueva aparece encima.
    final seMovio =
        _estrella != widget.pose.centro || _radio != widget.pose.radio;
    final debajo = _cruzaLaEstrella && seMovio && _cruceDeLaEstrella < 1
        ? EscenaDelLogo.desdePose(widget.pose)
        : null;
    final a = _aterrizaje;
    final puntos = _puntos;
    final vuelo = _ms - _T.quieto;
    var sombra = quieto || a == null || vuelo < 0
        ? null
        : sombraDelVuelo(a, curvaSeno(tramo(vuelo, 0, 1300)));
    Rect? fondo = Offset.zero & tamano;
    var radio = 0.0;
    EscenaDelLogo? estrella = quieta;
    var cruces = const <CruzDeLaSubida>[];
    var revelado = 0.0;
    final respuesta = _respuestaEn;
    final destino = _destino;
    // Sin movimiento no hay subida: el recibimiento sigue entero debajo de la
    // franja y la conversación que aparecen encima (RF-BIEN-15).
    if (respuesta != null && !quieto) {
      final desde = _ms - respuesta;
      final lineal = tramo(desde, _T.inicioDeLaSubida, _T.finDeLaSubida);
      final t = Curves.easeInOutCubic.transform(lineal);
      // El fondo de pantalla completa se recoge hasta la franja y sus
      // esquinas inferiores pasan de 0 a 26 dp (RF-BIEN-4).
      fondo = Rect.fromLTWH(
        0,
        0,
        tamano.width,
        mezcla(tamano.height, CabeceraConSello.alto(context), t),
      );
      radio = 26 * t;
      if (sombra != null) {
        final s = sombra;
        sombra = (
          centro: s.centro,
          ancho: s.ancho,
          opacidad: s.opacidad * (1 - tramo(desde, _T.inicioDelSalto, 310)),
        );
      }
      if (_selloPosado) {
        // La franja y el sello de debajo ya son iguales a lo que se pintaba,
        // así que no se pinta nada encima del sello real.
        fondo = null;
        estrella = null;
      } else if (destino != null) {
        estrella = _enLaSubida(quieta, destino, t);
        cruces = <CruzDeLaSubida>[
          for (var i = 0; i < quieta.cruces.length && i < 2; i++)
            _cruzEnLaSubida(quieta, i, destino, lineal),
        ];
        revelado = tramo(lineal, 0.55, 1);
      }
    }
    return _PintorDelRecibimiento(
      fondo: fondo,
      color: Color.lerp(naranjaDelSplash, franja, cambio)!,
      radio: radio,
      estrella: estrella,
      estrellaDebajo: debajo,
      opacidadDeLaEstrella: debajo == null ? 1 : _cruceDeLaEstrella,
      cruces: cruces,
      sombra: sombra,
      estela: quieto || a == null || puntos == null
          ? const <({Offset centro, double opacidad})>[]
          : estelaDelVuelo(puntos, a, vuelo),
      particulas: quieto || a == null
          ? const <({Offset centro, double radio, double opacidad})>[]
          : particulasDelAterrizaje(a, _ms - _T.aterrizaje),
      ulima: _selloPosado ? null : destino?.ulima,
      origenDeUlima: destino?.origenDeUlima,
      revelado: revelado,
    );
  }

  /// La estrella va de su pose a su lugar en el sello, se achica hasta
  /// 1,22 × 26 dp de punta a punta y gira 45°, que por su simetría de orden
  /// ocho se ve igual (RF-BIEN-4). Los «++» se pintan aparte.
  EscenaDelLogo _enLaSubida(EscenaDelLogo quieta, PiezasDelSello d, double t) =>
      quieta.copyWith(
        centro: Offset.lerp(quieta.centro, d.estrella, t),
        radio: mezcla(quieta.radio, d.radio, t),
        giro: quieta.giro + 45 * grado * t,
        cruces: const <CruzEnEscena>[],
      );

  /// Cada «+» sale al 22 % del tiempo, el segundo un 6 % después, salta en un
  /// arco de 18 dp y cae tras «ULIMA», sesgado −12° como la cursiva del
  /// sello (RF-BIEN-4).
  CruzDeLaSubida _cruzEnLaSubida(
    EscenaDelLogo quieta,
    int i,
    PiezasDelSello d,
    double lineal,
  ) {
    final cruz = quieta.cruces[i];
    final avance = Curves.easeInOutCubic.transform(
      tramo(lineal, 0.22 + 0.06 * i, 1),
    );
    final desde = quieta.aVista(cruz.centro);
    return CruzDeLaSubida(
      centro:
          Offset.lerp(desde, d.mas[i], avance)! -
          Offset(0, 18 * math.sin(math.pi * avance)),
      largo: mezcla(
        LogoGeometria.largoDeCruz * quieta.unidad * cruz.escala,
        d.largoDeLosMas,
        avance,
      ),
      sesgo: SelloDelLogo.inclinacionDeLosMas * avance,
    );
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: CustomPaint(
          key: Recibimiento.claveDelFondo,
          painter: _pintor(context),
        ),
      ),
      if (_aterrizaje != null &&
          _ms >= (_sinMovimiento ? _S.ulises : _T.quieto))
        _ulises(),
      if (_conTarjeta) ..._tarjetaYBotones(context),
    ],
  );

  Widget _ulises() {
    final a = _aterrizaje!;
    final respuesta = _respuestaEn;
    PoseDeUlises pose;
    if (_sinMovimiento) {
      // Ulises no vuela. Aparece en su lugar con un fundido de 160 ms, y al
      // responder pasa a su avatar con uno de 140 ms (RF-BIEN-15).
      pose = PoseDeUlises(
        centro: a,
        lado: 70,
        opacidad: respuesta == null
            ? tramo(_ms, _S.ulises, _S.ulises + _S.fundidoDeUlises)
            : 1 - tramo(_ms - respuesta, 0, _S.fundidoDelAvatar),
      );
    } else {
      pose = _ms < _T.aterrizaje
          ? ulisesEnVuelo(_puntos!, a, _ms - _T.quieto)
          : _ms < _T.finDelRebote
          ? ulisesAlAterrizar(a, _ms - _T.aterrizaje)
          : ulisesAsiente(a, _ms - _T.finDelRebote);
      if (respuesta != null) {
        pose = ulisesSalta(
          a,
          widget.avatar.center,
          _ms - respuesta - _T.inicioDelSalto,
        );
      }
    }
    return Positioned(
      left: pose.centro.dx - pose.lado / 2,
      top: pose.centro.dy - pose.lado / 2,
      // Una capa aislada, así que el vuelo no repinta el resto (RF-BIEN-18).
      child: RepaintBoundary(
        child: IgnorePointer(
          child: ExcludeSemantics(
            child: Transform.rotate(
              angle: pose.giro,
              child: Transform.scale(
                scaleX: pose.escalaX,
                scaleY: pose.escalaY,
                child: Opacity(
                  opacity: pose.opacidad.clamp(0.0, 1.0),
                  child: ClipOval(
                    key: Recibimiento.claveDeUlises,
                    child: Image.asset(
                      'assets/images/ulises_chatbot.png',
                      width: pose.lado,
                      height: pose.lado,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _tarjetaYBotones(BuildContext context) {
    final m = _medidas!;
    final b = Theme.brightnessOf(context);
    final respuesta = _respuestaEn;
    final quieto = _sinMovimiento;
    final lector = _conLector;
    // Al responder, la tarjeta y los botones se van en 280 ms. Tras un toque
    // en reposo, hasta el cuadro siguiente siguen enteros. Sin movimiento
    // siguen enteros debajo de la conversación que aparece encima.
    final salida = _fase != _Fase.subida || respuesta == null || quieto
        ? 1.0
        : 1 - tramo(_ms - respuesta, 0, 280);
    // Con lector están desde el relevo. Sin movimiento, fundidos de 180 ms
    // sin desplazamiento (RF-BIEN-15 y RF-BIEN-16).
    final aparece = lector
        ? 1.0
        : tramo(
            _ms,
            _msDeLaTarjeta,
            _msDeLaTarjeta + (quieto ? _S.fundido : 280),
          );
    final entra = _rebote.transform(
      tramo(_ms, _T.finDelRebote, _T.finDelRebote + 360),
    );
    final botones = lector
        ? 1.0
        : tramo(
            _ms,
            _msDeLosBotones,
            _msDeLosBotones + (quieto ? _S.fundido : 400),
          );
    final conForma = !quieto && !lector;
    return <Widget>[
      Positioned(
        left: m.tarjeta.left,
        top: m.tarjeta.top,
        width: m.tarjeta.width,
        child: IgnorePointer(
          child: Opacity(
            opacity: (aparece * salida).clamp(0.0, 1.0),
            // Entra en 360 ms con un leve rebote, desde 8 dp más abajo y al
            // 96 %.
            child: Transform.translate(
              offset: Offset(0, conForma ? 8 * (1 - entra) : 0),
              child: Transform.scale(
                scale: conForma ? 0.96 + 0.04 * entra : 1,
                alignment: const Alignment(-1, -0.2),
                child: const _Tarjeta(key: Recibimiento.claveDeLaTarjeta),
              ),
            ),
          ),
        ),
      ),
      if (_ms >= _msDeLosBotones)
        Positioned(
          left: m.botones.left,
          width: m.botones.width,
          top: m.botones.top,
          child: IgnorePointer(
            ignoring: _fase != _Fase.saludo,
            child: Opacity(
              opacity: (botones * salida).clamp(0.0, 1.0),
              // Entran en 400 ms desde 18 dp más abajo (B-2).
              child: Transform.translate(
                offset: Offset(
                  0,
                  conForma
                      ? 18 * (1 - Curves.easeOutCubic.transform(botones))
                      : 0,
                ),
                child: Column(
                  key: Recibimiento.claveDeLosBotones,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Boton(
                      texto: _Textos.siEntrar,
                      fondo: MaterialTheme.bienvenidaEntrarFondo(b),
                      tinta: MaterialTheme.bienvenidaEntrarTinta(b),
                      alTocar: () => _responder(true),
                    ),
                    const SizedBox(height: 10),
                    _Boton(
                      texto: _Textos.soyNuevo,
                      fondo: MaterialTheme.bienvenidaNuevoFondo(b),
                      tinta: MaterialTheme.bienvenidaNuevoTinta(b),
                      borde: MaterialTheme.bienvenidaNuevoBorde(b),
                      alTocar: () => _responder(false),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    ];
  }
}

/// La tarjeta del saludo, con su pico hacia Ulises (RF-BIEN-2).
class _Tarjeta extends StatefulWidget {
  const _Tarjeta({super.key});

  @override
  State<_Tarjeta> createState() => _TarjetaState();
}

class _TarjetaState extends State<_Tarjeta> {
  @override
  void initState() {
    super.initState();
    // Con lector, el foco pasa a la tarjeta y después a los dos botones
    // (RF-BIEN-16).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !MediaQuery.accessibleNavigationOf(context)) return;
      context.findRenderObject()?.sendSemanticsEvent(
        const FocusSemanticEvent(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);
    final fondo = MaterialTheme.bienvenidaSaludo(b);
    return Semantics(
      container: true,
      label: '${_Textos.saludo.replaceAll(' 👋', '')}. ${_Textos.pregunta}',
      excludeSemantics: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // El pico, un cuadrado de 14 dp girado 45° que asoma 5 dp por la
          // izquierda a 17 dp del borde superior, hacia Ulises.
          Positioned(
            left: -5,
            top: 17,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: fondo,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const SizedBox.square(dimension: 14),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: fondo,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(13, 9, 13, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _Textos.saludo,
                    style: _RecibimientoState._estiloSaludo.copyWith(
                      color: MaterialTheme.bienvenidaSaludoSub(b),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _Textos.pregunta,
                    style: _RecibimientoState._estiloPregunta.copyWith(
                      color: MaterialTheme.bienvenidaSaludoTinta(b),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// «Sí, entrar», relleno, o «Soy nuevo», con borde (RF-BIEN-2 y B-3).
class _Boton extends StatelessWidget {
  const _Boton({
    required this.texto,
    required this.fondo,
    required this.tinta,
    required this.alTocar,
    this.borde,
  });

  final String texto;
  final Color fondo;
  final Color tinta;
  final Color? borde;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => AnilloDeFoco(
    radio: BorderRadius.circular(16),
    child: Semantics(
      button: true,
      label: texto,
      // Con excludeSemantics, la acción del InkWell no llega al lector, así
      // que el botón la declara aquí (RF-BIEN-16).
      onTap: alTocar,
      excludeSemantics: true,
      // El borde de 1,5 dp va dentro de los 50 dp, como en la maqueta, así
      // que se pinta encima y no suma al alto.
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: borde == null ? null : Border.all(color: borde!, width: 1.5),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            // Cada uno se oscurece un 7 % al tocarlo (B-3).
            highlightColor: Colors.black.withValues(alpha: 0.07),
            splashColor: Colors.transparent,
            onTap: alTocar,
            child: Ink(
              decoration: BoxDecoration(
                color: fondo,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 50),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Text(
                      texto,
                      textAlign: TextAlign.center,
                      style: _RecibimientoState._estiloBoton.copyWith(
                        color: tinta,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Un «+» de la subida, en dp de la vista.
class CruzDeLaSubida {
  const CruzDeLaSubida({
    required this.centro,
    required this.largo,
    required this.sesgo,
  });

  final Offset centro;
  final double largo;

  /// Un sesgo horizontal, como el de los «++» del sello, y no un giro.
  final double sesgo;
}

/// El fondo, la sombra, la estela, las partículas, la estrella, los «++» y
/// la revelación de «ULIMA», en un solo pintor.
class _PintorDelRecibimiento extends CustomPainter {
  _PintorDelRecibimiento({
    required this.fondo,
    required this.color,
    required this.radio,
    required this.estrella,
    required this.estrellaDebajo,
    required this.opacidadDeLaEstrella,
    required this.cruces,
    required this.sombra,
    required this.estela,
    required this.particulas,
    required this.ulima,
    required this.origenDeUlima,
    required this.revelado,
  });

  /// Null cuando el sello real ya se ve en su lugar.
  final Rect? fondo;
  final Color color;
  final double radio;
  final EscenaDelLogo? estrella;

  /// Con reducir movimiento, la estrella del centro, entera debajo mientras
  /// la nueva aparece encima con [opacidadDeLaEstrella] (RF-BIEN-15).
  final EscenaDelLogo? estrellaDebajo;
  final double opacidadDeLaEstrella;
  final List<CruzDeLaSubida> cruces;
  final ({Offset centro, double ancho, double opacidad})? sombra;
  final List<({Offset centro, double opacidad})> estela;
  final List<({Offset centro, double radio, double opacidad})> particulas;
  final TextPainter? ulima;
  final Offset? origenDeUlima;
  final double revelado;

  @override
  void paint(Canvas canvas, Size size) {
    final f = fondo;
    if (f != null) {
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          f,
          bottomLeft: Radius.circular(radio),
          bottomRight: Radius.circular(radio),
        ),
        Paint()..color = color,
      );
    }
    final s = sombra;
    if (s != null && s.opacidad > 0) {
      canvas.drawOval(
        Rect.fromCenter(
          center: s.centro,
          width: s.ancho,
          height: s.ancho * 0.22,
        ),
        Paint()..color = Colors.black.withValues(alpha: s.opacidad),
      );
    }
    final blanco = Paint()..isAntiAlias = true;
    for (final p in estela) {
      blanco.color = Colors.white.withValues(alpha: p.opacidad);
      canvas.drawCircle(p.centro, radioDeLaEstela, blanco);
    }
    for (final p in particulas) {
      blanco.color = Colors.white.withValues(alpha: p.opacidad);
      canvas.drawCircle(p.centro, p.radio, blanco);
    }
    final abajo = estrellaDebajo;
    if (abajo != null) pintarEscena(canvas, abajo);
    final e = estrella;
    if (e != null) {
      if (opacidadDeLaEstrella < 1) {
        canvas.saveLayer(
          null,
          Paint()..color = Color.fromRGBO(0, 0, 0, opacidadDeLaEstrella),
        );
        pintarEscena(canvas, e);
        canvas.restore();
      } else {
        pintarEscena(canvas, e);
      }
    }
    if (cruces.isNotEmpty) {
      final pintura = Paint()
        ..isAntiAlias = true
        ..color = Colors.white;
      final (h, v) = LogoGeometria.barrasDeCruz();
      for (final c in cruces) {
        canvas.save();
        canvas.translate(c.centro.dx, c.centro.dy);
        canvas.skew(math.tan(c.sesgo), 0);
        canvas.scale(c.largo / LogoGeometria.largoDeCruz);
        canvas.drawRect(h, pintura);
        canvas.drawRect(v, pintura);
        canvas.restore();
      }
    }
    final texto = ulima;
    final origen = origenDeUlima;
    if (texto != null && origen != null && revelado > 0) {
      // «ULIMA» se revela de izquierda a derecha desde el 55 % de la subida.
      canvas.save();
      canvas.clipRect(
        Rect.fromLTWH(
          origen.dx - 4,
          origen.dy - 4,
          texto.width * revelado + 4,
          texto.height + 8,
        ),
      );
      texto.paint(canvas, origen);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PintorDelRecibimiento oldDelegate) => true;
}
