// test/HU06_aurelio/calculadora_evaluaciones_unitaria_test.dart
//
// UNITARIA — HU06 (calculadora): evaluaciones disponibles según el sílabo.
// Métodos: CalculadoraController.getRegisteredEvaluationIds() /
//          getAvailableEvaluations() / hasSyllabusData()
//          lib/pages/calculadora/calculadora_controller.dart
//
// REGLA: una evaluación ya registrada NO debe volver a ofrecerse en el
// dropdown del modal (AddNotaWithSyllabusModal se alimenta de estos métodos).
//
// AISLAMIENTO (sin mocks): el controller se construye DIRECTO, sin Get.put(),
// así GetX no dispara onInit() y no hay llamadas de red; `cursos` y
// `syllabusData` se siembran a mano porque se inicializan inline.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/evaluation_model.dart';
import 'package:ulima_plus/pages/calculadora/calculadora_controller.dart';

EvaluationComponent evaluacion(String id, String nombre, String sigla, double peso) =>
    EvaluationComponent(id: id, nombre: nombre, sigla: sigla, peso: peso, tipo: 'continua');

/// Controller con un curso (sección 'sec1') que ya tiene registrada la
/// evaluación 'ev1' de un sílabo con 3 evaluaciones.
CalculadoraController sembrado() {
  final c = CalculadoraController();
  c.cursos.add({
    'id': 'sec1',
    'nombre': 'Ingenieria de Software',
    'ciclo': '2026-1',
    'codigoSeccion': '801',
    'notas': <Map<String, dynamic>>[
      {'titulo': 'Parcial', 'peso': 30, 'valor': 15.0, 'evaluacionId': 'ev1'},
    ].obs,
    '_promedio': 0.0,
    '_sumaPesos': 0.0,
  });
  c.syllabusData['sec1'] = CourseSyllabus(
    cursoId: 'sec1',
    cursoNombre: 'Ingenieria de Software',
    evaluaciones: [
      evaluacion('ev1', 'Parcial', 'PA', 30),
      evaluacion('ev2', 'Final', 'EF', 40),
      evaluacion('ev3', 'Trabajo', 'TR', 30),
    ],
  );
  return c;
}

void main() {
  group('UNITARIA · CalculadoraController — evaluaciones del sílabo (HU06)', () {
    test('getRegisteredEvaluationIds devuelve solo los ids de las notas registradas', () {
      final c = sembrado();

      expect(c.getRegisteredEvaluationIds(0), ['ev1']);
    });

    test('getAvailableEvaluations excluye la evaluación ya registrada (regla anti-duplicado)', () {
      final c = sembrado();

      final disponibles = c.getAvailableEvaluations(0).map((e) => e.id).toList();

      expect(disponibles, ['ev2', 'ev3']);
      expect(disponibles, isNot(contains('ev1')));
    });

    test('índices fuera de rango devuelven listas vacías sin lanzar', () {
      final c = sembrado();

      expect(c.getAvailableEvaluations(99), isEmpty);
      expect(c.getRegisteredEvaluationIds(-1), isEmpty);
      expect(c.getSyllabusForCourse(99), isNull);
    });

    test('curso sin sílabo cargado: hasSyllabusData false y sin evaluaciones disponibles', () {
      final c = sembrado();
      c.cursos.add({
        'id': 'sec2',
        'nombre': 'Curso sin silabo',
        'ciclo': '2026-1',
        'codigoSeccion': '802',
        'notas': <Map<String, dynamic>>[].obs,
        '_promedio': 0.0,
        '_sumaPesos': 0.0,
      });

      expect(c.hasSyllabusData(0), isTrue);
      expect(c.hasSyllabusData(1), isFalse);
      expect(c.getAvailableEvaluations(1), isEmpty);
    });

    test('notas con evaluacionId vacío se filtran del listado de registradas', () {
      final c = sembrado();
      (c.cursos[0]['notas'] as RxList).add({
        'titulo': 'Huerfana',
        'peso': 10,
        'valor': 12.0,
        'evaluacionId': '',
      });

      expect(c.getRegisteredEvaluationIds(0), ['ev1']);
    });
  });
}
