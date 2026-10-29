import Combine
import XCTest
@testable import DittoPOS

@MainActor final class SettingsTests: XCTestCase {
    func testLocationSelectionCanBeSavedAndCleared() throws {
        let previousDefaults = Settings.defaults
        let suiteName = "SettingsTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        Settings.defaults = defaults
        defer {
            Settings.defaults = previousDefaults
            defaults.removePersistentDomain(forName: suiteName)
        }

        Settings.locationId = "42"
        XCTAssertEqual(Settings.locationId, "42")
        Settings.clearLocationsSetup()
        XCTAssertNil(Settings.locationId)
    }

    func testTabSelectionIsSavedAndPublished() {
        let previousValue = Settings.selectedTabView
        defer { Settings.selectedTabView = previousValue }
        var received: [TabViews?] = []
        let subscription = Settings.selectedTabViewPublisher.sink { received.append($0) }

        Settings.selectedTabView = .kds
        XCTAssertEqual(Settings.selectedTabView, .kds)
        XCTAssertEqual(received, [.kds])
        withExtendedLifetime(subscription) {}
    }
}
