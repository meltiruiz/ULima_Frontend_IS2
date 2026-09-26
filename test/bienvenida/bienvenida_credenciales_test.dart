// test/bienvenida/bienvenida_credenciales_test.dart
//
// UNITARIA + WIDGET · Bienvenida con Ulises
// (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-9 y B-20. La bienvenida cierra el controlador del registro sin
// GetX. Cerrarlo borra los cinco campos enseguida y los desecha después del
// cuadro en que el campo del compositor sale del árbol. La Tarea 24 suma los
// turnos y el oráculo de cuentas.
// Archivo probado lib/pages/registro/registro_controller.dart.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/domain/bienvenida/bienvenida_turnos.dart';
import 'package:ulima_plus/models/portal_sync_models.dart';
import 'package:ulima_plus/models/registro_models.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/bienvenida/conversacion.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/compositor.dart';
import 'package:ulima_plus/pages/registro/registro_controller.dart';
import 'package:ulima_plus/services/registro_service.dart';
import 'package:ulima_plus/services/session_navigation.dart';

import 'apoyo_bienvenida.dart';

/// Un servicio del registro cuya respuesta llega cuando la prueba lo pide.
class _ServicioEnVuelo extends RegistroService {
  final Completer<RegistroResult> respuesta = Completer<RegistroResult>();

  @override
  Future<RegistroResult> registrar({
    required String code,
    required String portalPassword,
    required String passcode,
    required String password,
    required bool consent,
  }) => respuesta.future;
}

RegistroResult _resultado() => RegistroResult(
  token: 'jwt-de-prueba',
  user: UserModel(
    code: '20230001',
    firstName: 'Alumna',
    lastName: 'De Prueba',
    email: 'test@aloe.ulima.edu.pe',
    role: 'student',
    currentCycle: '2026-2',
    setupComplete: false,
  ),
  summary: const PortalSyncSummary(
    coursesCreated: 0,
    sectionsCreated: 0,
    sectionsUpdated: 0,
    sessionsUpserted: 0,
    enrollmentsUpserted: 0,
    enrollmentsWithdrawn: 0,
    progressUpserted: 0,
    syllabiUpserted: 0,
  ),
  warnings: const [],
);

/// Un registro listo para enviar, con datos inventados.
RegistroController _listoParaEnviar(
  RegistroService servicio, {
  Future<String?> Function({required String code, required String password})?
  iniciarSesion,
  void Function()? alAdoptar,
}) =>
    RegistroController(
        service: servicio,
        adoptarSesion: ({required token, required user}) async =>
            alAdoptar?.call(),
        iniciarSesion:
            iniciarSesion ?? ({required code, required password}) async => null,
      )
      ..codigoCtrl.text = '20230001'
      ..passwordCtrl.text = 'Contrasena1'
      ..confirmacionCtrl.text = 'Contrasena1'
      ..portalPasswordCtrl.text = 'portal-de-prueba'
      ..passcodeCtrl.text = '123456'
      ..consentimientoAceptado.value = true;

