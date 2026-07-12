import 'package:get/get.dart';

import 'teacher_grade_section_controller.dart';

class TeacherGradeSectionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => TeacherGradeSectionController());
  }
}
