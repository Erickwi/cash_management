import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import 'package:shared_preferences/shared_preferences.dart';

class SocketClient {
  socket_io.Socket? _socket;

  socket_io.Socket? get socket => _socket;

  Future<void> connect(String serverUrl) async {
    _socket = socket_io.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.connect();

    final prefs = await SharedPreferences.getInstance();
    final roomCode = prefs.getString('room_code');
    if (roomCode != null) {
      _socket!.emit('join-room', roomCode);
    }

    _socket!.onConnect((_) {
      if (roomCode != null) {
        _socket!.emit('join-room', roomCode);
      }
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void on(String event, dynamic Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  void off(String event) {
    _socket?.off(event);
  }
}
