// lib/pages/password_reset/forgot_password_page.dart
// Paso 1 de la recuperación de contraseña (HU20): solicitar el código.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'forgot_password_controller.dart';
import 'password_reset_ui.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ForgotPasswordController>();
    final palette = PasswordResetPalette.from(context);

    return PasswordResetScaffold(
      palette: palette,
      conSello: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '¿Olvidaste tu contraseña?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.fieldText,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Ingresa tu código de alumno o correo institucional y te '
            'enviaremos un código de verificación.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.fieldHint,
              fontSize: 12.5,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 26),
          // Grupo: etiqueta a 8px de su campo (proximidad).
          PasswordResetFieldLabel(
            palette: palette,
            text: 'Código de alumno o correo',
          ),
          const SizedBox(height: 8),
          PasswordResetField(
            controller: controller.identifierController,
            palette: palette,
            hint: 'Ej. 20231234 o nombre@aloe.ulima.edu.pe',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => controller.submit(),
          ),
          Obx(
            () => PasswordResetErrorMessage(
              palette: palette,
              message: controller.errorMessage.value,
            ),
          ),
          const SizedBox(height: 28),
          Obx(
            () => PasswordResetPrimaryButton(
              palette: palette,
              label: 'Enviar código',
              loading: controller.submitting.value,
              onPressed: controller.submit,
            ),
          ),
        ],
      ),
    );
  }
}
