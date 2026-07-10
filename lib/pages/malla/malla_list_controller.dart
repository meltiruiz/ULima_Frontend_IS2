// lib/pages/malla/malla_list_controller.dart
// Controller de la vista lista de la malla (HU19, issues #91/#92).
//
// Reemplaza al lienzo 2D con una lista vertical por ciclos:
// - Modo normal: solo lectura. Muestra el progreso REAL del alumno
//   (computeStatuses); el tap resalta prerrequisitos/desbloqueos.
// - Modo simulación: copia de trabajo (simStatuses) que parte del progreso
//   real + la simulación persistida, cicla estados con tap y recalcula la
//   disponibilidad con efecto dominó completo (cascada hasta punto fijo).
//   Guardar persiste con el MISMO mecanismo/formato que la vista clásica
//   (PUT/DELETE /curriculum/me/simulation + StorageService), de modo que la
//   vista vieja y el backend siguen entendiendo la simulación.
//
// Toda la lógica de dominio vive en lib/domain/malla/malla_logic.dart.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/malla/malla_logic.dart' as malla_logic;
import '../../models/malla_models.dart';
import '../../models/user_model.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/evaluations_service.dart';
import '../../services/malla_service.dart';
import '../../services/storage_service.dart';

/// Filtros de la fila de chips bajo el header.
enum MallaListFilter { todos, disponibles, cursando, pendientes, electivos }

extension MallaListFilterX on MallaListFilter {
  String get label {
    switch (this) {
      case MallaListFilter.todos:
        return 'Todos';
      case MallaListFilter.disponibles:
        return 'Disponibles';
      case MallaListFilter.cursando:
        return 'Cursando';
      case MallaListFilter.pendientes:
        return 'Pendientes';
      case MallaListFilter.electivos:
        return 'Electivos';
    }
  }
}

/// Rol de una card cuando hay un curso resaltado.
enum CourseHighlightRole { none, selected, prerequisite, unlocks, dimmed }

class MallaListController extends GetxController {
  static const String otherElectivesGroup = 'Otros electivos';

  // ── Estado base ─────────────────────────────────────────────────────────────
  final loading = true.obs;
  final error = RxnString();
  final cards = <CourseNode>[].obs;

  /// Estados REALES (progreso del alumno, sin simulación).
  final realStatuses = <String, CourseStatus>{}.obs;

  // ── Modo simulación ─────────────────────────────────────────────────────────
  final simulationMode = false.obs;
  final saving = false.obs;

  /// Copia de trabajo de la simulación (solo válida en modo simulación).
  final simStatuses = <String, CourseStatus>{}.obs;
  Map<String, CourseStatus> _simEntrySnapshot = <String, CourseStatus>{};

  // ── Estado de UI ────────────────────────────────────────────────────────────
  final filter = MallaListFilter.todos.obs;
  final expandedLevels = <int>{}.obs;
  final electivesExpanded = false.obs;
  final highlightedCourseId = RxnString();

  late final MallaService _malla;
  late final AuthService _auth;
  Worker? _userWorker;

  UserModel? get user => _auth.currentUser;

  @override
  void onInit() {
    super.onInit();
    _malla = MallaService.to;
    _auth = AuthService.to;
    _userWorker = ever<UserModel?>(_auth.currentUserRx, (_) {
      if (!loading.value) _handleUserChanged();
    });
    _bootstrap();
  }

  @override
  void onClose() {
    _userWorker?.dispose();
    super.onClose();
  }

  // ── Carga ───────────────────────────────────────────────────────────────────

  Future<void> _bootstrap() async {
    loading.value = true;
    error.value = null;
    try {
      await _malla.load();
      // HU21: precargar sílabos en segundo plano (best-effort). NO debe
      // bloquear ni tumbar el render de la malla si el endpoint tarda o falla.
      _preloadSyllabus();
      _rebuild();
      _initExpansion();
    } catch (_) {
      error.value =
          'No pudimos cargar tu malla. Revisa tu conexión e inténtalo de nuevo.';
    } finally {
      loading.value = false;
    }
  }

  Future<void> _preloadSyllabus() async {
    try {
      await EvaluationSyllabusService().loadEvaluationData();
    } catch (_) {
      // Silencioso: la precarga de sílabos es opcional para el sheet de curso.
    }
  }

  Future<void> retry() => _bootstrap();

  void _handleUserChanged() {
    _rebuild();
    if (simulationMode.value) _recascadeSim();
  }

