import 'package:flutter/material.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const Color _backgroundColor = Color(0xFFF6F2EA);
  static const Color _activeColor = Color(0xFF34C759);
  static const Color _inactiveColor = Color(0xFF8E8E93);
  static const Color _activeBackground = Color(0x66D4FFD0);

  static const List<IconData> _icons = [
    Icons.home_filled,
    Icons.timer,
    Icons.settings,
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 4,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
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
                        borderRadius: BorderRadius.circular(30),
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
                            size: 25,
                            color: isSelected ? _activeColor : _inactiveColor,
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
