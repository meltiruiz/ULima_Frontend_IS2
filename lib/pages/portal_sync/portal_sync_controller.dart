import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../models/portal_sync_models.dart';
import '../../services/alert_service.dart';
import '../../services/portal_sync_service.dart';
import '../calculadora/calculadora_controller.dart';
import '../horario/horario_controller.dart';
import '../malla/malla_list_controller.dart';

/// En qué punto del flujo está la pantalla.
enum PortalSyncStep { form, loading, done }

/// Validación pura: `null` = válido. Separada del widget para poder probarla
/// sin montar nada, como `password_reset_validators.dart`.
String? validarPassword(String value) =>
    value.trim().isEmpty ? 'Escribe tu contraseña de miUlima.' : null;

String? validarPasscode(String value) {
  final v = value.trim();
  if (v.isEmpty) return 'Escribe el código de tu authenticator.';
  if (!RegExp(r'^\d{6,8}$').hasMatch(v)) {
    return 'El código son 6 dígitos, sin espacios.';
  }
  return null;
}

/// Primer error de los dos campos, o `null` si ambos están bien.
String? validarFormulario({required String password, required String passcode}) =>
    validarPassword(password) ?? validarPasscode(passcode);

class PortalSyncController extends GetxController {
  PortalSyncController({PortalSyncService? service})
      : _service = service ?? PortalSyncService();

  final PortalSyncService _service;

  // La contraseña vive SOLO en este TextEditingController. No entra en un Rx
  // observable, no se guarda y no se imprime.
  final passwordCtrl = TextEditingController();
  final passcodeCtrl = TextEditingController();

  final step = PortalSyncStep.form.obs;
  final errorMessage = RxnString();
  final passwordVisible = false.obs;
  final Rx<PortalSyncResult?> result = Rx<PortalSyncResult?>(null);

  bool get cargando => step.value == PortalSyncStep.loading;

  @override
  void onClose() {
    // `clear()` antes de `dispose()`: el texto no queda en el buffer del campo
    // cuando la pantalla se destruye.
    passwordCtrl.clear();
    passcodeCtrl.clear();
    passwordCtrl.dispose();
    passcodeCtrl.dispose();
    super.onClose();
  }

  Future<void> submit() async {
    if (cargando) return;
    final password = passwordCtrl.text;
    final passcode = passcodeCtrl.text.trim();

    final error = validarFormulario(password: password, passcode: passcode);
    if (error != null) {
      errorMessage.value = error;
      return;
    }

    errorMessage.value = null;
    step.value = PortalSyncStep.loading;
    try {
      final r = await _service.import(password: password, passcode: passcode);
      // Apenas se usó, se borra: si el alumno vuelve atrás no queda escrita.
      passwordCtrl.clear();
      passcodeCtrl.clear();
      await _service.refreshAfterImport();
      await _refrescarPantallas();
      result.value = r;
      step.value = PortalSyncStep.done;
    } on PortalSyncFailure catch (e) {
      // El código del authenticator ya caducó: se limpia para que el alumno
      // escriba el siguiente sin tener que borrarlo a mano. La contraseña se
      // conserva, que es lo que menos cambia entre intentos.
      passcodeCtrl.clear();
      errorMessage.value = e.message;
      step.value = PortalSyncStep.form;
    }
  }

  /// Recarga los controllers que estén vivos.
  ///
  /// Siempre con la guarda `isRegistered`: en GetX un `Get.find` sobre un
  /// `lazyPut` no resuelto CREA la instancia, así que sin la guarda se
  /// instanciarían controllers huérfanos de pantallas que el alumno no abrió.
  Future<void> _refrescarPantallas() async {
    try {
      if (Get.isRegistered<MallaListController>()) {
        await Get.find<MallaListController>().retry();
      }
      if (Get.isRegistered<HorarioController>()) {
        await Get.find<HorarioController>().reload();
      }
      if (Get.isRegistered<CalculadoraController>()) {
        // Se borra en vez de recargarlo: `recargar()` no reejecuta la carga del
        // sílabo, así que los pesos de las evaluaciones quedarían viejos. La
        // pestaña lo vuelve a crear al abrirse.
        await Get.delete<CalculadoraController>(force: true);
      }
      // La importación crea alertas (impedimentos, riesgo académico).
      if (Get.isRegistered<AlertService>()) {
        await AlertService.to.fetchAlerts();
      }
    } catch (_) {
      // El import ya salió bien: un fallo del refresco no es un error para el
      // alumno, solo significa que verá los datos nuevos al cambiar de pestaña.
    }
  }

  void volverAlFormulario() {
    errorMessage.value = null;
    step.value = PortalSyncStep.form;
  }
}
