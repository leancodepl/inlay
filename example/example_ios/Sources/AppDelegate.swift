import FlutterPluginRegistrant
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
        // The iOS embedding does not register plugins automatically, so every
        // engine inlay creates needs an explicit registration. Set before
        // start() so the prewarmed engine is covered too.
        InlayNavigator.shared.setOnEngineCreated { engine in
            GeneratedPluginRegistrant.register(with: engine)
        }
        // Lets Flutter engines detect a module built from a different schema
        // revision than this host.
        InlayNavigator.shared.setSchemaFingerprint(InlaySchema.fingerprint)
        InlayNavigator.shared.start()
        InlayNavigator.shared.setNativeRouteHandler(ExampleNativeRouteHandler())

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = RootTabBarController()
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}
