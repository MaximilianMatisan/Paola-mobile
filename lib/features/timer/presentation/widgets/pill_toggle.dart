import 'package:flutter/material.dart';
import 'package:interactive_notifications/core/util/constants.dart';

import '../../../../core/util/displayable.dart';

class PillToggle<T extends Displayable> extends StatelessWidget {
  final List<T> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool isAllowedToChangeOption;

  const PillToggle({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
    required this.isAllowedToChangeOption,
  });

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme
        .of(context)
        .colorScheme;

    Color activePillColor = isAllowedToChangeOption ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return IntrinsicWidth(
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(defaultCornerRadius),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                alignment: options.length == 1
                    ? Alignment.center
                    : Alignment(
                    -1 + 2 * selectedIndex / (options.length - 1), 0),
                child: FractionallySizedBox(
                  widthFactor: 1 / options.length,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: activePillColor,
                      borderRadius: BorderRadius.circular(defaultCornerRadius),
                    ),
                  ),
                ),
              ),
            ),
            IntrinsicHeight(
              child: Row(
                children: List.generate(options.length, (i) {
                  final selected = i == selectedIndex;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => isAllowedToChangeOption ? onChanged(i) : (),
                      child: Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 250),
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : colorScheme.onSurfaceVariant,
                          ),
                          child: Text(options[i].toDisplayableString()),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
