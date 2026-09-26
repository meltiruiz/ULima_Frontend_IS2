import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/recarga_ulima/aviso_recarga.dart';
import '../../components/recarga_ulima/franja_recarga.dart';
import '../../components/recarga_ulima/hoja_recarga_ulima.dart';
import '../../components/skeleton.dart';
import '../../configs/themes.dart';
import '../../domain/recarga_ulima/formato_nota.dart';
import '../../models/recarga_ulima_models.dart';
import 'mis_notas_controller.dart';

/// Texto de la tarjeta de un curso sin lectura en la última recarga.
const String textoLecturaParcial = 'No se pudo leer en esta actualización.';

/// Notas oficiales del alumno, las que publica la ULima (RF-RCG-6). Solo
/// lectura, con la franja que abre la hoja de recarga.
class MisNotasPage extends StatelessWidget {
  const MisNotasPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MisNotasController>();
    final brightness = Theme.brightnessOf(context);

    return Scaffold(
      backgroundColor: MaterialTheme.pageBg(brightness),
      appBar: AppBar(
        title: const Text('Notas oficiales'),
        // El botón de refrescar vuelve a consultar a ULima++, además del tirón
        // hacia abajo, y no entra a miUlima, que es lo que hace la franja.
        actions: [
          Obx(
            () => IconButton(
              icon: controller.isLoading.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              tooltip: 'Actualizar notas',
              onPressed: controller.isLoading.value ? null : controller.load,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.load,
        color: MaterialTheme.primaryColor,
        child: Obx(() {
          final vista = controller.vista;
          final aviso = controller.aviso;
          final siglas = Map<String, String>.of(controller.siglas);

          if (vista == null) {
            if (controller.isLoading.value) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: SkeletonCardList(count: 4, showAvatar: false),
              );
            }
            if (controller.errorCarga) {
              return _fill(
                _Empty(
                  icon: Icons.wifi_off,
                  message: 'No se pudieron cargar tus notas oficiales.',
                  brightness: brightness,
                ),
              );
            }
          }
          if (vista == null || vista.cursos.isEmpty) {
            // Sin cursos no hay franja, porque una recarga responde
            // 409 IMPORT_REQUIRED.
            return _fill(
              _Empty(
                icon: Icons.school_outlined,
                message: 'Aún no tienes cursos con notas oficiales.',
                brightness: brightness,
              ),
            );
          }
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: aviso != null
                    ? AvisoRecargaTarjeta(
                        aviso: aviso,
                        ultimaLectura: vista.lastReadAt,
                        onAccion: () => ejecutarAccionRecarga(context, aviso),
                      )
                    : FranjaRecarga(
                        ultimaLectura: vista.lastReadAt,
                        onTap: () => abrirHojaRecargaUlima(context),
                      ),
              ),
              for (final curso in vista.cursos)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CourseCard(
                    curso: curso,
                    titulos: [
                      for (final e in curso.evaluaciones)
                        controller.titulo(e, siglas),
                    ],
                    notaFinal: controller.notaFinal(curso),
                    calificado: controller.tieneNotas(curso),
                    lineaEstado: controller.sinLectura(curso)
                        ? textoLecturaParcial
                        : (curso.lastReadAt == null &&
                              curso.evaluaciones.isEmpty)
                        ? textoSinLecturaUlima
                        : null,
                    brightness: brightness,
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _fill(Widget child) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [SizedBox(height: 400, child: Center(child: child))],
  );
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.curso,
    required this.titulos,
    required this.notaFinal,
    required this.calificado,
    required this.lineaEstado,
    required this.brightness,
  });

  final CursoUlima curso;

  /// El título de cada evaluación, en el orden de `curso.evaluaciones`.
  final List<String> titulos;
  final double notaFinal;
  final bool calificado;

  /// `Aún no se actualizan desde la ULima`, `No se pudo leer en esta
  /// actualización.` o nada.
  final String? lineaEstado;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final textPrimary = MaterialTheme.textPrimary(brightness);
    final textSecondary = MaterialTheme.textSecondary(brightness);
    final linea = lineaEstado;

    return Container(
      decoration: BoxDecoration(
        color: MaterialTheme.cardBg(brightness),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MaterialTheme.borderColor(brightness)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      curso.courseName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sección ${curso.sectionCode}',
                      style: TextStyle(fontSize: 13, color: textSecondary),
                    ),
                    if (linea != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        linea,
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              _FinalBadge(nota: notaFinal, calificado: calificado),
            ],
          ),
          if (curso.evaluaciones.isNotEmpty) const SizedBox(height: 12),
          for (var i = 0; i < curso.evaluaciones.length; i++)
            _AssessmentRow(
              evaluacion: curso.evaluaciones[i],
              titulo: titulos[i],
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
        ],
      ),
    );
  }
}

class _AssessmentRow extends StatelessWidget {
  const _AssessmentRow({
    required this.evaluacion,
    required this.titulo,
    required this.textPrimary,
    required this.textSecondary,
  });

  final EvaluacionUlima evaluacion;
  final String titulo;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final semana = evaluacion.week;
    final nota = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w800,
      color: textPrimary,
    );
    final valor = switch (evaluacion.mark) {
      MarcaUlima.graded => Text(
        formatoNotaUlima(evaluacion.value!),
        textAlign: TextAlign.right,
        style: nota,
      ),
      MarcaUlima.np => Text('NP', textAlign: TextAlign.right, style: nota),
      MarcaUlima.pending => Text(
        'Sin nota',
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textSecondary,
        ),
      ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(fontSize: 13, color: textPrimary),
                ),
                if (semana != null)
                  Text(
                    'Semana $semana',
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
              ],
            ),
          ),
          Text(
            formatoPeso(evaluacion.weight),
            style: TextStyle(fontSize: 12, color: textSecondary),
          ),
          const SizedBox(width: 14),
          SizedBox(width: 56, child: valor),
        ],
      ),
    );
  }
}

class _FinalBadge extends StatelessWidget {
  const _FinalBadge({required this.nota, required this.calificado});

  final double nota;
  final bool calificado;

  @override
  Widget build(BuildContext context) {
    if (!calificado) {
      return const SizedBox.shrink();
    }
    final aprobado = nota >= 10.5;
    final color = aprobado ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            'Final',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            nota.toStringAsFixed(2),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.icon,
    required this.message,
    required this.brightness,
  });

  final IconData icon;
  final String message;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final textSecondary = MaterialTheme.textSecondary(brightness);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 48, color: textSecondary),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: textSecondary),
          ),
        ),
      ],
    );
  }
}
