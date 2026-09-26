// lib/pages/bienvenida/conversacion.dart
// Lo que se ve en la conversación con Ulises (RF-BIEN-5). El controlador
// arma las entradas con la pausa que espera cada una antes de entrar, y la
// página las revela con ese ritmo, o todas juntas con lector de pantalla
// (decisión 6 del plan). Nada de esto se guarda en disco.

import '../../models/specialty_test_models.dart';
import '../specialty_test/specialty_test_logic.dart' show SelloDeBloque;

enum TipoDeBurbuja { texto, error, consentimiento, avisos, cargando, esperando }

/// Las pausas del ritmo (RF-BIEN-2, RF-BIEN-5 y RF-BIEN-6).
abstract final class Ritmo {
  static const Duration entreBurbujas = Duration(milliseconds: 850);
  static const Duration antesDelCompositor = Duration(milliseconds: 500);
  static const Duration trasLaRespuesta = Duration(milliseconds: 650);
  static const Duration antesDelPaso = Duration(milliseconds: 900);
}

sealed class EntradaDeLaConversacion {
  const EntradaDeLaConversacion({required this.id, required this.pausa});

  /// Una clave estable, así que una burbuja nueva no reconstruye las
  /// anteriores (RF-BIEN-18).
  final int id;

  /// Cuánto espera antes de entrar, contado desde la entrada anterior.
  final Duration pausa;
}

class BurbujaDeUlises extends EntradaDeLaConversacion {
  const BurbujaDeUlises({
    required super.id,
    required this.texto,
    super.pausa = Duration.zero,
    this.tipo = TipoDeBurbuja.texto,
    this.titulo,
    this.lineas = const <String>[],
    this.sello,
  });

  final String texto;
  final TipoDeBurbuja tipo;

  /// Un título en negrita sobre el texto, como la tarea de una escala o
  /// «Algunas cosas que notamos».
  final String? titulo;

  /// Líneas precedidas de «· », como los avisos del registro.
  final List<String> lineas;

  /// El sello «Cierra el bloque k de B» junto a la burbuja (RF-TEST-4).
  final SelloDeBloque? sello;
}

/// Una respuesta del alumno. Un dato secreto se muestra como un candado y un
/// rótulo, nunca con su valor (RF-BIEN-9).
class RespuestaDelAlumno extends EntradaDeLaConversacion {
  const RespuestaDelAlumno({
    required super.id,
    required this.texto,
    this.secreta = false,
    this.conGoogle = false,
  }) : super(pausa: Duration.zero);

  final String texto;
  final bool secreta;
  final bool conGoogle;
}

/// El resultado del test, con sus tarjetas a lo ancho de la columna
/// (RF-BIEN-10). Guarda lo que muestra, así que queda en la conversación
/// aunque el alumno rehaga el test (RF-BIEN-5).
class ResultadoDelTest extends EntradaDeLaConversacion {
  const ResultadoDelTest({
    required super.id,
    required this.resultado,
    required this.contenido,
    this.corazones,
    super.pausa = Duration.zero,
  });

  final SpecialtyTestResult resultado;
  final SpecialtyTestContent contenido;

  /// Los corazones con que quedó al rehacer el test, que ya no se tocan, o
  /// null mientras es el resultado vigente.
  final Set<int>? corazones;

  /// El mismo resultado, de solo lectura, con [corazones].
  ResultadoDelTest congelado(Set<int> corazones) => ResultadoDelTest(
    id: id,
    resultado: resultado,
    contenido: contenido,
    corazones: Set<int>.unmodifiable(corazones),
    pausa: pausa,
  );
}
