// lib/pages/specialty_test/specialty_test_logic.dart
// Funciones puras del test de especialidad (HU36). Ninguna toca la red, GetX
// ni el árbol de widgets, así que se prueban solas
// (test/HU36_jeff/specialty_test_logic_test.dart y
// test/HU36_jeff/specialty_test_contraste_test.dart).

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/specialty_test_models.dart';

// ── Color y contraste (RF-TEST-12) ────────────────────────────────────────────

/// Mínimo WCAG de un texto contra su fondo.
const double kContrasteTexto = 4.5;

/// Mínimo WCAG de un ícono que da información.
const double kContrasteIcono = 3.0;

/// Razón de contraste WCAG 2.x entre dos colores opacos, de 1 a 21.
double razonDeContraste(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final claro = la > lb ? la : lb;
  final oscuro = la > lb ? lb : la;
  return (claro + 0.05) / (oscuro + 0.05);
}

final RegExp _hex = RegExp(r'^#([0-9a-fA-F]{6})$');

/// El color de un hex `#RRGGBB`, o null si no se puede leer. Un null cuenta
/// como neutro y no invalida el contenido (RF-TEST-2).
Color? colorDeHex(String? hex) {
  final m = _hex.firstMatch(hex?.trim() ?? '');
  if (m == null) return null;
  return Color(0xFF000000 | int.parse(m.group(1)!, radix: 16));
}

/// El color de una especialidad en el tema, `color.light` o `color.dark`.
Color? colorDeEspecialidad(TestSpecialty? especialidad, Brightness brillo) {
  if (especialidad == null) return null;
  return colorDeHex(
    brillo == Brightness.light
        ? especialidad.colorLight
        : especialidad.colorDark,
  );
}

/// [color] al [alfa] sobre [fondo], ya opaco y redondeado a 8 bits por canal,
/// como lo pinta la pantalla. Así se miden la tarjeta encendida (12 %), la del
/// resultado en oscuro (18 %) y la insignia «IA».
Color tinte(Color color, Color fondo, double alfa) {
  int canal(double c, double f) => ((c * alfa + f * (1 - alfa)) * 255).round();
  return Color.fromARGB(
    255,
    canal(color.r, fondo.r),
    canal(color.g, fondo.g),
    canal(color.b, fondo.b),
  );
}

/// [color] un 20 % más oscuro, el extremo inferior del degradado de la
/// tarjeta de la ganadora en claro (RF-TEST-8).
Color oscurecido(Color color) => tinte(Colors.black, color, 0.2);

/// La guarda de RF-TEST-12. Devuelve [color] si llega al mínimo contra
/// [fondo] (4,5:1 como texto, 3:1 como ícono), o [respaldo] si no llega o si
/// es null. El contenido puede cambiar sin otro APK, así que la app no confía
/// a ciegas en sus colores.
Color colorQueSeLee(
  Color? color, {
  required Color fondo,
  required Color respaldo,
  bool esTexto = true,
}) {
  if (color == null) return respaldo;
  final minimo = esTexto ? kContrasteTexto : kContrasteIcono;
  return razonDeContraste(color, fondo) >= minimo ? color : respaldo;
}

// ── Íconos de las tareas y de las especialidades (RF-TEST-5, decisión 8) ────

/// El ícono de un nombre fuera del mapa o ausente. No es de ninguna
/// especialidad ni de ninguna tarea, así que no delata nada.
const IconData kIconoNeutro = LucideIcons.sparkles;

