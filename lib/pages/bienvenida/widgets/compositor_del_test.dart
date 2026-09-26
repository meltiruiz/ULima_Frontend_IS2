// lib/pages/bienvenida/widgets/compositor_del_test.dart
// El test de especialidad dentro de la conversación (RF-BIEN-10). T0, el
// duelo y la escala con las tarjetas compactas (B-13), la espera, el
// resultado en la conversación (B-15) y la selección manual (RF-TEST-1 y
// RF-TEST-14). Las piezas son las del test (Tarea 22).

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../configs/themes.dart';
import '../../../domain/bienvenida/bienvenida_turnos.dart';
import '../../../models/specialty_test_models.dart';
import '../../specialty_test/specialty_test_controller.dart';
import '../../specialty_test/widgets/question_view.dart';
import '../../specialty_test/widgets/result_view.dart';
import '../bienvenida_controller.dart';
import '../conversacion.dart' show ResultadoDelTest;
import 'compositor.dart';

typedef _Textos = TextosDeLaBienvenida;

class CompositorDelTest extends StatelessWidget {
  const CompositorDelTest({super.key, required this.c, required this.turno});

  final BienvenidaController c;
  final TurnoDeLaBienvenida turno;

  @override
  Widget build(BuildContext context) {
    final t = c.test;
    if (t == null) return const SizedBox.shrink();
    // Cada caso lee sus Rx dentro de su propio Obx.
    switch (turno) {
      case TurnoDeLaBienvenida.t0Invitacion:
        return Obx(() {
          final error = t.carga.value == EstadoDeCarga.error;
          return RespuestasRapidas(
            respuestas: [
              RespuestaRapida(texto: _Textos.saltar, alTocar: c.saltarElTest),
              RespuestaRapida(
                texto: error ? _Textos.reintentar : _Textos.empezarElTest,
                principal: true,
                alTocar: error ? c.reintentarElContenido : c.empezarElTest,
              ),
            ],
          );
        });
      case TurnoDeLaBienvenida.pregunta:
      case TurnoDeLaBienvenida.desempate:
        return _Pregunta(c: c, t: t);
      case TurnoDeLaBienvenida.espera:
        return Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (c.pideReinicio.value)
                RespuestaRapida(
                  texto: _Textos.empezarDeNuevo,
                  principal: true,
                  alTocar: c.empezarDeNuevo,
                )
              else if (t.errorDeEspera.value != null)
                RespuestaRapida(
                  texto: _Textos.reintentar,
                  principal: true,
                  alTocar: c.reintentarLaEvaluacion,
                ),
              EnlaceSecundario(
                texto: _Textos.preguntaAnterior,
                alTocar: c.preguntaAnterior,
              ),
            ],
          ),
        );
      case TurnoDeLaBienvenida.resultado:
        return _BotonesDelResultado(c: c, t: t);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _Pregunta extends StatelessWidget {
  const _Pregunta({required this.c, required this.t});

  final BienvenidaController c;
  final SpecialtyTestController t;

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);
    final lector = MediaQuery.accessibleNavigationOf(context);
    void responder(String valor) => c.responderAlTest(valor, conLector: lector);
    return Obx(() {
      final contenido = t.contenido.value!;
      final paso = t.paso.value;
      final respuesta = t.respuestaActual;
      final total = contenido.totalQuestions;
      final pregunta = t.preguntaActual;
      final desempate = t.desempateActual;
      final rotulo = pregunta == null
          ? 'Desempate ${paso - total + 1}'
          : pregunta.isDuel
          ? _Textos.rotuloDelDuelo(paso + 1, total)
          : _Textos.rotuloDeLaEscala(paso + 1, total);
      final Widget respuestas;
      if (pregunta != null && !pregunta.isDuel) {
        // Solo las opciones, con la tarea en la burbuja de Ulises.
        respuestas = EscalaDelTest(
          pregunta: pregunta,
          opciones: contenido.scaleOptions,
          respuesta: respuesta,
          onTap: responder,
          compacto: true,
        );
      } else {
        final tareas = pregunta != null
            ? <TestTask>[pregunta.top!, pregunta.bottom!]
            : <TestTask>[desempate!.tiebreak.top, desempate.tiebreak.bottom];
        respuestas = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            DueloDelTest(
              tareas: tareas,
              contenido: contenido,
              respuesta: respuesta,
              ayuda: null,
              onTap: responder,
              compacto: true,
            ),
            const SizedBox(height: 8),
            LasDosONinguna(
              contenido: contenido,
              respuesta: respuesta,
              onTap: responder,
            ),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            // En mayúsculas a la vista, y el lector lo dice con su texto.
            rotulo.toUpperCase(),
            semanticsLabel: rotulo,
            style: TextStyle(
              color: MaterialTheme.testAccentText(b),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          respuestas,
          if (lector && respuesta != null) ...[
            const SizedBox(height: 8),
            BotonPrincipal(texto: _Textos.siguiente, alTocar: c.siguiente),
          ],
          // Desde la pregunta 2 y en los desempates (RF-BIEN-10).
          if (paso > 0)
            EnlaceSecundario(
              texto: _Textos.preguntaAnterior,
              alTocar: c.preguntaAnterior,
            ),
        ],
      );
    });
  }
}

