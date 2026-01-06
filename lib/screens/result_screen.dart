import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'dart:io' if (dart.library.html) '../services/dart_io_stub.dart' as io;
import '../providers/language_provider.dart';
import '../providers/game_provider.dart';
import '../services/excel_parser.dart';
import '../services/public_question_service.dart';
import '../constants/colors.dart';
import '../widgets/menu_button.dart';
import '../constants/strings.dart';
import '../utils/responsive.dart';
import 'game_screen.dart';
import 'main_menu_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  String _motivationalPhrase = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMotivationalPhrase();
  }

  Future<void> _loadMotivationalPhrase() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final currentLanguage = languageProvider.currentLanguage;

    if (!gameProvider.isGameWon) {
      setState(() {
        _motivationalPhrase = AppStrings.getString(AppStrings.wrongAnswerMessage, currentLanguage);
        _isLoading = false;
      });
      return;
    }

    try {
      final excelParser = ExcelParser.instance;
      final publicQuestionService = PublicQuestionService();
      List<String> phrases = [];

      final normalizedLanguage = currentLanguage.toUpperCase() == 'KZ' ? 'kz' : 'ru';

      if (kIsWeb) {
        try {
          final bytes = await publicQuestionService.downloadFinalPhrasesFile(language: normalizedLanguage);
          if (bytes != null) {
            final base64Data = base64Encode(bytes);
            phrases = await excelParser.parsePhrases(assetPath: 'bytes:$base64Data');
          }
        } catch (e) {
        }
      } else {
        try {
          final bytes = await publicQuestionService.downloadFinalPhrasesFile(language: normalizedLanguage);
          if (bytes != null) {
            final appDir = await getApplicationDocumentsDirectory();
            final tempFile = io.File(path.join(appDir.path, 'phrases_$normalizedLanguage.xlsx'));
            await tempFile.writeAsBytes(bytes);
            phrases = await excelParser.parsePhrases(assetPath: tempFile.path);
            try {
              await tempFile.delete();
            } catch (_) {}
          }
        } catch (e) {
        }
      }

      final validPhrases = phrases.where((p) {
        final trimmed = p.trim();

        if (trimmed.endsWith('?') || trimmed.endsWith('?')) return false;
        if (trimmed.length > 150) return false;
        final lower = trimmed.toLowerCase();
        final questionWords = ['кто', 'что', 'где', 'когда', 'как', 'почему', 'зачем', 'сколько', 
                              'чей', 'какой', 'какая', 'какое', 'какие', 'кем', 'чем',
                              'кто является', 'что является', 'как называется', 'в каком', 'у какого',
                              'қай', 'қандай', 'қанша', 'неше', 'қалай', 'неге', 'не үшін'];
        if (questionWords.any((word) => lower.startsWith(word))) return false;
        return true;
      }).toList();

      if (validPhrases.isNotEmpty) {
        final random = Random();
        final randomPhrase = validPhrases[random.nextInt(validPhrases.length)];
        setState(() {
          _motivationalPhrase = randomPhrase;
          _isLoading = false;
        });
      } else {
        final random = Random();

        final defaultPhrasesRu = [
          'Поздравляем! Вы ответили правильно на все вопросы!',
          'Отлично! Вы настоящий эрудит!',
          'Превосходно! Все ответы верны!',
          'Браво! Вы справились на отлично!',
          'Великолепно! Вы покорили все вопросы!',
        ];

        final defaultPhrasesKz = [
          'Құттықтаймыз! Сіз барлық сұрақтарға дұрыс жауап бердіңіз!',
          'Керемет! Сіз нағыз эрудит екенсіз!',
          'Тамаша! Барлық жауаптар дұрыс!',
          'Жарайсың! Сіз өте жақсы жұмыс істедіңіз!',
          'Үздік нәтиже! Барлық сұрақтарды жеңдіңіз!',
        ];

        final phrases = normalizedLanguage == 'kz' ? defaultPhrasesKz : defaultPhrasesRu;
        final defaultMessage = phrases[random.nextInt(phrases.length)];
        setState(() {
          _motivationalPhrase = defaultMessage;
          _isLoading = false;
        });
      }
    } catch (e) {
      final random = Random();
      final isKazakh = currentLanguage.toUpperCase() == 'KZ';

      final defaultPhrasesRu = [
        'Поздравляем! Вы ответили правильно на все вопросы!',
        'Отлично! Вы настоящий эрудит!',
        'Превосходно! Все ответы верны!',
      ];

      final defaultPhrasesKz = [
        'Құттықтаймыз! Сіз барлық сұрақтарға дұрыс жауап бердіңіз!',
        'Керемет! Сіз нағыз эрудит екенсіз!',
        'Тамаша! Барлық жауаптар дұрыс!',
      ];

      final phrases = isKazakh ? defaultPhrasesKz : defaultPhrasesRu;

      setState(() {
        _motivationalPhrase = phrases[random.nextInt(phrases.length)];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentLanguage = languageProvider.currentLanguage;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
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
            ],
            stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenHeight = Responsive.screenHeight(context);
              final isSmallScreen = screenHeight < 700;

              return Padding(
                padding: Responsive.symmetricPadding(
                  context,
                  small: isSmallScreen ? 16 : 20,
                  medium: 22,
                  large: 24,
                ),
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        Consumer<GameProvider>(
                          builder: (context, gameProvider, child) {

                            if (gameProvider.isGameWon) {
                              return Column(
                                children: [
                                  Container(
                                    padding: Responsive.symmetricPadding(
                                      context,
                                      small: isSmallScreen ? 12 : 16,
                                      medium: 18,
                                      large: 20,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppColors.glowPurple,
                                          AppColors.darkPrimary,
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.timerWarning.withOpacity(0.6),
                                          blurRadius: Responsive.dp(context, 15),
                                          spreadRadius: Responsive.dp(context, 3),
                                        ),
                                        BoxShadow(
                                          color: AppColors.glowPurple.withOpacity(0.4),
                                          blurRadius: Responsive.dp(context, 20),
                                          spreadRadius: Responsive.dp(context, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.emoji_events,
                                      size: Responsive.dp(context, isSmallScreen ? 50 : 60),
                                      color: AppColors.timerWarning,
                                    ),
                                  ),
                                  SizedBox(height: Responsive.dp(context, isSmallScreen ? 12 : 16)),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),

                Consumer<GameProvider>(
                  builder: (context, gameProvider, child) {

                    if (gameProvider.isGameWon) {
                      return const SizedBox.shrink();
                    }

                    final correctCount = gameProvider.correctAnswersCount;
                    final totalQuestions = gameProvider.questions.length;

                    final screenHeight = Responsive.screenHeight(context);
                    final isSmallScreen = screenHeight < 700;

                    return Container(
                      padding: Responsive.symmetricPadding(
                        context,
                        small: isSmallScreen ? 12 : 16,
                        medium: 18,
                        large: 20,
                      ),
                      margin: EdgeInsets.only(bottom: Responsive.dp(context, isSmallScreen ? 8 : 12)),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.cardBackground,
                            AppColors.cardBackground.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(Responsive.dp(context, 12)),
                        border: Border.all(
                          color: AppColors.cardBorder,
                          width: Responsive.dp(context, 1.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.glowPurple.withOpacity(0.3),
                            blurRadius: Responsive.dp(context, 10),
                            spreadRadius: Responsive.dp(context, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        currentLanguage == 'KZ'
                            ? 'Дұрыс жауаптар: $correctCount / $totalQuestions'
                            : 'Правильных ответов: $correctCount / $totalQuestions',
                        style: GoogleFonts.nunito(
                          fontSize: Responsive.textSize(context, isSmallScreen ? 13 : 15),
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          height: 1.3,
                          letterSpacing: Responsive.dp(context, 0.2),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),

                if (_isLoading)
                  SizedBox(
                    height: Responsive.dp(context, 40),
                    child: const CircularProgressIndicator(
                      color: AppColors.textPrimary,
                    ),
                  )
                else
                  Container(
                    padding: Responsive.symmetricPadding(
                      context,
                      small: isSmallScreen ? 12 : 16,
                      medium: 18,
                      large: 20,
                    ),
                    margin: EdgeInsets.only(bottom: Responsive.dp(context, isSmallScreen ? 8 : 12)),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.cardBackground,
                          AppColors.cardBackground.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(Responsive.dp(context, 12)),
                      border: Border.all(
                        color: AppColors.cardBorder,
                        width: Responsive.dp(context, 1.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.glowPurple.withOpacity(0.3),
                          blurRadius: Responsive.dp(context, 10),
                          spreadRadius: Responsive.dp(context, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      _motivationalPhrase,
                      style: GoogleFonts.nunito(
                        fontSize: Responsive.textSize(context, isSmallScreen ? 13 : 15),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.3,
                        letterSpacing: Responsive.dp(context, 0.2),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                MenuButton(
                  text: AppStrings.getString(AppStrings.restart, currentLanguage),
                  color: AppColors.cardBackground,
                  onPressed: () {

                    final gameProvider = Provider.of<GameProvider>(context, listen: false);
                    gameProvider.reset();

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const GameScreen()),
                    );
                  },
                ),
                SizedBox(height: Responsive.dp(context, isSmallScreen ? 8 : 12)),

                MenuButton(
                  text: AppStrings.getString(AppStrings.mainMenu, currentLanguage),
                  color: AppColors.cardBackground,
                  onPressed: () {

                    final gameProvider = Provider.of<GameProvider>(context, listen: false);
                    gameProvider.reset();

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const MainMenuScreen()),
                    );
                  },
                ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
