// test/HU23_jeff/chat_identidad_test.dart
//
// UNITARIA + WIDGET — HU23 (chat de sección): la identidad de la
// conversación (RF-CHAT-8) y la etiqueta de rol de los moderadores
// (RF-CHAT-10).
// - Las iniciales del curso con la regla de cuatro pasos y su color, blanco o
//   negro, el que dé más contraste con el color del curso.
// - Los tres tokens nuevos del chat en MaterialTheme: chatOwnBubbleBg,
//   errorBg e iconoNaranja, con las cifras de contraste que fija la spec, y
//   los cuatro archivos que pintan el naranja de un ícono leyéndolo de
//   iconoNaranja en lugar de repetir la condición del tema.
// - Los pares de colores de ChatPage (nombre, etiqueta de rol, hora, carnet,
//   lápida, error del stream, separador, estados, avisos, diálogo y AppBar),
//   cada uno con 4,5:1 para texto y 3:1 para ícono en los dos temas.
// - El círculo del curso (CursoAvatar), el mismo widget para la bandeja y el
//   AppBar.
// - ChatPage en los dos temas: cada elemento de RF-CHAT-8 con su token (AppBar,
//   fondo, burbujas, carnet, lápida, error del stream, estados, avisos y
//   diálogo de borrado) y la etiqueta de rol de RF-CHAT-10 solo junto al
//   nombre, sin fondo y con la burbuja del moderador igual a las demás.
// - chat_page.dart sin hex sueltos ni colores fijos de Colors, salvo white,
//   black y transparent.
// Archivos: lib/pages/chat/chat_linea_tiempo.dart,
// lib/pages/chat/curso_avatar.dart, lib/pages/chat/chat_page.dart y
// lib/configs/themes.dart.
//
// Todos los datos son inventados; el repo es público. Los nombres de curso
// son genéricos o «CURSO DE PRUEBA A».

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ulima_plus/configs/course_colors.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/message.dart';
import 'package:ulima_plus/pages/chat/chat_linea_tiempo.dart';
import 'package:ulima_plus/pages/chat/curso_avatar.dart';
import 'package:ulima_plus/services/api_client.dart';

import 'chat_repo_falso.dart';

const _negro = Color(0xFF000000);
const _blanco = Color(0xFFFFFFFF);

String _hex(Color c) =>
    '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

/// Una cifra con coma decimal para el nombre de la prueba, como la escribe la
/// spec («4,5» o «3»).
String _cifra(double x) =>
    (x == x.roundToDouble() ? x.toInt().toString() : x.toString()).replaceAll(
      '.',
      ',',
    );

/// Un texto o un ícono de `ChatPage` sobre su fondo, con los tokens que fija
/// la spec para cada tema. [minimo] es 4,5 para texto y 3 para un ícono que da
/// información. [claro] y [oscuro] son las cifras exactas de la spec, cuando
/// las da.
class _Par {
  const _Par(
    this.que,
    this.frente,
    this.fondo, {
    this.claro,
    this.oscuro,
    this.minimo = 4.5,
  });

  final String que;
  final Color Function(Brightness) frente;
  final Color Function(Brightness) fondo;
  final double? claro;
  final double? oscuro;
  final double minimo;
}

/// Color con que se pinta de verdad un texto o un ícono: el del `RichText`
/// que construye, ya mezclado con el estilo heredado.
Color? _colorPintado(WidgetTester tester, Finder texto) => tester
    .widget<RichText>(
      find.descendant(of: texto, matching: find.byType(RichText)).first,
    )
    .text
    .style
    ?.color;

/// Decoración del `Container` decorado más cercano que envuelve a [hijo]: la
/// burbuja, la lápida o la tarjeta del estado.
BoxDecoration _cajaDe(WidgetTester tester, Finder hijo) =>
    _contenedorDe(tester, hijo).decoration! as BoxDecoration;

Container _contenedorDe(WidgetTester tester, Finder hijo) =>
    tester.widget<Container>(
      find
          .ancestor(
            of: hijo,
            matching: find.byWidgetPredicate(
              (w) => w is Container && w.decoration is BoxDecoration,
            ),
          )
          .first,
    );

/// Un mensaje inventado con remitente, rol y fecha fijos.
ChatMessage _mensaje(
  String id,
  String senderId,
  String senderName,
  String body, {
  String role = 'student',
  int minuto = 0,
  bool deleted = false,
}) => ChatMessage.fromMap(id, {
  'senderId': senderId,
  'senderName': senderName,
  'senderRole': role,
  'body': body,
  'createdAt': DateTime.utc(2026, 9, 15, 15, minuto).millisecondsSinceEpoch,
  if (deleted) 'deleted': true,
  if (deleted) 'deletedBy': 'Docente De Prueba',
});

