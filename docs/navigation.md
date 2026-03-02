# Navigation

The framework provides type-safe, cross-boundary navigation between native (iOS/Android) and Flutter screens.

The framework uses a multi-engine approach: when native code navigates to a Flutter screen, a new native container (Activity on Android, ViewController on iOS) is created with its own Flutter engine. Consecutive Flutter screens within that container share the same engine and its Flutter navigation stack. A new engine is only created when a native screen needs to appear between Flutter screens. All engines share resources via a `FlutterEngineGroup`, so spinning up a new one is lightweight. You never manage engines directly.

## Background for Native Developers

A few Flutter concepts referenced in this guide:

- **Flutter engine** — A runtime that executes Dart code and renders Flutter UI. Each engine hosts its own Flutter navigation stack, so consecutive Flutter screens share one engine. A new engine is only needed when a native screen appears between Flutter screens (e.g. Flutter → **Native** → Flutter requires two engines). This framework uses a **multi-engine** approach to allow freely interleaving native and Flutter screens.
- **`FlutterEngineGroup`** — An API that lets multiple engines share resources (compiled code, fonts, images), making the multi-engine approach lightweight. The framework manages this for you.
- **`MaterialApp.router`** — The standard Flutter way to use a declarative routing library (like go_router or auto_route). The framework plugs into this system so the correct screen opens when a new engine starts.

## Concepts

- **Flutter route** — A screen rendered by Flutter. Navigating to it from native code creates a new engine inside a native container (Activity / ViewController). Navigating to it from within Flutter uses the existing engine's navigation stack.
- **Native route** — A screen rendered by the native platform. Flutter can request navigation to it, and the native side decides how to present it.
- **`Add2AppNavigator`** — The singleton that orchestrates all cross-boundary navigation. Accessed as `Add2AppNavigator.instance` (Dart), `Add2AppNavigator.shared` (iOS), or the `Add2AppNavigator` object (Android).
- **`PageSettings`** — A data class that carries a `routeId`, optional `params`, and optional `path` across the platform boundary. Generated route classes create this for you — you rarely touch it directly.

## Defining Routes

Routes are defined as plain Dart classes with annotations. Running the code generator produces type-safe route classes for **Dart, Swift, and Kotlin** so every platform gets compile-time safety.

### Flutter Routes

Annotate with `@Add2AppFlutterRoute` and provide a **path template**. The path determines the URL passed to the Flutter routing library (go_router, auto_route, etc.) when a new engine starts — it's how the framework tells the router which screen to display.

Path parameters (`:param`) map to required fields on the class.

```dart
@Add2AppFlutterRoute('/contact-details/:contactId')
class ContactDetailsPage {
  const ContactDetailsPage({
    required this.contactId,
    this.badges,
  });

  final String contactId;
  final List<ContactBadge>? badges;
}
```

The generator produces:
- A Dart class extending the generated `sealed class FlutterRoute` (which itself extends `FlutterRouteBase`) with serialization built in, enabling exhaustive pattern matching
- A Swift struct / Kotlin data class with the same fields, usable directly in native code

### Native Routes

Annotate with `@Add2AppNativeRoute` for screens that live on the native side.

```dart
@Add2AppNativeRoute()
class NativeEditProfilePage {
  const NativeEditProfilePage({required this.contactId});
  final String contactId;
}
```

The generator produces:
- A Dart class with a `toNativeRoute()` method for use in `Add2AppNavigator.instance.push()`
- A typed handler method in the generated `NativeRouteHandler` base class (Swift and Kotlin), so you implement native navigation with full type safety

## Navigating

### From Flutter (Dart)

All navigation goes through `Add2AppNavigator.instance.push()`:

```dart
// Open a Flutter screen (creates a new native container + engine)
await Add2AppNavigator.instance.push(
  ContactDetailsPage(contactId: 'abc-123'),
);

// Open a native screen
await Add2AppNavigator.instance.push(
  NativeEditProfilePage(contactId: 'abc-123').toNativeRoute(),
);

// Close the current screen (dismisses the native container)
await Add2AppNavigator.instance.pop();
```

