class Room {
  final String id;
  final String code;
  final DateTime createdAt;
  final List<Device>? devices;

  Room({
    required this.id,
    required this.code,
    required this.createdAt,
    this.devices,
  });

  factory Room.fromJson(Map<String, dynamic> json) => Room(
    id: json['id'],
    code: json['code'],
    createdAt: DateTime.parse(json['created_at']),
    devices: json['devices'] != null
        ? (json['devices'] as List).map((d) => Device.fromJson(d)).toList()
        : null,
  );
}

class Device {
  final String id;
  final String alias;
  final DateTime createdAt;

  Device({required this.id, required this.alias, required this.createdAt});

  factory Device.fromJson(Map<String, dynamic> json) => Device(
    id: json['id'],
    alias: json['alias'],
    createdAt: DateTime.parse(json['created_at']),
  );
}

class RoomJoinResponse {
  final Room room;
  final Device device;

  RoomJoinResponse({required this.room, required this.device});

  factory RoomJoinResponse.fromJson(Map<String, dynamic> json) => RoomJoinResponse(
    room: Room.fromJson(json['room']),
    device: Device.fromJson(json['device']),
  );
}
