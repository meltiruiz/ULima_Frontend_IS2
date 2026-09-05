import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/pages/alertas/alertas_page.dart';
import 'package:ulima_plus/pages/horario/horario_controller.dart';
import 'package:ulima_plus/services/alert_service.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

typedef AppHeaderLinkLauncher = Future<bool> Function(Uri uri);

class AppHeader extends StatelessWidget {
  final bool showScheduleToggle;
  final AppHeaderLinkLauncher? linkLauncher;

  const AppHeader({
    super.key,
    this.showScheduleToggle = false,
    this.linkLauncher,
  });

  static const List<DeviceOrientation> _scheduleOrientations = [
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];
  static const List<DeviceOrientation> _portraitOnly = [
    DeviceOrientation.portraitUp,
  ];

  // La URI se conserva completa y en un único lugar para evitar que al editar
  // el header se pierdan parámetros de seguimiento solicitados por el usuario.
  static final Uri _donBelisarioPromotionUri = Uri.parse(
    'https://www.donbelisario.com.pe/clasico-combo-contundente?'
    'gsImpressionId=01KXPTTES6C5C0S9FKJG902C2G&'
    'gsListName=Recomendaciones%20-%20Promociones&gsIndex=3',
  );

  Future<void> _openDonBelisarioPromotion() async {
    // La dependencia opcional hace verificable la URI sin abrir una aplicación
    // externa durante los widget tests. En producción siempre usa url_launcher.
    final launcher = linkLauncher ?? _launchExternally;
    await launcher(_donBelisarioPromotionUri);
  }

  static Future<bool> _launchExternally(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // El header ULIMA++ (campana de alertas y toggle de horario lista/calendario)
    // es propio del ALUMNO. El docente reusa este shell, así que ambos controles
    // se ocultan para él (el docente recibe 403 en /alerts/me y su horario es otra
    // vista): así no le aparecen íconos de alumno arriba a la derecha.
    final isTeacher = AuthService.to.currentUser?.isTeacher ?? false;
    final showAlerts = !isTeacher;

    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
      decoration: BoxDecoration(
        color: MaterialTheme.headerColor(Theme.brightnessOf(context)),
        border: Border(
          bottom: BorderSide(color: colors.primaryContainer, width: 2.0),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Semantics(
                button: true,
                excludeSemantics: true,
                label: 'Abrir promoción de Don Belisario',
                child: InkWell(
                  key: const Key('app-header-brand-link'),
                  borderRadius: BorderRadius.circular(4),
                  onTap: _openDonBelisarioPromotion,
                  child: Text(
                    'ULIMA++',
                    style: TextStyle(
                      color: colors.onPrimary,
                      fontSize: 20,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              Row(
                children: [
                  if (showScheduleToggle && !isTeacher)
                    Obx(() {
                      final hControl = Get.put(HorarioController());

                      // Mismo formato que la campana (InkWell + icono 28) para
                      // que el header NO cambie de alto en Horario. Un IconButton
                      // mide 48 y hacía este header ~18px más alto que los demás.
                      return Padding(
                        padding: const EdgeInsets.only(right: 18),
                        child: InkWell(
                          onTap: hControl.toggleListView,
                          child: Icon(
                            hControl.isListView.value
                                ? Icons.calendar_today
                                : Icons.format_list_bulleted,
                            color: colors.onPrimary,
                            size: 28,
                          ),
                        ),
                      );
                    }),
                  if (showAlerts)
                    Obx(() {
                      final count = Get.isRegistered<AlertService>()
                          ? AlertService.to.unreadCount
                          : 0;

                      return InkWell(
                        onTap: () async {
                          await SystemChrome.setPreferredOrientations(
                            _portraitOnly,
                          );
                          await Get.to(() => const AlertasPage());
                          if (showScheduleToggle) {
                            await SystemChrome.setPreferredOrientations(
                              _scheduleOrientations,
                            );
                          }
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              color: colors.onPrimary,
                              size: 30,
                            ),
                            if (count > 0)
                              Positioned(
                                right: -4,
                                top: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color.fromARGB(255, 29, 111, 219),
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$count',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    })
                  else
                    const SizedBox(width: 30, height: 30),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/* LOGO SVG
SvgPicture.asset(
                  'assets/images/logo.svg',
                  width: 30,
                  semanticsLabel: 'Logo',
                  
                ),
*/
