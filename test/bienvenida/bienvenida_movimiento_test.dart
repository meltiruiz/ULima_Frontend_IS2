// test/bienvenida/bienvenida_movimiento_test.dart
//
// WIDGET · Bienvenida con Ulises (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-15. Con reducir movimiento nada se mueve, gira ni cambia de escala,
// y cada cambio del logo es un fundido cruzado que deja siempre un logo a la
// vista. Las pausas del ritmo se quedan.
// Archivos probados lib/pages/bienvenida/widgets/recibimiento.dart y
// lib/pages/bienvenida/bienvenida_page.dart.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/logo/escena_del_logo.dart';
import 'package:ulima_plus/components/logo/sello_del_logo.dart';
import 'package:ulima_plus/components/skeleton.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/domain/bienvenida/bienvenida_turnos.dart';
import 'package:ulima_plus/models/registro_models.dart';
import 'package:ulima_plus/pages/bienvenida/bienvenida_page.dart';
import 'package:ulima_plus/pages/bienvenida/conversacion.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/burbujas.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/compositor.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/franja_con_sello.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/recibimiento.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/ulises_bubble.dart';
import 'package:ulima_plus/services/session_navigation.dart';

import 'apoyo_bienvenida.dart';

Map<String, Object> _conPose() => <String, Object>{
  argumentoDePose: EscenaDelLogo.reposo(
    centro: const Offset(187.5, 333.5),
    radio: 90,
  ).pose,
};

const _expirada = <String, Object>{argumentoDeMotivo: MotivoDeLlegada.expirada};

Finder _ulises() => find.byKey(Recibimiento.claveDeUlises);

double _opacidadDeUlises(WidgetTester tester) => tester
    .widget<Opacity>(
      find.ancestor(of: _ulises(), matching: find.byType(Opacity)).first,
    )
    .opacity;

({
  Color? fondo,
  Rect? areaDelFondo,
  EscenaDelLogo? estrella,
  EscenaDelLogo? estrellaDebajo,
  double opacidadDeLaEstrella,
  int puntos,
  int crucesDeLaSubida,
  double reveladoDeUlima,
})
_cuadro(WidgetTester tester) => Recibimiento.cuadroActual(
  tester.element(find.byKey(Recibimiento.claveDelFondo)),
);

