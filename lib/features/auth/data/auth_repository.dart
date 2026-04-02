import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/storage/secure_storage.dart';

// ─── Exception rôle ───────────────────────────────────────────────────────────

class NotRiderException implements Exception {
  const NotRiderException();
  @override
  String toString() =>
      'Ce numéro n\'est pas associé à un compte livreur. Contactez NYAMA.';
}

// ─── Modèles ──────────────────────────────────────────────────────────────────

class RiderUser {
  final String id;
  final String phone;
  final String? name;
  final String? riderId;
  final String? role;
  final String? vehicleType;

  const RiderUser({
    required this.id,
    required this.phone,
    this.name,
    this.riderId,
    this.role,
    this.vehicleType,
  });

  factory RiderUser.fromJson(Map<String, dynamic> json) => RiderUser(
        id: (json['id'] ?? json['_id'] ?? '').toString(),
        phone: (json['phone'] ?? '').toString(),
        name: json['name'] as String?,
        riderId: (json['riderId'] ?? json['rider']?['id'])?.toString(),
        role: json['role'] as String?,
        vehicleType: json['vehicleType'] as String? ??
            json['rider']?['vehicleType'] as String?,
      );

  bool get isRider {
    final r = role?.toUpperCase();
    return r == 'RIDER' || r == 'LIVREUR' || riderId != null;
  }
}

class AuthResult {
  final String accessToken;
  final String refreshToken;
  final RiderUser? user;

  const AuthResult({
    required this.accessToken,
    required this.refreshToken,
    this.user,
  });
}

// ─── Repository ───────────────────────────────────────────────────────────────

class AuthRepository {
  final _client = ApiClient.instance;

  Future<void> requestOtp(String phone) async {
    try {
      await _client.post(ApiConstants.requestOtp, data: {'phone': phone});
    } on DioException catch (e) {
      throw ApiExceptionHandler.handle(e);
    }
  }

  Future<AuthResult> verifyOtp(String phone, String code) async {
    try {
      final response = await _client.post(
        ApiConstants.verifyOtp,
        data: {'phone': phone, 'code': code},
      );
      final data = response.data as Map<String, dynamic>;
      final at = data['accessToken'] as String;
      final rt = data['refreshToken'] as String;
      final userJson = data['user'] as Map<String, dynamic>?;
      final user = userJson != null ? RiderUser.fromJson(userJson) : null;

      if (user != null && !user.isRider) throw const NotRiderException();

      await SecureStorage.saveAccessToken(at);
      await SecureStorage.saveRefreshToken(rt);
      if (user != null) {
        await SecureStorage.saveUserPhone(user.phone);
        await SecureStorage.saveUserId(user.id);
        if (user.riderId != null) await SecureStorage.saveRiderId(user.riderId!);
      }
      return AuthResult(accessToken: at, refreshToken: rt, user: user);
    } on NotRiderException {
      rethrow;
    } on DioException catch (e) {
      throw ApiExceptionHandler.handle(e);
    }
  }

  Future<void> logout() async {
    try {
      await _client.post(ApiConstants.logout);
    } catch (_) {}
    await SecureStorage.clearAll();
  }

  Future<bool> isLoggedIn() => SecureStorage.isLoggedIn();
}
