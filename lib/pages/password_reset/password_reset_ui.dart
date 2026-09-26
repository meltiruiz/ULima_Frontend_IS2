// lib/pages/password_reset/password_reset_ui.dart
// Paleta y widgets compartidos por las pantallas del flujo de recuperación
// de contraseña. Replica el estilo visual de la pantalla de login
// (card centrada, campos en caja y soporte de dark mode).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show FilteringTextInputFormatter, SystemUiOverlayStyle, TextInputFormatter;

import '../../components/logo/sello_del_logo.dart';
import '../../configs/themes.dart';
import 'password_reset_validators.dart';

class PasswordResetPalette {
  const PasswordResetPalette({
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
    required this.backIcon,
  });

  factory PasswordResetPalette.from(BuildContext context) {
    final isDark = Theme.brightnessOf(context) == Brightness.dark;

    if (isDark) {
      return const PasswordResetPalette(
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
        backIcon: Color(0xFFF4F4F4),
      );
    }

    return const PasswordResetPalette(
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
      backIcon: Colors.white,
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
  final Color backIcon;
}

/// Scaffold común del flujo: fondo, flecha de retorno y card centrada. Con
/// [conSello], la cabecera lleva el sello del logo en el mismo lugar que la
/// franja de la bienvenida, y la tarjeta queda bajo ella (RF-BIEN-20).
class PasswordResetScaffold extends StatelessWidget {
  const PasswordResetScaffold({
    super.key,
    required this.palette,
    required this.child,
    this.conSello = false,
  });

  final PasswordResetPalette palette;
  final Widget child;

  /// Lo encienden solo `/forgot-password` y `/reset-password`. Portal Sync
  /// no lo enciende y no cambia.
  final bool conSello;

  Widget _tarjeta() => SingleChildScrollView(
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    child: ConstrainedBox(
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
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 36, 32, 32),
          child: child,
        ),
      ),
    ),
  );

  Widget _flecha(BuildContext context) => IconButton(
    icon: Icon(Icons.arrow_back, color: palette.backIcon),
    tooltip: 'Volver',
    onPressed: () => Navigator.of(context).maybePop(),
  );

  @override
  Widget build(BuildContext context) {
    if (!conSello) {
      return Scaffold(
        backgroundColor: palette.background,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Stack(
            children: [
              Center(child: _tarjeta()),
              Positioned(top: 4, left: 4, child: _flecha(context)),
            ],
          ),
        ),
      );
    }
    // Íconos claros, porque arriba siempre hay #FF6600 o #262626.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: palette.background,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            Column(
              children: [
                // Sin color propio, porque el fondo ya es el de la franja.
                const CabeceraConSello(),
                Expanded(
                  child: SafeArea(top: false, child: Center(child: _tarjeta())),
                ),
              ],
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: _flecha(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Etiqueta de un grupo label+campo. Va a 8px de SU campo (proximidad).
class PasswordResetFieldLabel extends StatelessWidget {
  const PasswordResetFieldLabel({
    super.key,
    required this.palette,
    required this.text,
  });

  final PasswordResetPalette palette;
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

/// Campo de texto en caja (filled, 12px de radio, borde naranja al enfocar)
/// con el mismo estilo del login.
class PasswordResetField extends StatelessWidget {
  const PasswordResetField({
    super.key,
    required this.controller,
    required this.palette,
    required this.hint,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.obscureText = false,
    this.onSubmitted,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final PasswordResetPalette palette;
  final String hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
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
      inputFormatters: inputFormatters,
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

/// Código OTP en casillas individuales: un TextField oculto conserva el
/// teclado numérico, el pegado y el TextEditingController del GetX
/// controller; las casillas solo pintan los dígitos del valor actual.
class PasswordResetOtpField extends StatefulWidget {
  const PasswordResetOtpField({
    super.key,
    required this.controller,
    required this.palette,
    this.length = passwordResetCodeLength,
    this.boxHeight = 52,
    this.boxFill,
    this.idleBorderColor = Colors.transparent,
    this.readOnly = false,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final PasswordResetPalette palette;
  final int length;

  /// Alto de cada casilla. La hoja de recarga desde la ULima usa 50 (RF-RCG-2).
  final double boxHeight;

  /// Relleno de cada casilla. Con `null` usa `palette.fieldFill`.
  final Color? boxFill;

  /// Borde de las casillas que no tienen el foco, de 1 de ancho. Con el
  /// transparente de siempre no se ve (D13 de la recarga).
  final Color idleBorderColor;

  /// Durante la espera de la recarga, las casillas no se enfocan ni se editan.
  final bool readOnly;

  /// Toma el foco al montarse, como los campos de la bienvenida (RF-BIEN-5).
  final bool autofocus;

  @override
  State<PasswordResetOtpField> createState() => _PasswordResetOtpFieldState();
}

class _PasswordResetOtpFieldState extends State<PasswordResetOtpField> {
  final FocusNode _focusNode = FocusNode();

  /// Último texto pintado. Sirve para ignorar las notificaciones de sólo
  /// selección y no reconstruir las seis casillas por cada evento del canal.
  String _paintedText = '';

  @override
  void initState() {
    super.initState();
    _paintedText = widget.controller.text;
    widget.controller.addListener(_handleValueChanged);
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant PasswordResetOtpField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si el padre reconstruye con otro TextEditingController, re-vincular el
    // listener para que las casillas sigan reflejando el texto actual.
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleValueChanged);
      widget.controller.addListener(_handleValueChanged);
      _paintedText = widget.controller.text;
    }
    if (widget.readOnly && !oldWidget.readOnly) _focusNode.unfocus();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleValueChanged);
    _focusNode.dispose();
    super.dispose();
  }

  /// NUNCA escribe en el controller.
  ///
  /// La versión anterior forzaba aquí `controller.selection`. Toda escritura
  /// desde un listener del propio controller es una notificación re-entrante
  /// que acaba en `EditableText._updateRemoteEditingValueIfNeeded()` →
  /// `TextInput.setEditingState`: el framework contradiciendo al IME de iOS de
  /// forma asíncrona. Eso deja dos escritores del mismo texto sin número de
  /// secuencia, y es lo que hacía que el retroceso no borrara nada con el
  /// campo lleno (2026-09-07, iPhone SE).
  ///
  /// Además era innecesario: con `fontSize: 1` el texto mide unos 3 px pegados
  /// al borde de un campo de ~300, así que cualquier toque cae más allá del
  /// final y iOS ya pone el caret en `text.length` por su cuenta.
  void _handleValueChanged() {
    final text = widget.controller.text;
    if (text == _paintedText) return; // sólo cambió la selección
    _paintedText = text;
    if (mounted) setState(() {});
  }

  void _handleFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final raw = widget.controller.text;
    final text = raw.length > widget.length ? raw.substring(0, widget.length) : raw;
    // -1 cuando está lleno: ninguna casilla queda resaltada, en vez de dejar el
    // borde clavado en la sexta como si nada hubiera cambiado desde el quinto
    // dígito. Esa señal congelada es la mitad de «parece que cada uno de los
    // cuadros fuera uno solo».
    final activeIndex = text.length < widget.length ? text.length : -1;

    return Stack(
      children: [
        Row(
          children: [
            for (var i = 0; i < widget.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _OtpBox(
                  palette: widget.palette,
                  digit: i < text.length ? text[i] : '',
                  active: _focusNode.hasFocus && i == activeIndex,
                  height: widget.boxHeight,
                  fill: widget.boxFill ?? widget.palette.fieldFill,
                  idleBorderColor: widget.idleBorderColor,
                ),
              ),
            ],
          ],
        ),
        // TextField invisible extendido sobre las casillas: tocar cualquiera
        // lo enfoca, y una pulsación larga permite pegar el código completo.
        Positioned.fill(
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            autofocus: widget.autofocus && !widget.readOnly,
            readOnly: widget.readOnly,
            canRequestFocus: !widget.readOnly,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.oneTimeCode],
            // SIN LengthLimitingTextInputFormatter: en iOS su modo por
            // defecto (`truncateAfterCompositionEnds`) devuelve el valor VIEJO
            // cuando el campo ya está lleno, y esa divergencia entre lo que
            // sabe Dart y lo que sabe el IME es la causa del bug de borrado.
            // `digitsOnly` sí es seguro: con dígitos puros es la identidad.
            // El recorte a `length` se hace al pintar y al leer.
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            // Invisible, pero con geometría real: `cursorWidth: 0` le reporta a
            // UIKit un caret degenerado vía `setCaretRect`.
            cursorColor: Colors.transparent,
            style: const TextStyle(color: Colors.transparent, fontSize: 1),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isCollapsed: true,
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.palette,
    required this.digit,
    required this.active,
    required this.height,
    required this.fill,
    required this.idleBorderColor,
  });

  final PasswordResetPalette palette;
  final String digit;
  final bool active;
  final double height;
  final Color fill;
  final Color idleBorderColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(12),
        // En reposo, el transparente de siempre conserva el ancho de 2, así
        // que las pantallas de hoy no se mueven ni un píxel. Un borde visible
        // en reposo va de 1 (D13 de la recarga).
        border: active
            ? Border.all(color: palette.focusedFieldLine, width: 2)
            : Border.all(
                color: idleBorderColor,
                width: idleBorderColor == Colors.transparent ? 2 : 1,
              ),
      ),
      child: Text(
        digit,
        style: TextStyle(
          color: palette.fieldText,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Botón principal del flujo, con spinner mientras se envía la solicitud.
class PasswordResetPrimaryButton extends StatelessWidget {
  const PasswordResetPrimaryButton({
    super.key,
    required this.palette,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final PasswordResetPalette palette;
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
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
        child: loading
            ? SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: palette.buttonForeground,
                  strokeWidth: 2.2,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}

/// Mensaje de error centrado bajo los campos, estilo login.
class PasswordResetErrorMessage extends StatelessWidget {
  const PasswordResetErrorMessage({
    super.key,
    required this.palette,
    required this.message,
  });

  final PasswordResetPalette palette;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final msg = message;
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
  }
}
