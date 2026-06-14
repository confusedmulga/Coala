import 'package:flutter/material.dart';
import 'package:koala/models/note_color.dart';
import 'package:koala/utils/constants.dart';

/// Shows a modal bottom sheet with a row of color circles for picking a note color.
/// The default color (index 0) shows a diagonal slash-through circle.
/// The currently selected color shows a checkmark overlay.
class ColorPicker extends StatelessWidget {
  final int selectedColorIndex;
  final ValueChanged<int> onColorChanged;

  const ColorPicker({
    super.key,
    required this.selectedColorIndex,
    required this.onColorChanged,
  });

  /// Shows the color picker as a glass modal bottom sheet.
  static Future<void> show({
    required BuildContext context,
    required int selectedColorIndex,
    required ValueChanged<int> onColorChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet(
      context: context,
      backgroundColor: isDark
          ? Colors.white.withValues(alpha: 0.07)
          : Colors.white.withValues(alpha: 0.75),
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: Colors.transparent),
      ),
      builder: (context) => ColorPicker(
        selectedColorIndex: selectedColorIndex,
        onColorChanged: onColorChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.colorAndBackground,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: NoteColor.colors.map((noteColor) {
                final isSelected = noteColor.index == selectedColorIndex;
                final displayColor = noteColor.getColor(brightness);

                return Padding(
                  padding: const EdgeInsets.only(
                      right: AppDimensions.colorCircleSpacing),
                  child: GestureDetector(
                    onTap: () => onColorChanged(noteColor.index),
                    child: _ColorCircle(
                      color: displayColor,
                      isSelected: isSelected,
                      isDefault: noteColor.index == 0,
                      brightness: brightness,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ColorCircle extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final bool isDefault;
  final Brightness brightness;

  const _ColorCircle({
    required this.color,
    required this.isSelected,
    required this.isDefault,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    final size = AppDimensions.colorCircleSize;
    final borderColor = isSelected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.outlineVariant;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isDefault
                  ? (brightness == Brightness.light
                      ? Colors.white
                      : const Color(0xFF202124))
                  : color,
              shape: BoxShape.circle,
              border: Border.all(
                color: borderColor,
                width: isSelected ? 2.0 : 1.0,
              ),
            ),
          ),
          if (isDefault && !isSelected)
            CustomPaint(
              size: Size(size * 0.55, size * 0.55),
              painter: _SlashPainter(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          if (isSelected)
            Icon(
              Icons.check,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
        ],
      ),
    );
  }
}

/// Draws a diagonal line (slash) through the circle for the "no color" default.
class _SlashPainter extends CustomPainter {
  final Color color;

  _SlashPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, 0),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SlashPainter oldDelegate) =>
      color != oldDelegate.color;
}
