// lib/pages/malla/malla_page.dart
// Malla curricular con dos piscinas: obligatorios (arriba) y electivos (abajo).
//
// TT07 (#103): esta vista vuelve como "Vista mapa (clásica)" de SOLO LECTURA,
// accesible desde la vista de lista vía la ruta /malla-clasica. Muestra
// únicamente el estado persistido; toda escritura (simulación incluida)
// ocurre exclusivamente en la vista de lista. El controller se obtiene con
// Get.find (lo registra el binding de la ruta en main.dart), de modo que cada
// entrada a la ruta crea una instancia fresca y GetX la elimina al salir.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../configs/themes.dart';
import '../../models/malla_models.dart';
import 'malla_controller.dart';
import 'widgets/course_card.dart';
import 'widgets/course_detail_sheet.dart';
import 'widgets/prerequisite_painter.dart';

class MallaPage extends StatefulWidget {
  const MallaPage({super.key});

  @override
  State<MallaPage> createState() => _MallaPageState();
}

class _MallaPageState extends State<MallaPage> {
  static const List<DeviceOrientation> _mallaMapOrientations = [
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];
  static const List<DeviceOrientation> _portraitOnly = [
    DeviceOrientation.portraitUp,
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(_mallaMapOrientations);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(_portraitOnly);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<MallaController>(); // registrado por /malla-clasica
    final colors = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: MaterialTheme.pageBg(brightness),
      appBar: AppBar(
        backgroundColor: MaterialTheme.headerColor(brightness),
        foregroundColor: Colors.white,
        toolbarHeight: isLandscape ? 44 : null,
        title: const Text(
          'Vista mapa (clásica)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          if (!isLandscape) _ProgressBar(controller: c, colors: colors),
          if (!isLandscape) _ZoomToolbar(controller: c),
          Expanded(
            child: Obx(
              () => c.loading.value
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: MaterialTheme.primaryColor,
                      ),
                    )
                  : _MallaCanvas(controller: c),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Barra de progreso ──────────────────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.controller, required this.colors});
  final MallaController controller;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Obx(() {
      return Container(
        // Compacto para dar más alto al árbol/canvas (Parte 5).
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        decoration: BoxDecoration(
          color: MaterialTheme.cardBg(brightness),
          border: Border(
            bottom: BorderSide(color: colors.outline.withValues(alpha: 0.5)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Chip(
                  color: CourseStatus.approved.color,
                  label: 'Finalizados',
                  count: controller.approvedCount,
                ),
                const SizedBox(width: 10),
                _Chip(
                  color: CourseStatus.current.color,
                  label: 'En proceso',
                  count: controller.currentCount,
                ),
                const SizedBox(width: 10),
                _Chip(
                  color: CourseStatus.unlocked.color,
                  label: 'Disponibles',
                  count: controller.unlockedCount,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: controller.approvedRatio,
                minHeight: 6,
                backgroundColor: MaterialTheme.progressBg(brightness),
                color: MaterialTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Avance: ${controller.approvedCount} / ${controller.totalVisible} cursos',
              style: TextStyle(
                color: MaterialTheme.textMuted(brightness),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.color, required this.label, required this.count});
  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count',
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: MaterialTheme.textSecondary(brightness),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Toolbar de zoom ────────────────────────────────────────────────────────────
class _ZoomToolbar extends StatelessWidget {
  const _ZoomToolbar({required this.controller});
  final MallaController controller;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      color: MaterialTheme.cardBg(brightness),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          _IconBtn(icon: Icons.zoom_out, onTap: controller.zoomOut),
          const SizedBox(width: 4),
          Obx(
            () => SizedBox(
              width: 56,
              child: Text(
                '${(controller.zoom.value * 100).round()}%',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: MaterialTheme.textSecondary(brightness),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          _IconBtn(icon: Icons.zoom_in, onTap: controller.zoomIn),
          const SizedBox(width: 4),
          _IconBtn(
            icon: Icons.center_focus_strong,
            onTap: controller.resetZoom,
          ),
          const Spacer(),
          // Leyenda: línea sólida = obligatorio, línea discontinua = electivo
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 2.5,
                decoration: BoxDecoration(
                  color: MaterialTheme.textMuted(brightness),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'Obligatorio',
                style: TextStyle(
                  color: MaterialTheme.textDimmed(brightness),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: MaterialTheme.textMuted(brightness),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Container(
                    width: 5,
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: MaterialTheme.textMuted(brightness),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Container(
                    width: 5,
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: MaterialTheme.textMuted(brightness),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 5),
              Text(
                'Electivo',
                style: TextStyle(
                  color: MaterialTheme.textDimmed(brightness),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Material(
      color: MaterialTheme.iconBtnBg(brightness),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Center(
            child: Icon(
              icon,
              size: 18,
              color: MaterialTheme.textSecondary(brightness),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Canvas principal ───────────────────────────────────────────────────────────
class _MallaCanvas extends StatefulWidget {
  const _MallaCanvas({required this.controller});
  final MallaController controller;

  @override
  State<_MallaCanvas> createState() => _MallaCanvasState();
}

class _MallaCanvasState extends State<_MallaCanvas> {
  final _transformationController = TransformationController();
  bool _didInitialFocus = false;
  int _lastFocusRequest = 0;
  Size? _lastViewportSize;
  Offset? _zoomCenter;
  Offset? _zoomFocalPoint;
  bool _applyingTransform = false;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_handleTransformationChanged);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_handleTransformationChanged);
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Obx(() {
          final controller = widget.controller;
          _lastViewportSize = constraints.biggest;
          final mandatory = controller.mandatoryCards;
          final electives = controller.electiveCards;
          final allCards = controller.cards;
          final statuses = controller.statuses;
          final size = controller.canvasSize();
          final zoom = controller.zoom.value;
          final focusRequest = controller.focusRequests.value;

          final focusScheduled = _scheduleFocusIfNeeded(
            viewportSize: constraints.biggest,
            canvasSize: size,
            zoom: zoom,
            focusRequest: focusRequest,
          );
          if (!focusScheduled) {
            _scheduleZoomIfNeeded(
              viewportSize: constraints.biggest,
              canvasSize: size,
              zoom: zoom,
            );
          }

          // Posiciones absolutas de todas las cards (obligatorios + electivos).
          final positions = <String, Offset>{
            for (final c in allCards) c.id: controller.positionFor(c),
          };

          return InteractiveViewer(
            transformationController: _transformationController,
            constrained: false,
            minScale: 0.5,
            maxScale: 1.6,
            scaleEnabled: true,
            panEnabled: true,
            boundaryMargin: _viewerBoundaryMargin(constraints.biggest),
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: Stack(
                children: [
                  // ── Etiqueta sección obligatorios ─────────────────────────
                  Positioned(
                    left: MallaController.padding,
                    top: MallaController.padding,
                    child: const _SectionLabel(
                      icon: Icons.menu_book_outlined,
                      text: 'OBLIGATORIOS',
                    ),
                  ),

                  // ── Cabeceras de nivel — piscina obligatoria ──────────────
                  ..._levelHeaders(
                    mandatory,
                    yOffset:
                        MallaController.padding +
                        MallaController.sectionLabelHeight,
                  ),

                  // ── Separador entre piscinas ──────────────────────────────
                  if (electives.isNotEmpty)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: controller.separatorY - 18,
                      child: _PoolDivider(
                        width: size.width,
                        separatorY: controller.separatorY,
                      ),
                    ),

                  // ── Etiqueta sección electivos ────────────────────────────
                  if (electives.isNotEmpty)
                    Positioned(
                      left: MallaController.padding,
                      top:
                          controller.electiveSectionY -
                          MallaController.sectionLabelHeight,
                      child: const _SectionLabel(
                        icon: Icons.bookmark_border,
                        text: 'ELECTIVOS',
                      ),
                    ),

                  // ── Cabeceras de nivel — piscina electiva ─────────────────
                  if (electives.isNotEmpty)
                    ..._levelHeaders(
                      electives,
                      yOffset: controller.electiveSectionY,
                    ),

                  // ── Conectores de prerrequisitos ──────────────────────────
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: PrerequisitePainter(
                          courses: allCards,
                          statuses: statuses,
                          positions: positions,
                        ),
                      ),
                    ),
                  ),

                  // ── Cards obligatorias ────────────────────────────────────
                  // TT07: sin onLongPress — la vista mapa es solo lectura y
                  // no cicla estados.
                  for (final c in mandatory)
                    Positioned(
                      left: positions[c.id]!.dx,
                      top: positions[c.id]!.dy,
                      child: CourseCard(
                        course: c,
                        status: statuses[c.id] ?? CourseStatus.locked,
                        onTap: () => _openDetails(context, c, statuses),
                        onLongPress: null,
                      ),
                    ),

                  // ── Cards electivas ───────────────────────────────────────
                  for (final c in electives)
                    Positioned(
                      left: positions[c.id]!.dx,
                      top: positions[c.id]!.dy,
                      child: CourseCard(
                        course: c,
                        status: statuses[c.id] ?? CourseStatus.locked,
                        onTap: () => _openDetails(context, c, statuses),
                        onLongPress: null,
                      ),
                    ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  bool _scheduleFocusIfNeeded({
    required Size viewportSize,
    required Size canvasSize,
    required double zoom,
    required int focusRequest,
  }) {
    final manualRequest = focusRequest != _lastFocusRequest;
    if (_didInitialFocus && !manualRequest) return false;
    if (!viewportSize.width.isFinite || !viewportSize.height.isFinite) {
      return false;
    }
    if (viewportSize.isEmpty || canvasSize.isEmpty) return false;

    final target = widget.controller.focusOffsetForCurrentLevel();
    if (target == null) return false;
    final targetCenter = Offset(
      target.dx + MallaController.cardWidth / 2,
      _mandatoryPoolTopY,
    );
    final focalPoint = _initialFocusFocalPoint(viewportSize);

    _didInitialFocus = true;
    _lastFocusRequest = focusRequest;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _setTransformation(
        _matrixForFocus(
          target: targetCenter,
          focalPoint: focalPoint,
          viewportSize: viewportSize,
          canvasSize: canvasSize,
          zoom: zoom,
        ),
      );
      _zoomCenter = targetCenter;
      _zoomFocalPoint = focalPoint;
    });
    return true;
  }

  void _scheduleZoomIfNeeded({
    required Size viewportSize,
    required Size canvasSize,
    required double zoom,
  }) {
    if (!viewportSize.width.isFinite || !viewportSize.height.isFinite) return;
    if (viewportSize.isEmpty || canvasSize.isEmpty) return;
    if ((_matrixScale() - zoom).abs() < 0.001) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final focalPoint = _zoomFocalPoint ?? viewportSize.center(Offset.zero);
      final center = _zoomCenter ?? _contentPointForScreen(focalPoint);
      _setTransformation(
        _matrixForFocus(
          target: center,
          focalPoint: focalPoint,
          viewportSize: viewportSize,
          canvasSize: canvasSize,
          zoom: zoom,
        ),
      );
      _zoomCenter = center;
    });
  }

  void _handleTransformationChanged() {
    if (_applyingTransform) return;
    final scale = _matrixScale().clamp(0.5, 1.6).toDouble();
    if ((widget.controller.zoom.value - scale).abs() > 0.001) {
      widget.controller.zoom.value = scale;
    }
    final viewportSize = _lastViewportSize;
    if (viewportSize == null || viewportSize.isEmpty) return;
    _zoomFocalPoint = viewportSize.center(Offset.zero);
    _zoomCenter = _contentPointForScreen(_zoomFocalPoint!);
  }

  void _setTransformation(Matrix4 matrix) {
    _applyingTransform = true;
    _transformationController.value = matrix;
    _applyingTransform = false;
  }

  double _matrixScale() {
    return _transformationController.value.entry(0, 0).abs();
  }

  Offset _contentPointForScreen(Offset screenPoint) {
    final matrix = _transformationController.value;
    final scale = _matrixScale();
    if (scale == 0) return Offset.zero;
    return Offset(
      (screenPoint.dx - matrix.entry(0, 3)) / scale,
      (screenPoint.dy - matrix.entry(1, 3)) / scale,
    );
  }

  Offset _initialFocusFocalPoint(Size viewportSize) {
    final verticalFocusAnchor = viewportSize.width > viewportSize.height
        ? 0.16
        : 0.06;
    return Offset(
      viewportSize.width / 2,
      viewportSize.height * verticalFocusAnchor,
    );
  }

  Matrix4 _matrixForFocus({
    required Offset target,
    required Offset focalPoint,
    required Size viewportSize,
    required Size canvasSize,
    required double zoom,
  }) {
    final contentWidth = canvasSize.width * zoom;
    final contentHeight = canvasSize.height * zoom;

    var dx = focalPoint.dx - target.dx * zoom;
    var dy = focalPoint.dy - target.dy * zoom;

    final boundaryMargin = _viewerBoundaryMargin(viewportSize);
    final horizontalMargin = boundaryMargin.horizontal / 2;
    final verticalMargin = boundaryMargin.vertical / 2;
    final minDx = math.min(
      horizontalMargin,
      viewportSize.width - contentWidth - horizontalMargin,
    );
    final minDy = math.min(
      verticalMargin,
      viewportSize.height - contentHeight - verticalMargin,
    );
    dx = dx.clamp(minDx, horizontalMargin).toDouble();
    dy = dy.clamp(minDy, verticalMargin).toDouble();

    final matrix = Matrix4.identity();
    matrix.setEntry(0, 0, zoom);
    matrix.setEntry(1, 1, zoom);
    matrix.setEntry(0, 3, dx);
    matrix.setEntry(1, 3, dy);
    return matrix;
  }

  EdgeInsets _viewerBoundaryMargin(Size viewportSize) {
    return const EdgeInsets.symmetric(horizontal: 96, vertical: 72);
  }

  static const double _mandatoryPoolTopY =
      MallaController.padding +
      MallaController.sectionLabelHeight +
      MallaController.levelHeaderHeight;

  List<Widget> _levelHeaders(
    List<CourseNode> cards, {
    required double yOffset,
  }) {
    if (cards.isEmpty) return const [];
    final brightness = Theme.of(context).brightness;
    final levels = cards.map((c) => c.level).toSet().toList()..sort();
    return [
      for (final lvl in levels)
        Positioned(
          left:
              MallaController.padding +
              (lvl - 1) *
                  (MallaController.cardWidth + MallaController.columnGap),
          top: yOffset,
          child: SizedBox(
            width: MallaController.cardWidth,
            height: MallaController.levelHeaderHeight,
            child: Center(
              child: Text(
                'NIVEL $lvl',
                style: TextStyle(
                  color: MaterialTheme.textSecondary(brightness),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
    ];
  }

  void _openDetails(
    BuildContext context,
    CourseNode course,
    Map<String, CourseStatus> statuses,
  ) {
    // HU19: el sheet vive en widgets/course_detail_sheet.dart (compartido con
    // la vista lista); aquí se inyectan las dependencias del controller.
    // TT07: readOnly=true y sin onCycleStatus — desde la vista mapa el sheet
    // jamás muestra el botón de cambiar estado.
    final controller = widget.controller;
    showCourseDetailSheet(
      context,
      course: course,
      statuses: statuses,
      courseById: {for (final c in controller.cards) c.id: c},
      hasCompletedMandatoryCycles: controller.hasCompletedMandatoryCycles,
      onCycleStatus: null,
      readOnly: true,
    );
  }
}

// ── Separador visual entre piscinas ───────────────────────────────────────────
class _PoolDivider extends StatelessWidget {
  const _PoolDivider({required this.width, required this.separatorY});
  final double width;
  final double separatorY;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final divColor = MaterialTheme.dividerMalla(brightness);
    return SizedBox(
      width: width,
      height: 36,
      child: Row(
        children: [
          const SizedBox(width: MallaController.padding),
          Expanded(
            child: Container(
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    divColor.withValues(alpha: 0),
                    divColor,
                    divColor.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: MallaController.padding),
        ],
      ),
    );
  }
}

// ── Label de sección ───────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: MaterialTheme.textMuted(brightness)),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            color: MaterialTheme.textMuted(brightness),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}
