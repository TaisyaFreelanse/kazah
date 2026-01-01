import 'package:flutter/material.dart';
import '../constants/colors.dart';

class GameBackground extends StatelessWidget {
  final Widget child;

  const GameBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.gameBackgroundTop,
            AppColors.gameBackgroundBottom,
          ],
        ),
      ),
      child: child,
    );
  }
}

