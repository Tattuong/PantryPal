import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/iap_constants.dart';
import '../../models/app_theme_preset.dart';
import '../../models/food_item.dart';
import '../../models/shop_item.dart';
import '../../providers/pantry_provider.dart';
import '../../providers/shop_provider.dart';
import '../../widgets/coin_balance_chip.dart';
import 'add_food_screen.dart';
import 'bulk_add_screen.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  FoodCategory? _filterCategory;
  ExpiryStatus? _filterStatus;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final pantry = context.watch<PantryProvider>();
    final shop = context.watch<ShopProvider>();
    final header = shop.activeBackgroundId == ShopCatalog.defaultBackgroundId
        ? shop.activeTheme.headerGradient
        : shop.activeBackground.gradient;
    final cardStyle = shop.activeCardStyle;
    final items = pantry.filtered(category: _filterCategory, status: _filterStatus, query: _query);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: MediaQuery.paddingOf(context).top + 142,
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: header.colors.first,
            automaticallyImplyLeading: false,
            flexibleSpace: _PantryHeader(
              gradient: header,
              title: AppStrings.t(context, 'pantryTitle'),
              subtitle: AppStrings.t(context, 'pantrySubtitle'),
              total: '${pantry.totalCount}',
              expiring: '${pantry.expiringSoonItems.length}',
              expired: '${pantry.expiredItems.length}',
              totalLabel: AppStrings.t(context, 'statTotal'),
              expiringLabel: AppStrings.t(context, 'statExpiring'),
              expiredLabel: AppStrings.t(context, 'statExpired'),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: AppStrings.t(context, 'searchFood'),
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _FilterChip(
                    label: AppStrings.t(context, 'filterAll'),
                    selected: _filterCategory == null && _filterStatus == null,
                    onTap: () => setState(() {
                      _filterCategory = null;
                      _filterStatus = null;
                    }),
                  ),
                  _FilterChip(
                    label: AppStrings.t(context, 'filterExpiring'),
                    selected: _filterStatus == ExpiryStatus.expiringSoon,
                    onTap: () => setState(() {
                      _filterStatus = ExpiryStatus.expiringSoon;
                      _filterCategory = null;
                    }),
                  ),
                  _FilterChip(
                    label: AppStrings.t(context, 'filterExpired'),
                    selected: _filterStatus == ExpiryStatus.expired,
                    onTap: () => setState(() {
                      _filterStatus = ExpiryStatus.expired;
                      _filterCategory = null;
                    }),
                  ),
                  ...FoodCategory.values.map(
                    (c) => _FilterChip(
                      label: AppStrings.t(context, 'cat_${c.id}'),
                      selected: _filterCategory == c,
                      onTap: () => setState(() {
                        _filterCategory = c;
                        _filterStatus = null;
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (pantry.expiredItems.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: FilledButton.tonalIcon(
                  onPressed: () async {
                    final removed = await pantry.removeExpired();
                    if (removed > 0) await shop.rewardForCleanup(removed);
                  },
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: Text(AppStrings.t(context, 'clearExpired', {'count': '${pantry.expiredItems.length}'})),
                ),
              ),
            ),
          if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.kitchen_outlined, size: 64, color: AppColors.onSurfaceVariant.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text(AppStrings.t(context, 'pantryEmpty'), style: const TextStyle(color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _FoodCard(item: items[i], cardStyle: cardStyle, isDark: isDark, shop: shop),
                  ),
                  childCount: items.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: shop.hasBulkAdd
          ? FloatingActionButton.extended(
              onPressed: () => _showAddMenu(context, shop),
              icon: const Icon(Icons.add),
              label: Text(AppStrings.t(context, 'addFood')),
            )
          : FloatingActionButton.extended(
              onPressed: () => _openAdd(context),
              icon: const Icon(Icons.add),
              label: Text(AppStrings.t(context, 'addFood')),
            ),
    );
  }

  Future<void> _showAddMenu(BuildContext context, ShopProvider shop) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: Text(AppStrings.t(context, 'addFood')),
              onTap: () => Navigator.pop(ctx, 'single'),
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add_check),
              title: Text(AppStrings.t(context, 'bulkAddTitle')),
              onTap: () => Navigator.pop(ctx, 'bulk'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'bulk') {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const BulkAddScreen()));
    } else {
      await _openAdd(context);
    }
  }

  Future<void> _openAdd(BuildContext context) async {
    final shop = context.read<ShopProvider>();
    final pantry = context.read<PantryProvider>();
    if (!pantry.canAddMore(unlimited: shop.hasUnlimitedItems)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.t(context, 'itemLimitReached', {'max': '${IapConstants.freeItemLimit}'}))),
      );
      return;
    }
    final added = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const AddFoodScreen()));
    if (added == true) await shop.rewardForAddFood();
  }
}

