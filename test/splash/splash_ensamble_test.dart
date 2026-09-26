// test/splash/splash_ensamble_test.dart
//
// UNITARIA · Splash animado (specs/features/splash/splash.spec.md).
// RF-SPL-7 fija la entrada de Ensamble fila por fila, RF-SPL-10 su onda de
// espera y RF-SPL-21 su vuelta al reposo antes del relevo (S-34). RF-SPL-17
// fija la duración de 1250 + 530 ms.
// Archivo probado lib/pages/splash/variantes/ensamble.dart.

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/components/logo/escena_del_logo.dart';
import 'package:ulima_plus/components/logo/logo_geometria.dart';
import 'package:ulima_plus/pages/splash/variantes/ensamble.dart';
import 'package:ulima_plus/pages/splash/variantes/variante_de_intro.dart';
import 'package:ulima_plus/services/splash_variante_service.dart';

const _centro = Offset(187.5, 333.5);
const _v = Ensamble();

EscenaDelLogo _en(double ms, {double? cargaLista}) =>
    _v.escena(ms, centro: _centro, radio: 90, cargaLista: cargaLista);

void _enReposo(EscenaDelLogo e, {bool conCruces = true}) {
  for (final r in e.rombos) {
    expect(r.desplazamiento, closeTo(0, 1e-6));
    expect(r.giro, closeTo(0, 1e-6));
    expect(r.escala, closeTo(1, 1e-6));
    expect(r.opacidad, closeTo(1, 1e-6));
  }
  expect(e.escalaCentral, closeTo(1, 1e-6));
  expect(e.destello, isNull);
  if (conCruces) {
    expect(e.cruces, hasLength(2));
    for (var i = 0; i < 2; i++) {
      expect(e.cruces[i].centro, LogoGeometria.centrosDeCruz[i]);
      expect(e.cruces[i].escala, closeTo(1, 1e-6));
      expect(e.cruces[i].giro, closeTo(0, 1e-6));
    }
  } else {
    expect(e.cruces, isEmpty);
  }
}

