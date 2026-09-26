// lib/pages/splash/estado_de_la_capa.dart
// Si la capa del arranque cubre la pantalla. Mientras la cubre, /home no pide
// las orientaciones de Horario, y las pide cuando la capa se retira
// (RF-SPL-20, decisión S-26 y BR-SHELL-F-00 de app-shell).

import 'package:flutter/foundation.dart';

abstract final class EstadoDeLaCapa {
  static final ValueNotifier<bool> cubre = ValueNotifier<bool>(false);
}
