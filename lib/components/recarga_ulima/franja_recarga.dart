// lib/components/recarga_ulima/franja_recarga.dart
//
// La franja «Actualizar desde la ULima» de /mis-notas (RF-RCG-6 de
// specs/features/recarga-portal/recarga-portal.spec.md), que copia la
// tarjeta «Actualizar desde miUlima» del Perfil y abre la hoja de recarga.

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../configs/themes.dart';
import '../../domain/recarga_ulima/ultima_lectura.dart';

/// Texto de lo que todavía no tiene lectura de la ULima.
const String textoSinLecturaUlima = 'Aún no se actualizan desde la ULima';

class FranjaRecarga extends StatelessWidget {
  const FranjaRecarga({
    super.key,
    required this.ultimaLectura,
    required this.onTap,
  });

  /// La `lastReadAt` de la vista, o `null` si todavía no hay lectura.
  final DateTime? ultimaLectura;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brillo = Theme.of(context).brightness;
    final lectura = ultimaLectura;
    final segunda = lectura == null
        ? textoSinLecturaUlima
        : textoUltimaLectura(lectura, DateTime.now());
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: MaterialTheme.borderColor(brillo)),
    );
    return Semantics(
      button: true,
      label: 'Actualizar desde la ULima. $segunda',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: MaterialTheme.cardBg(brillo),
        shape: forma,
        child: InkWell(
          onTap: onTap,
          customBorder: forma,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: MaterialTheme.espPrincipalBg(brillo),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    LucideIcons.refreshCw,
                    color: MaterialTheme.primaryDark,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Actualizar desde la ULima',
                        style: TextStyle(
                          color: MaterialTheme.textPrimary(brillo),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        segunda,
                        style: TextStyle(
                          color: MaterialTheme.textSecondary(brillo),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: MaterialTheme.textMuted(brillo),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
