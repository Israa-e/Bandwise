import '../domain/course.dart';
import '../domain/course_repository.dart';
import 'course_content.dart';

/// Serves the bundled [course].
class MockCourseRepository implements CourseRepository {
  const MockCourseRepository();

  @override
  Future<Course> fetchCourse() async => course;
}
