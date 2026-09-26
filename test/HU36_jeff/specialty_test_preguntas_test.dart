// test/HU36_jeff/specialty_test_preguntas_test.dart
//
// Pruebas de widget de HU36, el test de especialidad, sobre el duelo
// (RF-TEST-5) y la escala de gusto (RF-TEST-6), con los íconos de Lucide de
// cada tarea.
// Pantalla: lib/pages/specialty_test/widgets/question_view.dart
//
// Datos inventados (datos_de_prueba.dart). El alumno de prueba es 20230001.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/specialty_test_models.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/question_view.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/task_icon.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';
import 'montaje_de_pantallas.dart';

const Color _swClaro = Color(0xFF1E3A8A);
const Color _swOscuro = Color(0xFFA5C0F7);

/// Abre la pregunta de índice [indice] con las respuestas anteriores de
/// [respuestasCompletas] y monta la pantalla.
Future<SpecialtyTestController> _enLaPregunta(
  WidgetTester tester, {
  int indice = 0,
  Brightness brillo = Brightness.light,
  double escala = 1.0,
  Size tamano = kIphoneSE,
  Map<String, dynamic>? contenido,
}) async {
  prepararTest(ApiFalsaDelTest(contenido: [contenido ?? contenidoJson()]));
  final c = ponerControlador();
  await tester.pump();
  c.empezar();
  responderPasos(c, respuestasEnOrden.take(indice).toList());
  await montarPantalla(
    tester,
    const QuestionView(),
    brillo: brillo,
    escala: escala,
    tamano: tamano,
  );
  return c;
}

BoxDecoration _decoracion(WidgetTester tester, String valor) =>
    tester
            .widget<AnimatedContainer>(
              find
                  .descendant(
                    of: find.byKey(QuestionView.tarjetaKey(valor)),
                    matching: find.byType(AnimatedContainer),
                  )
                  .first,
            )
            .decoration!
        as BoxDecoration;

TaskIconTile _baldosa(WidgetTester tester, String valor) =>
    tester.widget<TaskIconTile>(
      find.descendant(
        of: find.byKey(QuestionView.tarjetaKey(valor)),
        matching: find.byType(TaskIconTile),
      ),
    );

Icon _icono(WidgetTester tester, Finder dentroDe) => tester.widget<Icon>(
  find.descendant(
    of: find.descendant(of: dentroDe, matching: find.byType(TaskIconTile)),
    matching: find.byType(Icon),
  ),
);

void main() {
  // Get.put de un GetxService agenda onReady con
  // Get.engine.addPostFrameCallback, que necesita el binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(Get.reset);
  tearDown(Get.reset);

  _duelo();
  _escala();
}

