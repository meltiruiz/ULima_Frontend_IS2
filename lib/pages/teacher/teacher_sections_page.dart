import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../components/skeleton.dart';
import '../../configs/course_colors.dart';
import '../../configs/themes.dart';
import '../../models/advising_models.dart';
import '../../services/chat_repository.dart';
import '../chat/chat_linea_tiempo.dart';
import '../chat/chat_page.dart';
import '../chat/chats_inbox_page.dart';
import 'teacher_sections_controller.dart';

class TeacherSectionsPage extends StatelessWidget {
  const TeacherSectionsPage({super.key, this.chatRepository});

  /// Repositorio inyectable para tests, que se le pasa a cada `ChatPage` que
  /// abre una tarjeta. En producción es null y `ChatPage` usa el repositorio
  /// real.
  final ChatRepositoryContract? chatRepository;

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
                      chatRepository: chatRepository,
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

/// Tarjeta de una sección, que abre su chat (RF-CHAT-13). Es la misma
/// [TarjetaDeChat] de la fila de la bandeja del alumno, con la etiqueta
/// `Abrir el chat de <curso>, sección <N>` (o `…, sin sección`), y solo su
/// contenido es propio.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.section,
    required this.brightness,
    this.chatRepository,
  });

  final TeacherSectionOption section;
  final Brightness brightness;
  final ChatRepositoryContract? chatRepository;

  @override
  Widget build(BuildContext context) {
    return TarjetaDeChat(
      brillo: brightness,
      nombreDelCurso: section.courseName,
      codigoDeSeccion: section.sectionCode,
      onTap: () => Get.to<void>(
        () => ChatPage(
          sectionId: section.sectionId.toString(),
          courseName: section.courseName,
          sectionCode: section.sectionCode,
          // El mismo acento que usa Calificar para esta sección.
          courseColor: courseAccentColor(section.sectionId),
          repository: chatRepository,
        ),
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
                // «Sección N» o «Sin sección», como la fila de la bandeja. En
                // textSecondary, que da 10,35:1 y 6,44:1 contra la tarjeta;
                // el naranja de marca daba 2,94:1 en claro.
                Text(
                  etiquetaDeSeccion(section.sectionCode),
                  style: TextStyle(
                    color: MaterialTheme.textSecondary(brightness),
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
              // En textSecondary sobre su tinte llega a 4,5:1 en los dos
              // temas (8,45:1 y 5,26:1); textMuted se quedaba en 4,11:1 y
              // 3,37:1.
              _Badge(
                text: section.rol,
                color: MaterialTheme.textSecondary(brightness),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Un ícono pide 3:1 contra la tarjeta: iconoNaranja da
                  // 4,12:1 en claro y 5,65:1 en oscuro.
                  Icon(
                    LucideIcons.messagesSquare,
                    size: 20,
                    color: MaterialTheme.iconoNaranja(brightness),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Chat',
                    style: TextStyle(
                      color: MaterialTheme.textSecondary(brightness),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
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
