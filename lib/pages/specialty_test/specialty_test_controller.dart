// lib/pages/specialty_test/specialty_test_controller.dart
// El recorrido del test de especialidad (RF-TEST-1 a RF-TEST-11), con la
// bienvenida, las preguntas, el atrás, la pausa, la evaluación, los
// desempates, los reintentos y los guardados del resultado.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../models/specialty_test_models.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/specialty_test_service.dart';
import 'specialty_test_logic.dart';

/// De dónde se abre `/test-especialidad`.
enum OrigenDelTest { asistente, perfil }

/// La pantalla que muestra la ruta.
enum FaseDelTest { bienvenida, pregunta, espera, resultado }

/// La carga del contenido en la bienvenida.
enum EstadoDeCarga { cargando, lista, error }

/// Con qué se cierra la ruta. El asistente pasa a la selección manual con
/// [seleccionManual]; un cierre sin valor lo deja en el paso de carrera.
enum SalidaDelTest { seleccionManual, terminado }

enum TipoDeAviso { error, info, exito }

/// Un aviso pasajero (RF-TEST-11).
class AvisoDelTest {
  const AvisoDelTest(this.tipo, this.mensaje, {this.titulo});

  final TipoDeAviso tipo;
  final String mensaje;

  /// Solo el aviso de éxito del Perfil lleva título.
  final String? titulo;
}

/// Lo que el controlador le pide a la pantalla. La ruta usa la versión con
/// GetX de `specialty_test_page.dart`, y las pruebas, una falsa.
abstract class SpecialtyTestUi {
  /// Cierra la ruta del test.
  void cerrar([SalidaDelTest? salida]);

  /// Termina el asistente con `Get.offAllNamed('/home')`.
  void irAlHome();

  void avisar(AvisoDelTest aviso);

  /// Muestra el diálogo con [mensaje] y «Empezar de nuevo», y termina cuando
  /// el alumno lo toca.
  Future<void> pedirReinicio(String mensaje);
}

/// Textos propios de la app que salen del controlador.
class TextosDelTest {
  static const String sinConexion =
      'No pudimos conectarnos. Revisa tu conexión e inténtalo de nuevo.';
  static const String noDisponible =
      'El test de especialidad no está disponible para tu carrera.';
  static const String noSeGuardo =
      'No se pudo guardar. Revisa tu conexión e inténtalo de nuevo.';
  static const String noSeConfirmo =
      'No se pudo confirmar el guardado. Revisa tu conexión e inténtalo de '
      'nuevo.';
  static const String guardadoTitulo = 'Especialidades actualizadas';
  static const String guardadoMensaje = 'Tu selección se guardó correctamente.';
}

class SpecialtyTestController extends GetxController {
  SpecialtyTestController({
    required this.origen,
    required SpecialtyTestUi ui,
    SpecialtyTestService? service,
    AuthService? auth,
  }) : _ui = ui,
       _service = service ?? SpecialtyTestService.to,
       _auth = auth ?? AuthService.to;

  /// Pausa entre el toque y el avance solo (RF-TEST-5). No es movimiento, así
  /// que se queda con menos movimiento.
  static const Duration pausaDeAvance = Duration(milliseconds: 350);

  final OrigenDelTest origen;
  final SpecialtyTestUi _ui;
  final SpecialtyTestService _service;
  final AuthService _auth;

  final fase = FaseDelTest.bienvenida.obs;
  final carga = EstadoDeCarga.cargando.obs;

  /// La copia del contenido con la que se responde, que es la vigente o la
  /// de un test en pausa.
  final contenido = Rxn<SpecialtyTestContent>();
  final respuestas = <String, String>{}.obs;
  final desempates = <TiebreakRecord>[].obs;

  /// El paso actual. De 0 a T − 1 son preguntas y desde T, desempates.
  final paso = 0.obs;

  /// Los 350 ms entre el toque y el avance, en los que otro toque no hace
  /// nada.
  final bloqueado = false.obs;
  final historialAbierto = false.obs;