void main() {
  group('el cierre propio del registro (RF-BIEN-9 y B-20)', () {
    testWidgets('cerrar borra los cinco campos enseguida y los desecha '
        'después del cuadro, sin error de un campo desechado', (tester) async {
      final c = RegistroController(
        adoptarSesion: ({required token, required user}) async {},
        iniciarSesion: ({required code, required password}) async => null,
      );
      final campos = [
        c.codigoCtrl,
        c.passwordCtrl,
        c.confirmacionCtrl,
        c.portalPasswordCtrl,
        c.passcodeCtrl,
      ];
      for (final campo in campos) {
        campo.text = 'dato-de-prueba';
      }
      final mostrar = ValueNotifier<bool>(true);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<bool>(
              valueListenable: mostrar,
              builder: (_, visible, _) => visible
                  ? TextField(controller: c.passwordCtrl)
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      );
      // Como la bienvenida, primero saca el campo y en el mismo cuadro cierra.
      mostrar.value = false;
      c.cerrar();
      expect(c.cerrado, isTrue);
      for (final campo in campos) {
        expect(campo.text, '', reason: 'se borra enseguida');
        // Y sigue vivo hasta el cuadro siguiente (B-20).
        expect(() => campo.addListener(() {}), returnsNormally);
      }
      await tester.pump();
      await tester.pump();
      expect(tester.takeException(), isNull);
      for (final campo in campos) {
        expect(() => campo.addListener(() {}), throwsFlutterError);
      }
      // Cerrar dos veces no hace nada.
      c.cerrar();
    });

    for (final exito in [true, false]) {
      testWidgets('una respuesta del envío que llega después de cerrar no toca '
          'los campos desechados (${exito ? 'un 201' : 'un fallo'})', (
        tester,
      ) async {
        final servicio = _ServicioEnVuelo();
        var adopciones = 0;
        final c = _listoParaEnviar(servicio, alAdoptar: () => adopciones++);
        final envio = c.enviar();
        expect(c.paso.value, RegistroPaso.enviando);
        c.cerrar();
        await tester.pump();
        if (exito) {
          servicio.respuesta.complete(_resultado());
        } else {
          servicio.respuesta.completeError(
            const RegistroFailure('Sin conexión.', code: 'SIN_CONEXION'),
          );
        }
        await envio;
        expect(tester.takeException(), isNull);
        expect(c.paso.value, RegistroPaso.enviando, reason: 'se descarta');
        expect(adopciones, 0, reason: 'sin sesión desde un tramo cerrado');
      });
    }

    testWidgets('«Iniciar sesión» desde incierto que responde después de '
        'cerrar devuelve false sin escribir nada', (tester) async {
      final respuesta = Completer<String?>();
      final c = _listoParaEnviar(
        _ServicioEnVuelo(),
        iniciarSesion: ({required code, required password}) => respuesta.future,
      )..paso.value = RegistroPaso.incierto;
      final intento = c.intentarIniciarSesion();
      c.cerrar();
      await tester.pump();
      respuesta.complete(null);
      expect(await intento, isFalse);
      expect(c.errorMessage.value, isNull);
    });

    test('el texto de «Iniciar sesión» desde incierto nombra «Ya tengo '
        'cuenta» (B-30)', () async {
      final c = RegistroController(
        adoptarSesion: ({required token, required user}) async {},
        iniciarSesion: ({required code, required password}) async =>
            'Código o contraseña incorrectos.',
      )..paso.value = RegistroPaso.incierto;
      expect(await c.intentarIniciarSesion(), isFalse);
      expect(
        c.errorMessage.value,
        'Seguimos sin poder confirmarlo. Puedes volver a intentar el '
        'registro: si te dice que ya existe una cuenta con ese código, es que '
        'sí se creó y puedes recuperar la contraseña con “Ya tengo cuenta”.',
      );
    });
  });

  group('las credenciales en la conversación (RF-BIEN-9)', () {
    tearDown(Get.reset);

    test('el historial guarda los rótulos y nunca las contraseñas ni el código '
        'del authenticator', () async {
      final b = Bienvenida();
      await b.visitar();
      final c = b.controlador..responderAlSaludo(yaUsa: false);
      c.registro!.codigoCtrl.text = '20230001';
      c.enviarCodigoDeAlumno();
      c.registro!
        ..passwordCtrl.text = 'Secreta-Ulima-1'
        ..confirmacionCtrl.text = 'Secreta-Ulima-1';
      c.enviarContrasenas();
      c.aceptarConsentimiento();
      c.registro!.portalPasswordCtrl.text = 'Secreta-Portal-1';
      c.enviarPortal();
      c.registro!.passcodeCtrl.text = '482913';
      await c.crearCuenta();
      final textos = <String>[
        for (final e in c.entradas)
          if (e is BurbujaDeUlises) ...[
            e.texto,
            ...e.lineas,
          ] else if (e is RespuestaDelAlumno)
            e.texto,
      ].join('|');
      expect(textos, isNot(contains('Secreta-Ulima-1')));
      expect(textos, isNot(contains('Secreta-Portal-1')));
      expect(textos, isNot(contains('482913')));
      expect(textos, contains('20230001'), reason: 'el código sí se muestra');
    });

    test('el controlador del registro se crea sin Get.put', () async {
      final b = Bienvenida();
      await b.visitar();
      b.controlador.responderAlSaludo(yaUsa: false);
      expect(b.controlador.registro, isNotNull);
      expect(Get.isRegistered<RegistroController>(), isFalse);
      // Un Get.put sobre el campo anulable lo registraría con el tipo
      // anulable.
      expect(Get.isRegistered<RegistroController?>(), isFalse);
    });

    test(
      'se cierra al reiniciar la bienvenida y en el dispose de su visita',
      () async {
        final b = Bienvenida();
        final visita = b.controlador.nuevaVisita();
        await b.controlador.empezarVisita(visita);
        b.controlador.responderAlSaludo(yaUsa: false);
        final registro = b.controlador.registro!;
        b.controlador.terminarVisita(visita);
        expect(registro.cerrado, isTrue);

        // Una visita nueva reinicia la bienvenida y cierra el registro que
        // estuviera abierto, aunque la vieja no haya llegado a su dispose.
        final otra = b.controlador.nuevaVisita();
        await b.controlador.empezarVisita(otra);
        b.controlador.responderAlSaludo(yaUsa: false);
        final segundo = b.controlador.registro!;
        final tercera = b.controlador.nuevaVisita();
        await b.controlador.empezarVisita(tercera);
        expect(segundo.cerrado, isTrue);
        expect(b.controlador.registro, isNull);
      },
    );

    test('el paso al horario cierra el registro que estuviera abierto '
        '(RF-BIEN-11)', () async {
      final b = Bienvenida();
      await b.visitar();
      b.controlador.responderAlSaludo(yaUsa: false);
      final registro = b.controlador.registro!;
      b.controlador.pasoHecho();
      expect(registro.cerrado, isTrue);
      expect(b.controlador.registro, isNull);
      expect(b.controlador.test, isNull);
    });
  });

  group('en pantalla (RF-BIEN-9)', () {
    testWidgets('«Soy nuevo» está en E1 y en E2, y «Ya tengo cuenta» en N1', (
      tester,
    ) async {
      final b = Bienvenida(
        auth: AuthDeLaBienvenida(
          errorDeLogin: 'Código o contraseña incorrectos.',
        ),
      );
      await montarLaBienvenida(
        tester,
        b,
        argumentos: const {argumentoDeMotivo: MotivoDeLlegada.expirada},
      );
      await avanzar(tester, 1500);
      expect(find.text(TextosDeLaBienvenida.soyNuevo), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '20230001');
      await tester.pump();
      await tester.tap(find.byType(BotonDeEnvio));
      await avanzar(tester, 2000);
      expect(find.text(TextosDeLaBienvenida.soyNuevo), findsOneWidget);
      // Un login rechazado no ofrece crear una cuenta.
      await tester.enterText(find.byType(TextField).first, 'mala');
      await tester.pump();
      await tester.tap(find.text(TextosDeLaBienvenida.entrar));
      await avanzar(tester, 2000);
      expect(find.textContaining('crear'), findsNothing);
      expect(find.text(TextosDeLaBienvenida.soyNuevo), findsOneWidget);

      // «Soy nuevo» lleva a N1, que ofrece «Ya tengo cuenta».
      expect(find.text(TextosDeLaBienvenida.yaTengoCuenta), findsNothing);
      await tester.tap(find.text(TextosDeLaBienvenida.soyNuevo));
      await avanzar(tester, 2000);
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.n1Codigo);
      final compositor = find.byType(MarcoDelCompositor);
      expect(
        find.descendant(
          of: compositor,
          matching: find.text(TextosDeLaBienvenida.yaTengoCuenta),
        ),
        findsOneWidget,
      );
      // «Soy nuevo» queda solo como la respuesta del alumno.
      expect(
        find.descendant(
          of: compositor,
          matching: find.text(TextosDeLaBienvenida.soyNuevo),
        ),
        findsNothing,
      );
    });
  });
}
