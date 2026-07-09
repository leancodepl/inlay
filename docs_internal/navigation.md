# Navigation

The framework provides type-safe, cross-boundary navigation between native (iOS/Android) and Flutter screens.

The framework uses a multi-engine approach: when native code navigates to a Flutter screen, a new native container (Activity on Android, ViewController on iOS) is created with its own Flutter engine. Consecutive Flutter screens within that container share the same engine and its Flutter navigation stack. A new engine is only created when a native screen needs to appear between Flutter screens. All engines share resources via a `FlutterEngineGroup`, so spinning up a new one is lightweight. You never manage engines directly.

## Background for Native Developers

A few Flutter concepts referenced in this guide:

- **Flutter engine** - A runtime that executes Dart code and renders Flutter UI. Each engine hosts its own Flutter navigation stack, so consecutive Flutter screens share one engine. A new engine is only needed when a native screen appears between Flutter screens (e.g. Flutter → **Native** → Flutter requires two engines). This framework uses a **multi-engine** approach to allow freely interleaving native and Flutter screens.
- **`FlutterEngineGroup`** - An API that lets multiple engines share resources (compiled code, fonts, images), making the multi-engine approach lightweight. The framework manages this for you.
- **`MaterialApp.router`** - The standard Flutter way to use a declarative routing library (like go_router or auto_route). The framework plugs into this system so the correct screen opens when a new engine starts.

## Concepts

- **Flutter route** - A screen rendered by Flutter. Navigating to it from native code creates a new engine inside a native container (Activity / ViewController). Navigating to it from within Flutter uses the existing engine's navigation stack.
- **Flutter dialog route** - A dialog, bottom sheet, or action sheet rendered by Flutter over a native screen. The native side opens a transparent container so the underlying screen stays visible. Flutter renders the overlay content (barrier, animation, positioning). Uses the same engine-per-container model as regular routes.
- **Native route** - A screen rendered by the native platform. Flutter can request navigation to it, and the native side decides how to present it.
- **`InlayNavigator`** - The singleton that orchestrates all cross-boundary navigation. Accessed as `InlayNavigator.instance` (Dart), `InlayNavigator.shared` (iOS), or the `InlayNavigator` object (Android).
- **`PageSettings`** - A data class that carries a `routeId`, optional `params`, and optional `path` across the platform boundary. Generated route classes create this for you - you rarely touch it directly.

## Defining Routes

Routes are defined as plain Dart classes with annotations. Running the code generator produces type-safe route classes for **Dart, Swift, and Kotlin** so every platform gets compile-time safety.

### Flutter Routes

Annotate with `@InlayFlutterRoute` and provide a **path template**. The path determines the URL passed to the Flutter routing library (go_router, auto_route, etc.) when a new engine starts - it's how the framework tells the router which screen to display.

Path parameters (`:param`) map to required fields on the class.

```dart
@InlayFlutterRoute('/contact-details/:contactId')
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

### Flutter Dialog Routes

Annotate with `@InlayFlutterDialog` for overlays (dialogs, bottom sheets, action sheets) that are rendered by Flutter but presented over a native screen. The native side opens a **transparent** container so the underlying screen stays visible, and Flutter renders the dialog content (barrier, animation, positioning).

```dart
@InlayFlutterDialog('/confirm-delete/:itemId')
class ConfirmDeleteDialog {
  const ConfirmDeleteDialog({required this.itemId, this.title});

  final String itemId;
  final String? title;
}
```

The generator produces:

- A Dart class extending the generated `sealed class FlutterDialogRoute` (which extends `FlutterDialogRouteBase`) - separate from `FlutterRoute` so you can distinguish pages from dialogs in pattern matching
- A Swift struct conforming to `FlutterDialogRoute` / Kotlin data class implementing `FlutterDialogRoute`

Dialog routes work identically to page routes in the schema - they have path templates, support path and query parameters, and get the same serialization. The only difference is in how the native side presents them (transparent container instead of opaque).

### Native Routes

Annotate with `@InlayNativeRoute` for screens that live on the native side.

```dart
@InlayNativeRoute()
class NativeEditProfilePage {
  const NativeEditProfilePage({required this.contactId});
  final String contactId;
}
```

The generator produces:

- A Dart class with a `toNativeRoute()` method for use in `InlayNavigator.instance.push()`
- A typed handler method in the generated `NativeRouteHandler` base class (Swift and Kotlin), so you implement native navigation with full type safety

## Navigating

### From Flutter (Dart)

All navigation goes through `InlayNavigator.instance.push()`:

```dart
// Open a Flutter screen (creates a new native container + engine)
await InlayNavigator.instance.push(
  ContactDetailsPage(contactId: 'abc-123'),
);