  /// La copia vigente que trae la bienvenida, para «Empezar el test» y
  /// «Empezar de nuevo».
  SpecialtyTestContent? _vigente;
  Timer? _avance;
  bool _cerrado = false;

  bool get enAsistente => origen == OrigenDelTest.asistente;

  /// Hay respuestas en memoria, de esta ruta o de un test en pausa.
  bool get hayAvance => respuestas.isNotEmpty || desempates.isNotEmpty;

  int get totalPreguntas => contenido.value?.totalQuestions ?? 0;

  bool get enDesempate => paso.value >= totalPreguntas;

  /// La pregunta del paso actual, o null en un desempate.
  TestQuestion? get preguntaActual {
    final c = contenido.value;
    if (c == null || paso.value >= c.totalQuestions) return null;
    return c.questions[paso.value];
  }

  /// El desempate del paso actual, o null en una pregunta.
  TiebreakRecord? get desempateActual {
    final i = paso.value - totalPreguntas;
    if (i < 0 || i >= desempates.length) return null;
    return desempates[i];
  }

  /// La respuesta marcada en el paso actual, o null.
  String? get respuestaActual {
    final q = preguntaActual;
    if (q != null) return respuestas[q.id];
    return desempateActual?.answer;
  }

  /// La principal actual del alumno, que usan el resultado y sus guardados.
  int? get principalActual => _auth.currentUser?.especialidadPrincipal;

  @override
  void onInit() {
    super.onInit();
    final pausado = _service.paused;
    if (pausado != null) {
      contenido.value = pausado.content;
      // Una copia, porque `RxMap.assignAll` adopta el mapa que recibe, y el
      // de la pausa puede ser de solo lectura.
      respuestas.assignAll(Map<String, String>.of(pausado.answers));
      desempates.assignAll(pausado.tiebreaks);
    }
    unawaited(_cargarContenido());
  }

  @override
  void onClose() {
    _cerrado = true;
    _avance?.cancel();
    // Cualquier cierre con avance deja el test en pausa, sea el botón de
    // pausa, el atrás del sistema en la bienvenida o «Ahora no». Saltar y
    // terminar ya borraron las respuestas.
    final c = contenido.value;
    if (hayAvance && c != null) {
      _service.pause(
        PausedSpecialtyTest(
          content: c,
          answers: Map<String, String>.of(respuestas),
          tiebreaks: List<TiebreakRecord>.of(desempates),
        ),
      );
    }
    super.onClose();
  }

  // ── Bienvenida (RF-TEST-3) ─────────────────────────────────────────────────

  /// Pide el contenido de esta apertura. La primera apertura desde el
  /// asistente usa la precarga (RF-TEST-1), con su copia si ya está, la
  /// espera si sigue en vuelo y otro pedido si terminó en error.
  Future<void> _cargarContenido() async {
    carga.value = EstadoDeCarga.cargando;
    try {
      final precarga = enAsistente ? _service.takePrefetch() : null;
      SpecialtyTestContent vigente;
      if (precarga == null) {
        vigente = await _service.fetchContent();
      } else {
        try {
          vigente = await precarga;
        } on SpecialtyTestFailure catch (f) {
          if (f.kind == SpecialtyTestFailureKind.notAvailable) rethrow;
          vigente = await _service.fetchContent();
        }
      }
      if (_cerrado) return;
      _vigente = vigente;
      contenido.value ??= vigente;
      carga.value = EstadoDeCarga.lista;
    } on SpecialtyTestFailure catch (f) {
      if (_cerrado) return;
      if (f.kind == SpecialtyTestFailureKind.notAvailable) {
        _noDisponible(f.message);
        return;
      }
      carga.value = EstadoDeCarga.error;
    }
  }

  void reintentarCarga() {
    if (carga.value != EstadoDeCarga.error) return;
    unawaited(_cargarContenido());
  }

