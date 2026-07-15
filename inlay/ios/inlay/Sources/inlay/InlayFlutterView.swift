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

    /// Convenience initializer that accepts a type-safe `FlutterRoute`.
    public init(
        route: FlutterRoute,
        enableNativeNavigationBar: Bool = false,
        enableInteractiveContentPopGestureRecognizer: Bool = true
    ) {
        self.route = route.toPageSettings()
        self.enableNativeNavigationBar = enableNativeNavigationBar
        self.enableInteractiveContentPopGestureRecognizer = enableInteractiveContentPopGestureRecognizer
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
    }

    // MARK: - Coordinator

    /// Bridges the SwiftUI `DismissAction` into an escaping closure that the
    /// `FlutterViewController` can call from any thread.
    public class Coordinator {
        public var dismiss: (() -> Void)?
        public init() {}
    }
}
