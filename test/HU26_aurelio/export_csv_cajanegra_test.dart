// test/HU26_aurelio/export_csv_cajanegra_test.dart
//
// CAJA NEGRA — HU26: exportación de la lista de impedidos a CSV.
// Método: AttendanceRiskService.exportCsv()  — lib/services/attendance_risk_service.dart
//
// Se valida la SALIDA observable por el docente al tocar "Exportar CSV":
//   · nombre del archivo compartido: Ausencias_<Curso>_S<sección>.csv
//   · encabezado de 8 columnas
//   · una fila por alumno con % (1 decimal) y la etiqueta de estado
//   · el diálogo de compartir recibe ese mismo archivo y el texto del reporte
//
// DOBLES DE PRUEBA (plataformas nativas, no lógica):
//   · PathProviderPlatform -> carpeta temporal del test (sin canal nativo)
//   · SharePlatform        -> espía que captura qué se compartió
// La generación del CSV (StringBuffer + formato) es 100% real.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';
import 'package:ulima_plus/models/at_risk_student_model.dart';
import 'package:ulima_plus/services/attendance_risk_service.dart';

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.tempPath);

  final String tempPath;

  @override
  Future<String?> getTemporaryPath() async => tempPath;
}

class _SpyShare extends SharePlatform {
  ShareParams? ultimo;

  @override
  Future<ShareResult> share(ShareParams params) async {
    ultimo = params;
    return ShareResult('ok', ShareResultStatus.success);
  }
}

AtRiskStudent alumno({
  required String code,
  required String firstName,
  required String lastName,
  required int currentLevel,
  required int absent,
  required double pct,
  required String status,
  int? faltas,
}) =>
    AtRiskStudent(
      code: code,
      firstName: firstName,
      lastName: lastName,
      currentLevel: currentLevel,
      cycle: 3,
      absentHours: absent,
      totalHours: 100,
      absencePercentage: pct,
      status: status,
      missingFaltas: faltas,
    );

void main() {
  test('CN1: genera Ausencias_<Curso>_S<sección>.csv con encabezado y una fila por alumno', () async {
    final tmp = await Directory.systemTemp.createTemp('hu26_csv_');
    addTearDown(() => tmp.delete(recursive: true));

    PathProviderPlatform.instance = _FakePathProvider(tmp.path);
    final share = _SpyShare();
    SharePlatform.instance = share;

    final estudiantes = [
      alumno(
        code: '20230001',
        firstName: 'Maria',
        lastName: 'Garcia Lopez',
        currentLevel: 5,
        absent: 40,
        pct: 40.0,
        status: 'impedido',
      ),
      alumno(
        code: '20230002',
        firstName: 'Luis',
        lastName: 'Torres Vega',
        currentLevel: 4,
        absent: 21,
        pct: 21.5,
        status: 'en_riesgo',
        faltas: 2,
      ),
    ];

    await AttendanceRiskService()
        .exportCsv(estudiantes, 'Ingenieria de Software', '801');

    // El archivo se crea con el curso saneado (espacios -> _) y la sección.
    final file = File('${tmp.path}/Ausencias_Ingenieria_de_Software_S801.csv');
    expect(file.existsSync(), isTrue);

    final lineas = file.readAsStringSync().trim().split(RegExp(r'\r?\n'));
    expect(lineas, hasLength(3));
    expect(
      lineas[0],
      'Codigo,Apellidos,Nombres,Ciclo,Horas Ausentes,Total Horas,% Ausencia,Estado',
    );
    expect(lineas[1], '20230001,Garcia Lopez,Maria,5,40,100,40.0,Impedido');
    expect(
      lineas[2],
      '20230002,Torres Vega,Luis,4,21,100,21.5,En Riesgo: a 2 faltas',
    );

    // El diálogo de compartir recibió exactamente ese archivo y el texto.
    expect(share.ultimo, isNotNull);
    expect(share.ultimo!.files!.single.path, file.path);
    expect(
      share.ultimo!.text,
      'Reporte de ausencias - Ingenieria de Software (Seccion 801)',
    );
  });

  test('CN2: lista vacía -> CSV solo con el encabezado (sin filas fantasma)', () async {
    final tmp = await Directory.systemTemp.createTemp('hu26_csv_vacio_');
    addTearDown(() => tmp.delete(recursive: true));

    PathProviderPlatform.instance = _FakePathProvider(tmp.path);
    SharePlatform.instance = _SpyShare();

    await AttendanceRiskService().exportCsv(const [], 'Calculo 1', '305');

    final file = File('${tmp.path}/Ausencias_Calculo_1_S305.csv');
    expect(file.existsSync(), isTrue);

    final lineas = file.readAsStringSync().trim().split(RegExp(r'\r?\n'));
    expect(lineas, hasLength(1));
    expect(
      lineas[0],
      'Codigo,Apellidos,Nombres,Ciclo,Horas Ausentes,Total Horas,% Ausencia,Estado',
    );
  });
}
