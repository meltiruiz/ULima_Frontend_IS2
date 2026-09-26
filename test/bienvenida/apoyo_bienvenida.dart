// test/bienvenida/apoyo_bienvenida.dart
//
// Apoyo de las pruebas de la bienvenida. No termina en _test.dart, así que
// `flutter test` no lo corre como suite. Todo dato es inventado.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/domain/bienvenida/bienvenida_turnos.dart';
import 'package:ulima_plus/models/portal_sync_models.dart';
import 'package:ulima_plus/models/registro_models.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/bienvenida/bienvenida_controller.dart';
import 'package:ulima_plus/pages/bienvenida/bienvenida_page.dart';
import 'package:ulima_plus/pages/bienvenida/conversacion.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/compositor.dart';
import 'package:ulima_plus/pages/login/login_controller.dart';
import 'package:ulima_plus/pages/registro/registro_controller.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_logic.dart';
import 'package:ulima_plus/pages/splash/capa_de_arranque.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/registro_service.dart';
import 'package:ulima_plus/services/session_navigation.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';
import 'package:ulima_plus/services/storage_service.dart';

import '../HU36_jeff/dobles_de_red.dart';

UserModel alumnaDePrueba({bool setupComplete = true, int? careerId = 1}) =>
    UserModel(
      code: '20230001',
      firstName: 'Alumna',
      lastName: 'De Prueba',
      email: 'test@aloe.ulima.edu.pe',
      role: 'student',
      careerId: careerId,
      currentCycle: '2026-2',
      setupComplete: setupComplete,
    );

UserModel docenteDePrueba() => UserModel(
  code: 'docente.test',
  firstName: 'Docente',
  lastName: 'De Prueba',
  email: 'docente.test@ulima.edu.pe',
  role: 'teacher',
  currentCycle: '2026-2',
  setupComplete: true,
);

/// Lo que `AuthService.login` no atrapa.
class RedCaida implements Exception {
  const RedCaida();
}

/// Un AuthService sin red. [alEntrar] es el usuario que queda al entrar.
class AuthDeLaBienvenida extends AuthService {
  AuthDeLaBienvenida({
    this.usuario,
    this.alEntrar,
    this.errorDeLogin,
    this.redCaida = false,
    this.google,
  });

  UserModel? usuario;
  UserModel? alEntrar;
  String? errorDeLogin;
  bool redCaida;

  /// Lo que devuelve Google, con 'cancelar' para el selector cerrado.
  String? google;
  int logouts = 0;
  int logins = 0;

  /// Si no es null, `login` espera a este Completer, como un login lento.
  Completer<String?>? loginPendiente;

  /// Cada login, con código o con Google, cada guardado y cada recarga del
  /// catálogo esperan al primero de estos antes de responder, como una red
  /// lenta.
  final List<Completer<void>> esperas = <Completer<void>>[];

  Future<void> _esperar() async {
    if (esperas.isNotEmpty) await esperas.removeAt(0).future;
  }

  @override
  UserModel? get currentUser => usuario;

  @override
  Future<String?> login({
    required String code,
    required String password,
  }) async {
    logins++;
    final pendiente = loginPendiente;
    if (pendiente != null) return pendiente.future;
    await _esperar();
    if (redCaida) throw const RedCaida();
    if (errorDeLogin != null) return errorDeLogin;
    usuario = alEntrar ?? alumnaDePrueba();
    return null;
  }

  @override
  Future<String?> loginWithGoogle() async {
    logins++;
    await _esperar();
    if (google == 'cancelar') return null;
    if (google != null) return google;
    usuario = alEntrar ?? alumnaDePrueba();
    return null;
  }

  @override
  Future<void> logout() async {
    logouts++;
    usuario = null;
  }

  final List<SeleccionDeEspecialidades> guardados =
      <SeleccionDeEspecialidades>[];
  Object? falloAlGuardar;
  bool catalogoFalla = false;

  @override
  Future<void> completeSetup({
    required int careerId,
    int? especialidadPrincipal,
    required List<int> especialidadesInteres,
    Duration? timeout,
  }) async {
    await _esperar();
    if (falloAlGuardar != null) throw falloAlGuardar!;
    guardados.add(
      SeleccionDeEspecialidades(
        principal: especialidadPrincipal,
        intereses: List<int>.of(especialidadesInteres),
      ),
    );
    usuario?.setupComplete = true;
  }

