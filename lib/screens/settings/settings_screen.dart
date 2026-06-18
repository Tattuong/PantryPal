import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/food_item.dart';
import '../../providers/locale_provider.dart';
import '../../providers/pantry_provider.dart';
import '../../providers/shopping_provider.dart';
import '../../providers/shop_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/coin_balance_chip.dart';
import '../../widgets/coin_purchase_sheet.dart';
import '../main_shell.dart';
import '../privacy_policy_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shop = context.watch<ShopProvider>();
    final theme = context.watch<ThemeProvider>();
    final locale = context.watch<LocaleProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(AppStrings.t(context, 'settingsTitle')),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CoinBalanceChip(onTap: () => CoinPurchaseSheet.show(context)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle(AppStrings.t(context, 'activeCustomization')),
          _InfoTile(
            icon: Icons.palette_outlined,
            title: AppStrings.t(context, 'activeTheme'),
            subtitle: AppStrings.t(context, _themeNameKey(shop.activeThemeId)),
          ),
          _InfoTile(
            icon: Icons.layers_outlined,
            title: AppStrings.t(context, 'activeBackground'),
            subtitle: AppStrings.t(context, _bgNameKey(shop.activeBackgroundId)),
          ),
          _InfoTile(
            icon: Icons.style_outlined,
            title: AppStrings.t(context, 'activeSkin'),
            subtitle: AppStrings.t(context, _skinNameKey(shop.activeSkinId)),
          ),
          const SizedBox(height: 16),
          _SectionTitle(AppStrings.t(context, 'appearance')),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: Text(AppStrings.t(context, 'darkMode')),
            value: theme.isDarkMode,
            onChanged: (_) => theme.toggleTheme(),
          ),
          const SizedBox(height: 16),
          _SectionTitle(AppStrings.t(context, 'premiumFeatures')),
          if (shop.hasExportData)
            ListTile(
              leading: const Icon(Icons.file_download_outlined),
              title: Text(AppStrings.t(context, 'exportData')),
              subtitle: Text(AppStrings.t(context, 'exportDataDesc')),
              trailing: const Icon(Icons.share_outlined),
              onTap: () => _exportData(context),
            ),
          if (shop.hasCustomCategories) ...[
            ListTile(
              leading: const Icon(Icons.color_lens_outlined),
              title: Text(AppStrings.t(context, 'customCategoryColors')),
              subtitle: Text(AppStrings.t(context, 'customCategoryColorsDesc')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _pickCategoryColors(context, shop),
            ),
          ],
          if (shop.hasAdvancedAlerts)
            ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: Text(AppStrings.t(context, 'advancedAlertsActive')),
              subtitle: Text(AppStrings.t(context, 'advancedAlertsActiveDesc')),
            ),
          const SizedBox(height: 16),
          _SectionTitle(AppStrings.t(context, 'other')),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: Text(AppStrings.t(context, 'language')),
            subtitle: Text(locale.isVietnamese ? AppStrings.t(context, 'vietnamese') : AppStrings.t(context, 'english')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickLanguage(context, locale),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined),
            title: Text(AppStrings.t(context, 'resetData')),
            subtitle: Text(AppStrings.t(context, 'resetDataDesc')),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(AppStrings.t(context, 'resetData')),
                  content: Text(AppStrings.t(context, 'resetDataConfirm')),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.t(context, 'cancel'))),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppStrings.t(context, 'save'))),
                  ],
                ),
              );
              if (ok == true) {
                await context.read<PantryProvider>().removeExpired();
                // Clear all data would need explicit methods - skip for now
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.stars_outlined),
            title: Text(AppStrings.t(context, 'openShop')),
            subtitle: Text(AppStrings.t(context, 'openShopDesc')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => MainShell.of(context)?.openShop(),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(AppStrings.t(context, 'privacyPolicy')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              AppStrings.t(context, 'copyright'),
              style: TextStyle(color: AppColors.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    final pantry = context.read<PantryProvider>();
    final shopping = context.read<ShoppingProvider>();
    final pantryText = pantry.exportAsText();
    final shoppingText = shopping.exportText();
    if (pantryText.isEmpty && shoppingText.isEmpty) {
      AppToast.show(context, title: AppStrings.t(context, 'exportEmpty'));
      return;
    }
    final buffer = StringBuffer('PantryPal Export\n\n');
    if (pantryText.isNotEmpty) buffer.writeln(pantryText);
    if (shoppingText.isNotEmpty) {
      buffer.writeln('--- Shopping list ---');
      buffer.writeln(shoppingText);
    }
    await Share.share(buffer.toString().trim());
    AppToast.show(context, title: AppStrings.t(context, 'exportDone'));
  }

  Future<void> _pickCategoryColors(BuildContext context, ShopProvider shop) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ListenableBuilder(
          listenable: shop,
          builder: (context, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(AppStrings.t(context, 'customCategoryColors'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 12),
                ...FoodCategory.values.map((cat) {
                  final color = shop.categoryColor(cat);
                  return ListTile(
                    leading: CircleAvatar(backgroundColor: color, radius: 16),
                    title: Text(AppStrings.t(context, 'cat_${cat.id}')),
                    trailing: Icon(Icons.colorize_outlined, color: color),
                    onTap: () async {
                      final picked = await showDialog<Color>(
                        context: ctx,
                        builder: (dCtx) => AlertDialog(
                          title: Text(AppStrings.t(context, 'pickColor')),
                          content: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: AppColors.categoryPalette.map((c) {
                              return GestureDetector(
                                onTap: () => Navigator.pop(dCtx, c),
                                child: CircleAvatar(backgroundColor: c, radius: 20),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                      if (picked != null) await shop.setCategoryColor(cat, picked);
                    },
                  );
                }),
                TextButton(
                  onPressed: () async {
                    await shop.resetCategoryColors();
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text(AppStrings.t(context, 'resetDefault')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickLanguage(BuildContext context, LocaleProvider locale) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 22)),
              title: Text(AppStrings.t(context, 'english')),
              trailing: !locale.isVietnamese ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
              onTap: () async {
                await locale.setEnglish();
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Text('🇻🇳', style: TextStyle(fontSize: 22)),
              title: Text(AppStrings.t(context, 'vietnamese')),
              trailing: locale.isVietnamese ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
              onTap: () async {
                await locale.setVietnamese();
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _themeNameKey(String id) => switch (id) {
        'theme_sunset' => 'shopThemeSunset',
        'theme_midnight' => 'shopThemeMidnight',
        'theme_tropical' => 'shopThemeTropical',
        'theme_sakura' => 'shopThemeSakura',
        _ => 'themeDefault',
      };

  String _bgNameKey(String id) => switch (id) {
        'bg_sunrise' => 'shopBgSunrise',
        'bg_ocean' => 'shopBgOcean',
        'bg_aurora' => 'shopBgAurora',
        'bg_galaxy' => 'shopBgGalaxy',
        _ => 'bgDefault',
      };

  String _skinNameKey(String id) => switch (id) {
        'skin_neon' => 'shopSkinNeon',
        'skin_classic' => 'shopSkinClassic',
        'skin_glass' => 'shopSkinGlass',
        _ => 'skinDefault',
      };
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.onSurfaceVariant)),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoTile({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
    );
  }
}
