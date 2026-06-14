import 'package:intl/intl.dart';

/// Friendly date/time formatting utilities matching Google Keep style.
class AppDateUtils {
  AppDateUtils._();

  /// Format a reminder time in a user-friendly way.
  /// Examples: "Today, 8:00 AM", "Tomorrow, 3:00 PM", "Mon, Jun 15, 8:00 AM"
  static String formatReminder(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final noteDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final timeStr = DateFormat.jm().format(dateTime);

    if (noteDate == today) {
      return 'Today, $timeStr';
    } else if (noteDate == tomorrow) {
      return 'Tomorrow, $timeStr';
    } else if (noteDate.year == now.year) {
      return '${DateFormat('EEE, MMM d').format(dateTime)}, $timeStr';
    } else {
      return '${DateFormat('EEE, MMM d, y').format(dateTime)}, $timeStr';
    }
  }

  /// Format "Edited <time>" string for the note editor.
  static String formatEditedTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Edited just now';
    } else if (diff.inHours < 1) {
      return 'Edited ${diff.inMinutes} min ago';
    } else if (diff.inDays < 1) {
      return 'Edited ${DateFormat.jm().format(dateTime)}';
    } else if (diff.inDays < 7) {
      return 'Edited ${DateFormat('EEE').format(dateTime)} ${DateFormat.jm().format(dateTime)}';
    } else {
      return 'Edited ${DateFormat('MMM d').format(dateTime)}';
    }
  }

  /// Check if a reminder is past due.
  static bool isPastDue(DateTime reminderTime) {
    return reminderTime.isBefore(DateTime.now());
  }

  /// Check if a trashed note should be auto-purged (7 days).
  static bool shouldPurge(DateTime trashedAt) {
    return DateTime.now().difference(trashedAt).inDays >= 7;
  }
}
