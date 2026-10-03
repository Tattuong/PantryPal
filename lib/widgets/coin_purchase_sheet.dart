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

    shop.releasePurchaseUi();
    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (ctx) {
          final maxHeight = MediaQuery.sizeOf(ctx).height * 0.72;
          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: const _CoinPurchaseSheet(),
          );
        },
      );
    } finally {
      shop.releasePurchaseUi();
    }
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
    final hasPacks = shop.billing.isAvailable && products.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
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
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(
                  AppStrings.t(context, 'processingPurchase'),
                  style: const TextStyle(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (hasPacks)
            Flexible(
              child: ListView.separated(
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) => _PackTile(product: products[i]),
              ),
            )
          else
            _StatusBanner(
              icon: shop.billing.isAvailable
                  ? Icons.inventory_2_outlined
                  : Icons.storefront_outlined,
              text: AppStrings.t(
                context,
                shop.billing.isAvailable ? 'productsNotFound' : 'billingUnavailable',
              ),
              color: AppColors.onSurfaceVariant,
            ),
          const SizedBox(height: 12),
          Text(
            AppStrings.t(context, 'earnCoinsHint'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11),
          ),
        ],
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
      color: Theme.of(context).colorScheme.surface,
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
