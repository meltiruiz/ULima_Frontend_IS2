// test/splash/splash_arranque_test.dart
//
// UNITARIA + WIDGET · Splash animado (specs/features/splash/splash.spec.md).
// RF-SPL-4 fija que la intro navega sin transición, con el page y el binding
// de la GetPage de su destino y su argumento de ruta, que llega a la
// bienvenida siempre por offAllToLogin y que un 401 durante la carga no
// navega mientras la ruta es /arranque. Las Tareas 12 a 14 suman la capa, la
// intro completa y la carga.
// Archivos probados lib/services/session_navigation.dart y, desde la Tarea
// 12, lib/pages/splash/capa_de_arranque.dart.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ulima_plus/components/logo/escena_del_logo.dart';
import 'package:ulima_plus/main.dart';
import 'package:ulima_plus/pages/splash/arranque_page.dart';
import 'package:ulima_plus/pages/splash/capa_de_arranque.dart';
import 'package:ulima_plus/pages/splash/carga_del_arranque.dart';
import 'package:ulima_plus/pages/splash/estado_de_la_capa.dart';
import 'package:ulima_plus/pages/splash/variantes/variantes.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/recarga_ulima_service.dart';
import 'package:ulima_plus/services/session_navigation.dart';
import 'package:ulima_plus/services/specialty_test_service.dart';
import 'package:ulima_plus/services/splash_variante_service.dart';
import 'package:ulima_plus/services/storage_service.dart';

import 'apoyo_splash.dart';

/// Un almacén que cuenta los cierres de sesión, con un token guardado.
class _AlmacenEspia extends StorageService {
  int cierres = 0;

  @override
  Future<void> clearSession() async => cierres++;

  @override
  Future<String?> get savedToken async => 'token-guardado';
}

/// Un binding que deja constancia de que corrió.
class _BindingMarcado extends Bindings {
  static int veces = 0;

  @override
  void dependencies() => veces++;
}

Widget _pagina(String texto) => Scaffold(body: Center(child: Text(texto)));

Widget _app({String initialRoute = rutaDelArranque}) => GetMaterialApp(
  initialRoute: initialRoute,
  getPages: [
    GetPage(name: rutaDelArranque, page: () => _pagina('arranque')),
    GetPage(
      name: '/home',
      page: () => _pagina('home'),
      binding: _BindingMarcado(),
    ),
    GetPage(name: '/login', page: () => _pagina('login')),
    GetPage(name: '/perfil', page: () => _pagina('perfil')),
  ],
);

