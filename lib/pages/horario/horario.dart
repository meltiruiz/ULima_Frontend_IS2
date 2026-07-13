import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../descripcion_cursos/descrip_cursos.dart';
import '../teacher/at_risk_students_page.dart';
import 'horario_controller.dart';
import 'horario_list_view.dart';
import '../../components/skeleton.dart';
import '../../services/contacto_service.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/attendance_risk_service.dart';
import '../../models/contacto_model.dart';

class HorarioPage extends StatelessWidget {
  const HorarioPage({super.key});

  static const double startHour = 7.0;
  static const double endHour = 22.0;
  static const double hourHeight = 85.0;

  double _timeToHours(String timeStr) {
    try {
      final cleanStr = timeStr.trim().toLowerCase();

      // If it contains am/pm, use the 12-hour parser
      if (cleanStr.contains('am') || cleanStr.contains('pm')) {
        final parts = cleanStr.split(' ');
        if (parts.length >= 2) {
          final isPm = parts[1] == 'pm';
          final hms = parts[0].split(':');
          int hour = int.tryParse(hms[0]) ?? 12;
          int minute = hms.length > 1 ? (int.tryParse(hms[1]) ?? 0) : 0;

          if (isPm && hour != 12) hour += 12;
          if (!isPm && hour == 12) hour = 0;

          return hour + (minute / 60.0);
        }
      }

      // Try 24-hour parser (e.g., "14:00:00", "14:00")
      final hms = cleanStr.split(':');
      if (hms.isNotEmpty) {
        final hour = int.tryParse(hms[0]);
        if (hour != null) {
          final minute = hms.length > 1 ? (int.tryParse(hms[1]) ?? 0) : 0;
          return hour + (minute / 60.0);
        }
      }

      return 7.0;
    } catch (_) {
      return 7.0;
    }
  }

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

