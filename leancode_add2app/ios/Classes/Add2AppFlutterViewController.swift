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

    /// Keep the previous nav-bar visibility so we can restore it when leaving.
    private var previousNavigationBarHiddenState = false

    /// Keep the previous gesture delegate so we can restore it when leaving.
    private weak var previousGestureDelegate: UIGestureRecognizerDelegate?

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

        if !enableNativeNavigationBar, let navigationController {
            // When the navigation bar is hidden, UINavigationController's
            // internal delegate disables the interactive pop gesture.
            // Override the delegate so swipe-to-go-back keeps working.
            let gesture = navigationController.interactivePopGestureRecognizer
            previousGestureDelegate = gesture?.delegate
            gesture?.delegate = self
            gesture?.isEnabled = true
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard let navigationController else { return }

        navigationController.setNavigationBarHidden(
            previousNavigationBarHiddenState,
            animated: animated
        )

        if !enableNativeNavigationBar {
            navigationController.interactivePopGestureRecognizer?.delegate = previousGestureDelegate
        }
    }

    deinit {
        Add2AppNavigator.shared.cleanUpEngine(engine)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension Add2AppFlutterViewController {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let navigationController else { return false }
        return navigationController.viewControllers.count > 1
    }
}
