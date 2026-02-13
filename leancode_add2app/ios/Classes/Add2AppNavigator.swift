import Foundation
import Flutter

/// Protocol for handling native route requests dispatched from Flutter.
///
/// The generated `NativeRouteHandler` class conforms to this protocol,
/// dispatching `PageSettings` to typed `on*` methods. Developers subclass
/// the generated class rather than implementing this protocol directly.
protocol NativeRouteHandling: AnyObject {
    func handle(viewController: UIViewController, route: PageSettings)
}

/// Framework-level navigator that hides all Flutter internals
/// (`FlutterEngine`, `FlutterEngineGroup`, `FlutterViewController`, platform channels)
/// from the developer.
///
/// Usage from native iOS:
/// ```swift
/// // One-time setup (e.g. AppDelegate.didFinishLaunching)
/// Add2AppNavigator.shared.start()
///
/// // Navigate to a Flutter page from any UIViewController
/// Add2AppNavigator.shared.push(
///     from: self,
///     page: PageSettings(routeId: "soundsNotifications", params: ["contactId": "42"])
/// )
/// ```
///
/// Usage from Flutter (via Pigeon-generated `Add2AppNavigatorHostApi`):
/// ```dart
/// Add2AppNavigator.instance.push(SoundsNotificationsPage(contactId: '42'));
/// Add2AppNavigator.instance.pop();
/// ```
///
/// Navigation from Flutter to native screens:
/// ```swift
/// // Set the generated native route handler (e.g. AppDelegate.didFinishLaunching)
/// Add2AppNavigator.shared.setNativeRouteHandler(SignalNativeRouteHandler())
/// ```
/// ```dart
/// // From Flutter:
/// Add2AppNavigator.instance.pushNativeRoute(
///   NativeEditProfilePage(contactId: '42').toPageSettings(),
/// );
/// ```
///
/// The navigator automatically:
/// - Manages the `FlutterEngineGroup` singleton.
/// - Creates a generic `Add2AppFlutterViewController` for every push.
/// - Registers the Pigeon HostApi on each engine so Flutter can push/pop too.
/// - Attaches `KeyValueStorageImpl` to each engine.
final class Add2AppNavigator {

    // MARK: - Singleton

    static let shared = Add2AppNavigator()

    private init() {}

    // MARK: - Engine group

    /// Single `FlutterEngineGroup` shared across all add2app pages.
    private(set) var engineGroup: FlutterEngineGroup?

    /// The single Dart entrypoint used by all add2app pages.
    private static let dartEntrypoint = "add2appMain"

    /// The single native route handler set by the app.
    private var nativeRouteHandler: NativeRouteHandling?

    // MARK: - Initialisation

    /// Call once at app startup (e.g. `application(_:didFinishLaunchingWithOptions:)`).
    /// Idempotent — safe to call multiple times.
    func start() {
        guard engineGroup == nil else { return }
        engineGroup = FlutterEngineGroup(name: "add2app_engine_group", project: nil)
    }

    // MARK: - Public API (iOS side)

    /// Push a new Flutter view controller that displays the page described by `page`.
    ///
    /// This is the **only** method native iOS code needs to call.
    /// No FlutterEngine, no entrypoints, no channels.
    func push(from viewController: UIViewController, page: PageSettings, animated: Bool = true) {
        start()
        let flutterVC = createFlutterViewController(page: page)
        viewController.navigationController?.pushViewController(flutterVC, animated: animated)
            ?? viewController.present(flutterVC, animated: animated)
    }

