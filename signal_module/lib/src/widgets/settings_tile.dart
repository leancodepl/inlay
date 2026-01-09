import 'package:flutter/material.dart';

import '../theme/signal_theme.dart';

/// A settings list tile that matches Signal's design
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = destructive
        ? SignalColors.destructive
        : iconColor ?? theme.listTileTheme.iconColor;
    final effectiveTitleColor = destructive
        ? SignalColors.destructive
        : theme.listTileTheme.textColor;

    return ListTile(
      leading: Icon(icon, color: effectiveIconColor, size: 24),
      title: Text(
        title,
        style: TextStyle(color: effectiveTitleColor, fontSize: 16),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                color: theme.brightness == Brightness.dark
                    ? SignalColors.textSecondaryDark
                    : SignalColors.textSecondaryLight,
                fontSize: 14,
              ),
            )
          : null,
      trailing:
          trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

/// A section header for settings groups
class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: SignalColors.signalBlue,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// A divider for settings lists
class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key, this.indent = 56});

  final double indent;

  @override
  Widget build(BuildContext context) {
    return Divider(indent: indent, height: 1);
  }
}
