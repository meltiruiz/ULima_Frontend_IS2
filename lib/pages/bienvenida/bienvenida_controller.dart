// lib/pages/bienvenida/bienvenida_controller.dart
// La conversación de la bienvenida con Ulises (RF-BIEN-1 a RF-BIEN-13 y
// RF-BIEN-21 de specs/features/bienvenida/bienvenida.spec.md). Es permanente,
// como LoginController, con una visita por cada montaje de su página (B-19).
// Decide qué dice Ulises, qué pide el compositor y cuánto espera cada
// burbuja, y deja el dibujo y el ritmo a la página. Crea y cierra ella misma
// los controladores del registro y del test, sin Get.put (B-20 y B-34).

import 'dart:async';

import 'package:flutter/services.dart' show TextInput;
import 'package:get/get.dart';

import '../../domain/bienvenida/bienvenida_turnos.dart';
import '../../models/specialty_test_models.dart';
import '../../services/auth_service.dart';
import '../../services/post_login_route.dart';
import '../../services/session_navigation.dart';
import '../../services/specialty_test_service.dart';
import '../../services/storage_service.dart';
import '../login/login_controller.dart';
import '../password_reset/password_reset_validators.dart';
import '../registro/registro_controller.dart';
import '../specialty_test/specialty_test_controller.dart';
import '../specialty_test/specialty_test_logic.dart';
import '../specialty_test/widgets/question_view.dart' show emojisDeLaEscala;
import 'conversacion.dart';

/// La píldora bajo la franja mientras se crea la cuenta (RF-BIEN-8).
enum EstadoDeLaPildora { creando, creada }

typedef TextosB = TextosDeLaBienvenida;
typedef TurnoB = TurnoDeLaBienvenida;

class BienvenidaController extends GetxController {
  BienvenidaController({
    AuthService? auth,
    LoginController? login,
    RegistroController Function()? crearRegistro,
    SpecialtyTestController Function(SpecialtyTestUi ui)? crearTest,
    Future<String?> Function()? tokenGuardado,
    void Function(String ruta)? abrirRuta,
    void Function()? terminarAutocompletado,
    void Function(String titulo, String texto)? avisar,
  }) : _authInyectado = auth,
       _loginInyectado = login,
       _crearRegistro = crearRegistro ?? RegistroController.new,
       _crearTest =
           crearTest ??
           ((ui) => SpecialtyTestController(
             origen: OrigenDelTest.bienvenida,
             ui: ui,
           )),
       _tokenGuardado = tokenGuardado ?? (() => StorageService.to.savedToken),
       _abrirRuta = abrirRuta ?? ((ruta) => Get.toNamed<void>(ruta)),
       _terminarAutocompletado =
           terminarAutocompletado ?? (() => TextInput.finishAutofillContext()),
       _avisar =
           avisar ??
           ((titulo, texto) => Get.snackbar(
             titulo,
             texto,
             snackPosition: SnackPosition.BOTTOM,
           ));

  final AuthService? _authInyectado;
  final LoginController? _loginInyectado;
  final RegistroController Function() _crearRegistro;
  final SpecialtyTestController Function(SpecialtyTestUi ui) _crearTest;
  final Future<String?> Function() _tokenGuardado;
  final void Function(String ruta) _abrirRuta;

  /// Cierra el contexto del autocompletado para que el sistema ofrezca
  /// guardar el código y la contraseña (RF-BIEN-6). Las pruebas lo cambian
  /// por un registro, porque en la VM no hay plataforma que lo reciba.
  final void Function() _terminarAutocompletado;
  final void Function(String titulo, String texto) _avisar;

  final pildora = Rxn<EstadoDeLaPildora>();

  /// Mientras se envía el registro, el pulso recorre los rombos (RF-BIEN-4).
  final enviando = false.obs;

  /// Sube con cada resultado, y la página dibuja el confeti una vez bajo la
  /// franja (RF-BIEN-10).
  final confeti = 0.obs;
  final principalManual = RxnInt();
  final interesesManuales = <int>{}.obs;
  final catalogoFallido = false.obs;

  /// El test pidió empezar de nuevo, y el compositor lo ofrece.
  final pideReinicio = false.obs;

  final List<Worker> _trabajosDelTest = <Worker>[];
  int? _idDeLaCarga;
  FaseDelTest? _faseMostrada;
  int _pasoMostrado = -1;
  bool _volviendo = false;
  bool _saltando = false;
  bool _testDisponible = true;
  String? _botonQueGuarda;
  Completer<void>? _reinicio;

  AuthService get _auth => _authInyectado ?? AuthService.to;
  LoginController get _login => _loginInyectado ?? Get.find<LoginController>();

  /// El login, que usan los compositores de E1 y E2.
  LoginController get login => _login;

  /// El historial vive solo aquí, en memoria (RF-BIEN-5).
  final entradas = <EntradaDeLaConversacion>[].obs;

  /// El turno del compositor abierto, o null con el compositor cerrado.
  final turno = Rxn<TurnoDeLaBienvenida>();

  /// El último turno abierto, que decide el atrás del sistema.
  final ultimoTurno = Rxn<TurnoDeLaBienvenida>();
  final esperando = false.obs;
  final errorLocal = RxnString();

  /// La visita que el controlador ya atiende. La página no lee el estado
  /// mientras su visita no es esta (RF-BIEN-1).
  final visitaEmpezada = 0.obs;

  /// Sube con cada respuesta del alumno, y el sello late (RF-BIEN-4).
  final latidos = 0.obs;

  RegistroController? registro;
  SpecialtyTestController? test;

  int _visita = 0;
  int _siguienteId = 0;
  bool _conSesion = false;
  Worker? _googleEnWeb;

