import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:koala/providers/notes_provider.dart';
import 'package:koala/widgets/app_drawer.dart';
import 'package:koala/widgets/note_grid.dart';
import 'package:koala/utils/constants.dart';
import 'package:koala/widgets/gradient_background.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(AppStrings.reminders),
        ),
        drawer: const AppDrawer(selectedRoute: '/reminders'),
        body: NoteGrid(
          notes: notesProvider.reminderNotes,
          emptyMessage: AppStrings.noReminders,
          emptyIcon: Icons.notifications_none,
        ),
      ),
    );
  }
}
