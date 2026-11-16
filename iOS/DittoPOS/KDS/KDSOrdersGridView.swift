import AppUI
import SwiftUI

struct KDSOrdersGridView: View {
    @StateObject private var viewModel: KDSViewModel
    private let ordersRepository: OrdersRepository
    private let isActive: Bool

    init(ordersRepository: OrdersRepository, isActive: Bool = true) {
        self.ordersRepository = ordersRepository
        self.isActive = isActive
        _viewModel = StateObject(wrappedValue: KDSViewModel(ordersRepository: ordersRepository))
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TimelineView(.periodic(from: .now, by: 60)) { context in
                    KitchenBoard(orders: viewModel.orders, now: context.date) { order in
                        guard let next = order.status.next else { return }
                        ordersRepository.updateStatus(of: order, with: next)
                    }
                }
            }
        }
        .background(AppColors.background)
        .onAppear { viewModel.setVisible(isActive) }
        .onChange(of: isActive) { viewModel.setVisible($0) }
        .onDisappear { viewModel.setVisible(false) }
    }
}

struct KitchenBoard: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    let orders: [Order]
    let now: Date
    let onAdvance: (Order) -> Void

    private var preparing: [Order] { orders.filter { $0.status == .inProcess } }
    private var ready: [Order] { orders.filter { $0.status == .processed } }
    private var isEmpty: Bool { preparing.isEmpty && ready.isEmpty }

    var body: some View {
        VStack(spacing: sizeClass == .regular ? 16 : 12) {
            if sizeClass == .regular {
                HStack(spacing: 24) {
                    stageHeader("Preparing", count: preparing.count)
                    stageHeader("Ready", count: ready.count, ready: true)
                }
            } else {
                HStack {
                    Text("Preparing \(preparing.count)")
                    Spacer(minLength: 8)
                    Text("Ready \(ready.count)").foregroundStyle(AppColors.success)
                }.font(AppTypography.body.weight(.medium)).frame(minHeight: 32)
            }
            if isEmpty {
                AppEmptyState("No active orders", message: "Orders with items appear here.", icon: "check-circle", style: .success)
            } else if sizeClass == .regular {
                HStack(alignment: .top, spacing: 24) {
                    stageColumn(preparing, emptyMessage: "No orders preparing")
                    stageColumn(ready, emptyMessage: "No orders ready")
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) { tickets(preparing + ready) }
                }
            }
        }
        .padding(sizeClass == .regular ? 24 : AppLayout.padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func stageHeader(_ title: String, count: Int, ready: Bool = false) -> some View {
        Text("\(title) · \(count)").font(AppTypography.title)
            .foregroundStyle(ready ? AppColors.success : AppColors.text)
            .frame(maxWidth: .infinity, alignment: .leading).accessibilityAddTraits(.isHeader)
    }

    private func stageColumn(_ orders: [Order], emptyMessage: String) -> some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if orders.isEmpty {
                    AppWell { Text(emptyMessage).font(AppTypography.body).foregroundStyle(AppColors.secondaryText) }
                } else {
                    tickets(orders)
                }
            }
        }.frame(maxWidth: .infinity)
    }

    private func tickets(_ orders: [Order]) -> some View {
        ForEach(orders, id: \.documentId) { order in
            KDSOrderView(order: order, now: now) { onAdvance(order) }
        }
    }
}
