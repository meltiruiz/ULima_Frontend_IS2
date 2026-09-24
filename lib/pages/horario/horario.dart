import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../descripcion_cursos/descrip_cursos.dart';
import '../teacher/at_risk_students_page.dart';
import '../time_blocks/time_block_actions_sheet.dart';
import '../time_blocks/time_block_form_controller.dart';
import '../time_blocks/time_block_list_controller.dart';
import 'horario_controller.dart';
import 'horario_layout.dart';
import '../../components/skeleton.dart';
import '../../services/contacto_service.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/attendance_risk_service.dart';
import '../../models/contacto_model.dart';
import '../../models/time_block_model.dart';
import '../../configs/course_colors.dart';
import '../../configs/themes.dart';

class HorarioPage extends StatelessWidget {
  const HorarioPage({super.key});

  /// Botón para agregar un bloque propio (RF-BLQ-1). Solo lo ve el alumno.
  static const Key agregarBloqueKey = Key('horario-agregar-bloque');

  /// Botón que abre la lista «Mis bloques» (RF-BLQ-8), junto al de agregar y
  /// con sus mismas condiciones.
  static const Key misBloquesKey = Key('horario-mis-bloques');

  /// La línea "Tus bloques: N h esta semana" de las vistas de día y semanal.
  static const Key horasSemanaKey = Key('horario-horas-semana');

  /// Las horas de esa línea: sin decimal cuando la cifra es entera y con uno
  /// cuando no ("12 h", "12.5 h"). Se redondea a un decimal antes de decidir,
  /// para que 12.96 salga "13 h" y no "13.0 h".
  ///
  /// Pura y expuesta para poder probarla, igual que [blockGeometry]. Solo da
  /// forma: el número lo manda el servidor y no se recalcula en la app. La
  /// pantalla nunca le pasa una cifra que redondeada dé 0: la filtra antes
  /// `HorarioController.horasDeLaSemanaActiva` (D3).
  static String textoDeHoras(double horas) {
    final decimas = (horas * 10).round();
    final cifra = decimas % 10 == 0
        ? '${decimas ~/ 10}'
        : (decimas / 10).toStringAsFixed(1);
    return '$cifra h';
  }

  static const double startHour = 7.0;
  static const double endHour = 22.0;
  static const double hourHeight = 85.0;

  /// Desplazamiento de la línea de hora dentro de su fila en la vista vertical
  /// (`_hourLines` la dibuja con `margin: top 9`). Los bloques tienen que usar
  /// el MISMO valor o no coinciden con la hora que dicen ocupar.
  static const double vertLineOffset = 9.0;

  /// Separación entre dos bloques consecutivos. Se resta al alto, no a la
  /// duración: un bloque tiene que llegar hasta la línea de su hora de fin.
  static const double blockHairline = 2.0;

  /// Alto mínimo para que un bloque de la vista semanal muestre su sección
  /// debajo del nombre. Por debajo de esto el texto no entra y se omite.
  static const double compactMetaMinHeight = 34.0;

  /// Qué va debajo del nombre del curso dentro de un bloque.
  ///
  /// Pura y expuesta para poder probarla, igual que [blockGeometry].
  ///
  /// Lo decide la VISTA, no el tamaño del bloque:
  /// - Vista de día a día ([_portraitGrid], `vistaDia: true`): el salón. Nombre
  ///   del curso y dónde se dicta, nada más. La sección sobra — el alumno está
  ///   matriculado en una sola y la tiene en el detalle del curso — mientras que
  ///   el salón es el dato que va a buscar en el bloque.
  /// - Vista semanal horizontal ([_landscapeWeekGrid], `vistaDia: false`): la
  ///   sección. Cada día es una columna angosta donde el salón no entra.
  ///
  /// ⚠️ `compact` NO distingue las vistas, aunque lo parezca: significa que el
  /// bloque quedó chico. La semanal lo pasa fijo en `true`, pero la de día lo
  /// CALCULA (`dynamicHourHeight < 35`) y en una pantalla pequeña también da
  /// `true` — en un iPhone SE las 15 horas del día caben a ~25 px por hora. La
  /// primera versión de esto decidía por `compact` y el teléfono siguió
  /// mostrando la sección. Aquí `compact` solo gobierna el umbral de alto.
  static List<String> blockMetaLines({
    required bool vistaDia,
    required bool compact,
    required double height,
    required String seccionLabel,
    required String aula,
  }) {
    final linea = vistaDia ? aula : seccionLabel;
    if (!compact) return <String>[linea];
    return height >= compactMetaMinHeight ? <String>[linea] : const <String>[];
  }

  /// Dónde va y cuánto mide el bloque de un curso.
  ///
  /// Pura y expuesta para poder probarla: el bloque MIDE su duración. La versión
  /// anterior lo bajaba 10 px y le restaba 14 de alto, así que un curso de 7 a 9
  /// no llegaba a la línea de las 9 y aparentaba durar menos de lo que dura.
  static ({double top, double height}) blockGeometry({
    required double startVal,
    required double endVal,
    required double hourHeight,
    required double lineOffset,
  }) {
    final top = (startVal - startHour) * hourHeight + lineOffset;
    final duration = (endVal - startVal) * hourHeight;
    return (top: top, height: (duration - blockHairline).clamp(8.0, double.infinity).toDouble());
  }
  static const List<DeviceOrientation> _scheduleOrientations = [
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];
  static const List<DeviceOrientation> _portraitOnly = [
    DeviceOrientation.portraitUp,
  ];

