// lib/domain/recarga_ulima/formato_nota.dart
//
// Formato del peso y de la nota de la recarga desde la ULima (D10 de
// specs/features/recarga-portal/recarga-portal.spec.md). Punto decimal, como
// el resto de la app.

/// Diferencia por debajo de la cual dos decimales se consideran iguales.
const double _tolerancia = 1e-9;

bool _esEntero(num v) => (v - v.roundToDouble()).abs() < _tolerancia;

/// El peso sin el signo, entero sin decimales (`20`) y con hasta dos
/// decimales si los tiene (`12.5`, `12.25`).
String numeroDePeso(num peso) {
  if (_esEntero(peso)) return peso.round().toString();
  var texto = peso.toStringAsFixed(2);
  if (texto.endsWith('0')) texto = texto.substring(0, texto.length - 1);
  return texto;
}

/// El peso con su signo, como `20%` o `12.5%`, en las dos pantallas.
String formatoPeso(num peso) => '${numeroDePeso(peso)}%';

/// La nota de `/mis-notas`, con un decimal si tiene uno o ninguno (`15.0`,
/// `14.5`) y con dos si los tiene (`14.25`).
String formatoNotaUlima(double nota) =>
    _esEntero(nota * 10) ? nota.toStringAsFixed(1) : nota.toStringAsFixed(2);

/// La nota de la calculadora, siempre con un decimal, en las dos clases de
/// filas, así que una tarjeta nunca mezcla `14.25` y `14.3`.
String formatoNotaCalculadora(double nota) => nota.toStringAsFixed(1);