  void _rebuild() {
    final u = user;
    if (u == null) {
      cards.clear();
      realStatuses.clear();
      return;
    }
    // Igual que la vista clásica: los electivos con simulación persistida se
    // mantienen visibles aunque ya no coincidan con la especialidad elegida.
    final include = <String>{
      ..._malla.simulation.keys,
      ..._persistentSavedIds(u.code),
    };
    final visible = _malla.visibleCoursesFor(u, includeCourseIds: include);
    visible.sort(
      (a, b) => a.level != b.level ? a.level - b.level : a.row - b.row,
    );
    cards.assignAll(visible);

    final computed = _malla.computeStatuses(u);
    realStatuses.assignAll({
      for (final c in visible) c.id: computed[c.id] ?? CourseStatus.locked,
    });
  }

  Set<String> _persistentSavedIds(String? code) {
    final saved = _savedLocalStatuses(code);
    if (saved == null) return const <String>{};
    return saved.entries
        .where((e) => malla_logic.isPersistentStatus(e.value))
        .map((e) => e.key)
        .toSet();
  }

  Map<String, CourseStatus>? _savedLocalStatuses(String? code) {
    final userSaved =
        code == null ? null : StorageService.to.savedStatusesFor(code);
    return userSaved ?? StorageService.to.savedStatuses;
  }

  void _initExpansion() {
    expandedLevels.clear();
    final lvl = currentStudentLevel;
    if (lvl != null) expandedLevels.add(lvl);
  }

  /// Ciclo "actual" del alumno: el menor nivel con obligatorios pendientes
  /// (misma heurística que la vista clásica).
  int? get currentStudentLevel {
    final pendingMandatory = cards
        .where(
          (c) =>
              !c.isElective && realStatuses[c.id] != CourseStatus.approved,
        )
        .toList();
    if (pendingMandatory.isNotEmpty) {
      return pendingMandatory
          .map((c) => c.level)
          .reduce((a, b) => a < b ? a : b);
    }
    final pending = cards
        .where((c) => realStatuses[c.id] != CourseStatus.approved)
        .toList();
    if (pending.isEmpty) return null;
    return pending.map((c) => c.level).reduce((a, b) => a < b ? a : b);
  }

  // ── Estados mostrados ───────────────────────────────────────────────────────

  Map<String, CourseStatus> get displayedStatuses =>
      simulationMode.value ? simStatuses : realStatuses;

  CourseStatus statusOf(String courseId) =>
      displayedStatuses[courseId] ?? CourseStatus.locked;

  /// True si el estado mostrado de un curso difiere de su estado real
  /// (para marcarlo como "SIMULADO" en la card).
  bool isSimulatedChange(String courseId) =>
      simulationMode.value && simStatuses[courseId] != realStatuses[courseId];

  // ── Agrupación ──────────────────────────────────────────────────────────────

  List<int> get mandatoryLevels {
    final levels =
        cards.where((c) => !c.isElective).map((c) => c.level).toSet().toList()
          ..sort();
    return levels;
  }

  List<CourseNode> mandatoryForLevel(int level) =>
      cards.where((c) => !c.isElective && c.level == level).toList();

  List<CourseNode> get electives =>
      cards.where((c) => c.isElective).toList();

  /// Electivos agrupados por su primera especialidad (cada curso aparece una
  /// sola vez; sin especialidad → grupo "Otros electivos" al final).
  Map<String, List<CourseNode>> get electiveGroups {
    final groups = <String, List<CourseNode>>{};
    for (final c in electives) {
      final key =
          c.specialties.isEmpty ? otherElectivesGroup : c.specialties.first;
      groups.putIfAbsent(key, () => <CourseNode>[]).add(c);
    }
    final keys = groups.keys.toList()
      ..sort((a, b) {
        if (a == otherElectivesGroup) return 1;
        if (b == otherElectivesGroup) return -1;
        return a.compareTo(b);
      });
    return {for (final k in keys) k: groups[k]!};
  }

  void toggleLevel(int level) {
    if (expandedLevels.contains(level)) {
      expandedLevels.remove(level);
    } else {
      expandedLevels.add(level);
    }
  }

  void toggleElectives() => electivesExpanded.value = !electivesExpanded.value;

  // ── Filtros ─────────────────────────────────────────────────────────────────

  bool matchesFilter(CourseNode course) {
    switch (filter.value) {
      case MallaListFilter.todos:
        return true;
      case MallaListFilter.disponibles:
        return statusOf(course.id) == CourseStatus.unlocked;
      case MallaListFilter.cursando:
        return statusOf(course.id) == CourseStatus.current;
      case MallaListFilter.pendientes:
        return statusOf(course.id) == CourseStatus.locked;
      case MallaListFilter.electivos:
        return course.isElective;
    }
  }

  List<CourseNode> filtered(List<CourseNode> source) =>
      source.where(matchesFilter).toList();

