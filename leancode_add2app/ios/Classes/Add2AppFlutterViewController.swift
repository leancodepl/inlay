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

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        Add2AppNavigator.shared.configureEngine(
            engine,
            viewController: self,
            onPop: onPop
        )
    }

    deinit {
        Add2AppNavigator.shared.cleanUpEngine(engine)
    }
}
