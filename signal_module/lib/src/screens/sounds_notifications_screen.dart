import 'package:flutter/material.dart';

import '../theme/signal_theme.dart';
import '../widgets/settings_tile.dart';

/// Sounds & Notifications screen
/// This demonstrates nested Flutter navigation
class SoundsNotificationsScreen extends StatefulWidget {
  const SoundsNotificationsScreen({super.key, required this.contactId});

  final String contactId;

  @override
  State<SoundsNotificationsScreen> createState() =>
      _SoundsNotificationsScreenState();
}

class _SoundsNotificationsScreenState extends State<SoundsNotificationsScreen> {
  var _muteNotifications = false;
  var _showPreviews = true;
  var _notificationSound = 'Default';
  var _vibrationPattern = 'Default';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sounds & Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          // Mute toggle
          SwitchListTile(
            secondary: Icon(
              _muteNotifications
                  ? Icons.notifications_off
                  : Icons.notifications,
              color: isDark
                  ? SignalColors.textSecondaryDark
                  : SignalColors.textSecondaryLight,
            ),
            title: const Text('Mute notifications'),
            subtitle: _muteNotifications
                ? const Text('Notifications are muted')
                : null,
            value: _muteNotifications,
            onChanged: (value) {
              setState(() => _muteNotifications = value);
            },
          ),

          const Divider(indent: 56),

          SettingsTile(
            icon: Icons.music_note_outlined,
            title: 'Notification sound',
            subtitle: _notificationSound,
            onTap: () => _showSoundPicker(context),
          ),

          const Divider(indent: 56),

          SettingsTile(
            icon: Icons.vibration,
            title: 'Vibrate',
            subtitle: _vibrationPattern,
            onTap: () => _showVibrationPicker(context),
          ),

          const SizedBox(height: 24),
          const SettingsSectionHeader(title: 'Message notifications'),

          SwitchListTile(
            secondary: Icon(
              Icons.visibility_outlined,
              color: isDark
                  ? SignalColors.textSecondaryDark
                  : SignalColors.textSecondaryLight,
            ),
            title: const Text('Show previews'),
            subtitle: const Text('Display message content in notifications'),
            value: _showPreviews,
            onChanged: (value) {
              setState(() => _showPreviews = value);
            },
          ),

          const SizedBox(height: 32),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'These settings override the default notification settings for this conversation.',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? SignalColors.textSecondaryDark
                    : SignalColors.textSecondaryLight,
              ),
            ),
          ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }

  void _showSoundPicker(BuildContext context) {
    final sounds = ['Default', 'Signal', 'Pulse', 'Chime', 'Bamboo', 'None'];

    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Notification Sound',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            ...sounds.map(
              (sound) => ListTile(
                title: Text(sound),
                trailing: _notificationSound == sound
                    ? const Icon(Icons.check, color: SignalColors.signalBlue)
                    : null,
                onTap: () {
                  setState(() => _notificationSound = sound);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showVibrationPicker(BuildContext context) {
    final patterns = ['Default', 'Short', 'Long', 'Double', 'None'];

    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Vibration Pattern',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            ...patterns.map(
              (pattern) => ListTile(
                title: Text(pattern),
                trailing: _vibrationPattern == pattern
                    ? const Icon(Icons.check, color: SignalColors.signalBlue)
                    : null,
                onTap: () {
                  setState(() => _vibrationPattern = pattern);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
