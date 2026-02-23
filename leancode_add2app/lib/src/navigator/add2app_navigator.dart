import 'package:flutter/widgets.dart';

import 'add2app_navigator.g.dart';

export 'add2app_navigator.g.dart' show PageSettings;

/// Route target understood by [Add2AppNavigator].
enum Add2AppRouteType { flutter, native }

/// Common abstraction for all pushable destinations.
abstract class Add2AppRoute {
  const Add2AppRoute();

  /// Whether this route should open Flutter or native UI.
  Add2AppRouteType get type;

  /// Convert destination to transport-level page settings.
  PageSettings toPageSettings();
}

/// A typed Flutter route description for cross-boundary navigation.
///
/// This class represents a Flutter screen that can be opened from **native
/// code** (Android/iOS). When used with [Add2AppNavigator], the native side
/// creates a new Activity/ViewController hosting a Flutter engine that
/// displays this route.
///
/// ## Primary Use Case: Native → Flutter
///
/// The main purpose of `FlutterRouteBase` is to define Flutter screens
/// that native code can navigate to:
///
/// ```kotlin
/// // Android: open a Flutter screen from native code
/// Add2AppNavigator.push(context, PageSettings("soundsNotifications", listOf("42")))
/// ```
///
/// ## Secondary Use Case: Flutter → Flutter (New Engine)
///
/// You _can_ push this route from Flutter code, but be aware this creates
/// a **new Flutter engine**, not an in-Flutter navigation. This is rarely
/// needed. See [Add2AppNavigator] documentation for details.
///
/// ## Example
///
/// ```dart
/// class SoundsNotificationsPage extends FlutterRouteBase {
///   const SoundsNotificationsPage({required this.contactId});
///   final String contactId;
///
///   @override
///   String get routeId => 'soundsNotifications';
///
///   @override
///   Object? get params => [contactId];
/// }
/// ```
abstract class FlutterRouteBase extends Add2AppRoute {
  const FlutterRouteBase();

  /// Unique route identifier (matches the key in the page registry).
  String get routeId;

  /// Route parameters serialized as a list for StandardMessageCodec transport.
  Object? get params;

  @override
  Add2AppRouteType get type => Add2AppRouteType.flutter;

  /// Convert to the Pigeon-generated [PageSettings].
  @override
  PageSettings toPageSettings() {
    return PageSettings(routeId: routeId, params: params);
  }
}

/// Typed wrapper for native destinations.
///
/// Usually created by generated native page extensions, e.g.
/// `NativeEditProfilePage(...).toNativeRoute()`.
class NativeRouteWrapper extends Add2AppRoute {
  const NativeRouteWrapper(this.page);

  final PageSettings page;

  @override
  Add2AppRouteType get type => Add2AppRouteType.native;

  @override
  PageSettings toPageSettings() => page;
}

/// Signature for the factory that builds a [Widget] from the raw params.
typedef PageBuilder = Widget Function(Object? params);

