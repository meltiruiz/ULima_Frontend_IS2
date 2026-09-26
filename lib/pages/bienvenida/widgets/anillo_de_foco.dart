// lib/pages/bienvenida/widgets/anillo_de_foco.dart
// El anillo de foco de la bienvenida (RF-BIEN-16). Con el foco del teclado
// físico en un botón, una píldora o un enlace, un anillo de 2 dp en
// bienvenidaFoco lo rodea con la forma del control. Con el tacto no se ve,
// porque sigue el modo de resaltado de Flutter.

import 'package:flutter/material.dart';

import '../../../configs/themes.dart';

class AnilloDeFoco extends StatefulWidget {
  const AnilloDeFoco({super.key, required this.radio, required this.child});

  /// El radio de las esquinas del control, para que el anillo siga su forma.
  final BorderRadius radio;
  final Widget child;

  @override
  State<AnilloDeFoco> createState() => _AnilloDeFocoState();
}

class _AnilloDeFocoState extends State<AnilloDeFoco> {
  bool _conFoco = false;
  bool _conTeclado =
      FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_alCambiarElModo);
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_alCambiarElModo);
    super.dispose();
  }

  void _alCambiarElModo(FocusHighlightMode modo) {
    final conTeclado = modo == FocusHighlightMode.traditional;
    if (mounted && conTeclado != _conTeclado) {
      setState(() => _conTeclado = conTeclado);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = MaterialTheme.bienvenidaFoco(Theme.brightnessOf(context));
    return Focus(
      // No toma el foco. Solo escucha el del control que envuelve, y no suma
      // nada a la semántica.
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onFocusChange: (conFoco) {
        if (conFoco != _conFoco) setState(() => _conFoco = conFoco);
      },
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: widget.radio,
          border: _conFoco && _conTeclado
              ? Border.all(color: color, width: 2)
              : null,
        ),
        child: widget.child,
      ),
    );
  }
}
