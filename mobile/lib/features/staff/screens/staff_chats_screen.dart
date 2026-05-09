import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar_actions.dart';
import '../../../shared/widgets/app_skeleton_list.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/responsive_container.dart';
import '../../../shared/widgets/staff_search_bar.dart';
import '../../client/models/chat_session_model.dart';
import '../models/intervention_session_model.dart';
import '../providers/staff_chat_provider.dart';
import '../providers/staff_intervention_provider.dart';

/// Unified Chats screen with 4 sub-tabs:
/// Todos, Pendentes, Em atendimento, Concluídos
class StaffChatsScreen extends ConsumerStatefulWidget {
  const StaffChatsScreen({super.key});

  @override
  ConsumerState<StaffChatsScreen> createState() => _StaffChatsScreenState();
}

class _StaffChatsScreenState extends ConsumerState<StaffChatsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Check for query param filter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final goRouterState = GoRouterState.of(context);
      final filter = goRouterState.uri.queryParameters['filter'];
      if (filter == 'hoje') {
        // Stay on "Todos" tab (index 0) — filtering handled in list
        _tabController.animateTo(0);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(staffChatsSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: const [AppBarActions()],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Todos'),
            Tab(text: 'Pendentes'),
            Tab(text: 'Em atendimento'),
            Tab(text: 'Concluídos'),
          ],
        ),
      ),
      body: Column(
        children: [
          StaffSearchBar(
            hintText: 'Buscar por nome, RA ou telefone...',
            onChanged: (q) =>
                ref.read(staffChatsSearchProvider.notifier).setQuery(q),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _AllSessionsTab(searchQuery: searchQuery),
                _FilteredInterventionTab(
                  filter: (s) => s.isPending,
                  emptyMessage: 'Nenhuma conversa pendente',
                  emptyIcon: Icons.check_circle_outline,
                  searchQuery: searchQuery,
                ),
                _FilteredInterventionTab(
                  filter: (s) => s.isActive,
                  emptyMessage: 'Nenhuma conversa em atendimento',
                  emptyIcon: Icons.support_agent,
                  searchQuery: searchQuery,
                ),
                _FilteredInterventionTab(
                  filter: (s) =>
                      s.status == 'closed' ||
                      s.status == 'resolved',
                  emptyMessage: 'Nenhuma conversa concluída',
                  emptyIcon: Icons.done_all,
                  searchQuery: searchQuery,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Todos" tab: merges chat sessions + intervention sessions
class _AllSessionsTab extends ConsumerWidget {
  final String searchQuery;

  const _AllSessionsTab({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatSessionsAsync = ref.watch(staffChatSessionsProvider);
    final interventionAsync = ref.watch(interventionSessionsProvider);

    // Check for ?filter=hoje
    final goRouterState = GoRouterState.of(context);
    final filterHoje =
        goRouterState.uri.queryParameters['filter'] == 'hoje';

    return chatSessionsAsync.when(
      loading: () => const ResponsiveContainer(
        padding: EdgeInsets.all(16),
        child: AppSkeletonList(itemCount: 5, itemHeight: 80),
      ),
      error: (error, stack) => ResponsiveContainer(
        padding: const EdgeInsets.all(16),
        child: AppErrorState(
          onRetry: () {
            ref.invalidate(staffChatSessionsProvider);
            ref.invalidate(interventionSessionsProvider);
          },
        ),
      ),
      data: (chatSessions) {
        final interventionSessions = interventionAsync.valueOrNull ?? [];

        // Build unified list items
        final List<_UnifiedChatItem> items = [];

        // Add chat sessions
        for (final session in chatSessions) {
          items.add(_UnifiedChatItem(
            id: session.id,
            displayName:
                session.name ?? session.whatsappPhone ?? 'Sessão #${session.id.substring(0, 8)}',
            phone: session.whatsappPhone,
            date: session.startedAt,
            status: session.status,
            isIntervention: false,
          ));
        }

        // Add intervention sessions (avoid duplicates by ID)
        final chatIds = chatSessions.map((s) => s.id).toSet();
        for (final session in interventionSessions) {
          if (!chatIds.contains(session.id)) {
            items.add(_UnifiedChatItem(
              id: session.id,
              displayName: session.displayName,
              phone: session.whatsappPhone,
              date: session.startedAt,
              status: session.status,
              isIntervention: true,
            ));
          }
        }

        // Apply today filter
        var filtered = items;
        if (filterHoje) {
          final now = DateTime.now();
          filtered = items
              .where((i) =>
                  i.date.year == now.year &&
                  i.date.month == now.month &&
                  i.date.day == now.day)
              .toList();
        }

        // Apply search filter
        if (searchQuery.isNotEmpty) {
          final q = searchQuery.toLowerCase();
          filtered = filtered.where((i) {
            return i.displayName.toLowerCase().contains(q) ||
                (i.phone?.toLowerCase().contains(q) ?? false);
          }).toList();
        }

        // Sort by date descending
        filtered.sort((a, b) => b.date.compareTo(a.date));

        if (filtered.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(staffChatSessionsProvider);
              ref.invalidate(interventionSessionsProvider);
              await ref.read(staffChatSessionsProvider.future);
            },
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

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(staffChatSessionsProvider);
            ref.invalidate(interventionSessionsProvider);
            await ref.read(staffChatSessionsProvider.future);
          },
          child: ResponsiveContainer(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final item = filtered[index];
                return _ChatSessionCard(item: item);
              },
            ),
          ),
        );
      },
    );
  }
}

/// Intervention-only filtered tab (Pendentes, Em atendimento, Concluídos)
class _FilteredInterventionTab extends ConsumerWidget {
  final bool Function(InterventionSessionModel) filter;
  final String emptyMessage;
  final IconData emptyIcon;
  final String searchQuery;

  const _FilteredInterventionTab({
    required this.filter,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(interventionSessionsProvider);

    return sessionsAsync.when(
      loading: () => const ResponsiveContainer(
        padding: EdgeInsets.all(16),
        child: AppSkeletonList(itemCount: 4, itemHeight: 80),
      ),
      error: (error, stack) => ResponsiveContainer(
        padding: const EdgeInsets.all(16),
        child: AppErrorState(
          onRetry: () => ref.invalidate(interventionSessionsProvider),
        ),
      ),
      data: (sessions) {
        var filtered = sessions.where(filter).toList();

        // Apply search filter
        if (searchQuery.isNotEmpty) {
          final q = searchQuery.toLowerCase();
          filtered = filtered.where((s) {
            return s.displayName.toLowerCase().contains(q) ||
                s.displayIdentifier.toLowerCase().contains(q) ||
                (s.whatsappPhone?.toLowerCase().contains(q) ?? false);
          }).toList();
        }

        // Sort by date descending
        filtered.sort((a, b) => b.startedAt.compareTo(a.startedAt));

        if (filtered.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(interventionSessionsProvider);
              await ref.read(interventionSessionsProvider.future);
            },
            child: ListView(
              children: [
                const SizedBox(height: 120),
                AppEmptyState(
                  icon: emptyIcon,
                  message: emptyMessage,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(interventionSessionsProvider);
            await ref.read(interventionSessionsProvider.future);
          },
          child: ResponsiveContainer(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final session = filtered[index];
                return _ChatSessionCard(
                  item: _UnifiedChatItem(
                    id: session.id,
                    displayName: session.displayName,
                    phone: session.whatsappPhone,
                    date: session.startedAt,
                    status: session.status,
                    isIntervention: true,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// Unified chat item model (merges chat + intervention for display)
class _UnifiedChatItem {
  final String id;
  final String displayName;
  final String? phone;
  final DateTime date;
  final String status;
  final bool isIntervention;

  const _UnifiedChatItem({
    required this.id,
    required this.displayName,
    this.phone,
    required this.date,
    required this.status,
    required this.isIntervention,
  });
}

/// Card for each chat session (per D-22 design)
class _ChatSessionCard extends StatelessWidget {
  final _UnifiedChatItem item;

  const _ChatSessionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return GlassCard(
      onTap: () {
        if (item.isIntervention) {
          context.push('/staff/intervention/${item.id}');
        } else {
          context.push('/staff/chats/${item.id}');
        }
      },
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // CircleAvatar with initial
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Center(
              child: Text(
                item.displayName.isNotEmpty
                    ? item.displayName[0].toUpperCase()
                    : '?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Name + phone
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                if (item.phone != null && item.phone!.isNotEmpty)
                  Text(
                    _formatPhone(item.phone!),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          // Status badge + time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusBadge(status: item.status),
              const SizedBox(height: 4),
              Text(
                _relativeTime(item.date),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Format phone as (XX) XXXXX-XXXX
  String _formatPhone(String phone) {
    // Remove non-digit characters
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length == 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    }
    if (digits.length == 13 && digits.startsWith('55')) {
      // Brazilian country code
      return '(${digits.substring(2, 4)}) ${digits.substring(4, 9)}-${digits.substring(9)}';
    }
    // Fallback: return as-is
    return phone;
  }

  String _relativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m atrás';
    if (diff.inHours < 24) return '${diff.inHours}h atrás';
    if (diff.inDays < 7) return '${diff.inDays}d atrás';
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}';
  }
}

/// Status badge widget
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String label;
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'human_needed':
        label = 'PENDENTE';
        bgColor = isDark
            ? const Color(0xFFF57F17).withValues(alpha: 0.15)
            : const Color(0xFFFFF8E1);
        textColor = isDark ? const Color(0xFFFFD54F) : const Color(0xFFF57F17);
        break;
      case 'human_active':
        label = 'EM ATENDIMENTO';
        bgColor = isDark
            ? colors.primary.withValues(alpha: 0.15)
            : colors.primary.withValues(alpha: 0.1);
        textColor = colors.primary;
        break;
      case 'resolved':
      case 'closed':
        label = 'CONCLUÍDO';
        bgColor = isDark
            ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
            : const Color(0xFF4CAF50).withValues(alpha: 0.1);
        textColor =
            isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
        break;
      case 'active':
        label = 'ATIVA';
        bgColor = isDark
            ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
            : const Color(0xFF4CAF50).withValues(alpha: 0.1);
        textColor =
            isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
        break;
      default:
        label = status.toUpperCase();
        bgColor = colors.surfaceContainerHigh;
        textColor = colors.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
