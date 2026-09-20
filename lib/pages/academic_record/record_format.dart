/// Formato puro del récord académico: lo que comparten la tarjeta del Perfil
/// (RF-REC-1) y el encabezado de la pantalla (RF-REC-2).
///
/// Sin imports de Flutter a propósito: son funciones sobre `double?` y
/// `String?`, probadas sin montar widgets. Conservan el `null`: un dato que no
/// vino se omite en la UI, nunca se pinta como 0 (precedente RS-BE-10).
library;

/// Proporción de créditos acumulados sobre los requeridos, entre 0 y 1.
///
/// Devuelve `null` —y entonces no se dibujan ni la barra ni el anillo— si
/// falta cualquiera de los dos datos o si los requeridos son 0 o menos.
double? creditsProgress(double? accumulated, double? requiredCredits) {
  if (accumulated == null || requiredCredits == null) return null;
  if (requiredCredits <= 0) return null;
  return (accumulated / requiredCredits).clamp(0.0, 1.0).toDouble();
}

/// Número tal como se muestra: sin redondear y sin el `.0` de los enteros.
String formatDecimal(double value) {
  if (!value.isFinite) return value.toString();
  return value == value.truncateToDouble()
      ? value.toInt().toString()
      : value.toString();
}

/// "164 de 200 créditos", con las mismas guardas que [creditsProgress].
String? creditsOfRequiredLabel(double? accumulated, double? requiredCredits) {
  if (creditsProgress(accumulated, requiredCredits) == null) return null;
  return '${formatDecimal(accumulated!)} de '
      '${formatDecimal(requiredCredits!)} créditos';
}

/// "1.5 créd." | "3 créd.".
String creditsShortLabel(double credits) => '${formatDecimal(credits)} créd.';

/// "TERCIO SUPERIOR" del portal en tipo oración: "Tercio superior".
///
/// `null` si no hay dato o si viene en blanco: entonces no hay insignia.
String? formatRelativePosition(String? raw) {
  final texto = (raw ?? '')
      .trim()
      .split(' ')
      .where((parte) => parte.isNotEmpty)
      .join(' ');
  if (texto.isEmpty) return null;
  final minusculas = texto.toLowerCase();
  return minusculas[0].toUpperCase() + minusculas.substring(1);
}

/// Porcentaje del anillo, redondeado al entero: "82%".
String progressPercentLabel(double progress) =>
    '${(progress.clamp(0.0, 1.0) * 100).round()}%';