  Widget _currentTimeLine() {
    return IgnorePointer(
      child: SizedBox(
        height: 12,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerLeft,
          children: [
            Positioned(
              left: 0,
              right: 0,
              child: Container(height: 2, color: const Color(0xFFFF5252)),
            ),
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFFFF5252),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HorarioController());
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1E1E26)
          : const Color(0xFFF8F9FA),
      body: Obx(() {
        if (controller.isListView.value) {
          return HorarioListView();
        }

        final activeDay = controller.currentDay;
        if (activeDay == null) {
          // Skeleton con la silueta del horario (selector de días + bloques
          // de clases) en lugar del spinner central.
          return SkeletonPulse(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < 5; i++) ...[
                        const Expanded(
                          child: SkeletonBox(height: 44, borderRadius: 12),
                        ),
                        if (i < 4) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                  const SizedBox(height: 22),
                  for (final alto in const [88.0, 64.0, 110.0, 76.0]) ...[
                    SkeletonBox(
                      width: double.infinity,
                      height: alto,
                      borderRadius: 14,
                    ),
                    const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
          );
        }

        final courses = controller.currentDayCourses;
        final totalHours = (endHour - startHour).toInt() + 1;
        final currentHour = controller.currentLimaHourDecimal;
        final showCurrentTimeLine =
            controller.isCurrentLimaDay(activeDay) &&
            currentHour >= startHour &&
            currentHour <= endHour;
        final currentLineTop = (currentHour - startHour) * hourHeight + 6.0;

        return GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity != null) {
              if (details.primaryVelocity! < 0) {
                controller.nextDay();
              } else if (details.primaryVelocity! > 0) {
                controller.previousDay();
              }
            }
          },
          behavior: HitTestBehavior.translucent,
          child: Column(
            children: [
              Container(
                color: isDark
                    ? const Color(0xFF262630)
                    : const Color(0xFFFFF2EC),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: colors.primary,
                        size: 20,
                      ),
                      onPressed: controller.previousDay,
                    ),
                    Text(
                      '${activeDay.dayName}, ${activeDay.dateText}',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF2D2D2D),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: colors.primary,
                        size: 20,
                      ),
                      onPressed: controller.nextDay,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE5E5E5)),
              Container(
                width: double.infinity,
                color: isDark ? const Color(0xFF1B1B22) : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                child: Text(
                  activeDay.weekText,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFB0B0C0)
                        : const Color(0xFF666666),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE5E5E5)),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Stack(
                      children: [
                        Column(
                          children: List.generate(totalHours, (index) {
                            final hourVal = startHour + index;
                            final isPm = hourVal >= 12;
                            final displayHour = hourVal > 12
                                ? (hourVal - 12).toInt()
                                : hourVal.toInt();
                            final amPm = isPm ? 'pm' : 'am';

                            return SizedBox(
                              height: hourHeight,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 65,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        left: 16,
                                        top: 4,
                                      ),
                                      child: Text(
                                        '$displayHour $amPm',
                                        style: TextStyle(
                                          color: isDark
                                              ? const Color(0xFF9090A0)
                                              : const Color(0xFF9E9E9E),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.only(top: 12),
                                      height: 1.2,
                                      color: isDark
                                          ? const Color(0xFF2C2C38)
                                          : const Color(0xFFECECEC),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                        ...courses.map((course) {
                          final bool isEvaluation =
                              course['isEvaluation'] == true;

                          String nombreStr =
                              (course['curso'] as String? ?? 'CURSO')
                                  .toUpperCase();
                          if (nombreStr.contains(' / ')) {
                            nombreStr = nombreStr.split(' / ').first.trim();
                          } else if (nombreStr.contains('/')) {
                            nombreStr = nombreStr.split('/').first.trim();
                          }
                          final aulaStr =
                              course['salon'] as String? ?? 'Sin salón';
                          final colorStr = course['color'] as String? ?? 'blue';
                          final startStr =
                              course['hora_inicio'] as String? ?? '07:00 am';
                          final endStr =
                              course['hora_fin'] as String? ?? '09:00 am';

                          final startVal = _timeToHours(startStr);
                          final endVal = _timeToHours(endStr);

                          final double topPosition =
                              (startVal - startHour) * hourHeight + 12.0;
                          final double heightVal =
                              (endVal - startVal) * hourHeight - 8.0;

                          final courseColor = _resolveScheduleColor(
                            colorStr,
                            colors,
                          );

                          return Positioned(
                            top: topPosition,
                            left: 75,
                            right: 20,
                            height: heightVal,
                            child: InkWell(
                              onTap: () {
                                final String idSeccion =
                                    course['idSeccion']?.toString() ?? '';
                                final isTeacher =
                                    AuthService.to.currentUser?.isTeacher ??
                                    false;

                                if (isTeacher) {
                                  if (course['isAdvising'] == true) {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          title: Text(
                                            course['codigoSeccion'] ??
                                                'Asesoría',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                course['curso'] ?? '',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.schedule,
                                                    size: 18,
                                                    color: colors.primary,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      "Horario: $startStr - $endStr",
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.place,
                                                    size: 18,
                                                    color: colors.primary,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      "Aula/Canal: $aulaStr",
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (course['fecha'] != null) ...[
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.calendar_month,
                                                      size: 18,
                                                      color: colors.primary,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        "Fecha: ${course['fecha']}",
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Get.back(),
                                              child: const Text(
                                                "Cerrar",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  } else {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(24),
                                        ),
                                      ),
                                      builder: (context) =>
                                          _TeacherCourseDetailSheet(
                                            idSeccion: idSeccion,
                                            courseName: course['curso'] ?? '',
                                            sectionCode:
                                                course['codigoSeccion'] ?? '',
                                          ),
                                    );
                                  }
                                } else {
                                  if (idSeccion.isNotEmpty) {
                                    Get.to(
                                      () => DescripCursosPage(
                                        idSeccion: idSeccion,
                                      ),
                                    );
                                  }
                                }
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: courseColor,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: courseColor.withValues(
                                        alpha: 0.35,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal:
                                              (isEvaluation ||
                                                  course['isAdvising'] == true)
                                              ? 24.0
                                              : 12.0,
                                          vertical: heightVal < 80 ? 4.0 : 12.0,
                                        ),
                                        child: SingleChildScrollView(
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                nombreStr,
                                                textAlign: TextAlign.center,
                                                maxLines: heightVal < 80
                                                    ? 1
                                                    : 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                course['isAdvising'] == true
                                                    ? (course['codigoSeccion'] ??
                                                          'Asesoría')
                                                    : "Sección: ${course['codigoSeccion'] ?? 'Sin sección'}",
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.9),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                aulaStr,
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.9),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (isEvaluation)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.25,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            "📝 EVAL: ${course['evalSigla']}",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (course['isAdvising'] == true)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.25,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: const Text(
                                            "🤝 ASESORÍA",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        if (showCurrentTimeLine)
                          Positioned(
                            top: currentLineTop,
                            left: 75,
                            right: 0,
                            child: _currentTimeLine(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _TeacherCourseDetailSheet extends StatefulWidget {
  final String idSeccion;
  final String courseName;
  final String sectionCode;

  const _TeacherCourseDetailSheet({
    required this.idSeccion,
    required this.courseName,
    required this.sectionCode,
  });

  @override
  State<_TeacherCourseDetailSheet> createState() =>
      _TeacherCourseDetailSheetState();
}

class _TeacherCourseDetailSheetState extends State<_TeacherCourseDetailSheet> {
  bool _isLoading = true;
  String? _errorMessage;
  String _delegateName = 'No asignado';
  String _subdelegateName = 'No asignado';
  List<dynamic> _assessments = [];
  int _atRiskCount = 0;
  final Set<String> _notifiedAssessments = {};

  Future<void> _confirmAndNotify(
    String assessmentId,
    String assessmentName,
    int loadedCount,
    int totalCount,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notificar Publicación de Notas'),
        content: Text(
          '¿Deseas enviar una alerta a todos los alumnos de la sección indicando que las notas de "$assessmentName" han sido publicadas?\n\nAlumnos calificados: $loadedCount / $totalCount',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final res = await ApiClient().postJson(
          '/schedule/teacher/sections/${widget.idSeccion}/assessments/$assessmentId/notify-grades',
          body: {},
        );
        if (res['ok'] == true) {
          if (mounted) {
            setState(() {
              _notifiedAssessments.add(assessmentId);
            });
          }
          Get.snackbar(
            'Notificación enviada',
            'Se alertó a los ${res['notifiedCount'] ?? 'todos los'} alumnos de la sección.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          if (mounted) {
            setState(() {
              _notifiedAssessments.remove(assessmentId);
            });
          }
          Get.snackbar(
            'Error',
            'No se pudo enviar la notificación.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _notifiedAssessments.remove(assessmentId);
          });
        }
        debugPrint('Error notifying grades: $e');
        Get.snackbar(
          'Error',
          'Ocurrió un error al intentar notificar.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } else {
      if (mounted) {
        setState(() {
          _notifiedAssessments.remove(assessmentId);
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final isTeacher = AuthService.to.currentUser?.isTeacher ?? false;
    try {
      // Cada llamada se blinda por separado: si UNA falla, devuelve vacío y la
      // pantalla igual carga lo que sí pudo (antes un solo 404 tumbaba todo el
      // detalle con "Error al cargar detalles de la sección").
      final contactsFuture = ContactoService()
          .fetchContactos(widget.idSeccion)
          .catchError((e) {
        debugPrint('detalle: contactos falló: $e');
        return const ContactosCursoResult.empty();
      });
      // Endpoints exclusivos para docentes: no se llaman si el usuario es alumno.
      final assessmentsFuture = isTeacher
          ? ApiClient()
              .getJson(
                '/schedule/teacher/sections/${widget.idSeccion}/assessments-status',
              )
              .catchError((e) {
              debugPrint('detalle: assessments-status falló: $e');
              return <String, dynamic>{};
            })
          : Future.value(<String, dynamic>{});
      final atRiskFuture = isTeacher
          ? AttendanceRiskService()
              .fetchSummary(widget.idSeccion)
              .catchError((e) {
              debugPrint('detalle: attendance-risk falló: $e');
              return <String, dynamic>{};
            })
          : Future.value(<String, dynamic>{});

      final results = await Future.wait([
        contactsFuture,
        assessmentsFuture,
        atRiskFuture,
      ]);
      final contacts = results[0] as ContactosCursoResult;
      final assessmentsData = results[1] as Map<String, dynamic>;
      final atRiskData = results[2] as Map<String, dynamic>;
      final summary = atRiskData['summary'] as Map<String, dynamic>?;
      final impedido = (summary?['impedido'] as num?)?.toInt() ?? 0;
      final enRiesgo = (summary?['en_riesgo'] as num?)?.toInt() ?? 0;
      _atRiskCount = impedido + enRiesgo;

      for (final contact in contacts.alumnos) {
        final role = contact.roleInSection;
        final fullName = contact.user.fullName;
        if (role == 'delegado') {
          _delegateName = fullName;
        } else if (role == 'subdelegado') {
          _subdelegateName = fullName;
        }
      }

      _assessments = assessmentsData['assessments'] ?? [];

      // Inicializar el estado de notificaci\u00f3n desde el backend
      // (persiste aunque el alumno cierre sesi\u00f3n y vuelva a abrir la vista)
      final notified = <String>{};
      for (final ass in _assessments) {
        if (ass['isNotified'] == true) {
          final id = ass['id']?.toString();
          if (id != null) notified.add(id);
        }
      }

      if (mounted) {
        setState(() {
          _notifiedAssessments.addAll(notified);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error al cargar detalles de la sección';
        });
      }
      debugPrint('Error loading teacher course details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262630) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF4C4C5C)
                      : const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.courseName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF2D2D2D),
                    ),
                  ),
                ),
                _isLoading
                    ? const SizedBox(width: 48, height: 48)
                    : Badge(
                        isLabelVisible: _atRiskCount > 0,
                        label: Text(
                          '$_atRiskCount',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        smallSize: 20,
                        child: IconButton(
                          icon: Icon(
                            Icons.warning_amber_rounded,
                            color: _atRiskCount > 0
                                ? Colors.orange
                                : Colors.grey,
                            size: 24,
                          ),
                          tooltip: 'Alumnos impedidos y en riesgo',
                          onPressed: () {
                            Get.to(
                              () => AtRiskStudentsPage(
                                sectionId: widget.idSeccion,
                                courseName: widget.courseName,
                                sectionCode: widget.sectionCode,
                              ),
                            );
                          },
                        ),
                      ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Sección ${widget.sectionCode}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            else ...[
              _infoRow(context, Icons.person, 'Delegado', _delegateName),
              const SizedBox(height: 8),
              _infoRow(
                context,
                Icons.person_outline,
                'Subdelegado',
                _subdelegateName,
              ),
              const SizedBox(height: 18),
              Text(
                'Estado de carga de notas:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 8),
              if (_assessments.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No hay evaluaciones programadas en el sílabo.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? const Color(0xFF9090A0)
                          : const Color(0xFF666666),
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _assessments.length,
                    itemBuilder: (context, index) {
                      final ass = _assessments[index];
                      final code = ass['code'] ?? '';
                      final name = ass['name'] ?? '';



                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$code: $name',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF2D2D2D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: _notifiedAssessments.contains(
                                  ass['id']?.toString(),
                                ),
                                onChanged: (val) {
                                  final assId = ass['id']?.toString() ?? '';
                                  if (val) {
                                    // Activar: marcar optimistamente y pedir confirmaci\u00f3n
                                    setState(() => _notifiedAssessments.add(assId));
                                    _confirmAndNotify(
                                      assId,
                                      ass['name'] ?? '',
                                      (ass['loadedCount'] as num?)?.toInt() ?? 0,
                                      (ass['totalCount'] as num?)?.toInt() ?? 0,
                                    );
                                  } else {
                                    // Desactivar: solo visual, sin llamada al backend
                                    setState(() => _notifiedAssessments.remove(assId));
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String title,
    String value,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          '$title: ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFB0B0C0) : const Color(0xFF666666),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF2D2D2D),
            ),
          ),
        ),
      ],
    );
  }
}
