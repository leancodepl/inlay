import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'inlay_navigator.g.dart';

export 'inlay_navigator.g.dart' show PageSettings;

/// Route target understood by [InlayNavigator].
enum InlayRouteType { flutter, native, flutterDialog }

/// Common abstraction for all pushable destinations.
abstract class InlayRoute {
  const InlayRoute();

  /// Whether this route should open Flutter or native UI.
  InlayRouteType get type;

  /// Convert destination to transport-level page settings.
  PageSettings toPageSettings();
}

/// A typed Flutter route description for cross-boundary navigation.
///
/// This class represents a Flutter screen that can be opened from **native
/// code** (Android/iOS). When used with [InlayNavigator], the native side
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
/// InlayNavigator.push(context, PageSettings("soundsNotifications", listOf("42")))
/// ```
///
/// ## Secondary Use Case: Flutter → Flutter (New Engine)
///
/// You _can_ push this route from Flutter code, but be aware this creates
/// a **new Flutter engine**, not an in-Flutter navigation. This is rarely
/// needed. See [InlayNavigator] documentation for details.
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
abstract class FlutterRouteBase extends InlayRoute {
  const FlutterRouteBase();

  /// Unique route identifier resolved by the page handler.
  String get routeId;

  /// Route parameters serialized as a list for StandardMessageCodec transport.
  Object? get params;

  @override
  InlayRouteType get type => InlayRouteType.flutter;

  /// Convert to the Pigeon-generated [PageSettings].
  @override
  PageSettings toPageSettings() {
    return PageSettings(routeId: routeId, params: params);
  }
}

/// A typed Flutter dialog route description for cross-boundary navigation.
///
/// Like [FlutterRouteBase] but the native side opens a transparent container
/// so the underlying screen is visible. Flutter code renders the dialog content
/// (barrier, animation, positioning).
///
/// Generated dialog route classes extend this.
abstract class FlutterDialogRouteBase extends InlayRoute {
  const FlutterDialogRouteBase();

  /// Unique route identifier resolved by the page handler.
  String get routeId;

  /// Route parameters serialized as a list for StandardMessageCodec transport.
  Object? get params;

  @override
  InlayRouteType get type => InlayRouteType.flutterDialog;

  @override
  PageSettings toPageSettings() {
    return PageSettings(routeId: routeId, params: params);
  }
}

/// Typed wrapper for native destinations.
///
/// Usually created by generated native page extensions, e.g.
/// `NativeEditProfilePage(...).toNativeRoute()`.
class NativeRouteWrapper extends InlayRoute {
  const NativeRouteWrapper(this.page);

  final PageSettings page;

  @override
  InlayRouteType get type => InlayRouteType.native;

  @override
  PageSettings toPageSettings() => page;
}

/// Framework-level navigator for cross-boundary navigation in inlay.
///
/// ## Overview
///
/// `InlayNavigator` handles navigation **across the Flutter/native boundary**.
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
/// **Use `InlayNavigator` only when:**
/// - Navigating from **Flutter to native** screens
/// - Navigating from **native to Flutter** screens
/// - (Rare) Navigating from **Flutter to Flutter in a new engine** (see below)
///
/// ## Flutter → Flutter via InlayNavigator (New Engine)
///
/// When you call `InlayNavigator.instance.push(SomeFlutterRoute(...))` from
/// Flutter code, this creates a **new native Activity/ViewController** with a
/// **fresh Flutter engine**. This is fundamentally different from in-Flutter
/// navigation:
///
/// | Aspect | In-Flutter Navigation | InlayNavigator Flutter→Flutter |
/// |--------|----------------------|----------------------------------|
/// | Engine | Same engine | New engine instance |
/// | Memory | Shared widget tree | Separate memory space |
/// | State | Shared app state | Isolated state |
/// | Startup | Instant | Engine initialization delay |
/// | Use case | Normal navigation | Cross-module isolation |
///
/// **When to use Flutter→Flutter via InlayNavigator:**
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
/// InlayNavigator.push(context, PageSettings("soundsNotifications", mapOf("contactId" to "42")))
/// ```
///
/// From iOS:
/// ```swift
/// InlayNavigator.shared.push(PageSettings(routeId: "soundsNotifications", params: ["contactId": "42"]))
/// ```
///
/// ### Flutter → Native (common)
///
/// ```dart
/// InlayNavigator.instance.push(
///   NativeEditProfilePage(contactId: '42').toNativeRoute(),
/// );
/// ```
///
/// ### Flutter → Flutter via new engine (rare)
///
/// ```dart
/// // Creates a NEW Activity/ViewController with a NEW Flutter engine!
/// // Only use when you specifically need engine isolation.
/// InlayNavigator.instance.push(SoundsNotificationsPage(contactId: '42'));
/// ```
class InlayNavigator {
  InlayNavigator._();