  double _timeToHours(String timeStr) {
    try {
      final cleanStr = timeStr.trim().toLowerCase();

      // If it contains am/pm, use the 12-hour parser
      if (cleanStr.contains('am') || cleanStr.contains('pm')) {
        final parts = cleanStr.split(' ');
        if (parts.length >= 2) {
          final isPm = parts[1] == 'pm';
          final hms = parts[0].split(':');
          int hour = int.tryParse(hms[0]) ?? 12;
          int minute = hms.length > 1 ? (int.tryParse(hms[1]) ?? 0) : 0;

          if (isPm && hour != 12) hour += 12;
          if (!isPm && hour == 12) hour = 0;

          return hour + (minute / 60.0);
        }
      }

      // Try 24-hour parser (e.g., "14:00:00", "14:00")
      final hms = cleanStr.split(':');
      if (hms.isNotEmpty) {
        final hour = int.tryParse(hms[0]);
        if (hour != null) {
          final minute = hms.length > 1 ? (int.tryParse(hms[1]) ?? 0) : 0;
          return hour + (minute / 60.0);
        }
      }

      return 7.0;
    } catch (_) {
      return 7.0;
    }
  }

  Color _resolveScheduleColor(String colorStr, ColorScheme colors) {
    final cleanColor = colorStr.trim();
    final hexColor = cleanColor.startsWith('#')
        ? cleanColor.substring(1)
        : cleanColor;

    if (RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hexColor)) {
      return Color(int.parse('FF$hexColor', radix: 16));
    }
    if (RegExp(r'^[0-9a-fA-F]{8}$').hasMatch(hexColor)) {
      return Color(int.parse(hexColor, radix: 16));
    }

