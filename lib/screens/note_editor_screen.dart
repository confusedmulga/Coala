import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:koala/models/note.dart';
import 'package:koala/models/note_color.dart';
import 'package:koala/providers/notes_provider.dart';
import 'package:koala/providers/labels_provider.dart';
import 'package:koala/services/notification_service.dart';
import 'package:koala/utils/date_utils.dart';
import 'package:koala/widgets/color_picker.dart';
import 'package:koala/widgets/checklist_editor.dart';
import 'package:koala/widgets/editor_bottom_bar.dart';
import 'package:koala/widgets/label_chips.dart';
import 'package:koala/widgets/reminder_chip.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'package:koala/widgets/gradient_background.dart';

/// Full-screen note editor with title, content/checklist editing,
/// color theming, labels, reminders, and auto-save on back.
class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({super.key});

  static const String routeName = '/editor';

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late Note _note;
  late TextEditingController _titleController;
  List<dynamic> _blocks = [];
  int? _focusedBlockIndex;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final arg = ModalRoute.of(context)?.settings.arguments;
      if (arg is Note) {
        _note = arg;
      } else {
        _note = Note();
      }
      _titleController = TextEditingController(text: _note.title);
      
      _blocks = [];
      if (_note.imageUrl != null) {
        _blocks.add(_note.imageUrl!);
        _note.imageUrl = null;
      }

      if (!_note.isChecklist) {
        final parts = _note.content.split(RegExp(r'(\[IMG:.*?\]\n?)'));
        for (var part in parts) {
          if (part.startsWith('[IMG:')) {
            final path = part.substring(5, part.indexOf(']'));
            _blocks.add(path);
          } else if (part.isNotEmpty) {
            _blocks.add(TextEditingController(text: part));
          }
        }
      }
      if (_blocks.isEmpty || _blocks.last is String) {
        _blocks.add(TextEditingController());
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (var block in _blocks) {
      if (block is TextEditingController) block.dispose();
    }
    super.dispose();
  }

  String _getContentText() {
    return _blocks.map((block) {
      if (block is TextEditingController) return block.text;
      if (block is String) return '[IMG:$block]\n';
      return '';
    }).join();
  }

  String _getTextOnlyContent() {
    return _blocks.map((block) {
      if (block is TextEditingController) return block.text;
      return '';
    }).join('\n').trim();
  }

  Future<void> _saveAndPop() async {
    _note.title = _titleController.text;
    if (!_note.isChecklist) {
      _note.content = _getContentText();
      final firstImage = _blocks.firstWhere((b) => b is String, orElse: () => null) as String?;
      _note.imageUrl = firstImage;
    }

    final notesProvider = context.read<NotesProvider>();

    if (_note.isEmpty) {
      await notesProvider.deleteNoteIfEmpty(_note);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Empty note discarded')),
        );
      }
    } else {
      await notesProvider.updateNote(_note);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _togglePin() {
    setState(() {
      _note.isPinned = !_note.isPinned;
    });
  }

  void _archiveNote() async {
    _note.title = _titleController.text;
    if (!_note.isChecklist) {
      _note.content = _getContentText();
      final firstImage = _blocks.firstWhere((b) => b is String, orElse: () => null) as String?;
      _note.imageUrl = firstImage;
    }

    final notesProvider = context.read<NotesProvider>();
    await notesProvider.archiveNote(_note);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note archived')),
      );
      Navigator.pop(context);
    }
  }

  void _showColorPicker() {
    ColorPicker.show(
      context: context,
      selectedColorIndex: _note.colorIndex,
      onColorChanged: (colorIndex) {
        setState(() {
          _note.colorIndex = colorIndex;
        });
      },
    );
  }

  Future<void> _showReminderPicker() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _note.reminderTime ?? now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
          _note.reminderTime ?? now.add(const Duration(hours: 1))),
    );
    if (time == null || !mounted) return;

    final reminderDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    if (reminderDateTime.isBefore(DateTime.now())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a future time')),
        );
      }
      return;
    }

    setState(() {
      _note.reminderTime = reminderDateTime;
    });

    await NotificationService().scheduleReminder(
      noteId: _note.id,
      title: _note.title.isNotEmpty ? _note.title : 'Coala Reminder',
      body: _note.isChecklist
          ? _note.contentPreview
          : (_getTextOnlyContent().isNotEmpty ? _getTextOnlyContent() : 'You have a reminder'),
      scheduledTime: reminderDateTime,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Reminder set: ${AppDateUtils.formatReminder(reminderDateTime)}'),
        ),
      );
    }
  }

  void _showAddMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  _note.isChecklist
                      ? Icons.text_fields
                      : Icons.check_box_outlined,
                ),
                title: Text(
                  _note.isChecklist ? 'Convert to text note' : 'Checkboxes',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _toggleChecklistMode();
                },
              ),
              ListTile(
                leading: const Icon(Icons.brush_outlined),
                title: const Text('Drawing'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showComingSoon();
                },
              ),
              ListTile(
                leading: const Icon(Icons.mic_outlined),
                title: const Text('Recording'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showComingSoon();
                },
              ),
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const Text('Image'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _toggleChecklistMode() {
    setState(() {
      if (_note.isChecklist) {
        // Convert checklist to text
        _note.content = _note.checklistItems
            .map((item) => item.content)
            .where((c) => c.isNotEmpty)
            .join('\n');
        _note.isChecklist = false;
        _note.checklistItems = [];
        
        for (var block in _blocks) {
          if (block is TextEditingController) block.dispose();
        }
        _blocks = [TextEditingController(text: _note.content)];
      } else {
        // Convert text to checklist
        final textOnly = _getTextOnlyContent();
        final lines = textOnly.split('\n');
        _note.checklistItems = lines
            .asMap()
            .entries
            .map((entry) => ChecklistItem(
                  content: entry.value,
                  sortOrder: entry.key,
                ))
            .toList();
        if (_note.checklistItems.isEmpty) {
          _note.checklistItems = [ChecklistItem(sortOrder: 0)];
        }
        _note.isChecklist = true;
        _note.content = '';
      }
    });
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon')),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null && mounted) {
        setState(() {
          final path = pickedFile.path;
          if (_focusedBlockIndex != null && _focusedBlockIndex! < _blocks.length && _blocks[_focusedBlockIndex!] is TextEditingController) {
            final ctrl = _blocks[_focusedBlockIndex!] as TextEditingController;
            final text = ctrl.text;
            int cursorPosition = ctrl.selection.baseOffset;
            if (cursorPosition < 0) cursorPosition = text.length;

            final textBefore = text.substring(0, cursorPosition);
            final textAfter = text.substring(cursorPosition);

            ctrl.text = textBefore;

            _blocks.insert(_focusedBlockIndex! + 1, path);
            _blocks.insert(_focusedBlockIndex! + 2, TextEditingController(text: textAfter));
            _focusedBlockIndex = _focusedBlockIndex! + 2;
          } else {
            _blocks.add(path);
            _blocks.add(TextEditingController());
            _focusedBlockIndex = _blocks.length - 1;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outlined),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteNote();
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: const Text('Make a copy'),
                onTap: () {
                  Navigator.pop(ctx);
                  _copyNote();
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('Send'),
                onTap: () {
                  Navigator.pop(ctx);
                  _shareNote();
                },
              ),
              ListTile(
                leading: const Icon(Icons.label_outline),
                title: const Text('Labels'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showLabelsDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteNote() async {
    final notesProvider = context.read<NotesProvider>();
    await notesProvider.trashNote(_note);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note moved to trash')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _copyNote() async {
    _note.title = _titleController.text;
    if (!_note.isChecklist) {
      _note.content = _getContentText();
      final firstImage = _blocks.firstWhere((b) => b is String, orElse: () => null) as String?;
      _note.imageUrl = firstImage;
    }

    final notesProvider = context.read<NotesProvider>();
    await notesProvider.copyNote(_note);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note copied')),
      );
    }
  }

  void _shareNote() {
    final title = _titleController.text;
    final content = _note.isChecklist ? _note.contentPreview : _getTextOnlyContent();
    final text = [title, content].where((s) => s.isNotEmpty).join('\n\n');
    if (text.isNotEmpty) {
      Share.share(text);
    }
  }

  void _showLabelsDialog() {
    final labelsProvider = context.read<LabelsProvider>();
    final allLabels = labelsProvider.labels;
    final selectedIds = Set<String>.from(_note.labelIds);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Label note'),
              content: SizedBox(
                width: double.maxFinite,
                child: allLabels.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No labels yet. Create labels first.'),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: allLabels.length,
                        itemBuilder: (ctx, index) {
                          final label = allLabels[index];
                          final isSelected = selectedIds.contains(label.id);
                          return CheckboxListTile(
                            title: Text(label.name),
                            value: isSelected,
                            onChanged: (val) {
                              setDialogState(() {
                                if (val == true) {
                                  selectedIds.add(label.id);
                                } else {
                                  selectedIds.remove(label.id);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _note.labelIds = selectedIds.toList();
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    final hasColor = _note.colorIndex != 0;
    final rawNoteColor = hasColor
        ? NoteColor.fromIndex(_note.colorIndex).getColor(brightness)
        : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _saveAndPop();
      },
      child: Hero(
        tag: 'note-${_note.id}',
        child: GradientBackground(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            color: hasColor
                ? rawNoteColor!.withValues(alpha: isDark ? 0.15 : 0.20)
                : Colors.transparent,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              resizeToAvoidBottomInset: false,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _saveAndPop,
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      _note.isPinned
                          ? Icons.push_pin
                          : Icons.push_pin_outlined,
                    ),
                    tooltip: _note.isPinned ? 'Unpin' : 'Pin',
                    onPressed: _togglePin,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_alert_outlined),
                    tooltip: 'Reminder',
                    onPressed: _showReminderPicker,
                  ),
                  IconButton(
                    icon: const Icon(Icons.archive_outlined),
                    tooltip: 'Archive',
                    onPressed: _archiveNote,
                  ),
                ],
              ),
              body: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        0,
                        20,
                        MediaQuery.viewInsetsOf(context).bottom + 72,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_note.labelIds.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: LabelChips(labelIds: _note.labelIds),
                            ),
                          if (_note.reminderTime != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: ReminderChip(reminderTime: _note.reminderTime),
                            ),
                          TextField(
                            controller: _titleController,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.5,
                                ),
                            decoration: const InputDecoration(
                              hintText: 'Title',
                              border: InputBorder.none,
                            ),
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                          if (_note.isChecklist)
                            ChecklistEditor(
                              note: _note,
                              onChanged: () => setState(() {}),
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _blocks.asMap().entries.map((entry) {
                                final index = entry.key;
                                final block = entry.value;

                                if (block is String) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: block.startsWith('http')
                                              ? CachedNetworkImage(
                                                  imageUrl: block,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                )
                                              : Image.file(
                                                  File(block),
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: IconButton.filled(
                                            icon: const Icon(Icons.close, size: 18),
                                            onPressed: () {
                                              setState(() {
                                                _blocks.removeAt(index);
                                              });
                                            },
                                            style: IconButton.styleFrom(
                                              backgroundColor: Colors.black.withValues(alpha: 0.5),
                                              foregroundColor: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                } else if (block is TextEditingController) {
                                  return Focus(
                                    onFocusChange: (hasFocus) {
                                      if (hasFocus) _focusedBlockIndex = index;
                                    },
                                    child: TextField(
                                      controller: block,
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            height: 1.55,
                                          ),
                                      decoration: InputDecoration(
                                        hintText: index == 0 ? 'Note' : '',
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                      maxLines: null,
                                      keyboardType: TextInputType.multiline,
                                      textCapitalization: TextCapitalization.sentences,
                                    ),
                                  );
                                }
                                return const SizedBox();
                              }).toList(),
                            ),
                          const SizedBox(height: 16),
                          Text(
                            AppDateUtils.formatEditedTime(_note.updatedAt),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withValues(alpha: 0.40),
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  EditorBottomBar(
                    note: _note,
                    onColorTap: _showColorPicker,
                    onUndo: null,
                    onRedo: null,
                    onAddTap: _showAddMenu,
                    onMoreTap: _showMoreMenu,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
