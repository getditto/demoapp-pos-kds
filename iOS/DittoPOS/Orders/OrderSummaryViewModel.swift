import AppUI
import SwiftUI

struct OrderSummaryViewModel {
    let title: String
    let summary: String
    let total: String
    let date: String
    let status: String
    let statusColor: Color
    let usesColumns: Bool

    init(order: Order, availableWidth: CGFloat, accessibilityText: Bool) {
        usesColumns = availableWidth >= OrderSummaryLayout.minimumTableWidth && !accessibilityText
        title = "Order #\(order.title)"
        summary = order.summary.sorted { $0.key < $1.key }.map { "\($0.value) × \($0.key)" }.joined(separator: " · ")
        total = order.total.description
        date = order.createdAt.formatted(.dateTime.month(.abbreviated).day().hour().minute())
        switch order.status {
        case .open: status = "Open"; statusColor = AppColors.secondaryText
        case .inProcess: status = "Preparing"; statusColor = AppColors.brandText
        case .processed: status = "Ready"; statusColor = AppColors.success
        case .delivered: status = "Delivered"; statusColor = AppColors.success
        case .canceled: status = "Canceled"; statusColor = AppColors.secondaryText
        }
    }
}

enum OrderSummaryLayout {
    static let minimumTableWidth: CGFloat = 760
    static let titleWidth: CGFloat = 168
    static let statusWidth: CGFloat = 100
    static let dateWidth: CGFloat = 150
    static let totalWidth: CGFloat = 80
}
