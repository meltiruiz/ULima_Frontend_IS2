// lib/pages/splash/variantes/variante_de_intro.dart
// La base de las tres variantes de la intro (RF-SPL-6 a RF-SPL-10). Cada una
// es una línea de tiempo pura. Recibe el instante en ms, contado desde que la
// intro empieza a moverse, y devuelve la escena del logo. Así cada fila de
// las tablas de la spec se prueba con un número (decisión 1 del plan).

import 'dart:math' as math;

import 'package:flutter/animation.dart';

import '../../../components/logo/escena_del_logo.dart';
import '../../../services/splash_variante_service.dart';

const double grado = math.pi / 180;

/// El avance de 0 a 1 entre [desde] y [hasta], acotado.
double tramo(double ms, double desde, double hasta) =>
    ((ms - desde) / (hasta - desde)).clamp(0.0, 1.0).toDouble();

/// easeOutBack con el sobrepaso [s]. Vale 0 en 0 y 1 en 1, y pasa de 1 en
/// el medio.
double conRebote(double t, double s) {
  final u = t - 1;
  return 1 + u * u * ((s + 1) * u + s);
}

/// Medio seno, de 0 a 1 y de vuelta a 0.
double medioSeno(double t) => math.sin(math.pi * t.clamp(0.0, 1.0));

double mezcla(double a, double b, double t) => a + (b - a) * t;

Offset bezierCuadratica(Offset p0, Offset p1, Offset p2, double t) {
  final s = 1 - t;
  return p0 * (s * s) + p1 * (2 * s * t) + p2 * (t * t);
}

abstract class VarianteDeIntro {
  const VarianteDeIntro();

  VarianteSplash get tipo;

  /// Fin de la entrada, en ms.
  double get finDeLaEntrada;

  /// La duración de la salida hacia /home, en ms (RF-SPL-11).
  double get duracionDeLaSalida;
  Curve get curvaDeLaSalida;

  /// La escena en [ms]. Si la carga sigue al terminar la entrada, la variante
  /// repite su bucle (RF-SPL-10). Si la carga termina durante el bucle, en
  /// [cargaLista], la variante vuelve al reposo, que es lo que pide el relevo
  /// a la bienvenida (RF-SPL-21 y S-34). Hacia /home, la capa pasa a la
  /// salida en [cargaLista] y deja de pedir esta escena.
  EscenaDelLogo escena(
    double ms, {
    required Offset centro,
    required double radio,
    double? cargaLista,
  });

  /// Cuándo queda el logo en reposo, listo para el relevo.
  double finDelReposo(double? cargaLista);

  /// Lo que queda del bucle mientras corre la salida que empieza en
  /// [msInicio], con el reposo como base. La salida mueve la estrella y los
  /// «+» por su cuenta.
  EscenaDelLogo alSalir(
    double msInicio,
    double msEnSalida, {
    required Offset centro,
    required double radio,
  });

  /// El giro de la estrella al empezar la salida.
  double giroAlSalir(double msInicio) => 0;

  /// El destino del giro en curso al empezar la salida.
  double destinoDelGiro(double msInicio) => 0;
}
