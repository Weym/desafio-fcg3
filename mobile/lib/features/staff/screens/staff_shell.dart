import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_offline_banner.dart';
import '../providers/staff_dashboard_provider.dart';
import '../providers/staff_schedule_provider.dart';
import '../providers/staff_document_provider.dart';
import '../providers/staff_chat_provider.dart';
import '../providers/staff_resource_provider.dart';

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
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(RoutePaths.staffSchedule)) return 1;
    if (location.startsWith(RoutePaths.staffAI)) return 2;
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
        context.go(RoutePaths.staffAI);
      case 3:
        context.go(RoutePaths.staffDocuments);
      case 4:
        context.go(RoutePaths.staffResources);
    }
  }

  static const _destinations = <_NavItem>[
    _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Painel'),
    _NavItem(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: 'Agenda'),
    _NavItem(icon: Icons.psychology_outlined, activeIcon: Icons.psychology, label: 'Insights'),
    _NavItem(icon: Icons.folder_outlined, activeIcon: Icons.folder, label: 'Docs'),
    _NavItem(icon: Icons.meeting_room_outlined, activeIcon: Icons.meeting_room, label: 'Recursos'),
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
      icon: Icon(Icons.psychology_outlined),
      selectedIcon: Icon(Icons.psychology),
      label: Text('Insights'),
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
            bottomNavigationBar: _GlassBottomNav(
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

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}

/// Glass-panel bottom navigation matching alpha-connect prototype.
class _GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> destinations;
  final ValueChanged<int> onTap;

  const _GlassBottomNav({
    required this.currentIndex,
    required this.destinations,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 80 + bottomPadding,
          padding: EdgeInsets.only(bottom: bottomPadding),
          decoration: BoxDecoration(
            color: isDark
                ? colors.surfaceContainerLowest.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.7),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.4),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : colors.primary.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(destinations.length, (index) {
              final item = destinations[index];
              final isSelected = index == currentIndex;

              return GestureDetector(
                onTap: () => onTap(index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSelected ? item.activeIcon : item.icon,
                        size: 24,
                        color: isSelected
                            ? colors.onPrimary
                            : colors.onSurfaceVariant,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: isSelected
                              ? colors.onPrimary
                              : colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
