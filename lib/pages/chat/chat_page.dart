import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ulima_plus/pages/chat/chat_linea_tiempo.dart';
import 'package:ulima_plus/pages/chat/chat_seis_siete.dart';
import 'package:ulima_plus/pages/chat/curso_avatar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../components/networking/networking_card_preview.dart';
import '../../components/seis_siete/tambaleo_seis_siete.dart';
import '../../configs/course_colors.dart';
import '../../configs/themes.dart';
import '../../models/networking_model.dart';
import '../../services/api_client.dart';
import '../../services/chat_repository.dart';
import '../../models/message.dart';

/// Chat en vivo de una sección (HU23), con la identidad de la app
/// (RF-CHAT-8 a RF-CHAT-12). Todos sus colores salen de `MaterialTheme`.
class ChatPage extends StatefulWidget {
  final String sectionId;
  final String courseName;

  /// Código visible de la sección, como «801». Nulo, vacío o con solo
  /// espacios, el subtítulo dice «Sin sección».
  final String? sectionCode;

  /// Color del curso para su círculo en el AppBar, el mismo de la grilla del
  /// horario. Sin él se usa el acento de la sección, como en las vistas del
  /// docente.
  final Color? courseColor;

  /// Inyectable para tests; en producción usa el `ChatRepository` real.
  final ChatRepositoryContract? repository;

