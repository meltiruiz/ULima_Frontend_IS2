import 'api_client.dart';

/// Persiste en el backend las notas simuladas de la calculadora.
///
/// Antes las notas vivían solo en `SharedPreferences` (local del dispositivo);
/// ahora se sincronizan con el backend (`/simulated-grades/me`) para que sigan
/// al alumno entre dispositivos. El promedio se sigue calculando en el cliente.
class SimulatedGradesService {
  final ApiClient _api = ApiClient();

  /// Lista las notas simuladas del alumno.
  /// Devuelve `[{assessmentId:int, sectionId:int, value:double}]`.
  Future<List<Map<String, dynamic>>> fetchAll() async {
    final res = await _api.getJson('/simulated-grades/me');
    final list = (res['grades'] as List?) ?? const [];
    return list.map((g) {
      final m = Map<String, dynamic>.from(g as Map);
      return <String, dynamic>{
        'assessmentId': (m['assessmentId'] as num).toInt(),
        'sectionId': (m['sectionId'] as num).toInt(),
        'value': (m['value'] as num).toDouble(),
      };
    }).toList();
  }

  /// Upsert de una nota simulada: evaluación (`assessment.id`) + valor (0..20).
  Future<void> upsertOne(int assessmentId, double value) async {
    await _api.putJson('/simulated-grades/me', body: {
      'grades': [
        {'assessmentId': assessmentId, 'value': value},
      ],
    });
  }

  /// Borra la nota simulada del alumno para esa evaluación.
  Future<void> deleteOne(int assessmentId) async {
    await _api.deleteJson('/simulated-grades/me/$assessmentId');
  }
}
