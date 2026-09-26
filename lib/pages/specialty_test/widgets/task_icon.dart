// lib/pages/specialty_test/widgets/task_icon.dart
// La baldosa con el ícono de una tarea (RF-TEST-5 y RF-TEST-6).

import 'package:flutter/material.dart';

import '../../../configs/themes.dart';
import '../specialty_test_logic.dart';

/// La baldosa del ícono de una tarea. Sin [color] va neutra, con el fondo
/// `testTaskTileBg` y el ícono en `testTaskIconInk`, como antes del toque y
/// siempre en la escala. Con [color], el de su especialidad, se enciende.
/// El ícono sale del mapa cerrado, y un nombre desconocido cae al neutro.
/// Es decorativa, así que queda fuera del árbol de accesibilidad.
class TaskIconTile extends StatelessWidget {
  const TaskIconTile({
    super.key,
    required this.icono,
    this.color,
    this.width = 80,
    this.height = 80,
    this.iconSize = 40,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.apagada = false,
  });

  /// Nombre de Lucide que manda el contenido, o null.
  final String? icono;
  final Color? color;
  final double width;
  final double height;
  final double iconSize;
  final BorderRadius borderRadius;

  /// La otra tarjeta del duelo tras el toque, con el ícono al 50 %.
  final bool apagada;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final encendido = color;
    final fondo = encendido == null
        ? MaterialTheme.testTaskTileBg(b)
        : tinte(encendido, MaterialTheme.cardBg(b), 0.16);
    return ExcludeSemantics(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        height: height,
        decoration: BoxDecoration(color: fondo, borderRadius: borderRadius),
        alignment: Alignment.center,
        child: Opacity(
          opacity: apagada ? 0.5 : 1,
          child: Icon(
            iconoDelTest(icono),
            size: iconSize,
            color: encendido ?? MaterialTheme.testTaskIconInk(b),
          ),
        ),
      ),
    );
  }
}
