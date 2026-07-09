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
///         .inlayDialog(
///             isPresented: $showDialog,
///             route: ConfirmDeleteDialog(itemId: "42"),
///             onResult: { raw in
///                 let confirmed = ConfirmDeleteDialog.decodeResult(raw)
///             }
///         )
/// }
/// ```
///
/// `onResult` is invoked exactly once — with the result the dialog popped
/// with, or `nil` when it is dismissed without one. Decode raw values with
/// the generated `decodeResult`.
@available(iOS 16.0, *)
extension View {
    public func inlayDialog(
        isPresented: Binding<Bool>,
        route: FlutterDialogRoute,
        onResult: ((Any?) -> Void)? = nil
    ) -> some View {
        background(
            InlayDialogPresenter(
                isPresented: isPresented,
                route: route.toPageSettings(),
                onResult: onResult
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
private struct InlayDialogPresenter: UIViewControllerRepresentable {

    @Binding var isPresented: Bool
    let route: PageSettings
    var onResult: ((Any?) -> Void)?

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

            let dialogVC = InlayNavigator.shared.createFlutterDialogViewController(page: route)
            dialogVC.onResult = onResult
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
        weak var dialogVC: InlayFlutterDialogViewController?
    }
}
