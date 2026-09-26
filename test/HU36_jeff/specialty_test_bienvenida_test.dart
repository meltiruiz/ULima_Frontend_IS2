// test/HU36_jeff/specialty_test_bienvenida_test.dart
//
// Pruebas de HU36, el test de especialidad, sobre la bienvenida (RF-TEST-3),
// con la precarga del asistente (RF-TEST-1 y RF-TEST-2).
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
import 'package:ulima_plus/pages/specialty_test/widgets/ulises_bubble.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/welcome_view.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';
import 'montaje_de_pantallas.dart';

/// Un test en pausa con la copia de una versión anterior y dos respuestas.
PausedSpecialtyTest _pausado() => PausedSpecialtyTest(
  content: SpecialtyTestContent.tryParse(
    contenidoJson(version: '2026-09-24.1'),
  )!,
  answers: const {'q01': 'top', 'q02': 'none'},
  tiebreaks: const [],
);

void main() {
  // Get.put de un GetxService agenda onReady con
  // Get.engine.addPostFrameCallback, que necesita el binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(Get.reset);
  tearDown(Get.reset);

  _controlador();
  _pantalla();
}

void _controlador() {
  group('UNITARIA · Bienvenida en el controlador (RF-TEST-1 a RF-TEST-3)', () {
    test(
      'caso 1: desde el asistente usa la precarga y no pide otra vez',
      () async {
        final api = ApiFalsaDelTest();
        prepararTest(api).service.prefetchContent();
        await pumpEventQueue();
        final c = await montarControlador();
        expect(api.getsDeContenido, 1);
        expect(c.carga.value, EstadoDeCarga.lista);
        expect(c.fase.value, FaseDelTest.bienvenida);
        expect(c.contenido.value!.version, kVersionDePrueba);
      },
    );

    test(
      'caso 2: con la precarga en vuelo, la bienvenida espera cargando',
      () async {
        final pendiente = Completer<Map<String, dynamic>>();
        final api = ApiFalsaDelTest(contenido: [pendiente]);
        prepararTest(api).service.prefetchContent();
        final c = await montarControlador();
        expect(c.carga.value, EstadoDeCarga.cargando);
        pendiente.complete(contenidoJson());
        await pumpEventQueue();
        expect(c.carga.value, EstadoDeCarga.lista);
        expect(api.getsDeContenido, 1);
      },
    );

    test(
      'caso 3: si la precarga terminó en error, pide el contenido otra vez',
      () async {
        final api = ApiFalsaDelTest(
          contenido: [http.ClientException('sin red'), contenidoJson()],
        );
        prepararTest(api).service.prefetchContent();
        await pumpEventQueue();
        final c = await montarControlador();
        expect(api.getsDeContenido, 2);
        expect(c.carga.value, EstadoDeCarga.lista);
      },
    );

    test('caso 4: desde el Perfil y en cada apertura siguiente pide el '
        'contenido una vez', () async {
      final api = ApiFalsaDelTest();
      prepararTest(api);
      await montarControlador(origen: OrigenDelTest.perfil);
      expect(api.getsDeContenido, 1);
      Get.delete<SpecialtyTestController>();
      await montarControlador();
      expect(api.getsDeContenido, 2);
    });

    test(
      'caso 5: «Empezar el test» abre la pregunta 1 con la copia vigente',
      () async {
        prepararTest(ApiFalsaDelTest());
        final c = await montarControlador();
        expect(c.hayAvance, isFalse);
        c.empezar();
        expect(c.fase.value, FaseDelTest.pregunta);
        expect(c.paso.value, 0);
        expect(c.preguntaActual!.id, 'q01');
      },
    );

    test('caso 6: mientras carga, el botón principal no hace nada', () async {
      final api = ApiFalsaDelTest(
        contenido: [Completer<Map<String, dynamic>>()],
      );
      prepararTest(api);
      final c = await montarControlador();
      c.empezar();
      expect(c.fase.value, FaseDelTest.bienvenida);
    });

    test('caso 7: un test en pausa sigue en su primer paso sin responder y '
        'con su propia copia', () async {
      final t = prepararTest(
        ApiFalsaDelTest(contenido: [contenidoJson(version: '2026-09-25.5')]),
      );
      t.service.pause(_pausado());
      final c = await montarControlador();
      expect(c.hayAvance, isTrue);
      c.empezar();
      expect(c.fase.value, FaseDelTest.pregunta);
      expect(c.paso.value, 2);
      expect(c.contenido.value!.version, '2026-09-24.1');
    });

    test('caso 8: «Empezar de nuevo» borra las respuestas y abre la pregunta '
        '1 con la copia vigente', () async {
      final t = prepararTest(
        ApiFalsaDelTest(contenido: [contenidoJson(version: '2026-09-25.5')]),
      );
      t.service.pause(_pausado());
      final c = await montarControlador();
      c.empezarDeNuevo();
      expect(c.respuestas, isEmpty);
      expect(t.service.paused, isNull);
      expect(c.paso.value, 0);
      expect(c.fase.value, FaseDelTest.pregunta);
      expect(c.contenido.value!.version, '2026-09-25.5');
    });

    test('caso 9: «Saltar y elegir por mi cuenta» borra las respuestas y '
        'pasa a la selección manual', () async {
      final t = prepararTest(ApiFalsaDelTest());
      t.service.pause(_pausado());
      final ui = UiFalsa();
      final c = await montarControlador(ui: ui);
      c.saltar();
      expect(ui.cierres, [SalidaDelTest.seleccionManual]);
      expect(t.service.paused, isNull);
      Get.delete<SpecialtyTestController>();
      expect(t.service.paused, isNull);
    });

    test(
      'caso 10: «Ahora no» cierra la ruta y deja el avance en pausa',
      () async {
        final t = prepararTest(ApiFalsaDelTest());
        final ui = UiFalsa();
        final c = await montarControlador(origen: OrigenDelTest.perfil, ui: ui);
        c.empezar();
        c.responder('top', avanceSolo: false);
        c.atras();
        expect(c.fase.value, FaseDelTest.bienvenida);
        c.ahoraNo();
        expect(ui.cierres, [null]);
        Get.delete<SpecialtyTestController>();
        expect(t.service.paused!.answers, {'q01': 'top'});
        expect(t.service.paused!.content.version, kVersionDePrueba);
      },
    );

    test('caso 11: sin avance, cerrar no deja nada en pausa', () async {
      final t = prepararTest(ApiFalsaDelTest());
      await montarControlador();
      Get.delete<SpecialtyTestController>();
      expect(t.service.paused, isNull);
    });
  });
}

