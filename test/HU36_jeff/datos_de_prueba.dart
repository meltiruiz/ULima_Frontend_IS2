// test/HU36_jeff/datos_de_prueba.dart
//
// Datos de prueba del test de especialidad (HU36). No es un archivo de
// pruebas, y lo importan las pruebas de esta carpeta.
//
// El contenido es un recorte inventado de cinco preguntas con la forma de la
// versión 2026-09-25.4. Las líneas de Ulises son las de esa versión, porque
// RF-TEST-3 pide medir la bienvenida con sus cuatro líneas; las tareas, los
// electivos y los resultados son inventados. Los `specialtyId` son
// ilustrativos, como en el contrato. El alumno de prueba es 20230001.

import 'package:ulima_plus/models/user_model.dart';

const String kVersionDePrueba = '2026-09-25.4';

/// Las cuatro líneas de bienvenida de la versión 2026-09-25.4.
const List<String> kBienvenida = <String>[
  '¡Hola! Soy Ulises. Te voy a mostrar tareas de verdad, de las que se hacen '
      'en cada especialidad, y tú eliges cuál harías con más ganas.',
  'Son 14 preguntas, a veces una o dos más para desempatar, y te toma unos '
      'tres minutos. No hay respuestas buenas ni malas.',
  'Piensa en lo que harías con gusto un día cualquiera, no en lo que suena '
      'más importante.',
  'Si te gustan las dos, dilo. Si ninguna te llama, también vale.',
];

const String kDuelHelp = 'Toca la tarea que harías con más ganas.';
const String kScaleHelp = 'Elige cuánto te gustaría hacer esta tarea.';
const String kLoading = 'Dame un toque que junto tus respuestas.';
const List<String> kPick = <String>[
  'Anotado.',
  '¡Cra!',
  'Listo.',
  'Ya, siguiente.',
  'Lo apunto.',
  'Sigamos.',
  'Tomo nota.',
];
const List<String> kBoth = <String>[
  'Las dos, ¿no? Eso también cuenta.',
  'Ya, medio punto para cada una.',
];
const List<String> kNone = <String>[
  'Ninguna, ya. También me sirve saberlo.',
  'Ok, ninguna de las dos era lo tuyo.',
];
const List<String> kScale = <String>['Anotado.', 'Lo tengo.', '¡Cra!'];

/// Ids ilustrativos de las cuatro especialidades.
const int kIdSw = 1;
const int kIdTi = 5;
const int kIdSi = 6;
const int kIdVj = 7;

Map<String, dynamic> _tarea(
  String id,
  String especialidad,
  String texto,
  String? icono,
) => <String, dynamic>{
  'id': id,
  'specialty': especialidad,
  'text': texto,
  'illustration': 'Descripción de prueba que la app no muestra.',
  'icon': ?icono,
};

Map<String, dynamic> _especialidad(
  String clave,
  int id,
  String nombre,
  String claro,
  String oscuro,
  String icono,
  List<Map<String, dynamic>> electivos,
) => <String, dynamic>{
  'key': clave,
  'specialtyId': id,
  'name': nombre,
  'tagline': 'Frase de prueba de $nombre.',
  'color': <String, dynamic>{'light': claro, 'dark': oscuro},
  'icon': icono,
  'totalCredits': 21,
  'electives': electivos,
};

Map<String, dynamic> _electivo(String codigo, String letra) =>
    <String, dynamic>{
      'code': codigo,
      'name': 'ELECTIVO DE PRUEBA $letra',
      'shortName': 'Electivo $letra',
      'credits': 3,
      'prerequisite': 'Haber culminado el V ciclo',
    };

