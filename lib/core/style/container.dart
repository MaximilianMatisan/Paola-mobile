import 'package:flutter/material.dart';
import 'package:interactive_notifications/core/util/constants.dart';


BoxShadow defaultBoxShadow() {
  return BoxShadow(
    color: Colors.black.withValues(alpha: 0.25),
    blurRadius: 4,
    spreadRadius: 1,
    offset: const Offset(0, 4),
  );
}

BoxDecoration defaultBoxDecoration(Color color) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(defaultCornerRadius),
    boxShadow: [defaultBoxShadow()],
  );
}