import 'package:intl/intl.dart';

// ─── EarningEntry ──────────────────────────────────────────────────────────────

class EarningEntry {
  final int netXaf;
  final DateTime deliveredAt;

  const EarningEntry({required this.netXaf, required this.deliveredAt});

  String get timeLabel =>
      DateFormat("HH'h'mm").format(deliveredAt.toLocal());

  factory EarningEntry.fromJson(Map<String, dynamic> json) {
    final dt = json['deliveredAt'] as String? ?? json['createdAt'] as String?;
    return EarningEntry(
      netXaf: (json['netXaf'] ?? json['net'] ?? json['amount'] as num?)
              ?.toInt() ??
          0,
      deliveredAt:
          dt != null ? DateTime.tryParse(dt) ?? DateTime.now() : DateTime.now(),
    );
  }
}

// ─── EarningsModel ────────────────────────────────────────────────────────────

class EarningsModel {
  final int total;
  final int count;
  final int avgPerDelivery;
  final String period;
  final List<EarningEntry> breakdown;

  const EarningsModel({
    required this.total,
    required this.count,
    required this.avgPerDelivery,
    required this.period,
    required this.breakdown,
  });

  factory EarningsModel.fromJson(
    Map<String, dynamic> json, {
    String period = 'today',
  }) {
    final total = (json['total'] as num?)?.toInt() ?? 0;
    final count = (json['count'] as num?)?.toInt() ?? 0;
    final avg = count > 0 ? total ~/ count : 0;

    final rawBreakdown = json['breakdown'] as List<dynamic>? ?? [];
    final breakdown = rawBreakdown
        .map((e) => EarningEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    return EarningsModel(
      total: total,
      count: count,
      avgPerDelivery:
          (json['avgPerDelivery'] as num?)?.toInt() ?? avg,
      period: period,
      breakdown: breakdown,
    );
  }
}
