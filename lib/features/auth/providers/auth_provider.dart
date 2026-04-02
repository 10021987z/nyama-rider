import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/auth_repository.dart';

enum AuthStatus {
  initial,
  loading,
  otpSent,
  verifying,
  authenticated,
  unauthenticated,
  wrongRole,
  error,
}

class AuthState {
  final AuthStatus status;
  final RiderUser? user;
  final String? phone;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.phone,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading =>
      status == AuthStatus.loading || status == AuthStatus.verifying;

  AuthState copyWith({
    AuthStatus? status,
    RiderUser? user,
    String? phone,
    String? errorMessage,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        phone: phone ?? this.phone,
        errorMessage: errorMessage,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    final loggedIn = await _repo.isLoggedIn();
    if (!mounted) return;
    if (loggedIn) {
      final phone = await SecureStorage.getUserPhone();
      final id = await SecureStorage.getUserId();
      final riderId = await SecureStorage.getRiderId();
      final user = (phone != null && id != null)
          ? RiderUser(id: id, phone: phone, riderId: riderId)
          : null;
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> requestOtp(String phone) async {
    state = AuthState(status: AuthStatus.loading, phone: phone);
    try {
      await _repo.requestOtp(phone);
      if (!mounted) return;
      state = AuthState(status: AuthStatus.otpSent, phone: phone);
    } catch (e) {
      if (!mounted) return;
      state = AuthState(
          status: AuthStatus.error,
          phone: phone,
          errorMessage: _parse(e));
    }
  }

  Future<void> verifyOtp(String phone, String code) async {
    state = AuthState(status: AuthStatus.verifying, phone: phone);
    try {
      final result = await _repo.verifyOtp(phone, code);
      if (!mounted) return;
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.user ?? RiderUser(id: '', phone: phone),
        phone: phone,
      );
    } on NotRiderException catch (e) {
      if (!mounted) return;
      await _repo.logout();
      if (!mounted) return;
      state = AuthState(
          status: AuthStatus.wrongRole,
          phone: phone,
          errorMessage: e.toString());
    } catch (e) {
      if (!mounted) return;
      state = AuthState(
          status: AuthStatus.error,
          phone: phone,
          errorMessage: _parse(e));
    }
  }

  Future<void> resendOtp() async {
    final phone = state.phone;
    if (phone != null) await requestOtp(phone);
  }

  Future<void> logout() async {
    await _repo.logout();
    if (!mounted) return;
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  String _parse(Object e) {
    final msg = e.toString();
    if (msg.contains(':')) return msg.split(':').skip(1).join(':').trim();
    return msg;
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});
