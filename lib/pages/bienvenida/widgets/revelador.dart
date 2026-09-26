// lib/pages/bienvenida/widgets/revelador.dart
// El ritmo de la conversación (RF-BIEN-5). Revela cada entrada después de su
// pausa, y el compositor 500 ms después de la última, o 900 ms antes del
// paso al horario. Con lector de pantalla, las burbujas de un turno entran
// juntas (RF-BIEN-16). Retenido, no revela nada, como mientras corre el
// recibimiento. Las pausas no son movimiento, así que siguen con reducir
// movimiento (RF-BIEN-15).

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../conversacion.dart';

class Revelador extends ChangeNotifier {
  List<EntradaDeLaConversacion> _entradas = const <EntradaDeLaConversacion>[];
  bool _hayCompositor = false;
  bool _conLector = false;
  Duration _pausaDelCompositor = Ritmo.antesDelCompositor;
  int _visibles = 0;
  bool _compositor = false;
  bool _retenido = false;
  Timer? _reloj;

  int get visibles => _visibles;
  bool get compositorVisible => _compositor;
  bool get retenido => _retenido;

  set retenido(bool valor) {
    _retenido = valor;
    _programar();
  }

  void actualizar({
    required List<EntradaDeLaConversacion> entradas,
    required bool hayCompositor,
    required bool conLector,
    Duration pausaDelCompositor = Ritmo.antesDelCompositor,
  }) {
    _entradas = List<EntradaDeLaConversacion>.of(entradas);
    _hayCompositor = hayCompositor;
    _conLector = conLector;
    _pausaDelCompositor = pausaDelCompositor;
    var cambio = false;
    if (_visibles > _entradas.length) {
      _visibles = _entradas.length;
      cambio = true;
    }
    // Una entrada nueva o un turno sin compositor lo cierran.
    if (_compositor && (!hayCompositor || _visibles < _entradas.length)) {
      _compositor = false;
      cambio = true;
    }
    if (cambio) notifyListeners();
    _programar();
  }

  /// Muestra ya las primeras [cuantas], como el primer grupo que la
  /// conversación trae al terminar el recibimiento.
  void mostrarYa(int cuantas) {
    if (cuantas <= _visibles) return;
    _visibles = cuantas.clamp(0, _entradas.length);
    notifyListeners();
    _programar();
  }

  void _programar() {
    _reloj?.cancel();
    if (_retenido) return;
    if (_visibles < _entradas.length) {
      final pausa = _conLector ? Duration.zero : _entradas[_visibles].pausa;
      if (pausa == Duration.zero) {
        // Sin pausa, la entrada entra enseguida, en el mismo cuadro.
        _visibles++;
        notifyListeners();
        _programar();
        return;
      }
      _reloj = Timer(pausa, () {
        _visibles++;
        notifyListeners();
        _programar();
      });
      return;
    }
    if (_hayCompositor && !_compositor) {
      final pausa =
          _conLector && _pausaDelCompositor == Ritmo.antesDelCompositor
          ? Duration.zero
          : _pausaDelCompositor;
      _reloj = Timer(pausa, () {
        _compositor = true;
        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }
}
