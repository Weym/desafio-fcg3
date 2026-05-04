import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
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
  final year = dt.year;
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
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

    final chatSessionsAsync = ref.watch(chatSessionsProvider);
    final documentsAsync = ref.watch(documentsProvider);
    final appointmentsAsync = ref.watch(appointmentsProvider);

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _onRefresh(ref),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ola, $userName!',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              _buildChatCard(context, chatSessionsAsync),
              const SizedBox(height: 12),
              _buildAppointmentCard(context, appointmentsAsync),
              const SizedBox(height: 12),
              _buildDocumentCard(context, documentsAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatCard(
    BuildContext context,
    AsyncValue<List<ChatSessionModel>> asyncValue,
  ) {
    return asyncValue.when(
      loading: () => _DashboardCard(
        icon: Icons.smart_toy_outlined,
        iconColor: Theme.of(context).colorScheme.primary,
        title: 'Ultima atividade do bot',
        subtitle: 'Carregando...',
        onTap: () {},
      ),
      error: (error, stack) => _DashboardCard(
        icon: Icons.smart_toy_outlined,
        iconColor: Theme.of(context).colorScheme.primary,
        title: 'Ultima atividade do bot',
        subtitle: 'Erro ao carregar',
        onTap: () => context.go(RoutePaths.clientChat),
        trailing: const Icon(Icons.refresh, size: 20),
      ),
      data: (sessions) {
        String subtitle;
        if (sessions.isEmpty) {
          subtitle = 'Nenhuma atividade';
        } else {
          final latest = sessions.first;
          subtitle = _formatDateTime(latest.startedAt);
        }
        return _DashboardCard(
          icon: Icons.smart_toy_outlined,
          iconColor: Theme.of(context).colorScheme.primary,
          title: 'Ultima atividade do bot',
          subtitle: subtitle,
          onTap: () => context.go(RoutePaths.clientChat),
        );
      },
    );
  }

  Widget _buildAppointmentCard(
    BuildContext context,
    AsyncValue<List<AppointmentModel>> asyncValue,
  ) {
    return asyncValue.when(
      loading: () => _DashboardCard(
        icon: Icons.calendar_today_outlined,
        iconColor: Theme.of(context).colorScheme.tertiary,
        title: 'Proximo agendamento',
        subtitle: 'Carregando...',
        onTap: () {},
      ),
      error: (error, stack) => _DashboardCard(
        icon: Icons.calendar_today_outlined,
        iconColor: Theme.of(context).colorScheme.tertiary,
        title: 'Proximo agendamento',
        subtitle: 'Erro ao carregar',
        onTap: () => context.go(RoutePaths.clientNotifications),
        trailing: const Icon(Icons.refresh, size: 20),
      ),
      data: (appointments) {
        final upcoming = appointments.where((a) => a.isUpcoming).toList();
        String subtitle;
        if (upcoming.isEmpty) {
          subtitle = 'Sem agendamentos';
        } else {
          final next = upcoming.first;
          subtitle = '${next.date ?? ''} ${next.startTime ?? ''}'.trim();
          if (subtitle.isEmpty) subtitle = 'Agendado';
        }
        return _DashboardCard(
          icon: Icons.calendar_today_outlined,
          iconColor: Theme.of(context).colorScheme.tertiary,
          title: 'Proximo agendamento',
          subtitle: subtitle,
          onTap: () => context.go(RoutePaths.clientNotifications),
        );
      },
    );
  }

  Widget _buildDocumentCard(
    BuildContext context,
    AsyncValue<List<DocumentModel>> asyncValue,
  ) {
    return asyncValue.when(
      loading: () => _DashboardCard(
        icon: Icons.description_outlined,
        iconColor: Theme.of(context).colorScheme.secondary,
        title: 'Status de documentos',
        subtitle: 'Carregando...',
        onTap: () {},
      ),
      error: (error, stack) => _DashboardCard(
        icon: Icons.description_outlined,
        iconColor: Theme.of(context).colorScheme.secondary,
        title: 'Status de documentos',
        subtitle: 'Erro ao carregar',
        onTap: () => context.go(RoutePaths.clientDocuments),
        trailing: const Icon(Icons.refresh, size: 20),
      ),
      data: (docs) {
        final pendingCount = docs.where((d) => d.isPending).length;
        final readyCount = docs.where((d) => d.status == 'ready').length;
        String subtitle;
        if (docs.isEmpty) {
          subtitle = 'Nenhum documento';
        } else {
          final parts = <String>[];
          if (pendingCount > 0) parts.add('$pendingCount pendentes');
          if (readyCount > 0) parts.add('$readyCount prontos');
          subtitle = parts.isEmpty ? 'Todos entregues' : parts.join(' · ');
        }
        return _DashboardCard(
          icon: Icons.description_outlined,
          iconColor: Theme.of(context).colorScheme.secondary,
          title: 'Status de documentos',
          subtitle: subtitle,
          onTap: () => context.go(RoutePaths.clientDocuments),
        );
      },
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _DashboardCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              ?trailing,
              if (trailing == null)
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
