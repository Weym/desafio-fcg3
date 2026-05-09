import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_skeleton_chat.dart';
import '../../../shared/widgets/app_skeleton_list.dart';
import '../../client/models/chat_message_model.dart';
import '../../client/models/action_log_model.dart';
import '../providers/staff_chat_provider.dart';

class StaffChatDetailScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const StaffChatDetailScreen({super.key, required this.sessionId});

  @override
  ConsumerState<StaffChatDetailScreen> createState() =>
      _StaffChatDetailScreenState();
}

class _StaffChatDetailScreenState extends ConsumerState<StaffChatDetailScreen>
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
          _StaffMessagesTab(sessionId: widget.sessionId),
          _StaffActionsTab(sessionId: widget.sessionId),
        ],
      ),
    );
  }
}

class _StaffMessagesTab extends ConsumerWidget {
  final String sessionId;

  const _StaffMessagesTab({required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(staffChatMessagesProvider(sessionId));

    return messagesAsync.when(
      loading: () => const AppSkeletonChat(),
      error: (error, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            const Text('Erro ao carregar mensagens'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () =>
                  ref.invalidate(staffChatMessagesProvider(sessionId)),
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
                Icon(Icons.chat_bubble_outline, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(height: 16),
                Text(
                  'Nenhuma mensagem nesta sessao',
                  style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          );
        }

        final sorted = List<ChatMessageModel>.from(messages)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          itemCount: sorted.length,
          itemBuilder: (context, index) {
            return _MessageBubble(message: sorted[index]);
          },
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;

  const _MessageBubble({required this.message});

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
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isUser
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  message.content,
                  style: theme.textTheme.bodyMedium,
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

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _StaffActionsTab extends ConsumerWidget {
  final String sessionId;

  const _StaffActionsTab({required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionsAsync = ref.watch(staffActionLogsProvider(sessionId));

    return actionsAsync.when(
      loading: () => const AppSkeletonList(itemCount: 3, itemHeight: 56),
      error: (error, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            const Text('Erro ao carregar acoes'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () =>
                  ref.invalidate(staffActionLogsProvider(sessionId)),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
      data: (logs) {
        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(height: 16),
                Text(
                  'Nenhuma acao registrada nesta sessao',
                  style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
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

  IconData _statusIcon() {
    if (log.isError) return Icons.error_outline;
    if (log.status == 'retry_success') return Icons.refresh;
    return Icons.check_circle_outline;
  }

  Color _statusColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (log.isError) return Theme.of(context).colorScheme.error;
    if (log.status == 'retry_success') return isDark ? Colors.amber.shade300 : Colors.amber;
    return isDark ? const Color(0xFF81C784) : const Color(0xFF4CAF50);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ExpansionTile(
      leading: Icon(_statusIcon(), color: _statusColor(context)),
      title: Text(log.toolName),
      subtitle: Text('${_formatTime(log.createdAt)} \u2022 ${log.latencyMs ?? '?'}ms'),
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
                  jsonEncode(log.inputParams),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              if (log.outputResult != null) ...[
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
                    jsonEncode(log.outputResult!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
              if (log.reasoning != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Reasoning:',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  log.reasoning!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
