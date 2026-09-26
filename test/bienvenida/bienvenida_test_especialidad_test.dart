// test/bienvenida/bienvenida_test_especialidad_test.dart
//
// UNITARIA + WIDGET · Bienvenida con Ulises
// (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-10 y la enmienda aprobada a la spec del test. Con el origen
// `bienvenida`, el controlador del test se crea y se cierra sin GetX, no usa
// la precarga ni la pausa, empieza siempre en la pregunta 1, termina en el
// paso al horario y descarta lo que responde después de cerrarse. Las
// tarjetas compactas del duelo y la escala con solo sus opciones en el
// compositor (B-13), y los turnos del test en la conversación, desde T0
// hasta el resultado y la selección manual.
// Archivos probados lib/pages/specialty_test/specialty_test_controller.dart,
// lib/pages/specialty_test/widgets/question_view.dart,
// lib/pages/bienvenida/bienvenida_controller.dart y
// lib/pages/bienvenida/widgets/compositor_del_test.dart.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ulima_plus/components/logo/sello_del_logo.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/domain/bienvenida/bienvenida_turnos.dart';
import 'package:ulima_plus/models/specialty_test_models.dart';
import 'package:ulima_plus/models/user_model.dart';
import 'package:ulima_plus/pages/bienvenida/conversacion.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/compositor.dart';
import 'package:ulima_plus/pages/bienvenida/widgets/compositor_del_test.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/question_view.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/result_view.dart';
import 'package:ulima_plus/pages/specialty_test/widgets/task_icon.dart';
import 'package:ulima_plus/services/session_navigation.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';

import '../HU36_jeff/datos_de_prueba.dart';
import '../HU36_jeff/dobles_de_red.dart';
import '../HU36_jeff/dobles_del_controlador.dart';
import 'apoyo_bienvenida.dart';

