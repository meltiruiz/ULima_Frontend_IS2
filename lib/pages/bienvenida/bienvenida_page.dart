// lib/pages/bienvenida/bienvenida_page.dart
// La página de /login con la bienvenida de Ulises (RF-BIEN-1 a RF-BIEN-17).
// Cada montaje es una visita. El primer cuadro sale solo de los argumentos de
// la ruta, que son la pose del splash, el motivo o ninguno, y avisa a la capa
// del arranque cuando lo pinta (RF-SPL-21). Después pinta el estado del
// controlador, con el ritmo del revelador.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../components/logo/escena_del_logo.dart';
import '../../components/logo/sello_del_logo.dart';
import '../../configs/themes.dart';
import '../../domain/bienvenida/bienvenida_turnos.dart';
import '../../services/session_navigation.dart';
import '../home/home_page.dart' show abrirEnHorario;
import '../specialty_test/widgets/result_view.dart' show PintorDelConfeti;
import '../splash/capa_de_arranque.dart';
import '../splash/paso_al_horario.dart' show DatosDelPaso;
import 'bienvenida_controller.dart';
import 'conversacion.dart';
import 'widgets/burbujas.dart';
import 'widgets/compositor.dart';
import 'widgets/compositor_del_test.dart';
import 'widgets/franja_con_sello.dart';
import 'widgets/recibimiento.dart';
import 'widgets/revelador.dart';

class BienvenidaPage extends StatefulWidget {
  const BienvenidaPage({super.key});

  @override
  State<BienvenidaPage> createState() => _BienvenidaPageState();
}