/// Framework-level navigator for cross-boundary navigation in add2app.
///
/// ## Overview
///
/// `Add2AppNavigator` handles navigation **across the Flutter/native boundary**.
/// It coordinates with the native side to start new Activities (Android) or
/// ViewControllers (iOS).
///
/// ## Important: This is NOT in-Flutter Navigation
///
/// **For navigation within Flutter**, use Flutter's built-in `Navigator`:
///
/// ```dart
/// // Within Flutter - use standard Flutter navigation
/// Navigator.of(context).push(MaterialPageRoute(
///   builder: (_) => MyOtherScreen(),
/// ));
/// ```
///
/// **Use `Add2AppNavigator` only when:**
/// - Navigating from **Flutter to native** screens
/// - Navigating from **native to Flutter** screens
/// - (Rare) Navigating from **Flutter to Flutter in a new engine** (see below)
///
/// ## Flutter → Flutter via Add2AppNavigator (New Engine)
///
/// When you call `Add2AppNavigator.instance.push(SomeFlutterRoute(...))` from
/// Flutter code, this creates a **new native Activity/ViewController** with a
/// **fresh Flutter engine**. This is fundamentally different from in-Flutter
/// navigation:
///
/// | Aspect | In-Flutter Navigation | Add2AppNavigator Flutter→Flutter |
/// |--------|----------------------|----------------------------------|
/// | Engine | Same engine | New engine instance |
/// | Memory | Shared widget tree | Separate memory space |
/// | State | Shared app state | Isolated state |
/// | Startup | Instant | Engine initialization delay |
/// | Use case | Normal navigation | Cross-module isolation |
///
/// **When to use Flutter→Flutter via Add2AppNavigator:**
/// - When you need complete isolation between Flutter modules
/// - When different parts of the app have incompatible dependencies
/// - When navigating from native code that doesn't have access to the
///   current Flutter engine's navigator
///
/// **Prefer in-Flutter navigation when:**
/// - Navigating between screens within the same Flutter module
/// - You need shared state or want instant transitions
/// - Memory efficiency is important
///
/// ## Usage Examples
///
/// ### Native → Flutter (common)
///
/// From Android:
/// ```kotlin
/// Add2AppNavigator.push(context, PageSettings("soundsNotifications", mapOf("contactId" to "42")))
/// ```
///
/// From iOS:
/// ```swift
/// Add2AppNavigator.shared.push(PageSettings(routeId: "soundsNotifications", params: ["contactId": "42"]))
/// ```
///
/// ### Flutter → Native (common)
///
/// ```dart
/// Add2AppNavigator.instance.push(
///   NativeEditProfilePage(contactId: '42').toNativeRoute(),
/// );
/// ```
///
/// ### Flutter → Flutter via new engine (rare)
///
/// ```dart
/// // ⚠️ Creates a NEW Activity/ViewController with a NEW Flutter engine!
/// // Only use when you specifically need engine isolation.
/// Add2AppNavigator.instance.push(SoundsNotificationsPage(contactId: '42'));
/// ```
class Add2AppNavigator {
  Add2AppNavigator._();

  static final instance = Add2AppNavigator._();

  final _hostApi = Add2AppNavigatorHostApi();

  /// Registry: routeId → widget builder.
  final _pages = <String, PageBuilder>{};

  // ── Page registration ─────────────────────────────────────────────

  /// Register a page builder for a given [routeId].
  ///
  /// Call this once per page, typically in your entrypoint before `runApp`.
  void registerPage(String routeId, PageBuilder builder) {
    _pages[routeId] = builder;
  }

  /// Build a widget for the given [PageSettings].
  /// Returns an error widget if the route is not registered.
  Widget buildPage(PageSettings page) {
    final builder = _pages[page.routeId];
    if (builder == null) {
      return Center(child: Text('Unknown route: ${page.routeId}'));
    }
    return builder(page.params);
  }

  // ── Navigation ───────────────────────────────────────────────────────

  /// Pushes a route, creating a new native Activity/ViewController.
  ///
  /// For `Add2AppFlutterRoute`: Opens a **new** Activity/ViewController with
  /// a **new Flutter engine**. This is NOT the same as in-Flutter navigation.
  /// See class documentation for when to use this vs `Navigator.of(context)`.
  ///
  /// For `Add2AppNativeRoute`: Opens a native Activity/ViewController.
  Future<void> push(Add2AppRoute route) async {
    final page = route.toPageSettings();
    switch (route.type) {
      case Add2AppRouteType.flutter:
        await pushFlutterRoute(page);
      case Add2AppRouteType.native:
        await pushNativeRoute(page);
    }
  }

  /// Pop (finish) the current Flutter Activity/ViewController.
  Future<void> pop() async {
    await _hostApi.pop();
  }

  // ── Internal route dispatch ───────────────────────────────────────

  /// Starts a new Activity/ViewController with a new Flutter engine.
  ///
  /// **Warning:** This creates a completely new Flutter engine instance,
  /// not an in-Flutter navigation. The new engine:
  /// - Has its own widget tree and state
  /// - Requires engine initialization time
  /// - Consumes additional memory
  ///
  /// For navigation within the same Flutter module, use Flutter's `Navigator`
  /// instead:
  ///
  /// ```dart
  /// // Preferred for in-Flutter navigation:
  /// Navigator.of(context).push(MaterialPageRoute(builder: (_) => MyScreen()));
  /// ```
  ///
  /// This method is primarily intended to be called from native code via
  /// `Add2AppNavigator.push(...)` on Android/iOS. Calling it from Flutter
  /// is a niche use case for when you need complete engine isolation.
  Future<void> pushFlutterRoute(PageSettings page) async {
    await _hostApi.push(page);
  }

