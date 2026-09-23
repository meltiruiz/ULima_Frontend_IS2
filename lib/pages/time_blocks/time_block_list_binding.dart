// lib/pages/time_blocks/time_block_list_binding.dart
// Binding por ruta de /mis-bloques (RF-BLQ-8; regla del repo: nada de Get.put
// en builds). `lazyPut` sin `fenix`, como el del formulario: GetX elimina el
// controller al terminar la animación de salida, y el botón del horario no
// reabre la lista mientras siga registrado.

import 'package:get/get.dart';

import 'time_block_list_controller.dart';

class TimeBlockListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => TimeBlockListController());
  }
}
