import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/chat_message_model.dart';
import '../models/action_log_model.dart';
import '../providers/chat_provider.dart';

class ClientChatDetailScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const ClientChatDetailScreen({super.key, required this.sessionId});

  @override
  ConsumerState<ClientChatDetailScreen> createState() =>
      _ClientChatDetailScreenState();
}

class _ClientChatDetailScreenState extends ConsumerState<ClientChatDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversa'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mensagens'),
            Tab(text: 'Acoes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MessagesTab(sessionId: widget.sessionId),
          _ActionsTab(sessionId: widget.sessionId),
        ],
      ),
    );
  }
}

class _MessagesTab extends ConsumerWidget {
  final String sessionId;

  const _MessagesTab({required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(chatMessagesProvider(sessionId));

    return messagesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text('Erro ao carregar mensagens: $error'),
          ],
        ),
      ),
      data: (messages) {
        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64,
                    color: Theme.of(context).colorScheme.outlineVariant),
                const SizedBox(height: 16),
                Text(
                  'Nenhuma mensagem',
                  style: TextStyle(fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            return _MessageBubble(message: messages[index]);
          },
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;

  const _MessageBubble({required this.message});

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: screenWidth * 0.75),
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(AppSpacing.radiusXl),
                    topRight: const Radius.circular(AppSpacing.radiusXl),
                    bottomLeft: isUser
                        ? const Radius.circular(AppSpacing.radiusXl)
                        : Radius.zero,
                    bottomRight: isUser
                        ? Radius.zero
                        : const Radius.circular(AppSpacing.radiusXl),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary
                          .withValues(alpha: isUser ? 0.15 : 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: isUser
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(message.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionsTab extends ConsumerWidget {
  final String sessionId;

  const _ActionsTab({required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionsAsync = ref.watch(actionLogsProvider(sessionId));

    return actionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text('Erro ao carregar acoes: $error'),
          ],
        ),
      ),
      data: (logs) {
        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history_outlined, size: 64,
                    color: Theme.of(context).colorScheme.outlineVariant),
                const SizedBox(height: 16),
                Text(
                  'Nenhuma ação registrada',
                  style: TextStyle(fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            return _ActionLogTile(log: log);
          },
        );
      },
    );
  }
}

class _ActionLogTile extends StatelessWidget {
  final ActionLogModel log;

  const _ActionLogTile({required this.log});

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }

  String _prettyJson(Map<String, dynamic> json) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(json);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ExpansionTile(
      leading: Icon(
        log.isError ? Icons.error_outline : Icons.check_circle_outline,
        color: log.isError ? theme.colorScheme.error : const Color(0xFF4CAF50),
      ),
      title: Text(log.toolName),
      subtitle: Text('${_formatDate(log.createdAt)} \u00b7 ${log.status}'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Input:',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _prettyJson(log.inputParams),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Output:',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  log.outputResult != null
                      ? _prettyJson(log.outputResult!)
                      : 'Sem resultado',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              if (log.latencyMs != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Latencia: ${log.latencyMs}ms',
                  style: theme.textTheme.bodySmall,
                ),
              ],
              if (log.retry) ...[
                const SizedBox(height: 8),
                Chip(
                  label: const Text('Retry'),
                  backgroundColor: Colors.orange.withValues(alpha: 0.2),
                  labelStyle: const TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
