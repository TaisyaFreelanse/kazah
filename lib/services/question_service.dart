import '../models/question.dart';
import '../models/package_info.dart';
import 'excel_parser.dart';
import 'purchase_service.dart';
import 'package_service.dart';
import 'package_file_service.dart';

class QuestionService {
  final ExcelParser _excelParser = ExcelParser();
  final PurchaseService _purchaseService = PurchaseService();
  final PackageFileService _packageFileService = PackageFileService();

  /// Загружает все доступные вопросы (базовые + купленные пакеты)
  Future<List<Question>> getQuestions({
    required String language,
    List<String> purchasedPackageIds = const [],
  }) async {
    List<Question> allQuestions = [];

    // Загружаем базовые вопросы
    print('Получен язык: "$language" (длина: ${language.length})');
    final baseQuestionsPath = language == 'KZ'
        ? 'assets/data/questions_kz.xlsx'
        : 'assets/data/questions_ru.xlsx';

    print('Загрузка базовых вопросов из: $baseQuestionsPath (язык: $language)');
    final baseQuestions = await _excelParser.parseQuestions(
      assetPath: baseQuestionsPath,
      packageId: null, // Базовые вопросы не имеют packageId
    );
    print('Загружено базовых вопросов: ${baseQuestions.length}');
    allQuestions.addAll(baseQuestions);

    // Загружаем вопросы из купленных пакетов
    for (final packageId in purchasedPackageIds) {
      final packageQuestions = await _loadPackageQuestions(
        packageId: packageId,
        language: language,
      );
      allQuestions.addAll(packageQuestions);
    }

    return allQuestions;
  }

