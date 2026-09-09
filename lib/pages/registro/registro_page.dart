import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/portal_sync_models.dart';
import '../../services/auth_service.dart';
import '../../services/post_login_route.dart';
import '../password_reset/password_reset_ui.dart';
import 'registro_controller.dart';

/// Alta de cuenta contra miUlima.
///
/// Una sola ruta con cinco estados en vez de cinco pantallas, como hace
/// `PortalSyncPage` con tres: el flujo es lineal y volver atrás a mitad del
/// envío solo produce cuentas creadas que su dueño no sabe que tiene.
///
/// Reutiliza los widgets públicos de `password_reset_ui.dart` porque son el
/// mismo lenguaje visual del login, ya extraído (los del login son privados).
class RegistroPage extends GetView<RegistroController> {
  const RegistroPage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = PasswordResetPalette.from(context);
    return Obx(() {
      // Mientras se envía no se sale: ni con el gesto del sistema ni con el
      // botón de volver que `PasswordResetScaffold` dibuja siempre, porque
      // `PopScope` intercepta el `maybePop()` de los dos (BR-REG-F-09).
      //
      // `PopScope` solo veta lo que pasa por `Navigator.maybePop()`: el gesto
      // del sistema y el botón de volver del scaffold. NO frena las salidas
      // programáticas de GetX (`Get.back()`, `Get.offNamed()`), que llaman a
      // `pop()` directo. Hoy no hay ninguna expuesta durante `enviando` —el
      // switch no monta ningún paso con enlaces—, pero si se agrega una hay
      // que guardarla con `if (controller.enviando) return;`.
      // Tipo explícito `<dynamic>`: sin él, `onPopInvokedWithResult` hace que
      // Dart infiera `PopScope<Object>` en vez de `PopScope<dynamic>`, y
      // `find.byType(PopScope)` de los tests (que sí espera `<dynamic>`, el
      // que da la referencia a la clase sin argumentos) deja de encontrarlo.
      return PopScope<dynamic>(
        canPop: !controller.enviando,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _avisoEnviando();
        },
        child: PasswordResetScaffold(
          palette: palette,
          child: switch (controller.paso.value) {
            RegistroPaso.datos => _PasoDatos(palette: palette, controller: controller),
            RegistroPaso.verificar => _PasoVerificar(palette: palette, controller: controller),
            RegistroPaso.enviando => _Enviando(palette: palette),
            RegistroPaso.listo => _Listo(palette: palette, controller: controller),
            RegistroPaso.incierto => _Incierto(palette: palette, controller: controller),
          },
        ),
      );
    });
  }
}

/// Avisa que salir a mitad del envío deja una cuenta a medias.
///
/// Sin esto el botón de volver que `PasswordResetScaffold` siempre dibuja
/// queda visible y presionable, pero el `PopScope` lo veta en silencio: quien
/// espera los dos minutos del envío y lo presiona no ve nada y concluye que
/// la app se colgó.
void _avisoEnviando() {
  Get.snackbar(
    'Estamos creando tu cuenta',
    'No cierres la app: si sales ahora podrías quedarte con una cuenta a medias.',
  );
}

class _Titulo extends StatelessWidget {
  const _Titulo({required this.palette, required this.texto, required this.bajada});

  final PasswordResetPalette palette;
  final String texto;
  final String bajada;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          texto,
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.fieldText, fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Text(
          bajada,
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.fieldHint, fontSize: 12, height: 1.4),
        ),
      ],
    );
  }
}

/// Ojo de mostrar/ocultar, igual que el del login.
class _OjoContrasena extends StatelessWidget {
  const _OjoContrasena({required this.palette, required this.visible, required this.onTap});

  final PasswordResetPalette palette;
  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 20,
        color: palette.fieldHint,
      ),
      onPressed: onTap,
      splashRadius: 18,
    );
  }
}

class _PasoDatos extends StatelessWidget {
  const _PasoDatos({required this.palette, required this.controller});

