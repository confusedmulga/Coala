import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:koala/models/note.dart';
import 'dart:io';
import 'package:koala/models/note_color.dart';
import 'package:koala/providers/notes_provider.dart';
import 'package:koala/providers/labels_provider.dart';
import 'package:koala/utils/constants.dart';
import 'package:koala/utils/date_utils.dart';
import 'package:koala/widgets/glass_container.dart';

// Cache to avoid re-generating palettes during scroll
final Map<String, Color> _textColorCache = {};

/// A premium card for grid/list layout.
/// Supports both clear image cards with dynamic text contrast and 
/// frosted glassmorphism text cards.
class NoteCard extends StatefulWidget {
  final Note note;
  final VoidCallback? onTap;

  const NoteCard({
    super.key,
    required this.note,
    this.onTap,
  });

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  Color? _dynamicTextColor;

  @override
  void initState() {
    super.initState();
    _extractColor();
  }

  @override
  void didUpdateWidget(NoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note.imageUrl != widget.note.imageUrl) {
      _extractColor();
    }
  }

  Future<void> _extractColor() async {
    final imageUrl = widget.note.imageUrl;
    if (imageUrl == null || imageUrl.isEmpty) return;

    if (_textColorCache.containsKey(imageUrl)) {
      if (mounted) {
        setState(() {
          _dynamicTextColor = _textColorCache[imageUrl];
        });
      }
      return;
    }

    try {
      final isNetwork = imageUrl.startsWith('http');
      final imageProvider = isNetwork 
          ? CachedNetworkImageProvider(imageUrl) as ImageProvider
          : FileImage(File(imageUrl)) as ImageProvider;

      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        imageProvider,
        // Focus on the top region where the title usually sits
        region: const Rect.fromLTWH(0, 0, 300, 150),
        maximumColorCount: 10,
      );

      final dominantColor = paletteGenerator.dominantColor?.color ?? Colors.grey;
      // If the dominant color behind the text is light, use dark text. Otherwise use white.
      final textColor = dominantColor.computeLuminance() > 0.45 ? Colors.black87 : Colors.white;

      _textColorCache[imageUrl] = textColor;

      if (mounted) {
        setState(() {
          _dynamicTextColor = textColor;
        });
      }
    } catch (e) {
      // Fallback
      if (mounted) {
        setState(() {
          _dynamicTextColor = Colors.white;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final isSelected = notesProvider.selectedNoteIds.contains(widget.note.id);
    final isSelectionMode = notesProvider.isSelectionMode;
    final hasImage = widget.note.imageUrl != null && widget.note.imageUrl!.isNotEmpty;
    final selectedBorderColor = Theme.of(context).colorScheme.primary;

    return Hero(
      tag: 'note-${widget.note.id}',
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () {
            if (isSelectionMode) {
              notesProvider.toggleSelection(widget.note.id);
            } else if (widget.onTap != null) {
              widget.onTap!.call();
            } else {
              Navigator.pushNamed(context, '/editor', arguments: widget.note);
            }
          },
          onLongPress: () {
            notesProvider.startSelection(widget.note.id);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
              border: isSelected
                  ? Border.all(color: selectedBorderColor, width: 2.5)
                  : null,
              boxShadow: _buildCardShadow(isSelected),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius - (isSelected ? 2.5 : 0)),
              child: Stack(
                children: [
                  if (hasImage) _buildImageCard(context) else _buildTextCard(context),
                  if (isSelected) _buildSelectionOverlay(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<BoxShadow> _buildCardShadow(bool isSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedBorderColor = Theme.of(context).colorScheme.primary;

    if (isSelected) {
      return [
        BoxShadow(
          color: selectedBorderColor.withValues(alpha: 0.25),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ];
    }
    
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.30),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];
    }
    
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 20,
        spreadRadius: -2,
        offset: const Offset(0, 8),
      ),
    ];
  }

  Widget _buildImageCard(BuildContext context) {
    final labelsProvider = context.read<LabelsProvider>();
    final textColor = _dynamicTextColor ?? Colors.white;
    // Add subtle shadow to text only if it's white to help with readability on mixed backgrounds
    final textShadows = textColor == Colors.white 
        ? [Shadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 4, offset: const Offset(0, 1))]
        : null;

    return Stack(
      children: [
        // Image Background
        Positioned.fill(
          child: widget.note.imageUrl!.startsWith('http')
              ? CachedNetworkImage(
                  imageUrl: widget.note.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                )
              : Image.file(
                  File(widget.note.imageUrl!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
        ),
        // Subtle gradient scrims for readability
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.15),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.35), // Darker at bottom for chips
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
        ),
        // Content
        Padding(
          padding: const EdgeInsets.all(18.0),
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.note.title.isNotEmpty)
                  Text(
                    widget.note.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: textColor,
                      shadows: textShadows,
                      height: 1.2,
                    ),
                  ),
                if (widget.note.contentPreview.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.note.contentPreview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textColor.withValues(alpha: 0.85),
                      shadows: textShadows,
                      height: 1.3,
                    ),
                  ),
                ],
                // Push chips to the bottom if this is part of a tall card
                // We use a SizedBox to give image cards some minimum height
                const SizedBox(height: 60), 
                if (widget.note.reminderTime != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: _buildReminderChip(context, isImageCard: true),
                  ),
                if (widget.note.labelIds.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: _buildLabelChips(context, labelsProvider, isImageCard: true),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextCard(BuildContext context) {
    final labelsProvider = context.read<LabelsProvider>();
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final noteColorObj = NoteColor.fromIndex(widget.note.colorIndex);
    final hasCustomColor = widget.note.colorIndex != 0;
    final rawNoteColor = hasCustomColor ? noteColorObj.getColor(brightness) : null;

    final tintColor = hasCustomColor
        ? rawNoteColor!.withValues(alpha: isDark ? 0.25 : 0.40)
        : (isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.60));

    return GlassContainer(
      borderRadius: AppDimensions.cardBorderRadius,
      blurSigma: 24,
      tintColor: tintColor,
      tintOpacity: isDark ? 0.08 : 0.65,
      borderOpacity: isDark ? 0.10 : 0.50,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.note.title.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    widget.note.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      height: 1.2,
                    ),
                  ),
                ),
              if (widget.note.isChecklist)
                _buildChecklistPreview(context)
              else if (widget.note.contentPreview.isNotEmpty)
                Text(
                  widget.note.contentPreview,
                  maxLines: 8,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
              if (widget.note.reminderTime != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: _buildReminderChip(context),
                ),
              if (widget.note.labelIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: _buildLabelChips(context, labelsProvider),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistPreview(BuildContext context) {
    final unchecked = widget.note.checklistItems.where((item) => !item.isChecked).toList();
    final checked = widget.note.checklistItems.where((item) => item.isChecked).toList();
    final displayItems = unchecked.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...displayItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_box_outline_blank_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.50),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            )),
        if (unchecked.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              '+${unchecked.length - 5} more items',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.50),
              ),
            ),
          ),
        if (checked.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              '✓ ${checked.length} ${AppStrings.checkedItems}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.50),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReminderChip(BuildContext context, {bool isImageCard = false}) {
    final isPastDue = AppDateUtils.isPastDue(widget.note.reminderTime!);
    final baseColor = isImageCard ? Colors.white : Theme.of(context).colorScheme.onSurface;
    final textColor = isPastDue
        ? baseColor.withValues(alpha: 0.45)
        : baseColor.withValues(alpha: 0.85);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isImageCard 
            ? Colors.black.withValues(alpha: 0.3)
            : Theme.of(context).colorScheme.surface.withValues(alpha: 0.4),
        border: Border.all(
          color: isImageCard
              ? Colors.white.withValues(alpha: 0.2)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_outlined, size: 14, color: textColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              AppDateUtils.formatReminder(widget.note.reminderTime!),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
                decoration: isPastDue ? TextDecoration.lineThrough : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelChips(BuildContext context, LabelsProvider labelsProvider, {bool isImageCard = false}) {
    final visibleLabels = widget.note.labelIds.take(2).toList();
    final overflowCount = widget.note.labelIds.length - visibleLabels.length;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...visibleLabels.map((labelId) {
          final name = labelsProvider.getLabelName(labelId);
          if (name.isEmpty) return const SizedBox.shrink();
          return _labelChip(context, name, isImageCard: isImageCard);
        }),
        if (overflowCount > 0) _labelChip(context, '+$overflowCount', isImageCard: isImageCard),
      ],
    );
  }

  Widget _labelChip(BuildContext context, String text, {bool isImageCard = false}) {
    final textColor = isImageCard ? Colors.white.withValues(alpha: 0.9) : Theme.of(context).colorScheme.onSurface;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isImageCard 
            ? Colors.black.withValues(alpha: 0.3)
            : Theme.of(context).colorScheme.surface.withValues(alpha: 0.4),
        border: Border.all(
          color: isImageCard
              ? Colors.white.withValues(alpha: 0.2)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildSelectionOverlay(BuildContext context) {
    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.check,
          size: 18,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }
}
