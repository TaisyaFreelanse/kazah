import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/language_provider.dart';
import 'providers/game_provider.dart';
import 'screens/main_menu_screen.dart';

class BlimBilemApp extends StatelessWidget {
  const BlimBilemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => GameProvider()),
      ],
      child: MaterialApp(
        title: 'Bilim Bilem',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFF533483),
            secondary: const Color(0xFFE94560),
            surface: const Color(0xFF16213E),
            background: const Color(0xFF1A1A2E),
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.nunitoTextTheme(),
          scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        ),
        home: const MainMenuScreen(),
      ),
    );
  }
}

