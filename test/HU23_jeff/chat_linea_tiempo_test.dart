// test/HU23_jeff/chat_linea_tiempo_test.dart
//
// UNITARIA — HU23 (chat de sección): las piezas puras de la línea de tiempo
// de la conversación.
// - RF-CHAT-11: el día y la hora de un mensaje salen en hora de Lima
//   (UTC−5 todo el año), no en la zona del teléfono, y el separador dice
//   «Hoy», «Ayer» o «Lunes 21 de septiembre».
// - RF-CHAT-11: si antes de un mensaje va un separador de día.
// - RF-CHAT-9: si un mensaje abre grupo y si lleva el nombre del remitente.
// - RF-CHAT-8: el subtítulo del AppBar, «Sección N» o «Sin sección».
// - RF-CHAT-6 y RF-CHAT-13: la etiqueta accesible de la tarjeta que abre el
//   chat, «Abrir el chat de <curso>, sección <N>» o «…, sin sección».
// Archivo: lib/pages/chat/chat_linea_tiempo.dart.
//
// Todos los datos son inventados; el repo es público. Los remitentes son
// «Alumno De Prueba» y «Docente De Prueba», y los ids no son de nadie.

import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/models/message.dart';
import 'package:ulima_plus/pages/chat/chat_linea_tiempo.dart';

// --- Datos inventados ---------------------------------------------------------

/// uid de la sesión que mira el chat (un alumno sintético).
const _yo = '20230001';

/// Un mensaje de chat con lo mínimo que usan las reglas de grupo.
ChatMessage _msg({
  required String id,
  required String senderId,
  required DateTime createdAt,
  String senderName = 'Alumno De Prueba',
  bool deleted = false,
  String messageType = 'text',
}) => ChatMessage(
  id: id,
  senderId: senderId,
  senderName: senderName,
  senderRole: 'student',
  senderRoleLabel: 'Alumno',
  isModerator: false,
  weight: 10,
  body: messageType == 'networking_card'
      ? '${ChatMessage.networkingBodyPrefix}$senderId'
      : 'Mensaje de prueba $id',
  createdAt: createdAt,
  messageType: messageType,
  deleted: deleted,
  deletedBy: deleted ? 'Docente De Prueba' : null,
);

