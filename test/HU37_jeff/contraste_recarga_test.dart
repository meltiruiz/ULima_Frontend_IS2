// test/HU37_jeff/contraste_recarga_test.dart
//
// UNITARIA · Recarga desde la ULima (specs/features/recarga-portal/
// recarga-portal.spec.md), RF-RCG-10, contraste de cada pieza nueva con los
// valores de lib/configs/themes.dart y la fórmula de WCAG 2.1. Quedan fuera
// el botón «Actualizar» de la hoja (D12) y el texto «Nota: …/20» de las filas
// de la ULima (D24), que la spec deja como el resto de la app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/pages/chat/chat_linea_tiempo.dart'
    show contrasteWcag;

/// [frente] con opacidad [alfa] pintado sobre [fondo].
Color _mezcla(Color frente, double alfa, Color fondo) =>
    Color.alphaBlend(frente.withValues(alpha: alfa), fondo);

/// Una fila de la tabla de RF-RCG-10.
typedef _Pieza = ({String nombre, Color frente, Color fondo, double minimo});

List<_Pieza> _piezas(Brightness b) {
  final esquema = b == Brightness.light
      ? MaterialTheme.lightScheme()
      : MaterialTheme.darkScheme();
  final fila = _mezcla(esquema.primary, 0.1, esquema.surface);
  final rojo = Colors.red;
  return [
    (
      nombre: 'segunda línea de la fila «Notas oficiales»',
      frente: _mezcla(esquema.onSurface, 0.7, fila),
      fondo: fila,
      minimo: 4.5,
    ),
    (
      nombre: 'ícono de la fila',
      frente: MaterialTheme.iconoNaranja(b),
      fondo: fila,
      minimo: 3,
    ),
    (
      nombre: 'flecha de la fila',
      frente: _mezcla(esquema.onSurface, 0.5, fila),
      fondo: fila,
      minimo: 3,
    ),
    (
      nombre: 'texto de la marca ULima',
      frente: MaterialTheme.insigniaUlimaTexto(b),
      fondo: MaterialTheme.espPrincipalBg(b),
      minimo: 4.5,
    ),
    (
      nombre: 'ícono de la franja',
      frente: MaterialTheme.primaryDark,
      fondo: MaterialTheme.espPrincipalBg(b),
      minimo: 3,
    ),
    (
      nombre: 'segunda línea de la franja y del aviso',
      frente: MaterialTheme.textSecondary(b),
      fondo: MaterialTheme.cardBg(b),
      minimo: 4.5,
    ),
    (
      nombre: 'acción del aviso',
      frente: MaterialTheme.textoNaranja(b),
      fondo: MaterialTheme.cardBg(b),
      minimo: 4.5,
    ),
    (
      nombre: 'ícono rojo del aviso sobre su caja',
      frente: rojo,
      fondo: _mezcla(rojo, 0.12, MaterialTheme.cardBg(b)),
      minimo: 3,
    ),
    (
      nombre: 'ícono rojo del aviso compacto',
      frente: rojo,
      fondo: MaterialTheme.bloqueAsistencia(b),
      minimo: 3,
    ),
    (
      nombre: 'botones «Actualizar» y del estado sin datos del bloque',
      frente: MaterialTheme.textoNaranja(b),
      fondo: MaterialTheme.bloqueAsistencia(b),
      minimo: 4.5,
    ),
    (
      nombre: 'aviso de consentimiento y ayuda de la hoja',
      frente: _mezcla(esquema.onSurface, 0.7, esquema.surface),
      fondo: esquema.surface,
      minimo: 4.5,
    ),
    (
      nombre: 'pista del campo de contraseña',
      frente: _mezcla(esquema.onSurface, 0.6, esquema.surface),
      fondo: esquema.surface,
      minimo: 4.5,
    ),
    (
      nombre: 'borde de las casillas y del campo',
      frente: _mezcla(esquema.onSurface, 0.5, esquema.surface),
      fondo: esquema.surface,
      minimo: 3,
    ),
  ];
}

void main() {
  for (final brillo in Brightness.values) {
    final tema = brillo == Brightness.light ? 'claro' : 'oscuro';
    group('UNITARIA · contraste de la recarga en $tema (RF-RCG-10)', () {
      for (final pieza in _piezas(brillo)) {
        test('${pieza.nombre} llega a ${pieza.minimo}:1', () {
          expect(
            contrasteWcag(pieza.frente, pieza.fondo),
            greaterThanOrEqualTo(pieza.minimo),
          );
        });
      }
    });
  }

  test('los dos naranjas de texto tienen el valor de D11', () {
    expect(
      MaterialTheme.textoNaranja(Brightness.light),
      const Color(0xFFA34300),
    );
    expect(
      MaterialTheme.textoNaranja(Brightness.dark),
      const Color(0xFFFF6600),
    );
    expect(
      MaterialTheme.insigniaUlimaTexto(Brightness.light),
      const Color(0xFFA34300),
    );
    expect(
      MaterialTheme.insigniaUlimaTexto(Brightness.dark),
      const Color(0xFFFF8C42),
    );
  });
}
