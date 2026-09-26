// lib/models/specialty_test_models.dart
// Modelos del contrato del test de especialidad (RF-TEST-2).
//
// Los `tryFromJson` conservan los `null` que manda el servidor y no inventan
// ceros ni textos. Lo que la app necesita para no pintar un test roto se
// comprueba en [SpecialtyTestContent.tryParse], [EvaluationStep.tryParse] y
// [LastSpecialtyTestResult.tryParse], que devuelven `null` si falta.

/// Un electivo de una especialidad, tal como lo manda el contenido.
class TestElective {
  const TestElective({
    required this.code,
    required this.name,
    this.shortName,
    this.credits,
    this.prerequisite,
  });

  final String code;
  final String name;
  final String? shortName;
  final int? credits;
  final String? prerequisite;

  /// El nombre corto si llega, o el nombre completo.
  String get displayName => shortName ?? name;

  static TestElective? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final code = _texto(json['code']);
    final name = _texto(json['name']);
    if (code == null || name == null) return null;
    return TestElective(
      code: code,
      name: name,
      shortName: _texto(json['shortName']),
      credits: _entero(json['credits']),
      prerequisite: _texto(json['prerequisite']),
    );
  }
}

/// Una de las cuatro especialidades del contenido.
class TestSpecialty {
  const TestSpecialty({
    required this.key,
    required this.specialtyId,
    required this.name,
    required this.colorLight,
    required this.colorDark,
    this.tagline,
    this.icon,
    this.totalCredits,
    this.electives = const <TestElective>[],
  });

  /// `sw`, `ti`, `si` o `vj`.
  final String key;
  final int specialtyId;
  final String name;

  /// Hex `#RRGGBB` tal como llega. Si no se puede leer, cuenta como neutro
  /// (RF-TEST-12) y no invalida el contenido.
  final String colorLight;
  final String colorDark;
  final String? tagline;

  /// Nombre de Lucide en kebab-case, o null si no llega (RF-TEST-5).
  final String? icon;
  final int? totalCredits;
  final List<TestElective> electives;

  static TestSpecialty? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final key = _texto(json['key']);
    final specialtyId = _entero(json['specialtyId']);
    final name = _texto(json['name']);
    final color = json['color'];
    if (key == null || specialtyId == null || name == null || color is! Map) {
      return null;
    }
    final light = color['light'];
    final dark = color['dark'];
    if (light is! String || dark is! String) return null;
    final electivos = json['electives'];
    return TestSpecialty(
      key: key,
      specialtyId: specialtyId,
      name: name,
      colorLight: light,
      colorDark: dark,
      tagline: _texto(json['tagline']),
      icon: _texto(json['icon']),
      totalCredits: _entero(json['totalCredits']),
      electives: electivos is List
          ? electivos
                .map(TestElective.tryFromJson)
                .whereType<TestElective>()
                .toList(growable: false)
          : const <TestElective>[],
    );
  }
}

/// Una tarea de un duelo, de una escala o de un desempate.
class TestTask {
  const TestTask({
    required this.id,
    required this.specialty,
    required this.text,
    this.icon,
  });

  final String id;

  /// Clave de su especialidad. Solo enciende la tarjeta tocada (RF-TEST-5).
  final String specialty;
  final String text;
  final String? icon;

  static TestTask? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final id = _texto(json['id']);
    final specialty = _texto(json['specialty']);
    final text = _texto(json['text']);
    if (id == null || specialty == null || text == null) return null;
    return TestTask(
      id: id,
      specialty: specialty,
      text: text,
      icon: _texto(json['icon']),
    );
  }
}

enum TestQuestionType { duel, scale }

/// Una pregunta del contenido, que es un duelo con `top` y `bottom` o una
/// escala con `task`.
class TestQuestion {
  const TestQuestion({
    required this.id,
    required this.type,
    required this.prompt,
    this.n,
    this.top,
    this.bottom,
    this.task,
    this.reaction,
    this.blockClose,
  });

  final String id;
  final int? n;
  final TestQuestionType type;
  final String prompt;
  final TestTask? top;
  final TestTask? bottom;
  final TestTask? task;
  final String? reaction;
  final String? blockClose;

  bool get isDuel => type == TestQuestionType.duel;

  /// Las tareas de la pregunta, en el orden en que se pintan.
  List<TestTask> get tasks => isDuel ? [top!, bottom!] : [task!];

