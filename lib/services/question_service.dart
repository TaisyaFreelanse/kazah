import '../models/question.dart';
import '../models/package_info.dart';
import 'excel_parser.dart';
import 'purchase_service.dart';
import 'package_service.dart';
import 'package_file_service.dart';
import 'public_question_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';

class QuestionService {
  final ExcelParser _excelParser = ExcelParser();
  final PurchaseService _purchaseService = PurchaseService();
  final PackageFileService _packageFileService = PackageFileService();
  final PublicQuestionService _publicQuestionService = PublicQuestionService();

  Future<List<Question>> getQuestions({
    required String language,
    List<String> purchasedPackageIds = const [],
  }) async {
    List<Question> allQuestions = [];
    List<Question> baseQuestions = [];

    if (kIsWeb) {
      try {
        final bytes = await _publicQuestionService.downloadPublicQuestionsFile(language: language);
        if (bytes != null) {
          final base64Data = base64Encode(bytes);
          baseQuestions = await _excelParser.parseQuestions(
            assetPath: 'bytes:$base64Data',
            packageId: null,
          );
        } else {
          baseQuestions = await _loadBaseQuestionsFromAssets(language);
        }
      } catch (e) {
        baseQuestions = await _loadBaseQuestionsFromAssets(language);
      }
    } else {
      try {
        final cachedPath = await _publicQuestionService.downloadAndCacheFile(language: language);
        if (cachedPath != null) {
          baseQuestions = await _excelParser.parseQuestions(
            assetPath: cachedPath,
            packageId: null,
          );
        } else {

          baseQuestions = await _loadBaseQuestionsFromAssets(language);
        }
      } catch (e) {
        baseQuestions = await _loadBaseQuestionsFromAssets(language);
      }
    }

    allQuestions.addAll(baseQuestions);

    for (final packageId in purchasedPackageIds) {
      final packageQuestions = await _loadPackageQuestions(
        packageId: packageId,
        language: language,
      );
      allQuestions.addAll(packageQuestions);
    }

    return allQuestions;
  }

  Future<List<Question>> _loadBaseQuestionsFromAssets(String language) async {
    final baseQuestionsPath = language == 'KZ'
        ? 'assets/data/questions_kz.xlsx'
        : 'assets/data/questions_ru.xlsx';

    return await _excelParser.parseQuestions(
      assetPath: baseQuestionsPath,
      packageId: null,
    );
  }

  Future<List<Question>> _loadPackageQuestions({
    required String packageId,
    required String language,
  }) async {

    final packageService = PackageService();
    PackageInfo? packageInfo;

    try {
      packageInfo = await packageService.getPackageById(packageId);
    } catch (e) {
    }

    final isNumericId = int.tryParse(packageId) != null;

    if (isNumericId && packageInfo != null) {
      try {
        final filePath = await _packageFileService.downloadPackageFile(
          packageId: packageId,
          language: language,
        );

        if (filePath != null) {
          try {
            return await _excelParser.parseQuestions(
              assetPath: filePath,
              packageId: packageId,
            );
          } catch (e) {
          }
        }
      } catch (e) {
      }
    }

    String? assetPath;

    if (isNumericId && packageInfo != null) {

      final packageName = packageInfo.nameKz.toLowerCase();
      if (packageName.contains('тарих') || packageName.contains('история') || 
          packageInfo.nameRu.toLowerCase().contains('история')) {
        assetPath = language == 'KZ'
            ? 'assets/data/history_kz.xlsx'
            : 'assets/data/history_ru.xlsx';
      } else if (packageName.contains('көбірек') || packageName.contains('больше') ||
                 packageInfo.nameRu.toLowerCase().contains('больше')) {

        assetPath = null;
      }
    } else {

      switch (packageId) {
        case 'history':
          assetPath = language == 'KZ'
              ? 'assets/data/history_kz.xlsx'
              : 'assets/data/history_ru.xlsx';
          break;
        case 'more_questions':

          return [];
        default:
          return [];
      }
    }

    if (assetPath == null) return [];

    try {
      return await _excelParser.parseQuestions(
      assetPath: assetPath,
      packageId: packageId,
    );
  } catch (e) {
    return [];
  }
  }

