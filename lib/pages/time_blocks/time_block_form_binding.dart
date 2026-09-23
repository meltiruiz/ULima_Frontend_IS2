// lib/pages/time_blocks/time_block_form_binding.dart
// Binding por ruta de /bloque (regla del repo: nada de Get.put en builds).
// `lazyPut` sin `fenix`: GetX elimina el controller al terminar la animación
// de salida, y quien abre /bloque no lo reabre mientras siga registrado. Su
// `onClose` libera el TextEditingController del nombre.

import 'package:get/get.dart';

import 'time_block_form_controller.dart';

class TimeBlockFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => TimeBlockFormController());
  }
}
