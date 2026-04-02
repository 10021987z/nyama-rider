import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/courses_repository.dart';
import '../data/models/course_model.dart';

// ─── Repository provider ──────────────────────────────────────────────────────

final coursesRepositoryProvider = Provider<CoursesRepository>((ref) {
  return CoursesRepository();
});

// ─── Active course ────────────────────────────────────────────────────────────

final activeCourseProvider = StateProvider<CourseModel?>((ref) => null);

// ─── Available courses notifier ───────────────────────────────────────────────

class CoursesNotifier extends StateNotifier<List<CourseModel>> {
  final CoursesRepository _repo;
  Timer? _refreshTimer;

  CoursesNotifier(this._repo) : super([]) {
    refresh();
    // Auto-refresh every 30 seconds — offline-first, pas de dépendance data
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => refresh());
  }

  Future<void> refresh() async {
    try {
      final courses = await _repo.getAvailableOrders();
      if (!mounted) return;
      state = courses;
    } catch (_) {
      // Silently ignore — garde l'ancienne liste en cas d'erreur réseau
    }
  }

  Future<CourseModel> accept(String courseId) async {
    final course = await _repo.acceptOrder(courseId);
    if (!mounted) return course;
    // Retire la course acceptée de la liste disponible
    state = state.where((c) => c.id != courseId).toList();
    return course;
  }

  /// Socket: nouvelle course disponible — ajout en tête
  void addCourse(CourseModel course) {
    if (!mounted) return;
    final exists = state.any((c) => c.id == course.id);
    if (exists) return;
    state = [course, ...state];
  }

  /// Ignorer une course (dismiss sans API call)
  void dismissCourse(String courseId) {
    if (!mounted) return;
    state = state.where((c) => c.id != courseId).toList();
  }

  /// Socket: mise à jour statut d'une course
  void updateCourseStatus(String courseId, String status) {
    if (!mounted) return;
    // Si la course n'est plus disponible (prise par un autre), la retirer
    if (status == 'cancelled' || status == 'delivering' || status == 'delivered') {
      state = state.where((c) => c.id != courseId).toList();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

final availableCoursesProvider =
    StateNotifierProvider<CoursesNotifier, List<CourseModel>>(
  (ref) => CoursesNotifier(ref.read(coursesRepositoryProvider)),
);
