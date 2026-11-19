// Dropdown to switch the selected course, like components/CourseSwitcher.tsx
// of the web app. Nothing without courses (web app never connected), a plain
// label with one course, a menu with more.

import 'package:flutter/material.dart';
import 'package:paola_mobile/core/l10n/app_language.dart';
import 'package:paola_mobile/core/l10n/translations.dart';
import 'package:paola_mobile/core/style/paola_theme.dart';
import 'package:paola_mobile/core/util/constants.dart';
import 'package:paola_mobile/features/courses/data/course_repository.dart';
import 'package:paola_mobile/features/courses/models/course.dart';

String roleLabel(CourseRole role, Translations t) => switch (role) {
  CourseRole.student => t.roleStudent,
  CourseRole.tutor => t.roleTutor,
  CourseRole.prof => t.roleProf,
  CourseRole.forsch => t.roleForsch,
};

class CourseSwitcher extends StatelessWidget {
  const CourseSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = CourseRepository.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([repo.courses, repo.selectedCourseId]),
      builder: (context, _) {
        final courses = repo.courses.value;
        if (courses.isEmpty) return const SizedBox.shrink();
        final selected = repo.selectedCourse;
        final label = _Label(course: selected, dropdown: courses.length > 1);
        if (courses.length == 1) return label;
        return PopupMenuButton<int>(
          initialValue: selected?.id,
          color: context.colors.surface,
          tooltip: context.t.courseSwitcherPlaceholder,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PaolaRadius.control),
            side: BorderSide(color: context.colors.line),
          ),
          onSelected: repo.select,
          itemBuilder: (_) => [
            for (final c in courses)
              PopupMenuItem(
                value: c.id,
                child: Row(
                  children: [
                    Icon(
                      Icons.check,
                      size: 18,
                      color: c.id == selected?.id
                          ? context.colors.primary
                          : Colors.transparent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        c.title,
                        style: TextStyle(color: context.colors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _RoleTag(course: c),
                  ],
                ),
              ),
          ],
          child: label,
        );
      },
    );
  }
}

/// The selected course as a small box, with an arrow if it opens a menu.
class _Label extends StatelessWidget {
  final Course? course;
  final bool dropdown;

  const _Label({required this.course, required this.dropdown});

  @override
  Widget build(BuildContext context) {
    final course = this.course;
    return Container(
      padding: EdgeInsets.fromLTRB(10, 6, dropdown ? 6 : 10, 6),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border.all(color: context.colors.line),
        borderRadius: BorderRadius.circular(PaolaRadius.control),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              course?.title ?? context.t.courseSwitcherPlaceholder,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: context.colors.textPrimary,
              ),
            ),
          ),
          if (course != null) ...[
            const SizedBox(width: 6),
            _RoleTag(course: course),
          ],
          if (dropdown) ...[
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: context.colors.textSecondary,
            ),
          ],
        ],
      ),
    );
  }
}

/// The user's role in [course], or "Demo" for the web app's demo course.
class _RoleTag extends StatelessWidget {
  final Course course;

  const _RoleTag({required this.course});

  @override
  Widget build(BuildContext context) {
    if (course.id == demoCourseId) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: context.colors.primaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          context.t.courseSwitcherDemoBadge,
          style: TextStyle(fontSize: 11, color: context.colors.primary),
        ),
      );
    }
    return Text(
      roleLabel(course.role, context.t),
      style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
    );
  }
}