  @override
  List<Map<String, dynamic>> get especialidades => catalogoFalla
      ? const <Map<String, dynamic>>[]
      : <Map<String, dynamic>>[
          for (final (id, nombre, orden) in const [
            (1, 'Ingeniería de Software', 1),
            (5, 'Tecnologías de Información', 2),
            (6, 'Sistemas Inteligentes', 3),
            (7, 'Videojuegos', 4),
          ])
            <String, dynamic>{
              'id': id,
              'carrera_id': 1,
              'name': nombre,
              'display_order': orden,
              'is_active': true,
            },
        ];

  @override
  Set<int> get officialSpecialtyIds => catalogoFalla ? <int>{} : {1, 5, 6, 7};

  @override
  bool get catalogsFailed => catalogoFalla;

  /// La recarga del catálogo vuelve a fallar.
  bool recargaFalla = false;

  @override
  Future<bool> reloadCatalogs() async {
    await _esperar();
    if (recargaFalla) return false;
    catalogoFalla = false;
    return true;
  }
}

/// Un RegistroService sin red. Responde con [resultado], lanza [fallo] o
/// espera a [pendiente], y cuenta las llamadas.
class RegistroFalso implements RegistroService {
  RegistroFalso({this.resultado, this.fallo, this.pendiente});

  RegistroResult? resultado;
  RegistroFailure? fallo;
  Completer<RegistroResult>? pendiente;
  int llamadas = 0;

  @override
  Future<RegistroResult> registrar({
    required String code,
    required String portalPassword,
    required String passcode,
    required String password,
    required bool consent,
  }) async {
    llamadas++;
    if (pendiente != null) return pendiente!.future;
    if (fallo != null) throw fallo!;
    return resultado!;
  }
}

RegistroResult resultadoDelRegistro({
  int cursos = 5,
  List<String> avisos = const <String>[],
}) => RegistroResult(
  token: 'jwt-de-prueba',
  user: alumnaDePrueba(setupComplete: false),
  summary: PortalSyncSummary(
    coursesCreated: 0,
    sectionsCreated: 0,
    sectionsUpdated: 0,
    sessionsUpserted: 12,
    enrollmentsUpserted: cursos,
    enrollmentsWithdrawn: 0,
    progressUpserted: 40,
    syllabiUpserted: 0,
  ),
  warnings: <PortalSyncWarning>[
    for (final a in avisos)
      PortalSyncWarning.fromJson(<String, dynamic>{
        'code': 'AVISO',
        'message': a,
      }),
  ],
);

/// El controlador de la bienvenida con sus dobles, fuera de GetX.
class Bienvenida {
  Bienvenida({
    AuthDeLaBienvenida? auth,
    this.token,
    RegistroFalso? registro,
    this.adoptarFalla = false,
    bool avisosDeGetX = false,
    ApiFalsaDelTest? apiDelTest,
    Future<String?> Function()? tokenGuardado,
    RegistroController Function()? crearRegistro,
  }) : auth = auth ?? AuthDeLaBienvenida(),
       servicioDeRegistro =
           registro ?? RegistroFalso(resultado: resultadoDelRegistro()) {
    Get.testMode = true;
    Get.put<AuthService>(this.auth);
    Get.put<SpecialtyTestService>(
      SpecialtyTestService(apiClient: apiDelTest ?? ApiFalsaDelTest()),
    );
    login = LoginController();
    controlador = BienvenidaController(
      auth: this.auth,
      login: login,
      tokenGuardado: tokenGuardado ?? () async => token,
      abrirRuta: rutas.add,
      terminarAutocompletado: () => autocompletados.add((
        codigo: login.codeController.text,
        contrasena: login.passwordController.text,
      )),
      crearRegistro:
          crearRegistro ??
          () => RegistroController(
            service: servicioDeRegistro,
            adoptarSesion: ({required token, required user}) async {
              if (adoptarFalla) throw StateError('sin catálogos');
              this.auth.usuario = user;
            },
            iniciarSesion: ({required code, required password}) =>
                this.auth.login(code: code, password: password),
          ),
      // Con avisosDeGetX, el Get.snackbar de la bienvenida.
      avisar: avisosDeGetX ? null : (titulo, texto) => avisos.add(titulo),
    )..onStart();
  }

  final AuthDeLaBienvenida auth;
  final RegistroFalso servicioDeRegistro;
  final bool adoptarFalla;

  /// Los títulos de los avisos que salen abajo (B-29).
  final List<String> avisos = <String>[];
  String? token;
  final List<String> rutas = <String>[];

  /// Cada cierre del autocompletado, con lo que tenían los campos en ese
  /// momento (RF-BIEN-6).
  final List<({String codigo, String contrasena})> autocompletados =
      <({String codigo, String contrasena})>[];
  late final LoginController login;
  late final BienvenidaController controlador;

