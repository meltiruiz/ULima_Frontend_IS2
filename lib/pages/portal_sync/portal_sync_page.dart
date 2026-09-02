import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../models/portal_sync_models.dart';
import '../password_reset/password_reset_ui.dart';
import 'portal_sync_controller.dart';

/// Carga de ciclo desde miUlima.
///
/// Una sola pantalla con tres estados (formulario, cargando, resumen) en vez de
/// tres rutas: el flujo es lineal y el alumno no gana nada pudiendo volver al
/// paso anterior con el botón del sistema mientras la carga corre.
///
/// Reutiliza los widgets públicos de `password_reset_ui.dart` porque son el
/// mismo lenguaje visual del login, ya extraído (los del login son privados).
class PortalSyncPage extends GetView<PortalSyncController> {
  const PortalSyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = PasswordResetPalette.from(context);
    return PasswordResetScaffold(
      palette: palette,
      child: Obx(() {
        switch (controller.step.value) {
          case PortalSyncStep.loading:
            return _Cargando(palette: palette);
          case PortalSyncStep.done:
            return _Resumen(palette: palette, result: controller.result.value);
          case PortalSyncStep.form:
            return _Formulario(palette: palette, controller: controller);
        }
      }),
    );
  }
}

class _Formulario extends StatelessWidget {
  const _Formulario({required this.palette, required this.controller});

  final PasswordResetPalette palette;
  final PortalSyncController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Carga tus datos del ciclo',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.fieldText, fontSize: 20, fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Traemos de miUlima tus cursos, secciones, horario, docentes y tu '
          'avance de carrera. Entramos al portal con tus datos una sola vez y '
          'no los guardamos.',
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.fieldHint, fontSize: 12, height: 1.4),
        ),
        const SizedBox(height: 24),

        PasswordResetFieldLabel(palette: palette, text: 'Contraseña de miUlima'),
        const SizedBox(height: 8),
        Obx(() => PasswordResetField(
              controller: controller.passwordCtrl,
              palette: palette,
              hint: 'Tu contraseña del portal',
              obscureText: !controller.passwordVisible.value,
              textInputAction: TextInputAction.next,
            )),
        const SizedBox(height: 6),
        Obx(() => GestureDetector(
              onTap: () => controller.passwordVisible.toggle(),
              child: Text(
                controller.passwordVisible.value ? 'Ocultar contraseña' : 'Mostrar contraseña',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: palette.fieldHint, fontSize: 11, fontWeight: FontWeight.w600,
                ),
              ),
            )),
        const SizedBox(height: 20),

        PasswordResetFieldLabel(palette: palette, text: 'Código del authenticator'),
        const SizedBox(height: 8),
        PasswordResetOtpField(
          controller: controller.passcodeCtrl,
          palette: palette,
        ),
        const SizedBox(height: 8),
        Text(
          'El código de 6 dígitos que cambia cada 30 segundos.',
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.fieldHint, fontSize: 11),
        ),
        const SizedBox(height: 16),

        Obx(() => PasswordResetErrorMessage(
              palette: palette,
              message: controller.errorMessage.value,
            )),
        const SizedBox(height: 8),

        Obx(() => PasswordResetPrimaryButton(
              palette: palette,
              label: 'Cargar mis datos',
              loading: controller.cargando,
              onPressed: controller.submit,
            )),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => Get.back<void>(),
          child: Text(
            'Ahora no',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.fieldHint, fontSize: 12, fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Pantalla de espera. La importación real tarda entre 30 y 50 segundos: sin
/// decir qué está pasando, el alumno cree que se colgó.
class _Cargando extends StatelessWidget {
  const _Cargando({required this.palette});

  final PasswordResetPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 46, height: 46,
          child: CircularProgressIndicator(
            strokeWidth: 3, color: palette.buttonBackground,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Entrando a miUlima…',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.fieldText, fontSize: 17, fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Estamos trayendo tus cursos, tu horario y tu avance. Puede tomar '
          'hasta un minuto: no cierres la app.',
          textAlign: TextAlign.center,
          style: TextStyle(color: palette.fieldHint, fontSize: 12, height: 1.4),
        ),
      ],
    );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen({required this.palette, required this.result});

  final PasswordResetPalette palette;
  final PortalSyncResult? result;

  @override
  Widget build(BuildContext context) {
    final r = result;
    final s = r?.summary;
    final avisos = r?.warnings ?? const <PortalSyncWarning>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_rounded, size: 54, color: palette.buttonBackground),
        const SizedBox(height: 16),
        Text(
          r == null || r.periodCode.isEmpty
              ? 'Listo, ya tienes tus datos'
              : 'Listo, ciclo ${r.periodCode}',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.fieldText, fontSize: 19, fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 18),
        if (s != null) ...[
          _Fila(palette: palette, etiqueta: 'Cursos matriculados', valor: s.cursos),
          _Fila(palette: palette, etiqueta: 'Clases en tu horario', valor: s.sessionsUpserted),
          _Fila(palette: palette, etiqueta: 'Cursos de tu avance', valor: s.progressUpserted),
          if (s.syllabiUpserted > 0)
            _Fila(palette: palette, etiqueta: 'Sílabos encontrados', valor: s.syllabiUpserted),
          if (s.enrollmentsWithdrawn > 0)
            _Fila(palette: palette, etiqueta: 'Cursos que retiraste', valor: s.enrollmentsWithdrawn),
        ],
        if (avisos.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            'Algunas cosas que notamos',
            style: TextStyle(
              color: palette.fieldText, fontSize: 13, fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          // El mensaje del backend ya viene redactado para el alumno.
          for (final a in avisos)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '· ${a.message}',
                style: TextStyle(color: palette.fieldHint, fontSize: 11, height: 1.4),
              ),
            ),
        ],
        const SizedBox(height: 26),
        PasswordResetPrimaryButton(
          palette: palette,
          label: 'Ver mis cursos',
          loading: false,
          onPressed: () => Get.back<bool>(result: true),
        ),
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({required this.palette, required this.etiqueta, required this.valor});

  final PasswordResetPalette palette;
  final String etiqueta;
  final int valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              etiqueta,
              style: TextStyle(color: palette.fieldHint, fontSize: 12),
            ),
          ),
          Text(
            '$valor',
            style: TextStyle(
              color: palette.fieldText, fontSize: 15, fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
