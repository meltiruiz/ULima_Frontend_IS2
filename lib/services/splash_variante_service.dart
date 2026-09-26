// lib/services/splash_variante_service.dart
// La variante de la intro del splash (RF-SPL-6). Sale al azar, con
// probabilidad pareja y sin repetir la del arranque anterior, y la última se
// guarda en shared_preferences con su propia instancia, así que la lectura no
// espera a que la carga registre StorageService. Es una preferencia de
// interfaz y no un dato académico, y cerrar sesión no la borra.

import 'dart:async';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

enum VarianteSplash {
  ensamble,
  incremento,
  codigo;

  /// El valor que se guarda.
  String get clave => name;

  static VarianteSplash? deClave(String? clave) {
    for (final v in values) {
      if (v.name == clave) return v;
    }
    return null;
  }
}

/// Con una [ultima] válida sale una de las otras dos con probabilidad 1/2, y
/// sin ella, una de las tres con probabilidad 1/3.
VarianteSplash elegirVariante(VarianteSplash? ultima, Random random) {
  if (ultima == null) {
    return VarianteSplash.values[random.nextInt(VarianteSplash.values.length)];
  }
  final otras = <VarianteSplash>[
    for (final v in VarianteSplash.values)
      if (v != ultima) v,
  ];
  return otras[random.nextInt(otras.length)];
}

class SplashVarianteService {
  SplashVarianteService({Future<SharedPreferences> Function()? preferencias})
    : _preferencias = preferencias ?? SharedPreferences.getInstance;

  static const String clave = 'splash_ultima_variante';

  final Future<SharedPreferences> Function() _preferencias;

  /// Lee la última, elige y guarda la elegida sin esperar la escritura. Si la
  /// lectura falla, la variante sale entre las tres y no se guarda.
  Future<VarianteSplash> elegir(Random random) async {
    SharedPreferences? prefs;
    VarianteSplash? ultima;
    try {
      prefs = await _preferencias();
      ultima = VarianteSplash.deClave(prefs.getString(clave));
    } catch (_) {
      prefs = null;
    }
    final elegida = elegirVariante(ultima, random);
    if (prefs != null) {
      unawaited(
        prefs.setString(clave, elegida.clave).catchError((Object _) => false),
      );
    }
    return elegida;
  }
}
