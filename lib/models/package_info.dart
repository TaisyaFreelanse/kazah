import 'package:flutter/material.dart';

class PackageInfo {
  final String id;
  final String nameKz;
  final String nameRu;
  final Color color;
  final bool isPurchased;
  final int? price;
  final String? productId;

  PackageInfo({
    required this.id,
    required this.nameKz,
    required this.nameRu,
    required this.color,
    this.isPurchased = false,
    this.price,
    this.productId,
  });

  String getProductId() {
    // Если productId указан в API - используем его
    if (productId != null && productId!.isNotEmpty) {
      print('📦 Package $id: используем productId из API: $productId');
      return productId!;
    }
    
    // Иначе используем числовой ID пакета напрямую
    // В Google Play зарегистрированы числовые ID: 5, 6, 7, 8
    print('📦 Package $id: используем ID пакета как productId: $id');
    return id;
  }

  String getName(String language) {
    return language == 'KZ' ? nameKz : nameRu;
  }

  factory PackageInfo.fromJson(Map<String, dynamic> json) {
    final packageId = json['id'].toString();
    final productId = json['productId'] ?? json['product_id'];
    
    print('📦 Создание PackageInfo: id=$packageId, productId=$productId');
    
    return PackageInfo(
      id: packageId,
      nameKz: json['nameKZ'] ?? json['name'] ?? '',
      nameRu: json['nameRU'] ?? json['name'] ?? '',
      color: _hexToColor(json['iconColor'] ?? '#4CAF50'),
      isPurchased: false,
      price: json['price'] != null ? int.tryParse(json['price'].toString()) : null,
      productId: productId,
    );
  }

  static Color _hexToColor(String hex) {
    try {

      final hexCode = hex.replaceFirst('#', '');

      final fullHex = hexCode.length == 6 ? 'FF$hexCode' : hexCode;
      return Color(int.parse(fullHex, radix: 16));
    } catch (e) {
      return const Color(0xFF4CAF50);
    }
  }

  String toHex() {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameKZ': nameKz,
      'nameRU': nameRu,
      'iconColor': toHex(),
      'isPurchased': isPurchased,
      'price': price,
      'productId': productId,
    };
  }
}

