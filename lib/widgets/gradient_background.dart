import 'package:flutter/material.dart';

/// A gradient background widget that gives the glass effect something
/// beautiful to blur. Wrap Scaffold bodies with this.
class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF0F0F1A),
                  const Color(0xFF1A1A2E),
                  const Color(0xFF16213E),
                  const Color(0xFF0D1117),
                ]
              : [
                  const Color(0xFFF8F9FF),
                  const Color(0xFFEEF2FF),
                  const Color(0xFFF5F0FF),
                  const Color(0xFFFFF8F0),
                ],
          stops: const [0.0, 0.35, 0.65, 1.0],
        ),
      ),
      child: child,
    );
  }
}
