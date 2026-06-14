import 'package:flutter/foundation.dart';
import 'package:koala/models/label.dart';
import 'package:koala/services/database_service.dart';

/// Provider managing label CRUD operations.
class LabelsProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<Label> _labels = [];

  List<Label> get labels => _labels;

  Future<void> loadLabels() async {
    _labels = await _db.getAllLabels();
    notifyListeners();
  }

  Future<Label> createLabel(String name) async {
    final label = Label(
      name: name.trim(),
      sortOrder: _labels.length,
    );
    await _db.insertLabel(label);
    _labels.add(label);
    notifyListeners();
    return label;
  }

  Future<void> updateLabel(Label label) async {
    await _db.updateLabel(label);
    final index = _labels.indexWhere((l) => l.id == label.id);
    if (index != -1) {
      _labels[index] = label;
    }
    notifyListeners();
  }

  Future<void> deleteLabel(String id) async {
    await _db.deleteLabel(id);
    _labels.removeWhere((l) => l.id == id);
    notifyListeners();
  }

  Label? getLabelById(String id) {
    try {
      return _labels.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  String getLabelName(String id) {
    return getLabelById(id)?.name ?? '';
  }
}
