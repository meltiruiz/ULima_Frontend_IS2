import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../configs/themes.dart';
import '../../models/seccion_model.dart';
import 'anuncios_tab.dart';
import 'asesoria_tab.dart';
import 'contactos_tab.dart';
import 'descrip_cursos_controller.dart';
import '../../components/skeleton.dart';

class DescripCursosPage extends StatelessWidget {
  final String idSeccion;
  final DescripCursosController control = Get.put(DescripCursosController());

  DescripCursosPage({super.key, required this.idSeccion}) {
    control.cargarDatosCurso(idSeccion);
  }

  Color _sectionBackground(ColorScheme colors) =>
      MaterialTheme.bloqueSeccion(colors.brightness);
  Color _attendanceBackground(ColorScheme colors) =>
      MaterialTheme.bloqueAsistencia(colors.brightness);
  Color _attendanceDivider(ColorScheme colors) =>
      MaterialTheme.bloqueAsistenciaLinea(colors.brightness);

  Widget _courseTitle(BuildContext context, Seccion seccion) {
    ColorScheme colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.primary,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.paddingOf(context).top + 30,
          20,
          18,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Text(
                seccion.curso,
                style: TextStyle(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),

            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: () {
                  Get.back();
                },
                child: Icon(Icons.arrow_back, color: colors.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(BuildContext context, Seccion seccion) {
    ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,

      color: _sectionBackground(colors),

      padding: const EdgeInsets.symmetric(vertical: 10),

      child: Center(
        child: Text(
          'Sección: ${seccion.codigoSeccion}',
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _asistencia(BuildContext context, Seccion seccion) {
    ColorScheme colors = Theme.of(context).colorScheme;

    int asistido = seccion.asistido;

    int inasistencia = seccion.inasistencia;

    int total = seccion.total;

    // "Sin datos" es SOLO cuando el portal no reportó horas para esta matrícula.
    // Un ciclo recién empezado (64 programadas, 0 dictadas) SÍ es un dato: el
    // anillo se muestra vacío, que es exactamente lo que pasó. Antes se exigía
    // además un porcentaje no nulo y ese caso caía por error en "sin datos".
    //
    // El anillo ya no usa un porcentaje único: pinta dos arcos sobre el total
    // (ver `_AnilloAsistencia`). El `NaN` que clampeaba al máximo y pintaba la
    // dona llena y verde murió con eso. Ver RS-BE-10 y RS-BE-16.
    if (!seccion.asistenciaDisponible) {
      return _asistenciaSinDatos(context, colors);
    }

    return Container(
      width: double.infinity,

      color: _attendanceBackground(colors),

      padding: const EdgeInsets.all(20),

      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,

            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const Text(
                      'Asistencia',

                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        const Text(
                          '✓',

                          style: TextStyle(color: Colors.green, fontSize: 22),
                        ),

                        const SizedBox(width: 16),

                        Text('$asistido horas'),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Text(
                          '✗',

                          style: TextStyle(color: Colors.red, fontSize: 22),
                        ),

                        const SizedBox(width: 16),

                        Text('$inasistencia horas'),
                      ],
                    ),

                    const SizedBox(height: 14),

                    Container(height: 1, color: _attendanceDivider(colors)),

                    const SizedBox(height: 14),

                    Padding(
                      padding: const EdgeInsets.only(left: 38),

                      child: Text(
                        '$total horas',

                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),

                    // RS-BE-16: el anillo mide sobre lo DICTADO, no sobre el
                    // ciclo entero. Sin esta línea, un anillo lleno en la
                    // semana 2 se leería como "ya terminaste el curso".
                    Padding(
                      padding: const EdgeInsets.only(left: 38, top: 4),
                      child: Text(
                        '${seccion.horasTranscurridas} dictadas hasta hoy',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(
                width: 120,
                height: 120,

                child: Stack(
                  alignment: Alignment.center,

                  children: [
                    SizedBox(
                      width: 90,
                      height: 90,

                      child: CustomPaint(
                        painter: _AnilloAsistencia(
                          fraccionAsistida: seccion.fraccionAsistida,
                          fraccionFaltas: seccion.fraccionFaltas,
                          vacio: _attendanceDivider(colors),
                        ),
                      ),
                    ),

                    Container(
                      width: 48,
                      height: 48,

                      decoration: BoxDecoration(
                        color: _attendanceBackground(colors),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Estado honesto cuando no hay horas de asistencia cargadas.
  ///
  /// Deliberadamente NEUTRO, no verde: el verde es el color de "todo bien" en
  /// esta app, y "no sabemos" no es "todo bien". Tampoco muestra los tres ceros,
  /// que se leían como asistencia perfecta.
  Widget _asistenciaSinDatos(BuildContext context, ColorScheme colors) {
    return Container(
      width: double.infinity,
      color: _attendanceBackground(colors),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Asistencia',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.help_outline,
                color: colors.onSurfaceVariant,
                size: 22,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Sin datos de asistencia para este curso.',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Todavía no se importaron tus horas de clase desde miUlima.',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => Get.toNamed<dynamic>('/portal-sync'),
              icon: const Icon(Icons.sync, size: 18),
              label: const Text('Actualizar desde miUlima'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabItem({
    required BuildContext context,
    required IconData icon,
    required String text,
    required int index,
  }) {
    ColorScheme colors = Theme.of(context).colorScheme;
    return Obx(() {
      bool isSelected = control.selectedTab.value == index;
      return Expanded(
        child: InkWell(
          onTap: () {
            control.selectedTab.value = index;
            if (index == 2) control.fetchContactos(idSeccion);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isSelected ? colors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected ? colors.primary : Colors.grey,
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? colors.primary : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _tabs(BuildContext context) {
    ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      color: colors.surface,
      child: Row(
        children: [
          _tabItem(
            context: context,
            icon: Icons.notifications_none,
            text: 'Anuncios',
            index: 0,
          ),
          _tabItem(
            context: context,
            icon: Icons.bookmark_border,
            text: 'Asesorías',
            index: 1,
          ),
          _tabItem(
            context: context,
            icon: Icons.people_outline,
            text: 'Contactos',
            index: 2,
          ),
        ],
      ),
    );
  }

  Widget _selectedPage(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: Obx(() {
        switch (control.selectedTab.value) {
          case 0:
            return AnunciosTab(idSeccion: idSeccion);
          case 1:
            return AsesoriasTab(idSeccion: idSeccion);
          case 2:
            return ContactosTab(idSeccion: idSeccion);
          default:
            return AnunciosTab(idSeccion: idSeccion);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final seccion = control.getSeccionPorId(idSeccion);

      if (seccion == null) {
        // Skeleton con la silueta real de la pantalla (título + barra de
        // sección + bloque de asistencia con dona + tabs + cards), en lugar
        // del spinner central clásico.
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: SafeArea(
            child: SkeletonPulse(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: SkeletonBox(width: 220, height: 22, borderRadius: 6),
                  ),
                  const SizedBox(height: 14),
                  const SkeletonBox(
                    width: double.infinity,
                    height: 34,
                    borderRadius: 0,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              SkeletonBox(
                                width: 140,
                                height: 20,
                                borderRadius: 6,
                              ),
                              SizedBox(height: 14),
                              SkeletonBox(
                                width: 110,
                                height: 14,
                                borderRadius: 6,
                              ),
                              SizedBox(height: 10),
                              SkeletonBox(
                                width: 110,
                                height: 14,
                                borderRadius: 6,
                              ),
                              SizedBox(height: 14),
                              SkeletonBox(
                                width: 90,
                                height: 16,
                                borderRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SkeletonBox(
                          width: 90,
                          height: 90,
                          borderRadius: 45,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: const [
                        Expanded(
                          child: SkeletonBox(height: 28, borderRadius: 8),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: SkeletonBox(height: 28, borderRadius: 8),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: SkeletonBox(height: 28, borderRadius: 8),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Expanded(
                    child: SkeletonCardList(count: 2, showAvatar: false),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Column(
          children: [
            _courseTitle(context, seccion),
            _section(context, seccion),
            _asistencia(context, seccion),
            _tabs(context),
            Expanded(child: _selectedPage(context)),
          ],
        ),
      );
    });
  }
}


/// Anillo de asistencia: NACE VACÍO y se llena como las manecillas de un reloj.
///
/// Desde las 12 en punto y en sentido horario: primero el verde de las horas
/// asistidas, después el rojo de las faltas, y el resto SIN PINTAR porque son
/// clases que todavía no se dictaron.
///
/// Reemplaza a un `CircularProgressIndicator` con `backgroundColor: Colors.red`,
/// que pintaba de rojo todo lo no asistido: en la semana 2 mostraba 87.5% del
/// anillo en rojo, o sea afirmaba que el alumno había faltado a clases que
/// nunca ocurrieron.
class _AnilloAsistencia extends CustomPainter {
  const _AnilloAsistencia({
    required this.fraccionAsistida,
    required this.fraccionFaltas,
    required this.vacio,
  });

  final double fraccionAsistida;
  final double fraccionFaltas;

  /// Color de lo que todavía no se dictó. Neutro a propósito.
  final Color vacio;

  static const double _grosor = 16;
  static const double _arriba = -math.pi / 2;   // las 12 en punto

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height)
        .deflate(_grosor / 2);
    final trazo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _grosor;

    // Pista completa: el anillo vacío que se va a ir llenando.
    canvas.drawCircle(rect.center, rect.width / 2, trazo..color = vacio);

    final verde = fraccionAsistida.clamp(0.0, 1.0) * 2 * math.pi;
    final rojo = fraccionFaltas.clamp(0.0, 1.0) * 2 * math.pi;

    if (verde > 0) {
      canvas.drawArc(rect, _arriba, verde, false, trazo..color = Colors.green);
    }
    if (rojo > 0) {
      canvas.drawArc(rect, _arriba + verde, rojo, false, trazo..color = Colors.red);
    }
  }

  @override
  bool shouldRepaint(_AnilloAsistencia old) =>
      old.fraccionAsistida != fraccionAsistida ||
      old.fraccionFaltas != fraccionFaltas ||
      old.vacio != vacio;
}
