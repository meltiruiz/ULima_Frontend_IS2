// lib/pages/academic_record/academic_record_controller.dart
// Controller de /mi-record (RF-REC-2).

import 'package:get/get.dart';

import '../../models/academic_record_model.dart';
import '../../services/academic_record_service.dart';
import '../../services/auth_service.dart';

/// Vista de la pantalla sobre el estado único del récord.
///
/// No guarda una copia del récord: lo lee de [AcademicRecordService], que es el
/// mismo estado que pinta la tarjeta del Perfil (RF-REC-5). Así, al volver con
/// back después de borrar, la tarjeta no puede mostrar cifras viejas.
class AcademicRecordController extends GetxController {
  AcademicRecordController({
    AcademicRecordService? service,
    DateTime Function()? now,
  })  : _service = service ?? AcademicRecordService.to,
        _now = now ?? DateTime.now;

  final AcademicRecordService _service;
  final DateTime Function() _now;

  AcademicRecord? get record => _service.record;
  bool get isLoading => _service.isLoading;

  /// Un docente nunca tiene récord: el servicio no dispara el GET para él
  /// (RF-REC-1) y la pantalla se quedaría en el skeleton para siempre.
  /// `/mi-record` es una ruta con nombre y cualquiera puede llegar a ella
  /// ("Qué NO entra: mostrar el récord a otros roles").
  bool get hasError =>
      _service.hasError || (AuthService.to.currentUser?.isTeacher ?? false);

  String? get syncedLabel {
    final s = record?.syncedAt;
    return s == null ? null : syncedAgoLabel(s, _now());
  }

  Future<void> retry() => _service.load(force: true);

  /// Ciclo que el alumno tocó. Queda null hasta el primer toque, y entonces
  /// manda el más reciente (RF-REC-2). La tarea 8 lo vuelve a null al borrar
  /// el récord.
  final selectedPeriodCode = RxnString();

  /// Los ciclos del récord, en el orden en que los manda el backend: del más
  /// reciente al más viejo (RS-BE-26). El cliente no los reordena.
  List<String> get periodCodes =>
      record?.coursesByPeriod.map((p) => p.periodCode).toList() ??
      const <String>[];

  /// El ciclo que se está mostrando ahora mismo.
  String? get currentPeriodCode =>
      periodoSeleccionado(periodCodes, selectedPeriodCode.value);

  /// Solo el ciclo más reciente del récord puede decir "En curso" (RF-REC-3):
  /// en los demás, un curso sin nota es una raya.
  bool isMostRecentPeriod(String periodCode) =>
      periodCodes.isNotEmpty && periodCodes.first == periodCode;

  /// Un solo ciclo a la vez: el chip que se toca reemplaza al anterior.
  void selectPeriod(String periodCode) => selectedPeriodCode.value = periodCode;

  /// Borrado en vuelo (RF-REC-5). Mientras dure, el botón se deshabilita y no
  /// hay spinner: un indicador animado nunca para y colgaría los
  /// `pumpAndSettle` de los tests, igual que `SkeletonPulse`.
  final deleting = false.obs;

  /// Borra la copia del récord guardada en ULima++ (RF-REC-5).
  ///
  /// Relanza [AcademicRecordFailure] tal cual: el controller no sabe pintar
  /// avisos y es la pantalla la que muestra el mensaje. Si sale bien, el
  /// servicio deja el récord vacío, así que el ciclo elegido deja de existir
  /// y vuelve a null; si no, la próxima sincronización abriría en un chip
  /// que ya no está.
  Future<void> deleteRecord() async {
    if (deleting.value) return; // doble toque mientras el DELETE va en camino
    deleting.value = true;
    try {
      await _service.deleteRecord();
      selectedPeriodCode.value = null;
    } finally {
      deleting.value = false;
    }
  }

  /// Pura y expuesta para probarla. Un ciclo elegido que ya no está en el
  /// récord —porque se volvió a sincronizar y cambió— cae al más reciente, que
  /// es el primero de la lista.
  static String? periodoSeleccionado(
    List<String> periodCodes,
    String? elegido,
  ) {
    if (periodCodes.isEmpty) return null;
    if (elegido != null && periodCodes.contains(elegido)) return elegido;
    return periodCodes.first;
  }

  /// Pura y expuesta para probarla. El promedio del ciclo sale de `periods`,
  /// no de las notas: si el backend no manda ese ciclo, o su `average` es
  /// null, devuelve null y la tarjeta no pinta nada (nunca un 0).
  static double? periodAverage(
    List<AcademicPeriodSummary> periods,
    String periodCode,
  ) {
    for (final p in periods) {
      if (p.periodCode == periodCode) return p.average;
    }
    return null;
  }

  @override
  void onReady() {
    // GetX agenda onReady después del primer frame, así que ningún Rx cambia
    // mientras build construye: el Obx de la tarjeta del Perfil, que queda
    // debajo en la pila, escucha estos mismos Rx.
    super.onReady();
    _service.load();
  }

  /// Pura y expuesta para probarla. Compara FECHAS de calendario en Lima
  /// (UTC-5, sin horario de verano), no bloques de 24 h: una sincronización a
  /// las 23:30 de ayer es "hace 1 día" aunque haya pasado una hora.
  static String syncedAgoLabel(DateTime syncedAt, DateTime now) {
    DateTime diaEnLima(DateTime t) {
      final lima = t.toUtc().subtract(const Duration(hours: 5));
      return DateTime.utc(lima.year, lima.month, lima.day);
    }

    final dias = diaEnLima(now).difference(diaEnLima(syncedAt)).inDays;
    if (dias <= 0) return 'Sincronizado hoy';
    if (dias == 1) return 'Sincronizado hace 1 día';
    return 'Sincronizado hace $dias días';
  }
}
