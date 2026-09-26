// lib/pages/specialty_test/widgets/result_view.dart
// El resultado (RF-TEST-8 y RF-TEST-9), pantallas 4 y 5 de la maqueta.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../configs/themes.dart';
import '../../../models/specialty_test_models.dart';
import '../specialty_test_controller.dart';
import '../specialty_test_logic.dart';
import 'electives_sheet.dart';
import 'test_buttons.dart';
import 'ulises_bubble.dart';

const Color _tintaDorada = Color(0xFF1A0E05);
const List<Color> _dorado = [Color(0xFFFFD166), Color(0xFFFFB020)];

class ResultView extends StatefulWidget {
  const ResultView({super.key});

  static const Key tarjetaKey = Key('resultado-tarjeta');
  static const Key cuerpoKey = Key('resultado-cuerpo');
  static const Key confetiKey = Key('resultado-confeti');
  static Key filaKey(int specialtyId) => Key('fila-$specialtyId');
  static Key corazonKey(int specialtyId) => Key('corazon-$specialtyId');

  @override
  State<ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<ResultView> with TickerProviderStateMixin {
  /// El giro de la tarjeta y la cuenta de la afinidad, 600 ms, una vez.
  late final AnimationController _entrada = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  /// El confeti, una sola vez.
  late final AnimationController _confeti = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  /// Al abrir el resultado, el foco del lector pasa a Ulises (RF-TEST-13).
  final FocusNode _ulises = FocusNode(debugLabel: 'ulises-resultado');
  bool _motivoAbierto = false;
  bool _arranco = false;

  SpecialtyTestController get _c => Get.find<SpecialtyTestController>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_arranco) return;
    _arranco = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      // Sin giro, sin confeti y sin cuenta. Sale el valor final.
      _entrada.value = 1;
    } else {
      _entrada.forward();
      _confeti.forward();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ulises.requestFocus();
      HapticFeedback.heavyImpact();
    });
  }

  @override
  void dispose() {
    _entrada.dispose();
    _confeti.dispose();
    _ulises.dispose();
    super.dispose();
  }

  Future<void> _elegir(SpecialtyTestResult r) async {
    if (!r.tie) {
      await _c.elegirPrincipal(r.ranking.first.specialtyId);
      return;
    }
    final elegida = await showModalBottomSheet<int>(
      context: context,
      // Con texto grande la hoja pasa del alto por defecto, así que toma el
      // que necesita, hasta el 85 % de la pantalla, y desplaza (RF-TEST-13).
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HojaDelEmpate(ganadoras: r.winners),
    );
    if (elegida != null) await _c.elegirPrincipal(elegida);
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return ColoredBox(
      color: MaterialTheme.pageBg(b),
      child: SafeArea(
        child: Obx(() {
          final r = _c.resultado.value;
          final contenido = _c.contenido.value;
          final principal = _c.principalActual;
          final corazones = _c.corazones.toSet();
          final activos = _c.botonesActivos;
          final yaEsPrincipal = _c.yaEsPrincipal;
          if (r == null || contenido == null) return const SizedBox.shrink();
          final ganadoras = [
            for (final w in r.winners) contenido.specialtyByKey(w.key),
          ].whereType<TestSpecialty>().toList();
          return Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: _UlisesDelResultado(
                      texto: [?r.headline, ?r.tiebreakOutcome].join(' '),
                      foco: _ulises,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      key: ResultView.cuerpoKey,
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AnimatedBuilder(
                            animation: _entrada,
                            builder: (context, _) => TarjetaGanadora(
                              resultado: r,
                              contenido: contenido,
                              avance: Curves.easeOut.transform(_entrada.value),
                              motivoAbierto: _motivoAbierto,
                              onMotivo: () => setState(
                                () => _motivoAbierto = !_motivoAbierto,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          FilaDeElectivos(ganadoras: ganadoras, empate: r.tie),
                          const SizedBox(height: 10),
                          const EncabezadoDeLasDemas(),
                          for (var i = 0; i < r.others.length; i++)
                            FilaDelRanking(
                              key: ResultView.filaKey(r.others[i].specialtyId),
                              puesto: r.ranking.indexOf(r.others[i]) + 1,
                              entrada: r.others[i],
                              especialidad: contenido.specialtyByKey(
                                r.others[i].key,
                              ),
                              primera: i == 0,
                              marcada: corazones.contains(
                                r.others[i].specialtyId,
                              ),
                              esPrincipal: r.others[i].specialtyId == principal,
                              onCorazon: _c.guardando.value
                                  ? null
                                  : () => _c.alternarCorazon(
                                      r.others[i].specialtyId,
                                    ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TestPrimaryButton(
                          label: yaEsPrincipal
                              ? 'Ya es tu principal'
                              : 'Elegir como principal',
                          height: 48,
                          loading: _c.guardando.value,
                          onPressed: yaEsPrincipal || !activos
                              ? null
                              : () => _elegir(r),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TestSecondaryButton(
                                label: 'Decidir después',
                                onPressed: activos ? _c.decidirDespues : null,
                              ),
                            ),
                            Expanded(
                              child: TestSecondaryButton(
                                label: 'Rehacer el test',
                                icon: LucideIcons.rotateCcw,
                                onPressed: activos ? _c.rehacer : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!MediaQuery.disableAnimationsOf(context))
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: 180,
                  child: IgnorePointer(
                    child: ExcludeSemantics(
                      child: AnimatedBuilder(
                        animation: _confeti,
                        builder: (context, _) => CustomPaint(
                          key: ResultView.confetiKey,
                          painter: PintorDelConfeti(_confeti.value),
                        ),
                      ),
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

/// Ulises a 34 px con `headline` y, si llega, `tiebreakOutcome`.
class _UlisesDelResultado extends StatelessWidget {
  const _UlisesDelResultado({required this.texto, required this.foco});

  final String texto;
  final FocusNode foco;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: Focus(
        focusNode: foco,
        child: UlisesBubble(text: texto, avatarSize: 34, fontSize: 13),
      ),
    );
  }
}

/// Los colores de la tarjeta de la número uno en el tema.
class ColoresDeLaTarjeta {
  ColoresDeLaTarjeta(TestSpecialty? e, Brightness b)
    : oscuro = b == Brightness.dark,
      color = colorDeEspecialidad(e, b) ?? MaterialTheme.iconoNaranja(b) {
    final tarjeta = MaterialTheme.cardBg(b);
    if (oscuro) {
      fondo = tinte(color, tarjeta, 0.18);
      tinta = MaterialTheme.textPrimary(b);
      titulo = colorQueSeLee(color, fondo: fondo, respaldo: tinta);
      insigniaTexto = colorQueSeLee(
        color,
        fondo: MaterialTheme.testAiBadgeBg(b),
        respaldo: tinta,
      );
    } else {
      fondo = color;
      // El blanco sobre el color de la ganadora, o la tinta si no llega.
      tinta = colorQueSeLee(
        Colors.white,
        fondo: color,
        respaldo: MaterialTheme.textPrimary(b),
      );
      titulo = tinta;
      insigniaTexto = tinta;
    }
  }

  final bool oscuro;
  final Color color;
  late final Color fondo;
  late final Color tinta;
  late final Color titulo;
  late final Color insigniaTexto;
}

class TarjetaGanadora extends StatelessWidget {
  const TarjetaGanadora({
    super.key,
    required this.resultado,
    required this.contenido,
    required this.avance,
    required this.motivoAbierto,
    required this.onMotivo,
  });

  final SpecialtyTestResult resultado;
  final SpecialtyTestContent contenido;

  /// De 0 a 1, el avance del giro y de la cuenta de la afinidad.
  final double avance;
  final bool motivoAbierto;
  final VoidCallback onMotivo;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final r = resultado;
    final primera = r.ranking.first;
    final especialidad = contenido.specialtyByKey(primera.key);
    final k = ColoresDeLaTarjeta(especialidad, b);
    final nombres = r.winners.map((w) => w.name).toList();
    final afinidad = (primera.affinity * avance).round();
    final resumen = r.tie
        ? 'Empate, ${nombres.join(' y ')}, ${primera.affinity} % de afinidad'
        : 'Tu n.º 1, ${primera.name}, ${primera.affinity} % de afinidad';
    final motivo = r.reason ?? '';
    // Un solo nodo con el resumen y el motivo, y «Leer más» como su botón
    // hijo (RF-TEST-13).
    final etiqueta = [
      resumen,
      if (motivo.isNotEmpty)
        r.reasonByAi ? 'Motivo redactado con IA. $motivo' : motivo,
    ].join('. ');
    final tarjeta = Semantics(
      container: true,
      label: etiqueta,
      child: Container(
        key: ResultView.tarjetaKey,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
        decoration: BoxDecoration(
          color: k.oscuro ? k.fondo : null,
          gradient: k.oscuro
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [k.color, oscurecido(k.color)],
                ),
          borderRadius: BorderRadius.circular(22),
          border: k.oscuro
              ? Border.all(color: k.color.withValues(alpha: 0.35))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // El resumen y el motivo se leen en la etiqueta de la tarjeta.
            ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: k.tinta.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Icon(
                          iconoDelTest(especialidad?.icon),
                          size: 14,
                          color: k.tinta,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          r.tie ? 'Empate' : 'Tu n.º 1',
                          style: TextStyle(
                            color: k.tinta,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: _dorado,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$afinidad % afinidad',
                          style: const TextStyle(
                            color: _tintaDorada,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  for (final nombre in nombres)
                    Text(
                      nombre,
                      style: TextStyle(
                        color: k.titulo,
                        fontSize: 20.5,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                  const SizedBox(height: 8),
                  MedidorDeAfinidad(
                    fraccion: afinidad / 100,
                    pista: k.tinta.withValues(alpha: 0.24),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 9),
            MotivoDelResultado(
              texto: motivo,
              porIa: r.reasonByAi,
              colores: k,
              abierto: motivoAbierto,
              onTap: onMotivo,
            ),
          ],
        ),
      ),
    );
    // El giro de entrada, 600 ms, una sola vez. Al terminar, la tarjeta
    // sigue dentro del mismo Opacity y del mismo Transform, porque quitarlos
    // cambiaría el árbol y el motivo perdería lo que midió.
    return Opacity(
      opacity: avance.clamp(0.0, 1.0),
      child: Transform(
        alignment: Alignment.center,
        transform: avance >= 1
            ? Matrix4.identity()
            : (Matrix4.identity()
                ..setEntry(3, 2, 0.0014)
                ..rotateY(-70 * math.pi / 180 * (1 - avance))),
        child: tarjeta,
      ),
    );
  }
}

/// El medidor de 6 px, decorativo porque el número está en la pastilla.
class MedidorDeAfinidad extends StatelessWidget {
  const MedidorDeAfinidad({
    super.key,
    required this.fraccion,
    required this.pista,
  });

  final double fraccion;
  final Color pista;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 6,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: pista)),
            FractionallySizedBox(
              widthFactor: fraccion.clamp(0.0, 1.0),
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFC94D), Color(0xFFFFB020)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// El motivo, cortado en cuatro líneas con «Leer más», y la insignia «IA»
/// si lo redactó Cohere.
class MotivoDelResultado extends StatefulWidget {
  const MotivoDelResultado({
    super.key,
    required this.texto,
    required this.porIa,
    required this.colores,
    required this.abierto,
    required this.onTap,
  });

  final String texto;
  final bool porIa;
  final ColoresDeLaTarjeta colores;
  final bool abierto;
  final VoidCallback onTap;

  @override
  State<MotivoDelResultado> createState() => _MotivoState();
}

class _MotivoState extends State<MotivoDelResultado> {
  static const TextStyle _estilo = TextStyle(fontSize: 12.5, height: 1.38);

  final GlobalKey _parrafo = GlobalKey(debugLabel: 'motivo');

  /// Si el motivo cerrado pasa de cuatro líneas. Se lee del párrafo que se
  /// pinta, con la familia y el espaciado del tema y con la insignia, porque
  /// una medida aparte no los lleva y se equivoca justo en los largos de los
  /// motivos del contenido.
  bool _corta = false;

  void _leerElParrafo() {
    if (!mounted || widget.abierto) return;
    final parrafo = _parrafo.currentContext?.findRenderObject();
    if (parrafo is! RenderParagraph || !parrafo.hasSize) return;
    final corta = parrafo.didExceedMaxLines;
    if (corta != _corta) setState(() => _corta = corta);
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final estilo = _estilo.copyWith(color: widget.colores.tinta);
    final texto = widget.texto;
    final porIa = widget.porIa;
    final abierto = widget.abierto;
    final colores = widget.colores;
    // Depende de la escala de texto, así que un cambio vuelve a leer el
    // párrafo.
    MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        // Tras cada layout con otro ancho o con otro motivo, lee si el
        // párrafo pintado se cortó.
        WidgetsBinding.instance.addPostFrameCallback((_) => _leerElParrafo());
        final corta = _corta;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // El motivo se lee en la etiqueta de la tarjeta.
            ExcludeSemantics(
              child: Text.rich(
                key: _parrafo,
                TextSpan(
                  children: [
                    if (porIa)
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Container(
                          margin: const EdgeInsets.only(right: 5),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: MaterialTheme.testAiBadgeBg(b),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.sparkles,
                                size: 9,
                                color: colores.insigniaTexto,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'IA',
                                style: TextStyle(
                                  color: colores.insigniaTexto,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    TextSpan(text: texto),
                  ],
                ),
                style: estilo,
                maxLines: abierto ? null : 4,
                overflow: abierto ? null : TextOverflow.ellipsis,
              ),
            ),
            if (corta || abierto)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onTap,
                  style: TextButton.styleFrom(
                    foregroundColor: colores.tinta,
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    abierto ? 'Leer menos' : 'Leer más',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

/// La fila de electivos de la ganadora, o de las dos con empate, con «Ver».
class FilaDeElectivos extends StatelessWidget {
  const FilaDeElectivos({
    super.key,
    required this.ganadoras,
    required this.empate,
  });

  final List<TestSpecialty> ganadoras;
  final bool empate;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    if (ganadoras.isEmpty) return const SizedBox.shrink();
    final primera = ganadoras.first;
    final color =
        colorDeEspecialidad(primera, b) ?? MaterialTheme.iconoNaranja(b);
    final baldosa = tinte(color, MaterialTheme.cardBg(b), 0.13);
    final n = primera.electives.length;
    final cortos = empate
        ? [
            for (final g in ganadoras)
              if (g.electives.isNotEmpty) g.electives.first.displayName,
          ]
        : primera.electives.take(2).map((e) => e.displayName).toList();
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: MaterialTheme.cardBg(b),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: MaterialTheme.testLine(b)),
      ),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: baldosa,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                LucideIcons.bookOpen,
                size: 17,
                color: colorQueSeLee(
                  color,
                  fondo: baldosa,
                  respaldo: MaterialTheme.textPrimary(b),
                  esTexto: false,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  empate
                      ? 'Electivos de las dos'
                      : (n == 1 ? '1 electivo' : '$n electivos'),
                  style: TextStyle(
                    color: MaterialTheme.textPrimary(b),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (cortos.isNotEmpty)
                  Text(
                    cortos.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: MaterialTheme.testMuted(b),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => mostrarElectivos(context, ganadoras),
            style: TextButton.styleFrom(
              foregroundColor: MaterialTheme.testAccentText(b),
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ver',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
                ExcludeSemantics(
                  child: Icon(LucideIcons.chevronRight, size: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EncabezadoDeLasDemas extends StatelessWidget {
  const EncabezadoDeLasDemas({super.key});

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final gris = MaterialTheme.testMuted(b);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              'También te puede interesar',
              style: TextStyle(
                color: MaterialTheme.textPrimary(b),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ExcludeSemantics(
            child: Icon(LucideIcons.heart, size: 12, color: gris),
          ),
          const SizedBox(width: 4),
          Text(
            'guárdala',
            style: TextStyle(
              color: gris,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Una fila desde el puesto 2 (o el 3 con empate), con su corazón de 48 px
/// o, si es la principal, la estrella con «Tu principal».
class FilaDelRanking extends StatelessWidget {
  const FilaDelRanking({
    super.key,
    required this.puesto,
    required this.entrada,
    required this.especialidad,
    required this.primera,
    required this.marcada,
    required this.esPrincipal,
    required this.onCorazon,
  });

  final int puesto;
  final RankingEntry entrada;
  final TestSpecialty? especialidad;
  final bool primera;
  final bool marcada;
  final bool esPrincipal;
  final VoidCallback? onCorazon;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final pagina = MaterialTheme.pageBg(b);
    final color =
        colorDeEspecialidad(especialidad, b) ?? MaterialTheme.iconoNaranja(b);
    final baldosa = tinte(color, MaterialTheme.cardBg(b), 0.14);
    final etiqueta =
        'Puesto $puesto, ${entrada.name}, ${entrada.affinity} % de afinidad'
        '${esPrincipal ? ', Tu principal' : ''}';
    return Container(
      constraints: const BoxConstraints(minHeight: 53),
      decoration: BoxDecoration(
        border: primera
            ? null
            : Border(top: BorderSide(color: MaterialTheme.testLine(b))),
      ),
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: etiqueta,
        child: Row(
          children: [
            ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.only(left: 4, top: 6, bottom: 6),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: baldosa,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        iconoDelTest(especialidad?.icon),
                        size: 17,
                        color: color,
                      ),
                    ),
                    Positioned(
                      left: -6,
                      top: -6,
                      child: Container(
                        width: 17,
                        height: 17,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: MaterialTheme.textPrimary(b),
                          shape: BoxShape.circle,
                          border: Border.all(color: pagina, width: 2),
                        ),
                        child: Text(
                          '$puesto',
                          style: TextStyle(
                            color: pagina,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            entrada.name,
                            style: TextStyle(
                              color: MaterialTheme.textPrimary(b),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${entrada.affinity} %',
                          style: TextStyle(
                            color: colorQueSeLee(
                              color,
                              fondo: pagina,
                              respaldo: MaterialTheme.textPrimary(b),
                            ),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: SizedBox(
                        height: 4,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ColoredBox(
                                color: MaterialTheme.testTrack(b),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: entrada.affinity / 100,
                              child: ColoredBox(color: color),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
            if (esPrincipal)
              Padding(
                padding: const EdgeInsets.only(right: 2),
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: MaterialTheme.testAccentText(b),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Tu principal',
                        style: TextStyle(
                          color: MaterialTheme.testAccentText(b),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Semantics(
                button: true,
                toggled: marcada,
                label: marcada
                    ? 'Quitar ${entrada.name} de tus intereses'
                    : 'Marcar ${entrada.name} como interés',
                excludeSemantics: true,
                onTap: onCorazon,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    key: ResultView.corazonKey(entrada.specialtyId),
                    onPressed: onCorazon,
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      marcada ? Icons.favorite_rounded : LucideIcons.heart,
                      size: 21,
                      color: marcada
                          ? colorQueSeLee(
                              color,
                              fondo: pagina,
                              respaldo: MaterialTheme.textPrimary(b),
                              esTexto: false,
                            )
                          : MaterialTheme.testHeartOff(b),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// La hoja «¿Cuál eliges como principal?» del empate (decisión abierta 11).
class HojaDelEmpate extends StatelessWidget {
  const HojaDelEmpate({super.key, required this.ganadoras});

  final List<RankingEntry> ganadoras;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: MaterialTheme.sheetBg(b),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    '¿Cuál eliges como principal?',
                    style: TextStyle(
                      color: MaterialTheme.textPrimary(b),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                for (final g in ganadoras) ...[
                  TestPrimaryButton(
                    label: g.name,
                    height: 48,
                    onPressed: () => Navigator.of(context).pop(g.specialtyId),
                  ),
                  const SizedBox(height: 8),
                ],
                TestSecondaryButton(
                  label: 'Cancelar',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Confeti decorativo, una sola vez. Semilla fija para que las pruebas vean
/// siempre lo mismo.
class PintorDelConfeti extends CustomPainter {
  PintorDelConfeti(this.t);

  final double t;

  static const List<Color> _colores = [
    Color(0xFFFF6600),
    Color(0xFFFFB020),
    Color(0xFF22C55E),
    Color(0xFF2563EB),
    Color(0xFFC0267E),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final azar = math.Random(7);
    final pincel = Paint();
    for (var i = 0; i < 28; i++) {
      final x = azar.nextDouble() * size.width;
      final caida = size.height * (0.2 + azar.nextDouble() * 0.8) * t;
      pincel.color = _colores[i % _colores.length].withValues(
        alpha: (1 - t).clamp(0.0, 1.0),
      );
      canvas.save();
      canvas.translate(x, caida);
      canvas.rotate(azar.nextDouble() * math.pi * t * 4);
      canvas.drawRect(const Rect.fromLTWH(-3, -1.5, 6, 3), pincel);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(PintorDelConfeti old) => old.t != t;
}
