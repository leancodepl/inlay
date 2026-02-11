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

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        Add2AppNavigator.shared.configureEngine(engine, viewController: self)
    }

    deinit {
        Add2AppNavigator.shared.cleanUpEngine(engine)
    }
}
