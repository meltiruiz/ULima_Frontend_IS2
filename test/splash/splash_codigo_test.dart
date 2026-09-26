// test/splash/splash_codigo_test.dart
//
// UNITARIA · Splash animado (specs/features/splash/splash.spec.md).
// RF-SPL-9 fija la entrada de Código, RF-SPL-10 su cursor de espera y
// RF-SPL-21 su vuelta al reposo. La estrella mide R = 90 dp y las medidas de
// la maqueta, hecha con 86 dp, se escalan con R.
// Archivo probado lib/pages/splash/variantes/codigo.dart.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/components/logo/escena_del_logo.dart';
import 'package:ulima_plus/components/logo/logo_geometria.dart';
import 'package:ulima_plus/pages/splash/variantes/codigo.dart';
import 'package:ulima_plus/pages/splash/variantes/ensamble.dart';
import 'package:ulima_plus/pages/splash/variantes/incremento.dart';
import 'package:ulima_plus/pages/splash/variantes/variantes.dart';
import 'package:ulima_plus/services/splash_variante_service.dart';

const _centro = Offset(187.5, 333.5);
const _v = Codigo();
const _r = 354.8;

EscenaDelLogo _en(double ms, {double? cargaLista}) =>
    _v.escena(ms, centro: _centro, radio: 90, cargaLista: cargaLista);

