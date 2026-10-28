// Confirmation card shown before any delete action ("Delete Confirmation"
// component in the Figma file). Use it via [confirmDelete].

import 'package:flutter/material.dart';
import 'package:paola_mobile/core/l10n/app_language.dart';

import 'package:paola_mobile/core/style/paola_theme.dart';

/// Shows the delete confirmation over a dimmed screen. Resolves to true only
/// if the user tapped the confirm button; Cancel or tapping outside gives false.
/// [confirmLabel] defaults to "Delete" in the current language.
Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierColor: context.colors.scrim,
    builder: (context) => _DeleteConfirmation(
      title: title,
      message: message,
      confirmLabel: confirmLabel ?? context.t.delete,
    ),
  );
  return confirmed ?? false;
}

class _DeleteConfirmation extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;

  const _DeleteConfirmation({
    required this.title,
    required this.message,
    required this.confirmLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Material(
            type: MaterialType.transparency,
            child: PaolaCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.35,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: PaolaButton(
                          label: context.t.cancel,
                          style: PaolaButtonStyle.secondary,
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PaolaButton(
                          label: confirmLabel,
                          style: PaolaButtonStyle.dangerFilled,
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
