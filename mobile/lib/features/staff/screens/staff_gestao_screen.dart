import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/auth/providers/auth_state.dart';

/// Management screen (6th tab). Per D-12:
/// - Provider sees TabBar: "Staff" + "Alunos"
/// - Staff sees student list placeholder directly (D-11)
class StaffGestaoScreen extends ConsumerWidget {
  const StaffGestaoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isProvider = authState is AuthAuthenticated && authState.user.isProvider;

    if (isProvider) {
      return const _ProviderGestaoView();
    }
    return const _StaffGestaoView();
  }
}

/// Provider view: TabBar with "Staff" and "Alunos" tabs (D-12).
/// Staff tab will show full CRUD (Plan 04). Alunos tab = placeholder (D-13).
class _ProviderGestaoView extends StatelessWidget {
  const _ProviderGestaoView();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestão'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Staff'),
              Tab(text: 'Alunos'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // Staff tab — placeholder for Plan 04 staff list
            Center(child: Text('Carregando gestão de staff...')),
            // Alunos tab — placeholder pending Phase 19 integration (D-13)
            Center(child: Text('Gestão de alunos será integrada em breve')),
          ],
        ),
      ),
    );
  }
}

/// Staff view: sees student list directly without TabBar (D-11).
/// Placeholder pending Phase 19 integration.
class _StaffGestaoView extends StatelessWidget {
  const _StaffGestaoView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão de Alunos'),
      ),
      body: const Center(
        child: Text('Gestão de alunos será integrada em breve'),
      ),
    );
  }
}