  static TestQuestion? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final id = _texto(json['id']);
    final prompt = _texto(json['prompt']);
    if (id == null || prompt == null) return null;
    final tipo = json['type'];
    if (tipo == 'duel') {
      final top = TestTask.tryFromJson(json['top']);
      final bottom = TestTask.tryFromJson(json['bottom']);
      if (top == null || bottom == null) return null;
      return TestQuestion(
        id: id,
        n: _entero(json['n']),
        type: TestQuestionType.duel,
        prompt: prompt,
        top: top,
        bottom: bottom,
        reaction: _texto(json['reaction']),
        blockClose: _texto(json['blockClose']),
      );
    }
    if (tipo == 'scale') {
      final task = TestTask.tryFromJson(json['task']);
      if (task == null) return null;
      return TestQuestion(
        id: id,
        n: _entero(json['n']),
        type: TestQuestionType.scale,
        prompt: prompt,
        task: task,
        reaction: _texto(json['reaction']),
        blockClose: _texto(json['blockClose']),
      );
    }
    return null;
  }
}

/// Una opción del duelo o de la escala, con su id y su etiqueta.
class TestOption {
  const TestOption({required this.id, required this.label});

  final String id;
  final String label;

  static TestOption? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final id = _texto(json['id']);
    final label = _texto(json['label']);
    if (id == null || label == null) return null;
    return TestOption(id: id, label: label);
  }
}

/// Las listas de reacciones de Ulises (RF-TEST-4).
class UlisesReactions {
  const UlisesReactions({
    this.pick = const <String>[],
    this.both = const <String>[],
    this.none = const <String>[],
    this.scale = const <String>[],
  });

  final List<String> pick;
  final List<String> both;
  final List<String> none;
  final List<String> scale;

  static UlisesReactions fromJson(Object? json) {
    if (json is! Map) return const UlisesReactions();
    return UlisesReactions(
      pick: _textos(json['pick']),
      both: _textos(json['both']),
      none: _textos(json['none']),
      scale: _textos(json['scale']),
    );
  }
}

/// Las líneas de Ulises del recorrido. `startButton` llega pero no se usa
/// (decisión abierta 7).
class UlisesLines {
  const UlisesLines({
    this.welcome = const <String>[],
    this.duelHelp,
    this.scaleHelp,
    this.reactions = const UlisesReactions(),
    this.loading,
  });

  final List<String> welcome;
  final String? duelHelp;
  final String? scaleHelp;
  final UlisesReactions reactions;
  final String? loading;

  static UlisesLines fromJson(Object? json) {
    if (json is! Map) return const UlisesLines();
    return UlisesLines(
      welcome: _textos(json['welcome']),
      duelHelp: _texto(json['duelHelp']),
      scaleHelp: _texto(json['scaleHelp']),
      reactions: UlisesReactions.fromJson(json['reactions']),
      loading: _texto(json['loading']),
    );
  }
}

/// El contenido de `GET /specialty-test/content`.
class SpecialtyTestContent {
  const SpecialtyTestContent({
    required this.version,
    required this.specialties,
    required this.ulises,
    required this.duelOptions,
    required this.scaleOptions,
    required this.questions,
  });

  final String version;
  final List<TestSpecialty> specialties;
  final UlisesLines ulises;
  final List<TestOption> duelOptions;
  final List<TestOption> scaleOptions;
  final List<TestQuestion> questions;

  int get totalQuestions => questions.length;

  TestSpecialty? specialtyByKey(String key) {
    for (final s in specialties) {
      if (s.key == key) return s;
    }
    return null;
  }

  /// La etiqueta de una opción del duelo (`both` o `none`) o de la escala.
  String? optionLabel(String id) {
    for (final o in [...duelOptions, ...scaleOptions]) {
      if (o.id == id) return o.label;
    }
    return null;
  }