/// La conversación que ve el delegado (sesión '20230001'): dos mensajes del
/// profesor seguidos, uno de un compañero, uno propio, un carnet ajeno, un
/// carnet propio y una lápida, todos el mismo día.
List<ChatMessage> _conversacion() => [
  _mensaje(
    '1',
    '601',
    'Docente De Prueba',
    'Bienvenidos al curso',
    role: 'teacher',
  ),
  _mensaje(
    '2',
    '601',
    'Docente De Prueba',
    'Recuerden la práctica',
    role: 'teacher',
    minuto: 1,
  ),
  _mensaje('3', '502', 'Compañero De Prueba', 'Hola a todos', minuto: 2),
  _mensaje(
    '4',
    '20230001',
    'Alumno De Prueba',
    'Mensaje del delegado',
    role: 'delegate',
    minuto: 3,
  ),
  _mensaje(
    '5',
    '502',
    'Compañero De Prueba',
    '${ChatMessage.networkingBodyPrefix}502',
    minuto: 4,
  ),
  _mensaje(
    '6',
    '20230001',
    'Alumno De Prueba',
    '${ChatMessage.networkingBodyPrefix}20230001',
    role: 'delegate',
    minuto: 5,
  ),
  _mensaje(
    '7',
    '502',
    'Compañero De Prueba',
    'texto borrado',
    minuto: 6,
    deleted: true,
  ),
];

