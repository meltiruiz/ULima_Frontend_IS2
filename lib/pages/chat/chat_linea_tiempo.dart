// lib/pages/chat/chat_linea_tiempo.dart
//
// Piezas puras de la conversación de una sección (HU23), sin widgets ni
// estado, para probarlas aparte:
// - las iniciales del curso y su color (RF-CHAT-8);
// - el subtítulo del AppBar, «Sección N» o «Sin sección» (RF-CHAT-8), y la
//   etiqueta accesible de la tarjeta que abre el chat (RF-CHAT-6 y
//   RF-CHAT-13);
// - el día y la hora de un mensaje en hora de Lima, la etiqueta del día y si
//   antes de un mensaje va un separador (RF-CHAT-11);
// - si un mensaje abre grupo y si lleva el nombre del remitente (RF-CHAT-9).

import 'package:flutter/material.dart';

import '../../models/message.dart';

// ── Iniciales del curso (RF-CHAT-8) ─────────────────────────────────────────

/// Conectores que no cuentan para las iniciales, en minúscula.
const Set<String> _conectores = {
  'de',
  'del',
  'la',
  'las',
  'el',
  'los',
  'y',
  'e',
  'en',
  'para',
  'a',
  'al',
};

/// Romanos del I al X como palabra entera, sin distinguir mayúsculas.
final RegExp _romano = RegExp(
  r'^(I{1,3}|IV|VI{0,3}|IX|X)$',
  caseSensitive: false,
);

final RegExp _letra = RegExp(r'\p{L}', unicode: true);

/// Primera letra de [texto], en mayúscula y con su tilde, o `null` si no
/// tiene ninguna.
String? _primeraLetra(String texto) =>
    _letra.firstMatch(texto)?.group(0)?.toUpperCase();

/// Iniciales del curso para su círculo, con la regla de RF-CHAT-8:
/// 1. el nombre se recorta y se parte en palabras por los espacios;
/// 2. se descartan los conectores, los romanos del I al X y las palabras sin
///    letras, sin distinguir mayúsculas;
/// 3. las iniciales son la primera letra de las dos primeras palabras que
///    quedan, en mayúscula y con su tilde;
/// 4. si no queda ninguna, la primera letra del nombre, y si el nombre no
///    tiene letras, la cadena vacía (el círculo va sin texto).
String inicialesDeCurso(String nombre) {
  final palabras = nombre.trim().split(RegExp(r'\s+'));
  final quedan = palabras.where((p) {
    if (p.isEmpty) return false;
    if (_conectores.contains(p.toLowerCase())) return false;
    if (_romano.hasMatch(p)) return false;
    return _letra.hasMatch(p);
  });
  if (quedan.isEmpty) return _primeraLetra(nombre) ?? '';
  return quedan.take(2).map((p) => _primeraLetra(p)!).join();
}

/// Razón de contraste WCAG 2.x entre dos colores opacos, de 1 a 21.
double contrasteWcag(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final claro = la > lb ? la : lb;
  final oscuro = la > lb ? lb : la;
  return (claro + 0.05) / (oscuro + 0.05);
}

/// Color de las iniciales sobre [fondo]: blanco o negro, el que dé más
/// contraste. Con esta regla ningún fondo baja de 4,58:1.
Color colorDeIniciales(Color fondo) {
  final conBlanco = contrasteWcag(Colors.white, fondo);
  final conNegro = contrasteWcag(Colors.black, fondo);
  return conBlanco >= conNegro ? Colors.white : Colors.black;
}

// ── Subtítulo del AppBar y etiqueta de la tarjeta (RF-CHAT-8, 6 y 13) ──────

/// La sección de un chat en el subtítulo del AppBar (RF-CHAT-8), la fila de la
/// bandeja (RF-CHAT-6) y la tarjeta del docente (RF-CHAT-13): «Sección N» con
/// el código recortado, o solo «Sin sección» si el código llega nulo, vacío o
/// con solo espacios.
String etiquetaDeSeccion(String? codigo) {
  final limpio = codigo?.trim() ?? '';
  return limpio.isEmpty ? 'Sin sección' : 'Sección $limpio';
}

/// Etiqueta accesible de la tarjeta que abre el chat de un curso, en la
/// bandeja (RF-CHAT-6) y en Secciones del docente (RF-CHAT-13):
/// `Abrir el chat de <curso>, sección <N>` con el código recortado, o
/// `…, sin sección` si el código llega nulo, vacío o con solo espacios. La
/// sección va en la etiqueta para que dos secciones del mismo curso se
/// distingan.
String etiquetaParaAbrirElChat(String curso, String? codigo) {
  final limpio = codigo?.trim() ?? '';
  final seccion = limpio.isEmpty ? 'sin sección' : 'sección $limpio';
  return 'Abrir el chat de $curso, $seccion';
}