  /// «Empezar el test», o «Seguir el test» con avance en memoria, que vuelve
  /// al primer paso sin responder con la copia de ese test.
  void empezar() {
    if (carga.value != EstadoDeCarga.lista) return;
    if (!hayAvance) {
      _abrirPreguntaUno(_vigente!);
      return;
    }
    final c = contenido.value!;
    final siguiente = primerPasoSinResponder(c, respuestas, desempates);
    if (siguiente == null) {
      // Con todo respondido, la espera sigue al último paso.
      paso.value = c.totalQuestions + desempates.length - 1;
      _evaluar();
      return;
    }
    paso.value = siguiente;
    fase.value = FaseDelTest.pregunta;
  }

  /// «Empezar de nuevo» borra las respuestas y abre la pregunta 1 con la
  /// copia vigente.
  void empezarDeNuevo() {
    if (carga.value != EstadoDeCarga.lista) return;
    _borrarRespuestas();
    _abrirPreguntaUno(_vigente!);
  }

  void _abrirPreguntaUno(SpecialtyTestContent c) {
    contenido.value = c;
    respuestas.clear();
    desempates.clear();
    paso.value = 0;
    historialAbierto.value = false;
    fase.value = FaseDelTest.pregunta;
  }

  void _borrarRespuestas() {
    respuestas.clear();
    desempates.clear();
    _service.discardPaused();
  }

  /// «Saltar y elegir por mi cuenta» borra las respuestas, y el asistente
  /// pasa a la selección manual.
  void saltar() {
    _borrarRespuestas();
    _ui.cerrar(SalidaDelTest.seleccionManual);
  }

  /// «Ahora no», en el Perfil. Un avance queda en pausa.
  void ahoraNo() => _ui.cerrar();

  /// «Pausar el test y seguir luego». [onClose] guarda el avance.
  void pausar() => _ui.cerrar();

  /// El test no existe para la carrera (`404 SPECIALTY_TEST_NOT_AVAILABLE`).
  /// En el asistente pasa a la selección manual sin aviso; en el Perfil avisa
  /// con el mensaje del servidor y cierra la ruta.
  void _noDisponible(String? mensaje, {bool avisarSiempre = false}) {
    _borrarRespuestas();
    if (!enAsistente || avisarSiempre) {
      _ui.avisar(
        AvisoDelTest(TipoDeAviso.info, mensaje ?? TextosDelTest.noDisponible),
      );
    }
    _ui.cerrar(enAsistente ? SalidaDelTest.seleccionManual : null);
  }

  // ── Preguntas y desempates (RF-TEST-4 a RF-TEST-6) ─────────────────────────

  /// Responde el paso actual con [valor]. Con [avanceSolo], la pregunta
  /// avanza a los 350 ms y en ese tiempo otro toque no hace nada. Sin él
  /// (lector de pantalla activo), avanza con «Siguiente» (RF-TEST-13).
  void responder(String valor, {bool avanceSolo = true}) {
    final c = contenido.value;
    if (c == null || fase.value != FaseDelTest.pregunta || bloqueado.value) {
      return;
    }
    final p = paso.value;
    if (p < c.totalQuestions) respuestas[c.questions[p].id] = valor;
    desempates.assignAll(
      desempatesTrasResponder(
        totalPreguntas: c.totalQuestions,
        desempates: desempates,
        paso: p,
        respuesta: valor,
      ),
    );
    if (!avanceSolo) return;
    bloqueado.value = true;
    _avance = Timer(pausaDeAvance, () {
      bloqueado.value = false;
      avanzar();
    });
  }

  /// Pasa al paso siguiente. Tras la última pregunta o un desempate, va al
  /// desempate que ya está en memoria o evalúa.
  void avanzar() {
    final c = contenido.value;
    if (c == null || fase.value != FaseDelTest.pregunta) return;
    if (respuestaActual == null) return;
    historialAbierto.value = false;
    final p = paso.value;
    final siguiente = p + 1;
    final hayDesempateSiguiente =
        siguiente >= c.totalQuestions &&
        siguiente - c.totalQuestions < desempates.length;
    if (siguiente < c.totalQuestions || hayDesempateSiguiente) {
      paso.value = siguiente;
      return;
    }
    _evaluar();
  }

