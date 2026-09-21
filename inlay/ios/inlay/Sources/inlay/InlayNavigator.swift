import Foundation
import Flutter

/// Protocol for handling native route requests dispatched from Flutter.
///
/// The generated `NativeRouteHandler` class conforms to this protocol,
/// dispatching `PageSettings` to typed `on*` methods. Developers subclass
/// the generated class rather than implementing this protocol directly.
///
/// [completion] must be invoked exactly once with the screen's result
/// (`nil` for routes without one) - it completes the awaiting Dart future
/// when the route was pushed via `pushForResult()`.
public protocol NativeRouteHandling: AnyObject {
    func handle(
        viewController: UIViewController,
        route: PageSettings,
        completion: @escaping (Any?) -> Void
    )
}

/// Framework-level navigator that hides all Flutter internals
/// (`FlutterEngine`, `FlutterEngineGroup`, `FlutterViewController`, platform channels)
/// from the developer.
///
/// Usage from native iOS:
/// ```swift
/// // One-time setup (e.g. AppDelegate.didFinishLaunching)
/// InlayNavigator.shared.start()
///
/// // Navigate to a Flutter page from any UIViewController
/// InlayNavigator.shared.push(
///     from: self,
///     page: PageSettings(routeId: "soundsNotifications", params: ["contactId": "42"])
/// )
/// ```
///
/// Usage from Flutter (via Pigeon-generated `InlayNavigatorHostApi`):
/// ```dart
/// InlayNavigator.instance.push(SoundsNotificationsPage(contactId: '42'));
/// InlayNavigator.instance.pop();
/// ```
///
/// Navigation from Flutter to native screens:
/// ```swift
/// // Set the generated native route handler (e.g. AppDelegate.didFinishLaunching)
/// InlayNavigator.shared.setNativeRouteHandler(SignalNativeRouteHandler())
/// ```
/// ```dart
/// // From Flutter:
/// InlayNavigator.instance.pushNativeRoute(
///   NativeEditProfilePage(contactId: '42').toPageSettings(),
/// );
/// ```
///
/// The navigator automatically:
/// - Manages the `FlutterEngineGroup` singleton.
/// - Creates a generic `InlayFlutterViewController` for every push.
/// - Registers the Pigeon HostApi on each engine so Flutter can push/pop too.
/// - Attaches `KeyValueStorageImpl` to each engine.
///
/// Plugin registration is **not** automatic on iOS. If the Flutter module
/// uses plugins with native iOS code, register them per engine via
/// ``setOnEngineCreated(_:)``.
public final class InlayNavigator {

    // MARK: - Singleton

    public static let shared = InlayNavigator()

    private init() {}

    // MARK: - Engine group

    /// Single `FlutterEngineGroup` shared across all inlay pages.
    private(set) var engineGroup: FlutterEngineGroup?

    /// The Dart entrypoint used by all inlay pages. Defaults to `inlayMain`.
    public private(set) var dartEntrypoint = "inlayMain"
    /// Internal route used only for hidden engine warm-up.
    private static let prewarmRouteId = "__inlay_prewarm__"

    /// The single native route handler set by the app.
    private var nativeRouteHandler: NativeRouteHandling?
    /// Per-engine setup hook invoked once for every engine inlay creates.
    private var onEngineCreated: ((FlutterEngine) -> Void)?
    /// Whether `start()` should prewarm a hidden engine.
    public private(set) var isPrewarmEnabled = true
    /// Hidden warm-up engine kept alive for app lifetime.
    private var prewarmedEngine: FlutterEngine?

    // MARK: - Initialisation

    /// Set a callback invoked exactly once for every `FlutterEngine` inlay
    /// creates — including the hidden prewarmed engine — right after the
    /// engine starts running.
    ///
    /// The iOS embedding does not register plugins automatically, so every
    /// plugin with native iOS code stays unregistered on inlay's engines
    /// (`MissingPluginException` at runtime) until the host registers it
    /// per engine. This callback is the place to do that:
    ///
    /// ```swift
    /// // In AppDelegate.didFinishLaunching, before start():
    /// InlayNavigator.shared.setOnEngineCreated { engine in
    ///     GeneratedPluginRegistrant.register(with: engine)
    /// }
    /// InlayNavigator.shared.start()
    /// ```
    ///
    /// Set the callback before `start()` so the prewarmed engine is covered
    /// from the beginning. If a prewarmed engine already exists when the
    /// callback is set, the callback is invoked on it immediately. Set it
    /// once — replacing the callback later invokes the new one on the
    /// prewarmed engine again.
    public func setOnEngineCreated(_ callback: ((FlutterEngine) -> Void)?) {
        onEngineCreated = callback
        if let engine = prewarmedEngine {
            callback?(engine)
        }
    }

