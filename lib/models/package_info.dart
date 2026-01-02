import 'package:flutter/material.dart';

class PackageInfo {
  final String id;
  final String nameKz;
  final String nameRu;
  final Color color;
  final bool isPurchased;
  final int? price;

  PackageInfo({
    required this.id,
    required this.nameKz,
    required this.nameRu,
    required this.color,
    this.isPurchased = false,
    this.price,
  });

  String getName(String language) {
    return language == 'KZ' ? nameKz : nameRu;
  }

  factory PackageInfo.fromJson(Map<String, dynamic> json) {
    return PackageInfo(
      id: json['id'].toString(),
      nameKz: json['nameKZ'] ?? json['name'] ?? '',
      nameRu: json['nameRU'] ?? json['name'] ?? '',
      color: _hexToColor(json['iconColor'] ?? '#4CAF50'),
      isPurchased: false,
      price: json['price'] != null ? int.tryParse(json['price'].toString()) : null,
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
}

