// lib/pages/time_blocks/time_block_actions_sheet.dart
// RF-BLQ-5: lo que pasa al tocar un bloque propio en el horario. Una hoja con
// lo que se puede hacer con ESE día y con el bloque entero:
//   - Editar el bloque (todas las semanas): abre /bloque con la regla.
//   - Cancelar solo este día.
//   - Cambiar la hora solo este día.
//   - Volver al patrón, solo si ese día ya se salió de él.
//   - Borrar el bloque, con confirmación.
//
// No habla HTTP: cada acción llama a TimeBlocksService, que recarga la ventana
// del horario al terminar, así que la grilla se entera sola. Un error se
// muestra con el mensaje que llegó del servidor, tal cual (RF-BLQ-2).
//
// Editar y borrar el bloque entero ([editarBloque] y [borrarBloque]) también
// se usan desde la lista «Mis bloques» (RF-BLQ-8).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../configs/themes.dart';
import '../../models/time_block_model.dart';
import '../../services/time_blocks_service.dart';
import 'time_block_form_controller.dart';
import 'time_block_form_page.dart';
import 'time_block_validators.dart';

/// Lo que la alumna eligió en la hoja.
enum AccionDeBloque { editar, cancelarDia, cambiarHora, volverAlPatron, borrar }

/// Las mismas dos listas que `HorarioPage._portraitOnly` y
/// `HorarioPage._scheduleOrientations` (horario.dart), que son privadas de esa
/// pantalla. Solo el horario rota ("Schedule-only rotation",
/// specs/features/schedule/schedule.spec.md): el formulario se abre en vertical
/// y al volver se devuelve la rotación del horario, igual que al tocar un curso
/// o el botón de agregar.
const List<DeviceOrientation> _soloVertical = [DeviceOrientation.portraitUp];
const List<DeviceOrientation> _orientacionesDelHorario = [
  DeviceOrientation.portraitUp,
  DeviceOrientation.landscapeLeft,
  DeviceOrientation.landscapeRight,
];

const List<String> _dias = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];
const List<String> _meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// Las horas de un bloque como las muestran sus pantallas: "14:00 a 18:00",
/// en `HH:MM`, como en el formulario. La usan la cabecera de esta hoja y cada
/// fila de «Mis bloques» (RF-BLQ-8), para que las dos las escriban igual.
String rangoDeHoras(String inicio, String fin) => '$inicio a $fin';

/// Qué día es y a qué hora, para la cabecera de la hoja:
/// "Lunes 21 de septiembre, 14:00 a 18:00". Las horas van en `HH:MM`, como en
/// el formulario. Si la fecha no se puede leer, quedan solo las horas: no se
/// inventa un día.
String resumenDelDia(TimeBlockOccurrence ocurrencia) {
  final horas = rangoDeHoras(ocurrencia.startTime, ocurrencia.endTime);
  final fecha = DateTime.tryParse(ocurrencia.date);
  if (fecha == null) return horas;
  final dia = _dias[fecha.weekday - 1];
  return '${dia[0].toUpperCase()}${dia.substring(1)} ${fecha.day} de '
      '${_meses[fecha.month - 1]}, $horas';
}

