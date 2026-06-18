import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/iap_config_service.dart';
import '../../models/app_theme_preset.dart';
import '../../models/shop_item.dart';
import '../../providers/shop_provider.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/coin_purchase_sheet.dart';

enum ShopRewardsTab { all, premium, themes, backgrounds, skins, features }

class ShopScreen extends StatefulWidget {
  final bool embedded;

  const ShopScreen({super.key, this.embedded = false});

  @override
  ShopScreenState createState() => ShopScreenState();
}

class ShopScreenState extends State<ShopScreen> with SingleTickerProviderStateMixin {
  ShopRewardsTab _tab = ShopRewardsTab.all;
  late final AnimationController _shimmerCtrl;

  void selectTab(ShopRewardsTab tab) {
    if (_tab == tab) return;
    setState(() => _tab = tab);
  }

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  List<ShopItem> _itemsFor(ShopRewardsTab tab) => switch (tab) {
        ShopRewardsTab.all => ShopCatalog.items,
        ShopRewardsTab.premium => ShopCatalog.items.where((i) => i.category == ShopItemCategory.premium).toList(),
        ShopRewardsTab.themes => ShopCatalog.items.where((i) => i.category == ShopItemCategory.themes).toList(),
        ShopRewardsTab.backgrounds => ShopCatalog.items.where((i) => i.category == ShopItemCategory.backgrounds).toList(),
        ShopRewardsTab.skins => ShopCatalog.items.where((i) => i.category == ShopItemCategory.skins).toList(),
        ShopRewardsTab.features => ShopCatalog.items.where((i) => i.category == ShopItemCategory.features).toList(),
      };

  bool _useGrid(ShopRewardsTab tab) =>
      tab == ShopRewardsTab.themes || tab == ShopRewardsTab.backgrounds || tab == ShopRewardsTab.skins;

