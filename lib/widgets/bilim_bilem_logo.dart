import 'package:flutter/material.dart';
import '../constants/colors.dart';

class BilimBilemLogo extends StatelessWidget {
  final double size;
  final Color backgroundColor;
  final Color letterColor;

  const BilimBilemLogo({
    super.key,
    this.size = 50,
    this.backgroundColor = AppColors.startButton, // Оранжево-розовый цвет
    this.letterColor = AppColors.textPrimary, // Белый
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: BLogoPainter(
        backgroundColor: backgroundColor,
        letterColor: letterColor,
      ),
    );
  }
}

class BLogoPainter extends CustomPainter {
  final Color backgroundColor;
  final Color letterColor;

  BLogoPainter({
    required this.backgroundColor,
    required this.letterColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = letterColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double width = size.width;
    final double height = size.height;
    final double strokeWidth = size.width * 0.12;
    final double gap = strokeWidth * 0.8; // Расстояние между двойными линиями

    // Вертикальная линия (левая часть буквы B)
    final double x = width * 0.25;
    final double topY = height * 0.15;
    final double bottomY = height * 0.85;

    // Рисуем двойную вертикальную линию
    canvas.drawLine(
      Offset(x, topY),
      Offset(x, bottomY),
      paint,
    );
    canvas.drawLine(
      Offset(x + gap, topY),
      Offset(x + gap, bottomY),
      paint,
    );

    // Верхняя петля буквы B
    final double topLoopRadius = width * 0.2;
    final double topLoopCenterX = x + topLoopRadius;
    final double topLoopCenterY = height * 0.35;

    // Верхняя дуга (внешняя)
    final topArc1 = Path()
      ..moveTo(x, topY)
      ..arcTo(
        Rect.fromCircle(
          center: Offset(topLoopCenterX, topLoopCenterY),
          radius: topLoopRadius,
        ),
        -1.57, // -90 градусов
        3.14, // 180 градусов
        false,
      );
    canvas.drawPath(topArc1, paint);

    // Верхняя дуга (внутренняя)
    final topArc2 = Path()
      ..moveTo(x + gap, topY)
      ..arcTo(
        Rect.fromCircle(
          center: Offset(topLoopCenterX, topLoopCenterY),
          radius: topLoopRadius - gap,
        ),
        -1.57,
        3.14,
        false,
      );
    canvas.drawPath(topArc2, paint);

    // Нижняя петля буквы B
    final double bottomLoopRadius = width * 0.25;
    final double bottomLoopCenterX = x + bottomLoopRadius;
    final double bottomLoopCenterY = height * 0.65;

    // Нижняя дуга (внешняя)
    final bottomArc1 = Path()
      ..moveTo(x, height * 0.5)
      ..arcTo(
        Rect.fromCircle(
          center: Offset(bottomLoopCenterX, bottomLoopCenterY),
          radius: bottomLoopRadius,
        ),
        -1.57,
        3.14,
        false,
      );
    canvas.drawPath(bottomArc1, paint);

    // Нижняя дуга (внутренняя)
    final bottomArc2 = Path()
      ..moveTo(x + gap, height * 0.5)
      ..arcTo(
        Rect.fromCircle(
          center: Offset(bottomLoopCenterX, bottomLoopCenterY),
          radius: bottomLoopRadius - gap,
        ),
        -1.57,
        3.14,
        false,
      );
    canvas.drawPath(bottomArc2, paint);
  }

  @override
  bool shouldRepaint(BLogoPainter oldDelegate) =>
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.letterColor != letterColor;
}