  const ChatPage({
    super.key,
    required this.sectionId,
    required this.courseName,
    this.sectionCode,
    this.courseColor,
    this.repository,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatRepositoryContract _chatRepository =
      widget.repository ?? ChatRepository();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  ChatSession? _session;
  String? _loadError;
  bool _isLoading = true;

  /// Stream de mensajes de la página. Se crea una sola vez, cuando la sesión
  /// queda lista, y el `StreamBuilder` recibe siempre esta misma instancia,
  /// así que una reconstrucción no vuelve a suscribirse (RF-CHAT-2). Trae
  /// dentro la revisión del 67, porque el stream de Firebase admite un solo
  /// oyente (RF-67-6).
  Stream<List<ChatMessage>>? _mensajes;

  /// Ids ya vistos por la página y regla del 67 en vivo (RF-67-6).
  final DetectorSeisSiete _detectorSeisSiete = DetectorSeisSiete();

  /// Contador de disparos del tambaleo. Solo sube (RF-67-2).
  final ValueNotifier<int> _disparosSeisSiete = ValueNotifier<int>(0);

  Brightness get _brillo => Theme.of(context).brightness;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  /// Aviso de error: blanco sobre `errorBg` (RF-CHAT-8).
  void _avisoDeError(String titulo, String mensaje) {
    Get.snackbar(
      titulo,
      mensaje,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: MaterialTheme.errorBg(_brillo),
      colorText: Colors.white,
    );
  }

  /// Aviso que no es de error: tarjeta de la app con borde y texto en
  /// `textPrimary` (RF-CHAT-8).
  void _aviso(String titulo, String mensaje) {
    Get.snackbar(
      titulo,
      mensaje,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: MaterialTheme.cardBg(_brillo),
      colorText: MaterialTheme.textPrimary(_brillo),
      borderColor: MaterialTheme.borderColor(_brillo),
      borderWidth: 1,
    );
  }

  Future<void> _initializeChat() async {
    try {
      final session = await _chatRepository
          .signInWithCustomToken(widget.sectionId)
          .timeout(const Duration(seconds: 8));
      if (mounted) {
        setState(() {
          _session = session;
          _mensajes = _chatRepository
              .getMessages(widget.sectionId)
              .map(_revisarSeisSiete);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadError = 'No se pudo conectar al chat.');
        _avisoDeError('Error', 'No se pudo conectar al chat');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Revisa cada lista una sola vez, al llegar del stream, y la devuelve sin
  /// cambios. Con la app en segundo plano marca los ids como vistos pero no
  /// dispara (RF-67-6).
  List<ChatMessage> _revisarSeisSiete(List<ChatMessage> mensajes) {
    final dispara = _detectorSeisSiete.revisar(mensajes);
    if (dispara && mounted && _enPrimerPlano()) {
      _disparosSeisSiete.value++;
    }
    return mensajes;
  }

  /// Con el estado nulo, `inactive` o `resumed` la app cuenta como visible.
  static bool _enPrimerPlano() =>
      switch (WidgetsBinding.instance.lifecycleState) {
        null || AppLifecycleState.resumed || AppLifecycleState.inactive => true,
        AppLifecycleState.paused ||
        AppLifecycleState.hidden ||
        AppLifecycleState.detached => false,
      };

  Future<void> _sendMessage() async {
    final session = _session;
    if (session == null) {
      _aviso('Chat no disponible', 'Vuelve a intentar en unos segundos.');
      return;
    }

    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    try {
      await _chatRepository.sendMessage(widget.sectionId, text, session);
    } catch (_) {
      if (!mounted) return;
      _textController.text = text;
      _avisoDeError('Error', 'No se pudo enviar el mensaje');
    }
  }

  Future<void> _sendNetworkingCard() async {
    final session = _session;
    if (session == null) {
      _aviso('Chat no disponible', 'Vuelve a intentar en unos segundos.');
      return;
    }

    final ownerId = int.tryParse(session.uid);
    if (ownerId == null) return;

    try {
      await _chatRepository.fetchNetworkingCard(ownerId);
      await _chatRepository.sendNetworkingCard(widget.sectionId, session);
    } on ApiException catch (error) {
      if (!mounted) return;
      _aviso(
        'Carnet no disponible',
        error.code == 'NETWORKING_CARD_HIDDEN'
            ? 'Activa "Mostrar mi carnet" antes de enviarlo.'
            : error.message,
      );
    } catch (_) {
      if (!mounted) return;
      _aviso('No se pudo enviar', 'Intenta de nuevo en unos segundos.');
    }
  }

  Future<void> _openNetworkingCard(ChatMessage message) async {
    final ownerId = message.networkingOwnerId ?? int.tryParse(message.senderId);
    if (ownerId == null) return;

    try {
      final card = await _chatRepository.fetchNetworkingCard(ownerId);
      if (!mounted) return;
      _showNetworkingCardModal(card);
    } on ApiException catch (error) {
      if (!mounted) return;
      _aviso(
        'Carnet no disponible',
        error.code == 'NETWORKING_CARD_HIDDEN'
            ? 'Este usuario oculto su carnet.'
            : error.message,
      );
    } catch (_) {
      if (!mounted) return;
      _aviso('Carnet no disponible', 'No se pudo abrir este carnet.');
    }
  }

  void _showNetworkingCardModal(PublicNetworkingCardDto card) {
    final link = card.link;
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: NetworkingCardPreview(
            fullName: card.owner.fullName,
            primaryDetail: card.owner.primaryDetail,
            secondaryDetail: card.owner.secondaryDetail,
            optIn: card.card.optIn,
            link: link,
            emptyLinkText: 'Carnet visible sin red compartida',
            onOpenLink: () => _openNetworkingLink(link),
          ),
        ),
      ),
    );
  }

  Future<void> _openNetworkingLink(SocialLinkDto? link) async {
    final uri = Uri.tryParse(link?.url ?? '');
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// HU23: el autor o el profesor titular confirma y elimina un mensaje
  /// (borrado suave, RF-CHAT-4). El backend valida la autoría contra el
  /// `senderId` guardado; el stream de RTDB trae la lápida.
  Future<void> _confirmDelete(ChatMessage msg) async {
    final brillo = _brillo;
    final texto = MaterialTheme.textPrimary(brillo);
    // Lo propio se decide por senderId, como en RF-CHAT-9, no por el nombre.
    final esPropio = _esPropio(msg);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MaterialTheme.cardBg(brillo),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '¿Eliminar mensaje?',
          style: TextStyle(fontWeight: FontWeight.w800, color: texto),
        ),
        // Solo el profesor titular llega aquí con un mensaje ajeno (RF-CHAT-4).
        content: Text(
          esPropio
              ? 'Se eliminará para todos.'
              : 'Se eliminará para todos y verán que lo eliminaste tú.',
          style: TextStyle(fontSize: 13.5, color: texto),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: texto),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: MaterialTheme.errorBg(brillo),
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _chatRepository.deleteMessage(widget.sectionId, msg.id);
    } on ApiException catch (error) {
      if (!mounted) return;
      // Un 403 (CHAT_DELETE_FORBIDDEN) trae el motivo del servidor.
      _avisoDeError(
        'No se pudo eliminar',
        error.statusCode == 403 && error.message.trim().isNotEmpty
            ? error.message
            : 'Inténtalo de nuevo en unos segundos.',
      );
    } catch (_) {
      if (!mounted) return;
      _avisoDeError(
        'No se pudo eliminar',
        'Inténtalo de nuevo en unos segundos.',
      );
    }
  }

  /// El mensaje es de la sesión actual: su `senderId` es el `uid` de la sesión.
  bool _esPropio(ChatMessage msg) {
    final uid = _session?.uid ?? '';
    return uid.isNotEmpty && msg.senderId == uid;
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Widget _buildUnavailableState(Brightness brillo) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _TarjetaDeEstado(
          brillo: brillo,
          icono: Icons.lock_clock,
          tamanoIcono: 34,
          titulo: _loadError ?? 'Chat no disponible.',
          tamanoTitulo: 14,
          cuerpo: 'Solo los miembros de esta sección pueden entrar al chat.',
          tamanoCuerpo: 13,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _disparosSeisSiete.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brillo = _brillo;
    final colorCurso =
        widget.courseColor ??
        courseAccentColor(int.tryParse(widget.sectionId) ?? 0);

    final pantalla = Scaffold(
      backgroundColor: MaterialTheme.pageBg(brillo),
      appBar: AppBar(
        backgroundColor: MaterialTheme.headerColor(brillo),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CursoAvatar(nombre: widget.courseName, color: colorCurso, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.courseName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    etiquetaDeSeccion(widget.sectionCode),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null || _session == null
          ? _buildUnavailableState(brillo)
          : Column(
              children: [
                Expanded(child: _buildMessages(_session!, _mensajes!, brillo)),
                _BarraDeEscritura(
                  brillo: brillo,
                  controller: _textController,
                  onEnviar: _sendMessage,
                  onEnviarCarnet: _sendNetworkingCard,
                ),
              ],
            ),
    );

    // El truco del 67 inclina toda la pantalla, AppBar incluido, y pinta el
    // rótulo encima (RF-67-2 y RF-67-7). La pantalla se arma fuera del
    // builder, así que un disparo solo reconstruye el envoltorio.
    return ValueListenableBuilder<int>(
      valueListenable: _disparosSeisSiete,
      builder: (context, disparos, pantalla) => TambaleoSeisSiete(
        disparos: disparos,
        conRotulo: true,
        child: pantalla!,
      ),
      child: pantalla,
    );
  }

  Widget _buildMessages(
    ChatSession session,
    Stream<List<ChatMessage>> mensajes,
    Brightness brillo,
  ) {
    return StreamBuilder<List<ChatMessage>>(
      stream: mensajes,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Error: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: TextStyle(color: MaterialTheme.textSecondary(brillo)),
              ),
            ),
          );
        }

        final messages = snapshot.data ?? [];
        if (messages.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: _TarjetaDeEstado(
                brillo: brillo,
                icono: Icons.lock_outline_rounded,
                tamanoIcono: 30,
                titulo: 'Chat privado de la sección',
                tamanoTitulo: 14,
                cuerpo:
                    'Solo los miembros de esta sección pueden leer y escribir. Sé el primero en saludar 👋',
                tamanoCuerpo: 12.5,
              ),
            ),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        // «Hoy» y «Ayer» se comparan con la fecha actual en Lima (RF-CHAT-11).
        final hoyLima = enHoraDeLima(DateTime.now());

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            final anterior = index > 0 ? messages[index - 1] : null;
            final esPropio = _esPropio(msg);
            // RF-CHAT-4: el autor borra los suyos, con cualquier rol, y el
            // profesor titular, cualquiera. Nadie borra una lápida.
            final canDelete =
                !msg.deleted && (esPropio || session.role == 'teacher');

            final burbuja = _MessageBubble(
              message: msg,
              isMe: esPropio,
              abreGrupo: abreGrupo(msg, anterior),
              muestraNombre: llevaNombre(msg, anterior, session.uid),
              timeText: horaDeMensaje(msg.createdAt),
              brillo: brillo,
              onDelete: canDelete ? () => _confirmDelete(msg) : null,
              onOpenNetworkingCard: msg.isNetworkingCard
                  ? () => _openNetworkingCard(msg)
                  : null,
            );
            if (!abreDia(msg, anterior)) return burbuja;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SeparadorDeDia(
                  texto: etiquetaDeDia(enHoraDeLima(msg.createdAt), hoyLima),
                  brillo: brillo,
                ),
                burbuja,
              ],
            );
          },
        );
      },
    );
  }
}

