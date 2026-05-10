import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_animations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/animated_entrance.dart';
import '../../../shared/widgets/app_bar_actions.dart';
import '../../../shared/widgets/app_skeleton_list.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_error_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/responsive_container.dart';
import '../models/intervention_session_model.dart';
import '../providers/staff_intervention_provider.dart';

class StaffInterventionScreen extends ConsumerStatefulWidget {
  const StaffInterventionScreen({super.key});

  @override
  ConsumerState<StaffInterventionScreen> createState() =>
      _StaffInterventionScreenState();
}

class _StaffInterventionScreenState
    extends ConsumerState<StaffInterventionScreen>
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

  Future<void> _onRefresh() async {
    ref.invalidate(interventionSessionsProvider);
    await ref.read(interventionSessionsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Intervenção'),
        actions: const [AppBarActions()],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pendentes'),
            Tab(text: 'Em atendimento'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _InterventionList(
            filter: (s) => s.isPending,
            emptyMessage: 'Nenhuma conversa pendente',
            emptyIcon: Icons.check_circle_outline,
            onRefresh: _onRefresh,
          ),
          _InterventionList(
            filter: (s) => s.isActive,
            emptyMessage: 'Nenhuma conversa em atendimento',
            emptyIcon: Icons.support_agent,
            onRefresh: _onRefresh,
          ),
        ],
      ),
    );
  }
}

class _InterventionList extends ConsumerWidget {
  final bool Function(InterventionSessionModel) filter;
  final String emptyMessage;
  final IconData emptyIcon;
  final Future<void> Function() onRefresh;

  const _InterventionList({
    required this.filter,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(interventionSessionsProvider);

    return sessionsAsync.when(
      loading: () => const ResponsiveContainer(
        padding: EdgeInsets.all(16),
        child: AppSkeletonList(itemCount: 4, itemHeight: 140),
      ),
      error: (error, stack) => ResponsiveContainer(
        padding: const EdgeInsets.all(16),
        child: AppErrorState(
          onRetry: () => ref.invalidate(interventionSessionsProvider),
        ),
      ),
      data: (sessions) {
        final filtered = sessions.where(filter).toList()
          ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

        if (filtered.isEmpty) {
          return RefreshIndicator(
            onRefresh: onRefresh,
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

        return Column(
          children: [
            if (sessionsAsync.isRefreshing) const LinearProgressIndicator(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: onRefresh,
                child: ResponsiveContainer(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final session = filtered[index];
                      return AnimatedEntrance(
                        delay: AppAnimations.getEntranceDelay(index),
                        child: _InterventionCard(session: session),
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

class _InterventionCard extends ConsumerWidget {
  final InterventionSessionModel session;

  const _InterventionCard({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return GlassCard(
      onTap: session.isActive
          ? () => context.push('/staff/intervention/${session.id}')
          : null,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar + name + status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar circle with initial
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Center(
                  child: Text(
                    session.displayName[0].toUpperCase(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                    if (session.displayIdentifier.isNotEmpty)
                      Text(
                        session.displayIdentifier,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              _StatusBadge(session: session),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Escalation reason card (error/alert style)
          if (session.escalationReason != null &&
              session.escalationReason!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm + 4),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: colors.error.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MOTIVO DO ALERTA',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.error,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session.escalationReason!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: AppSpacing.md),

          // Time info
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 12,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                _relativeTime(session.startedAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),

          // "Assumir Conversa" button for pending sessions
          if (session.isPending) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _handleAssign(context, ref),
                icon: const Icon(Icons.support_agent, size: 18),
                label: const Text('Assumir Conversa'),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.sm + 4),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleAssign(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(staffInterventionServiceProvider);
      await service.assignSession(session.id);
      ref.invalidate(interventionSessionsProvider);
      if (context.mounted) {
        context.push('/staff/intervention/${session.id}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao assumir conversa: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
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

class _StatusBadge extends StatelessWidget {
  final InterventionSessionModel session;

  const _StatusBadge({required this.session});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isPending = session.isPending;

    final bgColor = isPending
        ? const Color(0xFFFFF8E1) // amber-100 equivalent
        : colors.primary.withValues(alpha: 0.1);
    final textColor = isPending
        ? const Color(0xFFF57F17) // amber-700 equivalent
        : colors.primary;
    final label = isPending ? 'PENDENTE' : 'EM ATENDIMENTO';

    // Adapt for dark mode
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBg = isDark
        ? (isPending
            ? const Color(0xFFF57F17).withValues(alpha: 0.15)
            : colors.primary.withValues(alpha: 0.15))
        : bgColor;
    final effectiveText = isDark
        ? (isPending ? const Color(0xFFFFD54F) : colors.primary)
        : textColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: effectiveText,
        ),
      ),
    );
  }
}
