import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/socket_provider.dart';
import '../../courses/data/models/course_model.dart';
import '../data/navigation_repository.dart';

// ─── Repository provider ──────────────────────────────────────────────────────

final navigationRepositoryProvider = Provider<NavigationRepository>((ref) {
  final socket = ref.read(socketServiceProvider);
  return NavigationRepository(socket);
});

// ─── Delivery step ────────────────────────────────────────────────────────────

enum DeliveryStep {
  arrivingRestaurant,
  atRestaurant,
  deliveringToClient,
  atClient,
}

// ─── Active delivery state ────────────────────────────────────────────────────

class ActiveDeliveryState {
  final String orderId;
  final CourseModel? course;
  final DeliveryStep step;

  const ActiveDeliveryState({
    required this.orderId,
    this.course,
    this.step = DeliveryStep.arrivingRestaurant,
  });

  ActiveDeliveryState copyWith({
    String? orderId,
    CourseModel? course,
    DeliveryStep? step,
  }) =>
      ActiveDeliveryState(
        orderId: orderId ?? this.orderId,
        course: course ?? this.course,
        step: step ?? this.step,
      );
}

// ─── Active delivery notifier ─────────────────────────────────────────────────

class ActiveDeliveryNotifier extends StateNotifier<ActiveDeliveryState?> {
  ActiveDeliveryNotifier() : super(null);

  void startDelivery(String orderId, CourseModel course) {
    state = ActiveDeliveryState(orderId: orderId, course: course);
  }

  void advanceStep() {
    if (state == null) return;
    final steps = DeliveryStep.values;
    final currentIndex = steps.indexOf(state!.step);
    if (currentIndex < steps.length - 1) {
      state = state!.copyWith(step: steps[currentIndex + 1]);
    }
  }

  void clear() => state = null;
}

final activeDeliveryProvider =
    StateNotifierProvider<ActiveDeliveryNotifier, ActiveDeliveryState?>(
  (ref) => ActiveDeliveryNotifier(),
);
