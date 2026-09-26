// lib/pages/specialty_test/specialty_test_binding.dart
// El binding por ruta de /test-especialidad (RF-TEST-1).

import 'package:get/get.dart';

import 'specialty_test_controller.dart';
import 'specialty_test_page.dart';

/// `lazyPut` sin `fenix`, para que el controlador muera al cerrar la ruta y
/// su `onClose` deje el avance en pausa. El argumento `origen` dice si se
/// abrió desde el asistente o desde el Perfil.
class SpecialtyTestBinding extends Bindings {
  @override
  void dependencies() {
    final argumentos = Get.arguments;
    final origen = argumentos is Map && argumentos['origen'] == 'perfil'
        ? OrigenDelTest.perfil
        : OrigenDelTest.asistente;
    Get.lazyPut<SpecialtyTestController>(
      () =>
          SpecialtyTestController(origen: origen, ui: const UiDelTestConGet()),
    );
  }
}