  /// La visita trae una sesión puesta o la puso «Sí, entrar» (RF-BIEN-21).
  bool get conSesion => _conSesion;

  @override
  void onInit() {
    super.onInit();
    _googleEnWeb = ever<DesenlaceDelLogin?>(_login.desenlaceDeGoogleEnWeb, (d) {
      if (d == null) return;
      // Se consume siempre, así un desenlace igual al anterior vuelve a
      // llegar. Solo cuenta mientras E1 está abierto (RF-BIEN-6).
      _login.desenlaceDeGoogleEnWeb.value = null;
      if (turno.value != TurnoB.e1Codigo) return;
      _trasGoogle(d);
    });
  }

  @override
  void onClose() {
    _googleEnWeb?.dispose();
    _cerrarLosTramos();
    super.onClose();
  }

  // ── Ayudas ───────────────────────────────────────────────────────────────

  int _id() => _siguienteId++;

  /// Ulises dice [lineas]. La primera espera [primera] y las siguientes
  /// 850 ms (RF-BIEN-5).
  void _decir(
    List<String> lineas, {
    Duration primera = Ritmo.trasLaRespuesta,
    TipoDeBurbuja tipo = TipoDeBurbuja.texto,
  }) {
    for (var i = 0; i < lineas.length; i++) {
      entradas.add(
        BurbujaDeUlises(
          id: _id(),
          texto: lineas[i],
          tipo: tipo,
          pausa: i == 0 ? primera : Ritmo.entreBurbujas,
        ),
      );
    }
  }

  /// Un error del backend o de la red, que entra enseguida (RF-BIEN-12).
  void _decirError(String mensaje) => _decir(
    <String>[mensaje],
    primera: Duration.zero,
    tipo: TipoDeBurbuja.error,
  );

  /// El compositor se cierra, entra la respuesta y el sello late.
  void _responder(
    String texto, {
    bool secreta = false,
    bool conGoogle = false,
  }) {
    turno.value = null;
    errorLocal.value = null;
    entradas.add(
      RespuestaDelAlumno(
        id: _id(),
        texto: texto,
        secreta: secreta,
        conGoogle: conGoogle,
      ),
    );
    latidos.value++;
  }

  void _abrir(TurnoDeLaBienvenida t) {
    turno.value = t;
    ultimoTurno.value = t;
  }

  // ── Visitas (RF-BIEN-1) ──────────────────────────────────────────────────

  /// El State de la página crea una visita al montarse.
  int nuevaVisita() => ++_visita;

  /// Después del primer cuadro de la página. Borra la conversación, cierra
  /// los tramos, vacía el login y mira si hay una sesión puesta.
  Future<void> empezarVisita(int visita, {MotivoDeLlegada? motivo}) async {
    if (visita != _visita) return;
    _reiniciar();
    final token = await _tokenGuardado();
    if (visita != _visita) return;
    final usuario = _auth.currentUser;
    final hayToken = token != null && token.isNotEmpty;
    if (motivo == null && hayToken && usuario != null) {
      // La llegada con sesión sigue lo que diga postLoginRoute (RF-BIEN-21).
      _conSesion = true;
      if (postLoginRoute(usuario) == '/home') {
        _decir(<String>[TextosB.e3], primera: Duration.zero);
        _abrir(TurnoB.pasoAlHorario);
        visitaEmpezada.value = visita;
        return;
      }
      _abrir(TurnoB.llegadaConSesion);
      visitaEmpezada.value = visita;
      return;
    }
    if (motivo != null) {
      // Directo a «Sí, entrar», con el sello ya en su lugar (RF-BIEN-3).
      _decir(<String>[TextosB.saludo], primera: Duration.zero);
      _abrirE1(primera: Ritmo.entreBurbujas);
      visitaEmpezada.value = visita;
      return;
    }
    _abrir(TurnoB.recibimiento);
    visitaEmpezada.value = visita;
  }

  /// El dispose de la página. Una visita vieja no toca la nueva.
  void terminarVisita(int visita) {
    if (visita != _visita) return;
    _cerrarLosTramos();
  }

  void _reiniciar() {
    _cerrarLosTramos();
    entradas.clear();
    turno.value = null;
    ultimoTurno.value = null;
    esperando.value = false;
    errorLocal.value = null;
    saludoEnLaConversacion.value = false;
    _conSesion = false;
    pildora.value = null;
    enviando.value = false;
    principalManual.value = null;
    interesesManuales.clear();
    catalogoFallido.value = false;
    _login.vaciarCampos();
  }

  void _cerrarLosTramos() {
    _cerrarRegistro();
    _cerrarTest();
  }

  void _cerrarRegistro() {
    registro?.cerrar();
    registro = null;
  }

  void _cerrarTest() {
    for (final w in _trabajosDelTest) {
      w.dispose();
    }
    _trabajosDelTest.clear();
    test?.onDelete();
    test = null;
    _idDeLaCarga = null;
    _faseMostrada = null;
    _pasoMostrado = -1;
    pideReinicio.value = false;
    _reinicio?.complete();
    _reinicio = null;
  }

  // ── Recibimiento (RF-BIEN-2 y RF-BIEN-21) ────────────────────────────────

  /// «Si no cabe», el último recurso. Ulises saluda ya en la conversación y
  /// la pregunta queda con sus respuestas rápidas (B-28).
  final saludoEnLaConversacion = false.obs;

  void saludarEnLaConversacion() {
    if (turno.value != TurnoB.recibimiento || saludoEnLaConversacion.value) {
      return;
    }
    saludoEnLaConversacion.value = true;
    entradas.add(BurbujaDeUlises(id: _id(), texto: TextosB.saludo));
    entradas.add(BurbujaDeUlises(id: _id(), texto: TextosB.pregunta));
  }

