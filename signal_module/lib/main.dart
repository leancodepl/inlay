import 'package:flutter/material.dart';
import 'package:signal_module/src/navigator/add2app_navigator.dart';
import 'package:signal_module/src/routes.dart';
import 'package:signal_module/src/storage/key_value_storage.dart';

void main() {
  runApp(const MyApp());
}

// ── Framework entrypoint ─────────────────────────────────────────────

/// **Single** Dart entrypoint used by [Add2AppNavigator] for every page.
///
/// The Android side always calls this entrypoint and encodes the target page
/// in the `initialRoute`.  This function:
/// 1. Registers all known pages in the navigator.
/// 2. Initialises framework services (e.g. [KeyValueStorage]).
/// 3. Decodes the `initialRoute` to find out which page to show.
/// 4. Builds the widget and runs the app.
///
/// Developers only need to add a new page to the registry here — no need
/// to create new entrypoints, Activities, method channels, etc.
@pragma('vm:entry-point')
void add2appMain() {
  WidgetsFlutterBinding.ensureInitialized();

  // ── 1. Register pages ──────────────────────────────────────────────
  _registerPages();

  // ── 2. Init framework services ─────────────────────────────────────
  KeyValueStorage().init();

  // ── 3. Decode initial route ────────────────────────────────────────
  final initialRoute =
      WidgetsBinding.instance.platformDispatcher.defaultRouteName;
  final page = Add2AppNavigator.decodeInitialRoute(initialRoute);

  // ── 4. Run ─────────────────────────────────────────────────────────
  runApp(
    MaterialApp(home: Add2AppNavigator.instance.buildPage(page)),
  );
}

/// Central page registry.
///
/// Every add2app screen is registered here once.  The key is the `routeId`
/// that matches the `Add2AppPage.routeId`.
void _registerPages() {
  Add2AppNavigator.instance
    ..registerPage('soundsNotifications', (params) {
      return SoundsNotificationsScreen(contactId: params['contactId'] ?? '1');
    })
    ..registerPage('setWallpaper', (params) {
      return SetWallpaperScreen(recipientId: params['recipientId']);
    })
    ..registerPage('contactDetails', (params) {
      return ContactDetailsScreen(contactId: params['contactId'] ?? '1');
    });
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
