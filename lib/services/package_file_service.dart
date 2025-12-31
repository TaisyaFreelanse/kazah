import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class PackageFileService {
  // URL бекенда
  static const String _apiBaseUrl = 'https://blim-bilem-admin-backend.onrender.com';
  
  /// Загружает файл пакета с сервера и кэширует локально
  /// Возвращает путь к локальному файлу
  Future<String?> downloadPackageFile({
    required String packageId,
    required String language,
  }) async {
    try {
      // Проверяем кэш
      final cachedPath = await _getCachedFilePath(packageId, language);
      if (cachedPath != null && await File(cachedPath).exists()) {
        print('Используем кэшированный файл: $cachedPath');
        return cachedPath;
      }

      // Загружаем файл с сервера
      print('Загрузка файла пакета $packageId ($language) с сервера...');
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/api/public/packages/$packageId/files/$language'),
        headers: {'Accept': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'},
      );

      if (response.statusCode == 200) {
        // Сохраняем файл в кэш
        final file = await _saveToCache(
          packageId: packageId,
          language: language,
          data: response.bodyBytes,
        );
        
        print('Файл успешно загружен и сохранен: ${file.path}');
        return file.path;
      } else {
        print('Ошибка загрузки файла: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Ошибка загрузки файла пакета $packageId ($language): $e');
      return null;
    }
  }

  /// Получает путь к кэшированному файлу
  Future<String?> _getCachedFilePath(String packageId, String language) async {
    try {
      final cacheDir = await _getCacheDirectory();
      final fileName = 'package_${packageId}_$language.xlsx';
      final filePath = path.join(cacheDir.path, fileName);
      return filePath;
    } catch (e) {
      print('Ошибка получения пути к кэшу: $e');
      return null;
    }
  }

  /// Сохраняет файл в кэш
  Future<File> _saveToCache({
    required String packageId,
    required String language,
    required Uint8List data,
  }) async {
    final cacheDir = await _getCacheDirectory();
    final fileName = 'package_${packageId}_$language.xlsx';
    final file = File(path.join(cacheDir.path, fileName));
    
    await file.writeAsBytes(data);
    return file;
  }

  /// Получает директорию для кэша
  Future<Directory> _getCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(path.join(appDir.path, 'package_files'));
    
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    
    return cacheDir;
  }

  /// Очищает кэш для конкретного пакета
  Future<void> clearCacheForPackage(String packageId) async {
    try {
      final cacheDir = await _getCacheDirectory();
      final files = await cacheDir.list().toList();
      
      for (final file in files) {
        if (file is File && file.path.contains('package_${packageId}_')) {
          await file.delete();
          print('Удален кэшированный файл: ${file.path}');
        }
      }
    } catch (e) {
      print('Ошибка очистки кэша для пакета $packageId: $e');
    }
  }

  /// Очищает весь кэш
  Future<void> clearAllCache() async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        print('Весь кэш очищен');
      }
    } catch (e) {
      print('Ошибка очистки кэша: $e');
    }
  }

  /// Проверяет, есть ли файл в кэше
  Future<bool> isFileCached(String packageId, String language) async {
    try {
      final cachedPath = await _getCachedFilePath(packageId, language);
      if (cachedPath != null) {
        return await File(cachedPath).exists();
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

