// lib/domain/bienvenida/bienvenida_turnos.dart
// Las reglas puras de la bienvenida con Ulises (decisión B-26 de
// specs/features/bienvenida/bienvenida.spec.md). Los turnos, el atrás de
// cada uno, el turno al que vuelve cada fallo del envío, el conteo de cursos,
// el latido del sello, el pulso de los rombos, las medidas del recibimiento
// con su regla «Si no cabe», el vuelo de Ulises y la configuración del botón
// de Google en web. Sin widgets ni GetX.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/animation.dart' show Curves;

enum TurnoDeLaBienvenida {
  recibimiento,
  llegadaConSesion,
  e1Codigo,
  e2Contrasena,
  e3Despedida,
  n1Codigo,
  n2Contrasena,
  n3Consentimiento,
  n4Portal,
  n5Authenticator,
  envio,
  incierto,
  t0Invitacion,
  pregunta,
  espera,
  desempate,
  resultado,
  seleccionManual,
  pasoAlHorario,
}

enum AccionDelAtras {
  salirDeLaApp,
  volverAE1,
  yaTengoCuenta,
  volver,
  avisarQueSeEnvia,
  volverAIntentar,
  preguntaAnterior,
  irAT0,
  nada,
}

/// El atrás del sistema hace lo mismo que el enlace secundario del turno
/// (RF-BIEN-13).
AccionDelAtras accionDelAtras(
  TurnoDeLaBienvenida turno, {
  bool testDisponible = true,
}) => switch (turno) {
  TurnoDeLaBienvenida.recibimiento ||
  TurnoDeLaBienvenida.llegadaConSesion ||
  TurnoDeLaBienvenida.e1Codigo => AccionDelAtras.salirDeLaApp,
  TurnoDeLaBienvenida.e2Contrasena => AccionDelAtras.volverAE1,
  TurnoDeLaBienvenida.n1Codigo => AccionDelAtras.yaTengoCuenta,
  TurnoDeLaBienvenida.n2Contrasena ||
  TurnoDeLaBienvenida.n3Consentimiento ||
  TurnoDeLaBienvenida.n4Portal ||
  TurnoDeLaBienvenida.n5Authenticator => AccionDelAtras.volver,
  TurnoDeLaBienvenida.envio => AccionDelAtras.avisarQueSeEnvia,
  TurnoDeLaBienvenida.incierto => AccionDelAtras.volverAIntentar,
  TurnoDeLaBienvenida.pregunta ||
  TurnoDeLaBienvenida.espera ||
  TurnoDeLaBienvenida.desempate => AccionDelAtras.preguntaAnterior,
  TurnoDeLaBienvenida.seleccionManual =>
    testDisponible ? AccionDelAtras.irAT0 : AccionDelAtras.nada,
  TurnoDeLaBienvenida.t0Invitacion ||
  TurnoDeLaBienvenida.resultado ||
  TurnoDeLaBienvenida.e3Despedida ||
  TurnoDeLaBienvenida.pasoAlHorario => AccionDelAtras.nada,
};

/// El turno al que vuelve la conversación tras un fallo del envío, con las
/// reglas de hoy de `registro_controller.dart:265-286` (RF-BIEN-8 y B-32).
TurnoDeLaBienvenida turnoTrasFalloDelEnvio(String? codigo) {
  const aIncierto = <String>{'TIEMPO_AGOTADO', 'SIN_TOKEN'};
  const aN1 = <String>{
    'USER_ALREADY_EXISTS',
    'INVALID_REQUEST_BODY',
    'INVALID_JSON_BODY',
  };
  if (aIncierto.contains(codigo)) return TurnoDeLaBienvenida.incierto;
  if (aN1.contains(codigo)) return TurnoDeLaBienvenida.n1Codigo;
  return TurnoDeLaBienvenida.n5Authenticator;
}

/// La frase del conteo, sin nombre (B-4) y sin las otras dos cifras del
/// resumen de hoy (B-31). Con 0 cursos no hay frase.
String? fraseDelConteo(int cursos) {
  if (cursos <= 0) return null;
  if (cursos == 1) return 'Traje tu curso del ciclo.';
  return 'Traje tus $cursos cursos del ciclo.';
}

/// La burbuja del 201, en una sola burbuja como en la maqueta.
String textoDeCuentaLista(int cursos) {
  final frase = fraseDelConteo(cursos);
  return frase == null
      ? TextosDeLaBienvenida.cuentaLista
      : '${TextosDeLaBienvenida.cuentaLista} $frase';
}

const Duration duracionDelLatido = Duration(milliseconds: 380);

