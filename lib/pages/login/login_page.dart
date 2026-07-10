import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../components/google_sign_in_button.dart';
import '../../configs/themes.dart';
import 'login_controller.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LoginController>();
    final palette = _LoginPalette.from(context);

    return Scaffold(
      backgroundColor: palette.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        // Login fijo: la tarjeta se centra y NO se puede arrastrar/rebotar
        // cuando cabe en pantalla (ClampingScrollPhysics evita el bounce de
        // iOS). Solo scrollea si el teclado reduce el alto por debajo del
        // contenido, para no cortar los campos en pantallas chicas.
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: Center(
                    child: _LoginCard(controller: controller, palette: palette),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({required this.controller, required this.palette});
  final LoginController controller;
  final _LoginPalette palette;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.cardBorder),
          boxShadow: [
            BoxShadow(
              color: palette.cardShadow,
              blurRadius: 32,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 40, 32, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: SvgPicture.asset(
                  'assets/images/Universidad_de_Lima_logo.svg',
                  width: 150,
                  colorMapper: palette.logoColorMapper,
                  semanticsLabel: 'Universidad de Lima',
                ),
              ),
              const SizedBox(height: 32),
              // Grupo: etiqueta a 8px de su campo, 20px entre grupos
              // (proximidad: cada etiqueta pertenece visualmente a SU campo).
              _FieldLabel(palette: palette, text: 'Código'),
              const SizedBox(height: 8),
              _BoxedField(
                controller: controller.codeController,
                palette: palette,
                // El alumno usa su código numérico y el docente/JP un usuario
                // alfanumérico (p.ej. "hquintan"), así que el teclado debe ser
                // de texto, no numérico.
                hint: 'Tu código o usuario',
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.username],
              ),
              const SizedBox(height: 20),
              _FieldLabel(palette: palette, text: 'Contraseña'),
              const SizedBox(height: 8),
              Obx(
                () => _BoxedField(
                  controller: controller.passwordController,
                  palette: palette,
                  hint: 'Tu contraseña',
                  obscureText: !controller.passwordVisible.value,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => controller.submit(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.passwordVisible.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: palette.fieldHint,
                    ),
                    onPressed: () => controller.passwordVisible.toggle(),
                    splashRadius: 18,
                  ),
                ),
              ),
              _ErrorMessage(controller: controller, palette: palette),
              const SizedBox(height: 28),
              _EntrarButton(controller: controller, palette: palette),
              const SizedBox(height: 10),
              _ForgotPasswordLink(palette: palette),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: Divider(color: palette.fieldLine)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'O inicia sesión con',
                      style: TextStyle(
                        color: palette.fieldHint,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: palette.fieldLine)),
                ],
              ),
              const SizedBox(height: 24),
              _GoogleButton(controller: controller, palette: palette),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.palette, required this.text});

  final _LoginPalette palette;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: palette.fieldText,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    );
  }
}

class _BoxedField extends StatelessWidget {
  const _BoxedField({
    required this.controller,
    required this.palette,
    required this.hint,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscureText = false,
    this.onSubmitted,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final _LoginPalette palette;
  final String hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onSubmitted: onSubmitted,
      cursorColor: palette.cursor,
      style: TextStyle(
        color: palette.fieldText,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: palette.fieldHint,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: palette.fieldFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.focusedFieldLine, width: 2),
        ),
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.controller, required this.palette});
  final LoginController controller;
  final _LoginPalette palette;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final msg = controller.errorMessage.value;
      if (msg == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          msg,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.error,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    });
  }
}