// ── Día y hora en Lima (RF-CHAT-11) ─────────────────────────────────────────

/// Lima está en UTC−5 todo el año, sin horario de verano, como `_nowInLima`
/// del horario.
///
/// Esta cuenta y las listas de días y meses de abajo repiten a propósito lo
/// que ya hacen `_nowInLima` (horario_controller.dart), `fechaEnLima`
/// (time_block_list_controller.dart), `syncedAgoLabel`
/// (academic_record_controller.dart) y `resumenDelDia`
/// (time_block_actions_sheet.dart). RF-CHAT-11 pide listas propias y los
/// `targets` de la spec del chat no incluyen esos archivos, así que juntarlos
/// en un helper común de fecha en Lima queda para un cambio con su propia
/// spec.
const Duration _desfaseLima = Duration(hours: 5);

const List<String> _dias = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

const List<String> _meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// Campos de pared de Lima (año, mes, día, hora y minuto) de [instante],
/// sin importar la zona del teléfono. El resultado va marcado como UTC para
/// que nadie lo vuelva a convertir.
DateTime enHoraDeLima(DateTime instante) =>
    instante.toUtc().subtract(_desfaseLima);

/// Hora de un mensaje, `HH:mm`, en hora de Lima.
String horaDeMensaje(DateTime createdAt) {
  final lima = enHoraDeLima(createdAt);
  final hh = lima.hour.toString().padLeft(2, '0');
  final mm = lima.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

/// Etiqueta del separador de [diaLima] vista desde [hoyLima]: «Hoy», «Ayer»
/// o el día completo, como «Lunes 21 de septiembre», sin año.
///
/// Las dos fechas son campos de pared de Lima (ver [enHoraDeLima]); solo
/// cuentan su año, su mes y su día, así que la hora no importa.
///
/// Un [diaLima] posterior a [hoyLima] también da el día completo. Pasa
/// cuando el reloj del teléfono va atrasado frente al `createdAt` del
/// servidor cerca de la medianoche de Lima. RF-CHAT-11 reserva «Hoy» para la
/// fecha actual en Lima, y un «Hoy» ahí dejaría el mensaje bajo un día que no
/// es el suyo, además de repetir «Hoy» en el separador de los mensajes del
/// día anterior. `syncedAgoLabel` sí lleva ese caso a «hoy», porque da una
/// sola etiqueta relativa y no una serie de separadores.
String etiquetaDeDia(DateTime diaLima, DateTime hoyLima) {
  final dia = DateTime.utc(diaLima.year, diaLima.month, diaLima.day);
  final hoy = DateTime.utc(hoyLima.year, hoyLima.month, hoyLima.day);
  final diferencia = hoy.difference(dia).inDays;
  if (diferencia == 0) return 'Hoy';
  if (diferencia == 1) return 'Ayer';
  return '${_dias[dia.weekday - 1]} ${dia.day} de ${_meses[dia.month - 1]}';
}

bool _mismoDiaEnLima(DateTime a, DateTime b) {
  final la = enHoraDeLima(a);
  final lb = enHoraDeLima(b);
  return la.year == lb.year && la.month == lb.month && la.day == lb.day;
}

/// Si antes de [actual] va un separador de día: es el primero de la lista o
/// el [anterior] es de otro día en hora de Lima. Una lápida cuenta como
/// mensaje de su día.
bool abreDia(ChatMessage actual, ChatMessage? anterior) =>
    anterior == null || !_mismoDiaEnLima(anterior.createdAt, actual.createdAt);

// ── Grupos de mensajes (RF-CHAT-9) ──────────────────────────────────────────

/// Si [actual] abre grupo: es el primero de la lista, el [anterior] tiene
/// otro `senderId`, es de otro día en hora de Lima o es una lápida. Vale igual
/// para propios, ajenos y mensajes de carnet.
bool abreGrupo(ChatMessage actual, ChatMessage? anterior) {
  if (abreDia(actual, anterior)) return true;
  if (anterior!.senderId != actual.senderId) return true;
  return anterior.deleted;
}

/// Si [actual] lleva el nombre del remitente: solo un mensaje ajeno (su
/// `senderId` no es [uidSesion]) que abre grupo. Un propio nunca lo lleva, y
/// una lápida tampoco, porque ya dice quién la borró.
bool llevaNombre(ChatMessage actual, ChatMessage? anterior, String uidSesion) {
  if (actual.deleted) return false;
  if (actual.senderId == uidSesion) return false;
  return abreGrupo(actual, anterior);
}
