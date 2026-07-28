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
    id: json['id'],
    roomId: json['room_id'],
    categoryId: json['category_id'],
    amount: double.parse(json['amount'].toString()),
    description: json['description'] ?? '',
    preferredDay: json['preferred_day'] ?? 1,
    isActive: json['is_active'] ?? true,
    createdAt: DateTime.parse(json['created_at']),
    categoryName: json['category_name'],
    categoryIcon: json['category_icon'],
    categoryColor: json['category_color'],
  );
}
