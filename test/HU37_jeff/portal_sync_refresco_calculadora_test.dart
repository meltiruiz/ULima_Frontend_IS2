// test/HU37_jeff/portal_sync_refresco_calculadora_test.dart
//
// UNITARIA · Recarga desde la ULima (specs/features/recarga-portal/
// recarga-portal.spec.md), RF-RCG-11, la importación recarga la calculadora
// en vez de borrarla.
// Archivos probados lib/pages/portal_sync/portal_sync_controller.dart y el
// recargarTodo() de lib/pages/calculadora/calculadora_controller.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/domain/malla/malla_entities.dart';
import 'package:ulima_plus/pages/calculadora/calculadora_controller.dart';
import 'package:ulima_plus/pages/portal_sync/portal_sync_controller.dart';
import 'package:ulima_plus/services/courses_service.dart';
import 'package:ulima_plus/services/evaluations_service.dart';
import 'package:ulima_plus/services/portal_sync_service.dart';
import 'package:ulima_plus/services/recarga_ulima_service.dart';

import 'recarga_dobles.dart';

/// La calculadora sin carga remota, que cuenta sus recargas.
class _CalculadoraEspia extends CalculadoraController {
  int recargas = 0;

  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  Future<void> recargarTodo() async => recargas++;
}

/// Una importación que sale bien, sin token. Todo inventado.
Map<String, dynamic> _importOk() => <String, dynamic>{
  'period': {'id': 2, 'code': '2026-2'},
  'identity': {
    'portalCode': '20230001',
    'fullName': 'Alumna De Prueba',
    'career': 'CARRERA DE PRUEBA',
  },
  'summary': {'enrollmentsUpserted': 5},
  'warnings': <dynamic>[],
};

const String _vistaGet = 'GET /grades/me/ulima';
const String _cursosGet = 'GET /grades/me/courses';
const String _notasGet = 'GET /grades/me/notes';
const String _calcularPost = 'POST /grades/me/calculate';

/// `GET /grades/me/courses` con la sección 81 y su sílabo. De esta misma ruta
/// `CoursesService` lee `cursos` y `EvaluationSyllabusService` lee `syllabi`,
/// así que el sílabo es la primera de sus dos llamadas en cada carga.
Map<String, dynamic> _cursosDelBackend({
  required int pesoPractica,
}) => <String, dynamic>{
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
        {
          'id': '5012',
          'nombre': 'Práctica',
          'sigla': 'PC01',
          'peso': pesoPractica,
        },
      ],
    },
  ],
};

/// `GET /grades/me/notes` con la Práctica simulada en [valor].
Map<String, dynamic> _notasSimuladas(num valor) => <String, dynamic>{
  'cursos': [
    {
      'sectionId': 81,
      'notas': [
        {'assessmentId': 5012, 'valor': valor},
      ],
    },
  ],
};

