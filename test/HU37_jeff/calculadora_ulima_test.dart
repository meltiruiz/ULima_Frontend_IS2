// test/HU37_jeff/calculadora_ulima_test.dart
//
// WIDGET · Recarga desde la ULima (specs/features/recarga-portal/
// recarga-portal.spec.md), RF-RCG-5 y RF-RCG-7, la fila «Notas oficiales» y
// las notas de la ULima dentro de la calculadora.
// Archivos probados lib/pages/calculadora/**, lib/components/calculadora/**
// y lib/components/recarga_ulima/fila_notas_oficiales.dart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/calculadora/nota_tile.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/domain/malla/malla_entities.dart';
import 'package:ulima_plus/models/evaluation_model.dart';
import 'package:ulima_plus/pages/calculadora/calculadora_controller.dart';
import 'package:ulima_plus/pages/calculadora/calculadora_page.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/courses_service.dart';
import 'package:ulima_plus/services/evaluations_service.dart';
import 'package:ulima_plus/services/recarga_ulima_service.dart';

import 'recarga_dobles.dart';

const String _vistaGet = 'GET /grades/me/ulima';

EvaluationComponent _ev(String id, String nombre, String sigla, double peso) =>
    EvaluationComponent(
      id: id,
      nombre: nombre,
      sigla: sigla,
      peso: peso,
      tipo: 'continua',
    );

/// La calculadora con un curso sembrado, sin la carga remota de cursos y
/// sílabo, pero con el ApiClient falso y la conexión real a la ULima.
class _CalculadoraDePrueba extends CalculadoraController {
  _CalculadoraDePrueba({
    required ApiClient api,
    this.simuladas = const [],
    this.conCurso = true,
    this.errorCursos = false,
  }) : super(apiClient: api);

  final List<Map<String, dynamic>> simuladas;
  final bool conCurso;
  final bool errorCursos;
  final List<(int, int)> borradas = [];

  @override
  // ignore: must_call_super
  void onInit() {
    if (errorCursos) {
      cargaError.value = true;
    } else if (conCurso) {
      cursos.add({
        'id': '81',
        'nombre': 'TALLER DE PROTOTIPADO',
        'ciclo': '2026-2',
        'codigoSeccion': '812',
        'notas': <Map<String, dynamic>>[...simuladas].obs,
        '_promedio': 0.0,
        '_sumaPesos': 0.0,
      });
    }
    syllabusData['81'] = CourseSyllabus(
      cursoId: '81',
      cursoNombre: 'TALLER DE PROTOTIPADO',
      evaluaciones: [
        _ev('5011', 'Examen escrito', 'EV01', 15),
        _ev('5012', 'Práctica', 'PC01', 25),
        _ev('5013', 'Exposición', 'EX01', 20),
      ],
    );
    conectarUlima();
  }

  @override
  Future<void> eliminarNota(int cursoIndex, int notaIndex) async {
    borradas.add((cursoIndex, notaIndex));
  }
}

Map<String, dynamic> _simulada(String id, String titulo, int peso, double v) =>
    {'titulo': titulo, 'peso': peso, 'valor': v, 'evaluacionId': id};

