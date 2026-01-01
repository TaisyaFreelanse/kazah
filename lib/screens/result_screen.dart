import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/language_provider.dart';
import '../providers/game_provider.dart';
import '../services/excel_parser.dart';
import '../constants/colors.dart';
import '../widgets/menu_button.dart';
import '../constants/strings.dart';
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
    final currentLanguage = languageProvider.currentLanguage;

    try {
      // Определяем путь к файлу фраз
      final phrasesPath = currentLanguage == 'KZ'
          ? 'assets/data/phrases_kz.xlsx'
          : 'assets/data/phrases_ru.xlsx';

      final excelParser = ExcelParser();
      final phrases = await excelParser.parsePhrases(assetPath: phrasesPath);

      if (phrases.isNotEmpty) {
        // Выбираем случайную фразу
        final random = Random();
        final randomPhrase = phrases[random.nextInt(phrases.length)];

        setState(() {
          _motivationalPhrase = randomPhrase;
          _isLoading = false;
        });
      } else {
        // Если фраз нет, используем дефолтное сообщение
        setState(() {
          _motivationalPhrase = currentLanguage == 'KZ'
              ? 'Құттықтаймыз! Сіз барлық сұрақтарға дұрыс жауап бердіңіз!'
              : 'Поздравляем! Вы ответили правильно на все вопросы!';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Ошибка загрузки мотивирующих фраз: $e');
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      setState(() {
        _motivationalPhrase = languageProvider.currentLanguage == 'KZ'
            ? 'Құттықтаймыз! Сіз барлық сұрақтарға дұрыс жауап бердіңіз!'
            : 'Поздравляем! Вы ответили правильно на все вопросы!';
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Золотой кубок/медаль с анимацией и свечением
                Container(
                  padding: const EdgeInsets.all(24),
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
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                      BoxShadow(
                        color: AppColors.glowPurple.withOpacity(0.4),
                        blurRadius: 50,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    size: 90,
                    color: AppColors.timerWarning,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Мотивирующая фраза
                if (_isLoading)
                  const CircularProgressIndicator(
                    color: AppColors.textPrimary,
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.cardBackground,
                          AppColors.cardBackground.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.cardBorder,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.glowPurple.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      _motivationalPhrase,
                      style: GoogleFonts.nunito(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.5,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 60),
                
                // Кнопка "Играть снова"
                MenuButton(
                  text: AppStrings.getString(AppStrings.restart, currentLanguage),
                  color: AppColors.startButton,
                  onPressed: () {
                    // Сбрасываем состояние игры
                    final gameProvider = Provider.of<GameProvider>(context, listen: false);
                    gameProvider.reset();
                    
                    // Переходим на экран игры
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const GameScreen()),
                    );
                  },
                ),
                const SizedBox(height: 24),
                
                // Кнопка "В главное меню"
                MenuButton(
                  text: AppStrings.getString(AppStrings.mainMenu, currentLanguage),
                  color: AppColors.additionalQuestionsButton,
                  onPressed: () {
                    // Сбрасываем состояние игры
                    final gameProvider = Provider.of<GameProvider>(context, listen: false);
                    gameProvider.reset();
                    
                    // Переходим в главное меню
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
      ),
    );
  }
}
