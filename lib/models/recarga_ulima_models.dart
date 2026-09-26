// lib/models/recarga_ulima_models.dart
//
// Modelos de la recarga desde la ULima (RF-RCG-1). Leen `GET /grades/me/ulima`
// y la respuesta de `POST /portal-sync/refresh`. La lectura es tolerante. Un
// número que llega como texto se convierte, una fecha ilegible queda `null`,
// un `mark` desconocido se trata como `pending` y un `match` desconocido como
// `none`.

/// Estado de una evaluación en el panel Nota del Aula Virtual.
enum MarcaUlima { graded, pending, np }

/// Cómo empareja el backend una evaluación de la ULima con el sílabo.
enum ParejaUlima { exact, exactOtherName, weekShift, none }

double? _decimal(Object? v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.trim());
  return null;
}

int? _entero(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim());
  return null;
}

DateTime? _fecha(Object? v) => v is String ? DateTime.tryParse(v) : null;

String _texto(Object? v) => v == null ? '' : v.toString();

List<Object?> _lista(Object? v) => v is List ? v : const <Object?>[];

Map<String, dynamic> _mapa(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : const <String, dynamic>{};

MarcaUlima _marca(Object? v) {
  switch (v) {
    case 'graded':
      return MarcaUlima.graded;
    case 'np':
      return MarcaUlima.np;
    default:
      return MarcaUlima.pending;
  }
}

ParejaUlima _pareja(Object? v) {
  switch (v) {
    case 'exact':
      return ParejaUlima.exact;
    case 'exact_other_name':
      return ParejaUlima.exactOtherName;
    case 'week_shift':
      return ParejaUlima.weekShift;
    default:
      return ParejaUlima.none;
  }
}

/// Una evaluación de un curso, tal como la publica la ULima.
class EvaluacionUlima {
  const EvaluacionUlima({
    required this.key,
    required this.group,
    required this.name,
    required this.week,
    required this.weight,
    required this.value,
    required this.mark,
    required this.assessmentId,
    required this.match,
  });

  final String key;
  final String? group;
  final String name;
  final int? week;
  final double weight;
  final double? value;
  final MarcaUlima mark;
  final int? assessmentId;
  final ParejaUlima match;

  /// Tiene pareja en el sílabo (RF-RCG-7, decisión B7).
  bool get tienePareja => match != ParejaUlima.none;

  /// La ULima ya publica algo, una nota o un NP.
  bool get publicada => mark != MarcaUlima.pending;

  factory EvaluacionUlima.fromJson(Map<String, dynamic> json) {
    final value = _decimal(json['value']);
    var mark = _marca(json['mark']);
    // Una nota «graded» sin valor no se puede pintar ni promediar, así que se
    // lee como pendiente.
    if (mark == MarcaUlima.graded && value == null) mark = MarcaUlima.pending;
    final assessmentId = _entero(json['assessmentId']);
    var match = _pareja(json['match']);
    // Sin `assessmentId` no hay con qué emparejar en el sílabo.
    if (assessmentId == null) match = ParejaUlima.none;
    final group = json['group'];
    return EvaluacionUlima(
      key: _texto(json['key']),
      group: group?.toString(),
      name: _texto(json['name']),
      week: _entero(json['week']),
      weight: _decimal(json['weight']) ?? 0,
      value: mark == MarcaUlima.graded ? value : null,
      mark: mark,
      assessmentId: assessmentId,
      match: match,
    );
  }
}

/// Un curso del alumno en el período activo, con sus evaluaciones.
class CursoUlima {
  const CursoUlima({
    required this.sectionId,
    required this.courseCode,
    required this.courseName,
    required this.sectionCode,
    required this.lastReadAt,
    required this.evaluaciones,
  });

  final int sectionId;
  final String courseCode;
  final String courseName;
  final String sectionCode;
  final DateTime? lastReadAt;

  /// Sale de `assessments` del JSON, en el orden en que llega.
  final List<EvaluacionUlima> evaluaciones;

  factory CursoUlima.fromJson(Map<String, dynamic> json) => CursoUlima(
    sectionId: _entero(json['sectionId']) ?? 0,
    courseCode: _texto(json['courseCode']),
    courseName: _texto(json['courseName']),
    sectionCode: _texto(json['sectionCode']),
    lastReadAt: _fecha(json['lastReadAt']),
    evaluaciones: _lista(
      json['assessments'],
    ).whereType<Map>().map((e) => EvaluacionUlima.fromJson(_mapa(e))).toList(),
  );
}

/// Lo que devuelve `GET /grades/me/ulima`.
class VistaUlima {
  const VistaUlima({required this.lastReadAt, required this.cursos});

  final DateTime? lastReadAt;

  /// Sale de `courses` del JSON, en el orden en que llega.
  final List<CursoUlima> cursos;

  factory VistaUlima.fromJson(Object? json) {
    final mapa = _mapa(json);
    return VistaUlima(
      lastReadAt: _fecha(mapa['lastReadAt']),
      cursos: _lista(
        mapa['courses'],
      ).whereType<Map>().map((c) => CursoUlima.fromJson(_mapa(c))).toList(),
    );
  }
}

/// Estado de un curso en una recarga, por panel.
class EstadoCursoRecarga {
  const EstadoCursoRecarga({
    required this.sectionId,
    required this.attendance,
    required this.grades,
  });

  final int sectionId;

  /// `updated`, `skipped`, `failed`, `unavailable`, `missing` o `not_reached`.
  final String attendance;

  /// `read`, `failed`, `unavailable`, `missing` o `not_reached`.
  final String grades;

  factory EstadoCursoRecarga.fromJson(Map<String, dynamic> json) =>
      EstadoCursoRecarga(
        sectionId: _entero(json['sectionId']) ?? 0,
        attendance: _texto(json['attendance']),
        grades: _texto(json['grades']),
      );
}

/// Lo que devuelve `POST /portal-sync/refresh` con `200`.
class ResultadoRecarga {
  const ResultadoRecarga({
    required this.readAt,
    required this.estados,
    required this.view,
  });

  final DateTime? readAt;
  final List<EstadoCursoRecarga> estados;
  final VistaUlima view;

  factory ResultadoRecarga.fromJson(Map<String, dynamic> json) =>
      ResultadoRecarga(
        readAt: _fecha(json['readAt']),
        estados: _lista(json['courses'])
            .whereType<Map>()
            .map((c) => EstadoCursoRecarga.fromJson(_mapa(c)))
            .toList(),
        view: VistaUlima.fromJson(json['view']),
      );
}
