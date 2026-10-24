import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neuroplay/app/providers.dart';
import 'package:neuroplay/core/theme/app_breakpoints.dart';
import 'package:neuroplay/core/theme/app_colors.dart';
import 'package:neuroplay/core/theme/app_spacing.dart';
import 'package:neuroplay/core/theme/app_theme.dart';

/// Navigation destination metadata.
class _NavDestination {
  const _NavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.tooltip,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String tooltip;
}

const _destinations = [
  _NavDestination(
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    tooltip: 'Navigate to Home Dashboard',
  ),
  _NavDestination(
    label: 'Games',
    icon: Icons.grid_view_outlined,
    selectedIcon: Icons.grid_view_rounded,
    tooltip: 'Navigate to Games Library',
  ),
  _NavDestination(
    label: 'Progress',
    icon: Icons.bar_chart_outlined,
    selectedIcon: Icons.bar_chart_rounded,
    tooltip: 'Navigate to Progress Analytics',
  ),
  _NavDestination(
    label: 'Challenges',
    icon: Icons.flag_outlined,
    selectedIcon: Icons.flag_rounded,
    tooltip: 'Navigate to Cognitive Challenges',
  ),
  _NavDestination(
    label: 'Profile',
    icon: Icons.person_outline_rounded,
    selectedIcon: Icons.person_rounded,
    tooltip: 'Navigate to Profile and Settings',
  ),
];

/// Top-level responsive application shell.
class AppShell extends ConsumerWidget {
  const AppShell({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompact = AppBreakpoints.isCompact(context);
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final isDark = theme.brightness == Brightness.dark;

    if (isCompact) {
      // Mobile Layout: Bottom NavigationBar
      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onDestinationSelected,
          destinations: _destinations
              .map(
                (d) => NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: d.label,
                  tooltip: d.tooltip,
                ),
              )
              .toList(),
        ),
      );
    }

    // Tablet & Desktop Layout: Left NavigationRail + Body
    final isExpanded = AppBreakpoints.isExpanded(context);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _onDestinationSelected,
            extended: isExpanded,
            minExtendedWidth: 200,
            leading: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.lg,
                horizontal: AppSpacing.md,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: tokens.mintContainer,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? const Color(0x3310B981)
                            : const Color(0xFFA7F3D0),
                      ),
                    ),
                    child: Icon(
                      Icons.psychology_rounded,
                      color: tokens.onMintContainer,
                      size: 24,
                    ),
                  ),
                  if (isExpanded) ...[
                    AppSpacing.gapW12,
                    Text(
                      'NEUROPLAY',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.navy900,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: IconButton(
                    icon: Icon(
                      isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                    ),
                    tooltip: isDark
                        ? 'Switch to Light Theme'
                        : 'Switch to Dark Theme',
                    onPressed: () {
                      ref.read(themeModeProvider.notifier).toggleTheme();
                    },
                  ),
                ),
              ),
            ),
            destinations: _destinations
                .map(
                  (d) => NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
                )
                .toList(),
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: tokens.cardBorder,
          ),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}
