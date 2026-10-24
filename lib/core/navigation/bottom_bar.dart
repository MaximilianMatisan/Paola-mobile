import 'package:flutter/material.dart';
import 'package:paola_mobile/core/style/container.dart';
import 'package:paola_mobile/core/util/constants.dart';


class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const List<IconData> _icons = [
    Icons.home_filled,
    Icons.timer,
    Icons.settings,
  ];

  @override
  Widget build(BuildContext context) {
    Color activeColor = Theme.of(context).colorScheme.primary;
    Color backgroundColor = Theme.of(context).colorScheme.surfaceContainer;
    Color inactiveColor = Theme.of(context).colorScheme.onSurfaceVariant;
    Color activeBackground = Theme.of(context).colorScheme.primaryContainer;

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
                            ? activeBackground
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(defaultCornerRadius),
                        border: isSelected
                            ? Border.all(
                                color: backgroundColor,
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
                            color: isSelected ? activeColor : inactiveColor,
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
