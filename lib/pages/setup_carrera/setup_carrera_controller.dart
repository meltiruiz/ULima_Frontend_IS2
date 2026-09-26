import 'package:get/get.dart';

import '../../services/auth_service.dart';
import '../../services/specialty_test_service.dart';
import '../specialty_test/specialty_test_controller.dart';
import '../specialty_test/specialty_test_logic.dart';
import '../specialty_test/specialty_test_page.dart';

/// Los pasos del asistente (RF-TEST-1). El test es una ruta aparte,
/// `/test-especialidad`, que se abre sobre el paso de carrera.
enum SetupStep { carrera, seleccion }

class SetupCarreraController extends GetxController {
  /// [abrirTest] solo lo pasan las pruebas. El asistente abre la ruta del
  /// test con el origen `asistente` y espera su salida.
  SetupCarreraController({Future<Object?> Function()? abrirTest})
    : _abrirTest = abrirTest ?? _abrirLaRutaDelTest;

  static Future<Object?> _abrirLaRutaDelTest() => Get.toNamed<Object?>(
    SpecialtyTestPage.ruta,
    arguments: SpecialtyTestPage.argumentos(OrigenDelTest.asistente),
  )!;

  final Future<Object?> Function() _abrirTest;

  final step = SetupStep.carrera.obs;
  final selectedPrincipal = RxnInt();
  final selectedInteres = <int>{}.obs;
  final saving = false.obs;
  final errorMessage = RxnString();

  AuthService get _auth => AuthService.to;

  String get selectedCarreraName => _auth.getCareerName(selectedCarreraId);

  int? get selectedCarreraId => _auth.currentUser?.careerId;

  /// El último intento de cargar los catálogos falló (RF-TEST-14).
  bool get catalogoFallido => _auth.catalogsFailed;

  List<Map<String, dynamic>> get especialidadesDisponibles {
    final cId = selectedCarreraId;
    if (cId == null) return const [];
    // El filtro `is_active` se queda como defensa (RF-TEST-14).
    final list = _auth.especialidades
        .where((e) => e['carrera_id'] == cId && e['is_active'] == true)
        .toList();
    list.sort((a, b) {
      final oA = (a['display_order'] as num?)?.toInt() ?? 999;
      final oB = (b['display_order'] as num?)?.toInt() ?? 999;
      return oA.compareTo(oB);
    });
    return list;
  }

  @override
  void onInit() {
    super.onInit();
    _cargarSeleccionOficial();
    // La precarga del test, una sola vez al montarse (RF-TEST-1). Un fallo
    // no se muestra en el paso de carrera.
    if (Get.isRegistered<SpecialtyTestService>()) {
      SpecialtyTestService.to.prefetchContent();
    }
  }

  /// La selección del alumno, solo con ids oficiales (RF-TEST-14).
  void _cargarSeleccionOficial() {
    final u = _auth.currentUser;
    final seleccion = seleccionOficial(
      principal: u?.especialidadPrincipal,
      intereses: u?.especialidadesInteres ?? const <int>[],
      oficiales: _auth.officialSpecialtyIds,
    );
    selectedPrincipal.value = seleccion.principal;
    selectedInteres.assignAll(seleccion.intereses);
  }

  /// «Continuar» del paso de carrera abre el test. Saltarlo, o un test no
  /// disponible, deja la selección manual, y la pausa y el atrás dejan al
  /// alumno aquí. Elegir o decidir después terminan el asistente desde la
  /// ruta del test.
  Future<void> continuar() async {
    final salida = await _abrirTest();
    if (isClosed) return;
    if (salida == SalidaDelTest.seleccionManual) irASeleccion();
  }

  void irASeleccion() {
    _cargarSeleccionOficial();
    step.value = SetupStep.seleccion;
  }

  /// El atrás del sistema en la selección manual.
  void volverACarrera() => step.value = SetupStep.carrera;

  /// «Reintentar» de los estados de catálogo. Tras cargar, vuelve a leer la
  /// selección oficial.
  Future<void> reintentarCatalogos() async {
    if (await _auth.reloadCatalogs()) _cargarSeleccionOficial();
  }

  void setPrincipal(int id) {
    if (selectedPrincipal.value == id) {
      selectedPrincipal.value = null;
    } else {
      selectedPrincipal.value = id;
      selectedInteres.remove(id);
    }
  }

  void toggleInteres(int id) {
    if (selectedPrincipal.value == id) return;
    if (selectedInteres.contains(id)) {
      selectedInteres.remove(id);
    } else {
      selectedInteres.add(id);
    }
  }

  Future<void> finish() async {
    errorMessage.value = null;
    final cId = selectedCarreraId;
    if (cId == null) {
      errorMessage.value = 'No se pudo determinar tu carrera.';
      return;
    }
    saving.value = true;
    try {
      await _auth.completeSetup(
        careerId: cId,
        especialidadPrincipal: selectedPrincipal.value,
        especialidadesInteres: selectedInteres.toList(),
      );
      Get.offAllNamed('/home');
    } catch (e) {
      errorMessage.value = 'No pudimos guardar la configuración: $e';
    } finally {
      saving.value = false;
    }
  }
}
