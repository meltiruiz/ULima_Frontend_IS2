import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/skeleton.dart';
import '../../configs/themes.dart';
import '../../models/official_grades_models.dart';
import 'teacher_grades_controller.dart';

/// Pestaña "Calificar": secciones que el docente dicta, para poner notas.
class TeacherGradesPage extends StatelessWidget {
  const TeacherGradesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TeacherGradesController>();
    final brightness = Theme.brightnessOf(context);

    return Container(
      color: MaterialTheme.pageBg(brightness),
      child: RefreshIndicator(
        onRefresh: controller.loadSections,
        color: MaterialTheme.primaryColor,
        child: Obx(() {
          final loading = controller.isLoading.value;
          final sections = controller.sections;

          if (loading && sections.isEmpty) {
            return _scroll(const Padding(
              padding: EdgeInsets.all(16),
              child: SkeletonCardList(count: 3, showAvatar: false),
            ));
          }
          if (controller.loadError.value != null && sections.isEmpty) {
            return _scroll(_Empty(
              icon: Icons.wifi_off,
              message: controller.loadError.value!,
              brightness: brightness,
            ));
          }
          if (sections.isEmpty) {
            return _scroll(_Empty(
              icon: Icons.layers_outlined,
              message: 'Aún no tienes secciones asignadas.',
              brightness: brightness,
            ));
          }
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: sections.length + 1,
            itemBuilder: (_, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Calificar',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: MaterialTheme.textPrimary(brightness),
                    ),
                  ),
                );
              }
              final section = sections[i - 1];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SectionCard(
                  section: section,
                  brightness: brightness,
                  onTap: () => controller.openSection(section),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _scroll(Widget child) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [SizedBox(height: 420, child: Center(child: child))],
      );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section, required this.brightness, required this.onTap});

  final GradingSection section;
  final Brightness brightness;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textPrimary = MaterialTheme.textPrimary(brightness);
    final textSecondary = MaterialTheme.textSecondary(brightness);

    return Material(
      color: MaterialTheme.cardBg(brightness),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: MaterialTheme.borderColor(brightness)),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(section.courseName,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textPrimary)),
                    const SizedBox(height: 3),
                    Text('Sección ${section.sectionCode} · ${section.rol}',
                        style: TextStyle(fontSize: 13, color: textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: textSecondary),
            ],
          ),
        ),
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
