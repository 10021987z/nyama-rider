import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/storage/secure_storage.dart';

/// Service de gestion des alertes d'urgence.
///
/// Principe : on tente d'envoyer immédiatement (SMS + appel) et on stocke
/// systématiquement l'alerte localement (journal + queue de secours au cas où
/// le lancement de l'intent aurait échoué).
class SosService {
  SosService._();
  static final SosService instance = SosService._();

  static const String emergencyNumber = '+237699000000';
  static const String riderName = 'Kevin';
  static const String _storageKey = 'sos_alerts';

  /// Utiles camerounais
  static const utilNumbers = <String, String>{
    'Police': '117',
    'Pompiers': '118',
    'SAMU': '119',
  };

  Future<Position?> _safePosition() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        final req = await Geolocator.requestPermission();
        if (req == LocationPermission.denied ||
            req == LocationPermission.deniedForever) {
          return null;
        }
      }
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 6));
    } catch (e) {
      debugPrint('[SOS] position error: $e');
      return null;
    }
  }

  /// Déclenche l'alerte complète : position, SMS, appel, stockage.
  Future<SosAlert> trigger() async {
    final pos = await _safePosition();
    final alert = SosAlert(
      timestamp: DateTime.now(),
      latitude: pos?.latitude,
      longitude: pos?.longitude,
    );

    await _store(alert);

    final gps = pos != null
        ? '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}'
        : 'indisponible';
    final message =
        'URGENCE NYAMA — Livreur $riderName en danger. Position GPS : $gps. Heure : ${alert.timestamp.toIso8601String()}';

    // SMS d'abord (non bloquant si KO)
    try {
      final smsUri = Uri(
        scheme: 'sms',
        path: emergencyNumber,
        queryParameters: {'body': message},
      );
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      }
    } catch (e) {
      debugPrint('[SOS] sms error: $e');
    }

    // Appel automatique ensuite
    try {
      final telUri = Uri.parse('tel:$emergencyNumber');
      if (await canLaunchUrl(telUri)) {
        await launchUrl(telUri);
      }
    } catch (e) {
      debugPrint('[SOS] call error: $e');
    }

    return alert;
  }

  Future<void> _store(SosAlert alert) async {
    try {
      final raw = await SecureStorage.readRaw(_storageKey);
      final list = raw == null
          ? <Map<String, dynamic>>[]
          : (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      list.add(alert.toJson());
      await SecureStorage.writeRaw(_storageKey, jsonEncode(list));
    } catch (e) {
      debugPrint('[SOS] store error: $e');
    }
  }

  Future<List<SosAlert>> history() async {
    try {
      final raw = await SecureStorage.readRaw(_storageKey);
      if (raw == null) return [];
      return (jsonDecode(raw) as List)
          .cast<Map<String, dynamic>>()
          .map(SosAlert.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }
}

class SosAlert {
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;

  SosAlert({
    required this.timestamp,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() => {
        'ts': timestamp.toIso8601String(),
        'lat': latitude,
        'lng': longitude,
      };

  factory SosAlert.fromJson(Map<String, dynamic> j) => SosAlert(
        timestamp: DateTime.parse(j['ts'] as String),
        latitude: (j['lat'] as num?)?.toDouble(),
        longitude: (j['lng'] as num?)?.toDouble(),
      );
}
