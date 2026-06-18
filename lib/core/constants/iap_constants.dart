class IapConstants {
  IapConstants._();

  static const String productPrefix = 'pp';

  static const String remoteConfigUrl = 'https://api2.blwsmartware.net/N205.json';

  static const Duration configTimeout = Duration(seconds: 10);

  static const List<String> coinPackIds = [
    'pp_pack_1',
    'pp_pack_2',
    'pp_pack_3',
    'pp_pack_4',
    'pp_pack_5',
    'pp_pack_6',
    'pp_pack_7',
    'pp_pack_8',
    'pp_pack_9',
    'pp_pack_10',
  ];

  static const String removeAdsProductId = 'pp_remove_ads';

  static List<String> get allProductIds => [...coinPackIds, removeAdsProductId];

  static const List<int> coinPackAmounts = [
    50,
    100,
    200,
    350,
    500,
    750,
    1000,
    1500,
    2200,
    3000,
  ];

  static int coinsForProduct(String productId) {
    final index = coinPackIds.indexOf(productId);
    if (index < 0) return 0;
    return coinPackAmounts[index];
  }

  static bool isRemoveAdsProduct(String productId) => productId == removeAdsProductId;

  static const int freeItemLimit = 30;
  static const int dailyLoginReward = 10;
  static const int addFoodReward = 3;
  static const int maxAddFoodRewardsPerDay = 10;
  static const int shoppingDoneReward = 2;
  static const int maxShoppingRewardsPerDay = 8;
  static const int shareListReward = 5;
  static const int maxShareRewardsPerDay = 3;
  static const int cleanupReward = 4;
  static const int maxCleanupRewardsPerDay = 5;
}
