import Flutter
import UIKit

/// Transparent Flutter view controller used for dialog overlays.
///
/// Unlike `InlayFlutterViewController`, this VC has a clear background
/// and no navigation bar management — it is always presented modally.
/// Flutter renders the dialog content (barrier, animation, positioning).
public final class InlayFlutterDialogViewController: FlutterViewController {

    /// The page this VC is displaying (set by `InlayNavigator`).
    public var page: PageSettings?

    /// Optional custom pop handler. When set (e.g. by the SwiftUI
    /// `.inlayDialog` modifier), Flutter's `pop()` invokes this closure
    /// instead of the default modal dismiss.
    public var onPop: (() -> Void)?

    // MARK: - Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.isOpaque = false

        // Re-configure engine with onPop if set. This must happen here
        // (not only in createFlutterDialogViewController) because the
        // caller sets onPop after the VC is created but before it loads.
        InlayNavigator.shared.configureEngine(
            engine,
            viewController: self,
            onPop: onPop,
            routeData: page
        )
    }

    deinit {
        InlayNavigator.shared.cleanUpEngine(engine)
    }
}
