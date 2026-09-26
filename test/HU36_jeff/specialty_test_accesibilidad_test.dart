// test/HU36_jeff/specialty_test_accesibilidad_test.dart
//
// Pruebas de widget de HU36, el test de especialidad, sobre la accesibilidad
// (RF-TEST-13), con lector de pantalla, texto grande y menos movimiento.
// Pantallas: lib/pages/specialty_test/widgets/
//
// Datos inventados (datos_de_prueba.dart). El alumno de prueba es 20230001.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/question_view.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/result_view.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/test_buttons.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/ulises_bubble.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/waiting_view.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/welcome_view.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';
import 'montaje_de_pantallas.dart';

/// Toda imagen de [pantalla] queda fuera del árbol de accesibilidad.
void _imagenesFueraDelArbol(WidgetTester tester) {
  final imagenes = find.byType(Image);
  final excluidas = find.descendant(
    of: find.byType(ExcludeSemantics),
    matching: find.byType(Image),
  );
  expect(imagenes.evaluate().length, excluidas.evaluate().length);
}

/// Todo botón del test mide al menos 48 de alto.
void _blancosTactiles(WidgetTester tester) {
  for (final tipo in [TestSecondaryButton, TestPrimaryButton]) {
    for (final e in find.byType(tipo).evaluate()) {
      expect(e.size!.height, greaterThanOrEqualTo(48));
    }
  }
}

void main() {
  // Get.put de un GetxService agenda onReady con
  // Get.engine.addPostFrameCallback, que necesita el binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(cargarRoboto);
  setUp(Get.reset);
  tearDown(Get.reset);

  _bienvenida();
  _preguntas();
  _espera();
  _resultado();
}

