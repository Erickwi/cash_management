import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/room.dart';
import 'room_provider.dart';
import 'socket_provider.dart';

class DeviceStatus {
  final String deviceId;
  final String alias;
  final bool isOnline;

  DeviceStatus({
    required this.deviceId,
    required this.alias,
    this.isOnline = false,
  });
}

class DeviceStatusState {
  final List<DeviceStatus> devices;

  DeviceStatusState({this.devices = const []});

  DeviceStatusState copyWith({List<DeviceStatus>? devices}) {
    return DeviceStatusState(devices: devices ?? this.devices);
  }
}

class DeviceStatusNotifier extends Notifier<DeviceStatusState> {
  @override
  DeviceStatusState build() {
    ref.listen<RoomState>(roomProvider, (prev, next) {
      if (next.isConnected && prev?.isConnected != true) {
        _initSocketListeners();
      } else if (!next.isConnected) {
        _clearDevices();
      }
    });

    ref.onDispose(() => _clearDevices());
    return DeviceStatusState();
  }

  void _initSocketListeners() {
    final socketNotifier = ref.read(socketProvider.notifier);
    socketNotifier.connect();

    socketNotifier.on('room-devices', (data) {
      if (data is List) {
        final devices = data.map((d) => DeviceStatus(
          deviceId: d['device_id']?.toString() ?? d['id']?.toString() ?? '',
          alias: d['alias']?.toString() ?? '',
          isOnline: d['is_online'] ?? d['online'] ?? false,
        )).toList();
        state = state.copyWith(devices: devices);
      }
    });

    socketNotifier.on('device-online', (data) {
      final deviceId = data['device_id']?.toString() ?? data['id']?.toString();
      if (deviceId == null) return;

      final currentDevices = List<DeviceStatus>.from(state.devices);
      final index = currentDevices.indexWhere((d) => d.deviceId == deviceId);
      if (index >= 0) {
        currentDevices[index] = DeviceStatus(
          deviceId: currentDevices[index].deviceId,
          alias: currentDevices[index].alias,
          isOnline: true,
        );
      } else {
        currentDevices.add(DeviceStatus(
          deviceId: deviceId,
          alias: data['alias']?.toString() ?? '',
          isOnline: true,
        ));
      }
      state = state.copyWith(devices: currentDevices);
    });

    socketNotifier.on('device-offline', (data) {
      final deviceId = data['device_id']?.toString() ?? data['id']?.toString();
      if (deviceId == null) return;

      final currentDevices = List<DeviceStatus>.from(state.devices);
      final index = currentDevices.indexWhere((d) => d.deviceId == deviceId);
      if (index >= 0) {
        currentDevices[index] = DeviceStatus(
          deviceId: currentDevices[index].deviceId,
          alias: currentDevices[index].alias,
          isOnline: false,
        );
        state = state.copyWith(devices: currentDevices);
      }
    });
  }

  void _clearDevices() {
    final socketNotifier = ref.read(socketProvider.notifier);
    socketNotifier.off('room-devices');
    socketNotifier.off('device-online');
    socketNotifier.off('device-offline');
    socketNotifier.disconnect();
    state = DeviceStatusState();
  }
}

final deviceStatusProvider = NotifierProvider<DeviceStatusNotifier, DeviceStatusState>(DeviceStatusNotifier.new);