  /// «Sí, entrar» o «Soy nuevo». La conversación ya trae el primer grupo.
  void responderAlSaludo({required bool yaUsa}) {
    if (turno.value != TurnoB.recibimiento) return;
    if (!saludoEnLaConversacion.value) {
      entradas.add(BurbujaDeUlises(id: _id(), texto: TextosB.saludo));
      entradas.add(BurbujaDeUlises(id: _id(), texto: TextosB.pregunta));
    }
    _responder(yaUsa ? TextosB.siEntrar : TextosB.soyNuevo);
    if (yaUsa) {
      _abrirE1();
    } else {
      _abrirN1();
    }
  }

  /// En la llegada con sesión, el fin del rebote de Ulises hace de respuesta,
  /// sin respuesta del alumno.
  void ulisesAterrizoConSesion() {
    if (turno.value != TurnoB.llegadaConSesion) return;
    turno.value = null;
    entradas.add(BurbujaDeUlises(id: _id(), texto: TextosB.saludoConSesion));
    entradas.add(BurbujaDeUlises(id: _id(), texto: TextosB.faltaEspecialidad));
    _empezarElTest();
  }

  // ── «Sí, entrar» (RF-BIEN-6) ─────────────────────────────────────────────

  void _abrirE1({Duration primera = Ritmo.trasLaRespuesta}) {
    _decir(<String>[TextosB.e1], primera: primera);
    _abrir(TurnoB.e1Codigo);
  }

  void enviarCodigo() {
    if (turno.value != TurnoB.e1Codigo || esperando.value) return;
    final codigo = _login.codeController.text.trim();
    if (codigo.isEmpty) return;
    _responder(codigo);
    _decir(<String>[TextosB.e2]);
    _abrir(TurnoB.e2Contrasena);
  }

  Future<void> entrar() async {
    if (turno.value != TurnoB.e2Contrasena || esperando.value) return;
    if (_login.passwordController.text.isEmpty) return;
    // Una visita nueva no recibe el desenlace de la anterior, y su espera
    // no la apaga el login viejo (RF-BIEN-1 y BR-AUTH-F-08).
    final visita = _visita;
    esperando.value = true;
    final d = await _login.entrar();
    if (visita != _visita) return;
    esperando.value = false;
    switch (d.tipo) {
      case TipoDeDesenlace.sesionPuesta:
        // Con los dos campos todavía escritos y montados, el sistema empareja
        // el usuario con la contraseña y ofrece guardarlos. Los campos se
        // vacían después, al pasar al horario o al reiniciar (RF-BIEN-6).
        _terminarAutocompletado();
        _responder(TextosB.contrasenaLista, secreta: true);
        _trasEntrar();
      case TipoDeDesenlace.error:
        // Vuelve a E1 con el código escrito y la contraseña vacía (B-6).
        _login.passwordController.clear();
        _decirError(d.mensaje ?? TextosB.sinConexion);
        _abrir(TurnoB.e1Codigo);
      case TipoDeDesenlace.sinConexion:
        _decirError(TextosB.sinConexion);
        _abrir(TurnoB.e2Contrasena);
      case TipoDeDesenlace.cancelado:
        break;
    }
  }

  Future<void> entrarConGoogle() async {
    if (turno.value != TurnoB.e1Codigo || esperando.value) return;
    final visita = _visita;
    esperando.value = true;
    final d = await _login.entrarConGoogle();
    if (visita != _visita) return;
    esperando.value = false;
    _trasGoogle(d);
  }

  void _trasGoogle(DesenlaceDelLogin d) {
    switch (d.tipo) {
      case TipoDeDesenlace.sesionPuesta:
        _responder(TextosB.continuarConGoogle, conGoogle: true);
        _trasEntrar();
      case TipoDeDesenlace.error:
        _decirError(d.mensaje ?? TextosB.sinConexion);
      case TipoDeDesenlace.sinConexion:
        _decirError(TextosB.sinConexion);
      case TipoDeDesenlace.cancelado:
        break;
    }
  }

  /// Con la sesión puesta, un docente o un alumno completo van al horario y
  /// un alumno a medias sigue con el test, sin navegar a /setup-carrera
  /// (RF-BIEN-6 y B-10).
  void _trasEntrar() {
    final usuario = _auth.currentUser;
    if (usuario == null) return;
    _conSesion = true;
    if (postLoginRoute(usuario) == '/home') {
      _decir(<String>[TextosB.e3]);
      _abrir(TurnoB.pasoAlHorario);
      return;
    }
    _decir(<String>[TextosB.holaFaltaEspecialidad]);
    _empezarElTest();
  }

  /// «Soy nuevo» en E1 o en E2. Lo escrito no pasa de una rama a la otra.
  /// Mientras se espera un login, el compositor no responde (BR-AUTH-F-08).
  void soyNuevo() {
    final t = turno.value;
    if (t != TurnoB.e1Codigo && t != TurnoB.e2Contrasena) return;
    if (esperando.value) return;
    _responder(TextosB.soyNuevo);
    _login.vaciarCampos();
    _abrirN1();
  }

  /// Abre /forgot-password encima, con el sello en su cabecera (B-9). Es
  /// un enlace de E2.
  void abrirOlvido() {
    if (turno.value != TurnoB.e2Contrasena || esperando.value) return;
    _abrirRuta('/forgot-password');
  }

  void volverAE1() {
    if (turno.value != TurnoB.e2Contrasena || esperando.value) return;
    _abrir(TurnoB.e1Codigo);
  }

  // ── Registro (RF-BIEN-7 a RF-BIEN-9) ─────────────────────────────────────