  /// Загружает вопросы из конкретного пакета
  /// Поддерживает как числовые ID из API, так и строковые (legacy)
  /// Приоритет: загрузка с сервера > локальные assets
  Future<List<Question>> _loadPackageQuestions({
    required String packageId,
    required String language,
  }) async {
    // Сначала пытаемся получить информацию о пакете из API
    final packageService = PackageService();
    PackageInfo? packageInfo;
    
    try {
      packageInfo = await packageService.getPackageById(packageId);
    } catch (e) {
      print('Не удалось получить информацию о пакете $packageId из API: $e');
    }
    
    // Проверяем, является ли ID числовым (из API)
    final isNumericId = int.tryParse(packageId) != null;
    
    // Приоритет 1: Пытаемся загрузить файл с сервера (для числовых ID из API)
    if (isNumericId && packageInfo != null) {
      try {
        // Пытаемся загрузить файл с сервера
        final filePath = await _packageFileService.downloadPackageFile(
          packageId: packageId,
          language: language,
        );
        
        if (filePath != null) {
          print('Загружаем вопросы из файла с сервера: $filePath');
          try {
            return await _excelParser.parseQuestions(
              assetPath: filePath,
              packageId: packageId,
            );
          } catch (e) {
            print('Ошибка парсинга файла с сервера, пробуем fallback: $e');
            // Продолжаем к fallback
          }
        }
      } catch (e) {
        print('Ошибка загрузки файла с сервера, пробуем fallback: $e');
        // Продолжаем к fallback
      }
    }
    
    // Приоритет 2: Fallback на локальные assets (для обратной совместимости)
    String? assetPath;
    
    if (isNumericId && packageInfo != null) {
      // Для числовых ID из API используем маппинг по имени пакета
      final packageName = packageInfo.nameKz.toLowerCase();
      if (packageName.contains('тарих') || packageName.contains('история') || 
          packageInfo.nameRu.toLowerCase().contains('история')) {
        assetPath = language == 'KZ'
            ? 'assets/data/history_kz.xlsx'
            : 'assets/data/history_ru.xlsx';
      } else if (packageName.contains('көбірек') || packageName.contains('больше') ||
                 packageInfo.nameRu.toLowerCase().contains('больше')) {
        // Для пакета "Больше вопросов" используем fallback на assets или возвращаем пустой список
        assetPath = null; // Файлы могут быть загружены с сервера выше
      }
    } else {
      // Для строковых ID (legacy) используем старый маппинг
      switch (packageId) {
        case 'history':
          assetPath = language == 'KZ'
              ? 'assets/data/history_kz.xlsx'
              : 'assets/data/history_ru.xlsx';
          break;
        case 'more_questions':
          // Для пакета "Больше вопросов" нет локальных файлов
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
      print('Ошибка загрузки пакета $packageId: $e');
      return [];
    }
  }

  /// Выбирает 13 вопросов для игры: 4 простых + 6 средних + 3 сложных
  /// И применяет рандомизацию ответов
  List<Question> selectGameQuestions(List<Question> allQuestions) {
    // Разделяем вопросы по сложности
    final easyQuestions = allQuestions
        .where((q) => q.difficulty == Difficulty.easy)
        .toList();
    final mediumQuestions = allQuestions
        .where((q) => q.difficulty == Difficulty.medium)
        .toList();
    final hardQuestions = allQuestions
        .where((q) => q.difficulty == Difficulty.hard)
        .toList();

    // Перемешиваем каждый список
    easyQuestions.shuffle();
    mediumQuestions.shuffle();
    hardQuestions.shuffle();

    // Выбираем нужное количество (4 простых, 6 средних, 3 сложных)
    final selectedEasy = easyQuestions.take(4).toList();
    final selectedMedium = mediumQuestions.take(6).toList();
    final selectedHard = hardQuestions.take(3).toList();

    // Проверяем, что достаточно вопросов
    if (selectedEasy.length < 4 ||
        selectedMedium.length < 6 ||
        selectedHard.length < 3) {
      print('Предупреждение: недостаточно вопросов для игры');
    }

    // Объединяем все выбранные вопросы
    List<Question> selectedQuestions = [];
    selectedQuestions.addAll(selectedEasy);
    selectedQuestions.addAll(selectedMedium);
    selectedQuestions.addAll(selectedHard);

    // Перемешиваем порядок вопросов
    selectedQuestions.shuffle();

    // Применяем рандомизацию ответов для каждого вопроса
    return selectedQuestions.map((question) {
      // Используем исходные ответы (правильный всегда первый, индекс 0)
      // Вопросы из парсера уже имеют правильный ответ с индексом 0
      return Question.withRandomizedAnswers(
        text: question.text,
        answers: question.answers, // Ответы уже в правильном формате
        difficulty: question.difficulty,
        packageId: question.packageId,
      );
    }).toList();
  }

  /// Получает список купленных пакетов
  /// Возвращает ID пакетов, которые были куплены пользователем
  /// ID могут быть как строковыми (для старых покупок), так и числовыми (из API)
  Future<List<String>> getPurchasedPackages() async {
    // Получаем все доступные пакеты из API
    final packageService = PackageService();
    List<String> purchased = [];
    
    try {
      final packages = await packageService.getActivePackages();
      
      // Проверяем каждый пакет из API
      for (final package in packages) {
        // Проверяем покупку по ID из API
        if (await _purchaseService.isPackagePurchased(package.id)) {
          purchased.add(package.id);
        }
      }
      
      // Также проверяем старые покупки по строковым ID (для обратной совместимости)
      final legacyPackages = ['history', 'more_questions'];
      for (final legacyId in legacyPackages) {
        if (await _purchaseService.isPackagePurchased(legacyId)) {
          // Проверяем, не добавлен ли уже этот пакет
          if (!purchased.contains(legacyId)) {
            purchased.add(legacyId);
          }
        }
      }
    } catch (e) {
      print('Ошибка получения пакетов из API, используем fallback: $e');
      // Fallback на старый способ при ошибке API
      final availablePackages = ['history', 'more_questions'];
      for (final packageId in availablePackages) {
        if (await _purchaseService.isPackagePurchased(packageId)) {
          purchased.add(packageId);
        }
      }
    }

    return purchased;
  }

  /// Полная загрузка и подготовка вопросов для игры
  Future<List<Question>> prepareGameQuestions(String language) async {
    // Получаем купленные пакеты
    final purchasedPackages = await getPurchasedPackages();

    // Загружаем все вопросы
    final allQuestions = await getQuestions(
      language: language,
      purchasedPackageIds: purchasedPackages,
    );

    // Выбираем и рандомизируем 13 вопросов
    return selectGameQuestions(allQuestions);
  }

  /// Получает альтернативный вопрос того же уровня сложности
  /// Исключает текущий вопрос и вопросы, уже используемые в игре
  /// ВАЖНО: allAvailableQuestions должны быть уже рандомизированы
  Question? getAlternativeQuestion(
    Question currentQuestion,
    List<Question> allAvailableQuestions,
    List<Question> usedQuestions,
  ) {
    // Фильтруем вопросы по сложности
    final sameDifficultyQuestions = allAvailableQuestions
        .where((q) => q.difficulty == currentQuestion.difficulty)
        .where((q) => q.text != currentQuestion.text) // Исключаем текущий вопрос
        .where((q) => !usedQuestions.any((used) => used.text == q.text)) // Исключаем уже использованные
        .toList();

    if (sameDifficultyQuestions.isEmpty) return null;

    // Перемешиваем и берем первый
    sameDifficultyQuestions.shuffle();
    final alternative = sameDifficultyQuestions.first;

    // Для правильной рандомизации нужно восстановить исходный порядок
    // Правильный ответ находится на позиции correctAnswerIndex
    final originalAnswers = List<String>.from(alternative.answers);
    final correctAnswerText = originalAnswers[alternative.correctAnswerIndex];
    
    // Перемещаем правильный ответ на первое место для корректной рандомизации
    originalAnswers.remove(correctAnswerText);
    originalAnswers.insert(0, correctAnswerText);

    // Применяем новую рандомизацию ответов
    return Question.withRandomizedAnswers(
      text: alternative.text,
      answers: originalAnswers,
      difficulty: alternative.difficulty,
      packageId: alternative.packageId,
    );
  }
}

