import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

// Условный импорт для File API (только на мобильных платформах)
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
// На веб-платформе используется stub, так как File API недоступен
import 'dart:io' if (dart.library.html) 'dart_io_stub.dart' as io;

class PublicQuestionService {
  // URL бекенда
  static const String _apiBaseUrl = 'https://blim-bilem-admin-backend.onrender.com';
  
  /// Загружает файл базовых вопросов с сервера
  /// Возвращает байты файла или null при ошибке
  Future<Uint8List?> downloadPublicQuestionsFile({
    required String language,
  }) async {
    try {
      print('Загрузка базовых вопросов ($language) с сервера...');
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/api/public/questions/files/$language'),
        headers: {'Accept': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'},
      );

      if (response.statusCode == 200) {
        print('Базовые вопросы успешно загружены с сервера');
        return response.bodyBytes;
      } else if (response.statusCode == 404) {
        print('Базовые вопросы не найдены на сервере, используем fallback');
        return null;
      } else {
        print('Ошибка загрузки базовых вопросов: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Ошибка загрузки базовых вопросов $language: $e');
      return null;
    }
  }

  /// Загружает файл и возвращает путь (для мобильных платформ)
  /// На веб-платформе возвращает null, так как файлы загружаются напрямую
  Future<String?> downloadAndCacheFile({
    required String language,
  }) async {
    if (kIsWeb) {
      // На веб-платформе не кэшируем, загружаем напрямую
      return null;
    }

    // Этот код выполняется только на мобильных платформах (kIsWeb уже проверен выше)
    try {
      final bytes = await downloadPublicQuestionsFile(language: language);
      if (bytes == null) return null;

      // Сохраняем в кэш (только на мобильных платформах)
      final appDir = await getApplicationDocumentsDirectory();
      // На мобильных платформах io - это dart:io
      // ignore: avoid_dynamic_calls
      final cacheDir = io.Directory(path.join(appDir.path, 'public_questions'));
      
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }
      
      final fileName = 'public_questions_$language.xlsx';
      // ignore: avoid_dynamic_calls
      final file = io.File(path.join(cacheDir.path, fileName));
      
      await file.writeAsBytes(bytes);
      print('Файл сохранен в кэш: ${file.path}');
      return file.path;
    } catch (e) {
      print('Ошибка сохранения файла в кэш: $e');
      return null;
    }
  }
}

