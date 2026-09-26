// test/bienvenida/bienvenida_recibimiento_test.dart
//
// UNITARIA + WIDGET · Bienvenida con Ulises
// (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-2 y RF-BIEN-3. El primer cuadro igual a la pose recibida, el vuelo
// de Ulises, la tarjeta a los 1,94 s y los botones a los 2,32 s, los toques
// ignorados antes, las medidas en 375 × 667 con 1,0, 1,3 y 2,0, «Si no cabe»
// y la subida con el primer grupo. Las medidas usan Roboto, la fuente del
// tema en Android, que sale de FLUTTER_ROOT.
// Archivos probados lib/pages/bienvenida/widgets/recibimiento.dart y
// lib/pages/bienvenida/widgets/vuelo_de_ulises.dart.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/logo/escena_del_logo.dart';
import 'package:ulima_plus/components/logo/sello_del_logo.dart';
import 'package:ulima_plus/domain/bienvenida/bienvenida_turnos.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/compositor.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/recibimiento.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/vuelo_de_ulises.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/ulises_bubble.dart';
import 'package:ulima_plus/services/session_navigation.dart';

import 'apoyo_bienvenida.dart';

/// La pose que deja la intro en 375 × 667.
PoseDelLogo _pose() =>
    EscenaDelLogo.reposo(centro: const Offset(187.5, 333.5), radio: 90).pose;

Map<String, Object> _conPose() => <String, Object>{argumentoDePose: _pose()};

Finder _fondo() => find.byKey(Recibimiento.claveDelFondo);
Finder _ulises() => find.byKey(Recibimiento.claveDeUlises);

