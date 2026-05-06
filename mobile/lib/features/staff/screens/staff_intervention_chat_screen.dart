import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../client/models/chat_message_model.dart';
import '../providers/staff_intervention_provider.dart';

class StaffInterventionChatScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const StaffInterventionChatScreen({super.key, required this.sessionId});

  @override
  ConsumerState<StaffInterventionChatScreen> createState() =>
      _StaffInterventionChatScreenState();
}

class _StaffInterventionChatScreenState
    extends ConsumerState<StaffInterventionChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _pollTimer;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Poll for new messages every 5 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        ref.invalidate(interventionMessagesProvider(widget.sessionId));
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      final service = ref.read(staffInterventionServiceProvider);
      await service.replyToSession(widget.sessionId, content);
      ref.invalidate(interventionMessagesProvider(widget.sessionId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _handleResolve() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolver conversa'),
        content: const Text(
          'Tem certeza que deseja marcar esta conversa como resolvida? '
          'O aluno será devolvido ao atendimento automático.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Resolver'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final service = ref.read(staffInterventionServiceProvider);
      await service.resolveSession(widget.sessionId);
      ref.invalidate(interventionSessionsProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao resolver: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync =
        ref.watch(interventionMessagesProvider(widget.sessionId));
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Atendimento'),
        actions: [
          TextButton.icon(
            onPressed: _handleResolve,
            icon: Icon(Icons.check_circle, color: colors.primary),
            label: Text(
              'Resolver',
              style: TextStyle(color: colors.primary),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: messagesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48),
                      const SizedBox(height: 16),
                      const Text('Erro ao carregar mensagens'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(
                            interventionMessagesProvider(widget.sessionId)),
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 64, color: colors.onSurfaceVariant),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhuma mensagem nesta conversa',
                            style:
                                TextStyle(fontSize: 16, color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    );
                  }

                  final sorted = List<ChatMessageModel>.from(messages)
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                    itemCount: sorted.length,
                    itemBuilder: (context, index) {
                      return _InterventionMessageBubble(
                          message: sorted[index]);
                    },
                  );
                },
              ),
            ),

            // Input area
            _MessageInputBar(
              controller: _messageController,
              isSending: _isSending,
              onSend: _handleSend,
            ),
          ],
        ),
      ),
    );
  }
}

/// Message bubble for intervention chat.
/// User messages (student) on LEFT, assistant/human on RIGHT.
class _InterventionMessageBubble extends StatelessWidget {
  final ChatMessageModel message;

  const _InterventionMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isUser = message.isUser;
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: (screenWidth * 0.75).clamp(0, 500).toDouble()),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser
                  ? colors.surfaceContainerHighest
                  : colors.primary,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AppSpacing.radiusXl),
                topRight: const Radius.circular(AppSpacing.radiusXl),
                bottomLeft: isUser
                    ? Radius.zero
                    : const Radius.circular(AppSpacing.radiusXl),
                bottomRight: isUser
                    ? const Radius.circular(AppSpacing.radiusXl)
                    : Radius.zero,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      colors.primary.withValues(alpha: isUser ? 0.05 : 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                // Role label
                Text(
                  isUser ? 'Aluno' : (message.role == 'assistant' ? 'IA' : 'Staff'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isUser
                        ? colors.onSurfaceVariant
                        : colors.onPrimary.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message.content,
                  style: TextStyle(
                    color: isUser ? colors.onSurface : colors.onPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 10,
                      color: isUser
                          ? colors.onSurfaceVariant
                          : colors.onPrimary.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(message.createdAt),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isUser
                            ? colors.onSurfaceVariant
                            : colors.onPrimary.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

/// Glass-style message input bar fixed at the bottom.
class _MessageInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _MessageInputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? colors.surfaceContainerLowest.withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Digite sua resposta...',
                hintStyle: TextStyle(color: colors.onSurfaceVariant),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                  borderSide: BorderSide(
                    color: colors.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                  borderSide: BorderSide(
                    color: colors.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusFull),
                  borderSide: BorderSide(color: colors.primary),
                ),
                filled: true,
                fillColor: colors.surfaceContainer.withValues(alpha: 0.5),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 4,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton.filled(
            onPressed: isSending ? null : onSend,
            icon: isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              disabledBackgroundColor:
                  colors.primary.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
