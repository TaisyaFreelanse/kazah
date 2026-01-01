import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';

enum AnswerButtonState {
  normal,
  hidden, // Скрыт подсказкой 50/50
  correct, // Правильный ответ (подсказка 1)
  incorrect, // Неправильный ответ (подсказка 1)
}

class AnswerButton extends StatefulWidget {
  final String text;
  final String label; // A, B, C, D
  final VoidCallback? onPressed;
  final bool isSelected;
  final AnswerButtonState state;

  const AnswerButton({
    super.key,
    required this.text,
    this.label = '',
    this.onPressed,
    this.isSelected = false,
    this.state = AnswerButtonState.normal,
  });

  @override
  State<AnswerButton> createState() => _AnswerButtonState();
}

class _AnswerButtonState extends State<AnswerButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _handleTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state == AnswerButtonState.hidden) {
      return const SizedBox.shrink();
    }

    Color backgroundColor = AppColors.questionCardBackground; // #2F3B39
    Color foregroundColor = AppColors.textPrimary;
    Color borderColor = AppColors.cardBorder;
    String displayText = widget.text;
    List<BoxShadow>? shadows;

    if (widget.state == AnswerButtonState.correct) {
      backgroundColor = AppColors.correctAnswer;
      foregroundColor = AppColors.textPrimary;
      borderColor = AppColors.correctAnswer;
      shadows = [
        BoxShadow(
          color: AppColors.glowCyan.withOpacity(0.5),
          blurRadius: 15,
          spreadRadius: 2,
        ),
      ];
    } else if (widget.state == AnswerButtonState.incorrect) {
      backgroundColor = AppColors.wrongAnswer;
      foregroundColor = AppColors.textPrimary;
      borderColor = AppColors.wrongAnswer;
      shadows = [
        BoxShadow(
          color: AppColors.glowPink.withOpacity(0.5),
          blurRadius: 15,
          spreadRadius: 2,
        ),
      ];
    } else if (widget.isSelected) {
      backgroundColor = AppColors.selectedAnswer;
      foregroundColor = AppColors.textDark;
      borderColor = AppColors.selectedAnswer;
      shadows = [
        BoxShadow(
          color: AppColors.timerWarning.withOpacity(0.5),
          blurRadius: 20,
          spreadRadius: 3,
        ),
      ];
    } else {
      shadows = [
        BoxShadow(
          color: AppColors.cardBorder.withOpacity(0.2),
          blurRadius: 8,
          spreadRadius: 1,
        ),
      ];
    }

    return GestureDetector(
      onTapDown: widget.onPressed != null ? _handleTapDown : null,
      onTapUp: widget.onPressed != null ? _handleTapUp : null,
      onTapCancel: widget.onPressed != null ? _handleTapCancel : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: shadows,
          ),
          child: ElevatedButton(
            onPressed: widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: borderColor,
                  width: 2,
                ),
              ),
              elevation: 0,
            ),
            child: Row(
              children: [
                // Метка (A, B, C, D) с градиентом
                if (widget.label.isNotEmpty) ...[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: widget.isSelected
                            ? [
                                AppColors.textDark.withOpacity(0.3),
                                AppColors.textDark.withOpacity(0.1),
                              ]
                            : [
                                foregroundColor.withOpacity(0.3),
                                foregroundColor.withOpacity(0.1),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: borderColor.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        widget.label,
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: foregroundColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                // Текст ответа
                Expanded(
                  child: Text(
                    displayText,
                    textAlign: TextAlign.left,
                    style: GoogleFonts.nunito(
                      fontSize: 17,
                      fontWeight: widget.isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
