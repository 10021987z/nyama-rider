import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

class SecureStorage {
  SecureStorage._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> saveAccessToken(String t) =>
      _storage.write(key: ApiConstants.accessTokenKey, value: t);
  static Future<String?> getAccessToken() =>
      _storage.read(key: ApiConstants.accessTokenKey);

  static Future<void> saveRefreshToken(String t) =>
      _storage.write(key: ApiConstants.refreshTokenKey, value: t);
  static Future<String?> getRefreshToken() =>
      _storage.read(key: ApiConstants.refreshTokenKey);

  static Future<void> saveUserPhone(String p) =>
      _storage.write(key: ApiConstants.userPhoneKey, value: p);
  static Future<String?> getUserPhone() =>
      _storage.read(key: ApiConstants.userPhoneKey);

  static Future<void> saveUserId(String id) =>
      _storage.write(key: ApiConstants.userIdKey, value: id);
  static Future<String?> getUserId() =>
      _storage.read(key: ApiConstants.userIdKey);

  static Future<void> saveRiderId(String id) =>
      _storage.write(key: ApiConstants.riderIdKey, value: id);
  static Future<String?> getRiderId() =>
      _storage.read(key: ApiConstants.riderIdKey);

  static Future<bool> isLoggedIn() async {
    final t = await getAccessToken();
    return t != null && t.isNotEmpty;
  }

  static Future<void> clearAll() => _storage.deleteAll();
}