void main() {
  setUpAll(cargarRoboto);
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  group('el vuelo, en funciones puras (RF-BIEN-2)', () {
    const aterrizaje = Offset(83.5, 471.5);
    final puntos = puntosDelVuelo(aterrizaje, const Size(375, 667));
    const grados = math.pi / 180;

    test('entra con 62 dp y −26° y llega con 70 dp a su lugar en 1300 ms', () {
      final inicio = ulisesEnVuelo(puntos, aterrizaje, 0);
      expect(inicio.centro, puntos.inicio);
      expect(inicio.lado, closeTo(62, 1e-9));
      expect(inicio.giro, closeTo(-26 * grados, 1e-9));
      final fin = ulisesEnVuelo(puntos, aterrizaje, 1300);
      expect(fin.centro.dx, closeTo(83.5, 1e-9));
      expect(fin.centro.dy, closeTo(471.5, 1e-9));
      expect(fin.lado, closeTo(70, 1e-9));
      expect(fin.giro, closeTo(0, 1e-9));
    });

    test('recorre la Bézier con la curva seno', () {
      // A la cuarta parte del tiempo, la curva seno lleva 1 − cos(π/4) / 2.
      final e = 0.5 - 0.5 * math.cos(math.pi / 4);
      final s = 1 - e;
      final esperado =
          puntos.inicio * (s * s * s) +
          puntos.control1 * (3 * s * s * e) +
          puntos.control2 * (3 * s * e * e) +
          aterrizaje * (e * e * e);
      final cuarto = ulisesEnVuelo(puntos, aterrizaje, 325).centro;
      expect(cuarto.dx, closeTo(esperado.dx, 1e-9));
      expect(cuarto.dy, closeTo(esperado.dy, 1e-9));
    });

    test('se inclina hasta 14° a mitad del vuelo', () {
      expect(
        ulisesEnVuelo(puntos, aterrizaje, 650).giro,
        closeTo(14 * grados, 1e-9),
      );
    });

    test('se comprime cinco veces como un aleteo', () {
      var compresiones = 0;
      var antes = 1.0;
      var bajando = false;
      for (var ms = 0.0; ms <= 1300; ms += 1) {
        final y = ulisesEnVuelo(puntos, aterrizaje, ms).escalaY;
        if (y < antes) bajando = true;
        if (y > antes && bajando) {
          compresiones++;
          bajando = false;
        }
        antes = y;
      }
      expect(compresiones + (bajando ? 1 : 0), 5);
    });

    test('la estela nunca pasa de 30 puntos de 7 dp y cada uno se apaga en '
        '560 ms', () {
      expect(radioDeLaEstela, 3.5);
      for (var ms = 0.0; ms <= 1900; ms += 10) {
        final estela = estelaDelVuelo(puntos, aterrizaje, ms);
        expect(estela.length, lessThanOrEqualTo(30));
        expect(estela.every((p) => p.opacidad > 0 && p.opacidad <= 1), isTrue);
      }
      expect(estelaDelVuelo(puntos, aterrizaje, 1300 + 560), isEmpty);
    });

    test('se posa con un rebote de 480 ms que lo aplasta y lo estira, y '
        'suelta seis partículas que se apagan en 480 ms', () {
      final aplastado = ulisesAlAterrizar(aterrizaje, 80);
      expect(aplastado.escalaY, lessThan(1));
      expect(aplastado.escalaX, greaterThan(1));
      final estirado = List<PoseDeUlises>.generate(
        48,
        (i) => ulisesAlAterrizar(aterrizaje, i * 10.0),
      ).any((p) => p.escalaY > 1);
      expect(estirado, isTrue);
      final quieto = ulisesAlAterrizar(aterrizaje, 480);
      expect(quieto.escalaX, closeTo(1, 1e-9));
      expect(quieto.escalaY, closeTo(1, 1e-9));
      expect(particulasDelAterrizaje(aterrizaje, 0), hasLength(6));
      expect(particulasDelAterrizaje(aterrizaje, 479), hasLength(6));
      expect(particulasDelAterrizaje(aterrizaje, 480), isEmpty);
      // Salen de sus pies hacia arriba, hasta 30 dp.
      for (final p in particulasDelAterrizaje(aterrizaje, 479.9)) {
        final pies = aterrizaje + const Offset(0, 35);
        expect((p.centro - pies).distance, closeTo(30, 0.1));
        expect(p.centro.dy, lessThanOrEqualTo(pies.dy + 1e-9));
      }
    });

    test('asiente en 320 ms con −6° y un 6 % más de escala', () {
      final medio = ulisesAsiente(aterrizaje, 160);
      expect(medio.giro, closeTo(-6 * grados, 1e-9));
      expect(medio.escalaX, closeTo(1.06, 1e-9));
      expect(medio.escalaY, closeTo(1.06, 1e-9));
      final fin = ulisesAsiente(aterrizaje, 320);
      expect(fin.giro, closeTo(0, 1e-9));
      expect(fin.escalaX, closeTo(1, 1e-9));
    });

    test('se agacha 190 ms y se posa en su avatar de 40 dp a los 910 ms, en '
        'un arco que sube sobre los dos extremos', () {
      const avatar = Offset(32, 150);
      expect(ulisesSalta(aterrizaje, avatar, 100).escalaY, lessThan(1));
      expect(ulisesSalta(aterrizaje, avatar, 100).centro, aterrizaje);
      final posado = ulisesSalta(aterrizaje, avatar, 910);
      expect(posado.centro.dx, closeTo(avatar.dx, 1e-9));
      expect(posado.centro.dy, closeTo(avatar.dy, 1e-9));
      expect(posado.lado, closeTo(40, 1e-9));
      // Por el control de 132 dp sobre el avatar, el arco pasa por encima de
      // él antes de posarse.
      final alto = List<double>.generate(
        72,
        (i) => ulisesSalta(aterrizaje, avatar, 190 + i * 10.0).centro.dy,
      ).reduce(math.min);
      expect(alto, lessThan(avatar.dy));
    });

    test('la sombra crece de 18 a 56 dp y se oscurece al acercarse', () {
      final lejos = sombraDelVuelo(aterrizaje, 0);
      final cerca = sombraDelVuelo(aterrizaje, 1);
      expect(lejos.ancho, 18);
      expect(cerca.ancho, 56);
      expect(lejos.opacidad, 0);
      expect(cerca.opacidad, closeTo(0.2, 1e-9));
    });
  });

  for (final brillo in Brightness.values) {
    testWidgets('el primer cuadro es #E77330 con el logo en la pose recibida, '
        'en ${brillo.name}', (tester) async {
      await montarLaBienvenida(
        tester,
        Bienvenida(),
        argumentos: _conPose(),
        brillo: brillo,
      );
      final cuadro = Recibimiento.cuadroActual(tester.element(_fondo()));
      expect(cuadro.fondo, const Color(0xFFE77330));
      expect(cuadro.estrella!.pose.centro, _pose().centro);
      expect(cuadro.estrella!.pose.radio, 90);
      expect(cuadro.estrella!.cruces, hasLength(2));
      await avanzar(tester, 3000);
    });
  }

  testWidgets('quieto 160 ms, Ulises entra con 62 dp, aterriza con 70 dp '
      'junto a la estrella y la tarjeta aparece a los 1,94 s', (tester) async {
    await montarLaBienvenida(tester, Bienvenida(), argumentos: _conPose());
    await avanzar(tester, 140);
    expect(_ulises(), findsNothing, reason: 'nada se mueve en 160 ms');
    // A los 168 ms ya vuela.
    await tester.pump(const Duration(milliseconds: 24));
    expect(_ulises(), findsOneWidget);
    await avanzar(tester, 32);
    expect(tester.getSize(_ulises()).width, closeTo(62, 1));
    await avanzar(tester, 1700);
    final ulises = tester.getRect(_ulises());
    expect(ulises.width, closeTo(70, 3));
    expect(ulises.center.dx, closeTo(187.5 - 104, 1));
    expect(ulises.center.dy, closeTo(333.5 + 138, 1));
    expect(find.text(TextosDeLaBienvenida.pregunta), findsNothing);
    await avanzar(tester, 150);
    expect(find.text(TextosDeLaBienvenida.pregunta), findsOneWidget);
    expect(find.text(TextosDeLaBienvenida.saludo), findsOneWidget);
    await avanzar(tester, 1000);
  });

  testWidgets('el fondo pasa en 1100 ms de #E77330 al color de la franja '
      'mientras Ulises vuela', (tester) async {
    await montarLaBienvenida(tester, Bienvenida(), argumentos: _conPose());
    // A los 380 ms va un 20 % del tiempo, y con la curva seno un 9,5 % del
    // color. Lineal, o en 900 ms, iría bastante más.
    await tester.pump(const Duration(milliseconds: 380));
    final esperado = Color.lerp(
      const Color(0xFFE77330),
      const Color(0xFFFF6600),
      curvaSeno(220 / 1100),
    )!;
    final pronto = Recibimiento.cuadroActual(tester.element(_fondo())).fondo!;
    expect(pronto.b, closeTo(esperado.b, 1.5 / 255));
    expect(pronto.r, closeTo(esperado.r, 1.5 / 255));
    await avanzar(tester, 320);
    final medio = Recibimiento.cuadroActual(tester.element(_fondo())).fondo;
    expect(medio, isNot(const Color(0xFFE77330)));
    expect(medio, isNot(const Color(0xFFFF6600)));
    await avanzar(tester, 600);
    expect(
      Recibimiento.cuadroActual(tester.element(_fondo())).fondo,
      const Color(0xFFFF6600),
    );
    await avanzar(tester, 2000);
  });

  testWidgets('los toques no cuentan hasta que los botones empiezan a entrar, '
      'a los 2,32 s', (tester) async {
    final b = Bienvenida();
    await montarLaBienvenida(tester, b, argumentos: _conPose());
    await avanzar(tester, 2100);
    expect(find.text(TextosDeLaBienvenida.siEntrar), findsNothing);
    await tester.tapAt(const Offset(187.5, 556));
    await tester.pump();
    expect(b.delAlumno, isEmpty);
    // A los 2,29 s todavía no hay botones.
    await avanzar(tester, 176);
    expect(find.text(TextosDeLaBienvenida.siEntrar), findsNothing);
    await avanzar(tester, 124);
    await tester.tap(find.text(TextosDeLaBienvenida.siEntrar));
    await tester.pump();
    expect(b.delAlumno, [TextosDeLaBienvenida.siEntrar]);
    await avanzar(tester, 3000);
  });

  testWidgets('la tarjeta va desde 11 dp después de Ulises hasta 12 dp del '
      'borde, y los botones a 22 dp de los lados, 26 dp sobre el borde, con '
      '10 dp entre ellos y 50 dp de alto', (tester) async {
    await montarLaBienvenida(tester, Bienvenida(), argumentos: _conPose());
    await avanzar(tester, 3000);
    final ulises = tester.getRect(_ulises());
    final tarjeta = tester.getRect(find.byKey(Recibimiento.claveDeLaTarjeta));
    expect(tarjeta.left - (187.5 - 104 + 35), closeTo(11, 0.5));
    expect(tarjeta.right, closeTo(375 - 12, 0.5));
    expect(tarjeta.top, closeTo(ulises.center.dy - 22, 3));
    final si = tester.getRect(
      find.ancestor(
        of: find.text(TextosDeLaBienvenida.siEntrar),
        matching: find.byType(InkWell),
      ),
    );
    final nuevo = tester.getRect(
      find.ancestor(
        of: find.text(TextosDeLaBienvenida.soyNuevo),
        matching: find.byType(InkWell),
      ),
    );
    expect(si.left, 22);
    expect(si.right, 375 - 22);
    expect(si.height, 50);
    expect(nuevo.top - si.bottom, 10);
    expect(nuevo.bottom, 667 - 26);
  });

  for (final escala in [1.3, 2.0]) {
    testWidgets('con el texto a $escala, Ulises salta al avatar real del '
        'primer grupo y la subida llega a la franja real (RF-BIEN-2, '
        'RF-BIEN-4 y RF-BIEN-16)', (tester) async {
      await montarLaBienvenida(
        tester,
        Bienvenida(),
        argumentos: _conPose(),
        escala: escala,
      );
      await avanzar(tester, 3000);
      await tester.tap(find.text(TextosDeLaBienvenida.siEntrar));
      // La burbuja ya terminó de entrar y Ulises todavía no se posa.
      await avanzar(tester, 500);
      final recibimiento = tester.widget<Recibimiento>(
        find.byType(Recibimiento),
      );
      final avatar = tester.getRect(find.byType(UlisesAvatar).first);
      expect(recibimiento.avatar.center.dx, closeTo(avatar.center.dx, 0.5));
      expect(recibimiento.avatar.center.dy, closeTo(avatar.center.dy, 0.5));
      expect(recibimiento.avatar.width, avatar.width);
      // Al final de la subida el fondo es la franja, con su alto real.
      await avanzar(tester, 450);
      final cuadro = Recibimiento.cuadroActual(tester.element(_fondo()));
      final franja = tester.getRect(find.byType(CabeceraConSello));
      expect(
        cuadro.areaDelFondo?.height ?? franja.height,
        closeTo(franja.height, 0.5),
      );
      await avanzar(tester, 2000);
    });
  }

  for (final escala in [1.0, 1.3, 2.0]) {
    for (final sinMovimiento in [false, true]) {
      testWidgets('con lector${sinMovimiento ? ' y sin movimiento' : ''} y el '
          'texto a $escala, la tarjeta nunca tapa la estrella, que queda '
          'entera, y Ulises y el fondo llegan (RF-BIEN-2, RF-BIEN-15 y '
          'RF-BIEN-16)', (tester) async {
        await montarLaBienvenida(
          tester,
          Bienvenida(),
          argumentos: _conPose(),
          escala: escala,
          conLector: true,
          sinMovimiento: sinMovimiento,
        );
        // En cada cuadro, la estrella a la vista queda fuera de la tarjeta.
        for (var t = 0; t < 3000; t += 16) {
          await tester.pump(const Duration(milliseconds: 16));
          final tarjeta = find.byKey(Recibimiento.claveDeLaTarjeta);
          if (tarjeta.evaluate().isEmpty) continue;
          final cuadro = Recibimiento.cuadroActual(tester.element(_fondo()));
          // La de encima. Con el cruce, la del centro sigue debajo.
          final estrella = cuadro.estrella!.pose;
          expect(
            tester.getRect(tarjeta).top,
            greaterThanOrEqualTo(estrella.centro.dy + estrella.radio - 0.5),
            reason: 'a los $t ms la tarjeta pisa la estrella a la vista',
          );
        }
        final cuadro = Recibimiento.cuadroActual(tester.element(_fondo()));
        expect(cuadro.estrellaDebajo, isNull, reason: 'el cruce terminó');
        expect(cuadro.opacidadDeLaEstrella, 1);
        final estrella = Recibimiento.estrellaActual(tester.element(_fondo()));
        final tarjeta = tester.getRect(
          find.byKey(Recibimiento.claveDeLaTarjeta),
        );
        expect(
          tarjeta.top,
          greaterThanOrEqualTo(estrella.centro.dy + estrella.radio + 12 - 0.5),
        );
        // Ulises llegó a su lugar y el fondo ya es el de la franja.
        expect(_ulises(), findsOneWidget);
        expect(cuadro.fondo, const Color(0xFFFF6600));
      });
    }
  }

  for (final escala in [1.0, 1.3, 2.0]) {
    testWidgets('en 375 × 667 con el texto a $escala, nada entra en el margen '
        'de la estrella ni queda a menos de 16 dp de los botones', (
      tester,
    ) async {
      await montarLaBienvenida(
        tester,
        Bienvenida(),
        argumentos: _conPose(),
        escala: escala,
      );
      await avanzar(tester, 3000);
      final estrella = Recibimiento.estrellaActual(tester.element(_fondo()));
      final tarjeta = tester.getRect(find.byKey(Recibimiento.claveDeLaTarjeta));
      final botones = tester.getRect(
        find.byKey(Recibimiento.claveDeLosBotones),
      );
      final ulises = tester.getRect(_ulises());
      // El margen libre es de 12 dp alrededor del círculo de la estrella, y
      // Ulises va recortado en círculo, así que se miden como círculos.
      final libre = estrella.radio + 12;
      expect(
        tarjeta.top,
        greaterThanOrEqualTo(estrella.centro.dy + libre - 0.5),
      );
      expect(
        (ulises.center - estrella.centro).distance,
        greaterThanOrEqualTo(libre + ulises.width / 2 - 1),
      );
      expect(botones.top - tarjeta.bottom, greaterThanOrEqualTo(16 - 0.5));
      expect(botones.top - ulises.bottom, greaterThanOrEqualTo(16 - 1));
      expect(botones.bottom, 667 - 26);
      // Nada tapa la estrella: sus puntas quedan dentro de la pantalla.
      expect(estrella.centro.dy - estrella.radio, greaterThanOrEqualTo(24));
      if (escala == 1.0) {
        expect(estrella.centro.dy, 333.5, reason: 'con 1,0 no se mueve');
        expect(estrella.radio, 90);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('si ni achicando la estrella caben, Ulises saluda ya en la '
      'conversación con las dos respuestas rápidas (B-28)', (tester) async {
    final b = Bienvenida();
    await montarLaBienvenida(
      tester,
      b,
      pantalla: const Size(600, 360),
      escala: 1.3,
    );
    await avanzar(tester, 4500);
    expect(find.byType(Recibimiento), findsNothing);
    expect(find.text(TextosDeLaBienvenida.pregunta), findsOneWidget);
    expect(find.byType(RespuestaRapida), findsNWidgets(2));
    await tester.tap(find.text(TextosDeLaBienvenida.siEntrar));
    await tester.pump();
    expect(
      b.deUlises.where((t) => t == TextosDeLaBienvenida.saludo),
      hasLength(1),
    );
    expect(b.deUlises.last, TextosDeLaBienvenida.e1);
    await avanzar(tester, 3000);
  });

  testWidgets('al responder, el logo sube al sello, la conversación ya trae '
      'el primer grupo y E1 entra 650 ms después de que Ulises se posa', (
    tester,
  ) async {
    final b = Bienvenida();
    await montarLaBienvenida(tester, b, argumentos: _conPose());
    await avanzar(tester, 2800);
    await tester.tap(find.text(TextosDeLaBienvenida.siEntrar));
    double opacidadDelNombre() => tester
        .widget<AnimatedOpacity>(
          find
              .ancestor(
                of: find.text(TextosDeLaBienvenida.ulises),
                matching: find.byType(AnimatedOpacity),
              )
              .first,
        )
        .opacity;
    await avanzar(tester, 500);
    // Mientras Ulises salta, él es el avatar, y el nombre espera.
    expect(opacidadDelNombre(), 0);
    await avanzar(tester, 600);
    expect(opacidadDelNombre(), 1);
    expect(find.byType(Recibimiento), findsNothing);
    expect(find.byType(SelloDelLogo), findsOneWidget);
    expect(find.text(TextosDeLaBienvenida.saludo), findsOneWidget);
    expect(find.text(TextosDeLaBienvenida.pregunta), findsOneWidget);
    expect(find.text(TextosDeLaBienvenida.ulises), findsOneWidget);
    expect(find.text(TextosDeLaBienvenida.e1), findsNothing);
    // Ulises se posa a los 1030 ms del toque, así que E1 entra a los 1680.
    await avanzar(tester, 500);
    expect(find.text(TextosDeLaBienvenida.e1), findsNothing);
    await avanzar(tester, 200);
    expect(find.text(TextosDeLaBienvenida.e1), findsOneWidget);
    expect(b.controlador.latidos.value, 1);
    await avanzar(tester, 1000);
  });

  testWidgets('en cada cuadro de la subida hay un logo a la vista, dibujado '
      'o el sello de la franja, y el sello late al posarse (RF-BIEN-4)', (
    tester,
  ) async {
    await montarLaBienvenida(tester, Bienvenida(), argumentos: _conPose());
    await avanzar(tester, 2800);
    await tester.tap(find.text(TextosDeLaBienvenida.siEntrar));
    await tester.pump();
    double opacidadDelSello() => tester
        .widget<Opacity>(
          find
              .ancestor(
                of: find.byType(SelloDelLogo),
                matching: find.byType(Opacity),
              )
              .first,
        )
        .opacity;
    var latioAlPosarse = false;
    var reveladoMaximo = 0.0;
    while (find.byType(Recibimiento).evaluate().isNotEmpty) {
      final cuadro = Recibimiento.cuadroActual(tester.element(_fondo()));
      final dibujado = cuadro.estrella != null;
      final real = opacidadDelSello() == 1 && cuadro.fondo == null;
      expect(dibujado || real, isTrue, reason: 'nunca un cuadro sin logo');
      if (dibujado) {
        // Los «++» nunca se pierden: van con la estrella o viajan solos.
        expect(
          cuadro.estrella!.cruces.length + cuadro.crucesDeLaSubida,
          greaterThanOrEqualTo(2),
          reason: 'nunca un logo sin sus «++»',
        );
        reveladoMaximo = math.max(reveladoMaximo, cuadro.reveladoDeUlima);
      }
      if (real) {
        final sello = tester.widget<SelloDelLogo>(find.byType(SelloDelLogo));
        latioAlPosarse |= sello.latido!.value > 0 && sello.latido!.value < 1;
      }
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(opacidadDelSello(), 1);
    expect(latioAlPosarse, isTrue);
    expect(reveladoMaximo, greaterThan(0.95), reason: '«ULIMA» se revela');
  });

  testWidgets('sin argumentos, el recibimiento corto arranca con el logo en su '
      'pose de reposo en el centro de la pantalla física (RF-BIEN-3)', (
    tester,
  ) async {
    await montarLaBienvenida(tester, Bienvenida());
    final cuadro = Recibimiento.cuadroActual(tester.element(_fondo()));
    expect(cuadro.fondo, const Color(0xFFE77330));
    expect(cuadro.estrella!.pose.centro, const Offset(187.5, 333.5));
    expect(cuadro.estrella!.pose.radio, 90);
    expect(cuadro.estrella!.cruces, hasLength(2));
    await avanzar(tester, 3000);
  });

  testWidgets('con un motivo no hay recibimiento y el sello está entero desde '
      'el primer cuadro', (tester) async {
    await montarLaBienvenida(
      tester,
      Bienvenida(),
      argumentos: const {argumentoDeMotivo: MotivoDeLlegada.restablecida},
    );
    expect(find.byType(Recibimiento), findsNothing);
    expect(find.byType(SelloDelLogo), findsOneWidget);
    await avanzar(tester, 1500);
    expect(find.byType(BotonDeEnvio), findsOneWidget);
  });
}