class _BotonesDelResultado extends StatelessWidget {
  const _BotonesDelResultado({required this.c, required this.t});

  final BienvenidaController c;
  final SpecialtyTestController t;

  Future<void> _elegir(BuildContext context) async {
    final r = t.resultado.value;
    if (r == null) return;
    var elegida = r.ranking.first.specialtyId;
    if (r.tie) {
      // Con empate, la hoja del test pregunta cuál (RF-TEST-9).
      final id = await showModalBottomSheet<int>(
        context: context,
        builder: (_) => HojaDelEmpate(ganadoras: r.winners),
      );
      if (id == null) return;
      elegida = id;
    }
    await c.elegirComoPrincipal(elegida);
  }

  @override
  Widget build(BuildContext context) => Obx(() {
    final activos = t.botonesActivos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        BotonPrincipal(
          texto: _Textos.elegirComoPrincipal,
          esperando: t.guardando.value,
          alTocar: activos ? () => _elegir(context) : null,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RespuestaRapida(
                texto: _Textos.decidirDespues,
                alTocar: activos ? c.decidirDespues : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: RespuestaRapida(
                texto: _Textos.rehacerElTest,
                alTocar: activos ? c.rehacerElTest : null,
              ),
            ),
          ],
        ),
      ],
    );
  });
}

TestSpecialty? _porId(SpecialtyTestContent contenido, int id) {
  for (final s in contenido.specialties) {
    if (s.specialtyId == id) return s;
  }
  return null;
}

/// El resultado en la conversación, que desplaza (B-15). Son la tarjeta de
/// la número uno y la de los electivos y «También te puede interesar», con
/// sus corazones. Se dibuja desde su entrada, así que queda aunque el alumno
/// rehaga el test, y solo el vigente deja tocar los corazones (RF-BIEN-5).
class ResultadoEnLaConversacion extends StatefulWidget {
  const ResultadoEnLaConversacion({
    super.key,
    required this.c,
    required this.entrada,
  });

  final BienvenidaController c;
  final ResultadoDelTest entrada;

  @override
  State<ResultadoEnLaConversacion> createState() =>
      _ResultadoEnLaConversacionState();
}