void main() {
  // Las posiciones de la maqueta se miden con Roboto, como en la app.
  setUpAll(cargarRoboto);
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  testWidgets('Ulises no vuela: aparece en su lugar con un fundido de 160 ms, '
      '120 ms después del relevo, sin sombra, estela ni partículas', (
    tester,
  ) async {
    await montarLaBienvenida(
      tester,
      Bienvenida(),
      argumentos: _conPose(),
      sinMovimiento: true,
    );
    await avanzar(tester, 112);
    expect(_ulises(), findsNothing);
    await tester.pump(const Duration(milliseconds: 16));
    expect(_ulises(), findsOneWidget, reason: 'a los 128 ms ya aparece');
    await tester.pump(const Duration(milliseconds: 72));
    // A los 200 ms va por la mitad de su fundido de 160 ms, en su lugar.
    expect(tester.getSize(_ulises()).width, 70);
    expect(_opacidadDeUlises(tester), closeTo(0.5, 0.02));
    final ulises = tester.getRect(_ulises());
    expect(ulises.center.dx, closeTo(187.5 - 104, 1));
    expect(ulises.center.dy, closeTo(333.5 + 138, 1));
    // El fondo cambia en 150 ms desde los 120.
    final fondo = _cuadro(tester).fondo!;
    final esperado = Color.lerp(
      const Color(0xFFE77330),
      const Color(0xFFFF6600),
      80 / 150,
    )!;
    expect(fondo.b, closeTo(esperado.b, 1.5 / 255));
    expect(_cuadro(tester).puntos, 0);
    await avanzar(tester, 150);
    expect(_opacidadDeUlises(tester), 1);
    expect(_cuadro(tester).fondo, const Color(0xFFFF6600));
    // Ni al aterrizar hay partículas.
    await avanzar(tester, 1300);
    expect(_cuadro(tester).puntos, 0);
    expect(tester.getRect(_ulises()), ulises);
  });

  testWidgets('la tarjeta y los botones aparecen con fundidos de 180 ms, sin '
      'desplazamiento, y los toques cuentan desde los botones', (tester) async {
    final b = Bienvenida();
    await montarLaBienvenida(
      tester,
      b,
      argumentos: _conPose(),
      sinMovimiento: true,
    );
    double opacidadDe(Key clave) => tester
        .widget<Opacity>(
          find
              .ancestor(of: find.byKey(clave), matching: find.byType(Opacity))
              .first,
        )
        .opacity;
    await avanzar(tester, 360);
    final escala = tester.widget<Transform>(
      find
          .ancestor(
            of: find.byKey(Recibimiento.claveDeLaTarjeta),
            matching: find.byType(Transform),
          )
          .first,
    );
    expect(escala.transform, Matrix4.identity());
    // A los 368 ms la tarjeta va por la mitad de su fundido de 180 ms.
    expect(
      opacidadDe(Recibimiento.claveDeLaTarjeta),
      closeTo((368 - 280) / 180, 0.02),
    );
    final tarjeta = tester.getRect(find.byKey(Recibimiento.claveDeLaTarjeta));
    await avanzar(tester, 400);
    expect(find.byKey(Recibimiento.claveDeLosBotones), findsOneWidget);
    expect(
      opacidadDe(Recibimiento.claveDeLosBotones),
      closeTo((768 - 660) / 180, 0.02),
    );
    expect(
      tester.getRect(find.byKey(Recibimiento.claveDeLaTarjeta)),
      tarjeta,
      reason: 'la tarjeta no se desplaza',
    );
    // Y se dibuja donde la pone su lugar, sin ningún corrimiento.
    final lugar = tester.getRect(
      find
          .ancestor(
            of: find.byKey(Recibimiento.claveDeLaTarjeta),
            matching: find.byType(IgnorePointer),
          )
          .first,
    );
    expect(tarjeta.top, lugar.top);
    expect(tarjeta.left, lugar.left);
    // A mitad de su fundido, los botones no se desplazan.
    final desplazamiento = tester.widget<Transform>(
      find
          .ancestor(
            of: find.byKey(Recibimiento.claveDeLosBotones),
            matching: find.byType(Transform),
          )
          .first,
    );
    expect(desplazamiento.transform, Matrix4.identity());
    await tester.tap(find.text(TextosDeLaBienvenida.siEntrar));
    await tester.pump();
    expect(b.delAlumno, [TextosDeLaBienvenida.siEntrar]);
    await avanzar(tester, 2000);
  });

  testWidgets('si RF-BIEN-2 sube la estrella, la nueva aparece encima en '
      '220 ms y la del centro sigue entera debajo hasta quedar cubierta', (
    tester,
  ) async {
    await montarLaBienvenida(
      tester,
      Bienvenida(),
      argumentos: _conPose(),
      sinMovimiento: true,
      escala: 2,
    );
    var cuadrosDelCruce = 0;
    for (var t = 0; t < 400; t += 16) {
      await tester.pump(const Duration(milliseconds: 16));
      final cuadro = _cuadro(tester);
      if (cuadro.estrellaDebajo == null) continue;
      cuadrosDelCruce++;
      expect(cuadro.estrellaDebajo!.pose.centro, const Offset(187.5, 333.5));
      expect(cuadro.estrellaDebajo!.pose.radio, 90);
      expect(cuadro.estrella!.pose.centro.dy, lessThan(333.5));
      expect(cuadro.opacidadDeLaEstrella, lessThan(1));
    }
    // 220 ms son unos 14 cuadros de 16 ms.
    expect(cuadrosDelCruce, inInclusiveRange(12, 15));
    expect(_cuadro(tester).estrellaDebajo, isNull);
    expect(_cuadro(tester).opacidadDeLaEstrella, 1);
  });

  testWidgets('con sesión, Ulises tampoco vuela y la estrella no se mueve', (
    tester,
  ) async {
    final b = Bienvenida(
      auth: AuthDeLaBienvenida(usuario: alumnaDePrueba(setupComplete: false)),
      token: 'jwt-de-prueba',
    );
    await montarLaBienvenida(
      tester,
      b,
      argumentos: _conPose(),
      sinMovimiento: true,
      escala: 2,
    );
    for (var t = 0; t < 600; t += 16) {
      await tester.pump(const Duration(milliseconds: 16));
      if (find.byType(Recibimiento).evaluate().isEmpty) break;
      final cuadro = _cuadro(tester);
      expect(cuadro.puntos, 0);
      expect(cuadro.estrellaDebajo, isNull);
      final estrella = Recibimiento.estrellaActual(
        tester.element(find.byKey(Recibimiento.claveDelFondo)),
      );
      expect(estrella.centro, const Offset(187.5, 333.5));
      if (_ulises().evaluate().isNotEmpty) {
        expect(tester.getSize(_ulises()).width, 70);
      }
    }
    await avanzar(tester, 3000);
    expect(
      find.text(TextosDeLaBienvenida.saludoConSesion, skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('si el token tarda 300 ms, el cruce de la estrella igual '
      'ocurre en 220 ms, con la del centro entera debajo (RF-BIEN-15)', (
    tester,
  ) async {
    await montarLaBienvenida(
      tester,
      Bienvenida(
        tokenGuardado: () => Future<String?>.delayed(
          const Duration(milliseconds: 300),
          () => null,
        ),
      ),
      argumentos: _conPose(),
      sinMovimiento: true,
      escala: 2,
    );
    var conCruce = false;
    for (var t = 0; t < 700; t += 16) {
      await tester.pump(const Duration(milliseconds: 16));
      final cuadro = _cuadro(tester);
      if (cuadro.estrellaDebajo != null) {
        conCruce = true;
        expect(cuadro.estrellaDebajo!.pose.radio, 90);
      }
    }
    expect(conCruce, isTrue, reason: 'la estrella no salta');
    expect(_cuadro(tester).opacidadDeLaEstrella, 1);
    await avanzar(tester, 1000);
  });

  testWidgets('en la subida sin movimiento, cada cuadro tiene un logo a '
      'opacidad plena, también si el toque llega pronto', (tester) async {
    await montarLaBienvenida(
      tester,
      Bienvenida(),
      argumentos: _conPose(),
      sinMovimiento: true,
    );
    await avanzar(tester, 700);
    await tester.tap(find.text(TextosDeLaBienvenida.siEntrar));
    double conversacion() => tester
        .widget<FadeTransition>(
          find
              .ancestor(
                of: find.byType(FranjaConSello),
                matching: find.byType(FadeTransition),
              )
              .first,
        )
        .opacity
        .value;
    for (var t = 0; t < 600; t += 16) {
      await tester.pump(const Duration(milliseconds: 16));
      final conRecibimiento = find.byType(Recibimiento).evaluate().isNotEmpty;
      expect(
        conRecibimiento || conversacion() == 1,
        isTrue,
        reason: 'a los $t ms no hay logo a opacidad plena',
      );
    }
  });

  testWidgets('al responder, la franja con el sello y la conversación '
      'aparecen encima en 220 ms mientras el recibimiento sigue entero '
      'debajo, y Ulises pasa a su avatar en 140 ms', (tester) async {
    await montarLaBienvenida(
      tester,
      Bienvenida(),
      argumentos: _conPose(),
      sinMovimiento: true,
    );
    await avanzar(tester, 900);
    await tester.tap(find.text(TextosDeLaBienvenida.siEntrar));
    await avanzar(tester, 100);
    expect(find.byType(Recibimiento), findsOneWidget);
    // La conversación va encima del recibimiento.
    final pila = tester.widget<Stack>(
      find
          .ancestor(
            of: find.byKey(const ValueKey<String>('conversacion')),
            matching: find.byType(Stack),
          )
          .first,
    );
    final claves = pila.children.map((w) => w.key).toList();
    expect(
      claves.indexOf(const ValueKey<String>('recibimiento')),
      lessThan(claves.indexOf(const ValueKey<String>('conversacion'))),
    );
    // El sello y el avatar se ven enteros en lo que aparece encima.
    expect(
      tester
          .widget<Opacity>(
            find
                .ancestor(
                  of: find.byType(SelloDelLogo),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity,
      1,
    );
    expect(
      tester
          .widget<Opacity>(
            find
                .ancestor(
                  of: find.byType(UlisesAvatar).first,
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity,
      1,
    );
    final cuadro = _cuadro(tester);
    expect(cuadro.estrella!.pose.radio, 90, reason: 'entero debajo');
    expect(
      cuadro.areaDelFondo,
      Offset.zero & const Size(375, 667),
      reason: 'el fondo no se recoge',
    );
    final encima = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.byType(FranjaConSello),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    // Los dos cuentan desde el cuadro que sigue al toque: 96 ms de 220 y de
    // 140.
    expect(encima.opacity.value, closeTo(96 / 220, 0.05));
    expect(_opacidadDeUlises(tester), closeTo(1 - 96 / 140, 0.05));
    await avanzar(tester, 200);
    expect(find.byType(Recibimiento), findsNothing);
    expect(find.byType(SelloDelLogo), findsOneWidget);
  });

  testWidgets('el sello no late, no hay pulso y la píldora queda quieta', (
    tester,
  ) async {
    final pendiente = Completer<RegistroResult>();
    final b = Bienvenida(registro: RegistroFalso(pendiente: pendiente));
    await montarLaBienvenida(
      tester,
      b,
      argumentos: _expirada,
      sinMovimiento: true,
    );
    await avanzar(tester, 1500);
    final sello = tester.widget<SelloDelLogo>(find.byType(SelloDelLogo));
    await tester.enterText(find.byType(TextField).first, '20230001');
    // Un cuadro tras teclear, para que el botón de envío se encienda.
    await tester.pump();
    await tester.tap(find.byType(BotonDeEnvio));
    await avanzar(tester, 200);
    expect(sello.latido!.value, 0);
    final c = b.controlador..soyNuevo();
    c.registro!.codigoCtrl.text = '20230001';
    c.enviarCodigoDeAlumno();
    c.registro!
      ..passwordCtrl.text = 'Contrasena1'
      ..confirmacionCtrl.text = 'Contrasena1';
    c.enviarContrasenas();
    c.aceptarConsentimiento();
    c.registro!.portalPasswordCtrl.text = 'clave-de-prueba';
    c.enviarPortal();
    c.registro!.passcodeCtrl.text = '123456';
    unawaited(c.crearCuenta());
    await avanzar(tester, 300);
    expect(sello.rombos!.value, isNull);
    final indicador = tester.widget<CircularProgressIndicator>(
      find.descendant(
        of: find.byType(PildoraDelRegistro),
        matching: find.byType(CircularProgressIndicator),
      ),
    );
    expect(indicador.value, isNotNull);
    pendiente.completeError(
      const RegistroFailure(
        'No hay conexión. Revisa tu internet e inténtalo de nuevo.',
        code: 'SIN_CONEXION',
      ),
    );
    await avanzar(tester, 3000);
  });

  testWidgets('el cursor del campo no parpadea mientras la bienvenida está '
      'montada, y vuelve a como estaba al salir', (tester) async {
    await montarLaBienvenida(
      tester,
      Bienvenida(),
      argumentos: _expirada,
      sinMovimiento: true,
    );
    await avanzar(tester, 1500);
    expect(EditableText.debugDeterministicCursor, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(EditableText.debugDeterministicCursor, isFalse);
  });

  testWidgets('con movimiento, el cursor parpadea como siempre', (
    tester,
  ) async {
    await montarLaBienvenida(tester, Bienvenida(), argumentos: _expirada);
    await avanzar(tester, 1500);
    expect(EditableText.debugDeterministicCursor, isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(EditableText.debugDeterministicCursor, isFalse);
  });

  testWidgets('con dos bienvenidas a la vez, como al volver del «¿Olvidaste '
      'tu contraseña?», el cursor sigue quieto en la nueva y vuelve a como '
      'estaba al salir de las dos (RF-BIEN-15)', (tester) async {
    await montarLaBienvenida(
      tester,
      Bienvenida(),
      argumentos: _expirada,
      sinMovimiento: true,
    );
    await avanzar(tester, 1500);
    unawaited(Get.toNamed<void>('/forgot-password'));
    await avanzar(tester, 600);
    // La vuelta monta otra bienvenida mientras la anterior sale.
    expect(offAllToLogin(motivo: MotivoDeLlegada.restablecida), isTrue);
    await tester.pump();
    expect(EditableText.debugDeterministicCursor, isTrue);
    await avanzar(tester, 1500);
    expect(find.byType(BienvenidaPage), findsOneWidget);
    expect(EditableText.debugDeterministicCursor, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(EditableText.debugDeterministicCursor, isFalse);
  });

  for (final quieto in [true, false]) {
    testWidgets('${quieto ? 'sin' : 'con'} movimiento, los indicadores de '
        'espera ${quieto ? 'quedan quietos' : 'giran'} y la burbuja de carga '
        '${quieto ? 'no' : 'sí'} pulsa (RF-BIEN-15 y RF-TEST-13)', (
      tester,
    ) async {
      const tema = MaterialTheme(TextTheme());
      Widget burbuja(TipoDeBurbuja tipo) => EntradaView(
        entrada: BurbujaDeUlises(
          id: tipo.index,
          texto: 'Un momento',
          tipo: tipo,
        ),
        anterior: null,
        primerGrupo: false,
        conMovimiento: !quieto,
        resultado: (_, _) => const SizedBox.shrink(),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: tema.light(),
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: quieto),
            child: Scaffold(
              body: ListView(
                children: [
                  BotonPrincipal(
                    texto: TextosDeLaBienvenida.entrar,
                    esperando: true,
                    alTocar: () {},
                  ),
                  RespuestaRapida(
                    texto: TextosDeLaBienvenida.iniciarSesion,
                    esperando: true,
                    alTocar: () {},
                  ),
                  burbuja(TipoDeBurbuja.esperando),
                  burbuja(TipoDeBurbuja.cargando),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      final indicadores = tester.widgetList<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicadores, hasLength(3));
      for (final i in indicadores) {
        expect(i.value, quieto ? isNotNull : isNull);
      }
      expect(find.byType(SkeletonBox), findsOneWidget);
      expect(
        find.byType(SkeletonPulse),
        quieto ? findsNothing : findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
