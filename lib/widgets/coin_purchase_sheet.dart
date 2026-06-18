import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/constants/iap_constants.dart';
import '../core/services/iap_config_service.dart';
import '../providers/shop_provider.dart';
import 'app_toast.dart';

class CoinPurchaseSheet {
  static Future<void> show(BuildContext context) async {
    final shop = context.read<ShopProvider>();
    if (shop.isBillingDisabled) {
      AppToast.show(
        context,
        title: AppStrings.t(context, 'billingDisabled'),
        icon: Icons.info_outline,
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const _CoinPurchaseSheet(),
    );
  }
}

class _CoinPurchaseSheet extends StatefulWidget {
  const _CoinPurchaseSheet();

  @override
  State<_CoinPurchaseSheet> createState() => _CoinPurchaseSheetState();
}

class _CoinPurchaseSheetState extends State<_CoinPurchaseSheet> {
  ShopProvider? _shop;
  bool _closedAfterPurchase = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shop = context.read<ShopProvider>();
    if (_shop != shop) {
      _shop?.removeListener(_onShopChanged);
      _shop = shop;
      _shop!.addListener(_onShopChanged);
    }
  }

  @override
  void dispose() {
    _shop?.removeListener(_onShopChanged);
    super.dispose();
  }

  void _onShopChanged() {
    if (_closedAfterPurchase || !mounted) return;
    final shop = _shop;
    if (shop == null) return;

    if (!shop.isPurchasing && shop.lastMessage == 'coinsAdded') {
      _closedAfterPurchase = true;
      shop.clearLastMessage();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopProvider>();
    final products = shop.billing.products;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.t(context, 'buyCoins'),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.t(context, 'buyCoinsDesc'),
              style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star_rounded, color: AppColors.warning, size: 20),
                const SizedBox(width: 6),
                Text(
                  AppStrings.t(context, 'yourCoins', {'count': shop.coins.toString()}),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            if (shop.configStatus == IapConfigStatus.networkError ||
                shop.configStatus == IapConfigStatus.timeout) ...[
              const SizedBox(height: 12),
              _StatusBanner(
                icon: Icons.wifi_off_outlined,
                text: AppStrings.t(context, 'configNetworkError'),
                color: AppColors.warning,
              ),
            ],
            if (shop.isPurchasing) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  AppStrings.t(context, 'processingPurchase'),
                  style: const TextStyle(color: AppColors.onSurfaceVariant),
                ),
              ),
            ] else if (!shop.billing.isAvailable) ...[
              const SizedBox(height: 24),
              _StatusBanner(
                icon: Icons.storefront_outlined,
                text: AppStrings.t(context, 'billingUnavailable'),
                color: AppColors.onSurfaceVariant,
              ),
            ] else if (products.isEmpty) ...[
              const SizedBox(height: 24),
              _StatusBanner(
                icon: Icons.inventory_2_outlined,
                text: AppStrings.t(context, 'productsNotFound'),
                color: AppColors.onSurfaceVariant,
              ),
            ] else ...[
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) => _PackTile(product: products[i]),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              AppStrings.t(context, 'earnCoinsHint'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackTile extends StatelessWidget {
  final ProductDetails product;

  const _PackTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final shop = context.read<ShopProvider>();
    final coins = IapConstants.coinsForProduct(product.id);
    final packNum = IapConstants.coinPackIds.indexOf(product.id) + 1;

    return Material(
      color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: shop.isPurchasing ? null : () => _buy(context, shop),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.star_rounded, color: AppColors.warning),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.t(context, 'coinPack', {'num': packNum.toString()}),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    Text(
                      AppStrings.t(context, 'coinAmount', {'count': coins.toString()}),
                      style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: shop.isPurchasing ? null : () => _buy(context, shop),
                child: Text(product.price),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _buy(BuildContext context, ShopProvider shop) async {
    final ok = await shop.buyCoinPack(product);
    if (!context.mounted) return;
    if (ok) {
      AppToast.show(context, title: AppStrings.t(context, 'openingBilling'));
    } else if (shop.lastMessage != null) {
      AppToast.show(context, title: AppStrings.t(context, shop.lastMessage!));
    }
  }
}

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _StatusBanner({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: color, fontSize: 13))),
        ],
      ),
    );
  }
}
