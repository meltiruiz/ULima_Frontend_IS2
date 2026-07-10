// lib/pages/malla/malla_controller.dart
// Orquesta el estado de la malla: catálogo + estados por curso + zoom + dos piscinas.
// TT03: la lógica de dominio (prerrequisitos, derivación de estados, ciclo de
// estados y mapeo de simulación) vive en lib/domain/malla/malla_logic.dart.
//
// TT07 (#103): este controller alimenta EXCLUSIVAMENTE la "Vista mapa
// (clásica)" de solo lectura (/malla-clasica). Solo LEE estado persistido
// (backend + StorageService); no expone ningún camino de escritura — el
// antiguo cycleStatus y la persistencia de simulación (PUT/DELETE
// /curriculum/me/simulation, saveStatuses) se eliminaron: la única fuente de
// escritura es la vista de lista (MallaListController).

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/malla/malla_logic.dart' as malla_logic;
import '../../models/malla_models.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/evaluations_service.dart';
import '../../services/malla_service.dart';
import '../../services/storage_service.dart';

class MallaController extends GetxController {
  // ── Dimensiones del grid ────────────────────────────────────────────────────
  static const double cardWidth = 180;
  static const double cardHeight = 110;
  static const double columnGap = 40;
  static const double rowGap = 24;
  static const double padding = 24;
  static const double levelHeaderHeight = 32;
  static const double sectionLabelHeight = 36;
  // Espacio entre piscina obligatoria y piscina electiva (incluye el label).
  static const double sectionGap = 80;

  // ── Estado reactivo ─────────────────────────────────────────────────────────
  final loading = true.obs;
  final cards = <CourseNode>[].obs;
  final statuses = <String, CourseStatus>{}.obs;
  final zoom = 1.0.obs;
  final focusRequests = 0.obs;

  // ── Caché de layout (se recalcula en _refresh) ──────────────────────────────
  final _electiveNormRows = <String, int>{};
  final _explicitSimulationCourseIds = <String>{};
  int _mandatoryMaxRow = 0;
  int _electiveMaxRow = 0;

  late final MallaService _malla;
  late final AuthService _auth;
  Worker? _userWorker;

  UserModel? get user => _auth.currentUser;

  // ── Piscinas ────────────────────────────────────────────────────────────────
  List<CourseNode> get mandatoryCards =>
      cards.where((c) => !c.isElective).toList();
  List<CourseNode> get electiveCards =>
      cards.where((c) => c.isElective).toList();

  // ── Geometría de secciones ──────────────────────────────────────────────────

  /// Y donde termina la piscina de obligatorios.
  double get _mandatorySectionBottom =>
      padding +
      sectionLabelHeight +
      levelHeaderHeight +
      (_mandatoryMaxRow + 1) * (cardHeight + rowGap);

  /// Y donde empiezan las cards de la piscina electiva.
  double get electiveSectionY => _mandatorySectionBottom + sectionGap;

  @override
  void onInit() {
    super.onInit();
    _malla = MallaService.to;
    _auth = AuthService.to;
    _userWorker = ever<UserModel?>(_auth.currentUserRx, (_) {
      if (!loading.value) _refresh(preserveCurrentStatuses: true);
    });
    _bootstrap();
  }

  @override
  void onClose() {
    _userWorker?.dispose();
    super.onClose();
  }

  Future<void> _preloadSyllabus() async {
    try {
      await EvaluationSyllabusService().loadEvaluationData();
    } catch (_) {
      // Silencioso: la precarga de sílabos es opcional para el sheet de curso.
    }
  }

