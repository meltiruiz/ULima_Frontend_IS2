// lib/pages/login/login_binding.dart
// Binding de la ruta /login, que muestra la bienvenida con Ulises.
//
// Registra el LoginController y el BienvenidaController como PERMANENTES
// (decisión B-19 de specs/features/bienvenida). Motivo del LoginController, el
// bug del "tipeo fantasma": con un binding normal (`lazyPut`), cuando se
// navega a /login con offAllToLogin() y ya había otra ruta /login enterrada en
// el stack, al eliminarse esa ruta vieja GetX dispone el LoginController y sus
// TextEditingController, incluso si la pantalla visible los está usando. Al
// ser permanente, GetX no lo dispone por cambios de ruta. Al reingresar se
// limpian los campos (resetFields) para no arrastrar lo tecleado por una
// sesión o un usuario anterior.
//
// El BienvenidaController es permanente por lo mismo. Cada montaje de su
// página es una visita nueva, que la página empieza después de su primer
// cuadro, así que aquí no se reinicia nada. Va después del LoginController,
// que escucha desde su onInit.

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../bienvenida/bienvenida_controller.dart';
import 'login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<LoginController>()) {
      // Reusar la instancia permanente. Se limpian los campos DESPUÉS del
      // frame actual, porque hacerlo durante el binding, que corre en pleno
      // build de la ruta, dispararía "setState() called during build" al
      // notificar al TextField todavía montado de la /login anterior.
      final controller = Get.find<LoginController>();
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => controller.resetFields(),
      );
    } else {
      Get.put(LoginController(), permanent: true);
    }
    if (!Get.isRegistered<BienvenidaController>()) {
      Get.put(BienvenidaController(), permanent: true);
    }
  }
}
