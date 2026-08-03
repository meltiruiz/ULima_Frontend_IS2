import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../components/skeleton.dart';
import '../../configs/themes.dart';
import '../../models/chatbot_models.dart';
import 'chatbot_controller.dart';

/// ULimaBot — asistente académico. Pantalla pulida: header de marca (naranja),
/// mensajes con markdown, animaciones de entrada, indicador de "escribiendo" y
/// auto-scroll. Toda la motion respeta el "reduce motion" del sistema.
class ChatbotPage extends StatelessWidget {
  const ChatbotPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChatbotController());
    final brightness = Theme.brightnessOf(context);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: MaterialTheme.pageBg(brightness),
      appBar: AppBar(
        backgroundColor: MaterialTheme.headerColor(brightness),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () {
            final isWide = MediaQuery.of(context).size.width > 600;
            if (!isWide && controller.activeSessionId.value != null) {
              controller.activeSessionId.value = null;
            } else {
              Get.back();
            }
          },
        ),
        title: Row(
          children: [
            const _BotAvatar(size: 30),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'ULimaBot',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Asistente académico',
                  style: TextStyle(fontSize: 11.5, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            tooltip: 'Nueva conversación',
            onPressed: () => controller.createSession(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          return _buildBody(controller, colors, brightness, isWide);
        },
      ),
    );
  }

  Widget _buildBody(
      ChatbotController controller, ColorScheme colors, Brightness brightness, bool isWide) {
    return Obx(() {
      if (controller.loadingSessions.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.sessions.isEmpty) {
        return _EmptyConversations(
          brightness: brightness,
          onCreate: () => controller.createSession(),
        );
      }

      if (isWide) {
        return Row(
          children: [
            SizedBox(
              width: 288,
              child: _buildSessionList(controller, colors, brightness),
            ),
            VerticalDivider(width: 1, color: MaterialTheme.borderColor(brightness)),
            Expanded(child: _ChatArea(controller: controller, brightness: brightness)),
          ],
        );
      }

      if (controller.activeSessionId.value == null) {
        return _buildSessionList(controller, colors, brightness);
      }

      return _ChatArea(controller: controller, brightness: brightness);
    });
  }

  Widget _buildSessionList(
      ChatbotController controller, ColorScheme colors, Brightness brightness) {
    return Obx(() {
      return ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: controller.sessions.length,
        separatorBuilder: (_, _) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final session = controller.sessions[index];
          final isActive = session.id == controller.activeSessionId.value;

          return Dismissible(
            key: Key(session.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 18),
              decoration: BoxDecoration(
                color: colors.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.trash2, color: Colors.white),
            ),
            confirmDismiss: (_) async {
              return await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Eliminar conversación'),
                      content: const Text('¿Estás seguro de eliminar esta conversación?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text('Eliminar', style: TextStyle(color: colors.error)),
                        ),
                      ],
                    ),
                  ) ??
                  false;
            },
            onDismissed: (_) => controller.deleteSession(session.id),
            child: Material(
              color: isActive
                  ? MaterialTheme.primaryColor.withValues(alpha: 0.10)
                  : MaterialTheme.cardBg(brightness),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => controller.selectSession(session.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.messageSquare,
                        size: 20,
                        color: isActive
                            ? MaterialTheme.primaryColor
                            : MaterialTheme.textMuted(brightness),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                color: MaterialTheme.textPrimary(brightness),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDate(session.updatedAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: MaterialTheme.textMuted(brightness),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }

  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inHours < 1) return '${diff.inMinutes} min';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays == 1) return 'Ayer';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Área de chat (StatefulWidget: dueña del ScrollController + TextEditingController
// y del auto-scroll al llegar mensajes / aparecer el indicador de escritura).
// ─────────────────────────────────────────────────────────────────────────────
class _ChatArea extends StatefulWidget {
  const _ChatArea({required this.controller, required this.brightness});

  final ChatbotController controller;
  final Brightness brightness;

  @override
  State<_ChatArea> createState() => _ChatAreaState();
}

class _ChatAreaState extends State<_ChatArea> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _text = TextEditingController();
  Worker? _msgWorker;
  Worker? _typingWorker;
  Worker? _loadWorker;
  bool _showScrollDown = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _msgWorker = ever(widget.controller.messages, (_) => _scrollToBottom());
    _typingWorker = ever(widget.controller.isTyping, (_) => _scrollToBottom());
    // Al abrir/cambiar de conversación: cuando terminan de cargar los mensajes,
    // arrancar posicionado en el ÚLTIMO mensaje (sin animación). Antes esto no
    // pasaba porque durante la carga se ve el skeleton y el ScrollController aún
    // no tiene el ListView, así que el auto-scroll no agarraba y quedaba arriba.
    _loadWorker = ever(widget.controller.loadingMessages, (loading) {
      if (loading == false) _scrollToBottom(animate: false);
    });
    // Caso: los mensajes ya estaban cargados cuando se montó este widget.
    _scrollToBottom(animate: false);
  }

  // Muestra el botón "bajar" cuando el usuario se alejó del final.
  void _onScroll() {
    if (!_scroll.hasClients) return;
    final show = _scroll.position.maxScrollExtent - _scroll.position.pixels > 200;
    if (show != _showScrollDown) {
      setState(() => _showScrollDown = show);
    }
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final target = _scroll.position.maxScrollExtent;
      if (animate && !MediaQuery.of(context).disableAnimations) {
        _scroll.animateTo(
          target,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scroll.jumpTo(target);
      }
      if (_showScrollDown && mounted) setState(() => _showScrollDown = false);
    });
  }

  void _submit() {
    final value = _text.text.trim();
    if (value.isEmpty || widget.controller.isTyping.value) return;
    widget.controller.sendQuestion(value);
    _text.clear();
  }

  @override
  void dispose() {
    _msgWorker?.dispose();
    _typingWorker?.dispose();
    _loadWorker?.dispose();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = widget.brightness;
    final controller = widget.controller;

    return Column(
      children: [
        Expanded(
          child: Obx(() {
            if (controller.loadingMessages.value) {
              return const SkeletonCardList(count: 6);
            }

            final count = controller.messages.length + (controller.isTyping.value ? 1 : 0);

            if (count == 0) {
              return _EmptyChat(brightness: brightness);
            }

            return Stack(
              children: [
                ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                  itemCount: count,
                  itemBuilder: (context, index) {
                    if (index >= controller.messages.length) {
                      return _TypingBubble(brightness: brightness);
                    }
                    return _MessageBubble(
                      message: controller.messages[index],
                      brightness: brightness,
                    );
                  },
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: _ScrollDownButton(
                    visible: _showScrollDown,
                    brightness: brightness,
                    onTap: _scrollToBottom,
                  ),
                ),
              ],
            );
          }),
        ),
        _InputBar(
          controller: _text,
          brightness: brightness,
          isTyping: controller.isTyping,
          onSubmit: _submit,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Botón flotante "bajar al último mensaje" (aparece al alejarse del final).
// ─────────────────────────────────────────────────────────────────────────────
class _ScrollDownButton extends StatelessWidget {
  const _ScrollDownButton({
    required this.visible,
    required this.brightness,
    required this.onTap,
  });

  final bool visible;
  final Brightness brightness;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedScale(
        scale: visible ? 1 : 0.6,
        duration: Duration(milliseconds: reduce ? 0 : 180),
        curve: Curves.easeOutBack,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: Duration(milliseconds: reduce ? 0 : 160),
          child: Material(
            color: MaterialTheme.cardBg(brightness),
            shape: CircleBorder(
              side: BorderSide(color: MaterialTheme.borderColor(brightness)),
            ),
            elevation: 3,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(9),
                child: Icon(
                  LucideIcons.chevronDown,
                  size: 22,
                  color: MaterialTheme.textPrimary(brightness),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Barra de entrada
// ─────────────────────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.brightness,
    required this.isTyping,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final Brightness brightness;
  final RxBool isTyping;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: MaterialTheme.cardBg(brightness),
        border: Border(top: BorderSide(color: MaterialTheme.borderColor(brightness))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                maxLength: 500,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                style: TextStyle(color: MaterialTheme.textPrimary(brightness)),
                decoration: InputDecoration(
                  hintText: 'Escribe tu pregunta...',
                  counterText: '',
                  filled: true,
                  fillColor: MaterialTheme.pageBg(brightness),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: MaterialTheme.borderColor(brightness)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: MaterialTheme.primaryColor, width: 1.6),
                  ),
                ),
                onSubmitted: (_) => onSubmit(),
              ),
            ),
            const SizedBox(width: 8),
            Obx(() {
              final busy = isTyping.value;
              return AnimatedScale(
                scale: busy ? 0.9 : 1.0,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                child: Material(
                  color: busy
                      ? MaterialTheme.primaryColor.withValues(alpha: 0.5)
                      : MaterialTheme.primaryColor,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: busy ? null : onSubmit,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(LucideIcons.send, size: 20, color: Colors.white),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Burbuja de mensaje (con entrada animada + avatar del bot + markdown)
// ─────────────────────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.brightness});

  final ChatbotMessage message;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final maxW = MediaQuery.of(context).size.width * (isUser ? 0.78 : 0.82);

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxW),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isUser ? MaterialTheme.primaryColor : MaterialTheme.cardBg(brightness),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 5),
          bottomRight: Radius.circular(isUser ? 5 : 18),
        ),
        border: isUser ? null : Border.all(color: MaterialTheme.borderColor(brightness)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: brightness == Brightness.dark ? 0.22 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: _MarkdownText(
        message.content,
        color: isUser ? Colors.white : MaterialTheme.textPrimary(brightness),
      ),
    );

    final row = Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isUser) ...[
          const _BotAvatar(size: 24),
          const SizedBox(width: 8),
        ],
        Flexible(child: bubble),
      ],
    );

    return _MessageEntrance(
      fromRight: isUser,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: row,
      ),
    );
  }
}

