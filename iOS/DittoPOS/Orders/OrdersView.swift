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
            VStack(spacing: AppLayout.mediumGap) {
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
                            LazyVStack(spacing: AppLayout.gap) {
                                Color.clear.frame(height: 0).id("top")
                                ForEach(state.orders, id: \.documentId) { order in
                                    let row = OrderHistoryRowViewModel(order: order)
                                    AppOrderSummary(title: row.title, summary: row.summary, status: row.status, tone: row.tone,
                                                    date: row.date, total: row.total,
                                                    expanded: AppOrderSummaryViewModel.supportsColumns(availableWidth: geometry.size.width))
                                }
                            }
                        }.onChange(of: state.pageIndex) { _ in proxy.scrollTo("top", anchor: .top) }
                    }
                }
                if state.total != nil {
                    AppPagination(label: "Page \(state.pageIndex + 1) of \(state.totalPages)", canPrevious: state.canPrevious, canNext: state.canNext, previous: previous, next: next)
                }
            }
            .padding(.horizontal, AppWindowViewModel(sizeClass: sizeClass).horizontalPadding)
            .padding(.vertical, AppLayout.padding)
        }.background(AppColors.background)
    }
}
