import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/skeleton.dart';
import '../../configs/themes.dart';
import '../../models/official_grades_models.dart';
import 'mis_notas_controller.dart';

/// Notas oficiales del alumno (las que pone el profesor). Solo lectura.
class MisNotasPage extends StatelessWidget {
  const MisNotasPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MisNotasController>();
    final brightness = Theme.brightnessOf(context);

    return Scaffold(
      backgroundColor: MaterialTheme.pageBg(brightness),
      appBar: AppBar(title: const Text('Notas oficiales')),
      body: RefreshIndicator(
        onRefresh: controller.load,
        color: MaterialTheme.primaryColor,
        child: Obx(() {
          final loading = controller.isLoading.value;
          final courses = controller.courses;

          if (loading && courses.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: SkeletonCardList(count: 4, showAvatar: false),
            );
          }
          if (controller.loadError.value != null && courses.isEmpty) {
            return _fill(_Empty(
              icon: Icons.wifi_off,
              message: controller.loadError.value!,
              brightness: brightness,
            ));
          }
          if (courses.isEmpty) {
            return _fill(_Empty(
              icon: Icons.school_outlined,
              message: 'Aún no tienes cursos con notas oficiales.',
              brightness: brightness,
            ));
          }
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            itemCount: courses.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CourseCard(
                course: courses[i],
                notaFinal: controller.notaFinal(courses[i]),
                calificado: controller.tieneNotas(courses[i]),
                brightness: brightness,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _fill(Widget child) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [SizedBox(height: 400, child: Center(child: child))],
      );
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.course,
    required this.notaFinal,
    required this.calificado,
    required this.brightness,
  });

  final OfficialCourse course;
  final double notaFinal;
  final bool calificado;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final textPrimary = MaterialTheme.textPrimary(brightness);
    final textSecondary = MaterialTheme.textSecondary(brightness);

    return Container(
      decoration: BoxDecoration(
        color: MaterialTheme.cardBg(brightness),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MaterialTheme.borderColor(brightness)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.courseName,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text('Sección ${course.sectionCode}',
                        style: TextStyle(fontSize: 13, color: textSecondary)),
                  ],
                ),
              ),
              _FinalBadge(nota: notaFinal, calificado: calificado),
            ],
          ),
          const SizedBox(height: 12),
          ...course.assessments.map((a) => _AssessmentRow(
                assessment: a,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              )),
        ],
      ),
    );
  }
}

class _AssessmentRow extends StatelessWidget {
  const _AssessmentRow({
    required this.assessment,
    required this.textPrimary,
    required this.textSecondary,
  });

  final OfficialAssessment assessment;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final hasValue = assessment.value != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${assessment.code} · ${assessment.name}',
              style: TextStyle(fontSize: 13, color: textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text('${assessment.weight.toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 12, color: textSecondary)),
          const SizedBox(width: 14),
          SizedBox(
            width: 44,
            child: Text(
              hasValue ? assessment.value!.toStringAsFixed(1) : '—',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: hasValue ? textPrimary : textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinalBadge extends StatelessWidget {
  const _FinalBadge({required this.nota, required this.calificado});

  final double nota;
  final bool calificado;

  @override
  Widget build(BuildContext context) {
    if (!calificado) {
      return const SizedBox.shrink();
    }
    final aprobado = nota >= 10.5;
    final color = aprobado ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text('Final', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
          Text(nota.toStringAsFixed(2),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.message, required this.brightness});

  final IconData icon;
  final String message;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final textSecondary = MaterialTheme.textSecondary(brightness);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 48, color: textSecondary),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(message, textAlign: TextAlign.center, style: TextStyle(color: textSecondary)),
        ),
      ],
    );
  }
}
