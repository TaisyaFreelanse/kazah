import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/package_info.dart';

class PackageService {

  static const String _apiBaseUrl = 'https:

  List<PackageInfo>? _cachedPackages;
  DateTime? _cacheTimestamp;
  static const Duration _cacheDuration = Duration(minutes: 5);

  Future<List<PackageInfo>> getActivePackages() async {

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

        _cachedPackages = packages;
        _cacheTimestamp = DateTime.now();

        return packages;
      } else {
        return _getDefaultPackages();
      }
    } catch (e) {
      return _getDefaultPackages();
    }
  }

  Future<PackageInfo?> getPackageById(String packageId) async {
    try {
      final packages = await getActivePackages();
      try {
        return packages.firstWhere((p) => p.id == packageId);
      } catch (e) {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<Color?> getPackageColor(String? packageId) async {
    if (packageId == null) return null;

    try {
      final package = await getPackageById(packageId);
      return package?.color;
    } catch (e) {
      return null;
    }
  }

  void clearCache() {
    _cachedPackages = null;
    _cacheTimestamp = null;
  }

  List<PackageInfo> _getDefaultPackages() {
    return [
      PackageInfo(
        id: 'more_questions',
        nameKz: 'Көбірек сұрақтар',
        nameRu: 'Больше вопросов',
        color: const Color(0xFF9C27B0),
        isPurchased: false,
      ),
      PackageInfo(
        id: 'history',
        nameKz: 'Қазақстан тарихы',
        nameRu: 'История Казахстана',
        color: const Color(0xFF795548),
        isPurchased: false,
      ),
    ];
  }
}

