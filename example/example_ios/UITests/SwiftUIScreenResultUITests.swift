import XCTest

/// End-to-end test for the `onResult:` parameter of the SwiftUI
/// `InlayFlutterView`: a Flutter page pushed inside a `NavigationStack`
/// pops with a typed `Int` result, and the SwiftUI host shows it.
final class SwiftUIScreenResultUITests: XCTestCase {

    func testSwiftUIScreenDeliversTypedResult() {
        let app = XCUIApplication()
        app.launch()

        app.tabBars.buttons["SwiftUI"].tap()
        app.tapButton("Open Flutter Counter")

        let done = app.flutterElement(label: "Done — return count to caller")
        XCTAssertTrue(
            done.waitForExistence(timeout: 20),
            "The Flutter counter page never appeared in the SwiftUI stack."
        )
        done.tap()

        let result = app.staticTexts
            .matching(NSPredicate(format: "label BEGINSWITH %@", "Counter screen returned: "))
            .firstMatch
        XCTAssertTrue(
            result.waitForExistence(timeout: 20),
            "The SwiftUI host never received the counter page's Int result."
        )
        XCTAssertFalse(
            result.label.hasSuffix("dismissed"),
            "Expected a typed result, got a dismissal."
        )
    }

    func testSwiftUIScreenDeliversNilOnBack() {
        let app = XCUIApplication()
        app.launch()

        app.tabBars.buttons["SwiftUI"].tap()
        app.tapButton("Open Flutter Counter")

        let done = app.flutterElement(label: "Done — return count to caller")
        XCTAssertTrue(
            done.waitForExistence(timeout: 20),
            "The Flutter counter page never appeared in the SwiftUI stack."
        )
        // Leave without a result: the page hides the native navigation bar,
        // so use the back button of the Flutter app bar.
        let back = app.flutterElement(label: "Back")
        XCTAssertTrue(
            back.waitForExistence(timeout: 10),
            "The Flutter back button never appeared."
        )
        back.tap()

        XCTAssertTrue(
            app.staticTexts["Counter screen returned: dismissed"].waitForExistence(timeout: 20),
            "Leaving the page without a result must deliver nil."
        )
    }
}