  List<Widget> _buildAllTabSlivers(List<ShopItem> items) {
    if (items.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: Text(AppStrings.t(context, 'shopEmptyCategory'), style: const TextStyle(color: AppColors.onSurfaceVariant))),
        ),
      ];
    }

    final premium = items.where((i) => i.category == ShopItemCategory.premium).toList();
    final themes = items.where((i) => i.category == ShopItemCategory.themes).toList();
    final backgrounds = items.where((i) => i.category == ShopItemCategory.backgrounds).toList();
    final skins = items.where((i) => i.category == ShopItemCategory.skins).toList();
    final features = items.where((i) => i.category == ShopItemCategory.features).toList();

    return [
      if (premium.isNotEmpty) ...[
        SliverToBoxAdapter(child: _SectionLabel(labelKey: 'shopMenuPremium')),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _WideRewardCard(item: premium[i])),
              childCount: premium.length,
            ),
          ),
        ),
      ],
      if (themes.isNotEmpty) ...[
        SliverToBoxAdapter(child: _SectionLabel(labelKey: 'shopMenuThemes')),
        _gridSliver(themes),
      ],
      if (backgrounds.isNotEmpty) ...[
        SliverToBoxAdapter(child: _SectionLabel(labelKey: 'shopMenuCards')),
        _gridSliver(backgrounds),
      ],
      if (skins.isNotEmpty) ...[
        SliverToBoxAdapter(child: _SectionLabel(labelKey: 'shopMenuSkins')),
        _gridSliver(skins),
      ],
      if (features.isNotEmpty) ...[
        SliverToBoxAdapter(child: _SectionLabel(labelKey: 'shopMenuFeatures')),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _WideRewardCard(item: features[i])),
              childCount: features.length,
            ),
          ),
        ),
      ],
      const SliverToBoxAdapter(child: SizedBox(height: 100)),
    ];
  }

  SliverPadding _gridSliver(List<ShopItem> items) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.78,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, i) => _BentoRewardCard(item: items[i]),
          childCount: items.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = _itemsFor(_tab);
    final bg = isDark ? AppColors.darkBackground : const Color(0xFFF0F2FA);

    final body = Stack(
      children: [
        Positioned(
          top: -120,
          left: -80,
          child: _GlowOrb(color: AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.22), size: 260),
        ),
        Positioned(
          top: 40,
          right: -60,
          child: _GlowOrb(color: AppColors.accent.withValues(alpha: isDark ? 0.25 : 0.15), size: 200),
        ),
        SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _RewardsHeader(embedded: widget.embedded, shimmer: _shimmerCtrl)),
              if (shop.configStatus == IapConfigStatus.timeout || shop.configStatus == IapConfigStatus.networkError)
                SliverToBoxAdapter(child: _ConfigBanner(status: shop.configStatus)),
              SliverToBoxAdapter(child: _StarBalanceCard(shop: shop, shimmer: _shimmerCtrl)),
              SliverToBoxAdapter(child: _MissionCarousel(shop: shop)),
              SliverToBoxAdapter(child: _TabStrip(selected: _tab, onSelect: (t) => setState(() => _tab = t))),
              if (_tab == ShopRewardsTab.all)
                ..._buildAllTabSlivers(items)
              else if (items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.onSurfaceVariant.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text(AppStrings.t(context, 'shopEmptyCategory'), style: const TextStyle(color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                )
              else if (_useGrid(_tab))
                _gridSliver(items)
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                        padding: EdgeInsets.only(bottom: i < items.length - 1 ? 12 : 0),
                        child: _WideRewardCard(item: items[i]),
                      ),
                      childCount: items.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return ColoredBox(color: bg, child: body);
    }

    return Scaffold(backgroundColor: bg, body: body);
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _RewardsHeader extends StatelessWidget {
  final bool embedded;
  final AnimationController shimmer;

  const _RewardsHeader({required this.embedded, required this.shimmer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(embedded ? 20 : 16, 12, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!embedded)
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              style: IconButton.styleFrom(backgroundColor: AppColors.primary.withValues(alpha: 0.08)),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.t(context, 'shopTitle'),
                  style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.8, height: 1.1),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.t(context, 'shopSubtitle'),
                  style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13, height: 1.35),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: shimmer,
            builder: (_, __) => Transform.rotate(
              angle: shimmer.value * 0.4,
              child: Icon(Icons.auto_awesome, color: AppColors.coin.withValues(alpha: 0.7 + shimmer.value * 0.3), size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarBalanceCard extends StatelessWidget {
  final ShopProvider shop;
  final AnimationController shimmer;

  const _StarBalanceCard({required this.shop, required this.shimmer});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF1A2235), const Color(0xFF252D45)]
                    : [Colors.white.withValues(alpha: 0.92), Colors.white.withValues(alpha: 0.75)],
              ),
              border: Border.all(color: (isDark ? Colors.white : AppColors.primary).withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: shimmer,
                      builder: (_, __) => Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.coin.withValues(alpha: 0.35 + shimmer.value * 0.15),
                              AppColors.coin.withValues(alpha: 0.05),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Icon(Icons.star_rounded, color: AppColors.coin, size: 34),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.t(context, 'yourWallet'),
                        style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${shop.coins}',
                            style: GoogleFonts.outfit(fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1),
                          ),
                          const SizedBox(width: 6),
                          Text(AppStrings.t(context, 'coinsLabel'), style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!shop.isBillingDisabled)
                  Material(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => CoinPurchaseSheet.show(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              AppStrings.t(context, 'buyCoins'),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MissionCarousel extends StatefulWidget {
  final ShopProvider shop;

  const _MissionCarousel({required this.shop});

  @override
  State<_MissionCarousel> createState() => _MissionCarouselState();
}

class _MissionCarouselState extends State<_MissionCarousel> {
  late Future<bool> _dailyFuture;

  @override
  void initState() {
    super.initState();
    _dailyFuture = widget.shop.hasClaimedDailyToday();
  }

  void _refreshDaily() {
    setState(() => _dailyFuture = widget.shop.hasClaimedDailyToday());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _dailyFuture,
      builder: (context, snapshot) {
        final dailyDone = snapshot.data ?? false;

        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: SizedBox(
            height: 92,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _MissionTile(
                icon: Icons.wb_sunny_rounded,
                iconColor: const Color(0xFFFFB020),
                title: AppStrings.t(context, 'earnCoins'),
                subtitle: dailyDone ? AppStrings.t(context, 'dailyRewardDone') : AppStrings.t(context, 'earnStepDaily'),
                actionLabel: dailyDone ? null : AppStrings.t(context, 'claimDailyButton'),
                done: dailyDone,
                onAction: dailyDone
                    ? null
                    : () async {
                        final claimed = await widget.shop.claimDailyReward();
                        if (!mounted) return;
                        _refreshDaily();
                        if (!claimed) {
                          AppToast.show(context, title: AppStrings.t(context, 'dailyRewardDone'), icon: Icons.info_outline);
                        }
                      },
              ),
              _MissionTile(
                icon: Icons.add_circle_outline,
                iconColor: AppColors.primary,
                title: AppStrings.t(context, 'earnStepAddFood'),
                subtitle: AppStrings.t(context, 'earnStepAddFoodDesc'),
                done: false,
              ),
              _MissionTile(
                icon: Icons.shopping_cart_checkout_outlined,
                iconColor: AppColors.success,
                title: AppStrings.t(context, 'earnStepShopping'),
                subtitle: AppStrings.t(context, 'earnStepShoppingDesc'),
                done: false,
              ),
              _MissionTile(
                icon: Icons.share_outlined,
                iconColor: const Color(0xFF74B9FF),
                title: AppStrings.t(context, 'earnStepShare'),
                subtitle: AppStrings.t(context, 'earnStepShareDesc'),
                done: false,
              ),
              if (!widget.shop.isBillingDisabled)
                _MissionTile(
                  icon: Icons.bolt_rounded,
                  iconColor: AppColors.accent,
                  title: AppStrings.t(context, 'buyCoins'),
                  subtitle: AppStrings.t(context, 'earnStepBuy'),
                  actionLabel: AppStrings.t(context, 'buyWithGooglePlay'),
                  onAction: () => CoinPurchaseSheet.show(context),
                ),
            ],
          ),
        ),
      );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String labelKey;

  const _SectionLabel({required this.labelKey});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        AppStrings.t(context, labelKey),
        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant),
      ),
    );
  }
}

