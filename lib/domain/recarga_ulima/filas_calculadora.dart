// lib/domain/recarga_ulima/filas_calculadora.dart
//
// Las filas de la calculadora cuando la ULima ya publica notas (RF-RCG-7 de
// specs/features/recarga-portal/recarga-portal.spec.md). Las simuladas viven
// en `curso['notas']` y las de la ULima en una lista aparte, bajo
// [claveNotasUlima], así que el guardado nunca las mezcla.

import '../../models/recarga_ulima_models.dart';

/// Clave del curso de la calculadora con sus filas de la ULima.
const String claveNotasUlima = 'notasUlima';

/// Clave del curso de la calculadora que dice si la ULima publica alguna
/// evaluación sin pareja en el sílabo (D15).
const String claveUlimaSinPareja = 'ulimaSinPareja';

/// Las filas de la ULima que entran a la calculadora, las que tienen nota o
/// NP y pareja en el sílabo. Las pendientes siguen disponibles para simular y
/// las que no tienen pareja se ven solo en `/mis-notas` (decisión B7).
List<Map<String, dynamic>> notasUlimaDeCurso(CursoUlima? curso) => [
  if (curso != null)
    for (final e in curso.evaluaciones)
      if (e.publicada && e.tienePareja)
        {
          'titulo': e.name,
          'peso': e.weight,
          'valor': e.value,
          'np': e.mark == MarcaUlima.np,
          'evaluacionId': '${e.assessmentId}',
        },
];

/// Si la ULima publica alguna evaluación del curso sin pareja en el sílabo.
bool ulimaSinPareja(CursoUlima? curso) =>
    curso?.evaluaciones.any((e) => !e.tienePareja) ?? false;

const List<String> _camposUlima = [
  'titulo',
  'peso',
  'valor',
  'np',
  'evaluacionId',
];

/// Si [antes], lo que tiene el curso, ya es igual a [despues]. Evita pedir
/// otra vez el promedio de un curso que no cambia.
bool mismasNotasUlima(Object? antes, List<Map<String, dynamic>> despues) {
  final lista = antes is List ? antes : const <Object?>[];
  if (lista.length != despues.length) return false;
  for (var i = 0; i < lista.length; i++) {
    final a = lista[i];
    if (a is! Map) return false;
    for (final campo in _camposUlima) {
      if (a[campo] != despues[i][campo]) return false;
    }
  }
  return true;
}

/// Una fila visible de la calculadora, simulada o de la ULima.
class FilaCalculadora {
  const FilaCalculadora({
    required this.deUlima,
    required this.titulo,
    required this.peso,
    required this.valor,
    required this.np,
    required this.evaluacionId,
    this.indiceSimulada,
  });

  final bool deUlima;
  final String titulo;
  final num peso;

  /// `null` solo con [np].
  final double? valor;
  final bool np;
  final String evaluacionId;

  /// La posición de la simulada en `curso['notas']`, que es la que pide
  /// `eliminarNota`. `null` en una fila de la ULima.
  final int? indiceSimulada;

  /// `NP` cuenta como 0 (decisión B8).
  double get valorParaPromedio => np ? 0 : (valor ?? 0);
}

String _id(Object? nota) => nota is Map ? '${nota['evaluacionId']}' : '';

/// Las filas visibles de un curso (RF-RCG-7).
///
/// Una simulada con el mismo `evaluacionId` que una de la ULima no se ve,
/// pero sigue en [simuladas] y vuelve si la ULima retira la nota (decisión
/// B6). El orden es el de [ordenSilabo], con las que no están en el sílabo al
/// final, primero las de la ULima y después las simuladas en su orden de hoy
/// (D7).
List<FilaCalculadora> filasVisibles({
  required List<Object?> simuladas,
  required List<Object?> ulima,
  List<String> ordenSilabo = const [],
}) {
  final idsUlima = {for (final u in ulima) _id(u)};
  final filas = <FilaCalculadora>[
    for (final u in ulima.whereType<Map>())
      FilaCalculadora(
        deUlima: true,
        titulo: '${u['titulo']}',
        peso: (u['peso'] as num?) ?? 0,
        valor: (u['valor'] as num?)?.toDouble(),
        np: u['np'] == true,
        evaluacionId: _id(u),
      ),
    for (final s in simuladas.whereType<Map>())
      if (!idsUlima.contains(_id(s)))
        FilaCalculadora(
          deUlima: false,
          titulo: '${s['titulo']}',
          peso: (s['peso'] as num?) ?? 0,
          valor: (s['valor'] as num?)?.toDouble() ?? 0,
          np: false,
          evaluacionId: _id(s),
          indiceSimulada: simuladas.indexWhere((n) => _id(n) == _id(s)),
        ),
  ];
  final posicion = {
    for (var i = 0; i < ordenSilabo.length; i++) ordenSilabo[i]: i,
  };
  final conOrden = filas.asMap().entries.toList()
    ..sort((a, b) {
      final pa = posicion[a.value.evaluacionId] ?? ordenSilabo.length;
      final pb = posicion[b.value.evaluacionId] ?? ordenSilabo.length;
      return pa != pb ? pa.compareTo(pb) : a.key.compareTo(b.key);
    });
  return [for (final e in conOrden) e.value];
}

/// Lo que recibe `POST /grades/me/calculate`, con el peso exacto de la ULima
/// y `NP` como 0.
List<Map<String, double>> notasParaPromedio(List<FilaCalculadora> filas) => [
  for (final f in filas)
    {'valor': f.valorParaPromedio, 'peso': f.peso.toDouble()},
];

/// Si el curso tiene alguna fila visible, simulada o de la ULima. Un curso
/// sin la lista de la ULima, como los que arma el doble de HU07, cuenta solo
/// sus simuladas.
bool tieneFilasVisibles(Map<dynamic, dynamic> curso) =>
    ((curso['notas'] as List?)?.isNotEmpty ?? false) ||
    ((curso[claveNotasUlima] as List?)?.isNotEmpty ?? false);

/// Los `evaluacionId` con una fila de la ULima visible en el curso.
Set<String> idsConNotaUlima(Map<dynamic, dynamic> curso) => {
  for (final u in (curso[claveNotasUlima] as List?) ?? const <Object?>[])
    _id(u),
};