  final PasswordResetPalette palette;
  final RegistroController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Titulo(
          palette: palette,
          texto: 'Crea tu cuenta de ULima++',
          bajada: 'Elige la contraseña con la que entrarás al app. '
              'No es la de miUlima.',
        ),
        const SizedBox(height: 24),
        PasswordResetFieldLabel(palette: palette, text: 'Código'),
        const SizedBox(height: 8),
        PasswordResetField(
          controller: controller.codigoCtrl,
          palette: palette,
          hint: 'Tu código de alumno',
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 20),
        PasswordResetFieldLabel(palette: palette, text: 'Contraseña'),
        const SizedBox(height: 8),
        Obx(() => PasswordResetField(
              controller: controller.passwordCtrl,
              palette: palette,
              hint: 'Al menos 8 caracteres',
              obscureText: !controller.passwordVisible.value,
              textInputAction: TextInputAction.next,
              suffixIcon: _OjoContrasena(
                palette: palette,
                visible: controller.passwordVisible.value,
                onTap: controller.passwordVisible.toggle,
              ),
            )),
        const SizedBox(height: 20),
        PasswordResetFieldLabel(palette: palette, text: 'Repetir contraseña'),
        const SizedBox(height: 8),
        Obx(() => PasswordResetField(
              controller: controller.confirmacionCtrl,
              palette: palette,
              hint: 'La misma otra vez',
              obscureText: !controller.passwordVisible.value,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => controller.continuar(),
            )),
        Obx(() => PasswordResetErrorMessage(
              palette: palette,
              message: controller.errorMessage.value,
            )),
        const SizedBox(height: 20),
        PasswordResetPrimaryButton(
          palette: palette,
          label: 'Continuar',
          loading: false,
          onPressed: controller.continuar,
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => Get.back<void>(),
          child: Text(
            'Ya tengo cuenta',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.fieldHint, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _PasoVerificar extends StatelessWidget {
  const _PasoVerificar({required this.palette, required this.controller});

  final PasswordResetPalette palette;
  final RegistroController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Titulo(
          palette: palette,
          texto: 'Verificamos que eres alumno',
          bajada: 'Entramos a miUlima con tus datos una sola vez, para traer '
              'tus cursos y tu avance. No los guardamos.',
        ),
        const SizedBox(height: 24),
        PasswordResetFieldLabel(palette: palette, text: 'Contraseña de miUlima'),
        const SizedBox(height: 8),
        Obx(() => PasswordResetField(
              controller: controller.portalPasswordCtrl,
              palette: palette,
              hint: 'Tu contraseña del portal',
              obscureText: !controller.portalPasswordVisible.value,
              textInputAction: TextInputAction.next,
              suffixIcon: _OjoContrasena(
                palette: palette,
                visible: controller.portalPasswordVisible.value,
                onTap: controller.portalPasswordVisible.toggle,
              ),
            )),
        const SizedBox(height: 20),
        PasswordResetFieldLabel(palette: palette, text: 'Código del authenticator'),
        const SizedBox(height: 8),
        PasswordResetOtpField(controller: controller.passcodeCtrl, palette: palette),
        const SizedBox(height: 8),
        Text(
          'El código de 6 dígitos que cambia cada 30 segundos.',
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.fieldHint, fontSize: 11),
        ),
        Obx(() => PasswordResetErrorMessage(
              palette: palette,
              message: controller.errorMessage.value,
            )),
        const SizedBox(height: 16),
        PasswordResetPrimaryButton(
          palette: palette,
          label: 'Crear mi cuenta',
          loading: false,
          onPressed: controller.enviar,
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: controller.volverADatos,
          child: Text(
            'Volver',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.fieldHint, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _Enviando extends StatelessWidget {
  const _Enviando({required this.palette});

  final PasswordResetPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 46,
          height: 46,
          // `palette.cursor` y no `buttonBackground`: en modo oscuro ese es
          // transparente y el spinner sería invisible.
          child: CircularProgressIndicator(strokeWidth: 3, color: palette.cursor),
        ),
        const SizedBox(height: 24),
        Text(
          'Creando tu cuenta…',
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.fieldText, fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Text(
          'Estamos entrando a miUlima y trayendo tus cursos, tu horario y tu '
          'avance. Puede tomar un par de minutos: no cierres la app.',
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.fieldHint, fontSize: 12, height: 1.4),
        ),
      ],
    );
  }
}

class _Listo extends StatelessWidget {
  const _Listo({required this.palette, required this.controller});

  final PasswordResetPalette palette;
  final RegistroController controller;