/// Estado vacío o de chat no disponible: la tarjeta de la app con un candado
/// naranja, el título en `textPrimary` y el cuerpo en `textSecondary`.
class _TarjetaDeEstado extends StatelessWidget {
  const _TarjetaDeEstado({
    required this.brillo,
    required this.icono,
    required this.tamanoIcono,
    required this.titulo,
    required this.tamanoTitulo,
    required this.cuerpo,
    required this.tamanoCuerpo,
  });

  final Brightness brillo;
  final IconData icono;
  final double tamanoIcono;
  final String titulo;
  final double tamanoTitulo;
  final String cuerpo;
  final double tamanoCuerpo;

  @override
  Widget build(BuildContext context) {
    final candado = MaterialTheme.iconoNaranja(brillo);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MaterialTheme.cardBg(brillo),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MaterialTheme.borderColor(brillo)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, color: candado, size: tamanoIcono),
          const SizedBox(height: 10),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: tamanoTitulo,
              fontWeight: FontWeight.w800,
              color: MaterialTheme.textPrimary(brillo),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            cuerpo,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: tamanoCuerpo,
              color: MaterialTheme.textSecondary(brillo),
            ),
          ),
        ],
      ),
    );
  }
}

/// Separador centrado antes del primer mensaje de cada día (RF-CHAT-11).
class _SeparadorDeDia extends StatelessWidget {
  const _SeparadorDeDia({required this.texto, required this.brillo});

