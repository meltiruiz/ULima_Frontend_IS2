// lib/components/recarga_ulima/aviso_recarga.dart
//
// El aviso rojo persistente de una recarga fallida (RF-RCG-4 de
// specs/features/recarga-portal/recarga-portal.spec.md), en su versión de
// tarjeta para /mis-notas y en su versión compacta para el bloque de
// asistencia (RF-RCG-8), y la acción de su botón.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../configs/themes.dart';
import '../../domain/recarga_ulima/avisos_recarga.dart';
import '../../domain/recarga_ulima/ultima_lectura.dart';
import '../../services/recarga_ulima_service.dart';
import 'hoja_recarga_ulima.dart';

/// Lo que hace el botón del aviso, o el de recarga si no hay aviso.
///
/// `Reintentar` abre otra vez la hoja, vacía. `Cargar mis datos` borra el
/// aviso, abre `/portal-sync`, espera su resultado y, si vuelve `true`, pide
/// otra vez la vista. Devuelve `true` solo si una recarga queda guardada.
Future<bool> ejecutarAccionRecarga(
  BuildContext context,
  AvisoRecarga? aviso,
) async {
  if (aviso?.accion == AccionAviso.cargarMisDatos) {
    final servicio = RecargaUlimaService.to;
    servicio.borrarAviso();
    final cargado = await Get.toNamed<dynamic>('/portal-sync');
    if (cargado == true) await servicio.cargar();
    return false;
  }
  return abrirHojaRecargaUlima(context);
}

/// El aviso en lugar de la franja de `/mis-notas`.
class AvisoRecargaTarjeta extends StatelessWidget {
  const AvisoRecargaTarjeta({
    super.key,
    required this.aviso,
    required this.ultimaLectura,
    required this.onAccion,
  });

  final AvisoRecarga aviso;

  /// La `lastReadAt` de la vista, o `null` si todavía no hay lectura.
  final DateTime? ultimaLectura;
  final VoidCallback onAccion;

  @override
  Widget build(BuildContext context) {
    final brillo = Theme.of(context).brightness;
    final secundario = TextStyle(
      fontSize: 11,
      color: MaterialTheme.textSecondary(brillo),
    );
    final lectura = ultimaLectura;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: MaterialTheme.cardBg(brillo),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AvisoRecarga.titulo,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: MaterialTheme.textPrimary(brillo),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(aviso.cuerpo, style: secundario),
                  if (lectura != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      textoNotasLeidas(lectura, DateTime.now()),
                      style: secundario,
                    ),
                  ],
                  BotonAccionRecarga(
                    texto: aviso.textoAccion,
                    onPressed: onAccion,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// El aviso compacto del bloque de asistencia de la ficha (RF-RCG-8).
class AvisoRecargaCompacto extends StatelessWidget {
  const AvisoRecargaCompacto({super.key, required this.aviso});

  final AvisoRecarga aviso;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AvisoRecarga.titulo,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
                Text(
                  aviso.cuerpo,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón de texto en el naranja de D11, con blanco táctil de 48.
class BotonAccionRecarga extends StatelessWidget {
  const BotonAccionRecarga({
    super.key,
    required this.texto,
    required this.onPressed,
    this.icono,
  });

  final String texto;
  final VoidCallback onPressed;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final brillo = Theme.of(context).brightness;
    final estilo = TextButton.styleFrom(
      foregroundColor: MaterialTheme.textoNaranja(brillo),
      minimumSize: const Size(48, 48),
      tapTargetSize: MaterialTapTargetSize.padded,
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
    );
    final icono = this.icono;
    if (icono == null) {
      return TextButton(
        onPressed: onPressed,
        style: estilo,
        child: Text(texto),
      );
    }
    return TextButton.icon(
      onPressed: onPressed,
      style: estilo,
      icon: Icon(icono, size: 18),
      label: Text(texto),
    );
  }
}
