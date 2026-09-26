// test/bienvenida/bienvenida_entrar_test.dart
//
// UNITARIA + WIDGET · Bienvenida con Ulises
// (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-6. LoginController deja de navegar y devuelve el desenlace, atrapa
// el fallo crudo de la red y apaga `submitting`, y vacía sus campos al
// salir. Los turnos E1, E2 y E3, con el código, la contraseña, Google en
// Android, iOS y web, el error, sin conexión, «Soy nuevo», «¿Olvidaste tu
// contraseña?» y el destino según el rol y la configuración. Mientras se
// espera un login el compositor no responde, y el desenlace que llega en
// otra visita se descarta (BR-AUTH-F-08 y RF-BIEN-1). El autocompletado de
// E1 y E2 en un mismo grupo.
// Archivos probados lib/pages/login/login_controller.dart,
// lib/pages/bienvenida/bienvenida_controller.dart y
// lib/pages/bienvenida/widgets/compositor.dart.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/google_sign_in_button.dart';
import 'package:ulima_plus/domain/bienvenida/bienvenida_turnos.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/bienvenida/conversacion.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/compositor.dart';
import 'package:ulima_plus/pages/login/login_controller.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/session_navigation.dart';

import 'apoyo_bienvenida.dart';

UserModel _alumna() => UserModel(
  code: '20230001',
  firstName: 'Alumna',
  lastName: 'De Prueba',
  email: 'test@aloe.ulima.edu.pe',
  role: 'student',
  currentCycle: '2026-2',
  setupComplete: true,
);

/// Lo que `AuthService.login` no atrapa, como un socket caído.
class _RedCaida implements Exception {
  const _RedCaida();
}

class _AuthDePrueba extends AuthService {
  _AuthDePrueba({this.error, this.redCaida = false, this.google});

  final String? error;
  final bool redCaida;

  /// Lo que devuelve Google, con 'cancelar' para el selector cerrado.
  final String? google;
  UserModel? _usuario;
  int logins = 0;

  @override
  UserModel? get currentUser => _usuario;

  @override
  Future<String?> login({
    required String code,
    required String password,
  }) async {
    logins++;
    if (redCaida) throw const _RedCaida();
    if (error != null) return error;
    _usuario = _alumna();
    return null;
  }

  @override
  Future<String?> loginWithGoogle() async {
    if (google == 'cancelar') return null;
    if (google != null) return google;
    _usuario = _alumna();
    return null;
  }
}

LoginController _controlador(_AuthDePrueba auth) {
  Get.testMode = true;
  Get.reset();
  Get.put<AuthService>(auth);
  return LoginController()
    ..codeController.text = '20230001'
    ..passwordController.text = 'secreta-de-prueba';
}

