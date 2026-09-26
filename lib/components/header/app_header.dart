import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/logo/estrella_del_logo.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/pages/alertas/alertas_page.dart';
import 'package:ulima_plus/pages/splash/puntos_de_aterrizaje.dart';
import 'package:ulima_plus/services/alert_service.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

typedef AppHeaderLinkLauncher = Future<bool> Function(Uri uri);

class AppHeader extends StatefulWidget {
  /// Si la pestaña activa es Horario. Solo sirve para devolverle la rotación
  /// al volver de las alertas (BR-SHELL-F-03).
  final bool isScheduleTab;
  final AppHeaderLinkLauncher? linkLauncher;

  const AppHeader({super.key, this.isScheduleTab = false, this.linkLauncher});

  /// La estrella mide 26 dp de punta a punta y va a 10 dp del texto
  /// (BR-SHELL-F-04).
  static const double tamanoDeEstrella = 26;
  static const double separacion = 10;

  /// El único estilo de «ULIMA++». La capa del arranque y el sello de la
  /// bienvenida dibujan réplicas suyas (RF-SPL-11 y RF-BIEN-4).
  static TextStyle estiloDeMarca(ColorScheme colores) => TextStyle(
    color: colores.onPrimary,
    fontSize: 20,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.bold,
  );

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

  static Future<bool> _launchExternally(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  // Claves propias de esta cabecera. No se comparten, así que dos cabeceras
  // que conviven un instante no chocan.
  final GlobalKey _claveCabecera = GlobalKey();
  final GlobalKey _claveEstrella = GlobalKey();
  final GlobalKey _claveTexto = GlobalKey();

  Future<void> _openDonBelisarioPromotion() async {
    // La dependencia opcional hace verificable la URI sin abrir una aplicación
    // externa durante los widget tests. En producción siempre usa url_launcher.
    final launcher = widget.linkLauncher ?? AppHeader._launchExternally;
    await launcher(AppHeader._donBelisarioPromotionUri);
  }

  Rect? _rectDe(GlobalKey clave) {
    final caja = clave.currentContext?.findRenderObject() as RenderBox?;
    if (caja == null || !caja.hasSize || !caja.attached) return null;
    return caja.localToGlobal(Offset.zero) & caja.size;
  }

  /// Informa la medida después del cuadro, cuando ya hay layout.
  void _informar(Duration _) {
    if (!mounted) return;
    final cabecera = _rectDe(_claveCabecera);
    final estrella = _rectDe(_claveEstrella);
    final texto = _rectDe(_claveTexto);
    if (cabecera == null || estrella == null || texto == null) return;
    final colores = Theme.of(context).colorScheme;
    PuntosDeAterrizaje.cabecera.value = MedidaDeCabecera(
      cabecera: cabecera,
      estrella: estrella,
      texto: texto,
      // El estilo con el que se dibuja, con lo que hereda del tema, para que
      // la réplica de la intro caiga sobre el texto real.
      estilo: DefaultTextStyle.of(
        context,
      ).style.merge(AppHeader.estiloDeMarca(colores)),
      escalaDeTexto: MediaQuery.textScalerOf(context),
      color: MaterialTheme.headerColor(Theme.brightnessOf(context)),
      colorDelBorde: colores.primaryContainer,
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(_informar);
    final colors = Theme.of(context).colorScheme;
    // La campana de alertas es propia del ALUMNO y es el único control a la
    // derecha (BR-SHELL-F-03). El docente reusa este shell y no la ve, porque
    // recibe 403 en /alerts/me, así que no le aparecen íconos de alumno arriba
    // a la derecha.
    final isTeacher = AuthService.to.currentUser?.isTeacher ?? false;
    final showAlerts = !isTeacher;

    // Íconos claros sobre la cabecera naranja u oscura, en los dos temas. La
    // intro del splash deja aplicado el último estilo de la barra, así que la
    // cabecera declara el suyo (RF-SPL-4 y BR-SHELL-F-04).
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        key: _claveCabecera,
        padding: const EdgeInsets.only(
          top: 50,
          left: 20,
          right: 20,
          bottom: 20,
        ),
        decoration: BoxDecoration(
          color: MaterialTheme.headerColor(Theme.brightnessOf(context)),
          border: Border(
            bottom: BorderSide(color: colors.primaryContainer, width: 2.0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // La estrella va fuera del enlace, que sigue siendo solo el
                // texto (BR-SHELL-F-01 y BR-SHELL-F-04).
                EstrellaDelLogo(
                  key: _claveEstrella,
                  tamano: AppHeader.tamanoDeEstrella,
                  color: colors.onPrimary,
                ),
                const SizedBox(width: AppHeader.separacion),
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
                      key: _claveTexto,
                      style: AppHeader.estiloDeMarca(colors),
                    ),
                  ),
                ),
              ],
            ),
            if (showAlerts)
              Obx(() {
                final count = Get.isRegistered<AlertService>()
                    ? AlertService.to.unreadCount
                    : 0;
                return InkWell(
                  onTap: () async {
                    await SystemChrome.setPreferredOrientations(
                      AppHeader._portraitOnly,
                    );
                    await Get.to(() => const AlertasPage());
                    if (widget.isScheduleTab) {
                      await SystemChrome.setPreferredOrientations(
                        AppHeader._scheduleOrientations,
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
      ),
    );
  }
}
