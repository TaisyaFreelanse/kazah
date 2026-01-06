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

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'answers': answers,
      'correctAnswerIndex': correctAnswerIndex,
      'difficulty': difficulty.toString().split('.').last,
      'packageId': packageId,
    };
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      text: json['text'] as String,
      answers: List<String>.from(json['answers'] as List),
      correctAnswerIndex: json['correctAnswerIndex'] as int,
      difficulty: Difficulty.values.firstWhere(
        (d) => d.toString().split('.').last == json['difficulty'],
        orElse: () => Difficulty.medium,
      ),
      packageId: json['packageId'] as String?,
    );
  }
}