/// La escala de la estrella en el latido, con el [avance] de 0 a 1.
double escalaDelLatido(double avance) {
  if (avance <= 0 || avance >= 1) return 1;
  if (avance <= 0.42) return 1 + 0.13 * math.sin(math.pi * avance / 0.42);
  if (avance >= 0.48 && avance <= 0.92) {
    return 1 + 0.05 * math.sin(math.pi * (avance - 0.48) / 0.44);
  }
  return 1;
}

/// El anillo del latido, con el radio en radios de la estrella.
({double radio, double opacidad}) anilloDelLatido(double avance) {
  final t = avance.clamp(0.0, 1.0).toDouble();
  return (
    radio: 0.62 + (1.5 - 0.62) * Curves.easeOutCubic.transform(t),
    opacidad: 0.55 * (1 - t),
  );
}

const Duration periodoDelPulso = Duration(milliseconds: 1100);

/// Dónde va el pulso, en rombos desde el de arriba, en sentido horario.
double posicionDelPulso(double ms) =>
    (ms / periodoDelPulso.inMilliseconds * 8) % 8;

/// La opacidad del rombo [k] con el pulso en [posicion].
double opacidadDelRombo(int k, double posicion) {
  final directa = (k - posicion).abs() % 8;
  final d = math.min(directa, 8 - directa);
  return 0.42 + 0.58 * math.max(0, 1 - d / 2.4);
}

/// Dónde queda cada pieza del recibimiento (RF-BIEN-2). Ulises se ancla a la
/// estrella, la tarjeta a Ulises y los botones al borde inferior.
class MedidasDelRecibimiento {
  const MedidasDelRecibimiento({
    required this.estrella,
    required this.radio,
    required this.ulises,
    required this.tarjeta,
    required this.botones,
    required this.enConversacion,
  });

  final Offset estrella;
  final double radio;
  final Rect ulises;
  final Rect tarjeta;
  final Rect botones;

  /// Ni achicando la estrella caben, y Ulises saluda ya en la conversación.
  final bool enConversacion;
}

MedidasDelRecibimiento medirElRecibimiento({
  required Offset estrella,
  required double radio,
  required Rect columna,
  required double altoDePantalla,
  required double areaSeguraArriba,
  required double areaSeguraAbajo,
  required double altoDeLaTarjeta,
  required double altoDeLosBotones,
}) {
  const ladoDeUlises = 70.0;
  final fondoDeLosBotones = altoDePantalla - areaSeguraAbajo - 26;
  final botones = Rect.fromLTRB(
    columna.left + 22,
    fondoDeLosBotones - altoDeLosBotones,
    columna.right - 22,
    fondoDeLosBotones,
  );
  final ux = estrella.dx - 104;
  var uy = estrella.dy + 138;

  // Si Ulises o la tarjeta quedan a menos de 16 dp de los botones, suben
  // juntos lo justo.
  double fondo(double y) =>
      math.max(y + ladoDeUlises / 2, y - 22 + altoDeLaTarjeta);
  final exceso = fondo(uy) - (botones.top - 16);
  if (exceso > 0) uy -= exceso;

  final tarjeta = Rect.fromLTRB(
    ux + ladoDeUlises / 2 + 11,
    uy - 22,
    columna.right - 12,
    uy - 22 + altoDeLaTarjeta,
  );

  // Lo más abajo que puede quedar el centro de una estrella de radio [r] sin
  // que la tarjeta ni Ulises, recortado en círculo, entren en el margen libre
  // de 12 dp alrededor de su círculo. Nunca baja de su pose.
  double centroQueCabe(double r) {
    final libre = r + 12;
    final dxDeLaTarjeta = math.max(
      0.0,
      math.max(tarjeta.left - estrella.dx, estrella.dx - tarjeta.right),
    );
    final porLaTarjeta = dxDeLaTarjeta >= libre
        ? double.infinity
        : tarjeta.top -
              math.sqrt(libre * libre - dxDeLaTarjeta * dxDeLaTarjeta);
    final libreDeUlises = libre + ladoDeUlises / 2;
    final dxDeUlises = (ux - estrella.dx).abs();
    final porUlises = dxDeUlises >= libreDeUlises
        ? double.infinity
        : uy -
              math.sqrt(
                libreDeUlises * libreDeUlises - dxDeUlises * dxDeUlises,
              );
    return math.min(estrella.dy, math.min(porLaTarjeta, porUlises));
  }

  // La estrella sube lo justo, sin acercarse a menos de 24 dp del área
  // segura de arriba, y si no alcanza, se achica hasta 60 dp. Si ni así
  // cabe, Ulises saluda ya en la conversación y la estrella no se mueve.
  final tope = areaSeguraArriba + 24;
  var r = radio;
  var sy = centroQueCabe(r);
  var enConversacion = false;
  if (sy - r < tope) {
    if (centroQueCabe(60) - 60 < tope) {
      enConversacion = true;
      sy = estrella.dy;
    } else {
      // El mayor radio con el que cabe, que es donde su borde de arriba
      // toca el tope.
      var cabe = 60.0;
      var noCabe = radio;
      for (var i = 0; i < 60; i++) {
        final medio = (cabe + noCabe) / 2;
        if (centroQueCabe(medio) - medio >= tope) {
          cabe = medio;
        } else {
          noCabe = medio;
        }
      }
      r = cabe;
      sy = centroQueCabe(r);
    }
  }

  final ulises = Rect.fromCenter(
    center: Offset(ux, uy),
    width: ladoDeUlises,
    height: ladoDeUlises,
  );
  return MedidasDelRecibimiento(
    estrella: Offset(estrella.dx, sy),
    radio: r,
    ulises: ulises,
    tarjeta: tarjeta,
    botones: botones,
    enConversacion: enConversacion,
  );
}

