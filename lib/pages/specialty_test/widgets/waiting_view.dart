// lib/pages/specialty_test/widgets/waiting_view.dart
// La espera de la evaluación y su error (RF-TEST-7 y RF-TEST-11).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../configs/themes.dart';
import '../specialty_test_controller.dart';
import '../specialty_test_logic.dart';
import 'question_view.dart';
import 'test_buttons.dart';
import 'ulises_bubble.dart';

/// La espera se queda en la conversación, con la barra y las plumas llenas.
/// Durante la espera nada responde salvo «Pregunta anterior», la pausa y
/// «Reintentar».
class WaitingView extends StatefulWidget {
  const WaitingView({super.key});

  @override
  State<WaitingView> createState() => _WaitingViewState();
}

class _WaitingViewState extends State<WaitingView> {
  /// En la espera, el foco del lector queda en la burbuja (RF-TEST-13).
  final FocusNode _burbuja = FocusNode(debugLabel: 'espera');

  SpecialtyTestController get _c => Get.find<SpecialtyTestController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _burbuja.requestFocus();
      // Si la última pregunta cierra un bloque, su sello cae aquí, con la
      // misma vibración leve que en la pregunta (RF-TEST-6).
      final c = _c.contenido.value;
      if (c == null) return;
      final turno = turnoDeEspera(c, trasDesempate: _c.esperaTrasDesempate);
      if (turno.sello != null) HapticFeedback.lightImpact();
    });
  }

  @override
  void dispose() {
    _burbuja.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final sinMovimiento = MediaQuery.disableAnimationsOf(context);
    return ColoredBox(
      color: MaterialTheme.pageBg(b),
      child: SafeArea(
        bottom: false,
        child: Obx(() {
          final c = _c.contenido.value;
          if (c == null) return const SizedBox.shrink();
          final error = _c.errorDeEspera.value;
          final completo = turnoDeEspera(
            c,
            trasDesempate: _c.esperaTrasDesempate,
          );
          // Con error, el aviso ocupa el lugar de la línea de espera.
          final turno = error == null
              ? completo
              : TurnoDeUlises(
                  completo.lineas.where((l) => l != c.ulises.loading).toList(),
                  sello: completo.sello,
                );
          return Column(
            children: [
              TestTopBar(
                subtitulo: subtituloDelPaso(c, _c.paso.value),
                onBack: _c.atras,
                onPause: _c.pausar,
              ),
              TestFeathers(total: c.totalQuestions, actual: null),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (turno.lineas.isNotEmpty)
                        UlisesTurnView(turno: turno, focusNode: _burbuja),
                      const SizedBox(height: 12),
                      if (error != null)
                        TestErrorMessage(
                          text: _c.textoDelErrorDeEspera,
                          onRetry: _c.reintentarEvaluacion,
                        )
                      else if (!sinMovimiento)
                        Padding(
                          padding: const EdgeInsets.only(left: 35),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: MaterialTheme.testAccent(b),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
