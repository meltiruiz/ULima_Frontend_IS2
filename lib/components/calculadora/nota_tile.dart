import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../configs/themes.dart';
import '../../domain/recarga_ulima/formato_nota.dart';

class NotaTile extends StatelessWidget {
  final String titulo;

  /// Entero en las simuladas y con el peso exacto de la ULima en las suyas.
  final num peso;

  /// `null` solo con [np].
  final double? nota;

  /// La ULima publica «NP» (decisión B8). La línea dice `Nota: NP`.
  final bool np;

  /// La nota la publica la ULima (RF-RCG-7). Lleva la marca «ULima» en lugar
  /// del tacho y no se puede borrar ni editar.
  final bool deUlima;
  final VoidCallback? onDelete;

  const NotaTile({
    super.key,
    required this.titulo,
    required this.peso,
    required this.nota,
    this.np = false,
    this.deUlima = false,
    this.onDelete,
  }) : assert(deUlima || onDelete != null, 'Una nota simulada se borra');

  String get _textoNota =>
      np ? 'Nota: NP' : 'Nota: ${formatoNotaCalculadora(nota ?? 0)}/20';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fila = _fila(context, colors);
    if (!deUlima) return fila;
    final notaDicha = np
        ? 'nota NP'
        : 'nota ${formatoNotaCalculadora(nota ?? 0)} de 20';
    return Semantics(
      container: true,
      excludeSemantics: true,
      label:
          '$titulo, peso ${numeroDePeso(peso)} por ciento, $notaDicha, '
          'publicada por la ULima',
      child: fila,
    );
  }

  Widget _fila(BuildContext context, ColorScheme colors) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: colors.onTertiaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    children: [
                      TextSpan(text: "Peso: ${formatoPeso(peso)}  •  "),
                      TextSpan(
                        text: _textoNota,
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (deUlima)
            const SizedBox(height: 40, child: Center(child: _InsigniaUlima()))
          else
            IconButton(
              icon: Icon(Icons.delete_outline, color: colors.error, size: 22),
              onPressed: () {
                Get.defaultDialog(
                  title: "Eliminar Nota",
                  titleStyle: TextStyle(color: colors.onSurface),
                  middleTextStyle: TextStyle(color: colors.onSurfaceVariant),
                  backgroundColor: colors.surface,
                  middleText:
                      "¿Estás seguro de que quieres eliminar '$titulo'?",
                  textConfirm: "Eliminar",
                  textCancel: "Cancelar",
                  confirmTextColor: colors.onError,
                  buttonColor: colors.error,
                  onConfirm: () {
                    onDelete!();
                    debugPrint(
                      "✅ ÉXITO: Se eliminó la nota '$titulo' correctamente.",
                    );
                    Get.back();
                  },
                );
              },
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

/// La marca «ULima» de una nota publicada, con el tamaño de
/// `RecordPositionBadge` y el naranja de D11. No es tocable.
class _InsigniaUlima extends StatelessWidget {
  const _InsigniaUlima();

  @override
  Widget build(BuildContext context) {
    final brillo = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: MaterialTheme.espPrincipalBg(brillo),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'ULima',
        style: TextStyle(
          color: MaterialTheme.insigniaUlimaTexto(brillo),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
