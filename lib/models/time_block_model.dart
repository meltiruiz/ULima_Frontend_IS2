/// Modelos de los bloques de horario propios del alumno (RF-BLQ-7): la regla
/// semanal, sus excepciones por día, y las ocurrencias ya expandidas por el
/// servidor con el total de horas de cada semana.
///
/// `fromJson` a mano con coerción defensiva, como
/// `academic_record_model.dart`: un dato sin valor queda `null` y nunca 0. El
/// único número que el alumno llega a leer es [TimeBlockWeek.hours], y es
/// `double?` justamente para que la línea de horas no pueda pintar un 0
/// inventado (RF-BLQ-6).
///
/// Una regla o una ocurrencia a la que le falta lo imprescindible (el id,
/// la fecha, las horas) no se rellena con 0 ni con '': `tryFromJson`
/// devuelve null y las listas la descartan. `fromJson` lanza
/// [FormatException] en ese mismo caso.
///
/// Las horas viajan como `"HH:MM"` y las fechas como `"YYYY-MM-DD"`, en hora
/// de Lima y sin zona pegada: son horas de pared, así que se guardan como
/// texto y nadie las convierte a `DateTime`.
library;

/// `double` o `null`. Copia de `academic_record_model.dart:16-17`.
double? _asDoubleOrNull(dynamic v) =>
    v == null ? null : (v is num ? v.toDouble() : double.tryParse(v.toString()));

/// `int` o `null`. Un número con decimal no es un entero válido.
int? _asIntOrNull(dynamic v) {
  if (v is int) return v;
  if (v is num) return v == v.truncateToDouble() ? v.toInt() : null;
  if (v is String) return int.tryParse(v.trim());
  return null;
}

String _asString(dynamic v) => v == null ? '' : v.toString();

