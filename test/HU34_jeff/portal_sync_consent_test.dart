import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/portal_consent/portal_consent_view.dart';
import 'package:ulima_plus/pages/password_reset/password_reset_ui.dart';
import 'package:ulima_plus/pages/portal_sync/portal_sync_binding.dart';
import 'package:ulima_plus/pages/portal_sync/portal_sync_controller.dart';
import 'package:ulima_plus/pages/portal_sync/portal_sync_page.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/portal_sync_service.dart';

/// Consentimiento antes de dar la contraseña del portal (RF-REC-6).
///
/// Aquí se prueba la pantalla sola: qué dice y a quién llama. Su uso dentro
/// del flujo de Portal Sync lo cubren los grupos del final de este archivo.
/// Todos los valores son inventados.

/// Monta [PortalConsentView] dentro del mismo `PasswordResetScaffold` que
/// usan las dos pantallas reales, para que la tarjeta tenga el ancho de 340 y
/// el scroll de verdad.
Widget _consentApp({
  required VoidCallback onAccept,
  required VoidCallback onExit,
  String exitLabel = 'Ahora no',
}) => MaterialApp(
      home: Builder(
        builder: (context) {
          final palette = PasswordResetPalette.from(context);
          return PasswordResetScaffold(
            palette: palette,
            child: PortalConsentView(
              palette: palette,
              onAccept: onAccept,
              onExit: onExit,
              exitLabel: exitLabel,
            ),
          );
        },
      ),
    );

/// Todo el texto visible de la pantalla, en una sola cadena.
String _textoVisible(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? '')
    .join(' ');

/// `ApiClient` falso para el POST de la importación. Cuenta las llamadas y
/// guarda el último body, que es lo que esta tarea tiene que comprobar.
class _FakePortalApi extends ApiClient {
  _FakePortalApi({this.respuesta, this.error})
      : super(configuredBaseUrl: 'http://test');

  final Map<String, dynamic>? respuesta;
  final Object? error;

  int posts = 0;
  Map<String, dynamic>? ultimoBody;

  @override
  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    posts++;
    ultimoBody = body;
    if (error != null) throw error!;
    return respuesta ?? <String, dynamic>{};
  }
}

/// Respuesta de una importación que salió bien. Todo inventado; el código
/// `20230001` es el alumno sintético del repo.
Map<String, dynamic> _importOk() => <String, dynamic>{
      'period': {'id': 2, 'code': '2026-2'},
      'identity': {
        'portalCode': '20230001',
        'fullName': 'Alumna De Prueba',
        'career': 'CARRERA DE PRUEBA',
      },
      'summary': {'enrollmentsUpserted': 5},
      'warnings': <dynamic>[],
    };

/// Controller con el formulario ya llenado, construido a mano y sin `Get.put`.
///
/// En el camino exitoso, `refreshAfterImport` y `_refrescarPantallas` no
/// revientan sin servicios registrados: todo lo suyo va dentro de un `try` o
/// detrás de `Get.isRegistered`. Como `_importOk()` no trae `token`, el
/// `replaceToken` ni se intenta (`portal_sync_service.dart:129`).
PortalSyncController _controller(_FakePortalApi api) {
  final c = PortalSyncController(service: PortalSyncService(apiClient: api));
  c.passwordCtrl.text = 'clave';
  c.passcodeCtrl.text = '123456';
  return c;
}

