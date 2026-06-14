import 'package:uuid/uuid.dart';

/// A single checklist item within a note.
class ChecklistItem {
  String id;
  String content;
  bool isChecked;
  int sortOrder;

  ChecklistItem({
    String? id,
    this.content = '',
    this.isChecked = false,
    this.sortOrder = 0,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap(String noteId) {
    return {
      'id': id,
      'note_id': noteId,
      'content': content,
      'is_checked': isChecked ? 1 : 0,
      'sort_order': sortOrder,
    };
  }

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id: map['id'] as String,
      content: map['content'] as String? ?? '',
      isChecked: (map['is_checked'] as int?) == 1,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }

  ChecklistItem copy() {
    return ChecklistItem(
      id: const Uuid().v4(),
      content: content,
      isChecked: isChecked,
      sortOrder: sortOrder,
    );
  }
}

/// The main Note model.
class Note {
  String id;
  String title;
  String content;
  bool isChecklist;
  int colorIndex;
  bool isPinned;
  bool isArchived;
  bool isTrashed;
  DateTime? reminderTime;
  int sortOrder;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? trashedAt;
  List<ChecklistItem> checklistItems;
  List<String> labelIds;
  String? imageUrl;

  Note({
    String? id,
    this.title = '',
    this.content = '',
    this.isChecklist = false,
    this.colorIndex = 0,
    this.isPinned = false,
    this.isArchived = false,
    this.isTrashed = false,
    this.reminderTime,
    this.sortOrder = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.trashedAt,
    List<ChecklistItem>? checklistItems,
    List<String>? labelIds,
    this.imageUrl,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        checklistItems = checklistItems ?? [],
        labelIds = labelIds ?? [];

  /// Whether the note is effectively empty (no content worth saving).
  bool get isEmpty {
    if (title.trim().isNotEmpty) return false;
    if (imageUrl != null && imageUrl!.isNotEmpty) return false;
    if (isChecklist) {
      return checklistItems.every((item) => item.content.trim().isEmpty);
    }
    return content.trim().isEmpty;
  }

  /// A short preview of the note content for display in cards.
  String get contentPreview {
    if (isChecklist) {
      final unchecked =
          checklistItems.where((item) => !item.isChecked).toList();
      if (unchecked.isEmpty) return '';
      return unchecked
          .take(8)
          .map((item) => item.content)
          .where((c) => c.isNotEmpty)
          .join('\n');
    }
    // Strip out [IMG:...] tags for the preview
    return content.replaceAll(RegExp(r'\[IMG:.*?\]\n?'), '').trim();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'is_checklist': isChecklist ? 1 : 0,
      'color_index': colorIndex,
      'is_pinned': isPinned ? 1 : 0,
      'is_archived': isArchived ? 1 : 0,
      'is_trashed': isTrashed ? 1 : 0,
      'reminder_time': reminderTime?.toIso8601String(),
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'trashed_at': trashedAt?.toIso8601String(),
      'image_url': imageUrl,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      isChecklist: (map['is_checklist'] as int?) == 1,
      colorIndex: map['color_index'] as int? ?? 0,
      isPinned: (map['is_pinned'] as int?) == 1,
      isArchived: (map['is_archived'] as int?) == 1,
      isTrashed: (map['is_trashed'] as int?) == 1,
      reminderTime: map['reminder_time'] != null
          ? DateTime.parse(map['reminder_time'] as String)
          : null,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      trashedAt: map['trashed_at'] != null
          ? DateTime.parse(map['trashed_at'] as String)
          : null,
      imageUrl: map['image_url'] as String?,
    );
  }

  Note copy() {
    return Note(
      title: title,
      content: content,
      isChecklist: isChecklist,
      colorIndex: colorIndex,
      isPinned: false,
      isArchived: isArchived,
      isTrashed: false,
      reminderTime: null,
      checklistItems:
          checklistItems.map((item) => item.copy()).toList(),
      labelIds: List<String>.from(labelIds),
      imageUrl: imageUrl,
    );
  }
}
