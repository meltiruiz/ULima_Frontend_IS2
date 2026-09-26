// lib/components/portal_consent/portal_consent_view.dart
// Pantalla de consentimiento previa a pedirle al alumno la contraseña de
// miUlima. La monta Portal Sync (/portal-sync), y la bienvenida (/login) usa
// sus textos en la tarjeta del consentimiento de la conversación.

import 'package:flutter/material.dart';

import '../../pages/password_reset/password_reset_ui.dart';

/// Contenido de la única pantalla de consentimiento de la app (RF-REC-6).
///
/// La Ley 29733 pide decirle al alumno qué datos se llevan, para qué y qué
/// pasa con su contraseña **antes** de que la escriba. Portal Sync monta este
/// widget y la bienvenida dibuja su tarjeta con estas mismas constantes, así
/// que los dos lugares donde ULima++ se la pide dicen exactamente lo mismo, y
/// si el alumno acepta en uno, aceptó lo mismo que en el otro.
///
/// Es solo el contenido de la tarjeta: quien lo usa lo pasa como `child` de su
/// propio [PasswordResetScaffold], igual que `portal_sync_page.dart` hace con
/// sus otros pasos.
///
/// No recuerda nada. La aceptación dura lo que dura la visita, porque se
/// muestra antes de cada importación (RF-REC-6, "Qué NO entra").
class PortalConsentView extends StatelessWidget {
  const PortalConsentView({
    super.key,
    required this.palette,
    required this.onAccept,
    required this.onExit,
    required this.exitLabel,
  });

  final PasswordResetPalette palette;
  final VoidCallback onAccept;
  final VoidCallback onExit;

  /// Texto del enlace para salir, «Ahora no» en Portal Sync.
  final String exitLabel;

  static const String titulo = 'Antes de entrar a miUlima';
  static const String introduccion =
      'Para cargar tus datos, ULima++ entra a miUlima con tu contraseña y trae:';
  static const List<String> datosImportados = <String>[
    'Tus datos: nombre, código, carrera y nivel.',
    'Tu ciclo: cursos, secciones, docentes, horarios y matrícula.',
    'Tu récord académico: notas históricas, PPA, ubicación relativa y créditos.',
    'Tu estado de impedimento y deuda.',
  ];
  static const String finalidad =
      'Estos datos se usan para mostrártelos a ti y para las funciones de '
      'ULima++ que ya usas: tu horario, tu malla y la lista de tu sección que '
      've tu docente.';
  static const String contrasena =
      'Tu contraseña se usa una sola vez y no se guarda.';
  static const String botonAceptar = 'Acepto';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.fieldText,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          introduccion,
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.fieldHint, fontSize: 12, height: 1.4),
        ),
        const SizedBox(height: 16),
        for (final dato in datosImportados)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // `palette.cursor` y NO `buttonBackground`: en modo oscuro el
                // fondo del botón es 0x00000000 y el ícono quedaría invisible
                // sobre la tarjeta negra (portal_sync_page.dart:187-190).
                Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: palette.cursor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dato,
                    style: TextStyle(
                      color: palette.fieldText,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Text(
          finalidad,
          style: TextStyle(
            color: palette.fieldText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          contrasena,
          style: TextStyle(
            color: palette.fieldText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        PasswordResetPrimaryButton(
          palette: palette,
          label: botonAceptar,
          loading: false,
          onPressed: onAccept,
        ),
        const SizedBox(height: 14),
        // No hay widget público de botón secundario en el kit: este es el
        // mismo GestureDetector + Text de 'Ahora no' (portal_sync_page.dart:116-125).
        GestureDetector(
          onTap: onExit,
          child: Text(
            exitLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.fieldHint,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
