// test/bienvenida/bienvenida_horario_test.dart
//
// UNITARIA + WIDGET · Bienvenida con Ulises
// (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-11. El paso al horario como función pura del instante, y la capa
// del arranque que lo dibuja mientras /home se monta debajo, con Ulises que
// vuela a su burbuja, el fundido si la cabecera no se mide y el fundido de
// 220 ms con reducir movimiento (RF-BIEN-15). Durante el paso ningún toque
// llega a /home, que se monta con la capa encima y así sigue en vertical, y
// al llegar desde el splash la burbuja aparece con la página. Todo dato es
// inventado.
// Archivos probados lib/pages/splash/paso_al_horario.dart,
// lib/pages/splash/capa_de_arranque.dart y lib/components/chatbot_bubble.dart.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/chatbot_bubble.dart';
import 'package:ulima_plus/components/logo/sello_del_logo.dart';
import 'package:ulima_plus/domain/bienvenida/bienvenida_turnos.dart';
import 'package:ulima_plus/pages/home/home_page.dart' show abrirEnHorario;
import 'package:ulima_plus/pages/splash/capa_de_arranque.dart';
import 'package:ulima_plus/pages/splash/estado_de_la_capa.dart';
import 'package:ulima_plus/pages/splash/paso_al_horario.dart';
import 'package:ulima_plus/pages/splash/puntos_de_aterrizaje.dart';
import 'package:ulima_plus/pages/splash/salidas.dart';
import 'package:ulima_plus/services/session_navigation.dart';
import 'package:ulima_plus/services/splash_variante_service.dart';

import '../splash/apoyo_splash.dart'
    show
        CargaFalsa,
        HomeDePrueba,
        VariantesFijas,
        appConCapa,
        reiniciarArranque,
        telefono,
        toquesEnLaPagina;
import 'apoyo_bienvenida.dart';

const _pantalla = Size(375, 667);
const _avatar = Rect.fromLTWH(12, 130, 40, 40);
const _burbuja = Rect.fromLTWH(12, 595, 60, 60);
const _colorDeLaCabecera = Color(0xFF1E1E24);
const _colorDeLaPagina = Color(0xFFFEFDFC);

PiezasDelSello _sello() => PiezasDelSello(
  estrella: const Offset(142, 75),
  radio: 15.86,
  ulima: TextPainter(
    text: const TextSpan(text: 'ULIMA', style: TextStyle(fontSize: 24.4)),
    textDirection: TextDirection.ltr,
  )..layout(),
  origenDeUlima: const Offset(168, 61),
  mas: const <Offset>[Offset(252, 70), Offset(264, 70)],
  largoDeLosMas: 12.2,
);

DatosDelPaso _datos({Rect? avatar = _avatar}) => DatosDelPaso(
  franja: const Rect.fromLTWH(0, 0, 375, 102),
  colorDeLaFranja: const Color(0xFFFF6600),
  sello: _sello(),
  conversacion: null,
  lugarDeLaConversacion: const Rect.fromLTWH(0, 102, 375, 565),
  avatar: avatar,
  colorDeFondo: const Color(0xFFF5F5F7),
  colorDeLaPagina: _colorDeLaPagina,
);

