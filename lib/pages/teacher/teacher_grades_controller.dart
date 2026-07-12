import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../models/official_grades_models.dart';
import '../../services/official_grades_service.dart';

/// Lista de secciones que el docente puede calificar (pestaña "Calificar").
class TeacherGradesController extends GetxController {
  TeacherGradesController({OfficialGradesService? service})
      : _service = service ?? OfficialGradesService();

  final OfficialGradesService _service;

  final sections = <GradingSection>[].obs;
  final isLoading = false.obs;
  final loadError = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadSections();
  }

  Future<void> loadSections() async {
    isLoading.value = true;
    loadError.value = null;
    try {
      sections.assignAll(await _service.fetchTeacherSections());
    } catch (e) {
      loadError.value = 'No se pudieron cargar tus secciones.';
      debugPrint('Error cargando secciones para calificar: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void openSection(GradingSection section) {
    Get.toNamed('/teacher-grade-section', arguments: {
      'sectionId': section.sectionId,
      'title': '${section.courseName} · ${section.sectionCode}',
    });
  }
}
