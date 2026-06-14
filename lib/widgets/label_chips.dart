import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:koala/providers/labels_provider.dart';
import 'package:koala/utils/constants.dart';

/// A row of small label pill chips for display on note cards.
/// Shows up to [maxVisible] labels with an overflow indicator.
class LabelChips extends StatelessWidget {
  final List<String> labelIds;
  final int maxVisible;

  const LabelChips({
    super.key,
    required this.labelIds,
    this.maxVisible = 3,
  });

  @override
  Widget build(BuildContext context) {
    if (labelIds.isEmpty) return const SizedBox.shrink();

    final labelsProvider = context.watch<LabelsProvider>();
    final visibleIds = labelIds.take(maxVisible).toList();
    final overflowCount = labelIds.length - visibleIds.length;

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        ...visibleIds.map((labelId) {
          final name = labelsProvider.getLabelName(labelId);
          if (name.isEmpty) return const SizedBox.shrink();
          return _LabelChip(label: name);
        }),
        if (overflowCount > 0) _LabelChip(label: '+$overflowCount'),
      ],
    );
  }
}

class _LabelChip extends StatelessWidget {
  final String label;

  const _LabelChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimensions.chipHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.chipBorderRadius),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
