import 'package:excel/excel.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import '../models/question.dart';

// Условный импорт для File API (только на мобильных платформах)
// На веб-платформе используется stub, так как File API недоступен
import 'dart:io' if (dart.library.html) 'dart_io_stub.dart' as io;

class ExcelParser {
  /// Парсит вопросы из Excel файла
  /// 
  /// [assetPath] - путь к файлу в assets (например, 'assets/data/questions_kz.xlsx')
  ///               или путь к локальному файлу (например, '/path/to/file.xlsx')
  /// [difficulty] - если указана, парсит только вопросы этой сложности, иначе все
  /// [packageId] - ID пакета для помеченных вопросов (null для базовых)
  Future<List<Question>> parseQuestions({
    required String assetPath,
    Difficulty? difficulty,
    String? packageId,
  }) async {
    try {
      print('Начинаем парсинг файла: $assetPath');
      
      Uint8List bytes;
      
      // Проверяем, переданы ли байты напрямую (для веб-платформы)
      if (assetPath.startsWith('bytes:')) {
        // Байты переданы напрямую (для веб-платформы)
        final base64Data = assetPath.substring(6); // Убираем префикс 'bytes:'
        bytes = Uint8List.fromList(base64Decode(base64Data));
        print('Парсинг из переданных байтов (размер: ${bytes.length} байт)');
      } else if (kIsWeb) {
        // На веб-платформе всегда загружаем из assets
        print('Загрузка из assets (веб-платформа): $assetPath');
        final ByteData data = await rootBundle.load(assetPath);
        bytes = data.buffer.asUint8List();
      } else {
        // На мобильных платформах проверяем, является ли путь локальным файлом
        // На веб-платформе File API недоступен, всегда используем assets
        if (kIsWeb) {
          // На веб-платформе всегда загружаем из assets
          print('Загрузка из assets (веб-платформа): $assetPath');
          final ByteData data = await rootBundle.load(assetPath);
          bytes = data.buffer.asUint8List();
        } else {
          // На мобильных платформах проверяем локальный файл
          try {
            // ignore: avoid_dynamic_calls
            final file = io.File(assetPath);
            if (await file.exists()) {
              // Загружаем из локального файла
              print('Загрузка из локального файла: $assetPath');
              final fileBytes = await file.readAsBytes();
              bytes = Uint8List.fromList(fileBytes);
            } else {
              // Загружаем из assets
              print('Загрузка из assets: $assetPath');
              final ByteData data = await rootBundle.load(assetPath);
              bytes = data.buffer.asUint8List();
            }
          } catch (e) {
            // Если File API недоступен, загружаем из assets
            print('File API недоступен, загрузка из assets: $assetPath');
            final ByteData data = await rootBundle.load(assetPath);
            bytes = data.buffer.asUint8List();
          }
        }
      }
      
      print('Файл загружен, размер: ${bytes.length} байт');
      
      // Открываем Excel файл
      final excel = Excel.decodeBytes(bytes);
      print('Excel файл открыт, листов: ${excel.tables.length}');
      
      List<Question> questions = [];
      
      // Определяем, какие листы парсить
      List<MapEntry<String, Difficulty>> sheetsToParse = [];
      
      if (difficulty != null) {
        // Парсим только нужный лист - ищем его по всем доступным листам
        for (final sheetName in excel.tables.keys) {
          final sheetDifficulty = _getDifficultyFromSheetName(sheetName);
          if (sheetDifficulty == difficulty) {
            sheetsToParse.add(MapEntry(sheetName, difficulty));
            break;
          }
        }
      } else {
        // Парсим все 3 листа в правильном порядке (easy, medium, hard)
        final allSheets = excel.tables.keys.toList();
        final difficulties = [Difficulty.easy, Difficulty.medium, Difficulty.hard];
        
        for (final diff in difficulties) {
          for (final sheetName in allSheets) {
            if (_getDifficultyFromSheetName(sheetName) == diff) {
              sheetsToParse.add(MapEntry(sheetName, diff));
              break;
            }
          }
        }
      }
      
      // Парсим каждый лист
      for (final entry in sheetsToParse) {
        final sheetName = entry.key;
        final currentDifficulty = entry.value;
        final sheet = excel.tables[sheetName];
        
        if (sheet == null) continue;
        
        // Парсим каждую строку
        for (var rowIndex = 0; rowIndex < sheet.rows.length; rowIndex++) {
          var row = sheet.rows[rowIndex];
          if (row.isEmpty) continue;
          
          // Извлекаем текст вопроса (первая колонка)
          final questionText = _getCellValue(row[0]);
          if (questionText.isEmpty) continue;
          
          // Пропускаем возможные заголовки (если первая строка не содержит вопроса)
          if (rowIndex == 0 && _isHeaderRow(row)) continue;
          
          // Извлекаем 6 вариантов ответа
          List<String> answers = [];
          for (int i = 1; i <= 6 && i < row.length; i++) {
            final answer = _getCellValue(row[i]);
            if (answer.isNotEmpty) {
              answers.add(answer);
            }
          }
          
          // Проверяем, что есть минимум 6 ответов
          if (answers.length < 6) continue;
          
          // Создаем вопрос (ответы не рандомизируем здесь, это будет в QuestionService)
          // Правильный ответ всегда первый (индекс 0)
          questions.add(Question(
            text: questionText,
            answers: answers,
            correctAnswerIndex: 0, // Правильный ответ всегда первый в исходных данных
            difficulty: currentDifficulty,
            packageId: packageId,
          ));
        }
      }
      
      print('Парсинг завершен, найдено вопросов: ${questions.length}');
      if (questions.isNotEmpty) {
        print('Первый вопрос (для проверки языка): "${questions.first.text}"');
        print('Первый ответ: "${questions.first.answers.isNotEmpty ? questions.first.answers[0] : 'нет ответов'}"');
      }
      return questions;
    } catch (e, stackTrace) {
      print('Ошибка парсинга Excel файла $assetPath: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Парсит мотивирующие фразы из Excel файла
  Future<List<String>> parsePhrases({
    required String assetPath,
  }) async {
    try {
      // Загружаем файл из assets
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      
      // Открываем Excel файл
      final excel = Excel.decodeBytes(bytes);
      
      List<String> phrases = [];
      
      // Берем первый лист
      final sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null) return phrases;
      
      // Парсим каждую строку
      for (var rowIndex = 0; rowIndex < sheet.rows.length; rowIndex++) {
        var row = sheet.rows[rowIndex];
        if (row.isEmpty) continue;
        
        // Пропускаем возможные заголовки
        if (rowIndex == 0 && _isHeaderRow(row)) continue;
        
        // Берем текст из первой колонки
        final phrase = _getCellValue(row[0]);
        if (phrase.isNotEmpty) {
          phrases.add(phrase);
        }
      }
      
      return phrases;
    } catch (e) {
      print('Ошибка парсинга фраз из $assetPath: $e');
      return [];
    }
  }

  /// Извлекает строковое значение из ячейки Excel
  String _getCellValue(dynamic cell) {
    if (cell == null) return '';
    
    final value = cell.value;
    if (value == null) return '';
    
    // Excel может хранить значение в разных форматах
    if (value is String) {
      return value.trim();
    } else if (value is num) {
      return value.toString().trim();
    } else if (value is bool) {
      return value.toString().trim();
    } else if (value is DateTime) {
      return value.toString().trim();
    }
    
    return value.toString().trim();
  }

  /// Преобразует имя листа в Difficulty
  Difficulty _getDifficultyFromSheetName(String sheetName) {
    final lowerName = sheetName.toLowerCase();
    
    // Проверяем английские названия
    if (lowerName.contains('easy') || lowerName.contains('просты') || lowerName == 'sheet1') {
      return Difficulty.easy;
    } else if (lowerName.contains('hard') || lowerName.contains('сложн') || lowerName == 'sheet3') {
      return Difficulty.hard;
    } else {
      // По умолчанию средний уровень (sheet2, средние, medium)
      return Difficulty.medium;
    }
  }

  /// Проверяет, является ли строка заголовком
  bool _isHeaderRow(List<dynamic> row) {
    if (row.isEmpty) return false;
    
    final firstCell = _getCellValue(row[0]).toLowerCase();
    // Проверяем типичные слова заголовков
    final headerKeywords = ['вопрос', 'question', '№', 'номер', 'n'];
    return headerKeywords.any((keyword) => firstCell.contains(keyword));
  }
}