    /// Call once at app startup (e.g. `application(_:didFinishLaunchingWithOptions:)`).
    /// Idempotent — safe to call multiple times.
    public func start(prewarm: Bool = true) {
        isPrewarmEnabled = prewarm
        if engineGroup == nil {
            engineGroup = FlutterEngineGroup(name: "inlay_engine_group", project: nil)
        }
        if isPrewarmEnabled {
            prewarmEngineIfNeeded()
        }
    }

    /// Change the Dart entrypoint used for every engine inlay creates.
    ///
    /// The entrypoint must be a top-level function in the Flutter module
    /// annotated with `@pragma('vm:entry-point')`. Engines that are already
    /// running keep their entrypoint; the hidden prewarmed engine is
    /// recreated so the next navigation uses the new one.
    public func setDartEntrypoint(_ entrypoint: String) {
        guard entrypoint != dartEntrypoint else { return }
        dartEntrypoint = entrypoint
        if prewarmedEngine != nil {
            destroyPrewarmedEngine()
            if isPrewarmEnabled {
                prewarmEngineIfNeeded()
            }
        }
    }

    /// Enable/disable automatic prewarming performed by `start()`.
    ///
    /// Enabled by default.
    public func setPrewarmEnabled(_ enabled: Bool) {
        isPrewarmEnabled = enabled
        if enabled {
            prewarm()
        } else {
            destroyPrewarmedEngine()
        }
    }

    /// Imperatively prewarm the hidden engine (independent from `setPrewarmEnabled`).
    public func prewarm() {
        start(prewarm: false)
        prewarmEngineIfNeeded()
    }

    /// Destroy the hidden prewarmed engine and release its resources.
    public func destroyPrewarmedEngine() {
        guard let engine = prewarmedEngine else { return }
        InlayNavigatorHostApiSetup.setUp(
            binaryMessenger: engine.binaryMessenger,
            api: nil
        )
        KeyValueStorageImpl.shared.detachFromEngine(engine)
        engine.destroyContext()
        prewarmedEngine = nil
    }

    /// Boots a hidden engine once so first visible inlay navigation is faster.
    private func prewarmEngineIfNeeded() {
        guard prewarmedEngine == nil, let engineGroup else { return }

        let options = FlutterEngineGroupOptions()
        options.entrypoint = dartEntrypoint
        options.initialRoute = Self.prewarmRouteId

        let engine = engineGroup.makeEngine(with: options)
        onEngineCreated?(engine)

        // The Dart entrypoint initializes Inlay services, so we must register
        // HostApi + storage even for a hidden warm-up engine.
        InlayNavigatorHostApiSetup.setUp(
            binaryMessenger: engine.binaryMessenger,
            api: InlayNavigatorPrewarmHostApi()
        )
        KeyValueStorageImpl.shared.attachToEngine(engine)

        prewarmedEngine = engine
    }

    // MARK: - Public API (iOS side)

    /// Push a new Flutter view controller that displays the page described by `route`.
    ///
    /// This is the **only** method native iOS code needs to call.
    /// No FlutterEngine, no entrypoints, no channels.
    ///
    /// - Parameter enableNativeNavigationBar: When `true`, the native UIKit
    ///   navigation bar is left visible (native back button + swipe gesture
    ///   work out-of-the-box). When `false` (default), the bar is hidden and
    ///   Flutter is expected to provide its own app bar. The interactive pop
    ///   gesture is re-enabled in both modes.
    /// - Parameter enableInteractiveContentPopGestureRecognizer: Opt in/out of
    ///   iOS 26's full-width back gesture. Defaults to `true`.
    ///
    /// ```swift
    /// InlayNavigator.shared.push(
    ///     from: self,
    ///     route: SoundsNotificationsPage(contactId: "42")
    /// )
    /// ```
    public func push(
        from viewController: UIViewController,
        route: FlutterRoute,
        enableNativeNavigationBar: Bool = false,
        animated: Bool = true,
        enableInteractiveContentPopGestureRecognizer: Bool = true
    ) {
        push(
            from: viewController,
            page: route.toPageSettings(),
            enableNativeNavigationBar: enableNativeNavigationBar,
            animated: animated,
            enableInteractiveContentPopGestureRecognizer: enableInteractiveContentPopGestureRecognizer
        )
    }