  List<Question> selectGameQuestions(List<Question> allQuestions) {
    final easyQuestions = allQuestions
        .where((q) => q.difficulty == Difficulty.easy)
        .toList();
    final mediumQuestions = allQuestions
        .where((q) => q.difficulty == Difficulty.medium)
        .toList();
    final hardQuestions = allQuestions
        .where((q) => q.difficulty == Difficulty.hard)
        .toList();

    easyQuestions.shuffle();
    mediumQuestions.shuffle();
    hardQuestions.shuffle();

    const int targetEasy = 4;
    const int targetMedium = 6;
    const int targetHard = 3;
    const int totalTarget = 13;

    Set<String> usedQuestionTexts = {};
    List<Question> selectedEasy = [];
    List<Question> selectedMedium = [];
    List<Question> selectedHard = [];

    for (var question in easyQuestions) {
      if (selectedEasy.length >= targetEasy) break;
      if (!usedQuestionTexts.contains(question.text)) {
        selectedEasy.add(question);
        usedQuestionTexts.add(question.text);
      }
    }

    for (var question in mediumQuestions) {
      if (selectedMedium.length >= targetMedium) break;
      if (!usedQuestionTexts.contains(question.text)) {
        selectedMedium.add(question);
        usedQuestionTexts.add(question.text);
      }
    }

    for (var question in hardQuestions) {
      if (selectedHard.length >= targetHard) break;
      if (!usedQuestionTexts.contains(question.text)) {
        selectedHard.add(question);
        usedQuestionTexts.add(question.text);
      }
    }

    int neededEasy = targetEasy - selectedEasy.length;
    int neededMedium = targetMedium - selectedMedium.length;
    int neededHard = targetHard - selectedHard.length;

    List<Question> remainingEasy = easyQuestions
        .where((q) => !usedQuestionTexts.contains(q.text))
        .toList();
    List<Question> remainingMedium = mediumQuestions
        .where((q) => !usedQuestionTexts.contains(q.text))
        .toList();
    List<Question> remainingHard = hardQuestions
        .where((q) => !usedQuestionTexts.contains(q.text))
        .toList();

    if (neededEasy > 0) {
      for (var question in remainingMedium) {
        if (selectedEasy.length >= targetEasy) break;
        if (!usedQuestionTexts.contains(question.text)) {
          selectedEasy.add(question);
          usedQuestionTexts.add(question.text);
        }
      }

      if (selectedEasy.length < targetEasy) {
        for (var question in remainingHard) {
          if (selectedEasy.length >= targetEasy) break;
          if (!usedQuestionTexts.contains(question.text)) {
            selectedEasy.add(question);
            usedQuestionTexts.add(question.text);
          }
        }
      }
    }

    if (neededMedium > 0) {
      for (var question in remainingEasy) {
        if (selectedMedium.length >= targetMedium) break;
        if (!usedQuestionTexts.contains(question.text)) {
          selectedMedium.add(question);
          usedQuestionTexts.add(question.text);
        }
      }

      if (selectedMedium.length < targetMedium) {
        for (var question in remainingHard) {
          if (selectedMedium.length >= targetMedium) break;
          if (!usedQuestionTexts.contains(question.text)) {
            selectedMedium.add(question);
            usedQuestionTexts.add(question.text);
          }
        }
      }
    }

    if (neededHard > 0) {
      for (var question in remainingMedium) {
        if (selectedHard.length >= targetHard) break;
        if (!usedQuestionTexts.contains(question.text)) {
          selectedHard.add(question);
          usedQuestionTexts.add(question.text);
        }
      }

      if (selectedHard.length < targetHard) {
        for (var question in remainingEasy) {
          if (selectedHard.length >= targetHard) break;
          if (!usedQuestionTexts.contains(question.text)) {
            selectedHard.add(question);
            usedQuestionTexts.add(question.text);
          }
        }
      }
    }

    List<Question> selectedQuestions = [];
    selectedQuestions.addAll(selectedEasy);
    selectedQuestions.addAll(selectedMedium);
    selectedQuestions.addAll(selectedHard);

    Set<String> finalCheck = {};
    List<Question> uniqueQuestions = [];
    for (var question in selectedQuestions) {
      if (!finalCheck.contains(question.text)) {
        uniqueQuestions.add(question);
        finalCheck.add(question.text);
      }
    }
    selectedQuestions = uniqueQuestions;

    final result = selectedQuestions.map((question) {
      return Question.withRandomizedAnswers(
        text: question.text,
        answers: question.answers,
        difficulty: question.difficulty,
        packageId: question.packageId,
      );
    }).toList();

    return result;
  }

  Future<List<String>> getPurchasedPackages() async {

    final packageService = PackageService();
    List<String> purchased = [];

    try {
      final packages = await packageService.getActivePackages();

      for (final package in packages) {

        if (await _purchaseService.isPackagePurchased(package.id)) {
          purchased.add(package.id);
        }
      }

      final legacyPackages = ['history', 'more_questions'];
      for (final legacyId in legacyPackages) {
        if (await _purchaseService.isPackagePurchased(legacyId)) {

          if (!purchased.contains(legacyId)) {
            purchased.add(legacyId);
          }
        }
      }
    } catch (e) {
      final availablePackages = ['history', 'more_questions'];
      for (final packageId in availablePackages) {
        if (await _purchaseService.isPackagePurchased(packageId)) {
          purchased.add(packageId);
        }
      }
    }

    return purchased;
  }

  Future<List<Question>> prepareGameQuestions(String language) async {
    final purchasedPackages = await getPurchasedPackages();

    final allQuestions = await getQuestions(
      language: language,
      purchasedPackageIds: purchasedPackages,
    );

    return selectGameQuestions(allQuestions);
  }

  Question? getAlternativeQuestion(
    Question currentQuestion,
    List<Question> allAvailableQuestions,
    List<Question> usedQuestions,
  ) {
    final usedTexts = usedQuestions.map((q) => q.text).toSet();
    usedTexts.add(currentQuestion.text);

    final sameDifficultyQuestions = allAvailableQuestions
        .where((q) => q.difficulty == currentQuestion.difficulty)
        .where((q) => !usedTexts.contains(q.text))
        .toList();

    if (sameDifficultyQuestions.isEmpty) {
      return null;
    }

    sameDifficultyQuestions.shuffle();
    final alternative = sameDifficultyQuestions.first;

    final originalAnswers = List<String>.from(alternative.answers);
    final correctAnswerText = originalAnswers[alternative.correctAnswerIndex];

    originalAnswers.remove(correctAnswerText);
    originalAnswers.insert(0, correctAnswerText);

    return Question.withRandomizedAnswers(
      text: alternative.text,
      answers: originalAnswers,
      difficulty: alternative.difficulty,
      packageId: alternative.packageId,
    );
  }
}

