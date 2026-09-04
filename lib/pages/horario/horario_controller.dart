import 'dart:async';
import 'package:flutter/material.dart';
import '../../configs/course_colors.dart';

import 'package:get/get.dart';

import '../../services/api_client.dart';
import '../../services/auth_service.dart';

class DaySchedule {
  final String dayName;
  final String dateText;
  final String weekText;

  DaySchedule(this.dayName, this.dateText, this.weekText);
}

class HorarioController extends GetxController {
  final currentDayIndex = 0.obs;
  final daysList = <DaySchedule>[].obs;
  final assessmentsList = <Map<String, dynamic>>[].obs;
  final weeklyLoad = <Map<String, dynamic>>[].obs;
  final currentLimaTime = _nowInLima().obs;
  
  // Nuevos estados para el rediseño de Horario (Lista / Calendario)
  final isListView = false.obs;

  final _todasLasSecciones = <Map<String, dynamic>>[].obs;
  final ApiClient _api = ApiClient();
  Timer? _clockTimer;

  static const List<String> _months = [
    "Enero",
    "Febrero",
    "Marzo",
    "Abril",
    "Mayo",
    "Junio",
    "Julio",
    "Agosto",
    "Septiembre",
    "Octubre",
    "Noviembre",
    "Diciembre",
  ];

  static DateTime _nowInLima() =>
      DateTime.now().toUtc().subtract(const Duration(hours: 5));

  static String _dateTextFor(DateTime date) =>
      "${date.day} de ${_months[date.month - 1]}";

  @override
  void onInit() {
    super.onInit();
    _startClock();
    final isTeacher = AuthService.to.currentUser?.isTeacher ?? false;
    if (isTeacher) {
      _loadTeacherDaysAndSessions();
      _loadTeacherAssessments();
    } else {
      _loadDays();
      _loadSecciones();
      _loadAssessments();
      _loadWeeklyLoad();
    }
  }

  /// Recarga los datos del horario (sesiones + evaluaciones).
  /// Llamado por [HomePage] al cambiar al tab del horario para reflejar
  /// asesorías o cambios recientes sin destruir el controller.
  Future<void> reload() async {
    final isTeacher = AuthService.to.currentUser?.isTeacher ?? false;
    if (isTeacher) {
      await Future.wait([
        _loadTeacherDaysAndSessions(),
        _loadTeacherAssessments(),
      ]);
    } else {
      await Future.wait([
        _loadDays(),
        _loadSecciones(),
        _loadAssessments(),
      ]);
    }
  }

  @override
  void onClose() {
    _clockTimer?.cancel();
    super.onClose();
  }

