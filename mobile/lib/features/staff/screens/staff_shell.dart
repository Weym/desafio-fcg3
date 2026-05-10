import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../shared/widgets/app_offline_banner.dart';
import '../../../shared/widgets/glass_bottom_nav.dart';
import '../providers/staff_dashboard_provider.dart';
import '../providers/staff_schedule_provider.dart';
import '../providers/staff_document_provider.dart';
import '../providers/staff_chat_provider.dart';
import '../providers/staff_resource_provider.dart';
import '../providers/staff_intervention_provider.dart';

class StaffShell extends ConsumerStatefulWidget {
  final Widget child;
  const StaffShell({super.key, required this.child});

  @override
  ConsumerState<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends ConsumerState<StaffShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefetchAdjacentTabs();
    });
  }

  void _prefetchAdjacentTabs() {
    ref.read(staffDashboardProvider);
    ref.read(staffAppointmentsProvider);
    ref.read(staffDocumentsProvider);
    ref.read(staffChatSessionsProvider);
    ref.read(staffResourcesProvider);
    ref.read(interventionSessionsProvider);
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(RoutePaths.staffSchedule)) return 1;
    if (location.startsWith(RoutePaths.staffIntervention)) return 2;
    if (location.startsWith(RoutePaths.staffDocuments)) return 3;
    if (location.startsWith(RoutePaths.staffResources)) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(RoutePaths.staffDashboard);
      case 1:
        context.go(RoutePaths.staffSchedule);
      case 2:
        context.go(RoutePaths.staffIntervention);
      case 3:
        context.go(RoutePaths.staffDocuments);
      case 4:
        context.go(RoutePaths.staffResources);
    }
  }

  static const _destinations = <NavItem>[
    NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Painel'),
    NavItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: 'Agenda'),
    NavItem(icon: Icons.support_agent_outlined, activeIcon: Icons.support_agent, label: 'Intervenção'),
    NavItem(icon: Icons.folder_outlined, activeIcon: Icons.folder, label: 'Docs'),
    NavItem(icon: Icons.meeting_room_outlined, activeIcon: Icons.meeting_room, label: 'Recursos'),
  ];

  static const _railDestinations = [
    NavigationRailDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: Text('Painel'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.calendar_today_outlined),
      selectedIcon: Icon(Icons.calendar_today),
      label: Text('Agenda'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.support_agent_outlined),
      selectedIcon: Icon(Icons.support_agent),
      label: Text('Intervenção'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.folder_outlined),
      selectedIcon: Icon(Icons.folder),
      label: Text('Documentos'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.meeting_room_outlined),
      selectedIcon: Icon(Icons.meeting_room),
      label: Text('Recursos'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (AppBreakpoints.isPhone(width)) {
          return Scaffold(
            body: Column(
              children: [
                const AppOfflineBanner(),
                Expanded(child: widget.child),
              ],
            ),
            bottomNavigationBar: GlassBottomNav(
              currentIndex: _currentIndex(context),
              destinations: _destinations,
              onTap: (index) => _onTap(context, index),
            ),
          );
        }

        // Tablet/Desktop: NavigationRail
        final extended = AppBreakpoints.isDesktop(width);
        return Scaffold(
          body: Column(
            children: [
              const AppOfflineBanner(),
              Expanded(
                child: Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _currentIndex(context),
                      onDestinationSelected: (index) =>
                          _onTap(context, index),
                      extended: extended,
                      minWidth: 72,
                      minExtendedWidth: 180,
                      destinations: _railDestinations,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerLow,
                    ),
                    const VerticalDivider(width: 1, thickness: 1),
                    Expanded(child: widget.child),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