  void setFilter(MallaListFilter value) => filter.value = value;

  int approvedIn(List<CourseNode> group) =>
      group.where((c) => statusOf(c.id) == CourseStatus.approved).length;

  // ── Créditos y progreso ─────────────────────────────────────────────────────

  int get totalCredits => cards.fold(0, (t, c) => t + c.credits);

  int get approvedCredits => _approvedCredits(realStatuses);

  int get simApprovedCredits => _approvedCredits(simStatuses);

  int _approvedCredits(Map<String, CourseStatus> statuses) => cards
      .where((c) => statuses[c.id] == CourseStatus.approved)
      .fold(0, (t, c) => t + c.credits);

  double get approvedRatio =>
      totalCredits == 0 ? 0 : approvedCredits / totalCredits;

  double get simApprovedRatio =>
      totalCredits == 0 ? 0 : simApprovedCredits / totalCredits;

  int get approvedPercent => (approvedRatio * 100).round();

  int get simApprovedPercent => (simApprovedRatio * 100).round();

  /// Créditos aprobados extra respecto al avance real (puede ser negativo si
  /// el alumno revirtió aprobados reales en la simulación).
  int get simExtraCredits => simApprovedCredits - approvedCredits;

  /// Cursos que la simulación deja disponibles y en la realidad están
  /// bloqueados.
  int get simUnlockedCount => cards
      .where(
        (c) =>
            simStatuses[c.id] == CourseStatus.unlocked &&
            realStatuses[c.id] == CourseStatus.locked,
      )
      .length;

  // ── Resaltado de prerrequisitos ─────────────────────────────────────────────

  Map<String, CourseNode> get _byId => {for (final c in cards) c.id: c};

  Set<String> get highlightPrerequisites {
    final id = highlightedCourseId.value;
    final course = id == null ? null : _byId[id];
    if (course == null) return const <String>{};
    return course.coursePrerequisites.toSet();
  }

  Set<String> get highlightUnlocks {
    final id = highlightedCourseId.value;
    if (id == null) return const <String>{};
    return cards
        .where((c) => c.coursePrerequisites.contains(id))
        .map((c) => c.id)
        .toSet();
  }

  CourseHighlightRole highlightRoleOf(String courseId) {
    final selected = highlightedCourseId.value;
    if (selected == null) return CourseHighlightRole.none;
    if (courseId == selected) return CourseHighlightRole.selected;
    if (highlightPrerequisites.contains(courseId)) {
      return CourseHighlightRole.prerequisite;
    }
    if (highlightUnlocks.contains(courseId)) {
      return CourseHighlightRole.unlocks;
    }
    return CourseHighlightRole.dimmed;
  }

  void toggleHighlight(String courseId) {
    highlightedCourseId.value =
        highlightedCourseId.value == courseId ? null : courseId;
  }

  void clearHighlight() => highlightedCourseId.value = null;

  /// Tap en una card: en modo normal resalta; en simulación cicla el estado.
  void onCourseTap(CourseNode course) {
    if (simulationMode.value) {
      cycleSimStatus(course.id);
    } else {
      toggleHighlight(course.id);
    }
  }

  // ── Modo simulación ─────────────────────────────────────────────────────────

  Set<String> get _protectedRealIds => realStatuses.entries
      .where((e) => malla_logic.isPersistentStatus(e.value))
      .map((e) => e.key)
      .toSet();

  void enterSimulation() {
    clearHighlight();
    final base = Map<String, CourseStatus>.from(realStatuses);

    // Baseline: la simulación persistida en backend; si no hay, los estados
    // persistentes guardados localmente (misma precedencia que la vista vieja).
    if (_malla.simulation.isNotEmpty) {
      _malla.simulation.forEach((courseId, simStatus) {
        final status = malla_logic.statusFromSimulation(simStatus);
        if (status != null && base.containsKey(courseId)) {
          base[courseId] = status;
        }
      });
    } else {
      final saved = _savedLocalStatuses(user?.code);
      if (saved != null) {
        for (final entry in saved.entries) {
          if (base.containsKey(entry.key) &&
              malla_logic.isPersistentStatus(entry.value)) {
            base[entry.key] = entry.value;
          }
        }
      }
    }

    final cascaded = _malla.recomputeDerivedAvailabilityCascade(
      visibleCourses: cards,
      currentStatuses: base,
      protectedCourseIds: _protectedRealIds,
    );
    simStatuses.assignAll(cascaded);
    _simEntrySnapshot = Map<String, CourseStatus>.from(cascaded);
    simulationMode.value = true;
  }