  void _startClock() {
    currentLimaTime.value = _nowInLima();
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      currentLimaTime.value = _nowInLima();
    });
  }

  Future<void> _loadDays() async {
    try {
      final code = AuthService.to.currentUser?.code;
      final data = await _api.getJson(
        '/schedule/me/sessions${code == null ? '' : '?code=$code'}',
      );
      final List<dynamic> decoded = data['days'] ?? [];
      daysList.assignAll(
        decoded
            .map(
              (d) => DaySchedule(
                d['dayName'] as String,
                d['dateText'] as String,
                d['weekText'] as String,
              ),
            )
            .toList(),
      );

      // Intentar buscar el día actual por fecha
      final todayStr = _dateTextFor(currentLimaTime.value);

      int idx = daysList.indexWhere(
        (d) => d.dateText.toLowerCase() == todayStr.toLowerCase(),
      );
      if (idx == -1) {
        // Fallback al primer viernes si no se encuentra el día exacto
        idx = daysList.indexWhere((d) => d.dayName == 'Viernes');
      }
      currentDayIndex.value = idx != -1 ? idx : 0;
    } catch (e) {
      debugPrint('Error al cargar dias: $e');
    }
  }

  Future<void> _loadSecciones() async {
    try {
      final code = AuthService.to.currentUser?.code;
      final data = await _api.getJson(
        '/schedule/me/sessions${code == null ? '' : '?code=$code'}',
      );
      _todasLasSecciones.assignAll(
        (data['secciones'] as List? ?? [])
            .map((item) => Map<String, dynamic>.from(item))
            .toList(),
      );
    } catch (e) {
      debugPrint('Error al cargar secciones: $e');
    }
  }

  Future<void> _loadAssessments() async {
    try {
      final code = AuthService.to.currentUser?.code;
      final data = await _api.getJson(
        '/schedule/me/assessments${code == null ? '' : '?code=$code'}',
      );
      assessmentsList.assignAll(
        List<Map<String, dynamic>>.from(data['assessments'] ?? []),
      );
      update();
    } catch (e) {
      debugPrint('Error al cargar evaluaciones: $e');
    }
  }

  Future<void> _loadWeeklyLoad() async {
    try {
      final code = AuthService.to.currentUser?.code;
      final data = await _api.getJson(
        '/schedule/me/load${code == null ? '' : '?code=$code'}',
      );
      weeklyLoad.assignAll(
        (data['weeks'] as List? ?? [])
            .map((item) => Map<String, dynamic>.from(item))
            .toList(),
      );
      update();
    } catch (e) {
      debugPrint('Error al cargar carga semanal: $e');
    }
  }

  Future<void> _loadTeacherDaysAndSessions() async {
    try {
      final data = await _api.getJson('/schedule/teacher/sessions');
      final List<dynamic> decoded = data['days'] ?? [];
      daysList.assignAll(
        decoded
            .map(
              (d) => DaySchedule(
                d['dayName'] as String,
                d['dateText'] as String,
                d['weekText'] as String,
              ),
            )
            .toList(),
      );

      _todasLasSecciones.assignAll(
        (data['secciones'] as List? ?? [])
            .map((item) => Map<String, dynamic>.from(item))
            .toList(),
      );

      final todayStr = _dateTextFor(currentLimaTime.value);
      int idx = daysList.indexWhere(
        (d) => d.dateText.toLowerCase() == todayStr.toLowerCase(),
      );
      if (idx == -1) {
        idx = daysList.indexWhere((d) => d.dayName == 'Viernes');
      }
      currentDayIndex.value = idx != -1 ? idx : 0;
    } catch (e) {
      debugPrint('Error al cargar dias y sesiones del docente: $e');
    }
  }

  Future<void> _loadTeacherAssessments() async {
    try {
      final data = await _api.getJson('/schedule/teacher/assessments');
      assessmentsList.assignAll(
        List<Map<String, dynamic>>.from(data['assessments'] ?? []),
      );
      update();
    } catch (e) {
      debugPrint('Error al cargar evaluaciones del docente: $e');
    }
  }

  DaySchedule? get currentDay =>
      daysList.isEmpty ? null : daysList[currentDayIndex.value];

  bool isCurrentLimaDay(DaySchedule day) =>
      day.dateText.toLowerCase() ==
      _dateTextFor(currentLimaTime.value).toLowerCase();

  double get currentLimaHourDecimal {
    final now = currentLimaTime.value;
    return now.hour + (now.minute / 60.0) + (now.second / 3600.0);
  }

  List<Map<String, dynamic>> get currentDayCourses {
    final activeDay = currentDay;
    if (activeDay == null) return const [];

    final currentDayName = activeDay.dayName.toLowerCase();
    final courses = <Map<String, dynamic>>[];

    // 1. Agregar las clases regulares
    for (final section in _todasLasSecciones) {
      final horarios = section['horarios'];
      if (horarios is List && horarios.isNotEmpty) {
        for (final rawHorario in horarios) {
          if (rawHorario is! Map) continue;
          final horario = Map<String, dynamic>.from(rawHorario);
          final courseDay = (horario['dia'] as String? ?? '').toLowerCase();
          if (courseDay != currentDayName) continue;

          // Si tiene una fecha (asesorías extra), verificar que coincida con el día activo
          final dateStr = horario['fecha'] as String?;
          if (dateStr != null && dateStr.isNotEmpty) {
            final parsedDate = DateTime.tryParse(dateStr);
            if (parsedDate != null) {
              final dayNum = parsedDate.day;
              final monthIdx = parsedDate.month - 1;
              if (monthIdx >= 0 && monthIdx < 12) {
                final formattedDate = "$dayNum de ${_months[monthIdx]}";
                if (formattedDate.toLowerCase().trim() != activeDay.dateText.toLowerCase().trim()) {
                  continue;
                }
              }
            }
          }

          courses.add({
            ...section,
            ...horario,
            'isEvaluation': false,
            'isAdvising': section['isAdvising'] == true
          });
        }
        continue;
      }

      final courseDay = (section['dia'] as String? ?? '').toLowerCase();
      if (courseDay == currentDayName) {
        courses.add({
          ...section,
          'isEvaluation': false,
          'isAdvising': section['isAdvising'] == true
        });
      }
    }

    // 2. Buscar evaluaciones para este dia y asociarlas a las clases regulares
    for (var course in courses) {
      if (course['isAdvising'] == true) continue;
      final sectionCode = course['codigoSeccion']?.toString().trim() ?? '';
      final courseName = course['curso']?.toString().toLowerCase().trim() ?? '';

      for (final assessment in assessmentsList) {
        final dateStr = assessment['date'] as String? ?? '';
        final parsedDate = DateTime.tryParse(dateStr);
        if (parsedDate != null) {
          final dayNum = parsedDate.day;
          final monthIdx = parsedDate.month - 1;
          if (monthIdx >= 0 && monthIdx < 12) {
            final formattedDate = "$dayNum de ${_months[monthIdx]}";
            final dateMatches = formattedDate.toLowerCase().trim() == activeDay.dateText.toLowerCase().trim();
            
            final evalSectionCode = assessment['sectionCode']?.toString().trim() ?? '';
            final evalCourseName = assessment['courseName']?.toString().toLowerCase().trim() ?? '';
            
            final matchesCourse = (evalSectionCode.isNotEmpty && evalSectionCode == sectionCode) ||
                                  (evalCourseName.isNotEmpty && evalCourseName == courseName);

            if (dateMatches && matchesCourse) {
              course['isEvaluation'] = true;
              course['evalSigla'] = assessment['code'] ?? '';
              course['evalNombre'] = assessment['name'] ?? '';
              debugPrint("--> MERGED! Set isEvaluation = true for course: ${course['curso']} (${assessment['code']})");
              break; // Encontrado para esta clase
            }
          }
        }
      }
    }

    return courses;
  }

  void previousDay() {
    if (daysList.isEmpty) return;
    if (currentDayIndex.value > 0) {
      currentDayIndex.value--;
    } else {
      currentDayIndex.value = daysList.length - 1;
    }
  }

  void nextDay() {
    if (daysList.isEmpty) return;
    if (currentDayIndex.value < daysList.length - 1) {
      currentDayIndex.value++;
    } else {
      currentDayIndex.value = 0;
    }
  }

  void toggleListView() {
    isListView.value = !isListView.value;
  }

  /// Color final de cada sección del alumno, ya sin repetidos.
  ///
  /// El backend guarda el color en `schedule_session`, fila que comparten todos
  /// los alumnos de la sección, así que no puede saber qué otros cursos lleva
  /// cada uno: dos cursos distintos pueden traer el mismo color. Pasa de verdad
  /// (en 2026-2, Seguridad de Sistemas y Paradigmas traen el mismo índigo), y
  /// por eso el desempate se hace acá, sobre el horario completo del alumno.
  ///
  /// Se calcula sobre TODAS las secciones y no sobre el día visible, para que un
  /// curso no cambie de color al pasar de lunes a martes. Las claves se ordenan
  /// para que el reparto sea estable entre recargas.
  Map<String, Color> get colorPorCurso {
    final claves = <String>[];
    final hexPorClave = <String, String?>{};

    for (final section in _todasLasSecciones) {
      if (section['isAdvising'] == true) continue;
      final id = section['idSeccion']?.toString() ?? '';
      if (id.isEmpty || hexPorClave.containsKey(id)) continue;

      // El color vive en el horario, no en la sección: a nivel de sección suele
      // venir un naranja por defecto que no distingue cursos.
      String? hex;
      final horarios = section['horarios'];
      if (horarios is List) {
        for (final h in horarios) {
          final c = (h is Map ? h['color']?.toString() : null)?.trim();
          if (c != null && c.isNotEmpty) {
            hex = c;
            break;
          }
        }
      }
      hexPorClave[id] = hex;
      claves.add(id);
    }

    claves.sort();
    return asignarColoresSinRepetir(claves, (k) => hexPorClave[k]);
  }

  List<Map<String, dynamic>> get uniqueEnrolledCourses {
    final uniqueCourses = <String, Map<String, dynamic>>{};

    for (final section in _todasLasSecciones) {
      if (section['isAdvising'] == true) continue;
      final sectionIdStr = section['idSeccion']?.toString() ?? '';
      if (sectionIdStr.isNotEmpty && !uniqueCourses.containsKey(sectionIdStr)) {
        // El color real del curso vive en cada horario (schedule_session.color_hex),
        // no a nivel de sección (ahí suele venir un default naranja). El calendario
        // ya usa el del horario; aquí replicamos eso para que la lista tenga los
        // mismos colores por curso.
        final entry = Map<String, dynamic>.from(section);
        final horarios = section['horarios'];
        if (horarios is List) {
          for (final h in horarios) {
            final hColor = (h is Map ? h['color']?.toString() : null)?.trim();
            if (hColor != null && hColor.isNotEmpty) {
              entry['color'] = hColor;
              break;
            }
          }
        }
        uniqueCourses[sectionIdStr] = entry;
      }
    }

    return uniqueCourses.values.toList();
  }
}