    return {
          'pink': colors.secondaryContainer,
          'blue': colors.secondary,
          'orange': colors.primary,
          'green': colors.tertiaryContainer,
          'purple': colors.tertiary,
          'teal': colors.primaryContainer,
          'red': colors.error,
        }[cleanColor.toLowerCase()] ??
        colors.outline;
  }

  Widget _currentTimeLine() {
    return IgnorePointer(
      child: SizedBox(
        height: 12,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerLeft,
          children: [
            Positioned(
              left: 0,
              right: 0,
              child: Container(height: 2, color: const Color(0xFFFF5252)),
            ),
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFFFF5252),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _hourLabel(double hourVal) {
    final isPm = hourVal >= 12;
    final displayHour = hourVal > 12 ? (hourVal - 12).toInt() : hourVal.toInt();
    return '$displayHour ${isPm ? 'pm' : 'am'}';
  }

  /// Los días de la vista semanal, en orden fijo de lunes a domingo: la
  /// primera aparición de cada nombre en `daysList`, que es la primera semana
  /// del ciclo (a las clases les da igual, se repiten todas las semanas).
  ///
  /// El domingo entra con RF-BLQ-4: antes la lista llegaba hasta el sábado y
  /// un bloque propio de domingo se veía en la vista de día pero desaparecía
  /// aquí. Un horario sin domingo sigue saliendo con sus seis columnas.
  List<DaySchedule> _weekDays(HorarioController controller) {
    const expected = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
    final days = <DaySchedule>[];
    for (final expectedDay in expected) {
      for (final day in controller.daysList) {
        final normalized = day.dayName.trim().toLowerCase();
        if (normalized == expectedDay ||
            (expectedDay == 'miércoles' && normalized == 'miercoles') ||
            (expectedDay == 'sábado' && normalized == 'sabado')) {
          days.add(day);
          break;
        }
      }
    }
    if (days.isNotEmpty) return days;
    return controller.daysList.take(7).toList();
  }

  double _dynamicHourHeight({
    required double availableHeight,
    required double topPadding,
    required double bottomPadding,
    required double minHeight,
  }) {
    final totalHours = (endHour - startHour).toInt() + 1;
    final gridHeight = availableHeight - topPadding - bottomPadding;
    if (!gridHeight.isFinite || gridHeight <= 0) return minHeight;
    return (gridHeight / totalHours).clamp(minHeight, hourHeight).toDouble();
  }

  Widget _hourLines({
    required double hourHeight,
    required double timeColumnWidth,
    required double labelLeftPadding,
    required double fontSize,
    required bool isDark,
  }) {
    final totalHours = (endHour - startHour).toInt() + 1;
    return Column(
      children: List.generate(totalHours, (index) {
        final hourVal = startHour + index;
        return SizedBox(
          height: hourHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: timeColumnWidth,
                child: Padding(
                  padding: EdgeInsets.only(left: labelLeftPadding, top: 2),
                  child: Text(
                    _hourLabel(hourVal),
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF9090A0)
                          : const Color(0xFF9E9E9E),
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 9),
                  height: 1,
                  color: isDark
                      ? const Color(0xFF2C2C38)
                      : const Color(0xFFECECEC),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  /// El mapa con el que una ocurrencia propia entra a [_courseBlock].
  ///
  /// Reusa las claves que ya leen las clases (`curso`, `hora_inicio`,
  /// `hora_fin`) para no duplicar el dibujo del bloque, y agrega
  /// `bloquePropio` con la ocurrencia tipada: de ahí salen su color y, con
  /// RF-BLQ-5, la hoja de acciones. `diaCancelado` marca un día cancelado
  /// (ver [HorarioController.bloquesCanceladosDelDia]), que se pinta tenue y
  /// con [_diaCanceladoTexto].
  /// No lleva `idSeccion`, `codigoSeccion`, `salon` ni `color`: un bloque
  /// propio no tiene curso, sección ni salón.
  static Map<String, dynamic> _bloqueComoCurso(
    TimeBlockOccurrence ocurrencia, {
    bool cancelado = false,
  }) =>
      <String, dynamic>{
        'curso': ocurrencia.title,
        'hora_inicio': ocurrencia.startTime,
        'hora_fin': ocurrencia.endTime,
        'isEvaluation': false,
        'isAdvising': false,
        'bloquePropio': ocurrencia,
        'diaCancelado': cancelado,
      };

  /// El tramo de un bloque en minutos, leído de las mismas claves, con los
  /// mismos respaldos (`'07:00 am'`/`'09:00 am'` si falta la hora) y con el
  /// mismo [_timeToHours] que [_courseBlock]. Así el reparto y el dibujo
  /// nunca discrepan sobre dónde está un bloque.
  ({int inicio, int fin}) _tramoEnMinutos(Map<String, dynamic> course) => (
        inicio:
            (_timeToHours(course['hora_inicio'] as String? ?? '07:00 am') * 60)
                .round(),
        fin: (_timeToHours(course['hora_fin'] as String? ?? '09:00 am') * 60)
            .round(),
      );

  /// La opacidad de un día cancelado: se ve, se toca y se distingue de uno
  /// que sí va (RF-BLQ-5, D2).
  static const double _opacidadDiaCancelado = 0.4;

  /// Lo que dice un día cancelado debajo de su nombre (D2), en el lugar donde
  /// una clase lleva su salón o su sección. La prueba lo busca por el texto
  /// literal, que es el que fija la spec.
  static const String _diaCanceladoTexto = 'Este día está cancelado';

  /// Pone un bloque en su columna dentro de la pista que va de `left` a
  /// `right` (RF-BLQ-4): mide `1/columnas` del ancho y se alinea en la columna
  /// que le tocó. Con una sola columna el factor es 1 y la alineación la
  /// izquierda: el bloque de siempre, al píxel. Con [tenue], a
  /// [_opacidadDiaCancelado]: la opacidad no le quita los toques.
  ///
  /// Con [FractionallySizedBox] y no calculando `left`/`right` porque aquí no
  /// se conoce el ancho del día: en la vista semanal cada día es un
  /// [Expanded]. El hijo mide solo su parte, así que un toque en la otra
  /// columna le llega al bloque de al lado y no a este.
  static Widget _enSuColumna({
    required int columna,
    required int columnas,
    bool tenue = false,
    required Widget bloque,
  }) {
    final double eje =
        columnas <= 1 ? -1.0 : 2 * columna / (columnas - 1) - 1;
    return FractionallySizedBox(
      widthFactor: 1 / columnas,
      alignment: Alignment(eje, 0),
      child: tenue
          ? Opacity(opacity: _opacidadDiaCancelado, child: bloque)
          : bloque,
    );
  }

  /// El día que se llama como [dia] dentro de la semana del día activo.
  ///
  /// [_weekDays] arma la vista semanal con la primera semana del ciclo. Para
  /// las clases da igual, pero los bloques propios cambian de una semana a
  /// otra (un día cancelado, uno movido, uno fuera de sus fechas), así que se
  /// buscan en la semana que la alumna estaba viendo al girar el teléfono.
  /// `daysList` trae cada semana como siete días seguidos de lunes a domingo
  /// (`schedule.service.ts`), de ahí el `% 7`.
  static DaySchedule _mismoDiaEnLaSemanaActiva(
    HorarioController controller,
    DaySchedule dia,
  ) {
    final dias = controller.daysList;
    if (dias.isEmpty) return dia;
    final activo = math.min(
      math.max(controller.currentDayIndex.value, 0),
      dias.length - 1,
    );
    final lunes = activo - activo % 7;
    final nombre = dia.dayName.trim().toLowerCase();
    for (var i = lunes; i < lunes + 7 && i < dias.length; i++) {
      if (dias[i].dayName.trim().toLowerCase() == nombre) return dias[i];
    }
    return dia;
  }

  /// Los bloques de un día ya repartidos en columnas (RF-BLQ-4): las clases,
  /// los bloques propios y los días cancelados juntos, porque los propios
  /// chocan con las clases a propósito y sin reparto el de arriba taparía al
  /// de abajo y se comería sus toques. Las clases van primero, en su orden de
  /// siempre; los cancelados, al final.
  List<Widget> _bloquesRepartidos({
    required BuildContext context,
    required HorarioController controller,
    required List<Map<String, dynamic>> clases,
    required List<TimeBlockOccurrence> propios,
    required List<TimeBlockOccurrence> cancelados,
    required double hourHeight,
    required double left,
    required double right,
    required bool compact,
    required bool vistaDia,
    required double lineOffset,
  }) {
    final bloques = <Map<String, dynamic>>[
      ...clases,
      ...propios.map(_bloqueComoCurso),
      for (final o in cancelados) _bloqueComoCurso(o, cancelado: true),
    ];
    final slots = repartirEnColumnas(bloques.map(_tramoEnMinutos).toList());
    return <Widget>[
      for (var i = 0; i < bloques.length; i++)
        _courseBlock(
          context: context,
          controller: controller,
          course: bloques[i],
          hourHeight: hourHeight,
          left: left,
          right: right,
          columna: slots[i].columna,
          columnas: slots[i].columnas,
          compact: compact,
          vistaDia: vistaDia,
          lineOffset: lineOffset,
        ),
    ];
  }

  Widget _courseBlock({
    required BuildContext context,
    required HorarioController controller,
    required Map<String, dynamic> course,
    required double hourHeight,
    required double left,
    required double right,
    /// La columna del bloque dentro de su día (desde 0) y entre cuántas se
    /// reparte el ancho, según [repartirEnColumnas]. Por omisión 0 de 1: todo
    /// el ancho, como antes del reparto.
    int columna = 0,
    int columnas = 1,
    required bool compact,
    /// true en la vista de día a día, false en la semanal horizontal. Separado
    /// de [compact] a propósito: ese dice si el bloque es chico, no qué vista es.
    required bool vistaDia,
    /// Dónde cae la línea de la hora dentro de su fila: 9 en la vista vertical,
    /// 0 en la horizontal, que dibuja las líneas justo en `i * alto`.
    double lineOffset = 0.0,
  }) {
    final colors = Theme.of(context).colorScheme;
    final bool isEvaluation = course['isEvaluation'] == true;

    // Un bloque propio de la alumna llega con su ocurrencia en `bloquePropio`
    // (ver [_bloqueComoCurso]). No tiene curso, sección ni salón. Si además
    // es un día cancelado, `diaCancelado` lo pinta tenue y lo dice.
    final bloquePropio = course['bloquePropio'] as TimeBlockOccurrence?;
    final esBloquePropio = bloquePropio != null;
    final diaCancelado = course['diaCancelado'] == true;

    String nombreStr = (course['curso'] as String? ?? 'CURSO').toUpperCase();
    // La barra separa el nombre bilingüe que manda el portal ("CURSO /
    // COURSE"). El nombre de un bloque propio lo escribió la alumna: va entero.
    if (!esBloquePropio && nombreStr.contains(' / ')) {
      nombreStr = nombreStr.split(' / ').first.trim();
    } else if (!esBloquePropio && nombreStr.contains('/')) {
      nombreStr = nombreStr.split('/').first.trim();
    }
    final aulaStr = course['salon'] as String? ?? 'Sin salón';
    final colorStr = course['color'] as String? ?? 'blue';
    final startStr = course['hora_inicio'] as String? ?? '07:00 am';
    final endStr = course['hora_fin'] as String? ?? '09:00 am';

    final startVal = _timeToHours(startStr);
    final endVal = _timeToHours(endStr);

    final geom = blockGeometry(
      startVal: startVal, endVal: endVal, hourHeight: hourHeight, lineOffset: lineOffset,
    );
    final double topPosition = geom.top;
    final double heightVal = geom.height;

    // El color de un bloque propio es el que eligió la alumna, y NO pasa por
    // [HorarioController.colorPorCurso]: ese reparte la paleta de doce entre
    // las secciones, y un bloque ahí dentro le quitaría el suyo a un curso.
    final courseColor = bloquePropio != null
        ? parseHexColor(bloquePropio.colorHex) ?? colors.outline
        : controller.colorPorCurso[course['idSeccion']?.toString()] ??
              _resolveScheduleColor(colorStr, colors);
    final badgeText = course['isAdvising'] == true
        ? 'ASESORIA'
        : isEvaluation
        ? 'EVAL ${course['evalSigla']}'
        : null;
    final titleFontSize = compact ? 9.5 : 13.5;
    final metaFontSize = compact ? 8.0 : 11.0;
    final horizontalPadding = compact ? 5.0 : 10.0;
    // Debajo del nombre: el salón en la vista de día y la sección en la
    // semanal ([blockMetaLines]). Un bloque propio no tiene ninguno de los dos
    // y va solo con su nombre; un día cancelado lleva en ese lugar
    // [_diaCanceladoTexto] (D2), con la misma regla de alto: si el bloque es
    // chico, no entra y se omite. Se decide aquí, y no dentro de
    // [blockMetaLines], para no cambiar el contrato que prueba
    // test/HU31_jeff/horario_bloque_contenido_test.dart.
    final lineasDebajo = diaCancelado
        ? blockMetaLines(
            vistaDia: vistaDia,
            compact: compact,
            height: heightVal,
            seccionLabel: _diaCanceladoTexto,
            aula: _diaCanceladoTexto,
          )
        : esBloquePropio
        ? const <String>[]
        : blockMetaLines(
            vistaDia: vistaDia,
            compact: compact,
            height: heightVal,
            seccionLabel: course['isAdvising'] == true
                ? (course['codigoSeccion']?.toString() ?? 'Asesoría')
                : "Sección: ${course['codigoSeccion'] ?? 'Sin sección'}",
            aula: aulaStr,
          );

    return Positioned(
      top: topPosition,
      left: left,
      right: right,
      height: heightVal,
      child: _enSuColumna(columna: columna, columnas: columnas, tenue: diaCancelado, bloque: InkWell(
        onTap: () async {
          // RF-BLQ-5: un bloque propio no tiene curso al que ir; abre su
          // hoja de acciones (la de un día cancelado solo ofrece volver al
          // patrón). Va primero: sin esta rama caería en la del alumno, que
          // con `idSeccion` vacío no hace nada.
          if (bloquePropio != null) {
            await mostrarAccionesDeBloque(
              context,
              bloquePropio,
              cancelado: diaCancelado,
            );
            return;
          }
          final String idSeccion = course['idSeccion']?.toString() ?? '';
          final isTeacher = AuthService.to.currentUser?.isTeacher ?? false;

          if (isTeacher) {
            if (course['isAdvising'] == true) {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text(
                      course['codigoSeccion'] ?? 'Asesoría',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course['curso'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 18,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Horario: $startStr - $endStr",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.place, size: 18, color: colors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Aula/Canal: $aulaStr",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (course['fecha'] != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_month,
                                size: 18,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Fecha: ${course['fecha']}",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text(
                          "Cerrar",
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  );
                },
              );
            } else {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (context) => _TeacherCourseDetailSheet(
                  idSeccion: idSeccion,
                  courseName: course['curso'] ?? '',
                  sectionCode: course['codigoSeccion'] ?? '',
                ),
              );
            }
          } else if (idSeccion.isNotEmpty) {
            await SystemChrome.setPreferredOrientations(_portraitOnly);
            // La ficha recibe el color del curso para su chat, el mismo de la
            // bandeja (RF-CHAT-7). Sin él, ChatPage usa su respaldo.
            await Get.to(
              () => DescripCursosPage(
                idSeccion: idSeccion,
                courseColor: controller.colorPorCurso[idSeccion],
              ),
            );
            await SystemChrome.setPreferredOrientations(_scheduleOrientations);
          }
        },
        borderRadius: BorderRadius.circular(compact ? 8 : 14),
        child: Container(
          decoration: BoxDecoration(
            color: courseColor,
            borderRadius: BorderRadius.circular(compact ? 8 : 14),
            boxShadow: compact
                ? null
                : [
                    BoxShadow(
                      color: courseColor.withValues(alpha: 0.30),
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  badgeText == null ? 4 : (compact ? 14 : 22),
                  horizontalPadding,
                  3,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        nombreStr,
                        textAlign: TextAlign.center,
                        maxLines: compact ? 2 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                        ),
                      ),
                      for (final linea in lineasDebajo) ...[
                        const SizedBox(height: 2),
                        Text(
                          linea,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: metaFontSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (badgeText != null)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 4 : 6,
                      vertical: compact ? 1 : 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 6 : 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      )),
    );
  }

  Widget _portraitGrid({
    required BuildContext context,
    required HorarioController controller,
    required DaySchedule activeDay,
    required bool isDark,
  }) {
    // Los bloques propios se leen AQUÍ y no dentro del LayoutBuilder: su
    // builder corre al hacer el layout, fuera del Obx de [build], y una
    // lectura ahí no suscribe a nada. Leídos aquí, cuando el service trae o
    // recarga su ventana el Obx se reconstruye y la grilla los pinta sola.
    // Los días cancelados, por lo mismo.
    final propios = controller.bloquesDelDia(activeDay);
    final cancelados = controller.bloquesCanceladosDelDia(activeDay);
    return LayoutBuilder(
      builder: (context, constraints) {
        const topPadding = 6.0;
        const bottomPadding = 6.0;
        final dynamicHourHeight = _dynamicHourHeight(
          availableHeight: constraints.maxHeight,
          topPadding: topPadding,
          bottomPadding: bottomPadding,
          minHeight: 22,
        );
        final courses = controller.currentDayCourses;
        final currentHour = controller.currentLimaHourDecimal;
        final showCurrentTimeLine =
            controller.isCurrentLimaDay(activeDay) &&
            currentHour >= startHour &&
            currentHour <= endHour;
        final currentLineTop =
            (currentHour - startHour) * dynamicHourHeight + vertLineOffset;

        return SizedBox.expand(
          child: Padding(
            padding: const EdgeInsets.only(
              top: topPadding,
              bottom: bottomPadding,
            ),
            child: Stack(
              children: [
                _hourLines(
                  hourHeight: dynamicHourHeight,
                  timeColumnWidth: 58,
                  labelLeftPadding: 14,
                  fontSize: 10,
                  isDark: isDark,
                ),
                ..._bloquesRepartidos(
                  context: context,
                  controller: controller,
                  clases: courses,
                  propios: propios,
                  cancelados: cancelados,
                  hourHeight: dynamicHourHeight,
                  left: 66,
                  right: 14,
                  compact: dynamicHourHeight < 35,
                  vistaDia: true,
                  lineOffset: vertLineOffset,
                ),
                if (showCurrentTimeLine)
                  Positioned(
                    top: currentLineTop,
                    left: 66,
                    right: 0,
                    child: _currentTimeLine(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _landscapeWeekGrid({
    required BuildContext context,
    required HorarioController controller,
    required bool isDark,
  }) {
    final weekDays = _weekDays(controller);
    if (weekDays.isEmpty) return const SizedBox.shrink();

    const stripOrange = Color(0xFFF26522);
    const stripDark = Color(0xFF2E2E2E);
    final bg = isDark ? const Color(0xFF1E1E26) : Colors.white;
    final lineColor = isDark
        ? const Color(0xFF2C2C38)
        : const Color(0xFFE6E6E6);
    final user = AuthService.to.currentUser;
    final studentCode = user?.code ?? '';
    // El nombre va tal como está guardado: APELLIDOS y después NOMBRES. Antes se
    // imprimía `lastName + firstName` sobre una partición equivocada —el backend
    // toma el último token como apellido— y salía "ANGELO SANCHEZ PALACIOS
    // JEFFERSON" en vez de "SANCHEZ PALACIOS JEFFERSON ANGELO".
    final studentName = user == null ? '' : user.fullName.toUpperCase();
    final cycle = user?.currentCycle ?? '';
    // Fuera del LayoutBuilder por lo mismo que en [_portraitGrid]: así el Obx
    // de [build] se entera cuando llegan o cambian los bloques propios.
    final propiosPorDia = <DaySchedule, List<TimeBlockOccurrence>>{
      for (final day in weekDays)
        day: controller.bloquesDelDia(
          _mismoDiaEnLaSemanaActiva(controller, day),
        ),
    };
    final canceladosPorDia = <DaySchedule, List<TimeBlockOccurrence>>{
      for (final day in weekDays)
        day: controller.bloquesCanceladosDelDia(
          _mismoDiaEnLaSemanaActiva(controller, day),
        ),
    };
    // RF-BLQ-6 también en la vista semanal, que pinta los bloques de la
    // semana del día activo. Se lee aquí, fuera del LayoutBuilder, por lo
    // mismo que los bloques: así el Obx de [build] se entera solo.
    final horasDeBloques = controller.horasDeLaSemanaActiva;

    return Container(
      color: bg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const headerThickness = 32.0;
          const identityThickness = 26.0;
          const gutter = 34.0;
          // Media etiqueta arriba y abajo. Las horas se dibujan CENTRADAS sobre
          // su línea, así que sin este hueco la de las 7 am se sale por arriba
          // y la de las 10 pm por abajo, que es justo lo que se veía cortado.
          const labelPad = 8.0;
          final totalHours = (endHour - startHour).toInt();
          final gridHeight = math.max(
            0.0,
            constraints.maxHeight - headerThickness - identityThickness,
          );
          final hourH = math.max(0.0, gridHeight - labelPad * 2) / totalHours;

          return Column(
            children: [
              SizedBox(
                height: headerThickness,
                child: Row(
                  children: [
                    const SizedBox(width: gutter),
                    for (final day in weekDays)
                      Expanded(
                        child: Container(
                          alignment: Alignment.center,
                          color: stripOrange,
                          // Sin fecha: el horario es SEMANAL y se repite todas
                          // las semanas, así que poner "24 de agosto" lo hacía
                          // parecer el horario de una semana concreta.
                          child: Text(
                            day.dayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                height: gridHeight,
                child: Row(
                  children: [
                    SizedBox(
                      width: gutter,
                      child: Stack(
                        children: [
                          for (int i = 0; i <= totalHours; i++)
                            Positioned(
                              top: labelPad + i * hourH - 6,
                              left: 0,
                              right: 2,
                              child: Text(
                                _hourLabel(startHour + i).toUpperCase(),
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFF9090A0)
                                      : const Color(0xFF9E9E9E),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    for (final day in weekDays)
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(color: lineColor, width: 1),
                            ),
                          ),
                          child: Stack(
                            children: [
                              for (int i = 0; i <= totalHours; i++)
                                Positioned(
                                  top: labelPad + i * hourH,
                                  left: 0,
                                  right: 0,
                                  child: Container(height: 1, color: lineColor),
                                ),
                              ..._bloquesRepartidos(
                                context: context,
                                controller: controller,
                                clases: controller.coursesForDay(day),
                                propios: propiosPorDia[day] ??
                                    const <TimeBlockOccurrence>[],
                                cancelados: canceladosPorDia[day] ??
                                    const <TimeBlockOccurrence>[],
                                hourHeight: hourH,
                                left: 2,
                                right: 2,
                                compact: true,
                                vistaDia: false,
                                lineOffset: labelPad,
                              ),
                              if (controller.isCurrentLimaDay(day) &&
                                  controller.currentLimaHourDecimal >=
                                      startHour &&
                                  controller.currentLimaHourDecimal <= endHour)
                                Positioned(
                                  top:
                                      labelPad +
                                      (controller.currentLimaHourDecimal -
                                              startHour) *
                                          hourH,
                                  left: 2,
                                  right: 0,
                                  child: _currentTimeLine(),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                height: identityThickness,
                child: Container(
                  color: stripDark,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        studentCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          studentName,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      // RF-BLQ-6: los encabezados de la vista semanal no
                      // llevan fecha (el horario de clases es semanal), así
                      // que la línea va aquí, junto al ciclo. Nunca un 0
                      // inventado: sin dato no hay línea.
                      if (horasDeBloques != null) ...[
                        Text(
                          'Tus bloques: ${textoDeHoras(horasDeBloques)} esta semana',
                          key: horasSemanaKey,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Text(
                        cycle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HorarioController());
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // RF-BLQ-1: agregar un bloque propio es solo del alumno; el horario del
    // docente es el de sus clases y asesorías. En horizontal la grilla semanal
    // ocupa toda la pantalla y el botón la taparía. El botón de «Mis bloques»
    // (RF-BLQ-8) va encima, con las mismas condiciones.
    final esAlumno = !(AuthService.to.currentUser?.isTeacher ?? false);
    final enHorizontal =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1E1E26)
          : const Color(0xFFF8F9FA),
      floatingActionButton: (esAlumno && !enHorizontal)
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.small(
                  key: misBloquesKey,
                  // La etiqueta accesible, como la de agregar.
                  tooltip: 'Mis bloques',
                  // Sin Hero: dos botones flotantes con la etiqueta
                  // de Hero por omisión en la misma pantalla hacen
                  // fallar la transición a cualquier otra ruta.
                  heroTag: null,
                  backgroundColor: colors.surface,
                  // Un ícono pide 3:1 contra el botón (WCAG). En
                  // claro el naranja de marca da 2,89:1 sobre
                  // #FEFDFC y el naranja oscuro del tema, 4,05:1; en
                  // oscuro el de marca ya da 5,65:1 sobre #1E1E24.
                  // iconoNaranja elige entre los dos por el tema.
                  foregroundColor: MaterialTheme.iconoNaranja(
                    Theme.of(context).brightness,
                  ),
                  onPressed: () async {
                    // La misma guarda que el de agregar: mientras la
                    // lista anterior termina de cerrarse, el binding
                    // le daría a la nueva su controller, y al
                    // terminar la salida GetX lo borraría.
                    if (Get.isRegistered<TimeBlockListController>()) {
                      return;
                    }
                    await SystemChrome.setPreferredOrientations(
                      _portraitOnly,
                    );
                    await Get.toNamed<dynamic>('/mis-bloques');
                    await SystemChrome.setPreferredOrientations(
                      _scheduleOrientations,
                    );
                  },
                  child: const Icon(Icons.list_alt),
                ),
                const SizedBox(height: 12),
                // `small`: la esquina inferior derecha es la franja de
                // 9 a 10 pm, donde sí hay clases; el botón chico tapa
                // menos.
                FloatingActionButton.small(
                  key: agregarBloqueKey,
                  tooltip: 'Agregar bloque',
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  // Como el toque de un curso: el formulario no rota
                  // (solo el horario puede), así que se fija en
                  // vertical antes de abrirlo y se devuelve la
                  // rotación al volver.
                  onPressed: () async {
                    // get 4.7.3 borra el controller del formulario
                    // recién al terminar la animación de salida, y
                    // antes de eso el binding le daría a /bloque el
                    // viejo.
                    if (Get.isRegistered<TimeBlockFormController>()) {
                      return;
                    }
                    await SystemChrome.setPreferredOrientations(
                      _portraitOnly,
                    );
                    await Get.toNamed<dynamic>('/bloque');
                    await SystemChrome.setPreferredOrientations(
                      _scheduleOrientations,
                    );
                  },
                  child: const Icon(Icons.add),
                ),
              ],
            )
          : null,
      body: Obx(() {
        final activeDay = controller.currentDay;
        if (activeDay == null) {
          // Skeleton con la silueta del horario (selector de días + bloques
          // de clases) en lugar del spinner central.
          return SkeletonPulse(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < 5; i++) ...[
                        const Expanded(
                          child: SkeletonBox(height: 44, borderRadius: 12),
                        ),
                        if (i < 4) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                  const SizedBox(height: 22),
                  for (final alto in const [88.0, 64.0, 110.0, 76.0]) ...[
                    SkeletonBox(
                      width: double.infinity,
                      height: alto,
                      borderRadius: 14,
                    ),
                    const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
          );
        }

        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;
        if (isLandscape) {
          return _landscapeWeekGrid(
            context: context,
            controller: controller,
            isDark: isDark,
          );
        }

        return GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity != null) {
              if (details.primaryVelocity! < 0) {
                controller.nextDay();
              } else if (details.primaryVelocity! > 0) {
                controller.previousDay();
              }
            }
          },
          behavior: HitTestBehavior.translucent,
          child: Column(
            children: [
              Container(
                color: isDark
                    ? const Color(0xFF262630)
                    : const Color(0xFFFFF2EC),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: colors.primary,
                        size: 20,
                      ),
                      onPressed: controller.previousDay,
                    ),
                    Text(
                      '${activeDay.dayName}, ${activeDay.dateText}',
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF2D2D2D),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: colors.primary,
                        size: 20,
                      ),
                      onPressed: controller.nextDay,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE5E5E5)),
              Container(
                width: double.infinity,
                color: isDark ? const Color(0xFF1B1B22) : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      activeDay.weekText,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFB0B0C0)
                            : const Color(0xFF666666),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // RF-BLQ-6: las horas de los bloques propios en la semana
                    // del día activo, tal como las manda el servidor. Se lee
                    // aquí, dentro del Obx de build y fuera de cualquier
                    // LayoutBuilder, para que la línea se entere sola cuando
                    // llegan los bloques o cambia el día. Si no hay dato, no
                    // hay línea: nunca un 0 inventado.
                    if (controller.horasDeLaSemanaActiva case final horas?) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Tus bloques: ${textoDeHoras(horas)} esta semana',
                        key: horasSemanaKey,
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFFB0B0C0)
                              : const Color(0xFF666666),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE5E5E5)),

              Expanded(
                child: _portraitGrid(
                  context: context,
                  controller: controller,
                  activeDay: activeDay,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _TeacherCourseDetailSheet extends StatefulWidget {
  final String idSeccion;
  final String courseName;
  final String sectionCode;

  const _TeacherCourseDetailSheet({
    required this.idSeccion,
    required this.courseName,
    required this.sectionCode,
  });

  @override
  State<_TeacherCourseDetailSheet> createState() =>
      _TeacherCourseDetailSheetState();
}

class _TeacherCourseDetailSheetState extends State<_TeacherCourseDetailSheet> {
  bool _isLoading = true;
  String? _errorMessage;
  String _delegateName = 'No asignado';
  String _subdelegateName = 'No asignado';
  List<dynamic> _assessments = [];
  int _atRiskCount = 0;
  final Set<String> _notifiedAssessments = {};

  Future<void> _confirmAndNotify(
    String assessmentId,
    String assessmentName,
    int loadedCount,
    int totalCount,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notificar Publicación de Notas'),
        content: Text(
          '¿Deseas enviar una alerta a todos los alumnos de la sección indicando que las notas de "$assessmentName" han sido publicadas?\n\nAlumnos calificados: $loadedCount / $totalCount',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final res = await ApiClient().postJson(
          '/schedule/teacher/sections/${widget.idSeccion}/assessments/$assessmentId/notify-grades',
          body: {},
        );
        if (res['ok'] == true) {
          if (mounted) {
            setState(() {
              _notifiedAssessments.add(assessmentId);
            });
          }
          Get.snackbar(
            'Notificación enviada',
            'Se alertó a los ${res['notifiedCount'] ?? 'todos los'} alumnos de la sección.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          if (mounted) {
            setState(() {
              _notifiedAssessments.remove(assessmentId);
            });
          }
          Get.snackbar(
            'Error',
            'No se pudo enviar la notificación.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _notifiedAssessments.remove(assessmentId);
          });
        }
        debugPrint('Error notifying grades: $e');
        Get.snackbar(
          'Error',
          'Ocurrió un error al intentar notificar.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } else {
      if (mounted) {
        setState(() {
          _notifiedAssessments.remove(assessmentId);
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final isTeacher = AuthService.to.currentUser?.isTeacher ?? false;
    try {
      // Cada llamada se blinda por separado: si UNA falla, devuelve vacío y la
      // pantalla igual carga lo que sí pudo (antes un solo 404 tumbaba todo el
      // detalle con "Error al cargar detalles de la sección").
      final contactsFuture = ContactoService()
          .fetchContactos(widget.idSeccion)
          .catchError((e) {
            debugPrint('detalle: contactos falló: $e');
            return <String, dynamic>{};
          });
      // Endpoints exclusivos para docentes: no se llaman si el usuario es alumno.
      final assessmentsFuture = isTeacher
          ? ApiClient()
                .getJson(
                  '/schedule/teacher/sections/${widget.idSeccion}/assessments-status',
                )
                .catchError((e) {
                  debugPrint('detalle: assessments-status falló: $e');
                  return <String, dynamic>{};
                })
          : Future.value(<String, dynamic>{});
      final atRiskFuture = isTeacher
          ? AttendanceRiskService().fetchSummary(widget.idSeccion).catchError((
              e,
            ) {
              debugPrint('detalle: attendance-risk falló: $e');
              return <String, dynamic>{};
            })
          : Future.value(<String, dynamic>{});

      final results = await Future.wait([
        contactsFuture,
        assessmentsFuture,
        atRiskFuture,
      ]);
      final contacts = results[0];
      final assessmentsData = results[1];
      final atRiskData = results[2];
      final summary = atRiskData['summary'] as Map<String, dynamic>?;
      final impedido = (summary?['impedido'] as num?)?.toInt() ?? 0;
      final enRiesgo = (summary?['en_riesgo'] as num?)?.toInt() ?? 0;
      _atRiskCount = impedido + enRiesgo;

      final List<dynamic> alumnos = contacts['alumnos'] ?? [];
      for (final a in alumnos) {
        if (a is ContactoCurso) {
          final role = a.roleInSection;
          final fullName = a.user.fullName;
          if (role == 'delegado') {
            _delegateName = fullName;
          } else if (role == 'subdelegado') {
            _subdelegateName = fullName;
          }
        }
      }

      _assessments = assessmentsData['assessments'] ?? [];

      // Inicializar el estado de notificaci\u00f3n desde el backend
      // (persiste aunque el alumno cierre sesi\u00f3n y vuelva a abrir la vista)
      final notified = <String>{};
      for (final ass in _assessments) {
        if (ass['isNotified'] == true) {
          final id = ass['id']?.toString();
          if (id != null) notified.add(id);
        }
      }

      if (mounted) {
        setState(() {
          _notifiedAssessments.addAll(notified);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error al cargar detalles de la sección';
        });
      }
      debugPrint('Error loading teacher course details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Solo el Profesor titular de ESTA sección puede "alertar" (notificar notas
    // y notificar alumnos en riesgo). El JP la ve pero no ejecuta esas acciones.
    final isProfesor = AuthService.to.isProfesorOfSection(
      int.tryParse(widget.idSeccion) ?? -1,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262630) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF4C4C5C)
                      : const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.courseName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF2D2D2D),
                    ),
                  ),
                ),
                _isLoading
                    ? const SizedBox(width: 48, height: 48)
                    : Badge(
                        isLabelVisible: _atRiskCount > 0,
                        label: Text(
                          '$_atRiskCount',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        smallSize: 20,
                        child: IconButton(
                          icon: Icon(
                            Icons.warning_amber_rounded,
                            color: _atRiskCount > 0
                                ? Colors.orange
                                : Colors.grey,
                            size: 24,
                          ),
                          tooltip: 'Alumnos impedidos y en riesgo',
                          onPressed: () async {
                            await SystemChrome.setPreferredOrientations(
                              HorarioPage._portraitOnly,
                            );
                            await Get.to(
                              () => AtRiskStudentsPage(
                                sectionId: widget.idSeccion,
                                courseName: widget.courseName,
                                sectionCode: widget.sectionCode,
                                isProfesor: isProfesor,
                              ),
                            );
                            await SystemChrome.setPreferredOrientations(
                              HorarioPage._scheduleOrientations,
                            );
                          },
                        ),
                      ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Sección ${widget.sectionCode}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            else ...[
              _infoRow(context, Icons.person, 'Delegado', _delegateName),
              const SizedBox(height: 8),
              _infoRow(
                context,
                Icons.person_outline,
                'Subdelegado',
                _subdelegateName,
              ),
              const SizedBox(height: 18),
              Text(
                'Estado de carga de notas:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 8),
              if (_assessments.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No hay evaluaciones programadas en el sílabo.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? const Color(0xFF9090A0)
                          : const Color(0xFF666666),
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _assessments.length,
                    itemBuilder: (context, index) {
                      final ass = _assessments[index];
                      final code = ass['code'] ?? '';
                      final name = ass['name'] ?? '';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$code: $name',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF2D2D2D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: _notifiedAssessments.contains(
                                  ass['id']?.toString(),
                                ),
                                // El JP ve el estado de carga pero NO puede
                                // notificar: el toggle queda deshabilitado. Solo
                                // el Profesor titular dispara la notificación.
                                onChanged: !isProfesor
                                    ? null
                                    : (val) {
                                        final assId =
                                            ass['id']?.toString() ?? '';
                                        if (val) {
                                          // Activar: marcar optimistamente y pedir confirmaci\u00f3n
                                          setState(
                                            () =>
                                                _notifiedAssessments.add(assId),
                                          );
                                          _confirmAndNotify(
                                            assId,
                                            ass['name'] ?? '',
                                            (ass['loadedCount'] as num?)
                                                    ?.toInt() ??
                                                0,
                                            (ass['totalCount'] as num?)
                                                    ?.toInt() ??
                                                0,
                                          );
                                        } else {
                                          // Desactivar: solo visual, sin llamada al backend
                                          setState(
                                            () => _notifiedAssessments.remove(
                                              assId,
                                            ),
                                          );
                                        }
                                      },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String title,
    String value,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          '$title: ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFB0B0C0) : const Color(0xFF666666),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF2D2D2D),
            ),
          ),
        ),
      ],
    );
  }
}
