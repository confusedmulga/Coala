import 'dart:ui';
import 'package:flutter/material.dart';

/// A reusable frosted-glass container using BackdropFilter.
/// Provides the liquid-glass aesthetic with blur, tint, specular sheen,
/// and a subtle edge highlight.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final double tintOpacity;
  final double borderOpacity;
  final Color? tintColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final List<BoxShadow>? boxShadow;
  final bool addSpecularSheen;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20.0,
    this.blurSigma = 20.0,
    this.tintOpacity = 0.12,
    this.borderOpacity = 0.30,
    this.tintColor,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.boxShadow,
    this.addSpecularSheen = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Resolve tint: caller-specified color, or adaptive white/dark
    final resolvedTint = tintColor ??
        (isDark
            ? Colors.white.withValues(alpha: tintOpacity * 0.6)
            : Colors.white.withValues(alpha: tintOpacity));

    final borderColor = isDark
        ? Colors.white.withValues(alpha: borderOpacity * 0.5)
        : Colors.white.withValues(alpha: borderOpacity);

    // Soft shadow for depth
    final shadows = boxShadow ??
        (isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  spreadRadius: -2,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.8),
                  blurRadius: 0,
                  spreadRadius: 0,
                  offset: const Offset(0, 0),
                ),
              ]);

    return Container(
      margin: margin,
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              // Glass fill tint
              color: resolvedTint,
              borderRadius: BorderRadius.circular(borderRadius),
              // Specular sheen gradient (top-left bright → bottom-right dim)
              gradient: addSpecularSheen
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              Colors.white.withValues(alpha: 0.10),
                              Colors.white.withValues(alpha: 0.02),
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.55),
                              Colors.white.withValues(alpha: 0.10),
                            ],
                      stops: const [0.0, 1.0],
                    )
                  : null,
              // Edge / border highlight
              border: Border.all(
                color: borderColor,
                width: 1.2,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
