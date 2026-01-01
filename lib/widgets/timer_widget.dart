import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';

class TimerWidget extends StatelessWidget {
  final int secondsRemaining;

  const TimerWidget({
    super.key,
    required this.secondsRemaining,
  });

  @override
  Widget build(BuildContext context) {
    Color timerColor;
    if (secondsRemaining <= 5) {
      timerColor = AppColors.timerDanger;
    } else if (secondsRemaining <= 8) {
      timerColor = AppColors.timerWarning;
    } else {
      timerColor = AppColors.timerNormal;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: timerColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: timerColor.withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        '00:${secondsRemaining.toString().padLeft(2, '0')}',
        style: GoogleFonts.nunito(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
