// lib/services/recarga_ulima_service.dart
//
// Única frontera de la app con `GET /grades/me/ulima` y
// `POST /portal-sync/refresh` (RF-RCG-1 de
// specs/features/recarga-portal/recarga-portal.spec.md). Es permanente porque
// la calculadora, `/mis-notas` y la ficha del curso comparten su estado.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../domain/recarga_ulima/avisos_recarga.dart';
import '../models/recarga_ulima_models.dart';
import '../pages/horario/horario_controller.dart';
import 'api_client.dart';
import 'auth_service.dart';

/// Estado de la recarga desde la ULima.
///
/// **La contraseña y el código no se guardan.** Llegan como parámetros de
/// [recargar] y se descartan al volver. Nunca entran en un `Rx`, en
/// `shared_preferences`, en `flutter_secure_storage` ni en un `debugPrint`, y
/// el cuerpo de la petición nunca se imprime.
///
/// **Dueño de los datos.** El estado se ata al alumno que lo pide, como en
/// `AcademicRecordService`. Los getters filtran por dueño, [cargar] y
/// [recargar] descartan el estado ajeno antes de cualquier `await`, y una
/// respuesta que vuelve después de un [clear] se descarta. Así el siguiente
/// alumno del mismo teléfono no ve nada del anterior, aunque el JWT caduque
/// sin pasar por `AuthService.logout()`.
class RecargaUlimaService extends GetxService {
  RecargaUlimaService({ApiClient? apiClient, Duration? plazo})
    : _api = apiClient ?? ApiClient(),
      plazo = plazo ?? plazoRecarga;

  static RecargaUlimaService get to => Get.find();

  /// Plazo de la app para la recarga, el mismo de la importación (D18).
  static const Duration plazoRecarga = Duration(seconds: 90);

  /// Plazo de `GET /grades/me/ulima`, que no entra al portal.
  static const Duration plazoCarga = Duration(seconds: 15);

  final ApiClient _api;

  /// El plazo de esta instancia. Las pruebas lo acortan.
  final Duration plazo;

  final Rxn<VistaUlima> _vista = Rxn<VistaUlima>();
  final Rxn<AvisoRecarga> _ultimoAviso = Rxn<AvisoRecarga>();
  final RxBool _errorCarga = false.obs;
  final RxBool _enviando = false.obs;

  /// Estados por curso del último `200`, por `sectionId` como texto, o `null`
  /// si no hay un resultado con estados.
  final Rxn<Map<String, EstadoCursoRecarga>> _estados =
      Rxn<Map<String, EstadoCursoRecarga>>();

  /// Código del alumno dueño del estado.
  String? _ownerCode;

  /// Sube con cada [clear]. Una respuesta que vuelve con otro número se
  /// descarta.
  int _generacion = 0;

  /// La vista que hay al enviar la recarga que termina en el aviso del plazo
  /// o de la red, o `null` si no había ninguna (D23).
  VistaUlima? _vistaAlEnviar;

  /// La recarga del horario que corre tras una recarga guardada (RF-RCG-3).
  /// Es la única llamada a `HorarioController.reload()` de la recarga, y la
  /// ficha del curso la espera en vez de repetirla.
  Future<void>? recargaHorario;

  bool get _esDelActual {
    final code = AuthService.to.currentUser?.code;
    return code != null && code == _ownerCode;
  }

  /// La vista del alumno actual, o `null`. El `Rx` se lee primero para que el
  /// `Obx` que llama se suscriba aunque después se devuelva `null`.
  VistaUlima? get vista {
    final v = _vista.value;
    return _esDelActual ? v : null;
  }

  /// El aviso rojo de la última recarga fallida del alumno actual.
  AvisoRecarga? get ultimoAviso {
    final a = _ultimoAviso.value;
    return _esDelActual ? a : null;
  }

  /// Si la última carga de la vista termina en error. No borra la vista
  /// anterior.
  bool get errorCarga {
    final e = _errorCarga.value;
    return _esDelActual && e;
  }

  /// Hay una recarga en vuelo.
  bool get enviando => _enviando.value;

  /// Si el último resultado con estados no trae las notas de [sectionId]
  /// como leídas (RF-RCG-3).
  bool sinLecturaDeNotas(Object sectionId) {
    final estados = _estados.value;
    if (!_esDelActual || estados == null) return false;
    return estados['$sectionId']?.grades != 'read';
  }

  /// Si el último resultado con estados no trae la asistencia de
  /// [sectionId] como actualizada (RF-RCG-3 y RF-RCG-8).
  bool sinLecturaDeAsistencia(Object sectionId) {
    final estados = _estados.value;
    if (!_esDelActual || estados == null) return false;
    return estados['$sectionId']?.attendance != 'updated';
  }

  /// Llama a [alCambiar] con cada cambio de la vista, sin exponer el `Rx`.
  /// Quien lo pide cierra el `Worker`.
  Worker alCambiarVista(void Function() alCambiar) =>
      ever<VistaUlima?>(_vista, (_) => alCambiar());

  /// Vacía todo y descarta lo que esté en vuelo.
  void clear() {
    _generacion++;
    _ownerCode = null;
    _vista.value = null;
    _ultimoAviso.value = null;
    _errorCarga.value = false;
    _enviando.value = false;
    _estados.value = null;
    _vistaAlEnviar = null;
    recargaHorario = null;
  }

