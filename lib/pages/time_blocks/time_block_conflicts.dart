// lib/pages/time_blocks/time_block_conflicts.dart
// Detección pura de cruces de un bloque propio (HU35, RF-BLQ-3): contra las
// clases que el horario ya tiene en pantalla y contra los demás bloques del
// alumno. Sin Flutter, sin HTTP y sin GetX, para poder probarla sin montar
// widgets — igual que HorarioPage.blockGeometry y blockMetaLines.
//
// El cruce nunca impide guardar: solo alimenta el aviso que ofrece guardar
// igual o volver a editar. La spec del backend no menciona cruces en ninguna
// de sus reglas, así que este aviso es lo único que avisa.

import '../../models/time_block_model.dart';
import 'time_block_validators.dart' show diasConFechaEnElRango;

/// Un cruce encontrado: con qué, qué día y a qué hora.
///
/// [dia] es 1 (lunes) a 7 (domingo). [inicio] y [fin] son `"HH:MM"` de 24 h,
/// normalizados: la clase los trae en 12 h ("04:00 pm") y el bloque propio en
/// 24 h, y el aviso tiene que leerse igual venga de donde venga.
class Cruce {
  const Cruce({
    required this.conQue,
    required this.dia,
    required this.inicio,
    required this.fin,
  });

  final String conQue;
  final int dia;
  final String inicio;
  final String fin;
}

