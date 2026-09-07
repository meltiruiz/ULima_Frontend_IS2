// test/HU20_jeff/reset_password_controller_verify_test.dart
// RS-AUTH-21: el paso del código deja de mentir.
//
// Antes, `continueToPassword` solo miraba el formato en local, así que
// CUALQUIER número de seis dígitos llevaba a la pantalla de contraseña nueva.
// El rechazo llegaba al final, con la contraseña ya escrita dos veces y un
// intento del token gastado sin que el usuario se enterara.
//
// spec: ULima_Backend_IS2/specs/features/auth/password-reset-verify.spec.md

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/pages/password_reset/reset_password_controller.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/password_reset_service.dart';

/// Doble del servicio: registra qué se verificó y decide si acepta.
class _ServicioFalso extends PasswordResetService {
  _ServicioFalso({this.error});

  /// Si no es null, `verify` lo lanza.
  final Object? error;
  final List<({String identifier, String code})> verificados = [];

  @override
  Future<void> verify({required String identifier, required String code}) async {
    verificados.add((identifier: identifier, code: code));
    if (error != null) throw error!;
  }
}

void main() {
  ResetPasswordController montar(_ServicioFalso servicio, {String codigo = '123456'}) {
    Get.testMode = true;
    Get.arguments; // el controlador lee Get.arguments en onInit
    final c = ResetPasswordController(service: servicio);
    c.identifier = '20230001';
    c.codeController.text = codigo;
    return c;
  }

  group('solo avanza si el backend acepta el código', () {
    test('con código válido pasa al paso de la contraseña', () async {
      final servicio = _ServicioFalso();
      final c = montar(servicio);

      await c.continueToPassword();

      expect(c.step.value, 1);
      expect(c.errorMessage.value, isNull);
      expect(servicio.verificados.single.code, '123456');
    });

    test('con código rechazado se queda en el paso del código', () async {
      final servicio = _ServicioFalso(
        error: ApiException(
          statusCode: 400,
          code: 'INVALID_RESET_CODE',
          message: 'Código inválido o expirado.',
        ),
      );
      final c = montar(servicio);

      await c.continueToPassword();

      expect(c.step.value, 0, reason: 'no debe llegar a la pantalla de contraseña');
      expect(c.errorMessage.value, 'Código inválido o expirado.');
    });

    test('un fallo de red no se confunde con un código malo', () async {
      final servicio = _ServicioFalso(error: Exception('sin red'));
      final c = montar(servicio);

      await c.continueToPassword();

      expect(c.step.value, 0);
      expect(c.errorMessage.value, contains('conexión'));
    });
  });

  group('no gasta intentos del token de más', () {
    test('un código con formato inválido ni siquiera sale a la red', () async {
      final servicio = _ServicioFalso();
      final c = montar(servicio, codigo: '12');

      await c.continueToPassword();

      expect(servicio.verificados, isEmpty,
          reason: 'validar el formato primero evita gastar un intento del token');
      expect(c.step.value, 0);
      expect(c.errorMessage.value, isNotNull);
    });

    test('dos toques seguidos solo verifican una vez', () async {
      final servicio = _ServicioFalso();
      final c = montar(servicio);

      // Sin await en la primera: simula el doble toque real.
      final primera = c.continueToPassword();
      await c.continueToPassword();
      await primera;

      expect(servicio.verificados.length, 1);
    });

    test('el séptimo dígito que el campo ya permite se recorta al enviar', () async {
      // El campo dejó de llevar LengthLimitingTextInputFormatter para arreglar
      // el borrado en iOS, así que el controller puede traer un dígito de más.
      final servicio = _ServicioFalso();
      final c = montar(servicio, codigo: '1234567');

      await c.continueToPassword();

      expect(servicio.verificados.single.code, '123456');
      expect(c.step.value, 1);
    });
  });
}
