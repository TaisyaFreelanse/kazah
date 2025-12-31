import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/menu_button.dart';
import '../widgets/language_button.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../providers/language_provider.dart';
import 'packages_screen.dart';
import 'game_screen.dart';
import 'dart:io';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

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
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Заголовок с трофеем и лампочкой
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: 48,
                      color: Colors.amber,
                    ),
                    SizedBox(width: 16),
                    Text(
                      'BLIM BILEM',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(2, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Icon(
                      Icons.lightbulb,
                      size: 48,
                      color: Colors.amber,
                    ),
                  ],
                ),
                const SizedBox(height: 60),
                
                // Кнопка СТАРТ
                MenuButton(
                  text: AppStrings.getString(AppStrings.start, currentLanguage),
                  color: AppColors.startButton,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const GameScreen()),
                    );
                  },
                ),
                const SizedBox(height: 24),
                
                // Кнопки выбора языка KZ/RU
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LanguageButton(
                      language: 'KZ',
                      isSelected: currentLanguage == 'KZ',
                      onPressed: () {
                        languageProvider.setLanguage('KZ');
                      },
                    ),
                    const SizedBox(width: 20),
                    LanguageButton(
                      language: 'RU',
                      isSelected: currentLanguage == 'RU',
                      onPressed: () {
                        languageProvider.setLanguage('RU');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Кнопка "Дополнительные вопросы"
                MenuButton(
                  text: AppStrings.getString(
                    AppStrings.additionalQuestions,
                    currentLanguage,
                  ),
                  color: AppColors.additionalQuestionsButton,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PackagesScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                
                // Кнопка "Выход"
                MenuButton(
                  text: AppStrings.getString(AppStrings.exitGame, currentLanguage),
                  color: AppColors.exitButton,
                  onPressed: () {
                    _showExitDialog(context, currentLanguage);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context, String language) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            language == 'KZ' ? 'Шығу' : 'Выход',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            language == 'KZ'
                ? 'Сіз шынымен ойыннан шығуды қалайсыз ба?'
                : 'Вы действительно хотите выйти из игры?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(language == 'KZ' ? 'Жоқ' : 'Нет'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                exit(0);
              },
              child: Text(
                language == 'KZ' ? 'Иә' : 'Да',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}

