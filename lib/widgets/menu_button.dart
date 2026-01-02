import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/responsive.dart';

class MenuButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onPressed;

  const MenuButton({
    super.key,
    required this.text,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Responsive.dp(context, 16)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: Responsive.dp(context, 8),
            offset: Offset(0, Responsive.dp(context, 4)),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.dp(context, 24),
            vertical: Responsive.dp(context, 14),
          ),
          minimumSize: Size(
            double.infinity,
            Responsive.dp(context, 48),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Responsive.dp(context, 16)),
          ),
          elevation: Responsive.dp(context, 8),
          shadowColor: color.withOpacity(0.5),
        ),
          child: Text(
            text,
            style: GoogleFonts.nunito(
              fontSize: Responsive.textSize(context, 16),
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, Responsive.dp(context, 1)),
                  blurRadius: Responsive.dp(context, 1),
                ),
              ],
            ),
          ),
      ),
    );
  }
}

