import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../widgets/language_button.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../providers/language_provider.dart';
import '../utils/responsive.dart';
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
  bool _isLoadingGame = false;

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

              Positioned(
                top: -Responsive.heightPercent(context, 10),
                right: -Responsive.widthPercent(context, 20),
                child: Container(
                  width: Responsive.widthPercent(context, 75),
                  height: Responsive.widthPercent(context, 75),
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
                bottom: -Responsive.heightPercent(context, 15),
                left: -Responsive.widthPercent(context, 30),
                child: Container(
                  width: Responsive.widthPercent(context, 100),
                  height: Responsive.widthPercent(context, 100),
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
                top: Responsive.heightPercent(context, 30),
                left: -Responsive.widthPercent(context, 12),
                child: Container(
                  width: Responsive.widthPercent(context, 50),
                  height: Responsive.widthPercent(context, 50),
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
                top: Responsive.heightPercent(context, 60),
                right: -Responsive.widthPercent(context, 7),
                child: Container(
                  width: Responsive.widthPercent(context, 37),
                  height: Responsive.widthPercent(context, 37),
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

              Padding(
                padding: Responsive.horizontalPadding(context, small: 24, medium: 32, large: 40).copyWith(
                  top: Responsive.heightPercent(context, 2),
                  bottom: Responsive.heightPercent(context, 2),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final screenHeight = Responsive.screenHeight(context);
                    final isSmallScreen = screenHeight < 700;

                    return SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: Responsive.dp(context, isSmallScreen ? 20 : 30)),

                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          width: Responsive.dp(context, isSmallScreen ? 80 : 100),
                          height: Responsive.dp(context, isSmallScreen ? 80 : 100),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4B0000),
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo_b.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.psychology,
                                    size: Responsive.adaptiveSize(context, small: 50, medium: 60, large: 70),
                                    color: AppColors.textPrimary,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: Responsive.dp(context, isSmallScreen ? 12 : 16)),

                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final fontSize = Responsive.textSize(
                            context,
                            isSmallScreen ? 24 : 28,
                          );
                          final strokeWidth = Responsive.dp(context, 2);
                          return Stack(
                            alignment: Alignment.center,
                            children: [

                              Text(
                                'BILIM BILEM',
                                style: GoogleFonts.inter(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w900,
                                  foreground: Paint()
                                    ..style = PaintingStyle.stroke
                                    ..strokeWidth = strokeWidth
                                    ..color = Colors.white,
                                  letterSpacing: Responsive.dp(context, 3),
                                  height: 1.0,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              Text(
                                'BILIM BILEM',
                                style: GoogleFonts.inter(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.cardBackground,
                                  letterSpacing: Responsive.dp(context, 3),
                                  height: 1.0,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                            SizedBox(height: Responsive.dp(context, isSmallScreen ? 12 : 16)),

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
                          SizedBox(width: Responsive.widthPercent(context, 4)),
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
                    SizedBox(height: Responsive.dp(context, isSmallScreen ? 12 : 16)),

                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Responsive.dp(context, 16)),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.startButton.withOpacity(0.5),
                              blurRadius: Responsive.dp(context, 15),
                              spreadRadius: Responsive.dp(context, 4),
                            ),
                            BoxShadow(
                              color: AppColors.glowPink.withOpacity(0.3),
                              blurRadius: Responsive.dp(context, 25),
                              spreadRadius: Responsive.dp(context, 2),
                            ),
                          ],
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoadingGame ? null : () async {

                              if (_isLoadingGame) return;

                              setState(() {
                                _isLoadingGame = true;
                              });

                              try {

                                await Future.delayed(const Duration(milliseconds: 100));

                                if (mounted) {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const GameScreen()),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isLoadingGame = false;
                                  });
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isLoadingGame 
                                  ? AppColors.cardBackground.withOpacity(0.6)
                                  : AppColors.cardBackground,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: Responsive.buttonHeight(context, small: 16, medium: 18, large: 20),
                              ),
                              minimumSize: Size(
                                double.infinity,
                                Responsive.buttonHeight(context, small: 48, medium: 52, large: 56),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(Responsive.dp(context, 50)),
                              ),
                              elevation: 0,
                              disabledBackgroundColor: AppColors.cardBackground.withOpacity(0.6),
                            ),
                            child: _isLoadingGame
                                ? SizedBox(
                                    width: Responsive.dp(context, 20),
                                    height: Responsive.dp(context, 20),
                                    child: CircularProgressIndicator(
                                      strokeWidth: Responsive.dp(context, 2),
                                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    currentLanguage == 'KZ' 
                                        ? 'Ойынды бастау'
                                        : currentLanguage == 'RU'
                                            ? 'Начать игру'
                                            : 'Let\'s start game',
                                    style: GoogleFonts.nunito(
                                      fontSize: Responsive.textSize(context, isSmallScreen ? 16 : 18),
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: Responsive.dp(context, 0.5),
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: Responsive.dp(context, isSmallScreen ? 12 : 16)),

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
                            backgroundColor: AppColors.cardBackground,
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: AppColors.cardBackground,
                              width: Responsive.dp(context, 2),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: Responsive.dp(context, isSmallScreen ? 12 : 14),
                            ),
                            minimumSize: Size(
                              double.infinity,
                              Responsive.dp(context, isSmallScreen ? 44 : 48),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Responsive.dp(context, 16)),
                            ),
                          ),
                          child: Text(
                            AppStrings.getString(
                              AppStrings.additionalQuestions,
                              currentLanguage,
                            ),
                            style: GoogleFonts.nunito(
                              fontSize: Responsive.textSize(context, isSmallScreen ? 13 : 14),
                              fontWeight: FontWeight.w900,
                              letterSpacing: Responsive.dp(context, 0.4),
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: Responsive.dp(context, isSmallScreen ? 12 : 16)),

                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            _showExitDialog(context, currentLanguage);
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.cardBackground,
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: AppColors.cardBackground,
                              width: Responsive.dp(context, 2),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: Responsive.dp(context, isSmallScreen ? 10 : 12),
                            ),
                            minimumSize: Size(
                              double.infinity,
                              Responsive.dp(context, isSmallScreen ? 40 : 44),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Responsive.dp(context, 16)),
                            ),
                          ),
                          child: Text(
                            AppStrings.getString(AppStrings.exitGame, currentLanguage),
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: Responsive.textSize(context, isSmallScreen ? 13 : 14),
                              fontWeight: FontWeight.w900,
                              letterSpacing: Responsive.dp(context, 0.3),
                            ),
                          ),
                        ),
                      ),
                    ),
                            SizedBox(height: Responsive.dp(context, isSmallScreen ? 12 : 16)),
                          ],
                        ),
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
