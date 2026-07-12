import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../domain/notas/notas_calculo.dart' as notas_calculo;
import '../../models/official_grades_models.dart';
import '../../services/official_grades_service.dart';

/// Notas OFICIALES del alumno (las que pone el profesor). Solo lectura.
/// La nota final se calcula por ponderación en el cliente (mismo criterio que
/// la calculadora), reusando el dominio testeado.
class MisNotasController extends GetxController {
  MisNotasController({OfficialGradesService? service})
      : _service = service ?? OfficialGradesService();

  final OfficialGradesService _service;

  final courses = <OfficialCourse>[].obs;
  final isLoading = false.obs;
  final loadError = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    loadError.value = null;
    try {
      courses.assignAll(await _service.fetchMyOfficialCourses());
    } catch (e) {
      loadError.value = 'No se pudieron cargar tus notas oficiales.';
      debugPrint('Error cargando notas oficiales: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Nota final (promedio ponderado) con las evaluaciones ya calificadas.
  double notaFinal(OfficialCourse course) => notas_calculo.calcularPromedioPonderado(
        course.assessments.map((a) => a.toCalcEntry()).toList(),
      );

  /// ¿Ya calificaron alguna evaluación de este curso?
  bool tieneNotas(OfficialCourse course) => course.assessments.any((a) => a.value != null);
}
