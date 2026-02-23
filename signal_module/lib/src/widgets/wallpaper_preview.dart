import 'package:flutter/material.dart';

import '../models/wallpaper.dart';

/// Preview widget for a wallpaper option
class WallpaperPreview extends StatelessWidget {
  const WallpaperPreview({
    super.key,
    required this.wallpaper,
    this.isSelected = false,
    this.onTap,
    this.size = 80,
  });

  final Wallpaper wallpaper;
  final bool isSelected;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size * 1.6,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 3,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: _buildWallpaperContent(),
        ),
      ),
    );
  }

  Widget _buildWallpaperContent() {
    return switch (wallpaper) {
      SolidColorWallpaper(:final color) => Container(color: color),
      GradientWallpaper(:final gradient) => Container(
        decoration: BoxDecoration(gradient: gradient),
      ),
      ImageWallpaper(imagePath: final path, :final isAsset) =>
        isAsset
            ? Image.asset(path, fit: BoxFit.cover)
            : Image.network(path, fit: BoxFit.cover),
    };
  }
}

/// Grid of wallpaper options
class WallpaperGrid extends StatelessWidget {
  const WallpaperGrid({
    super.key,
    required this.wallpapers,
    this.selectedId,
    this.onSelect,
  });

  final List<Wallpaper> wallpapers;
  final String? selectedId;
  final void Function(Wallpaper)? onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.625,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: wallpapers.length,
      itemBuilder: (context, index) {
        final wallpaper = wallpapers[index];
        return WallpaperPreview(
          wallpaper: wallpaper,
          isSelected: wallpaper.id == selectedId,
          onTap: () => onSelect?.call(wallpaper),
        );
      },
    );
  }
}

/// Full-screen wallpaper background
class WallpaperBackground extends StatelessWidget {
  const WallpaperBackground({super.key, required this.wallpaper, this.child});

  final Wallpaper wallpaper;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return switch (wallpaper) {
      SolidColorWallpaper(:final color) => Container(
        color: color,
        child: child,
      ),
      GradientWallpaper(:final gradient) => Container(
        decoration: BoxDecoration(gradient: gradient),
        child: child,
      ),
      ImageWallpaper(imagePath: final path, :final isAsset) => Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: isAsset
                ? AssetImage(path) as ImageProvider
                : NetworkImage(path),
            fit: BoxFit.cover,
          ),
        ),
        child: child,
      ),
    };
  }
}