// Open a native screen
await InlayNavigator.instance.push(
  NativeEditProfilePage(contactId: 'abc-123').toNativeRoute(),
);

// Close the current screen (dismisses the native container)
await InlayNavigator.instance.pop();
```

### From iOS (Swift)

```swift
// Push onto the UIKit navigation stack
InlayNavigator.shared.push(
  from: viewController,
  route: ContactDetailsPage(contactId: "abc-123"),
  animated: true
)

// Present modally
InlayNavigator.shared.present(
  from: viewController,
  route: ContactDetailsPage(contactId: "abc-123"),
  animated: true
)

// Or create a ViewController manually for custom presentation
let vc = InlayNavigator.shared.createFlutterViewController(
  route: ContactDetailsPage(contactId: "abc-123")
)
```

For **SwiftUI**, use the provided wrapper:

```swift
NavigationStack {
  InlayFlutterView(route: ContactDetailsPage(contactId: "abc-123"))
}
```

### From Android (Kotlin)

```kotlin
// Start a new Activity
InlayNavigator.push(context, ContactDetailsPage(contactId = "abc-123"))

// Or create a Fragment for embedding in an existing Activity
val fragment = InlayNavigator.createFragment(
  context, ContactDetailsPage(contactId = "abc-123")
)
```

For **Jetpack Compose**, add the optional `inlay_compose` plugin and use the provided composable:

```yaml
# pubspec.yaml of your Flutter module
dependencies:
  inlay:
    path: ../path/to/inlay
  inlay_compose:
    path: ../path/to/inlay_compose
```

```kotlin
import co.leancode.inlay.compose.InlayFlutterScreen

InlayFlutterScreen(route = ContactDetailsPage(contactId = "abc-123"))
```

Projects that don't use Compose should depend only on `inlay` - no Compose dependencies end up on the classpath. Use `InlayNavigator.push(...)` or `InlayNavigator.createFragment(...)` directly in that case.

#### Host Activity forwarding

`InlayFlutterFragment` extends Flutter's `FlutterFragment`, which requires the host Activity to forward seven callbacks - without them deep links, back handling, user-leave events, and memory trimming don't reach Flutter. This applies to any Activity that hosts an `InlayFlutterFragment` directly, via `InlayFlutterScreen` from the `inlay_compose` plugin, or via `InlayFlutterDialogFragment`.

The simplest option is to extend [`InlayFlutterHostActivity`](../inlay/android/src/main/kotlin/co/leancode/inlay/InlayFlutterHostActivity.kt), which wires the forwarding for you.

If you need a different base class (for example `AppCompatActivity`), use [`InlayFragmentHostDelegate`](../inlay/android/src/main/kotlin/co/leancode/inlay/InlayFragmentHostDelegate.kt) from your own Activity overrides:

```kotlin
class MyActivity : AppCompatActivity() {
  private val inlayHost by lazy { InlayFragmentHostDelegate(this) }

  override fun onPostResume() { super.onPostResume(); inlayHost.onPostResume() }
  override fun onNewIntent(intent: Intent) { super.onNewIntent(intent); inlayHost.onNewIntent(intent) }
  override fun onBackPressed() {
    if (!inlayHost.onBackPressed()) super.onBackPressed()
  }
  override fun onUserLeaveHint() { super.onUserLeaveHint(); inlayHost.onUserLeaveHint() }
  override fun onTrimMemory(level: Int) { super.onTrimMemory(level); inlayHost.onTrimMemory(level) }
  override fun onActivityResult(r: Int, rc: Int, d: Intent?) {
    super.onActivityResult(r, rc, d); inlayHost.onActivityResult(r, rc, d)
  }
  override fun onRequestPermissionsResult(r: Int, p: Array<out String>, g: IntArray) {
    super.onRequestPermissionsResult(r, p, g); inlayHost.onRequestPermissionsResult(r, p, g)
  }
}
```

The delegate walks the whole Fragment tree, so nested `InlayFlutterFragment`s (including the one inside `InlayFlutterDialogFragment`) are covered automatically.

### Dialogs

Dialog routes are presented in a transparent native container so the underlying screen remains visible. Flutter renders the dialog content, barrier, and animations.

#### From Flutter (Dart)

```dart
// Present a dialog over the current native screen
await InlayNavigator.instance.push(
  ConfirmDeleteDialog(itemId: '42'),
);
```

This works the same as a regular `push()` - the framework detects the `flutterDialog` route type and uses `presentDialog` instead of `push` on the native side.

#### From iOS (Swift)

**UIKit:**

```swift
InlayNavigator.shared.presentDialog(
  from: viewController,
  route: ConfirmDeleteDialog(itemId: "42")
)
```

**SwiftUI:**

```swift
@State private var showDialog = false