  /// «Pregunta anterior» y el atrás del sistema en las preguntas y en la
  /// espera (RF-TEST-4). Desde la pregunta 1 vuelve a la bienvenida.
  void atras() {
    switch (fase.value) {
      case FaseDelTest.pregunta:
        _avance?.cancel();
        bloqueado.value = false;
        historialAbierto.value = false;
        if (paso.value == 0) {
          fase.value = FaseDelTest.bienvenida;
        } else {
          paso.value = paso.value - 1;
        }
      case FaseDelTest.espera:
        _descartarEvaluacion();
        fase.value = FaseDelTest.pregunta;
      case FaseDelTest.bienvenida:
      case FaseDelTest.resultado:
        break;
    }
  }

  void alternarHistorial() => historialAbierto.toggle();

  // ── Evaluación, espera y desempates (RF-TEST-7 y RF-TEST-11) ───────────────

  /// El error de la espera, o null mientras se espera.
  final errorDeEspera = Rxn<SpecialtyTestFailure>();
  final resultado = Rxn<SpecialtyTestResult>();

  /// Sube con cada evaluación pedida y con cada atrás desde la espera. Una
  /// respuesta que vuelve con otro número se descarta.
  int _evaluacionVigente = 0;
  bool _evaluando = false;
  bool _otraPendiente = false;

  /// La espera sigue a un desempate y no a la última pregunta.
  bool get esperaTrasDesempate => paso.value >= totalPreguntas;

  void _evaluar() {
    fase.value = FaseDelTest.espera;
    errorDeEspera.value = null;
    final id = ++_evaluacionVigente;
    // Nunca dos en vuelo. La nueva sale cuando termina o vence la anterior,
    // y de las que esperan en esta ruta sale solo la última. El service
    // sostiene la regla aunque la ruta se cierre y otra siga el test.
    if (_evaluando) {
      _otraPendiente = true;
      return;
    }
    unawaited(_lanzarEvaluacion(id));
  }

  void _descartarEvaluacion() {
    _evaluacionVigente++;
    errorDeEspera.value = null;
  }

  bool _sigueVigente(int id) =>
      !_cerrado && id == _evaluacionVigente && fase.value == FaseDelTest.espera;

  Future<void> _lanzarEvaluacion(int id) async {
    _evaluando = true;
    try {
      var reintentado = false;
      while (true) {
        final c = contenido.value!;
        final cuerpo = cuerpoDeEvaluacion(
          version: c.version,
          respuestas: respuestas,
          desempates: desempates,
        );
        try {
          final pasoNuevo = await _service.evaluate(cuerpo);
          if (_sigueVigente(id)) _aplicarPaso(pasoNuevo);
          return;
        } on SpecialtyTestFailure catch (f) {
          if (!_sigueVigente(id)) return;
          if (f.kind == SpecialtyTestFailureKind.tiebreakMismatch &&
              !reintentado) {
            // Una sola vez y sin desempates, porque el servidor decide
            // cuáles tocan (decisión abierta 19).
            reintentado = true;
            desempates.clear();
            if (paso.value >= c.totalQuestions) {
              paso.value = c.totalQuestions - 1;
            }
            continue;
          }
          await _fallaDeEvaluacion(f);
          return;
        }
      }
    } finally {
      _evaluando = false;
      if (_otraPendiente && !_cerrado) {
        _otraPendiente = false;
        if (fase.value == FaseDelTest.espera) {
          unawaited(_lanzarEvaluacion(_evaluacionVigente));
        }
      }
    }
  }

  void _aplicarPaso(EvaluationStep pasoNuevo) {
    switch (pasoNuevo) {
      case TiebreakStep(:final tiebreak, :final ulisesLine):
        final antes = (tiebreak.order - 1).clamp(0, desempates.length);
        desempates.assignAll([
          ...desempates.take(antes),
          TiebreakRecord(tiebreak: tiebreak, ulisesLine: ulisesLine),
        ]);
        paso.value = totalPreguntas + desempates.length - 1;
        fase.value = FaseDelTest.pregunta;
      case ResultStep(:final result):
        _mostrarResultado(result);
    }
  }