  static final instance = InlayNavigator._();

  final _hostApi = InlayNavigatorHostApi();

  // ── Navigation ───────────────────────────────────────────────────────

  /// Pushes a route, creating a new native Activity/ViewController.
  ///
  /// For `InlayFlutterRoute`: Opens a **new** Activity/ViewController with
  /// a **new Flutter engine**. This is NOT the same as in-Flutter navigation.
  /// See class documentation for when to use this vs `Navigator.of(context)`.
  ///
  /// For `InlayNativeRoute`: Opens a native Activity/ViewController.
  Future<void> push(InlayRoute route) async {
    final page = route.toPageSettings();
    switch (route.type) {
      case InlayRouteType.flutter:
        await pushFlutterRoute(page);
      case InlayRouteType.native:
        await pushNativeRoute(page);
      case InlayRouteType.flutterDialog:
        await presentFlutterDialog(page);
    }
  }

  /// Pop (finish) the current Flutter Activity/ViewController.
  Future<void> pop() async {
    await _hostApi.pop();
  }

  /// Enable/disable native iOS swipe-back gesture for this container.
  ///
  /// This is used by `InlayNativePopGestureObserver` to prevent native
  /// container pop while the in-Flutter navigator can handle back.
  /// No-op on Android.
  Future<void> setNativePopGestureEnabled(bool enabled) async {
    await _hostApi.setNativePopGestureEnabled(enabled);
  }

  /// Pops the topmost Flutter route if the navigator can pop, otherwise
  /// closes the native container (Activity/ViewController).
  ///
  /// Use this as the handler for custom back buttons in add-to-app screens:
  ///
  /// ```dart
  /// IconButton(
  ///   icon: const Icon(Icons.arrow_back),
  ///   onPressed: () => InlayNavigator.instance.maybePop(context),
  /// )
  /// ```
  Future<void> maybePop(BuildContext context) async {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      await pop();
    }
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
  /// `InlayNavigator.push(...)` on Android/iOS. Calling it from Flutter
  /// is a niche use case for when you need complete engine isolation.
  Future<void> pushFlutterRoute(PageSettings page) async {
    await _hostApi.push(page);
  }

  /// Internal method: open a native Activity/ViewController route.
  ///
  /// The platform side dispatches to the `NativeRouteHandler` set via
  /// `InlayNavigator.setNativeRouteHandler(...)` on Android/iOS.
  ///
  /// Use the generated `.toNativeRoute()` extension on pigeon page classes:
  ///
  /// ```dart
  /// InlayNavigator.instance.push(
  ///   NativeEditProfilePage(contactId: '42').toNativeRoute(),
  /// );
  /// ```
  Future<void> pushNativeRoute(PageSettings page) async {
    await _hostApi.pushNativeRoute(page);
  }

  /// Present a Flutter dialog in a transparent native container.
  ///
  /// The native side creates a transparent Activity/ViewController with a
  /// new Flutter engine. Flutter renders the dialog content (barrier,
  /// animation, positioning) over the native screen underneath.
  Future<void> presentFlutterDialog(PageSettings page) async {
    await _hostApi.presentDialog(page);
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

  /// URL path from the platform's `defaultRouteName`
  /// (e.g. `/sounds-notifications/42`).
  ///
  /// Synchronous — available the moment the Dart isolate starts.
  /// For the prewarm engine or root, returns `/`.
  ///
  /// Use this as `initialLocation` for go_router, `initialDeepLink` for
  /// auto_route, or in a custom `RouteInformationProvider`.
  static String get initialPath {
    final raw = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    if (raw == '__inlay_prewarm__' || raw == '/') {
      return '/';
    }
    return raw;
  }

  /// Fetch the initial route data from the native host and decode it.
  ///
  /// [decoder] is the generated `decodeFlutterRouteData` function.
  /// The generic parameter `T` is inferred from the decoder's return type,
  /// so when using the generated sealed `FlutterRoute` hierarchy you get
  /// back the sealed type for exhaustive pattern matching:
  ///
  /// ```dart
  /// final route = await InlayNavigator.fetchInitialRoute(decodeFlutterRouteData);
  /// final widget = switch (route) {
  ///   MyPage(:final id) => MyScreen(id: id),
  ///   null => const FallbackScreen(),
  /// };
  /// ```
  static Future<T?> fetchInitialRoute<T extends InlayRoute>(
    T? Function(PageSettings?) decoder,
  ) async {
    try {
      final raw = await InlayNavigatorHostApi().getInitialRouteData();
      return decoder(raw);
    } on PlatformException catch (e, st) {
      debugPrint('InlayNavigator.fetchInitialRoute failed: $e\n$st');
      return null;
    } catch (e, st) {
      debugPrint('InlayNavigator.fetchInitialRoute failed: $e\n$st');
      return null;
    }
  }
}
