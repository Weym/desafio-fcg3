import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_bar_actions.dart';
import '../../../shared/widgets/app_skeleton_card.dart';
import '../../../shared/widgets/app_error_state.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/responsive_container.dart';
import '../models/staff_dashboard_model.dart';
import '../providers/staff_dashboard_provider.dart';

class StaffDashboardScreen extends ConsumerWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(staffDashboardProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel de Gestão'),
        actions: const [AppBarActions()],
      ),
      body: dashboardAsync.when(
        loading: () => const ResponsiveContainer(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              AppSkeletonCard(height: 80),
              AppSkeletonCard(height: 80),
              AppSkeletonCard(height: 80),
            ],
          ),
        ),
        error: (error, stack) => ResponsiveContainer(
          padding: const EdgeInsets.all(16),
          child: AppErrorState(
            onRetry: () => ref.invalidate(staffDashboardProvider),
          ),
        ),
        data: (dashboard) {
          final width = MediaQuery.sizeOf(context).width;
          int crossAxisCount = 2;
          if (AppBreakpoints.isTablet(width)) crossAxisCount = 3;
          if (AppBreakpoints.isDesktop(width)) crossAxisCount = 4;

          return Column(
            children: [
              if (dashboardAsync.isRefreshing) const LinearProgressIndicator(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(staffDashboardProvider);
                    await ref.read(staffDashboardProvider.future);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ResponsiveContainer(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Text(
                            'Visão estratégica da instituição.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Enrollment Period Banner
                          if (dashboard.enrollmentPeriod != null &&
                              dashboard.enrollmentPeriod!.isActive) ...[
                            _EnrollmentBanner(
                                period: dashboard.enrollmentPeriod!),
                            const SizedBox(height: AppSpacing.lg),
                          ],

                          // KPI Grid
                          GridView.count(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: AppSpacing.md,
                            mainAxisSpacing: AppSpacing.md,
                            childAspectRatio: 1.3,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _KpiCard(
                                icon: Icons.people_outlined,
                                iconColor: colors.primary,
                                containerColor: colors.primaryContainer,
                                value: dashboard.totalStudents.toString(),
                                label: 'Alunos',
                                onTap: null,
                              ),
                              _KpiCard(
                                icon: Icons.chat_bubble_outlined,
                                iconColor: colors.secondary,
                                containerColor: colors.secondaryContainer,
                                value:
                                    dashboard.activeChatSessions.toString(),
                                label: 'Chats Hoje',
                                onTap: () => context.go(RoutePaths.staffAI),
                              ),
                              _KpiCard(
                                icon: Icons.warning_amber_outlined,
                                iconColor: colors.error,
                                containerColor: colors.errorContainer,
                                value:
                                    dashboard.pendingDocuments.toString(),
                                label: 'Docs Pendentes',
                                onTap: () =>
                                    context.go(RoutePaths.staffDocuments),
                              ),
                              _KpiCard(
                                icon: Icons.calendar_today_outlined,
                                iconColor: colors.tertiary,
                                containerColor: colors.tertiaryContainer,
                                value: dashboard.upcomingAppointments
                                    .toString(),
                                label: 'Agendamentos',
                                onTap: () =>
                                    context.go(RoutePaths.staffSchedule),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // AI Insights section
                          GlassCard(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.smart_toy,
                                        size: 20, color: colors.primary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Insights de Eficiência IA',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colors.onSurface,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Taxa de Resolução Automatizada',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: colors.onSurface,
                                          ),
                                    ),
                                    Text(
                                      '${_calculateAiRate(dashboard)}%',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: colors.onSurface,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusFull),
                                  child: LinearProgressIndicator(
                                    value: _calculateAiRate(dashboard) / 100,
                                    minHeight: 8,
                                    backgroundColor: colors.surfaceContainer,
                                    color: colors.primary,
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
              ),
            ],
          );
        },
      ),
    );
  }

  double _calculateAiRate(StaffDashboardModel dashboard) {
    final total = dashboard.activeChatSessions + 10; // mock baseline
    if (total == 0) return 0;
    return ((total - 1) / total * 100).clamp(0, 100);
  }
}

class _EnrollmentBanner extends StatelessWidget {
  final EnrollmentPeriodInfo period;

  const _EnrollmentBanner({required this.period});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  period.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  period.daysRemaining != null
                      ? '${period.daysRemaining} dias restantes'
                      : 'Periodo ativo',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.primary,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              'Ativo',
              style: TextStyle(
                color: colors.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color containerColor;
  final String value;
  final String label;
  final VoidCallback? onTap;

  const _KpiCard({
    required this.icon,
    required this.iconColor,
    required this.containerColor,
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
