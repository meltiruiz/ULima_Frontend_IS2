// lib/pages/time_blocks/time_block_validators.dart
// Validadores puros del formulario de bloques propios (HU35, RF-BLQ-2). Sin
// Flutter ni I/O: devuelven null si el campo está bien, o un mensaje en
// español, y se componen con `??`. Mismo patrón que
// lib/pages/teacher/advising_validators.dart.
//
// El servidor vuelve a validar todo (RS-BE-31): estos mensajes son para que el
// alumno no llegue al servidor con un formulario obviamente incompleto. Ante un
// error del servidor se muestra el mensaje del servidor, no uno de aquí.

/// Largo máximo del título, el mismo que el CHECK `chk_time_block_titulo` y el
/// `max(60)` del esquema Zod del backend.
const int _largoMaximoDelNombre = 60;

/// Primera y última hora que la grilla del horario puede pintar
/// (`HorarioPage.startHour` y `endHour`, horario.dart:21-22). Un bloque fuera
/// de ahí sería invisible en la app, y el servidor lo rechaza con
/// `TIME_BLOCK_OUT_OF_GRID`.
const int _minutoMinimoDeLaGrilla = 7 * 60;
const int _minutoMaximoDeLaGrilla = 22 * 60;

final RegExp _hhmm = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
final RegExp _fechaPlana = RegExp(r'^\d{4}-\d{2}-\d{2}$');

/// Minutos desde medianoche de un `"HH:MM"` estricto, o null si no lo es.
/// A propósito NO acepta "4:00 pm": el formulario entrega siempre `HH:MM`.
int? _minutosDeHhmm(String v) {
  if (!_hhmm.hasMatch(v)) return null;
  final partes = v.split(':');
  return int.parse(partes[0]) * 60 + int.parse(partes[1]);
}

String? validarNombre(String v) {
  final limpio = v.trim();
  if (limpio.isEmpty) return 'Ponle un nombre al bloque.';
  if (limpio.length > _largoMaximoDelNombre) {
    return 'El nombre no puede pasar de $_largoMaximoDelNombre caracteres.';
  }
  return null;
}

/// 1 es lunes y 7 es domingo, la misma convención que `schedule_session`.
String? validarDias(Set<int> dias) {
  if (dias.isEmpty) return 'Marca al menos un día.';
  if (dias.any((d) => d < 1 || d > 7)) return 'Hay un día que no existe.';
  return null;
}

String? validarHoras(String? inicio, String? fin) {
  if (inicio == null || inicio.isEmpty || fin == null || fin.isEmpty) {
    return 'Indica la hora de inicio y de fin.';
  }
  final desde = _minutosDeHhmm(inicio);
  final hasta = _minutosDeHhmm(fin);
  if (desde == null || hasta == null) return 'Hora inválida (usa HH:MM).';
  if (hasta <= desde) return 'La hora de fin debe ser posterior a la de inicio.';
  if (desde < _minutoMinimoDeLaGrilla || hasta > _minutoMaximoDeLaGrilla) {
    return 'El bloque tiene que estar entre las 7 am y las 10 pm.';
  }
  return null;
}

String? validarFechas(String? desde, String? hasta) {
  if (desde == null || desde.isEmpty || hasta == null || hasta.isEmpty) {
    return 'Indica desde y hasta cuándo va el bloque.';
  }
  final inicio = _fechaPlana.hasMatch(desde) ? DateTime.tryParse(desde) : null;
  final fin = _fechaPlana.hasMatch(hasta) ? DateTime.tryParse(hasta) : null;
  if (inicio == null || fin == null) return 'Fecha inválida (usa AAAA-MM-DD).';
  if (fin.isBefore(inicio)) {
    return 'La fecha de fin no puede ser anterior a la de inicio.';
  }
  return null;
}

/// El mensaje de [validarDiasEnElRango]. Es, letra por letra, el que manda el
/// servidor cuando rechaza el mismo caso (RS-BE-31): venga de donde venga, el
/// alumno lee lo mismo.
const String mensajeSinDiasEnElRango =
    'Entre esas fechas no cae ninguno de los días que marcaste.';

/// `"YYYY-MM-DD"` → esa fecha a medianoche UTC, o null si no es una fecha plana
/// que existe (`DateTime.tryParse` corre el 30 de febrero al 2 de marzo, por
/// eso la vuelta tiene que dar el mismo día). En UTC para que sumar días no
/// tropiece con un cambio de hora del dispositivo.
DateTime? _fechaUtc(String? v) {
  if (v == null || !_fechaPlana.hasMatch(v)) return null;
  final fecha = DateTime.tryParse('${v}T00:00:00Z');
  if (fecha == null) return null;
  final partes = v.split('-').map(int.parse).toList();
  final existe = fecha.year == partes[0] &&
      fecha.month == partes[1] &&
      fecha.day == partes[2];
  return existe ? fecha : null;
}

/// Los días de la semana (1 = lunes … 7 = domingo) que tienen al menos una
/// fecha real entre [desde] y [hasta], las dos incluidas. Una semana entera ya
/// los tiene todos, así que nunca recorre más de siete fechas.
///
/// Vacío si el rango está invertido. null si falta alguna de las dos fechas o
/// no se lee: sin rango no se puede decir qué días tiene.
///
/// La usan [validarDiasEnElRango] y el aviso de cruce
/// (`time_block_conflicts.dart`), para que los dos lean igual qué días caen en
/// un rango.
Set<int>? diasConFechaEnElRango(String? desde, String? hasta) {
  final inicio = _fechaUtc(desde);
  final fin = _fechaUtc(hasta);
  if (inicio == null || fin == null) return null;
  final dias = <int>{};
  for (var fecha = inicio;
      !fecha.isAfter(fin) && dias.length < 7;
      fecha = fecha.add(const Duration(days: 1))) {
    dias.add(fecha.weekday);
  }
  return dias;
}

/// Que al menos una fecha entre [desde] y [hasta] caiga en uno de los [dias]
/// marcados. Sin eso el bloque no tiene ningún día real: martes y sábado del
/// miércoles 23 al miércoles 23 se guardaría, pero el servidor no generaría
/// ninguna ocurrencia y la grilla no pintaría nada.
///
/// No suma nada si faltan los días o las fechas, si las fechas no se leen o si
/// están invertidas: para eso ya están [validarDias] y [validarFechas].
String? validarDiasEnElRango(Set<int> dias, String? desde, String? hasta) {
  if (dias.isEmpty) return null;
  final conFecha = diasConFechaEnElRango(desde, hasta);
  if (conFecha == null || conFecha.isEmpty) return null;
  return conFecha.any(dias.contains) ? null : mensajeSinDiasEnElRango;
}

/// Todo el formulario, en orden de precedencia: se reporta el primer problema,
/// que es el que el alumno tiene más arriba en la pantalla. Que el rango tenga
/// días reales va al final: cruza dos campos, y solo tiene sentido cuando los
/// dos ya están bien.
String? validarFormulario({
  required String nombre,
  required Set<int> dias,
  required String? inicio,
  required String? fin,
  required String? desde,
  required String? hasta,
}) {
  return validarNombre(nombre) ??
      validarDias(dias) ??
      validarHoras(inicio, fin) ??
      validarFechas(desde, hasta) ??
      validarDiasEnElRango(dias, desde, hasta);
}
