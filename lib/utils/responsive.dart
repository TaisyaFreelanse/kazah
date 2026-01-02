import 'package:flutter/material.dart';

class Responsive {

  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static double textSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;

    const double baseScreenWidth = 360.0;

    final scale = screenWidth / baseScreenWidth;

    final limitedScale = scale.clamp(0.7, 1.2);
    return baseSize * limitedScale;
  }

  static double dp(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;

    const double baseScreenWidth = 360.0;

    final scale = screenWidth / baseScreenWidth;
    return baseSize * scale;
  }

  static double widthPercent(BuildContext context, double percent) {
    return screenWidth(context) * percent / 100;
  }

  static double heightPercent(BuildContext context, double percent) {
    return screenHeight(context) * percent / 100;
  }

  static bool isSmallScreen(BuildContext context) {
    return screenWidth(context) < 600;
  }

  static bool isMediumScreen(BuildContext context) {
    final width = screenWidth(context);
    return width >= 600 && width < 900;
  }

  static bool isLargeScreen(BuildContext context) {
    return screenWidth(context) >= 900;
  }

  static double adaptiveFontSize(BuildContext context, {
    required double small,
    double? medium,
    double? large,
  }) {
    if (isLargeScreen(context) && large != null) {
      return textSize(context, large);
    } else if (isMediumScreen(context) && medium != null) {
      return textSize(context, medium);
    } else {
      return textSize(context, small);
    }
  }

  static double adaptivePadding(BuildContext context, {
    required double small,
    double? medium,
    double? large,
  }) {
    if (isLargeScreen(context) && large != null) {
      return dp(context, large);
    } else if (isMediumScreen(context) && medium != null) {
      return dp(context, medium);
    } else {
      return dp(context, small);
    }
  }

  static double adaptiveSize(BuildContext context, {
    required double small,
    double? medium,
    double? large,
  }) {
    if (isLargeScreen(context) && large != null) {
      return dp(context, large);
    } else if (isMediumScreen(context) && medium != null) {
      return dp(context, medium);
    } else {
      return dp(context, small);
    }
  }

  static EdgeInsets horizontalPadding(BuildContext context, {
    double small = 16,
    double? medium,
    double? large,
  }) {
    final padding = adaptivePadding(
      context,
      small: small,
      medium: medium ?? small * 1.5,
      large: large ?? small * 2,
    );
    return EdgeInsets.symmetric(horizontal: padding);
  }

  static EdgeInsets verticalPadding(BuildContext context, {
    double small = 16,
    double? medium,
    double? large,
  }) {
    final padding = adaptivePadding(
      context,
      small: small,
      medium: medium ?? small * 1.5,
      large: large ?? small * 2,
    );
    return EdgeInsets.symmetric(vertical: padding);
  }

  static EdgeInsets symmetricPadding(BuildContext context, {
    double small = 16,
    double? medium,
    double? large,
  }) {
    final padding = adaptivePadding(
      context,
      small: small,
      medium: medium ?? small * 1.5,
      large: large ?? small * 2,
    );
    return EdgeInsets.all(padding);
  }

  static double iconSize(BuildContext context, {
    double small = 24,
    double? medium,
    double? large,
  }) {
    return adaptiveSize(
      context,
      small: small,
      medium: medium ?? small * 1.2,
      large: large ?? small * 1.5,
    );
  }

  static double buttonHeight(BuildContext context, {
    double small = 48,
    double? medium,
    double? large,
  }) {
    return adaptiveSize(
      context,
      small: small,
      medium: medium ?? small * 1.1,
      large: large ?? small * 1.2,
    );
  }
}

