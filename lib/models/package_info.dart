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

  /// Создает PackageInfo из JSON (из API)
  factory PackageInfo.fromJson(Map<String, dynamic> json) {
    return PackageInfo(
      id: json['id'].toString(),
      nameKz: json['nameKZ'] ?? json['name'] ?? '',
      nameRu: json['nameRU'] ?? json['name'] ?? '',
      color: _hexToColor(json['iconColor'] ?? '#4CAF50'),
      isPurchased: false, // Статус покупки проверяется отдельно
      price: json['price'] != null ? int.tryParse(json['price'].toString()) : null,
    );
  }

  /// Конвертирует HEX строку в Color
  static Color _hexToColor(String hex) {
    try {
      // Убираем # если есть
      final hexCode = hex.replaceFirst('#', '');
      // Добавляем FF для альфа-канала если нужно
      final fullHex = hexCode.length == 6 ? 'FF$hexCode' : hexCode;
      return Color(int.parse(fullHex, radix: 16));
    } catch (e) {
      print('Ошибка конвертации цвета $hex: $e');
      return const Color(0xFF4CAF50); // Дефолтный зеленый
    }
  }

  /// Конвертирует Color в HEX строку
  String toHex() {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }
}