    /// Push a Flutter screen that returns a typed result.
    ///
    /// `onResult` is invoked exactly once - with the decoded result the
    /// screen pops with, or `nil` when it is dismissed without one.
    ///
    /// ```swift
    /// InlayNavigator.shared.push(from: self, route: CounterPage()) { count in
    ///     // count: Int64?
    /// }
    /// ```
    public func push<R: FlutterRouteWithResult>(
        from viewController: UIViewController,
        route: R,
        enableNativeNavigationBar: Bool = false,
        animated: Bool = true,
        enableInteractiveContentPopGestureRecognizer: Bool = true,
        onResult: @escaping (R.ResultValue?) -> Void
    ) {
        push(
            from: viewController,
            page: route.toPageSettings(),
            enableNativeNavigationBar: enableNativeNavigationBar,
            animated: animated,
            enableInteractiveContentPopGestureRecognizer: enableInteractiveContentPopGestureRecognizer,
            onResult: { raw in onResult(R.decodeResult(raw)) }
        )
    }

    /// Present a Flutter page modally.
    public func present(
        from viewController: UIViewController,
        route: FlutterRoute,
        animated: Bool = true,
        enableInteractiveContentPopGestureRecognizer: Bool = true
    ) {
        present(
            from: viewController,
            page: route.toPageSettings(),
            animated: animated,
            enableInteractiveContentPopGestureRecognizer: enableInteractiveContentPopGestureRecognizer
        )
    }

    /// Present a Flutter page modally, receiving its typed result.
    ///
    /// `onResult` is invoked exactly once - with the decoded result, or
    /// `nil` when the screen is dismissed without one.
    public func present<R: FlutterRouteWithResult>(
        from viewController: UIViewController,
        route: R,
        animated: Bool = true,
        enableInteractiveContentPopGestureRecognizer: Bool = true,
        onResult: @escaping (R.ResultValue?) -> Void
    ) {
        present(
            from: viewController,
            page: route.toPageSettings(),
            animated: animated,
            enableInteractiveContentPopGestureRecognizer: enableInteractiveContentPopGestureRecognizer,
            onResult: { raw in onResult(R.decodeResult(raw)) }
        )
    }

    /// Create a `FlutterViewController` configured for the given route.
    ///
    /// - Parameter enableNativeNavigationBar: When `true`, the native UIKit
    ///   navigation bar is left visible. See ``push(from:route:enableNativeNavigationBar:animated:)``
    ///   for details.
    public func createFlutterViewController(
        route: FlutterRoute,
        enableNativeNavigationBar: Bool = false,
        enableInteractiveContentPopGestureRecognizer: Bool = true
    ) -> InlayFlutterViewController {
        createFlutterViewController(
            page: route.toPageSettings(),
            enableNativeNavigationBar: enableNativeNavigationBar,
            enableInteractiveContentPopGestureRecognizer: enableInteractiveContentPopGestureRecognizer
        )
    }

    // MARK: - Dialog API

    /// Present a Flutter dialog in a transparent native container.
    ///
    /// The dialog VC is presented modally with `.overFullScreen` style,
    /// so the underlying screen remains visible. Flutter renders the dialog
    /// content (barrier, animation, positioning).
    public func presentDialog(
        from viewController: UIViewController,
        route: FlutterDialogRoute,
        animated: Bool = true
    ) {
        presentDialog(
            from: viewController,
            page: route.toPageSettings(),
            animated: animated
        )
    }

    /// Present a Flutter dialog that returns a typed result.
    ///
    /// `onResult` is invoked exactly once - with the decoded result the
    /// dialog pops with, or `nil` when it is dismissed without one.
    ///
    /// ```swift
    /// InlayNavigator.shared.presentDialog(
    ///     from: self,
    ///     route: ConfirmDeleteDialog(itemId: "42")
    /// ) { confirmed in
    ///     // confirmed: Bool?
    /// }
    /// ```
    public func presentDialog<R: FlutterDialogRouteWithResult>(
        from viewController: UIViewController,
        route: R,
        animated: Bool = true,
        onResult: @escaping (R.ResultValue?) -> Void
    ) {
        presentDialog(
            from: viewController,
            page: route.toPageSettings(),
            animated: animated,
            onResult: { raw in onResult(R.decodeResult(raw)) }
        )
    }