/// La vista de la ULima con el examen escrito publicado en [valor].
Map<String, dynamic> _vistaConExamen(num valor) => vistaJson(
  courses: [
    cursoJson(assessments: [evaluacionJson(assessmentId: 5011, value: valor)]),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  test('tras una importación exitosa, CalculadoraController sigue registrado '
      'y su recargarTodo() corre una vez', () async {
    loguear(alumna());
    final calculadora =
        Get.put<CalculadoraController>(_CalculadoraEspia())
            as _CalculadoraEspia;
    final api = ApiRecargaFalsa()
      ..responder('POST /portal-sync/import', _importOk());
    final c = PortalSyncController(service: PortalSyncService(apiClient: api));
    c.aceptarConsentimiento();
    c.passwordCtrl.text = 'clave-de-prueba';
    c.passcodeCtrl.text = '482913';

    await c.submit();

    expect(c.step.value, PortalSyncStep.done);
    expect(Get.isRegistered<CalculadoraController>(), isTrue);
    expect(Get.find<CalculadoraController>(), same(calculadora));
    expect(calculadora.recargas, 1);
  });

  test('sin la calculadora registrada, la importación no la crea', () async {
    loguear(alumna());
    final api = ApiRecargaFalsa()
      ..responder('POST /portal-sync/import', _importOk());
    final c = PortalSyncController(service: PortalSyncService(apiClient: api));
    c.aceptarConsentimiento();
    c.passwordCtrl.text = 'clave-de-prueba';
    c.passcodeCtrl.text = '482913';

    await c.submit();

    expect(c.step.value, PortalSyncStep.done);
    expect(Get.isRegistered<CalculadoraController>(), isFalse);
  });

  test('el recargarTodo() real vuelve a pedir el sílabo, los cursos, las '
      'notas simuladas y la vista ya cargada de la ULima, y recalcula el '
      'promedio con los datos nuevos', () async {
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
    // Antes de importar, la Práctica pesa 25 en el sílabo, su simulada vale
    // 16 y la ULima publica un 15 en el examen escrito. Después de importar,
    // el backend responde 30, 18 y 17. Cada respuesta sale en orden y la
    // última se repite.
    final api = ApiRecargaFalsa(calcularPromedio: true)
      ..responder(_vistaGet, _vistaConExamen(15))
      ..responder(_vistaGet, _vistaConExamen(17))
      ..responder(_cursosGet, _cursosDelBackend(pesoPractica: 25))
      ..responder(_cursosGet, _cursosDelBackend(pesoPractica: 25))
      ..responder(_cursosGet, _cursosDelBackend(pesoPractica: 30))
      ..responder(_notasGet, _notasSimuladas(16))
      ..responder(_notasGet, _notasSimuladas(18))
      ..responder('POST /portal-sync/import', _importOk());
    CoursesService.setTestInstance(CoursesService(apiClient: api));
    EvaluationSyllabusService.setTestInstance(
      EvaluationSyllabusService(apiClient: api),
    );
    Get.put<RecargaUlimaService>(RecargaUlimaService(apiClient: api));
    await RecargaUlimaService.to.cargar();
    expect(RecargaUlimaService.to.vista, isNotNull);

    // El controller real corre su onInit. Con la vista ya cargada,
    // conectarUlima() no la vuelve a pedir.
    final calculadora = Get.put<CalculadoraController>(
      CalculadoraController(apiClient: api),
    );
    await pumpEventQueue();
    expect(api.veces(_vistaGet), 1);
    expect(api.veces(_cursosGet), 2);
    expect(api.veces(_notasGet), 1);
    expect(api.cuerposDe('/grades/me/calculate').last, {
      'notas': [
        {'valor': 15.0, 'peso': 15.0},
        {'valor': 16.0, 'peso': 25.0},
      ],
    });
    final antes = api.llamadas.length;

    final c = PortalSyncController(service: PortalSyncService(apiClient: api));
    c.aceptarConsentimiento();
    c.passwordCtrl.text = 'clave-de-prueba';
    c.passcodeCtrl.text = '482913';
    await c.submit();
    await pumpEventQueue();

    expect(c.step.value, PortalSyncStep.done);
    expect(Get.find<CalculadoraController>(), same(calculadora));
    final despues = api.llamadas.sublist(antes);
    int vecesDespues(String clave) => despues.where((l) => l == clave).length;
    // El sílabo y los cursos salen de GET /grades/me/courses, una vez cada
    // uno, porque refreshAfterImport() vacía los dos servicios.
    expect(vecesDespues(_cursosGet), 2);
    expect(vecesDespues(_notasGet), 1);
    // La vista ya estaba cargada y aun así sale de nuevo (RF-RCG-7).
    expect(vecesDespues(_vistaGet), 1);
    expect(vecesDespues(_calcularPost), greaterThanOrEqualTo(1));

    // Los datos nuevos llegan a la calculadora. El peso de la Práctica sale
    // del sílabo nuevo, la simulada de las notas nuevas y la fila de la
    // ULima de la vista nueva.
    expect(
      calculadora.syllabusData['81']!.evaluaciones
          .firstWhere((e) => e.id == '5012')
          .peso,
      30,
    );
    expect(api.cuerposDe('/grades/me/calculate').last, {
      'notas': [
        {'valor': 17.0, 'peso': 15.0},
        {'valor': 18.0, 'peso': 30.0},
      ],
    });
    expect(
      calculadora.calcularPromedio(0),
      closeTo(17 * 0.15 + 18 * 0.3, 1e-9),
    );
  });
}
