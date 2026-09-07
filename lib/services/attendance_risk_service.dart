import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ulima_plus/models/at_risk_student_model.dart';

import 'api_client.dart';

class AttendanceRiskService {
  final ApiClient _api = ApiClient();

  Future<List<AtRiskStudent>> fetchAttendanceRisk(String sectionId) async {
    final data = await _api.getJson(
      '/attendance-risk/sections/$sectionId/attendance-risk',
    );
    final List<dynamic> rawStudents = data['students'] ?? [];
    return rawStudents
        .map((s) => AtRiskStudent.fromJson(Map<String, dynamic>.from(s as Map)))
        .toList();
  }

  Future<Map<String, dynamic>> fetchSummary(String sectionId) async {
    return await _api.getJson(
      '/attendance-risk/sections/$sectionId/attendance-risk/summary',
    );
  }

  Future<bool> notifyStudents(String sectionId) async {
    try {
      await _api.postJson(
        '/attendance-risk/sections/$sectionId/attendance-risk/notify',
        body: {},
      );
      return true;
    } catch (e) {
      debugPrint('Error notifying students: $e');
      return false;
    }
  }

  Future<void> exportCsv(List<AtRiskStudent> students, String courseName, String sectionCode) async {
    final buffer = StringBuffer();
    buffer.writeln('Codigo,Apellidos,Nombres,Ciclo,Horas Ausentes,Total Horas,% Ausencia,Estado');
    for (final s in students) {
      buffer.writeln(
        '${s.code},${s.lastName},${s.firstName},${s.currentLevel ?? ""},${s.absentHours},${s.totalHours},${s.absencePercentage?.toStringAsFixed(1) ?? ""},${s.statusLabel}',
      );
    }

    final dir = await getTemporaryDirectory();
    final sanitizedCourse = courseName.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');
    final file = File('${dir.path}/Ausencias_${sanitizedCourse}_S$sectionCode.csv');
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles([XFile(file.path)], text: 'Reporte de ausencias - $courseName (Seccion $sectionCode)');
  }
}