void main() {
  group('UNITARIA · enHoraDeLima (RF-CHAT-11)', () {
    test('resta 5 h al instante en UTC y da los campos de pared de Lima', () {
      final lima = enHoraDeLima(DateTime.utc(2026, 9, 15, 3, 30));

      expect(lima.year, 2026);
      expect(lima.month, 9);
      expect(lima.day, 14);
      expect(lima.hour, 22);
      expect(lima.minute, 30);
    });

    test('no depende de la zona en que llega el instante', () {
      final instante = DateTime.utc(2026, 9, 15, 5, 10);

      expect(enHoraDeLima(instante.toLocal()), enHoraDeLima(instante));
    });
  });

  group('UNITARIA · horaDeMensaje (RF-CHAT-11)', () {
    test('03:30 UTC del 15 se muestra como 22:30 de Lima', () {
      expect(horaDeMensaje(DateTime.utc(2026, 9, 15, 3, 30)), '22:30');
    });

    test('05:10 UTC del 15 se muestra como 00:10 de Lima', () {
      expect(horaDeMensaje(DateTime.utc(2026, 9, 15, 5, 10)), '00:10');
    });

    test('la misma hora llega aunque el instante venga en hora local', () {
      final instante = DateTime.utc(2026, 9, 15, 3, 30).toLocal();

      expect(horaDeMensaje(instante), '22:30');
    });

    test('rellena con cero las horas y los minutos de una cifra', () {
      expect(horaDeMensaje(DateTime.utc(2026, 9, 15, 14, 5)), '09:05');
    });
  });

  group('UNITARIA · etiquetaDeDia (RF-CHAT-11)', () {
    final hoy = DateTime.utc(2026, 9, 23, 10, 15);

    test('el mismo día que hoy dice «Hoy»', () {
      expect(etiquetaDeDia(DateTime.utc(2026, 9, 23, 0, 1), hoy), 'Hoy');
      expect(etiquetaDeDia(DateTime.utc(2026, 9, 23, 23, 59), hoy), 'Hoy');
    });

    test('el día anterior dice «Ayer», sin importar la hora', () {
      expect(etiquetaDeDia(DateTime.utc(2026, 9, 22, 23, 59), hoy), 'Ayer');
      expect(
        etiquetaDeDia(
          DateTime.utc(2026, 9, 22, 12),
          DateTime.utc(2026, 9, 23, 0, 1),
        ),
        'Ayer',
      );
    });

    test('dos días antes dice el día completo en español', () {
      expect(
        etiquetaDeDia(DateTime.utc(2026, 9, 21, 8), hoy),
        'Lunes 21 de septiembre',
      );
    });

    test('«Ayer» también cruza el mes y el año', () {
      expect(
        etiquetaDeDia(DateTime.utc(2025, 12, 31, 20), DateTime.utc(2026, 1, 1)),
        'Ayer',
      );
      expect(
        etiquetaDeDia(DateTime.utc(2026, 8, 31, 20), DateTime.utc(2026, 9, 1)),
        'Ayer',
      );
    });

    test('el día completo cruza el mes y el año', () {
      expect(
        etiquetaDeDia(
          DateTime.utc(2025, 12, 31, 20),
          DateTime.utc(2026, 1, 2, 9),
        ),
        'Miércoles 31 de diciembre',
      );
    });

    test('los días van con mayúscula inicial y los meses en minúscula', () {
      // Del lunes 14 al domingo 20 de septiembre de 2026.
      const esperados = [
        'Lunes 14 de septiembre',
        'Martes 15 de septiembre',
        'Miércoles 16 de septiembre',
        'Jueves 17 de septiembre',
        'Viernes 18 de septiembre',
        'Sábado 19 de septiembre',
        'Domingo 20 de septiembre',
      ];
      for (var i = 0; i < esperados.length; i++) {
        expect(etiquetaDeDia(DateTime.utc(2026, 9, 14 + i), hoy), esperados[i]);
      }
      const meses = [
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
      for (var m = 1; m <= 12; m++) {
        expect(
          etiquetaDeDia(DateTime.utc(2025, m, 1), hoy),
          endsWith(' 1 de ${meses[m - 1]}'),
        );
      }
    });

    test('la etiqueta usa los campos que recibe, sin pasar por la zona', () {
      // Campos de pared de Lima que llegan como hora local: 23:30 del 22 es
      // «Ayer» con hoy el 23, aunque en un teléfono en Lima ese instante ya
      // sea el 23 en UTC.
      expect(
        etiquetaDeDia(DateTime(2026, 9, 22, 23, 30), DateTime(2026, 9, 23, 8)),
        'Ayer',
      );
    });

    test('un día posterior a hoy dice el día completo, no «Hoy»', () {
      // El reloj del teléfono va atrasado: para él son las 23:58 del 23 y el
      // servidor ya fechó un mensaje a las 00:01 del 24.
      expect(
        etiquetaDeDia(
          DateTime.utc(2026, 9, 24, 0, 1),
          DateTime.utc(2026, 9, 23, 23, 58),
        ),
        'Jueves 24 de septiembre',
      );
      expect(
        etiquetaDeDia(DateTime.utc(2026, 9, 25, 9), hoy),
        'Viernes 25 de septiembre',
      );
    });

    test(
      'con el reloj atrasado, dos días seguidos no quedan bajo dos «Hoy»',
      () {
        // Instantes reales: 04:58 UTC del 24 es 23:58 del 23 en Lima (el reloj
        // del teléfono), 04:50 UTC es 23:50 del 23 y 05:01 UTC es 00:01 del 24.
        final hoyLima = enHoraDeLima(DateTime.utc(2026, 9, 24, 4, 58));
        final antes = enHoraDeLima(DateTime.utc(2026, 9, 24, 4, 50));
        final despues = enHoraDeLima(DateTime.utc(2026, 9, 24, 5, 1));

        expect(etiquetaDeDia(antes, hoyLima), 'Hoy');
        expect(etiquetaDeDia(despues, hoyLima), 'Jueves 24 de septiembre');
      },
    );
  });

  group('UNITARIA · abreDia (RF-CHAT-11)', () {
    test('el primero de la lista abre día', () {
      final primero = _msg(
        id: '1',
        senderId: '503',
        createdAt: DateTime.utc(2026, 9, 15, 15),
      );

      expect(abreDia(primero, null), isTrue);
    });

    test('otro día en Lima abre día aunque esté a minutos en UTC', () {
      // 04:58 UTC del 15 es 23:58 del 14 en Lima; 05:02 UTC es 00:02 del 15.
      final anterior = _msg(
        id: '1',
        senderId: '503',
        createdAt: DateTime.utc(2026, 9, 15, 4, 58),
      );
      final actual = _msg(
        id: '2',
        senderId: '503',
        createdAt: DateTime.utc(2026, 9, 15, 5, 2),
      );

      expect(abreDia(actual, anterior), isTrue);
    });

    test('el mismo día en Lima no abre día aunque en UTC cambie el día', () {
      // 23:50 UTC del 14 y 00:10 UTC del 15 son 18:50 y 19:10 del 14 en Lima.
      final anterior = _msg(
        id: '1',
        senderId: '503',
        createdAt: DateTime.utc(2026, 9, 14, 23, 50),
      );
      final actual = _msg(
        id: '2',
        senderId: '504',
        createdAt: DateTime.utc(2026, 9, 15, 0, 10),
      );

      expect(abreDia(actual, anterior), isFalse);
    });

    test('una lápida cuenta como mensaje de su día', () {
      final lapida = _msg(
        id: '1',
        senderId: '503',
        createdAt: DateTime.utc(2026, 9, 15, 15),
        deleted: true,
      );
      final mismoDia = _msg(
        id: '2',
        senderId: '503',
        createdAt: DateTime.utc(2026, 9, 15, 16),
      );
      final lapidaOtroDia = _msg(
        id: '3',
        senderId: '504',
        createdAt: DateTime.utc(2026, 9, 16, 16),
        deleted: true,
      );

      expect(abreDia(mismoDia, lapida), isFalse);
      expect(abreDia(lapidaOtroDia, mismoDia), isTrue);
    });
  });

  group('UNITARIA · etiquetaDeSeccion (RF-CHAT-8)', () {
    test('con código dice «Sección N»', () {
      expect(etiquetaDeSeccion('801'), 'Sección 801');
    });

    test('recorta los espacios del código', () {
      expect(etiquetaDeSeccion('  802 '), 'Sección 802');
    });

    test('con código nulo, vacío o solo espacios dice solo «Sin sección»', () {
      expect(etiquetaDeSeccion(null), 'Sin sección');
      expect(etiquetaDeSeccion(''), 'Sin sección');
      expect(etiquetaDeSeccion('   '), 'Sin sección');
    });
  });

  group('UNITARIA · etiquetaParaAbrirElChat (RF-CHAT-6 y RF-CHAT-13)', () {
    test('con código dice «Abrir el chat de <curso>, sección <N>»', () {
      expect(
        etiquetaParaAbrirElChat('Curso De Prueba A', '801'),
        'Abrir el chat de Curso De Prueba A, sección 801',
      );
    });

    test('recorta los espacios del código y deja el curso tal como llega', () {
      expect(
        etiquetaParaAbrirElChat('CURSO DE PRUEBA B', ' 802  '),
        'Abrir el chat de CURSO DE PRUEBA B, sección 802',
      );
    });

    test('con código nulo, vacío o solo espacios dice «…, sin sección»', () {
      for (final codigo in <String?>[null, '', '   ']) {
        expect(
          etiquetaParaAbrirElChat('Curso De Prueba A', codigo),
          'Abrir el chat de Curso De Prueba A, sin sección',
          reason: '«$codigo»',
        );
      }
    });

    test('dos secciones del mismo curso dan etiquetas distintas', () {
      expect(
        etiquetaParaAbrirElChat('Curso De Prueba A', '801'),
        isNot(etiquetaParaAbrirElChat('Curso De Prueba A', '802')),
      );
      expect(
        etiquetaParaAbrirElChat('Curso De Prueba A', '801'),
        isNot(etiquetaParaAbrirElChat('Curso De Prueba A', null)),
      );
    });
  });

  group('UNITARIA · abreGrupo y llevaNombre (RF-CHAT-9)', () {
    final base = DateTime.utc(2026, 9, 15, 15);

    test('el primero de la lista abre grupo; ajeno con nombre, propio sin', () {
      final ajeno = _msg(id: '1', senderId: '503', createdAt: base);
      final propio = _msg(id: '2', senderId: _yo, createdAt: base);

      expect(abreGrupo(ajeno, null), isTrue);
      expect(llevaNombre(ajeno, null, _yo), isTrue);
      expect(abreGrupo(propio, null), isTrue);
      expect(llevaNombre(propio, null, _yo), isFalse);
    });

    test('mismo remitente y mismo día no abre grupo ni lleva nombre', () {
      final anterior = _msg(id: '1', senderId: '503', createdAt: base);
      final actual = _msg(
        id: '2',
        senderId: '503',
        createdAt: base.add(const Duration(hours: 3)),
      );

      expect(abreGrupo(actual, anterior), isFalse);
      expect(llevaNombre(actual, anterior, _yo), isFalse);
    });

    test('otro senderId con el mismo nombre abre grupo y lleva nombre', () {
      final anterior = _msg(
        id: '1',
        senderId: '503',
        createdAt: base,
        senderName: 'Alumno De Prueba',
      );
      final actual = _msg(
        id: '2',
        senderId: '504',
        createdAt: base.add(const Duration(minutes: 1)),
        senderName: 'Alumno De Prueba',
      );

      expect(abreGrupo(actual, anterior), isTrue);
      expect(llevaNombre(actual, anterior, _yo), isTrue);
    });

    test('otro día en Lima abre grupo aunque esté a minutos en UTC', () {
      // 04:58 UTC del 15 es 23:58 del 14 en Lima; 05:02 UTC es 00:02 del 15.
      final anterior = _msg(
        id: '1',
        senderId: '503',
        createdAt: DateTime.utc(2026, 9, 15, 4, 58),
      );
      final actual = _msg(
        id: '2',
        senderId: '503',
        createdAt: DateTime.utc(2026, 9, 15, 5, 2),
      );

      expect(abreGrupo(actual, anterior), isTrue);
      expect(llevaNombre(actual, anterior, _yo), isTrue);
    });

    test('el mismo día en Lima no abre grupo aunque en UTC cambie el día', () {
      // 23:50 UTC del 14 y 00:10 UTC del 15 son 18:50 y 19:10 del 14 en Lima.
      final anterior = _msg(
        id: '1',
        senderId: '503',
        createdAt: DateTime.utc(2026, 9, 14, 23, 50),
      );
      final actual = _msg(
        id: '2',
        senderId: '503',
        createdAt: DateTime.utc(2026, 9, 15, 0, 10),
      );

      expect(abreGrupo(actual, anterior), isFalse);
    });

    test(
      'si el anterior es una lápida, abre grupo y el ajeno lleva nombre',
      () {
        final lapida = _msg(
          id: '1',
          senderId: '503',
          createdAt: base,
          deleted: true,
        );
        final actual = _msg(
          id: '2',
          senderId: '503',
          createdAt: base.add(const Duration(minutes: 1)),
        );

        expect(abreGrupo(actual, lapida), isTrue);
        expect(llevaNombre(actual, lapida, _yo), isTrue);
      },
    );

    test('una lápida nunca lleva nombre', () {
      final anterior = _msg(id: '1', senderId: '504', createdAt: base);
      final lapida = _msg(
        id: '2',
        senderId: '503',
        createdAt: base.add(const Duration(minutes: 1)),
        deleted: true,
      );

      expect(abreGrupo(lapida, anterior), isTrue);
      expect(llevaNombre(lapida, anterior, _yo), isFalse);
      expect(llevaNombre(lapida, null, _yo), isFalse);
    });

    test('un mensaje propio nunca lleva nombre, aunque abra grupo', () {
      final anterior = _msg(id: '1', senderId: '503', createdAt: base);
      final propio = _msg(
        id: '2',
        senderId: _yo,
        createdAt: base.add(const Duration(minutes: 1)),
      );

      expect(abreGrupo(propio, anterior), isTrue);
      expect(llevaNombre(propio, anterior, _yo), isFalse);
    });

    test('un mensaje de carnet sigue la misma regla', () {
      final anterior = _msg(id: '1', senderId: '503', createdAt: base);
      final carnetMismo = _msg(
        id: '2',
        senderId: '503',
        createdAt: base.add(const Duration(minutes: 1)),
        messageType: 'networking_card',
      );
      final carnetOtro = _msg(
        id: '3',
        senderId: '504',
        createdAt: base.add(const Duration(minutes: 2)),
        messageType: 'networking_card',
      );

      expect(carnetMismo.isNetworkingCard, isTrue);
      expect(abreGrupo(carnetMismo, anterior), isFalse);
      expect(llevaNombre(carnetMismo, anterior, _yo), isFalse);
      expect(abreGrupo(carnetOtro, carnetMismo), isTrue);
      expect(llevaNombre(carnetOtro, carnetMismo, _yo), isTrue);
    });
  });
}
