// Exercise sheets of the selected course for the analysis tab. They come
// from the web app (when it is connected) through CourseRepository and are
// kept in the local database, so the sheets still show offline.

import 'package:paola_mobile/core/data/local_database.dart';
import 'package:paola_mobile/features/courses/data/course_repository.dart';
import 'package:paola_mobile/features/study_history/models/exercise_sheet.dart';

class SheetRepository {
  SheetRepository._();
  static final SheetRepository instance = SheetRepository._();

  /// Sheets of the selected course; empty without a course. With [refresh]
  /// the courses are fetched from the web app first, if it can be reached.
  Future<List<ExerciseSheet>> sheets({bool refresh = true}) async {
    final courses = CourseRepository.instance;
    if (refresh) await courses.refresh();
    final id = courses.selectedCourseId.value;
    if (id == null) return [];
    return LocalDatabase.instance.sheetsOf(id);
  }
}