/// La curva del vuelo de Ulises. Sus puntos son los de la maqueta, medidos
/// desde el aterrizaje y por 1,2 (B-27). Si el inicio cae dentro de la
/// pantalla, se corre arriba y a la derecha hasta quedar fuera.
({Offset inicio, Offset control1, Offset control2}) puntosDelVuelo(
  Offset aterrizaje,
  Size pantalla,
) {
  const mitad = 31.0; // Ulises mide 62 dp al empezar
  var inicio = aterrizaje + const Offset(353, -578);
  if (inicio.dx - mitad < pantalla.width && inicio.dy + mitad > 0) {
    final c = math.min(pantalla.width - (inicio.dx - mitad), inicio.dy + mitad);
    inicio += Offset(c, -c);
  }
  return (
    inicio: inicio,
    control1: aterrizaje + const Offset(221, -478),
    control2: aterrizaje + const Offset(-187, -226),
  );
}

enum TemaDelBotonDeGoogle { outline, filledBlack }

/// La configuración del botón oficial de GIS en web, como valores simples
/// que la VM prueba (B-35). La traduce `google_sign_in_button_web.dart`.
class ConfiguracionDelBotonDeGoogle {
  const ConfiguracionDelBotonDeGoogle({
    required this.tema,
    required this.ancho,
  });

  static const String tipo = 'standard';
  static const String texto = 'continue_with';
  static const String idioma = 'es';
  static const String forma = 'rectangular';
  static const String logo = 'left';
  static const String tamano = 'large';

  final TemaDelBotonDeGoogle tema;

  /// El ancho del compositor hasta 400 px, el máximo de GIS.
  final double ancho;
}

ConfiguracionDelBotonDeGoogle configuracionDelBotonDeGoogle({
  required bool oscuro,
  required double anchoDelCompositor,
}) => ConfiguracionDelBotonDeGoogle(
  tema: oscuro
      ? TemaDelBotonDeGoogle.filledBlack
      : TemaDelBotonDeGoogle.outline,
  ancho: math.min(anchoDelCompositor, 400),
);

/// Los textos de «Textos nuevos» y los de hoy que la bienvenida conserva.
abstract final class TextosDeLaBienvenida {
  // Recibimiento.
  static const String saludo = '¡Craa! Hola, soy Ulises 👋';
  static const String pregunta = '¿Ya usas ULima++?';
  static const String siEntrar = 'Sí, entrar';
  static const String soyNuevo = 'Soy nuevo';
  static const String ulises = 'Ulises';
  static const String tu = 'Tú';

  // Sí, entrar.
  static const String e1 = '¡Qué bueno verte! ¿Cuál es tu código o usuario?';
  static const String rotuloCodigo = 'Código';
  static const String pistaCodigo = 'Tu código o usuario';
  static const String separadorO = 'o';
  static const String continuarConGoogle = 'Continuar con Google';
  static const String e2 = 'Y tu contraseña de ULima++.';
  static const String rotuloContrasena = 'Contraseña';
  static const String pistaContrasena = 'Tu contraseña';
  static const String entrar = 'Entrar';
  static const String olvidaste = '¿Olvidaste tu contraseña?';
  static const String contrasenaLista = 'Contraseña lista';
  static const String e3 = '¡Hola de nuevo! Te llevo a tu horario 🪶';

  // Sin especialidad (RF-BIEN-21).
  static const String saludoConSesion = '¡Craa! Hola de nuevo 👋';
  static const String faltaEspecialidad = 'Te falta elegir tu especialidad.';
  static const String holaFaltaEspecialidad =
      '¡Hola de nuevo! Te falta elegir tu especialidad.';