void main() {
  group('Código, la entrada (RF-SPL-9)', () {
    test('es la variante codigo, entra en 1330 ms y sale en 420 ms', () {
      expect(_v.tipo, VarianteSplash.codigo);
      expect(_v.finDeLaEntrada, 1330);
      expect(_v.duracionDeLaSalida, 420);
      expect(_v.finDeLaEntrada + _v.duracionDeLaSalida, 1750);
    });

    test('la estrella sube 0,66 R y se achica a 0,82 R en 320 ms', () {
      expect(_en(0).desplazamientoDeEstrella, Offset.zero);
      final arriba = _en(320);
      expect(arriba.desplazamientoDeEstrella.dy, closeTo(-0.66 * _r, 1e-6));
      expect(arriba.escalaDeEstrella, closeTo(0.82, 1e-6));
    });

    test('«ULima» se teclea a los 250, 318, 386, 454 y 522 ms', () {
      expect(_en(249).texto, isNull);
      expect(_en(250).texto!.visibles, 1);
      expect(_en(453).texto!.visibles, 3);
      expect(_en(522).texto!.visibles, 5);
    });

    test('el cursor aparece de 160 a 240 ms, avanza con cada letra y cada «+» '
        'y retrocede dos a los 780 ms', () {
      expect(_en(160).cursor!.opacidad, closeTo(0, 1e-6));
      expect(_en(240).cursor!.opacidad, closeTo(1, 1e-6));
      double x(double ms) => _en(ms).cursor!.centro.dx;
      expect(x(240), closeTo(TextoDeCodigo.bordeDeCelda(0), 1e-6));
      expect(x(700), closeTo(TextoDeCodigo.bordeDeCelda(7), 1e-6));
      expect(x(780), closeTo(TextoDeCodigo.bordeDeCelda(5), 1e-6));
      expect(_en(960).cursor, isNull);
    });

    test('cada «+» tecleado aparece en #FFE7A3 con un rebote de 0,55 a 1 en '
        '110 ms', () {
      final nace = _en(610).cruces.single;
      expect(nace.color, const Color(0xFFFFE7A3));
      expect(nace.escala, closeTo(0.55 * Codigo.escalaTecleada, 1e-6));
      expect(nace.centro, TextoDeCodigo.centroDeCelda(5));
      expect(_en(720).cruces[0].escala, closeTo(Codigo.escalaTecleada, 1e-6));
      expect(_en(680).cruces, hasLength(2));
    });

    test(
      'cada «+» vuela a su lugar, gira 90°, se engruesa y pasa a blanco',
      () {
        final llega = _en(1160).cruces[0];
        expect(llega.centro, LogoGeometria.centrosDeCruz[0]);
        expect(llega.giro, closeTo(90 * grado, 1e-6));
        expect(llega.grosor, closeTo(1, 1e-6));
        expect(llega.color, const Color(0xFFFFFFFF));
        expect(llega.escala, closeTo(1, 1e-6));
        final segundo = _en(1210).cruces[1];
        expect(segundo.centro, LogoGeometria.centrosDeCruz[1]);
        // Cada uno sube en arco sobre los dos extremos.
        final medio = _en(970).cruces[0];
        expect(medio.centro.dy, lessThan(LogoGeometria.centrosDeCruz[0].dy));
      },
    );

    test('al aterrizar cada «+» rebota 12 % durante 150 ms', () {
      expect(_en(1160 + 75).cruces[0].escala, closeTo(1.12, 1e-6));
      expect(_en(1310).cruces[0].escala, closeTo(1, 1e-6));
    });

    test(
      'el segundo «+» rebota de 1180 a 1330 ms, cuando ya está a menos de '
      '1 dp de su lugar, y termina con la entrada (decisión 11 del plan)',
      () {
        final llegando = _en(1180).cruces[1];
        // Un dp en u, con R = 90 dp.
        const unDp = _r / 90;
        expect(
          (llegando.centro - LogoGeometria.centrosDeCruz[1]).distance,
          lessThan(unDp),
        );
        expect(_en(1180 + 75).cruces[1].escala, closeTo(1.12, 1e-6));
        expect(_en(1330).cruces[1].escala, closeTo(1, 1e-6));
      },
    );

    test('el texto baja 0,12 R y se desvanece entre 790 y 960 ms', () {
      expect(_en(790).texto!.opacidad, closeTo(1, 1e-6));
      final cayendo = _en(959).texto!;
      expect(cayendo.opacidad, lessThan(0.05));
      expect(cayendo.dy, closeTo(0.12 * _r, 0.01 * _r));
    });

    test('la estrella vuelve al centro y a R entre 820 y 1210 ms, y late '
        '3,5 % hasta los 1330 ms', () {
      final vuelta = _en(1210);
      expect(vuelta.desplazamientoDeEstrella.dy, closeTo(0, 1e-6));
      expect(vuelta.escalaDeEstrella, closeTo(1, 1e-6));
      expect(_en(1270).escalaDeEstrella, closeTo(1.035, 1e-6));
    });

    test('un anillo sale de 1,02 R a 1,5 R entre 1190 y 1410 ms', () {
      final anillo = _en(1190).anillos.single;
      expect(anillo.radio, closeTo(1.02 * _r, 1e-6));
      expect(anillo.opacidad, closeTo(0.38, 1e-6));
      expect(_en(1409).anillos, hasLength(1));
      expect(_en(1410).anillos, isEmpty);
    });

    test('a los 1330 ms el logo está completo, sin texto ni cursor', () {
      final e = _en(1330);
      expect(e.texto, isNull);
      expect(e.cursor, isNull);
      expect(e.desplazamientoDeEstrella, Offset.zero);
      expect(e.escalaDeEstrella, closeTo(1, 1e-6));
      for (var i = 0; i < 2; i++) {
        expect(e.cruces[i].centro, LogoGeometria.centrosDeCruz[i]);
        expect(e.cruces[i].escala, closeTo(1, 1e-6), reason: 'quieto');
      }
    });
  });

  group('Código, la espera y el reposo (RF-SPL-10 y RF-SPL-21)', () {
    test('si la carga sigue, un cursor parpadea a la derecha de los «++», '
        'entra en 200 ms y sigue un coseno de 1060 ms', () {
      expect(_en(1330).cursor, isNull);
      final lleno = _en(1530).cursor!;
      expect(lleno.opacidad, closeTo(1, 1e-6));
      expect(lleno.centro.dx, greaterThan(LogoGeometria.centrosDeCruz[1].dx));
      expect(_en(1530 + 530).cursor, isNull);
      expect(_en(1530 + 1060).cursor!.opacidad, closeTo(1, 1e-6));
    });

    test('con la carga lista, el cursor se apaga en 120 ms', () {
      expect(_v.finDelReposo(1600), 1720);
      expect(_en(1720, cargaLista: 1600).cursor, isNull);
      final saliendo = _v.alSalir(1530, 60, centro: _centro, radio: 90);
      expect(saliendo.cursor!.opacidad, closeTo(0.5, 1e-6));
      expect(_v.alSalir(1530, 120, centro: _centro, radio: 90).cursor, isNull);
    });

    test('hacia la bienvenida el relevo es a los 1330 ms, con los dos «+» '
        'quietos (RF-SPL-17, RF-SPL-21 y decisión 11 del plan)', () {
      expect(_v.finDelReposo(null), 1330);
      expect(_v.finDelReposo(900), 1330);
      final quieto = _en(1330, cargaLista: 900);
      for (var i = 0; i < 2; i++) {
        expect(quieto.cruces[i].escala, closeTo(1, 1e-6));
      }
    });
  });

  test('varianteDe da la variante de cada tipo', () {
    expect(varianteDe(VarianteSplash.ensamble), isA<Ensamble>());
    expect(varianteDe(VarianteSplash.incremento), isA<Incremento>());
    expect(varianteDe(VarianteSplash.codigo), isA<Codigo>());
  });
}
