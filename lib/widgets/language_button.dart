import 'package:flutter/material.dart';
import '../constants/colors.dart';

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
    final color = language == 'KZ' ? AppColors.kzButton : AppColors.ruButton;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: isSelected ? 12 : 8,
          shadowColor: color.withOpacity(0.5),
        ),
        child: Text(
          language,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            shadows: [
              const Shadow(
                color: Colors.black26,
                offset: Offset(0, 2),
                blurRadius: 2,
              ),
            ],
            decoration: isSelected ? TextDecoration.underline : null,
            decorationThickness: 2,
          ),
        ),
      ),
    );
  }
}

