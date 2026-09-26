// test/HU36_jeff/specialty_test_conversacion_test.dart
//
// Pruebas de HU36, el test de especialidad, sobre la conversación con Ulises
// (RF-TEST-4).
// Controlador: lib/pages/specialty_test/specialty_test_controller.dart
//
// Datos inventados (datos_de_prueba.dart). El alumno de prueba es 20230001.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/specialty_test_models.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/question_view.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/ulises_bubble.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';
import 'montaje_de_pantallas.dart';

TiebreakRecord _desempate(int order, {String? respuesta}) => TiebreakRecord(
  tiebreak:
      (EvaluationStep.tryParse(
                desempateJson(order: order, id: 'tb-si-vj-$order'),
              )!
              as TiebreakStep)
          .tiebreak,
  ulisesLine: 'Línea del desempate $order.',
  answer: respuesta,
);

void main() {
  // Get.put de un GetxService agenda onReady con
  // Get.engine.addPostFrameCallback, que necesita el binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(Get.reset);
  tearDown(Get.reset);

  _controlador();
  _pantalla();
  _ruta();
}

void _controlador() {
  group('UNITARIA · Recorrido en el controlador (RF-TEST-4)', () {
    test('caso 1: responder y avanzar recorren las preguntas y guardan cada '
        'respuesta', () async {
      prepararTest(ApiFalsaDelTest());
      final c = await montarControlador();
      c.empezar();
      responderPasos(c, ['top', 'both']);
      expect(c.paso.value, 2);
      expect(c.respuestas, {'q01': 'top', 'q02': 'both'});
      expect(c.preguntaActual!.type, TestQuestionType.scale);
      expect(c.respuestaActual, isNull);
    });

    testWidgets('caso 2: el avance solo llega a los 350 ms y los toques de '
        'ese tiempo no cuentan', (tester) async {
      prepararTest(ApiFalsaDelTest());
      // Dentro de testWidgets el tiempo es falso y pumpEventQueue no avanza,
      // así que la carga corre con tester.pump().
      final c = Get.put<SpecialtyTestController>(
        SpecialtyTestController(origen: OrigenDelTest.asistente, ui: UiFalsa()),
      );
      await tester.pump();
      c.empezar();
      c.responder('top');
      expect(c.bloqueado.value, isTrue);
      c.responder('bottom');
      await tester.pump(const Duration(milliseconds: 349));
      expect(c.paso.value, 0);
      expect(c.respuestas['q01'], 'top');
      await tester.pump(const Duration(milliseconds: 1));
      expect(c.paso.value, 1);
      expect(c.bloqueado.value, isFalse);
    });

    test('caso 3: sin avance solo, la respuesta queda marcada hasta '
        '«Siguiente»', () async {
      prepararTest(ApiFalsaDelTest());
      final c = await montarControlador();
      c.empezar();
      c.responder('none', avanceSolo: false);
      expect(c.paso.value, 0);
      expect(c.respuestaActual, 'none');
      c.responder('top', avanceSolo: false);
      expect(c.respuestaActual, 'top');
      c.avanzar();
      expect(c.paso.value, 1);
      // Sin respuesta, «Siguiente» no avanza.
      c.avanzar();
      expect(c.paso.value, 1);
    });

    test('caso 4: atrás lleva a la anterior con su respuesta marcada, y desde '
        'la 1 a la bienvenida', () async {
      prepararTest(ApiFalsaDelTest());
      final c = await montarControlador();
      c.empezar();
      responderPasos(c, ['top', 'both']);
      c.atras();
      expect(c.paso.value, 1);
      expect(c.respuestaActual, 'both');
      c.atras();
      c.atras();
      expect(c.fase.value, FaseDelTest.bienvenida);
      expect(c.hayAvance, isTrue);
      c.empezar();
      expect(c.paso.value, 2);
    });

    test('caso 5: la última respuesta lleva a la espera, también si se '
        'repite la misma', () async {
      prepararTest(ApiFalsaDelTest());
      final c = await montarControlador();
      c.empezar();
      responderPasos(c, respuestasEnOrden);
      expect(c.fase.value, FaseDelTest.espera);
      c.atras();
      expect(c.fase.value, FaseDelTest.pregunta);
      expect(c.paso.value, 4);
      expect(c.respuestaActual, 'nada');
      responderPasos(c, ['nada']);
      expect(c.fase.value, FaseDelTest.espera);
    });

    test('caso 6: cambiar una pregunta borra los desempates y cambiar el 1 '
        'borra el 2', () async {
      final t = prepararTest(ApiFalsaDelTest());
      t.service.pause(
        PausedSpecialtyTest(
          content: SpecialtyTestContent.tryParse(contenidoJson())!,
          answers: respuestasCompletas(),
          tiebreaks: [
            _desempate(1, respuesta: 'top'),
            _desempate(2),
          ],
        ),
      );
      final c = await montarControlador();
      c.empezar();
      expect(c.paso.value, 6);
      expect(c.enDesempate, isTrue);
      c.atras();
      expect(c.paso.value, 5);
      expect(c.respuestaActual, 'top');
      c.responder('none', avanceSolo: false);
      expect(c.desempates, hasLength(1));
      expect(c.desempates.single.answer, 'none');
      c.atras();
      expect(c.paso.value, 4);
      c.responder('nada', avanceSolo: false);
      expect(c.desempates, isEmpty);
    });

    test('caso 7: el historial se despliega y se pliega, y se pliega al '
        'avanzar', () async {
      prepararTest(ApiFalsaDelTest());
      final c = await montarControlador();
      c.empezar();
      responderPasos(c, ['top']);
      c.alternarHistorial();
      expect(c.historialAbierto.value, isTrue);
      c.alternarHistorial();
      expect(c.historialAbierto.value, isFalse);
      c.alternarHistorial();
      responderPasos(c, ['both']);
      expect(c.historialAbierto.value, isFalse);
    });

    test('caso 8: pausar cierra la ruta y deja las respuestas y la copia en '
        'el service', () async {
      final t = prepararTest(ApiFalsaDelTest());
      final ui = UiFalsa();
      final c = await montarControlador(ui: ui);
      c.empezar();
      responderPasos(c, ['top', 'both']);
      c.pausar();
      expect(ui.cierres, [null]);
      Get.delete<SpecialtyTestController>();
      expect(t.service.paused!.answers, {'q01': 'top', 'q02': 'both'});
      expect(t.service.paused!.answeredQuestions, 2);
    });
  });
}

