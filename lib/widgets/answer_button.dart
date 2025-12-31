import 'package:flutter/material.dart';

enum AnswerButtonState {
  normal,
  hidden, // Скрыт подсказкой 50/50
  correct, // Правильный ответ (подсказка 1)
  incorrect, // Неправильный ответ (подсказка 1)
}

class AnswerButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isSelected;
  final AnswerButtonState state;

  const AnswerButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isSelected = false,
    this.state = AnswerButtonState.normal,
  });

  @override
  Widget build(BuildContext context) {
    if (state == AnswerButtonState.hidden) {
      return const SizedBox.shrink();
    }

    Color backgroundColor = Colors.white;
    Color foregroundColor = Colors.black87;
    String displayText = text;

    if (state == AnswerButtonState.correct) {
      backgroundColor = Colors.green;
      foregroundColor = Colors.white;
      displayText = 'Верно';
    } else if (state == AnswerButtonState.incorrect) {
      backgroundColor = Colors.red;
      foregroundColor = Colors.white;
      displayText = 'Неверно';
    } else if (isSelected) {
      backgroundColor = Colors.blue;
      foregroundColor = Colors.white;
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        displayText,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}