/// Pantalla alta para que la conversación entera quede construida.
void _pantallaAlta(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('UNITARIA · inicialesDeCurso (RF-CHAT-8)', () {
    const casos = <String, String>{
      'INGENIERÍA DE SOFTWARE II': 'IS',
      'Ingeniería de Software II': 'IS',
      'Cálculo I': 'C',
      'Programación en C': 'PC',
      'Lenguaje C': 'LC',
      'Ética y Ciudadanía': 'ÉC',
      'II': 'I',
      'de la': 'D',
      '': '',
      '  123  ': '',
    };
    for (final caso in casos.entries) {
      test('«${caso.key}» da «${caso.value}»', () {
        expect(inicialesDeCurso(caso.key), caso.value);
      });
    }

    test('descarta todos los conectores, sin distinguir mayúsculas', () {
      expect(
        inicialesDeCurso('DE DEL LA LAS EL LOS Y E EN PARA A AL Redes Datos'),
        'RD',
      );
    });

    test('descarta los romanos del I al X y conserva los que no lo son', () {
      expect(
        inicialesDeCurso('i ii iii iv v vi vii viii ix x Taller Integrador'),
        'TI',
      );
      // XI, IIII o VX no cumplen la regla: son palabras como cualquier otra.
      expect(inicialesDeCurso('XI Seminario'), 'XS');
      expect(inicialesDeCurso('IIII Seminario'), 'IS');
      expect(inicialesDeCurso('VX Seminario'), 'VS');
    });

    test(
      'descarta las palabras sin letras y usa las dos primeras que quedan',
      () {
        expect(inicialesDeCurso('2026 - Curso de Prueba A'), 'CP');
        expect(inicialesDeCurso('CURSO DE PRUEBA A'), 'CP');
      },
    );

    test('recorta y parte por cualquier cantidad de espacios', () {
      expect(inicialesDeCurso('   Redes    de   Computadoras  '), 'RC');
    });

    test('pone la inicial en mayúscula y conserva su tilde', () {
      expect(inicialesDeCurso('ética profesional'), 'ÉP');
      expect(inicialesDeCurso('álgebra lineal'), 'ÁL');
    });

    test('con palabras solo descartables usa la primera letra del nombre', () {
      expect(inicialesDeCurso('I II'), 'I');
      expect(inicialesDeCurso('y de 3'), 'Y');
      expect(inicialesDeCurso('12 de'), 'D');
    });
  });

  group('UNITARIA · contrasteWcag', () {
    test('blanco y negro dan 21:1, en cualquier orden', () {
      expect(contrasteWcag(_blanco, _negro), closeTo(21, 0.001));
      expect(contrasteWcag(_negro, _blanco), closeTo(21, 0.001));
    });

    test('un color contra sí mismo da 1:1', () {
      expect(contrasteWcag(kCoursePalette.first, kCoursePalette.first), 1);
    });

    test('el naranja de marca sobre blanco da 2,94:1, como dice la spec', () {
      expect(
        contrasteWcag(_blanco, MaterialTheme.primaryColor),
        closeTo(2.94, 0.005),
      );
    });
  });

  group('UNITARIA · colorDeIniciales (RF-CHAT-8)', () {
    for (final color in kCoursePalette) {
      test('las iniciales sobre ${_hex(color)} llegan a 4,5:1', () {
        final texto = colorDeIniciales(color);

        expect(texto, anyOf(_blanco, _negro));
        expect(contrasteWcag(texto, color), greaterThanOrEqualTo(4.5));
      });
    }

    test('elige el de mayor contraste entre blanco y negro', () {
      for (final color in kCoursePalette) {
        final conBlanco = contrasteWcag(_blanco, color);
        final conNegro = contrasteWcag(_negro, color);
        expect(
          colorDeIniciales(color),
          conBlanco >= conNegro ? _blanco : _negro,
          reason: _hex(color),
        );
      }
      expect(colorDeIniciales(_negro), _blanco);
      expect(colorDeIniciales(_blanco), _negro);
    });

    test('el peor caso posible da 4,58:1 y ningún color baja de ahí', () {
      // #8855EE queda casi en el punto donde blanco y negro empatan, que es
      // el peor caso de la regla: (1,05 / 0,05) ^ 0,5 ≈ 4,58.
      const peor = Color(0xFF8855EE);
      expect(contrasteWcag(colorDeIniciales(peor), peor), closeTo(4.58, 0.005));

      var minimo = double.infinity;
      for (var r = 0; r < 256; r += 17) {
        for (var g = 0; g < 256; g += 17) {
          for (var b = 0; b < 256; b += 17) {
            final c = Color.fromARGB(255, r, g, b);
            final contraste = contrasteWcag(colorDeIniciales(c), c);
            if (contraste < minimo) minimo = contraste;
          }
        }
      }
      expect(minimo, greaterThanOrEqualTo(4.58));
    });
  });

  group('UNITARIA · tokens del chat en MaterialTheme (RF-CHAT-8)', () {
    test('chatOwnBubbleBg vale #FFE8DC en claro y #3A2A22 en oscuro', () {
      expect(
        MaterialTheme.chatOwnBubbleBg(Brightness.light),
        const Color(0xFFFFE8DC),
      );
      expect(
        MaterialTheme.chatOwnBubbleBg(Brightness.dark),
        const Color(0xFF3A2A22),
      );
    });

    test('textPrimary sobre la burbuja propia da 15,16:1 y 11,74:1', () {
      final claro = contrasteWcag(
        MaterialTheme.textPrimary(Brightness.light),
        MaterialTheme.chatOwnBubbleBg(Brightness.light),
      );
      final oscuro = contrasteWcag(
        MaterialTheme.textPrimary(Brightness.dark),
        MaterialTheme.chatOwnBubbleBg(Brightness.dark),
      );

      expect(claro, greaterThanOrEqualTo(4.5));
      expect(oscuro, greaterThanOrEqualTo(4.5));
      expect(claro, closeTo(15.16, 0.005));
      expect(oscuro, closeTo(11.74, 0.005));
    });

    test('errorBg vale #B3261E en los dos temas y con blanco da 6,54:1', () {
      for (final b in Brightness.values) {
        expect(MaterialTheme.errorBg(b), const Color(0xFFB3261E));
        final contraste = contrasteWcag(_blanco, MaterialTheme.errorBg(b));
        expect(contraste, greaterThanOrEqualTo(4.5));
        expect(contraste, closeTo(6.54, 0.005));
      }
    });

    test('iconoNaranja es primaryDark en claro y primaryColor en oscuro', () {
      expect(
        MaterialTheme.iconoNaranja(Brightness.light),
        MaterialTheme.primaryDark,
      );
      expect(
        MaterialTheme.iconoNaranja(Brightness.dark),
        MaterialTheme.primaryColor,
      );
    });

    test('iconoNaranja sobre cardBg da 4,12:1 y 5,65:1, sobre el 3:1 de un '
        'ícono', () {
      final claro = contrasteWcag(
        MaterialTheme.iconoNaranja(Brightness.light),
        MaterialTheme.cardBg(Brightness.light),
      );
      final oscuro = contrasteWcag(
        MaterialTheme.iconoNaranja(Brightness.dark),
        MaterialTheme.cardBg(Brightness.dark),
      );

      expect(claro, greaterThanOrEqualTo(3));
      expect(oscuro, greaterThanOrEqualTo(3));
      expect(claro, closeTo(4.12, 0.005));
      expect(oscuro, closeTo(5.65, 0.005));
    });
  });

  group(
    'UNITARIA · el naranja de un ícono sale de iconoNaranja (RF-CHAT-8)',
    () {
      // Solo cuenta el código: los comentarios pueden nombrar la condición.
      String codigo(String ruta) =>
          File(ruta).readAsStringSync().replaceAll(RegExp(r'//[^\n]*'), '');

      // Las dos formas en que los archivos escribían la condición: con el
      // brillo claro primero o con isDark, y con primaryColor o colors.primary.
      final condicion = RegExp(
        r'Brightness\.light\s*\?\s*MaterialTheme\.primaryDark|'
        r'MaterialTheme\.primaryDark\s*:\s*MaterialTheme\.primaryColor|'
        r'isDark\s*\?\s*colors\.primary\s*:\s*MaterialTheme\.primaryDark',
      );

      for (final ruta in <String>[
        'lib/pages/chat/chat_page.dart',
        'lib/pages/horario/horario.dart',
        'lib/pages/descripcion_cursos/descrip_cursos.dart',
        'lib/pages/teacher/teacher_sections_page.dart',
      ]) {
        test(
          '$ruta usa MaterialTheme.iconoNaranja y no repite la condición',
          () {
            final fuente = codigo(ruta);

            expect(fuente, contains('MaterialTheme.iconoNaranja('));
            expect(condicion.allMatches(fuente), isEmpty);
          },
        );
      }

      test('chat_page.dart ya no define su propio _naranjaDeIcono', () {
        expect(
          codigo('lib/pages/chat/chat_page.dart'),
          isNot(contains('_naranjaDeIcono')),
        );
      });
    },
  );

  group('UNITARIA · pares de colores de ChatPage (RF-CHAT-8 y RF-CHAT-10)', () {
    // Cada par es un texto o un ícono de la conversación sobre su fondo, con
    // los tokens que fija la spec. El texto llega a 4,5:1 y el ícono que da
    // información, a 3:1, en los dos temas. Donde la spec da la cifra exacta,
    // la prueba la fija también.
    final pares = <_Par>[
      _Par(
        'RF-CHAT-10 · el nombre del remitente en textPrimary sobre la burbuja ajena',
        MaterialTheme.textPrimary,
        MaterialTheme.cardBg,
        claro: 17.85,
        oscuro: 14.22,
      ),
      _Par(
        'RF-CHAT-10 · la etiqueta de rol en textSecondary sobre la burbuja ajena',
        MaterialTheme.textSecondary,
        MaterialTheme.cardBg,
        claro: 10.35,
        oscuro: 6.44,
      ),
      _Par(
        'el cuerpo de un mensaje ajeno en textPrimary sobre cardBg',
        MaterialTheme.textPrimary,
        MaterialTheme.cardBg,
        claro: 17.85,
        oscuro: 14.22,
      ),
      _Par(
        'la hora en textSecondary sobre la burbuja propia',
        MaterialTheme.textSecondary,
        MaterialTheme.chatOwnBubbleBg,
        oscuro: 5.31,
        minimo: 5.31,
      ),
      _Par(
        'la hora en textSecondary sobre la burbuja ajena',
        MaterialTheme.textSecondary,
        MaterialTheme.cardBg,
        minimo: 5.31,
      ),
      _Par(
        'el ícono del recuadro del carnet en blanco sobre primaryDark',
        (_) => Colors.white,
        (_) => MaterialTheme.primaryDark,
        claro: 4.12,
        oscuro: 4.12,
        minimo: 3,
      ),
      _Par(
        'la lápida, con su texto y su ícono, en textSecondary sobre tagBg',
        MaterialTheme.textSecondary,
        MaterialTheme.tagBg,
        claro: 9.45,
        oscuro: 5.60,
      ),
      _Par(
        'el error del stream en textSecondary sobre pageBg',
        MaterialTheme.textSecondary,
        MaterialTheme.pageBg,
        claro: 9.90,
        oscuro: 6.99,
      ),
      _Par(
        'el separador de día en textSecondary sobre pageBg',
        MaterialTheme.textSecondary,
        MaterialTheme.pageBg,
        claro: 9.90,
        oscuro: 6.99,
      ),
      _Par(
        'el título de los estados en textPrimary sobre cardBg',
        MaterialTheme.textPrimary,
        MaterialTheme.cardBg,
        claro: 17.85,
        oscuro: 14.22,
      ),
      _Par(
        'el cuerpo de los estados en textSecondary sobre cardBg',
        MaterialTheme.textSecondary,
        MaterialTheme.cardBg,
        claro: 10.35,
        oscuro: 6.44,
      ),
      _Par(
        'el candado de los estados en iconoNaranja sobre cardBg',
        MaterialTheme.iconoNaranja,
        MaterialTheme.cardBg,
        claro: 4.12,
        oscuro: 5.65,
        minimo: 3,
      ),
      _Par(
        'el texto de un aviso que no es de error en textPrimary sobre cardBg',
        MaterialTheme.textPrimary,
        MaterialTheme.cardBg,
        claro: 17.85,
        oscuro: 14.22,
      ),
      _Par(
        '«Eliminar» del diálogo de borrado en blanco sobre errorBg',
        (_) => Colors.white,
        MaterialTheme.errorBg,
        claro: 6.54,
        oscuro: 6.54,
      ),
    ];

    for (final par in pares) {
      for (final b in Brightness.values) {
        final tema = b == Brightness.light ? 'claro' : 'oscuro';
        final cifra = b == Brightness.light ? par.claro : par.oscuro;
        test('${par.que} llega a ${_cifra(par.minimo)}:1 en $tema', () {
          final contraste = contrasteWcag(par.frente(b), par.fondo(b));

          expect(contraste, greaterThanOrEqualTo(par.minimo));
          if (cifra != null) expect(contraste, closeTo(cifra, 0.005));
        });
      }
    }

    test('el AppBar toma headerColor, con 16,58:1 en oscuro', () {
      final oscuro = MaterialTheme.headerColor(Brightness.dark);

      expect(oscuro, const Color(0xFF1E1E24));
      expect(contrasteWcag(Colors.white, oscuro), closeTo(16.58, 0.005));
    });

    test('el AppBar claro es la excepción del dueño, blanco sobre #FF6600', () {
      // «AppBar en el tema claro» de la spec. Si el header cambia de color, la
      // excepción deja de ser la misma y esta prueba lo avisa.
      final claro = MaterialTheme.headerColor(Brightness.light);

      expect(claro, MaterialTheme.primaryColor);
      expect(contrasteWcag(Colors.white, claro), closeTo(2.94, 0.005));
    });
  });

  group('WIDGET · CursoAvatar (RF-CHAT-8)', () {
    Future<void> montar(WidgetTester tester, Widget avatar) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: Center(child: avatar)),
          ),
        );

    BoxDecoration decoracion(WidgetTester tester) {
      final caja = tester.widget<Container>(
        find.descendant(
          of: find.byType(CursoAvatar),
          matching: find.byType(Container),
        ),
      );
      return caja.decoration! as BoxDecoration;
    }

    testWidgets('pinta las iniciales sobre un círculo del color del curso', (
      tester,
    ) async {
      final azul = kCoursePalette[0];
      await montar(
        tester,
        CursoAvatar(nombre: 'Ingeniería de Software II', color: azul),
      );

      expect(find.text('IS'), findsOneWidget);
      final deco = decoracion(tester);
      expect(deco.color, azul);
      expect(deco.shape, BoxShape.circle);
      final texto = tester.widget<Text>(find.text('IS'));
      expect(texto.style?.color, colorDeIniciales(azul));
    });

    testWidgets('mide 42 px por omisión y respeta el tamaño que recibe', (
      tester,
    ) async {
      await montar(
        tester,
        CursoAvatar(nombre: 'CURSO DE PRUEBA A', color: kCoursePalette[3]),
      );
      expect(tester.getSize(find.byType(CursoAvatar)), const Size(42, 42));

      await montar(
        tester,
        CursoAvatar(
          nombre: 'CURSO DE PRUEBA A',
          color: kCoursePalette[3],
          size: 36,
        ),
      );
      expect(tester.getSize(find.byType(CursoAvatar)), const Size(36, 36));
    });

    testWidgets('las iniciales en blanco o negro según el color del curso', (
      tester,
    ) async {
      // Índigo lleva iniciales blancas; amarillo, negras.
      final indigo = kCoursePalette[11];
      final amarillo = kCoursePalette[7];
      await montar(
        tester,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CursoAvatar(nombre: 'Redes de Datos', color: indigo),
            CursoAvatar(nombre: 'Cálculo I', color: amarillo),
          ],
        ),
      );

      expect(tester.widget<Text>(find.text('RD')).style?.color, _blanco);
      expect(tester.widget<Text>(find.text('C')).style?.color, _negro);
    });

    testWidgets('con un nombre sin letras no pinta texto, solo el color', (
      tester,
    ) async {
      final verde = kCoursePalette[1];
      await montar(tester, CursoAvatar(nombre: '  123  ', color: verde));

      expect(
        find.descendant(
          of: find.byType(CursoAvatar),
          matching: find.byType(Text),
        ),
        findsNothing,
      );
      expect(decoracion(tester).color, verde);
    });

    testWidgets('con un nombre vacío tampoco pinta texto', (tester) async {
      await montar(tester, CursoAvatar(nombre: '', color: kCoursePalette[2]));

      expect(
        find.descendant(
          of: find.byType(CursoAvatar),
          matching: find.byType(Text),
        ),
        findsNothing,
      );
    });
  });

  group('WIDGET · ChatPage con la identidad de la app (RF-CHAT-8)', () {
    tearDown(Get.reset);

    testWidgets('sin color usa el acento de la sección, o el del 0 si el id no '
        'es un número', (tester) async {
      final repo = ChatRepoFalso(session: sesionDelegado);
      await tester.pumpWidget(chatEnApp(repo, sectionId: '5'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<CursoAvatar>(find.byType(CursoAvatar)).color,
        courseAccentColor(5),
      );

      await tester.pumpWidget(chatEnApp(repo, sectionId: 'abc'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<CursoAvatar>(find.byType(CursoAvatar)).color,
        courseAccentColor(0),
      );
    });

    for (final b in Brightness.values) {
      final tema = b == Brightness.light ? 'claro' : 'oscuro';
      final candado = b == Brightness.light
          ? MaterialTheme.primaryDark
          : MaterialTheme.primaryColor;

      testWidgets('el AppBar va en headerColor, con el círculo de 36 px y la '
          'flecha, el título y el subtítulo en blanco, en $tema', (
        tester,
      ) async {
        final rosa = kCoursePalette[4];
        final repo = ChatRepoFalso(session: sesionDelegado);
        await tester.pumpWidget(
          chatEnApp(repo, brillo: b, sectionCode: '801', courseColor: rosa),
        );
        await tester.pumpAndSettle();

        final appBar = find.byType(AppBar);
        final lienzo = tester.widget<Material>(
          find.descendant(of: appBar, matching: find.byType(Material)).first,
        );
        expect(lienzo.color, MaterialTheme.headerColor(b));
        expect(lienzo.surfaceTintColor, anyOf(isNull, Colors.transparent));

        final circulo = find.descendant(
          of: appBar,
          matching: find.byType(CursoAvatar),
        );
        expect(tester.getSize(circulo), const Size(36, 36));
        expect(tester.widget<CursoAvatar>(circulo).color, rosa);

        expect(_colorPintado(tester, find.byIcon(Icons.arrow_back)), _blanco);
        expect(
          _colorPintado(tester, find.text('INGENIERÍA DE SOFTWARE II')),
          _blanco,
        );
        expect(_colorPintado(tester, find.text('Sección 801')), _blanco);
      });

      testWidgets('el fondo va en pageBg, la burbuja propia en chatOwnBubbleBg '
          'y la ajena en cardBg con borde, en $tema', (tester) async {
        _pantallaAlta(tester);
        final repo = ChatRepoFalso(
          session: sesionDelegado,
          messages: _conversacion(),
        );
        await tester.pumpWidget(chatEnApp(repo, brillo: b));
        await tester.pumpAndSettle();

        expect(
          tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
          MaterialTheme.pageBg(b),
        );

        final propia = _cajaDe(tester, find.text('Mensaje del delegado'));
        expect(propia.color, MaterialTheme.chatOwnBubbleBg(b));
        expect(
          _colorPintado(tester, find.text('Mensaje del delegado')),
          MaterialTheme.textPrimary(b),
        );

        final ajena = _cajaDe(tester, find.text('Hola a todos'));
        expect(ajena.color, MaterialTheme.cardBg(b));
        expect(ajena.border, Border.all(color: MaterialTheme.borderColor(b)));
        expect(
          _colorPintado(tester, find.text('Hola a todos')),
          MaterialTheme.textPrimary(b),
        );
      });

      testWidgets(
        'RF-CHAT-10: la etiqueta de rol sale solo junto al nombre, en '
        'textSecondary, en negrita y sin fondo, en $tema',
        (tester) async {
          _pantallaAlta(tester);
          final repo = ChatRepoFalso(
            session: sesionDelegado,
            messages: _conversacion(),
          );
          await tester.pumpWidget(chatEnApp(repo, brillo: b));
          await tester.pumpAndSettle();

          // Solo el primer mensaje del profesor lleva nombre y etiqueta; el
          // segundo, del mismo día, no. El propio del delegado tampoco.
          expect(find.text('Docente De Prueba'), findsOneWidget);
          expect(find.text('Profesor'), findsOneWidget);
          expect(find.text('Delegado'), findsNothing);
          expect(find.text('Alumno De Prueba'), findsNothing);

          final etiqueta = find.text('Profesor');
          expect(
            _colorPintado(tester, etiqueta),
            MaterialTheme.textSecondary(b),
          );
          expect(
            tester.widget<Text>(etiqueta).style!.fontWeight,
            isIn([FontWeight.w700, FontWeight.w800, FontWeight.w900]),
          );
          expect(tester.widget<Text>(etiqueta).style!.backgroundColor, isNull);
          // Ningún recuadro entre la etiqueta y la burbuja: el Container
          // decorado más cercano a la etiqueta es la burbuja del mensaje.
          expect(
            _contenedorDe(tester, etiqueta),
            same(_contenedorDe(tester, find.text('Bienvenidos al curso'))),
          );

          expect(
            _colorPintado(tester, find.text('Docente De Prueba')),
            MaterialTheme.textPrimary(b),
          );
        },
      );

      testWidgets('RF-CHAT-10: la burbuja del moderador es igual a la de otro '
          'ajeno, en $tema', (tester) async {
        _pantallaAlta(tester);
        final repo = ChatRepoFalso(
          session: sesionDelegado,
          messages: _conversacion(),
        );
        await tester.pumpWidget(chatEnApp(repo, brillo: b));
        await tester.pumpAndSettle();

        final moderador = _cajaDe(tester, find.text('Bienvenidos al curso'));
        final siguiente = _cajaDe(tester, find.text('Recuerden la práctica'));
        final alumno = _cajaDe(tester, find.text('Hola a todos'));
        for (final caja in [moderador, siguiente]) {
          expect(caja.color, alumno.color);
          expect(caja.border, alumno.border);
          expect(caja.color, MaterialTheme.cardBg(b));
        }
      });

      testWidgets('la burbuja de carnet sin borde naranja, con su recuadro en '
          'primaryDark y la credencial en blanco, en $tema', (tester) async {
        _pantallaAlta(tester);
        final repo = ChatRepoFalso(
          session: sesionDelegado,
          messages: _conversacion(),
        );
        await tester.pumpWidget(chatEnApp(repo, brillo: b));
        await tester.pumpAndSettle();

        final textos = find.text('Envio su carnet de networking');
        expect(textos, findsNWidgets(2));

        // El ajeno lleva el fondo y el borde de las ajenas; el propio, el de
        // las propias, sin borde.
        final ajena = _cajaDe(tester, textos.at(0));
        expect(ajena.color, MaterialTheme.cardBg(b));
        expect(ajena.border, Border.all(color: MaterialTheme.borderColor(b)));
        final propia = _cajaDe(tester, textos.at(1));
        expect(propia.color, MaterialTheme.chatOwnBubbleBg(b));
        expect(propia.border, isNull);

        for (final texto in [textos.at(0), textos.at(1)]) {
          expect(_colorPintado(tester, texto), MaterialTheme.textPrimary(b));
        }

        // Los recuadros de las dos burbujas, sin contar la barra.
        final credenciales = find.descendant(
          of: find.byType(ListView),
          matching: find.byIcon(LucideIcons.idCard),
        );
        expect(credenciales, findsNWidgets(2));
        for (var i = 0; i < 2; i++) {
          expect(
            _cajaDe(tester, credenciales.at(i)).color,
            MaterialTheme.primaryDark,
          );
          expect(_colorPintado(tester, credenciales.at(i)), _blanco);
        }
      });

      testWidgets('la lápida va en tagBg con borde y su texto y su ícono en '
          'textSecondary, en $tema', (tester) async {
        _pantallaAlta(tester);
        final repo = ChatRepoFalso(
          session: sesionDelegado,
          messages: _conversacion(),
        );
        await tester.pumpWidget(chatEnApp(repo, brillo: b));
        await tester.pumpAndSettle();

        final texto = find.text('Mensaje eliminado por Docente De Prueba');
        final lapida = _cajaDe(tester, texto);
        expect(lapida.color, MaterialTheme.tagBg(b));
        expect(lapida.border, Border.all(color: MaterialTheme.borderColor(b)));
        expect(_colorPintado(tester, texto), MaterialTheme.textSecondary(b));
        expect(
          _colorPintado(tester, find.byIcon(Icons.do_not_disturb_on_outlined)),
          MaterialTheme.textSecondary(b),
        );
      });

      testWidgets('la hora y el separador de día van en textSecondary, en '
          '$tema', (tester) async {
        _pantallaAlta(tester);
        final repo = ChatRepoFalso(
          session: sesionDelegado,
          messages: _conversacion(),
        );
        await tester.pumpWidget(chatEnApp(repo, brillo: b));
        await tester.pumpAndSettle();

        // 15:00 UTC del 15 de septiembre es 10:00 del martes 15 en Lima.
        expect(
          _colorPintado(tester, find.text('Martes 15 de septiembre')),
          MaterialTheme.textSecondary(b),
        );
        expect(
          _colorPintado(tester, find.text('10:00')),
          MaterialTheme.textSecondary(b),
        );
      });

      testWidgets('el error del stream va en textSecondary, en $tema', (
        tester,
      ) async {
        final repo = ChatRepoFalso(
          session: sesionDelegado,
          streamError: Exception('sin permiso'),
        );
        await tester.pumpWidget(chatEnApp(repo, brillo: b));
        await tester.pumpAndSettle();

        final error = find.textContaining('Error: ');
        expect(error, findsOneWidget);
        expect(_colorPintado(tester, error), MaterialTheme.textSecondary(b));
      });

      testWidgets('el estado vacío va en cardBg con borde, el título en '
          'textPrimary, el cuerpo en textSecondary y el candado naranja, en '
          '$tema', (tester) async {
        final repo = ChatRepoFalso(session: sesionDelegado);
        await tester.pumpWidget(chatEnApp(repo, brillo: b));
        await tester.pumpAndSettle();

        final titulo = find.text('Chat privado de la sección');
        final tarjeta = _cajaDe(tester, titulo);
        expect(tarjeta.color, MaterialTheme.cardBg(b));
        expect(tarjeta.border, Border.all(color: MaterialTheme.borderColor(b)));
        expect(_colorPintado(tester, titulo), MaterialTheme.textPrimary(b));
        expect(
          _colorPintado(
            tester,
            find.textContaining('Solo los miembros de esta sección'),
          ),
          MaterialTheme.textSecondary(b),
        );
        expect(
          _colorPintado(tester, find.byIcon(Icons.lock_outline_rounded)),
          candado,
        );
      });

      testWidgets('el estado no disponible va en cardBg con borde y su aviso, '
          'en blanco sobre errorBg, en $tema', (tester) async {
        final repo = ChatRepoFalso(error: Exception('403'));
        await tester.pumpWidget(chatEnApp(repo, brillo: b));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final titulo = find.text('No se pudo conectar al chat.');
        final tarjeta = _cajaDe(tester, titulo);
        expect(tarjeta.color, MaterialTheme.cardBg(b));
        expect(tarjeta.border, Border.all(color: MaterialTheme.borderColor(b)));
        expect(_colorPintado(tester, titulo), MaterialTheme.textPrimary(b));
        expect(
          _colorPintado(
            tester,
            find.text(
              'Solo los miembros de esta sección pueden entrar al chat.',
            ),
          ),
          MaterialTheme.textSecondary(b),
        );
        expect(_colorPintado(tester, find.byIcon(Icons.lock_clock)), candado);

        final aviso = tester.widget<GetSnackBar>(find.byType(GetSnackBar));
        expect(aviso.backgroundColor, MaterialTheme.errorBg(b));
        expect((aviso.titleText! as Text).style!.color, _blanco);
        expect((aviso.messageText! as Text).style!.color, _blanco);

        Get.closeAllSnackbars();
        await tester.pumpAndSettle();
      });

      testWidgets('el aviso de envío fallido va en blanco sobre errorBg, en '
          '$tema', (tester) async {
        final repo = ChatRepoFalso(
          session: sesionDelegado,
          sendError: Exception('sin red'),
        );
        await tester.pumpWidget(chatEnApp(repo, brillo: b));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), 'Hola');
        await tester.pump();
        await tester.tap(find.byIcon(Icons.send));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final aviso = tester.widget<GetSnackBar>(find.byType(GetSnackBar));
        expect(
          (aviso.messageText! as Text).data,
          'No se pudo enviar el mensaje',
        );
        expect(aviso.backgroundColor, MaterialTheme.errorBg(b));
        expect((aviso.messageText! as Text).style!.color, _blanco);

        Get.closeAllSnackbars();
        await tester.pumpAndSettle();
      });

      testWidgets('un aviso que no es de error va en cardBg con borde y texto '
          'en textPrimary, en $tema', (tester) async {
        final repo = ChatRepoFalso(
          session: sesionDelegado,
          fetchCardError: ApiException(
            statusCode: 403,
            code: 'NETWORKING_CARD_HIDDEN',
            message: 'Carnet oculto',
          ),
        );
        await tester.pumpWidget(chatEnApp(repo, brillo: b));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(LucideIcons.idCard));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final aviso = tester.widget<GetSnackBar>(find.byType(GetSnackBar));
        expect(
          (aviso.messageText! as Text).data,
          'Activa "Mostrar mi carnet" antes de enviarlo.',
        );
        expect(aviso.backgroundColor, MaterialTheme.cardBg(b));
        expect(aviso.borderColor, MaterialTheme.borderColor(b));
        expect(
          (aviso.titleText! as Text).style!.color,
          MaterialTheme.textPrimary(b),
        );
        expect(
          (aviso.messageText! as Text).style!.color,
          MaterialTheme.textPrimary(b),
        );

        Get.closeAllSnackbars();
        await tester.pumpAndSettle();
      });

      testWidgets(
        'el diálogo de borrado va en cardBg, con «Eliminar» en blanco '
        'sobre errorBg, en $tema',
        (tester) async {
          _pantallaAlta(tester);
          final repo = ChatRepoFalso(
            session: sesionDocente,
            messages: _conversacion(),
          );
          await tester.pumpWidget(chatEnApp(repo, brillo: b));
          await tester.pumpAndSettle();

          await tester.longPress(find.text('Hola a todos'));
          await tester.pumpAndSettle();

          final dialogo = find.byType(AlertDialog);
          expect(dialogo, findsOneWidget);
          final lienzo = tester.widget<Material>(
            find.descendant(of: dialogo, matching: find.byType(Material)).first,
          );
          expect(lienzo.color, MaterialTheme.cardBg(b));
          expect(lienzo.surfaceTintColor, anyOf(isNull, Colors.transparent));

          expect(
            _colorPintado(tester, find.text('¿Eliminar mensaje?')),
            MaterialTheme.textPrimary(b),
          );
          expect(
            _colorPintado(
              tester,
              find.text(
                'Se eliminará para todos y verán que lo eliminaste tú.',
              ),
            ),
            MaterialTheme.textPrimary(b),
          );
          expect(
            _colorPintado(tester, find.text('Cancelar')),
            MaterialTheme.textPrimary(b),
          );

          final eliminar = find.text('Eliminar');
          expect(_colorPintado(tester, eliminar), _blanco);
          final boton = tester.widget<Material>(
            find.ancestor(of: eliminar, matching: find.byType(Material)).first,
          );
          expect(boton.color, MaterialTheme.errorBg(b));
        },
      );
    }
  });

  group('UNITARIA · colores con nombre en chat_page.dart (RF-CHAT-8)', () {
    // Solo cuenta el código: los comentarios pueden nombrar colores viejos.
    final codigo = File(
      'lib/pages/chat/chat_page.dart',
    ).readAsStringSync().replaceAll(RegExp(r'//[^\n]*'), '');

    test('no construye colores: ni Color(0x…) ni Color.fromARGB y afines', () {
      expect(RegExp(r'\bColor\s*\(').allMatches(codigo), isEmpty);
      expect(RegExp(r'\bColor\.\w+\s*\(').allMatches(codigo), isEmpty);
    });

    test('de Colors solo usa white, black y transparent', () {
      final usados = RegExp(
        r'\bColors\.(\w+)',
      ).allMatches(codigo).map((m) => m.group(1)).toSet();

      expect(usados, isNotEmpty);
      expect(usados.difference({'white', 'black', 'transparent'}), isEmpty);
    });

    test(
      'Colors.white va pleno y Colors.black con opacidad, solo en sombras',
      () {
        expect(RegExp(r'Colors\.white\s*\.').allMatches(codigo), isEmpty);
        final negros = RegExp(r'Colors\.black\s*\.').allMatches(codigo);
        for (final negro in negros) {
          final antes = codigo.substring(
            (negro.start - 120).clamp(0, codigo.length),
            negro.start,
          );
          expect(antes, contains('BoxShadow('));
        }
      },
    );
  });
}
