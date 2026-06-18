import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../core/constants/iap_constants.dart';
import '../core/services/billing_service.dart';
import '../core/services/iap_config_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/storage_service.dart';
import '../models/app_theme_preset.dart';
import '../models/food_item.dart';
import '../models/shop_coin_event.dart';
import '../models/shop_item.dart';

enum ShopPurchaseResult {
  success,
  insufficientCoins,
  alreadyOwned,
  notFound,
  error,
}

class ShopProvider extends ChangeNotifier {
  static const _coinsKey = 'pp_coins';
  static const _ownedKey = 'pp_owned_items';
  static const _activeThemeKey = 'pp_active_theme';
  static const _activeBgKey = 'pp_active_background';
  static const _activeSkinKey = 'pp_active_skin';
  static const _lastDailyKey = 'pp_last_daily_reward';
  static const _addFoodRewardDateKey = 'pp_add_food_reward_date';
  static const _addFoodRewardCountKey = 'pp_add_food_reward_count';
  static const _shoppingRewardDateKey = 'pp_shopping_reward_date';
  static const _shoppingRewardCountKey = 'pp_shopping_reward_count';
  static const _shareRewardDateKey = 'pp_share_reward_date';
  static const _shareRewardCountKey = 'pp_share_reward_count';
  static const _cleanupRewardDateKey = 'pp_cleanup_reward_date';
  static const _cleanupRewardCountKey = 'pp_cleanup_reward_count';
  static const _processedPurchasesKey = 'pp_processed_purchases';
  static const _categoryColorsKey = 'pp_category_colors';

  final IapConfigService _configService = IapConfigService();
  final BillingService _billing = BillingService();

  int _coins = 0;
  Set<String> _ownedItems = {};
  Map<String, int> _categoryColorOverrides = {};
  String _activeThemeId = ShopCatalog.defaultThemeId;
  String _activeBackgroundId = ShopCatalog.defaultBackgroundId;
  String _activeSkinId = ShopCatalog.defaultSkinId;
  bool _isPurchasing = false;
  bool _isLoading = true;
  String? _lastMessage;
  Set<String> _processedPurchaseIds = {};
  ShopCoinEvent? _lastCoinEvent;

  int get coins => _coins;
  Set<String> get ownedItems => _ownedItems;
  String get activeThemeId => _activeThemeId;
  String get activeBackgroundId => _activeBackgroundId;
  String get activeSkinId => _activeSkinId;
  bool get isPurchasing => _isPurchasing;
  bool get isLoading => _isLoading;
  String? get lastMessage => _lastMessage;
  ShopCoinEvent? get lastCoinEvent => _lastCoinEvent;
  IapConfigService get configService => _configService;
  BillingService get billing => _billing;

  bool get isBillingDisabled => _configService.isBillingDisabled;
  bool get isBillingAvailable =>
      !isBillingDisabled && _billing.isAvailable && _billing.products.isNotEmpty;
  IapConfigStatus get configStatus => _configService.status;

  bool get hasRemoveAds => _ownedItems.contains('remove_ads');
  bool get hasUnlimitedItems => _ownedItems.contains('feat_unlimited_items');
  bool get hasAdvancedAlerts => _ownedItems.contains('feat_advanced_alerts');
  bool get hasExportData => _ownedItems.contains('feat_export_data');
  bool get hasCustomCategories => _ownedItems.contains('feat_custom_categories');
  bool get hasBulkAdd => _ownedItems.contains('feat_bulk_add');
  bool get hasNoWatermark => _ownedItems.contains('feat_no_watermark');

  AppThemePreset get activeTheme => AppThemePresets.get(_activeThemeId);
  AppBackground get activeBackground => AppBackground.get(_activeBackgroundId);
  CardStyle get activeCardStyle => CardStyle.get(_activeSkinId);

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _loadLocal();
    await _configService.fetch();

