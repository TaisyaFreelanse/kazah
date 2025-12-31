enum Difficulty {
  easy,
  medium,
  hard,
}

class Question {
  final String text;
  final List<String> answers; // 6 вариантов
  final int correctAnswerIndex; // индекс правильного ответа после рандомизации
  final Difficulty difficulty;
  final String? packageId; // null для базовых вопросов

  Question({
    required this.text,
    required this.answers,
    required this.correctAnswerIndex,
    required this.difficulty,
    this.packageId,
  });

  // Метод для создания вопроса с рандомизированными ответами
  static Question withRandomizedAnswers({
    required String text,
    required List<String> answers,
    required Difficulty difficulty,
    String? packageId,
  }) {
    // Правильный ответ всегда первый в исходных данных (индекс 0)
    final correctAnswer = answers[0];
    
    // Создаем копию списка и перемешиваем
    final shuffledAnswers = List<String>.from(answers)..shuffle();
    
    // Находим новый индекс правильного ответа
    final newCorrectIndex = shuffledAnswers.indexOf(correctAnswer);
    
    return Question(
      text: text,
      answers: shuffledAnswers,
      correctAnswerIndex: newCorrectIndex,
      difficulty: difficulty,
      packageId: packageId,
    );
  }
}

