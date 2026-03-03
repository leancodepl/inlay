import SwiftUI

@available(iOS 16.0, *)
struct SwiftUIHomeView: View {
    @State private var showConfirmDialog = false
    @State private var showThemePickerDialog = false

    var body: some View {
        List {
            NavigationLink("Open Flutter Greeting") {
                Add2AppFlutterView(
                    route: GreetingPage(name: "SwiftUI", style: .formal)
                )
                .ignoresSafeArea()
            }

            NavigationLink("Open Flutter Counter") {
                Add2AppFlutterView(route: CounterPage(seed: nil))
                    .ignoresSafeArea()
            }

            NavigationLink("Open Flutter Profile") {
                Add2AppFlutterView(
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
        }
        .navigationTitle("SwiftUI Home")
        .add2appDialog(
            isPresented: $showConfirmDialog,
            route: ConfirmActionDialog(action: "delete", message: "Are you sure?")
        )
        .add2appDialog(
            isPresented: $showThemePickerDialog,
            route: ThemePickerDialog(userId: "42")
        )
    }
}
