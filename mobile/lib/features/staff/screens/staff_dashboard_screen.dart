import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../models/staff_dashboard_model.dart';
import '../providers/staff_dashboard_provider.dart';

class StaffDashboardScreen extends ConsumerWidget {
  const StaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(staffDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              const Text('Erro ao carregar dashboard'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(staffDashboardProvider),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (dashboard) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(staffDashboardProvider);
            await ref.read(staffDashboardProvider.future);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enrollment Period Banner (D-02)
                if (dashboard.enrollmentPeriod != null &&
                    dashboard.enrollmentPeriod!.isActive)
                  _EnrollmentBanner(period: dashboard.enrollmentPeriod!),
                if (dashboard.enrollmentPeriod != null &&
                    dashboard.enrollmentPeriod!.isActive)
                  const SizedBox(height: 16),
                // KPI Grid (D-01)
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _KpiCard(
                      icon: Icons.people_outlined,
                      iconColor: Colors.blue.shade700,
                      value: dashboard.totalStudents,
                      label: 'Alunos',
                      onTap: null,
                    ),
                    _KpiCard(
                      icon: Icons.school_outlined,
                      iconColor: Colors.purple.shade700,
                      value: dashboard.activeEnrollments,
                      label: 'Matriculas',
                      onTap: null,
                    ),
                    _KpiCard(
                      icon: Icons.folder_outlined,
                      iconColor: Colors.amber.shade700,
                      value: dashboard.pendingDocuments,
                      label: 'Docs Pendentes',
                      onTap: () => context.go(RoutePaths.staffDocuments),
                    ),
                    _KpiCard(
                      icon: Icons.calendar_today_outlined,
                      iconColor: Theme.of(context).colorScheme.tertiary,
                      value: dashboard.upcomingAppointments,
                      label: 'Agendamentos',
                      onTap: () => context.go(RoutePaths.staffSchedule),
                    ),
                    _KpiCard(
                      icon: Icons.chat_bubble_outlined,
                      iconColor: Colors.green.shade700,
                      value: dashboard.activeChatSessions,
                      label: 'Chats Ativos',
                      onTap: () => context.go(RoutePaths.staffAI),
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

class _EnrollmentBanner extends StatelessWidget {
  final EnrollmentPeriodInfo period;

  const _EnrollmentBanner({required this.period});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${period.daysRemaining} dias restantes',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Ativo',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final int value;
  final String label;
  final VoidCallback? onTap;

  const _KpiCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const Spacer(),
            Text(
              value.toString(),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: card,
      );
    }
    return card;
  }
}
