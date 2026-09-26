// test/HU36_jeff/montaje_de_pantallas.dart
//
// Montaje de las pantallas del test de especialidad (HU36) en las pruebas
// de widget. No es un archivo de pruebas.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/configs/themes.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_binding.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_controller.dart';
import 'package:ulima_plus/pages/specialty_test/specialty_test_page.dart';

import 'dobles_del_controlador.dart';

/// El iPhone SE de RF-TEST-3 y RF-TEST-8.
const Size kIphoneSE = Size(375, 667);

/// Monta [pantalla] con el tema de la app, en el tamaño [tamano] y con la
/// escala de texto, el lector de pantalla y el movimiento que se pidan.
Future<void> montarPantalla(
  WidgetTester tester,
  Widget pantalla, {
  Brightness brillo = Brightness.light,
  double escala = 1.0,
  bool lector = false,
  bool sinMovimiento = false,
  Size tamano = kIphoneSE,
}) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final tema = MaterialTheme(ThemeData().textTheme);
  await tester.pumpWidget(
    GetMaterialApp(
      theme: tema.light(),
      darkTheme: tema.dark(),
      themeMode: brillo == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(escala),
          disableAnimations: sinMovimiento,
          accessibleNavigation: lector,
        ),
        child: child!,
      ),
      home: Scaffold(body: pantalla),
    ),
  );
  await tester.pump();
}

/// Registra el controlador con una pantalla falsa. Dentro de testWidgets la
/// carga corre con `tester.pump()`, no con `pumpEventQueue`.
SpecialtyTestController ponerControlador({
  OrigenDelTest origen = OrigenDelTest.asistente,
  UiFalsa? ui,
}) => Get.put<SpecialtyTestController>(
  SpecialtyTestController(origen: origen, ui: ui ?? UiFalsa()),
);

/// El color del primer `Text` con [texto].
Color? colorDeTexto(WidgetTester tester, String texto) =>
    tester.widget<Text>(find.text(texto).first).style?.color;

/// Si [finder] cae entero dentro de la pantalla de [tamano].
bool dentroDeLaPantalla(
  WidgetTester tester,
  Finder finder, {
  Size tamano = kIphoneSE,
}) {
  final r = tester.getRect(finder);
  return r.top >= 0 &&
      r.bottom <= tamano.height &&
      r.left >= 0 &&
      r.right <= tamano.width;
}

/// Carga Roboto del SDK de Flutter con el nombre de familia del tema, como
/// `test/HU23_jeff/chats_pestana_test.dart`. Sin esto, la fuente de pruebas
/// dibuja cada letra como un cuadrado del ancho de su tamaño y ninguna
/// medida de «cabe sin desplazar» se parece a la del teléfono.
Future<void> cargarRoboto() async {
  final raiz = Platform.environment['FLUTTER_ROOT'];
  expect(
    raiz,
    isNotNull,
    reason: 'flutter test fija FLUTTER_ROOT; sin él no hay Roboto que medir',
  );
  final cargador = FontLoader('Roboto');
  for (final peso in ['Regular', 'Medium', 'Bold', 'Black']) {
    final archivo = File(
      '$raiz/bin/cache/artifacts/material_fonts/Roboto-$peso.ttf',
    );
    expect(archivo.existsSync(), isTrue, reason: archivo.path);
    cargador.addFont(
      Future<ByteData>.value(ByteData.sublistView(archivo.readAsBytesSync())),
    );
  }
  await cargador.load();
}

/// Anota cada vibración que pide la pantalla hasta el final de la prueba,
/// con el tipo tal como viaja por el canal, por ejemplo
/// `HapticFeedbackType.lightImpact`.
List<String> escucharVibraciones(WidgetTester tester) {
  final vibraciones = <String>[];
  final mensajero = tester.binding.defaultBinaryMessenger;
  mensajero.setMockMethodCallHandler(SystemChannels.platform, (llamada) async {
    if (llamada.method == 'HapticFeedback.vibrate') {
      vibraciones.add(llamada.arguments as String);
    }
    return null;
  });
  addTearDown(
    () => mensajero.setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return vibraciones;
}

/// Monta la app con la ruta real del test sobre una pantalla de inicio y la
/// abre con [origen]. Devuelve el `Future` de `Get.toNamed`, que se completa
/// con la salida al cerrarse la ruta.
Future<Future<Object?>?> abrirLaRuta(
  WidgetTester tester, {
  OrigenDelTest origen = OrigenDelTest.asistente,
}) async {
  tester.view.physicalSize = kIphoneSE;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final tema = MaterialTheme(ThemeData().textTheme);
  await tester.pumpWidget(
    GetMaterialApp(
      theme: tema.light(),
      initialRoute: '/inicio',
      getPages: [
        GetPage(
          name: '/inicio',
          page: () => const Scaffold(body: Text('Pantalla de inicio')),
        ),
        GetPage(
          name: '/home',
          page: () => const Scaffold(body: Text('Home de prueba')),
        ),
        GetPage(
          name: SpecialtyTestPage.ruta,
          page: () => const SpecialtyTestPage(),
          binding: SpecialtyTestBinding(),
        ),
      ],
    ),
  );
  final salida = Get.toNamed<Object?>(
    SpecialtyTestPage.ruta,
    arguments: SpecialtyTestPage.argumentos(origen),
  );
  await asentar(tester);
  return salida;
}

/// Deja pasar las transiciones de ruta y de pantalla. No usa
/// `pumpAndSettle`, porque el vaivén de la bienvenida y el brillo de la
/// pluma se repiten sin fin.
Future<void> asentar(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
}
