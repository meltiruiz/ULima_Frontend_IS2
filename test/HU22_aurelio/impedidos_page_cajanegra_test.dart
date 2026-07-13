// test/HU22_aurelio/impedidos_page_cajanegra_test.dart
//
// CAJA NEGRA — HU22 (lista de impedidos como docente): visualizar, filtrar y
// buscar. Se evalúa AtRiskStudentsPage completa SOLO por entradas del docente
// y salidas visibles, sin conocer la implementación.
//
// Escenario: la sección 801 devuelve 3 alumnos
//   · Garcia (impedida, 40%) · Torres (en riesgo a 2 faltas, 21%) · Luna (normal, 5%)
//
// | Entrada del docente               | Salida esperada                                  |
// |-----------------------------------|--------------------------------------------------|
// | Abrir la lista de la sección      | 3 tarjetas ordenadas por % desc (Garcia primero), |
// |                                   | resumen 1/1/1 y chips con conteos                 |
// | Tocar el filtro "Impedidos (1)"   | solo la tarjeta de Garcia                         |
// | Volver a "Todos (3)"              | reaparecen las 3 tarjetas                         |
// | Escribir "tor" en el buscador     | solo Torres (por apellido, con debounce)          |
// | Escribir "20230003" (código)      | solo Luna                                         |
// | Escribir "zzz"                    | estado vacío "No se encontraron alumnos..."       |
//
// DOBLE DE PRUEBA: el fake reemplaza SOLO la carga HTTP (loadData); la
// búsqueda, los filtros y el orden son los REALES del controller — son la
// funcionalidad bajo prueba.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/at_risk_student_model.dart';
import 'package:ulima_plus/pages/teacher/at_risk_students_controller.dart';
import 'package:ulima_plus/pages/teacher/at_risk_students_page.dart';

class _AtRiskControllerFake extends AtRiskStudentsController {
  _AtRiskControllerFake(this._fijos);

  final List<AtRiskStudent> _fijos;

  @override
  Future<void> loadData(String sectionId) async {
    allStudents.value = _fijos;
    isLoading.value = false;
    loadError.value = false;
    setSortMode(SortMode.absenceDesc); // dispara el _applyFilter real
  }
}

AtRiskStudent alumno({
  required String code,
  required String firstName,
  required String lastName,
  required int absent,
  required String status,
  int? faltas,
}) =>
    AtRiskStudent(
      code: code,
      firstName: firstName,
      lastName: lastName,
      currentLevel: 5,
      cycle: 3,
      absentHours: absent,
      totalHours: 100,
      absencePercentage: absent.toDouble(),
      status: status,
      missingFaltas: faltas,
    );

final garcia = alumno(
    code: '20230001', firstName: 'Maria', lastName: 'Garcia Lopez', absent: 40, status: 'impedido');
final torres = alumno(
    code: '20230002', firstName: 'Luis', lastName: 'Torres Vega', absent: 21, status: 'en_riesgo', faltas: 2);
final luna = alumno(
    code: '20230003', firstName: 'Ana', lastName: 'Luna Paz', absent: 5, status: 'normal');

Future<void> abrirPagina(WidgetTester tester) async {
  // Viewport alto para que las 3 tarjetas se construyan sin scroll.
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  // Se siembra ANTES de pumpear: initState de la página reutiliza el
  // controller ya registrado (Get.isRegistered) y llama a loadData del fake.
  Get.put<AtRiskStudentsController>(_AtRiskControllerFake([luna, garcia, torres]));

  await tester.pumpWidget(GetMaterialApp(
    home: const AtRiskStudentsPage(
      sectionId: '42',
      courseName: 'Ingenieria de Software',
      sectionCode: '801',
    ),
  ));
  await tester.pump();
}

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  testWidgets('CN1: muestra los 3 alumnos ordenados por % de ausencia con resumen y estados', (tester) async {
    await abrirPagina(tester);

    // Encabezado de la sección.
    expect(find.text('Ingenieria de Software'), findsOneWidget);
    expect(find.text('Seccion 801'), findsOneWidget);

    // Las 3 tarjetas con su % y etiqueta de estado.
    expect(find.text('Maria Garcia Lopez'), findsOneWidget);
    expect(find.text('Luis Torres Vega'), findsOneWidget);
    expect(find.text('Ana Luna Paz'), findsOneWidget);
    expect(find.text('40.0%'), findsOneWidget);
    expect(find.text('Impedido'), findsOneWidget);
    expect(find.text('En Riesgo: a 2 faltas'), findsOneWidget);
    expect(find.text('Normal'), findsOneWidget);

    // Resumen 1/1/1 y chips de filtro con conteos.
    expect(find.text('1 Impedidos'), findsOneWidget);
    expect(find.text('1 En riesgo'), findsOneWidget);
    expect(find.text('1 Normal'), findsOneWidget);
    expect(find.text('Todos (3)'), findsOneWidget);
    expect(find.text('Impedidos (1)'), findsOneWidget);

    // Orden por % de ausencia descendente (aunque el fake sembró desordenado).
    final yGarcia = tester.getTopLeft(find.text('Maria Garcia Lopez')).dy;
    final yTorres = tester.getTopLeft(find.text('Luis Torres Vega')).dy;
    final yLuna = tester.getTopLeft(find.text('Ana Luna Paz')).dy;
    expect(yGarcia, lessThan(yTorres));
    expect(yTorres, lessThan(yLuna));
  });

  testWidgets('CN2: el filtro "Impedidos" deja solo a Garcia y "Todos" restaura la lista', (tester) async {
    await abrirPagina(tester);

    await tester.tap(find.text('Impedidos (1)'));
    await tester.pump();

    expect(find.text('Maria Garcia Lopez'), findsOneWidget);
    expect(find.text('Luis Torres Vega'), findsNothing);
    expect(find.text('Ana Luna Paz'), findsNothing);

    await tester.tap(find.text('Todos (3)'));
    await tester.pump();

    expect(find.text('Luis Torres Vega'), findsOneWidget);
    expect(find.text('Ana Luna Paz'), findsOneWidget);
  });

  testWidgets('CN3: la búsqueda filtra por apellido o código con debounce y muestra vacío si no hay match', (tester) async {
    await abrirPagina(tester);

    // Por apellido (insensible a mayúsculas, espera el debounce de 300ms).
    await tester.enterText(find.byType(TextField), 'tor');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Luis Torres Vega'), findsOneWidget);
    expect(find.text('Maria Garcia Lopez'), findsNothing);
    expect(find.text('Ana Luna Paz'), findsNothing);

    // Por código exacto.
    await tester.enterText(find.byType(TextField), '20230003');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Ana Luna Paz'), findsOneWidget);
    expect(find.text('Luis Torres Vega'), findsNothing);

    // Sin coincidencias -> estado vacío específico de búsqueda.
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('No se encontraron alumnos con ese codigo o apellido'), findsOneWidget);
  });
}
