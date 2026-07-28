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
    id: json['id'],
    roomId: json['room_id'],
    name: json['name'],
    type: json['type'],
    icon: json['icon'] ?? 'category',
    color: json['color'] ?? '#78909C',
    isPreset: json['is_preset'] ?? false,
  );
}