/// El controlador como lo crea la bienvenida, sin Get.put.
Future<SpecialtyTestController> _enLaBienvenida(UiFalsa ui) async {
  final c = SpecialtyTestController(origen: OrigenDelTest.bienvenida, ui: ui)
    ..onStart();
  await pumpEventQueue();
  return c;
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  group('el controlador con origen bienvenida (enmienda a RF-TEST-1, '
      'RF-TEST-2 y RF-TEST-9, B-34)', () {
    test('no adopta el test en pausa del Perfil, no lo descarta ni lo '
        'reemplaza al cerrarse', () async {
      final (:auth, :service) = prepararTest(ApiFalsaDelTest());
      final pausa = PausedSpecialtyTest(
        content: SpecialtyTestContent.tryParse(contenidoJson())!,
        answers: const <String, String>{'q01': 'bottom', 'q02': 'none'},
        tiebreaks: const <TiebreakRecord>[],
      );
      service.pause(pausa);
      final c = await _enLaBienvenida(UiFalsa());
      expect(c.enBienvenida, isTrue);
      expect(c.terminaEnElHome, isTrue);
      expect(c.respuestas, isEmpty, reason: 'no adopta la pausa');
      c.empezar();
      expect(c.paso.value, 0);
      c.responder('top', avanceSolo: false);
      c.onDelete();
      expect(service.paused, same(pausa), reason: 'no la reemplaza');
      // Saltar borra sus respuestas sin descartar la pausa.
      final otro = await _enLaBienvenida(UiFalsa());
      otro
        ..empezar()
        ..responder('top', avanceSolo: false)
        ..saltar();
      expect(service.paused, same(pausa), reason: 'no la descarta');
      otro.onDelete();
      expect(auth.guardados, isEmpty);
    });

    test('pide el contenido una vez, sin la precarga', () async {
      final api = ApiFalsaDelTest();
      final (auth: _, :service) = prepararTest(api);
      service.prefetchContent();
      await pumpEventQueue();
      final antes = api.getsDeContenido;
      final c = await _enLaBienvenida(UiFalsa());
      expect(api.getsDeContenido, antes + 1);
      expect(c.carga.value, EstadoDeCarga.lista);
    });

    test('«Elegir como principal» y «Decidir después» terminan en el paso '
        'al horario, como el asistente', () async {
      prepararTest(ApiFalsaDelTest());
      final ui = UiFalsa();
      final c = await _enLaBienvenida(ui);
      c.empezar();
      responderPasos(c, respuestasEnOrden);
      await pumpEventQueue();
      expect(c.resultado.value, isNotNull);
      await c.elegirPrincipal(c.resultado.value!.ranking.first.specialtyId);
      expect(ui.alHome, 1);
      expect(ui.cierres, isEmpty);
    });

    test('«Decidir después» guarda y termina en el paso al horario', () async {
      final (:auth, service: _) = prepararTest(ApiFalsaDelTest());
      final ui = UiFalsa();
      final c = await _enLaBienvenida(ui);
      c.empezar();
      responderPasos(c, respuestasEnOrden);
      await pumpEventQueue();
      await c.decidirDespues();
      expect(auth.guardados, hasLength(1));
      expect(ui.alHome, 1);
      expect(ui.cierres, isEmpty);
    });

    for (final guarda in <bool>[true, false]) {
      test('un PUT que ${guarda ? 'guarda' : 'falla'} después del cierre se '
          'descarta, sin el paso al horario ni avisos (B-34 y enmienda a '
          'RF-TEST-2)', () async {
        final (:auth, service: _) = prepararTest(ApiFalsaDelTest());
        final respuesta = Completer<void>();
        auth.respuestasDeGuardado.add(respuesta);
        final ui = UiFalsa();
        final c = await _enLaBienvenida(ui);
        c.empezar();
        responderPasos(c, respuestasEnOrden);
        await pumpEventQueue();
        final guardado = c.elegirPrincipal(
          c.resultado.value!.ranking.first.specialtyId,
        );
        c.onDelete();
        if (guarda) {
          respuesta.complete();
        } else {
          respuesta.completeError(Exception('sin red'));
        }
        await guardado;
        await pumpEventQueue();
        expect(ui.alHome, 0);
        expect(ui.avisos, isEmpty);
      });
    }

    test('el atrás en el resultado no hace nada', () async {
      prepararTest(ApiFalsaDelTest());
      final ui = UiFalsa();
      final c = await _enLaBienvenida(ui);
      c.empezar();
      responderPasos(c, respuestasEnOrden);
      await pumpEventQueue();
      c.atrasEnResultado();
      await pumpEventQueue();
      expect(ui.alHome, 0);
      expect(ui.cierres, isEmpty);
    });

    test('un 404 pasa a la selección manual sin aviso', () async {
      prepararTest(
        ApiFalsaDelTest(
          contenido: <Object>[
            const SpecialtyTestFailure(
              SpecialtyTestFailureKind.notAvailable,
              message:
                  'El test de especialidad no está disponible para tu carrera.',
            ),
          ],
        ),
      );
      final ui = UiFalsa();
      await _enLaBienvenida(ui);
      expect(ui.cierres, [SalidaDelTest.seleccionManual]);
      expect(ui.avisos, isEmpty);
    });

    test('sin carrera no llama a completeSetup y avisa «No se pudo determinar '
        'tu carrera.»', () async {
      final sinCarrera = UserModel(
        code: '20230001',
        firstName: 'Alumna',
        lastName: 'De Prueba',
        email: 'test@aloe.ulima.edu.pe',
        role: 'student',
        currentCycle: '2026-2',
        setupComplete: false,
      );
      final (:auth, service: _) = prepararTest(
        ApiFalsaDelTest(),
        usuario: sinCarrera,
      );
      final ui = UiFalsa();
      final c = await _enLaBienvenida(ui);
      c.empezar();
      responderPasos(c, respuestasEnOrden);
      await pumpEventQueue();
      await c.decidirDespues();
      expect(auth.guardados, isEmpty);
      expect(ui.avisos.single.mensaje, 'No se pudo determinar tu carrera.');
      expect(ui.alHome, 0);
    });

    test(
      'una evaluación que responde después del cierre se descarta',
      () async {
        prepararTest(ApiFalsaDelTest());
        final ui = UiFalsa();
        final c = await _enLaBienvenida(ui);
        c.empezar();
        responderPasos(c, respuestasEnOrden);
        c.onDelete();
        await pumpEventQueue();
        expect(c.resultado.value, isNull);
        expect(ui.cierres, isEmpty);
        expect(ui.avisos, isEmpty);
      },
    );
  });

  group('las piezas compactas (B-13)', () {
    testWidgets('en el compositor, las tarjetas son las compactas de la '
        'maqueta, de 56 dp con la baldosa de 40 dp y radio 11, el ícono de '
        '22 dp, el borde de 1,5, el radio de 16, el texto de 12,5 a 10 dp de '
        'la baldosa, 8 dp entre ellas, la moneda de 26 y la insignia de 24 '
        '(B-13 y RF-BIEN-10)', (tester) async {
      final contenido = SpecialtyTestContent.tryParse(contenidoJson())!;
      final duelo = contenido.questions.firstWhere((q) => q.isDuel);
      const tema = MaterialTheme(TextTheme());
      Future<void> montar(String? respuesta) => tester.pumpWidget(
        MaterialApp(
          theme: tema.light(),
          home: Scaffold(
            body: DueloDelTest(
              tareas: [duelo.top!, duelo.bottom!],
              contenido: contenido,
              respuesta: respuesta,
              ayuda: null,
              onTap: (_) {},
              compacto: true,
            ),
          ),
        ),
      );
      await montar(null);
      final tarjetas = find.byType(TarjetaDeTarea);
      expect(tarjetas, findsNWidgets(2));
      expect(tester.getSize(tarjetas.first).height, 56);
      expect(tester.getSize(tarjetas.last).height, 56);
      expect(
        tester.getTopLeft(tarjetas.last).dy -
            tester.getBottomLeft(tarjetas.first).dy,
        8,
      );
      final caja = tester.widget<AnimatedContainer>(
        find
            .descendant(
              of: tarjetas.first,
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      final decoracion = caja.decoration! as BoxDecoration;
      expect((decoracion.border! as Border).top.width, 1.5);
      expect(decoracion.borderRadius, BorderRadius.circular(16));
      final baldosa = find.byType(TaskIconTile).first;
      expect(tester.getSize(baldosa), const Size(40, 40));
      expect(
        tester.widget<TaskIconTile>(baldosa).borderRadius,
        BorderRadius.circular(11),
      );
      final icono = find.descendant(of: baldosa, matching: find.byType(Icon));
      expect(tester.getSize(icono), const Size(22, 22));
      final texto = find.text(duelo.top!.text);
      expect(tester.widget<Text>(texto).style!.fontSize, 12.5);
      expect(tester.getTopLeft(texto).dx - tester.getTopRight(baldosa).dx, 10);
      final moneda = find.ancestor(
        of: find.text('o'),
        matching: find.byType(Container),
      );
      expect(tester.getSize(moneda.first), const Size(26, 26));
      // La encendida lleva la insignia del visto.
      await montar('top');
      await tester.pumpAndSettle();
      final visto = find.byIcon(LucideIcons.check);
      expect(tester.widget<Icon>(visto).size, 12);
      final insignia = find.ancestor(
        of: visto,
        matching: find.byType(Container),
      );
      expect(tester.getSize(insignia.first), const Size(24, 24));
    });

    testWidgets('en el compositor, la escala trae solo sus cuatro opciones, '
        'sin la baldosa, el rótulo de la tarjeta, la tarea ni el prompt, y '
        'su grupo se lee con el prompt (RF-BIEN-10 y enmienda a RF-TEST-6)', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      final contenido = SpecialtyTestContent.tryParse(contenidoJson())!;
      final escala = contenido.questions.firstWhere((q) => !q.isDuel);
      const tema = MaterialTheme(TextTheme());
      await tester.pumpWidget(
        MaterialApp(
          theme: tema.light(),
          home: Scaffold(
            body: EscalaDelTest(
              pregunta: escala,
              opciones: contenido.scaleOptions,
              respuesta: null,
              onTap: (_) {},
              compacto: true,
            ),
          ),
        ),
      );
      expect(find.byType(OpcionDeEscala), findsNWidgets(4));
      expect(find.byType(TaskIconTile), findsNothing);
      expect(find.text('ESCALA DE GUSTO'), findsNothing);
      expect(find.text(escala.task!.text), findsNothing);
      expect(find.text(escala.prompt), findsNothing);
      expect(find.bySemanticsLabel(escala.prompt), findsOneWidget);
      semantica.dispose();
    });

    test('los emojis de la escala son públicos y siguen el orden de las '
        'opciones (RF-TEST-6)', () {
      expect(emojisDeLaEscala, ['😴', '🙂', '😃', '🤩']);
    });
  });

  group('el test en la conversación (RF-BIEN-10)', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    /// Una alumna recién registrada, con la conversación en T0.
    Future<Bienvenida> enT0({ApiFalsaDelTest? api, int? careerId = 1}) async {
      final b = Bienvenida(
        auth: AuthDeLaBienvenida(
          usuario: alumnaDePrueba(setupComplete: false, careerId: careerId),
          alEntrar: alumnaDePrueba(setupComplete: false, careerId: careerId),
        ),
        token: 'jwt-de-prueba',
        apiDelTest: api,
      );
      await b.visitar();
      b.controlador.ulisesAterrizoConSesion();
      await pumpEventQueue();
      return b;
    }

    String? ultimaDeUlises(Bienvenida b) =>
        b.deUlises.isEmpty ? null : b.deUlises.last;

    test('mientras llega el contenido Ulises muestra la burbuja de carga, y '
        'después la invitación con T preguntas (B-11 y B-12)', () async {
      final b = await enT0();
      final c = b.controlador;
      expect(c.test, isNotNull);
      expect(Get.isRegistered<SpecialtyTestController>(), isFalse);
      // Un Get.put sobre el campo anulable lo registraría con ese tipo.
      expect(Get.isRegistered<SpecialtyTestController?>(), isFalse);
      expect(
        ultimaDeUlises(b),
        '¿Empezamos tu test de especialidad? Son 5 preguntas cortas.',
      );
      expect(
        c.entradas.whereType<BurbujaDeUlises>().any(
          (e) => e.tipo == TipoDeBurbuja.cargando,
        ),
        isFalse,
        reason: 'la burbuja de carga se reemplaza',
      );
      expect(c.turno.value, TurnoDeLaBienvenida.t0Invitacion);
    });

    test('cada pregunta es un turno con sus líneas y el prompt, y la respuesta '
        'es el texto de la tarea o el emoji con la etiqueta', () async {
      final b = await enT0();
      final c = b.controlador..empezarElTest();
      expect(b.delAlumno.last, TextosDeLaBienvenida.empezarElTest);
      expect(
        b.deUlises,
        containsAllInOrder([kDuelHelp, '¿Cuál harías con más ganas?']),
      );
      expect(c.turno.value, TurnoDeLaBienvenida.pregunta);
      final tareaDeArriba = c.test!.preguntaActual!.top!.text;
      c
        ..responderAlTest('top', conLector: true)
        ..siguiente();
      expect(b.delAlumno.last, tareaDeArriba);
      expect(b.deUlises, contains('Reacción propia de la pregunta uno.'));
      expect(c.latidos.value, greaterThanOrEqualTo(2));
      // La tercera es una escala: el emoji con la etiqueta.
      c
        ..responderAlTest('both', conLector: true)
        ..siguiente()
        ..responderAlTest('bastante', conLector: true)
        ..siguiente();
      expect(b.delAlumno.last, '😃 Bastante');
    });

    test('«Pregunta anterior» repite el paso previo, y desde la pregunta 1 '
        'lleva a T0', () async {
      final b = await enT0();
      final c = b.controlador..empezarElTest();
      c
        ..responderAlTest('top', conLector: true)
        ..siguiente()
        ..preguntaAnterior();
      expect(b.delAlumno.last, TextosDeLaBienvenida.preguntaAnterior);
      expect(c.test!.paso.value, 0);
      expect(c.turno.value, TurnoDeLaBienvenida.pregunta);
      c.preguntaAnterior();
      expect(c.turno.value, TurnoDeLaBienvenida.t0Invitacion);
    });

    test('tras volver a T0, «Empezar el test» abre la pregunta 1 sin '
        'respuestas, porque en la conversación no hay «Seguir el test» '
        '(enmienda a RF-TEST-3)', () async {
      final b = await enT0();
      final c = b.controlador..empezarElTest();
      c
        ..responderAlTest('top', conLector: true)
        ..siguiente()
        ..responderAlTest('both', conLector: true)
        ..siguiente()
        ..preguntaAnterior()
        ..preguntaAnterior()
        ..preguntaAnterior();
      expect(c.turno.value, TurnoDeLaBienvenida.t0Invitacion);
      c.empezarElTest();
      expect(c.turno.value, TurnoDeLaBienvenida.pregunta);
      expect(c.test!.paso.value, 0);
      expect(c.test!.respuestas, isEmpty);
      expect(c.test!.respuestaActual, isNull);
      expect(b.deUlises.last, '¿Cuál harías con más ganas?');
    });

    test('la espera dice la línea de carga, y el resultado entra con el '
        'confeti y sus tres botones', () async {
      final b = await enT0();
      final c = b.controlador..empezarElTest();
      for (final v in respuestasEnOrden) {
        c
          ..responderAlTest(v, conLector: true)
          ..siguiente();
      }
      expect(
        c.entradas.whereType<BurbujaDeUlises>().last.tipo,
        TipoDeBurbuja.esperando,
      );
      expect(b.deUlises.last, kLoading);
      await pumpEventQueue();
      expect(c.confeti.value, 1);
      expect(
        b.deUlises.last,
        'Lo tuyo apunta a Desarrollo de Videojuegos, con 75 % de afinidad.',
        reason: 'el titular del resultado',
      );
      expect(c.entradas.whereType<ResultadoDelTest>(), hasLength(1));
      expect(c.turno.value, TurnoDeLaBienvenida.resultado);
    });

    test('«Decidir después» guarda, responde y se despide hacia el '
        'horario', () async {
      final b = await enT0();
      final c = b.controlador..empezarElTest();
      for (final v in respuestasEnOrden) {
        c
          ..responderAlTest(v, conLector: true)
          ..siguiente();
      }
      await pumpEventQueue();
      await c.decidirDespues();
      expect(b.auth.guardados, hasLength(1));
      expect(b.delAlumno.last, TextosDeLaBienvenida.decidirDespues);
      expect(b.deUlises.last, TextosDeLaBienvenida.listoAlHorario);
      expect(c.turno.value, TurnoDeLaBienvenida.pasoAlHorario);
    });

    test('«Elegir como principal» guarda, responde y se despide hacia el '
        'horario', () async {
      final b = await enT0();
      final c = b.controlador..empezarElTest();
      for (final v in respuestasEnOrden) {
        c
          ..responderAlTest(v, conLector: true)
          ..siguiente();
      }
      await pumpEventQueue();
      final primera = c.test!.resultado.value!.ranking.first.specialtyId;
      await c.elegirComoPrincipal(primera);
      expect(b.auth.guardados.single.principal, primera);
      expect(b.delAlumno.last, 'Elegir como principal');
      expect(b.deUlises.last, TextosDeLaBienvenida.listoAlHorario);
      expect(c.turno.value, TurnoDeLaBienvenida.pasoAlHorario);
    });

    test('«Rehacer el test» vuelve a la pregunta 1 sin pasar por T0', () async {
      final b = await enT0();
      final c = b.controlador..empezarElTest();
      for (final v in respuestasEnOrden) {
        c
          ..responderAlTest(v, conLector: true)
          ..siguiente();
      }
      await pumpEventQueue();
      c.rehacerElTest();
      expect(b.delAlumno.last, 'Rehacer el test');
      expect(c.turno.value, TurnoDeLaBienvenida.pregunta);
      expect(c.test!.paso.value, 0);
    });

    test('«Saltar y elegir por mi cuenta» pasa a la selección manual con la '
        'lista oficial, y el atrás vuelve a T0', () async {
      final b = await enT0();
      final c = b.controlador..saltarElTest();
      expect(b.deUlises.last, TextosDeLaBienvenida.eligeMencion);
      expect(c.turno.value, TurnoDeLaBienvenida.seleccionManual);
      expect(c.especialidadesOficiales.map((e) => e['id']), [1, 5, 6, 7]);
      c.atras();
      expect(c.turno.value, TurnoDeLaBienvenida.t0Invitacion);
    });

    test('la selección manual guarda con «Finalizar configuración» o «Saltar '
        'por ahora»', () async {
      final b = await enT0();
      final c = b.controlador
        ..saltarElTest()
        ..marcarPrincipal(5)
        ..alternarInteres(7);
      await c.terminarLaSeleccion();
      expect(b.auth.guardados.single.principal, 5);
      expect(b.auth.guardados.single.intereses, [7]);
      expect(b.delAlumno.last, TextosDeLaBienvenida.finalizar);
      expect(c.turno.value, TurnoDeLaBienvenida.pasoAlHorario);

      // Sin marcar nada, la respuesta es «Saltar por ahora».
      final otra = await enT0();
      final d = otra.controlador..saltarElTest();
      await d.terminarLaSeleccion();
      expect(otra.auth.guardados.single.principal, isNull);
      expect(otra.auth.guardados.single.intereses, isEmpty);
      expect(otra.delAlumno.last, TextosDeLaBienvenida.saltarPorAhora);
      expect(d.turno.value, TurnoDeLaBienvenida.pasoAlHorario);
    });

    test('un 404 pasa a la selección manual sin aviso, y el atrás no hace '
        'nada', () async {
      final b = await enT0(
        api: ApiFalsaDelTest(
          contenido: <Object>[
            const SpecialtyTestFailure(
              SpecialtyTestFailureKind.notAvailable,
              message: 'No disponible.',
            ),
          ],
        ),
      );
      final c = b.controlador;
      expect(c.turno.value, TurnoDeLaBienvenida.seleccionManual);
      expect(b.deUlises, isNot(contains('No disponible.')));
      c.atras();
      expect(c.turno.value, TurnoDeLaBienvenida.seleccionManual);
    });

    test(
      'sin carrera no guarda y dice el texto de hoy del asistente',
      () async {
        final b = await enT0(careerId: null);
        final c = b.controlador
          ..saltarElTest()
          ..marcarPrincipal(5);
        await c.terminarLaSeleccion();
        expect(b.auth.guardados, isEmpty);
        expect(b.deUlises.last, TextosDeLaBienvenida.sinCarrera);
      },
    );

    test(
      'si el catálogo no carga, dice que no pudo y ofrece reintentar',
      () async {
        final b = await enT0();
        b.auth.catalogoFalla = true;
        final c = b.controlador..saltarElTest();
        expect(b.deUlises.last, TextosDeLaBienvenida.noCargaronEspecialidades);
        expect(c.catalogoFallido.value, isTrue);
        await c.reintentarElCatalogo();
        expect(c.catalogoFallido.value, isFalse);
      },
    );
  });

  group('el compositor del test (RF-BIEN-10 y B-13)', () {
    /// Entra con la configuración a medias desde E1, así que la
    /// conversación sigue con el test (RF-BIEN-6 y B-10).
    Future<Bienvenida> enT0(WidgetTester tester, {ApiFalsaDelTest? api}) async {
      final b = Bienvenida(
        auth: AuthDeLaBienvenida(
          alEntrar: alumnaDePrueba(setupComplete: false),
        ),
        token: 'jwt-de-prueba',
        apiDelTest: api,
      );
      await montarLaBienvenida(
        tester,
        b,
        argumentos: const {argumentoDeMotivo: MotivoDeLlegada.expirada},
      );
      await avanzar(tester, 1500);
      await tester.enterText(find.byType(TextField).first, '20230001');
      await tester.pump();
      await tester.tap(find.byType(BotonDeEnvio));
      await avanzar(tester, 2000);
      await tester.enterText(find.byType(TextField).first, 'secreta-de-prueba');
      await tester.pump();
      await tester.tap(find.text(TextosDeLaBienvenida.entrar));
      await avanzar(tester, 3500);
      return b;
    }

    testWidgets('T0 ofrece «Saltar y elegir por mi cuenta» y «Empezar el '
        'test»', (tester) async {
      await enT0(tester);
      expect(find.text(TextosDeLaBienvenida.saltar), findsOneWidget);
      expect(find.text(TextosDeLaBienvenida.empezarElTest), findsOneWidget);
    });

    testWidgets('si el contenido no carga, T0 ofrece «Reintentar» en lugar '
        'de «Empezar el test» (RF-BIEN-12)', (tester) async {
      final b = await enT0(
        tester,
        api: ApiFalsaDelTest(
          contenido: <Object>[
            const SpecialtyTestFailure(SpecialtyTestFailureKind.offline),
            contenidoJson(),
          ],
        ),
      );
      final compositor = find.byType(MarcoDelCompositor);
      expect(
        find.descendant(
          of: compositor,
          matching: find.text(TextosDeLaBienvenida.reintentar),
        ),
        findsOneWidget,
      );
      expect(find.text(TextosDeLaBienvenida.empezarElTest), findsNothing);
      expect(find.text(TextosDeLaBienvenida.saltar), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: compositor,
          matching: find.text(TextosDeLaBienvenida.reintentar),
        ),
      );
      await avanzar(tester, 3500);
      expect(b.controlador.turno.value, TurnoDeLaBienvenida.t0Invitacion);
      expect(find.text(TextosDeLaBienvenida.empezarElTest), findsOneWidget);
    });

    testWidgets('la espera con un error ofrece «Reintentar» y «Pregunta '
        'anterior», y el resultado entra con su tarjeta y sus tres botones', (
      tester,
    ) async {
      final b = await enT0(
        tester,
        api: ApiFalsaDelTest(
          evaluaciones: <Object>[
            const SpecialtyTestFailure(SpecialtyTestFailureKind.offline),
            resultadoJson(),
          ],
        ),
      );
      final c = b.controlador..empezarElTest();
      for (final v in respuestasEnOrden) {
        c
          ..responderAlTest(v, conLector: true)
          ..siguiente();
      }
      await avanzar(tester, 16000);
      expect(c.turno.value, TurnoDeLaBienvenida.espera);
      final compositor = find.byType(MarcoDelCompositor);
      Finder enElCompositor(String texto) =>
          find.descendant(of: compositor, matching: find.text(texto));
      expect(
        enElCompositor(TextosDeLaBienvenida.preguntaAnterior),
        findsOneWidget,
      );
      await tester.tap(enElCompositor(TextosDeLaBienvenida.reintentar));
      await avanzar(tester, 200);
      // El confeti cae bajo la franja, nunca sobre el sello (RF-BIEN-10).
      final confeti = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is PintorDelConfeti,
      );
      expect(confeti, findsOneWidget);
      expect(
        tester.getRect(confeti).top,
        greaterThanOrEqualTo(
          tester.getRect(find.byType(CabeceraConSello)).bottom - 0.5,
        ),
      );
      await avanzar(tester, 6000);
      expect(c.turno.value, TurnoDeLaBienvenida.resultado);
      expect(find.byType(TarjetaGanadora, skipOffstage: false), findsOneWidget);
      for (final boton in <String>[
        TextosDeLaBienvenida.elegirComoPrincipal,
        TextosDeLaBienvenida.decidirDespues,
        TextosDeLaBienvenida.rehacerElTest,
      ]) {
        expect(enElCompositor(boton), findsOneWidget, reason: boton);
      }
      expect(
        enElCompositor(TextosDeLaBienvenida.preguntaAnterior),
        findsNothing,
      );
    });

    testWidgets('el duelo va en el compositor con el rótulo, las tarjetas '
        'compactas y las dos opciones de abajo', (tester) async {
      final b = await enT0(tester);
      await tester.tap(find.text(TextosDeLaBienvenida.empezarElTest));
      await avanzar(tester, 3500);
      // El rótulo va en mayúsculas (RF-BIEN-10).
      expect(find.text('ESTO O AQUELLO · 1 DE 5'), findsOneWidget);
      final duelo = tester.widget<DueloDelTest>(find.byType(DueloDelTest));
      expect(duelo.compacto, isTrue);
      expect(
        find.text(TextosDeLaBienvenida.preguntaAnterior),
        findsNothing,
        reason: 'la pregunta 1 no la ofrece',
      );
      expect(find.text('Me gustan las dos'), findsOneWidget);
      expect(find.text('Ninguna me llama'), findsOneWidget);
      final tarea = b.controlador.test!.preguntaActual!.top!.text;
      await tester.tap(find.byType(TarjetaDeTarea).first);
      await tester.pump(const Duration(milliseconds: 360));
      await avanzar(tester, 300);
      expect(find.text(tarea), findsWidgets, reason: 'la respuesta del alumno');
      expect(
        find.text(TextosDeLaBienvenida.preguntaAnterior),
        findsNothing,
        reason: 'la pregunta 2 todavía no entra',
      );
      await avanzar(tester, 3000);
      expect(find.text(TextosDeLaBienvenida.preguntaAnterior), findsOneWidget);
    });

    testWidgets('en una escala, la tarea va una sola vez, en la burbuja de '
        'Ulises, y el compositor no trae su ícono (RF-BIEN-10)', (
      tester,
    ) async {
      final b = await enT0(tester);
      await tester.tap(find.text(TextosDeLaBienvenida.empezarElTest));
      await avanzar(tester, 3500);
      // Las dos primeras son duelos, y la tercera, una escala.
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byType(TarjetaDeTarea).first);
        await avanzar(tester, 5000);
      }
      final pregunta = b.controlador.test!.preguntaActual!;
      expect(pregunta.isDuel, isFalse);
      expect(find.text('ESCALA DE GUSTO · 3 DE 5'), findsOneWidget);
      final compositor = find.byType(MarcoDelCompositor);
      expect(
        find.descendant(of: compositor, matching: find.byType(OpcionDeEscala)),
        findsNWidgets(4),
      );
      expect(
        find.descendant(of: compositor, matching: find.byType(TaskIconTile)),
        findsNothing,
      );
      expect(find.text(pregunta.task!.text), findsOneWidget);
      expect(
        find.descendant(
          of: compositor,
          matching: find.text(pregunta.task!.text),
        ),
        findsNothing,
      );
    });

    testWidgets('con reducir movimiento el resultado no trae confeti pero sí '
        'la vibración de RF-TEST-8, como el test en su pantalla (RF-TEST-13 '
        'y RF-BIEN-15)', (tester) async {
      final vibraciones = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (llamada) async {
          if (llamada.method == 'HapticFeedback.vibrate') {
            vibraciones.add(llamada.arguments);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final b = Bienvenida(
        auth: AuthDeLaBienvenida(
          alEntrar: alumnaDePrueba(setupComplete: false),
        ),
        token: 'jwt-de-prueba',
      );
      await montarLaBienvenida(
        tester,
        b,
        argumentos: const {argumentoDeMotivo: MotivoDeLlegada.expirada},
        sinMovimiento: true,
      );
      await avanzar(tester, 1500);
      b.login.codeController.text = '20230001';
      b.controlador.enviarCodigo();
      b.login.passwordController.text = 'secreta-de-prueba';
      await b.controlador.entrar();
      await avanzar(tester, 3000);
      final c = b.controlador..empezarElTest();
      for (final v in respuestasEnOrden) {
        c
          ..responderAlTest(v, conLector: true)
          ..siguiente();
      }
      await tester.pump();
      await tester.pump();
      expect(c.confeti.value, 1);
      expect(vibraciones, ['HapticFeedbackType.heavyImpact']);
      expect(
        find.byType(CustomPaint).evaluate().where((e) {
          final w = e.widget as CustomPaint;
          return w.painter is PintorDelConfeti;
        }),
        isEmpty,
      );
      await avanzar(tester, 16000);
    });

    testWidgets('tras «Rehacer el test», el resultado anterior sigue en la '
        'conversación, de solo lectura, con los corazones que tenía '
        '(RF-BIEN-5 y RF-BIEN-10)', (tester) async {
      final b = await enT0(tester);
      final c = b.controlador..empezarElTest();
      for (final v in respuestasEnOrden) {
        c
          ..responderAlTest(v, conLector: true)
          ..siguiente();
      }
      // Las 28 entradas del test entran con su ritmo.
      await avanzar(tester, 16000);
      final resultados = find.byType(
        ResultadoEnLaConversacion,
        skipOffstage: false,
      );
      expect(resultados, findsOneWidget);
      final segunda = c.test!.resultado.value!.ranking[1].specialtyId;
      c.alternarCorazon(segunda);
      await avanzar(tester, 500);
      c.rehacerElTest();
      await avanzar(tester, 3000);
      expect(resultados, findsOneWidget, reason: 'la entrada sigue');
      expect(
        find.byType(TarjetaGanadora, skipOffstage: false),
        findsOneWidget,
        reason: 'con su tarjeta, aunque el test ya no tenga resultado',
      );
      final filas = tester
          .widgetList<FilaDelRanking>(
            find.byType(FilaDelRanking, skipOffstage: false),
          )
          .toList();
      expect(filas, isNotEmpty);
      expect(filas.every((f) => f.onCorazon == null), isTrue);
      expect(
        filas.firstWhere((f) => f.entrada.specialtyId == segunda).marcada,
        isTrue,
        reason: 'el corazón que tenía',
      );
    });

    testWidgets('la selección manual lista las oficiales con «Principal» y '
        '«Me interesa»', (tester) async {
      await enT0(tester);
      await tester.tap(find.text(TextosDeLaBienvenida.saltar));
      await avanzar(tester, 3000);
      expect(find.text('Ingeniería de Software'), findsOneWidget);
      expect(find.text(TextosDeLaBienvenida.principal), findsNWidgets(4));
      expect(find.text(TextosDeLaBienvenida.meInteresa), findsNWidgets(4));
      expect(find.text(TextosDeLaBienvenida.saltarPorAhora), findsOneWidget);
      await tester.tap(find.text(TextosDeLaBienvenida.principal).first);
      await tester.pump();
      expect(find.text(TextosDeLaBienvenida.finalizar), findsOneWidget);
    });
  });
}