class _BienvenidaPageState extends State<BienvenidaPage>
    with TickerProviderStateMixin {
  late final BienvenidaController _c = Get.find<BienvenidaController>();
  late final int _visita;
  final Revelador _revelador = Revelador();
  final ScrollController _desplazamiento = ScrollController();
  late final AnimationController _latido = AnimationController(
    vsync: this,
    duration: duracionDelLatido,
  );
  final ValueNotifier<List<double>?> _rombos = ValueNotifier<List<double>?>(
    null,
  );
  late final Ticker _pulso = createTicker(_alPulsar);
  late final AnimationController _confeti = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  final List<Worker> _trabajos = <Worker>[];
  Timer? _finDeLaPildora;
  final ValueNotifier<EstadoDeLaPildora?> _pildora =
      ValueNotifier<EstadoDeLaPildora?>(null);

  bool _leida = false;
  PoseDelLogo? _pose;
  MotivoDeLlegada? _motivo;

  /// El sello de la franja, destino de la subida del recibimiento.
  final GlobalKey _claveDelSello = GlobalKey();
  bool _recibimientoTerminado = false;

  /// Mientras el logo sube, el recibimiento dibuja el sello y a Ulises, así
  /// que los de la conversación esperan a que se posen.
  bool _selloVisible = true;
  bool _avatarVisible = true;

  final GlobalKey _claveDeLaConversacion = GlobalKey();
  final GlobalKey _claveDelUltimoAvatar = GlobalKey();
  bool _pasoEmpezado = false;

  /// Sin movimiento, la franja con el sello y la conversación aparecen encima
  /// del recibimiento en 220 ms (RF-BIEN-15). Fuera de ese cruce vale 1.
  late final AnimationController _cruceDeLaSubida = AnimationController(
    vsync: this,
    duration: Duration(
      milliseconds: TiemposSinMovimiento.cruceDeLaSubida.round(),
    ),
    value: 1,
    // Es el fundido de reducir movimiento, así que no se acorta con él.
    animationBehavior: AnimationBehavior.preserve,
  );
  bool _cruceSinMovimiento = false;

  /// La primera burbuja nueva de Ulises, a la que va el foco del lector
  /// (RF-BIEN-16). Las entradas que el revelador suelta antes de un mismo
  /// cuadro son un solo grupo, así que [_visiblesAntes] se actualiza después
  /// del cuadro.
  int _visiblesAntes = 0;
  int? _idAEnfocar;
  bool _grupoAbierto = false;

  /// Sin movimiento, el cursor del campo no parpadea (RF-BIEN-15). El SDK
  /// solo lo permite con un interruptor global, así que las páginas montadas
  /// que lo piden se cuentan, y la primera guarda el valor de antes, que
  /// vuelve cuando sale la última. Al volver del «¿Olvidaste tu
  /// contraseña?» conviven dos bienvenidas.
  static int _cursoresQuietos = 0;
  static bool _cursorDeAntes = false;
  bool _pideCursorQuieto = false;

  bool get _sinMovimiento => MediaQuery.disableAnimationsOf(context);
  bool get _conLector => MediaQuery.accessibleNavigationOf(context);

  @override
  void initState() {
    super.initState();
    _visita = _c.nuevaVisita();
    _trabajos.addAll(<Worker>[
      ever<int>(_c.latidos, (_) => _latir()),
      ever<bool>(_c.enviando, _alCambiarElEnvio),
      ever<EstadoDeLaPildora?>(_c.pildora, _alCambiarLaPildora),
      ever<List<EntradaDeLaConversacion>>(_c.entradas, (_) => _sincronizar()),
      ever<TurnoDeLaBienvenida?>(_c.turno, (_) => _sincronizar()),
      ever<int>(_c.visitaEmpezada, (_) => _sincronizar()),
      ever<int>(_c.confeti, (_) {
        if (!mounted) return;
        // La vibración va siempre, como en el test en su pantalla, y el
        // confeti no va con reducir movimiento (RF-TEST-8 y RF-TEST-13).
        unawaited(HapticFeedback.heavyImpact());
        if (_sinMovimiento) return;
        unawaited(_confeti.forward(from: 0));
      }),
    ]);
    _revelador.addListener(_alRevelar);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // El primer cuadro ya se pintó igual al último de la intro.
      CapaDeArranque.avisarPrimerCuadroDeLaBienvenida();
      unawaited(_c.empezarVisita(_visita, motivo: _motivo));
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pedirElCursorQuieto(_sinMovimiento);
    if (_leida) return;
    _leida = true;
    final argumentos = ModalRoute.of(context)?.settings.arguments;
    if (argumentos is Map) {
      final pose = argumentos[argumentoDePose];
      final motivo = argumentos[argumentoDeMotivo];
      _pose = pose is PoseDelLogo ? pose : null;
      _motivo = motivo is MotivoDeLlegada ? motivo : null;
    }
    // Sin un motivo, la conversación espera al recibimiento, que la suelta
    // cuando Ulises se posa en su avatar (RF-BIEN-2).
    _revelador.retenido = _motivo == null;
    // Sin pose, el splash no precargó a Ulises (RF-BIEN-3).
    if (_pose == null) {
      unawaited(
        precacheImage(
          const AssetImage('assets/images/ulises_chatbot.png'),
          context,
        ).catchError((Object _) {}),
      );
    }
  }

  void _pedirElCursorQuieto(bool pide) {
    if (pide == _pideCursorQuieto) return;
    _pideCursorQuieto = pide;
    if (pide) {
      if (_cursoresQuietos++ == 0) {
        _cursorDeAntes = EditableText.debugDeterministicCursor;
      }
      EditableText.debugDeterministicCursor = true;
    } else if (--_cursoresQuietos == 0) {
      EditableText.debugDeterministicCursor = _cursorDeAntes;
    }
  }

  bool get _atendida => _c.visitaEmpezada.value == _visita;

  void _sincronizar() {
    if (!mounted || !_atendida) return;
    final turno = _c.turno.value;
    _revelador.actualizar(
      entradas: _c.entradas,
      hayCompositor: turno != null && _tieneCompositor(turno),
      conLector: _conLector,
      pausaDelCompositor: turno == TurnoDeLaBienvenida.pasoAlHorario
          ? Ritmo.antesDelPaso
          : Ritmo.antesDelCompositor,
    );
  }

  /// Con «Si no cabe», el recibimiento tiene sus respuestas rápidas (B-28).
  bool _tieneCompositor(TurnoDeLaBienvenida t) => switch (t) {
    TurnoDeLaBienvenida.recibimiento => _c.saludoEnLaConversacion.value,
    TurnoDeLaBienvenida.llegadaConSesion => false,
    _ => true,
  };

  void _alRevelar() {
    if (!mounted) return;
    final visibles = _revelador.visibles;
    final entradas = _c.entradas;
    if (_conLector && visibles > _visiblesAntes) {
      final nuevas = entradas.sublist(
        _visiblesAntes.clamp(0, entradas.length),
        visibles.clamp(0, entradas.length),
      );
      _idAEnfocar =
          nuevas.whereType<BurbujaDeUlises>().firstOrNull?.id ?? _idAEnfocar;
    }
    if (!_grupoAbierto) {
      _grupoAbierto = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _grupoAbierto = false;
        if (mounted) _visiblesAntes = _revelador.visibles;
      });
    }
    setState(() {});
    // La conversación se desplaza en 450 ms hasta el final, o salta con
    // reducir movimiento (RF-BIEN-5 y RF-BIEN-15).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_desplazamiento.hasClients) return;
      final fin = _desplazamiento.position.maxScrollExtent;
      if (_sinMovimiento) {
        _desplazamiento.jumpTo(fin);
      } else {
        unawaited(
          _desplazamiento.animateTo(
            fin,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
          ),
        );
      }
    });
    // El paso empieza cuando el revelador abre su turno, 900 ms después de
    // E3, en el cuadro siguiente, así que la imagen sale ya pintada.
    if (_revelador.compositorVisible &&
        _c.turno.value == TurnoDeLaBienvenida.pasoAlHorario) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _empezarElPaso());
    }
  }

  /// Entrega a la capa la franja, el sello, a Ulises en su último avatar y
  /// una imagen de la conversación, navega a /home en Horario sin transición
  /// y reinicia la conversación (RF-BIEN-11).
  void _empezarElPaso() {
    if (_pasoEmpezado || !mounted) return;
    _pasoEmpezado = true;
    final datos = _datosDelPaso();
    final entregado =
        datos != null && CapaDeArranque.empezarElPasoAlHorario(datos);
    // Si la capa no lo toma, la imagen y el texto medido se descartan aquí.
    if (!entregado) datos?.desechar();
    offAllSinTransicion('/home', arguments: abrirEnHorario);
    _c.pasoHecho();
  }

  DatosDelPaso? _datosDelPaso() {
    final sello = PiezasDelSello.medir(_claveDelSello);
    // La franja se mide con el contexto del sello, que está bajo el Material.
    final contextoDelSello = _claveDelSello.currentContext;
    final caja =
        _claveDeLaConversacion.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (sello == null ||
        contextoDelSello == null ||
        caja == null ||
        !caja.hasSize) {
      sello?.desechar();
      return null;
    }
    final b = Theme.brightnessOf(context);
    final avatar =
        _claveDelUltimoAvatar.currentContext?.findRenderObject() as RenderBox?;
    return DatosDelPaso(
      franja: Rect.fromLTWH(
        0,
        0,
        MediaQuery.sizeOf(context).width,
        CabeceraConSello.alto(contextoDelSello),
      ),
      colorDeLaFranja: MaterialTheme.bienvenidaFranja(b),
      sello: sello,
      conversacion: _imagen(caja),
      lugarDeLaConversacion: caja.localToGlobal(Offset.zero) & caja.size,
      avatar: avatar == null || !avatar.hasSize
          ? null
          : avatar.localToGlobal(Offset.zero) & avatar.size,
      colorDeFondo: MaterialTheme.pageBg(b),
      colorDeLaPagina: Theme.of(context).colorScheme.surface,
    );
  }

  /// Si la plataforma no puede capturar la imagen, la capa pinta solo el
  /// fondo de la conversación, que se desvanece igual.
  ui.Image? _imagen(RenderRepaintBoundary caja) {
    try {
      return caja.toImageSync(
        pixelRatio: MediaQuery.devicePixelRatioOf(context),
      );
    } on Object {
      return null;
    }
  }

  void _latir() {
    if (!mounted || _sinMovimiento) return;
    unawaited(_latido.forward(from: 0));
  }

  Duration _inicioDelPulso = Duration.zero;
  Duration _ahoraDelPulso = Duration.zero;
  List<double>? _desdeAlApagar;

  void _alCambiarElEnvio(bool enviando) {
    if (!mounted || _sinMovimiento) return;
    // Un Ticker detenido vuelve a contar desde cero al empezar otra vez, así
    // que el pulso de un reenvío empieza en el rombo de arriba (RF-BIEN-4).
    if (!_pulso.isActive) _ahoraDelPulso = Duration.zero;
    _inicioDelPulso = _ahoraDelPulso;
    _desdeAlApagar = enviando ? null : _rombos.value;
    if (!_pulso.isActive) unawaited(_pulso.start());
  }

  /// El pulso recorre los ocho rombos mientras se envía, y con cualquier
  /// desenlace vuelven a la opacidad plena en 200 ms (RF-BIEN-4).
  void _alPulsar(Duration t) {
    _ahoraDelPulso = t;
    final ms = (t - _inicioDelPulso).inMicroseconds / 1000;
    if (_c.enviando.value) {
      final p = posicionDelPulso(ms);
      _rombos.value = <double>[
        for (var k = 0; k < 8; k++) opacidadDelRombo(k, p),
      ];
      return;
    }
    final desde = _desdeAlApagar;
    final avance = (ms / 200).clamp(0.0, 1.0);
    if (desde == null || avance >= 1) {
      _rombos.value = null;
      _pulso.stop();
      return;
    }
    _rombos.value = <double>[for (final o in desde) o + (1 - o) * avance];
  }

  void _alCambiarLaPildora(EstadoDeLaPildora? estado) {
    _finDeLaPildora?.cancel();
    _pildora.value = estado;
    // «Cuenta creada» se va 900 ms después (RF-BIEN-8).
    if (estado == EstadoDeLaPildora.creada) {
      _finDeLaPildora = Timer(const Duration(milliseconds: 900), () {
        _pildora.value = null;
      });
    }
  }

  @override
  void dispose() {
    for (final w in _trabajos) {
      w.dispose();
    }
    _finDeLaPildora?.cancel();
    _revelador
      ..removeListener(_alRevelar)
      ..dispose();
    _desplazamiento.dispose();
    _latido.dispose();
    _confeti.dispose();
    _pulso.dispose();
    _rombos.dispose();
    _pildora.dispose();
    _cruceDeLaSubida.dispose();
    _pedirElCursorQuieto(false);
    _c.terminarVisita(_visita);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Arriba siempre hay #E77330, la franja naranja o la #262626
      // (RF-BIEN-17).
      value: SystemUiOverlayStyle.light,
      child: Obx(
        () => PopScope(
          canPop: _atendida && _c.atrasSaleDeLaApp,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _c.atras();
          },
          child: Scaffold(
            backgroundColor: MaterialTheme.pageBg(b),
            resizeToAvoidBottomInset: true,
            // Un solo grupo del autocompletado para todos los turnos, que
            // vive lo que vive la página, así que E1 y E2 comparten el mismo
            // aunque el compositor cambie. Al salir no guarda nada, porque
            // solo la sesión puesta cierra el contexto con
            // finishAutofillContext (RF-BIEN-6).
            body: AutofillGroup(
              onDisposeAction: AutofillContextAction.cancel,
              // Con el contexto del cuerpo, bajo el Material del Scaffold,
              // así que las medidas del texto usan el estilo de la app y no el
              // de error de MaterialApp (RF-BIEN-2 y RF-BIEN-16).
              child: Builder(builder: _cuerpo),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cuerpo(BuildContext context) {
    final atendida = _atendida;
    // Sin un motivo, el recibimiento tapa la conversación desde el primer
    // cuadro, que sale solo de los argumentos (RF-BIEN-1 a RF-BIEN-3).
    final conRecibimiento = _motivo == null && !_recibimientoTerminado;
    // Las claves conservan el estado de los dos al cambiar de orden.
    final conversacion = KeyedSubtree(
      key: const ValueKey<String>('conversacion'),
      child: FadeTransition(
        opacity: _cruceDeLaSubida,
        child: _conversacion(context, atendida: atendida),
      ),
    );
    final recibimiento = conRecibimiento
        ? Positioned.fill(
            key: const ValueKey<String>('recibimiento'),
            child: _recibimiento(context, atendida: atendida),
          )
        : null;
    // Sin movimiento, la franja y la conversación aparecen encima del
    // recibimiento, que sigue entero debajo hasta quedar cubierto.
    final encima = _cruceSinMovimiento;
    return Stack(
      children: [
        if (encima && recibimiento != null) recibimiento,
        conversacion,
        Positioned(
          top: CabeceraConSello.alto(context),
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: ClipRect(
              child: AnimatedBuilder(
                animation: _confeti,
                builder: (context, _) => _confeti.isAnimating
                    ? CustomPaint(painter: PintorDelConfeti(_confeti.value))
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        if (!encima && recibimiento != null) recibimiento,
        Positioned(
          top: CabeceraConSello.alto(context) + 8,
          left: 0,
          right: 0,
          child: Center(
            child: ValueListenableBuilder<EstadoDeLaPildora?>(
              valueListenable: _pildora,
              builder: (context, estado, _) => estado == null
                  ? const SizedBox.shrink()
                  : PildoraDelRegistro(estado: estado),
            ),
          ),
        ),
      ],
    );
  }

  Widget _recibimiento(BuildContext context, {required bool atendida}) =>
      Recibimiento(
        pose: _pose ?? _poseDeReposo(context),
        // Mientras el controlador no atiende la visita, todavía no se sabe
        // si hay una sesión puesta (RF-BIEN-21).
        conSesion: atendida ? _c.conSesion : null,
        claveDelSello: _claveDelSello,
        avatar: _avatar(context),
        alResponder: (yaUsa) => _c.responderAlSaludo(yaUsa: yaUsa),
        alAterrizarConSesion: _c.ulisesAterrizoConSesion,
        alSaludarEnLaConversacion: _c.saludarEnLaConversacion,
        alSubir: () {
          // La conversación ya trae su primer grupo, sin esperar el ritmo.
          _sincronizar();
          _revelador.mostrarYa(_primerGrupoConRespuesta());
          setState(() {
            // Sin movimiento, el sello y el avatar se ven enteros en la
            // franja y la conversación que aparecen encima (RF-BIEN-15).
            _selloVisible = _sinMovimiento;
            _avatarVisible = _sinMovimiento;
            _cruceSinMovimiento = _sinMovimiento;
          });
          if (_sinMovimiento) unawaited(_cruceDeLaSubida.forward(from: 0));
        },
        alPosarseElSello: () {
          setState(() => _selloVisible = true);
          _latir();
        },
        alTerminar: () {
          setState(() {
            _avatarVisible = true;
            _recibimientoTerminado = true;
            _cruceSinMovimiento = false;
          });
          // 650 ms después empieza el primer turno de la rama elegida.
          _revelador.retenido = false;
        },
      );

  /// El primer grupo de Ulises y, si la hay, la respuesta del alumno. Las
  /// entradas que siguen esperan su pausa (RF-BIEN-2 y RF-BIEN-21).
  int _primerGrupoConRespuesta() {
    final entradas = _c.entradas;
    final respuesta = entradas.indexWhere((e) => e is RespuestaDelAlumno);
    if (respuesta >= 0) return respuesta + 1;
    return entradas.takeWhile((e) => e is BurbujaDeUlises).length.clamp(0, 2);
  }

  /// El avatar de 40 dp del primer grupo, bajo la franja, con el relleno de
  /// la lista y el de la primera burbuja.
  Rect _avatar(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final columna = math.min(ancho, 600.0);
    return Rect.fromLTWH(
      (ancho - columna) / 2 + 12,
      CabeceraConSello.alto(context) + 8 + 12,
      40,
      40,
    );
  }

  PoseDelLogo _poseDeReposo(BuildContext context) {
    final vista = MediaQuery.sizeOf(context);
    final pantalla = View.of(context).display;
    // En web la estrella se centra en la vista, porque display.size es el
    // del monitor (RF-BIEN-3).
    final centro = kIsWeb
        ? vista.center(Offset.zero)
        : centroDelNativo(vista, pantalla.size / pantalla.devicePixelRatio);
    return EscenaDelLogo.reposo(centro: centro, radio: radioDelNativo).pose;
  }

  Widget _conversacion(BuildContext context, {required bool atendida}) {
    final visibles = atendida ? _revelador.visibles : 0;
    final entradas = _c.entradas;
    final turno = _c.turno.value;
    final primerIdDeUlises = entradas
        .whereType<BurbujaDeUlises>()
        .map((e) => e.id)
        .firstOrNull;
    final cuantas = visibles.clamp(0, entradas.length);
    // El primer avatar del último grupo de Ulises, de donde sale a volar en
    // el paso al horario (RF-BIEN-11).
    var ultimoAvatar = -1;
    for (var i = 0; i < cuantas; i++) {
      if (entradas[i] is BurbujaDeUlises &&
          (i == 0 || entradas[i - 1] is! BurbujaDeUlises)) {
        ultimoAvatar = i;
      }
    }
    // El compositor mide hasta el 60 % del alto sobre el teclado (RF-BIEN-5).
    return LayoutBuilder(
      builder: (context, limites) => Column(
        children: [
          FranjaConSello(
            latido: _latido,
            rombos: _rombos,
            claveDelSello: _claveDelSello,
            selloVisible: _selloVisible,
          ),
          Expanded(
            child: RepaintBoundary(
              key: _claveDeLaConversacion,
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: ListView.builder(
                          controller: _desplazamiento,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                          itemCount: cuantas,
                          itemBuilder: (context, i) {
                            final entrada = entradas[i];
                            final primerGrupo = _enElPrimerGrupo(
                              entradas,
                              i,
                              primerIdDeUlises,
                            );
                            return EntradaView(
                              key: ValueKey<int>(entrada.id),
                              entrada: entrada,
                              anterior: i > 0 ? entradas[i - 1] : null,
                              primerGrupo: primerGrupo,
                              ocultarAvatar: primerGrupo && !_avatarVisible,
                              claveDelAvatar: i == ultimoAvatar
                                  ? _claveDelUltimoAvatar
                                  : null,
                              enfocar: entrada.id == _idAEnfocar,
                              conMovimiento: !_sinMovimiento,
                              resultado: (context, r) =>
                                  ResultadoEnLaConversacion(c: _c, entrada: r),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  if (atendida && turno != null && _revelador.compositorVisible)
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: _CompositorAnimado(
                          key: ValueKey<TurnoDeLaBienvenida>(turno),
                          conMovimiento: !_sinMovimiento,
                          altoDisponible: limites.maxHeight,
                          child: compositorDelTurno(context, _c, turno),
                        ),
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

  /// El primer grupo de Ulises es el de las burbujas desde la primera hasta
  /// la primera respuesta del alumno.
  bool _enElPrimerGrupo(
    List<EntradaDeLaConversacion> entradas,
    int i,
    int? primerId,
  ) {
    if (primerId == null) return false;
    for (var j = 0; j <= i; j++) {
      if (entradas[j] is RespuestaDelAlumno) return false;
    }
    return true;
  }
}

/// El compositor entra en 300 ms, subiendo 8 dp, o con un fundido de 200 ms
/// con reducir movimiento (RF-BIEN-5 y RF-BIEN-15).
class _CompositorAnimado extends StatelessWidget {
  const _CompositorAnimado({
    super.key,
    required this.conMovimiento,
    required this.altoDisponible,
    required this.child,
  });

  final bool conMovimiento;
  final double altoDisponible;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final contenido = child;
    if (contenido == null) return const SizedBox.shrink();
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: conMovimiento ? 300 : 200),
      curve: Curves.easeOutCubic,
      child: MarcoDelCompositor(
        altoDisponible: altoDisponible,
        child: contenido,
      ),
      builder: (context, t, hijo) => Opacity(
        opacity: t,
        child: conMovimiento
            ? Transform.translate(offset: Offset(0, 8 * (1 - t)), child: hijo)
            : hijo,
      ),
    );
  }
}
