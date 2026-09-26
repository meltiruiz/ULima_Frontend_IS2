// test/bienvenida/bienvenida_conversacion_test.dart
//
// WIDGET · Bienvenida con Ulises (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-5. La franja con el sello, la conversación y el compositor fijo
// abajo, los grupos de Ulises, las respuestas a la derecha, el ritmo de 850 y
// 500 ms, el compositor de E1 y E2 y el teclado. Llega con un motivo, así que
// empieza directo en E1, sin el recibimiento de la Tarea 28.
// Archivo probado lib/pages/bienvenida/bienvenida_page.dart.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/logo/sello_del_logo.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/domain/bienvenida/bienvenida_turnos.dart';
import 'package:ulima_plus/pages/bienvenida/conversacion.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/compositor.dart';
import 'package:ulima_plus/services/session_navigation.dart';

import 'apoyo_bienvenida.dart';

const _expirada = <String, Object>{argumentoDeMotivo: MotivoDeLlegada.expirada};

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  test('el ritmo es de 850 ms entre burbujas, 650 ms tras una respuesta, '
      '500 ms antes del compositor y 900 ms antes del paso al horario '
      '(RF-BIEN-5 y RF-BIEN-6)', () {
    expect(Ritmo.entreBurbujas, const Duration(milliseconds: 850));
    expect(Ritmo.trasLaRespuesta, const Duration(milliseconds: 650));
    expect(Ritmo.antesDelCompositor, const Duration(milliseconds: 500));
    expect(Ritmo.antesDelPaso, const Duration(milliseconds: 900));
  });

  test('N1 espera 650 ms tras «Soy nuevo» y su pregunta 850 ms, E1 con motivo '
      '850 ms tras el saludo, y E2 y E3 650 ms tras la respuesta', () async {
    Duration pausaDe(Bienvenida b, String texto) => b.controlador.entradas
        .whereType<BurbujaDeUlises>()
        .lastWhere((e) => e.texto == texto)
        .pausa;
    const ms650 = Duration(milliseconds: 650);
    const ms850 = Duration(milliseconds: 850);
    final nuevo = Bienvenida();
    await nuevo.visitar();
    nuevo.controlador.responderAlSaludo(yaUsa: false);
    expect(pausaDe(nuevo, TextosDeLaBienvenida.n1a), ms650);
    expect(pausaDe(nuevo, TextosDeLaBienvenida.n1b), ms850);
    Get.reset();
    final b = Bienvenida();
    await b.visitar(motivo: MotivoDeLlegada.expirada);
    expect(pausaDe(b, TextosDeLaBienvenida.saludo), Duration.zero);
    expect(pausaDe(b, TextosDeLaBienvenida.e1), ms850);
    b.login.codeController.text = '20230001';
    b.controlador.enviarCodigo();
    expect(pausaDe(b, TextosDeLaBienvenida.e2), ms650);
    b.login.passwordController.text = 'secreta-de-prueba';
    await b.controlador.entrar();
    expect(pausaDe(b, TextosDeLaBienvenida.e3), ms650);
  });

  testWidgets('la franja con el sello va arriba, la conversación en medio y '
      'el compositor abajo', (tester) async {
    final b = Bienvenida();
    await montarLaBienvenida(tester, b, argumentos: _expirada);
    // E1 entra a los 850 ms y el compositor 500 ms después, en 300 ms.
    await avanzar(tester, 1800);
    final sello = tester.getRect(find.byType(SelloDelLogo));
    final compositor = tester.getRect(find.byType(MarcoDelCompositor));
    expect(sello.top, lessThan(100));
    expect(compositor.bottom, closeTo(667, 0.5));
    expect(
      tester.widget<CabeceraConSello>(find.byType(CabeceraConSello)).color,
      MaterialTheme.bienvenidaFranja(Brightness.light),
    );
    expect(find.text(TextosDeLaBienvenida.saludo), findsOneWidget);
    expect(find.text(TextosDeLaBienvenida.e1), findsOneWidget);
  });

  testWidgets('cada burbuja entra 850 ms después de la anterior y el '
      'compositor 500 ms después de la última', (tester) async {
    final b = Bienvenida();
    await montarLaBienvenida(tester, b, argumentos: _expirada);
    // El saludo entra enseguida, E1 850 ms después.
    expect(find.text(TextosDeLaBienvenida.saludo), findsOneWidget);
    expect(find.text(TextosDeLaBienvenida.e1), findsNothing);
    await tester.pump(const Duration(milliseconds: 840));
    expect(find.text(TextosDeLaBienvenida.e1), findsNothing);
    await tester.pump(const Duration(milliseconds: 20));
    expect(find.text(TextosDeLaBienvenida.e1), findsOneWidget);
    expect(find.byType(MarcoDelCompositor), findsNothing);
    // E1 entró a los 850 ms, así que el compositor entra a los 1350.
    await tester.pump(const Duration(milliseconds: 480));
    expect(find.byType(MarcoDelCompositor), findsNothing);
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump(const Duration(milliseconds: 20));
    expect(find.byType(MarcoDelCompositor), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('el primer grupo lleva el nombre «Ulises» y los siguientes no, '
      'y las respuestas van a la derecha con «Tú»', (tester) async {
    final semantica = tester.ensureSemantics();
    final b = Bienvenida();
    await montarLaBienvenida(tester, b, argumentos: _expirada);
    await avanzar(tester, 1500);
    expect(find.text('Ulises'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '20230001');
    // El botón se activa en el cuadro siguiente al texto.
    await tester.pump();
    await tester.tap(find.byType(BotonDeEnvio));
    await avanzar(tester, 1600);
    final respuesta = tester.getRect(find.text('20230001').last);
    expect(respuesta.right, greaterThan(375 - 40));
    expect(find.bySemanticsLabel('Tú, 20230001'), findsOneWidget);
    expect(find.text('Ulises'), findsOneWidget, reason: 'solo el primer grupo');
    expect(find.text(TextosDeLaBienvenida.e2), findsOneWidget);
    semantica.dispose();
  });

  testWidgets('el botón de envío queda inactivo con el campo vacío', (
    tester,
  ) async {
    final b = Bienvenida();
    await montarLaBienvenida(tester, b, argumentos: _expirada);
    await avanzar(tester, 1500);
    final boton = tester.widget<BotonDeEnvio>(find.byType(BotonDeEnvio));
    expect(boton.alTocar, isNull);
    await tester.enterText(find.byType(TextField).first, 'docente.test');
    await tester.pump();
    expect(
      tester.widget<BotonDeEnvio>(find.byType(BotonDeEnvio)).alTocar,
      isNotNull,
    );
  });

  testWidgets('E2 trae el ojo, «Entrar», «¿Olvidaste tu contraseña?» y «Soy '
      'nuevo»', (tester) async {
    final semantica = tester.ensureSemantics();
    final b = Bienvenida();
    await montarLaBienvenida(tester, b, argumentos: _expirada);
    await avanzar(tester, 1500);
    await tester.enterText(find.byType(TextField).first, '20230001');
    // El botón se activa en el cuadro siguiente al texto.
    await tester.pump();
    await tester.tap(find.byType(BotonDeEnvio));
    await avanzar(tester, 2000);
    expect(
      find.bySemanticsLabel(TextosDeLaBienvenida.mostrarContrasena),
      findsOneWidget,
    );
    expect(find.text(TextosDeLaBienvenida.entrar), findsOneWidget);
    expect(find.text(TextosDeLaBienvenida.olvidaste), findsOneWidget);
    expect(find.text(TextosDeLaBienvenida.soyNuevo), findsOneWidget);
    await tester.tap(find.text(TextosDeLaBienvenida.olvidaste));
    expect(b.rutas, ['/forgot-password']);
    semantica.dispose();
  });

  testWidgets('E1 trae «o», «Continuar con Google» y «Soy nuevo»', (
    tester,
  ) async {
    final b = Bienvenida();
    await montarLaBienvenida(tester, b, argumentos: _expirada);
    await avanzar(tester, 1500);
    expect(find.text(TextosDeLaBienvenida.separadorO), findsOneWidget);
    expect(find.byType(BotonDeGoogle), findsOneWidget);
    expect(
      tester.getSize(find.byType(BotonDeGoogle)).height,
      greaterThanOrEqualTo(48),
    );
    expect(find.text(TextosDeLaBienvenida.soyNuevo), findsOneWidget);
    // El logo oficial de Google, a color y sin filtro (RF-BIEN-6).
    final logo = tester.widget<SvgPicture>(
      find.descendant(
        of: find.byType(BotonDeGoogle),
        matching: find.byType(SvgPicture),
      ),
    );
    expect(logo.colorFilter, isNull);
    expect(
      (logo.bytesLoader as SvgAssetLoader).assetName,
      'assets/images/google_logo.svg',
    );
  });

  testWidgets('con el teclado abierto la franja queda arriba y el compositor '
      'sobre el teclado', (tester) async {
    final b = Bienvenida();
    await montarLaBienvenida(tester, b, argumentos: _expirada);
    await avanzar(tester, 1800);
    tester.view.viewInsets = const FakeViewPadding(bottom: 600);
    await tester.pump();
    final sello = tester.getRect(find.byType(SelloDelLogo));
    final compositor = tester.getRect(find.byType(MarcoDelCompositor));
    expect(sello.top, lessThan(100));
    expect(compositor.bottom, closeTo(667 - 300, 0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('el campo va en testChipBg y con el foco pasa a cardBg '
      '(RF-BIEN-5)', (tester) async {
    final b = Bienvenida();
    await montarLaBienvenida(tester, b, argumentos: _expirada);
    await avanzar(tester, 1500);
    Color? fondo(Set<WidgetState> estados) {
      final decorador = tester.widget<InputDecorator>(
        find.byType(InputDecorator).first,
      );
      return WidgetStateProperty.resolveAs<Color?>(
        decorador.decoration.fillColor,
        estados,
      );
    }

    expect(fondo(<WidgetState>{}), MaterialTheme.testChipBg(Brightness.light));
    expect(
      fondo(<WidgetState>{WidgetState.focused}),
      MaterialTheme.cardBg(Brightness.light),
    );
    expect(
      tester
          .widget<InputDecorator>(find.byType(InputDecorator).first)
          .isFocused,
      isTrue,
    );
  });

  for (final (escala, teclado) in <(double, double)>[
    (1.0, 300),
    (1.0, 340),
    (1.3, 300),
  ]) {
    testWidgets('con el teclado de $teclado dp y el texto a $escala, el '
        'compositor de N2 mide hasta el 60 % del alto sobre el teclado y nada '
        'desborda (RF-BIEN-5)', (tester) async {
      final b = Bienvenida();
      await montarLaBienvenida(
        tester,
        b,
        argumentos: _expirada,
        escala: escala,
      );
      await avanzar(tester, 1500);
      b.controlador.soyNuevo();
      await avanzar(tester, 3000);
      await tester.enterText(find.byType(TextField).first, '20230001');
      await tester.pump();
      await tester.tap(find.byType(BotonDeEnvio));
      await avanzar(tester, 2500);
      expect(find.text(TextosDeLaBienvenida.rotuloRepetir), findsOneWidget);
      tester.view.viewInsets = FakeViewPadding(bottom: teclado * 2);
      await tester.pump();
      final alto = tester.getSize(find.byType(MarcoDelCompositor)).height;
      expect(alto, lessThanOrEqualTo((667 - teclado) * 0.6 + 0.5));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('las burbujas de Ulises van en cardBg y las respuestas en '
      'bienvenidaPropia', (tester) async {
    final b = Bienvenida();
    await montarLaBienvenida(tester, b, argumentos: _expirada);
    await avanzar(tester, 1500);
    final caja = tester.widget<DecoratedBox>(
      find
          .ancestor(
            of: find.text(TextosDeLaBienvenida.saludo),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect(
      (caja.decoration as BoxDecoration).color,
      MaterialTheme.cardBg(Brightness.light),
    );
    // La respuesta del alumno, en bienvenidaPropia.
    await tester.enterText(find.byType(TextField).first, '20230001');
    await tester.pump();
    await tester.tap(find.byType(BotonDeEnvio));
    await avanzar(tester, 1000);
    final respuesta = tester.widget<DecoratedBox>(
      find
          .ancestor(
            of: find.descendant(
              of: find.byType(ListView),
              matching: find.text('20230001'),
            ),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect(
      (respuesta.decoration as BoxDecoration).color,
      MaterialTheme.bienvenidaPropia(Brightness.light),
    );
  });
}
