import DittoSwift
import Foundation

enum TestDitto {
    /// Runs `body` with a Ditto instance backed by a throwaway local store,
    /// and deletes the store afterwards.
    @MainActor static func withInstance<T>(_ body: (Ditto) async throws -> T) async throws -> T {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let config = DittoConfig(
            databaseID: UUID().uuidString,
            connect: .smallPeersOnly(),
            persistenceDirectory: directory
        )
        return try await body(Ditto.openSync(config: config))
    }
}
