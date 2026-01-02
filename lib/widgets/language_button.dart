import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../utils/responsive.dart';

class LanguageButton extends StatelessWidget {
  final String language;
  final bool isSelected;
  final VoidCallback onPressed;

  const LanguageButton({
    super.key,
    required this.language,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Responsive.dp(context, 12)),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: Responsive.dp(context, 6),
                  spreadRadius: Responsive.dp(context, 1),
                  offset: Offset(0, Responsive.dp(context, 2)),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cardBackground,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.dp(context, 20),
            vertical: Responsive.dp(context, 10),
          ),
          minimumSize: Size(
            Responsive.dp(context, 80),
            Responsive.dp(context, 36),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Responsive.dp(context, 12)),
          ),
          elevation: 0,
        ),
          child: Text(
            language,
            style: GoogleFonts.nunito(
              fontSize: Responsive.textSize(context, 14),
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
      ),
    );
  }
}
