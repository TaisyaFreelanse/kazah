enum Difficulty {
  easy,
  medium,
  hard,
}

class Question {
  final String text;
  final List<String> answers;
  final int correctAnswerIndex;
  final Difficulty difficulty;
  final String? packageId;

  Question({
    required this.text,
    required this.answers,
    required this.correctAnswerIndex,
    required this.difficulty,
    this.packageId,
  });

  static Question withRandomizedAnswers({
    required String text,
    required List<String> answers,
    required Difficulty difficulty,
    String? packageId,
  }) {

    final correctAnswer = answers[0];

    final shuffledAnswers = List<String>.from(answers)..shuffle();

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

