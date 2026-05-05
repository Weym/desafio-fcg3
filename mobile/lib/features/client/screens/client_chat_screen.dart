import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../shared/widgets/app_skeleton_list.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_state.dart';
import '../../../shared/widgets/responsive_container.dart';
import '../models/chat_session_model.dart';
import '../models/chat_message_model.dart';
import '../providers/chat_provider.dart';

class ClientChatScreen extends ConsumerStatefulWidget {
  const ClientChatScreen({super.key});

  @override
  ConsumerState<ClientChatScreen> createState() => _ClientChatScreenState();
}

class _ClientChatScreenState extends ConsumerState<ClientChatScreen> {
  String? _selectedSessionId;

  Future<void> _onRefresh() async {
    ref.invalidate(chatSessionsProvider);
    await ref.read(chatSessionsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(chatSessionsProvider);
    final isDesktop = AppBreakpoints.isDesktop(MediaQuery.sizeOf(context).width);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
      ),
      body: sessionsAsync.when(
        loading: () => const ResponsiveContainer(
          padding: EdgeInsets.all(16),
          child: AppSkeletonList(itemCount: 5, itemHeight: 72),
        ),
        error: (error, stack) => ResponsiveContainer(
          padding: const EdgeInsets.all(16),
          child: AppErrorState(
            onRetry: () => ref.invalidate(chatSessionsProvider),
          ),
        ),
        data: (sessions) {
          if (sessions.isEmpty) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView(
                children: const [
                  SizedBox(height: 120),
                  AppEmptyState(
                    icon: Icons.chat_bubble_outline,
                    message: 'Nenhuma conversa encontrada',
                  ),
                ],
              ),
            );
          }

          final sorted = List<ChatSessionModel>.from(sessions)
            ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

          if (isDesktop) {
            return Column(
              children: [
                if (sessionsAsync.isRefreshing)
                  const LinearProgressIndicator(),
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width * 0.35,
                        child: RefreshIndicator(
                          onRefresh: _onRefresh,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: sorted.length,
                            itemBuilder: (context, index) {
                              final session = sorted[index];
                              return _SessionCard(
                                session: session,
                                selected: session.id == _selectedSessionId,
                                onTap: () {
                                  setState(() => _selectedSessionId = session.id);
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      const VerticalDivider(width: 1, thickness: 1),
                      Expanded(
                        child: _selectedSessionId != null
                            ? _DetailPanel(sessionId: _selectedSessionId!)
                            : const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.chat_outlined, size: 64, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text(
                                      'Selecione uma conversa',
                                      style: TextStyle(fontSize: 16, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          // Phone/Tablet: existing single-column with GoRouter navigation
          return Column(
            children: [
              if (sessionsAsync.isRefreshing)
                const LinearProgressIndicator(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ResponsiveContainer(
                    padding: const EdgeInsets.all(8),
                    child: ListView.builder(
                      itemCount: sorted.length,
                      itemBuilder: (context, index) {
                        final session = sorted[index];
                        return _SessionCard(
                          session: session,
                          selected: false,
                          onTap: () => context.go('/client/chat/${session.id}'),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Detail panel for desktop master-detail layout.
/// Shows messages and actions tabs inline.
class _DetailPanel extends ConsumerStatefulWidget {
  final String sessionId;

  const _DetailPanel({required this.sessionId});

  @override
  ConsumerState<_DetailPanel> createState() => _DetailPanelState();
}

class _DetailPanelState extends ConsumerState<_DetailPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Mensagens'),
              Tab(text: 'Acoes'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _MessagesPanel(sessionId: widget.sessionId),
              _ActionsPanel(sessionId: widget.sessionId),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessagesPanel extends ConsumerWidget {
  final String sessionId;

  const _MessagesPanel({required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(chatMessagesProvider(sessionId));

    return messagesAsync.when(
      loading: () => const AppSkeletonList(itemCount: 5, itemHeight: 56),
      error: (error, stack) => AppErrorState(
        onRetry: () => ref.invalidate(chatMessagesProvider(sessionId)),
      ),
      data: (messages) {
        if (messages.isEmpty) {
          return const AppEmptyState(
            icon: Icons.chat_bubble_outline,
            message: 'Nenhuma mensagem',
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

class _ActionsPanel extends ConsumerWidget {
  final String sessionId;

  const _ActionsPanel({required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionsAsync = ref.watch(actionLogsProvider(sessionId));

    return actionsAsync.when(
      loading: () => const AppSkeletonList(itemCount: 3, itemHeight: 56),
      error: (error, stack) => AppErrorState(
        onRetry: () => ref.invalidate(actionLogsProvider(sessionId)),
      ),
      data: (logs) {
        if (logs.isEmpty) {
          return const AppEmptyState(
            icon: Icons.history_outlined,
            message: 'Nenhuma acao registrada',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            return ExpansionTile(
              leading: Icon(
                log.isError ? Icons.error_outline : Icons.check_circle_outline,
                color: log.isError ? Colors.red : Colors.green,
              ),
              title: Text(log.toolName),
              subtitle: Text(log.status),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    'Latencia: ${log.latencyMs ?? "?"}ms',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            );
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
          constraints: BoxConstraints(maxWidth: screenWidth * 0.5),
          child: Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isUser
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft:
                        isUser ? const Radius.circular(12) : Radius.zero,
                    bottomRight:
                        isUser ? Radius.zero : const Radius.circular(12),
                  ),
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

class _SessionCard extends StatelessWidget {
  final ChatSessionModel session;
  final VoidCallback onTap;
  final bool selected;

  const _SessionCard({
    required this.session,
    required this.onTap,
    required this.selected,
  });

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = session.isActive;

    return Card(
      elevation: selected ? 3 : 1,
      color: selected
          ? theme.colorScheme.primaryContainer
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: isActive
                    ? theme.colorScheme.primary.withValues(alpha: 0.12)
                    : Colors.grey.withValues(alpha: 0.12),
                child: Icon(
                  Icons.chat,
                  color: isActive ? theme.colorScheme.primary : Colors.grey,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(session.startedAt),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          isActive ? 'Ativa' : 'Encerrada',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isActive
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (session.messageCount != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${session.messageCount} msgs',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
