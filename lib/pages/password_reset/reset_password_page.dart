// lib/pages/password_reset/reset_password_page.dart
// Paso 2 de la recuperación de contraseña (HU20), en dos sub-pasos para
// enfocar una tarea por pantalla: (1) código de verificación, (2) nueva
// contraseña. Si el backend rechaza el código, se regresa al sub-paso 1
// con el error visible ahí.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'password_reset_ui.dart';
import 'password_reset_validators.dart';
import 'reset_password_controller.dart';

class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ResetPasswordController>();
    final palette = PasswordResetPalette.from(context);

    return PasswordResetScaffold(
      palette: palette,
      child: Obx(
        () => AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.08, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: controller.step.value == 0
              ? _CodeStep(
                  key: const ValueKey('code-step'),
                  controller: controller,
                  palette: palette,
                )
              : _PasswordStep(
                  key: const ValueKey('password-step'),
                  controller: controller,
                  palette: palette,
                ),
        ),
      ),
    );
  }
}

/// Sub-paso 1: solo el código de verificación (+ reenviar).
class _CodeStep extends StatelessWidget {
  const _CodeStep({super.key, required this.controller, required this.palette});

  final ResetPasswordController controller;
  final PasswordResetPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Verifica tu correo',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.fieldText,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          controller.maskedEmail != null
              ? 'Enviamos un código de verificación a '
                    '${controller.maskedEmail}.'
              : 'Ingresa el código de $passwordResetCodeLength dígitos '
                    'que enviamos a tu correo institucional.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.fieldHint,
            fontSize: 12.5,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 26),
        PasswordResetFieldLabel(
          palette: palette,
          text: 'Código de verificación',
        ),
        const SizedBox(height: 8),
        PasswordResetOtpField(
          controller: controller.codeController,
          palette: palette,
        ),
        Obx(
          () => PasswordResetErrorMessage(
            palette: palette,
            message: controller.errorMessage.value,
          ),
        ),
        const SizedBox(height: 28),
        // Obx: `submitting` cambia mientras se verifica el código contra el
        // backend, y sin envolverlo el spinner no se repintaría nunca.
        Obx(
          () => PasswordResetPrimaryButton(
            palette: palette,
            label: 'Continuar',
            loading: controller.submitting.value,
            onPressed: controller.continueToPassword,
          ),
        ),
        const SizedBox(height: 10),
        _ResendLink(controller: controller, palette: palette),
      ],
    );
  }
}

/// Sub-paso 2: nueva contraseña y confirmación.
class _PasswordStep extends StatelessWidget {
  const _PasswordStep({
    super.key,
    required this.controller,
    required this.palette,
  });

  final ResetPasswordController controller;
  final PasswordResetPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: controller.backToCode,
              icon: Icon(
                Icons.arrow_back,
                size: 20,
                color: palette.fieldHint,
              ),
              splashRadius: 18,
              tooltip: 'Cambiar código',
            ),
            Expanded(
              child: Text(
                'Crea tu nueva contraseña',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: palette.fieldText,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            // Equilibra el ancho del IconButton para centrar el título.
            const SizedBox(width: 48),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Usa al menos $passwordResetMinPasswordLength caracteres. '
          'Al confirmar, se cerrarán tus sesiones activas.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.fieldHint,
            fontSize: 12.5,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 26),
        PasswordResetFieldLabel(palette: palette, text: 'Nueva contraseña'),
        const SizedBox(height: 8),
        Obx(
          () => PasswordResetField(
            controller: controller.passwordController,
            palette: palette,
            hint: 'Mínimo $passwordResetMinPasswordLength caracteres',
            obscureText: !controller.passwordVisible.value,
            textInputAction: TextInputAction.next,
            suffixIcon: _VisibilityToggle(
              palette: palette,
              visible: controller.passwordVisible.value,
              onPressed: () => controller.passwordVisible.toggle(),
            ),
          ),
        ),
        const SizedBox(height: 22),
        PasswordResetFieldLabel(
          palette: palette,
          text: 'Confirmar contraseña',
        ),
        const SizedBox(height: 8),
        Obx(
          () => PasswordResetField(
            controller: controller.confirmController,
            palette: palette,
            hint: 'Repite la nueva contraseña',
            obscureText: !controller.confirmVisible.value,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => controller.submit(),
            suffixIcon: _VisibilityToggle(
              palette: palette,
              visible: controller.confirmVisible.value,
              onPressed: () => controller.confirmVisible.toggle(),
            ),
          ),
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
            label: 'Confirmar',
            loading: controller.submitting.value,
            onPressed: controller.submit,
          ),
        ),
      ],
    );
  }
}

class _VisibilityToggle extends StatelessWidget {
  const _VisibilityToggle({
    required this.palette,
    required this.visible,
    required this.onPressed,
  });

  final PasswordResetPalette palette;
  final bool visible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 20,
        color: palette.fieldHint,
      ),
      onPressed: onPressed,
      splashRadius: 18,
    );
  }
}

class _ResendLink extends StatelessWidget {
  const _ResendLink({required this.controller, required this.palette});

  final ResetPasswordController controller;
  final PasswordResetPalette palette;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cooldown = controller.resendCooldown.value;
      final resending = controller.resending.value;
      final enabled = cooldown == 0 && !resending;
      final label = resending
          ? 'Reenviando...'
          : cooldown > 0
          ? 'Reenviar código (${cooldown}s)'
          : 'Reenviar código';

      return Center(
        child: TextButton(
          onPressed: enabled ? controller.resendCode : null,
          style: TextButton.styleFrom(
            foregroundColor: palette.fieldText,
            disabledForegroundColor: palette.fieldHint,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
        ),
      );
    });
  }
}
