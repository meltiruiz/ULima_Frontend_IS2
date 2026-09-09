import 'dart:async';

import '../models/registro_models.dart';
import 'api_client.dart';

/// Alta de cuenta en ULima++ para quien todavía no existe en la base.
///
/// La persona escribe su código, la contraseña que quiere para ULima++, su
/// contraseña de miUlima y el código del authenticator. El BACKEND entra al
/// portal, comprueba que sea alumno matriculado, crea la cuenta e importa el
/// ciclo, todo en una transacción.
///
/// **Las credenciales de miUlima no se guardan en ningún lado.** Llegan por
/// parámetro, viajan en el cuerpo y se descartan. No entran en un `Rx`, no van
/// a `shared_preferences`, no se imprimen.
class RegistroService {
  RegistroService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  /// `ApiClient` no impone timeout (`_send` llama a `request.send()` sin
  /// `.timeout()`), así que sin esto la pantalla quedaría colgada para siempre.
  ///
  /// Son 120 s y no los 90 de la importación porque el registro hace todo lo
  /// que hace ella —incluido el login contra el portal— y además crea la
  /// cuenta. Quedarse corto es peor que quedarse largo: el servidor puede
  /// confirmar la transacción mientras el cliente ya dejó de esperar.
  static const Duration registroTimeout = Duration(seconds: 120);

  /// Registra y devuelve la sesión, o lanza [RegistroFailure] con un mensaje
  /// listo para mostrar. Nunca lanza `ApiException` cruda.
  Future<RegistroResult> registrar({
    required String code,
    required String portalPassword,
    required String passcode,
    required String password,
  }) async {
    Map<String, dynamic> res;
    try {
      res = await _api.postJson(
        '/auth/register',
        body: {
          'code': code,
          'portalPassword': portalPassword,
          'passcode': passcode,
          'password': password,
        },
      ).timeout(registroTimeout);
    } on ApiException catch (e) {
      throw RegistroFailure(mensajeDeError(e), code: e.code);
    } on TimeoutException {
      // NO se afirma que falló: el servidor pudo haber confirmado la
      // transacción mientras dejábamos de esperar. Ver BR-REG-F-08.
      throw const RegistroFailure(
        'No pudimos confirmar si tu cuenta se creó.',
        code: 'TIEMPO_AGOTADO',
      );
    } catch (_) {
      // `ApiClient` propaga los fallos de red sin envolver. A diferencia del
      // plazo vencido, acá lo habitual es que la petición ni haya llegado.
      throw const RegistroFailure(
        'No hay conexión. Revisa tu internet e inténtalo de nuevo.',
        code: 'SIN_CONEXION',
      );
    }

    // A partir de acá el 201 ya llegó: la cuenta EXISTE. Nada de lo que pase
    // ahora puede reportarse como "no se pudo crear" (BR-REG-F-10).
    try {
      final r = RegistroResult.fromJson(res);
      if (r.token.isEmpty) {
        throw const RegistroFailure(
          'Tu cuenta se creó, pero no recibimos la sesión.',
          code: 'SIN_TOKEN',
        );
      }
      return r;
    } on RegistroFailure {
      rethrow;
    } catch (_) {
      // `UserModel.fromJson` hace casts duros sobre `role` y `setupComplete`.
      throw const RegistroFailure(
        'Tu cuenta se creó, pero no pudimos leer la respuesta.',
        code: 'SIN_TOKEN',
      );
    }
  }

  /// Traduce el código del backend a algo que la persona entienda.
  ///
  /// Pública y estática a propósito, para poder probarla directo: la
  /// equivalente de portal-sync es privada y sus tests tienen que ejercerla
  /// dando un rodeo por `import()`.
  static String mensajeDeError(ApiException e) {
    switch (e.code) {
      case 'USER_ALREADY_EXISTS':
        return 'Ya existe una cuenta con ese código. Inicia sesión o recupera '
            'tu contraseña.';
      case 'PORTAL_AUTH_FAILED':
        // Nombra las dos causas porque el backend no las distingue: aplastarlo
        // a "contraseña mala" manda a cambiar la contraseña universitaria sin
        // motivo, cuando lo más probable es que el código haya vencido.
        return 'miUlima rechazó los datos. Revisa tu contraseña del portal y '
            'que el código del authenticator siga vigente.';
      case 'PORTAL_SESSION_INVALID':
        return 'La sesión de miUlima se cortó mientras cargábamos. Inténtalo de nuevo.';
      case 'NOT_ENROLLED':
        // La frase final no es adorno. Este código vuelve a `verificar`, donde
        // el único botón dice "Crear mi cuenta": sin decirlo, la pantalla se
        // lee como un formulario que hay que corregir y la persona reintenta.
        // Reintentar no puede funcionar —la matrícula no aparece porque no
        // existe— y a los cinco intentos el backend la bloquea una hora.
        return 'miUlima no reporta matrícula en el ciclo actual, así que '
            'todavía no podemos crear tu cuenta. No hace falta que lo '
            'intentes de nuevo ahora.';
      case 'PORTAL_IDENTITY_UNVERIFIABLE':
        return 'No pudimos leer tu matrícula en miUlima.';
      case 'PORTAL_TIMEOUT':
        return 'miUlima tardó demasiado en responder. Inténtalo más tarde.';
      case 'PORTAL_UNAVAILABLE':
        return 'miUlima no está respondiendo. Inténtalo más tarde.';
      case 'REGISTRATION_UNAVAILABLE':
        // Mismo motivo que `NOT_ENROLLED`: el registro está apagado del lado
        // del servidor y volver a pulsar el botón solo gasta cupo. Acá el
        // "más tarde" sí tiene sentido porque el estado cambia solo.
        return 'El registro no está disponible por ahora. Vuelve a intentarlo '
            'más tarde.';
      case 'RATE_LIMITED':
        // Se muestra el texto del backend y NO se lee `details`: detrás de este
        // código hay dos limitadores y la clave cambia entre ellos
        // (`retryAfterMinutes` vs `retryAfterSeconds`).
        //
        // Tampoco se le agrega nada: los dos mensajes ya dicen cuánto esperar
        // —«Intenta de nuevo en 42 minuto(s).» el de por código, «en unos
        // segundos» el de concurrencia— y cualquier añadido nuestro chocaría
        // con uno de los dos. El respaldo cubre el caso de `message` vacío.
        return e.message.isNotEmpty
            ? e.message
            : 'Demasiados intentos. Espera un rato antes de volver a intentar.';
      case 'INVALID_REQUEST_BODY':
      case 'INVALID_JSON_BODY':
        // Los dos traen su mensaje en inglés.
        return 'Revisa tus datos: el código debe tener entre 6 y 10 dígitos.';
      case 'INTERNAL_ERROR':
      case 'INTERNAL_SERVER_ERROR':
        // Son dos códigos distintos porque `register` es el único método del
        // módulo sin traductor de errores de base de datos.
        return 'Algo falló de nuestro lado. Inténtalo de nuevo.';
      default:
        return e.message.isNotEmpty
            ? e.message
            : 'No pudimos crear tu cuenta. Inténtalo de nuevo.';
    }
  }
}