/// Mapa cerrado de los 52 nombres de Lucide de la versión 2026-09-25.4 a sus
/// constantes de `lucide_icons_flutter` 3.1.15, cada una con el camelCase de
/// su nombre. La app nunca arma un `IconData` con un punto de código que
/// llegue del servidor, porque el build de release recorta la fuente a las
/// constantes que nombra el código. Un nombre nuevo sale neutro hasta el
/// siguiente APK.
const Map<String, IconData> kIconosDelTest = <String, IconData>{
  // Las cuatro especialidades.
  'code-xml': LucideIcons.codeXml,
  'server-cog': LucideIcons.serverCog,
  'chart-column-big': LucideIcons.chartColumnBig,
  'gamepad-2': LucideIcons.gamepad2,
  // Las 48 tareas, 24 de las preguntas y 24 de los desempates.
  'shopping-cart': LucideIcons.shoppingCart,
  'shelving-unit': LucideIcons.shelvingUnit,
  'refrigerator': LucideIcons.refrigerator,
  'mountain': LucideIcons.mountain,
  'eye': LucideIcons.eye,
  'store': LucideIcons.store,
  'drumstick': LucideIcons.drumstick,
  'rabbit': LucideIcons.rabbit,
  'camera': LucideIcons.camera,
  'folder-search': LucideIcons.folderSearch,
  'school': LucideIcons.school,
  'drafting-compass': LucideIcons.draftingCompass,
  'rocket': LucideIcons.rocket,
  'smartphone': LucideIcons.smartphone,
  'hand-coins': LucideIcons.handCoins,
  'clipboard-pen-line': LucideIcons.clipboardPenLine,
  'ticket': LucideIcons.ticket,
  'clock-arrow-up': LucideIcons.clockArrowUp,
  'route': LucideIcons.route,
  'messages-square': LucideIcons.messagesSquare,
  'user-minus': LucideIcons.userMinus,
  'pencil': LucideIcons.pencil,
  'footprints': LucideIcons.footprints,
  'bus': LucideIcons.bus,
  'calendar-clock': LucideIcons.calendarClock,
  'hospital': LucideIcons.hospital,
  'key-round': LucideIcons.keyRound,
  'receipt': LucideIcons.receipt,
  'blocks': LucideIcons.blocks,
  'goal': LucideIcons.goal,
  'database': LucideIcons.database,
  'rocking-chair': LucideIcons.rockingChair,
  'land-plot': LucideIcons.landPlot,
  'dices': LucideIcons.dices,
  'ghost': LucideIcons.ghost,
  'headphones': LucideIcons.headphones,
  'siren': LucideIcons.siren,
  'badge-percent': LucideIcons.badgePercent,
  'stamp': LucideIcons.stamp,
  'graduation-cap': LucideIcons.graduationCap,
  'house-wifi': LucideIcons.houseWifi,
  'drama': LucideIcons.drama,
  'droplet': LucideIcons.droplet,
  'radio-tower': LucideIcons.radioTower,
  'soup': LucideIcons.soup,
  'map-pinned': LucideIcons.mapPinned,
  'split': LucideIcons.split,
  'pill-bottle': LucideIcons.pillBottle,
};

/// El ícono de [nombre], o [kIconoNeutro] si no está en el mapa o es null.
IconData iconoDelTest(String? nombre) => kIconosDelTest[nombre] ?? kIconoNeutro;

// ── La conversación con Ulises (RF-TEST-4) ────────────────────────────────────
//
// Un «paso» del recorrido es un índice. De 0 a T − 1 son las preguntas del
// contenido y desde T van los desempates, en orden.

/// El sello «Cierra el bloque k de B» que cae junto a un `blockClose`.
class SelloDeBloque {
  const SelloDeBloque(this.k, this.total);

  /// Orden de la pregunta entre las que traen `blockClose`.
  final int k;

  /// Cuántas preguntas del contenido traen `blockClose`.
  final int total;

  String get texto => 'Cierra el bloque $k de $total';

  @override
  bool operator ==(Object other) =>
      other is SelloDeBloque && other.k == k && other.total == total;

  @override
  int get hashCode => Object.hash(k, total);
}

/// El último turno de Ulises, con sus burbujas en orden y el sello si una de
/// ellas es un `blockClose`. La app no escribe ninguna línea propia.
class TurnoDeUlises {
  const TurnoDeUlises(this.lineas, {this.sello});

  final List<String> lineas;
  final SelloDeBloque? sello;
}

String? _rotar(List<String> lista, int n) =>
    lista.isEmpty ? null : lista[n % lista.length];

