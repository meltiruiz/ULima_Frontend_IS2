// test/bienvenida/bienvenida_ruta_test.dart
//
// UNITARIA + WIDGET · Bienvenida con Ulises
// (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-1 y B-21. offAllToLogin suma el motivo de la llegada como argumento
// de ruta. El 401 pasa `expirada` y su aviso sale abajo (B-29). El cierre de
// sesión y «Volver a iniciar sesión» del Perfil no pasan motivo. Cada montaje
// es una visita, con el primer cuadro sacado de los argumentos, el reinicio
// que cierra los tramos, y lo que una visita vieja deja en vuelo, que no toca
// la nueva. La ruta /login muestra la bienvenida, con LoginBinding, y
// /registro ya no existe.
// Archivos probados lib/services/session_navigation.dart,
// lib/services/api_client.dart,
// lib/pages/bienvenida/bienvenida_controller.dart y
// lib/pages/bienvenida/bienvenida_page.dart.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ulima_plus/domain/bienvenida/bienvenida_turnos.dart';
import 'package:ulima_plus/main.dart';
import 'package:ulima_plus/models/registro_models.dart';
import 'package:ulima_plus/pages/bienvenida/bienvenida_controller.dart';
import 'package:ulima_plus/pages/bienvenida/bienvenida_page.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/compositor.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/recibimiento.dart';
import 'package:ulima_plus/pages/login/login_binding.dart';
import 'package:ulima_plus/pages/login/login_controller.dart';
import 'package:ulima_plus/pages/registro/registro_controller.dart';
import 'package:ulima_plus/pages/splash/salidas.dart' show naranjaDelSplash;
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/session_navigation.dart';
import 'package:ulima_plus/services/storage_service.dart';

import 'apoyo_bienvenida.dart';

class _StorageEspia extends StorageService {
  int cierres = 0;

  @override
  Future<void> clearSession() async => cierres++;

  @override
  Future<String?> get savedToken async => 'token-guardado';
}

Widget _pagina(String texto) => Scaffold(body: Center(child: Text(texto)));

Widget _app() => GetMaterialApp(
  initialRoute: '/perfil',
  getPages: [
    GetPage(name: '/perfil', page: () => _pagina('perfil')),
    GetPage(name: '/login', page: () => _pagina('login')),
  ],
);