void _bienvenida() {
  group('WIDGET · Accesibilidad de la bienvenida (RF-TEST-13)', () {
    for (final escala in [1.0, 1.3, 2.0]) {
      testWidgets('con texto a $escala no desborda y los blancos miden 48', (
        tester,
      ) async {
        prepararTest(ApiFalsaDelTest());
        ponerControlador();
        await montarPantalla(tester, const WelcomeView(), escala: escala);
        expect(tester.takeException(), isNull);
        _blancosTactiles(tester);
        expect(
          dentroDeLaPantalla(tester, find.text('Empezar el test')),
          isTrue,
        );
      });
    }

    testWidgets('desde 1,3 el héroe baja a 200 px', (tester) async {
      prepararTest(ApiFalsaDelTest());
      ponerControlador();
      await montarPantalla(tester, const WelcomeView(), escala: 1.3);
      expect(tester.getSize(find.byKey(WelcomeView.heroKey)).height, 200);
    });

    testWidgets('las imágenes de Ulises y los orbes quedan fuera del árbol', (
      tester,
    ) async {
      prepararTest(ApiFalsaDelTest());
      ponerControlador();
      await montarPantalla(tester, const WelcomeView());
      _imagenesFueraDelArbol(tester);
      expect(find.bySemanticsLabel('Empezar el test'), findsOneWidget);
    });

    testWidgets('con menos movimiento no hay vaivén: la pantalla se asienta', (
      tester,
    ) async {
      prepararTest(ApiFalsaDelTest());
      ponerControlador();
      await montarPantalla(tester, const WelcomeView(), sinMovimiento: true);
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}

/// Monta la conversación en la pregunta de índice [indice].
Future<SpecialtyTestController> _enLaPregunta(
  WidgetTester tester, {
  int indice = 0,
  double escala = 1.0,
  bool lector = false,
  bool sinMovimiento = false,
}) async {
  prepararTest(ApiFalsaDelTest());
  final c = ponerControlador();
  await tester.pump();
  c.empezar();
  responderPasos(c, respuestasEnOrden.take(indice).toList());
  await montarPantalla(
    tester,
    const QuestionView(),
    escala: escala,
    lector: lector,
    sinMovimiento: sinMovimiento,
  );
  await tester.pump();
  return c;
}

/// El nodo `Focus` que envuelve a [texto] tiene el foco.
bool _conFoco(WidgetTester tester, String texto) =>
    Focus.of(tester.element(find.text(texto))).hasPrimaryFocus;

void _preguntas() {
  group('WIDGET · Accesibilidad de las preguntas (RF-TEST-13)', () {
    testWidgets('cada tarjeta es un botón con su tarea, la ayuda y selected', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await _enLaPregunta(tester, lector: true);
      final top = find.byKey(QuestionView.tarjetaKey('top'));
      expect(
        tester.getSemantics(top),
        isSemantics(
          label: 'Tarea de prueba uno arriba',
          hint: kDuelHelp,
          isButton: true,
          hasTapAction: true,
          isSelected: false,
        ),
      );
      await tester.tap(top);
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.getSemantics(top), isSemantics(isSelected: true));
      expect(
        tester.getSemantics(find.text('Me gustan las dos')),
        isSemantics(label: 'Me gustan las dos', isButton: true),
      );
      semantica.dispose();
    });

    testWidgets('la escala es un grupo con el enunciado y cada opción, un '
        'botón exclusivo con checked', (tester) async {
      final semantica = tester.ensureSemantics();
      await _enLaPregunta(tester, indice: 2, lector: true);
      final opcion = find.byKey(QuestionView.opcionKey('bastante'));
      expect(
        tester.getSemantics(opcion),
        isSemantics(
          label: 'Bastante',
          isButton: true,
          isInMutuallyExclusiveGroup: true,
          isChecked: false,
        ),
      );
      await tester.tap(opcion);
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.getSemantics(opcion), isSemantics(isChecked: true));
      semantica.dispose();
    });

    testWidgets('la burbuja es una región viva y el enunciado, un encabezado', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await _enLaPregunta(tester);
      expect(
        tester.getSemantics(find.byType(UlisesTurnView)),
        isSemantics(isLiveRegion: true),
      );
      expect(
        tester.getSemantics(find.text('¿Cuál harías con más ganas?')),
        isSemantics(isHeader: true),
      );
      semantica.dispose();
    });

    testWidgets('el foco pasa al enunciado nuevo al avanzar y al volver', (
      tester,
    ) async {
      final c = await _enLaPregunta(tester, lector: true);
      expect(_conFoco(tester, '¿Cuál harías con más ganas?'), isTrue);
      await tester.tap(find.byKey(QuestionView.tarjetaKey('top')));
      await tester.pump();
      await tester.tap(find.text('Siguiente'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
      expect(c.paso.value, 1);
      expect(_conFoco(tester, '¿Y entre estas dos?'), isTrue);
      await tester.tap(find.byTooltip('Pregunta anterior'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
      expect(_conFoco(tester, '¿Cuál harías con más ganas?'), isTrue);
    });

    testWidgets('con lector no hay avance solo y aparece «Siguiente»', (
      tester,
    ) async {
      final c = await _enLaPregunta(tester, lector: true);
      expect(find.text('Siguiente'), findsNothing);
      await tester.tap(find.byKey(QuestionView.tarjetaKey('bottom')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(c.paso.value, 0);
      expect(find.text('Siguiente'), findsOneWidget);
      await tester.tap(find.text('Siguiente'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(c.paso.value, 1);
    });

    testWidgets('con lector, «Siguiente» de la pregunta que sale no avanza '
        'la que entra', (tester) async {
      final c = await _enLaPregunta(tester, indice: 1, lector: true);
      await tester.tap(find.byKey(QuestionView.tarjetaKey('top')));
      await tester.pump();
      await tester.tap(find.byTooltip('Pregunta anterior'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
      expect(c.paso.value, 0);
      // La pregunta 1 vuelve con su respuesta y su «Siguiente», y la 2 sale
      // con el suyo.
      final queSale = find.ancestor(
        of: find.text('Tarea de prueba dos arriba'),
        matching: find.byType(SingleChildScrollView),
      );
      await tester.tap(
        find.descendant(of: queSale, matching: find.text('Siguiente')),
        warnIfMissed: false,
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(c.paso.value, 0);
    });

    testWidgets('la pastilla del historial dice ver u ocultar y su estado', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await _enLaPregunta(tester, indice: 2);
      final pastilla = find.text('2 respuestas anteriores');
      expect(
        tester.getSemantics(pastilla),
        isSemantics(
          label: 'Ver tus 2 respuestas anteriores',
          isButton: true,
          isExpanded: false,
        ),
      );
      await tester.tap(pastilla);
      await tester.pump();
      expect(
        tester.getSemantics(pastilla),
        isSemantics(
          label: 'Ocultar tus respuestas anteriores',
          isExpanded: true,
        ),
      );
      semantica.dispose();
    });

    testWidgets('las imágenes quedan fuera del árbol y los blancos miden 48', (
      tester,
    ) async {
      await _enLaPregunta(tester);
      _imagenesFueraDelArbol(tester);
      for (final t in ['Pregunta anterior', 'Pausar el test y seguir luego']) {
        final r = tester.getSize(find.byTooltip(t));
        expect(r.width, greaterThanOrEqualTo(48));
        expect(r.height, greaterThanOrEqualTo(48));
      }
      expect(
        tester
            .getSize(
              find.ancestor(
                of: find.text('Me gustan las dos'),
                matching: find.byType(InkWell),
              ),
            )
            .height,
        greaterThanOrEqualTo(48),
      );
    });

    for (final escala in [1.0, 1.3, 2.0]) {
      testWidgets('con texto a $escala ni el duelo ni la escala desbordan', (
        tester,
      ) async {
        await _enLaPregunta(tester, escala: escala);
        expect(tester.takeException(), isNull);
        Get.reset();
        await _enLaPregunta(tester, indice: 2, escala: escala);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('desde 1,3 «Me gustan las dos» y «Ninguna me llama» van una '
        'debajo de otra', (tester) async {
      await _enLaPregunta(tester, escala: 1.3);
      expect(
        tester.getTopLeft(find.text('Ninguna me llama')).dy,
        greaterThan(tester.getBottomLeft(find.text('Me gustan las dos')).dy),
      );
    });

    testWidgets('con menos movimiento no brilla la pluma ni crece la opción', (
      tester,
    ) async {
      await _enLaPregunta(tester, indice: 2, sinMovimiento: true);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(QuestionView.opcionKey('nada')));
      await tester.pump();
      expect(
        tester
            .widget<AnimatedScale>(
              find.descendant(
                of: find.byKey(QuestionView.opcionKey('nada')),
                matching: find.byType(AnimatedScale),
              ),
            )
            .scale,
        1,
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
    });
  });
}

void _espera() {
  group('WIDGET · Accesibilidad de la espera (RF-TEST-13)', () {
    for (final escala in [1.0, 1.3, 2.0]) {
      testWidgets('con texto a $escala no desborda, y el foco y la región viva '
          'quedan en la burbuja', (tester) async {
        final semantica = tester.ensureSemantics();
        final pendiente = Completer<Map<String, dynamic>>();
        prepararTest(ApiFalsaDelTest(evaluaciones: [pendiente]));
        final c = ponerControlador();
        await tester.pump();
        c.empezar();
        responderPasos(c, respuestasEnOrden);
        await montarPantalla(tester, const WaitingView(), escala: escala);
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(
          Focus.of(tester.element(find.text(kLoading))).hasPrimaryFocus,
          isTrue,
        );
        expect(
          tester.getSemantics(find.byType(UlisesTurnView)),
          isSemantics(isLiveRegion: true),
        );
        pendiente.complete(resultadoJson());
        await tester.pump();
        semantica.dispose();
      });
    }
  });
}

/// Los nodos hijos de [nodo] en el árbol de accesibilidad.
List<SemanticsNode> _hijos(SemanticsNode nodo) {
  final hijos = <SemanticsNode>[];
  nodo.visitChildren((hijo) {
    hijos.add(hijo);
    return true;
  });
  return hijos;
}

/// Llega al resultado de [evaluacion] y monta la pantalla.
Future<SpecialtyTestController> _enElResultado(
  WidgetTester tester, {
  Map<String, dynamic>? evaluacion,
  double escala = 1.0,
  bool sinMovimiento = true,
}) async {
  prepararTest(ApiFalsaDelTest(evaluaciones: [evaluacion ?? resultadoJson()]));
  final c = ponerControlador();
  await tester.pump();
  c.empezar();
  responderPasos(c, respuestasEnOrden);
  await tester.pump();
  await montarPantalla(
    tester,
    const ResultView(),
    escala: escala,
    sinMovimiento: sinMovimiento,
  );
  await tester.pump();
  return c;
}

void _resultado() {
  group('WIDGET · Accesibilidad del resultado (RF-TEST-13)', () {
    testWidgets('la tarjeta es un nodo con la número uno, su afinidad y el '
        'motivo con la insignia «IA», y «Leer más» es su botón hijo', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await _enElResultado(
        tester,
        evaluacion: resultadoJson(reasonSource: 'ai'),
      );
      final tarjeta = tester.getSemantics(find.byKey(ResultView.tarjetaKey));
      expect(
        tarjeta.label,
        'Tu n.º 1, Desarrollo de Videojuegos, 75 % de afinidad. Motivo '
        'redactado con IA. $kMotivoLargo',
      );
      // Ni el resumen ni el motivo quedan como nodos sueltos.
      expect(
        find.bySemanticsLabel(
          'Tu n.º 1, Desarrollo de Videojuegos, 75 % de afinidad',
        ),
        findsNothing,
      );
      expect(
        find.bySemanticsLabel('Motivo redactado con IA. $kMotivoLargo'),
        findsNothing,
      );
      final hijos = _hijos(tarjeta);
      expect(hijos, hasLength(1));
      expect(
        hijos.single,
        isSemantics(label: 'Leer más', isButton: true, hasTapAction: true),
      );
      expect(tester.getSemantics(find.text('Leer más')), same(hijos.single));
      semantica.dispose();
    });

    testWidgets('con empate la tarjeta nombra las dos, y un motivo que cabe '
        'va sin botón', (tester) async {
      final semantica = tester.ensureSemantics();
      const corto = 'Motivo corto de prueba que cabe entero.';
      await _enElResultado(
        tester,
        evaluacion: resultadoJson(empate: true, motivo: corto),
      );
      final tarjeta = tester.getSemantics(find.byKey(ResultView.tarjetaKey));
      expect(
        tarjeta.label,
        'Empate, Sistemas de Información y Desarrollo de Videojuegos, 62 % '
        'de afinidad. $corto',
      );
      expect(_hijos(tarjeta), isEmpty);
      semantica.dispose();
    });

    testWidgets('cada fila se lee con su puesto y el corazón es un botón con '
        'toggled', (tester) async {
      final semantica = tester.ensureSemantics();
      await _enElResultado(tester);
      expect(
        find.bySemanticsLabel(
          'Puesto 2, Sistemas de Información, 65 % de afinidad',
        ),
        findsOneWidget,
      );
      final corazon = find.byKey(ResultView.corazonKey(kIdSi));
      expect(
        tester.getSemantics(corazon),
        isSemantics(
          label: 'Marcar Sistemas de Información como interés',
          isButton: true,
          isToggled: false,
        ),
      );
      await tester.tap(corazon);
      await tester.pump();
      expect(
        tester.getSemantics(corazon),
        isSemantics(
          label: 'Quitar Sistemas de Información de tus intereses',
          isToggled: true,
        ),
      );
      semantica.dispose();
    });

    testWidgets('al abrir el resultado el foco pasa a la burbuja de Ulises', (
      tester,
    ) async {
      await _enElResultado(tester);
      expect(
        Focus.of(
          tester.element(
            find.text(
              'Lo tuyo apunta a Desarrollo de Videojuegos, con 75 % de '
              'afinidad.',
            ),
          ),
        ).hasPrimaryFocus,
        isTrue,
      );
    });

    testWidgets('con menos movimiento no hay confeti ni giro y la afinidad '
        'sale con su valor final', (tester) async {
      await _enElResultado(tester);
      expect(find.byKey(ResultView.confetiKey), findsNothing);
      expect(find.text('75 % afinidad'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    for (final escala in [1.0, 1.3, 2.0]) {
      testWidgets('con texto a $escala no desborda y los botones siguen '
          'abajo', (tester) async {
        await _enElResultado(tester, escala: escala);
        expect(tester.takeException(), isNull);
        expect(
          dentroDeLaPantalla(tester, find.text('Rehacer el test')),
          isTrue,
        );
        _blancosTactiles(tester);
      });

      testWidgets('con texto a $escala la hoja del empate no desborda y '
          '«Cancelar» queda en la pantalla', (tester) async {
        await _enElResultado(
          tester,
          evaluacion: resultadoJson(empate: true),
          escala: escala,
        );
        await tester.tap(find.text('Elegir como principal'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('¿Cuál eliges como principal?'), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(dentroDeLaPantalla(tester, find.text('Cancelar')), isTrue);
        _blancosTactiles(tester);
      });
    }
  });
}
