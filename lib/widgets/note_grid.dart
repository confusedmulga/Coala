import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:koala/models/note.dart';
import 'package:koala/providers/settings_provider.dart';
import 'package:koala/utils/constants.dart';
import 'package:koala/widgets/note_card.dart';

class NoteGrid extends StatelessWidget {
  final List<Note> notes;
  final String emptyMessage;
  final IconData emptyIcon;

  const NoteGrid({
    super.key,
    required this.notes,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              emptyIcon,
              size: 100,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    final isGridView = context.watch<SettingsProvider>().isGridView;
    final pinnedNotes = notes.where((n) => n.isPinned).toList();
    final otherNotes = notes.where((n) => !n.isPinned).toList();

    return ListView(
      padding: const EdgeInsets.all(AppDimensions.gridPadding),
      children: [
        if (pinnedNotes.isNotEmpty) ...[
          _buildSectionHeader(context, AppStrings.pinned),
          _buildGrid(pinnedNotes, isGridView),
          const SizedBox(height: 16),
        ],
        if (pinnedNotes.isNotEmpty && otherNotes.isNotEmpty)
          _buildSectionHeader(context, AppStrings.others),
        if (otherNotes.isNotEmpty) _buildGrid(otherNotes, isGridView),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
      ),
    );
  }

  Widget _buildGrid(List<Note> notesToDisplay, bool isGridView) {
    if (!isGridView) {
      return MasonryGridView.count(
        crossAxisCount: 1,
        mainAxisSpacing: AppDimensions.gridSpacing,
        crossAxisSpacing: AppDimensions.gridSpacing,
        itemCount: notesToDisplay.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return NoteCard(note: notesToDisplay[index]);
        },
      );
    }

    return MasonryGridView.extent(
      maxCrossAxisExtent: 220.0, // Natural sizing like Pinterest
      mainAxisSpacing: AppDimensions.gridSpacing,
      crossAxisSpacing: AppDimensions.gridSpacing,
      itemCount: notesToDisplay.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return NoteCard(note: notesToDisplay[index]);
      },
    );
  }
}
