import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import 'models/course_model.dart';

class CoursesRepository {
  final _client = ApiClient.instance;

  Future<List<CourseModel>> getAvailableOrders() async {
    try {
      final response = await _client.get(ApiConstants.availableOrders);
      final data = response.data;
      final List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map && data['data'] is List) {
        list = data['data'] as List<dynamic>;
      } else if (data is Map && data['orders'] is List) {
        list = data['orders'] as List<dynamic>;
      } else {
        list = [];
      }
      return list
          .map((e) => CourseModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiExceptionHandler.handle(e);
    }
  }

  Future<CourseModel> acceptOrder(String orderId) async {
    try {
      final response =
          await _client.post(ApiConstants.acceptOrder(orderId));
      final body = response.data;
      final json = body is Map && body['data'] is Map
          ? body['data'] as Map<String, dynamic>
          : body as Map<String, dynamic>;
      return CourseModel.fromJson(json);
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
