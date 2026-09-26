// lib/pages/specialty_test/widgets/question_view.dart
// La conversación con Ulises en una pregunta (RF-TEST-4 a RF-TEST-6), con la
// barra, las plumas, el historial, el duelo, la escala y el desempate.
// Pantallas 2 y 3 de la maqueta.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../configs/themes.dart';
import '../../../models/specialty_test_models.dart';
import '../specialty_test_controller.dart';
import '../specialty_test_logic.dart';
import 'task_icon.dart';
import 'test_buttons.dart';
import 'ulises_bubble.dart';

/// Los emojis decorativos de la escala, uno por opción y en su orden.
const List<String> _emojis = <String>['😴', '🙂', '😃', '🤩'];

/// Si la escala de texto pide la versión apilada (RF-TEST-6 y RF-TEST-13).
bool _textoGrande(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(1) >= 1.3;

class QuestionView extends GetView<SpecialtyTestController> {
  const QuestionView({super.key});

  /// La tarjeta del duelo de `top` o de `bottom`.
  static Key tarjetaKey(String valor) => Key('tarjeta-$valor');

  /// Una opción de la escala por su id.
  static Key opcionKey(String id) => Key('opcion-$id');

  static const Key historialKey = Key('historial-lista');

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final sinMovimiento = MediaQuery.disableAnimationsOf(context);
    return ColoredBox(
      color: MaterialTheme.pageBg(b),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Obx(
              () => TestTopBar(
                subtitulo: subtituloDelPaso(
                  controller.contenido.value!,
                  controller.paso.value,
                ),
                onBack: controller.atras,
                onPause: controller.pausar,
              ),
            ),
            Obx(() {
              final c = controller.contenido.value!;
              final p = controller.paso.value;
              return TestFeathers(
                total: c.totalQuestions,
                actual: p < c.totalQuestions ? p : null,
                respondidas: {
                  for (var i = 0; i < c.totalQuestions; i++)
                    if (controller.respuestas.containsKey(c.questions[i].id)) i,
                },
              );
            }),
            Expanded(
              child: Obx(() {
                final datos = _DatosDelPaso.tryDe(controller);
                // Al salir de la pregunta (espera o resultado) el paso puede
                // quedar sin datos un instante, hasta que la ruta cambia de
                // pantalla.
                if (datos == null) return const SizedBox.shrink();
                return AnimatedSwitcher(
                  duration: Duration(milliseconds: sinMovimiento ? 150 : 180),
                  // La reacción y la pregunta siguiente entran juntas, y el
                  // par anterior se encoge hacia la pastilla del historial,
                  // que está arriba. Con menos movimiento, solo un fundido.
                  transitionBuilder: (hijo, animacion) {
                    final fundido = FadeTransition(
                      opacity: animacion,
                      child: hijo,
                    );
                    if (sinMovimiento) return fundido;
                    return SizeTransition(
                      sizeFactor: animacion,
                      alignment: Alignment.topCenter,
                      child: fundido,
                    );
                  },
                  child: _Paso(
                    key: ValueKey<int>(datos.paso),
                    datos: datos,
                    controller: controller,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lo que pinta un paso, leído de los Rx dentro del Obx.
class _DatosDelPaso {
  const _DatosDelPaso({
    required this.paso,
    required this.contenido,
    required this.pregunta,
    required this.desempate,
    required this.respuesta,
    required this.turno,
    required this.filasDelHistorial,
    required this.historialAbierto,
  });

  static _DatosDelPaso? tryDe(SpecialtyTestController c) {
    final contenido = c.contenido.value;
    final paso = c.paso.value;
    final respuestas = Map<String, String>.of(c.respuestas);
    final desempates = c.desempates.toList();
    final historialAbierto = c.historialAbierto.value;
    if (contenido == null) return null;
    final pregunta = c.preguntaActual;
    final desempate = c.desempateActual;
    if (pregunta == null && desempate == null) return null;
    return _DatosDelPaso(
      paso: paso,
      contenido: contenido,
      pregunta: pregunta,
      desempate: desempate,
      respuesta: c.respuestaActual,
      turno: pregunta != null
          ? turnoAntesDePregunta(contenido, paso, respuestas)
          : turnoAntesDeDesempate(desempate!),
      filasDelHistorial: historial(contenido, respuestas, desempates, paso),
      historialAbierto: historialAbierto,
    );
  }

  final int paso;
  final SpecialtyTestContent contenido;
  final TestQuestion? pregunta;
  final TiebreakRecord? desempate;
  final String? respuesta;
  final TurnoDeUlises turno;
  final List<EntradaDelHistorial> filasDelHistorial;
  final bool historialAbierto;
}

class _Paso extends StatefulWidget {
  const _Paso({super.key, required this.datos, required this.controller});

  final _DatosDelPaso datos;
  final SpecialtyTestController controller;

  @override
  State<_Paso> createState() => _PasoState();
}

class _PasoState extends State<_Paso> {
  /// El foco del lector pasa al enunciado del paso nuevo (RF-TEST-13).
  final FocusNode _enunciado = FocusNode(debugLabel: 'enunciado');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _enunciado.requestFocus();
      // El sello cae con una vibración leve (RF-TEST-6).
      if (widget.datos.turno.sello != null) HapticFeedback.lightImpact();
    });
  }

  @override
  void dispose() {
    _enunciado.dispose();
    super.dispose();
  }

  /// Si este paso es el vigente. En la transición, el paso que sale sigue en
  /// pantalla uno o dos cuadros y recibe toques, pero el controlador ya está
  /// en el que entra, así que esos toques no hacen nada.
  bool get _vigente => widget.datos.paso == widget.controller.paso.value;

  void _responder(String valor) {
    if (!_vigente) return;
    HapticFeedback.selectionClick();
    widget.controller.responder(
      valor,
      avanceSolo: !MediaQuery.accessibleNavigationOf(context),
    );
  }

  void _avanzar() {
    if (_vigente) widget.controller.avanzar();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.datos;
    final pregunta = d.pregunta;
    final lector = MediaQuery.accessibleNavigationOf(context);
    final esEscala = pregunta != null && !pregunta.isDuel;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (d.filasDelHistorial.isNotEmpty)
            _Historial(
              filas: d.filasDelHistorial,
              abierto: d.historialAbierto,
              onTap: widget.controller.alternarHistorial,
            ),
          UlisesTurnView(turno: d.turno),
          const SizedBox(height: 12),
          if (esEscala)
            _Escala(
              pregunta: pregunta,
              opciones: d.contenido.scaleOptions,
              respuesta: d.respuesta,
              foco: _enunciado,
              onTap: _responder,
            )
          else ...[
            _Encabezado(
              rotulo: pregunta == null ? 'Desempate' : 'Esto o aquello',
              enunciado: pregunta?.prompt ?? d.desempate!.tiebreak.prompt,
              foco: _enunciado,
            ),
            const SizedBox(height: 12),
            _Duelo(
              tareas:
                  pregunta?.tasks ??
                  [d.desempate!.tiebreak.top, d.desempate!.tiebreak.bottom],
              contenido: d.contenido,
              respuesta: d.respuesta,
              ayuda: d.contenido.ulises.duelHelp,
              onTap: _responder,
            ),
            const SizedBox(height: 14),
            _LasDosONinguna(
              contenido: d.contenido,
              respuesta: d.respuesta,
              onTap: _responder,
            ),
          ],
          if (lector && d.respuesta != null) ...[
            const SizedBox(height: 14),
            TestPrimaryButton(
              label: 'Siguiente',
              icon: LucideIcons.arrowRight,
              onPressed: _avanzar,
            ),
          ],
        ],
      ),
    );
  }
}

/// La barra de 52 px de la conversación, con «Pregunta anterior», Ulises y
/// «Pausar el test y seguir luego». La usan la pregunta y la espera.
class TestTopBar extends StatelessWidget {
  const TestTopBar({
    super.key,
    required this.subtitulo,
    required this.onBack,
    required this.onPause,
  });

  final String subtitulo;
  final VoidCallback onBack;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final tinta = MaterialTheme.textPrimary(b);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Pregunta anterior',
              style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: onBack,
              icon: Icon(LucideIcons.chevronLeft, color: tinta, size: 22),
            ),
            Expanded(
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: SizedBox(
                      width: 38,
                      height: 38,
                      child: Stack(
                        children: [
                          const UlisesAvatar(size: 38),
                          Positioned(
                            right: -1,
                            bottom: 0,
                            child: Container(
                              width: 11,
                              height: 11,
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: MaterialTheme.pageBg(b),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ulises',
                          style: TextStyle(
                            color: tinta,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          subtitulo,
                          style: TextStyle(
                            color: MaterialTheme.testMuted(b),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Pausar el test y seguir luego',
              style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: onPause,
              icon: Icon(LucideIcons.pause, color: tinta, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

/// Una pluma por pregunta, siempre en naranja (RF-TEST-4). [actual] es null
/// en los desempates y en la espera, donde van todas llenas. Son
/// decorativas.
class TestFeathers extends StatefulWidget {
  const TestFeathers({
    super.key,
    required this.total,
    required this.actual,
    this.respondidas = const <int>{},
  });

  final int total;
  final int? actual;
  final Set<int> respondidas;

  /// Marca cada pluma para las pruebas.
  static Key plumaKey(int i) => Key('pluma-$i');

  @override
  State<TestFeathers> createState() => _TestFeathersState();
}

class _TestFeathersState extends State<TestFeathers>
    with SingleTickerProviderStateMixin {
  late final AnimationController _brillo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  /// La pluma actual brilla, salvo con menos movimiento o sin pluma actual.
  /// Se ajusta al montar, al cambiar el movimiento y al cambiar de paso, así
  /// que al volver del desempate a la última pregunta el brillo sigue.
  void _ajustarBrillo() {
    if (MediaQuery.disableAnimationsOf(context) || widget.actual == null) {
      if (_brillo.isAnimating || _brillo.value != 0) {
        _brillo.stop();
        _brillo.value = 0;
      }
    } else if (!_brillo.isAnimating) {
      _brillo.repeat(reverse: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ajustarBrillo();
  }

  @override
  void didUpdateWidget(TestFeathers oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ajustarBrillo();
  }

  @override
  void dispose() {
    _brillo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final llena = MaterialTheme.testFeatherOn(b);
    final vacia = MaterialTheme.testFeatherOff(b);
    return ExcludeSemantics(
      child: Container(
        height: 32,
        padding: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: MaterialTheme.testLine(b))),
        ),
        child: AnimatedBuilder(
          animation: _brillo,
          builder: (context, _) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.total; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Transform.rotate(
                    angle: 22 * math.pi / 180,
                    child: Icon(
                      LucideIcons.feather,
                      key: TestFeathers.plumaKey(i),
                      size: 18,
                      color:
                          widget.actual == null ||
                              i == widget.actual ||
                              widget.respondidas.contains(i)
                          ? llena
                          : vacia,
                      shadows: i == widget.actual
                          ? [
                              Shadow(
                                color: llena.withValues(
                                  alpha: 0.9 * _brillo.value,
                                ),
                                blurRadius: 5,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// La pastilla «N respuestas anteriores» y, desplegada, la lista de lo
/// respondido, sin colores de especialidad y solo para leer.
class _Historial extends StatelessWidget {
  const _Historial({
    required this.filas,
    required this.abierto,
    required this.onTap,
  });

  final List<EntradaDelHistorial> filas;
  final bool abierto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final gris = MaterialTheme.testMuted(b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Semantics(
            button: true,
            expanded: abierto,
            label: etiquetaDeLaPastilla(filas.length, desplegada: abierto),
            excludeSemantics: true,
            onTap: onTap,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(999),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Center(
                  widthFactor: 1,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(9, 5, 12, 5),
                    decoration: BoxDecoration(
                      color: MaterialTheme.testChipBg(b),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          abierto
                              ? LucideIcons.chevronUp
                              : LucideIcons.chevronDown,
                          size: 14,
                          color: gris,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            textoDeLaPastilla(filas.length),
                            style: TextStyle(
                              color: gris,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (abierto)
          Container(
            key: QuestionView.historialKey,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MaterialTheme.cardBg(b),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: MaterialTheme.testLine(b)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final f in filas)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${f.etiqueta}  ',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(text: f.respuesta),
                        ],
                      ),
                      style: TextStyle(
                        color: MaterialTheme.textPrimary(b),
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// El rótulo en mayúsculas y el enunciado, que es un encabezado y recibe el
/// foco del lector.
class _Encabezado extends StatelessWidget {
  const _Encabezado({
    required this.rotulo,
    required this.enunciado,
    required this.foco,
  });

  final String rotulo;
  final String enunciado;
  final FocusNode foco;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo.toUpperCase(),
          style: TextStyle(
            color: MaterialTheme.testAccentText(b),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.66,
          ),
        ),
        const SizedBox(height: 3),
        Focus(
          focusNode: foco,
          child: Semantics(
            header: true,
            child: Text(
              enunciado,
              style: TextStyle(
                color: MaterialTheme.textPrimary(b),
                fontSize: 17.5,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum _EstadoTarjeta { neutra, encendida, apagada }

/// Las dos tarjetas del duelo, neutras hasta el toque (RF-TEST-5).
class _Duelo extends StatelessWidget {
  const _Duelo({
    required this.tareas,
    required this.contenido,
    required this.respuesta,
    required this.ayuda,
    required this.onTap,
  });

  final List<TestTask> tareas;
  final SpecialtyTestContent contenido;
  final String? respuesta;
  final String? ayuda;
  final ValueChanged<String> onTap;

  _EstadoTarjeta _estado(String valor) {
    switch (respuesta) {
      case null:
        return _EstadoTarjeta.neutra;
      case 'both':
        return _EstadoTarjeta.encendida;
      case 'none':
        return _EstadoTarjeta.apagada;
      default:
        return respuesta == valor
            ? _EstadoTarjeta.encendida
            : _EstadoTarjeta.apagada;
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    Widget tarjeta(TestTask tarea, String valor) => _TarjetaDeTarea(
      key: QuestionView.tarjetaKey(valor),
      tarea: tarea,
      estado: _estado(valor),
      color:
          colorDeEspecialidad(contenido.specialtyByKey(tarea.specialty), b) ??
          MaterialTheme.testTaskIconInk(b),
      ayuda: ayuda,
      onTap: () => onTap(valor),
    );
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            tarjeta(tareas.first, 'top'),
            const SizedBox(height: 12),
            tarjeta(tareas.last, 'bottom'),
          ],
        ),
        ExcludeSemantics(
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: MaterialTheme.pageBg(b),
              shape: BoxShape.circle,
              border: Border.all(color: MaterialTheme.testLine(b), width: 1.5),
            ),
            child: Text(
              'o',
              style: TextStyle(
                color: MaterialTheme.testMuted(b),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TarjetaDeTarea extends StatelessWidget {
  const _TarjetaDeTarea({
    super.key,
    required this.tarea,
    required this.estado,
    required this.color,
    required this.ayuda,
    required this.onTap,
  });

  final TestTask tarea;
  final _EstadoTarjeta estado;

  /// El color de su especialidad en el tema, que solo se ve encendida.
  final Color color;
  final String? ayuda;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final encendida = estado == _EstadoTarjeta.encendida;
    final apagada = estado == _EstadoTarjeta.apagada;
    final tarjeta = MaterialTheme.cardBg(b);
    return Semantics(
      button: true,
      selected: encendida,
      label: tarea.text,
      hint: ayuda,
      excludeSemantics: true,
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: const BoxConstraints(minHeight: 104),
            decoration: BoxDecoration(
              color: encendida ? tinte(color, tarjeta, 0.12) : tarjeta,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: encendida ? color : MaterialTheme.testLine(b),
                // El borde más grueso de la encendida acompaña al color
                // (RF-TEST-13).
                width: encendida ? 1.5 : 1,
              ),
              boxShadow: encendida
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        spreadRadius: 4,
                      ),
                    ]
                  : null,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
                  child: Row(
                    children: [
                      TaskIconTile(
                        icono: tarea.icon,
                        color: encendida ? color : null,
                        apagada: apagada,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tarea.text,
                          style: TextStyle(
                            color: apagada
                                ? MaterialTheme.testInk2(b)
                                : MaterialTheme.textPrimary(b),
                            fontSize: 14,
                            fontWeight: apagada
                                ? FontWeight.w600
                                : FontWeight.w700,
                            height: 1.32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (encendida)
            Positioned(
              top: -9,
              right: -7,
              child: ExcludeSemantics(
                // El salto de la insignia, que no ocurre con menos
                // movimiento.
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: MediaQuery.disableAnimationsOf(context) ? 1 : 0.4,
                    end: 1,
                  ),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.elasticOut,
                  builder: (context, escala, hijo) =>
                      Transform.scale(scale: escala, child: hijo),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: MaterialTheme.pageBg(b),
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      LucideIcons.check,
                      size: 13,
                      color: MaterialTheme.pageBg(b),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// «Me gustan las dos» y «Ninguna me llama», con las etiquetas de
/// `duelOptions`, en dos columnas o, desde 1,3, una debajo de otra.
class _LasDosONinguna extends StatelessWidget {
  const _LasDosONinguna({
    required this.contenido,
    required this.respuesta,
    required this.onTap,
  });

  final SpecialtyTestContent contenido;
  final String? respuesta;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    Widget boton(String id) => _BotonAlterno(
      etiqueta: contenido.optionLabel(id)!,
      elegido: respuesta == id,
      onTap: () => onTap(id),
    );
    if (_textoGrande(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [boton('both'), const SizedBox(height: 8), boton('none')],
      );
    }
    return Row(
      children: [
        Expanded(child: boton('both')),
        const SizedBox(width: 8),
        Expanded(child: boton('none')),
      ],
    );
  }
}

class _BotonAlterno extends StatelessWidget {
  const _BotonAlterno({
    required this.etiqueta,
    required this.elegido,
    required this.onTap,
  });

  final String etiqueta;
  final bool elegido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Semantics(
      button: true,
      selected: elegido,
      label: etiqueta,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: elegido
            ? MaterialTheme.testAccentSoft(b)
            : MaterialTheme.cardBg(b),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: elegido
                ? MaterialTheme.testAccent(b)
                : MaterialTheme.testLine(b),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Text(
                  etiqueta,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: elegido
                        ? MaterialTheme.testAccentDeep(b)
                        : MaterialTheme.testInk2(b),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// La escala de gusto (RF-TEST-6). Nunca se enciende con el color de su
/// especialidad, porque ese color la delataría.
class _Escala extends StatelessWidget {
  const _Escala({
    required this.pregunta,
    required this.opciones,
    required this.respuesta,
    required this.foco,
    required this.onTap,
  });

  final TestQuestion pregunta;
  final List<TestOption> opciones;
  final String? respuesta;
  final FocusNode foco;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final dosPorDos =
        _textoGrande(context) || MediaQuery.sizeOf(context).width < 340;
    final botones = [
      for (var i = 0; i < opciones.length; i++)
        _OpcionDeEscala(
          key: QuestionView.opcionKey(opciones[i].id),
          emoji: _emojis[i],
          etiqueta: opciones[i].label,
          elegida: respuesta == opciones[i].id,
          onTap: () => onTap(opciones[i].id),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: MaterialTheme.cardBg(b),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: MaterialTheme.testLine(b)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TaskIconTile(
                icono: pregunta.task!.icon,
                width: double.infinity,
                height: 92,
                borderRadius: BorderRadius.zero,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESCALA DE GUSTO',
                      style: TextStyle(
                        color: MaterialTheme.testAccentText(b),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.66,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      pregunta.task!.text,
                      style: TextStyle(
                        color: MaterialTheme.textPrimary(b),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Focus(
                      focusNode: foco,
                      child: Semantics(
                        header: true,
                        child: Text(
                          pregunta.prompt,
                          style: TextStyle(
                            color: MaterialTheme.testMuted(b),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          container: true,
          explicitChildNodes: true,
          label: pregunta.prompt,
          child: dosPorDos
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FilaDeOpciones(opciones: botones.sublist(0, 2)),
                    const SizedBox(height: 6),
                    _FilaDeOpciones(opciones: botones.sublist(2)),
                  ],
                )
              : _FilaDeOpciones(opciones: botones),
        ),
      ],
    );
  }
}

/// Una fila de opciones del mismo alto, aunque una etiqueta ocupe dos
/// líneas.
class _FilaDeOpciones extends StatelessWidget {
  const _FilaDeOpciones({required this.opciones});

  final List<Widget> opciones;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < opciones.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(child: opciones[i]),
          ],
        ],
      ),
    );
  }
}

class _OpcionDeEscala extends StatelessWidget {
  const _OpcionDeEscala({
    super.key,
    required this.emoji,
    required this.etiqueta,
    required this.elegida,
    required this.onTap,
  });

  final String emoji;
  final String etiqueta;
  final bool elegida;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final sinMovimiento = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      checked: elegida,
      label: etiqueta,
      excludeSemantics: true,
      onTap: onTap,
      child: AnimatedScale(
        scale: elegida && !sinMovimiento ? 1.08 : 1,
        duration: const Duration(milliseconds: 150),
        child: Material(
          color: elegida
              ? MaterialTheme.testAccentSoft(b)
              : MaterialTheme.cardBg(b),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(
              color: elegida
                  ? MaterialTheme.testAccent(b)
                  : MaterialTheme.testLine(b),
              width: elegida ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(15),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ExcludeSemantics(
                      child: Text(emoji, style: const TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      etiqueta,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: elegida
                            ? MaterialTheme.testAccentDeep(b)
                            : MaterialTheme.testInk2(b),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
