import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/socket_provider.dart';
import '../../../core/utils/fcfa_formatter.dart';
import '../../../core/utils/sound_service.dart';
import '../../../shared/widgets/course_card.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../data/models/course_model.dart';
import '../providers/courses_provider.dart';

class CoursesScreen extends ConsumerStatefulWidget {
  const CoursesScreen({super.key});

  @override
  ConsumerState<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends ConsumerState<CoursesScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupSocket());
  }

  void _setupSocket() {
    final socket = ref.read(socketServiceProvider);
    socket.on('order:ready', _onNewCourse);
    socket.on('order:status', _onOrderStatus);
  }

  void _onNewCourse(dynamic data) async {
    if (!mounted || data is! Map) return;
    try {
      final course =
          CourseModel.fromJson(Map<String, dynamic>.from(data));
      ref.read(availableCoursesProvider.notifier).addCourse(course);
      // Son perçant + vibration forte — Kevin est sur sa moto
      await SoundService.playNewCourseAlert();
    } catch (_) {}
  }

  void _onOrderStatus(dynamic data) {
    if (!mounted || data is! Map) return;
    final orderId = data['orderId'] as String?;
    final status = data['status'] as String?;
    if (orderId != null && status != null) {
      ref
          .read(availableCoursesProvider.notifier)
          .updateCourseStatus(orderId, status);
    }
  }

  @override
  void dispose() {
    try {
      final socket = ref.read(socketServiceProvider);
      socket.off('order:ready');
      socket.off('order:status');
    } catch (_) {}
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    await ref.read(availableCoursesProvider.notifier).refresh();
    if (mounted) setState(() => _isLoading = false);
  }

  void _onCourseAccepted(CourseModel course) {
    context.push('/navigation/${course.id}', extra: course);
  }

  @override
  Widget build(BuildContext context) {
    final courses = ref.watch(availableCoursesProvider);
    final activeCourse = ref.watch(activeCourseProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Bandeau supérieur ──────────────────────────────────────
            _TopBanner(activeCourse: activeCourse),

            // ── Course en cours → bannière persistante ─────────────────
            if (activeCourse != null)
              _ActiveCourseBanner(
                course: activeCourse,
                onTap: () =>
                    context.push('/navigation/${activeCourse.id}'),
              ),

            // ── Corps ─────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? _buildShimmer()
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _refresh,
                      child: courses.isEmpty
                          ? _buildEmpty()
                          : _buildList(courses),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: 500,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🏍️', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text(
                'Pas de course disponible',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Les commandes arrivent bientôt...',
                style: TextStyle(
                    fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: SizedBox(
                  height: 72,
                  child: ElevatedButton(
                    onPressed: _refresh,
                    child: const Text(
                      '🔄  Rafraîchir',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── List ───────────────────────────────────────────────────────────────────

  Widget _buildList(List<CourseModel> courses) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: courses.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, i) => CourseCard(
        key: ValueKey(courses[i].id),
        course: courses[i],
        onAccepted: _onCourseAccepted,
      ),
    );
  }

  // ── Shimmer ────────────────────────────────────────────────────────────────

  Widget _buildShimmer() {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        CourseCardShimmer(),
        SizedBox(height: 14),
        CourseCardShimmer(),
      ],
    );
  }
}

// ── Top banner ────────────────────────────────────────────────────────────────

class _TopBanner extends StatelessWidget {
  final CourseModel? activeCourse;
  const _TopBanner({this.activeCourse});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary, // Nyama Orange
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Text('🏍️',
              style: TextStyle(fontSize: 24, color: Colors.white)),
          const SizedBox(width: 10),
          const Text(
            'NYAMA Rider',
            style: TextStyle(
              fontFamily: 'Montserrat',
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'En ligne 🟢',
              style: TextStyle(
                  fontFamily: 'NunitoSans',
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Active course banner ──────────────────────────────────────────────────────

class _ActiveCourseBanner extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onTap;

  const _ActiveCourseBanner(
      {required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        color: AppColors.navBlue,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Text('📦', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Course en cours — ${course.deliveryAddress}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

// ─── UNUSED IMPORT PREVENTION — fcfa_formatter ───────────────────────────────
// ignore: unused_element
String _unused(int v) => v.toFcfa();
