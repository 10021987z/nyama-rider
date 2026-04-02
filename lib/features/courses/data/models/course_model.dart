import 'package:intl/intl.dart';

// ─── CourseItemModel ──────────────────────────────────────────────────────────

class CourseItemModel {
  final String name;
  final int quantity;

  const CourseItemModel({required this.name, required this.quantity});

  factory CourseItemModel.fromJson(Map<String, dynamic> json) =>
      CourseItemModel(
        name: json['menuItemName'] as String? ??
            json['name'] as String? ??
            'Article',
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      );
}

// ─── CourseModel ──────────────────────────────────────────────────────────────

class CourseModel {
  final String id;
  final String cookName;
  final String? cookAddress;
  final double? cookLat;
  final double? cookLng;
  final String? cookPhone;
  final String deliveryAddress;
  final String? landmark;
  final double? deliveryLat;
  final double? deliveryLng;
  final String? clientPhone;
  final String? clientNote;
  final String? paymentMethod; // 'CASH', 'ORANGE_MONEY', 'MTN_MOMO'
  final int totalXaf;
  final int deliveryFeeXaf;
  final List<CourseItemModel> items;
  final DateTime createdAt;
  final String status;
  final int? distanceM;
  final int? estimatedMinutes;

  const CourseModel({
    required this.id,
    required this.cookName,
    this.cookAddress,
    this.cookLat,
    this.cookLng,
    this.cookPhone,
    required this.deliveryAddress,
    this.landmark,
    this.deliveryLat,
    this.deliveryLng,
    this.clientPhone,
    this.clientNote,
    this.paymentMethod,
    required this.totalXaf,
    required this.deliveryFeeXaf,
    required this.items,
    required this.createdAt,
    this.status = 'ready',
    this.distanceM,
    this.estimatedMinutes,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    final cookData = json['cook'] as Map<String, dynamic>? ??
        json['restaurant'] as Map<String, dynamic>?;
    final cookName = json['cookName'] as String? ??
        cookData?['name'] as String? ??
        'Cuisinière';
    final cookAddress = json['cookAddress'] as String? ??
        cookData?['address'] as String? ??
        cookData?['quartier'] as String?;

    final delivData = json['delivery'] as Map<String, dynamic>?;
    final deliveryAddress = json['deliveryAddress'] as String? ??
        delivData?['address'] as String? ??
        delivData?['zone'] as String? ??
        'Adresse inconnue';
    final landmark = json['landmark'] as String? ??
        delivData?['landmark'] as String?;

    final itemsList = (json['items'] as List<dynamic>? ?? [])
        .map((e) => CourseItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final cookCoords = cookData?['coordinates'] as Map<String, dynamic>?;
    final delivCoords = delivData?['coordinates'] as Map<String, dynamic>?;
    final clientData = json['client'] as Map<String, dynamic>?;

    return CourseModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      cookName: cookName,
      cookAddress: cookAddress,
      cookLat: (json['cookLat'] as num?)?.toDouble() ??
          (cookData?['lat'] as num?)?.toDouble() ??
          (cookCoords?['lat'] as num?)?.toDouble(),
      cookLng: (json['cookLng'] as num?)?.toDouble() ??
          (cookData?['lng'] as num?)?.toDouble() ??
          (cookCoords?['lng'] as num?)?.toDouble(),
      cookPhone: json['cookPhone'] as String? ??
          cookData?['phone'] as String?,
      deliveryAddress: deliveryAddress,
      landmark: landmark,
      deliveryLat: (json['deliveryLat'] as num?)?.toDouble() ??
          (delivData?['lat'] as num?)?.toDouble() ??
          (delivCoords?['lat'] as num?)?.toDouble(),
      deliveryLng: (json['deliveryLng'] as num?)?.toDouble() ??
          (delivData?['lng'] as num?)?.toDouble() ??
          (delivCoords?['lng'] as num?)?.toDouble(),
      clientPhone: json['clientPhone'] as String? ??
          clientData?['phone'] as String?,
      clientNote: json['clientNote'] as String? ??
          delivData?['note'] as String?,
      paymentMethod: json['paymentMethod'] as String?,
      totalXaf: (json['totalXaf'] as num?)?.toInt() ?? 0,
      deliveryFeeXaf: (json['deliveryFeeXaf'] as num?)?.toInt() ?? 0,
      items: itemsList,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      status: json['status'] as String? ?? 'ready',
      distanceM: (json['distanceM'] as num?)?.toInt() ??
          (json['distance'] as num?)?.toInt(),
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ??
          (json['estimatedTime'] as num?)?.toInt(),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String get shortId =>
      id.length >= 4 ? id.substring(0, 4).toUpperCase() : id.toUpperCase();

  String get distanceLabel {
    if (distanceM == null) return '—';
    if (distanceM! < 1000) return '${distanceM}m';
    return '${(distanceM! / 1000).toStringAsFixed(1)} km';
  }

  String get estimatedLabel {
    if (estimatedMinutes == null) return '—';
    return '~$estimatedMinutes min';
  }

  String get itemsLabel => '${items.length} article${items.length > 1 ? 's' : ''}';

  String get formattedDate =>
      DateFormat("d MMM 'à' HH'h'mm", 'fr').format(createdAt.toLocal());
}

// ─── RiderProfileModel ────────────────────────────────────────────────────────

class RiderProfileModel {
  final String userId;
  final String? vehicleType;
  final String? plateNumber;
  final double avgRating;
  final int totalTrips;
  final String? momoPhone;
  final String? momoProvider;
  final bool isOnline;
  final String? name;

  const RiderProfileModel({
    required this.userId,
    this.vehicleType,
    this.plateNumber,
    this.avgRating = 0,
    this.totalTrips = 0,
    this.momoPhone,
    this.momoProvider,
    this.isOnline = false,
    this.name,
  });

  factory RiderProfileModel.fromJson(Map<String, dynamic> json) {
    final riderData = json['rider'] as Map<String, dynamic>? ?? json;
    return RiderProfileModel(
      userId: (json['id'] ?? json['_id'] ?? json['userId'] ?? '').toString(),
      vehicleType: riderData['vehicleType'] as String?,
      plateNumber: riderData['plateNumber'] as String?,
      avgRating: (riderData['avgRating'] as num?)?.toDouble() ?? 0,
      totalTrips: (riderData['totalTrips'] as num?)?.toInt() ?? 0,
      momoPhone: riderData['momoPhone'] as String? ?? json['phone'] as String?,
      momoProvider: riderData['momoProvider'] as String?,
      isOnline: riderData['isOnline'] as bool? ?? false,
      name: json['name'] as String?,
    );
  }
}
