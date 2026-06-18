import 'package:flutter/material.dart';

enum FoodCategory {
  meat,
  vegetable,
  fruit,
  dairy,
  drink,
  grain,
  frozen,
  snack,
  other;

  static FoodCategory fromId(String? id) {
    if (id == null) return FoodCategory.other;
    return FoodCategory.values.firstWhere(
      (c) => c.name == id,
      orElse: () => FoodCategory.other,
    );
  }
}

extension FoodCategoryX on FoodCategory {
  String get id => name;

  IconData get icon => switch (this) {
        FoodCategory.meat => Icons.set_meal_outlined,
        FoodCategory.vegetable => Icons.grass_outlined,
        FoodCategory.fruit => Icons.local_florist_outlined,
        FoodCategory.dairy => Icons.egg_outlined,
        FoodCategory.drink => Icons.local_drink_outlined,
        FoodCategory.grain => Icons.rice_bowl_outlined,
        FoodCategory.frozen => Icons.ac_unit_outlined,
        FoodCategory.snack => Icons.cookie_outlined,
        FoodCategory.other => Icons.category_outlined,
      };

  Color get color => switch (this) {
        FoodCategory.meat => const Color(0xFFE74C3C),
        FoodCategory.vegetable => const Color(0xFF27AE60),
        FoodCategory.fruit => const Color(0xFFF39C12),
        FoodCategory.dairy => const Color(0xFF3498DB),
        FoodCategory.drink => const Color(0xFF1ABC9C),
        FoodCategory.grain => const Color(0xFFD4AC0D),
        FoodCategory.frozen => const Color(0xFF74B9FF),
        FoodCategory.snack => const Color(0xFFE67E22),
        FoodCategory.other => const Color(0xFF7F8C8D),
      };
}

enum ExpiryStatus { fresh, expiringSoon, expired }

class FoodItem {
  final String id;
  final String name;
  final FoodCategory category;
  final DateTime? expiryDate;
  final int quantity;
  final String unit;
  final String notes;
  final DateTime addedAt;

  const FoodItem({
    required this.id,
    required this.name,
    required this.category,
    this.expiryDate,
    this.quantity = 1,
    this.unit = '',
    this.notes = '',
    required this.addedAt,
  });

  ExpiryStatus get expiryStatus {
    if (expiryDate == null) return ExpiryStatus.fresh;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate!.year, expiryDate!.month, expiryDate!.day);
    if (expiry.isBefore(today)) return ExpiryStatus.expired;
    if (expiry.difference(today).inDays <= 3) return ExpiryStatus.expiringSoon;
    return ExpiryStatus.fresh;
  }

  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate!.year, expiryDate!.month, expiryDate!.day);
    return expiry.difference(today).inDays;
  }

  FoodItem copyWith({
    String? name,
    FoodCategory? category,
    DateTime? expiryDate,
    bool clearExpiry = false,
    int? quantity,
    String? unit,
    String? notes,
  }) {
    return FoodItem(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      expiryDate: clearExpiry ? null : (expiryDate ?? this.expiryDate),
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      notes: notes ?? this.notes,
      addedAt: addedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.id,
        'expiryDate': expiryDate?.toIso8601String(),
        'quantity': quantity,
        'unit': unit,
        'notes': notes,
        'addedAt': addedAt.toIso8601String(),
      };

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
        id: json['id'] as String,
        name: json['name'] as String,
        category: FoodCategory.fromId(json['category'] as String?),
        expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate'] as String) : null,
        quantity: json['quantity'] as int? ?? 1,
        unit: json['unit'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        addedAt: DateTime.parse(json['addedAt'] as String),
      );
}