  /// Comprueba lo que la app necesita (RF-TEST-2) y devuelve null si algo
  /// falta. Un elemento roto invalida todo el contenido, porque la app nunca
  /// pinta un test a medias. No fija el número de preguntas ni la versión.
  static SpecialtyTestContent? tryParse(Object? json) {
    if (json is! Map) return null;
    final version = _texto(json['version']);
    final rawSpecialties = json['specialties'];
    final rawQuestions = json['questions'];
    final rawDuel = json['duelOptions'];
    final rawScale = json['scaleOptions'];
    if (version == null ||
        rawSpecialties is! List ||
        rawQuestions is! List ||
        rawDuel is! List ||
        rawScale is! List) {
      return null;
    }

    final specialties = <TestSpecialty>[];
    for (final raw in rawSpecialties) {
      final s = TestSpecialty.tryFromJson(raw);
      if (s == null) return null;
      specialties.add(s);
    }
    final claves = specialties.map((s) => s.key).toSet();
    if (specialties.isEmpty) return null;

    final questions = <TestQuestion>[];
    for (final raw in rawQuestions) {
      final q = TestQuestion.tryFromJson(raw);
      if (q == null) return null;
      if (q.tasks.any((t) => !claves.contains(t.specialty))) return null;
      questions.add(q);
    }
    if (questions.isEmpty) return null;

    final duelOptions = <TestOption>[];
    for (final raw in rawDuel) {
      final o = TestOption.tryFromJson(raw);
      if (o == null) return null;
      duelOptions.add(o);
    }
    final idsDuelo = duelOptions.map((o) => o.id).toSet();
    if (!idsDuelo.contains('both') || !idsDuelo.contains('none')) return null;

    final scaleOptions = <TestOption>[];
    for (final raw in rawScale) {
      final o = TestOption.tryFromJson(raw);
      if (o == null) return null;
      scaleOptions.add(o);
    }
    // RF-TEST-6 ata un emoji a cada opción por su orden.
    if (scaleOptions.length != 4) return null;

    return SpecialtyTestContent(
      version: version,
      specialties: List.unmodifiable(specialties),
      ulises: UlisesLines.fromJson(json['ulises']),
      duelOptions: List.unmodifiable(duelOptions),
      scaleOptions: List.unmodifiable(scaleOptions),
      questions: List.unmodifiable(questions),
    );
  }
}

/// Un desempate respondido, tal como viaja en `tiebreakAnswers`.
class TiebreakAnswer {
  const TiebreakAnswer({required this.id, required this.answer});

  final String id;
  final String answer;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'answer': answer,
  };
}

/// Un desempate que manda el servidor.
class TestTiebreak {
  const TestTiebreak({
    required this.id,
    required this.order,
    required this.prompt,
    required this.top,
    required this.bottom,
  });

  final String id;

  /// 1 o 2.
  final int order;
  final String prompt;
  final TestTask top;
  final TestTask bottom;

  static TestTiebreak? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final id = _texto(json['id']);
    final order = _entero(json['order']);
    final prompt = _texto(json['prompt']);
    final top = TestTask.tryFromJson(json['top']);
    final bottom = TestTask.tryFromJson(json['bottom']);
    if (id == null ||
        order == null ||
        prompt == null ||
        top == null ||
        bottom == null) {
      return null;
    }
    return TestTiebreak(
      id: id,
      order: order,
      prompt: prompt,
      top: top,
      bottom: bottom,
    );
  }
}

/// Un desempate del recorrido en memoria, con el que mandó el servidor, la
/// línea de Ulises que lo anuncia y la respuesta, si ya la hay. Vive solo en
/// la memoria del controlador y del service (RF-TEST-2 y RF-TEST-4).
class TiebreakRecord {
  const TiebreakRecord({required this.tiebreak, this.ulisesLine, this.answer});

  final TestTiebreak tiebreak;
  final String? ulisesLine;
  final String? answer;

  TiebreakRecord withAnswer(String? answer) => TiebreakRecord(
    tiebreak: tiebreak,
    ulisesLine: ulisesLine,
    answer: answer,
  );
}

/// Una fila del ranking.
class RankingEntry {
  const RankingEntry({
    required this.key,
    required this.specialtyId,
    required this.name,
    required this.affinity,
  });

  final String key;
  final int specialtyId;
  final String name;

  /// Entero de 0 a 100 que calcula el servidor.
  final int affinity;

  static RankingEntry? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final key = _texto(json['key']);
    final specialtyId = _entero(json['specialtyId']);
    final name = _texto(json['name']);
    final affinity = _entero(json['affinity']);
    if (key == null ||
        specialtyId == null ||
        name == null ||
        affinity == null ||
        affinity < 0 ||
        affinity > 100) {
      return null;
    }
    return RankingEntry(
      key: key,
      specialtyId: specialtyId,
      name: name,
      affinity: affinity,
    );
  }
}

/// El resultado de una evaluación que terminó.
class SpecialtyTestResult {
  const SpecialtyTestResult({
    required this.version,
    required this.tie,
    required this.ranking,
    this.completedAt,
    this.reason,
    this.reasonSource,
    this.headline,
    this.tiebreakOutcome,
  });

