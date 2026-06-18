import 'food_item.dart';

class ShoppingItem {
  final String id;
  final String name;
  final FoodCategory category;
  final int quantity;
  final String unit;
  final bool isChecked;
  final DateTime createdAt;

  const ShoppingItem({
    required this.id,
    required this.name,
    required this.category,
    this.quantity = 1,
    this.unit = '',
    this.isChecked = false,
    required this.createdAt,
  });

  ShoppingItem copyWith({
    String? name,
    FoodCategory? category,
    int? quantity,
    String? unit,
    bool? isChecked,
  }) {
    return ShoppingItem(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      isChecked: isChecked ?? this.isChecked,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.id,
        'quantity': quantity,
        'unit': unit,
        'isChecked': isChecked,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
        id: json['id'] as String,
        name: json['name'] as String,
        category: FoodCategory.fromId(json['category'] as String?),
        quantity: json['quantity'] as int? ?? 1,
        unit: json['unit'] as String? ?? '',
        isChecked: json['isChecked'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
