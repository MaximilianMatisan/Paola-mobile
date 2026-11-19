// A course the user is a member of, as /api/course/myCourses of the web app
// returns it: the course table plus the user's role and join date from
// course_membership (see init-db.sql of the web app). The local database
// reads it the same way (LocalDatabase.courses).

enum CourseRole { student, tutor, prof, forsch }

class Course {
  final int id;
  final int? ownerId;
  final String title;
  final String description;
  final CourseRole role;

  /// When the user joined the course; the fallback selection is the course
  /// joined first, like the web app's CourseContext.
  final DateTime? joinedAt;

  const Course({
    required this.id,
    this.ownerId,
    required this.title,
    this.description = '',
    this.role = CourseRole.student,
    this.joinedAt,
  });

  static CourseRole _role(Object? value) =>
      CourseRole.values.asNameMap()['${value ?? ''}'] ?? CourseRole.student;

  factory Course.fromJson(Map<String, dynamic> json) => Course(
    id: (json['id'] as num).toInt(),
    ownerId: (json['owner_id'] as num?)?.toInt(),
    title: '${json['title'] ?? ''}',
    description: '${json['description'] ?? ''}',
    role: _role(json['role']),
    joinedAt: DateTime.tryParse('${json['joined_at'] ?? ''}'),
  );

  factory Course.fromRow(Map<String, Object?> row) => Course.fromJson(row);
}
