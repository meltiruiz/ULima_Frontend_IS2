import 'package:flutter/widgets.dart';

import '../domain/bienvenida/bienvenida_turnos.dart';
// Import condicional. En web usa el botón oficial de Google (GIS), y en
// móvil y escritorio el stub, porque ahí va el botón propio.
import 'google_sign_in_button_stub.dart'
    if (dart.library.html) 'google_sign_in_button_web.dart'
    as platform;

/// Botón oficial de Google Identity Services, con la configuración de la
/// bienvenida (RF-BIEN-6 y B-35). Solo se dibuja en web, porque en
/// `google_sign_in` 6.x `signIn()` no funciona ahí y se requiere
/// `renderButton`. En móvil devuelve un widget vacío.
Widget googleSignInButton({
  required ConfiguracionDelBotonDeGoogle configuracion,
}) => platform.googleSignInButton(configuracion: configuracion);
