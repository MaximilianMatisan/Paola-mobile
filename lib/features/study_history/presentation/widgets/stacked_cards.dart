import 'package:flutter/material.dart';
import 'package:paola_mobile/core/style/container.dart';
import 'package:paola_mobile/core/util/constants.dart';

import '../../../timer/models/mood.dart';

class StackedCard extends StatelessWidget {
  const StackedCard({
    super.key,
    required this.label,
    required this.value,
    required this.mood,
    this.onTap,
    this.layers = 2,
    this.layerOffset = 10.0,
    this.layerInset = 10.0,
  }) : assert(layers >= 0);

  final String label;
  final String value;
  final Mood mood;
  final VoidCallback? onTap;

  final int layers;

  final double layerOffset;

  final double layerInset;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color cardColor = colorScheme.surfaceContainer;
    final Color iconBackgroundColor = colorScheme.surfaceContainerLowest;
    final BorderRadius borderRadius = BorderRadius.circular(
      defaultCornerRadius,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (int i = layers; i >= 1; i--)
          Positioned(
            left: i * layerInset,
            right: i * layerInset,
            top: i * layerOffset,
            bottom: -i * layerOffset,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                color: Color.lerp(cardColor, Colors.black, 0.05),
                boxShadow: [defaultBoxShadow()],
              ),
            ),
          ),

        Material(
          color: cardColor,
          elevation: 5,
          borderRadius: borderRadius,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30, 10, 30, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label.toUpperCase(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          value,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 65,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: iconBackgroundColor,
                    ),
                    child: Icon(
                      mood.icon,
                      size: largeIconPixelSize,
                      color: mood.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
