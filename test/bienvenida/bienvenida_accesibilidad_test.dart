// test/bienvenida/bienvenida_accesibilidad_test.dart
//
// WIDGET · Bienvenida con Ulises (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-16. Con lector de pantalla, la tarjeta y los botones aparecen con
// el relevo y el foco pasa a la tarjeta, la llegada con sesión empieza con el
// relevo, las burbujas de un turno entran juntas y el foco pasa a la primera
// nueva de Ulises. Los controles son botones con su texto y miden al menos
// 48 dp. Con teclado físico, el foco va del campo al botón de envío y después
// a los enlaces, con el anillo de 2 dp en bienvenidaFoco en los botones, las
// píldoras y los enlaces. Intro envía y nada desborda con el texto al 100, 130
// y 200 %.
// Archivos probados lib/pages/bienvenida/widgets/recibimiento.dart,
// lib/pages/bienvenida/widgets/burbujas.dart y
// lib/pages/bienvenida/bienvenida_page.dart.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/logo/escena_del_logo.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/domain/bienvenida/bienvenida_turnos.dart';
import 'package:ulima_plus/pages/bienvenida/bienvenida_controller.dart'
    show EstadoDeLaPildora;
import 'package:ulima_plus/pages/bienvenida/conversacion.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/burbujas.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/anillo_de_foco.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/compositor.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/franja_con_sello.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/recibimiento.dart';
import 'package:ulima_plus/services/session_navigation.dart';

import 'apoyo_bienvenida.dart';

Map<String, Object> _conPose() => <String, Object>{
  argumentoDePose: EscenaDelLogo.reposo(
    centro: const Offset(187.5, 333.5),
    radio: 90,
  ).pose,
};

const _expirada = <String, Object>{argumentoDeMotivo: MotivoDeLlegada.expirada};

/// El anillo de 2 dp que rodea un control con el foco del teclado.
final _anilloEncendido = Border.all(
  color: MaterialTheme.bienvenidaFoco(Brightness.light),
  width: 2,
);

/// Muestra el foco como con teclado físico, también después de un toque, y
/// deja el modo de siempre al terminar la prueba.
void _conTecladoFisico() {
  FocusManager.instance.highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;
  addTearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );
}

Future<void> _tab(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.pump();
}

/// Si el foco del teclado está dentro de [control].
bool _enfocado(Finder control) {
  final contexto = FocusManager.instance.primaryFocus?.context;
  if (contexto == null) return false;
  return find
      .descendant(
        of: control,
        matching: find.byElementPredicate((e) => identical(e, contexto)),
      )
      .evaluate()
      .isNotEmpty;
}

/// El borde del anillo de foco que envuelve el texto [texto], o null si no
/// se ve.
Border? _anilloSobre(WidgetTester tester, String texto) => _borde(
  tester,
  find
      .ancestor(of: find.text(texto), matching: find.byType(AnilloDeFoco))
      .first,
);

/// El borde del anillo de foco dentro de [control], o null si no se ve.
Border? _anilloDe(WidgetTester tester, Finder control) => _borde(
  tester,
  find.descendant(of: control, matching: find.byType(AnilloDeFoco)).first,
);

Border? _borde(WidgetTester tester, Finder anillo) {
  final caja = tester.widget<DecoratedBox>(
    find.descendant(of: anillo, matching: find.byType(DecoratedBox)).first,
  );
  return (caja.decoration as BoxDecoration).border as Border?;
}

/// Guarda lo que la app le manda al lector por el canal de accesibilidad.
List<Map<Object?, Object?>> _escucharAlLector(WidgetTester tester) {
  final eventos = <Map<Object?, Object?>>[];
  final mensajero = tester.binding.defaultBinaryMessenger;
  mensajero.setMockDecodedMessageHandler<dynamic>(
    SystemChannels.accessibility,
    (mensaje) async {
      if (mensaje is Map) eventos.add(mensaje);
      return null;
    },
  );
  addTearDown(
    () => mensajero.setMockDecodedMessageHandler<dynamic>(
      SystemChannels.accessibility,
      null,
    ),
  );
  return eventos;
}

