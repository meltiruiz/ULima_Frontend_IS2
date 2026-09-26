// lib/pages/specialty_test/specialty_test_profile_card.dart
// La tarjeta del test en «Configuración académica» del Perfil (RF-TEST-10).

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/skeleton.dart';
import '../../configs/themes.dart';
import '../../models/specialty_test_models.dart';
import '../../services/specialty_test_service.dart';
import 'specialty_test_controller.dart';
import 'specialty_test_logic.dart';
import 'specialty_test_page.dart';
import 'widgets/test_buttons.dart';
import 'widgets/ulises_bubble.dart';

/// El último resultado, un test a medias y el acceso para hacerlo o
/// rehacerlo. Sin maqueta, usa las piezas del resultado (decisión abierta
/// 16). La monta `perfil.dart` solo si `SpecialtyTestService` está
/// registrado. Con el test no disponible no aparece.
class SpecialtyTestProfileCard extends StatefulWidget {
  const SpecialtyTestProfileCard({super.key});

  static const Key skeletonKey = Key('tarjeta-test-esqueleto');
  static const String titulo = 'Test de especialidad';

  /// El ícono de una ganadora y la barra de una fila, por su clave.
  static Key iconoKey(String clave) => Key('icono-perfil-$clave');
  static Key barraKey(String clave) => Key('barra-perfil-$clave');

  @override
  State<SpecialtyTestProfileCard> createState() =>
      _SpecialtyTestProfileCardState();
}

class _SpecialtyTestProfileCardState extends State<SpecialtyTestProfileCard> {
  SpecialtyTestService get _s => SpecialtyTestService.to;

  @override
  void initState() {
    super.initState();
    // Después del frame, nunca durante build, como la tarjeta del récord.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _s.loadLastResult();
    });
  }

  Future<void> _abrirElTest() async {
    await Get.toNamed<Object?>(
      SpecialtyTestPage.ruta,
      arguments: SpecialtyTestPage.argumentos(OrigenDelTest.perfil),
    );
    // Si el test terminó, el service tiene el resultado marcado como viejo
    // y lo pide otra vez.
    if (mounted) await _s.loadLastResult();
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Obx(() {
      // Los Rx se leen siempre, para que el Obx quede suscrito a todos.
      final estado = _s.lastResultStatus;
      final resultado = _s.lastResult;
      final pausado = _s.paused;
      final contenido = _s.content;
      if (estado == LastResultStatus.notAvailable) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: MaterialTheme.cardBg(b),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: MaterialTheme.borderColor(b)),
          ),
          child: switch (estado) {
            LastResultStatus.loading => const SkeletonPulse(
              key: SpecialtyTestProfileCard.skeletonKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 140, height: 14),
                  SizedBox(height: 10),
                  SkeletonBox(width: double.infinity, height: 32),
                  SizedBox(height: 8),
                  SkeletonBox(width: double.infinity, height: 10),
                ],
              ),
            ),
            LastResultStatus.error => _Error(
              onRetry: () {
                _s.loadLastResult(force: true);
              },
            ),
            _ => _Contenido(
              resultado: estado == LastResultStatus.loaded ? resultado : null,
              pausado: pausado,
              contenido: contenido,
              onAbrir: _abrirElTest,
            ),
          },
        ),
      );
    });
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo({this.conUlises = false});

  final bool conUlises;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Row(
      children: [
        if (conUlises) ...[
          const UlisesAvatar(size: 28),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Text(
            SpecialtyTestProfileCard.titulo,
            style: TextStyle(
              color: MaterialTheme.textPrimary(b),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Titulo(),
        const SizedBox(height: 8),
        TestErrorMessage(
          text: 'No se pudo cargar tu último test.',
          onRetry: onRetry,
        ),
      ],
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({
    required this.resultado,
    required this.pausado,
    required this.contenido,
    required this.onAbrir,
  });

  final LastSpecialtyTestResult? resultado;
  final PausedSpecialtyTest? pausado;
  final SpecialtyTestContent? contenido;
  final VoidCallback onAbrir;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final gris = MaterialTheme.testMuted(b);
    final r = resultado;
    final p = pausado;
    final String boton;
    if (p != null) {
      boton = 'Seguir el test';
    } else if (r != null) {
      boton = 'Rehacer el test';
    } else {
      boton = 'Hacer el test';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Titulo(conUlises: r == null && p == null),
        if (r?.completedAt != null) ...[
          const SizedBox(height: 2),
          Text(
            'Hecho el ${fechaEnLima(r!.completedAt!)}',
            style: TextStyle(color: gris, fontSize: 12),
          ),
        ],
        const SizedBox(height: 10),
        if (p != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Tienes un test a medias, ${p.answeredQuestions} de '
              '${p.content.totalQuestions}.',
              style: TextStyle(
                color: MaterialTheme.textPrimary(b),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (r == null && p == null)
          Text(
            'Todavía no hiciste el test.',
            style: TextStyle(color: gris, fontSize: 13),
          ),
        if (r != null) ...[
          for (final w in r.winners)
            _FilaGanadora(entrada: w, contenido: contenido),
          for (final o in r.others)
            _FilaCompacta(entrada: o, contenido: contenido),
          if (r.isCurrentVersion == false)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'El test cambió desde que lo hiciste.',
                style: TextStyle(color: gris, fontSize: 12),
              ),
            ),
        ],
        const SizedBox(height: 10),
        TestPrimaryButton(label: boton, height: 48, onPressed: onAbrir),
      ],
    );
  }
}

/// El color de una especialidad del contenido, o null si no hay copia o no
/// se puede leer.
Color? _colorDe(SpecialtyTestContent? contenido, String clave, Brightness b) =>
    colorDeEspecialidad(contenido?.specialtyByKey(clave), b);

class _FilaGanadora extends StatelessWidget {
  const _FilaGanadora({required this.entrada, required this.contenido});

  final RankingEntry entrada;
  final SpecialtyTestContent? contenido;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final color = _colorDe(contenido, entrada.key, b);
    final baldosa = color == null
        ? MaterialTheme.testTaskTileBg(b)
        : tinte(color, MaterialTheme.cardBg(b), 0.14);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: baldosa,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                iconoDelTest(contenido?.specialtyByKey(entrada.key)?.icon),
                key: SpecialtyTestProfileCard.iconoKey(entrada.key),
                size: 19,
                color: colorQueSeLee(
                  color,
                  fondo: baldosa,
                  respaldo: MaterialTheme.iconoNaranja(b),
                  esTexto: false,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entrada.name,
              style: TextStyle(
                color: MaterialTheme.textPrimary(b),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${entrada.affinity} %',
            style: TextStyle(
              color: MaterialTheme.textPrimary(b),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaCompacta extends StatelessWidget {
  const _FilaCompacta({required this.entrada, required this.contenido});

  final RankingEntry entrada;
  final SpecialtyTestContent? contenido;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final barra =
        _colorDe(contenido, entrada.key, b) ?? MaterialTheme.testMuted(b);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entrada.name,
                  style: TextStyle(
                    color: MaterialTheme.textPrimary(b),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${entrada.affinity} %',
                style: TextStyle(
                  color: MaterialTheme.testMuted(b),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 4,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(color: MaterialTheme.testTrack(b)),
                  ),
                  FractionallySizedBox(
                    widthFactor: entrada.affinity / 100,
                    child: ColoredBox(
                      key: SpecialtyTestProfileCard.barraKey(entrada.key),
                      color: barra,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
