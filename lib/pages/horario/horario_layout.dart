// lib/pages/horario/horario_layout.dart
// El reparto en columnas de los bloques que coinciden en el mismo tramo de un
// día (RF-BLQ-4). Antes de RF-BLQ-4, `HorarioPage._courseBlock` recibía
// `left`/`right` fijos por vista (66/14 en la vista de día y 2/2 en la
// semanal), así que dos bloques simultáneos se dibujaban uno encima del otro a
// ancho completo y el de arriba se comía los toques del de abajo. Los bloques
// propios del alumno van a chocar con las clases a propósito, así que hay que
// repartir.
//
// Función pura de nivel superior para poder probarla sin montar widgets, igual
// que HorarioPage.blockGeometry y HorarioPage.blockMetaLines, que la spec cita
// como modelo. Este archivo no importa Flutter ni GetX a propósito: entran
// enteros, salen enteros.

/// En qué columna va un bloque y entre cuántas se reparte el ancho de su día.
///
/// [columna] es 0-based y siempre menor que [columnas].
///
/// [columnas] es la cuenta del racimo entero, no la del tramo exacto del
/// bloque: dos bloques encadenados por un tercero miden lo mismo aunque en su
/// hora concreta sobre sitio. Si no, un bloque cambiaría de ancho a media
/// mañana y la grilla parecería rota.
class SlotColumna {
  const SlotColumna(this.columna, this.columnas);

  final int columna;
  final int columnas;

  @override
  String toString() => 'SlotColumna($columna de $columnas)';
}

/// Reparte en columnas los bloques que se solapan dentro de un mismo día.
///
/// Los tramos van en **minutos desde medianoche**: convertir el texto de la
/// hora es cosa de quien llama. Entrada en el mismo orden en que se van a
/// pintar y salida en el mismo orden, de modo que `resultado[i]` es el slot de
/// `bloques[i]`.
///
/// Tocarse en el borde **no** es solaparse —una termina 18:00 y la otra empieza
/// 18:00—, el mismo criterio que `seCruzan` en
/// `lib/pages/time_blocks/time_block_conflicts.dart`.
///
/// El algoritmo: ordenar por hora de inicio, cortar en racimos de bloques que
/// se solapan en cadena y, dentro del racimo, dar a cada bloque la primera
/// columna que ya quedó libre. `columnas` es el máximo alcanzado por el racimo
/// y se le asigna a todos sus miembros.
///
/// Devuelve columnas, **no** píxeles: pasar de columna a `left`/`right`
/// depende del ancho disponible y de los márgenes de cada vista, así que vive
/// en la vista y se prueba ahí.
List<SlotColumna> repartirEnColumnas(List<({int inicio, int fin})> bloques) {
  if (bloques.isEmpty) return const <SlotColumna>[];

  final columnaDe = List<int>.filled(bloques.length, 0);
  final columnasDe = List<int>.filled(bloques.length, 1);

  // Índices ordenados por hora de inicio; a igual inicio, primero el más largo,
  // y a igual tramo se conserva el orden de entrada. El desempate no cambia el
  // ancho de nadie, solo de qué lado cae cada bloque, y así es estable.
  final orden = List<int>.generate(bloques.length, (i) => i)
    ..sort((a, b) {
      final porInicio = bloques[a].inicio.compareTo(bloques[b].inicio);
      if (porInicio != 0) return porInicio;
      final porFin = bloques[b].fin.compareTo(bloques[a].fin);
      if (porFin != 0) return porFin;
      return a.compareTo(b);
    });

  var racimo = <int>[];         // índices del racimo en curso
  var finesDeColumna = <int>[]; // hasta qué minuto está ocupada cada columna
  var finDelRacimo = 0;         // el fin más tardío visto en el racimo

  void cerrarRacimo() {
    final cuantas = finesDeColumna.length;
    for (final i in racimo) {
      columnasDe[i] = cuantas;
    }
    racimo = <int>[];
    finesDeColumna = <int>[];
  }

  for (final i in orden) {
    final bloque = bloques[i];

    // Empieza cuando el racimo entero ya terminó: nada de lo anterior lo
    // alcanza, así que abre racimo propio y vuelve a ancho completo.
    if (racimo.isNotEmpty && bloque.inicio >= finDelRacimo) cerrarRacimo();

    // La primera columna cuyo último bloque ya terminó. Tocarse en el borde
    // libera la columna, de ahí el `<=` y no `<`.
    var columna = finesDeColumna.indexWhere((fin) => fin <= bloque.inicio);
    if (columna == -1) {
      columna = finesDeColumna.length;
      finesDeColumna.add(bloque.fin);
    } else {
      finesDeColumna[columna] = bloque.fin;
    }

    columnaDe[i] = columna;
    racimo.add(i);
    finDelRacimo =
        racimo.length == 1 || bloque.fin > finDelRacimo ? bloque.fin : finDelRacimo;
  }
  cerrarRacimo();

  return List<SlotColumna>.generate(
    bloques.length,
    (i) => SlotColumna(columnaDe[i], columnasDe[i]),
  );
}
