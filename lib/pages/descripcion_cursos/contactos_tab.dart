import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../components/descripcion_cursos/contacto_card.dart';
import '../../components/error_retry.dart';
import '../../components/networking/networking_card_preview.dart';
import '../../components/skeleton.dart';
import '../../models/networking_model.dart';
import '../../services/auth_service.dart';
import 'descrip_cursos_controller.dart';

class ContactosTab extends StatelessWidget {
  final String idSeccion;
  final DescripCursosController control = Get.find();

  ContactosTab({super.key, required this.idSeccion});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Obx(() {
      if (control.isLoading.value &&
          control.docenteContacto.value == null &&
          control.alumnosContacto.isEmpty) {
        return const SkeletonCardList(count: 4, padding: EdgeInsets.all(16));
      }
      // Un fallo de carga se muestra como error con reintentar, no como una
      // lista de contactos vacía (que parecía una sección sin alumnos/docente).
      if (control.contactosError.value &&
          control.docenteContacto.value == null &&
          control.alumnosContacto.isEmpty) {
        return ErrorRetry(
          compact: true,
          title: 'No se pudieron cargar los contactos',
          onRetry: () => control.fetchContactos(idSeccion),
        );
      }
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        children: [
          Text(
            'DOCENTE',
            style: TextStyle(
              color: colors.secondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (control.docenteContacto.value != null)
            ContactoCard(
              nombres: control.docenteContacto.value!.firstName,
              apellidos: control.docenteContacto.value!.lastName,
              rol: 'docente',
              networkingVisible:
                  control.docenteContacto.value!.networking?.optIn ?? false,
              onNetworkingTap: () => _showNetworkingCard(
                context,
                fullName: control.docenteContacto.value!.fullName,
                primaryDetail:
                    '${control.docenteContacto.value!.code} - Docente',
                secondaryDetail: '',
                networking: control.docenteContacto.value!.networking,
              ),
            ),
          // HU18: grupo Jefe de Práctica (solo si la sección tiene JP).
          if (control.jpContacto.value != null) ...[
            const SizedBox(height: 22),
            Text(
              'JEFE DE PRÁCTICA',
              style: TextStyle(
                color: colors.secondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ContactoCard(
              nombres: control.jpContacto.value!.firstName,
              apellidos: control.jpContacto.value!.lastName,
              rol: 'jp',
              networkingVisible:
                  control.jpContacto.value!.networking?.optIn ?? false,
              onNetworkingTap: () => _showNetworkingCard(
                context,
                fullName: control.jpContacto.value!.fullName,
                primaryDetail:
                    '${control.jpContacto.value!.code} - Jefe de Practica',
                secondaryDetail: '',
                networking: control.jpContacto.value!.networking,
              ),
            ),
          ],
          const SizedBox(height: 22),
          Text(
            'ALUMNOS',
            style: TextStyle(
              color: colors.secondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          // Delegados que miUlima publica pero que todavía no usan ULima++.
          // Van PRIMERO, como los delegados con cuenta: el orden de la lista
          // es por cargo, y que uno no se haya instalado la app no lo mueve de
          // lugar. No abren el carnet: no hay carnet que abrir.
          ...control.representantesPendientes.map(
            (rep) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ContactoCard(
                nombres: rep.firstName,
                apellidos: rep.lastName,
                rol: rep.rolEnEspanol,
                networkingVisible: false,
                enUlimaPlus: false,
              ),
            ),
          ),
          ...control.alumnosContacto.map((contacto) {
            final user = contacto.user;
            final role = contacto.roleInSection;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ContactoCard(
                nombres: user.firstName,
                apellidos: user.lastName,
                rol: role,
                networkingVisible: contacto.networking?.optIn ?? false,
                onNetworkingTap: () => _showNetworkingCard(
                  context,
                  fullName: user.fullName,
                  primaryDetail: _careerName(user.careerId),
                  secondaryDetail: '${user.code} - ${_roleLabel(role)}',
                  networking: contacto.networking,
                ),
              ),
            );
          }),
        ],
      );
    });
  }

  String _careerName(int? careerId) {
    if (!Get.isRegistered<AuthService>()) return '';
    return AuthService.to.getCareerName(careerId);
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'delegado':
        return 'Delegado';
      case 'subdelegado':
        return 'Subdelegado';
      default:
        return 'Alumno';
    }
  }

  void _showNetworkingCard(
    BuildContext context, {
    required String fullName,
    required String primaryDetail,
    required String secondaryDetail,
    required NetworkingCardDto? networking,
  }) {
    if (networking?.optIn != true) return;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final link = networking!.link;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: NetworkingCardPreview(
              fullName: fullName,
              primaryDetail: primaryDetail,
              secondaryDetail: secondaryDetail,
              optIn: networking.optIn,
              link: link,
              emptyLinkText: 'Carnet visible sin red compartida',
              onOpenLink: () => _openLink(link),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openLink(SocialLinkDto? link) async {
    final uri = Uri.tryParse(link?.url ?? '');
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
