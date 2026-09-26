// test/HU37_jeff/asistencia_recarga_test.dart
//
// WIDGET · Recarga desde la ULima (specs/features/recarga-portal/
// recarga-portal.spec.md), RF-RCG-8, el botón y la hora de la última lectura
// en el bloque de asistencia de la ficha del curso.
// Archivos probados lib/pages/descripcion_cursos/**,
// lib/components/recarga_ulima/pie_asistencia.dart y
// lib/models/seccion_model.dart.
//
// La sección es la 301, código 801, del CURSO DE PRUEBA A, como en
// test/HU23_jeff/chat_ficha_curso_test.dart.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/recarga_ulima/hoja_recarga_ulima.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/seccion_model.dart';
import 'package:ulima_plus/pages/descripcion_cursos/descrip_cursos.dart';
import 'package:ulima_plus/pages/descripcion_cursos/descrip_cursos_controller.dart';
import 'package:ulima_plus/pages/horario/horario_controller.dart';
import 'package:ulima_plus/services/recarga_ulima_service.dart';
import 'package:ulima_plus/services/seccion_service.dart';

import 'recarga_dobles.dart';

const String _refresh = 'POST /portal-sync/refresh';
const String _leida = '2025-09-22T15:42:10.000Z';

/// El texto de la ruta `/portal-sync` de prueba.
const String _pantallaImportacion = 'PANTALLA DE IMPORTACIÓN';

Map<String, dynamic> _seccionJson({
  bool conDatos = true,
  int asistido = 12,
  Object? leidaEn = _leida,
}) => <String, dynamic>{
  'idSeccion': '301',
  'codigoSeccion': '801',
  'curso': 'CURSO DE PRUEBA A',
  'asistido': conDatos ? asistido : 0,
  'inasistencia': conDatos ? 2 : 0,
  'total': conDatos ? 30 : 0,
  'asistenciaDisponible': conDatos,
  'horasTranscurridas': conDatos ? asistido + 2 : 0,
  'asistenciaLeidaEn': leidaEn,
};

/// `SeccionService` sin red. Cada respuesta es una `Seccion`, `null` o algo
/// que se lanza, y la última se repite.
class _SeccionesFalsas extends SeccionService {
  _SeccionesFalsas(this.respuestas);

  final List<Object?> respuestas;
  int pedidas = 0;

  @override
  Future<Seccion?> findSectionById(String id) async {
    final r =
        respuestas[pedidas < respuestas.length
            ? pedidas
            : respuestas.length - 1];
    pedidas++;
    if (r is Seccion?) return r;
    throw r;
  }
}

/// La ficha con la sección fija y sin red en las pestañas. `DescripCursosPage`
/// hace `Get.put(DescripCursosController())` y GetX conserva esta instancia.
class _Ficha extends DescripCursosController {
  _Ficha(this._inicial, this.falsas) : super(seccionService: falsas);

  final Seccion _inicial;
  final _SeccionesFalsas falsas;
  int cargasDePestanas = 0;

  @override
  Future<void> cargarDatosCurso(String idSeccion) async {
    seccionActual.value = _inicial;
    secciones.value = <Seccion>[_inicial];
  }

  @override
  Future<void> fetchAnuncios(String idSeccion) async => cargasDePestanas++;

  @override
  Future<void> fetchAsesorias(String idSeccion) async => cargasDePestanas++;

  @override
  Future<void> fetchContactos(String idSeccion) async => cargasDePestanas++;
}

/// El horario sin su carga remota. Cuenta sus recargas y devuelve
/// [enrolados] en `uniqueEnrolledCourses`. Con [recargados], `reload()`
/// termina solo cuando ese `Completer` se completa y deja en [enrolados] las
/// filas que trae, como la recarga real que llega después.
class _HorarioEspia extends HorarioController {
  _HorarioEspia(this.enrolados, {this.recargados});

  List<Map<String, dynamic>> enrolados;
  final Completer<List<Map<String, dynamic>>>? recargados;
  int recargas = 0;

  @override
  // ignore: must_call_super
  void onInit() {}

  @override
  Future<void> reload() async {
    recargas++;
    final filas = recargados;
    if (filas != null) enrolados = await filas.future;
  }

  @override
  List<Map<String, dynamic>> get uniqueEnrolledCourses => enrolados;
}

