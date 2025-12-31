import 'package:flutter/material.dart';

class PackageBadge extends StatelessWidget {
  final Color color;

  const PackageBadge({
    super.key,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

