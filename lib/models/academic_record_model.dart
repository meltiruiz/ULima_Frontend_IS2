/// Modelos del récord académico que ULima++ copia de miUlima
/// (`GET /academic-record/me`).
///
/// `fromJson` a mano con coerción defensiva, como el resto del repo, con una
/// diferencia: aquí un dato sin valor queda `null`, nunca 0 (RF-REC-1). La UI
/// lo omite en vez de pintar un 0 que el alumno tomaría por real. Por eso no se
/// usa `_asInt` (`official_grades_models.dart:5`), que convierte `null` y
/// `"1.5"` en 0.
///
/// `credits`, `ppa`, `average` y los `credits*` pueden traer decimal y se
/// guardan como `double` sin redondear. `attempt`, `grade`, `level` y
/// `courses` son enteros.
library;

/// `double` o `null`. Copia de `official_grades_models.dart:6-7`.
double? _asDoubleOrNull(dynamic v) =>
    v == null ? null : (v is num ? v.toDouble() : double.tryParse(v.toString()));

/// `int` o `null`. Un número con decimal (una nota 15.5) no es un entero
/// válido y queda `null`; 2.0 sí se lee como 2.
int? _asIntOrNull(dynamic v) {
  if (v is int) return v;
  if (v is num) return v == v.truncateToDouble() ? v.toInt() : null;
  if (v is String) return int.tryParse(v.trim());
  return null;
}

String _asString(dynamic v) => v == null ? '' : v.toString();

