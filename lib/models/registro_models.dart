/// Modelos del alta de cuenta contra miUlima (HU33).
///
/// `POST /auth/register` devuelve un cuerpo **plano**: no tiene los `period` ni
/// `identity` anidados de `POST /portal-sync/import`, así que `PortalSyncResult`
/// no sirve acá. `summary` y `warnings` sí son idénticos y se reutilizan.
library;

import 'portal_sync_models.dart';
import 'user_model.dart';

/// Lo que devuelve un registro exitoso.
class RegistroResult {
  const RegistroResult({
    required this.token,
    required this.user,
    required this.summary,
    required this.warnings,
  });

  final String token;

  /// El usuario tal como quedó en la base. Su `code` es el que certificó el
  /// portal, que puede no ser el que la persona tecleó (BR-REG-F-06).
  final UserModel user;

  final PortalSyncSummary summary;

  /// Un registro exitoso puede traerlos: sílabos caídos, panel de delegados
  /// fuera de servicio, `CAREER_MISMATCH`. No son errores (BR-REG-F-07).
  final List<PortalSyncWarning> warnings;

  factory RegistroResult.fromJson(Map<String, dynamic> json) {
    final usuario = json['user'];
    final resumen = json['summary'];
    final avisos = json['warnings'];
    return RegistroResult(
      token: json['token']?.toString() ?? '',
      user: UserModel.fromJson(
        usuario is Map ? Map<String, dynamic>.from(usuario) : <String, dynamic>{},
      ),
      summary: resumen is Map<String, dynamic>
          ? PortalSyncSummary.fromJson(resumen)
          : const PortalSyncSummary(
              coursesCreated: 0,
              sectionsCreated: 0,
              sectionsUpdated: 0,
              sessionsUpserted: 0,
              enrollmentsUpserted: 0,
              enrollmentsWithdrawn: 0,
              progressUpserted: 0,
              syllabiUpserted: 0,
            ),
      warnings: avisos is List
          ? avisos
              .whereType<Map<String, dynamic>>()
              .map(PortalSyncWarning.fromJson)
              .toList()
          : const <PortalSyncWarning>[],
    );
  }
}

/// Fallo del registro con un mensaje ya listo para mostrar.
///
/// `code` es el del backend cuando el fallo vino de él, o uno interno
/// (`TIEMPO_AGOTADO`, `SIN_TOKEN`, `SIN_CONEXION`) cuando lo produjo el
/// cliente. La pantalla decide a qué paso volver mirando ese código.
class RegistroFailure implements Exception {
  const RegistroFailure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'RegistroFailure($code): $message';
}