    public func presentDialog(
        from viewController: UIViewController,
        page: PageSettings,
        animated: Bool = true,
        onResult: ((Any?) -> Void)? = nil
    ) {
        start(prewarm: isPrewarmEnabled)
        let vc = createFlutterDialogViewController(page: page)
        vc.onResult = onResult
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        viewController.present(vc, animated: animated)
    }

    /// Create a transparent `FlutterViewController` configured for a dialog overlay.
    public func createFlutterDialogViewController(
        page: PageSettings
    ) -> InlayFlutterDialogViewController {
        start(prewarm: isPrewarmEnabled)

        let initialRoute = Self.encodePageSettings(page)

        let options = FlutterEngineGroupOptions()
        options.entrypoint = dartEntrypoint
        options.initialRoute = initialRoute
        let engine = engineGroup!.makeEngine(with: options)
        onEngineCreated?(engine)

        let vc = InlayFlutterDialogViewController(engine: engine, nibName: nil, bundle: nil)
        vc.page = page

        configureEngine(
            engine,
            viewController: vc,
            routeData: page
        )
        return vc
    }

    // MARK: - Internal PageSettings-based navigation (used by Pigeon HostApi)

    public func push(
        from viewController: UIViewController,
        page: PageSettings,
        enableNativeNavigationBar: Bool = false,
        animated: Bool = true,
        enableInteractiveContentPopGestureRecognizer: Bool = true,
        onResult: ((Any?) -> Void)? = nil
    ) {
        start(prewarm: isPrewarmEnabled)
        let flutterVC = createFlutterViewController(
            page: page,
            enableNativeNavigationBar: enableNativeNavigationBar,
            enableInteractiveContentPopGestureRecognizer: enableInteractiveContentPopGestureRecognizer
        )
        flutterVC.onResult = onResult
        viewController.navigationController?.pushViewController(flutterVC, animated: animated)
            ?? viewController.present(flutterVC, animated: animated)
    }

    public func present(
        from viewController: UIViewController,
        page: PageSettings,
        animated: Bool = true,
        enableInteractiveContentPopGestureRecognizer: Bool = true,
        onResult: ((Any?) -> Void)? = nil
    ) {
        start(prewarm: isPrewarmEnabled)
        let flutterVC = createFlutterViewController(
            page: page,
            enableInteractiveContentPopGestureRecognizer: enableInteractiveContentPopGestureRecognizer
        )
        flutterVC.onResult = onResult
        viewController.present(flutterVC, animated: animated)
    }

    // MARK: - Native route handler

    /// Set the native route handler that processes Flutter → native navigation.
    ///
    /// Typically you pass an instance of the generated `NativeRouteHandler`
    /// subclass. The generated base class dispatches `PageSettings` to typed
    /// `on*` methods — you only implement those.
    ///
    /// ```swift
    /// // In AppDelegate.didFinishLaunching:
    /// InlayNavigator.shared.setNativeRouteHandler(SignalNativeRouteHandler())
    /// ```
    public func setNativeRouteHandler(_ handler: NativeRouteHandling) {
        nativeRouteHandler = handler
    }

    /// Dispatch a native route request. Called by the Pigeon HostApi impl.
    /// Throws if no handler is set.
    func dispatchNativeRoute(
        from viewController: UIViewController,
        route: PageSettings,
        completion: @escaping (Any?) -> Void = { _ in }
    ) throws {
        guard let handler = nativeRouteHandler else {
            throw InlayNavigatorError(
                code: "NO_NATIVE_ROUTE_HANDLER",
                message: "No native route handler set. "
                    + "Call InlayNavigator.shared.setNativeRouteHandler(...) in AppDelegate first.",
                details: nil
            )
        }
        handler.handle(viewController: viewController, route: route, completion: completion)
    }

    // MARK: - ViewController factory

