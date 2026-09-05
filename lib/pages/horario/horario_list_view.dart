import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'horario_controller.dart';
import '../chat/chat_page.dart';
import '../../configs/themes.dart';

/// Lista de CHATS de los cursos del alumno. Misma estructura de tarjeta que el
/// docente (ver TeacherSectionsPage) para que el diseño sea uniforme: tile con
/// icono, nombre + sección y acceso al chat. Tocar la tarjeta abre el chat.
/// Conserva el color por-curso (acento) que ya usa el horario.
class HorarioListView extends StatelessWidget {
  final HorarioController controller = Get.find();

  HorarioListView({super.key});

  static const List<DeviceOrientation> _scheduleOrientations = [
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];
  static const List<DeviceOrientation> _portraitOnly = [
    DeviceOrientation.portraitUp,
  ];

  /// Color del curso: resuelve el hex del backend (#RRGGBB / RRGGBB / AARRGGBB)
  /// o, como fallback, un nombre de color. Es el acento por-curso de cada card.
  Color _resolveScheduleColor(String colorStr, ColorScheme colors) {
    final cleanColor = colorStr.trim();
    final hexColor = cleanColor.startsWith('#')
        ? cleanColor.substring(1)
        : cleanColor;

    if (RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hexColor)) {
      return Color(int.parse('FF$hexColor', radix: 16));
    }
    if (RegExp(r'^[0-9a-fA-F]{8}$').hasMatch(hexColor)) {
      return Color(int.parse(hexColor, radix: 16));
    }

    return {
          'pink': colors.secondaryContainer,
          'blue': colors.secondary,
          'orange': colors.primary,
          'green': colors.tertiaryContainer,
          'purple': colors.tertiary,
          'teal': colors.primaryContainer,
          'red': colors.error,
        }[cleanColor.toLowerCase()] ??
        colors.outline;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Obx(() {
      final uniqueCourses = controller.uniqueEnrolledCourses;

      return Column(
        children: [
          // Sub-header: back (vuelve al calendario) + título. Ya no hay ojo de
          // asistencia: esta pantalla es solo de chats.
          Container(
            color: isDark ? const Color(0xFF262630) : const Color(0xFFFFF2EC),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: colors.primary),
                  onPressed: controller.toggleListView,
                  tooltip: 'Volver',
                ),
                Expanded(
                  child: Text(
                    'Mis chats',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: MaterialTheme.textPrimary(brightness),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                // Espaciador simétrico al IconButton del back para centrar bien.
                const SizedBox(width: 48),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: MaterialTheme.borderColor(brightness),
          ),

          Expanded(
            child: uniqueCourses.isEmpty
                ? _EmptyCourses(brightness: brightness)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: uniqueCourses.length,
                    itemBuilder: (context, index) {
                      final course = uniqueCourses[index];
                      final courseColor = _resolveScheduleColor(
                        course['color']?.toString() ?? 'blue',
                        colors,
                      );
                      final nombre = (course['curso'] as String? ?? 'CURSO')
                          .toUpperCase();
                      final seccion =
                          course['codigoSeccion']?.toString() ?? 'Sin sección';
                      final idSeccion = course['idSeccion']?.toString() ?? '';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ChatCourseCard(
                          brightness: brightness,
                          courseColor: courseColor,
                          nombre: nombre,
                          seccion: seccion,
                          onOpenChat: idSeccion.isEmpty
                              ? null
                              : () async {
                                  await SystemChrome.setPreferredOrientations(
                                    _portraitOnly,
                                  );
                                  await Get.to(
                                    () => ChatPage(
                                      sectionId: idSeccion,
                                      courseName: nombre,
                                    ),
                                  );
                                  await SystemChrome.setPreferredOrientations(
                                    _scheduleOrientations,
                                  );
                                },
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    });
  }
}

/// Tarjeta de chat de un curso (alumno). Estructura uniforme con la del docente:
/// tile con icono, nombre + sección y un icono de chat. Toda la tarjeta abre el
/// chat. El color del curso se usa como acento (tile, sección e icono de chat).
class _ChatCourseCard extends StatelessWidget {
  const _ChatCourseCard({
    required this.brightness,
    required this.courseColor,
    required this.nombre,
    required this.seccion,
    required this.onOpenChat,
  });

  final Brightness brightness;
  final Color courseColor;
  final String nombre;
  final String seccion;
  final VoidCallback? onOpenChat;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onOpenChat,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MaterialTheme.cardBg(brightness),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MaterialTheme.borderColor(brightness)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: courseColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.menu_book_rounded,
                color: courseColor,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: MaterialTheme.textPrimary(brightness),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Sección $seccion',
                    style: TextStyle(
                      color: courseColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.forum_rounded, size: 22, color: courseColor),
          ],
        ),
      ),
    );
  }
}

class _EmptyCourses extends StatelessWidget {
  const _EmptyCourses({required this.brightness});
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 48,
              color: MaterialTheme.textMuted(brightness),
            ),
            const SizedBox(height: 12),
            Text(
              'No hay cursos matriculados.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: MaterialTheme.textSecondary(brightness),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
