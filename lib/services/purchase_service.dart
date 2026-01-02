import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:in_app_purchase/in_app_purchase.dart';

class PurchaseService {
  final InAppPurchase? _iap = kIsWeb ? null : InAppPurchase.instance;
  static const String _purchasedPackagesKey = 'purchased_packages';

  static const Set<String> _productIds = {'more_questions', 'history'};

  List<ProductDetails> _products = [];
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  bool _isAvailable = false;

  Function(String packageId, bool success, String? error)? onPurchaseUpdated;

  PurchaseService() {
    _init();
  }

  Future<void> _init() async {

    if (kIsWeb || _iap == null) {
      _isAvailable = false;
      return;
    }

    try {
      _isAvailable = await _iap!.isAvailable();
      if (!_isAvailable) {
        return;
      }
    } catch (e) {
      _isAvailable = false;
      return;
    }

    await loadProducts();

    _purchaseSubscription = _iap!.purchaseStream.listen(
      _listenToPurchaseUpdated,
      onDone: () {
        _purchaseSubscription?.cancel();
      },
      onError: (error) {
      },
    );
  }

  Future<void> loadProducts() async {
    if (!_isAvailable || _iap == null) return;

    try {
      final ProductDetailsResponse response =
          await _iap!.queryProductDetails(_productIds);

      _products = response.productDetails;
    } catch (e) {
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {

        onPurchaseUpdated?.call(
          purchaseDetails.productID,
          false,
          null,
        );
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {

          onPurchaseUpdated?.call(
            purchaseDetails.productID,
            false,
            purchaseDetails.error?.message ?? 'Ошибка покупки',
          );
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {

          _handleSuccessfulPurchase(purchaseDetails);
        }

        if (purchaseDetails.pendingCompletePurchase && _iap != null) {
          _iap!.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<void> _handleSuccessfulPurchase(
      PurchaseDetails purchaseDetails) async {
    final packageId = purchaseDetails.productID;

    await markPackageAsPurchased(packageId);
    onPurchaseUpdated?.call(packageId, true, null);
  }

  Future<bool> isPackagePurchased(String packageId) async {

    final prefs = await SharedPreferences.getInstance();
    final purchased = prefs.getStringList(_purchasedPackagesKey) ?? [];

    if (purchased.contains(packageId)) {
      return true;
    }

    if (!_isAvailable) {
      return false;
    }

    return false;
  }

  Future<void> markPackageAsPurchased(String packageId) async {
    final prefs = await SharedPreferences.getInstance();
    final purchased = prefs.getStringList(_purchasedPackagesKey) ?? [];
    if (!purchased.contains(packageId)) {
      purchased.add(packageId);
      await prefs.setStringList(_purchasedPackagesKey, purchased);
    }
  }

  Future<bool> buyPackage(String packageId) async {
    if (!_isAvailable) {
      onPurchaseUpdated?.call(packageId, false, 'Покупки недоступны');
      return false;
    }

    final product = _products.firstWhere(
      (p) => p.id == packageId,
      orElse: () => throw Exception('Продукт не найден: $packageId'),
    );

    try {

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      final bool success = await _iap!.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (!success) {
        onPurchaseUpdated?.call(
          packageId,
          false,
          'Не удалось инициировать покупку',
        );
      }

      return success;
    } catch (e) {
      onPurchaseUpdated?.call(
        packageId,
        false,
        e.toString(),
      );
      return false;
    }
  }

  Future<void> restorePurchases() async {
    if (!_isAvailable) {
      return;
    }

    if (_iap == null) return;

    try {
      await _iap!.restorePurchases();
    } catch (e) {
    }
  }

  ProductDetails? getProductDetails(String packageId) {
    try {
      return _products.firstWhere((p) => p.id == packageId);
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _purchaseSubscription?.cancel();
  }
}