    /// Present a Flutter page modally.
    func present(from viewController: UIViewController, page: PageSettings, animated: Bool = true) {
        start()
        let flutterVC = createFlutterViewController(page: page)
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
    /// Add2AppNavigator.shared.setNativeRouteHandler(SignalNativeRouteHandler())
    /// ```
    func setNativeRouteHandler(_ handler: NativeRouteHandling) {
        nativeRouteHandler = handler
    }

    /// Dispatch a native route request. Called by the Pigeon HostApi impl.
    /// Throws if no handler is set.
    func dispatchNativeRoute(from viewController: UIViewController, route: PageSettings) throws {
        guard let handler = nativeRouteHandler else {
            throw PigeonError(
                code: "NO_NATIVE_ROUTE_HANDLER",
                message: "No native route handler set. "
                    + "Call Add2AppNavigator.shared.setNativeRouteHandler(...) in AppDelegate first.",
                details: nil
            )
        }
        handler.handle(viewController: viewController, route: route)
    }

    // MARK: - ViewController factory

    /// Create a `FlutterViewController` configured for the given page.
    func createFlutterViewController(page: PageSettings) -> Add2AppFlutterViewController {
        start()

        let initialRoute = Self.encodePageSettings(page)

        let options = FlutterEngineGroupOptions()
        options.entrypoint = Self.dartEntrypoint
        options.initialRoute = initialRoute
        let engine = engineGroup!.makeEngine(with: options)

        let vc = Add2AppFlutterViewController(engine: engine, nibName: nil, bundle: nil)
        vc.page = page
        return vc
    }

    // MARK: - Engine configuration (called by Add2AppFlutterViewController)

    /// Called by `Add2AppFlutterViewController.viewDidLoad`.
    /// Registers Pigeon APIs + storage on the engine.
    ///
    /// - Parameters:
    ///   - engine: The `FlutterEngine` to configure.
    ///   - viewController: The hosting view controller.
    ///   - onPop: Optional custom pop handler. When provided, Flutter's `pop()`
    ///            calls this closure instead of the default navigation-controller
    ///            pop / modal dismiss. Used by `Add2AppFlutterView` to integrate
    ///            with SwiftUI's `NavigationStack`.
    func configureEngine(
        _ engine: FlutterEngine,
        viewController: UIViewController,
        onPop: (() -> Void)? = nil
    ) {
        let hostApi = Add2AppNavigatorHostApiImpl(
            navigator: self,
            viewController: viewController,
            onPop: onPop
        )
        Add2AppNavigatorHostApiSetup.setUp(
            binaryMessenger: engine.binaryMessenger,
            api: hostApi
        )
        KeyValueStorageImpl.shared.attachToEngine(engine)
    }

    /// Called when the Flutter view controller is being deallocated.
    func cleanUpEngine(_ engine: FlutterEngine) {
        Add2AppNavigatorHostApiSetup.setUp(
            binaryMessenger: engine.binaryMessenger,
            api: nil
        )
        KeyValueStorageImpl.shared.detachFromEngine(engine)
    }

    // MARK: - Encoding

    /// Encode `PageSettings` into a single string suitable for `initialRoute`.
    /// Format: `routeId?key1=value1&key2=value2`
    ///
    /// For Flutter pages (Map params) the params are URL-encoded into the query string.
    /// For native pages (pigeon-encoded List params) only the routeId is used.
    static func encodePageSettings(_ page: PageSettings) -> String {
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

private class Add2AppNavigatorHostApiImpl: Add2AppNavigatorHostApi {

    private weak var navigator: Add2AppNavigator?
    private weak var viewController: UIViewController?
    private var onPop: (() -> Void)?

    init(navigator: Add2AppNavigator, viewController: UIViewController, onPop: (() -> Void)? = nil) {
        self.navigator = navigator
        self.viewController = viewController
        self.onPop = onPop
    }

    func push(page: PageSettings) throws {
        DispatchQueue.main.async { [weak self] in
            guard let self, let vc = self.viewController, let nav = self.navigator else { return }
            nav.push(from: vc, page: page)
        }
    }

    func pop() throws {
        DispatchQueue.main.async { [weak self] in
            if let onPop = self?.onPop {
                onPop()
            } else if let vc = self?.viewController {
                if let nav = vc.navigationController {
                    nav.popViewController(animated: true)
                } else {
                    vc.dismiss(animated: true)
                }
            }
        }
    }

    func pushNativeRoute(route: PageSettings) throws {
        DispatchQueue.main.async { [weak self] in
            guard let self, let vc = self.viewController, let nav = self.navigator else { return }
            try? nav.dispatchNativeRoute(from: vc, route: route)
        }
    }
}