  final String texto;
  final Brightness brillo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Semantics(
        header: true,
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: MaterialTheme.textSecondary(brillo),
          ),
        ),
      ),
    );
  }
}

/// Barra de escritura (RF-CHAT-12): «Enviar carnet», el campo y el botón
/// enviar, que se ve deshabilitado mientras el campo recortado está vacío.
class _BarraDeEscritura extends StatelessWidget {
  const _BarraDeEscritura({
    required this.brillo,
    required this.controller,
    required this.onEnviar,
    required this.onEnviarCarnet,
  });

  final Brightness brillo;
  final TextEditingController controller;
  final VoidCallback onEnviar;
  final VoidCallback onEnviarCarnet;

  @override
  Widget build(BuildContext context) {
    final naranja = MaterialTheme.iconoNaranja(brillo);

    return Container(
      decoration: BoxDecoration(
        color: MaterialTheme.cardBg(brillo),
        border: Border(
          top: BorderSide(color: MaterialTheme.borderColor(brillo)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: MaterialTheme.tagBg(brillo),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Enviar carnet',
                      onPressed: onEnviarCarnet,
                      icon: Icon(LucideIcons.idCard, size: 21, color: naranja),
                      visualDensity: VisualDensity.compact,
                    ),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 4,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: 'Escribe un mensaje...',
                          hintStyle: TextStyle(
                            color: MaterialTheme.textSecondary(brillo),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 10,
                          ),
                        ),
                        style: TextStyle(
                          color: MaterialTheme.textPrimary(brillo),
                        ),
                        onSubmitted: (_) => onEnviar(),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, valor, _) => _BotonEnviar(
                brillo: brillo,
                habilitado: valor.text.trim().isNotEmpty,
                onEnviar: onEnviar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón enviar: círculo `primaryDark` con `Icons.send` en blanco. Con el
/// campo recortado vacío se ve deshabilitado: `tagBg` con el ícono en
/// `textMuted`, sin sombra, ripple ni respuesta de toque y con la semántica de
/// un botón deshabilitado (RF-CHAT-12).
class _BotonEnviar extends StatelessWidget {
  const _BotonEnviar({
    required this.brillo,
    required this.habilitado,
    required this.onEnviar,
  });

  final Brightness brillo;
  final bool habilitado;
  final VoidCallback onEnviar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      enabled: habilitado,
      child: Tooltip(
        message: 'Enviar mensaje',
        child: Material(
          color: habilitado
              ? MaterialTheme.primaryDark
              : MaterialTheme.tagBg(brillo),
          shape: const CircleBorder(),
          elevation: habilitado ? 2 : 0,
          child: InkWell(
            customBorder: const CircleBorder(),
            // El toque siempre llega a enviar, que no manda un campo vacío,
            // igual que la tecla del teclado. Así también envía un toque que
            // llega justo después de escribir, antes de que el botón se
            // repinte habilitado.
            onTap: onEnviar,
            // Deshabilitado: sin ripple, sin resaltado, sin la respuesta de
            // toque de la plataforma (el clic de Android) y sin la acción de
            // toque en la semántica.
            enableFeedback: habilitado,
            excludeFromSemantics: !habilitado,
            canRequestFocus: habilitado,
            splashFactory: habilitado ? null : NoSplash.splashFactory,
            overlayColor: habilitado
                ? null
                : const WidgetStatePropertyAll(Colors.transparent),
            mouseCursor: habilitado ? null : SystemMouseCursors.basic,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(
                Icons.send,
                color: habilitado
                    ? Colors.white
                    : MaterialTheme.textMuted(brillo),
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Burbuja de un mensaje: propia en `chatOwnBubbleBg`, ajena en `cardBg` con
/// borde. El nombre y la etiqueta de rol solo van en un ajeno que abre grupo
/// (RF-CHAT-9 y RF-CHAT-10).
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool abreGrupo;
  final bool muestraNombre;
  final String timeText;
  final Brightness brillo;

  /// Solo se pasa cuando el mensaje no está eliminado y es propio o la sesión
  /// es el profesor titular: habilita el long-press para eliminar (RF-CHAT-4).
  final VoidCallback? onDelete;
  final VoidCallback? onOpenNetworkingCard;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.abreGrupo,
    required this.muestraNombre,
    required this.timeText,
    required this.brillo,
    this.onDelete,
    this.onOpenNetworkingCard,
  });

  @override
  Widget build(BuildContext context) {
    // HU23: mensaje eliminado → lápida "eliminado por…".
    if (message.deleted) {
      return _DeletedTombstone(message: message, isMe: isMe, brillo: brillo);
    }

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(12),
      topRight: const Radius.circular(12),
      bottomLeft: Radius.circular(isMe ? 12 : 0),
      bottomRight: Radius.circular(isMe ? 0 : 12),
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      // Long-press: solo si se puede eliminar (onDelete != null).
      child: GestureDetector(
        onLongPress: onDelete,
        onTap: message.isNetworkingCard ? onOpenNetworkingCard : null,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          margin: EdgeInsets.only(
            top: abreGrupo ? 8 : 2,
            bottom: 2,
            left: isMe ? 48 : 0,
            right: isMe ? 0 : 48,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isMe
                ? MaterialTheme.chatOwnBubbleBg(brillo)
                : MaterialTheme.cardBg(brillo),
            borderRadius: borderRadius,
            border: isMe
                ? null
                : Border.all(color: MaterialTheme.borderColor(brillo)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (muestraNombre)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 2,
                    children: [
                      Text(
                        message.senderName,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: MaterialTheme.textPrimary(brillo),
                        ),
                      ),
                      // Un moderador se distingue solo por esta etiqueta,
                      // como texto y sin fondo (RF-CHAT-10).
                      if (message.isModerator &&
                          message.senderRoleLabel.isNotEmpty)
                        Text(
                          message.senderRoleLabel,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: MaterialTheme.textSecondary(brillo),
                          ),
                        ),
                    ],
                  ),
                ),
              if (message.isNetworkingCard)
                _NetworkingCardMessage(timeText: timeText, brillo: brillo)
              else
                Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 8,
                  children: [
                    Text(
                      message.text,
                      style: TextStyle(
                        fontSize: 15.5,
                        color: MaterialTheme.textPrimary(brillo),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        timeText,
                        style: TextStyle(
                          fontSize: 11,
                          color: MaterialTheme.textSecondary(brillo),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NetworkingCardMessage extends StatelessWidget {
  const _NetworkingCardMessage({required this.timeText, required this.brillo});

  final String timeText;
  final Brightness brillo;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: MaterialTheme.primaryDark,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(LucideIcons.idCard, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 9),
        Flexible(
          child: Text(
            'Envio su carnet de networking',
            style: TextStyle(
              color: MaterialTheme.textPrimary(brillo),
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          timeText,
          style: TextStyle(
            fontSize: 11,
            color: MaterialTheme.textSecondary(brillo),
          ),
        ),
      ],
    );
  }
}

/// HU23: lápida de un mensaje eliminado (RF-CHAT-4). Reemplaza al bubble
/// normal; mantiene el lado (izq/der) del emisor original, en `tagBg` con el
/// texto y el ícono en `textSecondary`. Si lo borró su autor, el autor lee
/// «Eliminaste este mensaje» y los demás «Se eliminó este mensaje»; si lo borró
/// otra persona, todos leen «Mensaje eliminado por» y el nombre de `deletedBy`.
class _DeletedTombstone extends StatelessWidget {
  const _DeletedTombstone({
    required this.message,
    required this.isMe,
    required this.brillo,
  });

  final ChatMessage message;
  final bool isMe;
  final Brightness brillo;

  String get _texto {
    if (message.deletedBySender) {
      return isMe ? 'Eliminaste este mensaje' : 'Se eliminó este mensaje';
    }
    final by = (message.deletedBy != null && message.deletedBy!.isNotEmpty)
        ? message.deletedBy!
        : 'el profesor';
    return 'Mensaje eliminado por $by';
  }

  @override
  Widget build(BuildContext context) {
    final fg = MaterialTheme.textSecondary(brillo);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: EdgeInsets.only(
          top: 8,
          bottom: 2,
          left: isMe ? 48 : 0,
          right: isMe ? 0 : 48,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: MaterialTheme.tagBg(brillo),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: MaterialTheme.borderColor(brillo)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.do_not_disturb_on_outlined, size: 15, color: fg),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                _texto,
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
