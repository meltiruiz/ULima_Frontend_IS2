// lib/pages/password_reset/reset_password_controller.dart
// Paso 2 de la recuperación de contraseña: confirmar el código y definir
// la nueva contraseña. Funciona tanto desde el login (paso 1 previo) como
// desde el Perfil (modo autenticado, con correo enmascarado).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/password_reset_service.dart';
import '../../services/session_navigation.dart';
import '../../services/storage_service.dart';
import 'password_reset_validators.dart';

class ResetPasswordController extends GetxController {
  /// Inyectable solo para las pruebas: en la app se construye el real.
  ResetPasswordController({PasswordResetService? service})
      : _service = service ?? PasswordResetService();

  static const int resendCooldownSeconds = 60;

  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  /// Paso visible: 0 = código de verificación, 1 = nueva contraseña.
  final step = 0.obs;

  final errorMessage = RxnString();
  final submitting = false.obs;
  final resending = false.obs;
  final passwordVisible = false.obs;
  final confirmVisible = false.obs;

  /// Segundos restantes del cooldown de "Reenviar código" (0 = habilitado).
  final resendCooldown = 0.obs;
  Timer? _cooldownTimer;

  /// Código de alumno o correo con el que se solicitó el código.
  String identifier = '';

  /// Correo enmascarado (solo en el flujo autenticado desde Perfil).
  String? maskedEmail;

  final PasswordResetService _service;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      identifier = args['identifier']?.toString() ?? '';
      final masked = args['maskedEmail']?.toString();
      maskedEmail = (masked == null || masked.isEmpty) ? null : masked;
    }
    if (identifier.isEmpty) {
      // Llegada sin argumentos (p. ej. refresh del navegador en web o URL
      // directa): sin identifier no se puede confirmar, se vuelve al paso 1.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offNamed('/forgot-password');
      });
    }
  }

  /// El código tal como lo entiende el flujo: recortado a su largo.
  ///
  /// El campo ya no lleva `LengthLimitingTextInputFormatter` —era la causa del
  /// bug de borrado en iOS— así que el controller sí puede traer un dígito de
  /// más. Sin este recorte, `validateResetCode` rechazaría con «debe tener 6
  /// dígitos» un código que en pantalla se ve perfecto.
  String get _codigo {
    final crudo = codeController.text.trim();
    return crudo.length > passwordResetCodeLength
        ? crudo.substring(0, passwordResetCodeLength)
        : crudo;
  }

  /// Paso 1 -> 2: comprueba el código CONTRA EL BACKEND y solo entonces avanza.
  ///
  /// Antes solo miraba el formato en local, así que cualquier número de seis
  /// dígitos llegaba a la pantalla de contraseña y el rechazo aparecía al
  /// final, con la contraseña ya escrita dos veces y un intento gastado.
  ///
  /// El formato se sigue validando primero para no gastar una petición —ni un
  /// intento del token— con algo que ni siquiera tiene seis dígitos.
  Future<void> continueToPassword() async {
    if (submitting.value) return; // dos toques no gastan dos intentos

    final codeError = validateResetCode(_codigo);
    if (codeError != null) {
      errorMessage.value = codeError;
      return;
    }
    if (identifier.isEmpty) {
      errorMessage.value =
          'No se pudo verificar el código. Vuelve a solicitarlo.';
      return;
    }

    errorMessage.value = null;
    submitting.value = true;
    try {
      await _service.verify(identifier: identifier, code: _codigo);
      step.value = 1;
    } on ApiException catch (e) {
      errorMessage.value = e.message.isEmpty
          ? 'Código inválido o expirado.'
          : e.message;
    } catch (_) {
      errorMessage.value = 'No se pudo verificar el código. Revisa tu conexión.';
    } finally {
      submitting.value = false;
    }
  }

  /// Paso 2 -> 1 (flecha atrás o código rechazado por el backend).
  void backToCode() {
    errorMessage.value = null;
    step.value = 0;
  }

  Future<void> submit() async {
    final code = _codigo;
    final newPassword = passwordController.text;
    final confirmation = confirmController.text;

    final localError = validatePasswordResetForm(
      code: code,
      newPassword: newPassword,
      confirmation: confirmation,
    );
    if (localError != null) {
      errorMessage.value = localError;
      return;
    }
    if (identifier.isEmpty) {
      errorMessage.value =
          'No se pudo restablecer la contraseña. Vuelve a solicitar el código.';
      return;
    }

    errorMessage.value = null;
    submitting.value = true;

    try {
      await _service.confirm(
        identifier: identifier,
        code: code,
        newPassword: newPassword,
      );
      // La contraseña cambió: se invalida cualquier sesión local y se vuelve
      // al login. Se limpia el token antes para que logout() no llame al
      // backend con credenciales ya inválidas. offAllToLogin garantiza una
      // sola ruta /login aunque otro camino (p. ej. un 401 en vuelo) ya haya
      // navegado (ver services/session_navigation.dart).
      await StorageService.to.clearToken();
      await AuthService.to.logout();
      offAllToLogin();
      Get.snackbar(
        'Contraseña actualizada',
        'Inicia sesión con tu nueva contraseña.',
      );
    } on ApiException catch (e) {
      errorMessage.value = e.message;
      if (e.code == 'INVALID_RESET_CODE') {
        // El código es el problema: regresar al paso del código para
        // corregirlo o reenviarlo, con el error visible ahí.
        step.value = 0;
      }
    } catch (_) {
      errorMessage.value =
          'No se pudo restablecer la contraseña. Intenta de nuevo.';
    } finally {
      submitting.value = false;
    }
  }

  Future<void> resendCode() async {
    if (resendCooldown.value > 0 || resending.value || submitting.value) {
      return;
    }
    if (identifier.isEmpty) {
      errorMessage.value = 'No se pudo reenviar el código. Vuelve a empezar.';
      return;
    }

    errorMessage.value = null;
    resending.value = true;

    try {
      final message = await _service.request(identifier);
      _startCooldown();
      Get.snackbar('Código reenviado', message);
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (_) {
      errorMessage.value = 'No se pudo reenviar el código. Intenta de nuevo.';
    } finally {
      resending.value = false;
    }
  }

  void _startCooldown() {
    resendCooldown.value = resendCooldownSeconds;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendCooldown.value <= 1) {
        resendCooldown.value = 0;
        timer.cancel();
      } else {
        resendCooldown.value--;
      }
    });
  }

  @override
  void onClose() {
    _cooldownTimer?.cancel();
    codeController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.onClose();
  }
}
