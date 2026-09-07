import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/at_risk_student_model.dart';
import 'package:ulima_plus/services/attendance_risk_service.dart';

enum SortMode { absenceDesc, absenceAsc, lastNameAsc }
enum FilterMode { all, impedido, enRiesgo, normal }

class AtRiskStudentsController extends GetxController {
  final AttendanceRiskService _service = AttendanceRiskService();

  final RxList<AtRiskStudent> allStudents = <AtRiskStudent>[].obs;
  final RxList<AtRiskStudent> filteredStudents = <AtRiskStudent>[].obs;
  final RxBool isLoading = true.obs;
  // Distingue "falló la carga" de "sección sin alumnos" (HU22): antes un fallo
  // del endpoint se veía como "No se encontraron alumnos" (falso negativo).
  final RxBool loadError = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString courseName = ''.obs;
  final RxString sectionCode = ''.obs;
  final Rx<SortMode> sortMode = SortMode.absenceDesc.obs;
  final Rx<FilterMode> filterMode = FilterMode.all.obs;
  String _sectionId = '';

  int get impedidoCount => allStudents.where((s) => s.isImpedido).length;
  int get enRiesgoCount => allStudents.where((s) => s.isEnRiesgo).length;
  int get normalCount => allStudents.where((s) => s.isNormal).length;
  /// Matrículas sin asistencia cargada. NO se suman a `normalCount`.
  int get sinDatosCount => allStudents.where((s) => s.isSinDatos).length;

  @override
  void onInit() {
    super.onInit();
    debounce(
      searchQuery,
      (_) => _applyFilter(),
      time: const Duration(milliseconds: 300),
    );
  }

  Future<void> loadData(String sectionId) async {
    try {
      _sectionId = sectionId;
      isLoading.value = true;
      final students = await _service.fetchAttendanceRisk(sectionId);
      allStudents.value = students;
      _applyFilter();
      loadError.value = false;
    } catch (e) {
      debugPrint('Error loading at-risk students: $e');
      loadError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  /// Reintenta la carga (botón "Reintentar" del estado de error).
  Future<void> retry() => loadData(_sectionId);

  @override
  Future<void> refresh() async {
    await loadData(_sectionId);
  }

  void setCourseInfo(String name, String code) {
    courseName.value = name;
    sectionCode.value = code;
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
  }

  void setSortMode(SortMode mode) {
    sortMode.value = mode;
    _applyFilter();
  }

  void setFilterMode(FilterMode mode) {
    filterMode.value = mode;
    _applyFilter();
  }

  Future<void> exportCsv() async {
    await _service.exportCsv(allStudents, courseName.value, sectionCode.value);
  }

  Future<bool> notifyStudents() async {
    final success = await _service.notifyStudents(_sectionId);
    if (success) {
      Get.snackbar(
        'Notificaciones enviadas',
        'Se notifico a los alumnos en riesgo de la seccion ${sectionCode.value}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      await refresh();
    } else {
      Get.snackbar(
        'Error',
        'No se pudieron enviar las notificaciones',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
    return success;
  }

  void _applyFilter() {
    var result = List<AtRiskStudent>.from(allStudents);

    final query = searchQuery.value.toLowerCase().trim();
    if (query.isNotEmpty) {
      result = result.where((s) {
        return s.code.toLowerCase().contains(query) ||
            s.lastName.toLowerCase().contains(query);
      }).toList();
    }

    switch (filterMode.value) {
      case FilterMode.impedido:
        result = result.where((s) => s.isImpedido).toList();
      case FilterMode.enRiesgo:
        result = result.where((s) => s.isEnRiesgo).toList();
      case FilterMode.normal:
        result = result.where((s) => s.isNormal).toList();
      case FilterMode.all:
        break;
    }

    switch (sortMode.value) {
      case SortMode.absenceDesc:
        result.sort((a, b) => _byAbsence(b, a));
      case SortMode.absenceAsc:
        result.sort((a, b) => _byAbsence(a, b));
      case SortMode.lastNameAsc:
        result.sort((a, b) => a.lastName.compareTo(b.lastName));
    }

    filteredStudents.value = result;
  }

  /// Ordena por % de ausencia dejando SIEMPRE al final a quien no tiene dato.
  /// Un null no es un 0: sin esta guarda, las matrículas sin medir aparecían
  /// primeras en el orden ascendente como si fueran las de mejor asistencia.
  static int _byAbsence(AtRiskStudent x, AtRiskStudent y) {
    final a = x.absencePercentage;
    final b = y.absencePercentage;
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }
}
