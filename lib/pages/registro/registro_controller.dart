import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../models/registro_models.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/registro_service.dart';
import '../password_reset/password_reset_validators.dart';

/// En qué punto del alta está la pantalla.
enum RegistroPaso { datos, verificar, enviando, listo, incierto }

/// Validación pura: `null` = válido. Separada del widget para poder probarla
/// sin montar nada, como `password_reset_validators.dart`.
///
/// El rango es el mismo `^\d{6,10}$` de `registerSchema`. Se valida acá porque
/// el limitador de tasa del backend corre ANTES de validar el cuerpo: mandar
/// un código mal formado gasta uno de los cinco intentos por hora y devuelve
/// un 400 (BR-REG-F-03).
String? validarCodigo(String value) {
  final v = value.trim();
  if (v.isEmpty) return 'Escribe tu código de alumno.';
  if (!RegExp(r'^\d{6,10}$').hasMatch(v)) {
    return 'El código son entre 6 y 10 dígitos, sin espacios ni letras.';
  }
  return null;
}

/// Primer error del paso 1, o `null` si los tres campos están bien.
///
/// La contraseña usa los validadores del reset (mínimo 8). El backend acepta
/// cualquier cosa a propósito y lo declara deuda; pedir menos acá dejaría una
/// cuenta que no puede recuperar su propia contraseña.
String? validarPasoDatos({
  required String codigo,
  required String password,
  required String confirmacion,
}) =>
    validarCodigo(codigo) ??
    validateNewPassword(password) ??
    validatePasswordConfirmation(password, confirmacion);

String? validarPortalPassword(String value) =>
    value.trim().isEmpty ? 'Escribe tu contraseña de miUlima.' : null;

/// De 6 a 8 dígitos, igual que `PortalSyncController` y por el mismo motivo:
/// SecurID entrega 6 de tokencode y 8 cuando el PIN va delante, y
/// `PasswordResetOtpField` no recorta el texto (se le quitó el limitador de
/// longitud para arreglar el borrado en iOS).
String? validarPasscode(String value) {
  final v = value.trim();
  if (v.isEmpty) return 'Escribe el código de tu authenticator.';
  if (!RegExp(r'^\d{6,8}$').hasMatch(v)) {
    return 'El código del authenticator son 6 dígitos, sin espacios.';
  }
  return null;
}

String? validarPasoVerificar({
  required String portalPassword,
  required String passcode,
}) =>
    validarPortalPassword(portalPassword) ?? validarPasscode(passcode);

/// Costuras hacia `AuthService`, que no es construible en tests.
typedef AdoptarSesionFn = Future<void> Function({
  required String token,
  required UserModel user,
});
typedef IniciarSesionFn = Future<String?> Function({
  required String code,
  required String password,
});

class RegistroController extends GetxController {
  RegistroController({
    RegistroService? service,
    AdoptarSesionFn? adoptarSesion,
    IniciarSesionFn? iniciarSesion,
  })  : _service = service ?? RegistroService(),
        _adoptar = adoptarSesion ?? _adoptarPorDefecto,
        _login = iniciarSesion ?? _loginPorDefecto;

  static Future<void> _adoptarPorDefecto({
    required String token,
    required UserModel user,
  }) =>
      AuthService.to.adoptarSesion(token: token, user: user);

  static Future<String?> _loginPorDefecto({
    required String code,
    required String password,
  }) =>
      AuthService.to.login(code: code, password: password);

  final RegistroService _service;
  final AdoptarSesionFn _adoptar;
  final IniciarSesionFn _login;

  // Los cinco campos viven SOLO acá. Ninguno entra en un Rx observable, se
  // guarda o se imprime. Moverse entre pasos nunca los borra: lo único que se
  // borra es el passcode, y solo cuando un envío falló (BR-REG-F-05).
  final codigoCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmacionCtrl = TextEditingController();
  final portalPasswordCtrl = TextEditingController();
  final passcodeCtrl = TextEditingController();

  final paso = RegistroPaso.datos.obs;
  final errorMessage = RxnString();

  /// True mientras el login de rescate de `incierto` está en vuelo.
  ///
  /// Alimenta el `loading` del botón, que así se apaga y deja de ser pulsable.
  /// `paso` no sirve de guarda: se queda en `incierto` durante todo el `await`,
  /// así que sin esto un segundo toque sobre una conexión lenta dispara un
  /// segundo login, un segundo token guardado, una segunda carga de catálogos
  /// y un segundo `Get.offAllNamed`.
  final iniciandoSesion = false.obs;

  /// True cuando se sabe que la cuenta EXISTE aunque el flujo haya terminado en
  /// `incierto`.
  ///
  /// A `incierto` se llega por dos códigos y solo uno deja duda de verdad. Con
  /// `TIEMPO_AGOTADO` no sabemos si el servidor confirmó la transacción; con
  /// `SIN_TOKEN` el 201 ya llegó y lo único que falló fue dejar la sesión
  /// puesta. `resultado` no alcanza para distinguirlos: cuando el `SIN_TOKEN`
  /// lo lanza el servicio —201 sin token, o respuesta ilegible— no hay
  /// `RegistroResult` que guardar y aun así la cuenta está creada. Sin esto la
  /// pantalla titula "no pudimos confirmar" sobre un texto que dice que sí se
  /// creó, y se contradice hacia el lado que sabe menos.
  final cuentaConfirmada = false.obs;
  final passwordVisible = false.obs;
  final portalPasswordVisible = false.obs;
  final Rx<RegistroResult?> resultado = Rx<RegistroResult?>(null);

  bool get enviando => paso.value == RegistroPaso.enviando;

