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

  Set<String> _productIds = {};

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
        _testMode = kIsWeb;
        if (_testMode) {
          await prefs.setBool(_testModeKey, true);
        }
      }
    } catch (e) {
      _testMode = kIsWeb;
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
      if (_productIds.isEmpty) {
        return; // Нет продуктов для загрузки
      }
      
      final ProductDetailsResponse response =
          await _iap!.queryProductDetails(_productIds);

      // Проверяем, какие продукты не найдены
      if (response.notFoundIDs.isNotEmpty) {
        print('⚠️ Продукты не найдены в Google Play: ${response.notFoundIDs.join(", ")}');
        print('📦 Запрошенные product IDs: ${_productIds.join(", ")}');
      }
      
      if (response.error != null) {
        print('❌ Ошибка загрузки продуктов: ${response.error}');
      }

      _products = response.productDetails;
      
      if (_products.isNotEmpty) {
        print('✅ Загружено продуктов: ${_products.length}');
        print('📦 Найденные продукты: ${_products.map((p) => p.id).join(", ")}');
      }
    } catch (e) {
      print('❌ Исключение при загрузке продуктов: $e');
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
    print('✅ Успешная покупка: productId=$productId');
    
    final prefs = await SharedPreferences.getInstance();
    final packageIdKey = prefs.getString('product_${productId}_packageId');
    final packageId = packageIdKey ?? productId;
    print('📦 Сохранение покупки: productId=$productId -> packageId=$packageId');

    await markPackageAsPurchased(packageId);
    print('💾 Пакет $packageId помечен как купленный');
    CacheService.instance.clearCache();
    await onPurchaseUpdated?.call(packageId, true, null);
  }

  Future<bool> isPackagePurchased(String packageId) async {
    final prefs = await SharedPreferences.getInstance();
    final purchased = prefs.getStringList(_purchasedPackagesKey) ?? [];
    
    print('🔍 Проверка покупки пакета $packageId: купленные пакеты = [${purchased.join(", ")}]');

    if (purchased.contains(packageId)) {
      print('✅ Пакет $packageId найден в списке купленных');
      return true;
    }

    if (_testMode || !_isAvailable) {
      print('⚠️ Тестовый режим или покупки недоступны: testMode=$_testMode, available=$_isAvailable');
      return false;
    }

    print('❌ Пакет $packageId не найден в списке купленных');
    return false;
  }

  Future<void> markPackageAsPurchased(String packageId) async {
    final prefs = await SharedPreferences.getInstance();
    final purchased = prefs.getStringList(_purchasedPackagesKey) ?? [];
    if (!purchased.contains(packageId)) {
      purchased.add(packageId);
      await prefs.setStringList(_purchasedPackagesKey, purchased);
      print('💾 Пакет $packageId добавлен в список купленных. Всего куплено: ${purchased.length}');
    } else {
      print('ℹ️ Пакет $packageId уже был в списке купленных');
    }
  }

  Future<bool> buyPackage(String packageId, {String? productId}) async {
    final actualProductId = productId ?? packageId;
    
    print('🛒 Попытка покупки: packageId=$packageId, productId=$actualProductId');
    print('📦 Доступные продукты в Google Play: ${_products.map((p) => p.id).join(", ")}');
    print('📋 Загруженные product IDs: ${_productIds.join(", ")}');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('product_${actualProductId}_packageId', packageId);
    if (kIsWeb) {
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

