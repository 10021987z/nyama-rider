import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/api_constants.dart';

class SocketService {
  io.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  void connect(String token) {
    if (_socket?.connected == true) return;
    _socket = io.io(
      ApiConstants.wsUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );
    _socket!.connect();
    _socket!.onConnect((_) {
      assert(() {
        // ignore: avoid_print
        print('[Socket] Connected');
        return true;
      }());
    });
    _socket!.onDisconnect((_) {
      assert(() {
        // ignore: avoid_print
        print('[Socket] Disconnected');
        return true;
      }());
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void on(String event, void Function(dynamic) callback) =>
      _socket?.on(event, callback);

  void off(String event) => _socket?.off(event);

  void emit(String event, dynamic data) => _socket?.emit(event, data);
}
