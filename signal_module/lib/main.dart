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
      return MaterialPageRoute(
        settings: settings,
        builder: (_) {
          return const ContactDetailsScreen(contactId: '1');
        },
      );
    },
    'setWallpaper': (settings, isContainerPage, uniqueId) {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) {
          return const SetWallpaperScreen();
        },
      );
    },
    'soundsNotifications': (settings, isContainerPage, uniqueId) {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) {
          return const SoundsNotificationsScreen(contactId: '1');
        },
      );
    },
  };

  Route<dynamic>? routeFactory(
    RouteSettings settings,
    bool isContainerPage,
    String? uniqueId,
  ) {
    final func = routerMap[settings.name]!;
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