  // Soy nuevo.
  static const String n1a = '¡Genial! Tu cuenta se crea aquí mismo.';
  static const String n1b = '¿Cuál es tu código de alumno?';
  static const String rotuloCodigoDeAlumno = 'Código de alumno';
  static const String pistaCodigoDeAlumno = 'Tu código de alumno';
  static const String n2 =
      'Ahora elige la contraseña con la que entrarás a ULima++. No es la de '
      'miUlima.';
  static const String pistaNueva = 'Al menos 8 caracteres';
  static const String rotuloRepetir = 'Repetir contraseña';
  static const String pistaRepetir = 'La misma otra vez';
  static const String contrasenaUlimaLista = 'Contraseña de ULima++ lista';
  static const String n3 =
      'Para traer tus cursos entro a miUlima una sola vez. Antes, lee esto 👇';
  static const String acepto = 'Acepto';
  static const String n4 = 'Tu contraseña de miUlima, la del portal.';
  static const String rotuloPortal = 'Contraseña de miUlima';
  static const String pistaPortal = 'Tu contraseña del portal';
  static const String contrasenaMiUlimaLista = 'Contraseña de miUlima lista';
  static const String n5 = 'Último paso. El código de tu authenticator.';
  static const String rotuloAuthenticator = 'Código del authenticator';
  static const String notaAuthenticator =
      'El código de 6 dígitos que cambia cada 30 segundos.';
  static const String crearMiCuenta = 'Crear mi cuenta';
  static const String authenticatorListo = 'Código del authenticator listo';
  static const String volver = 'Volver';
  static const String yaTengoCuenta = 'Ya tengo cuenta';

  // Envío.
  static const String creando = 'Estoy creando tu cuenta y trayendo tu ciclo.';
  static const String advertencia =
      'Puede tomar un par de minutos: no cierres la app.';
  static const String pildoraCreando = 'Creando tu cuenta…';
  static const String pildoraCreada = 'Cuenta creada';
  static const String cuentaLista = '¡Craa! Tu cuenta ya está lista.';
  static const String avisosDelRegistro = 'Algunas cosas que notamos';
  static const String avisoEnvioTitulo = 'Estamos creando tu cuenta';
  static const String avisoEnvioTexto =
      'No cierres la app: si sales ahora podrías quedarte con una cuenta a '
      'medias.';

  // incierto.
  static const String inciertoTitulo =
      'No pudimos confirmar si tu cuenta se creó.';
  static const String inciertoTexto =
      'Es posible que sí se haya creado. Prueba entrar con el código y la '
      'contraseña que acabas de elegir.';
  static const String creadaTitulo = 'Tu cuenta ya está creada.';
  static const String creadaTexto =
      'Entra con el código y la contraseña que acabas de elegir.';
  static const String volverAIntentar = 'Volver a intentar el registro';
  static const String iniciarSesion = 'Iniciar sesión';

  // Test.
  static String invitacionAlTest(int preguntas) =>
      '¿Empezamos tu test de especialidad? Son $preguntas preguntas cortas.';
  static const String saltar = 'Saltar y elegir por mi cuenta';
  static const String empezarElTest = 'Empezar el test';
  static const String noCargoElTest = 'No pudimos cargar el test.';
  static const String reintentar = 'Reintentar';
  static const String empezarDeNuevo = 'Empezar de nuevo';
  static const String elegirComoPrincipal = 'Elegir como principal';
  static const String decidirDespues = 'Decidir después';
  static const String rehacerElTest = 'Rehacer el test';
  static const String siguiente = 'Siguiente';
  static String rotuloDelDuelo(int n, int total) =>
      'Esto o aquello · $n de $total';
  static String rotuloDeLaEscala(int n, int total) =>
      'Escala de gusto · $n de $total';
  static const String preguntaAnterior = 'Pregunta anterior';
  static const String listoAlHorario = '¡Listo! Te llevo a tu horario 🪶';
  static const String eligeMencion =
      'Elige una mención como tu diploma principal.';
  static const String noCargaronEspecialidades =
      'No pudimos cargar las especialidades.';
  static const String sinCarrera = 'No se pudo determinar tu carrera.';
  static const String principal = 'Principal';
  static const String meInteresa = 'Me interesa';
  static const String saltarPorAhora = 'Saltar por ahora';
  static const String finalizar = 'Finalizar configuración';

  // Errores y sesión.
  static const String sinConexion =
      'No hay conexión. Revisa tu internet e inténtalo de nuevo.';
  static const String sesionCaducada =
      'Tu sesión caducó o iniciaste sesión en otro dispositivo.';

  // Semántica.
  static const String enviar = 'Enviar';
  static const String mostrarContrasena = 'Mostrar contraseña';
  static const String ocultarContrasena = 'Ocultar contraseña';
}