Object? _argumentosDe(WidgetTester tester, String texto) =>
    ModalRoute.of(tester.element(find.text(texto)))!.settings.arguments;

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  group('el motivo de la llegada (RF-BIEN-1 y B-21)', () {
    testWidgets('offAllToLogin pasa el motivo como argumento de ruta', (
      tester,
    ) async {
      await tester.pumpWidget(_app());
      expect(offAllToLogin(motivo: MotivoDeLlegada.restablecida), isTrue);
      await tester.pumpAndSettle();
      expect(_argumentosDe(tester, 'login'), {
        argumentoDeMotivo: MotivoDeLlegada.restablecida,
      });
    });

    testWidgets('sin motivo no pasa argumentos, como el cierre de sesión', (
      tester,
    ) async {
      await tester.pumpWidget(_app());
      expect(offAllToLogin(), isTrue);
      await tester.pumpAndSettle();
      expect(_argumentosDe(tester, 'login'), isNull);
    });

    test(
      '«Volver a iniciar sesión» del Perfil sigue siendo un VoidCallback',
      () {
        // perfil.dart:101 usa `onPressed: offAllToLogin`.
        const VoidCallback boton = offAllToLogin;
        expect(boton, isNotNull);
      },
    );

    testWidgets('el 401 borra la sesión, llega con `expirada` y su aviso sale '
        'abajo (B-29)', (tester) async {
      final espia = _StorageEspia();
      Get.put<StorageService>(espia);
      await tester.pumpWidget(_app());
      final servidor = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {'code': 'UNAUTHORIZED', 'message': 'Token inválido'},
          }),
          401,
          headers: {'content-type': 'application/json'},
        ),
      );
      await tester.runAsync(
        () => http.runWithClient(() async {
          try {
            await ApiClient(
              configuredBaseUrl: 'http://test',
            ).getJson('/alerts/me');
          } catch (_) {}
        }, () => servidor),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(espia.cierres, 1);
      expect(Get.currentRoute, '/login');
      expect(_argumentosDe(tester, 'login'), {
        argumentoDeMotivo: MotivoDeLlegada.expirada,
      });
      final aviso = tester.widget<GetSnackBar>(find.byType(GetSnackBar));
      expect(aviso.snackPosition, SnackPosition.BOTTOM);
      expect(find.text('Sesión expirada'), findsOneWidget);
      // El aviso nació dentro de runAsync, así que su temporizador de 3 s es
      // real y dispararía en otra prueba. Cerrarlo aquí lo cancela.
      Get.closeAllSnackbars();
      await tester.pumpAndSettle();
      expect(find.byType(GetSnackBar), findsNothing);
    });
  });

  // Cerrar el registro programa un cuadro, así que el binding va primero.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('las visitas (RF-BIEN-1 y B-19)', () {
    test('cada visita reinicia la conversación, cierra los tramos y vacía el '
        'login', () async {
      final b = Bienvenida();
      await b.visitar();
      b.controlador.responderAlSaludo(yaUsa: false);
      expect(b.controlador.registro, isNotNull);
      b.login.codeController.text = '20230001';
      await b.visitar();
      expect(b.controlador.entradas, isEmpty);
      expect(b.controlador.registro, isNull);
      expect(b.login.codeController.text, '');
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.recibimiento);
    });

    test('cada visita cierra el tramo del registro y borra sus cinco campos '
        '(RF-BIEN-9)', () async {
      final creados = <RegistroController>[];
      final b = Bienvenida(
        crearRegistro: () {
          final r = RegistroController(
            service: RegistroFalso(),
            adoptarSesion: ({required token, required user}) async {},
            iniciarSesion: ({required code, required password}) async => null,
          );
          creados.add(r);
          return r;
        },
      );
      await b.visitar();
      b.controlador.responderAlSaludo(yaUsa: false);
      final r = creados.single
        ..codigoCtrl.text = '20230001'
        ..passwordCtrl.text = 'Contrasena1'
        ..confirmacionCtrl.text = 'Contrasena1'
        ..portalPasswordCtrl.text = 'clave-de-prueba'
        ..passcodeCtrl.text = '123456';
      await b.visitar();
      expect(r.cerrado, isTrue);
      for (final campo in [
        r.codigoCtrl,
        r.passwordCtrl,
        r.confirmacionCtrl,
        r.portalPasswordCtrl,
        r.passcodeCtrl,
      ]) {
        expect(campo.text, '');
      }
    });

    test(
      'el token de una visita vieja que llega tarde no toca la nueva',
      () async {
        final tarde = Completer<String?>();
        var pedidos = 0;
        final b = Bienvenida(
          auth: AuthDeLaBienvenida(
            usuario: alumnaDePrueba(setupComplete: false),
          ),
          tokenGuardado: () =>
              ++pedidos == 1 ? tarde.future : Future<String?>.value(),
        );
        final vieja = b.controlador.nuevaVisita();
        final empiezaVieja = b.controlador.empezarVisita(vieja);
        final nueva = b.controlador.nuevaVisita();
        await b.controlador.empezarVisita(nueva);
        b.controlador.responderAlSaludo(yaUsa: false);
        // El token de la vieja llega con la sesión de un alumno sin
        // especialidad, que la llevaría a la llegada con sesión.
        tarde.complete('jwt-de-prueba');
        await empiezaVieja;
        expect(b.controlador.visitaEmpezada.value, nueva);
        expect(b.controlador.conSesion, isFalse);
        expect(b.controlador.turno.value, TurnoDeLaBienvenida.n1Codigo);
        expect(b.controlador.registro, isNotNull);
      },
    );

    test('una visita vieja no toca la nueva', () async {
      final b = Bienvenida();
      final vieja = b.controlador.nuevaVisita();
      final nueva = b.controlador.nuevaVisita();
      await b.controlador.empezarVisita(nueva);
      b.controlador.responderAlSaludo(yaUsa: false);
      await b.controlador.empezarVisita(vieja);
      b.controlador.terminarVisita(vieja);
      expect(b.controlador.registro, isNotNull);
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.n1Codigo);
      b.controlador.terminarVisita(nueva);
      expect(b.controlador.registro, isNull);
    });

    test('con un motivo arranca directo en E1, con el primer grupo y sin la '
        'pregunta (B-8)', () async {
      for (final motivo in MotivoDeLlegada.values) {
        final b = Bienvenida();
        await b.visitar(motivo: motivo);
        expect(b.deUlises, [
          TextosDeLaBienvenida.saludo,
          TextosDeLaBienvenida.e1,
        ]);
        expect(b.controlador.turno.value, TurnoDeLaBienvenida.e1Codigo);
        Get.reset();
      }
    });

    /// Empieza otra visita con el motivo, llega a E2 y deja su login en
    /// vuelo, así que su compositor espera.
    Future<({Future<void> entrada})> otraVisitaQueEspera(
      Bienvenida b,
      Completer<void> espera,
    ) async {
      await b.visitar(motivo: MotivoDeLlegada.restablecida);
      b.login.codeController.text = '20230001';
      b.controlador.enviarCodigo();
      b.login.passwordController.text = 'secreta-de-prueba';
      b.auth.esperas.add(espera);
      final entrada = b.controlador.entrar();
      expect(b.controlador.esperando.value, isTrue);
      return (entrada: entrada);
    }

    test('«Iniciar sesión» desde incierto que responde en otra visita no '
        'apaga la espera de esa visita', () async {
      final vieja = Completer<void>();
      final nueva = Completer<void>();
      final b = Bienvenida(
        registro: RegistroFalso(
          fallo: const RegistroFailure('x', code: 'TIEMPO_AGOTADO'),
        ),
      );
      await b.visitar();
      final c = b.controlador..responderAlSaludo(yaUsa: false);
      c.registro!.codigoCtrl.text = '20230001';
      c.enviarCodigoDeAlumno();
      c.registro!
        ..passwordCtrl.text = 'Contrasena1'
        ..confirmacionCtrl.text = 'Contrasena1';
      c
        ..enviarContrasenas()
        ..aceptarConsentimiento();
      c.registro!.portalPasswordCtrl.text = 'clave-de-prueba';
      c.enviarPortal();
      c.registro!.passcodeCtrl.text = '123456';
      await c.crearCuenta();
      expect(c.turno.value, TurnoDeLaBienvenida.incierto);
      b.auth.esperas.add(vieja);
      final intento = c.iniciarSesionDesdeIncierto();
      // Mientras espera, el atrás no vuelve a N5 (BR-AUTH-F-08).
      c.atras();
      expect(c.turno.value, TurnoDeLaBienvenida.incierto);
      final (:entrada) = await otraVisitaQueEspera(b, nueva);
      vieja.complete();
      await intento;
      expect(c.esperando.value, isTrue);
      expect(c.turno.value, TurnoDeLaBienvenida.e2Contrasena);
      nueva.complete();
      await entrada;
      expect(c.turno.value, TurnoDeLaBienvenida.pasoAlHorario);
    });

    test('un guardado de la selección manual que responde en otra visita no '
        'la lleva al horario ni apaga su espera', () async {
      final vieja = Completer<void>();
      final nueva = Completer<void>();
      final b = Bienvenida(
        auth: AuthDeLaBienvenida(usuario: alumnaDePrueba(setupComplete: false)),
        token: 'jwt-de-prueba',
      );
      await b.visitar();
      final c = b.controlador..ulisesAterrizoConSesion();
      await pumpEventQueue();
      c
        ..saltarElTest()
        ..marcarPrincipal(1);
      b.auth.esperas.add(vieja);
      final guardado = c.terminarLaSeleccion();
      // Mientras guarda, el atrás no vuelve a T0.
      c.atras();
      expect(c.turno.value, TurnoDeLaBienvenida.seleccionManual);
      final (:entrada) = await otraVisitaQueEspera(b, nueva);
      vieja.complete();
      await guardado;
      expect(c.esperando.value, isTrue);
      expect(c.turno.value, TurnoDeLaBienvenida.e2Contrasena);
      expect(b.deUlises, isNot(contains(TextosDeLaBienvenida.listoAlHorario)));
      nueva.complete();
      await entrada;
    });

    test('una recarga del catálogo que responde en otra visita no dice nada '
        'en ella', () async {
      final vieja = Completer<void>();
      final nueva = Completer<void>();
      final b = Bienvenida(
        auth: AuthDeLaBienvenida(usuario: alumnaDePrueba(setupComplete: false)),
        token: 'jwt-de-prueba',
      );
      b.auth
        ..catalogoFalla = true
        ..recargaFalla = true;
      await b.visitar();
      final c = b.controlador..ulisesAterrizoConSesion();
      await pumpEventQueue();
      c.saltarElTest();
      expect(c.catalogoFallido.value, isTrue);
      b.auth.esperas.add(vieja);
      final recarga = c.reintentarElCatalogo();
      final (:entrada) = await otraVisitaQueEspera(b, nueva);
      final antes = b.deUlises.length;
      vieja.complete();
      await recarga;
      expect(b.deUlises.length, antes);
      expect(c.esperando.value, isTrue);
      nueva.complete();
      await entrada;
    });

    test(
      'al pasar al horario se borra el historial y se vacía el login',
      () async {
        final b = Bienvenida();
        await b.visitar();
        b.controlador.responderAlSaludo(yaUsa: true);
        b.login.codeController.text = '20230001';
        b.controlador.pasoHecho();
        expect(b.controlador.entradas, isEmpty);
        expect(b.login.codeController.text, '');
      },
    );
  });

  group('la página y sus visitas (RF-BIEN-1)', () {
    setUp(() {
      Get.testMode = true;
      Get.reset();
    });
    tearDown(Get.reset);

    testWidgets('tras un cierre de sesión que deja la franja con el sello, el '
        'primer cuadro sale solo de los argumentos y no muestra nada de la '
        'visita anterior', (tester) async {
      final b = Bienvenida();
      await montarLaBienvenida(
        tester,
        b,
        argumentos: const {argumentoDeMotivo: MotivoDeLlegada.expirada},
      );
      await avanzar(tester, 1500);
      expect(find.text(TextosDeLaBienvenida.e1), findsOneWidget);
      // Va al home y cierra sesión, que llega a /login sin argumentos.
      Get.offAllNamed<void>('/home');
      await avanzar(tester, 600);
      expect(offAllToLogin(), isTrue);
      await tester.pump();
      expect(
        tester.takeException(),
        isNull,
        reason: 'sin setState en el build',
      );
      // En su primer cuadro la ruta nueva se construye fuera de la vista, como
      // toda ruta con transición, así que se busca también ahí.
      final nueva = find.byType(BienvenidaPage, skipOffstage: false).last;
      // El primer cuadro es el naranja del splash con el logo en reposo, y
      // la conversación de la visita anterior no se pinta.
      final fondo = find.descendant(
        of: nueva,
        matching: find.byKey(Recibimiento.claveDelFondo, skipOffstage: false),
        skipOffstage: false,
      );
      expect(fondo, findsOneWidget);
      final cuadro = Recibimiento.cuadroActual(tester.element(fondo));
      expect(cuadro.fondo, naranjaDelSplash);
      expect(cuadro.estrella!.cruces, hasLength(2));
      expect(
        find.descendant(
          of: nueva,
          matching: find.text(TextosDeLaBienvenida.e1, skipOffstage: false),
          skipOffstage: false,
        ),
        findsNothing,
      );
      expect(
        find.descendant(of: nueva, matching: find.byType(MarcoDelCompositor)),
        findsNothing,
      );
      // Después del primer cuadro, la visita nueva empieza de cero.
      await tester.pump();
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.recibimiento);
      await avanzar(tester, 4000);
    });

    testWidgets('en el restablecimiento conviven dos /login, sin setState '
        'durante el build, y el dispose de la página vieja no toca la visita '
        'nueva', (tester) async {
      final b = Bienvenida();
      await montarLaBienvenida(
        tester,
        b,
        argumentos: const {argumentoDeMotivo: MotivoDeLlegada.expirada},
      );
      await avanzar(tester, 1500);
      // «¿Olvidaste tu contraseña?» abre /forgot-password encima, y el
      // restablecimiento navega a /login con la vieja todavía en la pila.
      Get.toNamed<void>('/forgot-password');
      await avanzar(tester, 600);
      expect(offAllToLogin(motivo: MotivoDeLlegada.restablecida), isTrue);
      await tester.pump();
      expect(
        tester.takeException(),
        isNull,
        reason: 'sin setState en el build',
      );
      // La visita nueva empieza en E1 por el motivo, y abre un tramo que el
      // dispose de la vieja cerraría si no estuviera guardado por la visita.
      await tester.pump();
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.e1Codigo);
      b.controlador.soyNuevo();
      expect(b.controlador.registro, isNotNull);
      await avanzar(tester, 1500);
      expect(find.byType(BienvenidaPage, skipOffstage: false), findsOneWidget);
      expect(b.controlador.registro, isNotNull, reason: 'la vieja no la toca');
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.n1Codigo);
      expect(tester.takeException(), isNull);
    });
  });

  group('la ruta /login con la bienvenida (RF-BIEN-1, B-19, B-23 y B-25)', () {
    test('/login muestra la bienvenida con LoginBinding, y /registro ya no '
        'existe', () {
      final login = paginasDeLaApp.firstWhere((p) => p.name == '/login');
      expect(login.page(), isA<BienvenidaPage>());
      expect(login.binding, isA<LoginBinding>());
      expect(paginasDeLaApp.map((p) => p.name), isNot(contains('/registro')));
    });

    testWidgets('LoginBinding registra LoginController y la bienvenida y los '
        'reusa en cada llegada (B-19)', (tester) async {
      registrarLosServiciosDeLaBienvenida();
      LoginBinding().dependencies();
      final login = Get.find<LoginController>();
      final bienvenida = Get.find<BienvenidaController>();
      LoginBinding().dependencies();
      await tester.pump();
      expect(Get.find<LoginController>(), same(login));
      expect(Get.find<BienvenidaController>(), same(bienvenida));
    });

    testWidgets('en la app real, «Soy nuevo» abre el registro en la '
        'conversación sin salir de /login (RS-FE-1 y B-23)', (tester) async {
      registrarLosServiciosDeLaBienvenida();
      await tester.pumpWidget(const MyApp(initialRoute: '/login'));
      await avanzar(tester, 2800);
      await tester.tap(find.text(TextosDeLaBienvenida.soyNuevo));
      await tester.pump();
      expect(
        Get.find<BienvenidaController>().turno.value,
        TurnoDeLaBienvenida.n1Codigo,
      );
      expect(Get.currentRoute, '/login');
      await avanzar(tester, 4000);
      expect(
        find.text(TextosDeLaBienvenida.rotuloCodigoDeAlumno),
        findsOneWidget,
      );
    });
  });
}
