/// Modelos de la carga de ciclo desde miUlima (portal-sync).
///
/// `fromJson` a mano con coerción defensiva, como el resto del repo: el backend
/// devuelve enteros, pero un cambio de serialización que los mande como texto no
/// debe romper la pantalla.
library;

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

String _asString(dynamic v) => v == null ? '' : v.toString();

/// Período académico tal como lo reporta el backend.
class PortalSyncPeriod {
  const PortalSyncPeriod({required this.id, required this.code});

  final int id;
  final String code;

  factory PortalSyncPeriod.fromJson(Map<String, dynamic> json) =>
      PortalSyncPeriod(id: _asInt(json['id']), code: _asString(json['code']));
}

/// Respuesta de `GET /portal-sync/status`.
///
/// `activePeriod` puede ser null: el contrato lo permite cuando todavía no hay
/// ningún período activo, y en ese caso `needsImport` viene true.
class PortalSyncStatus {
  const PortalSyncStatus({
    required this.activePeriod,
    required this.enrollmentsInActivePeriod,
    required this.needsImport,
  });

  final PortalSyncPeriod? activePeriod;
  final int enrollmentsInActivePeriod;
  final bool needsImport;

  factory PortalSyncStatus.fromJson(Map<String, dynamic> json) {
    final periodo = json['activePeriod'];
    return PortalSyncStatus(
      activePeriod: periodo is Map<String, dynamic>
          ? PortalSyncPeriod.fromJson(periodo)
          : null,
      enrollmentsInActivePeriod: _asInt(json['enrollmentsInActivePeriod']),
      needsImport: json['needsImport'] == true,
    );
  }

  /// Estado seguro cuando `/portal-sync/status` falla: sin aviso.
  ///
  /// Un fallo del status NO debe mostrar el banner. Proponerle cargar sus datos
  /// a un alumno que ya los tiene es peor que no proponérselo a uno que los
  /// necesita: el segundo igual puede entrar desde Perfil.
  static const PortalSyncStatus desconocido = PortalSyncStatus(
    activePeriod: null,
    enrollmentsInActivePeriod: 0,
    needsImport: false,
  );
}

/// Advertencia de la importación. El backend define nueve códigos posibles; la
/// app muestra `message` tal cual, así que no hace falta enumerarlos acá.
class PortalSyncWarning {
  const PortalSyncWarning({
    required this.code,
    required this.block,
    required this.message,
  });

  final String code;
  final String block;
  final String message;

  factory PortalSyncWarning.fromJson(Map<String, dynamic> json) =>
      PortalSyncWarning(
        code: _asString(json['code']),
        block: _asString(json['block']),
        message: _asString(json['message']),
      );
}

/// Contadores de lo que la importación escribió.
class PortalSyncSummary {
  const PortalSyncSummary({
    required this.coursesCreated,
    required this.sectionsCreated,
    required this.sectionsUpdated,
    required this.sessionsUpserted,
    required this.enrollmentsUpserted,
    required this.enrollmentsWithdrawn,
    required this.progressUpserted,
    required this.syllabiUpserted,
  });

  final int coursesCreated;
  final int sectionsCreated;
  final int sectionsUpdated;
  final int sessionsUpserted;
  final int enrollmentsUpserted;
  final int enrollmentsWithdrawn;
  final int progressUpserted;
  final int syllabiUpserted;

  /// Los cursos del ciclo, que es el número que al alumno le importa.
  int get cursos => enrollmentsUpserted;

  factory PortalSyncSummary.fromJson(Map<String, dynamic> json) =>
      PortalSyncSummary(
        coursesCreated: _asInt(json['coursesCreated']),
        sectionsCreated: _asInt(json['sectionsCreated']),
        sectionsUpdated: _asInt(json['sectionsUpdated']),
        sessionsUpserted: _asInt(json['sessionsUpserted']),
        enrollmentsUpserted: _asInt(json['enrollmentsUpserted']),
        enrollmentsWithdrawn: _asInt(json['enrollmentsWithdrawn']),
        progressUpserted: _asInt(json['progressUpserted']),
        syllabiUpserted: _asInt(json['syllabiUpserted']),
      );
}

/// Respuesta de `POST /portal-sync/import`.
class PortalSyncResult {
  const PortalSyncResult({
    required this.periodCode,
    required this.fullName,
    required this.career,
    required this.summary,
    required this.warnings,
  });

  final String periodCode;
  final String fullName;
  final String career;
  final PortalSyncSummary summary;
  final List<PortalSyncWarning> warnings;

  factory PortalSyncResult.fromJson(Map<String, dynamic> json) {
    final periodo = json['period'];
    final identidad = json['identity'];
    final resumen = json['summary'];
    final avisos = json['warnings'];
    return PortalSyncResult(
      periodCode: periodo is Map<String, dynamic> ? _asString(periodo['code']) : '',
      fullName: identidad is Map<String, dynamic> ? _asString(identidad['fullName']) : '',
      career: identidad is Map<String, dynamic> ? _asString(identidad['career']) : '',
      summary: resumen is Map<String, dynamic>
          ? PortalSyncSummary.fromJson(resumen)
          : const PortalSyncSummary(
              coursesCreated: 0, sectionsCreated: 0, sectionsUpdated: 0,
              sessionsUpserted: 0, enrollmentsUpserted: 0, enrollmentsWithdrawn: 0,
              progressUpserted: 0, syllabiUpserted: 0,
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
