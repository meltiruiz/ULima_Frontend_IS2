// lib/pages/academic_record/record_course_row.dart
// La fila de un curso del récord académico (RF-REC-3): el nombre, la etiqueta
// "N.ª vez", "código · N créd.", la observación y el chip de nota.
//
// La decisión del chip y la de la etiqueta son funciones puras de nivel
// superior para poder probarlas sin montar widgets, igual que
// HorarioPage.blockMetaLines y HorarioPage.blockGeometry
// (lib/pages/horario/horario.dart:56-82), que la spec cita como modelo.

import 'package:flutter/material.dart';

import '../../configs/themes.dart';
import '../../models/academic_record_model.dart';
import 'record_format.dart';

/// Los cinco tonos del chip de nota de RF-REC-3.
enum RecordChipTone { green, amber, red, blue, neutral }

/// Lo que se pinta en el chip: de qué color va y qué dice.
typedef RecordChip = ({RecordChipTone tone, String label});

/// Los seis casos de la tabla de RF-REC-3, en un solo lugar.
///
/// El orden importa: la nota manda. Un curso con nota es verde, ámbar o rojo
/// aunque esté en el ciclo más reciente; recién cuando no hay nota entra en
/// juego `gradeRaw` (la marca del portal: convalidación, retiro u otra) y,
/// si tampoco la hay, el ciclo decide entre "En curso" y una raya.
///
/// Un curso del ciclo en curso sin nota NUNCA sale azul: el azul es el color
/// de las marcas del portal, y ese ciclo es el que el alumno ve primero.
RecordChip recordChipFor({
  required int? grade,
  required String? gradeRaw,
  required bool isMostRecentPeriod,
}) {
  if (grade != null) {
    // Las notas de un dígito llevan cero delante ("08"), como en la maqueta
    // aprobada: así todos los chips miden lo mismo en la columna.
    final label = grade.toString().padLeft(2, '0');
    if (grade >= 14) return (tone: RecordChipTone.green, label: label);
    if (grade >= 11) return (tone: RecordChipTone.amber, label: label);
    return (tone: RecordChipTone.red, label: label);
  }
  // Un gradeRaw en blanco no es una marca del portal: es un dato que no vino.
  final raw = gradeRaw?.trim() ?? '';
  if (raw.isNotEmpty) return (tone: RecordChipTone.blue, label: raw);
  return isMostRecentPeriod
      ? (tone: RecordChipTone.neutral, label: RecordCourseRow.inProgressLabel)
      : (tone: RecordChipTone.neutral, label: RecordCourseRow.noGradeLabel);
}

/// Colores del chip. Todos salen de la paleta que el repo ya usa.
///
/// Verde y rojo son los de la nota final de /mis-notas
/// (mis_notas_page.dart:209), el ámbar es el del curso en curso de la malla
/// (malla_models.dart:23 y :37), el azul es el del chip de interés del Perfil
/// (perfil.dart:594-596) y el neutro es el de la insignia "Fija"
/// (perfil.dart:273-297).
({Color background, Color foreground}) recordChipColors(
  RecordChipTone tone,
  Brightness brightness,
) {
  switch (tone) {
    case RecordChipTone.green:
      return (
        background: const Color(0xFF16A34A).withValues(alpha: 0.12),
        foreground: const Color(0xFF16A34A),
      );
    case RecordChipTone.amber:
      return (
        background: const Color(0xFFF59E0B).withValues(alpha: 0.15),
        foreground: const Color(0xFFD97706),
      );
    case RecordChipTone.red:
      return (
        background: const Color(0xFFDC2626).withValues(alpha: 0.12),
        foreground: const Color(0xFFDC2626),
      );
    case RecordChipTone.blue:
      return (
        background: MaterialTheme.espInteresBg(brightness),
        foreground: brightness == Brightness.light
            ? const Color(0xFF0369A1)
            : const Color(0xFF38BDF8),
      );
    case RecordChipTone.neutral:
      return (
        background: MaterialTheme.tagBg(brightness),
        foreground: MaterialTheme.labelColor(brightness),
      );
  }
}

/// "2.ª vez" desde la segunda matrícula; en la primera no hay etiqueta.
///
/// Con `attempt` nulo tampoco: un dato que no vino no se convierte en "1.ª
/// vez" ni en nada.
String? attemptLabel(int? attempt) =>
    (attempt != null && attempt >= 2) ? '$attempt.ª vez' : null;

/// "100002 · 1.5 créd.", o solo el código si no vinieron los créditos.
String courseSubtitle({required String code, required double? credits}) =>
    credits == null ? code : '$code · ${creditsShortLabel(credits)}';

/// Un curso del récord, tal como llegó del portal.
///
/// El código y el nombre se muestran sin tocarlos y sin cruzarlos con la malla
/// vigente: los cursos de mallas anteriores conservan los suyos (RF-REC-3).
///
/// Quién es el ciclo más reciente lo decide la pantalla, no la fila: por eso
/// [isMostRecentPeriod] entra como parámetro.
class RecordCourseRow extends StatelessWidget {
  const RecordCourseRow({
    super.key,
    required this.course,
    required this.isMostRecentPeriod,
  });

  final RecordCourse course;
  final bool isMostRecentPeriod;

  /// Chip neutro del ciclo en curso: el curso todavía no tiene nota.
  static const String inProgressLabel = 'En curso';

  /// Chip neutro de un ciclo viejo que se quedó sin nota y sin marca.
  static const String noGradeLabel = '—';

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.brightnessOf(context);
    final chip = recordChipFor(
      grade: course.grade,
      gradeRaw: course.gradeRaw,
      isMostRecentPeriod: isMostRecentPeriod,
    );
    final colors = recordChipColors(chip.tone, brightness);
    final intento = attemptLabel(course.attempt);
    final observation = course.observation;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Wrap y no Row: con un nombre largo, la etiqueta "N.ª vez"
                // baja a la línea siguiente en vez de desbordar.
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      course.name,
                      style: TextStyle(
                        color: MaterialTheme.textPrimary(brightness),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (intento != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: MaterialTheme.tagBg(brightness),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          intento,
                          style: TextStyle(
                            color: MaterialTheme.labelColor(brightness),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  courseSubtitle(code: course.code, credits: course.credits),
                  style: TextStyle(
                    color: MaterialTheme.textMuted(brightness),
                    fontSize: 12,
                  ),
                ),
                if (observation != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      observation,
                      style: TextStyle(
                        color: MaterialTheme.textMuted(brightness),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            constraints: const BoxConstraints(minWidth: 40),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              chip.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.foreground,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