/// Abre la hoja de acciones de [ocurrencia] y hace lo que la alumna elija.
///
/// Lo llama el toque de un bloque propio en `HorarioPage._courseBlock`.
/// [cancelado] es true cuando el bloque tocado es un día cancelado, que la
/// grilla pinta tenue desde la regla (RF-BLQ-5): su hoja solo ofrece volver
/// al patrón.
///
/// [context] tiene que ser del horario montado, y solo se usa antes del primer
/// `await`: si la alumna gira el teléfono con la hoja abierta, la grilla
/// cambia de vista y ese contexto deja de existir. El navegador y el
/// messenger de la app no cambian, así que se toman al empezar.
Future<void> mostrarAccionesDeBloque(
  BuildContext context,
  TimeBlockOccurrence ocurrencia, {
  bool cancelado = false,
}) async {
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final service = TimeBlocksService.to;
  // El formulario edita la REGLA (todas las semanas), no esta ocurrencia.
  final regla =
      service.blocks.firstWhereOrNull((b) => b.id == ocurrencia.blockId);

  final accion = await showModalBottomSheet<AccionDeBloque>(
    context: context,
    builder: (_) => TimeBlockActionsSheet(
      ocurrencia: ocurrencia,
      puedeEditar: regla != null,
      cancelado: cancelado,
    ),
  );
  if (accion == null) return;
  // Otra acción deja viejo el «Deshacer» de una cancelación anterior: si la
  // alumna devolvió al patrón un día movido y después lo tocara, el día
  // volvería a moverse y la app desharía su última elección.
  messenger.hideCurrentSnackBar();

  final id = ocurrencia.blockId;
  final fecha = ocurrencia.date;
  switch (accion) {
    case AccionDeBloque.editar:
      if (regla == null) return;
      await editarBloque(regla, rotacionAlVolver: _orientacionesDelHorario);
    case AccionDeBloque.cancelarDia:
      final ok = await _intentar(
        navigator,
        messenger,
        () => service.setException(id, fecha, status: 'cancelled'),
      );
      if (!ok) return;
      // Un atajo: el día cancelado también se devuelve desde su hoja (la
      // grilla lo pinta tenue). Deshacer lo deja como estaba: en el patrón, o
      // en sus horas movidas si ya se había movido.
      Future<void> deshacer() => ocurrencia.moved
          ? service.setException(
              id,
              fecha,
              status: 'moved',
              startTime: ocurrencia.startTime,
              endTime: ocurrencia.endTime,
            )
          : service.clearException(id, fecha);
      _avisar(
        messenger,
        SnackBar(
          content: const Text(TimeBlockActionsSheet.diaCancelado),
          // Se cierra solo a los 4 s. Desde Flutter 3.38 un aviso con botón
          // se queda por omisión hasta que lo tocan: pasaba de pantalla en
          // pantalla y dejaba en cola los avisos de las otras.
          persist: false,
          action: SnackBarAction(
            label: TimeBlockActionsSheet.deshacer,
            onPressed: () => _intentar(navigator, messenger, deshacer),
          ),
        ),
      );
    case AccionDeBloque.cambiarHora:
      if (!navigator.mounted) return;
      final horas = await showDialog<({String inicio, String fin})>(
        context: navigator.context,
        builder: (_) => TimeBlockDayHoursDialog(
          inicio: ocurrencia.startTime,
          fin: ocurrencia.endTime,
        ),
      );
      if (horas == null) return;
      await _intentar(
        navigator,
        messenger,
        () => service.setException(
          id,
          fecha,
          status: 'moved',
          startTime: horas.inicio,
          endTime: horas.fin,
        ),
      );
    case AccionDeBloque.volverAlPatron:
      await _intentar(
        navigator,
        messenger,
        () => service.clearException(id, fecha),
      );
    case AccionDeBloque.borrar:
      await borrarBloque(
        navigator,
        messenger,
        id: id,
        titulo: ocurrencia.title,
      );
  }
}

/// Abre /bloque para editar [regla], el bloque entero (todas las semanas). La
/// usan esta hoja y la lista «Mis bloques» (RF-BLQ-8).
///
/// No abre nada mientras el formulario anterior siga cerrándose: es la misma
/// guarda que el botón de agregar (HorarioPage). get 4.7.3 borra el controller
/// del formulario recién al terminar la animación de salida, y antes de eso el
/// binding le daría a /bloque el viejo, que ignora esta regla y queda por
/// liberar.
///
/// Con [rotacionAlVolver], el formulario se abre fijado en vertical y al volver
/// se pide esa rotación: lo necesita el horario, que es la única pantalla que
/// rota. «Mis bloques» ya es vertical y no la pasa.
Future<void> editarBloque(
  TimeBlockRule regla, {
  List<DeviceOrientation>? rotacionAlVolver,
}) async {
  if (Get.isRegistered<TimeBlockFormController>()) return;
  if (rotacionAlVolver != null) {
    await SystemChrome.setPreferredOrientations(_soloVertical);
  }
  await Get.toNamed<dynamic>('/bloque', arguments: regla);
  if (rotacionAlVolver != null) {
    await SystemChrome.setPreferredOrientations(rotacionAlVolver);
  }
}

