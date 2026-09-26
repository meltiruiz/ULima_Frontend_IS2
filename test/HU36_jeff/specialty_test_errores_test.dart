// test/HU36_jeff/specialty_test_errores_test.dart
//
// Pruebas de HU36, el test de especialidad, sobre cada fila de la tabla de
// errores y sin conexión (RF-TEST-11).
// Controlador: lib/pages/specialty_test/specialty_test_controller.dart
//
// Datos inventados (datos_de_prueba.dart). El alumno de prueba es 20230001.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/specialty_test_models.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_logic.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_page.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';
import 'montaje_de_pantallas.dart';

ApiException _api(int status, String code, String mensaje, {Object? details}) =>
    ApiException(
      statusCode: status,
      code: code,
      message: mensaje,
      details: details,
    );

const String _noDisponible =
    'El test de especialidad no está disponible para tu carrera.';

void main() {
  // Get.put de un GetxService agenda onReady con
  // Get.engine.addPostFrameCallback, que necesita el binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(Get.reset);
  tearDown(Get.reset);

  _bienvenida();
  _espera();
  _guardados();
  _avisos();
}

void _bienvenida() {
  group(
    'UNITARIA · Errores de la bienvenida y de las preguntas (RF-TEST-11)',
    () {
      test('fila 1: sin conexión, contenido no válido o un 500 dejan el error '
          'con el secundario activo', () async {
        final fallas = <Object>[
          http.ClientException('sin red'),
          contenidoJson()..remove('questions'),
          _api(500, 'INTERNAL_SERVER_ERROR', 'Error del servidor'),
        ];
        for (final falla in fallas) {
          Get.reset();
          final t = prepararTest(ApiFalsaDelTest(contenido: [falla]));
          t.service.pause(
            PausedSpecialtyTest(
              content: SpecialtyTestContent.tryParse(contenidoJson())!,
              answers: const {'q01': 'top'},
              tiebreaks: const [],
            ),
          );
          final ui = UiFalsa();
          final c = await montarControlador(ui: ui);
          expect(c.carga.value, EstadoDeCarga.error, reason: '$falla');
          c.empezar();
          expect(c.fase.value, FaseDelTest.bienvenida);
          // «Saltar y elegir por mi cuenta» sigue activo, y un fallo nunca
          // atrapa al alumno en el asistente.
          c.saltar();
          expect(ui.cierres, [SalidaDelTest.seleccionManual]);
        }
      });

      testWidgets('fila 1: el plazo de 15 s también deja el error', (
        tester,
      ) async {
        prepararTest(
          ApiFalsaDelTest(contenido: [Completer<Map<String, dynamic>>()]),
        );
        final c = Get.put<SpecialtyTestController>(
          SpecialtyTestController(origen: OrigenDelTest.perfil, ui: UiFalsa()),
        );
        await tester.pump(const Duration(seconds: 14));
        expect(c.carga.value, EstadoDeCarga.cargando);
        await tester.pump(const Duration(seconds: 1));
        expect(c.carga.value, EstadoDeCarga.error);
      });

      test('fila 1: «Reintentar» pide otra vez y carga', () async {
        final api = ApiFalsaDelTest(
          contenido: [http.ClientException('sin red'), contenidoJson()],
        );
        prepararTest(api);
        final c = await montarControlador();
        expect(c.carga.value, EstadoDeCarga.error);
        c.reintentarCarga();
        await pumpEventQueue();
        expect(c.carga.value, EstadoDeCarga.lista);
        expect(api.getsDeContenido, 2);
      });

      test('fila 2: el 404 en el asistente pasa a la selección manual sin '
          'aviso', () async {
        final t = prepararTest(
          ApiFalsaDelTest(
            contenido: [
              _api(404, 'SPECIALTY_TEST_NOT_AVAILABLE', _noDisponible),
            ],
          ),
        );
        t.service.prefetchContent();
        await pumpEventQueue();
        final ui = UiFalsa();
        await montarControlador(ui: ui);
        expect(ui.cierres, [SalidaDelTest.seleccionManual]);
        expect(ui.avisos, isEmpty);
      });

      test('fila 2: el 404 en el Perfil avisa con el mensaje del servidor y '
          'cierra la ruta', () async {
        prepararTest(
          ApiFalsaDelTest(
            contenido: [
              _api(404, 'SPECIALTY_TEST_NOT_AVAILABLE', _noDisponible),
            ],
          ),
        );
        final ui = UiFalsa();
        await montarControlador(origen: OrigenDelTest.perfil, ui: ui);
        expect(ui.cierres, [null]);
        expect(ui.avisos.single.tipo, TipoDeAviso.info);
        expect(ui.avisos.single.mensaje, _noDisponible);
      });

      test('fila 3: entre pregunta y pregunta el test no usa la red', () async {
        final api = ApiFalsaDelTest();
        prepararTest(api);
        final c = await montarControlador();
        final antes = api.llamadas.length;
        c.empezar();
        responderPasos(c, ['top', 'both', 'bastante', 'none']);
        c.atras();
        c.alternarHistorial();
        expect(api.llamadas.length, antes);
      });
    },
  );
}

