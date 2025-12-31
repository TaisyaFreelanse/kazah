import '../models/question.dart';
import 'excel_parser.dart';
import 'purchase_service.dart';

class QuestionService {
  final ExcelParser _excelParser = ExcelParser();
  final PurchaseService _purchaseService = PurchaseService();

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
  Future<List<Question>> _loadPackageQuestions({
    required String packageId,
    required String language,
  }) async {
    // Маппинг ID пакетов на файлы с учетом языка
    String? assetPath;
    switch (packageId) {
      case 'history':
        assetPath = language == 'KZ'
            ? 'assets/data/history_kz.xlsx'
            : 'assets/data/history_ru.xlsx';
        break;
      case 'more_questions':
        // TODO: Добавить файл для пакета "Больше вопросов"
        // assetPath = language == 'KZ'
        //     ? 'assets/data/more_questions_kz.xlsx'
        //     : 'assets/data/more_questions_ru.xlsx';
        break;
      default:
        return [];
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
  Future<List<String>> getPurchasedPackages() async {
    // Проверяем все доступные пакеты
    final availablePackages = ['history', 'more_questions'];
    List<String> purchased = [];

    for (final packageId in availablePackages) {
      if (await _purchaseService.isPackagePurchased(packageId)) {
        purchased.add(packageId);
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

