// lib/pages/bienvenida/widgets/compositor.dart
// El compositor de la conversación y sus piezas (RF-BIEN-5 y RF-BIEN-16).
// Va fijo abajo, sobre el teclado, mide hasta el 60 % del alto disponible y
// desplaza por dentro si su contenido es más alto. Todo control mide al
// menos 48 dp de alto.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../components/google_sign_in_button.dart';
import '../../../configs/themes.dart';
import '../../../domain/bienvenida/bienvenida_turnos.dart';
import '../../password_reset/password_reset_ui.dart';
import '../bienvenida_controller.dart';
import 'anillo_de_foco.dart';
import 'compositor_del_test.dart';

typedef _Textos = TextosDeLaBienvenida;

class MarcoDelCompositor extends StatelessWidget {
  const MarcoDelCompositor({
    super.key,
    required this.child,
    required this.altoDisponible,
  });

  final Widget child;

  /// El alto de la página sobre el teclado. El Scaffold ya descuenta el
  /// teclado de su cuerpo, así que su MediaQuery no lo trae y la página lo
  /// mide con su LayoutBuilder.
  final double altoDisponible;

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);
    final mq = MediaQuery.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: MaterialTheme.cardBg(b),
        border: Border(top: BorderSide(color: MaterialTheme.testLine(b))),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: altoDisponible * 0.6),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            12,
            10,
            12,
            24 + (mq.viewInsets.bottom > 0 ? 0 : mq.padding.bottom),
          ),
          child: child,
        ),
      ),
    );
  }
}

