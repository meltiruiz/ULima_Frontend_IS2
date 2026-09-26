// lib/components/seis_siete/tambaleo_seis_siete.dart
//
// Envoltorio del truco del 67 (RF-67-2, RF-67-3, RF-67-4 y RF-67-7 de
// specs/features/six-seven/six-seven.spec.md). Inclina de un lado a otro lo
// que envuelve, que en un chat es toda la pantalla con su AppBar, y en los
// chats de sección pinta encima el rótulo «SIX SEVEN!!!» sin inclinarlo.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../configs/themes.dart';
import '../../domain/seis_siete/seis_siete.dart';

/// Clave del `Transform` que inclina el área. La usan las pruebas.
const Key claveGiroSeisSiete = ValueKey<String>('seis-siete-giro');

/// Clave de la región viva del rótulo «SIX SEVEN!!!». La usan las pruebas.
const Key claveRotuloSeisSiete = ValueKey<String>('seis-siete-rotulo');

/// Inclina [child] cada vez que [disparos] sube (RF-67-2).
///
/// Al montarse toma [disparos] como punto de partida y no se mueve, así que
/// abrir o reconstruir el chat nunca lo dispara. Hay un solo tambaleo a la
/// vez (RF-67-3), y con movimiento reducido no hay giro (RF-67-4). Con
/// [conRotulo] pinta además el rótulo de los chats de sección (RF-67-7).
class TambaleoSeisSiete extends StatefulWidget {
  const TambaleoSeisSiete({
    super.key,
    required this.disparos,
    required this.child,
    this.conRotulo = false,
  });

  /// Contador de disparos. Solo sube.
  final int disparos;

  /// Enciende el rótulo «SIX SEVEN!!!» (solo en los chats de sección).
  final bool conRotulo;

  /// Lo que se inclina. Se pinta siempre, también en reposo.
  final Widget child;

  @override
  State<TambaleoSeisSiete> createState() => _TambaleoSeisSieteState();
}

class _TambaleoSeisSieteState extends State<TambaleoSeisSiete>
    with SingleTickerProviderStateMixin {
  // `preserve` evita que «Quitar animaciones» acorte los 2000 ms al 5 %
  // (RF-67-4).
  late final AnimationController _avance = AnimationController(
    vsync: this,
    duration: duracionSeisSiete,
    animationBehavior: AnimationBehavior.preserve,
  )..addListener(_alAvanzar);

  /// Último valor de `disparos` que ya se atendió. Se fija en `initState`
  /// y no con un `late` perezoso, que tomaría el valor del primer disparo.
  late int _base;

  /// Si hay un tambaleo en curso, con giro o sin él.
  bool _activo = false;

  /// Si el tambaleo en curso gira y anima el rótulo. Se fija al disparar.
  bool _conMovimiento = false;

  @override
  void initState() {
    super.initState();
    _base = widget.disparos;
  }

  @override
  void didUpdateWidget(TambaleoSeisSiete anterior) {
    super.didUpdateWidget(anterior);
    if (widget.disparos <= _base) return;
    _base = widget.disparos;
    // Uno a la vez, sin reinicio ni cola (RF-67-3).
    if (_activo) return;
    _activo = true;
    // Las marcas se leen en el momento del disparo (RF-67-4).
    _conMovimiento = !_pideMenosMovimiento();
    _avance.forward(from: 0);
  }

  /// «Quitar animaciones» de Android o «Reducir movimiento» de iOS (D6).
  bool _pideMenosMovimiento() =>
      MediaQuery.disableAnimationsOf(context) ||
      View.of(context).platformDispatcher.accessibilityFeatures.reduceMotion;

  /// Termina el tambaleo justo a los 2000 ms. El controller llega a 1 en ese
  /// cuadro, pero recién marcaría `completed` en el siguiente.
  void _alAvanzar() {
    if (!_activo || _avance.value < 1) return;
    _avance.stop();
    setState(() {
      _activo = false;
      _conMovimiento = false;
    });
  }

  @override
  void dispose() {
    _avance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // El teclado del sistema tapa la parte de abajo. El giro y el rótulo se
    // centran en lo que queda a la vista (RF-67-2 y RF-67-7).
    final teclado = MediaQuery.viewInsetsOf(context).bottom;

    return ColoredBox(
      // Las esquinas que el giro deja al descubierto muestran el fondo de la
      // página (RF-67-2).
      color: MaterialTheme.pageBg(Theme.brightnessOf(context)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            child: AnimatedBuilder(
              animation: _avance,
              builder: (context, hijo) => Transform.rotate(
                key: claveGiroSeisSiete,
                angle: _activo && _conMovimiento
                    ? anguloSeisSiete(_avance.value)
                    : 0,
                origin: Offset(0, -teclado / 2),
                child: hijo,
              ),
              // Cada cuadro solo vuelve a componer esta capa y no repinta
              // los mensajes (RF-67-2, «Árbol estable»).
              child: RepaintBoundary(child: widget.child),
            ),
          ),
          if (widget.conRotulo && _activo)
            Positioned(
              left: 16,
              top: 0,
              right: 16,
              bottom: teclado,
              child: IgnorePointer(
                child: Center(
                  child: _RotuloSeisSiete(
                    avance: _avance,
                    animado: _conMovimiento,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Píldora «SIX SEVEN!!!» de los chats de sección (RF-67-7).
class _RotuloSeisSiete extends StatelessWidget {
  const _RotuloSeisSiete({required this.avance, required this.animado});

  /// Avance del tambaleo, de 0 a 1 en 2000 ms.
  final Animation<double> avance;

  /// Sin movimiento reducido entra y sale con fundido y escala.
  final bool animado;

  static const double _entradaMs = 150;
  static const double _salidaMs = 250;

  @override
  Widget build(BuildContext context) {
    final brillo = Theme.brightnessOf(context);
    final pildora = Semantics(
      key: claveRotuloSeisSiete,
      container: true,
      liveRegion: true,
      label: textoSeisSiete,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: MaterialTheme.cardBg(brillo),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: MaterialTheme.iconoNaranja(brillo),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                textoSeisSiete,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: MaterialTheme.textPrimary(brillo),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (!animado) return pildora;

    return AnimatedBuilder(
      animation: avance,
      builder: (context, hijo) {
        final ms = avance.value * duracionSeisSiete.inMilliseconds;
        final entrada = (ms / _entradaMs).clamp(0.0, 1.0);
        final salida = ((duracionSeisSiete.inMilliseconds - ms) / _salidaMs)
            .clamp(0.0, 1.0);
        return Opacity(
          opacity: math.min(entrada, salida),
          child: Transform.scale(
            scale: 0.8 + 0.2 * Curves.easeOutBack.transform(entrada),
            child: hijo,
          ),
        );
      },
      child: pildora,
    );
  }
}
