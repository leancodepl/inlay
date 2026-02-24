import SwiftUI
import UIKit

final class RootTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()

        let uiKitHome = UINavigationController(rootViewController: HomeViewController())
        uiKitHome.tabBarItem = UITabBarItem(
            title: "UIKit",
            image: UIImage(systemName: "list.bullet"),
            selectedImage: UIImage(systemName: "list.bullet")
        )

        let swiftUIHomeController: UIViewController
        if #available(iOS 16.0, *) {
            swiftUIHomeController = UINavigationController(
                rootViewController: UIHostingController(rootView: SwiftUIHomeView())
            )
        } else {
            swiftUIHomeController = UINavigationController(rootViewController: HomeViewController())
        }
        swiftUIHomeController.tabBarItem = UITabBarItem(
            title: "SwiftUI",
            image: UIImage(systemName: "swift"),
            selectedImage: UIImage(systemName: "swift")
        )

        viewControllers = [uiKitHome, swiftUIHomeController]
    }
}
