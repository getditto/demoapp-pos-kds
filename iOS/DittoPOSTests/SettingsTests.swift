import XCTest

@MainActor final class SettingsTests: XCTestCase {
    func testPersistedDestinationDecodesLegacyIdsAndRetainsSelection() throws {
        let previous = Settings.defaults
        let suite = "SettingsTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        Settings.defaults = defaults
        defer {
            Settings.defaults = previous
            defaults.removePersistentDomain(forName: suite)
        }
        let key = "live.ditto.DittoPOS.selectedTab"
        defaults.set(2, forKey: key)
        XCTAssertEqual(Settings.selectedTabView, .kds)
        defaults.set(999, forKey: key)
        XCTAssertNil(Settings.selectedTabView)
        Settings.selectedTabView = .pos
        Settings.selectedTabView = nil
        XCTAssertEqual(defaults.integer(forKey: key), 0)
        Settings.selectedTabView = .settings
        XCTAssertEqual(defaults.integer(forKey: key), 3)
        Settings.defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        XCTAssertEqual(Settings.selectedTabView, .settings)
    }
}