    /// Create a `FlutterViewController` configured for the given page.
    public func createFlutterViewController(
        page: PageSettings,
        enableNativeNavigationBar: Bool = false,
        enableInteractiveContentPopGestureRecognizer: Bool = true
    ) -> InlayFlutterViewController {
        start(prewarm: isPrewarmEnabled)

        let initialRoute = Self.encodePageSettings(page)

        let options = FlutterEngineGroupOptions()
        options.entrypoint = dartEntrypoint
        options.initialRoute = initialRoute
        let engine = engineGroup!.makeEngine(with: options)
        onEngineCreated?(engine)

        let vc = InlayFlutterViewController(engine: engine, nibName: nil, bundle: nil)
        vc.page = page
        vc.enableNativeNavigationBar = enableNativeNavigationBar
        vc.enableInteractiveContentPopGestureRecognizer = enableInteractiveContentPopGestureRecognizer

        // Configure HostApi + storage immediately after engine creation.
        // Dart may start executing before `viewDidLoad`, so delaying setup can
        // cause startup races (missing initial route data or storage channels).
        configureEngine(
            engine,
            viewController: vc,
            routeData: page
        )
        return vc
    }

    // MARK: - Engine configuration (called by InlayFlutterViewController)

    /// Called by `InlayFlutterViewController.viewDidLoad`.
    /// Registers Pigeon APIs + storage on the engine.
    ///
    /// - Parameters:
    ///   - engine: The `FlutterEngine` to configure.
    ///   - viewController: The hosting view controller.
    ///   - onPop: Optional custom pop handler. When provided, Flutter's `pop()`
    ///            calls this closure instead of the default navigation-controller
    ///            pop / modal dismiss. Used by `InlayFlutterView` to integrate
    ///            with SwiftUI's `NavigationStack`.
    func configureEngine(
        _ engine: FlutterEngine,
        viewController: UIViewController,
        onPop: (() -> Void)? = nil,
        routeData: PageSettings? = nil
    ) {
        let hostApi = InlayNavigatorHostApiImpl(
            navigator: self,
            viewController: viewController,
            onPop: onPop,
            routeData: routeData
        )
        InlayNavigatorHostApiSetup.setUp(
            binaryMessenger: engine.binaryMessenger,
            api: hostApi
        )
        KeyValueStorageImpl.shared.attachToEngine(engine)
    }

    /// Called when the Flutter view controller is being deallocated.
    ///
    /// Detaches the channels and then tears the engine down explicitly, so
    /// the Dart isolate and its native resources are released together with
    /// the container instead of lingering until the last reference to the
    /// engine goes away - host-side channel wrappers created on the engine's
    /// binary messenger (and other plugin registrations) commonly keep it
    /// alive past the view controller's deinit.
    func cleanUpEngine(_ engine: FlutterEngine) {
        InlayNavigatorHostApiSetup.setUp(
            binaryMessenger: engine.binaryMessenger,
            api: nil
        )
        KeyValueStorageImpl.shared.detachFromEngine(engine)
        engine.destroyContext()
    }

    // MARK: - Encoding

    /// Encode `PageSettings` into a single string suitable for `initialRoute`.
    /// Format: `routeId?key1=value1&key2=value2`
    ///
    /// For Flutter pages (Map params) the params are URL-encoded into the query string.
    /// For native pages (pigeon-encoded List params) only the routeId is used.
    static func encodePageSettings(_ page: PageSettings) -> String {
        if let path = page.path { return path }

        guard let params = page.params else {
            return page.routeId
        }

        // Flutter pages use [String: String] params — URL-encode them.
        if let mapParams = params as? [String: String], !mapParams.isEmpty {
            let query = mapParams
                .sorted(by: { $0.key < $1.key })
                .map { "\($0.key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
                .joined(separator: "&")
            return "\(page.routeId)?\(query)"
        }

        // Native pages carry pigeon-encoded List params — no URL encoding.
        return page.routeId
    }

    /// Decode the `initialRoute` string back into `PageSettings`.
    static func decodePageSettings(_ initialRoute: String) -> PageSettings {
        guard let questionMark = initialRoute.firstIndex(of: "?") else {
            return PageSettings(routeId: initialRoute, params: nil)
        }
        let routeId = String(initialRoute[initialRoute.startIndex..<questionMark])
        let queryString = String(initialRoute[initialRoute.index(after: questionMark)...])
        var params: [String: String] = [:]
        for pair in queryString.split(separator: "&") {
            let parts = pair.split(separator: "=", maxSplits: 1)
            if parts.count == 2 {
                let key = String(parts[0]).removingPercentEncoding ?? String(parts[0])
                let value = String(parts[1]).removingPercentEncoding ?? String(parts[1])
                params[key] = value
            }
        }
        return PageSettings(routeId: routeId, params: params)
    }
}

// MARK: - HostApi implementation (handles push/pop from Flutter)

private class InlayNavigatorHostApiImpl: InlayNavigatorHostApi {

