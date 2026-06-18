import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/iap_constants.dart';
import '../core/services/notification_service.dart';
import '../core/services/storage_service.dart';
import '../models/food_item.dart';

class PantryProvider extends ChangeNotifier {
  static const _itemsKey = 'pp_food_items';

  final _uuid = const Uuid();
  List<FoodItem> _items = [];
  bool _loaded = false;

  List<FoodItem> get items => List.unmodifiable(_items);
  bool get isLoaded => _loaded;

  List<FoodItem> get expiredItems => _items.where((i) => i.expiryStatus == ExpiryStatus.expired).toList();
  List<FoodItem> get expiringSoonItems => _items.where((i) => i.expiryStatus == ExpiryStatus.expiringSoon).toList();
  List<FoodItem> get freshItems => _items.where((i) => i.expiryStatus == ExpiryStatus.fresh).toList();

  int get totalCount => _items.length;

  Future<void> load() async {
    final raw = await StorageService.instance.getString(_itemsKey);
    if (raw != null && raw.isNotEmpty) {
      _items = StorageService.decodeList(raw).map(FoodItem.fromJson).toList();
    }
    _loaded = true;
    await NotificationService.instance.scheduleExpiryAlerts(_items);
    notifyListeners();
  }

  Future<void> _save() async {
    await StorageService.instance.saveString(
      _itemsKey,
      StorageService.encodeList(_items.map((e) => e.toJson()).toList()),
    );
    await NotificationService.instance.scheduleExpiryAlerts(_items);
  }

  bool canAddMore({required bool unlimited}) {
    if (unlimited) return true;
    return _items.length < IapConstants.freeItemLimit;
  }

  Future<bool> addItem({
    required String name,
    required FoodCategory category,
    DateTime? expiryDate,
    int quantity = 1,
    String unit = '',
    String notes = '',
    required bool unlimited,
  }) async {
    if (!canAddMore(unlimited: unlimited)) return false;

    _items.insert(
      0,
      FoodItem(
        id: _uuid.v4(),
        name: name.trim(),
        category: category,
        expiryDate: expiryDate,
        quantity: quantity,
        unit: unit.trim(),
        notes: notes.trim(),
        addedAt: DateTime.now(),
      ),
    );
    await _save();
    notifyListeners();
    return true;
  }

  Future<void> updateItem(FoodItem item) async {
    final index = _items.indexWhere((e) => e.id == item.id);
    if (index < 0) return;
    _items[index] = item;
    await _save();
    notifyListeners();
  }

  Future<void> removeItem(String id) async {
    _items.removeWhere((e) => e.id == id);
    await _save();
    notifyListeners();
  }

  Future<int> removeExpired() async {
    final before = _items.length;
    _items.removeWhere((e) => e.expiryStatus == ExpiryStatus.expired);
    final removed = before - _items.length;
    if (removed > 0) await _save();
    notifyListeners();
    return removed;
  }

  Future<int> addBulkItems({
    required List<({String name, FoodCategory category, int daysUntilExpiry})> entries,
    required bool unlimited,
  }) async {
    var added = 0;
    for (final entry in entries) {
      if (!canAddMore(unlimited: unlimited)) break;
      final name = entry.name.trim();
      if (name.isEmpty) continue;

      _items.insert(
        0,
        FoodItem(
          id: _uuid.v4(),
          name: name,
          category: entry.category,
          expiryDate: DateTime.now().add(Duration(days: entry.daysUntilExpiry)),
          addedAt: DateTime.now(),
        ),
      );
      added++;
    }

    if (added > 0) await _save();
    notifyListeners();
    return added;
  }

  String exportAsText() {
    if (_items.isEmpty) return '';
    final buffer = StringBuffer('--- Pantry ---\n');
    for (final item in _items) {
      final expiry = item.expiryDate != null
          ? item.expiryDate!.toIso8601String().split('T').first
          : 'no expiry';
      buffer.writeln('• ${item.name} [${item.category.id}] — $expiry');
    }
    return buffer.toString();
  }

  List<FoodItem> filtered({FoodCategory? category, ExpiryStatus? status, String query = ''}) {
    return _items.where((item) {
      if (category != null && item.category != category) return false;
      if (status != null && item.expiryStatus != status) return false;
      if (query.isNotEmpty && !item.name.toLowerCase().contains(query.toLowerCase())) return false;
      return true;
    }).toList()
      ..sort((a, b) {
        if (a.expiryDate == null && b.expiryDate == null) return b.addedAt.compareTo(a.addedAt);
        if (a.expiryDate == null) return 1;
        if (b.expiryDate == null) return -1;
        return a.expiryDate!.compareTo(b.expiryDate!);
      });
  }
}
