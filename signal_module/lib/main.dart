import 'package:flutter/material.dart';
import 'package:leancode_add2app/leancode_add2app.dart';
import 'package:signal_module/src/generated/routes.g.dart';
import 'package:signal_module/src/screens/contact_details_screen.dart';
import 'package:signal_module/src/screens/set_wallpaper_screen.dart';
import 'package:signal_module/src/screens/sounds_notifications_screen.dart';

void main() {
  runApp(const MyApp());
}

// ── Framework entrypoint ─────────────────────────────────────────────

/// **Single** Dart entrypoint used by [Add2AppNavigator] for every page.
///
/// The Android side always calls this entrypoint and encodes the target page
/// in the `initialRoute`.  This function:
/// 1. Uses generated typed route handlers.
/// 2. Initialises framework services (e.g. [KeyValueStorage]).
/// 3. Decodes the `initialRoute` to find out which page to show.
/// 4. Builds the widget and runs the app.
///
/// Developers only need to implement generated handler methods here — no need
/// to create new entrypoints, Activities, method channels, etc.
@pragma('vm:entry-point')
void add2appMain() {
  WidgetsFlutterBinding.ensureInitialized();

  const routeHandler = _SignalFlutterRouteHandler();

  // ── 1. Init framework services ─────────────────────────────────────
  KeyValueStorage.instance.init();

  // ── 2. Decode initial route ────────────────────────────────────────
  final page = Add2AppNavigator.initialPageFromPlatform();

  // ── 3. Run ─────────────────────────────────────────────────────────
  runApp(MaterialApp(home: routeHandler.handle(page)));
}

/// Route handler that maps typed routes to screens.
///
/// Extend the generated [FlutterRouteHandler] and implement a method for each
/// Flutter route. The handler provides compile-time type safety - if you add
/// a new route, you'll get a compile error until you implement its handler.
class _SignalFlutterRouteHandler extends FlutterRouteHandler {
  const _SignalFlutterRouteHandler();

  @override
  Widget onSoundsNotifications(SoundsNotificationsPage page) {
    return SoundsNotificationsScreen(contactId: page.contactId);
  }

  @override
  Widget onSetWallpaper(SetWallpaperPage page) {
    return SetWallpaperScreen(recipientId: page.recipientId);
  }

  @override
  Widget onContactDetails(ContactDetailsPage page) {
    return ContactDetailsScreen(contactId: page.contactId);
  }
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
