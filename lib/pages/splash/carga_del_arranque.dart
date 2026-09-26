// lib/pages/splash/carga_del_arranque.dart
// La carga del arranque como una función que devuelve la ruta de destino y
// corre en paralelo con la intro (RF-SPL-4). Da los mismos pasos que el
// main() de antes y en el mismo orden, salvo las alertas del alumno, que
// pide HomeController al montarse (decisión S-7). Un fallo antes de registrar
// los servicios deja la intro en su bucle (RF-SPL-18).

import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../firebase_options.dart';
import '../../services/academic_record_service.dart';
import '../../services/alert_service.dart';
import '../../services/auth_service.dart';
import '../../services/malla_service.dart';
import '../../services/post_login_route.dart';
import '../../services/recarga_ulima_service.dart';
import '../../services/specialty_test_service.dart';
import '../../services/storage_service.dart';
import '../../services/time_blocks_service.dart';
import 'capa_de_arranque.dart';

Future<void> _iniciarFirebase() =>
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

Future<String> cargarElArranque({
  Future<void> Function()? iniciarFirebase,
}) async {
  try {
    await (iniciarFirebase ?? _iniciarFirebase)();
    LucideIcons.info.codePoint;
    await Get.putAsync<StorageService>(
      () => StorageService().init(),
      permanent: true,
    );
  } catch (error) {
    throw FalloAntesDeLosServicios(error);
  }
  registrarLosServicios();
  final restaurada = await AuthService.to.tryRestoreSession();
  if (!restaurada) return '/login';
  return postLoginRoute(AuthService.to.currentUser!);
}

/// Los servicios globales permanentes, en el orden de siempre.
void registrarLosServicios() {
  Get.put<AuthService>(AuthService(), permanent: true);
  Get.put<AlertService>(AlertService(), permanent: true);
  Get.put<MallaService>(MallaService(), permanent: true);
  // Estado único del récord (RF-REC-5), compartido por la tarjeta del Perfil
  // y /mi-record. No carga nada al arrancar.
  Get.put<AcademicRecordService>(AcademicRecordService(), permanent: true);
  // Estado único de la recarga desde la ULima (RF-RCG-1), compartido por la
  // calculadora, /mis-notas y la ficha del curso. No carga nada al arrancar.
  Get.put<RecargaUlimaService>(RecargaUlimaService(), permanent: true);
  // Estado único de los bloques de horario propios (RF-BLQ-7). Tampoco carga
  // nada al arrancar.
  Get.put<TimeBlocksService>(TimeBlocksService(), permanent: true);
  // Capa de datos del test de especialidad (RF-TEST-2). Permanente porque
  // guarda en memoria la copia del contenido de la sesión, un test en pausa
  // y el último resultado. Tampoco carga nada al arrancar.
  Get.put<SpecialtyTestService>(SpecialtyTestService(), permanent: true);
}

/// En web no hay intro y la ruta inicial es la de la carga, salvo el alumno
/// sin especialidad, que arranca en la bienvenida (RF-SPL-12 y S-22).
String rutaInicialEnWeb(String ruta) =>
    ruta == '/setup-carrera' ? '/login' : ruta;
