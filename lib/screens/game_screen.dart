import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:async';
import '../providers/game_provider.dart';
import '../providers/language_provider.dart';
import '../services/timer_service.dart';
import '../services/question_service.dart';
import '../widgets/answer_button.dart';
import '../widgets/package_badge.dart';
import '../services/package_service.dart';
import '../constants/colors.dart';
import '../models/question.dart';
import '../utils/responsive.dart';
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
  final PackageService _packageService = PackageService.instance;
  Map<String, Color> _packageColors = {};
  int _selectedAnswerIndex = -1;
  int _secondsRemaining = 23;
  Set<int> _hiddenAnswerIndices = {};
  Map<int, AnswerButtonState> _answerStates = {};
  bool _isHint1Active = false;
  bool _hint1Used = false;
  bool _hint2Used = false;
  bool _hint3Used = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() async {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

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

    final questionService = QuestionService.instance;
    final selectedLanguage = languageProvider.currentLanguage;

    try {
      final purchasedPackages = await questionService.getPurchasedPackages();

      final results = await Future.wait([
        questionService.getQuestions(
          language: selectedLanguage,
          purchasedPackageIds: purchasedPackages,
        ),
        _loadPackageColors(),
      ]);

      final allQuestionsRaw = results[0] as List<Question>;

      if (allQuestionsRaw.isEmpty) {

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainMenuScreen()),
          );
        }
        return;
      }

      final questions = questionService.selectGameQuestions(allQuestionsRaw);

      final allQuestions = allQuestionsRaw.map((q) {

        final originalAnswers = List<String>.from(q.answers);
        final correctAnswerText = originalAnswers[q.correctAnswerIndex];
        originalAnswers.remove(correctAnswerText);
        originalAnswers.insert(0, correctAnswerText);

        return Question.withRandomizedAnswers(
          text: q.text,
          answers: originalAnswers,
          difficulty: q.difficulty,
          packageId: q.packageId,
        );
      }).toList();

      gameProvider.startGame(questions, allAvailableQuestions: allQuestions);

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        _startTimerForQuestion();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
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
      _secondsRemaining = 23;
      _selectedAnswerIndex = -1;
      _hiddenAnswerIndices.clear();
      _answerStates.clear();
      _isHint1Active = false;
    });
  }

  Future<void> _loadPackageColors() async {
    try {
      final packages = await _packageService.getActivePackages();
      if (mounted) {
        setState(() {
          _packageColors = {
            for (var package in packages) package.id: package.color,
          };
        });
      } else {
        _packageColors = {
          for (var package in packages) package.id: package.color,
        };
      }
    } catch (e) {
      _packageColors = {
        'more_questions': AppColors.packageMoreQuestions,
        'history': AppColors.packageHistory,
      };
    }
  }

  Color _getPackageColor(String? packageId) {
    if (packageId == null) return Colors.transparent;

    if (_packageColors.containsKey(packageId)) {
      return _packageColors[packageId]!;
    }

    _packageService.getPackageColor(packageId).then((color) {
      if (color != null && mounted) {
        setState(() {
          _packageColors[packageId] = color;
        });
      }
    });

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
    final screenHeight = Responsive.screenHeight(context);
    final isSmallScreen = screenHeight < 700;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
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
            borderRadius: BorderRadius.circular(Responsive.dp(context, 12)),
            border: Border.all(
              color: isUsed 
                  ? AppColors.cardBorder.withOpacity(0.3)
                  : Colors.white,
              width: Responsive.dp(context, 1.5),
            ),
            boxShadow: isUsed
                ? [
                    BoxShadow(
                      color: AppColors.questionCardBackground.withOpacity(0.3),
                      blurRadius: Responsive.dp(context, 8),
                      spreadRadius: Responsive.dp(context, 1),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AppColors.glowPurple.withOpacity(0.3),
                      blurRadius: Responsive.dp(context, 8),
                      spreadRadius: Responsive.dp(context, 1),
                    ),
                  ],
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon),
            iconSize: Responsive.dp(context, isSmallScreen ? 20 : 24),
            color: isUsed 
                ? AppColors.textSecondary 
                : AppColors.cardBackground,
            tooltip: label,
            padding: EdgeInsets.all(Responsive.dp(context, 8)),
            constraints: BoxConstraints(
              minWidth: Responsive.dp(context, isSmallScreen ? 40 : 44),
              minHeight: Responsive.dp(context, isSmallScreen ? 40 : 44),
            ),
          ),
        ),
        SizedBox(height: Responsive.dp(context, 4)),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: Responsive.textSize(context, isSmallScreen ? 9 : 10),
            fontWeight: FontWeight.w600,
            color: isUsed 
                ? AppColors.textSecondary 
                : AppColors.cardBackground,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _handleAnswerSelected(int answerIndex) {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final currentQuestion = gameProvider.currentQuestion;

    if (currentQuestion == null) return;

    if (_isHint1Active) {
      _showHint1Feedback(answerIndex, currentQuestion);
      return;
    }

    if (_selectedAnswerIndex != -1 && !_hint1Used) return;
    if (_hiddenAnswerIndices.contains(answerIndex)) return;

    setState(() {
      _selectedAnswerIndex = answerIndex;
    });

    _timerService?.stop();

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      final isCorrect = gameProvider.checkAnswer(answerIndex);

      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;

        if (!isCorrect) {
          gameProvider.nextQuestion();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ResultScreen()),
          );
          return;
        }

        if (gameProvider.currentQuestionIndex < gameProvider.questions.length - 1) {

          gameProvider.nextQuestion();
          _startTimerForQuestion();
        } else {

          gameProvider.nextQuestion();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ResultScreen()),
          );
        }
      });
    });
  }

  void _showHint1Feedback(int answerIndex, Question currentQuestion) {
    final isCorrect = answerIndex == currentQuestion.correctAnswerIndex;

    setState(() {
      _answerStates[answerIndex] = isCorrect 
          ? AnswerButtonState.correct 
          : AnswerButtonState.incorrect;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _answerStates.clear();
        _isHint1Active = false;

      });
    });
  }

  void _activateHint1() {
    if (_hint1Used) return;
    setState(() {
      _isHint1Active = true;
      _hint1Used = true;
    });
  }

  void _activateHint2() {
    if (_hint2Used) return;

    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final currentQuestion = gameProvider.currentQuestion;
    if (currentQuestion == null) return;

    final wrongIndices = List.generate(
      6,
      (index) => index != currentQuestion.correctAnswerIndex ? index : -1,
    ).where((index) => index != -1).toList();

    wrongIndices.shuffle();
    final indicesToHide = wrongIndices.take(3).toSet();

    setState(() {
      _hiddenAnswerIndices = indicesToHide;
      _hint2Used = true;
    });
  }

  void _activateHint3() async {
    if (_hint3Used) return;

    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final currentQuestion = gameProvider.currentQuestion;
    if (currentQuestion == null) return;

    final questionService = QuestionService.instance;

    final alternativeQuestion = questionService.getAlternativeQuestion(
      currentQuestion,
      gameProvider.allAvailableQuestions,
      gameProvider.questions,
    );

    if (alternativeQuestion == null) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет доступных альтернативных вопросов')),
      );
      return;
    }

    gameProvider.replaceCurrentQuestion(alternativeQuestion);

    _timerService?.reset();
    _timerService?.start();
    setState(() {
      _secondsRemaining = 23;
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

        if (currentQuestion == null || _isInitializing) {

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
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          );
        }

        final languageProvider = Provider.of<LanguageProvider>(context);
        final questionNumber = gameProvider.currentQuestionIndex + 1;
        final totalQuestions = gameProvider.questions.length;
        final progress = questionNumber / totalQuestions;

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

                Positioned(
                  top: -Responsive.heightPercent(context, 7),
                  right: -Responsive.widthPercent(context, 15),
                  child: Container(
                    width: Responsive.widthPercent(context, 62),
                    height: Responsive.widthPercent(context, 62),
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
                  bottom: -Responsive.heightPercent(context, 10),
                  left: -Responsive.widthPercent(context, 20),
                  child: Container(
                    width: Responsive.widthPercent(context, 75),
                    height: Responsive.widthPercent(context, 75),
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

                Padding(
                  padding: Responsive.horizontalPadding(context, small: 16, medium: 20, large: 24).copyWith(
                    top: Responsive.heightPercent(context, 1.5),
                    bottom: Responsive.heightPercent(context, 1.5),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: AppColors.cardBackground,
                          size: Responsive.iconSize(context, small: 24, medium: 28, large: 32),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.timer,
                              size: Responsive.iconSize(context, small: 18, medium: 20, large: 22),
                              color: AppColors.cardBackground,
                            ),
                            SizedBox(width: Responsive.widthPercent(context, 2)),
                            Text(
                              '00:${_secondsRemaining.toString().padLeft(2, '0')}',
                              style: GoogleFonts.nunito(
                                fontSize: Responsive.adaptiveFontSize(context, small: 16, medium: 18, large: 20),
                                fontWeight: FontWeight.bold,
                                color: AppColors.cardBackground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: Responsive.widthPercent(context, 12)),
                    ],
                  ),
                ),

                Padding(
                  padding: Responsive.horizontalPadding(context, small: 16, medium: 20, large: 24),
                  child: Container(
                    height: Responsive.dp(context, 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Responsive.dp(context, 10)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.glowCyan.withOpacity(0.3),
                          blurRadius: Responsive.dp(context, 10),
                          spreadRadius: Responsive.dp(context, 1),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Responsive.dp(context, 10)),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.progressBackground,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.progressFill),
                        minHeight: Responsive.dp(context, 6),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: Responsive.heightPercent(context, 1.5)),

                Padding(
                  padding: Responsive.horizontalPadding(context, small: 16, medium: 20, large: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        languageProvider.currentLanguage == 'KZ'
                            ? 'Сұрақ $questionNumber / $totalQuestions'
                            : 'Вопрос $questionNumber из $totalQuestions',
                        style: GoogleFonts.nunito(
                          fontSize: Responsive.adaptiveFontSize(context, small: 13, medium: 14, large: 15),
                          color: AppColors.cardBackground,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: Responsive.heightPercent(context, 2)),

                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final screenHeight = Responsive.screenHeight(context);
                      final isSmallScreen = screenHeight < 700;

                      return Padding(
                        padding: Responsive.horizontalPadding(context, small: 16, medium: 20, large: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [

                            if (currentQuestion.packageId != null) ...[
                              PackageBadge(
                                color: _getPackageColor(currentQuestion.packageId),
                              ),
                              SizedBox(height: Responsive.dp(context, 8)),
                            ],

                            Flexible(
                              flex: 2,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(Responsive.dp(context, 16)),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: Responsive.dp(context, 10),
                                    sigmaY: Responsive.dp(context, 10),
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    padding: Responsive.symmetricPadding(
                                      context,
                                      small: isSmallScreen ? 12 : 16,
                                      medium: 18,
                                      large: 20,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardBackground.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(Responsive.dp(context, 16)),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: Responsive.dp(context, 2),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: Responsive.dp(context, 15),
                                          spreadRadius: Responsive.dp(context, 1),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        currentQuestion.text,
                                        style: GoogleFonts.nunito(
                                          fontSize: Responsive.textSize(
                                            context,
                                            isSmallScreen ? 14 : 16,
                                          ),
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                          height: 1.3,
                                          letterSpacing: Responsive.dp(context, 0.3),
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 5,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: Responsive.dp(context, isSmallScreen ? 8 : 12)),

                            Flexible(
                              flex: 4,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ...List.generate(currentQuestion.answers.length, (index) {
                                    if (_hiddenAnswerIndices.contains(index)) {
                                      return const SizedBox.shrink();
                                    }

                                    final labels = ['A', 'B', 'C', 'D', 'E', 'F'];

                                    return Flexible(
                                      child: AnswerButton(
                                        text: currentQuestion.answers[index],
                                        label: labels[index],
                                        isSelected: _selectedAnswerIndex == index && !_isHint1Active,
                                        state: _answerStates[index] ?? AnswerButtonState.normal,

                                        onPressed: (_selectedAnswerIndex == -1 || (_hint1Used && !_isHint1Active))
                                            ? () => _handleAnswerSelected(index)
                                            : null,
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),

                            SizedBox(height: Responsive.dp(context, isSmallScreen ? 6 : 8)),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: _buildHintButton(
                                    icon: Icons.check_circle_outline,
                                    label: languageProvider.currentLanguage == 'KZ' ? 'Тексеру' : 'Проверка',
                                    onPressed: _hint1Used ? null : _activateHint1,
                                    isUsed: _hint1Used,
                                  ),
                                ),
                                SizedBox(width: Responsive.dp(context, 8)),
                                Expanded(
                                  child: _buildHintButton(
                                    icon: Icons.hide_source,
                                    label: '50/50',
                                    onPressed: _hint2Used ? null : _activateHint2,
                                    isUsed: _hint2Used,
                                  ),
                                ),
                                SizedBox(width: Responsive.dp(context, 8)),
                                Expanded(
                                  child: _buildHintButton(
                                    icon: Icons.swap_horiz,
                                    label: languageProvider.currentLanguage == 'KZ' ? 'Ауыстыру' : 'Замена',
                                    onPressed: _hint3Used ? null : _activateHint3,
                                    isUsed: _hint3Used,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
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

