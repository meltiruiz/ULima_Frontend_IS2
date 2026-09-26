// test/HU37_jeff/mis_notas_ulima_test.dart
//
// WIDGET · Recarga desde la ULima (specs/features/recarga-portal/
// recarga-portal.spec.md), RF-RCG-4 y RF-RCG-6, la pantalla «Notas
// oficiales» (/mis-notas) con las notas de la ULima, la franja y el aviso.
// Archivos probados lib/pages/mis_notas/**, lib/components/recarga_ulima/
// franja_recarga.dart y lib/components/recarga_ulima/aviso_recarga.dart.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/recarga_ulima/hoja_recarga_ulima.dart';
import 'package:ulima_plus/components/skeleton.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/pages/mis_notas/mis_notas_controller.dart';
import 'package:ulima_plus/pages/mis_notas/mis_notas_page.dart';
import 'package:ulima_plus/services/evaluations_service.dart';
import 'package:ulima_plus/services/recarga_ulima_service.dart';

import 'recarga_dobles.dart';

const String _vistaGet = 'GET /grades/me/ulima';
const String _cursosGet = 'GET /grades/me/courses';
const String _refresh = 'POST /portal-sync/refresh';

/// El sílabo de la sección 81, con la sigla EV01 para la evaluación 5011.
Map<String, dynamic> _silaboJson() => <String, dynamic>{
  'cursos': <dynamic>[],
  'syllabi': [
    {
      'cursoId': '81',
      'cursoNombre': 'TALLER DE PROTOTIPADO',
      'evaluaciones': [
        {
          'id': '5011',
          'nombre': 'Examen escrito',
          'sigla': 'EV01',
          'peso': 15,
          'tipo': 'continua',
        },
        {
          'id': '5013',
          'nombre': 'Exposición',
          'sigla': 'EX01',
          'peso': 20,
          'tipo': 'continua',
        },
      ],
    },
  ],
};

/// Lo que devuelve `/portal-sync` en cada visita de la prueba.
Object? _salidaPortal = true;

Future<ApiRecargaFalsa> _abrir(
  WidgetTester tester, {
  ApiRecargaFalsa? api,
  Future<void> Function(RecargaUlimaService)? antes,
  bool silaboFalla = false,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  loguear(alumna());
  final falsa = api ?? (ApiRecargaFalsa()..responder(_vistaGet, vistaJson()));
  falsa.responder(
    _cursosGet,
    silaboFalla ? errorApi(500, 'HTTP_ERROR') : _silaboJson(),
  );
  final servicio = Get.put<RecargaUlimaService>(
    RecargaUlimaService(apiClient: falsa),
  );
  if (antes != null) await antes(servicio);
  await tester.pumpWidget(
    GetMaterialApp(
      theme: const MaterialTheme(TextTheme()).light(),
      initialRoute: '/mis-notas',
      getPages: [
        GetPage(
          name: '/mis-notas',
          page: () => const MisNotasPage(),
          binding: BindingsBuilder(() {
            Get.put(
              MisNotasController(
                silabo: EvaluationSyllabusService(apiClient: falsa),
              ),
            );
          }),
        ),
        GetPage(
          name: '/portal-sync',
          page: () => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Get.back<Object?>(result: _salidaPortal),
                child: const Text('VOLVER DEL PORTAL'),
              ),
            ),
          ),
        ),
      ],
    ),
  );
  await tester.pump();
  await tester.pump();
  return falsa;
}

