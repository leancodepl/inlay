import SwiftUI
import Flutter

/// Present a Flutter dialog over the current native screen.
///
/// Unlike `.fullScreenCover`, this modifier uses UIKit's `.overFullScreen`
/// presentation so the background stays visible behind the transparent
/// Flutter dialog. When Flutter calls `pop()`, the dialog dismisses and
/// `isPresented` is reset to `false`.
///
/// ```swift
/// @State private var showDialog = false
///
/// var body: some View {
///     Button("Show Dialog") { showDialog = true }
///         .add2appDialog(
///             isPresented: $showDialog,
///             route: ConfirmDeleteDialog(itemId: "42")
///         )
/// }
/// ```
@available(iOS 16.0, *)
extension View {
    public func add2appDialog(
        isPresented: Binding<Bool>,
        route: FlutterDialogRoute
    ) -> some View {
        background(
            Add2AppDialogPresenter(
                isPresented: isPresented,
                route: route.toPageSettings()
            )
        )
    }
}

// MARK: - Private bridge

/// An invisible `UIViewControllerRepresentable` that presents the Flutter
/// dialog via UIKit's `.overFullScreen` modal presentation. This keeps the
/// background visible and avoids the SwiftUI `.fullScreenCover` pitfalls
/// (which removes the presenting view from the hierarchy).
@available(iOS 16.0, *)
private struct Add2AppDialogPresenter: UIViewControllerRepresentable {

    @Binding var isPresented: Bool
    let route: PageSettings

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .clear
        vc.view.isUserInteractionEnabled = false
        return vc
    }

    func updateUIViewController(_ anchor: UIViewController, context: Context) {
        let coordinator = context.coordinator

        if isPresented && !coordinator.isPresenting {
            coordinator.isPresenting = true

            let dialogVC = Add2AppNavigator.shared.createFlutterDialogViewController(page: route)
            dialogVC.modalPresentationStyle = .overFullScreen
            dialogVC.modalTransitionStyle = .crossDissolve

            dialogVC.onPop = { [weak dialogVC, weak coordinator] in
                dialogVC?.dismiss(animated: true) {
                    coordinator?.isPresenting = false
                    isPresented = false
                }
            }

            coordinator.dialogVC = dialogVC

            // Walk up to the root VC so the dialog covers the full screen
            // (including tab bars, toolbars, etc.).
            var presenter: UIViewController = anchor
            while let parent = presenter.parent {
                presenter = parent
            }
            while let presented = presenter.presentedViewController {
                presenter = presented
            }

            presenter.present(dialogVC, animated: true)
        } else if !isPresented && coordinator.isPresenting {
            // Handle programmatic dismissal (isPresented set to false externally).
            coordinator.isPresenting = false
            coordinator.dialogVC?.dismiss(animated: true)
            coordinator.dialogVC = nil
        }
    }

    class Coordinator {
        var isPresenting = false
        weak var dialogVC: Add2AppFlutterDialogViewController?
    }
}