/// El contenido de prueba, con cinco preguntas, dos de ellas escalas con
/// `blockClose`, así que el sello cuenta hasta 2. La 1 y la 4 traen reacción
/// propia; la 2 no, y usa la lista de reacciones.
Map<String, dynamic> contenidoJson({
  String version = kVersionDePrueba,
  String? iconoDeLaPrimera = 'shopping-cart',
}) => <String, dynamic>{
  'version': version,
  'specialties': <dynamic>[
    _especialidad(
      'sw',
      kIdSw,
      'Ingeniería de Software',
      '#1E3A8A',
      '#A5C0F7',
      'code-xml',
      [
        _electivo('900101', 'A'),
        _electivo('900102', 'B'),
        _electivo('900103', 'C'),
      ],
    ),
    _especialidad(
      'ti',
      kIdTi,
      'Tecnologías de la Información',
      '#0F7A45',
      '#7EE8BE',
      'server-cog',
      [_electivo('900201', 'D')],
    ),
    _especialidad(
      'si',
      kIdSi,
      'Sistemas de Información',
      '#9333EA',
      '#B98AF8',
      'chart-column-big',
      [_electivo('900301', 'E'), _electivo('900302', 'F')],
    ),
    _especialidad(
      'vj',
      kIdVj,
      'Desarrollo de Videojuegos',
      '#76164A',
      '#EC7FB3',
      'gamepad-2',
      [_electivo('900401', 'G'), _electivo('900402', 'H')],
    ),
  ],
  'ulises': <String, dynamic>{
    'welcome': kBienvenida,
    'startButton': 'Vamos',
    'duelHelp': kDuelHelp,
    'scaleHelp': kScaleHelp,
    'reactions': <String, dynamic>{
      'pick': kPick,
      'both': kBoth,
      'none': kNone,
      'scale': kScale,
    },
    'loading': kLoading,
  },
  'duelOptions': <dynamic>[
    <String, dynamic>{'id': 'top', 'label': '(tarea de arriba)'},
    <String, dynamic>{'id': 'bottom', 'label': '(tarea de abajo)'},
    <String, dynamic>{'id': 'both', 'label': 'Me gustan las dos'},
    <String, dynamic>{'id': 'none', 'label': 'Ninguna me llama'},
  ],
  'scaleOptions': <dynamic>[
    <String, dynamic>{'id': 'nada', 'label': 'Nada'},
    <String, dynamic>{'id': 'un_poco', 'label': 'Un poco'},
    <String, dynamic>{'id': 'bastante', 'label': 'Bastante'},
    <String, dynamic>{'id': 'me_encantaria', 'label': 'Me encantaría'},
  ],
  'questions': <dynamic>[
    <String, dynamic>{
      'id': 'q01',
      'n': 1,
      'type': 'duel',
      'prompt': '¿Cuál harías con más ganas?',
      'top': _tarea(
        'q01.top',
        'sw',
        'Tarea de prueba uno arriba',
        iconoDeLaPrimera,
      ),
      'bottom': _tarea(
        'q01.bottom',
        'si',
        'Tarea de prueba uno abajo',
        'shelving-unit',
      ),
      'reaction': 'Reacción propia de la pregunta uno.',
    },
    <String, dynamic>{
      'id': 'q02',
      'n': 2,
      'type': 'duel',
      'prompt': '¿Y entre estas dos?',
      'top': _tarea(
        'q02.top',
        'ti',
        'Tarea de prueba dos arriba',
        'refrigerator',
      ),
      'bottom': _tarea(
        'q02.bottom',
        'vj',
        'Tarea de prueba dos abajo',
        'mountain',
      ),
    },
    <String, dynamic>{
      'id': 'q03',
      'n': 3,
      'type': 'scale',
      'prompt': '¿Cuánto te gustaría hacer esto?',
      'task': _tarea(
        'q03.task',
        'vj',
        'Tarea de prueba tres en escala',
        'smartphone',
      ),
      'blockClose': 'Cierre de prueba del bloque uno.',
    },
    <String, dynamic>{
      'id': 'q04',
      'n': 4,
      'type': 'duel',
      'prompt': '¿Cuál de estas elegirías?',
      'top': _tarea('q04.top', 'sw', 'Tarea de prueba cuatro arriba', 'route'),
      'bottom': _tarea(
        'q04.bottom',
        'ti',
        'Tarea de prueba cuatro abajo',
        'school',
      ),
      'reaction': 'Reacción propia de la pregunta cuatro.',
    },
    <String, dynamic>{
      'id': 'q05',
      'n': 5,
      'type': 'scale',
      'prompt': '¿Cuánto te gustaría hacer esta otra?',
      'task': _tarea(
        'q05.task',
        'si',
        'Tarea de prueba cinco en escala',
        'user-minus',
      ),
      'blockClose': 'Cierre de prueba del bloque dos.',
    },
  ],
};

/// Las respuestas completas de [contenidoJson].
Map<String, String> respuestasCompletas() => <String, String>{
  'q01': 'top',
  'q02': 'both',
  'q03': 'bastante',
  'q04': 'none',
  'q05': 'nada',
};

