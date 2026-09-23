// lib/pages/time_blocks/time_block_list_page.dart
// RF-BLQ-8: la lista «Mis bloques». Todos los bloques guardados de la alumna,
// con su color, nombre, días, horas y fechas, y los avisos de la fila: si ya
// terminó o si ninguno de sus días marcados cae entre sus fechas. Tocar una
// fila ofrece editar o borrar el bloque, con el mismo código que la hoja de
// RF-BLQ-5 (editarBloque y borrarBloque, time_block_actions_sheet.dart). Solo
// cambia el cuerpo de la confirmación de borrado: aquí no se tocó ningún día.
//
// Ningún widget lee JSON ni habla HTTP: todo sale de TimeBlockListController,
// que lee TimeBlocksService.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../configs/course_colors.dart';
import '../../configs/themes.dart';
import '../../models/time_block_model.dart';
import 'time_block_actions_sheet.dart';
import 'time_block_form_page.dart';
import 'time_block_list_controller.dart';

class TimeBlockListPage extends GetView<TimeBlockListController> {
  const TimeBlockListPage({super.key});

  /// El título de la pantalla y la etiqueta del botón del horario.
  static const String titulo = 'Mis bloques';
  static const String sinBloques = 'Todavía no tienes bloques propios.';
  static const String errorDeCarga = 'No se pudieron cargar tus bloques.';
  static const String reintentar = 'Reintentar';
  static const String terminado = 'Terminó';
  static const String sinDiasReales =
      'Ningún día marcado cae entre sus fechas';

  /// El cuerpo de la confirmación de borrado desde la lista. El de la hoja de
  /// un día ([TimeBlockActionsSheet.borrarCuerpo]) termina en «no solo este»,
  /// y aquí no se tocó ningún día al que eso se refiera.
  static String borrarCuerpo(String titulo) =>
      'Se borra "$titulo" con todos sus días.';

  /// El color del aviso «Terminó»: el texto atenuado del tema. `textMuted`
  /// no alcanza en oscuro (#787890 da 3,86:1 sobre la fila), y este llega a
  /// 7,58:1 en claro (#475569 sobre #FFFFFF) y 4,80:1 en oscuro (#8888A0
  /// sobre #1E1E24). Los avisos van en 12 px w700 y piden 4,5:1.
  static Color colorTerminado(Brightness b) => MaterialTheme.textDimmed(b);

  /// El color del aviso «Ningún día marcado cae entre sus fechas». El naranja
  /// oscuro del tema (#D45500) da 4,12:1 sobre la fila blanca y 4,03:1 sobre
  /// la oscura, así que en claro va uno más oscuro (#B34700, 5,50:1) y en
  /// oscuro el naranja claro que el tema oscuro usa como `secondary`
  /// (#FF8C42, 7,17:1 sobre #1E1E24).
  static Color colorSinDiasReales(Brightness b) => b == Brightness.light
      ? const Color(0xFFB34700)
      : MaterialTheme.darkScheme().secondary;

  /// Key de la fila de un bloque, por su id.
  static Key filaKey(int id) => ValueKey<String>('mis-bloques-fila-$id');

  /// Key del círculo con el color de un bloque, por su id.
  static Key colorKey(int id) => ValueKey<String>('mis-bloques-color-$id');

  /// Los días en orden de la semana, con las etiquetas del formulario, y las
  /// horas como las escribe la hoja de RF-BLQ-5: "Lu, Mi · 14:00 a 18:00".
  static String diasYHoras(TimeBlockRule regla) {
    final dias = <int>{
      for (final d in regla.daysOfWeek)
        if (d >= 1 && d <= 7) d,
    }.toList()
      ..sort();
    final horas = rangoDeHoras(regla.startTime, regla.endTime);
    if (dias.isEmpty) return horas;
    final etiquetas =
        dias.map((d) => TimeBlockFormPage.diasLabels[d - 1]).join(', ');
    return '$etiquetas · $horas';
  }

  /// "Del 01/09/2026 al 15/12/2026".
  static String fechasDelBloque(TimeBlockRule regla) =>
      'Del ${fechaCorta(regla.startDate)} al ${fechaCorta(regla.endDate)}';

