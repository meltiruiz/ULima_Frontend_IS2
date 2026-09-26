// test/splash/splash_incremento_test.dart
//
// UNITARIA · Splash animado (specs/features/splash/splash.spec.md).
// RF-SPL-8 fija la entrada de Incremento, RF-SPL-10 sus tics de espera y la
// salida que absorbe el tic en curso, y RF-SPL-21 su vuelta al reposo, que
// termina el tic en curso a lo sumo 700 ms después de su inicio (S-34).
// Archivo probado lib/pages/splash/variantes/incremento.dart.

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/components/logo/escena_del_logo.dart';
import 'package:ulima_plus/components/logo/logo_geometria.dart';
import 'package:ulima_plus/pages/splash/variantes/incremento.dart';
import 'package:ulima_plus/pages/splash/variantes/variante_de_intro.dart';
import 'package:ulima_plus/services/splash_variante_service.dart';

const _centro = Offset(187.5, 333.5);
const _v = Incremento();

EscenaDelLogo _en(double ms, {double? cargaLista}) =>
    _v.escena(ms, centro: _centro, radio: 90, cargaLista: cargaLista);

void main() {
  group('Incremento, la entrada (RF-SPL-8)', () {
    test('es la variante incremento, entra en 1150 ms y sale en 620 ms', () {
      expect(_v.tipo, VarianteSplash.incremento);
      expect(_v.finDeLaEntrada, 1150);
      expect(_v.duracionDeLaSalida, 620);
      expect(_v.finDeLaEntrada + _v.duracionDeLaSalida, 1770);
    });

    test('arranca igual al nativo, sin giro ni «++»', () {
      final e = _en(0);
      expect(e.giro, 0);
      expect(e.corrimiento, Offset.zero);
      expect(e.cruces, isEmpty);
    });

    test('la estrella gira 45° con el resorte a los 500 ms', () {
      expect(_en(500).giro, closeTo(45 * grado, 1.5 * grado));
      expect(_en(1150).giro, closeTo(45 * grado, 1e-9));
    });

    test('el latido saca los rombos 24 u y baja la estrella central a 95 % '
        'en el primer 32 %', () {
      final pico = _en(180 + 0.32 * 380);
      expect(pico.rombos.first.desplazamiento, closeTo(24, 1e-6));
      expect(pico.escalaCentral, closeTo(0.95, 1e-6));
      expect(_en(560).rombos.first.desplazamiento, closeTo(0, 1e-6));
    });

    test('la onda va de 250 u a 540 u entre 230 y 790 ms', () {
      final onda = _en(230).anillos.single;
      expect(onda.radio, closeTo(250, 1e-6));
      expect(onda.trazo, closeTo(13.5, 1e-6));
      expect(onda.opacidad, closeTo(0.42, 1e-6));
      expect(_en(790).anillos, isEmpty);
    });

    test('el primer «+» sale de detrás de la estrella, de x = 190 u a su '
        'lugar, y solo se ve a la derecha de x = 236 u hasta los 920 ms', () {
      final nace = _en(480).cruces.single;
      expect(nace.centro.dx, closeTo(190, 1e-6));
      expect(nace.escala, closeTo(0.72, 1e-6));
      expect(_en(600).recorteDeCruces, 236);
      final llega = _en(920).cruces.first;
      expect(llega.centro.dx, closeTo(LogoGeometria.centrosDeCruz[0].dx, 1e-6));
      expect(llega.escala, closeTo(1, 1e-6));
      expect(_en(920).recorteDeCruces, isNull);
    });

    test('el segundo «+» nace del primero y se corre 94 u, como i++', () {
      expect(_en(699).cruces, hasLength(1));
      final nace = _en(700).cruces[1];
      expect(nace.centro.dx, closeTo(LogoGeometria.centrosDeCruz[0].dx, 1e-6));
      expect(nace.escala, closeTo(0.8, 1e-6));
      final llega = _en(1120).cruces[1];
      expect(llega.centro.dx, closeTo(LogoGeometria.centrosDeCruz[1].dx, 1e-6));
      expect(
        LogoGeometria.centrosDeCruz[1].dx - LogoGeometria.centrosDeCruz[0].dx,
        closeTo(94, 0.5),
      );
    });

    test('todo el conjunto se corre −36 u entre 480 y 1060 ms', () {
      expect(_en(480).corrimiento, Offset.zero);
      expect(_en(1060).corrimiento.dx, closeTo(-36, 1e-6));
    });

    test('a los 1150 ms queda el logo completo, corrido y con sus «++»', () {
      final e = _en(1150);
      expect(e.corrimiento.dx, closeTo(-36, 1e-6));
      expect(e.rombos.every((r) => r.desplazamiento == 0), isTrue);
      for (var i = 0; i < 2; i++) {
        expect(e.cruces[i].centro, LogoGeometria.centrosDeCruz[i]);
        expect(e.cruces[i].escala, closeTo(1, 1e-6));
      }
      // La pose sigue al conjunto corrido (RF-SPL-21).
      expect(e.pose.centro.dx, closeTo(187.5 - 36 * 90 / 354.8, 1e-9));
    });
  });

  group('Incremento, los tics y el reposo (RF-SPL-10 y RF-SPL-21)', () {
    test('desde 1400 ms hay un tic de 45° cada 1300 ms', () {
      expect(_en(1399).giro, closeTo(45 * grado, 1e-9));
      expect(_en(2100).giro, closeTo(90 * grado, 0.5 * grado));
      expect(_en(2700).giro, closeTo(90 * grado, 0.1 * grado));
      expect(_en(3400).giro, closeTo(135 * grado, 0.5 * grado));
    });

    test('con cada tic los rombos laten 8 u y cada «+» asiente un 14 %', () {
      expect(_en(1400 + 210).rombos.first.desplazamiento, closeTo(8, 1e-6));
      expect(_en(1400 + 60 + 160).cruces[0].escala, closeTo(1.14, 1e-6));
      expect(_en(1400 + 170 + 160).cruces[1].escala, closeTo(1.14, 1e-6));
      expect(_en(1400 + 500).rombos.first.desplazamiento, closeTo(0, 1e-6));
    });

    test('con la carga lista antes de 1150 ms no hay tics', () {
      expect(_en(1700, cargaLista: 900).giro, closeTo(45 * grado, 1e-9));
      expect(_v.finDelReposo(900), 1150);
    });

    test('hacia la bienvenida termina el tic en curso, a lo sumo 700 ms '
        'desde su inicio', () {
      expect(_v.finDelReposo(1500), 2100);
      expect(_v.finDelReposo(2200), 2200);
      expect(_v.finDelReposo(1300), 1300);
      final reposo = _en(2100, cargaLista: 1500);
      expect(reposo.giro, closeTo(90 * grado, 1e-9));
      expect(reposo.rombos.every((r) => r.desplazamiento == 0), isTrue);
      // Ningún tic nuevo empieza después de la carga.
      expect(_en(2800, cargaLista: 1500).giro, closeTo(90 * grado, 1e-9));
    });

    test('la salida absorbe el tic en curso y termina 45° más allá de su '
        'destino', () {
      expect(_v.giroAlSalir(1500), greaterThan(45 * grado));
      expect(_v.giroAlSalir(1500), lessThan(90 * grado));
      expect(_v.destinoDelGiro(1500), closeTo(90 * grado, 1e-9));
      expect(_v.destinoDelGiro(1200), closeTo(45 * grado, 1e-9));
    });

    test('en la salida, el latido y el asentimiento se apagan en 150 ms', () {
      final inicio = _v.alSalir(1610, 0, centro: _centro, radio: 90);
      expect(inicio.rombos.first.desplazamiento, closeTo(8, 1e-6));
      final apagado = _v.alSalir(1610, 150, centro: _centro, radio: 90);
      expect(apagado.rombos.every((r) => r.desplazamiento == 0), isTrue);
      expect(apagado.cruces.every((c) => (c.escala - 1).abs() < 1e-9), isTrue);
    });
  });
}
