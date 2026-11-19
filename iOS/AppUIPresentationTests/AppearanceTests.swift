import XCTest

@MainActor final class AppearanceTests: XCTestCase {
    func testSystemOverrideRelaunchAndPreservedDraftThroughTheNativeSettingsUI() {
        let originalAppearance = XCUIDevice.shared.appearance
        let app = XCUIApplication(bundleIdentifier: "live.ditto.pos.ui-test-host")
        app.launchEnvironment["UI_TEST_SETTINGS_SUITE"] = "AppearanceTests.\(UUID().uuidString)"
        app.launchArguments = ["--reset-settings"]
        defer {
            app.terminate()
            XCUIDevice.shared.appearance = originalAppearance
        }
        XCUIDevice.shared.appearance = .light
        app.launch()
        assertAppearance("Light", in: app)
        let draft = app.textFields["Draft"]
        draft.tap()
        draft.typeText("retained")
        app.keyboards.buttons["Done"].tap()
        app.buttons["Settings"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Appearance"].exists)
        XCUIDevice.shared.appearance = .dark
        assertAppearance("Dark", in: app)
        app.buttons["Light"].tap()
        assertAppearance("Light", in: app)
        XCUIDevice.shared.appearance = .light
        XCUIDevice.shared.appearance = .dark
        assertAppearance("Light", in: app)
        app.buttons["System"].tap()
        assertAppearance("Dark", in: app)
        app.buttons["POS"].firstMatch.tap()
        XCTAssertEqual(app.textFields["Draft"].value as? String, "retained")
        app.buttons["Settings"].firstMatch.tap()
        app.buttons["Dark"].tap()
        app.terminate()
        XCUIDevice.shared.appearance = .light
        app.launchArguments = []
        app.launch()
        assertAppearance("Dark", in: app)
        app.buttons["Settings"].firstMatch.tap()
        app.buttons["System"].tap()
        assertAppearance("Light", in: app)
    }

    private func assertAppearance(_ appearance: String, in app: XCUIApplication) {
        let shell = app.otherElements["app-shell"]
        let expected = NSPredicate(format: "value == %@", appearance)
        expectation(for: expected, evaluatedWith: shell)
        waitForExpectations(timeout: 5)
    }
}
