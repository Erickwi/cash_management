class Category {
  final String id;
  final String roomId;
  final String name;
  final String type;
  final String icon;
  final String color;
  final bool isPreset;

  Category({
    required this.id,
    required this.roomId,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    required this.isPreset,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id']?.toString() ?? '',
    roomId: json['room_id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    type: json['type']?.toString() ?? '',
    icon: json['icon']?.toString() ?? 'category',
    color: json['color']?.toString() ?? '#78909C',
    isPreset: json['is_preset'] ?? false,
  );
}