/// Pide confirmación y, si la alumna confirma, borra el bloque [id] con todos
/// sus días. La usan esta hoja y la lista «Mis bloques» (RF-BLQ-8), así que
/// las dos piden la confirmación con el mismo título y los mismos botones.
///
/// El cuerpo es [TimeBlockActionsSheet.borrarCuerpo], que habla del día
/// tocado («no solo este»), salvo que llegue [cuerpo]: la lista pasa el suyo,
/// porque ahí no se tocó ningún día.
///
/// Recibe [navigator] y [messenger] y no un contexto: quien la llama los toma
/// antes de su primer `await`, porque su contexto puede no sobrevivir a la
/// espera (la hoja del horario, si la alumna gira el teléfono).
Future<void> borrarBloque(
  NavigatorState navigator,
  ScaffoldMessengerState messenger, {
  required int id,
  required String titulo,
  String? cuerpo,
}) async {
  if (!navigator.mounted) return;
  final confirmar = await showDialog<bool>(
    context: navigator.context,
    builder: (ctx) => AlertDialog(
      key: TimeBlockActionsSheet.confirmarBorradoKey,
      title: const Text(TimeBlockActionsSheet.borrarTitulo),
      content: Text(cuerpo ?? TimeBlockActionsSheet.borrarCuerpo(titulo)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text(TimeBlockActionsSheet.cancelarLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text(
            TimeBlockActionsSheet.borrarConfirmar,
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
  // Cerrar el diálogo con el barrier o con back devuelve null: no borra.
  if (confirmar != true) return;
  await _intentar(navigator, messenger, () => TimeBlocksService.to.remove(id));
}

/// Corre una escritura del service y dice si salió bien. Si falla, lo avisa
/// con el mensaje que trae el error: el del servidor, tal cual.
///
/// Mientras viaja, un indicador sin texto tapa el horario. La escritura y la
/// recarga que la sigue pueden tardar hasta 30 s con el backend en frío, y
/// sin él la alumna no ve nada y el bloque sigue tocable: un segundo borrado
/// daría un error justo después de uno bueno, y cancelar y luego mover el
/// mismo día quedaría como dijera el orden de las peticiones. No se cierra
/// con el barrier ni con atrás, igual que el formulario mientras guarda.
Future<bool> _intentar(
  NavigatorState navigator,
  ScaffoldMessengerState messenger,
  Future<void> Function() escritura,
) async {
  final espera = navigator.mounted
      ? DialogRoute<void>(
          context: navigator.context,
          barrierDismissible: false,
          builder: (_) => const PopScope(
            canPop: false,
            child: Center(child: CircularProgressIndicator()),
          ),
        )
      : null;
  // Sin esperar su futuro: la ruta se quita en el finally.
  if (espera != null) navigator.push(espera);
  try {
    await escritura();
    return true;
  } on TimeBlocksFailure catch (e) {
    _avisar(messenger, SnackBar(content: Text(e.message)));
  } catch (e) {
    // Red de seguridad, como en el formulario: el service envuelve sus
    // errores en TimeBlocksFailure, pero si algo se le escapa la alumna
    // tiene que enterarse de que no se hizo.
    debugPrint('Error en una acción de bloque: $e');
    _avisar(
      messenger,
      const SnackBar(content: Text(TimeBlocksService.genericErrorMessage)),
    );
  } finally {
    // Se quita ESTA ruta, y solo si sigue en el navegador; nunca con un pop a
    // ciegas. Un 401 en plena escritura manda al login con offAllToLogin()
    // (api_client.dart), que ya se la llevó, y un pop cerraría el login.
    if (espera != null && espera.isActive) navigator.removeRoute(espera);
  }
  return false;
}

/// Muestra [aviso] en lugar del que esté en pantalla. El messenger pone en
/// cola lo que llega mientras otro aviso está a la vista: sin quitarlo, el
/// error de la acción siguiente esperaría a que se fuera el de «Deshacer».
void _avisar(ScaffoldMessengerState messenger, SnackBar aviso) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(aviso);
}

/// La hoja: qué bloque y qué día, y las acciones. Devuelve la elegida con
/// `Navigator.pop`; quien la abrió ([mostrarAccionesDeBloque]) la ejecuta.
class TimeBlockActionsSheet extends StatelessWidget {
  const TimeBlockActionsSheet({
    super.key,
    required this.ocurrencia,
    required this.puedeEditar,
    this.cancelado = false,
  });

  final TimeBlockOccurrence ocurrencia;

  /// Si la regla del bloque está a mano. Llega con las ocurrencias en la
  /// misma carga, así que falta solo si el service quedó a medias.
  final bool puedeEditar;

  /// Si es un día cancelado (la grilla lo pinta tenue). Entonces la hoja
  /// solo ofrece volver al patrón.
  final bool cancelado;

  static const String editar = 'Editar el bloque';
  static const String editarDetalle = 'Todas las semanas';
  static const String cancelarDia = 'Cancelar solo este día';
  static const String cambiarHora = 'Cambiar la hora solo este día';
  static const String volverAlPatron = 'Volver al patrón';
  static const String diaCanceladoDetalle = 'Este día está cancelado';
  static const String borrar = 'Borrar el bloque';

  static const String diaCancelado = 'Se canceló este día.';
  static const String deshacer = 'Deshacer';

  static const String borrarTitulo = '¿Borrar el bloque?';
  static String borrarCuerpo(String titulo) =>
      'Se borra "$titulo" con todos sus días, no solo este.';
  static const String borrarConfirmar = 'Borrar';

  /// Los dos botones de los diálogos (borrar y cambiar la hora).
  static const String cancelarLabel = 'Cancelar';
  static const String guardarLabel = 'Guardar';

  static const Key confirmarBorradoKey = Key('bloque-confirmar-borrado');
  static const Key cambiarHoraKey = Key('bloque-cambiar-hora');
  static const Key horaInicioKey = Key('bloque-dia-hora-inicio');
  static const Key horaFinKey = Key('bloque-dia-hora-fin');

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.brightnessOf(context);
    void elegir(AccionDeBloque accion) => Navigator.of(context).pop(accion);

    // SingleChildScrollView: la hoja modal mide como mucho 9/16 del alto, y
    // en la vista semanal (horizontal) sus acciones no entran sin scroll.
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
                    ocurrencia.title,
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
                    resumenDelDia(ocurrencia),
                    style: TextStyle(
                      fontSize: 13,
                      color: MaterialTheme.textMuted(brightness),
                    ),
                  ),
                ],
              ),
            ),
            if (cancelado)
              // Un día cancelado solo se devuelve al patrón (RF-BLQ-5): ese
              // día no se edita, no se cancela otra vez ni cambia de hora.
              ListTile(
                leading: const Icon(Icons.undo),
                title: const Text(volverAlPatron),
                subtitle: const Text(diaCanceladoDetalle),
                onTap: () => elegir(AccionDeBloque.volverAlPatron),
              )
            else ...[
              if (puedeEditar)
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text(editar),
                  subtitle: const Text(editarDetalle),
                  onTap: () => elegir(AccionDeBloque.editar),
                ),
              ListTile(
                leading: const Icon(Icons.event_busy_outlined),
                title: const Text(cancelarDia),
                onTap: () => elegir(AccionDeBloque.cancelarDia),
              ),
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text(cambiarHora),
                onTap: () => elegir(AccionDeBloque.cambiarHora),
              ),
              // El servidor manda `moved: true` en un día que se salió del
              // patrón. Un día cancelado tiene su propia hoja (arriba).
              if (ocurrencia.moved)
                ListTile(
                  leading: const Icon(Icons.undo),
                  title: const Text(volverAlPatron),
                  onTap: () => elegir(AccionDeBloque.volverAlPatron),
                ),
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text(
                  borrar,
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () => elegir(AccionDeBloque.borrar),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Cambiar la hora solo este día": los mismos campos y pickers que el
/// formulario ([TimeBlockPickerField] y `showTimePicker`) y el mismo
/// validador puro ([validarHoras]). Devuelve las dos horas en `HH:MM`, o null
/// si la alumna se arrepiente. No habla con el service.
class TimeBlockDayHoursDialog extends StatefulWidget {
  const TimeBlockDayHoursDialog({
    super.key,
    required this.inicio,
    required this.fin,
  });

  /// Las horas de ese día, en `HH:MM`.
  final String inicio;
  final String fin;

  @override
  State<TimeBlockDayHoursDialog> createState() =>
      _TimeBlockDayHoursDialogState();
}

class _TimeBlockDayHoursDialogState extends State<TimeBlockDayHoursDialog> {
  TimeOfDay? _inicio;
  TimeOfDay? _fin;
  String? _error;

  @override
  void initState() {
    super.initState();
    _inicio = TimeBlockFormController.horaDeTexto(widget.inicio);
    _fin = TimeBlockFormController.horaDeTexto(widget.fin);
  }

  String? _texto(TimeOfDay? t) =>
      t == null ? null : TimeBlockFormController.fmtHora(t);

  Future<TimeOfDay?> _elegir(TimeOfDay? actual, TimeOfDay respaldo) =>
      showTimePicker(
        context: context,
        initialTime: actual ?? respaldo,
        // Los mismos textos en español que el formulario (D7).
        helpText: TimeBlockFormPage.pickerHoraTitulo,
        cancelText: TimeBlockFormPage.pickerCancelar,
        confirmText: TimeBlockFormPage.pickerAceptar,
      );

  void _guardar() {
    final inicio = _texto(_inicio);
    final fin = _texto(_fin);
    final error = validarHoras(inicio, fin);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop((inicio: inicio!, fin: fin!));
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.brightnessOf(context);
    Widget label(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 12),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: MaterialTheme.textPrimary(brightness),
            ),
          ),
        );

    return AlertDialog(
      key: TimeBlockActionsSheet.cambiarHoraKey,
      // Se puede abrir desde la vista semanal, en horizontal: en un iPhone SE
      // eso deja 375 px de alto, y con las dos horas una debajo de la otra el
      // diálogo desbordaba. Van lado a lado, como en el formulario, y si aun
      // así no entra (letra grande), el contenido scrollea.
      scrollable: true,
      title: const Text(TimeBlockActionsSheet.cambiarHora),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    label('Hora de inicio'),
                    TimeBlockPickerField(
                      key: TimeBlockActionsSheet.horaInicioKey,
                      texto: _texto(_inicio) ?? '--:--',
                      icono: Icons.schedule,
                      brightness: brightness,
                      onTap: () async {
                        final elegida = await _elegir(
                          _inicio,
                          const TimeOfDay(hour: 14, minute: 0),
                        );
                        if (elegida == null || !mounted) return;
                        setState(() {
                          _inicio = elegida;
                          _error = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    label('Hora de fin'),
                    TimeBlockPickerField(
                      key: TimeBlockActionsSheet.horaFinKey,
                      texto: _texto(_fin) ?? '--:--',
                      icono: Icons.schedule,
                      brightness: brightness,
                      onTap: () async {
                        final elegida = await _elegir(
                          _fin,
                          const TimeOfDay(hour: 18, minute: 0),
                        );
                        if (elegida == null || !mounted) return;
                        setState(() {
                          _fin = elegida;
                          _error = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: const TextStyle(
                  color: MaterialTheme.primaryDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(TimeBlockActionsSheet.cancelarLabel),
        ),
        TextButton(
          onPressed: _guardar,
          child: const Text(TimeBlockActionsSheet.guardarLabel),
        ),
      ],
    );
  }
}
