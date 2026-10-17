import 'course.dart';

/// Source of units, lessons and exercises.
abstract interface class CourseRepository {
  Future<Course> fetchCourse();
}
