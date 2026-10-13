import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A destination in [AppBottomNav].
class AppNavDestination {
  const AppNavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// The five main tabs, in order.
const appNavDestinations = [
  AppNavDestination(
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
  ),
  AppNavDestination(
    label: 'Learn',
    icon: Icons.menu_book_outlined,
    selectedIcon: Icons.menu_book_rounded,
  ),
  AppNavDestination(
    label: 'Practice',
    icon: Icons.edit_note_outlined,
    selectedIcon: Icons.edit_note_rounded,
  ),
  AppNavDestination(
    label: 'Progress',
    icon: Icons.insights_outlined,
    selectedIcon: Icons.insights_rounded,
  ),
  AppNavDestination(
    label: 'Profile',
    icon: Icons.person_outline_rounded,
    selectedIcon: Icons.person_rounded,
  ),
];

/// Bottom navigation bar. The selected tab is purple, bold, and marked with a
/// dot so selection doesn't rely on color alone.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.destinations = appNavDestinations,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AppNavDestination> destinations;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: AppShadows.raised,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              for (var i = 0; i < destinations.length; i++)
                Expanded(
                  child: _NavItem(
                    destination: destinations[i],
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                    index: i,
                    count: destinations.length,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
    required this.index,
    required this.count,
  });

  final AppNavDestination destination;
  final bool selected;
  final VoidCallback onTap;
  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textMuted;
    return Semantics(
      button: true,
      selected: selected,
      label: '${destination.label}, tab ${index + 1} of $count',
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        highlightColor: AppColors.primaryTint,
        splashColor: AppColors.primaryTint,
        radius: 40,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? destination.selectedIcon : destination.icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              destination.label,
              style: AppTextStyles.labelSm.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : null,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
