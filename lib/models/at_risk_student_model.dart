class AtRiskStudent {
  final String code;
  final String firstName;
  final String lastName;
  final int? currentLevel;
  final int? cycle;
  final int absentHours;
  final int totalHours;
  /// `null` cuando no hay asistencia cargada. Un 0 acá se leía como
  /// "cero faltas" y pintaba la fila de verde. Ver RS-BE-10.
  final double? absencePercentage;
  final String status;
  final int? missingFaltas;

  AtRiskStudent({
    required this.code,
    required this.firstName,
    required this.lastName,
    this.currentLevel,
    this.cycle,
    required this.absentHours,
    required this.totalHours,
    required this.absencePercentage,
    required this.status,
    this.missingFaltas,
  });

  bool get isImpedido => status == 'impedido';

  bool get isEnRiesgo => status == 'en_riesgo';

  bool get isNormal => status == 'normal';

  /// No es un grado de riesgo: es ausencia de medición.
  bool get isSinDatos => status == 'sin_datos';

  String get statusLabel {
    if (isImpedido) return 'Impedido';
    if (isEnRiesgo && missingFaltas != null) {
      return 'En Riesgo: a $missingFaltas faltas';
    }
    if (isSinDatos) return 'Sin datos';
    if (isNormal) return 'Normal';
    return status;
  }

  String get fullName => '$firstName $lastName';

  factory AtRiskStudent.fromJson(Map<String, dynamic> json) {
    return AtRiskStudent(
      code: json['code']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      currentLevel: (json['currentLevel'] as num?)?.toInt(),
      cycle: (json['cycle'] as num?)?.toInt(),
      absentHours: (json['absentHours'] as num?)?.toInt() ?? 0,
      totalHours: (json['totalHours'] as num?)?.toInt() ?? 0,
      absencePercentage: (json['absencePercentage'] as num?)?.toDouble(),
      status: json['status']?.toString() ?? '',
      missingFaltas: (json['missingFaltas'] as num?)?.toInt(),
    );
  }
}
