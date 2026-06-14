import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:koala/models/note.dart';
import 'package:koala/providers/notes_provider.dart';
import 'package:koala/utils/constants.dart';
import 'package:koala/widgets/app_drawer.dart';
import 'package:koala/widgets/keep_search_bar.dart';
import 'package:koala/widgets/note_grid.dart';
import 'package:koala/widgets/bottom_action_bar.dart';
import 'package:koala/widgets/color_picker.dart';
import 'package:koala/widgets/gradient_background.dart';
import 'package:koala/widgets/glass_container.dart';

/// The main home screen displaying active notes in a staggered grid layout.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String routeName = '/';

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final isSelectionMode = notesProvider.isSelectionMode;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawerScrimColor: Colors.black.withValues(alpha: 0.1),
        drawer: const AppDrawer(selectedRoute: '/'),
        body: isSelectionMode
            ? _buildSelectionBody(context, notesProvider)
            : _buildNormalBody(context, notesProvider),
        floatingActionButton: isSelectionMode
            ? null
            : _buildFab(context),
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
        bottomNavigationBar: isSelectionMode
            ? null
            : BottomActionBar(
                onNewChecklist: () => _createNewNote(context, isChecklist: true),
              ),
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FloatingActionButton(
      heroTag: 'fab_new_note',
      onPressed: () => _createNewNote(context, isChecklist: false),
      tooltip: 'New note',
      backgroundColor: isDark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.white.withValues(alpha: 0.80),
      foregroundColor: Theme.of(context).colorScheme.primary,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.90),
          width: 1.5,
        ),
      ),
      child: const Icon(Icons.add),
    );
  }

  Widget _buildNormalBody(BuildContext context, NotesProvider notesProvider) {
    final pinnedNotes = notesProvider.pinnedNotes;
    final unpinnedNotes = notesProvider.unpinnedNotes;

    return SafeArea(
      child: Column(
        children: [
          const KeepSearchBar(),
          Expanded(
            child: _buildNotesList(context, pinnedNotes, unpinnedNotes),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionBody(BuildContext context, NotesProvider notesProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Glass selection app bar
        GlassContainer(
          borderRadius: 0,
          blurSigma: 20,
          tintOpacity: isDark ? 0.08 : 0.60,
          borderOpacity: 0,
          boxShadow: [],
          addSpecularSheen: false,
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: kToolbarHeight,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => notesProvider.clearSelection(),
                  ),
                  Text(
                    '${notesProvider.selectedCount}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.push_pin_outlined),
                    tooltip: 'Pin',
                    onPressed: () => notesProvider.pinSelected(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_alert_outlined),
                    tooltip: 'Reminder',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Set reminder for selected')),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.palette_outlined),
                    tooltip: 'Change color',
                    onPressed: () {
                      ColorPicker.show(
                        context: context,
                        selectedColorIndex: 0,
                        onColorChanged: (colorIndex) {
                          notesProvider.changeColorSelected(colorIndex);
                        },
                      );
                    },
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'archive':
                          notesProvider.archiveSelected();
                          break;
                        case 'delete':
                          notesProvider.trashSelected();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'archive', child: Text('Archive')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: _buildNotesList(
            context,
            notesProvider.pinnedNotes,
            notesProvider.unpinnedNotes,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesList(
    BuildContext context,
    List<Note> pinnedNotes,
    List<Note> unpinnedNotes,
  ) {
    if (pinnedNotes.isEmpty && unpinnedNotes.isEmpty) {
      return NoteGrid(
        notes: const [],
        emptyMessage: AppStrings.noNotes,
        emptyIcon: Icons.lightbulb_outline,
      );
    }

    if (pinnedNotes.isEmpty) {
      return NoteGrid(
        notes: unpinnedNotes,
        emptyMessage: AppStrings.noNotes,
        emptyIcon: Icons.lightbulb_outline,
      );
    }

    if (unpinnedNotes.isEmpty) {
      return NoteGrid(
        notes: pinnedNotes,
        emptyMessage: AppStrings.noNotes,
        emptyIcon: Icons.lightbulb_outline,
      );
    }

    // Both pinned and unpinned exist — show sections
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, AppStrings.pinned),
          NoteGrid(
            notes: pinnedNotes,
            emptyMessage: '',
            emptyIcon: Icons.push_pin_outlined,
          ),
          const SizedBox(height: 8),
          _sectionHeader(context, AppStrings.others),
          NoteGrid(
            notes: unpinnedNotes,
            emptyMessage: '',
            emptyIcon: Icons.lightbulb_outline,
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.45),
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              fontSize: 10,
            ),
      ),
    );
  }

  Future<void> _createNewNote(BuildContext context,
      {required bool isChecklist}) async {
    final notesProvider = context.read<NotesProvider>();
    final note = await notesProvider.createNote(isChecklist: isChecklist);
    if (context.mounted) {
      Navigator.pushNamed(context, '/editor', arguments: note);
    }
  }
}
