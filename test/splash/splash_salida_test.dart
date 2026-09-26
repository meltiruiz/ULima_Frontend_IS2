// test/splash/splash_salida_test.dart
//
// UNITARIA + WIDGET · Splash animado (specs/features/splash/splash.spec.md).
// RF-SPL-11 fija la salida hacia /home de cada variante, con el panel que se
// recoge hasta la cabecera, la estrella que vuela a la estrella de la
// cabecera y los «++» que terminan sobre los del texto, y RF-SPL-13 el color
// del panel en cada tema.
// Archivos probados lib/pages/splash/salidas.dart y, desde la Tarea 13,
// lib/pages/splash/capa_de_arranque.dart.

import 'dart:math' as math;
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/logo/escena_del_logo.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/pages/splash/capa_de_arranque.dart';
import 'package:ulima_plus/pages/splash/puntos_de_aterrizaje.dart';
import 'package:ulima_plus/pages/splash/salidas.dart';
import 'package:ulima_plus/pages/splash/variantes/codigo.dart';
import 'package:ulima_plus/pages/splash/variantes/ensamble.dart';
import 'package:ulima_plus/pages/splash/variantes/incremento.dart';
import 'package:ulima_plus/pages/splash/variantes/variante_de_intro.dart';
import 'package:ulima_plus/services/splash_variante_service.dart';

import 'apoyo_splash.dart';

const _pantalla = Size(375, 667);
const _centro = Offset(187.5, 333.5);

