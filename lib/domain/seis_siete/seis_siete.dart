// lib/domain/seis_siete/seis_siete.dart
//
// Regla pura del truco del 67 (specs/features/six-seven/six-seven.spec.md).
// Decide qué mensaje es un 67 (RF-67-1) y da el ángulo del tambaleo en cada
// instante (RF-67-2). No importa Flutter ni GetX, como el resto de
// lib/domain, y es el único sitio donde vive la regla.

import 'dart:math' as math;

/// Texto de la burbuja de Ulises y del rótulo de los chats de sección.
const String textoSeisSiete = 'SIX SEVEN!!!';

/// Amplitud del tambaleo, 3° en radianes (D2).
const double amplitudSeisSiete = 3 * math.pi / 180;

/// Ciclos completos de seno en cada tambaleo (D3).
const int ciclosSeisSiete = 4;

/// Duración de cada tambaleo y de la ventana de «uno a la vez» (RF-67-3).
const Duration duracionSeisSiete = Duration(milliseconds: 2000);

/// Formas que disparan, ya normalizadas (P1 y D1).
const Set<String> _formasSeisSiete = {
  '67',
  '6 7',
  '6-7',
  'six seven',
  'six-seven',
};

/// Espacios en blanco y signos «!» o «¡» del principio o del final.
final RegExp _bordesSeisSiete = RegExp(r'^[\s!¡]+|[\s!¡]+$');

/// Cada tramo interno de espacios en blanco.
final RegExp _espaciosSeisSiete = RegExp(r'\s+');

/// Si [texto] es un 67 (RF-67-1). Quita los bordes, pasa a minúsculas, reduce
/// cada tramo de espacios a uno y compara con la lista cerrada, así que un 67
/// dentro de una frase no cuenta.
bool esSeisSiete(String texto) {
  final normalizado = texto
      .replaceAll(_bordesSeisSiete, '')
      .toLowerCase()
      .replaceAll(_espaciosSeisSiete, ' ');
  return _formasSeisSiete.contains(normalizado);
}

/// Ángulo del tambaleo en radianes para un [progreso] entre 0 y 1 (RF-67-2).
/// Es −A · sen(2π · n · progreso), así que el primer vaivén va hacia la
/// izquierda. Fuera de ese rango devuelve 0.
double anguloSeisSiete(double progreso) {
  if (progreso < 0 || progreso > 1) return 0;
  return -amplitudSeisSiete *
      math.sin(2 * math.pi * ciclosSeisSiete * progreso);
}