/// Entrada animada (fade + slide). Respeta el "reduce motion" del sistema.
class _MessageEntrance extends StatefulWidget {
  const _MessageEntrance({required this.child, required this.fromRight});

  final Widget child;
  final bool fromRight;

  @override
  State<_MessageEntrance> createState() => _MessageEntranceState();
}

class _MessageEntranceState extends State<_MessageEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _t = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reduce motion: sin animación de entrada.
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) {
        final v = _t.value;
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset((widget.fromRight ? 18 : -18) * (1 - v), 10 * (1 - v)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Indicador "escribiendo…" (3 puntos animados)
// ─────────────────────────────────────────────────────────────────────────────
class _TypingBubble extends StatefulWidget {
  const _TypingBubble({required this.brightness});
  final Brightness brightness;

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return _MessageEntrance(
      fromRight: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const _BotAvatar(size: 24),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: MaterialTheme.cardBg(widget.brightness),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(5),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(color: MaterialTheme.borderColor(widget.brightness)),
              ),
              child: reduce
                  ? Text(
                      'Escribiendo…',
                      style: TextStyle(
                        fontSize: 13,
                        color: MaterialTheme.textMuted(widget.brightness),
                      ),
                    )
                  : AnimatedBuilder(
                      animation: _c,
                      builder: (context, _) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(3, (i) => _dot(i)),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(int i) {
    // Onda: cada punto adelanta su fase; sube y baja la opacidad/escala.
    final phase = (_c.value + i * 0.18) % 1.0;
    final wave = (0.5 - (phase - 0.5).abs()) * 2; // 0→1→0
    final v = 0.35 + wave * 0.65;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: Transform.translate(
        offset: Offset(0, -wave * 2.5),
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: MaterialTheme.primaryColor.withValues(alpha: v),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar del bot
// ─────────────────────────────────────────────────────────────────────────────
class _BotAvatar extends StatelessWidget {
  const _BotAvatar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    // Ulises — la mascota del asistente. El PNG tiene las esquinas BLANCAS
    // (opacas), así que lo recortamos a círculo con ClipOval: sobre el header
    // naranja ya no aparece el recuadro blanco, y en las burbujas queda igual de
    // limpio. BoxFit.cover para que el badge llene el círculo sin bordes.
    return ClipOval(
      child: Image.asset(
        'assets/images/ulises_chatbot.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Renderizador de markdown liviano: **negrita** y viñetas (- / *), sin dependencias.
// ─────────────────────────────────────────────────────────────────────────────
class _MarkdownText extends StatelessWidget {
  const _MarkdownText(this.text, {required this.color});

  final String text;
  final Color color;

  static final RegExp _bold = RegExp(r'\*\*(.+?)\*\*');
  static final RegExp _bullet = RegExp(r'^([-*])\s+(.*)$');

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(fontSize: 14.5, height: 1.42, color: color);
    final lines = text.replaceAll('\r\n', '\n').split('\n');
    final children = <Widget>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].replaceAll('\t', '  ');
      final trimmed = line.trimLeft();

      if (trimmed.isEmpty) {
        if (children.isNotEmpty && i != lines.length - 1) {
          children.add(const SizedBox(height: 7));
        }
        continue;
      }

      final bulletMatch = _bullet.firstMatch(trimmed);
      if (bulletMatch != null) {
        final indent = (line.length - trimmed.length).clamp(0, 8).toDouble();
        children.add(Padding(
          padding: EdgeInsets.only(left: indent * 1.5, top: 2, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6.5, right: 8),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(child: Text.rich(_inline(bulletMatch.group(2)!), style: base)),
            ],
          ),
        ));
      } else {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Text.rich(_inline(trimmed), style: base),
        ));
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  InlineSpan _inline(String source) {
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in _bold.allMatches(source)) {
      if (m.start > last) spans.add(TextSpan(text: source.substring(last, m.start)));
      spans.add(TextSpan(
        text: m.group(1),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ));
      last = m.end;
    }
    if (last < source.length) spans.add(TextSpan(text: source.substring(last)));
    return TextSpan(children: spans);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Estados vacíos
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.brightness});
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _FloatingBot(),
            const SizedBox(height: 18),
            Text(
              '¡Hola! Soy ULimaBot',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: MaterialTheme.textPrimary(brightness),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pregúntame por tu horario, evaluaciones,\nmalla o alertas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: MaterialTheme.textMuted(brightness),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyConversations extends StatelessWidget {
  const _EmptyConversations({required this.brightness, required this.onCreate});
  final Brightness brightness;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _FloatingBot(),
            const SizedBox(height: 18),
            Text(
              'Aún no tienes conversaciones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: MaterialTheme.textPrimary(brightness),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea una nueva para empezar a chatear con ULimaBot.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: MaterialTheme.textMuted(brightness)),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onCreate,
              style: FilledButton.styleFrom(
                backgroundColor: MaterialTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
              ),
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Nueva conversación'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Avatar del bot con un flote suave (delight en estados vacíos). Reduce-motion aware.
class _FloatingBot extends StatefulWidget {
  const _FloatingBot();

  @override
  State<_FloatingBot> createState() => _FloatingBotState();
}

class _FloatingBotState extends State<_FloatingBot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const avatar = _BotAvatar(size: 60);
    if (MediaQuery.of(context).disableAnimations) return avatar;
    return AnimatedBuilder(
      animation: CurvedAnimation(parent: _c, curve: Curves.easeInOut),
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_c.value);
        return Transform.translate(offset: Offset(0, -6 * t), child: child);
      },
      child: avatar,
    );
  }
}
