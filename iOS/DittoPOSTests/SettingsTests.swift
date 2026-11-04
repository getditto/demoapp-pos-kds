import Combine
import XCTest

@MainActor final class SettingsTests: XCTestCase {
    func testPersistedDestinationDecodesLegacyIdsAndPublishesSelectionChanges() throws {
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
        var received: [TabViews?] = []
        let subscription = Settings.selectedTabViewPublisher.sink { received.append($0) }
        defer { subscription.cancel() }
        Settings.selectedTabView = .pos
        Settings.selectedTabView = nil
        XCTAssertEqual(defaults.integer(forKey: key), 0)
        Settings.selectedTabView = .locations
        XCTAssertEqual(received, [.pos, nil, .locations])
        XCTAssertEqual(defaults.integer(forKey: key), 3)
        Settings.defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        XCTAssertEqual(Settings.selectedTabView, .locations)
    }
}
