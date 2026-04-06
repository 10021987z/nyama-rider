import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/fcfa_formatter.dart';
import '../../core/utils/sound_service.dart';
import '../../features/courses/data/models/course_model.dart';
import '../../features/courses/providers/courses_provider.dart';
import 'swipe_button.dart';

/// Carte course — persona Kevin
/// GAIN en premier, zones larges, SwipeButton anti-erreur
class CourseCard extends ConsumerStatefulWidget {
  final CourseModel course;
  /// Appelé après acceptation réussie pour naviguer vers la course
  final void Function(CourseModel course) onAccepted;

  const CourseCard({
    super.key,
    required this.course,
    required this.onAccepted,
  });

  @override
  ConsumerState<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends ConsumerState<CourseCard> {
  bool _isAccepting = false;
  int _swipeResetKey = 0; // Incrémenté pour forcer reset du SwipeButton

  Future<void> _accept() async {
    if (_isAccepting) return;
    setState(() => _isAccepting = true);

    final messenger = ScaffoldMessenger.of(context);

    try {
      final accepted = await ref
          .read(availableCoursesProvider.notifier)
          .accept(widget.course.id);

      if (!mounted) return;

      // Vibration + son
      await SoundService.vibrateSuccess();

      // Définir la course active
      ref.read(activeCourseProvider.notifier).state = accepted;

      // SnackBar succès
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Course acceptée ! 🎉',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );

      // Callback parent → navigation
      widget.onAccepted(accepted);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAccepting = false;
        _swipeResetKey++; // Reset le SwipeButton
      });

      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Cette course n\'est plus disponible',
            style: TextStyle(fontSize: 15),
          ),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 3),
        ),
      );

      // Rafraîchir la liste
      ref.read(availableCoursesProvider.notifier).refresh();
    }
  }

  void _dismiss() {
    ref
        .read(availableCoursesProvider.notifier)
        .dismissCourse(widget.course.id);
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;

    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. GAIN — ce que Kevin regarde en premier ──────────
                Text(
                  course.deliveryFeeXaf.toFcfa(),
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 10),

                // ── 2. Distance + durée ────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.navBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '🏍️ ${course.distanceLabel}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '⏱️ ${course.estimatedLabel}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── 3. Cuisinière ──────────────────────────────────────
                Row(
                  children: [
                    const Text('🍽️', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        course.cookAddress != null
                            ? '${course.cookName} — ${course.cookAddress}'
                            : course.cookName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // ── 4. Destination ─────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📍', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        course.landmark != null
                            ? '${course.deliveryAddress}, ${course.landmark}'
                            : course.deliveryAddress,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // ── 5. Articles ────────────────────────────────────────
                Row(
                  children: [
                    const Text('📦', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      course.itemsLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(thickness: 1),
                const SizedBox(height: 10),

                // ── 6. SwipeButton ─────────────────────────────────────
                _isAccepting
                    ? Container(
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : SwipeButton(
                        key: ValueKey(_swipeResetKey),
                        label: 'Glissez pour accepter →',
                        color: AppColors.primary,
                        onConfirmed: _accept,
                      ),
              ],
            ),

            // ── ✖ Dismiss button — top-right ───────────────────────────
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: _dismiss,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.divider),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '✕',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
