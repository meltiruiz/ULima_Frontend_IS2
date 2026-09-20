import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../components/skeleton.dart';
import '../../configs/themes.dart';
import '../../models/academic_record_model.dart';
import '../../services/academic_record_service.dart';
import 'record_format.dart';
import 'record_position_badge.dart';

/// Tarjeta del récord académico en el Perfil (RF-REC-1).
///
/// Lee el mismo [AcademicRecordService] que la pantalla, así que las dos
/// comparten un solo estado (RF-REC-5): al volver con back, o mientras se
/// recarga, nunca se ve el PPA ni los créditos anteriores.
///
/// Es `StatefulWidget` porque `ProfilePage` no es reactiva y se vuelve a
/// montar cada vez que se abre la pestaña Perfil: la carga se dispara en
/// `initState`, no en `build`. Un dato `null` se omite; nunca se pinta 0.
class RecordProfileCard extends StatefulWidget {
  const RecordProfileCard({super.key});

  /// Marca el bloque de carga para los tests: con `SkeletonPulse` en pantalla
  /// no se puede usar `pumpAndSettle`.
  static const Key skeletonKey = Key('record-card-skeleton');

  static const String ppaLabel = 'PPA';
  static const String neverSyncedText =
      'Sincroniza con el portal para ver tu récord';
  static const String linkText = 'Ver mi récord completo ›';

  /// Título que se muestra cuando la carga falló: sin cifras, solo el nombre
  /// de la pantalla y el enlace para entrar y reintentar.
  static const String errorTitle = 'Mi récord académico';

  @override
  State<RecordProfileCard> createState() => _RecordProfileCardState();
}

class _RecordProfileCardState extends State<RecordProfileCard> {
  @override
  void initState() {
    super.initState();
    // Después del frame, nunca durante build: load() cambia Rx y un Obx que
    // reaccionara haría setState en plena construcción del árbol.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // La guarda de docente y la caché por usuario ya están en el servicio.
      if (mounted) AcademicRecordService.to.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Semantics(
      button: true,
      label: 'Mi récord académico',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Get.toNamed<dynamic>('/mi-record'),
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: MaterialTheme.cardBg(brightness),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: MaterialTheme.borderColor(brightness)),
            ),
            child: Obx(() {
              final servicio = AcademicRecordService.to;
              // Los dos Rx se leen siempre, pase lo que pase después: así el
              // Obx queda suscrito a los dos en cualquier estado.
              final record = servicio.record;
              final hasError = servicio.hasError;

              if (record == null) {
                return hasError ? _error(brightness) : _cargando();
              }
              if (!record.hasRecord) return _sinSincronizar(brightness);
              return _conRecord(brightness, record.snapshot);
            }),
          ),
        ),
      ),
    );
  }

  Widget _cargando() => const SkeletonPulse(
    key: RecordProfileCard.skeletonKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SkeletonBox(width: 40, height: 10),
        SizedBox(height: 6),
        SkeletonBox(width: 90, height: 26),
        SizedBox(height: 12),
        SkeletonBox(width: double.infinity, height: 6),
      ],
    ),
  );

  Widget _error(Brightness brightness) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        RecordProfileCard.errorTitle,
        style: TextStyle(
          color: MaterialTheme.textPrimary(brightness),
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 6),
      const Text(
        RecordProfileCard.linkText,
        style: TextStyle(
          color: MaterialTheme.primaryDark,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );

  Widget _sinSincronizar(Brightness brightness) => Row(
    children: [
      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: MaterialTheme.espPrincipalBg(brightness),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.history_edu_outlined,
          color: MaterialTheme.primaryDark,
          size: 20,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          RecordProfileCard.neverSyncedText,
          style: TextStyle(
            color: MaterialTheme.textPrimary(brightness),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Icon(
        LucideIcons.chevronRight,
        size: 18,
        color: MaterialTheme.labelColor(brightness),
      ),
    ],
  );

  Widget _conRecord(Brightness brightness, AcademicSnapshot? snapshot) {
    final ppa = snapshot?.ppa;
    final posicion = formatRelativePosition(snapshot?.relativePosition);
    final progreso = creditsProgress(
      snapshot?.creditsAccumulated,
      snapshot?.creditsRequired,
    );
    final creditos = creditsOfRequiredLabel(
      snapshot?.creditsAccumulated,
      snapshot?.creditsRequired,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Cada bloque solo se monta si su dato vino: RF-REC-1, "Datos que
        // faltan". Nunca se rellena con 0.
        if (ppa != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    RecordProfileCard.ppaLabel,
                    style: TextStyle(
                      color: MaterialTheme.labelColor(brightness),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    formatDecimal(ppa),
                    style: TextStyle(
                      color: MaterialTheme.textPrimary(brightness),
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (posicion != null) RecordPositionBadge(label: posicion),
            ],
          )
        else if (posicion != null)
          Align(
            alignment: Alignment.centerLeft,
            child: RecordPositionBadge(label: posicion),
          ),
        if (progreso != null) ...[
          const SizedBox(height: 10),
          Text(
            // creditsOfRequiredLabel tiene las mismas guardas que
            // creditsProgress: si hay barra, hay texto.
            creditos!,
            style: TextStyle(
              color: MaterialTheme.textSecondary(brightness),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progreso,
              minHeight: 6,
              backgroundColor: MaterialTheme.progressBg(brightness),
              color: MaterialTheme.primaryColor,
            ),
          ),
        ],
        const SizedBox(height: 10),
        const Text(
          RecordProfileCard.linkText,
          style: TextStyle(
            color: MaterialTheme.primaryDark,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