  @override
  Widget build(BuildContext context) {
    final r = controller.resultado.value;
    final avisos = r?.warnings ?? const <PortalSyncWarning>[];
    final nombre = r?.user.firstName ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_rounded, size: 54, color: palette.cursor),
        const SizedBox(height: 16),
        Text(
          nombre.isEmpty ? 'Listo, ya tienes cuenta' : 'Listo, $nombre',
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.fieldText, fontSize: 20, fontWeight: FontWeight.w800),
        ),
        if (r != null) ...[
          const SizedBox(height: 16),
          _Fila(palette: palette, etiqueta: 'Cursos matriculados', valor: '${r.summary.cursos}'),
          _Fila(palette: palette, etiqueta: 'Clases en tu horario', valor: '${r.summary.sessionsUpserted}'),
          _Fila(palette: palette, etiqueta: 'Cursos de tu avance', valor: '${r.summary.progressUpserted}'),
        ],
        if (avisos.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            'Algunas cosas que notamos',
            style: TextStyle(color: palette.fieldText, fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          for (final a in avisos)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '· ${a.message}',
                style: TextStyle(color: palette.fieldHint, fontSize: 11, height: 1.35),
              ),
            ),
        ],
        const SizedBox(height: 24),
        PasswordResetPrimaryButton(
          palette: palette,
          label: 'Entrar',
          loading: false,
          onPressed: () {
            final user = controller.resultado.value?.user;
            if (user == null) return;
            Get.offAllNamed(postLoginRoute(user));
          },
        ),
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({required this.palette, required this.etiqueta, required this.valor});

  final PasswordResetPalette palette;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: TextStyle(color: palette.fieldHint, fontSize: 13)),
          Text(valor, style: TextStyle(color: palette.fieldText, fontSize: 13, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _Incierto extends StatelessWidget {
  const _Incierto({required this.palette, required this.controller});

  final PasswordResetPalette palette;
  final RegistroController controller;

  @override
  Widget build(BuildContext context) {
    // A `incierto` se llega por dos caminos que NO saben lo mismo. Con
    // `SIN_TOKEN` el 201 llegó y la cuenta está creada: lo único que falló fue
    // dejar la sesión puesta, y el título tiene que decir eso en vez de dudar
    // de algo que ya se sabe. Con el plazo vencido la duda es real.
    final confirmada = controller.cuentaConfirmada.value;
    final titulo = confirmada
        ? 'Tu cuenta ya está creada'
        : 'No pudimos confirmar si tu cuenta se creó';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.help_outline_rounded, size: 54, color: palette.error),
        const SizedBox(height: 16),
        _Titulo(
          palette: palette,
          texto: titulo,
          bajada: confirmada
              ? 'Entra con el código y la contraseña que acabas de elegir.'
              : 'Es posible que sí se haya creado. Prueba entrar con el '
                  'código y la contraseña que acabas de elegir.',
        ),
        Obx(() {
          // Por el camino del plazo vencido el mensaje de error es LA MISMA
          // frase del título: pintarlo debajo en naranja la repite sin agregar
          // nada. Los demás mensajes de este estado —el del rescate fallido,
          // el de la sesión que no se pudo dejar puesta— sí dicen algo nuevo.
          final msg = controller.errorMessage.value;
          return PasswordResetErrorMessage(
            palette: palette,
            message: _repiteElTitulo(msg, titulo) ? null : msg,
          );
        }),
        const SizedBox(height: 20),
        Obx(() => PasswordResetPrimaryButton(
              palette: palette,
              label: 'Iniciar sesión',
              // Apagar el botón mientras el login está en vuelo es lo que
              // impide que un doble toque dispare dos sesiones (y da el único
              // acuse de recibo que esta pantalla tiene durante la espera).
              loading: controller.iniciandoSesion.value,
              onPressed: () async {
                final entro = await controller.intentarIniciarSesion();
                if (!entro) return;
                // `login()` ya dejó el usuario puesto; de ahí sale la ruta.
                final user = AuthService.to.currentUser;
                if (user != null) Get.offAllNamed(postLoginRoute(user));
              },
            )),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: controller.volverAVerificar,
          child: Text(
            'Volver a intentar el registro',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.fieldHint, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

/// True si el error a pintar bajo el título es la misma frase que el título.
///
/// Se compara sin puntuación ni mayúsculas porque las dos cadenas nacen en
/// archivos distintos —el título en la página, el mensaje en
/// `RegistroService`— y difieren solo en el punto final.
bool _repiteElTitulo(String? mensaje, String titulo) {
  if (mensaje == null) return false;
  String normalizar(String s) =>
      s.replaceAll(RegExp(r'[.\u2026]'), '').trim().toLowerCase();
  return normalizar(mensaje) == normalizar(titulo);
}