/// La ruta de la página que muestra [texto].
Route<dynamic> _rutaDe(WidgetTester tester, String texto) =>
    ModalRoute.of(tester.element(find.text(texto)))!;

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
    _BindingMarcado.veces = 0;
  });
  tearDown(Get.reset);

  group('la navegación de la intro (RF-SPL-4)', () {
    testWidgets('offAllSinTransicion usa el page y el binding de la GetPage, '
        'sin transición, opaca y con el argumento', (tester) async {
      await tester.pumpWidget(_app());
      await tester.pump();
      final navego = offAllSinTransicion(
        '/home',
        arguments: const {'pestana': 'horario'},
      );
      expect(navego, isTrue);
      await tester.pump();
      expect(find.text('home'), findsOneWidget);
      expect(find.text('arranque'), findsNothing);
      expect(Get.currentRoute, '/home');
      expect(_BindingMarcado.veces, 1);
      final ruta = _rutaDe(tester, 'home');
      expect(ruta, isA<GetPageRoute<dynamic>>());
      expect(
        (ruta as GetPageRoute<dynamic>).transition,
        Transition.noTransition,
      );
      expect(ruta.opaque, isTrue);
      expect(ruta.settings.arguments, const {'pestana': 'horario'});
    });

    testWidgets('en /arranque, offAllToLogin no navega salvo desde la intro', (
      tester,
    ) async {
      await tester.pumpWidget(_app());
      await tester.pump();
      expect(offAllToLogin(), isFalse);
      await tester.pump();
      expect(Get.currentRoute, rutaDelArranque);
      expect(find.text('arranque'), findsOneWidget);
    });

    testWidgets('desde la intro llega a /login sin transición y con la pose', (
      tester,
    ) async {
      await tester.pumpWidget(_app());
      await tester.pump();
      final pose = EscenaDelLogo.reposo(
        centro: const Offset(144, 320),
        radio: 90,
      ).pose;
      expect(offAllToLogin(pose: pose, desdeLaIntro: true), isTrue);
      await tester.pump();
      expect(Get.currentRoute, '/login');
      final ruta = _rutaDe(tester, 'login') as GetPageRoute<dynamic>;
      expect(ruta.transition, Transition.noTransition);
      expect((ruta.settings.arguments! as Map)[argumentoDePose], same(pose));
      // Ya en /login, una segunda llamada no navega.
      expect(offAllToLogin(desdeLaIntro: true), isFalse);
    });

    testWidgets('fuera de /arranque, offAllToLogin sigue igual que hoy, con su '
        'transición y sin argumentos', (tester) async {
      await tester.pumpWidget(_app(initialRoute: '/perfil'));
      await tester.pump();
      expect(offAllToLogin(), isTrue);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(Get.currentRoute, '/login');
      final ruta = _rutaDe(tester, 'login') as GetPageRoute<dynamic>;
      expect(ruta.transition, isNot(Transition.noTransition));
      expect(ruta.settings.arguments, isNull);
    });
  });

  group('la capa (RF-SPL-4 y RF-SPL-6)', () {
    setUp(reiniciarArranque);
    tearDown(reiniciarArranque);

    testWidgets('sin intro está inactiva, no tapa la pantalla y deja pasar '
        'los toques', (tester) async {
      telefono(tester);
      await tester.pumpWidget(appConCapa());
      await tester.pump();
      expect(CapaDeArranque.fase, FaseDeLaCapa.inactiva);
      expect(EstadoDeLaCapa.cubre.value, isFalse);
      await tester.tap(find.text('bienvenida'));
      expect(toquesEnLaPagina, 1);
    });

    testWidgets('con intro tapa la pantalla, bloquea los toques y la barra de '
        'estado usa íconos claros', (tester) async {
      telefono(tester);
      await tester.pumpWidget(
        appConCapa(
          intro: IntroDelArranque(
            carga: CargaFalsa().call,
            variantes: VariantesFijas(VarianteSplash.ensamble),
            random: Random(1),
          ),
        ),
      );
      await tester.pump();
      expect(EstadoDeLaCapa.cubre.value, isTrue);
      expect(CapaDeArranque.fase, isNot(FaseDeLaCapa.inactiva));
      final bloqueo = tester.widget<AbsorbPointer>(
        find
            .descendant(
              of: find.byType(CapaDeArranque),
              matching: find.byType(AbsorbPointer),
            )
            .first,
      );
      expect(bloqueo.absorbing, isTrue);
      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find
            .descendant(
              of: find.byType(CapaDeArranque),
              matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
            )
            .first,
      );
      expect(region.value.statusBarIconBrightness, Brightness.light);
    });

    testWidgets('la estrella queda quieta hasta que la variante está elegida y '
        'el tiempo de la intro corre desde ahí', (tester) async {
      telefono(tester);
      final variantes = VariantesFijas(
        VarianteSplash.ensamble,
        enseguida: false,
      );
      await tester.pumpWidget(
        appConCapa(
          intro: IntroDelArranque(
            carga: CargaFalsa().call,
            variantes: variantes,
            random: Random(1),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(CapaDeArranque.fase, FaseDeLaCapa.eligiendo);
      final quieta = CapaDeArranque.escenaActual!;
      expect(quieta.rombos.every((r) => r.desplazamiento == 0), isTrue);
      expect(quieta.cruces, isEmpty);

      variantes.elegirYa();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(CapaDeArranque.fase, FaseDeLaCapa.intro);
      // A unos 200 ms de la elección, los rombos de Ensamble se están
      // abriendo.
      expect(
        CapaDeArranque.escenaActual!.rombos[3].desplazamiento,
        greaterThan(100),
      );
    });

    testWidgets('si la capa sale del árbol activa, deja de cubrir la pantalla '
        'y no deja a /home esperando sus orientaciones', (tester) async {
      telefono(tester);
      await tester.pumpWidget(
        appConCapa(
          intro: IntroDelArranque(
            carga: CargaFalsa().call,
            variantes: VariantesFijas(VarianteSplash.ensamble),
            random: Random(1),
          ),
        ),
      );
      await tester.pump();
      expect(EstadoDeLaCapa.cubre.value, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(EstadoDeLaCapa.cubre.value, isFalse);
      expect(CapaDeArranque.fase, FaseDeLaCapa.inactiva);
    });

    testWidgets('la carga corre en paralelo desde el montaje', (tester) async {
      telefono(tester);
      final carga = CargaFalsa();
      await tester.pumpWidget(
        appConCapa(
          intro: IntroDelArranque(
            carga: carga.call,
            variantes: VariantesFijas(VarianteSplash.codigo, enseguida: false),
            random: Random(1),
          ),
        ),
      );
      expect(carga.llamadas, 1);
    });
  });

  group(
    'el final de la intro (RF-SPL-4, RF-SPL-10, RF-SPL-17 y RF-SPL-18)',
    () {
      final hapticas = <String>[];

      setUp(() {
        reiniciarArranque();
        hapticas.clear();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (llamada) async {
              if (llamada.method.startsWith('HapticFeedback')) {
                hapticas.add(llamada.method);
              }
              return null;
            });
      });

      tearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
        reiniciarArranque();
      });

      Future<CargaFalsa> montar(
        WidgetTester tester,
        VarianteSplash variante, {
        WidgetBuilder? home,
        List<NavigatorObserver> observadores = const [],
      }) async {
        telefono(tester);
        final carga = CargaFalsa();
        await tester.pumpWidget(
          appConCapa(
            intro: IntroDelArranque(
              carga: carga.call,
              variantes: VariantesFijas(variante),
              random: Random(1),
            ),
            home: home ?? (_) => const HomeDePrueba(),
            observadores: observadores,
          ),
        );
        return carga;
      }

      for (final tipo in VarianteSplash.values) {
        testWidgets('${tipo.name}: con la carga lista antes, la entrada se ve '
            'completa y la salida deja /home en Horario en 1,8 s o menos', (
          tester,
        ) async {
          final carga = await montar(tester, tipo);
          carga.terminar('/home');
          final v = varianteDe(tipo);
          final hasta = await avanzarHasta(
            tester,
            () => CapaDeArranque.fase == FaseDeLaCapa.inactiva,
          );
          expect(Get.currentRoute, '/home');
          expect(
            ModalRoute.of(
              tester.element(find.text('home')),
            )!.settings.arguments,
            const {'pestana': 'horario'},
          );
          expect(
            hasta,
            greaterThanOrEqualTo(v.finDeLaEntrada + v.duracionDeLaSalida),
          );
          // Más el primer cuadro de /home y su medida (RF-SPL-17).
          expect(hasta, lessThanOrEqualTo(1780 + 64));
          expect(EstadoDeLaCapa.cubre.value, isFalse);
          expect(hapticas, isEmpty, reason: 'sin háptica (S-14)');
        });
      }

      testWidgets('con la carga más larga, Incremento repite sus tics y la '
          'salida empieza al terminar la carga', (tester) async {
        final carga = await montar(tester, VarianteSplash.incremento);
        await avanzar(tester, 2100);
        expect(CapaDeArranque.fase, FaseDeLaCapa.intro);
        expect(CapaDeArranque.escenaActual!.giro, greaterThan(80 * grado));
        carga.terminar('/home');
        await avanzar(tester, 64);
        expect(
          CapaDeArranque.fase,
          anyOf(FaseDeLaCapa.esperandoCabecera, FaseDeLaCapa.salida),
        );
        await avanzar(tester, 700);
        expect(CapaDeArranque.fase, FaseDeLaCapa.inactiva);
      });

      testWidgets(
        'un 401 durante la carga no navega ni avisa, y la intro llega '
        'una sola vez a la bienvenida (S-20)',
        (tester) async {
          final rutas = ObservadorDeRutas();
          final almacen = _AlmacenEspia();
          Get.put<StorageService>(almacen);
          final servidor = MockClient(
            (_) async => http.Response(
              jsonEncode({
                'error': {'code': 'UNAUTHORIZED', 'message': 'Token inválido'},
              }),
              401,
              headers: {'content-type': 'application/json'},
            ),
          );
          int? loginsTrasEl401;
          telefono(tester);
          await tester.pumpWidget(
            appConCapa(
              intro: IntroDelArranque(
                carga: () async {
                  await Future<void>.delayed(const Duration(milliseconds: 100));
                  // Un 401 de GET /auth/me pasa por el interceptor real de
                  // ApiClient, con /arranque como ruta actual.
                  try {
                    await http.runWithClient(
                      () => ApiClient(
                        configuredBaseUrl: 'http://test',
                      ).getJson('/auth/me'),
                      () => servidor,
                    );
                  } catch (_) {}
                  loginsTrasEl401 = rutas.nombres
                      .where((n) => n == '/login')
                      .length;
                  return '/login';
                },
                variantes: VariantesFijas(VarianteSplash.ensamble),
                random: Random(1),
              ),
              observadores: [rutas],
            ),
          );
          await avanzarHasta(
            tester,
            () => CapaDeArranque.fase == FaseDeLaCapa.inactiva,
          );
          // El interceptor borra la sesión, no navega ni avisa.
          expect(almacen.cierres, 1);
          expect(loginsTrasEl401, 0);
          // La intro navega una sola vez a la bienvenida.
          expect(rutas.nombres.where((n) => n == '/login'), hasLength(1));
          expect(find.byType(GetSnackBar), findsNothing);
          expect(Get.isSnackbarOpen, isFalse);
        },
      );

      testWidgets(
        'un fallo antes de registrar los servicios deja la intro en su '
        'bucle y lo registra (RF-SPL-18)',
        (tester) async {
          final registro = <String>[];
          final anterior = debugPrint;
          debugPrint = (String? m, {int? wrapWidth}) => registro.add(m ?? '');
          // Flutter exige devolver debugPrint antes de terminar la prueba.
          try {
            final carga = await montar(tester, VarianteSplash.ensamble);
            carga.fallar(const FalloAntesDeLosServicios('sin Firebase'));
            await avanzar(tester, 5000);
          } finally {
            debugPrint = anterior;
          }
          expect(CapaDeArranque.fase, FaseDeLaCapa.intro);
          expect(EstadoDeLaCapa.cubre.value, isTrue);
          expect(registro.join(), contains('sin Firebase'));
        },
      );

      testWidgets('un fallo después de registrarlos hace el relevo a la '
          'bienvenida', (tester) async {
        final carga = await montar(tester, VarianteSplash.codigo);
        carga.fallar(StateError('almacén de claves'));
        await avanzarHasta(
          tester,
          () => CapaDeArranque.fase == FaseDeLaCapa.inactiva,
        );
        expect(Get.currentRoute, '/login');
      });

      testWidgets(
        'si la cabecera no se mide, la salida es un fundido de 300 ms',
        (tester) async {
          final carga = await montar(
            tester,
            VarianteSplash.ensamble,
            home: (_) => const HomeDePrueba(informa: false),
          );
          carga.terminar('/home');
          await avanzarHasta(
            tester,
            () => CapaDeArranque.fase == FaseDeLaCapa.fundido,
          );
          final desde = await avanzarHasta(
            tester,
            () => CapaDeArranque.fase == FaseDeLaCapa.inactiva,
          );
          expect(desde, inInclusiveRange(290, 340));
        },
      );

      testWidgets(
        'si la ruta de debajo cambia durante la salida, termina con el '
        'fundido de 300 ms',
        (tester) async {
          final carga = await montar(tester, VarianteSplash.incremento);
          carga.terminar('/home');
          await avanzarHasta(
            tester,
            () => CapaDeArranque.fase == FaseDeLaCapa.salida,
          );
          await avanzar(tester, 100);
          expect(offAllToLogin(), isTrue);
          await avanzar(tester, 32);
          expect(CapaDeArranque.fase, FaseDeLaCapa.fundido);
          await avanzar(tester, 400);
          expect(CapaDeArranque.fase, FaseDeLaCapa.inactiva);
        },
      );
    },
  );

  group('la carga y main (RF-SPL-4, RF-SPL-12 y RF-SPL-18)', () {
    setUp(reiniciarArranque);
    tearDown(reiniciarArranque);

    test('un fallo de Firebase o del almacén es un fallo antes de los '
        'servicios', () async {
      await expectLater(
        cargarElArranque(
          iniciarFirebase: () async => throw StateError('sin Firebase'),
        ),
        throwsA(isA<FalloAntesDeLosServicios>()),
      );
      expect(Get.isRegistered<AuthService>(), isFalse);
    });

    test('sin sesión guardada registra los servicios y devuelve /login, sin '
        'red', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
      final ruta = await cargarElArranque(iniciarFirebase: () async {});
      expect(ruta, '/login');
      expect(Get.isRegistered<StorageService>(), isTrue);
      expect(Get.isRegistered<AuthService>(), isTrue);
      // El servicio del test de especialidad llega con fcbf2e7 y sigue
      // registrado, ahora desde la carga.
      expect(Get.isRegistered<SpecialtyTestService>(), isTrue);
      // La recarga desde la ULima llega con el merge de main y también se
      // registra desde la carga.
      expect(Get.isRegistered<RecargaUlimaService>(), isTrue);
    });

    test('la carga ya no pide las alertas, que pide el home al montarse '
        '(S-7)', () {
      final fuente = File(
        'lib/pages/splash/carga_del_arranque.dart',
      ).readAsStringSync();
      expect(fuente, isNot(contains('fetchAlerts')));
    });

    test('en web, el alumno sin especialidad arranca en /login', () {
      expect(rutaInicialEnWeb('/setup-carrera'), '/login');
      expect(rutaInicialEnWeb('/home'), '/home');
      expect(rutaInicialEnWeb('/login'), '/login');
    });

    test('las GetPage se declaran una sola vez, con /arranque y las rutas del '
        'test de especialidad', () {
      final nombres = paginasDeLaApp.map((p) => p.name).toList();
      expect(nombres.toSet(), hasLength(nombres.length));
      expect(
        nombres,
        containsAll(<String>[
          rutaDelArranque,
          '/home',
          '/login',
          '/setup-carrera',
          '/test-especialidad',
        ]),
      );
    });

    testWidgets('fuera de web la app arranca en /arranque con la capa activa', (
      tester,
    ) async {
      telefono(tester);
      await tester.pumpWidget(
        MyApp(
          intro: IntroDelArranque(
            carga: CargaFalsa().call,
            variantes: VariantesFijas(VarianteSplash.ensamble),
            random: Random(1),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ArranquePage), findsOneWidget);
      expect(find.byType(CapaDeArranque), findsOneWidget);
      expect(CapaDeArranque.fase, isNot(FaseDeLaCapa.inactiva));
    });
  });
}
