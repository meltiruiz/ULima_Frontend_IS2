import 'package:get/get.dart';

import 'registro_controller.dart';

/// Binding por ruta, que es la convención dura del repo: `Get.put` dentro de
/// `build()` asociaba el controller al overlay del snackbar y GetX lo destruía,
/// rompiendo los `TextEditingController`.
///
/// `lazyPut` sin `fenix` ni `permanent` a propósito: GetX elimina el controller
/// al salir de la ruta, y eso es lo que dispara `onClose()` y por tanto el
/// borrado de las credenciales de miUlima (RS-FE-6).
class RegistroBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RegistroController>(RegistroController.new);
  }
}