/// Monta la conversación en la pregunta 1 y deja al controlador a mano.
Future<SpecialtyTestController> _conversacion(
  WidgetTester tester, {
  UiFalsa? ui,
}) async {
  prepararTest(ApiFalsaDelTest());
  final c = ponerControlador(ui: ui);
  await tester.pump();
  c.empezar();
  await montarPantalla(tester, const QuestionView());
  return c;
}

/// Responde tocando y deja pasar el avance y la transición.
Future<void> _tocarYAvanzar(WidgetTester tester, Finder objetivo) async {
  await tester.tap(objetivo);
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump(const Duration(milliseconds: 200));
}

List<String> _burbujas(WidgetTester tester) => tester
    .widgetList<UlisesBubble>(find.byType(UlisesBubble))
    .map((b) => b.text)
    .toList();

void _pantalla() {
  group('WIDGET · La conversación con Ulises (RF-TEST-4)', () {
    testWidgets('caso 9: la barra dice «Pregunta N de T» con las preguntas '
        'del contenido', (tester) async {
      await _conversacion(tester);
      expect(find.text('Ulises'), findsOneWidget);
      expect(find.text('Pregunta 1 de 5'), findsOneWidget);
      expect(find.byTooltip('Pregunta anterior'), findsOneWidget);
      expect(find.byTooltip('Pausar el test y seguir luego'), findsOneWidget);
      await _tocarYAvanzar(tester, find.byKey(QuestionView.tarjetaKey('top')));
      expect(find.text('Pregunta 2 de 5'), findsOneWidget);
    });

    testWidgets('caso 10: las plumas van llenas hasta la actual y vacías '
        'después, siempre en naranja', (tester) async {
      await _conversacion(tester);
      await _tocarYAvanzar(tester, find.byKey(QuestionView.tarjetaKey('top')));
      const b = Brightness.light;
      Color pluma(int i) =>
          tester.widget<Icon>(find.byKey(TestFeathers.plumaKey(i))).color!;
      expect(pluma(0), MaterialTheme.testFeatherOn(b));
      expect(pluma(1), MaterialTheme.testFeatherOn(b));
      expect(pluma(2), MaterialTheme.testFeatherOff(b));
      expect(pluma(4), MaterialTheme.testFeatherOff(b));
    });

    testWidgets('caso 10b: al volver del desempate 1 a la última pregunta, '
        'la pluma actual vuelve a brillar', (tester) async {
      final t = prepararTest(ApiFalsaDelTest());
      t.service.pause(
        PausedSpecialtyTest(
          content: SpecialtyTestContent.tryParse(contenidoJson())!,
          answers: respuestasCompletas(),
          tiebreaks: [_desempate(1)],
        ),
      );
      final c = ponerControlador();
      await tester.pump();
      c.empezar();
      expect(c.enDesempate, isTrue);
      await montarPantalla(tester, const QuestionView());
      double brillo() =>
          tester
              .widget<Icon>(find.byKey(TestFeathers.plumaKey(4)))
              .shadows
              ?.single
              .color
              .a ??
          0;
      expect(brillo(), 0);
      await tester.tap(find.byTooltip('Pregunta anterior'));
      await tester.pump();
      expect(c.paso.value, 4);
      await tester.pump(const Duration(milliseconds: 800));
      expect(brillo(), greaterThan(0));
    });

    testWidgets('caso 11: en pantalla queda solo el último turno de Ulises, '
        'con sus reglas', (tester) async {
      await _conversacion(tester);
      expect(_burbujas(tester), [kDuelHelp]);
      await _tocarYAvanzar(tester, find.byKey(QuestionView.tarjetaKey('top')));
      expect(_burbujas(tester), ['Reacción propia de la pregunta uno.']);
      await _tocarYAvanzar(tester, find.text('Me gustan las dos'));
      expect(_burbujas(tester), [kBoth[0], kScaleHelp]);
      await _tocarYAvanzar(tester, find.text('Bastante'));
      expect(_burbujas(tester), ['Cierre de prueba del bloque uno.']);
      expect(find.text('Cierra el bloque 1 de 2'), findsOneWidget);
    });

    testWidgets('caso 12: ninguna línea ni rótulo nombra una especialidad', (
      tester,
    ) async {
      await _conversacion(tester);
      for (final nombre in [
        'Ingeniería de Software',
        'Tecnologías de la Información',
        'Sistemas de Información',
        'Desarrollo de Videojuegos',
      ]) {
        expect(find.textContaining(nombre), findsNothing);
      }
    });

    testWidgets('caso 13: la pastilla del historial se despliega y se pliega', (
      tester,
    ) async {
      await _conversacion(tester);
      expect(find.text('1 respuesta anterior'), findsNothing);
      await _tocarYAvanzar(tester, find.byKey(QuestionView.tarjetaKey('top')));
      expect(find.text('1 respuesta anterior'), findsOneWidget);
      expect(find.byKey(QuestionView.historialKey), findsNothing);
      await tester.tap(find.text('1 respuesta anterior'));
      await tester.pump();
      expect(find.byKey(QuestionView.historialKey), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(QuestionView.historialKey),
          matching: find.textContaining('Tarea de prueba uno arriba'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('1 respuesta anterior'));
      await tester.pump();
      expect(find.byKey(QuestionView.historialKey), findsNothing);
    });

    testWidgets(
      'caso 14: «Pregunta anterior» vuelve con la respuesta marcada',
      (tester) async {
        final c = await _conversacion(tester);
        await _tocarYAvanzar(
          tester,
          find.byKey(QuestionView.tarjetaKey('top')),
        );
        await tester.tap(find.byTooltip('Pregunta anterior'));
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.text('Pregunta 1 de 5'), findsOneWidget);
        expect(find.byIcon(LucideIcons.check), findsOneWidget);
        expect(c.respuestaActual, 'top');
      },
    );

    testWidgets('caso 15: «Pausar el test y seguir luego» cierra la ruta', (
      tester,
    ) async {
      final ui = UiFalsa();
      await _conversacion(tester, ui: ui);
      await tester.tap(find.byTooltip('Pausar el test y seguir luego'));
      expect(ui.cierres, [null]);
    });
  });
}

