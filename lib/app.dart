import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:koala/providers/settings_provider.dart';
import 'package:koala/screens/home_screen.dart';
import 'package:koala/screens/search_screen.dart';
import 'package:koala/screens/archive_screen.dart';
import 'package:koala/screens/trash_screen.dart';
import 'package:koala/screens/label_screen.dart';
import 'package:koala/screens/reminders_screen.dart';
import 'package:koala/screens/labels_manager_screen.dart';
import 'package:koala/screens/settings_screen.dart';
import 'package:koala/screens/note_editor_screen.dart';

/// Root MaterialApp widget with Material 3 theming tuned for liquid-glass UI.
class KoalaApp extends StatelessWidget {
  const KoalaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'Coala',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/search': (context) => const SearchScreen(),
        '/archive': (context) => const ArchiveScreen(),
        '/trash': (context) => const TrashScreen(),
        '/reminders': (context) => const RemindersScreen(),
        '/labels-manager': (context) => const LabelsManagerScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
      onGenerateRoute: (routeSettings) {
        if (routeSettings.name == '/editor') {
          return MaterialPageRoute(
            builder: (context) => const NoteEditorScreen(),
            settings: routeSettings,
          );
        }
        if (routeSettings.name == '/label') {
          final args = routeSettings.arguments as Map<String, String>;
          return MaterialPageRoute(
            builder: (context) => LabelScreen(
              labelId: args['id']!,
              labelName: args['name']!,
            ),
            settings: routeSettings,
          );
        }
        return null;
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFFBBC05),
      brightness: brightness,
    );

    final textTheme = GoogleFonts.interTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      // Transparent scaffold — gradient is applied per-screen
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: null, // inherits from colorScheme
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: isDark
            ? const Color(0xFF1C1C2E).withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.75),
        elevation: 0,
      ),
      // Cards: fully transparent — NoteCard uses GlassContainer
      cardTheme: const CardThemeData(
        elevation: 0,
        color: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark
            ? const Color(0xFF394457).withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.80),
        foregroundColor: isDark ? const Color(0xFFD3E3FD) : const Color(0xFF041E49),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.60),
            width: 1.2,
          ),
        ),
      ),
      bottomAppBarTheme: const BottomAppBarThemeData(
        color: Colors.transparent,
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.20)
              : Colors.black.withValues(alpha: 0.12),
        ),
        labelStyle: textTheme.labelSmall,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark
            ? const Color(0xFF303030).withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.95),
        contentTextStyle: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF202124),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark
            ? const Color(0xFF1E1E2E).withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.92),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
      ),
    );
  }
}
