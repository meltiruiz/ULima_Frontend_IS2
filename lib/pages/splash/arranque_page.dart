// lib/pages/splash/arranque_page.dart
// La página vacía de /arranque, del naranja del splash, sobre la que corre
// la intro (RF-SPL-4).

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'salidas.dart';

class ArranquePage extends StatelessWidget {
  const ArranquePage({super.key});

  @override
  Widget build(BuildContext context) =>
      const AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: ColoredBox(color: naranjaDelSplash, child: SizedBox.expand()),
      );
}
