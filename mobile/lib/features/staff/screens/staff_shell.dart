import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../shared/widgets/app_offline_banner.dart';

class StaffShell extends StatelessWidget {
  final Widget child;
  const StaffShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(RoutePaths.staffSchedule)) return 1;
    if (location.startsWith(RoutePaths.staffAI)) return 2;
    if (location.startsWith(RoutePaths.staffDocuments)) return 3;
    return 0; // Dashboard
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(RoutePaths.staffDashboard);
      case 1:
        context.go(RoutePaths.staffSchedule);
      case 2:
        context.go(RoutePaths.staffAI);
      case 3:
        context.go(RoutePaths.staffDocuments);
    }
  }

  static const _navItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_outlined),
      activeIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.calendar_today_outlined),
      activeIcon: Icon(Icons.calendar_today),
      label: 'Agenda',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.psychology_outlined),
      activeIcon: Icon(Icons.psychology),
      label: 'IA',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.folder_outlined),
      activeIcon: Icon(Icons.folder),
      label: 'Documentos',
    ),
  ];

  static const _railDestinations = [
    NavigationRailDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: Text('Dashboard'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.calendar_today_outlined),
      selectedIcon: Icon(Icons.calendar_today),
      label: Text('Agenda'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.psychology_outlined),
      selectedIcon: Icon(Icons.psychology),
      label: Text('IA'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.folder_outlined),
      selectedIcon: Icon(Icons.folder),
      label: Text('Documentos'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (AppBreakpoints.isPhone(width)) {
          // Phone: BottomNavigationBar (existing behavior)
          return Scaffold(
            body: Column(
              children: [
                const AppOfflineBanner(),
                Expanded(child: child),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex(context),
              onTap: (index) => _onTap(context, index),
              type: BottomNavigationBarType.fixed,
              items: _navItems,
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
                    ),
                    const VerticalDivider(width: 1, thickness: 1),
                    Expanded(child: child),
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
