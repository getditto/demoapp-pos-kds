import DittoUI
import SwiftUI

struct KDSOrderView: View {
    let order: Order
    let now: Date
    let onAdvance: () -> Void

    var body: some View {
        DittoTicket(
            title: "#\(order.title)",
            lines: order.summary.sorted(by: { $0.key < $1.key }).map { "\($0.value) × \($0.key)" },
            isPaid: order.isPaid,
            elapsed: Self.elapsedFormatter.localizedString(for: order.createdAt, relativeTo: now),
            isReady: order.status == .processed,
            onAdvance: onAdvance
        )
    }

    private static let elapsedFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()
}
