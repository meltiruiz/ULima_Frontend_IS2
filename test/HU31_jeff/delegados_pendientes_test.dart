import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulima_plus/components/descripcion_cursos/contacto_card.dart';
import 'package:ulima_plus/models/contacto_model.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/contacto_service.dart';

/// Delegados que miUlima publica pero que todavía no usan ULima++.
///
/// El caso que estas pruebas protegen es el de adopción: de un salón de 40, el
/// primero que instala la app sincroniza y la app ya sabe quién es el delegado
/// aunque esa persona no tenga cuenta. Sin eso, la pantalla de contactos
/// mentiría por omisión hasta que el delegado se instalara la app.

class _FakeApiClient extends ApiClient {
  _FakeApiClient(this.respuesta) : super(configuredBaseUrl: 'http://test');

  final Map<String, dynamic> respuesta;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    String? token,
    Map<String, String?> query = const {},
  }) async => respuesta;
}

Map<String, dynamic> _respuesta({List<Map<String, dynamic>>? pendientes}) {
  final base = <String, dynamic>{
    'docente': null,
    'jefePractica': null,
    'alumnos': <dynamic>[],
  };
  // Sin la clave se simula un backend viejo, que es un caso que se prueba.
  if (pendientes != null) base['representantesPendientes'] = pendientes;
  return base;
}

