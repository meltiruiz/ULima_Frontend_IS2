import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/skeleton.dart';
import '../../configs/themes.dart';
import '../../models/advising_models.dart';
import '../chat/chat_page.dart';
import 'teacher_sections_controller.dart';

class TeacherSectionsPage extends StatelessWidget {
  const TeacherSectionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TeacherSectionsController>();
    final brightness = Theme.brightnessOf(context);

    return Container(
      color: MaterialTheme.pageBg(brightness),
      child: RefreshIndicator(
        onRefresh: controller.loadSections,
        color: MaterialTheme.primaryColor,
        child: Obx(() {
          final loading = controller.isLoading.value;
          final sections = controller.sections;

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _Header(count: sections.length, brightness: brightness),
              ),
              if (loading && sections.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SkeletonCardList(count: 3, showAvatar: false),
                  ),
                )
              else if (controller.loadError.value != null && sections.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    icon: Icons.wifi_off,
                    message: controller.loadError.value!,
                    brightness: brightness,
                  ),
                )
              else if (sections.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    icon: Icons.layers_outlined,
                    message: 'Aun no tienes secciones asignadas.',
                    brightness: brightness,
                  ),
                )
              else
                SliverList.builder(
                  itemCount: sections.length,
                  itemBuilder: (_, index) => Padding(
                    padding: EdgeInsets.fromLTRB(16, index == 0 ? 4 : 6, 16, 6),
                    child: _SectionCard(
                      section: sections[index],
                      brightness: brightness,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 88)),
            ],
          );
        }),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.count, required this.brightness});

  final int count;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: MaterialTheme.primaryColor.withValues(alpha: 0.15),
            child: const Icon(Icons.layers, color: MaterialTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mis secciones',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: MaterialTheme.textPrimary(brightness),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count asignadas',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: MaterialTheme.textSecondary(brightness),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section, required this.brightness});

  final TeacherSectionOption section;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Get.to(
        () => ChatPage(
          sectionId: section.sectionId.toString(),
          courseName: section.courseName,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MaterialTheme.cardBg(brightness),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MaterialTheme.borderColor(brightness)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: MaterialTheme.espPrincipalBg(brightness),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.school_outlined,
                color: MaterialTheme.primaryDark,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.courseName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: MaterialTheme.textPrimary(brightness),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    section.sectionCode,
                    style: const TextStyle(
                      color: MaterialTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _Badge(
                  text: section.rol,
                  color: MaterialTheme.textMuted(brightness),
                ),
                const SizedBox(height: 10),
                Icon(
                  Icons.forum_outlined,
                  size: 20,
                  color: MaterialTheme.primaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.message,
    required this.brightness,
  });

  final IconData icon;
  final String message;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: MaterialTheme.textMuted(brightness)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: MaterialTheme.textSecondary(brightness),
            ),
          ),
        ],
      ),
    );
  }
}