class _PantryHeader extends StatelessWidget {
  final LinearGradient gradient;
  final String title;
  final String subtitle;
  final String total;
  final String expiring;
  final String expired;
  final String totalLabel;
  final String expiringLabel;
  final String expiredLabel;

  const _PantryHeader({
    required this.gradient,
    required this.title,
    required this.subtitle,
    required this.total,
    required this.expiring,
    required this.expired,
    required this.totalLabel,
    required this.expiringLabel,
    required this.expiredLabel,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return LayoutBuilder(
      builder: (context, constraints) {
        final collapsed = constraints.maxHeight <= top + kToolbarHeight + 8;

        return DecoratedBox(
          decoration: BoxDecoration(gradient: gradient),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, top, 12, collapsed ? 0 : 12),
            child: collapsed
                ? SizedBox(
                    height: kToolbarHeight,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const CoinBalanceChip(),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const CoinBalanceChip(),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _StatChip(label: totalLabel, value: total, color: Colors.white)),
                          const SizedBox(width: 8),
                          Expanded(child: _StatChip(label: expiringLabel, value: expiring, color: AppColors.warning)),
                          const SizedBox(width: 8),
                          Expanded(child: _StatChip(label: expiredLabel, value: expired, color: AppColors.error)),
                        ],
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: color, height: 1)),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _FoodCard extends StatelessWidget {
  final FoodItem item;
  final CardStyle cardStyle;
  final bool isDark;
  final ShopProvider shop;

  const _FoodCard({
    required this.item,
    required this.cardStyle,
    required this.isDark,
    required this.shop,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = shop.categoryColor(item.category);
    final statusColor = switch (item.expiryStatus) {
      ExpiryStatus.expired => AppColors.expired,
      ExpiryStatus.expiringSoon => AppColors.expiringSoon,
      ExpiryStatus.fresh => AppColors.fresh,
    };

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(cardStyle.borderRadius)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => context.read<PantryProvider>().removeItem(item.id),
      child: Material(
        color: cardStyle.glassEffect
            ? Theme.of(context).colorScheme.surface.withValues(alpha: isDark ? 0.7 : 0.85)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(cardStyle.borderRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(cardStyle.borderRadius),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddFoodScreen(editItem: item))),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(cardStyle.borderRadius),
              border: Border.all(color: cardStyle.borderWidth > 0 ? cardStyle.borderColor : Colors.transparent, width: cardStyle.borderWidth),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.category.icon, color: catColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.t(context, 'cat_${item.category.id}'),
                        style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11),
                      ),
                      if (item.quantity > 1 || item.unit.isNotEmpty)
                        Text(
                          '${item.quantity}${item.unit.isNotEmpty ? ' ${item.unit}' : ''}',
                          style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (item.expiryDate != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _expiryLabel(context, item),
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 10),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat.yMMMd(AppStrings.languageCodeOf(context)).format(item.expiryDate!),
                        style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
                      ),
                    ] else
                      Text(AppStrings.t(context, 'noExpiry'), style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _expiryLabel(BuildContext context, FoodItem item) {
    final days = item.daysUntilExpiry;
    if (days == null) return AppStrings.t(context, 'noExpiry');
    if (days < 0) return AppStrings.t(context, 'expiredLabel');
    if (days == 0) return AppStrings.t(context, 'expiresToday');
    return AppStrings.t(context, 'daysLeft', {'days': '$days'});
  }
}