void _duelo() {
  group('WIDGET · El duelo (RF-TEST-5)', () {
    testWidgets('caso 1: antes del toque las dos tarjetas son neutras', (
      tester,
    ) async {
      await _enLaPregunta(tester);
      const b = Brightness.light;
      for (final valor in ['top', 'bottom']) {
        final d = _decoracion(tester, valor);
        expect(d.color, MaterialTheme.cardBg(b));
        expect(d.border!.top.color, MaterialTheme.testLine(b));
        // El borde de 1 px, que pasa a 1,5 solo en la encendida.
        expect(d.border!.top.width, 1);
        expect(_baldosa(tester, valor).color, isNull);
      }
      expect(
        _icono(tester, find.byKey(QuestionView.tarjetaKey('top'))).color,
        MaterialTheme.testTaskIconInk(b),
      );
      expect(find.text('ESTO O AQUELLO'), findsOneWidget);
      expect(find.text('¿Cuál harías con más ganas?'), findsOneWidget);
      expect(find.byIcon(LucideIcons.check), findsNothing);
    });

    testWidgets('caso 2: al tocar, la tarjeta se enciende con el color de su '
        'especialidad y la otra se apaga', (tester) async {
      final c = await _enLaPregunta(tester);
      await tester.tap(find.byKey(QuestionView.tarjetaKey('top')));
      await tester.pump(const Duration(milliseconds: 150));
      final d = _decoracion(tester, 'top');
      expect(d.border!.top.color, _swClaro);
      expect(d.border!.top.width, 1.5);
      expect(d.boxShadow!.single.spreadRadius, 4);
      expect(_baldosa(tester, 'top').color, _swClaro);
      expect(_baldosa(tester, 'bottom').apagada, isTrue);
      expect(_decoracion(tester, 'bottom').border!.top.width, 1);
      final otra = tester.widget<Text>(find.text('Tarea de prueba uno abajo'));
      expect(otra.style!.color, MaterialTheme.testInk2(Brightness.light));
      expect(otra.style!.fontWeight, FontWeight.w600);
      expect(find.byIcon(LucideIcons.check), findsOneWidget);
      expect(c.respuestas['q01'], 'top');
      await tester.pump(const Duration(milliseconds: 250));
    });

    testWidgets('caso 2b: el toque en una tarjeta suena con '
        'HapticFeedback.selectionClick', (tester) async {
      await _enLaPregunta(tester);
      final vibraciones = escucharVibraciones(tester);
      await tester.tap(find.byKey(QuestionView.tarjetaKey('bottom')));
      await tester.pump();
      expect(vibraciones, ['HapticFeedbackType.selectionClick']);
      await tester.pump(const Duration(milliseconds: 550));
    });

    testWidgets('caso 3: en oscuro se enciende con color.dark', (tester) async {
      await _enLaPregunta(tester, brillo: Brightness.dark);
      await tester.tap(find.byKey(QuestionView.tarjetaKey('top')));
      await tester.pump(const Duration(milliseconds: 150));
      expect(_decoracion(tester, 'top').border!.top.color, _swOscuro);
      await tester.pump(const Duration(milliseconds: 250));
    });

    testWidgets('caso 4: «Me gustan las dos» enciende las dos y «Ninguna me '
        'llama» apaga las dos', (tester) async {
      await _enLaPregunta(tester);
      await tester.tap(find.text('Me gustan las dos'));
      await tester.pump(const Duration(milliseconds: 150));
      expect(_baldosa(tester, 'top').color, isNotNull);
      expect(_baldosa(tester, 'bottom').color, isNotNull);
      expect(find.byIcon(LucideIcons.check), findsNWidgets(2));
      await tester.pump(const Duration(milliseconds: 250));
      Get.reset();
      await _enLaPregunta(tester);
      await tester.tap(find.text('Ninguna me llama'));
      await tester.pump(const Duration(milliseconds: 150));
      expect(_baldosa(tester, 'top').apagada, isTrue);
      expect(_baldosa(tester, 'bottom').apagada, isTrue);
      expect(find.byIcon(LucideIcons.check), findsNothing);
      await tester.pump(const Duration(milliseconds: 250));
    });

    testWidgets('caso 5: avanza sola a los 350 ms y otro toque en ese tiempo '
        'no hace nada', (tester) async {
      final c = await _enLaPregunta(tester);
      await tester.tap(find.byKey(QuestionView.tarjetaKey('top')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(QuestionView.tarjetaKey('bottom')));
      await tester.pump(const Duration(milliseconds: 249));
      expect(c.paso.value, 0);
      expect(c.respuestas['q01'], 'top');
      await tester.pump(const Duration(milliseconds: 1));
      expect(c.paso.value, 1);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Tarea de prueba dos arriba'), findsOneWidget);
    });

    for (final (objetivo, ms) in [
      (find.byKey(QuestionView.tarjetaKey('bottom')), 10),
      (find.text('Ninguna me llama'), 5),
    ]) {
      testWidgets('caso 5b: un toque en la pregunta que sale, a los $ms ms '
          'del avance, no responde la que entra', (tester) async {
        final c = await _enLaPregunta(tester, indice: 1);
        await tester.tap(find.byKey(QuestionView.tarjetaKey('top')));
        await tester.pump(const Duration(milliseconds: 350));
        expect(c.paso.value, 2);
        await tester.pump(Duration(milliseconds: ms));
        // Solo la pregunta 2, que sale, tiene tarjetas y esos botones.
        await tester.tap(objetivo, warnIfMissed: false);
        await tester.pump();
        expect(c.respuestas.containsKey('q03'), isFalse);
        expect(c.respuestas['q02'], 'top');
        await tester.pump(const Duration(milliseconds: 550));
        expect(c.paso.value, 2);
      });
    }

    testWidgets('caso 6: el ícono de la tarea es el de su nombre, y uno '
        'desconocido cae al neutro', (tester) async {
      await _enLaPregunta(tester);
      expect(
        _icono(tester, find.byKey(QuestionView.tarjetaKey('top'))).icon,
        LucideIcons.shoppingCart,
      );
      expect(
        _icono(tester, find.byKey(QuestionView.tarjetaKey('bottom'))).icon,
        LucideIcons.shelvingUnit,
      );
      Get.reset();
      await _enLaPregunta(
        tester,
        contenido: contenidoJson(iconoDeLaPrimera: 'icono-que-no-existe'),
      );
      expect(
        _icono(tester, find.byKey(QuestionView.tarjetaKey('top'))).icon,
        LucideIcons.sparkles,
      );
    });

    testWidgets('caso 7: el desempate usa la misma pantalla, con su rótulo y '
        'sus íconos, neutros hasta el toque', (tester) async {
      final t = prepararTest(ApiFalsaDelTest());
      t.service.pause(
        PausedSpecialtyTest(
          content: SpecialtyTestContent.tryParse(contenidoJson())!,
          answers: respuestasCompletas(),
          tiebreaks: [
            TiebreakRecord(
              tiebreak:
                  (EvaluationStep.tryParse(desempateJson())! as TiebreakStep)
                      .tiebreak,
              ulisesLine: 'Línea del desempate de prueba.',
            ),
          ],
        ),
      );
      final c = ponerControlador();
      await tester.pump();
      c.empezar();
      await montarPantalla(tester, const QuestionView());
      expect(find.text('DESEMPATE'), findsOneWidget);
      expect(find.text('Desempate 1'), findsOneWidget);
      expect(find.text('Línea del desempate de prueba.'), findsOneWidget);
      final top = find.byKey(QuestionView.tarjetaKey('top'));
      expect(_icono(tester, top).icon, LucideIcons.soup);
      expect(
        _icono(tester, top).color,
        MaterialTheme.testTaskIconInk(Brightness.light),
      );
      await tester.tap(top);
      await tester.pump(const Duration(milliseconds: 150));
      // `si` en claro.
      expect(_icono(tester, top).color, const Color(0xFF9333EA));
      await tester.pump(const Duration(milliseconds: 250));
    });
  });
}

void _escala() {
  group('WIDGET · La escala de gusto (RF-TEST-6)', () {
    testWidgets('caso 8: la tarjeta trae el ícono, el rótulo, la tarea y el '
        'enunciado, y el ícono nunca toma color', (tester) async {
      final c = await _enLaPregunta(tester, indice: 2);
      expect(find.text('ESCALA DE GUSTO'), findsOneWidget);
      expect(find.text('Tarea de prueba tres en escala'), findsOneWidget);
      expect(find.text('¿Cuánto te gustaría hacer esto?'), findsOneWidget);
      Icon icono() => tester.widget<Icon>(
        find.descendant(
          of: find.byType(TaskIconTile),
          matching: find.byType(Icon),
        ),
      );
      expect(icono().icon, LucideIcons.smartphone);
      expect(icono().color, MaterialTheme.testTaskIconInk(Brightness.light));
      c.responder('bastante', avanceSolo: false);
      await tester.pump();
      expect(icono().color, MaterialTheme.testTaskIconInk(Brightness.light));
    });

    testWidgets('caso 9: las cuatro opciones van en fila, con su emoji y en '
        'su orden', (tester) async {
      await _enLaPregunta(tester, indice: 2);
      final y = <double>{
        for (final id in ['nada', 'un_poco', 'bastante', 'me_encantaria'])
          tester.getTopLeft(find.byKey(QuestionView.opcionKey(id))).dy,
      };
      expect(y, hasLength(1));
      final x = [
        for (final id in ['nada', 'un_poco', 'bastante', 'me_encantaria'])
          tester.getTopLeft(find.byKey(QuestionView.opcionKey(id))).dx,
      ];
      expect(x, [...x]..sort());
      for (final e in ['😴', '🙂', '😃', '🤩']) {
        expect(find.text(e), findsOneWidget);
      }
      expect(
        tester.getSize(find.byKey(QuestionView.opcionKey('nada'))).height,
        greaterThanOrEqualTo(64),
      );
    });

    for (final (escala, ancho) in [(1.3, 375.0), (1.0, 320.0)]) {
      testWidgets('caso 10: con texto a $escala y $ancho de ancho van en dos '
          'por dos', (tester) async {
        await _enLaPregunta(
          tester,
          indice: 2,
          escala: escala,
          tamano: Size(ancho, 667),
        );
        double arriba(String id) =>
            tester.getTopLeft(find.byKey(QuestionView.opcionKey(id))).dy;
        expect(arriba('nada'), arriba('un_poco'));
        expect(arriba('bastante'), greaterThan(arriba('nada')));
        expect(arriba('bastante'), arriba('me_encantaria'));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('caso 11: la opción elegida pasa a naranja y crece un 8 %', (
      tester,
    ) async {
      final c = await _enLaPregunta(tester, indice: 2);
      await tester.tap(find.text('Bastante'));
      await tester.pump(const Duration(milliseconds: 150));
      const b = Brightness.light;
      final opcion = find.byKey(QuestionView.opcionKey('bastante'));
      final material = tester.widget<Material>(
        find.descendant(of: opcion, matching: find.byType(Material)).first,
      );
      expect(material.color, MaterialTheme.testAccentSoft(b));
      expect(
        (material.shape! as RoundedRectangleBorder).side.color,
        MaterialTheme.testAccent(b),
      );
      expect(colorDeTexto(tester, 'Bastante'), MaterialTheme.testAccentDeep(b));
      expect(
        tester
            .widget<AnimatedScale>(
              find.descendant(of: opcion, matching: find.byType(AnimatedScale)),
            )
            .scale,
        1.08,
      );
      expect(c.respuestas['q03'], 'bastante');
      await tester.pump(const Duration(milliseconds: 250));
    });

    testWidgets('caso 11b: la opción elegida suena con '
        'HapticFeedback.selectionClick', (tester) async {
      await _enLaPregunta(tester, indice: 2);
      final vibraciones = escucharVibraciones(tester);
      await tester.tap(find.text('Un poco'));
      await tester.pump();
      expect(vibraciones, ['HapticFeedbackType.selectionClick']);
      await tester.pump(const Duration(milliseconds: 550));
    });

    testWidgets('caso 12: el sello del bloque cae con '
        'HapticFeedback.lightImpact, y un paso sin sello no vibra', (
      tester,
    ) async {
      // Escucha desde antes del montaje, porque el paso vibra en el primer
      // cuadro.
      final vibraciones = escucharVibraciones(tester);
      final c = await _enLaPregunta(tester, indice: 2);
      await tester.pump();
      // La pregunta 3 sigue a un duelo, así que llega sin sello.
      expect(find.textContaining('Cierra el bloque'), findsNothing);
      expect(vibraciones, isEmpty);
      await tester.tap(find.text('Bastante'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      expect(c.paso.value, 3);
      expect(find.text('Cierra el bloque 1 de 2'), findsOneWidget);
      expect(vibraciones, [
        'HapticFeedbackType.selectionClick',
        'HapticFeedbackType.lightImpact',
      ]);
      await tester.pump(const Duration(milliseconds: 200));
    });
  });
}
