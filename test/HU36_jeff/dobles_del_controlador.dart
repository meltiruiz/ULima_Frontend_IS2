// test/HU36_jeff/dobles_del_controlador.dart
//
// Dobles del controlador del test de especialidad (HU36). No es un archivo
// de pruebas.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_logic.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';

/// Un `AuthService` con usuario cuyo `completeSetup` no sale a la red. Cada
/// guardado toma la siguiente respuesta de [respuestasDeGuardado], donde null
/// guarda, un Completer espera y cualquier otra cosa se lanza. Al guardar
/// pone al día el usuario como el real.
class AuthDelControlador extends AuthService {
  AuthDelControlador(UserModel user) : userRx = Rx<UserModel?>(user);

  final Rx<UserModel?> userRx;
  final List<Object?> respuestasDeGuardado = <Object?>[];
  final List<SeleccionDeEspecialidades> guardados =
      <SeleccionDeEspecialidades>[];
  final List<Duration?> plazos = <Duration?>[];

  @override
  UserModel? get currentUser => userRx.value;

  @override
  Rx<UserModel?> get currentUserRx => userRx;

  @override
  Future<void> refreshCurrentUser() async {}

  @override
  Future<void> completeSetup({
    required int careerId,
    int? especialidadPrincipal,
    required List<int> especialidadesInteres,
    Duration? timeout,
  }) async {
    guardados.add(
      SeleccionDeEspecialidades(
        principal: especialidadPrincipal,
        intereses: List<int>.of(especialidadesInteres),
      ),
    );
    plazos.add(timeout);
    final respuesta = respuestasDeGuardado.isEmpty
        ? null
        : respuestasDeGuardado.removeAt(0);
    if (respuesta is Completer<void>) {
      await respuesta.future;
    } else if (respuesta != null) {
      throw respuesta;
    }
    final user = userRx.value!;
    user.especialidadPrincipal = especialidadPrincipal;
    user.especialidadesInteres = especialidadesInteres
        .where((id) => id != especialidadPrincipal)
        .toList();
    user.setupComplete = true;
    userRx.refresh();
  }
}

/// La pantalla falsa, que anota lo que el controlador le pide.
class UiFalsa implements SpecialtyTestUi {
  final List<SalidaDelTest?> cierres = <SalidaDelTest?>[];
  int alHome = 0;
  final List<AvisoDelTest> avisos = <AvisoDelTest>[];
  final List<String> reinicios = <String>[];

  /// Si no es null, el diálogo de reinicio espera a que se complete.
  Completer<void>? dialogo;

  @override
  void cerrar([SalidaDelTest? salida]) => cierres.add(salida);

  @override
  void irAlHome() => alHome++;

  @override
  void avisar(AvisoDelTest aviso) => avisos.add(aviso);

  @override
  Future<void> pedirReinicio(String mensaje) {
    reinicios.add(mensaje);
    return dialogo?.future ?? Future<void>.value();
  }
}

/// Registra el usuario, el service sobre [api] y, si se pide, la precarga.
({AuthDelControlador auth, SpecialtyTestService service}) prepararTest(
  ApiFalsaDelTest api, {
  UserModel? usuario,
}) {
  final auth = AuthDelControlador(usuario ?? alumno());
  Get.put<AuthService>(auth);
  final service = Get.put<SpecialtyTestService>(
    SpecialtyTestService(apiClient: api),
  );
  return (auth: auth, service: service);
}

/// Crea el controlador como lo haría su binding y deja correr la carga.
Future<SpecialtyTestController> montarControlador({
  OrigenDelTest origen = OrigenDelTest.asistente,
  UiFalsa? ui,
}) async {
  final c = Get.put<SpecialtyTestController>(
    SpecialtyTestController(origen: origen, ui: ui ?? UiFalsa()),
  );
  await pumpEventQueue();
  return c;
}

/// Responde en orden cada paso con [valores], sin la pausa de 350 ms.
void responderPasos(SpecialtyTestController c, List<String> valores) {
  for (final v in valores) {
    c.responder(v, avanceSolo: false);
    c.avanzar();
  }
}

/// Las respuestas de [respuestasCompletas] en el orden de las preguntas.
List<String> get respuestasEnOrden => respuestasCompletas().values.toList();
