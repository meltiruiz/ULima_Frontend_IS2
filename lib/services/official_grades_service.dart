import 'api_client.dart';
import '../models/official_grades_models.dart';

/// Calificación oficial (módulo backend `official-grades`).
/// - Docente: lista sus secciones, lee la grilla y guarda notas por evaluación.
/// - Alumno: lee sus notas oficiales.
class OfficialGradesService {
  final ApiClient _api = ApiClient();

  // ─── Docente ───────────────────────────────────────────────────────────────

  Future<List<GradingSection>> fetchTeacherSections() async {
    final data = await _api.getJson('/official-grades/teacher/sections');
    final raw = (data['sections'] as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((s) => GradingSection.fromJson(Map<String, dynamic>.from(s)))
        .toList();
  }

  Future<SectionGrid> fetchSectionGrid(int sectionId) async {
    final data = await _api.getJson('/official-grades/teacher/sections/$sectionId/scores');
    return SectionGrid.fromJson(data);
  }

  /// Guarda (upsert) un lote de notas y devuelve la grilla actualizada.
  Future<SectionGrid> saveScores(
    int sectionId,
    List<Map<String, dynamic>> scores,
  ) async {
    final data = await _api.putJson(
      '/official-grades/teacher/sections/$sectionId/scores',
      body: {'scores': scores},
    );
    return SectionGrid.fromJson(data);
  }

  // ─── Alumno ──────────────────────────────────────────────────────────────

  Future<List<OfficialCourse>> fetchMyOfficialCourses() async {
    final data = await _api.getJson('/official-grades/me');
    final raw = (data['courses'] as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((c) => OfficialCourse.fromJson(Map<String, dynamic>.from(c)))
        .toList();
  }
}
