import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../providers/game_provider.dart';
import '../providers/language_provider.dart';
import '../services/timer_service.dart';
import '../services/question_service.dart';
import '../widgets/answer_button.dart';
import '../widgets/package_badge.dart';
import '../services/package_service.dart';
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

  void _handleTimeout() {
    _timerService?.stop();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const TimeoutScreen()),
    );
  }

  Widget _buildHintButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required bool isUsed,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: isUsed
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.questionCardBackground,
                      AppColors.questionCardBackgroundLight,
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.white.withOpacity(0.9),
                    ],
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUsed 
                  ? AppColors.cardBorder.withOpacity(0.3)
                  : Colors.white,
              width: 2,
            ),
            boxShadow: isUsed
                ? [
                    BoxShadow(
                      color: AppColors.questionCardBackground.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AppColors.glowPurple.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon),
            iconSize: 32,
            color: isUsed 
                ? AppColors.textSecondary 
                : AppColors.cardBackground,
            tooltip: label,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isUsed 
                ? AppColors.textSecondary 
                : AppColors.cardBackground,
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

        final languageProvider = Provider.of<LanguageProvider>(context);
        final questionNumber = gameProvider.currentQuestionIndex + 1;
        final totalQuestions = gameProvider.questions.length;
        final progress = questionNumber / totalQuestions;
        
        // Определяем название категории
        String categoryName = currentQuestion.packageId != null
            ? 'Пакет'
            : (languageProvider.currentLanguage == 'KZ' ? 'Негізгі' : 'Базовые');
        
        return Scaffold(
          backgroundColor: AppColors.gameBackgroundTop,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.splashTop,
                  AppColors.splashMiddle,
                  AppColors.splashMiddle2,
                  AppColors.splashBottom,
                  AppColors.splashAccent,
                  AppColors.cardBackground,
                ],
                stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Декоративные элементы фона
                Positioned(
                  top: -60,
                  right: -60,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.splashAccent.withOpacity(0.3),
                          AppColors.splashMiddle.withOpacity(0.15),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -80,
                  left: -80,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.splashBottom.withOpacity(0.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                // Навигационная панель
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppColors.cardBackground),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      Expanded(
                        child: Text(
                          categoryName,
                          style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.cardBackground,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // Для баланса
                    ],
                  ),
                ),
                
                // Progress bar с эффектом свечения
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.glowCyan.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.progressBackground,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.progressFill),
                        minHeight: 8,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Номер вопроса и таймер
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        languageProvider.currentLanguage == 'KZ'
                            ? 'Сұрақ $questionNumber / $totalQuestions'
                            : 'Вопрос $questionNumber из $totalQuestions',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: AppColors.cardBackground,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.timer,
                            size: 18,
                            color: AppColors.cardBackground,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '00:${_secondsRemaining.toString().padLeft(2, '0')}',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              color: AppColors.cardBackground,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Карточка с вопросом
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        // Значок пакета (если вопрос из пакета)
                        if (currentQuestion.packageId != null) ...[
                          PackageBadge(
                            color: _getPackageColor(currentQuestion.packageId),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Текст вопроса с эффектом стекла
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Text(
                                currentQuestion.text,
                                style: GoogleFonts.nunito(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  height: 1.5,
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Кнопки ответов
                        ...List.generate(currentQuestion.answers.length, (index) {
                          if (_hiddenAnswerIndices.contains(index)) {
                            return const SizedBox.shrink();
                          }
                          
                          final labels = ['A', 'B', 'C', 'D', 'E', 'F'];
                          
                          return AnswerButton(
                            text: currentQuestion.answers[index],
                            label: labels[index],
                            isSelected: _selectedAnswerIndex == index && !_isHint1Active,
                            state: _answerStates[index] ?? AnswerButtonState.normal,
                            onPressed: _isHint1Active || _selectedAnswerIndex == -1
                                ? () => _handleAnswerSelected(index)
                                : null,
                          );
                        }),
                        
                        const SizedBox(height: 24),
                        
                        // Кнопки подсказок
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildHintButton(
                              icon: Icons.check_circle_outline,
                              label: languageProvider.currentLanguage == 'KZ' ? 'Тексеру' : 'Проверка',
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
                              label: languageProvider.currentLanguage == 'KZ' ? 'Ауыстыру' : 'Замена',
                              onPressed: _hint3Used ? null : _activateHint3,
                              isUsed: _hint3Used,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Кнопка Check с эффектом свечения
                        if (_selectedAnswerIndex != -1 && !_isHint1Active)
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.startButton.withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                                BoxShadow(
                                  color: AppColors.glowPink.withOpacity(0.3),
                                  blurRadius: 30,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  _handleAnswerSelected(_selectedAnswerIndex);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.startButton,
                                  foregroundColor: AppColors.textPrimary,
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  languageProvider.currentLanguage == 'KZ' ? 'Тексеру' : 'Check',
                                  style: GoogleFonts.nunito(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

