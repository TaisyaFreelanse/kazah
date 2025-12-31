import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:in_app_purchase/in_app_purchase.dart';

class PurchaseService {
  final InAppPurchase? _iap = kIsWeb ? null : InAppPurchase.instance;
  static const String _purchasedPackagesKey = 'purchased_packages';
  
  // Product IDs для пакетов (должны соответствовать ID в App Store / Google Play)
  static const Set<String> _productIds = {'more_questions', 'history'};
  
  List<ProductDetails> _products = [];
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  bool _isAvailable = false;

  // Callback для обработки покупок
  Function(String packageId, bool success, String? error)? onPurchaseUpdated;

  PurchaseService() {
    _init();
  }

  Future<void> _init() async {
    // На веб-платформе покупки недоступны
    if (kIsWeb || _iap == null) {
      _isAvailable = false;
      print('In-App Purchase недоступен на веб-платформе');
      return;
    }
    
    // Проверяем доступность покупок
    try {
      _isAvailable = await _iap!.isAvailable();
    
    if (!_isAvailable) {
      print('In-App Purchase недоступен');
      return;
    }
    } catch (e) {
      print('Ошибка инициализации In-App Purchase: $e');
      _isAvailable = false;
      return;
    }

    // Загружаем продукты
    await loadProducts();

    // Подписываемся на обновления покупок
    _purchaseSubscription = _iap!.purchaseStream.listen(
      _listenToPurchaseUpdated,
      onDone: () {
        _purchaseSubscription?.cancel();
      },
      onError: (error) {
        print('Ошибка потока покупок: $error');
      },
    );
  }

  /// Загружает список доступных продуктов
  Future<void> loadProducts() async {
    if (!_isAvailable || _iap == null) return;

    try {
      final ProductDetailsResponse response =
          await _iap!.queryProductDetails(_productIds);

      if (response.notFoundIDs.isNotEmpty) {
        print('Продукты не найдены: ${response.notFoundIDs}');
      }

      _products = response.productDetails;
      print('Загружено продуктов: ${_products.length}');
    } catch (e) {
      print('Ошибка загрузки продуктов: $e');
    }
  }

  /// Обрабатывает обновления покупок
  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Покупка в процессе - показываем индикатор загрузки
        onPurchaseUpdated?.call(
          purchaseDetails.productID,
          false,
          null,
        );
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          // Ошибка покупки
          onPurchaseUpdated?.call(
            purchaseDetails.productID,
            false,
            purchaseDetails.error?.message ?? 'Ошибка покупки',
          );
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          // Успешная покупка или восстановление
          _handleSuccessfulPurchase(purchaseDetails);
        }

        // Завершаем покупку
        if (purchaseDetails.pendingCompletePurchase && _iap != null) {
          _iap!.completePurchase(purchaseDetails);
        }
      }
    }
  }

  /// Обрабатывает успешную покупку
  Future<void> _handleSuccessfulPurchase(
      PurchaseDetails purchaseDetails) async {
    final packageId = purchaseDetails.productID;

    // Сохраняем покупку локально
    await markPackageAsPurchased(packageId);

    // Уведомляем о успешной покупке
    onPurchaseUpdated?.call(packageId, true, null);
  }

  /// Проверяет, куплен ли пакет
  Future<bool> isPackagePurchased(String packageId) async {
    // Сначала проверяем локальное хранилище
    final prefs = await SharedPreferences.getInstance();
    final purchased = prefs.getStringList(_purchasedPackagesKey) ?? [];
    
    if (purchased.contains(packageId)) {
      return true;
    }

    // Если покупки недоступны, возвращаем результат из локального хранилища
    if (!_isAvailable) {
      return false;
    }

    // Проверяем через In-App Purchase (для восстановления покупок)
    // Восстановление покупок обрабатывается через purchaseStream
    return false;
  }

  /// Помечает пакет как купленный (локально)
  Future<void> markPackageAsPurchased(String packageId) async {
    final prefs = await SharedPreferences.getInstance();
    final purchased = prefs.getStringList(_purchasedPackagesKey) ?? [];
    if (!purchased.contains(packageId)) {
      purchased.add(packageId);
      await prefs.setStringList(_purchasedPackagesKey, purchased);
    }
  }

  /// Инициирует покупку пакета
  Future<bool> buyPackage(String packageId) async {
    if (!_isAvailable) {
      onPurchaseUpdated?.call(packageId, false, 'Покупки недоступны');
      return false;
    }

    // Находим продукт
    final product = _products.firstWhere(
      (p) => p.id == packageId,
      orElse: () => throw Exception('Продукт не найден: $packageId'),
    );

    try {
      // Создаем параметры покупки
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );

      // Пакеты вопросов - это non-consumable продукты
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

  /// Восстанавливает покупки
  Future<void> restorePurchases() async {
    if (!_isAvailable) {
      print('Покупки недоступны для восстановления');
      return;
    }

    if (_iap == null) return;
    
    try {
      await _iap!.restorePurchases();
      // Восстановленные покупки будут обработаны через purchaseStream
    } catch (e) {
      print('Ошибка восстановления покупок: $e');
    }
  }

  /// Получает информацию о продукте
  ProductDetails? getProductDetails(String packageId) {
    try {
      return _products.firstWhere((p) => p.id == packageId);
    } catch (e) {
      return null;
    }
  }

  /// Освобождает ресурсы
  void dispose() {
    _purchaseSubscription?.cancel();
  }
}

