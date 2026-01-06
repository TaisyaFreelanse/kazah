import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question.dart';
import '../models/package_info.dart';

class CacheService {
  static const String _questionsCacheKey = 'cached_questions';
  static const String _packagesCacheKey = 'cached_packages';
  static const String _cacheTimestampKey = 'cache_timestamp';
  static const Duration _cacheDuration = Duration(hours: 24);

  static CacheService? _instance;
  static CacheService get instance => _instance ??= CacheService._();
  
  CacheService._();

  Map<String, List<Question>> _questionsCache = {};
  List<PackageInfo>? _packagesCache;
  DateTime? _lastCacheTime;

  Future<void> initialize() async {
    await _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampStr = prefs.getString(_cacheTimestampKey);
      
      if (timestampStr != null) {
        final timestamp = DateTime.parse(timestampStr);
        if (DateTime.now().difference(timestamp) < _cacheDuration) {
          final questionsJson = prefs.getString(_questionsCacheKey);
          final packagesJson = prefs.getString(_packagesCacheKey);
          
          if (questionsJson != null) {
            try {
              final Map<String, dynamic> decoded = jsonDecode(questionsJson);
              _questionsCache = decoded.map((key, value) => MapEntry(
                key,
                (value as List).map((q) => Question.fromJson(q as Map<String, dynamic>)).toList(),
              ));
            } catch (e) {
              _questionsCache = {};
            }
          }
          
          if (packagesJson != null) {
            try {
              final List<dynamic> decoded = jsonDecode(packagesJson);
              _packagesCache = decoded.map((p) => PackageInfo.fromJson(p as Map<String, dynamic>)).toList();
            } catch (e) {
              _packagesCache = null;
            }
          }
          
          _lastCacheTime = timestamp;
        }
      }
    } catch (e) {
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final questionsJson = jsonEncode(_questionsCache.map((key, value) => MapEntry(
        key,
        value.map((q) => q.toJson()).toList(),
      )));
      
      final packagesJson = _packagesCache != null
          ? jsonEncode(_packagesCache!.map((p) => p.toJson()).toList())
          : null;
      
      await prefs.setString(_questionsCacheKey, questionsJson);
      if (packagesJson != null) {
        await prefs.setString(_packagesCacheKey, packagesJson);
      }
      await prefs.setString(_cacheTimestampKey, DateTime.now().toIso8601String());
      _lastCacheTime = DateTime.now();
    } catch (e) {
    }
  }

  List<Question>? getCachedQuestions(String key) {
    return _questionsCache[key];
  }

  void cacheQuestions(String key, List<Question> questions) {
    _questionsCache[key] = questions;
    _saveToStorage();
  }

  List<PackageInfo>? getCachedPackages() {
    if (_lastCacheTime != null && 
        DateTime.now().difference(_lastCacheTime!) < _cacheDuration) {
      return _packagesCache;
    }
    return null;
  }

  void cachePackages(List<PackageInfo> packages) {
    _packagesCache = packages;
    _saveToStorage();
  }

  void clearCache() {
    _questionsCache.clear();
    _packagesCache = null;
    _lastCacheTime = null;
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove(_questionsCacheKey);
      prefs.remove(_packagesCacheKey);
      prefs.remove(_cacheTimestampKey);
    });
  }

  bool isCacheValid() {
    return _lastCacheTime != null && 
           DateTime.now().difference(_lastCacheTime!) < _cacheDuration;
  }
}

