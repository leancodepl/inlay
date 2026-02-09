import 'package:flutter/material.dart';
import 'package:signal_module/src/routes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Map<String, PageRoute<dynamic> Function(RouteSettings, String)> routerMap = {
    'contactDetails': (settings, uniqueId) {
      final args = settings.arguments as Map?;
      final recipientId = args?['recipientId'] as String? ?? '1';

      return MaterialPageRoute(
        settings: settings,
        builder: (_) {
          return ContactDetailsScreen(contactId: recipientId);
        },
      );
    },
    'setWallpaper': (settings, uniqueId) {
      final args = settings.arguments as Map?;
      final recipientId = args?['recipientId'] as String?;

      return MaterialPageRoute(
        settings: settings,
        builder: (_) {
          return SetWallpaperScreen(recipientId: recipientId);
        },
      );
    },
    'soundsNotifications': (settings, uniqueId) {
      final args = settings.arguments as Map?;
      final recipientId = args?['recipientId'] as String? ?? '1';

      return MaterialPageRoute(
        settings: settings,
        builder: (_) {
          return SoundsNotificationsScreen(contactId: recipientId);
        },
      );
    },
  };

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Center(child: Text('Signal Module')));
  }
}
