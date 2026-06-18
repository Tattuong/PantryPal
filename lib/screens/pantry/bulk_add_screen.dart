import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/iap_constants.dart';
import '../../models/food_item.dart';
import '../../providers/pantry_provider.dart';
import '../../providers/shop_provider.dart';
import '../../widgets/app_toast.dart';

class BulkAddScreen extends StatefulWidget {
  const BulkAddScreen({super.key});

  @override
  State<BulkAddScreen> createState() => _BulkAddScreenState();
}

class _BulkAddScreenState extends State<BulkAddScreen> {
  final _ctrl = TextEditingController();
  int _defaultDays = 7;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final shop = context.read<ShopProvider>();
    final pantry = context.read<PantryProvider>();
    final lines = _ctrl.text.split('\n').where((l) => l.trim().isNotEmpty);

    final entries = <({String name, FoodCategory category, int daysUntilExpiry})>[];
    for (final line in lines) {
      final parts = line.split(',').map((p) => p.trim()).toList();
      final name = parts.first;
      if (name.isEmpty) continue;

      FoodCategory category = FoodCategory.other;
      var days = _defaultDays;

      if (parts.length >= 2) {
        category = FoodCategory.fromId(parts[1].toLowerCase());
      }
      if (parts.length >= 3) {
        days = int.tryParse(parts[2]) ?? _defaultDays;
      }

      entries.add((name: name, category: category, daysUntilExpiry: days));
    }

    if (entries.isEmpty) return;

    final added = await pantry.addBulkItems(entries: entries, unlimited: shop.hasUnlimitedItems);
    if (!mounted) return;

    if (added > 0) {
      for (var i = 0; i < added && i < IapConstants.maxAddFoodRewardsPerDay; i++) {
        await shop.rewardForAddFood();
      }
      AppToast.show(context, title: AppStrings.t(context, 'bulkAddSuccess', {'count': '$added'}));
      Navigator.pop(context, added);
    } else {
      AppToast.show(
        context,
        title: AppStrings.t(context, 'itemLimitReached', {'max': '${IapConstants.freeItemLimit}'}),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t(context, 'bulkAddTitle'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(AppStrings.t(context, 'bulkAddHint'), style: const TextStyle(height: 1.5)),
          const SizedBox(height: 8),
          Text(
            AppStrings.t(context, 'bulkAddFormat'),
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(AppStrings.t(context, 'bulkAddDefaultDays')),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: _defaultDays,
                items: [3, 5, 7, 14, 30]
                    .map((d) => DropdownMenuItem(value: d, child: Text('$d ${AppStrings.t(context, 'daysUnit')}') ))
                    .toList(),
                onChanged: (v) => setState(() => _defaultDays = v ?? 7),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            maxLines: 12,
            decoration: InputDecoration(
              hintText: AppStrings.t(context, 'bulkAddPlaceholder'),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.playlist_add_check),
            label: Text(AppStrings.t(context, 'bulkAddButton')),
          ),
        ],
      ),
    );
  }
}
