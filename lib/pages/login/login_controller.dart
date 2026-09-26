// lib/pages/login/login_controller.dart

import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../services/auth_service.dart';

enum TipoDeDesenlace { sesionPuesta, error, sinConexion, cancelado }

/// Lo que devuelve un intento de entrar. La bienvenida decide el turno
/// siguiente con él, y el controlador ya no navega (RF-BIEN-6).
class DesenlaceDelLogin {
  const DesenlaceDelLogin.sesionPuesta()
    : tipo = TipoDeDesenlace.sesionPuesta,
      mensaje = null;
  const DesenlaceDelLogin.error(String this.mensaje)
    : tipo = TipoDeDesenlace.error;
  const DesenlaceDelLogin.sinConexion()
    : tipo = TipoDeDesenlace.sinConexion,
      mensaje = null;
  const DesenlaceDelLogin.cancelado()
    : tipo = TipoDeDesenlace.cancelado,
      mensaje = null;

  final TipoDeDesenlace tipo;
  final String? mensaje;
}

class LoginController extends GetxController {
  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final submitting = false.obs;
  final passwordVisible = false.obs;

  AuthService get _auth => AuthService.to;

  StreamSubscription<GoogleSignInAccount?>? _googleSub;

  @override
  void onInit() {
    super.onInit();
    // En web el login con Google se hace con el botón oficial (renderButton):
    // la cuenta llega por este stream, no por un Future.
    if (kIsWeb) {
      _googleSub = _auth.googleSignIn.onCurrentUserChanged.listen(
        _onGoogleUserChanged,
      );
    }
  }

  /// El desenlace del login con Google en web, que llega por
  /// `onCurrentUserChanged` sin nadie que lo espere (RF-BIEN-6).
  final desenlaceDeGoogleEnWeb = Rxn<DesenlaceDelLogin>();

  Future<void> _onGoogleUserChanged(GoogleSignInAccount? account) async {
    if (account == null || submitting.value) return;
    submitting.value = true;
    try {
      final error = await _auth.finishGoogleLogin(account);
      final desenlace = error == null
          ? const DesenlaceDelLogin.sesionPuesta()
          : DesenlaceDelLogin.error(error);
      desenlaceDeGoogleEnWeb.value = desenlace;
    } catch (_) {
      desenlaceDeGoogleEnWeb.value = const DesenlaceDelLogin.sinConexion();
    } finally {
      submitting.value = false;
    }
  }

  /// Limpia el formulario. Se llama al (re)entrar a /login porque el
  /// LoginController es permanente (ver LoginBinding).
  void resetFields() {
    vaciarCampos();
    submitting.value = false;
  }

  /// Vacía el código y la contraseña. La bienvenida lo llama al salir hacia
  /// el horario, al reiniciarse y tras un 401, así que la contraseña ya no
  /// queda en el campo durante toda la sesión (RF-BIEN-5).
  void vaciarCampos() {
    codeController.clear();
    passwordController.clear();
    passwordVisible.value = false;
    // Un desenlace de Google en web sin atender no llega a la visita nueva.
    desenlaceDeGoogleEnWeb.value = null;
  }

  /// Entra con código o usuario y contraseña, sin navegar.
  Future<DesenlaceDelLogin> entrar() async {
    final code = codeController.text.trim();
    final password = passwordController.text;
    if (code.isEmpty || password.isEmpty) {
      // Es solo defensa, porque la bienvenida no deja enviar un campo vacío.
      const mensaje = 'Ingresa tu código y contraseña.';
      return const DesenlaceDelLogin.error(mensaje);
    }
    submitting.value = true;
    try {
      final error = await _auth.login(code: code, password: password);
      if (error != null) {
        return DesenlaceDelLogin.error(error);
      }
      return const DesenlaceDelLogin.sesionPuesta();
    } catch (_) {
      // `AuthService.login` solo atrapa ApiException, y un fallo de red sale
      // crudo. Antes dejaba el botón girando.
      return const DesenlaceDelLogin.sinConexion();
    } finally {
      submitting.value = false;
    }
  }

  /// Entra con Google en Android e iOS, sin navegar.
  Future<DesenlaceDelLogin> entrarConGoogle() async {
    submitting.value = true;
    // Tras un 401 el usuario viejo sigue en memoria sin token, así que la
    // sesión solo queda puesta si entra un usuario nuevo (RF-BIEN-21).
    final antes = _auth.currentUser;
    try {
      final error = await _auth.loginWithGoogle();
      if (error != null) {
        return DesenlaceDelLogin.error(error);
      }
      // `loginWithGoogle` devuelve null también cuando la persona cancela.
      final despues = _auth.currentUser;
      return despues == null || identical(despues, antes)
          ? const DesenlaceDelLogin.cancelado()
          : const DesenlaceDelLogin.sesionPuesta();
    } catch (_) {
      return const DesenlaceDelLogin.sinConexion();
    } finally {
      submitting.value = false;
    }
  }

  @override
  void onClose() {
    _googleSub?.cancel();
    codeController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
