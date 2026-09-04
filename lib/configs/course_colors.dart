import 'package:flutter/material.dart';

/// Paleta de acentos por curso.
///
/// DOCE colores porque el techo realista son 9 cursos en un ciclo (27 créditos):
/// con los 8 de antes, dos cursos del mismo alumno compartían color por
/// obligación matemática. Los ocho primeros conservan su orden original para
/// que nada de lo ya pintado cambie de color; los cuatro últimos rellenan los
/// tonos que faltaban (cian, lima, marrón, índigo) en vez de repetir vecinos.
///
/// Debe coincidir con `COURSE_COLOR_PALETTE` del backend
/// (`portal-sync.repository.ts`), que es quien decide el color inicial de cada
/// curso al importar el horario.
const List<Color> kCoursePalette = [
  Color(0xFF2F80ED), // azul
  Color(0xFF27AE60), // verde
  Color(0xFFEB5757), // rojo
  Color(0xFF9B51E0), // morado
  Color(0xFFEC4899), // rosa
  Color(0xFFF2994A), // naranja
  Color(0xFF00B8A9), // teal
  Color(0xFFF2C94C), // amarillo
  Color(0xFF00A2C7), // cian
  Color(0xFF7CB518), // lima
  Color(0xFF8B6D5C), // marrón
  Color(0xFF5B5BD6), // índigo
];

/// Color estable para una sección/curso a partir de un `seed` (usar `sectionId`).
///
/// Se usa en las vistas del DOCENTE, donde el backend no envía color por curso.
Color courseAccentColor(int seed) =>
    kCoursePalette[seed.abs() % kCoursePalette.length];

/// Convierte un hex del backend (`#RRGGBB`, `RRGGBB` o `AARRGGBB`) a [Color].
/// Devuelve `null` si no es un hex reconocible, para que quien llame decida.
Color? parseHexColor(String? hex) {
  final limpio = (hex ?? '').trim().replaceFirst('#', '');
  if (RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(limpio)) {
    return Color(int.parse('FF$limpio', radix: 16));
  }
  if (RegExp(r'^[0-9a-fA-F]{8}$').hasMatch(limpio)) {
    return Color(int.parse(limpio, radix: 16));
  }
  return null;
}

/// Reparte colores entre los cursos de UN alumno sin que se repitan.
///
/// El backend guarda el color en `schedule_session`, una fila que comparten
/// todos los alumnos de la sección, así que allá es imposible saber qué otros
/// cursos lleva cada uno: dos cursos distintos pueden traer el mismo color. Pasa
/// de verdad — en el ciclo 2026-2, Seguridad de Sistemas y Paradigmas de
/// Programación traen los dos el mismo índigo.
///
/// Acá se respeta el color que manda el backend siempre que se pueda (así el
/// curso se ve igual para todos y se puede hablar del "curso azul") y solo se
/// mueve al siguiente libre de la paleta cuando ya lo tomó otro curso.
///
/// [clavesOrdenadas] debe venir en un orden ESTABLE (por ejemplo, alfabético):
/// de lo contrario, quién se queda con el color disputado cambiaría entre
/// recargas y el horario parecería parpadear.
///
/// Si hay más cursos que colores, los sobrantes reutilizan la paleta por orden;
/// con 12 colores y un techo de 9 cursos no debería ocurrir.
Map<String, Color> asignarColoresSinRepetir(
  List<String> clavesOrdenadas,
  String? Function(String clave) hexPreferido,
) {
  final asignado = <String, Color>{};
  final tomados = <int>{};

  int? slotDe(String? hex) {
    final c = parseHexColor(hex);
    if (c == null) return null;
    final i = kCoursePalette.indexWhere((p) => p.toARGB32() == c.toARGB32());
    return i == -1 ? null : i;
  }

  // Primera pasada: cada curso se queda con su color si está libre.
  final pendientes = <String>[];
  for (final clave in clavesOrdenadas) {
    final slot = slotDe(hexPreferido(clave));
    if (slot != null && !tomados.contains(slot)) {
      tomados.add(slot);
      asignado[clave] = kCoursePalette[slot];
    } else {
      pendientes.add(clave);
    }
  }

  // Segunda pasada: los que chocaron (o traían un color fuera de la paleta)
  // toman el siguiente hueco libre, avanzando desde su propia preferencia para
  // que el resultado no dependa del orden de llegada más de lo necesario.
  for (final clave in pendientes) {
    final desde = slotDe(hexPreferido(clave)) ?? 0;
    var elegido = -1;
    for (var k = 0; k < kCoursePalette.length; k++) {
      final i = (desde + k) % kCoursePalette.length;
      if (!tomados.contains(i)) {
        elegido = i;
        break;
      }
    }
    if (elegido == -1) {
      // Más cursos que colores: se reparte por orden, sin dejar a nadie gris.
      elegido = asignado.length % kCoursePalette.length;
    } else {
      tomados.add(elegido);
    }
    asignado[clave] = kCoursePalette[elegido];
  }

  return asignado;
}
