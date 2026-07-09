import SwiftUI
import UIKit
import inlay

final class HomeViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "UIKit Home"
        view.backgroundColor = .systemBackground

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
        ])

        stack.addArrangedSubview(makeButton("Open Flutter Greeting") { [weak self] in
            guard let self else { return }
            InlayNavigator.shared.push(
                from: self,
                route: GreetingPage(name: "iOS", style: .casual)
            )
        })

        stack.addArrangedSubview(makeButton("Open Flutter Counter") { [weak self] in
            guard let self else { return }
            InlayNavigator.shared.push(from: self, route: CounterPage(seed: nil))
        })

        stack.addArrangedSubview(makeButton("Open Flutter Profile") { [weak self] in
            guard let self else { return }
            InlayNavigator.shared.push(
                from: self,
                route: ProfilePage(
                    userId: "42",
                    badges: [UserBadge(label: "UIKit badge", level: .gold)]
                )
            )
        })

        stack.addArrangedSubview(makeButton("Open Native Settings") { [weak self] in
            guard let self else { return }
            self.navigationController?.pushViewController(
                NativeSettingsViewController(userId: "42"),
                animated: true
            )
        })

        stack.addArrangedSubview(makeButton("Open Confirm Dialog (await result)") { [weak self] in
            guard let self else { return }
            InlayNavigator.shared.presentDialog(
                from: self,
                route: ConfirmActionDialog(action: "delete", message: "Are you sure?"),
                onResult: { [weak self] confirmed in
                    // confirmed: Bool?
                    self?.showResult("Confirm dialog", value: confirmed.map(String.init) ?? "dismissed")
                }
            )
        })

        stack.addArrangedSubview(makeButton("Open Counter (await result)") { [weak self] in
            guard let self else { return }
            InlayNavigator.shared.push(
                from: self,
                route: CounterPage(seed: nil),
                onResult: { [weak self] count in
                    // count: Int64?
                    self?.showResult("Counter", value: count.map(String.init) ?? "dismissed")
                }
            )
        })

        stack.addArrangedSubview(makeButton("Open Theme Picker Dialog") { [weak self] in
            guard let self else { return }
            InlayNavigator.shared.presentDialog(
                from: self,
                route: ThemePickerDialog(userId: "42")
            )
        })

        if #available(iOS 16.0, *) {
            stack.addArrangedSubview(makeButton("Open SwiftUI Counter View") { [weak self] in
                guard let self else { return }
                self.navigationController?.pushViewController(
                    UIHostingController(rootView: NativeCounterView()),
                    animated: true
                )
            })
        }
    }

    private func showResult(_ label: String, value: String) {
        let alert = UIAlertController(
            title: "\(label) returned",
            message: value,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func makeButton(_ title: String, action: @escaping () -> Void) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title
        let button = UIButton(configuration: config)
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return button
    }
}
