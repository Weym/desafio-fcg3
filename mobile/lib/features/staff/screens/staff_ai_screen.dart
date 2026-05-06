import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar_actions.dart';
import '../../../shared/widgets/app_skeleton_list.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/responsive_container.dart';
import '../../client/models/chat_session_model.dart';
import '../../client/models/chat_message_model.dart';
import '../providers/staff_chat_provider.dart';

class StaffAiScreen extends ConsumerStatefulWidget {
  const StaffAiScreen({super.key});

  @override
  ConsumerState<StaffAiScreen> createState() => _StaffAiScreenState();
}

class _StaffAiScreenState extends ConsumerState<StaffAiScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  String? _selectedSessionId;

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
    final isDesktop = AppBreakpoints.isDesktop(MediaQuery.sizeOf(context).width);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights IA'),
        actions: const [AppBarActions()],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sessões'),
            Tab(text: 'Estatísticas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SessionsTab(
            isDesktop: isDesktop,
            selectedSessionId: _selectedSessionId,
            onSessionSelected: (id) {
              setState(() => _selectedSessionId = id);
            },
          ),
          const _StatisticsTab(),
        ],
      ),
    );
  }
}

class _SessionsTab extends ConsumerWidget {
  final bool isDesktop;
  final String? selectedSessionId;
  final ValueChanged<String> onSessionSelected;

  const _SessionsTab({
    required this.isDesktop,
    required this.selectedSessionId,
    required this.onSessionSelected,
  });

  Future<void> _onRefresh(WidgetRef ref) async {
    ref.invalidate(staffChatSessionsProvider);
    await ref.read(staffChatSessionsProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(staffChatSessionsProvider);

    return sessionsAsync.when(
      loading: () => const ResponsiveContainer(
        padding: EdgeInsets.all(16),
        child: AppSkeletonList(itemCount: 5, itemHeight: 72),
      ),
      error: (error, stack) => ResponsiveContainer(
        padding: const EdgeInsets.all(16),
        child: AppErrorState(
          onRetry: () => ref.invalidate(staffChatSessionsProvider),
        ),
      ),
      data: (sessions) {
        if (sessions.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => _onRefresh(ref),
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
                      width: (MediaQuery.sizeOf(context).width * 0.35).clamp(0, 400).toDouble(),
                      child: RefreshIndicator(
                        onRefresh: () => _onRefresh(ref),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: sorted.length,
                          itemBuilder: (context, index) {
                            final session = sorted[index];
                            return _SessionCard(
                              session: session,
                              selected: session.id == selectedSessionId,
                              onTap: () => onSessionSelected(session.id),
                            );
                          },
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 1, thickness: 1),
                    Expanded(
                      child: selectedSessionId != null
                          ? _ChatDetailPanel(sessionId: selectedSessionId!)
                          : Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.psychology_outlined, size: 64, color: Theme.of(context).colorScheme.outlineVariant),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Selecione uma sessão',
                                    style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                onRefresh: () => _onRefresh(ref),
                child: ResponsiveContainer(
                  padding: const EdgeInsets.all(16),
                  child: ListView.builder(
                    itemCount: sorted.length,
                    itemBuilder: (context, index) {
                      final session = sorted[index];
                      return _SessionCard(
                        session: session,
                        selected: false,
                        onTap: () => context.push('/staff/ai/${session.id}'),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Detail panel for desktop master-detail layout (staff AI sessions).
class _ChatDetailPanel extends ConsumerStatefulWidget {
  final String sessionId;

  const _ChatDetailPanel({required this.sessionId});

  @override
  ConsumerState<_ChatDetailPanel> createState() => _ChatDetailPanelState();
}

class _ChatDetailPanelState extends ConsumerState<_ChatDetailPanel>
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
    final messagesAsync = ref.watch(staffChatMessagesProvider(sessionId));

    return messagesAsync.when(
      loading: () => const AppSkeletonList(itemCount: 5, itemHeight: 56),
      error: (error, stack) => AppErrorState(
        onRetry: () => ref.invalidate(staffChatMessagesProvider(sessionId)),
      ),
      data: (messages) {
        if (messages.isEmpty) {
          return const AppEmptyState(
            icon: Icons.chat_bubble_outline,
            message: 'Nenhuma mensagem nesta sessao',
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

class _ActionsPanel extends ConsumerWidget {
  final String sessionId;

  const _ActionsPanel({required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionsAsync = ref.watch(staffActionLogsProvider(sessionId));

    return actionsAsync.when(
      loading: () => const AppSkeletonList(itemCount: 3, itemHeight: 56),
      error: (error, stack) => AppErrorState(
        onRetry: () => ref.invalidate(staffActionLogsProvider(sessionId)),
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
                color: log.isError ? Theme.of(context).colorScheme.error : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF81C784) : const Color(0xFF4CAF50)),
              ),
              title: Text(log.toolName),
              subtitle: Text('${log.status} \u2022 ${log.latencyMs ?? "?"}ms'),
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

class _SessionCard extends StatelessWidget {
  final ChatSessionModel session;
  final VoidCallback onTap;
  final bool selected;

  const _SessionCard({
    required this.session,
    required this.onTap,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isActive = session.isActive;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.whatsappPhone ??
                      'Sessão #${session.id.substring(0, 8)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(session.startedAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? (isDark ? const Color(0xFF4CAF50).withValues(alpha: 0.15) : const Color(0xFF4CAF50).withValues(alpha: 0.1))
                  : colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              border: Border.all(
                color: isActive
                    ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
                    : colors.outlineVariant,
              ),
            ),
            child: Text(
              isActive ? 'Ativa' : 'Encerrada',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isActive
                    ? (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32))
                    : colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }
}

class _StatisticsTab extends ConsumerWidget {
  const _StatisticsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(staffChatStatisticsProvider);

    return statsAsync.when(
      loading: () => const ResponsiveContainer(
        padding: EdgeInsets.all(16),
        child: AppSkeletonList(itemCount: 3, itemHeight: 80),
      ),
      error: (error, stack) => ResponsiveContainer(
        padding: const EdgeInsets.all(16),
        child: AppErrorState(
          onRetry: () => ref.invalidate(staffChatStatisticsProvider),
        ),
      ),
      data: (data) {
        final totalSessions = data['total_sessions'] ?? 0;
        final activeSessions = data['active_sessions'] ?? 0;
        final closedSessions = data['closed_sessions'] ?? 0;

        if (totalSessions == 0 && activeSessions == 0 && closedSessions == 0) {
          return const AppEmptyState(
            icon: Icons.insights_outlined,
            message: 'Dados insuficientes para estatisticas',
          );
        }

        return ResponsiveContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _StatCard(
                icon: Icons.forum_outlined,
                iconColor: Theme.of(context).colorScheme.primary,
                value: totalSessions.toString(),
                label: 'Total de Sessões',
              ),
              const SizedBox(height: 12),
              _StatCard(
                icon: Icons.chat,
                iconColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF81C784) : const Color(0xFF4CAF50),
                value: activeSessions.toString(),
                label: 'Sessões Ativas',
              ),
              const SizedBox(height: 12),
              _StatCard(
                icon: Icons.check_circle_outline,
                iconColor: Theme.of(context).colorScheme.outline,
                value: closedSessions.toString(),
                label: 'Sessões Encerradas',
              ),
              const SizedBox(height: 24),
              Text(
                'Estatisticas baseadas nas sessoes de chat registradas.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
