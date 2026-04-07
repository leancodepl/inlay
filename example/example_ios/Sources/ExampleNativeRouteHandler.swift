import UIKit
import inlay

final class ExampleNativeRouteHandler: NativeRouteHandler {
    override func onNativeSettings(page: NativeSettingsPage, viewController: UIViewController) {
        let target = NativeSettingsViewController(userId: "42")
        viewController.navigationController?.pushViewController(target, animated: true)
            ?? viewController.present(UINavigationController(rootViewController: target), animated: true)
    }

    override func onNativeAbout(page: NativeAboutPage, viewController: UIViewController) {
        let target = NativeAboutViewController(version: page.appVersion)
        viewController.navigationController?.pushViewController(target, animated: true)
            ?? viewController.present(UINavigationController(rootViewController: target), animated: true)
    }
}
