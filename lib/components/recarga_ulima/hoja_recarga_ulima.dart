// lib/components/recarga_ulima/hoja_recarga_ulima.dart
//
// La hoja de recarga desde la ULima (RF-RCG-2 y RF-RCG-3 de
// specs/features/recarga-portal/recarga-portal.spec.md), con el formato del
// modal «Registrar Nota». La abren la franja de /mis-notas y el bloque de
// asistencia de la ficha del curso.

import 'package:flutter/material.dart';

import '../../configs/themes.dart';
import '../../pages/password_reset/password_reset_ui.dart';
import '../../pages/portal_sync/portal_sync_controller.dart'
    show validarFormulario;
import '../../services/auth_service.dart';
import '../../services/recarga_ulima_service.dart';

/// Abre la hoja y devuelve `true` si la recarga queda guardada. Un toque
/// fuera o un arrastre no la cierran (D4).
Future<bool> abrirHojaRecargaUlima(BuildContext context) async {
  final guardada = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (_) => const HojaRecargaUlima(),
  );
  return guardada ?? false;
}

class HojaRecargaUlima extends StatefulWidget {
  const HojaRecargaUlima({super.key});

  @override
  State<HojaRecargaUlima> createState() => _HojaRecargaUlimaState();
}

class _HojaRecargaUlimaState extends State<HojaRecargaUlima> {
  // La contraseña y el código viven solo en estos dos controllers, que se
  // vacían al cerrar de cualquier forma y antes de dispose().
  final TextEditingController _password = TextEditingController();
  final TextEditingController _passcode = TextEditingController();
  bool _verPassword = false;
  bool _esperando = false;

  @override
  void initState() {
    super.initState();
    _password.addListener(_refrescar);
    _passcode.addListener(_refrescar);
  }

  @override
  void dispose() {
    _password.removeListener(_refrescar);
    _passcode.removeListener(_refrescar);
    _vaciar();
    _password.dispose();
    _passcode.dispose();
    super.dispose();
  }

  void _refrescar() {
    if (mounted) setState(() {});
  }

  void _vaciar() {
    _password.clear();
    _passcode.clear();
  }

  /// El mismo criterio de `/portal-sync`, contraseña no vacía tras `trim()`
  /// y código con `^\d{6,8}$`.
  bool get _listo =>
      validarFormulario(password: _password.text, passcode: _passcode.text) ==
      null;

  void _cerrar() {
    _vaciar();
    Navigator.of(context).pop(false);
  }

  Future<void> _actualizar() async {
    if (!_listo || _esperando) return;
    setState(() => _esperando = true);
    // La contraseña viaja sin trim() y el código sin recortar a seis, igual
    // que en /portal-sync.
    final guardada = await RecargaUlimaService.to.recargar(
      password: _password.text,
      passcode: _passcode.text.trim(),
    );
    _vaciar();
    // Con un 401, offAllToLogin() (api_client.dart) retira la hoja antes de
    // que recargar() devuelva. La hoja sigue montada hasta el frame siguiente,
    // y un pop sin esta guarda sacaría /login (RF-RCG-3).
    if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
      Navigator.of(context).pop(guardada);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tenue = colors.onSurface.withValues(alpha: 0.7);
    final borde = colors.onSurface.withValues(alpha: 0.5);
    final codigo = AuthService.to.currentUser?.code;
    final rotulo = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: colors.onSurface,
    );

    return PopScope(
      canPop: !_esperando,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _vaciar();
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            'Actualizar desde la ULima',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                        if (codigo != null)
                          Text.rich(
                            TextSpan(
                              text: 'Entras como ',
                              children: [
                                TextSpan(
                                  text: codigo,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurface,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    icon: Icon(Icons.close, color: colors.onSurface),
                    onPressed: _esperando ? null : _cerrar,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Al tocar «Actualizar» aceptas que ULima++ lea en miUlima tus '
                'notas parciales y tu asistencia. La contraseña y el código '
                'se usan una sola vez y no se guardan.',
                style: TextStyle(fontSize: 13, color: tenue),
              ),
              const SizedBox(height: 20),
              ExcludeSemantics(
                child: Text('Contraseña de miUlima', style: rotulo),
              ),
              const SizedBox(height: 8),
              Semantics(
                container: true,
                label: 'Contraseña de miUlima',
                child: TextField(
                  controller: _password,
                  obscureText: !_verPassword,
                  readOnly: _esperando,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: const [AutofillHints.password],
                  style: TextStyle(color: colors.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Tu contraseña del portal',
                    hintStyle: TextStyle(
                      color: colors.onSurface.withValues(alpha: 0.6),
                    ),
                    constraints: const BoxConstraints(minHeight: 52),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borde),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borde),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.primary, width: 2),
                    ),
                    suffixIcon: IconButton(
                      tooltip: _verPassword
                          ? 'Ocultar contraseña'
                          : 'Mostrar contraseña',
                      icon: Icon(
                        _verPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: tenue,
                      ),
                      onPressed: _esperando
                          ? null
                          : () => setState(() => _verPassword = !_verPassword),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ExcludeSemantics(
                child: Text('Código del autenticador', style: rotulo),
              ),
              const SizedBox(height: 8),
              Semantics(
                container: true,
                label: 'Código del autenticador, 6 dígitos',
                child: PasswordResetOtpField(
                  controller: _passcode,
                  palette: PasswordResetPalette.from(context),
                  boxHeight: 50,
                  boxFill: Colors.transparent,
                  idleBorderColor: borde,
                  readOnly: _esperando,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'El código de 6 dígitos que cambia cada 30 segundos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: tenue),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _esperando ? null : _cerrar,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: colors.onSurface,
                        side: BorderSide(
                          color: colors.outline.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _listo && !_esperando ? _actualizar : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: MaterialTheme.primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: colors.primary.withValues(
                          alpha: 0.3,
                        ),
                        disabledForegroundColor: colors.onSurface.withValues(
                          alpha: 0.38,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _esperando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Actualizar',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
              if (_esperando) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Center(
                    child: Text(
                      'Leyendo miUlima. Puede tardar hasta un minuto.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: tenue),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
