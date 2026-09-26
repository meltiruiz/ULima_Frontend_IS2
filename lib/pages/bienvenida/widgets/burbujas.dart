// lib/pages/bienvenida/widgets/burbujas.dart
// Los grupos de Ulises, las respuestas del alumno, la tarjeta del
// consentimiento y los avisos del registro (RF-BIEN-5, RF-BIEN-7 y
// RF-BIEN-16). Cada grupo de Ulises se lee como «Ulises» seguido de sus
// burbujas, y cada respuesta como «Tú, <texto>».

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show FocusSemanticEvent;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../components/portal_consent/portal_consent_view.dart';
import '../../../components/skeleton.dart';
import '../../../configs/themes.dart';
import '../../../domain/bienvenida/bienvenida_turnos.dart';
import '../../specialty_test/widgets/question_view.dart' show emojisDeLaEscala;
import '../../specialty_test/widgets/ulises_bubble.dart';
import '../conversacion.dart';

class EntradaView extends StatelessWidget {
  const EntradaView({
    super.key,
    required this.entrada,
    required this.anterior,
    required this.primerGrupo,
    required this.resultado,
    this.conMovimiento = true,
    this.ocultarAvatar = false,
    this.claveDelAvatar,
    this.enfocar = false,
  });

  final EntradaDeLaConversacion entrada;
  final EntradaDeLaConversacion? anterior;

  /// Si es el primer grupo de Ulises, que lleva el avatar de 40 dp y el
  /// nombre.
  final bool primerGrupo;
  final Widget Function(BuildContext context, ResultadoDelTest entrada)
  resultado;
  final bool conMovimiento;

  /// Ulises es el avatar mientras salta desde el recibimiento, así que el
  /// del primer grupo y su nombre esperan a que se pose (RF-BIEN-2).
  final bool ocultarAvatar;

  /// El primer avatar del último grupo de Ulises, de donde sale a volar en
  /// el paso al horario (RF-BIEN-11).
  final GlobalKey? claveDelAvatar;

  /// Con lector, el foco pasa a esta entrada (RF-BIEN-16).
  final bool enfocar;

  @override
  Widget build(BuildContext context) {
    final hijo = switch (entrada) {
      final BurbujaDeUlises u => _BurbujaDeUlises(
        entrada: u,
        primeraDelGrupo: anterior is! BurbujaDeUlises,
        primerGrupo: primerGrupo,
        ocultarAvatar: ocultarAvatar,
        claveDelAvatar: claveDelAvatar,
      ),
      final RespuestaDelAlumno r => _Respuesta(entrada: r),
      final ResultadoDelTest r => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: resultado(context, r),
      ),
    };
    return _Enfocable(
      enfocar: enfocar,
      child: _Entra(conMovimiento: conMovimiento, child: hijo),
    );
  }
}

/// Con lector de pantalla, el foco pasa a la primera burbuja nueva de Ulises
/// (RF-BIEN-16). Cada entrada ya es un nodo de la lista, que recibe el foco y
/// el lector lee en su orden.
class _Enfocable extends StatefulWidget {
  const _Enfocable({required this.enfocar, required this.child});

  final bool enfocar;
  final Widget child;

  @override
  State<_Enfocable> createState() => _EnfocableState();
}

class _EnfocableState extends State<_Enfocable> {
  @override
  void initState() {
    super.initState();
    if (widget.enfocar) _enfocar();
  }

  @override
  void didUpdateWidget(_Enfocable anterior) {
    super.didUpdateWidget(anterior);
    if (widget.enfocar && !anterior.enfocar) _enfocar();
  }

  void _enfocar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.findRenderObject()?.sendSemanticsEvent(
        const FocusSemanticEvent(),
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Cada burbuja entra en 340 ms, subiendo 8 dp y de 98 % a 100 % con un
/// leve rebote. Con reducir movimiento, un fundido de 200 ms (RF-BIEN-15).
class _Entra extends StatelessWidget {
  const _Entra({required this.conMovimiento, required this.child});

  final bool conMovimiento;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 0, end: 1),
    duration: Duration(milliseconds: conMovimiento ? 340 : 200),
    curve: conMovimiento ? Curves.easeOutBack : Curves.linear,
    child: child,
    builder: (context, t, hijo) {
      final opacidad = t.clamp(0.0, 1.0);
      if (!conMovimiento) return Opacity(opacity: opacidad, child: hijo);
      return Opacity(
        opacity: opacidad,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - t)),
          child: Transform.scale(scale: 0.98 + 0.02 * t, child: hijo),
        ),
      );
    },
  );
}

class _BurbujaDeUlises extends StatelessWidget {
  const _BurbujaDeUlises({
    required this.entrada,
    required this.primeraDelGrupo,
    required this.primerGrupo,
    this.ocultarAvatar = false,
    this.claveDelAvatar,
  });

