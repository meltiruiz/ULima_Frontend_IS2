import 'package:get/get.dart';

import 'mis_notas_controller.dart';

class MisNotasBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MisNotasController());
  }
}
