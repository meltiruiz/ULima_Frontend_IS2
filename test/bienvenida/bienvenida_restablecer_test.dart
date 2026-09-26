// test/bienvenida/bienvenida_restablecer_test.dart
//
// UNITARIA + WIDGET · Bienvenida con Ulises
// (specs/features/bienvenida/bienvenida.spec.md).
// RF-BIEN-20. Las pantallas de «¿Olvidaste tu contraseña?» conservan sus
// textos y sus pasos, sus avisos salen abajo, y el restablecimiento llega a
// la bienvenida con `restablecida`. La Tarea 18 suma el sello en su
// cabecera.
// Archivos probados lib/pages/password_reset/*_controller.dart y
// lib/pages/perfil/perfil.dart.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/components/logo/sello_del_logo.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/pages/password_reset/forgot_password_controller.dart';
import 'package:ulima_plus/pages/password_reset/forgot_password_page.dart';
import 'package:ulima_plus/pages/password_reset/password_reset_ui.dart';
import 'package:ulima_plus/pages/password_reset/reset_password_controller.dart';
import 'package:ulima_plus/pages/password_reset/reset_password_page.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/password_reset_service.dart';
import 'package:ulima_plus/services/session_navigation.dart';
import 'package:ulima_plus/services/storage_service.dart';

class _ServicioFalso extends PasswordResetService {
  @override
  Future<String> request(String identifier) async => 'Te enviamos un código.';

  @override
  Future<void> confirm({
    required String identifier,
    required String code,
    required String newPassword,
  }) async {}
}

class _AlmacenFalso extends StorageService {
  @override
  Future<void> clearToken() async {}
}

class _AuthSinRed extends AuthService {
  @override
  Future<void> logout() async {}
}

Widget _pagina(String texto) => Scaffold(body: Center(child: Text(texto)));

Future<void> _montar(WidgetTester tester) async {
  await tester.pumpWidget(
    GetMaterialApp(
      initialRoute: '/forgot-password',
      getPages: [
        GetPage(name: '/forgot-password', page: () => _pagina('olvido')),
        GetPage(name: '/reset-password', page: () => _pagina('restablecer')),
        GetPage(name: '/login', page: () => _pagina('login')),
      ],
    ),
  );
}

void _avisoAbajo(WidgetTester tester, String titulo) {
  expect(find.text(titulo), findsOneWidget);
  final aviso = tester.widget<GetSnackBar>(find.byType(GetSnackBar));
  expect(aviso.snackPosition, SnackPosition.BOTTOM, reason: titulo);
}

