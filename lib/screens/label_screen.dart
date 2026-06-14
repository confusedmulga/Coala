import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:koala/providers/notes_provider.dart';
import 'package:koala/providers/settings_provider.dart';
import 'package:koala/widgets/app_drawer.dart';
import 'package:koala/widgets/note_grid.dart';
import 'package:koala/utils/constants.dart';
import 'package:koala/widgets/gradient_background.dart';

class LabelScreen extends StatelessWidget {
  final String labelId;
  final String labelName;

  const LabelScreen({
    super.key,
    required this.labelId,
    required this.labelName,
  });

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(labelName),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                Navigator.pushNamed(context, '/search');
              },
            ),
            IconButton(
              icon: Icon(
                settingsProvider.isGridView
                    ? Icons.view_agenda_outlined
                    : Icons.grid_view,
              ),
              onPressed: () {
                settingsProvider.toggleViewMode();
              },
            ),
          ],
        ),
        drawer: AppDrawer(selectedRoute: 'label_$labelId'),
        body: NoteGrid(
          notes: notesProvider.notesByLabel(labelId),
          emptyMessage: AppStrings.noNotes,
          emptyIcon: Icons.label_outline,
        ),
      ),
    );
  }
}
