import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/room.dart';
import 'api_provider.dart';

class RoomState {
  final bool isConnected;
  final Room? room;
  final Device? device;
  final bool isLoading;
  final String? error;

  RoomState({
    this.isConnected = false,
    this.room,
    this.device,
    this.isLoading = false,
    this.error,
  });

  RoomState copyWith({
    bool? isConnected,
    Room? room,
    Device? device,
    bool? isLoading,
    String? error,
  }) => RoomState(
    isConnected: isConnected ?? this.isConnected,
    room: room ?? this.room,
    device: device ?? this.device,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

class RoomNotifier extends Notifier<RoomState> {
  @override
  RoomState build() {
    _loadStoredRoom();
    return RoomState();
  }

  Future<void> _loadStoredRoom() async {
    final prefs = await SharedPreferences.getInstance();
    final roomCode = prefs.getString('room_code');
    final deviceId = prefs.getString('device_id');
    final alias = prefs.getString('alias');

    if (roomCode != null && deviceId != null) {
      state = state.copyWith(
        isConnected: true,
        room: Room(id: '', code: roomCode, createdAt: DateTime.now()),
        device: Device(id: deviceId, alias: alias ?? '', createdAt: DateTime.now()),
      );
    }
  }

  Future<void> createRoom(String alias) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.createRoom(alias);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('room_code', result.room.code);
      await prefs.setString('device_id', result.device.id);
      await prefs.setString('alias', alias);

      state = state.copyWith(
        isConnected: true,
        room: result.room,
        device: result.device,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> joinRoom(String code, String alias) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = ref.read(apiServiceProvider);
      final result = await api.joinRoom(code, alias);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('room_code', result.room.code);
      await prefs.setString('device_id', result.device.id);
      await prefs.setString('alias', alias);

      state = state.copyWith(
        isConnected: true,
        room: result.room,
        device: result.device,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> disconnect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('room_code');
    await prefs.remove('device_id');
    await prefs.remove('alias');

    state = RoomState();
  }
}

final roomProvider = NotifierProvider<RoomNotifier, RoomState>(RoomNotifier.new);
