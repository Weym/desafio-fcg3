import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../shared/widgets/app_offline_banner.dart';

class ClientShell extends StatelessWidget {
  final Widget child;
  const ClientShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(RoutePaths.clientChat)) return 1;
    if (location.startsWith(RoutePaths.clientDocuments)) return 2;
    if (location.startsWith(RoutePaths.clientNotifications)) return 3;
    if (location.startsWith(RoutePaths.clientSupport)) return 4;
    return 0; // Home
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(RoutePaths.clientHome);
      case 1:
        context.go(RoutePaths.clientChat);
      case 2:
        context.go(RoutePaths.clientDocuments);
      case 3:
        context.go(RoutePaths.clientNotifications);
      case 4:
        context.go(RoutePaths.clientSupport);
    }
  }

  static const _navItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.chat_outlined),
      activeIcon: Icon(Icons.chat),
      label: 'Chat',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.description_outlined),
      activeIcon: Icon(Icons.description),
      label: 'Documentos',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.notifications_outlined),
      activeIcon: Icon(Icons.notifications),
      label: 'Notificacoes',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.support_agent_outlined),
      activeIcon: Icon(Icons.support_agent),
      label: 'Suporte',
    ),
  ];

  static const _railDestinations = [
    NavigationRailDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: Text('Home'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.chat_outlined),
      selectedIcon: Icon(Icons.chat),
      label: Text('Chat'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.description_outlined),
      selectedIcon: Icon(Icons.description),
      label: Text('Documentos'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.notifications_outlined),
      selectedIcon: Icon(Icons.notifications),
      label: Text('Notificacoes'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.support_agent_outlined),
      selectedIcon: Icon(Icons.support_agent),
      label: Text('Suporte'),
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
