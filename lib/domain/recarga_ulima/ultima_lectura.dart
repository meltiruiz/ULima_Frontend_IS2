// lib/domain/recarga_ulima/ultima_lectura.dart
//
// La hora de la última lectura de la ULima (RF-RCG-9 y D22 de
// specs/features/recarga-portal/recarga-portal.spec.md).

import '../../pages/chat/chat_linea_tiempo.dart' show enHoraDeLima;

/// Los doce meses en minúscula. Repite la lista privada `_meses` de
/// `chat_linea_tiempo.dart`, que no está en los `targets` de la spec.
const List<String> _meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// La parte variable del texto, vista desde [ahora], con las dos fechas en
/// hora de Lima y comparadas por fecha de calendario.
///
/// Mismo día, o un [leidoEn] posterior a [ahora] por un reloj atrasado, da
/// `hoy a las HH:mm`. El día anterior da `ayer a las HH:mm`. Otro día del
/// mismo año da `el 22 de septiembre a las HH:mm`, y otro año suma
/// ` de 2025` después del mes.
String cuandoSeLeyo(DateTime leidoEn, DateTime ahora) {
  final leido = enHoraDeLima(leidoEn);
  final hoy = enHoraDeLima(ahora);
  final diaLeido = DateTime.utc(leido.year, leido.month, leido.day);
  final diaHoy = DateTime.utc(hoy.year, hoy.month, hoy.day);
  final hh = leido.hour.toString().padLeft(2, '0');
  final mm = leido.minute.toString().padLeft(2, '0');
  final hora = 'a las $hh:$mm';
  final dias = diaHoy.difference(diaLeido).inDays;
  if (dias <= 0) return 'hoy $hora';
  if (dias == 1) return 'ayer $hora';
  final anio = leido.year == hoy.year ? '' : ' de ${leido.year}';
  return 'el ${leido.day} de ${_meses[leido.month - 1]}$anio $hora';
}

/// `Última lectura <cuándo>`, para la fila, la franja y el bloque de
/// asistencia.
String textoUltimaLectura(DateTime leidoEn, DateTime ahora) =>
    'Última lectura ${cuandoSeLeyo(leidoEn, ahora)}';

/// `Se muestran las notas leídas <cuándo>.`, para el aviso rojo.
String textoNotasLeidas(DateTime leidoEn, DateTime ahora) =>
    'Se muestran las notas leídas ${cuandoSeLeyo(leidoEn, ahora)}.';
