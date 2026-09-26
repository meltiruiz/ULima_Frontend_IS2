import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../models/portal_sync_models.dart';
import '../../services/alert_service.dart';
import '../../services/portal_sync_service.dart';
import '../calculadora/calculadora_controller.dart';
import '../horario/horario_controller.dart';
import '../malla/malla_list_controller.dart';

/// En qué punto del flujo está la pantalla.
///
/// `consent` va PRIMERO y es el estado inicial (RF-REC-6): el formulario de
/// credenciales no se dibuja hasta que el alumno acepta.
enum PortalSyncStep { consent, form, loading, done }

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

  final step = PortalSyncStep.consent.obs;
  final errorMessage = RxnString();
  final passwordVisible = false.obs;
  final Rx<PortalSyncResult?> result = Rx<PortalSyncResult?>(null);

  /// Si el alumno ya aceptó el consentimiento EN ESTA VISITA. No se guarda en
  /// `StorageService` ni en `shared_preferences` a propósito (RF-REC-6, "Qué
  /// NO entra"): se pregunta antes de cada importación.
  final consentimientoAceptado = false.obs;

  bool get cargando => step.value == PortalSyncStep.loading;

  /// RF-REC-6: el alumno aceptó la pantalla de consentimiento. Dura lo que dura
  /// este controller, es decir, una visita a /portal-sync: PortalSyncBinding usa
  /// lazyPut sin fenix, así que salir y volver a entrar la pide de nuevo.
  void aceptarConsentimiento() {
    consentimientoAceptado.value = true;
    errorMessage.value = null;
    step.value = PortalSyncStep.form;
  }

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
    // Sin aceptación no se envía nada (RF-REC-6).
    if (!consentimientoAceptado.value) {
      step.value = PortalSyncStep.consent;
      return;
    }
    final password = passwordCtrl.text;
    // SIN recortar, a propósito: `validarPasscode` acepta de 6 a 8 dígitos
    // (`^\d{6,8}$`) y el campo comparte widget con el código de recuperación,
    // que ahora recorta sólo al PINTAR. Recortar aquí a 6 haría imposible un
    // passcode de 7 u 8 — que es justo lo que hacía el
    // LengthLimitingTextInputFormatter que se quitó para arreglar el borrado
    // en iOS. Ver PasswordResetOtpField.
    final passcode = passcodeCtrl.text.trim();

    final error = validarFormulario(password: password, passcode: passcode);
    if (error != null) {
      errorMessage.value = error;
      return;
    }

    errorMessage.value = null;
    step.value = PortalSyncStep.loading;
    try {
      final r = await _service.import(
        password: password,
        passcode: passcode,
        consent: consentimientoAceptado.value,
      );
      // Apenas se usó, se borra: si el alumno vuelve atrás no queda escrita.
      passwordCtrl.clear();
      passcodeCtrl.clear();
      // El token viaja con el resultado: trae el cargo recalculado, así que
      // la pestaña de delegado aparece o desaparece sin volver a entrar.
      await _service.refreshAfterImport(token: r.token);
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
        // Se recarga entero en vez de borrarlo (RF-RCG-11). La fila «Notas
        // oficiales» y el aviso de IMPORT_REQUIRED abren /portal-sync con la
        // calculadora montada debajo, y borrar su controller deja a
        // «Registrar Nota» sin él. `recargarTodo()` sí vuelve a pedir el
        // sílabo, así que los pesos no quedan viejos.
        await Get.find<CalculadoraController>().recargarTodo();
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
}
