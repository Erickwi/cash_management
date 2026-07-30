import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/socket_client.dart';
import 'api_provider.dart';

class SocketState {
  final bool isConnected;
  final String? error;

  SocketState({this.isConnected = false, this.error});
}

class SocketNotifier extends Notifier<SocketState> {
  SocketClient? _client;

  SocketClient? get client => _client;

  @override
  SocketState build() {
    ref.onDispose(() => disconnect());
    return SocketState();
  }

  Future<void> connect() async {
    if (_client != null) return;

    _client = SocketClient();
    try {
      final api = ref.read(apiClientProvider);
      final serverUrl = await api.getBaseUrl();
      await _client!.connect(serverUrl);
      state = SocketState(isConnected: true);
    } catch (e) {
      state = SocketState(error: e.toString());
    }
  }

  void disconnect() {
    _client?.disconnect();
    _client = null;
    state = SocketState();
  }

  void on(String event, dynamic Function(dynamic) handler) {
    _client?.on(event, handler);
  }

  void off(String event) {
    _client?.off(event);
  }

  void emit(String event, dynamic data) {
    _client?.socket?.emit(event, data);
  }
}

final socketProvider = NotifierProvider<SocketNotifier, SocketState>(SocketNotifier.new);