### From iOS (Swift)

```swift
// Push onto the UIKit navigation stack
Add2AppNavigator.shared.push(
  from: viewController,
  route: ContactDetailsPage(contactId: "abc-123"),
  animated: true
)

// Present modally
Add2AppNavigator.shared.present(
  from: viewController,
  route: ContactDetailsPage(contactId: "abc-123"),
  animated: true
)

// Or create a ViewController manually for custom presentation
let vc = Add2AppNavigator.shared.createFlutterViewController(
  route: ContactDetailsPage(contactId: "abc-123")
)
```

For **SwiftUI**, use the provided wrapper:

```swift
NavigationStack {
  Add2AppFlutterView(route: ContactDetailsPage(contactId: "abc-123"))
}
```

### From Android (Kotlin)

```kotlin
// Start a new Activity
Add2AppNavigator.push(context, ContactDetailsPage(contactId = "abc-123"))

// Or create a Fragment for embedding in an existing Activity
val fragment = Add2AppNavigator.createFragment(
  context, ContactDetailsPage(contactId = "abc-123")
)
```

For **Jetpack Compose**, use the provided composable:

```kotlin
Add2AppFlutterScreen(route = ContactDetailsPage(contactId = "abc-123"))
```

## Handling Native Routes (Flutter → Native)

When Flutter pushes a native route, the framework dispatches it to a `NativeRouteHandler` you register on the native side. The generated handler has a typed method for each `@Add2AppNativeRoute`, so you don't parse strings.

### iOS

```swift
// Register once (e.g. in AppDelegate)
Add2AppNavigator.shared.setNativeRouteHandler(MyNativeRouteHandler())

// Implement the generated handler
class MyNativeRouteHandler: NativeRouteHandler {
  override func onNativeEditProfile(
    from viewController: UIViewController,
    contactId: String
  ) {
    let vc = EditProfileViewController(contactId: contactId)
    viewController.navigationController?.pushViewController(vc, animated: true)
  }
}
```

### Android

```kotlin
// Register once (e.g. in Application.onCreate)
Add2AppNavigator.setNativeRouteHandler(object : NativeRouteHandler() {
  override fun onNativeEditProfile(context: Context, contactId: String) {
    context.startActivity(
      Intent(context, EditProfileActivity::class.java)
        .putExtra("contactId", contactId)
    )
  }
})
```

## Flutter Router Integration

When the native side opens a Flutter screen, the framework encodes the route and passes it to the new Flutter engine. The Dart side needs to resolve that into the correct widget. The framework supports two integration styles:

1. **Declarative** — Works with `MaterialApp.router` and any Navigator 2.0 routing library (go_router, auto_route, etc.). The framework passes the initial route as a URL path and the router matches it to a screen.
2. **Imperative** — Works with plain `MaterialApp` and no routing library. The generated `sealed class FlutterRoute` hierarchy lets you use Dart pattern matching for exhaustive, type-safe route resolution — no strings, no handler classes.

### Declarative (MaterialApp.router)

The framework encodes the route as a URL path (e.g. `/contact-details/abc-123`) and passes it as the initial route for the new Flutter engine. A routing library on the Dart side matches that path to a widget.

There are two integration points:

- **`Add2AppNavigator.initialPath`** — reads the platform's `defaultRouteName` and returns the URL path. You pass this to your routing library as the initial location. This is synchronous and carries path parameters only.
- **`Add2AppNavigator.fetchInitialRoute(decodeFlutterRouteData)`** — fetches the full route data (including non-path parameters like lists and complex objects) from the native host and decodes it into a typed route object. Pass this as extra data to your router so builders can access non-path parameters.

If your routes only use path parameters, `initialPath` alone is sufficient. If any route has non-path parameters (e.g. `List<ContactBadge>? badges`), you need both.