/// La reacción a la respuesta [respuesta] de la pregunta de índice [indice].
/// Un duelo usa su `reaction` o, sin ella, la lista de `pick`, `both` o
/// `none`; una escala, su `blockClose` o la lista de `scale`. De la lista va
/// la línea de índice N − 1 módulo su largo, donde N − 1 = [indice] + 1 es el
/// número de la pregunta respondida.
String? reaccionA(
  SpecialtyTestContent contenido,
  int indice,
  String respuesta,
) {
  final pregunta = contenido.questions[indice];
  final reacciones = contenido.ulises.reactions;
  final numero = indice + 1;
  if (pregunta.isDuel) {
    if (pregunta.reaction != null) return pregunta.reaction;
    final lista = switch (respuesta) {
      'both' => reacciones.both,
      'none' => reacciones.none,
      _ => reacciones.pick,
    };
    return _rotar(lista, numero);
  }
  return pregunta.blockClose ?? _rotar(reacciones.scale, numero);
}

/// El sello de la pregunta de índice [indice], o null si no trae
/// `blockClose`. El contrato no manda el campo `block`, y esta cuenta da el
/// mismo número.
SelloDeBloque? selloDe(SpecialtyTestContent contenido, int indice) {
  if (contenido.questions[indice].blockClose == null) return null;
  final conCierre = <int>[
    for (var i = 0; i < contenido.questions.length; i++)
      if (contenido.questions[i].blockClose != null) i,
  ];
  return SelloDeBloque(conCierre.indexOf(indice) + 1, conCierre.length);
}

/// El turno de Ulises antes de la pregunta de índice [indice].
TurnoDeUlises turnoAntesDePregunta(
  SpecialtyTestContent contenido,
  int indice,
  Map<String, String> respuestas,
) {
  final lineas = <String>[];
  SelloDeBloque? sello;
  if (indice == 0) {
    final ayuda = contenido.ulises.duelHelp;
    if (ayuda != null) lineas.add(ayuda);
  } else {
    final previa = contenido.questions[indice - 1];
    final reaccion = reaccionA(
      contenido,
      indice - 1,
      respuestas[previa.id] ?? '',
    );
    if (reaccion != null) lineas.add(reaccion);
    if (!previa.isDuel && previa.blockClose != null) {
      sello = selloDe(contenido, indice - 1);
    }
  }
  final primeraEscala = contenido.questions.indexWhere((q) => !q.isDuel);
  final ayudaEscala = contenido.ulises.scaleHelp;
  if (indice == primeraEscala && ayudaEscala != null) lineas.add(ayudaEscala);
  return TurnoDeUlises(lineas, sello: sello);
}

/// El turno antes de un desempate, con la línea que manda el servidor.
TurnoDeUlises turnoAntesDeDesempate(TiebreakRecord desempate) =>
    TurnoDeUlises([?desempate.ulisesLine]);

/// El turno de la espera, con el `blockClose` de la última pregunta y su
/// sello, si lo trae y la espera sigue a esa pregunta, y la línea de espera.
TurnoDeUlises turnoDeEspera(
  SpecialtyTestContent contenido, {
  required bool trasDesempate,
}) {
  final lineas = <String>[];
  SelloDeBloque? sello;
  if (!trasDesempate) {
    final ultima = contenido.questions.length - 1;
    final cierre = contenido.questions[ultima].blockClose;
    if (cierre != null) {
      lineas.add(cierre);
      sello = selloDe(contenido, ultima);
    }
  }
  final espera = contenido.ulises.loading;
  if (espera != null) lineas.add(espera);
  return TurnoDeUlises(lineas, sello: sello);
}

/// «Pregunta N de T», «Desempate 1» o «Desempate 2».
String subtituloDelPaso(SpecialtyTestContent contenido, int paso) {
  final total = contenido.totalQuestions;
  return paso < total
      ? 'Pregunta ${paso + 1} de $total'
      : 'Desempate ${paso - total + 1}';
}

/// El texto de una respuesta en el historial, que es la tarea elegida, «Me
/// gustan las dos», «Ninguna me llama» o, en una escala,
/// «`<etiqueta> · <tarea>`».
String textoDeRespuesta(
  SpecialtyTestContent contenido, {
  required List<TestTask> tareas,
  required String respuesta,
}) {
  if (tareas.length == 1) {
    final etiqueta = contenido.optionLabel(respuesta) ?? respuesta;
    return '$etiqueta · ${tareas.single.text}';
  }
  return switch (respuesta) {
    'top' => tareas.first.text,
    'bottom' => tareas.last.text,
    _ => contenido.optionLabel(respuesta) ?? respuesta,
  };
}

