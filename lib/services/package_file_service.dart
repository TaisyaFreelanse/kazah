import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class PackageFileService {

  static const String _apiBaseUrl = 'https:

  Future<String?> downloadPackageFile({
    required String packageId,
    required String language,
  }) async {
    try {

      final cachedPath = await _getCachedFilePath(packageId, language);
      if (cachedPath != null && await File(cachedPath).exists()) {
        return cachedPath;
      }

      final response = await http.get(
        Uri.parse('$_apiBaseUrl/api/public/packages/$packageId/files/$language'),
        headers: {'Accept': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'},
      );

      if (response.statusCode == 200) {

        final file = await _saveToCache(
          packageId: packageId,
          language: language,
          data: response.bodyBytes,
        );

        return file.path;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<String?> _getCachedFilePath(String packageId, String language) async {
    try {
      final cacheDir = await _getCacheDirectory();
      final fileName = 'package_${packageId}_$language.xlsx';
      final filePath = path.join(cacheDir.path, fileName);
      return filePath;
    } catch (e) {
      return null;
    }
  }

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

  Future<Directory> _getCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(path.join(appDir.path, 'package_files'));

    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    return cacheDir;
  }

  Future<void> clearCacheForPackage(String packageId) async {
    try {
      final cacheDir = await _getCacheDirectory();
      final files = await cacheDir.list().toList();

      for (final file in files) {
        if (file is File && file.path.contains('package_${packageId}_')) {
          await file.delete();
        }
      }
    } catch (e) {
    }
  }

  Future<void> clearAllCache() async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
    } catch (e) {
    }
  }

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

