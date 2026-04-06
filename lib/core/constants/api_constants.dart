class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://nyama-api-production.up.railway.app/api/v1';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 15);

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String requestOtp = '/auth/otp/request';
  static const String verifyOtp = '/auth/otp/verify';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';

  // ── Rider courses ─────────────────────────────────────────────────────────
  static const String availableOrders = '/rider/available-orders';
  static String acceptOrder(String id) => '/rider/orders/$id/accept';
  static String rejectOrder(String id) => '/rider/orders/$id/reject';
  static String deliveryStatus(String id) => '/rider/deliveries/$id/status';
  static String orderById(String id) => '/rider/orders/$id';

  // ── Rider location ────────────────────────────────────────────────────────
  static const String riderLocation = '/rider/location';

  // ── Rider earnings ────────────────────────────────────────────────────────
  static const String riderEarnings = '/rider/earnings';
  static const String riderEarningsHistory = '/rider/earnings/history';

  // ── Rider profile ─────────────────────────────────────────────────────────
  static const String riderProfile = '/rider/profile';

  // ── WebSocket ─────────────────────────────────────────────────────────────
  static const String wsUrl = 'https://nyama-api-production.up.railway.app';

  // ── Storage keys ──────────────────────────────────────────────────────────
  static const String accessTokenKey = 'rider_access_token';
  static const String refreshTokenKey = 'rider_refresh_token';
  static const String userPhoneKey = 'rider_phone';
  static const String userIdKey = 'rider_user_id';
  static const String riderIdKey = 'rider_id';
}
