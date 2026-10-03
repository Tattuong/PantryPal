import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/food_item.dart';
import '../../models/shopping_item.dart';
import '../../providers/shopping_provider.dart';
import '../../providers/shop_provider.dart';
import '../../widgets/coin_balance_chip.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final _inputCtrl = TextEditingController();
  FoodCategory _category = FoodCategory.other;

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    final name = _inputCtrl.text.trim();
    if (name.isEmpty) return;
    await context.read<ShoppingProvider>().addItem(name: name, category: _category);
    _inputCtrl.clear();
  }

  Future<void> _shareList() async {
    final shop = context.read<ShopProvider>();
    final text = context.read<ShoppingProvider>().exportText();
    if (text.isEmpty) return;

    final branded = shop.hasNoWatermark
        ? text
        : '${AppStrings.t(context, 'shoppingListTitle')}\n\n$text\n\n${AppStrings.t(context, 'shareListBranded')}';

    await Share.share(branded);
    await shop.rewardForShare();
  }

  @override
  Widget build(BuildContext context) {
    final shopping = context.watch<ShoppingProvider>();
    final unchecked = shopping.items.where((e) => !e.isChecked).toList();
    final checked = shopping.items.where((e) => e.isChecked).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppStrings.t(context, 'shoppingListTitle')),
        actions: [
          if (shopping.items.isNotEmpty)
            IconButton(onPressed: _shareList, icon: const Icon(Icons.share_outlined)),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CoinBalanceChip(onTap: null),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: AppStrings.t(context, 'shoppingHint'),
                      prefixIcon: const Icon(Icons.add_shopping_cart_outlined),
                    ),
                    onSubmitted: (_) => _addItem(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _addItem, child: Text(AppStrings.t(context, 'add'))),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: FoodCategory.values.map((c) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(AppStrings.t(context, 'cat_${c.id}'), style: const TextStyle(fontSize: 11)),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
                );
              }).toList(),
            ),
          ),
          if (shopping.items.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shopping_basket_outlined, size: 64, color: AppColors.onSurfaceVariant.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text(AppStrings.t(context, 'shoppingEmpty'), style: const TextStyle(color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  if (unchecked.isNotEmpty) ...[
                    Text(AppStrings.t(context, 'toBuy'), style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    ...unchecked.map((item) => _ShoppingTile(item: item)),
                  ],
                  if (checked.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(AppStrings.t(context, 'bought'), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.onSurfaceVariant)),
                        ),
                        TextButton(
                          onPressed: () => shopping.clearChecked(),
                          child: Text(AppStrings.t(context, 'clearChecked')),
                        ),
                      ],
                    ),
                    ...checked.map((item) => _ShoppingTile(item: item)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ShoppingTile extends StatelessWidget {
  final ShoppingItem item;

  const _ShoppingTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final shopping = context.read<ShoppingProvider>();
    final shop = context.read<ShopProvider>();

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => shopping.removeItem(item.id),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: CheckboxListTile(
          value: item.isChecked,
          onChanged: (_) async {
            final wasUnchecked = !item.isChecked;
            await shopping.toggleChecked(item.id);
            if (wasUnchecked) await shop.rewardForShoppingDone();
          },
          title: Text(item.name, style: TextStyle(decoration: item.isChecked ? TextDecoration.lineThrough : null)),
          subtitle: Text(AppStrings.t(context, 'cat_${item.category.id}')),
          secondary: CircleAvatar(
            backgroundColor: shop.categoryColor(item.category).withValues(alpha: 0.15),
            child: Icon(item.category.icon, color: shop.categoryColor(item.category), size: 20),
          ),
        ),
      ),
    );
  }
}