  Future<void> _bootstrap() async {
    loading.value = true;
    try {
      await _malla.load();
      // HU21: precargar sílabos en segundo plano (best-effort). NO debe
      // bloquear ni tumbar el render de la malla si el endpoint tarda o falla.
      _preloadSyllabus();
      final code = user?.code;

      final backendStatuses = <String, CourseStatus>{};
      _explicitSimulationCourseIds.clear();
      _malla.simulation.forEach((courseId, simStatus) {
        final status = _statusFromSimulation(simStatus);
        if (status != null) {
          backendStatuses[courseId] = status;
          _explicitSimulationCourseIds.add(courseId);
        }
      });

      final userSaved = code == null
          ? null
          : StorageService.to.savedStatusesFor(code);
      final sessionSaved = StorageService.to.savedStatuses;
      final saved = userSaved ?? sessionSaved;

      if (backendStatuses.isNotEmpty) {
        statuses.assignAll(backendStatuses);
      } else if (saved != null) {
        final knownSaved = _knownCourseStatuses(saved);
        statuses.assignAll(knownSaved);
        _explicitSimulationCourseIds.addAll(
          knownSaved.entries
              .where((entry) => _isPersistentStatus(entry.value))
              .map((entry) => entry.key),
        );
      }

      // TT07: sin escritura de migración a StorageService aquí — la vista
      // mapa es solo lectura; la vista de lista ya guarda con code al
      // persistir una simulación.
      _refresh(preserveCurrentStatuses: true);
    } finally {
      loading.value = false;
    }
  }

  void _refresh({bool preserveCurrentStatuses = false}) {
    final previousStatuses = preserveCurrentStatuses
        ? Map<String, CourseStatus>.from(statuses)
        : const <String, CourseStatus>{};
    final u = user;
    if (u == null) {
      cards.clear();
      statuses.clear();
      _electiveNormRows.clear();
      return;
    }
    final visible = _malla.visibleCoursesFor(
      u,
      includeCourseIds: _persistentStatusCourseIds(previousStatuses),
    );
    cards.assignAll(visible);
    final visibleIds = visible.map((c) => c.id).toSet();
    final computed = _malla.computeStatuses(u);

    final nextStatuses = <String, CourseStatus>{
      for (final id in visibleIds) id: computed[id] ?? CourseStatus.locked,
    };
    for (final entry in previousStatuses.entries) {
      if (_explicitSimulationCourseIds.contains(entry.key) ||
          _isPersistentStatus(entry.value)) {
        nextStatuses[entry.key] = entry.value;
      }
    }

    statuses.assignAll(_knownCourseStatuses(nextStatuses));
    _computePoolLayout();
    _recomputeDerivedAvailability();
  }

  void _recomputeDerivedAvailability() {
    statuses.addAll(
      _knownCourseStatuses(
        _malla.recomputeDerivedAvailability(
          visibleCourses: cards,
          currentStatuses: statuses,
          fixedStatusCourseIds: _explicitSimulationCourseIds,
        ),
      ),
    );
    statuses.refresh();
  }

  Map<String, CourseStatus> _knownCourseStatuses(
    Map<String, CourseStatus> source,
  ) {
    return malla_logic.filterKnownCourseStatuses(
      malla_logic.MallaGraph(_malla.courses),
      source,
    );
  }

  Set<String> _persistentStatusCourseIds(Map<String, CourseStatus> source) {
    return {
      ..._explicitSimulationCourseIds,
      ...source.entries
          .where((entry) => _isPersistentStatus(entry.value))
          .map((entry) => entry.key),
    };
  }

  bool _isPersistentStatus(CourseStatus status) =>
      malla_logic.isPersistentStatus(status);

  /// Calcula las filas normalizadas (0-indexed) de los electivos dentro de su
  /// piscina y el max row de cada sección.
  void _computePoolLayout() {
    final mandatory = mandatoryCards;
    _mandatoryMaxRow = mandatory.isEmpty
        ? 0
        : mandatory.map((c) => c.row).reduce(max);

    _electiveNormRows.clear();
    final byLevel = <int, List<CourseNode>>{};
    for (final c in electiveCards) {
      byLevel.putIfAbsent(c.level, () => []).add(c);
    }
    _electiveMaxRow = 0;
    for (final lvlCourses in byLevel.values) {
      lvlCourses.sort((a, b) => a.row.compareTo(b.row));
      for (int i = 0; i < lvlCourses.length; i++) {
        _electiveNormRows[lvlCourses[i].id] = i;
        if (i > _electiveMaxRow) _electiveMaxRow = i;
      }
    }
  }

