import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:koala/app.dart';
import 'package:koala/providers/notes_provider.dart';
import 'package:koala/providers/labels_provider.dart';
import 'package:koala/providers/settings_provider.dart';
import 'package:koala/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service
  await NotificationService().initialize();

  // Create providers and load initial data
  final notesProvider = NotesProvider();
  final labelsProvider = LabelsProvider();
  final settingsProvider = SettingsProvider();

  await Future.wait([
    notesProvider.loadNotes(),
    labelsProvider.loadLabels(),
    settingsProvider.loadSettings(),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: notesProvider),
        ChangeNotifierProvider.value(value: labelsProvider),
        ChangeNotifierProvider.value(value: settingsProvider),
      ],
      child: const KoalaApp(),
    ),
  );
}
