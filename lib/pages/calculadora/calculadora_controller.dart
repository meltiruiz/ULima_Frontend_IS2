import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../domain/recarga_ulima/filas_calculadora.dart';
import '../../models/evaluation_model.dart';
import '../../services/evaluations_service.dart';
import '../../services/courses_service.dart';
import '../../services/auth_service.dart';
import '../../services/api_client.dart';
import '../../services/recarga_ulima_service.dart';

class CalculadoraController extends GetxController {
  /// [apiClient] es para las pruebas. Sin él usa el `ApiClient` de siempre.
  CalculadoraController({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  late var cursos = <Map<String, dynamic>>[].obs;

  // Distingue "falló la carga de cursos" de "aún no registras notas": antes un
  // fallo del endpoint se veía igual que la calculadora vacía, sin pista del
  // error (ver docs/AUDITORIA_TECNICA.md §6.1). La vista muestra un ErrorRetry
  // cuando esto es true y no hay cursos cargados.
  final RxBool cargaError = false.obs;

  late EvaluationSyllabusService _syllabusService;
  late CoursesService _coursesService;
  final ApiClient _api;

  late var syllabusData = <String, CourseSyllabus>{}.obs;

  /// Hay una vista de la ULima del alumno actual (RF-RCG-5). Sin ella la fila
  /// «Notas oficiales» lleva solo el título.
  final RxBool hayVistaUlima = false.obs;

  /// La `lastReadAt` de esa vista, para la segunda línea de la fila.
  final Rxn<DateTime> ultimaLecturaUlima = Rxn<DateTime>();

  /// Escucha los cambios de la vista de la ULima. Lo cierra [onClose].
  Worker? _vistaUlima;

  @override
  void onInit() {
    super.onInit();
    _syllabusService = EvaluationSyllabusService();
    _coursesService = CoursesService();

    _cargarDatosSyllabus();
    _inicializarCursos();
    conectarUlima();
  }

  @override
  void onClose() {
    _vistaUlima?.dispose();
    super.onClose();
  }

  /// Llena las filas de la ULima desde `RecargaUlimaService` y las rehace con
  /// cada cambio de su vista (RF-RCG-7). La página nunca hace `Get.find` del
  /// servicio. Sin el servicio registrado, la calculadora queda como hoy.
  void conectarUlima() {
    if (!Get.isRegistered<RecargaUlimaService>()) return;
    final servicio = RecargaUlimaService.to;
    _vistaUlima?.dispose();
    _vistaUlima = servicio.alCambiarVista(aplicarVistaUlima);
    aplicarVistaUlima();
    if (servicio.vista == null) servicio.cargar();
  }

  /// Rehace las filas de la ULima de cada curso desde la vista del alumno
  /// actual y, con [recalcular], pide el promedio de los cursos que cambian.
  /// Un fallo de la carga sin vista previa deja la calculadora como hoy, y con
  /// vista previa del mismo alumno las filas siguen. Sin vista quita las filas
  /// y no pide el promedio, porque la vista queda en `null` solo con
  /// `RecargaUlimaService.clear()`. En el cierre de sesión ese `clear()` llega
  /// con el JWT ya revocado, y un `POST /grades/me/calculate` con ese token
  /// recibe un 401 que `ApiClient` trata como sesión expirada.
  void aplicarVistaUlima({bool recalcular = true}) {
    final vista = Get.isRegistered<RecargaUlimaService>()
        ? RecargaUlimaService.to.vista
        : null;
    hayVistaUlima.value = vista != null;
    ultimaLecturaUlima.value = vista?.lastReadAt;
    final cambiados = <int>[];
    for (var i = 0; i < cursos.length; i++) {
      final curso = cursos[i];
      final deUlima = vista?.cursos.firstWhereOrNull(
        (c) => '${c.sectionId}' == '${curso['id']}',
      );
      final notas = notasUlimaDeCurso(deUlima);
      final sinPareja = ulimaSinPareja(deUlima);
      if (mismasNotasUlima(curso[claveNotasUlima], notas) &&
          (curso[claveUlimaSinPareja] ?? false) == sinPareja) {
        continue;
      }
      curso[claveNotasUlima] = notas;
      curso[claveUlimaSinPareja] = sinPareja;
      cambiados.add(i);
    }
    if (cambiados.isEmpty) return;
    cursos.refresh();
    if (!recalcular || vista == null) return;
    for (final i in cambiados) {
      _calcularPromedio(i);
    }
  }

  /// Vuelve a pedir el sílabo, los cursos, las notas simuladas y la vista de
  /// la ULima, y recalcula los promedios (RF-RCG-11). Lo llama la importación
  /// en vez de borrar el controller.
  Future<void> recargarTodo() async {
    await _cargarDatosSyllabus();
    await _inicializarCursos();
    if (Get.isRegistered<RecargaUlimaService>()) {
      await RecargaUlimaService.to.cargar();
    }
  }

  Future<void> _cargarDatosSyllabus() async {
    try {
      await _syllabusService.loadEvaluationData();
      for (var syllabus in _syllabusService.allSyllabuses) {
        syllabusData[syllabus.cursoId] = syllabus;
      }
      debugPrint('Datos del silabo cargados en el controlador');
    } catch (e) {
      debugPrint('Error al cargar datos del silabo: $e');
    }
  }

  /// Reintenta la carga de cursos (botón "Reintentar" del estado de error).
  void recargar() => _inicializarCursos();

  Future<void> _inicializarCursos() async {
    try {
      final user = AuthService.to.currentUser;

      final List<Map<String, dynamic>> seccionesInscritas =
          user?.courseProgress?.currentCourses ?? [];
      await _coursesService.loadCoursesData();
      final cursosData = _coursesService.allCourses;

      final notasGuardadas = await _cargarNotasRemotas();

      List<Map<String, dynamic>> cursosExpandidos = [];

      for (var curso in cursosData) {
        List<dynamic> seccionesDelCurso = curso['secciones'] ?? [];

        for (var seccion in seccionesDelCurso) {
          bool estaInscrito = seccionesInscritas.any(
            (inscrito) => inscrito['idSeccion'] == seccion['idSeccion'],
          );

          if (!estaInscrito) continue;

          var notasRx = <Map<String, dynamic>>[].obs;
          final sectionIdStr = seccion['idSeccion'].toString();

          final notasDeApi = notasGuardadas[sectionIdStr];
          if (notasDeApi != null) {
            for (final n in notasDeApi) {
              final syllabus = syllabusData[sectionIdStr];
              final eval = syllabus?.evaluaciones.firstWhereOrNull(
                (e) => e.id == n['assessmentId'].toString(),
              );
              notasRx.add({
                'titulo': eval?.nombre ?? 'Evaluacion',
                'peso': eval?.peso.toInt() ?? 0,
                'valor': n['valor']?.toDouble() ?? 0.0,
                'evaluacionId': n['assessmentId'].toString(),
              });
            }
          }

          cursosExpandidos.add({
            'id': seccion['idSeccion'],
            'nombre': curso['nombre']?.toString() ?? 'Curso sin nombre',
            'ciclo': curso['ciclo']?.toString() ?? '2026-1',
            'codigoSeccion':
                seccion['codigoSeccion']?.toString() ?? 'Sin seccion',
            'notas': notasRx,
            '_promedio': 0.0,
            '_sumaPesos': 0.0,
          });
        }
      }

      cursos.value = cursosExpandidos;
      aplicarVistaUlima(recalcular: false);
      for (int i = 0; i < cursos.length; i++) {
        await _calcularPromedio(i);
      }
      // Limpiar el error al ÉXITO (no antes del await): durante un reintento se
      // mantiene el ErrorRetry hasta que la carga vuelve a completar bien.
      cargaError.value = false;
      debugPrint(
        'Cursos y secciones cargados correctamente: ${cursos.length} secciones.',
      );
    } catch (e) {
      debugPrint('Error al inicializar cursos: $e');
      cargaError.value = true;
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> _cargarNotasRemotas() async {
    try {
      final data = await _api.getJson('/grades/me/notes');
      final List<dynamic> cursosList = data['cursos'] as List? ?? [];
      final Map<String, List<Map<String, dynamic>>> result = {};
      for (final c in cursosList) {
        final sectionId = c['sectionId'].toString();
        result[sectionId] = (c['notas'] as List)
            .map((n) => Map<String, dynamic>.from(n as Map))
            .toList();
      }
      return result;
    } catch (e) {
      debugPrint('Error al cargar notas desde backend: $e');
      return {};
    }
  }

  Future<void> _guardarNotasRemotas() async {
    try {
      final payload = {
        'cursos': cursos
            .map(
              (curso) => {
                'sectionId': int.tryParse(curso['id']?.toString() ?? '') ?? 0,
                'notas': (curso['notas'] as List)
                    .map(
                      (nota) => {
                        'assessmentId':
                            int.tryParse(
                              nota['evaluacionId']?.toString() ?? '',
                            ) ??
                            0,
                        'valor': (nota['valor'] as num).toDouble(),
                      },
                    )
                    .toList(),
              },
            )
            .toList(),
      };
      await _api.postJson('/grades/me/notes', body: payload);
    } catch (e) {
      debugPrint('Error al guardar notas en backend: $e');
    }
  }

  Future<void> _calcularPromedio(int cursoIndex) async {
    if (cursoIndex < 0 || cursoIndex >= cursos.length) return;
    final curso = cursos[cursoIndex];
    try {
      // Las filas visibles, simuladas y de la ULima, con NP como 0 y el peso
      // exacto de la ULima (RF-RCG-7).
      final notasClean = notasParaPromedio(
        filasVisibles(
          simuladas: curso['notas'] as List,
          ulima: (curso[claveNotasUlima] as List?) ?? const [],
        ),
      );

      final result = await _api.postJson(
        '/grades/me/calculate',
        body: {'notas': notasClean},
      );
      cursos[cursoIndex]['_promedio'] = (result['promedio'] as num).toDouble();
      cursos[cursoIndex]['_sumaPesos'] = (result['sumaPesos'] as num)
          .toDouble();
      cursos.refresh();
    } catch (e) {
      debugPrint('Error al calcular promedio via API: $e');
      cursos[cursoIndex]['_promedio'] = 0.0;
      cursos[cursoIndex]['_sumaPesos'] = 0.0;
      cursos.refresh();
    }
  }

  double calcularPromedio(int cursoIndex) =>
      (cursos[cursoIndex]['_promedio'] as num?)?.toDouble() ?? 0.0;

  double sumaPesos(int cursoIndex) =>
      (cursos[cursoIndex]['_sumaPesos'] as num?)?.toDouble() ?? 0.0;

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
      _calcularPromedio(cursoIndex);
      _guardarNotasRemotas();
    }
  }

  Future<void> eliminarNota(int cursoIndex, int notaIndex) async {
    if (cursoIndex >= 0 && cursoIndex < cursos.length) {
      final notas = cursos[cursoIndex]['notas'] as RxList<dynamic>;
      if (notaIndex >= 0 && notaIndex < notas.length) {
        final nota = notas[notaIndex];
        final sectionId = cursos[cursoIndex]['id']?.toString();
        final assessmentId = nota['evaluacionId']?.toString();
        if (sectionId != null && assessmentId != null) {
          await _api.deleteJson('/grades/me/notes/$sectionId/$assessmentId');
        }
        notas.removeAt(notaIndex);
        _calcularPromedio(cursoIndex);
      }
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

  /// Las evaluaciones del sílabo sin nota simulada y sin una fila de la ULima
  /// visible (RF-RCG-7).
  List<EvaluationComponent> getAvailableEvaluations(int cursoIndex) {
    final allEvaluations = getEvaluationsForCourse(cursoIndex);
    final registeredIds = getRegisteredEvaluationIds(cursoIndex);
    final deUlima = cursoIndex >= 0 && cursoIndex < cursos.length
        ? idsConNotaUlima(cursos[cursoIndex])
        : const <String>{};
    return allEvaluations
        .where(
          (eval) =>
              !registeredIds.contains(eval.id) && !deUlima.contains(eval.id),
        )
        .toList();
  }

}