  void _abrirN1({Duration primera = Ritmo.trasLaRespuesta}) {
    registro ??= _crearRegistro();
    _decir(<String>[TextosB.n1a, TextosB.n1b], primera: primera);
    _abrir(TurnoB.n1Codigo);
  }

  /// Cada turno valida lo suyo en local, con los validadores de hoy, antes
  /// de cerrar el compositor y sin llamar a la red (BR-REG-F-03).
  bool _valida(String? error) {
    errorLocal.value = error;
    return error == null;
  }

  void enviarCodigoDeAlumno() {
    final r = registro;
    if (r == null || turno.value != TurnoB.n1Codigo) return;
    if (!_valida(validarCodigo(r.codigoCtrl.text))) return;
    // El código es la excepción, porque su burbuja lo muestra (RF-BIEN-9).
    _responder(r.codigoCtrl.text.trim());
    _decir(<String>[TextosB.n2]);
    _abrir(TurnoB.n2Contrasena);
  }

  void enviarContrasenas() {
    final r = registro;
    if (r == null || turno.value != TurnoB.n2Contrasena) return;
    final error =
        validateNewPassword(r.passwordCtrl.text) ??
        validatePasswordConfirmation(
          r.passwordCtrl.text,
          r.confirmacionCtrl.text,
        );
    if (!_valida(error)) return;
    _responder(TextosB.contrasenaUlimaLista, secreta: true);
    // Aceptado una vez, el consentimiento dura lo que dura la rama.
    if (r.consentimientoAceptado.value) {
      _abrirN4();
    } else {
      _decir(<String>[TextosB.n3]);
      entradas.add(
        BurbujaDeUlises(
          id: _id(),
          texto: '',
          tipo: TipoDeBurbuja.consentimiento,
          pausa: Ritmo.entreBurbujas,
        ),
      );
      _abrir(TurnoB.n3Consentimiento);
    }
  }

  void aceptarConsentimiento() {
    final r = registro;
    if (r == null || turno.value != TurnoB.n3Consentimiento) return;
    r.aceptarConsentimiento();
    _responder(TextosB.acepto);
    _abrirN4();
  }

  void _abrirN4() {
    _decir(<String>[TextosB.n4]);
    _abrir(TurnoB.n4Portal);
  }

  void enviarPortal() {
    final r = registro;
    if (r == null || turno.value != TurnoB.n4Portal) return;
    if (!_valida(validarPortalPassword(r.portalPasswordCtrl.text))) return;
    _responder(TextosB.contrasenaMiUlimaLista, secreta: true);
    _abrirN5();
  }

  void _abrirN5() {
    _decir(<String>[TextosB.n5]);
    _abrir(TurnoB.n5Authenticator);
  }

  /// «Crear mi cuenta». El envío es un botón y no sale solo al completar las
  /// seis casillas (B-5).
  Future<void> crearCuenta() async {
    final r = registro;
    if (r == null || turno.value != TurnoB.n5Authenticator) return;
    if (!_valida(validarPasscode(r.passcodeCtrl.text))) return;
    _responder(TextosB.authenticatorListo, secreta: true);
    _decir(<String>[TextosB.creando, TextosB.advertencia]);
    ultimoTurno.value = TurnoB.envio;
    pildora.value = EstadoDeLaPildora.creando;
    enviando.value = true;
    await r.enviar();
    if (!identical(registro, r)) return;
    enviando.value = false;
    switch (r.paso.value) {
      case RegistroPaso.listo:
        _alCrearLaCuenta(r);
      case RegistroPaso.incierto:
        pildora.value = null;
        _decirLaDuda(r);
      case RegistroPaso.datos:
        pildora.value = null;
        _decirError(r.errorMessage.value ?? TextosB.sinConexion);
        _abrir(TurnoB.n1Codigo);
      case RegistroPaso.verificar:
      case RegistroPaso.consentimiento:
      case RegistroPaso.enviando:
        pildora.value = null;
        _decirError(r.errorMessage.value ?? TextosB.sinConexion);
        _abrir(TurnoB.n5Authenticator);
    }
  }

  void _alCrearLaCuenta(RegistroController r) {
    pildora.value = EstadoDeLaPildora.creada;
    final resultado = r.resultado.value;
    _decir(<String>[
      textoDeCuentaLista(resultado?.summary.cursos ?? 0),
    ], primera: Duration.zero);
    final avisos = resultado?.warnings ?? const [];
    if (avisos.isNotEmpty) {
      entradas.add(
        BurbujaDeUlises(
          id: _id(),
          texto: '',
          tipo: TipoDeBurbuja.avisos,
          titulo: TextosB.avisosDelRegistro,
          lineas: <String>[for (final a in avisos) a.message],
          pausa: Ritmo.entreBurbujas,
        ),
      );
    }
    _cerrarRegistro();
    _conSesion = true;
    // Sigue a otra burbuja de Ulises.
    _empezarElTest(primera: Ritmo.entreBurbujas);
  }

  /// Los títulos de hoy con un punto final, y con SIN_TOKEN el mensaje si no
  /// repite el título (RF-BIEN-8).
  void _decirLaDuda(RegistroController r) {
    final confirmada = r.cuentaConfirmada.value;
    final lineas = confirmada
        ? <String>[TextosB.creadaTitulo, TextosB.creadaTexto]
        : <String>[TextosB.inciertoTitulo, TextosB.inciertoTexto];
    final mensaje = r.errorMessage.value;
    String normal(String s) =>
        s.replaceAll(RegExp(r'[.…]'), '').trim().toLowerCase();
    if (mensaje != null && normal(mensaje) != normal(lineas.first)) {
      lineas.add(mensaje);
    }
    _decir(lineas, primera: Duration.zero);
    _abrir(TurnoB.incierto);
  }

