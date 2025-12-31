import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/language_provider.dart';
import '../services/timer_service.dart';
import '../services/question_service.dart';
import '../services/package_service.dart';
import '../widgets/timer_widget.dart';
import '../widgets/answer_button.dart';
import '../widgets/package_badge.dart';
import '../constants/colors.dart';
import '../models/question.dart';
import 'result_screen.dart';
import 'timeout_screen.dart';
import 'main_menu_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  TimerService? _timerService;
  final PackageService _packageService = PackageService();
  Map<String, Color> _packageColors = {}; // Кэш цветов пакетов
  int _selectedAnswerIndex = -1;
  int _secondsRemaining = 13;
  Set<int> _hiddenAnswerIndices = {}; // Для подсказки 50/50
  Map<int, AnswerButtonState> _answerStates = {}; // Состояния кнопок для подсказки 1
  bool _isHint1Active = false; // Флаг активной подсказки 1
  bool _hint1Used = false;
  bool _hint2Used = false;
  bool _hint3Used = false;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() async {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    
    print('=== ИНИЦИАЛИЗАЦИЯ ИГРЫ ===');
    print('Выбранный язык: "${languageProvider.currentLanguage}"');
    
    // Загружаем цвета пакетов из API
    await _loadPackageColors();
    
    // Инициализируем таймер
    _timerService = TimerService(
      onTick: (seconds) {
        setState(() {
          _secondsRemaining = seconds;
        });
      },
      onTimeout: () {
        _handleTimeout();
      },
    );
    
    // Загружаем вопросы из QuestionService
    final questionService = QuestionService();
    try {
      final selectedLanguage = languageProvider.currentLanguage;
      print('Подготовка вопросов для языка: "$selectedLanguage"');
      final questions = await questionService.prepareGameQuestions(
        selectedLanguage,
      );
      
      if (questions.isEmpty) {
        // Если нет вопросов, возвращаемся в меню
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainMenuScreen()),
          );
        }
        return;
      }
      
      // Получаем все доступные вопросы для подсказки 3 (без рандомизации)
      // Нужны исходные вопросы для правильной работы подсказки 3
      final purchasedPackages = await questionService.getPurchasedPackages();
      final allQuestionsRaw = await questionService.getQuestions(
        language: languageProvider.currentLanguage,
        purchasedPackageIds: purchasedPackages,
      );
      
      // Применяем рандомизацию ко всем вопросам для подсказки 3
      final allQuestions = allQuestionsRaw.map((q) {
        // Восстанавливаем исходный порядок ответов
        final originalAnswers = List<String>.from(q.answers);
        final correctAnswerText = originalAnswers[q.correctAnswerIndex];
        originalAnswers.remove(correctAnswerText);
        originalAnswers.insert(0, correctAnswerText);
        
        // Применяем рандомизацию
        return Question.withRandomizedAnswers(
          text: q.text,
          answers: originalAnswers,
          difficulty: q.difficulty,
          packageId: q.packageId,
        );
      }).toList();
      
      // Запускаем игру с загруженными вопросами
      gameProvider.startGame(questions, allAvailableQuestions: allQuestions);
      
      // Запускаем таймер для первого вопроса
      if (mounted) {
        _startTimerForQuestion();
      }
    } catch (e) {
      print('Ошибка загрузки вопросов: $e');
      // В случае ошибки возвращаемся в меню
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainMenuScreen()),
        );
      }
    }
  }

  void _startTimerForQuestion() {
    _timerService?.reset();
    _timerService?.start();
    setState(() {
      _secondsRemaining = 13;
      _selectedAnswerIndex = -1;
      _hiddenAnswerIndices.clear();
      _answerStates.clear();
      _isHint1Active = false;
    });
  }

  void _handleTimeout() {
    _timerService?.stop();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const TimeoutScreen()),
    );
  }

  /// Загружает цвета пакетов из API
  Future<void> _loadPackageColors() async {
    try {
      final packages = await _packageService.getActivePackages();
      _packageColors = {
        for (var package in packages) package.id: package.color,
      };
      print('Загружено цветов пакетов: ${_packageColors.length}');
    } catch (e) {
      print('Ошибка загрузки цветов пакетов: $e');
      // Используем дефолтные цвета при ошибке
      _packageColors = {
        'more_questions': AppColors.packageMoreQuestions,
        'history': AppColors.packageHistory,
      };
    }
  }

  /// Получает цвет значка пакета
  Color _getPackageColor(String? packageId) {
    if (packageId == null) return Colors.transparent;
    
    // Пытаемся получить цвет из кэша
    if (_packageColors.containsKey(packageId)) {
      return _packageColors[packageId]!;
    }
    
    // Если цвет не найден, пытаемся загрузить из API (асинхронно)
    _packageService.getPackageColor(packageId).then((color) {
      if (color != null && mounted) {
        setState(() {
          _packageColors[packageId] = color;
        });
      }
    });
    
    // Возвращаем дефолтный цвет или серый
    return _packageColors[packageId] ?? Colors.grey;
  }

  Widget _buildHintButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required bool isUsed,
  }) {
    return Column(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          iconSize: 32,
          color: isUsed ? Colors.grey : Colors.blue,
          tooltip: label,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isUsed ? Colors.grey : Colors.black87,
          ),
        ),
      ],
    );
  }

  void _handleAnswerSelected(int answerIndex) {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final currentQuestion = gameProvider.currentQuestion;
    
    if (currentQuestion == null) return;
    
    // Если активна подсказка 1 (проверка ответа)
    if (_isHint1Active) {
      _showHint1Feedback(answerIndex, currentQuestion);
      return;
    }
    
    // Обычный выбор ответа (завершает вопрос)
    if (_selectedAnswerIndex != -1) return; // Уже выбран ответ
    if (_hiddenAnswerIndices.contains(answerIndex)) return; // Ответ скрыт подсказкой 50/50
    
    setState(() {
      _selectedAnswerIndex = answerIndex;
    });
    
    _timerService?.stop();
    
    // Проверяем правильность ответа
    final isCorrect = answerIndex == currentQuestion.correctAnswerIndex;
    
    // Небольшая задержка перед переходом
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      
      if (gameProvider.currentQuestionIndex < gameProvider.questions.length - 1) {
        // Переход к следующему вопросу
        gameProvider.nextQuestion();
        _startTimerForQuestion();
      } else {
        // Игра завершена - переход на экран победы
        gameProvider.nextQuestion(); // Завершаем игру
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ResultScreen()),
        );
      }
    });
  }

  /// Подсказка 1: Показать обратную связь (Верно/Неверно)
  void _showHint1Feedback(int answerIndex, Question currentQuestion) {
    final isCorrect = answerIndex == currentQuestion.correctAnswerIndex;
    
    setState(() {
      _answerStates[answerIndex] = isCorrect 
          ? AnswerButtonState.correct 
          : AnswerButtonState.incorrect;
    });
    
    // Через 2 секунды возвращаем в исходное состояние
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _answerStates.remove(answerIndex);
      });
    });
  }

  /// Подсказка 1: Активация проверки ответа
  void _activateHint1() {
    if (_hint1Used) return;
    setState(() {
      _isHint1Active = true;
      _hint1Used = true;
    });
  }

  /// Подсказка 2: 50/50 - скрыть 3 неправильных ответа
  void _activateHint2() {
    if (_hint2Used) return;
    
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final currentQuestion = gameProvider.currentQuestion;
    if (currentQuestion == null) return;
    
    // Находим все неправильные индексы
    final wrongIndices = List.generate(
      6,
      (index) => index != currentQuestion.correctAnswerIndex ? index : -1,
    ).where((index) => index != -1).toList();
    
    // Перемешиваем и берем 3 случайных
    wrongIndices.shuffle();
    final indicesToHide = wrongIndices.take(3).toSet();
    
    setState(() {
      _hiddenAnswerIndices = indicesToHide;
      _hint2Used = true;
    });
  }

  /// Подсказка 3: Замена вопроса
  void _activateHint3() async {
    if (_hint3Used) return;
    
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final currentQuestion = gameProvider.currentQuestion;
    if (currentQuestion == null) return;
    
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final questionService = QuestionService();
    
    // Получаем альтернативный вопрос
    final alternativeQuestion = questionService.getAlternativeQuestion(
      currentQuestion,
      gameProvider.allAvailableQuestions,
      gameProvider.questions,
    );
    
    if (alternativeQuestion == null) {
      // Если альтернативного вопроса нет, просто используем текущий
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет доступных альтернативных вопросов')),
      );
      return;
    }
    
    // Заменяем вопрос
    gameProvider.replaceCurrentQuestion(alternativeQuestion);
    
    // Сбрасываем таймер и запускаем заново
    _timerService?.reset();
    _timerService?.start();
    setState(() {
      _secondsRemaining = 13;
      _selectedAnswerIndex = -1;
      _hiddenAnswerIndices.clear();
      _answerStates.clear();
      _isHint1Active = false;
      _hint3Used = true;
    });
  }

  @override
  void dispose() {
    _timerService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final currentQuestion = gameProvider.currentQuestion;
        
        if (currentQuestion == null) {
          // Если вопроса нет, возвращаемся в меню
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainMenuScreen()),
            );
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Таймер сверху
                  Center(
                    child: TimerWidget(secondsRemaining: _secondsRemaining),
                  ),
                  const SizedBox(height: 16),
                  
                  // Кнопки подсказок
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildHintButton(
                        icon: Icons.check_circle_outline,
                        label: 'Проверка',
                        onPressed: _hint1Used ? null : _activateHint1,
                        isUsed: _hint1Used,
                      ),
                      _buildHintButton(
                        icon: Icons.hide_source,
                        label: '50/50',
                        onPressed: _hint2Used ? null : _activateHint2,
                        isUsed: _hint2Used,
                      ),
                      _buildHintButton(
                        icon: Icons.swap_horiz,
                        label: 'Замена',
                        onPressed: _hint3Used ? null : _activateHint3,
                        isUsed: _hint3Used,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Значок пакета (если вопрос из пакета) и текст вопроса
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (currentQuestion.packageId != null) ...[
                        PackageBadge(
                          color: _getPackageColor(currentQuestion.packageId),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          currentQuestion.text,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // 6 кнопок ответов
                  Expanded(
                    child: ListView.builder(
                      itemCount: currentQuestion.answers.length,
                      itemBuilder: (context, index) {
                        if (_hiddenAnswerIndices.contains(index)) {
                          return const SizedBox.shrink();
                        }
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: AnswerButton(
                            text: currentQuestion.answers[index],
                            isSelected: _selectedAnswerIndex == index && !_isHint1Active,
                            state: _answerStates[index] ?? AnswerButtonState.normal,
                            onPressed: _isHint1Active || _selectedAnswerIndex == -1
                                ? () => _handleAnswerSelected(index)
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

