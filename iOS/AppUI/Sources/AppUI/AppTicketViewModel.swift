import SwiftUI

struct AppTicketViewModel {
    let paymentTitle: String
    let paymentColor: Color
    let stageTitle: String
    let stageColor: Color
    let actionTitle: String
    let actionLabel: String
    let actionKind: AppButtonStyle.Kind

    init(title: String, isPaid: Bool, isReady: Bool) {
        paymentTitle = isPaid ? "Paid" : "Unpaid"
        paymentColor = isPaid ? AppColors.success : AppColors.secondaryText
        stageTitle = isReady ? "Ready" : "Preparing"
        stageColor = isReady ? AppColors.success : AppColors.brandText
        actionTitle = isReady ? "Complete order" : "Mark ready"
        actionLabel = "\(actionTitle), \(title)"
        actionKind = isReady ? .secondary : .primary
    }
}
