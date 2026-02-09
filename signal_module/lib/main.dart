import 'package:flutter/material.dart';
import 'package:signal_module/src/routes.dart';

void main() {
  runApp(const MyApp());
}

/// ADD2APP entrypoint: Set Wallpaper screen (launched with standalone Flutter engine, no engine group).
@pragma('vm:entry-point')
void mainSetWallpaper() {
  runApp(const _Add2AppHost(initialRoute: 'setWallpaper'));
}

/// ADD2APP entrypoint: Sounds & Notifications screen (launched with engine from FlutterEngineGroup).
@pragma('vm:entry-point')
void mainSoundsNotifications() {
  runApp(const _Add2AppHost(initialRoute: 'soundsNotifications'));
}

/// Host widget for add2app entrypoints: shows a single screen based on initialRoute.
/// The recipientId is read from the engine's initial route (set by Android when starting the activity).
class _Add2AppHost extends StatelessWidget {
  const _Add2AppHost({required this.initialRoute});

  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    final routeFromPlatform =
        WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    final recipientId = routeFromPlatform.isEmpty ? null : routeFromPlatform;

    switch (initialRoute) {
      case 'setWallpaper':
        return MaterialApp(home: SetWallpaperScreen(recipientId: recipientId));
      case 'soundsNotifications':
        return MaterialApp(
          home: SoundsNotificationsScreen(contactId: recipientId ?? '1'),
        );
      default:
        return MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Unknown route: $initialRoute')),
          ),
        );
    }
  }
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