Iterable<Object?> _focos(List<Map<Object?, Object?>> eventos) =>
    eventos.where((e) => e['type'] == 'focus').map((e) => e['nodeId']);

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  testWidgets('con lector, la tarjeta y los botones aparecen con el relevo, el '
      'foco pasa a la tarjeta y los toques cuentan enseguida', (tester) async {
    final semantica = tester.ensureSemantics();
    final eventos = _escucharAlLector(tester);
    final b = Bienvenida();
    await montarLaBienvenida(
      tester,
      b,
      argumentos: _conPose(),
      conLector: true,
    );
    await avanzar(tester, 50);
    final tarjeta = find.byKey(Recibimiento.claveDeLaTarjeta);
    expect(tarjeta, findsOneWidget);
    expect(find.byKey(Recibimiento.claveDeLosBotones), findsOneWidget);
    expect(_focos(eventos), contains(tester.getSemantics(tarjeta).id));
    expect(
      tester.getSemantics(tarjeta),
      isSemantics(label: '¡Craa! Hola, soy Ulises. ¿Ya usas ULima++?'),
    );
    await tester.tap(find.text(TextosDeLaBienvenida.siEntrar));
    await tester.pump();
    expect(b.delAlumno, [TextosDeLaBienvenida.siEntrar]);
    await avanzar(tester, 2000);
    semantica.dispose();
  });

  testWidgets('los dos botones del recibimiento son botones con su texto y '
      'miden al menos 48 dp', (tester) async {
    final semantica = tester.ensureSemantics();
    await montarLaBienvenida(tester, Bienvenida(), argumentos: _conPose());
    await avanzar(tester, 3000);
    for (final texto in [
      TextosDeLaBienvenida.siEntrar,
      TextosDeLaBienvenida.soyNuevo,
    ]) {
      expect(
        tester.getSemantics(find.bySemanticsLabel(texto)),
        isSemantics(label: texto, isButton: true, hasTapAction: true),
      );
    }
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    semantica.dispose();
  });

  testWidgets('los controles del compositor son botones que el lector puede '
      'tocar, y miden al menos 48 dp', (tester) async {
    final semantica = tester.ensureSemantics();
    await montarLaBienvenida(tester, Bienvenida(), argumentos: _expirada);
    await avanzar(tester, 1500);
    await tester.enterText(find.byType(TextField).first, '20230001');
    await tester.pump();
    for (final texto in [
      TextosDeLaBienvenida.enviar,
      TextosDeLaBienvenida.continuarConGoogle,
      TextosDeLaBienvenida.soyNuevo,
    ]) {
      expect(
        tester.getSemantics(find.bySemanticsLabel(texto)),
        isSemantics(label: texto, isButton: true, hasTapAction: true),
      );
    }
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    semantica.dispose();
  });

  testWidgets('con lector y sesión, la conversación empieza con el relevo y '
      'el foco pasa a la primera burbuja de Ulises', (tester) async {
    final semantica = tester.ensureSemantics();
    final eventos = _escucharAlLector(tester);
    final b = Bienvenida(
      auth: AuthDeLaBienvenida(usuario: alumnaDePrueba(setupComplete: false)),
      token: 'jwt-de-prueba',
    );
    await montarLaBienvenida(tester, b, conLector: true);
    await avanzar(tester, 200);
    expect(find.byKey(Recibimiento.claveDeLaTarjeta), findsNothing);
    expect(find.text(TextosDeLaBienvenida.saludoConSesion), findsOneWidget);
    final primera = tester
        .getSemantics(find.text(TextosDeLaBienvenida.saludoConSesion))
        .id;
    final segunda = tester
        .getSemantics(find.text(TextosDeLaBienvenida.faltaEspecialidad))
        .id;
    expect(primera, isNot(segunda));
    expect(_focos(eventos), contains(primera));
    expect(_focos(eventos), isNot(contains(segunda)));
    await avanzar(tester, 3000);
    semantica.dispose();
  });

  testWidgets('con lector, las burbujas de un turno entran juntas y el foco '
      'pasa a la primera nueva de Ulises', (tester) async {
    final semantica = tester.ensureSemantics();
    final eventos = _escucharAlLector(tester);
    await montarLaBienvenida(
      tester,
      Bienvenida(),
      argumentos: _expirada,
      conLector: true,
    );
    await avanzar(tester, 50);
    expect(find.text(TextosDeLaBienvenida.saludo), findsOneWidget);
    expect(find.text(TextosDeLaBienvenida.e1), findsOneWidget);
    // El foco va a la primera de Ulises, el saludo, y no a E1.
    final saludo = tester.getSemantics(find.text(TextosDeLaBienvenida.saludo));
    final e1 = tester.getSemantics(find.text(TextosDeLaBienvenida.e1));
    expect(saludo.id, isNot(e1.id));
    expect(_focos(eventos), contains(saludo.id));
    expect(_focos(eventos), isNot(contains(e1.id)));
    await tester.enterText(find.byType(TextField).first, '20230001');
    // Un cuadro tras teclear, para que el botón de envío se encienda.
    await tester.pump();
    await tester.tap(find.byType(BotonDeEnvio));
    await avanzar(tester, 100);
    expect(find.text(TextosDeLaBienvenida.e2), findsOneWidget);
    // Y en E2 a su burbuja, no a la respuesta del alumno.
    expect(
      _focos(eventos),
      contains(tester.getSemantics(find.text(TextosDeLaBienvenida.e2)).id),
    );
    expect(
      _focos(eventos),
      isNot(
        contains(
          tester
              .getSemantics(
                find.descendant(
                  of: find.byType(ListView),
                  matching: find.text('20230001'),
                ),
              )
              .id,
        ),
      ),
    );
    semantica.dispose();
  });

  testWidgets('el campo no toma el foco solo con lector, e Intro envía', (
    tester,
  ) async {
    final b = Bienvenida();
    await montarLaBienvenida(tester, b, argumentos: _expirada, conLector: true);
    await avanzar(tester, 600);
    final campo = tester.widget<TextField>(find.byType(TextField).first);
    expect(campo.autofocus, isFalse);
    await tester.enterText(find.byType(TextField).first, '20230001');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(b.delAlumno, ['20230001']);
    await avanzar(tester, 2000);
  });

  testWidgets('con teclado físico, el foco va del campo al botón de envío y '
      'después a los enlaces, y el anillo de 2 dp en bienvenidaFoco sigue al '
      'foco en E1 y en E2', (tester) async {
    _conTecladoFisico();
    final b = Bienvenida();
    await montarLaBienvenida(tester, b, argumentos: _expirada);
    await avanzar(tester, 1500);
    final soyNuevo = find.widgetWithText(
      EnlaceSecundario,
      TextosDeLaBienvenida.soyNuevo,
    );

    // E1. El campo, el botón de envío, «Continuar con Google» y «Soy nuevo».
    await tester.enterText(find.byType(TextField).first, '20230001');
    await tester.pump();
    expect(_enfocado(find.byType(CampoDelCompositor)), isTrue);
    await _tab(tester);
    expect(_enfocado(find.byType(BotonDeEnvio)), isTrue);
    expect(_anilloDe(tester, find.byType(BotonDeEnvio)), _anilloEncendido);
    await _tab(tester);
    expect(_enfocado(find.byType(BotonDeGoogle)), isTrue);
    expect(_anilloDe(tester, find.byType(BotonDeEnvio)), isNull);
    expect(_anilloDe(tester, find.byType(BotonDeGoogle)), _anilloEncendido);
    await _tab(tester);
    expect(_enfocado(soyNuevo), isTrue);
    expect(_anilloDe(tester, soyNuevo), _anilloEncendido);

    // E2. El campo con su ojo, «Entrar», «¿Olvidaste tu contraseña?» y «Soy
    // nuevo». El campo del código que sigue montado no toma el foco.
    await tester.tap(find.byType(BotonDeEnvio));
    await avanzar(tester, 2000);
    await tester.enterText(find.byType(TextField).first, 'secreta-de-prueba');
    await tester.pump();
    await _tab(tester);
    expect(_enfocado(find.byType(OjoDeLaContrasena)), isTrue);
    expect(_anilloDe(tester, find.byType(OjoDeLaContrasena)), _anilloEncendido);
    await _tab(tester);
    expect(_enfocado(find.byType(BotonPrincipal)), isTrue);
    expect(_anilloDe(tester, find.byType(BotonPrincipal)), _anilloEncendido);
    await _tab(tester);
    final olvidaste = find.widgetWithText(
      EnlaceSecundario,
      TextosDeLaBienvenida.olvidaste,
    );
    expect(_enfocado(olvidaste), isTrue);
    expect(_anilloDe(tester, olvidaste), _anilloEncendido);
    await _tab(tester);
    expect(_enfocado(soyNuevo), isTrue);
  });

  testWidgets('el anillo de foco rodea también los dos botones del '
      'recibimiento y las píldoras, y un toque no lo enciende', (tester) async {
    _conTecladoFisico();
    await montarLaBienvenida(tester, Bienvenida(), argumentos: _conPose());
    await avanzar(tester, 3000);
    expect(_anilloSobre(tester, TextosDeLaBienvenida.siEntrar), isNull);
    await _tab(tester);
    expect(
      _anilloSobre(tester, TextosDeLaBienvenida.siEntrar),
      _anilloEncendido,
    );
    await _tab(tester);
    expect(_anilloSobre(tester, TextosDeLaBienvenida.siEntrar), isNull);
    expect(
      _anilloSobre(tester, TextosDeLaBienvenida.soyNuevo),
      _anilloEncendido,
    );

    const tema = MaterialTheme(TextTheme());
    await tester.pumpWidget(
      MaterialApp(
        theme: tema.light(),
        home: Scaffold(
          body: Center(
            child: RespuestasRapidas(
              respuestas: [
                RespuestaRapida(
                  texto: TextosDeLaBienvenida.volver,
                  alTocar: () {},
                ),
                RespuestaRapida(
                  texto: TextosDeLaBienvenida.acepto,
                  alTocar: () {},
                  principal: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await _tab(tester);
    expect(_anilloSobre(tester, TextosDeLaBienvenida.volver), _anilloEncendido);
    await _tab(tester);
    expect(_anilloSobre(tester, TextosDeLaBienvenida.volver), isNull);
    expect(_anilloSobre(tester, TextosDeLaBienvenida.acepto), _anilloEncendido);

    // Con el tacto, el foco no se ve (FocusHighlightMode.touch).
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTouch;
    await tester.pump();
    expect(_anilloSobre(tester, TextosDeLaBienvenida.acepto), isNull);
  });

  for (final escala in <double>[1.0, 1.3, 2.0]) {
    testWidgets('con el texto al ${(escala * 100).round()} % en 375 × 667, E1 '
        'y E2 no desbordan', (tester) async {
      await montarLaBienvenida(
        tester,
        Bienvenida(),
        argumentos: _expirada,
        escala: escala,
      );
      await avanzar(tester, 1500);
      expect(tester.takeException(), isNull);
      // «Continuar con Google» crece con su texto en lugar de recortarlo.
      final texto = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: find.byType(BotonDeGoogle),
          matching: find.byType(RichText),
        ),
      );
      expect(
        texto.size.height,
        greaterThanOrEqualTo(
          texto.getMinIntrinsicHeight(texto.size.width) - 0.5,
        ),
        reason: 'el texto se recorta',
      );
      expect(
        tester.getSize(find.byType(BotonDeGoogle)).height,
        greaterThanOrEqualTo(48),
      );
      await llegarAE2(tester);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('la píldora y el error local son regiones vivas, las burbujas '
      'no, y los controles son botones con su acción, con el ojo que dice '
      '«Mostrar contraseña» y «Ocultar contraseña» (RF-BIEN-16)', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    const tema = MaterialTheme(TextTheme());
    var visible = false;
    Finder vivaEn(Type tipo) => find.descendant(
      of: find.byType(tipo),
      matching: find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.liveRegion == true,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: tema.light(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => ListView(
              children: [
                const PildoraDelRegistro(estado: EstadoDeLaPildora.creando),
                const ErrorLocal('Ingresa tu código de alumno.'),
                EntradaView(
                  entrada: const BurbujaDeUlises(id: 1, texto: 'Hola'),
                  anterior: null,
                  primerGrupo: false,
                  resultado: (_, _) => const SizedBox.shrink(),
                ),
                OjoDeLaContrasena(
                  visible: visible,
                  alTocar: () => setState(() => visible = !visible),
                ),
                BotonPrincipal(
                  texto: TextosDeLaBienvenida.entrar,
                  alTocar: () {},
                ),
                RespuestaRapida(
                  texto: TextosDeLaBienvenida.acepto,
                  alTocar: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    for (final tipo in [PildoraDelRegistro, ErrorLocal]) {
      expect(
        tester.getSemantics(vivaEn(tipo)),
        isSemantics(isLiveRegion: true),
        reason: '$tipo',
      );
    }
    expect(vivaEn(EntradaView), findsNothing);
    expect(
      tester.getSemantics(find.text('Hola')),
      isSemantics(isLiveRegion: false),
    );
    for (final texto in [
      TextosDeLaBienvenida.mostrarContrasena,
      TextosDeLaBienvenida.entrar,
      TextosDeLaBienvenida.acepto,
    ]) {
      expect(
        tester.getSemantics(find.bySemanticsLabel(texto)),
        isSemantics(label: texto, isButton: true, hasTapAction: true),
        reason: texto,
      );
    }
    await tester.tap(find.byType(OjoDeLaContrasena));
    await tester.pump();
    expect(
      tester.getSemantics(
        find.bySemanticsLabel(TextosDeLaBienvenida.ocultarContrasena),
      ),
      isSemantics(
        label: TextosDeLaBienvenida.ocultarContrasena,
        isButton: true,
        hasTapAction: true,
      ),
    );
    semantica.dispose();
  });
}
