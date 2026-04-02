import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import '../../courses/data/models/course_model.dart';
import 'models/earnings_model.dart';

class EarningsRepository {
  final Dio _client = ApiClient.instance;

  Future<EarningsModel> getEarnings({String period = 'today'}) async {
    try {
      final response = await _client.get(
        ApiConstants.riderEarnings,
        queryParameters: {'period': period},
      );
      final body = response.data;
      final json = body is Map && body['data'] is Map
          ? body['data'] as Map<String, dynamic>
          : body as Map<String, dynamic>;
      return EarningsModel.fromJson(json, period: period);
    } on DioException catch (e) {
      throw ApiExceptionHandler.handle(e);
    }
  }

  Future<RiderProfileModel> getProfile() async {
    try {
      final response = await _client.get(ApiConstants.riderProfile);
      final body = response.data;
      final json = body is Map && body['data'] is Map
          ? body['data'] as Map<String, dynamic>
          : body as Map<String, dynamic>;
      return RiderProfileModel.fromJson(json);
    } on DioException catch (e) {
      throw ApiExceptionHandler.handle(e);
    }
  }
}