/// Ruta y binding REALES de `/portal-sync`, para que el paso inicial y el
/// reinicio al volver a entrar se prueben como los vive el alumno. No hay red:
/// ninguna prueba de este grupo toca 'Cargar mis datos'.
Widget _portalApp() => GetMaterialApp(
      initialRoute: '/inicio',
      getPages: [
        GetPage(
          name: '/inicio',
          page: () => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Get.toNamed<dynamic>('/portal-sync'),
                child: const Text('ABRIR'),
              ),
            ),
          ),
        ),
        GetPage(
          name: '/portal-sync',
          page: () => const PortalSyncPage(),
          binding: PortalSyncBinding(),
        ),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WIDGET · PortalConsentView (RF-REC-6)', () {
    testWidgets('muestra el título, los cuatro datos, la finalidad, la contraseña y los dos botones', (tester) async {
      await tester.pumpWidget(_consentApp(onAccept: () {}, onExit: () {}));
      await tester.pump();

      expect(find.text('Antes de entrar a miUlima'), findsOneWidget);
      expect(
        find.text('Para cargar tus datos, ULima++ entra a miUlima con tu contraseña y trae:'),
        findsOneWidget,
      );
      expect(find.text('Tus datos: nombre, código, carrera y nivel.'), findsOneWidget);
      expect(find.text('Tu ciclo: cursos, secciones, docentes, horarios y matrícula.'), findsOneWidget);
      expect(
        find.text('Tu récord académico: notas históricas, PPA, ubicación relativa y créditos.'),
        findsOneWidget,
      );
      expect(find.text('Tu estado de impedimento y deuda.'), findsOneWidget);
      expect(
        find.text(
          'Estos datos se usan para mostrártelos a ti y para las funciones de '
          'ULima++ que ya usas: tu horario, tu malla y la lista de tu sección que '
          've tu docente.',
        ),
        findsOneWidget,
      );
      expect(find.text('Tu contraseña se usa una sola vez y no se guarda.'), findsOneWidget);
      expect(find.text('Acepto'), findsOneWidget);
      expect(find.text('Ahora no'), findsOneWidget);
    });

    testWidgets('nombra cada dato que se importa, como exige RF-REC-6', (tester) async {
      await tester.pumpWidget(_consentApp(onAccept: () {}, onExit: () {}));
      await tester.pump();

      final texto = _textoVisible(tester);
      for (final dato in const <String>[
        'nombre',
        'código',
        'carrera',
        'nivel',
        'cursos',
        'secciones',
        'docentes',
        'horarios',
        'matrícula',
        'notas históricas',
        'PPA',
        'ubicación relativa',
        'créditos',
        'impedimento',
        'deuda',
      ]) {
        expect(
          texto,
          contains(dato),
          reason: 'la pantalla de consentimiento no nombra "$dato"',
        );
      }
    });

    testWidgets('dice para qué se usan los datos y que la contraseña no se guarda', (tester) async {
      await tester.pumpWidget(_consentApp(onAccept: () {}, onExit: () {}));
      await tester.pump();

      final texto = _textoVisible(tester);
      expect(texto, contains('para mostrártelos a ti'));
      expect(texto, contains('la lista de tu sección que ve tu docente'));
      expect(texto, contains('se usa una sola vez y no se guarda'));
    });

    testWidgets('no promete que la contraseña nunca sale del portal: es falso', (tester) async {
      await tester.pumpWidget(_consentApp(onAccept: () {}, onExit: () {}));
      await tester.pump();

      expect(_textoVisible(tester), isNot(contains('nunca sale del portal')));
    });

    testWidgets('"Acepto" llama a onAccept una vez y no a onExit', (tester) async {
      var aceptos = 0;
      var salidas = 0;
      await tester.pumpWidget(_consentApp(
        onAccept: () => aceptos++,
        onExit: () => salidas++,
      ));
      await tester.pump();

      // La tarjeta mide 704 px de alto y la pantalla del test 600: 'Acepto'
      // cae fuera (y ≈ 696-719). Sin este ensureVisible, el tap falla.
      await tester.ensureVisible(find.text('Acepto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Acepto'));
      await tester.pump();

      expect(aceptos, 1);
      expect(salidas, 0);
    });

    testWidgets('el botón de salir muestra el exitLabel recibido y llama a onExit', (tester) async {
      var aceptos = 0;
      var salidas = 0;
      await tester.pumpWidget(_consentApp(
        onAccept: () => aceptos++,
        onExit: () => salidas++,
        exitLabel: 'Volver',
      ));
      await tester.pump();

      expect(find.text('Ahora no'), findsNothing);
      // 'Volver' también es el tooltip de la flecha del scaffold, pero un
      // tooltip sin mostrar no crea ningún Text: este es el enlace de salir.
      expect(find.text('Volver'), findsOneWidget);

      await tester.ensureVisible(find.text('Volver'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Volver'));
      await tester.pump();

      expect(salidas, 1);
      expect(aceptos, 0);
    });

    testWidgets('es solo el contenido de la tarjeta: no trae Scaffold propio', (tester) async {
      await tester.pumpWidget(_consentApp(onAccept: () {}, onExit: () {}));
      await tester.pump();

      // Si trajera su propio Scaffold no se podría montar como `child` del
      // PasswordResetScaffold de Portal Sync ni del de Registro.
      expect(
        find.descendant(
          of: find.byType(PortalConsentView),
          matching: find.byType(Scaffold),
        ),
        findsNothing,
      );
      expect(find.byType(PasswordResetScaffold), findsOneWidget);
    });
  });

  group('UNITARIA · textos fijos de PortalConsentView (RF-REC-6)', () {
    test('las constantes que reutilizan Portal Sync y Registro no cambian', () {
      expect(PortalConsentView.titulo, 'Antes de entrar a miUlima');
      expect(PortalConsentView.botonAceptar, 'Acepto');
      expect(PortalConsentView.introduccion,
          'Para cargar tus datos, ULima++ entra a miUlima con tu contraseña y trae:');
      expect(
        PortalConsentView.finalidad,
        'Estos datos se usan para mostrártelos a ti y para las funciones de '
        'ULima++ que ya usas: tu horario, tu malla y la lista de tu sección que '
        've tu docente.',
      );
      expect(PortalConsentView.contrasena,
          'Tu contraseña se usa una sola vez y no se guarda.');
      expect(PortalConsentView.datosImportados, hasLength(4));
    });
  });

  group('UNITARIA · PortalSyncController consentimiento (RF-REC-6)', () {
    test('caso 1: arranca en el consentimiento y sin aceptación', () {
      final c = _controller(_FakePortalApi(respuesta: _importOk()));

      expect(c.step.value, PortalSyncStep.consent);
      expect(c.consentimientoAceptado.value, isFalse);
    });

    test('caso 2: submit() sin aceptar no manda nada y se queda en consent', () async {
      final api = _FakePortalApi(respuesta: _importOk());
      final c = _controller(api);

      await c.submit();

      expect(api.posts, 0,
          reason: 'sin aceptación no puede salir ninguna petición');
      expect(c.step.value, PortalSyncStep.consent);
    });

    test('caso 3: aceptarConsentimiento() abre el formulario', () {
      final c = _controller(_FakePortalApi(respuesta: _importOk()));

      c.aceptarConsentimiento();

      expect(c.consentimientoAceptado.value, isTrue);
      expect(c.step.value, PortalSyncStep.form);
      expect(c.errorMessage.value, isNull);
    });

    test('caso 4: tras aceptar, el body lleva consent: true en el nivel superior', () async {
      final api = _FakePortalApi(respuesta: _importOk());
      final c = _controller(api);

      c.aceptarConsentimiento();
      await c.submit();

      expect(api.posts, 1);
      expect(api.ultimoBody!['consent'], isTrue);
      expect(api.ultimoBody!.keys.toSet(), equals({'credentials', 'consent'}),
          reason: 'consent va AL LADO de credentials, nunca dentro');
      expect(
        (api.ultimoBody!['credentials'] as Map<String, dynamic>).keys.toSet(),
        equals({'password', 'passcode'}),
      );
      expect(c.step.value, PortalSyncStep.done);
    });

    test('caso 5: un fallo vuelve al formulario sin volver a pedir la aceptación', () async {
      final api = _FakePortalApi(
        error: ApiException(
          statusCode: 409,
          code: 'PORTAL_LOGIN_REJECTED',
          message: 'x',
        ),
      );
      final c = _controller(api);
      c.aceptarConsentimiento();

      // Se anotan TODOS los estados por los que pasa desde que aceptó: la
      // prueba es que `consent` no vuelve a aparecer en esta visita. `listen`
      // de GetX no reemite el valor actual (eso es `listenAndPump`), así que
      // `vistos` son exactamente los cambios posteriores a la aceptación.
      final vistos = <PortalSyncStep>[];
      final sub = c.step.listen(vistos.add);

      await c.submit();

      expect(api.posts, 1);
      expect(c.step.value, PortalSyncStep.form);
      expect(c.consentimientoAceptado.value, isTrue);
      expect(c.errorMessage.value, isNotNull);

      // El catch limpia el passcode porque ya caducó; el alumno escribe otro.
      c.passcodeCtrl.text = '123456';
      await c.submit();

      expect(api.posts, 2,
          reason: 'el segundo intento sale sin volver a aceptar');
      expect(vistos, isNot(contains(PortalSyncStep.consent)));
      await sub.cancel();
    });

    test('caso 6: una visita nueva vuelve a empezar por el consentimiento', () {
      final primera = _controller(_FakePortalApi(respuesta: _importOk()));
      primera.aceptarConsentimiento();
      expect(primera.step.value, PortalSyncStep.form);

      // PortalSyncBinding usa lazyPut SIN fenix: salir de la ruta borra el
      // controller y volver a entrar construye otro desde cero.
      final segunda = _controller(_FakePortalApi(respuesta: _importOk()));

      expect(segunda.step.value, PortalSyncStep.consent);
      expect(segunda.consentimientoAceptado.value, isFalse);
    });
  });

  group('UNITARIA · PortalSyncService.import consent', () {
    test('caso 7: con consent false la clave no viaja en el body', () async {
      final api = _FakePortalApi(respuesta: _importOk());

      await PortalSyncService(apiClient: api)
          .import(password: 'c', passcode: '123456', consent: false);

      expect(api.ultimoBody!.keys.toSet(), equals({'credentials'}));
      expect(api.ultimoBody!.containsKey('consent'), isFalse,
          reason: 'nunca se manda consent: false (RS-BE-29)');
    });
  });

  group('WIDGET · PortalSyncPage con consentimiento', () {
    setUp(() => Get.testMode = true);
    tearDown(Get.reset);

    testWidgets('caso 8: /portal-sync arranca en el consentimiento, no en el formulario', (tester) async {
      await tester.pumpWidget(_portalApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('ABRIR'));
      await tester.pumpAndSettle();

      expect(find.text(PortalConsentView.titulo), findsOneWidget);
      expect(find.text('Carga tus datos del ciclo'), findsNothing);
      expect(find.text('Contraseña de miUlima'), findsNothing);
    });

    testWidgets('caso 9: "Acepto" muestra el formulario de credenciales', (tester) async {
      await tester.pumpWidget(_portalApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('ABRIR'));
      await tester.pumpAndSettle();

      // La tarjeta del consentimiento es más alta que la pantalla del test
      // (704 px medidos en la tarea 9, contra 600): sin ensureVisible el tap
      // sobre 'Acepto' falla.
      await tester.ensureVisible(find.text(PortalConsentView.botonAceptar));
      await tester.pumpAndSettle();
      await tester.tap(find.text(PortalConsentView.botonAceptar));
      await tester.pump();

      expect(find.text('Carga tus datos del ciclo'), findsOneWidget);
      expect(find.text(PortalConsentView.titulo), findsNothing);
    });

    testWidgets('caso 10: "Ahora no" en el consentimiento cierra la pantalla', (tester) async {
      await tester.pumpWidget(_portalApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('ABRIR'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Ahora no'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ahora no'));
      await tester.pumpAndSettle();

      // Vuelve a /inicio. home_page.dart:171 recibe null y no refresca nada,
      // que es lo correcto: no hubo importación.
      expect(find.text('ABRIR'), findsOneWidget);
      expect(find.text(PortalConsentView.titulo), findsNothing);
    });

    testWidgets('caso 11: salir y volver a entrar pide la aceptación de nuevo', (tester) async {
      await tester.pumpWidget(_portalApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('ABRIR'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text(PortalConsentView.botonAceptar));
      await tester.pumpAndSettle();
      await tester.tap(find.text(PortalConsentView.botonAceptar));
      await tester.pump();
      expect(find.text('Carga tus datos del ciclo'), findsOneWidget);

      // Ya en el formulario, se sale por su propio 'Ahora no'. Ningún campo
      // del formulario tiene foco (nadie escribió ni tocó uno) y el kit no usa
      // `autofocus`, así que no hay cursor parpadeando y pumpAndSettle asienta.
      await tester.ensureVisible(find.text('Ahora no'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ahora no'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ABRIR'));
      await tester.pumpAndSettle();

      expect(find.text(PortalConsentView.titulo), findsOneWidget);
      expect(find.text('Carga tus datos del ciclo'), findsNothing);
    });
  });
}
