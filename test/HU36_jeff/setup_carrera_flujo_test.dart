// test/HU36_jeff/setup_carrera_flujo_test.dart
//
// Pruebas de widget de HU36, el test de especialidad, sobre el asistente con
// el test como paso central (RF-TEST-1), la selección oficial (RF-TEST-14) y
// el contraste de sus dos pasos (RF-TEST-12).
// Pantalla: lib/pages/setup_carrera/
//
// Datos inventados (datos_de_prueba.dart). El alumno de prueba es 20230001.
// El id 3 hace de especialidad antigua.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/pages/setup_carrera/setup_carrera_binding.dart';
import 'package:ulima_plus/pages/setup_carrera/setup_carrera_controller.dart';
import 'package:ulima_plus/pages/setup_carrera/setup_carrera_page.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_logic.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/test_buttons.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';
import 'package:ulima_plus/services/storage_service.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'montaje_de_pantallas.dart';

/// Un `AuthService` real sobre [api], con la sesión y los catálogos
/// puestos, y el service del test registrado.
Future<void> _sesion(
  WidgetTester tester,
  ApiFalsaDelTest api, {
  int? principal,
  List<int>? intereses,
}) async {
  await tester.runAsync(() async {
    Get.put<StorageService>(AlmacenDePrueba());
    final auth = Get.put<AuthService>(AuthService(apiClient: api));
    await auth.adoptarSesion(
      token: 'token-de-prueba',
      user: alumno(
        principal: principal,
        intereses: intereses,
        setupComplete: false,
      ),
    );
  });
  Get.put<SpecialtyTestService>(SpecialtyTestService(apiClient: api));
}

/// Monta el asistente con un [abrirTest] falso que devuelve [salida].
Future<SetupCarreraController> _asistente(
  WidgetTester tester, {
  Object? salida,
  Brightness brillo = Brightness.light,
}) async {
  final c = Get.put<SetupCarreraController>(
    SetupCarreraController(abrirTest: () async => salida),
  );
  await montarPantalla(tester, const SetupCarreraPage(), brillo: brillo);
  await tester.pump();
  return c;
}

/// Toca el único «Reintentar» y deja terminar la recarga de los catálogos.
Future<void> _reintentar(WidgetTester tester) async {
  await tester.runAsync(() async {
    await tester.tap(find.text('Reintentar'));
    await Future<void>.delayed(const Duration(milliseconds: 10));
  });
  await tester.pump();
}

/// El paso del asistente cuyo widget privado se llama [nombre], sin la
/// cabecera, que va aparte en blanco sobre `headerColor`.
Finder _paso(String nombre) =>
    find.byWidgetPredicate((w) => w.runtimeType.toString() == nombre);

/// Monta el asistente en [brillo] y llama a [revisar] con el paso de carrera
/// y con la selección manual. Sin [sinCatalogo], la selección lleva una
/// principal, un interés, una descripción abierta y el aviso de un guardado
/// que falla, así que están todos los estados de la tarjeta y de sus chips.
/// Con [sinCatalogo], los dos pasos muestran su aviso de catálogo.
Future<void> _recorrerElAsistente(
  WidgetTester tester, {
  required Brightness brillo,
  bool sinCatalogo = false,
  required void Function(Finder paso) revisar,
}) async {
  final falla = http.ClientException('sin red');
  await _sesion(
    tester,
    sinCatalogo
        ? ApiFalsaDelTest(carreras: [falla])
        : ApiFalsaDelTest(guardados: [falla]),
    principal: sinCatalogo ? null : kIdSw,
    intereses: sinCatalogo ? null : [kIdTi],
  );
  await _asistente(
    tester,
    salida: SalidaDelTest.seleccionManual,
    brillo: brillo,
  );
  expect(
    find.text('No pudimos cargar tu carrera.'),
    sinCatalogo ? findsOneWidget : findsNothing,
  );
  revisar(_paso('_CarreraStep'));
  await tester.tap(find.text('Continuar'));
  await tester.pump();
  if (sinCatalogo) {
    expect(find.text('No pudimos cargar las especialidades.'), findsOneWidget);
  } else {
    await tester.tap(find.byIcon(LucideIcons.chevronDown).first);
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.text('Finalizar configuración'));
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
    await tester.pump();
    expect(find.text('Descripción de prueba.'), findsOneWidget);
    expect(find.text('Quitar principal'), findsOneWidget);
    expect(find.text('Quitar interés'), findsOneWidget);
    expect(find.textContaining('No pudimos guardar'), findsOneWidget);
  }
  revisar(_paso('_SeleccionStep'));
}

