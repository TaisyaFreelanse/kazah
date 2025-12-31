import 'package:flutter/material.dart';

class PackageInfo {
  final String id;
  final String nameKz;
  final String nameRu;
  final Color color;
  final bool isPurchased;

  PackageInfo({
    required this.id,
    required this.nameKz,
    required this.nameRu,
    required this.color,
    this.isPurchased = false,
  });

  String getName(String language) {
    return language == 'KZ' ? nameKz : nameRu;
  }
}

