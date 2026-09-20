// lib/pages/academic_record/academic_record_binding.dart

import 'package:get/get.dart';

import 'academic_record_controller.dart';

/// Binding por ruta, como el resto de la app: nada de Get.put dentro de build.
class AcademicRecordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AcademicRecordController>(() => AcademicRecordController());
  }
}