/// Una fila del historial, con el número de la pregunta, o «Desempate k», y
/// la respuesta.
class EntradaDelHistorial {
  const EntradaDelHistorial(this.etiqueta, this.respuesta);

  final String etiqueta;
  final String respuesta;
}

/// Lo respondido antes del paso [paso], en orden y sin colores.
List<EntradaDelHistorial> historial(
  SpecialtyTestContent contenido,
  Map<String, String> respuestas,
  List<TiebreakRecord> desempates,
  int paso,
) {
  final total = contenido.totalQuestions;
  final filas = <EntradaDelHistorial>[];
  for (var i = 0; i < paso && i < total; i++) {
    final pregunta = contenido.questions[i];
    final respuesta = respuestas[pregunta.id];
    if (respuesta == null) continue;
    filas.add(
      EntradaDelHistorial(
        '${i + 1}',
        textoDeRespuesta(
          contenido,
          tareas: pregunta.tasks,
          respuesta: respuesta,
        ),
      ),
    );
  }
  for (var j = 0; j < paso - total && j < desempates.length; j++) {
    final d = desempates[j];
    final respuesta = d.answer;
    if (respuesta == null) continue;
    filas.add(
      EntradaDelHistorial(
        'Desempate ${j + 1}',
        textoDeRespuesta(
          contenido,
          tareas: [d.tiebreak.top, d.tiebreak.bottom],
          respuesta: respuesta,
        ),
      ),
    );
  }
  return filas;
}

/// «N respuestas anteriores» o «1 respuesta anterior».
String textoDeLaPastilla(int n) =>
    n == 1 ? '1 respuesta anterior' : '$n respuestas anteriores';

/// La etiqueta de la pastilla para el lector de pantalla. Con una sola
/// respuesta va en singular, como la pastilla.
String etiquetaDeLaPastilla(int n, {required bool desplegada}) {
  if (desplegada) return 'Ocultar tus respuestas anteriores';
  return n == 1
      ? 'Ver tu respuesta anterior'
      : 'Ver tus $n respuestas anteriores';
}

/// Los desempates que quedan tras responder el paso [paso] con [respuesta].
/// Responder una pregunta los borra todos, porque el servidor decide cuáles
/// tocan. Responder el desempate i conserva los anteriores, le pone la
/// respuesta y borra los siguientes.
List<TiebreakRecord> desempatesTrasResponder({
  required int totalPreguntas,
  required List<TiebreakRecord> desempates,
  required int paso,
  required String respuesta,
}) {
  if (paso < totalPreguntas) return const <TiebreakRecord>[];
  final i = paso - totalPreguntas;
  return [...desempates.take(i), desempates[i].withAnswer(respuesta)];
}

/// El primer paso sin responder, o null si todo está respondido y toca
/// evaluar. Sirve para seguir un test en pausa (RF-TEST-3).
int? primerPasoSinResponder(
  SpecialtyTestContent contenido,
  Map<String, String> respuestas,
  List<TiebreakRecord> desempates,
) {
  final pregunta = contenido.questions.indexWhere(
    (q) => !respuestas.containsKey(q.id),
  );
  if (pregunta >= 0) return pregunta;
  final desempate = desempates.indexWhere((d) => d.answer == null);
  if (desempate >= 0) return contenido.totalQuestions + desempate;
  return null;
}

/// Cuántas preguntas del contenido tienen respuesta, la N de «Tienes un test
/// a medias, N de T.» (RF-TEST-10).
int preguntasRespondidas(
  SpecialtyTestContent contenido,
  Map<String, String> respuestas,
) => contenido.questions.where((q) => respuestas.containsKey(q.id)).length;

/// El cuerpo exacto de `POST /specialty-test/me/evaluate` (RS-BE-39), con la
/// versión con la que el alumno responde, las respuestas por id de pregunta y
/// los desempates respondidos en orden. Nunca lleva datos del alumno.
Map<String, dynamic> cuerpoDeEvaluacion({
  required String version,
  required Map<String, String> respuestas,
  required List<TiebreakRecord> desempates,
}) => <String, dynamic>{
  'version': version,
  'answers': Map<String, String>.of(respuestas),
  'tiebreakAnswers': <Map<String, dynamic>>[
    for (final d in desempates)
      if (d.answer != null)
        TiebreakAnswer(id: d.tiebreak.id, answer: d.answer!).toJson(),
  ],
};

