import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:koala/models/note.dart';
import 'package:koala/models/label.dart';

/// Singleton service managing all SQLite database operations.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'koala.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE notes ADD COLUMN image_url TEXT');
        }
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        title TEXT,
        content TEXT,
        is_checklist INTEGER DEFAULT 0,
        color_index INTEGER DEFAULT 0,
        is_pinned INTEGER DEFAULT 0,
        is_archived INTEGER DEFAULT 0,
        is_trashed INTEGER DEFAULT 0,
        reminder_time TEXT,
        sort_order INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        trashed_at TEXT,
        image_url TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE checklist_items (
        id TEXT PRIMARY KEY,
        note_id TEXT NOT NULL,
        content TEXT,
        is_checked INTEGER DEFAULT 0,
        sort_order INTEGER DEFAULT 0,
        FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE labels (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        sort_order INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE note_labels (
        note_id TEXT NOT NULL,
        label_id TEXT NOT NULL,
        PRIMARY KEY (note_id, label_id),
        FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE,
        FOREIGN KEY (label_id) REFERENCES labels(id) ON DELETE CASCADE
      )
    ''');
  }

  // ===================== NOTES =====================

  Future<List<Note>> getAllNotes() async {
    final db = await database;
    final maps = await db.query('notes', orderBy: 'sort_order ASC, updated_at DESC');
    final notes = <Note>[];

    for (final map in maps) {
      final note = Note.fromMap(map);
      note.checklistItems = await getChecklistItems(note.id);
      note.labelIds = await getNoteLabelIds(note.id);
      notes.add(note);
    }
    return notes;
  }

  Future<Note?> getNoteById(String id) async {
    final db = await database;
    final maps = await db.query('notes', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    final note = Note.fromMap(maps.first);
    note.checklistItems = await getChecklistItems(note.id);
    note.labelIds = await getNoteLabelIds(note.id);
    return note;
  }

  Future<void> insertNote(Note note) async {
    final db = await database;
    await db.insert('notes', note.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);

    // Insert checklist items
    for (final item in note.checklistItems) {
      await db.insert('checklist_items', item.toMap(note.id),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Insert label associations
    for (final labelId in note.labelIds) {
      await db.insert(
        'note_labels',
        {'note_id': note.id, 'label_id': labelId},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> updateNote(Note note) async {
    final db = await database;
    note.updatedAt = DateTime.now();
    await db.update('notes', note.toMap(), where: 'id = ?', whereArgs: [note.id]);

    // Replace checklist items
    await db.delete('checklist_items', where: 'note_id = ?', whereArgs: [note.id]);
    for (final item in note.checklistItems) {
      await db.insert('checklist_items', item.toMap(note.id));
    }

    // Replace label associations
    await db.delete('note_labels', where: 'note_id = ?', whereArgs: [note.id]);
    for (final labelId in note.labelIds) {
      await db.insert(
        'note_labels',
        {'note_id': note.id, 'label_id': labelId},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> deleteNote(String id) async {
    final db = await database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllTrashed() async {
    final db = await database;
    await db.delete('notes', where: 'is_trashed = 1');
  }

  /// Purge trashed notes older than 7 days.
  Future<void> purgeOldTrashed() async {
    final db = await database;
    final cutoff =
        DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
    await db.delete(
      'notes',
      where: 'is_trashed = 1 AND trashed_at IS NOT NULL AND trashed_at < ?',
      whereArgs: [cutoff],
    );
  }

  // ===================== CHECKLIST ITEMS =====================

  Future<List<ChecklistItem>> getChecklistItems(String noteId) async {
    final db = await database;
    final maps = await db.query(
      'checklist_items',
      where: 'note_id = ?',
      whereArgs: [noteId],
      orderBy: 'sort_order ASC',
    );
    return maps.map((m) => ChecklistItem.fromMap(m)).toList();
  }

  // ===================== LABELS =====================

  Future<List<Label>> getAllLabels() async {
    final db = await database;
    final maps = await db.query('labels', orderBy: 'sort_order ASC, name ASC');
    return maps.map((m) => Label.fromMap(m)).toList();
  }

  Future<void> insertLabel(Label label) async {
    final db = await database;
    await db.insert('labels', label.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> updateLabel(Label label) async {
    final db = await database;
    await db.update('labels', label.toMap(),
        where: 'id = ?', whereArgs: [label.id]);
  }

  Future<void> deleteLabel(String id) async {
    final db = await database;
    await db.delete('labels', where: 'id = ?', whereArgs: [id]);
  }

  // ===================== NOTE-LABEL RELATIONS =====================

  Future<List<String>> getNoteLabelIds(String noteId) async {
    final db = await database;
    final maps = await db.query('note_labels',
        where: 'note_id = ?', whereArgs: [noteId]);
    return maps.map((m) => m['label_id'] as String).toList();
  }

  Future<void> setNoteLabels(String noteId, List<String> labelIds) async {
    final db = await database;
    await db.delete('note_labels', where: 'note_id = ?', whereArgs: [noteId]);
    for (final labelId in labelIds) {
      await db.insert(
        'note_labels',
        {'note_id': noteId, 'label_id': labelId},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }
}
