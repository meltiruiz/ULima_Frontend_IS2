// test/HU36_jeff/specialty_test_eleccion_test.dart
//
// Pruebas de HU36, el test de especialidad, sobre «Elegir como principal»,
// los corazones, «Decidir después» y «Rehacer el test» (RF-TEST-9).
// Controlador: lib/pages/specialty_test/specialty_test_controller.dart
//
// Datos inventados (datos_de_prueba.dart). El alumno de prueba es 20230001.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_logic.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/result_view.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';
import 'montaje_de_pantallas.dart';

/// Llega al resultado con [usuario] y el resultado de [evaluacion].
Future<({SpecialtyTestController c, AuthDelControlador auth, UiFalsa ui})>
_alResultado({
  OrigenDelTest origen = OrigenDelTest.asistente,
  UserModel? usuario,
  Map<String, dynamic>? evaluacion,
}) async {
  final t = prepararTest(
    ApiFalsaDelTest(evaluaciones: [evaluacion ?? resultadoJson()]),
    usuario: usuario,
  );
  final ui = UiFalsa();
  final c = await montarControlador(origen: origen, ui: ui);
  c.empezar();
  responderPasos(c, respuestasEnOrden);
  await pumpEventQueue();
  expect(c.fase.value, FaseDelTest.resultado);
  return (c: c, auth: t.auth, ui: ui);
}

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
  group('UNITARIA · Elegir como principal (RF-TEST-9)', () {
    test('caso 1: en el asistente manda la ganadora y los corazones y va al '
        'home', () async {
      final r = await _alResultado(usuario: alumno(intereses: [kIdTi]));
      expect(r.c.corazones, {kIdTi});
      await r.c.elegirPrincipal(kIdVj);
      expect(
        r.auth.guardados.single,
        const SeleccionDeEspecialidades(principal: kIdVj, intereses: [kIdTi]),
      );
      expect(r.auth.plazos.single, SpecialtyTestService.saveTimeout);
      expect(r.ui.alHome, 1);
      expect(r.ui.cierres, isEmpty);
    });

    test('caso 2: en el Perfil cierra la ruta y avisa como siempre', () async {
      final r = await _alResultado(origen: OrigenDelTest.perfil);
      await r.c.elegirPrincipal(kIdVj);
      expect(r.ui.cierres, [SalidaDelTest.terminado]);
      expect(r.ui.alHome, 0);
      expect(r.ui.avisos.single.tipo, TipoDeAviso.exito);
      expect(r.ui.avisos.single.titulo, 'Especialidades actualizadas');
      expect(
        r.ui.avisos.single.mensaje,
        'Tu selección se guardó correctamente.',
      );
    });

    test('caso 3: una principal anterior del ranking pasa a interés', () async {
      final r = await _alResultado(usuario: alumno(principal: kIdSw));
      await r.c.elegirPrincipal(kIdVj);
      expect(
        r.auth.guardados.single,
        const SeleccionDeEspecialidades(principal: kIdVj, intereses: [kIdSw]),
      );
    });

    test(
      'caso 4: con empate, la ganadora que no se elige pasa a interés',
      () async {
        final r = await _alResultado(evaluacion: resultadoJson(empate: true));
        await r.c.elegirPrincipal(kIdVj);
        expect(
          r.auth.guardados.single,
          const SeleccionDeEspecialidades(principal: kIdVj, intereses: [kIdSi]),
        );
      },
    );

    test(
      'caso 5: si la ganadora ya es la principal, el botón lo dice',
      () async {
        final r = await _alResultado(usuario: alumno(principal: kIdVj));
        expect(r.c.yaEsPrincipal, isTrue);
        Get.reset();
        final otra = await _alResultado(usuario: alumno(principal: kIdSw));
        expect(otra.c.yaEsPrincipal, isFalse);
      },
    );
  });

  group('UNITARIA · Corazones (RF-TEST-9)', () {
    test(
      'caso 6: un corazón guarda enseguida con la principal sin cambios',
      () async {
        final r = await _alResultado(usuario: alumno(principal: kIdSw));
        r.c.alternarCorazon(kIdSi);
        expect(r.c.corazones, {kIdSi});
        await pumpEventQueue();
        expect(
          r.auth.guardados.single,
          const SeleccionDeEspecialidades(principal: kIdSw, intereses: [kIdSi]),
        );
        r.c.alternarCorazon(kIdSi);
        await pumpEventQueue();
        expect(
          r.auth.guardados.last,
          const SeleccionDeEspecialidades(principal: kIdSw),
        );
      },
    );

    test(
      'caso 7: los toques seguidos se juntan y se manda el último estado',
      () async {
        final r = await _alResultado();
        final primero = Completer<void>();
        r.auth.respuestasDeGuardado.add(primero);
        r.c.alternarCorazon(kIdSi);
        r.c.alternarCorazon(kIdTi);
        r.c.alternarCorazon(kIdSw);
        r.c.alternarCorazon(kIdSw);
        expect(r.auth.guardados, hasLength(1));
        primero.complete();
        await pumpEventQueue();
        expect(r.auth.guardados, hasLength(2));
        expect(
          r.auth.guardados.last,
          const SeleccionDeEspecialidades(intereses: [kIdSi, kIdTi]),
        );
        expect(r.c.guardandoCorazones.value, isFalse);
      },
    );

    test('caso 8: si el guardado de los toques juntados falla, se descartan '
        'con él', () async {
      final r = await _alResultado();
      final primero = Completer<void>();
      r.auth.respuestasDeGuardado
        ..add(primero)
        ..add(TimeoutException('plazo'));
      r.c.alternarCorazon(kIdSi);
      r.c.alternarCorazon(kIdTi);
      primero.complete();
      await pumpEventQueue();
      expect(r.c.corazones, {kIdSi});
      expect(r.ui.avisos.single.tipo, TipoDeAviso.error);
    });

    test('caso 9: en el asistente, el primer corazón completa la '
        'configuración', () async {
      final r = await _alResultado(usuario: alumno(setupComplete: false));
      r.c.alternarCorazon(kIdTi);
      await pumpEventQueue();
      expect(r.auth.currentUser!.setupComplete, isTrue);
    });

    test('caso 10: nunca hay dos guardados en vuelo entre corazones y '
        'botones', () async {
      final r = await _alResultado();
      final corazon = Completer<void>();
      r.auth.respuestasDeGuardado.add(corazon);
      r.c.alternarCorazon(kIdSi);
      expect(r.c.botonesActivos, isFalse);
      await r.c.elegirPrincipal(kIdVj);
      await r.c.decidirDespues();
      r.c.rehacer();
      expect(r.auth.guardados, hasLength(1));
      expect(r.c.fase.value, FaseDelTest.resultado);
      corazon.complete();
      await pumpEventQueue();
      final boton = Completer<void>();
      r.auth.respuestasDeGuardado.add(boton);
      unawaited(r.c.elegirPrincipal(kIdVj));
      r.c.alternarCorazon(kIdTi);
      expect(r.c.corazones, {kIdSi});
      expect(r.auth.guardados, hasLength(2));
      boton.complete();
      await pumpEventQueue();
    });
  });

  group('UNITARIA · Decidir después, Rehacer y atrás (RF-TEST-9)', () {
    test('caso 11: «Decidir después» en el asistente guarda la selección y va '
        'al home', () async {
      final r = await _alResultado(
        usuario: alumno(principal: kIdSw, intereses: [kIdTi]),
      );
      await r.c.decidirDespues();
      expect(
        r.auth.guardados.single,
        const SeleccionDeEspecialidades(principal: kIdSw, intereses: [kIdTi]),
      );
      expect(r.ui.alHome, 1);
    });

    test(
      'caso 12: «Decidir después» en el Perfil cierra sin guardar',
      () async {
        final r = await _alResultado(origen: OrigenDelTest.perfil);
        await r.c.decidirDespues();
        expect(r.auth.guardados, isEmpty);
        expect(r.ui.cierres, [SalidaDelTest.terminado]);
      },
    );

    test('caso 13: «Rehacer el test» vuelve a la pregunta 1 con la misma '
        'copia y sin respuestas', () async {
      final r = await _alResultado();
      final copia = r.c.contenido.value;
      r.c.rehacer();
      expect(r.c.fase.value, FaseDelTest.pregunta);
      expect(r.c.paso.value, 0);
      expect(r.c.respuestas, isEmpty);
      expect(r.c.resultado.value, isNull);
      expect(r.c.contenido.value, same(copia));
    });

    test('caso 14: el atrás del sistema no hace nada en el asistente y es '
        '«Decidir después» en el Perfil', () async {
      final asistente = await _alResultado();
      asistente.c.atrasEnResultado();
      await pumpEventQueue();
      expect(asistente.ui.cierres, isEmpty);
      expect(asistente.ui.alHome, 0);
      expect(asistente.auth.guardados, isEmpty);
      Get.reset();
      final perfil = await _alResultado(origen: OrigenDelTest.perfil);
      perfil.c.atrasEnResultado();
      await pumpEventQueue();
      expect(perfil.ui.cierres, [SalidaDelTest.terminado]);
    });
  });
}

