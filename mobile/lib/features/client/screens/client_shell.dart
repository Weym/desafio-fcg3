import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../shared/widgets/app_offline_banner.dart';
import '../../../shared/widgets/glass_bottom_nav.dart';
import '../providers/chat_provider.dart';
import '../providers/document_provider.dart';
import '../providers/appointment_provider.dart';
import '../providers/resource_booking_provider.dart';

class ClientShell extends ConsumerStatefulWidget {
  final Widget child;
  const ClientShell({super.key, required this.child});

  @override
  ConsumerState<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends ConsumerState<ClientShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefetchAdjacentTabs();
    });
  }

  void _prefetchAdjacentTabs() {
    ref.read(chatSessionsProvider);
    ref.read(documentsProvider);
    ref.read(appointmentsProvider);
    ref.read(availableResourcesProvider);
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(RoutePaths.clientChat)) return 1;
    if (location.startsWith(RoutePaths.clientDocuments)) return 2;
    if (location.startsWith(RoutePaths.clientNotifications)) return 3;
    if (location.startsWith(RoutePaths.clientResources)) return 4;
    if (location.startsWith(RoutePaths.clientSupport)) return 5;
    return 0;
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
        context.go(RoutePaths.clientResources);
      case 5:
        context.go(RoutePaths.clientSupport);
    }
  }

  static const _destinations = <NavItem>[
    NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Início'),
    NavItem(icon: Icons.chat_outlined, activeIcon: Icons.chat, label: 'Chat'),
    NavItem(icon: Icons.description_outlined, activeIcon: Icons.description, label: 'Docs'),
    NavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'Avisos'),
    NavItem(icon: Icons.meeting_room_outlined, activeIcon: Icons.meeting_room, label: 'Recursos'),
  ];

  static const _railDestinations = [
    NavigationRailDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: Text('Início'),
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
      label: Text('Notificações'),
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