/// Monta la calculadora. Sin [vista], no registra el servicio de la ULima.
Future<(_CalculadoraDePrueba, ApiRecargaFalsa)> _montar(
  WidgetTester tester, {
  Object? vista,
  bool conServicio = true,
  List<Map<String, dynamic>> simuladas = const [],
  bool conCurso = true,
  bool errorCursos = false,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  loguear(alumna());
  final api = ApiRecargaFalsa(calcularPromedio: true);
  if (vista != null) api.responder(_vistaGet, vista);
  if (conServicio) {
    Get.put<RecargaUlimaService>(RecargaUlimaService(apiClient: api));
  }
  final c =
      Get.put<CalculadoraController>(
            _CalculadoraDePrueba(
              api: api,
              simuladas: simuladas,
              conCurso: conCurso,
              errorCursos: errorCursos,
            ),
          )
          as _CalculadoraDePrueba;
  await tester.pumpWidget(
    GetMaterialApp(
      theme: const MaterialTheme(TextTheme()).light(),
      home: const CalculadoraPage(),
      getPages: [
        GetPage(
          name: '/mis-notas',
          page: () => const Scaffold(body: Text('PANTALLA DE NOTAS OFICIALES')),
        ),
      ],
    ),
  );
  await tester.pump();
  await tester.pump();
  return (c, api);
}

Map<String, dynamic> _vistaCon(
  List<Map<String, dynamic>> evaluaciones, {
  Object? lastReadAt = '2025-09-22T15:42:10.000Z',
}) => vistaJson(
  lastReadAt: lastReadAt,
  courses: [cursoJson(lastReadAt: lastReadAt, assessments: evaluaciones)],
);

/// `GET /grades/me/courses` con la sección 81 y su sílabo, que
/// `CoursesService` lee de `cursos` y `EvaluationSyllabusService` de
/// `syllabi`.
Map<String, dynamic> _cursosDelBackend() => <String, dynamic>{
  'cursos': [
    {
      'id': '690417',
      'nombre': 'TALLER DE PROTOTIPADO',
      'ciclo': '2026-2',
      'secciones': [
        {'idSeccion': '81', 'codigoSeccion': '812'},
      ],
    },
  ],
  'syllabi': [
    {
      'cursoId': '81',
      'cursoNombre': 'TALLER DE PROTOTIPADO',
      'evaluaciones': [
        {'id': '5011', 'nombre': 'Examen escrito', 'sigla': 'EV01', 'peso': 15},
        {'id': '5012', 'nombre': 'Práctica', 'sigla': 'PC01', 'peso': 25},
        {'id': '5013', 'nombre': 'Exposición', 'sigla': 'EX01', 'peso': 20},
      ],
    },
  ],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  group('WIDGET · la fila «Notas oficiales» (RF-RCG-5)', () {
    testWidgets('el birrete ya no está y la fila va bajo «Cursos con notas»', (
      tester,
    ) async {
      await _montar(tester, vista: vistaJson());

      expect(find.byTooltip('Notas oficiales'), findsNothing);
      expect(
        find.widgetWithIcon(IconButton, Icons.school_outlined),
        findsNothing,
      );
      expect(find.text('Notas oficiales'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Notas oficiales')).dy,
        greaterThan(
          tester.getTopLeft(find.textContaining('Cursos con notas')).dy,
        ),
      );
    });

    testWidgets('con lectura, «Última lectura …», y su Semantics de botón', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await _montar(tester, vista: vistaJson());

      expect(find.text('Última lectura $lecturaDePrueba'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Notas oficiales. Última lectura $lecturaDePrueba',
        ),
        findsWidgets,
      );
      semantica.dispose();
    });

    testWidgets('sin lectura, «Aún no se actualizan desde la ULima»', (
      tester,
    ) async {
      await _montar(tester, vista: vistaJson(lastReadAt: null));

      expect(find.text('Aún no se actualizan desde la ULima'), findsOneWidget);
    });

    testWidgets('sin vista, porque la carga falló o no hay servicio, solo el '
        'título', (tester) async {
      await _montar(tester, vista: errorApi(500, 'HTTP_ERROR'));
      expect(find.text('Notas oficiales'), findsOneWidget);
      expect(find.textContaining('Última lectura'), findsNothing);
      expect(find.text('Aún no se actualizan desde la ULima'), findsNothing);
    });

    testWidgets('sin el servicio registrado la fila también está, con solo el '
        'título', (tester) async {
      await _montar(tester, conServicio: false);

      expect(find.text('Notas oficiales'), findsOneWidget);
      expect(find.textContaining('Última lectura'), findsNothing);
    });

    testWidgets('con una vista previa y errorCarga en verdadero, la fila '
        'conserva la hora', (tester) async {
      final (_, api) = await _montar(tester, vista: vistaJson());
      api.responder(_vistaGet, errorApi(500, 'HTTP_ERROR'));

      await RecargaUlimaService.to.cargar();
      await tester.pump();

      expect(RecargaUlimaService.to.errorCarga, isTrue);
      expect(find.text('Última lectura $lecturaDePrueba'), findsOneWidget);
    });

    for (final (estado, conCurso, errorCursos) in <(String, bool, bool)>[
      ('con notas', true, false),
      ('sin notas', false, false),
      ('con el error de cursos', false, true),
    ]) {
      testWidgets('en el estado $estado, la fila lleva a /mis-notas', (
        tester,
      ) async {
        await _montar(
          tester,
          vista: vistaJson(),
          conCurso: conCurso,
          errorCursos: errorCursos,
        );

        await tester.tap(find.text('Notas oficiales'));
        await tester.pumpAndSettle();

        expect(find.text('PANTALLA DE NOTAS OFICIALES'), findsOneWidget);
      });
    }
  });

  group('WIDGET · las notas de la ULima en la calculadora (RF-RCG-7)', () {
    testWidgets(
      'una fila de la ULima lleva la marca «ULima», sin tacho, con su '
      'Semantics',
      (tester) async {
        final semantica = tester.ensureSemantics();
        await _montar(tester, vista: _vistaCon([evaluacionJson(value: 15)]));

        expect(find.text('Examen escrito 1'), findsOneWidget);
        expect(find.text('ULima'), findsOneWidget);
        expect(find.byIcon(Icons.delete_outline), findsNothing);
        expect(
          find.bySemanticsLabel(
            'Examen escrito 1, peso 15 por ciento, nota '
            '15.0 de 20, publicada por la ULima',
          ),
          findsWidgets,
        );
        semantica.dispose();
      },
    );

    testWidgets('un curso solo con notas de la ULima aparece y cuenta en '
        '«Cursos con notas»', (tester) async {
      await _montar(tester, vista: _vistaCon([evaluacionJson(value: 15)]));

      expect(find.text('Cursos con notas: 1'), findsOneWidget);
      expect(find.text('TALLER DE PROTOTIPADO'), findsOneWidget);
      expect(find.text('No hay notas registradas'), findsNothing);
    });

    testWidgets('el promedio y la suma de pesos cuentan las dos clases de '
        'filas, con NP como 0', (tester) async {
      final (_, api) = await _montar(
        tester,
        vista: _vistaCon([
          evaluacionJson(assessmentId: 5011, value: 14, weight: 15),
          evaluacionJson(
            assessmentId: 5013,
            mark: 'np',
            value: null,
            weight: 20,
          ),
        ]),
        simuladas: [_simulada('5012', 'Práctica', 25, 16)],
      );

      expect(api.cuerposDe('/grades/me/calculate').last, {
        'notas': [
          {'valor': 14.0, 'peso': 15.0},
          {'valor': 0.0, 'peso': 20.0},
          {'valor': 16.0, 'peso': 25.0},
        ],
      });
      // 14 · 0.15 + 16 · 0.25 = 6.10, con 15 + 20 + 25 de pesos.
      expect(find.text('6.10'), findsOneWidget);
      expect(find.text('Suma de pesos: 60.0% / 100%'), findsOneWidget);
      expect(
        find.textContaining('Peso: 20%  •  Nota: NP', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Peso: 15%  •  Nota: 14.0/20', findRichText: true),
        findsOneWidget,
      );
    });

    for (final (valor, desaprobado) in <(double, bool)>[
      (10.9, true),
      (11, false),
    ]) {
      testWidgets('con promedio $valor ${desaprobado ? '' : 'no '}se ve '
          '«Desaprobado», como hoy', (tester) async {
        await _montar(
          tester,
          vista: _vistaCon([evaluacionJson(value: valor, weight: 100)]),
        );

        expect(
          find.textContaining('Desaprobado'),
          desaprobado ? findsOneWidget : findsNothing,
        );
      });
    }

    testWidgets('el orden de las filas sigue al sílabo', (tester) async {
      await _montar(
        tester,
        vista: _vistaCon([evaluacionJson(assessmentId: 5012, value: 15)]),
        simuladas: [
          _simulada('5013', 'Exposición', 20, 12),
          _simulada('5011', 'Examen escrito', 15, 13),
        ],
      );

      final titulos = tester
          .widgetList<NotaTile>(find.byType(NotaTile))
          .map((t) => t.titulo)
          .toList();
      expect(titulos, ['Examen escrito', 'Examen escrito 1', 'Exposición']);
    });

    testWidgets('el tacho de una simulada que sigue a una fila de la ULima '
        "llama a eliminarNota con su índice en curso['notas']", (tester) async {
      // «Práctica» es la fila visible 1 y la simulada 0, así que la prueba
      // falla si CursoCard pasa la posición visible en lugar de su índice.
      final (c, _) = await _montar(
        tester,
        vista: _vistaCon([evaluacionJson(assessmentId: 5011, value: 15)]),
        simuladas: [
          _simulada('5012', 'Práctica', 25, 16),
          _simulada('5011', 'Examen escrito', 15, 13),
        ],
      );

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      expect(c.borradas, [(0, 0)]);
    });

    testWidgets('«Registrar Nota» no ofrece una evaluación ya publicada', (
      tester,
    ) async {
      final (c, _) = await _montar(
        tester,
        vista: _vistaCon([evaluacionJson(assessmentId: 5011, value: 15)]),
      );

      expect(c.getAvailableEvaluations(0).map((e) => e.id), ['5012', '5013']);
    });

    testWidgets('POST /grades/me/notes nunca lleva una nota de la ULima', (
      tester,
    ) async {
      final (c, api) = await _montar(
        tester,
        vista: _vistaCon([evaluacionJson(assessmentId: 5011, value: 15)]),
      );

      c.agregarNota(0, 'Práctica', 25, 16, '5012');
      await tester.pump();

      expect(api.cuerposDe('/grades/me/notes').single, {
        'cursos': [
          {
            'sectionId': 81,
            'notas': [
              {'assessmentId': 5012, 'valor': 16.0},
            ],
          },
        ],
      });
    });

    testWidgets('la línea del sílabo que no coincide', (tester) async {
      await _montar(
        tester,
        vista: _vistaCon([
          evaluacionJson(value: 15),
          evaluacionJson(
            key: '07.30',
            name: 'Examen extra',
            assessmentId: null,
            match: 'none',
          ),
        ]),
      );

      expect(
        find.text(
          'La ULima publica evaluaciones que no están en el sílabo '
          'cargado. Míralas en Notas oficiales.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.text('Examen extra'), findsNothing);
    });

    testWidgets('una vista nueva rehace las filas y la simulada oculta vuelve '
        'si la ULima retira la nota (B6)', (tester) async {
      final (_, api) = await _montar(
        tester,
        vista: _vistaCon([evaluacionJson(assessmentId: 5011, value: 15)]),
        simuladas: [_simulada('5011', 'Examen escrito', 15, 13)],
      );
      expect(find.text('ULima'), findsOneWidget);
      api.responder(_vistaGet, _vistaCon(const []));

      await RecargaUlimaService.to.cargar();
      await tester.pump();

      expect(find.text('ULima'), findsNothing);
      expect(find.text('Examen escrito'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('clear() quita las filas de la ULima sin pedir '
        'POST /grades/me/calculate, que en el cierre de sesión sale con el '
        'JWT ya revocado', (tester) async {
      final (_, api) = await _montar(
        tester,
        vista: _vistaCon([evaluacionJson(assessmentId: 5011, value: 15)]),
        simuladas: [_simulada('5011', 'Examen escrito', 15, 13)],
      );
      expect(find.text('ULima'), findsOneWidget);
      final promedios = api.cuerposDe('/grades/me/calculate').length;

      RecargaUlimaService.to.clear();
      await tester.pump();

      expect(api.cuerposDe('/grades/me/calculate'), hasLength(promedios));
      expect(find.text('ULima'), findsNothing);
      expect(find.text('Examen escrito'), findsOneWidget);
    });
  });

  group('WIDGET · la carga real con la vista ya cargada (RF-RCG-7)', () {
    testWidgets('_inicializarCursos pone las filas de la ULima de una vista '
        'que llega antes que los cursos y las manda al promedio', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);
      final cursosDeSiempre = CoursesService.instance;
      final silaboDeSiempre = EvaluationSyllabusService.instance;
      addTearDown(() {
        CoursesService.setTestInstance(cursosDeSiempre);
        EvaluationSyllabusService.setTestInstance(silaboDeSiempre);
      });
      loguear(
        alumna()
          ..courseProgress = CourseProgress(
            approvedLevels: <int>{},
            approvedElectives: <String>{},
            currentCourses: [
              {'idSeccion': '81'},
            ],
          ),
      );
      final api = ApiRecargaFalsa(calcularPromedio: true)
        ..responder(
          _vistaGet,
          _vistaCon([evaluacionJson(assessmentId: 5011, value: 15)]),
        )
        ..responder('GET /grades/me/courses', _cursosDelBackend())
        ..responder('GET /grades/me/notes', {
          'cursos': [
            {
              'sectionId': 81,
              'notas': [
                {'assessmentId': 5012, 'valor': 16},
              ],
            },
          ],
        });
      CoursesService.setTestInstance(CoursesService(apiClient: api));
      EvaluationSyllabusService.setTestInstance(
        EvaluationSyllabusService(apiClient: api),
      );
      Get.put<RecargaUlimaService>(RecargaUlimaService(apiClient: api));
      await RecargaUlimaService.to.cargar();
      expect(RecargaUlimaService.to.vista, isNotNull);

      // El controller real corre su onInit. El sílabo y los cursos llegan
      // después de conectarUlima(), así que solo _inicializarCursos pone las
      // filas de la ULima.
      Get.put<CalculadoraController>(CalculadoraController(apiClient: api));
      await tester.pumpWidget(
        GetMaterialApp(
          theme: const MaterialTheme(TextTheme()).light(),
          home: const CalculadoraPage(),
        ),
      );
      await tester.pump();
      await tester.pump();

      // La vista no vuelve a cambiar, así que su ever no rehace las filas.
      expect(api.veces(_vistaGet), 1);
      expect(find.text('Examen escrito 1'), findsOneWidget);
      expect(find.text('ULima'), findsOneWidget);
      expect(find.text('Práctica'), findsOneWidget);
      expect(api.cuerposDe('/grades/me/calculate').single, {
        'notas': [
          {'valor': 15.0, 'peso': 15.0},
          {'valor': 16.0, 'peso': 25.0},
        ],
      });
    });
  });
}
