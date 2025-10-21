import 'package:flutter/material.dart';

/// Maps legacy Horizon App named colors to hex codes
/// This ensures compatibility with events created in the original web app
class ColorMapper {
  static final Map<String, String> _colorMap = {
    'cerulean': '#6f97b8',
    'grape': '#806d8c',
    'turquoise': '#83b7b8',
    'green': '#90a583',
    'wildfire': '#d4a373',
    'rose': '#c8a5b3',
    'brick': '#a39088',
    'chrome': '#d5d5d5',
    'orange': '#deb168',
    'coral': '#bc8a8d',
    'slate': '#8994a1',
    'stone': '#a8a196',
  };

  /// Converts a color string (named or hex) to a Color object
  /// Handles both legacy named colors and hex codes
  static Color parseColor(String colorString) {
    try {
      // Check if it's a named color first
      final hexColor = _colorMap[colorString.toLowerCase()];
      if (hexColor != null) {
        return _hexToColor(hexColor);
      }

      // If not a named color, try parsing as hex
      return _hexToColor(colorString);
    } catch (e) {
      // Default fallback color
      return const Color(0xFF3B82F6); // Blue
    }
  }

  /// Converts hex string to Color
  static Color _hexToColor(String hexString) {
    String hex = hexString.replaceAll('#', '');

    // Add alpha if not present
    if (hex.length == 6) {
      hex = 'FF$hex';
    }

    return Color(int.parse(hex, radix: 16));
  }

  /// Converts hex code back to named color if it matches
  /// Useful for displaying color names in UI
  static String? hexToNamedColor(String hexString) {
    final normalizedHex = hexString.toLowerCase().replaceAll('#', '');

    for (final entry in _colorMap.entries) {
      final mapHex = entry.value.toLowerCase().replaceAll('#', '');
      if (mapHex == normalizedHex) {
        return entry.key;
      }
    }

    return null; // Not a named color
  }
}