class _EntrarButton extends StatelessWidget {
  const _EntrarButton({required this.controller, required this.palette});
  final LoginController controller;
  final _LoginPalette palette;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: controller.submitting.value ? null : controller.submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: palette.buttonBackground,
            foregroundColor: palette.buttonForeground,
            disabledBackgroundColor: palette.disabledButtonBackground,
            disabledForegroundColor: palette.disabledButtonForeground,
            elevation: 0,
            padding: EdgeInsets.zero,
            side: palette.buttonSide,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: controller.submitting.value
              ? SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: palette.buttonForeground,
                    strokeWidth: 2.2,
                  ),
                )
              : Text(
                  'Entrar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}

class _ForgotPasswordLink extends StatelessWidget {
  const _ForgotPasswordLink({required this.palette});
  final _LoginPalette palette;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: () => Get.toNamed('/forgot-password'),
        style: TextButton.styleFrom(
          foregroundColor: palette.fieldHint,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text(
          '¿Olvidaste tu contraseña?',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.controller, required this.palette});
  final LoginController controller;
  final _LoginPalette palette;

  @override
  Widget build(BuildContext context) {
    // En web se usa el botón oficial de Google (GIS); signIn() no funciona en web.
    if (kIsWeb) {
      return Obx(
        () => SizedBox(
          height: 50,
          child: controller.submitting.value
              ? const Center(child: CircularProgressIndicator())
              : Center(child: googleSignInButton()),
        ),
      );
    }
    return Obx(
      () => SizedBox(
        height: 50,
        child: OutlinedButton(
          onPressed: controller.submitting.value ? null : controller.loginWithGoogle,
          style: OutlinedButton.styleFrom(
            backgroundColor: palette.card,
            foregroundColor: palette.fieldText,
            side: BorderSide(color: palette.fieldLine),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/images/google_logo.svg',
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Google',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginPalette {
  const _LoginPalette({
    required this.background,
    required this.card,
    required this.cardBorder,
    required this.cardShadow,
    required this.fieldText,
    required this.fieldHint,
    required this.fieldFill,
    required this.fieldLine,
    required this.focusedFieldLine,
    required this.cursor,
    required this.error,
    required this.buttonBackground,
    required this.buttonForeground,
    required this.disabledButtonBackground,
    required this.disabledButtonForeground,
    required this.buttonSide,
    this.logoColorMapper,
  });

  factory _LoginPalette.from(BuildContext context) {
    final isDark = Theme.brightnessOf(context) == Brightness.dark;

    if (isDark) {
      return const _LoginPalette(
        background: Color(0xFF262626),
        card: Color(0xFF050505),
        cardBorder: Color(0xFF262626),
        cardShadow: Color(0x99000000),
        fieldText: Color(0xFFF4F4F4),
        fieldHint: Color(0xFF9A9AA6),
        fieldFill: Color(0xFF2A2A36),
        fieldLine: Color(0xFFE7E7E7),
        focusedFieldLine: Color(0xFFFA7525),
        cursor: Color(0xFFFA7525),
        error: Color(0xFFFA7525),
        buttonBackground: Color(0x00000000),
        buttonForeground: Color(0xFFF4F4F4),
        disabledButtonBackground: Color(0x00000000),
        disabledButtonForeground: Color(0xFF8F8F8F),
        buttonSide: BorderSide(color: Color(0xFFE7E7E7), width: 1.5),
        logoColorMapper: _LogoTextColorMapper(Color(0xFFF4F4F4)),
      );
    }

    return const _LoginPalette(
      background: MaterialTheme.primaryColor,
      card: Colors.white,
      cardBorder: Colors.transparent,
      cardShadow: Color(0x33000000),
      fieldText: Color(0xFF1A1A1A),
      fieldHint: Color(0xFF9B9B9B),
      fieldFill: Color(0xFFF1F5F9),
      fieldLine: Color(0xFFCFCFCF),
      focusedFieldLine: MaterialTheme.primaryColor,
      cursor: MaterialTheme.primaryColor,
      error: MaterialTheme.primaryDark,
      buttonBackground: MaterialTheme.primaryColor,
      buttonForeground: Colors.white,
      disabledButtonBackground: Color(0x99FF6600),
      disabledButtonForeground: Colors.white,
      buttonSide: BorderSide.none,
    );
  }

  final Color background;
  final Color card;
  final Color cardBorder;
  final Color cardShadow;
  final Color fieldText;
  final Color fieldHint;
  final Color fieldFill;
  final Color fieldLine;
  final Color focusedFieldLine;
  final Color cursor;
  final Color error;
  final Color buttonBackground;
  final Color buttonForeground;
  final Color disabledButtonBackground;
  final Color disabledButtonForeground;
  final BorderSide buttonSide;
  final ColorMapper? logoColorMapper;
}

class _LogoTextColorMapper extends ColorMapper {
  const _LogoTextColorMapper(this.textColor);

  final Color textColor;

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    if (color == Colors.black || color == const Color(0xFF000000)) {
      return textColor;
    }

    return color;
  }

  @override
  bool operator ==(Object other) {
    return other is _LogoTextColorMapper && other.textColor == textColor;
  }

  @override
  int get hashCode => textColor.hashCode;
}
