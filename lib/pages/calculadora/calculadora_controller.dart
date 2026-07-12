import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../domain/notas/notas_calculo.dart' as notas_calculo;
import '../../models/evaluation_model.dart';
import '../../services/evaluations_service.dart';
import '../../services/courses_service.dart';
import '../../services/notas_service.dart';
import '../../services/simulated_grades_service.dart';
import '../../services/auth_service.dart';

class CalculadoraController extends GetxController {
  late var cursos = <Map<String, dynamic>>[].obs;

  late EvaluationSyllabusService _syllabusService;
  late CoursesService _coursesService;
  late NotasService _notasService;
  late SimulatedGradesService _simGradesService;

  late String _idEstudianteActual;

  late var syllabusData = <String, CourseSyllabus>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _syllabusService = EvaluationSyllabusService();
    _coursesService = CoursesService();
    _notasService = NotasService();
    _simGradesService = SimulatedGradesService();

    _cargarDatosSyllabus();
    _inicializarCursos();
  }

  void _cargarDatosSyllabus() async {
    try {
      await _syllabusService.loadEvaluationData();
      for (var syllabus in _syllabusService.allSyllabuses) {
        syllabusData[syllabus.cursoId] = syllabus;
      }
      debugPrint('✓ Datos del sílabo cargados en el controlador');
    } catch (e) {
      debugPrint('✗ Error al cargar datos del sílabo: $e');
    }
  }

  void _inicializarCursos() async {
    try {
      final user = AuthService.to.currentUser;

      final List<Map<String, dynamic>> seccionesInscritas =
          user?.courseProgress?.currentCourses ?? [];
      _idEstudianteActual =
          await _notasService.obtenerIdEstudianteActual() ?? 'default';
      // Reintenta la carga si el arranque falló (p. ej. la app inició sin
      // sesión): loadCoursesData es idempotente y sale de inmediato si ya
      // cargó; sin esto, la calculadora quedaba vacía para siempre.
      await _coursesService.loadCoursesData();
      final cursosData = _coursesService.allCourses;
      final notasGuardadas = await _notasService.cargarNotas(
        _idEstudianteActual,
      );

      List<Map<String, dynamic>> cursosExpandidos = [];

      for (var curso in cursosData) {
        List<dynamic> seccionesDelCurso = curso['secciones'] ?? [];

        for (var seccion in seccionesDelCurso) {
          bool estaInscrito = seccionesInscritas.any(
            (inscrito) => inscrito['idSeccion'] == seccion['idSeccion'],
          );

          if (!estaInscrito) continue;

          var notasRx = <Map<String, dynamic>>[].obs;

          Map<String, dynamic>? cursoBuscado = notasGuardadas.firstWhereOrNull(
            (n) => n['id'] == seccion['idSeccion'],
          );

          if (cursoBuscado != null && cursoBuscado['notas'] != null) {
            notasRx.addAll(
              List<Map<String, dynamic>>.from(cursoBuscado['notas']),
            );
          }

          cursosExpandidos.add({
            'id': seccion['idSeccion'],
            'nombre': curso['nombre']?.toString() ?? 'Curso sin nombre',
            'ciclo': curso['ciclo']?.toString() ?? '2026-1',
            'codigoSeccion':
                seccion['codigoSeccion']?.toString() ?? 'Sin sección',
            'notas': notasRx,
          });
        }
      }

      cursos.value = cursosExpandidos;
      debugPrint(
        '✓ Cursos y secciones cargados correctamente: ${cursos.length} secciones.',
      );

      // Sincroniza con el backend (fuente de verdad entre dispositivos). Si el
      // backend no responde, se conservan las notas locales ya cargadas.
      await _sincronizarConBackend();
    } catch (e) {
      debugPrint('✗ Error al inicializar cursos: $e');
    }
  }

  /// Trae las notas simuladas del backend y las fusiona con lo mostrado:
  /// el backend es la fuente de verdad; las notas que solo existían en local
  /// (aún no subidas) se conservan y se suben (migración one-time). Reconstruye
  /// título/peso desde el sílabo. Ante cualquier error, mantiene lo local.
  Future<void> _sincronizarConBackend() async {
    try {
      await _syllabusService.loadEvaluationData(); // idempotente; da título/peso
      final backend = await _simGradesService.fetchAll();

      final bySection = <String, List<Map<String, dynamic>>>{};
      for (final g in backend) {
        (bySection[g['sectionId'].toString()] ??= []).add(g);
      }

      for (final curso in cursos) {
        final sectionId = curso['id'].toString();
        final evals = _syllabusService.getEvaluationsByCourseId(sectionId);
        final notas = curso['notas'] as RxList<dynamic>;

        final merged = <Map<String, dynamic>>[];
        final seen = <String>{};

        // 1) Notas del backend (fuente de verdad).
        for (final g in (bySection[sectionId] ?? const [])) {
          final evalId = g['assessmentId'].toString();
          final ev = evals.firstWhereOrNull((e) => e.id == evalId);
          merged.add({
            'titulo': ev?.nombre ?? 'Evaluación',
            'peso': ev?.peso ?? 0,
            'valor': g['value'],
            'evaluacionId': evalId,
          });
          seen.add(evalId);
        }

        // 2) Notas presentes solo en local: se conservan y se suben al backend.
        for (final ln in List<Map<String, dynamic>>.from(notas)) {
          final evalId = ln['evaluacionId']?.toString();
          if (evalId == null || evalId.isEmpty || seen.contains(evalId)) continue;
          merged.add(ln);
          seen.add(evalId);
          final aid = int.tryParse(evalId);
          final valor = double.tryParse(ln['valor']?.toString() ?? '');
          if (aid != null && valor != null) {
            _simGradesService.upsertOne(aid, valor).catchError(
              (e) => debugPrint('✗ subir nota local al backend: $e'),
            );
          }
        }

        notas.assignAll(merged);
      }

      cursos.refresh();
      _guardarNotasLocal(); // refresca la caché local con lo sincronizado
    } catch (e) {
      debugPrint('✗ No se pudo sincronizar notas con el backend, uso local: $e');
    }
  }

  // El cálculo puro vive en lib/domain/notas/ para poder testearlo (TT03).
  double calcularPromedio(List notas) => notas_calculo.calcularPromedioPonderado(notas);

  double sumaPesos(List notas) => notas_calculo.sumaDePesos(notas);

  void agregarNota(
    int cursoIndex,
    String titulo,
    int peso,
    double valor,
    String evaluacionId,
  ) {
    if (cursoIndex >= 0 && cursoIndex < cursos.length) {
      final notas = cursos[cursoIndex]['notas'] as RxList<dynamic>;
      notas.add({
        'titulo': titulo,
        'peso': peso,
        'valor': valor,
        'evaluacionId': evaluacionId,
      });
      cursos.refresh();
      _guardarNotasLocal();

      // Persiste en el backend (optimista): si falla, la nota queda en local.
      final aid = int.tryParse(evaluacionId);
      if (aid != null) {
        _simGradesService.upsertOne(aid, valor).catchError(
          (e) => debugPrint('✗ guardar nota en backend: $e'),
        );
      }
    }
  }

  void eliminarNota(int cursoIndex, int notaIndex) {
    if (cursoIndex >= 0 && cursoIndex < cursos.length) {
      final notas = cursos[cursoIndex]['notas'] as RxList<dynamic>;
      if (notaIndex >= 0 && notaIndex < notas.length) {
        final removed = Map<String, dynamic>.from(notas[notaIndex] as Map);
        notas.removeAt(notaIndex);
        cursos.refresh();
        _guardarNotasLocal();

        // Borra también en el backend.
        final evalId = removed['evaluacionId']?.toString();
        final aid = evalId != null ? int.tryParse(evalId) : null;
        if (aid != null) {
          _simGradesService.deleteOne(aid).catchError(
            (e) => debugPrint('✗ borrar nota en backend: $e'),
          );
        }
      }
    }
  }

  void _guardarNotasLocal() async {
    try {
      await _notasService.guardarNotas(_idEstudianteActual, cursos);
    } catch (e) {
      debugPrint('✗ Error al guardar notas localmente: $e');
    }
  }

  CourseSyllabus? getSyllabusForCourse(int cursoIndex) {
    if (cursoIndex >= 0 && cursoIndex < cursos.length) {
      final cursoId = cursos[cursoIndex]['id'] as String?;
      if (cursoId != null && syllabusData.containsKey(cursoId)) {
        return syllabusData[cursoId];
      }
    }
    return null;
  }

  List<EvaluationComponent> getEvaluationsForCourse(int cursoIndex) {
    final syllabus = getSyllabusForCourse(cursoIndex);
    return syllabus?.evaluaciones ?? [];
  }

  bool hasSyllabusData(int cursoIndex) {
    if (cursoIndex >= 0 && cursoIndex < cursos.length) {
      final cursoId = cursos[cursoIndex]['id'] as String?;
      return cursoId != null && syllabusData.containsKey(cursoId);
    }
    return false;
  }

  List<String> getRegisteredEvaluationIds(int cursoIndex) {
    if (cursoIndex >= 0 && cursoIndex < cursos.length) {
      final notas = cursos[cursoIndex]['notas'] as List?;
      return (notas ?? [])
          .map((nota) => nota['evaluacionId'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
    }
    return [];
  }

  List<EvaluationComponent> getAvailableEvaluations(int cursoIndex) {
    final allEvaluations = getEvaluationsForCourse(cursoIndex);
    final registeredIds = getRegisteredEvaluationIds(cursoIndex);
    return allEvaluations
        .where((eval) => !registeredIds.contains(eval.id))
        .toList();
  }
}
