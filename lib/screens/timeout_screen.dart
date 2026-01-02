import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/language_provider.dart';
import '../providers/game_provider.dart';
import '../constants/strings.dart';
import '../constants/colors.dart';
import '../widgets/menu_button.dart';
import '../utils/responsive.dart';
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
                  child: Padding(
                    padding: Responsive.symmetricPadding(
                      context,
                      small: isSmallScreen ? 16 : 20,
                      medium: 22,
                      large: 24,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        Icon(
                          Icons.timer_off,
                          size: Responsive.dp(context, isSmallScreen ? 60 : 80),
                          color: const Color(0xFF4B0000),
                        ),
                        SizedBox(height: Responsive.dp(context, isSmallScreen ? 20 : 24)),

                        Text(
                          AppStrings.getString(AppStrings.timeoutMessage, currentLanguage),
                          style: GoogleFonts.nunito(
                            fontSize: Responsive.textSize(context, isSmallScreen ? 20 : 24),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(0, Responsive.dp(context, 1)),
                                blurRadius: Responsive.dp(context, 3),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: Responsive.dp(context, isSmallScreen ? 32 : 40)),

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
                        SizedBox(height: Responsive.dp(context, isSmallScreen ? 12 : 16)),

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

