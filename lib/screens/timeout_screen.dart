import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/game_provider.dart';
import '../constants/strings.dart';
import '../constants/colors.dart';
import '../widgets/menu_button.dart';
import 'game_screen.dart';
import 'main_menu_screen.dart';

class TimeoutScreen extends StatelessWidget {
  const TimeoutScreen({super.key});

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
                // Иконка времени
                const Icon(
                  Icons.timer_off,
                  size: 80,
                  color: Colors.red,
                ),
                const SizedBox(height: 32),
                
                // Сообщение
                Text(
                  AppStrings.getString(AppStrings.timeoutMessage, currentLanguage),
                  style: const TextStyle(
                    fontSize: 28,
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
                
                // Кнопка "Начать заново"
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