void _pantalla() {
  group('WIDGET · La bienvenida (RF-TEST-3)', () {
    testWidgets('caso 12: las líneas de bienvenida van en orden, sin el '
        'nombre del alumno, y solo la primera sin avatar', (tester) async {
      prepararTest(ApiFalsaDelTest());
      ponerControlador();
      await montarPantalla(tester, const WelcomeView());
      expect(find.text('Test de especialidad'), findsOneWidget);
      expect(find.text('Ulises'), findsOneWidget);
      final burbujas = tester
          .widgetList<UlisesBubble>(find.byType(UlisesBubble))
          .toList();
      expect(burbujas.map((b) => b.text), kBienvenida);
      expect(burbujas.map((b) => b.showAvatar), [false, true, true, true]);
      expect(find.textContaining('Alumna'), findsNothing);
      expect(find.text('Vamos'), findsNothing);
    });

    testWidgets('caso 13: en el asistente van las dos pastillas, «Empezar el '
        'test» y «Saltar y elegir por mi cuenta»', (tester) async {
      prepararTest(ApiFalsaDelTest());
      final ui = UiFalsa();
      ponerControlador(ui: ui);
      await montarPantalla(tester, const WelcomeView());
      expect(find.text('3 a 4 min'), findsOneWidget);
      expect(find.text('Rehazlo en Perfil'), findsOneWidget);
      expect(find.text('Empezar el test'), findsOneWidget);
      expect(find.text('Ahora no'), findsNothing);
      await tester.tap(find.text('Saltar y elegir por mi cuenta'));
      expect(ui.cierres, [SalidaDelTest.seleccionManual]);
    });

    testWidgets('caso 14: en el Perfil no va «Rehazlo en Perfil» y el '
        'secundario es «Ahora no»', (tester) async {
      prepararTest(ApiFalsaDelTest());
      final ui = UiFalsa();
      ponerControlador(origen: OrigenDelTest.perfil, ui: ui);
      await montarPantalla(tester, const WelcomeView());
      expect(find.text('Rehazlo en Perfil'), findsNothing);
      expect(find.text('Saltar y elegir por mi cuenta'), findsNothing);
      await tester.tap(find.text('Ahora no'));
      expect(ui.cierres, [null]);
    });

    testWidgets('caso 15: con un test en pausa, «Seguir el test» y «Empezar '
        'de nuevo»', (tester) async {
      final t = prepararTest(ApiFalsaDelTest());
      t.service.pause(_pausado());
      final c = ponerControlador();
      await montarPantalla(tester, const WelcomeView());
      expect(find.text('Seguir el test'), findsOneWidget);
      expect(find.text('Empezar el test'), findsNothing);
      await tester.tap(find.text('Seguir el test'));
      expect(c.fase.value, FaseDelTest.pregunta);
      expect(c.paso.value, 2);
    });

    testWidgets('caso 16: mientras carga hay esqueleto, el principal está '
        'desactivado y el secundario responde', (tester) async {
      prepararTest(
        ApiFalsaDelTest(contenido: [Completer<Map<String, dynamic>>()]),
      );
      final ui = UiFalsa();
      final c = ponerControlador(ui: ui);
      await montarPantalla(tester, const WelcomeView());
      expect(find.byKey(WelcomeView.skeletonKey), findsOneWidget);
      expect(find.byType(UlisesBubble), findsNothing);
      // El héroe se ve completo.
      expect(find.byType(UlisesAvatar), findsOneWidget);
      await tester.tap(find.text('Empezar el test'));
      expect(c.fase.value, FaseDelTest.bienvenida);
      await tester.tap(find.text('Saltar y elegir por mi cuenta'));
      expect(ui.cierres, [SalidaDelTest.seleccionManual]);
      // El plazo de 15 s del contenido sigue vivo y se vence antes de salir.
      await tester.pump(const Duration(seconds: 15));
    });

    testWidgets('caso 17: con error, el mensaje y «Reintentar», que vuelve a '
        'pedir', (tester) async {
      final api = ApiFalsaDelTest(
        contenido: [http.ClientException('sin red'), contenidoJson()],
      );
      prepararTest(api);
      final c = ponerControlador();
      await montarPantalla(tester, const WelcomeView());
      expect(find.text('No pudimos cargar el test.'), findsOneWidget);
      await tester.tap(find.text('Empezar el test'));
      expect(c.fase.value, FaseDelTest.bienvenida);
      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      expect(api.getsDeContenido, 2);
      expect(find.byType(UlisesBubble), findsNWidgets(4));
    });

    testWidgets('caso 18: con las cuatro líneas de 2026-09-25.4 a 375 × 667 '
        'nada desborda y los botones siguen a la vista', (tester) async {
      prepararTest(ApiFalsaDelTest());
      ponerControlador();
      await montarPantalla(tester, const WelcomeView());
      expect(tester.takeException(), isNull);
      expect(dentroDeLaPantalla(tester, find.text('Empezar el test')), isTrue);
      expect(
        dentroDeLaPantalla(tester, find.text('Saltar y elegir por mi cuenta')),
        isTrue,
      );
      // El cuerpo desplaza y los botones quedan fijos abajo.
      final antes = tester.getRect(find.text('Empezar el test'));
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.pump();
      expect(tester.getRect(find.text('Empezar el test')), antes);
    });

    testWidgets('caso 19: en oscuro el héroe sigue naranja y el cuerpo toma '
        'los tokens', (tester) async {
      prepararTest(ApiFalsaDelTest());
      ponerControlador();
      await montarPantalla(
        tester,
        const WelcomeView(),
        brillo: Brightness.dark,
      );
      expect(
        colorDeTexto(tester, 'Test de especialidad'),
        const Color(0xFF1A0E05),
      );
      expect(
        colorDeTexto(tester, kBienvenida.first),
        MaterialTheme.textPrimary(Brightness.dark),
      );
      expect(
        colorDeTexto(tester, 'Ulises'),
        MaterialTheme.testMuted(Brightness.dark),
      );
    });
  });
}
