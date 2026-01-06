import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'cache_service.dart';
import 'package_file_service.dart';

class PurchaseService {
  final InAppPurchase? _iap = kIsWeb ? null : InAppPurchase.instance;
  static const String _purchasedPackagesKey = 'purchased_packages';
  static const String _testModeKey = 'test_purchase_mode';

  Set<String> _productIds = {'more_questions', 'history'};

  List<ProductDetails> _products = [];
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  bool _isAvailable = false;
  bool _testMode = false;

  Future<void> Function(String packageId, bool success, String? error)? onPurchaseUpdated;

  PurchaseService() {
    _loadTestMode();
    _init();
  }

  Future<void> _loadTestMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTestMode = prefs.getBool(_testModeKey);
      if (savedTestMode != null) {
        _testMode = savedTestMode;
      } else {
        _testMode = true;
        await prefs.setBool(_testModeKey, true);
      }
    } catch (e) {
      _testMode = true;
    }
  }

  Future<void> setTestMode(bool enabled) async {
    _testMode = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_testModeKey, enabled);
    } catch (e) {
    }
  }

  bool getTestMode() => _testMode;

  Future<void> _init() async {
    if (kIsWeb || _iap == null) {
      _isAvailable = false;
      if (!_testMode) {
        await _enableTestMode();
      }
      return;
    }

    try {
      _isAvailable = await _iap!.isAvailable();
      if (!_isAvailable) {
        if (!_testMode) {
          await _enableTestMode();
        }
        return;
      }
    } catch (e) {
      _isAvailable = false;
      if (!_testMode) {
        await _enableTestMode();
      }
      return;
    }

    await loadProducts();
    
    if (_products.isEmpty && !_testMode) {
      await _enableTestMode();
    }

    _purchaseSubscription = _iap!.purchaseStream.listen(
      _listenToPurchaseUpdated,
      onDone: () {
        _purchaseSubscription?.cancel();
      },
      onError: (error) {
      },
    );
  }

  Future<void> _enableTestMode() async {
    _testMode = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_testModeKey, true);
    } catch (e) {
    }
  }

  Future<void> loadProducts() async {
    if (!_isAvailable || _iap == null) return;

    try {
      final ProductDetailsResponse response =
          await _iap!.queryProductDetails(_productIds);

      _products = response.productDetails;
      
      if (response.notFoundIDs.isNotEmpty && !_testMode) {
        await _enableTestMode();
      }
    } catch (e) {
      if (!_testMode) {
        await _enableTestMode();
      }
    }
  }

  Future<void> updateProductIds(Set<String> packageIds) async {
    _productIds = packageIds;
    await loadProducts();
  }

  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {

        await onPurchaseUpdated?.call(
          purchaseDetails.productID,
          false,
          null,
        );
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {

          await onPurchaseUpdated?.call(
            purchaseDetails.productID,
            false,
            purchaseDetails.error?.message ?? 'Ошибка покупки',
          );
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {

          await _handleSuccessfulPurchase(purchaseDetails);
        }

        if (purchaseDetails.pendingCompletePurchase && _iap != null) {
          _iap!.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<void> _handleSuccessfulPurchase(
      PurchaseDetails purchaseDetails) async {
    final productId = purchaseDetails.productID;
    
    final prefs = await SharedPreferences.getInstance();
    final packageIdKey = prefs.getString('product_${productId}_packageId');
    final packageId = packageIdKey ?? productId;

    await markPackageAsPurchased(packageId);
    CacheService.instance.clearCache();
    await onPurchaseUpdated?.call(packageId, true, null);
  }

  Future<bool> isPackagePurchased(String packageId) async {
    final prefs = await SharedPreferences.getInstance();
    final purchased = prefs.getStringList(_purchasedPackagesKey) ?? [];

    if (purchased.contains(packageId)) {
      return true;
    }

    if (_testMode || !_isAvailable) {
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

  Future<bool> buyPackage(String packageId, {String? productId}) async {
    final actualProductId = productId ?? packageId;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('product_${actualProductId}_packageId', packageId);
    if (_testMode || kIsWeb) {
      await Future.delayed(const Duration(milliseconds: 500));
      await markPackageAsPurchased(packageId);
      CacheService.instance.clearCache();
      final packageFileService = PackageFileService();
      try {
        await packageFileService.clearCacheForPackage(packageId);
      } catch (e) {
      }
      await onPurchaseUpdated?.call(packageId, true, null);
      return true;
    }

    if (!_isAvailable) {
      if (!_testMode) {
        await _enableTestMode();
      }
      if (_testMode) {
        await Future.delayed(const Duration(milliseconds: 500));
        await markPackageAsPurchased(packageId);
        CacheService.instance.clearCache();
        final packageFileService = PackageFileService();
        try {
          await packageFileService.clearCacheForPackage(packageId);
        } catch (e) {
        }
        await onPurchaseUpdated?.call(packageId, true, null);
        return true;
      }
      await onPurchaseUpdated?.call(packageId, false, 'Покупки недоступны');
      return false;
    }

    try {
      var product = _products.firstWhere(
        (p) => p.id == actualProductId,
        orElse: () => throw Exception('not_found'),
      );

      if (product.id != actualProductId) {
        _productIds.add(actualProductId);
        await loadProducts();
        product = _products.firstWhere(
          (p) => p.id == actualProductId,
          orElse: () => throw Exception('Продукт не найден: $actualProductId'),
        );
      }

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      final bool success = await _iap!.buyNonConsumable(
        purchaseParam: purchaseParam,
      );

      if (!success) {
        await onPurchaseUpdated?.call(
          packageId,
          false,
          'Не удалось инициировать покупку',
        );
      }

      return success;
    } catch (e) {
      if (e.toString().contains('not_found')) {
        try {
          _productIds.add(actualProductId);
          await loadProducts();
          final product = _products.firstWhere(
            (p) => p.id == actualProductId,
            orElse: () => throw Exception('Продукт не найден в Google Play: $actualProductId'),
          );

          final PurchaseParam purchaseParam = PurchaseParam(
            productDetails: product,
          );

          final bool success = await _iap!.buyNonConsumable(
            purchaseParam: purchaseParam,
          );

          if (!success) {
            await onPurchaseUpdated?.call(
              packageId,
              false,
              'Не удалось инициировать покупку',
            );
          }

          return success;
        } catch (e2) {
          await onPurchaseUpdated?.call(
            packageId,
            false,
            e2.toString(),
          );
          return false;
        }
      } else {
        if (!_testMode && (e.toString().contains('не найден') || e.toString().contains('not found'))) {
          await _enableTestMode();
          await Future.delayed(const Duration(milliseconds: 500));
          await markPackageAsPurchased(packageId);
          CacheService.instance.clearCache();
          final packageFileService = PackageFileService();
          try {
            await packageFileService.clearCacheForPackage(packageId);
          } catch (e2) {
          }
          await onPurchaseUpdated?.call(packageId, true, null);
          return true;
        }
        await onPurchaseUpdated?.call(
          packageId,
          false,
          e.toString(),
        );
        return false;
      }
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

