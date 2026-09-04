import 'dart:async';

import '../models/portal_sync_models.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'courses_service.dart';
import 'evaluations_service.dart';
import 'malla_service.dart';

/// Carga de ciclo desde miUlima.
///
/// El alumno escribe su contraseña de miUlima y el código del authenticator; el
/// BACKEND hace el login contra el portal y corre la importación. El usuario del
/// portal no se manda: es el código del alumno y el backend ya lo tiene del JWT.
///
/// **La contraseña no se guarda en ningún lado.** Se recibe por parámetro, viaja
/// en el cuerpo de la petición y se descarta. No entra en un `Rx`, no va a
/// `shared_preferences`, no se imprime.
class PortalSyncService {
  PortalSyncService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  /// `ApiClient` no impone timeout (`_send` llama a `request.send()` sin
  /// `.timeout()`), así que sin esto la pantalla quedaría colgada para siempre
  /// si el portal no responde. La importación real tarda ~30-50 s: 90 s deja
  /// margen sin que el alumno espere indefinidamente.
  static const Duration importTimeout = Duration(seconds: 90);
  static const Duration statusTimeout = Duration(seconds: 15);

  /// Estado de la carga. Nunca lanza: un fallo acá no puede romper el Home.
  Future<PortalSyncStatus> status() async {
    try {
      // Sin `token:`: `ApiClient._send` lo resuelve solo desde el almacén
      // seguro, igual que el resto de los servicios del repo.
      final res = await _api
          .getJson('/portal-sync/status')
          .timeout(statusTimeout);
      return PortalSyncStatus.fromJson(res);
    } catch (_) {
      // Incluye ApiException y fallos de red crudos: ApiClient no los envuelve.
      return PortalSyncStatus.desconocido;
    }
  }

  /// Importa usando las credenciales de miUlima.
  ///
  /// Devuelve el resultado, o lanza [PortalSyncFailure] con un mensaje ya listo
  /// para mostrar. Nunca lanza `ApiException` cruda: la pantalla no debería
  /// tener que conocer los códigos del backend.
  Future<PortalSyncResult> import({
    required String password,
    required String passcode,
  }) async {
    try {
      final res = await _api
          .postJson(
            '/portal-sync/import',
            body: {
              'credentials': {'password': password, 'passcode': passcode},
            },
          )
          .timeout(importTimeout);
      return PortalSyncResult.fromJson(res);
    } on ApiException catch (e) {
      throw PortalSyncFailure(_mensajeDe(e), code: e.code);
    } on TimeoutException {
      throw const PortalSyncFailure(
        'La carga tardó demasiado. miUlima puede estar lento; inténtalo de nuevo.',
      );
    } catch (_) {
      // ApiClient propaga los fallos de red sin envolver.
      throw const PortalSyncFailure('No hay conexión. Revisa tu internet e inténtalo de nuevo.');
    }
  }

  /// Traduce el código del backend a algo que el alumno entienda.
  ///
  /// Ninguno de estos es 401 a propósito: el `ApiClient` trata cualquier 401
  /// como expiración del JWT y expulsa al login, así que un tipeo en el código
  /// del authenticator cerraría la sesión de ULima++.
  static String _mensajeDe(ApiException e) {
    switch (e.code) {
      case 'PORTAL_LOGIN_REJECTED':
        return 'miUlima rechazó los datos. Revisa tu contraseña y que el código '
            'del authenticator siga vigente.';
      case 'PORTAL_SESSION_INVALID':
        return 'La sesión de miUlima expiró mientras cargábamos. Inténtalo de nuevo.';
      case 'PORTAL_IDENTITY_MISMATCH':
        return 'Esa cuenta de miUlima no corresponde a tu usuario de ULima++.';
      case 'PORTAL_IDENTITY_UNVERIFIABLE':
        return 'No se pudo confirmar tu identidad en el portal.';
      case 'PORTAL_TIMEOUT':
        return 'miUlima tardó demasiado en responder. Inténtalo más tarde.';
      case 'PORTAL_UNAVAILABLE':
        return 'miUlima no está respondiendo. Inténtalo más tarde.';
      case 'RATE_LIMITED':
        return e.message.isNotEmpty
            ? e.message
            : 'Demasiados intentos. Espera un rato antes de volver a cargar.';
      default:
        return e.message.isNotEmpty
            ? e.message
            : 'No se pudo cargar tus datos. Inténtalo de nuevo.';
    }
  }

  /// Invalida todo lo que quedó viejo después de importar.
  ///
  /// Son CINCO capas, no las tres que suponía el diseño original. Cada una
  /// cortocircuita por su cuenta, así que saltarse una deja la pantalla
  /// mostrando datos del ciclo anterior sin ningún síntoma visible:
  ///
  ///  1. El usuario (nivel, carrera): reasignarlo dispara los `ever()` que
  ///     ambos controllers de malla instalan sobre `currentUserRx`.
  ///  2. `CoursesService` y `EvaluationSyllabusService`, que cortocircuitan por
  ///     código de alumno; como el alumno es el mismo, sin `clear()` la recarga
  ///     se salta entera.
  ///  3. `MallaService`, que hace lo mismo. Sin esto, `MallaListController.retry()`
  ///     NO vuelve a pedir `/curriculum/me`.
  ///  4. Los controllers vivos.
  ///  5. Las alertas, porque la importación crea algunas.
  ///
  /// Nada acá puede lanzar: el import ya salió bien y un fallo del refresco no
  /// debe convertirse en un error para el alumno.
  Future<void> refreshAfterImport({String? token}) async {
    // El token PRIMERO: trae el cargo recalculado y `refreshCurrentUser` va a
    // usarlo para pedir /auth/me. Al revés se consultaría con el token viejo.
    if (token != null) {
      try {
        await AuthService.to.replaceToken(token);
      } catch (_) { /* seguir con el token viejo es peor que nada, no fatal */ }
    }
    try {
      await AuthService.to.refreshCurrentUser();
    } catch (_) { /* el import ya salió bien */ }
    try {
      CoursesService().clear();
      EvaluationSyllabusService().clear();
      MallaService.to.clear();
    } catch (_) { /* servicios no registrados en algún test */ }
  }
}

/// Fallo de la carga con un mensaje ya listo para mostrar.
class PortalSyncFailure implements Exception {
  const PortalSyncFailure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'PortalSyncFailure($code): $message';
}