Future<void> _cerrarAvisos(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.reset();
  });
  tearDown(Get.reset);

  group('los avisos abajo (RF-BIEN-20 y B-29)', () {
    testWidgets('«Solicitud enviada» sale abajo', (tester) async {
      await _montar(tester);
      final c = ForgotPasswordController(service: _ServicioFalso());
      c.identifierController.text = '20230001';
      await c.submit();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      // Los avisos se cierran aunque una comprobación falle, porque la cola de
      // avisos de GetX es estática y un aviso colgado frena a los siguientes.
      try {
        _avisoAbajo(tester, 'Solicitud enviada');
      } finally {
        await _cerrarAvisos(tester);
      }
    });

    testWidgets('«Código reenviado» sale abajo', (tester) async {
      await _montar(tester);
      final c = ResetPasswordController(service: _ServicioFalso());
      c.identifier = '20230001';
      await c.resendCode();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      try {
        _avisoAbajo(tester, 'Código reenviado');
      } finally {
        c.onClose();
        await _cerrarAvisos(tester);
      }
    });

    testWidgets('el restablecimiento llega con `restablecida` y «Contraseña '
        'actualizada» sale abajo', (tester) async {
      Get.put<StorageService>(_AlmacenFalso());
      Get.put<AuthService>(_AuthSinRed());
      await _montar(tester);
      final c = ResetPasswordController(service: _ServicioFalso());
      c.identifier = '20230001';
      c.codeController.text = '123456';
      c.passwordController.text = 'Contrasena1';
      c.confirmController.text = 'Contrasena1';
      await c.submit();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      try {
        expect(Get.currentRoute, '/login');
        expect(
          ModalRoute.of(tester.element(find.text('login')))!.settings.arguments,
          {argumentoDeMotivo: MotivoDeLlegada.restablecida},
        );
        _avisoAbajo(tester, 'Contraseña actualizada');
      } finally {
        await _cerrarAvisos(tester);
      }
    });

    test('«Código enviado» del Perfil sale abajo', () {
      final perfil = File('lib/pages/perfil/perfil.dart').readAsStringSync();
      final inicio = perfil.indexOf("'Código enviado'");
      expect(inicio, isNonNegative);
      final llamada = perfil.substring(inicio, perfil.indexOf(');', inicio));
      expect(llamada, contains('snackPosition: SnackPosition.BOTTOM'));
      // Los avisos «Error» del Perfil no cambian.
      expect(perfil, contains("Get.snackbar('Error', e.message);"));
    });
  });

  group('el sello en la cabecera (RF-BIEN-20 y B-9)', () {
    Future<void> montar(
      WidgetTester tester, {
      Brightness brillo = Brightness.light,
      double escala = 1,
      double teclado = 0,
      String inicial = '/forgot-password',
    }) async {
      tester.view.physicalSize = const Size(750, 1334);
      tester.view.devicePixelRatio = 2;
      tester.view.viewInsets = FakeViewPadding(bottom: teclado * 2);
      addTearDown(tester.view.reset);
      const tema = MaterialTheme(TextTheme());
      await tester.pumpWidget(
        GetMaterialApp(
          theme: brillo == Brightness.light ? tema.light() : tema.dark(),
          initialRoute: inicial,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(escala)),
            child: child!,
          ),
          getPages: [
            GetPage(
              name: '/forgot-password',
              page: () => const ForgotPasswordPage(),
              binding: BindingsBuilder(() {
                Get.lazyPut(
                  () => ForgotPasswordController(service: _ServicioFalso()),
                );
              }),
            ),
            GetPage(
              name: '/reset-password',
              page: () => const ResetPasswordPage(),
              binding: BindingsBuilder(() {
                Get.lazyPut(
                  () => ResetPasswordController(service: _ServicioFalso()),
                );
              }),
            ),
            GetPage(
              name: '/sello',
              page: () =>
                  const Scaffold(body: Column(children: [CabeceraConSello()])),
            ),
          ],
        ),
      );
      await tester.pump();
    }

    Rect selloDeLaFranja(WidgetTester tester) =>
        tester.getRect(find.byType(SelloDelLogo).last);

    for (final brillo in Brightness.values) {
      testWidgets('/forgot-password y /reset-password llevan el sello en el '
          'mismo lugar y del mismo tamaño que la franja (${brillo.name})', (
        tester,
      ) async {
        await montar(tester, brillo: brillo, inicial: '/sello');
        final enLaFranja = selloDeLaFranja(tester);
        Get.offAllNamed('/forgot-password');
        await tester.pumpAndSettle();
        expect(tester.getRect(find.byType(SelloDelLogo)), enLaFranja);
        Get.toNamed('/reset-password', arguments: {'identifier': '20230001'});
        await tester.pumpAndSettle();
        expect(tester.getRect(find.byType(SelloDelLogo).last), enLaFranja);
      });
    }

    testWidgets('en cada cuadro de la transición queda un sello a la vista', (
      tester,
    ) async {
      await montar(tester);
      Get.toNamed('/reset-password', arguments: {'identifier': '20230001'});
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(find.byType(SelloDelLogo), findsWidgets, reason: 'cuadro $i');
      }
      Get.back<void>();
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(find.byType(SelloDelLogo), findsWidgets, reason: 'cuadro $i');
      }
    });

    for (final escala in [1.0, 1.3, 2.0]) {
      testWidgets('con el texto al ${escala * 100} % y el teclado abierto, la '
          'flecha sigue arriba a la izquierda y el sello nunca queda bajo '
          'ella', (tester) async {
        await montar(tester, escala: escala, teclado: 300);
        final flecha = tester.getRect(find.byTooltip('Volver'));
        final sello = tester.getRect(find.byType(SelloDelLogo));
        expect(flecha.left, lessThan(20));
        expect(sello.left, greaterThan(flecha.right));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('el sello de la cabecera queda quieto, sin latido ni pulso', (
      tester,
    ) async {
      await montar(tester);
      final sello = tester.widget<SelloDelLogo>(find.byType(SelloDelLogo));
      expect(sello.latido, isNull);
      expect(sello.rombos, isNull);
      final antes = tester.getRect(find.byType(SelloDelLogo));
      await tester.pump(const Duration(seconds: 2));
      expect(tester.getRect(find.byType(SelloDelLogo)), antes);
    });

    testWidgets('/reset-password abierta desde el Perfil, con el correo '
        'enmascarado, lleva el mismo sello', (tester) async {
      await montar(tester, inicial: '/sello');
      final enLaFranja = selloDeLaFranja(tester);
      Get.toNamed(
        '/reset-password',
        arguments: {
          'identifier': '20230001',
          'maskedEmail': 't***@aloe.ulima.edu.pe',
        },
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byType(SelloDelLogo).last), enLaFranja);
    });

    for (final escala in [1.0, 1.3, 2.0]) {
      testWidgets('con el texto al ${escala * 100} % y el teclado abierto, la '
          'tarjeta queda bajo la cabecera y nada desborda', (tester) async {
        await montar(tester, escala: escala, teclado: 300);
        final cabecera = tester.getRect(find.byType(CabeceraConSello));
        final tarjeta = tester.getRect(
          find
              .ancestor(
                of: find.text('¿Olvidaste tu contraseña?'),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        expect(tarjeta.top, greaterThanOrEqualTo(cabecera.bottom));
        expect(tester.takeException(), isNull);
      });
    }

    for (final brillo in Brightness.values) {
      testWidgets('en ${brillo.name} declara íconos claros', (tester) async {
        await montar(tester, brillo: brillo);
        final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
          find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
        );
        expect(region.value.statusBarIconBrightness, Brightness.light);
      });
    }

    testWidgets('declara íconos claros y el sello es un encabezado', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await montar(tester);
      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
      );
      expect(region.value.statusBarIconBrightness, Brightness.light);
      expect(
        tester.getSemantics(find.bySemanticsLabel('ULIMA++')),
        isSemantics(isHeader: true),
      );
      semantica.dispose();
    });

    testWidgets('sin encenderlo, PasswordResetScaffold no lleva el sello, '
        'como en Portal Sync', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => PasswordResetScaffold(
              palette: PasswordResetPalette.from(context),
              child: const Text('portal'),
            ),
          ),
        ),
      );
      expect(find.byType(SelloDelLogo), findsNothing);
      expect(find.byType(CabeceraConSello), findsNothing);
    });
  });
}