var body: some View {
    Button("Delete") { showDialog = true }
        .inlayDialog(
            isPresented: $showDialog,
            route: ConfirmDeleteDialog(itemId: "42"),
            onResult: { confirmed in
                // confirmed: Bool? - already decoded
            }
        )
}
```

The `.inlayDialog` modifier uses UIKit's `.overFullScreen` presentation under the hood, so the background stays visible. For dialog routes declaring `result:`, `onResult` is invoked exactly once - with the decoded result, or `nil` on dismissal without one.

#### From Android (Kotlin)

**Activity / Fragment:**

```kotlin
InlayNavigator.presentDialog(activity, ConfirmDeleteDialog(itemId = "42"))
```

This shows an `InlayFlutterDialogFragment` - a `DialogFragment` with a transparent fullscreen window.

**Jetpack Compose** - add the `inlay_compose` plugin (see above) and drive `InlayFlutterDialog` from state, the same shape as SwiftUI's `.inlayDialog`:

```kotlin
import co.leancode.inlay.compose.InlayFlutterDialog

var showDialog by remember { mutableStateOf(false) }

Button(onClick = { showDialog = true }) { Text("Delete") }
InlayFlutterDialog(
    isPresented = showDialog,
    route = ConfirmDeleteDialog(itemId = "42"),
    onDismissRequest = { showDialog = false },
    onResult = { confirmed ->
        // confirmed: Boolean? - already decoded
    },
)
```

While `isPresented` is `true` the framework's transparent `InlayFlutterDialogFragment` is shown over the Activity. Do **not** wrap it in a Compose `Dialog` or a Compose Navigation `dialog()` destination - a `FragmentManager` cannot attach fragments inside a Compose dialog window, and the fragment manages its own window anyway. `onDismissRequest` fires when the dialog goes away for any reason (Flutter pop, barrier tap, back); for dialog routes declaring `result:`, `onResult` is invoked exactly once - with the decoded result, or `null` on dismissal without one. `InlayFlutterScreen` and `InlayNavigator.createFragment` take the same typed `onResult` parameter for full-screen embeds.

## Handling Native Routes (Flutter → Native)

When Flutter pushes a native route, the framework dispatches it to a `NativeRouteHandler` you register on the native side. The generated handler has a typed method for each `@InlayNativeRoute`, so you don't parse strings.

### iOS

```swift
// Register once (e.g. in AppDelegate)
InlayNavigator.shared.setNativeRouteHandler(MyNativeRouteHandler())

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
InlayNavigator.setNativeRouteHandler(object : NativeRouteHandler() {
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

1. **Declarative** - Works with `MaterialApp.router` and any Navigator 2.0 routing library (go_router, auto_route, etc.). The framework passes the initial route as a URL path and the router matches it to a screen. Dialog routes use `InlayDialogPage` / `InlayBottomSheetPage`.
2. **Imperative** - Works with plain `MaterialApp` and no routing library. The generated `sealed class FlutterRoute` / `sealed class FlutterDialogRoute` hierarchies let you use Dart pattern matching for exhaustive, type-safe route resolution. Dialog routes use `runInlayDialog`.

### Declarative (MaterialApp.router)

The framework encodes the route as a URL path (e.g. `/contact-details/abc-123`) and passes it as the initial route for the new Flutter engine. A routing library on the Dart side matches that path to a widget.

There are two integration points:

- **`InlayNavigator.initialPath`** - reads the platform's `defaultRouteName` and returns the URL path. You pass this to your routing library as the initial location. This is synchronous and carries path parameters only.
- **`InlayNavigator.fetchInitialRoute(decoder)`** - fetches the full route data (including non-path parameters like lists and complex objects) from the native host and decodes it into a typed route object. Pass this as extra data to your router so builders can access non-path parameters. Use `decodeFlutterRouteData` if you only have page routes, or `decodeInlayRouteData` if you have both pages and dialogs.

If your routes only use path parameters, `initialPath` alone is sufficient. If any route has non-path parameters (e.g. `List<ContactBadge>? badges`), you need both.

`InlayBackButtonDispatcher` ensures that when the user presses back and the router stack is empty, the native container (Activity/ViewController) is dismissed instead of doing nothing.

`InlayNativePopGestureObserver` syncs the iOS interactive back-swipe gesture with the Flutter navigation stack. Without it, the native swipe-back gesture may dismiss the entire Flutter container even when there are in-Flutter routes to pop. Wrap it around the router's child via `MaterialApp.router`'s `builder`.

#### go_router example

```dart
GoRouter createRouter({
  String initialLocation = '/',
  InlayRoute? initialExtra,
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
      // Dialog routes use pageBuilder with InlayDialogPage
      GoRoute(
        path: '/confirm-delete/:itemId',
        pageBuilder: (_, state) {
          final dialog = state.extra is ConfirmDeleteDialog
              ? state.extra! as ConfirmDeleteDialog
              : null;
          return InlayDialogPage(
            builder: (_) => ConfirmDeleteContent(
              itemId: dialog?.itemId ?? state.pathParameters['itemId']!,
            ),
          );
        },
      ),
      // Bottom sheet routes use InlayBottomSheetPage
      GoRoute(
        path: '/theme-picker/:userId',
        pageBuilder: (_, state) => InlayBottomSheetPage(
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => ThemePickerContent(
            userId: state.pathParameters['userId']!,
          ),
        ),
      ),
    ],
  );
}

@pragma('vm:entry-point')
void inlayMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await KeyValueStorage.instance.init();

  final path = InlayNavigator.initialPath;
  // Use decodeInlayRouteData (combined decoder) when you have both
  // page routes and dialog routes. It tries page routes first, then dialogs.
  final route = await InlayNavigator.fetchInitialRoute(
    decodeInlayRouteData,
  );
  final router = createRouter(
    initialLocation: path,
    initialExtra: route,
  );

  // Dialog routes need a transparent scaffold background
  final isDialog = route is FlutterDialogRouteBase;

  runApp(
    MaterialApp.router(
      theme: isDialog
          ? ThemeData.light().copyWith(
              scaffoldBackgroundColor: Colors.transparent,
            )
          : ThemeData.light(),
      routeInformationProvider: router.routeInformationProvider,
      routeInformationParser: router.routeInformationParser,
      routerDelegate: router.routerDelegate,
      backButtonDispatcher: InlayBackButtonDispatcher(),
      builder: (_, child) => InlayNativePopGestureObserver(
        child: child ?? const SizedBox.shrink(),
      ),
    ),
  );
}
```

**Key points for dialog routes in go_router:**

- Use `pageBuilder` (not `builder`) so you can return `InlayDialogPage` or `InlayBottomSheetPage`
- `InlayDialogPage` shows an `AlertDialog`-style overlay. Parameters like `barrierDismissible` and `barrierColor` are configurable.
- `InlayBottomSheetPage` shows a modal bottom sheet. Parameters like `isScrollControlled`, `isDismissible`, `enableDrag`, and `showDragHandle` are configurable.
- Both pages automatically call `InlayNavigator.instance.pop()` when the dialog/sheet is dismissed, closing the native transparent container
- The `MaterialApp` theme must set `scaffoldBackgroundColor: Colors.transparent` for dialog engines so the native screen shows through
- Routers that manage their own page types (e.g. auto_route) can't host these `Page`s - use the underlying `InlayDialogLauncher` / `InlayBottomSheetLauncher` widgets inside a transparent zero-transition route instead (see the auto_route example below). Same options, same auto-pop behavior.

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
      // Dialog routes: auto_route manages its own page types, so
      // InlayDialogPage can't be returned from a builder. Use the
      // launcher widgets inside a transparent zero-transition route.
      NamedRouteDef(
        name: 'ConfirmDeleteDialogRoute',
        path: '/confirm-delete/:itemId',
        type: const RouteType.custom(opaque: false, duration: Duration.zero),
        builder: (_, data) => InlayDialogLauncher<bool>(
          encodeResult: ConfirmDeleteDialog.encodeResult,
          builder: (_) => ConfirmDeleteContent(
            itemId: data.params.getString('itemId'),
          ),
        ),
      ),
    ],
  );
}

