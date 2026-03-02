import Flutter
import UIKit

/// Generic Flutter view controller used by `Add2AppNavigator` for every page.
///
/// Developers never subclass this or reference it directly — they call
/// `Add2AppNavigator.shared.push(from:page:)` and this VC is created
/// automatically.
///
/// Equivalent of Android's `Add2AppFlutterActivity`.
final class Add2AppFlutterViewController: FlutterViewController {

    /// The page this VC is displaying (set by `Add2AppNavigator`).
    var page: PageSettings?

    /// Optional custom pop handler. When set (e.g. by `Add2AppFlutterView`),
    /// Flutter's `pop()` invokes this closure instead of the default
    /// navigation-controller pop / modal dismiss.
    var onPop: (() -> Void)?

    /// When `true`, the native UIKit navigation bar is left visible so the
    /// native back button and interactive pop gesture work out-of-the-box.
    ///
    /// When `false` (default), the bar is hidden and Flutter is expected to
    /// provide its own app bar / back button. The interactive pop gesture is
    /// still re-enabled manually so swipe-to-go-back works.
    var enableNativeNavigationBar = false

    /// When `true` (default), opt into iOS 26's full-width back gesture via
    /// `interactiveContentPopGestureRecognizer`.
    ///
    /// Set to `false` to force edge-only back gesture behavior.
    var enableInteractiveContentPopGestureRecognizer = true

    /// Keep the previous nav-bar visibility so we can restore it when leaving.
    private var previousNavigationBarHiddenState = false

    /// Keep the previous gesture delegate so we can restore it when leaving.
    private weak var previousGestureDelegate: UIGestureRecognizerDelegate?
    /// Keep the previous gesture enabled-state so we can restore it when leaving.
    private var previousGestureEnabledState = true
    /// Keep the previous full-width pop gesture delegate so we can restore it.
    private weak var previousContentGestureDelegate: UIGestureRecognizerDelegate?
    /// Keep the previous full-width pop gesture enabled-state.
    private var previousContentGestureEnabledState = true
    /// Runtime state controlled from Flutter to avoid container pop
    /// while nested Flutter routes can handle back.
    private var nativePopGestureEnabled = true

    func setNativePopGestureEnabled(_ enabled: Bool) {
        nativePopGestureEnabled = enabled
        navigationController?.interactivePopGestureRecognizer?.isEnabled = enabled
#if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            navigationController?.interactiveContentPopGestureRecognizer?.isEnabled =
                enabled && enableInteractiveContentPopGestureRecognizer
        }
#endif
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        Add2AppNavigator.shared.configureEngine(
            engine,
            viewController: self,
            onPop: onPop,
            routeData: page
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let navigationController else { return }
        previousNavigationBarHiddenState = navigationController.isNavigationBarHidden

        if enableNativeNavigationBar {
            navigationController.setNavigationBarHidden(false, animated: animated)
        } else {
            navigationController.setNavigationBarHidden(true, animated: animated)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard let navigationController else { return }
        let edgeGesture = navigationController.interactivePopGestureRecognizer
        previousGestureEnabledState = edgeGesture?.isEnabled ?? true
#if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            previousContentGestureEnabledState =
                navigationController.interactiveContentPopGestureRecognizer?.isEnabled ?? true
        }
#endif

        if !enableNativeNavigationBar {
            // When the navigation bar is hidden, UINavigationController's
            // internal delegate disables the interactive pop gesture.
            // Override the delegate so swipe-to-go-back keeps working.
            previousGestureDelegate = edgeGesture?.delegate
            edgeGesture?.delegate = self
#if compiler(>=6.2)
            if #available(iOS 26.0, *) {
                previousContentGestureDelegate =
                    navigationController.interactiveContentPopGestureRecognizer?.delegate
                if enableInteractiveContentPopGestureRecognizer {
                    navigationController.interactiveContentPopGestureRecognizer?.delegate = self
                }
            }
#endif
        }

        edgeGesture?.isEnabled = nativePopGestureEnabled
#if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            navigationController.interactiveContentPopGestureRecognizer?.isEnabled =
                nativePopGestureEnabled && enableInteractiveContentPopGestureRecognizer
        }
#endif
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard let navigationController else { return }

        navigationController.setNavigationBarHidden(
            previousNavigationBarHiddenState,
            animated: animated
        )

        let edgeGesture = navigationController.interactivePopGestureRecognizer
        if !enableNativeNavigationBar {
            edgeGesture?.delegate = previousGestureDelegate
#if compiler(>=6.2)
            if #available(iOS 26.0, *) {
                navigationController.interactiveContentPopGestureRecognizer?.delegate =
                    previousContentGestureDelegate
            }
#endif
        }
        edgeGesture?.isEnabled = previousGestureEnabledState
#if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            navigationController.interactiveContentPopGestureRecognizer?.isEnabled =
                previousContentGestureEnabledState
        }
#endif
    }

    deinit {
        Add2AppNavigator.shared.cleanUpEngine(engine)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension Add2AppFlutterViewController {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard nativePopGestureEnabled, let navigationController else { return false }
#if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            if gestureRecognizer === navigationController.interactiveContentPopGestureRecognizer {
                return nativePopGestureEnabled
                    && enableInteractiveContentPopGestureRecognizer
                    && navigationController.viewControllers.count > 1
            }
        }
#endif
        return navigationController.viewControllers.count > 1
    }
}