class _MissionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final bool done;
  final VoidCallback? onAction;

  const _MissionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.done = false,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 228,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: iconColor.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, height: 1.2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 10, height: 1.2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: onAction,
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      actionLabel!,
                      style: TextStyle(color: iconColor, fontWeight: FontWeight.w800, fontSize: 10, height: 1.1),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (done)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Icon(Icons.check_circle_rounded, color: AppColors.success.withValues(alpha: 0.9), size: 18),
            ),
        ],
      ),
    );
  }
}

class _TabStrip extends StatelessWidget {
  final ShopRewardsTab selected;
  final ValueChanged<ShopRewardsTab> onSelect;

  const _TabStrip({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final tabs = <(ShopRewardsTab, String)>[
      (ShopRewardsTab.all, 'shopMenuAll'),
      (ShopRewardsTab.premium, 'shopMenuPremium'),
      (ShopRewardsTab.themes, 'shopMenuThemes'),
      (ShopRewardsTab.backgrounds, 'shopMenuCards'),
      (ShopRewardsTab.skins, 'shopMenuSkins'),
      (ShopRewardsTab.features, 'shopMenuFeatures'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.t(context, 'shopBrowse'), style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final (tab, key) = tabs[i];
                final active = selected == tab;
                return GestureDetector(
                  onTap: () => onSelect(tab),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active ? AppColors.primary : AppColors.onSurfaceVariant.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      AppStrings.t(context, key),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: active ? Colors.white : AppColors.onSurface,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BentoRewardCard extends StatelessWidget {
  final ShopItem item;

  const _BentoRewardCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopProvider>();
    final owned = shop.ownsItem(item.id);
    final isActive = _RewardActions.itemIsActive(shop, item);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: owned ? null : () => _RewardActions.tryPurchase(context, shop, item),
        child: Ink(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isActive ? AppColors.primary : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.04)),
              width: isActive ? 2 : 1,
            ),
            boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _ItemVisual(item: item, large: true),
                      if (owned)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(isActive ? Icons.radio_button_checked : Icons.check, color: Colors.white, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  AppStrings.t(context, isActive ? 'active' : 'owned'),
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.t(context, item.nameKey),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppStrings.t(context, item.descKey),
                      style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 10, height: 1.25),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    _RewardActions(item: item, owned: owned, isActive: isActive, dense: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WideRewardCard extends StatelessWidget {
  final ShopItem item;

  const _WideRewardCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopProvider>();
    final owned = shop.ownsItem(item.id);
    final isActive = _RewardActions.itemIsActive(shop, item);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isActive ? AppColors.primary : Colors.transparent, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(width: 72, height: 72, child: _ItemVisual(item: item)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.t(context, item.nameKey), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(AppStrings.t(context, item.descKey), style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 11, height: 1.35)),
                  const SizedBox(height: 10),
                  _RewardActions(item: item, owned: owned, isActive: isActive),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemVisual extends StatelessWidget {
  final ShopItem item;
  final bool large;

  const _ItemVisual({required this.item, this.large = false});

  @override
  Widget build(BuildContext context) {
    if (item.type == ShopItemType.theme) {
      final preset = AppThemePresets.byId[item.id];
      if (preset != null) {
        return DecoratedBox(
          decoration: BoxDecoration(gradient: preset.headerGradient),
          child: Center(child: Icon(Icons.palette_rounded, color: Colors.white.withValues(alpha: 0.9), size: large ? 32 : 26)),
        );
      }
    }
    if (item.type == ShopItemType.background) {
      final bg = AppBackground.byId[item.id];
      if (bg != null) {
        return DecoratedBox(
          decoration: BoxDecoration(gradient: bg.gradient),
          child: Center(child: Icon(Icons.layers_rounded, color: Colors.white.withValues(alpha: 0.85), size: large ? 28 : 22)),
        );
      }
    }
    if (item.type == ShopItemType.skin) {
      final skin = CardStyle.byId[item.id];
      if (skin != null) {
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [skin.accentColor.withValues(alpha: 0.5), skin.borderColor.withValues(alpha: 0.35)],
            ),
          ),
          child: Center(child: Icon(Icons.inventory_2_rounded, color: Colors.white.withValues(alpha: 0.9), size: large ? 28 : 22)),
        );
      }
    }

    final tint = switch (item.category) {
      ShopItemCategory.premium => AppColors.accent,
      ShopItemCategory.features => AppColors.primary,
      _ => AppColors.coin,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tint.withValues(alpha: 0.25), tint.withValues(alpha: 0.08)],
        ),
      ),
      child: Center(child: Icon(item.icon, color: tint, size: large ? 30 : 24)),
    );
  }
}

class _RewardActions extends StatelessWidget {
  final ShopItem item;
  final bool owned;
  final bool isActive;
  final bool dense;

