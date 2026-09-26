// test/HU36_jeff/specialty_test_perfil_test.dart
//
// Pruebas de widget de HU36, el test de especialidad, sobre el último
// resultado en el Perfil y «Rehacer el test» (RF-TEST-10).
// Tarjeta: lib/pages/specialty_test/specialty_test_profile_card.dart
//
// Datos inventados (datos_de_prueba.dart). El alumno de prueba es 20230001.
// La fecha se mide en hora de Lima, y la verificación de la spec corre esta
// carpeta con TZ=UTC.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/specialty_test_models.dart';
import 'package:ulima_plus/pages/perfil/perfil.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_page.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_profile_card.dart';
import 'package:ulima_plus/services/academic_record_service.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'dobles_del_controlador.dart';
import 'montaje_de_pantallas.dart';

Future<ApiFalsaDelTest> _tarjeta(
  WidgetTester tester, {
  List<Object>? resultados,
  List<Object>? contenido,
  PausedSpecialtyTest? pausado,
}) async {
  final api = ApiFalsaDelTest(resultados: resultados, contenido: contenido);
  final t = prepararTest(api);
  if (pausado != null) t.service.pause(pausado);
  await montarPantalla(
    tester,
    const SingleChildScrollView(child: SpecialtyTestProfileCard()),
  );
  await tester.pump();
  return api;
}

PausedSpecialtyTest _pausado() => PausedSpecialtyTest(
  content: SpecialtyTestContent.tryParse(contenidoJson())!,
  answers: const {'q01': 'top', 'q02': 'none'},
  tiebreaks: const [],
);

ApiException _noDisponible() => ApiException(
  statusCode: 404,
  code: 'SPECIALTY_TEST_NOT_AVAILABLE',
  message: 'El test de especialidad no está disponible para tu carrera.',
);

void main() {
  // Get.put de un GetxService agenda onReady con
  // Get.engine.addPostFrameCallback, que necesita el binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(Get.reset);
  tearDown(Get.reset);

  _estados();
  _navegacion();
}

void _estados() {
  group('WIDGET · Los estados de la tarjeta del Perfil (RF-TEST-10)', () {
    testWidgets('caso 1: mientras carga, un esqueleto', (tester) async {
      final pendiente = Completer<Map<String, dynamic>>();
      await _tarjeta(tester, resultados: [pendiente]);
      expect(find.byKey(SpecialtyTestProfileCard.skeletonKey), findsOneWidget);
      pendiente.complete(<String, dynamic>{'result': null});
      await tester.pump();
      expect(find.byKey(SpecialtyTestProfileCard.skeletonKey), findsNothing);
    });

    testWidgets('caso 2: sin test, Ulises, el título, el aviso y «Hacer el '
        'test»', (tester) async {
      await _tarjeta(
        tester,
        resultados: [
          <String, dynamic>{'result': null},
        ],
      );
      expect(find.text('Test de especialidad'), findsOneWidget);
      expect(find.text('Todavía no hiciste el test.'), findsOneWidget);
      expect(find.text('Hacer el test'), findsOneWidget);
    });

    testWidgets('caso 3: con resultado, la fecha en hora de Lima, la número '
        'uno, las demás y «Rehacer el test»', (tester) async {
      await _tarjeta(tester);
      expect(find.text('Hecho el 25/09/2026'), findsOneWidget);
      expect(find.text('Desarrollo de Videojuegos'), findsOneWidget);
      expect(find.text('75 %'), findsOneWidget);
      expect(find.text('Sistemas de Información'), findsOneWidget);
      expect(find.text('24 %'), findsOneWidget);
      expect(find.text('Rehacer el test'), findsOneWidget);
      expect(find.text('El test cambió desde que lo hiciste.'), findsNothing);
      // Sin motivo, que no se guarda.
      expect(find.textContaining('sumó'), findsNothing);
    });

    testWidgets('caso 4: con empate van las dos ganadoras', (tester) async {
      await _tarjeta(tester, resultados: [ultimoResultadoJson(empate: true)]);
      expect(
        find.byKey(SpecialtyTestProfileCard.iconoKey('si')),
        findsOneWidget,
      );
      expect(
        find.byKey(SpecialtyTestProfileCard.iconoKey('vj')),
        findsOneWidget,
      );
    });

    testWidgets('caso 5: con otra versión, «El test cambió desde que lo '
        'hiciste.»', (tester) async {
      await _tarjeta(
        tester,
        resultados: [ultimoResultadoJson(isCurrentVersion: false)],
      );
      expect(find.text('El test cambió desde que lo hiciste.'), findsOneWidget);
    });

    testWidgets('caso 6: con un test a medias, «Tienes un test a medias, N de '
        'T.» y «Seguir el test», con o sin resultado', (tester) async {
      await _tarjeta(tester, pausado: _pausado());
      expect(find.text('Tienes un test a medias, 2 de 5.'), findsOneWidget);
      expect(find.text('Seguir el test'), findsOneWidget);
      expect(find.text('Desarrollo de Videojuegos'), findsOneWidget);
      Get.reset();
      await _tarjeta(
        tester,
        resultados: [
          <String, dynamic>{'result': null},
        ],
        pausado: _pausado(),
      );
      expect(find.text('Tienes un test a medias, 2 de 5.'), findsOneWidget);
      expect(find.text('Todavía no hiciste el test.'), findsNothing);
    });

    testWidgets('caso 7: con error, el aviso y «Reintentar», que vuelve a '
        'pedir', (tester) async {
      final api = await _tarjeta(
        tester,
        resultados: [http.ClientException('sin red'), ultimoResultadoJson()],
      );
      expect(find.text('No se pudo cargar tu último test.'), findsOneWidget);
      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      expect(api.getsDeResultado, 2);
      expect(find.text('Desarrollo de Videojuegos'), findsOneWidget);
    });

    testWidgets('caso 8: sin el test disponible, la tarjeta no aparece', (
      tester,
    ) async {
      await _tarjeta(tester, resultados: [_noDisponible()]);
      expect(find.text('Test de especialidad'), findsNothing);
      expect(tester.getSize(find.byType(SpecialtyTestProfileCard)).height, 0);
    });

    testWidgets('caso 9: los colores salen del contenido y, sin contenido, '
        'van neutros', (tester) async {
      await _tarjeta(tester);
      const b = Brightness.light;
      Color? icono(String clave) => tester
          .widget<Icon>(find.byKey(SpecialtyTestProfileCard.iconoKey(clave)))
          .color;
      Color? barra(String clave) => tester
          .widget<ColoredBox>(
            find.byKey(SpecialtyTestProfileCard.barraKey(clave)),
          )
          .color;
      expect(icono('vj'), const Color(0xFF76164A));
      expect(barra('si'), const Color(0xFF9333EA));
      Get.reset();
      await _tarjeta(tester, contenido: [http.ClientException('sin red')]);
      expect(find.text('Desarrollo de Videojuegos'), findsOneWidget);
      expect(icono('vj'), MaterialTheme.iconoNaranja(b));
      expect(barra('si'), MaterialTheme.testMuted(b));
    });
  });
}

