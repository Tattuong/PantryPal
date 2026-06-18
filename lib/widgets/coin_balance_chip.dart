import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../providers/shop_provider.dart';
import 'coin_purchase_sheet.dart';

class CoinBalanceChip extends StatelessWidget {
  final VoidCallback? onTap;

  const CoinBalanceChip({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopProvider>();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () => CoinPurchaseSheet.show(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.coin.withValues(alpha: 0.2),
                AppColors.warning.withValues(alpha: 0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.coin.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: AppColors.coin, size: 18),
              const SizedBox(width: 4),
              Text(
                '${shop.coins}',
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.coin, fontSize: 14),
              ),
              if (!shop.isBillingDisabled) ...[
                const SizedBox(width: 4),
                const Icon(Icons.add_circle_outline, color: AppColors.coin, size: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
