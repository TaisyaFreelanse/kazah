import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../widgets/language_button.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../providers/language_provider.dart';
import 'packages_screen.dart';
import 'game_screen.dart';
import 'dart:io';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentLanguage = languageProvider.currentLanguage;

    return Scaffold(
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
        child: SafeArea(
          child: Stack(
            children: [
              // Декоративные элементы фона с градиентами
              Positioned(
                top: -80,
                right: -80,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.splashAccent.withOpacity(0.4),
                        AppColors.splashMiddle.withOpacity(0.2),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -120,
                left: -120,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.splashBottom.withOpacity(0.3),
                        AppColors.splashMiddle2.withOpacity(0.15),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).size.height * 0.3,
                left: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.cardBackground.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).size.height * 0.6,
                right: -30,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.splashAccent.withOpacity(0.25),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Основной контент
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),
                    // Персонаж (монстр) с анимацией - уменьшенный размер
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground, // Темно-фиолетовый цвет
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.cardBackground.withOpacity(0.6),
                                blurRadius: 25,
                                spreadRadius: 8,
                              ),
                              BoxShadow(
                                color: AppColors.glowPurple.withOpacity(0.3),
                                blurRadius: 40,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo_b.jpg',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback на иконку, если изображение не найдено
                                return const Center(
                                  child: Icon(
                                    Icons.psychology,
                                    size: 50,
                                    color: AppColors.textPrimary,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Текст "Bilim Bilem" - жирный блочный шрифт с белой обводкой
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Белая обводка
                          Text(
                            'BILIM BILEM',
                            style: GoogleFonts.inter(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 3
                                ..color = Colors.white,
                              letterSpacing: 3.0,
                              height: 1.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          // Основной текст
                          Text(
                            'BILIM BILEM',
                            style: GoogleFonts.inter(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              color: AppColors.cardBackground,
                              letterSpacing: 3.0,
                              height: 1.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 1),
                    // Кнопки выбора языка KZ/RU - над кнопкой "Начать игру"
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LanguageButton(
                            language: 'KZ',
                            isSelected: currentLanguage == 'KZ',
                            onPressed: () {
                              languageProvider.setLanguage('KZ');
                            },
                          ),
                          const SizedBox(width: 16),
                          LanguageButton(
                            language: 'RU',
                            isSelected: currentLanguage == 'RU',
                            onPressed: () {
                              languageProvider.setLanguage('RU');
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Кнопка "Let's start game" с эффектом свечения - уменьшенный размер
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.startButton.withOpacity(0.5),
                              blurRadius: 15,
                              spreadRadius: 4,
                            ),
                            BoxShadow(
                              color: AppColors.glowPink.withOpacity(0.3),
                              blurRadius: 25,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const GameScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.startButton,
                              foregroundColor: AppColors.textPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50), // Круглая форма (pill)
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              currentLanguage == 'KZ' 
                                  ? 'Ойынды бастау'
                                  : currentLanguage == 'RU'
                                      ? 'Начать игру'
                                      : 'Let\'s start game',
                              style: GoogleFonts.nunito(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Кнопка "Дополнительные вопросы" - уменьшенный размер
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PackagesScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: BorderSide(
                              color: AppColors.cardBorder,
                              width: 2,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            AppStrings.getString(
                              AppStrings.additionalQuestions,
                              currentLanguage,
                            ),
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Кнопка "Выход" - более заметная
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            _showExitDialog(context, currentLanguage);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.cardBackground,
                            side: BorderSide(
                              color: AppColors.cardBackground,
                              width: 2,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            AppStrings.getString(AppStrings.exitGame, currentLanguage),
                            style: GoogleFonts.nunito(
                              color: AppColors.cardBackground,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(flex: 1),
                  ],
                ),
              ),
            ],
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
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(
              color: AppColors.cardBackground,
              width: 2,
            ),
          ),
          title: Text(
            language == 'KZ' ? 'Шығу' : 'Выход',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.bold,
              color: AppColors.cardBackground,
            ),
          ),
          content: Text(
            language == 'KZ'
                ? 'Сіз шынымен ойыннан шығуды қалайсыз ба?'
                : 'Вы действительно хотите выйти из игры?',
            style: GoogleFonts.nunito(color: AppColors.cardBackground),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                language == 'KZ' ? 'Жоқ' : 'Нет',
                style: GoogleFonts.nunito(color: AppColors.cardBackground),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                exit(0);
              },
              child: Text(
                'Да',
                style: GoogleFonts.nunito(
                  color: AppColors.cardBackground,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
