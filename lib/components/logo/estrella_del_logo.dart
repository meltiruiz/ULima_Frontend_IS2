// lib/components/logo/estrella_del_logo.dart
// La estrella del logo, quieta y sin «++», como en la cabecera
// (BR-SHELL-F-04). Se pinta con la geometría única (RF-SPL-2), así que la
// estrella de la intro aterriza sobre la misma figura (RF-SPL-11).

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'escena_del_logo.dart';
import 'pintor_del_logo.dart';

/// Una escena que no cambia nunca.
class EscenaFija implements ValueListenable<EscenaDelLogo> {
  EscenaFija(this.value);

  @override
  final EscenaDelLogo value;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

class EstrellaDelLogo extends StatelessWidget {
  const EstrellaDelLogo({
    super.key,
    this.tamano = 26,
    this.color = const Color(0xFFFFFFFF),
  });

  /// De punta a punta, sin retraer.
  final double tamano;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final escena = EscenaFija(
      EscenaDelLogo.reposo(
        centro: Offset(tamano / 2, tamano / 2),
        radio: tamano / 2,
        conCruces: false,
      ),
    );
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: tamano,
        child: CustomPaint(painter: PintorDelLogo(escena, color: color)),
      ),
    );
  }
}
