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

    /// Keep the previous nav-bar visibility so we can restore it when leaving.
    private var previousNavigationBarHiddenState = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // Match native background color during Flutter first-frame startup.
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
        // Flutter provides its own app bar, so hide UIKit's bar to avoid
        // transient safe-area inset changes (content jump on first render).
        navigationController.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(
            previousNavigationBarHiddenState,
            animated: animated
        )
    }

    deinit {
        Add2AppNavigator.shared.cleanUpEngine(engine)
    }
}