  /// Lo que dice Ulises. Las burbujas sin texto, como la de carga o la
  /// tarjeta del consentimiento, no cuentan.
  List<String> get deUlises => <String>[
    for (final e in controlador.entradas)
      if (e is BurbujaDeUlises && e.texto.isNotEmpty) e.texto,
  ];

  List<String> get delAlumno => <String>[
    for (final e in controlador.entradas)
      if (e is RespuestaDelAlumno) e.texto,
  ];

  /// Empieza una visita nueva, como el primer cuadro de la página.
  Future<void> visitar({MotivoDeLlegada? motivo}) async {
    final v = controlador.nuevaVisita();
    await controlador.empezarVisita(v, motivo: motivo);
  }
}

/// Monta /login con la bienvenida real y los controladores de [b], y llega
/// con [argumentos], como la intro o offAllToLogin.
Future<void> montarLaBienvenida(
  WidgetTester tester,
  Bienvenida b, {
  Map<String, Object>? argumentos,
  Brightness brillo = Brightness.light,
  Size pantalla = const Size(375, 667),
  double escala = 1,
  bool conLector = false,
  bool sinMovimiento = false,
  bool conCapa = false,
  Widget Function()? home,
}) async {
  tester.view.physicalSize = pantalla * 2;
  tester.view.devicePixelRatio = 2;
  tester.view.display.size = pantalla * 2;
  tester.view.display.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  addTearDown(tester.view.display.reset);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(
        accessibleNavigation: conLector,
        disableAnimations: sinMovimiento,
      );
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  Get.put<LoginController>(b.login, permanent: true);
  Get.put<BienvenidaController>(b.controlador, permanent: true);
  const tema = MaterialTheme(TextTheme());
  await tester.pumpWidget(
    GetMaterialApp(
      theme: brillo == Brightness.light ? tema.light() : tema.dark(),
      home: const SizedBox.shrink(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(escala)),
        // Con la capa del arranque, como el builder de MyApp (RF-SPL-4).
        child: conCapa ? CapaDeArranque(child: child!) : child!,
      ),
      getPages: [
        GetPage(name: '/login', page: () => const BienvenidaPage()),
        GetPage(name: '/forgot-password', page: () => const Text('olvido')),
        GetPage(name: '/home', page: home ?? () => const Text('home')),
      ],
    ),
  );
  Get.offAll<void>(
    () => const BienvenidaPage(),
    routeName: '/login',
    arguments: argumentos,
    transition: Transition.noTransition,
  );
  await tester.pump();
  await tester.pump();
}

/// Avanza [ms] en cuadros de 16 ms.
Future<void> avanzar(WidgetTester tester, int ms) async {
  for (var t = 0; t < ms; t += 16) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// Un StorageService sin sesión guardada, para montar la ruta real de /login.
class StorageSinToken extends StorageService {
  @override
  Future<String?> get savedToken async => null;
}

/// Registra, sin red, los servicios que lee la bienvenida que crea
/// LoginBinding, como en la app real.
AuthDeLaBienvenida registrarLosServiciosDeLaBienvenida() {
  Get.testMode = true;
  final auth = AuthDeLaBienvenida();
  Get.put<AuthService>(auth);
  Get.put<StorageService>(StorageSinToken());
  return auth;
}

/// Desde el recibimiento, toca «Sí, entrar» y espera el compositor de E1.
Future<void> llegarAE1(WidgetTester tester) async {
  await avanzar(tester, 2800);
  await tester.tap(find.text(TextosDeLaBienvenida.siEntrar));
  await avanzar(tester, 2600);
}

/// Desde E1, envía [codigo] y espera el compositor de E2.
Future<void> llegarAE2(
  WidgetTester tester, {
  String codigo = '20230001',
}) async {
  await tester.enterText(find.byType(TextField).first, codigo);
  // Un cuadro tras teclear, para que el botón de envío se encienda.
  await tester.pump();
  await tester.tap(find.byType(BotonDeEnvio));
  await avanzar(tester, 2000);
}

/// Carga Roboto del SDK de Flutter con el nombre de familia del tema, para
/// medir el texto como en la app. Con la letra de prueba, todas las
/// familias miden lo mismo.
Future<void> cargarRoboto() async {
  final raiz = Platform.environment['FLUTTER_ROOT'];
  expect(
    raiz,
    isNotNull,
    reason: 'flutter test fija FLUTTER_ROOT; sin él no hay Roboto que medir',
  );
  final archivo = File(
    '$raiz/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
  );
  expect(archivo.existsSync(), isTrue, reason: archivo.path);
  final cargador = FontLoader('Roboto')
    ..addFont(
      Future<ByteData>.value(ByteData.sublistView(archivo.readAsBytesSync())),
    );
  await cargador.load();
}
