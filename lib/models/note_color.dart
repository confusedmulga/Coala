import 'package:flutter/material.dart';

/// Google Keep note color palette — 12 colors + default
/// Each color has a light and dark mode variant.
class NoteColor {
  final int index;
  final String name;
  final Color lightColor;
  final Color darkColor;

  const NoteColor({
    required this.index,
    required this.name,
    required this.lightColor,
    required this.darkColor,
  });

  Color getColor(Brightness brightness) {
    return brightness == Brightness.light ? lightColor : darkColor;
  }

  static const List<NoteColor> colors = [
    NoteColor(
      index: 0,
      name: 'Default',
      lightColor: Color(0xFFFFFFFF),
      darkColor: Color(0xFF202124),
    ),
    NoteColor(
      index: 1,
      name: 'Coral',
      lightColor: Color(0xFFFAAFA8),
      darkColor: Color(0xFF77172E),
    ),
    NoteColor(
      index: 2,
      name: 'Peach',
      lightColor: Color(0xFFF39F76),
      darkColor: Color(0xFF692B17),
    ),
    NoteColor(
      index: 3,
      name: 'Sand',
      lightColor: Color(0xFFFFF8B8),
      darkColor: Color(0xFF7C4A03),
    ),
    NoteColor(
      index: 4,
      name: 'Mint',
      lightColor: Color(0xFFE2F6D3),
      darkColor: Color(0xFF264D3B),
    ),
    NoteColor(
      index: 5,
      name: 'Sage',
      lightColor: Color(0xFFB4DDD3),
      darkColor: Color(0xFF0C625D),
    ),
    NoteColor(
      index: 6,
      name: 'Fog',
      lightColor: Color(0xFFD3E4EC),
      darkColor: Color(0xFF256377),
    ),
    NoteColor(
      index: 7,
      name: 'Storm',
      lightColor: Color(0xFFAECCDC),
      darkColor: Color(0xFF284255),
    ),
    NoteColor(
      index: 8,
      name: 'Dusk',
      lightColor: Color(0xFFD3BFDB),
      darkColor: Color(0xFF472E5B),
    ),
    NoteColor(
      index: 9,
      name: 'Blossom',
      lightColor: Color(0xFFF6E2DD),
      darkColor: Color(0xFF6C394F),
    ),
    NoteColor(
      index: 10,
      name: 'Clay',
      lightColor: Color(0xFFE9E3D4),
      darkColor: Color(0xFF4B443A),
    ),
    NoteColor(
      index: 11,
      name: 'Chalk',
      lightColor: Color(0xFFEFEFF1),
      darkColor: Color(0xFF232427),
    ),
  ];

  static NoteColor fromIndex(int index) {
    if (index < 0 || index >= colors.length) return colors[0];
    return colors[index];
  }
}
