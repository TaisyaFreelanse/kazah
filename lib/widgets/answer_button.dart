import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../utils/responsive.dart';

enum AnswerButtonState {
  normal,
  hidden,
  correct,
  incorrect,
}

class AnswerButton extends StatefulWidget {
  final String text;
  final String label;
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

  String _formatNumericAnswer(String text) {

    try {
      final number = double.tryParse(text.trim());
      if (number != null) {

        if (number == number.toInt()) {
          return number.toInt().toString();
        }

        return number.toString().replaceAll(RegExp(r'\.?0+$'), '');
      }
    } catch (e) {

    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state == AnswerButtonState.hidden) {
      return const SizedBox.shrink();
    }

    Color backgroundColor = AppColors.questionCardBackground;
    Color foregroundColor = AppColors.textPrimary;
    Color borderColor = AppColors.cardBorder;
    String displayText = _formatNumericAnswer(widget.text);
    List<BoxShadow>? shadows;

    if (widget.isSelected && widget.state == AnswerButtonState.normal) {

      backgroundColor = AppColors.selectedAnswer;
      foregroundColor = Colors.black;
      borderColor = AppColors.selectedAnswer;
      shadows = [

        BoxShadow(
          color: AppColors.timerWarning.withOpacity(0.8),
          blurRadius: Responsive.dp(context, 25),
          spreadRadius: Responsive.dp(context, 4),
        ),

        BoxShadow(
          color: AppColors.timerWarning.withOpacity(0.6),
          blurRadius: Responsive.dp(context, 15),
          spreadRadius: Responsive.dp(context, 2),
        ),

        BoxShadow(
          color: AppColors.timerWarning.withOpacity(0.4),
          blurRadius: Responsive.dp(context, 35),
          spreadRadius: Responsive.dp(context, 1),
        ),
      ];
    } else if (widget.state == AnswerButtonState.correct) {

      backgroundColor = AppColors.correctAnswer;
      foregroundColor = AppColors.textPrimary;
      borderColor = AppColors.correctAnswer;
      shadows = [
        BoxShadow(
          color: AppColors.glowCyan.withOpacity(0.5),
          blurRadius: Responsive.dp(context, 15),
          spreadRadius: Responsive.dp(context, 2),
        ),
      ];
    } else if (widget.state == AnswerButtonState.incorrect) {

      backgroundColor = AppColors.wrongAnswer;
      foregroundColor = AppColors.textPrimary;
      borderColor = AppColors.wrongAnswer;
      shadows = [
        BoxShadow(
          color: AppColors.glowPink.withOpacity(0.5),
          blurRadius: Responsive.dp(context, 15),
          spreadRadius: Responsive.dp(context, 2),
        ),
      ];
    } else {

      backgroundColor = const Color(0xFF2F3B39);
      foregroundColor = AppColors.textPrimary;
      borderColor = const Color(0xFF2F3B39);
      shadows = [
        BoxShadow(
          color: const Color(0xFF2F3B39).withOpacity(0.3),
          blurRadius: Responsive.dp(context, 8),
          spreadRadius: Responsive.dp(context, 1),
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
          margin: EdgeInsets.only(bottom: Responsive.dp(context, 6)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Responsive.dp(context, 12)),
            boxShadow: shadows,
          ),
          child: ElevatedButton(
            onPressed: widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.dp(context, 12),
                vertical: Responsive.dp(context, 10),
              ),
              minimumSize: Size(
                0,
                Responsive.dp(context, 40),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Responsive.dp(context, 12)),
                side: BorderSide(
                  color: borderColor,
                  width: Responsive.dp(context, 1.5),
                ),
              ),
              elevation: 0,
            ),
            child: Row(
              children: [

                if (widget.label.isNotEmpty) ...[
                  Container(
                    width: Responsive.dp(context, 28),
                    height: Responsive.dp(context, 28),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: widget.isSelected
                            ? [
                                Colors.black.withOpacity(0.3),
                                Colors.black.withOpacity(0.1),
                              ]
                            : [
                                foregroundColor.withOpacity(0.3),
                                foregroundColor.withOpacity(0.1),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(Responsive.dp(context, 12)),
                      border: Border.all(
                        color: borderColor.withOpacity(0.5),
                        width: Responsive.dp(context, 1.5),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        widget.label,
                        style: GoogleFonts.nunito(
                          fontSize: Responsive.textSize(context, 14),
                          fontWeight: FontWeight.bold,
                          color: foregroundColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: Responsive.dp(context, 8)),
                ],

                Expanded(
                  child: Text(
                    displayText,
                    textAlign: TextAlign.left,
                    style: GoogleFonts.nunito(
                      fontSize: Responsive.textSize(context, 13),
                      fontWeight: widget.isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: foregroundColor,
                      letterSpacing: Responsive.dp(context, 0.2),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
