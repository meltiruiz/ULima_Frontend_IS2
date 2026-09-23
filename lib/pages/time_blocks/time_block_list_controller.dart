// lib/pages/time_blocks/time_block_list_controller.dart
// RF-BLQ-8: estado de la lista «Mis bloques». Todos los bloques guardados de
// la alumna, también los que la grilla no pinta: los vencidos, los que caen
// fuera de la ventana del ciclo y los que no tienen ningún día real entre sus
// fechas.
//
// No guarda copia de nada ni habla HTTP: lee TimeBlocksService, que recarga
// después de cada escritura, así que la lista (un Obx) y la grilla se enteran
// solas. Lo suyo es el reloj de hoy en Lima, el orden de la lista y qué avisa
// cada fila; eso último en funciones puras, para probarlas sin widgets.

import 'package:get/get.dart';

import '../../models/time_block_model.dart';
import '../../services/time_blocks_service.dart';
import 'time_block_validators.dart' show validarDiasEnElRango;

final RegExp _fechaPlana = RegExp(r'^\d{4}-\d{2}-\d{2}$');

/// La fecha de [instante] en Lima, `"YYYY-MM-DD"`. Lima es UTC-5 todo el año,
/// sin horario de verano: es la misma cuenta que `HorarioController`.
String fechaEnLima(DateTime instante) {
  final lima = instante.toUtc().subtract(const Duration(hours: 5));
  return '${lima.year.toString().padLeft(4, '0')}-'
      '${lima.month.toString().padLeft(2, '0')}-'
      '${lima.day.toString().padLeft(2, '0')}';
}

/// Si la fecha de fin de [regla] ya pasó el día [hoy] (`"YYYY-MM-DD"`, en
/// Lima). Un bloque que termina hoy sigue vigente. Una fecha que no se lee
/// no cuenta como pasada: no se inventa un «Terminó».
///
/// Las dos fechas son `"YYYY-MM-DD"`, así que compararlas como texto es
/// compararlas como fechas.
bool bloqueTerminado(TimeBlockRule regla, String hoy) =>
    _fechaPlana.hasMatch(regla.endDate) &&
    _fechaPlana.hasMatch(hoy) &&
    regla.endDate.compareTo(hoy) < 0;

/// Si ninguno de los días marcados de [regla] cae entre sus fechas. Es la
/// misma función que valida el formulario (RF-BLQ-2), así que la lista y el
/// formulario nunca discrepan sobre un bloque.
bool bloqueSinDiasReales(TimeBlockRule regla) =>
    validarDiasEnElRango(
      regla.daysOfWeek.toSet(),
      regla.startDate,
      regla.endDate,
    ) !=
    null;

/// Los bloques en el orden de la lista: primero los vigentes y después los
/// que ya terminaron el día [hoy], cada grupo por fecha de inicio. Si dos
/// empiezan el mismo día, va primero el que termina antes, y si también
/// coinciden, el de id menor: así el orden no depende de cómo llegaron.
///
/// Devuelve una lista nueva: la de [bloques] no se toca.
List<TimeBlockRule> ordenarMisBloques(
  Iterable<TimeBlockRule> bloques,
  String hoy,
) {
  int clave(TimeBlockRule b) => bloqueTerminado(b, hoy) ? 1 : 0;
  return bloques.toList()
    ..sort((a, b) {
      final porGrupo = clave(a).compareTo(clave(b));
      if (porGrupo != 0) return porGrupo;
      final porInicio = a.startDate.compareTo(b.startDate);
      if (porInicio != 0) return porInicio;
      final porFin = a.endDate.compareTo(b.endDate);
      return porFin != 0 ? porFin : a.id.compareTo(b.id);
    });
}

class TimeBlockListController extends GetxController {
  TimeBlockListController({
    TimeBlocksService? service,
    DateTime Function()? ahora,
  })  : _service = service,
        _ahora = ahora ?? DateTime.now;

  final TimeBlocksService? _service;

  /// El reloj. Las pruebas lo fijan; en la app es [DateTime.now].
  final DateTime Function() _ahora;

  /// El service se resuelve tarde (no en el constructor), como en el
  /// formulario: el binding construye el controller antes de que nadie toque
  /// `Get.find`.
  TimeBlocksService get service => _service ?? TimeBlocksService.to;

  /// Hoy en Lima, `"YYYY-MM-DD"`.
  String get hoy => fechaEnLima(_ahora());

  /// Todos los bloques de la alumna, en el orden de la lista para el día
  /// [hoy]. Se pasa [hoy] para que el orden y los avisos de las filas usen la
  /// misma fecha. Leerlo dentro del Obx de la pantalla la suscribe a los
  /// bloques del service.
  List<TimeBlockRule> bloquesOrdenados(String hoy) =>
      ordenarMisBloques(service.blocks, hoy);

  bool get cargando => service.isLoading;
  bool get conError => service.hasError;

  /// Si ya llegó alguna carga de la alumna. El service guarda las reglas y
  /// la ventana de ocurrencias juntas, así que sin ventana tampoco hay
  /// reglas: una lista vacía antes de la primera carga no significa que no
  /// tenga bloques.
  bool get cargado => service.snapshot != null;

  /// «Reintentar»: vuelve a pedir la ventana vigente, reglas incluidas.
  Future<void> reintentar() => service.reload();
}