  Future<void> iniciarSesionDesdeIncierto() async {
    final r = registro;
    if (r == null || turno.value != TurnoB.incierto || esperando.value) return;
    final visita = _visita;
    esperando.value = true;
    final entro = await r.intentarIniciarSesion();
    if (visita != _visita) return;
    esperando.value = false;
    if (!identical(registro, r)) return;
    if (!entro) {
      _decirError(r.errorMessage.value ?? TextosB.sinConexion);
      return;
    }
    _responder(TextosB.iniciarSesion);
    _cerrarRegistro();
    _conSesion = true;
    final usuario = _auth.currentUser;
    if (usuario != null && postLoginRoute(usuario) == '/home') {
      _decir(<String>[TextosB.e3]);
      _abrir(TurnoB.pasoAlHorario);
      return;
    }
    _empezarElTest();
  }

  void volverAIntentarElRegistro() {
    final r = registro;
    if (r == null || turno.value != TurnoB.incierto) return;
    r.volverAVerificar();
    _responder(TextosB.volverAIntentar);
    _abrirN5();
  }

  /// «Ya tengo cuenta», en todos los turnos del registro antes del envío y
  /// en incierto (RF-BIEN-9).
  void yaTengoCuenta() {
    const conEnlace = <TurnoDeLaBienvenida>{
      TurnoB.n1Codigo,
      TurnoB.n2Contrasena,
      TurnoB.n3Consentimiento,
      TurnoB.n4Portal,
      TurnoB.n5Authenticator,
      TurnoB.incierto,
    };
    if (!conEnlace.contains(turno.value)) return;
    _responder(TextosB.yaTengoCuenta);
    _cerrarRegistro();
    _abrirE1();
  }

  /// «Volver» reabre el turno anterior con lo escrito, y Ulises repite su
  /// pregunta (BR-REG-F-05).
  void volver() {
    final anterior = switch (turno.value) {
      TurnoB.n2Contrasena => TurnoB.n1Codigo,
      TurnoB.n3Consentimiento || TurnoB.n4Portal => TurnoB.n2Contrasena,
      TurnoB.n5Authenticator => TurnoB.n4Portal,
      _ => null,
    };
    if (anterior == null) return;
    _responder(TextosB.volver);
    final pregunta = switch (anterior) {
      TurnoB.n1Codigo => TextosB.n1b,
      TurnoB.n2Contrasena => TextosB.n2,
      _ => TextosB.n4,
    };
    _decir(<String>[pregunta]);
    _abrir(anterior);
  }

  // ── Test (RF-BIEN-10 y RF-BIEN-21) ───────────────────────────────────────

  /// T0. La bienvenida crea el controlador del test ella misma, sin
  /// Get.put, y pide el contenido una vez (B-34 y enmienda a RF-TEST-2).
  void _empezarElTest({Duration primera = Ritmo.trasLaRespuesta}) {
    _cerrarTest();
    _testDisponible = true;
    ultimoTurno.value = TurnoB.t0Invitacion;
    final t = test = _crearTest(_UiDeLaBienvenida(this));
    _idDeLaCarga = _id();
    entradas.add(
      BurbujaDeUlises(
        id: _idDeLaCarga!,
        texto: '',
        tipo: TipoDeBurbuja.cargando,
        pausa: primera,
      ),
    );
    _trabajosDelTest.addAll(<Worker>[
      ever<EstadoDeCarga>(t.carga, (_) => _alCambiarLaCarga()),
      ever<FaseDelTest>(t.fase, _alCambiarLaFase),
      ever<int>(t.paso, _alCambiarElPaso),
      ever<SpecialtyTestFailure?>(t.errorDeEspera, _alFallarLaEspera),
    ]);
    t.onStart();
    _alCambiarLaCarga();
  }

  void _reemplazarLaCarga(
    String texto, {
    TipoDeBurbuja tipo = TipoDeBurbuja.texto,
  }) {
    final id = _idDeLaCarga;
    _idDeLaCarga = null;
    final i = id == null ? -1 : entradas.indexWhere((e) => e.id == id);
    final burbuja = BurbujaDeUlises(
      id: i >= 0 ? id! : _id(),
      texto: texto,
      tipo: tipo,
      pausa: i >= 0 ? entradas[i].pausa : Duration.zero,
    );
    if (i >= 0) {
      entradas[i] = burbuja;
    } else {
      entradas.add(burbuja);
    }
  }

  void _alCambiarLaCarga() {
    final t = test;
    if (t == null) return;
    switch (t.carga.value) {
      case EstadoDeCarga.cargando:
        break;
      case EstadoDeCarga.lista:
        // Solo la carga de T0 trae su invitación. La de «Empezar de nuevo»
        // abre la pregunta 1 sola.
        if (_idDeLaCarga == null) return;
        if (t.fase.value != FaseDelTest.bienvenida) return;
        _reemplazarLaCarga(
          TextosB.invitacionAlTest(t.contenido.value!.totalQuestions),
        );
        _faseMostrada = FaseDelTest.bienvenida;
        _pasoMostrado = t.paso.value;
        _abrir(TurnoB.t0Invitacion);
      case EstadoDeCarga.error:
        // También cuando falla la carga de «Empezar de nuevo», que no tiene
        // burbuja de carga, así que el turno no queda sin salida.
        _reemplazarLaCarga(TextosB.noCargoElTest, tipo: TipoDeBurbuja.error);
        _abrir(TurnoB.t0Invitacion);
        unawaited(_trasUnFalloConSesion());
    }
  }