  final String? version;
  final DateTime? completedAt;
  final bool tie;
  final List<RankingEntry> ranking;
  final String? reason;

  /// `"ai"` o `"templates"`.
  final String? reasonSource;
  final String? headline;

  /// null sin desempate.
  final String? tiebreakOutcome;

  bool get reasonByAi => reasonSource == 'ai';

  /// Las ganadoras, que son la primera o, con empate, las dos primeras.
  List<RankingEntry> get winners =>
      tie ? ranking.take(2).toList(growable: false) : [ranking.first];

  /// Las filas de abajo, desde el puesto 2 o, con empate, desde el 3.
  List<RankingEntry> get others => ranking.skip(tie ? 2 : 1).toList();

  static SpecialtyTestResult? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final ranking = _ranking(json['ranking']);
    final tie = json['tie'];
    if (ranking == null || tie is! bool) return null;
    if (tie && ranking.length < 2) return null;
    final ulises = json['ulises'];
    return SpecialtyTestResult(
      version: _texto(json['version']),
      completedAt: _fecha(json['completedAt']),
      tie: tie,
      ranking: ranking,
      reason: _texto(json['reason']),
      reasonSource: _texto(json['reasonSource']),
      headline: ulises is Map ? _texto(ulises['headline']) : null,
      tiebreakOutcome: ulises is Map ? _texto(ulises['tiebreakOutcome']) : null,
    );
  }
}

/// Lo que devuelve `POST /specialty-test/me/evaluate`.
sealed class EvaluationStep {
  const EvaluationStep();

  static EvaluationStep? tryParse(Object? json) {
    if (json is! Map) return null;
    final status = json['status'];
    if (status == 'tiebreak') {
      final tiebreak = TestTiebreak.tryFromJson(json['tiebreak']);
      if (tiebreak == null) return null;
      return TiebreakStep(
        tiebreak: tiebreak,
        ulisesLine: _texto(json['ulisesLine']),
      );
    }
    if (status == 'result') {
      final result = SpecialtyTestResult.tryFromJson(json['result']);
      if (result == null) return null;
      return ResultStep(result);
    }
    return null;
  }
}

class TiebreakStep extends EvaluationStep {
  const TiebreakStep({required this.tiebreak, this.ulisesLine});

  final TestTiebreak tiebreak;
  final String? ulisesLine;
}

class ResultStep extends EvaluationStep {
  const ResultStep(this.result);

  final SpecialtyTestResult result;
}

/// El último resultado guardado (`GET /specialty-test/me/result`), sin
/// motivo, que no se guarda.
class LastSpecialtyTestResult {
  const LastSpecialtyTestResult({
    required this.tie,
    required this.ranking,
    this.version,
    this.isCurrentVersion,
    this.completedAt,
  });

  final String? version;

  /// null si el servidor no lo manda, y entonces la tarjeta no dice que el
  /// test cambió.
  final bool? isCurrentVersion;
  final DateTime? completedAt;
  final bool tie;
  final List<RankingEntry> ranking;

  List<RankingEntry> get winners =>
      tie ? ranking.take(2).toList(growable: false) : [ranking.first];

  List<RankingEntry> get others => ranking.skip(tie ? 2 : 1).toList();

  static LastSpecialtyTestResult? tryParse(Object? json) {
    if (json is! Map) return null;
    final ranking = _ranking(json['ranking']);
    final tie = json['tie'];
    if (ranking == null || tie is! bool) return null;
    if (tie && ranking.length < 2) return null;
    final current = json['isCurrentVersion'];
    return LastSpecialtyTestResult(
      version: _texto(json['version']),
      isCurrentVersion: current is bool ? current : null,
      completedAt: _fecha(json['completedAt']),
      tie: tie,
      ranking: ranking,
    );
  }
}

// ── Lectura segura ────────────────────────────────────────────────────────────

String? _texto(Object? value) => value is String ? value : null;

int? _entero(Object? value) {
  if (value is int) return value;
  if (value is num && value == value.roundToDouble()) return value.toInt();
  return null;
}

List<String> _textos(Object? value) {
  if (value is! List) return const <String>[];
  return value.whereType<String>().toList(growable: false);
}

DateTime? _fecha(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

List<RankingEntry>? _ranking(Object? value) {
  if (value is! List || value.isEmpty) return null;
  final ranking = <RankingEntry>[];
  for (final raw in value) {
    final entry = RankingEntry.tryFromJson(raw);
    if (entry == null) return null;
    ranking.add(entry);
  }
  return List.unmodifiable(ranking);
}
