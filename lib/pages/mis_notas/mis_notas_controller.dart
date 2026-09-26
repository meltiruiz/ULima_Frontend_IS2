import 'package:get/get.dart';

import '../../domain/notas/notas_calculo.dart' as notas_calculo;
import '../../domain/recarga_ulima/avisos_recarga.dart';
import '../../models/recarga_ulima_models.dart';
import '../../services/evaluations_service.dart';
import '../../services/recarga_ulima_service.dart';

/// Notas oficiales del alumno, las que publica la ULima (RF-RCG-6, decisión
/// B10). Lee `RecargaUlimaService`, que comparte su estado con la calculadora
/// y la ficha del curso. `OfficialGradesService` sigue en las pantallas del
/// docente.
class MisNotasController extends GetxController {
  MisNotasController({
    RecargaUlimaService? servicio,
    EvaluationSyllabusService? silabo,
  }) : _servicio = servicio ?? RecargaUlimaService.to,
       _silabo = silabo ?? EvaluationSyllabusService();

  final RecargaUlimaService _servicio;
  final EvaluationSyllabusService _silabo;

  final isLoading = false.obs;

  /// La sigla del sílabo de cada evaluación, por `assessmentId` (D9). Queda
  /// vacía si el sílabo no carga, y entonces las filas van sin prefijo.
  final siglas = <String, String>{}.obs;

  VistaUlima? get vista => _servicio.vista;
  AvisoRecarga? get aviso => _servicio.ultimoAviso;
  bool get errorCarga => _servicio.errorCarga;

  /// El último resultado no trae las notas de [curso] como leídas.
  bool sinLectura(CursoUlima curso) =>
      _servicio.sinLecturaDeNotas(curso.sectionId);

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// Consulta solo a ULima++, nunca entra a miUlima.
  Future<void> load() async {
    isLoading.value = true;
    try {
      await Future.wait([_servicio.cargar(), _cargarSiglas()]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _cargarSiglas() async {
    await _silabo.loadEvaluationData();
    if (!_silabo.isLoaded) {
      siglas.clear();
      return;
    }
    siglas.assignAll({
      for (final silabo in _silabo.allSyllabuses)
        for (final e in silabo.evaluaciones)
          if (e.sigla.isNotEmpty) e.id: e.sigla,
    });
  }

  /// `EV01 · Examen escrito 1` con pareja y sigla, o solo el nombre de la
  /// ULima (D9). Lee [siglas] de [conSiglas] para que el `Obx` que llama se
  /// suscriba.
  String titulo(EvaluacionUlima e, Map<String, String> conSiglas) {
    final sigla = e.tienePareja ? conSiglas['${e.assessmentId}'] : null;
    return sigla == null ? e.name : '$sigla · ${e.name}';
  }

  /// Nota final con lo ya publicado, con `NP` y las pendientes como 0
  /// (decisión B8).
  double notaFinal(CursoUlima curso) =>
      notas_calculo.calcularPromedioPonderado([
        for (final e in curso.evaluaciones)
          {'valor': e.value ?? 0, 'peso': e.weight},
      ]);

  /// La insignia «Final» sale solo con alguna nota o algún NP.
  bool tieneNotas(CursoUlima curso) =>
      curso.evaluaciones.any((e) => e.publicada);
}
