import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar_actions.dart';
import '../../../shared/widgets/app_skeleton_card.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/responsive_container.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/auth_state.dart';
import '../providers/chat_provider.dart';
import '../providers/document_provider.dart';
import '../providers/appointment_provider.dart';
import '../models/chat_session_model.dart';
import '../models/document_model.dart';
import '../models/appointment_model.dart';

String _formatDateTime(DateTime dt) {
  final day = dt.day.toString().padLeft(2, '0');
  final month = dt.month.toString().padLeft(2, '0');
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  return '$day/$month $hour:$minute';
}

class ClientHomeScreen extends ConsumerWidget {
  const ClientHomeScreen({super.key});

  Future<void> _onRefresh(WidgetRef ref) async {
    ref.invalidate(chatSessionsProvider);
    ref.invalidate(documentsProvider);
    ref.invalidate(appointmentsProvider);
    await Future.wait([
      ref.read(chatSessionsProvider.future),
      ref.read(documentsProvider.future),
      ref.read(appointmentsProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userName = authState is AuthAuthenticated ? authState.user.name : '';
    final colors = Theme.of(context).colorScheme;

    final chatSessionsAsync = ref.watch(chatSessionsProvider);
    final documentsAsync = ref.watch(documentsProvider);
    final appointmentsAsync = ref.watch(appointmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alpha Connect'),
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Icon(Icons.school_rounded, color: colors.primary),
          ),
        ),
        actions: const [AppBarActions()],
      ),
      body: RefreshIndicator(
        onRefresh: () => _onRefresh(ref),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ResponsiveContainer(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting
                Text(
                  'Olá, $userName!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pronto para mais um dia de aprendizado?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Summary cards grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 500;
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildChatSummaryCard(
                                context, chatSessionsAsync, colors),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _buildAppointmentSummaryCard(
                                context, appointmentsAsync, colors),
                          ),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        _buildChatSummaryCard(
                            context, chatSessionsAsync, colors),
                        const SizedBox(height: AppSpacing.md),
                        _buildAppointmentSummaryCard(
                            context, appointmentsAsync, colors),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xl),

                // Quick Actions
                Text(
                  'Ações Rápidas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildQuickActions(context, documentsAsync),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatSummaryCard(
    BuildContext context,
    AsyncValue<List<ChatSessionModel>> asyncValue,
    ColorScheme colors,
  ) {
    return asyncValue.when(
      loading: () => const AppSkeletonCard(height: 140),
      error: (_, __) => _SummaryGlassCard(
        icon: Icons.smart_toy_outlined,
        iconBgColor: colors.primaryContainer,
        iconColor: colors.onPrimaryContainer,
        title: 'Chatbot Alpha',
        subtitle: 'Assistente Virtual',
        bottomLabel: 'Última interação:',
        bottomValue: 'Erro ao carregar',
        onTap: () => context.go(RoutePaths.clientChat),
      ),
      data: (sessions) {
        String lastTime;
        if (sessions.isEmpty) {
          lastTime = 'Nenhuma';
        } else {
          lastTime = _formatDateTime(sessions.first.startedAt);
        }
        return _SummaryGlassCard(
          icon: Icons.smart_toy_outlined,
          iconBgColor: colors.primaryContainer,
          iconColor: colors.onPrimaryContainer,
          title: 'Chatbot Alpha',
          subtitle: 'Assistente Virtual',
          bottomLabel: 'Última interação:',
          bottomValue: lastTime,
          onTap: () => context.go(RoutePaths.clientChat),
        );
      },
    );
  }

  Widget _buildAppointmentSummaryCard(
    BuildContext context,
    AsyncValue<List<AppointmentModel>> asyncValue,
    ColorScheme colors,
  ) {
    return asyncValue.when(
      loading: () => const AppSkeletonCard(height: 140),
      error: (_, __) => _SummaryGlassCard(
        icon: Icons.calendar_today,
        iconBgColor: colors.secondaryContainer,
        iconColor: colors.onSecondaryContainer,
        title: 'Agendamentos',
        subtitle: 'Próximos Eventos',
        bottomLabel: 'Próximo:',
        bottomValue: 'Erro ao carregar',
        onTap: () => context.go(RoutePaths.clientNotifications),
      ),
      data: (appointments) {
        final upcoming = appointments.where((a) => a.isUpcoming).toList();
        String nextTime;
        if (upcoming.isEmpty) {
          nextTime = 'Sem agendamentos';
        } else {
          final next = upcoming.first;
          nextTime = '${next.slotDate ?? ''} ${next.slotStartTime ?? ''}'.trim();
          if (nextTime.isEmpty) nextTime = 'Agendado';
        }
        return _SummaryGlassCard(
          icon: Icons.calendar_today,
          iconBgColor: colors.secondaryContainer,
          iconColor: colors.onSecondaryContainer,
          title: 'Agendamentos',
          subtitle: 'Próximos Eventos',
          bottomLabel: 'Próximo:',
          bottomValue: nextTime,
          onTap: () => context.go(RoutePaths.clientNotifications),
        );
      },
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    AsyncValue<List<DocumentModel>> documentsAsync,
  ) {
    final colors = Theme.of(context).colorScheme;

    final actions = [
      _QuickAction(
        label: 'Solicitar documento',
        icon: Icons.description_outlined,
        color: colors.primary,
        onTap: () => context.go(RoutePaths.clientDocuments),
      ),
      _QuickAction(
        label: 'Conversar com Mentor',
        icon: Icons.chat_outlined,
        color: colors.secondary,
        onTap: () => context.go(RoutePaths.clientChat),
      ),
      _QuickAction(
        label: 'Notificações',
        icon: Icons.notifications_outlined,
        color: colors.tertiary,
        onTap: () => context.go(RoutePaths.clientNotifications),
      ),
      _QuickAction(
        label: 'Suporte',
        icon: Icons.support_agent_outlined,
        color: colors.error,
        onTap: () => context.go(RoutePaths.clientSupport),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 2.2,
      children: actions.map((action) {
        return GlassCard(
          onTap: action.onTap,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(action.icon, size: 20, color: action.color),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  action.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SummaryGlassCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String bottomLabel;
  final String bottomValue;
  final VoidCallback? onTap;

  const _SummaryGlassCard({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.bottomLabel,
    required this.bottomValue,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Icon(icon, size: 24, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    bottomLabel,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ),
                Flexible(
                  child: Text(
                    bottomValue,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                    overflow: TextOverflow.ellipsis,
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

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