  void cycleSimStatus(String courseId) {
    if (!simulationMode.value) return;
    final next = malla_logic.nextCycleStatus(
      simStatuses[courseId] ?? CourseStatus.locked,
    );
    if (next == null) return; // locked no cicla
    simStatuses[courseId] = next;
    _recascadeSim();
  }

  void _recascadeSim() {
    simStatuses.assignAll(
      _malla.recomputeDerivedAvailabilityCascade(
        visibleCourses: cards,
        currentStatuses: simStatuses,
        protectedCourseIds: _protectedRealIds,
      ),
    );
  }

  bool get simHasChanges {
    if (_simEntrySnapshot.length != simStatuses.length) return true;
    for (final entry in simStatuses.entries) {
      if (_simEntrySnapshot[entry.key] != entry.value) return true;
    }
    return false;
  }

  /// Descarta la simulación en curso y vuelve al estado real.
  void discardSimulation() {
    simulationMode.value = false;
    simStatuses.clear();
    _simEntrySnapshot = <String, CourseStatus>{};
  }

  /// Persiste la simulación con el mismo mecanismo/formato que la vista
  /// clásica (MallaController._persistSimulation): un PUT por curso cuyo
  /// estado simulado difiere del real y un DELETE por curso que vuelve a
  /// coincidir con la realidad.
  ///
  /// A diferencia del fire-and-forget clásico, aquí el baseline local
  /// (`replaceSimulation`) solo registra los cursos cuyo request tuvo ÉXITO:
  /// si un PUT/DELETE falla, el curso conserva lo que el backend realmente
  /// tiene, se avisa con un snackbar de error y se permanece en modo
  /// simulación para que el siguiente "Guardar" reintente (el skip por
  /// igualdad ya no lo omite).
  Future<void> saveSimulation() async {
    if (saving.value) return;
    saving.value = true;
    try {
      final api = ApiClient();
      final previouslyPersisted = Map<String, String>.from(_malla.simulation);
      final nextPersisted = <String, String>{};
      final requests = <Future<void>>[];
      var anyFailure = false;

      for (final course in cards) {
        final next = simStatuses[course.id] ?? CourseStatus.locked;
        final simulationStatus = malla_logic.simulationStatusFor(
          next,
          realStatuses[course.id],
        );
        final previous = previouslyPersisted[course.id];
        if (simulationStatus != null) {
          if (previous == simulationStatus) {
            nextPersisted[course.id] = simulationStatus;
            continue; // ya está persistido igual
          }
          final courseIdNum = int.tryParse(course.id);
          if (courseIdNum == null) continue;
          requests.add(
            api
                .putJson(
                  '/curriculum/me/simulation',
                  body: {
                    'curriculumCourseId': courseIdNum,
                    'status': simulationStatus,
                  },
                )
                .then((_) {
                  nextPersisted[course.id] = simulationStatus;
                })
                .catchError((Object e) {
                  debugPrint('Error al guardar la simulación: $e');
                  anyFailure = true;
                  // El backend conserva el valor anterior (si existía).
                  if (previous != null) nextPersisted[course.id] = previous;
                }),
          );
        } else if (previous != null) {
          requests.add(
            api
                .deleteJson('/curriculum/me/simulation/${course.id}')
                .then((_) {})
                .catchError((Object e) {
                  debugPrint('Error al eliminar la simulación: $e');
                  anyFailure = true;
                  // El DELETE falló: el backend todavía tiene esta entrada.
                  nextPersisted[course.id] = previous;
                }),
          );
        }
      }

      await Future.wait(requests);

      // Mismo formato local que la vista clásica (statuses combinados) para
      // que MallaController._bootstrap lo siga entendiendo.
      await StorageService.to.saveStatuses(
        Map<String, CourseStatus>.from(simStatuses),
        code: user?.code,
      );
      _malla.replaceSimulation(nextPersisted);

      if (anyFailure) {
        Get.snackbar(
          'No se pudo guardar',
          'Algunos cambios no llegaron al servidor. Revisa tu conexión y '
              'vuelve a tocar "Guardar" para reintentar.',
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(12),
        );
        return; // seguimos en modo simulación para poder reintentar
      }

      discardSimulation();
      Get.snackbar(
        'Simulación guardada',
        'Tu escenario "¿y si...?" quedó guardado. Tu avance real no cambió.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    } finally {
      saving.value = false;
    }
  }

  // ── Delegaciones para el detail sheet ───────────────────────────────────────

  bool hasCompletedMandatoryCycles(
    int throughLevel,
    Map<String, CourseStatus> sourceStatuses,
  ) {
    return _malla.hasCompletedMandatoryCyclesFromStatuses(
      sourceStatuses,
      throughLevel,
    );
  }

  Map<String, CourseNode> get courseById => _byId;
}
