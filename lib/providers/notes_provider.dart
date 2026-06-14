import 'package:flutter/foundation.dart';
import 'package:koala/models/note.dart';
import 'package:koala/models/label.dart';
import 'package:koala/services/database_service.dart';

/// Provider managing all note operations — CRUD, filtering, search, multi-select.
class NotesProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<Note> _allNotes = [];
  String _searchQuery = '';
  int? _searchColorFilter;
  String? _searchLabelFilter;
  String? _searchTypeFilter;
  Set<String> _selectedNoteIds = {};
  bool _isSelectionMode = false;

  List<Note> get allNotes => _allNotes;
  String get searchQuery => _searchQuery;
  bool get isSelectionMode => _isSelectionMode;
  Set<String> get selectedNoteIds => _selectedNoteIds;
  int get selectedCount => _selectedNoteIds.length;

  // ===================== FILTERED LISTS =====================

  /// Active notes (not archived, not trashed).
  List<Note> get activeNotes =>
      _allNotes.where((n) => !n.isArchived && !n.isTrashed).toList();

  /// Pinned active notes.
  List<Note> get pinnedNotes =>
      activeNotes.where((n) => n.isPinned).toList();

  /// Unpinned active notes.
  List<Note> get unpinnedNotes =>
      activeNotes.where((n) => !n.isPinned).toList();

  /// Archived notes.
  List<Note> get archivedNotes =>
      _allNotes.where((n) => n.isArchived && !n.isTrashed).toList();

  /// Trashed notes.
  List<Note> get trashedNotes =>
      _allNotes.where((n) => n.isTrashed).toList();

  /// Notes with reminders.
  List<Note> get reminderNotes => _allNotes
      .where((n) => n.reminderTime != null && !n.isTrashed)
      .toList();

  /// Notes filtered by a specific label.
  List<Note> notesByLabel(String labelId) => _allNotes
      .where(
          (n) => n.labelIds.contains(labelId) && !n.isArchived && !n.isTrashed)
      .toList();

  /// Search results based on current filters.
  List<Note> get searchResults {
    var results = _allNotes.where((n) => !n.isTrashed).toList();

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      results = results.where((n) {
        return n.title.toLowerCase().contains(query) ||
            n.content.toLowerCase().contains(query) ||
            n.checklistItems
                .any((item) => item.content.toLowerCase().contains(query));
      }).toList();
    }

    if (_searchColorFilter != null) {
      results =
          results.where((n) => n.colorIndex == _searchColorFilter).toList();
    }

    if (_searchLabelFilter != null) {
      results = results
          .where((n) => n.labelIds.contains(_searchLabelFilter))
          .toList();
    }

    if (_searchTypeFilter != null) {
      switch (_searchTypeFilter) {
        case 'lists':
          results = results.where((n) => n.isChecklist).toList();
          break;
        case 'reminders':
          results = results.where((n) => n.reminderTime != null).toList();
          break;
      }
    }

    return results;
  }

  // ===================== LOADING =====================

  Future<void> loadNotes() async {
    _allNotes = await _db.getAllNotes();
    await _db.purgeOldTrashed();
    _allNotes = await _db.getAllNotes();
    
    // TEMPORARY: Inject dummy image notes for testing the new UI
    if (_allNotes.isEmpty) {
      await _createNoteWithImage('Beautiful Mountains', 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=600&q=80');
      await _createNoteWithImage('Modern Architecture', 'https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=600&q=80');
      await _createNoteWithImage('Morning Coffee', 'https://images.unsplash.com/photo-1497935586351-b67a49e012bf?auto=format&fit=crop&w=600&q=80');
    }

    notifyListeners();
  }

  Future<void> _createNoteWithImage(String title, String imageUrl) async {
    final note = Note(
      title: title,
      imageUrl: imageUrl,
      sortOrder: 0,
    );
    for (final n in activeNotes) {
      n.sortOrder += 1;
    }
    await _db.insertNote(note);
    _allNotes.insert(0, note);
  }


  // ===================== CRUD =====================

  Future<Note> createNote({bool isChecklist = false}) async {
    final note = Note(
      isChecklist: isChecklist,
      sortOrder: 0,
    );
    if (isChecklist) {
      note.checklistItems = [ChecklistItem(sortOrder: 0)];
    }
    // Shift existing sort orders
    for (final n in activeNotes) {
      n.sortOrder += 1;
    }
    await _db.insertNote(note);
    _allNotes.insert(0, note);
    notifyListeners();
    return note;
  }

  Future<void> updateNote(Note note) async {
    note.updatedAt = DateTime.now();
    await _db.updateNote(note);
    final index = _allNotes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _allNotes[index] = note;
    }
    notifyListeners();
  }

  Future<void> deleteNoteIfEmpty(Note note) async {
    if (note.isEmpty) {
      await _db.deleteNote(note.id);
      _allNotes.removeWhere((n) => n.id == note.id);
      notifyListeners();
    }
  }

  // ===================== NOTE ACTIONS =====================

  Future<void> togglePin(Note note) async {
    note.isPinned = !note.isPinned;
    await updateNote(note);
  }

  Future<void> archiveNote(Note note) async {
    note.isArchived = true;
    note.isPinned = false;
    await updateNote(note);
  }

  Future<void> unarchiveNote(Note note) async {
    note.isArchived = false;
    await updateNote(note);
  }

  Future<void> trashNote(Note note) async {
    note.isTrashed = true;
    note.isPinned = false;
    note.trashedAt = DateTime.now();
    await updateNote(note);
  }

  Future<void> restoreNote(Note note) async {
    note.isTrashed = false;
    note.trashedAt = null;
    await updateNote(note);
  }

  Future<void> deleteNotePermanently(Note note) async {
    await _db.deleteNote(note.id);
    _allNotes.removeWhere((n) => n.id == note.id);
    notifyListeners();
  }

  Future<void> emptyTrash() async {
    await _db.deleteAllTrashed();
    _allNotes.removeWhere((n) => n.isTrashed);
    notifyListeners();
  }

  Future<void> changeColor(Note note, int colorIndex) async {
    note.colorIndex = colorIndex;
    await updateNote(note);
  }

  Future<void> setReminder(Note note, DateTime? reminderTime) async {
    note.reminderTime = reminderTime;
    await updateNote(note);
  }

  Future<Note> copyNote(Note note) async {
    final copy = note.copy();
    await _db.insertNote(copy);
    _allNotes.insert(0, copy);
    notifyListeners();
    return copy;
  }

  Future<void> setNoteLabels(Note note, List<String> labelIds) async {
    note.labelIds = labelIds;
    await _db.setNoteLabels(note.id, labelIds);
    await updateNote(note);
  }

  // ===================== SEARCH =====================

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSearchColorFilter(int? colorIndex) {
    _searchColorFilter = colorIndex;
    notifyListeners();
  }

  void setSearchLabelFilter(String? labelId) {
    _searchLabelFilter = labelId;
    notifyListeners();
  }

  void setSearchTypeFilter(String? type) {
    _searchTypeFilter = type;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _searchColorFilter = null;
    _searchLabelFilter = null;
    _searchTypeFilter = null;
    notifyListeners();
  }

  // ===================== MULTI-SELECT =====================

  void toggleSelection(String noteId) {
    if (_selectedNoteIds.contains(noteId)) {
      _selectedNoteIds.remove(noteId);
      if (_selectedNoteIds.isEmpty) {
        _isSelectionMode = false;
      }
    } else {
      _selectedNoteIds.add(noteId);
      _isSelectionMode = true;
    }
    notifyListeners();
  }

  void startSelection(String noteId) {
    _isSelectionMode = true;
    _selectedNoteIds = {noteId};
    notifyListeners();
  }

  void clearSelection() {
    _isSelectionMode = false;
    _selectedNoteIds = {};
    notifyListeners();
  }

  List<Note> get selectedNotes =>
      _allNotes.where((n) => _selectedNoteIds.contains(n.id)).toList();

  Future<void> archiveSelected() async {
    for (final note in selectedNotes) {
      await archiveNote(note);
    }
    clearSelection();
  }

  Future<void> trashSelected() async {
    for (final note in selectedNotes) {
      await trashNote(note);
    }
    clearSelection();
  }

  Future<void> pinSelected() async {
    final allPinned = selectedNotes.every((n) => n.isPinned);
    for (final note in selectedNotes) {
      note.isPinned = !allPinned;
      await updateNote(note);
    }
    clearSelection();
  }

  Future<void> changeColorSelected(int colorIndex) async {
    for (final note in selectedNotes) {
      await changeColor(note, colorIndex);
    }
    clearSelection();
  }

  Future<void> setLabelsSelected(List<String> labelIds) async {
    for (final note in selectedNotes) {
      await setNoteLabels(note, labelIds);
    }
    clearSelection();
  }
}
