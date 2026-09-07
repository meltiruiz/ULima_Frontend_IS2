import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/error_retry.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/at_risk_student_model.dart';
import 'package:ulima_plus/pages/teacher/at_risk_students_controller.dart';

class AtRiskStudentsPage extends StatefulWidget {
  final String sectionId;
  final String courseName;
  final String sectionCode;

  /// Solo el Profesor titular puede "alertar" (notificar a los alumnos en
  /// riesgo). El JP puede VER la lista pero no notifica → se le oculta el botón.
  final bool isProfesor;

  const AtRiskStudentsPage({
    super.key,
    required this.sectionId,
    required this.courseName,
    required this.sectionCode,
    this.isProfesor = true,
  });

  @override
  State<AtRiskStudentsPage> createState() => _AtRiskStudentsPageState();
}

class _AtRiskStudentsPageState extends State<AtRiskStudentsPage> {
  static const Color impedidoRed = Color(0xFFD32F2F);
  static const Color riesgoOrange = Color(0xFFF57C00);

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<AtRiskStudentsController>()) {
      Get.put(AtRiskStudentsController());
    }
    final ctrl = Get.find<AtRiskStudentsController>();
    ctrl.setCourseInfo(widget.courseName, widget.sectionCode);
    ctrl.loadData(widget.sectionId);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final controller = Get.find<AtRiskStudentsController>();

    return Scaffold(
      backgroundColor: MaterialTheme.pageBg(brightness),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.courseName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            Text(
              'Seccion ${widget.sectionCode}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.8)),
            ),
          ],
        ),
        actions: [
          Obx(() {
            if (controller.isLoading.value) return const SizedBox.shrink();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.file_download_outlined, color: Colors.white),
                  tooltip: 'Exportar CSV',
                  onPressed: controller.exportCsv,
                ),
                if (widget.isProfesor)
                IconButton(
                  icon: const Icon(Icons.notifications_active_outlined, color: Colors.white),
                  tooltip: 'Notificar alumnos en riesgo',
                  onPressed: () async {
                    final ctrl = controller;
                    final impedidos = ctrl.impedidoCount;
                    final enRiesgo = ctrl.enRiesgoCount;
                    final total = impedidos + enRiesgo;
                    if (total == 0) {
                      Get.snackbar(
                        'Sin alumnos en riesgo',
                        'No hay alumnos impedidos o en riesgo para notificar',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                      return;
                    }
                    final confirm = await Get.dialog<bool>(
                      AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text('Notificar alumnos', style: TextStyle(fontWeight: FontWeight.w800)),
                        content: Text(
                          'Se enviara una notificacion a $total alumno${total == 1 ? '' : 's'} '
                          '($impedidos impedido${impedidos == 1 ? '' : 's'}, '
                          '$enRiesgo en riesgo) de la seccion ${ctrl.sectionCode.value}.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(result: false),
                            child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          FilledButton(
                            onPressed: () => Get.back(result: true),
                            child: const Text('Enviar', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ctrl.notifyStudents();
                    }
                  },
                ),
                PopupMenuButton<SortMode>(
              icon: Icon(
                controller.sortMode.value == SortMode.absenceDesc
                    ? Icons.arrow_downward
                    : controller.sortMode.value == SortMode.absenceAsc
                        ? Icons.arrow_upward
                        : Icons.sort_by_alpha,
                color: Colors.white,
              ),
              tooltip: 'Ordenar por...',
              onSelected: controller.setSortMode,
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: SortMode.absenceDesc,
                  child: Row(
                    children: [
                      if (controller.sortMode.value == SortMode.absenceDesc)
                        const Icon(Icons.check, size: 18, color: MaterialTheme.primaryColor),
                      const SizedBox(width: 8),
                      const Text('Mayor % ausencia'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: SortMode.absenceAsc,
                  child: Row(
                    children: [
                      if (controller.sortMode.value == SortMode.absenceAsc)
                        const Icon(Icons.check, size: 18, color: MaterialTheme.primaryColor),
                      const SizedBox(width: 8),
                      const Text('Menor % ausencia'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: SortMode.lastNameAsc,
                  child: Row(
                    children: [
                      if (controller.sortMode.value == SortMode.lastNameAsc)
                        const Icon(Icons.check, size: 18, color: MaterialTheme.primaryColor),
                      const SizedBox(width: 8),
                      const Text('Apellido A-Z'),
                    ],
                  ),
                ),
              ],
                ),
              ],
            );
          }),
        ],
      ),
      body: Column(
        children: [
          _SearchBar(controller: controller, isDark: isDark),
          Obx(() {
            if (controller.isLoading.value && controller.allStudents.isEmpty) {
              return const SizedBox.shrink();
            }
            return _SummaryBar(controller: controller, isDark: isDark);
          }),
          Obx(() {
            final students = controller.allStudents;
            if (students.isNotEmpty) {
              return _FilterChips(controller: controller, isDark: isDark);
            }
            return const SizedBox.shrink();
          }),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.allStudents.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              // Un fallo del endpoint se muestra como error con reintentar, no
              // como "No se encontraron alumnos" (falso negativo: parecía una
              // sección sin alumnos cuando en realidad la carga HU22 falló).
              if (controller.loadError.value && controller.allStudents.isEmpty) {
                return ErrorRetry(
                  title: 'No se pudo cargar la lista de alumnos',
                  onRetry: controller.retry,
                );
              }

              final displayStudents = controller.filteredStudents;

              if (displayStudents.isEmpty) {
                return _EmptyState(
                  message: controller.searchQuery.value.isNotEmpty
                      ? 'No se encontraron alumnos con ese codigo o apellido'
                      : 'No se encontraron alumnos en esta seccion',
                  isDark: isDark,
                );
              }

              return RefreshIndicator(
                onRefresh: controller.refresh,
                color: MaterialTheme.primaryColor,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: displayStudents.length,
                  itemBuilder: (context, index) {
                    return _StudentCard(
                      student: displayStudents[index],
                      isDark: isDark,
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final AtRiskStudentsController controller;
  final bool isDark;

  const _SearchBar({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MaterialTheme.cardBg(isDark ? Brightness.dark : Brightness.light),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        onChanged: controller.onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Buscar por codigo o apellido...',
          hintStyle: TextStyle(
            color: MaterialTheme.textMuted(isDark ? Brightness.dark : Brightness.light),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: MaterialTheme.textMuted(isDark ? Brightness.dark : Brightness.light),
            size: 20,
          ),
          suffixIcon: Obx(() {
            if (controller.searchQuery.value.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.clear, size: 18),
              onPressed: () => controller.onSearchChanged(''),
            );
          }),
          filled: true,
          fillColor: isDark ? const Color(0xFF2A2A36) : const Color(0xFFF1F5F9),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        style: TextStyle(
          fontSize: 14,
          color: MaterialTheme.textPrimary(isDark ? Brightness.dark : Brightness.light),
        ),
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final AtRiskStudentsController controller;
  final bool isDark;

  const _SummaryBar({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final total = controller.allStudents.length;
    if (total == 0) return const SizedBox.shrink();

    final impedido = controller.impedidoCount;
    final enRiesgo = controller.enRiesgoCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _SummaryChip(
            label: '$impedido Impedidos',
            color: _AtRiskStudentsPageState.impedidoRed,
            fraction: total > 0 ? impedido / total : 0.0,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          _SummaryChip(
            label: '$enRiesgo En riesgo',
            color: _AtRiskStudentsPageState.riesgoOrange,
            fraction: total > 0 ? enRiesgo / total : 0.0,
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          // El conteo sale del estado real, no de `total - impedido - enRiesgo`:
          // esa resta absorbía cualquier categoría nueva dentro de "Normal", y
          // así las matrículas sin medir se contaban como alumnos sanos.
          _SummaryChip(
            label: '${controller.normalCount} Normal',
            color: Colors.green,
            fraction: total > 0 ? controller.normalCount / total : 0.0,
            isDark: isDark,
          ),
          if (controller.sinDatosCount > 0) ...[
            const SizedBox(width: 8),
            _SummaryChip(
              label: '${controller.sinDatosCount} Sin datos',
              color: Colors.blueGrey,
              fraction: total > 0 ? controller.sinDatosCount / total : 0.0,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final Color color;
  final double fraction;
  final bool isDark;

  const _SummaryChip({
    required this.label,
    required this.color,
    required this.fraction,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                backgroundColor: isDark ? const Color(0xFF2A2A36) : const Color(0xFFE0E0E0),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final AtRiskStudentsController controller;
  final bool isDark;

  const _FilterChips({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'Todos',
                count: controller.allStudents.length,
                isSelected: controller.filterMode.value == FilterMode.all,
                onTap: () => controller.setFilterMode(FilterMode.all),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Impedidos',
                count: controller.impedidoCount,
                color: _AtRiskStudentsPageState.impedidoRed,
                isSelected: controller.filterMode.value == FilterMode.impedido,
                onTap: () => controller.setFilterMode(FilterMode.impedido),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'En riesgo',
                count: controller.enRiesgoCount,
                color: _AtRiskStudentsPageState.riesgoOrange,
                isSelected: controller.filterMode.value == FilterMode.enRiesgo,
                onTap: () => controller.setFilterMode(FilterMode.enRiesgo),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Normal',
                count: controller.normalCount,
                color: Colors.green,
                isSelected: controller.filterMode.value == FilterMode.normal,
                onTap: () => controller.setFilterMode(FilterMode.normal),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? MaterialTheme.primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : chipColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? chipColor : chipColor.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final AtRiskStudent student;
  final bool isDark;

  const _StudentCard({required this.student, required this.isDark});

  void _showDetail(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final cycle = student.cycle;
    final limitLabel = cycle != null && cycle >= 6
        ? '35% (6° ciclo+)'
        : '25% (1°-5° ciclo)';
    final limiteHoras = cycle != null && cycle >= 6
        ? (student.totalHours * 0.35).toStringAsFixed(1)
        : (student.totalHours * 0.25).toStringAsFixed(1);

    final Color statusColor;
    if (student.isImpedido) {
      statusColor = _AtRiskStudentsPageState.impedidoRed;
    } else if (student.isEnRiesgo) {
      statusColor = _AtRiskStudentsPageState.riesgoOrange;
    } else if (student.isSinDatos) {
      // Neutro a propósito: el verde es "todo bien" en esta pantalla, y
      // "no sabemos" no es "todo bien".
      statusColor = Colors.blueGrey;
    } else {
      statusColor = Colors.green;
    }
    final IconData statusIcon = student.isImpedido
        ? Icons.cancel
        : student.isEnRiesgo
            ? Icons.warning_amber_rounded
            : Icons.check_circle;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              statusIcon,
              color: statusColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                student.fullName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Codigo', student.code, brightness),
            const SizedBox(height: 6),
            _detailRow('Ciclo del alumno', '${student.currentLevel ?? "-"}°', brightness),
            const SizedBox(height: 6),
            _detailRow('Ciclo del curso', '${student.cycle ?? "-"}°', brightness),
            const SizedBox(height: 6),
            _detailRow('Horas ausentes', '${student.absentHours}h', brightness),
            const SizedBox(height: 6),
            _detailRow('Total horas seccion', '${student.totalHours}h', brightness),
            const SizedBox(height: 6),
            _detailRow('% ausencia', student.absencePercentage == null ? 'Sin datos' : '${student.absencePercentage!.toStringAsFixed(1)}%', brightness),
            const SizedBox(height: 6),
            _detailRow('Limite aplicado', limitLabel, brightness),
            const SizedBox(height: 6),
            _detailRow('Max. horas permitidas', '$limiteHoras h', brightness),
            if (student.isEnRiesgo && student.missingFaltas != null) ...[
              const SizedBox(height: 6),
              _detailRow('Faltas restantes', '${student.missingFaltas}', brightness),
            ],
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                student.statusLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cerrar', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, Brightness brightness) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: MaterialTheme.textMuted(brightness),
        )),
        Text(value, style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: MaterialTheme.textPrimary(brightness),
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final Color statusColor;
    if (student.isImpedido) {
      statusColor = _AtRiskStudentsPageState.impedidoRed;
    } else if (student.isEnRiesgo) {
      statusColor = _AtRiskStudentsPageState.riesgoOrange;
    } else {
      statusColor = Colors.green;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _showDetail(context),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: MaterialTheme.cardBg(brightness),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: MaterialTheme.borderColor(brightness)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.fullName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: MaterialTheme.textPrimary(brightness),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Codigo: ${student.code}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: MaterialTheme.textMuted(brightness),
                              ),
                            ),
                            if (student.currentLevel != null) ...[
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: MaterialTheme.tagBg(brightness),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${student.currentLevel}° ciclo',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: MaterialTheme.textSecondary(brightness),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        student.absencePercentage == null
                            ? '—'
                            : '${student.absencePercentage!.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          student.statusLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _ProgressBar(student: student, isDark: isDark),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final AtRiskStudent student;
  final bool isDark;

  const _ProgressBar({required this.student, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final limitPct = (student.cycle != null && student.cycle! >= 6) ? 35.0 : 25.0;
    // Sin dato no se dibuja avance: una barra en 0 se lee como 0% de faltas.
    final fraction = student.absencePercentage == null
        ? 0.0
        : (student.absencePercentage! / limitPct).clamp(0.0, 1.0);
    final barColor = student.isImpedido
        ? _AtRiskStudentsPageState.impedidoRed
        : student.isEnRiesgo
            ? _AtRiskStudentsPageState.riesgoOrange
            : student.isSinDatos
                ? Colors.blueGrey
                : Colors.green;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            backgroundColor: isDark ? const Color(0xFF2A2A36) : const Color(0xFFE0E0E0),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          student.absencePercentage == null
              ? 'Sin datos de asistencia'
              : '${student.absencePercentage!.toStringAsFixed(1)}% de ${limitPct.toStringAsFixed(0)}% limite',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: MaterialTheme.textMuted(isDark ? Brightness.dark : Brightness.light),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final bool isDark;

  const _EmptyState({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 56,
              color: Colors.green.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: MaterialTheme.textMuted(brightness),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
