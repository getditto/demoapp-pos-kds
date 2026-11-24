import AppUI
import Foundation

struct OrderHistoryRowViewModel {
    let title: String
    let summary: String
    let total: String
    let date: String
    let status: String
    let tone: AppStatusTone

    init(order: Order) {
        title = "Order #\(order.title)"
        summary = order.summary.sorted { $0.key < $1.key }.map { "\($0.value) × \($0.key)" }.joined(separator: " · ")
        total = order.total.description
        date = order.createdAt.formatted(.dateTime.month(.abbreviated).day().hour().minute())
        switch order.status {
        case .open: status = "Open"; tone = .secondary
        case .inProcess: status = "Preparing"; tone = .active
        case .processed: status = "Ready"; tone = .success
        case .delivered: status = "Delivered"; tone = .success
        case .canceled: status = "Canceled"; tone = .secondary
        }
    }
}