/// Texto sin espacios en los bordes, o `null` si no hay texto. Es lo que
/// conserva en `null` las horas de una excepción `cancelled`.
String? _asStringOrNull(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

Map<String, dynamic> _asMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

/// Los elementos que son objetos; el resto se descarta.
List<Map<String, dynamic>> _asMapList(dynamic v) => v is List
    ? v.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList()
    : const <Map<String, dynamic>>[];

/// Los días del patrón: 1 es lunes y 7 es domingo, la misma convención que
/// `schedule_session.day_of_week`. Lo que no sea un entero de 1 a 7 se
/// descarta en vez de colarse como un 0 que la grilla no sabría pintar.
List<int> _asDaysOfWeek(dynamic v) => v is List
    ? v
        .map(_asIntOrNull)
        .whereType<int>()
        .where((d) => d >= 1 && d <= 7)
        .toList()
    : const <int>[];

/// Lo que se sale del patrón un día concreto.
class TimeBlockException {
  const TimeBlockException({
    required this.date,
    required this.status,
    required this.startTime,
    required this.endTime,
  });

  /// `"YYYY-MM-DD"`.
  final String date;

  /// `'cancelled'` (ese día no va) o `'moved'` (ese día tiene otras horas).
  final String status;

  /// Solo vienen con `'moved'`; con `'cancelled'` son `null` y se conservan
  /// así, sin convertirse en cadena vacía ni en la hora del patrón.
  final String? startTime;
  final String? endTime;

  factory TimeBlockException.fromJson(Object? json) {
    final map = _asMap(json);
    return TimeBlockException(
      date: _asString(map['date']),
      status: _asString(map['status']),
      startTime: _asStringOrNull(map['startTime']),
      endTime: _asStringOrNull(map['endTime']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'date': date,
        'status': status,
        'startTime': startTime,
        'endTime': endTime,
      };
}

/// La regla: el patrón semanal y el rango de fechas en que vale.
class TimeBlockRule {
  const TimeBlockRule({
    required this.id,
    required this.title,
    required this.colorHex,
    required this.daysOfWeek,
    required this.startTime,
    required this.endTime,
    required this.startDate,
    required this.endDate,
    required this.exceptions,
  });

  /// El id del servidor. Siempre es uno real: una regla sin id se descarta
  /// al leerla ([tryFromJson]).
  final int id;
  final String title;

  /// `"#RRGGBB"`. El formulario solo ofrece los doce de `kCoursePalette`
  /// (RF-BLQ-2); el servidor acepta cualquier `#RRGGBB`, así que acá no se
  /// valida ni se normaliza: llega y se guarda.
  final String colorHex;

  /// 1 es lunes y 7 es domingo.
  final List<int> daysOfWeek;

  /// `"HH:MM"` en hora de Lima.
  final String startTime;
  final String endTime;

  /// `"YYYY-MM-DD"`.
  final String startDate;
  final String endDate;
  final List<TimeBlockException> exceptions;

  /// La regla de [json], o null si le falta algo sin lo cual no sirve: el
  /// `id` (editarla o borrarla mandaría `/time-blocks/me/0`), las horas o
  /// las fechas. Nunca se rellena con 0 ni con '' (RF-BLQ-7).
  static TimeBlockRule? tryFromJson(Object? json) {
    final map = _asMap(json);
    final id = _asIntOrNull(map['id']);
    final startTime = _asStringOrNull(map['startTime']);
    final endTime = _asStringOrNull(map['endTime']);
    final startDate = _asStringOrNull(map['startDate']);
    final endDate = _asStringOrNull(map['endDate']);
    if (id == null ||
        id <= 0 ||
        startTime == null ||
        endTime == null ||
        startDate == null ||
        endDate == null) {
      return null;
    }
    return TimeBlockRule(
      id: id,
      title: _asString(map['title']),
      colorHex: _asString(map['colorHex']),
      daysOfWeek: _asDaysOfWeek(map['daysOfWeek']),
      startTime: startTime,
      endTime: endTime,
      startDate: startDate,
      endDate: endDate,
      exceptions:
          _asMapList(map['exceptions']).map(TimeBlockException.fromJson).toList(),
    );
  }

  /// Como [tryFromJson], pero lanza [FormatException] si falta algo. Es para
  /// la respuesta de una escritura, que trae un solo bloque; las listas usan
  /// [tryFromJson] y descartan la entrada.
  factory TimeBlockRule.fromJson(Object? json) =>
      tryFromJson(json) ??
      (throw const FormatException('Bloque de horario incompleto.'));

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'colorHex': colorHex,
        'daysOfWeek': daysOfWeek,
        'startTime': startTime,
        'endTime': endTime,
        'startDate': startDate,
        'endDate': endDate,
        'exceptions': exceptions.map((e) => e.toJson()).toList(),
      };
}

/// Un día concreto del bloque, ya expandido por el servidor: las
/// excepciones están aplicadas (un día cancelado no llega) y [moved] dice si
/// ese día se salió del patrón.
class TimeBlockOccurrence {
  const TimeBlockOccurrence({
    required this.blockId,
    required this.title,
    required this.colorHex,
    required this.date,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.moved,
  });

  /// El [TimeBlockRule.id] de su regla. Siempre es uno real: una ocurrencia
  /// sin él se descarta al leerla ([tryFromJson]).
  final int blockId;
  final String title;
  final String colorHex;

  /// `"YYYY-MM-DD"`: la vista de día filtra por esta fecha, no por el nombre
  /// del día.
  final String date;

  /// 1 es lunes y 7 es domingo. Si el servidor no lo mandara, sale de
  /// [date]; nunca queda en 0.
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final bool moved;

  /// La ocurrencia de [json], o null si le falta algo sin lo cual no se
  /// puede pintar ni tocar: el `blockId` (tocarla mandaría
  /// `/time-blocks/me/0/…`), una fecha que se pueda leer o las horas (sin
  /// ellas se pintaría a las 7:00, el respaldo de la grilla). Nunca se
  /// rellena con 0 ni con '' (RF-BLQ-7).
  static TimeBlockOccurrence? tryFromJson(Object? json) {
    final map = _asMap(json);
    final blockId = _asIntOrNull(map['blockId']);
    final date = _asStringOrNull(map['date']);
    final fecha = date == null ? null : DateTime.tryParse(date);
    final startTime = _asStringOrNull(map['startTime']);
    final endTime = _asStringOrNull(map['endTime']);
    if (blockId == null ||
        blockId <= 0 ||
        date == null ||
        fecha == null ||
        startTime == null ||
        endTime == null) {
      return null;
    }
    final dia = _asIntOrNull(map['dayOfWeek']);
    return TimeBlockOccurrence(
      blockId: blockId,
      title: _asString(map['title']),
      colorHex: _asString(map['colorHex']),
      date: date,
      dayOfWeek: dia != null && dia >= 1 && dia <= 7 ? dia : fecha.weekday,
      startTime: startTime,
      endTime: endTime,
      moved: map['moved'] == true,
    );
  }

  /// Como [tryFromJson], pero lanza [FormatException] si falta algo.
  factory TimeBlockOccurrence.fromJson(Object? json) =>
      tryFromJson(json) ??
      (throw const FormatException('Ocurrencia de bloque incompleta.'));

  Map<String, dynamic> toJson() => <String, dynamic>{
        'blockId': blockId,
        'title': title,
        'colorHex': colorHex,
        'date': date,
        'dayOfWeek': dayOfWeek,
        'startTime': startTime,
        'endTime': endTime,
        'moved': moved,
      };
}

/// Las horas que los bloques del alumno ocupan en una semana de lunes a
/// domingo. [hours] es `double?` y lo calcula el servidor: la app lo muestra
/// y no lo recalcula (RF-BLQ-6).
class TimeBlockWeek {
  const TimeBlockWeek({required this.weekStart, required this.hours});

  /// El lunes de esa semana, `"YYYY-MM-DD"`.
  final String weekStart;
  final double? hours;

  factory TimeBlockWeek.fromJson(Object? json) {
    final map = _asMap(json);
    return TimeBlockWeek(
      weekStart: _asString(map['weekStart']),
      hours: _asDoubleOrNull(map['hours']),
    );
  }
}

/// Respuesta de `GET /time-blocks/me/occurrences`.
class TimeBlocksSnapshot {
  const TimeBlocksSnapshot({required this.occurrences, required this.weeks});

  /// Ordenadas por fecha y hora de inicio, como las manda el servidor.
  final List<TimeBlockOccurrence> occurrences;
  final List<TimeBlockWeek> weeks;

  factory TimeBlocksSnapshot.fromJson(Object? json) {
    final map = _asMap(json);
    return TimeBlocksSnapshot(
      // Una ocurrencia incompleta se descarta, no se pinta a las 7:00.
      occurrences: _asMapList(map['occurrences'])
          .map(TimeBlockOccurrence.tryFromJson)
          .whereType<TimeBlockOccurrence>()
          .toList(),
      weeks: _asMapList(map['weeks']).map(TimeBlockWeek.fromJson).toList(),
    );
  }
}
