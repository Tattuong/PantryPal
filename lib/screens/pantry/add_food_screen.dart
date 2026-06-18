import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/iap_constants.dart';
import '../../models/food_item.dart';
import '../../providers/pantry_provider.dart';
import '../../providers/shop_provider.dart';

class AddFoodScreen extends StatefulWidget {
  final FoodItem? editItem;

  const AddFoodScreen({super.key, this.editItem});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _quantityCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _notesCtrl;
  late FoodCategory _category;
  DateTime? _expiryDate;
  bool _hasExpiry = true;

  bool get _isEdit => widget.editItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.editItem;
    _nameCtrl = TextEditingController(text: item?.name ?? '');
    _quantityCtrl = TextEditingController(text: '${item?.quantity ?? 1}');
    _unitCtrl = TextEditingController(text: item?.unit ?? '');
    _notesCtrl = TextEditingController(text: item?.notes ?? '');
    _category = item?.category ?? FoodCategory.other;
    _expiryDate = item?.expiryDate ?? DateTime.now().add(const Duration(days: 7));
    _hasExpiry = item?.expiryDate != null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _quantityCtrl.dispose();
    _unitCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _saveItem() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final pantry = context.read<PantryProvider>();
    final quantity = int.tryParse(_quantityCtrl.text.trim()) ?? 1;

    if (_isEdit) {
      await pantry.updateItem(
        widget.editItem!.copyWith(
          name: name,
          category: _category,
          expiryDate: _hasExpiry ? _expiryDate : null,
          clearExpiry: !_hasExpiry,
          quantity: quantity,
          unit: _unitCtrl.text.trim(),
          notes: _notesCtrl.text.trim(),
        ),
      );
      if (mounted) Navigator.pop(context);
      return;
    }

    final shop = context.read<ShopProvider>();
    final ok = await pantry.addItem(
      name: name,
      category: _category,
      expiryDate: _hasExpiry ? _expiryDate : null,
      quantity: quantity,
      unit: _unitCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
      unlimited: shop.hasUnlimitedItems,
    );

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.t(context, 'itemLimitReached', {'max': '${IapConstants.freeItemLimit}'}),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t(context, _isEdit ? 'editFood' : 'addFood')),
        actions: [
          if (_isEdit)
            IconButton(
              onPressed: () async {
                await context.read<PantryProvider>().removeItem(widget.editItem!.id);
                if (mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: AppStrings.t(context, 'foodName')),
          ),
          const SizedBox(height: 16),
          Text(AppStrings.t(context, 'category'), style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: FoodCategory.values.map((c) {
              final selected = _category == c;
              return ChoiceChip(
                label: Text(AppStrings.t(context, 'cat_${c.id}')),
                selected: selected,
                avatar: Icon(c.icon, size: 16, color: selected ? Colors.white : c.color),
                onSelected: (_) => setState(() => _category = c),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quantityCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: AppStrings.t(context, 'quantity')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _unitCtrl,
                  decoration: InputDecoration(labelText: AppStrings.t(context, 'unit')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(AppStrings.t(context, 'hasExpiry')),
            value: _hasExpiry,
            onChanged: (v) => setState(() => _hasExpiry = v),
          ),
          if (_hasExpiry)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AppStrings.t(context, 'expiryDate')),
              subtitle: Text(
                _expiryDate != null
                    ? DateFormat.yMMMd(AppStrings.languageCodeOf(context)).format(_expiryDate!)
                    : '-',
              ),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickDate,
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: InputDecoration(labelText: AppStrings.t(context, 'notes')),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saveItem,
            child: Text(AppStrings.t(context, 'save')),
          ),
        ],
      ),
    );
  }
}
