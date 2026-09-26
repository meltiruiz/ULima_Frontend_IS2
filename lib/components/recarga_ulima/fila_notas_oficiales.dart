// lib/components/recarga_ulima/fila_notas_oficiales.dart
//
// La fila «Notas oficiales» del encabezado de la calculadora (RF-RCG-5 de
// specs/features/recarga-portal/recarga-portal.spec.md), con el estilo de la
// hoja «Selecciona un Curso». Reemplaza al birrete sin texto.

import 'package:flutter/material.dart';

import '../../configs/themes.dart';
import '../../domain/recarga_ulima/ultima_lectura.dart';
import 'franja_recarga.dart' show textoSinLecturaUlima;

class FilaNotasOficiales extends StatelessWidget {
  const FilaNotasOficiales({
    super.key,
    required this.hayVista,
    required this.ultimaLectura,
    required this.onTap,
  });

  /// Hay una vista de la ULima del alumno actual. Sin ella, porque la primera
  /// carga está en curso o termina en error, la fila lleva solo el título.
  final bool hayVista;

  /// La `lastReadAt` de la vista, o `null` si todavía no hay lectura.
  final DateTime? ultimaLectura;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final lectura = ultimaLectura;
    final segunda = !hayVista
        ? null
        : lectura == null
        ? textoSinLecturaUlima
        : textoUltimaLectura(lectura, DateTime.now());
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: colors.primary.withValues(alpha: 0.3)),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Semantics(
        button: true,
        label: segunda == null
            ? 'Notas oficiales'
            : 'Notas oficiales. $segunda',
        excludeSemantics: true,
        onTap: onTap,
        child: Material(
          color: colors.primary.withValues(alpha: 0.1),
          shape: forma,
          child: InkWell(
            onTap: onTap,
            customBorder: forma,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 22,
                      color: MaterialTheme.iconoNaranja(colors.brightness),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Notas oficiales',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: colors.onSurface,
                            ),
                          ),
                          if (segunda != null)
                            Text(
                              segunda,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 22,
                      color: colors.onSurface.withValues(alpha: 0.5),
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
