// lib/pages/password_reset/forgot_password_controller.dart
// Paso 1 de la recuperación de contraseña: solicitar el código de verificación.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/api_client.dart';
import '../../services/password_reset_service.dart';

class ForgotPasswordController extends GetxController {
  /// Inyectable solo para las pruebas. En la app se construye el real.
  ForgotPasswordController({PasswordResetService? service})
    : _service = service ?? PasswordResetService();

  final identifierController = TextEditingController();
  final errorMessage = RxnString();
  final submitting = false.obs;

  final PasswordResetService _service;

  Future<void> submit() async {
    // Evita dobles envíos por Enter repetido mientras la petición está en vuelo.
    if (submitting.value) return;

    final identifier = identifierController.text.trim();

    if (identifier.isEmpty) {
      errorMessage.value =
          'Ingresa tu código de alumno o correo institucional.';
      return;
    }

    errorMessage.value = null;
    submitting.value = true;

    try {
      final message = await _service.request(identifier);
      Get.toNamed('/reset-password', arguments: {'identifier': identifier});
      // Abajo, para no tapar el sello de la cabecera (RF-BIEN-20).
      Get.snackbar(
        'Solicitud enviada',
        message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (_) {
      errorMessage.value =
          'No se pudo procesar la solicitud. Intenta de nuevo.';
    } finally {
      submitting.value = false;
    }
  }

  @override
  void onClose() {
    identifierController.dispose();
    super.onClose();
  }
}
