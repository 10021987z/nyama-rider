import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  const NetworkException() : super('Pas de connexion. Vérifiez votre réseau.');
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException() : super('Session expirée. Reconnectez-vous.', statusCode: 401);
}

class ApiExceptionHandler {
  static ApiException handle(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const NetworkException();
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 401) return const UnauthorizedException();
        final data = e.response?.data;
        String msg = 'Erreur serveur ($code)';
        if (data is Map) {
          msg = (data['message'] ?? data['error'] ?? msg).toString();
        }
        return ApiException(msg, statusCode: code);
      default:
        return ApiException(e.message ?? 'Erreur inconnue');
    }
  }
}
