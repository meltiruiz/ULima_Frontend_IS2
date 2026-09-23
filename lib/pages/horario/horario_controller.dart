import 'dart:async';
import 'package:flutter/material.dart';
import '../../configs/course_colors.dart';

import 'package:get/get.dart';

import '../../models/time_block_model.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/time_blocks_service.dart';
import '../time_blocks/time_block_conflicts.dart' show numeroDeDia;

class DaySchedule {
  final String dayName;
  final String dateText;
  final String weekText;

  /// La fecha exacta de ese día en hora de Lima, `"YYYY-MM-DD"`, o null
  /// cuando el ciclo no tiene semanas (el mismo caso en que [dateText] llega
  /// vacío). La manda `/schedule/me/sessions` (D1). De aquí, y nunca de
  /// [dateText], salen las fechas de los bloques propios (RF-BLQ-4 y
  /// RF-BLQ-7): [dateText] no trae año.
  final String? isoDate;

  DaySchedule(this.dayName, this.dateText, this.weekText, {this.isoDate});

  /// Un elemento de `days` de `/schedule/me/sessions`. Los tres textos se
  /// leen como siempre; [isoDate] queda en null si no llega (un backend
  /// anterior) o si no es una fecha `YYYY-MM-DD` que existe.
  factory DaySchedule.fromJson(Map<String, dynamic> json) => DaySchedule(
    json['dayName'] as String,
    json['dateText'] as String,
    json['weekText'] as String,
    isoDate: _fechaIsoONull(json['isoDate']),
  );
}

/// [valor] si es una fecha `YYYY-MM-DD` que existe en el calendario, o null.
/// `DateTime.tryParse` corre el 30 de febrero al 2 de marzo: por eso la vuelta
/// a texto tiene que dar lo mismo.
String? _fechaIsoONull(Object? valor) {
  if (valor is! String) return null;
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(valor)) return null;
  final fecha = DateTime.tryParse('${valor}T00:00:00Z');
  if (fecha == null) return null;
  return HorarioController._fechaPlana(fecha) == valor ? valor : null;
}

class HorarioController extends GetxController {
  final currentDayIndex = 0.obs;
  final daysList = <DaySchedule>[].obs;
  final assessmentsList = <Map<String, dynamic>>[].obs;
  final weeklyLoad = <Map<String, dynamic>>[].obs;
  final currentLimaTime = _nowInLima().obs;

  // Nuevos estados para el rediseño de Horario (Lista / Calendario)
  final isListView = false.obs;

  final _todasLasSecciones = <Map<String, dynamic>>[].obs;
  final ApiClient _api = ApiClient();
  Timer? _clockTimer;

  static const List<String> _months = [
    "Enero",
    "Febrero",
    "Marzo",
    "Abril",
    "Mayo",
    "Junio",
    "Julio",
    "Agosto",
    "Septiembre",
    "Octubre",
    "Noviembre",
    "Diciembre",
  ];

  static DateTime _nowInLima() =>
      DateTime.now().toUtc().subtract(const Duration(hours: 5));

  static String _dateTextFor(DateTime date) =>
      "${date.day} de ${_months[date.month - 1]}";

  @override
  void onInit() {
    super.onInit();
    _startClock();
    final isTeacher = AuthService.to.currentUser?.isTeacher ?? false;
    if (isTeacher) {
      _loadTeacherDaysAndSessions();
      _loadTeacherAssessments();
    } else {
      _cargarDiasYBloques();
      _loadSecciones();
      _loadAssessments();
      _loadWeeklyLoad();
      // En un ciclo de más de 120 días la ventana va desde el lunes de la
      // semana activa (ventanaVisible): al cambiar de semana se pide la
      // nueva. Dentro de la misma semana, load no vuelve a pedir nada.
      _ventanaDeBloques = ever<int>(
        currentDayIndex,
        (_) => _cargarBloquesPropios(),
      );
    }
  }

  /// Recarga los datos del horario (sesiones + evaluaciones).
  /// Llamado por [HomePage] al cambiar al tab del horario para reflejar
  /// asesorías o cambios recientes sin destruir el controller.
  Future<void> reload() async {
    final isTeacher = AuthService.to.currentUser?.isTeacher ?? false;
    if (isTeacher) {
      await Future.wait([
        _loadTeacherDaysAndSessions(),
        _loadTeacherAssessments(),
      ]);
    } else {
      await Future.wait([
        _cargarDiasYBloques(),
        _loadSecciones(),
        _loadAssessments(),
      ]);
    }
  }