DestinoDeLaSalida _destino() => DestinoDeLaSalida.desdeMedida(
  const MedidaDeCabecera(
    cabecera: Rect.fromLTWH(0, 0, 375, 102),
    estrella: Rect.fromLTWH(20, 52, 26, 26),
    texto: Rect.fromLTWH(56, 55, 90, 20),
    estilo: TextStyle(
      fontSize: 20,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    escalaDeTexto: TextScaler.noScaling,
    color: _colorDeLaCabecera,
    colorDelBorde: Color(0xFF3A3A44),
  ),
  _pantalla,
);

EscenaDelPaso _en(
  double ms, {
  Rect? burbuja = _burbuja,
  Rect? avatar = _avatar,
}) => pasoAlHorario(
  ms: ms,
  datos: _datos(avatar: avatar),
  destino: _destino(),
  burbuja: burbuja,
  pantalla: _pantalla,
);

/// Una /home con la cabecera que se informa y la burbuja de Ulises. Su botón
/// «home» cuenta los toques en `toquesEnLaPagina`.
class _HomeConBurbuja extends StatelessWidget {
  const _HomeConBurbuja({this.informa = true});

  final bool informa;

  /// Si la capa cubría la pantalla cuando /home se construyó por primera
  /// vez, que es cuando HomePage decide sus orientaciones (Tarea 6).
  static bool? cubiertaAlMontarse;

  @override
  Widget build(BuildContext context) {
    cubiertaAlMontarse ??= EstadoDeLaCapa.cubre.value;
    return Scaffold(
      body: Stack(
        children: [
          HomeDePrueba(informa: informa),
          const Positioned.fill(child: ChatbotBubble()),
        ],
      ),
    );
  }
}

/// Entra con «Sí, entrar» desde E1, con la capa del arranque en el builder,
/// y vuelve en el cuadro en que la capa toma el paso.
Future<Bienvenida> _hastaElPaso(
  WidgetTester tester, {
  bool informa = true,
  bool sinMovimiento = false,
  double escala = 1,
  void Function()? antesDeEntrar,
}) async {
  final b = Bienvenida(auth: AuthDeLaBienvenida(alEntrar: alumnaDePrueba()));
  await montarLaBienvenida(
    tester,
    b,
    argumentos: const {argumentoDeMotivo: MotivoDeLlegada.expirada},
    sinMovimiento: sinMovimiento,
    escala: escala,
    conCapa: true,
    home: () => _HomeConBurbuja(informa: informa),
  );
  await avanzar(tester, 1500);
  await llegarAE2(tester);
  await tester.enterText(find.byType(TextField).first, 'secreta-de-prueba');
  // Un cuadro tras teclear, para que «Entrar» se encienda.
  await tester.pump();
  antesDeEntrar?.call();
  await tester.tap(find.text(TextosDeLaBienvenida.entrar));
  // E3 entra 650 ms después y el paso empieza 900 ms después de E3.
  for (
    var t = 0;
    t < 3000 && CapaDeArranque.fase == FaseDeLaCapa.inactiva;
    t += 16
  ) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  expect(CapaDeArranque.fase, isNot(FaseDeLaCapa.inactiva));
  return b;
}

/// La opacidad con que se ve Ulises en la capa durante el paso.
double _opacidadDeUlisesEnLaCapa(WidgetTester tester) => tester
    .widget<Opacity>(
      find
          .ancestor(
            of: find.byKey(CapaDeArranque.claveDeUlisesDelPaso),
            matching: find.byType(Opacity),
          )
          .first,
    )
    .opacity;

/// La burbuja oculta mientras Ulises vuela, con su GestureDetector dentro.
Finder _burbujaOculta() => find.descendant(
  of: find.byType(ChatbotBubble),
  matching: find.byWidgetPredicate(
    (w) => w is Opacity && w.opacity == 0 && w.child is GestureDetector,
  ),
);

void main() {
  setUp(reiniciarArranque);
  setUp(() => _HomeConBurbuja.cubiertaAlMontarse = null);
  tearDown(reiniciarArranque);

  group('el paso, en funciones puras (RF-BIEN-11)', () {
    test('antes de medir la cabecera, el paso queda en su primer cuadro', () {
      final e = pasoAlHorario(
        ms: 0,
        datos: _datos(),
        destino: null,
        burbuja: null,
        pantalla: _pantalla,
      );
      expect(e.radioDeLaFranja, 26);
      expect(e.franja, const Rect.fromLTWH(0, 0, 375, 102));
      expect(e.estrella.centro, const Offset(142, 75));
      expect(e.opacidadDeLaConversacion, 1);
      expect(e.paginaOpacidad, 0);
    });

    test('las esquinas pasan de 26 dp a 0 en el primer 40 % y el color va al '
        'de la cabecera', () {
      expect(_en(0).radioDeLaFranja, closeTo(26, 1e-9));
      expect(_en(0.4 * 1050).radioDeLaFranja, closeTo(0, 1e-9));
      expect(
        _en(0.4 * 1050).colorDeLaFranja.toARGB32(),
        _colorDeLaCabecera.toARGB32(),
      );
    });

    test('la conversación se desvanece en el primer 35 % y /home aparece del '
        '22 % al 55 %, subiendo 24 dp desde el 32 % hasta el 75 %', () {
      expect(_en(0.35 * 1050).opacidadDeLaConversacion, closeTo(0, 1e-9));
      expect(_en(0.22 * 1050).paginaOpacidad, closeTo(0, 1e-9));
      expect(_en(0.55 * 1050).paginaOpacidad, closeTo(1, 1e-9));
      expect(_en(0.32 * 1050).paginaDy, closeTo(24, 1e-9));
      expect(_en(0.75 * 1050).paginaDy, closeTo(0, 1e-9));
    });

    test('la franja con el sello tapa la cabecera hasta el 70 % y se desvanece '
        'hasta el 100 %', () {
      expect(_en(0.7 * 1050).opacidadDeLaFranja, closeTo(1, 1e-9));
      expect(_en(1050).opacidadDeLaFranja, closeTo(0, 1e-9));
    });

    test(
      'el sello termina en la estrella de 26 dp y en el texto de la '
      'cabecera, y las cruces se funden con los glifos en el último 25 %',
      () {
        final d = _destino();
        final fin = _en(1050);
        expect(fin.estrella.centro.dx, closeTo(d.estrella.center.dx, 1e-9));
        expect(fin.estrella.centro.dy, closeTo(d.estrella.center.dy, 1e-9));
        expect(fin.estrella.radio, closeTo(13, 1e-9));
        expect(fin.origenDeUlima.dx, closeTo(d.texto.left, 1e-9));
        expect(fin.origenDeUlima.dy, closeTo(d.texto.top, 1e-9));
        for (var i = 0; i < 2; i++) {
          expect(fin.cruces[i].centro.dx, closeTo(d.cruces[i].dx, 1e-9));
          expect(fin.cruces[i].centro.dy, closeTo(d.cruces[i].dy, 1e-9));
        }
        expect(fin.opacidadDeLasCruces, closeTo(0, 1e-9));
        expect(fin.fundidoAlTexto, closeTo(1, 1e-9));
        expect(_en(0.75 * 1050).opacidadDeLasCruces, closeTo(1, 1e-9));
      },
    );

    test('Ulises sale de su avatar, crece hasta 1,6 veces, llega a la burbuja '
        'con 56 dp y se posa en 420 ms', () {
      expect(_en(0).ulises!.centro, _avatar.center);
      expect(_en(0).ulises!.lado, closeTo(40, 1e-9));
      expect(_en(0.45 * 1150).ulises!.lado, closeTo(64, 1e-9));
      final llega = _en(1150);
      expect(llega.ulises!.centro.dx, closeTo(_burbuja.center.dx, 1e-9));
      expect(llega.ulises!.centro.dy, closeTo(_burbuja.center.dy, 1e-9));
      expect(llega.ulises!.lado, closeTo(56, 1e-9));
      expect(llega.ulisesPosado, isFalse);
      expect(_en(1570).ulises, isNull);
      expect(_en(1570).ulisesPosado, isTrue);
      expect(duracionDelPaso(conVuelo: true), 1570);
    });

    test('sin burbuja, como el docente, Ulises se desvanece con la '
        'conversación y el paso dura 1050 ms', () {
      expect(_en(0, burbuja: null).ulises!.opacidad, closeTo(1, 1e-9));
      expect(
        _en(0.35 * 1050, burbuja: null).ulises!.opacidad,
        closeTo(0, 1e-9),
      );
      expect(_en(0, burbuja: null).ulisesPosado, isTrue);
      expect(duracionDelPaso(conVuelo: false), 1050);
    });
  });

  group('la capa dibuja el paso (RF-BIEN-11 y B-33)', () {
    testWidgets('la bienvenida entrega el paso, navega a /home en Horario y se '
        'reinicia, y la burbuja espera oculta a Ulises', (tester) async {
      final semantica = tester.ensureSemantics();
      final b = await _hastaElPaso(tester);
      await avanzar(tester, 150);
      expect(CapaDeArranque.fase, FaseDeLaCapa.pasoAlHorario);
      expect(EstadoDeLaCapa.cubre.value, isTrue);
      expect(Get.currentRoute, '/home');
      final home = tester.element(find.byType(HomeDePrueba));
      expect(ModalRoute.of(home)!.settings.arguments, abrirEnHorario);
      expect(b.controlador.entradas, isEmpty);
      expect(b.login.codeController.text, '');
      expect(b.login.passwordController.text, '');
      expect(PuntosDeAterrizaje.ulisesEnVuelo.value, isTrue);
      expect(_burbujaOculta(), findsOneWidget);
      // Ulises vuela en la capa, a la vista.
      expect(find.byKey(CapaDeArranque.claveDeUlisesDelPaso), findsOneWidget);
      expect(_opacidadDeUlisesEnLaCapa(tester), 1);
      // El lector solo ve «ULIMA++», sin «cargando» (RF-BIEN-16).
      expect(find.bySemanticsLabel('ULIMA++'), findsOneWidget);
      expect(find.bySemanticsLabel(etiquetaDeLaIntro), findsNothing);
      await avanzar(tester, 1700);
      expect(CapaDeArranque.fase, FaseDeLaCapa.inactiva);
      expect(EstadoDeLaCapa.cubre.value, isFalse);
      expect(PuntosDeAterrizaje.ulisesEnVuelo.value, isFalse);
      expect(_burbujaOculta(), findsNothing);
      semantica.dispose();
    });

    testWidgets('durante el paso ningún toque llega a /home, que se monta con '
        'la capa encima y así sigue en vertical, y al retirarse la capa los '
        'toques vuelven (S-26)', (tester) async {
      final orientaciones = <Object?>[];
      final mensajero = tester.binding.defaultBinaryMessenger;
      mensajero.setMockMethodCallHandler(SystemChannels.platform, (
        llamada,
      ) async {
        if (llamada.method == 'SystemChrome.setPreferredOrientations') {
          orientaciones.add(llamada.arguments);
        }
        return null;
      });
      addTearDown(
        () => mensajero.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await _hastaElPaso(tester);
      await avanzar(tester, 150);
      expect(CapaDeArranque.fase, FaseDeLaCapa.pasoAlHorario);
      expect(_HomeConBurbuja.cubiertaAlMontarse, isTrue);
      await tester.tap(find.text('home'), warnIfMissed: false);
      await tester.pump();
      expect(toquesEnLaPagina, 0, reason: 'los toques quedan en la capa');
      expect(orientaciones, isEmpty, reason: 'nada pide girar bajo la capa');
      await avanzar(tester, 1700);
      expect(CapaDeArranque.fase, FaseDeLaCapa.inactiva);
      await tester.tap(find.text('home'));
      await tester.pump();
      expect(toquesEnLaPagina, 1);
    });

    testWidgets('al llegar a /home desde el splash, la burbuja aparece con la '
        'página y no espera a nadie (S-28)', (tester) async {
      telefono(tester);
      final carga = CargaFalsa();
      await tester.pumpWidget(
        appConCapa(
          intro: IntroDelArranque(
            carga: carga.call,
            variantes: VariantesFijas(VarianteSplash.ensamble),
            random: Random(1),
          ),
          home: (_) => const _HomeConBurbuja(),
        ),
      );
      carga.terminar('/home');
      var enLaSalida = false;
      for (
        var t = 0;
        t < 4000 &&
            (!enLaSalida || CapaDeArranque.fase != FaseDeLaCapa.inactiva);
        t += 16
      ) {
        await tester.pump(const Duration(milliseconds: 16));
        if (CapaDeArranque.fase == FaseDeLaCapa.salida) {
          enLaSalida = true;
          expect(find.byType(ChatbotBubble), findsOneWidget);
          expect(_burbujaOculta(), findsNothing);
          expect(PuntosDeAterrizaje.ulisesEnVuelo.value, isFalse);
        }
      }
      expect(enLaSalida, isTrue);
      expect(CapaDeArranque.fase, FaseDeLaCapa.inactiva);
      expect(_burbujaOculta(), findsNothing);
    });

    testWidgets('si la cabecera no se mide, el paso es un fundido de 300 ms y '
        'la burbuja aparece con la página', (tester) async {
      await _hastaElPaso(tester, informa: false);
      await avanzar(tester, 500);
      expect(CapaDeArranque.fase, FaseDeLaCapa.inactiva);
      expect(PuntosDeAterrizaje.ulisesEnVuelo.value, isFalse);
      expect(_burbujaOculta(), findsNothing);
    });

    testWidgets('con reducir movimiento, /home entera debajo y la capa se '
        'desvanece encima en 220 ms, sin vuelo (RF-BIEN-15)', (tester) async {
      await _hastaElPaso(tester, sinMovimiento: true);
      var visto = false;
      var dura = 0;
      while (dura < 1000 && CapaDeArranque.fase != FaseDeLaCapa.inactiva) {
        visto = visto || PuntosDeAterrizaje.ulisesEnVuelo.value;
        await tester.pump(const Duration(milliseconds: 16));
        dura += 16;
      }
      expect(CapaDeArranque.fase, FaseDeLaCapa.inactiva);
      expect(dura, lessThanOrEqualTo(300));
      expect(visto, isFalse);
    });
  });

  group(
    'el paso sale de lo que se ve (RF-BIEN-4, RF-BIEN-11 y RF-BIEN-16)',
    () {
      // Con la letra de prueba todas las familias miden lo mismo, así que el
      // sello se mide con Roboto, como en la app.
      setUpAll(cargarRoboto);

      for (final escala in <double>[1.0, 1.3]) {
        testWidgets('con el texto a $escala, «ULIMA», los «++» y la franja del '
            'primer cuadro caen sobre los del sello real', (tester) async {
          late Rect ulima;
          late Rect losMas;
          late Rect franja;
          late double yDeLosMas;
          await _hastaElPaso(
            tester,
            escala: escala,
            antesDeEntrar: () {
              final sello = find.byType(SelloDelLogo);
              ulima = tester.getRect(
                find.descendant(of: sello, matching: find.text('ULIMA')),
              );
              losMas = tester.getRect(
                find
                    .descendant(of: sello, matching: find.byType(CustomPaint))
                    .last,
              );
              franja = tester.getRect(find.byType(CabeceraConSello));
              // El pintor de los «++» los centra en la base de sus glifos
              // menos 0,34 em, contados desde arriba de su caja.
              final contexto = tester.element(sello);
              final escala = tester
                  .widget<Text>(
                    find.descendant(of: sello, matching: find.text('ULIMA')),
                  )
                  .textScaler!;
              final estilo = DefaultTextStyle.of(contexto).style.merge(
                SelloDelLogo.estilo(Theme.of(contexto).colorScheme),
              );
              final glifos = TextPainter(
                text: TextSpan(text: '++', style: estilo),
                textDirection: TextDirection.ltr,
                textScaler: escala,
              )..layout();
              yDeLosMas =
                  losMas.top +
                  glifos.computeDistanceToActualBaseline(
                    TextBaseline.alphabetic,
                  ) -
                  0.34 * escala.scale(estilo.fontSize!);
              glifos.dispose();
            },
          );
          final e = CapaDeArranque.pasoActual!;
          expect(e.escalaDeUlima, 1);
          expect(e.origenDeUlima.dx, closeTo(ulima.left, 0.5));
          expect(e.origenDeUlima.dy, closeTo(ulima.top, 0.5));
          // Cada «+» va al 25 % y al 75 % de la caja de los «++», a la altura
          // en que los dibuja su pintor.
          expect(e.cruces, hasLength(2));
          for (var i = 0; i < 2; i++) {
            final c = e.cruces[i].centro;
            expect(
              c.dx,
              closeTo(losMas.left + losMas.width * (0.25 + 0.5 * i), 0.5),
            );
            expect(c.dy, closeTo(yDeLosMas, 0.5));
          }
          expect(e.franja.top, 0);
          expect(e.franja.height, closeTo(franja.height, 0.5));
          await avanzar(tester, 1800);
        });
      }
    },
  );

  group('Ulises en los fundidos del paso (RF-BIEN-11 y RF-BIEN-15)', () {
    testWidgets('con reducir movimiento, Ulises se desvanece con la capa en '
        '220 ms', (tester) async {
      await _hastaElPaso(tester, sinMovimiento: true);
      await avanzar(tester, 16);
      expect(CapaDeArranque.fase, FaseDeLaCapa.fundido);
      await avanzar(tester, 96);
      expect(CapaDeArranque.opacidad, inExclusiveRange(0, 1));
      expect(
        _opacidadDeUlisesEnLaCapa(tester),
        closeTo(CapaDeArranque.opacidad, 0.05),
      );
      await avanzar(tester, 300);
      expect(CapaDeArranque.fase, FaseDeLaCapa.inactiva);
    });

    testWidgets('si la cabecera no se mide, Ulises se desvanece con la capa en '
        '300 ms', (tester) async {
      await _hastaElPaso(tester, informa: false);
      for (
        var t = 0;
        t < 500 && CapaDeArranque.fase != FaseDeLaCapa.fundido;
        t += 16
      ) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(CapaDeArranque.fase, FaseDeLaCapa.fundido);
      await avanzar(tester, 150);
      expect(CapaDeArranque.opacidad, inExclusiveRange(0, 1));
      expect(
        _opacidadDeUlisesEnLaCapa(tester),
        closeTo(CapaDeArranque.opacidad, 0.05),
      );
      await avanzar(tester, 400);
      expect(CapaDeArranque.fase, FaseDeLaCapa.inactiva);
    });
  });

  group('lo que la capa suelta (RF-BIEN-11)', () {
    testWidgets('al retirarse, la capa desecha los textos medidos de la '
        'cabecera', (tester) async {
      await _hastaElPaso(tester);
      await avanzar(tester, 150);
      final destino = CapaDeArranque.destinoActual!;
      expect(destino.pintorDeUlima.debugDisposed, isFalse);
      await avanzar(tester, 1700);
      expect(CapaDeArranque.fase, FaseDeLaCapa.inactiva);
      expect(destino.pintorDeUlima.debugDisposed, isTrue);
      expect(destino.pintorDeLosMas.debugDisposed, isTrue);
    });

    testWidgets('si la capa sale del árbol a mitad del paso, la burbuja '
        'vuelve a verse', (tester) async {
      await _hastaElPaso(tester);
      await avanzar(tester, 150);
      expect(PuntosDeAterrizaje.ulisesEnVuelo.value, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(PuntosDeAterrizaje.ulisesEnVuelo.value, isFalse);
    });
  });

  group('la cabecera de /home bajo la franja (RF-BIEN-11)', () {
    test('mientras el cuerpo sube, una banda del fondo de /home tapa lo que '
        'bajó de la cabecera, debajo de la conversación', () {
      final datos = _datos();
      final destino = _destino();
      final e = pasoAlHorario(
        ms: 450,
        datos: datos,
        destino: destino,
        burbuja: _burbuja,
        pantalla: _pantalla,
      );
      expect(e.paginaDy, greaterThan(1));
      expect(e.paginaOpacidad, greaterThan(0));
      final banda = Rect.fromLTWH(
        e.franja.left,
        e.franja.bottom,
        e.franja.width,
        e.paginaDy,
      );
      expect(
        (Canvas canvas) => pintarElPaso(canvas, e, datos, destino),
        paints..rect(rect: banda, color: _colorDeLaPagina),
      );
      // En el primer cuadro la página no se ve y no hay banda.
      final inicio = pasoAlHorario(
        ms: 0,
        datos: datos,
        destino: destino,
        burbuja: _burbuja,
        pantalla: _pantalla,
      );
      expect(
        (Canvas canvas) => pintarElPaso(canvas, inicio, datos, destino),
        isNot(paints..rect(color: _colorDeLaPagina)),
      );
      // Y cuando el cuerpo llegó, tampoco.
      final fin = pasoAlHorario(
        ms: 1000,
        datos: datos,
        destino: destino,
        burbuja: _burbuja,
        pantalla: _pantalla,
      );
      expect(fin.paginaDy, lessThan(0.5));
      expect(
        (Canvas canvas) => pintarElPaso(canvas, fin, datos, destino),
        isNot(paints..rect(color: _colorDeLaPagina)),
      );
      datos.sello.ulima.dispose();
    });
  });
}
