import 'package:get/get.dart';

import 'portal_sync_controller.dart';

/// Binding por ruta, que es la convención dura del repo: `Get.put` dentro de
/// `build()` asociaba el controller al overlay del snackbar y GetX lo destruía,
/// rompiendo los `TextEditingController` (ver el comentario en `main.dart`).
class PortalSyncBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PortalSyncController>(PortalSyncController.new);
  }
}
