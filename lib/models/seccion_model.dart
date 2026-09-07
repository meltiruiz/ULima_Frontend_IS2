class Seccion {
  final String idSeccion;
  final String codigoSeccion;
  final String docenteCode;
  final double promedioSeccion;
  final String idCurso;
  final String curso;
  final int asistido;
  final int inasistencia;
  final int total;

  /// ¿Hay asistencia cargada para esta sección? Es una bandera POSITIVA a
  /// propósito: los `?? 0` de este archivo vuelven invisible cualquier `null`
  /// del backend, así que la ausencia de dato tiene que ser explícita.
  final bool asistenciaDisponible;

  /// Horas de clase ya DICTADAS (asistidas + faltas), no las del ciclo entero.
  /// RS-BE-16.
  final int horasTranscurridas;

  Seccion({
    required this.idSeccion,
    required this.codigoSeccion,
    required this.docenteCode,
    required this.promedioSeccion,
    required this.idCurso,
    required this.curso,
    required this.asistido,
    required this.inasistencia,
    required this.total,
    required this.asistenciaDisponible,
    required this.horasTranscurridas,
  });

  /// Fracción asistida (0..1) sobre las horas TRANSCURRIDAS, o `null` si
  /// todavía no se dictó ninguna.
  ///
  /// NUNCA devolver `asistido / total` sin esta guarda: con `total = 0` da
  /// `0/0 = NaN`, y `clampDouble` de Flutter resuelve NaN al MÁXIMO
  /// (`sky_engine/lib/ui/math.dart`: `if (x.isNaN) return max;`). El
  /// `CircularProgressIndicator` terminaba pintado lleno y verde, afirmándole
  /// al alumno que asistió al 100% justo cuando no se sabe nada.
  /// Fracción del ANILLO pintada de verde: horas asistidas sobre el total del
  /// ciclo. El anillo nace vacío y se llena como las manecillas de un reloj.
  ///
  /// Sobre el TOTAL y no sobre lo dictado a propósito: lo que todavía no se
  /// dictó tiene que quedar SIN PINTAR. Pintarlo de rojo —como hacía el
  /// `backgroundColor` del indicador— dice que faltaste a clases que no
  /// ocurrieron; pintarlo de verde dice que ya terminaste el curso.
  double get fraccionAsistida => total > 0 ? asistido / total : 0.0;

  /// Fracción del anillo pintada de rojo: horas de falta sobre el total.
  double get fraccionFaltas => total > 0 ? inasistencia / total : 0.0;

  /// RS-BE-16: se divide por lo dictado, no por el ciclo entero. Con 8 horas
  /// asistidas de 64 programadas en la semana 2, dividir por `total` daría
  /// 12.5% y el alumno leería "asististe al 12.5%" — la misma deshonestidad que
  /// arregló RS-BE-10, invertida.
  double? get porcentajeAsistencia {
    if (horasTranscurridas <= 0) return null;
    return asistido / horasTranscurridas;
  }

  factory Seccion.fromJson(Map<String, dynamic> json) {
    return Seccion(
      idSeccion: json['idSeccion']?.toString() ?? '',
      codigoSeccion: json['codigoSeccion']?.toString() ?? '',
      docenteCode: json['docenteCode']?.toString() ?? '',
      promedioSeccion: (json['promedioSeccion'] as num?)?.toDouble() ?? 0.0,
      idCurso: json['idCurso']?.toString() ?? '',
      curso: json['curso']?.toString() ?? 'Sin curso',
      asistido: (json['asistido'] as num?)?.toInt() ?? 0,
      inasistencia: (json['inasistencia'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      // El backend manda `asistenciaDisponible` desde RS-BE-10. Con un backend
      // viejo que todavía no lo emite se cae a la MISMA regla que usa el
      // servidor (`total > 0`), nunca a `true`.
      asistenciaDisponible: (json['asistenciaDisponible'] as bool?) ??
          (((json['total'] as num?)?.toInt() ?? 0) > 0),
      // Con un backend viejo que no lo emita, se reconstruye igual.
      horasTranscurridas: (json['horasTranscurridas'] as num?)?.toInt() ??
          (((json['asistido'] as num?)?.toInt() ?? 0) +
              ((json['inasistencia'] as num?)?.toInt() ?? 0)),
    );
  }
}
