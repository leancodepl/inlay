import SwiftUI
import UIKit
import inlay

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        InlayNavigator.shared.start()
        InlayNavigator.shared.setNativeRouteHandler(ExampleNativeRouteHandler())

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = RootTabBarController()
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}
