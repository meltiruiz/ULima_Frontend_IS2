import 'package:flutter/widgets.dart';

import '../domain/bienvenida/bienvenida_turnos.dart';

/// Stub para plataformas que no son web. En móvil la bienvenida usa su botón
/// propio, que llama a `GoogleSignIn.signIn()`, así que aquí no se dibuja
/// nada.
Widget googleSignInButton({
  required ConfiguracionDelBotonDeGoogle configuracion,
}) => const SizedBox.shrink();