  @override
  void onClose() {
    _clockTimer?.cancel();
    _ventanaDeBloques?.dispose();
    super.onClose();
  }

  void _startClock() {
    currentLimaTime.value = _nowInLima();
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      currentLimaTime.value = _nowInLima();
    });
  }

  Future<void> _loadDays() async {
    try {
      final code = AuthService.to.currentUser?.code;
      final data = await _api.getJson(
        '/schedule/me/sessions${code == null ? '' : '?code=$code'}',
      );
      final List<dynamic> decoded = data['days'] ?? [];
      daysList.assignAll(
        decoded
            .map(
              (d) => DaySchedule.fromJson(Map<String, dynamic>.from(d as Map)),
            )
            .toList(),
      );

      // Intentar buscar el día actual por fecha
      final todayStr = _dateTextFor(currentLimaTime.value);

      int idx = daysList.indexWhere(
        (d) => d.dateText.toLowerCase() == todayStr.toLowerCase(),
      );
      if (idx == -1) {
        // Fallback al primer viernes si no se encuentra el día exacto
        idx = daysList.indexWhere((d) => d.dayName == 'Viernes');
      }
      currentDayIndex.value = idx != -1 ? idx : 0;
    } catch (e) {
      debugPrint('Error al cargar dias: $e');
    }
  }

  Future<void> _loadSecciones() async {
    try {
      final code = AuthService.to.currentUser?.code;
      final data = await _api.getJson(
        '/schedule/me/sessions${code == null ? '' : '?code=$code'}',
      );
      _todasLasSecciones.assignAll(
        (data['secciones'] as List? ?? [])
            .map((item) => Map<String, dynamic>.from(item))
            .toList(),
      );
    } catch (e) {
      debugPrint('Error al cargar secciones: $e');
    }
  }

  Future<void> _loadAssessments() async {
    try {
      final code = AuthService.to.currentUser?.code;
      final data = await _api.getJson(
        '/schedule/me/assessments${code == null ? '' : '?code=$code'}',
      );
      assessmentsList.assignAll(
        List<Map<String, dynamic>>.from(data['assessments'] ?? []),
      );
      update();
    } catch (e) {
      debugPrint('Error al cargar evaluaciones: $e');
    }
  }

  Future<void> _loadWeeklyLoad() async {
    try {
      final code = AuthService.to.currentUser?.code;
      final data = await _api.getJson(
        '/schedule/me/load${code == null ? '' : '?code=$code'}',
      );
      weeklyLoad.assignAll(
        (data['weeks'] as List? ?? [])
            .map((item) => Map<String, dynamic>.from(item))
            .toList(),
      );
      update();
    } catch (e) {
      debugPrint('Error al cargar carga semanal: $e');
    }
  }

  Future<void> _loadTeacherDaysAndSessions() async {
    try {
      final data = await _api.getJson('/schedule/teacher/sessions');
      final List<dynamic> decoded = data['days'] ?? [];
      daysList.assignAll(
        decoded
            .map(
              (d) => DaySchedule(
                d['dayName'] as String,
                d['dateText'] as String,
                d['weekText'] as String,
              ),
            )
            .toList(),
      );

      _todasLasSecciones.assignAll(
        (data['secciones'] as List? ?? [])
            .map((item) => Map<String, dynamic>.from(item))
            .toList(),
      );

      final todayStr = _dateTextFor(currentLimaTime.value);
      int idx = daysList.indexWhere(
        (d) => d.dateText.toLowerCase() == todayStr.toLowerCase(),
      );
      if (idx == -1) {
        idx = daysList.indexWhere((d) => d.dayName == 'Viernes');
      }
      currentDayIndex.value = idx != -1 ? idx : 0;
    } catch (e) {
      debugPrint('Error al cargar dias y sesiones del docente: $e');
    }
  }

  Future<void> _loadTeacherAssessments() async {
    try {
      final data = await _api.getJson('/schedule/teacher/assessments');
      assessmentsList.assignAll(
        List<Map<String, dynamic>>.from(data['assessments'] ?? []),
      );
      update();
    } catch (e) {
      debugPrint('Error al cargar evaluaciones del docente: $e');
    }
  }

  DaySchedule? get currentDay =>
      daysList.isEmpty ? null : daysList[currentDayIndex.value];

  bool isCurrentLimaDay(DaySchedule day) =>
      day.dateText.toLowerCase() ==
      _dateTextFor(currentLimaTime.value).toLowerCase();

  double get currentLimaHourDecimal {
    final now = currentLimaTime.value;
    return now.hour + (now.minute / 60.0) + (now.second / 3600.0);
  }

  List<Map<String, dynamic>> get currentDayCourses {
    final activeDay = currentDay;
    if (activeDay == null) return const [];
    return coursesForDay(activeDay);
  }

  List<Map<String, dynamic>> coursesForDay(DaySchedule activeDay) {
    final currentDayName = activeDay.dayName.toLowerCase();
    final courses = <Map<String, dynamic>>[];

    // 1. Agregar las clases regulares
    for (final section in _todasLasSecciones) {
      final horarios = section['horarios'];
      if (horarios is List && horarios.isNotEmpty) {
        for (final rawHorario in horarios) {
          if (rawHorario is! Map) continue;
          final horario = Map<String, dynamic>.from(rawHorario);
          final courseDay = (horario['dia'] as String? ?? '').toLowerCase();
          if (courseDay != currentDayName) continue;

          // Si tiene una fecha (asesorías extra), verificar que coincida con el día activo
          final dateStr = horario['fecha'] as String?;
          if (dateStr != null && dateStr.isNotEmpty) {
            final parsedDate = DateTime.tryParse(dateStr);
            if (parsedDate != null) {
              final dayNum = parsedDate.day;
              final monthIdx = parsedDate.month - 1;
              if (monthIdx >= 0 && monthIdx < 12) {
                final formattedDate = "$dayNum de ${_months[monthIdx]}";
                if (formattedDate.toLowerCase().trim() !=
                    activeDay.dateText.toLowerCase().trim()) {
                  continue;
                }
              }
            }
          }

          courses.add({
            ...section,
            ...horario,
            'isEvaluation': false,
            'isAdvising': section['isAdvising'] == true,
          });
        }
        continue;
      }

      final courseDay = (section['dia'] as String? ?? '').toLowerCase();
      if (courseDay == currentDayName) {
        courses.add({
          ...section,
          'isEvaluation': false,
          'isAdvising': section['isAdvising'] == true,
        });
      }
    }

    // 2. Buscar evaluaciones para este dia y asociarlas a las clases regulares
    for (var course in courses) {
      if (course['isAdvising'] == true) continue;
      final sectionCode = course['codigoSeccion']?.toString().trim() ?? '';
      final courseName = course['curso']?.toString().toLowerCase().trim() ?? '';

      for (final assessment in assessmentsList) {
        final dateStr = assessment['date'] as String? ?? '';
        final parsedDate = DateTime.tryParse(dateStr);
        if (parsedDate != null) {
          final dayNum = parsedDate.day;
          final monthIdx = parsedDate.month - 1;
          if (monthIdx >= 0 && monthIdx < 12) {
            final formattedDate = "$dayNum de ${_months[monthIdx]}";
            final dateMatches =
                formattedDate.toLowerCase().trim() ==
                activeDay.dateText.toLowerCase().trim();

            final evalSectionCode =
                assessment['sectionCode']?.toString().trim() ?? '';
            final evalCourseName =
                assessment['courseName']?.toString().toLowerCase().trim() ?? '';

            final matchesCourse =
                (evalSectionCode.isNotEmpty &&
                    evalSectionCode == sectionCode) ||
                (evalCourseName.isNotEmpty && evalCourseName == courseName);

            if (dateMatches && matchesCourse) {
              course['isEvaluation'] = true;
              course['evalSigla'] = assessment['code'] ?? '';
              course['evalNombre'] = assessment['name'] ?? '';
              debugPrint(
                "--> MERGED! Set isEvaluation = true for course: ${course['curso']} (${assessment['code']})",
              );
              break; // Encontrado para esta clase
            }
          }
        }
      }
    }

    return courses;
  }

  /// Los bloques propios que caen en [dia] (RF-BLQ-4): las ocurrencias que el
  /// servidor ya expandió, filtradas por fecha ([_caeEnElDia]).
  List<TimeBlockOccurrence> bloquesDelDia(DaySchedule dia) {
    final propias = _bloquesPropios;
    if (propias.isEmpty) return const <TimeBlockOccurrence>[];
    return propias.where((o) => _caeEnElDia(o.date, dia)).toList();
  }

  /// Los días cancelados de los bloques propios que caen en [dia] (RF-BLQ-5),
  /// con las horas de su regla y `moved: false`.
  ///
  /// El servidor no manda un día cancelado entre las ocurrencias (RS-BE-33),
  /// pero la regla trae la excepción. La grilla lo pinta tenue, con "Este día
  /// está cancelado", para que la alumna pueda tocarlo y devolverlo al patrón
  /// desde su hoja. Solo cuenta si la fecha sigue en el patrón (uno de sus
  /// días y dentro de su rango): una excepción que quedó fuera al editar la
  /// regla ya no se expande, y tampoco se pinta.
  List<TimeBlockOccurrence> bloquesCanceladosDelDia(DaySchedule dia) {
    final reglas = _reglasPropias;
    if (reglas.isEmpty) return const <TimeBlockOccurrence>[];
    return <TimeBlockOccurrence>[
      for (final regla in reglas)
        for (final excepcion in regla.exceptions)
          if (excepcion.status == 'cancelled' &&
              _enElPatron(regla, excepcion.date) &&
              _caeEnElDia(excepcion.date, dia))
            TimeBlockOccurrence(
              blockId: regla.id,
              title: regla.title,
              colorHex: regla.colorHex,
              date: excepcion.date,
              dayOfWeek: DateTime.parse(excepcion.date).weekday,
              startTime: regla.startTime,
              endTime: regla.endTime,
              moved: false,
            ),
    ];
  }

  /// La ventana de ocurrencias que pide el horario (RF-BLQ-7), como fechas
  /// planas `YYYY-MM-DD`.
  ///
  /// Es la del ciclo visible: del primer al último `isoDate` no nulo de
  /// [daysList], en el orden en que llegan. No se lee nada de `dateText` ni
  /// del ciclo del alumno: `dateText` no trae año, y adivinarlo era frágil.
  ///
  /// Si esa ventana pasa de los 120 días que acepta el servidor
  /// (`TIME_BLOCK_WINDOW_TOO_WIDE`; un ciclo de 16 semanas son 112), son 120
  /// días desde el lunes de la semana del día activo. Al cambiar de semana,
  /// [currentDayIndex] cambia y el `ever` de `onInit` pide la ventana nueva;
  /// dentro de la misma semana es la misma, y `load` no vuelve a pedir nada.
  ///
  /// Si ningún día trae `isoDate` ([daysList] vacío, o el ciclo sin semanas,
  /// que llega con `isoDate` null, `dateText` vacío y "Semana actual"), son
  /// las cuatro semanas de lunes a domingo alrededor de hoy en Lima: la
  /// pasada, la actual y las dos siguientes.
  ({String from, String to}) ventanaVisible() {
    final ciclo = _fechasDelCiclo();
    if (ciclo == null) {
      final desde = _lunesDeEstaSemana().subtract(const Duration(days: 7));
      final hasta = desde.add(const Duration(days: 27));
      return (from: _fechaPlana(desde), to: _fechaPlana(hasta));
    }
    final (primero, ultimo, activo) = ciclo;
    if (ultimo.difference(primero).inDays < _diasMaximosPorVentana) {
      return (from: _fechaPlana(primero), to: _fechaPlana(ultimo));
    }
    final desde = _lunesDe(activo);
    final hasta = desde.add(const Duration(days: _diasMaximosPorVentana - 1));
    return (from: _fechaPlana(desde), to: _fechaPlana(hasta));
  }

  /// Los días que cubre como mucho una ventana, contando los dos extremos: el
  /// tope del servidor (`TIME_BLOCK_WINDOW_TOO_WIDE`).
  static const int _diasMaximosPorVentana = 120;

  /// Si la fecha plana [iso] ("2026-09-21") es la de [dia] ([_fechaDelDia]).
  ///
  /// Compara por FECHA. El nombre del día no basta: [daysList] trae los siete
  /// días de CADA semana del ciclo, y una práctica del lunes 21 no es la del
  /// lunes 28.
  bool _caeEnElDia(String iso, DaySchedule dia) {
    final fecha = _fechaDelDia(dia);
    return fecha != null && iso == _fechaPlana(fecha);
  }

  /// La fecha de [dia] a medianoche UTC: su `isoDate`, la fecha exacta que
  /// manda `/schedule/me/sessions` (D1).
  ///
  /// Si el ciclo no tiene semanas, el backend manda los siete días con
  /// `isoDate` null (y `dateText` vacío, "Semana actual"): no hay fecha, y
  /// por el nombre saldrían los cuatro lunes de la ventana uno al lado del
  /// otro. Se toma ese día de la semana en la semana de hoy, que es lo que
  /// "Semana actual" dice. Con más de siete días sin `isoDate` (un ciclo con
  /// semanas que manda un backend sin RS-BE-36) tampoco hay fecha, y la
  /// semana de hoy saldría en cada semana del ciclo, así que es null y el
  /// bloque se omite. null también si no se reconoce el nombre del día.
  DateTime? _fechaDelDia(DaySchedule dia) {
    final propia = _fechaDeIso(dia.isoDate);
    if (propia != null) return propia;
    // El ciclo sin semanas llega con siete días. Más días sin isoDate vienen
    // de un backend sin RS-BE-36, así que no hay fecha y el bloque se omite.
    if (daysList.length > 7) return null;
    final numero = numeroDeDia(dia.dayName);
    if (numero == null) return null;
    return _lunesDeEstaSemana().add(Duration(days: numero - 1));
  }

  /// Si [fecha] cae en uno de los días de [regla] y dentro de su rango.
  static bool _enElPatron(TimeBlockRule regla, String fecha) {
    final dia = DateTime.tryParse(fecha);
    if (dia == null) return false;
    return regla.daysOfWeek.contains(dia.weekday) &&
        fecha.compareTo(regla.startDate) >= 0 &&
        fecha.compareTo(regla.endDate) <= 0;
  }

  /// La fecha del primer `isoDate` de [daysList], la del último y la del día
  /// activo (la primera, si el activo no trae), o null si ningún día trae
  /// `isoDate`.
  (DateTime, DateTime, DateTime)? _fechasDelCiclo() {
    final dias = daysList;
    // Marcador null-aware (`?`): un día sin isoDate no entra. Con un
    // `if (… case final f?)` el analizador saca `use_null_aware_elements`.
    final fechas = <DateTime>[
      for (final dia in dias) ?_fechaDeIso(dia.isoDate),
    ];
    if (fechas.isEmpty) return null;
    var indice = currentDayIndex.value;
    if (indice < 0 || indice >= dias.length) indice = 0;
    final activo = _fechaDeIso(dias[indice].isoDate) ?? fechas.first;
    return (fechas.first, fechas.last, activo);
  }

  /// `"2026-09-21"` → el 21 de septiembre de 2026 a medianoche UTC, o null.
  /// En UTC para que restar días no tropiece con un cambio de hora del
  /// dispositivo.
  static DateTime? _fechaDeIso(String? iso) =>
      iso == null ? null : DateTime.tryParse('${iso}T00:00:00Z');

  /// El lunes de la semana de [fecha].
  static DateTime _lunesDe(DateTime fecha) =>
      fecha.subtract(Duration(days: fecha.weekday - 1));

  /// El lunes de la semana de hoy en Lima, a medianoche UTC. Los campos de
  /// [currentLimaTime] ya son la hora de pared de Lima (`_nowInLima`).
  DateTime _lunesDeEstaSemana() {
    final ahora = currentLimaTime.value;
    return _lunesDe(DateTime.utc(ahora.year, ahora.month, ahora.day));
  }

  /// Las ocurrencias que el servidor ya expandió, o vacío.
  ///
  /// Van en su propia lista y NUNCA en [_todasLasSecciones] (RF-BLQ-7): ese
  /// arreglo alimenta [colorPorCurso] y el marcado de evaluaciones de
  /// [coursesForDay], así que un bloque ahí dentro le quitaría un color de la
  /// paleta a un curso real y podría quedar marcado como evaluación por
  /// coincidir de nombre con una.
  ///
  /// Se leen del service y no se copian: leer `snapshot` dentro del `Obx` de
  /// la pantalla lo suscribe, y la grilla refleja sola lo que la alumna crea,
  /// edita o borra. Sin el service registrado no hay bloques y nada se cae.
  List<TimeBlockOccurrence> get _bloquesPropios {
    if (!Get.isRegistered<TimeBlocksService>()) {
      return const <TimeBlockOccurrence>[];
    }
    return TimeBlocksService.to.snapshot?.occurrences ??
        const <TimeBlockOccurrence>[];
  }

  /// Las reglas de la alumna, del service, o vacío. Como [_bloquesPropios], se
  /// leen y no se copian: un día que se cancela o vuelve al patrón se repinta
  /// solo.
  List<TimeBlockRule> get _reglasPropias {
    if (!Get.isRegistered<TimeBlocksService>()) {
      return const <TimeBlockRule>[];
    }
    return TimeBlocksService.to.blocks;
  }

  /// El `ever` de [onInit] sobre [currentDayIndex]: en un ciclo de más de 120
  /// días, pide la ventana de la semana nueva. Lo apaga [onClose].
  Worker? _ventanaDeBloques;

  /// Los días primero y los bloques después: la ventana sale de las fechas
  /// del ciclo ([ventanaVisible]), y sin días sería la de respaldo.
  Future<void> _cargarDiasYBloques() async {
    await _loadDays();
    await _cargarBloquesPropios();
  }

  /// Pide al service la [ventanaVisible]. Idempotente: si la ventana es la
  /// misma y ya está cargada, el service no vuelve a pedir nada. Nunca lanza.
  Future<void> _cargarBloquesPropios() {
    if (!Get.isRegistered<TimeBlocksService>()) return Future<void>.value();
    final ventana = ventanaVisible();
    return TimeBlocksService.to.load(from: ventana.from, to: ventana.to);
  }

  static String _fechaPlana(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Las horas que los bloques propios ocupan en la semana del día activo
  /// —la de lunes a domingo que lo contiene—, o null si la línea de RF-BLQ-6
  /// no se pinta.
  ///
  /// El número NO se calcula aquí: es el `hours` que el servidor manda en
  /// `weeks` para esa semana (RS-BE-34). Sumar las ocurrencias en la app sería
  /// una segunda cuenta que podría no coincidir con la suya.
  ///
  /// null si no hay línea que pintar: si la alumna no tiene bloques, si la
  /// semana del día activo no vino en `weeks` (queda fuera de la
  /// [ventanaVisible]), o si vino con `hours` null o con un total que,
  /// redondeado a un decimal como lo pinta `HorarioPage.textoDeHoras`, da 0.
  /// Una semana sin ocurrencias viene con `hours: 0` (RS-BE-34), y el servidor
  /// no redondea: un bloque de dos minutos llega con 0.033. La línea solo sale
  /// si la cifra que se va a pintar es mayor que 0 (D3): nunca se pinta "0 h"
  /// ni un 0 en lugar de un dato que falta.
  double? get horasDeLaSemanaActiva {
    // Todo lo reactivo se lee ANTES de cualquier return: el Obx de la pantalla
    // que llama a este getter queda suscrito a los bloques, a la ventana y al
    // día activo aunque hoy devuelva null, y la línea aparece sola cuando
    // llegan los bloques o cambia el día.
    final servicio = Get.isRegistered<TimeBlocksService>()
        ? TimeBlocksService.to
        : null;
    final snapshot = servicio?.snapshot;
    final reglas = servicio?.blocks ?? const <TimeBlockRule>[];
    final dia = currentDay;
    if (snapshot == null || reglas.isEmpty || dia == null) return null;
    final horas = _semanaQueContiene(dia, snapshot.weeks)?.hours;
    // El mismo redondeo a décimas de textoDeHoras: menos de 3 minutos (0.05 h)
    // se pintarían "0 h".
    return horas != null && (horas * 10).round() > 0 ? horas : null;
  }

  /// La entrada de [semanas] de la semana que contiene a [dia], o null.
  ///
  /// Cada `weekStart` es un lunes (RS-BE-34): [dia] es de la semana cuyo
  /// `weekStart` es el lunes de su fecha. La fecha es la de [_fechaDelDia],
  /// la misma de [bloquesDelDia]: su `isoDate` o, si el ciclo no tiene
  /// semanas, ese día en la semana de hoy. Nunca se lee `dateText`.
  TimeBlockWeek? _semanaQueContiene(
    DaySchedule dia,
    List<TimeBlockWeek> semanas,
  ) {
    final fecha = _fechaDelDia(dia);
    if (fecha == null) return null;
    final lunes = _fechaPlana(_lunesDe(fecha));
    for (final semana in semanas) {
      if (semana.weekStart == lunes) return semana;
    }
    return null;
  }

  void previousDay() {
    if (daysList.isEmpty) return;
    if (currentDayIndex.value > 0) {
      currentDayIndex.value--;
    } else {
      currentDayIndex.value = daysList.length - 1;
    }
  }

  void nextDay() {
    if (daysList.isEmpty) return;
    if (currentDayIndex.value < daysList.length - 1) {
      currentDayIndex.value++;
    } else {
      currentDayIndex.value = 0;
    }
  }

  void toggleListView() {
    isListView.value = !isListView.value;
  }

  /// Color final de cada sección del alumno, ya sin repetidos.
  ///
  /// El backend guarda el color en `schedule_session`, fila que comparten todos
  /// los alumnos de la sección, así que no puede saber qué otros cursos lleva
  /// cada uno: dos cursos distintos pueden traer el mismo color. Pasa de verdad
  /// (en 2026-2, Seguridad de Sistemas y Paradigmas traen el mismo índigo), y
  /// por eso el desempate se hace acá, sobre el horario completo del alumno.
  ///
  /// Se calcula sobre TODAS las secciones y no sobre el día visible, para que un
  /// curso no cambie de color al pasar de lunes a martes. Las claves se ordenan
  /// para que el reparto sea estable entre recargas.
  Map<String, Color> get colorPorCurso {
    final claves = <String>[];
    final hexPorClave = <String, String?>{};

    for (final section in _todasLasSecciones) {
      if (section['isAdvising'] == true) continue;
      final id = section['idSeccion']?.toString() ?? '';
      if (id.isEmpty || hexPorClave.containsKey(id)) continue;

      // El color vive en el horario, no en la sección: a nivel de sección suele
      // venir un naranja por defecto que no distingue cursos.
      String? hex;
      final horarios = section['horarios'];
      if (horarios is List) {
        for (final h in horarios) {
          final c = (h is Map ? h['color']?.toString() : null)?.trim();
          if (c != null && c.isNotEmpty) {
            hex = c;
            break;
          }
        }
      }
      hexPorClave[id] = hex;
      claves.add(id);
    }

    claves.sort();
    return asignarColoresSinRepetir(claves, (k) => hexPorClave[k]);
  }

  List<Map<String, dynamic>> get uniqueEnrolledCourses {
    final uniqueCourses = <String, Map<String, dynamic>>{};

    for (final section in _todasLasSecciones) {
      if (section['isAdvising'] == true) continue;
      final sectionIdStr = section['idSeccion']?.toString() ?? '';
      if (sectionIdStr.isNotEmpty && !uniqueCourses.containsKey(sectionIdStr)) {
        // El color real del curso vive en cada horario (schedule_session.color_hex),
        // no a nivel de sección (ahí suele venir un default naranja). El calendario
        // ya usa el del horario; aquí replicamos eso para que la lista tenga los
        // mismos colores por curso.
        final entry = Map<String, dynamic>.from(section);
        final horarios = section['horarios'];
        if (horarios is List) {
          for (final h in horarios) {
            final hColor = (h is Map ? h['color']?.toString() : null)?.trim();
            if (hColor != null && hColor.isNotEmpty) {
              entry['color'] = hColor;
              break;
            }
          }
        }
        uniqueCourses[sectionIdStr] = entry;
      }
    }

    return uniqueCourses.values.toList();
  }
}
