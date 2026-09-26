// lib/components/recarga_ulima/pie_asistencia.dart
//
// La recarga en el bloque de asistencia de la ficha del curso (RF-RCG-8 de
// specs/features/recarga-portal/recarga-portal.spec.md). La ficha monta estas
// piezas solo con `RecargaUlimaService` registrado.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/recarga_ulima/avisos_recarga.dart';
import '../../domain/recarga_ulima/ultima_lectura.dart';
import '../../services/recarga_ulima_service.dart';
import 'aviso_recarga.dart';

/// Texto de un curso sin lectura de asistencia en la última recarga.
const String textoAsistenciaSinLeer = 'No se pudo leer en esta actualización.';

Future<void> _actuar(
  BuildContext context,
  AvisoRecarga? aviso,
  Future<void> Function() alRecargar,
) async {
  if (await ejecutarAccionRecarga(context, aviso)) await alRecargar();
}

/// La fila bajo las horas y el anillo, con la hora de la última lectura a la
/// izquierda y «Actualizar» a la derecha (D1).
class PieAsistencia extends StatelessWidget {
  const PieAsistencia({
    super.key,
    required this.idSeccion,
    required this.leidaEn,
    required this.alRecargar,
  });

  final String idSeccion;

  /// `asistenciaLeidaEn` de la sección. Con `null` la línea no se pinta (D2).
  final DateTime? leidaEn;

  /// Lo que hace la ficha tras una recarga guardada, que es volver a leer su
  /// sección.
  final Future<void> Function() alRecargar;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Obx(() {
      final servicio = RecargaUlimaService.to;
      final aviso = servicio.ultimoAviso;
      final sinLeer = servicio.sinLecturaDeAsistencia(idSeccion);
      final leida = leidaEn;
      final secundario = TextStyle(
        fontSize: 12,
        color: colors.onSurfaceVariant,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: aviso != null
                    ? AvisoRecargaCompacto(aviso: aviso)
                    : leida == null
                    ? const SizedBox.shrink()
                    : Text(
                        textoUltimaLectura(leida, DateTime.now()),
                        style: secundario,
                      ),
              ),
              BotonAccionRecarga(
                texto: aviso?.textoAccion ?? 'Actualizar',
                icono: Icons.sync,
                onPressed: () => _actuar(context, aviso, alRecargar),
              ),
            ],
          ),
          if (aviso == null && sinLeer)
            Text(textoAsistenciaSinLeer, style: secundario),
        ],
      );
    });
  }
}

/// Las señales y el botón del estado sin datos, entre la línea explicativa y
/// el final del bloque (D3).
class RecargaSinDatos extends StatelessWidget {
  const RecargaSinDatos({
    super.key,
    required this.idSeccion,
    required this.alRecargar,
  });

  final String idSeccion;
  final Future<void> Function() alRecargar;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Obx(() {
      final servicio = RecargaUlimaService.to;
      final aviso = servicio.ultimoAviso;
      final sinLeer = servicio.sinLecturaDeAsistencia(idSeccion);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (aviso != null) ...[
            AvisoRecargaCompacto(aviso: aviso),
            const SizedBox(height: 12),
          ] else if (sinLeer) ...[
            Text(
              textoAsistenciaSinLeer,
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
          ],
          BotonAccionRecarga(
            texto: aviso?.textoAccion ?? 'Actualizar desde la ULima',
            icono: Icons.sync,
            onPressed: () => _actuar(context, aviso, alRecargar),
          ),
        ],
      );
    });
  }
}