  const _RewardActions({
    required this.item,
    required this.owned,
    required this.isActive,
    this.dense = false,
  });

  static bool itemIsActive(ShopProvider shop, ShopItem item) {
    if (item.type == ShopItemType.theme) return shop.activeThemeId == item.id;
    if (item.type == ShopItemType.background) return shop.activeBackgroundId == item.id;
    if (item.type == ShopItemType.skin) return shop.activeSkinId == item.id;
    return shop.ownsItem(item.id);
  }

  static void tryPurchase(BuildContext context, ShopProvider shop, ShopItem item) {
    if (shop.ownsItem(item.id)) return;
    _purchase(context, shop, item);
  }

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopProvider>();

    if (owned && (item.type == ShopItemType.theme || item.type == ShopItemType.background || item.type == ShopItemType.skin)) {
      return Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          if (!isActive)
            _ActionChip(
              label: AppStrings.t(context, 'apply'),
              filled: true,
              onTap: () {
                if (item.type == ShopItemType.theme) {
                  shop.selectTheme(item.id);
                } else if (item.type == ShopItemType.background) {
                  shop.selectBackground(item.id);
                } else {
                  shop.selectSkin(item.id);
                }
                AppToast.show(context, title: AppStrings.t(context, 'applied'));
              },
            ),
          if (isActive)
            _ActionChip(
              label: AppStrings.t(context, 'resetDefault'),
              onTap: () async {
                if (item.type == ShopItemType.theme) {
                  await shop.resetThemeToDefault();
                } else if (item.type == ShopItemType.background) {
                  await shop.resetBackgroundToDefault();
                } else {
                  await shop.resetSkinToDefault();
                }
                AppToast.show(context, title: AppStrings.t(context, 'resetToDefault'));
              },
            ),
        ],
      );
    }

    if (owned) {
      return Row(
        children: [
          Icon(Icons.verified_rounded, color: AppColors.success, size: dense ? 16 : 18),
          const SizedBox(width: 6),
          Text(AppStrings.t(context, 'owned'), style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: dense ? 11 : 13)),
        ],
      );
    }

    if (item.id == 'remove_ads' && shop.isBillingAvailable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StarPriceButton(item: item, dense: dense),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: shop.isPurchasing
                ? null
                : () async {
                    final ok = await shop.buyRemoveAdsViaBilling();
                    if (!context.mounted) return;
                    if (ok) {
                      AppToast.show(context, title: AppStrings.t(context, 'openingBilling'));
                    } else if (shop.lastMessage != null) {
                      AppToast.show(context, title: AppStrings.t(context, shop.lastMessage!));
                    }
                  },
            child: Text(
              '${AppStrings.t(context, 'removeAdsIap')}${shop.billing.removeAdsProduct != null ? ' · ${shop.billing.removeAdsProduct!.price}' : ''}',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: dense ? 10 : 11),
            ),
          ),
        ],
      );
    }

    return _StarPriceButton(item: item, dense: dense);
  }

  static void _purchase(BuildContext context, ShopProvider shop, ShopItem item) {
    final result = shop.buyWithCoins(item.id);
    switch (result) {
      case ShopPurchaseResult.success:
        final applied = item.type == ShopItemType.theme ||
            item.type == ShopItemType.background ||
            item.type == ShopItemType.skin;
        AppToast.show(
          context,
          title: AppStrings.t(context, applied ? 'applied' : 'purchaseSuccess'),
          message: applied ? AppStrings.t(context, item.nameKey) : null,
        );
      case ShopPurchaseResult.insufficientCoins:
        AppToast.show(context, title: AppStrings.t(context, 'insufficientCoins'), icon: Icons.warning_amber_rounded, color: AppColors.warning);
        if (!shop.isBillingDisabled) CoinPurchaseSheet.show(context);
      case ShopPurchaseResult.alreadyOwned:
        AppToast.show(context, title: AppStrings.t(context, 'alreadyOwned'));
      case ShopPurchaseResult.notFound:
      case ShopPurchaseResult.error:
        AppToast.show(context, title: AppStrings.t(context, 'purchaseFailed'));
    }
  }
}

class _StarPriceButton extends StatelessWidget {
  final ShopItem item;
  final bool dense;

  const _StarPriceButton({required this.item, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final shop = context.read<ShopProvider>();
    final canAfford = shop.coins >= item.price;

    return Material(
      color: canAfford ? AppColors.coin.withValues(alpha: 0.15) : AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _RewardActions._purchase(context, shop, item),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: dense ? 10 : 14, vertical: dense ? 8 : 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star_rounded, size: dense ? 14 : 16, color: canAfford ? AppColors.coin : AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                '${item.price}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: dense ? 12 : 14,
                  color: canAfford ? AppColors.onSurface : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _ActionChip({required this.label, required this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: filled ? null : Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: filled ? Colors.white : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfigBanner extends StatelessWidget {
  final IapConfigStatus status;

  const _ConfigBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final text = status == IapConfigStatus.timeout
        ? AppStrings.t(context, 'configTimeout')
        : AppStrings.t(context, 'configNetworkError');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_tethering_error_rounded, size: 18, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 11, color: AppColors.warning, height: 1.3))),
        ],
      ),
    );
  }
}