/// Deja correr las animaciones sin esperar a un cursor o a un indicador.
Future<void> _asentar(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Map<String, dynamic> _conNotas() => vistaJson(
  courses: [
    cursoJson(
      assessments: [
        evaluacionJson(),
        evaluacionJson(
          key: '07.15',
          name: 'Exposición',
          week: 10,
          weight: 20,
          value: null,
          mark: 'np',
          assessmentId: 5013,
        ),
        evaluacionJson(
          key: '07.20',
          name: 'Trabajo final',
          week: null,
          weight: 12.5,
          value: null,
          mark: 'pending',
          assessmentId: null,
          match: 'none',
        ),
      ],
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.reset();
    _salidaPortal = true;
  });
  tearDown(Get.reset);

  group('WIDGET · estados de /mis-notas (RF-RCG-6)', () {
    testWidgets('primera carga, el esqueleto de hoy y sin franja', (
      tester,
    ) async {
      final pendiente = Completer<Map<String, dynamic>>();
      await _abrir(
        tester,
        api: ApiRecargaFalsa()..responder(_vistaGet, pendiente),
      );

      expect(find.byType(SkeletonCardList), findsOneWidget);
      expect(
        tester.widget<SkeletonCardList>(find.byType(SkeletonCardList)).count,
        4,
      );
      expect(
        find.text('Aún no tienes cursos con notas oficiales.'),
        findsNothing,
      );
      expect(find.text('Actualizar desde la ULima'), findsNothing);
      expect(find.text('Notas oficiales'), findsOneWidget);

      pendiente.complete(vistaJson());
      await tester.pump();
      expect(find.byType(SkeletonCardList), findsNothing);
      expect(find.text('Actualizar desde la ULima'), findsOneWidget);
    });

    testWidgets(
      'error de carga sin datos, el vacío con wifi_off y sin franja',
      (tester) async {
        await _abrir(
          tester,
          api: ApiRecargaFalsa()
            ..responder(_vistaGet, errorApi(500, 'HTTP_ERROR')),
        );

        expect(find.byIcon(Icons.wifi_off), findsOneWidget);
        expect(
          find.text('No se pudieron cargar tus notas oficiales.'),
          findsOneWidget,
        );
        expect(find.text('Actualizar desde la ULima'), findsNothing);
      },
    );

    testWidgets('sin cursos, el vacío de hoy y sin franja', (tester) async {
      await _abrir(
        tester,
        api: ApiRecargaFalsa()
          ..responder(_vistaGet, vistaJson(lastReadAt: null, courses: [])),
      );

      expect(find.byIcon(Icons.school_outlined), findsOneWidget);
      expect(
        find.text('Aún no tienes cursos con notas oficiales.'),
        findsOneWidget,
      );
      expect(find.text('Actualizar desde la ULima'), findsNothing);
    });

    testWidgets('antes de la primera lectura, la franja y las tarjetas dicen '
        '«Aún no se actualizan desde la ULima» y no tienen filas', (
      tester,
    ) async {
      await _abrir(
        tester,
        api: ApiRecargaFalsa()
          ..responder(
            _vistaGet,
            vistaJson(
              lastReadAt: null,
              courses: [cursoJson(lastReadAt: null, assessments: [])],
            ),
          ),
      );

      expect(find.text('Actualizar desde la ULima'), findsOneWidget);
      expect(
        find.text('Aún no se actualizan desde la ULima'),
        findsNWidgets(2),
      );
      expect(find.text('Sección 812'), findsOneWidget);
      expect(find.text('Sin nota'), findsNothing);
      expect(find.text('Final'), findsNothing);
    });

    testWidgets('sin notas publicadas, la franja con la hora y las filas con '
        '«Sin nota», sin «Final»', (tester) async {
      await _abrir(
        tester,
        api: ApiRecargaFalsa()
          ..responder(
            _vistaGet,
            vistaJson(
              courses: [
                cursoJson(
                  assessments: [evaluacionJson(value: null, mark: 'pending')],
                ),
              ],
            ),
          ),
      );

      expect(find.text('Última lectura $lecturaDePrueba'), findsOneWidget);
      expect(find.text('Sin nota'), findsOneWidget);
      expect(find.text('Final'), findsNothing);
    });

    testWidgets('con notas, una graded, una np con NP, una pending sin semana '
        'y la insignia «Final»', (tester) async {
      await _abrir(
        tester,
        api: ApiRecargaFalsa()..responder(_vistaGet, _conNotas()),
      );

      expect(find.text('EV01 · Examen escrito 1'), findsOneWidget);
      expect(find.text('Semana 3'), findsOneWidget);
      expect(find.text('15%'), findsOneWidget);
      expect(find.text('14.5'), findsOneWidget);
      expect(find.text('EX01 · Exposición'), findsOneWidget);
      expect(find.text('Semana 10'), findsOneWidget);
      // La fila sin semana no lleva la línea «Semana».
      expect(find.textContaining('Semana'), findsNWidgets(2));
      expect(find.text('NP'), findsOneWidget);
      // Sin pareja va sin sigla, sin semana, y se muestra igual (B7).
      expect(find.text('Trabajo final'), findsOneWidget);
      expect(find.text('12.5%'), findsOneWidget);
      expect(find.text('Sin nota'), findsOneWidget);
      // 14.5 · 15 / 100, con NP y la pendiente en 0.
      expect(find.text('Final'), findsOneWidget);
      expect(find.text('2.17'), findsOneWidget);
    });

    // La 5013 está en el sílabo con la sigla EX01, así que solo la pareja
    // decide si la fila la lleva.
    for (final match in <String>['none', 'pareja_desconocida']) {
      testWidgets('la sigla solo con pareja, y la 5013 del sílabo con match '
          '«$match» se ve sin EX01 (D9 y B7)', (tester) async {
        await _abrir(
          tester,
          api: ApiRecargaFalsa()
            ..responder(
              _vistaGet,
              vistaJson(
                courses: [
                  cursoJson(
                    assessments: [
                      evaluacionJson(),
                      evaluacionJson(
                        key: '07.15',
                        name: 'Exposición',
                        week: 10,
                        weight: 20,
                        value: null,
                        mark: 'pending',
                        assessmentId: 5013,
                        match: match,
                      ),
                    ],
                  ),
                ],
              ),
            ),
        );

        expect(find.text('EV01 · Examen escrito 1'), findsOneWidget);
        expect(find.text('Exposición'), findsOneWidget);
        expect(find.textContaining('EX01'), findsNothing);
      });
    }

    testWidgets('la nota de la fila sigue D10, 14.25 con dos decimales y 15 '
        'con uno', (tester) async {
      await _abrir(
        tester,
        api: ApiRecargaFalsa()
          ..responder(
            _vistaGet,
            vistaJson(
              courses: [
                cursoJson(
                  assessments: [
                    evaluacionJson(value: 14.25),
                    evaluacionJson(
                      key: '07.15',
                      name: 'Exposición',
                      week: 10,
                      weight: 20,
                      value: 15,
                      assessmentId: 5013,
                    ),
                  ],
                ),
              ],
            ),
          ),
      );

      expect(find.text('14.25'), findsOneWidget);
      expect(find.text('14.3'), findsNothing);
      expect(find.text('15.0'), findsOneWidget);
    });

    testWidgets('ninguna sigla si el sílabo no carga', (tester) async {
      await _abrir(
        tester,
        api: ApiRecargaFalsa()..responder(_vistaGet, _conNotas()),
        silaboFalla: true,
      );

      expect(find.text('Examen escrito 1'), findsOneWidget);
      expect(find.text('Exposición'), findsOneWidget);
      expect(find.textContaining('EV01'), findsNothing);
    });

    testWidgets('la insignia «Final» aprueba con 10.5 y desaprueba con 10.4', (
      tester,
    ) async {
      await _abrir(
        tester,
        api: ApiRecargaFalsa()
          ..responder(
            _vistaGet,
            vistaJson(
              courses: [
                cursoJson(
                  assessments: [evaluacionJson(weight: 100, value: 10.5)],
                ),
                cursoJson(
                  sectionId: 82,
                  sectionCode: '813',
                  courseName: 'CURSO DE PRUEBA B',
                  assessments: [evaluacionJson(weight: 100, value: 10.4)],
                ),
              ],
            ),
          ),
      );

      Color colorDe(String texto) =>
          tester.widget<Text>(find.text(texto)).style!.color!;
      expect(colorDe('10.50'), const Color(0xFF16A34A));
      expect(colorDe('10.40'), const Color(0xFFDC2626));
    });

    testWidgets('la insignia «Final» sale también con un solo NP, en 0.00 '
        '(B8)', (tester) async {
      await _abrir(
        tester,
        api: ApiRecargaFalsa()
          ..responder(
            _vistaGet,
            vistaJson(
              courses: [
                cursoJson(
                  assessments: [evaluacionJson(value: null, mark: 'np')],
                ),
              ],
            ),
          ),
      );

      expect(find.text('NP'), findsOneWidget);
      expect(find.text('Final'), findsOneWidget);
      expect(find.text('0.00'), findsOneWidget);
    });

    for (final (lectura, etiqueta) in <(Object?, String)>[
      (
        '2025-09-22T15:42:10.000Z',
        'Actualizar desde la ULima. Última lectura $lecturaDePrueba',
      ),
      (null, 'Actualizar desde la ULima. Aún no se actualizan desde la ULima'),
    ]) {
      testWidgets('la franja lleva un Semantics de botón con su etiqueta, '
          '${lectura == null ? 'sin' : 'con'} lectura', (tester) async {
        final semantica = tester.ensureSemantics();
        await _abrir(
          tester,
          api: ApiRecargaFalsa()
            ..responder(_vistaGet, vistaJson(lastReadAt: lectura)),
        );

        final franja = find.bySemanticsLabel(etiqueta);
        expect(franja, findsWidgets);
        expect(
          tester.getSemantics(franja.first),
          isSemantics(isButton: true, hasTapAction: true, label: etiqueta),
        );
        semantica.dispose();
      });
    }

    testWidgets('la franja abre la hoja de recarga', (tester) async {
      await _abrir(tester);

      await tester.tap(find.text('Actualizar desde la ULima'));
      await _asentar(tester);

      expect(find.byType(HojaRecargaUlima), findsOneWidget);
    });

    testWidgets('la flecha del AppBar llama solo a GET /grades/me/ulima y, sin '
        'conexión, conserva la vista', (tester) async {
      final api = ApiRecargaFalsa()
        ..responder(_vistaGet, vistaJson())
        ..responder(_vistaGet, errorApi(500, 'HTTP_ERROR'));
      await _abrir(tester, api: api);
      final antes = List<String>.of(api.llamadas);

      await tester.tap(find.byTooltip('Actualizar notas'));
      await tester.pump();
      await tester.pump();

      expect(api.llamadas.sublist(antes.length), [_vistaGet]);
      expect(api.veces(_refresh), 0);
      expect(find.text('TALLER DE PROTOTIPADO'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsNothing);
    });
  });

  group('WIDGET · lectura parcial y aviso rojo (RF-RCG-3 y RF-RCG-4)', () {
    testWidgets('una tarjeta sin lectura en el último resultado lleva «No se '
        'pudo leer en esta actualización.», también si nunca se leyó', (
      tester,
    ) async {
      final api = ApiRecargaFalsa()
        ..responder(
          _refresh,
          resultadoJson(
            view: vistaJson(
              courses: [
                cursoJson(),
                cursoJson(
                  sectionId: 82,
                  sectionCode: '813',
                  courseName: 'CURSO DE PRUEBA B',
                  lastReadAt: null,
                  assessments: [],
                ),
              ],
            ),
            courses: [
              {'sectionId': 81, 'attendance': 'updated', 'grades': 'read'},
              {'sectionId': 82, 'attendance': 'failed', 'grades': 'failed'},
            ],
          ),
        )
        ..responder(_vistaGet, errorApi(500, 'HTTP_ERROR'));
      await _abrir(
        tester,
        api: api,
        antes: (s) =>
            s.recargar(password: 'clave-de-prueba', passcode: '482913'),
      );

      expect(
        find.text('No se pudo leer en esta actualización.'),
        findsOneWidget,
      );
      // La franja sí lleva «Aún no…» solo si la vista no tiene hora; aquí
      // la tiene, así que no queda ningún «Aún no se actualizan».
      expect(find.text('Aún no se actualizan desde la ULima'), findsNothing);
    });

    testWidgets('el aviso de rechazo reemplaza a la franja, con la línea de la '
        'última lectura, «Reintentar» y la vista anterior debajo', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      final api = ApiRecargaFalsa()
        ..responder(_vistaGet, vistaJson())
        ..responder(_refresh, errorApi(409, 'PORTAL_LOGIN_REJECTED'));
      await _abrir(
        tester,
        api: api,
        antes: (s) async {
          await s.cargar();
          await s.recargar(password: 'clave-de-prueba', passcode: '482913');
        },
      );

      expect(find.text('Actualizar desde la ULima'), findsNothing);
      expect(find.text('No se pudo actualizar'), findsOneWidget);
      expect(
        find.text(
          'miUlima rechazó los datos. Revisa tu contraseña y que el '
          'código del autenticador siga vigente.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Se muestran las notas leídas $lecturaDePrueba.'),
        findsOneWidget,
      );
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text('TALLER DE PROTOTIPADO'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('No se pudo actualizar')),
        isSemantics(isLiveRegion: true),
      );
      semantica.dispose();
    });

    testWidgets('el de 403 lleva «Reintentar», que abre la hoja vacía', (
      tester,
    ) async {
      final api = ApiRecargaFalsa()
        ..responder(_vistaGet, vistaJson())
        ..responder(_refresh, errorApi(403, 'PORTAL_IDENTITY_MISMATCH'));
      await _abrir(
        tester,
        api: api,
        antes: (s) async {
          await s.cargar();
          await s.recargar(password: 'clave-de-prueba', passcode: '482913');
        },
      );

      expect(
        find.text(
          'La cuenta de miUlima no corresponde a tu usuario de '
          'ULima++.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Reintentar'));
      await _asentar(tester);

      expect(find.byType(HojaRecargaUlima), findsOneWidget);
      final contrasena = tester.widget<TextField>(
        find
            .descendant(
              of: find.byType(HojaRecargaUlima),
              matching: find.byType(TextField),
            )
            .first,
      );
      expect(contrasena.controller!.text, isEmpty);
      // El aviso sigue a la vista mientras la hoja está abierta.
      expect(find.text('No se pudo actualizar'), findsOneWidget);
    });

    for (final (salida, recarga) in <(Object?, bool)>[
      (true, true),
      (false, false),
      (null, false),
    ]) {
      testWidgets('el de IMPORT_REQUIRED lleva «Cargar mis datos», que borra '
          'el aviso, abre /portal-sync y, si vuelve $salida, '
          '${recarga ? 'sí' : 'no'} pide la vista', (tester) async {
        _salidaPortal = salida;
        final api = ApiRecargaFalsa()
          ..responder(_vistaGet, vistaJson())
          ..responder(_refresh, errorApi(409, 'IMPORT_REQUIRED'));
        await _abrir(
          tester,
          api: api,
          antes: (s) async {
            await s.cargar();
            await s.recargar(password: 'clave-de-prueba', passcode: '482913');
          },
        );
        expect(find.text('Primero carga tus datos del ciclo.'), findsOneWidget);
        final vistasAntes = api.veces(_vistaGet);

        await tester.tap(find.text('Cargar mis datos'));
        await _asentar(tester);
        expect(find.text('VOLVER DEL PORTAL'), findsOneWidget);
        expect(RecargaUlimaService.to.ultimoAviso, isNull);

        await tester.tap(find.text('VOLVER DEL PORTAL'));
        await _asentar(tester);

        expect(api.veces(_vistaGet), vistasAntes + (recarga ? 1 : 0));
        expect(find.text('Actualizar desde la ULima'), findsOneWidget);
      });
    }
  });
}
