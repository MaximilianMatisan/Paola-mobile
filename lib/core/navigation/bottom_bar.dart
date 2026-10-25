import 'package:flutter/material.dart';
import 'package:paola_mobile/core/util/constants.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const List<_NavItem> _items = [
    _NavItem(Icons.home_outlined, 'Home'),
    _NavItem(Icons.schedule_outlined, 'Timer'),
    _NavItem(Icons.settings_outlined, 'Settings'),
  ];

  static const double _navBarHeight = 80;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerLowest,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: scheme.outlineVariant, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: _navBarHeight,
            child: Row(
              children: [
                for (int i = 0; i < _items.length; i++)
                  Expanded(
                    child: _NavBarItem(
                      icon: _items[i].icon,
                      label: _items[i].label,
                      selected: i == currentIndex,
                      onTap: () => onTap(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem(this.icon, this.label);
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  static const Duration _duration = Duration(milliseconds: 220);
  static const double _selectedTabLineWidth = 40;
  static const double _selectedTabLineHeight = 3;
  static const double _navBarFontSize = 14;
  static const double _spaceBetweenElements = 4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final Color contentColor =
    selected ? scheme.onSurface : scheme.onSurfaceVariant;

    final TextStyle labelStyle = (theme.textTheme.labelLarge ??
        const TextStyle())
        .copyWith(
      fontSize: _navBarFontSize,
      color: contentColor,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
    );

    return InkWell(
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: defaultIconPixelSize, color: contentColor),
              const SizedBox(height: _spaceBetweenElements),
              AnimatedDefaultTextStyle(
                style: labelStyle,
                duration: _duration,
                child: Text(label),
              ),
              const SizedBox(height: _spaceBetweenElements),
              // Selected tab line
              AnimatedContainer(
                duration: _duration,
                curve: Curves.easeOutCubic,
                width: selected ? _selectedTabLineWidth : 0,
                height: selected ? _selectedTabLineHeight : 0,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ],
          ),
        ),
    );
  }
}