/// Monta el resultado con [usuario] y sin animaciones de entrada.
Future<({SpecialtyTestController c, AuthDelControlador auth})>
_pantallaDelResultado(
  WidgetTester tester, {
  UserModel? usuario,
  Map<String, dynamic>? evaluacion,
}) async {
  final t = prepararTest(
    ApiFalsaDelTest(evaluaciones: [evaluacion ?? resultadoJson()]),
    usuario: usuario,
  );
  final c = ponerControlador();
  await tester.pump();
  c.empezar();
  responderPasos(c, respuestasEnOrden);
  await tester.pump();
  await montarPantalla(tester, const ResultView(), sinMovimiento: true);
  return (c: c, auth: t.auth);
}

void _pantalla() {
  group('WIDGET · Elegir y corazones en el resultado (RF-TEST-9)', () {
    testWidgets('caso 15: los corazones marcados son los intereses y el '
        'toque guarda', (tester) async {
      final r = await _pantallaDelResultado(
        tester,
        usuario: alumno(intereses: [kIdTi]),
      );
      Icon corazon(int id) => tester.widget<Icon>(
        find.descendant(
          of: find.byKey(ResultView.corazonKey(id)),
          matching: find.byType(Icon),
        ),
      );
      expect(corazon(kIdTi).icon, Icons.favorite_rounded);
      expect(corazon(kIdSi).icon, isNot(Icons.favorite_rounded));
      await tester.tap(find.byKey(ResultView.corazonKey(kIdSi)));
      await tester.pump();
      expect(corazon(kIdSi).icon, Icons.favorite_rounded);
      expect(
        r.auth.guardados.single,
        const SeleccionDeEspecialidades(intereses: [kIdSi, kIdTi]),
      );
    });

    testWidgets('caso 16: si la ganadora ya es la principal, el botón dice '
        '«Ya es tu principal» y no guarda', (tester) async {
      final r = await _pantallaDelResultado(
        tester,
        usuario: alumno(principal: kIdVj),
      );
      expect(find.text('Elegir como principal'), findsNothing);
      await tester.tap(find.text('Ya es tu principal'));
      await tester.pump();
      expect(r.auth.guardados, isEmpty);
    });

    testWidgets('caso 17: con empate, la hoja pregunta cuál y «Cancelar» no '
        'guarda', (tester) async {
      final r = await _pantallaDelResultado(
        tester,
        evaluacion: resultadoJson(empate: true),
      );
      await tester.tap(find.text('Elegir como principal'));
      await tester.pumpAndSettle();
      expect(find.text('¿Cuál eliges como principal?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(r.auth.guardados, isEmpty);
      await tester.tap(find.text('Elegir como principal'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Desarrollo de Videojuegos'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        r.auth.guardados.single,
        const SeleccionDeEspecialidades(principal: kIdVj, intereses: [kIdSi]),
      );
    });

    testWidgets('caso 18: mientras un guardado está en vuelo los botones no '
        'responden', (tester) async {
      final r = await _pantallaDelResultado(tester);
      final pendiente = Completer<void>();
      r.auth.respuestasDeGuardado.add(pendiente);
      await tester.tap(find.byKey(ResultView.corazonKey(kIdSi)));
      await tester.pump();
      await tester.tap(find.text('Decidir después'));
      await tester.tap(find.text('Rehacer el test'));
      await tester.pump();
      expect(r.auth.guardados, hasLength(1));
      expect(r.c.fase.value, FaseDelTest.resultado);
      pendiente.complete();
      await tester.pump();
      await tester.tap(find.text('Rehacer el test'));
      await tester.pump();
      expect(r.c.fase.value, FaseDelTest.pregunta);
    });
  });
}
