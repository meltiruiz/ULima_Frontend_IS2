// lib/pages/time_blocks/time_block_form_controller.dart
// RF-BLQ-2: estado del formulario de un bloque propio. El mismo controller
// crea (sin argumento de ruta) y edita (con un TimeBlockRule en Get.arguments).
//
// No habla HTTP: eso es de TimeBlocksService. No valida a mano: eso es de
// time_block_validators.dart. Lo suyo es sostener los seis campos, traducirlos
// al contrato ("HH:MM", "YYYY-MM-DD") y decidir si se guarda.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../configs/course_colors.dart';
import '../../models/time_block_model.dart';
import '../../services/time_blocks_service.dart';
import '../horario/horario_controller.dart';
import 'time_block_conflicts.dart';
import 'time_block_validators.dart';

class TimeBlockFormController extends GetxController {
  TimeBlockFormController({
    TimeBlocksService? service,
    List<Map<String, dynamic>> Function()? secciones,
    String? Function()? finDelCiclo,
  })  : _service = service,
        _secciones = secciones ?? seccionesDelHorario,
        _finDelCiclo = finDelCiclo ?? finDelCicloDelHorario;

  final TimeBlocksService? _service;
  final List<Map<String, dynamic>> Function() _secciones;
  final String? Function() _finDelCiclo;

  /// Solo para fallos que no traen mensaje del servidor. Es el MISMO texto
  /// que ya usa el service (Tarea 1): el alumno no tiene por qué leer dos
  /// versiones del mismo error.
  static const String errorGenerico = TimeBlocksService.genericErrorMessage;

  /// El service se resuelve tarde (no en el constructor) para que el binding
  /// pueda construir el controller antes de que nadie toque `Get.find`.
  TimeBlocksService get service => _service ?? TimeBlocksService.to;

  /// Las clases del alumno, tal como las tiene el horario en pantalla. Si la
  /// pantalla de horario no está montada (el formulario abierto desde una ruta
  /// suelta), no hay clases contra las que cruzar y la lista va vacía.
  ///
  /// `uniqueEnrolledCourses` ya deja fuera las asesorías: son de una fecha
  /// suelta, y compararlas por día de la semana avisaría de un cruce en todas
  /// las semanas.
  static List<Map<String, dynamic>> seccionesDelHorario() =>
      Get.isRegistered<HorarioController>()
          ? Get.find<HorarioController>().uniqueEnrolledCourses
          : const <Map<String, dynamic>>[];

  /// El último día del ciclo visible, `"YYYY-MM-DD"`: el último `isoDate` no
  /// nulo de los días del horario en pantalla, el mismo extremo de la ventana
  /// de bloques (RF-BLQ-7). null si la pantalla de horario no está montada o
  /// si ningún día trae `isoDate` (el ciclo sin semanas).
  static String? finDelCicloDelHorario() {
    if (!Get.isRegistered<HorarioController>()) return null;
    final dias = Get.find<HorarioController>().daysList;
    for (var i = dias.length - 1; i >= 0; i--) {
      final iso = dias[i].isoDate;
      if (iso != null) return iso;
    }
    return null;
  }

