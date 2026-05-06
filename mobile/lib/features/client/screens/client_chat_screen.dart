import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_skeleton_list.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_state.dart';
import '../../../shared/widgets/glass_card.dart';
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
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
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
                        child: Column(
                          children: [
                            // Search bar
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: _SearchBar(),
                            ),
                            Expanded(
                              child: RefreshIndicator(
                                onRefresh: _onRefresh,
                                child: ListView.separated(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                  ),
                                  itemCount: sorted.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: AppSpacing.sm),
                                  itemBuilder: (context, index) {
                                    final session = sorted[index];
                                    return _SessionCard(
                                      session: session,
                                      selected:
                                          session.id == _selectedSessionId,
                                      onTap: () {
                                        setState(() =>
                                            _selectedSessionId = session.id);
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const VerticalDivider(width: 1, thickness: 1),
                      Expanded(
                        child: _selectedSessionId != null
                            ? _DetailPanel(sessionId: _selectedSessionId!)
                            : Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.chat_outlined,
                                        size: 64, color: colors.outlineVariant),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Selecione uma conversa',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: colors.onSurfaceVariant,
                                      ),
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

          // Phone/Tablet: single-column
          return Column(
            children: [
              if (sessionsAsync.isRefreshing) const LinearProgressIndicator(),
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: AppSpacing.sm,
                ),
                child: _SearchBar(),
              ),
              // Section header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'CONVERSAS RECENTES',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ResponsiveContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ListView.separated(
                      itemCount: sorted.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final session = sorted[index];
                        return _SessionCard(
                          session: session,
                          selected: false,
                          onTap: () =>
                              context.go('/client/chat/${session.id}'),
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

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return TextField(
      decoration: InputDecoration(
        hintText: 'Buscar conversas...',
        prefixIcon: Icon(Icons.search, color: colors.outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          borderSide: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          borderSide: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.3)),
        ),
        filled: true,
        fillColor: colors.surfaceContainer.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

/// Detail panel for desktop master-detail layout.
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
              Tab(text: 'Ações'),
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
    final colors = Theme.of(context).colorScheme;

    return actionsAsync.when(
      loading: () => const AppSkeletonList(itemCount: 3, itemHeight: 56),
      error: (error, stack) => AppErrorState(
        onRetry: () => ref.invalidate(actionLogsProvider(sessionId)),
      ),
      data: (logs) {
        if (logs.isEmpty) {
          return const AppEmptyState(
            icon: Icons.history_outlined,
            message: 'Nenhuma ação registrada',
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
                color: log.isError ? colors.error : const Color(0xFF4CAF50),
              ),
              title: Text(log.toolName),
              subtitle: Text(log.status),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    'Latência: ${log.latencyMs ?? "?"}ms',
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
    final colors = Theme.of(context).colorScheme;
    final isUser = message.isUser;
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: screenWidth * 0.75),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser
                  ? colors.primary
                  : colors.surfaceContainerHighest,
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
                  color: colors.primary.withValues(alpha: isUser ? 0.15 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: TextStyle(
                    color: isUser ? colors.onPrimary : colors.onSurface,
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
                          ? colors.onPrimary.withValues(alpha: 0.6)
                          : colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(message.createdAt),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isUser
                            ? colors.onPrimary.withValues(alpha: 0.6)
                            : colors.onSurfaceVariant,
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
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isActive = session.isActive;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: BorderRadius.circular(
        selected ? AppSpacing.radiusXl : AppSpacing.radiusLg,
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isActive
                  ? colors.primaryContainer
                  : colors.secondaryContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Icon(
              isActive ? Icons.smart_toy : Icons.chat,
              size: 26,
              color: isActive
                  ? colors.onPrimaryContainer
                  : colors.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Sessão ${_formatDate(session.startedAt)}',
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colors.onSurface,
                                ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _formatDate(session.startedAt),
                      style: TextStyle(
                        fontSize: 10,
                        color: colors.outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (session.messageCount != null)
                  Text(
                    '${session.messageCount} mensagens',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 6),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? colors.primary.withValues(alpha: 0.1)
                        : colors.surfaceContainerHigh.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    border: Border.all(
                      color: isActive
                          ? colors.primary.withValues(alpha: 0.2)
                          : colors.outlineVariant,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isActive)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.primary,
                          ),
                        ),
                      Text(
                        isActive ? 'Ativa' : 'Encerrada',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isActive
                              ? colors.primary
                              : colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