    private weak var navigator: InlayNavigator?
    private weak var viewController: UIViewController?
    private var onPop: (() -> Void)?
    private let routeData: PageSettings?

    init(
        navigator: InlayNavigator,
        viewController: UIViewController,
        onPop: (() -> Void)? = nil,
        routeData: PageSettings? = nil
    ) {
        self.navigator = navigator
        self.viewController = viewController
        self.onPop = onPop
        self.routeData = routeData
    }

    func push(page: PageSettings) throws {
        DispatchQueue.main.async { [weak self] in
            guard let self, let vc = self.viewController, let nav = self.navigator else { return }
            nav.push(from: vc, page: page)
        }
    }

    func pushForResult(page: PageSettings, completion: @escaping (Result<Any?, Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self, let vc = self.viewController, let nav = self.navigator else {
                completion(.success(nil))
                return
            }
            nav.push(from: vc, page: page, onResult: { completion(.success($0)) })
        }
    }

    func pop(result: Any?) throws {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let vc = self.viewController
            // Deliver the result only after the container is gone, so the
            // caller's onResult is free to present its own UI on the screen
            // underneath (presenting mid-dismiss silently fails on iOS).
            let deliver = {
                (vc as? InlayFlutterViewController)?.deliverResult(result)
                (vc as? InlayFlutterDialogViewController)?.deliverResult(result)
            }
            if let onPop = self.onPop {
                onPop()
                deliver()
            } else if let vc {
                if let nav = vc.navigationController {
                    nav.popViewController(animated: true)
                    if let coordinator = nav.transitionCoordinator {
                        coordinator.animate(alongsideTransition: nil) { _ in deliver() }
                    } else {
                        deliver()
                    }
                } else {
                    vc.dismiss(animated: true, completion: deliver)
                }
            } else {
                deliver()
            }
        }
    }

    func pushNativeRoute(route: PageSettings) throws {
        DispatchQueue.main.async { [weak self] in
            guard let self, let vc = self.viewController, let nav = self.navigator else { return }
            try? nav.dispatchNativeRoute(from: vc, route: route)
        }
    }

    func pushNativeRouteForResult(
        route: PageSettings,
        completion: @escaping (Result<Any?, Error>) -> Void
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self, let vc = self.viewController, let nav = self.navigator else {
                completion(.success(nil))
                return
            }
            do {
                try nav.dispatchNativeRoute(from: vc, route: route) {
                    completion(.success($0))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }

    func setNativePopGestureEnabled(enabled: Bool) throws {
        DispatchQueue.main.async { [weak self] in
            guard let vc = self?.viewController as? InlayFlutterViewController else { return }
            vc.setNativePopGestureEnabled(enabled)
        }
    }

    func getInitialRouteData() throws -> PageSettings? {
        return routeData
    }

    func presentDialog(page: PageSettings) throws {
        DispatchQueue.main.async { [weak self] in
            guard let self, let vc = self.viewController, let nav = self.navigator else { return }
            nav.presentDialog(from: vc, page: page)
        }
    }

    func presentDialogForResult(
        page: PageSettings,
        completion: @escaping (Result<Any?, Error>) -> Void
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self, let vc = self.viewController, let nav = self.navigator else {
                completion(.success(nil))
                return
            }
            nav.presentDialog(from: vc, page: page, onResult: { completion(.success($0)) })
        }
    }
}

/// No-op HostApi for the hidden warm-up engine.
private class InlayNavigatorPrewarmHostApi: InlayNavigatorHostApi {
    func push(page: PageSettings) throws {}
    func pushForResult(page: PageSettings, completion: @escaping (Result<Any?, Error>) -> Void) {
        completion(.success(nil))
    }
    func pop(result: Any?) throws {}
    func pushNativeRoute(route: PageSettings) throws {}
    func pushNativeRouteForResult(
        route: PageSettings,
        completion: @escaping (Result<Any?, Error>) -> Void
    ) {
        completion(.success(nil))
    }
    func setNativePopGestureEnabled(enabled: Bool) throws {}
    func getInitialRouteData() throws -> PageSettings? { nil }
    func presentDialog(page: PageSettings) throws {}
    func presentDialogForResult(
        page: PageSettings,
        completion: @escaping (Result<Any?, Error>) -> Void
    ) {
        completion(.success(nil))
    }
}