class RotuloDelCampo extends StatelessWidget {
  const RotuloDelCampo(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text(
      texto,
      style: TextStyle(
        color: MaterialTheme.testInk2(Theme.brightnessOf(context)),
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class CampoDelCompositor extends StatelessWidget {
  const CampoDelCompositor({
    super.key,
    required this.controlador,
    required this.pista,
    this.oculto = false,
    this.teclado = TextInputType.text,
    this.accion = TextInputAction.done,
    this.pistasDeAutocompletado,
    this.alEnviar,
    this.sufijo,
    this.autofocus = true,
    this.focusNode,
  });

  final TextEditingController controlador;
  final String pista;
  final bool oculto;
  final TextInputType teclado;
  final TextInputAction accion;
  final Iterable<String>? pistasDeAutocompletado;
  final ValueChanged<String>? alEnviar;
  final Widget? sufijo;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);
    // Con lector de pantalla el campo no toma el foco solo (RF-BIEN-16).
    final lector = MediaQuery.accessibleNavigationOf(context);
    final borde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: TextField(
        controller: controlador,
        focusNode: focusNode,
        autofocus: autofocus && !lector,
        obscureText: oculto,
        keyboardType: teclado,
        textInputAction: accion,
        autofillHints: pistasDeAutocompletado,
        onSubmitted: alEnviar,
        style: TextStyle(color: MaterialTheme.textPrimary(b), fontSize: 15),
        decoration: InputDecoration(
          hintText: pista,
          hintStyle: TextStyle(color: MaterialTheme.testMuted(b), fontSize: 15),
          filled: true,
          // Con foco, fondo cardBg (RF-BIEN-5). InputDecorator resuelve el
          // relleno con el estado del foco, y focusColor no lo cambia.
          fillColor: WidgetStateColor.resolveWith(
            (estados) => estados.contains(WidgetState.focused)
                ? MaterialTheme.cardBg(b)
                : MaterialTheme.testChipBg(b),
          ),
          suffixIcon: sufijo,
          border: borde,
          enabledBorder: borde,
          focusedBorder: borde.copyWith(
            borderSide: BorderSide(
              color: MaterialTheme.bienvenidaFoco(b),
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class BotonDeEnvio extends StatelessWidget {
  const BotonDeEnvio({super.key, required this.alTocar});

  /// Null mientras el campo está vacío, y el botón queda al 40 %.
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);
    return AnilloDeFoco(
      radio: BorderRadius.circular(24),
      child: Semantics(
        button: true,
        onTap: alTocar,
        enabled: alTocar != null,
        label: _Textos.enviar,
        excludeSemantics: true,
        child: Opacity(
          opacity: alTocar == null ? 0.4 : 1,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: alTocar,
              child: Ink(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      MaterialTheme.testAccentHi(b),
                      MaterialTheme.testAccent(b),
                    ],
                  ),
                ),
                child: Icon(
                  LucideIcons.arrowUp,
                  color: MaterialTheme.testAccentInk(b),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OjoDeLaContrasena extends StatelessWidget {
  const OjoDeLaContrasena({
    super.key,
    required this.visible,
    required this.alTocar,
  });

  final bool visible;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => AnilloDeFoco(
    radio: BorderRadius.circular(24),
    child: Semantics(
      button: true,
      onTap: alTocar,
      toggled: visible,
      label: visible ? _Textos.ocultarContrasena : _Textos.mostrarContrasena,
      excludeSemantics: true,
      child: IconButton(
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        onPressed: alTocar,
        icon: Icon(
          visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 20,
          color: MaterialTheme.testMuted(Theme.brightnessOf(context)),
        ),
      ),
    ),
  );
}

/// Una respuesta rápida, en píldora. La principal va rellena.
class RespuestaRapida extends StatelessWidget {
  const RespuestaRapida({
    super.key,
    required this.texto,
    required this.alTocar,
    this.principal = false,
    this.esperando = false,
  });

  final String texto;
  final VoidCallback? alTocar;
  final bool principal;
  final bool esperando;

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);
    return AnilloDeFoco(
      radio: BorderRadius.circular(999),
      child: Semantics(
        button: true,
        onTap: esperando ? null : alTocar,
        label: texto,
        excludeSemantics: true,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: esperando ? null : alTocar,
            child: Ink(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: principal
                    ? null
                    : Border.all(
                        color: MaterialTheme.testAccent(b),
                        width: 1.5,
                      ),
                gradient: principal
                    ? LinearGradient(
                        colors: [
                          MaterialTheme.testAccentHi(b),
                          MaterialTheme.testAccent(b),
                        ],
                      )
                    : null,
              ),
              child: Center(
                widthFactor: 1,
                child: esperando
                    ? SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          // Sin movimiento no gira (RF-BIEN-15).
                          value: MediaQuery.disableAnimationsOf(context)
                              ? 0.75
                              : null,
                          strokeWidth: 2,
                          color: MaterialTheme.testAccentInk(b),
                        ),
                      )
                    : Text(
                        texto,
                        style: TextStyle(
                          color: principal
                              ? MaterialTheme.testAccentInk(b)
                              : MaterialTheme.testAccentText(b),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
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

class RespuestasRapidas extends StatelessWidget {
  const RespuestasRapidas({super.key, required this.respuestas});

  final List<RespuestaRapida> respuestas;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.end,
    spacing: 8,
    runSpacing: 8,
    children: respuestas,
  );
}

class BotonPrincipal extends StatelessWidget {
  const BotonPrincipal({
    super.key,
    required this.texto,
    required this.alTocar,
    this.esperando = false,
  });

  final String texto;
  final VoidCallback? alTocar;
  final bool esperando;

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);
    final activo = alTocar != null && !esperando;
    return AnilloDeFoco(
      radio: BorderRadius.circular(15),
      child: Semantics(
        button: true,
        onTap: activo ? alTocar : null,
        enabled: activo,
        label: texto,
        excludeSemantics: true,
        child: Opacity(
          opacity: alTocar == null ? 0.4 : 1,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: activo ? alTocar : null,
              child: Ink(
                height: 48,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    colors: [
                      MaterialTheme.testAccentHi(b),
                      MaterialTheme.testAccent(b),
                    ],
                  ),
                ),
                child: Center(
                  child: esperando
                      ? SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            // Sin movimiento no gira (RF-BIEN-15).
                            value: MediaQuery.disableAnimationsOf(context)
                                ? 0.75
                                : null,
                            strokeWidth: 2,
                            color: MaterialTheme.testAccentInk(b),
                          ),
                        )
                      : Text(
                          texto,
                          style: TextStyle(
                            color: MaterialTheme.testAccentInk(b),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
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

class EnlaceSecundario extends StatelessWidget {
  const EnlaceSecundario({
    super.key,
    required this.texto,
    required this.alTocar,
    this.apagado = false,
  });

  final String texto;
  final VoidCallback? alTocar;

  /// «¿Olvidaste tu contraseña?» va en testMuted, como en la maqueta.
  final bool apagado;

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);
    return AnilloDeFoco(
      radio: BorderRadius.circular(8),
      child: Semantics(
        button: true,
        onTap: alTocar,
        label: texto,
        excludeSemantics: true,
        child: InkWell(
          onTap: alTocar,
          child: SizedBox(
            height: 48,
            child: Center(
              widthFactor: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  texto,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: apagado
                        ? MaterialTheme.testMuted(b)
                        : MaterialTheme.testAccentText(b),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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

class ErrorLocal extends StatelessWidget {
  const ErrorLocal(this.mensaje, {super.key});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final color = MaterialTheme.testAccentText(Theme.brightnessOf(context));
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Icon(LucideIcons.circleAlert, size: 14, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                mensaje,
                style: TextStyle(color: color, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// «Continuar con Google» en Android e iOS, con el logo oficial y los
/// colores de la marca de Google (RF-BIEN-6).
class BotonDeGoogle extends StatelessWidget {
  const BotonDeGoogle({super.key, required this.alTocar});

  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);
    return AnilloDeFoco(
      radio: BorderRadius.circular(12),
      child: Semantics(
        button: true,
        onTap: alTocar,
        label: _Textos.continuarConGoogle,
        excludeSemantics: true,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: alTocar,
            child: Ink(
              decoration: BoxDecoration(
                color: MaterialTheme.bienvenidaGoogleFondo(b),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: MaterialTheme.bienvenidaGoogleBorde(b),
                ),
              ),
              // 48 dp de alto, que crecen con el texto grande en lugar de
              // desbordar (RF-BIEN-16).
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 46),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/images/google_logo.svg',
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          _Textos.continuarConGoogle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: MaterialTheme.bienvenidaGoogleTinta(b),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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

/// Un campo con su botón de envío a la derecha.
class _CampoConEnvio extends StatelessWidget {
  const _CampoConEnvio({required this.campo, required this.alEnviar});

  final Widget campo;
  final VoidCallback? alEnviar;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: campo),
      const SizedBox(width: 8),
      BotonDeEnvio(alTocar: alEnviar),
    ],
  );
}

/// El campo con el texto que el botón de envío escucha.
class _AlEscribir extends StatelessWidget {
  const _AlEscribir({required this.controlador, required this.builder});

  final TextEditingController controlador;
  final Widget Function(BuildContext context, bool vacio) builder;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: controlador,
        builder: (context, valor, _) =>
            builder(context, valor.text.trim().isEmpty),
      );
}

class _E1 extends StatelessWidget {
  const _E1({required this.c});

  final BienvenidaController c;

  @override
  Widget build(BuildContext context) {
    final login = c.login;
    final b = Theme.brightnessOf(context);
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const RotuloDelCampo(_Textos.rotuloCodigo),
          _AlEscribir(
            controlador: login.codeController,
            builder: (context, vacio) => _CampoConEnvio(
              campo: CampoDelCompositor(
                controlador: login.codeController,
                pista: _Textos.pistaCodigo,
                accion: TextInputAction.next,
                pistasDeAutocompletado: const [AutofillHints.username],
                alEnviar: (_) => c.enviarCodigo(),
              ),
              alEnviar: vacio || c.esperando.value ? null : c.enviarCodigo,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Divider(color: MaterialTheme.testLine(b))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  _Textos.separadorO,
                  style: TextStyle(color: MaterialTheme.testMuted(b)),
                ),
              ),
              Expanded(child: Divider(color: MaterialTheme.testLine(b))),
            ],
          ),
          const SizedBox(height: 10),
          // En web, signIn() no funciona con google_sign_in 6.x, así que va
          // el botón oficial, con el ancho del compositor hasta 400 px y el
          // tema del sistema, y la cuenta llega por onCurrentUserChanged.
          if (kIsWeb)
            LayoutBuilder(
              builder: (context, limites) => Center(
                child: googleSignInButton(
                  configuracion: configuracionDelBotonDeGoogle(
                    oscuro: Theme.brightnessOf(context) == Brightness.dark,
                    anchoDelCompositor: limites.maxWidth,
                  ),
                ),
              ),
            )
          else
            BotonDeGoogle(
              alTocar: c.esperando.value ? null : c.entrarConGoogle,
            ),
          EnlaceSecundario(texto: _Textos.soyNuevo, alTocar: c.soyNuevo),
        ],
      ),
    );
  }
}

class _E2 extends StatelessWidget {
  const _E2({required this.c});

  final BienvenidaController c;

  @override
  Widget build(BuildContext context) {
    final login = c.login;
    return Obx(() {
      // Se lee aquí, en el alcance del Obx, y no dentro del builder del
      // botón, que se construye aparte.
      final esperando = c.esperando.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // El campo de E1 sigue montado en el grupo del autocompletado,
          // invisible y fuera de la semántica y del foco, para que el llavero
          // de iOS y el gestor de contraseñas de Google emparejen el usuario
          // con la contraseña (RF-BIEN-6).
          ExcludeFocus(
            child: Offstage(
              child: CampoDelCompositor(
                controlador: login.codeController,
                pista: _Textos.pistaCodigo,
                pistasDeAutocompletado: const [AutofillHints.username],
                autofocus: false,
              ),
            ),
          ),
          const RotuloDelCampo(_Textos.rotuloContrasena),
          CampoDelCompositor(
            controlador: login.passwordController,
            pista: _Textos.pistaContrasena,
            oculto: !login.passwordVisible.value,
            pistasDeAutocompletado: const [AutofillHints.password],
            alEnviar: (_) => c.entrar(),
            sufijo: OjoDeLaContrasena(
              visible: login.passwordVisible.value,
              alTocar: login.passwordVisible.toggle,
            ),
          ),
          const SizedBox(height: 10),
          _AlEscribir(
            controlador: login.passwordController,
            builder: (context, vacio) => BotonPrincipal(
              texto: _Textos.entrar,
              esperando: esperando,
              alTocar: vacio ? null : c.entrar,
            ),
          ),
          EnlaceSecundario(
            texto: _Textos.olvidaste,
            alTocar: c.abrirOlvido,
            apagado: true,
          ),
          EnlaceSecundario(texto: _Textos.soyNuevo, alTocar: c.soyNuevo),
        ],
      );
    });
  }
}

/// El compositor de cada turno. Null en los turnos sin compositor.
Widget? compositorDelTurno(
  BuildContext context,
  BienvenidaController c,
  TurnoDeLaBienvenida turno,
) => switch (turno) {
  TurnoDeLaBienvenida.e1Codigo => _E1(c: c),
  TurnoDeLaBienvenida.e2Contrasena => _E2(c: c),
  TurnoDeLaBienvenida.n1Codigo => _N1(c: c),
  TurnoDeLaBienvenida.n2Contrasena => _N2(c: c),
  TurnoDeLaBienvenida.n3Consentimiento => _N3(c: c),
  TurnoDeLaBienvenida.n4Portal => _N4(c: c),
  TurnoDeLaBienvenida.n5Authenticator => _N5(c: c),
  TurnoDeLaBienvenida.incierto => _Incierto(c: c),
  TurnoDeLaBienvenida.t0Invitacion ||
  TurnoDeLaBienvenida.pregunta ||
  TurnoDeLaBienvenida.desempate ||
  TurnoDeLaBienvenida.espera ||
  TurnoDeLaBienvenida.resultado => CompositorDelTest(c: c, turno: turno),
  TurnoDeLaBienvenida.seleccionManual => SeleccionManual(c: c),
  // «Si no cabe», Ulises saluda ya en la conversación y la pregunta queda
  // con sus respuestas rápidas (B-28).
  TurnoDeLaBienvenida.recibimiento when c.saludoEnLaConversacion.value =>
    RespuestasRapidas(
      respuestas: [
        RespuestaRapida(
          texto: _Textos.siEntrar,
          principal: true,
          alTocar: () => c.responderAlSaludo(yaUsa: true),
        ),
        RespuestaRapida(
          texto: _Textos.soyNuevo,
          alTocar: () => c.responderAlSaludo(yaUsa: false),
        ),
      ],
    ),
  TurnoDeLaBienvenida.recibimiento ||
  TurnoDeLaBienvenida.llegadaConSesion ||
  TurnoDeLaBienvenida.e3Despedida ||
  TurnoDeLaBienvenida.envio ||
  TurnoDeLaBienvenida.pasoAlHorario => null,
};

/// Los enlaces que el registro deja fijos antes del envío (RF-BIEN-9).
class _EnlacesDelRegistro extends StatelessWidget {
  const _EnlacesDelRegistro({required this.c, this.conVolver = true});

  final BienvenidaController c;
  final bool conVolver;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 8,
    children: [
      if (conVolver) EnlaceSecundario(texto: _Textos.volver, alTocar: c.volver),
      EnlaceSecundario(texto: _Textos.yaTengoCuenta, alTocar: c.yaTengoCuenta),
    ],
  );
}

/// Un turno con campo. El error local de la validación va bajo el campo, y
/// después los botones y los enlaces (RF-BIEN-5).
class _ConError extends StatelessWidget {
  const _ConError({
    required this.c,
    required this.campo,
    this.despues = const <Widget>[],
  });

  final BienvenidaController c;

  /// El rótulo y el campo, hasta el que lleva el error debajo.
  final List<Widget> campo;
  final List<Widget> despues;

  @override
  Widget build(BuildContext context) => Obx(
    () => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...campo,
        if (c.errorLocal.value != null) ErrorLocal(c.errorLocal.value!),
        ...despues,
      ],
    ),
  );
}

class _N1 extends StatelessWidget {
  const _N1({required this.c});

  final BienvenidaController c;

  @override
  Widget build(BuildContext context) {
    final r = c.registro!;
    return _ConError(
      c: c,
      campo: [
        const RotuloDelCampo(_Textos.rotuloCodigoDeAlumno),
        _AlEscribir(
          controlador: r.codigoCtrl,
          builder: (context, vacio) => _CampoConEnvio(
            campo: CampoDelCompositor(
              controlador: r.codigoCtrl,
              pista: _Textos.pistaCodigoDeAlumno,
              teclado: TextInputType.number,
              alEnviar: (_) => c.enviarCodigoDeAlumno(),
            ),
            alEnviar: vacio ? null : c.enviarCodigoDeAlumno,
          ),
        ),
      ],
      despues: [_EnlacesDelRegistro(c: c, conVolver: false)],
    );
  }
}

class _N2 extends StatefulWidget {
  const _N2({required this.c});

  final BienvenidaController c;

  @override
  State<_N2> createState() => _N2State();
}

class _N2State extends State<_N2> {
  /// «Siguiente» del teclado pasa de «Contraseña» a «Repetir contraseña»
  /// (RF-BIEN-5).
  final FocusNode _repetir = FocusNode(debugLabel: 'repetir');

  @override
  void dispose() {
    _repetir.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final r = c.registro!;
    return Obx(() {
      // Se lee aquí, en el alcance del Obx, y no dentro del builder del
      // campo, que se construye aparte.
      final visible = r.passwordVisible.value;
      return _ConError(
        c: c,
        campo: [
          const RotuloDelCampo(_Textos.rotuloContrasena),
          CampoDelCompositor(
            controlador: r.passwordCtrl,
            pista: _Textos.pistaNueva,
            oculto: !visible,
            accion: TextInputAction.next,
            pistasDeAutocompletado: const [AutofillHints.newPassword],
            alEnviar: (_) => _repetir.requestFocus(),
            sufijo: OjoDeLaContrasena(
              visible: visible,
              alTocar: r.passwordVisible.toggle,
            ),
          ),
          const SizedBox(height: 10),
          const RotuloDelCampo(_Textos.rotuloRepetir),
          _AlEscribir(
            controlador: r.confirmacionCtrl,
            builder: (context, vacio) => _CampoConEnvio(
              campo: CampoDelCompositor(
                controlador: r.confirmacionCtrl,
                pista: _Textos.pistaRepetir,
                oculto: !visible,
                autofocus: false,
                focusNode: _repetir,
                alEnviar: (_) => c.enviarContrasenas(),
              ),
              alEnviar: vacio ? null : c.enviarContrasenas,
            ),
          ),
        ],
        despues: [_EnlacesDelRegistro(c: c)],
      );
    });
  }
}

class _N3 extends StatelessWidget {
  const _N3({required this.c});

  final BienvenidaController c;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      RespuestasRapidas(
        respuestas: [
          RespuestaRapida(texto: _Textos.volver, alTocar: c.volver),
          RespuestaRapida(
            texto: _Textos.acepto,
            alTocar: c.aceptarConsentimiento,
            principal: true,
          ),
        ],
      ),
      _EnlacesDelRegistro(c: c, conVolver: false),
    ],
  );
}

class _N4 extends StatelessWidget {
  const _N4({required this.c});

  final BienvenidaController c;

  @override
  Widget build(BuildContext context) {
    final r = c.registro!;
    return Obx(() {
      // Se lee aquí, en el alcance del Obx, y no dentro del builder del
      // campo, que se construye aparte.
      final visible = r.portalPasswordVisible.value;
      return _ConError(
        c: c,
        campo: [
          const RotuloDelCampo(_Textos.rotuloPortal),
          _AlEscribir(
            controlador: r.portalPasswordCtrl,
            builder: (context, vacio) => _CampoConEnvio(
              campo: CampoDelCompositor(
                controlador: r.portalPasswordCtrl,
                pista: _Textos.pistaPortal,
                oculto: !visible,
                alEnviar: (_) => c.enviarPortal(),
                sufijo: OjoDeLaContrasena(
                  visible: visible,
                  alTocar: r.portalPasswordVisible.toggle,
                ),
              ),
              alEnviar: vacio ? null : c.enviarPortal,
            ),
          ),
        ],
        despues: [_EnlacesDelRegistro(c: c)],
      );
    });
  }
}

class _N5 extends StatelessWidget {
  const _N5({required this.c});

  final BienvenidaController c;

  @override
  Widget build(BuildContext context) {
    final r = c.registro!;
    final b = Theme.brightnessOf(context);
    return _ConError(
      c: c,
      campo: [
        const RotuloDelCampo(_Textos.rotuloAuthenticator),
        // El campo de seis casillas de hoy (RF-BIEN-7), que toma el foco como
        // todo campo del compositor, salvo con lector (RF-BIEN-5 y
        // RF-BIEN-16), con los colores de la conversación (RF-BIEN-14).
        PasswordResetOtpField(
          controller: r.passcodeCtrl,
          palette: _paletaDeLasCasillas(context),
          autofocus: !MediaQuery.accessibleNavigationOf(context),
        ),
      ],
      despues: [
        const SizedBox(height: 6),
        Text(
          _Textos.notaAuthenticator,
          style: TextStyle(color: MaterialTheme.testMuted(b), fontSize: 12),
        ),
        const SizedBox(height: 10),
        _AlEscribir(
          controlador: r.passcodeCtrl,
          builder: (context, vacio) => BotonPrincipal(
            texto: _Textos.crearMiCuenta,
            alTocar: vacio ? null : c.crearCuenta,
          ),
        ),
        _EnlacesDelRegistro(c: c),
      ],
    );
  }
}

/// La paleta de las casillas de N5, con el relleno, el texto y el borde de
/// foco de los campos del compositor (RF-BIEN-5 y RF-BIEN-14). Lo demás es lo
/// de las pantallas de la contraseña, que las casillas no usan.
PasswordResetPalette _paletaDeLasCasillas(BuildContext context) {
  final b = Theme.brightnessOf(context);
  final base = PasswordResetPalette.from(context);
  return PasswordResetPalette(
    background: base.background,
    card: base.card,
    cardBorder: base.cardBorder,
    cardShadow: base.cardShadow,
    fieldText: MaterialTheme.textPrimary(b),
    fieldHint: MaterialTheme.testMuted(b),
    fieldFill: MaterialTheme.testChipBg(b),
    fieldLine: base.fieldLine,
    focusedFieldLine: MaterialTheme.bienvenidaFoco(b),
    cursor: MaterialTheme.bienvenidaFoco(b),
    error: base.error,
    buttonBackground: base.buttonBackground,
    buttonForeground: base.buttonForeground,
    disabledButtonBackground: base.disabledButtonBackground,
    disabledButtonForeground: base.disabledButtonForeground,
    buttonSide: base.buttonSide,
    backIcon: base.backIcon,
  );
}

class _Incierto extends StatelessWidget {
  const _Incierto({required this.c});

  final BienvenidaController c;

  @override
  Widget build(BuildContext context) => Obx(
    () => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        RespuestasRapidas(
          respuestas: [
            RespuestaRapida(
              texto: _Textos.volverAIntentar,
              alTocar: c.esperando.value ? null : c.volverAIntentarElRegistro,
            ),
            RespuestaRapida(
              texto: _Textos.iniciarSesion,
              principal: true,
              esperando: c.esperando.value,
              alTocar: c.iniciarSesionDesdeIncierto,
            ),
          ],
        ),
        EnlaceSecundario(
          texto: _Textos.yaTengoCuenta,
          alTocar: c.yaTengoCuenta,
        ),
      ],
    ),
  );
}