`Add2AppBackButtonDispatcher` ensures that when the user presses back and the router stack is empty, the native container (Activity/ViewController) is dismissed instead of doing nothing.

`Add2AppNativePopGestureObserver` syncs the iOS interactive back-swipe gesture with the Flutter navigation stack. Without it, the native swipe-back gesture may dismiss the entire Flutter container even when there are in-Flutter routes to pop. Wrap it around the router's child via `MaterialApp.router`'s `builder`.

#### go_router example

```dart
GoRouter createRouter({
  String initialLocation = '/',
  FlutterRouteBase? initialExtra,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    initialExtra: initialExtra,
    routes: [
      GoRoute(
        path: '/sounds-notifications/:contactId',
        builder: (_, state) => SoundsNotificationsScreen(
          contactId: state.pathParameters['contactId']!,
        ),
      ),
      GoRoute(
        path: '/contact-details/:contactId',
        builder: (_, state) {
          final page = state.extra is ContactDetailsPage
              ? state.extra! as ContactDetailsPage
              : null;
          return ContactDetailsScreen(
            contactId: state.pathParameters['contactId']!,
            badges: page?.badges,
          );
        },
      ),
    ],
  );
}

@pragma('vm:entry-point')
void add2appMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await KeyValueStorage.instance.init();

  final path = Add2AppNavigator.initialPath;
  final route = await Add2AppNavigator.fetchInitialRoute(
    decodeFlutterRouteData,
  );
  final router = createRouter(
    initialLocation: path,
    initialExtra: route,
  );

  runApp(
    MaterialApp.router(
      routeInformationProvider: router.routeInformationProvider,
      routeInformationParser: router.routeInformationParser,
      routerDelegate: router.routerDelegate,
      backButtonDispatcher: Add2AppBackButtonDispatcher(),
      builder: (_, child) => Add2AppNativePopGestureObserver(
        child: child ?? const SizedBox.shrink(),
      ),
    ),
  );
}
```

#### auto_route example

```dart
RootStackRouter createRouter() {
  return RootStackRouter.build(
    routes: [
      NamedRouteDef(
        name: 'SoundsNotificationsRoute',
        path: '/sounds-notifications/:contactId',
        builder: (_, data) => SoundsNotificationsScreen(
          contactId: data.params.getString('contactId'),
        ),
      ),
      NamedRouteDef(
        name: 'ContactDetailsRoute',
        path: '/contact-details/:contactId',
        builder: (_, data) => ContactDetailsScreen(
          contactId: data.params.getString('contactId'),
        ),
      ),
    ],
  );
}

@pragma('vm:entry-point')
void add2appMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await KeyValueStorage.instance.init();

  final initialLocation = Add2AppNavigator.initialPath;
  final router = createRouter();

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
      builder: (_, child) => Add2AppNativePopGestureObserver(
        child: child ?? const SizedBox.shrink(),
      ),
    ),
  );
}
```

#### Other routing libraries

For any routing library that works with `MaterialApp.router`, the framework provides `Add2AppRouteInformationProvider` — a drop-in replacement for `PlatformRouteInformationProvider` that seeds the router with the correct initial path:

```dart
MaterialApp.router(
  routeInformationProvider: Add2AppRouteInformationProvider(),
  routeInformationParser: myCustomParser,
  routerDelegate: myCustomDelegate,
  backButtonDispatcher: Add2AppBackButtonDispatcher(),
  builder: (_, child) => Add2AppNativePopGestureObserver(
    child: child ?? const SizedBox.shrink(),
  ),
)
```

### Imperative (sealed class + pattern matching)

If you don't use a declarative routing library, the framework supports a fully imperative approach using Dart's sealed classes and pattern matching. Instead of mapping URL paths to routes, you decode `PageSettings` into a typed `FlutterRoute` and use a `switch` expression for exhaustive, type-safe route resolution — no strings, no handler classes, no abstract methods to override.

#### How it works