void _ruta() {
  group('WIDGET · El atrás del sistema en la ruta (RF-TEST-1 y RF-TEST-4)', () {
    testWidgets('caso 16: el argumento dice el origen y el atrás en la '
        'bienvenida cierra la ruta sin salida', (tester) async {
      final t = prepararTest(ApiFalsaDelTest());
      final salida = await abrirLaRuta(tester, origen: OrigenDelTest.perfil);
      final c = Get.find<SpecialtyTestController>();
      expect(c.origen, OrigenDelTest.perfil);
      c.empezar();
      responderPasos(c, ['top']);
      c.atras();
      c.atras();
      await asentar(tester);
      expect(c.fase.value, FaseDelTest.bienvenida);
      await tester.binding.handlePopRoute();
      await asentar(tester);
      expect(find.text('Pantalla de inicio'), findsOneWidget);
      expect(await salida, isNull);
      // El controlador murió con la ruta y dejó el avance en pausa.
      expect(Get.isRegistered<SpecialtyTestController>(), isFalse);
      expect(t.service.paused!.answers, {'q01': 'top'});
    });

    testWidgets('caso 17: en una pregunta, el atrás del sistema lleva a la '
        'anterior y desde la espera, a la pregunta', (tester) async {
      prepararTest(
        ApiFalsaDelTest(evaluaciones: [Completer<Map<String, dynamic>>()]),
      );
      await abrirLaRuta(tester);
      final c = Get.find<SpecialtyTestController>();
      c.empezar();
      responderPasos(c, ['top', 'both']);
      await asentar(tester);
      await tester.binding.handlePopRoute();
      await asentar(tester);
      expect(c.paso.value, 1);
      expect(find.text('Pregunta 2 de 5'), findsOneWidget);
      responderPasos(c, ['both', 'nada', 'top', 'nada']);
      await tester.pump();
      expect(c.fase.value, FaseDelTest.espera);
      await tester.binding.handlePopRoute();
      await asentar(tester);
      expect(c.fase.value, FaseDelTest.pregunta);
      expect(c.paso.value, 4);
      // La evaluación en vuelo vence y se descarta.
      await tester.pump(const Duration(seconds: 20));
    });
  });
}
