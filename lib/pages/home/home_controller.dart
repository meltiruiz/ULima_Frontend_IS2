import 'package:get/get.dart';

import '../../models/portal_sync_models.dart';
import '../../services/alert_service.dart';
import '../../services/auth_service.dart';
import '../../services/portal_sync_service.dart';

class HomeController extends GetxController {
  HomeController({PortalSyncService? portalSync})
      : _portalSync = portalSync ?? PortalSyncService();

  final PortalSyncService _portalSync;

  final portalStatus = PortalSyncStatus.desconocido.obs;

  /// "Después" oculta el aviso solo hasta el próximo arranque de la app, así que
  /// vive en memoria y no en `shared_preferences`: el alumno que aún no cargó
  /// sus datos debe volver a verlo, no perderlo para siempre por un toque.
  final pospuesto = false.obs;

  /// El aviso es solo para alumnos: portal-sync exige rol de alumno en el
  /// backend, y un docente recibiría 403.
  bool get _esAlumno => !(AuthService.to.currentUser?.isTeacher ?? false);

  bool get mostrarBannerCarga =>
      _esAlumno && !pospuesto.value && portalStatus.value.needsImport;

  /// Texto del aviso. `activePeriod` puede venir null (el contrato lo permite
  /// cuando todavía no hay ningún período activo), así que hay dos redacciones.
  String get textoBanner {
    final p = portalStatus.value.activePeriod;
    return p == null
        ? 'Aún no tienes tus cursos cargados. Tráelos desde miUlima.'
        : 'Aún no tienes los cursos del ciclo ${p.code}. Tráelos desde miUlima.';
  }

  @override
  void onInit() {
    super.onInit();
    try {
      AlertService.to.fetchAlerts();
    } catch (_) {}
    refrescarEstadoPortal();
  }

  /// `status()` nunca lanza: ante cualquier fallo devuelve el estado neutro, que
  /// deja el aviso oculto. Proponerle cargar a quien ya tiene sus datos es peor
  /// que no proponérselo a quien los necesita, que igual puede entrar por Perfil.
  Future<void> refrescarEstadoPortal() async {
    if (!_esAlumno) return;
    portalStatus.value = await _portalSync.status();
  }

  void posponerCarga() => pospuesto.value = true;
}
