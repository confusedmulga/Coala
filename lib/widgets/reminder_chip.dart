import 'package:flutter/material.dart';
import 'package:koala/utils/constants.dart';
import 'package:koala/utils/date_utils.dart';

/// A chip displaying a reminder date/time with a bell icon.
/// Past-due reminders are shown with dimmed, strikethrough text.
class ReminderChip extends StatelessWidget {
  final DateTime? reminderTime;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const ReminderChip({
    super.key,
    required this.reminderTime,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (reminderTime == null) return const SizedBox.shrink();

    final isPastDue = AppDateUtils.isPastDue(reminderTime!);
    final contentColor = isPastDue
        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: AppDimensions.chipHeight,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.chipBorderRadius),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_outlined, size: 14, color: contentColor),
            const SizedBox(width: 4),
            Text(
              AppDateUtils.formatReminder(reminderTime!),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: contentColor,
                    decoration:
                        isPastDue ? TextDecoration.lineThrough : null,
                  ),
            ),
            if (onDismiss != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDismiss,
                child: Icon(Icons.close, size: 14, color: contentColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
