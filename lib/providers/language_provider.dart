import 'package:flutter/foundation.dart';
import '../services/language_service.dart';

class LanguageProvider extends ChangeNotifier {
  final LanguageService _languageService = LanguageService();
  String _currentLanguage = LanguageService.defaultLanguage;

  String get currentLanguage => _currentLanguage;

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    _currentLanguage = await _languageService.getCurrentLanguage();
    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    _currentLanguage = language;
    await _languageService.setLanguage(language);
    notifyListeners();
  }
}

