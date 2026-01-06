import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/package_info.dart';
import 'cache_service.dart';

class PackageService {
  static PackageService? _instance;
  static PackageService get instance => _instance ??= PackageService._();
  
  PackageService._();

  static const String _apiBaseUrl = 'http://localhost:3000';

  List<PackageInfo>? _cachedPackages;
  DateTime? _cacheTimestamp;
  static const Duration _cacheDuration = Duration(minutes: 5);
  Future<List<PackageInfo>>? _loadingFuture;
  
  final CacheService _cacheService = CacheService.instance;

  Future<List<PackageInfo>> getActivePackages() async {
    final cached = _cacheService.getCachedPackages();
    if (cached != null) {
      _cachedPackages = cached;
      _cacheTimestamp = DateTime.now();
      return cached;
    }
    
    if (_cachedPackages != null && 
        _cacheTimestamp != null && 
        DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
      return _cachedPackages!;
    }

    if (_loadingFuture != null) {
      return _loadingFuture!;
    }

    _loadingFuture = _fetchPackages();
    try {
      final packages = await _loadingFuture!;
      _loadingFuture = null;
      _cacheService.cachePackages(packages);
      return packages;
    } catch (e) {
      _loadingFuture = null;
      return _getDefaultPackages();
    }
  }

  Future<List<PackageInfo>> _fetchPackages() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/api/public/packages'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

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
    _loadingFuture = null;
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

