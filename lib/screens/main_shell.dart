import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../widgets/ad_banner_slot.dart';
import 'pantry/pantry_screen.dart';
import 'settings/settings_screen.dart';
import 'shop/shop_screen.dart';
import 'shopping/shopping_list_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static MainShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<MainShellState>();

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _index = 0;
  ShopRewardsTab _shopTab = ShopRewardsTab.all;
  int _shopTabRequest = 0;

  void openShop({ShopRewardsTab tab = ShopRewardsTab.all}) {
    setState(() {
      _index = 2;
      _shopTab = tab;
      _shopTabRequest++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final screens = [
      const PantryScreen(),
      const ShoppingListScreen(),
      ShopScreen(
        embedded: true,
        active: _index == 2,
        requestedTab: _shopTab,
        tabRequest: _shopTabRequest,
      ),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AdBannerSlot(),
          SafeArea(
            top: false,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, -2))
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  children: [
                    _NavItem(
                        icon: Icons.kitchen_outlined,
                        activeIcon: Icons.kitchen_rounded,
                        label: AppStrings.t(context, 'navPantry'),
                        active: _index == 0,
                        primary: primary,
                        onTap: () => setState(() => _index = 0)),
                    _NavItem(
                        icon: Icons.shopping_basket_outlined,
                        activeIcon: Icons.shopping_basket_rounded,
                        label: AppStrings.t(context, 'navShopping'),
                        active: _index == 1,
                        primary: primary,
                        onTap: () => setState(() => _index = 1)),
                    _NavItem(
                        icon: Icons.stars_outlined,
                        activeIcon: Icons.stars_rounded,
                        label: AppStrings.t(context, 'navShop'),
                        active: _index == 2,
                        primary: primary,
                        onTap: () => setState(() => _index = 2)),
                    _NavItem(
                        icon: Icons.settings_outlined,
                        activeIcon: Icons.settings_rounded,
                        label: AppStrings.t(context, 'navSettings'),
                        active: _index == 3,
                        primary: primary,
                        onTap: () => setState(() => _index = 3)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final Color primary;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color:
                active ? primary.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(active ? activeIcon : icon,
                  color: active ? primary : AppColors.onSurfaceVariant,
                  size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                  color: active ? primary : AppColors.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
