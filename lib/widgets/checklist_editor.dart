import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:koala/models/note.dart';
import 'package:koala/providers/settings_provider.dart';
import 'package:koala/utils/constants.dart';

class ChecklistEditor extends StatefulWidget {
  final Note note;
  final VoidCallback onChanged;

  const ChecklistEditor({
    super.key,
    required this.note,
    required this.onChanged,
  });

  @override
  State<ChecklistEditor> createState() => _ChecklistEditorState();
}

class _ChecklistEditorState extends State<ChecklistEditor> {
  late FocusNode _newFocusNode;
  final TextEditingController _newController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _newFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _newFocusNode.dispose();
    _newController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final uncheckedItems = widget.note.checklistItems
        .where((item) => !item.isChecked)
        .toList();
    final checkedItems = widget.note.checklistItems
        .where((item) => item.isChecked)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (uncheckedItems.isNotEmpty)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: uncheckedItems.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = uncheckedItems.removeAt(oldIndex);
                uncheckedItems.insert(newIndex, item);
                _updateSortOrders(uncheckedItems, checkedItems);
                widget.onChanged();
              });
            },
            itemBuilder: (context, index) {
              return _buildChecklistItem(uncheckedItems[index], context);
            },
          ),
        _buildAddItemRow(),
        if (checkedItems.isNotEmpty && settings.showCheckedItems)
          _buildCheckedItemsSection(checkedItems, settings),
      ],
    );
  }

  Widget _buildChecklistItem(ChecklistItem item, BuildContext context) {
    return Container(
      key: ValueKey(item.id),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: widget.note.checklistItems.indexOf(item),
            child: const Icon(Icons.drag_indicator, color: Colors.grey),
          ),
          Checkbox(
            value: item.isChecked,
            onChanged: (value) {
              setState(() {
                item.isChecked = value ?? false;
                widget.onChanged();
              });
            },
          ),
          Expanded(
            child: TextFormField(
              initialValue: item.content,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                decoration: item.isChecked ? TextDecoration.lineThrough : null,
                color: item.isChecked ? Colors.grey : null,
              ),
              onChanged: (value) {
                item.content = value;
                widget.onChanged();
              },
              onFieldSubmitted: (_) {
                _addNewItem();
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () {
              setState(() {
                widget.note.checklistItems.remove(item);
                widget.onChanged();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAddItemRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          const SizedBox(width: 24),
          const Icon(Icons.add, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _newController,
              focusNode: _newFocusNode,
              decoration: const InputDecoration(
                hintText: AppStrings.listItem,
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _addNewItem();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckedItemsSection(
      List<ChecklistItem> checkedItems, SettingsProvider settings) {
    return ExpansionTile(
      title: Text('${checkedItems.length} ${AppStrings.checkedItems}'),
      initiallyExpanded: true,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: checkedItems.length,
          itemBuilder: (context, index) {
            return _buildChecklistItem(checkedItems[index], context);
          },
        ),
      ],
    );
  }

  void _addNewItem() {
    if (_newController.text.isNotEmpty) {
      setState(() {
        widget.note.checklistItems.add(
          ChecklistItem(
            content: _newController.text,
            sortOrder: widget.note.checklistItems.length,
          ),
        );
        _newController.clear();
        widget.onChanged();
        _newFocusNode.requestFocus();
      });
    } else {
      setState(() {
        widget.note.checklistItems.add(
          ChecklistItem(
            content: '',
            sortOrder: widget.note.checklistItems.length,
          ),
        );
        widget.onChanged();
        _newFocusNode.requestFocus();
      });
    }
  }

  void _updateSortOrders(
      List<ChecklistItem> unchecked, List<ChecklistItem> checked) {
    int i = 0;
    for (var item in unchecked) {
      item.sortOrder = i++;
    }
    for (var item in checked) {
      item.sortOrder = i++;
    }
    widget.note.checklistItems = [...unchecked, ...checked];
  }
}