  void empezarElTest() {
    final t = test;
    if (t == null || turno.value != TurnoB.t0Invitacion) return;
    if (t.carga.value != EstadoDeCarga.lista) return;
    _responder(TextosB.empezarElTest);
    t.empezar();
  }

  void saltarElTest() {
    final t = test;
    if (t == null || turno.value != TurnoB.t0Invitacion) return;
    _responder(TextosB.saltar);
    _saltando = true;
    t.saltar();
    _saltando = false;
  }

  void reintentarElContenido() {
    final t = test;
    if (t == null || t.carga.value != EstadoDeCarga.error) return;
    _responder(TextosB.reintentar);
    _idDeLaCarga = _id();
    entradas.add(
      BurbujaDeUlises(
        id: _idDeLaCarga!,
        texto: '',
        tipo: TipoDeBurbuja.cargando,
        pausa: Ritmo.trasLaRespuesta,
      ),
    );
    t.reintentarCarga();
  }

  /// Con [conLector], la pregunta no avanza sola y espera «Siguiente»
  /// (RF-TEST-5 y RF-TEST-13).
  void responderAlTest(String valor, {bool conLector = false}) {
    if (turno.value != TurnoB.pregunta && turno.value != TurnoB.desempate) {
      return;
    }
    test?.responder(valor, avanceSolo: !conLector);
  }

  void siguiente() => test?.avanzar();

  void preguntaAnterior() {
    final t = test;
    if (t == null) return;
    const conEnlace = <TurnoDeLaBienvenida>{
      TurnoB.pregunta,
      TurnoB.desempate,
      TurnoB.espera,
    };
    if (!conEnlace.contains(ultimoTurno.value)) return;
    _responder(TextosB.preguntaAnterior);
    _volviendo = true;
    t.atras();
  }

  void reintentarLaEvaluacion() {
    final t = test;
    if (t == null || t.errorDeEspera.value == null) return;
    _responder(TextosB.reintentar);
    t.reintentarEvaluacion();
    _decir(<String>[
      ?t.contenido.value?.ulises.loading,
    ], tipo: TipoDeBurbuja.esperando);
  }

  void empezarDeNuevo() {
    if (!pideReinicio.value) return;
    pideReinicio.value = false;
    _responder(TextosB.empezarDeNuevo);
    _volviendo = true;
    _reinicio?.complete();
    _reinicio = null;
  }

  Future<void> elegirComoPrincipal(int especialidad) async {
    _botonQueGuarda = TextosB.elegirComoPrincipal;
    await test?.elegirPrincipal(especialidad);
  }

  Future<void> decidirDespues() async {
    _botonQueGuarda = TextosB.decidirDespues;
    await test?.decidirDespues();
  }

  void rehacerElTest() {
    final t = test;
    if (t == null || t.resultado.value == null) return;
    // El resultado queda en la conversación, de solo lectura, con los
    // corazones que tenía (RF-BIEN-5).
    final i = entradas.lastIndexWhere(
      (e) => e is ResultadoDelTest && e.corazones == null,
    );
    if (i >= 0) {
      entradas[i] = (entradas[i] as ResultadoDelTest).congelado(t.corazones);
    }
    _responder(TextosB.rehacerElTest);
    _volviendo = true;
    t.rehacer();
  }

  void alternarCorazon(int especialidad) => test?.alternarCorazon(especialidad);

  /// La fase del test cambió. Cada cambio de fase es un turno nuevo, y al
  /// pasar de una pregunta a la espera entra la respuesta a esa pregunta.
  /// Los cambios de paso dentro de una fase que no es la de preguntas, como
  /// el paso 0 de «Rehacer el test» con el resultado todavía a la vista, no
  /// dicen nada.
  void _alCambiarLaFase(FaseDelTest fase) {
    final t = test;
    final c = t?.contenido.value;
    if (t == null || c == null || fase == _faseMostrada) return;
    final venia = _faseMostrada;
    _faseMostrada = fase;
    switch (fase) {
      case FaseDelTest.bienvenida:
        _decir(<String>[TextosB.invitacionAlTest(c.totalQuestions)]);
        _abrir(TurnoB.t0Invitacion);
      case FaseDelTest.pregunta:
        _decirElPaso(t, c, t.paso.value);
      case FaseDelTest.espera:
        if (venia == FaseDelTest.pregunta && !_volviendo) {
          _responder(_textoDeLaRespuesta(t, c, _pasoMostrado));
        }
        final lineas = turnoDeEspera(c, trasDesempate: t.esperaTrasDesempate);
        _decirConSello(lineas.lineas, lineas.sello, ultimaEsperando: true);
        _abrir(TurnoB.espera);
      case FaseDelTest.resultado:
        _decirElResultado(t);
    }
    _volviendo = false;
    _pasoMostrado = t.paso.value;
  }

  /// El paso cambió dentro de las preguntas. Si el alumno avanzó, entra su
  /// respuesta al paso que deja, y Ulises dice el paso nuevo. Con «Pregunta
  /// anterior» no entra ninguna respuesta más.
  void _alCambiarElPaso(int paso) {
    final t = test;
    final c = t?.contenido.value;
    if (t == null || c == null) return;
    if (t.fase.value != FaseDelTest.pregunta ||
        _faseMostrada != FaseDelTest.pregunta ||
        paso == _pasoMostrado) {
      return;
    }
    if (paso > _pasoMostrado && !_volviendo) {
      _responder(_textoDeLaRespuesta(t, c, _pasoMostrado));
    }
    _volviendo = false;
    _pasoMostrado = paso;
    _decirElPaso(t, c, paso);
  }

