import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/recarga_ulima/filas_calculadora.dart';
import 'nota_tile.dart';

class CursoCard extends StatelessWidget {
  final Map curso;
  final double promedio;
  final double sumaPesos;
  final int cursoIndex;

  /// Recibe la posición de la simulada en `curso['notas']`, no la de la fila
  /// visible (RF-RCG-7).
  final Function(int, int) onDeleteNota;

  /// Los ids de las evaluaciones del sílabo de la sección, en su orden (D7).
  final List<String> ordenSilabo;

  const CursoCard({
    super.key,
    required this.curso,
    required this.promedio,
    required this.sumaPesos,
    required this.cursoIndex,
    required this.onDeleteNota,
    this.ordenSilabo = const [],
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.onSecondary,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          // Header Naranja - Parte Superior
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Cambia tu Text temporalmente por esto para ver qué hay en "curso":
                          // En lib/components/calculadora/curso_card.dart
                          Text(
                            "Sección: ${curso['codigoSeccion'] ?? 'Sin sección'}",
                            style: TextStyle(
                              color: colors.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            curso['nombre'],
                            style: TextStyle(
                              color: colors.onPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            "Ciclo: ${curso['ciclo']}",
                            style: TextStyle(
                              color: colors.onPrimary.withValues(alpha: 0.8),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          promedio.toStringAsFixed(2),
                          style: TextStyle(
                            color: colors.onPrimary,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (promedio < 11.0)
                          Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: colors.onPrimary,
                                size: 14,
                              ),
                              Text(
                                " Desaprobado",
                                style: TextStyle(
                                  color: colors.onPrimary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.shadow.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        widthFactor: (sumaPesos / 100).clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: colors.secondary.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          "Suma de pesos: ${sumaPesos.toStringAsFixed(1)}% / 100%",
                          style: TextStyle(
                            color: colors.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Obx(() {
              // Las simuladas y las de la ULima, en listas aparte. El doble de
              // HU07 arma sus cursos sin la segunda.
              final filas = filasVisibles(
                simuladas: curso['notas'] as List,
                ulima: (curso[claveNotasUlima] as List?) ?? const [],
                ordenSilabo: ordenSilabo,
              );
              return Column(
                children: [
                  for (final fila in filas)
                    fila.deUlima
                        ? NotaTile(
                            titulo: fila.titulo,
                            peso: fila.peso,
                            nota: fila.valor,
                            np: fila.np,
                            deUlima: true,
                          )
                        : NotaTile(
                            titulo: fila.titulo,
                            peso: fila.peso,
                            nota: fila.valor,
                            onDelete: () =>
                                onDeleteNota(cursoIndex, fila.indiceSimulada!),
                          ),
                  if (curso[claveUlimaSinPareja] == true)
                    const _SilaboQueNoCoincide(),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// La línea de un curso con evaluaciones de la ULima que no están en el
/// sílabo cargado (D15).
class _SilaboQueNoCoincide extends StatelessWidget {
  const _SilaboQueNoCoincide();

  @override
  Widget build(BuildContext context) {
    final tenue = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.7);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: tenue),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'La ULima publica evaluaciones que no están en el sílabo '
              'cargado. Míralas en Notas oficiales.',
              style: TextStyle(fontSize: 12, color: tenue),
            ),
          ),
        ],
      ),
    );
  }
}
