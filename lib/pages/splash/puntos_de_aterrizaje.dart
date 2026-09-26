// lib/pages/splash/puntos_de_aterrizaje.dart
// Dónde quedan las piezas a las que llega la capa del arranque. La cabecera
// informa su estrella y su texto una vez que se dibuja (RF-SPL-11), y la
// burbuja de Ulises su lugar inicial (RF-BIEN-11). Cada una informa desde su
// propio State, sin una GlobalKey compartida, y si dos cabeceras conviven un
// instante manda la última que se dibuja.

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

class MedidaDeCabecera {
  const MedidaDeCabecera({
    required this.cabecera,
    required this.estrella,
    required this.texto,
    required this.estilo,
    required this.escalaDeTexto,
    required this.color,
    required this.colorDelBorde,
  });

  /// La cabecera entera, con su borde inferior, en coordenadas globales.
  final Rect cabecera;
  final Rect estrella;

  /// El texto «ULIMA++».
  final Rect texto;
  final TextStyle estilo;
  final TextScaler escalaDeTexto;

  /// `headerColor` del tema.
  final Color color;
  final Color colorDelBorde;

  @override
  bool operator ==(Object other) =>
      other is MedidaDeCabecera &&
      other.cabecera == cabecera &&
      other.estrella == estrella &&
      other.texto == texto &&
      other.estilo == estilo &&
      other.escalaDeTexto == escalaDeTexto &&
      other.color == color &&
      other.colorDelBorde == colorDelBorde;

  @override
  int get hashCode => Object.hash(
    cabecera,
    estrella,
    texto,
    estilo,
    escalaDeTexto,
    color,
    colorDelBorde,
  );
}

abstract final class PuntosDeAterrizaje {
  static final ValueNotifier<MedidaDeCabecera?> cabecera =
      ValueNotifier<MedidaDeCabecera?>(null);

  /// El lugar inicial de la burbuja de Ulises, en coordenadas globales.
  static final ValueNotifier<Rect?> burbuja = ValueNotifier<Rect?>(null);

  /// La capa lo enciende solo en el paso al horario de la bienvenida, y la
  /// burbuja espera oculta hasta que se apaga (decisiones S-28 y B-16).
  static final ValueNotifier<bool> ulisesEnVuelo = ValueNotifier<bool>(false);

  static void reiniciar() {
    cabecera.value = null;
    burbuja.value = null;
    ulisesEnVuelo.value = false;
  }
}
