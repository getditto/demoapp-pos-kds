import Foundation

@MainActor struct OrderEviction {
    static let lastRunKey = "v2.lastEvictionAt"

    let now: () -> Date
    let calendar: Calendar
    let lastRun: () -> TimeInterval
    let recordRun: (TimeInterval) -> Void
    let evict: (String) async throws -> Void

    func runIfDue() async throws -> String? {
        let date = now()
        guard date.timeIntervalSince1970 - lastRun() >= 24 * 60 * 60 else { return nil }
        let cutoff = DittoWireDate.string(from: calendar.startOfDay(for: date))
        try await evict(cutoff)
        // A failed eviction must remain eligible on the next invocation.
        recordRun(date.timeIntervalSince1970)
        return cutoff
    }
}
