// lib/domain/recarga_ulima/avisos_recarga.dart
//
// El aviso rojo de una recarga fallida (RF-RCG-4 y D5 de
// specs/features/recarga-portal/recarga-portal.spec.md). La app nunca
// muestra el `message` del backend, así que cada causa tiene su cuerpo fijo.

/// Qué hace el botón del aviso.
enum AccionAviso { reintentar, cargarMisDatos }

class AvisoRecarga {
  const AvisoRecarga({
    required this.cuerpo,
    required this.accion,
    this.esperaLectura = false,
  });

  /// El título es siempre el mismo.
  static const String titulo = 'No se pudo actualizar';

  final String cuerpo;
  final AccionAviso accion;

  /// Es el aviso del plazo o de la red, que se borra solo cuando una lectura
  /// posterior muestra que la recarga sí queda guardada (D23).
  final bool esperaLectura;

  String get textoAccion =>
      accion == AccionAviso.reintentar ? 'Reintentar' : 'Cargar mis datos';

  @override
  bool operator ==(Object other) =>
      other is AvisoRecarga &&
      other.cuerpo == cuerpo &&
      other.accion == accion &&
      other.esperaLectura == esperaLectura;

  @override
  int get hashCode => Object.hash(cuerpo, accion, esperaLectura);
}

/// El plazo de 90 s de la app vence sin respuesta.
const AvisoRecarga avisoPlazo = AvisoRecarga(
  cuerpo:
      'La actualización tardó demasiado. Inténtalo de nuevo en unos '
      'minutos.',
  accion: AccionAviso.reintentar,
  esperaLectura: true,
);

/// La petición falla por la red, sin respuesta del backend.
const AvisoRecarga avisoSinRed = AvisoRecarga(
  cuerpo: 'No hay conexión. Revisa tu internet e inténtalo de nuevo.',
  accion: AccionAviso.reintentar,
  esperaLectura: true,
);

String _minutos(int n) => n == 1 ? '1 minuto' : '$n minutos';

AvisoRecarga _reintentar(String cuerpo) =>
    AvisoRecarga(cuerpo: cuerpo, accion: AccionAviso.reintentar);

AvisoRecarga _limite(Object? details) {
  final datos = details is Map ? details : const <Object?, Object?>{};
  final minutos = datos['retryAfterMinutes'];
  final n = minutos is num ? minutos.round() : null;
  switch (datos['kind']) {
    case 'quota' when n != null:
      return _reintentar(
        'Llegaste al límite de actualizaciones por hora. '
        'Intenta de nuevo en ${_minutos(n)}.',
      );
    case 'rejected_logins' when n != null:
      return _reintentar(
        'Hubo varios intentos con datos rechazados. Para '
        'cuidar tu cuenta de miUlima, intenta de nuevo en ${_minutos(n)}.',
      );
    default:
      return _reintentar(
        'Hubo demasiados intentos. Intenta de nuevo más tarde.',
      );
  }
}

/// El aviso de un error del backend, por su código (tabla de RF-RCG-4). Un
/// `400`, un `500` o un código desconocido dan el aviso genérico.
AvisoRecarga avisoDeError(String code, {Object? details}) {
  switch (code) {
    case 'PORTAL_LOGIN_REJECTED':
      return _reintentar(
        'miUlima rechazó los datos. Revisa tu contraseña y '
        'que el código del autenticador siga vigente.',
      );
    case 'RATE_LIMITED':
      return _limite(details);
    case 'PORTAL_REFRESH_IN_PROGRESS':
      return _reintentar(
        'Ya hay una actualización en curso. Espera a que '
        'termine y vuelve a intentarlo.',
      );
    case 'IMPORT_REQUIRED':
      return const AvisoRecarga(
        cuerpo: 'Primero carga tus datos del ciclo.',
        accion: AccionAviso.cargarMisDatos,
      );
    case 'PORTAL_SESSION_INVALID':
      return _reintentar(
        'miUlima cerró la sesión antes de terminar. Inténtalo de nuevo.',
      );
    case 'PORTAL_IDENTITY_MISMATCH':
      return _reintentar(
        'La cuenta de miUlima no corresponde a tu usuario de ULima++.',
      );
    case 'PORTAL_IDENTITY_UNVERIFIABLE':
      return _reintentar('No se pudo confirmar tu identidad en miUlima.');
    case 'PORTAL_UNAVAILABLE':
      return _reintentar('miUlima no está respondiendo. Inténtalo más tarde.');
    case 'PORTAL_UNREADABLE':
      return _reintentar(
        'miUlima responde con páginas que ULima++ no sabe leer.',
      );
    case 'PORTAL_TIMEOUT':
      return _reintentar(
        'miUlima tardó demasiado en responder. Inténtalo más tarde.',
      );
    default:
      return _reintentar('Algo falló al leer miUlima. Inténtalo de nuevo.');
  }
}
