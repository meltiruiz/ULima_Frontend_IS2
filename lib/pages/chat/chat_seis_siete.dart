// lib/pages/chat/chat_seis_siete.dart
//
// Detector del 67 que llega en vivo a un chat de sección (RF-67-6 de
// specs/features/six-seven/six-seven.spec.md). No depende de Flutter, así
// que se prueba aparte con listas armadas a mano.

import '../../domain/seis_siete/seis_siete.dart';
import '../../models/message.dart';

/// Recuerda los ids que la página ya vio y dice si una lista trae un 67 nuevo.
///
/// La primera lista es el historial, así que solo marca sus ids como vistos y
/// nunca dispara. En cada lista siguiente, un mensaje es nuevo si su id no
/// figura en ninguna lista anterior. La lista dispara si al menos uno de los
/// nuevos no está borrado, no es un carnet y su cuerpo es un 67. Todos los
/// ids nuevos quedan vistos, disparen o no.
class DetectorSeisSiete {
  final Set<String> _vistos = <String>{};
  bool _conHistorial = false;

  /// Revisa [mensajes], la lista completa que trae cada evento del stream, y
  /// devuelve si dispara un tambaleo.
  bool revisar(List<ChatMessage> mensajes) {
    if (!_conHistorial) {
      _conHistorial = true;
      _vistos.addAll(mensajes.map((m) => m.id));
      return false;
    }
    var dispara = false;
    for (final mensaje in mensajes) {
      final esNuevo = _vistos.add(mensaje.id);
      if (esNuevo &&
          !mensaje.deleted &&
          !mensaje.isNetworkingCard &&
          esSeisSiete(mensaje.text)) {
        dispara = true;
      }
    }
    return dispara;
  }
}