/// Llega hasta la espera con todas las respuestas.
Future<SpecialtyTestController> _hastaLaEspera({
  OrigenDelTest origen = OrigenDelTest.asistente,
  UiFalsa? ui,
}) async {
  final c = await montarControlador(origen: origen, ui: ui);
  c.empezar();
  responderPasos(c, respuestasEnOrden);
  await pumpEventQueue();
  return c;
}

void _espera() {
  group('UNITARIA · Errores de la espera (RF-TEST-11)', () {
    test('fila 4: sin conexión deja el aviso de la espera, las respuestas y '
        '«Pregunta anterior»', () async {
      prepararTest(
        ApiFalsaDelTest(evaluaciones: [http.ClientException('sin red')]),
      );
      final c = await _hastaLaEspera();
      expect(c.fase.value, FaseDelTest.espera);
      expect(c.errorDeEspera.value!.kind, SpecialtyTestFailureKind.offline);
      expect(
        c.textoDelErrorDeEspera,
        'No pudimos conectarnos. Revisa tu conexión e inténtalo de nuevo.',
      );
      expect(c.respuestas, respuestasCompletas());
      c.atras();
      expect(c.fase.value, FaseDelTest.pregunta);
      expect(c.errorDeEspera.value, isNull);
    });

    testWidgets('fila 4: el plazo de 20 s también', (tester) async {
      prepararTest(
        ApiFalsaDelTest(evaluaciones: [Completer<Map<String, dynamic>>()]),
      );
      final c = Get.put<SpecialtyTestController>(
        SpecialtyTestController(origen: OrigenDelTest.asistente, ui: UiFalsa()),
      );
      await tester.pump();
      c.empezar();
      responderPasos(c, respuestasEnOrden);
      await tester.pump(const Duration(seconds: 19));
      expect(c.errorDeEspera.value, isNull);
      await tester.pump(const Duration(seconds: 1));
      expect(c.errorDeEspera.value!.kind, SpecialtyTestFailureKind.offline);
    });

    test('fila 5: un 409 o un 400 de respuestas abre el diálogo y «Empezar de '
        'nuevo» pide el contenido y abre la pregunta 1', () async {
      for (final falla in [
        _api(
          409,
          'SPECIALTY_TEST_VERSION_OUTDATED',
          'El test se actualizó. Vuelve a empezarlo.',
          details: {'currentVersion': '2026-09-25.5'},
        ),
        _api(
          400,
          'SPECIALTY_TEST_INVALID_ANSWERS',
          'Las respuestas no corresponden a esta versión del test.',
        ),
      ]) {
        Get.reset();
        final api = ApiFalsaDelTest(
          contenido: [
            contenidoJson(),
            contenidoJson(version: '2026-09-25.5'),
          ],
          evaluaciones: [falla],
        );
        prepararTest(api);
        final ui = UiFalsa()..dialogo = Completer<void>();
        final c = await _hastaLaEspera(ui: ui);
        expect(ui.reinicios, [falla.message]);
        expect(c.fase.value, FaseDelTest.espera);
        ui.dialogo!.complete();
        await pumpEventQueue();
        expect(api.getsDeContenido, 2);
        expect(c.fase.value, FaseDelTest.pregunta);
        expect(c.paso.value, 0);
        expect(c.respuestas, isEmpty);
        expect(c.contenido.value!.version, '2026-09-25.5');
      }
    });

    test('fila 6: el 404 al evaluar avisa, borra las respuestas y cierra '
        'según el origen', () async {
      for (final origen in OrigenDelTest.values) {
        Get.reset();
        final t = prepararTest(
          ApiFalsaDelTest(
            evaluaciones: [
              _api(404, 'SPECIALTY_TEST_NOT_AVAILABLE', _noDisponible),
            ],
          ),
        );
        final ui = UiFalsa();
        final c = await _hastaLaEspera(origen: origen, ui: ui);
        expect(ui.avisos.single.mensaje, _noDisponible);
        expect(ui.avisos.single.tipo, TipoDeAviso.info);
        // El asistente y la bienvenida terminan en la selección manual, y
        // el Perfil cierra su ruta (enmienda de la bienvenida a RF-TEST-1).
        expect(ui.cierres, [
          origen == OrigenDelTest.perfil ? null : SalidaDelTest.seleccionManual,
        ]);
        expect(c.respuestas, isEmpty);
        expect(c.errorDeEspera.value, isNull);
        Get.delete<SpecialtyTestController>();
        expect(t.service.paused, isNull);
      }
    });

    test('fila 7: el desempate que no coincide se repite una vez sin '
        'desempates y sigue con lo que responda el servidor', () async {
      final api = ApiFalsaDelTest(
        evaluaciones: [
          desempateJson(),
          _api(
            400,
            'SPECIALTY_TEST_TIEBREAK_MISMATCH',
            'Los desempates enviados no son los que corresponden a estas '
                'respuestas.',
            details: {'expected': null},
          ),
          resultadoJson(),
        ],
      );
      prepararTest(api);
      final c = await _hastaLaEspera();
      responderPasos(c, ['top']);
      await pumpEventQueue();
      expect(api.cuerposDeEvaluacion, hasLength(3));
      expect(api.cuerposDeEvaluacion[1]['tiebreakAnswers'], isNotEmpty);
      expect(api.cuerposDeEvaluacion[2]['tiebreakAnswers'], isEmpty);
      expect(c.fase.value, FaseDelTest.resultado);
    });

    test('fila 7: si vuelve a fallar, queda el error de la espera', () async {
      final mismatch = _api(
        400,
        'SPECIALTY_TEST_TIEBREAK_MISMATCH',
        'Los desempates enviados no son los que corresponden a estas '
            'respuestas.',
      );
      final api = ApiFalsaDelTest(
        evaluaciones: [desempateJson(), mismatch, mismatch],
      );
      prepararTest(api);
      final c = await _hastaLaEspera();
      responderPasos(c, ['top']);
      await pumpEventQueue();
      expect(api.cuerposDeEvaluacion, hasLength(3));
      expect(
        c.errorDeEspera.value!.kind,
        SpecialtyTestFailureKind.tiebreakMismatch,
      );
      c.atras();
      expect(c.paso.value, 4);
      expect(c.desempates, isEmpty);
    });

    test('fila 8: el 429 muestra el mensaje del servidor y conserva las '
        'respuestas', () async {
      const mensaje =
          'Hiciste demasiados intentos del test. Intenta de nuevo en 12 '
          'minuto(s).';
      final api = ApiFalsaDelTest(
        evaluaciones: [
          _api(
            429,
            'RATE_LIMITED',
            mensaje,
            details: {'retryAfterMinutes': 12},
          ),
          resultadoJson(),
        ],
      );
      prepararTest(api);
      final c = await _hastaLaEspera();
      expect(c.textoDelErrorDeEspera, mensaje);
      expect(c.respuestas, respuestasCompletas());
      c.reintentarEvaluacion();
      await pumpEventQueue();
      expect(c.fase.value, FaseDelTest.resultado);
    });

    test('fila 9: un 413 o un 500 muestran el mensaje del servidor y '
        '«Reintentar»', () async {
      for (final falla in [
        _api(413, 'PAYLOAD_TOO_LARGE', 'La petición es demasiado grande.'),
        _api(500, 'INTERNAL_SERVER_ERROR', 'Error del servidor'),
      ]) {
        Get.reset();
        prepararTest(ApiFalsaDelTest(evaluaciones: [falla]));
        final c = await _hastaLaEspera();
        expect(c.textoDelErrorDeEspera, falla.message);
      }
    });

    test('fila 10: si Cohere falla, el resultado llega igual con el motivo '
        'de las plantillas', () async {
      prepararTest(ApiFalsaDelTest(evaluaciones: [resultadoJson()]));
      final c = await _hastaLaEspera();
      expect(c.fase.value, FaseDelTest.resultado);
      expect(c.resultado.value!.reasonByAi, isFalse);
    });
  });
}

