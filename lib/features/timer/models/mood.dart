import 'package:flutter/material.dart';
import 'package:paola_mobile/core/l10n/translations.dart';

enum Mood {
  perfect(icon: Icons.sentiment_very_satisfied, color: Colors.teal),
  good(icon: Icons.sentiment_satisfied, color: Colors.green),
  normal(icon: Icons.sentiment_neutral, color: Colors.amber),
  bad(icon: Icons.sentiment_dissatisfied, color: Colors.orange),
  miserable(icon: Icons.sentiment_very_dissatisfied, color: Colors.red);

  final IconData icon;
  final Color color;

  const Mood({required this.icon, required this.color});

  String label(Translations t) => switch (this) {
    perfect => t.moodPerfect,
    good => t.moodGood,
    normal => t.moodNormal,
    bad => t.moodBad,
    miserable => t.moodMiserable,
  };
}
