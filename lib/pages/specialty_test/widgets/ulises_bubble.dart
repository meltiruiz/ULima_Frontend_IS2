// lib/pages/specialty_test/widgets/ulises_bubble.dart
// La burbuja y el avatar de Ulises (RF-TEST-3 y RF-TEST-4).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../configs/themes.dart';
import '../specialty_test_logic.dart';

/// Ulises con la misma imagen del chatbot, recortada en círculo como en
/// `chatbot_page.dart`. Queda fuera del árbol de accesibilidad.
class UlisesAvatar extends StatelessWidget {
  const UlisesAvatar({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ClipOval(
        child: Image.asset(
          'assets/images/ulises_chatbot.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}

/// Una burbuja de Ulises, con el avatar de 28 px o con la sangría que deja
/// su lugar.
class UlisesBubble extends StatelessWidget {
  const UlisesBubble({
    super.key,
    required this.text,
    this.showAvatar = true,
    this.avatarSize = 28,
    this.fontSize = 13.5,
  });

  final String text;
  final bool showAvatar;
  final double avatarSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (showAvatar)
          UlisesAvatar(size: avatarSize)
        else
          SizedBox(width: avatarSize),
        const SizedBox(width: 7),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: MaterialTheme.cardBg(b),
              border: Border.all(color: MaterialTheme.testLine(b)),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(6),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: MaterialTheme.textPrimary(b),
                fontSize: fontSize,
                height: 1.4,
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
      ],
    );
  }
}

/// El sello «Cierra el bloque k de B», un poco girado, en `testAccentSoft`.
class SelloDeBloqueView extends StatelessWidget {
  const SelloDeBloqueView({super.key, required this.sello});

  final SelloDeBloque sello;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Padding(
      padding: const EdgeInsets.only(left: 35),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Transform.rotate(
          angle: -2 * math.pi / 180,
          child: Container(
            padding: const EdgeInsets.fromLTRB(3, 3, 10, 3),
            decoration: BoxDecoration(
              color: MaterialTheme.testAccentSoft(b),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: MaterialTheme.testAccent(b),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.check,
                      size: 11,
                      color: MaterialTheme.testAccentInk(b),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    sello.texto,
                    style: TextStyle(
                      color: MaterialTheme.testAccentDeep(b),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// El último turno de Ulises, con sus burbujas, el avatar en la última y el
/// sello después de la primera si lo hay. Es una región viva, así que el
/// lector lee la reacción al avanzar (RF-TEST-13).
class UlisesTurnView extends StatelessWidget {
  const UlisesTurnView({super.key, required this.turno, this.focusNode});

  final TurnoDeUlises turno;

  /// El foco del lector en la espera (RF-TEST-13).
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final lineas = turno.lineas;
    final hijos = <Widget>[];
    for (var i = 0; i < lineas.length; i++) {
      if (i > 0) hijos.add(const SizedBox(height: 4));
      hijos.add(
        UlisesBubble(text: lineas[i], showAvatar: i == lineas.length - 1),
      );
      if (i == 0 && turno.sello != null) {
        hijos
          ..add(const SizedBox(height: 6))
          ..add(SelloDeBloqueView(sello: turno.sello!));
      }
    }
    Widget contenido = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: hijos,
    );
    // El Focus va dentro de la región viva, así que su nodo es el mismo.
    if (focusNode != null) {
      contenido = Focus(focusNode: focusNode, child: contenido);
    }
    return Semantics(liveRegion: true, container: true, child: contenido);
  }
}
