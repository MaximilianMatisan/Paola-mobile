// List of all exercise sheets, like the sheet menu of the web app
// (components/sheet-sidebar.tsx): the current sheet highlighted, earlier
// ones greyed out, upcoming ones faded with a lock and not tappable.

import 'package:flutter/material.dart';
import 'package:paola_mobile/core/l10n/app_language.dart';
import 'package:paola_mobile/core/style/paola_theme.dart';
import 'package:paola_mobile/features/study_history/models/exercise_sheet.dart';
import 'package:paola_mobile/features/study_history/presentation/widgets/session_list.dart';

class SheetMenu extends StatelessWidget {
  final List<ExerciseSheet> sheets;
  final ExerciseSheet? current;

  /// Number of recorded sessions per sheet id.
  final Map<int, int> sessionCounts;

  final ValueChanged<ExerciseSheet> onOpen;

  /// Sessions outside every sheet's range; shows an extra entry when > 0.
  final int unassignedCount;
  final VoidCallback onOpenUnassigned;

  const SheetMenu({
    super.key,
    required this.sheets,
    required this.current,
    required this.sessionCounts,
    required this.onOpen,
    required this.unassignedCount,
    required this.onOpenUnassigned,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = ExerciseSheet.sortBySchedule(sheets);
    List<ExerciseSheet> byPhase(SheetPhase phase) =>
        sorted.where((s) => s.phase() == phase).toList();
    // Newest first, like a history.
    final past = byPhase(SheetPhase.past).reversed.toList();
    final active = [
      ...byPhase(SheetPhase.active),
      ...byPhase(SheetPhase.undated),
    ];
    final future = byPhase(SheetPhase.future);

    Widget section(String title, List<ExerciseSheet> items, _ItemStyle style) {
      if (items.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: context.colors.textSecondary,
                ),
              ),
            ),
            for (final s in items)
              _SheetItem(
                sheet: s,
                style: s.id == current?.id ? _ItemStyle.current : style,
                sessions: sessionCounts[s.id] ?? 0,
                onTap: style == _ItemStyle.locked ? null : () => onOpen(s),
              ),
          ],
        ),
      );
    }

    return PaolaCard(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Text(
              context.t.sheets,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.colors.textPrimary,
              ),
            ),
          ),
          section(context.t.sheetsCurrent, active, _ItemStyle.normal),
          section(context.t.sheetsEarlier, past, _ItemStyle.past),
          section(context.t.sheetsUpcoming, future, _ItemStyle.locked),
          if (unassignedCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _MenuRow(
                title: context.t.sessionsWithoutSheet,
                trailing: Text(
                  '$unassignedCount',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colors.textSecondary,
                  ),
                ),
                style: _ItemStyle.past,
                onTap: onOpenUnassigned,
              ),
            ),
        ],
      ),
    );
  }
}

enum _ItemStyle { current, normal, past, locked }

class _SheetItem extends StatelessWidget {
  final ExerciseSheet sheet;
  final _ItemStyle style;
  final int sessions;
  final VoidCallback? onTap;

  const _SheetItem({
    required this.sheet,
    required this.style,
    required this.sessions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final small = TextStyle(fontSize: 12, color: context.colors.textSecondary);
    final range = formatDateRange(sheet.validFrom, sheet.validUntil);
    final Widget trailing = style == _ItemStyle.locked
        ? Icon(
            Icons.lock_outline,
            size: 15,
            color: context.colors.textSecondary,
          )
        : Text(
            [
              if (range.isNotEmpty) range,
              if (sessions > 0) '$sessions×',
            ].join('  ·  '),
            style: small,
          );
    return _MenuRow(
      title: sheet.title,
      trailing: trailing,
      style: style,
      onTap: onTap,
      tooltip: style == _ItemStyle.locked ? context.t.sheetLocked : null,
    );
  }
}

class _MenuRow extends StatelessWidget {
  final String title;
  final Widget trailing;
  final _ItemStyle style;
  final VoidCallback? onTap;
  final String? tooltip;

  const _MenuRow({
    required this.title,
    required this.trailing,
    required this.style,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isCurrent = style == _ItemStyle.current;
    final textColor = switch (style) {
      _ItemStyle.current => colors.primary,
      _ItemStyle.normal => colors.textPrimary,
      _ItemStyle.past || _ItemStyle.locked => colors.textSecondary,
    };
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(PaolaRadius.control),
    );
    Widget row = Material(
      color: isCurrent ? colors.primaryContainer : Colors.transparent,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              trailing,
              if (onTap != null) ...[
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 18, color: textColor),
              ],
            ],
          ),
        ),
      ),
    );
    if (style == _ItemStyle.locked) row = Opacity(opacity: 0.45, child: row);
    if (tooltip != null) row = Tooltip(message: tooltip!, child: row);
    return row;
  }
}