  /// `"YYYY-MM-DD"` → "dd/mm/aaaa". Lo que no tenga esa forma se muestra tal
  /// cual: no se inventa otra fecha.
  static String fechaCorta(String iso) {
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(iso);
    return m == null ? iso : '${m[3]}/${m[2]}/${m[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.brightnessOf(context);

    return Scaffold(
      backgroundColor: MaterialTheme.pageBg(brightness),
      appBar: AppBar(title: const Text(titulo)),
      body: Obx(() {
        // Todo lo reactivo se lee ANTES de decidir qué pintar: así el Obx
        // queda suscrito a las reglas, a la carga y al error aunque hoy salga
        // por el primer return.
        final hoy = controller.hoy;
        final bloques = controller.bloquesOrdenados(hoy);
        final cargando = controller.cargando;
        final cargado = controller.cargado;
        final conError = controller.conError;

        // El error manda aunque queden bloques de antes: borrar uno no lo
        // quita de la lista hasta que llega la recarga, y si esa recarga
        // falló lo que queda puede estar viejo.
        if (conError) {
          return _EstadoDeLaLista(
            icono: Icons.wifi_off_rounded,
            texto: errorDeCarga,
            onReintentar: controller.reintentar,
          );
        }
        if (bloques.isEmpty) {
          // Sin ninguna carga todavía no se sabe si hay bloques: el horario
          // los pide después de sus días.
          if (cargando || !cargado) {
            return const Center(child: CircularProgressIndicator());
          }
          return const _EstadoDeLaLista(
            icono: Icons.event_note_outlined,
            texto: sinBloques,
          );
        }
        // Una recarga en curso con bloques en pantalla no los tapa: el service
        // recarga sin vaciar después de cada escritura, y la lista no
        // parpadea. SingleChildScrollView y no ListView: son 20 como mucho
        // (el tope del servidor) y así todas las filas existen en el árbol.
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final regla in bloques)
                _FilaDeBloque(
                  regla: regla,
                  terminado: bloqueTerminado(regla, hoy),
                  sinDiasReales: bloqueSinDiasReales(regla),
                  onTap: () => _abrirAcciones(context, regla),
                ),
            ],
          ),
        );
      }),
    );
  }

  /// La hoja de una fila: editar o borrar el bloque entero. Las dos acciones
  /// son las de la hoja de RF-BLQ-5, con su guarda y su confirmación.
  ///
  /// [context] es el de la pantalla y solo se usa antes del primer `await`;
  /// el navegador y el messenger se toman al empezar, como en
  /// [mostrarAccionesDeBloque].
  Future<void> _abrirAcciones(BuildContext context, TimeBlockRule regla) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final accion = await showModalBottomSheet<AccionDeBloque>(
      context: context,
      builder: (_) => _AccionesDeLaFila(regla: regla),
    );
    if (accion == null) return;
    // Como en la hoja de un día: un «Deshacer» que siguiera en pantalla
    // actuaría sobre un bloque que la alumna acaba de editar o borrar.
    messenger.hideCurrentSnackBar();
    if (accion == AccionDeBloque.editar) {
      // Sin rotación que devolver: la lista ya es vertical, como el
      // formulario.
      await editarBloque(regla);
    } else if (accion == AccionDeBloque.borrar) {
      await borrarBloque(
        navigator,
        messenger,
        id: regla.id,
        titulo: regla.title,
        cuerpo: TimeBlockListPage.borrarCuerpo(regla.title),
      );
    }
  }
}

/// Una fila: el color, el nombre, los días con las horas, las fechas y, si
/// corresponde, sus avisos.
class _FilaDeBloque extends StatelessWidget {
  const _FilaDeBloque({
    required this.regla,
    required this.terminado,
    required this.sinDiasReales,
    required this.onTap,
  });

  final TimeBlockRule regla;
  final bool terminado;
  final bool sinDiasReales;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);
    final color =
        parseHexColor(regla.colorHex) ?? Theme.of(context).colorScheme.outline;
    final detalle = TextStyle(
      fontSize: 13,
      color: MaterialTheme.textSecondary(b),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        key: TimeBlockListPage.filaKey(regla.id),
        onTap: onTap,
        tileColor: MaterialTheme.cardBg(b),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: MaterialTheme.borderColor(b)),
        ),
        contentPadding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        titleAlignment: ListTileTitleAlignment.top,
        leading: Container(
          key: TimeBlockListPage.colorKey(regla.id),
          width: 20,
          height: 20,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        minLeadingWidth: 20,
        title: Text(
          regla.title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: MaterialTheme.textPrimary(b),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(TimeBlockListPage.diasYHoras(regla), style: detalle),
            const SizedBox(height: 2),
            Text(TimeBlockListPage.fechasDelBloque(regla), style: detalle),
            if (terminado) ...[
              const SizedBox(height: 6),
              Text(
                TimeBlockListPage.terminado,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: TimeBlockListPage.colorTerminado(b),
                ),
              ),
            ],
            if (sinDiasReales) ...[
              const SizedBox(height: 6),
              Text(
                TimeBlockListPage.sinDiasReales,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: TimeBlockListPage.colorSinDiasReales(b),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// La hoja que abre una fila. Devuelve la acción elegida con `Navigator.pop`;
/// quien la abrió la ejecuta. Los textos son los de la hoja de RF-BLQ-5.
class _AccionesDeLaFila extends StatelessWidget {
  const _AccionesDeLaFila({required this.regla});

  final TimeBlockRule regla;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.brightnessOf(context);
    void elegir(AccionDeBloque accion) => Navigator.of(context).pop(accion);

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    regla.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: MaterialTheme.textPrimary(brightness),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    TimeBlockListPage.diasYHoras(regla),
                    style: TextStyle(
                      fontSize: 13,
                      color: MaterialTheme.textMuted(brightness),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text(TimeBlockActionsSheet.editar),
              onTap: () => elegir(AccionDeBloque.editar),
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text(
                TimeBlockActionsSheet.borrar,
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () => elegir(AccionDeBloque.borrar),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carga fallida o lista vacía: un ícono, el texto y, si hay qué reintentar,
/// el botón. El botón copia el de `ErrorRetry` (lib/components); ese widget
/// no se usa porque pide además un párrafo que la spec no tiene.
class _EstadoDeLaLista extends StatelessWidget {
  const _EstadoDeLaLista({
    required this.icono,
    required this.texto,
    this.onReintentar,
  });

  final IconData icono;
  final String texto;
  final VoidCallback? onReintentar;

  @override
  Widget build(BuildContext context) {
    final b = Theme.brightnessOf(context);
    final colors = Theme.of(context).colorScheme;
    final reintentar = onReintentar;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 48, color: MaterialTheme.textMuted(b)),
            const SizedBox(height: 12),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MaterialTheme.textPrimary(b),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (reintentar != null) ...[
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: reintentar,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text(
                  TimeBlockListPage.reintentar,
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
