// lib/configs/theme.dart

import 'package:flutter/material.dart';

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static const Color primaryColor = Color(0xFFFF6600);

  static const Color primaryDark = Color(0xFFD45500);

  static const Color blackColor = Color(0xFF1A1A1A);

  static const Color greyColor = Color.fromARGB(255, 32, 32, 32);

  static const Color whiteColor = Color(0xFFFFFFFF);

  //FONDO HEADER
  static Color headerColor(Brightness brightness) {
    return brightness == Brightness.light
        ? primaryColor
        : Color.fromARGB(255, 30, 30, 36);
  }

  //INFO CURSOS
  static Color bloqueCurso(Brightness brightness) {
    return brightness == Brightness.light
        ? const Color(0xFFFF7A1A)
        : primaryColor;
  }

  static Color bloqueSeccion(Brightness brightness) {
    return brightness == Brightness.light
        ? const Color(0xFFFFD8C2)
        : const Color(0xFF4A332B);
  }

  static Color bloqueAsistencia(Brightness brightness) {
    return brightness == Brightness.light
        ? const Color(0xFFFFE8DC)
        : const Color(0xFF342B2F);
  }

  static Color bloqueAsistenciaLinea(Brightness brightness) {
    return brightness == Brightness.light
        ? const Color(0xFFE3B08C)
        : const Color(0xFFFFB088);
  }

  // ── Helpers para Malla y Perfil (dark mode) ──────────────────────────────

  /// Fondo principal del canvas / página.
  static Color pageBg(Brightness b) =>
      b == Brightness.light ? const Color(0xFFF8FAFC) : const Color(0xFF16161C);

  /// Fondo de tarjetas / barras.
  static Color cardBg(Brightness b) =>
      b == Brightness.light ? Colors.white : const Color(0xFF1E1E24);

  /// Texto primario fuerte (títulos, nombres).
  static Color textPrimary(Brightness b) =>
      b == Brightness.light ? const Color(0xFF0F172A) : const Color(0xFFEDEDF3);

  /// Texto secundario (subtítulos, labels).
  static Color textSecondary(Brightness b) =>
      b == Brightness.light ? const Color(0xFF334155) : const Color(0xFFA0A0B0);

  /// Texto terciario / muted (hints, caption).
  static Color textMuted(Brightness b) =>
      b == Brightness.light ? const Color(0xFF64748B) : const Color(0xFF787890);

  /// Texto dimmed (aún más sutil).
  static Color textDimmed(Brightness b) =>
      b == Brightness.light ? const Color(0xFF475569) : const Color(0xFF8888A0);

  /// Borde de tarjetas y separadores.
  static Color borderColor(Brightness b) =>
      b == Brightness.light ? const Color(0xFFE5E5E5) : const Color(0xFF2E2E38);

  /// Fondo de tags / badges.
  static Color tagBg(Brightness b) =>
      b == Brightness.light ? const Color(0xFFF1F5F9) : const Color(0xFF28283A);

  /// Fondo de botones icon.
  static Color iconBtnBg(Brightness b) =>
      b == Brightness.light ? const Color(0xFFF1F5F9) : const Color(0xFF28283A);

  /// Progress bar background.
  static Color progressBg(Brightness b) =>
      b == Brightness.light ? const Color(0xFFE2E8F0) : const Color(0xFF2A2A36);

  /// Fondo de info locked message.
  static Color lockedBg(Brightness b) =>
      b == Brightness.light ? const Color(0xFFF1F5F9) : const Color(0xFF22222C);

  /// Fondo de especialidad principal.
  static Color espPrincipalBg(Brightness b) =>
      b == Brightness.light ? const Color(0xFFFFF1EA) : const Color(0xFF3A2A22);

  /// Fondo de interes chip.
  static Color espInteresBg(Brightness b) =>
      b == Brightness.light ? const Color(0xFFF0F7FF) : const Color(0xFF1A2A3A);

  /// Fondo de chip disabled.
  static Color chipDisabledBg(Brightness b) =>
      b == Brightness.light ? const Color(0xFFF5F5F5) : const Color(0xFF22222C);

  /// Borde de chip disabled.
  static Color chipDisabledBorder(Brightness b) =>
      b == Brightness.light ? const Color(0xFFE0E0E0) : const Color(0xFF3A3A44);

  /// Texto disabled.
  static Color chipDisabledText(Brightness b) =>
      b == Brightness.light ? const Color(0xFFCCCCCC) : const Color(0xFF555566);

  /// Texto chip inactive.
  static Color chipInactiveText(Brightness b) =>
      b == Brightness.light ? const Color(0xFF555555) : const Color(0xFF9999AA);

  /// Fondo de bottom sheet.
  static Color sheetBg(Brightness b) =>
      b == Brightness.light ? Colors.white : const Color(0xFF1E1E24);

  /// Handle del bottom sheet.
  static Color sheetHandle(Brightness b) =>
      b == Brightness.light ? const Color(0xFFDDDDDD) : const Color(0xFF444450);

  /// Fondo de row no seleccionado en sheet.
  static Color sheetRowBg(Brightness b) =>
      b == Brightness.light ? const Color(0xFFFAFAFA) : const Color(0xFF22222C);

  /// Texto label "Carrera", "Principal", etc.
  static Color labelColor(Brightness b) =>
      b == Brightness.light ? const Color(0xFF777777) : const Color(0xFF9090A0);

  /// Fondo de external faculty badge en detail sheet.
  static Color externalBadgeBg(Brightness b) =>
      b == Brightness.light ? const Color(0xFFF0F4FF) : const Color(0xFF1E2A3A);

  /// Color del separador de malla.
  static Color dividerMalla(Brightness b) =>
      b == Brightness.light ? const Color(0xFFCBD5E1) : const Color(0xFF3A3A48);

  /// Color del specialty badge en detail sheet.
  static Color specialtyBg(Brightness b) =>
      b == Brightness.light ? const Color(0xFFFFE8DC) : const Color(0xFF3A2A22);

  /// Texto no seleccionado / sin especialización.
  static Color placeholderText(Brightness b) =>
      b == Brightness.light ? const Color(0xFFAAAAAA) : const Color(0xFF606070);

  /// Texto description en sheet.
  static Color descText(Brightness b) =>
      b == Brightness.light ? const Color(0xFF888888) : const Color(0xFF7A7A8A);

  // ── Chat de sección (HU23, RF-CHAT-8) ────────────────────────────────────

  /// Fondo de las burbujas propias del chat. Son los tonos de `specialtyBg`,
  /// pero con token propio para que un cambio en la malla no las toque. Con
  /// `textPrimary` da 15,16:1 en claro y 11,74:1 en oscuro.
  static Color chatOwnBubbleBg(Brightness b) =>
      b == Brightness.light ? const Color(0xFFFFE8DC) : const Color(0xFF3A2A22);

  /// Fondo de los avisos de error y de la acción «Eliminar» del chat, igual en
  /// los dos temas. Con texto blanco da 6,54:1.
  static Color errorBg(Brightness b) => const Color(0xFFB3261E);

  /// Naranja de un ícono informativo, que pide 3:1 contra su fondo. Va en
  /// `primaryDark` en claro y en `primaryColor` en oscuro, porque el
  /// `#FF6600` da 2,94:1 sobre blanco; con `cardBg` da 4,12:1 y 5,65:1.
  static Color iconoNaranja(Brightness b) =>
      b == Brightness.light ? primaryDark : primaryColor;

  // ── Test de especialidad (HU36, RF-TEST-12) ──────────────────────────────
  // Paleta de la maqueta `ulises-v2.html`, que ya llega al contraste pedido.
  // Las cifras de cada par están en la tabla de RF-TEST-12.

  /// Texto de la tarjeta apagada y de las opciones.
  static Color testInk2(Brightness b) =>
      b == Brightness.light ? const Color(0xFF334155) : const Color(0xFFCFCFDB);

  /// Texto secundario del test y de la tarjeta del Perfil.
  static Color testMuted(Brightness b) =>
      b == Brightness.light ? const Color(0xFF556070) : const Color(0xFFA5A5B5);

  /// Bordes de tarjetas y botones.
  static Color testLine(Brightness b) =>
      b == Brightness.light ? const Color(0xFFE2E8F0) : const Color(0xFF30303A);

  /// Pastilla del historial.
  static Color testChipBg(Brightness b) =>
      b == Brightness.light ? const Color(0xFFEEF2F7) : const Color(0xFF24242C);

  /// Fondo del botón principal y de la opción elegida.
  static Color testAccent(Brightness b) =>
      b == Brightness.light ? const Color(0xFFFF6600) : const Color(0xFFFF8C42);

  /// Tope del degradado del botón principal.
  static Color testAccentHi(Brightness b) =>
      b == Brightness.light ? const Color(0xFFFF7F24) : const Color(0xFFFF9D5C);

  /// Texto sobre `testAccent`.
  static Color testAccentInk(Brightness b) =>
      b == Brightness.light ? const Color(0xFF1A0E05) : const Color(0xFF16161C);

  /// Rótulos, botones secundarios y «Reintentar».
  static Color testAccentText(Brightness b) =>
      b == Brightness.light ? const Color(0xFFB84A00) : const Color(0xFFFF9A57);

  /// Texto sobre `testAccentSoft`.
  static Color testAccentDeep(Brightness b) =>
      b == Brightness.light ? const Color(0xFF7A3300) : const Color(0xFFFFC49A);

  /// Pastillas, sello y opción elegida.
  static Color testAccentSoft(Brightness b) =>
      b == Brightness.light ? const Color(0xFFFFF1E6) : const Color(0xFF3A2A22);

  /// Corazón sin marcar.
  static Color testHeartOff(Brightness b) =>
      b == Brightness.light ? const Color(0xFF64748B) : const Color(0xFF9A9AAC);

  /// Pista de las barras.
  static Color testTrack(Brightness b) =>
      b == Brightness.light ? const Color(0xFFE8EDF3) : const Color(0xFF2C2C36);

  /// Plumas llenas. En claro va en `#D45500` y no en el `#FF6600` de la
  /// maqueta, que da 2,81:1 (decisión abierta 15).
  static Color testFeatherOn(Brightness b) =>
      b == Brightness.light ? const Color(0xFFD45500) : const Color(0xFFFF8C42);

  /// Plumas vacías.
  static Color testFeatherOff(Brightness b) =>
      b == Brightness.light ? const Color(0xFFCBD5E1) : const Color(0xFF3A3A46);

  /// Baldosa del ícono de la tarea.
  static Color testTaskTileBg(Brightness b) =>
      b == Brightness.light ? const Color(0xFFF1F5F9) : const Color(0xFF25252D);

  /// Ícono de la tarea antes del toque y en la escala, y el ícono neutro.
  static Color testTaskIconInk(Brightness b) =>
      b == Brightness.light ? const Color(0xFF64748B) : const Color(0xFF8A8A9C);

  /// Fondo de la insignia «IA» de la tarjeta del resultado, que es `#140A50`
  /// al 38 % en claro, sobre el color de la ganadora, y `#16161C` en oscuro.
  static Color testAiBadgeBg(Brightness b) =>
      b == Brightness.light ? const Color(0x61140A50) : const Color(0xFF16161C);

  // LIGHT SCHEME
  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,

      primary: primaryColor,

      onPrimary: whiteColor,

      primaryContainer: primaryColor,

      onPrimaryContainer: blackColor,

      secondary: primaryDark,

      onSecondary: whiteColor,

      secondaryContainer: Color(0xFFFFD1B3),

      onSecondaryContainer: blackColor,

      tertiary: Color.fromARGB(255, 58, 58, 58),

      onTertiary: whiteColor,

      tertiaryContainer: Color(0xFFEAEAEA),

      onTertiaryContainer: blackColor,

      error: Colors.red,

      onError: whiteColor,

      surface: Color.fromARGB(255, 254, 253, 252),

      onSurface: blackColor,

      outline: Color(0xFFDADADA),

      shadow: Colors.black,

      inverseSurface: blackColor,

      onInverseSurface: whiteColor,

      inversePrimary: primaryDark,
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  // DARK SCHEME
  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,

      primary: primaryColor,

      onPrimary: whiteColor,

      primaryContainer: primaryDark,

      onPrimaryContainer: Color.fromARGB(255, 42, 42, 42),

      secondary: Color(0xFFFF8C42),

      onSecondary: blackColor,

      secondaryContainer: greyColor,

      onSecondaryContainer: whiteColor,

      tertiary: Color(0xFFBDBDBD),

      onTertiary: blackColor,

      tertiaryContainer: greyColor,

      onTertiaryContainer: whiteColor,

      error: Colors.red,

      onError: whiteColor,

      surface: Color.fromARGB(255, 30, 30, 36),

      onSurface: whiteColor,

      outline: Color(0xFF444444),

      shadow: Colors.black,

      inverseSurface: whiteColor,

      onInverseSurface: blackColor,

      inversePrimary: primaryDark,
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  ThemeData theme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,

      brightness: colorScheme.brightness,

      colorScheme: colorScheme,

      scaffoldBackgroundColor: colorScheme.surface,

      canvasColor: colorScheme.surface,

      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,

          foregroundColor: colorScheme.onPrimary,

          padding: const EdgeInsets.symmetric(vertical: 16),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: colorScheme.surface,

        elevation: 2,

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),

      textTheme: textTheme.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
    );
  }
}