void _guardados() {
  group('UNITARIA · Errores de los guardados del resultado (RF-TEST-11)', () {
    Future<({SpecialtyTestController c, AuthDelControlador auth, UiFalsa ui})>
    alResultado() async {
      final t = prepararTest(ApiFalsaDelTest());
      final ui = UiFalsa();
      final c = await _hastaLaEspera(ui: ui);
      expect(c.fase.value, FaseDelTest.resultado);
      return (c: c, auth: t.auth, ui: ui);
    }

    test('fila 11: un PUT que falla avisa con el mensaje del servidor o el '
        'propio, y el corazón vuelve', () async {
      final r = await alResultado();
      r.auth.respuestasDeGuardado
        ..add(_api(404, 'SPECIALTY_NOT_FOUND', 'Mensaje de prueba del 404.'))
        ..add(Exception('sin red'));
      r.c.alternarCorazon(kIdSi);
      await pumpEventQueue();
      expect(r.c.corazones, isEmpty);
      expect(r.ui.avisos.last.mensaje, 'Mensaje de prueba del 404.');
      expect(r.ui.avisos.last.tipo, TipoDeAviso.error);
      r.c.alternarCorazon(kIdTi);
      await pumpEventQueue();
      expect(r.c.corazones, isEmpty);
      expect(
        r.ui.avisos.last.mensaje,
        'No se pudo guardar. Revisa tu conexión e inténtalo de nuevo.',
      );
      expect(r.c.fase.value, FaseDelTest.resultado);
    });

    test('fila 12: un PUT sin respuesta en 15 s avisa que no se confirmó, y '
        'el asistente no termina', () async {
      final r = await alResultado();
      r.c.alternarCorazon(kIdSi);
      await pumpEventQueue();
      r.auth.respuestasDeGuardado
        ..add(TimeoutException('plazo'))
        ..add(TimeoutException('plazo'));
      r.c.alternarCorazon(kIdTi);
      await pumpEventQueue();
      expect(r.c.corazones, {kIdSi});
      await r.c.elegirPrincipal(kIdVj);
      expect(r.ui.alHome, 0);
      expect(r.c.botonesActivos, isTrue);
      expect(r.ui.avisos.map((a) => a.mensaje), [
        'No se pudo confirmar el guardado. Revisa tu conexión e inténtalo de '
            'nuevo.',
        'No se pudo confirmar el guardado. Revisa tu conexión e inténtalo de '
            'nuevo.',
      ]);
      // Repetir es seguro, porque cada PUT manda la selección entera.
      await r.c.elegirPrincipal(kIdVj);
      expect(r.ui.alHome, 1);
      expect(
        r.auth.guardados.last,
        const SeleccionDeEspecialidades(principal: kIdVj, intereses: [kIdSi]),
      );
    });
  });
}

