// test/HU36_jeff/specialty_test_resultado_test.dart
//
// Pruebas de widget de HU36, el test de especialidad, sobre el resultado
// (RF-TEST-8).
// Pantalla: lib/pages/specialty_test/widgets/result_view.dart
//
// Datos inventados (datos_de_prueba.dart). El alumno de prueba es 20230001.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_logic.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/result_view.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/ulises_bubble.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';
import 'montaje_de_pantallas.dart';

const Color _vjClaro = Color(0xFF76164A);
const Color _vjOscuro = Color(0xFFEC7FB3);

/// Llega al resultado de [evaluacion] y monta la pantalla. Deja pasar la
/// entrada (600 ms) y el confeti (1200 ms).
Future<SpecialtyTestController> _enElResultado(
  WidgetTester tester, {
  Map<String, dynamic>? evaluacion,
  UserModel? usuario,
  Brightness brillo = Brightness.light,
  bool sinMovimiento = false,
  bool esperarEntrada = true,
}) async {
  prepararTest(
    ApiFalsaDelTest(evaluaciones: [evaluacion ?? resultadoJson()]),
    usuario: usuario,
  );
  final c = ponerControlador();
  await tester.pump();
  c.empezar();
  responderPasos(c, respuestasEnOrden);
  await tester.pump();
  expect(c.fase.value, FaseDelTest.resultado);
  await montarPantalla(
    tester,
    const ResultView(),
    brillo: brillo,
    sinMovimiento: sinMovimiento,
  );
  if (esperarEntrada) await tester.pump(const Duration(milliseconds: 1300));
  return c;
}

double _arriba(WidgetTester tester, Finder f) => tester.getTopLeft(f).dy;

/// Motivos inventados con los largos que importan. El de 104 caracteres
/// es tan largo como el de la maqueta, los de 184 y 191 son como los de IA
/// que caben enteros en Android, el de 213 es como el de las plantillas que
/// allí se corta, y los del contenido miden de 190 a 541. El tercer campo
/// dice si el motivo se corta seguro, o null si depende de la letra.
const List<(int, String, bool?)> _motivosDePrueba = [
  (
    104,
    'Te llamaron las tareas de probar ideas rápido y de pensar en quien '
        'juega, como se hace en sus electivos.',
    false,
  ),
  (
    157,
    'En los duelos de prueba sumó la mayor parte de los puntos, y las tareas '
        'que elegiste piden pensar en quien juega y probar ideas rápido cada '
        'semana del ciclo.',
    null,
  ),
  (
    184,
    'Elegiste una y otra vez las tareas de probar ideas rápido y ajustar '
        'reglas, y en la escala le diste un «Bastante» a la tarea de prueba, '
        'así que esta especialidad va primero en la fila.',
    null,
  ),
  (
    191,
    'Tus respuestas se inclinan por las tareas de diseñar reglas y probar '
        'prototipos con otras personas, y la escala de prueba confirmó ese '
        'interés con un «Me encantaría» claro y sin ninguna duda.',
    null,
  ),
  (
    213,
    'En los duelos de prueba, esta especialidad sumó 4 de 5 puntos, con '
        'tareas como ajustar las reglas de un nivel o probar una idea con '
        'jugadores, y en la escala le diste un «Bastante» a la tarea de prueba '
        'del bloque.',
    null,
  ),
  (
    541,
    'Desarrollo de Videojuegos sumó 5,5 de 7 puntos en los duelos de prueba, '
        'con tareas como ajustar las reglas de un nivel, probar una idea con '
        'jugadores y medir cuánto tardan en entender un menú. En la escala le '
        'diste un «Me encantaría» a la tarea de prueba del bloque dos, y eso '
        'la dejó adelante de Sistemas de Información, que quedó cerca porque '
        'también elegiste tareas de ordenar datos. Sus electivos de prueba '
        'trabajan eso durante el ciclo, con proyectos en equipo y entregas '
        'cortas que se prueban con personas antes de cerrar cada versión.',
    true,
  ),
];

/// El párrafo pintado del motivo [motivo], con la insignia o sin ella.
Finder _parrafoDelMotivo(String motivo) => find.byWidgetPredicate(
  (w) => w is RichText && w.text.toPlainText().endsWith(motivo),
);

void main() {
  // Get.put de un GetxService agenda onReady con
  // Get.engine.addPostFrameCallback, que necesita el binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(cargarRoboto);
  setUp(Get.reset);
  tearDown(Get.reset);

  _resultado();
  _ruta();
}

