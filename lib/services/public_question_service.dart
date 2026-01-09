import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'dart:io' if (dart.library.html) 'dart_io_stub.dart' as io;

class PublicQuestionService {

  static const String _apiBaseUrl = 'https://blim-bilem-admin-backend.onrender.com';

  Future<Uint8List?> downloadPublicQuestionsFile({
    required String language,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/api/public/questions/files/$language'),
        headers: {'Accept': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'},
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<String?> downloadAndCacheFile({
    required String language,
  }) async {
    if (kIsWeb) {

      return null;
    }

    try {
      final bytes = await downloadPublicQuestionsFile(language: language);
      if (bytes == null) return null;

      final appDir = await getApplicationDocumentsDirectory();

      final cacheDir = io.Directory(path.join(appDir.path, 'public_questions'));

      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      final fileName = 'public_questions_$language.xlsx';

      final file = io.File(path.join(cacheDir.path, fileName));

      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      return null;
    }
  }

  Future<Uint8List?> downloadFinalPhrasesFile({
    required String language,
  }) async {

    final languageVariants = [
      language.toLowerCase(),
      language.toUpperCase(),
      language,
    ];

    for (final lang in languageVariants) {
      try {
        final url = '$_apiBaseUrl/api/public/phrases/files/$lang';
        final response = await http.get(
          Uri.parse(url),
          headers: {'Accept': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'},
        );

        if (response.statusCode == 200) {
          if (response.bodyBytes.isEmpty) {
            continue;
          }
          return response.bodyBytes;
        } else if (response.statusCode == 404) {
          continue;
        } else {
          continue;
        }
      } catch (e) {
        continue;
      }
    }

    return null;
  }
}

