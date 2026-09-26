import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as gsi_web;

import '../domain/bienvenida/bienvenida_turnos.dart';

/// Dibuja el botón oficial de Google (GIS) para web. Al hacer clic dispara
/// el flujo de Google, y la cuenta llega por `GoogleSignIn.onCurrentUserChanged`
/// a LoginController, que publica el desenlace para la bienvenida
/// (RF-BIEN-6).
///
/// El botón se crea una vez por configuración y se reutiliza, para que el
/// SDK no llame a `initialize()` en cada reconstrucción. La configuración de
/// GIS queda fija al dibujar el botón, así que un cambio del tema o del ancho
/// lo vuelve a dibujar. El aviso de GIS por un `initialize()` repetido que eso
/// puede dejar en la consola se acepta, porque web no se despliega.
Widget googleSignInButton({
  required ConfiguracionDelBotonDeGoogle configuracion,
}) => _GoogleSignInButtonWeb(configuracion: configuracion);

class _GoogleSignInButtonWeb extends StatefulWidget {
  const _GoogleSignInButtonWeb({required this.configuracion});

  final ConfiguracionDelBotonDeGoogle configuracion;

  @override
  State<_GoogleSignInButtonWeb> createState() => _GoogleSignInButtonWebState();
}

class _GoogleSignInButtonWebState extends State<_GoogleSignInButtonWeb> {
  late Widget _button = _dibujar(widget.configuracion);

  @override
  void didUpdateWidget(_GoogleSignInButtonWeb anterior) {
    super.didUpdateWidget(anterior);
    final antes = anterior.configuracion;
    final ahora = widget.configuracion;
    if (antes.tema != ahora.tema || antes.ancho != ahora.ancho) {
      _button = _dibujar(ahora);
    }
  }

  /// Los valores salen de la función pura de lib/domain/bienvenida (B-35).
  static Widget _dibujar(ConfiguracionDelBotonDeGoogle c) =>
      gsi_web.renderButton(
        configuration: gsi_web.GSIButtonConfiguration(
          type: gsi_web.GSIButtonType.standard,
          theme: switch (c.tema) {
            TemaDelBotonDeGoogle.outline => gsi_web.GSIButtonTheme.outline,
            TemaDelBotonDeGoogle.filledBlack =>
              gsi_web.GSIButtonTheme.filledBlack,
          },
          size: gsi_web.GSIButtonSize.large,
          text: gsi_web.GSIButtonText.continueWith,
          shape: gsi_web.GSIButtonShape.rectangular,
          logoAlignment: gsi_web.GSIButtonLogoAlignment.left,
          minimumWidth: c.ancho,
          locale: ConfiguracionDelBotonDeGoogle.idioma,
        ),
      );

  @override
  Widget build(BuildContext context) => KeyedSubtree(
    // Un botón nuevo monta su propio elemento de GIS.
    key: ValueKey<Object>(_button),
    child: _button,
  );
}