  // ── Posicionamiento ─────────────────────────────────────────────────────────

  Offset positionFor(CourseNode c) {
    final x = padding + (c.level - 1) * (cardWidth + columnGap);
    if (!c.isElective) {
      return Offset(
        x,
        padding +
            sectionLabelHeight +
            levelHeaderHeight +
            c.row * (cardHeight + rowGap),
      );
    }
    final normRow = _electiveNormRows[c.id] ?? 0;
    return Offset(
      x,
      electiveSectionY + levelHeaderHeight + normRow * (cardHeight + rowGap),
    );
  }

  int? get currentStudentLevel {
    final pendingMandatory = mandatoryCards
        .where((c) => statuses[c.id] != CourseStatus.approved)
        .toList();
    if (pendingMandatory.isNotEmpty) {
      return pendingMandatory
          .map((c) => c.level)
          .reduce((a, b) => a < b ? a : b);
    }

    final pending = cards
        .where((c) => statuses[c.id] != CourseStatus.approved)
        .toList();
    if (pending.isEmpty) return null;
    return pending.map((c) => c.level).reduce((a, b) => a < b ? a : b);
  }

  Offset? focusOffsetForCurrentLevel() {
    final level = currentStudentLevel;
    if (level == null) return null;

    final target =
        mandatoryCards
            .where(
              (c) =>
                  c.level == level && statuses[c.id] != CourseStatus.approved,
            )
            .toList()
          ..sort((a, b) => a.row.compareTo(b.row));

    if (target.isNotEmpty) return positionFor(target.first);

    return Offset(
      padding + (level - 1) * (cardWidth + columnGap),
      padding + sectionLabelHeight + levelHeaderHeight,
    );
  }

  /// Y del separador entre piscinas (centro del sectionGap).
  double get separatorY => _mandatorySectionBottom + sectionGap / 2;

  Size canvasSize() {
    if (cards.isEmpty) return const Size(1200, 800);
    final maxLevel = cards.map((c) => c.level).reduce((a, b) => a > b ? a : b);
    final w = padding * 2 + maxLevel * (cardWidth + columnGap);
    final h = electiveCards.isEmpty
        ? _mandatorySectionBottom + padding
        : electiveSectionY +
              levelHeaderHeight +
              (_electiveMaxRow + 1) * (cardHeight + rowGap) +
              padding;
    return Size(w, h);
  }

  CourseStatus? _statusFromSimulation(String status) =>
      malla_logic.statusFromSimulation(status);

  // ── Métricas de progreso ────────────────────────────────────────────────────
  int get approvedCount => _visibleStatusCount(CourseStatus.approved);
  int get currentCount => _visibleStatusCount(CourseStatus.current);
  int get unlockedCount => _visibleStatusCount(CourseStatus.unlocked);
  int get totalVisible => cards.length;

  double get approvedRatio =>
      totalVisible == 0 ? 0 : approvedCount / totalVisible;

  int _visibleStatusCount(CourseStatus status) {
    return cards.where((c) => statuses[c.id] == status).length;
  }

  bool hasCompletedMandatoryCycles(
    int throughLevel,
    Map<String, CourseStatus> sourceStatuses,
  ) {
    return _malla.hasCompletedMandatoryCyclesFromStatuses(
      sourceStatuses,
      throughLevel,
    );
  }

  // ── Zoom ────────────────────────────────────────────────────────────────────
  void zoomIn() => zoom.value = (zoom.value + 0.1).clamp(0.5, 1.6);
  void zoomOut() => zoom.value = (zoom.value - 0.1).clamp(0.5, 1.6);
  void resetZoom() {
    zoom.value = 1.0;
    focusRequests.value++;
  }
}
