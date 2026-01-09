import 'package:flutter/material.dart';

import 'src/models/contact.dart';
import 'src/screens/contact_details_screen.dart';
import 'src/screens/set_wallpaper_screen.dart';
import 'src/screens/sounds_notifications_screen.dart';
import 'src/theme/signal_theme.dart';

void main() {
  runApp(const SignalModuleDevApp());
}

/// Development app with screen picker for standalone testing
class SignalModuleDevApp extends StatelessWidget {
  const SignalModuleDevApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Signal Module Dev',
      theme: SignalTheme.lightTheme,
      darkTheme: SignalTheme.darkTheme,
      home: const _ScreenPicker(),
    );
  }
}

/// Screen picker for development
class _ScreenPicker extends StatelessWidget {
  const _ScreenPicker();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Signal Module'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(context, 'Available Screens'),
          const SizedBox(height: 8),
          Text(
            'Select a screen to preview',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? SignalColors.textSecondaryDark
                  : SignalColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 16),
          _ScreenCard(
            title: 'Contact Details',
            subtitle: 'Profile view with settings',
            icon: Icons.person,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const ContactDetailsScreen(
                  contactId: 'alice',
                  contact: MockContacts.alice,
                ),
              ),
            ),
          ),
          _ScreenCard(
            title: 'Contact Details (Bob)',
            subtitle: 'Muted contact, no verification',
            icon: Icons.person_outline,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const ContactDetailsScreen(
                  contactId: 'bob',
                  contact: MockContacts.bob,
                ),
              ),
            ),
          ),
          _ScreenCard(
            title: 'Set Wallpaper',
            subtitle: 'Wallpaper selection screen',
            icon: Icons.wallpaper,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const SetWallpaperScreen(),
              ),
            ),
          ),
          _ScreenCard(
            title: 'Sounds & Notifications',
            subtitle: 'Notification settings',
            icon: Icons.notifications,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) =>
                    const SoundsNotificationsScreen(contactId: 'alice'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    );
  }
}

class _ScreenCard extends StatelessWidget {
  const _ScreenCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isDark ? SignalColors.darkSurface : SignalColors.lightSurface,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: SignalColors.signalBlue.withValues(alpha: 0.1),
          child: Icon(icon, color: SignalColors.signalBlue),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