  Future<void> _fallaDeEvaluacion(SpecialtyTestFailure f) async {
    switch (f.kind) {
      case SpecialtyTestFailureKind.versionOutdated:
      case SpecialtyTestFailureKind.invalidAnswers:
        await _ui.pedirReinicio(f.message ?? '');
        if (_cerrado) return;
        await _empezarConContenidoNuevo();
      case SpecialtyTestFailureKind.notAvailable:
        _noDisponible(f.message, avisarSiempre: true);
      case SpecialtyTestFailureKind.offline:
      case SpecialtyTestFailureKind.rateLimited:
      case SpecialtyTestFailureKind.tiebreakMismatch:
      case SpecialtyTestFailureKind.server:
        errorDeEspera.value = f;
    }
  }

  /// El texto del error de la espera, que es el mensaje del servidor o, sin
  /// él, el de sin conexión.
  String get textoDelErrorDeEspera =>
      errorDeEspera.value?.message ?? TextosDelTest.sinConexion;

  void reintentarEvaluacion() {
    if (fase.value != FaseDelTest.espera || errorDeEspera.value == null) {
      return;
    }
    _evaluar();
  }

  /// «Empezar de nuevo» del diálogo de la espera. Pide el contenido otra vez
  /// y abre la pregunta 1.
  Future<void> _empezarConContenidoNuevo() async {
    _borrarRespuestas();
    contenido.value = null;
    _vigente = null;
    fase.value = FaseDelTest.bienvenida;
    await _cargarContenido();
    if (_cerrado || carga.value != EstadoDeCarga.lista) return;
    _abrirPreguntaUno(_vigente!);
  }

  // ── Resultado (RF-TEST-8) ──────────────────────────────────────────────────

  /// Los corazones que se ven marcados.
  final corazones = <int>{}.obs;

  void _mostrarResultado(SpecialtyTestResult r) {
    _avance?.cancel();
    resultado.value = r;
    _borrarRespuestas();
    corazones.assignAll(
      corazonesIniciales(
        intereses: _auth.currentUser?.especialidadesInteres ?? const <int>[],
        idsDelRanking: _idsDe(r),
      ),
    );
    _corazonesConfirmados = Set<int>.of(corazones);
    fase.value = FaseDelTest.resultado;
  }

  List<int> _idsDe(SpecialtyTestResult r) =>
      r.ranking.map((e) => e.specialtyId).toList(growable: false);

  // ── Elegir, corazones y Decidir después (RF-TEST-9) ─────────────────────────

  /// Un guardado de los botones en vuelo.
  final guardando = false.obs;

  /// Un guardado de los corazones en vuelo.
  final guardandoCorazones = false.obs;
  bool _corazonesPendientes = false;

  /// Los últimos corazones que confirmó el servidor.
  Set<int> _corazonesConfirmados = <int>{};

  /// Los botones responden cuando no hay ningún guardado en vuelo.
  bool get botonesActivos => !guardando.value && !guardandoCorazones.value;

  /// La ganadora ya es la principal, y el botón dice «Ya es tu principal».
  bool get yaEsPrincipal {
    final r = resultado.value;
    if (r == null || r.tie) return false;
    return r.ranking.first.specialtyId == principalActual;
  }

  /// «Elegir como principal». Con empate, la pantalla pregunta cuál y pasa
  /// aquí su `specialtyId`.
  Future<void> elegirPrincipal(int elegida) async {
    final r = resultado.value;
    if (r == null || !botonesActivos) return;
    int? otra;
    if (r.tie) {
      for (final w in r.winners) {
        if (w.specialtyId != elegida) otra = w.specialtyId;
      }
    }
    final seleccion = seleccionAlElegir(
      elegida: elegida,
      principalActual: principalActual,
      corazones: corazones,
      idsDelRanking: _idsDe(r),
      otraGanadora: otra,
    );
    if (!await _guardarBotones(seleccion)) return;
    if (enAsistente) {
      _ui.irAlHome();
      return;
    }
    _ui.cerrar(SalidaDelTest.terminado);
    _ui.avisar(
      const AvisoDelTest(
        TipoDeAviso.exito,
        TextosDelTest.guardadoMensaje,
        titulo: TextosDelTest.guardadoTitulo,
      ),
    );
  }

