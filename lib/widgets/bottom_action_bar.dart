import 'package:flutter/material.dart';
import 'package:koala/utils/constants.dart';
import 'package:koala/widgets/glass_container.dart';

/// Glass-morphism bottom action bar for the home screen.
/// Uses GlassContainer to blur content behind it.
class BottomActionBar extends StatelessWidget {
  final VoidCallback? onNewChecklist;

  const BottomActionBar({
    super.key,
    this.onNewChecklist,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: GlassContainer(
        borderRadius: 0,
        blurSigma: 28,
        addSpecularSheen: false,
        height: AppDimensions.bottomBarHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            children: [
              _glassIconButton(
                context,
                icon: Icons.check_box_outlined,
                tooltip: 'New list',
                onPressed: onNewChecklist,
              ),
              _glassIconButton(
                context,
                icon: Icons.brush_outlined,
                tooltip: 'New drawing',
                onPressed: () => _showComingSoon(context),
              ),
              _glassIconButton(
                context,
                icon: Icons.mic_none_outlined,
                tooltip: 'New audio note',
                onPressed: () => _showComingSoon(context),
              ),
              _glassIconButton(
                context,
                icon: Icons.image_outlined,
                tooltip: 'New image note',
                onPressed: () => _showComingSoon(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassIconButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    VoidCallback? onPressed,
  }) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        foregroundColor:
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
