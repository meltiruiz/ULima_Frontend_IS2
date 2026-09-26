// test/splash/splash_seleccion_test.dart
//
// UNITARIA · Splash animado (specs/features/splash/splash.spec.md).
// RF-SPL-6. La variante sale al azar con probabilidad pareja y sin repetir la
// del arranque anterior, y la última se guarda en shared_preferences.
// Archivo probado lib/services/splash_variante_service.dart.

import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ulima_plus/services/splash_variante_service.dart';
import 'package:ulima_plus/services/storage_service.dart';

import 'apoyo_splash.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('elegirVariante (RF-SPL-6)', () {
    test('sin una última válida sale una de las tres', () {
      final vistas = <VarianteSplash>{
        for (var i = 0; i < 3; i++) elegirVariante(null, RandomFijo([i])),
      };
      expect(vistas, VarianteSplash.values.toSet());
    });

    test('con una última sale una de las otras dos, nunca la misma', () {
      for (final ultima in VarianteSplash.values) {
        final random = RandomFijo([0, 1]);
        final a = elegirVariante(ultima, random);
        final b = elegirVariante(ultima, random);
        expect({a, b}, VarianteSplash.values.toSet()..remove(ultima));
        expect(random.maximos, [2, 2]);
      }
    });

    test('a la larga cada variante sale en un tercio de los arranques y '
        'nunca dos veces seguidas', () {
      final random = Random(7);
      final cuenta = <VarianteSplash, int>{};
      VarianteSplash? ultima;
      const arranques = 30000;
      for (var i = 0; i < arranques; i++) {
        final v = elegirVariante(ultima, random);
        expect(v, isNot(ultima));
        cuenta[v] = (cuenta[v] ?? 0) + 1;
        ultima = v;
      }
      for (final v in VarianteSplash.values) {
        expect(cuenta[v]! / arranques, closeTo(1 / 3, 0.02), reason: '$v');
      }
    });

    test('las claves son ensamble, incremento y codigo', () {
      expect(VarianteSplash.values.map((v) => v.clave).toList(), [
        'ensamble',
        'incremento',
        'codigo',
      ]);
      expect(VarianteSplash.deClave('codigo'), VarianteSplash.codigo);
      expect(VarianteSplash.deClave('otra'), isNull);
      expect(VarianteSplash.deClave(null), isNull);
    });
  });

  group('SplashVarianteService (RF-SPL-6)', () {
    test('lee la última, elige otra y la guarda con su clave', () async {
      SharedPreferences.setMockInitialValues({
        'splash_ultima_variante': 'codigo',
      });
      final random = RandomFijo([1]);
      final v = await SplashVarianteService().elegir(random);
      expect(v, VarianteSplash.incremento);
      expect(random.maximos, [2]);
      final prefs = await SharedPreferences.getInstance();
      await Future<void>.delayed(Duration.zero);
      expect(prefs.getString('splash_ultima_variante'), 'incremento');
    });

    test('un valor desconocido cuenta como la primera vez', () async {
      SharedPreferences.setMockInitialValues({
        'splash_ultima_variante': 'otra',
      });
      final random = RandomFijo([2]);
      expect(
        await SplashVarianteService().elegir(random),
        VarianteSplash.codigo,
      );
      expect(random.maximos, [3]);
    });

    test('si la lectura falla, sale entre las tres y no se guarda', () async {
      final random = RandomFijo([0]);
      final servicio = SplashVarianteService(
        preferencias: () async => throw StateError('sin almacén'),
      );
      expect(await servicio.elegir(random), VarianteSplash.ensamble);
      expect(random.maximos, [3]);
    });

    test('cerrar sesión no borra la última variante', () async {
      SharedPreferences.setMockInitialValues({
        'splash_ultima_variante': 'ensamble',
        'session_code': '20230001',
      });
      FlutterSecureStorage.setMockInitialValues({'session_token': 'jwt'});
      final almacen = await StorageService().init();
      await almacen.clearSession();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('session_code'), isNull);
      expect(prefs.getString('splash_ultima_variante'), 'ensamble');
    });
  });
}