  /// El corazón de una fila. Cambia al tocarlo y guarda enseguida. Los
  /// toques seguidos se juntan y se manda el último estado.
  void alternarCorazon(int specialtyId) {
    if (resultado.value == null || guardando.value) return;
    if (corazones.contains(specialtyId)) {
      corazones.remove(specialtyId);
    } else {
      corazones.add(specialtyId);
    }
    if (guardandoCorazones.value) {
      _corazonesPendientes = true;
      return;
    }
    unawaited(_guardarCorazones());
  }

  Future<void> _guardarCorazones() async {
    final r = resultado.value!;
    guardandoCorazones.value = true;
    try {
      while (true) {
        final enviados = Set<int>.of(corazones);
        final seleccion = seleccionConCorazones(
          principalActual: principalActual,
          corazones: enviados,
          idsDelRanking: _idsDe(r),
        );
        final error = await _guardar(seleccion);
        if (_cerrado) return;
        if (error != null) {
          // Vuelven al último estado confirmado, y los toques juntados se
          // descartan con el guardado que falló.
          corazones.assignAll(_corazonesConfirmados);
          _corazonesPendientes = false;
          _ui.avisar(error);
          return;
        }
        _corazonesConfirmados = enviados;
        if (!_corazonesPendientes) return;
        _corazonesPendientes = false;
        if (setEquals(corazones.toSet(), _corazonesConfirmados)) return;
      }
    } finally {
      if (!_cerrado) guardandoCorazones.value = false;
    }
  }

  /// «Decidir después». En el asistente manda la selección actual para
  /// marcar la configuración como completa; en el Perfil cierra sin guardar,
  /// porque los corazones ya están guardados.
  Future<void> decidirDespues() async {
    final r = resultado.value;
    if (r == null || !botonesActivos) return;
    if (!enAsistente) {
      _ui.cerrar(SalidaDelTest.terminado);
      return;
    }
    final seleccion = seleccionConCorazones(
      principalActual: principalActual,
      corazones: corazones,
      idsDelRanking: _idsDe(r),
    );
    if (await _guardarBotones(seleccion)) _ui.irAlHome();
  }

  /// «Rehacer el test» vuelve a la pregunta 1 con la misma copia y sin
  /// respuestas, sin pasar por la bienvenida.
  void rehacer() {
    if (resultado.value == null || !botonesActivos) return;
    final c = contenido.value!;
    resultado.value = null;
    _abrirPreguntaUno(c);
  }

  /// El atrás del sistema en el resultado. En el asistente no hace nada; en
  /// el Perfil es «Decidir después» (decisión abierta 12).
  void atrasEnResultado() {
    if (enAsistente) return;
    unawaited(decidirDespues());
  }

  Future<bool> _guardarBotones(SeleccionDeEspecialidades seleccion) async {
    guardando.value = true;
    final error = await _guardar(seleccion);
    if (_cerrado) return false;
    guardando.value = false;
    if (error != null) {
      _ui.avisar(error);
      return false;
    }
    return true;
  }

  /// Un `PUT` con plazo de 15 s. Devuelve null si guardó, o el aviso que
  /// explica el fallo.
  Future<AvisoDelTest?> _guardar(SeleccionDeEspecialidades seleccion) async {
    final careerId = _auth.currentUser?.careerId;
    if (careerId == null) {
      return const AvisoDelTest(TipoDeAviso.error, TextosDelTest.noSeGuardo);
    }
    try {
      await _auth.completeSetup(
        careerId: careerId,
        especialidadPrincipal: seleccion.principal,
        especialidadesInteres: seleccion.intereses,
        timeout: SpecialtyTestService.saveTimeout,
      );
      return null;
    } on TimeoutException {
      // El guardado puede estar hecho en el servidor.
      return const AvisoDelTest(TipoDeAviso.error, TextosDelTest.noSeConfirmo);
    } on ApiException catch (e) {
      return AvisoDelTest(TipoDeAviso.error, e.message);
    } catch (_) {
      return const AvisoDelTest(TipoDeAviso.error, TextosDelTest.noSeGuardo);
    }
  }
}
