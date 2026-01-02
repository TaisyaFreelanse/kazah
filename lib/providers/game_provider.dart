import 'package:flutter/foundation.dart';
import '../models/question.dart';

class GameProvider extends ChangeNotifier {
  List<Question> _questions = [];
  List<Question> _allAvailableQuestions = [];
  int _currentQuestionIndex = 0;
  bool _isGameActive = false;
  int _correctAnswersCount = 0;
  bool _isGameWon = false;

  List<Question> get questions => _questions;
  List<Question> get allAvailableQuestions => _allAvailableQuestions;
  Question? get currentQuestion => 
      _currentQuestionIndex < _questions.length 
          ? _questions[_currentQuestionIndex] 
          : null;
  int get currentQuestionIndex => _currentQuestionIndex;
  bool get isGameActive => _isGameActive;
  bool get isGameComplete => _currentQuestionIndex >= _questions.length;
  int get correctAnswersCount => _correctAnswersCount;
  bool get isGameWon => _isGameWon;

  void startGame(List<Question> questions, {List<Question>? allAvailableQuestions}) {
    _questions = List.from(questions);
    _allAvailableQuestions = allAvailableQuestions ?? List.from(questions);
    _currentQuestionIndex = 0;
    _isGameActive = true;
    _correctAnswersCount = 0;
    _isGameWon = false;
    notifyListeners();
  }

  bool checkAnswer(int answerIndex) {
    final currentQuestion = this.currentQuestion;
    if (currentQuestion == null) return false;

    final isCorrect = answerIndex == currentQuestion.correctAnswerIndex;
    if (isCorrect) {
      _correctAnswersCount++;
      if (_currentQuestionIndex == _questions.length - 1) {
        _isGameWon = true;
      }
    } else {
      _isGameWon = false;
    }
    notifyListeners();
    return isCorrect;
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
    _correctAnswersCount = 0;
    _isGameWon = false;
    notifyListeners();
  }
}

