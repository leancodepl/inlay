import 'package:flutter/material.dart';
import 'package:leancode_add2app/leancode_add2app.dart';
import 'package:signal_module/src/router.dart';
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
/// 2. Creates a go_router with routes matching the path templates.
/// 3. go_router reads `initialLocation` from the platform to build the
///    correct page stack.
///
/// Developers define routes in the go_router configuration — no need
/// to create new entrypoints, Activities, method channels, etc.
@pragma('vm:entry-point')
void add2appMain() {
  WidgetsFlutterBinding.ensureInitialized();

  // ── 1. Init framework services ─────────────────────────────────────
  KeyValueStorage.instance.init();

  // ── 2. Create router (reads initialLocation from platform) ─────────
  final router = createSignalRouter();

  // ── 3. Run ─────────────────────────────────────────────────────────
  runApp(MaterialApp.router(
    routerConfig: router,
    backButtonDispatcher: Add2AppBackButtonDispatcher(),
  ));
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
