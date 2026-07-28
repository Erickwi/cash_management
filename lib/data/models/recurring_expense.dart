class RecurringExpense {
  final String id;
  final String roomId;
  final String categoryId;
  final double amount;
  final String description;
  final int preferredDay;
  final bool isActive;
  final DateTime createdAt;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;

  RecurringExpense({
    required this.id,
    required this.roomId,
    required this.categoryId,
    required this.amount,
    required this.description,
    required this.preferredDay,
    this.isActive = true,
    required this.createdAt,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
  });

  factory RecurringExpense.fromJson(Map<String, dynamic> json) => RecurringExpense(
    id: json['id']?.toString() ?? '',
    roomId: json['room_id']?.toString() ?? '',
    categoryId: json['category_id']?.toString() ?? '',
    amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0.0,
    description: json['description']?.toString() ?? '',
    preferredDay: json['preferred_day'] ?? 1,
    isActive: json['is_active'] ?? true,
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
    categoryName: json['category_name']?.toString(),
    categoryIcon: json['category_icon']?.toString(),
    categoryColor: json['category_color']?.toString(),
  );
}