    if (!isBillingDisabled && (Platform.isAndroid || Platform.isIOS)) {
      await _billing.init(
        onPurchase: _handlePurchase,
        onError: () => notifyListeners(),
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshConfig() async {
    await _configService.fetch(forceRefresh: true);
    notifyListeners();
  }

  Future<void> _loadLocal() async {
    _coins = await StorageService.instance.getInt(_coinsKey) ?? 0;
    final owned = await StorageService.instance.getStringList(_ownedKey);
    _ownedItems = owned?.toSet() ?? {};
    _activeThemeId =
        await StorageService.instance.getString(_activeThemeKey) ?? ShopCatalog.defaultThemeId;
    _activeBackgroundId =
        await StorageService.instance.getString(_activeBgKey) ?? ShopCatalog.defaultBackgroundId;
    _activeSkinId =
        await StorageService.instance.getString(_activeSkinKey) ?? ShopCatalog.defaultSkinId;
    final processed = await StorageService.instance.getStringList(_processedPurchasesKey);
    _processedPurchaseIds = processed?.toSet() ?? {};
    final colors = await StorageService.instance.getData(_categoryColorsKey);
    if (colors != null) {
      _categoryColorOverrides = colors.map((k, v) => MapEntry(k, (v as num).toInt()));
    }
  }

  Future<void> _saveLocal() async {
    await StorageService.instance.saveInt(_coinsKey, _coins);
    await StorageService.instance.saveStringList(_ownedKey, _ownedItems.toList());
    await StorageService.instance.saveString(_activeThemeKey, _activeThemeId);
    await StorageService.instance.saveString(_activeBgKey, _activeBackgroundId);
    await StorageService.instance.saveString(_activeSkinKey, _activeSkinId);
    await StorageService.instance.saveStringList(_processedPurchasesKey, _processedPurchaseIds.toList());
  }

  bool ownsItem(String id) => _ownedItems.contains(id);

  Color categoryColor(FoodCategory category) {
    if (hasCustomCategories) {
      final override = _categoryColorOverrides[category.id];
      if (override != null) return Color(override);
    }
    return category.color;
  }

  Future<void> setCategoryColor(FoodCategory category, Color color) async {
    if (!hasCustomCategories) return;
    _categoryColorOverrides[category.id] = color.toARGB32();
    await StorageService.instance.saveData(
      _categoryColorsKey,
      _categoryColorOverrides.map((k, v) => MapEntry(k, v)),
    );
    notifyListeners();
  }

  Future<void> resetCategoryColors() async {
    if (!hasCustomCategories) return;
    _categoryColorOverrides.clear();
    await StorageService.instance.remove(_categoryColorsKey);
    notifyListeners();
  }

  ShopPurchaseResult buyWithCoins(String itemId) {
    final item = ShopCatalog.find(itemId);
    if (item == null) return ShopPurchaseResult.notFound;
    if (item.oneTime && _ownedItems.contains(itemId)) {
      return ShopPurchaseResult.alreadyOwned;
    }
    if (_coins < item.price) return ShopPurchaseResult.insufficientCoins;

    _coins -= item.price;
    _ownedItems.add(itemId);
    _applyItem(item);
    _lastMessage = 'purchaseSuccess';
    _saveLocal();
    if (item.id == 'feat_advanced_alerts') {
      unawaited(_rescheduleNotifications());
    }
    notifyListeners();
    return ShopPurchaseResult.success;
  }

  void _applyItem(ShopItem item) {
    switch (item.type) {
      case ShopItemType.theme:
        _activeThemeId = item.id;
      case ShopItemType.background:
        _activeBackgroundId = item.id;
      case ShopItemType.skin:
        _activeSkinId = item.id;
      case ShopItemType.removeAds:
      case ShopItemType.feature:
        break;
    }
  }

  Future<bool> buyCoinPack(ProductDetails product) async {
    if (isBillingDisabled || !_billing.isAvailable) return false;
    _isPurchasing = true;
    _lastMessage = null;
    notifyListeners();
    final ok = await _billing.buyCoinPack(product);
    if (!ok) {
      _isPurchasing = false;
      _lastMessage = 'purchaseFailed';
      notifyListeners();
    }
    return ok;
  }

  Future<bool> buyRemoveAdsViaBilling() async {
    if (isBillingDisabled || !_billing.isAvailable || _billing.removeAdsProduct == null) {
      return false;
    }
    if (hasRemoveAds) return false;
    _isPurchasing = true;
    _lastMessage = null;
    notifyListeners();
    final ok = await _billing.buyRemoveAds();
    if (!ok) {
      _isPurchasing = false;
      _lastMessage = 'purchaseFailed';
      notifyListeners();
    }
    return ok;
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    final purchaseId = purchase.purchaseID ?? '${purchase.productID}_${purchase.transactionDate}';
    if (_processedPurchaseIds.contains(purchaseId)) {
      _isPurchasing = false;
      notifyListeners();
      return;
    }

    if (IapConstants.isRemoveAdsProduct(purchase.productID)) {
      _ownedItems.add('remove_ads');
      _processedPurchaseIds.add(purchaseId);
      _lastMessage = 'removeAdsUnlocked';
    } else {
      final coins = IapConstants.coinsForProduct(purchase.productID);
      if (coins > 0) {
        _coins += coins;
        _processedPurchaseIds.add(purchaseId);
        _lastMessage = 'coinsAdded';
        _emitCoinEarned(coins, 'coinsAdded');
      }
    }

    _isPurchasing = false;
    await _saveLocal();
    notifyListeners();
  }

  Future<bool> claimDailyReward() async {
    final today = _dateKey(DateTime.now());
    final last = await StorageService.instance.getString(_lastDailyKey);
    if (last == today) return false;

    const amount = IapConstants.dailyLoginReward;
    _coins += amount;
    await StorageService.instance.saveString(_lastDailyKey, today);
    _lastMessage = 'dailyRewardClaimed';
    _emitCoinEarned(amount, 'dailyRewardClaimed');
    await _saveLocal();
    notifyListeners();
    return true;
  }

  Future<bool> hasClaimedDailyToday() async {
    final today = _dateKey(DateTime.now());
    final last = await StorageService.instance.getString(_lastDailyKey);
    return last == today;
  }

  Future<bool> rewardForAddFood() async {
    final today = _dateKey(DateTime.now());
    final savedDate = await StorageService.instance.getString(_addFoodRewardDateKey);
    var count = await StorageService.instance.getInt(_addFoodRewardCountKey) ?? 0;

    if (savedDate != today) {
      count = 0;
      await StorageService.instance.saveString(_addFoodRewardDateKey, today);
    }

    if (count >= IapConstants.maxAddFoodRewardsPerDay) return false;

    const amount = IapConstants.addFoodReward;
    _coins += amount;
    count++;
    await StorageService.instance.saveInt(_addFoodRewardCountKey, count);
    _emitCoinEarned(amount, 'addFoodRewardEarned');
    await _saveLocal();
    notifyListeners();
    return true;
  }

  Future<bool> rewardForShoppingDone() async {
    final today = _dateKey(DateTime.now());
    final savedDate = await StorageService.instance.getString(_shoppingRewardDateKey);
    var count = await StorageService.instance.getInt(_shoppingRewardCountKey) ?? 0;

    if (savedDate != today) {
      count = 0;
      await StorageService.instance.saveString(_shoppingRewardDateKey, today);
    }

    if (count >= IapConstants.maxShoppingRewardsPerDay) return false;

    const amount = IapConstants.shoppingDoneReward;
    _coins += amount;
    count++;
    await StorageService.instance.saveInt(_shoppingRewardCountKey, count);
    _emitCoinEarned(amount, 'shoppingRewardEarned');
    await _saveLocal();
    notifyListeners();
    return true;
  }

  Future<bool> rewardForShare() async {
    final today = _dateKey(DateTime.now());
    final savedDate = await StorageService.instance.getString(_shareRewardDateKey);
    var count = await StorageService.instance.getInt(_shareRewardCountKey) ?? 0;

    if (savedDate != today) {
      count = 0;
      await StorageService.instance.saveString(_shareRewardDateKey, today);
    }

    if (count >= IapConstants.maxShareRewardsPerDay) return false;

    const amount = IapConstants.shareListReward;
    _coins += amount;
    count++;
    await StorageService.instance.saveInt(_shareRewardCountKey, count);
    _emitCoinEarned(amount, 'shareRewardEarned');
    await _saveLocal();
    notifyListeners();
    return true;
  }

  Future<bool> rewardForCleanup(int removedCount) async {
    if (removedCount <= 0) return false;

    final today = _dateKey(DateTime.now());
    final savedDate = await StorageService.instance.getString(_cleanupRewardDateKey);
    var count = await StorageService.instance.getInt(_cleanupRewardCountKey) ?? 0;

    if (savedDate != today) {
      count = 0;
      await StorageService.instance.saveString(_cleanupRewardDateKey, today);
    }

    if (count >= IapConstants.maxCleanupRewardsPerDay) return false;

    const amount = IapConstants.cleanupReward;
    _coins += amount;
    count++;
    await StorageService.instance.saveInt(_cleanupRewardCountKey, count);
    _emitCoinEarned(amount, 'cleanupRewardEarned');
    await _saveLocal();
    notifyListeners();
    return true;
  }

  Future<void> selectTheme(String themeId) async {
    if (themeId != ShopCatalog.defaultThemeId && !_ownedItems.contains(themeId)) return;
    _activeThemeId = themeId;
    await _saveLocal();
    notifyListeners();
  }

  Future<void> selectBackground(String bgId) async {
    if (bgId != ShopCatalog.defaultBackgroundId && !_ownedItems.contains(bgId)) return;
    _activeBackgroundId = bgId;
    await _saveLocal();
    notifyListeners();
  }

  Future<void> selectSkin(String skinId) async {
    if (skinId != ShopCatalog.defaultSkinId && !_ownedItems.contains(skinId)) return;
    _activeSkinId = skinId;
    await _saveLocal();
    notifyListeners();
  }

  Future<void> resetThemeToDefault() => selectTheme(ShopCatalog.defaultThemeId);
  Future<void> resetBackgroundToDefault() => selectBackground(ShopCatalog.defaultBackgroundId);
  Future<void> resetSkinToDefault() => selectSkin(ShopCatalog.defaultSkinId);

  void clearLastMessage() => _lastMessage = null;
  void clearCoinEvent() => _lastCoinEvent = null;

  void _emitCoinEarned(int amount, String messageKey) {
    if (amount <= 0) return;
    _lastCoinEvent = ShopCoinEvent(amount: amount, messageKey: messageKey);
  }

  Future<void> _rescheduleNotifications() async {
    final raw = await StorageService.instance.getString('pp_food_items');
    if (raw == null || raw.isEmpty) return;
    final items = StorageService.decodeList(raw).map(FoodItem.fromJson).toList();
    await NotificationService.instance.scheduleExpiryAlerts(items);
  }

  String _dateKey(DateTime dt) => '${dt.year}-${dt.month}-${dt.day}';

  @override
  void dispose() {
    _billing.dispose();
    super.dispose();
  }
}