1. The code generator produces a `sealed class FlutterRoute` with a subclass for every `@Add2AppFlutterRoute`. All route classes extend this sealed type.
2. The generated `decodeFlutterRouteData` function decodes `PageSettings` into the sealed `FlutterRoute?` type.
3. You use `Add2AppNavigator.fetchInitialRoute(decodeFlutterRouteData)` to get the typed route, then pattern-match on it with a `switch` expression. The compiler enforces exhaustiveness — if you add a new route, you get a compile error until you handle it.

#### Wire up in the entrypoint

```dart
@pragma('vm:entry-point')
void add2appMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await KeyValueStorage.instance.init();

  final route = await Add2AppNavigator.fetchInitialRoute(
    decodeFlutterRouteData,
  );

  final widget = switch (route) {
    ContactDetailsPage(:final contactId) =>
      ContactDetailsScreen(contactId: contactId),
    SoundsNotificationsPage(:final contactId) =>
      SoundsNotificationsScreen(contactId: contactId),
    SetWallpaperPage(:final recipientId) =>
      SetWallpaperScreen(recipientId: recipientId),
    null => const HomeScreen(),
  };

  runApp(MaterialApp(home: widget));
}
```

The sealed `FlutterRoute` hierarchy gives you:
- **Exhaustive pattern matching** — the Dart compiler ensures every route is handled. Adding a new `@Add2AppFlutterRoute` makes the `switch` non-exhaustive, producing a compile error until you add a case.
- **Field destructuring** — extract route fields directly in the pattern (e.g. `ContactDetailsPage(:final contactId)`) without manually accessing them from a page object.
- **No boilerplate** — no handler class to extend, no interface to implement, no abstract methods. Just a `switch` expression.
- **`null` handles unknowns** — `decodeFlutterRouteData` returns `null` for unrecognized route IDs (including the prewarm engine's placeholder), so you handle them naturally in the `null` branch.

`fetchInitialRoute` retrieves the full route data (including non-path parameters like lists and complex objects) from the native host and returns the sealed type for exhaustive matching.

Note that this approach uses a plain `MaterialApp` — not `MaterialApp.router` — because there's no declarative router involved.

## Setup

### Native Initialization

Call once at app startup to create the engine group. Both `start()` and `init()` accept an optional `prewarm` parameter (defaults to `true`) that controls whether a hidden engine is prewarmed immediately.

**iOS (AppDelegate):**

```swift
Add2AppNavigator.shared.start() // prewarm: true by default
Add2AppNavigator.shared.setNativeRouteHandler(MyNativeRouteHandler())
```

**Android (Application.onCreate):**

```kotlin
Add2AppNavigator.init(applicationContext) // prewarm = true by default
Add2AppNavigator.setNativeRouteHandler(MyNativeRouteHandler())
```

### Engine Prewarming

By default the framework keeps a hidden prewarmed engine so the first Flutter navigation feels instant. You can control this:

```swift
// iOS
Add2AppNavigator.shared.setPrewarmEnabled(false)
Add2AppNavigator.shared.destroyPrewarmedEngine()
```

```kotlin
// Android
Add2AppNavigator.setPrewarmEnabled(false)
Add2AppNavigator.destroyPrewarmedEngine()
```

## How It Works Under the Hood

1. **Native init** — `start()` / `init()` creates a `FlutterEngineGroup` and optionally prewarms one engine.
2. **Push** — When a route is pushed, the framework encodes `PageSettings` into a URL string, creates a new engine from the group, and presents it in a native container (Activity / ViewController).
3. **Dart entrypoint** — Every engine runs the same Dart entrypoint (`add2appMain`). A routing library reads the initial path to render the correct screen, or the imperative approach decodes `PageSettings` into a sealed `FlutterRoute` for pattern matching.
4. **Pop** — Dismissing the native container destroys the engine and cleans up platform channel registrations.

Routes are serialized as:

```
/path/with/:params?extraParam=value
```

The Dart side decodes this with `Add2AppNavigator.initialPath`.
