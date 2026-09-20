import 'package:flutter/material.dart';

import '../../configs/themes.dart';

/// Insignia de ubicación relativa del alumno ("Tercio superior").
///
/// La comparten la tarjeta del Perfil (RF-REC-1) y el encabezado de la
/// pantalla del récord (RF-REC-2). Recibe el texto YA formateado con
/// `formatRelativePosition`: cuando esa función devuelve null no hay dato y
/// quien llama simplemente no monta la insignia.
class RecordPositionBadge extends StatelessWidget {
  const RecordPositionBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: MaterialTheme.espPrincipalBg(brightness),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: MaterialTheme.primaryDark,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
