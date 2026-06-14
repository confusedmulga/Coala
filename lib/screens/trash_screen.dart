import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:koala/providers/notes_provider.dart';
import 'package:koala/widgets/app_drawer.dart';
import 'package:koala/widgets/note_grid.dart';
import 'package:koala/utils/constants.dart';
import 'package:koala/widgets/gradient_background.dart';
import 'package:koala/widgets/glass_container.dart';

class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(AppStrings.trash),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'empty') {
                  notesProvider.emptyTrash();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'empty',
                  child: Text(AppStrings.emptyTrash),
                ),
              ],
            ),
          ],
        ),
        drawer: const AppDrawer(selectedRoute: '/trash'),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: GlassContainer(
                borderRadius: 12,
                blurSigma: 12,
                tintOpacity: 0.40,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppStrings.trashNotice,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: NoteGrid(
                notes: notesProvider.trashedNotes,
                emptyMessage: AppStrings.noTrashedNotes,
                emptyIcon: Icons.delete_outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
