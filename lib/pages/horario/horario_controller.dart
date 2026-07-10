import 'dart:async';

import 'package:flutter/foundation.dart';
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
  final showAttendance = false.obs;

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
    // El horario es de alumno: sus endpoints /schedule|/sections/me devuelven
    // 403 para un docente. Evitamos disparar esas cargas si hay docente logueado.
    if (AuthService.to.currentUser?.isTeacher ?? false) return;
    _loadDays();
    _loadSecciones();
    _loadAssessments();
    _loadWeeklyLoad();
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

          courses.add({...section, ...horario, 'isEvaluation': false});
        }
        continue;
      }

      final courseDay = (section['dia'] as String? ?? '').toLowerCase();
      if (courseDay == currentDayName) {
        courses.add({...section, 'isEvaluation': false});
      }
    }

    // 2. Buscar evaluaciones para este dia y asociarlas a las clases regulares
    for (var course in courses) {
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

  void toggleAttendance() {
    showAttendance.value = !showAttendance.value;
  }

  List<Map<String, dynamic>> get uniqueEnrolledCourses {
    final uniqueCourses = <String, Map<String, dynamic>>{};

    for (final section in _todasLasSecciones) {
      final sectionIdStr = section['idSeccion']?.toString() ?? '';
      if (sectionIdStr.isNotEmpty && !uniqueCourses.containsKey(sectionIdStr)) {
        uniqueCourses[sectionIdStr] = section;
      }
    }
    
    return uniqueCourses.values.toList();
  }
}
