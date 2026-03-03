import Flutter
import UIKit

/// Transparent Flutter view controller used for dialog overlays.
///
/// Unlike `Add2AppFlutterViewController`, this VC has a clear background
/// and no navigation bar management — it is always presented modally.
/// Flutter renders the dialog content (barrier, animation, positioning).
final class Add2AppFlutterDialogViewController: FlutterViewController {

    /// The page this VC is displaying (set by `Add2AppNavigator`).
    var page: PageSettings?

    /// Optional custom pop handler. When set (e.g. by the SwiftUI
    /// `.add2appDialog` modifier), Flutter's `pop()` invokes this closure
    /// instead of the default modal dismiss.
    var onPop: (() -> Void)?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.isOpaque = false

        // Re-configure engine with onPop if set. This must happen here
        // (not only in createFlutterDialogViewController) because the
        // caller sets onPop after the VC is created but before it loads.
        Add2AppNavigator.shared.configureEngine(
            engine,
            viewController: self,
            onPop: onPop,
            routeData: page
        )
    }

    deinit {
        Add2AppNavigator.shared.cleanUpEngine(engine)
    }
}