@pragma('vm:entry-point')
void inlayMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await KeyValueStorage.instance.init();

  final initialLocation = InlayNavigator.initialPath;
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
      backButtonDispatcher: InlayBackButtonDispatcher(),
      builder: (_, child) => InlayNativePopGestureObserver(
        child: child ?? const SizedBox.shrink(),
      ),
    ),
  );
}
```

#### Other routing libraries

For any routing library that works with `MaterialApp.router`, the framework provides `InlayRouteInformationProvider` - a drop-in replacement for `PlatformRouteInformationProvider` that seeds the router with the correct initial path:

```dart
MaterialApp.router(
  routeInformationProvider: InlayRouteInformationProvider(),
  routeInformationParser: myCustomParser,
  routerDelegate: myCustomDelegate,
  backButtonDispatcher: InlayBackButtonDispatcher(),
  builder: (_, child) => InlayNativePopGestureObserver(
    child: child ?? const SizedBox.shrink(),
  ),
)
```

### Imperative (sealed class + pattern matching)

If you don't use a declarative routing library, the framework supports a fully imperative approach using Dart's sealed classes and pattern matching. Instead of mapping URL paths to routes, you decode `PageSettings` into a typed `FlutterRoute` and use a `switch` expression for exhaustive, type-safe route resolution - no strings, no handler classes, no abstract methods to override.

#### How it works

1. The code generator produces a `sealed class FlutterRoute` (for pages) and optionally a `sealed class FlutterDialogRoute` (for dialogs). Each `@InlayFlutterRoute` / `@InlayFlutterDialog` becomes a subclass of the respective sealed type.
2. The generated `decodeInlayRouteData` function decodes `PageSettings` into either type (returning `InlayRoute?`).
3. You use `InlayNavigator.fetchInitialRoute(decodeInlayRouteData)` to get the typed route, then pattern-match with a `switch` expression. The compiler enforces exhaustiveness - if you add a new route, you get a compile error until you handle it.

#### Wire up in the entrypoint

```dart
@pragma('vm:entry-point')
void inlayMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await KeyValueStorage.instance.init();

  final route = await InlayNavigator.fetchInitialRoute(
    decodeInlayRouteData,
  );

  switch (route) {
    // Page routes - use a regular MaterialApp
    case ContactDetailsPage(:final contactId):
      runApp(MaterialApp(
        home: ContactDetailsScreen(contactId: contactId),
      ));
    case SoundsNotificationsPage(:final contactId):
      runApp(MaterialApp(
        home: SoundsNotificationsScreen(contactId: contactId),
      ));

    // Dialog routes - use runInlayDialog with standard Flutter APIs
    case ConfirmDeleteDialog(:final itemId, :final title):
      runInlayDialog(
        onReady: (context) => showDialog(
          context: context,
          builder: (_) => ConfirmDeleteContent(itemId: itemId, title: title),
        ),
      );
    case ThemePickerDialog(:final userId):
      runInlayDialog(
        onReady: (context) => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => ThemePickerContent(userId: userId),
        ),
      );

    case null:
      runApp(const MaterialApp(home: HomeScreen()));
  }
}
```

`runInlayDialog` sets up a transparent `MaterialApp` and calls your `onReady` callback after the first frame. When the dialog/sheet is dismissed, the native transparent container is automatically closed. You use standard Flutter APIs (`showDialog`, `showModalBottomSheet`, etc.) inside the callback - the framework doesn't impose any special dialog widget.

The sealed class hierarchies give you:

- **Exhaustive pattern matching** - the Dart compiler ensures every route is handled. Adding a new `@InlayFlutterRoute` or `@InlayFlutterDialog` makes the `switch` non-exhaustive, producing a compile error until you add a case.
- **Field destructuring** - extract route fields directly in the pattern (e.g. `ConfirmDeleteDialog(:final itemId)`) without manually accessing them from a page object.
- **No boilerplate** - no handler class to extend, no interface to implement, no abstract methods. Just a `switch` expression.
- **`null` handles unknowns** - `decodeInlayRouteData` returns `null` for unrecognized route IDs (including the prewarm engine's placeholder), so you handle them naturally in the `null` branch.

`fetchInitialRoute` retrieves the full route data (including non-path parameters like lists and complex objects) from the native host and returns the sealed type for exhaustive matching.

Note that this approach uses a plain `MaterialApp` - not `MaterialApp.router` - because there's no declarative router involved.

## Setup

### Native Initialization

Call once at app startup to create the engine group. Both `start()` and `init()` accept an optional `prewarm` parameter (defaults to `true`) that controls whether a hidden engine is prewarmed immediately.

**iOS (AppDelegate):**

```swift
// Register plugins on every engine inlay creates. The iOS embedding does
// not do this automatically - without it, every plugin with native iOS
// code throws MissingPluginException on inlay's engines.
InlayNavigator.shared.setOnEngineCreated { engine in
    GeneratedPluginRegistrant.register(with: engine)
}
InlayNavigator.shared.start() // prewarm: true by default
InlayNavigator.shared.setNativeRouteHandler(MyNativeRouteHandler())
```

**Android (Application.onCreate):**

```kotlin
InlayNavigator.init(applicationContext) // prewarm = true by default
InlayNavigator.setNativeRouteHandler(MyNativeRouteHandler())
```

### Plugin Registration (`setOnEngineCreated`)

Flutter plugins register **per engine**. On Android the Flutter embedding invokes
`GeneratedPluginRegistrant` automatically for every engine, so nothing is needed there.
On iOS registration is manual, and since inlay creates engines internally, the host can't
reach them directly - `setOnEngineCreated` is the hook for that. The callback runs exactly
once per engine (including the hidden prewarmed engine), right after the engine starts.

- Set the callback **before** `start()` so the prewarmed engine is covered. If a prewarmed
  engine already exists when the callback is set, it is invoked on it immediately.
- On Android, `setOnEngineCreated` also exists, but do **not** register plugins in it (they
  register automatically - doing it again would double-register). Use it for other per-engine
  setup, e.g. custom platform channels or platform view factories.
- `GeneratedPluginRegistrant` on iOS lives in the `FlutterPluginRegistrant` pod (source
  integration via `podhelper.rb`) - `import FlutterPluginRegistrant` in the AppDelegate.

### Returning Results from Screens

Declare a result type on a route annotation and the generator emits typed plumbing:

```dart
@InlayFlutterDialog('/confirm-action/:action', result: bool)   // Flutter dialog -> bool
@InlayFlutterRoute('/counter', result: int)                    // Flutter screen -> int
@InlayNativeRoute(result: String)                              // native screen -> String
```

The result type joins the schema fingerprint. Dismissal without an explicit result delivers
`null`, exactly once.

**Native → Flutter** (native awaits): `push`/`presentDialog` take an `onResult` callback;
so do the declarative wrappers - SwiftUI's `.inlayDialog(onResult:)` and Compose's
`InlayFlutterScreen`/`InlayFlutterDialog` (`onResult =`). The callbacks are **typed**:
routes declaring `result:` generate classes implementing `FlutterRouteWithResult<R>` /
`FlutterDialogRouteWithResult<R>` (Kotlin) or conforming to `FlutterRouteWithResult` /
`FlutterDialogRouteWithResult` (Swift, `ResultValue` associated type), and the generic
overloads deliver an already-decoded `R?` - no casts, no `decodeResult` at call sites
(the raw `decodeResult`/`encodeResult` codecs remain for the low-level `PageSettings`
APIs). The Flutter screen returns via `Route.popWithResult(value)` (full screen) or an
`InlayDialogPage`/`InlayBottomSheetPage`'s `encodeResult:` + `Navigator.pop(context, value)`
(dialog/sheet).

**Flutter → native / Flutter → Flutter** (Flutter awaits): the generated route class exposes
`Future<R?> pushForResult()`. On the native side, the generated `NativeRouteHandler` method for
a result-typed route gains a `completion: (R) -> Unit/Void` the developer invokes.

Transport: `InlayNavigatorHostApi` gained `@async pushForResult` / `presentDialogForResult` /
`pushNativeRouteForResult`, and `pop(result)` carries the value back. Per-container result
callbacks live in process memory (Android: keyed by an Intent/dialog id; not restored across
process death).

### Schema Fingerprint (automatic drift detection)

The generated Dart compiles into the module and the generated Kotlin/Swift compile into the
hosts, so the two binaries can be built from different schema revisions. Serialization is
positional, which turns such drift into silent corruption or crashes. `inlay_gen` therefore
emits a stable **schema fingerprint** into every language's output (Dart:
`inlaySchemaFingerprint`, Kotlin: `InlaySchema.FINGERPRINT`, Swift: `InlaySchema.fingerprint`)
and wires the check into the generated code itself - no app code involved:

- Every generated `toPageSettings()` embeds the sender's fingerprint into `PageSettings`
  (`schemaFingerprint` field).
- Native → Flutter: the generated Dart decoders (`decodeFlutterRouteData`,
  `decodeFlutterDialogRouteData`, `decodeInlayRouteData`) verify the incoming fingerprint
  and throw an `InlaySchemaMismatchException` naming both fingerprints on mismatch.
  `fetchInitialRoute` deliberately rethrows it (unlike other decode errors), so the
  engine fails loudly instead of falling back to a path-only render.
- Flutter → native: the generated `NativeRouteHandler` verifies before dispatching
  (`IllegalStateException` on Android - surfaced to the Dart caller as a
  `PlatformException` - and `fatalError` on iOS).

A `PageSettings` without a fingerprint (hand-built, or produced by pre-fingerprint
generated code) skips the check.

### Engine Prewarming

By default the framework keeps a hidden prewarmed engine so the first Flutter navigation feels instant. You can control this:

```swift
// iOS
InlayNavigator.shared.setPrewarmEnabled(false)
InlayNavigator.shared.destroyPrewarmedEngine()
InlayNavigator.shared.isPrewarmEnabled // read current state
```

```kotlin
// Android
InlayNavigator.setPrewarmEnabled(false)
InlayNavigator.destroyPrewarmedEngine()
InlayNavigator.isPrewarmEnabled // read current state
```

### Dart Entrypoint

Every engine runs a single Dart entrypoint, `inlayMain` by default. It can be changed - e.g. to switch between routing integrations, or to point inlay at a dedicated entrypoint in a module that also runs standalone:

```swift
// iOS
InlayNavigator.shared.setDartEntrypoint("inlayAutoRouteMain")
```

```kotlin
// Android
InlayNavigator.setDartEntrypoint("inlayAutoRouteMain")
```

The entrypoint must be a top-level function in the Flutter module annotated with `@pragma('vm:entry-point')`. Engines that are already running keep their entrypoint; the hidden prewarmed engine is recreated so the next navigation uses the new one. The example app exposes this on its native settings screens to switch between the go_router, auto_route, and imperative routing demos at runtime.

## How It Works Under the Hood

1. **Native init** - `start()` / `init()` creates a `FlutterEngineGroup` and optionally prewarms one engine.
2. **Push** - When a route is pushed, the framework encodes `PageSettings` into a URL string, creates a new engine from the group, and presents it in a native container (Activity / ViewController).
3. **Present dialog** - For dialog routes, the native side creates a transparent container (`DialogFragment` on Android, `.overFullScreen` modal on iOS) instead of an opaque one. The engine starts the same way, but Flutter renders over the visible native screen underneath.
4. **Dart entrypoint** - Every engine runs the same Dart entrypoint (`inlayMain` by default, configurable via `setDartEntrypoint`). A routing library reads the initial path to render the correct screen, or the imperative approach decodes `PageSettings` into a sealed `FlutterRoute` / `FlutterDialogRoute` for pattern matching.
5. **Pop** - Dismissing the native container destroys the engine and cleans up platform channel registrations. For dialogs, Flutter's `InlayNavigator.instance.pop()` is called automatically when the dialog/sheet is dismissed.

Routes are serialized as:

```
/path/with/:params?extraParam=value
```

The Dart side decodes this with `InlayNavigator.initialPath`.
