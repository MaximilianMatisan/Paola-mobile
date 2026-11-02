// Small help "readme" for the current page: a question mark button at the
// bottom right that opens a short explanation with the main points of the
// page. Same idea as components/page-help.tsx of the paola web app.
//
// Each screen passes it as `floatingActionButton` of its Scaffold, with the
// texts from translations.dart (helpXTitle / helpXIntro / helpXBullets).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:paola_mobile/core/l10n/app_language.dart';
import 'package:paola_mobile/core/style/paola_theme.dart';

class PageHelpContent {
  final String title;
  final String intro;
  final List<String> bullets;

  const PageHelpContent({
    required this.title,
    required this.intro,
    required this.bullets,
  });
}

class PageHelpButton extends StatefulWidget {
  final PageHelpContent help;

  const PageHelpButton({super.key, required this.help});

  /// Space to leave below a page's content so the button doesn't cover it.
  static const double bottomSpace = 88;

  @override
  State<PageHelpButton> createState() => _PageHelpButtonState();
}

class _PageHelpButtonState extends State<PageHelpButton> {
  static const double _buttonSize = 44;
  static const double _maxCardWidth = 320;

  bool _open = false;

  void _toggle() => setState(() => _open = !_open);

  @override
  Widget build(BuildContext context) {
    final cardWidth = math.min(
      _maxCardWidth,
      MediaQuery.sizeOf(context).width - 32,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_open) ...[
          SizedBox(
            width: cardWidth,
            child: _HelpCard(
              help: widget.help,
              onClose: () => setState(() => _open = false),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Tooltip(
          message: context.t.helpButtonTooltip,
          child: Material(
            color: context.colors.surface,
            shape: CircleBorder(side: BorderSide(color: context.colors.line)),
            elevation: 4,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _toggle,
              child: SizedBox(
                width: _buttonSize,
                height: _buttonSize,
                child: Icon(
                  _open ? Icons.close : Icons.help_outline,
                  size: 24,
                  color: context.colors.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HelpCard extends StatelessWidget {
  final PageHelpContent help;
  final VoidCallback onClose;

  const _HelpCard({required this.help, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bodyStyle = TextStyle(
      fontSize: 14,
      height: 1.35,
      color: colors.textPrimary,
    );

    return Material(
      color: colors.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PaolaRadius.card),
        side: BorderSide(color: colors.line),
      ),
      child: ConstrainedBox(
        // Long texts scroll inside the card instead of overflowing.
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.6,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      help.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    tooltip: context.t.helpClose,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      help.intro,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final bullet in help.bullets)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('•  ', style: bodyStyle),
                            Expanded(child: Text(bullet, style: bodyStyle)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