/// Un paso de desempate de `POST /specialty-test/me/evaluate`.
Map<String, dynamic> desempateJson({
  int order = 1,
  String id = 'tb-si-vj-1',
}) => <String, dynamic>{
  'status': 'tiebreak',
  'tiebreak': <String, dynamic>{
    'id': id,
    'order': order,
    'prompt': '¿Cuál harías con más ganas?',
    'top': _tarea('$id.top', 'si', 'Tarea de desempate $order arriba', 'soup'),
    'bottom': _tarea(
      '$id.bottom',
      'vj',
      'Tarea de desempate $order abajo',
      'map-pinned',
    ),
  },
  'ulisesLine': order == 1
      ? 'Tienes dos especialidades muy parejas. Te hago una pregunta más '
            'para desempatar.'
      : 'Sigue reñido. Una última y listo.',
};

Map<String, dynamic> _fila(String clave, int id, String nombre, int afinidad) =>
    <String, dynamic>{
      'key': clave,
      'specialtyId': id,
      'name': nombre,
      'affinity': afinidad,
    };

/// El ranking de prueba, en el que Videojuegos gana con 75.
List<Map<String, dynamic>> rankingJson({bool empate = false}) => empate
    ? [
        _fila('si', kIdSi, 'Sistemas de Información', 62),
        _fila('vj', kIdVj, 'Desarrollo de Videojuegos', 62),
        _fila('ti', kIdTi, 'Tecnologías de la Información', 30),
        _fila('sw', kIdSw, 'Ingeniería de Software', 24),
      ]
    : [
        _fila('vj', kIdVj, 'Desarrollo de Videojuegos', 75),
        _fila('si', kIdSi, 'Sistemas de Información', 65),
        _fila('ti', kIdTi, 'Tecnologías de la Información', 28),
        _fila('sw', kIdSw, 'Ingeniería de Software', 24),
      ];

/// Motivo inventado de 330 caracteres, largo como los de las plantillas.
const String kMotivoLargo =
    'Desarrollo de Videojuegos sumó la mayor parte de los puntos de los '
    'duelos de prueba y la escala de prueba le dio un empujón más. Las '
    'tareas que elegiste tienen en común pensar en quien juega, probar '
    'ideas rápido y ajustar reglas hasta que la experiencia funcione, que '
    'es justo lo que se trabaja en sus electivos de prueba durante el ciclo.';

/// Un paso de resultado de `POST /specialty-test/me/evaluate`.
Map<String, dynamic> resultadoJson({
  bool empate = false,
  String reasonSource = 'templates',
  String motivo = kMotivoLargo,
  String? headline,
  String? tiebreakOutcome,
}) => <String, dynamic>{
  'status': 'result',
  'result': <String, dynamic>{
    'version': kVersionDePrueba,
    'completedAt': '2026-09-25T20:15:00.000Z',
    'tie': empate,
    'ranking': rankingJson(empate: empate),
    'reason': motivo,
    'reasonSource': reasonSource,
    'ulises': <String, dynamic>{
      'intro': 'Ya tengo tu resultado.',
      'headline':
          headline ??
          (empate
              ? 'Empate. Sistemas de Información y Desarrollo de Videojuegos '
                    'quedaron igualitas, con 62 %.'
              : 'Lo tuyo apunta a Desarrollo de Videojuegos, con 75 % de '
                    'afinidad.'),
      'tiebreakOutcome': tiebreakOutcome,
      'closing': 'Línea de cierre que la app no pinta.',
      'retake': 'Línea de rehacer que la app no pinta.',
    },
  },
};

/// `GET /specialty-test/me/result` con un resultado. Las 03:30 UTC del 26 son
/// las 22:30 del 25 en Lima.
Map<String, dynamic> ultimoResultadoJson({
  bool empate = false,
  bool? isCurrentVersion = true,
  String completedAt = '2026-09-26T03:30:00.000Z',
}) => <String, dynamic>{
  'result': <String, dynamic>{
    'version': kVersionDePrueba,
    'isCurrentVersion': ?isCurrentVersion,
    'completedAt': completedAt,
    'tie': empate,
    'ranking': rankingJson(empate: empate),
  },
};

/// El alumno de prueba.
UserModel alumno({
  String code = '20230001',
  int? principal,
  List<int>? intereses,
  bool setupComplete = true,
  String role = 'student',
}) => UserModel(
  code: code,
  firstName: 'Alumna',
  lastName: 'De Prueba',
  email: 'test@aloe.ulima.edu.pe',
  role: role,
  careerId: 1,
  especialidadPrincipal: principal,
  especialidadesInteres: intereses,
  currentCycle: '2026-2',
  setupComplete: setupComplete,
);
