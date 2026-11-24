import AppUI
import SwiftUI

struct KDSOrderView: View {
    let order: Order
    let now: Date
    let onAdvance: () -> Void

    var body: some View {
        let viewModel = KitchenTicketViewModel(order: order, now: now)
        AppTicket(title: viewModel.title, lines: viewModel.lines, isPaid: viewModel.isPaid,
                  elapsed: viewModel.elapsed, isReady: viewModel.isReady, onAdvance: onAdvance)
    }

}