/// Los tokens de `MaterialTheme` en [b]. Las constantes de la paleta, como
/// el blanco, no cuentan, porque son iguales en los dos temas.
Set<int> _tokensDe(Brightness b) => {
  for (final token in <Color Function(Brightness)>[
    MaterialTheme.headerColor,
    MaterialTheme.bloqueCurso,
    MaterialTheme.bloqueSeccion,
    MaterialTheme.bloqueAsistencia,
    MaterialTheme.bloqueAsistenciaLinea,
    MaterialTheme.pageBg,
    MaterialTheme.cardBg,
    MaterialTheme.textPrimary,
    MaterialTheme.textSecondary,
    MaterialTheme.textMuted,
    MaterialTheme.textDimmed,
    MaterialTheme.borderColor,
    MaterialTheme.tagBg,
    MaterialTheme.iconBtnBg,
    MaterialTheme.progressBg,
    MaterialTheme.lockedBg,
    MaterialTheme.espPrincipalBg,
    MaterialTheme.espInteresBg,
    MaterialTheme.chipDisabledBg,
    MaterialTheme.chipDisabledBorder,
    MaterialTheme.chipDisabledText,
    MaterialTheme.chipInactiveText,
    MaterialTheme.sheetBg,
    MaterialTheme.sheetHandle,
    MaterialTheme.sheetRowBg,
    MaterialTheme.labelColor,
    MaterialTheme.externalBadgeBg,
    MaterialTheme.dividerMalla,
    MaterialTheme.specialtyBg,
    MaterialTheme.placeholderText,
    MaterialTheme.descText,
    MaterialTheme.chatOwnBubbleBg,
    MaterialTheme.errorBg,
    MaterialTheme.iconoNaranja,
    MaterialTheme.testInk2,
    MaterialTheme.testMuted,
    MaterialTheme.testLine,
    MaterialTheme.testChipBg,
    MaterialTheme.testAccent,
    MaterialTheme.testAccentHi,
    MaterialTheme.testAccentInk,
    MaterialTheme.testAccentText,
    MaterialTheme.testAccentDeep,
    MaterialTheme.testAccentSoft,
    MaterialTheme.testHeartOff,
    MaterialTheme.testTrack,
    MaterialTheme.testFeatherOn,
    MaterialTheme.testFeatherOff,
    MaterialTheme.testTaskTileBg,
    MaterialTheme.testTaskIconInk,
    MaterialTheme.testAiBadgeBg,
  ])
    token(b).toARGB32(),
};

/// La tinta que pinta el `RichText` que [e] construye, que en un `Text` y en
/// un `Icon` ya lleva el estilo heredado.
Color? _tintaPintada(Element e) {
  Color? tinta;
  var encontrada = false;
  void buscar(Element hijo) {
    if (encontrada) return;
    final w = hijo.widget;
    if (w is RichText) {
      encontrada = true;
      tinta = w.text.style?.color;
      return;
    }
    hijo.visitChildren(buscar);
  }

  e.visitChildren(buscar);
  return tinta;
}

/// Cada color que pintan los `Container`, `Text` e `Icon` de [paso], con el
/// fondo, el borde y el degradado de cada `Container` y la tinta efectiva de
/// cada `Text` e `Icon`.
List<(String, Color)> _coloresDe(Finder paso) {
  final colores = <(String, Color)>[];
  for (final e
      in find
          .descendant(of: paso, matching: find.byType(Container))
          .evaluate()) {
    final w = e.widget as Container;
    if (w.color != null) colores.add(('el fondo de un Container', w.color!));
    final d = w.decoration;
    if (d is! BoxDecoration) continue;
    if (d.color != null) colores.add(('el fondo de un Container', d.color!));
    for (final c in d.gradient?.colors ?? const <Color>[]) {
      colores.add(('el degradado de un Container', c));
    }
    final borde = d.border;
    if (borde is Border) {
      for (final lado in [borde.top, borde.right, borde.bottom, borde.left]) {
        if (lado.style == BorderStyle.none) continue;
        colores.add(('el borde de un Container', lado.color));
      }
    }
  }
  for (final e
      in find.descendant(of: paso, matching: find.byType(Text)).evaluate()) {
    final tinta = _tintaPintada(e);
    final texto = (e.widget as Text).data ?? '';
    colores.add(('el texto «$texto»', tinta ?? const Color(0x00000000)));
  }
  for (final e
      in find.descendant(of: paso, matching: find.byType(Icon)).evaluate()) {
    final tinta = _tintaPintada(e);
    final icono = (e.widget as Icon).icon?.codePoint.toRadixString(16);
    colores.add(('el ícono U+$icono', tinta ?? const Color(0x00000000)));
  }
  return colores;
}

