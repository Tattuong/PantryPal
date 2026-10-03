import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../constants/iap_constants.dart';

typedef PurchaseCallback = Future<void> Function(PurchaseDetails purchase);

class BillingService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool isAvailable = false;
  bool isInitialized = false;
  List<ProductDetails> coinProducts = [];
  ProductDetails? removeAdsProduct;
  String? lastError;

  List<ProductDetails> get products => coinProducts;

  Future<void> init({
    required PurchaseCallback onPurchase,
    required VoidCallback onError,
    required VoidCallback onCanceled,
  }) async {
    if (isInitialized) return;

    try {
      isAvailable = await _iap.isAvailable();
      if (!isAvailable) {
        lastError = 'Billing not available on this device';
        isInitialized = true;
        return;
      }

      _subscription?.cancel();
      _subscription = _iap.purchaseStream.listen(
        (purchases) async {
          for (final purchase in purchases) {
            if (purchase.status == PurchaseStatus.pending) continue;

            if (purchase.status == PurchaseStatus.purchased ||
                purchase.status == PurchaseStatus.restored) {
              try {
                await onPurchase(purchase);
              } catch (e) {
                lastError = e.toString();
                debugPrint('Purchase handler error: $e');
                onError();
              }
            } else if (purchase.status == PurchaseStatus.canceled) {
              onCanceled();
            } else if (purchase.status == PurchaseStatus.error) {
              lastError = purchase.error?.message ?? 'Purchase failed';
              onError();
            }

            // A user-cancel update is a plain PurchaseDetails with an empty id.
            // completePurchase expects a store purchase and throws on that object.
            if (purchase.pendingCompletePurchase &&
                (purchase.purchaseID?.isNotEmpty ?? false)) {
              try {
                await _iap.completePurchase(purchase);
              } catch (e) {
                debugPrint('completePurchase error: $e');
              }
            }
          }
        },
        onError: (Object e) {
          lastError = e.toString();
          onError();
        },
      );

      await loadProducts();
      isInitialized = true;
    } catch (e) {
      lastError = e.toString();
      debugPrint('Billing init error: $e');
      isInitialized = true;
    }
  }

  Future<void> loadProducts() async {
    if (!isAvailable) return;

    final response = await _iap.queryProductDetails(IapConstants.allProductIds.toSet());
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('Products not found: ${response.notFoundIDs}');
    }
    if (response.error != null) {
      lastError = response.error!.message;
    }

    coinProducts = response.productDetails
        .where((p) => IapConstants.coinPackIds.contains(p.id))
        .toList()
      ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));

    removeAdsProduct = response.productDetails
        .where((p) => p.id == IapConstants.removeAdsProductId)
        .firstOrNull;
  }

  Future<bool> buyCoinPack(ProductDetails product) async {
    if (!isAvailable) return false;
    try {
      final param = PurchaseParam(productDetails: product);
      return await _iap.buyConsumable(purchaseParam: param);
    } catch (e) {
      lastError = e.toString();
      debugPrint('buyCoinPack error: $e');
      return false;
    }
  }

  Future<bool> buyRemoveAds() async {
    if (!isAvailable || removeAdsProduct == null) return false;
    try {
      final param = PurchaseParam(productDetails: removeAdsProduct!);
      return await _iap.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      lastError = e.toString();
      debugPrint('buyRemoveAds error: $e');
      return false;
    }
  }

  Future<void> restorePurchases() async {
    if (!isAvailable) return;
    await _iap.restorePurchases();
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
