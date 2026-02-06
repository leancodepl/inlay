import 'package:flutter/material.dart';
import 'package:flutter_boost/flutter_boost.dart';
import 'package:signal_module/src/routes.dart';

void main() {
  CustomFlutterBinding();
  runApp(const MyApp());
}

class CustomFlutterBinding extends WidgetsFlutterBinding
    with BoostFlutterBinding {}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Map<String, FlutterBoostRouteFactory> routerMap = {
    'contactDetails': (settings, isContainerPage, uniqueId) {
      final args = settings.arguments as Map?;
      final recipientId = args?['recipientId'] as String? ?? '1';
      
      return MaterialPageRoute(
        settings: settings,
        builder: (_) {
          return ContactDetailsScreen(contactId: recipientId);
        },
      );
    },
    'setWallpaper': (settings, isContainerPage, uniqueId) {
      final args = settings.arguments as Map?;
      final recipientId = args?['recipientId'] as String?;
      
      return MaterialPageRoute(
        settings: settings,
        builder: (_) {
          return SetWallpaperScreen(recipientId: recipientId);
        },
      );
    },
    'soundsNotifications': (settings, isContainerPage, uniqueId) {
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

  Route<dynamic>? routeFactory(
    RouteSettings settings,
    bool isContainerPage,
    String? uniqueId,
  ) {
    print('FlutterBoost routeFactory called:');
    print('  - route name: ${settings.name}');
    print('  - arguments: ${settings.arguments}');
    print('  - isContainerPage: $isContainerPage');
    print('  - uniqueId: $uniqueId');
    
    final func = routerMap[settings.name];
    if (func == null) {
      print('ERROR: Unknown route: ${settings.name}');
      print('Available routes: ${routerMap.keys.join(", ")}');
      return null;
    }
    return func(settings, isContainerPage, uniqueId);
  }

  Widget appBuilder(Widget home) {
    return MaterialApp(
      home: home,

      builder: (_, _) {
        return home;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FlutterBoostApp(routeFactory, appBuilder: appBuilder);
  }
}