void main() {
  group('Ensamble, la entrada (RF-SPL-7)', () {
    test('es la variante ensamble, entra en 1250 ms y sale en 530 ms', () {
      expect(_v.tipo, VarianteSplash.ensamble);
      expect(_v.finDeLaEntrada, 1250);
      expect(_v.duracionDeLaSalida, 530);
      expect(_v.finDeLaEntrada + _v.duracionDeLaSalida, 1780);
    });

    test('quieta de 0 a 80 ms, igual al nativo y sin «++»', () {
      _enReposo(_en(0), conCruces: false);
      _enReposo(_en(80), conCruces: false);
      expect(_en(0).centro, _centro);
      expect(_en(0).radio, 90);
    });

    test('a los 260 ms los ocho rombos están abiertos, 200 u afuera, a −60°, '
        'con escala 0,6 y opacidad 0,4', () {
      for (final r in _en(260).rombos) {
        expect(r.desplazamiento, closeTo(200, 1e-6));
        expect(r.giro, closeTo(-60 * grado, 1e-6));
        expect(r.escala, closeTo(0.6, 1e-6));
        expect(r.opacidad, closeTo(0.4, 1e-6));
      }
    });

    test('cada rombo encaja desde 260 + 50·k durante 264 ms, el último hasta '
        '874 ms', () {
      for (var k = 0; k < 8; k++) {
        final inicio = 260.0 + 50 * k;
        final abierto = _en(inicio - 1).rombos[k];
        if (k > 0) expect(abierto.desplazamiento, closeTo(200, 1e-6));
        final alMedio = _en(inicio + 50).rombos[k];
        expect(alMedio.opacidad, closeTo(1, 1e-6), reason: 'opacidad a 50 ms');
        final encajado = _en(inicio + 264).rombos[k];
        expect(encajado.desplazamiento, closeTo(0, 1e-6), reason: 'rombo $k');
        expect(encajado.giro, closeTo(0, 1e-6));
        expect(encajado.escala, closeTo(1, 1e-6));
      }
      expect(260 + 50 * 7 + 264, 874);
    });

    test('el encaje rebota, porque el desplazamiento pasa de cero', () {
      var minimo = double.infinity;
      for (var ms = 260.0; ms <= 524; ms += 2) {
        minimo = math.min(minimo, _en(ms).rombos[0].desplazamiento);
      }
      expect(minimo, lessThan(0));
    });

    test(
      'la estrella central se contrae 2,2 % 119 ms después de cada encaje',
      () {
        // El pico de la compresión del rombo 0 es a 260 + 119 + 95 ms.
        expect(_en(474).escalaCentral, closeTo(0.978, 1e-3));
        expect(_en(378).escalaCentral, closeTo(1, 1e-6));
      },
    );

    test('el destello cruza de 720 a 1080 ms, sin desenfoque', () {
      expect(_en(719).destello, isNull);
      final medio = _en(900).destello!;
      expect(medio.avance, closeTo(0.5, 1e-6));
      expect(medio.intensidad, closeTo(1, 1e-6));
      expect(_en(1081).destello, isNull);
    });

    test('el anillo crece de 370 u a 640 u entre 720 y 1260 ms', () {
      final inicio = _en(
        720,
      ).anillos.firstWhere((a) => a.centro == Offset.zero);
      expect(inicio.radio, closeTo(370, 1e-6));
      expect(inicio.trazo, closeTo(16, 1e-6));
      expect(inicio.opacidad, closeTo(0.35, 1e-6));
      expect(_en(1260).anillos, isEmpty);
    });

    test('cada «+» aparece girando de −90° a 0° con rebote de escala', () {
      expect(_en(859).cruces, isEmpty);
      final nace = _en(860).cruces.single;
      expect(nace.giro, closeTo(-90 * grado, 1e-6));
      expect(nace.escala, closeTo(0, 1e-6));
      expect(_en(930).cruces, hasLength(2));
      final primero = _en(1160).cruces[0];
      expect(primero.giro, closeTo(0, 1e-6));
      expect(primero.escala, closeTo(1, 1e-6));
      var maxima = 0.0;
      for (var ms = 860.0; ms <= 1160; ms += 2) {
        maxima = math.max(maxima, _en(ms).cruces[0].escala);
      }
      expect(maxima, greaterThan(1), reason: 'el rebote de escala');
      final onda = _en(900).anillos.where((a) => a.centro != Offset.zero);
      expect(onda, isNotEmpty, reason: 'la onda del primer «+»');
    });

    test('a los 1250 ms queda el logo completo con sus «++»', () {
      _enReposo(_en(1250));
      expect(_en(1250).anillos, isEmpty);
    });
  });

  group('Ensamble, la espera y el reposo (RF-SPL-10 y RF-SPL-21)', () {
    test('si la carga sigue, una onda de hasta 20 u recorre los rombos en '
        'sentido horario, con un período de 1100 ms, y entra en 300 ms', () {
      final alEntrar = _en(1250);
      expect(alEntrar.rombos.every((r) => r.desplazamiento == 0), isTrue);
      var maximo = 0.0;
      for (var ms = 1550.0; ms < 1550 + 1100; ms += 5) {
        final ds = _en(ms).rombos.map((r) => r.desplazamiento);
        maximo = math.max(maximo, ds.reduce(math.max));
      }
      expect(maximo, closeTo(20, 0.5));
      // Un período después, cada rombo vuelve a su desplazamiento.
      for (var k = 0; k < 8; k++) {
        expect(
          _en(1700).rombos[k].desplazamiento,
          closeTo(_en(2800).rombos[k].desplazamiento, 1e-6),
        );
      }
      // El pico pasa del rombo k al k + 1 en 1100 / 8 ms.
      final a = _en(1800).rombos.map((r) => r.desplazamiento).toList();
      final b = _en(
        1800 + 1100 / 8,
      ).rombos.map((r) => r.desplazamiento).toList();
      for (var k = 0; k < 8; k++) {
        expect(b[(k + 1) % 8], closeTo(a[k], 1e-6));
      }
    });

    test('con la carga lista antes de 1250 ms no hay bucle', () {
      _enReposo(_en(1500, cargaLista: 600));
      expect(_v.finDelReposo(600), 1250);
      expect(_v.finDelReposo(null), 1250);
    });

    test('si la carga termina en el bucle, la onda se apaga en 300 ms antes '
        'del relevo', () {
      expect(_v.finDelReposo(2000), 2300);
      final apagandose = _en(2150, cargaLista: 2000);
      final sinApagar = _en(2150);
      final suma = apagandose.rombos.fold<double>(
        0,
        (s, r) => s + r.desplazamiento,
      );
      final sumaSinApagar = sinApagar.rombos.fold<double>(
        0,
        (s, r) => s + r.desplazamiento,
      );
      expect(suma, lessThan(sumaSinApagar));
      _enReposo(_en(2300, cargaLista: 2000));
      _enReposo(_en(2600, cargaLista: 2000));
    });

    test('en la salida la onda se apaga en el primer tercio', () {
      final inicio = _v.alSalir(2000, 0, centro: _centro, radio: 90);
      final ahora = _en(2000);
      for (var k = 0; k < 8; k++) {
        expect(
          inicio.rombos[k].desplazamiento,
          closeTo(ahora.rombos[k].desplazamiento, 1e-6),
        );
      }
      final tercio = _v.alSalir(2000, 530 / 3, centro: _centro, radio: 90);
      expect(tercio.rombos.every((r) => r.desplazamiento.abs() < 1e-9), isTrue);
    });
  });
}