  /// Borra el aviso rojo, como pide «Cargar mis datos» (RF-RCG-4).
  void borrarAviso() {
    _ultimoAviso.value = null;
    _vistaAlEnviar = null;
  }

  /// Toma como dueño al alumno actual, o devuelve `false` si no hay uno que
  /// pueda usar la recarga. Descarta el estado ajeno antes de cualquier
  /// `await`.
  bool _tomarDueno() {
    final user = AuthService.to.currentUser;
    if (user == null || user.isTeacher) return false;
    if (_ownerCode != user.code) clear();
    _ownerCode = user.code;
    return true;
  }

  /// Si [despues] trae una `lastReadAt` posterior a la de [antes], o una
  /// donde [antes] tenía `null` (D23). Sin [antes], porque no había vista
  /// al enviar, nada cuenta como avance, ya que la hora de una recarga
  /// anterior no se distingue de la de esta.
  static bool _avanzo(VistaUlima? antes, VistaUlima? despues) {
    if (antes == null) return false;
    final base = antes.lastReadAt;
    final nueva = despues?.lastReadAt;
    return nueva != null && (base == null || nueva.isAfter(base));
  }

  /// Pide `GET /grades/me/ulima`. Nunca lanza. Un fallo no borra la vista
  /// que ya hay y deja [errorCarga] en verdadero hasta la siguiente carga
  /// buena.
  Future<void> cargar() async {
    if (!_tomarDueno()) return;
    final generacion = _generacion;
    try {
      final json = await _api.getJson('/grades/me/ulima').timeout(plazoCarga);
      if (generacion != _generacion) return;
      final nueva = VistaUlima.fromJson(json);
      _vista.value = nueva;
      _errorCarga.value = false;
      // D23. La recarga que vence el plazo o falla por la red sí queda
      // guardada.
      final aviso = _ultimoAviso.value;
      if (aviso != null &&
          aviso.esperaLectura &&
          _avanzo(_vistaAlEnviar, nueva)) {
        _ultimoAviso.value = null;
        _vistaAlEnviar = null;
        _recargarHorario();
      }
    } catch (e) {
      if (generacion != _generacion) return;
      debugPrint(
        'No se pudieron cargar las notas de la ULima: '
        '${e.runtimeType}',
      );
      _errorCarga.value = true;
    }
  }

  void _recargarHorario() {
    recargaHorario = Get.isRegistered<HorarioController>()
        ? Get.find<HorarioController>().reload()
        : null;
  }

  /// Recarga notas y asistencia con un solo inicio de sesión en miUlima
  /// (`POST /portal-sync/refresh`, RF-RCG-1 y RF-RCG-3).
  ///
  /// Devuelve `true` si la recarga queda guardada, con un `200` o con la
  /// lectura posterior de D23. Con un error deja el aviso de RF-RCG-4 en
  /// [ultimoAviso] y devuelve `false`. Una segunda llamada mientras hay otra
  /// en vuelo no hace nada y devuelve `false`. Sin vista cargada, llama antes
  /// a [cargar] para tener la base de D23.
  Future<bool> recargar({
    required String password,
    required String passcode,
  }) async {
    if (_enviando.value) return false;
    if (!_tomarDueno()) return false;
    final generacion = _generacion;
    _enviando.value = true;
    _ultimoAviso.value = null;
    _vistaAlEnviar = null;
    _estados.value = null;
    VistaUlima? vistaAntes;
    try {
      // D23. Sin vista no hay con qué comparar la lectura que sigue a un
      // plazo vencido, así que se pide antes del envío.
      if (_vista.value == null) {
        await cargar();
        if (generacion != _generacion) return false;
      }
      vistaAntes = _vista.value;
      final json = await _api
          .postJson(
            '/portal-sync/refresh',
            body: {
              'credentials': {'password': password, 'passcode': passcode},
              'consent': true,
            },
          )
          .timeout(plazo);
      if (generacion != _generacion) return false;
      final resultado = ResultadoRecarga.fromJson(json);
      _vista.value = resultado.view;
      _errorCarga.value = false;
      _estados.value = {for (final e in resultado.estados) '${e.sectionId}': e};
      _recargarHorario();
      return true;
    } on ApiException catch (e) {
      if (generacion != _generacion) return false;
      // El 401 es la expiración del JWT y la maneja ApiClient, que cierra la
      // sesión. El backend nunca responde 401 por un fallo del portal.
      if (e.statusCode != 401) {
        _ultimoAviso.value = avisoDeError(e.code, details: e.details);
      }
      return false;
    } on TimeoutException {
      return _trasPlazoORed(avisoPlazo, vistaAntes, generacion);
    } catch (_) {
      // ApiClient propaga los fallos de red sin envolverlos.
      return _trasPlazoORed(avisoSinRed, vistaAntes, generacion);
    } finally {
      if (generacion == _generacion) _enviando.value = false;
    }
  }

  /// El backend puede terminar y escribir después de que la app deja de
  /// esperar, así que se vuelve a pedir la vista antes de decidir (D23).
  Future<bool> _trasPlazoORed(
    AvisoRecarga aviso,
    VistaUlima? vistaAntes,
    int generacion,
  ) async {
    if (generacion != _generacion) return false;
    await cargar();
    if (generacion != _generacion) return false;
    if (_avanzo(vistaAntes, _vista.value)) {
      // Como un 200, pero sin estados por curso.
      _recargarHorario();
      return true;
    }
    _ultimoAviso.value = aviso;
    _vistaAlEnviar = vistaAntes;
    return false;
  }
}