/// Texto sin espacios en los bordes, o `null` si no hay texto.
String? _asStringOrNull(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

Map<String, dynamic>? _asMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : null;

/// Los elementos que son objetos; el resto se descarta.
List<Map<String, dynamic>> _asMapList(dynamic v) => v is List
    ? v.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList()
    : const <Map<String, dynamic>>[];

/// Cantidad de cursos y de créditos de un grupo (aprobados, convalidados,
/// matriculados o desaprobados). Cada número es `null` por separado.
class AcademicTotals {
  const AcademicTotals({required this.courses, required this.credits});

  final int? courses;
  final double? credits;

  /// Grupo sin datos: lo que queda cuando el JSON no trae el objeto.
  static const AcademicTotals none = AcademicTotals(courses: null, credits: null);

  factory AcademicTotals.fromJson(Object? json) {
    final map = _asMap(json);
    if (map == null) return none;
    return AcademicTotals(
      courses: _asIntOrNull(map['courses']),
      credits: _asDoubleOrNull(map['credits']),
    );
  }
}

/// Información general del alumno según miUlima: la foto acumulada
/// (RS-BE-24 y RS-BE-25).
class AcademicSnapshot {
  const AcademicSnapshot({
    required this.ppa,
    required this.relativePosition,
    required this.creditsAccumulated,
    required this.creditsRequired,
    required this.approved,
    required this.convalidated,
  });

  final double? ppa;

  /// Tal como la da el portal, en mayúsculas ("TERCIO SUPERIOR").
  final String? relativePosition;
  final double? creditsAccumulated;
  final double? creditsRequired;
  final AcademicTotals approved;
  final AcademicTotals convalidated;

  factory AcademicSnapshot.fromJson(Map<String, dynamic> json) =>
      AcademicSnapshot(
        ppa: _asDoubleOrNull(json['ppa']),
        relativePosition: _asStringOrNull(json['relativePosition']),
        creditsAccumulated: _asDoubleOrNull(json['creditsAccumulated']),
        creditsRequired: _asDoubleOrNull(json['creditsRequired']),
        approved: AcademicTotals.fromJson(json['approved']),
        convalidated: AcademicTotals.fromJson(json['convalidated']),
      );
}

/// Resumen de un ciclo (un elemento de `periods`). El backend solo tiene
/// algunos ciclos, así que un ciclo del récord puede no tener resumen.
class AcademicPeriodSummary {
  const AcademicPeriodSummary({
    required this.periodCode,
    required this.average,
    required this.relativePosition,
    required this.level,
    required this.convalidated,
    required this.enrolled,
    required this.approved,
    required this.failed,
  });

  final String periodCode;
  final double? average;
  final String? relativePosition;
  final int? level;
  final AcademicTotals convalidated;
  final AcademicTotals enrolled;
  final AcademicTotals approved;
  final AcademicTotals failed;

  factory AcademicPeriodSummary.fromJson(Map<String, dynamic> json) =>
      AcademicPeriodSummary(
        periodCode: _asString(json['periodCode']),
        average: _asDoubleOrNull(json['average']),
        relativePosition: _asStringOrNull(json['relativePosition']),
        level: _asIntOrNull(json['level']),
        convalidated: AcademicTotals.fromJson(json['convalidated']),
        enrolled: AcademicTotals.fromJson(json['enrolled']),
        approved: AcademicTotals.fromJson(json['approved']),
        failed: AcademicTotals.fromJson(json['failed']),
      );
}

/// Un curso del récord. Los cursos de mallas anteriores traen su código y su
/// nombre originales.
class RecordCourse {
  const RecordCourse({
    required this.code,
    required this.name,
    required this.attempt,
    required this.credits,
    required this.grade,
    required this.gradeRaw,
    required this.section,
    required this.observation,
  });

  final String code;
  final String name;

  /// Vez que se lleva el curso (1, 2, 3…).
  final int? attempt;
  final double? credits;

  /// Nota entera de 0 a 20, o `null` (ciclo en curso, convalidación, retiro…).
  final int? grade;

  /// Texto original de la celda NOTA del portal; `null` si venía vacía.
  final String? gradeRaw;

  /// Sección. En el JSON la clave es `section`, no `sectionCode`.
  final String? section;
  final String? observation;

  factory RecordCourse.fromJson(Map<String, dynamic> json) => RecordCourse(
        code: _asString(json['code']),
        name: _asString(json['name']),
        attempt: _asIntOrNull(json['attempt']),
        credits: _asDoubleOrNull(json['credits']),
        grade: _asIntOrNull(json['grade']),
        gradeRaw: _asStringOrNull(json['gradeRaw']),
        section: _asStringOrNull(json['section']),
        observation: _asStringOrNull(json['observation']),
      );
}

/// Los cursos de un ciclo del récord (un elemento de `record`).
class RecordPeriod {
  const RecordPeriod({required this.periodCode, required this.courses});

  final String periodCode;
  final List<RecordCourse> courses;

  factory RecordPeriod.fromJson(Map<String, dynamic> json) => RecordPeriod(
        periodCode: _asString(json['periodCode']),
        courses: _asMapList(json['courses']).map(RecordCourse.fromJson).toList(),
      );
}

/// Respuesta de `GET /academic-record/me`.
class AcademicRecord {
  const AcademicRecord({
    required this.syncedAt,
    required this.snapshot,
    required this.periodSummaries,
    required this.coursesByPeriod,
  });

  /// Fecha de la importación que guardó esta copia, en UTC. `null` si el
  /// alumno nunca sincronizó con un récord de confianza y su consentimiento.
  final DateTime? syncedAt;

  /// Información general; `null` si el backend no la tiene.
  final AcademicSnapshot? snapshot;

  /// Resumen por ciclo (clave JSON `periods`).
  final List<AcademicPeriodSummary> periodSummaries;

  /// Cursos agrupados por ciclo (clave JSON `record`), en el orden del
  /// backend: del ciclo más reciente al más viejo (RS-BE-26). Aquí no se
  /// reordena.
  final List<RecordPeriod> coursesByPeriod;

  /// Sin `syncedAt` no hay récord y la pantalla muestra su estado vacío
  /// (RF-REC-4).
  bool get hasRecord => syncedAt != null;

  /// Sin récord: el estado que queda tras borrarlo (RF-REC-5).
  static const AcademicRecord empty = AcademicRecord(
    syncedAt: null,
    snapshot: null,
    periodSummaries: <AcademicPeriodSummary>[],
    coursesByPeriod: <RecordPeriod>[],
  );

  factory AcademicRecord.fromJson(Map<String, dynamic> json) {
    final raw = json['syncedAt'];
    final snapshot = _asMap(json['snapshot']);
    return AcademicRecord(
      syncedAt: raw is String ? DateTime.tryParse(raw)?.toUtc() : null,
      snapshot: snapshot == null ? null : AcademicSnapshot.fromJson(snapshot),
      periodSummaries: _asMapList(json['periods'])
          .map(AcademicPeriodSummary.fromJson)
          .toList(),
      coursesByPeriod:
          _asMapList(json['record']).map(RecordPeriod.fromJson).toList(),
    );
  }
}
