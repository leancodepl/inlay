import XCTest

/// End-to-end test for the `onResult:` parameter of the SwiftUI
/// `.inlayDialog` modifier: the Flutter dialog's typed `Bool` result must
/// reach the SwiftUI host and update its state.
final class SwiftUIDialogResultUITests: XCTestCase {

    func testSwiftUIDialogDeliversTypedResult() {
        let app = XCUIApplication()
        app.launch()

        app.tabBars.buttons["SwiftUI"].tap()
        app.tapButton("Open Confirm Dialog")

        let confirm = app.flutterElement(label: "Confirm")
        XCTAssertTrue(
            confirm.waitForExistence(timeout: 20),
            "The Flutter confirm dialog never appeared over SwiftUI."
        )
        confirm.tap()

        XCTAssertTrue(
            app.staticTexts["Confirm dialog returned: true"].waitForExistence(timeout: 20),
            "The SwiftUI host never received the dialog's Bool result."
        )
    }
}
