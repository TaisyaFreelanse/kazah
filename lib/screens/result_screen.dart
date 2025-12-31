import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Золотой кубок/медаль
                const Icon(
                  Icons.emoji_events,
                  size: 120,
                  color: Colors.amber,
                ),
                const SizedBox(height: 32),
                
                // Мотивирующая фраза
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  Text(
                    _motivationalPhrase,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
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
                  color: AppColors.exitButton,
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

