import 'package:flutter/material.dart';
import 'package:interactive_notifications/core/style/container.dart';
import 'package:interactive_notifications/core/util/constants.dart';


class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const Color _inactiveColor = Color(0xFF8E8E93);
  static const Color _activeBackground = Color(0x66D4FFD0);

  static const List<IconData> _icons = [
    Icons.home_filled,
    Icons.timer,
    Icons.settings,
  ];

  @override
  Widget build(BuildContext context) {
    Color activeColor = Theme.of(context).colorScheme.primary;
    Color backgroundColor = Theme.of(context).colorScheme.surfaceContainer;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
        child: Container(
          height: 64,
          decoration: defaultBoxDecoration(backgroundColor),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Row(
              children: List.generate(_icons.length, (index) {
                final bool isSelected = currentIndex == index;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(index),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _activeBackground
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(defaultCornerRadius),
                        border: isSelected
                            ? Border.all(
                                color: Colors.white.withValues(alpha: 0.9),
                                width: 1.5,
                              )
                            : null,
                      ),
                      child: Center(
                        child: AnimatedScale(
                          scale: isSelected ? 1.2 : 1.0,
                          duration: const Duration(milliseconds: 250),
                          child: Icon(
                            _icons[index],
                            size: defaultIconPixelSize,
                            color: isSelected ? activeColor : _inactiveColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
