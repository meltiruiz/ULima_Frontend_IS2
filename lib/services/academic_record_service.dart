import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/academic_record_model.dart';
import 'api_client.dart';
import 'auth_service.dart';

/// Estado único del récord académico del alumno (RF-REC-5).
///
/// La tarjeta del Perfil y la pantalla `/mi-record` leen de este mismo
/// servicio, así que nunca muestran dos versiones del récord. El estado se
/// vacía y se vuelve a pedir tras el `DELETE` ([deleteRecord]) y en
/// `PortalSyncService.refreshAfterImport` ([reload]); y se vacía (sin volver a
/// pedir) en `AuthService.logout()` ([clear], TT06: invalida TODAS las cachés
/// por-usuario al cerrar sesión, con guarda `Get.isRegistered` porque no todas
/// las pruebas que llaman a `logout()` registran este servicio).
///
/// **Guarda por dueño, además del logout.** [record] igual descarta el estado
/// de cualquier usuario que no sea el actual, y [load] descarta el estado ajeno
/// antes del primer `await`: así una cuenta nueva en el mismo dispositivo nunca
/// ve el récord de la anterior aunque, por lo que sea, `AuthService.logout()`
/// no se hubiera llegado a llamar.
///
/// Un docente nunca dispara el `GET` ni el `DELETE`: para él la ruta responde
/// 403 (RF-REC-1).
class AcademicRecordService extends GetxService {
  AcademicRecordService({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  static AcademicRecordService get to => Get.find();

  /// `ApiClient` no impone timeout (`_send` llama a `request.send()` sin
  /// `.timeout()`): sin esto, la tarjeta del Perfil se quedaría cargando para
  /// siempre si el backend no responde.
  static const Duration loadTimeout = Duration(seconds: 15);
  static const Duration deleteTimeout = Duration(seconds: 15);

  /// Mensaje que la pantalla muestra cuando el `DELETE` falla.
  static const String deleteErrorMessage =
      'No se pudo borrar tu récord. Inténtalo de nuevo.';

  final ApiClient _api;
  final Rxn<AcademicRecord> _record = Rxn<AcademicRecord>();
  final RxBool _loading = false.obs;
  final RxBool _hasError = false.obs;

  /// Alumno dueño del estado, o de la carga en vuelo.
  String? _ownerCode;

  /// Sube con cada [clear] y con cada carga nueva. Una respuesta que vuelve
  /// con otro número es vieja y se descarta.
  int _generation = 0;

  /// Carga en vuelo: dos [load] seguidos comparten un solo `GET`.
  Future<void>? _inFlight;

  /// El récord del usuario actual, o null si todavía no hay una copia cargada
  /// para él. Con [AcademicRecord.hasRecord] en false es el estado vacío
  /// (nunca sincronizó, o borró su récord).
  AcademicRecord? get record {
    // El Rx se lee SIEMPRE primero: así el Obx que llama a este getter se
    // suscribe aunque después se devuelva null.
    final r = _record.value;
    final code = AuthService.to.currentUser?.code;
    return (code != null && code == _ownerCode) ? r : null;
  }

  /// A diferencia de [record], no están filtrados por dueño: por eso
  /// `AuthService.logout()` llama a [clear] en vez de confiar solo en la
  /// guarda de [load]. Sin eso, la cuenta nueva podría ver un frame del
  /// estado de carga o de error del alumno anterior antes de su primer
  /// `load()`.
  bool get isLoading => _loading.value;
  bool get hasError => _hasError.value;

  /// Olvida el récord y descarta la carga en vuelo.
  void clear() {
    _generation++;
    _inFlight = null;
    _ownerCode = null;
    _record.value = null;
    _hasError.value = false;
    _loading.value = false;
  }

  /// Pide `GET /academic-record/me`. Nunca lanza: un fallo queda en
  /// [hasError]. Sin usuario o con un docente no hace nada. Sin [force] es
  /// idempotente por usuario: si ya hay récord o una carga en vuelo, no
  /// vuelve a pedir.
  Future<void> load({bool force = false}) {
    final user = AuthService.to.currentUser;
    if (user == null || user.isTeacher) return Future<void>.value();
    // Otro usuario sin logout de por medio: su estado se descarta ANTES de
    // cualquier await.
    if (_ownerCode != user.code) clear();
    if (!force && _record.value != null) return Future<void>.value();
    if (!force && _inFlight != null) return _inFlight!;
    _ownerCode = user.code;
    final generation = ++_generation;
    return _inFlight = _fetch(generation);
  }

  Future<void> _fetch(int generation) async {
    _loading.value = true;
    _hasError.value = false;
    try {
      final json =
          await _api.getJson('/academic-record/me').timeout(loadTimeout);
      if (generation != _generation) return;
      _record.value = AcademicRecord.fromJson(json);
    } catch (e) {
      if (generation != _generation) return;
      // ApiException, fallo de red crudo (ApiClient no lo envuelve) o plazo
      // vencido. No se propaga: la tarjeta y la pantalla muestran su estado
      // de error y ofrecen reintentar.
      debugPrint('Error cargando el récord académico: $e');
      _hasError.value = true;
    } finally {
      if (generation == _generation) {
        _loading.value = false;
        _inFlight = null;
      }
    }
  }

  /// Vacía el estado y lo vuelve a pedir. Mientras llega, [record] es null:
  /// nadie ve el PPA ni los créditos anteriores (RF-REC-5).
  Future<void> reload() {
    clear();
    return load(force: true);
  }

  /// `DELETE /academic-record/me`. Si falla, lanza [AcademicRecordFailure]
  /// con [deleteErrorMessage] y el récord no cambia. Si sale bien, [record]
  /// pasa al instante a [AcademicRecord.empty] y se recarga para confirmarlo.
  Future<void> deleteRecord() async {
    final user = AuthService.to.currentUser;
    if (user == null || user.isTeacher) return;
    try {
      await _api.deleteJson('/academic-record/me').timeout(deleteTimeout);
    } catch (e) {
      // ApiException, fallo de red crudo o plazo vencido: para el alumno es
      // lo mismo.
      debugPrint('Error borrando el récord académico: $e');
      throw const AcademicRecordFailure(deleteErrorMessage);
    }
    // El backend ya no tiene copia: el estado vacío se muestra al instante y
    // la recarga lo confirma (RF-REC-5). Se descarta cualquier carga en
    // vuelo, que traería el récord recién borrado.
    _generation++;
    _inFlight = null;
    _ownerCode = user.code;
    _record.value = AcademicRecord.empty;
    _hasError.value = false;
    _loading.value = false;
    // load() nunca lanza: si esta recarga falla, record sigue siendo
    // AcademicRecord.empty (no null) y la pantalla se queda en el estado vacío.
    await load(force: true);
  }
}

/// Fallo del borrado, con un mensaje ya listo para mostrar.
class AcademicRecordFailure implements Exception {
  const AcademicRecordFailure(this.message);

  final String message;

  @override
  String toString() => 'AcademicRecordFailure: $message';
}