void main() {
  group('LoginController devuelve el desenlace (RF-BIEN-6)', () {
    tearDown(Get.reset);

    test('con la sesión puesta devuelve sesionPuesta y no navega', () async {
      final c = _controlador(_AuthDePrueba());
      final d = await c.entrar();
      expect(d.tipo, TipoDeDesenlace.sesionPuesta);
      expect(c.submitting.value, isFalse);
      expect(Get.currentRoute, isNot('/home'));
    });

    test('un login rechazado devuelve el mensaje de hoy', () async {
      final c = _controlador(
        _AuthDePrueba(error: 'Código o contraseña incorrectos.'),
      );
      final d = await c.entrar();
      expect(d.tipo, TipoDeDesenlace.error);
      expect(d.mensaje, 'Código o contraseña incorrectos.');
    });

    test(
      'un fallo crudo de la red devuelve sinConexion y apaga submitting',
      () async {
        final c = _controlador(_AuthDePrueba(redCaida: true));
        final d = await c.entrar();
        expect(d.tipo, TipoDeDesenlace.sinConexion);
        expect(c.submitting.value, isFalse);
      },
    );

    test('con un campo vacío no llama al backend', () async {
      final auth = _AuthDePrueba();
      final c = _controlador(auth)..passwordController.text = '';
      final d = await c.entrar();
      expect(d.tipo, TipoDeDesenlace.error);
      expect(d.mensaje, 'Ingresa tu código y contraseña.');
      expect(auth.logins, 0);
    });

    test('Google cancelado no hace nada, un error trae su mensaje', () async {
      final cancelado = _controlador(_AuthDePrueba(google: 'cancelar'));
      expect(
        (await cancelado.entrarConGoogle()).tipo,
        TipoDeDesenlace.cancelado,
      );
      final conError = _controlador(
        _AuthDePrueba(google: 'Tu correo no está registrado en el sistema.'),
      );
      final d = await conError.entrarConGoogle();
      expect(d.tipo, TipoDeDesenlace.error);
      expect(d.mensaje, 'Tu correo no está registrado en el sistema.');
      final bien = _controlador(_AuthDePrueba());
      expect((await bien.entrarConGoogle()).tipo, TipoDeDesenlace.sesionPuesta);
    });

    test(
      'cancelar Google con un usuario viejo en memoria no pone la sesión',
      () async {
        // Tras un 401 el usuario queda en memoria sin token (RF-BIEN-21), y
        // cancelar el selector no hace nada (RF-BIEN-6).
        final auth = _AuthDePrueba(google: 'cancelar').._usuario = _alumna();
        final c = _controlador(auth);
        expect((await c.entrarConGoogle()).tipo, TipoDeDesenlace.cancelado);
      },
    );

    test('vaciarCampos borra el código, la contraseña y un desenlace de Google '
        'en web sin atender', () {
      final c = _controlador(_AuthDePrueba())
        ..desenlaceDeGoogleEnWeb.value = const DesenlaceDelLogin.sesionPuesta()
        ..vaciarCampos();
      expect(c.desenlaceDeGoogleEnWeb.value, isNull);
      expect(c.codeController.text, '');
      expect(c.passwordController.text, '');
      expect(c.passwordVisible.value, isFalse);
    });
  });

  group('los turnos de «Sí, entrar» (RF-BIEN-6)', () {
    tearDown(Get.reset);

    Future<Bienvenida> enE2({AuthDeLaBienvenida? auth}) async {
      final b = Bienvenida(auth: auth);
      await b.visitar();
      b.controlador.responderAlSaludo(yaUsa: true);
      b.login.codeController.text = '  20230001 ';
      b.controlador.enviarCodigo();
      b.login.passwordController.text = 'secreta-de-prueba';
      return b;
    }

    test('al responder, la conversación trae el primer grupo y la respuesta, '
        'y sigue E1', () async {
      final b = Bienvenida();
      await b.visitar();
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.recibimiento);
      b.controlador.responderAlSaludo(yaUsa: true);
      expect(b.deUlises, [
        TextosDeLaBienvenida.saludo,
        TextosDeLaBienvenida.pregunta,
        TextosDeLaBienvenida.e1,
      ]);
      expect(b.delAlumno, ['Sí, entrar']);
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.e1Codigo);
      expect(b.controlador.latidos.value, 1);
      // El primer turno de la rama espera 650 ms tras la respuesta.
      final e1 = b.controlador.entradas.last;
      expect(e1.pausa, Ritmo.trasLaRespuesta);
    });

    test(
      'E1 manda el código recortado, tal como se escribió, y abre E2',
      () async {
        final b = await enE2();
        expect(b.delAlumno.last, '20230001');
        expect(b.deUlises.last, TextosDeLaBienvenida.e2);
        expect(b.controlador.turno.value, TurnoDeLaBienvenida.e2Contrasena);
      },
    );

    test('el usuario alfanumérico del docente también vale', () async {
      final b = Bienvenida(
        auth: AuthDeLaBienvenida(alEntrar: docenteDePrueba()),
      );
      await b.visitar();
      b.controlador.responderAlSaludo(yaUsa: true);
      b.login.codeController.text = 'docente.test';
      b.controlador.enviarCodigo();
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.e2Contrasena);
    });

    test('con la sesión puesta entra un candado y la despedida, y pide el paso '
        'al horario', () async {
      final b = await enE2();
      await b.controlador.entrar();
      final respuesta = b.controlador.entradas
          .whereType<RespuestaDelAlumno>()
          .last;
      expect(respuesta.texto, TextosDeLaBienvenida.contrasenaLista);
      expect(respuesta.secreta, isTrue);
      expect(b.deUlises.last, TextosDeLaBienvenida.e3);
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.pasoAlHorario);
      expect(
        b.rutas,
        isEmpty,
        reason: 'la bienvenida no navega a /setup-carrera',
      );
    });

    test('con la sesión puesta cierra el autocompletado con el código y la '
        'contraseña todavía escritos, y un login rechazado no lo cierra '
        '(RF-BIEN-6)', () async {
      final rechazado = await enE2(
        auth: AuthDeLaBienvenida(
          errorDeLogin: 'Código o contraseña incorrectos.',
        ),
      );
      await rechazado.controlador.entrar();
      expect(rechazado.autocompletados, isEmpty);
      Get.reset();
      final b = await enE2();
      await b.controlador.entrar();
      expect(b.autocompletados, [
        (codigo: '  20230001 ', contrasena: 'secreta-de-prueba'),
      ]);
      // Los campos se vacían después, al pasar al horario.
      b.controlador.pasoHecho();
      expect(b.login.codeController.text, '');
      expect(b.login.passwordController.text, '');
      expect(b.autocompletados, hasLength(1));
    });

    test('un docente también va al paso al horario', () async {
      final b = await enE2(
        auth: AuthDeLaBienvenida(alEntrar: docenteDePrueba()),
      );
      await b.controlador.entrar();
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.pasoAlHorario);
    });

    test('con la configuración a medias, Ulises dice que falta la especialidad '
        'y sigue el test, sin navegar a /setup-carrera (B-10)', () async {
      final b = await enE2(
        auth: AuthDeLaBienvenida(
          alEntrar: alumnaDePrueba(setupComplete: false),
        ),
      );
      await b.controlador.entrar();
      expect(b.deUlises.last, TextosDeLaBienvenida.holaFaltaEspecialidad);
      expect(
        b.controlador.turno.value,
        isNot(TurnoDeLaBienvenida.pasoAlHorario),
      );
      expect(b.controlador.conSesion, isTrue);
      expect(b.rutas, isEmpty);
    });

    test('un login rechazado dice el mensaje y vuelve a E1 con el código y la '
        'contraseña vacía (B-6)', () async {
      final b = await enE2(
        auth: AuthDeLaBienvenida(
          errorDeLogin: 'Código o contraseña incorrectos.',
        ),
      );
      await b.controlador.entrar();
      final error = b.controlador.entradas.last as BurbujaDeUlises;
      expect(error.texto, 'Código o contraseña incorrectos.');
      expect(error.tipo, TipoDeBurbuja.error);
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.e1Codigo);
      expect(b.login.codeController.text, '  20230001 ');
      expect(b.login.passwordController.text, '');
    });

    test('sin conexión dice el texto de hoy y E2 sigue abierto con la '
        'contraseña escrita', () async {
      final b = await enE2(auth: AuthDeLaBienvenida(redCaida: true));
      await b.controlador.entrar();
      expect(b.deUlises.last, TextosDeLaBienvenida.sinConexion);
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.e2Contrasena);
      expect(b.login.passwordController.text, 'secreta-de-prueba');
      expect(b.controlador.esperando.value, isFalse);
    });

    test('una visita nueva mientras «Entrar» espera no recibe su desenlace ni '
        'pierde su propia espera (RF-BIEN-1 y BR-AUTH-F-08)', () async {
      final vieja = Completer<void>();
      final nueva = Completer<void>();
      final auth = AuthDeLaBienvenida()..esperas.addAll([vieja, nueva]);
      final b = await enE2(auth: auth);
      final c = b.controlador;
      final entradaVieja = c.entrar();
      expect(c.esperando.value, isTrue);
      // El restablecimiento llega a /login con otra visita mientras el login
      // de la anterior sigue en vuelo.
      await b.visitar(motivo: MotivoDeLlegada.restablecida);
      b.login.codeController.text = '20230001';
      c.enviarCodigo();
      b.login.passwordController.text = 'secreta-de-prueba';
      final entradaNueva = c.entrar();
      expect(c.esperando.value, isTrue);
      vieja.complete();
      await entradaVieja;
      expect(
        c.esperando.value,
        isTrue,
        reason: 'el login viejo no apaga la espera de la visita nueva',
      );
      expect(b.delAlumno, ['20230001']);
      expect(c.turno.value, TurnoDeLaBienvenida.e2Contrasena);
      expect(b.autocompletados, isEmpty);
      nueva.complete();
      await entradaNueva;
      expect(b.delAlumno, ['20230001', TextosDeLaBienvenida.contrasenaLista]);
      expect(c.turno.value, TurnoDeLaBienvenida.pasoAlHorario);
    });

    test(
      'una visita nueva mientras Google espera no recibe su desenlace',
      () async {
        final espera = Completer<void>();
        final auth = AuthDeLaBienvenida()..esperas.add(espera);
        final b = Bienvenida(auth: auth);
        await b.visitar();
        b.controlador.responderAlSaludo(yaUsa: true);
        final google = b.controlador.entrarConGoogle();
        await b.visitar(motivo: MotivoDeLlegada.expirada);
        espera.complete();
        await google;
        expect(b.delAlumno, isEmpty);
        expect(b.deUlises, [
          TextosDeLaBienvenida.saludo,
          TextosDeLaBienvenida.e1,
        ]);
        expect(b.controlador.turno.value, TurnoDeLaBienvenida.e1Codigo);
        expect(b.controlador.esperando.value, isFalse);
      },
    );

    test('mientras «Entrar» espera, el compositor no responde, ni un segundo '
        'toque, el atrás, «¿Olvidaste tu contraseña?» ni «Soy nuevo» '
        '(BR-AUTH-F-08)', () async {
      final espera = Completer<void>();
      final auth = AuthDeLaBienvenida()..esperas.add(espera);
      final b = await enE2(auth: auth);
      final c = b.controlador;
      final entrada = c.entrar();
      final antes = c.entradas.length;
      await c.entrar();
      c
        ..atras()
        ..volverAE1()
        ..abrirOlvido()
        ..soyNuevo();
      expect(auth.logins, 1, reason: 'sin segundo login');
      expect(c.entradas.length, antes);
      expect(c.turno.value, TurnoDeLaBienvenida.e2Contrasena);
      expect(b.rutas, isEmpty);
      expect(c.registro, isNull);
      expect(b.login.codeController.text, '  20230001 ');
      espera.complete();
      await entrada;
      expect(c.turno.value, TurnoDeLaBienvenida.pasoAlHorario);
    });

    test(
      'mientras Google espera, E1 no manda el código ni pasa a «Soy nuevo»',
      () async {
        final espera = Completer<void>();
        final auth = AuthDeLaBienvenida(google: 'cancelar')
          ..esperas.add(espera);
        final b = Bienvenida(auth: auth);
        await b.visitar();
        final c = b.controlador..responderAlSaludo(yaUsa: true);
        final google = c.entrarConGoogle();
        await c.entrarConGoogle();
        b.login.codeController.text = '20230001';
        c
          ..enviarCodigo()
          ..soyNuevo()
          ..atras();
        expect(auth.logins, 1);
        expect(c.turno.value, TurnoDeLaBienvenida.e1Codigo);
        expect(b.delAlumno, [TextosDeLaBienvenida.siEntrar]);
        espera.complete();
        await google;
        expect(c.esperando.value, isFalse);
        c.enviarCodigo();
        expect(c.turno.value, TurnoDeLaBienvenida.e2Contrasena);
      },
    );

    test('«¿Olvidaste tu contraseña?» solo abre desde E2', () async {
      final b = Bienvenida();
      await b.visitar();
      b.controlador
        ..responderAlSaludo(yaUsa: true)
        ..abrirOlvido();
      expect(b.rutas, isEmpty);
    });

    test(
      'Google cancelado no hace nada, un error es una burbuja y E1 sigue',
      () async {
        final b = Bienvenida(auth: AuthDeLaBienvenida(google: 'cancelar'));
        await b.visitar();
        b.controlador.responderAlSaludo(yaUsa: true);
        final antes = b.controlador.entradas.length;
        await b.controlador.entrarConGoogle();
        expect(b.controlador.entradas.length, antes);
        b.auth.google = 'Tu correo no está registrado en el sistema.';
        await b.controlador.entrarConGoogle();
        expect(b.deUlises.last, 'Tu correo no está registrado en el sistema.');
        expect(b.controlador.turno.value, TurnoDeLaBienvenida.e1Codigo);
      },
    );

    test('Google con la sesión puesta responde con su logo y sigue igual que '
        'con el código', () async {
      final b = Bienvenida();
      await b.visitar();
      b.controlador.responderAlSaludo(yaUsa: true);
      await b.controlador.entrarConGoogle();
      final respuesta = b.controlador.entradas
          .whereType<RespuestaDelAlumno>()
          .last;
      expect(respuesta.texto, TextosDeLaBienvenida.continuarConGoogle);
      expect(respuesta.conGoogle, isTrue);
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.pasoAlHorario);
    });

    test('Google en web llega por el resultado observable mientras E1 está '
        'abierto', () async {
      final b = Bienvenida();
      await b.visitar();
      b.controlador.responderAlSaludo(yaUsa: true);
      b.auth.usuario = alumnaDePrueba();
      b.login.desenlaceDeGoogleEnWeb.value =
          const DesenlaceDelLogin.sesionPuesta();
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.pasoAlHorario);
      expect(b.login.desenlaceDeGoogleEnWeb.value, isNull);
    });

    test('un desenlace de Google en web fuera de E1 se descarta, y el '
        'siguiente, aunque sea igual, llega en E1', () async {
      final b = Bienvenida();
      await b.visitar();
      b.login.desenlaceDeGoogleEnWeb.value =
          const DesenlaceDelLogin.sesionPuesta();
      expect(b.login.desenlaceDeGoogleEnWeb.value, isNull);
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.recibimiento);
      b.controlador.responderAlSaludo(yaUsa: true);
      b.auth.usuario = alumnaDePrueba();
      b.login.desenlaceDeGoogleEnWeb.value =
          const DesenlaceDelLogin.sesionPuesta();
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.pasoAlHorario);
    });

    test(
      '«Soy nuevo» en E1 y en E2 vacía el login y empieza el registro',
      () async {
        void comprobar(Bienvenida b) {
          expect(b.delAlumno.last, TextosDeLaBienvenida.soyNuevo);
          expect(b.login.codeController.text, '');
          expect(b.login.passwordController.text, '');
          expect(b.controlador.turno.value, TurnoDeLaBienvenida.n1Codigo);
          expect(b.controlador.registro, isNotNull);
          expect(b.deUlises.sublist(b.deUlises.length - 2), [
            TextosDeLaBienvenida.n1a,
            TextosDeLaBienvenida.n1b,
          ]);
        }

        final enE1 = Bienvenida();
        await enE1.visitar();
        enE1.controlador.responderAlSaludo(yaUsa: true);
        enE1.login.codeController.text = '20230001';
        enE1.controlador.soyNuevo();
        comprobar(enE1);
        Get.reset();
        final b = await enE2();
        b.controlador.soyNuevo();
        comprobar(b);
      },
    );

    test('«¿Olvidaste tu contraseña?» abre /forgot-password encima', () async {
      final b = await enE2();
      b.controlador.abrirOlvido();
      expect(b.rutas, ['/forgot-password']);
    });

    test(
      'el atrás en E2 vuelve a E1 con el código, y en E1 sale de la app',
      () async {
        final b = await enE2();
        expect(b.controlador.atrasSaleDeLaApp, isFalse);
        b.controlador.atras();
        expect(b.controlador.turno.value, TurnoDeLaBienvenida.e1Codigo);
        expect(b.login.codeController.text, '  20230001 ');
        expect(b.controlador.atrasSaleDeLaApp, isTrue);
      },
    );
  });

  group('«Entrar» mientras espera (RF-BIEN-6 y BR-AUTH-F-08)', () {
    setUp(() {
      Get.testMode = true;
      Get.reset();
    });
    tearDown(Get.reset);

    testWidgets('el botón muestra su indicador mientras espera y lo quita al '
        'responder', (tester) async {
      final espera = Completer<void>();
      final b = Bienvenida(
        auth: AuthDeLaBienvenida(
          errorDeLogin: 'Código o contraseña incorrectos.',
        )..esperas.add(espera),
      );
      await montarLaBienvenida(
        tester,
        b,
        argumentos: const {argumentoDeMotivo: MotivoDeLlegada.expirada},
      );
      await avanzar(tester, 1500);
      await tester.enterText(find.byType(TextField).first, '20230001');
      await tester.pump();
      await tester.tap(find.byType(BotonDeEnvio));
      await avanzar(tester, 2000);
      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && w.controller == b.login.passwordController,
        ),
        'secreta-de-prueba',
      );
      await tester.pump();
      await tester.tap(find.text(TextosDeLaBienvenida.entrar));
      await tester.pump();
      final boton = tester.widget<BotonPrincipal>(find.byType(BotonPrincipal));
      expect(boton.esperando, isTrue);
      expect(
        find.descendant(
          of: find.byType(BotonPrincipal),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      espera.complete();
      await avanzar(tester, 3000);
    });
  });

  group('el autocompletado (RF-BIEN-6)', () {
    setUp(() {
      Get.testMode = true;
      Get.reset();
    });
    tearDown(Get.reset);

    testWidgets('E1 y E2 van en un mismo AutofillGroup, en E2 el campo del '
        'código sigue montado, invisible y fuera del foco, y la sesión puesta '
        'cierra el contexto con los dos campos escritos', (tester) async {
      final b = Bienvenida();
      await montarLaBienvenida(
        tester,
        b,
        argumentos: const {argumentoDeMotivo: MotivoDeLlegada.expirada},
      );
      await avanzar(tester, 1500);
      final grupo = find.byType(AutofillGroup);
      expect(grupo, findsOneWidget);
      final grupoDeE1 = tester.element(grupo);
      Finder campoDe(TextEditingController c, {bool soloVisibles = true}) =>
          find.descendant(
            of: grupo,
            matching: find.byWidgetPredicate(
              (w) => w is TextField && w.controller == c,
              skipOffstage: soloVisibles,
            ),
            skipOffstage: soloVisibles,
          );
      expect(campoDe(b.login.codeController), findsOneWidget);
      expect(
        tester.widget<TextField>(campoDe(b.login.codeController)).autofillHints,
        [AutofillHints.username],
      );

      await tester.enterText(campoDe(b.login.codeController), '20230001');
      await tester.pump();
      await tester.tap(find.byType(BotonDeEnvio));
      await avanzar(tester, 2000);
      expect(tester.element(grupo), same(grupoDeE1), reason: 'el mismo grupo');
      expect(campoDe(b.login.passwordController), findsOneWidget);
      expect(
        tester
            .widget<TextField>(campoDe(b.login.passwordController))
            .autofillHints,
        [AutofillHints.password],
      );
      // El campo del código no se ve, pero sigue montado en el grupo.
      expect(campoDe(b.login.codeController), findsNothing);
      final oculto = campoDe(b.login.codeController, soloVisibles: false);
      expect(oculto, findsOneWidget);
      expect(tester.widget<TextField>(oculto).autofillHints, [
        AutofillHints.username,
      ]);
      final offstage = tester.widget<Offstage>(
        find.ancestor(of: oculto, matching: find.byType(Offstage)).first,
      );
      expect(
        offstage.offstage,
        isTrue,
        reason: 'fuera de la vista y de la semántica',
      );
      expect(
        find.ancestor(of: oculto, matching: find.byType(ExcludeFocus)),
        findsWidgets,
        reason: 'fuera del foco',
      );

      await tester.enterText(
        campoDe(b.login.passwordController),
        'secreta-de-prueba',
      );
      await tester.pump();
      await tester.tap(find.text(TextosDeLaBienvenida.entrar));
      await tester.pump();
      expect(b.autocompletados, [
        (codigo: '20230001', contrasena: 'secreta-de-prueba'),
      ]);
      await avanzar(tester, 3000);
    });
  });

  group('el botón de GIS (RF-BIEN-6, B-25 y B-35)', () {
    testWidgets('fuera de web, el botón con su configuración no dibuja nada', (
      tester,
    ) async {
      await tester.pumpWidget(
        Center(
          child: googleSignInButton(
            configuracion: configuracionDelBotonDeGoogle(
              oscuro: false,
              anchoDelCompositor: 351,
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(SizedBox)), Size.zero);
    });
  });
}