void _avisos() {
  group('WIDGET · Los avisos y el diálogo de la ruta (RF-TEST-11)', () {
    testWidgets('fila 13: el aviso de error va en blanco sobre errorBg y el '
        'que informa, en cardBg con borde', (tester) async {
      prepararTest(ApiFalsaDelTest());
      await abrirLaRuta(tester);
      const ui = UiDelTestConGet();
      const b = Brightness.light;
      ui.avisar(const AvisoDelTest(TipoDeAviso.error, 'Aviso de prueba.'));
      await asentar(tester);
      var barra = tester.widget<GetSnackBar>(find.byType(GetSnackBar));
      expect(barra.backgroundColor, MaterialTheme.errorBg(b));
      expect(colorDeTexto(tester, 'Aviso de prueba.'), Colors.white);
      await tester.pump(const Duration(seconds: 5));
      await asentar(tester);
      ui.avisar(const AvisoDelTest(TipoDeAviso.info, 'Otro aviso de prueba.'));
      await asentar(tester);
      barra = tester.widget<GetSnackBar>(find.byType(GetSnackBar));
      expect(barra.backgroundColor, MaterialTheme.cardBg(b));
      expect(barra.borderColor, MaterialTheme.borderColor(b));
      expect(
        colorDeTexto(tester, 'Otro aviso de prueba.'),
        MaterialTheme.textPrimary(b),
      );
      // Con el aviso abierto, cerrar la ruta la cierra igual.
      ui.cerrar();
      await asentar(tester);
      expect(find.text('Pantalla de inicio'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await asentar(tester);
    });

    testWidgets('fila 5: el diálogo trae el mensaje y «Empezar de nuevo», y '
        'el atrás no lo cierra', (tester) async {
      prepararTest(ApiFalsaDelTest());
      await abrirLaRuta(tester);
      const ui = UiDelTestConGet();
      var tocado = false;
      unawaited(
        ui
            .pedirReinicio('El test se actualizó. Vuelve a empezarlo.')
            .then((_) => tocado = true),
      );
      await asentar(tester);
      expect(
        find.text('El test se actualizó. Vuelve a empezarlo.'),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await asentar(tester);
      expect(find.text('Empezar de nuevo'), findsOneWidget);
      expect(tocado, isFalse);
      await tester.tap(find.text('Empezar de nuevo'));
      await asentar(tester);
      expect(tocado, isTrue);
    });
  });
}
