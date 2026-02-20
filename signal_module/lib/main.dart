import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:leancode_add2app/leancode_add2app.dart';
import 'package:signal_module/src/router.dart';
import 'package:signal_module/src/router_auto_route.dart';
import 'package:signal_module/src/screens/set_wallpaper_screen.dart';
import 'package:signal_module/src/screens/sounds_notifications_screen.dart';

void main() {
  runApp(const MyApp());
}

// ── Framework entrypoint ─────────────────────────────────────────────

/// **Single** Dart entrypoint used by [Add2AppNavigator] for every page.
///
/// The native side always calls this entrypoint and encodes the target page
/// as a URL path in `initialRoute`. This function:
/// 1. Initialises framework services (e.g. [KeyValueStorage]).
/// 2. Creates an auto_route router with routes matching the path templates.
/// 3. auto_route reads `initialLocation` from the platform to build the
///    correct page stack.
///
/// Developers define routes in the auto_route configuration — no need
/// to create new Activities, method channels, etc.
@pragma('vm:entry-point')
void add2appMain() {
  // Temporary switch for manual testing of auto_route in the native host.
  _runAdd2AppWithAutoRoute();
}

/// Alternative entrypoint kept for backward compatibility with native config.
@pragma('vm:entry-point')
void add2appAutoRouteMain() {
  _runAdd2AppWithAutoRoute();
}

/// Preserved go_router example entrypoint.
@pragma('vm:entry-point')
void add2appGoRouterMain() {
  _runAdd2AppWithGoRouter();
}

void _runAdd2AppWithGoRouter() {
  WidgetsFlutterBinding.ensureInitialized();

  KeyValueStorage.instance.init();

  final router = createSignalRouter();

  runApp(
    MaterialApp.router(
      routeInformationProvider: router.routeInformationProvider,
      routeInformationParser: router.routeInformationParser,
      routerDelegate: router.routerDelegate,
      backButtonDispatcher: Add2AppBackButtonDispatcher(),
    ),
  );
}

void _runAdd2AppWithAutoRoute() {
  WidgetsFlutterBinding.ensureInitialized();

  KeyValueStorage.instance.init();

  final initialLocation = normalizeSignalAutoRouteLocation(
    Add2AppNavigator.initialLocationFromPlatform(),
  );
  final router = createSignalAutoRouter();

  runApp(
    MaterialApp.router(
      routeInformationParser: router.defaultRouteParser(
        includePrefixMatches: true,
      ),
      routerDelegate: router.delegate(
        deepLinkBuilder: (_) => DeepLink.path(initialLocation),
        rebuildStackOnDeepLink: true,
      ),
      backButtonDispatcher: Add2AppBackButtonDispatcher(),
    ),
  );
}

// ── Legacy entrypoints (kept for backward compatibility) ─────────────

/// ADD2APP entrypoint: Set Wallpaper screen (standalone engine).
@pragma('vm:entry-point')
void mainSetWallpaper() {
  runApp(const _LegacyAdd2AppHost(initialRoute: 'setWallpaper'));
}

/// ADD2APP entrypoint: Sounds & Notifications screen (engine group).
@pragma('vm:entry-point')
void mainSoundsNotifications() {
  WidgetsFlutterBinding.ensureInitialized();
  KeyValueStorage().init();
  runApp(const _LegacyAdd2AppHost(initialRoute: 'soundsNotifications'));
}

/// Legacy host widget — kept only for old Activities that haven't migrated yet.
class _LegacyAdd2AppHost extends StatelessWidget {
  const _LegacyAdd2AppHost({required this.initialRoute});

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

// ── Standalone app (for development) ─────────────────────────────────

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Center(child: Text('Signal Module')));
  }
}
