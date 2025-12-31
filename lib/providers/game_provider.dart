import 'package:flutter/foundation.dart';
import '../models/question.dart';

class GameProvider extends ChangeNotifier {
  List<Question> _questions = [];
  List<Question> _allAvailableQuestions = []; // Все доступные вопросы для подсказки 3
  int _currentQuestionIndex = 0;
  bool _isGameActive = false;

  List<Question> get questions => _questions;
  List<Question> get allAvailableQuestions => _allAvailableQuestions;
  Question? get currentQuestion => 
      _currentQuestionIndex < _questions.length 
          ? _questions[_currentQuestionIndex] 
          : null;
  int get currentQuestionIndex => _currentQuestionIndex;
  bool get isGameActive => _isGameActive;
  bool get isGameComplete => _currentQuestionIndex >= _questions.length;

  void startGame(List<Question> questions, {List<Question>? allAvailableQuestions}) {
    _questions = questions;
    _allAvailableQuestions = allAvailableQuestions ?? questions;
    _currentQuestionIndex = 0;
    _isGameActive = true;
    notifyListeners();
  }

  void nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      _currentQuestionIndex++;
      notifyListeners();
    } else {
      _isGameActive = false;
      notifyListeners();
    }
  }

  /// Заменяет текущий вопрос на другой того же уровня сложности
  void replaceCurrentQuestion(Question newQuestion) {
    if (_currentQuestionIndex < _questions.length) {
      _questions[_currentQuestionIndex] = newQuestion;
      notifyListeners();
    }
  }

  void reset() {
    _questions = [];
    _allAvailableQuestions = [];
    _currentQuestionIndex = 0;
    _isGameActive = false;
    notifyListeners();
  }
}

