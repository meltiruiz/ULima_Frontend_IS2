import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../domain/notas/notas_calculo.dart' as notas_calculo;
import '../../models/official_grades_models.dart';
import '../../services/official_grades_service.dart';

/// Grilla de calificación de una sección (el profesor pone las notas).
class TeacherGradeSectionController extends GetxController {
  TeacherGradeSectionController({OfficialGradesService? service})
      : _service = service ?? OfficialGradesService();

  final OfficialGradesService _service;

  late final int sectionId;
  late final String title;

  final grid = Rxn<SectionGrid>();
  final isLoading = false.obs;
  final loadError = RxnString();
  final isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    sectionId = (args is Map && args['sectionId'] is int) ? args['sectionId'] as int : 0;
    title = (args is Map && args['title'] is String) ? args['title'] as String : 'Calificar';
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    loadError.value = null;
    try {
      grid.value = await _service.fetchSectionGrid(sectionId);
    } catch (e) {
      loadError.value = 'No se pudo cargar la sección.';
      debugPrint('Error cargando grilla de calificación: $e');
    } finally {
      isLoading.value = false;
    }
  }

  double? scoreFor(int enrollmentId, int assessmentId) =>
      grid.value?.scores[SectionGrid.scoreKey(enrollmentId, assessmentId)];

  bool hasAnyScore(int enrollmentId) {
    final g = grid.value;
    if (g == null) return false;
    return g.assessments.any((a) => scoreFor(enrollmentId, a.assessmentId) != null);
  }

  /// Nota final (promedio ponderado) del alumno con lo ya calificado.
  double finalFor(int enrollmentId) {
    final g = grid.value;
    if (g == null) return 0;
    final entries = g.assessments
        .map((a) => {'valor': scoreFor(enrollmentId, a.assessmentId) ?? 0, 'peso': a.weight})
        .toList();
    return notas_calculo.calcularPromedioPonderado(entries);
  }

  /// Guarda (upsert) las notas editadas de un alumno. `values`: assessmentId -> nota.
  Future<bool> saveStudent(int enrollmentId, Map<int, double> values) async {
    if (values.isEmpty) return true;
    isSaving.value = true;
    try {
      final scores = values.entries
          .map((e) => {'enrollmentId': enrollmentId, 'assessmentId': e.key, 'value': e.value})
          .toList();
      grid.value = await _service.saveScores(sectionId, scores);
      Get.snackbar('Guardado', 'Notas actualizadas.');
      return true;
    } catch (e) {
      debugPrint('Error guardando notas: $e');
      Get.snackbar('Error', 'No se pudieron guardar las notas.');
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
