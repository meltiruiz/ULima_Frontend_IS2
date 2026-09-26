// lib/pages/specialty_test/widgets/test_buttons.dart
// Los botones y el mensaje de error que comparten las pantallas del test y
// el asistente (RF-TEST-1, RF-TEST-11 y RF-TEST-12).

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../configs/themes.dart';

/// El botón principal, a lo ancho, con 52 px de alto como mínimo, degradado
/// de `testAccentHi` a `testAccent` y texto en `testAccentInk`. Desactivado
/// baja su opacidad y no responde.
class TestPrimaryButton extends StatelessWidget {
  const TestPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final double height;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final tinta = MaterialTheme.testAccentInk(b);
    final activo = onPressed != null && !loading;
    return Semantics(
      button: true,
      enabled: activo,
      label: label,
      excludeSemantics: true,
      onTap: activo ? onPressed : null,
      child: Opacity(
        opacity: activo || loading ? 1 : 0.45,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: height),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  MaterialTheme.testAccentHi(b),
                  MaterialTheme.testAccent(b),
                ],
              ),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(17),
                onTap: activo ? onPressed : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: tinta,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (loading) ...[
                        const SizedBox(width: 9),
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: tinta,
                          ),
                        ),
                      ] else if (icon != null) ...[
                        const SizedBox(width: 9),
                        Icon(icon, size: 19, color: tinta),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// El botón secundario, con texto en `testAccentText`, 48 px de alto como
/// mínimo y sin fondo.
class TestSecondaryButton extends StatelessWidget {
  const TestSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final color = MaterialTheme.testAccentText(b);
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        disabledForegroundColor: color.withValues(alpha: 0.45),
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 6)],
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Un error de carga (RF-TEST-11), con el texto en `textPrimary` sobre
/// `cardBg`, el ícono en `iconoNaranja` y «Reintentar» como botón
/// secundario.
class TestErrorMessage extends StatelessWidget {
  const TestErrorMessage({
    super.key,
    required this.text,
    required this.onRetry,
  });

  final String text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 6),
      decoration: BoxDecoration(
        color: MaterialTheme.cardBg(b),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MaterialTheme.testLine(b)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Icon(
                  LucideIcons.wifiOff,
                  size: 18,
                  color: MaterialTheme.iconoNaranja(b),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: MaterialTheme.textPrimary(b),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TestSecondaryButton(label: 'Reintentar', onPressed: onRetry),
          ),
        ],
      ),
    );
  }
}
