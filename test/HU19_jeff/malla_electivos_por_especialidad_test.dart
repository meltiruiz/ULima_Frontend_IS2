// test/HU19_jeff/malla_electivos_por_especialidad_test.dart
// Cómo se agrupan los electivos de la malla por especialidad.
//
// EL BUG (2026-09-18): la agrupación tomaba `specialties.first` y descartaba el
// resto, así que un electivo que pertenece a DOS diplomas solo aparecía en uno.
// Y los hay: según el plan oficial de diplomas de especialidad
// (diplomas_de_especialidad_2025-1_v3.pdf), PROGRAMACIÓN MÓVIL, PROYECTO DE
// DESARROLLO DE SOFTWARE e INTERACCIÓN HUMANO COMPUTADORA son de Ingeniería de
// Software Y de Desarrollo de Videojuegos, y ARQUITECTURA DE TECNOLOGÍAS DE LA
// INFORMACIÓN es de Tecnologías de la Información Y de Sistemas de Información.
// Un alumno de Videojuegos no veía en su diploma cursos que le corresponden.
//
// OJO, DEVOPS no es un ejemplo de esto: el plan oficial lo pone SOLO en
// Tecnologías de la Información. La base lo tenía también en Software por un
// error de carga, que se corrigió en los datos, no aquí.

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/domain/malla/malla_entities.dart';
import 'package:ulima_plus/pages/malla/malla_list_controller.dart';

CourseNode _electivo(String id, List<String> especialidades) => CourseNode(
      id: id,
      code: 'E-$id',
      name: 'Electivo $id',
      credits: 3,
      level: 10,
      prerequisites: const [],
      category: CourseCategory.elective,
      row: 0,
      specialties: especialidades,
    );

List<String> _nombres(List<CourseNode> cursos) => cursos.map((c) => c.id).toList();

const _software = 'Ingeniería de Software';
const _videojuegos = 'Desarrollo de Videojuegos';
const _ti = 'Tecnologías de la Información';
const _si = 'Sistemas de Información';

void main() {
  const otros = MallaListController.otherElectivesGroup;
  final agrupar = MallaListController.agruparElectivosPorEspecialidad;

  group('un electivo aparece en cada especialidad a la que pertenece', () {
    test('PROGRAMACIÓN MÓVIL sale en Software Y en Videojuegos', () {
      final grupos = agrupar([_electivo('movil', [_software, _videojuegos])]);

      expect(grupos[_software], isNotNull);
      expect(grupos[_videojuegos], isNotNull,
          reason: 'la agrupación vieja tomaba solo la primera especialidad');
      expect(_nombres(grupos[_software]!), ['movil']);
      expect(_nombres(grupos[_videojuegos]!), ['movil']);
    });

    test('uno de una sola especialidad sigue apareciendo una vez', () {
      final grupos = agrupar([_electivo('devops', [_ti])]);
      expect(grupos.keys, [_ti]);
      expect(_nombres(grupos[_ti]!), ['devops']);
    });

    test('una especialidad repetida en la lista no duplica el curso', () {
      // El backend manda `array_agg(distinct ...)`, pero la agrupación no
      // debería depender de eso para no pintar dos tarjetas iguales.
      final grupos = agrupar([_electivo('x', [_ti, _ti])]);
      expect(_nombres(grupos[_ti]!), ['x']);
    });
  });

  group('lo que no cambia', () {
    test('sin especialidad va a «Otros electivos»', () {
      final grupos = agrupar([_electivo('suelto', const [])]);
      expect(grupos.keys, [otros]);
    });

    test('las especialidades van en orden alfabético y «Otros» al final', () {
      final grupos = agrupar([
        _electivo('suelto', const []),
        _electivo('b', [_ti]),
        _electivo('a', [_si]),
        _electivo('arq-ti', [_ti, _si]),
        _electivo('movil', [_software, _videojuegos]),
      ]);
      expect(grupos.keys.toList(), [_videojuegos, _software, _si, _ti, otros]);
    });

    test('dentro de cada grupo se respeta el orden de la malla', () {
      final grupos = agrupar([
        _electivo('primero', [_ti]),
        _electivo('segundo', [_ti]),
      ]);
      expect(_nombres(grupos[_ti]!), ['primero', 'segundo']);
    });

    test('sin electivos no hay grupos', () {
      expect(agrupar(const []), isEmpty);
    });
  });
}
