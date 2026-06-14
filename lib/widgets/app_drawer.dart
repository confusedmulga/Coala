import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:koala/providers/labels_provider.dart';
import 'package:koala/utils/constants.dart';
import 'package:koala/widgets/glass_container.dart';

/// Liquid-glass side navigation drawer (iOS 26 style).
class AppDrawer extends StatelessWidget {
  final String selectedRoute;

  const AppDrawer({
    super.key,
    required this.selectedRoute,
  });

  @override
  Widget build(BuildContext context) {
    final labelsProvider = context.watch<LabelsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // --- Border radii ---
    const borderRadius =
        BorderRadius.horizontal(right: Radius.circular(28));

    // --- Outer border (bright highlight) ---
    final outerBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.white.withValues(alpha: 0.50);

    // --- Inner border (subtle glow) ---
    final innerBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.22);

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 36, sigmaY: 36),
        child: Container(
          width: AppDimensions.drawerWidth,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            // More translucent glass fill
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Colors.white.withValues(alpha: 0.06),
                      Colors.white.withValues(alpha: 0.02),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.30),
                      Colors.white.withValues(alpha: 0.08),
                    ],
            ),
            // Outer bright border on the right edge
            border: Border(
              right: BorderSide(
                color: outerBorderColor,
                width: 1.5,
              ),
              top: BorderSide(
                color: outerBorderColor,
                width: 0.5,
              ),
              bottom: BorderSide(
                color: outerBorderColor,
                width: 0.5,
              ),
            ),
          ),
          child: Stack(
            children: [
              // --- Fresnel edge brightening overlay ---
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: borderRadius,
                      border: Border.all(
                        color: innerBorderColor,
                        width: 1.0,
                      ),
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.2,
                        colors: isDark
                            ? [
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.04),
                              ]
                            : [
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.12),
                              ],
                        stops: const [0.3, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              // --- Specular highlight blob (top-left) ---
              Positioned(
                top: -12,
                left: -12,
                child: IgnorePointer(
                  child: Container(
                    width: 140,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(70),
                      gradient: RadialGradient(
                        center: Alignment.topLeft,
                        radius: 1.5,
                        colors: isDark
                            ? [
                                Colors.white.withValues(alpha: 0.08),
                                Colors.transparent,
                              ]
                            : [
                                Colors.white.withValues(alpha: 0.38),
                                Colors.transparent,
                              ],
                      ),
                    ),
                  ),
                ),
              ),
              // --- Actual content ---
              SafeArea(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // App title / header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                      child: Row(
                        children: [
                          _buildGlassIcon(context, isDark),
                          const SizedBox(width: 12),
                          Text(
                            AppStrings.appName,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                          ),
                        ],
                      ),
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.lightbulb_outline,
                      title: AppStrings.notes,
                      route: '/',
                      isSelected: selectedRoute == '/',
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.notifications_none,
                      title: AppStrings.reminders,
                      route: '/reminders',
                      isSelected: selectedRoute == '/reminders',
                    ),
                    if (labelsProvider.labels.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        child: Row(
                          children: [
                            Text(
                              AppStrings.labels.toUpperCase(),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    letterSpacing: 1.0,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.55),
                                  ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pushNamedAndRemoveUntil(context,
                                    '/labels-manager', (route) => route.isFirst);
                              },
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('EDIT'),
                            ),
                          ],
                        ),
                      ),
                      ...labelsProvider.labels.map((label) =>
                          _buildDrawerItem(
                            context,
                            icon: Icons.label_outline,
                            title: label.name,
                            route: '/label',
                            arguments: {'id': label.id, 'name': label.name},
                            isSelected:
                                selectedRoute == 'label_${label.id}',
                          )),
                    ],
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Divider(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.12),
                        thickness: 0.8,
                      ),
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.edit_outlined,
                      title: AppStrings.editLabels,
                      route: '/labels-manager',
                      isSelected: selectedRoute == '/labels-manager',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Divider(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.12),
                        thickness: 0.8,
                      ),
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.archive_outlined,
                      title: AppStrings.archive,
                      route: '/archive',
                      isSelected: selectedRoute == '/archive',
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.delete_outline,
                      title: AppStrings.trash,
                      route: '/trash',
                      isSelected: selectedRoute == '/trash',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Divider(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.12),
                        thickness: 0.8,
                      ),
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.settings_outlined,
                      title: AppStrings.settings,
                      route: '/settings',
                      isSelected: selectedRoute == '/settings',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Glass-circle Coala icon in the header.
  Widget _buildGlassIcon(BuildContext context, bool isDark) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Semi-transparent fill instead of a solid gradient
        color: isDark
            ? Colors.white.withValues(alpha: 0.10)
            : Colors.white.withValues(alpha: 0.40),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.20)
              : Colors.white.withValues(alpha: 0.55),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: isDark ? 0.25 : 0.18),
            blurRadius: 10,
            spreadRadius: -1,
          ),
        ],
      ),
      child: Icon(
        Icons.eco,
        color: Theme.of(context).colorScheme.primary,
        size: 20,
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    Map<String, String>? arguments,
    required bool isSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget itemContent = ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? colorScheme.primary
            : colorScheme.onSurface.withValues(alpha: 0.65),
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.onSurface.withValues(alpha: 0.85),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          fontSize: 14,
          letterSpacing: -0.1,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      dense: true,
      onTap: () {
        Navigator.pop(context);
        if (!isSelected) {
          if (route == '/') {
            Navigator.popUntil(context, (r) => r.isFirst);
          } else {
            if (arguments != null) {
              Navigator.pushNamedAndRemoveUntil(
                  context, route, (r) => r.isFirst,
                  arguments: arguments);
            } else {
              Navigator.pushNamedAndRemoveUntil(
                  context, route, (r) => r.isFirst);
            }
          }
        }
      },
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: isSelected
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                // Subtle glass overlay instead of opaque gradient
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.35),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.14)
                      : Colors.white.withValues(alpha: 0.50),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(
                        alpha: isDark ? 0.18 : 0.10),
                    blurRadius: 8,
                    spreadRadius: -2,
                    offset: const Offset(0, 2),
                  ),
                ],
              )
            : null,
        child: isSelected
            ? ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: itemContent,
                ),
              )
            : itemContent,
      ),
    );
  }
}
