import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/language_provider.dart';
import 'providers/game_provider.dart';
import 'services/cache_service.dart';
import 'services/package_service.dart';
import 'screens/main_menu_screen.dart';

class BlimBilemApp extends StatefulWidget {
  const BlimBilemApp({super.key});

  @override
  State<BlimBilemApp> createState() => _BlimBilemAppState();
}

class _BlimBilemAppState extends State<BlimBilemApp> {
  @override
  void initState() {
    super.initState();
    _preloadData();
  }

  void _preloadData() async {
    await CacheService.instance.initialize();
    PackageService.instance.getActivePackages();
  }

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