String _hex(Color c) =>
    '#${c.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';

/// Los fondos sobre los que pinta [e], del más cercano hacia arriba hasta el
/// primero opaco, ya mezclados. Un degradado aporta cada uno de sus colores.
List<Color> _fondosDe(Element e) {
  final capas = <List<Color>>[];
  e.visitAncestorElements((a) {
    final w = a.widget;
    List<Color>? colores;
    if (w is DecoratedBox &&
        w.position == DecorationPosition.background &&
        w.decoration is BoxDecoration) {
      final d = w.decoration as BoxDecoration;
      colores = d.gradient?.colors ?? (d.color == null ? null : [d.color!]);
    } else if (w is ColoredBox) {
      colores = [w.color];
    } else if (w is Material &&
        w.type != MaterialType.transparency &&
        w.color != null) {
      colores = [w.color!];
    }
    if (colores == null) return true;
    capas.add(colores);
    return colores.any((c) => c.a < 1);
  });
  var fondos = capas.removeLast();
  for (final capa in capas.reversed) {
    fondos = [
      for (final arriba in capa)
        for (final abajo in fondos) Color.alphaBlend(arriba, abajo),
    ];
  }
  return fondos;
}

/// Cada texto e ícono de [paso] con su tinta efectiva, sus fondos y el
/// mínimo que le pide RF-TEST-12.
List<(String, Color, List<Color>, double)> _tintasDe(Finder paso) => [
  for (final e
      in find.descendant(of: paso, matching: find.byType(RichText)).evaluate())
    () {
      final texto = e.widget as RichText;
      final icono = find
          .ancestor(of: find.byWidget(texto), matching: find.byType(Icon))
          .evaluate()
          .isNotEmpty;
      return (
        icono
            ? 'el ícono U+${texto.text.toPlainText().runes.first.toRadixString(16)}'
            : 'el texto «${texto.text.toPlainText()}»',
        texto.text.style!.color!,
        _fondosDe(e),
        icono ? kContrasteIcono : kContrasteTexto,
      );
    }(),
];