void main() {
  group('RepresentantePendiente.fromJson', () {
    test('mapea los campos y traduce el cargo al vocabulario de la tarjeta', () {
      final r = RepresentantePendiente.fromJson({
        'code': '20209999',
        'firstName': 'JUAN CARLOS',
        'lastName': 'PEREZ RAMIREZ',
        'position': 'delegate',
        'contactable': false,
      });

      expect(r.code, '20209999');
      expect(r.firstName, 'JUAN CARLOS');
      expect(r.lastName, 'PEREZ RAMIREZ');
      // La tarjeta pinta el badge mirando 'delegado'/'subdelegado', el mismo
      // vocabulario que usa roleInSection para los alumnos CON cuenta: así no
      // necesita saber de dónde salió el dato.
      expect(r.rolEnEspanol, 'delegado');
    });

    test('subdelegate también se traduce', () {
      final r = RepresentantePendiente.fromJson({'position': 'subdelegate'});
      expect(r.rolEnEspanol, 'subdelegado');
    });

    test('contactable llega en false y NUNCA se asume lo contrario', () {
      // El backend lo manda siempre false, pero si faltara, el default seguro
      // es false: ofrecer escribirle a alguien que no está en la app es peor
      // que no ofrecerlo.
      expect(RepresentantePendiente.fromJson({}).contactable, isFalse);
      expect(
        RepresentantePendiente.fromJson({'contactable': true}).contactable,
        isTrue,
      );
    });
  });

  group('ContactoService', () {
    test('parsea representantesPendientes', () async {
      final servicio = ContactoService(
        api: _FakeApiClient(
          _respuesta(
            pendientes: [
              {
                'code': '20209999',
                'firstName': 'JUAN CARLOS',
                'lastName': 'PEREZ RAMIREZ',
                'position': 'delegate',
                'contactable': false,
              },
            ],
          ),
        ),
      );

      final data = await servicio.fetchContactos('1');
      final pendientes =
          data['representantesPendientes'] as List<RepresentantePendiente>;

      expect(pendientes, hasLength(1));
      expect(pendientes.single.rolEnEspanol, 'delegado');
    });

    test('si el backend no manda la clave, la lista queda vacía', () async {
      // Compatibilidad hacia atrás: un backend sin esta feature responde sin la
      // clave hermana y la pantalla debe comportarse como antes, no reventar.
      final servicio = ContactoService(api: _FakeApiClient(_respuesta()));
      final data = await servicio.fetchContactos('1');

      expect(data['representantesPendientes'], isEmpty);
      expect(data['alumnos'], isEmpty);
    });
  });

  group('cruce por código (regresión de producción 2026-09-04)', () {
    Map<String, dynamic> alumno(String code, {String rol = 'estudiante'}) => {
      'user': {'code': code, 'firstName': 'JUAN', 'lastName': 'PEREZ'},
      'roleInSection': rol,
      'networking': null,
    };

    test(
      'un delegado CON cuenta que nunca sincronizó recibe igual su badge',
      () async {
        // El caso que rompió en producción: el compañero existe como usuario
        // (cuenta sembrada) pero nunca importó, así que no tiene fila en
        // section_representative y el backend lo manda con roleInSection
        // "estudiante". Sin este cruce quedaba pintado como un alumno más y el
        // portal desmentido en pantalla.
        final servicio = ContactoService(
          api: _FakeApiClient({
            'docente': null,
            'jefePractica': null,
            'alumnos': [alumno('20209999')],
            'representantesPendientes': [
              {
                'code': '20209999',
                'firstName': 'JUAN',
                'lastName': 'PEREZ',
                'position': 'delegate',
                'contactable': false,
              },
            ],
          }),
        );

        final data = await servicio.fetchContactos('1');
        final alumnos = data['alumnos'] as List<ContactoCurso>;

        expect(alumnos.single.roleInSection, 'delegado');
        // Y NO se pinta aparte: eso lo duplicaría en la misma pantalla.
        expect(data['representantesPendientes'], isEmpty);
      },
    );

    test('el que no tiene cuenta sí se pinta aparte', () async {
      final servicio = ContactoService(
        api: _FakeApiClient({
          'docente': null,
          'jefePractica': null,
          'alumnos': [alumno('20200001')],
          'representantesPendientes': [
            {
              'code': '20209999',
              'firstName': 'ANA',
              'lastName': 'TORRES',
              'position': 'subdelegate',
              'contactable': false,
            },
          ],
        }),
      );

      final data = await servicio.fetchContactos('1');
      final pendientes =
          data['representantesPendientes'] as List<RepresentantePendiente>;

      expect(pendientes.single.code, '20209999');
      expect((data['alumnos'] as List).length, 1);
    });

    test('un cargo real del backend no lo pisa el claim', () async {
      // Si section_representative ya dice que es delegado, esa es la verdad
      // con permisos y el claim no debe degradarla ni cambiarla.
      final servicio = ContactoService(
        api: _FakeApiClient({
          'docente': null,
          'jefePractica': null,
          'alumnos': [alumno('20209999', rol: 'delegado')],
          'representantesPendientes': [
            {
              'code': '20209999',
              'firstName': 'JUAN',
              'lastName': 'PEREZ',
              'position': 'subdelegate',
              'contactable': false,
            },
          ],
        }),
      );

      final data = await servicio.fetchContactos('1');
      final alumnos = data['alumnos'] as List<ContactoCurso>;
      expect(alumnos.single.roleInSection, 'delegado');
    });
  });

  group('ContactoCard sin cuenta en ULima++', () {
    Widget montar(Widget hijo) =>
        MaterialApp(home: Scaffold(body: hijo));

    testWidgets('muestra el badge del cargo y la marca de ausencia', (
      tester,
    ) async {
      await tester.pumpWidget(
        montar(
          const ContactoCard(
            nombres: 'JUAN CARLOS',
            apellidos: 'PEREZ RAMIREZ',
            rol: 'delegado',
            enUlimaPlus: false,
          ),
        ),
      );

      expect(find.text('Delegado'), findsOneWidget);
      expect(find.text('Aún no está en ULima++'), findsOneWidget);
    });

    testWidgets('un contacto normal NO lleva la marca', (tester) async {
      await tester.pumpWidget(
        montar(
          const ContactoCard(
            nombres: 'ANA',
            apellidos: 'TORRES',
            rol: 'delegado',
          ),
        ),
      );

      expect(find.text('Delegado'), findsOneWidget);
      expect(find.text('Aún no está en ULima++'), findsNothing);
    });

    testWidgets('el botón de carnet queda inhabilitado', (tester) async {
      // Sin cuenta no hay carnet que abrir. Y el tooltip NO puede decir
      // "Carnet oculto": eso sugiere una decisión de privacidad de alguien que
      // ni siquiera está en la app.
      var tocado = false;
      await tester.pumpWidget(
        montar(
          ContactoCard(
            nombres: 'JUAN CARLOS',
            apellidos: 'PEREZ RAMIREZ',
            rol: 'delegado',
            enUlimaPlus: false,
            onNetworkingTap: () => tocado = true,
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(tocado, isFalse);
      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, 'Aún no está en ULima++');
    });
  });
}
