// test/HU37_jeff/hoja_recarga_test.dart
//
// WIDGET · Recarga desde la ULima (specs/features/recarga-portal/
// recarga-portal.spec.md), RF-RCG-2 y RF-RCG-3, la hoja de recarga, y los
// cuatro parámetros opcionales de PasswordResetOtpField.
// Archivos probados lib/components/recarga_ulima/hoja_recarga_ulima.dart y
// lib/pages/password_reset/password_reset_ui.dart.
//
// Con un campo enfocado el cursor parpadea sin fin, así que estas pruebas
// avanzan el reloj con pump y nunca con pumpAndSettle.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/recarga_ulima/hoja_recarga_ulima.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/pages/password_reset/password_reset_ui.dart';
import 'package:ulima_plus/services/recarga_ulima_service.dart';
import 'package:ulima_plus/services/session_navigation.dart';

import 'recarga_dobles.dart';

const String _refresh = 'POST /portal-sync/refresh';

/// La recarga con el JWT vencido. Hace lo mismo que ApiClient._send ante un
/// 401, que primero manda al login con offAllToLogin() y después lanza.
class _ApiSesionVencida extends ApiRecargaFalsa {
  @override
  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    if (path != '/portal-sync/refresh') {
      return super.postJson(path, body: body, token: token);
    }
    offAllToLogin();
    throw errorApi(401, 'UNAUTHORIZED');
  }
}

ThemeData _tema(Brightness brillo) {
  const tema = MaterialTheme(TextTheme());
  return brillo == Brightness.light ? tema.light() : tema.dark();
}

