// lib/services/password_reset_service.dart
// Recuperación de contraseña (HU20): solicitar y confirmar el código de reset.

import 'api_client.dart';

class PasswordResetService {
  final ApiClient _api = ApiClient();

  static const String genericRequestMessage =
      'Si la cuenta existe, enviamos un código de verificación al correo institucional.';

  /// Solicita un código de reset para [identifier] (código de alumno o correo
  /// institucional). El backend responde 200 siempre con un mensaje genérico.
  Future<String> request(String identifier) async {
    final response = await _api.postJson(
      '/auth/password-reset/request',
      body: {'identifier': identifier.trim()},
    );
    final message = response['message']?.toString();
    return (message == null || message.isEmpty)
        ? genericRequestMessage
        : message;
  }

  /// Comprueba el código ANTES de pedir la contraseña nueva (RS-AUTH-17).
  ///
  /// Existe porque la app avanzaba con cualquier código de seis dígitos: solo
  /// se validaba el formato en local y el rechazo llegaba al final, con la
  /// contraseña ya escrita y un intento del token gastado.
  ///
  /// No gasta el token —`confirm` lo sigue necesitando— pero sí consume un
  /// intento, por eso el backend permite 6 y no 5.
  ///
  /// Lanza [ApiException] (400 `INVALID_RESET_CODE`) si el código no sirve.
  Future<void> verify({required String identifier, required String code}) async {
    await _api.postJson(
      '/auth/password-reset/verify',
      body: {'identifier': identifier.trim(), 'code': code.trim()},
    );
  }

  /// Confirma el reset con el código recibido y la nueva contraseña.
  /// Lanza [ApiException] (400) con el mensaje del backend si el código es
  /// inválido/expirado o la contraseña no cumple el mínimo.
  Future<void> confirm({
    required String identifier,
    required String code,
    required String newPassword,
  }) async {
    await _api.postJson(
      '/auth/password-reset/confirm',
      body: {
        'identifier': identifier.trim(),
        'code': code.trim(),
        'newPassword': newPassword,
      },
    );
  }

  /// Envía el código al correo del usuario en sesión (flujo desde Perfil).
  /// Devuelve el mensaje del backend y el correo enmascarado al que se envió
  /// el código (campo `email` de la respuesta; vacío si el backend no lo da).
  Future<({String message, String maskedEmail})> requestMe() async {
    final response = await _api.postJson(
      '/auth/password-reset/request-me',
      body: const <String, dynamic>{},
    );
    final message = response['message']?.toString();
    return (
      message: (message == null || message.isEmpty)
          ? genericRequestMessage
          : message,
      maskedEmail:
          response['email']?.toString() ??
          response['maskedEmail']?.toString() ??
          '',
    );
  }
}
