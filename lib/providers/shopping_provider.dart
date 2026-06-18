import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/services/storage_service.dart';
import '../models/food_item.dart';
import '../models/shopping_item.dart';

class ShoppingProvider extends ChangeNotifier {
  static const _itemsKey = 'pp_shopping_items';

  final _uuid = const Uuid();
  List<ShoppingItem> _items = [];
  bool _loaded = false;

  List<ShoppingItem> get items => List.unmodifiable(_items);
  bool get isLoaded => _loaded;
  int get uncheckedCount => _items.where((e) => !e.isChecked).length;

  Future<void> load() async {
    final raw = await StorageService.instance.getString(_itemsKey);
    if (raw != null && raw.isNotEmpty) {
      _items = StorageService.decodeList(raw).map(ShoppingItem.fromJson).toList();
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    await StorageService.instance.saveString(
      _itemsKey,
      StorageService.encodeList(_items.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> addItem({
    required String name,
    FoodCategory category = FoodCategory.other,
    int quantity = 1,
    String unit = '',
  }) async {
    _items.insert(
      0,
      ShoppingItem(
        id: _uuid.v4(),
        name: name.trim(),
        category: category,
        quantity: quantity,
        unit: unit.trim(),
        createdAt: DateTime.now(),
      ),
    );
    await _save();
    notifyListeners();
  }

  Future<void> toggleChecked(String id) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index < 0) return;
    _items[index] = _items[index].copyWith(isChecked: !_items[index].isChecked);
    await _save();
    notifyListeners();
  }

  Future<void> removeItem(String id) async {
    _items.removeWhere((e) => e.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> clearChecked() async {
    _items.removeWhere((e) => e.isChecked);
    await _save();
    notifyListeners();
  }

  Future<void> addFromPantrySuggestion(String name, FoodCategory category) async {
    if (_items.any((e) => e.name.toLowerCase() == name.toLowerCase())) return;
    await addItem(name: name, category: category);
  }

  String exportText() {
    final unchecked = _items.where((e) => !e.isChecked).toList();
    if (unchecked.isEmpty) return '';
    return unchecked.map((e) {
      final qty = e.quantity > 1 ? ' (${e.quantity}${e.unit.isNotEmpty ? ' ${e.unit}' : ''})' : '';
      return '• ${e.name}$qty';
    }).join('\n');
  }
}