  /// `#RRGGBB` en mayúsculas, que es lo que pide el contrato.
  static String hexDeColor(Color color) =>
      '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  static String fmtHora(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static String fmtFecha(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static TimeOfDay? horaDeTexto(String? hhmm) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch((hhmm ?? '').trim());
    if (m == null) return null;
    final h = int.parse(m.group(1)!);
    final min = int.parse(m.group(2)!);
    if (h > 23 || min > 59) return null;
    return TimeOfDay(hour: h, minute: min);
  }

  static DateTime? fechaDeTexto(String? yyyymmdd) =>
      DateTime.tryParse((yyyymmdd ?? '').trim());

  final nombre = TextEditingController();
  final colorHex = ''.obs;
  final dias = <int>{}.obs;
  final inicio = Rxn<TimeOfDay>();
  final fin = Rxn<TimeOfDay>();
  final desde = Rxn<DateTime>();
  final hasta = Rxn<DateTime>();

  final guardando = false.obs;
  final errorMessage = RxnString();

  TimeBlockRule? _bloque;

  /// El bloque que se está editando, o null si se está creando.
  TimeBlockRule? get bloque => _bloque;
  bool get editando => _bloque != null;

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg is TimeBlockRule) {
      _bloque = arg;
      nombre.text = arg.title;
      colorHex.value = arg.colorHex.toUpperCase();
      dias.assignAll(arg.daysOfWeek);
      inicio.value = horaDeTexto(arg.startTime);
      fin.value = horaDeTexto(arg.endTime);
      desde.value = fechaDeTexto(arg.startDate);
      hasta.value = fechaDeTexto(arg.endDate);
    } else {
      colorHex.value = hexDeColor(kCoursePalette.first);
    }
  }

  String? get inicioTexto =>
      inicio.value == null ? null : fmtHora(inicio.value!);
  String? get finTexto => fin.value == null ? null : fmtHora(fin.value!);
  String? get desdeTexto =>
      desde.value == null ? null : fmtFecha(desde.value!);
  String? get hastaTexto =>
      hasta.value == null ? null : fmtFecha(hasta.value!);

  /// Dónde abre el selector de «Hasta» (RF-BLQ-2). Solo eso: no llena el
  /// campo.
  ///
  /// Si ya tiene fecha, en esa. Si no, en el último día del ciclo visible
  /// ([finDelCicloDelHorario]) cuando no es anterior a «Desde» (o a [hoy], si
  /// «Desde» sigue vacío). Sin ciclo con fechas, o con el ciclo ya terminado
  /// para esa fecha, en «Desde» (o [hoy]) más 6 días. Antes abría en «Desde»,
  /// y aceptar los dos selectores sin moverlos dejaba un bloque de un solo
  /// día, que casi nunca es uno de los marcados.
  DateTime fechaInicialDeHasta(DateTime hoy) {
    final elegida = hasta.value;
    if (elegida != null) return elegida;
    final base = _soloFecha(desde.value ?? hoy);
    final fin = fechaDeTexto(_finDelCiclo());
    if (fin != null && !_soloFecha(fin).isBefore(base)) return _soloFecha(fin);
    // Por calendario y no con Duration: 6 días de 24 h pueden no ser 6 días
    // si en medio cambia la hora del dispositivo.
    return DateTime(base.year, base.month, base.day + 6);
  }

  static DateTime _soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Deja el mensaje del validador en [errorMessage] y dice si se puede seguir.
  bool validar() {
    final mensaje = validarFormulario(
      nombre: nombre.text,
      dias: dias.toSet(),
      inicio: inicioTexto,
      fin: finTexto,
      desde: desdeTexto,
      hasta: hastaTexto,
    );
    errorMessage.value = mensaje;
    return mensaje == null;
  }

  /// Cruces del bloque tal como está ahora, contra las clases en pantalla y
  /// contra los demás bloques del alumno. Al editar, el propio bloque no cuenta.
  List<Cruce> cruces() {
    final i = inicioTexto;
    final f = finTexto;
    if (i == null || f == null || dias.isEmpty) return const <Cruce>[];
    return crucesDeBloque(
      dias: dias.toSet(),
      inicio: i,
      fin: f,
      secciones: _secciones(),
      bloques: service.blocks,
      ignorarBloqueId: _bloque?.id,
      // Un bloque propio de otro rango de fechas nunca coincide con este.
      desde: desdeTexto,
      hasta: hastaTexto,
    );
  }

  /// Crea o edita. Devuelve true solo si el servidor aceptó. Un error del
  /// servidor se muestra TAL CUAL llega (RF-BLQ-2): no se reescribe acá.
  Future<bool> guardar() async {
    if (!validar()) return false;
    guardando.value = true;
    try {
      final input = TimeBlockInput(
        title: nombre.text.trim(),
        colorHex: colorHex.value,
        daysOfWeek: dias.toList()..sort(),
        startTime: inicioTexto!,
        endTime: finTexto!,
        startDate: desdeTexto!,
        endDate: hastaTexto!,
      );
      final actual = _bloque;
      if (actual == null) {
        await service.create(input);
      } else {
        await service.update(actual.id, input);
      }
      return true;
    } on TimeBlocksFailure catch (e) {
      errorMessage.value = e.message;
      return false;
    } catch (e) {
      // Red de seguridad: el service envuelve sus errores en
      // TimeBlocksFailure, pero si algo se le escapa el alumno tiene que ver
      // un mensaje y no un botón que no hace nada.
      debugPrint('Error guardando el bloque: $e');
      errorMessage.value = errorGenerico;
      return false;
    } finally {
      guardando.value = false;
    }
  }

  @override
  void onClose() {
    nombre.dispose();
    super.onClose();
  }
}
