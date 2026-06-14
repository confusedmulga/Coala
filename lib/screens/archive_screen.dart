import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:koala/providers/notes_provider.dart';
import 'package:koala/widgets/app_drawer.dart';
import 'package:koala/widgets/note_grid.dart';
import 'package:koala/utils/constants.dart';
import 'package:koala/widgets/gradient_background.dart';

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(AppStrings.archive),
        ),
        drawer: const AppDrawer(selectedRoute: '/archive'),
        body: NoteGrid(
          notes: notesProvider.archivedNotes,
          emptyMessage: AppStrings.noArchivedNotes,
          emptyIcon: Icons.archive_outlined,
        ),
      ),
    );
  }
}
