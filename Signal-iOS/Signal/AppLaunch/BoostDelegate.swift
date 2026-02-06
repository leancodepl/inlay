import UIKit
import flutter_boost

class BoostDelegate: NSObject, FlutterBoostDelegate {

    func pushNativeRoute(_ pageName: String!, arguments: [AnyHashable: Any]!) {
        // TODO
    }

    func pushFlutterRoute(_ options: FlutterBoostRouteOptions!) {
        let vc = FBFlutterViewContainer()
        vc.setName(options.pageName, uniqueId: options.uniqueId, params: options.arguments, opaque: options.opaque)

        let isPresent = (options.arguments?["isPresent"] as? Bool) ?? false
        let isAnimated = (options.arguments?["isAnimated"] as? Bool) ?? true

        if let navigationController = topNavigationController() {
            if isPresent || !options.opaque {
                navigationController.present(vc, animated: isAnimated, completion: nil)
            } else {
                navigationController.pushViewController(vc, animated: isAnimated)
            }
        } else if let topVC = topViewController() {
            topVC.present(vc, animated: isAnimated, completion: nil)
        }
    }

    func popRoute(_ options: FlutterBoostRouteOptions!) {
        if let navigationController = topNavigationController(),
           let vc = navigationController.presentedViewController as? FBFlutterViewContainer,
           vc.uniqueIDString() == options.uniqueId {
            vc.dismiss(animated: true, completion: nil)
        } else if let navigationController = topNavigationController() {
            navigationController.popViewController(animated: true)
        } else if let topVC = topViewController() {
            topVC.dismiss(animated: true, completion: nil)
        }
    }

    private func topViewController() -> UIViewController? {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else {
            return nil
        }

        var topVC = window.rootViewController
        while let presented = topVC?.presentedViewController {
            topVC = presented
        }
        return topVC
    }

    private func topNavigationController() -> UINavigationController? {
        guard let topVC = topViewController() else { return nil }
        if let nav = topVC as? UINavigationController {
            return nav
        }
        return topVC.navigationController
    }
}