/// Una cabecera como la de la app en 375 × 667, medida a mano.
MedidaDeCabecera _medida({Color color = MaterialTheme.primaryColor}) =>
    MedidaDeCabecera(
      cabecera: const Rect.fromLTWH(0, 0, 375, 102),
      estrella: const Rect.fromLTWH(20, 52, 26, 26),
      texto: const Rect.fromLTWH(56, 55, 90, 20),
      estilo: const TextStyle(
        fontSize: 20,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      escalaDeTexto: TextScaler.noScaling,
      color: color,
      colorDelBorde: const Color(0xFF333333),
    );

EscenaDeSalida _salida(
  VarianteDeIntro v,
  double msEnSalida, {
  double? msInicio,
  MedidaDeCabecera? medida,
}) => salidaHaciaHome(
  variante: v,
  msInicio: msInicio ?? v.finDeLaEntrada,
  msEnSalida: msEnSalida,
  centroDelMarco: _centro,
  radioDelMarco: 90,
  destino: DestinoDeLaSalida.desdeMedida(medida ?? _medida(), _pantalla),
);

/// Comprueba que los «++» sueltan la estrella en [msDeSuelta] y llegan a sus
/// glifos en [msDeLlegada]. En cada instante de [instantes], cada «+» va por
/// la recta que une el punto donde se soltó con su glifo, con el avance de
/// easeInOutCubic, y su distancia a la estrella ya no es la del comienzo
/// escalada con el radio de ella.
void _compruebaLaSuelta(
  VarianteDeIntro v, {
  required double msDeSuelta,
  required double msDeLlegada,
  required List<double> instantes,
}) {
  final d = DestinoDeLaSalida.desdeMedida(_medida(), _pantalla);
  final inicial = _salida(v, 0);
  final alSoltar = _salida(v, msDeSuelta);
  for (final ms in instantes) {
    final s = _salida(v, ms);
    final avance = Curves.easeInOutCubic.transform(
      (ms - msDeSuelta) / (msDeLlegada - msDeSuelta),
    );
    final factor = s.estrella.radio / inicial.estrella.radio;
    for (var i = 0; i < 2; i++) {
      final motivo = 'el «+» $i a los $ms ms';
      final esperado = Offset.lerp(
        alSoltar.cruces[i].centro,
        d.cruces[i],
        avance,
      )!;
      expect(s.cruces[i].centro.dx, closeTo(esperado.dx, 1e-6), reason: motivo);
      expect(s.cruces[i].centro.dy, closeTo(esperado.dy, 1e-6), reason: motivo);
      final pegado =
          s.estrella.centro +
          (inicial.cruces[i].centro - inicial.estrella.centro) * factor;
      expect(
        (s.cruces[i].centro - pegado).distance,
        greaterThan(1),
        reason: motivo,
      );
    }
  }
  final llegada = _salida(v, msDeLlegada);
  for (var i = 0; i < 2; i++) {
    expect(llegada.cruces[i].centro.dx, closeTo(d.cruces[i].dx, 1e-6));
    expect(llegada.cruces[i].centro.dy, closeTo(d.cruces[i].dy, 1e-6));
  }
}

void main() {
  group('las salidas como funciones puras (RF-SPL-11)', () {
    final variantes = <VarianteDeIntro>[
      const Ensamble(),
      const Incremento(),
      const Codigo(),
    ];

    test('el destino ubica «ULIMA» y los dos «+» del texto de la cabecera', () {
      final d = DestinoDeLaSalida.desdeMedida(_medida(), _pantalla);
      expect(d.anchosDeUlima, hasLength(6));
      expect(d.anchosDeUlima.first, 0);
      expect(d.cruces, hasLength(2));
      expect(d.cruces[0].dx, greaterThan(56 + d.anchosDeUlima.last - 1));
      expect(d.cruces[1].dx, greaterThan(d.cruces[0].dx));
      expect(d.tamanoDeCruz, greaterThan(0));
    });

    test('desechar libera los textos medidos del destino', () {
      final d = DestinoDeLaSalida.desdeMedida(_medida(), _pantalla);
      expect(d.pintorDeUlima.debugDisposed, isFalse);
      d.desechar();
      expect(d.pintorDeUlima.debugDisposed, isTrue);
      expect(d.pintorDeLosMas.debugDisposed, isTrue);
    });

    for (final v in variantes) {
      group(v.tipo.name, () {
        test('empieza con el panel en toda la pantalla y la estrella en su '
            'pose', () {
          final s = _salida(v, 0);
          expect(s.panel, Offset.zero & _pantalla);
          expect(s.colorDelPanel, naranjaDelSplash);
          final pose = v
              .escena(v.finDeLaEntrada, centro: _centro, radio: 90)
              .pose;
          expect(s.estrella.centro.dx, closeTo(pose.centro.dx, 1e-6));
          expect(s.estrella.centro.dy, closeTo(pose.centro.dy, 1e-6));
          expect(s.estrella.radio, closeTo(90, 1e-6));
          expect(s.paginaOpacidad, 0);
          expect(s.opacidadDelConjunto, 1);
        });

        test('termina con el panel en la cabecera, la estrella de 26 dp en la '
            'de la cabecera y los «++» sobre el texto', () {
          final s = _salida(v, v.duracionDeLaSalida);
          expect(s.panel, const Rect.fromLTRB(0, 0, 375, 102));
          expect(s.colorDelPanel, MaterialTheme.primaryColor);
          expect(s.estrella.centro, const Offset(33, 65));
          expect(s.estrella.radio, closeTo(13, 1e-6));
          final d = DestinoDeLaSalida.desdeMedida(_medida(), _pantalla);
          for (var i = 0; i < 2; i++) {
            expect(s.cruces[i].centro.dx, closeTo(d.cruces[i].dx, 1e-6));
            expect(s.cruces[i].centro.dy, closeTo(d.cruces[i].dy, 1e-6));
          }
          expect(s.opacidadDeLasCruces, 0);
          expect(s.opacidadDeLosMas, 1);
          expect(s.paginaDy, 0);
          expect(s.paginaOpacidad, 1);
          expect(s.opacidadDelConjunto, 0);
        });

        test('los «++» dibujados se funden con los del texto en el último '
            '25 %', () {
          expect(
            _salida(v, 0.75 * v.duracionDeLaSalida).opacidadDeLosMas,
            closeTo(0, 1e-9),
          );
          expect(
            _salida(v, 0.875 * v.duracionDeLaSalida).opacidadDeLosMas,
            closeTo(0.5, 1e-6),
          );
        });

        test('el panel se funde sobre la cabecera en los últimos 100 ms', () {
          final d = v.duracionDeLaSalida;
          expect(_salida(v, d - 100).opacidadDelConjunto, 1);
          expect(_salida(v, d - 50).opacidadDelConjunto, closeTo(0.5, 1e-6));
        });

        test('en oscuro el panel termina en el headerColor oscuro', () {
          final oscuro = MaterialTheme.headerColor(Brightness.dark);
          final s = _salida(
            v,
            v.duracionDeLaSalida,
            medida: _medida(color: oscuro),
          );
          expect(s.colorDelPanel, oscuro);
        });
      });
    }

    test(
      'A. el borde del panel se abomba unos 130 dp a mitad de la salida, '
      '«ULIMA» se revela desde el 68 % y el segundo «+» va un 4 % después',
      () {
        const v = Ensamble();
        expect(_salida(v, 265).combado, closeTo(130, 1e-6));
        expect(_salida(v, 0.68 * 530).reveladoDeUlima, closeTo(0, 1e-9));
        expect(_salida(v, 0.84 * 530).reveladoDeUlima, closeTo(0.5, 1e-6));
        // El segundo «+» sigue en su origen hasta el 4 % de la salida y
        // después avanza con la curva de (t − 0,04) / 0,96, que se lee en su
        // largo.
        final d = DestinoDeLaSalida.desdeMedida(_medida(), _pantalla);
        final inicio = _salida(v, 0);
        final alCuatro = _salida(v, 0.04 * 530);
        expect(
          alCuatro.cruces[1].centro.dx,
          closeTo(inicio.cruces[1].centro.dx, 1e-9),
        );
        expect(
          alCuatro.cruces[1].centro.dy,
          closeTo(inicio.cruces[1].centro.dy, 1e-9),
        );
        expect(alCuatro.cruces[1].largo, closeTo(inicio.cruces[1].largo, 1e-9));
        final mitad = _salida(v, 0.5 * 530);
        double avance(int i) =>
            (mitad.cruces[i].largo - inicio.cruces[i].largo) /
            (d.tamanoDeCruz - inicio.cruces[i].largo);
        expect(avance(0), closeTo(Curves.easeInOutCubic.transform(0.5), 1e-9));
        expect(
          avance(1),
          closeTo(Curves.easeInOutCubic.transform(0.46 / 0.96), 1e-9),
        );
        // Cada «+» se sesga con su propio avance hasta −12°.
        expect(mitad.cruces[1].sesgo, closeTo(-12 * grado * avance(1), 1e-9));
        expect(_salida(v, 530).cruces[0].sesgo, closeTo(-12 * grado, 1e-6));
        expect(_salida(v, 0.5 * 530).paginaDy, closeTo(10, 1e-6));
      },
    );

    test('B. las esquinas llegan a 75 dp, la estrella gira otros 45° más lo '
        'que falte del tic y los «++» se sueltan a los 150 ms y llegan a los '
        'glifos en 450 ms', () {
      const v = Incremento();
      expect(_salida(v, 310).radioInferior, closeTo(75, 1e-6));
      // Sin tic en curso, gira de 45° a 90°.
      expect(_salida(v, 0).estrella.giro, closeTo(45 * grado, 1e-9));
      expect(_salida(v, 620).estrella.giro, closeTo(90 * grado, 1e-9));
      // A mitad de un tic, termina 45° más allá de su destino.
      expect(
        _salida(v, 620, msInicio: 1500).estrella.giro,
        closeTo(135 * grado, 1e-9),
      );
      // Pegados a la estrella hasta los 150 ms.
      final pegados = _salida(v, 100);
      final rel0 = pegados.cruces[0].centro - pegados.estrella.centro;
      final rel1 = pegados.cruces[1].centro - pegados.estrella.centro;
      final inicial = _salida(v, 0);
      final relInicial = inicial.cruces[0].centro - inicial.estrella.centro;
      final factor = pegados.estrella.radio / inicial.estrella.radio;
      expect(rel0.dx, closeTo(relInicial.dx * factor, 1e-6));
      expect(rel1.dx, greaterThan(rel0.dx));
      // Desde los 150 ms cada «+» va del punto donde se soltó a su glifo, así
      // que su distancia a la estrella ya no escala con el radio de ella.
      _compruebaLaSuelta(
        v,
        msDeSuelta: 150,
        msDeLlegada: 600,
        instantes: const <double>[200, 375],
      );
      // Se sesgan como la cursiva desde que se sueltan, hasta −12°.
      expect(_salida(v, 150).cruces[0].sesgo, closeTo(0, 1e-12));
      expect(_salida(v, 620).cruces[1].sesgo, closeTo(-12 * grado, 1e-6));
      expect(_salida(v, 0.62 * 620).opacidadDeUlima, closeTo(0, 1e-9));
      expect(_salida(v, 0.95 * 620).opacidadDeUlima, closeTo(1, 1e-9));
      expect(_salida(v, 0).paginaDy, 32);
    });

    test('C. el panel va recto, «ULIMA» se teclea desde el 55 %, una letra '
        'cada 7 %, y los «++» se sueltan al 45 %', () {
      const v = Codigo();
      expect(_salida(v, 210).combado, 0);
      expect(_salida(v, 210).radioInferior, 0);
      expect(_salida(v, 0.54 * 420).letrasDeUlima, 0);
      expect(_salida(v, 0.56 * 420).letrasDeUlima, 1);
      expect(_salida(v, 0.70 * 420).letrasDeUlima, 3);
      expect(_salida(v, 0.90 * 420).letrasDeUlima, 5);
      final antes = _salida(v, 0.44 * 420);
      final rel = antes.cruces[0].centro - antes.estrella.centro;
      final inicial = _salida(v, 0);
      final relInicial = inicial.cruces[0].centro - inicial.estrella.centro;
      final factor = antes.estrella.radio / inicial.estrella.radio;
      expect(rel.dx, closeTo(relInicial.dx * factor, 1e-6));
      _compruebaLaSuelta(
        v,
        msDeSuelta: 0.45 * 420,
        msDeLlegada: 420,
        instantes: const <double>[0.5 * 420, 0.75 * 420],
      );
      expect(_salida(v, 420).cruces[1].sesgo, closeTo(-10 * grado, 1e-6));
      expect(_salida(v, 0.35 * 420).paginaOpacidad, closeTo(0, 1e-9));
      // El anillo de Código sigue en el centro de la pantalla.
      final restos = _salida(v, 40).restos;
      expect(restos.centro, _centro);
      expect(restos.anillos, isNotEmpty);
    });

    test('cada «+» dibujado se sesga hacia la derecha como la cursiva de '
        '«ULIMA++», sin girar su barra horizontal', () async {
      // Un «+» de 80 dp con −12° en el centro de un lienzo de 120 dp, sin
      // panel, estrella ni texto que lo tapen.
      const lado = 120;
      const lejos = EscenaDelLogo(centro: Offset(-500, -500), radio: 1);
      const escena = EscenaDeSalida(
        panel: Rect.zero,
        colorDelPanel: Color(0x00000000),
        combado: 0,
        radioInferior: 0,
        opacidadDelConjunto: 1,
        estrella: lejos,
        restos: lejos,
        cruces: <CruzDeSalida>[
          CruzDeSalida(centro: Offset(60, 60), largo: 80, sesgo: -12 * grado),
        ],
        opacidadDeLasCruces: 1,
        opacidadDeLosMas: 0,
        reveladoDeUlima: 0,
        opacidadDeUlima: 0,
        letrasDeUlima: 5,
        paginaDy: 0,
        paginaOpacidad: 1,
      );
      final grabadora = ui.PictureRecorder();
      pintarSalida(
        Canvas(grabadora),
        escena,
        DestinoDeLaSalida.desdeMedida(_medida(), _pantalla),
      );
      final imagen = await grabadora.endRecording().toImage(lado, lado);
      final bytes = (await imagen.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      bool pintado(int x, int y) =>
          bytes.getUint8(4 * (y * lado + x) + 3) > 127;
      double media(Iterable<int> valores) =>
          valores.reduce((a, b) => a + b) / valores.length;
      double centroDeFila(int y) => media([
        for (var x = 0; x < lado; x++)
          if (pintado(x, y)) x,
      ]);
      double centroDeColumna(int x) => media([
        for (var y = 0; y < lado; y++)
          if (pintado(x, y)) y,
      ]);
      // La barra vertical, lejos de la horizontal, tiene la punta de arriba
      // a la derecha de la de abajo, 70 dp × tan 12° en 70 filas.
      expect(
        centroDeFila(25) - centroDeFila(95),
        closeTo(70 * math.tan(12 * grado), 1),
      );
      // La barra horizontal sigue horizontal a los dos lados de la vertical.
      expect(centroDeColumna(28), closeTo(60, 0.75));
      expect(centroDeColumna(92), closeTo(60, 0.75));
    });
  });

  group('la salida en la capa (RF-SPL-11 y RF-SPL-13)', () {
    setUp(reiniciarArranque);
    tearDown(reiniciarArranque);

    for (final modo in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('la página sube y aparece como un todo sobre el fondo del '
          'tema, y el panel termina en el headerColor (${modo.name})', (
        tester,
      ) async {
        telefono(tester);
        final carga = CargaFalsa();
        await tester.pumpWidget(
          appConCapa(
            intro: IntroDelArranque(
              carga: carga.call,
              variantes: VariantesFijas(VarianteSplash.ensamble),
              random: Random(1),
            ),
            home: (_) => const HomeDePrueba(),
            modo: modo,
          ),
        );
        carga.terminar('/home');
        await avanzarHasta(
          tester,
          () => CapaDeArranque.fase == FaseDeLaCapa.salida,
        );
        await avanzar(tester, 265);
        final medio = CapaDeArranque.salidaActual!;
        expect(medio.paginaDy, inExclusiveRange(0, 20));
        final corrida = tester.widget<Transform>(
          find
              .ancestor(of: find.text('home'), matching: find.byType(Transform))
              .last,
        );
        expect(
          corrida.transform.getTranslation().y,
          closeTo(medio.paginaDy, 1e-6),
        );
        // La página aparece como un todo, con una sola opacidad.
        expect(medio.paginaOpacidad, inExclusiveRange(0, 1));
        final fundida = tester.widget<Opacity>(
          find
              .ancestor(of: find.text('home'), matching: find.byType(Opacity))
              .last,
        );
        expect(fundida.opacity, closeTo(medio.paginaOpacidad, 1e-6));
        // Detrás de la página va el fondo del tema, sin destello.
        final fondo = tester.widget<ColoredBox>(
          find
              .descendant(
                of: find.byType(CapaDeArranque),
                matching: find.byType(ColoredBox),
              )
              .first,
        );
        expect(
          fondo.color,
          Theme.of(tester.element(find.text('home'))).colorScheme.surface,
        );
        await avanzar(tester, 250);
        final ultimo = CapaDeArranque.salidaActual;
        final esperado = modo == ThemeMode.dark
            ? const Color.fromARGB(255, 30, 30, 36)
            : const Color(0xFFFF6600);
        expect(ultimo, isNotNull, reason: 'la salida sigue a los 515 ms');
        expect(ultimo!.colorDelPanel.r, closeTo(esperado.r, 0.02));
        expect(ultimo.colorDelPanel.g, closeTo(esperado.g, 0.02));
        expect(ultimo.colorDelPanel.b, closeTo(esperado.b, 0.02));
        await avanzarHasta(
          tester,
          () => CapaDeArranque.fase == FaseDeLaCapa.inactiva,
        );
        expect(Get.currentRoute, '/home');
      });
    }
  });
}
