// lib/pages/home/home_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/footer/app_footer.dart';
import 'package:ulima_plus/components/header/app_header.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/components/chatbot_bubble.dart';
import 'package:ulima_plus/configs/themes.dart';

import '../horario/horario_controller.dart';
import 'home_controller.dart';
import 'home_shell_config.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeController control = Get.put(HomeController());
  final user = AuthService.to.currentUser;

  int _currentIndex = 0;

  late final HomeShellConfig _config = HomeShellConfig.forUser(user);

  /// Índice del tab de Horario, derivado de las pestañas reales (para un JP la
  /// pestaña "Calificar" no existe, así que Horario/Asesorías se corren).
  int get _horarioTabIndex =>
      _config.footerItems.indexWhere((i) => i.label == 'Horario');

  Widget _buildBody() {
    return _config.pages[_currentIndex];
  }

  void _onTabTap(int index) {
    final previous = _currentIndex;
    setState(() {
      _currentIndex = index;
    });
    // Si el usuario cambia al tab de Horario, recargamos los datos
    // para reflejar asesorías creadas o modificadas recientemente.
    // Para docentes: también recargamos si venían del tab de Asesorías (su
    // índice se deriva de las pestañas reales, que varían para un JP).
    final isTeacher = user?.isTeacher ?? false;
    final asesoriasIndex =
        _config.footerItems.indexWhere((i) => i.label == 'Asesorias');
    final comingFromAsesorias =
        isTeacher && asesoriasIndex != -1 && previous == asesoriasIndex;
    if (index == _horarioTabIndex || comingFromAsesorias) {
      try {
        Get.find<HorarioController>().reload();
      } catch (_) {
        // El controller aún no existe (primera visita): onInit lo cargará.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final u = user;
    final showBubble = u != null && !u.isTeacher;
    return Scaffold(
      backgroundColor: colors.surface,
      body: Column(
        children: [
          AppHeader(showScheduleToggle: _currentIndex == _horarioTabIndex),
          // Aviso de carga de ciclo. Sin esto, un alumno sin matrícula ve un
          // esqueleto permanente en Horario y una calculadora vacía, sin nada
          // que le diga qué hacer.
          Obx(() => control.mostrarBannerCarga
              ? _PortalSyncBanner(controller: control)
              : const SizedBox.shrink()),
          Expanded(
            // La burbuja del chatbot va en un Stack sobre el body (no en el slot
            // fijo del FAB) para poder arrastrarla; las zonas vacías del Stack
            // dejan pasar los toques al contenido de abajo.
            child: Stack(
              children: [
                _buildBody(),
                if (showBubble) const ChatbotBubble(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppFooter(
        currentIndex: _currentIndex,
        items: _config.footerItems,
        onTap: _onTabTap,
      ),
    );
  }
}



/// Aviso de "te faltan tus cursos", con la acción para traerlos.
///
/// Franja de ancho completo sobre el contenido, siguiendo el mismo patrón que
/// el banner de simulación de la malla.
class _PortalSyncBanner extends StatelessWidget {
  const _PortalSyncBanner({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final primary = MaterialTheme.primaryColor;
    return Container(
      width: double.infinity,
      color: primary.withValues(alpha: 0.14),
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          Icon(Icons.cloud_download_outlined, size: 18, color: primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              controller.textoBanner,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: MaterialTheme.textPrimary(Theme.brightnessOf(context)),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final cargado = await Get.toNamed<dynamic>('/portal-sync');
              // Al volver de una carga exitosa el aviso ya no aplica.
              if (cargado == true) await controller.refrescarEstadoPortal();
            },
            style: TextButton.styleFrom(
              foregroundColor: primary,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 32),
            ),
            child: const Text(
              'Cargar',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            onPressed: controller.posponerCarga,
            icon: const Icon(Icons.close, size: 16),
            color: MaterialTheme.textMuted(Theme.brightnessOf(context)),
            tooltip: 'Después',
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