void _resultado() {
  group('WIDGET · El resultado (RF-TEST-8)', () {
    testWidgets('caso 1: las piezas van en orden, de Ulises a los botones', (
      tester,
    ) async {
      await _enElResultado(tester);
      final orden = [
        find.byType(UlisesBubble),
        find.byKey(ResultView.tarjetaKey),
        find.text('2 electivos'),
        find.text('También te puede interesar'),
        find.byKey(ResultView.filaKey(kIdSi)),
        find.byKey(ResultView.filaKey(kIdTi)),
        find.byKey(ResultView.filaKey(kIdSw)),
        find.text('Elegir como principal'),
        find.text('Decidir después'),
      ];
      final alturas = [for (final f in orden) _arriba(tester, f)];
      expect(alturas, [...alturas]..sort());
      expect(find.text('Rehacer el test'), findsOneWidget);
      expect(find.text('Tu n.º 1'), findsOneWidget);
      expect(find.text('75 % afinidad'), findsOneWidget);
      expect(find.text('Desarrollo de Videojuegos'), findsOneWidget);
      expect(find.text('65 %'), findsOneWidget);
    });

    testWidgets('caso 2: la burbuja lleva headline y tiebreakOutcome tal cual '
        'y nunca intro, closing ni retake', (tester) async {
      await _enElResultado(
        tester,
        evaluacion: resultadoJson(
          headline:
              'Esta vez ninguna despegó del todo. Por ahora, '
              'Desarrollo de Videojuegos va adelante, con 45 %.',
          tiebreakOutcome: 'Ahí está, ya se inclinó la balanza.',
        ),
      );
      expect(
        tester.widget<UlisesBubble>(find.byType(UlisesBubble)).text,
        'Esta vez ninguna despegó del todo. Por ahora, Desarrollo de '
        'Videojuegos va adelante, con 45 %. Ahí está, ya se inclinó la '
        'balanza.',
      );
      expect(find.textContaining('Ya tengo tu resultado'), findsNothing);
      expect(find.textContaining('que la app no pinta'), findsNothing);
    });

    testWidgets('caso 3: la insignia «IA» sale solo con reasonSource "ai"', (
      tester,
    ) async {
      await _enElResultado(tester);
      expect(find.text('IA'), findsNothing);
      Get.reset();
      await _enElResultado(
        tester,
        evaluacion: resultadoJson(reasonSource: 'ai'),
      );
      expect(find.text('IA'), findsOneWidget);
    });

    testWidgets('caso 4: el motivo se corta en cuatro líneas y «Leer más» lo '
        'despliega', (tester) async {
      await _enElResultado(tester);
      Text motivo() => tester.widget<Text>(
        find.byWidgetPredicate(
          (w) => w is Text && w.textSpan?.toPlainText() == kMotivoLargo,
        ),
      );
      expect(motivo().maxLines, 4);
      await tester.tap(find.text('Leer más'));
      await tester.pump();
      expect(motivo().maxLines, isNull);
      await tester.tap(find.text('Leer menos'));
      await tester.pump();
      expect(motivo().maxLines, 4);
    });

    for (final (largo, motivo, seCorta) in _motivosDePrueba) {
      testWidgets('caso 4b: con Roboto, un motivo de $largo caracteres lleva '
          '«Leer más» solo si su párrafo pasa de cuatro líneas', (
        tester,
      ) async {
        for (final fuente in ['templates', 'ai']) {
          Get.reset();
          await _enElResultado(
            tester,
            evaluacion: resultadoJson(motivo: motivo, reasonSource: fuente),
          );
          final parrafo = _parrafoDelMotivo(motivo);
          // La medida vale solo si el párrafo es el que se ve en Android.
          expect(
            tester.widget<RichText>(parrafo).text.style!.fontFamily,
            'Roboto',
          );
          final corta = tester
              .renderObject<RenderParagraph>(parrafo)
              .didExceedMaxLines;
          expect(
            find.text('Leer más').evaluate().isNotEmpty,
            corta,
            reason: 'con reasonSource "$fuente"',
          );
          if (seCorta != null) expect(corta, seCorta);
        }
      });
    }

    testWidgets('caso 5: con empate, «Empate», los dos nombres, una pastilla '
        'y las filas desde el puesto 3', (tester) async {
      await _enElResultado(tester, evaluacion: resultadoJson(empate: true));
      expect(find.text('Empate'), findsOneWidget);
      expect(find.text('Sistemas de Información'), findsOneWidget);
      expect(find.text('Desarrollo de Videojuegos'), findsOneWidget);
      expect(find.textContaining('% afinidad'), findsOneWidget);
      expect(find.text('Electivos de las dos'), findsOneWidget);
      expect(find.byKey(ResultView.filaKey(kIdSi)), findsNothing);
      expect(find.byKey(ResultView.filaKey(kIdTi)), findsOneWidget);
      expect(find.byKey(ResultView.corazonKey(kIdVj)), findsNothing);
    });

    for (final brillo in Brightness.values) {
      testWidgets('caso 6: a 375 × 667 con 1,0 todo cabe sin desplazar en '
          '${brillo.name}', (tester) async {
        await _enElResultado(tester, brillo: brillo);
        final cuerpo = tester.state<ScrollableState>(
          find.descendant(
            of: find.byKey(ResultView.cuerpoKey),
            matching: find.byType(Scrollable),
          ),
        );
        expect(cuerpo.position.maxScrollExtent, 0);
        expect(
          dentroDeLaPantalla(tester, find.text('Rehacer el test')),
          isTrue,
        );
      });
    }

    testWidgets('caso 7: la hoja de electivos trae el título, la frase y cada '
        'electivo', (tester) async {
      await _enElResultado(tester);
      await tester.tap(find.text('Ver'));
      await tester.pumpAndSettle();
      expect(
        find.text('Electivos de Desarrollo de Videojuegos'),
        findsOneWidget,
      );
      expect(
        find.text('Frase de prueba de Desarrollo de Videojuegos.'),
        findsOneWidget,
      );
      expect(find.text('Electivo G'), findsWidgets);
      expect(find.text('900401 · 3 créditos'), findsOneWidget);
      expect(find.text('Haber culminado el V ciclo'), findsNWidgets(2));
    });

    testWidgets('caso 8: la principal actual lleva la estrella con «Tu '
        'principal» y no tiene corazón', (tester) async {
      await _enElResultado(tester, usuario: alumno(principal: kIdSi));
      expect(find.text('Tu principal'), findsOneWidget);
      expect(find.byKey(ResultView.corazonKey(kIdSi)), findsNothing);
      expect(
        colorDeTexto(tester, 'Tu principal'),
        MaterialTheme.testAccentText(Brightness.light),
      );
    });

    testWidgets('caso 9: en claro la tarjeta es un degradado del color y en '
        'oscuro el color al 18 % con el título en color', (tester) async {
      await _enElResultado(tester);
      BoxDecoration deco() =>
          tester
                  .widget<Container>(find.byKey(ResultView.tarjetaKey))
                  .decoration!
              as BoxDecoration;
      expect((deco().gradient! as LinearGradient).colors, [
        _vjClaro,
        oscurecido(_vjClaro),
      ]);
      expect(colorDeTexto(tester, 'Tu n.º 1'), Colors.white);
      Get.reset();
      await _enElResultado(tester, brillo: Brightness.dark);
      const b = Brightness.dark;
      expect(deco().color, tinte(_vjOscuro, MaterialTheme.cardBg(b), 0.18));
      expect(colorDeTexto(tester, 'Desarrollo de Videojuegos'), _vjOscuro);
      expect(colorDeTexto(tester, 'Tu n.º 1'), MaterialTheme.textPrimary(b));
    });

    testWidgets('caso 10: al entrar hay confeti y una vibración fuerte, y la '
        'afinidad cuenta hasta su valor', (tester) async {
      final vibraciones = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (llamada) async {
          if (llamada.method == 'HapticFeedback.vibrate') {
            vibraciones.add(llamada.arguments);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await _enElResultado(tester, esperarEntrada: false);
      expect(find.byKey(ResultView.confetiKey), findsOneWidget);
      expect(vibraciones, contains('HapticFeedbackType.heavyImpact'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('75 % afinidad'), findsNothing);
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.text('75 % afinidad'), findsOneWidget);
    });
  });
}

void _ruta() {
  group('WIDGET · El atrás del sistema en el resultado (RF-TEST-8)', () {
    testWidgets('caso 11: en el asistente no hace nada', (tester) async {
      final t = prepararTest(ApiFalsaDelTest());
      await abrirLaRuta(tester);
      final c = Get.find<SpecialtyTestController>();
      c.empezar();
      responderPasos(c, respuestasEnOrden);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(ResultView), findsOneWidget);
      await tester.binding.handlePopRoute();
      await asentar(tester);
      expect(find.byType(ResultView), findsOneWidget);
      expect(find.text('Pantalla de inicio'), findsNothing);
      expect(Get.isRegistered<SpecialtyTestController>(), isTrue);
      expect(c.fase.value, FaseDelTest.resultado);
      expect(t.auth.guardados, isEmpty);
    });

    testWidgets('caso 12: en el Perfil es «Decidir después» y cierra la ruta '
        'sin guardar', (tester) async {
      final t = prepararTest(ApiFalsaDelTest());
      final salida = await abrirLaRuta(tester, origen: OrigenDelTest.perfil);
      final c = Get.find<SpecialtyTestController>();
      c.empezar();
      responderPasos(c, respuestasEnOrden);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.binding.handlePopRoute();
      await asentar(tester);
      expect(find.text('Pantalla de inicio'), findsOneWidget);
      expect(await salida, SalidaDelTest.terminado);
      expect(t.auth.guardados, isEmpty);
    });
  });
}
