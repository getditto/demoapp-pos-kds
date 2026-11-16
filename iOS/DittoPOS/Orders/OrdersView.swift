import AppUI
import SwiftUI

struct OrdersView: View {
    @StateObject private var history: OrdersHistory
    let isActive: Bool
    init(repository: OrdersRepository, isActive: Bool) {
        _history = StateObject(wrappedValue: OrdersHistory(repository: repository))
        self.isActive = isActive
    }
    var body: some View {
        OrdersContent(state: history.state, previous: history.previous, next: history.next)
            .onAppear { history.setVisible(isActive) }
            .onChange(of: isActive) { history.setVisible($0) }
            .onDisappear { history.setVisible(false) }
    }
}

struct OrdersContent: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    let state: OrdersHistoryState
    let previous: () -> Void
    let next: () -> Void
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 12) {
                if state.isLoading {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if state.orders.isEmpty {
                    GeometryReader { viewport in
                        ScrollView {
                            AppEmptyState("No orders yet", message: "Orders for this location will appear here.", icon: "receipt", style: .large)
                                .frame(minHeight: viewport.size.height)
                        }
                    }.frame(maxHeight: .infinity)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                Color.clear.frame(height: 0).id("top")
                                ForEach(state.orders, id: \.documentId) { order in
                                    AppOrderSummary(
                                        title: "Order #\(order.title)", summary: order.summary.keys.sorted().map { "\(order.summary[$0]!) × \($0)" }.joined(separator: " · "),
                                        status: order.historyStatusTitle, tone: order.historyStatusTone,
                                        date: order.createdAt.formatted(.dateTime.month(.abbreviated).day().hour().minute()),
                                        total: order.total.description, expanded: geometry.size.width >= 760)
                                }
                            }
                        }.onChange(of: state.pageIndex) { _ in proxy.scrollTo("top", anchor: .top) }
                    }
                }
                if state.total != nil {
                    AppPagination(label: "Page \(state.pageIndex + 1) of \(state.totalPages)", canPrevious: state.canPrevious, canNext: state.canNext, previous: previous, next: next)
                }
            }
            .padding(.horizontal, sizeClass == .regular ? 20 : AppLayout.padding)
            .padding(.vertical, AppLayout.padding)
        }.background(AppColors.background)
    }
}

extension Order {
    var historyStatusTitle: String {
        switch status {
        case .open: return "Open"
        case .inProcess: return "Preparing"
        case .processed: return "Ready"
        case .delivered: return "Delivered"
        case .canceled: return "Canceled"
        }
    }
    var historyStatusTone: AppStatusTone {
        switch status {
        case .inProcess: return .active
        case .processed, .delivered: return .success
        case .open, .canceled: return .secondary
        }
    }
}
