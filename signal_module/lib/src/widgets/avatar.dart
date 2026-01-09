import 'package:flutter/material.dart';

import '../theme/signal_theme.dart';

/// Signal-style avatar widget
class SignalAvatar extends StatelessWidget {
  const SignalAvatar({
    super.key,
    required this.initials,
    this.imageUrl,
    this.size = 80,
    this.backgroundColor,
  });

  final String initials;
  final String? imageUrl;
  final double size;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        backgroundColor ??
        (isDark ? SignalColors.signalBlue : SignalColors.signalBlue);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        image: imageUrl != null
            ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: imageUrl == null
          ? Center(
              child: Text(
                initials,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }
}

/// Large avatar with optional action buttons (for profile headers)
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.initials,
    this.imageUrl,
    this.size = 100,
    this.onCameraTap,
    this.showCameraButton = false,
  });

  final String initials;
  final String? imageUrl;
  final double size;
  final VoidCallback? onCameraTap;
  final bool showCameraButton;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SignalAvatar(initials: initials, imageUrl: imageUrl, size: size),
        if (showCameraButton)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: onCameraTap,
              child: Container(
                width: size * 0.32,
                height: size * 0.32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SignalColors.signalBlue,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: size * 0.16,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