// ── Selección de especialidades (RF-TEST-9 y RF-TEST-14) ─────────────────────

/// Una selección lista para `PUT /academic-profile/me/specialties`, que
/// reemplaza la selección entera (BR-AP-04).
class SeleccionDeEspecialidades {
  const SeleccionDeEspecialidades({
    this.principal,
    this.intereses = const <int>[],
  });

  final int? principal;
  final List<int> intereses;

  @override
  bool operator ==(Object other) =>
      other is SeleccionDeEspecialidades &&
      other.principal == principal &&
      other.intereses.length == intereses.length &&
      Iterable<int>.generate(
        intereses.length,
      ).every((i) => other.intereses[i] == intereses[i]);

  @override
  int get hashCode => Object.hash(principal, Object.hashAll(intereses));

  @override
  String toString() => 'Seleccion($principal, $intereses)';
}

/// La principal solo si es oficial y los intereses oficiales sin la
/// principal, en su orden y sin repetir (RF-TEST-14). Así nunca viaja un id
/// antiguo, que con BR-AP-07 daría `404 SPECIALTY_NOT_FOUND`.
SeleccionDeEspecialidades seleccionOficial({
  required int? principal,
  required Iterable<int> intereses,
  required Set<int> oficiales,
}) {
  final principalOficial = principal != null && oficiales.contains(principal)
      ? principal
      : null;
  final vistos = <int>{};
  final interesesOficiales = <int>[
    for (final id in intereses)
      if (oficiales.contains(id) && id != principalOficial && vistos.add(id))
        id,
  ];
  return SeleccionDeEspecialidades(
    principal: principalOficial,
    intereses: interesesOficiales,
  );
}

/// Los corazones marcados al abrir el resultado, que son los intereses del
/// alumno que están en el ranking.
Set<int> corazonesIniciales({
  required Iterable<int> intereses,
  required Iterable<int> idsDelRanking,
}) {
  final ranking = idsDelRanking.toSet();
  return intereses.where(ranking.contains).toSet();
}

List<int> _enOrdenDelRanking(Set<int> ids, List<int> idsDelRanking) =>
    idsDelRanking.where(ids.contains).toList();

/// La selección al elegir [elegida] como principal. Los intereses son los
/// corazones, la principal anterior si es otra y está en el ranking
/// (decisión abierta 23) y, con empate, la otra ganadora (decisión abierta
/// 11). Los ids salen solo del ranking.
SeleccionDeEspecialidades seleccionAlElegir({
  required int elegida,
  required int? principalActual,
  required Set<int> corazones,
  required List<int> idsDelRanking,
  int? otraGanadora,
}) {
  final intereses = <int>{...corazones, ?principalActual, ?otraGanadora}
    ..remove(elegida);
  return seleccionOficial(
    principal: elegida,
    intereses: _enOrdenDelRanking(intereses, idsDelRanking),
    oficiales: idsDelRanking.toSet(),
  );
}

/// La selección de un corazón o de «Decidir después», con la principal
/// actual sin cambios y los corazones como intereses.
SeleccionDeEspecialidades seleccionConCorazones({
  required int? principalActual,
  required Set<int> corazones,
  required List<int> idsDelRanking,
}) => seleccionOficial(
  principal: principalActual,
  intereses: _enOrdenDelRanking(corazones, idsDelRanking),
  oficiales: idsDelRanking.toSet(),
);

// ── Fecha en hora de Lima (RF-TEST-10) ────────────────────────────────────────

/// Lima está en UTC−5 todo el año, sin horario de verano.
const Duration _desfaseLima = Duration(hours: 5);

/// «dd/mm/aaaa» de [instante] en hora de Lima, sin depender de la zona del
/// teléfono.
String fechaEnLima(DateTime instante) {
  final lima = instante.toUtc().subtract(_desfaseLima);
  final dd = lima.day.toString().padLeft(2, '0');
  final mm = lima.month.toString().padLeft(2, '0');
  return '$dd/$mm/${lima.year}';
}
