import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:koala/models/note_color.dart';
import 'package:koala/providers/notes_provider.dart';
import 'package:koala/providers/labels_provider.dart';
import 'package:koala/widgets/note_grid.dart';
import 'package:koala/widgets/gradient_background.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final labelsProvider = context.watch<LabelsProvider>();

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              notesProvider.clearSearch();
              Navigator.pop(context);
            },
          ),
          title: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search your notes',
              border: InputBorder.none,
            ),
            onChanged: (value) {
              notesProvider.setSearchQuery(value);
            },
          ),
          actions: [
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  _searchController.clear();
                  notesProvider.setSearchQuery('');
                },
              ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilters(context, notesProvider, labelsProvider),
            Expanded(
              child: NoteGrid(
                notes: notesProvider.searchResults,
                emptyMessage: 'No matching notes',
                emptyIcon: Icons.search_off,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context, NotesProvider notesProvider, LabelsProvider labelsProvider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'Lists',
            isSelected: notesProvider.searchResults.any((n) => n.isChecklist),
            onSelected: (selected) {
              notesProvider.setSearchTypeFilter(selected ? 'lists' : null);
            },
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Reminders',
            isSelected: notesProvider.searchResults.any((n) => n.reminderTime != null),
            onSelected: (selected) {
              notesProvider.setSearchTypeFilter(selected ? 'reminders' : null);
            },
          ),
          const SizedBox(width: 8),
          ...labelsProvider.labels.map((label) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: _buildFilterChip(
                  label: label.name,
                  isSelected: notesProvider.searchResults.any((n) => n.labelIds.contains(label.id)),
                  onSelected: (selected) {
                    notesProvider.setSearchLabelFilter(selected ? label.id : null);
                  },
                ),
              )),
          const SizedBox(width: 8),
          ...NoteColor.colors.skip(1).map((color) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: InkWell(
                  onTap: () {
                    notesProvider.setSearchColorFilter(color.index);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.getColor(Theme.of(context).brightness),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required ValueChanged<bool> onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      showCheckmark: false,
    );
  }
}