  /// Ulises dice [lineas], con el sello junto a la primera, que es el
  /// `blockClose` (RF-TEST-4).
  void _decirConSello(
    List<String> lineas,
    SelloDeBloque? sello, {
    bool ultimaEsperando = false,
  }) {
    for (var i = 0; i < lineas.length; i++) {
      final ultima = i == lineas.length - 1;
      entradas.add(
        BurbujaDeUlises(
          id: _id(),
          texto: lineas[i],
          sello: i == 0 ? sello : null,
          tipo: ultima && ultimaEsperando
              ? TipoDeBurbuja.esperando
              : TipoDeBurbuja.texto,
          pausa: i == 0 ? Ritmo.trasLaRespuesta : Ritmo.entreBurbujas,
        ),
      );
    }
  }

  void _decirElPaso(
    SpecialtyTestController t,
    SpecialtyTestContent c,
    int paso,
  ) {
    if (paso < c.totalQuestions) {
      final previo = turnoAntesDePregunta(
        c,
        paso,
        Map<String, String>.of(t.respuestas),
      );
      final q = c.questions[paso];
      _decirConSello(previo.lineas, previo.sello);
      // En una escala, la tarea en negrita y debajo el prompt.
      entradas.add(
        BurbujaDeUlises(
          id: _id(),
          texto: q.prompt,
          titulo: q.isDuel ? null : q.task?.text,
          pausa: previo.lineas.isEmpty
              ? Ritmo.trasLaRespuesta
              : Ritmo.entreBurbujas,
        ),
      );
      _abrir(TurnoB.pregunta);
      return;
    }
    final d = t.desempateActual!;
    final previo = turnoAntesDeDesempate(d);
    _decirConSello(previo.lineas, null);
    entradas.add(
      BurbujaDeUlises(
        id: _id(),
        texto: d.tiebreak.prompt,
        pausa: previo.lineas.isEmpty
            ? Ritmo.trasLaRespuesta
            : Ritmo.entreBurbujas,
      ),
    );
    _abrir(TurnoB.desempate);
  }

  String _textoDeLaRespuesta(
    SpecialtyTestController t,
    SpecialtyTestContent c,
    int paso,
  ) {
    if (paso < 0) return '';
    if (paso < c.totalQuestions) {
      final q = c.questions[paso];
      final valor = t.respuestas[q.id] ?? '';
      if (!q.isDuel) {
        final i = c.scaleOptions.indexWhere((o) => o.id == valor);
        final etiqueta = c.optionLabel(valor) ?? valor;
        return i >= 0 ? '${emojisDeLaEscala[i]} $etiqueta' : etiqueta;
      }
      return textoDeRespuesta(c, tareas: [q.top!, q.bottom!], respuesta: valor);
    }
    final i = paso - c.totalQuestions;
    if (i >= t.desempates.length) return '';
    final d = t.desempates[i];
    return textoDeRespuesta(
      c,
      tareas: [d.tiebreak.top, d.tiebreak.bottom],
      respuesta: d.answer ?? '',
    );
  }

  void _decirElResultado(SpecialtyTestController t) {
    final r = t.resultado.value;
    if (r == null) return;
    confeti.value++;
    _decir(<String>[?r.headline, ?r.tiebreakOutcome]);
    entradas.add(
      ResultadoDelTest(
        id: _id(),
        resultado: r,
        contenido: t.contenido.value!,
        pausa: Ritmo.entreBurbujas,
      ),
    );
    _abrir(TurnoB.resultado);
  }

  void _alFallarLaEspera(SpecialtyTestFailure? fallo) {
    final t = test;
    if (t == null || fallo == null) return;
    _decirError(t.textoDelErrorDeEspera);
    _abrir(TurnoB.espera);
    unawaited(_trasUnFalloConSesion());
  }

  void _volverAT0() {
    final t = test;
    final c = t?.contenido.value;
    if (t == null || c == null || !_testDisponible) return;
    _decir(<String>[TextosB.invitacionAlTest(c.totalQuestions)]);
    _abrir(TurnoB.t0Invitacion);
  }

  // Lo que el controlador del test le pide a la conversación.

  void _aLaSeleccionManual() {
    // Sin el toque de «Saltar», la salida viene de un 404 y el test no está
    // disponible (RF-TEST-1).
    if (!_saltando) {
      _testDisponible = false;
      // La burbuja de carga no llega a su invitación.
      final id = _idDeLaCarga;
      if (id != null) entradas.removeWhere((e) => e.id == id);
      _cerrarTest();
    }
    principalManual.value = _auth.currentUser?.especialidadPrincipal;
    interesesManuales.assignAll(
      _auth.currentUser?.especialidadesInteres ?? const <int>[],
    );
    _decir(<String>[TextosB.eligeMencion]);
    catalogoFallido.value =
        _auth.catalogsFailed || especialidadesOficiales.isEmpty;
    if (catalogoFallido.value) {
      _decirError(TextosB.noCargaronEspecialidades);
    }
    _abrir(TurnoB.seleccionManual);
  }

  void _despedirseDelTest() {
    _responder(_botonQueGuarda ?? TextosB.elegirComoPrincipal);
    _botonQueGuarda = null;
    _decir(<String>[TextosB.listoAlHorario]);
    _abrir(TurnoB.pasoAlHorario);
  }

  void _avisoDelTest(AvisoDelTest aviso) {
    _decirError(aviso.mensaje);
    unawaited(_trasUnFalloConSesion());
  }

  Future<void> _pedirReinicio(String mensaje) {
    _decirError(mensaje);
    pideReinicio.value = true;
    _abrir(TurnoB.espera);
    final reinicio = _reinicio = Completer<void>();
    return reinicio.future;
  }

  // ── Selección manual (RF-TEST-1 y RF-TEST-14) ────────────────────────────

