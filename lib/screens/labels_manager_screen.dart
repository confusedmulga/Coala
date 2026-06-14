import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:koala/providers/labels_provider.dart';
import 'package:koala/utils/constants.dart';
import 'package:koala/widgets/gradient_background.dart';

class LabelsManagerScreen extends StatefulWidget {
  const LabelsManagerScreen({super.key});

  @override
  State<LabelsManagerScreen> createState() => _LabelsManagerScreenState();
}

class _LabelsManagerScreenState extends State<LabelsManagerScreen> {
  final TextEditingController _newLabelController = TextEditingController();

  @override
  void dispose() {
    _newLabelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labelsProvider = context.watch<LabelsProvider>();

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(AppStrings.editLabels),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.add, color: Colors.grey),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _newLabelController,
                      decoration: const InputDecoration(
                        hintText: AppStrings.newLabel,
                        border: InputBorder.none,
                      ),
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          labelsProvider.createLabel(value);
                          _newLabelController.clear();
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () {
                      if (_newLabelController.text.isNotEmpty) {
                        labelsProvider.createLabel(_newLabelController.text);
                        _newLabelController.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: labelsProvider.labels.length,
                itemBuilder: (context, index) {
                  final label = labelsProvider.labels[index];
                  return ListTile(
                    leading: const Icon(Icons.label_outline),
                    title: TextFormField(
                      initialValue: label.name,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                      onFieldSubmitted: (value) {
                        if (value.isNotEmpty) {
                          label.name = value;
                          labelsProvider.updateLabel(label);
                        }
                      },
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text(AppStrings.deleteLabel),
                            content: Text("Delete label '${label.name}'?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('CANCEL'),
                              ),
                              TextButton(
                                onPressed: () {
                                  labelsProvider.deleteLabel(label.id);
                                  Navigator.pop(context);
                                },
                                child: const Text('DELETE'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
