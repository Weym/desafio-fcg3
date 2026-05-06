import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../core/responsive/breakpoints.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_offline_banner.dart';
import '../providers/chat_provider.dart';
import '../providers/document_provider.dart';
import '../providers/appointment_provider.dart';

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
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(RoutePaths.clientChat)) return 1;
    if (location.startsWith(RoutePaths.clientDocuments)) return 2;
    if (location.startsWith(RoutePaths.clientNotifications)) return 3;
    if (location.startsWith(RoutePaths.clientSupport)) return 4;
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
        context.go(RoutePaths.clientSupport);
    }
  }

  static const _destinations = <_NavItem>[
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Início'),
    _NavItem(icon: Icons.chat_outlined, activeIcon: Icons.chat, label: 'Chat'),
    _NavItem(icon: Icons.description_outlined, activeIcon: Icons.description, label: 'Docs'),
    _NavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'Avisos'),
    _NavItem(icon: Icons.support_agent_outlined, activeIcon: Icons.support_agent, label: 'Suporte'),
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
          return Scaffold(
            body: Column(
              children: [
                const AppOfflineBanner(),
                Expanded(child: widget.child),
              ],
            ),
            extendBody: true,
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

// Internal nav item data class
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
