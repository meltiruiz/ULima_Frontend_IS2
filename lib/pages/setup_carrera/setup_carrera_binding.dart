// lib/pages/setup_carrera/setup_carrera_binding.dart
// El binding por ruta de /setup-carrera (RF-TEST-1).

import 'package:get/get.dart';

import 'setup_carrera_controller.dart';

/// Reemplaza el `Get.put` dentro de `build`, como pide la regla del repo que
/// recuerda `main.dart`.
class SetupCarreraBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SetupCarreraController>(() => SetupCarreraController());
  }
}
