import 'package:uuid/uuid.dart';

/// Label model for categorizing notes.
class Label {
  String id;
  String name;
  int sortOrder;

  Label({
    String? id,
    required this.name,
    this.sortOrder = 0,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sort_order': sortOrder,
    };
  }

  factory Label.fromMap(Map<String, dynamic> map) {
    return Label(
      id: map['id'] as String,
      name: map['name'] as String,
      sortOrder: map['sort_order'] as int? ?? 0,
    );
  }
}
