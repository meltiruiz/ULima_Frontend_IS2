// Modelos de la calificación oficial (módulo backend `official-grades`).
// Las notas oficiales las pone el profesor/JP por evaluación; la nota final se
// calcula en el cliente por ponderación (ver domain/notas/notas_calculo.dart).

int _asInt(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
double? _asDoubleOrNull(dynamic v) =>
    v == null ? null : (v is num ? v.toDouble() : double.tryParse(v.toString()));

/// Sección que un docente puede calificar.
class GradingSection {
  final int sectionId;
  final String courseName;
  final String sectionCode;
  final String rol; // 'Profesor' | 'JP'

  GradingSection({
    required this.sectionId,
    required this.courseName,
    required this.sectionCode,
    required this.rol,
  });

  factory GradingSection.fromJson(Map<String, dynamic> json) => GradingSection(
        sectionId: _asInt(json['sectionId']),
        courseName: json['courseName']?.toString() ?? '',
        sectionCode: json['sectionCode']?.toString() ?? '',
        rol: json['rol']?.toString() ?? 'Profesor',
      );
}

class GradingStudent {
  final int enrollmentId;
  final String code;
  final String fullName;

  GradingStudent({required this.enrollmentId, required this.code, required this.fullName});

  factory GradingStudent.fromJson(Map<String, dynamic> json) => GradingStudent(
        enrollmentId: _asInt(json['enrollmentId']),
        code: json['code']?.toString() ?? '',
        fullName: json['fullName']?.toString() ?? '',
      );
}

class GradingAssessment {
  final int assessmentId;
  final String code;
  final String name;
  final double weight;
  final int weekNumber;

  GradingAssessment({
    required this.assessmentId,
    required this.code,
    required this.name,
    required this.weight,
    required this.weekNumber,
  });

  factory GradingAssessment.fromJson(Map<String, dynamic> json) => GradingAssessment(
        assessmentId: _asInt(json['assessmentId']),
        code: json['code']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        weight: _asDoubleOrNull(json['weight']) ?? 0,
        weekNumber: _asInt(json['weekNumber']),
      );
}

/// Grilla de calificación de una sección: alumnos × evaluaciones + notas puestas.
class SectionGrid {
  final int sectionId;
  final List<GradingStudent> students;
  final List<GradingAssessment> assessments;
  // Nota puesta, indexada por "enrollmentId:assessmentId".
  final Map<String, double> scores;

  SectionGrid({
    required this.sectionId,
    required this.students,
    required this.assessments,
    required this.scores,
  });

  static String scoreKey(int enrollmentId, int assessmentId) => '$enrollmentId:$assessmentId';

  factory SectionGrid.fromJson(Map<String, dynamic> json) {
    final scores = <String, double>{};
    for (final s in (json['scores'] as List?) ?? const []) {
      final m = Map<String, dynamic>.from(s as Map);
      final v = _asDoubleOrNull(m['value']);
      if (v != null) scores[scoreKey(_asInt(m['enrollmentId']), _asInt(m['assessmentId']))] = v;
    }
    return SectionGrid(
      sectionId: _asInt(json['sectionId']),
      students: ((json['students'] as List?) ?? const [])
          .map((s) => GradingStudent.fromJson(Map<String, dynamic>.from(s as Map)))
          .toList(),
      assessments: ((json['assessments'] as List?) ?? const [])
          .map((a) => GradingAssessment.fromJson(Map<String, dynamic>.from(a as Map)))
          .toList(),
      scores: scores,
    );
  }
}

/// Una evaluación oficial del alumno (con su nota, si ya la pusieron).
class OfficialAssessment {
  final int assessmentId;
  final String code;
  final String name;
  final double weight;
  final double? value;

  OfficialAssessment({
    required this.assessmentId,
    required this.code,
    required this.name,
    required this.weight,
    required this.value,
  });

  factory OfficialAssessment.fromJson(Map<String, dynamic> json) => OfficialAssessment(
        assessmentId: _asInt(json['assessmentId']),
        code: json['code']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        weight: _asDoubleOrNull(json['weight']) ?? 0,
        value: _asDoubleOrNull(json['value']),
      );

  /// Mapa para el cálculo ponderado (domain/notas): {'valor', 'peso'}.
  Map<String, dynamic> toCalcEntry() => {'valor': value ?? 0, 'peso': weight};
}

/// Notas oficiales del alumno en un curso/sección.
class OfficialCourse {
  final int sectionId;
  final String courseName;
  final String sectionCode;
  final List<OfficialAssessment> assessments;

  OfficialCourse({
    required this.sectionId,
    required this.courseName,
    required this.sectionCode,
    required this.assessments,
  });

  factory OfficialCourse.fromJson(Map<String, dynamic> json) => OfficialCourse(
        sectionId: _asInt(json['sectionId']),
        courseName: json['courseName']?.toString() ?? '',
        sectionCode: json['sectionCode']?.toString() ?? '',
        assessments: ((json['assessments'] as List?) ?? const [])
            .map((a) => OfficialAssessment.fromJson(Map<String, dynamic>.from(a as Map)))
            .toList(),
      );

  /// Suma de pesos de las evaluaciones ya calificadas (para saber el avance).
  double get gradedWeight =>
      assessments.where((a) => a.value != null).fold(0.0, (s, a) => s + a.weight);
}
