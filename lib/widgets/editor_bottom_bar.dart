import 'package:flutter/material.dart';
import 'package:koala/models/note.dart';
import 'package:koala/utils/date_utils.dart';
import 'package:koala/widgets/glass_container.dart';

/// Glass-morphism bottom bar for the note editor.
/// Uses GlassContainer to blur content behind it for a floating panel effect.
class EditorBottomBar extends StatelessWidget {
  final Note note;
  final VoidCallback onColorTap;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback onAddTap;
  final VoidCallback onMoreTap;

  const EditorBottomBar({
    super.key,
    required this.note,
    required this.onColorTap,
    this.onUndo,
    this.onRedo,
    required this.onAddTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 0,
      blurSigma: 28,
      addSpecularSheen: false,
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_box_outlined),
                  iconSize: 22,
                  onPressed: onAddTap,
                  tooltip: 'Add',
                ),
                IconButton(
                  icon: const Icon(Icons.palette_outlined),
                  iconSize: 22,
                  onPressed: onColorTap,
                  tooltip: 'Color',
                ),
              ],
            ),
            Text(
              AppDateUtils.formatEditedTime(note.updatedAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.45),
                    fontSize: 11,
                  ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.undo),
                  iconSize: 22,
                  onPressed: onUndo,
                ),
                IconButton(
                  icon: const Icon(Icons.redo),
                  iconSize: 22,
                  onPressed: onRedo,
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  iconSize: 22,
                  onPressed: onMoreTap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