void _navegacion() {
  group('WIDGET · Los botones de la tarjeta y el Perfil (RF-TEST-10)', () {
    testWidgets('caso 10: «Rehacer el test» abre el test desde el Perfil y, '
        'al volver de un test terminado, pide otra vez', (tester) async {
      final api = ApiFalsaDelTest();
      prepararTest(api);
      Object? argumentos;
      await tester.pumpWidget(
        GetMaterialApp(
          home: const Scaffold(
            body: SingleChildScrollView(child: SpecialtyTestProfileCard()),
          ),
          getPages: [
            GetPage(
              name: SpecialtyTestPage.ruta,
              page: () {
                argumentos = Get.arguments;
                return const Scaffold(body: Text('Test de prueba'));
              },
            ),
          ],
        ),
      );
      await tester.pump();
      expect(api.getsDeResultado, 1);
      await tester.tap(find.text('Rehacer el test'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(argumentos, {'origen': 'perfil'});
      // Un test terminado deja el último resultado viejo.
      await SpecialtyTestService.to.evaluate(const {});
      Get.back<void>();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(api.getsDeResultado, 2);
    });

    testWidgets('caso 11: el Perfil sin el service no monta la tarjeta ni '
        'falla', (tester) async {
      Get.put<AuthService>(AuthDelControlador(alumno()));
      Get.put<AcademicRecordService>(
        AcademicRecordService(apiClient: ApiFalsaDelTest()),
      );
      await tester.pumpWidget(const GetMaterialApp(home: ProfilePage()));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(SpecialtyTestProfileCard), findsNothing);
    });

    testWidgets('caso 12: con el service, la tarjeta va debajo de '
        '«Especialización»', (tester) async {
      prepararTest(ApiFalsaDelTest());
      Get.put<AcademicRecordService>(
        AcademicRecordService(apiClient: ApiFalsaDelTest()),
      );
      await tester.pumpWidget(const GetMaterialApp(home: ProfilePage()));
      await tester.pump();
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Test de especialidad'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      final especializacion = tester.getTopLeft(
        find.text('Especialización').first,
      );
      final tarjeta = tester.getTopLeft(find.text('Test de especialidad'));
      expect(tarjeta.dy, greaterThan(especializacion.dy));
    });
  });
}
