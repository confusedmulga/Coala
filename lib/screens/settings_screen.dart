import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:koala/providers/settings_provider.dart';
import 'package:koala/utils/constants.dart';
import 'package:koala/widgets/gradient_background.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(AppStrings.settings),
        ),
        body: ListView(
          children: [
            _sectionHeader(context, 'Display options'),
            ListTile(
              title: const Text('Add new items to'),
              subtitle: Text(settingsProvider.addNewToTop ? 'Top' : 'Bottom'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Add new items to'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RadioListTile<bool>(
                          title: const Text('Top'),
                          value: true,
                          groupValue: settingsProvider.addNewToTop,
                          onChanged: (value) {
                            settingsProvider.setAddNewToTop(value!);
                            Navigator.pop(context);
                          },
                        ),
                        RadioListTile<bool>(
                          title: const Text('Bottom'),
                          value: false,
                          groupValue: settingsProvider.addNewToTop,
                          onChanged: (value) {
                            settingsProvider.setAddNewToTop(value!);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SwitchListTile(
              title: const Text('Move checked items to bottom'),
              value: settingsProvider.moveCheckedToBottom,
              onChanged: (value) {
                settingsProvider.setMoveCheckedToBottom(value);
              },
            ),
            SwitchListTile(
              title: const Text('Display checked items'),
              value: settingsProvider.showCheckedItems,
              onChanged: (value) {
                settingsProvider.setShowCheckedItems(value);
              },
            ),
            const Divider(),
            _sectionHeader(context, 'Theme'),
            ListTile(
              title: const Text('Theme'),
              subtitle: Text(_getThemeName(settingsProvider.themeMode)),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Choose theme'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RadioListTile<ThemeMode>(
                          title: const Text('Light'),
                          value: ThemeMode.light,
                          groupValue: settingsProvider.themeMode,
                          onChanged: (value) {
                            settingsProvider.setThemeMode(value!);
                            Navigator.pop(context);
                          },
                        ),
                        RadioListTile<ThemeMode>(
                          title: const Text('Dark'),
                          value: ThemeMode.dark,
                          groupValue: settingsProvider.themeMode,
                          onChanged: (value) {
                            settingsProvider.setThemeMode(value!);
                            Navigator.pop(context);
                          },
                        ),
                        RadioListTile<ThemeMode>(
                          title: const Text('System default'),
                          value: ThemeMode.system,
                          groupValue: settingsProvider.themeMode,
                          onChanged: (value) {
                            settingsProvider.setThemeMode(value!);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const Divider(),
            _sectionHeader(context, 'Sharing'),
            const ListTile(
              title: Text('Enable sharing'),
              subtitle: Text('Coming soon'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System default';
    }
  }
}
