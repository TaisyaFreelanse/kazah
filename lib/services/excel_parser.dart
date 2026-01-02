import 'package:excel/excel.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import '../models/question.dart';

import 'dart:io' if (dart.library.html) 'dart_io_stub.dart' as io;

class ExcelParser {

  Future<List<Question>> parseQuestions({
    required String assetPath,
    Difficulty? difficulty,
    String? packageId,
  }) async {
    try {
      Uint8List bytes;

      if (assetPath.startsWith('bytes:')) {
        final base64Data = assetPath.substring(6);
        bytes = Uint8List.fromList(base64Decode(base64Data));
      } else if (kIsWeb) {
        final ByteData data = await rootBundle.load(assetPath);
        bytes = data.buffer.asUint8List();
      } else {
        if (kIsWeb) {
          final ByteData data = await rootBundle.load(assetPath);
          bytes = data.buffer.asUint8List();
        } else {
          try {
            final file = io.File(assetPath);
            if (await file.exists()) {
              final fileBytes = await file.readAsBytes();
              bytes = Uint8List.fromList(fileBytes);
            } else {
              final ByteData data = await rootBundle.load(assetPath);
              bytes = data.buffer.asUint8List();
            }
          } catch (e) {
            final ByteData data = await rootBundle.load(assetPath);
            bytes = data.buffer.asUint8List();
          }
        }
      }

      final excel = Excel.decodeBytes(bytes);

      List<Question> questions = [];

      List<MapEntry<String, Difficulty>> sheetsToParse = [];

      if (difficulty != null) {

        for (final sheetName in excel.tables.keys) {
          final sheetDifficulty = _getDifficultyFromSheetName(sheetName);
          if (sheetDifficulty == difficulty) {
            sheetsToParse.add(MapEntry(sheetName, difficulty));
            break;
          }
        }
      } else {
        final allSheets = excel.tables.keys.toList();
        final difficulties = [Difficulty.easy, Difficulty.medium, Difficulty.hard];

        for (final diff in difficulties) {
          for (final sheetName in allSheets) {
            final detectedDifficulty = _getDifficultyFromSheetName(sheetName);
            if (detectedDifficulty == diff) {
              sheetsToParse.add(MapEntry(sheetName, diff));
              break;
            }
          }
        }
      }

      for (final entry in sheetsToParse) {
        final sheetName = entry.key;
        final currentDifficulty = entry.value;
        final sheet = excel.tables[sheetName];

        if (sheet == null) continue;

        for (var rowIndex = 0; rowIndex < sheet.rows.length; rowIndex++) {
          var row = sheet.rows[rowIndex];
          if (row.isEmpty) continue;

          final questionText = _getCellValue(row[0]);
          if (questionText.isEmpty) continue;

          if (rowIndex == 0 && _isHeaderRow(row)) continue;

          List<String> answers = [];
          for (int i = 1; i <= 6 && i < row.length; i++) {
            final answer = _getCellValue(row[i]);
            if (answer.isNotEmpty) {
              answers.add(answer);
            }
          }

          if (answers.length < 6) continue;

          questions.add(Question(
            text: questionText,
            answers: answers,
            correctAnswerIndex: 0,
            difficulty: currentDifficulty,
            packageId: packageId,
          ));
        }
      }

      return questions;
    } catch (e, stackTrace) {
      return [];
    }
  }

  Future<List<String>> parsePhrases({
    required String assetPath,
  }) async {
    try {
      Uint8List bytes;

      if (assetPath.startsWith('bytes:')) {
        final base64Data = assetPath.substring(6);
        bytes = Uint8List.fromList(base64Decode(base64Data));
      } else if (kIsWeb) {
        final ByteData data = await rootBundle.load(assetPath);
        bytes = data.buffer.asUint8List();
      } else {
        try {
          final file = io.File(assetPath);
          if (await file.exists()) {
            final fileBytes = await file.readAsBytes();
            bytes = Uint8List.fromList(fileBytes);
          } else {
            final ByteData data = await rootBundle.load(assetPath);
            bytes = data.buffer.asUint8List();
          }
        } catch (e) {
          final ByteData data = await rootBundle.load(assetPath);
          bytes = data.buffer.asUint8List();
        }
      }

      final excel = Excel.decodeBytes(bytes);

      List<String> phrases = [];

      final sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null) {
        return phrases;
      }

      for (var rowIndex = 0; rowIndex < sheet.rows.length; rowIndex++) {
        var row = sheet.rows[rowIndex];
        if (row.isEmpty) continue;

        if (rowIndex == 0 && _isHeaderRow(row)) {
          continue;
        }

        final phrase = _getCellValue(row[0]);
        if (phrase.isEmpty) continue;

        final trimmedPhrase = phrase.trim();

        if (trimmedPhrase.length > 150) {
          continue;
        }

        if (trimmedPhrase.endsWith('?') || trimmedPhrase.endsWith('?')) {
          continue;
        }

        final lowerPhrase = trimmedPhrase.toLowerCase();
        final questionWords = ['кто', 'что', 'где', 'когда', 'как', 'почему', 'зачем', 'сколько', 
                              'чей', 'какой', 'какая', 'какое', 'какие', 'кем', 'чем',
                              'кто является', 'что является', 'как называется', 'в каком', 'у какого',
                              'қай', 'қандай', 'қанша', 'неше', 'қалай', 'неге', 'не үшін'];
        if (questionWords.any((word) => lowerPhrase.startsWith(word))) {
          continue;
        }

        final questionWordCount = questionWords.where((word) => lowerPhrase.contains(word)).length;
        if (questionWordCount >= 2) {
          continue;
        }

        phrases.add(trimmedPhrase);
      }

      return phrases;
    } catch (e) {
      return [];
    }
  }

  String _getCellValue(dynamic cell) {
    if (cell == null) return '';

    final value = cell.value;
    if (value == null) return '';

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

  Difficulty _getDifficultyFromSheetName(String sheetName) {
    final lowerName = sheetName.toLowerCase().trim();

    if (lowerName.contains('easy') || 
        lowerName.contains('просты') || 
        lowerName.contains('легк') || 
        lowerName == 'sheet1' ||
        lowerName == 'легкие') {
      return Difficulty.easy;
    } else if (lowerName.contains('hard') || 
             lowerName.contains('сложн') || 
             lowerName == 'sheet3' ||
             lowerName == 'сложные') {
      return Difficulty.hard;
    } else {
      return Difficulty.medium;
    }
  }

  bool _isHeaderRow(List<dynamic> row) {
    if (row.isEmpty) return false;

    final firstCell = _getCellValue(row[0]).toLowerCase();

    final headerKeywords = ['вопрос', 'question', '№', 'номер', 'n'];
    return headerKeywords.any((keyword) => firstCell.contains(keyword));
  }
}

