import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exceptions.dart';
import '../../../core/network/socket_service.dart';

class NavigationRepository {
  final Dio _client = ApiClient.instance;
  final SocketService _socket;

  NavigationRepository(this._socket);

  /// PATCH /rider/deliveries/:id/status
  Future<void> updateDeliveryStatus(String deliveryId, String status) async {
    try {
      await _client.patch(
        ApiConstants.deliveryStatus(deliveryId),
        data: {'status': status},
      );
    } on DioException catch (e) {
      throw ApiExceptionHandler.handle(e);
    }
  }

  /// Émet la position GPS du livreur via socket
  void emitLocation({
    required double lat,
    required double lng,
    double? heading,
    double? speed,
  }) {
    final data = <String, dynamic>{'lat': lat, 'lng': lng};
    if (heading != null) data['heading'] = heading;
    if (speed != null) data['speed'] = speed;
    _socket.emit('rider:location', data);
  }
}
