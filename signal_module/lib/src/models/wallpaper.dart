import 'package:flutter/material.dart';

/// Represents a chat wallpaper option
sealed class Wallpaper {
  const Wallpaper({required this.id, required this.name});

  final String id;
  final String name;
}

/// A solid color wallpaper
class SolidColorWallpaper extends Wallpaper {
  const SolidColorWallpaper({
    required super.id,
    required super.name,
    required this.color,
  });

  final Color color;
}

/// A gradient wallpaper
class GradientWallpaper extends Wallpaper {
  const GradientWallpaper({
    required super.id,
    required super.name,
    required this.colors,
    this.angle = 0,
  });

  final List<Color> colors;
  final double angle;

  LinearGradient get gradient => LinearGradient(
    colors: colors,
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    transform: GradientRotation(angle * 3.14159 / 180),
  );
}

/// An image wallpaper
class ImageWallpaper extends Wallpaper {
  const ImageWallpaper({
    required super.id,
    required super.name,
    required this.imagePath,
    this.isAsset = true,
  });

  final String imagePath;
  final bool isAsset;
}

/// Preset wallpapers available in Signal
class PresetWallpapers {
  PresetWallpapers._();

  static const List<Wallpaper> all = [
    // Solid colors
    SolidColorWallpaper(
      id: 'solid_blush',
      name: 'Blush',
      color: Color(0xFFF3E2DB),
    ),
    SolidColorWallpaper(
      id: 'solid_copper',
      name: 'Copper',
      color: Color(0xFFE4C9A8),
    ),
    SolidColorWallpaper(
      id: 'solid_dust',
      name: 'Dust',
      color: Color(0xFFD6D4D2),
    ),
    SolidColorWallpaper(
      id: 'solid_celadon',
      name: 'Celadon',
      color: Color(0xFFCFE4CF),
    ),
    SolidColorWallpaper(
      id: 'solid_rainforest',
      name: 'Rainforest',
      color: Color(0xFF354A37),
    ),
    SolidColorWallpaper(
      id: 'solid_pacific',
      name: 'Pacific',
      color: Color(0xFF203E5B),
    ),
    SolidColorWallpaper(
      id: 'solid_frost',
      name: 'Frost',
      color: Color(0xFFD4E3F0),
    ),
    SolidColorWallpaper(
      id: 'solid_navy',
      name: 'Navy',
      color: Color(0xFF1B2C4B),
    ),
    SolidColorWallpaper(
      id: 'solid_lilac',
      name: 'Lilac',
      color: Color(0xFFE6DEF0),
    ),
    SolidColorWallpaper(
      id: 'solid_pink',
      name: 'Pink',
      color: Color(0xFFF2D9E7),
    ),
    SolidColorWallpaper(
      id: 'solid_eggplant',
      name: 'Eggplant',
      color: Color(0xFF422C48),
    ),
    SolidColorWallpaper(
      id: 'solid_silver',
      name: 'Silver',
      color: Color(0xFF6B7D8E),
    ),

    // Gradients
    GradientWallpaper(
      id: 'gradient_sunset',
      name: 'Sunset',
      colors: [Color(0xFFE76F51), Color(0xFFF4A261)],
    ),
    GradientWallpaper(
      id: 'gradient_noir',
      name: 'Noir',
      colors: [Color(0xFF2B2D42), Color(0xFF8D99AE)],
    ),
    GradientWallpaper(
      id: 'gradient_heatmap',
      name: 'Heatmap',
      colors: [Color(0xFF9B2226), Color(0xFFBB3E03), Color(0xFFCA6702)],
    ),
    GradientWallpaper(
      id: 'gradient_aqua',
      name: 'Aqua',
      colors: [Color(0xFF0077B6), Color(0xFF00B4D8), Color(0xFF90E0EF)],
    ),
    GradientWallpaper(
      id: 'gradient_iridescent',
      name: 'Iridescent',
      colors: [
        Color(0xFFF72585),
        Color(0xFF7209B7),
        Color(0xFF3A0CA3),
        Color(0xFF4361EE),
      ],
    ),
    GradientWallpaper(
      id: 'gradient_monstera',
      name: 'Monstera',
      colors: [Color(0xFF2D6A4F), Color(0xFF40916C), Color(0xFF74C69D)],
    ),
  ];

  static Wallpaper? byId(String id) {
    return all.where((w) => w.id == id).firstOrNull;
  }
}
