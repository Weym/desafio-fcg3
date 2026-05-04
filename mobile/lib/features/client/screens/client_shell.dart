import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex(context),
        onTap: (index) => _onTap(context, index),
        type: BottomNavigationBarType.fixed,
        items: const [
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
        ],
      ),
    );
  }
}