/// Una pantalla alta, porque con la fuente de pruebas cada letra mide 1 em y
/// la hoja entera no cabe en 600 de alto.
void _pantallaAlta(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

/// Deja correr las animaciones de la hoja, sin esperar al cursor.
Future<void> _asentar(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// El resultado de la última hoja cerrada, o `null` si sigue abierta.
bool? _resultado;

Future<ApiRecargaFalsa> _abrir(
  WidgetTester tester, {
  Brightness brillo = Brightness.light,
  ApiRecargaFalsa? api,
  bool conUsuario = true,
}) async {
  _pantallaAlta(tester);
  loguear(conUsuario ? alumna() : null);
  final falsa = api ?? ApiRecargaFalsa();
  Get.put<RecargaUlimaService>(RecargaUlimaService(apiClient: falsa));
  _resultado = null;
  await tester.pumpWidget(
    GetMaterialApp(
      theme: _tema(brillo),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                _resultado = await abrirHojaRecargaUlima(context);
              },
              child: const Text('ABRIR'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('ABRIR'));
  await _asentar(tester);
  return falsa;
}

Finder get _campoContrasena => find.byType(TextField).first;
Finder get _campoCodigo => find.descendant(
  of: find.byType(PasswordResetOtpField),
  matching: find.byType(TextField),
);
Finder get _cajas => find.descendant(
  of: find.byType(PasswordResetOtpField),
  matching: find.byType(AnimatedContainer),
);

ElevatedButton _botonActualizar(WidgetTester tester) =>
    tester.widget<ElevatedButton>(find.byType(ElevatedButton).last);

Future<void> _llenar(
  WidgetTester tester, {
  String password = 'clave-de-prueba',
  String codigo = '482913',
}) async {
  await tester.enterText(_campoContrasena, password);
  await tester.enterText(_campoCodigo, codigo);
  await tester.pump();
}

String _textoDe(WidgetTester tester, Finder campo) =>
    tester.widget<TextField>(campo).controller!.text;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  group('WIDGET · PasswordResetOtpField conserva su forma por defecto', () {
    testWidgets('sin los parámetros nuevos, 52 de alto, el relleno de la '
        'paleta y el borde en reposo transparente de 2', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      late PasswordResetPalette paleta;
      await tester.pumpWidget(
        MaterialApp(
          theme: _tema(Brightness.light),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                paleta = PasswordResetPalette.from(context);
                return PasswordResetOtpField(
                  controller: controller,
                  palette: paleta,
                );
              },
            ),
          ),
        ),
      );

      expect(_cajas, findsNWidgets(6));
      for (final caja in tester.widgetList<AnimatedContainer>(_cajas)) {
        final deco = caja.decoration! as BoxDecoration;
        expect(deco.color, paleta.fieldFill);
        final borde = deco.border! as Border;
        expect(borde.top.color, Colors.transparent);
        expect(borde.top.width, 2);
      }
      expect(tester.getSize(_cajas.first).height, 52);
    });
  });

  group('WIDGET · la hoja de recarga (RF-RCG-2)', () {
    testWidgets('los textos exactos, con el código del alumno en negrita', (
      tester,
    ) async {
      await _abrir(tester);

      expect(find.text('Actualizar desde la ULima'), findsOneWidget);
      expect(find.text('Entras como 20230001'), findsOneWidget);
      final entras = tester.widget<Text>(find.text('Entras como 20230001'));
      final codigo =
          (entras.textSpan! as TextSpan).children!.single as TextSpan;
      expect(codigo.text, '20230001');
      expect(codigo.style!.fontWeight, FontWeight.bold);
      expect(
        find.text(
          'Al tocar «Actualizar» aceptas que ULima++ lea en miUlima tus '
          'notas parciales y tu asistencia. La contraseña y el código se '
          'usan una sola vez y no se guardan.',
        ),
        findsOneWidget,
      );
      expect(find.text('Contraseña de miUlima'), findsOneWidget);
      expect(find.text('Tu contraseña del portal'), findsOneWidget);
      expect(find.text('Código del autenticador'), findsOneWidget);
      expect(
        find.text('El código de 6 dígitos que cambia cada 30 segundos.'),
        findsOneWidget,
      );
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Actualizar'), findsOneWidget);
      expect(find.byTooltip('Cerrar'), findsOneWidget);
      expect(find.byTooltip('Mostrar contraseña'), findsOneWidget);

      await tester.tap(find.byTooltip('Mostrar contraseña'));
      await tester.pump();
      expect(find.byTooltip('Ocultar contraseña'), findsOneWidget);
    });

    testWidgets('sin usuario, la línea «Entras como» no se pinta', (
      tester,
    ) async {
      await _abrir(tester, conUsuario: false);

      expect(find.textContaining('Entras como'), findsNothing);
      expect(find.text('Actualizar desde la ULima'), findsOneWidget);
    });

    testWidgets('«Actualizar» se apaga sin contraseña, con cinco dígitos y con '
        'una contraseña de espacios, y se enciende con seis', (tester) async {
      await _abrir(tester);
      expect(_botonActualizar(tester).onPressed, isNull);

      await _llenar(tester, password: '', codigo: '482913');
      expect(_botonActualizar(tester).onPressed, isNull);

      await _llenar(tester, codigo: '48291');
      expect(_botonActualizar(tester).onPressed, isNull);

      await _llenar(tester, password: '   ', codigo: '482913');
      expect(_botonActualizar(tester).onPressed, isNull);

      await _llenar(tester);
      expect(_botonActualizar(tester).onPressed, isNotNull);

      // Apagado lleva primary al 30 % de fondo y onSurface al 38 % de texto.
      await _llenar(tester, password: '');
      final estilo = _botonActualizar(tester).style!;
      final colores = _tema(Brightness.light).colorScheme;
      expect(
        estilo.backgroundColor!.resolve({WidgetState.disabled}),
        colores.primary.withValues(alpha: 0.3),
      );
      expect(
        estilo.foregroundColor!.resolve({WidgetState.disabled}),
        colores.onSurface.withValues(alpha: 0.38),
      );
      expect(estilo.backgroundColor!.resolve({}), MaterialTheme.primaryColor);
      expect(estilo.foregroundColor!.resolve({}), Colors.white);
    });

    testWidgets('las seis casillas miden 50 de alto, no tienen relleno y '
        'llevan el borde en reposo de D13, y el campo mide al menos 52', (
      tester,
    ) async {
      await _abrir(tester);
      final colores = _tema(Brightness.light).colorScheme;

      expect(_cajas, findsNWidgets(6));
      for (final caja in tester.widgetList<AnimatedContainer>(_cajas)) {
        final deco = caja.decoration! as BoxDecoration;
        expect(deco.color, Colors.transparent);
        final borde = deco.border! as Border;
        expect(borde.top.color, colores.onSurface.withValues(alpha: 0.5));
        expect(borde.top.width, 1);
      }
      for (var i = 0; i < 6; i++) {
        expect(tester.getSize(_cajas.at(i)).height, 50);
      }
      expect(tester.getSize(_campoContrasena).height, greaterThanOrEqualTo(52));
    });

    testWidgets('la espera muestra su texto, deja las casillas de solo '
        'lectura, apaga la X y «Cancelar» y no deja cerrar con atrás', (
      tester,
    ) async {
      final pendiente = Completer<Map<String, dynamic>>();
      final api = ApiRecargaFalsa()..responder(_refresh, pendiente);
      await _abrir(tester, api: api);
      await _llenar(tester);

      await tester.tap(find.text('Actualizar'));
      await tester.pump();

      expect(api.veces(_refresh), 1);
      expect(
        find.text('Leyendo miUlima. Puede tardar hasta un minuto.'),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Actualizar'), findsNothing);
      expect(tester.widget<TextField>(_campoCodigo).readOnly, isTrue);
      expect(tester.widget<TextField>(_campoContrasena).readOnly, isTrue);
      expect(
        tester
            .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.close))
            .onPressed,
        isNull,
      );
      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNull,
      );

      // Un solo pump no termina de quitar la ruta, y la hoja se seguiría
      // encontrando aunque atrás la cerrara.
      await tester.binding.handlePopRoute();
      await _asentar(tester);
      expect(find.byType(HojaRecargaUlima), findsOneWidget);

      // Al terminar, la hoja se cierra sola.
      pendiente.complete(resultadoJson());
      await _asentar(tester);
      expect(find.byType(HojaRecargaUlima), findsNothing);
    });

    for (final (forma, cerrar)
        in <(String, Future<void> Function(WidgetTester))>[
          ('la X', (t) => t.tap(find.byTooltip('Cerrar'))),
          ('«Cancelar»', (t) => t.tap(find.text('Cancelar'))),
          ('atrás', (t) => t.binding.handlePopRoute()),
        ]) {
      testWidgets('cerrar con $forma vacía los dos campos y al reabrir llegan '
          'vacíos', (tester) async {
        await _abrir(tester);
        await _llenar(tester);
        final contrasena = tester
            .widget<TextField>(_campoContrasena)
            .controller!;
        final codigo = tester.widget<TextField>(_campoCodigo).controller!;

        await cerrar(tester);
        await _asentar(tester);

        expect(find.byType(HojaRecargaUlima), findsNothing);
        expect(_resultado, isFalse);
        expect(contrasena.text, isEmpty);
        expect(codigo.text, isEmpty);

        await tester.tap(find.text('ABRIR'));
        await _asentar(tester);
        expect(_textoDe(tester, _campoContrasena), isEmpty);
        expect(_textoDe(tester, _campoCodigo), isEmpty);
      });
    }

    testWidgets('un toque fuera no la cierra', (tester) async {
      await _abrir(tester);

      await tester.tapAt(const Offset(10, 10));
      await _asentar(tester);

      expect(find.byType(HojaRecargaUlima), findsOneWidget);
    });

    testWidgets('el éxito cierra la hoja, vacía los campos y devuelve true', (
      tester,
    ) async {
      final api = ApiRecargaFalsa()..responder(_refresh, resultadoJson());
      await _abrir(tester, api: api);
      await _llenar(tester);
      final contrasena = tester.widget<TextField>(_campoContrasena).controller!;

      await tester.tap(find.text('Actualizar'));
      await _asentar(tester);

      expect(find.byType(HojaRecargaUlima), findsNothing);
      expect(_resultado, isTrue);
      expect(contrasena.text, isEmpty);
      expect(api.cuerposDe('/portal-sync/refresh').single['credentials'], {
        'password': 'clave-de-prueba',
        'passcode': '482913',
      });
    });

    testWidgets('el error cierra la hoja, vacía los campos, devuelve false y '
        'deja el aviso', (tester) async {
      final api = ApiRecargaFalsa()
        ..responder(_refresh, errorApi(409, 'PORTAL_LOGIN_REJECTED'));
      await _abrir(tester, api: api);
      await _llenar(tester);
      final codigo = tester.widget<TextField>(_campoCodigo).controller!;

      await tester.tap(find.text('Actualizar'));
      await _asentar(tester);

      expect(find.byType(HojaRecargaUlima), findsNothing);
      expect(_resultado, isFalse);
      expect(codigo.text, isEmpty);
      expect(RecargaUlimaService.to.ultimoAviso, isNotNull);
    });

    // RF-RCG-3. ApiClient retira la hoja con offAllToLogin() antes de que
    // recargar() devuelva, y la hoja sigue montada hasta el frame siguiente,
    // así que un pop sin guarda sacaría /login y dejaría el navegador vacío.
    testWidgets('un 401 deja a la vista el login de ApiClient, sin la hoja ni '
        'aviso', (tester) async {
      _pantallaAlta(tester);
      loguear(alumna());
      Get.put<RecargaUlimaService>(
        RecargaUlimaService(apiClient: _ApiSesionVencida()),
      );
      await tester.pumpWidget(
        GetMaterialApp(
          theme: _tema(Brightness.light),
          initialRoute: '/',
          getPages: [
            GetPage(
              name: '/',
              page: () => Scaffold(
                body: Builder(
                  builder: (context) => Center(
                    child: ElevatedButton(
                      onPressed: () => abrirHojaRecargaUlima(context),
                      child: const Text('ABRIR'),
                    ),
                  ),
                ),
              ),
            ),
            GetPage(
              name: '/login',
              page: () => const Scaffold(body: Center(child: Text('LOGIN'))),
            ),
          ],
        ),
      );
      await tester.tap(find.text('ABRIR'));
      await _asentar(tester);
      await _llenar(tester);

      await tester.tap(find.text('Actualizar'));
      await _asentar(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('LOGIN'), findsOneWidget);
      expect(find.byType(HojaRecargaUlima), findsNothing);
      expect(Get.currentRoute, '/login');
      expect(RecargaUlimaService.to.ultimoAviso, isNull);
    });

    testWidgets('las etiquetas de Semantics', (tester) async {
      final semantica = tester.ensureSemantics();
      await _abrir(tester);

      expect(
        tester.getSemantics(find.text('Actualizar desde la ULima')),
        isSemantics(isHeader: true),
      );
      final contrasena = tester.getSemantics(_campoContrasena);
      expect(contrasena, isSemantics(isTextField: true, isObscured: true));
      expect(contrasena.label, startsWith('Contraseña de miUlima'));
      expect(
        tester.getSemantics(_campoCodigo),
        isSemantics(
          isTextField: true,
          label: 'Código del autenticador, 6 dígitos',
        ),
      );
      semantica.dispose();
    });

    for (final brillo in Brightness.values) {
      testWidgets('en ${brillo.name}, la ayuda y el aviso van en onSurface al '
          '70 % y la hoja no se desborda', (tester) async {
        await _abrir(tester, brillo: brillo);
        final colores = _tema(brillo).colorScheme;

        final ayuda = tester.widget<Text>(
          find.text('El código de 6 dígitos que cambia cada 30 segundos.'),
        );
        expect(ayuda.style!.color, colores.onSurface.withValues(alpha: 0.7));
        expect(tester.takeException(), isNull);
      });
    }
  });
}