Future<void> _asentar(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<_Ficha> _abrirFicha(
  WidgetTester tester, {
  Map<String, dynamic>? seccion,
  List<Object?> recargadas = const [null],
  ApiRecargaFalsa? api,
  bool conServicio = true,
  Future<void> Function(RecargaUlimaService)? antes,
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  loguear(alumna());
  if (conServicio) {
    final servicio = Get.put<RecargaUlimaService>(
      RecargaUlimaService(apiClient: api ?? ApiRecargaFalsa()),
    );
    if (antes != null) await antes(servicio);
  }
  final ficha =
      Get.put<DescripCursosController>(
            _Ficha(
              Seccion.fromJson(seccion ?? _seccionJson()),
              _SeccionesFalsas(recargadas),
            ),
          )
          as _Ficha;
  await tester.pumpWidget(
    GetMaterialApp(
      theme: const MaterialTheme(TextTheme()).light(),
      home: DescripCursosPage(idSeccion: '301'),
      getPages: [
        GetPage(
          name: '/portal-sync',
          page: () => const Scaffold(body: Text(_pantallaImportacion)),
        ),
      ],
    ),
  );
  await tester.pump();
  return ficha;
}

Finder get _enLaHoja => find.byType(HojaRecargaUlima);

/// Toca «Cargar mis datos» y comprueba que abre `/portal-sync`, no la hoja, y
/// que borra el aviso.
Future<void> _cargarMisDatosAbreLaImportacion(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(TextButton, 'Cargar mis datos'));
  await _asentar(tester);

  expect(find.text(_pantallaImportacion), findsOneWidget);
  expect(_enLaHoja, findsNothing);
  expect(RecargaUlimaService.to.ultimoAviso, isNull);
}

/// Llena la hoja y toca su «Actualizar».
Future<void> _enviarHoja(WidgetTester tester) async {
  final campos = find.descendant(
    of: _enLaHoja,
    matching: find.byType(TextField),
  );
  await tester.enterText(campos.first, 'clave-de-prueba');
  await tester.enterText(campos.last, '482913');
  await tester.pump();
  await tester.tap(
    find.descendant(of: _enLaHoja, matching: find.text('Actualizar')),
  );
  await _asentar(tester);
}

Map<String, dynamic> _resultado(String asistencia) => resultadoJson(
  view: vistaJson(
    courses: [
      cursoJson(
        sectionId: 301,
        sectionCode: '801',
        courseName: 'CURSO DE PRUEBA A',
      ),
    ],
  ),
  courses: [
    {'sectionId': 301, 'attendance': asistencia, 'grades': 'read'},
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  group('UNITARIA · Seccion.asistenciaLeidaEn (RF-RCG-8)', () {
    test('Seccion.fromJson lee asistenciaLeidaEn y tolera que falte', () {
      expect(
        Seccion.fromJson(_seccionJson()).asistenciaLeidaEn,
        DateTime.utc(2025, 9, 22, 15, 42, 10),
      );
      expect(
        Seccion.fromJson(_seccionJson(leidaEn: null)).asistenciaLeidaEn,
        isNull,
      );
      expect(
        Seccion.fromJson(
          _seccionJson()..remove('asistenciaLeidaEn'),
        ).asistenciaLeidaEn,
        isNull,
      );
      expect(
        Seccion.fromJson(
          _seccionJson(leidaEn: 'no es fecha'),
        ).asistenciaLeidaEn,
        isNull,
      );
    });
  });

  group('WIDGET · el bloque con datos (RF-RCG-8)', () {
    testWidgets('la fila nueva lleva la hora a la izquierda y «Actualizar», '
        'en el naranja de D11, a la derecha', (tester) async {
      await _abrirFicha(tester);

      final hora = find.text('Última lectura $lecturaDePrueba');
      expect(hora, findsOneWidget);
      final boton = find.widgetWithText(TextButton, 'Actualizar');
      expect(boton, findsOneWidget);
      expect(
        find.descendant(of: boton, matching: find.byIcon(Icons.sync)),
        findsOneWidget,
      );
      expect(tester.getCenter(hora).dx, lessThan(tester.getCenter(boton).dx));
      expect(tester.getSize(boton).height, greaterThanOrEqualTo(48));
      expect(
        tester.widget<TextButton>(boton).style!.foregroundColor!.resolve({}),
        MaterialTheme.textoNaranja(Brightness.light),
      );
    });

    testWidgets('con asistenciaLeidaEn en null no hay línea de hora', (
      tester,
    ) async {
      await _abrirFicha(tester, seccion: _seccionJson(leidaEn: null));

      expect(find.textContaining('Última lectura'), findsNothing);
      expect(find.widgetWithText(TextButton, 'Actualizar'), findsOneWidget);
    });

    testWidgets('un 200 llama a recargarSeccion, que pide la sección sin '
        'volver a llamar a reload(), no recarga las pestañas y conserva la '
        'elegida', (tester) async {
      final horario =
          Get.put<HorarioController>(_HorarioEspia(const [])) as _HorarioEspia;
      final api = ApiRecargaFalsa()..responder(_refresh, _resultado('updated'));
      final ficha = await _abrirFicha(
        tester,
        api: api,
        recargadas: [Seccion.fromJson(_seccionJson(asistido: 13))],
      );
      ficha.selectedTab.value = 1;
      await tester.pump();
      final pestanas = ficha.cargasDePestanas;
      expect(find.text('12 horas'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Actualizar'));
      await _asentar(tester);
      await _enviarHoja(tester);

      expect(_enLaHoja, findsNothing);
      expect(ficha.falsas.pedidas, 1);
      expect(horario.recargas, 1);
      expect(ficha.cargasDePestanas, pestanas);
      expect(ficha.selectedTab.value, 1);
      expect(find.text('13 horas'), findsOneWidget);
    });

    testWidgets('si esa petición falla, espera recargaHorario y lee '
        'uniqueEnrolledCourses', (tester) async {
      // El horario tiene la fila vieja de 12 horas y la de 14 llega solo
      // cuando termina reload(), así que leerlo sin esperar deja 12.
      final recargados = Completer<List<Map<String, dynamic>>>();
      final horario =
          Get.put<HorarioController>(
                _HorarioEspia([
                  _seccionJson(asistido: 12),
                ], recargados: recargados),
              )
              as _HorarioEspia;
      final api = ApiRecargaFalsa()..responder(_refresh, _resultado('updated'));
      final ficha = await _abrirFicha(
        tester,
        api: api,
        recargadas: [errorApi(500, 'HTTP_ERROR')],
      );

      await tester.tap(find.widgetWithText(TextButton, 'Actualizar'));
      await _asentar(tester);
      await _enviarHoja(tester);

      expect(ficha.falsas.pedidas, 1);
      expect(horario.recargas, 1);
      expect(find.text('12 horas'), findsOneWidget);

      recargados.complete([_seccionJson(asistido: 14)]);
      await _asentar(tester);

      expect(horario.recargas, 1);
      expect(find.text('14 horas'), findsOneWidget);
    });

    testWidgets('la línea de lectura parcial, con un sectionId entero y un '
        'idSeccion de texto', (tester) async {
      final api = ApiRecargaFalsa()..responder(_refresh, _resultado('failed'));
      await _abrirFicha(
        tester,
        api: api,
        antes: (s) =>
            s.recargar(password: 'clave-de-prueba', passcode: '482913'),
      );

      expect(
        find.text('No se pudo leer en esta actualización.'),
        findsOneWidget,
      );
    });

    testWidgets('el aviso compacto reemplaza a la hora y el botón pasa a la '
        'acción del aviso', (tester) async {
      final api = ApiRecargaFalsa()
        ..responder(_refresh, errorApi(409, 'IMPORT_REQUIRED'));
      await _abrirFicha(
        tester,
        api: api,
        antes: (s) =>
            s.recargar(password: 'clave-de-prueba', passcode: '482913'),
      );

      expect(find.text('No se pudo actualizar'), findsOneWidget);
      expect(find.text('Primero carga tus datos del ciclo.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.textContaining('Última lectura'), findsNothing);
      expect(
        find.widgetWithText(TextButton, 'Cargar mis datos'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextButton, 'Actualizar'), findsNothing);

      await _cargarMisDatosAbreLaImportacion(tester);
    });
  });

  group('WIDGET · el bloque sin datos (RF-RCG-8 y D3)', () {
    testWidgets('el botón dice «Actualizar desde la ULima», en el naranja de '
        'D11, y abre la hoja', (tester) async {
      await _abrirFicha(tester, seccion: _seccionJson(conDatos: false));

      expect(
        find.text('Sin datos de asistencia para este curso.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Todavía no se importaron tus horas de clase desde '
          'miUlima.',
        ),
        findsOneWidget,
      );
      expect(find.text('Actualizar desde miUlima'), findsNothing);
      final boton = find.widgetWithText(
        TextButton,
        'Actualizar desde la ULima',
      );
      expect(
        tester.widget<TextButton>(boton).style!.foregroundColor!.resolve({}),
        MaterialTheme.textoNaranja(Brightness.light),
      );

      await tester.tap(boton);
      await _asentar(tester);
      expect(_enLaHoja, findsOneWidget);
    });

    testWidgets('la línea de lectura parcial va entre la línea explicativa y '
        'el botón', (tester) async {
      final api = ApiRecargaFalsa()..responder(_refresh, _resultado('missing'));
      await _abrirFicha(
        tester,
        seccion: _seccionJson(conDatos: false),
        api: api,
        antes: (s) =>
            s.recargar(password: 'clave-de-prueba', passcode: '482913'),
      );

      final explicativa = tester.getTopLeft(
        find.text(
          'Todavía no se importaron '
          'tus horas de clase desde miUlima.',
        ),
      );
      final parcial = tester.getTopLeft(
        find.text('No se pudo leer en esta actualización.'),
      );
      final boton = tester.getTopLeft(
        find.widgetWithText(TextButton, 'Actualizar desde la ULima'),
      );
      expect(parcial.dy, greaterThan(explicativa.dy));
      expect(boton.dy, greaterThan(parcial.dy));
    });

    testWidgets('el aviso compacto va en el mismo lugar y su «Reintentar» '
        'abre la hoja', (tester) async {
      final api = ApiRecargaFalsa()
        ..responder(_refresh, errorApi(409, 'PORTAL_LOGIN_REJECTED'));
      await _abrirFicha(
        tester,
        seccion: _seccionJson(conDatos: false),
        api: api,
        antes: (s) =>
            s.recargar(password: 'clave-de-prueba', passcode: '482913'),
      );

      expect(find.text('No se pudo actualizar'), findsOneWidget);
      final boton = find.widgetWithText(TextButton, 'Reintentar');
      expect(boton, findsOneWidget);
      expect(
        tester.getTopLeft(boton).dy,
        greaterThan(tester.getTopLeft(find.text('No se pudo actualizar')).dy),
      );

      await tester.tap(boton);
      await _asentar(tester);
      expect(_enLaHoja, findsOneWidget);
    });

    testWidgets('con IMPORT_REQUIRED el botón dice «Cargar mis datos» y abre '
        '/portal-sync en lugar de la hoja', (tester) async {
      final api = ApiRecargaFalsa()
        ..responder(_refresh, errorApi(409, 'IMPORT_REQUIRED'));
      await _abrirFicha(
        tester,
        seccion: _seccionJson(conDatos: false),
        api: api,
        antes: (s) =>
            s.recargar(password: 'clave-de-prueba', passcode: '482913'),
      );

      expect(find.text('Primero carga tus datos del ciclo.'), findsOneWidget);
      expect(
        find.widgetWithText(TextButton, 'Actualizar desde la ULima'),
        findsNothing,
      );

      await _cargarMisDatosAbreLaImportacion(tester);
    });
  });

  group('WIDGET · sin RecargaUlimaService (RF-RCG-8)', () {
    testWidgets('el bloque con datos queda como hoy, sin la fila nueva', (
      tester,
    ) async {
      await _abrirFicha(tester, conServicio: false);

      expect(find.text('12 horas'), findsOneWidget);
      expect(find.textContaining('Última lectura'), findsNothing);
      expect(find.widgetWithText(TextButton, 'Actualizar'), findsNothing);
    });

    testWidgets('el botón del estado sin datos sigue abriendo /portal-sync', (
      tester,
    ) async {
      await _abrirFicha(
        tester,
        seccion: _seccionJson(conDatos: false),
        conServicio: false,
      );

      expect(find.text('Actualizar desde miUlima'), findsOneWidget);
      expect(find.text('Actualizar desde la ULima'), findsNothing);
    });
  });
}