  /// Internal method: open a native Activity/ViewController route.
  ///
  /// The platform side dispatches to the `NativeRouteHandler` set via
  /// `Add2AppNavigator.setNativeRouteHandler(...)` on Android/iOS.
  ///
  /// Use the generated `.toNativeRoute()` extension on pigeon page classes:
  ///
  /// ```dart
  /// Add2AppNavigator.instance.push(
  ///   NativeEditProfilePage(contactId: '42').toNativeRoute(),
  /// );
  /// ```
  Future<void> pushNativeRoute(PageSettings page) async {
    await _hostApi.pushNativeRoute(page);
  }

  // ── Initial route parsing ─────────────────────────────────────────

  /// Decode the `initialRoute` string (set by the platform) back into
  /// [PageSettings].  Format: `routeId?key=val&key=val`
  static PageSettings decodeInitialRoute(String initialRoute) {
    final questionMark = initialRoute.indexOf('?');
    if (questionMark < 0) {
      return PageSettings(routeId: initialRoute);
    }

    final routeId = initialRoute.substring(0, questionMark);
    final query = initialRoute.substring(questionMark + 1);
    final params = <String, String>{};

    for (final pair in query.split('&')) {
      final eq = pair.indexOf('=');
      if (eq > 0) {
        params[Uri.decodeComponent(pair.substring(0, eq))] =
            Uri.decodeComponent(pair.substring(eq + 1));
      }
    }

    return PageSettings(routeId: routeId, params: params);
  }

  /// Reads platform `defaultRouteName` and decodes it into [PageSettings].
  ///
  /// Keeps Flutter platform-dispatcher details hidden from app modules.
  static PageSettings initialPageFromPlatform() {
    final initialRoute =
        WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    return decodeInitialRoute(initialRoute);
  }

  /// Returns the raw URL path from the platform's `defaultRouteName`.
  ///
  /// For routes with a `path` annotation, this returns the full URL path
  /// (e.g. `/sounds-notifications/42`). For the prewarm engine or root,
  /// returns `/`.
  ///
  /// Use this as `initialLocation` for go_router, `initialDeepLink` for
  /// auto_route, or in a custom `RouteInformationProvider`.
  @Deprecated('Use initialPath instead')
  static String initialLocationFromPlatform() {
    return initialPath;
  }

  /// URL path from the platform's `defaultRouteName`
  /// (e.g. `/sounds-notifications/42`).
  ///
  /// Synchronous — available the moment the Dart isolate starts.
  /// For the prewarm engine or root, returns `/`.
  ///
  /// Use this as `initialLocation` for go_router, `initialDeepLink` for
  /// auto_route, or in a custom `RouteInformationProvider`.
  static String get initialPath {
    final raw =
        WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    if (raw == '__add2app_prewarm__' || raw == '/') {
      return '/';
    }
    return raw;
  }

  /// Fetch the initial route data from the native host and decode it.
  ///
  /// [decoder] is the generated `decodeFlutterRouteData` function.
  /// Returns the fully typed [FlutterRouteBase] subclass (including path
  /// params like `contactId`), or `null` for the prewarm engine / when
  /// native didn't set any data.
  ///
  /// ```dart
  /// final route = await Add2AppNavigator.fetchInitialRoute(decodeFlutterRouteData);
  /// if (route case SoundsNotificationsPage page) { ... }
  /// ```
  static Future<FlutterRouteBase?> fetchInitialRoute(
    FlutterRouteBase? Function(PageSettings?) decoder,
  ) async {
    try {
      final raw = await Add2AppNavigatorHostApi().getInitialRouteData();
      return decoder(raw);
    } catch (_) {
      return null;
    }
  }
}
