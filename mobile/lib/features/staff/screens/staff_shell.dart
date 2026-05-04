import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';

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
        ],
      ),
    );
  }
}
