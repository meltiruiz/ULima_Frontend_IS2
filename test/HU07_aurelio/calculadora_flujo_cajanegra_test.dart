// test/HU07_aurelio/calculadora_flujo_cajanegra_test.dart
//
// CAJA NEGRA — HU06 + HU07 (calculadora): registrar una nota y ver el promedio.
// Se evalúa la pantalla Calculadora completa (CalculadoraPage +
// AddNotaWithSyllabusModal + CursoCard) SOLO por entradas del usuario y
// salidas visibles, sin conocer la implementación interna.
//
// | Entrada del usuario                       | Salida esperada                            |
// |-------------------------------------------|--------------------------------------------|
// | Abrir la calculadora sin notas            | "No hay notas registradas" · contador 0    |
// | "Registrar Nota" y confirmar sin escribir | "La nota es requerida"                     |
// | Escribir "abc" y Registrar                | "Ingresa un número válido"                 |
// | Escribir "25" y Registrar                 | "La nota debe estar entre 0 y 20"          |
// | Escribir "15" y Registrar                 | snackbar "PA registrada" y modal cerrado   |
// | Mirar la tarjeta del curso                | promedio 4.50 · "Suma de pesos: 30.0%..."  |
// | Eliminar la nota confirmando el diálogo   | vuelve a "No hay notas registradas"        |
//
// DOBLE DE PRUEBA: el backend se reemplaza en el borde del controller — el
// fake replica la fórmula de POST /grades/me/calculate (promedio =
// Σ valor·peso/100, la misma de grades.logic.ts, cubierta por bun test en
// ULima_Backend_IS2/test/HU07_aurelio). La UI real no se modifica.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/evaluation_model.dart';
import 'package:ulima_plus/pages/calculadora/calculadora_controller.dart';
import 'package:ulima_plus/pages/calculadora/calculadora_page.dart';

class _CalculadoraControllerFake extends CalculadoraController {
  _CalculadoraControllerFake({this.conNota = false});

  final bool conNota;

  @override
  // ignore: must_call_super
  void onInit() {
    // Reemplaza la carga remota de onInit (sílabo + cursos + notas) por datos
    // sembrados: un curso de la sección 'sec1' con 3 evaluaciones en el sílabo.
    cursos.add({
      'id': 'sec1',
      'nombre': 'Ingenieria de Software',
      'ciclo': '2026-1',
      'codigoSeccion': '801',
      'notas': <Map<String, dynamic>>[
        if (conNota)
          {'titulo': 'Parcial', 'peso': 30, 'valor': 15.0, 'evaluacionId': 'ev1'},
      ].obs,
      '_promedio': conNota ? 4.5 : 0.0,
      '_sumaPesos': conNota ? 30.0 : 0.0,
    });
    syllabusData['sec1'] = CourseSyllabus(
      cursoId: 'sec1',
      cursoNombre: 'Ingenieria de Software',
      evaluaciones: [
        EvaluationComponent(id: 'ev1', nombre: 'Parcial', sigla: 'PA', peso: 30, tipo: 'parcial'),
        EvaluationComponent(id: 'ev2', nombre: 'Final', sigla: 'EF', peso: 40, tipo: 'final'),
        EvaluationComponent(id: 'ev3', nombre: 'Trabajo', sigla: 'TR', peso: 30, tipo: 'continua'),
      ],
    );
  }

  // Réplica local del cálculo del backend (POST /grades/me/calculate).
  void _recalcular(int i) {
    final notas = cursos[i]['notas'] as List;
    double promedio = 0;
    double suma = 0;
    for (final n in notas) {
      promedio += (n['valor'] as num) * ((n['peso'] as num) / 100);
      suma += (n['peso'] as num).toDouble();
    }
    cursos[i]['_promedio'] = promedio;
    cursos[i]['_sumaPesos'] = suma;
    cursos.refresh();
  }

  @override
  void agregarNota(int cursoIndex, String titulo, int peso, double valor, String evaluacionId) {
    (cursos[cursoIndex]['notas'] as RxList).add({
      'titulo': titulo,
      'peso': peso,
      'valor': valor,
      'evaluacionId': evaluacionId,
    });
    _recalcular(cursoIndex);
  }

  @override
  Future<void> eliminarNota(int cursoIndex, int notaIndex) async {
    (cursos[cursoIndex]['notas'] as RxList).removeAt(notaIndex);
    _recalcular(cursoIndex);
  }
}

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  testWidgets('CN1: valida vacío/abc/25, registra 15 y muestra promedio 4.50 con 30/100 de pesos', (tester) async {
    Get.put<CalculadoraController>(_CalculadoraControllerFake());

    await tester.pumpWidget(GetMaterialApp(home: const CalculadoraPage()));
    await tester.pump();

    // Estado inicial: hay un curso inscrito pero sin notas registradas.
    expect(find.text('No hay notas registradas'), findsOneWidget);
    expect(find.text('Cursos con notas: 0'), findsOneWidget);

    // Abre el modal (con un único curso va directo, sin selector de curso).
    await tester.tap(find.text('Registrar Nota'));
    await tester.pumpAndSettle();

    // Selecciona la evaluación "Parcial" del sílabo (peso automático 30%).
    // (se toca el DropdownButton: su hint no participa del hit-test)
    await tester.tap(find.byType(DropdownButton<EvaluationComponent>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Parcial').last);
    await tester.pumpAndSettle();
    expect(find.text('Peso automático:'), findsOneWidget);

    // Confirmar sin escribir -> requerida.
    await tester.tap(find.text('Registrar'));
    await tester.pump();
    expect(find.text('La nota es requerida'), findsOneWidget);

    // Entrada no numérica.
    await tester.enterText(find.byType(TextField), 'abc');
    await tester.tap(find.text('Registrar'));
    await tester.pump();
    expect(find.text('Ingresa un número válido'), findsOneWidget);

    // Fuera del rango 0-20.
    await tester.enterText(find.byType(TextField), '25');
    await tester.tap(find.text('Registrar'));
    await tester.pump();
    expect(find.text('La nota debe estar entre 0 y 20'), findsOneWidget);

    // Nota válida -> se registra, el modal se cierra y aparece el snackbar.
    await tester.enterText(find.byType(TextField), '15');
    await tester.tap(find.text('Registrar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('PA registrada'), findsOneWidget);

    // HU07: la tarjeta muestra el promedio ponderado (15·0.30 = 4.50) y el
    // avance de pesos; con menos de 11 aparece la marca de desaprobado.
    expect(find.text('4.50'), findsOneWidget);
    expect(find.text('Suma de pesos: 30.0% / 100%'), findsOneWidget);
    expect(find.text('Cursos con notas: 1'), findsOneWidget);
    expect(find.textContaining('Desaprobado'), findsOneWidget);

    // Deja expirar el snackbar (2s) para no dejar timers pendientes.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('CN2: eliminar la única nota deja la calculadora vacía otra vez', (tester) async {
    Get.put<CalculadoraController>(_CalculadoraControllerFake(conNota: true));

    await tester.pumpWidget(GetMaterialApp(home: const CalculadoraPage()));
    await tester.pump();

    // Con la nota sembrada, la tarjeta ya muestra el promedio.
    expect(find.text('4.50'), findsOneWidget);
    expect(find.text('Cursos con notas: 1'), findsOneWidget);

    // Elimina la nota confirmando el diálogo.
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Eliminar Nota'), findsOneWidget);

    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(find.text('No hay notas registradas'), findsOneWidget);
    expect(find.text('Cursos con notas: 0'), findsOneWidget);
  });
}