  /// Solo las oficiales de la carrera, en su orden (RF-TEST-14).
  List<Map<String, dynamic>> get especialidadesOficiales {
    final carrera = _auth.currentUser?.careerId;
    if (carrera == null) return const <Map<String, dynamic>>[];
    final oficiales = _auth.officialSpecialtyIds;
    final lista = _auth.especialidades
        .where(
          (e) =>
              e['carrera_id'] == carrera &&
              oficiales.contains(int.tryParse('${e['id']}')),
        )
        .toList();
    lista.sort(
      (a, b) => ((a['display_order'] as num?) ?? 999).compareTo(
        (b['display_order'] as num?) ?? 999,
      ),
    );
    return lista;
  }

  void marcarPrincipal(int especialidad) {
    if (principalManual.value == especialidad) {
      principalManual.value = null;
    } else {
      principalManual.value = especialidad;
      interesesManuales.remove(especialidad);
    }
  }

  void alternarInteres(int especialidad) {
    if (principalManual.value == especialidad) return;
    if (!interesesManuales.remove(especialidad)) {
      interesesManuales.add(especialidad);
    }
  }

  Future<void> terminarLaSeleccion() async {
    if (turno.value != TurnoB.seleccionManual || esperando.value) return;
    final carrera = _auth.currentUser?.careerId;
    if (carrera == null) {
      _decirError(TextosB.sinCarrera);
      return;
    }
    final seleccion = seleccionOficial(
      principal: principalManual.value,
      intereses: interesesManuales,
      oficiales: _auth.officialSpecialtyIds,
    );
    final visita = _visita;
    esperando.value = true;
    try {
      await _auth.completeSetup(
        careerId: carrera,
        especialidadPrincipal: seleccion.principal,
        especialidadesInteres: seleccion.intereses,
      );
    } catch (_) {
      if (visita != _visita) return;
      esperando.value = false;
      // La spec no fija este texto (decisión 8 del plan).
      _decirError(TextosDelTest.noSeGuardo);
      unawaited(_trasUnFalloConSesion());
      return;
    }
    if (visita != _visita) return;
    esperando.value = false;
    _botonQueGuarda = seleccion.principal == null && seleccion.intereses.isEmpty
        ? TextosB.saltarPorAhora
        : TextosB.finalizar;
    _despedirseDelTest();
  }

  Future<void> reintentarElCatalogo() async {
    if (turno.value != TurnoB.seleccionManual || esperando.value) return;
    final visita = _visita;
    esperando.value = true;
    final cargo = await _auth.reloadCatalogs();
    if (visita != _visita) return;
    esperando.value = false;
    catalogoFallido.value = !cargo || especialidadesOficiales.isEmpty;
    if (catalogoFallido.value) {
      _decirError(TextosB.noCargaronEspecialidades);
      unawaited(_trasUnFalloConSesion());
    }
  }

  // ── El 401 dentro de la conversación (RF-BIEN-12 y B-22) ─────────────────

  /// En /login el interceptor del 401 borra la sesión y no navega, así que
  /// tras cada fallo de un turno con sesión se mira si el token sigue.
  Future<void> _trasUnFalloConSesion() async {
    if (!_conSesion) return;
    final token = await _tokenGuardado();
    if (token != null && token.isNotEmpty) return;
    // La misma limpieza local que logout, sin red porque no hay token.
    await _auth.logout();
    _reiniciar();
    _decirError(TextosB.sesionCaducada);
    _abrirE1(primera: Ritmo.entreBurbujas);
  }

  // ── Atrás (RF-BIEN-13) ───────────────────────────────────────────────────

  AccionDelAtras get _accionDelAtras => accionDelAtras(
    ultimoTurno.value ?? TurnoB.recibimiento,
    testDisponible: _testDisponible,
  );

  bool get atrasSaleDeLaApp => _accionDelAtras == AccionDelAtras.salirDeLaApp;

  void atras() {
    // Mientras se espera una respuesta, el atrás tampoco hace nada.
    if (esperando.value) return;
    switch (_accionDelAtras) {
      case AccionDelAtras.volverAE1:
        volverAE1();
      case AccionDelAtras.yaTengoCuenta:
        yaTengoCuenta();
      case AccionDelAtras.volver:
        volver();
      case AccionDelAtras.avisarQueSeEnvia:
        _avisar(TextosB.avisoEnvioTitulo, TextosB.avisoEnvioTexto);
      case AccionDelAtras.volverAIntentar:
        volverAIntentarElRegistro();
      case AccionDelAtras.preguntaAnterior:
        preguntaAnterior();
      case AccionDelAtras.irAT0:
        _volverAT0();
      case AccionDelAtras.salirDeLaApp:
      case AccionDelAtras.nada:
        break;
    }
  }

  // ── Paso al horario (RF-BIEN-11) ─────────────────────────────────────────

  /// La página entregó el paso a la capa y navegó a /home. Se cierran los
  /// tramos, se borra el historial y se vacían los campos.
  void pasoHecho() => _reiniciar();
}

/// La pantalla del test dentro de la conversación (B-34).
class _UiDeLaBienvenida implements SpecialtyTestUi {
  _UiDeLaBienvenida(this._bienvenida);

  final BienvenidaController _bienvenida;

  @override
  void cerrar([SalidaDelTest? salida]) {
    if (salida == SalidaDelTest.seleccionManual) {
      _bienvenida._aLaSeleccionManual();
    }
  }

  @override
  void irAlHome() => _bienvenida._despedirseDelTest();

  @override
  void avisar(AvisoDelTest aviso) => _bienvenida._avisoDelTest(aviso);

  @override
  Future<void> pedirReinicio(String mensaje) =>
      _bienvenida._pedirReinicio(mensaje);
}
