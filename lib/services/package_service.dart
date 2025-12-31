import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/package_info.dart';

class PackageService {
  // URL бекенда (можно вынести в конфигурацию)
  static const String _apiBaseUrl = 'https://blim-bilem-admin-backend.onrender.com';
  
  // Кэш пакетов
  List<PackageInfo>? _cachedPackages;
  DateTime? _cacheTimestamp;
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Получает список активных пакетов из API
  Future<List<PackageInfo>> getActivePackages() async {
    // Проверяем кэш
    if (_cachedPackages != null && 
        _cacheTimestamp != null && 
        DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
      return _cachedPackages!;
    }

    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/api/public/packages'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final packages = data.map((json) => PackageInfo.fromJson(json)).toList();
        
        // Обновляем кэш
        _cachedPackages = packages;
        _cacheTimestamp = DateTime.now();
        
        return packages;
      } else {
        print('Ошибка получения пакетов: ${response.statusCode}');
        return _getDefaultPackages();
      }
    } catch (e) {
      print('Ошибка загрузки пакетов из API: $e');
      // Возвращаем пакеты по умолчанию при ошибке
      return _getDefaultPackages();
    }
  }

  /// Получает информацию о конкретном пакете по ID
  Future<PackageInfo?> getPackageById(String packageId) async {
    try {
      final packages = await getActivePackages();
      try {
        return packages.firstWhere((p) => p.id == packageId);
      } catch (e) {
        return null;
      }
    } catch (e) {
      print('Ошибка получения пакета $packageId: $e');
      return null;
    }
  }

  /// Получает цвет значка пакета по ID
  Future<Color?> getPackageColor(String? packageId) async {
    if (packageId == null) return null;
    
    try {
      final package = await getPackageById(packageId);
      return package?.color;
    } catch (e) {
      print('Ошибка получения цвета пакета $packageId: $e');
      return null;
    }
  }

  /// Очищает кэш (для принудительного обновления)
  void clearCache() {
    _cachedPackages = null;
    _cacheTimestamp = null;
  }

  /// Возвращает пакеты по умолчанию (fallback при ошибке API)
  /// Использует строковые ID для обратной совместимости
  List<PackageInfo> _getDefaultPackages() {
    return [
      PackageInfo(
        id: 'more_questions', // Строковый ID для обратной совместимости
        nameKz: 'Көбірек сұрақтар',
        nameRu: 'Больше вопросов',
        color: const Color(0xFF9C27B0), // Фиолетовый
        isPurchased: false,
      ),
      PackageInfo(
        id: 'history', // Строковый ID для обратной совместимости
        nameKz: 'Қазақстан тарихы',
        nameRu: 'История Казахстана',
        color: const Color(0xFF795548), // Коричневый
        isPurchased: false,
      ),
    ];
  }
}

