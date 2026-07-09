import SwiftUI
import inlay

@available(iOS 16.0, *)
struct SwiftUIHomeView: View {
    @State private var showConfirmDialog = false
    @State private var showThemePickerDialog = false
    @State private var lastDialogResult: String?

    var body: some View {
        List {
            NavigationLink("Open Flutter Greeting") {
                InlayFlutterView(
                    route: GreetingPage(name: "SwiftUI", style: .formal)
                )
                .ignoresSafeArea()
            }

            NavigationLink("Open Flutter Counter") {
                InlayFlutterView(route: CounterPage(seed: nil))
                    .ignoresSafeArea()
            }

            NavigationLink("Open Flutter Profile") {
                InlayFlutterView(
                    route: ProfilePage(
                        userId: "42",
                        badges: [UserBadge(label: "SwiftUI badge", level: .silver)]
                    )
                )
                .ignoresSafeArea()
            }

            NavigationLink("Open Native Counter View") {
                NativeCounterView()
            }

            Button("Open Confirm Dialog") {
                showConfirmDialog = true
            }

            Button("Open Theme Picker Dialog") {
                showThemePickerDialog = true
            }

            if let lastDialogResult {
                Text("Confirm dialog returned: \(lastDialogResult)")
            }
        }
        .navigationTitle("SwiftUI Home")
        .inlayDialog(
            isPresented: $showConfirmDialog,
            route: ConfirmActionDialog(action: "delete", message: "Are you sure?"),
            onResult: { confirmed in
                // confirmed: Bool?
                lastDialogResult = confirmed.map(String.init) ?? "dismissed"
            }
        )
        .inlayDialog(
            isPresented: $showThemePickerDialog,
            route: ThemePickerDialog(userId: "42")
        )
    }
}
