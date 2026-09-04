import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/configs/course_colors.dart';

/// Reparto de colores entre los cursos de un alumno.
///
/// El backend guarda el color en `schedule_session`, fila compartida por todos
/// los alumnos de la sección, así que no puede garantizar que dos cursos de un
/// mismo alumno tengan colores distintos. Ese desempate vive acá.

void main() {
  group('paleta', () {
    test('tiene al menos 9 colores: el techo son 9 cursos por ciclo', () {
      expect(kCoursePalette.length, greaterThanOrEqualTo(9));
    });

    test('no hay colores repetidos en la paleta', () {
      final vistos = kCoursePalette.map((c) => c.toARGB32()).toSet();
      expect(vistos.length, kCoursePalette.length);
    });
  });

  group('parseHexColor', () {
    test('acepta las tres formas que manda el backend', () {
      expect(parseHexColor('#2F80ED'), const Color(0xFF2F80ED));
      expect(parseHexColor('2F80ED'), const Color(0xFF2F80ED));
      expect(parseHexColor('FF2F80ED'), const Color(0xFF2F80ED));
    });

    test('devuelve null ante basura, en vez de un color equivocado', () {
      for (final v in [null, '', '  ', 'azul', '#GGGGGG', '#12345']) {
        expect(parseHexColor(v), isNull, reason: 'entrada: $v');
      }
    });
  });

  group('asignarColoresSinRepetir', () {
    test('respeta el color del backend cuando no hay conflicto', () {
      final r = asignarColoresSinRepetir(
        ['A', 'B'],
        (k) => k == 'A' ? '#2F80ED' : '#27AE60',
      );
      expect(r['A'], const Color(0xFF2F80ED));
      expect(r['B'], const Color(0xFF27AE60));
    });

    test('CASO REAL: dos cursos con el mismo color quedan con colores distintos', () {
      // En 2026-2, Seguridad de Sistemas y Paradigmas de Programación traen
      // ambos el mismo índigo desde el backend.
      final r = asignarColoresSinRepetir(
        ['Paradigmas', 'Seguridad'],
        (_) => '#5B5BD6',
      );
      expect(r['Paradigmas'], isNot(r['Seguridad']));
      // Y uno de los dos conserva el color original: no se mueven los dos.
      expect(
        [r['Paradigmas'], r['Seguridad']],
        contains(const Color(0xFF5B5BD6)),
      );
    });

    test('nueve cursos reciben nueve colores distintos', () {
      final claves = List.generate(9, (i) => 'curso$i');
      final r = asignarColoresSinRepetir(claves, (_) => '#5B5BD6'); // todos igual
      expect(r.length, 9);
      expect(r.values.map((c) => c.toARGB32()).toSet().length, 9);
    });

    test('un color fuera de la paleta no deja al curso sin color', () {
      // Antes, un hex nulo o desconocido caía a `colors.outline`: gris.
      final r = asignarColoresSinRepetir(['A'], (_) => null);
      expect(r['A'], isNotNull);
      expect(kCoursePalette, contains(r['A']));
    });

    test('es estable: el mismo orden de entrada da el mismo reparto', () {
      final claves = ['A', 'B', 'C'];
      String? hex(String _) => '#2F80ED';
      expect(
        asignarColoresSinRepetir(claves, hex).toString(),
        asignarColoresSinRepetir(claves, hex).toString(),
      );
    });

    test('con más cursos que colores nadie se queda sin color', () {
      final claves = List.generate(kCoursePalette.length + 3, (i) => 'c$i');
      final r = asignarColoresSinRepetir(claves, (_) => null);
      expect(r.length, claves.length);
      expect(r.values.every(kCoursePalette.contains), isTrue);
    });
  });
}