/// Los días como se escriben en el aviso.
const List<String> _nombresDeDia = <String>[
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

/// Los mismos sin tilde: el horario manda "Miércoles" o "Miercoles" según de
/// dónde venga, y `_weekDays` de `HorarioPage` ya tolera las dos formas.
const List<String> _nombresDeDiaSinTilde = <String>[
  'lunes',
  'martes',
  'miercoles',
  'jueves',
  'viernes',
  'sabado',
  'domingo',
];

/// Nombre del día del horario → 1 (lunes) a 7 (domingo), o null si no es un
/// día conocido. Tolera "Miercoles" y "Sabado" sin tilde.
///
/// La usan el aviso de cruce y la grilla de los bloques propios
/// (`HorarioController`): con una sola función, los dos leen igual qué día
/// nombra un texto.
int? numeroDeDia(String nombre) {
  final limpio = nombre
      .trim()
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u');
  if (limpio.isEmpty) return null;
  final i = _nombresDeDiaSinTilde.indexOf(limpio);
  return i < 0 ? null : i + 1;
}

/// Minutos desde medianoche de una hora del horario.
///
/// Acepta las dos formas que circulan por la app: 12 h con sufijo
/// ("8:00 am", "04:00 pm") y 24 h con o sin segundos ("14:00", "14:00:00").
///
/// Devuelve null cuando no se puede leer. Ahí está la diferencia con
/// `HorarioPage._timeToHours`, que devuelve 7.0 para pintar el bloque al
/// inicio de la grilla en vez de hacerlo desaparecer: aquí no hay nada que
/// pintar, y una hora que no se lee no genera un aviso de cruce.
int? horaAMinutos(String texto) {
  var limpio = texto.trim().toLowerCase();
  if (limpio.isEmpty) return null;

  var esDoceHoras = false;
  var esPm = false;
  if (limpio.endsWith('am') || limpio.endsWith('pm')) {
    esPm = limpio.endsWith('pm');
    esDoceHoras = true;
    limpio = limpio.substring(0, limpio.length - 2).trim();
  }

  final partes = limpio.split(':');
  var hora = int.tryParse(partes[0].trim());
  if (hora == null) return null;
  final minuto = partes.length > 1 ? int.tryParse(partes[1].trim()) : 0;
  if (minuto == null || minuto < 0 || minuto > 59) return null;

  if (esDoceHoras) {
    if (hora < 1 || hora > 12) return null;
    if (esPm && hora != 12) hora += 12;
    if (!esPm && hora == 12) hora = 0;
  } else if (hora < 0 || hora > 23) {
    return null;
  }
  return hora * 60 + minuto;
}

String _enHhmm(int minutos) =>
    '${(minutos ~/ 60).toString().padLeft(2, '0')}:'
    '${(minutos % 60).toString().padLeft(2, '0')}';

/// Para el aviso, que se lee en 12 h como el resto del horario. Solo recibe
/// horas que salieron de [_enHhmm], así que el respaldo de 0 es inalcanzable
/// desde [crucesDeBloque]; está para que un [Cruce] armado a mano no reviente.
String _en12h(String hhmm) {
  final minutos = horaAMinutos(hhmm) ?? 0;
  final hora24 = minutos ~/ 60;
  final resto = minutos % 60;
  final sufijo = hora24 >= 12 ? 'pm' : 'am';
  final hora12 = hora24 % 12 == 0 ? 12 : hora24 % 12;
  return '$hora12:${resto.toString().padLeft(2, '0')} $sufijo';
}

/// Dos rangos del MISMO día se cruzan si uno empieza antes de que el otro
/// termine. Tocarse en el borde (una termina 18:00 y la otra empieza 18:00)
/// **no** es cruce.
bool _minutosSeCruzan(int inicioA, int finA, int inicioB, int finB) =>
    inicioA < finB && inicioB < finA;

/// [_minutosSeCruzan] sobre horas en texto, en cualquiera de los dos formatos.
/// Si alguna hora no se puede leer devuelve false: no se avisa de un cruce que
/// no se pudo comprobar.
bool seCruzan(String inicioA, String finA, String inicioB, String finB) {
  final ia = horaAMinutos(inicioA);
  final fa = horaAMinutos(finA);
  final ib = horaAMinutos(inicioB);
  final fb = horaAMinutos(finB);
  if (ia == null || fa == null || ib == null || fb == null) return false;
  return _minutosSeCruzan(ia, fa, ib, fb);
}

const Set<int> _todaLaSemana = <int>{1, 2, 3, 4, 5, 6, 7};

/// Los días de la semana con al menos una fecha real en el rango
/// `YYYY-MM-DD` de [desde] a [hasta]. Un rango que falta o no se lee se toma
/// como abierto, con todos los días: sin fechas no se puede descartar nada, y
/// el aviso prefiere avisar de más que callar un cruce real.
Set<int> _diasConFecha(String? desde, String? hasta) =>
    diasConFechaEnElRango(desde, hasta) ?? _todaLaSemana;

/// Los días de la semana con al menos una fecha real COMÚN a los dos rangos:
/// los de su intersección. Vacío si los rangos no se solapan. Qué días de
/// esos son de los dos bloques lo decide quien llama.
///
/// Un rango que falta o no se lee se toma como abierto, igual que en
/// [_diasConFecha]: la intersección es entonces el otro rango.
Set<int> _diasConFechaEnComun(
  String? desdeA,
  String? hastaA,
  String? desdeB,
  String? hastaB,
) {
  final aSeLee = diasConFechaEnElRango(desdeA, hastaA) != null;
  final bSeLee = diasConFechaEnElRango(desdeB, hastaB) != null;
  if (!aSeLee) return _diasConFecha(desdeB, hastaB);
  if (!bSeLee) return _diasConFecha(desdeA, hastaA);
  // Los dos rangos se leen: las fechas planas se comparan como texto. La
  // intersección va del inicio más tardío al fin más temprano; si queda
  // invertida, no hay fecha común y el resultado es vacío.
  final desde = desdeA!.compareTo(desdeB!) >= 0 ? desdeA : desdeB;
  final hasta = hastaA!.compareTo(hastaB!) <= 0 ? hastaA : hastaB;
  return _diasConFecha(desde, hasta);
}

/// Con qué choca un bloque que el alumno está por guardar.
///
/// [secciones] son las secciones del horario **sin aplanar**, como las tiene
/// `_todasLasSecciones` del controller: cada una con `curso` y una lista
/// `horarios` de mapas con `dia`, `hora_inicio` y `hora_fin`. [bloques] son los
/// bloques propios ya guardados. [ignorarBloqueId] sirve al editar: un bloque
/// no se cruza consigo mismo.
///
/// Solo avisa de cruces que pueden pasar en una fecha real (RF-BLQ-3):
///
/// - Contra las clases mira el día de la semana y la hora: el horario de
///   clases es el del ciclo y no trae fechas. Pero solo por los días de la
///   semana que tienen al menos una fecha real entre [desde] y [hasta] (los del
///   bloque que se guarda): un bloque de lunes y miércoles que va de un lunes
///   al martes siguiente no tiene miércoles, y no choca con la clase del
///   miércoles.
/// - Contra otro bloque propio hace falta una fecha común a los dos rangos
///   cuyo día de la semana sea de los dos bloques, y que las horas se crucen.
///   Que los rangos se solapen no basta: un bloque de martes y sábado que va
///   del miércoles 23 al 23 no tiene ninguna fecha real, y no choca con nada.
///
/// Si [desde] o [hasta] faltan, el rango del bloque nuevo se toma como
/// abierto, así que contra las clases queda solo el día de la semana y contra
/// otro bloque cuentan los días con fecha en el rango del bloque guardado.
///
/// La lista sale ordenada por día y por hora de inicio, para que el aviso se
/// lea siempre igual sin importar en qué orden llegaron las clases.
List<Cruce> crucesDeBloque({
  required Set<int> dias,
  required String inicio,
  required String fin,
  required List<Map<String, dynamic>> secciones,
  required List<TimeBlockRule> bloques,
  int? ignorarBloqueId,
  String? desde,
  String? hasta,
}) {
  final inicioMin = horaAMinutos(inicio);
  final finMin = horaAMinutos(fin);
  if (inicioMin == null || finMin == null) return const <Cruce>[];

  final cruces = <Cruce>[];
  final diasDelRango = _diasConFecha(desde, hasta);

  for (final seccion in secciones) {
    final horarios = seccion['horarios'];
    if (horarios is! List) continue;
    final curso = (seccion['curso'] as String? ?? '').trim();
    for (final crudo in horarios) {
      if (crudo is! Map) continue;
      final dia = numeroDeDia(crudo['dia'] as String? ?? '');
      if (dia == null || !dias.contains(dia) || !diasDelRango.contains(dia)) {
        continue;
      }
      final desdeMin = horaAMinutos(crudo['hora_inicio'] as String? ?? '');
      final hastaMin = horaAMinutos(crudo['hora_fin'] as String? ?? '');
      if (desdeMin == null || hastaMin == null) continue;
      if (!_minutosSeCruzan(inicioMin, finMin, desdeMin, hastaMin)) continue;
      cruces.add(Cruce(
        conQue: curso.isEmpty ? 'una clase' : curso,
        dia: dia,
        inicio: _enHhmm(desdeMin),
        fin: _enHhmm(hastaMin),
      ));
    }
  }

  for (final bloque in bloques) {
    if (ignorarBloqueId != null && bloque.id == ignorarBloqueId) continue;
    final diasEnComun = _diasConFechaEnComun(
      desde,
      hasta,
      bloque.startDate,
      bloque.endDate,
    );
    if (diasEnComun.isEmpty) continue;
    final desdeMin = horaAMinutos(bloque.startTime);
    final hastaMin = horaAMinutos(bloque.endTime);
    if (desdeMin == null || hastaMin == null) continue;
    if (!_minutosSeCruzan(inicioMin, finMin, desdeMin, hastaMin)) continue;
    for (final dia in bloque.daysOfWeek) {
      if (!dias.contains(dia) || !diasEnComun.contains(dia)) continue;
      cruces.add(Cruce(
        conQue: bloque.title,
        dia: dia,
        inicio: _enHhmm(desdeMin),
        fin: _enHhmm(hastaMin),
      ));
    }
  }

  cruces.sort((a, b) {
    final porDia = a.dia.compareTo(b.dia);
    return porDia != 0 ? porDia : a.inicio.compareTo(b.inicio);
  });
  return cruces;
}

/// El texto del aviso: nombra con qué y cuándo. Cadena vacía si no hay cruces
/// (quien llama no debe mostrar el aviso en ese caso).
String mensajeDeCruce(List<Cruce> cruces) {
  if (cruces.isEmpty) return '';
  final partes = cruces
      .map((c) =>
          '${c.conQue}, ${_nombresDeDia[c.dia - 1]} '
          'de ${_en12h(c.inicio)} a ${_en12h(c.fin)}')
      .toList();
  if (partes.length == 1) return 'Se cruza con ${partes.first}.';
  return 'Se cruza con:\n${partes.map((p) => '• $p').join('\n')}';
}