void main() {
  // Get.put de un GetxService agenda onReady con
  // Get.engine.addPostFrameCallback, que necesita el binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(cargarRoboto);
  setUp(Get.reset);
  tearDown(Get.reset);

  group('WIDGET · El asistente con el test (RF-TEST-1)', () {
    testWidgets('caso 1: carrera, test y selección manual, sin el paso '
        '«Decisión»', (tester) async {
      await _sesion(tester, ApiFalsaDelTest());
      final c = await _asistente(tester, salida: SalidaDelTest.seleccionManual);
      expect(find.text('Tu carrera'), findsOneWidget);
      expect(find.text('Carrera de Prueba'), findsOneWidget);
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      expect(c.step.value, SetupStep.seleccion);
      expect(find.text('Especialización principal'), findsOneWidget);
      for (final texto in [
        'Sí, quiero elegir ahora',
        'Todavía no estoy seguro',
        'Quiero explorar primero',
        'Opcional. Puedes elegirla ahora, explorarla o decidirlo luego desde '
            'tu perfil.',
      ]) {
        expect(find.text(texto), findsNothing);
      }
    });

    testWidgets('caso 2: la pausa o el atrás del test dejan al alumno en la '
        'carrera', (tester) async {
      await _sesion(tester, ApiFalsaDelTest());
      final c = await _asistente(tester);
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      expect(c.step.value, SetupStep.carrera);
    });

    testWidgets('caso 3: el atrás del sistema vuelve de la selección a la '
        'carrera, y en la carrera sale de la app', (tester) async {
      final salidas = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (llamada) async {
          salidas.add(llamada.method);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await _sesion(tester, ApiFalsaDelTest());
      final c = await _asistente(tester, salida: SalidaDelTest.seleccionManual);
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(c.step.value, SetupStep.carrera);
      expect(salidas, isNot(contains('SystemNavigator.pop')));
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(salidas, contains('SystemNavigator.pop'));
    });

    testWidgets('caso 4: al montarse pide el contenido del test una sola vez', (
      tester,
    ) async {
      final api = ApiFalsaDelTest();
      await _sesion(tester, api);
      await _asistente(tester);
      await tester.pump();
      expect(api.getsDeContenido, 1);
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      expect(api.getsDeContenido, 1);
      expect(SpecialtyTestService.to.takePrefetch(), isNotNull);
    });

    testWidgets(
      'caso 5: la ruta tiene su binding y la página no hace Get.put',
      (tester) async {
        await _sesion(tester, ApiFalsaDelTest());
        // Sin el binding, la página no encuentra su controlador y no lo
        // registra por su cuenta.
        await montarPantalla(tester, const SetupCarreraPage());
        expect(
          tester.takeException().toString(),
          contains('"SetupCarreraController" not found'),
        );
        expect(Get.isRegistered<SetupCarreraController>(), isFalse);
        SetupCarreraBinding().dependencies();
        expect(Get.isRegistered<SetupCarreraController>(), isTrue);
        expect(Get.isPrepared<SetupCarreraController>(), isTrue);
        final delBinding = Get.find<SetupCarreraController>();
        await montarPantalla(tester, const SetupCarreraPage());
        expect(tester.takeException(), isNull);
        expect(
          identical(Get.find<SetupCarreraController>(), delBinding),
          isTrue,
        );
        final pagina = tester.widget<SetupCarreraPage>(
          find.byType(SetupCarreraPage),
        );
        expect(identical(pagina.controller, delBinding), isTrue);
        expect(delBinding.step.value, SetupStep.carrera);
      },
    );

    testWidgets('caso 6: sin el catálogo de carreras, la carrera y la '
        'selección muestran su aviso con «Reintentar», y «Continuar» sigue '
        'activo', (tester) async {
      // Las dos cargas de la sesión y el primer «Reintentar» fallan. Con las
      // carreras caídas, las especialidades no llegan a pedirse.
      final api = ApiFalsaDelTest(
        carreras: [
          http.ClientException('sin red'),
          http.ClientException('sin red'),
          http.ClientException('sin red'),
          carrerasJson(),
        ],
      );
      await _sesion(tester, api);
      final c = await _asistente(tester, salida: SalidaDelTest.seleccionManual);
      expect(find.text('No pudimos cargar tu carrera.'), findsOneWidget);
      expect(find.text('Carrera de Prueba'), findsNothing);
      await _reintentar(tester);
      expect(find.text('No pudimos cargar tu carrera.'), findsOneWidget);
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      expect(c.step.value, SetupStep.seleccion);
      expect(
        find.text('No pudimos cargar las especialidades.'),
        findsOneWidget,
      );
      await _reintentar(tester);
      expect(find.text('No pudimos cargar las especialidades.'), findsNothing);
      expect(find.text('Ingeniería de Software'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(c.step.value, SetupStep.carrera);
      expect(find.text('No pudimos cargar tu carrera.'), findsNothing);
      expect(find.text('Carrera de Prueba'), findsOneWidget);
    });

    testWidgets('caso 6b: si solo fallan las especialidades, la carrera '
        'muestra su tarjeta y solo la selección muestra el aviso', (
      tester,
    ) async {
      final api = ApiFalsaDelTest(
        especialidades: [
          http.ClientException('sin red'),
          http.ClientException('sin red'),
          http.ClientException('sin red'),
          especialidadesJson(),
        ],
      );
      await _sesion(tester, api);
      final c = await _asistente(tester, salida: SalidaDelTest.seleccionManual);
      // El catálogo cuenta como fallido, pero la carrera sí cargó.
      expect(c.catalogoFallido, isTrue);
      expect(find.text('No pudimos cargar tu carrera.'), findsNothing);
      expect(find.text('Carrera de Prueba'), findsOneWidget);
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      expect(c.step.value, SetupStep.seleccion);
      expect(
        find.text('No pudimos cargar las especialidades.'),
        findsOneWidget,
      );
      await _reintentar(tester);
      expect(
        find.text('No pudimos cargar las especialidades.'),
        findsOneWidget,
      );
      await _reintentar(tester);
      expect(find.text('No pudimos cargar las especialidades.'), findsNothing);
      expect(find.text('Ingeniería de Software'), findsOneWidget);
    });

    testWidgets('caso 7: el botón inferior es el principal del test, con '
        '52 px de alto y tinta sobre naranja, y «Finalizar configuración» '
        'cabe entero a 375 de ancho', (tester) async {
      // El botón de la etiqueta es un TestPrimaryButton a lo ancho, de
      // 52 px, con el texto en testAccentInk sobre testAccent.
      void esElBotonNuevo(String etiqueta) {
        final texto = find.text(etiqueta);
        final boton = find.ancestor(
          of: texto,
          matching: find.byType(TestPrimaryButton),
        );
        expect(boton, findsOneWidget, reason: etiqueta);
        expect(find.byType(ElevatedButton), findsNothing, reason: etiqueta);
        expect(tester.getSize(boton), const Size(335, 52), reason: etiqueta);
        expect(
          colorDeTexto(tester, etiqueta),
          MaterialTheme.testAccentInk(Brightness.light),
          reason: etiqueta,
        );
        expect(
          _fondosDe(tester.element(texto)),
          contains(MaterialTheme.testAccent(Brightness.light)),
          reason: etiqueta,
        );
      }

      await _sesion(tester, ApiFalsaDelTest(), intereses: [kIdSi]);
      await _asistente(tester, salida: SalidaDelTest.seleccionManual);
      esElBotonNuevo('Continuar');
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      final texto = find.text('Finalizar configuración');
      expect(texto, findsOneWidget);
      expect(tester.takeException(), isNull);
      esElBotonNuevo('Finalizar configuración');
      // Una sola línea, dentro del botón.
      expect(tester.getSize(texto).height, lessThan(30));
      expect(dentroDeLaPantalla(tester, texto), isTrue);
    });

    for (final brillo in Brightness.values) {
      for (final sinCatalogo in [false, true]) {
        testWidgets('caso ${sinCatalogo ? '8b' : '8'}: en ${brillo.name}, '
            '${sinCatalogo ? 'con los avisos de catálogo' : 'con cada estado '
                      'de la tarjeta y de sus chips'}, la cabecera va en '
            'headerColor con texto blanco y cada Container, Text e Icon de '
            'los pasos lleva un token de MaterialTheme', (tester) async {
          final tokens = _tokensDe(brillo);
          var revisados = 0;
          final sueltos = <String>[];
          await _recorrerElAsistente(
            tester,
            brillo: brillo,
            sinCatalogo: sinCatalogo,
            revisar: (paso) {
              final scaffold = tester.widget<Scaffold>(
                find.byType(Scaffold).last,
              );
              expect(scaffold.backgroundColor, MaterialTheme.pageBg(brillo));
              final cabecera = tester.widget<Container>(
                find
                    .ancestor(
                      of: find.text('Hola, Alumna'),
                      matching: find.byType(Container),
                    )
                    .first,
              );
              expect(
                (cabecera.decoration! as BoxDecoration).color,
                MaterialTheme.headerColor(brillo),
              );
              expect(colorDeTexto(tester, 'Hola, Alumna'), Colors.white);
              if (find.text('Tu carrera').evaluate().isNotEmpty) {
                expect(
                  colorDeTexto(tester, 'Tu carrera'),
                  MaterialTheme.textPrimary(brillo),
                );
                if (!sinCatalogo) {
                  expect(
                    colorDeTexto(tester, 'Carrera de Prueba'),
                    MaterialTheme.textPrimary(brillo),
                  );
                }
              }
              for (final (que, color) in _coloresDe(paso)) {
                revisados++;
                if (!tokens.contains(color.toARGB32())) {
                  sueltos.add('$que en ${_hex(color)}');
                }
              }
            },
          );
          if (!sinCatalogo) {
            expect(
              colorDeTexto(tester, 'Especialización principal'),
              MaterialTheme.textPrimary(brillo),
            );
          }
          expect(revisados, greaterThan(sinCatalogo ? 10 : 60));
          expect(sueltos, isEmpty);
        });
      }
    }
  });

  group('WIDGET · La selección manual solo con lo oficial (RF-TEST-14)', () {
    testWidgets('caso 9: arranca con la selección oficial y su PUT no lleva '
        'el id antiguo', (tester) async {
      final api = ApiFalsaDelTest();
      await _sesion(tester, api, principal: 3, intereses: [kIdTi, 3]);
      final c = await _asistente(tester, salida: SalidaDelTest.seleccionManual);
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      expect(c.selectedPrincipal.value, isNull);
      expect(c.selectedInteres, {kIdTi});
      await tester.runAsync(() async {
        await tester.tap(find.text('Finalizar configuración'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      await tester.pump();
      expect(api.cuerposDeGuardado.single, {
        'primarySpecialtyId': null,
        'interestSpecialtyIds': [kIdTi],
      });
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('caso 10: solo muestra las especialidades activas del '
        'catálogo', (tester) async {
      final catalogo = especialidadesJson();
      (catalogo['specialties'] as List).add(<String, dynamic>{
        'id': 3,
        'carrera_id': 1,
        'name': 'ESPECIALIDAD ANTIGUA DE PRUEBA',
        'is_active': false,
        'display_order': 5,
      });
      await _sesion(tester, ApiFalsaDelTest(especialidades: [catalogo]));
      await _asistente(tester, salida: SalidaDelTest.seleccionManual);
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      expect(find.text('ESPECIALIDAD ANTIGUA DE PRUEBA'), findsNothing);
      expect(find.text('Desarrollo de Videojuegos'), findsOneWidget);
    });
  });

  group('WIDGET · El contraste del asistente (RF-TEST-12)', () {
    for (final brillo in Brightness.values) {
      for (final sinCatalogo in [false, true]) {
        testWidgets('caso ${sinCatalogo ? '11b' : '11'}: en ${brillo.name}, '
            '${sinCatalogo ? 'con los avisos de catálogo' : 'con cada estado '
                      'de la tarjeta y de sus chips'}, todo texto de los '
            'pasos llega a 4,5:1 contra su fondo y todo ícono a 3:1', (
          tester,
        ) async {
          var revisados = 0;
          final bajos = <String>[];
          await _recorrerElAsistente(
            tester,
            brillo: brillo,
            sinCatalogo: sinCatalogo,
            revisar: (paso) {
              for (final (que, tinta, fondos, minimo) in _tintasDe(paso)) {
                for (final fondo in fondos) {
                  revisados++;
                  final razon = razonDeContraste(tinta, fondo);
                  if (razon < minimo) {
                    bajos.add(
                      '$que en ${_hex(tinta)} sobre ${_hex(fondo)} da '
                      '${razon.toStringAsFixed(2).replaceAll('.', ',')}:1',
                    );
                  }
                }
              }
            },
          );
          expect(revisados, greaterThan(sinCatalogo ? 6 : 40));
          expect(bajos, isEmpty);
        });
      }
    }

    for (final brillo in Brightness.values) {
      testWidgets('caso 12: en ${brillo.name}, «Me interesa» de la principal '
          'no responde y lo marcan el fondo y el borde, con la etiqueta en '
          'testMuted', (tester) async {
        await _sesion(tester, ApiFalsaDelTest(), principal: kIdSw);
        final c = await _asistente(
          tester,
          salida: SalidaDelTest.seleccionManual,
          brillo: brillo,
        );
        await tester.tap(find.text('Continuar'));
        await tester.pump();
        Finder chipDe(String especialidad) => find
            .ancestor(
              of: find.descendant(
                of: find.ancestor(
                  of: find.text(especialidad),
                  matching: find.byType(AnimatedContainer),
                ),
                matching: find.text('Me interesa'),
              ),
              matching: find.byType(Container),
            )
            .first;
        BoxDecoration fondoDe(Finder chip) =>
            tester.widget<Container>(chip).decoration! as BoxDecoration;
        final apagado = chipDe('Ingeniería de Software');
        final neutro = chipDe('Sistemas de Información');
        expect(fondoDe(neutro).color, MaterialTheme.chipDisabledBg(brillo));
        // Sin relleno, con el borde gris, sobre la tarjeta de la principal.
        expect(fondoDe(apagado).color, isNull);
        expect(
          (fondoDe(apagado).border! as Border).top.color,
          MaterialTheme.chipDisabledBorder(brillo),
        );
        final etiqueta = find.descendant(
          of: apagado,
          matching: find.text('Me interesa'),
        );
        expect(
          tester.widget<Text>(etiqueta).style?.color,
          MaterialTheme.testMuted(brillo),
        );
        await tester.tap(etiqueta);
        await tester.pump();
        expect(c.selectedPrincipal.value, kIdSw);
        expect(c.selectedInteres, isEmpty);
      });
    }
  });
}
