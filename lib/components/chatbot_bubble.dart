import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../pages/splash/puntos_de_aterrizaje.dart';

/// Burbuja flotante del chatbot (Ulises).
///
/// - Sin fondo ni texto: solo la carita de Ulises, para que tape lo mínimo.
/// - "Latido" tipo sonar (dos anillos que crecen y se desvanecen) + micro-escala,
///   el efecto típico de los asistentes. Respeta el "reduce motion" del sistema.
/// - ARRASTRABLE: el usuario la reubica; al soltar hace snap al borde izq/der
///   más cercano. Al tocarla abre el chatbot.
///
/// Se coloca dentro de un Stack que ocupa el área del body (debajo del header y
/// encima del contenido). Las zonas vacías del Stack no capturan toques, así que
/// el contenido de abajo sigue siendo interactivo.
class ChatbotBubble extends StatefulWidget {
  const ChatbotBubble({super.key, this.size = 60});

  /// Diámetro del área táctil (la carita). El halo pinta un poco más grande.
  final double size;

  @override
  State<ChatbotBubble> createState() => _ChatbotBubbleState();
}

class _ChatbotBubbleState extends State<ChatbotBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  Offset? _pos; // esquina superior-izquierda de la burbuja dentro del Stack
  bool _dragging = false;

  static const double _margin = 12;

  final GlobalKey _clave = GlobalKey();
  bool _informada = false;

  /// Informa su lugar inicial una vez, después de su primer cuadro, como la
  /// cabecera informa su estrella (RF-BIEN-11).
  void _informar() {
    final caja = _clave.currentContext?.findRenderObject() as RenderBox?;
    if (!mounted || caja == null || !caja.hasSize) return;
    PuntosDeAterrizaje.burbuja.value =
        caja.localToGlobal(Offset.zero) & caja.size;
  }

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // El latido solo corre con animaciones habilitadas (respeta "reduce motion"
    // y no deja el ticker infinito corriendo sin efecto visible).
    if (MediaQuery.of(context).disableAnimations) {
      if (_pulse.isAnimating) _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bubble = widget.size;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;

        double clampX(double x) =>
            x.clamp(_margin, (maxW - bubble - _margin).clamp(_margin, double.infinity));
        double clampY(double y) =>
            y.clamp(_margin, (maxH - bubble - _margin).clamp(_margin, double.infinity));

        // Posición inicial: abajo a la IZQUIERDA. Así no choca con el FAB
        // "Simular mi avance" de la malla (que va abajo a la derecha).
        _pos ??= Offset(_margin, maxH - bubble - _margin);
        final pos = Offset(clampX(_pos!.dx), clampY(_pos!.dy));
        if (!_informada) {
          _informada = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => _informar());
        }

        return Stack(
          children: [
            Positioned(
              left: pos.dx,
              top: pos.dy,
              // Oculta solo mientras la capa trae a Ulises en el paso al
              // horario. En cualquier otra llegada aparece con la página
              // (decisiones S-28 y B-16).
              child: ValueListenableBuilder<bool>(
                valueListenable: PuntosDeAterrizaje.ulisesEnVuelo,
                builder: (context, enVuelo, hijo) =>
                    Opacity(opacity: enVuelo ? 0 : 1, child: hijo),
                child: GestureDetector(
                  key: _clave,
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Get.toNamed('/chatbot'),
                  onPanStart: (_) => setState(() => _dragging = true),
                  onPanUpdate: (d) => setState(() {
                    _pos = Offset(
                      clampX(pos.dx + d.delta.dx),
                      clampY(pos.dy + d.delta.dy),
                    );
                  }),
                  onPanEnd: (_) => setState(() {
                    _dragging = false;
                    // Snap al borde horizontal más cercano; conserva la altura.
                    final goRight = (_pos!.dx + bubble / 2) > maxW / 2;
                    _pos = Offset(
                      goRight ? (maxW - bubble - _margin) : _margin,
                      clampY(_pos!.dy),
                    );
                  }),
                  child: _BubbleVisual(
                    pulse: _pulse,
                    size: bubble,
                    dragging: _dragging,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BubbleVisual extends StatelessWidget {
  const _BubbleVisual({
    required this.pulse,
    required this.size,
    required this.dragging,
  });

  final Animation<double> pulse;
  final double size;
  final bool dragging;

  static const Color _accent = Color(0xFFF57C00); // naranja Ulima

  @override
  Widget build(BuildContext context) {
    final avatar = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/ulises_chatbot.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );

    // Reduce motion: burbuja estática, sin latido.
    if (MediaQuery.of(context).disableAnimations) {
      return SizedBox(width: size, height: size, child: avatar);
    }

    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: pulse,
        builder: (context, child) {
          final t = pulse.value; // 0..1
          // Latido suave (sube y baja); se congela mientras se arrastra.
          final beat = 1.0 + (dragging ? 0.0 : 0.045 * (0.5 - (t - 0.5).abs()) * 2);
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (!dragging) ...[
                _ring(t),
                _ring((t + 0.5) % 1.0),
              ],
              Transform.scale(scale: beat, child: child),
            ],
          );
        },
        child: avatar,
      ),
    );
  }

  /// Anillo "sonar": de chico y visible a grande y transparente.
  Widget _ring(double t) {
    final scale = 1.0 + t * 0.85;
    final opacity = ((1.0 - t) * 0.45).clamp(0.0, 1.0);
    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _accent, width: 2.5),
          ),
        ),
      ),
    );
  }
}
