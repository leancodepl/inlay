import SwiftUI
import Flutter

/// A SwiftUI view that embeds a Flutter page, designed to work seamlessly
/// inside a `NavigationStack` (or `NavigationView`).
///
/// Drop it into a `NavigationStack` alongside native SwiftUI screens:
///
/// ```swift
/// struct ContentView: View {
///     var body: some View {
///         NavigationStack {
///             List {
///                 NavigationLink("Contact Details") {
///                     InlayFlutterView(
///                         route: ContactDetailsPage(contactId: "42")
///                     )
///                     .ignoresSafeArea()
///                     .navigationTitle("Contact")
///                     .navigationBarTitleDisplayMode(.inline)
///                 }
///
///                 NavigationLink("Set Wallpaper") {
///                     InlayFlutterView(
///                         route: SetWallpaperPage(recipientId: "42")
///                     )
///                     .ignoresSafeArea()
///                 }
///
///                 NavigationLink("Settings (native)") {
///                     NativeSettingsView()
///                 }
///             }
///             .navigationTitle("Home")
///         }
///     }
/// }
/// ```
///
/// ### Typed results
///
/// For routes declared with a `result:` type, pass `onResult` to receive
/// the decoded value the Flutter page pops with:
///
/// ```swift
/// NavigationLink("Open Counter") {
///     InlayFlutterView(route: CounterPage(seed: nil)) { count in
///         // count: Int64?
///     }
/// }
/// ```
///
/// `onResult` is invoked exactly once - with the decoded result, or `nil`
/// when the page is dismissed without one (back button, swipe-back gesture).
///
/// ### How it works
///
/// Under the hood the view creates an `InlayFlutterViewController` via
/// `InlayNavigator.shared.createFlutterViewController(page:)` and wraps it
/// with `UIViewControllerRepresentable`. The engine is configured with a
/// custom `onPop` handler that calls SwiftUI's `dismiss()` action, so when
/// Flutter code calls `pop()`, the `NavigationStack` pops back naturally.
///
/// ### Pop integration
///
/// When Flutter code calls `pop()`, the view uses SwiftUI's
/// `@Environment(\.dismiss)` to pop the current navigation destination.
/// This integrates naturally with `NavigationStack`'s back-stack management.
///
/// Equivalent of Android's `InlayFlutterScreen` Composable.
@available(iOS 16.0, *)
public struct InlayFlutterView: UIViewControllerRepresentable {

    /// The Flutter page to display, described as a `PageSettings`.
    public let route: PageSettings

    /// When `true`, the native UIKit navigation bar is left visible.
    /// See ``InlayFlutterViewController/enableNativeNavigationBar``.
    public let enableNativeNavigationBar: Bool

    /// When `true` (default), enables iOS 26 full-width back gesture
    /// (`interactiveContentPopGestureRecognizer`).
    public let enableInteractiveContentPopGestureRecognizer: Bool

    /// Receives the wire-format result the Flutter page pops with, or `nil`
    /// when it is dismissed without one. Set by the typed-result initializer.
    let onResult: ((Any?) -> Void)?

    /// Convenience initializer that accepts a type-safe `FlutterRoute`.
    public init(
        route: FlutterRoute,
        enableNativeNavigationBar: Bool = false,
        enableInteractiveContentPopGestureRecognizer: Bool = true
    ) {
        self.route = route.toPageSettings()
        self.enableNativeNavigationBar = enableNativeNavigationBar
        self.enableInteractiveContentPopGestureRecognizer = enableInteractiveContentPopGestureRecognizer
        self.onResult = nil
    }

    /// Initializer for routes that return a typed result.
    ///
    /// `onResult` is invoked exactly once - with the decoded result the
    /// Flutter page pops with, or `nil` when it is dismissed without one.
    ///
    /// Equivalent of Android's `InlayFlutterScreen(route, onResult = ...)`.
    public init<R: FlutterRouteWithResult>(
        route: R,
        enableNativeNavigationBar: Bool = false,
        enableInteractiveContentPopGestureRecognizer: Bool = true,
        onResult: @escaping (R.ResultValue?) -> Void
    ) {
        self.route = route.toPageSettings()
        self.enableNativeNavigationBar = enableNativeNavigationBar
        self.enableInteractiveContentPopGestureRecognizer = enableInteractiveContentPopGestureRecognizer
        self.onResult = { raw in onResult(R.decodeResult(raw)) }
    }

    @Environment(\.dismiss) private var dismiss

    // MARK: - UIViewControllerRepresentable

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public func makeUIViewController(context: Context) -> InlayFlutterViewController {
        let vc = InlayNavigator.shared.createFlutterViewController(
            page: route,
            enableNativeNavigationBar: enableNativeNavigationBar,
            enableInteractiveContentPopGestureRecognizer: enableInteractiveContentPopGestureRecognizer
        )

        // Wire up the dismiss action through the coordinator so it stays
        // up-to-date across SwiftUI view updates.
        let coordinator = context.coordinator
        vc.onPop = { [weak coordinator] in
            coordinator?.dismiss?()
        }

        // Set the initial dismiss closure.
        let currentDismiss = dismiss
        coordinator.dismiss = { currentDismiss() }

        // Route the result to whatever `onResult` the caller passed most
        // recently. The coordinator is captured strongly on purpose: a
        // swipe-back delivers `nil` from the controller's deinit, which can
        // run after SwiftUI has released the coordinator.
        coordinator.onResult = onResult
        if onResult != nil {
            vc.onResult = { raw in coordinator.onResult?(raw) }
        }

        return vc
    }

    public func updateUIViewController(
        _ uiViewController: InlayFlutterViewController,
        context: Context
    ) {
        // Keep the dismiss closure fresh — SwiftUI may provide a new
        // DismissAction on re-renders.
        let currentDismiss = dismiss
        context.coordinator.dismiss = { currentDismiss() }
        // Keep the result callback fresh too - it can capture new view state.
        context.coordinator.onResult = onResult
    }

    // MARK: - Coordinator

    /// Bridges the SwiftUI `DismissAction` and the latest `onResult` into
    /// escaping closures that the `FlutterViewController` can call.
    public class Coordinator {
        public var dismiss: (() -> Void)?
        var onResult: ((Any?) -> Void)?
        public init() {}
    }
}
