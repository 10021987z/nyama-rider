import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';
import 'api_exceptions.dart';

/// Global offline state
final offlineNotifier = ValueNotifier<bool>(false);

class ApiClient {
  ApiClient._();

  static Dio? _instance;

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    dio.interceptors.addAll([
      _AuthInterceptor(dio),
      _OfflineInterceptor(),
      _LogInterceptor(),
    ]);
    return dio;
  }

  static void reset() => _instance = null;
}

class _AuthInterceptor extends Interceptor {
  final Dio _dio;
  bool _isRefreshing = false;
  final List<RequestOptions> _pending = [];

  _AuthInterceptor(this._dio);

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (_isAuthRoute(options.path)) return handler.next(options);
    final token = await SecureStorage.getAccessToken();
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) return handler.next(err);
    if (_isAuthRoute(err.requestOptions.path)) return handler.next(err);

    if (_isRefreshing) {
      _pending.add(err.requestOptions);
      return;
    }
    _isRefreshing = true;
    try {
      final newToken = await _refreshToken();
      if (newToken != null) {
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        final resp = await _dio.fetch(err.requestOptions);
        for (final req in _pending) {
          req.headers['Authorization'] = 'Bearer $newToken';
          _dio.fetch(req).ignore();
        }
        _pending.clear();
        handler.resolve(resp);
      } else {
        await _logout();
        handler.next(err);
      }
    } catch (_) {
      await _logout();
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<String?> _refreshToken() async {
    final rt = await SecureStorage.getRefreshToken();
    if (rt == null) return null;
    try {
      final resp = await _dio.post(ApiConstants.refreshToken,
          data: {'refreshToken': rt}, options: Options(headers: {}));
      final at = resp.data['accessToken'] as String?;
      final nrt = resp.data['refreshToken'] as String?;
      if (at != null) {
        await SecureStorage.saveAccessToken(at);
        if (nrt != null) await SecureStorage.saveRefreshToken(nrt);
        return at;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _logout() => SecureStorage.clearAll();
  bool _isAuthRoute(String p) => p.contains('/auth/');
}

class _OfflineInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    offlineNotifier.value = false;
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      offlineNotifier.value = true;
    }
    handler.next(err);
  }
}

class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('[API] ${options.method} ${options.path}');
      return true;
    }());
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('[API] ${response.statusCode} ${response.requestOptions.path}');
      return true;
    }());
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('[API] ERROR ${err.response?.statusCode} ${err.requestOptions.path}');
      return true;
    }());
    handler.next(ApiExceptionHandler.handle(err) as DioException? ?? err);
  }
}
