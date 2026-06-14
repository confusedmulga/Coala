import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:koala/providers/settings_provider.dart';
import 'package:koala/utils/constants.dart';
import 'package:koala/widgets/glass_container.dart';

/// Pill-shaped frosted-glass search bar for the home screen.
class KeepSearchBar extends StatelessWidget {
  const KeepSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: GlassContainer(
        borderRadius: AppDimensions.searchBarBorderRadius,
        blurSigma: 28,
        tintOpacity: 0.45,
        borderOpacity: 0.40,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.searchBarBorderRadius),
          onTap: () {
            Navigator.pushNamed(context, '/search');
          },
          child: SizedBox(
            height: AppDimensions.searchBarHeight,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.menu,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.70),
                  ),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      AppStrings.searchHint,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.45),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    settingsProvider.isGridView
                        ? Icons.view_agenda_outlined
                        : Icons.grid_view,
                  ),
                  onPressed: () {
                    settingsProvider.toggleViewMode();
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(
                            alpha: isDark ? 0.15 : 0.50,
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(
                              alpha: isDark ? 0.25 : 0.60,
                            ),
                            width: 0.8,
                          ),
                        ),
                        child: Icon(
                          Icons.person,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