class _ResultadoEnLaConversacionState extends State<ResultadoEnLaConversacion> {
  bool _motivoAbierto = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.c.test;
    final r = widget.entrada.resultado;
    final contenido = widget.entrada.contenido;
    final fijos = widget.entrada.corazones;
    final vigente = fijos == null && identical(t?.resultado.value, r);
    final sinMovimiento = MediaQuery.disableAnimationsOf(context);
    final ganadoras = <TestSpecialty>[
      for (final w in r.winners) ?_porId(contenido, w.specialtyId),
    ];
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: sinMovimiento ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 900),
      builder: (context, avance, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TarjetaGanadora(
            resultado: r,
            contenido: contenido,
            avance: avance,
            motivoAbierto: _motivoAbierto,
            onMotivo: () => setState(() => _motivoAbierto = !_motivoAbierto),
          ),
          const SizedBox(height: 10),
          FilaDeElectivos(ganadoras: ganadoras, empate: r.tie),
          const SizedBox(height: 10),
          const EncabezadoDeLasDemas(),
          if (vigente)
            Obx(
              () => Column(
                children: [
                  for (var i = 1; i < r.ranking.length; i++)
                    FilaDelRanking(
                      puesto: i + 1,
                      entrada: r.ranking[i],
                      especialidad: _porId(contenido, r.ranking[i].specialtyId),
                      primera: false,
                      marcada: t!.corazones.contains(r.ranking[i].specialtyId),
                      esPrincipal:
                          t.principalActual == r.ranking[i].specialtyId,
                      onCorazon: () =>
                          widget.c.alternarCorazon(r.ranking[i].specialtyId),
                    ),
                ],
              ),
            )
          else
            Column(
              children: [
                for (var i = 1; i < r.ranking.length; i++)
                  FilaDelRanking(
                    puesto: i + 1,
                    entrada: r.ranking[i],
                    especialidad: _porId(contenido, r.ranking[i].specialtyId),
                    primera: false,
                    marcada: fijos?.contains(r.ranking[i].specialtyId) ?? false,
                    esPrincipal: t?.principalActual == r.ranking[i].specialtyId,
                    onCorazon: null,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// La lista oficial con «Principal» y «Me interesa» y el botón de hoy
/// (RF-TEST-1 y RF-TEST-14).
class SeleccionManual extends StatelessWidget {
  const SeleccionManual({super.key, required this.c});

  final BienvenidaController c;

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);
    return Obx(() {
      if (c.catalogoFallido.value) {
        return RespuestaRapida(
          texto: _Textos.reintentar,
          principal: true,
          esperando: c.esperando.value,
          alTocar: c.reintentarElCatalogo,
        );
      }
      final nada =
          c.principalManual.value == null && c.interesesManuales.isEmpty;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final e in c.especialidadesOficiales)
            _FilaManual(
              nombre: e['name']?.toString() ?? '',
              principal: c.principalManual.value == e['id'],
              interes: c.interesesManuales.contains(e['id']),
              alPrincipal: () => c.marcarPrincipal(e['id'] as int),
              alInteres: () => c.alternarInteres(e['id'] as int),
              brillo: b,
            ),
          const SizedBox(height: 8),
          BotonPrincipal(
            texto: nada ? _Textos.saltarPorAhora : _Textos.finalizar,
            esperando: c.esperando.value,
            alTocar: c.terminarLaSeleccion,
          ),
        ],
      );
    });
  }
}

class _FilaManual extends StatelessWidget {
  const _FilaManual({
    required this.nombre,
    required this.principal,
    required this.interes,
    required this.alPrincipal,
    required this.alInteres,
    required this.brillo,
  });

  final String nombre;
  final bool principal;
  final bool interes;
  final VoidCallback alPrincipal;
  final VoidCallback alInteres;
  final Brightness brillo;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          nombre,
          style: TextStyle(
            color: MaterialTheme.textPrimary(brillo),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            RespuestaRapida(
              texto: _Textos.principal,
              principal: principal,
              alTocar: alPrincipal,
            ),
            RespuestaRapida(
              texto: _Textos.meInteresa,
              principal: interes,
              alTocar: alInteres,
            ),
          ],
        ),
      ],
    ),
  );
}
