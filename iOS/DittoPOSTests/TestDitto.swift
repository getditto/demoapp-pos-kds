import DittoSwift
import Foundation
import XCTest

enum TestDitto {
    /// Uses local storage without credentials or sync, then removes it.
    @MainActor static func withInstance<T>(_ body: (Ditto) async throws -> T) async throws -> T {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let config = DittoConfig(
            databaseID: UUID().uuidString,
            connect: .smallPeersOnly(),
            persistenceDirectory: directory
        )
        let ditto = try Ditto.openSync(config: config)
        XCTAssertNil(ditto.config.encryptionKey)
        XCTAssertFalse(ditto.isEncrypted)
        XCTAssertFalse(ditto.isActivated)
        XCTAssertFalse(ditto.sync.isActive)
        defer { XCTAssertFalse(ditto.sync.isActive, "Local-store tests must never start sync") }
        return try await body(ditto)
    }
}