  final BurbujaDeUlises entrada;
  final bool primeraDelGrupo;
  final bool primerGrupo;
  final bool ocultarAvatar;
  final GlobalKey? claveDelAvatar;

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);
    final avatar = primerGrupo ? 40.0 : 28.0;
    final ancha = entrada.tipo == TipoDeBurbuja.consentimiento;
    return Padding(
      padding: EdgeInsets.only(top: primeraDelGrupo ? 12 : 6),
      child: LayoutBuilder(
        builder: (context, limites) {
          final maximo = limites.maxWidth * (ancha ? 0.92 : 0.74);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                key: claveDelAvatar,
                width: avatar,
                child: primeraDelGrupo
                    // Al posarse Ulises, su avatar queda en su lugar.
                    ? Opacity(
                        opacity: ocultarAvatar ? 0 : 1,
                        child: UlisesAvatar(size: avatar),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (primeraDelGrupo && primerGrupo)
                      // El nombre aparece en 250 ms al posarse Ulises.
                      AnimatedOpacity(
                        opacity: ocultarAvatar ? 0 : 1,
                        duration: const Duration(milliseconds: 250),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            TextosDeLaBienvenida.ulises,
                            style: TextStyle(
                              color: MaterialTheme.testMuted(b),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maximo),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: MaterialTheme.cardBg(b),
                          border: Border.all(color: MaterialTheme.testLine(b)),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(primeraDelGrupo ? 6 : 18),
                            topRight: const Radius.circular(18),
                            bottomLeft: const Radius.circular(18),
                            bottomRight: const Radius.circular(18),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          child: _Contenido(entrada: entrada),
                        ),
                      ),
                    ),
                    if (entrada.sello != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: SelloDeBloqueView(sello: entrada.sello!),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.entrada});

  final BurbujaDeUlises entrada;

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);
    final estilo = TextStyle(
      color: MaterialTheme.textPrimary(b),
      fontSize: 14,
      height: 1.35,
    );
    final negrita = estilo.copyWith(fontWeight: FontWeight.w700);
    final quieto = MediaQuery.disableAnimationsOf(context);
    switch (entrada.tipo) {
      case TipoDeBurbuja.cargando:
        // Sin movimiento, el esqueleto no pulsa (RF-BIEN-15).
        const esqueleto = SkeletonBox(width: 180, height: 14);
        return quieto ? esqueleto : const SkeletonPulse(child: esqueleto);
      case TipoDeBurbuja.error:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              LucideIcons.circleAlert,
              size: 16,
              color: MaterialTheme.testAccentText(b),
            ),
            const SizedBox(width: 6),
            Flexible(child: Text(entrada.texto, style: estilo)),
          ],
        );
      case TipoDeBurbuja.esperando:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(entrada.texto, style: estilo)),
            const SizedBox(width: 8),
            SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(
                // Sin movimiento no gira (RF-BIEN-15 y RF-TEST-13).
                value: quieto ? 0.75 : null,
                strokeWidth: 2,
                color: MaterialTheme.testAccent(b),
              ),
            ),
          ],
        );
      case TipoDeBurbuja.consentimiento:
        // Los textos literales de PortalConsentView (RF-BIEN-7 y RF-REC-6).
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              PortalConsentView.titulo,
              style: negrita.copyWith(fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(PortalConsentView.introduccion, style: estilo),
            const SizedBox(height: 4),
            for (final dato in PortalConsentView.datosImportados)
              Text('· $dato', style: estilo),
            const SizedBox(height: 6),
            Text(PortalConsentView.finalidad, style: estilo),
            const SizedBox(height: 6),
            Text(PortalConsentView.contrasena, style: negrita),
          ],
        );
      case TipoDeBurbuja.avisos:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entrada.titulo ?? '', style: negrita),
            for (final l in entrada.lineas) Text('· $l', style: estilo),
          ],
        );
      case TipoDeBurbuja.texto:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entrada.titulo != null) Text(entrada.titulo!, style: negrita),
            Text(entrada.texto, style: estilo),
          ],
        );
    }
  }
}

class _Respuesta extends StatelessWidget {
  const _Respuesta({required this.entrada});

  final RespuestaDelAlumno entrada;

  /// El emoji de la escala queda fuera de la semántica (RF-BIEN-16).
  String get _lectura {
    var texto = entrada.texto;
    for (final e in emojisDeLaEscala) {
      if (texto.startsWith('$e ')) texto = texto.substring(e.length + 1);
    }
    return 'Tú, $texto';
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);
    final tinta = MaterialTheme.bienvenidaPropiaTinta(b);
    final estilo = TextStyle(
      color: tinta,
      fontSize: 14,
      fontWeight: FontWeight.w700,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Align(
        alignment: Alignment.centerRight,
        child: FractionallySizedBox(
          widthFactor: 0.72,
          alignment: Alignment.centerRight,
          child: Align(
            alignment: Alignment.centerRight,
            child: Semantics(
              label: _lectura,
              excludeSemantics: true,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: MaterialTheme.bienvenidaPropia(b),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(6),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (entrada.secreta) ...[
                        Icon(LucideIcons.lock, size: 14, color: tinta),
                        const SizedBox(width: 6),
                      ],
                      if (entrada.conGoogle) ...[
                        SvgPicture.asset(
                          'assets/images/google_logo.svg',
                          width: 16,
                          height: 16,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(child: Text(entrada.texto, style: estilo)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
