import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../courses/data/models/course_model.dart';
import '../data/earnings_repository.dart';
import '../data/models/earnings_model.dart';

// ─── Repository ───────────────────────────────────────────────────────────────

final earningsRepositoryProvider = Provider<EarningsRepository>((ref) {
  return EarningsRepository();
});

// ─── Period selector ──────────────────────────────────────────────────────────

final selectedPeriodProvider = StateProvider<String>((ref) => 'today');

// ─── Earnings by period ───────────────────────────────────────────────────────

final earningsProvider =
    FutureProvider.family<EarningsModel, String>((ref, period) async {
  final repo = ref.read(earningsRepositoryProvider);
  return repo.getEarnings(period: period);
});

// ─── Rider profile ────────────────────────────────────────────────────────────

final riderProfileProvider = FutureProvider<RiderProfileModel>((ref) async {
  final repo = ref.read(earningsRepositoryProvider);
  return repo.getProfile();
});
