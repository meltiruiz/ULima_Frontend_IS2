// test/HU36_jeff/perfil_especialidad_antigua_test.dart
//
// Pruebas de widget de HU36, el test de especialidad, sobre lo oficial en el
// Perfil y el id antiguo en caché (RF-TEST-14, decisión 6).
// Pantalla: lib/pages/perfil/perfil.dart
//
// Datos inventados (datos_de_prueba.dart). El alumno de prueba es 20230001.
// El id 3 hace de especialidad antigua, porque no está en el catálogo
// oficial.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/models/malla_models.dart';
import 'package:ulima_plus/pages/perfil/perfil.dart';
import 'package:ulima_plus/services/academic_record_service.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/malla_service.dart';
import 'package:ulima_plus/services/storage_service.dart';

import 'datos_de_prueba.dart';
import 'dobles_de_red.dart';
import 'montaje_de_pantallas.dart';

const int _antigua = 3;

/// Un `AuthService` real sobre la API falsa, con la sesión puesta y los
/// catálogos cargados como en un registro recién hecho.
Future<AuthService> _sesion(
  ApiFalsaDelTest api, {
  int? principal,
  List<int>? intereses,
}) async {
  Get.put<StorageService>(AlmacenDePrueba());
  final auth = Get.put<AuthService>(AuthService(apiClient: api));
  await auth.adoptarSesion(
    token: 'token-de-prueba',
    user: alumno(principal: principal, intereses: intereses),
  );
  Get.put<MallaService>(MallaService());
  Get.put<AcademicRecordService>(
    AcademicRecordService(apiClient: ApiFalsaDelTest()),
  );
  return auth;
}

Future<void> _perfil(WidgetTester tester) async {
  await montarPantalla(tester, const ProfilePage());
  await tester.pump();
  await tester.scrollUntilVisible(
    find.text('Configuración académica'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
}

void main() {
  // Get.put de un GetxService agenda onReady con
  // Get.engine.addPostFrameCallback, que necesita el binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(cargarRoboto);
  setUp(Get.reset);
  tearDown(Get.reset);

  group('WIDGET · Solo lo oficial en «Especialización» (RF-TEST-14)', () {
    testWidgets('caso 1: un id antiguo no pinta ningún chip, vacío ni con '
        'nombre', (tester) async {
      await tester.runAsync(
        () => _sesion(
          ApiFalsaDelTest(),
          principal: _antigua,
          intereses: [kIdSi, _antigua],
        ),
      );
      await _perfil(tester);
      expect(find.text('Principal'), findsNothing);
      expect(find.text('También me interesa'), findsOneWidget);
      expect(find.text('Sistemas de Información'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is Text && w.data == ''),
        findsNothing,
      );
    });

    testWidgets('caso 2: solo con ids antiguos dice «Sin especialización '
        'seleccionada» en textSecondary', (tester) async {
      await tester.runAsync(
        () => _sesion(
          ApiFalsaDelTest(),
          principal: _antigua,
          intereses: [_antigua],
        ),
      );
      await _perfil(tester);
      expect(find.text('Sin especialización seleccionada'), findsOneWidget);
      expect(
        colorDeTexto(tester, 'Sin especialización seleccionada'),
        MaterialTheme.textSecondary(Brightness.light),
      );
    });

    testWidgets('caso 3: con el catálogo fallido, el aviso y «Reintentar», y '
        '«Editar» no abre la hoja', (tester) async {
      final api = ApiFalsaDelTest(
        especialidades: [
          http.ClientException('sin red'),
          http.ClientException('sin red'),
          especialidadesJson(),
        ],
      );
      await tester.runAsync(() => _sesion(api, intereses: [kIdSi]));
      await _perfil(tester);
      expect(
        find.text('No se pudieron cargar tus especialidades.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Editar'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Guardar'), findsNothing);
      await tester.runAsync(() async {
        await tester.tap(find.text('Reintentar'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      await tester.pump();
      expect(
        find.text('No se pudieron cargar tus especialidades.'),
        findsNothing,
      );
      expect(find.text('Sistemas de Información'), findsOneWidget);
    });

    testWidgets('caso 4: la hoja de «Editar» arranca con la selección oficial '
        'y su PUT no lleva el id antiguo', (tester) async {
      final api = ApiFalsaDelTest();
      await tester.runAsync(
        () => _sesion(api, principal: _antigua, intereses: [kIdTi, _antigua]),
      );
      await _perfil(tester);
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('Guardar'));
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      await tester.pumpAndSettle();
      expect(api.cuerposDeGuardado.single, {
        'primarySpecialtyId': null,
        'interestSpecialtyIds': [kIdTi],
      });
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('caso 5: getEspecialidadName y la malla no cambian: un id '
        'antiguo da un nombre vacío y sus electivos no aparecen', (
      tester,
    ) async {
      final auth = (await tester.runAsync(() => _sesion(ApiFalsaDelTest())))!;
      expect(auth.getEspecialidadName(_antigua), '');
      expect(auth.getEspecialidadName(kIdSw), 'Ingeniería de Software');
      final electivo = CourseNode(
        id: 'curso-prueba-a',
        code: 'E-PRUEBA-A',
        name: 'CURSO DE PRUEBA A',
        credits: 3,
        level: 8,
        prerequisites: const [],
        category: CourseCategory.elective,
        row: 0,
        specialties: const ['Ingeniería de Software'],
      );
      final malla = MallaService.to;
      expect(
        malla.electiveMatchesUserSpecialties(electivo, [_antigua]),
        isFalse,
      );
      expect(malla.electiveMatchesUserSpecialties(electivo, [kIdSw]), isTrue);
    });
  });
}
