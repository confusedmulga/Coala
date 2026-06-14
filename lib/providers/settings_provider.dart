import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider managing app-wide settings — theme, view mode.
class SettingsProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _viewModeKey = 'view_mode';
  static const String _addNewToTopKey = 'add_new_to_top';
  static const String _moveCheckedToBottomKey = 'move_checked_to_bottom';
  static const String _showCheckedItemsKey = 'show_checked_items';

  ThemeMode _themeMode = ThemeMode.system;
  bool _isGridView = true;
  bool _addNewToTop = true;
  bool _moveCheckedToBottom = true;
  bool _showCheckedItems = true;

  ThemeMode get themeMode => _themeMode;
  bool get isGridView => _isGridView;
  bool get addNewToTop => _addNewToTop;
  bool get moveCheckedToBottom => _moveCheckedToBottom;
  bool get showCheckedItems => _showCheckedItems;

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final themeIndex = prefs.getInt(_themeKey) ?? 0;
    _themeMode = ThemeMode.values[themeIndex];

    _isGridView = prefs.getBool(_viewModeKey) ?? true;
    _addNewToTop = prefs.getBool(_addNewToTopKey) ?? true;
    _moveCheckedToBottom = prefs.getBool(_moveCheckedToBottomKey) ?? true;
    _showCheckedItems = prefs.getBool(_showCheckedItemsKey) ?? true;

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
    notifyListeners();
  }

  Future<void> toggleViewMode() async {
    _isGridView = !_isGridView;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_viewModeKey, _isGridView);
    notifyListeners();
  }

  Future<void> setAddNewToTop(bool value) async {
    _addNewToTop = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_addNewToTopKey, value);
    notifyListeners();
  }

  Future<void> setMoveCheckedToBottom(bool value) async {
    _moveCheckedToBottom = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_moveCheckedToBottomKey, value);
    notifyListeners();
  }

  Future<void> setShowCheckedItems(bool value) async {
    _showCheckedItems = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showCheckedItemsKey, value);
    notifyListeners();
  }
}
