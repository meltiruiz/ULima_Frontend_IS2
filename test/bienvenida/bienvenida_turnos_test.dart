// test/bienvenida/bienvenida_turnos_test.dart
//
// UNITARIA · Bienvenida con Ulises (specs/features/bienvenida/bienvenida.spec.md).
// Las reglas puras de B-26. El atrás de RF-BIEN-13, el turno de cada fallo
// del envío y el conteo de RF-BIEN-8, el latido y el pulso de RF-BIEN-4, las
// medidas y «Si no cabe» de RF-BIEN-2 (B-27 y B-28), el vuelo de Ulises y la
// configuración de GIS de RF-BIEN-6 (B-35).
// Archivo probado lib/domain/bienvenida/bienvenida_turnos.dart.

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/animation.dart' show Curves;
import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/domain/bienvenida/bienvenida_turnos.dart';

typedef _T = TurnoDeLaBienvenida;
typedef _A = AccionDelAtras;

void main() {
  group('el atrás del sistema (RF-BIEN-13)', () {
    test('cada turno hace lo mismo que su enlace secundario', () {
      final tabla = <_T, _A>{
        _T.recibimiento: _A.salirDeLaApp,
        _T.llegadaConSesion: _A.salirDeLaApp,
        _T.e1Codigo: _A.salirDeLaApp,
        _T.e2Contrasena: _A.volverAE1,
        _T.n1Codigo: _A.yaTengoCuenta,
        _T.n2Contrasena: _A.volver,
        _T.n3Consentimiento: _A.volver,
        _T.n4Portal: _A.volver,
        _T.n5Authenticator: _A.volver,
        _T.envio: _A.avisarQueSeEnvia,
        _T.incierto: _A.volverAIntentar,
        _T.t0Invitacion: _A.nada,
        _T.resultado: _A.nada,
        _T.pregunta: _A.preguntaAnterior,
        _T.espera: _A.preguntaAnterior,
        _T.desempate: _A.preguntaAnterior,
        _T.seleccionManual: _A.irAT0,
        _T.pasoAlHorario: _A.nada,
        _T.e3Despedida: _A.nada,
      };
      for (final MapEntry(key: turno, value: accion) in tabla.entries) {
        expect(accionDelAtras(turno), accion, reason: '$turno');
      }
      expect(tabla.keys.toSet(), _T.values.toSet(), reason: 'todos los turnos');
      expect(
        accionDelAtras(_T.seleccionManual, testDisponible: false),
        _A.nada,
      );
    });
  });

  group('el envío del registro (RF-BIEN-8)', () {
    test('cada fallo vuelve al turno de hoy', () {
      for (final codigo in [
        'USER_ALREADY_EXISTS',
        'INVALID_REQUEST_BODY',
        'INVALID_JSON_BODY',
      ]) {
        expect(turnoTrasFalloDelEnvio(codigo), _T.n1Codigo, reason: codigo);
      }
      expect(turnoTrasFalloDelEnvio('TIEMPO_AGOTADO'), _T.incierto);
      expect(turnoTrasFalloDelEnvio('SIN_TOKEN'), _T.incierto);
      expect(turnoTrasFalloDelEnvio('SIN_CONEXION'), _T.n5Authenticator);
      expect(turnoTrasFalloDelEnvio('PORTAL_AUTH_FAILED'), _T.n5Authenticator);
      expect(turnoTrasFalloDelEnvio(null), _T.n5Authenticator);
    });

    test(
      'la frase del conteo, sin nombre ni las otras cifras (B-4 y B-31)',
      () {
        expect(fraseDelConteo(0), isNull);
        expect(fraseDelConteo(1), 'Traje tu curso del ciclo.');
        expect(fraseDelConteo(6), 'Traje tus 6 cursos del ciclo.');
        expect(textoDeCuentaLista(0), '¡Craa! Tu cuenta ya está lista.');
        expect(
          textoDeCuentaLista(6),
          '¡Craa! Tu cuenta ya está lista. Traje tus 6 cursos del ciclo.',
        );
      },
    );
  });

  group('el latido y el pulso (RF-BIEN-4)', () {
    test('el latido dura 380 ms, sube 13 % en el primer 42 % y 5 % entre el '
        '48 % y el 92 %', () {
      expect(duracionDelLatido, const Duration(milliseconds: 380));
      expect(escalaDelLatido(0), 1);
      expect(escalaDelLatido(0.21), closeTo(1.13, 1e-9));
      // Con forma de medio seno, y no de triángulo.
      expect(
        escalaDelLatido(0.105),
        closeTo(1 + 0.13 * math.sin(math.pi / 4), 1e-9),
      );
      expect(
        escalaDelLatido(0.59),
        closeTo(1 + 0.05 * math.sin(math.pi / 4), 1e-9),
      );
      expect(escalaDelLatido(0.45), 1);
      expect(escalaDelLatido(0.70), closeTo(1.05, 1e-9));
      expect(escalaDelLatido(0.95), 1);
      expect(escalaDelLatido(1), 1);
    });

    test('el anillo del latido crece de 0,62 a 1,5 radios y su opacidad baja '
        'de 0,55 a 0', () {
      expect(anilloDelLatido(0).radio, closeTo(0.62, 1e-9));
      expect(anilloDelLatido(0).opacidad, closeTo(0.55, 1e-9));
      expect(anilloDelLatido(1).radio, closeTo(1.5, 1e-9));
      expect(anilloDelLatido(1).opacidad, closeTo(0, 1e-9));
      // El radio crece con easeOutCubic y la opacidad baja en línea recta.
      expect(
        anilloDelLatido(0.5).radio,
        closeTo(0.62 + (1.5 - 0.62) * Curves.easeOutCubic.transform(0.5), 1e-9),
      );
      expect(anilloDelLatido(0.5).opacidad, closeTo(0.275, 1e-9));
    });

    test('el pulso recorre los ocho rombos en 1100 ms desde el de arriba', () {
      expect(periodoDelPulso, const Duration(milliseconds: 1100));
      expect(posicionDelPulso(0), 0);
      expect(posicionDelPulso(1100 / 8), closeTo(1, 1e-9));
      expect(posicionDelPulso(1100), closeTo(0, 1e-9));
    });

    test(
      'la opacidad es 0,42 + 0,58 × máx(0; 1 − d / 2,4), con d circular',
      () {
        expect(opacidadDelRombo(0, 0), closeTo(1, 1e-9));
        expect(
          opacidadDelRombo(2, 0),
          closeTo(0.42 + 0.58 * (1 - 2 / 2.4), 1e-9),
        );
        expect(opacidadDelRombo(4, 0), closeTo(0.42, 1e-9));
        expect(
          opacidadDelRombo(7, 0),
          closeTo(0.42 + 0.58 * (1 - 1 / 2.4), 1e-9),
        );
        expect(
          opacidadDelRombo(0, 7.5),
          closeTo(0.42 + 0.58 * (1 - 0.5 / 2.4), 1e-9),
        );
      },
    );
  });

  group('las medidas del recibimiento (RF-BIEN-2, B-27 y B-28)', () {
    MedidasDelRecibimiento enElSe({required double tarjeta}) =>
        medirElRecibimiento(
          estrella: const Offset(187.5, 333.5),
          radio: 90,
          columna: const Rect.fromLTWH(0, 0, 375, 667),
          altoDePantalla: 667,
          areaSeguraArriba: 20,
          areaSeguraAbajo: 0,
          altoDeLaTarjeta: tarjeta,
          altoDeLosBotones: 110,
        );

    test('en el iPhone SE con el texto al 100 % la estrella no se mueve', () {
      final m = enElSe(tarjeta: 59.5);
      expect(m.estrella, const Offset(187.5, 333.5));
      expect(m.radio, 90);
      expect(m.ulises.center, const Offset(83.5, 471.5));
      expect(m.ulises.width, 70);
      expect(m.botones.top, 531);
      expect(m.botones.left, 22);
      expect(m.botones.right, 375 - 22);
      expect(m.tarjeta.top, 471.5 - 22);
      expect(m.tarjeta.left, 83.5 + 35 + 11);
      expect(m.tarjeta.right, 375 - 12);
      // Unos 14 dp bajo el margen de la estrella y 22 dp sobre los botones.
      expect(m.tarjeta.top - (333.5 + 90 + 12), closeTo(14, 0.01));
      expect(m.botones.top - m.tarjeta.bottom, closeTo(22, 0.01));
      expect(m.enConversacion, isFalse);
    });

    test('si la tarjeta crece, Ulises y la tarjeta suben lo justo y la '
        'estrella sube antes de que entren en su margen', () {
      final m = enElSe(tarjeta: 99.5);
      expect(m.botones.top - m.tarjeta.bottom, closeTo(16, 0.01));
      // Manda el margen de 12 dp alrededor del círculo de la estrella, y la
      // pieza que queda bajo su centro es la tarjeta (RF-BIEN-2).
      expect(m.tarjeta.top, closeTo(m.estrella.dy + 90 + 12, 0.01));
      expect(m.estrella.dy, closeTo(313.5, 0.01));
      expect(m.radio, 90);
      // Ulises, recortado en círculo, tampoco entra en el margen.
      expect(
        (m.ulises.center - m.estrella).distance,
        greaterThanOrEqualTo(90 + 12 + 35),
      );
    });

    test('con el texto al 130 % y al 200 % la estrella sube unos 15 dp y unos '
        '95 dp, como estima la spec', () {
      // La tarjeta con «¿Ya usas ULima++?» en dos líneas al 130 %, y con las
      // dos líneas en dos renglones cada una al 200 %.
      expect(333.5 - enElSe(tarjeta: 98.1).estrella.dy, closeTo(15, 5));
      expect(333.5 - enElSe(tarjeta: 173.2).estrella.dy, closeTo(95, 5));
    });

    test('si no alcanza, la estrella se achica hasta 60 dp sin acercarse a '
        'menos de 24 dp del área segura', () {
      final m = enElSe(tarjeta: 300);
      expect(m.radio, lessThan(90));
      expect(m.radio, greaterThanOrEqualTo(60));
      expect(m.estrella.dy - m.radio, closeTo(20 + 24, 0.01));
      expect(m.tarjeta.top, closeTo(m.estrella.dy + m.radio + 12, 0.01));
    });

    test('si ni así cabe, Ulises saluda ya en la conversación', () {
      final m = enElSe(tarjeta: 420);
      expect(m.enConversacion, isTrue);
      expect(m.estrella, const Offset(187.5, 333.5));
      expect(m.radio, 90);
    });
  });

  group('el vuelo de Ulises (RF-BIEN-2)', () {
    test('los puntos son los de la maqueta por 1,2, desde el aterrizaje', () {
      final p = puntosDelVuelo(const Offset(83.5, 471.5), const Size(375, 667));
      expect(p.inicio, const Offset(83.5 + 353, 471.5 - 578));
      expect(p.control1, const Offset(83.5 + 221, 471.5 - 478));
      expect(p.control2, const Offset(83.5 - 187, 471.5 - 226));
    });

    test('en una tableta el inicio se corre arriba y a la derecha hasta quedar '
        'fuera', () {
      final p = puntosDelVuelo(const Offset(400, 900), const Size(1024, 1366));
      final fuera = p.inicio.dx - 31 >= 1024 || p.inicio.dy + 31 <= 0;
      expect(fuera, isTrue);
      expect(p.inicio.dx, greaterThanOrEqualTo(400 + 353));
      expect(p.inicio.dy, lessThanOrEqualTo(900 - 578));
    });
  });

  group('el botón de Google en web (RF-BIEN-6 y B-35)', () {
    test('continue_with, es, rectangular, el logo a la izquierda y el tema del '
        'sistema', () {
      final claro = configuracionDelBotonDeGoogle(
        oscuro: false,
        anchoDelCompositor: 351,
      );
      expect(claro.tema, TemaDelBotonDeGoogle.outline);
      expect(claro.ancho, 351);
      final oscuro = configuracionDelBotonDeGoogle(
        oscuro: true,
        anchoDelCompositor: 560,
      );
      expect(oscuro.tema, TemaDelBotonDeGoogle.filledBlack);
      expect(oscuro.ancho, 400, reason: 'el máximo de GIS');
      expect(ConfiguracionDelBotonDeGoogle.texto, 'continue_with');
      expect(ConfiguracionDelBotonDeGoogle.idioma, 'es');
      expect(ConfiguracionDelBotonDeGoogle.forma, 'rectangular');
      expect(ConfiguracionDelBotonDeGoogle.logo, 'left');
    });
  });

  test('los textos de Ulises con número', () {
    expect(
      TextosDeLaBienvenida.invitacionAlTest(14),
      '¿Empezamos tu test de especialidad? Son 14 preguntas cortas.',
    );
    expect(
      TextosDeLaBienvenida.rotuloDelDuelo(3, 14),
      'Esto o aquello · 3 de 14',
    );
    expect(
      TextosDeLaBienvenida.rotuloDeLaEscala(9, 14),
      'Escala de gusto · 9 de 14',
    );
  });
}
