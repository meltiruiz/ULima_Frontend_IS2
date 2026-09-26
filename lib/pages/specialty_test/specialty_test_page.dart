// lib/pages/specialty_test/specialty_test_page.dart
// La ruta /test-especialidad (RF-TEST-1), que cambia entre la bienvenida,
// la pregunta, la espera y el resultado.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../configs/themes.dart';
import 'specialty_test_controller.dart';
import 'widgets/question_view.dart';
import 'widgets/result_view.dart';
import 'widgets/waiting_view.dart';
import 'widgets/welcome_view.dart';

class SpecialtyTestPage extends GetView<SpecialtyTestController> {
  const SpecialtyTestPage({super.key});

  static const String ruta = '/test-especialidad';

  /// Los argumentos de la ruta para [origen].
  static Map<String, String> argumentos(OrigenDelTest origen) => {
    'origen': origen.name,
  };

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final sinMovimiento = MediaQuery.disableAnimationsOf(context);
    return Obx(() {
      final fase = controller.fase.value;
      return PopScope(
        // Solo la bienvenida deja salir con el atrás del sistema. En las
        // preguntas y en la espera lleva al paso previo; en el resultado,
        // nada en el asistente y «Decidir después» en el Perfil.
        canPop: fase == FaseDelTest.bienvenida,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (fase == FaseDelTest.resultado) {
            controller.atrasEnResultado();
          } else {
            controller.atras();
          }
        },
        child: Scaffold(
          backgroundColor: MaterialTheme.pageBg(b),
          body: AnimatedSwitcher(
            duration: Duration(milliseconds: sinMovimiento ? 150 : 220),
            child: KeyedSubtree(
              key: ValueKey<FaseDelTest>(fase),
              child: switch (fase) {
                FaseDelTest.bienvenida => const WelcomeView(),
                FaseDelTest.pregunta => const QuestionView(),
                FaseDelTest.espera => const WaitingView(),
                FaseDelTest.resultado => const ResultView(),
              },
            ),
          ),
        ),
      );
    });
  }
}

/// La pantalla con GetX. Cierra la ruta con `pop` del navegador y no con
/// `Get.back()`, que con un aviso abierto solo cierra el aviso.
class UiDelTestConGet implements SpecialtyTestUi {
  const UiDelTestConGet();

  Brightness get _brillo {
    final contexto = Get.context;
    return contexto == null ? Brightness.light : Theme.of(contexto).brightness;
  }

  @override
  void cerrar([SalidaDelTest? salida]) =>
      Get.key.currentState?.pop<SalidaDelTest>(salida);

  @override
  void irAlHome() => Get.offAllNamed<void>('/home');

  @override
  void avisar(AvisoDelTest aviso) {
    final b = _brillo;
    switch (aviso.tipo) {
      case TipoDeAviso.exito:
        // El aviso de siempre del Perfil (`perfil.dart`), sin cambios.
        Get.snackbar(aviso.titulo ?? '', aviso.mensaje);
      case TipoDeAviso.error:
        // Blanco sobre `errorBg`, 6,54:1, como los avisos de error del chat.
        Get.rawSnackbar(
          messageText: Text(
            aviso.mensaje,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          backgroundColor: MaterialTheme.errorBg(b),
          margin: const EdgeInsets.all(12),
          borderRadius: 12,
        );
      case TipoDeAviso.info:
        Get.rawSnackbar(
          messageText: Text(
            aviso.mensaje,
            style: TextStyle(color: MaterialTheme.textPrimary(b), fontSize: 14),
          ),
          backgroundColor: MaterialTheme.cardBg(b),
          borderColor: MaterialTheme.borderColor(b),
          margin: const EdgeInsets.all(12),
          borderRadius: 12,
        );
    }
  }

  @override
  Future<void> pedirReinicio(String mensaje) {
    return Get.dialog<void>(
      PopScope(
        canPop: false,
        child: Builder(
          builder: (context) {
            final b = Theme.of(context).brightness;
            return AlertDialog(
              backgroundColor: MaterialTheme.cardBg(b),
              content: Text(
                mensaje,
                style: TextStyle(
                  color: MaterialTheme.textPrimary(b),
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: MaterialTheme.testAccentText(b),
                    minimumSize: const Size(48, 48),
                  ),
                  child: const Text(
                    'Empezar de nuevo',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      barrierDismissible: false,
    );
  }
}