  @override
  void onClose() {
    // `clear()` antes de `dispose()`: el texto no queda en el buffer del campo
    // cuando la pantalla se destruye.
    for (final c in [
      codigoCtrl,
      passwordCtrl,
      confirmacionCtrl,
      portalPasswordCtrl,
      passcodeCtrl,
    ]) {
      c.clear();
      c.dispose();
    }
    super.onClose();
  }

  /// Paso 1 → paso 2. **No consulta al backend**: preguntar "¿existe este
  /// código?" sería un oráculo de enumeración de cuentas (BR-REG-F-02).
  void continuar() {
    final error = validarPasoDatos(
      codigo: codigoCtrl.text,
      password: passwordCtrl.text,
      confirmacion: confirmacionCtrl.text,
    );
    if (error != null) {
      errorMessage.value = error;
      return;
    }
    errorMessage.value = null;
    paso.value = RegistroPaso.verificar;
  }

  void volverADatos() {
    errorMessage.value = null;
    paso.value = RegistroPaso.datos;
  }

  Future<void> enviar() async {
    if (enviando) return;
    final error = validarPasoVerificar(
      portalPassword: portalPasswordCtrl.text,
      passcode: passcodeCtrl.text,
    );
    if (error != null) {
      errorMessage.value = error;
      return;
    }

    errorMessage.value = null;
    paso.value = RegistroPaso.enviando;

    final RegistroResult r;
    try {
      r = await _service.registrar(
        code: codigoCtrl.text.trim(),
        portalPassword: portalPasswordCtrl.text,
        passcode: passcodeCtrl.text.trim(),
        password: passwordCtrl.text,
      );
    } on RegistroFailure catch (e) {
      _manejarFallo(e);
      return;
    } catch (_) {
      // El servicio envuelve todo, pero si un doble o un cambio futuro lanza
      // otra cosa, la pantalla no puede quedarse en `enviando` para siempre.
      // Es el agujero que sí tiene `PortalSyncController`.
      _manejarFallo(const RegistroFailure(
        'No pudimos crear tu cuenta. Inténtalo de nuevo.',
      ));
      return;
    }

    // Apenas se usaron, se borran.
    portalPasswordCtrl.clear();
    passcodeCtrl.clear();

    try {
      await _adoptar(token: r.token, user: r.user);
    } catch (_) {
      // La cuenta EXISTE: el 201 ya volvió. Lo que falló es dejar la sesión
      // puesta, y para eso `incierto` ofrece justamente iniciar sesión.
      resultado.value = r;
      _manejarFallo(const RegistroFailure(
        'Tu cuenta se creó, pero no pudimos dejarte la sesión iniciada.',
        code: 'SIN_TOKEN',
      ));
      return;
    }

    resultado.value = r;
    paso.value = RegistroPaso.listo;
  }

  void _manejarFallo(RegistroFailure e) {
    passcodeCtrl.clear();
    errorMessage.value = e.message;
    // Se fija ANTES que `paso`: la pantalla se repinta observando `paso`, así
    // que leerlo después daría el valor viejo durante un frame.
    cuentaConfirmada.value = e.code == 'SIN_TOKEN';

    const aIncierto = {'TIEMPO_AGOTADO', 'SIN_TOKEN'};
    const aDatos = {
      'USER_ALREADY_EXISTS',
      'INVALID_REQUEST_BODY',
      'INVALID_JSON_BODY',
    };

    if (aIncierto.contains(e.code)) {
      paso.value = RegistroPaso.incierto;
    } else if (aDatos.contains(e.code)) {
      paso.value = RegistroPaso.datos;
    } else {
      paso.value = RegistroPaso.verificar;
    }
  }

  /// Primera salida de `incierto`: intentar entrar con lo que ya se eligió.
  ///
  /// Devuelve `true` si la sesión quedó iniciada; navegar es cosa de la página.
  ///
  /// Un fallo **no** prueba que la cuenta no exista: puede existir bajo el
  /// código que devolvió el portal, que gana sobre el tecleado (BR-REG-F-06).
  Future<bool> intentarIniciarSesion() async {
    if (paso.value != RegistroPaso.incierto) return false;
    if (iniciandoSesion.value) return false;
    iniciandoSesion.value = true;
    errorMessage.value = null;
    final String? error;
    try {
      error = await _login(
        code: codigoCtrl.text.trim(),
        password: passwordCtrl.text,
      );
    } catch (_) {
      // `AuthService.login` solo atrapa `ApiException`: un socket caído o un
      // `ClientException` salen crudos. Y a `incierto` se llega casi siempre
      // POR una red mala —el plazo venció—, así que la red sigue mal cuando se
      // pulsa este botón. Sin este catch la excepción escapa a la zona, la
      // línea de arriba ya borró el texto rojo y nada lo reemplaza: la
      // pantalla no hace nada visible, que es justo lo que BR-REG-F-11 existe
      // para evitar. `enviar()` ya tiene su catch-all por este mismo motivo.
      errorMessage.value =
          'No hay conexión. Revisa tu internet e inténtalo de nuevo.';
      return false;
    } finally {
      iniciandoSesion.value = false;
    }
    if (error == null) return true;
    errorMessage.value =
        'Seguimos sin poder confirmarlo. Puedes volver a intentar el registro: '
        'si te dice que ya existe una cuenta con ese código, es que sí se creó '
        'y puedes recuperar la contraseña desde el login.';
    return false;
  }

  /// Segunda salida de `incierto`.
  void volverAVerificar() {
    errorMessage.value = null;
    passcodeCtrl.clear();
    paso.value = RegistroPaso.verificar;
  }
}
